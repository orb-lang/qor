# Set

  A fundamental data structure for any language\.

In Lua, the natural pattern for making a set is simply

```lua
stooge =  { "larry" = true, "moe" = true, "curly" = true }

if stooge["larry"] then
   print "nyuk nyuk nyuk"
end
```

Which invites a certain amount of common behavior to eliminate verbosity\.

Our first implementation stores Sets in this fashion, but also had methods,
with the obvious \(in retrospect\!\) flaw that if the method name were to be a
member of the Set, then that method becomes shadowed\.

The subsequent implementation uses indirection to prevent this, while
maintaining the methods, but we lost the ability to index a Set to test
membership\.  Instead we would call it a la `stooge("larry")`, which works,
ok, but it isn't idiomatic Lua\.

This time, no methods, only metamethods, and we use a callable constructor
library for the infrequent occasions when we need to do a Set operation we
can't represent through operators and metasyntax\.

The collection of tables we build this with is a bit bespoke:

```lua
local core = require "qor:core"
local Set, Set_Build, Set_M = {}, {}, {}
setmetatable(Set, Set_Build)
```

Since we do *not* want any \_\_indexing on our instances, and we have different
semantics for \_\_call on the library and on the instance\.


### Set\(tab?\) \-> Set

  Half of the point of a dedicated Set is to allow the above set to be written
more compactly as `Set {"larry", "curly", "moe"}`\.

Our constructor examines one argument, which must be `nil` or a table\.  If a
table, *that table* is used to construct the Set, which must be kept in mind
if, for example, one wants to use a common table to build up several Sets\.

The technique for that is found in the next section\.

```lua
function Set_Build.__call(_new, tab)
   assert(type(tab) == 'table', "#1 to Set must be a table or nil")
   local top = #tab
   local shunt;  -- we need this for number keys
   for i = 1, top do
      local v = tab[i]
      if type(v) == 'number' then
         shunt = shunt or {}
         shunt[v] = true
      else
         tab[v] = true
      end
      tab[i] = nil
   end
   if shunt then
      for v in pairs(shunt) do
         tab[v] = true
      end
   end
   return setmetatable(tab, Set_M)
end
```


### set\(\.\.\.\) \->, aka Set\.insert

  Calling a set adds all the elements to the Set\.  As is normal with inserting
into tables, we do not return the set\.

So to reuse an array table in several sets, `unpack` it into a call on the
Set you're setting up\.

There are only two ways to add elements to sets, and this is one, with the
only other mutable operation being `set.remove(set, ...)`\.

```lua
function Set_M.__call(set, ...)
   for i = 1, select('#', ...) do
      set[select(i, ...)] = true
   end
end

Set.insert = Set_M.__call
```


### set\[index\] = true

The other way to add elements is to set them to `true`\.

We make sure the user doesn't *initially* set values to anything but `true`,
but `__newindex` only applies to missing values, so elements can be set to
anything the user cares to, including `nil`, which is the only other intended
revalue\.

We use truthiness rather than boolean truth, so this is reasonably forgiving
of storing unexpected values for Set elements\.  We're striking the right
balance between simplicity, speed, and correctness here\.

Be that as it may, I urge the user to restrict values in Set tables to `true`
or `nil`\.

```lua
function Set_M.__newindex(set, key, value)
   assert(value == true or value == nil, "value must be true or nil")
   rawset(set, key, value)
end
```


### Set\.remove\(set, \.\.\.\) \-> removed\_elements : any

Removes any elements which are in the set, returning all the removed elements
in the parameter order, but with no `nil` values for elements which were not
removed\.

```lua
insert = assert(table.insert)
function Set.remove(set, ...)
   local removed;
   for i = 1, select('#', ...) do
      local elem = select(i, ...)
      if set[elem] then
         removed = removed or {}
         insert(removed, elem)
         set[elem] = nil
      end
   end
   if removed then
      return(unpack(removed))
   end
end
```


## Set metamethods and operations

  We put anything with a sensible signature into metamethods, because our
architecture forbids the ordinary kind\.

It makes sense to intersperse these in with operations, which are provided by
the `Set` cassette, not the `Set_M` metatable\.


### \_\_len

This one is refreshingly simple now that the only keys are the elements of the
set\.

```lua
local nkeys = assert(table.nkeys)

function Set_M.__len(set)
   return nkeys(set)
end
```


### Operators

  All operators create a new set, rather than mutating either of the inputs,
and will accept an array table as either the left or right value of a binary
operation\.


#### \_binOp\(left: Set?, right: Set?\) \-> set, set

A consistent surface to allow either side of the operation to be an array
table\.

```lua
local function _fix(tab)
   if getmetatable(tab) == Set_M then
      return tab
   else
      return Set(tab)
   end
end

local function _binOp(left, right)
   return _fix(left), _fix(right)
end
```


### \_\_add   set \+ set

```lua
local clone = assert(require "table.clone")

function Set_M.__add(left, right)
   left, right = _binOp(left, right)
   local set, other;
   if #left > #right then
      set = clone(left)
      other = right
   else
      set = clone(right)
      other = left
   end

   for elem in pairs(other) do
      set[elem] = true
   end
   return setmetatable(set, Set_M)
end
```


### \_\_repr

We have an existing repr for Sets, which works just as well here once we
remove the indirection\.

\#Todo
make normal Sets a useable return form for sessions\.  We have one somewhere in
repr\.

```lua
local wrap, yield = assert(coroutine.wrap), assert(coroutine.yield)
local tabulate, Token
local sortedpairs = assert(core.table.sortedpairs)

function Set_M.__repr(set, window, c)
   tabulate = tabulate or require "repr:tabulate"
   Token = Token or require "repr:token"

   return wrap(function()
      yield(Token("#{ ", { color = "base", event = "array"}))
      local first = true
      window.depth = window.depth + 1
      for v, _ in sortedpairs(set) do
         if first then
            first = false
         else
            yield(Token(", ", { color = "base", event = "sep" }))
         end
         for t in tabulate(v, window, c) do
            yield(t)
         end
      end
      window.depth = window.depth - 1
      yield(Token(" }", { color = "base", event = "end" }))
   end)
end
```


## Operators: NYI

  Writing the Set operations is beyond my interest in implementing at the moment\.

The semantics are already defined in the other Set module, and it's a matter
of porting the algorithms and writing adequate sessions\.

We are using set operations, at least in Voltron, so they're coming up soon\.


```lua
return Set
```
