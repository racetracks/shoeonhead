-- Minimal World of Warcraft API stub for loading MyAddon in plain
-- Lua 5.1 (tests only, not shipped). Frames are inert objects that remember
-- scripts, events, text, shown state and size.
local stub = {}

local clock = 1790000000			-- server time (seconds), settable
local uptime = 1000
function stub.SetTime(t) clock = t end
function stub.Advance(s) clock = clock + s; uptime = uptime + s end

local frames, eventFrames = {}, {}
local timers = {}

local W = {}
local WMT = { __index = function(t, k)
	local m = W[k]
	if m then return m end
	-- setters and other actions do nothing; anything else is missing
	if type(k) == "string" and (k:match("^Set") or k:match("^Enable") or k:match("^Disable") or
		k:match("^Clear") or k:match("^Lock") or k:match("^Unlock") or k:match("^Start") or
		k:match("^Stop") or k:match("^Play") or k:match("^Raise") or k:match("^Lower") or
		k:match("^Add") or k:match("^Hook") or k:match("^Register") or k:match("^Unregister") or
		k:match("^Insert") or k:match("^Highlight") or k:match("^Lock") or k:match("^Refresh") or
		k:match("^Scroll") or k:match("^Adjust") or k:match("^Toggle")) then
		return W._noop
	end
	return nil
end }
W._noop = function() end

local function new(kind, name, parent)
	local f = setmetatable({ _kind = kind, _name = name, _parent = parent, _shown = true,
		_scripts = {}, _events = {}, _w = 100, _h = 20, _text = "" }, WMT)
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end
stub.new = new

function W:GetName() return self._name end
function W:GetObjectType() return self._kind end
function W:IsObjectType(k) return self._kind == k end
function W:GetParent() return self._parent end
function W:SetParent(p) self._parent = p end
function W:SetScript(k, fn) self._scripts[k] = fn end
function W:GetScript(k) return self._scripts[k] end
function W:HasScript() return true end
function W:HookScript(k, fn)
	local old = self._scripts[k]
	self._scripts[k] = old and function(...) old(...); fn(...) end or fn
end
function W:RegisterEvent(e) self._events[e] = true; eventFrames[self] = true end
function W:UnregisterEvent(e) self._events[e] = nil end
function W:UnregisterAllEvents() self._events = {} end
function W:IsEventRegistered(e) return self._events[e] == true end
function W:RegisterUnitEvent(e) self:RegisterEvent(e) end
function W:IsShown() return self._shown end
function W:IsVisible()
	local f = self
	while f do
		if not f._shown then return false end
		f = f._parent
	end
	return true
end
function W:Show()
	local was = self._shown
	self._shown = true
	if not was and self._scripts.OnShow and self:IsVisible() then self._scripts.OnShow(self) end
end
function W:Hide()
	local was = self._shown
	self._shown = false
	if was and self._scripts.OnHide then self._scripts.OnHide(self) end
end
function W:SetShown(s) if s then self:Show() else self:Hide() end end
function W:GetWidth() return self._w end
function W:GetHeight() return self._h end
function W:GetSize() return self._w, self._h end
function W:SetWidth(w) self._w = w end
function W:SetHeight(h) self._h = h end
function W:SetSize(w, h) self._w = w; self._h = h or w end
function W:GetRect() return 0, 0, self._w, self._h end
function W:GetLeft() return 0 end
function W:GetRight() return self._w end
function W:GetTop() return self._h end
function W:GetBottom() return 0 end
function W:GetCenter() return 0, 0 end
function W:GetScale() return 1 end
function W:GetEffectiveScale() return 1 end
function W:GetNumPoints() return 0 end
function W:SetText(t) self._text = t == nil and "" or tostring(t) end
function W:SetColorTexture(r, g, b, a) self._color = { r, g, b, a } end
function W:GetText() return self._text end
function W:SetFormattedText(fmt, ...) self._text = string.format(fmt, ...) end
function W:GetStringWidth() return #(self._text or "") * 6 end
function W:GetStringHeight() return 12 end
function W:GetNumLines() return 1 end
function W:GetNumber() return tonumber(self._text) or 0 end
function W:SetNumber(n) self._text = tostring(n) end
function W:GetChecked() return self._checked == true end
function W:SetChecked(c) self._checked = c and true or false end
function W:IsEnabled() return self._enabled ~= false end
function W:Enable() self._enabled = true end
function W:Disable() self._enabled = false end
function W:SetEnabled(e) self._enabled = e and true or false end
function W:GetFrameLevel() return 1 end
function W:GetFrameStrata() return "MEDIUM" end
function W:GetID() return self._id or 0 end
function W:SetID(i) self._id = i end
-- a check sets f._focus to give a box the keyboard
function W:HasFocus() return self._focus or false end
function W:Insert(t) self._text = (self._text or "") .. tostring(t or "") end
function W:GetCursorPosition() return 0 end
function W:GetVerticalScroll() return self._vscroll or 0 end
function W:SetVerticalScroll(v)
	self._vscroll = v
	local fn = self._scripts.OnVerticalScroll
	if fn then fn(self, v) end
