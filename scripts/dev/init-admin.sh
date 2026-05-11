#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKEND_API_URL="${BACKEND_API_URL:-http://127.0.0.1:8080/api}"
DB_URL="${DB_URL:-jdbc:postgresql://127.0.0.1:5432/support}"
DB_USERNAME="${DB_USERNAME:-$(id -un 2>/dev/null || printf 'postgres')}"
DB_PASSWORD="${DB_PASSWORD:-123456}"
ADMIN_STAFF_ID="${ADMIN_STAFF_ID:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
ADMIN_NAME="${ADMIN_NAME:-Admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_TIMEZONE="${ADMIN_TIMEZONE:-UTC}"
ADMIN_TEAM_NAME="${ADMIN_TEAM_NAME:-System Admin}"
ADMIN_TEAM_COLOR="${ADMIN_TEAM_COLOR:-#334155}"
ADMIN_TEAM_VISIBLE="${ADMIN_TEAM_VISIBLE:-false}"

TEAM_ID="${ADMIN_TEAM_ID:-900000000000001000}"
STAFF_ID_NUMERIC="${ADMIN_STAFF_RECORD_ID:-900000000000001001}"
ACCOUNT_ID="${ADMIN_ACCOUNT_ID:-900000000000001101}"

log() {
  echo "[init-admin] $*"
}

jdbc_host=""
jdbc_port=""
jdbc_database=""

parse_jdbc_url() {
  local normalized_url
  local authority

  normalized_url="${DB_URL#jdbc:postgresql://}"
  if [[ "$normalized_url" == "$DB_URL" ]]; then
    log "DB_URL must use jdbc:postgresql://host[:port]/database format."
    return 1
  fi

  normalized_url="${normalized_url%%\?*}"
  authority="${normalized_url%%/*}"
  jdbc_database="${normalized_url#*/}"

  if [[ -z "$authority" || -z "$jdbc_database" || "$jdbc_database" == "$normalized_url" ]]; then
    log "DB_URL must include both a PostgreSQL host and database name."
    return 1
  fi

  jdbc_host="${authority%%:*}"
  jdbc_port="5432"
  if [[ "$authority" == *:* ]]; then
    jdbc_port="${authority##*:}"
  fi
}

normalize_admin_team_visible() {
  local normalized_visible

  normalized_visible="$(printf '%s' "$ADMIN_TEAM_VISIBLE" | tr '[:upper:]' '[:lower:]')"

  case "$normalized_visible" in
    true|false)
      ADMIN_TEAM_VISIBLE="$normalized_visible"
      ;;
    *)
      log "ADMIN_TEAM_VISIBLE must be either true or false."
      return 1
      ;;
  esac
}

psql_exec() {
  PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h "$jdbc_host" -p "$jdbc_port" -U "$DB_USERNAME" -d "$jdbc_database" "$@"
}

json_field() {
  local field_name="$1"
  python3 - "$field_name" <<'PY'
import json
import sys

field = sys.argv[1]
payload = json.load(sys.stdin)
value = payload[field]
if isinstance(value, str):
    print(value)
else:
    print(json.dumps(value, ensure_ascii=True))
PY
}

activate_or_verify_login() {
  local activate_body
  local activate_response
  local login_response
  local http_code

  activate_body="$(printf '{"staffId":"%s","newPassword":"%s"}' "$ADMIN_STAFF_ID" "$ADMIN_PASSWORD")"
  activate_response="$(curl -sS -w $'\n%{http_code}' -H 'Content-Type: application/json' -d "$activate_body" "$BACKEND_API_URL/auth/activate")"
  http_code="$(printf '%s' "$activate_response" | tail -n 1)"
  activate_response="$(printf '%s' "$activate_response" | sed '$d')"

  if [[ "$http_code" == "200" ]]; then
    log "Admin account activated for staff_id=$ADMIN_STAFF_ID"
    return 0
  fi

  login_response="$(curl -sS -w $'\n%{http_code}' -H 'Content-Type: application/json' -d "$(printf '{"staffId":"%s","password":"%s"}' "$ADMIN_STAFF_ID" "$ADMIN_PASSWORD")" "$BACKEND_API_URL/auth/login")"
  http_code="$(printf '%s' "$login_response" | tail -n 1)"
  login_response="$(printf '%s' "$login_response" | sed '$d')"

  if [[ "$http_code" == "200" ]]; then
    log "Admin account already active and login succeeded for staff_id=$ADMIN_STAFF_ID"
    return 0
  fi

  log "Activation failed: $activate_response"
  log "Login verification failed: $login_response"
  return 1
}

main() {
  parse_jdbc_url
  normalize_admin_team_visible

  log "Ensuring bootstrap team, staff, and account records exist."
  psql_exec <<SQL
BEGIN;

INSERT INTO workspace_team (
  id,
  name,
  color,
  display_order,
  visible,
  description,
  deleted
) VALUES (
  ${TEAM_ID},
  '${ADMIN_TEAM_NAME//\'/\'\'}',
  '${ADMIN_TEAM_COLOR//\'/\'\'}',
  0,
  ${ADMIN_TEAM_VISIBLE},
  'Bootstrap team for the first local admin account.',
  0
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  color = EXCLUDED.color,
  visible = EXCLUDED.visible,
  description = EXCLUDED.description,
  deleted = 0;

INSERT INTO workspace_staff (
  id,
  staff_id,
  name,
  email,
  timezone,
  team_id,
  status,
  deleted
) VALUES (
  ${STAFF_ID_NUMERIC},
  '${ADMIN_STAFF_ID//\'/\'\'}',
  '${ADMIN_NAME//\'/\'\'}',
  '${ADMIN_EMAIL//\'/\'\'}',
  '${ADMIN_TIMEZONE//\'/\'\'}',
  ${TEAM_ID},
  'Active',
  0
)
ON CONFLICT (id) DO UPDATE SET
  staff_id = EXCLUDED.staff_id,
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  timezone = EXCLUDED.timezone,
  team_id = EXCLUDED.team_id,
  status = EXCLUDED.status,
  deleted = 0;

INSERT INTO workspace_account (
  id,
  staff_record_id,
  staff_id,
  role_code,
  account_status,
  password_hash,
  auth_source,
  notes,
  deleted,
  token_version
) VALUES (
  ${ACCOUNT_ID},
  ${STAFF_ID_NUMERIC},
  '${ADMIN_STAFF_ID//\'/\'\'}',
  'admin',
  'PENDING_ACTIVATION',
  NULL,
  'LOCAL_PASSWORD',
  'Bootstrap admin account managed by scripts/dev/init-admin.sh',
  0,
  1
)
ON CONFLICT (id) DO UPDATE SET
  staff_record_id = EXCLUDED.staff_record_id,
  staff_id = EXCLUDED.staff_id,
  role_code = EXCLUDED.role_code,
  auth_source = EXCLUDED.auth_source,
  notes = EXCLUDED.notes,
  deleted = 0;

COMMIT;
SQL

  if ! curl -fsS "$BACKEND_API_URL/../actuator/health" >/dev/null 2>&1; then
    log "Backend health check failed at ${BACKEND_API_URL%/api}/actuator/health"
    return 1
  fi

  activate_or_verify_login
  log "Admin initialization completed: staff_id=$ADMIN_STAFF_ID password=$ADMIN_PASSWORD"
}

main "$@"
