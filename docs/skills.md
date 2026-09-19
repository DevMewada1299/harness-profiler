# Skills & connectors (local TrueForge)

What our demo agents can use, where each lives, and how to invoke it from the
UI. Grounded in the live instance at `http://localhost:8790` on 2026-09-19
(`GET /api/v1/skills`, `/api/v1/mcp-servers`, `/api/v1/agents`), not assumed.

## Mental model

TrueForge separates three things:

- **Connectors (MCP servers)** — raw remote tool endpoints. Live in
  **Settings → Connectors**.
- **Skills** — higher-level packaged workflows that sit *on top of* connectors.
  Live in **Settings → Skills**.
- **Agents** — a model + runtime config with connectors and/or skills *attached*.
  Composed in **Build Agent**, persisted with **Save Agent**.

You never "run a skill" directly. You **attach** it to an agent, then **prompt
the agent**; the model decides when to call the skill/tool during the run, and
you see the call appear inline in the session.

---

## Skills we need

### `wiki-qa`

- **What it does:** answers questions about a repository from its generated
  DeepWiki. Companion to `wiki-architect`.
- **Backed by:** the `deepwiki` connector.
- **Used by:** the **Research Tools Demo** agent.
- **Why it matters for the demo:** lets an agent understand a *whole* real
  codebase and answer grounded questions about it — the "bigger code" story —
  without a sandbox or any local clone.
- **Where it lives:** Settings → Skills (installed ✅).
- **Attach:** Build Agent → **Skills** section → add `wiki-qa` (preload off).

### `wiki-architect`

- **What it does:** plans and structures a repository wiki / brief from a
  codebase (DeepWiki). Use before `wiki-qa` when you want a structured overview
  rather than a single answer.
- **Backed by:** the `deepwiki` connector.
- **Used by:** optional — add to the Research Tools Demo if you want to show the
  plan-then-answer pair.
- **Where it lives:** Settings → Skills (installed ✅).
- **Attach:** Build Agent → **Skills** section → add `wiki-architect`.

> The **Python Fixer Demo** deliberately uses **no skills** — it is the minimal
> baseline agent (sandbox only). That is intentional, not a gap.

---

## Connectors (MCP servers) we need

All three are connected with `auth_status: not_required`.

| Connector | Endpoint | Role in the demo |
|---|---|---|
| `deepwiki` | `mcp.deepwiki.com/mcp` | powers `wiki-qa` / `wiki-architect`; understand a repo |
| `exa` | `mcp.exa.ai/mcp` | web/neural search fallback |
| `parallel-web` | `search.parallel.ai/mcp` | parallel web search fallback |

- **Where they live:** Settings → Connectors (all connected ✅).
- **Attach:** Build Agent → **MCP Servers** section → add each; set discovery to
  **deferred** (no preloaded tools) so the tool list stays short.

---

## Which agent uses what

| Agent | Sandbox | Skills | Connectors | Purpose |
|---|---|---|---|---|
| Python Fixer Demo (`codefixer1`) | on | none | none | fix failing tests in a fresh sandbox |
| Research Tools Demo | off | `wiki-qa` (+ optional `wiki-architect`) | `deepwiki`, `exa`, `parallel-web` | understand a real repo, answer grounded |

---

## How to call a skill from the UI

1. Sidebar → **Build Agent** (or open a saved agent from **Agents**).
2. In the **Skills** section, click add and pick the skill (e.g. `wiki-qa`).
   Leave preload off.
3. In the **MCP Servers** section, add any connectors the skill needs
   (`wiki-qa` needs `deepwiki`).
4. Type a prompt in the **"Ask anything…"** box that requires the skill, e.g.
   *"Using DeepWiki only, summarize the purpose of <repo> in two sentences."*
5. Send it. The model invokes the skill on its own — watch the session for the
   inline **tool call** (e.g. a `deepwiki` call) and its result.
6. **Save Agent** to keep the configuration so it appears under **Agents**.

You are not clicking a "run skill" button — you are giving the agent a task it
can only do *with* the skill, and confirming from the session trace that it
actually used it.
