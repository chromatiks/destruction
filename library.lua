--[[
  Noctro UI
  Built from the Destruction shell (exact_clone_open) look:
  dark panel, 80px icon sidebar, dual columns, watermark.
  No other product names.
]]

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer

local function hui()
	local ok, g = pcall(function()
		return gethui and gethui()
	end)
	if ok and typeof(g) == "Instance" then
		return g
	end
	return CoreGui
end

local function protect(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	gui.Parent = hui()
end

local ACCENT = Color3.fromRGB(245, 93, 97)
local BG = Color3.fromRGB(17, 17, 22)
local BG2 = Color3.fromRGB(20, 20, 26)
local BG3 = Color3.fromRGB(24, 24, 30)
local LINE = Color3.fromRGB(33, 33, 38)
local TEXT = Color3.fromRGB(255, 255, 255)
local DIM = Color3.fromRGB(120, 120, 126)
local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_REG = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)

local Noctro = {
	Flags = {},
	Connections = {},
	Windows = {},
	Keybinds = {},
	ConfigDir = "Noctro/configs",
	Author = "Noctro",
	_setters = {},
}

local function tween(obj, props, t, style, dir)
	local ti = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local tw = TS:Create(obj, ti, props)
	tw:Play()
	return tw
end

local function conn(sig, fn)
	local c = sig:Connect(fn)
	table.insert(Noctro.Connections, c)
	return c
end

local function mk(class, props, parent)
	local i = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				i[k] = v
			end
		end
		if props.Parent then
			i.Parent = props.Parent
		end
	end
	if parent then
		i.Parent = parent
	end
	return i
end

local function corner(p, r)
	return mk("UICorner", { CornerRadius = UDim.new(0, r or 6) }, p)
end

local function stroke(p, col, th)
	return mk("UIStroke", { Color = col or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end

local function pad(p, l, r, t, b)
	return mk("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
	}, p)
end

local function list(p, dir, spacing)
	return mk("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, spacing or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, p)
end

local function dragify(frame, handle)
	handle = handle or frame
	local dragging, start, startPos
	conn(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = input.Position
			startPos = frame.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if c then c:Disconnect() end
				end
			end)
		end
	end)
	conn(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - start
			local goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			tween(frame, { Position = goal }, 0.08, Enum.EasingStyle.Quad)
		end
	end)
end

local function ensureFolders()
	pcall(function()
		if not isfolder then return end
		if not isfolder("Noctro") then makefolder("Noctro") end
		if not isfolder(Noctro.ConfigDir) then makefolder(Noctro.ConfigDir) end
	end)
end
ensureFolders()

local function buildWatermark(sg)
	local bar = mk("Frame", {
		Active = true,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -15, 0, 12),
		Size = UDim2.new(0, 0, 0, 38),
		AnchorPoint = Vector2.new(1, 0),
		Parent = sg,
	})
	corner(bar, 8)
	stroke(bar, LINE, 1)
	pad(bar, 12, 22, 0, 0)
	local lay = list(bar, Enum.FillDirection.Horizontal, 16)
	lay.VerticalAlignment = Enum.VerticalAlignment.Center

	local logoWrap = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 21, 0, 38), LayoutOrder = 1, Parent = bar })
	mk("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(34, 34),
		Image = "rbxassetid://81603686073386",
		ScaleType = Enum.ScaleType.Fit,
		Parent = logoWrap,
	})
	mk("Frame", { BackgroundColor3 = ACCENT, BorderSizePixel = 0, Size = UDim2.new(0, 2, 0, 38), LayoutOrder = 2, Parent = bar })

	local function chip(order, icon, text)
		local f = mk("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 38),
			LayoutOrder = order,
			Parent = bar,
		})
		local l = list(f, Enum.FillDirection.Horizontal, 6)
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		mk("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), Image = icon, LayoutOrder = 1, Parent = f })
		local lbl = mk("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 38),
			Text = text,
			TextColor3 = TEXT,
			TextSize = 15,
			FontFace = FONT,
			LayoutOrder = 2,
			Parent = f,
		})
		return lbl
	end

	local fpsL = chip(3, "rbxassetid://94212016861936", "0 fps")
	local msL = chip(4, "rbxassetid://104669375183960", "0 ms")
	local timeL = chip(5, "rbxassetid://121808839832144", "00:00:00")
	chip(6, "rbxassetid://92483947987410", tostring(game.Name or "Game"))

	local frames, last = 0, tick()
	conn(RS.RenderStepped, function()
		frames += 1
		local now = tick()
		if now - last >= 1 then
			fpsL.Text = tostring(frames) .. " fps"
			frames = 0
			last = now
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			msL.Text = tostring(ping) .. " ms"
			timeL.Text = os.date("%H:%M:%S")
		end
	end)
	return bar
