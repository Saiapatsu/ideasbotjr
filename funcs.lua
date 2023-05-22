-- Read messages
-- Send messages
-- Add emoji

-- Moderation perms, unusable without verification >:(
-- Manage Messages: delete messages and emoji
-- Manage roles (to add/remove the role)

--------------------------------------------------

local fs = require "fs"
local env = getfenv()

-- Reused as a rope to reduce GC pressure
local staticRope = {}

channelsMessage = {}
channelsReaction = {}

local msgConsole = {
	fake = true,
	reply = function(self, ...) return print(...) end,
}

--------------------------------------------------

function async(fn, ...)
	return coroutine.wrap(fn)(...)
end

function try(fn, ...)
	if fn == nil then return end
	local success, err = pcall(fn, ...)
	if not success then
		print("Error: " .. err)
		-- stop()
	end
end

function messageIsImage(message)
	return message.attachment or message.embed or message.content:find("https?://")
end

function scold(message)
	-- async(message.delete, message)
	local reply = message.channel:sendf("<@%s> Please, only send images and links in this channel.", message.author.id)
	timer.sleep(4000)
	reply:delete()
end

function messageHasReaction(message, hash)
	for _,v in pairs(message.reactions) do
		if v.emojiHash == hash then return true end
	end
	return false
end

function alertme(where)
	print(os.date() .. " /!\\ Bot is alive in \a" .. where)
end

--------------------------------------------------

local function parseListFromFile(path)
	local list = {}
	for line in fs.readFileSync(path):gmatch("[^\r\n]+") do
		-- completely ignoring bayonet for now
		line = line:match("^[ \t]*([^;#]*)") -- strip leading tabs, comment and trailing ;bayonet
		line = line:match("(.-) *$") -- strip trailing spaces from bayonet
		if line ~= "" then
			table.insert(list, line)
		end
	end
	return list
end

local function pick(tbl)
	return tbl[math.random(#tbl)]
end

--------------------------------------------------

guildTest = {
	upvote = "\xE2\x9A\xA0\xEF\xB8\x8F", -- warning
	downvote = "\xF0\x9F\x90\xB4", -- horse
	weekly = "okbud:1070367873891041351",
	roleFreedom = "936745626048294923", -- rancid
	roleDownvote = "1070364517604802671", -- redditor
	showcase = "1070158816001396767", -- #boten
	weekly = "1030063439160295435", -- #emoji
	bots = "1070158816001396767", -- #boten
}

guildIdeas = {
	upvote = "upvote:539111244842532874",
	downvote = "downvote:539111244414844929",
	weekly = "Weekly:742160530353160192",
	roleFreedom = "309090145099972608", -- unbound
	roleDownvote = "1075535684368081108", -- downvote
	showcase = "520457693979213833",
	weekly = "742157612879183993",
	bots = "309121149592403980",
}

guilds = {
	["517339055831384084"] = guildTest,
	["309088417466023936"] = guildIdeas,
}

function messageCanDoAnything(dataGuild, message)
	return message.member:hasRole(dataGuild.roleFreedom)
end

function messageCanBeDownvoted(dataGuild, message)
	return message.member:hasRole(dataGuild.roleDownvote) or message.content:find(dataGuild.downvote, 1, true)
end

--------------------------------------------------

function messageHandlerShowcase(message)
	local dataGuild = guilds[message.guild.id]
	if dataGuild == nil then return end
	alertme("showcase")
	p(message.content)
	if messageIsImage(message) then
		async(message.addReaction, message, dataGuild.upvote)
		if messageCanBeDownvoted(dataGuild, message) then
			message:addReaction(dataGuild.downvote)
		end
	elseif messageCanDoAnything(dataGuild, message) then
		-- keep it
	else
		scold(message)
	end
end

function messageHandlerWeekly(message)
	local dataGuild = guilds[message.guild.id]
	if dataGuild == nil then return end
	alertme("weekly")
	p(message.content)
	if messageIsImage(message) then
		message:addReaction(dataGuild.weekly)
	elseif messageCanDoAnything(dataGuild, message) then
		-- keep it
	else
		scold(message)
	end
end

--------------------------------------------------

local chances = {} -- [()->()]: number
local function commit(chance, fn)
	chances[fn] = chance
	return fn
end

-- Append all table arguments into first table
local function append(a, b, ...)
	if b == nil then return a end
	for k,v in pairs(b) do a[k] = v end
	return append(a, ...)
end

local listModObject = parseListFromFile "dict\\mod object" -- object only
local listModLocationObject = parseListFromFile "dict\\mod location object" -- object and location common
local listLocations = parseListFromFile "dict\\locations"
local listObjects = parseListFromFile "dict\\objects"
append(listModObject, listModLocationObject)

local function juxtapose(a, b)
	return string.format("%s %s", pick(a), pick(b))
end
local function ofthe(a, b)
	return string.format("%s of the %s", pick(a), pick(b))
end

local makeItemModObject = commit(#listModObject * #listObjects, function()
	return juxtapose(listModObject, listObjects)
end)
local makeItemObjectOfTheMod = commit(#listModObject * #listObjects, function()
	return ofthe(listObjects, listModObject)
end)
local makeDungeonModObject = commit(#listModLocationObject * #listLocations, function()
	return juxtapose(listModLocationObject, listLocations)
end)
local makeDungeonPlaceOfTheMod = commit(#listModLocationObject * #listLocations, function()
	return ofthe(listLocations, listModLocationObject)
end)

local function makeItem()
	local aaa = chances[makeItemModObject]
	local max = aaa + chances[makeItemObjectOfTheMod]
	local n = math.random(max)
	if n > aaa then
		return makeItemObjectOfTheMod()
	else
		return makeItemModObject()
	end
end

local function makeDungeon()
	local n = math.random(2)
	if n == 1 then
		return makeDungeonPlaceOfTheMod()
	else
		return makeDungeonModObject()
	end
end

local function generator(fn, message, str, pos)
	-- .command
	-- .command 1
	-- .command asdasd
	-- Parse amount of things to generate, limit it to a small number unless console
	local count, pos = string.match(str, "^%s*([^ ]*)()", pos)
	if not message.fake then
		count = math.min(8, tonumber(count) or 1)
	end
	
	for i = 1, count do
		staticRope[i] = fn()
	end
	
	message:reply(table.concat(staticRope, "\n", 1, count))
end

-- for the console
function item(str) return generator(makeItem, msgConsole, tostring(str), 1) end
function dungeon(str) return generator(makeDungeon, msgConsole, tostring(str), 1) end

--------------------------------------------------

local nextHelp = 0

function messageHandlerBots(message)
	local dataGuild = guilds[message.guild.id]
	if dataGuild == nil then return end
	local str = message.content
	if str:sub(1, 1) ~= "." then return end
	alertme("bots")
	p(message.content)
	local word, pos = str:match("^(%S+)()", 2)
	if word == nil then
		-- space between dot and word: do nothing
	elseif word == "item" then
		generator(makeItem, message, str, pos)
	elseif word == "dungeon" then
		generator(makeDungeon, message, str, pos)
	elseif word == "help" then
		-- Throttle usage of this command just in case
		local now = os.clock()
		if now < nextHelp then return end
		nextHelp = now + 10
		message:reply([[
I manage the reactions in <#]] .. dataGuild.showcase .. [[> and <#]] .. dataGuild.weekly .. [[> since 2023-02-01 and generate item ideas in <#]] .. dataGuild.bots .. [[ since 2023-04-20.
Read my source code and wordlist at: <https://github.com/Saiapatsu/ideasbotjr>
To get a downvote, upvote your own message in #showcase (and then remove it because you should not self-upvote), write <:]] .. dataGuild.downvote .. [[> in your message (can't edit it in yet), ask an Unbound to downvote you or ask staff for the <@&]] .. dataGuild.roleDownvote .. [[> role.
Write .item in this channel to get an item name and .dungeon to get a dungeon name.
]])
	end
end

--------------------------------------------------

function reactionHandlerShowcase(reaction, userId, message)
	local dataGuild = guilds[message.guild.id]
	if dataGuild == nil then return end
	if messageCanDoAnything(dataGuild, message) then return end
	if message.author.id == userId and reaction.emojiHash == dataGuild.upvote then
		-- On self-upvote:
		-- If there is no downvote, add one, otherwise remove own upvote.
		-- Afterward, remove user's upvote.
		if messageHasReaction(message, dataGuild.downvote) then
			async(message.removeReaction, message, dataGuild.upvote)
		else
			async(message.addReaction, message, dataGuild.downvote)
		end
		-- Can't have shit without Manage Messages
		-- message:removeReaction(dataGuild.upvote, userId)
	end
end

function reactionHandlerWeekly(reaction, userId, message)
	local dataGuild = guilds[message.guild.id]
	if dataGuild == nil then return end
	if messageCanDoAnything(dataGuild, message) then return end
	if message.author.id == userId and reaction.emojiHash == dataGuild.weekly then
		message:removeReaction(dataGuild.weekly, userId)
	end
end

--------------------------------------------------

local guild = guildTest

channelsMessage[guild.bots] = messageHandlerBots
channelsReaction[guild.showcase] = reactionHandlerShowcase
channelsReaction[guild.weekly] = reactionHandlerWeekly

local guild = guildIdeas

channelsMessage[guild.showcase] = messageHandlerShowcase
channelsMessage[guild.weekly] = messageHandlerWeekly
channelsMessage[guild.bots] = messageHandlerBots
channelsReaction[guild.showcase] = reactionHandlerShowcase
channelsReaction[guild.weekly] = reactionHandlerWeekly

--------------------------------------------------

function onReady()
	print("Logged in as ".. client.user.username)
end

function onMessageCreate(message)
	if message.author.bot then return end
	env.message = message
	try(channelsMessage[message.channel.id], message)
end

function onReactionAdd(reaction, userId)
	local message = reaction.message
	if message.author.bot then return end
	env.reaction = reaction
	try(channelsReaction[message.channel.id], reaction, userId, message)
end

--------------------------------------------------
-- Repl commands

function cls() print("\x1b[H\x1b[2J") end

function uptime()
	local dt = os.clock() - startTime
	print(string.format("%.1f hours", dt / (60*60)))
end

--------------------------------------------------

print("Loaded")
