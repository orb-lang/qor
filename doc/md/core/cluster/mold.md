# Mold


### Message\.mold\(msg\)

  Confirms validity of a Message, returning one of `(msg, check)` or
`(nil, check)`\.

**Very** much an open question how this works\.

```lua
local _Message_fields = {
   method  = true,
   message = true,
   sendto  = true,
   call    = true,
}
```