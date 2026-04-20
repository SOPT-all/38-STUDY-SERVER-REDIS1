# Redis Study

레디스 입문부터 실전 활용까지 함께 학습하는 스터디 레포입니다.

## 스터디 목표

- 레디스 핵심 개념 이해
- 실무에서 자주 쓰는 캐싱 패턴 익히기
- 성능 개선 관점에서 Redis 적용 경험 쌓기
- 매주 학습 내용 정리와 발표를 통해 설명 가능한 수준까지 정리하기

## 참가자

| 이름 | 폴더 ID |
| --- | --- |
| 김규일 | `gyuill-kim` |
| 이지현 | `jihyeon-lee` |
| 유서연 | `seoyeon-yoo` |
| 김성휘 | `seonghwi-kim` |
| 신진수 | `jinsu-shin` |

## 진행 방식

- 매주 월요일 21:00 디스코드 스터디룸 진행
- 해당 주차 과제는 스터디 전날인 일요일 23:59까지 PR 생성
- PR에는 이번 주 학습 내용 정리와 추가 학습 내용 1개 이상 포함
- 스터디 당일에는 발표자 1명이 주차 내용을 정리 발표하고, 이어서 Q&A 및 추가 학습 내용을 공유

## PR 작성 규칙

- 브랜치 예시: `week01/gyuill-kim`
- PR 제목 예시: `[Week 01] 김규일`
- 본인 주차 폴더에만 과제 정리
- 강의 내용 정리는 `README.md`에 작성
- 실습 결과물은 같은 폴더 안에 자유롭게 추가

## 폴더 구조

```text
.
├── .github/
│   └── pull_request_template.md
├── assignments/
│   ├── week01-sections-01-03/
│   │   ├── README.md
│   │   └── gyuill-kim/
│   │       ├── README.md
│   │       ├── practice-notes.md
│   │       └── example-code.js
│   └── ...
├── context.md
└── README.md
```

## 주차별 커리큘럼

아래 커리큘럼은 인프런 강의
[`비전공자도 이해할 수 있는 Redis 입문/실전 활용(성능 최적화편)`](https://www.inflearn.com/course/%EB%B9%84%EC%A0%84%EA%B3%B5%EC%9E%90-redis-%EC%9E%85%EB%AC%B8-%EC%84%B1%EB%8A%A5-%EC%B5%9C%EC%A0%81%ED%99%94?cid=334605#curriculum)
의 섹션 구성을 기준으로 2026-04-20에 정리했습니다.

| Week | 주제 | 강의 섹션 기준 |
| --- | --- | --- |
| 01 | 섹션 1~3 묶음 | Section 1. Orientation, Section 2. Redis Basic Concepts, Section 3. Learning how to use Redis |
| 02 | 섹션 4~6 묶음 | Section 4. Redis Caching Strategies, Section 5. Spring Boot + Redis, Section 6. Nest.js + Redis |
| 03 | 섹션 7~8 묶음 | Section 7. AWS EC2, Section 8. Load Testing |
| 04 | 섹션 9~10 묶음 | Section 9. Docker Compose, Section 10. AWS ElastiCache |

## 제출 가이드

각 주차 폴더의 본인 디렉터리 안에서 아래 방식으로 제출합니다.

- `README.md`: 강의 내용 정리
- 그 외 파일들: 실습 코드, 명령어 기록, 캡처 이미지, 예제 파일 등

`README.md`에는 아래 내용을 정리합니다.

1. 이번 주 학습 내용 요약
2. 실습 과정과 핵심 코드 또는 명령어
3. 문제 해결 과정 또는 트러블슈팅
4. 추가 학습 내용 1개 이상
5. 다음 주에 확인할 질문 또는 논의 포인트

주차별 범위는 아래 기준으로 제출합니다.

- Week 01: 섹션 1, 2, 3
- Week 02: 섹션 4, 5, 6
- Week 03: 섹션 7, 8
- Week 04: 섹션 9, 10

## 참고 자료

- 강의 링크: <https://www.inflearn.com/course/%EB%B9%84%EC%A0%84%EA%B3%B5%EC%9E%90-redis-%EC%9E%85%EB%AC%B8-%EC%84%B1%EB%8A%A5-%EC%B5%9C%EC%A0%81%ED%99%94?cid=334605#curriculum>
