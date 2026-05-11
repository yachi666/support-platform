#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER_DIR="$ROOT_DIR/support-roster-server"
STALE_MAIN_CLASS="$SERVER_DIR/target/classes/com/support/server/supportrosterserver/SupportRosterServerApplication 2.class"
STALE_MAIN_SOURCE="$SERVER_DIR/src/main/java/com/support/server/supportrosterserver/SupportRosterServerApplication 2.java"

export DB_URL="${DB_URL:-jdbc:postgresql://127.0.0.1:5432/support}"
export DB_USERNAME="${DB_USERNAME:-$(id -un 2>/dev/null || printf 'postgres')}"
export DB_PASSWORD="${DB_PASSWORD:-123456}"
PROXY_BYPASS_JAVA_OPTS="-Djava.net.useSystemProxies=false -DproxySet=false -Dhttp.proxyHost= -Dhttp.proxyPort= -Dhttps.proxyHost= -Dhttps.proxyPort= -DsocksProxyHost= -DsocksProxyPort= -Dhttp.nonProxyHosts=127.0.0.1|localhost -Dhttps.nonProxyHosts=127.0.0.1|localhost"

if ! command -v mvn >/dev/null 2>&1; then
  echo "[start-backend] Maven (mvn) is required but was not found in PATH. Install it with: brew install maven" >&2
  exit 1
fi

if [[ -f "$STALE_MAIN_CLASS" && ! -f "$STALE_MAIN_SOURCE" ]]; then
  rm -f "$STALE_MAIN_CLASS"
fi

cd "$SERVER_DIR"
exec env \
  JAVA_TOOL_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  JDK_JAVA_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  _JAVA_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  MAVEN_OPTS="$PROXY_BYPASS_JAVA_OPTS" \
  mvn -Dspring-boot.run.mainClass=com.support.server.supportrosterserver.SupportRosterServerApplication spring-boot:run
