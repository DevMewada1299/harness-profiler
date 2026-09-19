# TrueForge SDK findings

Discovery performed by User A on 2026-09-19 against the local TrueForge UI at
`http://localhost:8790` and the published
`@truefoundry/trueforge-sdk@0.2.0` package. This is evidence for the collector
design, not pilot measurement data.

## Status

**The pilot is discovery-blocked.** The local server currently has a direct
`openai` provider configured at `https://api.openai.com/v1` and no configured
Daytona provider. That does not meet the planned AI Gateway or sandbox
requirements, so no model or benchmark run was started.

| Question | Answer | Source |
|---|---|---|
| Session exposes per-call tokens? | Declared: a terminal `model.message` has `inputTokens`, `outputTokens`, optional cache read/write tokens, and an input-token breakdown. A live run must still prove the provider populates them. | SDK v0.2.0 `ModelMessageUsage` type |
| Session exposes per-call timings? | Declared: `model.message` has `createdAt`; streaming deltas may have `createdAt`. The runner can timestamp its turn submission and first delta, but live precision is unproven. | SDK v0.2.0 `ModelMessageEvent` and `ModelMessageDeltaEvent` types |
| SSE event types and timestamps | Declared stream types include `turn.created`, `model.message`, `model.message.delta`, `tool.response`, `tool.approval_required`, `sandbox.created`, `thread.created`, `thread.done`, and `turn.done`; lifecycle events carry ISO-8601 timestamps. | SDK v0.2.0 `TurnStreamingEvent` type; local OpenAPI 0.2.0 |
| TTFT measurable from stream? | Design is possible: record runner send time and the first `model.message.delta` arrival. It has not been proven against the configured model. | SDK v0.2.0 type surface; no live model turn was run |
| Subagent steps distinguishable? | Declared: `thread.created` carries the new thread id, parent, and agent info; `thread.done` carries terminal state. | SDK v0.2.0 `ThreadCreatedEvent` and `ThreadDoneEvent` types |
| Compaction observable as an event? | **No.** The current `TurnStreamingEvent` union has no compaction event. Configuration exists, but no event supplies the schema-v0.1 compaction fields. Do not implement or measure `compaction_on` until a live lower-seam mapping is demonstrated or User A and User B jointly version the schema. | SDK v0.2.0 `RuntimeConfig`, `CompactionConfig`, and `TurnStreamingEvent` types |
| Capabilities settable per inline agent? | Declared: `AgentSpec.config` exposes `dynamicSubAgents.enabled`, `contextManagement.compaction.enabled`, `sandbox.enabled`, and MCP `preload`/approval controls. | SDK v0.2.0 `AgentSpec`, `RuntimeConfig`, `McpServer` types |
| Gateway exposes raw prompt and accepts `run_id`? | **Unproven.** The currently configured provider is direct OpenAI, not a TrueFoundry AI Gateway endpoint. No raw prompt, cache, cost, or `run_id` join evidence exists. | Local TrueForge Settings → Models inspection |
| Daytona can create required toolchain sandbox? | **Unproven.** Daytona is available but not configured; no sandbox was created and no toolchain command was run. | Local TrueForge Settings → Sandbox providers inspection |
| Runner can stage the fixture before the first model call? | **No documented path found.** The SDK/OpenAPI exposes sandbox enablement, `sandbox.created`, and post-turn sandbox-file download, but no sandbox exec, upload, or pre-turn staging endpoint. Daytona settings expose only key, timeout, and lifecycle values—not snapshot selection. | SDK v0.2.0 sessions client; local OpenAPI 0.2.0; local Daytona configuration form |
| Runner can execute the trusted verifier after the turn? | **No documented path found.** The public TrueForge API can download listed sandbox artifacts but does not expose sandbox command execution. | SDK v0.2.0 sessions client; local OpenAPI 0.2.0 |
| Ripwire tool time observable without changing `tool_call.tool`? | **Unproven.** `model.message.toolCalls` gives the configured tool name and `tool.response` links by `toolCallId`, but no Ripwire CLI/MCP integration has been exercised. Do not label a generic shell call as `ripwire` without live evidence of the executed command or a versioned schema decision. | SDK v0.2.0 `ModelMessageEvent`, `ToolResponseEvent`, and `ToolCall` types |

## Consequences for the collector

1. The collector must refuse the matrix before starting any run unless it has
   recorded evidence for the configured gateway, a Daytona sandbox with `git`,
   `cmake`, a C++ compiler, `cargo`, and `rustc`, fixture staging, the trusted
   verifier, and the trace mapping.
2. Explicit inline-agent configuration can prevent TrueForge defaults from
   leaking into `baseline`: dynamic subagents and compaction can be set false;
   eager versus deferred MCP loading can be controlled with `preload`.
3. The trace writer may derive model-call boundaries from the stream, but must
   leave gateway-only fields unavailable rather than fabricate raw-prompt,
   cache, cost, or compaction values.
4. The v0.1 `tool_call.tool` value remains the actual TrueForge tool name. A
   Ripwire CLI invocation is not a new tool name merely because its command
   mentions Ripwire.

## Fixture-source findings

The requested source template resolves to
`gAldeia/cpp-library-template@bccb37c57c8bb47ed7f700b4f9b8f025c11c19eb`.
It contains an MIT license template in `LICENSE-template.md`, CMake project
structure, and a CTest-compatible test setup. Its current test target fetches
GoogleTest, so the derived calculator fixture must replace that target with
dependency-free CTest tests before the benchmark pin. The derived public
repository does not yet exist; no fixture URL or benchmark commit has been
invented.

## Required next discovery actions

- Configure a **custom TrueFoundry AI Gateway** provider locally, select one
  fixed model, and provide a documented gateway request/telemetry path that
  accepts the runner's `run_id` without storing a secret in this repository.
- Configure Daytona in the local UI with the existing key, then prove the
  required toolchain in a fresh sandbox.
- Demonstrate a supported way to stage the fixture before the first model call
  and run the trusted verifier against the same resulting sandbox. If this
  requires a separate supported Daytona control plane, prove how its sandbox is
  bound to the TrueForge session.
- Run a short non-benchmark discovery turn and retain its event payloads. It
  must show the actual mapping for tools, approvals, subagents, compaction,
  gateway telemetry, and Ripwire (if any) before the 18-run matrix is enabled.
