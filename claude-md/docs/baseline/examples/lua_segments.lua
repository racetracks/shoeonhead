-- lua_segments.lua
-- Splits Lua source into code, string and comment segments, so the rule
-- checks (tools/check_style.lua, tools/check_layers.lua) can look at code
-- only. Lua 5.1.
--
--   local segments = dofile("tools/lua_segments.lua")
--   for _, seg in ipairs(segments(src)) do ... seg.kind, seg.text ... end
--
-- kind is "code", "string", "comment" (one line) or "longcomment".

-- Splits a file into segments: { kind = "code" | "string" | "comment", text }.
return function(src)
	local segs = {}
	local i, n = 1, #src
	local codeStart = 1
	local function flushCode(upto)
		if upto >= codeStart then segs[#segs + 1] = { kind = "code", text = src:sub(codeStart, upto) } end
	end
	while i <= n do
		local c = src:sub(i, i)
		if c == "-" and src:sub(i, i + 1) == "--" then
			flushCode(i - 1)
			local eqs = src:match("^%-%-%[(=*)%[", i)
			local j
			if eqs then
				local _, e = src:find("]" .. eqs .. "]", i, true)
				j = e or n
			else
				j = (src:find("\n", i, true) or (n + 1)) - 1
			end
			segs[#segs + 1] = { kind = eqs and "longcomment" or "comment", text = src:sub(i, j) }
			i = j + 1
			codeStart = i
		elseif c == "\"" or c == "'" then
			flushCode(i - 1)
			local j = i + 1
			while j <= n do
				local d = src:sub(j, j)
				if d == "\\" then
					j = j + 2
				elseif d == c or d == "\n" then
					break
				else
					j = j + 1
				end
			end
			segs[#segs + 1] = { kind = "string", text = src:sub(i, j) }
			i = j + 1
			codeStart = i
		elseif c == "[" and src:match("^%[=*%[", i) then
			flushCode(i - 1)
			local eqs = src:match("^%[(=*)%[", i)
			local _, e = src:find("]" .. eqs .. "]", i, true)
			e = e or n
			segs[#segs + 1] = { kind = "string", text = src:sub(i, e) }
			i = e + 1
			codeStart = i
		else
			i = i + 1
		end
	end
	flushCode(n)
	return segs
end
