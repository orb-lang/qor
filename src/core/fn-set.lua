

















local FSet, FSet_m = {}, {}












local __add, __sub, __mod, __unm;







local __len;































local __eq, __lt, __lte;






















local function spread(fn)
   return function(_, a)
      return fn(a) and true or nil
   end
end



local function readonly(tab, key, val)
   error("can't assign " .. key .. " to a function set")
end

local function new(fn)
   local fset = setmetatable({}, { __index = spread(fn),
                                   __add = __add,
                                   __sub = __sub,
                                   __mod = __mod,
                                   __len = __len,
                                   __unm = __unm,
                                   -- comparators, negative
                                   __newindex = readonly, })
   return fset
end






__add = function(left, right)
   return new(function(elem)
      return left[elem] or right[elem]
   end)
end






__sub = function(left, right)
   return new(function(elem)
      return (left[elem] and (not right[elem])) or nil
   end)
end






__mod = function(left, right)
   return new(function(elem)
      return left[elem] and right[elem]
   end)
end






__unm = function(set)
   return new(function(elem)
      return (not elem) or nil
   end)
end








__len = function() error("can't take the length of a function set") end



return new

