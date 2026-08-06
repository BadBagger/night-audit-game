# Night Audit — Godot vertical slice

A playable slice of Chapters I–III:

- **Chapter I — "The Container"**: top-down movement, one NPC conversation,
  three examinable clues plus two red-herring props, the deduction-board
  puzzle, and the pocket-the-phone / leave-it choice that seeds the Ledger.
- **Chapter II — "Debts Owed"**: three contacts (Sal, Priya, Costigan),
  visitable in any order, each with their own puzzle and (for Sal/Priya) a
  Pay / Lean / Work branch that feeds the Ledger.
- **Chapter III — "The Boat"**: a real-time patrol/detection encounter with
  Voss, the skim-audit puzzle (a 12-transaction ledger to reconcile), the
  safe/desk-grab branch gated on Sal's Chapter II outcome, and a scripted
  confrontation ending that plays out differently depending on whether
  Dana got spotted.

## Requirements

Godot 4.x. Verified against Godot 4.7.1, played through by hand and
confirmed working end to end (Chapter I).

Two levels of automated verification exist per chapter:

1. **Load check**: `godot --headless --quit-after 3` — confirms the scene
   builds and every script parses. Caught and fixed one real bug this way:
   `Camera2D.current` doesn't exist in Godot 4 (renamed to `enabled` from
   Godot 3) — the camera setup was silently broken until this was corrected.
2. **Full flow check**: `tools/TestChapter1Driver.gd`,
   `tools/TestChapter2Driver.gd`, and `tools/TestChapter3Driver.gd` (run via
   `godot --headless --path . res://tools/TestChapter1.tscn`, `TestChapter2.tscn`,
   or `TestChapter3.tscn`) drive each chapter's *entire* loop end-to-end
   against the real game logic — not just "does it load." These are
   regression tests: rerun the relevant one(s) after touching `Main.gd`,
   `Chapter2.gd`, `Chapter3.gd`, `DialogueBox.gd`, `DeductionBoard.gd`,
   `TicketBoard.gd`, `ManifestBoard.gd`, `AuditBoard.gd`, `PatrolNPC.gd`,
   or `GameState.gd` — 52/52 checks currently pass across all three.
   - Chapter I: 15/15, including audio-loads-on-a-line, a deliberate wrong
     deduction-board answer, and a repeat-examine.
   - Chapter II: 23/23, including audio-loads, a wrong ticket on Sal's
     cipher, a wrong donation flag on Priya's manifest, and Costigan's
     full state machine (one soft miss from `hostile`, then the correct
     grief → case → offer sequence to reach `open`).
   - Chapter III: 14/14, including audio-loads, an over-flagged audit
     attempt that correctly rejects before the exact set solves it, a
     first Voss spot that cover-holds under favorable conditions, and —
     tested in a separate isolated phase, since the guard that blocks
     re-triggering the confrontation after a successful ending would
     otherwise mask it — the rule that a *second* spot always forces
     retreat regardless of how good Dana's cover is.

**A real bug this testing caught**: `AuditBoard`'s exact-match win check
could fire `solved` twice in a row if a player toggled a flag off right
after completing the correct set (untoggling can re-create an exact match
from a different direction), and `Chapter3.gd`'s handler didn't guard
against being called twice — the second call tried to make a duplicate
signal connection and crashed. Fixed with a one-line guard
(`if GameState.get_flag("audit_solved", false): return`) at the top of
`_on_audit_solved()`. Worth checking `DeductionBoard.gd`'s and
`ManifestBoard.gd`'s equivalent handlers if this class of bug matters to
you — they weren't audited for the same issue.

