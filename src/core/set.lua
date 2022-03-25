































local core = require "qor:core"
local Set, Set_Build, Set_M = {}, {}, {}
setmetatable(Set, Set_Build)


















function Set_Build.__call(_new, tab)
   assert(type(tab) == 'table', "#1 to Set must be a table or nil")
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


















local nkeys = assert(table.nkeys)

function Set_M.__len(set)
   return nkeys(set)
end
















local function _fix(tab)
   if getmetatable(tab) == Set_M then
      return tab
   else
      return new(tab)
   end
end

local function _binOp(left, right)
   return _fix(left), _fix(right)
end






local clone = assert(require "table.clone")

function Set_M.__add(left, right)
   left, right = _binOp(left, right)
   local set, other;
   if #left > #right then
      set = clone(left)
      other = right
   else
      set = clone(right)
      other = left
   end

   for elem in pairs(other) do
      set[elem] = true
   end
   return setmetatable(set, Set_M)
end













local wrap, yield = assert(coroutine.wrap), assert(coroutine.yield)
local tabulate, Token
local sortedpairs = assert(core.table.sortedpairs)

function Set_M.__repr(set, window, c)
   tabulate = tabulate or require "repr:tabulate"
   Token = Token or require "repr:token"

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

