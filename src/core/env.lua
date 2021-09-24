






local next = assert(next) -- !

local Env = {}
function Env.fenv(...)
   local _env = {}
   local f = unpack(...)
   if not f then return _env end
   if f then
      for k,v in next, f, nil do
         _env[k] = v
      end
      return _env
   end
end



return Env

