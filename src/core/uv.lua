

















local assert = assert or error "no assert"

local Uv = {}

local uv = assert(require "luv")

local s = require "status:status" ()
s.chatty = true










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











local resume = assert(coroutine.resume)

function Uv.once(event)
   local idle = uv.new_idle()
   idle:start(function()
      idle:stop()
      idle:close()
      s:chat("executing event of type %s", type(event))
      if type(event) == 'thread' then
         resume(event)
      else
         event()
      end
   end)
end




return Uv