end

local notifHost
local function ensureNotifHost()
	if notifHost and notifHost.Parent then return notifHost end
	notifHost = mk("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 320, 1, -32),
		Parent = hui(),
	})
	local l = list(notifHost, Enum.FillDirection.Vertical, 8)
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	l.HorizontalAlignment = Enum.HorizontalAlignment.Right
	return notifHost
end

function Noctro:Notify(opts)
	opts = opts or {}
	local host = ensureNotifHost()
	local title = opts.Title or opts.Name or "Noctro"
	local body = opts.Content or opts.Description or opts.Text or ""
	local dur = opts.Duration or 3.5
	local card = mk("Frame", {
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 300, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = host,
	})
	corner(card, 8)
	stroke(card, LINE, 1)
	pad(card, 14, 14, 12, 12)
	local accent = mk("Frame", {
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Parent = card,
	})
	corner(accent, 2)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 18),
		Position = UDim2.fromOffset(8, 0),
		Text = title,
		TextColor3 = TEXT,
		TextSize = 15,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(8, 22),
		Text = body,
		TextColor3 = DIM,
		TextSize = 13,
		FontFace = FONT_REG,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = card,
	})
	card.BackgroundTransparency = 1
	tween(card, { BackgroundTransparency = 0 }, 0.22)
	task.delay(dur, function()
		if card and card.Parent then
			tween(card, { BackgroundTransparency = 1 }, 0.18)
			task.wait(0.2)
			card:Destroy()
		end
	end)
end

local kbGui, kbList
local function ensureKeybindList()
	if kbGui and kbGui.Parent then return end
	kbGui = mk("Frame", {
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 120),
		Size = UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = hui(),
	})
	corner(kbGui, 8)
	stroke(kbGui, LINE, 1)
	pad(kbGui, 10, 10, 10, 10)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Keybinds",
		TextColor3 = TEXT,
		TextSize = 14,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = kbGui,
	})
	kbList = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = kbGui,
	})
	list(kbList, Enum.FillDirection.Vertical, 4)
	dragify(kbGui)
end

local function refreshKeybindList()
	ensureKeybindList()
	for _, c in ipairs(kbList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for _, kb in ipairs(Noctro.Keybinds) do
		local data = Noctro.Flags[kb.Flag]
		local active = type(data) == "table" and data.active
		local disp = (type(data) == "table" and data.key and data.key.Name) or kb.Display or "None"
		local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = kbList })
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.55, 0, 1, 0),
			Text = kb.Name or "Bind",
			TextColor3 = DIM,
			TextSize = 13,
			FontFace = FONT_REG,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.45, 0, 1, 0),
			Position = UDim2.fromScale(0.55, 0),
			Text = disp,
			TextColor3 = active and ACCENT or TEXT,
			TextSize = 13,
			FontFace = FONT,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
	end
end

function Noctro:KeybindList(state)
	ensureKeybindList()
	if state == nil then
		kbGui.Visible = not kbGui.Visible
	else
		kbGui.Visible = not not state
	end
	refreshKeybindList()
end

function Noctro:GetConfig()
	local out = {}
	for flag, val in pairs(Noctro.Flags) do
		if typeof(val) == "Color3" then
			out[flag] = { R = val.R, G = val.G, B = val.B, __color = true }
		elseif type(val) == "table" and val.key then
			out[flag] = { key = val.key and val.key.Name, mode = val.mode, active = val.active }
		else
			out[flag] = val
		end
	end
	return out
