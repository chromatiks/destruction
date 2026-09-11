--[[
  Destruction UI Library
  Visual style: Neptune open-menu clone (714x475, sidebar 80, accent 245,93,97)
  Feature set: Chromatik/Glacier-class (window, tabs, sections, elements, config, watermark, keybinds, notifs)
  Host: https://raw.githubusercontent.com/chromatiks/destruction/refs/heads/main/library.lua
]]

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

local Library = {
    Directory = "Destruction",
    Flags = {},
    ConfigFlags = {},
    Connections = {},
    Windows = {},
    Open = true,
    Unloaded = false,
    Version = "2.0.0",
    MenuKey = Enum.KeyCode.LeftAlt,
    Theme = {
        Accent = Color3.fromRGB(245, 93, 97),
        Background = Color3.fromRGB(17, 17, 22),
        Surface = Color3.fromRGB(20, 20, 26),
        Surface2 = Color3.fromRGB(27, 27, 35),
        Elevated = Color3.fromRGB(33, 33, 38),
        Hover = Color3.fromRGB(39, 39, 43),
        Line = Color3.fromRGB(33, 33, 38),
        Text = Color3.fromRGB(255, 255, 255),
        Dim = Color3.fromRGB(103, 103, 126),
        DimIcon = Color3.fromRGB(103, 103, 126),
    },
    _themeObjects = {},
    _toggles = {},
}

Library.__index = Library

local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_REG = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

local function hui()
    local h
    pcall(function() if gethui then h = gethui() end end)
    if typeof(h) == "Instance" then return h end
    return CoreGui
end

local function protect(gui)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    gui.Parent = hui()
end

local function tween(obj, props, t, style, dir)
    local tw = TS:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
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
    s.Color = col or Library.Theme.Line
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function padding(p, t, b, l, r)
    local x = Instance.new("UIPadding")
    x.PaddingTop = UDim.new(0, t or 0)
    x.PaddingBottom = UDim.new(0, b or t or 0)
    x.PaddingLeft = UDim.new(0, l or t or 0)
    x.PaddingRight = UDim.new(0, r or l or t or 0)
    x.Parent = p
    return x
end

local function trackTheme(obj, prop, key)
    key = key or "Accent"
    Library._themeObjects[key] = Library._themeObjects[key] or {}
    table.insert(Library._themeObjects[key], {obj = obj, prop = prop})
end

function Library:SetAccent(c)
    self.Theme.Accent = c
    for _, e in ipairs(self._themeObjects.Accent or {}) do
        pcall(function() e.obj[e.prop] = c end)
    end
end

