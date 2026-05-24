# Week 05 - 유서연

## Redis의 List 자료 구조

**List(리스트)**

> 순서대로 데이터를 저장할 수 있는 자료 구조

- 먼저 들어온 데이터를 먼저 처리하는 **Queue**
- 나중에 들어온 데이터를 먼저 처리하는 **Stack**

### 자주 사용하는 List 명령어

- **RPUSH 명령어**: 리스트의 오른쪽에 데이터 추가

```bash
RPUSH key value
```

위 명령어를 실행하면 `my_list`라는 리스트에 `1`, `2`가 순서대로 저장된다.

Redis에서는 리스트를 따로 생성하는 명령어가 없고, 데이터를 넣는 순간 Redis가 알아서 리스트를 생성한다.

- **LRANGE 명령어**: 리스트에 저장된 데이터를 인덱스 범위로 조회

```bash
LRANGE key start end
```

- **LLEN 명령어**: 리스트에 들어있는 데이터의 총 개수 조회

```bash
LLEN key
```

- **LPOP 명령어**: 리스트의 왼쪽에서 데이터를 꺼내오는 명령어

```bash
LPOP key
```

---

### [실습] 좋아요 수 폭증으로 인한 DB 부하를 Redis로 해결하기

#### 문제

좋아요 요청이 들어올 때마다 DB에 바로 저장하면, 요청이 폭증했을 때 DB가 모든 쓰기 작업을 직접 처리해야 한다.

```sql
INSERT INTO likes (user_id, post_id)
VALUES (?, ?)
```

좋아요처럼 짧은 시간에 많이 발생할 수 있는 기능은 DB에 부하를 크게 줄 수 있다.

#### 해결 방법: Write Back 방식 사용하기

DB에 바로 저장하지 않고, 좋아요 데이터를 먼저 Redis List에 쌓아둔다.

```text
좋아요 요청
→ Redis List에 먼저 저장
→ 사용자에게 빠르게 응답
→ 스케줄러가 Redis에서 꺼내 DB에 저장
```

즉, Redis List를 **임시 Queue**로 사용한다.

이를 통해 요청이 갑자기 몰려도 DB가 모든 요청을 즉시 처리하지 않고, 스케줄러를 통해 나누어 처리할 수 있다.

#### 핵심 코드 흐름

- 좋아요 요청을 Redis List에 저장

```java
public void likePostWithRedis(LikePostRequestDto request) {
    Long userId = request.getUserId();
    Long postId = request.getPostId();

    String value = userId + ":" + postId;

    redisTemplate.opsForList().rightPush("like_queue", value);
}
```

이 코드를 Redis 명령어로 보면 다음과 같다.

```bash
RPUSH like_queue 1:10
```

이 방식에서는 좋아요 요청이 들어올 때 DB에 바로 접근하지 않는다.  

대신 Redis에 빠르게 데이터를 쌓고, 클라이언트에게 먼저 응답한다.

- 스케줄러가 Redis 데이터를 DB에 저장

```java
@Scheduled(fixedDelay = 1000)
public void saveLikesToDb() {
    List<Like> likesToSave = new ArrayList<>();

    while (true) {
        String value = redisTemplate.opsForList().leftPop("like_queue");

        if (value == null) {
            break;
        }

        String[] split = value.split(":");
        Long userId = Long.parseLong(split[0]);
        Long postId = Long.parseLong(split[1]);

        likesToSave.add(new Like(userId, postId));

        if (likesToSave.size() >= 1000) {
            break;
        }
    }

    likeRepository.saveAll(likesToSave);
}
```

이 코드는 Redis List에 쌓인 좋아요 데이터를 최대 1000개씩 꺼내 DB에 저장한다.

이런 방식으로 DB가 모든 요청을 실시간으로 처리하지 않고, 스케줄러를 통해 일정 단위로 나누어 처리한다.

#### Write Back 방식의 장점

Write Back 방식의 가장 큰 장점은 **빠른 응답**과 **DB 부하 감소**이다.

기존 방식에서는 좋아요 요청마다 DB에 `INSERT`가 발생한다.

```text
요청 1개 = DB INSERT 1번
```

하지만, Write Back 방식에서는 요청이 들어올 때 Redis에 먼저 저장하고 바로 응답한다.

```text
요청 1개 = Redis 저장 1번
DB 저장 = 스케줄러가 모아서 처리
```

