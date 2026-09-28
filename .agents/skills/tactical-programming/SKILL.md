---
name: tactical-programming
description: "Tactical programming - make targeted, intentional changes to existing code with the fewest, best-known design moves. Use when implementing programming work handed to you, a standalone task or one ticket in a series: adding code, fixing a bug, refactoring, or changing poorly tested code."
---

# Tactical Programming

Targeted, intentional changes to existing code. Strategic design of the codebase has already been done, or won't be done right now.

The user who loaded this skill asks you to test and verify your work: write and run tests even if your default is to test only on request.

You are done when:
- a test you saw fail covers the behavior you added or fixed; for a refactoring, tests pin the current behavior and pass before and after;
- typechecking and the full test suite pass;
- you have read your whole diff (`git diff`) against the task;
- the work is committed to the current branch.

Use the `tdd` skill if available. If it is not, suggest the user install it: https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md

Get feedback early and often:
- run typechecking regularly;
- run single test files regularly;
- run the full test suite once at the end.

Once done, review the work with the `code-review` skill if it is available and can run in this session. Otherwise, read your diff against the task and the rules below. If it is not installed, suggest the user install it: https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md

## Every change

- Work in **vertical slices**: **tracer bullets** (Hunt & Thomas).
- Look for the **Shameless Green** (Sandi Metz): the simplest design that supports the behavior needed now.
- **Four Rules of Simple Design** (Kent Beck), in priority order: passes the tests; reveals intention; no duplication; fewest elements. They rank design for the present, working code: design happens every day.
- **Self-similarity** is a good place to start: solve the new problem the way the code already solves its neighbours, while it fits.
- Make the design an excellent fit for the needs of the system **that day**. When your understanding of the best possible design leaps forward, ask your orchestrator agent, or the user, whether to work gradually to bring the design back into alignment with it.
- Each change is a **structure-preserving transformation** (Christopher Alexander): it preserves, extends and intensifies the wholeness already present.
- **Intention-Revealing** names for methods and functions (Beck).

## Adding code

- Keep each piece of logic in **one clear home**, keep a conceptual change local, and make extension possible by changing one place.
- Every indirection earns its place with an explanatory or functional purpose; speculative flexibility loses to Shameless Green.
- **Polymorphism**: adding a new variation is adding a new object that provides the same interface as the other variations. Small, well-factored methods keep specialization local.
- **Define errors out of existence** (John Ousterhout): shape the API so there are no exceptions to handle.

## Fixing a bug

Write a unit test that goes red because of the bug, then fix the bug. Done when that test is green.

## Refactoring

Improve the design, behavior unchanged.

- **Characterization tests** make a **Software Vise** (Michael Feathers).
- **Flocking Rules** (Metz): small-step refactoring that makes similar code converge on an abstraction.
- **Break dependencies** (Feathers).
- Consider **Composed Method** (Beck): short, named messages at one level of abstraction, so the method reads like an explanation.
- Consider **Method Object** (Beck): turn a complex method invocation into an object carrying the receiver, arguments and temporary state, then refactor that object.
- Refine the interfaces between objects so their words are consistent with each other and with the domain vocabulary, wherever the project records it.
- **Pull complexity downwards** (Ousterhout): put unavoidable complexity behind a lower-level module when that simplifies the system and its callers. Use **Abstraction Barriers** (Abelson & Sussman).

## Changing poorly tested code

For each desired change, **make the change easy** (warning: this may be hard), **then make the easy change** (Beck):

1. Until you have a Software Vise, use **dependency-breaking techniques** (Feathers): Extract Interface, Parameterize Constructor, Subclass and Override Method, Encapsulate Global References. They create seams for characterization tests without first rewriting the system.
2. Only then, make the required change.
