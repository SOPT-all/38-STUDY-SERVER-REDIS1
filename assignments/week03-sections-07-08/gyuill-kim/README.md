# Week 03 - 김규일

## AWS 환경에서 Redis 캐싱 성능 측정하기

이번 주차에서는 로컬에서 확인했던 Redis 캐싱 효과를 AWS 환경에 배포한 뒤, Postman과 k6로 성능을 측정하는 내용을 학습했습니다.

3주차 범위는 다음 두 가지입니다.

1. EC2, RDS, Spring Boot, Redis를 활용한 배포 환경 구성
2. Redis 적용 전후 응답 시간과 Throughput 비교

---

## 핵심 요약

Redis를 적용했다고 해서 성능이 좋아졌다고 바로 말할 수는 없습니다.  
성능 개선은 반드시 수치로 확인해야 합니다.

이번 주차의 핵심은 다음과 같습니다.

- EC2에는 Spring Boot와 Redis를 실행한다.
- RDS에는 원본 게시글 데이터를 저장한다.
- Spring Boot는 먼저 Redis를 조회하고, 캐시에 없으면 RDS에서 데이터를 조회한다.
- Redis 적용 전후를 같은 조건에서 비교해야 한다.
- 단건 응답 시간은 Postman으로, 동시 요청 처리량은 k6로 확인한다.

---

## 1. 이번 주차 아키텍처

전체 구조는 다음과 같습니다.

```text
Client / Postman / k6
  -> EC2
      -> Spring Boot
      -> Redis
  -> RDS MySQL
```

각 구성 요소의 역할은 다음과 같습니다.

| 구성 요소 | 역할 |
| --- | --- |
| EC2 | Spring Boot 서버와 Redis 실행 |
| Spring Boot | 게시글 조회 API 제공 |
| Redis | 게시글 조회 결과 캐싱 |
| RDS MySQL | 원본 게시글 데이터 저장 |
| Postman | 단건 응답 시간 확인 |
| k6 | 동시 요청 상황에서 처리량 측정 |

게시글 목록 조회 흐름은 다음과 같습니다.

```text
요청
  -> Spring Boot
  -> Redis 조회
    -> Cache Hit: Redis 데이터 반환
    -> Cache Miss: RDS 조회 후 Redis 저장
```

이번 실습에서는 Redis를 EC2 안에 직접 설치합니다.  
실무에서는 보통 EC2에 직접 설치하기보다 AWS ElastiCache 같은 관리형 Redis를 사용합니다.

---

## 2. AWS 리소스 생성 시 주의점

AWS 실습은 실제 비용이 발생할 수 있으므로 리소스를 만들기 전에 비용을 먼저 확인해야 합니다.

| 리소스 | 체크할 것 |
| --- | --- |
| EC2 | 인스턴스 실행 시간, Public IPv4 비용, 8080 포트 오픈 |
| RDS | DB 인스턴스 실행 시간, 스토리지, 3306 포트 오픈 |
| Redis | 이번 주차에서는 EC2 내부에 설치 |

EC2는 `t3a.small` 이상을 권장합니다.  
`t2.micro`처럼 작은 인스턴스에서는 Spring Boot와 Redis를 함께 실행하기에 부족할 수 있습니다.

RDS는 초기 DB 이름을 `mydb`로 설정하고, EC2에서 접근할 수 있도록 보안 그룹을 열어야 합니다.

실습이 끝난 뒤에는 EC2, RDS, Public IPv4, 스냅샷 같은 리소스를 정리해야 합니다.

---

## 3. EC2에 Redis와 Spring Boot 실행하기

### Redis 설치

```bash
sudo apt update
sudo apt install redis
redis-cli
```

Redis가 정상 실행 중인지 확인합니다.

```bash
127.0.0.1:6379> ping
PONG
```

`PONG`이 나오면 Redis가 정상 동작 중이라는 뜻입니다.

### JDK 설치

Spring Boot 3.x 기준으로 JDK 17을 설치합니다.

```bash
sudo apt install openjdk-17-jdk
java -version
```

### 프로젝트 실행

EC2에서 GitHub Repository를 clone 받은 뒤 빌드하고 실행합니다.

