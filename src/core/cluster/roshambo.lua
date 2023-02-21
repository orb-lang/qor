







































































local core, cluster = use ("qor:core", "cluster:cluster")
local Set = core.set










local new, Roshambo, Rock_M = cluster.order()

cluster.construct(new, function(_new, rock)
   rock.trials = {}
   rock.roshambo = {}

   return rock
end)















local function getSet(rock, scissors)
   if rock.roshambo[scissors] then
      return rock.roshambo[scissors]
   else
      rock.roshambo[scissors] = Set {}
      return rock.roshambo[scissors]
   end
end

function Roshambo.beats(rock, scissors, paper)
   assert(scissors ~= nil, "first value can't be nil")
   assert(paper ~= nil, "second value can't be nil")
   if rock.roshambo[paper] and rock.roshambo[paper][scissors] then
      return nil, "contradiction " .. tostring(paper)
                  .. " beats " .. tostring(scissors)
   end
   local losers = getSet(rock, scissors)
   losers[paper] = true
   return true
end



local insert = table.insert

function Rock_M.__call(rock, scissors, paper)
   local trial, roshambo = rock.trial, rock.roshambo
   if roshambo[scissors] and roshambo[scissors][paper] then
      return scissors
   elseif roshambo[paper] and roshambo[paper][scissors] then
      return paper
   end
   local victors, vias = {}, {}
   local victor = nil

   for try in pairs(trial) do
      local contender = try(scissors, paper)
      if contender ~= nil then
         insert(victors, contender)
         insert(vias, try)
         victor = contender
      end
   end
   if not victor then
      return nil, "which is to win, we do not know"
   end
   if #victors == 1 then
      return victor
   end
   if #victors == 2 then
      if rawequal(victors[1], victors[2]) then
         return victor
      else
         local oneWin, twoWin = roshambo[vias[1]], roshambo[vias[2]]
         if oneWin and oneWin[vias[2]] then
            return victors[1]
         end
         if twoWin and twoWin[vias[1]] then
            return victors[2]
         end
         return nil, "no tiebreaker for trials with contradictory wins"
      end
   end
   local same = true
   for _, contender in ipairs(victors) do
      same = same and rawequal(victor, contender)
   end
   if same then
      return victor
   end

   return nil, "can't handle contradictory results \z
                for " .. #victors .. " trials"
end



return new

