









local _base = {}










function _base.no_op()
   return
end









function _base.thunk(fn, ...)
   local args = pack(...)
   return function()
      return fn(unpack(args, 1, args.n))
   end
end






local format = assert(string.format)

function _base.assertfmt(pred, msg, ...)
   if pred then
      return pred
   else
      error(format(msg, ...), 2)
   end
end









function _base.iscallable(val)
   if type(val) == 'function' then return true end
   if type(val) == 'table' then
      local M = getmetatable(val)
      if M and rawget(M, "__call") then
         return true
      end
   end
   return false
end



return _base

