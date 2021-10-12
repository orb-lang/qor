# Message


Reifies a statement as a Lua table\.

Messages are read\-only, with an open\-ended API which will be incrementally
versioned from 1\.



### Versioning

<<tk>>


#### imports

```lua
local core = require "core:core"
local s = require "status:status"

s.chatty = true

local meta = assert(core.Meta)

local readOnly = assert(core.readOnly)
```


## Message

```lua
local _Message = meta {}
_Message._VERSION = 1
```


### Message API

The array portion of the Message will be parameters, if any, and `.n` is
always used\.  We may as well make `#msg` return `.n` while we're at it\.


#### fields

  This is inherently open\-ended, in that we can make up a new kind of Message
whenever we need one\.  A message can't *just* be array parameters and `.n`,
that would imply some kind of default method we don't necessarily have\.
`__call`?  That seems awkward, I'd rather that be expressed as
`call = true`\.

For a request for action we need some of:


- method:  Says "receiver, call this method with the provided parameters"\.
    Value is a symbol\.  Without `sendto`, the method is called on the
    receiver itself\.


- sendto:  Because it can't be `for`\.  This says "intended for whatever is
    living on the slot with this name"\.  Combines with `method`,
    `message`, and `call`\.

    In general, an Actor can only act on messages using entities on its
    own slots, so that's explicitly the semantic of `sendto`\.  We'll
    find ourselves needing more general dispatch eventually, with event
    Messages, but `sendto` will always mean "send this to your own slot
    with this name"\.


- message:  A Message which is dispatched to whatever is returned from
    dispatching **this** message\. In other words, `{ call = "foo",
    message = { method = "bar", "baz" } }` ultimately evaluates to
    `target.foo():bar("baz")`\.  These may be nested arbitrarily deep
    to produce a chain of calls\.


- call:  Value is either `true` or a symbol\.  If a symbol, call the function
    at that slot with the parameters, if `true`, then call the receiver
    with the parameters\.


- n:  Already mentioned, but for completeness, an integer >= 0 which specifies
    the number of parameters in the array portion of the Message\.


### validate\(msg : ?Message\) \-> msg : Message | \(nil, reason : string\)

Confirms that the putative Message is using the API in a conformant style\.

Since we have only one validator function and the API number is one, we will
eschew the extra complexity of checking first the version \(after molding the
argument as a table\) and then dispatching from an array collection of
validators\.

```lua
local function validate(msg)
   -- table?
   if not type(msg) == 'table' then
      return nil, "message is not a table!"
   end

   -- params?
   if msg.n or #msg > 0 then
      if not msg.method or msg.call then
         return nil, "arguments provided for un-callable message!"
      end
   end

   if msg.call then
      if not type(msg.call) == 'string' or msg.call == true then
         return nil, "message.call not a string or =true=!"
      end
   end

   if msg.message then
      return validate(msg.message)
   end

   return msg
end
```


### new\(msg\)

```lua
local valid = s.chatty and validate or function(a, b) return a, b end


local function new(msg)
   assert(type(msg) == 'table', "#1 must be a table")
   local Msg = {}
   for k, v in pairs(msg) do
      Msg[k] = v
   end
   return valid (readOnly(setmeta(Msg, Message)))
end
```

A message is `target:message(...)`, a call is `target.call(...)` or if call is
`true`, it's `target(...)`\.

\-\-\-\-\-

This gives us everything we need for an Actor to take action, but it then
needs to reply in many cases, so we need more for that\.

Note that *every* field in the above is optional, because a reply is also a
Message, and a reply doesn't have to come with a request for action, it can
just be an envelope around a payload\.

So we'll need some more fields\.  Here's a tentative list, I expect we'll be
working on this one for awhile to get it right\.


- sender:  A name for the Actor sending the message\.  This has some
    implications, in terms of wanting an Actor base class which knows
    its own name, and can craft Messages which provide that without
    explicitly adding it as a parameter\.


- reply:  A flag\.  When set to `true`, the Actor receiving the message is
    expected to package up the return value of the method call into a
    Message and send it back\.

    Note that this is *a* mechanism, not *the* mechanism, for handling
    the result of a Message\.  I'll discuss more options below when we
    start to flesh out the coroutine loop for Maestro activities\.

    Just noting here that sometimes an Actor is in a position to hand
    off return values directly, and when that's the case, that's what we
    should do\.



- replyto:  I don't love this name, but `returnto` isn't great either, so it
    will do for a discussion\.  The default reply is back to the sender,
    but the payload might not be intended directly for the sender, but
    rather someone living on one of his slots\.

> @daniels: I would YAGNI this for now, and implement it as `replypath`
   analogous with `sendpath` if/when we need it\.

@atman:


- ret:  An ntable containing the return values of a reply Message\.  This is
    what we call packaged return values in Valiant, and I see no reason to
    change that\.  I'd say that we want the array portion of a Message to
    be only used for method\-call parameters, because reusing it to return
    a payload in a reply would be confusing\.

The intention here is that `sender` is used to route the reply Message, and
`replyto` becomes `sendto` in the reply \(when present\)\.  That gets us one
level deep, and only covers the case where the reply Message goes back to the
Actor who sent the first Message\.

We can and should extend the protocol when we have more complex routing, but
we should also avoid this\!  Abstractions should pull their weight, and we
don't want the benefits we get from using an Actor\-Message architecture to
evaporate in weird bespoke control flow, with actions bouncing around some
complex addressing scheme which has to be stepped through to really understand\.

Unless we have no other choice, and at some point that might be the case\.

It's always tempting to keep going on this kind of design work, but at the
moment it's unclear when we'll even use some of these fields\.  It would make
sense for Maestro to include a request for a reply to a mouse click, but by
definition it doesn't know which Agent needs to handle it until Zoneherd
figures that out, and we don't really have to *tell* Zoneherd to reply, it's
smart enough to just do that\.

So let's take a look at the Maestro action loop\.  At some point the Message
specific parts of this document will get broken out into a distinct Message
project, for now, these topics are related in a "what happens next" sort of
way, more than anything\.
