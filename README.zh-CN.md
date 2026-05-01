# 🛡️ Support Platform

<div align="center">

**完整的值班排班管理系统，包含公开看板与工作台后台**

[English](./README.md) • [后端仓库](https://github.com/yachi666/support-roster-server) • [前端仓库](https://github.com/yachi666/support-roster-ui)

[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](./LICENSE)
[![Backend](https://img.shields.io/badge/Backend-Spring_Boot_4-6db33f?style=flat-square)](https://github.com/yachi666/support-roster-server)
[![Frontend](https://img.shields.io/badge/Frontend-Vue_3-42b883?style=flat-square)](https://github.com/yachi666/support-roster-ui)
[![Testing](https://img.shields.io/badge/Testing-Playwright-2ead33?style=flat-square)](./automationtest)

</div>

---

## 📖 项目概览

Support Platform 是一个 **Git 超级工程（superproject）**，统一编排了完整的值班排班系统。它将 Spring Boot 后端、Vue 3 前端、本地开发自动化和端到端浏览器测试整合在一个工作区中。

**适用于以下场景的团队：**
- 📅 发布值班覆盖信息，提供日期与时区控制
- 👥 管理排班数据、联系人和排期
- ✅ 校验排班质量，及早发现配置错误
- 🧪 在完整本地栈基础上维护浏览器回归测试

---

## ✨ 核心特性

- **🔐 多级权限体系** – 公开访问 + 工作台权限分级
- **📊 丰富的排班管理** – 月度规划、校验中心、联系人管理
- **🌐 时区感知** – 支持全球团队，灵活的日期/时区控制
- **🤖 完整自动化覆盖** – Playwright 测试覆盖登录、权限、路由和业务流程
- **🚀 一键本地开发** – 集成脚本完成 PostgreSQL + 后端 + 前端编排

---

## ⚡ 快速开始

```bash
# 克隆并初始化子模块
git clone https://github.com/yachi666/support-platform.git
cd support-platform
git submodule update --init --recursive

# 启动全栈服务（PostgreSQL + 后端 + 前端）
./scripts/dev/restart-all.sh
```

**默认本地访问地址：**

| 服务 | 地址 | 用途 |
|------|------|------|
| 🌐 **前端** | `http://127.0.0.1:5173` | 公开看板 + 管理工作台 |
| 🔌 **后端 API** | `http://127.0.0.1:8080/api` | REST 接口 |
| 💚 **健康检查** | `http://127.0.0.1:8080/actuator/health` | 服务状态 |

> **默认管理员账号：** 用户名 `admin`，密码 `admin`（详见 [`AGENTS.md`](./AGENTS.md)）

---

## 📦 仓库组成

本仓库是一个 **Git 超级工程（superproject）**。后端和前端位于 **Git 子模块（submodule）** 中，应用代码与工作区编排独立演进。

| 组件 | 类型 | 说明 |
|------|------|------|
| **[Support Roster Server](https://github.com/yachi666/support-roster-server)** | 子模块 | Spring Boot 后端 • Viewer/Workspace API • 认证 • 校验 • PostgreSQL 持久化 |
| **[Support Roster UI](https://github.com/yachi666/support-roster-ui)** | 子模块 | Vue 3 SPA • 公开排班看板 • 管理工作台 • 联系人管理 |
| **[Automation Test](./automationtest/)** | 父仓库 | Playwright 回归测试套件 • 登录/权限/路由/校验 |
| **[Development Scripts](./scripts/dev/)** | 父仓库 | 本地编排 • 启动/停止/重启/健康检查 |

---

## 📸 产品截图

**公开看板**按团队展示值班覆盖，提供日期与时区控制。**工作台页面**提供排班规划、校验、联系人管理和后台工具。

<table>
  <tr>
    <td width="50%"><b>公开排班看板</b><br/><img src="./docs/assets/screenshots/public-viewer.png" alt="公开看板"/></td>
    <td width="50%"><b>工作台总览</b><br/><img src="./docs/assets/screenshots/workspace-overview.png" alt="工作台总览"/></td>
  </tr>
  <tr>
    <td width="50%"><b>月度排班规划</b><br/><img src="./docs/assets/screenshots/workspace-roster.png" alt="月排班"/></td>
    <td width="50%"><b>校验中心</b><br/><img src="./docs/assets/screenshots/workspace-validation.png" alt="校验中心"/></td>
  </tr>
  <tr>
    <td colspan="2"><b>联系信息</b><br/><img src="./docs/assets/screenshots/contact-information.png" alt="联系信息"/></td>
  </tr>
</table>

---

## 🏗️ 仓库结构

```text
support-platform/               # ← 当前位置（Git 超级工程）
├── support-roster-server/      # Git 子模块 → 后端服务
├── support-roster-ui/          # Git 子模块 → 前端应用
├── automationtest/             # Playwright 自动化（父仓库）
├── scripts/dev/                # 本地开发脚本（父仓库）
├── docs/                       # 工作区文档
└── test/                       # 测试数据与脚手架
```

**理解子模块：**

父仓库只记录每个子模块的 **Git SHA**，不直接包含源码文件。这让应用开发与工作区编排保持独立。

```bash
# 检查子模块状态
git submodule status

# 同步子模块到记录的提交
git submodule update --init --recursive
```

**修改子模块时：**

1. **在子模块内**完成修改、提交、推送
2. 回到父仓库
3. 提交更新后的子模块指针
4. 按依赖顺序合并/推送：**先子模块，后父仓库**

> 📘 详见 [`AGENTS.md`](./AGENTS.md) 了解子模块工作流和 detached HEAD 处理

---

## 🛠️ 本地开发

### 前置要求

- **Java 21+**（用于 Spring Boot 后端）
- **Node.js 20.19+ 或 22.12+**（用于 Vue 前端）
- **PostgreSQL 16+**（本地或远程）
- **Git** 及子模块支持

### 环境配置

1. **初始化子模块：**
   ```bash
   git submodule update --init --recursive
   ```

2. **配置 PostgreSQL：**
   ```bash
   # 默认连接（需要时在 scripts/dev/*.sh 中调整）
   jdbc:postgresql://127.0.0.1:5432/support
   ```

3. **启动服务栈：**
   ```bash
   ./scripts/dev/restart-all.sh
   ```

   该脚本会：
   - ✅ 使用 `pg_isready` 检查 PostgreSQL 可用性
   - 🛑 停止端口 `8080` 和 `5173` 上的现有监听
   - 🚀 后台启动后端和前端
   - 💚 等待两个端点的健康检查通过
   - 📝 将运行日志写入 `.dev-runtime/logs/`

### 单独命令

```bash
./scripts/dev/start-backend.sh     # 启动后端（前台）
./scripts/dev/start-frontend.sh    # 启动前端（前台）
./scripts/dev/stop-all.sh          # 停止所有服务
```

> 📘 详见 [`scripts/dev/README.md`](./scripts/dev/README.md) 了解环境变量和高级配置

---

## 🧪 测试

使用**共享自动化工程**进行登录、工作台冒烟、路由守卫、权限和校验回归：

```bash
cd automationtest
npm install
npm run install:browsers    # 安装 Playwright 浏览器
npm run precheck            # 验证环境
npm run test:smoke          # 运行冒烟测试
```

> **说明：** `npm run test:smoke` 会先自动重启后端和前端服务；如果本地环境已经启动，可改用 `npm run test:smoke:raw`。

**测试覆盖：**
- 🔐 认证流程与受保护路由重定向
- 📄 工作台页面冒烟测试
- 🛡️ 管理员专属导航与权限检查
- ✅ 校验中心回归场景
- 📋 联系信息增删改查

> 📘 详见 [`automationtest/README.md`](./automationtest/README.md) 了解详细测试文档与配置

---

## 📚 文档导航

| 组件 | 文档 |
|------|------|
| **🖥️ 后端** | [README](https://github.com/yachi666/support-roster-server/blob/main/README.md) • [API 规范](https://github.com/yachi666/support-roster-server/blob/main/.specs/_index.md) |
| **🌐 前端** | [README](https://github.com/yachi666/support-roster-ui/blob/main/README.md) • [UI 规范](https://github.com/yachi666/support-roster-ui/blob/main/.specs/spec.md) |
| **🤖 自动化** | [测试指南](./automationtest/README.md) |
| **⚙️ 开发脚本** | [编排文档](./scripts/dev/README.md) |
| **🔧 工作区** | [Agent 指令](./AGENTS.md) – 子模块工作流与约定 |

---

## 🤝 贡献指南

本项目采用 **Git 超级工程 + 子模块**架构：

- **应用代码变更：** 请直接向 [support-roster-server](https://github.com/yachi666/support-roster-server) 或 [support-roster-ui](https://github.com/yachi666/support-roster-ui) 提交
- **自动化/脚本变更：** 向本仓库的 `automationtest/` 或 `scripts/` 目录提交
- **子模块更新：** 遵循 [`AGENTS.md`](./AGENTS.md) 中的工作流

请查阅各组件的 README 了解具体贡献指南。

---

## 📄 许可证

父级工作区采用 [MIT License](./LICENSE)。

**注意：** 子模块可能有独立许可证。单独分发前请查看各项目的 `LICENSE` 文件。

---

<div align="center">

**为值班团队用心打造 ❤️**

[问题反馈](https://github.com/yachi666/support-platform/issues) • [后端仓库](https://github.com/yachi666/support-roster-server) • [前端仓库](https://github.com/yachi666/support-roster-ui)

</div>
