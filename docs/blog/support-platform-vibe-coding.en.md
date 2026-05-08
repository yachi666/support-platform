# 🛡️ I Built an On-Call Roster Platform with 100% Vibe Coding

> From “Who is on support today?” to “Open the dashboard”: a lightweight product story for teams that run recurring support rotations.

![Public roster viewer](/Users/lzn/.codex/worktrees/3884/support/docs/assets/blog/support-platform-vibe-coding/public-viewer.png)

## Introduction

Every support team eventually invents the same ritual: an Excel file, a chat message, a wiki page, a pinned announcement, and someone asking whether the version they found is still the latest one.

That works for a while. Then the team grows, rotations span time zones, support ownership changes, and other departments need a reliable way to find the right person without asking around.

So I built **Support Platform**, a full-stack on-call roster management and display system. It has a public viewer for “who is covering now?” and an authenticated workspace for managing teams, staff, shift definitions, monthly rosters, imports, exports, and contact information.

And yes: this was built with **100% vibe coding**. Not as a toy demo, but as a real internal tool shaped through conversation, fast implementation, browser verification, and repeated product iteration. 🚀

## The Problem

On-call rosters look simple until they become shared infrastructure.

- 📅 **People need one public source of truth** for current coverage.
- 🌍 **Time zones matter**, especially when APAC, EMEA, and AMER all participate.
- 👥 **Escalation details matter**: team email, xMatter, GSD, EIM, runbooks, and chat channels.
- ✅ **Regression quality matters**: roster saving, permissions, imports, exports, and core UI flows should remain testable.
- 🔐 **Permissions matter**: viewers can be public, but workspace editing needs role-based access.

The goal was not to build “a prettier spreadsheet.” The goal was to turn roster operations into a small but dependable product.

## What the Product Does

### 1. Public Viewer: answer “who is on support?” without login

The public viewer shows teams, daily coverage, date controls, timezone controls, and a live timeline. For partner teams, this becomes the front door: open the page, find the team, contact the current support owner.

![Public roster viewer](/Users/lzn/.codex/worktrees/3884/support/docs/assets/blog/support-platform-vibe-coding/public-viewer.png)

### 2. Monthly Planner: spreadsheet familiarity, structured data underneath

The monthly roster planner keeps the familiar grid interaction: people and teams on the left, dates across the top, shift codes in colored cells. Under the surface, the data is structured, validated, exported, imported, and shared through APIs.

![Monthly roster planner](/Users/lzn/.codex/worktrees/3884/support/docs/assets/blog/support-platform-vibe-coding/monthly-roster-planner.png)

### 3. Contact Directory: support is more than a name

When an incident happens, knowing the on-call person is only step one. Teams also need escalation groups, service desk groups, EIM IDs, runbooks, and communication channels. The contact directory brings those details into the same support workflow.

![Contact directory](/Users/lzn/.codex/worktrees/3884/support/docs/assets/blog/support-platform-vibe-coding/contact-information.png)

## Implementation

The project is a full-stack workspace, not a single-page prototype:

- 🖥️ **Backend**: Spring Boot 4 + PostgreSQL for public viewer APIs, workspace APIs, authentication, roster persistence, and import/export.
- 🌐 **Frontend**: Vue 3 + Vite for the public viewer, login flow, workspace layout, monthly planner, staff directory, team mapping, shift definitions, and contact directory.
- 🧩 **Repository model**: a Git superproject that coordinates backend and frontend submodules, plus local scripts for starting PostgreSQL, the API, and the UI together.

The core design is intentionally straightforward: public viewing and authenticated administration are separated, the backend owns persistence and business rules, and the frontend focuses on making roster ownership, maintenance, and contact paths easy to scan.

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

## Automated Testing: Turning Vibe Coding into a Regression Loop

Automation was not an afterthought in this project. It was part of the product workflow from the beginning. The idea was simple: AI can help move faster, but every new capability should leave behind a repeatable way to prove it still works.

Backend development follows a more **test-driven** rhythm. APIs, domain rules, persistence behavior, and permission boundaries are pinned down with unit and service tests. Roster saving, contact creation, import/export behavior, and workspace access rules are the kind of behaviors that should be protected by backend tests before the UI ever gets involved.

Frontend work benefits from **AI-assisted browser testing**. After a feature is implemented, I start the local backend and frontend, then drive the product in a real browser: log in, navigate, click, filter, save, and capture screenshots. For flows like workspace routing, monthly roster editing, import/export, and contact directory browsing, a real browser check catches issues that component-level tests often miss.

Stable browser checks are then promoted into the standalone `automationtest/` project, where Playwright provides repeatable regression coverage:

- 🔐 Login, logout, and protected-route redirects
- 🧭 Workspace smoke coverage for core pages
- 🛡️ Admin permissions and readonly/editor boundaries
- 📋 Contact directory creation and display
- 📅 Monthly roster editing, import, export, and previous-month copy flows
- ✅ Roster persistence, import/export, and core page-state regression scenarios

New features follow the same pattern: **backend tests lock down the rules, AI browser testing validates the experience, and stable paths become Playwright scripts for future regression runs**. That is what makes vibe coding useful beyond the first burst of speed.

## What “100% Vibe Coding” Meant Here

For this project, vibe coding did not mean randomly generating code and hoping for the best. It meant keeping the feedback loop extremely tight:

1. Start from the real workflow pain, not from a technical abstraction.
2. Shape the product through conversation: pages, APIs, data models, and workflow rules.
3. Implement a slice, start the local stack, and verify it in the browser.
4. Adjust the interaction when the page feels hard to scan or the data story feels weak.
5. Keep tests, screenshots, local scripts, and documentation in the same delivery loop.

That style works especially well for internal tools. The users are close, the workflows are concrete, and the value is easy to validate: can people find the current support owner, can admins maintain the month, and can the system catch bad roster data before it causes confusion?

## Who Else Could Use This?

Although this started as a technical support roster, the same pattern fits many teams:

- SRE and DevOps on-call rotations
- L1 / L2 / L3 support teams
- Data platform support
- Application platform support
- Security incident response
- Release-window coverage
- Regional business support teams

If your team keeps answering “who is responsible today?”, “where is the escalation contact?”, or “is next month’s roster complete?”, this pattern is probably reusable.

## Closing

The real win is not replacing a spreadsheet. The real win is turning support coverage into a reliable, visible, validated workflow.

For viewers, it is one place to find the current owner. For admins, it is a structured workspace. For other departments, it is a pattern they can reuse for their own rotations.

And for me, it was a useful reminder: when the problem is clear, the feedback loop is fast, and browser verification is part of the flow, **100% vibe coding can move an internal product from idea to usable system surprisingly quickly.** ✨
