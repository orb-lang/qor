










local function is_string(_, str)
   return type(str) == 'string'
end




local String = setmetatable({}, { __call = is_string })






local assertfmt = require "core:core/_base".assertfmt
local byte = assert(string.byte)
local find = assert(string.find)
local sub = assert(string.sub)
local format = assert(string.format)








for k, v in next, string do
  String[k] = v
end









String.assertfmt = assertfmt
























local function continue(c)
   return c >= 128 and c <= 191
end

local function _offsideErr(str, offset)
   return nil, "out of bounds: #str: " .. tostring(#str)
                  .. ", offset: " .. tostring(offset)
end
function String.utf8(str, offset)
   offset = offset or 1
   local byte = byte
   local head = byte(str, offset)
   if not head then
      return _offsideErr(str, offset)
   end
   if head < 128 then
      return 1
   elseif head >= 194 and head <= 223 then
      local two = byte(str, offset + 1)
      if not two then
         return _offsideErr(str, offset + 1)
      end
      if continue(two) then
         return 2
      else
         return nil, "utf8: bad second byte"
      end
   elseif head >= 224 and head <= 239 then
      local two, three = byte(str, offset + 1), byte(str, offset + 2)
      if (not two) or (not three) then
         return _offsideErr(str, offset + 2)
      end
      if continue(two) and continue(three) then
         return 3
      else
         return nil, "utf8: bad second and/or third byte"
      end
   elseif head >= 240 and head <= 244 then
      local two, three, four = byte(str, offset + 1),
                               byte(str, offset + 2),
                               byte(str, offset + 3)
      if (not two) or (not three) or (not four) then
         return _offsideErr(str, offset + 3)
      end
      if continue(two) and continue(three) and continue(four) then
         return 4
      else
         return nil, "utf8: bad second, third, and/or fourth byte"
      end
   elseif continue(head) then
      return nil, "utf8: continuation byte at head"
   elseif head == 192 or head == 193 then
      return nil, "utf8: 192 or 193 forbidden"
   else -- head > 245
      return nil, "utf8: byte > 245"
   end
end













local function findall(str, patt)
   local find = type(str) == 'string' and find or str.find
   local matches = {}
   local index = 1
   local left, right
   repeat
     left, right = find(str, patt, index)
     if left then
        matches[#matches + 1] = {left, right}
        index = right + 1
     end
   until left == nil
   if #matches > 0 then
      return matches
   else
      return nil
   end
end

String.findall = findall














































local fmt_set = {"*", "C", "L", "R", "T", "U", "b", "n", "q", "s", "t" }

for i, v in ipairs(fmt_set) do
   fmt_set[i] = "%%" .. v
end

--[[
local function next_fmt(str)
   local head, tail
   for _, v in ipairs(fmt_set) do
      head, tail = 2
end]]

function String.format_safe(str, ...)

end









local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }

function String.litpat(s)
    return (s:gsub(".", matches))
end











local function cleave(str, pat)
   local at = find(str, pat)
   if at then
      return sub(str, 1, at - 1), sub(str, at + 1)
   else
      return str, nil
   end
end
String.cleave = cleave










function String.isidentifier(str)
   return find(str, "^[a-zA-Z_][a-zA-Z0-9_]+$") == 1
end








function String.lines(str)
   local pos = 1;
   return function()
      if not pos then return nil end
      local p1 = find(str, "[\r\n]", pos)
      local line
      if p1 then
         local p2 = p1
         if sub(str, p1, p1) == "\r" and sub(str, p1+1, p1+1) == "\n" then
            p2 = p1 + 1
         end
         line = sub(str, pos, p1 - 1 )
         pos = p2 + 1
      else
         line = sub(str, pos )
         pos = nil
      end
      return line
   end
end






















local _nl_map = setmetatable({}, { __mode = 'k' })

local function _findPos(nl_map, target, start)
   local line = start or 1
   local cursor = 0
   local col
   while true do
      if line > #nl_map then
         -- technically two possibilities: node.last is after the
         -- end of str, or it's on a final line with no newline.
         -- the former would be quite exceptional, so we assume the latter
         -- here.
         -- so we need the old cursor back:
         cursor = nl_map[line - 1][1] + 1
         return line, target - cursor + 1
      end
      local next_nl = nl_map[line][1]
      if target > next_nl then
         -- advance
         cursor = next_nl + 1
         line = line + 1
      else
         return line, (target - cursor) + 1
      end
   end
end



local function nextLine(str, target, idx, nl_map)
   local prev_nl, next_nl = nl_map[#nl_map] or 0,
                            find(str, "\n", idx)

   if not next_nl then
      next_nl = #str + 1 -- (I think? fake newline)
   end
   nl_map[#nl_map + 1] = next_nl
   if target > next_nl then
      return nil, next_nl + 1
   else
      -- this is just to bust the cache until I write the memoized search
      local top = #nl_map
      table.clear(nl_map)
      return top, target - prev_nl
   end

end



function String.linepos(str, offset)
   local nl_map;
   assert(offset <= #str, "can't find a position longer than the string!")
   if _nl_map[str] then
      nl_map = _nl_map[str]
   else
      nl_map = {}
      _nl_map[str] = nl_map
   end
   -- otherwise find the offsets
   local line, idx = nil, 1
   while not line do
      line, idx = nextLine(str, offset, idx, nl_map)
   end

   return line, idx -- which becomes column when line is truthy

end









local function _str__repr(str_tab)
    return str_tab[1]
end

local _str_M = {__repr = _str__repr}

function String.to_repr(str)
   str = tostring(str)
   return setmetatable({str}, _str_M)
end










function String.slurp(filename)
  local f = io.open(tostring(filename), "rb")
  if not f then
     error ("no such file: " .. tostring(filename))
  end
  local content = f:read("*all")
  f:close()
  return content
end












function String.spit(filename, file)
  local f = io.open(tostring(filename), "w+")
  if not f then
     error ("no such file: " .. tostring(filename))
  end
  local ok = f:write(file)
  f:close()
end








local sub = assert(string.sub)

function String.splice(to_split, to_splice, index)
   assert(type(to_split) == "string", "bad argument #1 to splice: "
           .. "string expected, got %s", type(to_split))
   assert(type(to_splice) == "string", "bad argument #2 to splice: "
           .. "string expected, got %s", type(to_splice))
   assert(type(index) == "number", "bad argument #2 to splice: "
          .. " number expected, got %s", type(index))
   assert(index >= 0 and index <= #to_split, "splice index out of bounds")
   local head, tail = sub(to_split, 1, index), sub(to_split, index + 1)
   return head .. to_splice .. tail
end



return String

