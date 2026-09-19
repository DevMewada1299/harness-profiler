# Python TrueForge Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and run an honest local TrueForge Python bug-fix demonstration, using a pinned public fixture and curated read-only research tools.

**Architecture:** The public fixture is a dependency-free Python calculator whose initial commit intentionally fails `unittest`. The local TrueForge UI has a sandbox-only fixer and a separate research agent. The harness repository stores task metadata and demo evidence, but does not write benchmark traces.

**Tech Stack:** Python 3.13 standard-library `unittest`, Git, local TrueForge 0.2.0, Daytona, direct OpenAI, DeepWiki/Exa/Parallel Web remote MCP servers.

**Spec:** `docs/superpowers/specs/2026-09-19-python-trueforge-demo-design.md`

## Global Constraints

- Work in User A's collector lane only; do not edit `analyzer/`.
- Preserve `TRACE_SCHEMA.md` v0.1. Do not create a trace with inferred or fabricated measurements.
- Use only `python3 -m unittest -v`; no pytest or package installation.
- Pin the task to a full Git commit and label its live session `exploratory_demo`.
- The fixture clone begins after the first model call; it is not benchmark staging evidence.
- The fixer has no MCP servers or TrueForge skills.
- The research agent mounts only connected `deepwiki`, `exa`, and `parallel-web` MCP servers with deferred discovery, plus deferred `wiki-qa`.
- Do not install, bridge, or invoke Ripwire.
- Use fixed model `gpt-5-4-mini` and reasoning effort `low` in every live demo session.

## Review Focus

- Division by zero must raise `ZeroDivisionError`; Task 1 owns its test.
- The fixture pin must equal the remote branch head; Task 2 proves the equality.
- The fixture must need no package manager; Task 1 reruns in a clean clone.
- Research tools must not leak into the fixer configuration; Task 3 includes a UI inspection.
- No exploratory session may appear as a benchmark trace; Task 4 checks `traces/` is untouched.

---

## File Structure

| Location | Responsibility |
|---|---|
| `https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git` branch `python-demo` | Intentionally failing Python fixture. |
| `tasks/python-unittest-calculator-01.json` | Pinned fixture metadata, verifier, prompt, and task shape. |
| `docs/sdk-findings.md` | Live Python/pytest tool evidence. |
| `docs/python-trueforge-demo-runbook.md` | Exact local agent settings and safe public prompts. |
| `docs/python-trueforge-demo-handoff.md` | Actual fixture pin, sessions, result, and limitations. |

## Task 1: Create and publish the failing fixture

**Files:**
- Create in fixture repository: `calculator.py`
- Create in fixture repository: `test_calculator.py`
- Create in fixture repository: `README.md`
- Create in fixture repository: `.gitignore`

**Interfaces:**
- Produces: `divide(left: float, right: float) -> float`.
- Produces: verifier command `python3 -m unittest -v`.

- [ ] **Step 1: Create the fixture branch**

Run:

```sh
git clone https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git /private/tmp/python-trueforge-demo-fixture
git -C /private/tmp/python-trueforge-demo-fixture checkout -b python-demo
```

Expected: `git -C /private/tmp/python-trueforge-demo-fixture branch --show-current` prints `python-demo`.

- [ ] **Step 2: Write the intentionally wrong implementation and objective test**

Create `calculator.py`:

```python
def divide(left: float, right: float) -> float:
    """Return the quotient of two numbers."""
    return left * right
```

Create `test_calculator.py`:

```python
import unittest

from calculator import divide


class DivideTests(unittest.TestCase):
    def test_divide_returns_the_quotient(self) -> None:
        self.assertEqual(divide(8, 4), 2)

    def test_divide_by_zero_raises(self) -> None:
        with self.assertRaises(ZeroDivisionError):
            divide(1, 0)


if __name__ == "__main__":
    unittest.main()
```

Create `README.md`:

~~~markdown
# Python calculator fixture

Run the verifier with:

```sh
python3 -m unittest -v
```
~~~

Create `.gitignore`:

```text
__pycache__/
*.py[cod]
```

- [ ] **Step 3: Prove the fixture starts broken**

Run from `/private/tmp/python-trueforge-demo-fixture`:

```sh
python3 -m unittest -v
```

Expected: FAIL. The normal division receives `32` instead of `2`; division by zero does not raise.

- [ ] **Step 4: Publish the immutable broken fixture**

Run:

