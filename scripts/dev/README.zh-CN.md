# Development Scripts

[English](./README.md)

这是支持排班工作区的本地编排脚本集合。除非脚本另有说明，所有命令都应从仓库根目录执行。

## 命令总览

| 命令 | 用途 |
|------|------|
| `./scripts/dev/start-backend.sh` | 前台启动 `support-roster-server`。 |
| `./scripts/dev/start-frontend.sh` | 前台启动 `support-roster-ui`。 |
| `./scripts/dev/stop-all.sh` | 停止已记录的服务和默认端口监听。 |
| `./scripts/dev/restart-all.sh` | 后台重启前后端并等待健康检查。 |
| `./scripts/dev/test-restart-all.sh` | 验证重启脚本行为。 |

## 推荐入口

```bash
./scripts/dev/restart-all.sh
```

`restart-all.sh` 是推荐的本地开发入口。它会：

1. 解析 `DB_URL`，并通过 `pg_isready` 检查 PostgreSQL 可用性。
2. 当 `START_LOCAL_POSTGRES_WITH_BREW=1` 时，可选择启动 Homebrew PostgreSQL。
3. 停止 `8080` 和 `5173` 端口上的旧监听。
4. 后台启动后端和前端。
5. 等待 `http://127.0.0.1:8080/actuator/health`。
6. 等待 `http://127.0.0.1:5173`。
7. 将运行日志写入 `.dev-runtime/logs/`。

## 默认值

| 变量 | 使用方 | 默认值 |
|------|--------|--------|
| `DB_URL` | 后端与重启预检 | `jdbc:postgresql://127.0.0.1:5432/support` |
| `DB_USERNAME` | 后端与 PostgreSQL 可用性检查 | 当前系统用户，脚本内有兜底 |
| `DB_PASSWORD` | 后端 | `123456` |
| `HOST` | 前端 | `127.0.0.1` |
| `PORT` | 前端 | `5173` |
| `BACKEND_HEALTH_URL` | 重启健康检查 | `http://127.0.0.1:8080/actuator/health` |
| `FRONTEND_URL` | 重启健康检查 | `http://127.0.0.1:5173` |
| `START_LOCAL_POSTGRES_WITH_BREW` | 重启预检 | `0` |

## 单独命令

### 启动后端

```bash
./scripts/dev/start-backend.sh
```

以前台方式启动 Spring Boot 服务，适合需要直接在终端观察后端日志时使用。

### 启动前端

```bash
./scripts/dev/start-frontend.sh
```

以前台方式启动 Vite 开发服务器。

### 停止服务

```bash
./scripts/dev/stop-all.sh
```

停止已记录的后台进程，以及 `8080` 和 `5173` 端口上的监听。即使没有进程运行也会正常退出。

### 重启服务

```bash
./scripts/dev/restart-all.sh
```

后台启动前后端，并在健康检查时禁用本地代理环境变量。日志写入：

```text
.dev-runtime/logs/backend.log
.dev-runtime/logs/frontend.log
```

## PostgreSQL 预检

如果 PostgreSQL 不可用，`restart-all.sh` 会在停止现有服务前退出，避免数据库不可用时破坏仍然可用的前后端会话。

要求：

- `DB_URL` 必须使用 `jdbc:postgresql://host[:port]/database` 格式。
- `pg_isready` 必须存在于 `PATH`。
- 只有明确希望脚本执行 `brew services start postgresql` 时，才设置 `START_LOCAL_POSTGRES_WITH_BREW=1`。

## 示例

```bash
DB_URL=jdbc:postgresql://127.0.0.1:5432/support \
DB_USERNAME="$(id -un)" \
DB_PASSWORD=123456 \
./scripts/dev/restart-all.sh
```

重启成功后会输出：

```text
Frontend: http://127.0.0.1:5173
Backend health: http://127.0.0.1:8080/actuator/health
Backend log: .dev-runtime/logs/backend.log
Frontend log: .dev-runtime/logs/frontend.log
```
