





local Mod = {}




local _base = require "qor:core/_base"
local assertfmt = assert(_base.assertfmt)
local require, pack, unpack = assert(require), assert(pack), assert(unpack)








Mod.lazyloader = assert(_base.lazyloader)











function Mod.import(req_str, ...)
   local mod = require(req_str)
   local fields, exports = pack(...), {}
   for i = 1, fields.n do
       exports[i] = assert(mod[fields[i]], "can't require %s", fields[i])
   end
   exports.n = fields.n
   return unpack(exports)
end








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

