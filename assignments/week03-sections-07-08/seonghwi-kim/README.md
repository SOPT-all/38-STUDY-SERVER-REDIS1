# Week 03 - 김성휘

이번 주 학습 내용을 여기에 정리합니다.

# 3 주차 - 섹션 7, 8

# 🚀 섹션 7 -  AWS EC2에서 Redis 활용하기

## **💸 대략적으로 AWS 비용 얼마나 나오는 지**

- EC2 인스턴스 (t3a.small) → 하루에 1달러 정도
- RDS 인스턴스 (t4g.micro) → 하루에 1달러 정도
- 캐시 (cache.t3micro)  → 하루에 850원 정도
- 혹시나 비용이 많이 나가고 있는 건 아닌 지 체크하는 방법
    - 청구서 → 서비스별 요금 확인하기

## **🏗️ EC2, RDS, Spring Boot, Redis를 활용한 아키텍처 구성**

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/38e15ac7-1003-4f46-b18f-ec69c82c0e81/Untitled.png)

- EC2 내부에 Spring 과 Redis를 같이 설치 (서로 통신할 수 있게 세팅)
- RDS 를 스프링의 데이터 베이스 이용

---

## **⚙️ EC2, RDS, Spring Boot, Redis 셋팅**

### 🖥️ EC2

- 인스턴스 유형: `t.small` (`t.micro`는 Spring과 Redis를 동시에 돌리면 서버가 죽을 수도 있음)
- 네트워크 설정
    - VPC는 기본값으로
    - 보안그룹

      ![image.png](attachment:804badcf-f632-4ef9-8bc1-c406be7d6474:image.png)

    - 나머지는 기본값으로 해서 인스턴스 생성하기

## **🗄️ RDS**

데이터 베이스 생성(전체 구성) → MySQL → 템플릿: 프리티어 → 가용성 및 내구성: 단일 AZ DB 인스턴스 배포(인스턴스 1개) → DB 인스턴스 식별자(DB 이름 설정)

![image.png](attachment:4a046147-eec5-4c41-8287-f757f9ac30b0:image.png)

나머지는 디폴트로 하고, 퍼블릭 엑세스를 ‘예’로 설정 (외부에서 DB로 접근을 쉽게 하기 위해서)

추가 구성 → 초기 데이터베이스 이름 설정 → 자동 백업 해제 → 데이터 베이스 생성

![image.png](attachment:5404b513-99db-44ce-b76d-8be95f460b74:image.png)

생성된 RDS에 들어가서 보안그룹 수정 → 인바운드 규칙 편집 → MySQL(3306), 모든 IPv4 허용으로 추가 → 규칙 저장

![image.png](attachment:409c79d8-3e44-4820-8206-2555395182f6:image.png)

방금 만든 EC2 를 연결(원격 접속)

### ✅ EC2에 Redis 설치

1. **Redis 설치하기**

    ```
    $ sudo apt update
    $ sudo apt install redis
    ```


1. **Redis 잘 설치됐는 지 확인**

    ```bash
    $ redis-cli
    
    127.0.0.1:6379> ping
    PONG
    ```

   ![image.png](attachment:be4bd851-c6cb-4cf9-af8f-9e3fa83daf50:image.png)


### ✅ EC2에 Spring Boot 프로젝트 셋팅하기

1. **JDK 설치하기**

   Spring Boot는 3.x.x 버전을 사용할 예정이고, JDK는 17버전을 사용할 예정이다. 그에 맞게 환경을 설치해보자.

    ```tsx
    $ sudo apt install openjdk-17-jdk
    ```


1. **잘 설치됐는 지 확인하기**

    ```bash
    $ java -version
    ```

   ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/0f47cefa-3896-4c11-91cd-0d5d3f51f9f0/Untitled.png)


