# Math/number extensions

```lua
local Math = {}
for k, v in pairs(math) do
   Math[k] = v
end
```


### Math\.inbounds\(value, lower, upper\)

Checks if `value` is in bounds in the range `lower..upper`, inclusive\. Either
bound may be omitted, in which case no checking is performed on that end\.

```lua
function Math.inbounds(value, lower, upper)
  if lower and value < lower then
    return false
  end
  if upper and value > upper then
    return false
  end
  return true
end
```


### Math\.flip\(\)

Conditional wrapper over random\.

```lua
local random = assert(math.random)

function Math.flip()
   if random(2) == 1 then
      return true
   else
      return false
   end
end
```


### Math\.isposint\(num\): i | nil

Returns `num` iff positive and integer, otherwise `nil`\.

```lua
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
```


### Math\.posint\(num: Any\): i | Error

An error\-raising wrapper for `isposint`\.

```lua
function Math.posint(num)
   return assert(isposint(num))
end
```


### Math\.clamp\(value, lower, upper\)

Returns `value` if `value` is `inbounds` of `(lower, upper)`\. If greater
or lesser than that interval, returns `upper` or `lower`, respectively\.
If upper is less than lower, raises an error \(`upper == lower` is fine\)\.

```lua
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
```


```lua
return Math
```
