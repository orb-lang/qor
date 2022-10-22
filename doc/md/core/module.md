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

Defined in the [base module](https://gitlab.com/special-circumstance/qor/-/blob/trunk/doc/md/core/_base.md)\.

```lua
Mod.lazyloader = assert(_base.lazyloader)
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
