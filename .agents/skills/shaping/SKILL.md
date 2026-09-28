---
name: shaping
description: "Shaping - turn a raw idea for a change into a pitch, after Shape Up: the problem, the solution, its no-gos and rabbit holes."
disable-model-invocation: true
metadata:
  source: "Ryan Singer, Shape Up: Stop Running in Circles and Ship Work that Matters (Basecamp, 2019)"
---

# Shaping

Grill the user to turn their raw idea for a change (a new feature, or a change to an existing one) into a solved, bounded solution: a **pitch**.

You are done when the user has approved a pitch that the agent building it can use without this conversation, and that contains, in the glossary's terms:

- the problem: one specific story that shows why the way it works today fails;
- the appetite;
- the solution:
  - the elements of each chosen sketch (places, affordances, arrows), with the sketch;
  - must-haves;
  - nice-to-haves;
  - no-gos;
  - what is left to the builder;
- the rabbit holes, each with the decision that avoids it.

The **appetite** bounds the solution: an investment limit agreed with the user right after the problem, before exploring solutions. An agent builds it, so measure it in what stays scarce rather than in build time: the user's attention, the review and testing the user or team must do, the risk to existing data and behavior, and the tokens spent (scope drift, endless review cycles). Express it concretely, for example "small: reviewed in one sitting, no data migration". Move every must-have that exceeds it to the nice-to-haves or the no-gos, or revisit the appetite with the user.

## 1. Grill

Grill the user with the `grill-with-docs` skill, if available: only the user can invoke it, so load the two skills it calls, `grilling` and `domain-modeling`. If it is not available, suggest the user install it: https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md

Settle the problem before the solution. Act as an expert with a duty to advise, and let the user speak first: ask for a real, recent case in their own words and what they do today without the change, then offer choices, with your recommendation, to help them sharpen it. The answer stays theirs. Ask each question in terms of what people see and do in the product, so a user who does not read code can answer it.

When the solution has a UI, use the `fat-marker-sketch` skill as a decision tool on the flow: 2 or 3 meaningfully different versions of the key screen or flow, for the user to pick one or adjust it. Resume the questions the comparison exposes, and sketch again only when a remaining product decision needs it; leave visual polish and routine screens to implementation. If the skill is not available, suggest the user install it: https://github.com/camille-hdl/skills/blob/main/skills/fat-marker-sketch/SKILL.md

Done when the problem, the appetite and the solution are settled with the user, including a chosen version of each sketched screen or flow.

## 2. Find the rabbit holes

Walk through the chosen solution step by step, from the user's first action to the end, against the code and the rest of the product. At each step, look for new technical work, assumptions about how parts fit together (data, scheduled jobs, notifications, permissions, payments), and hard decisions better settled now. Finding them is your job: check each assumption whose failure would change the scope or invalidate the approach, and mark the ones you cannot check as unverified. For each rabbit hole, tell the user what they would see go wrong, then let them choose: patch it with a simpler behavior, declare it a no-go, or cut the part that causes it down to a nice-to-have.

Done when you have walked every step of the solution, and every rabbit hole found has the user's decision.

## 3. Write the pitch

Write the pitch where the project keeps its specs or plans; if there is none, propose `docs/pitches/<date>-<slug>.md` and ask the user to confirm. Copy each chosen sketch next to the pitch and link it from there.

Before showing it, read the pitch as the agent that will build it, without this conversation: list every point where it would have to guess (a limit, a time zone, what happens to existing data, who is notified). If you can dispatch a sub-agent, give it only the pitch and the repository, and ask it for that list. Settle each point with the user, or write it down as left to the builder. Then show the pitch to the user and revise it with them.

Done when the user approves it. Approval ends shaping: then ask the user what comes next, among a technical spec (suggest they invoke the `to-spec` skill, in this same conversation), a discussion with the team, or building it.

## Every design decision

- **Design it twice** (John Ousterhout): consider several options for each major design decision, and let the user choose, with your guidance.
- **Structure-preserving transformation** (Christopher Alexander): a change preserves, extends and intensifies the wholeness already present, instead of disrupting it. Ask how the change integrates with the rest of the system.
