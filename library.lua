--[[
  Destruction UI — visual match to Neptune open menu (exact_clone_open + screenshot)
  714x475 · sidebar 80 · accent 245,93,97 · Arimo · pill toggles · top-right watermark
]]

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Library = {
    Directory = "Destruction",
    Flags = {},
    Connections = {},
    Windows = {},
    Open = true,
    Unloaded = false,
    Version = "2.1.0",
    MenuKey = Enum.KeyCode.LeftAlt,
    Theme = {
        Accent = Color3.fromRGB(245, 93, 97),
        Background = Color3.fromRGB(17, 17, 22),
        Surface = Color3.fromRGB(20, 20, 26),
        Surface2 = Color3.fromRGB(27, 27, 35),
        Elevated = Color3.fromRGB(33, 33, 38),
        Text = Color3.fromRGB(255, 255, 255),
        Dim = Color3.fromRGB(140, 140, 150),
        Placeholder = Color3.fromRGB(90, 90, 100),
        Stroke = Color3.fromRGB(33, 33, 38),
    },
    _theme = {},
}

local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_MED = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

local function hui()
    local h
    pcall(function() if gethui then h = gethui() end end)
    return typeof(h) == "Instance" and h or CoreGui
end

local function protect(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = hui()
end

local function tween(o, p, t, s, d)
    local tw = TS:Create(o, TweenInfo.new(t or 0.18, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
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

local function track(obj, prop)
    Library._theme[#Library._theme + 1] = { obj = obj, prop = prop }
end

function Library:SetAccent(c)
    self.Theme.Accent = c
    for _, e in ipairs(self._theme) do
        pcall(function() e.obj[e.prop] = c end)
    end
end

function Library:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, start, startPos
    conn(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, start, startPos = true, input.Position, frame.Position
        end
    end)
    conn(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    conn(UIS.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - start
        local vs = Camera.ViewportSize
        local nx = math.clamp(startPos.X.Offset + d.X, 0, math.max(0, vs.X - frame.AbsoluteSize.X))
        local ny = math.clamp(startPos.Y.Offset + d.Y, 0, math.max(0, vs.Y - frame.AbsoluteSize.Y))
        frame.Position = UDim2.fromOffset(nx, ny)
    end)
end

pcall(function()
    if makefolder then makefolder(Library.Directory) makefolder(Library.Directory .. "/configs") end
end)

----------------------------------------------------------------
-- Notifications (slide from top-right)
----------------------------------------------------------------
local notifHost
local function getNotifHost()
    if notifHost and notifHost.Parent then return notifHost end
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestNotifs"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 3000
    protect(sg)
    local h = Instance.new("Frame")
    h.BackgroundTransparency = 1
    h.AnchorPoint = Vector2.new(1, 0)
    h.Position = UDim2.new(1, -16, 0, 56)
    h.Size = UDim2.new(0, 300, 1, -70)
    h.Parent = sg
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = h
    notifHost = h
    return h
end

function Library:Notify(opts)
    if type(opts) ~= "table" then opts = { Title = tostring(opts) } end
    local host = getNotifHost()
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Library.Theme.Background
    f.BorderSizePixel = 0
    f.Size = UDim2.new(0, 280, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = host
    corner(f, 8)
    stroke(f, Library.Theme.Stroke, 1)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = f
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Library.Theme.Accent
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(0, 3, 1, 24)
    bar.Position = UDim2.fromOffset(-14, -12)
    bar.Parent = f
    corner(bar, 2)
    track(bar, "BackgroundColor3")
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 16)
    t.FontFace = FONT
    t.TextSize = 14
    t.TextColor3 = Library.Theme.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = opts.Title or "Notification"
    t.Parent = f
    if opts.Content or opts.Description then
        local b = Instance.new("TextLabel")
        b.BackgroundTransparency = 1
        b.Position = UDim2.fromOffset(0, 20)
        b.Size = UDim2.new(1, 0, 0, 0)
        b.AutomaticSize = Enum.AutomaticSize.Y
        b.FontFace = FONT_MED
        b.TextSize = 12
        b.TextColor3 = Library.Theme.Dim
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextWrapped = true
        b.Text = opts.Content or opts.Description
        b.Parent = f
    end
    f.Position = UDim2.fromOffset(40, 0)
    f.BackgroundTransparency = 1
    tween(f, { BackgroundTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.25, Enum.EasingStyle.Quint)
    task.delay(opts.Duration or 3.5, function()
        if not f.Parent then return end
        tween(f, { BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0) }, 0.2)
        task.wait(0.22)
        f:Destroy()
    end)
end

----------------------------------------------------------------
-- Watermark (exact: top-right, 38h, accent bar, chips)
----------------------------------------------------------------
function Library:Watermark(opts)
    opts = type(opts) == "table" and opts or { Text = tostring(opts or "Destruction") }
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestWM"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 100
    protect(sg)

    local f = Instance.new("Frame")
    f.Active = true
    f.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(1, 0)
    f.Position = UDim2.new(1, -15, 0, 12)
    f.Size = UDim2.new(0, 0, 0, 38)
    f.AutomaticSize = Enum.AutomaticSize.X
    f.Parent = sg
    corner(f, 8)
    stroke(f, Color3.fromRGB(33, 33, 38), 1)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 16)
    pad.Parent = f
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = f

    local function addLogo(order)
        local h = Instance.new("Frame")
        h.BackgroundTransparency = 1
        h.Size = UDim2.fromOffset(20, 38)
        h.LayoutOrder = order
        h.Parent = f
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Position = UDim2.fromScale(0.5, 0.5)
        img.Size = UDim2.fromOffset(18, 18)
        img.Image = "rbxassetid://" .. tostring(opts.Icon or "81603686073386"):gsub("rbxassetid://", "")
        img.Parent = h
    end

    local function addBar(order)
        local b = Instance.new("Frame")
        b.BackgroundColor3 = Library.Theme.Accent
        b.BorderSizePixel = 0
        b.Size = UDim2.fromOffset(2, 22)
        b.LayoutOrder = order
        b.Parent = f
        track(b, "BackgroundColor3")
    end

    local function addChip(iconId, text, order)
        local h = Instance.new("Frame")
        h.BackgroundTransparency = 1
        h.Size = UDim2.fromOffset(0, 38)
        h.AutomaticSize = Enum.AutomaticSize.X
        h.LayoutOrder = order
        h.Parent = f
        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.VerticalAlignment = Enum.VerticalAlignment.Center
        hl.Padding = UDim.new(0, 5)
        hl.Parent = h
        if iconId then
            local ic = Instance.new("ImageLabel")
            ic.BackgroundTransparency = 1
            ic.Size = UDim2.fromOffset(13, 13)
            ic.Image = "rbxassetid://" .. tostring(iconId):gsub("rbxassetid://", "")
            ic.ImageColor3 = Color3.fromRGB(220, 220, 230)
            ic.Parent = h
        end
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.fromOffset(0, 38)
        l.AutomaticSize = Enum.AutomaticSize.X
        l.FontFace = FONT
        l.TextSize = 14
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.Text = text or ""
        l.Parent = h
        return l
    end

    addLogo(1)
    addBar(2)
    local fpsL = addChip("121808839832144", "0 FPS", 3)
    local pingL = addChip(nil, "0 ms", 4)
    local timeL = addChip(nil, os.date("%H:%M:%S"), 5)
    local gameL = addChip("92483947987410", "...", 6)

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
            timeL.Text = os.date("%H:%M:%S")
            pcall(function()
                local p = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                pingL.Text = math.floor(p + 0.5) .. " ms"
            end)
        end
    end)

    f.BackgroundTransparency = 1
    tween(f, { BackgroundTransparency = 0 }, 0.3)
    Library:MakeDraggable(f)
    return {
        SetVisible = function(_, v) f.Visible = v and true or false end,
        SetText = function(_, t) end,
        Frame = f,
        Gui = sg,
    }
end

----------------------------------------------------------------
-- Keybind list
----------------------------------------------------------------
function Library:KeybindList()
    local sg = Instance.new("ScreenGui")
    sg.Name = "DestKB"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    protect(sg)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Library.Theme.Background
    f.BorderSizePixel = 0
    f.Position = UDim2.fromOffset(12, 12)
    f.Size = UDim2.fromOffset(170, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = sg
    corner(f, 8)
    stroke(f, Library.Theme.Stroke, 1)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = f
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
    Instance.new("UIListLayout", body).Padding = UDim.new(0, 4)
    local rows = {}
    Library:MakeDraggable(f, title)
    local api = {
        Gui = sg,
        SetVisible = function(_, v) f.Visible = v and true or false end,
        Add = function(_, name, key)
            local r = Instance.new("TextLabel")
            r.BackgroundTransparency = 1
            r.Size = UDim2.new(1, 0, 0, 15)
            r.FontFace = FONT_MED
            r.TextSize = 12
            r.TextColor3 = Library.Theme.Dim
            r.TextXAlignment = Enum.TextXAlignment.Left
            r.Text = string.format("%s  [%s]", name, key or "NONE")
            r.Parent = body
            rows[name] = r
        end,
        Set = function(_, name, key)
            if rows[name] then rows[name].Text = string.format("%s  [%s]", name, key or "NONE") end
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
    local winTitle = opts.Name or opts.Title or "Destruction"
    local winSub = opts.Subtitle or opts.Description or ""
    local logoId = tostring(opts.Icon or "81603686073386"):gsub("rbxassetid://", "")

    local screen = Instance.new("ScreenGui")
    screen.Name = "DestWindow"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protect(screen)

    -- MAIN 714 x 475
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    main.BorderSizePixel = 0
    main.Size = UDim2.fromOffset(714, 475)
    main.Position = UDim2.new(0.5, -357, 0.5, -237)
    main.Active = true
    main.ClipsDescendants = true
    main.Parent = screen
    corner(main, 15)

    -- SIDEBAR 80
    local side = Instance.new("Frame")
    side.BackgroundTransparency = 1
    side.Size = UDim2.new(0, 80, 1, 0)
    side.Parent = main

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(8, 10)
    logo.Size = UDim2.fromOffset(64, 56)
    logo.Image = "rbxassetid://" .. logoId
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = side

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.Position = UDim2.fromOffset(0, 75)
    tabScroll.Size = UDim2.new(1, 0, 1, -90)
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new()
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.Parent = side
    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 6)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabScroll

    -- CONTENT 619 x 445 at 80,15
    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(80, 12)
    content.Size = UDim2.new(1, -92, 1, -24)
    content.ClipsDescendants = true
    content.Parent = main

    -- header title + subtitle
    local headTitle = Instance.new("TextLabel")
    headTitle.BackgroundTransparency = 1
    headTitle.Position = UDim2.fromOffset(8, 4)
    headTitle.Size = UDim2.new(1, -160, 0, 20)
    headTitle.FontFace = FONT
    headTitle.TextSize = 16
    headTitle.TextColor3 = Library.Theme.Text
    headTitle.TextXAlignment = Enum.TextXAlignment.Left
    headTitle.Text = winTitle
    headTitle.Parent = content

    local headSub = Instance.new("TextLabel")
    headSub.BackgroundTransparency = 1
    headSub.Position = UDim2.fromOffset(8, 24)
    headSub.Size = UDim2.new(1, -160, 0, 16)
    headSub.FontFace = FONT_MED
    headSub.TextSize = 12
    headSub.TextColor3 = Library.Theme.Dim
    headSub.TextXAlignment = Enum.TextXAlignment.Left
    headSub.Text = winSub
    headSub.Parent = content

    local pages = Instance.new("Frame")
    pages.BackgroundTransparency = 1
    pages.Position = UDim2.fromOffset(0, 48)
    pages.Size = UDim2.new(1, 0, 1, -48)
    pages.ClipsDescendants = true
    pages.Parent = content

    -- drag
    Library:MakeDraggable(main, side)
    do
        local dragging, start, startPos
        conn(main.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if (input.Position.Y - main.AbsolutePosition.Y) > 55 then return end
            if (input.Position.X - main.AbsolutePosition.X) > 80 then
                dragging, start, startPos = true, input.Position, main.Position
            end
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
                tween(main, { BackgroundTransparency = 0 }, 0.22, Enum.EasingStyle.Quint)
            else
                tween(main, { BackgroundTransparency = 1 }, 0.16)
                task.delay(0.18, function()
                    if not Library.Open then main.Visible = false main.BackgroundTransparency = 0 end
                end)
            end
        end
    end)

    local Window = { Tabs = {}, Main = main, Screen = screen }

    function Window:SetVisible(v)
        main.Visible = v and true or false
        Library.Open = main.Visible
    end

    function Window:Tab(t)
        t = t or {}
        local name = t.Name or "Tab"
        local iconId = tostring(t.Icon or "136634011674328"):gsub("rbxassetid://", "")
        local sub = t.Subtitle or t.Description or ""

        -- tab button 50x50 corner 3
        local btn = Instance.new("Frame")
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
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

        -- two columns
        local left = Instance.new("ScrollingFrame")
        left.BackgroundTransparency = 1
        left.BorderSizePixel = 0
        left.Size = UDim2.new(0.5, -6, 1, 0)
        left.ScrollBarThickness = 2
        left.ScrollBarImageColor3 = Library.Theme.Accent
        left.CanvasSize = UDim2.new()
        left.AutomaticCanvasSize = Enum.AutomaticSize.Y
        left.Parent = page
        track(left, "ScrollBarImageColor3")
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 14)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = left
        local lp = Instance.new("UIPadding")
        lp.PaddingLeft = UDim.new(0, 4)
        lp.PaddingRight = UDim.new(0, 4)
        lp.PaddingBottom = UDim.new(0, 12)
        lp.Parent = left

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
        track(right, "ScrollBarImageColor3")
        local rl = Instance.new("UIListLayout")
        rl.Padding = UDim.new(0, 14)
        rl.SortOrder = Enum.SortOrder.LayoutOrder
        rl.Parent = right
        local rp = Instance.new("UIPadding")
        rp.PaddingLeft = UDim.new(0, 4)
        rp.PaddingRight = UDim.new(0, 4)
        rp.PaddingBottom = UDim.new(0, 12)
        rp.Parent = right

        local Tab = { Name = name, Page = page, Button = btn, Icon = img }

        local function selectTab()
            for _, ot in ipairs(Window.Tabs) do
                ot.Page.Visible = false
                tween(ot.Button, { BackgroundColor3 = Color3.fromRGB(20, 20, 26) }, 0.15)
                tween(ot.Icon, { ImageColor3 = Library.Theme.Dim }, 0.15)
            end
            page.Visible = true
            tween(btn, { BackgroundColor3 = Color3.fromRGB(27, 27, 35) }, 0.15)
            tween(img, { ImageColor3 = Library.Theme.Accent }, 0.15)
            headTitle.Text = name
            headSub.Text = sub ~= "" and sub or (opts.Subtitle or "")
            page.Position = UDim2.fromOffset(0, 8)
            page.BackgroundTransparency = 1
            tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.2, Enum.EasingStyle.Quint)
        end
        conn(hit.MouseButton1Click, selectTab)
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then task.defer(selectTab) end

        function Tab:Section(s)
            s = s or {}
            local parent = (s.Side == "Right" or s.Side == 2) and right or left

            local sec = Instance.new("Frame")
            sec.BackgroundTransparency = 1
            sec.Size = UDim2.new(1, 0, 0, 0)
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.Parent = parent

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0, 18)
            title.FontFace = FONT
            title.TextSize = 13
            title.TextColor3 = Library.Theme.Text
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Text = s.Name or "Section"
            title.Parent = sec

            local body = Instance.new("Frame")
            body.BackgroundTransparency = 1
            body.Position = UDim2.fromOffset(0, 22)
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.Parent = sec
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

            -- PILL TOGGLE (27x16) exact
            function Section:Toggle(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local state = o.Default == true
                if flag then Library.Flags[flag] = state end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -50, 1, 0)
                nl.FontFace = FONT
                nl.TextSize = 14
                nl.TextColor3 = Library.Theme.Text
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.TextYAlignment = Enum.TextYAlignment.Center
                nl.Text = o.Name or "Toggle"
                nl.Parent = r

                local trackF = Instance.new("Frame")
                trackF.AnchorPoint = Vector2.new(1, 0.5)
                trackF.Position = UDim2.new(1, 0, 0.5, 0)
                trackF.Size = UDim2.fromOffset(27, 16)
                trackF.BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35)
                trackF.BorderSizePixel = 0
                trackF.Parent = r
                corner(trackF, 8)
                track(trackF, "BackgroundColor3")

                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(10, 10)
                knob.Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.Parent = trackF
                corner(knob, 5)

                local hitB = Instance.new("TextButton")
                hitB.BackgroundTransparency = 1
                hitB.Size = UDim2.fromScale(1, 1)
                hitB.Text = ""
                hitB.Parent = r

                local function set(v, silent)
                    state = not not v
                    if flag then Library.Flags[flag] = state end
                    tween(trackF, { BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35) }, 0.15)
                    tween(knob, { Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3) }, 0.15, Enum.EasingStyle.Quad)
                    if not silent and o.Callback then task.spawn(o.Callback, state) end
                end
                conn(hitB.MouseButton1Click, function() set(not state) end)

                local api = { Set = set, Get = function() return state end, Frame = r }

                -- gear / Extra like screenshot
                function api:Extra()
                    local gear = Instance.new("ImageButton")
                    gear.BackgroundTransparency = 1
                    gear.AnchorPoint = Vector2.new(1, 0.5)
                    gear.Position = UDim2.new(1, -34, 0.5, 0)
                    gear.Size = UDim2.fromOffset(14, 14)
                    gear.Image = "rbxassetid://6031280882"
                    gear.ImageColor3 = Library.Theme.Dim
                    gear.Parent = r
                    nl.Size = UDim2.new(1, -70, 1, 0)
                    local open = false
                    local panel = Instance.new("Frame")
                    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                    panel.BorderSizePixel = 0
                    panel.Size = UDim2.new(1, 0, 0, 0)
                    panel.AutomaticSize = Enum.AutomaticSize.Y
                    panel.Visible = false
                    panel.Parent = body
                    corner(panel, 6)
                    local pp = Instance.new("UIPadding")
                    pp.PaddingTop = UDim.new(0, 8)
                    pp.PaddingBottom = UDim.new(0, 8)
                    pp.PaddingLeft = UDim.new(0, 10)
                    pp.PaddingRight = UDim.new(0, 10)
                    pp.Parent = panel
                    local pl = Instance.new("UIListLayout")
                    pl.Padding = UDim.new(0, 6)
                    pl.Parent = panel
                    conn(gear.MouseButton1Click, function()
                        open = not open
                        panel.Visible = open
                        tween(gear, { ImageColor3 = open and Library.Theme.Accent or Library.Theme.Dim }, 0.12)
                    end)
                    local extraSec = {}
                    function extraSec:Toggle(eo)
                        return Section.Toggle(setmetatable({ Parent = panel }, { __index = Section }), eo)
                    end
                    function extraSec:Slider(eo)
                        return Section.Slider(Section, eo) -- fall through; simplified
                    end
                    -- simpler: add elements into panel via shared helpers
                    extraSec._panel = panel
                    extraSec.Toggle = function(_, eo)
                        eo = eo or {}
                        local er = Instance.new("Frame")
                        er.BackgroundTransparency = 1
                        er.Size = UDim2.new(1, 0, 0, 20)
                        er.Parent = panel
                        local en = Instance.new("TextLabel")
                        en.BackgroundTransparency = 1
                        en.Size = UDim2.new(1, -40, 1, 0)
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
                        tr.BackgroundColor3 = st and Library.Theme.Accent or Color3.fromRGB(27, 27, 35)
                        tr.BorderSizePixel = 0
                        tr.Parent = er
                        corner(tr, 7)
                        local kn = Instance.new("Frame")
                        kn.Size = UDim2.fromOffset(8, 8)
                        kn.Position = st and UDim2.fromOffset(14, 3) or UDim2.fromOffset(2, 3)
                        kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        kn.BorderSizePixel = 0
                        kn.Parent = tr
                        corner(kn, 4)
                        local hb = Instance.new("TextButton")
                        hb.BackgroundTransparency = 1
                        hb.Size = UDim2.fromScale(1, 1)
                        hb.Text = ""
                        hb.Parent = er
                        local fl = eo.Flag
                        if fl then Library.Flags[fl] = st end
                        conn(hb.MouseButton1Click, function()
                            st = not st
                            if fl then Library.Flags[fl] = st end
                            tween(tr, { BackgroundColor3 = st and Library.Theme.Accent or Color3.fromRGB(27, 27, 35) }, 0.12)
                            tween(kn, { Position = st and UDim2.fromOffset(14, 3) or UDim2.fromOffset(2, 3) }, 0.12)
                            if eo.Callback then task.spawn(eo.Callback, st) end
                        end)
                    end
                    extraSec.Slider = function(_, eo)
                        Section:Slider(eo) -- parent still main body; acceptable for compact
                    end
                    return extraSec
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
                vl.Text = tostring(value) .. (o.Suffix or "")
                vl.Parent = wrap
                local trackB = Instance.new("Frame")
                trackB.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
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
                track(fill, "BackgroundColor3")
                local function set(v, silent)
                    v = math.clamp(tonumber(v) or minv, minv, maxv)
                    if step >= 1 then v = math.floor(v / step + 0.5) * step
                    else v = math.floor(v / step + 0.5) * step end
                    value = v
                    if flag then Library.Flags[flag] = value end
                    fill.Size = UDim2.new((value - minv) / math.max(maxv - minv, 1e-9), 0, 1, 0)
                    vl.Text = tostring(value) .. (o.Suffix or "")
                    if not silent and o.Callback then task.spawn(o.Callback, value) end
                end
                local sliding = false
                conn(trackB.InputBegan, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true end
                end)
                conn(UIS.InputEnded, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
                end)
                conn(UIS.InputChanged, function(i)
                    if not sliding then return end
                    if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
                    local rel = (i.Position.X - trackB.AbsolutePosition.X) / math.max(trackB.AbsoluteSize.X, 1)
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
                box.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
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
                local chev = Instance.new("ImageLabel")
                chev.BackgroundTransparency = 1
                chev.AnchorPoint = Vector2.new(1, 0.5)
                chev.Position = UDim2.new(1, -8, 0.5, 0)
                chev.Size = UDim2.fromOffset(12, 12)
                chev.Image = "rbxassetid://6034818372"
                chev.ImageColor3 = Library.Theme.Dim
                chev.Parent = box
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
                local r = row(30)
                r.Size = UDim2.new(1, 0, 0, 30)
                local b = Instance.new("TextButton")
                b.AutoButtonColor = false
                b.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
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
                    task.delay(0.12, function() tween(b, { BackgroundColor3 = Color3.fromRGB(27, 27, 35) }, 0.18) end)
                    if o.Callback then task.spawn(o.Callback) end
                end)
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
                b.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
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
                        if Library.KeybindListInstance then Library.KeybindListInstance:Set(o.Name or flag, key.Name) end
                        if o.Callback then task.spawn(o.Callback, key) end
                    end
                end)
                if Library.KeybindListInstance then Library.KeybindListInstance:Add(o.Name or flag, key.Name or "NONE") end
                return { Get = function() return key end }
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
                box.BackgroundColor3 = Color3.fromRGB(27, 27, 35)
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(0, 20)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.FontFace = FONT
                box.TextSize = 13
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderColor3 = Library.Theme.Placeholder
                box.PlaceholderText = o.Placeholder or ""
                box.Text = text
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = wrap
                corner(box, 4)
                local bp = Instance.new("UIPadding")
                bp.PaddingLeft = UDim.new(0, 10)
                bp.Parent = box
                conn(box.FocusLost, function()
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

            function Section:Colorpicker(o)
                o = o or {}
                local flag = o.Flag or o.Name
                local col = o.Default or Library.Theme.Accent
                if flag then Library.Flags[flag] = col end
                local r = row(22)
                local nl = Instance.new("TextLabel")
                nl.BackgroundTransparency = 1
                nl.Size = UDim2.new(1, -30, 1, 0)
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

    function Window:GetConfig()
        local cfg = {}
        for k, v in pairs(Library.Flags) do
            if typeof(v) == "Color3" then cfg[k] = { __c = true, R = v.R, G = v.G, B = v.B }
            elseif typeof(v) == "EnumItem" then cfg[k] = { __e = true, T = tostring(v.EnumType), N = v.Name }
            else cfg[k] = v end
        end
        return HS:JSONEncode(cfg)
    end

    function Window:SaveConfig(name)
        name = name or "default"
        pcall(function()
            if makefolder then makefolder(Library.Directory .. "/configs") end
            writefile(Library.Directory .. "/configs/" .. name .. ".json", Window:GetConfig())
        end)
        Library:Notify({ Title = "Config", Content = "Saved " .. name, Duration = 2 })
    end

    function Window:LoadConfig(name)
        name = name or "default"
        local ok, data = pcall(function()
            return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. name .. ".json"))
        end)
        if not ok or type(data) ~= "table" then
            Library:Notify({ Title = "Config", Content = "Load failed", Duration = 2 })
            return
        end
        for k, v in pairs(data) do
            if type(v) == "table" and v.__c then Library.Flags[k] = Color3.new(v.R, v.G, v.B)
            elseif type(v) == "table" and v.__e then pcall(function() Library.Flags[k] = Enum[v.T][v.N] end)
            else Library.Flags[k] = v end
        end
        Library:Notify({ Title = "Config", Content = "Loaded " .. name, Duration = 2 })
    end

    function Window:Unload()
        Library.Unloaded = true
        for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
        pcall(function() screen:Destroy() end)
    end

    table.insert(Library.Windows, Window)
    main.BackgroundTransparency = 1
    tween(main, { BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Quint)
    Library:Notify({ Title = winTitle, Content = "Loaded · LeftAlt toggles", Duration = 3 })
    return Window
end

function Library:Unload()
    for _, w in ipairs(self.Windows) do pcall(function() w:Unload() end) end
    self.Unloaded = true
end

getgenv().Destruction = Library
getgenv().Chromatik = Library
return Library
