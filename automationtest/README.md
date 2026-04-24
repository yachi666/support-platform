# automationtest

独立的浏览器自动化工程，面向 `support-roster-ui` / `support-roster-server` 的可复用 E2E 冒烟与权限路由验证。

## 当前目标

- 登录流程冒烟
- 受保护路由校验
- 核心工作台页面冒烟
- 为后续角色权限回归、业务流程回归、自动化建数/清数预留扩展点
- workspace validation blocker 回归

## 设计原则

- **松耦合**：页面对象、认证、断言、数据生命周期分层
- **可扩展**：先做 smoke / route checks，后续可平滑扩到完整 E2E
- **环境可复用**：支持手工准备测试环境，也为后续自动建数留接口
- **清理可控**：即使首版不自动造数，也内置 cleanup registry，后续建数时能自动回收

## 目录结构

```text
automationtest/
  config/      # 环境与项目配置
  fixtures/    # Playwright fixtures
  helpers/     # 认证、断言、清理、数据契约
  pages/       # Page Object Models
  scripts/     # 预检脚本
  specs/       # 测试用例
  artifacts/   # 报告与运行产物
```

## 环境变量

复制 `.env.example` 为本地 `.env`，按需填写：

- `AUTOTEST_BASE_URL`
- `AUTOTEST_API_BASE_URL`
- `AUTOTEST_DB_URL`
- `AUTOTEST_STAFF_ID`
- `AUTOTEST_PASSWORD`

后续扩展角色权限回归时，再补 `AUTOTEST_ADMIN_*` / `AUTOTEST_EDITOR_*` / `AUTOTEST_READONLY_*`。

本地默认 smoke 账号当前可使用：

- `AUTOTEST_STAFF_ID=123456`
- `AUTOTEST_PASSWORD=12345678`

## 使用方式

```bash
cd automationtest
npm install
npm run test:smoke
```

默认测试入口会先调用仓库根目录下的 `scripts/dev/restart-all.sh`，重启本地前后端服务并等待健康检查通过，然后再执行 `precheck` 与 Playwright。

如需在服务已就绪时跳过重启，可使用原始入口：

```bash
npm run test:raw
npm run test:smoke:raw
npm run test:validation:raw
```

## 数据准备与清理

当前默认模式是**复用手工准备环境**，测试本身不主动建数。

但工程已经预留了两类扩展：

1. `helpers/seed-contracts.mjs`
   - 用来描述“测试运行前应该存在什么数据”
   - 当前只做环境契约检查
   - 后续可以扩展为自动建数入口

2. `helpers/cleanup-registry.mjs`
   - 每条测试都可注册 cleanup step
   - 当前即使无建数，也统一走同一生命周期
   - 后续接入建数后，无需改测试外层结构

当前已经接入两类自动建数回归：

- `seedMissingPrimaryCoverageScenario`
  - 自动创建 team / staff / primary shift / non-primary shift
  - 在独立 future month 写入仅非 primary 的 roster assignment
  - 触发 `Missing Primary Coverage`
  - 测试结束后自动删除 shift / staff / team
- `seedValidationCleanupScenario`
  - 通过 API 创建独立 team / primary shift
  - 通过 `AUTOTEST_DB_URL` 直连 PostgreSQL，插入：
    - `Invalid Team Scope`
    - `Orphan Assignment`
  - 在浏览器中验证 `立即修复 -> 预览删除 -> 二次确认 -> 校验重算`
  - 测试结束后自动回收 DB 脏数据和 API 建立的 team / shift

建议分层扩展：

1. 优先用公开 API 构造“合法但高风险”的数据
   - 例如 `Missing Primary Coverage`
   - 优点是最接近真实用户路径，维护成本低
2. 对于公开 API 无法稳定制造的脏状态，再补 DB 直连 seed
   - 例如失效引用、历史脏 assignment、绕过正常写路径的异常数据
   - 这类场景应单独标注为 `corruption-regression`

## 当前首批用例

- `specs/auth/login-smoke.spec.mjs`
- `specs/auth/route-guard.spec.mjs`
- `specs/workspace/core-smoke.spec.mjs`
- `specs/workspace/validation-regression.spec.mjs`
- `specs/workspace/validation-cleanup-regression.spec.mjs`
- `specs/permissions/admin-route-access.spec.mjs`

## 后续建议

- 加 `storageState` 缓存，区分 UI 登录冒烟与 API 登录加速用例
- 加 editor / readonly 角色矩阵
- 加自动建数与自动清数
- 加 CI profile 与测试环境隔离
