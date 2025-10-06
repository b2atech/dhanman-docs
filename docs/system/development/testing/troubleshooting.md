# Testing Troubleshooting

- Flaky tests: identify non-determinism (time, async, external)
- Integration tests: reset DB state, use test containers
- E2E: stable selectors, test IDs strategy, retries where safe
- Logs: capture and attach on CI failures