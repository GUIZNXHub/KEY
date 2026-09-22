local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local playerGui = LP:WaitForChild("PlayerGui")

-- ============================================================
-- KEY SYSTEM
-- API pública: valida Key + Roblox UserId + Username
-- O UserId é usado como identificador principal.
-- ============================================================
local KEY_FILE = "snoo_guiznx_key.txt"

-- COLOQUE A URL REAL DA SUA API AQUI.
-- Exemplo: https://seu-dominio.com/api/public/validate
local KEY_API  = "https://snoo-guiznxkeys2.lovable.app/api/public/validate"

local DISCORD_INVITE = "https://discord.gg/35DH7E3hc"

-- Faz POST JSON para a API usando o request disponível no ambiente.
local function keyHttpPost(url, payload)
    local body = HttpService:JSONEncode(payload)

    local req = (syn and syn.request) or (http and http.request) or http_request or request

    if typeof(req) == "function" then
        local ok, res = pcall(req, {
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
            },
            Body = body,
        })

        if ok and type(res) == "table" then
            local status = tonumber(res.StatusCode or res.status_code or 200) or 200
            local responseBody = res.Body or res.body
            if type(responseBody) == "string" and responseBody ~= "" then
                return responseBody, status
            end
        end
    end

    -- Fallback para ambientes em que HttpService está habilitado.
    local ok, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
            },
            Body = body,
        })
    end)

    if ok and type(result) == "table" then
        return result.Body, tonumber(result.StatusCode) or 200
    end

    return nil, nil
end

local function validateKey(key)
    if type(key) ~= "string" then
        return false, nil
    end

    key = key:match("^%s*(.-)%s*$") or ""
    if key == "" then
        return false, nil
    end

    -- Envia a Key, UserId e Username para o backend.
    local payload = {
        key = key,
        userId = tostring(LP.UserId),
        username = tostring(LP.Name),
    }

    local body, status = keyHttpPost(KEY_API, payload)

    if not body or body == "" then
        return false, {
            valid = false,
            reason = "API_OFFLINE",
        }
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not ok or type(data) ~= "table" then
        return false, {
            valid = false,
            reason = "INVALID_API_RESPONSE",
            status = status,
        }
    end

    if data.valid == true then
        return true, data
    end

    return false, data
end

local function loadSavedKey()
    if not (readfile and isfile and isfile(KEY_FILE)) then return nil end
    local ok, content = pcall(readfile, KEY_FILE)
    if not ok or type(content) ~= "string" then return nil end
    content = content:match("^%s*(.-)%s*$") or ""
    if content == "" then return nil end
    return content
end

local function saveKey(key)
    if not writefile then return end
    pcall(writefile, KEY_FILE, tostring(key or ""))
end

local function clearSavedKey()
    if isfile and isfile(KEY_FILE) and delfile then
        pcall(delfile, KEY_FILE)
    elseif writefile then
        pcall(writefile, KEY_FILE, "")
    end
end

-- Forward: defined after the whole main script body
local initMainScript

local function showKeySystemUI()
    -- Same UI library as the main script
    local Skibidi = loadstring((game:HttpGet(
        "https://raw.githubusercontent.com/blookzz/skibidi/refs/heads/main/UILib%20(2).lua"
    )):gsub("https://discord.gg/vonhub", DISCORD_INVITE))()

    local gold = Color3.fromRGB(220, 160, 60)
    Skibidi.Init({
        Theme = {
            Accent    = gold,
            AccentDim = Color3.new(gold.R * 0.45, gold.G * 0.45, gold.B * 0.45),
            AccentSec = Color3.new(math.min(gold.R * 1.18, 1), math.min(gold.G * 1.18, 1), math.min(gold.B * 1.18, 1)),
            Bg0 = Color3.fromRGB(10, 10, 10),
            Bg1 = Color3.fromRGB(17, 17, 17),
            Bg2 = Color3.fromRGB(25, 25, 25),
        },
        Parent = playerGui,
    })

    local panel = Skibidi.CreatePanel({
        Name = "SnooKeySystem",
        Title = "Snoo × Guiznx",
        SubTitle = "Key System",
        Width = 360,
        Height = 220,
        Variant = "gold",
        Tabs = {
            { Name = "Unlock", Icon = "key" },
        },
        DefaultTab = 1,
        ClampToScreen = true,
        Search = false,
        Discord = true,
        ConfirmClose = false,
    })

    local tab = panel.GetTab(1)
    local section = Skibidi.CreateSection(tab, {
        Title = "Premium Access",
        Open = true,
        Icon = "shield",
    })
    local content = section.Content

    local statusLabel = Skibidi.CreateLabel(content, {
        Text = "Enter your key to unlock the script.",
        Height = 28,
    })

    local keyInput = Skibidi.CreateTextInput(content, {
        Label = "License Key",
        Placeholder = "Paste key...",
        Default = "",
        Icon = "key",
        Width = 190,
    })

    local busy = false

    local function setStatus(text, kind)
        if statusLabel and statusLabel.SetText then
            pcall(statusLabel.SetText, text)
        end
        if kind == "ok" then
            pcall(Skibidi.ShowNotification, "Premium unlocked", text, 3, "success")
        elseif kind == "err" then
            pcall(Skibidi.ShowNotification, "Key rejected", text, 3, "error")
        end
    end

    local function destroyUI()
        pcall(function()
            if panel.Close then panel.Close() end
        end)
        pcall(function()
            if panel.Gui then panel.Gui:Destroy() end
        end)
    end

    local function onUnlocked(key)
        saveKey(key)
        setStatus("Premium unlocked — loading script...", "ok")
        task.delay(0.75, function()
            destroyUI()
            if initMainScript then
                pcall(initMainScript)
            end
        end)
    end

    Skibidi.CreateButton(content, {
        Text = "Unlock",
        Icon = "lock-open",
        OnClick = function()
            if busy then return end
            local key = ""
            if keyInput then
                if keyInput.GetValue then
                    local ok, v = pcall(keyInput.GetValue)
                    if ok then key = tostring(v or "") end
                elseif keyInput.TextBox then
                    key = tostring(keyInput.TextBox.Text or "")
                end
            end
            key = key:match("^%s*(.-)%s*$") or ""
            if key == "" then
                setStatus("Please paste a key first.", "err")
                return
            end
            busy = true
            setStatus("Validating key...", "info")
            task.spawn(function()
                local ok, data = validateKey(key)
                busy = false
                if ok then
                    onUnlocked(key)
                else
                    local reason = (data and data.reason) and tostring(data.reason) or "INVALID_KEY"
                    local messages = {
                        INVALID_KEY = "Key inválida.",
                        EXPIRED = "Key expirada.",
                        BLACKLISTED = "Usuário blacklistado.",
                        BANNED = "Usuário banido.",
                        KEY_ALREADY_LINKED = "Esta Key pertence a outro usuário.",
                        REVOKED = "Key revogada.",
                        API_OFFLINE = "Não foi possível conectar à API.",
                        INVALID_API_RESPONSE = "A API retornou uma resposta inválida.",
                    }
                    setStatus(messages[reason] or ("Key rejeitada: " .. reason), "err")
                end
            end)
        end,
    })

    Skibidi.CreateButton(content, {
        Text = "Copy Discord",
        Icon = "message-circle",
        OnClick = function()
            if setclipboard then
                pcall(setclipboard, DISCORD_INVITE)
            elseif toclipboard then
                pcall(toclipboard, DISCORD_INVITE)
            end
            setStatus("Discord invite copied.", "info")
            pcall(Skibidi.ShowNotification, "Discord", "Invite copied to clipboard", 2.5, "info")
        end,
    })

    Skibidi.CreateLabel(content, {
        Text = "No valid key → script will not load.",
        Height = 22,
    })
end

local function startWithKeyGate()
    local saved = loadSavedKey()
    if saved then
        local ok = validateKey(saved)
        if ok then
            -- already unlocked — run main immediately
            if initMainScript then initMainScript() end
            return
        end
        -- saved key no longer valid
        clearSavedKey()
    end
    -- no valid key → show lock UI and DO NOT run main
    showKeySystemUI()
end

