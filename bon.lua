local DEBUG = true
local DEBUG_EXTENDED = false

local cpu = os.clock
if(VERSIONSTR) then
	cpu = SysTime
end

local startTime = cpu()
local function log(...)
	if DEBUG_EXTENDED then
		local time = cpu() - startTime
		print("[bON] [T+"..string.format("%.3f",time*1000).."ms]",...)
	end
end
local function logWarn(...)
	if DEBUG then
		local time = cpu() - startTime
		print("[bON] [T+"..string.format("%.3f",time*1000).."ms]","[Warning]",...)
	end
end

--globals
local type = type
local tonumber = tonumber
local tostring = tostring

--table
local t_concat = table.concat

--string
local s_gsub = string.gsub
local s_sub = string.sub
local s_format = string.format
local s_match = string.match
local s_byte = string.byte
local s_char = string.char
local s_find = string.find
local pattern_escape_replacements = {
	["("] = "%(",
	[")"] = "%)",
	["."] = "%.",
	["%"] = "%%",
	["+"] = "%+",
	["-"] = "%-",
	["*"] = "%*",
	["?"] = "%?",
	["["] = "%[",
	["]"] = "%]",
	["^"] = "%^",
	["$"] = "%$",
	["\0"] = "%z"
}
local s_patternEscape = function(str)
	return (str:gsub(".",pattern_escape_replacements))
end

--main
local dictionaryLookup = {}
local specialCodes = {}
local specialCodesLookup = {}
local deserializeTypes = {}
local serializeTypes = {}

local reservedChars = {
	"\\",
	"=",
	";",
	"{",
	"}",
	"[",
	"]",
	--"\0"
}

local stringEscapeTable = {}
local stringUnescapeTable = {}
for i=1,#reservedChars do
	stringEscapeTable[reservedChars[i]] = s_format("\\%01x",i)
	stringUnescapeTable[s_format("\\%01x",i)] = reservedChars[i]
end

local reservedCharsString = "[%"..t_concat(reservedChars,"%").."]"
local reservedCharsStringEx = "[^%"..t_concat(reservedChars,"%").."]"

local function escapeSpecial(str)
	return (s_gsub(str,reservedCharsString,stringEscapeTable))
end

local function unescapeSpecial(str)
	return (s_gsub(str,"\\(.)",stringUnescapeTable))
end

local function registerSerializer(params)
	specialCodes[params.type] = params.code
	specialCodesLookup[params.code] = params.type
	serializeTypes[params.type] = params.serialize
	deserializeTypes[params.code] = params.deserialize
end

