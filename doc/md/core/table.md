# Table Extensions


```lua
local meta = require "core/meta"
local Tab = {}
for k, v in pairs(table) do
   Tab[k] = v
end
```


## n\_table

  Sometimes we want to be able to include `nil` in an array\-type table\.  The
usual way to handle this in Lua is with a table that has a `.n` field\.

This is a metatable and constructor which provides a table which behaves in
that fashion\.

\#Todo
should be their own constructor; they can share some methods, but `.n` has
different semantics in this case, since it refers to the first open slot\.


```lua
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
```


### readOnly\(tab\)

Makes a table read\-only, will throw an error if assigned to\.

```lua
local function RO_M__newindex(tab, key, value)
   error("attempt to write value `" .. tostring(value)
         .. "` to read-only table slot `." .. tostring(key) .. "`")
end

function Tab.readOnly(tab)
   return setmetatable({}, {__index = tab, __newindex = RO_M__newindex})
end
```


### hasfield\(tab, field\) & hasfield\.field\(tab\)


A nicety which can be used both for predication and assignment\.

```lua
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
```


### clone\(tab, depth\)

Performs a shallow clone of table, attaching metatable if available\.

Will recurse to `depth` if provided\.

This will unroll circular references, which may not be what you want\.

```lua
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
```


### Table\.deepclone\(tab\)

Makes a cycle\-checked deep copy of a table, including metatables\.

```lua
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
```


### cloneinstance\(tab\)

`deepclone` is useful to take a snapshot, as of an environment, with the
assurance that no subsequent action can mutate your clone\.  With some caveats,
if you're holding closures with mutable state, or userdata\.

`cloneinstance` covers a more common use case, where you want a deep clone of
an instance table, which may have circular references and member instances,
but want to retain the same metatable for each table cloned\.

metatables are often used as a poor man's type signature, and this function
will not break that contract\.

```lua
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
```


### isarray\(tab\)

Determines if `tab` is an array, i\.e\. a table whose only keys are a contiguous
range of integers starting at 1\.

This seems potentially unsafe\-\-pairs\(\) technically may return keys in any order\.
In practice integer keys seem to be returned first and in\-order, and certainly
**if** there are only integer keys I imagine this holds true no matter what\. If
there are non\-integer keys, well, things being out of order will cause us to
fail fast, which is a good thing, so\.\.\.bonus, I guess\.

NB: this function bears no resemblance to the actual behavior of Lua, which
is frankly somewhat horrifying if one goes off\-reservation with table
behavior\. \(The actual Lua behavior uses a binary search, so some "holes"\-\-
e\.g\. \{1, nil, 3\}\-\-will affect \#, while others won't\. We are more careful, at
the cost of some performance\.\)

```lua
function Tab.isarray(tab)
   local i = 1
   for k,_ in pairs(tab) do
      if k ~= i then return false end
      i = i + 1
   end
   return true
end
```


### arraymap\(tab, fn\)

Iterates the array portion of `tab`, applying `fn` and storing the first
return value in a new table, which is returned\.

Note that `nil` values will break the one\-to\-one relationship between the
first table and the returned table\.

```lua
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
```


### compact\(tab, n\)

  Makes the array portion of a table compact up to `n`, by moving any values
found above `nils` downward into the holes\.

This is recommended as an alternative to a `remove`\-heavy algorithm\.  Since it
moves values at most once, it's faster to cache the value of `#tab`, remove
unwanted values, and run `compact` once at the end\.

This is a `.n` aware algorithm, and will use it if the second argument is not
provided\.  As the purpose is to shrink a table with holes, we feel that
providing `#tab` as a further fallback is asking for trouble\.

Returns nothing, in common with other functions which mutate a table in\-place\.

```lua
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
```


### inverse\(tab\)

Returns a new table, in which all keys of `tab` are values of the new table,
and vice versa\.

Throws an error if duplicate values are present in the table\.

```lua
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
```


### flatten\(tab, level\)

Takes nested tables and flattens the array portion into a single table, which
is returned\.

Will decline to follow circular references, with a side\-effect that multiple
instances of the same table are only copied once\.

If `level` is provided, `flatten` will only iterate to the specified depth:

```lua-example
tab = {1, {2, {3, 4}, 5}, 6}
flatten(tab)
-- {1, 2, 3, 4, 5, 6}
flatten(tab, 1)
-- {1, 2, {3, 4}, 5, 6}
```

```lua
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
```

### iscallable\(val\)

  Determines if `val` is callable, i\.e\. a function, or something with a
`__call` metamethod\.

```lua
local hasmetamethod = assert(meta.hasmetamethod)

function Tab.iscallable(val)
   return type(val) == "function"
      or hasmetamethod("__call", val)
end
```

### arrayof\(tab\)

Clones and returns the array portion of a table\.

```lua
function Tab.arrayof(tab)
   local arr = {}
   for i,v in ipairs(tab) do
      arr[i] = v
   end
   return arr
end
```


### collect\(iter, \.\.\.\)

  Collects and returns up to two tables of values, given an iterator and
arguments to pass to it\.

```lua
function Tab.collect(iter, tab, ...)
   local k_tab, v_tab = {}, {}
   for k, v in iter(tab, ...) do
      k_tab[#k_tab + 1] = k
      v_tab[#v_tab + 1] = v
   end
   return k_tab, v_tab
end
```


### select\(tab, key\)

Recursively return all `v` for `key` in all subtables of tab\.

NB: this is not being used and collides with a core library name\.

Should probably be removed\.

```lua
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
```


### reverse\(tab\)

Reverses \(only\) the array portion of a table, returning a new table\.

```lua
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
```


### keys\(tab\)

Returns an array of the keys of a table\.

```lua
function Tab.keys(tab)
   assert(type(tab) == "table", "keys must receive a table")
   local keys = {}
   for k, _ in pairs(tab) do
      keys[#keys + 1] = k
   end

   return keys, #keys
end
```


### values\(tab\)

```lua
function Tab.values(tab)
   assert(type(tab) == "table", "vals must receive a table")
   local vals = {}
   for _, v in pairs(tab) do
      vals[#vals + 1] = v
   end

   return vals, #vals
end
```

### slice\(tab, from\[, to\]\)

Extracts a slice of `tab`, starting at index `from` and ending at index `to`,
inclusive\. If `to` is ommitted, the size of `tab` is used\. Either `from` or
`to` may be negative, in which case they are relative to the end of the table\.
If `to` is less than `from`, an empty table is returned\.

```lua

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

```

### splice\(tab, index, into\)

Puts the full contents of `into` into `tab` at `index`\.  The argument order is
compatible with existing functions and method syntax\.

if `index` is nil, the contents of `into` will be inserted at the end of
`tab`

\#Todo

```lua
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
```


### addall\(tab, to\_add\)

Adds all key\-value pairs of the `to_add` table to `tab`\.

```lua
function Tab.addall(tab, to_add)
   for k, v in pairs (to_add) do
      tab[k] = v
   end
end
```

### safeget\(tab, key\)

This will retrieve a value, given a key, without causing errors if the table
has been made strict\.

```lua
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
```


```lua
return Tab
```