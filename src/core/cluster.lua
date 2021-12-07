










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
                   for _, __ in next, tab, nil do
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
      if Meta.__meta then
         tab.__meta = tab.__meta or {}
         for _, __ in next, Meta.__meta, nil do
            tab.__meta[_] = __
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
   error ("cannot make metatable from type" .. type(Meta))
end































function cluster.constructor(mt, new, instance)
   instance = instance or {}
   if new then
      mt.__call = new
   elseif not mt.__call then
      error "nil metatable passed to constructor without __call metamethod"
   end

   local constructor = setmetatable(instance, mt)
   mt.idEst = constructor
   return constructor
end

















<<<<<<< HEAD
local insert, remove = assert(table.insert), assert(table.remove)


function cluster.methodchain(method)

   local value_catch = {}
   local remove = assert(table.remove)

   local function value__call(value_catch, value, ...)
      method(value_catch[1], value_catch[2], value, ...)
      value_catch[2] = nil
      return remove(value_catch)
   end

   setmetatable(value_catch, { __call = value__call })

   return function (obj, first)
      insert(value_catch, obj)
      insert(value_catch, first)
      return value_catch
   end
end













function cluster.indexafter(idx_fn, idx_super)
   if type(idx_super) == 'table' then
      return function(tab, key)
         local val = idx_fn(tab, key)
         if val then
            return val
         else
            return idx_super[key]
         end
      end
   elseif type(idx_super) == 'function' then
      return function(tab, key)
         local val = idx_fn(tab, key)
         if val then
            return val
         else
            return idx_super(tab,key)
         end
      end
   end
end

















local _instances = setmetatable({}, { __mode = 'k'})

function cluster.instancememo(instance, message)
   local memos = { [message] = {} }
   -- grab the method, we're going to need it later
   local method = instance[message]
   _instances[instance] = memos
   local function memo_method(inst, p, ...)
      local param_set = assert(_instances[inst][message],
                             "missing instance or message")
      local results = param_set[p]
      if results then return unpack(results) end

      results = pack(method(inst, p, ...))
      param_set[p] = results
      return unpack(results)
   end
   instance[message] = memo_method
end













||||||| de8f75e
=======
local insert, remove = assert(table.insert), assert(table.remove)


function cluster.methodchain(method)

   local value_catch = {}
   local remove = assert(table.remove)

   local function value__call(value_catch, value, ...)
      method(value_catch[1], value_catch[2], value, ...)
      value_catch[2] = nil
      return remove(value_catch)
   end

   setmetatable(value_catch, { __call = value__call })

   return function (obj, first)
      insert(value_catch, obj)
      insert(value_catch, first)
      return value_catch
   end
end












function cluster.indexafter(idx_fn, idx_super)
   if type(idx_super) == 'table' then
      return function(tab, key)
         local val = idx_fn(tab, key)
         if val then
            return val
         else
            return idx_super[key]
         end
      end
   elseif type(idx_super) == 'function' then
      return function(tab, key)
         local val = idx_fn(tab, key)
         if val then
            return val
         else
            return idx_super(tab,key)
         end
      end
   end
end

















local _instances = setmetatable({}, { __mode = 'k'})

function cluster.instancememo(instance, message)
   local memos = { [message] = {} }
   -- grab the method, we're going to need it later
   local method = instance[message]
   _instances[instance] = memos
   local function memo_method(inst, p, ...)
      local param_set = assert(_instances[inst][message],
                             "missing instance or message")
      local results = param_set[p]
      if results then return unpack(results) end

      results = pack(method(inst, p, ...))
      param_set[p] = results
      return unpack(results)
   end
   instance[message] = memo_method
end













>>>>>>> key-value-builder


















--| if =fn= exists, bind fn(obj, ...)
local function _maybe_bind(obj, fn)
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
         and _maybe_bind(obj, super_idx[field])
         or  _maybe_bind(obj, super_idx(obj, field))
   end
   -- No superclass, or our class uses an __index function so we can't
   -- meaningfully figure out what to do
   return nil
end




return cluster

