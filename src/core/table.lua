



local _base = require "core:core/_base"




local meta = require "core/meta"
local Tab = {}
for k, v in pairs(table) do
   Tab[k] = v
end






















local N_M = {}
N_M.__index = N_M

function N_M.__len(tab)
   return tab.n
end

function N_M.__ipairs(tab)
   local i = 1
   return function()
      if i >= tab.n then return nil end
      i = i + 1
      return i - 1, tab[i - 1]
   end
end

function Tab.n_table(tab, djikstra)
   tab = tab or {}
   tab.n = 0
   return setmetatable(tab, N_M)
end








local function RO_M__newindex(tab, key, value)
   error("attempt to write value `" .. tostring(value)
         .. "` to read-only table slot `." .. tostring(key) .. "`")
end

function Tab.readOnly(tab)
   return setmetatable({}, {__index = tab, __newindex = RO_M__newindex})
end









local function _hasfield(tab, field)
   if type(tab) == "table" and rawget(tab, field) then
      return tab[field]
   elseif getmetatable(tab) then
      local _M = getmetatable(tab)
      local maybeIndex = rawget(_M, "__index")
      if type(maybeIndex) == "table" then
         return _hasfield(maybeIndex, field)
      elseif type(maybeIndex) == "function" then
         local success, result = pcall(maybeIndex, tab, field)
         if success and result ~= nil then
            return result
         end
      end
   end
   return nil
end

local function _hf__index(_, field)
   return function(tab)
      return _hasfield(tab, field)
   end
end

local function _hf__call(_, tab, field)
   return _hasfield(tab, field)
end

Tab.hasfield = setmetatable({}, { __index = _hf__index,
                                   __call  = _hf__call })












local function _clone(tab, depth)
   depth = depth or 1
   assert(depth > 0, "depth must be positive " .. tostring(depth))
   local clone = {}
   for k,v in next, tab do
      if depth > 1 and type(v) == "table" then
        v = _clone(v, depth - 1)
      end
      clone[k] = v
   end
   return setmetatable(clone, getmetatable(tab))
end
Tab.clone = _clone








function Tab.deepclone(tab)
   assert(type(tab) == "table",
          "cannot deepclone value of type " .. type(tab))
   local dupes = {}
   local function _deep(val)
      local copy = val
      if type(val) == "table" then
         if dupes[val] then
            copy = dupes[val]
         else
            copy = {}
            dupes[val] = copy
            for k,v in next, val do
               copy[_deep(k)] = _deep(v)
            end
            -- copy the metatable after, in case it contains
            -- __index or __newindex behaviors
            copy = setmetatable(copy, _deep(getmetatable(val)))
         end
      end
      return copy
   end
   return _deep(tab)
end

















function Tab.cloneinstance(tab)
   assert(type(tab) == "table",
          "cannot cloneinstance of type " .. type(tab))
   local dupes = {}
   local function _deep(val)
      local copy = val
      if type(val) == "table" then
         if dupes[val] then
            copy = dupes[val]
         else
            copy = {}
            dupes[val] = copy
            for k,v in next, val do
               copy[_deep(k)] = _deep(v)
            end
            copy = setmetatable(copy, getmetatable(val))
         end
      end
      return copy
   end
   return _deep(tab)
end





















function Tab.isarray(tab)
   local i = 1
   for k,_ in pairs(tab) do
      if k ~= i then return false end
      i = i + 1
   end
   return true
end

















local insert = assert(table.insert)

function Tab.arraymap(tab, fn)
   local ret, ret_val = {}
   for _, val in ipairs(tab) do
      ret_val = fn(val) -- necessary to avoid unpacking multiple values
                        -- in insert (could be =insert(ret, (fn(val)))=...)
      insert(ret, ret_val)
   end
   return ret
end



















function Tab.compact(tab, n)
   n = assert(n or tab.n, "a numeric value must be provided for non-ntables")
   local cursor, slot, empty = 1, nil, nil
   while cursor <= n do
      slot = tab[cursor]
      if slot == nil and empty == nil then
         -- mark the empty position
         empty = cursor
      end
      if slot ~= nil and empty ~= nil then
         tab[empty] = slot
         tab[cursor] = nil
         cursor = empty
         empty = nil
      end
      cursor = cursor + 1
   end
   if tab.n then
      tab.n = #tab
   end
end











function Tab.inverse(tab)
   local bat = {}
   for k,v in pairs(tab) do
      if bat[v] then
         error("duplicate value on key " .. k)
      end
      bat[v] = k
   end
   return bat
end






















