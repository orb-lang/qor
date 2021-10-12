






local assert = assert or error "no assert"

local Uv = {}

local uv = assert(require "luv")










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




return Uv

