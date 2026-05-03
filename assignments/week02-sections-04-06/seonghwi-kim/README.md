# 2 주차 - 섹션 4, 5, 6

# 🚀 섹션 4 -  Redis 캐싱 전략

## **캐시(Cache), 캐싱(Caching)이란?**

캐시: 원본 저장소보다 **빠르게** 가져올 수 있는 **임시 데이터 저장소**

캐싱: 캐시에 접근해서 데이터를 빠르게 가져오는 방식

---

## **데이터를 캐싱할 때 사용하는 전략 (Cache Aside, Write Around)**

→ 현업에서 가장 많이 사용하는 전략 두 가지를 공부

### 1. Cache Aside (= Look Aside, Lazy Loading 전략 🔍

캐시에서 데이터를 확인하고, 없으면 DB에서 조회하는 방식.
데이터를 어떻게 **조회**할 지에 대한 전략.

1) Cache Hit: 캐시에 데이터가 있는 경우 ✅

2) Cache Miss: 캐시에 데이터가 없는 경우 ❌

### 2. Write Around 전략 ✍️

쓰기 작업(저장, 수정, 삭제)을 캐시에는 반영하지 않고, DB에만 반영하는 방식.
데이터를 어떻게 **쓸지(저장, 수정, 삭제)**에 대한 전략.

---

## **Cache Aside, Write Around 전략의 한계점 / 해결 방법**

### **⚠️** Cache Aside, Write Around 전략의 한계점

1. 캐시된 데이터와 DB 데이터가 불일치할 수도 있다.

   → 데이터의 일관성을 보장할 수 없다!

2. 캐시에 저장할 수 있는 공간이 비교적 작다.

   → 캐시는 메모리(RAM)에 저장하기 때문에, DB에 비해 많은 양의 데이터를 저장할 수 없다. (Redis의 한계점)


### **🛠️ 극복 방법**

1. 캐시된 데이터와 DB 데이터의 불일치 문제

   → 성능 향상과 데이터 일관성은 **Trade Off** 관계이므로 다음과 같은 데이터에 캐시를 적용하는 게 적절

   - 자주 조회되는 데이터
   - 잘 변하지 않는 데이터
   - 실시간으로 정확하게 일치하지 않아도 되는 데이터

   데이터의 불일치를 해결하기 위해
   적절한 주기로 데이터를 동기화시켜 주어야 하므로, TTL 기능(Time To Live, 만료 시간 설정 기능)을 활용!
   → 일정 시간이 지나면 캐시 삭제 → 데이터 조회 → Cache Miss 발생 → DB에서 새롭게 조회하면서 데이터를 캐시 (새로운 데이터 갱신!) (완전 극복은 아니고, 단점을 보완 한정도,,)

2. 캐시에 저장할 수 있는 공간이 비교적 작다.

   TTL 기능을 활용하여 캐시의 공간을 효율적으로 사용 가능! (자주 조회하지 않는 데이터는 만료 시간에 의해 데이터가 삭제됨)


→ Cache Aside, Write Around 전략을 사용할 때, 주로 **TTL**을 같이 활용!

---

## **캐싱으로 조회 성능 개선을 하기 전 OOO을 항상 먼저해야 한다!**

### 데이터 조회 성능을 개선하는 방법

- SQL 튜닝
- 캐싱 서버 활용 (Redis 등)
- 레플리케이션 (Master/Slave 구조)
- 샤딩
- DB 스케일업 (CPU, Memory, SSD 등 하드웨어 업그레이드)

### 이 중에서 **`SQL 튜닝`** 을 가장 먼저 고려해야 한다!!!

1. SQL 튜닝을 제외한 나머지 방법은 추가적인 비용이 발생!

   추가적인 시스템 구축 → 금전적, 시간적 비용이 추가 발생 → 더 복잡해진 시스템 구조로 인한 관리 비용이 증가

   그에 비해 SQL 튜닝은 기존의 시스템 변경 없이 성능을 개선 가능!

2. 근본적인 문제를 해결하는 방법은 SQL 튜닝일 가능성이 높다.

   SQL 자체가 비효율적으로 작성됐다면, 아무리 시스템적으로 성능을 개선하더라도 한계가 존재.

   SQL 튜닝으로 성능 향상시킨다면,
   시스템적인 성능 개선이 필요 없거나 훨씬 큰 성능 개선 효과를 얻을 수 있음


→ 가장 가성비 좋은 방법이 SQL 튜닝!!!

혹시나 **SQL 튜닝**에 대한 기본기를 다지고 싶다면 아래 강의를 추천

