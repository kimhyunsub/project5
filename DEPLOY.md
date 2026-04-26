# Biz Home Deploy

`biz-home`은 빌드 단계가 없는 정적 사이트입니다.

파일:

- `index.html`
- `invite.html`
- `app.js`
- `invite.js`
- `styles.css`
- `config.js`

## 운영 기본값

현재 `config.js`에는 운영 기본 주소가 들어 있습니다.

```js
window.BIZ_HOME_API_BASE_URL = "https://api.hsft.io.kr/api";
window.BIZ_HOME_ADMIN_URL = "https://admin.hsft.io.kr/login";
```

운영 공개 도메인:

```text
https://biz.hsft.io.kr
```

운영 서버에서 다른 주소를 써야 하면 `config.js`만 수정하면 됩니다.

## 권장 배포 구조

예시 디렉터리:

```bash
/var/www/biz-home
```

배포 대상 파일:

```bash
index.html
invite.html
app.js
invite.js
styles.css
config.js
```

## Nginx 예시

예시 설정 파일은 [biz-home.conf.example](/Users/hyeonseobkim/workspace/attendance-app/biz-home/infra/nginx/biz-home.conf.example)에 있습니다.

일반적인 적용 순서:

```bash
sudo mkdir -p /var/www/biz-home
sudo cp -R . /var/www/biz-home
sudo cp infra/nginx/biz-home.conf.example /etc/nginx/sites-available/biz-home.conf
sudo ln -s /etc/nginx/sites-available/biz-home.conf /etc/nginx/sites-enabled/biz-home.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 빠른 수동 배포

서버에 SSH 접속이 가능하면 로컬에서 이렇게 올릴 수 있습니다.

```bash
rsync -av --delete \
  index.html invite.html app.js invite.js styles.css config.js \
  user@your-server:/var/www/biz-home/
```

## Windows 미니PC 배포

`C:\attendance-app\biz-home`에 저장소를 clone 해두었다면 아래 스크립트를 사용할 수 있습니다.

경로:

```text
C:\attendance-app\biz-home\scripts
```

파일:

- `deploy-prod.bat`
- `deploy-prod.ps1`
- `deploy-prod.vbs`
- `restart-prod.bat`
- `restart-prod.ps1`
- `restart-prod.vbs`

동작:

- `deploy-prod`
  - `git fetch`
  - `git checkout main`
  - `git pull origin main`
  - 필수 정적 파일 확인
  - `nginx.exe -s reload`

- `restart-prod`
  - 현재 파일 기준으로 `nginx.exe -s reload`만 실행

기본 nginx 경로:

```text
C:\nginx
```

다른 경로면 인자로 넘기면 됩니다.

예시:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-prod.ps1 -Branch main -NginxRoot "C:\nginx"
```

로컬 변경이 있어도 강제로 진행하려면:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-prod.ps1 -Branch main -ForceSync -NginxRoot "C:\nginx"
```

배치 파일로도 가능:

```bat
deploy-prod.bat -ForceSync -NginxRoot C:\nginx
restart-prod.bat -NginxRoot C:\nginx
```

## 확인 포인트

- 회사 가입 페이지: `https://biz.hsft.io.kr/`
- 초대 페이지: `/invite.html?token=...`
- 가입 완료 후 관리자 이동 주소: `config.js`의 `window.BIZ_HOME_ADMIN_URL`
- 가입 API 주소: `config.js`의 `window.BIZ_HOME_API_BASE_URL`

## 주의

- 현재 지도는 Leaflet CDN을 사용합니다.
- 운영 서버가 외부 CDN 접근이 제한된 환경이면 Leaflet 파일을 로컬 정적 파일로 내려받아 함께 서빙해야 합니다.
