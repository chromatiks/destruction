--[[
  Destruction UI — polished shell library
  exact_clone_open.lua beside this file, or HttpGet from repo.
  v3.1 — animations, smooth drag, real colorpicker, better notifs
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
    Version = "3.1.0",
    MenuKey = Enum.KeyCode.LeftAlt,
    Theme = {
        Accent = Color3.fromRGB(245, 93, 97),
        Background = Color3.fromRGB(17, 17, 22),
        Surface = Color3.fromRGB(20, 20, 26),
        Surface2 = Color3.fromRGB(27, 27, 35),
        Text = Color3.fromRGB(255, 255, 255),
        Dim = Color3.fromRGB(140, 140, 150),
        Stroke = Color3.fromRGB(33, 33, 38),
    },
}

local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_MED = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

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

    local function fadeContent(out, cb)
        local targets = { leftScroll, rightScroll }
        for _, sc in ipairs(targets) do
            if out then
                tween(sc, { ScrollBarImageTransparency = 1 }, 0.12)
                for _, ch in ipairs(sc:GetChildren()) do
                    if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                        tween(ch, { BackgroundTransparency = 1 }, 0.12)
                        for _, d in ipairs(ch:GetDescendants()) do
                            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                                pcall(function() tween(d, { TextTransparency = 1 }, 0.1) end)
                            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                                pcall(function() tween(d, { ImageTransparency = 1 }, 0.1) end)
                            elseif d:IsA("Frame") then
                                pcall(function()
                                    if d.BackgroundTransparency < 1 then
                                        tween(d, { BackgroundTransparency = 1 }, 0.1)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.delay(out and 0.14 or 0, function()
            if cb then cb() end
            if not out then return end
            -- fade back in after tab switch
            for _, sc in ipairs(targets) do
                tween(sc, { ScrollBarImageTransparency = 0 }, 0.2)
                for _, ch in ipairs(sc:GetChildren()) do
                    if ch:IsA("GuiObject") and ch.Visible and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                        -- restore: re-show by resetting transparencies carefully
                        for _, d in ipairs(ch:GetDescendants()) do
                            if d:IsA("TextLabel") or d:IsA("TextButton") then
                                pcall(function()
                                    d.TextTransparency = 1
                                    tween(d, { TextTransparency = 0 }, 0.22)
                                end)
                            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                                pcall(function()
                                    if d.ImageTransparency < 1 then
                                        local goal = d.ImageTransparency
                                        d.ImageTransparency = 1
                                        tween(d, { ImageTransparency = goal }, 0.22)
                                    else
                                        d.ImageTransparency = 1
                                        tween(d, { ImageTransparency = 0 }, 0.22)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end

    local function selectTab(i)
        if switching or current == i then return end
        switching = true
        local prev = current
        current = i

        for idx, fr in ipairs(tabFrames) do
            if fr then
                local on = idx == i
                tween(fr, {
                    BackgroundColor3 = on and Library.Theme.Surface2 or Library.Theme.Surface,
                }, 0.22, Enum.EasingStyle.Quint)
                if tabIcons[idx] then
                    tween(tabIcons[idx], {
                        ImageColor3 = on and Library.Theme.Accent or Library.Theme.Dim,
                    }, 0.22, Enum.EasingStyle.Quint)
                end
            end
        end

        fadeContent(true, function()
            for ti, list in pairs(tabSections) do
                for _, sec in ipairs(list) do
                    if sec and sec.Root then
                        sec.Root.Visible = (ti == i)
                    end
                end
            end
            if tabs[i] then
                titleL.Text = tabs[i].Name or titleL.Text
                if tabs[i].Subtitle then
                    subL.Text = tabs[i].Subtitle
                end
                titleL.TextTransparency = 1
                subL.TextTransparency = 1
                tween(titleL, { TextTransparency = 0 }, 0.25)
                tween(subL, { TextTransparency = 0 }, 0.28)
            end
            fadeContent(false)
            switching = false
        end)
    end

    for i, btn in ipairs(tabButtons) do
        if btn then
            conn(btn.MouseButton1Click, function()
                selectTab(i)
            end)
            -- hover
            conn(btn.MouseEnter, function()
                if current ~= i and tabFrames[i] then
                    tween(tabFrames[i], { BackgroundColor3 = Color3.fromRGB(24, 24, 30) }, 0.15)
                end
            end)
            conn(btn.MouseLeave, function()
                if current ~= i and tabFrames[i] then
                    tween(tabFrames[i], { BackgroundColor3 = Library.Theme.Surface }, 0.15)
                end
            end)
        end
    end

    ----------------------------------------------------------------
    -- Smooth drag (lerp-smoothed)
    ----------------------------------------------------------------
    do
        local dragging = false
        local startMouse = Vector2.zero
        local startPos = UDim2.new()
        local targetPos = UDim2.new()
        local dragConn

        conn(main.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local rel = input.Position.Y - main.AbsolutePosition.Y
            if rel > 56 then return end
            dragging = true
            startMouse = Vector2.new(input.Position.X, input.Position.Y)
            startPos = main.Position
            targetPos = startPos
            if dragConn then dragConn:Disconnect() end
            dragConn = RS.RenderStepped:Connect(function(dt)
                if not dragging then return end
                -- smooth follow
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
                    -- settle
                    tween(main, { Position = targetPos }, 0.18, Enum.EasingStyle.Quint)
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

    local menuKey = opts.Keybind or Library.MenuKey
    conn(UIS.InputBegan, function(input, gp)
        if gp or Library.Unloaded then return end
        if input.KeyCode == menuKey then
            Library.Open = not Library.Open
            if Library.Open then
                main.Visible = true
                main.BackgroundTransparency = 1
                main.Size = main.Size
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

    local Window = { Shell = a, Main = main, Gui = gui }
    local tabCount = 0

    function Window:Tab(t)
        t = t or {}
        tabCount += 1
        local idx = tabCount
        tabs[idx] = { Name = t.Name or ("Tab " .. idx), Subtitle = t.Subtitle or t.Description }
        tabSections[idx] = {}

        if tabIcons[idx] and t.Icon then
            local icon = tostring(t.Icon):gsub("rbxassetid://", "")
            tabIcons[idx].Image = "rbxassetid://" .. icon
        end
        if tabFrames[idx] then
            tabFrames[idx].Visible = true
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

            local root = Instance.new("Frame")
            root.BackgroundTransparency = 1
            root.Size = UDim2.new(1, -4, 0, 0)
            root.AutomaticSize = Enum.AutomaticSize.Y
            root.Visible = (current == idx) or (current == nil and idx == 1)
            root.Parent = parent
            table.insert(tabSections[idx], { Root = root })

            local head = Instance.new("TextLabel")
            head.BackgroundTransparency = 1
            head.Size = UDim2.new(1, 0, 0, 18)
            head.FontFace = FONT
            head.TextSize = 13
            head.TextColor3 = Library.Theme.Text
            head.TextXAlignment = Enum.TextXAlignment.Left
            head.Text = s.Name or "Section"
            head.Parent = root

            local body = Instance.new("Frame")
            body.BackgroundTransparency = 1
            body.Position = UDim2.fromOffset(0, 22)
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Parent = root
            local bl = Instance.new("UIListLayout")
            bl.Padding = UDim.new(0, 8)
            bl.SortOrder = Enum.SortOrder.LayoutOrder
            bl.Parent = body

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
                local flag = o.Flag or o.Name
                local state = o.Default == true
                if flag then Library.Flags[flag] = state end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -48, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.TextYAlignment = Enum.TextYAlignment.Center
                nl.Text = o.Name or "Toggle"
                nl.Parent = r

                local trackF = Instance.new("Frame")
                trackF.AnchorPoint = Vector2.new(1, 0)
                trackF.Position = UDim2.new(1, -2, 0, 3)
                trackF.Size = UDim2.fromOffset(27, 16)
                trackF.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Surface2
                trackF.BorderSizePixel = 0
                trackF.Parent = r
                local tc = Instance.new("UICorner")
                tc.CornerRadius = UDim.new(1, 0)
                tc.Parent = trackF

                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(10, 10)
                knob.Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.Parent = trackF
                local kc = Instance.new("UICorner")
                kc.CornerRadius = UDim.new(1, 0)
                kc.Parent = knob

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.fromScale(1, 1)
                hit.Text = ""
                hit.Parent = r

                local function set(v, silent)
                    state = not not v
                    if flag then Library.Flags[flag] = state end
                    tween(trackF, {
                        BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Surface2,
                    }, 0.18, Enum.EasingStyle.Quint)
                    tween(knob, {
                        Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3),
                    }, 0.2, Enum.EasingStyle.Quint)
                    if not silent and o.Callback then task.spawn(o.Callback, state) end
                end
                conn(hit.MouseButton1Click, function() set(not state) end)

                local api = { Set = set, Get = function() return state end }

                function api:Extra()
                    local gear = Instance.new("ImageButton")
                    gear.BackgroundTransparency = 1
                    gear.AnchorPoint = Vector2.new(1, 0.5)
                    gear.Position = UDim2.new(1, -36, 0.5, 0)
                    gear.Size = UDim2.fromOffset(14, 14)
                    gear.Image = "rbxassetid://123677974615593"
                    gear.ImageColor3 = Library.Theme.Dim
                    gear.Parent = r
                    nl.Size = UDim2.new(1, -70, 1, 0)
                    local open = false
                    local panel = Instance.new("Frame")
                    panel.BackgroundColor3 = Library.Theme.Surface
                    panel.BorderSizePixel = 0
                    panel.Size = UDim2.new(1, 0, 0, 0)
                    panel.AutomaticSize = Enum.AutomaticSize.Y
                    panel.Visible = false
                    panel.BackgroundTransparency = 1
                    panel.ClipsDescendants = true
                    panel.Parent = body
                    corner(panel, 6)
                    pad(panel, 8, 8, 10, 10)
                    local pl = Instance.new("UIListLayout")
                    pl.Padding = UDim.new(0, 6)
                    pl.Parent = panel
                    conn(gear.MouseButton1Click, function()
                        open = not open
                        if open then
                            panel.Visible = true
                            panel.BackgroundTransparency = 1
                            tween(panel, { BackgroundTransparency = 0 }, 0.2)
                        else
                            tween(panel, { BackgroundTransparency = 1 }, 0.15)
                            task.delay(0.16, function()
                                if not open then panel.Visible = false end
                            end)
                        end
                        tween(gear, {
                            ImageColor3 = open and Library.Theme.Accent or Library.Theme.Dim,
                            Rotation = open and 90 or 0,
                        }, 0.2, Enum.EasingStyle.Quint)
                    end)
                    return {
                        Toggle = function(_, eo)
                            eo = eo or {}
                            local er = Instance.new("Frame")
                            er.BackgroundTransparency = 1
                            er.Size = UDim2.new(1, 0, 0, 20)
                            er.Parent = panel
                            local en = Instance.new("TextLabel")
                            en.BackgroundTransparency = 1
                            en.Size = UDim2.new(1, -36, 1, 0)
                            en.FontFace = FONT
                            en.TextSize = 12
                            en.TextColor3 = Library.Theme.Text
                            en.TextXAlignment = Enum.TextXAlignment.Left
                            en.Text = eo.Name or "Option"
                            en.Parent = er
                            local st = eo.Default == true
                            local tr = Instance.new("Frame")
                            tr.AnchorPoint = Vector2.new(1, 0.5)
                            tr.Position = UDim2.new(1, 0, 0.5, 0)
                            tr.Size = UDim2.fromOffset(24, 14)
                            tr.BackgroundColor3 = st and Library.Theme.Accent or Library.Theme.Surface2
                            tr.BorderSizePixel = 0
                            tr.Parent = er
                            local trc = Instance.new("UICorner")
                            trc.CornerRadius = UDim.new(1, 0)
                            trc.Parent = tr
                            local kn = Instance.new("Frame")
                            kn.Size = UDim2.fromOffset(8, 8)
                            kn.Position = st and UDim2.fromOffset(14, 3) or UDim2.fromOffset(2, 3)
                            kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            kn.BorderSizePixel = 0
                            kn.Parent = tr
                            local knc = Instance.new("UICorner")
                            knc.CornerRadius = UDim.new(1, 0)
                            knc.Parent = kn
                            local hb = Instance.new("TextButton")
                            hb.BackgroundTransparency = 1
                            hb.Size = UDim2.fromScale(1, 1)
                            hb.Text = ""
                            hb.Parent = er
                            if eo.Flag then Library.Flags[eo.Flag] = st end
                            conn(hb.MouseButton1Click, function()
                                st = not st
                                if eo.Flag then Library.Flags[eo.Flag] = st end
                                tween(tr, {
                                    BackgroundColor3 = st and Library.Theme.Accent or Library.Theme.Surface2,
                                }, 0.15)
                                tween(kn, {
                                    Position = st and UDim2.fromOffset(14, 3) or UDim2.fromOffset(2, 3),
                                }, 0.15)
                                if eo.Callback then task.spawn(eo.Callback, st) end
                            end)
                        end,
                    }
                end
                return api
            end

            function Section:Slider(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local minv, maxv = o.Min or 0, o.Max or 100
                local step = o.Float or o.Increment or 1
                local value = o.Default or minv
                if flag then Library.Flags[flag] = value end
                local wrap = row(40)
                wrap.Size = UDim2.new(1, 0, 0, 40)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -50, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Slider"
                nl.Parent = wrap
                local vl = Instance.new("TextLabel")
                vl.BackgroundTransparency = 1
                vl.AnchorPoint = Vector2.new(1, 0)
                vl.Position = UDim2.new(1, 0, 0, 0)
                vl.Size = UDim2.fromOffset(48, 16)
                vl.FontFace = FONT
                vl.TextSize = 12
                vl.TextColor3 = Library.Theme.Dim
                vl.TextXAlignment = Enum.TextXAlignment.Right
                vl.Parent = wrap
                local trackB = Instance.new("Frame")
                trackB.BackgroundColor3 = Library.Theme.Surface2
                trackB.BorderSizePixel = 0
                trackB.Position = UDim2.fromOffset(0, 24)
                trackB.Size = UDim2.new(1, 0, 0, 6)
                trackB.Parent = wrap
                corner(trackB, 3)
                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Library.Theme.Accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.Parent = trackB
                corner(fill, 3)
                local function set(v, silent)
                    v = math.clamp(tonumber(v) or minv, minv, maxv)
                    if step >= 1 then
                        v = math.floor(v / step + 0.5) * step
                    else
                        v = math.floor(v / step + 0.5) * step
                    end
                    value = v
                    if flag then Library.Flags[flag] = value end
                    local alpha = (value - minv) / math.max(maxv - minv, 1e-9)
                    tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.12, Enum.EasingStyle.Quad)
                    vl.Text = tostring(value) .. (o.Suffix or "")
                    if not silent and o.Callback then task.spawn(o.Callback, value) end
                end
                local sliding = false
                conn(trackB.InputBegan, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                        or i.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                    end
                end)
                conn(UIS.InputEnded, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                        or i.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                conn(UIS.InputChanged, function(i)
                    if not sliding then return end
                    if i.UserInputType ~= Enum.UserInputType.MouseMovement
                        and i.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    local rel = (i.Position.X - trackB.AbsolutePosition.X) / math.max(trackB.AbsoluteSize.X, 1)
                    set(minv + rel * (maxv - minv))
                end)
                set(value, true)
                return { Set = set, Get = function() return value end }
            end

            function Section:Dropdown(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local items = o.Values or o.Items or o.Options or {}
                local cur = o.Default or items[1]
                if flag then Library.Flags[flag] = cur end
                local wrap = row(44)
                wrap.Size = UDim2.new(1, 0, 0, 44)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, 0, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Dropdown"
                nl.Parent = wrap
                local box = Instance.new("TextButton")
                box.AutoButtonColor = false
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 20)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.FontFace = FONT
                box.TextSize = 13
                box.TextColor3 = Library.Theme.Text
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Text = "  " .. tostring(cur or "Select")
                box.Parent = wrap
                corner(box, 4)
                local idx = 1
                for i, v in ipairs(items) do
                    if v == cur then idx = i break end
                end
                conn(box.MouseButton1Click, function()
                    if #items == 0 then return end
                    idx = idx % #items + 1
                    cur = items[idx]
                    box.Text = "  " .. tostring(cur)
                    tween(box, { BackgroundColor3 = Library.Theme.Accent }, 0.08)
                    task.delay(0.1, function()
                        tween(box, { BackgroundColor3 = Library.Theme.Surface2 }, 0.2)
                    end)
                    if flag then Library.Flags[flag] = cur end
                    if o.Callback then task.spawn(o.Callback, cur) end
                end)
                return {
                    Set = function(v)
                        cur = v
                        box.Text = "  " .. tostring(v)
                    end,
                    Get = function() return cur end,
                }
            end

            function Section:Button(o)
                o = o or {}
                local r = row(30)
                r.Size = UDim2.new(1, 0, 0, 30)
                local b = Instance.new("TextButton")
                b.AutoButtonColor = false
                b.BackgroundColor3 = Library.Theme.Surface2
                b.BorderSizePixel = 0
                b.Size = UDim2.fromScale(1, 1)
                b.FontFace = FONT
                b.TextSize = 13
                b.TextColor3 = Library.Theme.Text
                b.Text = o.Name or "Button"
                b.Parent = r
                corner(b, 4)
                conn(b.MouseEnter, function()
                    tween(b, { BackgroundColor3 = Color3.fromRGB(34, 34, 42) }, 0.12)
                end)
                conn(b.MouseLeave, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Surface2 }, 0.12)
                end)
                conn(b.MouseButton1Click, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Accent }, 0.08)
                    task.delay(0.12, function()
                        tween(b, { BackgroundColor3 = Library.Theme.Surface2 }, 0.2)
                    end)
                    if o.Callback then task.spawn(o.Callback) end
                end)
            end

            function Section:Textbox(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local text = o.Default or ""
                if flag then Library.Flags[flag] = text end
                local wrap = row(44)
                wrap.Size = UDim2.new(1, 0, 0, 44)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, 0, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Text"
                nl.Parent = wrap
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 20)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.FontFace = FONT
                box.TextSize = 13
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
                box.PlaceholderText = o.Placeholder or ""
                box.Text = text
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = wrap
                corner(box, 4)
                pad(box, 0, 0, 10, 0)
                conn(box.Focused, function()
                    tween(box, { BackgroundColor3 = Color3.fromRGB(32, 32, 40) }, 0.12)
                end)
                conn(box.FocusLost, function()
                    tween(box, { BackgroundColor3 = Library.Theme.Surface2 }, 0.12)
                    text = box.Text
                    if flag then Library.Flags[flag] = text end
                    if o.Callback then task.spawn(o.Callback, text) end
                end)
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
            end

            function Section:Keybind(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local key = o.Default or Enum.KeyCode.Unknown
                if flag then Library.Flags[flag] = key end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -88, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Keybind"
                nl.Parent = r
                local b = Instance.new("TextButton")
                b.AutoButtonColor = false
                b.BackgroundColor3 = Library.Theme.Surface2
                b.BorderSizePixel = 0
                b.AnchorPoint = Vector2.new(1, 0.5)
                b.Position = UDim2.new(1, 0, 0.5, 0)
                b.Size = UDim2.fromOffset(78, 20)
                b.FontFace = FONT
                b.TextSize = 12
                b.TextColor3 = Library.Theme.Dim
                b.Text = (key and key.Name) or "NONE"
                b.Parent = r
                corner(b, 4)
                local listening = false
                conn(b.MouseButton1Click, function()
                    listening = true
                    b.Text = "..."
                    tween(b, { TextColor3 = Library.Theme.Accent, BackgroundColor3 = Color3.fromRGB(34, 34, 42) }, 0.12)
                end)
                conn(UIS.InputBegan, function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        b.Text = key.Name
                        tween(b, { TextColor3 = Library.Theme.Dim, BackgroundColor3 = Library.Theme.Surface2 }, 0.15)
                        listening = false
                        if flag then Library.Flags[flag] = key end
                        if o.Callback then task.spawn(o.Callback, key) end
                    end
                end)
                return { Get = function() return key end }
            end

            function Section:Colorpicker(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local col = o.Default or Library.Theme.Accent
                if flag then Library.Flags[flag] = col end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -28, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Color"
                nl.Parent = r
                local sw = Instance.new("TextButton")
                sw.AutoButtonColor = false
                sw.BackgroundColor3 = col
                sw.BorderSizePixel = 0
                sw.AnchorPoint = Vector2.new(1, 0.5)
                sw.Position = UDim2.new(1, 0, 0.5, 0)
                sw.Size = UDim2.fromOffset(18, 18)
                sw.Text = ""
                sw.Parent = r
                corner(sw, 4)
                stroke(sw, Color3.fromRGB(0, 0, 0), 1)

                conn(sw.MouseButton1Click, function()
                    openColorPicker(sw, col, function(c)
                        col = c
                        tween(sw, { BackgroundColor3 = c }, 0.12)
                        if flag then Library.Flags[flag] = c end
                        if o.GlobalAccent then
                            Library.Theme.Accent = c
                        end
                        if o.Callback then task.spawn(o.Callback, c) end
                    end)
                end)

                return {
                    Set = function(c)
                        col = c
                        sw.BackgroundColor3 = c
                    end,
                    Get = function()
                        return col
                    end,
                }
            end

            return Section
        end

        return Tab
    end

    function Window:Unload()
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

    function Window:SaveConfig(name)
        name = name or "default"
        pcall(function()
            if makefolder then makefolder(Library.Directory .. "/configs") end
            -- Color3 is not JSON-safe — store as table
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
            writefile(Library.Directory .. "/configs/" .. name .. ".json", HS:JSONEncode(payload))
        end)
        Library:Notify({ Title = "Config", Content = "Saved " .. name })
    end

    function Window:LoadConfig(name)
        name = name or "default"
        local ok, data = pcall(function()
            return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. name .. ".json"))
        end)
        if ok and type(data) == "table" then
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
            end
            Library:Notify({ Title = "Config", Content = "Loaded " .. name })
        else
            Library:Notify({ Title = "Config", Content = "Load failed" })
        end
    end

    Library:Notify({
        Title = opts.Name or "Destruction",
        Content = "Ready · " .. (menuKey and menuKey.Name or "LeftAlt") .. " toggles",
        Duration = 3,
    })
    return Window
end

function Library:Watermark(opts)
    opts = opts or {}
    return {
        SetVisible = function(_, v)
            -- shell watermark is managed internally
        end,
        SetText = function() end,
    }
end

function Library:KeybindList()
    return {
        SetVisible = function() end,
        Add = function() end,
        Set = function() end,
    }
end

getgenv().Destruction = Library
return Library