end

function Noctro:SetConfig(data)
	if type(data) ~= "table" then return end
	for flag, val in pairs(data) do
		if type(val) == "table" and val.__color then
			Noctro.Flags[flag] = Color3.new(val.R, val.G, val.B)
		else
			Noctro.Flags[flag] = val
		end
		local setter = Noctro._setters[flag]
		if setter then pcall(setter, Noctro.Flags[flag]) end
	end
end

function Noctro:SaveConfig(name)
	ensureFolders()
	name = tostring(name or "default")
	local path = Noctro.ConfigDir .. "/" .. name .. ".json"
	local ok, enc = pcall(HS.JSONEncode, HS, Noctro:GetConfig())
	if not ok then return false end
	return pcall(function() writefile(path, enc) end)
end

function Noctro:LoadConfig(name)
	ensureFolders()
	name = tostring(name or "default")
	local path = Noctro.ConfigDir .. "/" .. name .. ".json"
	local ok, raw = pcall(function() return readfile(path) end)
	if not ok or not raw then return false end
	local dok, data = pcall(HS.JSONDecode, HS, raw)
	if not dok or type(data) ~= "table" then return false end
	Noctro:SetConfig(data)
	return true
end

local function keyName(k)
	if not k then return "None" end
	if typeof(k) == "EnumItem" then return k.Name end
	return tostring(k)
end

