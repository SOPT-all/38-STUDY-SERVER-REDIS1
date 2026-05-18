## Docker Compose와 ElastiCache로 Redis 운영 구조 이해하기

이번 주차에서는 Redis와 Spring Boot를 Docker Compose로 함께 실행하고, EC2에 직접 설치한 Redis 대신 AWS ElastiCache를 사용하는 구조를 학습했습다.

4주차 범위는 다음 두 가지였습니다.

1. Docker Compose로 Spring Boot와 Redis를 함께 실행하기
2. AWS ElastiCache를 생성하고 Spring Boot와 연결하기

---

## 핵심 요약

3주차에서는 EC2 안에 Redis를 직접 설치해서 사용했다면 4주차에서는 이 구조를 조금 더 운영 환경에 가깝게 바꿉니다.

이번 주차의 내용은 다음과 같습니다.

- Docker Compose를 사용하면 Spring Boot와 Redis를 한 번에 실행할 수 있다.
- 컨테이너끼리는 서비스 이름으로 통신할 수 있다.
- EC2에 Redis를 직접 설치하면 운영과 확장 부담이 생긴다.
- ElastiCache는 AWS가 관리해주는 Redis 서비스이다.
- ElastiCache는 같은 VPC 내부에서 접근하는걸 기본으로 제공한다.

---

## 1. Docker Compose를 사용하는 이유

Spring Boot와 Redis를 각각 직접 실행하면 실행 순서와 환경 설정을 매번 신경 써야 한다.

예를 들어 로컬에서 테스트하려면 다음 작업을 따로 해야 합니다.

- Redis 실행
- Spring Boot 빌드
- Spring Boot 실행
- Redis host, port 확인
- 기존 프로세스 종료 확인

Docker Compose를 사용하면 여러 컨테이너를 하나의 설정 파일로 묶어서 실행할 수 있다.

```
docker compose up
  -> api-server 컨테이너 실행
  -> cache-server 컨테이너 실행
  -> Redis가 준비된 뒤 Spring Boot 실행
```

이렇게 하면 실행 환경을 코드로 관리할 수 있고 로컬과 서버 환경의 차이를 줄일 수 있다.

---

## 2. 로컬 Docker Compose 구성

### Dockerfile

Spring Boot 애플리케이션을 컨테이너로 실행하기 위한 Dockerfile이다.

```docker
FROM openjdk:17-jdk

COPY build/libs/*SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "/app.jar"]
```

빌드된 jar 파일을 컨테이너 안으로 복사하고 `java -jar`로 실행한다.

### compose.yml

Spring Boot와 Redis를 함께 실행한다.

```yaml
services:
  api-server:
    build: .
    ports:
      - 8080:8080
    depends_on:
      cache-server:
        condition: service_healthy

  cache-server:
    image: redis
    ports:
      - 6379:6379
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 10
```

여기서 중요한 부분은 `depends_on`과 `healthcheck`이다.

Redis가 아직 준비되지 않았는데 Spring Boot가 먼저 뜨면 연결 실패가 날 수 있다.

그래서 Redis가 `healthy` 상태가 된 뒤 API 서버를 실행하도록 설정한다.

---

## 3. Docker 환경에서 application.yml 수정

컨테이너 환경에서는 `localhost`의 의미가 달라진다.

Spring Boot 컨테이너 안에서 `localhost`는 내 Mac이나 EC2가 아니라 Spring Boot 컨테이너 자기 자신을 의미한다.

그래서 Redis host는 Compose 서비스 이름인 `cache-server`로 설정한다.

```yaml
spring:
  profiles:
    default: local
  datasource:
    url: jdbc:mysql://host.docker.internal:3306/mydb
    username: root
    password: password
  data:
    redis:
      host: cache-server
      port: 6379
```

로컬 DB에 접근할 때는 `host.docker.internal`을 사용할 수 있다.

정리하면 다음과 같다.

| 대상 | 설정 값 |
| --- | --- |
| Redis | `cache-server:6379` |
| 로컬 MySQL | `host.docker.internal:3306` |
| Spring Boot API | `localhost:8080` |

---

## 4. 로컬에서 Docker Compose 실행하기

기존에 실행 중인 Redis와 Spring Boot가 있다면 먼저 종료한다.

```bash
brew services stop redis
lsof -i:8080
kill {Spring Boot PID}
```

프로젝트를 빌드한 뒤 Docker Compose로 실행한다.

```bash
./gradlew clean build -x test
docker compose up --build -d
```

컨테이너 상태와 로그를 확인한다.