end
function W:GetVerticalScrollRange() return 0 end
function W:GetMinMaxValues() return 0, 100 end
function W:GetValue() return self._value or 0 end
function W:SetValue(v) self._value = v end
function W:GetMaxLetters() return 255 end
function W:SetAlpha(a) self._alpha = a end
function W:GetAlpha() return self._alpha or 1 end
function W:GetTextColor() return 1, 1, 1, 1 end
function W:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
function W:GetJustifyH() return "LEFT" end
-- only text regions justify: on a Button or Frame the game has no such method
local JUSTIFIES = { FontString = true, EditBox = true, SimpleHTML = true, MessageFrame = true, ScrollingMessageFrame = true }
local function justify(self, name)
	if not JUSTIFIES[self._kind] then error(("attempt to call method '%s' (a nil value) on a %s"):format(name, tostring(self._kind)), 3) end
end
function W:SetJustifyH() justify(self, "SetJustifyH") end
function W:SetJustifyV() justify(self, "SetJustifyV") end
function W:GetChildren() return end
function W:GetRegions() return end
function W:GetNumChildren() return 0 end
function W:SetHyperlinksEnabled(on) self._links = on and true or false end
function W:GetHyperlinksEnabled() return self._links or false end
-- a check sets f._mouseOver to put the mouse over a frame
function W:IsMouseOver() return self._mouseOver or false end
function W:IsDragging() return false end
function W:GetTexture() return nil end
function W:GetAtlas() return nil end
function W:IsProtected() return false end
function W:IsForbidden() return false end
function W:GetDebugName() return self._name or "?" end
function W:GetHighlightTexture() return self._hl or new("Texture", nil, self) end
function W:GetNormalTexture() return new("Texture", nil, self) end
function W:GetPushedTexture() return new("Texture", nil, self) end
function W:GetDisabledTexture() return new("Texture", nil, self) end
function W:GetCheckedTexture() return new("Texture", nil, self) end
function W:GetFontString()
	if not self._fs then self._fs = new("FontString", nil, self) end
	return self._fs
end
function W:GetScrollChild() return self._child end
function W:SetScrollChild(c) self._child = c end
function W:CreateFontString(name) return new("FontString", name, self) end
function W:CreateTexture(name) return new("Texture", name, self) end
function W:CreateMaskTexture(name) return new("Texture", name, self) end
function W:CreateLine(name) return new("Line", name, self) end
function W:CreateAnimationGroup() return new("AnimationGroup", nil, self) end
function W:CreateAnimation() return new("Animation", nil, self) end
function W:CreateFrame(kind, name) return new(kind, name, self) end

