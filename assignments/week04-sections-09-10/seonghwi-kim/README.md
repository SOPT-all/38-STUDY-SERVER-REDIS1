# Week 04 - 김성휘

이번 주 학습 내용을 여기에 정리합니다.

# 4 주차 - 섹션 9, 10, 11

# 섹션 9 - Docker Compose로 Redis + Spring Boot 띄우기

## 1. Docker Compose로 Redis, Spring Boot 한 번에 띄울 수 있게 구성하기

1. Dockerfile 생성

    ```yaml
    FROM openjdk:17-jdk
    
    COPY build/libs/*SNAPSHOT.jar app.jar
    
    ENTRYPOINT ["java", "-jar", "/app.jar"]
    ```

2. **compose.yml 만들기**

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
          test: [ "CMD", "redis-cli", "ping" ]
          interval: 5s
          retries: 10
    ```


## 2. AWS EC2에서 Docker Compose를 활용해,  Redis, Spring Boot 띄워보기

1. **EC2에 Docker 설치하기**

    ```bash
    $ sudo apt-get update && \
    	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
    	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    	sudo apt-key fingerprint 0EBFCD88 && \
    	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    	sudo apt-get update && \
    	sudo apt-get install -y docker-ce && \
    	sudo usermod -aG docker ubuntu && \
    	newgrp docker && \
    	sudo curl -L "https://github.com/docker/compose/releases/download/2.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    	sudo chmod +x /usr/local/bin/docker-compose && \
    	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    	
    $ docker -v # Docker 버전 확인
    $ docker compose version # Docker Compose 버전 확인
    ```

2. 기존에 실행되고 있는 Redis, Spring Boot 종료하기

    ```bash
    # Redis 중지
    $ sudo systemctl stop redis
    $ sudo systemctl status redis # 잘 종료됐는 지 확인
    
    # Spring Boot 종료
    $ sudo lsof -i:8080 # 8080번 포트 실행되고 있는 프로세스 확인
    $ kill {Spring Boot의 PID} # 프로세스 종료
    $ sudo lsof -i:8080 # 잘 종료됐는 지 확인
    ```

3. **Docker 컨테이너로 띄워보기**

    ```bash
    $ ./gradlew clean build -x test
    $ docker compose -f compose-prod.yml up --build -d 
    
    $ docker ps # 잘 띄워졌는 지 확인
    $ docker compose logs -f # 실시간 로그 확인하기
    ```


# 섹션 10 - AWS ElastiCache 활용하기

## 1. 현업에서 EC2에 Redis를 설치해서 쓰지 않고 ElastiCache를 쓰는 이유

EC2에 MySQL을 설치 안 하고, RDS를 이용하는 것처럼 ElastiCache를 사용하면 더 쉽게 세팅이나 확장, 모니터링을 할 수 있다.

## 2. EC2, Redis, Spring Boot, ElastiCache를 활용한 아키텍처 구성

### ✅ 이전의 아키텍처 구성

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/38e15ac7-1003-4f46-b18f-ec69c82c0e81/Untitled.png)

### ✅ ElastiCache를 도입했을 때의 아키텍처 구성

![image.png](attachment:ac38f785-6fea-44a5-9656-f30f61392ec6:image.png)

## 3. AWS ElastiCache 셋팅하기

ElastiCache → 구성 → Rediss OSS → 노드 기반 캐시 → 생성방법: 클러스터 캐시

![image.png](attachment:f4342972-7437-4c74-9db3-d959344f710b:image.png)

- 노드: 하나의 캐시 서버
- 클러스터: 여러 캐시 서버를 이루는 한 단위의 그룹

![출처 : AWS 공식 문서](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/cf4e6cec-46e8-4758-9d9d-6711a5b904de/Untitled.png)

출처 : AWS 공식 문서

클러스터 모드: 비활성화됨 → 클러스터 정보 → 이름: redis-study-cache-server (sopkathon-cache-server ← 솝커톤 때 써보기!)

![image.png](attachment:f942de70-9ba8-4c5d-8562-0b1b6cd88d82:image.png)

위치 → AWS 클라우드 → 다중 AZ: 사용 해제 → 자동 장애 조치 (Failover): 사용

- 다중 AZ: 여러 리전에 캐시 서버를 나누기
- 자동 장애 조치 (Failover): 클러스터 내부에 특정 노드가 장애가 났을 때, 정상 노드로 교체하는 기능 (= 내부에 장애가 발생하면, 스스로 해결하는 기능)

![image.png](attachment:6446fa82-c88f-4f7f-a5ee-31506054a299:image.png)

캐시 설정 → 노드 유형: `t3.micro` → 복제본 개수: 0

- 복제본이 한 개 이상 있어야 `failover` 처리가 가능하다. (없으면 불가능)
- 복제본 개수가 늘어날수록, 노드가 늘어난다. → 비용이 증가한다. → 최소한의 비용으로 실습하려면, 복제본 개수를 `0`  으로 설정하자.

![image.png](attachment:ec0442a0-e28b-47a3-8ad0-c8b9cb357f51:image.png)

연결 → 새 서브넷 그룹 생성 → 이름: redis-study-subnet-group → **다음** 클릭

![image.png](attachment:40c47894-544c-4804-adfe-1a47409a7deb:image.png)

새 창에서 EC2 → 보안 그룹 → 생성 → 보안 그룹 이름: redis-cache-server-security-group → 인바운드 규칙 추가 → 포트 범위: 6379 (EC2 인스턴스가 Redis에 접근) → IPv4 Anywhere (ElastiCache 서비스는 기본적으로 같은 VPC 내에서만 접근할 수 있게 세팅이 되어 있다. → 외부 IP 접근이 기본적으로 막혀 있다! → 보안 그룹에서 모든 IP를 허용한다 하더라도, 외부에서 ElastiCache 에 접근하면 막힘 → 같은 VPC 에 있는 리소스들만 접근 가능하다. ) → **보안 그룹 생성**

![image.png](attachment:1f7c3a52-2127-4141-b426-399ca035f62b:image.png)

다시 ElastiCache 설정 창으로 돌아와서 → 고급 설정 → 보안 → 저장 중 암호화 / 전송 중 암호화: 사용 해제 → 보안 그룹 → 관리 →

![image.png](attachment:69d14273-4c6d-40ea-bd09-cd121d66b85c:image.png)

백업 → 자동 백업 사용: 해제 ( 캐싱은 임의로 데이터를 저장하는 용도이기 때문에, TTL을 이용한다. (영구적으로 보존하지 않는다.) ) → **다음** → **생성**

![image.png](attachment:07399ff3-4c77-47d5-866d-1441f098a3e9:image.png)

## 4. AWS ElastiCache 가 정상적으로 잘 생성됐는지 확인하기

ElastiCache  생성이 15 ~ 20분 정도 걸릴 수가 있음!

- 기본 엔드포인트: 프라이머리 엔드포인트 → 주로 모든 것을 총괄하고 모든 권한을 가지고 있는 Redis의 주소.
- 리더 엔드포인트: 읽기 전용 → 신경쓰지 말기

기본 엔드포인트에서 포트 번호 (:6379) 빼고 복사하기 → EC2에 접속 → `redis-cli -h {복사한 기본 엔드포인트}` → 접속 됐는지 `ping` 날려보기 (같은 VPC 내에 있기 때문에 EC2 에서도 ElastiCache 에 접속 가능하다!!)

- `redis-cli`: 현재 내 컴퓨터에 있는 Redis 서버로 접속
- `redis-cli -h {복사한 기본 엔드포인트}`: 옵션 `-h` 를 이용해서 다른 주소에 있는 Redis 서버로 접속 (포트 번호 없이)

```bash
sudo apt update
sudo apt install -y redis-tools

