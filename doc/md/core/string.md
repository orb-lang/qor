#\* String extensions


- [ ] \#Todo core\.stringable: type\(str?\) = 'string' or hasmetamethod \_\_tostring


### Type Predicate: string\(str?\): str | nil, type\(str\)

  Each core extension named after a type can be used to test a value for that
primitive type\.

```lua
local function is_string(_, str)
   local t = type(str)
   return t == 'string'
          and str
          or nil, t
end
```


```lua
local String = setmetatable({}, { __call = is_string })
```


## String extensions

```lua
local assertfmt = require "core:core/_base".assertfmt
local byte = assert(string.byte)
local find = assert(string.find)
local sub = assert(string.sub)
local format = assert(string.format)
```


#### copy string table

This lets us use `core:string` as a drop\-in replacement for the string table\.

```lua
for k, v in next, string do
  String[k] = v
end
```


### assertfmt\(predicate, msg, \.\.\.\)

Not clear this belongs here, but it is as much like `string.format` as
anything else\.

```lua
String.assertfmt = assertfmt
```


### stringable\(is\_str\)

```lua
assert(true)

function String.stringable(is_str)
   return type(is_str) == 'string'
      or (type(is_str) == 'table' and hasmetamethod(__tostring))
|
end
```


### utf8\(str, \[offset\]\)

This takes a string and validates one codepoint, starting at the given
offset \(default of 1\)\.

Return is either the \(valid\) length in bytes, or nil and an error string\.

```lua
local function continue(c)
   return c >= 128 and c <= 191
end

local function _offsideErr(str, offset)
   return nil, "out of bounds: #str: " .. tostring(#str)
                  .. ", offset: " .. tostring(offset)
end
function String.utf8(str, offset)
   offset = offset or 1
   local byte = byte
   local head = byte(str, offset)
   if not head then
      return _offsideErr(str, offset)
   end
   if head < 128 then
      return 1
   elseif head >= 194 and head <= 223 then
      local two = byte(str, offset + 1)
      if not two then
         return _offsideErr(str, offset + 1)
      end
      if continue(two) then
         return 2
      else
         return nil, "utf8: bad second byte"
      end
   elseif head >= 224 and head <= 239 then
      local two, three = byte(str, offset + 1), byte(str, offset + 2)
      if (not two) or (not three) then
         return _offsideErr(str, offset + 2)
      end
      if continue(two) and continue(three) then
         return 3
      else
         return nil, "utf8: bad second and/or third byte"
      end
   elseif head >= 240 and head <= 244 then
      local two, three, four = byte(str, offset + 1),
                               byte(str, offset + 2),
                               byte(str, offset + 3)
      if (not two) or (not three) or (not four) then
         return _offsideErr(str, offset + 3)
      end
      if continue(two) and continue(three) and continue(four) then
         return 4
      else
         return nil, "utf8: bad second, third, and/or fourth byte"
      end
   elseif continue(head) then
      return nil, "utf8: continuation byte at head"
   elseif head == 192 or head == 193 then
      return nil, "utf8: 192 or 193 forbidden"
   else -- head > 245
      return nil, "utf8: byte > 245"
   end
end
```


### split\(str, patt\)

Searches `str` for `patt`, returning two strings:

if `patt` is found, the substrings **exclusive of** the found substring,
otherwise `str, ""`

```lua
function String.split(str, patt)
   local first, last = find(str, patt)
   if first then
      return sub(str, 1, first - 1), sub(str, last + 1)
   else
      return str, ""
   end
end
```


### findall\(str, patt\)

Runs `find` repeatedly, returning an array of arrays where `[1]` is the
beginning of the match, and `[2]` is the end\.

Returns `nil` if no match is found\.

Should probably take a third parameter to limit the number of matches\.

```lua
local function findall(str, patt)
   local find = type(str) == 'string' and find or str.find
   local matches = {}
   local index = 1
   local left, right
   repeat
     left, right = find(str, patt, index)
     if left then
        matches[#matches + 1] = {left, right}
        index = right + 1
     end
   until left == nil
   if #matches > 0 then
      return matches
   else
      return nil
   end
end

String.findall = findall
```


### typeformat\(str, \.\.\.\)

Background: I want to start using format in errors and assertions\.

It's not as bad to use concatenation in\-place for errors, since evaluating
them is a final step\.  Assertions run much faster if passed only arguments\.

Lua peforms a small number of implicit conversions, mostly at the string
boundary\. This is an actual feature since the language has both `..` and `+`,
but it leaves a bit to be desired when it comes to `string.format`\.

`format` treats any `%s` as a request to convert `tostring`, also treating
`%d` as a call to `tonumber`\.  The latter I will allow, I'm struggling to find
a circumstance where casting "1" to "1" through `1` is dangerous\.