local TEMPLATE_PARTS = {
	PortraitFrameTemplate = { "TitleText", "CloseButton", "Portrait", "PortraitContainer" },
	ButtonFrameTemplate = { "TitleText", "CloseButton", "Portrait", "Inset" },
	InputBoxTemplate = { "Left", "Right", "Middle" },
	UIPanelScrollFrameTemplate = { "ScrollBar" },
	FauxScrollFrameTemplate = { "ScrollBar", "ScrollChildFrame" },
	InputScrollFrameTemplate = { "EditBox", "CharCount", "ScrollBar" },
	PanelTabButtonTemplate = { "Left", "Right", "Middle", "LeftActive", "RightActive", "MiddleActive", "Text" },
	CharacterFrameTabTemplate = { "Left", "Right", "Middle", "LeftActive", "RightActive", "MiddleActive", "Text" },
	CharacterFrameTabButtonTemplate = { "Left", "Right", "Middle", "LeftDisabled", "RightDisabled", "MiddleDisabled", "Text" },
	TabButtonTemplate = { "Left", "Right", "Middle", "Text" },
	UICheckButtonTemplate = { "Text" },
	WhoFrameColumnHeaderTemplate = { "Left", "Right", "Middle" },
	FriendsFrameColumnHeaderTemplate = { "Left", "Right", "Middle" },
}

function CreateFrame(kind, name, parent, template)
	local f = new(kind, name, parent)
	f._template = template
	if template then
		for t in tostring(template):gmatch("[^,%s]+") do
			for _, part in ipairs(TEMPLATE_PARTS[t] or {}) do
				local child = new("Frame", name and (name .. part) or nil, f)
				f[part] = child
				if part == "ScrollBar" then
					child.ScrollUpButton = new("Button", name and (name .. "ScrollBarScrollUpButton") or nil, child)
					child.ScrollDownButton = new("Button", name and (name .. "ScrollBarScrollDownButton") or nil, child)
				end
			end
		end
	end
	if kind == "Button" or kind == "CheckButton" then
		f.Text = f:GetFontString()
		if name then _G[name .. "Text"] = f.Text end
	end
	if f.PortraitContainer then f.PortraitContainer.portrait = new("Texture", nil, f) end
	return f
end