-- ============================================================
-- MAIN SCRIPT (only runs after a valid key)
-- ============================================================
initMainScript = function()
-- ============================================================
-- RUNTIME
-- ============================================================
local environment = (getgenv and getgenv()) or _G
local RUNTIME_KEY = "__SNOO_GUIZNX_RUNTIME"
local previous = environment[RUNTIME_KEY]
if type(previous) == "table" and type(previous.destroy) == "function" then
    pcall(previous.destroy)
end

local runtime = {
    alive = true,
    enabled = false,
    snipeKey = Enum.KeyCode.Z,
    listeningKey = false,
    connections = {},
    spamCount = 20,
    submitAfter = 1,
    autoSubmit = false,
    spamRedeem = true,
    antiRagdoll = false,
    autoBuy = false,
    antiLag = false,
    removeAccessories = false,
    gui = nil,
    settingsGui = nil,
    eliteGui = nil,
    lastCode = nil,
    spamLoopActive = false,
    notifConn = nil,
    notifyRemote = nil,
    seen = {},
    capturedParts = {},
    uiMode = "normal", -- "normal" | "elite"
    -- Also Redeem At: set of capture counts (1-9) that trigger intermediate submit
    -- e.g. { [1]=true, [2]=true, [3]=true } → redeem after 1st, 2nd and 3rd part
    alsoRedeemAt = {},
}
environment[RUNTIME_KEY] = runtime

-- ============================================================
-- HELPERS
-- ============================================================
local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(runtime.connections, c)
    return c
end

local function new(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius),
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

-- ============================================================
-- BACKGROUND PADRÃO
-- ============================================================
local BG_IMAGE = "rbxassetid://70418952815837"
local BG_BASE_COLOR = Color3.fromRGB(15, 10, 25)

local function applyBackground(parent, cornerRadius)
    local bgFrame = new("Frame", {
        Name = parent.Name .. "Background",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = BG_BASE_COLOR,
        BorderSizePixel = 0,
        ZIndex = 0,
    }, parent)
    corner(bgFrame, cornerRadius)

    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(25, 10, 40)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(15, 8, 25)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(30, 12, 45)),
        }),
        Rotation = 45,
    }, bgFrame)

    local bgImage = new("ImageLabel", {
        Name = parent.Name .. "BackgroundImage",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image = BG_IMAGE,
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 1,
    }, bgFrame)
    corner(bgImage, cornerRadius)

    return bgFrame, bgImage
end

-- ============================================================
-- GUI DETECTION
-- ============================================================
local function isOurGui(instance)
    local p = instance
    for _ = 1, 10 do
        if not p then break end
        if p.Name == "SnooGuiznxUI" or p.Name == "SnooGuiznxSettingsUI"
            or p.Name == "SnooEliteUI" or p.Name == "SnooLoadingUI" then
            return true
        end
        p = p.Parent
    end
    return false
end

local function isVisibleChain(inst)
    local current = inst
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") then return current.Enabled end
        current = current.Parent
    end
    return true
end

