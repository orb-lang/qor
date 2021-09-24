# Core


For now, this is a compatibility shim: we're going to import everything from
all the submodules, and return one big table\.

This **should** mean we can do a big search\-replace to change all
`singletons/core` to `core:core`\.

Then go through and require the appropriate submodules until we're not
using `core:core` at all\.

After that, we want to put each submodule on a table, using a lazy\-load so
that we only get a specific module if we try and use it\.

```lua
local mods = {}
local core = {}
local insert = assert(table.insert)

mods[require "core:core/cluster"] =  'core'
mods[require "core:core/coro"] =  'coro'
mods[require "core:core/fn"] =  'fn'
mods[require "core:core/math"] =  'math'
mods[require "core:core/meta"] =  'meta'
mods[require "core:core/module"] =  'module'
mods[require "core:core/string"] =  'string'
mods[require "core:core/table"] =  'table'
mods[require "core:core/thread"] =  'thread'
mods[require "core:core/env"] =  'env'

for k, v in pairs(mods) do
   core[v] = k
end

return core
```
