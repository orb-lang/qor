















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