local function findAllTextBoxes(pg)
    local boxes = {}
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextBox") and not isOurGui(d) then
                    boxes[#boxes+1] = d
                end
            end
        end
    end
    return boxes
end

local function findCodeBox()
    local pg = playerGui
    if not pg then return nil end
    local allBoxes = findAllTextBoxes(pg)
    for _, box in ipairs(allBoxes) do
        if isVisibleChain(box) then
            local n  = box.Name:lower()
            local pn = (box.Parent and box.Parent.Name or ""):lower()
            if n:find("code") or pn:find("code") or n:find("redeem") or pn:find("redeem") or n:find("input") or n:find("enter") then
                return box
            end
        end
    end
    for _, box in ipairs(allBoxes) do
        if isVisibleChain(box) then return box end
    end
    return nil
end

local function findSubmitButton(box)
    local pg = playerGui
    if not pg then return nil end

    local searchNames = {"submit","redeem","claim","confirm","enter","send","apply","ok","use","go","check"}

    if box then
        local p = box.Parent
        for _ = 1, 6 do
            if not p then break end
            for _, d in ipairs(p:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) and d ~= box then
                    local n = d.Name:lower()
                    local txt = ""
                    pcall(function() txt = d.Text:lower() end)
                    for _, sn in ipairs(searchNames) do
                        if (n:find(sn) or txt:find(sn)) and isVisibleChain(d) then
                            return d
                        end
                    end
                end
            end
            p = p.Parent
        end
    end

    local btns = {}
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, d in ipairs(gui:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) then
                    local n = d.Name:lower()
                    local txt = ""
                    pcall(function() txt = d.Text:lower() end)
                    for _, sn in ipairs(searchNames) do
                        if (n:find(sn) or txt:find(sn)) and isVisibleChain(d) then
                            table.insert(btns, d)
                            break
                        end
                    end
                end
            end
        end
    end
    return btns[1]
end

local getupvalues = (debug and debug.getupvalues) or getupvalues
local getconns    = getconnections or (debug and debug.getconnections)
local setupv      = (debug and debug.setupvalue) or setupvalue

local function clickButton(btn)
    if not btn then return false end
    local anyOk = false
    local methods = {
        function() btn.MouseButton1Click:Fire() end,
        function() btn.Activated:Fire() end,
    }
    if typeof(firesignal) == "function" then
        table.insert(methods, function() firesignal(btn.MouseButton1Click) end)
        table.insert(methods, function() firesignal(btn.Activated) end)
    end
    if typeof(getconns) == "function" then
        table.insert(methods, function()
            local ok, cs = pcall(getconns, btn.MouseButton1Click)
            if ok and type(cs) == "table" then
                for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
            end
            local ok2, cs2 = pcall(getconns, btn.Activated)
            if ok2 and type(cs2) == "table" then
                for _, c in ipairs(cs2) do pcall(function() c:Fire() end) end
            end
        end)
    end
    if typeof(fireclick) == "function" then
        table.insert(methods, function() fireclick(btn) end)
    end
    for _, fn in ipairs(methods) do
        local ok = pcall(fn)
        anyOk = anyOk or ok
    end
    return anyOk
end

local function fireBoxFocusLost(box)
    if not box then return false end
    local anyFired = false
    if typeof(firesignal) == "function" then
        anyFired = anyFired or pcall(firesignal, box.FocusLost, true)
    end
    if typeof(getconns) == "function" then
        local ok, cs = pcall(getconns, box.FocusLost)
        if ok and type(cs) == "table" then
            for _, c in ipairs(cs) do
                local fn
                pcall(function() fn = c.Function end)
                if fn and typeof(getupvalues) == "function" and typeof(setupv) == "function" then
                    local uOk, ups = pcall(getupvalues, fn)
                    if uOk and type(ups) == "table" then
                        for i, v in pairs(ups) do
                            if type(v) == "boolean" and v == true then
                                pcall(setupv, fn, i, false)
                            end
                        end
                    end
                end
                local fOk = pcall(function()
                    if c.Enabled ~= false then c:Fire(true) end
                end)
                anyFired = anyFired or fOk
            end
        end
    end
    return anyFired
end

-- ============================================================
-- REDEEM
-- ============================================================
local function redeemCode(code)
    if not code or code == "" then return false, "no code" end

    local box = findCodeBox()
    if not box then return false, "no code box" end

    pcall(function() box.Text = code end)

    local submitBtn = findSubmitButton(box)
    if not submitBtn then
        fireBoxFocusLost(box)
        return false, "no submit button"
    end

    if runtime.spamRedeem then
        local n = math.clamp(runtime.spamCount, 1, 100)
        for i = 1, n do
            if not runtime.alive then break end
            clickButton(submitBtn)
            task.wait(0.0001)
        end
    else
        clickButton(submitBtn)
    end

    fireBoxFocusLost(box)
    return true, "submitted"
end

local function startSpamRedeem(code)
    if runtime.spamLoopActive then return end
    runtime.spamLoopActive = true

    local count = math.clamp(runtime.spamCount, 1, 100)
    local success = 0

    consoleLog(string.format(
        "<font color='rgb(105,190,132)'>Spamming %d vezes...</font>",
        count
    ))

    task.spawn(function()
        for i = 1, count do
            if not runtime.alive or not runtime.spamLoopActive then break end
            local ok = redeemCode(code)
            if ok then success = success + 1 end
            if i % 5 == 0 or i == count then
                consoleLog(string.format(
                    "<font color='rgb(105,190,132)'>Spam %d/%d</font> <font color='rgb(150,150,150)'>(%d ok)</font>",
                    i, count, success
                ))
            end
            task.wait(0.0001)
        end
        consoleLog(string.format(
            "<font color='rgb(105,190,132)'>Spam finalizado: %d/%d</font>",
            success, count
        ))
        runtime.spamLoopActive = false
    end)
end

-- ============================================================
-- NOTIFICATION LISTENER (Submit After funcional)
-- ============================================================
local function resolveNotifyRemote()
    if runtime.notifyRemote and runtime.notifyRemote.Parent then
        return runtime.notifyRemote
    end
    local candidates = {}
    pcall(function()
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                local n = d.Name:lower()
                if n:find("notif") or n:find("announce") or n:find("broadcast")
                or n:find("global") or n:find("message") or n:find("chat") then
                    table.insert(candidates, d)
                end
            end
        end
    end)
    if #candidates > 0 then
        runtime.notifyRemote = candidates[1]
        return candidates[1]
    end
    return nil
end

local function stripRich(text)
    if type(text) ~= "string" then return tostring(text) end
    return (text:gsub("<[^>]->", ""))
end

local function tokenize(text)
    local words = {}
    for word in text:gmatch("[%w_]+") do
        words[#words + 1] = word
    end
    return words
end

local function alsoRedeemActive()
    if type(runtime.alsoRedeemAt) ~= "table" then return false end
    for _, on in pairs(runtime.alsoRedeemAt) do
        if on then return true end
    end
    return false
end

local function maxAlsoRedeem()
    local m = 0
    if type(runtime.alsoRedeemAt) ~= "table" then return m end
    for n, on in pairs(runtime.alsoRedeemAt) do
        if on then
            local num = tonumber(n) or 0
            if num > m then m = num end
        end
    end
    return m
end

-- force=true → always redeem (Also Redeem At). force=false → only if Auto Submit is on.
local function doAutoRedeem(joined, reason, force)
    if not joined or joined == "" then return end
    runtime.lastCode = joined
    consoleLog(string.format(
        "<font color='rgb(105,190,132)'>Submitting (%s): %s</font>",
        tostring(reason or "auto"),
        joined
    ))
    if not force and not runtime.autoSubmit then return end
    task.spawn(function()
        local ok, err = redeemCode(joined)
        if ok then
            consoleLog("<font color='rgb(105,190,132)'>Redeemed: " .. joined .. "</font>")
        else
            consoleLog("<font color='rgb(150,150,150)'>Failed: " .. tostring(err) .. "</font>")
        end
    end)
end

local function pickAnnouncementText(...)
    local args = { ... }
    for i = 1, #args do
        local a = args[i]
        if type(a) == "string" and a ~= "" then
            return a
        elseif type(a) == "table" then
            for _, v in pairs(a) do
                if type(v) == "string" and v ~= "" then
                    return v
                end
            end
        end
    end
    if #args > 0 then
        return tostring(args[1])
    end
    return ""
end

local function onAnnouncement(...)
    if not runtime.enabled then return end

    local text = stripRich(pickAnnouncementText(...))
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" then return end
    -- code parts are single tokens (no spaces) — ignore full sentences
    if text:find("%s") then return end

    if runtime.seen[text] then return end
    runtime.seen[text] = true
    task.delay(1.25, function() runtime.seen[text] = nil end)

    -- each announcement = one code part (keep as-is)
    table.insert(runtime.capturedParts, text)

    local capturedCount = #runtime.capturedParts
    local joined = table.concat(runtime.capturedParts) -- FREE + GARAMA + 6767 → FREEGARAMA6767

    local usingAlso = alsoRedeemActive()
    local target = usingAlso and math.max(maxAlsoRedeem(), 1) or runtime.submitAfter

    consoleLog(string.format(
        "<font color='rgb(105,190,132)'>Captured %d/%d</font> <font color='rgb(150,150,150)'>[%s]</font>",
        capturedCount,
        target,
        joined
    ))

    if usingAlso then
        -- Also Redeem At drives submit (does NOT need Auto Submit)
        -- Example selected 1,2,3:
        --   1st "FREE"          → redeem FREE
        --   2nd "GARAMA"        → redeem FREEGARAMA
        --   3rd "6767"          → redeem FREEGARAMA6767
        local hit = runtime.alsoRedeemAt[capturedCount] == true
        if hit then
            doAutoRedeem(joined, "AlsoRedeem@" .. tostring(capturedCount), true)
        end
        -- clear only after the highest selected number
        if capturedCount >= maxAlsoRedeem() then
            runtime.capturedParts = {}
        end
    else
        -- Classic mode: Submit After + Auto Submit toggle
        if capturedCount >= runtime.submitAfter then
            doAutoRedeem(joined, "submitAfter", false)
            runtime.capturedParts = {}
        end
    end
end

local function startNotifListener()
    if runtime.notifConn then return end
    local remote = resolveNotifyRemote()
    if remote then
        runtime.notifConn = remote.OnClientEvent:Connect(function(...)
            pcall(onAnnouncement, ...)
        end)
    end
end

local function stopNotifListener()
    if runtime.notifConn then
        disconnect(runtime.notifConn)
        runtime.notifConn = nil
    end
end

-- ============================================================

-- ============================================================
local snipeConn = nil
local function startSnipe()
    if snipeConn then return end
    startNotifListener()
    snipeConn = RunService.Heartbeat:Connect(function()
        if not runtime.alive or not runtime.enabled then return end
    end)
end

local function stopSnipe()
    disconnect(snipeConn)
    snipeConn = nil
    stopNotifListener()
end

local antiRagdollConn = nil
local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not runtime.antiRagdoll then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                if hum:GetState() == Enum.HumanoidStateType.Physics
                or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end)
end

local autoBuyConn = nil
local function startAutoBuy()
    if autoBuyConn then return end
    autoBuyConn = RunService.Heartbeat:Connect(function()
        if not runtime.autoBuy then return end
    end)
end

local antiLagOriginal = nil
local function startAntiLag()
    if antiLagOriginal then return end
    pcall(function()
        antiLagOriginal = {
            QualityLevel = settings().Rendering.QualityLevel,
            GlobalShadows = Lighting.GlobalShadows,
        }
    end)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
    end)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            pcall(function()
                d.Material = Enum.Material.Plastic
                d.Reflectance = 0
                d.CastShadow = false
            end)
        end
    end
end

local function stopAntiLag()
    if not antiLagOriginal then return end
    pcall(function()
        settings().Rendering.QualityLevel = antiLagOriginal.QualityLevel
        Lighting.GlobalShadows = antiLagOriginal.GlobalShadows
    end)
    antiLagOriginal = nil
end

local function removeAccessoriesNow()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("Accessory") or d:IsA("Hat") then
                    pcall(function() d:Destroy() end)
                end
            end
        end
    end
end

-- ============================================================
-- LOADING SCREEN (full black + progress bar 2.8s)
-- ============================================================
local switchUIMode -- forward declaration (used by Elite UI button)

