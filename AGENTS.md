# Agent brief

Read [`PROJECT.md`](PROJECT.md) for the full project description and
[`TRACE_SCHEMA.md`](TRACE_SCHEMA.md) for the data contract before doing anything.

## Hard rules

1. **The trace schema is a contract** between two people working in parallel.
   Do not change a field without saying so explicitly and bumping
   `schema_version`.
2. **Stay in your lane.** `collector/` and `analyzer/` have different owners.
   Do not edit across the boundary. Do not "helpfully" refactor the other side.
3. **The analyzer must always work against `samples/`.** Those hand-made traces
   exist so the analysis half can be built before any real run exists.
4. **One setting changed per variant.** Never two. That is the whole method.
5. **Report spread across repeats**, never a single run. Agents are
   non-deterministic; a single number is not a result.
6. **Do not invent numbers.** If a metric cannot be derived from the trace,
   say so and stop.
7. Discovery before code on the collector side: find out what the TrueForge SDK
   and SSE stream actually expose, report it, then build.

## Style

- Small, independent modules. One metric per function.
- Plain output — a table and a few charts. No dashboard framework.
- Comments explain *why a metric matters*, not what the line does.
