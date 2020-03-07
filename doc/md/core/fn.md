# Function Extensions


  Various methods to extend the functionality of functions and methods,
methodically.


This is also the home of some core functions which are distinguished by their
actions, side effects, or effect on control flow, rather than by acting on
a specific data structure.  Currently this is limited to ``assertfmt``.


#### imports

```lua
local _base = require "core:core/_base"
```
## fn table

```lua
local fn = {}
```
### thunk(fn, ...)

Returns a function which, called, will call the function with the given
arguments.

```lua
fn.thunk = assert(_base.thunk)
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
### itermap(fn, iter)

Applies ``fn`` to each element returned from ``iter``, in turn.


For a consistent interface, all return values are ``pack``ed into one array
slot of a table, which is returned.

```lua
function fn.itermap(fn, iter)
   local ret, res = {}
   while true do
      res = pack(fn(iter()))
      if #res == 0 then
         return ret
      else
         ret[#ret + 1] = res
      end
   end
end
```
### dynamic(fn)

Because functions are immutable, we can't replace all instances of a function,
at least not without trawling the entire program with the ``debug`` library
looking for upvalues and locals.


``dynamic`` returns a callable table, which calls the function with the given
arguments.  It also has a ``patch`` method, which replaces the calling function
with a new function.


Since tables are mutable, all instances of that function are thereby replaced.

```lua
local function _patch(dynamic, fn)
   getmetatable(dynamic).__call = function(_, ...)
                                     return fn(...)
                                  end
end

local function dyn_newindex()
   error "Can't assign to a dynamic function"
end

function fn.dynamic(fn)
   return setmetatable({}, { __call = function(_, ...)
                                         return fn(...)
                                      end,
                             __index = { patch = _patch },
                             __newindex = dyn_newindex })
end
```
### hookable(fn)

As we build out ``helm``, I would like to be able to expose a rich API for
extensions, a la Emacs.


One of the ways to do this is to expose functions with hooks: actions taken
before or after a given function.


Doing this well means not letting implementation get ahead of use; think of
this as a proof of concept.


A hookable function is a callable table with slots ``pre`` and ``post``, which,
when present, are called before and after the function.


``pre`` receives the same parameters, and must return parameters that are then
passed to the main function.  These don't have to be the same parameters,
but certainly can be, if pre is called for side effects.  This calling
convention gives ``pre`` a chance to modify the default parameters.


``post`` receives the return values of the main function, if any, followed by
either the return parameters of ``pre`` or the main parameters, depending on if
there is a pre-hook.  The reason for this calling convention is that otherwise
the order of parameters changes if the ``pre`` hook is removed, making it
difficult to write a ``post`` hook which is unaware of what ``pre`` is doing.


This is because we don't want to have to structure the main function in a
parameter-passing style, but if it does return something, ``post`` should get a
shot at it.


The return values are the return values of ``post`` or the main function,
depending.

```lua
local _hooks = setmetatable({}, {__mode = "k"})

local function hookable_newindex()
   error "Attempt to assign value to a hookable function"
end

local function call_with_hooks(hooked, fn, ...)
   local pre, post = _hooks[hooked].pre, _hooks[hooked].post

   if pre and post then
      local new_arg = pack(pre(...))
      return post(fn(unpack(new_arg)), unpack(new_arg))
   elseif pre then
      return fn(pre(...))
   elseif post then
      return post(fn(...), ...)
   else
      return fn(...)
   end
end

local function hookPre(hooked, pre_hook)
   _hooks[hooked].pre = pre_hook
end

local function hookPost(hooked, post_hook)
   _hooks[hooked].post = post_hook
end

local function unhookPre(hooked)
   _hooks[hooked].pre = nil
end

local function unhookPost(hooked)
   _hooks[hooked].post = nil
end

local hook_index = { hookPre    =  hookPre,
                     hookPost   =  hookPost,
                     unhookPre  =  unhookPre,
                     unhookPost =  unhookPost }

function fn.hookable(fn, pre, post)
   local hook_m = { __newindex = hookable_newindex,
                    __index    = hook_index,
                    __call = function(hooked, ...)
                                return call_with_hooks(hooked, fn, ...)
                             end }
   local hooked = setmetatable({}, hook_m)
   local hook_attr = { pre = pre, post = post }
   _hooks[hooked] = hook_attr
   return hooked
end

```
## Errors and asserts


### Assertfmt

I'll probably just globally replace assert with this over time.


This avoids doing concatenations and conversions on messages that we never
see in normal use.

```lua
fn.assertfmt = _base.assertfmt
```
```lua
return fn
```
