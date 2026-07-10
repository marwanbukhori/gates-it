# How `02-showcase/` was built — AI-driven development in practice

`02-showcase/` (Pawmise) was built using AI-driven development with Claude and the `superpowers` plugin. This document describes the actual process: what I did, what the AI did, and why the distinction matters.

---

## Why document this at all?

The assessment says "the answer must not be built with AI." The answer (`01-answers/`) isn't — I wrote it by hand. But `02-showcase/` is something different: it's a deliberate demonstration of a development workflow I use on real projects. Hiding it would be dishonest. Documenting it honestly is more useful to any reviewer who wants to understand how I work.

---

## The workflow

### 1. Brainstorm — what are we actually building?

Before writing any spec, I worked out the product story: what would make both assessment tasks coherent in a single product? The answer was a pet-adoption platform where the discount engine is the fee engine. This is not an arbitrary connection — it's a real product use case that motivates every architectural decision.

The constraints I set myself:
- `Domain/Discount` is never modified. It is composed, not extended.
- `01-answers/` is never touched.
- Every phase ships working, tested software before the next begins.

### 2. Spec — write precise requirements before touching code

Each phase of Pawmise has a written technical spec:

- **Roadmap** (`docs/superpowers/specs/2026-07-10-pawmise-roadmap.md`) — product vision, phased plan, scope guardrails
- **Phase 1 backend design** (`docs/superpowers/specs/2026-07-10-pawmise-phase1-backend-design.md`) — exact entity schemas, API surface, fee engine composition rules, test requirements, acceptance criteria

The spec is precise enough that there is only one reasonable implementation. Ambiguous specs produce ambiguous code. Writing a good spec is a significant part of the work.

Examples of decisions the spec resolves before any code is generated:
- Which strategy handles loyalty fees (not `LoyaltyDiscount` — its semantics are wrong for a configurable rate; `PercentageDiscount` with a config value instead)
- How the fee engine selects a discount when multiple apply (best single discount wins; centralised in one method; stacking is a one-method change if requirements change)
- Why adoption fees are stored on the `Adoption` record (auditability — a fee must reflect what was calculated at the time, not the current config)
- Exactly which endpoints are public vs protected, and which return problem+json vs the Laravel default

### 3. Plan — break the spec into independent, reviewable tasks

Before running any generation, I broke the Phase 1 spec into independent subtasks. A good plan has tasks that:
- Have clear acceptance criteria
- Can be reviewed independently
- Don't assume a specific implementation of the next task

For Phase 1, the tasks were approximately:
1. Config file and Sanctum install
2. User migration (add `adoptions_count`)
3. `Pet` model, migration, factory, seeder
4. `Adoption` model and migration
5. `AdoptionFeeCalculator` + value objects + unit tests
6. API endpoints + feature tests
7. OpenAPI spec update

### 4. Execute with review gates

Each task was given to a subagent with the relevant section of the spec as context. After each task, I reviewed:

- **Correctness** — does the code do what the spec says?
- **Architecture fit** — does the new code respect the layer rules? Does `Domain/Adoption` import anything from `Illuminate\*`? Does the controller do any business logic?
- **Test coverage** — does the test cover the specified paths? Are there edge cases in the spec that are not covered?
- **Naming** — are the names consistent with the existing codebase conventions?

This is the most important part of the process. AI generation without review is not engineering. Every class in `02-showcase/laravel/app/Domain/Adoption/` was read, understood, and accepted (or sent back for revision) before being committed.

Concrete examples of things I caught and corrected during review:
- The original `AdoptionFeeCalculator` used a `max()` comparison on money amounts without normalising units — corrected to compare savings as floats before selecting.
- An early draft of the fee calculator imported `Illuminate\Support\Collection`. That violates the domain layer rule. Replaced with a plain PHP array.

### 5. Verify

After each phase, I ran the full test suite to confirm nothing regressed:

```bash
(cd 02-showcase/laravel && composer test)
```

Tests are not generated as an afterthought — the spec lists them as acceptance criteria. Every new path through the fee engine has a corresponding unit test written to spec before the implementation is accepted.

---

## What AI is good at in this workflow

- Generating boilerplate that follows a clear pattern (migrations, factories, resources, form requests)
- Filling in a class to a precise interface specification
- Writing exhaustive test cases for a specified set of inputs
- Keeping code consistent with surrounding style when given examples

## What I do that AI cannot do (yet)

- Decide what to build and why
- Write the spec precisely enough that the implementation is correct by construction
- Recognise when a generated class violates a layer rule that wasn't in the immediate prompt
- Know when the "obvious" implementation has a subtle correctness problem (the fee comparison example above)
- Make architectural trade-offs that won't be obvious until the system grows

---

## Why AI fluency is a hireable skill

The difference between a developer who uses AI well and one who doesn't is not whether they use it — it's the quality of what they specify and the rigour with which they review. The output of this workflow is a codebase I can reason about, explain, and maintain. The architecture decisions, the layer boundaries, the error semantics, the test requirements — all of these came from me.

If you want to verify that claim: ask me to walk through `AdoptionFeeCalculator` in a code review. I can explain every decision. Ask me why `PercentageDiscount` was chosen for loyalty fees instead of `LoyaltyDiscount`. I can give you the exact reasoning. That's what directing AI looks like in practice.

---

## Tooling reference

- **Claude** — Anthropic's LLM, accessed via claude.ai
- **`superpowers` plugin** — Claude Code plugin providing brainstorming, spec writing, plan creation, and subagent execution with review gates
- Git worktrees for parallel development without branch switching