1. **Spring Boot 프로젝트에서 application.yml 정보 수정하기**

   **application.yml**

    ```yaml
    # local 환경
    spring:
      profiles:
        default: local
      datasource:
        url: jdbc:mysql://localhost:3306/mydb
        username: root
        password: password
        driver-class-name: com.mysql.cj.jdbc.Driver
      jpa:
        hibernate:
          ddl-auto: update
        show-sql: true
      data:
        redis:
          host: localhost
          port: 6379
    
    logging:
      level:
        org.springframework.cache: trace 
    
    ---
    # prod 환경
    spring:
      config:
        activate:
          on-profile: prod
      datasource:
        url: jdbc:mysql://**{rds 주소}**:3306/mydb
        username: **admin**
        password: **password**
    ```

   rds 주소는 생성했던 RDS 엔드포인트 복붙하기


1. **EC2로부터 Github Clone 받기**

    ```bash
    $ git clone {Github Repository 주소}
    $ cd {프로젝트 경로}
    ```

   applicaion.yml 파일 수정하기

2. **서버 실행시키기**

```bash
# ./gradlew 실행 권한 추가
cd ~/seonghwi.kim
chmod +x gradlew
./gradlew clean build -x test
```

```bash
# 스프링 프로젝트 경로로 들어가서 아래 명령어 실행
$ ./gradlew clean build -x test 
$ cd build/libs
$ java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명}
```

정상적으로 서버가 실행되는 걸 확인할 수 있다.
그리고 JPA의 ddl 옵션으로 인해 테이블도 생성이 된다.

인텔리제이에서 database 생성 → 이름 수정 → Host 칸에 ‘RDS 엔드포인트’ 입력 → User / Password 입력 → Test Connection 성공하는지 확인하기

![image.png](attachment:b80e4d07-7c29-4ccb-9901-fb1b4c87be26:image.png)

만약 연결이 안된다면, RDS의 보안 그룹에서 3306 port를 열어 놓았는지 확인하기!!

모든 스키마 보기 클릭 → mydb가 이미 생성 되어있는 걸 확인 가능 (RDS의 초기 데이터베이스 이름을 `mydb` 로 설정했기 때문) → table 이 생성된 걸 확인 가능 (EC2에서 Spring 서버를 띄울 때, RDS와 연결되면서 테이블 정보를 업데이트 함!)

![image.png](attachment:35214c12-b45a-49aa-89e8-9aa945c8a75a:image.png)

mydb 오른쪽클릭 → New → Query Console → RDS에 더미데이터 넣기

### 더미 유저 1,000명 생성

```sql
# 게시글 작성자로 쓸 유저를 1,000명 넣기
INSERT INTO users (nickname, email, created_at, updated_at)
SELECT
    CONCAT('user', n),
    CONCAT('user', n, '@test.com'),
    NOW(),
    NOW()
FROM (
    SELECT
        a.n
        + b.n * 10
        + c.n * 100
        + 1 AS n
    FROM
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
) numbers
WHERE n <= 1000;
```

확인:

```sql
SELECT COUNT(*) FROM users;
```

---

### 게시글 100만 개 생성

```sql
INSERT INTO posts (
    title,
    content,
    is_anonymous,
    board_type,
    user_id,
    created_at,
    updated_at
)
SELECT
    CONCAT('더미 게시글 제목 ', n) AS title,
    CONCAT('Redis 캐시 성능 테스트용 더미 게시글 내용입니다. 게시글 번호: ', n) AS content,
    IF(n % 2 = 0, TRUE, FALSE) AS is_anonymous,
    CASE
        WHEN n % 3 = 0 THEN 'FREE'
        WHEN n % 3 = 1 THEN 'HOT'
        ELSE 'SECRET'
    END AS board_type,
    ((n - 1) % 1000) + 1 AS user_id,
    NOW() - INTERVAL (n % 365) DAY AS created_at,
    NOW() - INTERVAL (n % 365) DAY AS updated_at
FROM (
    SELECT
        a.n
        + b.n * 10
        + c.n * 100
        + d.n * 1000
        + e.n * 10000
        + f.n * 100000
        + 1 AS n
    FROM
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) f
) numbers
WHERE n <= 1000000;
```

