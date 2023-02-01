discordia = require "discordia"
fs = require "fs"
client = discordia.Client()

local env = getfenv()

function reload() setfenv(loadfile("funcs.lua"), env)() end
reload()

client:on("ready", function() return onReady() end)
client:on("messageCreate", function(message) return onMessageCreate(message) end)

client:run(fs.readFileSync("./TOKEN"))

-- note: repl.lua has been modified to support passing an environment
-- repl will require a bunch of stuff and put them in there by default
local repl = require "repl" (process.stdin.handle, process.stdout.handle, "REPL active", env).start()
