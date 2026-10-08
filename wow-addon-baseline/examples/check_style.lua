-- check_style.lua
-- Code style checks for MyAddon Lua files (Lua 5.1, run by
-- tools/check_rules.sh). Strings and comments are skipped where a rule is
-- about code only.
--
--   lua5.1 tools/check_style.lua [--fix] <file.lua> ...
--
-- Reports (file:line: reason) and exits 1 when any file has:
--   * a byte above 127 (rule 2, ASCII only)
--   * goto or a ::label:: (rule 1, Lua 5.1 only)
--   * a Lua 5.2+ library call: table.unpack, table.pack, table.move, bit32,
--     utf8, _ENV, rawlen (rule 1)
--   * indentation with spaces (rule 4)
--   * code aligned with a run of spaces mid-line (rule 4)
--   * whitespace at the end of a line
--
-- --fix rewrites the last three in place: alignment runs become tabs that
-- reach the same tab stop (tab width 4), trailing whitespace is removed.
-- Text inside strings and long comments is never changed.

local TAB = 4
local fix = false
local files = {}
for _, a in ipairs(arg) do
	if a == "--fix" then fix = true else files[#files + 1] = a end
end

local NEWER = { "table.unpack", "table.pack", "table.move", "bit32.", "utf8.", "_ENV", "rawlen" }

local problems = 0
local function report(path, line, msg)
	problems = problems + 1
	print(("%s:%d: %s"):format(path, line, msg))
end

-- Visual column after appending text (tabs to the next multiple of TAB).
local function advance(col, text)
	for i = 1, #text do
		if text:sub(i, i) == "\t" then
			col = col + TAB - (col % TAB)
		else
			col = col + 1
		end
	end
	return col
end

-- Tabs that take a cursor at column col to at least column target.
local function tabsTo(col, target)
	local out = {}
	repeat
		out[#out + 1] = "\t"
		col = col + TAB - (col % TAB)
	until col >= target
	return table.concat(out)
end

-- Splits a file into segments: { kind = "code" | "string" | "comment", text }.
local segments = dofile((arg[0]:match("^(.*[/\\])") or "") .. "lua_segments.lua")

local function checkFile(path)
	local fh = assert(io.open(path, "rb"))
	local src = fh:read("*a")
	fh:close()

	-- byte and line checks on the raw text
	local lineNo = 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		lineNo = lineNo + 1
		if line:find("[\128-\255]") then report(path, lineNo, "non-ASCII byte (write it as a \\ddd escape)") end
		if line:find("^\t* ") then report(path, lineNo, "indented with spaces") end
	end

	-- token-aware checks and the fixer
	local segs = segments(src)
	local out = {}
	local line, col, hasText = 1, 0, false
	local function emit(text)
		out[#out + 1] = text
		for i = 1, #text do
			local c = text:sub(i, i)
			if c == "\n" then
				line, col, hasText = line + 1, 0, false
			else
				col = advance(col, c)
				if c ~= " " and c ~= "\t" then hasText = true end
			end
		end
	end
	for si, seg in ipairs(segs) do
		local text = seg.text
		if seg.kind == "code" then
			local function lineAt(s) return line + select(2, text:sub(1, s):gsub("\n", "")) end
			local g = text:find("%f[%w_]goto%f[^%w_]")
			if g then report(path, lineAt(g), "goto is not Lua 5.1") end
			local l = text:find("::[%a_][%w_]*::")
			if l then report(path, lineAt(l), "::label:: is not Lua 5.1") end
			for _, name in ipairs(NEWER) do
				local s = text:find(name, 1, true)
				if s and not (s > 1 and text:sub(s - 1, s - 1):match("[%w_.]")) then
					report(path, lineAt(s), name .. " is Lua 5.2+")
				end
			end
			local pos = 1
			while pos <= #text do
				local s, e = text:find("[ \t]+", pos)
				if not s then
					emit(text:sub(pos))
					break
				end
				emit(text:sub(pos, s - 1))
				local run = text:sub(s, e)
				local nextc = text:sub(e + 1, e + 1)
				if nextc == "" then
					local ns = segs[si + 1]
					nextc = ns and ns.text:sub(1, 1) or "\n"
				end
				if nextc == "\n" then
					report(path, line, "trailing whitespace")
					if not fix then emit(run) end
				elseif not hasText then
					emit(run)						-- indentation (checked above)
				elseif #run >= 2 and run:find(" ") then
					report(path, line, "aligned with spaces")
					emit(fix and tabsTo(col, advance(col, run)) or run)
				else
					emit(run)
				end
				pos = e + 1
			end
		else
			if seg.kind == "comment" then
				-- a one-line comment: only its trailing whitespace is checked
				local body, trail = text:match("^(.-)([ \t]*)$")
				if trail ~= "" then
					report(path, line, "trailing whitespace")
					if fix then text = body end
				end
			end
			emit(text)
		end
	end

	if fix then
		local new = table.concat(out)
		if new ~= src then
			local wh = assert(io.open(path, "wb"))
			wh:write(new)
			wh:close()
		end
	end
end

for _, path in ipairs(files) do checkFile(path) end
if problems > 0 and not fix then os.exit(1) end
