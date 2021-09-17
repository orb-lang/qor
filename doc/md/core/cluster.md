# Cluster


One of the language\-development goals we have with the Bridge project is to
build and extend a Meta\-Object Protocol\.

That's cluster\.

#### imports

```lua
local act = require "core:core/cluster/actor"
```


## cluster

```lua
local cluster = {}

for k, v in pairs(act) do
   cluster[k] = v
end
```


## Identity and Membership


## Inheritance


### Meta

This is our default pattern for single inheritance with transference of
metamethods\.

```lua
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
```


## \_\_meta

The meta metatable\.

Index looks up symbol resolution, such that on a self\-indexed table, the
metafields and metamethods are available\.  While this is untrue of a table
in which `__index` does not point to itself\.

The cluster word `meta` will therefore post\-copy out of a table called
`__meta`, if such a metametatable should happen to exist as the rvalue of
the `__meta` field\.

Valid keys are only strings starting with a double underscore\.  Valid values
would tend to be best thought of as tables and functions, with booleans
playing their usual role\.  To put a point upon it, rules are not imposed here\.



### super\(field\)

  A mixin which allows for the accessing of a method up the inheritance chain
from the shadowed field\.

Invoked as `obj :super 'field' (params)`\.

```lua
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
```

```lua
return cluster
```
