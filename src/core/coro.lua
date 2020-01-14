



local coro = {}











local function pack(...)
   return { n = select('#', ...), ... }
end
coro.pack = pack
















local create, status, resume = coroutine.create,
                                coroutine.status,
                                coroutine.resume

function coro.safeWrap(f)
   local wrapped_fn = create(f)
   return function(...)
      if status(wrapped_fn) == "dead" then
         return nil
      else
         local success, a, b, c, d, e
         success, a, b, c, d, e =  resume(wrapped_fn, ...)
         if success then
            return a, b, c, d, e
         else
            error(a)
         end
      end
   end
end




return coro
