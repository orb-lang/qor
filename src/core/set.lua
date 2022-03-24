































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






function Set.remove(set, ...)

end



local wrap, yield = assert(coroutine.wrap), assert(coroutine.yield)
local tabulate, Token

function Set_M.__repr(set, window, c)
   tabulate = tabulate or require "repr:tabulate"
   Token = Token or require "repr:token"

   return wrap(function()
      yield(Token("#{ ", { color = "base", event = "array"}))
      local first = true
      window.depth = window.depth + 1
      for v, _ in pairs(set) do
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

