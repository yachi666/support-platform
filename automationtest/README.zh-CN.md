# Automation Test

[English](./README.md)

这是支持排班平台的可复用 Playwright 自动化测试工程。它位于父级工作区中，用于同时覆盖 `support-roster-ui`、`support-roster-server` 和本地开发脚本，避免在任一子模块里散落一次性浏览器脚本。

## 覆盖范围

| 范围 | 检查内容 |
|------|----------|
| 认证 | 登录冒烟、账号激活前提、受保护路由重定向。 |
| 工作台冒烟 | 已认证用户可加载核心工作台页面。 |
| 权限 | 管理员导航和受限路由访问。 |
| 联系信息 | 公开列表/搜索和管理员创建流程。 |
| 校验回归 | Missing primary coverage、失效引用、清理确认和校验重算流程。 |
| Linux 密码 | Linux 密码页的路由保护和冒烟覆盖。 |
| 排班回归 | 排班规划行为的浏览器回归覆盖。 |

## 目录说明

```text
automationtest/
├── config/       # 环境加载与 Playwright 配置
├── fixtures/     # 共享 Playwright fixtures
├── helpers/      # 认证、API 客户端、DB helper、建数契约、清理注册
├── pages/        # Page Object Models
├── scripts/      # 预检脚本
├── specs/        # 测试用例
└── artifacts/    # 报告和运行产物
```

## 前置条件

- Node.js `^20.19.0 || >=22.12.0`
- npm
- Playwright 浏览器二进制
- 本地前后端依赖
- 运行 DB 建数回归时需要 PostgreSQL

安装依赖和 Chromium：

```bash
cd automationtest
npm install
npm run install:browsers
```

## 环境变量

复制 `.env.example` 为 `.env`，按需调整。

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `AUTOTEST_BASE_URL` | `http://127.0.0.1:5173` | 前端地址。 |
| `AUTOTEST_API_BASE_URL` | `http://127.0.0.1:8080/api` | 后端 API 基础地址。 |
| `AUTOTEST_DB_URL` | `postgresql://localhost:5432/support` | DB 建数使用的 PostgreSQL 地址。 |
| `AUTOTEST_DEFAULT_TIMEOUT_MS` | `15000` | 共享 Playwright 超时时间。 |
| `AUTOTEST_TRACE` | `retain-on-failure` | Playwright trace 策略。 |
| `AUTOTEST_WORKERS` | `1` | 本地稳定运行的 worker 数量。 |
| `AUTOTEST_STAFF_ID` | 代码中为空，示例为 `123456` | 主冒烟测试员工 ID。 |
| `AUTOTEST_PASSWORD` | 代码中为空，示例为 `12345678` | 主冒烟测试密码。 |

后续权限矩阵可使用以下可选账号：

```text
AUTOTEST_ADMIN_STAFF_ID
AUTOTEST_ADMIN_PASSWORD
AUTOTEST_EDITOR_STAFF_ID
AUTOTEST_EDITOR_PASSWORD
AUTOTEST_READONLY_STAFF_ID
AUTOTEST_READONLY_PASSWORD
```

## 运行测试

默认入口会通过 `../scripts/dev/restart-all.sh` 重启本地服务，执行预检，然后运行 Playwright。

```bash
npm run test
npm run test:smoke
npm run test:validation
```

如果服务已经启动，并且明确希望跳过重启步骤，可使用 raw 入口：

```bash
npm run test:raw
npm run test:smoke:raw
npm run test:validation:raw
```

交互和调试命令：

```bash
npm run test:headed
npm run test:ui
npm run codegen
```

## 当前用例

```text
specs/auth/linux-password-route-guard.spec.mjs
specs/auth/login-smoke.spec.mjs
specs/auth/route-guard.spec.mjs
specs/contact-information/admin-create.spec.mjs
specs/contact-information/public-list.spec.mjs
specs/permissions/admin-route-access.spec.mjs
specs/workspace/core-smoke.spec.mjs
specs/workspace/linux-passwords-smoke.spec.mjs
specs/workspace/roster-regression.spec.mjs
specs/workspace/validation-cleanup-regression.spec.mjs
specs/workspace/validation-regression.spec.mjs
```

## 数据生命周期

工程优先复用手工准备好的测试环境，但对于不建数就不稳定的回归场景，用例会创建隔离数据。

两层 helper 负责控制生命周期：

| Helper | 作用 |
|--------|------|
| `helpers/seed-contracts.mjs` | 描述测试所需数据，并按需创建场景数据。 |
| `helpers/cleanup-registry.mjs` | 注册清理步骤，确保 API 和 DB 创建的数据在测试后回收。 |

建议：

- 合法且用户可触达的数据状态优先通过公开 API 或工作台 API 构造。
- 只有正常 API 难以稳定制造的脏数据回归，才使用 PostgreSQL 直连建数。
- 新增建数时同步注册清理步骤。

## 排查建议

- 环境不确定时先运行 `npm run precheck`。
- 只有确认前后端已启动时才使用 `npm run test:raw`。
- 默认命令启动失败时，查看 `.dev-runtime/logs/backend.log` 和 `.dev-runtime/logs/frontend.log`。
- 新增浏览器测试应沉淀在本工程中，不要散落到 UI 或 Server 子模块。

## 许可证

本工程是私有工作区工具。当前 package metadata 标注为 `MIT`。
