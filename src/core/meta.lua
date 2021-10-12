





















local _base = require "core:core/_base"






local meta = {}












function meta.meta(MT, tab)
   tab = tab or {}
   if MT and MT.__index then
      -- inherit
      return setmetatable(tab, MT)
   elseif MT then
      -- decorate
      MT.__index = MT
      return MT
   else
      -- new metatable
      local _M = tab
      _M.__index = _M
      return _M
   end
end






















local sub = assert(string.sub)

local function hasmetamethod(mmethod, tab)
   assert(type(mmethod) == "string", "metamethod must be a string")
   local M = getmetatable(tab)
   if not M then
      return false
   end
   if sub(mmethod,1,2) == "__" then
      return rawget(M, mmethod)
   else
      return rawget(M, "__" .. mmethod)
   end
end

meta.hasmetamethod = hasmetamethod










function meta.instanceof(obj, Class)
   if type(Class) == 'string' then
      return type(obj) == Class
   else
      return type(obj) == 'table' and obj.idEst == Class
   end
end



return meta