local function showLoadingScreen(onComplete)
    local loadGui = Instance.new("ScreenGui")
    loadGui.Name = "SnooLoadingUI"
    loadGui.IgnoreGuiInset = true
    loadGui.ResetOnSpawn = false
    loadGui.DisplayOrder = 9999
    loadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loadGui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = loadGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0.5, 0, 0.42, 0)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 28
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.Text = "LOADING YOUR SCRIPT"
    title.Parent = bg

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 22)
    sub.Position = UDim2.new(0.5, 0, 0.48, 0)
    sub.AnchorPoint = Vector2.new(0.5, 0.5)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.TextColor3 = Color3.fromRGB(120, 120, 140)
    sub.Text = "Snoo × Guiznx"
    sub.Parent = bg

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 280, 0, 8)
    barBg.Position = UDim2.new(0.5, 0, 0.55, 0)
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    corner(barBg, 4)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    corner(barFill, 4)

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.new(0, 60, 0, 18)
    pct.Position = UDim2.new(0.5, 0, 0.59, 0)
    pct.AnchorPoint = Vector2.new(0.5, 0.5)
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.GothamBold
    pct.TextSize = 12
    pct.TextColor3 = Color3.fromRGB(150, 150, 170)
    pct.Text = "0%"
    pct.Parent = bg

    local duration = 2.8
    local start = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not runtime.alive then
            disconnect(conn)
            pcall(function() loadGui:Destroy() end)
            return
        end
        local t = math.clamp((os.clock() - start) / duration, 0, 1)
        barFill.Size = UDim2.new(t, 0, 1, 0)
        pct.Text = math.floor(t * 100) .. "%"
        if t >= 1 then
            disconnect(conn)
            -- fade out animation
            local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(bg, fadeInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(title, fadeInfo, { TextTransparency = 1 }):Play()
            TweenService:Create(sub, fadeInfo, { TextTransparency = 1 }):Play()
            TweenService:Create(barBg, fadeInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(barFill, fadeInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(pct, fadeInfo, { TextTransparency = 1 }):Play()
            task.delay(0.5, function()
                pcall(function() loadGui:Destroy() end)
                if onComplete then onComplete() end
            end)
        end
    end)
end

-- ============================================================
-- ELITE-STYLE UI (modeled after eliteautocode.txt)
-- ============================================================
local function destroyEliteUI()
    if runtime.eliteGui then
        pcall(function() runtime.eliteGui:Destroy() end)
        runtime.eliteGui = nil
    end
end

local function createEliteUI()
    destroyEliteUI()

    local C = {
        bg0 = Color3.fromRGB(8, 8, 12),
        bg1 = Color3.fromRGB(13, 13, 18),
        bg2 = Color3.fromRGB(20, 20, 28),
        bg3 = Color3.fromRGB(16, 16, 22),
        accent = Color3.fromRGB(52, 152, 219),
        accentDim = Color3.fromRGB(30, 70, 120),
        accentSec = Color3.fromRGB(92, 184, 240),
        activeTabText = Color3.fromRGB(255, 255, 255),
        toggleOff = Color3.fromRGB(30, 30, 40),
        toggleOn = Color3.fromRGB(41, 128, 185),
        knob = Color3.fromRGB(133, 193, 233),
        textPri = Color3.fromRGB(220, 220, 230),
        textMuted = Color3.fromRGB(100, 100, 120),
        inputBg = Color3.fromRGB(10, 10, 16),
        tweenFast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        tweenMed = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        toggleW = 40,
        toggleH = 20,
        knobSz = 16,
    }

    local TITLE_H = 36
    local TABBAR_H = 37
    local ROW_H = 34
    local PAGE_PAD = 10
    local FULL_H_MAIN = TITLE_H + TABBAR_H + (ROW_H * 6 + 6 * 5) + PAGE_PAD * 2
    local FULL_H_STATUS = TITLE_H + TABBAR_H + 220

    local eliteGui = Instance.new("ScreenGui")
    eliteGui.Name = "SnooEliteUI"
    eliteGui.ResetOnSpawn = false
    eliteGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    eliteGui.Parent = playerGui
    runtime.eliteGui = eliteGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, FULL_H_MAIN)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -FULL_H_MAIN / 2)
    mainFrame.BackgroundColor3 = C.bg1
    mainFrame.BackgroundTransparency = 0.04
    mainFrame.Active = true
    mainFrame.Parent = eliteGui
    corner(mainFrame, 10)
    stroke(mainFrame, C.accent, 0, 1.2)

    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
    titleBar.BackgroundColor3 = C.bg0
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = mainFrame
    corner(titleBar, 10)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -52, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = C.accentSec
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "SNOO × GUIZNX"
    titleLabel.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 20)
    minBtn.AnchorPoint = Vector2.new(1, 0.5)
    minBtn.Position = UDim2.new(1, -8, 0.5, 0)
    minBtn.BackgroundColor3 = C.accentDim
    minBtn.BorderSizePixel = 0
    minBtn.Font = Enum.Font.GothamBlack
    minBtn.TextSize = 14
    minBtn.TextColor3 = C.accentSec
    minBtn.Text = "–"
    minBtn.Parent = titleBar
    corner(minBtn, 5)

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Position = UDim2.new(0, 0, 0, TITLE_H)
    tabBar.Size = UDim2.new(1, 0, 0, TABBAR_H)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 10)
    tabPad.PaddingRight = UDim.new(0, 10)
    tabPad.PaddingTop = UDim.new(0, 11)
    tabPad.PaddingBottom = UDim.new(0, 2)
    tabPad.Parent = tabBar

    local function makeTab(text, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.33, -4, 1, 0)
        btn.LayoutOrder = order
        btn.BackgroundColor3 = C.bg2
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = C.textMuted
        btn.Text = text
        btn.Parent = tabBar
        corner(btn, 6)
        stroke(btn, C.accentDim, 0, 1)
        return btn
    end

    local tabMain = makeTab("Main", 1)
    local tabAA = makeTab("Helpers", 2)
    local tabStatus = makeTab("Status", 3)

    local content = Instance.new("Frame")
    content.Position = UDim2.new(0, 0, 0, TITLE_H + TABBAR_H)
    content.Size = UDim2.new(1, 0, 1, -(TITLE_H + TABBAR_H))
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local pageMain = Instance.new("Frame")
    pageMain.Size = UDim2.new(1, 0, 1, 0)
    pageMain.BackgroundTransparency = 1
    pageMain.Parent = content
    local mainList = Instance.new("UIListLayout")
    mainList.Padding = UDim.new(0, 6)
    mainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainList.Parent = pageMain
    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0, 10)
    mainPad.PaddingBottom = UDim.new(0, 10)
    mainPad.PaddingLeft = UDim.new(0, 10)
    mainPad.PaddingRight = UDim.new(0, 10)
    mainPad.Parent = pageMain

    local pageAA = Instance.new("Frame")
    pageAA.Size = UDim2.new(1, 0, 1, 0)
    pageAA.BackgroundTransparency = 1
    pageAA.Visible = false
    pageAA.Parent = content
    local aaList = Instance.new("UIListLayout")
    aaList.Padding = UDim.new(0, 6)
    aaList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    aaList.Parent = pageAA
    local aaPad = Instance.new("UIPadding")
    aaPad.PaddingTop = UDim.new(0, 10)
    aaPad.PaddingBottom = UDim.new(0, 10)
    aaPad.PaddingLeft = UDim.new(0, 10)
    aaPad.PaddingRight = UDim.new(0, 10)
    aaPad.Parent = pageAA

    local pageStatus = Instance.new("Frame")
    pageStatus.Size = UDim2.new(1, 0, 1, 0)
    pageStatus.BackgroundTransparency = 1
    pageStatus.Visible = false
    pageStatus.Parent = content
    local statusPad = Instance.new("UIPadding")
    statusPad.PaddingTop = UDim.new(0, 8)
    statusPad.PaddingBottom = UDim.new(0, 8)
    statusPad.PaddingLeft = UDim.new(0, 8)
    statusPad.PaddingRight = UDim.new(0, 8)
    statusPad.Parent = pageStatus

    local statusScroll = Instance.new("ScrollingFrame")
    statusScroll.Size = UDim2.new(1, 0, 1, -32)
    statusScroll.BackgroundColor3 = C.bg3
    statusScroll.BackgroundTransparency = 0.2
    statusScroll.BorderSizePixel = 0
    statusScroll.ScrollBarThickness = 3
    statusScroll.ScrollBarImageColor3 = C.accentDim
    statusScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    statusScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    statusScroll.ClipsDescendants = true
    statusScroll.Parent = pageStatus
    corner(statusScroll, 5)
    stroke(statusScroll, C.accentDim, 0, 1)
    local statusLayout = Instance.new("UIListLayout")
    statusLayout.Padding = UDim.new(0, 2)
    statusLayout.Parent = statusScroll
    local statusInnerPad = Instance.new("UIPadding")
    statusInnerPad.PaddingLeft = UDim.new(0, 4)
    statusInnerPad.PaddingRight = UDim.new(0, 4)
    statusInnerPad.PaddingTop = UDim.new(0, 4)
    statusInnerPad.PaddingBottom = UDim.new(0, 4)
    statusInnerPad.Parent = statusScroll

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(1, 0, 0, 26)
    clearBtn.Position = UDim2.new(0, 0, 1, -26)
    clearBtn.BackgroundColor3 = C.bg2
    clearBtn.Font = Enum.Font.Gotham
    clearBtn.TextSize = 11
    clearBtn.TextColor3 = C.textMuted
    clearBtn.Text = "Clear Log"
    clearBtn.Parent = pageStatus
    corner(clearBtn, 6)
    stroke(clearBtn, C.accentDim, 0, 1)

    local function eliteLog(msg)
        local clean = tostring(msg or ""):gsub("<[^>]->", "")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 10
        lbl.TextColor3 = C.textPri
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.Text = "[" .. (os.date and os.date("%H:%M:%S") or "??") .. "] " .. clean
        lbl.Parent = statusScroll
        task.defer(function()
            statusScroll.CanvasPosition = Vector2.new(0, math.huge)
        end)
    end

    -- Route logs to Elite status while in elite mode (safe multi-switch)
    if not runtime._origConsoleLog then
        runtime._origConsoleLog = consoleLog
    end
    function consoleLog(message)
        if runtime._origConsoleLog then
            pcall(runtime._origConsoleLog, message)
        end
        if runtime.uiMode == "elite" then
            eliteLog(message)
        end
    end

    clearBtn.MouseButton1Click:Connect(function()
        for _, c in ipairs(statusScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        eliteLog("Log cleared")
    end)

    -- Helper to create a row
    local function makeRow(parent, height)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, height or ROW_H)
        row.BackgroundColor3 = C.bg2
        row.Parent = parent
        corner(row, 7)
        stroke(row, C.accentDim, 0, 1)
        return row
    end

    local function makeToggle(parent, label, default, onChanged)
        local row = makeRow(parent)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = C.textPri
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = label
        lbl.Parent = row

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -10, 0.5, 0)
        track.Size = UDim2.new(0, C.toggleW, 0, C.toggleH)
        track.BackgroundColor3 = default and C.toggleOn or C.toggleOff
        track.Parent = row
        corner(track, 99)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, C.knobSz, 0, C.knobSz)
        knob.Position = default
            and UDim2.new(0, C.toggleW - C.knobSz - 2, 0.5, -C.knobSz / 2)
            or UDim2.new(0, 2, 0.5, -C.knobSz / 2)
        knob.BackgroundColor3 = C.knob
        knob.Parent = track
        corner(knob, 99)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = row

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(track, C.tweenFast, { BackgroundColor3 = state and C.toggleOn or C.toggleOff }):Play()
            TweenService:Create(knob, C.tweenFast, {
                Position = state
                    and UDim2.new(0, C.toggleW - C.knobSz - 2, 0.5, -C.knobSz / 2)
                    or UDim2.new(0, 2, 0.5, -C.knobSz / 2)
            }):Play()
            if onChanged then onChanged(state) end
        end)
        return row
    end

    local function makeButton(parent, text, onClick)
        local row = makeRow(parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextColor3 = C.textPri
        btn.Text = text
        btn.Parent = row
        btn.MouseButton1Click:Connect(function()
            if onClick then onClick() end
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(row, C.tweenFast, { BackgroundColor3 = Color3.fromRGB(28, 28, 38) }):Play()
            TweenService:Create(btn, C.tweenFast, { TextColor3 = C.accent }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(row, C.tweenFast, { BackgroundColor3 = C.bg2 }):Play()
            TweenService:Create(btn, C.tweenFast, { TextColor3 = C.textPri }):Play()
        end)
        return row
    end

    local function makeInput(parent, label, default, onSubmit)
        local row = makeRow(parent)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = C.textPri
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = label
        lbl.Parent = row

        local box = Instance.new("TextBox")
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -10, 0.5, 0)
        box.Size = UDim2.new(0, 50, 0, 22)
        box.BackgroundColor3 = C.inputBg
        box.BorderSizePixel = 0
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.TextColor3 = C.accentSec
        box.Text = tostring(default)
        box.ClearTextOnFocus = false
        box.Parent = row
        corner(box, 5)
        stroke(box, C.accentDim, 0, 1)

        box.FocusLost:Connect(function()
            if onSubmit then onSubmit(box.Text) end
        end)
        return box
    end

    -- MAIN PAGE CONTROLS
    makeToggle(pageMain, "Snipe", runtime.enabled, function(on)
        runtime.enabled = on
        if on then startSnipe() else stopSnipe() end
    end)
    makeToggle(pageMain, "Auto Enter Code", runtime.autoSubmit, function(on)
        runtime.autoSubmit = on
    end)
    makeInput(pageMain, "Submit After", runtime.submitAfter, function(v)
        runtime.submitAfter = math.clamp(tonumber(v) or 1, 1, 10)
        runtime.capturedParts = {}
    end)
    makeInput(pageMain, "Spam Redeem", runtime.spamCount, function(v)
        runtime.spamCount = math.clamp(math.floor(tonumber(v) or 20), 1, 100)
    end)
    makeButton(pageMain, "Force Scan + Code", function()
        consoleLog("Force Scan started – manual capture mode")
    end)
    makeButton(pageMain, "Redeem Last Code", function()
        local code = runtime.lastCode
        if (not code or code == "") and #runtime.capturedParts > 0 then
            code = table.concat(runtime.capturedParts)
        end
        if code and code ~= "" then
            runtime.lastCode = code
            startSpamRedeem(code)
        else
            consoleLog("No code to redeem")
        end
    end)
    makeButton(pageMain, "Copy Last Code", function()
        local code = runtime.lastCode
        if (not code or code == "") and #runtime.capturedParts > 0 then
            code = table.concat(runtime.capturedParts)
        end
        if code and code ~= "" then
            if setclipboard then pcall(setclipboard, code) elseif toclipboard then pcall(toclipboard, code) end
            consoleLog("Copied: " .. code)
        else
            consoleLog("No code to copy")
        end
    end)

    -- HELPERS PAGE
    makeToggle(pageAA, "Anti Ragdoll", runtime.antiRagdoll, function(on)
        runtime.antiRagdoll = on
        if on then startAntiRagdoll() else disconnect(antiRagdollConn); antiRagdollConn = nil end
    end)
    makeToggle(pageAA, "Auto Buy", runtime.autoBuy, function(on)
        runtime.autoBuy = on
        if on then startAutoBuy() else disconnect(autoBuyConn); autoBuyConn = nil end
    end)
    makeToggle(pageAA, "Anti Lag", runtime.antiLag, function(on)
        runtime.antiLag = on
        if on then startAntiLag() else stopAntiLag() end
    end)
    makeToggle(pageAA, "Remove Accessories", runtime.removeAccessories, function(on)
        runtime.removeAccessories = on
        if on then removeAccessoriesNow() end
    end)

    -- Mini system: return to Normal (Skibidi) UI
    makeButton(pageAA, "← Back to Normal UI", function()
        switchUIMode("normal")
    end)

    -- Tab switching
    local currentTab = 1
    local isMinimized = false
    local function setTab(idx)
        currentTab = idx
        pageMain.Visible = idx == 1
        pageAA.Visible = idx == 2
        pageStatus.Visible = idx == 3
        tabMain.BackgroundColor3 = idx == 1 and C.toggleOn or C.bg2
        tabAA.BackgroundColor3 = idx == 2 and C.toggleOn or C.bg2
        tabStatus.BackgroundColor3 = idx == 3 and C.toggleOn or C.bg2
        tabMain.TextColor3 = idx == 1 and C.activeTabText or C.textMuted
        tabAA.TextColor3 = idx == 2 and C.activeTabText or C.textMuted
        tabStatus.TextColor3 = idx == 3 and C.activeTabText or C.textMuted
        local h = isMinimized and TITLE_H or (idx == 3 and FULL_H_STATUS or FULL_H_MAIN)
        TweenService:Create(mainFrame, C.tweenMed, { Size = UDim2.new(0, 320, 0, h) }):Play()
    end
    setTab(1)

    tabMain.MouseButton1Click:Connect(function() setTab(1) end)
    tabAA.MouseButton1Click:Connect(function() setTab(2) end)
    tabStatus.MouseButton1Click:Connect(function() setTab(3) end)

    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "–"
        content.Visible = not isMinimized
        tabBar.Visible = not isMinimized
        local h = isMinimized and TITLE_H or (currentTab == 3 and FULL_H_STATUS or FULL_H_MAIN)
        TweenService:Create(mainFrame, C.tweenMed, { Size = UDim2.new(0, 320, 0, h) }):Play()
    end)

    -- Drag
    do
        local dragging, dragStart, startPos = false, nil, nil
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end)
    end

    eliteLog("Elite UI loaded – Snoo × Guiznx")
    consoleLog("UI switched to Elite style")
