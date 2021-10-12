





























local _base = require "core:_base"
local iscallable = assert(_base.iscallable)






local act = {}





















local __act_mth_attr = setmetatable({}, { __mode = 'kv' })

function act.borrowmethod(actor, method)
   assert(iscallable(method) or type(method) == 'string',
          "#2 for borrowmethod must be string or callable")
   local uid = {}
   __act_mth_attr[uid] = actor
   actor = nil
   if type(method) == 'string' then
      -- return a lookup function
      return function(...)
         local _actor = __act_mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return _actor[method](_actor, ...)
      end
   else
      -- return a direct-call function
      return function(...)
         local _actor = __act_mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return method(_actor, ...)
      end
   end
end









local __act_getter_attr = setmetatable({}, { __mode = 'kv' })

function act.getter(actor, slot)
   local uid = {}
   __act_getter_attr[uid] = actor
   actor = nil
   return function()
             local _actor = __act_getter_attr[uid]
             if not _actor then
                error "actor has gone out of scope"
             end
             return _actor[slot]
          end
end






local function dispatchmessage(actor, msg)
   while msg do
      -- #todo replace this with
      -- construction-time translation to nested message?

      -- handle recursive case first
      if msg.message then
         actor :dispatchmessage(msg.message)
         return actor
      end

      if msg.sendto then
         actor = actor[msg.sendto]
      elseif msg.property then
         actor = actor[msg.property]
      elseif msg.call == true then
         actor = actor(unpack(msg))
      elseif msg.call then
         actor = actor[msg.call](unpack(msg))
      elseif msg.method then
         actor = actor[msg.method](actor, unpack(msg))
      else
         error("Message must have one of property, call, or method")
      end
      msg = msg.message
   end
   return actor
end





return act