---

### 개수 확인

```sql
SELECT COUNT(*) FROM posts;
```

게시판 타입 별로도 확인:

```sql
SELECT board_type, COUNT(*)
FROM posts
GROUP BY board_type;
```

예상 결과

```
FREE    약 333333개
HOT     약 333334개
SECRET  약 333333개
```

---

## **Redis를 적용하기 전후 성능 비교해보기 (Postman)**

postman에서 EC2 퍼블릭 IP로 요청 보내기

![image.png](attachment:c9f12334-e383-4f11-93f8-9ae6a2ea6279:image.png)

5.15 초

![image.png](attachment:eaa67d36-5e2b-4630-ae84-3b8604411e58:image.png)

3.94 초

생각보다 드라마틱하게 줄지 않네… 라고 생각했다.

### 🚨 근데 여기서 문제!!

### 🚨 현재 코드만으로는 Spring 애플리케이션이 Redis를 캐시 저장소로 사용할 수 없는 상태

Spring Boot에서 캐시(Cache, 임시 저장소)를 쓰려면 캐싱 기능을 활성화해야 하고, Spring Boot 공식 문서 기준으로 `@EnableCaching`이 있어야 캐시 인프라가 자동 설정돼. 또한 실제 캐시 대상 메서드에는 `@Cacheable` 같은 캐시 애노테이션이 있어야 하는데, 과제 레포를 가져와서 없었다..

### 🤔 그렇다면 5.15초 → 3.94초는 왜 줄었을까?!?

1. **JVM(Java Virtual Machine, 자바 실행 환경) 워밍업**
2. **DB 커넥션 풀(Connection Pool, DB 연결 재사용 공간) 초기화 이후 재사용**
3. **MySQL/RDS 내부 버퍼 캐시(Buffer Cache, DB가 자주 읽은 데이터를 메모리에 올려두는 것)**
4. **OS 파일 캐시**
5. **네트워크 지연 편차**
6. **Postman 자체 측정 편차**

특히 첫 요청은 느리고, 두 번째 요청부터 빨라지는 건 Redis가 없어도 흔히 발생한다고 한다…

→ LLM을 이용해 내 프로젝트에 맞춰서 빠르게 **실습용 Redis 응답 캐시(Filter)** 추가

---

## 🤖 LLM 이용

## 1. 프로젝트 루트로 이동

```
cd ~/seonghwi.kim
```

---

## 2. Redis 의존성 추가

```
python3<<'PY'
from pathlib import Path

path = Path("build.gradle")
text = path.read_text()

redis_deps = """implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-cache'"""

if "spring-boot-starter-data-redis" not in text:
    text = text.replace(
        "implementation 'org.springframework.boot:spring-boot-starter-data-jpa'",
        "implementation 'org.springframework.boot:spring-boot-starter-data-jpa'\n    " + redis_deps
    )

path.write_text(text)
PY
```

확인:

```bash
grep-n"redis\|cache" build.gradle
```

정상이라면 아래처럼.

```bash
implementation 'org.springframework.boot:spring-boot-starter-data-redis'
implementation 'org.springframework.boot:spring-boot-starter-cache'
```

---

## 3. Redis 응답 캐시 필터 추가

