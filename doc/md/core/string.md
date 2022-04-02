#\* String extensions


- [ ] \#Todo core\.stringable: type\(str?\) = 'string' or hasmetamethod \_\_tostring


### Type Predicate: string\(str?\) \-> boolean

  Each core extension named after a type can be used to test a value for that
primitive type\.

```lua
local function is_string(_, str)
   return type(str) == 'string'
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
local find = assert(string.find)
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


### linepos\(str\) \-> row, col

This is an algorithm which offers significant speed increases after warming up
on a string\.  We'll be using this algorithm in source mapping among other
places\.

Therefore we build up indices into newlines lazily on the first call, and use
or extend that map for any subsequent searches of that string\.


- [#Todo]  This is a straight port of the code in Node, which needs to be
    converted to actually use binary search as documented above\.

  - [ ]  Binary search over map

  - [ ]  Lazy map construction: continue building up the map or binary search
      backward


```lua
local _nl_map = setmetatable({}, { __mode = 'kv' })

local function _findPos(nl_map, target, start)
   local line = start or 1
   local cursor = 0
   local col
   while true do
      if line > #nl_map then
         -- technically two possibilities: node.last is after the
         -- end of str, or it's on a final line with no newline.
         -- the former would be quite exceptional, so we assume the latter
         -- here.
         -- so we need the old cursor back:
         cursor = nl_map[line - 1][1] + 1
         return line, target - cursor + 1
      end
      local next_nl = nl_map[line][1]
      if target > next_nl then
         -- advance
         cursor = next_nl + 1
         line = line + 1
      else
         return line, target - cursor + 1
      end
   end
end
```

```lua
function String.linepos(str, offset)
   local nl_map
   if _nl_map[str] then
      nl_map = _nl_map[str]
   else
      nl_map = findall(str, "\n")
      -- should we add a final here? I think so, #str + 1, fake newline
      _nl_map[str] = nl_map
   end
   if not nl_map then
      -- there are no newlines:
      return 1, offset
   end
   -- otherwise find the offsets
   local line, col = _findPos(nl_map, offset)

   return line, col
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
