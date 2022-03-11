










































local function lazy_load_gen(requires)
   return function(tab, key)
      if requires[key] then
         -- put the return on the core table
         tab[key] = require(requires[key])
         return tab[key]
      else
         error("core doesn't have a module " .. tostring(key))
      end
   end
end





local function call_gen(requires)
   return function(tab, env)
      local _;
      for k in pairs(requires) do
         _ = tab[k]
         if env then
            -- assign the now cached value as a global or at least slot
            env[k] = tab[k]
         end
      end
      return tab
   end
end








local core_modules = {
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



return setmetatable({}, { __index = lazy_load_gen(core_modules),
                                __call  = call_gen(core_modules) })

