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
