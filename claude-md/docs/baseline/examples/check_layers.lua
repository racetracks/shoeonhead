-- check_layers.lua
-- Rule 6: client front-end code never lives in the core logic files. Run
-- by tools/check_rules.sh from the repo root (Lua 5.1).
--
--   lua5.1 tools/check_layers.lua
--
-- The core files below may keep data, decide, and say "something changed"
-- by firing an event on the core event bus. They may not draw or open anything: no frames other
-- than plain event frames (CreateFrame("Frame")), no tooltips, dialogs,
-- menus, anchors or font strings, and no calls into the window code
-- (the UI kit, widget builders, window refresh and show functions, and
-- the main window frames: list your own names in BANNED below). Strings and comments are not checked.
--
-- List any file allowed on purpose here, with the reason.

local segments = dofile((arg[0]:match("^(.*[/\\])") or "") .. "lua_segments.lua")

local CORE = {
	-- every core logic file, by name (folder-relative)
	"MyAddon.lua", "MYADDON_Events.lua", "MYADDON_Options.lua",
}

-- { Lua pattern, what it is }
local BANNED = {
	{ "CreateFrame%s*%(%s*\"[^\"]*\"%s*,", "a frame with a parent or template (only plain event frames)" },
	{ "CreateFrame%s*%(%s*\"[^\"Ff][^\"]*\"", "a frame other than an event frame" },
	{ "GameTooltip", "a tooltip" },
	{ "StaticPopupDialogs", "a dialog" },
	{ "StaticPopup_Show", "a dialog" },
	{ "MenuUtil", "a menu" },
	{ "UIParent", "a window anchor" },
	{ ":SetPoint%s*%(", "a frame anchor" },
	{ ":CreateFontString%s*%(", "a font string" },
	{ ":CreateTexture%s*%(", "a texture" },
	-- your project's UI entry points (placeholders: replace with your names)
	{ "UIKIT%.", "the UI kit" },
	{ "WIDGETS%.", "the widget builders" },
	{ "Refresh%u%w*%s*%(", "a window refresh (fire an event instead)" },
	{ "Show%u%w*Window%s*%(", "a window (fire an event instead)" },
	{ "_G%[\"MYADDON\"%]", "the main window" },
	{ "_G%.MYADDON%f[^%w_]", "the main window" },
}

-- Core functions that only print to chat or tidy data may still be named
-- Refresh*/Show* (definitions, not calls into the UI).
local ALLOWED_NAMES = {
	-- ["RefreshSomething"] = true,	-- why it is data, not UI
}

local problems = 0

local function checkFile(path)
	local fh = io.open(path, "rb")
	if not fh then
		print(path .. ": missing (update the CORE list in tools/check_layers.lua)")
		problems = problems + 1
		return
	end
	local src = fh:read("*a")
	fh:close()
	local line = 1
	for _, seg in ipairs(segments(src)) do
		if seg.kind == "code" then
			for _, b in ipairs(BANNED) do
				local init = 1
				while true do
					local s, e = seg.text:find(b[1], init)
					if not s then break end
					local word = seg.text:sub(s, e)
					if not ALLOWED_NAMES[word] then
						local at = line + select(2, seg.text:sub(1, s):gsub("\n", ""))
						print(("%s:%d: %s in a core file: %s"):format(path, at, b[2], word))
						problems = problems + 1
					end
					init = e + 1
				end
			end
		end
		line = line + select(2, seg.text:gsub("\n", ""))
	end
end

-- the core files live in the MyAddon folder (3.0 layout)
-- core logic files live in the core or in the on-demand back end
local function where(path)
	for _, dir in ipairs({ "MyAddon/", "MyAddon_Library/" }) do
		local fh = io.open(dir .. path, "rb")
		if fh then fh:close() return dir .. path end
	end
	return "MyAddon/" .. path
end
for _, path in ipairs(CORE) do checkFile(where(path)) end
if problems > 0 then
	print("Core files must not hold UI code (rule 6). Move it to a UI file and fire an event from the core.")
	os.exit(1)
end
