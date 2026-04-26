
# ⌨️ Redis 기본 명령어 익히기

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