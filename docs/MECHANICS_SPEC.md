# Mechanics Spec — reverse-engineered from the real implementation

The README references "the puzzle-math spec doc" and "the pitch dossier" repeatedly
as the authoritative source for this game's rules, but neither exists anywhere in
this repo. If they only ever existed in chat history or on the local machine, that's
the exact gap this project's own `docs/ANIMATION_BIBLE.md` warns against elsewhere:
a rule that isn't written down isn't durable.

This document does not attempt to reconstruct whatever the original design intent
was — I never saw it. Instead it documents **what is actually built and running**,
extracted directly from the current scripts, verified by reading the real logic
(not guessed, not remembered). Where a chapter isn't implemented yet, it isn't
covered here. Treat this as ground truth for the current build; if a future design
pass wants different numbers, edit here first, matching the discipline already
established for `ANIMATION_BIBLE.md`.

## GameState (`scripts/GameState.gd`) — the shared ledger

Autoload, holds everything that persists across a chapter:

- `cash`: starts at **$400**.
- `heat`: starts at **0**, only ever incremented (Chapter III's wrong safe code, see
  below). Nothing currently reads `heat` except that one increment and the Chapter
  III summary line — it's tracked but not yet a gate on anything.
- `ledger.trust`: per-NPC integer, starts at 0 for `reyes`, `sal`, `priya`,
  `costigan`.
- `ledger.flags`: a generic string-keyed bag (`set_flag`/`get_flag`) — this is how
  every chapter tracks its own state machine (`sal_done`, `audit_solved`,
  `times_spotted`, etc.), not a fixed schema.
- `collected_clues`: `{clue_id: {tag, label}}`.

### The Pay / Lean / Work action economy

Every NPC choice that calls `apply_action(npc_id, action)` applies the same fixed
deltas, regardless of which NPC or chapter:

| Action | Trust | Cash |
|---|---|---|
| `pay` | +1 | −75 |
| `lean` | −3 | 0 |
| `work` | +2 | 0 |

`work` is strictly better than `pay` on trust and costs nothing — the two are
differentiated narratively (what Dana actually says), not mechanically. Worth
knowing if a future balance pass wants `pay` to matter more: right now the only
reason to ever pick `pay` is the dialogue flavor, not the ledger math.

## Chapter I — the deduction board

Three real clues, two irrelevant ones (`CLUE_DEFS` in `scripts/Main.gd`):

| Clue | Tag | Position |
|---|---|---|
| Arterial spatter, low, wrong wall | `cause_location_mismatch` | (520, 410) |
| Receipt, soaked but legible | `timeline_marker` | (690, 370) |
| Rope burn on the tie-down | `staging_evidence` | (425, 515) |
| Discarded coffee cup | `irrelevant` | (1100, 500) |
| Smudged footprint | `irrelevant` | (550, 700) |

The board (`DeductionBoardUI`) has exactly the three real tags as slots. Assigning
an `irrelevant`-tagged clue to any slot never matches (`irrelevant` isn't a slot
tag) — the two red herrings are unwinnable by design, not a trap with a "wrong"
outcome; they just never fit, and the board says so ("Doesn't fit...") rather than
hard-failing. There's no penalty for trying them.

## Chapter II — three independent encounters

### Sal — the ticket cipher (`scripts/TicketBoard.gd`)

Rule: `digit_sum(ticket_number) % 7 == day_num % 7`.

| Ticket | Digit sum | mod 7 | Day | mod 7 | Match |
|---|---|---|---|---|---|
| 3312 | 9 | 2 | Mon 12 | 5 | no |
| 4471 | 16 | 2 | Tue 13 | 6 | no |
| **5206** | **13** | **6** | **Tue 13** | **6** | **yes** |
| 1180 | 10 | 3 | Wed 14 | 0 | no |

4471 is the near-miss trap the README mentions — same day (Tue 13) as the correct
ticket, wrong number, and its digit-sum mod 7 (2) doesn't match day-mod-7 (6)
either. Solving unlocks `sal_ticket_solved`, then a Pay/Lean/Work choice
(`GameState.apply_action("sal", ...)`) that also sets `sal_gave_code` — **true**
for `pay` or `work`, **false** for `lean`. That flag is Chapter III's safe code
gate (see below) — it's the one piece of Chapter II state that reaches all the way
into Chapter III's mechanics, not just its dialogue.

### Priya — the manifest (`scripts/ManifestBoard.gd`)

Three delay events (D1 Mon 09:00 flagged, D2 Tue 14:00 **not** flagged, D3 Thu
03:00 flagged) against four donations. Win condition: flag `G1`, `G3`, and
`account`; leave `G2` and `G4` unflagged. G1 and G3 sit within 6h of a *flagged*
delay; G2 sits close to D2 but D2 isn't flagged, so it doesn't count even though
the timing looks similar; G4 has no nearby delay at all. This is an exact-match
check (`flagged["G1"] and flagged["G3"] and flagged["account"] and not
flagged["G2"] and not flagged["G4"]`) — no partial credit, and the UI only ever
gives a hint on a wrong *positive* flag (G2/G4), not on leaving G1/G3/account
unflagged.

### Costigan — the trust state machine (`scripts/Chapter2.gd`)

