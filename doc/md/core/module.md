# Module

Tools for dealing with modules\.


```lua
local Mod = {}
```

```lua

local assert = assert(require "core:core/_base" . assertfmt)
local require, pack, unpack = assert(require), assert(pack), assert(unpack)
```


### import\(req\_str, \.\.\.\)

This is something like an `import` statement from other dynamic languages\.

The first parameter is a `require` string, and the rest are fields from the
return value to assert and return\.

```lua
function Mod.import(req_str, ...)
   local mod = require(req_str)
   local fields, exports = pack(...), {}
   for i = 1, fields.n do
       exports[i] = assert(mod[fields[i]], "can't require %s", fields[i])
   end
   exports.n = fields.n
   return unpack(exports)
end
```


### request

The optional veresion of `require`\.

```lua
local pcall = assert(pcall)

function Mod.request(module)
   local ok, mod = pcall(require, module)
   if ok then
      return mod
   else
      return nil
   end
end
```

```lua
return Mod
```
