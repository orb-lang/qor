













local _base = require "qor:core/_base"
local unique = assert(_base.unique)













local function is_fn(_, fn)
   return type(fn) == 'function'
end



local fn = setmetatable({}, { __call = is_fn })









fn.no_op = _base.no_op













function fn.optionfirst(...)
   local arg = pack(...)
   local top, rx = arg[arg.n], nil
   for i = arg.n, 2, -1 do
      arg[i] = arg[i - 1]
   end
   arg[1] = top
   return unpack(arg)
end















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

local function curry(fn, param)
   assert(type(fn) == 'function' or
          type(fn) == 'table' and getmetatable(fn).__call,
          '#1 of curry must be a function or callable table')
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

fn.curry = curry









fn.thunk = assert(_base.thunk)












function fn.deferSend(obj, msg, ...)
   assert(type(obj) == 'table', "#1 to deferSend must be a table")
   assert(type(msg) == 'string', "#2 to deferSend must be a string")
   local packed = pack(...)
   return function()
      return obj[msg](obj, unpack(packed))
   end
end








fn.iscallable = assert(_base.iscallable)



















function fn.partial(fn, ...)
   for i = 1, select('#', ...) do
      fn = curry(fn, select(i, ...))
   end
   return fn
end








function fn.compose(f, g)
   return function(...)
      return g(f(...))
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

local function dynamic(fn)
   -- make a unique as key
   local uid = unique()
   _dynamics_call[uid] = fn
   local function dyn_fn(...)
      return _dynamics_call[uid](...)
   end
   _dynamics_registry[dyn_fn] = uid
   return dyn_fn
end

fn.dynamic = dynamic

















function fn.patch_dynamic(dyn_fn, fn)
   assert(_dynamics_registry[dyn_fn], "cannot patch a non-dynamic function")
   local uid = _dynamics_registry[dyn_fn]
   _dynamics_call[uid] = fn
end
























































local _pre_hook, _post_hook = setmetatable({}, {__mode = 'k'}),
                              setmetatable({}, {__mode = 'k'})

local function _call_with_hooks(uid, ...)
   local fn = _dynamics_call[uid]
   assert(fn, "_dynamics_call is missing a hookable function")
   local pre, post = _pre_hook[uid], _post_hook[uid]

   if pre and post then
      local new_arg = pack(pre(...))
      local rets = pack(fn(unpack(new_arg)))
      -- make into one pack, because you can only apply multiple arguments at
      -- the end of a function call
      for i = 1, new_arg.n do
         rets[#rets + 1] = new_arg[i]
      end
      rets.n = new_arg.n + rets.n
      return post(unpack(rets))
   elseif pre then
      return fn(pre(...))
   elseif post then
      local args, rets = pack(...), pack(fn(...))
      -- same trick here...
      for i = 1, rets.n do
         args[#args + 1] = rets[i]
      end
      args.n = rets.n + args.n
      return post(unpack(args))
   else
      return fn(...)
   end
end

local function prehook(hooked, pre_hook)
   _pre_hook[_dynamics_registry[hooked]] = pre_hook
end

local function posthook(hooked, post_hook)
   _post_hook[_dynamics_registry[hooked]] = post_hook
end

fn.prehook, fn.posthook = prehook, posthook

function fn.hookable(fn, pre, post)
   -- make a uid, add to _dynamics_call
   local uid = unique()
   _dynamics_call[uid] = fn
   local hookable = function(...)
                       return _call_with_hooks(uid, ...)
                    end
   -- register the hookable in the dynamics registry
   _dynamics_registry[hookable] = uid
   if pre then
      prehook(hookable, pre)
   end
   if post then
      posthook(hookable, post)
   end
   return hookable
end












fn.assertfmt = _base.assertfmt



return fn

