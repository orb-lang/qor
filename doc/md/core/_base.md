# Core base


This contains parts of the core module system which are used within the core
module system\.

Nothing in this module should be invoked directly, except by core; everything
in it is attached to one of the other submodules\.

```lua
local _base = {}
```


### thunk\(fn, \.\.\.\)

Returns a function which, called, will call the function with the given
arguments\.

```lua
function _base.thunk(fn, ...)
   local args = pack(...)
   return function()
      return fn(unpack(args, 1, args.n))
   end
end
```


### assertfmt\(pred, msg, \.\.\.\)

```lua
local format = assert(string.format)

function _base.assertfmt(pred, msg, ...)
   if pred then
      return pred
   else
      error(format(msg, ...), 2)
   end
end
```

```lua
return _base
```
