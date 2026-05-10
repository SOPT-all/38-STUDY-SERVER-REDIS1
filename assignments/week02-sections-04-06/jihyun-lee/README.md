# Week 02 - 이지현

## 캐시, 캐싱

- 캐시(Cache)
    
    원본 저장소보다 빠르게 가져올 수 있는 임시 데이터 저장소
    
- 캐싱(Caching)
    
    캐시에 접근해서 데이터를 빠르게 가져오는 방식
    

## 데이터 캐싱 전략

### Cache Aside

= Lazy Loading 전략

서버가 먼저 캐시를 확인하고, 없으면 DB에서 조회한 뒤 캐시에 저장 (데이터 조회 전략)

```
1. 클라이언트 요청
2. 서버가 캐시 조회
3. 캐시에 있으면 바로 반환 (Cache Hit)
4. 캐시에 없으면 DB 조회 (Cache Miss)
5. DB에서 가져온 데이터를 캐시에 저장
6. 응답 반환
```

- 자주 조회되는 데이터만 캐시에 저장됨
- 캐시 서버에 장애가 나도 DB를 조회해서 서비스할 수 있음
- 처음 요청은 DB를 조회해야 하므로 느릴 수 있음

### Write Around

데이터를 저장하거나 수정할 때 DB에만 저장하고 캐시는 갱신하지 않는 방식 (데이터 저장, 수정, 삭제 전략)

```
1. 클라이언트가 데이터 수정 요청
2. 서버가 DB에 저장
3. 캐시는 건드리지 않음
4. 나중에 조회 요청이 오면 캐시에 저장
```

- 자주 조회되지 않는 데이터를 캐시에 넣지 않아도 됨
- 캐시 공간을 아낄 수 있음

### Cache Aside, Write Around 전략의 한계점 / 해결 방법

- 캐시된 데이터와 DB 데이터가 일치하지 않을 수 있음
    - 데이터 조회 성능 개선 목적으로 레디스를 쓰는 경우에는 데이터 일관성을 포기하고 성능 향상을 택한 것
        
        ⇒ 캐시를 적용시키기에 적절한 데이터
        
        - 자주 조회되는 데이터
        - 잘 변하지 않는 데이터
        - 실시간으로 정확하게 일치하지 않아도 되는 데이터
    - 적절한 주기로 데이터를 동기회시켜줘야 함 → TTL 기능
- 캐시에 저장할 수 있는 공간이 비교적 작음
    - TTL 기능을 통해 캐시의 공간을 효율적으로 사용 (자주 조회하지 않는 데이터는 삭제됨)

### Write Through

데이터를 저장하거나 수정할 때 DB와 캐시에 동시에 반영하는 방식

```
1. 클라이언트가 데이터 수정 요청
2. 서버가 DB에 저장
3. 서버가 캐시에도 저장
4. 응답 반환
```

#### 장점

- DB와 캐시가 비교적 일치
- 수정 후 바로 최신 데이터를 캐시에서 조회할 수 있음

#### 단점

- 쓰기 작업이 느려질 수 있음
- 자주 조회되지 않는 데이터까지 캐시에 저장될 수 있음

### Write Back

먼저 캐시에만 데이터를 저장하고, DB에는 나중에 반영하는 방식

```
1. 클라이언트가 데이터 수정 요청
2. 서버가 캐시에 먼저 저장
3. 나중에 DB에 저장
```

#### 장점

- 쓰기 속도가 빠름
- 쓰기 요청이 많은 서비스에서 성능을 높일 수 있음

#### 단점

- 캐시 장애가 나면 DB에 반영되지 않은 데이터가 사라질 수 있음
- 구현이 복잡함

### Refresh Ahead

캐시가 만료되기 전에 미리 새 데이터로 갱신하는 방식

```
1. 캐시에 데이터 저장
2. 만료 시간이 가까워짐
3. 백그라운드에서 미리 DB 조회
4. 캐시를 최신 데이터로 갱신
```

인기 게시글 목록, 랭킹, 메인 화면 데이터처럼 많은 사용자가 자주 보는 데이터에 사용할 수 있음

#### 장점

- 캐시 만료 직후 요청이 몰려도 DB 부하를 줄일 수 있음
- 사용자는 빠른 응답을 계속 받을 수 있음

#### 단점

- 구현이 어려움
- 실제로 조회되지 않을 데이터까지 갱신할 수 있음

## 캐싱을 조회 성능 개선을 하기 전 SQL 튜닝 먼저하기

데이터 조회 성능을 개선하는 방법

- SQL 튜닝
- 캐싱 서버 활용 (Redis 등)
- 레플리케이션 (Master/Slave 구조)
- 샤딩
- DB 스케일업 (CPU, Memory, SSD 등 하드웨어 업그레이드)

#### SQL 튜닝을 먼저 고려하는 이유

