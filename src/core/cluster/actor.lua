





























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









local gmatch = assert(string.gmatch)
local function dispatchmessage(actor, msg)
   local result
   while msg do
      -- #todo replace this with construction-time translation to nested message?
      if msg.sendto then
         for prop in gmatch(msg.sendto, "([^.]+)[.]?") do
            actor = actor[prop]
         end
      end
      if msg.property then
         result = pack(actor[msg.property])
      elseif msg.call == true then
         result = pack(actor(unpack(msg)))
      elseif msg.call then
         local fn = actor[msg.call]
         if not fn then
            -- #todo this leaves out useful information in the case of a
            -- nested message, and also doesn't know how to represent the
            -- starting/root actor. We really want to stringify the whole
            -- chain in a meaningful way
            error("attempt to call a nil function " .. msg.call
                  .. " on " .. tostring(msg.sendto))
         end
         result = pack(fn(unpack(msg)))
      elseif msg.method then
         local fn = actor[msg.method]
         if not fn then
            -- Similar concern as with .call, also this is annoyingly similar
            error("attempt to call a nil method " .. msg.method
                  .. " on " .. tostring(msg.sendto))
         end
         result = pack(fn(actor, unpack(msg)))
      else
         error("Message must have one of property, call, or method: " .. (require "repr:repr".ts(msg)))
      end
      actor = result[1]
      msg = msg.message
   end
   return unpack(result)
end
act.dispatchmessage = dispatchmessage





return act

