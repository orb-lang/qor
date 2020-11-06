



























local _base = require "core:core/_base"












local fn = {}


















fn.thunk = assert(_base.thunk)
































function fn.partial(fn, ...)
   local args = pack(...)
   return function(...)
      return fn(unpack(args, 1, args.n), ...)
   end
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

