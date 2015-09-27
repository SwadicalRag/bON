# Banana Object Notation
A (reasonably) fast, compact (non-)human-readable table serialization library for Lua

## Purpose
To store huge tables in a string format with no problems and retrieve tables back from strings as quickly as possible.

## Where is this used?
Nowhere D: (yet)

## How is bON different?
As of version 27092015, bON:
 - Automatically detects ordered keys and does not serialize their value.
 - Washes your dishes (maybe)
 - Handles any type of recursing tables (even tables that recurse through their keys!)
 - Does your homework for you. (sometimes)
 - Re-uses table keys and values where possible, saving huge amounts of data with big tables.

## Benchmarks? Benchmarks.
Against [vON](https://github.com/vercas/vON):

(tested with no recursion, as vON did not like recursing tables when I tested)

Tested with LuaJIT 2.1.0-alpha
#### Table used (derived from the vON example):
```lua
local tbl = {
    1, -1337, -99.99, 2, 3, 100, 101, 121, 143, 144, "ma\"ra", "are", "mere",
    {
        500,600,700,800,900,9001,
        [true] = false,
        [false] = "lol?",
        pere = true,
        [1997] = "vasile",
        [{ [true] = false, [false] = true }] = { [true] = "true", ["false"] = false }
    },
    true, false, false, true, false, true, true, false, true,
    [1337] = 1338,
    mara = "are",
    mere = false,
    [true] = false,
    [{ [true] = false, [false] = true }] = { [true] = "true", ["false"] = false },
	ayy = "lmao",
	memes = {
		XD = "wow",
		tableInsideTable = {
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow",
			"wow",
			"wow",
			"wow",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow",
			"wow!!!!!!!!!!!!!!!!!!!",
			"wow",
			"wow",
			"wow"
		},
		tooMuchSwag = {
			"because i am swad"
		}
	},
	whoo = 1234
}

--[[
tbl.recursion = tbl
tbl.memes.recurse = tbl
]]
```

#### sON output:
``
{;n1;n-1337;n-99.99;n2;n3;n100;n101;n121;n143;n144;sma"ra;sare;smere;{;n500;n600;n700;n800;n900;n9001;F=slol?;T=22;n1997=svasile;{;22=24;24=22;}={;sfalse=22;24=strue;};spere=24;};24;22;22;24;22;24;24;22;24;swhoo=n1234;24=22;smemes={;stooMuchSwag={;sbecause i am swad;};stableInsideTable={;swow!!!!!!!!!!!!!!!!!!!;41;41;41;swow;41;42;41;42;42;42;42;41;42;41;42;42;42;};sXD=42;};sayy=slmao;{;22=24;24=22;}={;29=22;24=30;};n1337=n1338;smara=13;14=22;}
``
#### vON output:
``
n1;n-1337;n-99.99;n2;n3;n100;n101;n121;n143;n144;"ma\"rav""arev""merev"{n500;n600;n700;n800;n900;n9001~b0:"lol?v"b1:0{~b0:11:0}:{~"falsev":b01:"truev"}n1997:"vasilev""perev":b1}b100101101~"marav":"arev"b1:0"whoov":n1234;n1337:n1338;"ayyv":"lmaov""memesv":{~"tableInsideTablev":{"wow!!!!!!!!!!!!!!!!!!!v""wow!!!!!!!!!!!!!!!!!!!v""wow!!!!!!!!!!!!!!!!!!!v""wow!!!!!!!!!!!!!!!!!!!v""wowv""wow!!!!!!!!!!!!!!!!!!!v""wowv""wow!!!!!!!!!!!!!!!!!!!v""wowv""wowv""wowv""wowv""wow!!!!!!!!!!!!!!!!!!!v""wowv""wow!!!!!!!!!!!!!!!!!!!v""wowv""wowv""wowv"}"XDv":"wowv""tooMuchSwagv":{"because i am swadv"}}"merev":b0{~b0:11:0}:{~"falsev":b01:"truev"}
``

#### Benchmark output (using os.clock):
```
sON serialization       448     characters
vON serialization       633     characters
Serialization
bON: 0.168 sec
vON: 0.135 sec
vON wins by 124.44444444444%
Deserialization
bON: 0.001 sec
vON: 0.053 sec
bON wins by 5300%
```

#### Example Usage
First, place ``bon.lua`` somewhere in your working directory

In GLua:
```lua
local bON = CompileFile("path/to/bon.lua")()
local tbl = {"wow!"}

local serialized = bON.serialize(tbl)
print(serialized)

local deserialized = bON.deserialize(serialized)
PrintTable(tbl)
PrintTable(deserialized)
```

In Lua:
```lua
local bON = dofile("path/to/bon.lua")
local tbl = {"wow!"}

local serialized = bON.serialize(tbl)
print(serialized)

local deserialized = bON.deserialize(serialized)
for k,v in pairs(tbl) do
    print(k,v)
end
for k,v in pairs(deserialized) do
    print(k,v)
end
```
