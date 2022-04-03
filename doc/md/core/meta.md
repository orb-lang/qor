# Metatable Extensions


  Extensions to metatables\.

Right now this isn't well\-organized, and I need to change that\.

But I have to do it carefully, because `meta` touches the code all over the
place, and even though it's almost identical to `Meta` in [cluster](NO default.domain IN MANIFESTqor/MISSING_POST_PROJECTdoc/md/core/cluster.md), it might break something to just replace it\.

When the refactor is complete, this will be functions acting on metatables,
not using them to implement cluster, which is the extensions to the
Meta\-Object protocols which we use to implement the bridge object and actor
systems\.


#### imports

Just `_base`, which is the only valid import for a `core` module\.

```lua
local _base = require "core:core/_base"
```


## meta library

```lua
local meta = {}
```


### meta\.meta

One of many metas, and this one I hope not in use\.

We'll find out quick:

```lua
function meta.meta(MT, tab)
   error "this is no longer provided"
end
```


### metatables\(tab\)

  Returns an iterator over all metatables of the table\.

This corrects an important and pervasive bug in our code, one which has never
yet shown up but is there nonetheless\.

Because of the `__metatable` metamethod, a call to `getmetatable` can return
literally anything\.  We assume, wrongly, that this return value will be either
a table or falsey, and `metatables` will not try and correct for this: if a
`__metatable` method returns something that isn't a table or `false`, we
return it\.

What the `metatables` iterator does is cycle checking, and when it finds one
it returns `nil`\.

```lua
function meta.metatables(tab)
   local dupes = { tab = true }
   local _M = tab
   return function()
      _M = getmetatable(_M)
      if (_M == nil) or dupes[_M] then return nil end
      dupes[_M] = true
      return _M
   end
end
```


### hasmetamethod\(mmethod, tab\)

Given a table, return a metamethod if present, otherwise, return `false` or
`nil`\.

This is slightly magical, in that you can leave off the `"__"` in the name
of the metamethod\.

This could be enhanced to work the same way as `hasfield`, so that
=hasmetamethod\.index\(tab\) returns the index if the table has an "\_\_index"
metamethod\.

I've made the parameter order identical to `hasfield` so as to make this
practical; for now, it's a bit of fiddling around for little benefit\.

This method accepts that any `__` field on the metatable is a metamethod,
either a native one or a custom extension\.  It certainly should be\.

```lua
local sub = assert(string.sub)

local function hasmetamethod(mmethod, tab)
   assert(type(mmethod) == "string", "metamethod must be a string")
   local M = getmetatable(tab)
   if not M then
      return false
   end
   if sub(mmethod,1,2) == "__" then
      return rawget(M, mmethod)
   else
      return rawget(M, "__" .. mmethod)
   end
end

meta.hasmetamethod = hasmetamethod
```


### instanceof\(obj, Class\)

  Answers whether `obj` is an "instance of" `Class`, which may be either the
name of a builtin type \("number", "string", etc\), or a module return value
which will be compared against `obj.idEst`\.

```lua
function meta.instanceof(obj, Class)
   if type(Class) == 'string' then
      return type(obj) == Class
   else
      return type(obj) == 'table' and obj.idEst == Class
   end
end
```



### weak\(mode\)

Simplifies the drudgery of constructing basic weak tables\.

Mode defaults to `'kv'`\.

```lua
function meta.weak(mode)
   mode = mode or 'kv'
   return setmetatable({}, { __mode = mode })
end
```

```lua
return meta
```