function Library:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, start, startPos
    conn(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = frame.Position
        end
    end)
    conn(handle.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    conn(UIS.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - start
            local nx = startPos.X.Offset + d.X
            local ny = startPos.Y.Offset + d.Y
            local vs = Camera.ViewportSize
            nx = math.clamp(nx, 0, math.max(0, vs.X - frame.AbsoluteSize.X))
            ny = math.clamp(ny, 0, math.max(0, vs.Y - frame.AbsoluteSize.Y))
            frame.Position = UDim2.fromOffset(nx, ny)
        end
    end)
end

-- folders
pcall(function()
    if makefolder then
        makefolder(Library.Directory)
        makefolder(Library.Directory .. "/configs")
    end
end)

----------------------------------------------------------------
-- Notifications
----------------------------------------------------------------
local notifGui
local function notifHost()
    if notifGui and notifGui.Parent then return notifGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestNotifs"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2000
    protect(sg)
    local h = Instance.new("Frame")
    h.BackgroundTransparency = 1
    h.AnchorPoint = Vector2.new(1, 0)
    h.Position = UDim2.new(1, -14, 0, 14)
    h.Size = UDim2.new(0, 300, 1, -28)
    h.Parent = sg
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = h
    notifGui = h
    return h
end

function Library:Notify(opts)
    if type(opts) ~= "table" then opts = { Title = tostring(opts) } end
    local host = notifHost()
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Library.Theme.Surface2
    f.BorderSizePixel = 0
    f.Size = UDim2.new(0, 280, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = host
    corner(f, 6)
    stroke(f, Library.Theme.Elevated, 1)
    padding(f, 10, 10, 12, 12)
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = Library.Theme.Accent
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.Position = UDim2.fromOffset(-12, -10)
    accent.Parent = f
    corner(accent, 2)
    trackTheme(accent, "BackgroundColor3")
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 16)
    t.FontFace = FONT
    t.TextSize = 13
    t.TextColor3 = Library.Theme.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = opts.Title or "Notification"
    t.Parent = f
    if opts.Content or opts.Description then
        local b = Instance.new("TextLabel")
        b.BackgroundTransparency = 1
        b.Position = UDim2.fromOffset(0, 18)
        b.Size = UDim2.new(1, 0, 0, 0)
        b.AutomaticSize = Enum.AutomaticSize.Y
        b.FontFace = FONT_REG
        b.TextSize = 12
        b.TextColor3 = Library.Theme.Dim
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextWrapped = true
        b.Text = opts.Content or opts.Description
        b.Parent = f
    end
    f.BackgroundTransparency = 1
    tween(f, { BackgroundTransparency = 0 }, 0.18)
    task.delay(opts.Duration or 3.5, function()
        if f.Parent then
            tween(f, { BackgroundTransparency = 1 }, 0.18)
            task.wait(0.2)
            f:Destroy()
        end
    end)
end

----------------------------------------------------------------
-- Watermark (FPS live)
----------------------------------------------------------------
function Library:Watermark(opts)
    opts = type(opts) == "table" and opts or { Text = tostring(opts or "Destruction") }
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestWatermark"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 100
    protect(sg)

    -- exact clone: h=38, bg 17,17,22, top-right, stroke 33,33,38, pad L12 R22
    local f = Instance.new("Frame")
    f.Active = true
    f.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(1, 0)
    f.Position = UDim2.new(1, -15, 0, 12)
    f.Size = UDim2.new(0, 0, 0, 38)
    f.AutomaticSize = Enum.AutomaticSize.X
    f.Parent = sg
    corner(f, 6)
    local st = stroke(f, Color3.fromRGB(33, 33, 38), 1)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 22)
    pad.Parent = f

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = f

    local function chipIcon(asset, order)
        local hold = Instance.new("Frame")
        hold.BackgroundTransparency = 1
        hold.Size = UDim2.fromOffset(0, 38)
        hold.AutomaticSize = Enum.AutomaticSize.X
        hold.LayoutOrder = order
        hold.Parent = f
        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.VerticalAlignment = Enum.VerticalAlignment.Center
        hl.Padding = UDim.new(0, 6)
        hl.Parent = hold
        local ic = Instance.new("ImageLabel")
        ic.BackgroundTransparency = 1
        ic.Size = UDim2.fromOffset(14, 14)
        ic.Image = "rbxassetid://" .. tostring(asset):gsub("rbxassetid://", "")
        ic.ImageColor3 = Color3.fromRGB(255, 255, 255)
        ic.Parent = hold
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.fromOffset(0, 38)
        l.AutomaticSize = Enum.AutomaticSize.X
        l.FontFace = FONT
        l.TextSize = 15
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.Text = ""
        l.Parent = hold
        return l, hold
    end

    -- logo slot
    local logoHold = Instance.new("Frame")
    logoHold.BackgroundTransparency = 1
    logoHold.Size = UDim2.fromOffset(21, 38)
    logoHold.LayoutOrder = 1
    logoHold.Parent = f
    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.fromScale(0.5, 0.5)
    logo.Size = UDim2.fromOffset(16, 16)
    logo.Image = "rbxassetid://" .. tostring(opts.Icon or "81603686073386"):gsub("rbxassetid://", "")
    logo.Parent = logoHold

    -- accent bar 2x38
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Library.Theme.Accent
    bar.BorderSizePixel = 0
    bar.Size = UDim2.fromOffset(2, 38)
    bar.LayoutOrder = 2
    bar.Parent = f
    trackTheme(bar, "BackgroundColor3")

    local nameL = select(1, chipIcon("10723407389", 3))
    nameL.Text = opts.Text or "Destruction"
    local userL = select(1, chipIcon("10723407389", 4))
    userL.Text = LP.Name
    local fpsL = select(1, chipIcon("121808839832144", 5))
    fpsL.Text = "0 FPS"
    local gameL = select(1, chipIcon("92483947987410", 6))
    gameL.Text = "..."

    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        gameL.Text = info.Name or tostring(game.PlaceId)
    end)

    local frames, last = 0, tick()
    conn(RS.RenderStepped, function()
        frames += 1
        local now = tick()
        if now - last >= 1 then
            fpsL.Text = tostring(frames) .. " FPS"
            frames = 0
            last = now
        end
    end)

    -- fade in
    f.BackgroundTransparency = 1
    tween(f, { BackgroundTransparency = 0 }, 0.25)

    Library:MakeDraggable(f)
    return {
        SetText = function(_, t) nameL.Text = t end,
        SetVisible = function(_, v)
            if v then
                f.Visible = true
                f.BackgroundTransparency = 1
                tween(f, { BackgroundTransparency = 0 }, 0.2)
            else
                tween(f, { BackgroundTransparency = 1 }, 0.15)
                task.delay(0.15, function() f.Visible = false end)
            end
        end,
        Gui = sg,
        Frame = f,
    }
