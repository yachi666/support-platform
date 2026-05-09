# Vibe Coding in Practice: Building Support Platform for On-Call Rosters

> From “Who is on support today?” to “open the dashboard”: a practical build story for teams that run recurring support rotations.

![Public roster viewer](../assets/blog/support-platform-vibe-coding/public-viewer.png)

## Introduction

Most support teams start with the same improvised setup: an Excel file, a chat message, a wiki page, maybe a pinned announcement. It works until someone has to ask whether the version they found is still current.

Then the team grows. Rotations cross time zones. Ownership changes. Other departments need a reliable way to find the right person without asking around.

So I built **Support Platform**, a full-stack on-call roster management and display system. It has a public viewer for “who is covering now?” and an authenticated workspace for teams, staff, shift definitions, monthly rosters, imports, exports, and contact details.

> Note: the technical work for this product, from UI design and implementation to documentation, tests, and the first draft of this post, was done by AI. My role was to raise the idea, clarify the requirements through conversation with AI, and review the final result.

## The Problem

On-call rosters look simple until they become shared infrastructure.

- **One public source of truth** for current coverage.
- **Timezone-aware viewing**, especially when APAC, EMEA, and AMER all participate.
- **Escalation details** such as team email, xMatter, GSD, EIM, runbooks, and chat channels.
- **Regression coverage** for roster saving, permissions, imports, exports, and core UI flows.
- **Role-based permissions** so the viewer can stay public while workspace editing remains controlled.

The goal was to move roster work out of “spreadsheet plus tribal memory” and into a small product that people could trust.

## What the Product Does

### 1. Public Viewer: answer “who is on support?” without login

The public viewer shows teams, daily coverage, date controls, timezone controls, and a live timeline. In the refreshed demo data, L1, L2, L3, and several support teams have both day and night shifts, so the page shows full-day coverage across the screen. For partner teams, this becomes the front door: open the page, find the team, contact the current support owner.

![Public roster viewer](../assets/blog/support-platform-vibe-coding/public-viewer.png)

### 2. Monthly Planner: spreadsheet familiarity, structured data underneath

The monthly roster planner keeps the familiar grid interaction: people and teams on the left, dates across the top, shift codes in colored cells. Underneath, the roster is structured data that can be validated, imported, exported, and served through APIs.

![Monthly roster planner](../assets/blog/support-platform-vibe-coding/monthly-roster-planner.png)

### 3. Contact Directory: support is more than a name

When an incident happens, knowing the on-call person is only the first step. Teams also need escalation groups, service desk groups, EIM IDs, runbooks, and communication channels. The contact directory keeps those details close to the roster instead of scattering them across wikis and chat history.

![Contact directory](../assets/blog/support-platform-vibe-coding/contact-information.png)

## Implementation

The project is a full-stack workspace, not a single-page prototype:

- **Backend**: Spring Boot 4 + PostgreSQL for public viewer APIs, workspace APIs, authentication, roster persistence, and import/export.
- **Frontend**: Vue 3 + Vite for the public viewer, login flow, workspace layout, monthly planner, staff directory, team mapping, shift definitions, and contact directory.
- **Repository model**: a Git superproject that coordinates backend and frontend submodules, plus local scripts for starting PostgreSQL, the API, and the UI together.

The core design stays simple: public viewing and authenticated administration are separated, the backend owns persistence and business rules, and the frontend makes roster ownership, maintenance, and contact paths easy to scan.

```text
Support Platform
├── Public Viewer
│   ├── Teams
│   ├── Daily shifts
│   └── Timezone-aware timeline
├── Workspace Admin
│   ├── Staff / Teams / Shift Definitions
│   ├── Monthly Roster Planner
│   └── Import / Export
├── Contact Information
│   ├── Team email
│   ├── xMatter / GSD / EIM
│   └── Runbook links
└── Automation
    └── Playwright smoke and regression tests
```

## GitHub Links

The project is organized as a superproject with backend and frontend submodules. This keeps the application parts independent while the parent repository owns scripts, documentation, automation tests, and blog assets.

