


local Math = {}
for k, v in pairs(math) do
   Math[k] = v
end









function Math.inbounds(value, lower, upper)
  if lower and value < lower then
    return false
  end
  if upper and value > upper then
    return false
  end
  return true
end








local random = assert(math.random)

function Math.flip()
   if random(2) == 1 then
      return true
   else
      return false
   end
end








local floor = assert(math.floor)

local function isposint(arg)
   if type(arg) ~= 'number' then
      return nil, "not a number"
   elseif arg <= 0 then
      return nil, "not positive"
   elseif floor(arg) ~= arg then
      return nil, "not integer"
   else
      return arg
   end
end

Math.isposint = isposint








function Math.posint(num)
   return assert(isposint(num))
end










local assertfmt = assert(require "core:_base" . assertfmt)
function Math.clamp(value, lower, upper)
   if lower and upper then
      assertfmt(lower <= upper, "Clamp range must be nonempty (lower <= upper), got (%d, %d)", lower, upper)
   end
   if lower and value < lower then
      value = lower
   end
   if upper and value > upper then
      value = upper
   end
   return value
end




return Math