What I want is a type\-checked `format`, which I can extend to use a few more
flexible strategies, depending on the context\.

Less concerned about hostility and more about explicit coding practices\. Also
don't want to undermine hardening elsewhere\.

From the wiki, the full set of numeric parameters is
`{A,a,c,d,E,e,f,G,g,i,o,u,X,x}`\.  That leaves `%q` and `%s`, the former does
string escaping but of course it is the Lua/C style of escaping\.

We add `%t` and `%L` \(for λ\), which call `tostring` on a table or a function
respectively\.  While we're being thorough, `%b` for boolean, `%n` for `nil`,
and `%*` for the union type\.  Why bother with `nil`, which we can just write?
Type\-checking, of course\.  We treat `nil` as a full type, because in Lua, it
is\.

`%t` will actually accept all remaining compound types: `userdata`, `thread`,
and `cdata`\.  For only tables, we can have `%T`, and also `%U`, `%R` \(coRo\),
and `%C`\.

Note our `%L` is not the C version\.  Tempted to have `%λ` directly, but
that's a bit weird and it breaks the idea that format sequences are two
bytes long\.  While I don't intend to write code that would break in this
case, eh\.

`typeformat` returns the correctly formatted string, or throws an error\.

```lua
local fmt_set = {"*", "C", "L", "R", "T", "U", "b", "n", "q", "s", "t" }

for i, v in ipairs(fmt_set) do
   fmt_set[i] = "%%" .. v
end

--[[
local function next_fmt(str)
   local head, tail
   for _, v in ipairs(fmt_set) do
      head, tail = 2
end]]

function String.format_safe(str, ...)

end
```

### litpat\(s\)

`%` escapes all pattern characters\.

The resulting string will literally match `s` in `sub` or `gsub`\.

```lua
local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }

function String.litpat(s)
    return (s:gsub(".", matches))
end
```


### cleave\(str, patt\)

Performs the common operation of returning one run of bytes up to `patt`
then the rest of the bytes after `patt`\.

Can be used to build iterators, either stateful or coroutine\-based\.

```lua
local function cleave(str, pat)
   local at = find(str, pat)
   if at then
      return sub(str, 1, at - 1), sub(str, at + 1)
   else
      return str, nil
   end
end
String.cleave = cleave
```

### isidentifier\(str\)

Determines if `str` is a valid Lua identifier\.
This follows the Lua standard\-\-LuaJIT is actually much more permissive,
but the rules are potentially quite complicated wrt special Unicode characters
like ZWJ and NBSP, so let's stick with the simple standard for now\.

```lua
function String.isidentifier(str)
   return find(str, "^[a-zA-Z_][a-zA-Z0-9_]+$") == 1
end
```


#### String\.lines\(str\)

Returns an iterator over the lines of a string\.

```lua
function String.lines(str)
   local pos = 1;
   return function()
      if not pos then return nil end
      local p1 = find(str, "[\r\n]", pos)
      local line
      if p1 then
         local p2 = p1
         if sub(str, p1, p1) == "\r" and sub(str, p1+1, p1+1) == "\n" then
            p2 = p1 + 1
         end
         line = sub(str, pos, p1 - 1 )
         pos = p2 + 1
      else
         line = sub(str, pos )
         pos = nil
      end
      return line
   end
end
```



#### String\.linesnl\(str\)

An iterator over all lines, which includes the newline\.

```lua
function String.linesnl(str)
   local pos = 1;
   return function()
      if not pos then return nil end
      local nl = find(str, "\n", pos)
      local rx = pos
      if nl then
         pos = nl + 1
         return sub(str, rx, nl)
      else
         pos = nil
         return sub(str, rx)
      end
   end
end
```


### linepos\(str, offset\) \-> line, col

Returns the line and column corresponding to the given offset\.

The first call for a given string builds up a map of newlines, any subsequent
call will either continue this map or perform a binary search over what
currently exists\.

This is merely good, we could chase optimal by choosing a stride based on the
average line length instead\.


#### weak string cache

```lua
local _nl_map = setmetatable({}, { __mode = 'k' })
```


#### locate\(value, lower, upper\)

  Returns the column if the value is in bounds, or `nil, boolean` where the
second value is `true` if the value is below the boundar\.

```lua
local function locate(value, lower, upper)
   if value > lower
      and value <= upper then
      return value - lower
   elseif value <= lower then
      return nil, true
   else
      return nil, false
   end
end
```


#### tryLine\(target, linum, nl\_map\)

Looks for the target on `linum`\.

Returns either the line and column, or `nil, boolean`, the second value
returning `true` if the correct line is lower, `false` for higher\.

