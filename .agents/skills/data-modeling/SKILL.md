---
name: data-modeling
description: "Data modeling - translate a conceptual domain model into a data model: classes, properties, attributes, tables, rows. Use when designing a new data structure from a domain: classes, entities, attributes, relationships, or a database schema."
metadata:
  source: "William Kent, Data and Reality, 3rd edition, with commentary by Steve Hoberman (Technics Publications, 2012)"
---

# Data Modeling

Data modeling turns the domain model into classes, tables, keys and constraints.

You are done when every decision a reader could not infer from the schema alone is written down as one row: the distinction, the representation chosen (key, constraint, table, column), and what enforces it (the database or the application). For every invariant retained, verify that the stated database or application mechanism actually guarantees it; a rationale alone is not enforcement. Put the rows in the design document the project already uses (a spec, a ticket, an ADR); if there is none, write them as comments next to the schema. A separate data model document would drift from the implementation.

Name classes, tables and columns with the project's glossary terms (`CONTEXT.md`). When a term is fuzzy, or two words compete for one concept, load the `domain-modeling` skill and settle the term before choosing its representation.

Settle these for each concept before choosing its representation:

- **Oneness**: what counts as one thing?
- **Sameness**: when do two records describe the same thing, and what stays the same when its attributes change?
- **Category**: entity, relationship, or attribute?
- **Existence**: when does it begin and end, and what is kept afterwards?
- **Scope of uniqueness**: within which set is a name or code unique? An implicit enclosing scope still belongs in the constraint.
- **Relationship**: why are these things related, and which role does each one play? Name every role; a relationship with more than two roles stays one relationship.
- **Bounds**: for everything that can grow (links per record, rows shown on one page, files and their size, text length), write the largest value you design for. When the domain states no maximum, choose one from the screen, the cost or the expected use, and say which. Name what enforces it, and make exceeding it fail loudly: an error at write time, or an alert where refusing would do more harm.
