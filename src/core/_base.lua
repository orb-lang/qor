









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










local newproxy = newproxy or function() return {} end



function _base.unique()
   return newproxy()
end



















local function lazy_load_gen(requires)
   local name = requires[1] or "generic codex you really should name"
   requires[1] = nil
   return function(tab, key)
      if requires[key] then
         -- put the return on the core table
         tab[key] = require(requires[key])
         return tab[key]
      else
         error(name .. " doesn't have a module '" .. tostring(key) .. "'")
      end
   end
end





local function call_gen(requires)
   return function(tab, env)
      local _;
      for k in pairs(requires) do
         _ = tab[k]
         if env then
            -- assign the now cached value as a global or at least slot
            env[k] = tab[k]
         end
      end
      return tab
   end
end





function _base.lazyloader(lazy_table)
   return setmetatable({}, { __index = lazy_load_gen(lazy_table),
                             __call  = call_gen(lazy_table) })
end



return _base

