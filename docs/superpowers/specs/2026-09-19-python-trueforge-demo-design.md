# Python TrueForge Demo Design

## Purpose

Deliver a truthful one-hour demonstration of the local TrueForge deployment:
an agent fixes a deliberately broken Python calculator in a Daytona sandbox and
proves the fix with the Python standard library test runner. The demonstration
also shows the already-completed analyzer against its maintained sample traces.

This is an operational demonstration, not an end-to-end benchmark result. It
must make that distinction explicit to the audience.

## Evidence and constraints

- The local TrueForge server has a connected OpenAI provider and a working
  Daytona provider.
- A live sandbox exposes `python3` 3.13.15 and Git. It does not expose
  `pytest`, CMake, a C++ compiler, Cargo, or rustc.
- The released local server cannot stage a fixture into a fresh sandbox before
  the model's first call.
- The direct OpenAI provider does not provide the gateway raw-prompt, cache,
  cost, or caller-supplied `run_id` evidence required by the benchmark plan.
- The v0.1 trace schema remains unchanged. No demo file may invent a token,
  timing, cache, cost, prompt-prefix, compaction, or Ripwire value.
- User B owns `analyzer/`; this work never edits it.

## Fixture

The existing empty public repository
`https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git` is the
demo fixture repository. Its name is retained for continuity with the deferred
C++→Rust pilot, but the demo is explicitly Python-only.

The first commit on a `python-demo` branch contains only:

- `calculator.py` — a `divide(left, right)` function with one intentional
  multiplication bug and normal Python `ZeroDivisionError` behavior.
- `test_calculator.py` — `unittest` cases for a normal division and division
  by zero.
- `README.md` — the exact verifier command:
  `python3 -m unittest -v`.
- `.gitignore` — Python bytecode and cache entries.

The task is a single-file edit. Its verifier is the standard-library command
above; it has no package installation step.

`tasks/python-unittest-calculator-01.json` records the public fixture URL, the
immutable `python-demo` commit, `python3 -m unittest -v`, and the
`single_file_edit` shape. The task card does not claim that the fixture can be
staged before the first model call.

## Demo agents and tools

Two saved local TrueForge agents make the tool boundary visible:

1. **Python Fixer Demo** has sandbox enabled and no MCP server or TrueForge
   skill. It uses the sandbox `exec` tool for Git, file inspection/editing, and
   `python3 -m unittest -v`. Its prompt tells it to clone the pinned
   `python-demo` fixture commit, find the failing calculator behavior, make the
   smallest correction, and run the verifier. Its task-local clone happens
   after the first model call, so the resulting session is labelled
   `exploratory_demo`, not a benchmark run.
2. **Research Tools Demo** has sandbox disabled. It mounts exactly the three
   already-connected, read-only remote MCP servers — `deepwiki`, `exa`, and
   `parallel-web` — with deferred discovery (`preload: false`). It mounts the
   `wiki-qa` TrueForge skill with deferred loading. This agent is separate from
   the fixer so web/repository tool schemas cannot affect the coding demo or a
   future baseline.

No other connector is enabled. GitHub, Linear, Notion, Sentry, Supabase,
Stripe, Confluence, Jira, PostHog, and Tavily's direct connector are excluded
because they are unconfigured or could write external data.

Ripwire is not mounted in this time-boxed demo. `ripwire --mcp` is a stdio
server, while TrueForge local connects to remote Streamable HTTP or SSE MCP
servers. A secure bridge plus a separately installed Ripwire binary would be a
new subsystem and cannot identify Ripwire-only time in schema v0.1. It is a
follow-up only after a versioned trace-contract decision.

## Demonstration sequence

1. Show the local TrueForge settings: the three connected MCP servers and the
   enabled read-only `wiki-qa` research skill.
2. Show the Research Tools Demo answer one public-repository question using
   DeepWiki. This validates that the configured MCP connection is usable.
3. Show the Python Fixer Demo clone the pinned fixture commit, run the failing
   `unittest` suite, correct `calculator.py`, and rerun the suite successfully.
4. Run User B's analyzer against `samples/*.jsonl` and show the generated HTML
   report. State that these are parser-validation samples, not measurements
   from the preceding fixer session.
5. Show `docs/sdk-findings.md` and state the two known benchmark gates:
   sandbox staging and unavailable gateway telemetry/toolchain.

## Out of scope

- No C++→Rust migration attempt.
- No 18-run matrix, comparison table, conditional harness rule, or claimed
  performance metric.
- No files in `traces/` unless every required value is measured through an
  approved trace mapping.
- No schema change and no changes to `analyzer/`.
- No automatic package installation in a sandbox.

## Acceptance criteria

- The `python-demo` fixture commit is public and its `unittest` verifier fails
  before the correction.
- The Python Fixer Demo starts a fresh Daytona sandbox, checks out the pinned
  commit, changes only `calculator.py`, and finishes with a passing verifier.
- The Research Tools Demo successfully calls at least one of its existing
  read-only MCP servers without accessing non-public data.
- The fixture task card records the fixture URL, immutable commit, verifier,
  and `single_file_edit` shape.
- The analyzer continues to run against `samples/`; any displayed report is
  labelled sample-backed.
- The demo handoff records the session URLs, fixture commit, and the explicit
  non-benchmark limitations.
