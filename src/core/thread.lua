







local uv = require "luv"



local thread = {}



local running = assert(coroutine.running)














function thread.onloop()
   local _, main = running()
   return main and uv.loop_alive()
end



return thread
