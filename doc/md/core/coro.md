# Coroutine Extensions


```lua
local coro = {}
```
## 5.2 compatibility


### pack(...)

A 5.2 shim.

```lua
local function pack(...)
   return { n = select('#', ...), ... }
end
coro.pack = pack
```
## Coroutine extensions


### safeWrap(f, ...)

This is to avoid the ``cannot resume dead coroutine`` error in using stock
``wrap``.


Due to the way ``coroutine.resume`` works, I've limited to five return
values, since we need to catch the ``yield()``s in order to strip the
success predicate.

```lua
local create, status, resume = coroutine.create,
                                coroutine.status,
                                coroutine.resume

function coro.safeWrap(f)
   local wrapped_fn = create(f)
   return function(...)
      if status(wrapped_fn) == "dead" then
         return nil
      else
         local success, a, b, c, d, e
         success, a, b, c, d, e =  resume(wrapped_fn, ...)
         if success then
            return a, b, c, d, e
         else
            error(a)
         end
      end
   end
end
```
```lua
return coro
```
