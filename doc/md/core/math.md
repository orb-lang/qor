# Math/number extensions

```lua
local Math = {}
```
### Math.inbounds(value, lower, upper)

Checks if a value is in bounds in the range lower..upper, inclusive. Either
bound may be omitted, in which case no checking is performed on that end.

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
### Math.bound(value, lower, upper)

As ``inbounds``, but answers a value constrained to be within the specified range.

```lua
function Math.bound(value, lower, upper)
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