[비전공자도 이해할 수 있는 MySQL 성능 최적화 입문/실전 (SQL 튜닝편) 강의 | JSCODE 박재성 - 인프런](https://inf.run/7QHc5)

---

# 🌱 섹션 5 - 로컬 환경에서 Spring Boot + Redis 로 구현하기

## **기본적인 Spring Boot 프로젝트 셋팅하기**

boards:page:1:size:19

→ 게시글들의 1번 페이지의 사이즈가 10 개 짜리의 데이터

`@Cacheable`  을 사용하여 Cache Aside 전략으로 캐싱 적용: 해당 메서드 요청이 들어옴 → 먼저 레디스의 데이터를 조회 후 응답(Cache Hit) → 데이터가 없다면(Cache Miss), 메서드 내부의 로직(DB 조회)을 실행한 후 return 값으로 응답 → 그 return 값을 레디스에 저장

**[속성 값 설명]**

- `cacheNames` : 캐시 이름을 설정
- `key` : Redis에 저장할 Key의 이름을 설정
- `cacheManager` : 사용할 `cacheManager` (`boardCacheManager` 클래스) 의 Bean 이름을 지정

<img width="1666" height="109" alt="스크린샷 2026-05-03 234754" src="https://github.com/user-attachments/assets/1b4570a8-775f-4bfb-88cb-6a43a6ddb575" />

```prolog
2026-05-03T23:47:36.079+09:00 TRACE 7868 --- [nio-8080-exec-3] o.s.cache.interceptor.CacheInterceptor   : No cache entry for key 'boards:page:1:size:10' in cache(s) [getBoards]
Hibernate: select b1_0.id,b1_0.content,b1_0.created_at,b1_0.title from boards b1_0 order by b1_0.created_at desc limit ?
Hibernate: select count(b1_0.id) from boards b1_0
2026-05-03T23:47:36.915+09:00 TRACE 7868 --- [nio-8080-exec-3] o.s.cache.interceptor.CacheInterceptor   : Creating cache entry for key 'boards:page:1:size:10' in cache(s) [getBoards]
```

→ No cache → DB 조회해서 SQL문 실행 → create cache(DB에서 조회한 데이터를 캐시에 저장)

<img width="1768" height="76" alt="스크린샷 2026-05-03 234914" src="https://github.com/user-attachments/assets/fb63d2ba-e619-419b-a521-91bc486d12be" />

```prolog
2026-05-03T23:48:59.339+09:00 TRACE 7868 --- [nio-8080-exec-7] o.s.cache.interceptor.CacheInterceptor   : Computed cache key 'boards:page:1:size:10' for operation Builder[public java.util.List com.example.redisinspring.BoardService.getBoards(int,int)] caches=[getBoards] | key=''boards:page:' + #page + ':size:' + #size' | keyGenerator='' | cacheManager='boardCacheManager' | cacheResolver='' | condition='' | unless='' | sync='false'
2026-05-03T23:48:59.343+09:00 TRACE 7868 --- [nio-8080-exec-7] o.s.cache.interceptor.CacheInterceptor   : Cache entry for key 'boards:page:1:size:10' found in cache(s) [getBoards]

```

→ Cache entry (캐시에서 데이터를 꺼냄 / SQL 쿼리는 X)

redis-cli 로 확인

<img width="1097" height="342" alt="스크린샷 2026-05-03 235247" src="https://github.com/user-attachments/assets/4591c259-fb2a-4ea5-b21a-dadc893110ab" />

## **Redis를 적용하기 전후 성능 비교해보기 (Postman)**

### 성능 개선

성능 개선을 할 때는, 반드시 **수치를 측정하면서 비교**해야 한다!!

1. Redis 캐시 사용 전 → 평균 약 350 ms

   <img width="1484" height="862" alt="스크린샷 2026-05-04 004031" src="https://github.com/user-attachments/assets/cc1d55e1-6ccd-47dd-ba18-b171bee17a0a" />

2. Redis 캐시 사용 후 → 평균 약 14 ms

   <img width="1499" height="867" alt="스크린샷 2026-05-04 004326" src="https://github.com/user-attachments/assets/80680b67-2eda-4e9f-a106-52e3409eec26" />


결과: Redis 캐시 적용 전 평균 응답 시간은 약 350ms였고, 적용 후 약 14ms로 감소하여 **약 25배의 성능 향상**을 확인했다.
---

# 섹션 6 - [보충 강의] 로컬 환경에서 Nest.js + Redis 로 구현하기

## 기본적인 Nest.js 프로젝트 셋팅하기

---

## 추가 학습 내용

### 데이터 조회 성능을 개선하는 방법

데이터 조회 성능을 개선하는 방법에는 SQL 튜닝, 캐싱 서버 활용, 레플리케이션, 샤딩, DB 스케일업 등이 있다.

- **SQL 튜닝(SQL Tuning, SQL 성능 개선)**  
  비효율적인 쿼리를 개선해서 DB가 데이터를 더 빠르게 조회하도록 하는 방법이다.  
  추가 인프라 비용 없이 기존 쿼리를 개선할 수 있기 때문에 가장 먼저 고려하는 것이 좋다.

- **캐싱 서버 활용(Caching Server, 캐싱 서버)**  
  자주 조회되는 데이터를 Redis 같은 캐시에 저장해두고, DB를 매번 조회하지 않고 빠르게 응답하는 방법이다.

- **레플리케이션(Replication, 복제)**  
  DB를 여러 대로 복제하고, 조회 요청을 Slave DB로 분산시켜 Master DB의 부하를 줄이는 방법이다.
  - Master DB는 데이터 생성·수정·삭제 같은 **쓰기 작업**을 담당하는 주 DB
  - Slave DB는 Master DB의 데이터를 복제해두고, 주로 **조회 작업**을 처리해서 부하를 분산하는 보조 DB
  - ex) 게시글 서비스에서 사용자가 게시글을 작성하거나 수정하면 **Master DB**에 저장된다.  
    다른 사용자들이 게시글 목록을 조회할 때는 **Slave DB**에서 데이터를 읽어와서 Master DB의 부담을 줄일 수 있다.

