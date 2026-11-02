# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The project guide for every coding agent is AGENTS.md: commands, definition of done, architecture, testing rules, Connect IQ traps and the Liftosaur API facts. It is imported here so there is one source to keep current.

@AGENTS.md

## Claude Code specifics

- Simulator runs (`scripts/test.sh`, `scripts/preview.sh`) take 15-60 s and share one simulator: run them one at a time, never in parallel.
- To see a preview, capture only the simulator window (find its id with `CGWindowListCopyWindowInfo`, then `screencapture -l <id>`), never the whole screen.
- Background tests take about 5 minutes per wake-up: run them with `run_in_background` and wait for the notification.
- Commit as the noreply identity already set in the repo's git config.
