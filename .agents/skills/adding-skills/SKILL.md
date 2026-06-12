---
name: adding-skills
description: "Guidelines for adding new agent skills: always register in AGENTS.md, and prefer deterministic scripts with unit tests over pure SKILL.md for repeatable workflows."
metadata:
  version: "1.0.0"
---

# Adding Skills

## Always register in AGENTS.md

Every new skill **must** have a routing entry in `AGENTS.md` under `## Skill routing`. Without it, agents won't know to load the skill.

```markdown
| <trigger description> | `skill-name` |
```

The trigger description should match the natural language phrases a user or agent would use when the skill is relevant. Check existing entries for style.

After adding the skill file, verify the entry exists — the skill is not discoverable until it is registered.

## Script vs SKILL.md

When the task being documented is **deterministic and repeatable** (same inputs → same outputs, no ambiguity, can be verified), prefer a script over a pure SKILL.md:

| Situation | Prefer |
|-----------|--------|
| Workflow requires judgment or context (e.g. designing hook behavior, choosing arg-parsing strategy) | SKILL.md |
| Workflow is a fixed sequence of CLI calls with predictable outputs | Script + unit tests |
| AI-only meta-task (e.g. how to add skills, how to create PRs) | SKILL.md |

When creating a script:
- Write unit tests covering pure functions (`test_<name>.py` or equivalent)
- Keep the SKILL.md thin — point to the script and document usage, not the logic