redis-cli --version

```

![image.png](attachment:1c26f690-d18e-4194-99f1-25dc2b9af3ac:image.png)

로컬에서 터미널로 접속하려고 하면, 같은 VPC 가 아니므로 접속이 불가하다.



## 5. Spring Boot에 ElastiCache 연결하기

1. **application.yml 파일 수정하기**

   **application.yml**

    ```
    # local 환경
    spring:
      profiles:
        default: local
      datasource:
        url: jdbc:mysql://host.docker.internal:3306/mydb
        username: root
        password: password
        driver-class-name: com.mysql.cj.jdbc.Driver
      jpa:
        hibernate:
          ddl-auto: update
        show-sql: true
      data:
        redis:
          host: cache-server
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
        url: jdbc:mysql://instagram-db.coseefawhrzc.ap-northeast-2.rds.amazonaws.com:3306/mydb
        username: admin
        password: password
      data:
        redis:
          host: **instagram-cache-server.s8nyjv.ng.0001.apn2.cache.amazonaws.com**
          port: 6379
    ```


1. **Github Repository에 Push하기**


2. **EC2에서 Git Pull 받기**

    ```
    $ cd {프로젝트 경로 }
    $ git pull origin main
    ```


1. **기존 서버 종료시키기**

    ```bash
    $ docker compose down # 이전 실습에서 실행시켰던 컨테이너 종료시키기
    $ docker ps # 종료됐는 지 확인
    ```


1. **Spring Boot 프로젝트 실행시키기**

    ```bash
    $ ./gradlew clean build -x test 
    $ cd build/libs
    $ java -jar -Dspring.profiles.active=prod {빌드된 jar 파일명}
    ```


1. **Postman으로 테스트해보기**

   ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/e35a8144-c5ff-40f0-b123-384a331e35bb/7e1f0a81-2f6b-4d68-9cec-66388ae7fe83/Untitled.png)


1. **실제 ElastiCache에 캐시가 저장되고 있는 지 확인해보기**

   새로운 EC2 창 열어서 아래 명령어를 통해 ElastiCache에 접속하기

    ```bash
    $ redis-cli -h {ElastiCache의 기본 엔드포인트}
    $ keys *
    $ get getBoards::boards:page:1:size:10
    $ ttl getBoards::boards:page:1:size:10
    ```


### ✅ 전체 흐름 다시 복습하기

- ElastiCache를 도입했을 때의 아키텍처 구성

![image.png](attachment:ac38f785-6fea-44a5-9656-f30f61392ec6:image.png)

# 섹션 11 - 마무리

## 1. 비용 나가지 않게 지금까지 사용했던 AWS 리소스 종료하기

결제 및 비용 관리 → 청구서 → 서비스별 요금 → `+` 눌러서 비용이 나가고 있는지 확인하기.

## 2. 이 다음에는 어떤 걸 공부해야 하나요?

프로젝트에서 꼭 적용시켜 보기 → 솝커톤에서 사용해보자~

라고 생각하면서 밤까지 공부해서 솝커톤 갔었는데, Redis를 적용을 못 했습니다..
다음 프로젝트에서 사용할 수 있으면, 꼭 Redis를 적용해보고 싶습니다.

---
## 추가 학습 내용

### Redis의 영속화 방식

Redis는 기본적으로 메모리(RAM)에 데이터를 저장하지만, 설정에 따라 데이터를 디스크에 저장할 수도 있다.

대표적인 방식으로는 RDB와 AOF가 있다.

- RDB: 특정 시점의 Redis 데이터를 스냅샷처럼 저장하는 방식
- AOF: Redis에 실행된 명령어를 로그처럼 계속 기록하는 방식

RDB는 복구 속도가 빠르고 파일 크기가 비교적 작지만, 마지막 저장 이후의 데이터는 유실될 수 있다.  
AOF는 데이터 유실 가능성을 줄일 수 있지만, 기록해야 할 로그가 많아지면 파일 크기가 커질 수 있다.

이를 통해 Redis도 단순한 임시 저장소로만 사용하는 것이 아니라, 설정에 따라 데이터 복구를 고려할 수 있다는 점을 알게 되었다.

---

### Redis의 데이터 삭제 방식

Redis는 TTL이 끝난 데이터를 바로 모두 삭제하는 것이 아니라, 여러 방식으로 만료된 데이터를 정리한다.

대표적으로 Lazy Expiration과 Active Expiration 방식이 있다.

- Lazy Expiration: key를 조회했을 때 만료 시간이 지났다면 그때 삭제하는 방식
- Active Expiration: Redis가 주기적으로 만료된 key를 찾아 삭제하는 방식

즉, TTL이 끝났다고 해서 모든 데이터가 정확히 그 순간 바로 삭제되는 것은 아니다.  
Redis는 성능을 고려해서 만료된 데이터를 효율적으로 정리한다.

또한 TTL을 설정하면 Redis 데이터가 자동으로 삭제되기 때문에 메모리 관리에 도움이 된다.  

캐시 데이터는 언젠가 사라질 수 있다는 전제를 두고, 캐시가 없을 때 DB에서 다시 조회할 수 있는 구조로 설계하는 것이 중요한 것 같다.

---