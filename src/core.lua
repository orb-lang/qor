















local mods = {}
local core = {}
local insert = assert(table.insert)
insert(mods, require "core:core/cluster")
insert(mods, require "core:core/coro")
insert(mods, require "core:core/fn")
insert(mods, require "core:core/math")
insert(mods, require "core:core/meta")
insert(mods, require "core:core/module")
insert(mods, require "core:core/string")
insert(mods, require "core:core/table")
insert(mods, require "core:core/thread")
insert(mods, require "core:core/env")

for _, mod in ipairs(mods) do
   for k,v in pairs(mod) do
      core[k] = v
   end
end
return core