**Known gap**: the Chapter I → Chapter II and Chapter II → Chapter III
scene transitions (`get_tree().change_scene_to_file`) are *not* covered by
any automated test — each harness instantiates its chapter's scene as a
plain child rather than as the engine's real `current_scene`, and calling
`change_scene_to_file` in that context frees the test driver itself
instead of the intended scene (confirmed by trying it twice: both harnesses
crashed with `Parameter "data.tree" is null` until their tests were
adjusted to stop just short of triggering the transition). This is a
limitation of the test harness's architecture, not evidence of a bug in
either transition — `change_scene_to_file` is a standard, heavily-used
Godot API, and in real play `Main.tscn`/`Chapter2.tscn` genuinely are
`current_scene`, so it should work — but neither wire has actually been
run, only reasoned about. If a chapter doesn't advance after the previous
one's summary line, this is the first place to look. (Chapter III doesn't
have this problem in the other direction — it has no transition onward,
since Chapter IV doesn't exist yet.)

Neither check confirms the gameplay *feels* right (movement responsiveness,
dialogue pacing against the voiced lines, whether the puzzles are fun to
solve, whether picking a wrong donation/ticket enough times gets tedious,
whether Voss's 75-second patrol cycle makes the stealth beat feel tense or
just slow) — that needs a real playthrough in the editor. Only Chapter I
has had one so far.

## Running it

1. Open Godot 4, choose "Import", and select this folder's `project.godot`.
2. Press F5 (or the Play button). `scenes/Main.tscn` is the entry scene —
   Chapter I leads into Chapter II automatically once its summary line is
   dismissed.

## Controls

- **WASD / Arrow keys** — move
- **E** — interact with whatever's nearest (glows amber when in range... once
  we add a highlight; for now, just walk up and press E)
- **Space / Enter** — advance dialogue lines
- Click — used inside the deduction board, ticket board, and manifest board
  UIs to select slots/tickets/donations

## What's implemented

- Procedural placeholder art (no image assets): every character and prop is
  drawn in code as a flat noir silhouette matching the pitch dossier's
  palette (`#14161c` ground, `#d98a3d` amber accent).
- A reusable interact system (`Player.gd`'s `reach` Area2D + anything with an
  `interact()` method).
- A real dialogue system (`DialogueBox.gd`) supporting linear lines,
  branching choices, and an optional voiced line per entry.
- `GameState.gd` (autoload): collected evidence, per-NPC trust, cash
  (starts at $400), and a generic `apply_action(npc_id, "pay"|"lean"|"work")`
  that applies the Ledger deltas from the puzzle-math spec doc.
- **Chapter I**: the deduction board (`DeductionBoard.gd`) — 3 required
  slots, 2 red herrings that reject with an explanation instead of a hard
  fail. Full VO: Dana is **Charmion** (`lUCNYQh2kqW2wiie85Qk`), Reyes is
  **Declan Sage** (`kqVT88a5QfII1HNAEPTJ`). Clips in `vo/chapter1/`,
  matching the line IDs in `vo/chapter1_vo_pack.md`. The flat placeholder
  ground/container rectangles have been replaced with a real rendered
  background (`art/backgrounds/pier9_ch1_background_pass01.png`, from the
  Blender graybox pass) — see "Chapter I background integration" below.
- **Chapter II**: three independent, any-order encounters in one scene
  (`Chapter2.gd`):
  - **Sal** — `TicketBoard.gd`, the mod-7 digit-sum cipher from the spec
    doc (4 tickets, 1 correct, the "near-miss" trap included).
  - **Priya** — `ManifestBoard.gd`, timestamp matching against flagged
    delay events plus a "shared account" finding (3 required flags).
  - **Costigan** — a dialogue state machine (`hostile → guarded →
    listening → open`) requiring grief → case → offer in that order; one
    soft miss from `hostile` is forgiven, a second hard-ends the scene.
  - Sal and Priya both end in a Pay / Lean / Work choice that calls
    `GameState.apply_action(...)`. Full VO for all three branches of both,
    voiced as: Sal = **Grandpa Spuds Oxley**, Priya = **Emily**,
    Costigan = **Adam**, Dana = Charmion throughout. Clips in
    `vo/chapter2/`, named by speaker prefix (`SA-`/`DS-` for Sal's scene,
    `PR-`/`DP-` for Priya's, `CO-`/`DC-` for Costigan's).
