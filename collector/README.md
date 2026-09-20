# collector/ — teammate A

Owns everything that produces traces. Nothing here reads analysis code.

## Current state (2026-09-19)

Discovery is done and the full benchmark is **gated**, so no `traces/` exist yet
— on purpose (we don't fake numbers). What works today:

- **Discovery findings:** [`docs/sdk-findings.md`](../docs/sdk-findings.md) —
  what the SDK/SSE actually expose, and the gates: provider is direct OpenAI (no
  gateway → no raw prompt / cache / cost / `run_id`), the Daytona image lacks a
  C++/Rust toolchain, and `compaction`/`code_mode` aren't cleanly one-setting
  toggles.
- **Working local demo (not a benchmark):** a Python fixer that repairs failing
  tests in a fresh Daytona sandbox. Task card
  [`tasks/python-unittest-calculator-01.json`](../tasks/python-unittest-calculator-01.json),
  runbook [`docs/python-trueforge-demo-runbook.md`](../docs/python-trueforge-demo-runbook.md).
  Fixture pinned at `cpp-to-rust-calculator-fixture@0b0cc56` (branch `python-demo`).
- **Ripwire as a host-run MCP connector:** makes the `ripwire_on` variant
  measurable via named tools (no schema change). Start it with
  [`ripwire-serve.sh`](ripwire-serve.sh); optional login auto-start in
  [`dev.harness.ripwire.plist`](dev.harness.ripwire.plist); agent instructions
  in [`docs/agent-instructions-ripwire.md`](../docs/agent-instructions-ripwire.md).
- **Demo scripts:** [`docs/demo-script-cpp-to-rust.md`](../docs/demo-script-cpp-to-rust.md)
  (read-aloud, placeholders for live values).

The sections below are the **target** runner — build them once the gates clear.

## Responsibilities

1. Run TrueForge locally (`npx @truefoundry/trueforge`).
2. Configure the agent's tools: `grep`, `read_file`, `edit_file`,
   `run_tests` (sandbox). Approval required on `edit_file`.
3. Point TrueForge's model provider at the TrueFoundry AI Gateway.
4. Drive runs from code via the TypeScript SDK — task x variant x repeat.
5. Write `traces/<run_id>.jsonl` per TRACE_SCHEMA.md.

## First task: discovery, not code

Before writing the runner, run one task by hand and answer:

- [ ] What does a session expose after a run — tokens per step? timings?
- [ ] What events arrive on the SSE stream, and do they carry a timestamp?
- [ ] Can TTFT be measured as (first token event) minus (request sent)?
- [ ] Are subagent steps attributed to a distinguishable agent id?
- [ ] Does a compaction produce an observable event?
- [ ] Which harness capabilities are settable per agent via the SDK?
- [ ] Does the gateway expose the raw prompt (needed for `prompt_prefix_hash`)?

Write the answers into `docs/sdk-findings.md`. Anything unavailable at this
seam has to come from the gateway seam instead.

## Runner shape

```
for task in tasks:
  for variant in variants:
    for repeat in 0..R:
      agent   = sdk.createAgent(variant.config)
      session = sdk.createSession(agent)
      stream  = sdk.sendMessage(session, task.prompt)
      for event of stream: trace.record(event)
      detail  = sdk.getSession(session.id)     // tokens, steps
      passed  = run(task.verify_cmd)
      trace.finish(detail, passed)
```

## Guardrails

- Cap turns and spend per run. A runaway variant must not eat the quota.
- Same model for every variant — the harness is the only thing changing.
- Pass `run_id` to the gateway as a header so its logs can be joined to the run.
