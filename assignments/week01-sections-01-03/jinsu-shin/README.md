# Week 01 - 신진수

## 1. 이번 주 학습 내용 요약

- Redis의 기본 데이터 저장/조회/삭제 명령어 학습
- TTL(만료시간) 개념과 활용 방법 이해
- 현업에서 사용하는 Key 네이밍 컨벤션 정리

## 2. 실습 과정과 핵심 코드 또는 명령어

실습 환경: Docker로 Redis 컨테이너 실행 (`docker run -d --name redis -p 6379:6379 redis`)

### 데이터 저장

```bash
127.0.0.1:6379> set users:1:name "jinsu shin"
OK
127.0.0.1:6379> set users:1:hobby "watching movies"
OK
127.0.0.1:6379> set users:1:job "server developer"
OK
127.0.0.1:6379> set users:1:food "samgyeopsal"
OK
127.0.0.1:6379> set users:1:city "yongin"
OK
```

### 데이터 조회

```bash
127.0.0.1:6379> get users:1:name
"jinsu shin"
127.0.0.1:6379> get users:1:hobby
"watching movies"
127.0.0.1:6379> get users:1:job
"server developer"
127.0.0.1:6379> get users:1:food
"samgyeopsal"
127.0.0.1:6379> get users:1:city
"yongin"
```

### 모든 Key 조회 및 패턴 필터

```bash
127.0.0.1:6379> keys *
1) "users:1:city"
2) "users:1:food"
3) "users:1:name"
4) "users:1:hobby"
5) "users:1:job"

127.0.0.1:6379> keys users:1:*
1) "users:1:city"
2) "users:1:food"
3) "users:1:name"
4) "users:1:hobby"
5) "users:1:job"
```

### TTL 설정 및 확인

거주 도시처럼 변경 가능성이 있는 데이터를 임시 데이터로 가정하고 만료시간 설정.

```bash
127.0.0.1:6379> set users:1:city "yongin" ex 15
OK
127.0.0.1:6379> ttl users:1:city
(integer) 9                          # 9초 남음
127.0.0.1:6379> ttl users:1:name
(integer) -1                         # 만료시간 없음
```

15초 후 확인:

```bash
127.0.0.1:6379> get users:1:city
(nil)                                # 만료되어 삭제됨
127.0.0.1:6379> ttl users:1:city
(integer) -2                         # 키 자체가 없음
```

### 데이터 삭제

```bash
127.0.0.1:6379> del users:1:food
(integer) 1                          # 삭제 성공
127.0.0.1:6379> get users:1:food
(nil)
```

### 전체 데이터 삭제

```bash
127.0.0.1:6379> flushall
OK
127.0.0.1:6379> keys *
(empty array)
```

## 3. 문제 해결 과정 또는 트러블슈팅

### 실수 및 수정

- `key *` 입력 시 `ERR unknown command 'key'` 에러 발생 → `keys *` 로 수정 (오타 주의)
- `del user:1:food` 입력 시 `(integer) 0` 반환 → key 이름을 `user`로 잘못 입력. `users:1:food`로 수정 후 정상 삭제 확인

### 깨달은 점

**Key 네이밍 컨벤션**

콜론(`:`)을 활용해 계층적으로 의미를 구분한다.

- `users:100:profile` → users 중 PK가 100인 user의 profile
- `products:123:details` → products 중 PK가 123인 product의 details

| 장점 | 설명 |
|------|------|
| 가독성 | 데이터의 의미와 용도를 쉽게 파악 가능 |
| 일관성 | 컨벤션 준수로 유지보수 용이 |
| 검색 및 필터링 용이성 | 패턴 매칭으로 특정 유형의 Key를 빠르게 탐색 |
| 확장성 | Key 이름 충돌 방지 |

Redis는 메모리 공간이 한정되어 있어 모든 데이터를 저장할 수 없다. TTL을 활용해 자주 사용하는 데이터만 캐싱하고, 일정 시간이 지나면 자동으로 삭제되도록 운영하는 것이 일반적인 패턴이다.

**네이밍 컨벤션이 실수를 드러낸다**

`del user:1:food`에서 `(integer) 0`이 반환됐을 때, 명령이 실패한 게 아니라 해당 key가 없다는 뜻임을 알 수 있었다. 만약 key 이름이 단순히 `food`였다면 오타인지 원래 없는 key인지 구분하기 어려웠을 것이다. `users:1:food`처럼 계층적으로 구성된 컨벤션 덕분에 `user`와 `users`의 차이가 명확히 보여 오타를 바로 인지할 수 있었다.

또한 `keys users:1:*` 패턴 매칭으로 특정 유저의 데이터만 필터링할 수 있다는 점이 실용적으로 느껴졌다. 실무에서 특정 유저의 캐시를 전부 무효화할 때 이 패턴을 활용할 수 있겠다고 생각했다.

**Integer 반환값의 의미**

Redis 명령어가 반환하는 `(integer)` 값은 단순 숫자가 아니라 각각 명확한 의미를 가진다.

| 명령어 | 반환값 | 의미 |
|--------|--------|------|
| `del users:1:food` | `(integer) 1` | 삭제된 key 개수 (1개 삭제 성공) |
| `del user:1:food` | `(integer) 0` | 삭제된 key 개수 (해당 key 없음) |
| `ttl users:1:city` | `(integer) 9` | 만료까지 남은 시간(초) |
| `ttl users:1:name` | `(integer) -1` | 만료시간이 설정되지 않은 key |
| `ttl users:1:city` (만료 후) | `(integer) -2` | 존재하지 않는 key |

특히 `del`이 성공/실패 대신 삭제된 개수를 반환한다는 점이 인상적이었다. 여러 key를 한 번에 삭제할 때도 `del key1 key2 key3` 형태로 쓸 수 있고, 반환값으로 실제로 몇 개가 삭제됐는지 확인할 수 있다.

## 4. 추가 학습 내용

- https://recondite-dry-2f7.notion.site/Redis-1-34ee55358a8d80c7ac35eaac4f49e12c?source=copy_link
- 노션에 정리했습니다!
## 5. 다음 주에 확인할 질문 또는 논의 포인트

- 캐싱 전략(Cache-Aside, Write-Through 등) 각각 어떤 상황에 적합한가?
- TTL을 너무 짧게/길게 설정했을 때 생기는 실무 문제는?
