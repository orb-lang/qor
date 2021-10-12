








































local Set = require "set:set"
local s   = require "status:status"
s.verbose = true
















local function beats(roshambo, champ, loser)
   --needs check for opposite condition,
   --which is nilled out.
   if roshambo._beats[loser] and
      roshambo._beats[loser][champ] then
      roshambo:pr "reversal of fortune"
      roshambo._beats[loser] = roshambo._beats[loser] - champ
      roshambo:pr(roshambo._beats[loser])
   end
   champion = roshambo._beats[champ]
   if champion then
      champion = champion + Set{loser}
   else
      champion = Set{loser}
   end
   roshambo._beats[champ] = champion
   roshambo:pr(champ.." beats "..tostring(roshambo._beats[champ]))
end






local function duel(roshambo,champ,challenge)
   if roshambo._duel_with then
      roshambo:pr "it's a duel!"
      local winner, loser = roshambo:_duel_with(champ,challenge)
      roshambo:beats(winner,loser)
      return winner, loser
   else
      roshambo:pr "victory by fiat"
      roshambo:beats(champ,challenge)
      return champ, challenge
   end
end











local function duel_with(roshambo, fn)
   roshambo._duel_with = fn
end








local function fight(roshambo, champ, challenge)
   if roshambo._beats[champ] then
      if roshambo._beats[champ](challenge) then
          roshambo:pr(tostring(champ).." wins")
          return champ, challenge
      elseif roshambo._beats[challenge] then
         if roshambo._beats[challenge](champ) then
            roshambo:pr(tostring(challenge).." wins")
            return challenge, champ
         end
      else --duel here
         s:verb(tostring(challenge) .. " not found")
         return duel(roshambo,champ,challenge)
      end
   else --duel here as well
      s:verb(tostring(champ).." not found")
      return duel(roshambo, champ, challenge)
   end
end








function roshambo_sort(roshambo, champ, challenge)
   local victor = fight(roshambo, champ, challenge)
   return victor == champ and true or false
end

local R = {}
R.fight = fight
R.beats = beats
R.duel_with = duel_with
R.sort  = roshambo_sort
--- an alias for fight
-- @function __call
-- @param champ
-- @param challenge
-- @within metamethods
R["__call"] = fight
R["__index"] = R
setmetatable(R,{}) -- clu.Meta

--- instantiates a roshambo
-- @function Roshambo
-- @param init a optional table of champ/loser key/value pairs.
-- @return an instance of roshambo
local function Roshambo(init)
   local rosh = {}
   rosh._beats = {}
   if init then
      if type(init) == "table" then
         for i,v in pairs(init) do
            rosh._beats[i] = Set{v}
         end
      else
         error("Roshambo must be initialized with a table")
      end
   end
   setmetatable(rosh,R)
   rosh.foo = "bar"
   return rosh
end



return Roshambo

