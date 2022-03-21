# Core


  Core provides the primitive extensions to the Lua language used by every
other system in the bridge\.


## Design

Core itself is a lazy loader, with the following interface\.

To include `core` without paying for what you don't use, or worrying much
about getting what you need when you need it, do this:

```lua
local core = require "core"
```

Any field access will require the requested table\.

To make core eager, call it:

```lua
local core = require "core" ()
```

This presents the same interface, but with every subtable already in memory\.

To add the subtables as fields of another table, such as an environment,
pass this as the argument:

```lua
require "core" (getfenv(1))
```

The tables, such as `table`, named after global tables in the global table,
are designed as conservative replacements for their namesakes\.  Conservative
in that any field present in 'Lua classic' will have an identical value if
that value is a function\.


Which is a bit funny looking, but does mean that any tweaks or enhancements to
the indexer will be seen in the caller without further ado\.

So the module is just this:

```lua
return require "qor:core/_base" . lazyloader {
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
}
```

