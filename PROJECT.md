# Harness Profiler

## What this project is

A profiler that measures how **agent harness design choices** change the inference
load of a coding agent — and a rule layer that turns those measurements into
per-task recommendations.

Everyone else benchmarks hardware with the harness held fixed. We hold the
hardware fixed and vary the harness.

## The use case

A coding agent that fixes failing tests in a small repo.

- Pass/fail is objective (the test runner decides), so no subjective grading.
- Tasks are small and cheap, so we can run many repeats.
- Every harness capability TrueForge exposes actually matters for coding.

## Platform

[TrueForge](https://trueforge.dev) — open-source agent harness (TrueFoundry).
Run locally with `npx @truefoundry/trueforge` (SQLite, no extra infra).
Drive it from code via its TypeScript SDK (`@truefoundry/trueforge-core`),
REST + SSE, OpenAPI docs at `/api/v1/docs`.

Model calls are routed through TrueFoundry's AI Gateway so we get per-call
cost, timing, retries and fallback without touching agent code.

## What a "design choice" is

A decision about how the loop is built around the model. The model and the task
stay the same; the plumbing differs, and so does the load on inference.

Variants we test (one setting changed at a time):

| Variant | What changes |
|---|---|
| `baseline` | plain loop, no extras |
| `subagents_on` | side jobs delegated to helper agents (more calls, parallel, separate contexts) |
| `compaction_on` | old history summarized when context grows (one extra call now, shorter prompts later) |
| `deferred_tools_on` | short tool list up front, details loaded on demand (shorter prompts) |
| `code_mode_on` | model writes one script instead of many separate tool calls (fewer round trips) |

## Input → Output

**Input:** 10–15 coding tasks, each tagged by *shape* (files touched, expected
turns, search-heavy vs edit-heavy), run under each variant, repeated 3–5 times.

**Output:**
1. Trace files (`traces/*.jsonl`) — one JSON line per event.
2. A comparison table per variant: model calls, tokens, TTFT, tool-wait,
   cache reuse, pass rate, cost per success.
3. **Conditional rules** — the actual deliverable. e.g. "subagents help on
   wide-search tasks, hurt on single-file edits; crossover at ~3 files touched."

**Stretch goal:** feed the rules back so the harness picks its own settings
per task (harness-level co-design).

## Success criteria

- Pipeline runs end to end unattended.
- Numbers repeat across runs (report spread, not just medians).
- At least two conditional rules stated with the evidence behind them.

## Architecture

```
              TASK SET (repo + broken tests + task cards)
                          |
   =========== A's SIDE (collector/) ==============
                          |
                    [ RUNNER ]  loops task x variant x repeat
                          |  TypeScript SDK
                    TrueForge server ---- tools: grep, read, edit, run_tests
                          |                      (approval on edit)
                          |  model calls
                  TrueFoundry AI Gateway ---- model provider
                          |
        [ TRACE WRITER ]  <- SSE events + session data + gateway logs
                          |
   ============= traces/*.jsonl  (THE CONTRACT) =============
                          |
   =========== B's SIDE (analyzer/) ===============
                          |
                    [ PARSER ]     jsonl -> normalized run objects
                    [ METRICS ]    per-run numbers
                    [ AGGREGATOR ] per-variant, across repeats
                    [ RULES ]      conditional findings by task shape
                    [ REPORT ]     single HTML page
```

### Two seams into TrueForge

1. **Above** — the runner drives the server via the SDK. TTFT is measured as the
   wall-clock gap between sending a turn and the first token event arriving on
   the SSE stream. Token counts and step details come from the session after the
   run ends.
2. **Below** — TrueForge's model provider points at the AI Gateway. That is the
   only place we see the raw bytes sent to the model, which is the only reliable
   way to compute prefix stability and cache hit ratio.

Both seams write to the same trace file, joined by `run_id` (passed to the
gateway as a header/metadata).

3. **(Stretch)** TrueForge is open source — if a capability we want to vary is
   not exposed as config, patch the server. Do not start here.

## Metrics to compute

**Build first (these give real findings):**
- prefix stability — does the start of the prompt stay byte-identical between
  turns? Anything changing near the front (timestamps, session IDs, reshuffled
  tool lists) kills cache reuse.
- cache hit ratio — cached input / total input, per turn; should climb over a run
- idle breakdown — wall time split into generating / tool wait / sandbox wait /
  approval wait
- tool result size — which tool floods the context
- cost per successful task (not per run)

**Then:**
- context growth curve (prompt tokens vs turn number)
- prefill:decode ratio (input vs output tokens)
- burstiness — concurrent in-flight calls over time (subagents spike this)
- tool list overhead — tokens spent on tool definitions every call
- round trips per unit of work (calls per file edited)
- reasoning token share; reasoning replay cost
- compaction: trigger points, extra call cost, tokens saved after, pass-rate impact
- subagent overhead: setup tokens vs summary tokens returned
- tool failure/retry rate
- variance across repeats (wide spread = unstable setting, a finding in itself)

## Ground rules for agents working in this repo

- The trace schema in `TRACE_SCHEMA.md` is a contract between two people
  working in parallel. **Do not change it without saying so explicitly.**
- `collector/` and `analyzer/` are owned by different people. Stay in your lane;
  do not edit across the boundary.
- Sample traces in `samples/` let the analyzer be built before any real run
  exists. Always keep the analyzer working against them.
- One setting changed per variant. Never two.
- Report spread across repeats, never a single run.
- Do not invent numbers. If a metric can't be derived from the trace, say so.
