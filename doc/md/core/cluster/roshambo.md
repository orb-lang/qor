# Roshambo


> A library by Combat
>
> being
>
> a Mnemnion joint
>
> of BSD license
>
> copyright 2021 e\.v\.


## Use

At the simplest level, Roshambo decides between any two values\.

This is done by fiat: `roshambo.beats(rock, scissors)` means that
`roshambo(scissors, rock)` will return `rock, scissors`\.

This is done by looking up the value of `"rock"` against the victor
table, which returns a set of all values which rock defeats\. Roshambo takes
care that all fiat victory conditions are partially\-ordered: rock and
scissors cannot be entered as victors viz a viz one another\.

Should there be no victory, Roshambo falls back on its duel method, if the
instance provides one\.

Duels are decisive, with the results memoized\.

The user may override the result of a duel by fiat, or force further combat\.

If there is no decisive victor, because a dueling function is not provided,
roshambo will declare victory by precedence: the first variable is the
victor\.

This operation is idempotent, duels are fought once per pair\.
Roshambo is always decisive\.


## Implementation

A roshambo is how we break ties\.

Rules:


-  If two objects are both in a roshambo, we apply this roshambo, and return
    the winner\.


-  Otherwise, we try the *trials* against both objects, which return `nil` if
    not applicable, and a winner if they are\.


-  If they have both won at least once, we try a roshambo on the trials
    themselves, returning the winner of the winner, by elimination, presuming


-  If not, we return `nil`, and why: either no trials apply, or there is no
    tiebreaker for two trials returning different victors\.  So up to four
    values\.


### Rock

The Roshambo subject takes the irregular form `rock`\.

> "Always throw rock" \-Ancient Wisdom of the Masquerade

```lua
_ = return roshambo 'rock' -- i win
```

```lua
local core, cluster = use ("qor:core", "cluster:cluster")
local Set = core.set
```


### Roshambo\(\)

**¡Erre Rioja\!**

This adds two maps, `trials` and `roshambo`\.

```lua
local new, Roshambo, Rock_M = cluster.order()

cluster.construct(new, function(_new, rock)
   rock.trials = {}
   rock.roshambo = {}

   return rock
end)
```


### Roshambo:beats\(\)

The less\-than obvious thing is to check that we haven't entered a
contradiction\.

Roshambo, as the name is meant to indicate, defines rules, so we provide no
way to remove facts from the Roshambo\.

The fields are provided, so with some care, a second Roshambo could be
modified out of a clone of the first\.

```lua
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
```

```lua
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
```

```lua
return new
```
