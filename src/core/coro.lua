


local coro = {}




local _base = require "core:core/_base"
local thunk = assert(_base.thunk)









local coro = {}
for k,v in next, coroutine do
   coro[k] = v
end















local create, status, resume = assert(coroutine.create),
                               assert(coroutine.status),
                               assert(coroutine.resume)

local remove = assert(table.remove)

function coro.safewrap(f)
   local wrapped_fn = create(f)
   return function(...)
      if status(wrapped_fn) == 'dead' then
         return nil, "cannot resume dead coroutine inside safewrap"
      else
         local rets  =  pack(resume(wrapped_fn, ...))
         if rets[1] then
             return unpack(rets, 2, rets.n)
         else
            return nil, rets[2]
         end
      end
   end
end









































local wrap = assert(coroutine.wrap)

function coro.wrapgen(fn, ...)
   local body = thunk(fn, ...)
   return function()
      return wrap(body)
   end
end








function coro.cogen(fn, ...)
   local body = thunk(fn, ...)
   return function()
      return create(body)
   end
end




















function coro.fire(co, ...)
   local cotype = type(co)
   if cotype == 'thread' then
      -- check the status
      if status(co) == 'dead' then
         return nil, "fire cannot resume dead coroutine"
      end
      local rets = pack(resume(co, ...))
      if rets[1] == true then
         remove(rets, 1)
         rets.n = rets.n -1
         return unpack(rets)
      elseif rets[1] == false then
         return nil, rets[2]
      end
   elseif cotype == 'function' then
      return co(...)
   else
      error("cannot fire on a " .. cotype)
   end
end




return coro

