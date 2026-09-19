# TrueForge SDK findings

Discovery performed by User A on 2026-09-19 against the local TrueForge UI at
`http://localhost:8790` and the published
`@truefoundry/trueforge-sdk@0.2.0` package. This is evidence for the collector
design, not pilot measurement data.

## Status

**The pilot is discovery-blocked.** Local OpenAI and Daytona are now configured,
and a non-benchmark sandbox discovery turn succeeded in creating a Daytona
sandbox. The required C++/Rust toolchain is absent from that sandbox, so no
benchmark run was started.

| Question | Answer | Source |
|---|---|---|
| Session exposes per-call tokens? | Declared: a terminal `model.message` has `inputTokens`, `outputTokens`, optional cache read/write tokens, and an input-token breakdown. A live run must still prove the provider populates them. | SDK v0.2.0 `ModelMessageUsage` type |
| Session exposes per-call timings? | Declared: `model.message` has `createdAt`; streaming deltas may have `createdAt`. The runner can timestamp its turn submission and first delta, but live precision is unproven. | SDK v0.2.0 `ModelMessageEvent` and `ModelMessageDeltaEvent` types |
| SSE event types and timestamps | Declared stream types include `turn.created`, `model.message`, `model.message.delta`, `tool.response`, `tool.approval_required`, `sandbox.created`, `thread.created`, `thread.done`, and `turn.done`; lifecycle events carry ISO-8601 timestamps. | SDK v0.2.0 `TurnStreamingEvent` type; local OpenAPI 0.2.0 |
| TTFT measurable from stream? | Design is possible: record runner send time and the first `model.message.delta` arrival. It has not been proven against the configured model. | SDK v0.2.0 type surface; no live model turn was run |
| Subagent steps distinguishable? | Declared: `thread.created` carries the new thread id, parent, and agent info; `thread.done` carries terminal state. | SDK v0.2.0 `ThreadCreatedEvent` and `ThreadDoneEvent` types |
| Compaction observable as an event? | **No.** The current `TurnStreamingEvent` union has no compaction event. Configuration exists, but no event supplies the schema-v0.1 compaction fields. Do not implement or measure `compaction_on` until a live lower-seam mapping is demonstrated or User A and User B jointly version the schema. | SDK v0.2.0 `RuntimeConfig`, `CompactionConfig`, and `TurnStreamingEvent` types |
| Capabilities settable per inline agent? | Declared: `AgentSpec.config` exposes `dynamicSubAgents.enabled`, `contextManagement.compaction.enabled`, `sandbox.enabled`, and MCP `preload`/approval controls. | SDK v0.2.0 `AgentSpec`, `RuntimeConfig`, `McpServer` types |
| Code Mode selectable per inline agent? | **No.** There is no Code Mode field in `RuntimeConfig`. Server source wires Code Mode automatically only when the resolved agent has non-empty MCP tool sets. A sandbox-only coding task has no independent Code Mode switch to vary. | TrueForge 0.2.0 `SessionHandle` and `Sandbox.configureCodeMode` source |
| Gateway exposes raw prompt and accepts `run_id`? | **Unproven.** The currently configured provider is direct OpenAI, not a TrueFoundry AI Gateway endpoint. No raw prompt, cache, cost, or `run_id` join evidence exists. | Local TrueForge Settings → Models inspection |
| Daytona can create required toolchain sandbox? | **No.** A live non-benchmark sandbox probe found `git version 2.39.5`, then `/usr/bin/bash: line 1: cmake: command not found`; a second probe found no `cmake`, `cargo`, `rustc`, `c++`, or `g++` on `PATH`. | Local TrueForge session on 2026-09-19 |
| Runner can stage the fixture before the first model call? | **No.** In the 0.2.0 server, a fresh sandbox is created lazily inside the agent's `exec` tool handler, after the model requests that tool. The only reattach input comes from a prior turn's persisted sandbox id; neither `AgentSpec` nor the public API accepts a runner-supplied initial sandbox id. The release-owned Daytona image cannot be selected in local settings. | TrueForge 0.2.0 `Sandbox.ensureSandboxCreated`, `SessionHandle`, and Daytona settings/OpenAPI source |
| Runner can execute the trusted verifier after the turn? | **Potential lower seam, unproven.** The server's Daytona provider can execute commands when given a sandbox id, and `sandbox.created` exposes that id. A trusted runner with a separately provisioned Daytona credential could verify the resulting sandbox after the turn. The public TrueForge SDK/API does not provide that command endpoint. | TrueForge 0.2.0 `DaytonaProvider.exec`, `SandboxCreatedEvent`, and public SDK/OpenAPI |
| Ripwire tool time observable without changing `tool_call.tool`? | **No for the requested CLI-only variant.** Ripwire would run as the sandbox's actual `exec` tool; the command is present in the model tool arguments, but schema v0.1 stores neither command nor command classification. Keeping `tool: "exec"` preserves the contract but prevents User B from isolating Ripwire time. Do not implement `ripwire_on` until we jointly version the schema (for example, an optional command classification) or use a genuinely named Ripwire MCP tool. | TrueForge 0.2.0 sandbox `exec` source; SDK v0.2.0 `ToolCall` and `ToolResponseEvent` types |

## Consequences for the collector

1. The collector must refuse the matrix before starting any run unless it has
   recorded evidence for the configured gateway, a Daytona sandbox with `git`,
   `cmake`, a C++ compiler, `cargo`, and `rustc`, fixture staging, the trusted
   verifier, and the trace mapping.
2. Explicit inline-agent configuration can prevent TrueForge defaults from
   leaking into `baseline`: dynamic subagents and compaction can be set false;
   eager versus deferred MCP loading can be controlled with `preload`.
