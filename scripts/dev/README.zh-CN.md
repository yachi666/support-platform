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
| `./scripts/dev/init-admin.sh` | 初始化首个本地管理员账号，并绑定到有效的引导团队。 |
| `./scripts/dev/test-restart-all.sh` | 验证重启脚本行为。 |

## 推荐入口

```bash
./scripts/dev/restart-all.sh
```

`restart-all.sh` 是推荐的本地开发入口。它会：

1. 解析 `DB_URL`，并通过 `pg_isready` 或 `psql` 检查 PostgreSQL 服务可用性。
2. 当目标是本地数据库且服务未启动时，默认自动拉起 Homebrew PostgreSQL。
3. 第一次启动时，如果本地目标数据库不存在，会自动创建。
4. 停止 `8080` 和 `5173` 端口上的旧监听。
5. 后台启动后端和前端。
6. 等待 `http://127.0.0.1:8080/actuator/health`。
7. 等待 `http://127.0.0.1:5173`。
8. 将运行日志写入 `.dev-runtime/logs/`。

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
| `START_LOCAL_POSTGRES_WITH_BREW` | 重启预检 | `auto` |

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

### 初始化首个管理员

```bash
./scripts/dev/init-admin.sh
```

脚本会创建或更新一个可重复使用的本地引导管理员，默认值如下：

- 员工 ID：`admin`
- 密码：`admin`
- 团队：`System Admin`

它会确保管理员绑定到一个有效团队，这样空库首启时跑 validation 冒烟不会额外冒出无关的 `Missing Team` 问题。

常见覆盖方式：

```bash
ADMIN_STAFF_ID=alice \
ADMIN_PASSWORD=secret123 \
ADMIN_TEAM_NAME="Workspace Admin" \
./scripts/dev/init-admin.sh
```

## PostgreSQL 预检

如果 PostgreSQL 无法被启动或验证，`restart-all.sh` 会在停止现有服务前退出，避免数据库不可用时破坏仍然可用的前后端会话。

要求：

- `DB_URL` 必须使用 `jdbc:postgresql://host[:port]/database` 格式。
- `PATH` 中至少要有 `pg_isready` 或 `psql` 其中之一。
- 若希望首次启动时自动建本地库，需要 `psql` 和 `createdb` 可用。
- `START_LOCAL_POSTGRES_WITH_BREW=auto` 是默认值，只会对本地数据库目标自动执行 `brew services start postgresql`；设为 `0` 可禁用自动启动，设为 `1` 可强制启用。

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