- **Chapter III**: `PatrolNPC.gd` — a deterministic patrol state machine
  (counting-room dwell 25s → transit 10s → crew-deck dwell 30s → transit
  10s, looping) with a sight radius that's only "live" outside the
  crew-deck dwell (the one safe window in the cycle). `AuditBoard.gd` — the
  12-transaction skim-audit puzzle from the spec doc: a ghost vendor
  (null), a cross-account bleed (an account ID that calls back to Priya's
  Chapter II finding), and a 3-wire structuring pattern, plus a distractor
  and an exact-set-match win condition that fails on over-flagging too.
  The safe's code depends on `sal_gave_code` from Chapter II (set via the
  Pay/Work branches, not Lean). Getting spotted runs the
  trust/heat-weighted cover formula from the spec doc; a second spot
  always forces retreat regardless. Full VO: Voss is **Alexandra**
  (`3dzJXoCYueSQiptQ6euE`), Dana is Charmion throughout. Clips in
  `vo/chapter3/`.
- Any dialogue line dict can carry an `"audio": "res://..."` key and
  `DialogueBox.gd` will play it automatically.

## What's not implemented yet

- Any of Chapters IV–V (including their VO). Mick and Calloway are cast
  (see `vo/elevenlabs_voice_shortlist.md`) but have no lines generated
  yet — they don't appear until Chapter IV/V.
- Sprite animation (the player is a static silhouette; movement has no walk
  cycle).
- Save/load.
- Sound effects / music (VO only, no SFX or score yet).
- Visual "in range" highlighting on interactables (currently invisible —
  you'll know you're close enough when E does something).
- The Chapter I → Chapter II and Chapter II → Chapter III transitions are
  wired but not automated-test covered — see "Known gap" above.
- Chapter III's environment is still flat placeholder `Prop` rectangles,
  unlike Chapter I's real rendered background — no Blender pass exists for
  the boat yet.

## Chapter I background integration

`scripts/Main.gd` now loads `art/backgrounds/pier9_ch1_background_pass01.png`
(2560x1440, from `night-audit-blender-graybox`'s environment pass) as a
`Sprite2D` background instead of the old flat `Prop` rectangles. Player
spawn, Reyes, and all 5 clue positions were moved to match the coordinates
in that project's `GODOT_INTEGRATION_HANDOFF.md`, and `Player.gd` gained a
`movement_bounds: Rect2` field (set by whichever scene wants to clamp
movement — Chapter I sets it, Chapter II doesn't) so Dana can't wander off
the plate.

**One deviation from the handoff, worth knowing about**: the handoff's
suggested movement-bounds rect — `Rect2((250,480), (1750,560))` — doesn't
actually contain the spatter clue (y=410) or receipt clue (y=370); both
sit above its top edge, which would have made 2 of the 3 required clues
unreachable. The rect was widened to `Rect2((300,320), (1650,720))`, which
covers every marker in the handoff (Dana, Reyes, all clues) with margin
for the player's 40px interact radius. Retune this — along with the
red-herring clue positions, which the handoff didn't specify and were
placed by guess — once someone is actually looking at Dana standing on
the plate.

**Verification status**: confirmed the texture imports and loads without
error, and the coordinate math is consistent (checked by hand against the
handoff's numbers). Could **not** confirm how it actually looks —
`--headless` on this machine uses Godot's dummy rendering driver, which
doesn't rasterize anything (`get_viewport().get_texture()` returns null),
so there's no way to screenshot-verify from this environment. This one
genuinely needs a human to open the editor and look at it.

## Known rough edges

- UI panel sizing across `DialogueBox.gd` / `DeductionBoard.gd` /
  `TicketBoard.gd` / `ManifestBoard.gd` is computed by hand, not tested
  against actual rendered font metrics — watch for minor overflow/clipping
  on first look.
- `project.godot`'s `config/features` version string — if your Godot build
  is not 4.7, it should still open and auto-upgrade, but say so if it
  doesn't.
- Chapter II's world is one big scene with three locations spread far
  apart (pawnshop, picket line, dockmaster shack); walking between them
  takes a while at the current player speed. Worth revisiting if it drags
  in an actual playthrough.
