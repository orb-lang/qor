














































local _base = require "qor:core/_base"
local core    = _base.lazyloader { 'core',

   cluster    = "qor:core/cluster",
   coro       = "qor:core/coro",
   fn         = "qor:core/fn",
   debug      = "qor:core/debug",
   math       = "qor:core/math",
   meta       = "qor:core/meta",
   ["module"] = "qor:core/module",
   string     = "qor:core/string",
   table      = "qor:core/table",
   thread     = "qor:core/thread",
   env        = "qor:core/env",
   uv         = "qor:core/uv",
   set        = "qor:core/set",
}

core.unique = _base.unique



return core

