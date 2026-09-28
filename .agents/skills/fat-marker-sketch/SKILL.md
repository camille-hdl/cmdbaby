---
name: fat-marker-sketch
description: Fat marker sketch - draw very low-fidelity UI concepts as hand-drawn images, several variants side by side. Use when the user wants to explore UI or UX directions for a problem quickly, before wireframes or prototypes, or asks for a rough sketch of a screen, component, or flow.
---

# Fat Marker Sketch

A **fat marker sketch** is a UI concept drawn “with such broad strokes that adding detail is difficult or impossible” ([Shape Up, ch. 4](https://basecamp.com/shapeup/1.3-chapter-04)). The thick line keeps detail loose while making an idea visible, so the user can compare directions and pick one in minutes.

The **elements** are the output; the drawing only makes them visible. There are three kinds:

1. **Places**: what can be displayed or navigated to: screens, panels, dialogs, drop-down menus…
2. **Affordances**: what the user can act on or read: buttons, links, form fields, checkboxes, tooltips, labels.
3. **Arrows**: how the affordances take the user from place to place.

Leave out colors, copy, spacing, icons, and exact sizes. A labeled box is a finished affordance.

## 1. Frame the sketch

Fix what you are sketching (one screen, component, or flow) and the problem it solves, from the request. Default to **3 variants**, or the number the user asked for. Each variant is a genuinely different direction, not the same layout with a detail moved.

Done when you can state the problem in one sentence and name each variant in a few words.

## 2. Write the elements

For each variant, list its places, affordances, and arrows in text, using short place names for the `place` values in the JSON you render in step 3. Two examples:

```text
A · Map with side panel
- place: a map zoomed in on a country
- affordance: a dot for each point of interest, no clusters
- place: a panel showing a grid of postcards from that point of interest
- arrow: clicking a dot opens the panel

B · Collapsible page tree
- place: the list of top-level pages
- affordance: a search field above the pages
- affordance: a chevron before each page, pointing right when its subpages are hidden, down when they are visible
- arrow: clicking the chevron toggles the subpages
```

Done when every variant accounts for all three kinds, and every arrow starts from an affordance and ends in a place.

## 3. Draw

Draw all variants side by side in one image, left to right, each under its name, with a thick, hand-drawn line. Use the tool the user names, when they name one. Otherwise, use `@camille-hdl/fat-marker` first: write a one-line JSON file such as `{"variants":[{"variant":"A · Search","contains":[{"place":"Search","contains":[{"affordance":"Search"}]}]}]}`, then run `npx @camille-hdl/fat-marker sketch.json -o sketch.png`. If that package is unavailable or unsuitable, use any other tool available to you that produces an image. See the [package README](https://github.com/camille-hdl/fat-marker#readme) for the format and CLI, or run `npx @camille-hdl/fat-marker --help` for the complete format guide and example. When no tool fits, ask the user.

Done when the image file exists.

## 4. Check the image

Look at the image yourself before showing it: overlaps, clipped text, and arrows that miss their target show only there. Fix the drawing and check again. If you cannot view the image, say so when you show it.

With `@camille-hdl/fat-marker`, read stderr first: each `fat-marker: warning:` line names an arrow, by the field of its `to`, that runs through a place's name, or an affordance's label or scribble. Rearrange the data and render again until no warning is left: set the target place beside the affordance's place in a row, put the affordance last in its row, or move the crossed element. A warning does not fail the command. If one remains, say so when you show the image.

Done when each element from step 2 is visible and readable in its variant, and the render printed no warning, or you said which remain.

## 5. Show and iterate

Give the user the image path, and the editable source if the tool produced one. Summarize each variant in one line.

When the user picks a direction, sketch variants of that direction, or of the next element it leads to, with the same steps.

Done when the user has picked a direction or asked for other variants.
