





























local _base = require "core:_base"
local iscallable = assert(_base.iscallable)






local act = {}





















local _weak = { __mode = 'kv' }
local __act_mth_attr = setmetatable({}, _weak)
local __mth_attr = setmetatable({}, _weak)

function act.borrowmethod(actor, method)
   assert(iscallable(method) or type(method) == 'string',
          "#2 for borrowmethod must be string or callable")
   local uid = {}
   __act_mth_attr[uid] = actor
   actor = nil
   if type(method) == 'string' then
      -- return a lookup function
      __mth_attr[uid] = method
      method = nil
      return function(...)
         local _actor = __act_mth_attr[uid]
         local _method = __mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return _actor[_method](_actor, ...)
      end
   else
      -- return a direct-call function
      __mth_attr[uid] = method
      method = nil
      return function(...)
         local _actor = __act_mth_attr[uid]
         local _method = __mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return _method(_actor, ...)
      end
   end
end



return act