```bash
mkdir-p src/main/java/org/sopt/global/config

cat > src/main/java/org/sopt/global/config/RedisResponseCacheFilter.java<<'EOF'
package org.sopt.global.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RedisResponseCacheFilter extends OncePerRequestFilter {

    private static final Duration CACHE_TTL = Duration.ofMinutes(10);

    private final StringRedisTemplate redisTemplate;

    public RedisResponseCacheFilter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isCacheTarget(request);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String cacheKey = buildCacheKey(request);

        String cachedBody = redisTemplate.opsForValue().get(cacheKey);

        if (cachedBody != null) {
            response.setStatus(HttpServletResponse.SC_OK);
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setHeader("X-Redis-Cache", "HIT");
            response.getWriter().write(cachedBody);
            return;
        }

        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(response);

        try {
            filterChain.doFilter(request, responseWrapper);
        } finally {
            byte[] body = responseWrapper.getContentAsByteArray();

            if (responseWrapper.getStatus() == HttpServletResponse.SC_OK && body.length > 0) {
                Charset charset = getResponseCharset(responseWrapper);
                String responseBody = new String(body, charset);

                redisTemplate.opsForValue().set(cacheKey, responseBody, CACHE_TTL);
                responseWrapper.setHeader("X-Redis-Cache", "MISS");
            }

            responseWrapper.copyBodyToResponse();
        }
    }

    private boolean isCacheTarget(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && "/api/v1/posts".equals(request.getRequestURI());
    }

    private String buildCacheKey(HttpServletRequest request) {
        String queryString = request.getQueryString();

        if (queryString == null || queryString.isBlank()) {
            return "posts:list";
        }

        return "posts:list:" + queryString;
    }

    private Charset getResponseCharset(ContentCachingResponseWrapper responseWrapper) {
        String characterEncoding = responseWrapper.getCharacterEncoding();

        if (characterEncoding == null || characterEncoding.isBlank()) {
            return StandardCharsets.UTF_8;
        }

        return Charset.forName(characterEncoding);
    }
}
EOF
```

---

## 4. Redis 실행 상태 확인

```
sudo systemctl status redis-server
```

켜져 있지 않으면:

```
sudo systemctl enable redis-server
sudo systemctlstart redis-server
```

Redis 연결 확인:

```
redis-cliping
```

정상이면:

```
PONG
```

---

## 5. 기존 Redis 데이터 비우기

```
redis-cli flushall
redis-cli dbsize
```

정상이라면:

```
OK
(integer) 0
```

---

## 6. 다시 빌드

```
cd ~/seonghwi.kim
./gradlew clean build-x test
```

---

## 7. 서버 실행

```
java-jar build/libs/assignment-1.0-SNAPSHOT.jar--spring.profiles.active=prod
```

---

## 8. Postman으로 다시 테스트

---

![image.png](attachment:10551545-73cf-4662-934f-8171f76566b7:image.png)

4.89 초

![image.png](attachment:578ffb4d-2005-49a0-af1c-a76ae9c5fa24:image.png)

17 m 초

![image.png](attachment:ee79e034-bdfa-4b08-8129-a4240ff1b796:image.png)

redis-cli monitor로 확인!

```bash
ubuntu@ip-172-31-40-182:~$ redis-cli monitor
OK
1778425134.095354 [0 127.0.0.1:59440] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425135.340409 [0 127.0.0.1:59440] "GET" "posts:list:boardType=FREE&page=0&size=10"
```

근데 한글이 깨지고 있어서 필터 코드의 문자 인코딩을 수정해야 함

필터 코드 수정

