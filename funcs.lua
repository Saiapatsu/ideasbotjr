function onReady()
	print("Logged in as ".. client.user.username)
end

function onMessageCreate(message)
	if message.content == "!ping" then
		message:addReaction("\xF0\x9F\x90\xB4")
	end
end

function cls()
	print("\x1b[H\x1b[2J")
end