local function serializeAny(obj,dictionary)
	--first check if it has already been serialized
	local dictionaryValue = dictionary[obj]
	if(dictionaryValue ~= nil) then
		--log("recurseDict")
		return dictionaryValue
	else
		local obj_type = type(obj)
		if(obj_type == "table") then
			--log("newTable")
			--if it's a table that hasn't already been serialised, begin a new table block
			local out = {"{"}

			dictionaryLookup[dictionary] = dictionaryLookup[dictionary] + 1
			dictionary[obj] = dictionaryLookup[dictionary]

			--save all ordered keys
			local ordered = {}

			for i=1,#obj do
				ordered[i] = true
				out[#out+1] = serializeAny(obj[i],dictionary)
			end

			for k,v in next,obj do
				if(not ordered[k]) then
					--don't resereialize ordered table entries
					out[#out+1] = serializeAny(k,dictionary).."="..serializeAny(v,dictionary)
				end
			end

			dictionaryLookup[obj] = dictionaryIndex
			return t_concat(out,";")..";}"
		else
			local serializer = serializeTypes[obj_type]
			if(serializer) then
				--normal serialize
				--log("newSerialize")
				dictionaryLookup[dictionary] = dictionaryLookup[dictionary] + 1
				dictionary[obj] = dictionaryLookup[dictionary]
				local code,data = serializer(obj)
				return code..data
			else
				--unknown type.
				logWarn("Unknown type "..obj_type.."! Skipping.")
				return serializeAny("unknown",dictionary)
			end
		end
	end
end

local function serialize(tbl)
	local dictionary = {}
	dictionaryLookup[dictionary] = 0
	local out = serializeAny(tbl,dictionary)
	dictionaryLookup[dictionary] = nil
	return out
end

local function getNextBlock(str,JMP)
	if(s_sub(str,JMP,JMP) == "{") then
		local start,finish = s_find(str,"%b{}",JMP)
		if not (start or finish) then
			error("Stuck! "..s_sub(str,n,-1).."\t"..tostring(start)..", "..tostring(finish))
		end

		return s_sub(str,start,finish+1),finish+2,true
	else
		local start,finish = s_find(str,"^([^=;]*)",JMP)
		if not (start or finish) then
			error("Stuck! "..s_sub(str,JMP,-1).."\t"..tostring(start)..", "..tostring(finish))
		end
		local out = s_sub(str,start,finish+1)

		return out,finish+2,false
	end
end

local function deserializeBlock(str,dictionary)
	local lookup = dictionary[tonumber(str)]
	if(lookup ~= nil) then
		return lookup
	else
		local code,data = s_match(str,"(.)(.*)")
		local deserializer = deserializeTypes[code]
		if(deserializer) then
			local obj = deserializer(data,dictionary)
			dictionary[#dictionary+1] = obj
			return obj
		else
			error("Unknown type code \""..code.."\"")
		end
	end
end

local function deserializeAny(str,dictionary)
	local out = {}
	dictionary[#dictionary+1] = out
	local lastKey
	local section = ""
	local JMP = 2
	while JMP < #str do
		section,JMP,isTableBlock = getNextBlock(str,JMP)
		--log(JMP,"section",section)
		if(isTableBlock) then
			local tableSection,operand = s_match(section,"^(.-)([;=]+)$")

			--log(JMP,"tableSection",tableSection)
			if(operand == "=") then
				--log(JMP,"tableSaveKey")
				lastKey = deserializeAny(tableSection,dictionary)
			else
				if(lastKey ~= nil) then
					--log(JMP,"tableSaveToKey",lastKey)
					out[lastKey] = deserializeAny(tableSection,dictionary)
					lastKey = nil
				else
					--log(JMP,"tableSaveToIndex")
					out[#out+1] = deserializeAny(tableSection,dictionary)
				end
			end
			--log(JMP,"endTable",operand)
		else
			if(section == ";") then return out end
			local data,operand = s_match(section,"^(.+)(.)$")
			--log(JMP,"data",data,"operand",operand)

			if(operand == "=") then
				lastKey = deserializeBlock(data,dictionary)
			else
				if(lastKey ~= nil) then
					out[lastKey] = deserializeBlock(data,dictionary)
					lastKey = nil
				else
					out[#out+1] = deserializeBlock(data,dictionary)
				end
			end
		end
	end

	return out
end

local function deserialize(str)
	return deserializeAny(str,{})
end

registerSerializer {
	code = "s",
	serialize = function(var)
		return "s",escapeSpecial(var)
	end,
	deserialize = function(data)
		return unescapeSpecial(data)
	end,
	type = "string"
}

registerSerializer {
	code = "n",
	serialize = function(var)
		--return s_format("%x",var)
		return "n",var
	end,
	deserialize = function(data)
		--return tonumber(data,16) or 0
		return tonumber(data) or 0
	end,
	type = "number"
}

registerSerializer {
	code = "b",
	serialize = function(var)
		if var then
			return "T",""
		else
			return "F",""
		end
	end,
	type = "boolean"
}

registerSerializer {
	code = "F",
	deserialize = function()
		return false
	end,
	type = "_"
}

registerSerializer {
	code = "T",
	deserialize = function()
		return true
	end,
	type = "__"
}

return {
	serialize = serialize,
	deserialize = deserialize,
	VERSION = 27092015,
	VERSIONSTR = "27/09/2015"
}