function Tab.flatten(tab, level)
   local ret, copies = {}, {}
   local function _flat(t, depth)
      if level and depth > level then
         ret[#ret + 1] = t
         return nil
      end
      for _,v in ipairs(t) do
         if type(v) ~= "table" then
            ret[#ret + 1] = v
         else
            if not copies[v] then
               copies[v] = true
               _flat(v, depth + 1)
            end
         end
      end
   end
   _flat(tab, 0)
   return ret
end









Tab.iscallable = assert(_base.iscallable)








function Tab.arrayof(tab)
   local arr = {}
   for i,v in ipairs(tab) do
      arr[i] = v
   end
   return arr
end









function Tab.collect(iter, tab, ...)
   local k_tab, v_tab = {}, {}
   for k, v in iter(tab, ...) do
      k_tab[#k_tab + 1] = k
      v_tab[#v_tab + 1] = v
   end
   return k_tab, v_tab
end












local function _select(collection, tab, key, cycle)
   cycle = cycle or {}
   for k,v in pairs(tab) do
      if key == k then
         collection[#collection + 1] = v
      end
      if type(v) == "table" and not cycle[v] then
         cycle[v] = true
         collection = _select(collection, v, key, cycle)
      end
   end
   return collection
end

function Tab.select(tab, key)
   return _select({}, tab, key)
end








function Tab.reverse(tab)
   if type(tab) ~= "table" or #tab == 0 then
      return {}
   end
   local bat = {}
   for i,v in ipairs(tab) do
      bat[#tab - i + 1] = v
   end
   return bat
end










function Tab.deleterange(tab, start, stop)
   if start > stop then return end
   local offset = stop - start + 1
   for i = start, #tab do
      tab[i] = tab[i + offset]
   end
end








function Tab.keys(tab)
   assert(type(tab) == "table", "keys must receive a table")
   local keys = {}
   for k, _ in pairs(tab) do
      keys[#keys + 1] = k
   end

   return keys, #keys
end






function Tab.values(tab)
   assert(type(tab) == "table", "values must receive a table")
   local vals = {}
   for _, v in pairs(tab) do
      vals[#vals + 1] = v
   end

   return vals, #vals
end











function Tab.slice(tab, from, to)
   to = to or #tab
   if from < 0 then
      from = #tab + 1 + from
   end
   if to < 0 then
      to = #tab + 1 + to
   end
   local answer = {}
   for i = 0, to - from do
      answer[i + 1] = tab[from + i]
   end
   return answer
end














local insert = assert(table.insert)

local sp_er = "table<core>.splice: "
local _e_1 = sp_er .. "$1 must be a table"
local _e_2 = sp_er .. "$2 must be a number"
local _e_3 = sp_er .. "$3 must be a table"

local function push(queue, x)
   queue.tail = queue.tail + 1
   queue[queue.tail] = x
end

local function pop(queue)
   if queue.tail == queue.head then return nil end
   queue.head = queue.head + 1
   return queue[queue.head]
end

function Tab.splice(tab, index, to_add)
   assert(type(tab) == "table", _e_1)
   assert(type(index) == "number" or index == nil, _e_2)
   if index == nil then
      index = #tab + 1
   end
   assert(type(to_add) == "table", _e_3)
    index = index - 1
    local queue = { head = 0, tail = 0}
    local i = 1
    -- replace elements, spilling onto queue
    for j = 1, #to_add do
        push(queue, tab[i + index])
        tab[i + index] = to_add[j]
        i = i + 1
    end
    -- run the queue up the remainder of the table
    local elem = pop(queue)
    while elem ~= nil do
       push(queue, tab[i + index])
       tab[i + index] = elem
       i = i + 1
       elem = pop(queue)
    end
    return tab
end













local compact, splice = Tab.compact, Tab.splice

function Tab.replace(tab, index, to_add, span)
   assert(type(tab) == "table", _e_1)
   assert(type(index) == "number", _e_2)
   assert(type(to_add) == "table", _e_3)
   span = span or #to_add
   -- easiest to handle the three cases as distinct.
   if span == #to_add then
      for i = index, index + span - 1 do
         tab[i] = to_add[i - index + 1]
      end
   elseif span > #to_add then
      local top = #tab
      -- replace #to_add worth of elements
      for i = index, index + #to_add - 1 do
         tab[i] = to_add[i - index + 1]
      end
      -- nil out remaining elements
      for i = index + #to_add, index + span - 1 do
         tab[i] = nil
      end
      compact(tab, top)
   else -- if span < #to_add
      -- replace span worth of elements
      for i = index, index + span - 1 do
         tab[i] = to_add[i - index + 1]
      end
      -- make a table to hold the rest, copy
      local spill = {}
      for i = 1, #to_add - span do
        spill[i] = to_add[i + span]
      end
      splice(tab, index + span, spill)
   end
end








function Tab.addall(tab, to_add)
   for k, v in pairs (to_add) do
      tab[k] = v
   end
end








function Tab.pget(tab, key)
   local ok, val = pcall(function() return tab[key] end)
   if ok then
      return val
   else
      return nil
   end
end









function Tab.safeget(tab, key)
   while tab ~= nil do
      local val = rawget(tab, key)
      if val ~= nil then return val end
      local M = getmetatable(tab)
      if M then
         tab = rawget(M, '__index')
         if type(tab) ~= 'table' then
            return nil
         end
      else
         tab = nil
      end
   end
   return nil
end













function Tab.fromkeys(tab, ...)
   local answer = {}
   local keys = pack(...)
   for _, k in ipairs(keys) do
      answer[k] = tab[k]
   end
   return answer
end



return Tab