1. SQL 튜닝을 제외한 나머지 방법은 추가적인 시스템을 구축해야 함 → 금정적, 시간적 비용이 추가적으로 발생
    
    반면, SQL 튜닝은 기존의 시스템 변경 없이 성능을 개선할 수 있음
    
2. 근본적인 문제를 해결하는 방법이 SQL 튜닝일 가능성이 높음
    
    SQL 자체가 비효율적으로 작성됐다면 아무리 시스템적으로 성능을 개선한다고 하더라도 한계가 있음
    
    SQL 튜닝을 통해 훨씬 간단한 개선으로 큰 성능 개선 효과를 얻을 수 있음
    

## 핵심 어노테이션

- `@Cacheable` : 캐시에 값이 있으면 메서드를 실행하지 않고 캐시 값을 반환. 캐시에 없으면 메서드를 실행하고 결과를 캐시에 저장.
- `@CachePut` : 메서드를 항상 실행하고, 그 결과를 캐시에 저장 (Write Through 전략)
- `@CacheEvict` : 해당 캐시를 삭제. 다음 조회 때 DB에서 최신 데이터를 다시 가져와 캐시에 저장.
    - Write Around 전략에서 수정 직후 캐시에 예전 데이터가 남아 있으면 오래된 데이터가 조회될 수 있음 → 보통 수정/삭제 시에는 기존 캐시를 삭제
- `@EnableCaching` : 캐시 기능을 켜는 어노테이션.
- `@Caching` : 여러 캐시 작업을 한 번에 묶을 때 사용
    
    예를 들어서 게시글을 수정하면, 게시글 상세 캐시 삭제, 게시글 목록 캐시 삭제, 인기 게시글 캐시 삭제 등 여러 캐시를 같이 지워야 할 수 있음
    
    ```java
    @Caching(evict = {
            @CacheEvict(value = "post", key = "#postId"),
            @CacheEvict(value = "postList", allEntries = true),
            @CacheEvict(value = "popularPosts", allEntries = true)
    })
    public void updatePost(Long postId, UpdatePostRequest request) {
        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundException::new);
    
        post.update(request.title(), request.content());
    }
    ```
    
    `allEntries = true`는 해당 캐시 그룹의 모든 데이터를 삭제한다는 뜻
    
- `@CacheConfig` : 클래스 단위로 공통 캐시 설정을 지정할 때 사용

## RedisTemplate vs @Cacheable

- `@Cacheable`: 메서드 결과를 자동으로 캐싱하는 방식
- `RedisTemplate`: Redis에 직접 명령을 보내는 방식

#### `@Cacheable`

`@Cacheable` 은 Spring Cache 추상화 기능 → 즉, 개발자가 Redis 명령어를 직접 쓰지 않아도 됨

```java
@Cacheable(value = "post", key = "#postId")
public PostResponse getPost(Long postId) {
    return postRepository.findById(postId)
            .map(PostResponse::from)
            .orElseThrow(PostNotFoundException::new);
}
```

동작 흐름은 다음과 같음

```
1. getPost(1) 호출
2. Spring이 먼저 캐시에서 post::1 조회
3. 캐시에 있으면 메서드 실행 안 함
4. 캐시에 없으면 메서드 실행
5. 실행 결과를 Redis에 저장
6. 결과 반환
```

메서드 반환값 전체를 캐싱할 때 좋음

#### RedisTemplate

`RedisTemplate`은 Redis를 직접 다루는 도구
Spring이 자동으로 캐싱해주는 것이 아니라, 개발자가 직접 저장, 조회, 삭제를 작성

```java
redisTemplate.opsForValue().set("post:" + postId, postResponse);
PostResponse cached = (PostResponse) redisTemplate.opsForValue().get("post:" + postId);
redisTemplate.delete("post:" + postId);
```

TTL도 직접 줄 수 있음

```java
redisTemplate.opsForValue()
        .set("post:" + postId, postResponse, Duration.ofMinutes(10));
```

`RedisTemplate`은 단순 캐시보다 Redis 기능을 직접 쓰고 싶을 때 좋음

- 랭킹
- 인증 코드 저장
- Refresh Token 저장
- 분산 락
- 실시간 접속자 수

#### 상황 비교

- 게시글 상세 조회 캐싱 → `@Cacheable` 이 더 편함. 개발자가 캐시 조회, 저장 코드를 직접 작성하지 않아도 됨
- 인증 코드 저장 → `RedisTemplate`이 더 자연스러움. 인증 코드는 메서드 결과 캐싱이라기보다, 특정 key에 값을 직접 저장하고 만료 시간을 주는 기능
- 인기 게시글 랭킹 → `RedisTemplate`이 더 적합. Redis의 `Sorted Set`을 사용할 수 있기 때문

## Cache Stampede / Cache Avalanche

### Cache Stampede 문제

<aside>

캐시가 만료되는 순간, 많은 요청이 동시에 DB로 몰리는 문제

</aside>

#### 왜 문제가 될까?

원래 캐시를 쓰는 이유는 DB 부하를 줄이기 위해서

