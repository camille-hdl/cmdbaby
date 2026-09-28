---
name: hill-chart
description: Hill chart - draw the progress of a project's scopes as dots on a hill, Shape Up style. Use when the user wants to show or update where the scopes of a project stand, or asks for a hill chart.
---

# Hill Chart

A **hill chart** shows the progress of a project as dots on a hill ([Shape Up, ch. 13 “Show Progress”](https://basecamp.com/shapeup/3.4-chapter-13)). Each dot is a **scope**: a part of the project that can be built, integrated, and finished independently of the rest, named in the project's own language (“Locate”, “Reply”).

Every piece of work has two phases, one per half of the hill:

- **Uphill**, the left half, “Figuring out what to do”: uncertainty, unknowns, problem solving. The first third means “I've thought about this”, the second third “I've validated my approach”, the final third “I'm far enough with what I've built that I don't believe there are other unknowns.”
- **The top**: “Now I know what to do.”
- **Downhill**, the right half, “Getting it done”: execution. All the work is visible; what remains is doing it, down to the finish at the bottom right.

A dot's position is a judgment, not a percentage of tasks done: a scope with most of its tasks checked can still be uphill if an unknown remains.

## The chart

This rule is the user's, and it wins over any habit of your drawing tool:

> The chart is minimalistic: scopes are represented by points on the hill, labeled by their title in a friendly, readable font, their progress represented only by their position on the hill and relative to each-other. That's it. The user should be able to figure out in a second, without squinting, the rough progress of the scopes.

## 1. Place the scopes

List the project's scopes with their titles, from the user or the project's documents. For each one, assign a numeric position from 0 (left foot) to 1 (finish), with 0.5 at the top of the hill:

- the user's placement, when they give one: the people doing the work have the full context;
- otherwise, your judgment from what the user tells you, with the thirds above, and you say which dots you placed yourself;
- otherwise, ask the user.

A scope that is partly over the hill and partly not has no single position: propose splitting it into smaller scopes.

Done when every scope has a title and a position from 0 to 1: below 0.5 is uphill, 0.5 is the top, and above 0.5 is downhill.

## 2. Draw

Draw the hill and its dots with the tool the user names, when they name one. Otherwise, use `@camille-hdl/hill-chart` first: write a one-line JSON file such as `{"scopes":[{"name":"Login","position":0.9}]}`, then run `npx @camille-hdl/hill-chart chart.json -o chart.png` (or `npx @camille-hdl/hill-chart chart.json > chart.svg`). If that package is unavailable or unsuitable, use any other tool available to you that produces an image. When no tool fits, ask the user.

Done when the image file exists.

## 3. Check the image

Look at the image yourself before showing it, and read it as the user will: in one second, without squinting. Each title is readable and clearly belongs to its dot, no two labels overlap, and the order of the dots on the hill matches step 1. Fix the drawing and check again. If you cannot view the image, say so when you show it.

Done when the rough progress of every scope reads at a glance.

## 4. Show and update

Give the user the image path, with one line per scope that moved, or that you placed yourself.

At each update, move the dots from the previous chart rather than placing them afresh, so movement shows. A dot that has not moved since the last update is a raised hand, “Something might be wrong here”: name it to the user, and ask what could be solved to get it over the hill.

Done when the user has the chart, and each stuck dot has been named.
