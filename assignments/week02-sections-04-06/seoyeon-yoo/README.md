# Week 02 - 유서연

## 캐시(Cache)

> 원본 저장소보다 더 빠르게 접근할 수 있는 임시 데이터 저장소

실제 서비스에서는 같은 데이터를 여러 번 반복해서 조회하는 경우가 많은데, 이때 매번 DB에 접근해서 데이터를 가져오면 요청이 많아질수록 응답 시간이 길어지고 DB 부하도 커진다.

이때, 자주 조회되거나 조회 비용이 큰 데이터를 더 빠른 저장소에 임시로 저장해두면, 이후 같은 요청이 들어왔을 때 DB까지 가지 않고 데이터를 반환할 수 있다. 이러한 방식을 **캐싱**이라고 한다.

이때, 캐시에 원하는 데이터가 존재하는 경우를 `Cache Hit`, 캐시에 데이터가 없어 원본 저장소까지 조회해야 하는 경우를 `Cache Miss`라고 한다.

## 캐싱 전략
> 캐시와 DB를 어떤 순서로 읽고 쓸지 정하는 방식

### 1️⃣ Cache Aside

> 애플리케이션이 캐시를 직접 관리하는 방식

조회 요청이 들어오면 먼저 캐시를 확인하고, 캐시에 데이터가 없을 때만 DB를 조회한다.

조회 요청 → 캐시 확인 → 캐시에 있으면 바로 반환
- → 캐시에 없으면 DB 조회 → 조회 결과를 캐시에 저장 → 결과 반환

Spring Boot에서는 `@Cacheable`을 사용해 구현한다.

```java
@Cacheable(value = "boards", key = "#id")
public BoardResponse getBoard(Long id) {
    Board board = boardRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

    return BoardResponse.from(board);
}
```

처음 요청에서는 캐시에 데이터가 없기 때문에 메서드가 실행되고 DB를 조회한다.
하지만, 같은 `id`로 다시 요청하면 메서드가 실행되지 않고, Redis에 저장된 캐시 값이 바로 반환된다.

즉, 자주 조회되는 데이터일수록 DB 접근 횟수를 줄이고 응답 속도를 개선할 수 있다.

#### 장점

- 자주 조회되는 데이터의 응답 속도를 개선할 수 있다.
- DB 조회 횟수를 줄일 수 있다.
- 필요한 데이터만 캐시에 저장하므로 메모리를 효율적으로 사용할 수 있다.

#### 한계점

- 캐시와 DB를 동시에 관리하는 방식이 아니기 때문에 데이터 불일치가 발생할 수 있다. (수정 반영 이전의 데이터가 조회될 수 있음)

### 2️⃣ Write Around

> 데이터를 저장하거나 수정할 때 캐시에 바로 반영하지 않고, DB에만 저장하는 방식

캐시는 이후 조회 요청이 들어왔을 때 필요하면 채워진다.

- 쓰기 요청 → DB에만 저장 → 캐시는 갱신하지 않음
- 조회 요청 → 캐시 확인 → 없으면 DB 조회 → 조회 결과를 캐시에 저장

예를 들어, 게시글을 생성할 때는 DB에만 저장하고, 해당 게시글이 실제로 조회될 때 캐시에 저장하는 방식이다.

```java
public Long createBoard(BoardCreateRequest request) {
    Board board = new Board(request.title(), request.content());
    return boardRepository.save(board).getId();
}
```

이후 조회 시에는 Cache Aside 방식으로 캐시에 저장된다.

```java
@Cacheable(value = "boards", key = "#id")
public BoardResponse getBoard(Long id) {
    Board board = boardRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

    return BoardResponse.from(board);
}
```

#### 장점

- 한 번도 조회되지 않을 데이터를 캐시에 저장하지 않아도 된다.
- 캐시 메모리를 불필요하게 사용하지 않는다.
- 쓰기 흐름이 비교적 단순하다.

#### 한계점

- 처음 조회할 때는 반드시 DB를 조회해야 한다. 따라서 첫 요청에서는 캐싱 효과를 얻을 수 없다.
- 기존 캐시가 남아 있는 상태에서 데이터가 수정되거나 삭제되면, Cache Aside와 마찬가지로 오래된 데이터가 반환될 수 있다.