end

local function setNormalUIVisible(visible)
    local function apply(obj)
        if not obj then return end
        pcall(function()
            if obj:IsA("ScreenGui") then
                obj.Enabled = visible
            elseif obj:IsA("GuiObject") then
                obj.Visible = visible
                local sg = obj:FindFirstAncestorOfClass("ScreenGui")
                if sg then sg.Enabled = visible end
            end
        end)
    end
    apply(runtime.gui)
    -- also try by name in case the reference changed
    pcall(function()
        local sg = playerGui:FindFirstChild("SnooGuiznxUI")
            or CoreGui:FindFirstChild("SnooGuiznxUI")
        if sg then
            if sg:IsA("ScreenGui") then
                sg.Enabled = visible
            else
                sg.Visible = visible
            end
        end
    end)
end

switchUIMode = function(mode)
    if mode == runtime.uiMode then return end

    if mode == "elite" then
        -- Keep Normal UI alive, just hide it (mini system – no destroy)
        setNormalUIVisible(false)
        showLoadingScreen(function()
            if not runtime.alive then return end
            runtime.uiMode = "elite"
            createEliteUI()
        end)
    else
        -- Back to Normal: destroy Elite → loading → re-show Skibidi
        destroyEliteUI()
        showLoadingScreen(function()
            if not runtime.alive then return end
            runtime.uiMode = "normal"
            setNormalUIVisible(true)
            consoleLog("UI switched back to Normal (Skibidi)")
        end)
    end
