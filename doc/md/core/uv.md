# UV


  A core library extending [libuv](httk://), specifically the [luv](httk://) bindings\.

```lua
local assert = assert or error "no assert"

local Uv = {}

local uv = assert(require "luv")
```


### Uv\.deferby\(event, ms\)

  Causes `event` \(a callable of no parameters\) after `ms` milliseconds, during
the timer step in a `uv` event loop\.  `ms` parameter defaults to 0\.


```lua
function Uv.deferby(event, ms)
   ms =  ms or 0
   local timer = uv.new_timer()

   local _event = function()
      event()
      timer:stop()
   end

   timer:start(ms, 0, _event)

   return;
end
```


```lua
return Uv
```