```bash
docker ps
docker compose logs -f
```

Postman으로 API를 호출해서 정상 동작하는지 확인한다.

---

## 5. EC2에서 Docker Compose로 실행하기

EC2에서는 `prod` 프로필을 사용해야 하므로 별도 Dockerfile과 compose 파일을 둔다.

### Dockerfile-prod

```docker
FROM openjdk:17-jdk

COPY build/libs/*SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "/app.jar"]
```

### compose-prod.yml

```yaml
services:
  api-server:
    build:
      context: .
      dockerfile: ./Dockerfile-prod
    ports:
      - 8080:8080
    depends_on:
      cache-server:
        condition: service_healthy

  cache-server:
    image: redis
    ports:
      - 6379:6379
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 10
```

EC2에서 최신 코드를 받은 뒤 실행한다.

```bash
cd {프로젝트 경로}
git pull origin main

./gradlew clean build -x test
docker compose -f compose-prod.yml up --build -d
```

컨테이너 상태와 로그를 확인한다.

```bash
docker ps
docker compose logs -f
```

이 구조에서는 EC2에 Redis를 직접 설치해서 실행하는 대신 Redis 컨테이너를 띄운다.

---

## 6. 왜 ElastiCache를 사용하는가?

EC2에 Redis를 직접 설치해서 쓰면 학습에는 좋지만 

운영에는 직접 관리해야 하는 내용이 많아서 부담이 크다.

- Redis 설치와 버전 관리
- 장애 대응
- 백업 설정
- 모니터링
- 확장
- 보안 설정
- 서버 리소스 관리

ElastiCache는 AWS가 대신 Redis를 관리해준다.

그래서 직접 Redis 서버를 운영하는 부담을 줄일 수 있다.

| 직접 설치한 Redis | ElastiCache |
| --- | --- |
| EC2 안에서 직접 설치/관리 | AWS 관리형 Redis |
| 설치와 장애 대응을 직접 처리 | 모니터링과 관리 기능 제공 |
| 확장과 백업 구성이 번거로움 | 설정 기반으로 확장 가능 |
| 학습용으로 적합 | 운영 환경에 더 적합 |

그래서 실무에서는 Redis를 EC2에 직접 설치하기보다 ElastiCache를 사용하는 경우도 많다고 한다.

---

## 7. ElastiCache 아키텍처

ElastiCache를 도입하면 구조가 다음처럼 바뀐다.

```
Client
  -> EC2
      -> Spring Boot
  -> RDS MySQL
  -> ElastiCache Redis
```

이전에는 Spring Boot와 Redis가 같은 EC2 안에 있었다.

```
EC2
  -> Spring Boot
  -> Redis
```

ElastiCache를 사용하면 Redis가 EC2 밖의 별도 관리형 서비스가 된다.

```
EC2
  -> Spring Boot
  -> ElastiCache Redis
```

Spring Boot 입장에서는 Redis host만 ElastiCache 엔드포인트로 바뀐다.

---

## 8. ElastiCache 생성 시 주요 설정

ElastiCache를 만들 때 중요한 설정은 다음과 같다.

| 설정 | 정리 |
| --- | --- |
| 클러스터 | 여러 캐시 노드를 묶은 단위 |
| 노드 | 실제 Redis 서버 하나 |
| 클러스터 모드 | 대규모 트래픽에서 데이터를 나누어 저장하는 방식 |
| 복제본 | 장애 대응과 읽기 분산을 위한 노드 |
| Multi AZ | 여러 가용 영역에 노드를 배치하는 설정 |
| Failover | 장애 발생 시 정상 노드로 전환하는 기능 |
| 보안 그룹 | EC2에서 Redis 6379 포트로 접근할 수 있게 설정 |

복제본을 1개 이상 두면 장애 대응에는 유리하지만 노드 수가 늘어나 비용도 증가한다.

---

## 9. ElastiCache 접속 확인

ElastiCache가 생성되면 기본 엔드포인트를 확인한다.

주의할 점은 ElastiCache는 기본적으로 같은 VPC 내부에서 접근한다는 것이다.

따라서 로컬 PC에서 바로 접속되지 않는 것이 정상이다.

EC2에 접속해서 Redis CLI로 확인한다.

```bash
redis-cli -h {ElastiCache 기본 엔드포인트}
```

정상 접속 후 캐시 데이터를 확인한다.

```bash
keys *
get getBoards::boards:page:1:size:10
ttl getBoards::boards:page:1:size:10
```

로컬에서 접속이 안 되는 이유는 ElastiCache가 외부 인터넷에 공개된 Redis가 아니기 때문이다.

