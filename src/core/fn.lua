













local _base = require "core:core/_base"






local fn = {}















local _curried = setmetatable({}, { __mode = 'k' })

local currier = {
   false, -- this shouldn't happen
   function(fn, a, b) -- [2]
      return function(...)
         return fn(a, b, ...)
      end
   end,
   function(fn, a, b, c) -- [3]
      return function(...)
         return fn(a, b, c, ...)
      end
   end,
   function(fn, a, b, c, d) -- [4]
      return function(...)
         return fn(a, b, c, d, ...)
      end
   end,
   function(fn, a, b, c, d, e) -- [5]
      return function(...)
         return fn(a, b, c, d, e, ...)
      end
   end,
}

function fn.curry(fn, param)
   assert(type(fn) == 'function', '#1 of curry must be a function')
   local curried;
   local pre = _curried[fn]
   if not pre then
      curried = function(...) return fn(param, ...) end
      _curried[curried] = { param, n = 1 , fn = fn }
   else
      if pre.n <= 4 then
         local post = {}
         for i = 1, pre.n do
            post[i] = pre[i]
         end
         post.n = pre.n + 1
         post.fn = pre.fn
         post[post.n] = param
         curried = currier[post.n](post.fn, unpack(post, 1, post.n))
         _curried[curried] = post
      else
         curried = function(...) return fn(param, ...) end
      end
   end

   return curried
end










fn.thunk = assert(_base.thunk)
















local function _unpacker(fn, args)
   return function(...)
      -- clone args
      local call = {}
      for i = 1, args.n do
         call[i] = args[i]
      end
      call.n = args.n
      -- add new args from ...
      for i = 1, select('#', ...) do
         call.n = call.n + 1
         call[call.n] = select(i, ...)
      end
      return fn(unpack(call, 1, call.n))
   end
end

function fn.partial(fn, ...)
   local args = pack(...)
   return _unpacker(fn, args)
end











function fn.itermap(fn, iter)
   local ret, res = {}
   while true do
      res = pack(fn(iter()))
      if #res == 0 then
         return ret
      else
         ret[#ret + 1] = res
      end
   end
end
























local _dynamics_call = setmetatable({}, {__mode = 'k'})
local _dynamics_registry  = setmetatable({}, {__mode = 'kv'})

function fn.dynamic(fn)
   -- make a unique table as key
   local uid = {}
   local function dyn_fn(...)
      return _dynamics_call[uid](...)
   end
   _dynamics_call[uid] = fn
   _dynamics_registry[dyn_fn] = uid
   return dyn_fn
end









function fn.patch_dynamic(dyn_fn, fn)
   assert(_dynamics_registry[dyn_fn], "cannot patch a non-dynamic function")
   local uid = _dynamics_registry[dyn_fn]
   _dynamics_call[uid] = fn
end




































local _hooks = setmetatable({}, {__mode = "k"})

local function hookable_newindex()
   error "Attempt to assign value to a hookable function"
end

local function call_with_hooks(hooked, fn, ...)
   local pre, post = _hooks[hooked].pre, _hooks[hooked].post

   if pre and post then
      local new_arg = pack(pre(...))
      return post(fn(unpack(new_arg)), unpack(new_arg))
   elseif pre then
      return fn(pre(...))
   elseif post then
      return post(fn(...), ...)
   else
      return fn(...)
   end
end

local function hookPre(hooked, pre_hook)
   _hooks[hooked].pre = pre_hook
end

local function hookPost(hooked, post_hook)
   _hooks[hooked].post = post_hook
end

local function unhookPre(hooked)
   _hooks[hooked].pre = nil
end

local function unhookPost(hooked)
   _hooks[hooked].post = nil
end

local hook_index = { hookPre    =  hookPre,
                     hookPost   =  hookPost,
                     unhookPre  =  unhookPre,
                     unhookPost =  unhookPost }

function fn.hookable(fn, pre, post)
   local hook_m = { __newindex = hookable_newindex,
                    __index    = hook_index,
                    __call = function(hooked, ...)
                                return call_with_hooks(hooked, fn, ...)
                             end }
   local hooked = setmetatable({}, hook_m)
   local hook_attr = { pre = pre, post = post }
   _hooks[hooked] = hook_attr
   return hooked
end















fn.assertfmt = _base.assertfmt



return fn

