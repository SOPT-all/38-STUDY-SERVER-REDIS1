# Week 03 - 신진수

## 1. 이번 주 학습 내용 요약

- 부하 테스트(Load Test)의 개념과 목적 이해
- k6로 Redis 적용 전후 Throughput 직접 비교
- EC2 배포

---

## 2. 실습 과정과 핵심 코드 또는 명령어

### 실습 환경

| 항목 | 설정 |
|------|------|
| board (Redis 있음) | Spring Boot, 포트 8080 |
| board-plain (Redis 없음) | Spring Boot, 포트 8081 |
| DB | MySQL 8.0 (Docker, port 3307), 더미 데이터 100만 건 |
| Redis | latest (Docker, port 6379) |
| 부하 테스트 도구 | k6 |

### Docker 컨테이너 실행

```bash
docker run -d --name mysql-board \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=mydb \
  -p 3307:3306 \
  mysql:8.0

docker run -d --name redis -p 6379:6379 redis
```

### 더미 데이터 생성

```sql
SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO boards (title, content, created_at)
WITH RECURSIVE cte (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 1000000
)
SELECT
    CONCAT('Title', LPAD(n, 7, '0')),
    CONCAT('Content', LPAD(n, 7, '0')),
    TIMESTAMP(DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 3650 + 1) DAY)
        + INTERVAL FLOOR(RAND() * 86400) SECOND)
FROM cte;
```

### k6 스크립트

**Redis 없음 (board-plain, 8081)**

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 30,
  duration: '10s',
};

export default function () {
  const res = http.get('http://localhost:8081/boards?page=1&size=10');
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

**Redis 있음 (board, 8080)**

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 30,
  duration: '10s',
};

