-- DESTRUCTION_LIB_VERSION = 2026-09-12-a
--[[
  Destruction UI — polished shell library
  exact_clone_open.lua beside this file, or HttpGet from repo.
  v3.2 — keybind list, full config page, shell chrome
]]

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Library = {
    Directory = "Destruction",
    Flags = {},
    Connections = {},
    Open = true,
    Unloaded = false,
    Version = "3.2.0",
    MenuKey = Enum.KeyCode.LeftAlt,
    Theme = {
        Accent = Color3.fromRGB(245, 93, 97),
        Background = Color3.fromRGB(17, 17, 22),
        Surface = Color3.fromRGB(20, 20, 26),
        Surface2 = Color3.fromRGB(27, 27, 35),
        Text = Color3.fromRGB(255, 255, 255),
        Dim = Color3.fromRGB(103, 104, 126),
        Stroke = Color3.fromRGB(33, 33, 38),
    },
}

Library.Keybinds = {} -- { id = { Name, Key, Mode, Active, Row } }
Library._keybindListUI = nil
Library._configHandlers = {} -- flag -> { Set = fn, Get = fn, Type = "toggle"|... }

local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_MED = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

local function ensureDir()
    pcall(function()
        if makefolder then
            makefolder(Library.Directory)
            makefolder(Library.Directory .. "/configs")
        end
    end)
end

local function listConfigFiles()
    ensureDir()
    local names = {}
    local ok, files = pcall(function()
        return listfiles(Library.Directory .. "/configs")
    end)
    if ok and type(files) == "table" then
        for _, f in ipairs(files) do
            local n = tostring(f):match("([^/\\]+)%.json$")
            if n then table.insert(names, n) end
        end
    end
    table.sort(names)
    return names
end

local function serializeFlags()
    local payload = {}
    for k, v in pairs(Library.Flags) do
        if typeof(v) == "Color3" then
            payload[k] = { __color = true, R = v.R, G = v.G, B = v.B }
        elseif typeof(v) == "EnumItem" then
            payload[k] = { __enum = true, EnumType = tostring(v.EnumType), Name = v.Name }
        else
            payload[k] = v
        end
    end
    return payload
end

local function deserializeFlags(data)
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if type(v) == "table" and v.__color then
            Library.Flags[k] = Color3.new(v.R, v.G, v.B)
        elseif type(v) == "table" and v.__enum then
            pcall(function()
                Library.Flags[k] = Enum[v.EnumType][v.Name]
            end)
        else
            Library.Flags[k] = v
        end
        local h = Library._configHandlers[k]
        if h and h.Set then
            pcall(h.Set, Library.Flags[k], true)
        end
    end
end

local function hui()
    local h
    pcall(function()
        if gethui then h = gethui() end
    end)
    return typeof(h) == "Instance" and h or CoreGui
end

local function tween(o, props, t, style, dir)
    if not o or not o.Parent then return nil end
    local tw = TS:Create(
        o,
        TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function conn(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or Library.Theme.Stroke
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft = UDim.new(0, l or 0)
    u.PaddingRight = UDim.new(0, r or 0)
    u.Parent = p
    return u
end

----------------------------------------------------------------
-- Shell loader
----------------------------------------------------------------
local function loadShell()
    local src
    local tries = {
        function() return readfile("exact_clone_open.lua") end,
        function() return readfile("Destruction/exact_clone_open.lua") end,
        function() return game:HttpGet("https://raw.githubusercontent.com/chromatiks/destruction/refs/heads/main/exact_clone_open.lua") end,
    }
    for _, fn in ipairs(tries) do
        local ok, r = pcall(fn)
        if ok and type(r) == "string" and #r > 1000 then
            src = r
            break
        end
    end
    if not src then
        error("[Destruction] exact_clone_open.lua not found — place it next to the library or host it on the repo")
    end
    local chunk, err = loadstring(src)
    if not chunk then error("[Destruction] shell compile: " .. tostring(err)) end
    local a = chunk()
    if type(a) ~= "table" or not a.ScreenGui then
        error("[Destruction] shell did not return instance table")
    end
    return a
end

----------------------------------------------------------------
-- Notifications (slide + fade + accent bar)
----------------------------------------------------------------
local notifHost
local notifQueue = 0

function Library:Notify(opts)
    if type(opts) ~= "table" then
        opts = { Title = tostring(opts) }
    end
    if not notifHost or not notifHost.Parent then
        local sg = Instance.new("ScreenGui")
        sg.Name = "DestNotifs"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 5000
        sg.Parent = hui()
        local h = Instance.new("Frame")
        h.BackgroundTransparency = 1
        h.AnchorPoint = Vector2.new(1, 0)
        h.Position = UDim2.new(1, -16, 0, 56)
        h.Size = UDim2.new(0, 320, 1, -70)
        h.Parent = sg
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 10)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Right
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = h
        notifHost = h
    end

    notifQueue += 1
    local order = notifQueue

    local f = Instance.new("Frame")
    f.BackgroundColor3 = Library.Theme.Background
    f.BorderSizePixel = 0
    f.Size = UDim2.new(0, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.ClipsDescendants = true
    f.LayoutOrder = order
    f.BackgroundTransparency = 1
    f.Parent = notifHost
    corner(f, 10)
    stroke(f, Library.Theme.Stroke, 1)

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, 0, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent = f
    pad(inner, 14, 14, 16, 14)

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Library.Theme.Accent
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.Position = UDim2.fromOffset(0, 0)
    bar.Parent = f
    corner(bar, 2)

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, -8, 0, 16)
    t.Position = UDim2.fromOffset(6, 0)
    t.FontFace = FONT
    t.TextSize = 14
    t.TextColor3 = Library.Theme.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = opts.Title or "Notification"
    t.Parent = inner

    if opts.Content or opts.Description then
        local b = Instance.new("TextLabel")
        b.BackgroundTransparency = 1
        b.Position = UDim2.fromOffset(6, 20)
        b.Size = UDim2.new(1, -8, 0, 0)
        b.AutomaticSize = Enum.AutomaticSize.Y
        b.FontFace = FONT_MED
        b.TextSize = 12
        b.TextColor3 = Library.Theme.Dim
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextWrapped = true
        b.Text = opts.Content or opts.Description
        b.Parent = inner
    end

    -- enter: expand width + fade
    f.Size = UDim2.new(0, 0, 0, 0)
    task.defer(function()
        if not f.Parent then return end
        tween(f, { Size = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 0 }, 0.32, Enum.EasingStyle.Quint)
        -- slight scale feel via stroke
        local st = f:FindFirstChildOfClass("UIStroke")
        if st then
            st.Transparency = 1
            tween(st, { Transparency = 0 }, 0.28)
        end
    end)

    local life = opts.Duration or 3.5
    task.delay(life, function()
        if not f.Parent then return end
        tween(f, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, f.AbsoluteSize.Y) }, 0.28, Enum.EasingStyle.Quint)
        local st = f:FindFirstChildOfClass("UIStroke")
        if st then tween(st, { Transparency = 1 }, 0.2) end
        for _, d in ipairs(f:GetDescendants()) do
            if d:IsA("TextLabel") then
                tween(d, { TextTransparency = 1 }, 0.2)
            elseif d:IsA("Frame") and d ~= f then
                tween(d, { BackgroundTransparency = 1 }, 0.2)
            end
        end
        task.wait(0.3)
        f:Destroy()
    end)