그런데 Cache Stampede가 발생하면 캐시가 만료되는 순간 오히려 DB에 요청이 몰리게 됨

```
캐시 정상 상태: Redis가 대부분 처리
캐시 만료 순간: DB가 갑자기 대량 요청 처리
```

그래서 DB 응답이 느려지거나, 심하면 장애로 이어질 수 있음

#### 자주 발생하는 경우

특히 이런 데이터에서 자주 발생

```
인기 게시글 목록
메인 화면 데이터
랭킹 데이터
상품 상세 정보
이벤트 페이지
공지사항 목록
```

공통점은 많은 사용자가 동시에 조회하는 데이터라는 점

#### 해결 방법

1. 락 사용하기
    
    캐시가 없을 때 모든 요청이 DB를 조회하지 못하게 하고, 하나의 요청만 DB를 조회해서 캐시를 다시 채우게 하는 방식
    
    ```
    1. 캐시 만료
    2. 요청 1이 락 획득
    3. 요청 1만 DB 조회
    4. 요청 1이 Redis에 다시 저장
    5. 나머지 요청은 새 캐시 값을 사용
    ```
    
    흐름은 이렇게 볼 수 있음
    
    ```
    요청 A → Cache Miss → 락 획득 성공 → DB 조회 → 캐시 저장
    요청 B → Cache Miss → 락 획득 실패 → 잠시 대기 → 캐시 재조회
    요청 C → Cache Miss → 락 획득 실패 → 잠시 대기 → 캐시 재조회
    ```
    
    이 방식은 효과적이지만 구현이 조금 복잡함
    
2. Refresh Ahead
    
    캐시가 완전히 만료되기 전에 미리 갱신하는 방식
    
    ```
    1. 캐시 TTL = 10분
    2. 8분쯤 지났을 때 미리 DB 조회
    3. Redis 캐시를 새 값으로 갱신
    4. 사용자는 계속 Cache Hit 상태로 조회
    ```
    
    즉, 사용자가 Cache Miss를 만나기 전에 서버가 미리 캐시를 새로 채우는 방식
    
    인기 게시글, 랭킹, 메인 화면 데이터처럼 자주 조회되는 데이터에 적합함
    
3. Stale While Revalidate
    
    조금 오래된 데이터를 먼저 응답하고, 뒤에서 캐시를 새로 갱신하는 방식
    
    예를 들어 캐시 데이터에 두 가지 시간을 둠
    
    ```
    soft TTL: 5분
    hard TTL: 10분
    ```
    
    5분이 지나면 데이터가 조금 오래됐다고 판단하지만, 바로 버리지는 않음
    
    ```
    1. 요청이 들어옴
    2. soft TTL은 지났지만 hard TTL은 지나지 않음
    3. 일단 오래된 캐시 데이터를 응답
    4. 백그라운드에서 DB 조회 후 캐시 갱신
    ```
    
    장점은 사용자가 느린 응답을 덜 경험한다는 것
    단점은 사용자가 잠깐 오래된 데이터를 볼 수 있다는 것
    

### Cache Avalanche

<aside>

많은 캐시 데이터가 한꺼번에 만료되거나, 캐시 서버 자체가 장애 나서 대량 요청이 DB로 몰리는 문제

</aside>

예를 들어 여러 캐시에 TTL을 전부 10분으로 똑같이 줬을 때, 10분 뒤에 여러 캐시가 동시에 사라지면

```
많은 캐시 키가 동시에 만료
→ 많은 요청이 Cache Miss
→ DB로 대량 요청
→ DB 부하 급증
```

또는 Redis 서버가 장애 나도 비슷한 일이 생길 수 있음

```
Redis 장애
→ 모든 캐시 조회 실패
→ 요청이 전부 DB로 이동
→ DB 부하 급증
```

#### 자주 발생하는 경우

- 여러 캐시에 TTL을 동일하게 설정한 경우
- 대량 캐시가 동시에 만료되는 경우
- Redis 장애가 발생한 경우

#### 해결 방법

1. TTL을 랜덤하게 주기
    
    여러 캐시가 동시에 만료되지 않도록 TTL에 약간의 랜덤 값을 더하는 방식
    
    예를 들어 모든 캐시 TTL을 10분으로 고정하면 동시에 만료될 수 있음
    
    ```
    post:1 → 10분 뒤 만료
    post:2 → 10분 뒤 만료
    post:3 → 10분 뒤 만료
    ```
    
    대신 TTL을 조금씩 다르게 주면
    
    ```
    post:1 → 9분 40초 뒤 만료
    post:2 → 10분 10초 뒤 만료
    post:3 → 11분 뒤 만료
    ```
    
    Cache Miss가 한 순간에 몰리는 것을 줄일 수 있음
    
2. 캐시 서버 장애 대응
    - Redis timeout 짧게 설정
    - DB fallback 준비
    - 장애 시 요청 제한
3. 캐시 분산
    - Redis Cluster, Replica 등을 사용해 장애 영향을 줄임