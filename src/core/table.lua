



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
   local _M = getmetatable(tab)
   local clone = _M and setmetatable({}, _M) or {}
   for k,v in pairs(tab) do
      if depth > 1 and type(v) == "table" then
        v = _clone(v, depth - 1)
      end
      clone[k] = v
   end
   return clone
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
                        -- in insert
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








local hasmetamethod = assert(meta.hasmetamethod)

function Tab.iscallable(val)
   return type(val) == "function"
      or hasmetamethod("__call", val)
end







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









function Tab.removerange(tab, start, stop)
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
   assert(type(tab) == "table", "vals must receive a table")
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

function Tab.splice(tab, idx, into)
   assert(type(tab) == "table", _e_1)
   assert(type(idx) == "number" or idx == nil, _e_2)
   if idx == nil then
      idx = #tab + 1
   end
   assert(type(into) == "table", _e_3)
    idx = idx - 1
    local i = 1
    for j = 1, #into do
        insert(tab,i+idx,into[j])
        i = i + 1
    end
    return tab
end








function Tab.addall(tab, to_add)
   for k, v in pairs (to_add) do
      tab[k] = v
   end
end








function Tab.safeget(tab, key)
   local val = rawget(tab, key)
   if val ~= nil then
      return val
   end
   local _M = getmetatable(tab)
   while _M ~= nil and rawget(_M, "__index") ~= nil do
      local index_t = type(_M.__index)
      if index_t == "table" then
         val = rawget(_M.__index, key)
      elseif index_t == "function" then
         local success
         success, val = pcall(_M.__index, table, key)
         if success then
            return val
         else
            val = nil
         end
      else
         error("somehow, __index is of type " .. index_t)
      end
      if val ~= nil then
         return val
      end
      _M = index_t == "table" and getmetatable(_M.__index) or nil
   end
   return nil
end




return Tab
