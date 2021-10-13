# Actor

  A collection of useful functions for Actors\.

What constitutes an Actor in cluster, and therefore in bridge, is a work in
progress\.  It is a role, more than an interface or a specific type of object\.


## Premise

  One of the distinguishing characteristics of an Actor is that they are
singular\.

This means that only one reference to an Actor should exist, and only the
holder of that reference should call the Actor directly\.

Lua offers no way to enforce this, so we'll just have to be careful\.

Other communication must take place through various proxies\.  We have the
[Window](https://gitlab.com/special-circumstance/core/-/blob/trunk/doc/md/window/window.md), which offers a proxy table with fine\-grained
access to the underlying Actor's table, and the [mailbox](https://gitlab.com/special-circumstance/core/-/blob/trunk/doc/md/mailbox/mailbox.md),
a two\-way queue for message passing\.

There will inevitably be methods and functions useful in constructing and
implementing Actors\.  I have one so far, hence this module\.


#### \_base

```lua
local _base = require "core:_base"
local iscallable = assert(_base.iscallable)
```


## actor library

```lua
local act = {}
```


### act\.borrowmethod\(actor, method\)

  This function takes an Actor and a method, and returns a closure which a\)
will call the method with the Actor as the first parameter and b\) will not
retain a strong reference to the Actor\.

The method may be either a callable or a string\.  A callable is used directly,
and a string is used at call\-time to retrieve a method from the Actor and call
it\.

Both options are provided, because with the callable, it doesn't have to be an
actual method on a field of the Actor, and with the string, the method itself
can change and will still be called\.

We do this with an anonymous index table and a weak attribute table, which we
use to retrieve the Actor and method if they haven't gone out of scope\.

```lua
local __act_mth_attr = setmetatable({}, { __mode = 'kv' })

function act.borrowmethod(actor, method)
   assert(iscallable(method) or type(method) == 'string',
          "#2 for borrowmethod must be string or callable")
   local uid = {}
   __act_mth_attr[uid] = actor
   actor = nil
   if type(method) == 'string' then
      -- return a lookup function
      return function(...)
         local _actor = __act_mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return _actor[method](_actor, ...)
      end
   else
      -- return a direct-call function
      return function(...)
         local _actor = __act_mth_attr[uid]
         if not _actor then
            error "actor has gone out of scope"
         end
         return method(_actor, ...)
      end
   end
end
```


## act\.getter\(actor, slot\)

  Provides a closure which will return the value of the slot on the given
actor\.

```lua
local __act_getter_attr = setmetatable({}, { __mode = 'kv' })

function act.getter(actor, slot)
   local uid = {}
   __act_getter_attr[uid] = actor
   actor = nil
   return function()
             local _actor = __act_getter_attr[uid]
             if not _actor then
                error "actor has gone out of scope"
             end
             return _actor[slot]
          end
end
```


## act\.dispatchmethod\(actor, msg\)

```lua
local function dispatchmessage(actor, msg)
   local _cyc = {}

   local function _dispatch(actor, msg)
      -- detect potential cycles
      if _cyc[msg] then error "cycle in Message" end
      _cyc[msg] = true

      -- handle recursive case first
      if msg.message then
         actor :dispatchmessage(msg.message)
         return actor
      end

      if msg.sendto then
         actor = actor[msg.sendto]
      elseif msg.property then
         actor = actor[msg.property]
      elseif msg.call == true then
         actor = actor(unpack(msg))
      elseif msg.call then
         actor = actor[msg.call](unpack(msg))
      elseif msg.method then
         actor = actor[msg.method](actor, unpack(msg))
      else
         error("Message must have one of property, call, or method")
      end
   end

   _dispatch(actor, msg)

   return actor
end
```



```lua
return act
```
