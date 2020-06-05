# Metatable Extensions


```lua
local meta = {}
```


## Meta Object Protocol

This is where we start to design Cluster\.

We shorten a few of the common Lua keywords: `coro` rather than `coroutine`,
and `getmeta` and `setmeta` over `getmetatable` and `setmetatable`\.

### meta

In my code there is a repeated pattern of use that is basic enough that I'm
entering it into the global namespace as simple `meta`\.

```lua
function meta.meta(MT, tab)
   tab = tab or {}
   if MT and MT.__index then
      -- inherit
      return setmetatable(tab, MT)
   elseif MT then
      -- decorate
      MT.__index = MT
      return MT
   else
      -- new metatable
      local _M = tab
      _M.__index = _M
      return _M
   end
end
```


### inherit\(meta\)

I may yet regret this\.

But I use this inheritance pattern throughout Nodes, along with Export,
and I've sprayed duplicates of this method across the orb codebase\.

It needs to live somewhere\. So here it is\.

\- \#params

  \- meta : the metatable to inherit from\.



```lua
function meta.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
```


### export\(mod, constructor\)

`export` is traditionally called at the end of a module to make a
functionalized table\.

This is\.\.\. sometimes the right thing to do\. sometimes\.

\- \#params

  \- mod :  The module metatable
  \- constructor :  A function, called =new=, which receives =mod= as the
                   first parameter\.

```lua
function meta.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
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

### endow\(Meta\)

Performs a thick copy of the metatable\.

Because this will include \_\_index and the like, this folds an level of
indirection out of inheritance\.

I plan to use this with Nodes when I make a single base class for a complex
Grammar\.

```lua
local pairs = assert(pairs)

function meta.endow(Meta)
   local MC = {}
   for k, v in pairs(Meta) do
      MC[k] = v
   end
   return MC
end
```

That's just a shallow clone, the subtlety is that if the \_\_index was a
self\-table, it now points to `Meta`, while if Meta was created through
endowment or inheritance it's now out of the picture\.

### instanceof\(obj, Class\)

Answers whether `obj` is an "instance of" `Class`, which may be either the
name of a builtin type \("number", "string", etc\), or a module return value
which will be compared against `obj.idEst`\.

```lua
function meta.instanceof(obj, Class)
   if type(Class) == "string" then
      return type(obj) == Class
   else
      return type(obj) == "table" and obj.idEst == Class
   end
end
```

```lua
return meta
```
