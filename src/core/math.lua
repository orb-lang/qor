


local Math = {}








function Math.inbounds(value, lower, upper)
  if lower and value < lower then
    return false
  end
  if upper and value > upper then
    return false
  end
  return true
end







function Math.clamp(value, lower, upper)
  if lower and value < lower then
    value = lower
  end
  if upper and value > upper then
    value = upper
  end
  return value
end




return Math
