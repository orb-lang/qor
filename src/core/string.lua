



local String = {}






local byte = assert(string.byte)
local find = assert(string.find)
local sub = assert(string.sub)
local format = assert(string.format)










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









local function _str__repr(str_tab)
    return str_tab[1]
end

local _str_M = {__repr = _str__repr}

function String.to_repr(str)
   str = tostring(str)
   return setmetatable({str}, {__index = _str_M})
end
















local concat = assert(table.concat)

local cp_M = {}


function cp_M.__tostring(codepoints)
   local answer = codepoints
   if codepoints.err then
      answer = {}
      for i, v in ipairs(codepoints) do
         local err_here = codepoints.err[i]
         answer[i] = err_here and err_here.char or v
      end
   end
   return concat(answer)
end

function String.codepoints(str, start, finish)
   start = start or 1
   finish = (finish and finish <= #str) and finish or #str
   local utf8 = String.utf8
   -- propagate nil
   if not str then return nil end
   -- break on bad type
   assert(type(str) == "string", "codepoints must be given a string")
   local codes = setmetatable({}, cp_M)
   local index = start
   while index <= finish do
      local width, err = utf8(str, index)
      if width then
         local point = sub(str, index, index + width - 1)
         insert(codes, point)
         index = index + width
      else
         -- take off a byte and store it
         local err_packet = { char = sub(str, index, index),
                              err  = err }
         codes.err = codes.err or {}
         insert(codes, "�")
         -- place the error at the same offset in the err table
         codes.err[#codes] = err_packet
         index = index + 1
      end
   end
   return codes
end








function String.slurp(filename)
  local f = io.open(filename, "rb")
  local content = f:read("*all")
  f:close()
  return content
end










function String.inbounds(value, lower, upper)
  if lower and value < lower then
    return false
  end
  if upper and value > upper then
    return false
  end
  return true
end







function String.bound(value, lower, upper)
  if lower and value < lower then
    value = lower
  end
  if upper and value > upper then
    value = upper
  end
  return value
end













local format = string.format

function String.assertfmt(pred, msg, ...)
   if pred then
      return pred
   else
      error(format(msg, ...))
   end
end



return String
