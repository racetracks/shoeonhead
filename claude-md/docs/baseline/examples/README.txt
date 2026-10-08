Real harness tooling from a working addon, with the addon prefix replaced by
MyAddon / MYADDON. Adapt the namespace, environment variables
(MYADDON_REAL_SAVES, MYADDON_EXTRA_ADDONS, MYADDON_TIME) and file lists.
Layout in the addon repo:
  tools/check_style.lua      Lua 5.1 bans, tabs, trailing whitespace (--fix)
  tools/check_layers.lua     no UI calls in core logic files
  tools/harness/run.lua      loads TOCs like the game, SavedVariables in/out
  tools/harness/wow_stub.lua fake WoW API (grow it as the addon grows)
  tools/harness/ui_compare.sh  snapshot every frame on two git refs and diff
The validate_all.sh driver is addon-specific; 06_HARNESS.md describes what
it must do.
  tools/lua_segments.lua     strips strings and comments for check_layers
