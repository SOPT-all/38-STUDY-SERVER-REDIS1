# Week 03 - 이지현

이번 주 학습 내용을 여기에 정리합니다.

## **이번 학습의 목표**

이번 학습에서는 AWS 환경에 Spring Boot 서버를 배포하고, Redis 캐싱을 적용했을 때 성능이 얼마나 좋아지는지 확인했다.

구성한 백엔드 아키텍처는 다음과 같다.

```
사용자
  ↓
EC2
- Spring Boot 서버
- Redis
  ↓
RDS
- MySQL DB
```

즉, EC2에는 Spring Boot 애플리케이션과 Redis를 설치하고, 데이터베이스는 RDS MySQL을 사용했다.

## **AWS 비용 정리**

실습에서 사용하는 주요 AWS 리소스는 EC2, RDS, Redis 또는 ElastiCache이다.

### **EC2**

EC2는 Spring Boot 서버와 Redis를 실행하는 서버 역할을 한다.

사용한 인스턴스는 `t3a.small`이며, 시간당 약 `0.026 USD` 정도 비용이 든다.

대략 하루 24시간 실행하면 약 800원 정도로 계산된다.

추가로 Public IPv4 주소 비용도 발생한다.

```
Public IPv4 비용: 시간당 0.005 USD
하루 기준 약 200원
```

따라서 학습이 끝나면 EC2 인스턴스를 종료하는 것이 좋다.

### **RDS**

RDS는 MySQL 데이터베이스 서버 역할을 한다.

사용한 인스턴스는 `t4g.micro`이며, 시간당 약 `0.026 USD`이다.

프리티어라면 월 750시간까지 무료로 사용할 수 있다.

스토리지는 GB-월 단위로 비용이 발생하며, 프리티어에서는 20GB까지 무료이다.

RDS도 Public IPv4를 사용하면 별도 비용이 발생한다.

### **Redis / ElastiCache**

Redis를 EC2에 직접 설치할 수도 있고, AWS ElastiCache를 사용할 수도 있다.

강의 자료에서는 ElastiCache 비용도 언급되어 있다.

```
cache.t3.micro: 시간당 약 0.025 USD
하루 기준 약 800원
```

다만 이번 실습 구조에서는 Redis를 EC2에 직접 설치했다.

## **EC2 생성 시 주의할 점**

Spring Boot와 Redis를 EC2 한 대에서 같이 실행하기 때문에 인스턴스 성능이 중요하다.

`t2.micro`는 성능이 부족할 수 있다.

Spring Boot 서버와 Redis를 같이 실행하면 메모리나 CPU가 부족해서 EC2가 멈출 수도 있다.

그래서 실습에서는 `t3a.small` 이상을 권장한다.

또한 Spring Boot 서버는 기본적으로 8080 포트를 사용하므로, EC2 보안 그룹에서 8080 포트를 열어야 한다.

```
EC2 보안 그룹에서 열어야 할 포트:
- 22: SSH 접속
- 8080: Spring Boot 서버 접속
```

## **RDS 생성 시 주의할 점**

RDS는 MySQL 데이터베이스로 사용했다.

실습을 쉽게 하기 위해 초기 데이터베이스 이름을 `mydb`로 생성했다.

Spring Boot에서 RDS에 접속하려면 RDS 보안 그룹에서 3306 포트를 열어야 한다.

```
RDS 보안 그룹에서 열어야 할 포트:
- 3306: MySQL 접속
```

다만 실제 운영 환경에서는 3306 포트를 아무 곳에나 열면 위험하다.

일반적으로는 EC2에서만 RDS에 접근할 수 있도록 제한하는 것이 좋다.

## **EC2에 Redis 설치**

EC2 서버에 접속한 뒤 Redis를 설치했다.

## **EC2에 Spring Boot 프로젝트 설정**

Spring Boot 3.x 버전을 사용하기 때문에 JDK 17을 설치했다.

Spring Boot 프로젝트에서는 `application.yml`을 수정했다.

### **local 환경**

로컬 환경에서는 MySQL과 Redis가 모두 내 컴퓨터 또는 localhost에 있다고 가정한다.

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
```

### **prod 환경**

배포 환경에서는 MySQL 주소가 RDS 주소로 바뀐다.

```yaml
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: jdbc:mysql://{rds 주소}:3306/mydb
    username: admin
    password: password
