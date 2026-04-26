# Support Workspace Agent Instructions

本目录为工作区根目录，涉及具体子项目的实现、规范维护与变更流程时，请优先遵循对应子项目中的说明：

- 服务端项目：`@support-roster-server/AGENTS.md`
- 前端项目：`@support-roster-ui/AGENTS.md`

## 使用说明

- 修改 `support-roster-server/` 下内容时，遵循 `@support-roster-server/AGENTS.md`
- 修改 `support-roster-ui/` 下内容时，遵循 `@support-roster-ui/AGENTS.md`
- 若一次任务同时涉及前后端，需同时满足两个子项目中的要求
- 如存在规范维护、spec 同步、导航更新等要求，以对应子项目文档为准

## 版本控制结构

- 本仓库 `support-platform/` 是 **git superproject**，不是单仓 monorepo。
- 以下两个目录是 **git submodule**：
  - `support-roster-server/` → `https://github.com/yachi666/support-roster-server.git`
  - `support-roster-ui/` → `https://github.com/yachi666/support-roster-ui.git`
- `automationtest/`、`docs/`、`scripts/` 等目录属于父仓库普通目录，**不是** submodule。

### 关键规则

- 父仓库提交的不是子项目文件内容，而是子模块的 **gitlink SHA**。
- 判断父仓库是否干净时，如果子模块工作区 HEAD 与父仓库记录的 SHA 不一致，父仓库会显示子模块为已修改状态。
- 当父仓库执行 `git submodule update --init --recursive` 后，子模块通常会被检出到父仓库记录的提交；此时子模块 **可能处于 detached HEAD**，这属于正常现象。
- 子模块自己的 `main` / feature branch 可以继续向前，但**父仓库是否一致**只取决于父仓库当前记录的子模块 SHA。

### 涉及 submodule 的标准操作顺序

1. 先在对应子模块内完成修改、提交、推送。
2. 回到父仓库，更新子模块指针（gitlink SHA）。
3. 在父仓库提交子模块指针变更。
4. 如果创建 PR，通常按依赖顺序处理：**子模块 PR 先合，父仓库 PR 后合**。

### 排查与同步命令

- 查看父仓库记录的子模块状态：`git submodule status`
- 将子模块同步到父仓库记录的提交：`git submodule update --init --recursive`
- 查看父仓库是否仅因子模块 SHA 漂移而变脏：`git status --short`
- 查看某个子模块当前实际 HEAD：在子模块目录执行 `git rev-parse HEAD`

### 当前项目理解约束

- 讨论“本地是否和远端 main 一致”时，要分别区分：
  - 父仓库 `support-platform`
  - 子模块仓库自身的 `main`
  - 父仓库当前记录的子模块 SHA
- 不要默认“子模块本地在 main 分支上”或“子模块 HEAD 就等于父仓库记录值”；这两者都需要单独检查。

## 浏览器自动化测试

- 本仓库已提供独立自动化测试工程：`@automationtest/`
- 涉及登录流程、核心页面冒烟、权限路由校验、浏览器回归验证时，优先复用 `automationtest`，不要临时散落新的浏览器脚本
- 浏览器测试涉及 workspace 管理员登录时，可直接使用默认账号密码：用户名 `admin`，密码 `admin`
- 推荐顺序：
  - 先执行 `cd automationtest && npm run precheck`
  - 再执行 `npm run test:smoke` 或按需运行 `specs/` 下的指定用例
- 当前 `automationtest` 默认复用手工准备好的本地环境；后续若新增自动建数/清数，应沿用现有的 `helpers/seed-contracts.mjs` 与 `helpers/cleanup-registry.mjs` 扩展，不要绕开这套生命周期
- 如浏览器验证流程或测试工程结构发生变化，需同步更新 `automationtest/README.md`
