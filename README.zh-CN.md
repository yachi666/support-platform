# Support Platform

[English](./README.md)

![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Backend](https://img.shields.io/badge/Backend-Spring_Boot_4-6db33f?style=flat-square)
![Frontend](https://img.shields.io/badge/Frontend-Vue_3-42b883?style=flat-square)
![Testing](https://img.shields.io/badge/Testing-Playwright-2ead33?style=flat-square)

Support Platform 是支持排班系统的父级工作区，组合了 Spring Boot API、Vue 3 公开/后台 UI、本地开发编排脚本，以及可复用的 Playwright 回归自动化。

它面向需要发布 on-call 覆盖、维护排班主数据、校验排班质量，并让浏览器冒烟测试贴近完整本地栈的团队。

## 工作区组成

| 组件 | 路径 | 说明 |
|------|------|------|
| Support Roster Server | [`support-roster-server/`](./support-roster-server/) | Spring Boot 后端，提供 viewer API、workspace API、认证、校验、导入和 PostgreSQL 持久化。 |
| Support Roster UI | [`support-roster-ui/`](./support-roster-ui/) | Vue 3 SPA，承载公开排班看板、管理工作台、联系信息、产品更新和受保护工具页。 |
| Automation Test | [`automationtest/`](./automationtest/) | Playwright 冒烟与回归测试，覆盖登录、路由守卫、工作台页面、权限和校验流程。 |
| Development Scripts | [`scripts/dev/`](./scripts/dev/) | 本地前后端启动、停止、重启和健康检查脚本。 |

## 效果截图

公开看板按支持团队展示 on-call 覆盖，并提供日期与时区控制。工作台页面覆盖排班维护、校验、权限和运营流程。

| 公开看板 | 工作台总览 |
|---|---|
| ![公开排班看板](./docs/assets/screenshots/public-viewer.png) | ![工作台总览](./docs/assets/screenshots/workspace-overview.png) |

| 月排班 | 校验中心 |
|---|---|
| ![月排班页面](./docs/assets/screenshots/workspace-roster.png) | ![校验中心](./docs/assets/screenshots/workspace-validation.png) |

| 联系信息 |
|---|
| ![联系信息页面](./docs/assets/screenshots/contact-information.png) |

## 快速开始

```bash
git submodule update --init --recursive
./scripts/dev/restart-all.sh
```

默认本地地址：

| 服务 | 地址 |
|------|------|
| 前端 | `http://127.0.0.1:5173` |
| 后端健康检查 | `http://127.0.0.1:8080/actuator/health` |
| 后端 API | `http://127.0.0.1:8080/api` |

## 仓库模型

本仓库是 Git superproject。后端和前端位于 Git submodule 中，因此应用代码变更和父级工作区变更需要分别提交。

父仓库只记录每个子模块的 Git SHA，不直接包含后端或前端源码内容。

```bash
git submodule status
git submodule update --init --recursive
```

修改子模块时：

1. 先在对应子模块内提交并推送。
2. 回到父仓库。
3. 提交更新后的子模块指针。
4. 按依赖顺序合并或推送：先子模块，后父仓库。

## 仓库结构

```text
support-platform/
├── support-roster-server/    # Git submodule: 后端服务
├── support-roster-ui/        # Git submodule: 前端应用
├── automationtest/           # 父仓库中的 Playwright 自动化工程
├── scripts/dev/              # 父仓库中的本地开发脚本
├── docs/assets/screenshots/  # README 使用的精选截图
├── docs/                     # 父仓库文档
└── test/                     # 父仓库测试资源
```

## 本地开发

推荐本地入口：

```bash
./scripts/dev/restart-all.sh
```

该脚本会检查 PostgreSQL 可用性，重启后端和前端，等待健康检查，并将日志写入 `.dev-runtime/logs/`。

常用直接命令：

```bash
./scripts/dev/start-backend.sh
./scripts/dev/start-frontend.sh
./scripts/dev/stop-all.sh
```

## 测试

登录、工作台冒烟、路由守卫、权限和校验回归请优先使用共享自动化工程：

```bash
cd automationtest
npm install
npm run precheck
npm run test:smoke
```

浏览器验证使用的默认本地管理员账号见 [`AGENTS.md`](./AGENTS.md)。自动化环境变量账号见 [`automationtest/.env.example`](./automationtest/.env.example)。

## 文档入口

| 范围 | 入口 |
|------|------|
| 后端 README | [`support-roster-server/README.md`](https://github.com/yachi666/support-roster-server/blob/main/README.md) |
| 后端 specs | [`support-roster-server/.specs/_index.md`](https://github.com/yachi666/support-roster-server/blob/main/.specs/_index.md) |
| 前端 README | [`support-roster-ui/README.md`](https://github.com/yachi666/support-roster-ui/blob/main/README.md) |
| 前端 specs | [`support-roster-ui/.specs/spec.md`](https://github.com/yachi666/support-roster-ui/blob/main/.specs/spec.md) |
| 自动化 README | [`automationtest/README.md`](./automationtest/README.md) |
| 开发脚本 README | [`scripts/dev/README.md`](./scripts/dev/README.md) |

## 许可证

父级工作区采用 [MIT License](./LICENSE)。子模块可能有独立许可证，单独分发前请查看对应项目的 `LICENSE`。
