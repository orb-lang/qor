








local cluster = {}















local sub = assert(string.sub)

local isempty = table.isempty
                or
                function(tab)
                   local count = 0
                   for _,__ in pairs(tab) do
                      count = count + 1
                   end
                   return count == 0
                end

function cluster.meta(Meta)
   if Meta and Meta.__index then
      -- inherit
      local tab = {}
      for field, value in next, Meta, nil do
         if sub(field, 1, 2) == "__" then
            tab[field] = value
         end
      end
      setmetatable(tab, Meta)
      tab.__index = tab
      return tab
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



return cluster
