# Thread


Bridge uses coroutines in combination with the `uv` event loop\.

This is a home for primitives which make that a little cleaner\.

```lua
local uv = require "luv"
```

```lua
local thread = {}
```


### nest\(tag\)

  Assymetric coroutines are the best primitive a single\-threaded language can
have for cooperative threading\.  They get a bad rap sometimes, exactly because
they are primitive\.  Any `yield` will find the next `resume` down on the call
stack, which is easy and composable when the user controls both the `resume`
and the `yield`\.

Sometimes what we want is a system that behaves just like ordinary coroutines,
but with the `resume` and `yield` \(and support functions\) paired together, so
that this system ignores any `yield` which doesn't come from within it\.

Wouldn't you know it, Phillipe Janda has solved this problem as well\!  The
solution \(and full copyright\) may be found [here]( https://github.com/saucisson/lua-coronest/blob/master/LICENSE)\.  Alban Linard, the
copyright holder, credits the former and I'm not surprised to hear it\.

This will probably end up in a modified form, I'm checking it in with all the
copyright information and will of course leave the link to the license for as
long as it resolves\.

As of the first commit, I've simply modified the main function to live on the
`thread` table, instead of being returned anoymously as one might expect from
a module\.

```lua
local select      = select
local create      = coroutine.create
local isyieldable = coroutine.isyieldable -- luacheck: ignore
local resume      = coroutine.resume
local running     = coroutine.running
local status      = coroutine.status
local wrap        = coroutine.wrap
local yield       = coroutine.yield

function thread.nest(tag)
  local coroutine = {
    isyieldable = isyieldable,
    running     = running,
    status      = status,
  }
  tag = tag or {}

  local function for_wrap (co, ...)
    if tag == ... then
      return select (2, ...)
    else
      return for_wrap (co, co (yield (...)))
    end
  end

  local function for_resume (co, st, ...)
    if not st then
      return st, ...
    elseif tag == ... then
      return st, select (2, ...)
    else
      return for_resume (co, resume (co, yield (...)))
    end
  end

  function coroutine.create (f)
    return create (function (...)
      return tag, f (...)
    end)
  end

  function coroutine.resume (co, ...)
    return for_resume (co, resume (co, ...))
  end

  function coroutine.wrap (f)
    local co = wrap (function (...)
      return tag, f (...)
    end)
    return function (...)
      return for_wrap (co, co (...))
    end
  end

  function coroutine.yield (...)
    return yield (tag, ...)
  end

  return coroutine
end
```


### onloop\(\)

A predicate which returns `true` if we're inside a `uv` event loop and inside
a coroutine: which means we can register a callback, `yield`, and `resume`
inside the callback\.

Used to write "purple" functions, which are colored red or blue depending on
whether or not we're handling things asynchronously\.

```lua
function thread.onloop()
   local _, main = running()
   return main and uv.loop_alive()
end
```


### canyield\(\.\.\.\)

If we're inside a coroutine, `yield` the values, otherwise, return them\.

This should let us write functions which are either blocking or non\-blocking,
with some care, by wrapping async operations in 'purple' functions and using
`canyield` to mark points where, in the service of e\.g\. resynchronizing, we
might want to surrender control\.

```lua
function thread.canyield(...)
   local _, main = running()
   if not main then
      yield(...)
   else
      return ...
   end
end
```

```lua
return thread
```
