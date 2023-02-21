# Function Sets


## What

A set is a sort of composable membership test\.

Our literal sets are discrete: we take a collection and map the elements as
keys, with the value `true`\.  This `set[elem]` is our membership test, and
we overload arithmetic to compose these\.

Function sets are indexable tables backed by functions, with operator
overloading which composes both with other function sets and with discrete
sets\.

Let's write shall we\.

```lua
local FSet, FSet_m = {}, {}
```

It might be worth 'clusterizing' this once we have a recipe for functional
indexing\.


#### operators

All of these will call `new` in the process of creating a new FSet, so we
predeclare them\.

```lua
local __add, __sub, __mod, __unm;
```

Because we provide `#set` for literal sets, we should throw an error if an
attempt is made to get the length\.  It will otherwise return 0, which looks
like a real answer, but isn't meaningful\.

```lua
local __len;
```

Arguably this could return a NaN, but I tend to regret that sort of
cleverness\.

As far as subset and equality go, we're not completely helpless, but it poses
a dilemma, because comparators are boolean and we've introduced a situation
where some combinations are impossible\.

One place I'm okay with getting a wrong answer sometimes is equality, where
we can cache the underlying functions in, you guessed it, a weak table, and
check that they have pointer identity\.

Two different wrappers around `type(elem) == 'string'` will test as
unequal, fine, don't do that then\.  This is one of the reasons why contracts
are being written, so that various cheap and useful functions which get used
in various contexts will all be the same object\.

Subset and proper subset work fine if one arm of the comparator is literal,
but I don't see a proper answer for comparison of two function sets which
isn't throwing an error\.

The degree of wrong answer is greater here if we say that `short` is not a
proper subset of `long` \(let's say the test is that `#elem` is 3 for the
first and 7 for the second\), it should be an error to compare them since the
contents are opaque to us\.

So error it is, because an idiom like `{2, 4, 5, 6} < is_even` is too useful
to pass up\.

```lua
local __eq, __lt, __lte;
```


### new\(fn: \(one\) \-> truthy\) \-> FSet

  We adjust the function signature so that the table itself is ignored by the
predicate function\.

Take care that the predicate function can throw no errors\! "The code has
broken" is not a membership test\.


#### spread\(fn: \(<T1>\) \-> <T2>\) \-> \(one, <T1>\) \-> true | nil

How's that for a type signature\.\.\.

The return signature splits the difference between three sorts of predicate\.
Since literal sets naturally test `true` or `nil`, we want the function
version to do so, even if it's handed a true predicate returning `boolean` or
a value\-returning predicate of type `<T> | nil`\.

```lua
local function spread(fn)
   return function(_, a)
      return fn(a) and true or nil
   end
end
```

```lua
local function readonly(tab, key, val)
   error("can't assign " .. key .. " to a function set")
end

local function new(fn)
   local fset = setmetatable({}, { __index = spread(fn),
                                   __add = __add,
                                   __sub = __sub,
                                   __mod = __mod,
                                   __len = __len,
                                   __unm = __unm,
                                   -- comparators, negative
                                   __newindex = readonly, })
   return fset
end
```


### Union: \_\_add   set \+ set

```lua
__add = function(left, right)
   return new(function(elem)
      return left[elem] or right[elem]
   end)
end
```


### Difference: \_\_sub set \- set

```lua
__sub = function(left, right)
   return new(function(elem)
      return (left[elem] and (not right[elem])) or nil
   end)
end
```


### Intersection: \_\_mod set % set

```lua
__mod = function(left, right)
   return new(function(elem)
      return left[elem] and right[elem]
   end)
end
```


### Negation: \_\_unm \-set

```lua
__unm = function(set)
   return new(function(elem)
      return (not elem) or nil
   end)
end
```


### Len: \#set \(how do we write an error?\)

We're better off throwing errors on questions we can't generally answer\.

```lua
__len = function() error("can't take the length of a function set") end
```

```lua
return new
```