```

서버 실행 시 `prod` 프로필을 사용했다.

### **application.yml 보안 주의**

강의에서는 편의를 위해 `application.yml`을 GitHub에 올렸지만, 실제 프로젝트에서는 조심해야 한다.

`application.yml`에는 DB 주소, DB 계정, 비밀번호 같은 민감한 정보가 들어갈 수 있다.

따라서 실제 프로젝트에서는 `.gitignore`에 추가하거나 환경 변수를 사용하는 것이 좋다.

## **RDS에 더미 데이터 넣기**

성능 테스트를 위해 RDS MySQL에 많은 양의 더미 데이터를 넣었다.

강의에서는 `boards` 테이블에 100만 개의 데이터를 삽입했다.

## **Redis 적용 전후 응답 속도 비교**

게시글 조회 API를 대상으로 Redis 캐싱 적용 전후 성능을 비교했다.

### **Redis 적용 전**

Redis 캐싱을 사용하지 않으면 매 요청마다 RDS에 직접 조회한다.

```java
public List<Board> getBoards(int page, int size) {
    Pageable pageable = PageRequest.of(page - 1, size);
    Page<Board> pageOfBoards = boardRepository.findAllByOrderByCreatedAtDesc(pageable);
    return pageOfBoards.getContent();
}
```

이 경우 평균 응답 시간이 약 500ms 정도 나왔다.

```
Redis 미적용: 평균 약 500ms
```

### **Redis 적용 후**

Redis 캐싱을 적용하면 첫 요청은 DB에서 데이터를 가져오지만, 이후 같은 요청은 Redis에서 데이터를 가져올 수 있다.

```java
@Cacheable(
    cacheNames = "getBoards",
    key = "'boards:page:' + #page + ':size:' + #size",
    cacheManager = "boardCacheManager"
)
public List<Board> getBoards(int page, int size) {
    Pageable pageable = PageRequest.of(page - 1, size);
    Page<Board> pageOfBoards = boardRepository.findAllByOrderByCreatedAtDesc(pageable);
    return pageOfBoards.getContent();
}
```

Redis 적용 후 평균 응답 시간이 약 20ms 정도 나왔다.

```
Redis 적용: 평균 약 20ms
```

즉, DB를 매번 조회하지 않고 Redis에서 빠르게 가져오기 때문에 응답 속도가 크게 개선되었다.

## **부하 테스트**

부하 테스트는 서버가 어느 정도의 요청을 견딜 수 있는지 확인하는 테스트이다.

이번 학습에서는 k6를 사용했다.

k6는 여러 사용자가 동시에 요청을 보내는 것처럼 테스트할 수 있는 도구이다.

### **Throughput**

부하 테스트에서 중요한 개념이 Throughput이다.

Throughput은 서버가 일정 시간 동안 처리할 수 있는 작업량이다.

보통 TPS라는 단위를 사용한다.

```
TPS = Transaction Per Second
TPS = 1초당 처리한 요청 수
```

예를 들어 서버가 1초에 100개의 요청을 처리할 수 있다면 Throughput은 100 TPS라고 할 수 있다.

## **k6 테스트 스크립트**

k6로 부하 테스트를 하기 위해 다음 스크립트를 작성했다.

```jsx
import http from 'k6/http';

export default function () {
  http.get('http://{EC2 IP 주소}:8080/boards');
}
```

이 스크립트는 EC2에 배포된 Spring Boot 서버의 `/boards` API로 GET 요청을 보낸다.

테스트 실행 명령어는 다음과 같다.

```bash
k6 run --vus 30 --duration 10s script.js
```

의미는 다음과 같다.

- -vus 30
    
    가상 사용자 30명이 동시에 요청을 보내는 것처럼 테스트
    
- -duration 10s
    
    10초 동안 테스트 실행
    

## Throughtput 비교

### **Redis 적용 전 Throughput**

Redis 캐싱을 끈 상태에서 테스트했다.

이 경우 API 요청마다 RDS를 조회한다.

결과는 약 1.6 TPS였다.

```
Redis 미적용: 약 1.6 TPS
```

즉, 1초에 약 1.6개의 요청을 처리했다는 의미이다.

데이터가 많고 DB 조회가 느리기 때문에 처리량이 낮게 나온 것이다.

### **Redis 적용 후 Throughput**

Redis 캐싱을 켠 상태에서 다시 테스트했다.

이 경우 같은 요청은 RDS가 아니라 Redis에서 조회된다.

결과는 약 385 TPS였다.

```
Redis 적용: 약 385 TPS
```

즉, 1초에 약 385개의 요청을 처리했다는 의미이다.

Redis를 적용하면서 처리량이 크게 증가했다.

## **Redis를 EC2에 직접 설치 vs ElastiCache 사용**

### **EC2에 Redis 직접 설치**

장점:

- 비용이 비교적 적게 든다
- 학습용으로 이해하기 좋다
- 직접 설치와 설정을 경험할 수 있다

단점:

- 장애 대응을 직접 해야 한다
- 백업, 모니터링, 보안 설정을 직접 해야 한다
- EC2가 죽으면 Redis도 같이 죽을 수 있다

### **ElastiCache 사용**

장점:

- AWS가 Redis 운영을 많이 대신해준다
- 모니터링, 백업, 장애 대응 기능을 활용할 수 있다
- 운영 환경에 더 적합하다

단점:

- 비용이 추가된다
- AWS 설정을 더 알아야 한다

## **부하 테스트 결과를 해석하는 방법**

TPS 외에도 다음과 같은 지표를 같이 보면 좋다.

- 평균 응답 시간
- p95 응답 시간
- p99 응답 시간
- 실패율
- CPU 사용률
- 메모리 사용률

특히 평균만 보면 위험할 수 있다.

예를 들어 평균 응답 시간이 20ms여도 일부 요청이 2초 걸릴 수 있다.

그래서 p95, p99를 본다.

```
p95 = 전체 요청 중 95%가 이 시간 안에 응답했다는 뜻
p99 = 전체 요청 중 99%가 이 시간 안에 응답했다는 뜻
```