```sh
git add calculator.py test_calculator.py README.md .gitignore
git commit -m "fixture: add failing Python calculator"
git push --set-upstream origin python-demo
git rev-parse HEAD
```

Expected: the final command prints one 40-character commit hash. Save it as `FIXTURE_COMMIT` for Task 2.

- [ ] **Step 5: Reproduce the failure from a clean clone**

Run:

```sh
git clone --branch python-demo https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git /private/tmp/python-trueforge-demo-fixture-verify
cd /private/tmp/python-trueforge-demo-fixture-verify
python3 -m unittest -v
```

Expected: the same two failures occur without a package manager or installation command.

## Task 2: Add the pinned task card and demo documentation

**Files:**
- Create: `tasks/python-unittest-calculator-01.json`
- Modify: `docs/sdk-findings.md`
- Create: `docs/python-trueforge-demo-runbook.md`

**Interfaces:**
- Consumes: `FIXTURE_COMMIT` produced by Task 1.
- Produces: task metadata and the exact configuration consumed in Task 3.

- [ ] **Step 1: Write the pinned task card**

Create `tasks/python-unittest-calculator-01.json`, replacing both `FIXTURE_COMMIT` strings with the literal Task 1 hash:

```json
{
  "task_id": "python-unittest-calculator-01",
  "prompt": "Clone https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git into /tmp/python-calculator, check out commit FIXTURE_COMMIT, run python3 -m unittest -v, identify the smallest code fix, change only calculator.py, and rerun python3 -m unittest -v. Do not install packages. Report the final verifier output.",
  "repo_url": "https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git",
  "commit": "FIXTURE_COMMIT",
  "repo_path": "/tmp/python-calculator",
  "verify_cmd": "python3 -m unittest -v",
  "shape": {
    "files_touched_expected": 1,
    "turns_expected": 4,
    "kind": "single_file_edit",
    "search_heavy": false,
    "tool_output_heavy": false
  }
}
```

- [ ] **Step 2: Validate the JSON and fixture pin**

Run:

```sh
python3 -m json.tool tasks/python-unittest-calculator-01.json
git ls-remote https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git refs/heads/python-demo
git -C /private/tmp/python-trueforge-demo-fixture cat-file -e FIXTURE_COMMIT^{commit}
```

Expected: JSON parses; `ls-remote` prints the exact task-card hash; `cat-file` exits successfully.

- [ ] **Step 3: Record Python tool evidence**

Add this row to `docs/sdk-findings.md`:

```markdown
| Python standard-library verifier available? | **Yes.** A live sandbox reported `Python 3.13.15`; `python3 -m pytest --version` failed because pytest is not installed. | Local TrueForge session on 2026-09-19 |
```

Expected: existing CMake, C++, Rust, staging, gateway, compaction, and Ripwire findings are unchanged.

- [ ] **Step 4: Write the exact runbook**

Create `docs/python-trueforge-demo-runbook.md`:

~~~markdown
# Local Python TrueForge demo

## Fixed settings

- Model: `gpt-5-4-mini`
- Reasoning effort: `low`
- Label every live session: `exploratory_demo`
- Do not create files in `traces/`.

## Python Fixer Demo

- Sandbox: enabled
- Dynamic subagents: disabled
- Compaction: disabled
- Large tool response: disabled
- MCP servers: none
- Skills: none

Send the exact `prompt` from `tasks/python-unittest-calculator-01.json`.

Pass condition: `python3 -m unittest -v` reports `Ran 2 tests` then `OK`; `git -C /tmp/python-calculator diff --name-only` prints only `calculator.py`.

## Research Tools Demo

- Sandbox: disabled
- MCP servers: `deepwiki`, `exa`, and `parallel-web`
- MCP preload: disabled; preload tools: none
- Skills: `wiki-qa`, preload disabled

Public prompt: `Using DeepWiki only, summarize the purpose of https://github.com/redhat-et/ripwire in two sentences and name one read-only repository-navigation capability. Do not create, edit, or transmit any data.`

Pass condition: a successful DeepWiki tool call is visible and the answer is grounded in the public repository.

## Audience statement

This is an exploratory local demonstration. Fixture cloning begins after the first model call, and direct OpenAI does not provide the gateway telemetry needed for a valid harness benchmark trace.
~~~

- [ ] **Step 5: Commit task metadata and documentation**

Run:

```sh
git add tasks/python-unittest-calculator-01.json docs/sdk-findings.md docs/python-trueforge-demo-runbook.md
git diff --cached --check
git commit -m "docs: add Python TrueForge demo task"
```