### 3️⃣ Cache Aside, Write Around 전략의 공통 한계

두 전략 모두 캐시와 DB가 완전히 하나의 저장소처럼 동작하는 것 아니기 때문에, 다음과 같은 문제가 생길 수 있다.

1. 데이터 정합성 문제

DB는 바뀌었는데 캐시는 예전 데이터를 가지고 있을 수 있다.

2. Cache Miss 문제

캐시에 데이터가 없으면 결국 DB를 조회해야 한다.

3. 캐시 장애 문제

Redis가 죽으면 캐시를 사용할 수 없고, DB로 트래픽이 몰릴 수 있다.

4. 메모리 관리 문제

캐시는 메모리 기반이기 때문에 모든 데이터를 무한히 저장할 수 없다.

이를 줄이기 위해서는 보통 다음 방법을 함께 사용한다.

- TTL 설정
- 수정/삭제 시 캐시 제거
- 캐시 Key 설계
- 자주 조회되는 데이터 위주로 캐싱
- Redis 장애 시 DB 조회로 fallback 처리

즉, Redis를 붙였다고 해서 모든 조회 성능 문제가 해결되는 것은 아니고, 어떤 데이터를 얼마나 오래 캐싱할지 함께 고민해야 한다.

### 4️⃣ 캐싱 전에 SQL 튜닝을 먼저 해야 하는 이유

캐싱은 성능 개선에 도움이 되지만, 느린 SQL 자체를 해결하는 방법은 아니다.

따라서, 캐싱을 적용하기 전에 먼저 SQL 튜닝을 확인해야 한다!

```text
- 불필요하게 전체 데이터를 조회하고 있지 않은지
- WHERE 조건에 맞는 인덱스가 있는지
- ORDER BY에 인덱스를 활용할 수 있는지
- N+1 문제가 발생하고 있지 않은지
- 필요한 컬럼만 조회하고 있는지
- Pagination이 DB 쿼리 단계에서 적용되고 있는지
```

캐싱은 성능 개선을 위한 좋은 방법이지만, SQL 튜닝 이후에 반복 조회 비용을 줄이기 위해 사용하는 보조 전략에 가깝다.

<br>

## 로컬 환경에서 Spring Boot + Redis로 구현하기

### 1. Redis 실행하기

Spring Boot에서 Redis 캐시를 사용하려면 먼저 로컬에서 Redis 서버가 실행 중이어야 한다.

```bash
brew services start redis
redis-cli ping
```

`redis-cli ping` 명령어를 실행했을 때 `PONG`이 반환되면 Redis가 정상적으로 실행 중인 것이다.

### 2. 의존성 추가하기

`build.gradle`에 Redis와 Cache 관련 의존성을 추가한다.

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-cache'
}
```

- `spring-boot-starter-data-redis`: Spring Boot에서 Redis에 연결하기 위한 의존성
- `spring-boot-starter-cache`: `@Cacheable`, `@CachePut`, `@CacheEvict` 같은 캐시 추상화 기능을 사용하기 위한 의존성

### 3. Redis 설정 추가하기

`application.yml`에 Redis 연결 정보를 추가한다.

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      database: 0
```

로컬 Redis는 기본적으로 `localhost:6379`에서 실행된다.

캐시 기능을 사용하려면 메인 클래스에 `@EnableCaching`을 추가해야 한다.

```java
@SpringBootApplication
@EnableCaching
public class RedisInSpringApplication {

    public static void main(String[] args) {
        SpringApplication.run(RedisInSpringApplication.class, args);
    }
}
```

`@EnableCaching`을 추가해야 Spring이 `@Cacheable`, `@CachePut`, `@CacheEvict` 같은 캐시 어노테이션을 인식하고 동작시킬 수 있다.

### 4. 캐시 적용

#### 조회: `@Cacheable`

```java
@Cacheable(value = "boards", key = "#id")
public BoardResponse getBoard(Long id) {
    Board board = boardRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

    return BoardResponse.from(board);
}
```

