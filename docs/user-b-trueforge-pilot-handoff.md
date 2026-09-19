# User B handoff: TrueForge C++ → Rust pilot

## Status

User A has begun a discovery-gated pilot. It is **not execution-ready** and
there are no valid measurements or new traces yet. `TRACE_SCHEMA.md` remains
v0.1; this note does not alter the contract or any `analyzer/` file.

## Fixture

| Item | Current state |
|---|---|
| Upstream source | `gAldeia/cpp-library-template@bccb37c57c8bb47ed7f700b4f9b8f025c11c19eb` |
| License preservation | Retain the upstream MIT notice/template in the derived fixture |
| Derived public repository | `DevMewada1299/cpp-to-rust-calculator-fixture` — not created yet; public-repository creation requires User A's confirmation |
| Benchmark pin | Pending the public repository and its baseline commit; no URL or revision has been invented |
| Baseline contents | Dependency-free CTest C++ calculator library plus CLI, reduced from the source template before pinning |
| Agent task | Replace the C++ library and CLI with a Rust library crate and Rust CLI preserving arguments, stdout, stderr, exit codes, operations, and failures; leave no C++ production target |
| Task shape | `multi_file_refactor` |
| Trusted outcome | External verifier runs Cargo tests, CLI success/failure checks, and confirms the Rust artifact is the deliverable |

The upstream template currently fetches GoogleTest for its own tests. The
fixture baseline will replace that with dependency-free CTest before its
benchmark commit, so its toolchain requirement stays limited to Git, CMake, a
C++ compiler, Cargo, and rustc.

## Planned run matrix

One pinned task × six variants × three fresh repeats: **18 runs**. Each run has
a fresh TrueForge session and fresh Daytona sandbox. The model is fixed across
all cells.

| Variant | Only intended change | Discovery status |
|---|---|---|
| `baseline` | Explicitly disables dynamic subagents and compaction, uses eager fixed tool definitions, and has no code-mode or Ripwire capability | Partial SDK support; no live proof |
| `subagents_on` | Enable dynamic subagents | Typed SDK control found; no live proof |
| `compaction_on` | Enable compaction | Typed SDK control found; **no explicit compaction event** in SDK v0.2.0 |
| `deferred_tools_on` | Change MCP tool loading from eager to deferred | Typed SDK control found; no live proof |
| `code_mode_on` | Enable the one-script code-mode mechanism | **Mechanism not yet found in SDK/API discovery** |
| `ripwire_on` | Make the Ripwire CLI available while keeping all other settings at baseline | **Not yet observable in the v0.1 trace contract** |

No matrix cell may run until its intended one-setting difference has been
proved from the configured runtime. In particular, `compaction_on`,
`code_mode_on`, and `ripwire_on` are not currently safe to measure.

## Runner approval policy

The intended runner policy is automatic approval only for file edits within the
fresh task sandbox, emitted as an `approval_wait` event with
`approver: "runner_policy"`. It must never approve edits outside that sandbox.
The current SDK declares approval-required events, but the resume/approval flow
still needs live proof before implementation.

## Discovery findings relevant to the analyzer

- The local TrueForge server is version 0.2.0. Its current model provider is a
  direct OpenAI endpoint, not the planned TrueFoundry AI Gateway. Therefore raw
  prompt bytes, cache counters, cost, and `run_id` joins are not established.
- Daytona is available but unconfigured; no sandbox or required toolchain has
  been proven.
- The SDK declares model messages, tool responses, approval events, sandbox
  creation, and subagent thread events. It does **not** declare an explicit
  compaction event.
- No documented public endpoint stages files or executes a sandbox command
  before/after a turn. The required pre-turn staging and trusted-verifier path
  need a supported demonstrated design before collection begins.
- Ripwire time is reportable only if its invocation can be observed without
  overwriting the actual `tool_call.tool` value. A generic shell tool call is
  not automatically a Ripwire tool call.

See [sdk-findings.md](sdk-findings.md) for the detailed evidence and gates.

## User B report requirements

When valid traces eventually exist, please:

- accept the six pilot variant labels while keeping the analyzer runnable from
  `samples/`;
- report spread across the three repeats, not a single run or only a point
  estimate;
- surface Ripwire tool time only where the schema can genuinely identify it;
- label every resulting chart/table as a **single-task pilot**, not a general
  harness rule;
- raise any schema need jointly with User A before changing parser assumptions.

## Ready-to-send message

> User A is adding a discovery-gated TrueForge pilot: one pinned C++ library + CLI → Rust full rewrite task, shaped as `multi_file_refactor`. The pilot runs six variants with three repeats each. Do not assume any new trace fields: schema v0.1 remains in force unless we jointly announce and version a change after live discovery. Please ensure the analyzer accepts the new variants, reports spread across repeats, surfaces Ripwire tool time only when it is observable in the contract, and labels this as a single-task pilot—not a general rule.

This message is ready for User A to send to User B once the handoff commit is
shared. No external message was sent by the collector work.
