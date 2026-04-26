# biz-home

사업자 가입용 정적 웹 페이지입니다.

현재 로컬 포트와 서버 역할 정리는 [LOCAL_DEV_ENV.md](/Users/hyeonseobkim/workspace/attendance-app/biz-home/LOCAL_DEV_ENV.md)를 참고하세요.
운영 배포 방법은 [DEPLOY.md](/Users/hyeonseobkim/workspace/attendance-app/biz-home/DEPLOY.md)를 참고하세요.

## 로컬 확인

`biz-home` 디렉터리에서 정적 서버를 실행하면 됩니다.

```bash
python3 -m http.server 4174
```

브라우저에서 `http://localhost:4174`로 접속하면 회사 가입 페이지를 확인할 수 있습니다.

직원 초대 링크 활성화 페이지는 `http://localhost:4174/invite.html?token=...` 형식으로 열 수 있습니다.

백엔드 기본 API 주소는 다음 규칙을 사용합니다.

- `localhost`에서 열면 `http://localhost:8090/api`
- `192.168.x.x`, `10.x.x.x` 같은 내부망 주소에서 열면 `http://현재접속호스트:8090/api`
- 그 외 호스트에서는 `https://api.hsft.io.kr/api`

다른 주소를 쓰고 싶다면 페이지 로드 전에 `window.BIZ_HOME_API_BASE_URL` 값을 주입해 덮어쓸 수 있습니다.
