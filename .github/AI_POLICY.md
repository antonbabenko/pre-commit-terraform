# AI / LLM Usage Policy

## The short version

You are responsible for every line you submit. If a maintainer asks you about any part of your change, you must be able to answer. If you can't, the PR will be closed.

## Ownership

The contributor — not the AI — is the author of the contribution. Using an LLM to generate code, tests, or documentation does not transfer responsibility to the tool. You are expected to:

- Understand every line of your change well enough to discuss it in review
- Have actually run and tested the code yourself
- Be able to explain *why* the change is correct, not just *what* it does

The LLM types for you. It doesn't think for you.

## Recommended tooling

If you're using an AI coding agent, install [OpenSpec](https://openspec.dev/) (`npm install -g @fission-ai/openspec@latest`, then `openspec init`) and use its spec-driven workflow (`/opsx:propose` → `/opsx:apply`) to scope the change into a reviewable proposal + spec + tasks *before* any code gets written. This repo already ships the matching skills/commands — see [`AGENTS.md`](../AGENTS.md#skill-routing).

Scoping the change up front makes it easier to meet the ownership expectations above: you review and understand the plan before the AI starts typing, instead of reverse-engineering intent from a pile of already-generated code.

## Disclosure

You are encouraged (but not required) to disclose when AI tools contributed to your work. A short note in the PR description is enough — e.g. *"Tests were initially drafted with an LLM and then reviewed and adjusted by me."*

Disclosure is not a liability. It helps maintainers calibrate their review. Hiding it when it's obvious wastes everyone's time.

## Slop

Pull requests that are clearly AI-generated without meaningful human review — cosmetically formatted but logically incorrect, missing context, or unrelated to any real issue — will be closed as spam without further discussion.

If you're not sure whether your PR meets the bar: re-read it line by line, run it, and ask yourself whether you can defend every decision in it.

## Questions or disagreements

This policy is intentionally minimal and open to refinement. If you think something here is wrong or missing, open an issue.
