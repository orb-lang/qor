








utf8 = require "lua-utf8"
local anterm; -- lazy-loaded




Print = {}











local byte, sub = assert(string.byte), assert(string.sub)
local concat = assert(table.concat)

local _splits, split_at = {" ", "-", "(", "{", "["}, {}

for _, v in ipairs(_splits) do
   split_at[v] = true
end

function Print.breakascii(str, width)
   if #str <= width then
      return str
   end
   local lines = {}
   local idx, left, right = 1, 1, width
   local gutter = math.floor(1/2 * width)
   local breaking = true
   while breaking do
      -- get one line
      if left + width > #str then
         -- take the last part
         lines[#lines + 1] = sub(str, left)
         breaking = false
      else
         for i = right, right - gutter, -1 do
            local test = split_at[sub(str, i, i)]
            if test then
               idx = i
               break
            end
         end
         if idx >= right - gutter then
            local offset = sub(str, idx, idx) == " " and 1 or 0
            lines[#lines + 1] = sub(str, left, idx - offset)
            left = idx + 1
            right = left + width
            idx = left
         else
            -- just break
            lines[#lines + 1] = sub(str, left, right)
            left = right + 1
            right = left + width
            idx = left
         end
      end
   end
   return concat(lines, "\n")
end




return Print