- 처음 요청에서는 캐시에 데이터가 없기 때문에 DB를 조회한다.
- 이후 같은 `id`로 다시 요청하면 Redis에 저장된 캐시 값을 반환한다.
- 즉, 반복 조회가 많은 데이터에 적용하면 DB 접근 횟수를 줄일 수 있다.

#### 수정/삭제: `@CacheEvict`

```java
@CacheEvict(value = "boards", key = "#id")
public void deleteBoard(Long id) {
    boardRepository.deleteById(id);
}
```

- 게시글이 수정/삭제되면 기존 캐시를 제거한다.
- 이후 같은 데이터를 다시 조회하면 Cache Miss가 발생한다.
- 이때 DB에서 최신 데이터를 조회하고, 다시 캐시에 저장할 수 있다.

#### TTL 설정

```java
@Configuration
public class RedisCacheConfig {

    @Bean
    public RedisCacheManager redisCacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(10));

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(config)
                .build();
    }
}
```

- TTL을 적용하면 캐시가 무한히 남는 것을 막을 수 있다.
- 오래된 데이터가 계속 조회되는 문제도 줄일 수 있다.

#### Redis 캐시 확인

```bash
redis-cli
keys *
```

- 캐시가 적용되었다면 API를 호출한 뒤 Redis CLI에서 Spring Cache가 만든 key를 확인할 수 있다.
- Spring Cache는 직렬화 방식에 따라 `get key`로 값을 바로 읽기 어려울 수 있다.
- 처음에는 키가 생성되었는지만 확인해도 캐시 적용 여부를 볼 수 있다.

<br>

## `@Cacheable`, `@CachePut`, `@CacheEvict` 차이

Spring Cache에서는 캐시를 다루기 위해 대표적으로 `@Cacheable`, `@CachePut`, `@CacheEvict`를 사용할 수 있다.

### `@Cacheable`

**캐시에 데이터가 있으면 메서드를 실행하지 않고, 캐시에 저장된 값을 바로 반환**한다.

캐시에 데이터가 없을 때만 메서드가 실행되고, 실행 결과가 캐시에 저장된다.

```java
@Cacheable(value = "boards", key = "#id")
public BoardResponse getBoard(Long id) {
    Board board = boardRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

    return BoardResponse.from(board);
}
```

즉, `@Cacheable`은 조회 성능을 개선할 때 주로 사용된다.

### `@CachePut`

**캐시 존재 여부와 관계없이 메서드를 항상 실행**한다. 그리고, 메서드 실행 결과를 캐시에 저장하거나 갱신한다.

```java
@CachePut(value = "boards", key = "#id")
public BoardResponse updateBoard(Long id, BoardUpdateRequest request) {
    Board board = boardRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

    board.update(request.title(), request.content());

    return BoardResponse.from(board);
}
```

`@Cacheable`이 캐시에 값이 있으면 메서드를 실행하지 않는 것과 달리, `@CachePut`은 항상 메서드를 실행한다.

따라서, DB 수정 작업을 수행한 뒤, 수정된 결과를 캐시에 바로 반영하고 싶을 때 사용할 수 있다.

### `@CacheEvict`

**캐시에 저장된 데이터를 제거**할 때 사용한다.

게시글을 수정하거나 삭제했는데 캐시를 그대로 두면, 이후 조회 시 수정 전 데이터가 반환될 수 있다.

이때, 기존 캐시를 삭제하면 다음 조회 요청에서 DB의 최신 데이터를 다시 가져와 캐시에 저장할 수 있다.

```java
@CacheEvict(value = "boards", key = "#id")
public void deleteBoard(Long id) {
    boardRepository.deleteById(id);
}
```

### 차이 정리

| 어노테이션 | 메서드 실행 여부 | 캐시 동작 | 주 사용 상황 |
| --- | --- | --- | --- |
| `@Cacheable` | 캐시에 값이 없을 때만 실행 | 조회 결과를 캐시에 저장 | 조회 성능 개선 |
| `@CachePut` | 항상 실행 | 실행 결과로 캐시 갱신 | 수정 후 캐시도 최신 값으로 갱신 |
| `@CacheEvict` | 보통 메서드 실행 후 동작 | 캐시 삭제 | 수정/삭제 후 기존 캐시 제거 |
