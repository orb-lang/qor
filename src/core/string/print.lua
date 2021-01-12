








utf8 = require "lua-utf8"
local anterm; -- lazy-loaded




Print = {}











local concat = assert(table.concat)
local floor = assert(math.floor)

local split_at = {}
for _, v in ipairs{" ", "-", "(", "{", "["} do
   split_at[v] = true
end

function Print.breakascii(str, width)
   if #str <= width then
      return str
   end
   local lines = {}
   local left = 1
   local min_width = floor(width / 2)
   while left <= #str do
      local max_right = left + width - 1
      if max_right >= #str then
         lines[#lines + 1] = str:sub(left)
         break
      end
      local split_index, offset
      for i = max_right, left + min_width - 1, -1 do
         if split_at[str:sub(i, i)] then
            split_index = i
            break
         end
      end
      if split_index then
         offset = str:sub(split_index, split_index) == " " and -1 or 0
      else
         -- Didn't find a natural breakpoint, just chop at the max width
         split_index = max_right
         offset = 0
      end
      lines[#lines + 1] = str:sub(left, split_index + offset)
      left = split_index + 1
      -- __G.foo = rawget(__G, "foo") or {}
      -- __G.foo[#__G.foo + 1] = left
   end
   return concat(lines, "\n")
end




return Print