end

-- ============================================================
-- ============================================================
-- SKIBIDI UI
-- ============================================================
local Skibidi = loadstring((game:HttpGet("https://raw.githubusercontent.com/blookzz/skibidi/refs/heads/main/UILib%20(2).lua")):gsub("https://discord.gg/vonhub", "https://discord.gg/35DH7E3hc"))()
local COLOR_CFG_PATH = "snoo_guiznx_colors.json"
local DEFAULT_ACCENT = Color3.fromRGB(220, 160, 60)
local function loadSavedAccent()
    if not (readfile and isfile and isfile(COLOR_CFG_PATH)) then return DEFAULT_ACCENT end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(COLOR_CFG_PATH)) end)
    if ok and type(data) == "table" and tonumber(data.r) and tonumber(data.g) and tonumber(data.b) then
        return Color3.fromRGB(
            math.clamp(tonumber(data.r), 0, 255),
            math.clamp(tonumber(data.g), 0, 255),
            math.clamp(tonumber(data.b), 0, 255)
        )
    end
    return DEFAULT_ACCENT
end
local savedAccent = loadSavedAccent()
local function saveAccent(color)
    if not writefile then return end
    pcall(writefile, COLOR_CFG_PATH, HttpService:JSONEncode({
        r = math.floor(color.R * 255 + 0.5),
        g = math.floor(color.G * 255 + 0.5),
        b = math.floor(color.B * 255 + 0.5),
    }))
end
Skibidi.Init({
    Theme = {
        Accent = savedAccent,
        AccentDim = Color3.new(savedAccent.R * 0.45, savedAccent.G * 0.45, savedAccent.B * 0.45),
        AccentSec = Color3.new(math.min(savedAccent.R * 1.18, 1), math.min(savedAccent.G * 1.18, 1), math.min(savedAccent.B * 1.18, 1)),
        Bg0 = Color3.fromRGB(10, 10, 10),
        Bg1 = Color3.fromRGB(17, 17, 17),
        Bg2 = Color3.fromRGB(25, 25, 25),
    },
    Parent = playerGui,
})

local panel = Skibidi.CreatePanel({
    Name = "SnooGuiznxUI",
    Title = "Snoo × Guiznx",
    SubTitle = "v3.3",
    Width = 460,
    Height = 330,
    Variant = "gold",
    TabSide = "left",
    TabWidth = 125,
    Tabs = {
        { Name = "Main", Icon = "home" },
        { Name = "Triggers", Icon = "zap" },
        { Name = "Admin Abuse", Icon = "shield" },
        { Name = "AI", Icon = "bot" },
        { Name = "UI", Icon = "palette" },
        { Name = "Notifications", Icon = "bell" },
        { Name = "Status", Icon = "activity" },
        { Name = "Credits", Icon = "users" },
    },
    DefaultTab = 1,
    ClampToScreen = true,
    ToggleKey = "Z",
    Search = false,
    Discord = true,
    ConfirmClose = false,
})
runtime.gui = panel.Gui

-- ============================================================
-- BACKGROUND-ONLY COLOR SYSTEM (does not touch accent/text/icons)
-- ============================================================
local activeBgBase = savedAccent

local function colorNear(a, b)
    return typeof(a) == "Color3" and typeof(b) == "Color3"
        and math.abs(a.R - b.R) < 0.018
        and math.abs(a.G - b.G) < 0.018
        and math.abs(a.B - b.B) < 0.018
end

-- Build a dark background palette from a base tint color
local function bgSetFrom(base)
    local function mix(t)
        -- t = 0 (darkest) .. 1 (lighter panel)
        local r = math.clamp(base.R * (0.06 + t * 0.22), 0, 1)
        local g = math.clamp(base.G * (0.06 + t * 0.22), 0, 1)
        local b = math.clamp(base.B * (0.06 + t * 0.22), 0, 1)
        -- ensure minimum darkness so UI stays readable
        local lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        if lum > 0.28 then
            local s = 0.28 / lum
            r, g, b = r * s, g * s, b * s
        end
        return Color3.new(r, g, b)
    end
    return {
        bg0 = mix(0.00), -- title / deepest
        bg1 = mix(0.35), -- main panel
        bg2 = mix(0.70), -- sections / rows
        bg3 = mix(0.50), -- inputs / scroll
    }
end

-- Must match Skibidi.Init Theme defaults so the first recolor hits real frames
local activeBgSet = {
    bg0 = Color3.fromRGB(10, 10, 10),
    bg1 = Color3.fromRGB(17, 17, 17),
    bg2 = Color3.fromRGB(25, 25, 25),
    bg3 = Color3.fromRGB(20, 20, 20),
}

local function recolorBackgroundOnly(root, oldSet, newSet)
    if not root then return end
    local function remapBg(c)
        if colorNear(c, oldSet.bg0) then return newSet.bg0 end
        if colorNear(c, oldSet.bg1) then return newSet.bg1 end
        if colorNear(c, oldSet.bg2) then return newSet.bg2 end
        if colorNear(c, oldSet.bg3) then return newSet.bg3 end
        return nil -- not a background color → leave unchanged
    end
    local function update(obj)
        pcall(function()
            if obj:IsA("GuiObject") then
                local nb = remapBg(obj.BackgroundColor3)
                if nb then
                    obj.BackgroundColor3 = nb
                end
            end
            -- intentionally do NOT touch TextColor3, ImageColor3, UIStroke, UIGradient
        end)
    end
    update(root)
    for _, obj in ipairs(root:GetDescendants()) do
        update(obj)
    end
end

local function applyBackgroundOnly(color)
    if typeof(color) ~= "Color3" then return end
    local oldSet = activeBgSet
    local newSet = bgSetFrom(color)

    -- Update Skibidi theme background slots only
    pcall(function()
        if Skibidi and Skibidi.Theme then
            Skibidi.Theme.Bg0 = newSet.bg0
            Skibidi.Theme.Bg1 = newSet.bg1
            Skibidi.Theme.Bg2 = newSet.bg2
        end
    end)

    if panel and panel.Gui then
        recolorBackgroundOnly(panel.Gui, oldSet, newSet)
    end

    activeBgBase = color
    activeBgSet = newSet
