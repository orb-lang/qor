# Function Extensions


  Various methods to extend the functionality of functions and methods,
methodically\.

This is also the home of some core functions which are distinguished by their
actions, side effects, or affect on control flow, rather than by acting on
a specific data structure\.  Currently this is limited to `assertfmt`\.


#### imports

```lua
local _base = require "core:core/_base"
```


## fn table

```lua
local fn = {}
```


### fn\.no\_op

A function which does nothing and returns nothing \(rather than `nil`, which
takes a stack frame\)\.

```lua
fn.no_op = _base.no_op
```


### fn\.optionfirst\(\.\.\.\)

  This is a B\- name, but for functions which receive closures, it's really
best if they're the last argument, so that they can be literal without
obscuring the existence of other parameters\.

Many of these have optional arguments, so we want a general "make the last
argument the first and return them" function\.

```lua
function fn.optionfirst(...)
   local arg = pack(...)
   local top, rx = arg[arg.n], nil
   for i = arg.n, 2, -1 do
      arg[i] = arg[i - 1]
   end
   arg[1] = top
   return unpack(arg)
end
```


### curry\(fn, param\)

  Returns a function which pre\-applies the given parameter to the first
position of the function\.

We could simply do this naively, and LuaJIT being what it is, there's a decent
chance it would be optimized away\.

But I prefer to provide a guarantee that, for up to five parameters, there is
exactly one level of indirection involved\.

```lua
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
```


### thunk\(fn, \.\.\.\)

Returns a function which, called, will call the function with the given
arguments\.

```lua
fn.thunk = assert(_base.thunk)
```


### deferSend\(obj, msg, \.\.\.\)

Returns a function which, called, will pass the message and arguments to the
given object\.

That is, `deferSend(obj, "msg", a)` is the same as `thunk(obj.msg, obj, a)`,
just a more convenient way of expressing it\.

```lua
function fn.deferSend(obj, msg, ...)
   assert(type(obj) == 'table', "#1 to deferSend must be a table")
   assert(type(msg) == 'string', "#2 to deferSend must be a string")
   local packed = pack(...)
   return function()
      return obj[msg](obj, unpack(packed))
   end
end
```


### iscallable\(maybe\_fn\)

Returns true for a function, or a table with a `__call` metamethod\.

```lua
fn.iscallable = assert(_base.iscallable)
```


### partial\(fn, \.\.\.\)

Partial applicator: takes a function, and fills in the given arguments,
returning another function which accepts additional arguments:

```lua-example
add5 = fn.partial(function(a,b)
                  return a + b
               end, 5)
return add5(10) -- returns 15
```

This is just a convenience function, which repeatedly curries the given `fn`
until the parameters are consumed\.

```lua
function fn.partial(fn, ...)
   for i = 1, select('#', ...) do
      fn = curry(fn, select(i, ...))
   end
   return fn
end
```


### compose\(f, g\)

Returns a function which calls g on the result of calling f with arguments\.

```lua
function fn.compose(f, g)
   return function(...)
      return g(f(...))
   end
end
```

Note that we can and maybe should use the same detection technique we use for
currying, to unwrap intermediates, so that `compose(compose(f,g), h)` becomes
one function with the line `return h(g(f(...)))`\.


### itermap\(fn, iter\)

Applies `fn` to each element returned from `iter`, in turn\.

For a consistent interface, all return values are `pack`ed into one array
slot of a table, which is returned\.

```lua
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
```


### fn\.dynamic\(fn\)

Because functions are immutable, we can't replace all instances of a function,
at least not without trawling the entire program with the `debug` library
looking for upvalues and locals\.

`dynamic` sets up a closure, which uses a private attributes table to retrieve
the passed function and call it\.

We create a table as a lightweight unique to index the function with, and
provide a second method, `fn.patch_dynamic`, to change the underlying function
when desired\.

We use two tables for the registry, because we want the values of the
`_dynamics_call` table to retain a reference even if it's the only one, which
allows anonymous functions to be registered as dynamic or patched in\.

The net result is a unique function which can be swapped out in all places in
which it is used\.

```lua
local _dynamics_call = setmetatable({}, {__mode = 'k'})
local _dynamics_registry  = setmetatable({}, {__mode = 'kv'})

local function dynamic(fn)
   -- make a unique table as key
   local uid = {}
   _dynamics_call[uid] = fn
   local function dyn_fn(...)
      return _dynamics_call[uid](...)
   end
   _dynamics_registry[dyn_fn] = uid
   return dyn_fn
end

fn.dynamic = dynamic
```


### fn\.patch\_dynamic\(dyn\_fn, fn\)

Replaces the attribute function with the new function, and updates the table
accordingly\.

```lua
function fn.patch_dynamic(dyn_fn, fn)
   assert(_dynamics_registry[dyn_fn], "cannot patch a non-dynamic function")
   local uid = _dynamics_registry[dyn_fn]
   _dynamics_call[uid] = fn
end
```


### hookable\(fn\)

As we build out `helm`, I would like to be able to expose a rich API for
extensions, a la Emacs\.

One of the ways to do this is to expose functions with hooks: actions taken
before or after a given function\.

A hookable function is registered as a `dynamic` function\.  This means that
`patch_dynamic` can replace the core function\.  Note that if you pass an
already `dynamic` function to  `hookable`, you'll end up with a "double
dynamic" function, which might not be what you want\! `patch_dynamic` will do
different things to the original \(dynamic\) function and its hookable dynamic
cousin\.

We offer two hooks, `pre` and `post`, which are hooked with `fn.prehook` and
`fn.posthook`, respectively\.  Functions may be unhooked by calling
`fn.prehook(fn, nil)`, or the equivalent for a posthook\.

`pre` receives the same parameters, and must return parameters which are then
passed to the main function\.  These don't have to be the same parameters, but
certainly can be, if pre is called for side effects\.  This calling convention
gives `pre` a chance to modify the original values of the parameters\.

`post` receives the return values of the main function, if any, followed by
either the return parameters of `pre` or the main parameters, depending on if
there is a pre\-hook\.  So a function `f(a, b, c)` which returns `d` will call a
 post\-hook with `post_f(d, a, b, c)`\.  The reason for this calling convention
is that post\-hooks are primarily interested in what the function did, and may
also need to know how the function was called\.

Note that Lua has no concept of how many parameters are "supposed to" be
passed to a function, and from `pack`'s perspective there is a difference
between `return nil` and just `return`\.  So if `f(a, b, c)` sometimes returns
`d` and sometimes returns nothing with a bare `return` keyword, or just by
falling off the end of the function, then sometimes you will get `post_f(d, a,, and sometimes just `post_f(a, b, c)`\.  So it's important to design
hookable
b, c)` functions so that they return a consistent number of parameters in
all cases, padded with `nil`s if necessary\.  This is not idiomatic,
particularly for functions which return an optional second value under some
circumstances\.

Similarly, if one were to call `f(a, b, c, extra)`, and the function has no
concept of an `extra` parameter, this is silently ignored, but `(un)pack` will
provide the post\-hook with `f_post(d, a, b, c, extra)`\.  This is less
important, since `f_post` will also ignore it unless it happens to have an
optional parameter\.

The return values are the return values of `post` or the main function,
depending, so if the call site is relying on something to be `returned`, a
post\-hook should make sure to return that something\.

```lua
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
   local uid = {}
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
```


## Errors and asserts


### Assertfmt

This avoids doing concatenations and conversions on messages that we never
see in normal use\.

```lua
fn.assertfmt = _base.assertfmt
```

```lua
return fn
```
