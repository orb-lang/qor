# Print


  String manipulation libraries for printing\.


```lua
Print = {}
```


#### Print\.breakascii\(str, width\)

Breaks a string into lines of up to `width` characters, attempting to do so at
word boundaries, but falling back to a hard chop if this is not possible\.
Will never produce a line less than half the maximum length \(other than the
last line, of course\)\. Assumes no preexisting newlines in the string\.

Answers the wrapped string, plus the height and width required to display itthe number of lines, and the length of the longest line\)\.

\(
Doing this with utf8 in the mix is harder, and we can get away with
ASCII\-only sometimes\.\.\.

```lua
local concat = assert(table.concat)
local floor, max = assert(math.floor), assert(math.max)
local inbounds = assert(require "core:math" . inbounds)

local split_at = {}
for _, v in ipairs{" ", "-", "(", "{", "["} do
   split_at[v] = v == " " and -1 or 0
end

function Print.breakascii(str, width)
   if #str <= width then
      return str, 1, #str
   end
   local lines = {}
   local actual_width = 0
   local left = 1
   local min_width = floor(width / 2)
   while left <= #str do
      local min_right = left + min_width - 1
      local max_right = left + width - 1
      local line
      if max_right >= #str then
         line = str:sub(left)
         lines[#lines + 1] = line
         actual_width = max(actual_width, #line)
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
      line = str:sub(left, split_index + offset)
      lines[#lines + 1] = line
      actual_width = max(actual_width, #line)
      left = split_index + 1
   end
   return concat(lines, "\n"), #lines, actual_width
end
```


```lua
function Print.center(str, width)
   local diff = width - #str
   local lmargin, rmargin
   if diff % 2 ~= 0 then
      lmargin, rmargin = math.floor(diff / 2), math.floor(diff / 2) + 1
   else
      lmargin, rmargin = diff / 2, diff / 2
   end
   return  (" "):rep(lmargin) .. str .. (" "):rep(rmargin)
end
```


```lua
return Print
```