```bash
cd ~/seonghwi.kim

cat > src/main/java/org/sopt/global/config/RedisResponseCacheFilter.java <<'EOF'
package org.sopt.global.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RedisResponseCacheFilter extends OncePerRequestFilter {

    private static final Duration CACHE_TTL = Duration.ofMinutes(10);

    private final StringRedisTemplate redisTemplate;

    public RedisResponseCacheFilter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isCacheTarget(request);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String cacheKey = buildCacheKey(request);

        String cachedBody = redisTemplate.opsForValue().get(cacheKey);

        if (cachedBody != null) {
            response.setStatus(HttpServletResponse.SC_OK);
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8");
            response.setHeader("X-Redis-Cache", "HIT");
            response.getWriter().write(cachedBody);
            return;
        }

        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(response);

        try {
            filterChain.doFilter(request, responseWrapper);
        } finally {
            byte[] body = responseWrapper.getContentAsByteArray();

            if (responseWrapper.getStatus() == HttpServletResponse.SC_OK && body.length > 0) {
                String responseBody = new String(body, StandardCharsets.UTF_8);

                redisTemplate.opsForValue().set(cacheKey, responseBody, CACHE_TTL);
                responseWrapper.setHeader("X-Redis-Cache", "MISS");
                responseWrapper.setCharacterEncoding(StandardCharsets.UTF_8.name());
                responseWrapper.setContentType(MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8");
            }

            responseWrapper.copyBodyToResponse();
        }
    }

    private boolean isCacheTarget(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && "/api/v1/posts".equals(request.getRequestURI());
    }

    private String buildCacheKey(HttpServletRequest request) {
        String queryString = request.getQueryString();

        if (queryString == null || queryString.isBlank()) {
            return "posts:list";
        }

        return "posts:list:" + queryString;
    }
}
EOF
```

# Redis 기존 캐시 삭제

한글 깨진 응답이 이미 Redis에 저장됐을 수 있으니까 Redis를 비우고 합시당.

```
redis-cli flushall
redis-cli dbsize
```

정상 결과:

```
OK
(integer) 0
```

![image.png](attachment:5d3389e5-e4ce-40b2-befa-753b3ed2319b:image.png)

4.83 초

![image.png](attachment:b57ca792-f8ea-4db5-8763-8f048298c2c0:image.png)

19 m 초

![image.png](attachment:fca9cc51-cf5a-4154-9bb2-de1046c39c90:image.png)

성능 개선 확인!

```bash
ubuntu@ip-172-31-40-182:~$ redis-cli monitor
OK
1778425632.606135 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425634.014201 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425634.882454 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425635.675552 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425636.508861 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425637.396581 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425638.339524 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425639.325743 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425640.221928 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425641.132754 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425642.049242 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425642.878377 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425644.007854 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425645.031739 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425645.955631 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425646.925540 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425647.790254 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425648.803662 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425649.901361 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425651.063544 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
1778425652.125046 [0 127.0.0.1:50730] "GET" "posts:list:boardType=FREE&page=0&size=10"
```

기존 응답 시간: 4.83초

Redis 캐시 적용 후 응답 시간: 19ms = 0.019초

- 개선 배수

  4.83초 / 0.019초 = 약 254.2배 (약 254배 빨라진 것)

- 감소율

  (4.83 - 0.019) / 4.83 * 100 = 약 99.61% (응답 시간이 약 99.6% 감소)


---

# 🧪 섹션 8 - 부하 테스트를 통해 Redis 적용 전후 성능 비교하기

## **🤔 내가 구성한 백엔드 서버는 1초당 몇 개의 요청을 견뎌낼 수 있을까?**

서비스를 배포하기 전에,

“혹시 요청이 몰려서 서버가 터지면 어떡하지?”

“내 서버는 어느 정도 사용자 요청을 견딜 수 있는 거지?”

“인스턴스 사양을 너무 작게 설정했나?”

라는 생각을 할 수 있다. → `부하 테스트`를 한다.

**Throughput**: 부하 테스트에서 서비스가 1초당 처리할 수 있는 작업량. 단위는 TPS(Transaction Per Seconds, 1초당 처리한 트랜잭션(요청)의 수)를 많이 활용한다.
만약 내가 만든 서비스가 1초에 최대 100개의 API 요청을 처리할 수 있다면, 이 서비스의 Throughput은 100 TPS 라고 얘기한다.

---

## **부하 테스트를 위한 환경 셋팅 (k6)**

성능 비교를 위해 `k6`라는 부하테스트 툴을 사용할 것이다. 부하테스트 툴에는 `k6` 이외에도 `ngrinder`, `jmeter`, `ab`, `locust` 등 다양한 툴이 있다. 하지만 그 중에서 간단하고 빠르게 테스트 해볼 수 있는 툴인 **`k6`**를 활용하고자 한다.

