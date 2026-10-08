-- Load MyAddon with the WoW stub, optionally with a SavedVariables
-- file, log in, run a script, log out and write the SavedVariables back.
--   lua5.1 tools/harness/run.lua <addonDir> <svIn|-> <svOut|-> [script.lua]
-- The script runs after login with globals STUB (the stub) and NS (the
-- core addon's root table; point it at yours below).
--
-- Several addons: the core TOC is <addonDir>/MyAddon.toc
-- or <addonDir>/MyAddon/MyAddon.toc. Every other addon is a
-- folder MyAddon_<Name> with a TOC of the same name, found either
-- next to the core folder or inside <addonDir>. As in the game:
--   * addons without "## LoadOnDemand: 1" load at login, dependencies first
--   * LoadOnDemand addons load when C_AddOns.LoadAddOn(name) is called
--   * each addon gets its own private table ("..." in its files) and an
--     ADDON_LOADED event after its files ran
--   * every global named in a loaded addon's "## SavedVariables:" line is
--     written to <svOut> at logout; a LoadOnDemand addon's saved variables
--     appear when it loads, and are written back unchanged if it never did
-- MYADDON_EXTRA_ADDONS (comma separated folders) adds addons of any name.
-- <svIn> may name several files separated by commas (one per SavedVariables
-- file in the game); they are all loaded before any addon.
local here = arg[0]:match("^(.*)/[^/]*$") or "."
local addonDir, svIn, svOut, script = arg[1], arg[2], arg[3], arg[4]

local STUB = dofile(here .. "/wow_stub.lua")
STUB.SetTime(tonumber(os.getenv("MYADDON_TIME") or "") or 1790000000)
_G.STUB = STUB


if svIn and svIn ~= "-" then
	for path in svIn:gmatch("[^,]+") do dofile(path) end
end

------------------------------------------------------------------------
-- Find the addons
------------------------------------------------------------------------
local CORE = "MyAddon"

local function exists(path)
	local fh = io.open(path, "rb")
	if fh then fh:close() return true end
	return false
end

-- name -> { name, dir, toc, lod, deps = {}, sv = {}, meta = {}, files = {} }
local addons, order = {}, {}

local function readToc(name, dir, toc)
	local a = { name = name, dir = dir, toc = toc, lod = false, deps = {}, sv = {}, meta = {}, files = {} }
	for line in io.lines(toc) do
		line = line:gsub("\r", "")
		local key, value = line:match("^##%s*([%w%-_]+)%s*:%s*(.-)%s*$")
		if key then
			a.meta[key] = value
			if key == "LoadOnDemand" then
				a.lod = value == "1"
			elseif key == "Dependencies" or key == "RequiredDeps" or key:match("^Dep") then
				for d in value:gmatch("[^,%s]+") do a.deps[#a.deps + 1] = d end
			elseif key == "SavedVariables" then
				for v in value:gmatch("[^,%s]+") do a.sv[#a.sv + 1] = v end
			end
		elseif not line:match("^#") and line:match("%S") then
			-- "file.lua [AllowLoadGameType standard]": the file name only
			local file = line:match("^%s*(.-)%s*%[") or line:match("^%s*(.-)%s*$")
			if file:match("%.lua$") then a.files[#a.files + 1] = (file:gsub("\\", "/")) end
		end
	end
	addons[name] = a
	order[#order + 1] = name
	return a
end

local coreDir
if exists(addonDir .. "/" .. CORE .. ".toc") then
	coreDir = addonDir
elseif exists(addonDir .. "/" .. CORE .. "/" .. CORE .. ".toc") then
	coreDir = addonDir .. "/" .. CORE
else
	error("no " .. CORE .. ".toc in " .. addonDir)
end
readToc(CORE, coreDir, coreDir .. "/" .. CORE .. ".toc")

-- child addons: MyAddon_<Name>/MyAddon_<Name>.toc
local seen = {}
local bases = { addonDir }
if coreDir ~= addonDir then bases[2] = coreDir .. "/.." end
for _, base in ipairs(bases) do
	local ls = io.popen('ls -d "' .. base .. '"/' .. CORE .. '_*/ 2>/dev/null')
	if ls then
		for dir in ls:lines() do
			dir = dir:gsub("/$", "")
			local name = dir:match("([^/]+)$")
			if name and not seen[name] and exists(dir .. "/" .. name .. ".toc") then
				seen[name] = true
				readToc(name, dir, dir .. "/" .. name .. ".toc")
			end
		end
		ls:close()
	end
end

-- other addons (MYADDON_EXTRA_ADDONS="dir,dir"): e.g. a UI suite stand-in
-- and a front-end addon kept in its own repository
for dir in (os.getenv("MYADDON_EXTRA_ADDONS") or ""):gmatch("[^,]+") do
	dir = dir:gsub("/$", "")
	local name = dir:match("([^/]+)$")
	if name and not addons[name] and exists(dir .. "/" .. name .. ".toc") then
		readToc(name, dir, dir .. "/" .. name .. ".toc")
	end
end

------------------------------------------------------------------------
-- Load them like the game does
------------------------------------------------------------------------
local loaded, loading = {}, {}
local privates = {}
local coreAddon

-- A LoadOnDemand addon's saved variables only exist once it loads (they are
-- read after its files run, before ADDON_LOADED); while it is not loaded,
-- the game leaves its file alone, so its old values are written back.
local stash = {}
for _, name in ipairs(order) do
	if addons[name].lod then
		for _, var in ipairs(addons[name].sv) do stash[var] = _G[var]; _G[var] = nil end
	end
end

local function load(name)
	local a = addons[name]
	if not a then return false, "MISSING" end
	if loaded[name] then return true end
	if loading[name] then error("dependency loop at " .. name) end
	loading[name] = true
	for _, d in ipairs(a.deps) do
		local ok = load(d)
		if not ok then loading[name] = nil return false, "DEP_MISSING" end
	end
	local private = {}
	privates[name] = private
	if name == CORE then coreAddon = private end
	for _, file in ipairs(a.files) do
		local f = assert(loadfile(a.dir .. "/" .. file))
		f(name, private)
	end
	for _, var in ipairs(a.sv) do
		if stash[var] ~= nil then _G[var] = stash[var]; stash[var] = nil end
	end
	loading[name] = nil
	loaded[name] = true
	STUB.Fire("ADDON_LOADED", name)
	return true
end

local function isLoaded(name) return loaded[name] == true end
C_AddOns.IsAddOnLoaded = isLoaded
C_AddOns.LoadAddOn = function(name)
	local ok, why = load(name)
	if ok then return true end
	return false, why
end
C_AddOns.EnableAddOn = function() end
C_AddOns.GetAddOnMetadata = function(name, field)
	local a = addons[name]
	if a and a.meta[field] then return a.meta[field] end
	return "test"
end
IsAddOnLoaded = isLoaded
LoadAddOn = C_AddOns.LoadAddOn

-- login: every addon that is not LoadOnDemand, dependencies first
for _, name in ipairs(order) do
	if not addons[name].lod then
		local ok, why = load(name)
		if not ok then print("ERROR " .. name .. " not loaded: " .. tostring(why)) end
	end
end

local NS = coreAddon -- the core addon's private table; use your root table if it differs
_G.NS = NS

STUB.Fire("PLAYER_LOGIN")
-- MYADDON_RELOAD=1: a /reload instead of a login
if os.getenv("MYADDON_RELOAD") == "1" then
	STUB.Fire("PLAYER_ENTERING_WORLD", false, true)
else
	STUB.Fire("PLAYER_ENTERING_WORLD", true, false)
end
STUB.Fire("IGNORELIST_UPDATE")
STUB.RunTimers()

if script then dofile(script) end

STUB.Fire("PLAYER_LOGOUT")
if svOut and svOut ~= "-" then
	-- every SavedVariables global of every addon that was loaded
	local fh = assert(io.open(svOut, "w"))
	for _, name in ipairs(order) do
		for _, var in ipairs(addons[name].sv) do
			local v = loaded[name] and _G[var] or stash[var]
			if v ~= nil then fh:write(var, " = ", STUB.serialize(v), "\n") end
		end
	end
	fh:close()
end