EC2와 ElastiCache가 같은 VPC에 있는지 확인해야 한다.

---

## 10. Spring Boot에 ElastiCache 연결하기

`prod` 프로필의 Redis host를 ElastiCache 기본 엔드포인트로 바꾼다.

```yaml
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
      host: {ElastiCache 기본 엔드포인트}
      port: 6379
```

변경 내용을 push하고 EC2에서 pull 받는다.

```bash
cd {프로젝트 경로}
git pull origin main
```

기존 Docker Compose 컨테이너를 종료한다.

```bash
docker compose down
docker ps
```

Spring Boot를 다시 실행한다.

```bash
./gradlew clean build -x test
cd build/libs
java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명}
```

Postman으로 API를 호출한 뒤, EC2에서 ElastiCache에 접속해 실제 캐시가 저장됐는지 확인ㅎ다.

```bash
redis-cli -h {ElastiCache 기본 엔드포인트}
keys *
ttl getBoards::boards:page:1:size:10
```

---

## 11. 실습 명령어 정리

### Docker Compose 실행

```bash
./gradlew clean build -x test
docker compose up --build -d
docker ps
docker compose logs -f
```

### EC2에서 prod Compose 실행

```bash
./gradlew clean build -x test
docker compose -f compose-prod.yml up --build -d
docker ps
docker compose logs -f
```

### 기존 프로세스 종료

```bash
brew services stop redis
lsof -i:8080
kill {PID}
```

### Docker Compose 종료

```bash
docker compose down
docker ps
```

### ElastiCache 확인

```bash
redis-cli -h {ElastiCache 기본 엔드포인트}
keys *
get getBoards::boards:page:1:size:10
ttl getBoards::boards:page:1:size:10
```

---

## 12. 트러블슈팅

### Spring Boot 컨테이너가 Redis에 연결하지 못하는 경우

- Redis host가 `localhost`로 되어 있지 않은지 확인
- Compose 서비스 이름인 `cache-server`를 사용했는지 확인
- Redis healthcheck가 정상인지 확인

### 로컬 DB에 연결하지 못하는 경우

- Docker 컨테이너에서 로컬 DB에 접근할 때 `host.docker.internal`을 사용했는지 확인
- MySQL이 로컬에서 실행 중인지 확인
- DB 이름, 계정, 비밀번호가 맞는지 확인

### EC2에서 Docker 명령어 권한 문제가 나는 경우

- Docker가 정상 설치됐는지 확인
- 현재 사용자가 docker 그룹에 포함됐는지 확인
- 필요하면 세션을 다시 접속하거나 `newgrp docker`를 실행

### ElastiCache에 로컬에서 접속되지 않는 경우

- ElastiCache는 기본적으로 같은 VPC 내부에서 접근한다.
- 로컬 PC에서 바로 접속되지 않는 것이 정상일 수 있다.
- EC2에서 `redis-cli -h {endpoint}`로 접속을 확인한다.

### ElastiCache 연결이 안 되는 경우

- EC2와 ElastiCache가 같은 VPC인지 확인
- ElastiCache 보안 그룹에서 `6379` 포트 접근이 허용됐는지 확인
- Spring Boot의 Redis host가 endpoint로 설정됐는지 확인

---

## 13. 추가 학습: 관리형 Redis를 쓰는 이유

ElastiCache 같은 관리형 서비스를 쓰는 이유는 단순히 설치가 편해서만은 아니다.

운영 환경에서는 기능 구현보다 안정적인 운영이 더 중요할 때가 많다.

직접 Redis를 운영하면 장애, 백업, 모니터링, 확장, 보안 업데이트를 직접 챙겨야 한다.

반면 ElastiCache는 이런 운영 부담을 AWS에 일부 위임할 수 있다.

### 직접 운영할 때 생기는 부담

EC2에 Redis를 직접 설치하면 처음에는 단순해 보인다.

```
EC2
  -> Spring Boot
  -> Redis
```

하지만 운영 관점에서는 Redis도 하나의 서버입니다.

따라서 아래 항목을 계속 관리해야 한다.

| 항목 | 직접 운영 시 고려할 점 |
| --- | --- |
| 장애 대응 | Redis 프로세스가 죽었을 때 자동 복구할 수 있는가? |
| 백업 | 필요한 데이터를 안전하게 보관할 수 있는가? |
| 모니터링 | 메모리 사용량, 연결 수, 명령 지연 시간을 보고 있는가? |
| 확장 | 트래픽 증가 시 노드나 사양을 쉽게 늘릴 수 있는가? |
| 보안 | 외부 접근 차단, 보안 그룹, 패치 관리를 하고 있는가? |
| 배포 영향 | EC2 재배포나 장애가 Redis까지 같이 영향을 주지 않는가? |

