# Task set

10–15 small coding tasks. Each is a broken repo state plus a test that must pass.

## Task card format (`tasks/<task_id>.json`)

```json
{
  "task_id": "fix-failing-test-01",
  "prompt": "The test suite is failing. Find the bug, fix it, make tests pass.",
  "repo_path": "repos/calc",
  "verify_cmd": "pytest -q",
  "shape": {
    "files_touched_expected": 1,
    "turns_expected": 5,
    "kind": "single_file_edit",
    "search_heavy": false,
    "tool_output_heavy": false
  }
}
```

`shape` is the important part. It is what lets the rules layer say
*when* a harness setting helps, instead of claiming one setting always wins.

## Shape vocabulary

| field | values | why it matters |
|---|---|---|
| `kind` | `single_file_edit`, `multi_file_refactor`, `wide_search`, `debug_loop` | the main axis subagents are expected to split on |
| `files_touched_expected` | int | candidate crossover variable for subagents |
| `turns_expected` | int | candidate crossover variable for compaction |
| `search_heavy` | bool | many grep/read calls, large tool results |
| `tool_output_heavy` | bool | tool results dominate context growth |

## Coverage target

Aim for a spread, not 15 of the same thing:

- 4–5 `single_file_edit` (short, few turns)
- 3–4 `multi_file_refactor`
- 3–4 `wide_search`
- 2–3 `debug_loop` (long, many test runs)

Without spread there is no crossover to find.