end

----------------------------------------------------------------
-- HSV color picker popup (shared)
----------------------------------------------------------------
local function openColorPicker(anchor, current, onChange)
    -- destroy previous picker
    local old = hui():FindFirstChild("DestColorPicker")
    if old then old:Destroy() end

    local h, s, v = Color3.toHSV(current or Library.Theme.Accent)
    local alpha = 1

    local sg = Instance.new("ScreenGui")
    sg.Name = "DestColorPicker"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 6000
    sg.Parent = hui()

    local panel = Instance.new("Frame")
    panel.BackgroundColor3 = Library.Theme.Background
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromOffset(200, 230)
    panel.ClipsDescendants = true
    panel.BackgroundTransparency = 1
    panel.Parent = sg
    corner(panel, 10)
    stroke(panel, Library.Theme.Stroke, 1)

    -- position near anchor
    local ap = typeof(anchor) == "Instance" and anchor.AbsolutePosition or Vector2.new(200, 200)
    local asz = typeof(anchor) == "Instance" and anchor.AbsoluteSize or Vector2.new(18, 18)
    local vp = Camera.ViewportSize
    local px = math.clamp(ap.X, 8, vp.X - 208)
    local py = math.clamp(ap.Y + asz.Y + 6, 8, vp.Y - 238)
    panel.Position = UDim2.fromOffset(px, py)

    -- SV square
    local sv = Instance.new("ImageLabel")
    sv.Name = "SV"
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    sv.BorderSizePixel = 0
    sv.Position = UDim2.fromOffset(12, 12)
    sv.Size = UDim2.fromOffset(176, 140)
    sv.Image = "rbxassetid://4155801252"
    sv.Parent = panel
    corner(sv, 6)

    local cursor = Instance.new("Frame")
    cursor.Size = UDim2.fromOffset(12, 12)
    cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cursor.BorderSizePixel = 0
    cursor.Position = UDim2.new(s, 0, 1 - v, 0)
    cursor.Parent = sv
    corner(cursor, 99)
    stroke(cursor, Color3.fromRGB(0, 0, 0), 1)

    -- Hue bar
    local hueBar = Instance.new("ImageLabel")
    hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueBar.BorderSizePixel = 0
    hueBar.Position = UDim2.fromOffset(12, 160)
    hueBar.Size = UDim2.fromOffset(176, 12)
    hueBar.Image = "rbxassetid://3570695787"
    hueBar.Parent = panel
    corner(hueBar, 4)

    local hueCursor = Instance.new("Frame")
    hueCursor.Size = UDim2.fromOffset(4, 14)
    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
    hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueCursor.BorderSizePixel = 0
    hueCursor.Parent = hueBar
    corner(hueCursor, 2)

    local preview = Instance.new("Frame")
    preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
    preview.BorderSizePixel = 0
    preview.Position = UDim2.fromOffset(12, 184)
    preview.Size = UDim2.fromOffset(176, 28)
    preview.Parent = panel
    corner(preview, 6)

    local function emit(silent)
        local c = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = c
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        if onChange and not silent then
            task.spawn(onChange, c)
        end
        return c
    end

    local draggingSV, draggingHue = false, false

    local function updateSV(input)
        local relX = math.clamp((input.Position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        local relY = math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        s, v = relX, 1 - relY
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        emit()
    end

    local function updateHue(input)
        local rel = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        h = rel
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        emit()
    end

    conn(sv.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            updateSV(i)
        end
    end)
    conn(hueBar.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            updateHue(i)
        end
    end)
    conn(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingSV, draggingHue = false, false
        end
    end)
    conn(UIS.InputChanged, function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        if draggingSV then updateSV(i) end
        if draggingHue then updateHue(i) end
    end)

    -- click outside to close
    local blocker = Instance.new("TextButton")
    blocker.BackgroundTransparency = 1
    blocker.Size = UDim2.fromScale(1, 1)
    blocker.Text = ""
    blocker.ZIndex = 0
    blocker.Parent = sg
    panel.ZIndex = 2
    for _, d in ipairs(panel:GetDescendants()) do
        if d:IsA("GuiObject") then d.ZIndex = 3 end
    end
    conn(blocker.MouseButton1Click, function()
        tween(panel, { BackgroundTransparency = 1 }, 0.15)
        task.delay(0.16, function()
            if sg.Parent then sg:Destroy() end
        end)
    end)

    -- open anim
    panel.Size = UDim2.fromOffset(200, 0)
    tween(panel, { Size = UDim2.fromOffset(200, 230), BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Quint)
    emit(true)

    return sg
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Library:Window(opts)
    -- DESTRUCTION_LIB_VERSION 2026-09-12-a
    opts = opts or {}
    local a = loadShell()
    local gui = a.ScreenGui
    local main = a.Frame
    local side = a.Frame_2
    local content = a.Frame_7
    local titleL = a.TextLabel
    local subL = a.TextLabel_2
    local leftScroll = a.ScrollingFrame_2
    local rightScroll = a.ScrollingFrame_3
    local watermark = a.Frame_67
    Library._wmFrame = watermark

    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)

    -- entrance
    main.BackgroundTransparency = 1
    main.Visible = true
    task.defer(function()
        tween(main, { BackgroundTransparency = 0 }, 0.35, Enum.EasingStyle.Quint)
    end)

    -- live watermark
    task.spawn(function()
        local frames, last = 0, tick()
        local labels = {}
        if watermark then
            for _, d in ipairs(watermark:GetDescendants()) do
                if d:IsA("TextLabel") then table.insert(labels, d) end
            end
        end
        conn(RS.RenderStepped, function()
            frames += 1
            local now = tick()
            if now - last < 1 then return end
            local fps = frames
            frames = 0
            last = now
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            local timeStr = os.date("%H:%M:%S")
            for _, l in ipairs(labels) do
                local t = l.Text
                if t:find("FPS") or t:find("fps") then
                    l.Text = fps .. " FPS"
                elseif t:find("ms") then
                    l.Text = ping .. " ms"
                elseif t:match("^%d%d:%d%d:%d%d$") then
                    l.Text = timeStr
                end
            end
        end)
        pcall(function()
            local info = MarketplaceService:GetProductInfo(game.PlaceId)
            if labels[#labels] and info and info.Name then
                labels[#labels].Text = info.Name
            end
        end)
    end)

    local function clearScroll(sf)
        for _, ch in ipairs(sf:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                ch:Destroy()
            end
        end
        if not sf:FindFirstChildOfClass("UIListLayout") then
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0, 12)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Parent = sf
        end
        if not sf:FindFirstChildOfClass("UIPadding") then
            pad(sf, 4, 8, 4, 4)
        end
    end
    clearScroll(leftScroll)
    clearScroll(rightScroll)

    -- Remove shell demo leftovers (sample rows / textboxes that look like a search bar)
    if content then
        for _, d in ipairs(content:GetDescendants()) do
            if d:IsA("TextBox") then
                d:Destroy()
            end
        end
        -- wipe any pre-built section frames still sitting outside the two scrolls
        for _, ch in ipairs(content:GetChildren()) do
            if ch:IsA("Frame") and ch ~= leftScroll and ch ~= rightScroll and ch.Name ~= "" then
                -- keep header labels only; destroy extra chrome sample frames if any
            end
        end
    end
    -- also clear sidebar extra demo if more than tab slots
    if side then
        for _, d in ipairs(side:GetDescendants()) do
            if d:IsA("TextBox") then
                d:Destroy()
            end
        end
    end

    titleL.Text = opts.Name or opts.Title or titleL.Text
    if opts.Subtitle or opts.Description then
        subL.Text = opts.Subtitle or opts.Description
    end

    local tabFrames = { a.Frame_3, a.Frame_4, a.Frame_5, a.Frame_6 }
    local tabButtons = { a.TextButton, a.TextButton_2, a.TextButton_3, a.TextButton_4 }
    local tabIcons = { a.ImageLabel_2, a.ImageLabel_3, a.ImageLabel_4, a.ImageLabel_5 }
    local tabs = {}
    local tabSections = {}
    local current
    local switching = false

    -- Tab selection: shell uses BackgroundTransparency (0 = selected overlay, 1 = hidden)
    local function applyTabVisual(idx, on, animate)
        local fr = tabFrames[idx]
        local ic = tabIcons[idx]
        if fr then
            if animate then
                tween(fr, {
                    BackgroundTransparency = on and 0 or 1,
                    BackgroundColor3 = Library.Theme.Surface2,
                }, 0.2, Enum.EasingStyle.Quint)
            else
                fr.BackgroundTransparency = on and 0 or 1
                fr.BackgroundColor3 = Library.Theme.Surface2
            end
            fr.Visible = true
        end
        if ic then
            if animate then
                tween(ic, {
                    ImageColor3 = on and Library.Theme.Accent or Library.Theme.Dim,
                }, 0.2, Enum.EasingStyle.Quint)
            else
                ic.ImageColor3 = on and Library.Theme.Accent or Library.Theme.Dim
            end
        end
    end

    local function selectTab(i)
        if switching then return end
        if current == i then return end
        switching = true
        current = i

        for idx = 1, #tabFrames do
            applyTabVisual(idx, idx == i, true)
        end

        -- Show only this tab's sections (no aggressive transparency fade that breaks the UI)
        for ti, list in pairs(tabSections) do
            local show = (ti == i)
            for _, sec in ipairs(list) do
                if sec and sec.Root then
                    sec.Root.Visible = show
                end
            end
        end

        if tabs[i] then
            if titleL then
                titleL.Text = tabs[i].Name or titleL.Text
            end
            if subL and tabs[i].Subtitle then
                subL.Text = tabs[i].Subtitle
            end
        end

        switching = false
    end

    -- Init all tab frames as deselected; hide extras until used
    for idx, fr in ipairs(tabFrames) do
        if fr then
            fr.BackgroundColor3 = Library.Theme.Surface2
            fr.BackgroundTransparency = 1
            fr.Visible = false
        end
        if tabIcons[idx] then
            tabIcons[idx].ImageColor3 = Library.Theme.Dim
        end
    end

    for i, btn in ipairs(tabButtons) do
        if btn then
            conn(btn.MouseButton1Click, function()
                if tabs[i] then
                    selectTab(i)
                end
            end)
            conn(btn.MouseEnter, function()
                if current ~= i and tabFrames[i] and tabs[i] then
                    tween(tabFrames[i], { BackgroundTransparency = 0.55 }, 0.12)
                end
            end)
            conn(btn.MouseLeave, function()
                if current ~= i and tabFrames[i] then
                    tween(tabFrames[i], { BackgroundTransparency = 1 }, 0.12)
                end
            end)
        end
    end

    local Window = {
        Shell = a,
        Main = main,
        Gui = gui,
    }
    local tabCount = 0

    Window.Tab = function(self, t)

        t = t or {}
        tabCount += 1
        local idx = tabCount
        tabs[idx] = { Name = t.Name or ("Tab " .. idx), Subtitle = t.Subtitle or t.Description, Icon = t.Icon }
        tabSections[idx] = {}

        if idx > #tabFrames then
            warn("[Destruction] Max " .. tostring(#tabFrames) .. " tabs in this shell layout (tab " .. tostring(t.Name) .. " ignored visually)")
        end

        if tabFrames[idx] then
            tabFrames[idx].Visible = true
            tabFrames[idx].BackgroundTransparency = 1
            tabFrames[idx].BackgroundColor3 = Library.Theme.Surface2
        end
        if tabIcons[idx] then
            if t.Icon then
                local icon = tostring(t.Icon)
                if not icon:find("rbxassetid://") and not icon:find("rbxthumb") then
                    icon = "rbxassetid://" .. icon:gsub("%D", "")
                end
                tabIcons[idx].Image = icon
            end
            tabIcons[idx].ImageColor3 = Library.Theme.Dim
            tabIcons[idx].ImageTransparency = 0
            tabIcons[idx].Visible = true
        end

        if idx == 1 then
            task.defer(function()
                current = nil
                selectTab(1)
            end)
        end

        local Tab = { Index = idx, Name = tabs[idx].Name }

        function Tab:Section(s)
            s = s or {}
            local parent = (s.Side == "Right" or s.Side == 2) and rightScroll or leftScroll

            -- shell section card: Surface bg, radius 3, header + 1px divider
            local root = Instance.new("Frame")
            root.BackgroundColor3 = Library.Theme.Surface
            root.BackgroundTransparency = 0
            root.BorderSizePixel = 0
            root.Size = UDim2.new(1, -2, 0, 0)
            root.AutomaticSize = Enum.AutomaticSize.Y
            root.Visible = (current == idx) or (current == nil and idx == 1)
            root.Parent = parent
            corner(root, 3)
            table.insert(tabSections[idx], { Root = root })

            local head = Instance.new("TextLabel")
            head.BackgroundTransparency = 1
            head.Position = UDim2.fromOffset(12, 8)
            head.Size = UDim2.new(1, -24, 0, 16)
            head.FontFace = FONT
            head.TextSize = 13
            head.TextColor3 = Library.Theme.Text
            head.TextXAlignment = Enum.TextXAlignment.Left
            head.Text = s.Name or "Section"
            head.Parent = root

            local divider = Instance.new("Frame")
            divider.BackgroundColor3 = Library.Theme.Stroke
            divider.BorderSizePixel = 0
            divider.Position = UDim2.fromOffset(0, 30)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Parent = root

            local body = Instance.new("Frame")
            body.BackgroundTransparency = 1
            body.Position = UDim2.fromOffset(12, 38)
            body.Size = UDim2.new(1, -24, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Parent = root
            local bl = Instance.new("UIListLayout")
            bl.Padding = UDim.new(0, 10)
            bl.SortOrder = Enum.SortOrder.LayoutOrder
            bl.Parent = body
            local bp = Instance.new("UIPadding")
            bp.PaddingBottom = UDim.new(0, 12)
            bp.Parent = body

            local Section = {}

            local function row(h)
                local r = Instance.new("Frame")
                r.BackgroundTransparency = 1
                r.Size = UDim2.new(1, 0, 0, h or 22)
                r.Parent = body
                return r
            end

            function Section:Toggle(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local state = o.Default == true or o.default == true
                if flag then Library.Flags[flag] = state end

                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -44, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.TextYAlignment = Enum.TextYAlignment.Center
                nl.Text = o.Name or o.name or "Toggle"
                nl.Parent = r

                -- shell track 27x16, knob 10x10
                local track = Instance.new("Frame")
                track.AnchorPoint = Vector2.new(1, 0.5)
                track.Position = UDim2.new(1, 0, 0.5, 0)
                track.Size = UDim2.fromOffset(27, 16)
                track.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Surface2
                track.BorderSizePixel = 0
                track.Parent = r
                corner(track, 4)

                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(10, 10)
                knob.Position = state and UDim2.fromOffset(14, 3) or UDim2.fromOffset(3, 3)
                knob.BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(82, 82, 100)
                knob.BorderSizePixel = 0
                knob.ZIndex = 2
                knob.Parent = track
                corner(knob, 3)

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.fromScale(1, 1)
                hit.Text = ""
                hit.ZIndex = 3
                hit.AutoButtonColor = false
                hit.Parent = r

                local function set(v, silent)
                    state = not not v
                    if flag then Library.Flags[flag] = state end
                    tween(track, {
                        BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Surface2,
                    }, 0.18, Enum.EasingStyle.Quint)
                    tween(knob, {
                        Position = state and UDim2.fromOffset(14, 3) or UDim2.fromOffset(3, 3),
                        BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(82, 82, 100),
                    }, 0.2, Enum.EasingStyle.Quint)
                    if not silent then
                        if o.Callback then task.spawn(o.Callback, state) end
                        if o.callback then task.spawn(o.callback, state) end
                    end
                end
                conn(hit.MouseButton1Click, function() set(not state) end)
                if flag then
                    Library._configHandlers[flag] = {
                        Set = function(v) set(v, true) end,
                        Get = function() return state end,
                        Type = "toggle",
                    }
                end
                return { Set = set, Get = function() return state end, Flag = flag, Root = r }
            end

            function Section:Slider(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local min = tonumber(o.Min or o.min) or 0
                local max = tonumber(o.Max or o.max) or 100
                local float = tonumber(o.Float or o.float or o.Increment) or 1
                local suffix = o.Suffix or o.suffix or ""
                local cur = tonumber(o.Default or o.default) or min
                cur = math.clamp(cur, min, max)
                if flag then Library.Flags[flag] = cur end

                local r = row(34)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -56, 0, 14)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or o.name or "Slider"
                nl.Parent = r

                local valL = Instance.new("TextLabel")
                valL.BackgroundTransparency = 1
                valL.AnchorPoint = Vector2.new(1, 0)
                valL.Position = UDim2.new(1, 0, 0, 0)
                valL.Size = UDim2.fromOffset(54, 14)
                valL.FontFace = FONT
                valL.TextSize = 13
                valL.TextColor3 = Library.Theme.Text
                valL.TextXAlignment = Enum.TextXAlignment.Right
                valL.Text = tostring(cur) .. suffix
                valL.Parent = r

                local track = Instance.new("Frame")
                track.BackgroundColor3 = Library.Theme.Surface2
                track.BorderSizePixel = 0
                track.Position = UDim2.fromOffset(0, 22)
                track.Size = UDim2.new(1, 0, 0, 5)
                track.Parent = r
                corner(track, 3)

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Library.Theme.Accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new((cur - min) / math.max(max - min, 1e-9), 0, 1, 0)
                fill.Parent = track
                corner(fill, 3)

                local function quantize(v)
                    if float >= 1 then return math.floor(v / float + 0.5) * float end
                    local d = math.max(1, math.floor(1 / float + 0.5))
                    return math.floor(v * d + 0.5) / d
                end
                local function apply(v, silent)
                    v = math.clamp(quantize(v), min, max)
                    cur = v
                    if flag then Library.Flags[flag] = cur end
                    fill.Size = UDim2.new((cur - min) / math.max(max - min, 1e-9), 0, 1, 0)
                    valL.Text = tostring(cur) .. suffix
                    if not silent then
                        if o.Callback then task.spawn(o.Callback, cur) end
                        if o.callback then task.spawn(o.callback, cur) end
                    end
                end

                local dragging = false
                conn(track.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                        apply(min + rel * (max - min))
                    end
                end)
                conn(UIS.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                conn(UIS.InputChanged, function(input)
                    if not dragging then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement
                        and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    apply(min + rel * (max - min))
                end)
                if flag then
                    Library._configHandlers[flag] = {
                        Set = function(v) apply(tonumber(v) or cur, true) end,
                        Get = function() return cur end,
                        Type = "slider",
                    }
                end
                return { Set = apply, Get = function() return cur end, Flag = flag, Root = r }
            end

            function Section:Dropdown(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local items = o.Values or o.Options or o.Items or o.items or o.options or {}
                local multi = o.MultiSelect or o.multi or false
                local searchable = o.Search ~= false and (#items >= 8 or o.Search == true)
                local cur = o.Default or o.default
                if multi then
                    if type(cur) ~= "table" then cur = {} end
                else
                    cur = cur or items[1]
                end
                if flag then Library.Flags[flag] = cur end

                local r = row(52)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, 0, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or o.name or "Dropdown"
                nl.Parent = r

                local box = Instance.new("Frame")
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 20)
                box.Size = UDim2.new(1, 0, 0, 28)
                box.Parent = r
                corner(box, 3)

                local function displayText()
                    if multi and type(cur) == "table" then
                        if #cur == 0 then return o.Placeholder or "None" end
                        if #cur <= 2 then return table.concat(cur, ", ") end
                        return tostring(cur[1]) .. " +" .. tostring(#cur - 1)
                    end
                    return tostring(cur or o.Placeholder or "None")
                end

                local valL = Instance.new("TextLabel")
                valL.BackgroundTransparency = 1
                valL.Position = UDim2.fromOffset(10, 0)
                valL.Size = UDim2.new(1, -32, 1, 0)
                valL.FontFace = FONT
                valL.TextSize = 13
                valL.TextColor3 = Library.Theme.Text
                valL.TextXAlignment = Enum.TextXAlignment.Left
                valL.TextTruncate = Enum.TextTruncate.AtEnd
                valL.Text = displayText()
                valL.Parent = box

                local chevron = Instance.new("ImageLabel")
                chevron.BackgroundTransparency = 1
                chevron.AnchorPoint = Vector2.new(1, 0.5)
                chevron.Position = UDim2.new(1, -8, 0.5, 0)
                chevron.Size = UDim2.fromOffset(11, 11)
                chevron.Image = "rbxassetid://127296511745226"
                chevron.ImageColor3 = Library.Theme.Dim
                chevron.Parent = box

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.fromScale(1, 1)
                hit.Text = ""
                hit.ZIndex = 3
                hit.AutoButtonColor = false
                hit.Parent = box

                local open = false
                local drop, dropConn, outsideConn
                local hostGui = (r:FindFirstAncestorOfClass("ScreenGui")) or gui

                local function isSelected(it)
                    if multi and type(cur) == "table" then
                        for _, v in ipairs(cur) do
                            if v == it then return true end
                        end
                        return false
                    end
                    return cur == it
                end

                local function close()
                    if dropConn then dropConn:Disconnect() dropConn = nil end
                    if outsideConn then outsideConn:Disconnect() outsideConn = nil end
                    if drop then
                        local d = drop
                        drop = nil
                        pcall(function() d:Destroy() end)
                    end
                    open = false
                    pcall(function()
                        tween(chevron, { Rotation = 0, ImageColor3 = Library.Theme.Dim }, 0.15)
                    end)
                end

                local function placeDrop()
                    if not drop or not box.Parent then return end
                    local abs = box.AbsolutePosition
                    local asz = box.AbsoluteSize
                    drop.Position = UDim2.fromOffset(abs.X, abs.Y + asz.Y + 4)
                    drop.Size = UDim2.fromOffset(asz.X, drop.Size.Y.Offset)
                end

                local function openDrop()
                    if open then close() return end
                    open = true
                    tween(chevron, { Rotation = 180, ImageColor3 = Library.Theme.Accent }, 0.15)

                    local abs = box.AbsolutePosition
                    local asz = box.AbsoluteSize
                    local maxH = math.clamp(26 * math.max(#items, 1) + (searchable and 36 or 10), 40, 180)

                    drop = Instance.new("Frame")
                    drop.Name = "DestDropdown"
                    drop.BackgroundColor3 = Library.Theme.Surface
                    drop.BorderSizePixel = 0
                    drop.Position = UDim2.fromOffset(abs.X, abs.Y + asz.Y + 4)
                    drop.Size = UDim2.fromOffset(asz.X, maxH)
                    drop.ZIndex = 400
                    drop.Parent = hostGui
                    corner(drop, 3)
                    stroke(drop, Library.Theme.Stroke, 1)

                    local y0 = 5
                    if searchable then
                        local searchBox = Instance.new("TextBox")
                        searchBox.BackgroundColor3 = Library.Theme.Surface2
                        searchBox.BorderSizePixel = 0
                        searchBox.Position = UDim2.fromOffset(6, 6)
                        searchBox.Size = UDim2.new(1, -12, 0, 24)
                        searchBox.FontFace = FONT
                        searchBox.TextSize = 12
                        searchBox.TextColor3 = Library.Theme.Text
                        searchBox.PlaceholderText = "Search"
                        searchBox.PlaceholderColor3 = Library.Theme.Dim
                        searchBox.ClearTextOnFocus = false
                        searchBox.Text = ""
                        searchBox.ZIndex = 401
                        searchBox.Parent = drop
                        corner(searchBox, 3)
                        y0 = 34
                        conn(searchBox:GetPropertyChangedSignal("Text"), function()
                            local filter = string.lower(searchBox.Text or "")
                            for _, ch in ipairs(drop:GetDescendants()) do
                                if ch:IsA("TextButton") and ch:GetAttribute("ItemName") then
                                    local name = string.lower(ch:GetAttribute("ItemName"))
                                    ch.Visible = filter == "" or string.find(name, filter, 1, true) ~= nil
                                end
                            end
                        end)
                    end

                    local sc = Instance.new("ScrollingFrame")
                    sc.BackgroundTransparency = 1
                    sc.Position = UDim2.fromOffset(4, y0)
                    sc.Size = UDim2.new(1, -8, 1, -(y0 + 4))
                    sc.BorderSizePixel = 0
                    sc.ScrollBarThickness = 2
                    sc.ScrollBarImageColor3 = Library.Theme.Stroke
                    sc.CanvasSize = UDim2.new()
                    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    sc.ZIndex = 401
                    sc.Parent = drop
                    local lay = Instance.new("UIListLayout")
                    lay.Padding = UDim.new(0, 1)
                    lay.Parent = sc

                    for _, it in ipairs(items) do
                        local on = isSelected(it)
                        local b = Instance.new("TextButton")
                        b.AutoButtonColor = false
                        b.BackgroundColor3 = Library.Theme.Accent
                        b.BackgroundTransparency = on and 0.82 or 1
                        b.Size = UDim2.new(1, 0, 0, 24)
                        b.FontFace = FONT
                        b.TextSize = 13
                        b.TextColor3 = on and Library.Theme.Accent or Library.Theme.Text
                        b.TextXAlignment = Enum.TextXAlignment.Left
                        b.Text = "  " .. tostring(it)
                        b:SetAttribute("ItemName", tostring(it))
                        b.ZIndex = 402
                        b.Parent = sc
                        corner(b, 3)
                        conn(b.MouseEnter, function()
                            if not isSelected(it) then
                                b.BackgroundTransparency = 0.9
                                b.BackgroundColor3 = Library.Theme.Surface2
                            end
                        end)
                        conn(b.MouseLeave, function()
                            if not isSelected(it) then
                                b.BackgroundTransparency = 1
                            end
                        end)
                        conn(b.MouseButton1Click, function()
                            if multi then
                                if type(cur) ~= "table" then cur = {} end
                                local found
                                for i, v in ipairs(cur) do
                                    if v == it then found = i break end
                                end
                                if found then table.remove(cur, found) else table.insert(cur, it) end
                                if flag then Library.Flags[flag] = cur end
                                valL.Text = displayText()
                                if o.Callback then task.spawn(o.Callback, cur) end
                                close()
                                openDrop()
                            else
                                cur = it
                                if flag then Library.Flags[flag] = cur end
                                valL.Text = displayText()
                                if o.Callback then task.spawn(o.Callback, cur) end
                                close()
                            end
                        end)
                    end

                    dropConn = RS.RenderStepped:Connect(placeDrop)
                    table.insert(Library.Connections, dropConn)
                    task.defer(function()
                        outsideConn = UIS.InputBegan:Connect(function(input)
                            if not open or not drop then return end
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                                and input.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end
                            local p = Vector2.new(input.Position.X, input.Position.Y)
                            local dpos, dsz = drop.AbsolutePosition, drop.AbsoluteSize
                            local bpos, bsz = box.AbsolutePosition, box.AbsoluteSize
                            local inDrop = p.X >= dpos.X and p.X <= dpos.X + dsz.X and p.Y >= dpos.Y and p.Y <= dpos.Y + dsz.Y
                            local inBox = p.X >= bpos.X and p.X <= bpos.X + bsz.X and p.Y >= bpos.Y and p.Y <= bpos.Y + bsz.Y
                            if not inDrop and not inBox then close() end
                        end)
                        table.insert(Library.Connections, outsideConn)
                    end)
                end

                conn(hit.MouseButton1Click, openDrop)
                if flag then
                    Library._configHandlers[flag] = {
                        Set = function(v)
                            cur = v
                            if flag then Library.Flags[flag] = cur end
                            valL.Text = displayText()
                        end,
                        Get = function() return cur end,
                        Type = "dropdown",
                    }
                end
                return {
                    Set = function(v) cur = v valL.Text = displayText() end,
                    Get = function() return cur end,
                    Flag = flag,
                    Root = r,
                }
            end

            function Section:Button(o)
                o = o or {}
                local r = row(28)
                local b = Instance.new("TextButton")
                b.AutoButtonColor = false
                b.BackgroundColor3 = Library.Theme.Surface2
                b.BorderSizePixel = 0
                b.Size = UDim2.fromScale(1, 1)
                b.FontFace = FONT
                b.TextSize = 13
                b.TextColor3 = Library.Theme.Text
                b.Text = o.Name or o.name or "Button"
                b.Parent = r
                corner(b, 3)
                conn(b.MouseEnter, function()
                    tween(b, { BackgroundColor3 = Color3.fromRGB(34, 34, 42) }, 0.12)
                end)
                conn(b.MouseLeave, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Surface2 }, 0.12)
                end)
                conn(b.MouseButton1Click, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Accent }, 0.06)
                    task.delay(0.1, function()
                        tween(b, { BackgroundColor3 = Library.Theme.Surface2 }, 0.18)
                    end)
                    if o.Callback then task.spawn(o.Callback) end
                    if o.callback then task.spawn(o.callback) end
                end)
                return { Root = r }
            end

            function Section:Textbox(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local cur = o.Default or o.default or ""
                if flag then Library.Flags[flag] = cur end
                local r = row(48)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, 0, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or o.name or "Textbox"
                nl.Parent = r
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 18)
                box.Size = UDim2.new(1, 0, 0, 26)
                box.FontFace = FONT
                box.TextSize = 13
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderText = o.Placeholder or o.placeholder or ""
                box.PlaceholderColor3 = Library.Theme.Dim
                box.ClearTextOnFocus = false
                box.Text = tostring(cur)
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = r
                corner(box, 3)
                local padx = Instance.new("UIPadding")
                padx.PaddingLeft = UDim.new(0, 10)
                padx.PaddingRight = UDim.new(0, 10)
                padx.Parent = box
                local function commit()
                    cur = box.Text
                    if flag then Library.Flags[flag] = cur end
                    if o.Callback then task.spawn(o.Callback, cur) end
                    if o.callback then task.spawn(o.callback, cur) end
                end
                conn(box.FocusLost, function() commit() end)
                if flag then
                    Library._configHandlers[flag] = {
                        Set = function(v) cur = tostring(v or "") box.Text = cur end,
                        Get = function() return cur end,
                        Type = "textbox",
                    }
                end
                return {
                    Set = function(v) cur = tostring(v or "") box.Text = cur end,
                    Get = function() return cur end,
                    Root = r,
                }
            end

            function Section:Label(o)
                local r = row(16)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.fromScale(1, 1)
                nl.FontFace = FONT_MED
                nl.TextSize = 12
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = type(o) == "table" and (o.Text or o.Name) or tostring(o)
                nl.Parent = r
                return { Root = r }
            end

            function Section:Keybind(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local key = o.Default or o.default or o.Key
                local mode = o.Mode or o.mode or "Toggle"
                local name = o.Name or o.name or "Keybind"
                local cb = o.Callback or o.callback
                if flag then
                    Library.Flags[flag] = { key = key, mode = mode, active = false }
                end
                local function keyStr(k)
                    if not k then return "None" end
                    if typeof(k) == "EnumItem" then return k.Name end
                    return tostring(k)
                end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -78, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = name
                nl.Parent = r
                local box = Instance.new("Frame")
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, 0, 0.5, 0)
                box.Size = UDim2.fromOffset(72, 20)
                box.Parent = r
                corner(box, 3)
                local kl = Instance.new("TextLabel")
                kl.BackgroundTransparency = 1
                kl.Size = UDim2.fromScale(1, 1)
                kl.FontFace = FONT
                kl.TextSize = 12
                kl.TextColor3 = Library.Theme.Text
                kl.Text = keyStr(key)
                kl.Parent = box
                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.fromScale(1, 1)
                hit.Text = ""
                hit.ZIndex = 3
                hit.AutoButtonColor = false
                hit.Parent = box
                local listening = false
                local kbId = tostring(flag or name)
                Library.Keybinds[kbId] = { Name = name, Key = key, Mode = mode, Active = false }
                local function refreshList()
                    if Library._keybindListUI and Library._keybindListUI.Refresh then
                        Library._keybindListUI.Refresh()
                    end
                end
                conn(hit.MouseButton1Click, function()
                    listening = true
                    kl.Text = "..."
                    kl.TextColor3 = Library.Theme.Accent
                end)
                conn(UIS.InputBegan, function(input)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            if flag and type(Library.Flags[flag]) == "table" then
                                Library.Flags[flag].key = key
                            end
                            Library.Keybinds[kbId].Key = key
                            kl.Text = keyStr(key)
                            kl.TextColor3 = Library.Theme.Text
                            listening = false
                            refreshList()
                        end
                        return
                    end
                    if key and input.KeyCode == key then
                        local data = flag and Library.Flags[flag]
                        if mode == "Hold" then
                            if type(data) == "table" then data.active = true end
                            Library.Keybinds[kbId].Active = true
                            if cb then task.spawn(cb, true) end
                        else
                            local ns = true
                            if type(data) == "table" then
                                data.active = not data.active
                                ns = data.active
                            end
                            Library.Keybinds[kbId].Active = ns
                            if cb then task.spawn(cb, ns) end
                        end
                        refreshList()
                    end
                end)
                conn(UIS.InputEnded, function(input)
                    if mode == "Hold" and key and input.KeyCode == key then
                        local data = flag and Library.Flags[flag]
                        if type(data) == "table" then data.active = false end
                        Library.Keybinds[kbId].Active = false
                        if cb then task.spawn(cb, false) end
                        refreshList()
                    end
                end)
                refreshList()
                return { Flag = flag, Get = function() return key end, Root = r }
            end

            function Section:Colorpicker(o)
                o = o or {}
                local flag = o.Flag or o.flag or o.Name
                local col = o.Default or o.default or Library.Theme.Accent
                if typeof(col) ~= "Color3" then col = Library.Theme.Accent end
                if flag then Library.Flags[flag] = col end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -36, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or o.name or "Color"
                nl.Parent = r
                local sw = Instance.new("Frame")
                sw.AnchorPoint = Vector2.new(1, 0.5)
                sw.Position = UDim2.new(1, 0, 0.5, 0)
                sw.Size = UDim2.fromOffset(28, 16)
                sw.BackgroundColor3 = col
                sw.BorderSizePixel = 0
                sw.Parent = r
                corner(sw, 3)
                stroke(sw, Library.Theme.Stroke, 1)
                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.fromScale(1, 1)
                hit.Text = ""
                hit.ZIndex = 3
                hit.AutoButtonColor = false
                hit.Parent = r
                conn(hit.MouseButton1Click, function()
                    -- cycle simple accent presets for reliability without bloated picker UI
                    local presets = {
                        Color3.fromRGB(245, 93, 97),
                        Color3.fromRGB(80, 160, 255),
                        Color3.fromRGB(120, 255, 140),
                        Color3.fromRGB(255, 190, 70),
                        Color3.fromRGB(180, 120, 255),
                        Color3.fromRGB(255, 255, 255),
                    }
                    local idx = 1
                    for i, c in ipairs(presets) do
                        if math.abs(c.R - col.R) < 0.02 and math.abs(c.G - col.G) < 0.02 and math.abs(c.B - col.B) < 0.02 then
                            idx = i % #presets + 1
                            break
                        end
                    end
                    col = presets[idx]
                    sw.BackgroundColor3 = col
                    if flag then Library.Flags[flag] = col end
                    if o.Callback then task.spawn(o.Callback, col) end
                end)
                if flag then
                    Library._configHandlers[flag] = {
                        Set = function(v)
                            if typeof(v) == "Color3" then
                                col = v
                                sw.BackgroundColor3 = col
                            end
                        end,
                        Get = function() return col end,
                        Type = "color",
                    }
                end
                return {
                    Set = function(c)
                        if typeof(c) == "Color3" then
                            col = c
                            sw.BackgroundColor3 = c
                        end
                    end,
                    Get = function() return col end,
                    Root = r,
                }
            end

            return Section
        end

        return Tab
    end

    Window.Unload = function(self)
        Library.Unloaded = true
        for _, c in ipairs(Library.Connections) do
            pcall(function() c:Disconnect() end)
        end
        pcall(function() gui:Destroy() end)
        pcall(function()
            local n = hui():FindFirstChild("DestNotifs")
            if n then n:Destroy() end
            local p = hui():FindFirstChild("DestColorPicker")
            if p then p:Destroy() end
        end)
    end

    Window.SaveConfig = function(self, name)
        name = name or "default"
        ensureDir()
        pcall(function()
            writefile(Library.Directory .. "/configs/" .. name .. ".json", HS:JSONEncode(serializeFlags()))
        end)
        Library:Notify({ Title = "Config", Content = "Saved " .. name })
        if Library._refreshConfigList then pcall(Library._refreshConfigList) end
    end

    Window.LoadConfig = function(self, name)
        name = name or "default"
        local ok, data = pcall(function()
            return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. name .. ".json"))
        end)
        if ok and type(data) == "table" then
            deserializeFlags(data)
            Library:Notify({ Title = "Config", Content = "Loaded " .. name })
        else
            Library:Notify({ Title = "Config", Content = "Load failed" })
        end
    end

    Window.BuildConfigPage = function(self, tab, opts)
        return Library:BuildConfigPage(tab, opts)
    end

    -- smooth drag on main frame
    do
        local dragging, startMouse, startPos, targetPos
        local dragConn
        conn(main.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            dragging = true
            startMouse = Vector2.new(input.Position.X, input.Position.Y)
            startPos = main.Position
            targetPos = startPos
            if dragConn then dragConn:Disconnect() end
            dragConn = RS.RenderStepped:Connect(function(dt)
                if not dragging then return end
                local cur = main.Position
                local lx = cur.X.Offset + (targetPos.X.Offset - cur.X.Offset) * math.clamp(dt * 18, 0, 1)
                local ly = cur.Y.Offset + (targetPos.Y.Offset - cur.Y.Offset) * math.clamp(dt * 18, 0, 1)
                main.Position = UDim2.new(cur.X.Scale, lx, cur.Y.Scale, ly)
            end)
            table.insert(Library.Connections, dragConn)
        end)
        conn(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    if targetPos then
                        tween(main, { Position = targetPos }, 0.18, Enum.EasingStyle.Quint)
                    end
                end
            end
        end)
        conn(UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local d = Vector2.new(input.Position.X, input.Position.Y) - startMouse
            targetPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + d.X,
                startPos.Y.Scale,
                startPos.Y.Offset + d.Y
            )
        end)
    end

    local menuKey = opts.Keybind or Library.MenuKey or Enum.KeyCode.LeftAlt
    Library.Open = true
    conn(UIS.InputBegan, function(input, gp)
        if gp or Library.Unloaded then return end
        if input.KeyCode == menuKey then
            Library.Open = not Library.Open
            if Library.Open then
                main.Visible = true
                main.BackgroundTransparency = 1
                tween(main, { BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Quint)
            else
                tween(main, { BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quint)
                task.delay(0.22, function()
                    if not Library.Open then
                        main.Visible = false
                        main.BackgroundTransparency = 0
                    end
                end)
            end
        end
    end)

    Library:Notify({
        Title = opts.Name or "Destruction",
        Content = "Ready · " .. (menuKey.Name or "LeftAlt") .. " toggles",
        Duration = 3,
    })
    return Window
end

function Library:Watermark(opts)
    opts = opts or {}
    local api = {
        _visible = true,
        SetVisible = function(self, v)
            self._visible = v ~= false
            if Library._wmFrame then
                Library._wmFrame.Visible = self._visible
            end
        end,
        SetText = function(self, t)
            if not Library._wmFrame then return end
            for _, d in ipairs(Library._wmFrame:GetDescendants()) do
                if d:IsA("TextLabel") and (d.Text:find("FPS") or d.Text:find("fps") or d.Text == "") then
                    -- leave live labels alone
                end
            end
        end,
    }
    if Library._wmFrame then
        Library._wmFrame.Visible = true
    end
    return api
end

----------------------------------------------------------------
-- Keybind list (floating panel, matches shell chrome)
----------------------------------------------------------------
function Library:KeybindList(opts)
    opts = opts or {}
    if Library._keybindListUI and Library._keybindListUI.Gui and Library._keybindListUI.Gui.Parent then
        return Library._keybindListUI
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "DestKeybinds"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 4000
    sg.Parent = hui()

    local panel = Instance.new("Frame")
    panel.Name = "KeybindList"
    panel.BackgroundColor3 = Library.Theme.Background
    panel.BorderSizePixel = 0
    panel.AnchorPoint = Vector2.new(0, 0.5)
    panel.Position = UDim2.new(0, 16, 0.5, 0)
    panel.Size = UDim2.fromOffset(200, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Parent = sg
    corner(panel, 10)
    stroke(panel, Library.Theme.Stroke, 1)
    pad(panel, 10, 10, 12, 12)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 18)
    title.FontFace = FONT
    title.TextSize = 13
    title.TextColor3 = Library.Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = opts.Title or "Keybinds"
    title.Parent = panel

    local list = Instance.new("Frame")
    list.BackgroundTransparency = 1
    list.Position = UDim2.fromOffset(0, 24)
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.Parent = panel
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = list

    local rows = {} -- id -> { frame, nameL, keyL }

    local function upsert(id, name, key, mode, active)
        id = tostring(id or name)
        local row = rows[id]
        if not row then
            local f = Instance.new("Frame")
            f.BackgroundTransparency = 1
            f.Size = UDim2.new(1, 0, 0, 18)
            f.Parent = list
            local n = Instance.new("TextLabel")
            n.BackgroundTransparency = 1
            n.Size = UDim2.new(1, -64, 1, 0)
            n.FontFace = FONT_MED
            n.TextSize = 12
            n.TextColor3 = Library.Theme.Dim
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.TextTruncate = Enum.TextTruncate.AtEnd
            n.Parent = f
            local k = Instance.new("TextLabel")
            k.BackgroundTransparency = 1
            k.AnchorPoint = Vector2.new(1, 0)
            k.Position = UDim2.new(1, 0, 0, 0)
            k.Size = UDim2.fromOffset(60, 18)
            k.FontFace = FONT
            k.TextSize = 12
            k.TextColor3 = Library.Theme.Text
            k.TextXAlignment = Enum.TextXAlignment.Right
            k.Parent = f
            row = { frame = f, nameL = n, keyL = k }
            rows[id] = row
        end
        row.nameL.Text = tostring(name or id)
        local keyName = (typeof(key) == "EnumItem" and key.Name) or tostring(key or "NONE")
        row.keyL.Text = keyName
        if active then
            row.keyL.TextColor3 = Library.Theme.Accent
            row.nameL.TextColor3 = Library.Theme.Text
        else
            row.keyL.TextColor3 = Library.Theme.Text
            row.nameL.TextColor3 = Library.Theme.Dim
        end
        Library.Keybinds[id] = { Name = name, Key = key, Mode = mode, Active = active }
    end

    local function setActive(id, active)
        id = tostring(id)
        local row = rows[id]
        if not row then return end
        if active then
            row.keyL.TextColor3 = Library.Theme.Accent
            row.nameL.TextColor3 = Library.Theme.Text
        else
            row.keyL.TextColor3 = Library.Theme.Text
            row.nameL.TextColor3 = Library.Theme.Dim
        end
        if Library.Keybinds[id] then
            Library.Keybinds[id].Active = active
        end
    end

    -- smooth drag
    do
        local dragging, start, startPos, target
        conn(panel.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            start = Vector2.new(input.Position.X, input.Position.Y)
            startPos = panel.Position
            target = startPos
        end)
        conn(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    tween(panel, { Position = target }, 0.15, Enum.EasingStyle.Quint)
                end
            end
        end)
        conn(UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = Vector2.new(input.Position.X, input.Position.Y) - start
            target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            local cur = panel.Position
            panel.Position = UDim2.new(cur.X.Scale, cur.X.Offset + (target.X.Offset - cur.X.Offset) * 0.35, cur.Y.Scale, cur.Y.Offset + (target.Y.Offset - cur.Y.Offset) * 0.35)
        end)
    end

    -- open anim
    panel.BackgroundTransparency = 1
    tween(panel, { BackgroundTransparency = 0 }, 0.25, Enum.EasingStyle.Quint)

    local api = {
        Gui = sg,
        Panel = panel,
        Upsert = upsert,
        SetActive = setActive,
        Add = function(_, name, key, mode)
            upsert(name, name, key, mode or "Toggle", false)
        end,
        Set = function(_, id, key)
            local kb = Library.Keybinds[id]
            if kb then upsert(id, kb.Name, key, kb.Mode, kb.Active) end
        end,
        Refresh = function()
            for id, kb in pairs(Library.Keybinds) do
                local key = kb.Key
                local keyName = (typeof(key) == "EnumItem" and key.Name) or tostring(key or "None")
                upsert(id, kb.Name or id, keyName, kb.Mode or "Toggle", kb.Active)
            end
        end,
        SetVisible = function(_, v)
            panel.Visible = v ~= false
            if v then
                panel.BackgroundTransparency = 1
                tween(panel, { BackgroundTransparency = 0 }, 0.2)
            end
        end,
        Clear = function()
            for id, row in pairs(rows) do
                row.frame:Destroy()
                rows[id] = nil
            end
            Library.Keybinds = {}
        end,
    }
    Library._keybindListUI = api
    -- initial populate
    api.Refresh()
    return api
end

----------------------------------------------------------------
-- Full config page builder (attach to a Tab)
----------------------------------------------------------------
function Library:BuildConfigPage(tab, opts)
    opts = opts or {}
    if not tab or not tab.Section then
        warn("[Destruction] BuildConfigPage needs a Tab")
        return
    end

    local left = tab:Section({ Name = opts.LeftName or "Configs", Side = "Left" })
    local right = tab:Section({ Name = opts.RightName or "Management", Side = "Right" })

    local selected = { name = "default" }
    local statusLabel

    local nameBox = left:Textbox({
        Name = "Config name",
        Flag = "__cfg_name",
        Default = "default",
        Placeholder = "my config",
        Callback = function(t)
            selected.name = t ~= "" and t or "default"
        end,
    })

    left:Button({
        Name = "Save config",
        Callback = function()
            local n = Library.Flags.__cfg_name or selected.name or "default"
            selected.name = n
            ensureDir()
            pcall(function()
                writefile(Library.Directory .. "/configs/" .. n .. ".json", HS:JSONEncode(serializeFlags()))
            end)
            Library:Notify({ Title = "Config", Content = "Saved \"" .. n .. "\"" })
            if Library._refreshConfigList then Library._refreshConfigList() end
        end,
    })

    left:Button({
        Name = "Load config",
        Callback = function()
            local n = Library.Flags.__cfg_name or selected.name or "default"
            local ok, data = pcall(function()
                return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. n .. ".json"))
            end)
            if ok and type(data) == "table" then
                deserializeFlags(data)
                Library:Notify({ Title = "Config", Content = "Loaded \"" .. n .. "\"" })
            else
                Library:Notify({ Title = "Config", Content = "Could not load \"" .. n .. "\"" })
            end
        end,
    })

    left:Button({
        Name = "Delete config",
        Callback = function()
            local n = Library.Flags.__cfg_name or selected.name or "default"
            local ok = pcall(function()
                delfile(Library.Directory .. "/configs/" .. n .. ".json")
            end)
            Library:Notify({ Title = "Config", Content = ok and ("Deleted \"" .. n .. "\"") or "Delete failed" })
            if Library._refreshConfigList then Library._refreshConfigList() end
        end,
    })

    left:Button({
        Name = "Refresh list",
        Callback = function()
            if Library._refreshConfigList then Library._refreshConfigList() end
            Library:Notify({ Title = "Config", Content = "List refreshed" })
        end,
    })

    -- Right: listed configs as buttons
    right:Label({ Text = "Saved configs appear below" })

    local listRows = {}
    local function clearList()
        for _, r in ipairs(listRows) do
            pcall(function()
                if type(r) == "table" and r.Root then
                    r.Root:Destroy()
                elseif typeof(r) == "Instance" then
                    r:Destroy()
                end
            end)
        end
        listRows = {}
    end

    local function refresh()
        clearList()
        local names = listConfigFiles()
        if #names == 0 then
            table.insert(listRows, right:Label({ Text = "(no configs yet)" }))
            return
        end
        for _, n in ipairs(names) do
            local btn = right:Button({
                Name = n,
                Callback = function()
                    selected.name = n
                    Library.Flags.__cfg_name = n
                    local ok, data = pcall(function()
                        return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. n .. ".json"))
                    end)
                    if ok and type(data) == "table" then
                        deserializeFlags(data)
                        Library:Notify({ Title = "Config", Content = "Loaded " .. tostring(n) })
                    else
                        Library:Notify({ Title = "Config", Content = "Failed to load " .. tostring(n) })
                    end
                end,
            })
            table.insert(listRows, btn)
        end
    end
    Library._refreshConfigList = refresh
    task.defer(refresh)

    right:Button({
        Name = "Set as autoload",
        Callback = function()
            local n = Library.Flags.__cfg_name or selected.name or "default"
            pcall(function()
                ensureDir()
                writefile(Library.Directory .. "/autoload.txt", n)
            end)
            Library:Notify({ Title = "Config", Content = "Autoload → " .. n })
        end,
    })

    right:Button({
        Name = "Clear autoload",
        Callback = function()
            pcall(function() delfile(Library.Directory .. "/autoload.txt") end)
            Library:Notify({ Title = "Config", Content = "Autoload cleared" })
        end,
    })

    -- try autoload once
    task.spawn(function()
        local ok, name = pcall(function()
            return readfile(Library.Directory .. "/autoload.txt")
        end)
        if ok and type(name) == "string" and name ~= "" then
            name = name:gsub("%s+$", "")
            local ok2, data = pcall(function()
                return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. name .. ".json"))
            end)
            if ok2 and type(data) == "table" then
                task.wait(0.35)
                deserializeFlags(data)
                Library.Flags.__cfg_name = name
                Library:Notify({ Title = "Config", Content = "Autoloaded \"" .. name .. "\"", Duration = 2.5 })
            end
        end
    end)

    return { Refresh = refresh }
end

getgenv().Destruction = Library
return Library

