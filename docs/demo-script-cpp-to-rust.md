# Demo script — migrating a legacy C++ repo to Rust

A read-aloud narration for the demo recording. **[SAY]** = what you say,
**[SHOW]** = what's on screen. Anything in `<angle brackets>` is a live value —
read it off the real run, do not pre-fill it (project rule: don't invent
numbers). Target ~4 minutes.

Prerequisite: the small legacy C++ fixture must exist (calculator library + CLI
+ CTest tests). If it doesn't yet, build it first — everything below assumes it.

---

## 0. Cold open (~15s)

**[SHOW]** The legacy C++ repo open in the editor — `calculator.hpp/.cpp`, a
CLI `main.cpp`, and the CTest tests.

**[SAY]** "This is a small legacy C++ codebase: a calculator library, a CLI, and
a test suite. The job is to migrate it to Rust *without changing its behavior* —
same operations, same CLI arguments, same stdout, stderr, and exit codes. The
tests are the contract."

---

## 1. The problem (~30s)

**[SAY]** "Migrating legacy code is where agents usually flail — they grep, read
whole files, lose the call graph, and break callers they never saw. Two ideas
fix that. One: the tests are an objective gate — pass or fail, no opinions. Two:
we give the agent a *map* of the code before it touches anything, so it changes
with the blast radius in view. That map is Ripwire."

---

## 2. Understand the legacy code with Ripwire (~60s)

**[SHOW]** Terminal — Ripwire already serving this repo (or run it live):
`~/.local/bin/ripwire . --for="migrate this C++ library and CLI to Rust"`.

**[SAY]** "Ripwire parses the repo and ranks it by importance. In one call I get
the symbols that matter for this task —"

**[SHOW]** The ranked map; point at the top symbols.

**[SAY]** "— `<top symbol>`, `<top symbol>`, the CLI entry point. Now the
question that keeps a migration safe: what depends on the thing I'm about to
rewrite?"

**[SHOW]** `ripwire . --impact=<function>` and `ripwire . --uses=<function>`.

**[SAY]** "`impact` gives the transitive blast radius; `uses` gives every caller.
`<N>` symbols reach this function. That's the list I must preserve behavior for.
This is the exact map the TrueForge agent gets through the `ripwire` connector —
31 tools, live."

---

## 3. The agent makes the migration (~70s)

**[SHOW]** TrueForge Build Agent — sandbox on, the `ripwire` connector attached,
Instructions pasted from `docs/agent-instructions-ripwire.md`. Send the
migration task prompt.

**[SAY]** "Same objective task card style as our test-fixing demo: clone, read
the tests, migrate, keep behavior identical. Watch the order it works in —"

**[SHOW]** The session: `explore` / `impact` calls, *then* edits.

**[SAY]** "It orients with Ripwire first, then writes the Rust: a library crate
and a CLI that mirror the C++ surface — the same operations, the same
argument parsing, the same exit codes on the same failures."

**[SHOW]** The generated Rust — `src/lib.rs`, `src/main.rs`, `Cargo.toml`.

**[SAY]** "Notice what it did *not* do — it didn't leave a C++ production target
behind. The Rust crate is the deliverable."

---

## 4. The objective gate (~50s)

**[SAY]** "Now the only thing that decides success — the tests. Behavior parity,
run on the host, because the migration toolchain lives here."

**[SHOW]** Terminal on the host:
```
cargo test
# then CLI parity against the original C++ binary:
./target/release/calc "2 + 2"   # stdout, exit code
./target/release/calc "1 / 0"   # same error + exit code as the C++ version
```

**[SAY]** "`<X passed; 0 failed>`. And the CLI matches the legacy binary
byte-for-byte on stdout, stderr, and exit codes — including the divide-by-zero
failure. The contract held."

---

## 5. The honest part — and why it's the point (~40s)

**[SAY]** "One thing we're upfront about. This verification runs on the host, not
in the agent's sandbox — because when we drove the real harness, we found its
released sandbox image ships without a C++ or Rust toolchain. We didn't fake
around that. We documented it as a gate, and we run the trusted verifier where
the tools actually are."

**[SHOW]** `docs/sdk-findings.md`.

**[SAY]** "That discipline is the whole project: the harness profiler measures how
design choices — like giving the agent Ripwire instead of plain grep — change the
work the model does, and it never reports a number it can't derive. A migration
that passes real tests, an agent that reads the call graph before it cuts, and an
honest map of what the harness must expose next."

---

## Live-value checklist (fill from the real run)

- `<top symbol>` names from the Ripwire map
- `<N>` symbols in the impact set
- `<X passed; 0 failed>` from `cargo test`
- CLI parity cases actually shown (success + a failure)

## Pre-record checklist

- [ ] C++ fixture exists with passing CTest tests (the "before")
- [ ] Ripwire server running on the fixture repo (`collector/ripwire-serve.sh`)
- [ ] `ripwire` connector attached to the agent; Instructions pasted
- [ ] Do one dry run so the sandbox is warm and numbers are known
- [ ] Original C++ CLI binary built, for the side-by-side parity check