```bash
git clone {Github Repository 주소}
cd {프로젝트 경로}

./gradlew clean build -x test
cd build/libs
java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명}
```

`prod` 프로필을 사용하면 AWS 환경용 설정으로 실행할 수 있습니다.

---

## 4. application.yml 설정

로컬과 AWS 환경은 DB 주소가 다르므로 프로필을 나누어 관리합니다.

```yaml
spring:
  profiles:
    default: local
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: password
  data:
    redis:
      host: localhost
      port: 6379

---
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: jdbc:mysql://{rds 주소}:3306/mydb
    username: admin
    password: password
  data:
    redis:
      host: localhost
      port: 6379
```

실습에서는 편의를 위해 DB 정보를 설정 파일에 직접 넣을 수 있습니다.  
하지만 실제 프로젝트에서는 DB 주소, 계정, 비밀번호를 Git에 올리면 안 됩니다.

운영 환경에서는 환경 변수, Secret Manager, CI/CD secret 등을 사용하는 것이 좋습니다.

---

## 5. RDS에 더미 데이터 넣기

성능 차이를 확인하려면 데이터가 충분히 있어야 합니다.

```sql
SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO boards (title, content, created_at)
WITH RECURSIVE cte (n) AS
(
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM cte WHERE n < 1000000
)
SELECT
  CONCAT('Title', LPAD(n, 7, '0')) AS title,
  CONCAT('Content', LPAD(n, 7, '0')) AS content,
  TIMESTAMP(
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 3650 + 1) DAY)
    + INTERVAL FLOOR(RAND() * 86400) SECOND
  ) AS created_at
FROM cte;
```

데이터가 적으면 DB 조회도 빠르게 끝나기 때문에 Redis 캐싱 효과가 잘 드러나지 않을 수 있습니다.

---

## 6. Postman으로 응답 시간 비교

Redis 적용 여부는 `BoardService`의 `@Cacheable` 주석 처리 여부로 비교합니다.

```java
@Cacheable(cacheNames = "getBoards", key = "'boards:page:' + #page + ':size:' + #size", cacheManager = "boardCacheManager")
public List<Board> getBoards(int page, int size) {
    Pageable pageable = PageRequest.of(page - 1, size);
    Page<Board> pageOfBoards = boardRepository.findAllByOrderByCreatedAtDesc(pageable);
    return pageOfBoards.getContent();
}
```

캐싱을 끄고 싶으면 `@Cacheable`을 주석 처리한 뒤 다시 빌드해서 실행합니다.

```bash
./gradlew clean build -x test
cd build/libs
java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명}
```

강의 예시 기준 결과는 다음과 같습니다.

| 상태 | 평균 응답 시간 |
| --- | ---: |
| Redis 적용 | 약 20ms |
| Redis 미적용 | 약 500ms |

Postman은 단건 요청의 응답 시간을 보기 좋지만, 동시에 많은 요청이 들어오는 상황은 확인하기 어렵습니다.  
그래서 처리량은 k6로 별도 측정합니다.

---

## 7. k6로 Throughput 측정하기

Throughput은 단위 시간 동안 처리한 요청 수입니다.  
백엔드 API에서는 보통 TPS(Transaction Per Second), 즉 초당 처리 요청 수로 표현합니다.

예를 들어 API가 1초에 100개 요청을 처리하면 `100 TPS`라고 말할 수 있습니다.

### k6 설치

```bash
brew install k6
k6
```

### k6 스크립트

```javascript
import http from 'k6/http';
import { sleep } from 'k6';

export default function () {
  http.get('http://{EC2 IP 주소}:8080/boards');
  sleep(1);
}
```

### 테스트 실행

Spring Boot 서버는 백그라운드에서 실행합니다.

```bash
./gradlew clean build -x test
cd build/libs
nohup java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명} &
```

8080 포트 실행 여부를 확인합니다.

```bash
lsof -i:8080
```

k6 테스트를 실행합니다.

```bash
k6 run --vus 30 --duration 10s script.js
```

옵션 의미는 다음과 같습니다.

