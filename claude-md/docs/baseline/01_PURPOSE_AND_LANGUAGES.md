# Purpose and languages

## What a WoW addon is, and its limits
An addon is Lua code plus TOC metadata that the World of Warcraft client loads from `Interface/AddOns/<Folder>/`. It runs inside the client's sandbox:
- It can only change what the user sees and does on their own client (frames, chat filtering, tooltips, keybinds). It cannot affect other players' screens.
- It cannot write files, open sockets or call a server. **SavedVariables are the only storage**, written by the client at logout and /reload.
- Sharing between users happens only through what ships in the addon (data lists), Import/Export strings the user copies, or in-game addon messages.
- Protected actions are blocked in combat; code must avoid taint (never touch secure frames or call protected functions from insecure paths). Addon code is always tainted (02 J).
- On Retail 12.x many combat, identity and chat values reach addons as **secret values** that can be shown but not compared or counted, and the combat log is closed to addons (02 J7, J8).
- Memory and CPU are shared with the game and every other addon, so cost when idle matters more than raw speed.

The author's addons favour **performance and memory first**, then code quality, then features.

## Languages and files
| What | Used for |
| --- | --- |
| **Lua 5.1** (WoW dialect, WoW API only, no libraries) | All addon code |
| **TOC** files | Metadata: Interface numbers, Title, Notes, Version, SavedVariables, dependencies, LoadOnDemand, file order |
| XML (rare) | Bindings.xml for keybinds; frames are built in Lua instead |
| **POSIX sh** and **lua5.1** | Tooling: rules checks, the offline harness, zip builds |
| **GitHub Actions YAML** | Rules CI and the release workflow |
| Markdown | Plans, analysis, decisions, status and handover documents |
| readme.txt / history.txt | Shipped in the zip; ASCII only |

## Client flavours
- Support several clients with **three TOCs per addon folder**: a base TOC listing every interface (`## Interface: <retail>, <classic>`), plus `_Mainline` (Retail) and the classic flavour suffix (for example `_Camelot`). One combined TOC alone has broken a classic client before.
- Look up interface numbers and API availability before each client patch: in game with `/dump select(4, GetBuildInfo())`, on the Warcraft Wiki "Public client builds" page, or on wago.tools. The number is `major x 10000 + minor x 100 + patch` (12.1.0 = 120100, Forever 1.60.1 = 16001). Snapshot and suffix table: reference/wow-api/01.
- The client picks the most specific TOC: game type suffix (`_Standard`, `_Camelot`, `_Mists`, `_Vanilla`), then family suffix (`_Mainline`, `_Classic`), then the base TOC. A new game-type suffix can silently take over from a family TOC (02 B5).
- Guard any API that differs between flavours (`C_AddOns` vs older globals, `SetResizeBounds` vs `SetMinResize`, new Social UI vs FriendsFrame).
