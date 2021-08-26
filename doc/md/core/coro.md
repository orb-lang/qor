# Coroutine extensions

```lua
local coro = {}
```
```lua
local _base = require "core:core/_base"
local thunk = assert(_base.thunk)
```
## coro table

We put all of the ``coroutine`` table on ``coro``, so it's an enhanced replacement
for the library:

```lua
local coro = {}
for k,v in next, coroutine do
   coro[k] = v
end
```
### safewrap(f, ...)

Stock ``wrap`` throws an error if you call it when the inner coroutine is dead.


This behavior can be inconvenient, sometimes we prefer the ``nil, err`` return
pattern, which ``safewrap`` provides.


We call it ``safewrap``, not ``pwrap``, because the latter would imply that the
first return value is always a boolean that must be handled at the call site,
and if you wanted that, you could just use ``resume``.

```lua
local create, status, resume = assert(coroutine.create),
                               assert(coroutine.status),
                               assert(coroutine.resume)

local remove = assert(table.remove)

function coro.safewrap(f)
   local wrapped_fn = create(f)
   return function(...)
      if status(wrapped_fn) == 'dead' then
         return nil, "cannot resume dead coroutine inside safewrap"
      else
         local rets  =  pack(resume(wrapped_fn, ...))
         if rets[1] then
             return unpack(rets, 2, rets.n)
         else
            return nil, rets[2]
         end
      end
   end
end
```
### wrapgen(fn, ...)

``wrapgen`` creates wrapped coroutine generators.


That is, it takes a function and arguments, and returns a function which will
produce a wrapped coroutine, called with those arguments, each time it's
called.


An example:

```lua-example
local tab = {1,2,3,4}
local cog = coro.wrapgen(
            function(t)
               for _,v in ipairs(t) do
                  coroutine.yield(v)
               end
            end, tab)
local iter = cog()
local new_tab = coro.collect(iter)
-- new_tab = {1,2,3,4}
```

Note that each call to ``cog`` will generate a fresh iterator, and that due to
Lua's semantics, tables (and userdata) remain mutable, e.g. an ``insert(tab,5)``
will modify the return on subsequent calls to ``cog``.


Also, any closure with mutable state will be in whatever state the next
generator finds it when a new wrapped coroutine is generated.  Providing
genuinely immutable semantics is difficult, expensive, and impossible in the
general case (that is, including userdata).


This pattern may be used to provide some of the additional functionality of
continuations; if a coroutine is a one-shot continuation, this is a one-shot
continuation _generator_, which may be called upon to create as many shots as
one might need.

```lua
local wrap = assert(coroutine.wrap)

function coro.wrapgen(fn, ...)
   local body = thunk(fn, ...)
   return function()
      return wrap(body)
   end
end
```
### cogen(fn, ...)

Equivalent to ``wrapgen``, but returns the coroutine itself.

```lua
function coro.cogen(fn, ...)
   local body = thunk(fn, ...)
   return function()
      return create(body)
   end
end
```
### fire(co, ...)

``fire`` is a one-shot ``wrap``, taking care of the marshalling and return
checking.  ``wrap`` creates the coroutine internally; it may be retrieved by
the enclosing function, but cannot be easily inspected or manipulated at the
call site.


Despite the name, the ``co`` parameter may also be a function, in which case it
is assumed to be a wrapped coroutine and is called directly.


This makes ``fire`` a unified framework, one in which funcitonalized coroutines
and bare coroutines may be interchangeably invoked.


Due to the pcall-like nature of ``coroutine.resume``, ``fire`` handles errors
arising in a coroutine, returning ``nil, err``. It makes no special effort to
handle those within a wrapped function; for this, use ``safewrap``.

```lua
function coro.fire(co, ...)
   local cotype = type(co)
   if cotype == 'thread' then
      -- check the status
      if status(co) == 'dead' then
         return nil, "fire cannot resume dead coroutine"
      end
      local rets = pack(resume(co, ...))
      if rets[1] == true then
         remove(rets, 1)
         rets.n = rets.n -1
         return unpack(rets)
      elseif rets[1] == false then
         return nil, rets[2]
      end
   elseif cotype == 'function' then
      return co(...)
   else
      error("cannot fire on a " .. cotype)
   end
end
```
### canyield(...)

Like ``yield``, except it first detects if we're inside a not-main coroutine.


If not, ``return`` the values.

```lua
local running = assert(coroutine.running)

function coro.canyield(...)
   local _, main = running()
   if not main then
      yield(...)
   else
      return ...
   end
end
```
```lua
return coro
```