end

-- Keep old name as alias so any leftover calls don't break
local function applyAccentEverywhere(color)
    applyBackgroundOnly(color)
end

-- Apply saved background tint once the panel exists
task.defer(function()
    if savedAccent and not colorNear(savedAccent, Color3.fromRGB(220, 160, 60)) then
        -- only re-apply if user previously saved a custom colour
        applyBackgroundOnly(savedAccent)
    elseif savedAccent then
        -- still apply gold-tint bg so palette is consistent after first save
        applyBackgroundOnly(savedAccent)
    end
end)

local mainTab = panel.GetTab(1)
local triggersTab = panel.GetTab(2)
local aaTab = panel.GetTab(3)
local aiTab = panel.GetTab(4)
local colorsTab = panel.GetTab(5)
local notificationTab = panel.GetTab(6)
local statusTab = panel.GetTab(7)
local creditsTab = panel.GetTab(8)

local mainSection = Skibidi.CreateSection(mainTab, { Title = "Snoo × Guiznx", Open = true, Icon = "crosshair" })
local mainContent = mainSection.Content
local statusWidget

local triggerKeywords = { "code", "redeem", "free", "gift", "reward", "claim", "bonus", "new code", "secret", "daily" }
local function buildTriggerTab(parent, tabTitle)
    local section = Skibidi.CreateSection(parent, { Title = tabTitle, Open = true, Icon = "target" })
    local content = section.Content
    local list = Skibidi.CreateInputList(content, {
        Label = "Detection phrases (blank = all)", Count = 10, Defaults = triggerKeywords,
        Placeholder = function(i) return "keyword " .. i end, Height = 150,
        OnChanged = function(i, value) triggerKeywords[i] = value end,
    })
    return section
end
buildTriggerTab(triggersTab, "Triggers")

local aiSection = Skibidi.CreateSection(aiTab, { Title = "AI", Open = true, Icon = "bot" })
Skibidi.CreateLabel(aiSection.Content, { Text = "Em breve...", Height = 55 })

local notifyRedeemed = true
local notifyFailed = true
local notifyDuration = 3.5
local lastToastAt = 0
local lastToastText = ""
local function showLocalToast(title, text, icon)
    local now = os.clock()
    -- Coalesce identical bursts so repeated events do not flood the UI.
    if text == lastToastText and (now - lastToastAt) < 0.85 then return end
    lastToastAt = now
    lastToastText = text
    Skibidi.ShowNotification(title, text, notifyDuration, icon)
end

local notificationSection = Skibidi.CreateSection(notificationTab, { Title = "Notification settings", Open = true, Icon = "bell" })
local notificationContent = notificationSection.Content
Skibidi.CreateToggle(notificationContent, {
    Label = "Code Redeemed", Icon = "circle-check", Default = notifyRedeemed,
    OnChanged = function(on) notifyRedeemed = on end,
})
Skibidi.CreateToggle(notificationContent, {
    Label = "Redeem Failed", Icon = "circle-x", Default = notifyFailed,
    OnChanged = function(on) notifyFailed = on end,
})
Skibidi.CreateSlider(notificationContent, {
    Label = "Toast Duration", Icon = "timer", Min = 1, Max = 6, Default = notifyDuration,
    Step = 0.5, Format = "%.1fs", OnChanged = function(value) notifyDuration = value end,
})
Skibidi.CreateButton(notificationContent, {
    Text = "Test Success Notification", Icon = "circle-check",
    OnClick = function() showLocalToast("Code Redeemed", "Test notification", "success") end,
})
Skibidi.CreateButton(notificationContent, {
    Text = "Test Failed Notification", Icon = "circle-x",
    OnClick = function() showLocalToast("Redeem Failed", "Test notification", "error") end,
})

local function cleanRich(value)
    return tostring(value or ""):gsub("<[^>]->", "")
end

function consoleLog(message)
    local clean = cleanRich(message)
    if statusWidget then statusWidget.Log(clean) end
    if notifyRedeemed and clean:find("Redeemed:", 1, true) then
        showLocalToast("Code Redeemed", clean, "success")
    elseif notifyFailed and clean:find("Failed:", 1, true) then
        showLocalToast("Redeem Failed", clean, "error")
    end
end

local snipeControl = Skibidi.CreateToggle(mainContent, {
    Label = "Snipe",
    Icon = "crosshair",
    Default = runtime.enabled,
    OnChanged = function(on)
        runtime.enabled = on
        if runtime.enabled then startSnipe() else stopSnipe() end
    end,
})

local autoSubmitControl = Skibidi.CreateToggle(mainContent, {
    Label = "Auto Enter Code",
    Icon = "send",
    Default = runtime.autoSubmit,
    OnChanged = function(on) runtime.autoSubmit = on end,
})

local submitInput = Skibidi.CreateTextInput(mainContent, {
    Label = "Submit After",
    Placeholder = "1",
    Default = tostring(runtime.submitAfter),
    NumericOnly = true,
    Width = 54,
    OnSubmit = function(value)
        runtime.submitAfter = math.clamp(tonumber(value) or 1, 1, 10)
        runtime.capturedParts = {}
    end,
})

