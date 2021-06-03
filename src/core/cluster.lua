










local act = require "core:core/cluster/actor"






local cluster = {}

for k, v in pairs(act) do
   cluster[k] = v
end















local sub = assert(string.sub)

local isempty = table.isempty
                or
                function(tab)
                   local empty = true
                   for _, __ in pairs(tab) do
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
      tab.__index = tab
      return setmetatable(tab, Meta)
   elseif Meta
      and type(Meta) == 'table'
      and isempty(Meta) then
      -- decorate
      Meta.__index = Meta
      return Meta
   elseif not Meta then
      local _M = {}
      _M.__index = _M
      return _M
   end
   error "cannot make metatable"
end











local function _bind(obj, fn)
  if not fn then return nil end
  return function(...)
     return fn(obj, ...)
  end
end

local function _get_idx(obj)
   local M = getmetatable(obj)
   return M and M.__index
end

function cluster.super(obj, field)
   local super_idx
   -- If the object has such a field directly, consider the implementation
   -- from the metatable to be the "super" implementation
   if rawget(obj, field) then
      super_idx = _get_idx(obj)
   -- Otherwise, look one step further up the inheritance chain
   else
      local M_idx = _get_idx(obj)
      super_idx = type(M_idx) == 'table' and _get_idx(M_idx) or nil
   end
   if super_idx then
      return type(super_idx) == 'table'
         and _bind(obj, super_idx[field])
         or  _bind(obj, super_idx(obj, field))
   end
   -- No superclass, or our class uses an __index function so we can't
   -- meaningfully figure out what to do
   return nil
end



return cluster

