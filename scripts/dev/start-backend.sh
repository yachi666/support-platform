#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export DB_URL="${DB_URL:-jdbc:postgresql://127.0.0.1:5432/support}"
export DB_USERNAME="${DB_USERNAME:-$(id -un 2>/dev/null || printf 'postgres')}"
export DB_PASSWORD="${DB_PASSWORD:-123456}"
PROXY_BYPASS_JAVA_OPTS="-Djava.net.useSystemProxies=false -DproxySet=false -Dhttp.proxyHost= -Dhttp.proxyPort= -Dhttps.proxyHost= -Dhttps.proxyPort= -DsocksProxyHost= -DsocksProxyPort= -Dhttp.nonProxyHosts=127.0.0.1|localhost -Dhttps.nonProxyHosts=127.0.0.1|localhost"

cd "$ROOT_DIR/support-roster-server"
exec env \
  JAVA_TOOL_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  JDK_JAVA_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  _JAVA_OPTIONS="$PROXY_BYPASS_JAVA_OPTS" \
  MAVEN_OPTS="$PROXY_BYPASS_JAVA_OPTS" \
  mvn spring-boot:run
