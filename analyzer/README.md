# analyzer/ — teammate B

Owns everything downstream of `traces/*.jsonl`. Never touches TrueForge.

Build against `samples/` from hour zero. Real traces arrive at the merge point.

## Layers (build in this order)

1. **parser** — read jsonl, group by `run_id`, validate schema, drop runs
   missing `run_start` or `run_end`.
2. **metrics** — one function per metric, each `(run) -> number`. Independent,
   so metrics can be added without touching anything else.
3. **aggregator** — group by variant, median + spread across repeats,
   join with task `shape`.
4. **rules** — compare variants *within each task shape*, emit conditional
   findings with the supporting numbers.
5. **report** — one HTML page: comparison table, idle-time bars,
   context-growth lines, rules at the top.

Layers 1–3 first. Layer 4 is what makes this a project instead of a dashboard.

## Metrics — build first

- prefix stability (does `prompt_prefix_hash` change where it shouldn't?)
- cache hit ratio (`cached_input_tokens` / `input_tokens`, per turn)
- idle breakdown (generating / tool wait / sandbox wait / approval wait)
- tool result size by tool (which tool floods context)
- cost per *successful* task

## Metrics — then

context growth curve; prefill:decode ratio; burstiness (concurrent calls over
time); tool-list overhead; round trips per file edited; reasoning token share;
compaction cost vs saving vs pass-rate impact; subagent setup vs summary tokens;
tool failure/retry rate; variance across repeats.

## Expected output from the two sample traces

Use these as the correctness check while building:

- subagents finished ~6s faster but used 8 model calls vs 5, and cut cached
  input tokens from 28.6k to 13.6k
- compaction shrank the prompt 6.6k -> 2.2k and dropped TTFT from ~2.0s to ~0.8s,
  at the cost of one extra 2.8s call
- `prompt_prefix_hash` changes at the compaction event — expected. A change
  anywhere else is the bug to flag.
