







local uv = require "luv"



local thread = {}




































local select       = select
local setmetatable = setmetatable
local create       = coroutine.create
local isyieldable  = coroutine.isyieldable -- luacheck: ignore
local resume       = coroutine.resume
local running      = coroutine.running
local status       = coroutine.status
local wrap         = coroutine.wrap
local yield        = coroutine.yield








local _tagged = setmetatable({}, {__mode = 'kv'})

local str_tags = setmetatable({}, {__mode = 'v'})






function thread.nest(tag)











  if type(tag) == 'string' then
     local _tag = str_tags[tag] or {}
     str_tags[tag] = _tag
     tag = _tag
  end

  tag = tag or {}

  if _tagged[tag] then
     return _tagged[tag]
  end










  local coroutine = {
    isyieldable = isyieldable,
    running     = running,
    status      = status,
  }

  _tagged[tag] = coroutine








  function coroutine.create (f)
    return create (function (...)
      return tag, f (...)
    end)
  end


  function coroutine.yield (...)
    return yield (tag, ...)
  end















  local function for_resume (co, ok, ...)
    if not ok then
      return ok, ...
    elseif tag == ... then
      return ok, select (2, ...)
    else
      return for_resume (co, resume (co, yield (...)))
    end
  end

  function coroutine.resume (co, ...)
    return for_resume (co, resume (co, ...))
  end
































  local function for_wrap (co, ...)
    if tag == ... then
      return select (2, ...)
    else
      return for_wrap (co, co (yield (...)))
    end
  end

  function coroutine.wrap (f)
    local co = wrap (function (...)
      return tag, f (...)
    end)
    return function (...)
      return for_wrap (co, co (...))
    end
  end






  return coroutine
end













function thread.onloop()
   local _, main = running()
   return main and uv.loop_alive()
end













function thread.canyield(...)
   local _, main = running()
   if not main then
      yield(...)
   else
      return ...
   end
end



return thread

