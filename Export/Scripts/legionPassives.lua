if not loadStatFile then
	dofile("statdesc.lua")
end
--loadStatFile("stat_descriptions.txt")
loadStatFile("passive_skill_stat_descriptions.txt")

local out = io.open("../Data/3_0/LegionPassives.lua", "w")

local stats = dat"Stats"
local alternatePassiveSkillDat = dat"AlternatePassiveSkills"
local alternatePassiveAdditionsDat = dat"AlternatePassiveAdditions"

local LEGION_PASSIVE_GROUP = 1e9

---@type fun(thing:string|table|number):string
function stringify(thing)
	if type(thing) == 'string' then
		return thing
	elseif type(thing) == 'table' then
		local s = "{";

		for k,v in pairs(thing) do
			--thing[k] = stringify(v);
			s = s.."\n\t"

			if type(k) == 'number' then
				s = s.."["..k.."] = "
			else
				s = s.."[\""..k.."\"] = "
			end

			if type(v) == 'string' then
				s = s.."\""..stringify(v).."\", "
			else
				if type(v) == "boolean" then
					v = v and "true" or "false"
				end

				val = stringify(v)..", "

				if type(v) == "table" then
					val = string.gsub(val, "\n", "\n\t")
				end

				s = s..val;
			end
		end

		return s.."\n}"
	elseif type(thing) == 'number' then
		return ""..thing;
	end
end 

---@type table <string, table> @this is the structure used to generate the final data file Data/3_0/LegionPassives
local data = {};
data.nodes = {};
data.groups = {};
data.additions = {};

local ksCount = -1;

for i=1, alternatePassiveSkillDat.rowCount do
	---@type table<string, boolean|string|number>
	local datFileRow = {};

	for j=1,#alternatePassiveSkillDat.cols-1 do
		local key = alternatePassiveSkillDat.spec[j].name
		datFileRow[key] = alternatePassiveSkillDat:ReadCell(i, j)
	end

	---@type table<string, boolean|string|number|table>
	local legionPassiveNode = {};

	-- id
	legionPassiveNode.id = datFileRow.Id;
	-- icon
	legionPassiveNode.icon = datFileRow.DDSIcon;
	-- is keystone
	legionPassiveNode.ks = isValueInTable(datFileRow.PassiveType, 4) and true or false

	if legionPassiveNode.ks then ksCount = ksCount + 1 end

	-- is notable
	legionPassiveNode['not'] = isValueInTable(datFileRow.PassiveType, 3) and true or false
	-- node name
	legionPassiveNode.dn = datFileRow.Name;
	-- is "mastery" ??
	legionPassiveNode.m = false
	-- self explanatory
	legionPassiveNode.isJewelSocket = false
	legionPassiveNode.isMultipleChoice = false
	legionPassiveNode.isMultipleChoiceOption = false
	legionPassiveNode.passivePointsGranted = 0
	-- something to do with tree starting positions
	legionPassiveNode.spc = {}
	-- display text TODO
	legionPassiveNode.sd = {}

	legionPassiveNode.stats = {}

	for idx,statKey in pairs(datFileRow.StatsKeys) do
		refRow = statKey._rowIndex
		statId = stats:ReadCell(refRow, 1)
		range = datFileRow["Stat"..idx]

		legionPassiveNode.stats[statId] = {
			["min"] = range[1],
			["max"] = range[2],
		}
	end

	for _, line in ipairs(describeStats(legionPassiveNode.stats)) do
		table.insert(legionPassiveNode.sd, line)
	end

	--

	-- TODO node group. everything has a group
	legionPassiveNode.g = LEGION_PASSIVE_GROUP
	-- 
	-- group orbit distance
	legionPassiveNode.o = legionPassiveNode.ks and 4 or 3
	legionPassiveNode.oidx = legionPassiveNode.ks and ksCount * 3 or math.floor(math.random() * 1e5)
	-- attributes granted 
	legionPassiveNode.sa = 0
	legionPassiveNode.da = 0
	legionPassiveNode.ia = 0
	-- connected nodes
	legionPassiveNode.out = {}
	legionPassiveNode["in"] = {}
	-- legion flag, so pob knows to handle the data in special ways
	legionPassiveNode.legion = true
	data.nodes[legionPassiveNode.id] = legionPassiveNode;
end

data.groups[LEGION_PASSIVE_GROUP] = {
    ["x"] = -6500,
    ["y"] = -6500,
    ["oo"] = {},
    ["n"] = {}
}

for k,v in pairs(data.nodes) do
	table.insert(data.groups[LEGION_PASSIVE_GROUP].n, k)
end

for i=1, alternatePassiveAdditionsDat.rowCount do
	---@type table<string, boolean|string|number>
	local datFileRow = {};

	for j=1,#alternatePassiveAdditionsDat.cols-1 do
		local key = alternatePassiveAdditionsDat.spec[j].name
		datFileRow[key] = alternatePassiveAdditionsDat:ReadCell(i, j)
	end

	---@type table<string, boolean|string|number|table>
	local legionPassiveAddition = {};

	-- id
	legionPassiveAddition.id = datFileRow.Id;
	-- Additions have no name, so we construct one for the UI (also, Lua regex is too limiting :( )
	legionPassiveAddition.dn = string.gsub(string.gsub(string.gsub(datFileRow.Id, "_", " "), "^%w* ", ""), "^%w* ", "")
	legionPassiveAddition.dn = legionPassiveAddition.dn:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	-- stat descriptions
	legionPassiveAddition.sd = {};

	legionPassiveAddition.stats = {}

	for idx,statKey in pairs(datFileRow.StatsKeys) do
		refRow = statKey + 1
		statId = stats:ReadCell(refRow, 1)
		range = datFileRow["Stat"..idx]

		legionPassiveAddition.stats[statId] = {
			["min"] = range[1],
			["max"] = range[2],
		}
	end

	for _, line in ipairs(describeStats(legionPassiveAddition.stats)) do
		table.insert(legionPassiveAddition.sd, line)
	end

	data.additions[legionPassiveAddition.id] = legionPassiveAddition;
end

str = stringify(data)

out:write("-- This file is automatically generated, do not edit!\n-- Item data (c) Grinding Gear Games\n\n")
out:write("return "..str)

out:close()

print("Legion passives exported.")