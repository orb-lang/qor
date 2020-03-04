













local _base = require "core:core/_base"






local fn = {}









fn.thunk = assert(_base.thunk)
















function fn.partial(fn, ...)
   local args = pack(...)
   return function(...)
      return fn(unpack(args, 1, args.n), ...)
   end
end











function fn.itermap(fn, iter)
   local ret, res = {}
   while true do
      res = pack(fn(iter()))
      if #res == 0 then
         return ret
      else
         ret[#ret + 1] = res
      end
   end
end






















local function _patch(dynamic, fn)
   getmetatable(dynamic).__call = function(_, ...)
                                     return fn(...)
                                  end
end

local function dyn_newindex()
   error "Can't assign to a dynamic function"
end

function fn.dynamic(fn)
   return setmetatable({}, { __call = function(_, ...)
                                         return fn(...)
                                      end,
                             __index = { patch = _patch },
                             __newindex = dyn_newindex })
end














fn.assertfmt = _base.assertfmt



return fn
