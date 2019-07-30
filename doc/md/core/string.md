# String extensions


```lua
local String = {}
```
## String extensions

```lua
local byte = assert(string.byte)
local find = assert(string.find)
local sub = assert(string.sub)
local format = assert(string.format)
```
### utf8(str, [offset])

This takes a string and validates one codepoint, starting at the given
offset (default of 1).


Return is either the (valid) length in bytes, or nil and an error string.

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
### typeformat(str, ...)

Background: I want to start using format in errors and assertions.


It's not as bad to use concatenation in-place for errors, since evaluating
them is a final step.  Assertions run much faster if passed only arguments.


Lua peforms a small number of implicit conversions, mostly at the string
boundary. This is an actual feature since the language has both ``..`` and ``+``,
but it leaves a bit to be desired when it comes to ``string.format``.


``format`` treats any ``%s`` as a request to convert ``tostring``, also treating
``%d`` as a call to ``tonumber``.  The latter I will allow, I'm struggling to find
a circumstance where casting "1" to "1" through ``1`` is dangerous.


What I want is a type-checked ``format``, which I can extend to use a few more
flexible strategies, depending on the context.


Less concerned about hostility and more about explicit coding practices. Also
don't want to undermine hardening elsewhere.


From the wiki, the full set of numeric parameters is
``{A,a,c,d,E,e,f,G,g,i,o,u,X,x}``.  That leaves ``%q`` and ``%s``, the former does
string escaping but of course it is the Lua/C style of escaping.


We add ``%t`` and ``%L`` (for λ), which call ``tostring`` on a table or a function
respectively.  While we're being thorough, ``%b`` for boolean, ``%n`` for ``nil``,
and ``%*`` for the union type.  Why bother with ``nil``, which we can just write?
Type-checking, of course.  We treat ``nil`` as a full type, because in Lua, it
is.


``%t`` will actually accept all remaining compound types: ``userdata``, ``thread``,
and ``cdata``.  For only tables, we can have ``%T``, and also ``%U``, ``%R`` (coRo),
and ``%C``.


Note our ``%L`` is not the C version.  Tempted to have ``%λ`` directly, but
that's a bit weird and it breaks the idea that format sequences are two
bytes long.  While I don't intend to write code that would break in this
case, eh.


``typeformat`` returns the correctly formatted string, or throws an error.

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
### litpat(s)

``%`` escapes all pattern characters.


The resulting string will literally match ``s`` in ``sub`` or ``gsub``.

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
### cleave(str, patt)

Performs the common operation of returning one run of bytes up to ``patt``
then the rest of the bytes after ``patt``.


Can be used to build iterators, either stateful or coroutine-based.

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
#### String.lines(str)

Returns an iterator over the lines of a string.

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
### to_repr(str)

makes a __repr-able table which returns the actual string without markup and
respecting line breaks.

```lua
local function _str__repr(str_tab)
    return str_tab[1]
end

local _str_M = {__repr = _str__repr}

function String.to_repr(str)
   str = tostring(str)
   return setmetatable({str}, {__index = _str_M})
end

```
### codepoints(str, [start], [finish])

Returns an array of the utf8 codepoints in ``str``.


If ``str`` is valid utf8, this array will contain all the original codepoints.
If not, ``codepoints`` will filter out invalid sequences and make a note of
where and what is wrong.


``start`` and ``finish`` are optional integers, specifying offsets into the
string.

```lua
local concat = assert(table.concat)

local cp_M = {}


function cp_M.__tostring(codepoints)
   local answer = codepoints
   if codepoints.err then
      answer = {}
      for i, v in ipairs(codepoints) do
         local err_here = codepoints.err[i]
         answer[i] = err_here and err_here.char or v
      end
   end
   return concat(answer)
end

function String.codepoints(str, start, finish)
   start = start or 1
   finish = (finish and finish <= #str) and finish or #str
   local utf8 = String.utf8
   -- propagate nil
   if not str then return nil end
   -- break on bad type
   assert(type(str) == "string", "codepoints must be given a string")
   local codes = setmetatable({}, cp_M)
   local index = start
   while index <= finish do
      local width, err = utf8(str, index)
      if width then
         local point = sub(str, index, index + width - 1)
         insert(codes, point)
         index = index + width
      else
         -- take off a byte and store it
         local err_packet = { char = sub(str, index, index),
                              err  = err }
         codes.err = codes.err or {}
         insert(codes, "�")
         -- place the error at the same offset in the err table
         codes.err[#codes] = err_packet
         index = index + 1
      end
   end
   return codes
end
```
### String.slurp(filename)

This takes a (text) file and returns a string containing its whole contents.

```lua
function String.slurp(filename)
  local f = io.open(filename, "rb")
  local content = f:read("*all")
  f:close()
  return content
end
```
## Math/number extensions

### String.inbounds(value, lower, upper)

Checks if a value is in bounds in the range lower..upper, inclusive. Either
bound may be omitted, in which case no checking is performed on that end.

```lua
function String.inbounds(value, lower, upper)
  if lower and value < lower then
    return false
  end
  if upper and value > upper then
    return false
  end
  return true
end
```
### String.bound(value, lower, upper)

As ``inbounds``, but answers a value constrained to be within the specified range.

```lua
function String.bound(value, lower, upper)
  if lower and value < lower then
    value = lower
  end
  if upper and value > upper then
    value = upper
  end
  return value
end
```
## Errors and asserts


### Assertfmt

I'll probably just globally replace assert with this over time.


This avoids doing concatenations and conversions on messages that we never
see in normal use.

```lua
local format = string.format

function String.assertfmt(pred, msg, ...)
   if pred then
      return pred
   else
      error(format(msg, ...))
   end
end
```
```lua
return String
```