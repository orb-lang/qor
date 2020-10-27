








local cluster = {}















local sub = assert(string.sub)

local isempty = table.isempty
                or
                function(tab)
                   local empty = true
                   for _,__ in pairs(tab) do
                      empty = false
                      break
                   end
                   return empty
                end

function cluster.Meta(Meta)
   if Meta and Meta.__index then
      -- inherit
      local tab = {}
      for field, value in next, Meta, nil do
         if sub(field, 1, 2) == "__" then
            tab[field] = value
         end
      end
      tab.__index = Meta
      return setmetatable(tab, Meta)
   elseif Meta
      and type(Meta) == "table"
      and isempty(Meta) then
      -- decorate
      Meta.__index = Meta
      return Meta
   elseif not Meta then
      local _M = {}
      _M.__index = _M
      return _M
   end
   -- callable tables and constructors here
   error "cannot make metatable"
end













local function _bind(obj, fn)
  if not fn then return nil end
  return function(...)
     return fn(obj, ...)
  end
end

function cluster.super(obj, field)
   if rawget(obj, field) then
      local idx = getmetatable(obj).__index
      if not idx then return nil end
      return _bind(obj, idx[field])
   else
      local M_idx = getmetatable(obj).__index
      if not M_idx then return nil end
      local idx = getmetatable(M_idx).__index
      if idx and type(idx) == 'table' then
         return _bind(obj, M[field])
      elseif idx and type(idx) == 'function' then
         return _bind(obj, idx(obj, field))
      else
         return nil
      end
   end
   -- no such field
   return nil
end



return cluster