- **샤딩(Sharding, 데이터 분산 저장)**  
  데이터를 여러 DB에 나누어 저장해서 한 DB에 데이터와 요청이 몰리는 문제를 줄이는 방법이다.
  - ex) 회원 데이터가 너무 많아 하나의 DB에서 처리하기 어려워지면,  
    회원 ID를 기준으로 데이터를 여러 DB에 나누어 저장할 수 있다. 
    - 1번 DB: userId 1 ~ 10000
    - 2번 DB: userId 10001 ~ 20000
    - 3번 DB: userId 20001 ~ 30000
    이처럼 데이터를 여러 DB에 분산 저장해서 한 DB에 데이터와 요청이 몰리는 문제를 줄이는 방식이 **샤딩(Sharding, 데이터 분산 저장)**이다.

- **DB 스케일업(Scale Up, 서버 성능 향상)**  
  DB 서버의 CPU, Memory, SSD 등을 업그레이드해서 서버 자체의 처리 성능을 높이는 방법이다.
  - ex) 게시글 조회 요청이 많아져 DB 서버가 느려졌을 때,  
    DB 서버의 CPU를 더 좋은 성능으로 바꾸거나 Memory를 늘리고, HDD 대신 SSD를 사용하는 방식이 **DB 스케일업(Scale Up, 서버 성능 향상)**이다.

---

### Redis 캐시 사용 시 주의할 점

Redis를 사용하면 조회 성능을 개선할 수 있지만, 캐시 운영 과정에서 주의해야 할 문제들도 있다.

- **Cache Stampede(캐시 스탬피드)**  
  특정 캐시가 만료되는 순간 여러 요청이 동시에 DB로 몰리는 문제이다.  
  이를 방지하기 위해 TTL(Time To Live, 만료 시간)을 적절히 분산하거나, Lock 기반 캐시 재생성 전략을 사용할 수 있다.
    - Lock 기반 캐시 재생성 전략: 캐시가 만료됐을 때 여러 요청이 동시에 DB를 조회하지 못하도록, 하나의 요청만 Lock(잠금)을 얻어 DB에서 데이터를 가져와 캐시를 다시 만들게 하는 방식
      - ex) 인기 게시글 캐시가 만료됐을 때 요청 100개가 동시에 들어오면,  
        그중 1개 요청만 Lock을 얻어 DB를 조회하고 캐시를 갱신한다.  
        나머지 요청들은 잠시 기다렸다가 새로 생성된 캐시 데이터를 사용한다.

- **Cache Penetration(캐시 침투)**  
  존재하지 않는 데이터를 계속 조회해서 매번 캐시를 거치지 못하고 DB까지 요청이 전달되는 문제이다.  
  이를 방지하기 위해 빈 결과도 짧은 TTL로 캐싱하거나, Bloom Filter(블룸 필터)를 활용할 수 있다.

- **Eviction Policy(데이터 제거 정책)**  
  Redis는 메모리 기반 저장소이기 때문에 메모리가 부족해질 경우 어떤 데이터를 제거할지 정책을 설정할 수 있다.  
  대표적인 방식으로는 LRU(Least Recently Used, 가장 오래 사용되지 않은 데이터 제거)와 LFU(Least Frequently Used, 가장 적게 사용된 데이터 제거)가 있다.


## 트러블슈팅 / 인사이트

- MySQL 콘솔에서 DB를 선택하지 않아 `No database selected` 오류가 발생했습니다. `USE mydb;`로 사용할 데이터베이스를 지정한 뒤 INSERT를 재실행하여 해결했습니다.

## 리뷰 포인트

- 조회 성능 개선을 위해 Redis 캐시를 적용할 때, TTL을 어느 정도로 설정하는 것이 적절할지,,,