Redis는 메모리 기반 저장소이기 때문에 디스크 기반 DB보다 빠르게 쓰기 요청을 처리할 수 있다.

그래서 갑자기 좋아요 요청이 몰려도 DB가 모든 요청을 직접 받지 않고, Redis가 중간에서 요청을 흡수하는 역할을 한다.

#### Write Back 방식의 트레이드오프

Write Back 방식은 성능 면에서는 유리하지만, 그만큼 감수해야 하는 trade-off가 있다.

1) Redis와 DB 사이에 데이터 불일치가 생길 수 있다

Write Back 방식에서는 Redis에 먼저 저장하고 DB에는 나중에 반영한다.

따라서 스케줄러가 DB에 저장하기 전까지는 Redis와 DB의 상태가 다를 수 있다.

```text
Redis: 최신 좋아요 데이터 존재
DB: 아직 이전 상태
```

즉, Redis에는 좋아요 요청이 쌓였지만 DB에는 아직 저장되지 않은 시간이 존재한다.

이런 구조에서는 DB만 조회하면 최신 좋아요 상태를 알 수 없을 수도 있다.

2) 장애가 발생하면 데이터 유실 가능성이 있다

Redis에 좋아요 데이터가 쌓인 상태에서 DB에 저장되기 전에 장애가 발생하면 문제가 생길 수 있다.

예를 들어 다음과 같은 상황이다.

```text
1. 사용자가 좋아요 요청
2. Redis List에 좋아요 데이터 저장
3. 클라이언트에게 성공 응답
4. DB 저장 전에 Redis 또는 서버 장애 발생
```

이 경우 클라이언트는 성공 응답을 받았지만, 실제 DB에는 좋아요 데이터가 저장되지 않을 수 있다.

즉, Write Back 방식에서는 빠른 응답을 얻는 대신, DB 반영 전 장애 상황을 반드시 고려해야 한다.

3) 재처리 로직이 필요할 수 있다

스케줄러가 Redis 데이터를 꺼낸 뒤 DB 저장에 실패하면 어떻게 될까?

단순히 `LPOP`으로 데이터를 꺼내면, 꺼낸 순간 Redis List에서는 데이터가 사라진다.

```java
String value = redisTemplate.opsForList().leftPop("like_queue");
```

그런데 이 이후 DB 저장에 실패하면, 해당 좋아요 데이터는 Redis에도 없고 DB에도 없는 상태가 될 수 있다.

따라서 실무에서는 실패한 데이터를 다시 처리할 수 있는 구조가 필요하다.

예를 들면 다음과 같은 방식이다.

```java
try {
    likeRepository.saveAll(likesToSave);
} catch (Exception e) {
    // 실패한 데이터를 별도 큐에 다시 저장
    for (Like like : likesToSave) {
        String retryValue = like.getUserId() + ":" + like.getPostId();
        redisTemplate.opsForList().rightPush("like_retry_queue", retryValue);
    }
}
```

이렇게 하면 DB 저장에 실패한 데이터를 `like_retry_queue`에 다시 넣고, 이후 재처리할 수 있다.

4) 스케줄러 주기와 배치 크기를 조절해야 한다

스케줄러가 너무 자주 실행되면 DB에 자주 접근하게 되어 Write Back의 장점이 줄어든다.

반대로 스케줄러 주기가 너무 길면 Redis와 DB 사이의 데이터 불일치 시간이 길어진다.

```java
@Scheduled(fixedDelay = 1000)
```

또한 한 번에 저장하는 데이터 개수도 중요하다.

```java
if (likesToSave.size() >= 1000) {
    break;
}
```

배치 크기가 너무 작으면 DB 저장 횟수가 많아지고, 너무 크면 한 번의 DB 저장 작업이 무거워질 수 있다.

따라서 서비스 트래픽과 DB 성능을 고려해 적절한 주기와 배치 크기를 정해야 한다.

#### Write Back을 사용할 때 고려할 점

Write Back 방식을 적용할 때는 단순히 빠르다는 장점만 보면 안되고, 다음 질문을 함께 고려해야 한다.

```text
1. DB에 바로 반영되지 않아도 괜찮은 데이터인가?
2. Redis와 DB 사이의 일시적인 불일치를 허용할 수 있는가?
3. Redis 장애 시 데이터 유실을 어떻게 막을 것인가?
4. DB 저장 실패 시 재처리 로직이 있는가?
5. 스케줄러 주기와 배치 크기는 적절한가?
```

