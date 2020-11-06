















local uv = require "luv"






local thread = {}






local running, yield = assert(coroutine.running),
                       assert(coroutine.yield)



























function thread.onloop()
   local _, main = running()
   return main and uv.loop_alive()
end


























function thread.canyield(...)
   local _, main = running()
   if not main then
      yield(...)
   else
      return ...
   end
end






return thread

