

















local FSet, FSet_m = {}, {}












local __add, __sub, __mod;















local function spread(fn)
   return function(_, a)
      return fn(a)
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
                                   __newindex = readonly })
   return fset
end






__add = function(left, right)
   local pred = function(elem)
      return left[elem] or right[elem]
   end
   return new(pred)
end






__sub = function(left, right)
   local pred = function(elem)
      return (left[elem] and (not right[elem])) or nil
   end
   return new(pred)
end






__mod = function(left, right)
   local pred = function(elem)
      return left[elem] and right[elem]
   end
   return new(pred)
end




return new

