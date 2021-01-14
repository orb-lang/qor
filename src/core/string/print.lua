








utf8 = require "lua-utf8"
local anterm; -- lazy-loaded




Print = {}











local concat = assert(table.concat)
local floor = assert(math.floor)
local inbounds = assert(require "core:math" . inbounds)

local split_at = {}
for _, v in ipairs{" ", "-", "(", "{", "["} do
   split_at[v] = v == " " and -1 or 0
end

function Print.breakascii(str, width)
   if #str <= width then
      return str
   end
   local lines = {}
   local left = 1
   local min_width = floor(width / 2)
   while left <= #str do
      local min_right = left + min_width - 1
      local max_right = left + width - 1
      if max_right >= #str then
         lines[#lines + 1] = str:sub(left)
         break
      end
      local split_index, offset
      -- Check one past the max width because we might be able to
      -- remove a trailing space
      for i = max_right + 1, min_right, -1 do
         offset = split_at[str:sub(i, i)]
         -- But now we do need to check if we'll actually be in bounds
         if offset and inbounds(i + offset, min_right, max_right) then
            split_index = i
            break
         end
      end
      if not split_index then
         -- Didn't find a natural breakpoint, just chop at the max width
         split_index = max_right
         offset = 0
      end
      lines[#lines + 1] = str:sub(left, split_index + offset)
      left = split_index + 1
   end
   return concat(lines, "\n")
end




return Print

