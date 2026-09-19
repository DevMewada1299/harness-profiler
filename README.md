# Harness Profiler

Measures how **agent harness design choices** change the inference load of a
coding agent, and turns the measurements into per-task rules.

Everyone else benchmarks hardware with the harness held fixed.
We hold the hardware fixed and vary the harness.

Built on [TrueForge](https://trueforge.dev), TrueFoundry's open-source agent harness.

## Read this first

- [`PROJECT.md`](PROJECT.md) — what we're building, why, and the architecture
- [`TRACE_SCHEMA.md`](TRACE_SCHEMA.md) — the contract between the two halves

## Layout

```
collector/   teammate A — runs agents, writes traces
analyzer/    teammate B — reads traces, produces metrics + report
samples/     hand-made traces so the analyzer works before any real run
tasks/       task cards + the broken-test repo under test
traces/      output (gitignored)
```

The two halves meet **only** at `traces/*.jsonl`. Neither reads the other's code.

## Quick start

    git clone <this repo> && cd harness-profiler

Teammate A:

    git checkout collector
    cd collector && npm install

Teammate B:

    git checkout analyzer
    cd analyzer && npm install
    npm run analyze -- ../samples/*.jsonl

## Working with Codex / Claude Code

Both read the repo-root brief automatically (`AGENTS.md` for Codex,
`CLAUDE.md` for Claude Code; both point at `PROJECT.md`).

Open the repo and state which half you own, e.g.

> I'm teammate B. Build the parser and metrics layer in `analyzer/` against
> `samples/`. Don't touch `collector/`.
