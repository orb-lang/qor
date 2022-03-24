































local set, set_Build, set_M = {}, {}, {}
setmetatable(set, set_Build)


















function set_Build.__call(_new, tab)
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
   return setmetatable(tab, set_M)
end













function set_M.__call(set, ...)
   for i = 1, select('#', ...) do
      set[select(i, ...)] = true
   end
end



return set