좋아요 기능은 사용자가 빠른 반응을 기대하는 기능이고, 약간의 DB 반영 지연을 허용할 수 있는 경우가 많다.

따라서, Write Back 방식을 적용하기에는 비교적 적합하다.

반면, 결제, 재고, 포인트처럼 즉시 정확성이 중요한 기능에는 Write Back을 그대로 적용하기 어렵다.

---

## Redis의 String 자료 구조

**String**

> 하나의 key에 하나의 value를 저장하는 방식

Redis의 String 자료 구조는 단순한 문자열뿐만 아니라 숫자, JSON 형태의 문자열 등 다양한 값을 저장할 수 있다.

가장 기본적인 사용 방식은 다음과 같다.

```bash
SET key value
GET key
DEL key
```

- `SET`: key-value 형태로 데이터를 저장한다.
- `GET`: key를 이용해 value를 조회한다.
- `DEL`: key를 이용해 데이터를 삭제한다.

### SET NX

- NX

> key가 존재하지 않을 때만 저장

```bash
SET key value NX
```

정리하면, `SET`과 `NX` 옵션을 함께 사용하면 기존에 key가 없을 때만 데이터를 저장할 수 있다.

이 방식은 Redis에서 Lock을 구현할 때 자주 사용된다.

예를 들어, 어떤 작업을 여러 사용자가 동시에 수행하려고 할 때, 먼저 key를 생성한 요청만 작업을 진행하게 만들 수 있다.

### [실습] 재고 차감 시 동시성 이슈 해결하기

#### 문제 

여러 사용자가 동시에 같은 상품을 구매하면 재고가 정확히 차감되어야 한다.

하지만 여러 요청이 동시에 같은 재고 값을 읽고 수정하면, 실제 요청 수보다 재고가 적게 차감되는 문제가 발생할 수 있다.

예를 들어 두 사용자가 동시에 재고 `10,000개`를 조회하면, 둘 다 같은 값을 기준으로 차감하게 된다.

```text
사용자 A: 재고 10,000개 조회
사용자 B: 재고 10,000개 조회
```

두 번 차감되어야 하지만, 둘 다 `9,999개`로 저장하면 실제로는 한 번만 차감된 것처럼 보인다.

#### 해결 방법: Redis Lock 사용하기

Redis의 `SET NX`를 사용해 Lock을 만든다.

```bash
SET stock_lock:1 lock NX EX 3
```

- `stock_lock:1`: 상품 재고에 대한 Lock key
- `lock`: 저장할 값
- `NX`: key가 없을 때만 저장
- `EX 3`: 3초 뒤 자동 삭제

이미 Lock key가 존재하면 다른 요청은 Lock 획득에 실패한다.  

즉, 먼저 Lock을 얻은 요청만 재고 차감 로직을 실행하고, 나머지 요청은 기다리게 된다.

이를 통해, 여러 요청이 동시에 하나의 재고 데이터를 수정하지 못하게 만들 수 있다!

#### 핵심 코드 흐름

- Lock 획득 시도

```java
private boolean tryLock(String key) {
    return redisTemplate
            .opsForValue()
            .setIfAbsent(key, "lock", Duration.ofMillis(3000));
}
```

`setIfAbsent()`는 Redis의 `SET NX`와 같은 역할을 한다.

즉, key가 없으면 저장하고 `true`를 반환한다.  
key가 이미 있으면 저장하지 않고 `false`를 반환한다.

- Lock을 얻은 요청만 재고 차감

```java
while (!tryLock(key)) {
    Thread.sleep(100);
}

try {
    stockService.decrease(id);
} finally {
    redisTemplate.delete(key);
}
```

흐름은 다음과 같다.

```text
1. Redis Lock 획득을 시도한다.
2. Lock을 얻지 못하면 잠깐 기다렸다가 다시 시도한다.
3. Lock을 얻은 요청만 재고 차감 로직을 실행한다.
4. 작업이 끝나면 Lock을 삭제한다.
```

여기서 `finally` 블록이 중요한 이유는, 중간에 예외가 발생해도 Lock을 해제해야 하기 때문이다.

Lock이 해제되지 않으면 다른 요청들이 계속 기다리는 문제가 생길 수 있다.
