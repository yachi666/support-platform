# Support Platform

[English](./README.md)

Support Platform 是支持排班产品的父级工作区，集中管理后端服务、Vue 前端、本地开发脚本，以及可复用的 Playwright 自动化测试工程。

本仓库是 Git superproject。实际应用代码位于 Git submodule 中，因此父仓库提交与子模块提交需要分别处理。

## 项目组成

| 项目 | 路径 | 说明 |
|------|------|------|
| Support Roster Server | [`support-roster-server/`](./support-roster-server/) | Spring Boot 后端，提供 viewer API、workspace API、认证、校验、导入和 PostgreSQL 持久化。 |
| Support Roster UI | [`support-roster-ui/`](./support-roster-ui/) | Vue 3 SPA，承载公开排班看板、管理工作台、联系信息、产品更新和受保护工具页。 |
| Automation Test | [`automationtest/`](./automationtest/) | Playwright 冒烟与回归测试，覆盖登录、路由守卫、工作台页面、权限和校验流程。 |
| Development Scripts | [`scripts/dev/`](./scripts/dev/) | 本地前后端启动、停止、重启和健康检查脚本。 |

## 效果示例

公开看板按支持团队展示 on-call 时间线，并提供日期与时区控制。

![公开看板时间线示例](./test/viewer-white-bg-check.png)

## 仓库结构

```text
support-platform/
├── support-roster-server/    # Git submodule: 后端服务
├── support-roster-ui/        # Git submodule: 前端应用
├── automationtest/           # 父仓库中的 Playwright 自动化工程
├── scripts/dev/              # 父仓库中的本地开发脚本
├── docs/                     # 父仓库文档
├── test/                     # 父仓库测试/视觉资源
└── .plans/                   # Agent 本地计划记录
```

## 子模块工作流

父仓库只记录子模块的 Git SHA，不记录子模块内文件内容。

```bash
git submodule status
git submodule update --init --recursive
```

修改子模块时建议按以下顺序：

1. 先在子模块仓库内完成提交和推送。
2. 回到父仓库。
3. 提交更新后的子模块指针。
4. 如需创建 PR，按依赖顺序处理：先子模块，后父仓库。

## 本地开发

推荐使用统一重启入口：

```bash
./scripts/dev/restart-all.sh
```

该脚本会检查 PostgreSQL 可用性，重启后端和前端，等待健康检查，并将日志写入 `.dev-runtime/logs/`。

默认访问地址：

| 服务 | 地址 |
|------|------|
| 前端 | `http://127.0.0.1:5173` |
| 后端健康检查 | `http://127.0.0.1:8080/actuator/health` |
| 后端 API | `http://127.0.0.1:8080/api` |

## 浏览器自动化

登录、工作台冒烟、路由守卫、权限和校验回归请优先使用共享自动化工程：

```bash
cd automationtest
npm install
npm run precheck
npm run test:smoke
```

本地 workspace 冒烟测试默认账号：

```text
AUTOTEST_STAFF_ID=123456
AUTOTEST_PASSWORD=12345678
```

## 文档入口

| 范围 | 入口 |
|------|------|
| 后端 README | [`support-roster-server/README.md`](./support-roster-server/README.md) |
| 后端 specs | [`support-roster-server/.specs/_index.md`](./support-roster-server/.specs/_index.md) |
| 前端 README | [`support-roster-ui/README.md`](./support-roster-ui/README.md) |
| 前端 specs | [`support-roster-ui/.specs/spec.md`](./support-roster-ui/.specs/spec.md) |
| 自动化 README | [`automationtest/README.md`](./automationtest/README.md) |
| 开发脚本 README | [`scripts/dev/README.md`](./scripts/dev/README.md) |

## 许可证

父级工作区采用 [Apache License 2.0](./LICENSE)。子模块可能有独立许可证，单独分发前请查看对应项目的 `LICENSE`。
