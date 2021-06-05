# Debug

Extensions to the debug library\.

```lua
local Debug = {}

for k,v in pairs(assert(debug)) do
   Debug[k] = v
end
```


### debug\.findrefs\(val\)

Finds every instance of a given value, anywhere in the code\.

This can be expected to take awhile\.

```lua
local getupvalue, getinfo = assert(debug.getupvalue), assert(debug.getinfo)

local function _findrefs(copies, val, dupes, subject)
   if dupes[subject] then return end
   dupes[subject] = true
   local function test_one(test, container)
      -- check key first
      if rawequal(test, val) then
         copies[#copies + 1] = container
         copies.n = copies.n + 1
      end
      if type(test) == 'table' then
         if not dupes[test] then
            _findrefs(copies, val, dupes, test)
         end
      elseif type(test) == 'function' then
         -- look in the upvalues
         if not copies[test] then
            dupes[test] = true
            local name, ups, idx = "", true, 1
            while ups ~= nil do
               name, ups = getupvalue(test, idx)
               if name == nil then
                  ups = nil
               else
                  if ups == val then
                     copies[#copies + 1] = debug.getinfo(test)
                     copies.n = copies.n + 1
                  end
                  if type(ups) == 'table' or type(ups) == 'function'
                     and (not dupes[ups]) then
                     _findrefs(copies, val, dupes, ups)
                  end
                  idx = idx + 1
               end
            end
         end
         dupes[test] = true
      end
   end
   if type(subject) == 'function' then
      test_one(subject)
   elseif type(subject) == 'table' then
      for k, v in next, subject do
         test_one(k, subject)
         test_one(v, subject)
      end
      local _M = getmetatable(subject)
      if _M then
         _findrefs(copies, val, dupes, _M)
      end
   end
   return copies
end

function Debug.findrefs(val)
   local dupes = {}
   return unpack(_findrefs({n = 0}, val, dupes, getfenv(1)))
end
```


```lua
return Debug
```
