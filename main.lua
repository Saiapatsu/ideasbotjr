-- hot reload
local env = getfenv()
function reload() setfenv(assert(loadfile("./funcs.lua")), env)() end
r = reload -- shortcut
reload()

-- discordia one-time setup
discordia = require "discordia"

client = discordia.Client({logFile = ""})
client:on("ready", function()
	TOKEN = nil
	TIMEOUT = nil
	return onReady()
end)
client:on("messageCreate", function(message) return onMessageCreate(message) end)
client:on("reactionAdd", function(reaction, userId) return onReactionAdd(reaction, userId) end)
-- client:on("reactionAddUncached", function(channel, messageId, hash, userId) return onReactionAddUncached(channel, messageId, hash, userId) end)

client:on("error", function(e)
	if e:sub(-9) == "EAI_AGAIN" then
		if client._token then return end
		if not TIMEOUT then return end
		if TIMEOUT <= 64000 then
			print("Retrying run() in " .. TIMEOUT .. "ms")
			timer.setTimeout(TIMEOUT, run)
			TIMEOUT = TIMEOUT * 2
		else
			print("Will no longer retry run()")
			TIMEOUT = nil
		end
	end
end)

local e = discordia.enums.gatewayIntent
client:disableAllIntents()
client:enableIntents(e.guilds, e.guildMessages, e.messageContent, e.guildMessageReactions)

function getToken()
	return require("fs").readFileSync("./TOKEN"):match("[^\n]+")
end
function run()
	if not TOKEN then
		TOKEN = getToken()
	end
	client:run(TOKEN)
end
function stop()
	TIMEOUT = nil
	client:stop()
end

startTime = os.time()

TIMEOUT = 1000
run()

-- repl
-- note: repl.lua has been modified to support passing an environment
-- repl will require a bunch of stuff and put them in there by default
require("repl")(process.stdin.handle, process.stdout.handle, "REPL active", env).start()
