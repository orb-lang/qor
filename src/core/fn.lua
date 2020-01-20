






local _base = require "core:core/_base"
local fn = {}










fn.thunk = assert(_base.thunk)
















function fn.partial(fn, ...)
   local args = pack(...)
   return function(...)
      return fn(unpack(args, 1, args.n), ...)
   end
end














fn.assertfmt = _base.assertfmt



return fn
