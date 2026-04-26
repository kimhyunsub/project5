# Local Dev Environment

2026-04-01 기준 로컬 개발 환경 메모입니다.

## 현재 사용하는 포트

- `backend`: `http://localhost:8090`
- `admin-web`: `http://localhost:8091`
- `mobile web`: `http://localhost:19006`
- `biz-home` 정적 페이지: `http://localhost:4174`

## 각 서버 역할

- `8090`
  백엔드 API 서버입니다.
  `biz-home`, `mobile web`, `admin-web`가 모두 이 API를 사용합니다.

- `8091`
  사업자 관리자 웹입니다.
  회사 가입 후 이 로그인 페이지로 이동합니다.

- `19006`
  Expo 기반 모바일 웹입니다.
  직원 초대 링크는 여기로 연결됩니다.
  초대 토큰이 있으면 사번을 자동으로 읽고 로그인 첫 화면에 반영합니다.

- `4174`
  `biz-home` 정적 안내/가입 페이지입니다.
  회사 최초 가입 페이지를 제공합니다.

## 현재 연결 규칙

### 회사 가입

- 시작 페이지: `http://localhost:4174`
- 가입 API: `http://localhost:8090/api/auth/company-signup`
- 가입 완료 후 이동: `http://localhost:8091/login`

### 직원 초대

- 관리자 웹에서 초대 링크 생성
- 초대 링크 기본 주소: `http://localhost:19006?token=...`
- 모바일 웹에서 사번 자동 입력
- 초대 진입 시 비밀번호 입력칸은 숨김
- `등록 시작`을 누르면 첫 로그인 비밀번호 변경 흐름으로 진행

## 주의할 점

- 초대 링크는 더 이상 `biz-home/invite.html`을 기본으로 쓰지 않습니다.
- 초대 링크 테스트는 `19006` 모바일 웹에서 확인해야 합니다.
- 관리자 웹은 현재 로컬 기본값으로 초대 링크를 `19006`으로 생성하도록 맞춰져 있습니다.

## admin-web UI 메모

- `admin-web`은 서버 렌더링 기반 관리자 웹입니다.
- 최근 `직원 목록` 화면부터 점진적으로 `Vue 3`를 도입했습니다.
- `Vue`는 CDN이 아니라 프로젝트 내부 정적 파일을 사용합니다.
- 로컬 Vue 파일: [vue.global.prod.js](/Users/hyeonseobkim/workspace/attendance-app/admin-web/src/main/resources/static/vendor/vue.global.prod.js)
- 직원 목록 Vue 스크립트: [employees-vue.js](/Users/hyeonseobkim/workspace/attendance-app/admin-web/src/main/resources/static/js/employees-vue.js)
- 직원 목록 템플릿: [employees.html](/Users/hyeonseobkim/workspace/attendance-app/admin-web/src/main/resources/templates/employees.html)

## 실행 중이던 프로세스 메모

2026-04-01 확인 시점:

- `backend` listening on `8090`
- `admin-web` listening on `8091`
- `mobile web` listening on `19006`
- `biz-home` static server listening on `4174`
