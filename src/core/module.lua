











local Mod = {}







local assert = assert(require "core:core/_base" . assertfmt)
local require, pack, unpack = assert(require), assert(pack), assert(unpack)






















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

