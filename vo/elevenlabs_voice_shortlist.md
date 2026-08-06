# Night Audit — Final ElevenLabs voice cast

Locked 2026-08-05. All eight roles cast and confirmed by ear against real
script lines (not just preview clips). Match by **Voice ID**, not name —
ElevenLabs display names can drift (see note at the bottom).

| Character | Voice | Voice ID | Note |
|---|---|---|---|
| **Dana Kowalczyk** | Charmion | `lUCNYQh2kqW2wiie85Qk` | "Soft and husky," middle-aged British. Accent doesn't match her American setting, but the texture won out over Tiffany (the American "gritty/calm" pick) on actual playback. |
| **Mick Kowalczyk** | Bagger (custom clone) | `o1XRlPmfuPfrsejkzMlW` | The user's own trained ElevenLabs voice. Beat the generic "Alex" candidate. |
| **Det. Anwar Reyes** | Declan Sage | `kqVT88a5QfII1HNAEPTJ` | "Wise, Deliberate, Captivating" — beat David Castlemore (newsreader alt). |
| **Sal Mercer** | Grandpa Spuds Oxley | `NOpBlnGInO9m6vDvFkFC` | Confirmed good on a real line ("Dana Kowalczyk. Christ...") — the "nervous/reedy" quality read fine in practice despite being unconfirmed from metadata alone. |
| **Priya Natarajan** | Emily | `VUGQSU6BSEjkbudnJbOj` | "Confident, professional, clarity and good diction." |
| **Frank Costigan** | Adam | `IRHApOXLvnW57QJPQH2P` | "Brooding, Dark, Tough American" — beat James ("Husky Storyteller" alt). |
| **Elena Voss** | Alexandra | `3dzJXoCYueSQiptQ6euE` | Recast after Danielle read too soft/warm. "Steady, clear, capable of speaking to the C-Suite," neutral North American — landed as the right cool/composed register. |
| **Renata Calloway** | Jessica Anne Bogart | `lxYfHSkYm1EzQzGhdbfc` | "Eloquent Villain" — strongest match found from the start, confirmed. |

## Generation notes for future lines

- Voice IDs above are all confirmed working against the real `text_to_speech`
  API — safe to reuse directly.
- **Avoid ElevenLabs' "narrative persona" category pages** (Detective,
  Antagonist, Podcast Host, and similar — anything with a paragraph-long
  character bio rather than a one-line tag). Their "Open in App" links are
  `voice-lab/share/...` tokens that do **not** resolve as real API voice
  IDs — 4 for 4 dead on this project (Sophisticated Investigator, Enigmatic
  Consultant, Warm Conversationalist, The Sophisticated Mastermind). Stick to
  category pages that expose a real `?voiceId=` query param link (Husky,
  Calm, Corporate, Adult Female, etc. all worked), or json2video's voice
  index, which mirrors real IDs.
- Only Chapter I has a finished script with line IDs. The other six
  characters were cast against improvised one-off test lines, not final
  script text — regenerate their actual lines once Chapters II–V are
  written, using these same Voice IDs.
