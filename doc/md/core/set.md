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
local set, set_Build, set_M = {}, {}, {}
setmetatable(set, set_Build)
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
function set_Build.__call(_new, tab)
   tab = tab or {}
   assert(type(tab) == 'table', "#1 to Set must be a table or nil")
   for i, v in ipairs(tab) do
      tab[v] = true
      tab[i] = nil
   end
   return setmetatable(tab, set_M)
end
```


### set\(\.\.\.\) \->

  Calling a set adds all the elements to the Set\.  As is normal with inserting
into tables, we do not return the set\.

There are only two mutations of sets offered, and this is one, the other one
is `set.remove(set, ...)` which removes elements as listed, and returns the
element iff they were there to be removed\.

```lua
function set_M.__call(set, ...)
   for i = 1, select('#', ...) do
      set_M[select(i, ...)] = true
   end
end
```

```lua
return set
```