- Main repository: [support-platform](https://github.com/yachi666/support-platform)
- Backend service: [support-roster-server](https://github.com/yachi666/support-roster-server)
- Frontend app: [support-roster-ui](https://github.com/yachi666/support-roster-ui)
- Automation test project: [automationtest](https://github.com/yachi666/support-platform/tree/main/automationtest)
- Blog and screenshot assets: [docs](https://github.com/yachi666/support-platform/tree/main/docs)

## AI Toolchain: Design, Coding, Assets, and Verification

I will not spend much time defining coding agents here. The useful part is where each tool helped in the delivery loop: fast edits, cross-file implementation, UI assets, browser verification, and regression coverage.

- **Copilot CLI YOLO mode** handled small, well-scoped edits, script changes, and repetitive updates where the feedback loop was short.
- **Codex CLI** helped with cross-file understanding, implementation breakdowns, frontend/backend coordination, documentation updates, and pre-commit checks.
- **Codex + GPT image2** generated UI assets when the interface needed icons, placeholders, or lightweight visuals that could be brought back into the frontend asset system.
- **Agent plugin `Superpower`** made requirement clarification, design, test-driven work, debugging, and verification explicit instead of treating generation speed as the only goal.
- **Skills `frontend-design`** kept the frontend aligned with the real usage context of an internal roster management tool.
- **Playwright CLI + skills** drove a real browser for login, navigation, screenshots, page checks, and regression-script extraction.

The stack is less interesting than the loop. Design, implementation, assets, verification, and documentation all stayed close together, while tests and browser results set the quality bar.

## Automated Testing: Turning Browser Checks into Regression Assets

Automation was part of the build from the start. Backend tests lock down rules, browser checks validate workflows, and stable paths are promoted into Playwright regression coverage.

Backend development follows a more **test-driven** rhythm. APIs, domain rules, persistence behavior, and permission boundaries are pinned down with unit and service tests. Roster saving, contact creation, import/export behavior, and workspace access rules are worth protecting before the UI gets involved.

Frontend work benefits from **AI-assisted browser testing**. After a feature is implemented, I start the local backend and frontend, then drive the product in a real browser: log in, navigate, click, filter, save, and capture screenshots. For workspace routing, monthly roster editing, import/export, and contact directory browsing, a real browser check catches issues that component-level tests often miss.

Stable browser checks are then promoted into the standalone `automationtest/` project, where Playwright provides repeatable regression coverage:

- Login, logout, and protected-route redirects
- Workspace smoke coverage for core pages
- Admin permissions and readonly/editor boundaries
- Contact directory creation and display
- Monthly roster editing, import, export, and previous-month copy flows
- Roster persistence, import/export, and core page-state regression scenarios

New features follow the same pattern: **backend tests lock down the rules, AI browser testing validates the experience, and stable paths become Playwright scripts for future regression runs**. The next change is easier because the verification path is already there.

## Who Else Could Use This?

This started as a technical support roster, but the pattern fits many teams:

- SRE and DevOps on-call rotations
- L1 / L2 / L3 support teams
- Data platform support
- Application platform support
- Security incident response
- Release-window coverage
- Regional business support teams

If your team keeps answering “who is responsible today?”, “where is the escalation contact?”, or “is next month’s roster complete?”, this pattern may save you some operational drag.

## Contributions and Feature Requests

If your team has a similar rotation, on-call, escalation, or cross-department support workflow, feature requests and contributions are welcome:

- Product requirements and usage scenarios: [support-platform issues](https://github.com/yachi666/support-platform/issues)
- Backend APIs, data models, permissions, imports, and exports: [support-roster-server](https://github.com/yachi666/support-roster-server)
- Frontend pages, interactions, i18n, and visual experience: [support-roster-ui](https://github.com/yachi666/support-roster-ui)
- Browser regression, smoke tests, and test-data lifecycle: [automationtest](https://github.com/yachi666/support-platform/tree/main/automationtest)

The most useful feedback would be concrete: different rotation models, handoff or swap workflows, notification integrations, multi-time-zone requirements, permission boundaries, import/export formats, and the day-to-day cost of keeping roster data fresh.

## Closing

The best part is making support coverage visible, reliable, and testable.

For viewers, it is one place to find the current owner. For admins, it is a structured workspace. For other departments, it is a pattern they can reuse for their own rotations.

For me, the project was a useful reminder: when the problem is clear, the feedback loop is short, and browser verification is part of the work, an internal tool can move from idea to usable system quickly without giving up engineering discipline.