end

function Library:KeybindList()
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestKeybinds"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    protect(sg)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Library.Theme.Surface2
    f.BorderSizePixel = 0
    f.Position = UDim2.fromOffset(12, 56)
    f.Size = UDim2.fromOffset(180, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = sg
    corner(f, 6)
    stroke(f, Library.Theme.Elevated, 1)
    padding(f, 8, 8, 10, 10)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 18)
    title.FontFace = FONT
    title.TextSize = 13
    title.TextColor3 = Library.Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Keybinds"
    title.Parent = f

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(0, 22)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = f
    local bl = Instance.new("UIListLayout")
    bl.Padding = UDim.new(0, 4)
    bl.Parent = body

    local rows = {}
    Library:MakeDraggable(f, title)

    local api = {
        Gui = sg,
        SetVisible = function(_, v) f.Visible = v and true or false end,
        Add = function(_, name, keyText)
            local r = Instance.new("TextLabel")
            r.BackgroundTransparency = 1
            r.Size = UDim2.new(1, 0, 0, 16)
            r.FontFace = FONT_REG
            r.TextSize = 12
            r.TextColor3 = Library.Theme.Dim
            r.TextXAlignment = Enum.TextXAlignment.Left
            r.Text = string.format("%s  [%s]", name, keyText or "NONE")
            r.Parent = body
            rows[name] = r
        end,
        Set = function(_, name, keyText)
            if rows[name] then
                rows[name].Text = string.format("%s  [%s]", name, keyText or "NONE")
            end
        end,
        Remove = function(_, name)
            if rows[name] then rows[name]:Destroy() rows[name] = nil end
        end,
    }
    Library.KeybindListInstance = api
    return api
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Library:Window(opts)
    opts = opts or {}
    local title = opts.Name or opts.Title or "Destruction"
    local logoId = tostring(opts.Icon or "81603686073386"):gsub("rbxassetid://", "")

    local screen = Instance.new("ScreenGui")
    screen.Name = "DestWindow"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protect(screen)

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BackgroundColor3 = Library.Theme.Background
    main.BorderSizePixel = 0
    main.Size = UDim2.fromOffset(714, 475)
    main.Position = UDim2.new(0.5, -357, 0.5, -237)
    main.Active = true
    main.ClipsDescendants = true
    main.Parent = screen
    corner(main, 15)

    -- sidebar
    local side = Instance.new("Frame")
    side.BackgroundTransparency = 1
    side.Size = UDim2.new(0, 80, 1, 0)
    side.Parent = main

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(8, 10)
    logo.Size = UDim2.fromOffset(64, 60)
    logo.Image = "rbxassetid://" .. logoId
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = side

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.Position = UDim2.fromOffset(0, 78)
    tabScroll.Size = UDim2.new(1, 0, 1, -90)
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new()
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.Parent = side
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabScroll

    -- content
    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(80, 0)
    content.Size = UDim2.new(1, -80, 1, 0)
    content.ClipsDescendants = true
    content.Parent = main

    local header = Instance.new("Frame")
    header.BackgroundColor3 = Library.Theme.Surface
    header.BorderSizePixel = 0
    header.Position = UDim2.fromOffset(8, 10)
    header.Size = UDim2.new(1, -16, 0, 40)
    header.Parent = content
    corner(header, 6)

    local headerTitle = Instance.new("TextLabel")
    headerTitle.BackgroundTransparency = 1
    headerTitle.Position = UDim2.fromOffset(14, 0)
    headerTitle.Size = UDim2.new(1, -28, 1, 0)
    headerTitle.FontFace = FONT
    headerTitle.TextSize = 14
    headerTitle.TextColor3 = Library.Theme.Text
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Text = title
    headerTitle.Parent = header

    local pages = Instance.new("Frame")
    pages.BackgroundTransparency = 1
    pages.Position = UDim2.fromOffset(8, 58)
    pages.Size = UDim2.new(1, -16, 1, -68)
    pages.ClipsDescendants = true
    pages.Parent = content

    Library:MakeDraggable(main, header)
    -- also allow drag from top of main
    do
        local dragging, start, startPos
        conn(main.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if input.Position.Y - main.AbsolutePosition.Y > 50 then return end
            dragging = true
            start = input.Position
            startPos = main.Position
        end)
        conn(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        conn(UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - start
            main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
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
                tween(main, { BackgroundTransparency = 0 }, 0.22)
            else
                local tw = tween(main, { BackgroundTransparency = 1 }, 0.18)
                task.delay(0.18, function() if not Library.Open then main.Visible = false main.BackgroundTransparency = 0 end end)
            end
        end
    end)

    local Window = { Tabs = {}, Screen = screen, Main = main, Title = title }

    function Window:SetVisible(v)
        main.Visible = v and true or false
        Library.Open = main.Visible
    end

    function Window:Tab(t)
        t = t or {}
        local name = t.Name or "Tab"
        local iconId = tostring(t.Icon or "136634011674328"):gsub("rbxassetid://", "")

        local btn = Instance.new("Frame")
        btn.BackgroundColor3 = Library.Theme.Surface
        btn.BorderSizePixel = 0
        btn.Size = UDim2.fromOffset(50, 50)
        btn.Parent = tabScroll
        corner(btn, 3)

        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Position = UDim2.fromOffset(15, 15)
        img.Size = UDim2.fromOffset(20, 20)
        img.Image = "rbxassetid://" .. iconId
        img.ImageColor3 = Library.Theme.Dim
        img.Parent = btn

        local hit = Instance.new("TextButton")
        hit.BackgroundTransparency = 1
        hit.Size = UDim2.fromScale(1, 1)
        hit.Text = ""
        hit.Parent = btn

        local page = Instance.new("Frame")
        page.BackgroundTransparency = 1
        page.Size = UDim2.fromScale(1, 1)
        page.Visible = false
        page.Parent = pages

        local left = Instance.new("ScrollingFrame")
        left.BackgroundTransparency = 1
        left.BorderSizePixel = 0
        left.Size = UDim2.new(0.5, -6, 1, 0)
        left.ScrollBarThickness = 2
        left.ScrollBarImageColor3 = Library.Theme.Accent
        left.CanvasSize = UDim2.new()
        left.AutomaticCanvasSize = Enum.AutomaticSize.Y
        left.Parent = page
        trackTheme(left, "ScrollBarImageColor3")
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 10)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = left

        local right = Instance.new("ScrollingFrame")
        right.BackgroundTransparency = 1
        right.BorderSizePixel = 0
        right.Position = UDim2.new(0.5, 6, 0, 0)
        right.Size = UDim2.new(0.5, -6, 1, 0)
        right.ScrollBarThickness = 2
        right.ScrollBarImageColor3 = Library.Theme.Accent
        right.CanvasSize = UDim2.new()
        right.AutomaticCanvasSize = Enum.AutomaticSize.Y
        right.Parent = page
        trackTheme(right, "ScrollBarImageColor3")
        local rl = Instance.new("UIListLayout")
        rl.Padding = UDim.new(0, 10)
        rl.SortOrder = Enum.SortOrder.LayoutOrder
        rl.Parent = right

        local Tab = { Name = name, Page = page, Button = btn, Icon = img }

        local function selectTab()
            for _, ot in ipairs(Window.Tabs) do
                ot.Page.Visible = false
                tween(ot.Button, { BackgroundColor3 = Library.Theme.Surface }, 0.15)
                ot.Icon.ImageColor3 = Library.Theme.Dim
            end
            page.Visible = true
            tween(btn, { BackgroundColor3 = Library.Theme.Surface2 }, 0.15)
            img.ImageColor3 = Library.Theme.Accent
            headerTitle.Text = title .. "  ·  " .. name
            page.Position = UDim2.fromOffset(0, 6)
            tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.18)
        end
        conn(hit.MouseButton1Click, selectTab)
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then task.defer(selectTab) end

        function Tab:Section(s)
            s = s or {}
            local parent = (s.Side == "Right" or s.Side == 2) and right or left
            local sec = Instance.new("Frame")
            sec.BackgroundColor3 = Library.Theme.Surface
            sec.BorderSizePixel = 0
            sec.Size = UDim2.new(1, -4, 0, 0)
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.Parent = parent
            corner(sec, 3)

            local head = Instance.new("TextLabel")
            head.BackgroundTransparency = 1
            head.Size = UDim2.new(1, -20, 0, 30)
            head.Position = UDim2.fromOffset(12, 0)
            head.FontFace = FONT
            head.TextSize = 14
            head.TextColor3 = Library.Theme.Text
            head.TextXAlignment = Enum.TextXAlignment.Left
            head.Text = s.Name or "Section"
            head.Parent = sec

            local div = Instance.new("Frame")
            div.BackgroundColor3 = Library.Theme.Elevated
            div.BorderSizePixel = 0
            div.Position = UDim2.fromOffset(0, 30)
            div.Size = UDim2.new(1, 0, 0, 1)
            div.Parent = sec

            local body = Instance.new("Frame")
            body.BackgroundTransparency = 1
            body.Position = UDim2.fromOffset(0, 31)
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Parent = sec
            padding(body, 8, 10, 10, 10)
            local bl = Instance.new("UIListLayout")
            bl.Padding = UDim.new(0, 8)
            bl.SortOrder = Enum.SortOrder.LayoutOrder
            bl.Parent = body

            local Section = {}

            local function baseRow(h)
                local r = Instance.new("Frame")
                r.BackgroundTransparency = 1
                r.Size = UDim2.new(1, 0, 0, h or 28)
                r.Parent = body
                return r
            end

            function Section:Toggle(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local state = o.Default == true
                if flag then Library.Flags[flag] = state end
                local r = baseRow(28)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -50, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.TextYAlignment = Enum.TextYAlignment.Center
                nl.Text = o.Name or "Toggle"
                nl.Parent = r
                -- pill track 27x16 fully rounded (exact clone)
                local track = Instance.new("Frame")
                track.AnchorPoint = Vector2.new(1, 0)
                track.Position = UDim2.new(1, -2, 0, 6)
                track.Size = UDim2.fromOffset(27, 16)
                track.BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35)
                track.BorderSizePixel = 0
                track.Parent = r
                corner(track, 8)
                trackTheme(track, "BackgroundColor3")
                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(10, 10)
                knob.Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.Parent = track
                corner(knob, 5)
                local hitB = Instance.new("TextButton")
                hitB.BackgroundTransparency = 1
                hitB.Size = UDim2.fromScale(1, 1)
                hitB.Text = ""
                hitB.Parent = r
                local function set(v, silent)
                    state = not not v
                    if flag then Library.Flags[flag] = state end
                    tween(track, { BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35) }, 0.15)
                    tween(knob, { Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3) }, 0.15, Enum.EasingStyle.Quad)
                    if not silent and o.Callback then task.spawn(o.Callback, state) end
                end
                conn(hitB.MouseButton1Click, function() set(not state) end)
                return { Set = set, Get = function() return state end }
            end

            function Section:Slider(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local minv, maxv = o.Min or 0, o.Max or 100
                local step = o.Float or o.Increment or 1
                local value = o.Default or minv
                if flag then Library.Flags[flag] = value end
                local wrap = baseRow(42)
                wrap.Size = UDim2.new(1, 0, 0, 42)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -54, 0, 16)
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
                vl.Size = UDim2.fromOffset(50, 16)
                vl.FontFace = FONT
                vl.TextSize = 12
                vl.TextColor3 = Library.Theme.Dim
                vl.TextXAlignment = Enum.TextXAlignment.Right
                vl.Text = tostring(value) .. (o.Suffix or "")
                vl.Parent = wrap
                local track = Instance.new("Frame")
                track.BackgroundColor3 = Library.Theme.Elevated
                track.BorderSizePixel = 0
                track.Position = UDim2.fromOffset(0, 24)
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Parent = wrap
                corner(track, 3)
                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Library.Theme.Accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.Parent = track
                corner(fill, 3)
                trackTheme(fill, "BackgroundColor3")
                local function set(v, silent)
                    v = math.clamp(tonumber(v) or minv, minv, maxv)
                    if step >= 1 then v = math.floor(v / step + 0.5) * step
                    else
                        local d = math.floor(v / step + 0.5) * step
                        v = tonumber(string.format("%.8f", d)) or d
                    end
                    value = v
                    if flag then Library.Flags[flag] = value end
                    local pct = (value - minv) / math.max(maxv - minv, 1e-9)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    if step < 1 then
                        vl.Text = string.format("%s%s", tostring(value), o.Suffix or "")
                    else
                        vl.Text = tostring(value) .. (o.Suffix or "")
                    end
                    if not silent and o.Callback then task.spawn(o.Callback, value) end
                end
                local sliding = false
                conn(track.InputBegan, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end
                end)
                conn(UIS.InputEnded, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
                end)
                conn(UIS.InputChanged, function(i)
                    if not sliding then return end
                    if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
                    local rel = (i.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                    set(minv + rel * (maxv - minv))
                end)
                set(value, true)
                return { Set = set, Get = function() return value end }
            end

            function Section:Dropdown(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local items = o.Values or o.Items or {}
                local cur = o.Default or items[1]
                if flag then Library.Flags[flag] = cur end
                local r = baseRow(28)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(0.42, 0, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Dropdown"
                nl.Parent = r
                local box = Instance.new("TextButton")
                box.AutoButtonColor = false
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, 0, 0.5, 0)
                box.Size = UDim2.new(0.55, 0, 0, 24)
                box.FontFace = FONT
                box.TextSize = 12
                box.TextColor3 = Library.Theme.Text
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Text = "  " .. tostring(cur or "Select")
                box.Parent = r
                corner(box, 4)
                local idx = 1
                for i, v in ipairs(items) do if v == cur then idx = i break end end
                conn(box.MouseButton1Click, function()
                    if #items == 0 then return end
                    idx = idx % #items + 1
                    cur = items[idx]
                    box.Text = "  " .. tostring(cur)
                    if flag then Library.Flags[flag] = cur end
                    if o.Callback then task.spawn(o.Callback, cur) end
                end)
                return {
                    Set = function(v) cur = v box.Text = "  " .. tostring(v) if flag then Library.Flags[flag] = v end end,
                    Get = function() return cur end,
                }
            end

            function Section:Button(o)
                o = o or {}
                local r = baseRow(30)
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
                conn(b.MouseButton1Click, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Accent }, 0.08)
                    task.delay(0.12, function() tween(b, { BackgroundColor3 = Library.Theme.Surface2 }, 0.15) end)
                    if o.Callback then task.spawn(o.Callback) end
                end)
            end

            function Section:Keybind(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local key = o.Default or Enum.KeyCode.Unknown
                if flag then Library.Flags[flag] = key end
                local r = baseRow(28)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -90, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 13
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
                b.Size = UDim2.fromOffset(80, 22)
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
                    b.TextColor3 = Library.Theme.Accent
                end)
                conn(UIS.InputBegan, function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        b.Text = key.Name
                        b.TextColor3 = Library.Theme.Dim
                        listening = false
                        if flag then Library.Flags[flag] = key end
                        if Library.KeybindListInstance then
                            Library.KeybindListInstance:Set(o.Name or flag, key.Name)
                        end
                        if o.Callback then task.spawn(o.Callback, key) end
                    end
                end)
                if Library.KeybindListInstance then
                    Library.KeybindListInstance:Add(o.Name or flag, key.Name or "NONE")
                end
                return { Get = function() return key end }
            end

            function Section:Textbox(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local text = o.Default or ""
                if flag then Library.Flags[flag] = text end
                local wrap = baseRow(50)
                wrap.Size = UDim2.new(1, 0, 0, 50)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, 0, 0, 16)
                nl.FontFace = FONT
                nl.TextSize = 13
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = o.Name or "Text"
                nl.Parent = wrap
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Library.Theme.Surface2
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 22)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.FontFace = FONT
                box.TextSize = 12
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderColor3 = Library.Theme.Dim
                box.PlaceholderText = o.Placeholder or ""
                box.Text = text
                box.ClearTextOnFocus = false
                box.Parent = wrap
                corner(box, 4)
                padding(box, 0, 0, 8, 8)
                conn(box.FocusLost, function()
                    text = box.Text
                    if flag then Library.Flags[flag] = text end
                    if o.Callback then task.spawn(o.Callback, text) end
                end)
            end

            function Section:Label(o)
                local r = baseRow(18)
                r.Size = UDim2.new(1, 0, 0, 18)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.fromScale(1, 1)
                nl.FontFace = FONT_REG
                nl.TextSize = 12
                nl.TextColor3 = Library.Theme.Dim
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Text = type(o) == "table" and (o.Text or o.Name) or tostring(o)
                nl.Parent = r
            end

            function Section:Colorpicker(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local col = o.Default or Library.Theme.Accent
                if flag then Library.Flags[flag] = col end
                local r = baseRow(28)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -36, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 13
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
                sw.Size = UDim2.fromOffset(22, 22)
                sw.Text = ""
                sw.Parent = r
                corner(sw, 4)
                -- cycle preset accents on click (compact)
                local presets = {
                    Color3.fromRGB(245, 93, 97),
                    Color3.fromRGB(100, 180, 255),
                    Color3.fromRGB(120, 220, 140),
                    Color3.fromRGB(240, 180, 60),
                    Color3.fromRGB(180, 120, 255),
                    Color3.fromRGB(255, 255, 255),
                }
                local pi = 1
                conn(sw.MouseButton1Click, function()
                    pi = pi % #presets + 1
                    col = presets[pi]
                    sw.BackgroundColor3 = col
                    if flag then Library.Flags[flag] = col end
                    if o.Callback then task.spawn(o.Callback, col) end
                    if o.GlobalAccent then Library:SetAccent(col) end
                end)
                return { Set = function(c) col = c sw.BackgroundColor3 = c if flag then Library.Flags[flag] = c end end, Get = function() return col end }
            end

            return Section
        end

        return Tab
    end

    function Window:Unload()
        Library.Unloaded = true
        for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
        pcall(function() screen:Destroy() end)
        if Library.KeybindListInstance and Library.KeybindListInstance.Gui then
            pcall(function() Library.KeybindListInstance.Gui:Destroy() end)
        end
    end

    -- config helpers on window
    function Window:GetConfig()
        local cfg = {}
        for k, v in pairs(Library.Flags) do
            if typeof(v) == "Color3" then
                cfg[k] = { __color = true, R = v.R, G = v.G, B = v.B }
            elseif typeof(v) == "EnumItem" then
                cfg[k] = { __enum = true, EnumType = tostring(v.EnumType), Name = v.Name }
            else
                cfg[k] = v
            end
        end
        cfg.__accent = { R = Library.Theme.Accent.R, G = Library.Theme.Accent.G, B = Library.Theme.Accent.B }
        return HS:JSONEncode(cfg)
    end

    function Window:SaveConfig(name)
        name = name or "default"
        local path = Library.Directory .. "/configs/" .. name .. ".json"
        pcall(function()
            if makefolder then makefolder(Library.Directory .. "/configs") end
            writefile(path, Window:GetConfig())
        end)
        Library:Notify({ Title = "Config", Content = "Saved " .. name, Duration = 2 })
    end

    function Window:LoadConfig(name)
        name = name or "default"
        local path = Library.Directory .. "/configs/" .. name .. ".json"
        local ok, data = pcall(function() return HS:JSONDecode(readfile(path)) end)
        if not ok or type(data) ~= "table" then
            Library:Notify({ Title = "Config", Content = "Failed to load " .. name, Duration = 2 })
            return
        end
        for k, v in pairs(data) do
            if k:sub(1, 2) ~= "__" then
                if type(v) == "table" and v.__color then
                    Library.Flags[k] = Color3.new(v.R, v.G, v.B)
                elseif type(v) == "table" and v.__enum then
                    pcall(function() Library.Flags[k] = Enum[v.EnumType][v.Name] end)
                else
                    Library.Flags[k] = v
                end
            end
        end
        if data.__accent then
            Library:SetAccent(Color3.new(data.__accent.R, data.__accent.G, data.__accent.B))
        end
        Library:Notify({ Title = "Config", Content = "Loaded " .. name, Duration = 2 })
    end

    table.insert(Library.Windows, Window)
    Library:Notify({ Title = title, Content = "Loaded · LeftAlt toggles menu", Duration = 4 })
    return Window
end

function Library:Unload()
    for _, w in ipairs(self.Windows) do pcall(function() w:Unload() end) end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Unloaded = true
end

getgenv().Destruction = Library
getgenv().Chromatik = Library
return Library
