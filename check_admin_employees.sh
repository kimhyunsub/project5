#!/bin/zsh

set -euo pipefail

BASE_URL="http://localhost:8091"
COOKIE_JAR="/tmp/admin-employees.cookies"
LOGIN_HTML="/tmp/admin-login.html"
LIST_JSON="/tmp/admin-employees-list.json"

curl -s -c "$COOKIE_JAR" "$BASE_URL/login" -o "$LOGIN_HTML"

CSRF_TOKEN=$(python3 - <<'PY'
import re
from pathlib import Path
html = Path("/tmp/admin-login.html").read_text()
m = re.search(r'name="_csrf" value="([^"]+)"', html)
print(m.group(1) if m else "")
PY
)

curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=re1560" \
  --data-urlencode "password=kftc2580" \
  --data-urlencode "_csrf=$CSRF_TOKEN" \
  -o /tmp/admin-login-post.html

curl -s -b "$COOKIE_JAR" "$BASE_URL/employees/list-data?page=1" -o "$LIST_JSON"

echo "==== list-data ===="
cat "$LIST_JSON"
