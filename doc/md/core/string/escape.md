# Lua string escape/unescape functions

Functions to escape nonprinting characters and \(optionally\) quotes in a string
so it can be used as a string literal, and to reverse this process\.
We leave the type of quotes to escape up to the caller, so as to avoid being
overzealous when used to produce output for display\.


#### imports

Because there are multiple distinct kinds of escape sequencee\.g\. `\n`, `\"`, `\xNN`\), we can't handle escaping in a single call to
`string.gsub`
\(, so we upgrade to `lpeg`\.

```lua
local L = require "lpeg"
local elpatt = require "espalier:elpatt"
local C, P, R, S = assert(L.C), assert(L.P), assert(L.R), assert(L.S)
local gsub, M = assert(elpatt.gsub), assert(elpatt.M)
```


```lua
local escape_module = {}
```


## escape\(str, quotes\), escape\_char\(ch, quotes\)

Escapes `str` so it contains only printable characters\. If `quotes` is
provided, also escapes those characters \(by preceding them with a backslash\),
making the result safe to turn into a quoted string literal\.

`escape_char` assumes the argument is a single character\-\-useful in code that
is already looping through one character at a time, e\.g\. because the string
has already been split into `Codepoints`\.

```lua
local escape_map = {
   ["\\"] = "\\\\",
   ["\a"] = "\\a",
   ["\b"] = "\\b",
   ["\f"] = "\\f",
   ["\n"] = "\\n",
   ["\r"] = "\\r",
   ["\t"] = "\\t",
   ["\v"] = "\\v"
}

local function _generic_escape(ch)
   return ("\\x%02x"):format(ch:byte())
end

local needs_escape = M(escape_map) + (R"\x00\x1f" + P"\x7f") / _generic_escape

function escape_module.escape(str, quotes)
   local patt = needs_escape
   if quotes then
      patt = S(quotes) / "\\%0" + patt
   end
   return gsub(str, patt)
end

function escape_module.escape_char(ch, quotes)
   local escaped = escape_map[ch]
   if escaped then
      return escaped
   elseif quotes and quotes:find(ch) then
      return "\\" .. ch
   elseif ch:find("%c") then
      return _generic_escape(ch)
   else
      return ch
   end
end
```


## unescape\(str\)

Unescapes `str`, interpreting all possible escaped quoting characters\.

```lua
local char = assert(string.char)

local unescape_map = {}
for k, v in pairs(escape_map) do
   unescape_map[v] = k
end

local higit = R"09" + R"af"

local escaped_char = M(unescape_map) +
                     (P"\\" * C(S"'\"[]")) / 1 +
                     (P"\\x" * C(higit * higit)) / function(hex)
                        return char(tonumber("0x" .. hex))
                     end

function escape_module.unescape(str)
   return gsub(str, escaped_char)
end
```

```lua
return escape_module
```