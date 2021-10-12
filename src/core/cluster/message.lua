

















local core = require "core:core"
local s = require "status:status"

s.chatty = true

local meta = assert(core.Meta)

local readOnly = assert(core.readOnly)






local _Message = meta {}

_Message._VERSION = 1

























































assert(true)

local function validate(msg)
   -- table?
   if not type(msg) == 'table' then
      return nil, "message is not a table!"
   end

   -- params?
   if msg.n or #msg > 0 then
      if not msg.n then
         return nil, "arguments provided without .n field!"
      end
      if not msg.method or msg.call then
         return nil, "arguments provided for un-callable message!"
      end
   end

   if msg.call then
      if not type(msg.call) == 'string' or msg.call == true then
         return nil, "message.call not a string or =true=!"
      end
   end

   if msg.message then
      return validate(msg.message)
   end

   return msg
end






local valid = s.chatty and validate or function(a, b) return a, b end


local function new(msg)
   assert(type(msg) == 'table', "#1 must be a table")
   local Msg = {}
   for k, v in pairs(msg) do
      Msg[k] = v
   end
   return valid (readOnly(setmeta(Msg, Message)))
end













































































return new

