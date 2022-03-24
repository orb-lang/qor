































local set, set_Build, set_M = {}, {}, {}
setmetatable(set, set_Build)


















function set_Build.__call(_new, tab)
   tab = tab or {}
   assert(type(tab) == 'table', "#1 to Set must be a table or nil")
   for i, v in ipairs(tab) do
      tab[v] = true
      tab[i] = nil
   end
   return setmetatable(tab, set_M)
end













function set_M.__call(set, ...)
   for i = 1, select('#', ...) do
      set_M[select(i, ...)] = true
   end
end



return set

