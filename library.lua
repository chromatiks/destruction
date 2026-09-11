--[[
  Destruction UI — built ON exact_clone_open shell (pixel-matched chrome)
  Put exact_clone_open.lua next to this file, or it HttpGets from your repo.
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
    Version = "3.0.0-shell",
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
    pcall(function() if gethui then h = gethui() end end)
    return typeof(h) == "Instance" and h or CoreGui
end

local function tween(o, p, t, s)
    local tw = TS:Create(o, TweenInfo.new(t or 0.18, s or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
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

----------------------------------------------------------------
-- Load EXACT shell from clone file
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
        if ok and type(r) == "string" and #r > 1000 then src = r break end
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
-- Notifications
----------------------------------------------------------------
local notifHost
function Library:Notify(opts)
    if type(opts) ~= "table" then opts = { Title = tostring(opts) } end
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
        h.Size = UDim2.new(0, 300, 1, -70)
        h.Parent = sg
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Right
        list.Parent = h
        notifHost = h
    end
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    f.BorderSizePixel = 0
    f.Size = UDim2.new(0, 280, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = notifHost
    corner(f, 8)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(33, 33, 38)
    st.Thickness = 1
    st.Parent = f
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
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 16)
    t.FontFace = FONT
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
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
        b.TextColor3 = Color3.fromRGB(140, 140, 150)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextWrapped = true
        b.Text = opts.Content or opts.Description
        b.Parent = f
    end
    f.BackgroundTransparency = 1
    tween(f, { BackgroundTransparency = 0 }, 0.2)
    task.delay(opts.Duration or 3.5, function()
        if f.Parent then
            tween(f, { BackgroundTransparency = 1 }, 0.18)
            task.wait(0.2)
            f:Destroy()
        end
    end)
end

----------------------------------------------------------------
-- Window from shell
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

    -- center window
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)

    -- live watermark FPS / time / ping / game
    task.spawn(function()
        local frames, last = 0, tick()
        -- find labels under watermark
        local labels = {}
        if watermark then
            for _, d in ipairs(watermark:GetDescendants()) do
                if d:IsA("TextLabel") then table.insert(labels, d) end
            end
        end
        -- typical order in clone: user-ish, time, game — we update by content heuristics
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
                if t:find("FPS") or t:find("fps") or tonumber((t:gsub("[^%d]", ""))) and t:find("%d%s*FPS") then
                    l.Text = fps .. " FPS"
                elseif t:find("ms") then
                    l.Text = ping .. " ms"
                elseif t:match("^%d%d:%d%d:%d%d$") then
                    l.Text = timeStr
                end
            end
            -- also try fixed indices if clone order is stable
            if labels[3] and labels[3].Text:find("%d") then
                -- keep game name
            end
        end)
        pcall(function()
            local info = MarketplaceService:GetProductInfo(game.PlaceId)
            for _, l in ipairs(labels) do
                if l.Text == "Anime Expeditions" or #l.Text > 8 and not l.Text:find(":") and not l.Text:find("FPS") then
                    -- leave or set game
                end
            end
            if labels[#labels] then labels[#labels].Text = info.Name or labels[#labels].Text end
        end)
    end)

    -- clear demo content from both columns; keep structure
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
            local p = Instance.new("UIPadding")
            p.PaddingLeft = UDim.new(0, 4)
            p.PaddingRight = UDim.new(0, 4)
            p.PaddingTop = UDim.new(0, 4)
            p.PaddingBottom = UDim.new(0, 8)
            p.Parent = sf
        end
    end
    clearScroll(leftScroll)
    clearScroll(rightScroll)

    titleL.Text = opts.Name or opts.Title or titleL.Text
    if opts.Subtitle or opts.Description then
        subL.Text = opts.Subtitle or opts.Description
    end

    -- tab buttons in sidebar (Frame_3..6 + TextButton..)
    local tabFrames = { a.Frame_3, a.Frame_4, a.Frame_5, a.Frame_6 }
    local tabButtons = { a.TextButton, a.TextButton_2, a.TextButton_3, a.TextButton_4 }
    local tabIcons = { a.ImageLabel_2, a.ImageLabel_3, a.ImageLabel_4, a.ImageLabel_5 }
    local tabPages = {}
    local tabs = {}
    local current

    -- each tab gets its own left/right by showing/hiding section groups
    -- simpler: one pair of scrolls, sections tagged by tab id
    local tabSections = {} -- tabIndex -> {sections}

    local function selectTab(i)
        current = i
        for idx, fr in ipairs(tabFrames) do
            if fr then
                local on = idx == i
                tween(fr, { BackgroundColor3 = on and Color3.fromRGB(27, 27, 35) or Color3.fromRGB(20, 20, 26) }, 0.15)
                if tabIcons[idx] then
                    tween(tabIcons[idx], { ImageColor3 = on and Library.Theme.Accent or Color3.fromRGB(140, 140, 150) }, 0.15)
                end
            end
        end
        -- show/hide section roots
        for ti, list in pairs(tabSections) do
            for _, sec in ipairs(list) do
                if sec and sec.Root then
                    sec.Root.Visible = (ti == i)
                end
            end
        end
        if tabs[i] then
            titleL.Text = tabs[i].Name or titleL.Text
            if tabs[i].Subtitle then subL.Text = tabs[i].Subtitle end
        end
    end

    for i, btn in ipairs(tabButtons) do
        if btn then
            conn(btn.MouseButton1Click, function()
                selectTab(i)
            end)
        end
    end

    -- drag main (top strip)
    do
        local dragging, start, startPos
        conn(main.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local rel = input.Position.Y - main.AbsolutePosition.Y
            if rel > 50 then return end
            dragging, start, startPos = true, input.Position, main.Position
        end)
        conn(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        conn(UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - start
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
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

    local Window = { Shell = a, Main = main, Gui = gui }
    local tabCount = 0

    function Window:Tab(t)
        t = t or {}
        tabCount += 1
        local idx = tabCount
        tabs[idx] = { Name = t.Name or ("Tab " .. idx), Subtitle = t.Subtitle or t.Description }
        tabSections[idx] = {}

        if tabIcons[idx] and t.Icon then
            tabIcons[idx].Image = "rbxassetid://" .. tostring(t.Icon):gsub("rbxassetid://", "")
        end
        if tabFrames[idx] then
            tabFrames[idx].Visible = true
        end

        if idx == 1 then task.defer(function() selectTab(1) end) end

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
            head.TextColor3 = Color3.fromRGB(255, 255, 255)
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

            -- EXACT pill toggle from clone Frame_15 (27x16) + Frame_16 knob 10x10
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
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.TextYAlignment = Enum.TextYAlignment.Center
                nl.Text = o.Name or "Toggle"
                nl.Parent = r

                local trackF = Instance.new("Frame")
                trackF.AnchorPoint = Vector2.new(1, 0)
                trackF.Position = UDim2.new(1, -2, 0, 3)
                trackF.Size = UDim2.fromOffset(27, 16)
                trackF.BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35)
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
                    tween(trackF, { BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(27, 27, 35) }, 0.15)
                    tween(knob, { Position = state and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3) }, 0.15)
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
                    gear.ImageColor3 = Color3.fromRGB(140, 140, 150)
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
                    Instance.new("UIListLayout", panel).Padding = UDim.new(0, 6)
                    conn(gear.MouseButton1Click, function()
                        open = not open
                        panel.Visible = open
                        tween(gear, { ImageColor3 = open and Library.Theme.Accent or Color3.fromRGB(140, 140, 150) }, 0.12)
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
                            en.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                                tween(tr, { BackgroundColor3 = st and Library.Theme.Accent or Color3.fromRGB(27, 27, 35) }, 0.12)
                                tween(kn, { Position = st and UDim2.fromOffset(14, 3) or UDim2.fromOffset(2, 3) }, 0.12)
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
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                vl.TextColor3 = Color3.fromRGB(140, 140, 150)
                vl.TextXAlignment = Enum.TextXAlignment.Right
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
                nl.TextColor3 = Color3.fromRGB(140, 140, 150)
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
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Text = "  " .. tostring(cur or "Select")
                box.Parent = wrap
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
                return { Set = function(v) cur = v box.Text = "  " .. tostring(v) end, Get = function() return cur end }
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
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
                b.Text = o.Name or "Button"
                b.Parent = r
                corner(b, 4)
                conn(b.MouseButton1Click, function()
                    tween(b, { BackgroundColor3 = Library.Theme.Accent }, 0.08)
                    task.delay(0.12, function() tween(b, { BackgroundColor3 = Color3.fromRGB(27, 27, 35) }, 0.18) end)
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
                nl.TextColor3 = Color3.fromRGB(140, 140, 150)
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
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
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
                nl.TextColor3 = Color3.fromRGB(140, 140, 150)
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
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                b.TextColor3 = Color3.fromRGB(140, 140, 150)
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
                        b.TextColor3 = Color3.fromRGB(140, 140, 150)
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
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                    Color3.fromRGB(245, 93, 97), Color3.fromRGB(100, 180, 255),
                    Color3.fromRGB(120, 220, 140), Color3.fromRGB(240, 180, 60),
                    Color3.fromRGB(180, 120, 255), Color3.fromRGB(255, 255, 255),
                }
                local pi = 1
                conn(sw.MouseButton1Click, function()
                    pi = pi % #presets + 1
                    col = presets[pi]
                    sw.BackgroundColor3 = col
                    if flag then Library.Flags[flag] = col end
                    if o.Callback then task.spawn(o.Callback, col) end
                    if o.GlobalAccent then Library.Theme.Accent = col end
                end)
                return { Set = function(c) col = c sw.BackgroundColor3 = c end, Get = function() return col end }
            end

            return Section
        end

        return Tab
    end

    function Window:Unload()
        Library.Unloaded = true
        for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
    end

    function Window:SaveConfig(name)
        name = name or "default"
        pcall(function()
            if makefolder then makefolder(Library.Directory .. "/configs") end
            writefile(Library.Directory .. "/configs/" .. name .. ".json", HS:JSONEncode(Library.Flags))
        end)
        Library:Notify({ Title = "Config", Content = "Saved " .. name })
    end

    function Window:LoadConfig(name)
        name = name or "default"
        local ok, data = pcall(function()
            return HS:JSONDecode(readfile(Library.Directory .. "/configs/" .. name .. ".json"))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do Library.Flags[k] = v end
            Library:Notify({ Title = "Config", Content = "Loaded " .. name })
        else
            Library:Notify({ Title = "Config", Content = "Load failed" })
        end
    end

    -- Watermark is already in shell (Frame_67) — no separate call needed
    Library:Notify({ Title = opts.Name or "Destruction", Content = "Shell loaded · LeftAlt toggles", Duration = 3 })
    return Window
end

-- Watermark already part of shell; stub for API compat
function Library:Watermark()
    return { SetVisible = function() end, SetText = function() end }
end

function Library:KeybindList()
    return { SetVisible = function() end, Add = function() end, Set = function() end }
end

getgenv().Destruction = Library
return Library
