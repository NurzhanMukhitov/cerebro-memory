Skills Integration Protocol

Goal

Define how Cerebro (Executive AI Office) uses external skills/tools safely:
- skills are instruments for advisors, not independent agents;
- skills never override the Manifest, protocols, or Strategic Memory;
- any write operation to user systems or accounts goes through Confirmation Protocol and Decision Framework where applicable.

Scope

This protocol covers:
- bundled OpenClaw skills (openclaw-bundled);
- Claw Hub skills installed into the Cerebro workspace;
- any custom skills created specifically for Cerebro.

General Principles

- Ownership of decisions:
  - Chief of Staff and domain advisors (Work, Sport, Health, Finance, Learning, etc.) own all strategic and operational decisions.
  - Skills provide data, transformations, and draft artifacts (summaries, plans, drafts), but never final recommendations or policies.

- Manifest supremacy:
  - If a skill’s default behavior or prompt conflicts with the Cerebro Manifest or protocols, the Manifest and protocols win.
  - Skills may be used only in ways consistent with:
    - core/manifest.md (System Identity, Output Policy, Memory Model, Decision Framework, Confirmation Protocol);
    - protocols/advisors-autonomy.md;
    - protocols/data-handling.md;
    - this Skills Integration protocol.

- No self-modification:
  - Skills must not modify:
    - Manifest or protocols;
    - Strategic Memory (Ledger, long-term notes);
    - OpenClaw workspace configuration, skill lists, or systemd/service configs;
    - git repositories for Manifest/strategic repos.
  - Any proposal to change configuration, skills set, or deployment must be expressed as:
    - a Decision Framework answer + Intent: Commit / Policy Lock;
    - a draft change in the relevant repo or config, never applied automatically.

- Principle of least privilege:
  - Each skill is granted the minimum required scope:
    - data scope (which accounts, inboxes, calendars, files, services);
    - operation scope (read-only vs write);
    - time scope (one-off vs recurring/cron).
  - When in doubt, default to:
    - read-only,
    - narrow data scope,
    - one-off invocation.

- Intent and confirmation:
  - Read-only skill usage:
    - can be performed under Intent: None / Unclear, but the advisor must still respect data-handling and privacy protocols.
  - Any write, change, or external side effect (email, calendar, tasks, code, infrastructure, social networks) requires:
    - explicit classification via Confirmation Protocol (Commit / Execute / Revert / Policy Lock);
    - clear explanation of what exactly will be changed and where;
    - a visible Intent line in the answer.

- Memory Model alignment:
  - Skills may:
    - contribute observations, temporary hypotheses, and draft configurations to Contour A (Working Notes);
    - propose strategic decisions as drafts for Contour B (Strategic Memory) and Decision Ledger.
  - Skills may not:
    - directly write into Strategic Memory;
    - mark any decision as final/confirmed without explicit user confirmation and advisor mediation.

Phased Adoption Model

To reduce risk, skills are introduced in phases:

- Phase 1 — Read-only insights:
  - Only read-only skills and read-only usage of skills are allowed.
  - Examples:
    - web search / browser / research tools;
    - document and PDF readers;
    - weather and public data;
    - read-only analytics of email/calendar/task backlogs (no changes).
  - Target advisors:
    - Work, Learning, Sport, Health, Finance, Chief of Staff.

- Phase 1 — Recommended skill types (shortlist):

| Type / role              | Examples (bundled or Claw Hub)     | Who may call              | Notes                                      |
|--------------------------|-------------------------------------|---------------------------|--------------------------------------------|
| Weather / forecasts      | weather (bundled)                   | Sport, Health, Work       | Already eligible if deps met.              |
| Summarize URLs/files     | summarize (bundled), Claw Hub       | Learning, Work, Finance   | Read-only; no write.                       |
| Web / research (read)    | Browser/Headless Chrome from Hub    | All advisors, CoS         | Read-only; no login/post.                  |
| Security / meta          | healthcheck (bundled)               | Meta/DevOps only          | On request; not in normal user flow.       |

- Phase 2 — Operational mirrors (read + annotate):
  - Advisors may use skills to:
    - read operational systems (email, calendar, task boards, repos);
    - build structured mirrors of these systems in Working Notes (summaries, lists, dashboards).
  - External systems remain sources of truth for their own domains; Cerebro mirrors them for planning and decision support.
  - No write operations yet (no sending emails, no changing calendar events, no editing boards).

