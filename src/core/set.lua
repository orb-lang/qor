































local core = require "qor:core"
local Set, Set_Build, Set_M = {}, {}, {}
setmetatable(Set, Set_Build)


















function Set_Build.__call(_new, tab)
   assert(type(tab) == 'table' or not tab, "#1 to Set must be a table or nil")
   tab = tab or {}
   local top = #tab
   local shunt;  -- we need this for number keys
   for i = 1, top do
      local v = tab[i]
      if type(v) == 'number' then
         shunt = shunt or {}
         shunt[v] = true
      else
         tab[v] = true
      end
      tab[i] = nil
   end
   if shunt then
      for v in pairs(shunt) do
         tab[v] = true
      end
   end
   return setmetatable(tab, Set_M)
end


















function Set_M.__call(set, ...)
   error
     "don't use Set(...) to mutate until we can warn about =if Set(elem)!="
   for i = 1, select('#', ...) do
      set[select(i, ...)] = true
   end
end

Set.insert = Set_M.__call




















function Set_M.__newindex(set, key, value)
   assert(value == true or value == nil, "value must be true or nil")
   rawset(set, key, value)
end














insert = assert(table.insert)
function Set.remove(set, ...)
   local removed;
   for i = 1, select('#', ...) do
      local elem = select(i, ...)
      if set[elem] then
         removed = removed or {}
         insert(removed, elem)
         set[elem] = nil
      end
   end
   if removed then
      return(unpack(removed))
   end
end


















Set_M.__len = assert(table.nkeys)




















local function _fix(tab)
   if getmetatable(tab) == Set_M then
      return tab, true
   else
      return Set(tab), false
   end
end

local function _binOp(left, right)
   local l_p, r_p;
   left, l_p = _fix(left)
   right, r_p = _fix(right)
   return left, right, l_p, r_p
end















local F__add = getmetatable(require "qor:core/fn-set"()) . __add



local function isFset(maybe)
   local _M = getmetatable(maybe)
   if _M and _M.__add == F__add then
      return true
   else
      return false
   end
end






local clone = assert(require "table.clone")

function Set_M.__add(left, right)
   -- Set union is commutative, but we need to clone to prevent subsequent
   -- mutation from changing the semantics
   if isFset(right) then
      return right + clone(left)
   end
   local l_isSet, r_isSet;
   left, right, l_isSet, r_isSet = _binOp(left, right)
   local set, other;
   if #left > #right then
      if l_isSet then
         set = clone(left)
      else
         set = left
      end
      other = right
   else
      if r_isSet then
         set = clone(right)
      else
         set = right
      end
      other = left
   end

   for elem in pairs(other) do
      set[elem] = true
   end
   return setmetatable(set, Set_M)
end








function Set_M.__sub(left, right)
   left, right =  _binOp(left, right)
   local set = {}
   for k in pairs(left) do
      if not right[k] then
         set[k] = true
      end
   end
   return setmetatable(set, Set_M)
end













function Set_M.__mod(left, right)
   left, right = _binOp(left, right)
   local set = {}
   for elem in pairs(left) do
      if right[elem] then
         set[elem] = true
      end
   end
   return setmetatable(set, Set_M)
end











local function not_missing(left, right)
   for elem in pairs(left) do
      if not right[elem] then
         return false
      end
   end
   return true
end



function Set_M.__eq(left, right)
   if not #left == #right then return false end
   return not_missing(left, right)
end








function Set_M.__lt(left, right)
   if #left >= #right then return false end
   return not_missing(left, right)
end









local wrap, yield = assert(coroutine.wrap), assert(coroutine.yield)
local tabulate, Token
local sortedpairs = assert(core.table.sortedpairs)

function Set_M.__repr(set, window, c)
   tabulate = tabulate or require "repr:tabulate"
   Token = Token or require "repr:token"
   if #set == 0 then
      -- we have a name for this
      local sent = false
      return function()
         if not sent then
            sent = true
            local empty = "#{" .. c.table('∅') .. "}"
            return empty
         end
      end
   end

   return wrap(function()
      yield(Token("#{ ", { color = "base", event = "array"}))
      local first = true
      window.depth = window.depth + 1
      for v, _ in sortedpairs(set) do
         if first then
            first = false
         else
            yield(Token(", ", { color = "base", event = "sep" }))
         end
         for t in tabulate(v, window, c) do
            yield(t)
         end
      end
      window.depth = window.depth - 1
      yield(Token(" }", { color = "base", event = "end" }))
   end)
end














return Set

