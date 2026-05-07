# Spring Boot Redis Practice

Week 02 Spring Boot + Redis 캐싱 실습용 프로젝트입니다.

강의 PDF의 Spring Boot 실습 범위에 맞춰 아래 구성을 준비했습니다.

- Spring Boot 3.x
- Java 17 target
- Spring Web
- Spring Data JPA
- MySQL Driver
- Spring Data Redis
- Spring Cache
- MySQL 8.x
- Redis 7.x

## 로컬 인프라 실행

```bash
docker compose up -d
```

실행되는 서비스는 다음과 같습니다.

| 서비스 | 주소 | 계정 |
| --- | --- | --- |
| MySQL | `localhost:3306/mydb` | `root` / `password` |
| Redis | `localhost:6379` | 없음 |

## 애플리케이션 실행

```bash
gradle bootRun
```

현재 전역 Gradle 실행에 문제가 있으면 로컬 Gradle 설치를 먼저 점검해야 합니다.

## API 확인

```bash
curl 'http://localhost:8080/boards?page=1&size=10'
```

처음 요청은 DB를 조회하고, 두 번째 요청부터는 Redis 캐시를 조회합니다.

캐시 키는 아래 패턴으로 생성됩니다.

```text
getBoards::boards:page:{page}:size:{size}
```

TTL은 `1분`으로 설정했습니다.

## 더미 데이터

JPA가 `boards` 테이블을 만든 뒤 아래 SQL을 실행하면 대량 더미 데이터를 넣을 수 있습니다.

```bash
docker exec -i week02-mysql mysql -uroot -ppassword mydb < docs/dummy-data.sql
```

## Redis 캐시 확인

로컬에 `redis-cli`가 없으면 Docker 컨테이너 안에서 확인할 수 있습니다.

```bash
docker exec -it week02-redis redis-cli
keys *
get getBoards::boards:page:1:size:10
ttl getBoards::boards:page:1:size:10
```
