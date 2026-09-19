# Trace Schema v0.1

**This file is a contract.** The collector writes it; the analyzer reads it.
Changing a field breaks the other person's work. Announce changes and bump
`schema_version`.

Format: JSON Lines. One file per run: `traces/<run_id>.jsonl`.
Every line has `schema_version`, `event`, `run_id`.
All timestamps are ISO-8601 UTC with milliseconds. All durations are integers in ms.

Worked examples: `samples/run_baseline.jsonl`, `samples/run_subagents.jsonl`.

---

## `run_start`

| field | type | notes |
|---|---|---|
| `task_id` | string | matches a task card in `tasks/` |
| `variant` | string | `baseline`, `subagents_on`, ... |
| `variant_config` | object | booleans for each harness capability |
| `model` | string | same across variants |
| `repeat_index` | int | 0-based |
| `ts` | timestamp | |

## `model_call`

| field | type | notes |
|---|---|---|
| `turn` | int | |
| `agent` | string | `main`, `sub-1`, ... |
| `call_id` | string | unique within run |
| `ts_start` / `ts_first_token` / `ts_end` | timestamp | |
| `ttft_ms` | int | `ts_first_token - ts_start` |
| `duration_ms` | int | |
| `input_tokens` / `output_tokens` | int | |
| `cached_input_tokens` | int | 0 if the provider reports none |
| `itl_ms_mean` | float | mean inter-token latency |
| `prompt_prefix_hash` | string | hash of the first N bytes of the prompt — **the cache-stability signal** |
| `finish_reason` | string | `tool_use`, `stop`, `error` |
| `tool_calls` | string[] | tool names requested |
| `concurrent_calls` | int | optional; in-flight calls at start |

## `tool_call`

| field | type | notes |
|---|---|---|
| `turn`, `agent`, `call_id` | | links back to the model call |
| `tool` | string | |
| `ts_start` / `ts_end` / `duration_ms` | | |
| `status` | string | `ok`, `error` |
| `result_tokens` | int | size of what re-enters context |
| `sandbox` | bool | optional; true if it needed the sandbox |

## `approval_wait`

`turn`, `agent`, `tool`, `ts_start`, `ts_end`, `duration_ms`,
`decision` (`approved` / `denied`), `approver`.

## `subagent_start` / `subagent_end`

Start: `parent_call_id`, `agent`, `purpose`, `ts`.
End: `agent`, `ts`, `summary_tokens`, `model_calls`.

## `compaction`

`turn`, `agent`, `ts_start`, `ts_end`, `duration_ms`,
`input_tokens`, `output_tokens`, `tokens_before`, `tokens_after`,
`trigger`, `prompt_prefix_hash`.

## `run_end`

| field | type | notes |
|---|---|---|
| `task_id`, `variant`, `ts`, `wall_ms` | | |
| `passed` | bool | from the test runner, not the model |
| `model_calls` | int | |
| `total_input_tokens` / `total_output_tokens` / `total_cached_input_tokens` | int | |
| `cost_usd` | float | from the gateway |
| `errors` | int | |

---

## Reading notes for the analyzer

- A run is only valid if it has both `run_start` and `run_end`. Drop the rest.
- `prompt_prefix_hash` is *expected* to change right after a `compaction` event.
  A change anywhere else is the bug worth flagging.
- Subagent model calls overlap in time — compute concurrency from the timestamps,
  don't assume calls are sequential.
- Idle time = `wall_ms` minus the sum of `model_call.duration_ms` for the main
  agent, then attributed to tool / sandbox / approval waits by their spans.