Expected: staged whitespace verification succeeds. No change is made to `analyzer/`, `TRACE_SCHEMA.md`, or `traces/`.

## Task 3: Configure and exercise local TrueForge agents

**Files:**
- Create in local TrueForge: saved agent `Python Fixer Demo`
- Create in local TrueForge: saved agent `Research Tools Demo`

**Interfaces:**
- Consumes: the exact settings and prompts in `docs/python-trueforge-demo-runbook.md`.
- Produces: two local session URLs and a successful sandbox verifier for Task 4.

- [ ] **Step 1: Enable the approved research skill**

In `http://localhost:8790/settings`, open **Skills** and enable `wiki-qa` only.

Expected: `wiki-qa` is configured; `mcp-builder`, `skill-creator`, and unrelated skills remain disabled.

- [ ] **Step 2: Create and validate Research Tools Demo**

Create and save `Research Tools Demo` with the fixed model and reasoning effort. Add only `deepwiki`, `exa`, and `parallel-web`; set all to deferred discovery with no preloaded tool. Add `wiki-qa` with preload disabled. Disable sandbox, dynamic subagents, compaction, and large tool response.

Expected: the saved-agent detail shows exactly three MCP servers, one skill, and sandbox disabled. Send the public runbook prompt; its agent steps show a successful `deepwiki` call. Record the session URL.

- [ ] **Step 3: Create and inspect Python Fixer Demo**

Create and save `Python Fixer Demo` with the fixed model and reasoning effort. Enable sandbox; disable dynamic subagents, compaction, and large tool response. Attach zero MCP servers and zero skills.

Expected: saved-agent detail shows sandbox enabled, zero MCP servers, zero skills, and all optional runtime features disabled.

- [ ] **Step 4: Run the pinned fix**

Send the exact task-card prompt to Python Fixer Demo. Do not approve package installation or alter the sandbox image.

Expected: the agent observes the failing verifier, changes only `calculator.py`, and its final output contains `Ran 2 tests` and `OK`. Record the session URL and final `git diff --name-only`.

## Task 4: Preserve truthful evidence and show the analyzer boundary

**Files:**
- Create: `docs/python-trueforge-demo-handoff.md`

**Interfaces:**
- Consumes: `FIXTURE_COMMIT`, task card, Research Tools session URL, and Fixer session URL.
- Produces: a reviewable non-benchmark handoff for User B and the audience.

- [ ] **Step 1: Confirm there is no benchmark trace**

Run:

```sh
git status --short traces
git diff --name-only -- traces
```

Expected: neither command prints a trace path. If either does, do not use that trace in the analyzer or presentation.

- [ ] **Step 2: Write the handoff after sessions complete**

Create `docs/python-trueforge-demo-handoff.md` with this structure, replacing each all-caps value with recorded evidence:

```markdown
# Python TrueForge demo handoff

- Fixture: `https://github.com/DevMewada1299/cpp-to-rust-calculator-fixture.git`
- Branch: `python-demo`
- Immutable fixture commit: `FIXTURE_COMMIT`
- Verifier: `python3 -m unittest -v`
- Research session: `RESEARCH_SESSION_URL`
- Fixer session: `FIXER_SESSION_URL`
- Fixer result: `Ran 2 tests` followed by `OK`; only `calculator.py` changed in the task-local clone.

## Scope label

`exploratory_demo`, not a benchmark measurement. The fixture clone happens after the first model call; the local sandbox lacks the C++/Rust toolchain; and direct OpenAI does not provide gateway raw-prompt, cache, cost, or `run_id` telemetry. No JSONL trace was generated from these sessions.

## User B note

Continue to run the analyzer against `samples/` until collector discovery supports every trace-schema field. Do not infer a harness comparison, recommendation, or Ripwire-specific timing from this demonstration.
```

- [ ] **Step 3: Demonstrate the analyzer only from User B's code**

If User B's completed analyzer branch is accessible, run its documented sample command from that branch:

```sh
npm run report -- ../samples/*.jsonl
```

Expected: an HTML report is generated from sample traces and is labelled sample-backed. If the branch is unavailable in this clone, do not recreate it or edit `analyzer/`; ask User B to open their completed report locally.

- [ ] **Step 4: Commit final evidence**

Run:

```sh
git add docs/python-trueforge-demo-handoff.md
git diff --cached --check
git commit -m "docs: record Python TrueForge demo evidence"
git status --short --branch
```

Expected: staged whitespace verification succeeds and the User A working tree is clean after the commit.