3. `code_mode_on` is not a valid one-setting variant for this sandbox-only task
   with the released public controls. Adding an MCP server solely to make it
   available would itself change the tool environment.
4. A post-turn trusted verifier may be feasible through the Daytona control
   plane, but it needs an out-of-repository credential and a live proof that
   the `sandbox.created` id can be accessed by that credential.
5. The trace writer may derive model-call boundaries from the stream, but must
   leave gateway-only fields unavailable rather than fabricate raw-prompt,
   cache, cost, or compaction values.
6. The v0.1 `tool_call.tool` value remains the actual TrueForge tool name. A
   Ripwire CLI invocation is `exec`, not a new tool name merely because its
   command mentions Ripwire.

## Fixture-source findings

The requested source template resolves to
`gAldeia/cpp-library-template@bccb37c57c8bb47ed7f700b4f9b8f025c11c19eb`.
It contains an MIT license template in `LICENSE-template.md`, CMake project
structure, and a CTest-compatible test setup. Its current test target fetches
GoogleTest, so the derived calculator fixture must replace that target with
dependency-free CTest tests before the benchmark pin. The derived public
repository does not yet exist; no fixture URL or benchmark commit has been
invented.

## Live sandbox evidence and root cause

The local discovery agent used the configured `gpt-5-4-mini` model and one
sandbox `exec` tool call. The exact probe was:

```sh
git --version && cmake --version && (c++ --version || g++ --version) && cargo --version && rustc --version
```

Its output stopped after `git version 2.39.5` with:

```text
/usr/bin/bash: line 1: cmake: command not found
```

The follow-up diagnostic found no paths for `cmake`, `cargo`, `rustc`, `c++`,
or `g++`. This consistently reproduces the missing-toolchain gate.

The TrueForge 0.2.0 source identifies the cause: standalone Daytona uses a
release-owned image URI, and the local sandbox-provider settings schema exposes
only the key and timeout/lifecycle fields. It has no image or snapshot override.
The release's own sandbox instructions list Python, Git, Curl, Helm, jq,
ripgrep, and genson as pre-installed; they do not provide the C++ or Rust tools
this task requires.

Installing packages during a task run is not an acceptable workaround. Every
pilot cell requires a fresh sandbox, so that installation would change the
environment, add agent/tool time, and destroy comparability. Continuing requires
either a TrueForge-supported configurable image containing the toolchain or a
release/upstream change that supplies one.

## Required next discovery actions

- For the local-only hackathon path, keep the configured direct OpenAI provider
  and one fixed model. A TrueFoundry AI Gateway account or Virtual Account
  Token is not required; gateway-only telemetry is unavailable on this path.
- If the original gateway telemetry requirement is retained, separately
  configure a custom TrueFoundry AI Gateway provider and prove a documented
  request/telemetry path accepts the runner's `run_id` without storing a secret
  in this repository.
- Daytona is configured and can create a sandbox, but it has not passed the
  required toolchain probe; resolve the image gate below.
- Replace or upgrade the release-owned sandbox image through a supported
  TrueForge path, then rerun the same probe. It must show Git, CMake, a C++
  compiler, Cargo, and rustc before any fixture work or benchmark session.
- Resolve the staging blocker. The released public API cannot attach a
  pre-staged sandbox to a first turn; do not emulate staging with an agent tool
  call because that would occur after the first model call.
- If a separate Daytona control plane is used for the trusted verifier, prove
  that its credential can access the `sandbox.created` id and that the verifier
  runs outside the agent-editable tree.
- Run a short non-benchmark discovery turn and retain its event payloads. It
  must show the actual mapping for tools, approvals, subagents, gateway
  telemetry, and any proposed replacement for compaction or Ripwire before the
  matrix is enabled.

## Update 2026-09-19 — Ripwire is measurable as a named MCP connector

The earlier Ripwire finding ("No for the requested CLI-only variant") assumed
Ripwire runs as the sandbox's `exec` tool, which collapses into a generic tool
name under schema v0.1. That assumption is now superseded for a different,
working setup:

- **Ripwire ships an MCP server** (`ripwire --mcp`, stdio) and, crucially,
  `--listen=HOST:PORT` serves the same MCP over **Streamable HTTP** — the exact
  transport TrueForge connectors require (they are URL-only). No bridge needed.
- Built from source on the host (cmake 4.3.4 / AppleClang 17, C++23; the Daytona
  sandbox still cannot build it — same toolchain gate as the C++/Rust pilot).
- Registered via `POST /api/v1/settings/mcp-servers` with a `remote` manifest
  pointing at `http://127.0.0.1:9700/mcp`. **TrueForge connected and enumerated
  31 named tools** (`explore`, `impact`, `uses`, `find_symbol`, `edit_check`,
  `quality_delta`, …) via `GET /api/v1/mcp-servers/ripwire/tools`.

**Consequence for the schema (no change needed):** because each Ripwire verb is
a distinctly named MCP tool, `tool_call.tool` already carries `ripwire`'s tool
names, so User B can isolate Ripwire time **without** a schema-v0.1 change. The
v0.1 blocker was specific to the CLI-as-`exec` framing; the MCP-connector
framing fits the existing contract. This is worth confirming jointly with User B
before the analyzer special-cases Ripwire, but it does not require a
`schema_version` bump.

**Caveat:** the host Ripwire indexes the host copy of the repo; a sandbox agent's
in-sandbox edits are not reflected until the server is re-pointed. Ripwire's role
is understand-before-edit context, so this is expected. This is a working
capability, not a benchmark measurement — no trace was produced.