export default function () {
  const res = http.get('http://localhost:8080/boards?page=1&size=10');
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

### 서버 빌드 및 실행

```bash
./gradlew clean build -x test
cd build/libs
nohup java -jar board-0.0.1-SNAPSHOT.jar &

# 포트 확인
lsof -i:8080  # board
lsof -i:8081  # board-plain
```

---

## 3. 성능 비교 결과

### Redis 없음 (board-plain)

```
vus: 30, duration: 10s

http_reqs: 289     26.07/s
http_req_duration: avg=1.1s  p(90)=1.17s  p(95)=1.2s
```

### Redis 있음 (board)

```
vus: 30, duration: 10s

http_reqs: 55782   5576.36/s
http_req_duration: avg=5.27ms  p(90)=7.21ms  p(95)=9.97ms
```

### 결과는? 두근 두근

| 항목 | Redis 없음 | Redis 있음 |
|------|-----------|-----------|
| **TPS** | 26 | 5,576 |
| **평균 응답시간** | 1.1s | 5.27ms |
| **P95** | 1.2s | 9.97ms |
| **Error Rate** | 0% | 0% |
| **성능 차이** | — | **약 214배** |

---

## 4. 이번 주 핵심 인사이트

규일님 아티클을 읽으면서 부하 테스트에 대한 관점이 바뀌었다.

> "단순히 서버가 죽는 지점을 관찰하고 끝"이 아니라,
> **안정성이 확보되는 구간을 파악하는 것**이 핵심이다.

VU 증가 → TPS 증가 → TPS 정체 → P99 Latency 증가 → Error Rate 증가

이 흐름에서 **전환 구간**을 찾는 것이 부하 테스트에서 주목해야 하는 부분이었다. 장애가 난 지점이 아니라, 장애가 나기 직전까지 안정적으로 운영 가능한 최대 구간을 아는 것이 운영 관점에서 더 중요하다!

### 핵심 지표 3가지

| 지표 | 의미 | 보는 이유!                     |
|------|------|----------------------------|
| **TPS** | 초당 처리 요청 수 | 시스템 최대 처리 용량 파악            |
| **P99 Latency** | 99%의 요청이 이 시간 이하로 응답 | 실제 사용자 경험 + 병목·장애 직전 신호 감지 |
| **Error Rate** | 실패 요청 비율 | 한계 초과 시점 감지                |


---

## 5. 추가 학습 내용

### 토스뱅크 약관 서버 사례로 보는 캐시 적용의 현실

> 참고: [캐시를 적용하기까지의 험난한 길 (TPS 1만 안정적으로 서비스하기) — 토스테크, 김경윤](https://toss.tech/article/cache-traffic-tip)

토스뱅크 약관 서버는 평균 1만, 최대 2만 TPS의 조회 트래픽을 받는다고 한다. 조회량이 많아 DB 부하가 심각해졌고, 해결책으로 Redis 캐시를 Look-aside 전략으로 적용했다고 한다.

캐시를 도입하면 반드시 따라오는 문제가 있다. 데이터가 변경될 때 캐시를 언제 무효화(evict)하느냐다. 직관적으로는 "DB에 저장하면서 캐시도 지우면 되지 않나?"라고 생각할 수 있는데, 이게 생각보다 타이밍이 까다롭다.

DB 커밋 **전**에 캐시를 지우면 다음 문제가 생긴다. 캐시가 비어있으니 다른 스레드가 DB를 조회해서 다시 캐시에 올리는데, 이 시점에 DB에는 아직 이전 값이 있다. 그러면 커밋이 완료된 후에도 캐시에는 과거 값이 살아있게 된다. 그래서 캐시 무효화는 반드시 DB 커밋 **후**에 해야 한다. 이를 `@TransactionalEventListener(phase = AFTER_COMMIT)`으로 구현했다고 한다.

우리 프로젝트에는 게시글 삭제/수정 API가 없어서 캐시 무효화가 없고, TTL 1분으로 자동 만료에 의존하고 있다. 만약 삭제 API가 생긴다면 이런 식이 될 것이다.

```java
// 단순히 @CacheEvict 쓰면 커밋 전에 캐시가 지워져서 위험하다..
@CacheEvict(cacheNames = "getBoards", allEntries = true)
@Transactional
public void deleteBoard(Long id) {
    boardRepository.deleteById(id);
}

// 커밋 후에 지우려면
@Transactional
public void deleteBoard(Long id) {
    boardRepository.deleteById(id);
    TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
        @Override
        public void afterCommit() {
            cacheManager.getCache("getBoards").clear();
        }
    });
}
```

그런데 커밋 후 캐시 무효화 사이의 0.003초가 문제였다고 한다. 약관 변경 이벤트를 Kafka로 발행하고, Consumer가 그 사이에 캐시를 조회하면 아직 무효화되지 않은 과거 값을 읽어버린다. 해결책은 순서를 강제하는 것이었다. 캐시를 먼저 무효화하고, 그 다음에 Kafka 이벤트를 발행하도록 `@Order`와 `TransactionSynchronizationManager`로 처리 순서를 보장했다고 한다.

그래도 여전히 Kafka 없이 일반 요청이 그 0.003초 안에 들어오는 경우는 어떡하냐는 의문이 남는다. 여기서 해결책은 코드가 아니라 정책이었다고 한다. `AFTER_COMMIT` 이벤트가 모두 처리되기 전까지는 API 응답이 나가지 않는다. 즉, 캐시 무효화가 완료되기 전은 아직 API가 응답하기 전 상태다. "커밋 직후 다음 요청"이 아니라 "API 응답 완료 이후 다음 요청"으로 기준을 바꾸면, 해당 구간은 문제가 되는 구간이 아니다.

마지막으로 캐시 무효화 자체가 실패하는 경우를 대비해 Circuit Breaker를 도입했다고 한다. 무효화에 실패하면 즉시 Circuit을 강제로 열고, 이후 모든 캐시 조회는 DB로 직접 가도록 했다. 성능은 낮아지지만 잘못된 캐시 데이터가 응답되는 것보다 낫다는 판단이었다고 한다.

우리 프로젝트에서는 Redis가 장애 나면 `@Cacheable`이 예외를 던져 요청 자체가 실패한다. Circuit Breaker를 적용한다면 이런 식이 될 것이다.

```java
// 현재: Redis 장애 시 요청 자체가 실패할 수 있음
@Cacheable(cacheNames = "getBoards", key = "'boards:page:' + #page + ':size:' + #size", cacheManager = "boardCacheManager")
public List<Board> getBoards(int page, int size) { ... }

// Circuit Breaker 적용: Redis 장애 시 DB로 직접 fallback
@CircuitBreaker(name = "redis", fallbackMethod = "getBoardsFallback")
@Cacheable(cacheNames = "getBoards", key = "'boards:page:' + #page + ':size:' + #size", cacheManager = "boardCacheManager")
public List<Board> getBoards(int page, int size) { ... }

public List<Board> getBoardsFallback(int page, int size, Exception e) {
    Pageable pageable = PageRequest.of(page - 1, size);
    return boardRepository.findAllByOrderByCreatedAtDesc(pageable).getContent();
}
```

우리 플젝에서는 Redis 캐시를 붙이는 건 어노테이션 몇 줄로 끝났지만, 실제 서비스에서는 커밋 타이밍, 이벤트 순서, 장애 시 Fallback까지 고려해야 한다는 걸 이 사례를 통해 배웠다.

---

## 6. 죄송합니다

AWS가 아직 조금 미숙해서,, EC2 배포는 스터디 전까지 시도해볼게요ㅠㅠ 배포 과정에서 어려웠던 부분이 있으면 과정 공유해보겠습니다!

---

## 7. 다음 주에 확인할 질문 또는 논의 포인트

- 로컬 환경에서 부하를 생성한 서버와 측정 대상 서버가 같아서 결과에 오차가 있을 수 있다. EC2에서 분리 환경으로 돌리면 수치가 어떻게 달라질까?
