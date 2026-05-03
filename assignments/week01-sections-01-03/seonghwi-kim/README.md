# Week 01 - 김성휘

이번 주 학습 내용을 여기에 정리합니다.

# 1 주차 - 섹션 1, 2, 3  

# 섹션 1 - OT

단순 듣기 or 단순 코드 따라치기는 지양하기

요약하기 / 내 말로 바꿔서 글 쓰기 / 남에게 설명하기 / 도식화 → 직접 생각하며 뇌를 사용하기 → 블로그 작성 추천

- 개발은 `파레토의 법칙` 이용하기 (완벽주의 성향 버리기!)

  cf. 전체 결과의 80%가 전체 원인의 20%에서 발생하는 현상을 뜻하는 80:20 법칙


- `First World 법칙`  활용하기

  낯선 용어 나올 때마다 기록하기 (쉽게 이해할 수 있는 직관적인 의미로!)


- `주석 공부법` 이용하기

  코드 한 줄마다 어떤 의미인지 스스로 적어보면서 이해하기


---

# 섹션 2 - Redis 기본 개념

## 📌 Redis 란 ?

약자: Remote Dictionary Server

데이터를 메모리(RAM)에 저장하는 오픈 소스, 초고속 인메모리(In-Memory) NoSQL 데이터 구조 저장소

→ 일반적인 DB처럼 데이터를 디스크(보조기억장치)에 저장하는 것이 아닌, **메모리(RAM)에 데이터를 올려두고 매우 빠르게 읽고 쓰는 저장소**

- 특징
    1. 매우 빠름
    2. Key - Value 방식으로 데이터 저장
    3. 다양한 자료구조 지원

       ex) String, List, Set, Hash, Sorted Set


cf) **인메모리(In-Memory)**: 데이터를 디스크가 아닌 주 기억장치(RAM)에 상주시켜 처리하는 방식

## 🤔 Redis를 어디에 많이 사용할까?

### 1. 🚀 Cache

DB에서 매번 조회하면 느리거나 부담이 큰 데이터를 Redis에 잠시 저장해두고 빠르게 조회

```
자유게시판 게시글 목록 조회
→ 먼저 Redis 확인
→ Redis에 있으면 바로 반환
→ Redis에 없으면 DB 조회 후 Redis에 저장
```

### 2. 🔐 Session 저장

로그인한 사용자 정보를 Redis에 저장 가능

### 3. 🏆 Ranking(랭킹)

Redis의 **Sorted Set**을 사용하면 랭킹 시스템을 쉽게 만들 수 있음

ex) 인기 검색어 순위, 게시글 좋아요 순위, 게임 점수 순위 등

### 4. 📢 Pub/Sub(발행/구독)

Redis는Publish/Subscribe(발행/구독) 기능도 제공

채팅, 알림, 실시간 이벤트 처리 등에 사용 가능

## Redis 🆚 일반 DB

| 구분 | Redis | 일반 DB |
| --- | --- | --- |
| 저장 위치 | 메모리 중심 | 디스크 중심 |
| 속도 | 매우 빠름 | 상대적으로 느림 |
| 데이터 구조 | Key-Value 중심 | Table 중심 |
| 주 용도 | 캐시, 세션, 랭킹, 임시 데이터 | 영구 데이터 저장 |
| 데이터 안정성 | 설정에 따라 영속화 가능 | 기본적으로 영구 저장 |

### Spring에서는

보통 캐싱, 로그인 세션, 토큰 관리, 랭킹, 분산 락 등에 많이 사용

백엔드 채용 공고에 종종 등장하는 ‘대용량 트래픽 처리 경험’, ‘Redis 사용 경험’

→ 대용량 트래픽 서비스는 NoSQL이 필요

| 용도 | 주로 사용하는 기술 |
| --- | --- |
| 회원, 게시글, 주문, 결제 | RDB |
| 자주 조회되는 데이터 | Redis |
| 세션, 인증 토큰 | Redis |
| 랭킹, 인기 게시글 | Redis Sorted Set |
| 로그, 이벤트 데이터 | NoSQL 또는 데이터 웨어하우스 |
| 검색 | Elasticsearch, OpenSearch |
| 대용량 파일 | S3 같은 Object Storage |

---

# 섹션 3 - Redis 사용법 익히기

# 1. 💻 Redis 설치하기

저는 아래와 같은 방법으로 Windows 11 에서 설치하였습니다.

Windows 11 + WSL(Windows Subsystem for Linux) 이용하였습니다.