특히 Spring Boot와 Redis가 같은 EC2에 있으면 한 서버에 책임이 몰린다.

EC2 CPU나 메모리가 부족해지면 API 서버와 Redis가 함께 영향을 받을 수 있다.

또 EC2 자체에 문제가 생기면 애플리케이션과 캐시가 동시에 죽을 수 있다.

### ElastiCache를 쓰면 좋아지는 점

ElastiCache를 사용하면 Redis를 별도 관리형 리소스로 분리할 수 있다.

```
EC2
  -> Spring Boot
  -> ElastiCache Redis
```

이렇게 분리하면 애플리케이션 서버와 캐시 서버의 역할이 명확해집니다.

ElastiCache의 장점은 다음과 같습니다.

- Redis 설치와 기본 운영을 AWS가 관리한다.
- CloudWatch를 통해 주요 지표를 확인할 수 있다.
- 노드 타입 변경이나 복제본 추가로 확장하기 쉽다.
- Multi AZ와 Failover를 통해 장애 대응 구조를 만들 수 있다.
- EC2와 분리되어 애플리케이션 배포 영향이 줄어든다.

물론 ElastiCache를 쓴다고 해서 모든 문제가 자동으로 해결되는 것은 아니다.

애플리케이션에서는 여전히 Redis 장애를 고려해야 한다.

예를 들어 Cache Aside 구조라면 Redis 연결 실패 시 DB로 fallback 할 수 있어야 한다.

```
Redis 정상
  -> Redis 조회
  -> Cache Hit 응답

Redis 장애
  -> Redis 조회 실패
  -> DB 조회로 fallback
  -> 응답은 느려지지만 서비스는 유지
```

캐시는 원본 저장소가 아니므로 캐시 장애 때문에 전체 서비스가 바로 죽지 않도록 설계하는 것이 중요하다.

### 비용과 안정성의 트레이드오프

관리형 서비스도 단점이 있습니다.

- 비용이 더 들 수 있다.
- AWS 환경에 종속될 수 있다.
- 세부 설정을 마음대로 제어하기 어렵다.

즉 ElastiCache는 공짜 해결책이 아니라 비용을 내고 운영 부담과 장애 위험을 줄이는 선택이다.

작은 사이드 프로젝트나 학습 환경에서는 Docker Compose만으로 충분할 수 있다.

하지만 실제 사용자가 있는 운영 서비스라면 Redis 장애, 백업, 모니터링, 확장까지 직접 책임지는 비용이 더 커질 수 있다.

그래서 직접 Redis를 설치해서 운영하는 것보다 관리형 Redis를 사용하는 편이 더 안정적일 수도 있다.

### 운영에서 추가로 봐야 할 지표

ElastiCache를 붙인 뒤에도 "연결됐다"에서 끝나면 안된다.

운영에서는 Redis가 안정적으로 동작하는지 지표를 계속 봐야 한다.

| 지표 | 의미 |
| --- | --- |
| CPU 사용률 | Redis 명령 처리 부하 |
| 메모리 사용량 | 캐시 데이터가 얼마나 쌓였는지 |
| Evictions | 메모리가 부족해서 키가 밀려났는지 |
| CurrConnections | 현재 연결된 클라이언트 수 |
| Cache Hit Ratio | 캐시가 실제로 얼마나 잘 맞는지 |
| Replication Lag | 복제본이 있을 때 지연이 발생하는지 |

특히 캐시 서버에서는 메모리 사용량과 eviction을 주의해서 봐야 합니다.

TTL이 없거나 너무 길면 Redis 메모리가 계속 증가할 수 있다.

메모리가 부족해지면 Redis의 eviction policy에 따라 기존 키가 삭제될 수 있고 그 결과 Cache Miss가 증가할 수 있다.

따라서 ElastiCache를 운영할 때는 다음을 함께 설계해야 한다.

- 어떤 데이터만 캐싱할 것인가?
- TTL은 얼마로 둘 것인가?
- 메모리가 부족하면 어떤 키를 먼저 제거할 것인가?
- Redis 장애 시 DB fallback은 가능한가?
- 캐시 Hit Ratio가 낮다면 캐싱 전략이 적절한가?

결론적으로 ElastiCache는 Redis 운영을 쉽게 만들어주지만 캐싱 전략과 장애 대응 설계까지 대신해주지는 않는다.

---