function Noctro:Window(opts)
	opts = opts or {}
	local title = opts.Name or opts.name or "Noctro"
	local size = opts.Size or Vector2.new(714, 475)

	local sg = mk("ScreenGui", {
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Name = "Noctro",
	})
	protect(sg)
	mk("UIScale", { Scale = 1, Parent = sg })

	local main = mk("Frame", {
		Active = true,
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(120, 100),
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = sg,
	})
	corner(main, 15)
	dragify(main)

	local side = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 1, 0),
		Parent = main,
	})
	mk("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 10),
		Size = UDim2.fromOffset(63, 60),
		Image = "rbxassetid://81603686073386",
		Parent = side,
	})
	local tabScroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 75),
		Size = UDim2.new(0, 80, 1, -120),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = side,
	})
	list(tabScroll, Enum.FillDirection.Vertical, 5).HorizontalAlignment = Enum.HorizontalAlignment.Center

	local avatar = mk("ImageLabel", {
		BackgroundColor3 = BG2,
		Position = UDim2.new(0, 22, 1, -55),
		Size = UDim2.fromOffset(35, 35),
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", LP and LP.UserId or 1),
		Parent = side,
	})
	corner(avatar, 99)

	local content = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(80, 15),
		Size = UDim2.new(1, -95, 1, -30),
		Parent = main,
	})
	corner(content, 8)
	stroke(content, LINE, 1)

	local header = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = content,
	})
	local titleLbl = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(0.5, 0, 0, 24),
		Text = title,
		TextColor3 = TEXT,
		TextSize = 18,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local search = mk("TextBox", {
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(180, 26),
		PlaceholderText = "Search...",
		PlaceholderColor3 = DIM,
		Text = "",
		TextColor3 = TEXT,
		TextSize = 13,
		FontFace = FONT_REG,
		ClearTextOnFocus = false,
		Parent = header,
	})
	corner(search, 6)
	pad(search, 8, 8, 0, 0)

	local pages = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		ClipsDescendants = true,
		Parent = content,
	})

	buildWatermark(sg)

	local window = { Tabs = {}, Current = nil, Main = main, ScreenGui = sg }

	local function filterSearch(q)
		q = string.lower(q or "")
		for _, tab in ipairs(window.Tabs) do
			for _, sec in ipairs(tab.Sections or {}) do
				for _, row in ipairs(sec.Rows or {}) do
					if row.Root then
						local name = string.lower(row.Search or row.Name or "")
						row.Root.Visible = (q == "" or string.find(name, q, 1, true) ~= nil)
					end
				end
			end
		end
	end
	conn(search:GetPropertyChangedSignal("Text"), function()
		filterSearch(search.Text)
	end)

	function window:Tab(topts)
		topts = topts or {}
		local name = topts.Name or topts.name or "Tab"
		local icon = topts.Icon or topts.icon

		local tabBtn = mk("Frame", {
			BackgroundColor3 = BG2,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(50, 50),
			Parent = tabScroll,
		})
		corner(tabBtn, 3)
		local iconImg = mk("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 15),
			Size = UDim2.fromOffset(20, 20),
			Image = (type(icon) == "string" and tostring(icon):find("rbx") and icon) or "rbxassetid://136634011674328",
			ImageColor3 = DIM,
			Parent = tabBtn,
		})
		local hit = mk("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
			Parent = tabBtn,
		})

		local page = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = pages,
		})
		local left = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 9),
			Size = UDim2.new(0.5, -16, 1, -18),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = LINE,
			BorderSizePixel = 0,
			Parent = page,
		})
		list(left, Enum.FillDirection.Vertical, 10)
		local right = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 6, 0, 9),
			Size = UDim2.new(0.5, -16, 1, -18),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = LINE,
			BorderSizePixel = 0,
			Parent = page,
		})
		list(right, Enum.FillDirection.Vertical, 10)

		local tab = { Name = name, Page = page, Sections = {}, Button = tabBtn, Icon = iconImg, _side = 0 }

		local function selectTab()
			for _, t in ipairs(window.Tabs) do
				t.Page.Visible = false
				t.Button.BackgroundTransparency = 1
				t.Icon.ImageColor3 = DIM
			end
			page.Visible = true
			tabBtn.BackgroundTransparency = 0
			iconImg.ImageColor3 = ACCENT
			window.Current = tab
			titleLbl.Text = title .. "  ·  " .. name
		end
		conn(hit.MouseButton1Click, selectTab)

		function tab:Section(sopts)
			sopts = sopts or {}
			local sname = sopts.Name or sopts.name or "Section"
			local sideName = sopts.Side or sopts.side
			local parentCol
			if sideName == "Right" or sideName == "right" then
				parentCol = right
			elseif sideName == "Left" or sideName == "left" then
				parentCol = left
			else
				tab._side = (tab._side % 2) + 1
				parentCol = (tab._side == 1) and left or right
			end

			local box = mk("Frame", {
				BackgroundColor3 = BG2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = parentCol,
			})
			corner(box, 8)
			pad(box, 12, 12, 10, 10)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Text = sname,
				TextColor3 = TEXT,
				TextSize = 14,
				FontFace = FONT,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = box,
			})
			local body = mk("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = box,
			})
			list(body, Enum.FillDirection.Vertical, 8)

			local section = { Name = sname, Root = box, Body = body, Rows = {} }
			table.insert(tab.Sections, section)

			local function rowBase(label)
				local row = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 28),
					Parent = body,
				})
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.55, 0, 1, 0),
					Text = label,
					TextColor3 = DIM,
					TextSize = 13,
					FontFace = FONT_REG,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				return row
			end

			function section:Toggle(o)
				o = o or {}
				local n = o.Name or o.name or "Toggle"
				local flag = o.Flag or o.flag or n
				local def = o.Default
				if def == nil then def = o.default or false end
				local cb = o.Callback or o.callback or function() end
				Noctro.Flags[flag] = not not def
				local row = rowBase(n)
				local track = mk("Frame", {
					BackgroundColor3 = def and ACCENT or LINE,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(36, 18),
					BorderSizePixel = 0,
					Parent = row,
				})
				corner(track, 9)
				local knob = mk("Frame", {
					BackgroundColor3 = TEXT,
					Size = UDim2.fromOffset(14, 14),
					Position = def and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
					BorderSizePixel = 0,
					Parent = track,
				})
				corner(knob, 7)
				local btn = mk("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", Parent = row })
				local function set(v, silent)
					Noctro.Flags[flag] = not not v
					tween(track, { BackgroundColor3 = v and ACCENT or LINE }, 0.15)
					tween(knob, { Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }, 0.15)
					if not silent then task.spawn(cb, Noctro.Flags[flag]) end
				end
				Noctro._setters[flag] = function(v) set(v, true) end
				conn(btn.MouseButton1Click, function() set(not Noctro.Flags[flag]) end)
				local api = { Set = set, Flag = flag }
				table.insert(section.Rows, { Name = n, Search = n, Root = row, Api = api })
				return api
			end

			function section:Slider(o)
				o = o or {}
				local n = o.Name or o.name or "Slider"
				local flag = o.Flag or o.flag or n
				local min = tonumber(o.Min or o.min) or 0
				local max = tonumber(o.Max or o.max) or 100
				local def = tonumber(o.Default or o.default) or min
				local suffix = o.Suffix or o.suffix or ""
				local cb = o.Callback or o.callback or function() end
				def = math.clamp(def, min, max)
				Noctro.Flags[flag] = def
				local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = body })
				mk("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 16), Text = n,
					TextColor3 = DIM, TextSize = 13, FontFace = FONT_REG, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})
				local valL = mk("TextLabel", {
					BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0.4, 0, 0, 16), Text = tostring(def) .. suffix,
					TextColor3 = TEXT, TextSize = 13, FontFace = FONT, TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
				})
				local track = mk("Frame", {
					BackgroundColor3 = LINE, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 6),
					BorderSizePixel = 0, Parent = row,
				})
				corner(track, 3)
				local fill = mk("Frame", {
					BackgroundColor3 = ACCENT,
					Size = UDim2.new((def - min) / math.max(max - min, 1e-9), 0, 1, 0),
					BorderSizePixel = 0, Parent = track,
				})
				corner(fill, 3)
				local dragging = false
				local function apply(v, silent)
					v = math.clamp(v, min, max)
					Noctro.Flags[flag] = v
					fill.Size = UDim2.new((v - min) / math.max(max - min, 1e-9), 0, 1, 0)
					valL.Text = tostring(math.floor(v * 100 + 0.5) / 100) .. suffix
					if not silent then task.spawn(cb, v) end
				end
				Noctro._setters[flag] = function(v) apply(tonumber(v) or def, true) end
				conn(track.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
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
					local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
					apply(min + rel * (max - min))
				end)
				local api = { Set = apply, Flag = flag }
				table.insert(section.Rows, { Name = n, Search = n, Root = row, Api = api })
				return api
			end

			function section:Dropdown(o)
				o = o or {}
				local n = o.Name or o.name or "Dropdown"
				local flag = o.Flag or o.flag or n
				local items = o.Values or o.Options or o.items or o.options or {}
				local multi = o.MultiSelect or o.multi or false
				local def = o.Default or o.default
				local cb = o.Callback or o.callback or function() end
				if multi then
					Noctro.Flags[flag] = type(def) == "table" and def or {}
				else
					Noctro.Flags[flag] = def or items[1]
				end
				local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Parent = body })
				mk("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0), Text = n,
					TextColor3 = DIM, TextSize = 13, FontFace = FONT_REG, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})
				local box = mk("TextButton", {
					BackgroundColor3 = BG3, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0.55, 0, 0, 24),
					Text = multi and "Select..." or tostring(Noctro.Flags[flag] or "Select..."),
					TextColor3 = TEXT, TextSize = 12, FontFace = FONT_REG, AutoButtonColor = false, Parent = row,
				})
				corner(box, 6)
				local open = false
				local drop
				local function close()
					if drop then drop:Destroy() drop = nil end
					open = false
				end
				conn(box.MouseButton1Click, function()
					if open then close() return end
					open = true
					drop = mk("Frame", {
						BackgroundColor3 = BG, BorderSizePixel = 0,
						Position = UDim2.fromOffset(box.AbsolutePosition.X, box.AbsolutePosition.Y + box.AbsoluteSize.Y + 4),
						Size = UDim2.fromOffset(box.AbsoluteSize.X, math.min(28 * #items + 8, 160)),
						ZIndex = 50, Parent = sg,
					})
					corner(drop, 6)
					stroke(drop, LINE, 1)
					local sc = mk("ScrollingFrame", {
						BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
						CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 2, BorderSizePixel = 0, Parent = drop,
					})
					list(sc, Enum.FillDirection.Vertical, 2)
					pad(sc, 4, 4, 4, 4)
					for _, it in ipairs(items) do
						local b = mk("TextButton", {
							BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24),
							Text = "  " .. tostring(it), TextColor3 = TEXT, TextSize = 12,
							FontFace = FONT_REG, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Parent = sc,
						})
						conn(b.MouseButton1Click, function()
							if multi then
								local t = Noctro.Flags[flag]
								if type(t) ~= "table" then t = {} end
								local found
								for i, v in ipairs(t) do if v == it then found = i break end end
								if found then table.remove(t, found) else table.insert(t, it) end
								Noctro.Flags[flag] = t
								box.Text = #t > 0 and table.concat(t, ", ") or "Select..."
								task.spawn(cb, t)
							else
								Noctro.Flags[flag] = it
								box.Text = tostring(it)
								task.spawn(cb, it)
								close()
							end
						end)
					end
				end)
				Noctro._setters[flag] = function(v)
					Noctro.Flags[flag] = v
					if multi and type(v) == "table" then
						box.Text = #v > 0 and table.concat(v, ", ") or "Select..."
					else
						box.Text = tostring(v)
					end
				end
				table.insert(section.Rows, { Name = n, Search = n, Root = row })
				return { Flag = flag }
			end

			function section:Keybind(o)
				o = o or {}
				local n = o.Name or o.name or "Keybind"
				local flag = o.Flag or o.flag or n
				local def = o.Default or o.default or o.Key
				local mode = o.Mode or o.mode or "Toggle"
				local cb = o.Callback or o.callback or function() end
				Noctro.Flags[flag] = { key = def, mode = mode, active = false }
				local row = rowBase(n)
				local box = mk("TextButton", {
					BackgroundColor3 = BG3, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(72, 22), Text = keyName(def),
					TextColor3 = TEXT, TextSize = 12, FontFace = FONT, AutoButtonColor = false, Parent = row,
				})
				corner(box, 6)
				local listening = false
				conn(box.MouseButton1Click, function()
					listening = true
					box.Text = "..."
				end)
				conn(UIS.InputBegan, function(input)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							Noctro.Flags[flag].key = input.KeyCode
							box.Text = keyName(input.KeyCode)
							listening = false
							refreshKeybindList()
						end
						return
					end
					local data = Noctro.Flags[flag]
					if not data or not data.key then return end
					if input.KeyCode == data.key then
						if mode == "Hold" then
							data.active = true
							task.spawn(cb, true)
						else
							data.active = not data.active
							task.spawn(cb, data.active)
						end
						refreshKeybindList()
					end
				end)
				conn(UIS.InputEnded, function(input)
					local data = Noctro.Flags[flag]
					if data and mode == "Hold" and data.key and input.KeyCode == data.key then
						data.active = false
						task.spawn(cb, false)
						refreshKeybindList()
					end
				end)
				table.insert(Noctro.Keybinds, { Name = n, Display = keyName(def), Flag = flag })
				refreshKeybindList()
				table.insert(section.Rows, { Name = n, Search = n, Root = row })
				return { Flag = flag }
			end

			function section:Button(o)
				o = o or {}
				local n = o.Name or o.name or "Button"
				local cb = o.Callback or o.callback or function() end
				local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Parent = body })
				local b = mk("TextButton", {
					BackgroundColor3 = BG3, Size = UDim2.fromScale(1, 1), Text = n,
					TextColor3 = TEXT, TextSize = 13, FontFace = FONT, AutoButtonColor = false, Parent = row,
				})
				corner(b, 6)
				conn(b.MouseButton1Click, function()
					tween(b, { BackgroundColor3 = ACCENT }, 0.08)
					task.delay(0.12, function() tween(b, { BackgroundColor3 = BG3 }, 0.15) end)
					task.spawn(cb)
				end)
				table.insert(section.Rows, { Name = n, Search = n, Root = row })
				return {}
			end

			function section:Textbox(o)
				o = o or {}
				local n = o.Name or o.name or "Textbox"
				local flag = o.Flag or o.flag or n
				local def = o.Default or o.default or ""
				local ph = o.Placeholder or o.placeholder or "..."
				local cb = o.Callback or o.callback or function() end
				Noctro.Flags[flag] = def
				local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = body })
				mk("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Text = n,
					TextColor3 = DIM, TextSize = 13, FontFace = FONT_REG, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})
				local box = mk("TextBox", {
					BackgroundColor3 = BG3, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24),
					Text = tostring(def), PlaceholderText = ph, PlaceholderColor3 = DIM,
					TextColor3 = TEXT, TextSize = 12, FontFace = FONT_REG, ClearTextOnFocus = false, Parent = row,
				})
				corner(box, 6)
				pad(box, 8, 8, 0, 0)
				conn(box.FocusLost, function()
					Noctro.Flags[flag] = box.Text
					task.spawn(cb, box.Text)
				end)
				Noctro._setters[flag] = function(v) box.Text = tostring(v) Noctro.Flags[flag] = v end
				table.insert(section.Rows, { Name = n, Search = n, Root = row })
				return { Flag = flag }
			end

			function section:Colorpicker(o)
				o = o or {}
				local n = o.Name or o.name or "Color"
				local flag = o.Flag or o.flag or n
				local def = o.Default or o.default or o.Color or ACCENT
				local cb = o.Callback or o.callback or function() end
				Noctro.Flags[flag] = def
				local row = rowBase(n)
				local swatch = mk("TextButton", {
					BackgroundColor3 = def, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(28, 18), Text = "", AutoButtonColor = false, Parent = row,
				})
				corner(swatch, 4)
				stroke(swatch, LINE, 1)
				local palette = {
					ACCENT, Color3.fromRGB(80, 160, 255), Color3.fromRGB(80, 220, 120),
					Color3.fromRGB(255, 180, 60), Color3.fromRGB(180, 100, 255), Color3.fromRGB(255, 255, 255),
				}
				local idx = 1
				conn(swatch.MouseButton1Click, function()
					idx = (idx % #palette) + 1
					local c = palette[idx]
					Noctro.Flags[flag] = c
					swatch.BackgroundColor3 = c
					task.spawn(cb, c)
				end)
				Noctro._setters[flag] = function(v)
					if typeof(v) == "Color3" then Noctro.Flags[flag] = v swatch.BackgroundColor3 = v end
				end
				table.insert(section.Rows, { Name = n, Search = n, Root = row })
				return { Flag = flag }
			end

			function section:Label(o)
				o = o or {}
				local text = o.Name or o.name or o.Text or "Label"
				local row = mk("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Text = text,
					TextColor3 = DIM, TextSize = 12, FontFace = FONT_REG, TextXAlignment = Enum.TextXAlignment.Left, Parent = body,
				})
				table.insert(section.Rows, { Name = text, Search = text, Root = row })
				return {}
			end

			return section
		end

		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then selectTab() end
		return tab
	end

	function window:AddConfigTab()
		local t = self:Tab({ Name = "Config", Icon = "rbxassetid://80758916183665" })
		local s = t:Section({ Name = "Configs", Side = "Left" })
		s:Textbox({ Name = "Config name", Flag = "cfg_name", Default = "default", Placeholder = "name" })
		s:Button({
			Name = "Save config",
			Callback = function()
				local n = Noctro.Flags.cfg_name or "default"
				if Noctro:SaveConfig(n) then
					Noctro:Notify({ Title = "Noctro", Content = "Saved " .. n })
				else
					Noctro:Notify({ Title = "Noctro", Content = "Save failed" })
				end
			end,
		})
		s:Button({
			Name = "Load config",
			Callback = function()
				local n = Noctro.Flags.cfg_name or "default"
				if Noctro:LoadConfig(n) then
					Noctro:Notify({ Title = "Noctro", Content = "Loaded " .. n })
				else
					Noctro:Notify({ Title = "Noctro", Content = "Load failed" })
				end
			end,
		})
		local s2 = t:Section({ Name = "Keybind list", Side = "Right" })
		s2:Button({
			Name = "Toggle keybind list",
			Callback = function() Noctro:KeybindList() end,
		})
		return t
	end

	table.insert(Noctro.Windows, window)
	return window
end

getgenv().Noctro = Noctro
return Noctro