```lua
local function tryLine(target, linum, nl_map)
   --   math.ceil makes this "wobbly" around the limits, so
   --   we clamp accordingly
   if linum > #nl_map then
      linum = #nl_map
   elseif linum < 1 then
      linum = 1
   end
   local prev_nl, next_nl = nl_map[linum - 1] or 0, nl_map[linum]
   local col, lower_than = locate(target, prev_nl, next_nl)
   if col then
      return linum, col
   else
      return nil, lower_than
   end
end
```


### nextLine\(str, target, idx, nl\_map\)

The lazy mapping form of `tryLine`, although here we return the next index to
try if we haven't found the line and column\.

```lua
local function nextLine(str, target, idx, nl_map)
   local prev_nl, next_nl = nl_map[#nl_map] or 0,
                            find(str, "\n", idx)

   if not next_nl then
      -- this works because we pre-exclude target > #str
      next_nl = #str + 1
   end

   nl_map[#nl_map + 1] = next_nl
   local line, col = tryLine(target, #nl_map, nl_map)
   if line then
      --table.clear(nl_map)
      return line, col
   else
     return nil, next_nl + 1
   end
end
```


#### linepos\(str, offset\)

Combines these strategies to get the job done\.

```lua
local ceil = assert(math.ceil)

local function linepos(str, offset)
   local nl_map;
   assert(offset <= #str, "can't find a position longer than the string!")
   if _nl_map[str] then
      nl_map = _nl_map[str]
   else
      nl_map = {}
      _nl_map[str] = nl_map
   end
   local mapped_to = nl_map[#nl_map] or 0

   local line, col, idx = nil, nil, 1
   if offset > mapped_to then
      -- build up the map and return what we find
      idx = mapped_to + 1
      repeat
         line, col = nextLine(str, offset, idx, nl_map)
         if not line then
            idx = col
         end
      until line
   else
      -- binary search
      local stride = ceil(#nl_map / 2)
      local idx = stride
      local lower;
      repeat
         line, lower = tryLine(offset, idx, nl_map)
         if not line then
            stride = ceil(stride / 2)
            if lower then
               idx = idx - stride
            else
               idx = idx + stride
            end
         end
      until line
      -- lower is a boolean until it's a column
      col = lower
   end

   return line, col
end

String.linepos = linepos
```


### lineat\(str, linum\)

Returns the line at the given line number in `str`, as well as the offsets
into the substring, which may prove useful and are in any case handy\.

```lua
function String.lineat(str, linum)
   local nl_map = _nl_map[str]
   if not nl_map then
      -- create the whole thing
      String.linepos(str, #str)
      nl_map = assert(_nl_map[str])
   end
   local last_col = nl_map[linum]
   -- we can signal why this doesn't work
   if not last_col then return "" end

   local first_col = (nl_map[linum - 1] or 0) + 1
   return sub(str, first_col, last_col), first_col, last_col
end
```


### to\_repr\(str\)

makes a \_\_repr\-able table which returns the actual string without markup and
respecting line breaks\.

```lua
local function _str__repr(str_tab)
    return str_tab[1]
end

local _str_M = {__repr = _str__repr}

function String.to_repr(str)
   str = tostring(str)
   return setmetatable({str}, _str_M)
end
```


### String\.slurp\(filename\)

This takes a \(text\) file and returns a string containing its whole contents\.

Uses `tostring()` on `filename` so it can be passed a Path etc\.

```lua
function String.slurp(filename)
  local f = io.open(tostring(filename), "rb")
  if not f then
     error ("no such file: " .. tostring(filename))
  end
  local content = f:read("*all")
  f:close()
  return content
end
```


### String\.spit\(filename, file\)

I'm\.\.\. adding this in late 2021?? what happened?

Guess I wasn't doing as much spitting as I used t/ y'know what? nevermind\.

in it to win it

```lua
function String.spit(filename, file)
  local f = io.open(tostring(filename), "w+")
  if not f then
     error ("no such file: " .. tostring(filename))
  end
  local ok = f:write(file)
  f:close()
end
```


### String\.splice\(to\_split, to\_splice, index\)

Splices `to_splice` into `to_split` at index `index`\.

```lua
local sub = assert(string.sub)

function String.splice(to_split, to_splice, index)
   assert(type(to_split) == "string", "bad argument #1 to splice: "
           .. "string expected, got %s", type(to_split))
   assert(type(to_splice) == "string", "bad argument #2 to splice: "
           .. "string expected, got %s", type(to_splice))
   assert(type(index) == "number", "bad argument #2 to splice: "
          .. " number expected, got %s", type(index))
   assert(index >= 0 and index <= #to_split, "splice index out of bounds")
   local head, tail = sub(to_split, 1, index), sub(to_split, index + 1)
   return head .. to_splice .. tail
end
```

```lua
return String
```
