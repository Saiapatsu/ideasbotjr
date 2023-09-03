-- hot reload
local env = getfenv()
function reload() setfenv(assert(loadfile("./funcs.lua")), env)() end
r = reload -- shortcut
reload()

-- discordia one-time setup
discordia = require "discordia"
client = discordia.Client({logFile = "NUL"})
client:on("ready", function() return onReady() end)
client:on("messageCreate", function(message) return onMessageCreate(message) end)
client:on("reactionAdd", function(reaction, userId) return onReactionAdd(reaction, userId) end)
-- client:on("reactionAddUncached", function(channel, messageId, hash, userId) return onReactionAddUncached(channel, messageId, hash, userId) end)
local e = discordia.enums.gatewayIntent
client:disableAllIntents()
client:enableIntents(e.guilds, e.guildMessages, e.messageContent, e.guildMessageReactions)
function run() client:run(require("fs").readFileSync("./TOKEN"):match("[^\n]+")) end
function stop() client:stop() end
run()

startTime = os.clock()

-- repl
-- note: repl.lua has been modified to support passing an environment
-- repl will require a bunch of stuff and put them in there by default
require("repl")(process.stdin.handle, process.stdout.handle, "REPL active", env).start()