States: `hostile → guarded → listening → open`, driven by three topic choices
(`grief`, `case`, `offer`) that only advance in that exact order:

```
hostile:   grief -> guarded   |  case -> hostile (no-op)  |  offer -> hostile (no-op)
guarded:   case -> listening  |  grief -> guarded (no-op) |  offer -> guarded (no-op)
listening: offer -> open      |  grief -> listening (no-op) | case -> listening (no-op)
```

**Only the `hostile` state punishes a wrong choice.** A no-op pick while hostile
increments `costigan_hostile_misses`; the first miss is forgiven ("...Not what I
asked."), the second ends the conversation permanently
(`costigan_done = true`, boat lead never granted). Wrong picks at `guarded` or
`listening` just don't advance — no miss counter, no hard fail, unlimited
attempts. This is an inconsistency worth a deliberate call: either the
forgiving-once rule should apply at every state, or the asymmetry (only the first
gate is punishing) is intentional because it's the "test the player is paying
attention" gate and the rest is meant to be more forgiving. Right now it reads as
unintentional rather than designed.

Reaching `open` sets `costigan_boat_lead` — Chapter III's cover-strength check
reads `ledger.trust["costigan"] >= 1`, not this flag directly, so **trust from
Costigan's `apply_action` calls is actually what Chapter III checks, not whether
his dialogue tree reached `open`.** Worth confirming that's intended — a player
could in principle reach `open` narratively without Costigan's trust actually
being ≥1 depending on how/whether `apply_action("costigan", ...)` gets called
elsewhere (it isn't called anywhere in the Costigan scene as currently read — his
trust never moves from 0 via this scene at all, meaning **`cover_strength` is
always 0 unless something outside this scene raises Costigan's trust**). This is
worth verifying against actual playtest behavior — as read, no path in Chapter II
raises `trust["costigan"]` above 0, which would make Chapter III's cover check
always fail on that half of the formula.

## Chapter III — the boat

### Voss's patrol (`scripts/PatrolNPC.gd`)

Deterministic loop, 75s total: counting-room dwell **25s** → transit **10s** →
crew-deck dwell **30s** → transit **10s** → repeat. Detection (`is_detection_active()`)
is live everywhere **except** the crew-deck dwell — so 45 of every 75 seconds (60%
of the cycle) is a live detection window, not 40% as "one safe window in the
cycle" might suggest at a glance. Sight radius is a 90px circle around Voss;
spotted fires when the player enters it during an active window.

### The cover formula, on being spotted

```
attempt = (1 if trust["costigan"] >= 1 else 0) + (1 if heat == 0 else 0)
survive if attempt >= 1
```

Per the Costigan section above, `trust["costigan"]` most likely never leaves 0 in
the current build — meaning **in practice, surviving a first spot currently comes
down entirely to `heat == 0`**, i.e., whether the player got the safe code wrong
in this same chapter (heat increments *after* a wrong code) or spotted a second
time elsewhere. The "Costigan vouches for you" half of the design intent (implied
by his closing line, "you don't go at it alone") doesn't appear to be reachable
as coded. **A second spot always forces retreat**, regardless of `attempt` —
checked before the cover formula runs at all.

### The safe (`scripts/Chapter3.gd`)

Gated on `sal_gave_code` (set in Chapter II, see above). Correct code: no cost.
Wrong code: `heat += 1`, but the safe still opens either way — there's no fail
state on the safe itself, only a heat cost for guessing wrong, which then feeds
back into the cover formula for the rest of the chapter.

### The skim-audit (`scripts/AuditBoard.gd`)

12 transactions, exact-set match required (`REQUIRED = ["T3", "T5", "T6", "T7",
"T8"]`), over-flagging explicitly rejected with a specific message, under-flagging
just doesn't resolve yet (no premature "wrong" verdict):

- **T3** — ghost vendor: `catering, $1120, vendor: ""`. No name on file.
- **T5** — cross-account bleed: `maintenance, $900, Bay Marine Repair, account:
  X-4471` — same vendor and category as T4 (`$640, ACC-01`), different account,
  and `X-4471` is the exact account ID Priya's manifest board flags as the shared
  account in Chapter II. This is the one required transaction that's a genuine
  cross-chapter callback, not just internally consistent within Chapter III.
- **T6/T7/T8** — three identical `wire, $9850, Internal Transfer, ACC-03`
  transactions — a structuring pattern (splitting into repeated same-size wires).
- T11 (`wire, $4200, ACC-03`) is the distractor: same category/vendor/account
  pattern as the structuring set but a different amount and not part of the
  required flag set — the trap is "it looks like it belongs with T6-T8," not that
  it's disguised as clean.

## What's genuinely unverified

Everything above is read directly from the scripts; none of it is guessed. Two
things flagged inline above are worth a deliberate decision rather than being left
as accidental behavior:

1. Costigan's trust apparently never moves in the current Chapter II scene, which
   would make half of Chapter III's cover formula permanently inert.
2. The hostile-only forgiveness asymmetry in Costigan's state machine.

Neither is a crash or a test failure — both are the kind of thing that only shows
up in an actual playthrough, which the README already notes hasn't happened past
Chapter I.
