



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



















function meta.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end

















function meta.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
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













local pairs = assert(pairs)

function meta.endow(Meta)
   local MC = {}
   for k, v in pairs(Meta) do
      MC[k] = v
   end
   return MC
end







return meta