(

가장 권장되는 Redis 설치 방법은 WSL(Ubuntu 등 리눅스 환경) 안에 Redis를 설치하는 것이라더라고요…!

- Redis는 원래 Linux 환경 기준으로 개발/운영
- Windows 네이티브 버전은 공식 지원이 오래전에 중단
- 실무에서도 Windows 사용자는 보통 WSL / Docker / 원격 Linux 서버에서 Redis를 사용

)

### 1) 🐧 Ubuntu 실행

```powershell
wsl -d Ubuntu
```

### 2) 📦 Redis 설치

Ubuntu 터미널 안에서:

```bash
sudo apt update
sudo apt install redis-server -y
```

### 3) ▶️ Redis 실행

```bash
sudo service redis-server start
```

### 4) ✅ 정상 확인

```bash
redis-cli
```

들어가서:

```bash
ping
```

→ PONG 나오는지 확인되면 정상!

![image.png](attachment:a0ced668-a64d-47a1-a34c-839a5bd86f46:image.png)

### 5) 🛑 Redis 종료

```bash
sudo service redis-server stop
```

# 2. ⌨️ Redis 기본 명령어 익히기

### 1) 💾 데이터(Key, Value) 저장하기

```bash
# set [key 이름] [value]
127.0.0.1:6379> set seonghwi:name "seonghwi kim" # 띄워쓰기 있으면 쌍따옴표로 묶어주가
OK
127.0.0.1:6379> set seonghwi:hobby soccer
OK
```

### 2) 🔍 저장한 데이터 조회하기 (Key로 Value 값 조회하기)

```bash
# get [key 이름]
127.0.0.1:6379> get seonghwi:name
"seonghwi kim"
127.0.0.1:6379> get seonghwi:hobby
"soccer"

127.0.0.1:6379> get ksh:name  # 없는 데이터를 조회할 경우 **(nil)** 라고 출력됨
(nil)
```

### 3) 🔍 저장된 모든 key 조회하기

```bash
127.0.0.1:6379> keys *
1) "seonghwi:hobby"
2) "seonghwi:name"
```

### 4) 🗑️ 데이터 삭제하기 (Key로 데이터 삭제하기)

```bash
# del [key 이름]
127.0.0.1:6379> del seonghwi:hobby
(integer) 1

127.0.0.1:6379> get seonghwi:hobby  # 삭제됐는 지 확인
(nil)
```

### 5) ⏰ 데이터 저장 시 만료시간(TTL) 정하기

**TTL(Time To Live)** 은 데이터를 Redis에 저장할 때 **얼마 동안 유지할지 시간을 정하는 기능.** 즉, 일정 시간이 지나면 Redis가 데이터를 자동 삭제하여 메모리를 효율적으로 관리할 수 있게 합니다.

### 왜 사용하나❓

Redis는 캐시(임시 저장소)로 많이 쓰이기 때문에 오래된 데이터를 계속 가지고 있으면 메모리를 낭비합니다.

그래서

- 일정 시간 후 필요 없어지는 데이터
- 잠깐만 유지하면 되는 데이터
- 자동 만료가 필요한 데이터

에 TTL을 설정합니다.

```bash
# set [key 이름] [value] **ex** [만료 시간(초)]
127.0.0.1:6379> set seonghwi:pet dog ex 30  # ex(expire)
```

### 6) ⏳만료시간(TTL) 확인하기

```bash
# ttl [key 이름] -> 만료 시간이 몇 초 남았는 지 반환
# 키가 없는 경우 -2를 반환
127.0.0.1:6379> set seonghwi:pet dog ex 30
OK
127.0.0.1:6379> ttl seonghwi:pet
(integer) 18
127.0.0.1:6379> ttl seonghwi:pet
(integer) 14
127.0.0.1:6379> ttl seonghwi:pet
(integer) -2  # 키가 없는 경우 -2를 반환 (여기서는 만료 시간이 끝났기 때문)

# 키는 존재하지만 만료 시간이 설정돼 있지 않은 경우에는 -1을 반환
127.0.0.1:6379>  ttl seonghwi:name
(integer) -1
```

### 7) 🧹 모든 데이터 삭제하기

```bash
127.0.0.1:6379> keys *
1) "seonghwi:name"
127.0.0.1:6379> flushall  # 모든 데이터 삭제
OK
127.0.0.1:6379> keys *
(empty array)  # 데이터가 존재 X
```

---

# 3. 🏷️ Redis에서 Key 네이밍 컨벤션 익히기

## 🧑‍💻 현업에서 자주 활용하는 네이밍 컨벤션

콜론(`:`)을 활용해 계층적으로 의미를 구분해서 사용

### 장점

1. 가독성
2. 일관성 → 유지 보수
3. 검색 및 필터링 용이성 → 패턴 매칭 용이
4. 확장상 → 이름 충돌 줄이기

---