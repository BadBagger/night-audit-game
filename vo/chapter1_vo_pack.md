# Night Audit — VO Production Pack: Chapter I

For use with ElevenLabs Voice Design (text-to-voice) + the standard TTS
generation flow. Scoped to Chapter I only, matching the playable Godot
slice in `night-audit-game/`, so generated lines can be dropped straight
into the working prototype.

---

## 1. Voice Design prompts

Full cast included here even though only Dana and Reyes appear in the
Chapter I slice — casting the whole roster now means later chapters don't
need a second pass. Paste the **Voice Design prompt** into ElevenLabs'
text-to-voice generator, audition the 3-4 candidates it returns against
one real line from the script below (not a generic sample), and pick the
one that survives an actual line reading, not just the preview clip.

| Character | Voice Design prompt |
|---|---|
| **Dana Kowalczyk** | American woman, early 40s, low warm alto with a dry, worn edge. Flat affect that cracks only at specific emotional beats. Controlled pacing, no vocal fry. Sounds like someone used to keeping her voice level in rooms that don't want her calm. |
| **Mick Kowalczyk** | American man, late 30s, warm mid-register, casual and a little worn. Affectionate cadence. Sounds like someone used to talking his way through a bad situation without raising his voice. |
| **Det. Anwar Reyes** | American man, mid-40s, even measured baritone, procedural cadence that softens on personal lines. Sounds like a career cop reading you your rights and meaning the kindness underneath it. |
| **Sal Mercer** | American man, 60s, higher reedy tenor, quick nervous pacing that tightens further under pressure. Sounds like someone who talks fast to keep from thinking too hard about what he's saying. |
| **Priya Natarajan** | American woman, 30s, clear resonant alto with strong diction, practiced at projecting to a crowd. Warm but firm. Sounds like the calmest person in a room that's about to not be calm. |
| **Frank Costigan** | American man, 50s, low gravelly baritone, blue-collar cadence, short clipped sentences. Sounds like decades of talking over dock machinery. |
| **Elena Voss** | Woman, 40s, cool controlled mezzo, minimal inflection, unhurried pacing. Sounds calm in a way that reads as more dangerous than shouting would. |
| **Renata Calloway** | American woman, 50s, polished low alto, unhurried boardroom cadence, faint dry amusement under the words. Sounds like she's never once had to raise her voice to get what she wants. |

### Starting generation settings (per character)

ElevenLabs' exact slider ranges shift between UI versions, so treat this
as relative guidance to dial in by ear, not literal numbers:

- **Dana, Mick, Sal, Priya** — lower/mid Stability. These four need
  genuine emotional variance line to line; too-high stability flattens
  Dana's restraint into monotone instead of *controlled*.
- **Reyes, Voss, Calloway** — higher Stability, low Style exaggeration.
  Their whole character is restraint — an over-expressive read undercuts
  Voss and Calloway specifically, where calm is the threat.
- Regenerate any line that comes back sounding "performed" rather than
  "said" — noir dialogue reads worse over-acted than under-acted.

---

## 2. What to voice vs. what stays text-only

Not every line in the script should go through VO. Recommend keeping
these **unvoiced** (on-screen text only), consistent with how most
narrative games split spoken dialogue from descriptive/UI text:

- Bracketed internal narration, e.g. `(You pocket the phone. Reyes
  doesn't look at your hand. That means he saw.)` — this reads as Dana's
  internal narration, not a spoken line. Voicing it as a hushed
  voice-over is a valid alternate choice if you want a noir-narrator
  feel throughout, but decide that as a deliberate style call, not by
  default.
- Control-hint text (`WASD to move`, `Talk to Reyes again`) — pure UI,
  never voice this.
- The auto-generated Ledger summary line at the end of the chapter — it's
  templated/variable text (`Reyes trust %s, phone %s`), not fixed
  dialogue, so it's not a good VO candidate as written.

The line-by-line table below flags each row accordingly.

---

## 3. Chapter I script — ready to paste

Line IDs match reading order in `Main.gd`. "Voice" column = who reads it.

| ID | Voice | Direction | Line |
|---|---|---|---|
| D-001 | Dana | Flat, tired, arriving at a scene she shouldn't be first to. | He's in there. Pier 9. I got here before anyone else did. |
| R-001 | Reyes | Not surprised, a little grim. | You beat us here. Course you did. |
| D-002 | Dana | Guarded, giving him the least she can. | I got a call. |
| R-002 | Reyes | Flat, procedural — he already expects a bad answer. | From who. |
| D-003 | Dana | Clipped, closing the subject. | Filtered voice. Blocked number. |
| R-003 | Reyes | Urgent but quiet — he's covering for her and both know it. | Ninety seconds, Dana. Then you're outside that tape. Look around if you have to. Fast. |
| D-004 | Dana | Clinical, working — this is the deduction-board voice: precise, not emotional. | The blood pattern is low against the far wall. Wrong angle for someone standing here. |
| D-005 | Dana | Same clinical register. | Rain-soaked, but the ink held. It wasn't out here long before the rain started. |
| D-006 | Dana | Same clinical register, first crack of something personal underneath. | A burn mark on the tie-down. Nothing here should have had rope on it. |
| D-007 | Dana | Dismissive, barely worth saying. | Just a cup. Doesn't connect to anything. |
| D-008 | Dana | Dismissive. | Too smeared by the rain to mean anything on its own. |
| R-004 | Reyes | *(conditional — only fires if the player talks to Reyes before finishing evidence)* Tense, watching the clock. | Whatever you're going to find, find it quick. |
| R-005 | Reyes | Quiet respect under the procedure. | You've got that look. Walk me through what you've got. |
| D-009 | Dana | The line lands — first time she says it out loud. Controlled, not triumphant. | He wasn't killed here. He was moved. |
| R-006 | Reyes | Grim agreement, then a warning underneath it. | ...Yeah. That's what I've got too. Don't say it again where anyone else can hear you say it that fast. |
| — | *(unvoiced)* | Narration/UI text — see section 2. | Mick's phone is half under his jacket, screen cracked. Reyes is a few feet away, giving you exactly enough room not to be watching. |
| — | *(unvoiced or optional narrator read)* | Internal narration. | (You pocket the phone. Reyes doesn't look at your hand. That means he saw.) |
| R-007 | Reyes | The one moment he lets real feeling through the procedure. | Twenty-four hours, Dana. After that I have to put your name in a file, and I can't take it back out. |
| — | *(unvoiced or optional narrator read)* | Internal narration. | (You leave it exactly where you found it.) |
| R-008 | Reyes | Genuine, brief warmth before going back to business. | Appreciate that. Twenty-four hours. Go talk to whoever he still talked to. |

---

## 4. Next step once you have audio files

Drop generated clips into `night-audit-game/vo/chapter1/` named by ID
(`D-001.mp3`, `R-001.mp3`, etc.). I can then extend `DialogueBox.gd` to
accept an optional `audio` path per line and play it through an
`AudioStreamPlayer` alongside the text — a small, low-risk change to the
existing dialogue system, not a rebuild.