-- Also Redeem At (1-9 multi-select) — intermediate cumulative submits
do
    local opts = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
    local defaults = {}
    for _, n in ipairs(opts) do
        if runtime.alsoRedeemAt[tonumber(n)] then
            defaults[#defaults + 1] = n
        end
    end
    Skibidi.CreateDropdown(mainContent, {
        Label = "Also Redeem At",
        Icon = "list-ordered",
        Options = opts,
        Multi = true,
        Default = defaults,
        Placeholder = "None",
        OnChanged = function(selected)
            local set = {}
            if type(selected) == "table" then
                for _, v in ipairs(selected) do
                    local n = tonumber(v)
                    if n and n >= 1 and n <= 9 then
                        set[n] = true
                    end
                end
            end
            runtime.alsoRedeemAt = set
            runtime.capturedParts = {} -- reset buffer on change
            local labels = {}
            for i = 1, 9 do
                if set[i] then labels[#labels + 1] = tostring(i) end
            end
            if #labels > 0 then
                consoleLog("Also Redeem At: " .. table.concat(labels, ", ") .. " (submit linked here, Auto Submit not required)")
            else
                consoleLog("Also Redeem At: none (using Submit After + Auto Submit)")
            end
        end,
    })
end

local spamInput = Skibidi.CreateTextInput(mainContent, {
    Label = "Spam Redeem",
    Placeholder = "20",
    Default = tostring(runtime.spamCount),
    NumericOnly = true,
    Width = 54,
    OnSubmit = function(value)
        runtime.spamCount = math.clamp(math.floor(tonumber(value) or 20), 1, 100)
    end,
})

Skibidi.CreateButton(mainContent, {
    Text = "Force Scan + Code",
    Icon = "scan-line",
    OnClick = function() consoleLog("Force Scan started – manual capture mode") end,
})

Skibidi.CreateButton(mainContent, {
    Text = "Redeem Last Code",
    Icon = "check",
    OnClick = function()
        local code = runtime.lastCode
        if (not code or code == "") and #runtime.capturedParts > 0 then code = table.concat(runtime.capturedParts) end
        if code and code ~= "" then
            runtime.lastCode = code
            startSpamRedeem(code)
        else
            consoleLog("No code to redeem")
        end
    end,
})

Skibidi.CreateButton(mainContent, {
    Text = "Copy Last Code",
    Icon = "copy",
    OnClick = function()
        local code = runtime.lastCode
        if (not code or code == "") and #runtime.capturedParts > 0 then code = table.concat(runtime.capturedParts) end
        if code and code ~= "" then
            if setclipboard then pcall(setclipboard, code) elseif toclipboard then pcall(toclipboard, code) end
            consoleLog("Copied: " .. code)
        else
            consoleLog("No code to copy")
        end
    end,
})

Skibidi.CreateButton(mainContent, {
    Text = "Clear Status",
    Icon = "trash-2",
    OnClick = function() if statusWidget then statusWidget.Clear() end end,
})

local aaSection = Skibidi.CreateSection(aaTab, { Title = "Automation helpers", Open = true, Icon = "shield" })
local aaContent = aaSection.Content
Skibidi.CreateToggle(aaContent, {
    Label = "Anti Ragdoll", Icon = "accessibility", Default = runtime.antiRagdoll,
    OnChanged = function(on)
        runtime.antiRagdoll = on
        if on then startAntiRagdoll() else disconnect(antiRagdollConn); antiRagdollConn = nil end
    end,
})
Skibidi.CreateToggle(aaContent, {
    Label = "Auto Buy", Icon = "shopping-cart", Default = runtime.autoBuy,
    OnChanged = function(on)
        runtime.autoBuy = on
        if on then startAutoBuy() else disconnect(autoBuyConn); autoBuyConn = nil end
    end,
})
Skibidi.CreateToggle(aaContent, {
    Label = "Anti Lag", Icon = "gauge", Default = runtime.antiLag,
    OnChanged = function(on)
        runtime.antiLag = on
        if on then startAntiLag() else stopAntiLag() end
    end,
})
Skibidi.CreateToggle(aaContent, {
    Label = "Remove Accessories", Icon = "user-round-x", Default = runtime.removeAccessories,
    OnChanged = function(on)
        runtime.removeAccessories = on
        if on then removeAccessoriesNow() end
    end,
})
Skibidi.CreateLabel(aaContent, { Text = "Press Z to show or hide the panel.", Height = 24 })

local colorsSection = Skibidi.CreateSection(colorsTab, { Title = "UI", Open = true, Icon = "palette" })
local colorsContent = colorsSection.Content

Skibidi.CreateDropdown(colorsContent, {
    Label = "UI Format", Icon = "layout", Options = { "Normal", "Elite Style" },
    Default = "Normal",
    OnChanged = function(value)
        if value == "Elite Style" then
            switchUIMode("elite")
        else
            switchUIMode("normal")
        end
    end,
})

Skibidi.CreateDropdown(colorsContent, {
    Label = "Background Theme", Icon = "paintbrush", Options = { "Gold", "Blue", "Green", "Red", "Purple", "Dark" },
    Default = "Gold", OnChanged = function(value)
        local presets = {
            Gold   = Color3.fromRGB(220, 160, 60),
            Blue   = Color3.fromRGB(70, 145, 235),
            Green  = Color3.fromRGB(70, 190, 115),
            Red    = Color3.fromRGB(220, 75, 75),
            Purple = Color3.fromRGB(140, 90, 220),
            Dark   = Color3.fromRGB(40, 40, 48),
        }
        local color = presets[value]
        if color then
            applyBackgroundOnly(color)
            saveAccent(color)
        end
    end,
})
Skibidi.CreateColorPicker(colorsContent, {
    Label = "Background Colour", Icon = "palette", Default = savedAccent,
    Tooltip = "Only changes the interface background. Text, buttons and accents stay the same.",
    OnChanged = function(color)
        applyBackgroundOnly(color)
        saveAccent(color)
    end,
})
Skibidi.CreateSlider(colorsContent, {
    Label = "UI Size", Icon = "scaling", Min = 80, Max = 140, Default = 110, Step = 1, Format = "%.0f%%",
    OnChanged = function(value) consoleLog("UI Size: " .. tostring(math.floor(value)) .. "%") end,
})

statusWidget = Skibidi.CreateStatusLog(statusTab, { Height = 275, MaxLines = 500 })
consoleLog("Sniping for codes")

-- ============================================================
-- CREDITS TAB
-- ============================================================
local creditsSection = Skibidi.CreateSection(creditsTab, { Title = "Credits", Open = true, Icon = "users" })
local creditsContent = creditsSection.Content

local creditsList = {
    {
        image = "rbxassetid://92235193275042",
        name = "Snoo",
        role = "Owner",
        color = Color3.fromRGB(255, 215, 60), -- amarelo cromado
    },
    {
        image = "rbxassetid://134719047102035",
        name = "ghostomistico",
        role = "Dev",
        color = Color3.fromRGB(70, 200, 110), -- verde
    },
    {
        image = "rbxassetid://114428274850622",
        name = "Guiznx",
        role = "Dev",
        color = Color3.fromRGB(70, 200, 110), -- verde
    },
}

local function createCreditRow(parent, data)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 56)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 10)

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.Position = UDim2.new(0, 8, 0.5, 0)
    avatar.AnchorPoint = Vector2.new(0, 0.5)
    avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    avatar.BorderSizePixel = 0
    avatar.Image = data.image
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Parent = row
    -- fully rounded (circle)
    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(1, 0)
    avCorner.Parent = avatar
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = data.color
    avStroke.Thickness = 1.5
    avStroke.Transparency = 0.15
    avStroke.Parent = avatar

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -70, 0, 22)
    nameLbl.Position = UDim2.new(0, 62, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 15
    nameLbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text = data.name
    nameLbl.Parent = row

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size = UDim2.new(1, -70, 0, 18)
    roleLbl.Position = UDim2.new(0, 62, 0, 30)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Font = Enum.Font.Gotham
    roleLbl.TextSize = 12
    roleLbl.TextColor3 = data.color
    roleLbl.TextXAlignment = Enum.TextXAlignment.Left
    roleLbl.Text = data.role
    roleLbl.Parent = row

    return row
end

-- layout for credit rows
local creditsLayout = Instance.new("UIListLayout")
creditsLayout.Padding = UDim.new(0, 8)
creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.Parent = creditsContent

local creditsPad = Instance.new("UIPadding")
creditsPad.PaddingTop = UDim.new(0, 6)
creditsPad.PaddingBottom = UDim.new(0, 6)
creditsPad.PaddingLeft = UDim.new(0, 6)
creditsPad.PaddingRight = UDim.new(0, 6)
creditsPad.Parent = creditsContent

for i, data in ipairs(creditsList) do
    local row = createCreditRow(creditsContent, data)
    row.LayoutOrder = i
end

-- ============================================================
-- API / CHARACTER / DESTROY
-- ============================================================
-- ============================================================
-- CHARACTER
-- ============================================================

-- ============================================================
connect(Players.PlayerAdded, function(plr)
    plr.CharacterAdded:Connect(function(char)
        if runtime.removeAccessories then
            task.wait(1)
            removeAccessoriesNow()
        end
    end)
end)

-- ============================================================
-- ============================================================
-- BOTÕES / HOTKEY
-- ============================================================
connect(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    if input.KeyCode == runtime.snipeKey then
        runtime.enabled = not runtime.enabled
        snipeControl.Set(runtime.enabled)
        if runtime.enabled then startSnipe() else stopSnipe() end
    end
end)

-- ============================================================
-- DESTROY
-- ============================================================

-- ============================================================
function runtime.destroy()
    runtime.alive = false
    runtime.enabled = false
    runtime.spamLoopActive = false

    stopSnipe()
    disconnect(antiRagdollConn)
    disconnect(autoBuyConn)
    stopAntiLag()

    for _, c in ipairs(runtime.connections) do
        disconnect(c)
    end
    table.clear(runtime.connections)

    if runtime.gui then pcall(function() runtime.gui:Destroy() end) runtime.gui = nil end
    if runtime.settingsGui then pcall(function() runtime.settingsGui:Destroy() end) runtime.settingsGui = nil end
    destroyEliteUI()

    if environment[RUNTIME_KEY] == runtime then
        environment[RUNTIME_KEY] = nil
    end
end

-- ============================================================
-- ============================================================
-- API
-- ============================================================
_G.SnooGuiznx = {
    Toggle = function()
        runtime.enabled = not runtime.enabled
        snipeControl.Set(runtime.enabled)
        if runtime.enabled then startSnipe() else stopSnipe() end
    end,
    SetKey = function(k) runtime.snipeKey = k end,
    SetCode = function(c) runtime.lastCode = c end,
    SetSpam = function(n)
        runtime.spamCount = math.clamp(tonumber(n) or 20, 1, 100)
        if spamInput and spamInput.TextBox then spamInput.TextBox.Text = tostring(runtime.spamCount) end
    end,
    Redeem = function() if runtime.lastCode then startSpamRedeem(runtime.lastCode) end end,
    Destroy = runtime.destroy,
}

end -- initMainScript

-- Gate: nothing runs without a valid key
startWithKeyGate()