-- events
function stub.Fire(event, ...)
	local list = {}
	for f in pairs(eventFrames) do
		if f._events[event] then list[#list + 1] = f end
	end
	for _, f in ipairs(list) do
		local h = f._scripts.OnEvent
		if h and f._events[event] then h(f, event, ...) end
	end
	return #list
end

-- run every queued C_Timer callback (and the ones they queue), and OnUpdate once
function stub.RunTimers(maxRounds)
	for _ = 1, maxRounds or 20 do
		if #timers == 0 then break end
		local q = timers
		timers = {}
		for _, fn in ipairs(q) do fn() end
	end
end
function stub.RunOnUpdate(n)
	for _ = 1, n or 1 do
		for _, f in ipairs(frames) do
			local h = f._scripts.OnUpdate
			if h and f:IsVisible() then h(f, 0.02) end
		end
	end
end

-- globals ---------------------------------------------------------------
UIParent = new("Frame", "UIParent")
WorldFrame = new("Frame", "WorldFrame")
FriendsFrame = new("Frame", "FriendsFrame")
FriendsFrame._shown = false
GameTooltip = new("GameTooltip", "GameTooltip")
ItemRefTooltip = new("GameTooltip", "ItemRefTooltip")
DEFAULT_CHAT_FRAME = new("ScrollingMessageFrame", "DEFAULT_CHAT_FRAME")
stub.chat = {}
function DEFAULT_CHAT_FRAME:AddMessage(m) stub.chat[#stub.chat + 1] = tostring(m) end
ChatFrame1 = DEFAULT_CHAT_FRAME
NUM_CHAT_WINDOWS = 1
UISpecialFrames = {}
StaticPopupDialogs = {}
SlashCmdList = {}
hash_SlashCmdList = {}
GameFontNormal, GameFontHighlight, GameFontHighlightSmall, GameFontNormalSmall = {}, {}, {}, {}
CANCEL, OKAY, ACCEPT, YES, NO, UNKNOWN, CLOSE = "Cancel", "Okay", "Accept", "Yes", "No", "Unknown", "Close"
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
LE_PARTY_CATEGORY_HOME = 1
Enum = setmetatable({}, { __index = function(t, k) local v = setmetatable({}, { __index = function() return 0 end }); rawset(t, k, v); return v end })

function GetTime() return uptime end
function GetServerTime() return clock end
local osdate = os.date
function date(fmt, t) return osdate(fmt, t or clock) end
function time(t) if t then return os.time(t) end return clock end
function debugprofilestop() return uptime * 1000 end
function GetFramerate() return 60 end
function InCombatLockdown() return false end
function IsEncounterInProgress() return false end
function UnitIsDeadOrGhost() return false end
function UnitAffectingCombat() return false end
function UnitName(u) if u == "player" then return "Tester", nil end return nil end
function UnitFullName(u) if u == "player" then return "Tester", "Realm" end return nil end
function GetUnitName(u) if u == "player" then return "Tester" end return nil end
function UnitGUID() return nil end
function UnitExists() return false end
function UnitIsPlayer() return false end
function UnitIsUnit() return false end
function UnitFactionGroup() return "Alliance", "Alliance" end
function UnitLevel() return 80 end
function UnitClass() return "Mage", "MAGE", 8 end
function UnitRace() return "Human", "Human" end
function GetRealmName() return "Realm" end
function GetNormalizedRealmName() return "Realm" end
function GetLocale() return "enUS" end
function GetBuildInfo() return "12.0.7", "1", "Oct 1 2026", 120007 end
function GetCVar() return "0" end
function GetCVarBool() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function IsInGuild() return false end
function GetNumGroupMembers() return 0 end
function GetChannelList() return end
function GetChannelName() return 0 end
function GetNumDisplayChannels() return 0 end
function IsAddOnLoaded() return false end
function GetAddOnMemoryUsage() return 0 end
function UpdateAddOnMemoryUsage() end
function collectgarbage_stub() end
function GetCursorPosition() return 0, 0 end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function PlaySound() end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function IsModifiedClick() return false end
function geterrorhandler() return function(e) print("ERROR: " .. tostring(e)); error(e, 0) end end
function seterrorhandler() end
function securecall(f, ...) return f(...) end
function hooksecurefunc(a, b, c)
	if type(a) == "table" then
		local old = a[b]
		a[b] = function(...) local r = { old(...) }; c(...); return unpack(r) end
	else
		local old = _G[a]
		_G[a] = function(...) local r = { (old or function() end)(...) }; b(...); return unpack(r) end
	end
end
function issecretvalue() return false end
function canaccessvalue() return true end
function tinsert(t, a, b) if b == nil then table.insert(t, a) else table.insert(t, a, b) end end
tremove = table.remove
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
table.wipe = wipe
strsplit = function(sep, s, n)
	local out, pos = {}, 1
	while true do
		if n and #out == n - 1 then out[#out + 1] = s:sub(pos); break end
		local a, b = s:find(sep, pos, true)
		if not a then out[#out + 1] = s:sub(pos); break end
		out[#out + 1] = s:sub(pos, a - 1)
		pos = b + 1
	end
	return unpack(out)
end
strtrim = function(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end
strlower, strupper, strsub, strlen, strfind, format, gsub, strrep, strbyte, strchar, strmatch, gmatch =
	string.lower, string.upper, string.sub, string.len, string.find, string.format, string.gsub, string.rep, string.byte, string.char, string.match, string.gmatch
string.trim = strtrim
strjoin = function(sep, ...) return table.concat({ ... }, sep) end
floor, ceil, abs, max, min, mod = math.floor, math.ceil, math.abs, math.max, math.min, math.fmod
getn = table.getn
sort = table.sort
bit = { band = function(a, b) return a % (b + 1) end }

C_Timer = {}
function C_Timer.After(_, fn) timers[#timers + 1] = fn end
function C_Timer.NewTimer(_, fn) timers[#timers + 1] = fn; return { Cancel = function() end, IsCancelled = function() return false end } end
function C_Timer.NewTicker(_, fn) return { Cancel = function() end, IsCancelled = function() return true end } end

C_FriendList = {}
local ignores = {}
function C_FriendList.GetNumIgnores() return #ignores end
function C_FriendList.GetIgnoreName(i) return ignores[i] end
function C_FriendList.AddIgnore(n) ignores[#ignores + 1] = n; return true end
function C_FriendList.DelIgnore() end
function C_FriendList.DelIgnoreByIndex() end
function C_FriendList.IsIgnored() return false end
function C_FriendList.SendWho() end
function C_FriendList.SetWhoToUi() end
function C_FriendList.GetNumWhoResults() return 0, 0 end
function C_FriendList.GetWhoInfo() return nil end
C_ChatInfo = { RegisterAddonMessagePrefix = function() return true end, SendAddonMessage = function() end }
C_AddOns = { IsAddOnLoaded = function() return false end, GetAddOnMetadata = function() return "test" end, LoadAddOn = function() end }
C_GuildInfo = {}
C_BattleNet = {}
C_Club = {}
C_ChatBubbles = {}
C_PartyInfo = {}
C_Map = {}
C_Spell = {}
C_Item = {}
C_CVar = { GetCVar = function() return "0" end, GetCVarBool = function() return false end }
C_DateAndTime = {}
C_Texture = {}
C_ClassColor = { GetClassColor = function() return { r = 1, g = 1, b = 1, GenerateHexColor = function() return "ffffffff" end } end }
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1, colorStr = "ffffffff" } end })
LOCALIZED_CLASS_NAMES_MALE = {}
LOCALIZED_CLASS_NAMES_FEMALE = {}
CLASS_ICON_TCOORDS = {}
Menu = { ModifyMenu = function() end }
MenuUtil = { CreateContextMenu = function() end }
ChatFrame_AddMessageEventFilter = function() end
ChatFrame_RemoveMessageEventFilter = function() end
ChatFrameUtil = { AddMessageEventFilter = function() end }
ChatEdit_InsertLink = function() end
ChatFrame_OpenChat = function() end
StaticPopup_Show = function() end
StaticPopup_Hide = function() end
FauxScrollFrame_Update = function() return true end
FauxScrollFrame_GetOffset = function() return 0 end
FauxScrollFrame_OnVerticalScroll = function() end
FauxScrollFrame_SetOffset = function() end
PanelTemplates_SetNumTabs = function() end
PanelTemplates_SetTab = function() end
PanelTemplates_TabResize = function() end
PanelTemplates_SelectTab = function() end
PanelTemplates_DeselectTab = function() end
SetPortraitToTexture = function() end
ButtonFrameTemplate_HidePortrait = function() end
UIDropDownMenu_Initialize = function() end
ToggleDropDownMenu = function() end
UIErrorsFrame = new("Frame", "UIErrorsFrame")
SendChatMessage = function() end
GetAutoCompleteRealms = function() return {} end
RegisterAddonMessagePrefix = function() end
EasyMenu = function() end
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a, GenerateHexColor = function() return "ffffffff" end } end
Settings = { RegisterCanvasLayoutCategory = function() return { GetID = function() return 1 end } end, RegisterAddOnCategory = function() end }
InterfaceOptions_AddCategory = function() end

-- SavedVariables writer (sorted keys, tabs)
local function serialize(v, indent, out, seen)
	local t = type(v)
	if t == "string" then out[#out + 1] = string.format("%q", v)
	elseif t == "number" or t == "boolean" or t == "nil" then out[#out + 1] = tostring(v)
	elseif t == "table" then
		if seen[v] then error("cycle in saved variables") end
		seen[v] = true
		out[#out + 1] = "{\n"
		local keys = {}
		for k in pairs(v) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b)
			if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then return a < b end
			return type(a) < type(b)
		end)
		for _, k in ipairs(keys) do
			local val = v[k]
			if type(val) ~= "function" and type(val) ~= "userdata" then
				out[#out + 1] = indent .. "\t["
				serialize(k, "", out, seen)
				out[#out + 1] = "] = "
				serialize(val, indent .. "\t", out, seen)
				out[#out + 1] = ",\n"
			end
		end
		out[#out + 1] = indent .. "}"
		seen[v] = nil
	end
end
stub.serialize = function(v) local out = {}; serialize(v, "", out, {}); return table.concat(out) end

stub.frames = frames
return stub
