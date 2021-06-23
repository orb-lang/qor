









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







function _base.deepclone(tab)
   assert(type(tab) == "table",
          "cannot deepclone value of type " .. type(tab))
   local dupes = {}
   local function _deep(val)
      local copy = val
      if type(val) == "table" then
         if dupes[val] then
            copy = dupes[val]
         else
            copy = {}
            dupes[val] = copy
            for k,v in next, val do
               copy[_deep(k)] = _deep(v)
            end
            -- copy the metatable after, in case it contains
            -- __index or __newindex behaviors
            copy = setmetatable(copy, _deep(getmetatable(val)))
         end
      end
      return copy
   end
   return _deep(tab)
end



return _base