간단하게 빠르게 테스트할 수 있다고 해서 테스트 결과가 부정확한 건 아니다. `k6`도 높은 정확도와 고부하를 발생시킬 수 있는 부하테스트 툴이다.

### 간단 비교

| 도구 | 실행 방식 | 작성 언어/스크립트 | 장점 | 단점 | 추천 상황 |
| --- | --- | --- | --- | --- | --- |
| **k6** | CLI 기반 부하 테스트 | JavaScript | 가볍고 빠름, 코드 기반이라 Git 관리 쉬움, CI/CD 연동 좋음 | GUI가 거의 없음 | **개발자가 API 성능 테스트를 코드로 관리할 때** |
| **nGrinder** | 서버 + 에이전트(부하 발생기) 구조 | Groovy, Jython | 웹 UI가 좋음, 여러 에이전트로 대규모 부하 테스트 가능, 결과 리포트 보기 편함 | 설치/운영이 비교적 무거움 | **팀 단위로 부하 테스트 환경을 구축할 때** |
| **JMeter** | GUI 또는 CLI 기반 | GUI 설정 중심, 일부 스크립트 가능 | 오래된 표준 도구, 기능 매우 많음, 다양한 프로토콜 지원 | 무겁고 설정이 복잡함, 초보자에게 어려울 수 있음 | **복잡한 시나리오나 다양한 프로토콜 테스트가 필요할 때** |
| **ab** | CLI 기반 단순 HTTP 부하 테스트 | 스크립트 거의 없음 | 설치와 사용이 매우 간단함 | 기능이 너무 단순함, 실제 사용자 시나리오 표현 어려움 | **아주 빠르게 단일 API 성능을 대략 확인할 때** |
| **Locust** | Python 코드 기반 부하 테스트 | Python | 사용자 행동 시나리오를 코드로 유연하게 작성 가능, 웹 UI 제공 | Python 환경 필요, 초반 설정 필요 | **실제 사용자 행동 흐름을 시뮬레이션할 때** |

`k6`는 사용자인척 요청을 보내는 툴이다.

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/54fb4913-3f3b-4bff-89e5-63a40a7a8869/Untitled.png)

원래라면 사용자가 직접 서비스에 요청을 보내야 하는데, `k6`는 여러 명의 사용자를 대신해서 요청을 보내는 툴이다.

### 참고사항

부하 테스트는 실습 편의를 위해 Spring Boot 서버와 동일한 EC2에서 k6를 실행하였다.
따라서 측정 결과에는 애플리케이션 서버와 부하 발생기가 같은 인스턴스 자원을 공유한다는 한계가 있다.

### EC2에 k6 설치 명령어

```bash
cd ~

sudo apt-get update
sudo apt-get install -y gpg curl

curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list

sudo apt-get update
sudo apt-get install -y k6
```

설치 확인:

```bash
k6 version
```

# k6 테스트 파일 만들기

아래 명령어로 `posts-test.js` 파일을 만들기

```bash
cd ~

cat > posts-test.js <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 30,
  duration: '10s',
};

export default function () {
  const url = 'http://3.34.130.126:8080/api/v1/posts?boardType=FREE&page=0&size=10';

  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(1);
}
EOF
```

# Redis 캐시 비우고 테스트

먼저 Redis 캐시를 비우기.

```bash
redis-cli flushall
redis-cli dbsize
```

그다음 k6 실행.

```bash
k6 run posts-test.js
```

---

## **📊 Redis를 적용하기 전·후 Throughput(처리량) 비교해보기**

TPS (Transactions Per Second) 또는 처리량 (Throughput)

### Redis 적용 전

![image.png](attachment:397c99be-fc6b-47db-90ea-c4c60a0b60c6:image.png)

### Redis 적용 후

