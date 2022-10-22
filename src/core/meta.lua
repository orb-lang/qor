





















local _base = require "core:core/_base"






local meta = {}






















local sub = assert(string.sub)

local function hasmetamethod(mmethod, tab)
   assert(type(mmethod) == "string", "metamethod must be a string")
   local M = getmetatable(tab)
   if not M then
      return false
   end
   return rawget(M, mmethod) or rawget(M, '__' .. mmethod)
end

meta.hasmetamethod = hasmetamethod










function meta.instanceof(obj, Class)
   if type(Class) == 'string' then
      return type(obj) == Class
   else
      return type(obj) == 'table' and obj.idEst == Class
   end
end











function meta.weak(mode)
   mode = mode or 'kv'
   return setmetatable({}, { __mode = mode })
end



return meta

