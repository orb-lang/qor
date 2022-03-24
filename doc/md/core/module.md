# Module

Tools for dealing with modules\.


```lua
local Mod = {}
```

```lua

local _base = require "qor:core/_base"
local assertfmt = assert(_base.assertfmt)
local require, pack, unpack = assert(require), assert(pack), assert(unpack)
```


### lazyloader\(tab\)

Defined in the [base module](NO default.domain IN MANIFESTqor/MISSING_POST_PROJECTdoc/md/core/_base.md)\.

```lua
Mod.lazyloader = assert(_base.lazyloader)
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

The optional version of `require`\.

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