![image.png](attachment:332bd692-8fbc-4988-85eb-e578062d117f:image.png)

### 📈 Throughput 비교 결과

| 구분 | 총 요청 수 | 초당 처리량 | 실패율 | 의미 |
| --- | --- | --- | --- | --- |
| Redis 적용 전 | 28건 | **0.70 req/s** | **64.28%** | 초당 약 0.7개 요청만 처리했고, 실패도 많이 발생 |
| Redis 적용 후 | 300건 | **29.63 req/s** | **0%** | 초당 약 29.6개 요청을 안정적으로 처리 |

Redis 적용 전 0.70 req/s → Redis 적용 후 29.63 req/s로 증가하여, 처리량이 약 42.3배 개선되었다.
→ 대규모 트래픽일수록, Redis의 역할이 중요해진다!!

---

## 추가 학습 내용

### 부하 테스트 결과를 해석할 때 Throughput만 보면 안 되는 이유

이번 실습에서는 k6를 사용해 Redis 적용 전후의 Throughput(처리량)을 비교했다. Redis 적용 전에는 약 0.70 req/s, Redis 적용 후에는 약 29.63 req/s로 측정되어 처리량이 크게 개선되었다.

하지만 부하 테스트 결과를 해석할 때는 `Throughput`만 보는 것보다, `응답 시간`과 `실패율`도 함께 확인해야 한다.

Throughput은 서버가 1초 동안 처리한 요청 수를 의미한다. 값이 높을수록 더 많은 요청을 처리했다는 뜻이지만, 요청이 많이 실패했거나 응답 시간이 너무 길다면 좋은 결과라고 보기 어렵다.

예를 들어 Redis 적용 전에는 Throughput이 약 0.70 req/s로 낮았고, 실패율도 64.28%로 높았다. 이는 서버가 요청을 안정적으로 처리하지 못했다는 의미이다. 반면 Redis 적용 후에는 Throughput이 약 29.63 req/s로 증가했고, 실패율도 0%로 낮아졌다. 따라서 단순히 처리량만 증가한 것이 아니라, 요청을 더 안정적으로 처리할 수 있게 된 것이다.

또한 이번 k6 테스트에서는 `sleep(1)`을 사용했기 때문에, 가상 사용자 30명 기준으로 이론상 최대 처리량이 약 30 req/s 근처로 제한된다. 즉, Redis 적용 후 29.63 req/s가 나온 것은 현재 테스트 조건에서는 거의 상한에 가까운 결과라고 볼 수 있다.

이번 실습을 통해 부하 테스트 결과를 볼 때는 다음 지표를 함께 봐야 한다는 점을 알게 되었다.

- `http_reqs`: 실제 처리한 요청 수와 초당 요청 수
- `http_req_duration`: 평균 응답 시간, p90, p95 응답 시간 (전체 요청 중 90 / 95%가 이 시간 안에 끝났다)
- `http_req_failed`: 실패한 요청 비율
- `checks_succeeded`: 내가 설정한 검증 조건을 통과한 비율

결론적으로 성능 개선 여부를 판단할 때는 Throughput이 얼마나 증가했는지뿐만 아니라, 응답 시간이 충분히 짧은지, 실패율이 낮은지도 함께 확인해야 한다.

---

## 다음 주에 확인할 질문 또는 논의 포인트

- Redis 캐시를 적용하면 조회 성능은 크게 좋아지지만, Redis에 장애가 발생했을 때 서비스가 어떻게 동작해야 하는지 논의해보고 싶다. → Redis가 죽어도 DB를 조회해서 응답하도록 fallback 구조를 가져가는 것이 적절한가…
- 현재 Redis는 Spring Boot와 같은 EC2 내부에 설치했는데, 실제 운영 환경에서는 Redis를 EC2 내부에 직접 설치하는 방식과 AWS ElastiCache를 사용하는 방식 중 어떤 선택이 더 적절한지… 선택 기준은?