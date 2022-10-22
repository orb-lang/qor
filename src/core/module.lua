





local Mod = {}




local _base = require "qor:core/_base"
local assertfmt = assert(_base.assertfmt)
local require, pack, unpack = assert(require), assert(pack), assert(unpack)








Mod.lazyloader = assert(_base.lazyloader)








local pcall = assert(pcall)

function Mod.request(module)
   local ok, mod = pcall(require, module)
   if ok then
      return mod
   else
      return nil
   end
end



return Mod

