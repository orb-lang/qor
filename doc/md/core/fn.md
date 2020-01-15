# Function Extensions


  Various methods to extend the functionality of functions and methods,
methodically.

```lua
local fn = {}
```
### thunk(fn, ...)

Returns a function which, called, will call the function with the given
arguments.

```lua
function fn.thunk(fn, ...)
   local args = pack(...)
   return function()
      return fn(unpack(args, 1, args.n))
   end
end
local thunk = fn.thunk
```
### partial(fn, ...)

Partial applicator: takes a function, and fills in the given arguments,
returning another function which accepts additional arguments:

```lua-example
add5 = fn.partial(function(a,b)
                  return a + b
               end, 5)
return add5(10) -- returns 15
```
```lua
function fn.partial(fn, ...)
   local args = pack(...)
   return function(...)
      return fn(unpack(args, 1, args.n), ...)
   end
end
```
## Errors and asserts


### Assertfmt

I'll probably just globally replace assert with this over time.


This avoids doing concatenations and conversions on messages that we never
see in normal use.

```lua
local format = assert(string.format)

function fn.assertfmt(pred, msg, ...)
   if pred then
      return pred
   else
      error(format(msg, ...), 2)
   end
end
```
```lua
return fn
```