| 옵션 | 의미 |
| --- | --- |
| `--vus 30` | 가상 사용자 30명 |
| `--duration 10s` | 10초 동안 테스트 |

---

## 8. Redis 적용 전후 Throughput 비교

강의 예시 기준 결과는 다음과 같습니다.

| 상태 | Throughput |
| --- | ---: |
| Redis 미적용 | 약 1.6 TPS |
| Redis 적용 | 약 385 TPS |

성능 향상 폭은 다음과 같이 계산할 수 있습니다.

```text
385 / 1.6 = 약 240배
```

Redis를 적용하지 않으면 요청마다 RDS를 조회합니다.

```text
요청
  -> Spring Boot
  -> RDS 조회
  -> 응답
```

Redis를 적용하면 첫 요청 이후에는 캐시에서 데이터를 가져옵니다.

```text
첫 요청
  -> Redis Miss
  -> RDS 조회
  -> Redis 저장

이후 요청
  -> Redis Hit
  -> 응답
```

DB까지 가지 않는 요청이 늘어나면 DB 쿼리 횟수, DB 커넥션 사용량, RDS CPU/I/O 부담이 줄어듭니다.  
그 결과 평균 응답 시간뿐 아니라 초당 처리 가능한 요청 수까지 증가합니다.

---

## 9. 실습 명령어 정리

### Redis 확인

```bash
redis-cli
ping
keys *
get getBoards::boards:page:1:size:10
ttl getBoards::boards:page:1:size:10
```

### k6 실행

```bash
k6 run --vus 30 --duration 10s script.js
```

---

## 10. 트러블슈팅

### EC2 API 호출이 안 되는 경우

- EC2 보안 그룹에 `8080` 포트가 열려 있는지 확인
- Spring Boot가 실제로 실행 중인지 확인
- EC2 Public IP로 요청하고 있는지 확인

```bash
lsof -i:8080
```

### RDS 연결이 안 되는 경우

- RDS 보안 그룹에 `3306` 포트가 열려 있는지 확인
- `application.yml`의 RDS 주소, DB 이름, 계정, 비밀번호 확인
- EC2에서 RDS에 접근 가능한지 확인

### Redis 캐시가 안 생기는 경우

- `@EnableCaching` 설정 확인
- `@Cacheable` 설정 확인
- CacheManager 이름 확인
- Redis host, port 확인

```bash
keys *
ttl {cache key}
```

### k6 결과가 이상한 경우

- Redis 적용 전후 테스트 조건이 같은지 확인
- 테스트 전 캐시 상태 확인
- EC2/RDS 인스턴스 사양 확인
- `--vus`, `--duration` 옵션 확인

---

## 11. 추가 학습: 평균만 보면 안 되는 이유

성능 테스트에서는 평균 응답 시간만 보면 부족합니다.

평균이 좋아도 일부 요청이 매우 느리면 사용자는 느리다고 느낄 수 있습니다.  
그래서 p95, p99 같은 지표를 같이 봐야 합니다.

| 지표 | 의미 |
| --- | --- |
| 평균 응답 시간 | 전체 요청의 평균 처리 시간 |
| p95 | 95% 요청이 이 시간 안에 끝남 |
| p99 | 99% 요청이 이 시간 안에 끝남 |
| 실패율 | 실패한 요청 비율 |
| TPS | 초당 처리 요청 수 |

Redis 캐싱 적용 후에도 다음을 같이 확인해야 합니다.

- Cache Hit 비율
- p95, p99 응답 시간
- 요청 실패율
- RDS 부하 감소 여부
- Redis 메모리 사용량

---

## 최종 정리

이번 주차에서는 AWS 환경에서 Redis 캐싱 적용 전후 성능을 비교했습니다.

Postman으로 단건 응답 시간을 확인했고, k6로 동시 요청 처리량을 측정했습니다.  
강의 예시에서는 Redis 적용 후 응답 시간이 약 `500ms`에서 `20ms`로 줄었고, Throughput은 약 `1.6 TPS`에서 `385 TPS`로 증가했습니다.

핵심은 Redis를 붙였다는 사실이 아니라, 같은 조건에서 측정한 수치로 성능 개선을 설명할 수 있어야 한다는 점입니다.
