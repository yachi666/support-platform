# Support Workspace Agent Instructions

本目录为工作区根目录，涉及具体子项目的实现、规范维护与变更流程时，请优先遵循对应子项目中的说明：

- 服务端项目：`@support-roster-server/AGENT.md`
- 前端项目：`@support-roster-ui/AGENT.md`

## 使用说明

- 修改 `support-roster-server/` 下内容时，遵循 `@support-roster-server/AGENT.md`
- 修改 `support-roster-ui/` 下内容时，遵循 `@support-roster-ui/AGENT.md`
- 若一次任务同时涉及前后端，需同时满足两个子项目中的要求
- 如存在规范维护、spec 同步、导航更新等要求，以对应子项目文档为准

## 浏览器自动化测试

- 本仓库已提供独立自动化测试工程：`@automationtest/`
- 涉及登录流程、核心页面冒烟、权限路由校验、浏览器回归验证时，优先复用 `automationtest`，不要临时散落新的浏览器脚本
- 推荐顺序：
  - 先执行 `cd automationtest && npm run precheck`
  - 再执行 `npm run test:smoke` 或按需运行 `specs/` 下的指定用例
- 当前 `automationtest` 默认复用手工准备好的本地环境；后续若新增自动建数/清数，应沿用现有的 `helpers/seed-contracts.mjs` 与 `helpers/cleanup-registry.mjs` 扩展，不要绕开这套生命周期
- 如浏览器验证流程或测试工程结构发生变化，需同步更新 `automationtest/README.md`
