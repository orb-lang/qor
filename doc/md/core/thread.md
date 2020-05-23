# Thread


Bridge uses coroutines in combination with the ``uv`` event loop.


This is a home for primitives which make that a little cleaner.

```lua
local uv = require "luv"
```
```lua
local thread = {}
```
```lua
local running = assert(coroutine.running)

```
### onloop()

A predicate which returns ``true`` if we're inside a ``uv`` event loop and inside
a coroutine: which means we can register a callback, ``yield``, and ``resume``
inside the callback.


Used to write "purple" functions, which are colored red or blue depending on
whether or not we're handling things asynchronously.

```lua
function thread.onloop()
   local _, main = running()
   return main and uv.loop_alive()
end
```
```lua
return thread
```