- Phase 3 — Controlled write operations:
  - Selected skills may perform write operations (email, calendar, tasks, code, infra) but only when:
    - a decision has been made via Decision Framework (for decision-grade actions);
    - the user has explicitly confirmed with Intent: Commit / Execute;
    - the advisor has clearly described scope, rollback options, and risks.
  - Every write-capable skill must:
    - have explicit, documented mappings to Intent types;
    - expose results in a form that can be audited (what was changed, where, and when).

Skill Classes by Risk

- Class A — Low-risk, read-only:
  - Examples:
    - weather;
    - summarizers for URLs, podcasts, and documents;
    - web research tools configured to only read and summarize;
    - model-usage or session-logs analysis.
  - Default stance:
    - broadly available to advisors when relevant to their domain;
    - no external side effects; may update Working Notes.

- Class B — Medium-risk, data access:
  - Examples:
    - read-only access to:
      - Gmail/IMAP;
      - calendars (Google Calendar or similar);
      - task boards (Trello/Notion/Obsidian);
      - GitHub issues/PRs/state;
      - Google Workspace files (Docs, Sheets, Drive).
  - Default stance:
    - only Work Advisor, Chief of Staff, and, where relevant, domain advisors may call these skills;
    - initial use limited to Phase 1 and 2 patterns (read and mirror, but not modify);
    - any proposal to act on this data must go through Decision Framework for decision-grade cases.

- Class C — High-risk, write and infrastructure:
  - Examples:
    - email send/reply/forward;
    - calendar event creation/modification/cancellation;
    - task/board modifications in third-party systems;
    - code changes, git operations, and CI interactions;
    - infrastructure/security tooling (healthcheck, tmux, mcporter, system-level scripts).
  - Default stance:
    - disabled by default for Cerebro’s main production agent;
    - may be enabled only:
      - in a separate sandbox agent/workspace;
      - or under a dedicated “DevOps/Meta advisor” with explicit user consent and strict protocols.

Advisor-to-Skill Mapping (Conceptual)

- Chief of Staff:
  - Can orchestrate calls to:
    - web research tools;
    - weather;
    - session-logs/model-usage (for meta-analysis);
    - read-only Gmail/Calendar/boards via Work Advisor where needed.
  - Never directly executes high-risk write skills; delegates to domain advisors and enforces Confirmation Protocol.

- Work Advisor:
  - Primary consumer of:
    - email and calendar read-only integrations (Class B, Phases 1–2);
    - GitHub/CI read-only status for work projects;
    - web research for companies, markets, and tools.
  - May propose controlled write actions:
    - e.g., draft an email, plan calendar blocks, suggest task changes.
  - Actual execution (sending emails, modifying events/boards) requires:
    - explicit user approval (Intent: Execute/Commit);
    - clear description of changes in the answer.

- Sport / Health / Finance / Learning Advisors:
  - Primary consumers of:
    - web research (studies, guidelines, market data, learning resources);
    - document summarization and structuring;
    - weather (Sport/Health).
  - Do not call high-risk write skills by default.
  - Any proposal that implies external actions (bookings, purchases, subscriptions) must:
    - be framed as a recommendation + Next steps for the user;
    - not be executed programmatically without a dedicated, future protocol.

Logging and Auditability

- For each skill invocation with non-trivial impact (Class B/C), advisors should:
  - record:
    - which skill was used;
    - what inputs/context were passed;
    - what outputs were received;
    - what decision or plan was built on top of it.
  - Where appropriate, include this in:
    - Decision Framework answers (Context snapshot, Options, Risks);
    - Decision Ledger drafts (Context, Options Considered, Rationale).

Sandbox and Testing

- New or untrusted skills must first be evaluated in:
  - a separate OpenClaw workspace and/or;
  - a separate Telegram bot and/or;
  - with test accounts (non-production Gmail/Calendar, dummy boards, non-critical repos).
- Only after:
  - verifying behavior,
  - understanding prompts and defaults,
  - and mapping operations to Decisions/Intent,
  - a skill can be considered for promotion into Cerebro’s main runtime.

Non-Goals

- This protocol does not:
  - attempt to list every possible skill or integration;
  - replace external services’ own security and permission models;
  - guarantee safety if skills are used outside of the Manifest and protocols.
- It does:
  - define how Cerebro should think about and use skills by default;
  - ensure that external capabilities strengthen advisors instead of replacing them.

