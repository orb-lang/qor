





























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






<<<<<<< HEAD
local function dispatchmessage(actor, msg)
   local _cyc = {}

   local function _dispatch(actor, msg)
      -- detect potential cycles
      if _cyc[msg] then error "cycle in Message" end
      _cyc[msg] = true
||||||| e2eadf6
local function dispatchmessage(actor, msg)
   while msg do
      -- #todo replace this with
      -- construction-time translation to nested message?
=======
>>>>>>> a4312a7759b00a047bbc3c04eb410ced6e664755



local gmatch = assert(string.gmatch)
local function dispatchmessage(actor, msg)
   while msg do
      -- #todo replace this with construction-time translation to nested message?
      if msg.sendto then
         for prop in gmatch(msg.sendto, "([^.]+)[.]?") do
            actor = actor[prop]
         end
      end
      if msg.property then
         actor = actor[msg.property]
      elseif msg.call == true then
         actor = actor(unpack(msg))
      elseif msg.call then
         actor = actor[msg.call](unpack(msg))
      elseif msg.method then
         actor = actor[msg.method](actor, unpack(msg))
      else
         error("Message must have one of property, call, or method: " .. (require "repr:repr".ts(msg)))
      end
   end

   _dispatch(actor, msg)

   return actor
end
act.dispatchmessage = dispatchmessage





return act

