# Core


For now, this is a compatibility shim: we're going to import everything from
all the submodules, and return one big table.


This **should** mean we can do a big search-replace to change all
``singletons/core`` to ``core:core``.


Then go through and require the appropriate submodules until we're not
using ``core:core`` at all.


After that, we want to put each submodule on a table, using a lazy-load so
that we only get a specific module if we try and use it.

```lua
local mods = {}
local core = {}
local insert = assert(table.insert)
insert(mods, require "core:core/meta")
insert(mods, require "core:core/fn")
insert(mods, require "core:core/string")
insert(mods, require "core:core/table")
for _, mod in ipairs(mod) do
   for k,v in pairs(mod) do
      core[k] = v
   end
end
return core
```