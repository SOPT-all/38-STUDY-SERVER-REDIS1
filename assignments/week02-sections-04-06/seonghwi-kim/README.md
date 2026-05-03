# Week 02 - 김성휘

# 2 주차 - 섹션 4, 5, 6

# 섹션 4 -  Redis 캐싱 전략

## **캐시(Cache), 캐싱(Caching)이란?**

캐시: 원본 저장소보다 **빠르게** 가져올 수 있는 **임시 데이터 저장소**

캐싱: 캐시에 접근해서 데이터를 빠르게 가져오는 방식

---

## **데이터를 캐싱할 때 사용하는 전략 (Cache Aside, Write Around)**

→ 현업에서 가장 많이 사용하는 전략 두 가지를 공부

### 1. Cache Aside (= Look Aside, Lazy Loading 전략

캐시에서 데이터를 확인하고, 없으면 DB에서 조회하는 방식.
데이터를 어떻게 **조회**할 지에 대한 전략.

1) Cache Hit: 캐시에 데이터가 있는 경우

2) Cache Miss: 캐시에 데이터가 없는 경우

### 2. Write Around 전략

쓰기 작업(저장, 수정, 삭제)을 캐시에는 반영하지 않고, DB에만 반영하는 방식.
데이터를 어떻게 **쓸지(저장, 수정, 삭제)**에 대한 전략.

---

## **Cache Aside, Write Around 전략의 한계점 / 해결 방법**

### Cache Aside, Write Around 전략의 한계점

1. 캐시된 데이터와 DB 데이터가 불일치할 수도 있다.

   → 데이터의 일관성을 보장할 수 없다!

2. 캐시에 저장할 수 있는 공간이 비교적 작다.

   → 캐시는 메모리(RAM)에 저장하기 때문에, DB에 비해 많은 양의 데이터를 저장할 수 없다. (Redis의 한계점)


### **극복 방법**

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

# 섹션 5 - 로컬 환경에서 Spring Boot + Redis 로 구현하기

## **기본적인 Spring Boot 프로젝트 셋팅하기**

boards:page:1:size:19

→ 게시글들의 1번 페이지의 사이즈가 10 개 짜리의 데이터

`@Cacheable`  을 사용하여 Cache Aside 전략으로 캐싱 적용: 해당 메서드 요청이 들어옴 → 먼저 레디스의 데이터를 조회 후 응답(Cache Hit) → 데이터가 없다면(Cache Miss), 메서드 내부의 로직(DB 조회)을 실행한 후 return 값으로 응답 → 그 return 값을 레디스에 저장

**[속성 값 설명]**

- `cacheNames` : 캐시 이름을 설정
- `key` : Redis에 저장할 Key의 이름을 설정

  [Redis에서 Key 네이밍 컨벤션 익히기](https://www.notion.so/Redis-Key-590f7cc86aff4982b1eca3a9c8368529?pvs=21)

- `cacheManager` : 사용할 `cacheManager` (`boardCacheManager` 클래스) 의 Bean 이름을 지정

![image.png](attachment:e104d3aa-da09-4451-9675-095508bb402c:image.png)

```prolog
2026-05-03T23:47:36.079+09:00 TRACE 7868 --- [nio-8080-exec-3] o.s.cache.interceptor.CacheInterceptor   : No cache entry for key 'boards:page:1:size:10' in cache(s) [getBoards]
Hibernate: select b1_0.id,b1_0.content,b1_0.created_at,b1_0.title from boards b1_0 order by b1_0.created_at desc limit ?
Hibernate: select count(b1_0.id) from boards b1_0
2026-05-03T23:47:36.915+09:00 TRACE 7868 --- [nio-8080-exec-3] o.s.cache.interceptor.CacheInterceptor   : Creating cache entry for key 'boards:page:1:size:10' in cache(s) [getBoards]
```

→ No cache → DB 조회해서 SQL문 실행 → create cache(DB에서 조회한 데이터를 캐시에 저장)

![image.png](attachment:4d4ccc3c-8387-4041-b3e0-132c4e3aa419:image.png)

```prolog
2026-05-03T23:48:59.339+09:00 TRACE 7868 --- [nio-8080-exec-7] o.s.cache.interceptor.CacheInterceptor   : Computed cache key 'boards:page:1:size:10' for operation Builder[public java.util.List com.example.redisinspring.BoardService.getBoards(int,int)] caches=[getBoards] | key=''boards:page:' + #page + ':size:' + #size' | keyGenerator='' | cacheManager='boardCacheManager' | cacheResolver='' | condition='' | unless='' | sync='false'
2026-05-03T23:48:59.343+09:00 TRACE 7868 --- [nio-8080-exec-7] o.s.cache.interceptor.CacheInterceptor   : Cache entry for key 'boards:page:1:size:10' found in cache(s) [getBoards]

```

→ Cache entry (캐시에서 데이터를 꺼냄 / SQL 쿼리는 X)

redis-cli 로 확인

![image.png](attachment:2be8c7c2-d566-4755-aea1-7d462afd3f88:image.png)

---

# 섹션 6 - [보충 강의] 로컬 환경에서 Nest.js + Redis 로 구현하기

## 기본적인 Nest.js 프로젝트 셋팅하기