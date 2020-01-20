








local _base = {}








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



return _base
