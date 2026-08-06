# Night Audit — Godot vertical slice

A playable slice of Chapters I–II:

- **Chapter I — "The Container"**: top-down movement, one NPC conversation,
  three examinable clues plus two red-herring props, the deduction-board
  puzzle, and the pocket-the-phone / leave-it choice that seeds the Ledger.
- **Chapter II — "Debts Owed"**: three contacts (Sal, Priya, Costigan),
  visitable in any order, each with their own puzzle and (for Sal/Priya) a
  Pay / Lean / Work branch that feeds the Ledger.

## Requirements

Godot 4.x. Verified against Godot 4.7.1, played through by hand and
confirmed working end to end (Chapter I).

Two levels of automated verification exist per chapter:

1. **Load check**: `godot --headless --quit-after 3` — confirms the scene
   builds and every script parses. Caught and fixed one real bug this way:
   `Camera2D.current` doesn't exist in Godot 4 (renamed to `enabled` from
   Godot 3) — the camera setup was silently broken until this was corrected.
2. **Full flow check**: `tools/TestChapter1Driver.gd` and
   `tools/TestChapter2Driver.gd` (run via
   `godot --headless --path . res://tools/TestChapter1.tscn` or
   `TestChapter2.tscn`) drive each chapter's *entire* loop end-to-end
   against the real game logic — not just "does it load." These are
   regression tests: rerun the relevant one after touching `Main.gd`,
   `Chapter2.gd`, `DialogueBox.gd`, `DeductionBoard.gd`, `TicketBoard.gd`,
   `ManifestBoard.gd`, or `GameState.gd`.
   - Chapter I: 15/15 checks pass, including audio-loads-on-a-line, a
     deliberate wrong deduction-board answer, and a repeat-examine.
   - Chapter II: 23/23 checks pass, including audio-loads, a wrong ticket
     on Sal's cipher, a wrong donation flag on Priya's manifest, and
     Costigan's full state machine (one soft miss from `hostile`, then the
     correct grief → case → offer sequence to reach `open`).

**Known gap**: the Chapter I → Chapter II scene transition
(`get_tree().change_scene_to_file`) is *not* covered by either automated
test — both harnesses instantiate their chapter's scene as a plain child
rather than as the engine's real `current_scene`, and calling
`change_scene_to_file` in that context frees the test driver itself
instead of the intended scene (confirmed by trying it: the harness crashed
with `Parameter "data.tree" is null`). This is a limitation of the test
harness's architecture, not evidence of a bug in the transition — Chapter
I's own regression test was adjusted to stop just short of triggering it.
`change_scene_to_file` is a standard, heavily-used Godot API, and in real
play `Main.tscn` genuinely is `current_scene`, so it should work — but
this specific wire has only been reasoned about, not run. If Chapter II
doesn't start after Chapter I's summary line, this is the first place to
look.

Neither check confirms the gameplay *feels* right (movement responsiveness,
dialogue pacing against the voiced lines, whether the puzzles are fun to
solve, whether picking a wrong donation/ticket enough times gets tedious)
— that needs a real playthrough in the editor. Only Chapter I has had one
so far.

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
- Any dialogue line dict can carry an `"audio": "res://..."` key and
  `DialogueBox.gd` will play it automatically.

## What's not implemented yet

- Any of Chapters III–V (including their VO). Mick, Voss, and Calloway are
  cast (see `vo/elevenlabs_voice_shortlist.md`) but have no lines generated
  yet — they don't appear until Chapter III.
- Sprite animation (the player is a static silhouette; movement has no walk
  cycle).
- Save/load.
- Sound effects / music (VO only, no SFX or score yet).
- Visual "in range" highlighting on interactables (currently invisible —
  you'll know you're close enough when E does something).
- The Chapter I → Chapter II transition is wired but not automated-test
  covered — see "Known gap" above.

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
