---
name: single-file-surgeon
description: Make safe, minimal, anchored edits to Sautero's single-file HTML application instead of rewriting sections. Use this skill for any change to the main app file — adding a feature, fixing a bug, refactoring, changing markup or styles — and whenever the user reports that something unrelated broke after an edit, that a diff is unexpectedly large, or that a change was lost. Also use it before any edit that would touch more than a couple of hundred lines.
---

# Single-File Surgeon

Sautero is one large HTML file containing markup, styles and all application logic. This is
a legitimate architectural choice for a solo founder — no build step, trivial deploy — but
it has one failure mode that matters: an LLM asked to "update the recipe module" will
happily rewrite two thousand lines, silently reformat code it did not understand, and drop
a feature nobody notices for three weeks.

Every rule here exists to prevent that.

## The prime rule

**Never rewrite. Only splice.**

Locate the smallest unique anchor, replace exactly that, leave every surrounding byte
untouched. If you cannot find a unique anchor, the answer is to read more of the file —
not to rewrite a larger region so the edit becomes unambiguous.

## Before editing

1. **Read the target region first.** Never edit code you have not read in this session.
2. **Map the file once per session.** Report the section boundaries you found (styles,
   markup, i18n catalogue, Supabase client, module code, init) with line numbers. Work from
   the map afterwards.
3. **State the plan.** Which anchors, how many edits, estimated lines changed. Get
   agreement before touching anything if the estimate exceeds the budget below.

## Change budget

| Change size | Rule |
|---|---|
| < 50 lines | proceed |
| 50–200 lines | state the plan first, then proceed |
| > 200 lines | **stop.** Report why it is that large and propose a split into steps. |
| whole-section rewrite | never, unless the user explicitly asks in this message |

Exceeding the budget is not a judgement call to be made silently. Say the number.

## Editing discipline

- **One logical change per edit.** Do not fix an unrelated bug you noticed. Report it
  separately.
- **Never reformat.** Not indentation, not quote style, not semicolons, not line wrapping,
  not "while I was in there". Match the surrounding style exactly, even where it is ugly.
- **Never reorder** functions, CSS rules, or markup blocks.
- **Never touch the i18n catalogue from this skill** — that is `de-ch-i18n`'s job.
- **Never strip comments**, including ones that look obsolete. They may be anchors for
  other tooling or for the user's memory.
- **Preserve trailing whitespace and blank-line patterns** in the replaced region.

## Additive-first

When adding something new, prefer appending a self-contained block at the end of its
section over threading changes through existing code. New CSS at the end of the style
block, new function at the end of the module, new markup as a new container. Interleaving
is what produces enormous diffs and lost features.

## After editing

Verify, in this order, and report each:

1. **Diff size.** Actual lines added/removed. If it exceeds what you predicted, say so
   explicitly and explain the gap.
2. **Structural integrity.** Tag balance, brace balance, no truncation at the edit
   boundaries, file still parses.
3. **Nothing vanished.** Confirm the function/element count did not drop unless intended.
   This is the check that catches the catastrophic case.
4. **Scope.** List every section the diff touched. Anything outside the plan is a defect —
   revert it.
5. **Downstream.** If the edit added user-facing strings, say so and hand off to
   `de-ch-i18n`. If it renders user content or touches the database, hand off to
   `rls-guard`. Do not do their jobs here.

## If something goes wrong

Never attempt to repair a bad edit with another edit on top. Revert to the last known-good
state and redo the change with tighter anchors. A stack of corrections on a single-file app
is how a file becomes unreviewable.

## Note for the user

The right long-term move is to split the file into modules, and this skill is not a
substitute for that. But splitting is a large, risky change that should happen when there
is time and a green deploy gate — not in the middle of shipping a feature. If the user
starts asking about the split, say plainly that it is worth doing and that it needs its own
dedicated session, not a drive-by.
