















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

