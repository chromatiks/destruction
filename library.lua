-- Noctro UI
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local run = game:GetService("RunService")
local stats = game:GetService("Stats")
local coregui = game:GetService("CoreGui")
local function get_hui()
    local h
    pcall(function()
        if gethui then h = gethui() end
    end)
    if typeof(h) == "Instance" then return h end
    pcall(function()
        h = game:GetService("CoreGui")
    end)
    if typeof(h) == "Instance" then return h end
    pcall(function()
        local lp = players.LocalPlayer
        if lp then h = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5) end
    end)
    return h or coregui
end
local tween_service = game:GetService("TweenService")
local marketplace = game:GetService("MarketplaceService")
local text_service = game:GetService("TextService")
local content_provider = game:GetService("ContentProvider")

local vec2 = Vector2.new
local dim2 = UDim2.new
local dim = UDim.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = gui_service:GetGuiInset().Y

local clamp = math.clamp
local floor = math.floor
local min = math.min
local max = math.max
local abs = math.abs

local insert = table.insert
local find = table.find
local remove = table.remove
local concat = table.concat

getgenv().Noctro = getgenv().Noctro or {}
local library = {
    directory = "Noctro",
    folders = {
        "/fonts",
        "/configs",
        "/assets",
    },
    flags = {},
    config_flags = {},
    connections = {},
    notifications = { notifs = {} },
    current_open = nil,
    version = "1.6.0-glacier",
    theme_dirty = false,
    silent = false,
    MenuKeybind = Enum.KeyCode.LeftAlt,
    MenuKeyName = "LAlt",
    keybind_registry = {},
    KeybindListInstance = nil,
    EspPreviewInstance = nil,
    author = "glacier",
}

library.__index = library

local function ensure_folders()
    for _, path in next, library.folders do
        pcall(makefolder, library.directory .. path)
    end
end
ensure_folders()

function library:SetConfigDirectory(path)
    if type(path) ~= "string" or path == "" then return end

    path = path:gsub("^/+", ""):gsub("/+$", "")
    library.directory = path
    ensure_folders()
end

local flags = library.flags
local config_flags = library.config_flags
local notifications = library.notifications

local themes = {
    preset = {
        accent = rgb(200, 72, 78),
        background = rgb(14, 14, 16),
        section = rgb(22, 22, 24),
        element = rgb(25, 25, 29),
        light = rgb(33, 33, 35),
        hover = rgb(39, 39, 43),
        line = rgb(21, 21, 23),
        text = rgb(255, 255, 255),
        dimtext = rgb(160, 160, 165),
        dimicon = rgb(140, 140, 145),
    },
    utility = {
        accent = {
            BackgroundColor3 = {},
            TextColor3 = {},
            ImageColor3 = {},
            ScrollBarImageColor3 = {},
            Color = {},
        },
    },
}

local keys = {
    [Enum.KeyCode.LeftShift] = "LS",
    [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC",
    [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent",
    [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA",
    [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.KeypadOne] = "Num1",
    [Enum.KeyCode.KeypadTwo] = "Num2",
    [Enum.KeyCode.KeypadThree] = "Num3",
    [Enum.KeyCode.KeypadFour] = "Num4",
    [Enum.KeyCode.KeypadFive] = "Num5",
    [Enum.KeyCode.KeypadSix] = "Num6",
    [Enum.KeyCode.KeypadSeven] = "Num7",
    [Enum.KeyCode.KeypadEight] = "Num8",
    [Enum.KeyCode.KeypadNine] = "Num9",
    [Enum.KeyCode.KeypadZero] = "Num0",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.Tilde] = "~",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.RightParenthesis] = ")",
    [Enum.KeyCode.LeftParenthesis] = "(",
    [Enum.KeyCode.Semicolon] = ";",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Asterisk] = "*",
    [Enum.KeyCode.Plus] = "+",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
    [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC",
}

local fonts = {}
do
    local function Register_Font(Name, Weight, Style, Asset)
        local path = library.directory .. "/fonts/" .. Asset.Id
        if not isfile(path) then
            pcall(function()
                writefile(path, Asset.Font)
            end)
        end

        local jsonPath = library.directory .. "/fonts/" .. Name .. ".font"
        pcall(delfile, jsonPath)

        local Data = {
            name = Name,
            faces = {
                {
                    name = "Normal",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(path),
                },
            },
        }

        writefile(jsonPath, http_service:JSONEncode(Data))
        return getcustomasset(jsonPath)
    end

    local function withTimeout(fn, timeoutSec)
        local done, result = false, nil
        task.spawn(function()
            local ok, r = pcall(fn)
            if ok then result = r end
            done = true
        end)
        local start = tick()
        while not done and (tick() - start) < timeoutSec do
            task.wait(0.03)
        end
        return result
    end

    local fallbackFamily = Font.fromEnum(Enum.Font.GothamMedium).Family
    fonts = {
        small = Font.new(fallbackFamily, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        font = Font.new(fallbackFamily, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }

    local Medium = withTimeout(function()
        return Register_Font("Medium", 200, "Normal", {
            Id = "Medium.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"), -- Upload the font to your own github incase of deletion.

        })
    end, 4)
    if Medium then
        fonts.small = Font.new(Medium, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end

    local SemiBold = withTimeout(function()
        return Register_Font("SemiBold", 200, "Normal", {
            Id = "SemiBold.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"), -- Upload the font to your own github incase of deletion.

        })
    end, 4)
    if SemiBold then
        fonts.font = Font.new(SemiBold, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end
end

local IconPack
do
    local done = false
    task.spawn(function()
        pcall(function()
            local Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
            IconPack = loadstring(game:HttpGetAsync(Url))()
            IconPack.SetIconsType("lucide")
        end)
        done = true
    end)
    local start = tick()
    while not done and (tick() - start) < 4 do
        task.wait(0.03)
    end
end

local function ResolveIcon(Icon)
    if type(Icon) == "number" then
        return "rbxassetid://" .. Icon
    end
    if type(Icon) ~= "string" then
        return "rbxassetid://0"
    end
    if string.match(Icon, "^rbxassetid://") or string.match(Icon, "^rbxasset://") then
        return Icon
    end
    if string.match(Icon, "^%d+$") then
        return "rbxassetid://" .. Icon
    end
    if IconPack then
        local Ok, Result = pcall(function()
            return IconPack.GetIcon(Icon)
        end)
        if Ok and Result and Result ~= "rbxassetid://0" then
            return Result
        end
    end
    return "rbxassetid://0"
end

local function ApplyIcon(Object, Icon)
    if not Icon then return end
    local Image = ResolveIcon(Icon)
    Object.Image = Image
end

function library.LoadEmblemLogo()
    if library._logoAsset and library._logoUrl == "https://raw.githubusercontent.com/chromatiks/Acen/main/EmblemBanners.png" then
        return library._logoAsset
    end
    library._logoUrl = "https://raw.githubusercontent.com/chromatiks/Acen/main/EmblemBanners.png"
    task.spawn(function()
        pcall(function()
            local data = game:HttpGet("https://raw.githubusercontent.com/chromatiks/Acen/main/EmblemBanners.png")
            if type(data) == "string" and #data > 80 then
                pcall(function()
                    if makefolder then makefolder("Emblem") end
                    writefile("Emblem/logo.png", data)
                end)
                local ok, id = pcall(function() return getcustomasset("Emblem/logo.png") end)
                if ok and id then
                    library._logoAsset = id
                    pcall(function()
                        if library._logoTargets then
                            for _, img in ipairs(library._logoTargets) do
                                if img then img.Image = id img.ImageColor3 = Color3.fromRGB(255,255,255) end
                            end
                        end
                    end)
                end
            end
        end)
    end)
    return library._logoAsset
end

function library:tween(obj, properties, easing_style, time)
    local tween = tween_service:Create(
        obj,
        TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0),
        properties
    )
    tween:Play()
    return tween
end

function library:connection(signal, callback)
    local connection = signal:Connect(callback)
    insert(library.connections, connection)
    return connection
end

function library:create(instance, options)
    local ins = Instance.new(instance)
    if type(options) == "table" then
        for prop, value in pairs(options) do
            pcall(function()
                ins[prop] = value
            end)
        end
    end
    return ins
end

function library:round(number, float)
    local multiplier = 1 / (float or 1)
    return floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
    if not instance then return end
    local bucket = themes.utility[theme] and themes.utility[theme][property]
    if not bucket then

        if themes.utility[theme] then
            themes.utility[theme][property] = {}
            bucket = themes.utility[theme][property]
        else
            return
        end
    end
    insert(bucket, instance)
end

function library:update_theme(theme, color)

    local buckets = themes.utility[theme]
    if buckets then
        for property_name, bucket in pairs(buckets) do
            for i = #bucket, 1, -1 do
                local object = bucket[i]
                if object and object.Parent then
                    pcall(function()
                        object[property_name] = color
                    end)
                else
                    table.remove(bucket, i)
                end
            end
        end
    end
    themes.preset[theme] = color

    if theme == "accent" then
        pcall(function()
            if library._active_tab_icon and library._active_tab_icon.Parent then
                library._active_tab_icon.ImageColor3 = color
            end
        end)
        if library._toggle_hooks then
            for _, switch in pairs(library._toggle_hooks) do
                if switch and switch.Parent then
                    pcall(function()
                        if switch.BackgroundTransparency and switch.BackgroundTransparency < 1 then
                            switch.BackgroundColor3 = color
                        end
                    end)
                end
            end
        end
        -- refresh selected tab button tint
        pcall(function()
            if library.selected_tab and library.selected_tab[1] then
                library.selected_tab[1].BackgroundColor3 = color
            end
        end)
        pcall(function()
            if library._lastSidebarTab and library._lastSidebarTab.items and library._lastSidebarTab.items.button then
                -- no-op; open_tab handles
            end
        end)
    end
end

function library:close_element(new_path)
    local open_element = library.current_open
    if open_element and new_path ~= open_element then
        if open_element.set_visible then
            open_element.set_visible(false)
        end
        open_element.open = false
    end
    if new_path ~= open_element then
        library.current_open = new_path or nil
    end
end

function library:mouse_in_frame(uiobject)
    local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
    local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
    return (y_cond and x_cond)
end

function library:draggify(frame)
    local dragging = false
    local start_size = frame.Position
    local start

    frame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local relY = input.Position.Y - frame.AbsolutePosition.Y
        if relY > 56 then return end
        dragging = true
        start = input.Position
        start_size = frame.Position
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            local aw = math.max(frame.AbsoluteSize.X, 50)
            local ah = math.max(frame.AbsoluteSize.Y, 50)
            local nx = start_size.X.Offset + (input.Position.X - start.X)
            local ny = start_size.Y.Offset + (input.Position.Y - start.Y)
            nx = clamp(nx, 0, math.max(0, viewport_x - aw))
            ny = clamp(ny, 0, math.max(0, viewport_y - ah))
            frame.Position = dim2(0, nx, 0, ny)
            library:close_element()
            pcall(function()
                local esp = library.EspPreviewInstance
                if esp and type(esp.DockToMain) == "function" then
                    esp.DockToMain()
                end
            end)
        end
    end)
end

function library:resizify(frame)
    local Frame = Instance.new("TextButton")
    Frame.Position = dim2(1, -10, 1, -10)
    Frame.Size = dim2(0, 10, 0, 10)
    Frame.BackgroundTransparency = 1
    Frame.Text = ""
    Frame.Parent = frame

    local resizing = false
    local start_size
    local start
    local og_size = frame.Size

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            start = input.Position
            start_size = frame.Size
        end
    end)

    Frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x = camera.ViewportSize.X
            local viewport_y = camera.ViewportSize.Y
            local minW = math.max(og_size.X.Offset * 0.55, 320)
            local minH = math.max(og_size.Y.Offset * 0.55, 280)
            local newW = clamp(start_size.X.Offset + (input.Position.X - start.X), minW, viewport_x - 8)
            local aspect = (og_size.Y.Offset > 0) and (og_size.Y.Offset / og_size.X.Offset) or (565 / 700)
            local newH = clamp(newW * aspect, minH, viewport_y - 8)
            frame.Size = dim2(0, newW, 0, newH)
        end
    end)
end

function library:next_flag()
    local index = 0
    for _ in flags do
        index = index + 1
    end
    return string.format("flagnumber%s", index + 1)
end

function library:convert(str)
    local values = {}
    for value in string.gmatch(str, "[^,]+") do
        insert(values, tonumber(value))
    end
    if #values == 4 then
        return unpack(values)
    end
end

function library:convert_enum(enum)
    local enum_parts = {}
    for part in string.gmatch(enum, "[%w_]+") do
        insert(enum_parts, part)
    end
    local enum_table = Enum
    for i = 2, #enum_parts do
        enum_table = enum_table[enum_parts[i]]
    end
    return enum_table
end

function library:unload_menu()
    if library.KeybindListInstance then
        pcall(function()
            if library.KeybindListInstance.Destroy then
                library.KeybindListInstance.Destroy()
            elseif library.KeybindListInstance.Gui then
                library.KeybindListInstance.Gui:Destroy()
            end
        end)
        library.KeybindListInstance = nil
    end
    if library.EspPreviewInstance then
        pcall(function()
            if library.EspPreviewInstance.Destroy then
                library.EspPreviewInstance.Destroy()
            elseif library.EspPreviewInstance.Gui then
                library.EspPreviewInstance.Gui:Destroy()
            end
        end)
        library.EspPreviewInstance = nil
    end
    library.keybind_registry = {}
    if library["items"] then
        library["items"]:Destroy()
    end
    if library["other"] then
        library["other"]:Destroy()
    end
    if library["watermark_gui"] then
        library["watermark_gui"]:Destroy()
    end
    for _, connection in library.connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    getgenv().Noctro = nil
    getgenv().Noctro = nil
end

function library:get_config(Created)
    local Config = {}
    for _, v in next, flags do
        if type(v) == "table" and v.key then
            Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
        elseif type(v) == "table" and v["Transparency"] and v["Color"] then
            Config[_] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
        else
            Config[_] = v
        end
    end

    Config.__accent = themes.preset.accent:ToHex()
    Config.__created = Created or os.date("%d.%m.%Y %H:%M")
    Config.__version = library.version
    Config.__creator = lp.DisplayName

    return http_service:JSONEncode(Config)
end

function library:load_config(config_json)
    local Ok, config = pcall(function()
        return http_service:JSONDecode(config_json)
    end)
    if not Ok or type(config) ~= "table" then
        return false
    end

    library.silent = true
    for _, v in config do
        local function_set = library.config_flags[_]
        if not function_set then
            continue
        end
        if type(v) == "table" and v["Transparency"] and v["Color"] then
            function_set(hex(v["Color"]), v["Transparency"])
        elseif type(v) == "table" and v["active"] then
            function_set(v)
        else
            function_set(v)
        end
    end

    if type(config.__accent) == "string" then
        local OkColor, Color = pcall(hex, config.__accent)
        if OkColor then
            library:update_theme("accent", Color)
        end
    end

    library.silent = false
    return true
end

function library:SaveConfigFile(Name)
    if not writefile then
        return false
    end
    writefile(library.directory .. "/configs/" .. Name .. ".json", library:get_config())
    return true
end

function library:LoadConfigFile(Name)
    if not isfile then
        return false
    end
    local Path = library.directory .. "/configs/" .. Name .. ".json"
    if not isfile(Path) then
        return false
    end
    return library:load_config(readfile(Path))
end

function library:ListConfigs()
    local Result = {}
    if not listfiles then
        return Result
    end
    for _, File in listfiles(library.directory .. "/configs") do
        if string.sub(File, -5) ~= ".json" then
            continue
        end
        local Name = string.match(File, "([^/\\]+)%.json$")
        if Name then
            insert(Result, Name)
        end
    end
    return Result
end

function library:window(properties)
    local cfg = {
        suffix = properties.suffix or properties.Suffix or "",
        name = properties.name or properties.Name or "Noctro",
        game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Noctro for Roblox",
        author = properties.author or properties.Author or library.author or "Noctro",
        size = properties.size or properties.Size or dim2(0, 820, 0, 460),
        selected_tab = nil,
        items = {},
    }

    if properties.author or properties.Author then
        library.author = cfg.author
    end

    library["items"] = library:create("ScreenGui", {
        Parent = get_hui(),
        Name = "\0",
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })

    library["other"] = library:create("ScreenGui", {
        Parent = get_hui(),
        Name = "\0",
        Enabled = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    library["cache"] = library:create("Folder", {
        Parent = library["other"],
        Name = "\0",
    })

    local items = cfg.items
    do
        items["main"] = library:create("Frame", {
            Parent = library["items"],
            Size = cfg.size,
            Name = "\0",
            Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })
        items["main"].Position = dim2(0, items["main"].AbsolutePosition.X, 0, items["main"].AbsolutePosition.Y)

        library:create("UICorner", {
            Parent = items["main"],
            CornerRadius = dim(0, 10),
        })

        library:create("UIStroke", {
            Color = rgb(23, 23, 29),
            Parent = items["main"],
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })

        items["side_frame"] = library:create("Frame", {
            Parent = items["main"],
            BackgroundTransparency = 1,
            Name = "\0",
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 72, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
        })

        library:create("Frame", {
            AnchorPoint = vec2(1, 0),
            Parent = items["side_frame"],
            Position = dim2(1, 0, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(0, 1, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })

        items["button_holder"] = library:create("ScrollingFrame", {
            Parent = items["side_frame"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 70),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, -80),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = dim2(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = rgb(60, 60, 66),
            Active = true,
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.button_holder = items["button_holder"]

        items["search_btn"] = library:create("Frame", {
            Parent = items["main"],
            BackgroundColor3 = themes.preset.element,
            Position = dim2(0, 86, 0, 12),
            Size = dim2(0, 280, 0, 34),
            BorderSizePixel = 0,
            ZIndex = 20,
        })
        library:create("UICorner", { Parent = items["search_btn"], CornerRadius = dim(0, 8) })
        library:create("UIStroke", { Parent = items["search_btn"], Color = rgb(48,48,54), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        local sic = library:create("ImageLabel", {
            Parent = items["search_btn"], BackgroundTransparency = 1,
            Size = dim2(0, 14, 0, 14), Position = dim2(0, 10, 0.5, -7),
            ImageColor3 = themes.preset.dimtext, BorderSizePixel = 0,
            Image = "rbxassetid://6031094678",
            ZIndex = 22,
        })
        pcall(function() if ApplyIcon then ApplyIcon(sic, "search") end end)
        local searchBox = library:create("TextBox", {
            Parent = items["search_btn"],
            BackgroundTransparency = 1,
            Position = dim2(0, 32, 0, 0),
            Size = dim2(1, -40, 1, 0),
            ZIndex = 22,
            PlaceholderText = "Search...",
            PlaceholderColor3 = themes.preset.dimtext,
            Text = "",
            TextColor3 = rgb(255, 255, 255),
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            FontFace = fonts.font,
            TextSize = 13,
            TextEditable = true,
            Active = true,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, BorderSizePixel = 0, ZIndex = 9,
        })
        items["search_box"] = searchBox
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(searchBox.Text or "")
            if library.OpenSearch and q == "" then return end
            -- light filter: open search popup when user presses enter handled below
        end)
        searchBox.FocusLost:Connect(function(enter)
            if enter and library.OpenSearch then
                library.OpenSearch()
            end
        end)
        pcall(function()
            items["search_btn"].InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    searchBox:CaptureFocus()
                end
            end)
        end)

        library:create("UIListLayout", {
            Parent = items["button_holder"],
            Padding = dim(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        })
        library:create("UIPadding", {
            Parent = items["button_holder"],
            PaddingTop = dim(0, 4),
            PaddingLeft = dim(0, 6),
            PaddingRight = dim(0, 6),
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 16),
            PaddingBottom = dim(0, 36),
            Parent = items["button_holder"],
            PaddingRight = dim(0, 11),
            PaddingLeft = dim(0, 10),
        })

        items["title"] = library:create("Frame", {
            Parent = items["side_frame"],
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 70),
            BorderSizePixel = 0,
        })
        items["title_icon"] = library:create("ImageLabel", {
            Parent = items["title"],
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 48, 0, 48),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ImageColor3 = rgb(255, 255, 255),
            ScaleType = Enum.ScaleType.Fit,
        })
        pcall(function()
            if ApplyIcon then ApplyIcon(items["title_icon"], cfg.icon or "layers") end
        end)
        library._logoTargets = library._logoTargets or {}
        table.insert(library._logoTargets, items["title_icon"])
        pcall(function() library.LoadEmblemLogo() end)
        pcall(function()
            items["title_icon"].ImageColor3 = rgb(255, 255, 255)
            items["title_icon"].Size = dim2(0, 28, 0, 28)
        end)
        pcall(function()
            local id = library.LoadEmblemLogo and library.LoadEmblemLogo()
            if id then items["title_icon"].Image = id items["title_icon"].ImageColor3 = rgb(255,255,255) end
        end)

        items["multi_holder"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 72, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -92, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        cfg.multi_holder = items["multi_holder"]

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["multi_holder"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.line,
        })

        items["profile_btn"] = library:create("TextButton", {
            Parent = items["multi_holder"], Name = "\0", Text = "", AutoButtonColor = false,
            BackgroundTransparency = 1, AnchorPoint = vec2(1, 0.5),
            Position = dim2(1, -14, 0.5, 0), Size = dim2(0, 32, 0, 32), ZIndex = 6, BorderSizePixel = 0,
        })
        items["profile_avatar"] = library:create("ImageLabel", {
            Parent = items["profile_btn"], Name = "\0", BackgroundColor3 = themes.preset.light,
            Size = dim2(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 6,
        })
        library:create("UICorner", { Parent = items["profile_avatar"], CornerRadius = dim(1, 0) })

        items["profile_ring"] = library:create("UIStroke", {
            Parent = items["profile_avatar"], Color = themes.preset.accent, Thickness = 1.5,
        })
        library:apply_theme(items["profile_ring"], "accent", "Color")
        task.spawn(function()
            local ok, content = pcall(function()
                return players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok and content then items["profile_avatar"].Image = content end
        end)

        local profileOpen = false
        local profilePopup = library:create("Frame", {
            Parent = items["main"], Name = "\0", Size = dim2(0, 240, 0, 0),
            BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, Visible = false,
            ZIndex = 80, ClipsDescendants = true, AnchorPoint = vec2(1, 0), Position = dim2(1, -10, 0, 56),
        })
        library:create("UICorner", { Parent = profilePopup, CornerRadius = dim(0, 10) })

        local function rebuildProfile()
            for _, ch in profilePopup:GetChildren() do
                if not ch:IsA("UICorner") then ch:Destroy() end
            end
            local display = lp.DisplayName or lp.Name
            local uname = "@" .. (lp.Name or "unknown")
            local uid = tostring(lp.UserId or 0)
            local age = "Unknown"
            pcall(function() age = tostring(lp.AccountAge or 0) .. " days" end)

            local bigAv = library:create("ImageLabel", {
                Parent = profilePopup, BackgroundColor3 = themes.preset.light,
                Position = dim2(0, 14, 0, 14), Size = dim2(0, 42, 0, 42),
                BorderSizePixel = 0, Image = items["profile_avatar"].Image, ZIndex = 81,
            })
            library:create("UICorner", { Parent = bigAv, CornerRadius = dim(1, 0) })
            local bigRing = library:create("UIStroke", { Parent = bigAv, Color = themes.preset.accent, Thickness = 1.5 })
            library:apply_theme(bigRing, "accent", "Color")

            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = display, TextSize = 15,
                TextColor3 = themes.preset.text, BackgroundTransparency = 1,
                Position = dim2(0, 66, 0, 16), Size = dim2(1, -80, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = uname, TextSize = 13,
                TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                Position = dim2(0, 66, 0, 36), Size = dim2(1, -80, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            local function infoRow(y, lab, val)
                library:create("TextLabel", {
                    Parent = profilePopup, FontFace = fonts.font, Text = lab, TextSize = 13,
                    TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                    Position = dim2(0, 14, 0, y), Size = dim2(0, 100, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
                })
                library:create("TextLabel", {
                    Parent = profilePopup, FontFace = fonts.font, Text = val, TextSize = 13,
                    TextColor3 = themes.preset.text, BackgroundTransparency = 1,
                    Position = dim2(0, 110, 0, y), Size = dim2(1, -124, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0, ZIndex = 81,
                })
            end
            infoRow(68, "User ID", uid)
            infoRow(90, "Account age", age)

            library:create("TextLabel", {
                Parent = profilePopup, FontFace = fonts.font, Text = "Menu toggle", TextSize = 13,
                TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
                Position = dim2(0, 14, 0, 118), Size = dim2(0, 100, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 81,
            })
            local currentKey = library.MenuKeybind or Enum.KeyCode.RightControl
            local keyName = library.MenuKeyName or keys[currentKey] or (typeof(currentKey) == "EnumItem" and currentKey.Name) or "RCtrl"
            local keyBox = library:create("TextButton", {
                Parent = profilePopup, FontFace = fonts.font, Text = keyName, TextSize = 12,
                TextColor3 = themes.preset.text, AutoButtonColor = false,
                BackgroundColor3 = themes.preset.light,
                Position = dim2(1, -70, 0, 114), Size = dim2(0, 56, 0, 22),
                BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("UICorner", { Parent = keyBox, CornerRadius = dim(0, 4) })
            library.ProfileKeyBox = keyBox
            local binding = false
            keyBox.MouseButton1Click:Connect(function()
                if binding then return end
                binding = true
                keyBox.Text = "..."
                local conn
                conn = uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        library.MenuKeybind = input.KeyCode
                        local nm = keys[input.KeyCode] or input.KeyCode.Name
                        keyBox.Text = nm
                        if config_flags["menu_bind"] then
                            pcall(function() config_flags["menu_bind"](input.KeyCode) end)
                        end
                        binding = false
                        conn:Disconnect()
                    end
                end)
            end)

            local unloadBtn = library:create("TextButton", {
                Parent = profilePopup, FontFace = fonts.font, Text = "Unload", TextSize = 14,
                TextColor3 = themes.preset.text, AutoButtonColor = false,
                BackgroundColor3 = themes.preset.light,
                Position = dim2(0, 14, 0, 150), Size = dim2(1, -28, 0, 30),
                BorderSizePixel = 0, ZIndex = 81,
            })
            library:create("UICorner", { Parent = unloadBtn, CornerRadius = dim(0, 6) })
            unloadBtn.MouseButton1Click:Connect(function()
                library:Notification({ Name = "Unloading", Description = "Noctro is shutting down.", Icon = "power" })
                task.delay(0.35, function() library:unload_menu() end)
            end)
        end

        local function setProfileVisible(bool)
            profileOpen = bool
            if bool then
                rebuildProfile()
                profilePopup.Size = dim2(0, 240, 0, 0)
                profilePopup.BackgroundTransparency = 1
                profilePopup.Visible = true
                library:tween(profilePopup, { Size = dim2(0, 240, 0, 194), BackgroundTransparency = 0 }, Enum.EasingStyle.Quint, 0.22)
            else
                library:tween(profilePopup, { Size = dim2(0, 240, 0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, 0.18)
                task.delay(0.2, function()
                    if not profileOpen then profilePopup.Visible = false end
                end)
            end
        end

        items["profile_btn"].MouseButton1Click:Connect(function()
            setProfileVisible(not profileOpen)
        end)

        library:connection(uis.InputBegan, function(input)
            if not profileOpen then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local pos = input.Position
            local pAbs, pSize = profilePopup.AbsolutePosition, profilePopup.AbsoluteSize
            local bAbs, bSize = items["profile_btn"].AbsolutePosition, items["profile_btn"].AbsoluteSize
            local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
            local overBtn = pos.X >= bAbs.X and pos.X <= bAbs.X + bSize.X and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSize.Y
            if not overPopup and not overBtn then setProfileVisible(false) end
        end)

        items["shadow"] = library:create("ImageLabel", {
            ImageColor3 = rgb(0, 0, 0),
            ScaleType = Enum.ScaleType.Slice,
            Parent = items["main"],
            BorderColor3 = rgb(0, 0, 0),
            Name = "\0",
            BackgroundColor3 = rgb(255, 255, 255),
            Size = dim2(1, 75, 1, 75),
            AnchorPoint = vec2(0.5, 0.5),
            Image = "rbxassetid://112971167999062",
            BackgroundTransparency = 1,
            Position = dim2(0.5, 0, 0.5, 0),
            SliceScale = 0.75,
            ZIndex = -100,
            BorderSizePixel = 0,
            SliceCenter = Rect.new(vec2(112, 112), vec2(147, 147)),
        })

        items["global_fade"] = library:create("Frame", {
            Parent = items["main"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 80, 0, 52),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -92, 1, -60),
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.background,
            ZIndex = 2,
        })

        library:create("UICorner", {
            Parent = items["shadow"],
            CornerRadius = dim(0, 5),
        })

        items["info"] = library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["main"],
            Name = "\0",
            Visible = false,
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        library:create("UICorner", {
            Parent = items["info"],
            CornerRadius = dim(0, 10),
        })

        items["grey_fill"] = library:create("Frame", {
            Name = "\0",
            Parent = items["info"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 6),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(23, 23, 25),
        })

        items["game"] = library:create("TextLabel", {
            FontFace = fonts.font,
            Parent = items["info"],
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.game_name,
            Name = "\0",
            Size = dim2(1, 0, 0, 0),
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 10, 0.5, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        items["other_info"] = library:create("TextLabel", {
            Parent = items["info"],
            RichText = true,
            Name = "\0",
            TextColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Text = string.format('<font color="rgb(72, 72, 73)">%s, </font>%s%s', cfg.author or library.author or "Noctro", cfg.name, cfg.suffix or ""),
            Size = dim2(1, 0, 0, 0),
            Position = dim2(0, -10, 0.5, -1),
            AnchorPoint = vec2(0, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            AutomaticSize = Enum.AutomaticSize.XY,
            FontFace = fonts.font,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        library:apply_theme(items["other_info"], "accent", "TextColor3")
    end

    library._menuMain = items["main"]
        library:draggify(items["main"])
        -- Discord only (top-right)
        do
            local discordUrl = properties.Discord or properties.discord or "https://discord.gg/emblem"
            local dbtn = library:create("TextButton", {
                Parent = items["main"],
                AnchorPoint = vec2(1, 0),
                Position = dim2(1, -92, 0, 12),
                Size = dim2(0, 28, 0, 28),
                BackgroundColor3 = themes.preset.element,
                Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 25,
            })
            library:create("UICorner", { Parent = dbtn, CornerRadius = dim(0, 7) })
            local dic = library:create("TextLabel", {
                Parent = dbtn, BackgroundTransparency = 1,
                AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
                Size = dim2(1, 0, 1, 0),
                Text = "DC", TextSize = 11, FontFace = fonts.font,
                TextColor3 = themes.preset.text, ZIndex = 26,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            dbtn.MouseButton1Click:Connect(function()
                local ok = pcall(function()
                    if setclipboard then setclipboard(tostring(discordUrl)) end
                end)
                pcall(function()
                    if library.notification then
                        library:notification({ text = ok and "Discord invite copied" or "Clipboard failed", time = 2 })
                    end
                end)
            end)
            items["discord_btn"] = dbtn
            -- avatar next to discord
            local avatarBtn = library:create("ImageButton", {
                Parent = items["main"],
                AnchorPoint = vec2(1, 0),
                Position = dim2(1, -52, 0, 12),
                Size = dim2(0, 32, 0, 32),
                BackgroundColor3 = themes.preset.element,
                AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 20,
                ScaleType = Enum.ScaleType.Crop,
            })
            library:create("UICorner", { Parent = avatarBtn, CornerRadius = dim(1, 0) })
            library:create("UIStroke", { Parent = avatarBtn, Color = themes.preset.accent, Thickness = 1.2 })
            task.spawn(function()
                local ok, content = pcall(function()
                    return players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok and content then avatarBtn.Image = content end
            end)
            dbtn.Position = dim2(1, -92, 0, 12)
            items["avatar_btn"] = avatarBtn
            local drop
            avatarBtn.MouseButton1Click:Connect(function()
                if drop and drop.Parent then
                    drop:Destroy()
                    drop = nil
                    return
                end
                drop = library:create("Frame", {
                    Parent = items["main"],
                    AnchorPoint = vec2(1, 0),
                    Position = dim2(1, -12, 0, 48),
                    Size = dim2(0, 168, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = themes.preset.section,
                    BorderSizePixel = 0,
                    ZIndex = 40,
                })
                library:create("UICorner", { Parent = drop, CornerRadius = dim(0, 8) })
                library:create("UIStroke", { Parent = drop, Color = rgb(30, 30, 36), Thickness = 1 })
                library:create("UIPadding", {
                    Parent = drop, PaddingTop = dim(0, 8), PaddingBottom = dim(0, 8),
                    PaddingLeft = dim(0, 8), PaddingRight = dim(0, 8),
                })
                library:create("UIListLayout", { Parent = drop, Padding = dim(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
                local function opt(text, fn)
                    local b = library:create("TextButton", {
                        Parent = drop, Size = dim2(1, 0, 0, 28), BackgroundColor3 = themes.preset.element,
                        Text = text, FontFace = fonts.font, TextSize = 12, TextColor3 = themes.preset.text,
                        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 41,
                    })
                    library:create("UICorner", { Parent = b, CornerRadius = dim(0, 6) })
                    b.MouseButton1Click:Connect(function()
                        pcall(fn)
                        if drop then drop:Destroy() drop = nil end
                    end)
                end
                opt("Copy username", function() if setclipboard then setclipboard(lp.Name) end end)
                opt("Copy user id", function() if setclipboard then setclipboard(tostring(lp.UserId)) end end)
                opt("Unload menu", function() library:unload_menu() end)
            end)
        end
    library:resizify(items["main"])

    do
        local touch = false
        pcall(function() touch = uis.TouchEnabled == true end)
        local vp = camera and camera.ViewportSize
        local needMobile = touch
        if vp and math.min(vp.X, vp.Y) < 700 then
            needMobile = true
        end
        if needMobile and vp then
            local scale = math.min(vp.X / 720, vp.Y / 580)
            scale = math.clamp(scale, 0.6, 1)
            local us = items["main"]:FindFirstChild("NoctroMobileScale")
            if not us then
                us = Instance.new("UIScale")
                us.Name = "NoctroMobileScale"
                us.Parent = items["main"]
            end
            us.Scale = scale
            library._mobile_scale = us
            task.defer(function()
                pcall(function()
                    local aw = items["main"].AbsoluteSize.X
                    local ah = items["main"].AbsoluteSize.Y
                    local x = math.max(6, math.floor((vp.X - aw) * 0.5))
                    local y = math.max(6, math.floor((vp.Y - ah) * 0.5))
                    items["main"].Position = dim2(0, x, 0, y)
                end)
            end)
        end

        if touch then
            local btnGui = library:create("ScreenGui", {
                Parent = get_hui(),
                Name = "\0",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
                DisplayOrder = 10050,
            })
            library._mobile_menu_gui = btnGui
            local btn = library:create("TextButton", {
                Parent = btnGui,
                Name = "\0",
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = themes.preset.section,
                Size = dim2(0, 46, 0, 46),
                Position = dim2(1, -58, 0.5, -23),
                BorderSizePixel = 0,
                ZIndex = 200,
            })
            library:create("UICorner", { Parent = btn, CornerRadius = dim(0, 12) })
            library:create("UIStroke", {
                Parent = btn, Color = themes.preset.accent, Thickness = 1.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            local icon = library:create("TextLabel", {
                Parent = btn,
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                Text = "≡",
                TextColor3 = themes.preset.text,
                TextSize = 22,
                FontFace = fonts.font,
                BorderSizePixel = 0,
                ZIndex = 201,
            })
            local open = true
            btn.MouseButton1Click:Connect(function()
                open = not open
                pcall(function()
                    if cfg.toggle_menu then
                        cfg.toggle_menu(open)
                    elseif library.items then
                        library.items.Enabled = open
                    end
                end)
                pcall(function()
                    shared = shared or {}
                    shared._hostMenuOpen = open
                end)
            end)
            do
                local dragging, start, startPos
                btn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        start = input.Position
                        startPos = btn.Position
                    end
                end)
                btn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                library:connection(uis.InputChanged, function(input)
                    if not dragging then return end
                    if input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                    local vp2 = camera.ViewportSize
                    local nx = startPos.X.Offset + (input.Position.X - start.X)
                    local ny = startPos.Y.Offset + (input.Position.Y - start.Y)
                    nx = clamp(nx, 8, vp2.X - 54)
                    ny = clamp(ny, 8, vp2.Y - 54)
                    if math.abs(input.Position.X - start.X) + math.abs(input.Position.Y - start.Y) > 12 then
                        btn.Position = dim2(0, nx, 0, ny)
                    end
                end)
            end
            library._mobile_menu_btn = btn
        end
    end

    function cfg.toggle_menu(bool)
        if bool == nil then
            bool = not library["items"].Enabled
        end
        bool = bool and true or false
        library["items"].Enabled = bool
        pcall(function()
            if items["main"] then
                items["main"].Visible = bool
                items["main"].BackgroundTransparency = 0
            end
        end)
        pcall(function()
            shared = shared or {}
            shared._hostMenuOpen = bool
        end)
    end

    library._menuMain = items["main"]
    library["items"].Enabled = true
    pcall(function()
        if items["main"] then items["main"].Visible = true end
    end)

    library._scrollAim = library._scrollAim or {}
    local function aimScroll(frame, delta)
        if not (frame and frame:IsA("ScrollingFrame")) then return end
        local maxY = 0
        pcall(function()
            maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
        end)
        if maxY < 1 then
            pcall(function()
                maxY = math.max(0, frame.CanvasSize.Y.Offset - frame.AbsoluteSize.Y)
            end)
        end
        local cur = library._scrollAim[frame] or frame.CanvasPosition.Y
        local nxt = math.clamp(cur + delta, 0, math.max(0, maxY))
        library._scrollAim[frame] = nxt
    end
    library:connection(uis.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        if not (library["items"] and library["items"].Enabled) then return end
        local m = uis:GetMouseLocation()
        local function inside(obj)
            if not (obj and obj.Parent) then return false end
            local p, s = obj.AbsolutePosition, obj.AbsoluteSize
            return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
        end
        local delta = -input.Position.Z * 72
        if inside(items["button_holder"]) or inside(items["side_frame"]) then
            aimScroll(items["button_holder"], delta)
            return
        end
        local th = library.selected_tab and library.selected_tab[4]
        if th and th:IsA("ScrollingFrame") and (inside(th) or (inside(items["main"]) and not inside(items["side_frame"]))) then
            aimScroll(th, delta)
        end
    end)
    library:connection(run.RenderStepped, function(dt)
        local aim = library._scrollAim
        if not aim then return end
        for frame, target in pairs(aim) do
            if not (frame and frame.Parent) then
                aim[frame] = nil
            else
                local y = frame.CanvasPosition.Y
                local ny = y + (target - y) * math.clamp((dt or 0.016) * 14, 0.12, 0.45)
                if math.abs(ny - target) < 0.6 then ny = target end
                frame.CanvasPosition = Vector2.new(0, ny)
            end
        end
    end)

    library:connection(uis.InputBegan, function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local bind = library.MenuKeybind or Enum.KeyCode.RightControl
        if type(bind) == "table" then bind = bind.key or bind.KeyCode end
        if input.KeyCode == bind then
            cfg.toggle_menu(not library["items"].Enabled)
        end
    end)

    return setmetatable(cfg, library)
end

function library:tab(properties)
    local cfg = {
        name = properties.name or properties.Name or "visuals",
        icon = properties.icon or properties.Icon or "layers",
        tabs = properties.tabs or properties.Tabs or { "Main" },
        pages = {},
        current_multi = nil,
        items = {},
    }
    library._lastSidebarTab = cfg
    cfg._emblemTab = cfg

    local items = cfg.items
    do
        items["tab_holder"] = library:create("ScrollingFrame", {
            Parent = library.cache,
            Name = "\0",
            Visible = false,
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = dim2(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = rgb(60,60,66),
            Active = true,
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            Parent = self.items["button_holder"],
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Name = "\0",
            Size = dim2(0, 40, 0, 40),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = themes.preset.accent,
            BackgroundTransparency = 1,
        })
        library:create("UICorner", { Parent = items["button"], CornerRadius = dim(0, 10) })

        items["icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.dimicon,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0.5, 0, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 20, 0, 20),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
            ZIndex = 5,
        })
        ApplyIcon(items["icon"], cfg.icon)

        items["name"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = themes.preset.dimtext,
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 0, 0),
            Position = dim2(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIPadding", {
            Parent = items["name"],
            PaddingRight = dim(0, 5),
            PaddingLeft = dim(0, 5),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        items["multi_section_button_holder"] = library:create("Frame", {
            Parent = library.cache,
            BackgroundTransparency = 1,
            Name = "\0",
            Visible = false,
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["multi_section_button_holder"],
            Padding = dim(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
        })

        library:create("UIPadding", {
            PaddingTop = dim(0, 8),
            PaddingBottom = dim(0, 7),
            Parent = items["multi_section_button_holder"],
            PaddingRight = dim(0, 7),
            PaddingLeft = dim(0, 7),
        })

        for _, section in cfg.tabs do
            local data = { items = {} }
            local multi_items = data.items

            multi_items["button"] = library:create("TextButton", {
                FontFace = fonts.font,
                TextColor3 = rgb(255, 255, 255),
                BorderColor3 = rgb(0, 0, 0),
                AutoButtonColor = false,
                Text = "",
                Parent = items["multi_section_button_holder"],
                Name = "\0",
                Size = dim2(0, 0, 0, 39),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 16,
                BackgroundColor3 = rgb(25, 25, 29),
            })

            multi_items["name"] = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = rgb(62, 62, 63),
                BorderColor3 = rgb(0, 0, 0),
                Text = section,
                Parent = multi_items["button"],
                Name = "\0",
                Size = dim2(0, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 16,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIPadding", {
                Parent = multi_items["name"],
                PaddingRight = dim(0, 5),
                PaddingLeft = dim(0, 5),
            })

            multi_items["accent"] = library:create("Frame", {
                BorderColor3 = rgb(0, 0, 0),
                AnchorPoint = vec2(0, 1),
                Parent = multi_items["button"],
                BackgroundTransparency = 1,
                Position = dim2(0, 10, 1, 4),
                Name = "\0",
                Size = dim2(1, -20, 0, 6),
                BorderSizePixel = 0,
                BackgroundColor3 = themes.preset.accent,
            })
            library:apply_theme(multi_items["accent"], "accent", "BackgroundColor3")

            library:create("UICorner", {
                Parent = multi_items["accent"],
                CornerRadius = dim(0, 999),
            })

            library:create("UIPadding", {
                Parent = multi_items["button"],
                PaddingRight = dim(0, 10),
                PaddingLeft = dim(0, 10),
            })

            library:create("UICorner", {
                Parent = multi_items["button"],
                CornerRadius = dim(0, 7),
            })

            multi_items["tab"] = library:create("Frame", {
                Parent = library.cache,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = rgb(0, 0, 0),
                Size = dim2(1, -20, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Parent = multi_items["tab"],
                Padding = dim(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
            })

            library:create("UIPadding", {
                PaddingTop = dim(0, 7),
                PaddingBottom = dim(0, 7),
                Parent = multi_items["tab"],
                PaddingRight = dim(0, 7),
                PaddingLeft = dim(0, 7),
            })

            data.text = multi_items["name"]
            data.accent = multi_items["accent"]
            data.button = multi_items["button"]
            data.page = multi_items["tab"]

            local tab_parent = library:create("Frame", {
                Parent = multi_items["tab"],
                BackgroundTransparency = 1,
                Name = "\0",
                Size = dim2(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderColor3 = rgb(0, 0, 0),
                BorderSizePixel = 0,
                Visible = true,
                BackgroundColor3 = rgb(255, 255, 255),
            })
            library:create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
                Parent = tab_parent,
                Padding = dim(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            data.parent = tab_parent
            data._sidebar = cfg
            data._emblemTab = cfg

            function data.open_page()
                local page = cfg.current_multi
                if page and page.text ~= data.text then
                    self.items["global_fade"].BackgroundTransparency = 0
                    library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                end

                for _, p in ipairs(cfg.pages) do
                    if p ~= data then
                        pcall(function()
                            library:tween(p.text, { TextColor3 = rgb(62, 62, 63) })
                            library:tween(p.accent, { BackgroundTransparency = 1 })
                            library:tween(p.button, { BackgroundTransparency = 1 })
                            p.page.Visible = false
                            p.page.Parent = library["cache"]
                            p.page.Size = dim2(1, -20, 1, -20)
                        end)
                    end
                end

                library:tween(data.text, { TextColor3 = rgb(255, 255, 255) })
                library:tween(data.accent, { BackgroundTransparency = 0 })
                library:tween(data.button, { BackgroundTransparency = 0 })
                library:tween(data.page, { Size = dim2(1, 0, 1, 0) }, Enum.EasingStyle.Quad, 0.4)

                data.page.Visible = true
                data.page.Parent = items["tab_holder"]
                cfg.current_multi = data
                library:close_element()
            end

            multi_items["button"].MouseButton1Down:Connect(function()
                data.open_page()
            end)

            cfg.pages[#cfg.pages + 1] = setmetatable(data, library)
        end

        if cfg.pages[1] and cfg.pages[1].open_page then
            cfg.pages[1].open_page()
        end
        -- hide sub-tab strip when only one page
        if #cfg.tabs <= 1 then
            pcall(function()
                if items["multi_section_button_holder"] then
                    items["multi_section_button_holder"].Visible = false
                    items["multi_section_button_holder"].Parent = library.cache
                end
                if self.items and self.items["multi_holder"] then
                    self.items["multi_holder"].Visible = false
                    self.items["multi_holder"].Size = dim2(1, -86, 0, 0)
                end
            end)
        end
    end

    function cfg.open_tab()
        local selected_tab = self.selected_tab
        if selected_tab then
            if selected_tab[4] ~= items["tab_holder"] then
                self.items["global_fade"].BackgroundTransparency = 0
                library:tween(self.items["global_fade"], { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, 0.4)
                selected_tab[4].Size = dim2(1, -92, 1, -101)
            end
            library:tween(selected_tab[1], { BackgroundTransparency = 1 })
            library:tween(selected_tab[2], { ImageColor3 = themes.preset.dimicon })
            library:tween(selected_tab[3], { TextColor3 = themes.preset.dimtext })
            selected_tab[4].Visible = false
            selected_tab[4].Parent = library["cache"]
            selected_tab[5].Visible = false
            selected_tab[5].Parent = library["cache"]
        end

        library:tween(items["button"], { BackgroundTransparency = 0.82, BackgroundColor3 = themes.preset.accent })
        library:tween(items["icon"], { ImageColor3 = themes.preset.accent })
        pcall(function() items["name"].Visible = false; items["name"].TextTransparency = 1 end)
        library._active_tab_icon = items["icon"]
        library:tween(items["tab_holder"], { Size = dim2(1, 0, 1, 0) }, Enum.EasingStyle.Quad, 0.25)

        items["tab_holder"].Visible = true
        items["tab_holder"].Position = dim2(0, 0, 0, 0)
        items["tab_holder"].Size = dim2(1, 0, 1, 0)
        local fade = self.items["global_fade"]
        items["tab_holder"].Parent = (fade and fade.Parent) and fade or self.items["main"]
        items["tab_holder"].ScrollingEnabled = true
        task.defer(function() pcall(library.RefreshPageScroll) end)
        -- only show multi strip when multiple sub-pages
        items["multi_section_button_holder"].Visible = (#cfg.tabs > 1)
        items["multi_section_button_holder"].Parent = self.items["multi_holder"]

        self.selected_tab = {
            items["button"],
            items["icon"],
            items["name"],
            items["tab_holder"],
            items["multi_section_button_holder"],
        }
        -- RefreshPageScroll and the mouse-wheel handler both read this off
        -- the shared `library` table (they aren't window methods, so they
        -- have no `self`), but only `self.selected_tab` (the window
        -- instance) was ever being set - the global copy stayed nil
        -- forever, so both those readers always bailed out early and
        -- mouse-wheel scrolling never worked. Mirror it here too.
        library.selected_tab = self.selected_tab
        library:close_element()
    end

    items["button"].MouseButton1Down:Connect(function()
        cfg.open_tab()
    end)

    if not self.selected_tab then
        cfg.open_tab(true)
    end

    -- Prefer first multi-page for :section / :column; still support unpack(pages)
    setmetatable(cfg, {
        __index = function(_, k)
            local page = cfg.pages and cfg.pages[1]
            if page then
                local v = rawget(page, k)
                if v ~= nil then return v end
                local mt = getmetatable(page)
                if mt and type(mt.__index) == "table" and mt.__index[k] then
                    local fn = mt.__index[k]
                    if type(fn) == "function" then
                        return function(_, ...) return fn(page, ...) end
                    end
                    return mt.__index[k]
                end
            end
            local fn = rawget(library, k)
            if type(fn) == "function" then
                return function(_, ...) return fn(page or cfg, ...) end
            end
            return fn
        end,
    })
    cfg.section = function(_, props)
        local page = cfg.pages and cfg.pages[1] or cfg
        return library.section(page, props)
    end
    cfg.column = function(_, props)
        local page = cfg.pages and cfg.pages[1] or cfg
        return library.column(page, props)
    end
    cfg.open_tab = cfg.open_tab
    return cfg, unpack(cfg.pages)
end

function library:seperator(properties)
    local cfg = { items = {}, name = properties.Name or properties.name or "General" }
    local items = cfg.items
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["button_holder"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 40, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })
    return setmetatable(cfg, library)
end

function library:column(properties)
    properties = properties or {}
    library._buildingTab = self._emblemTab or (self.open_tab and self) or library._buildingTab
    library._buildingPage = (self.open_page and self) or library._buildingPage

    local sub = properties.tab or properties.Tab
    local parent_frame = nil

    if sub and type(sub) == "number" and self.pages and self.pages[sub] then
        parent_frame = self.pages[sub].parent
    elseif self.parent then

        parent_frame = self.parent
    elseif self.items and self.items["tab_parent"] then
        parent_frame = self.items["tab_parent"]
    elseif self.pages and self.pages[1] then

        parent_frame = self.pages[1].parent
        sub = 1
    end

    local count_key = sub or 0
    self._column_counts = self._column_counts or {}
    self._column_counts[count_key] = (self._column_counts[count_key] or 0) + 1
    if self._column_counts[count_key] > 8 then
        warn("[Noctro] Max columns reached — extra column ignored.")
        local dummy = { items = { column = Instance.new("Frame") } }
        dummy.items.column.Parent = nil
        return setmetatable(dummy, library)
    end

    local cfg = { items = {}, size = properties.size or 1 }
    local items = cfg.items
    items["column"] = library:create("Frame", {
        Parent = parent_frame,
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", {
        PaddingBottom = dim(0, 10),
        Parent = items["column"],
    })
    library:create("UIListLayout", {
        Parent = items["column"],
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Padding = dim(0, 10),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    library._columns = library._columns or {}
    if items["column"] then
        table.insert(library._columns, items["column"])
        library._lastColumn = items["column"]
    end
    cfg._emblemTab = library._buildingTab
    cfg._emblemPage = library._buildingPage
    return setmetatable(cfg, library)
end

function library:sub_tab(properties)
    local cfg = { items = {}, order = properties.order or 0, size = properties.size or 1 }
    local items = cfg.items
    items["tab_parent"] = library:create("Frame", {
        Parent = self.items["tab"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(0, 0, cfg.size, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        Visible = true,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        Parent = items["tab_parent"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return setmetatable(cfg, library)
end

function library._visibleColumns()
    local out = {}
    local items = library["items"]
    local main = items and (items:FindFirstChild("main") or items:FindFirstChildWhichIsA("Frame"))
    for _, col in ipairs(library._columns or {}) do
        if col and col.Parent and col.Visible ~= false and col.AbsoluteSize.X > 50 and col.AbsoluteSize.Y > 40 then
            if (not main) or col:IsDescendantOf(main) then
                -- skip columns that are off-screen / cached
                if col.AbsoluteSize.X >= 120 and col.AbsoluteSize.X <= 420 then
                    table.insert(out, col)
                end
            end
        end
    end
    return out
end

function library._bestColumn(mx, my)
    local best, bestD
    for _, col in ipairs(library._visibleColumns()) do
        local p, s = col.AbsolutePosition, col.AbsoluteSize
        local inside = mx >= p.X and mx <= p.X + s.X and my >= p.Y and my <= p.Y + s.Y
        local cx, cy = p.X + s.X * 0.5, p.Y + s.Y * 0.5
        local d = (mx - cx) * (mx - cx) + (my - cy) * (my - cy)
        if inside then d = d * 0.15 end
        if not bestD or d < bestD then best, bestD = col, d end
    end
    return best
end

function library._updateGhost(col, height)
    if not col then
        if library._snapGhost then library._snapGhost.Visible = false end
        return
    end
    local parent = library["items"]
    if not library._snapGhost or not library._snapGhost.Parent then
        library._snapGhost = library:create("Frame", {
            Parent = parent,
            BackgroundColor3 = rgb(110, 110, 128),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            ZIndex = 250,
        })
        library:create("UICorner", { Parent = library._snapGhost, CornerRadius = dim(0, 7) })
    end
    library._snapGhost.Parent = library["items"]
    local ap, asz = col.AbsolutePosition, col.AbsoluteSize
    local yOff = 4
    local lay = col:FindFirstChildWhichIsA("UIListLayout")
    if lay and lay.AbsoluteContentSize.Y > 0 then
        yOff = lay.AbsoluteContentSize.Y + 6
    else
        for _, ch in ipairs(col:GetChildren()) do
            if ch:IsA("Frame") and ch.Visible and ch.AbsoluteSize.Y > 24 and ch.AbsoluteSize.Y < 900 then
                local rel = (ch.AbsolutePosition.Y - ap.Y) + ch.AbsoluteSize.Y + 7
                if rel > yOff then yOff = rel end
            end
        end
    end
    local h = math.clamp(height or 140, 70, 400)
    library._snapGhost.Visible = true
    library._snapGhost.ZIndex = 500
    -- Repositioning a *separate* element using another element's
    -- AbsolutePosition, then setting it via UDim2.fromOffset under a
    -- ScreenGui with IgnoreGuiInset = true, is a documented Roblox
    -- engine quirk: AbsolutePosition doesn't come back in the same
    -- coordinate space UDim2.fromOffset expects here, off by exactly
    -- the topbar GuiInset - which is what was showing up as the ghost
    -- rendering above where it should be. Compensate with the same
    -- gui_offset constant already computed at the top of this file.
    library._snapGhost.Position = UDim2.fromOffset(ap.X + 4, ap.Y + yOff + gui_offset)
    library._snapGhost.Size = UDim2.fromOffset(math.max(50, asz.X - 8), h)
end

function library.RefreshPageScroll()
    local th
    pcall(function()
        if library.selected_tab and library.selected_tab[4] and library.selected_tab[4]:IsA("ScrollingFrame") then
            th = library.selected_tab[4]
        end
    end)
    if not th then
        -- Fallback only ever matters if selected_tab hasn't been set yet
        -- (e.g. this runs before the very first tab finishes opening).
        -- Columns are parented under a plain Frame, not the ScrollingFrame
        -- directly, so walk up to find it instead of checking col.Parent.
        for _, col in ipairs(library._columns or {}) do
            if col and col.Parent then
                local anc = col.Parent
                while anc and not anc:IsA("ScrollingFrame") do
                    anc = anc.Parent
                end
                if anc and anc.Visible then
                    th = anc
                    break
                end
            end
        end
    end
    if not (th and th:IsA("ScrollingFrame")) then return end

    -- Columns use AutomaticSize.Y, so Roblox's own layout engine has
    -- already computed their true natural content height. Measure each
    -- column's actual bottom edge in screen space and compare against the
    -- scroll frame's own top edge, rather than assuming every column
    -- starts flush at Y=0 inside it - two columns with very different
    -- natural heights can end up positioned slightly differently under
    -- VerticalFlex=Fill, and comparing raw AbsoluteSize alone silently
    -- ignores that, which is exactly the kind of thing that produces a
    -- canvas taller than the content actually needs.
    local maxBottom = 0
    for _, col in ipairs(library._columns or {}) do
        if col and col.Parent and col.Visible ~= false and col:IsDescendantOf(th) then
            local bottom = col.AbsolutePosition.Y + col.AbsoluteSize.Y
            if bottom > maxBottom then maxBottom = bottom end
        end
    end
    local neededHeight = 0
    for _, col in ipairs(library._columns or {}) do
        if col and col.Parent and col:IsDescendantOf(th) then
            local h = 0
            local lay = col:FindFirstChildWhichIsA("UIListLayout")
            if lay then
                h = lay.AbsoluteContentSize.Y + 24
            else
                for _, ch in ipairs(col:GetChildren()) do
                    if ch:IsA("GuiObject") and ch.AbsoluteSize.Y > 8 then
                        h = h + ch.AbsoluteSize.Y + 8
                    end
                end
            end
            if h > neededHeight then neededHeight = h end
        end
    end

    local keep = th.CanvasPosition
    th.AutomaticCanvasSize = Enum.AutomaticSize.None
    th.ScrollingEnabled = true
    th.Active = true
    th.CanvasSize = dim2(0, 0, 0, math.max(neededHeight + 16, th.AbsoluteSize.Y))
    th.CanvasPosition = keep
    if library._scrollAim then
        library._scrollAim[th] = keep.Y
    end
end

function library.SnapSection(outline, mx, my)
    if not outline then return end
    -- mx/my must already be in the same coordinate space as AbsolutePosition
    -- (i.e. from an InputObject's .Position, not UserInputService:GetMouseLocation(),
    -- which additionally includes the topbar GuiInset and reads ~36px too high
    -- against every AbsolutePosition-based check below).
    local best
    for _, col in ipairs(library._visibleColumns()) do
        local p, s = col.AbsolutePosition, col.AbsoluteSize
        if mx >= p.X and mx <= p.X + s.X and my >= p.Y and my <= p.Y + s.Y then
            best = col
            break
        end
    end
    if best then
        outline.Parent = best
        local sy = tonumber(outline:GetAttribute("ScaleY")) or 0.5
        outline.AutomaticSize = Enum.AutomaticSize.Y
        outline.Size = dim2(1, 0, 0, 0)
        outline.Position = dim2(0, 0, 0, 0)
        library._lastColumn = best
    else
        -- keep floating on the menu overlay so it never vanishes
        if library._floatGui then
            outline.Parent = library._floatGui
        end
    end
    if library._snapGhost then library._snapGhost.Visible = false end
end

function library.OpenSearch()
    library._searchIndex = library._searchIndex or {}
    if #library._searchIndex == 0 then
        for flag, _ in pairs(library.flags or {}) do
            table.insert(library._searchIndex, { name = tostring(flag), flag = flag })
        end
    end
    if library._searchGui and library._searchGui.Parent then
        library._searchGui:Destroy()
    end
    local host = library["items"]
    local main = library._menuMain
    if not main and host then
        pcall(function()
            for _, ch in ipairs(host:GetChildren()) do
                if ch:IsA("Frame") and ch.AbsoluteSize.X > 400 then main = ch break end
            end
        end)
    end
    local gui = library:create("Frame", {
        Parent = main or host,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 400,
    })
    library._searchGui = gui
    local dimmer = library:create("TextButton", {
        Parent = gui, Size = dim2(1,0,1,0), BackgroundColor3 = rgb(0,0,0),
        BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, ZIndex = 400,
    })
    local box = library:create("Frame", {
        Parent = gui,
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(0, 380, 0, 320),
        BackgroundColor3 = rgb(22, 22, 26),
        BorderSizePixel = 0,
        ZIndex = 401,
    })
    library:create("UICorner", { Parent = box, CornerRadius = dim(0, 12) })
    library:create("UIStroke", { Parent = box, Color = rgb(48,48,54), Thickness = 1 })
    local title = library:create("TextLabel", {
        Parent = box, BackgroundTransparency = 1, Position = dim2(0, 16, 0, 10),
        Size = dim2(1, -40, 0, 22), FontFace = fonts.font, Text = "Search",
        TextSize = 16, TextColor3 = rgb(255,255,255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 402,
    })
    local close = library:create("TextButton", {
        Parent = box, Position = dim2(1, -28, 0, 10), Size = dim2(0, 18, 0, 18),
        BackgroundTransparency = 1, Text = "x", TextColor3 = themes.preset.dimtext,
        FontFace = fonts.font, TextSize = 16, ZIndex = 402,
    })
    local input = library:create("TextBox", {
        Parent = box, Position = dim2(0, 16, 0, 40), Size = dim2(1, -32, 0, 32),
        BackgroundColor3 = rgb(16,16,18), BorderSizePixel = 0, FontFace = fonts.font,
        Text = "", PlaceholderText = "Search sections and elements", TextColor3 = rgb(255,255,255),
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 402,
    })
    library:create("UICorner", { Parent = input, CornerRadius = dim(0, 7) })
    library:create("UIPadding", { Parent = input, PaddingLeft = dim(0, 28) })
    local ic = library:create("ImageLabel", {
        Parent = input, BackgroundTransparency = 1, Size = dim2(0, 14, 0, 14),
        Position = dim2(0, -20, 0.5, -7), Image = "rbxassetid://6031094678",
        ImageColor3 = themes.preset.dimtext, ZIndex = 403,
    })
    local list = library:create("ScrollingFrame", {
        Parent = box, Position = dim2(0, 16, 0, 84), Size = dim2(1, -32, 1, -100),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = dim2(0,0,0,0), ZIndex = 402,
    })
    library:create("UIListLayout", { Parent = list, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    local function render(q)
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        q = tostring(q or ""):lower()
        if q == "" then return end
        local n = 0
        for _, item in ipairs(library._searchIndex) do
            if n >= 50 then break end
            local name = tostring(item.name or "")
            if q == "" or name:lower():find(q, 1, true) then
                n += 1
                local b = library:create("TextButton", {
                    Parent = list, Size = dim2(1, 0, 0, 34), BackgroundColor3 = rgb(28,28,32),
                    BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 403,
                })
                library:create("UICorner", { Parent = b, CornerRadius = dim(0, 6) })
                library:create("Frame", {
                    Parent = b, Size = dim2(0, 3, 1, -10), Position = dim2(0, 6, 0, 5),
                    BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 404,
                })
                library:create("TextLabel", {
                    Parent = b, BackgroundTransparency = 1, Position = dim2(0, 16, 0, 0),
                    Size = dim2(1, -20, 1, 0), FontFace = fonts.font, Text = name,
                    TextSize = 14, TextColor3 = rgb(255,255,255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 404,
                })
                b.MouseButton1Click:Connect(function()
                    pcall(function()
                        local tab = item.tab
                        if type(tab) == "table" and not tab.open_tab and tab._sidebar then
                            tab = tab._sidebar
                        end
                        if type(tab) == "table" and tab.open_tab then
                            tab.open_tab()
                        end
                        local page = item.page
                        if type(page) == "table" and page.open_page then
                            page.open_page()
                        end
                    end)
                    task.delay(0.2, function()
                        pcall(function()
                            local inst = item.inst
                            if inst and inst.Parent then
                                local old = inst.BackgroundColor3
                                inst.BackgroundColor3 = themes.preset.accent
                                task.delay(0.8, function()
                                    pcall(function() inst.BackgroundColor3 = old end)
                                end)
                            end
                        end)
                    end)
                    pcall(function() gui:Destroy() end)
                end)
            end
        end
    end
    input:GetPropertyChangedSignal("Text"):Connect(function() render(input.Text) end)
    dimmer.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
    close.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
    local empty = library:create("TextLabel", {
        Parent = box, BackgroundTransparency = 1, Position = dim2(0, 0, 0, 140),
        Size = dim2(1, 0, 0, 20), FontFace = fonts.font, Text = "Start typing to search",
        TextSize = 14, TextColor3 = themes.preset.dimtext, ZIndex = 402,
    })
    input:GetPropertyChangedSignal("Text"):Connect(function()
        empty.Visible = input.Text == ""
    end)
    render("")
    task.defer(function() input:CaptureFocus() end)
end

function library:section(properties)
    -- Auto-create left/right columns if section is called on a tab/page without :column()
    if not (self and self.items and self.items["column"]) then
        local host = self
        if not host._emblem_auto_cols then
            local L = library.column(host, {})
            local R = library.column(host, {})
            host._emblem_auto_cols = { L = L, R = R }
        end
        local side = string.lower(tostring((properties and (properties.side or properties.Side)) or "left"))
        self = (side == "right") and host._emblem_auto_cols.R or host._emblem_auto_cols.L
    end

    local cfg = {
        name = properties.name or properties.Name or "section",
        side = properties.side or properties.Side or "left",
        default = properties.default or properties.Default or false,
        size = properties.size or properties.Size or self.size or 0.5,
        icon = properties.icon or properties.Icon or "box",
        fading_toggle = properties.fading or properties.Fading or false,
        items = {},
    }

    local items = cfg.items
    do
        items["outline"] = library:create("Frame", {
            Name = "\0",
            Parent = self.items["column"],
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.element,
        })
        pcall(function() items["outline"]:SetAttribute("ScaleY", cfg.size) end)
        task.defer(function()
            pcall(library.RefreshPageScroll)
        end)
        pcall(function()
            items["outline"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                pcall(library.RefreshPageScroll)
            end)
        end)

        library:create("UICorner", {
            Parent = items["outline"],
            CornerRadius = dim(0, 7),
        })

        items["inline"] = library:create("Frame", {
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, -2, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
        })

        library:create("UICorner", {
            Parent = items["inline"],
            CornerRadius = dim(0, 7),
        })
        library:create("UIPadding", {
            Parent = items["inline"],
            PaddingTop = dim(0, 36),
            PaddingBottom = dim(0, 8),
        })

        items["scrolling"] = library:create("Frame", {
            Parent = items["inline"],
            Name = "\0",
            Size = dim2(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 0),
            BackgroundColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            BorderSizePixel = 0,
        })

        items["elements"] = library:create("Frame", {
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["scrolling"],
            Name = "\0",
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0, 10),
            Size = dim2(1, -20, 0, 0),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("UIListLayout", {
            Parent = items["elements"],
            Padding = dim(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        library:create("UIPadding", {
            PaddingBottom = dim(0, 15),
            Parent = items["elements"],
        })

        items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = "",
            AutoButtonColor = false,
            Parent = items["outline"],
            Name = "\0",
            Position = dim2(0, 1, 0, 1),
            Size = dim2(1, -2, 0, 35),
            BorderSizePixel = 0,
            TextSize = 16,
            BackgroundColor3 = rgb(19, 19, 21),
        })

        library:create("UICorner", {
            Parent = items["button"],
            CornerRadius = dim(0, 7),
        })

        library._searchIndex = library._searchIndex or {}
        table.insert(library._searchIndex, { name = cfg.name, inst = items["outline"], tab = library._lastSidebarTab or library._buildingTab, page = library._buildingPage })

        do
            local dragging = false
            items["button"].InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                dragging = true
                library._sectionDragging = true
                if not library._floatGui or not library._floatGui.Parent then
                    library._floatGui = library:create("Frame", {
                        Parent = library["items"],
                        BackgroundTransparency = 1,
                        Size = dim2(1, 0, 1, 0),
                        ZIndex = 200,
                    })
                end
                library._floatGui.Visible = true
                -- input.Position (not UserInputService:GetMouseLocation()) - it's
                -- reported in the same coordinate space as AbsolutePosition, so
                -- everything downstream (grab offset, ghost placement, column
                -- hit-testing) lines up with where things are actually drawn
                -- instead of reading ~36px too high from the topbar GuiInset.
                local loc = input.Position
                local abs, sz = items["outline"].AbsolutePosition, items["outline"].AbsoluteSize
                items["outline"]:SetAttribute("GrabX", loc.X - abs.X)
                items["outline"]:SetAttribute("GrabY", loc.Y - abs.Y)
                items["outline"].Parent = library._floatGui
                items["outline"].Size = dim2(0, sz.X, 0, sz.Y)
                items["outline"].Position = dim2(0, loc.X - (loc.X - abs.X), 0, loc.Y - (loc.Y - abs.Y))
            end)
            uis.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local loc = input.Position
                local gx = items["outline"]:GetAttribute("GrabX") or 0
                local gy = items["outline"]:GetAttribute("GrabY") or 0
                items["outline"].Position = dim2(0, loc.X - gx, 0, loc.Y - gy)
                pcall(function()
                    library._updateGhost(library._bestColumn(loc.X, loc.Y), items["outline"].AbsoluteSize.Y)
                end)
            end)
            uis.InputEnded:Connect(function(input)
                if not dragging or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                dragging = false
                library._sectionDragging = false
                local loc = input.Position
                library.SnapSection(items["outline"], loc.X, loc.Y)
            end)
        end

        items["Icon"] = library:create("ImageLabel", {
            ImageColor3 = themes.preset.accent,
            BorderColor3 = rgb(0, 0, 0),
            Parent = items["button"],
            AnchorPoint = vec2(0, 0.5),
            BackgroundTransparency = 1,
            Position = dim2(0, 10, 0.5, 0),
            Name = "\0",
            Size = dim2(0, 22, 0, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(255, 255, 255),
        })
        ApplyIcon(items["Icon"], cfg.icon)
        library:apply_theme(items["Icon"], "accent", "ImageColor3")

        items["section_title"] = library:create("TextLabel", {
            FontFace = fonts.font,
            TextColor3 = rgb(255, 255, 255),
            BorderColor3 = rgb(0, 0, 0),
            Text = cfg.name,
            Parent = items["button"],
            Name = "\0",
            Size = dim2(0, 0, 1, 0),
            Position = dim2(0, 40, 0, -1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = 16,
            BackgroundColor3 = rgb(255, 255, 255),
        })

        library:create("Frame", {
            AnchorPoint = vec2(0, 1),
            Parent = items["button"],
            Position = dim2(0, 0, 1, 0),
            BorderColor3 = rgb(0, 0, 0),
            Size = dim2(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundColor3 = rgb(36, 36, 37),
        })
    end

    return setmetatable(cfg, library)
end

function library:toggle(options)
    options = options or {}
    local cfg = {
        enabled = options.enabled or options.Enabled or nil,
        name = options.name or options.Name or "Toggle",
        info = options.info or options.Info or nil,
        flag = options.flag or options.Flag or library:next_flag(),

        type = options.type and string.lower(options.type) or "toggle",
        default = (options.default ~= nil and options.default) or (options.Default ~= nil and options.Default) or false,
        folding = options.folding or options.Folding or false,
        callback = options.callback or options.Callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["toggle"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["left_components"] = library:create("Frame", {
        Parent = items["toggle"],
        Name = "\0",
        Position = dim2(0, 0, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 0, 0, 18),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 9,
    })
    library:create("UIListLayout", {
        Parent = items["left_components"],
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = dim(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["toggle"],
        Name = "\0",
        Size = dim2(1, -100, 0, 0),
        Position = dim2(0, 56, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["toggle"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["switch"] = library:create("TextButton", {
        FontFace = fonts.small,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["right_components"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        Size = dim2(0, 36, 0, 18),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(33, 33, 35),
    })

    library:create("UICorner", {
        Parent = items["switch"],
        CornerRadius = dim(0, 999),
    })

    items["knob"] = library:create("Frame", {
        Parent = items["switch"],
        Name = "\0",
        Position = dim2(0, 2, 0, 2),
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(160, 160, 165),
    })

    library:create("UICorner", {
        Parent = items["knob"],
        CornerRadius = dim(0, 999),
    })

    library._toggle_hooks = library._toggle_hooks or {}

    function cfg.set(bool)
        cfg.enabled = bool
        flags[cfg.flag] = bool
        library:tween(items["switch"], {
            BackgroundColor3 = bool and themes.preset.accent or rgb(33, 33, 35),
        })
        library:tween(items["knob"], {
            Position = bool and dim2(1, -16, 0, 2) or dim2(0, 2, 0, 2),
            BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(160, 160, 165),
        })

        if bool then
            library._toggle_hooks[cfg.flag] = items["switch"]
        else
            library._toggle_hooks[cfg.flag] = nil
        end
        if not library.silent then
            cfg.callback(bool)
        end
    end

    items["switch"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    items["toggle"].MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:slider(options)
    options = options or {}
    local cfg = {
        name = options.name or options.Name or "Slider",
        min = options.min or options.Min or 0,
        max = options.max or options.Max or 100,
        default = options.default or options.Default or options.min or options.Min or 0,
        interval = options.interval or options.Interval or options.decimals or options.Float or options.float or 1,
        suffix = options.suffix or options.Suffix or "",
        flag = options.flag or options.Flag or library:next_flag(),
        callback = options.callback or options.Callback or function() end,
        items = {},
        value = 0,
        sliding = false,
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["slider"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 42),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(1, -58, 0, 0),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["value"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = tostring(cfg.default) .. cfg.suffix,
        Parent = items["slider"],
        Name = "\0",
        Size = dim2(0, 54, 0, 18),
        Position = dim2(1, -59, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["track"] = library:create("Frame", {
        Parent = items["slider"],
        Name = "\0",
        Position = dim2(0, 5, 0, 24),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 8),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    -- items["name"] can now wrap to 2+ lines for long labels in narrow
    -- columns instead of truncating with "..." - when it does, its own
    -- height grows via AutomaticSize, so follow that here to push the
    -- track down instead of letting it overlap the wrapped second line.
    local function repositionTrack()
        local nameH = items["name"].AbsoluteSize.Y
        local y = math.max(24, nameH + 8)
        items["track"].Position = dim2(0, 5, 0, y)
    end
    items["name"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionTrack)
    task.defer(repositionTrack)

    library:create("UICorner", {
        Parent = items["track"],
        CornerRadius = dim(0, 4),
    })

    items["fill"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent,
    })
    library:apply_theme(items["fill"], "accent", "BackgroundColor3")

    library:create("UICorner", {
        Parent = items["fill"],
        CornerRadius = dim(0, 4),
    })

    items["knob"] = library:create("Frame", {
        Parent = items["track"],
        Name = "\0",
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0, 0, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 12, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
        ZIndex = 2,
    })

    library:create("UICorner", {
        Parent = items["knob"],
        CornerRadius = dim(0, 999),
    })

    library:create("UIStroke", {
        Color = themes.preset.accent,
        Parent = items["knob"],
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    library:apply_theme(items["knob"]:FindFirstChildOfClass("UIStroke"), "accent", "Color")

    items["hit"] = library:create("TextButton", {
        Parent = items["track"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 3,
        BorderSizePixel = 0,
    })

    function cfg.set(value)
        value = clamp(library:round(value, cfg.interval), cfg.min, cfg.max)
        cfg.value = value
        flags[cfg.flag] = value

        local fraction = (cfg.max - cfg.min) == 0 and 0 or (value - cfg.min) / (cfg.max - cfg.min)
        items["fill"].Size = dim2(fraction, 0, 1, 0)
        items["knob"].Position = dim2(fraction, 0, 0.5, 0)
        items["value"].Text = tostring(value) .. cfg.suffix

        if not library.silent then
            cfg.callback(value)
        end
    end

    local function calculate(input)
        local fraction = clamp((input.Position.X - items["track"].AbsolutePosition.X) / items["track"].AbsoluteSize.X, 0, 1)
        return cfg.min + (cfg.max - cfg.min) * fraction
    end

    items["hit"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = true
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if cfg.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg.set(calculate(input))
        end
    end)

    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.sliding = false
        end
    end)

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:dropdown(options)
    options = options or {}
    local optList = options.items or options.Items
        or options.Options or options.options
        or options.Values or options.values
        or options.List or options.list
        or {}
    local cfg = {
        name = options.name or options.Name or "Dropdown",
        options = optList,
        default = options.default or options.Default,
        multi = options.multi or options.Multi or options.MultiSelect or options.multi_select or false,
        flag = options.flag or options.Flag or library:next_flag(),
        callback = options.callback or options.Callback or function() end,
        placeholder = options.placeholder or options.Placeholder or "Select...",
        items = {},
        value = nil,
        open = false,
    }

    if cfg.multi then
        if type(cfg.default) == "table" then
            cfg.value = table.clone and table.clone(cfg.default) or { table.unpack(cfg.default) }
        else
            cfg.value = {}
        end
    end

    flags[cfg.flag] = cfg.multi and (type(cfg.default) == "table" and cfg.default or {}) or cfg.default

    local items = cfg.items
    items["dropdown"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 54),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    -- Declared early so the width-aware reposition/close-height helpers
    -- below (which need to check popup.open) can close over it; the
    -- popup Frame itself is still built further down where it always was.
    local popup = {
        open = false,
        order = {},
    }

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["dropdown"],
        Name = "\0",
        Size = dim2(1, -10, 0, 0),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    -- items["name"] can now wrap instead of truncating with "..." in
    -- narrow columns, so the box (and the whole closed-state height used
    -- by the open/close popup animation below) needs to follow its real
    -- height rather than assume a fixed single line.
    local function closedHeight()
        return items["name"].AbsoluteSize.Y + 4 + 28 + 4
    end
    local function repositionBox()
        items["box"].Position = dim2(0, 5, 0, items["name"].AbsoluteSize.Y + 4)
        if not popup or not popup.open then
            items["dropdown"].Size = dim2(1, 0, 0, closedHeight())
        end
    end
    items["name"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionBox)
    task.defer(repositionBox)

    items["box"] = library:create("Frame", {
        Parent = items["dropdown"],
        Name = "\0",
        Position = dim2(0, 5, 0, 22),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -10, 0, 28),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["box"],
        CornerRadius = dim(0, 6),
    })

    library:create("UIStroke", {
        Parent = items["box"],
        Color = themes.preset.line,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    items["selected"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = "None",
        Parent = items["box"],
        Name = "\0",
        Size = dim2(1, -34, 1, 0),
        Position = dim2(0, 11, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["arrow"] = library:create("ImageLabel", {
        ImageColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items["box"],
        AnchorPoint = vec2(1, 0.5),
        BackgroundTransparency = 1,
        Position = dim2(1, -10, 0.5, 0),
        Name = "\0",
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })
    ApplyIcon(items["arrow"], "chevron-down")

    items["hit"] = library:create("TextButton", {
        Parent = items["box"],
        Name = "\0",
        Text = "",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        ZIndex = 2,
        BorderSizePixel = 0,
    })

    -- popup was moved up next to items["dropdown"]'s creation (see comment
    -- there) so the reposition helpers could close over it.

    local popupFrame = library:create("Frame", {
        Parent = library["other"],
        Name = "\0",
        Size = dim2(0, 150, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 50,
    })

    local popupCorner = library:create("UICorner", {
        Parent = popupFrame,
        CornerRadius = dim(0, 6),
    })

    library:create("UIStroke", {
        Parent = popupFrame,
        Color = themes.preset.line,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local searchHolder = library:create("Frame", {
        Parent = popupFrame,
        Name = "\0",
        Size = dim2(1, 0, 0, 30),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.light,
        Visible = false,
        ZIndex = 51,
    })

    local searchIcon = library:create("ImageLabel", {
        Parent = searchHolder,
        BackgroundTransparency = 1,
        Position = dim2(0, 9, 0, 8),
        Size = dim2(0, 13, 0, 13),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 52,
    })
    ApplyIcon(searchIcon, "search")

    local searchBox = library:create("TextBox", {
        Parent = searchHolder,
        FontFace = fonts.font,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = themes.preset.dimtext,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 27, 0, 0),
        Size = dim2(1, -32, 1, 0),
        TextSize = 14,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    library:create("Frame", {
        Parent = searchHolder,
        Position = dim2(0, 6, 1, -1),
        Size = dim2(1, -12, 0, 1),
        BackgroundColor3 = themes.preset.line,
        BorderSizePixel = 0,
        ZIndex = 52,
    })

    local scroll = library:create("ScrollingFrame", {
        Parent = popupFrame,
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = dim2(0, 0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 51,
    })

    library:create("UIListLayout", {
        Parent = scroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = scroll,
        PaddingTop = dim(0, 4),
        PaddingBottom = dim(0, 4),
        PaddingLeft = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    local function applySearch(query)
        query = string.lower(query or "")
        for _, data in popup.order do
            local match = query == "" or string.find(string.lower(data.name), query, 1, true) ~= nil
            data.row.Visible = match
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(searchBox.Text)
    end)

    local function addRow(text)
        local row = library:create("TextButton", {
            Parent = scroll,
            Text = "",
            AutoButtonColor = false,
            Size = dim2(1, -4, 0, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            BackgroundColor3 = themes.preset.section,
            ZIndex = 52,
        })

        library:create("UICorner", {
            Parent = row,
            CornerRadius = dim(0, 4),
        })

        local line = library:create("Frame", {
            Parent = row,
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 6, 0.5, 0),
            Size = dim2(0, 3, 0, 0),
            BackgroundColor3 = themes.preset.accent,
            BorderSizePixel = 0,
            ZIndex = 53,
        })
        library:apply_theme(line, "accent", "BackgroundColor3")

        library:create("UICorner", {
            Parent = line,
            CornerRadius = dim(0, 4),
        })

        local label = library:create("TextLabel", {
            Parent = row,
            FontFace = fonts.font,
            Text = text,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0, 14, 0, 0),
            Size = dim2(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BorderSizePixel = 0,
            ZIndex = 53,
        })

        local data = {
            name = text,
            selected = false,
            row = row,
            line = line,
            label = label,
        }

        function data:Set(active, instant)
            data.selected = active
            local color = active and themes.preset.text or themes.preset.dimtext
            local bg = active and 0 or 1
            local lineH = active and 16 or 0
            if instant then
                row.BackgroundTransparency = bg
                label.TextColor3 = color
                line.Size = dim2(0, 3, 0, lineH)
            else
                library:tween(row, { BackgroundTransparency = bg })
                library:tween(label, { TextColor3 = color })
                library:tween(line, { Size = dim2(0, 3, 0, lineH) })
            end
        end

        row.MouseEnter:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 0.7 })
            end
        end)

        row.MouseLeave:Connect(function()
            if not data.selected then
                library:tween(row, { BackgroundTransparency = 1 })
            end
        end)

        row.MouseButton1Down:Connect(function()
            if cfg.multi then
                local idx = find(cfg.value, data.name)
                if idx then
                    remove(cfg.value, idx)
                    data:Set(false)
                else
                    insert(cfg.value, data.name)
                    data:Set(true)
                end
            else
                cfg.value = data.name
                for _, other in popup.order do
                    other:Set(other == data)
                end
                cfg.set_visible(false)
                cfg.open = false
            end
            cfg.report()
        end)

        insert(popup.order, data)
        return data
    end

    function cfg.refresh(new_options)
        if type(new_options) ~= "table" then return end
        for _, data in popup.order do
            if data.row then data.row:Destroy() end
        end
        popup.order = {}
        cfg.options = new_options
        for _, text in new_options do
            addRow(tostring(text))
        end
        if cfg.multi then
            cfg.value = {}
            items["selected"].Text = "None"
        else
            cfg.value = new_options[1]
            items["selected"].Text = tostring(new_options[1] or "None")
        end
        flags[cfg.flag] = cfg.value
    end
    cfg.Refresh = cfg.refresh

    function cfg.report()
        flags[cfg.flag] = cfg.value
        if cfg.multi then
            items["selected"].Text = #cfg.value > 0 and concat(cfg.value, ", ") or "None"
        else
            items["selected"].Text = cfg.value ~= nil and tostring(cfg.value) or "None"
        end
        if not library.silent then
            cfg.callback(cfg.value)
        end
    end

    function cfg.set_visible(bool)
        popup.open = bool
        if bool then
            local showSearch = #popup.order > 8
            local listHeight = min(#popup.order * 28 + 6, 160)
            local targetH = showSearch and (listHeight + 28) or listHeight

            searchBox.Text = ""
            applySearch("")
            searchHolder.Visible = showSearch
            if showSearch then
                scroll.Position = dim2(0, 0, 0, 28)
                scroll.Size = dim2(1, 0, 1, -28)
            else
                scroll.Position = dim2(0, 0, 0, 0)
                scroll.Size = dim2(1, 0, 1, 0)
            end

            popupFrame.BackgroundColor3 = themes.preset.light
            popupFrame.BackgroundTransparency = 0
            popupFrame.Position = dim2(0, 5, 0, closedHeight() - 2)
            popupFrame.Size = dim2(1, -10, 0, 0)
            popupFrame.Parent = items["dropdown"]
            popupFrame.Visible = true
            popupFrame.ClipsDescendants = true
            popupFrame.ZIndex = 5

            library:tween(items["dropdown"], {
                Size = dim2(1, 0, 0, closedHeight() + targetH),
            }, Enum.EasingStyle.Quint, 0.18)
            library:tween(popupFrame, {
                Size = dim2(1, -10, 0, targetH),
            }, Enum.EasingStyle.Quint, 0.18)
            library:tween(items["arrow"], { Rotation = 180 }, Enum.EasingStyle.Quint, 0.18)
            library:close_element(cfg)
        else
            library:tween(popupFrame, {
                Size = dim2(1, -10, 0, 0),
            }, Enum.EasingStyle.Quint, 0.15)
            library:tween(items["dropdown"], {
                Size = dim2(1, 0, 0, closedHeight()),
            }, Enum.EasingStyle.Quint, 0.15)
            library:tween(items["arrow"], { Rotation = 0 }, Enum.EasingStyle.Quint, 0.15)
            task.delay(0.16, function()
                if not popup.open then
                    popupFrame.Visible = false
                    popupFrame.Parent = library["other"]
                    items["dropdown"].Size = dim2(1, 0, 0, closedHeight())
                end
            end)
        end
    end

    library:connection(uis.InputBegan, function(input)
        if not popup.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local pos = input.Position
        local pAbs, pSize = popupFrame.AbsolutePosition, popupFrame.AbsoluteSize
        local bAbs, bSize = items["box"].AbsolutePosition, items["box"].AbsoluteSize
        local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X
            and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
        local overBox = pos.X >= bAbs.X and pos.X <= bAbs.X + bSize.X
            and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSize.Y
        if not overPopup and not overBox then
            cfg.set_visible(false)
            cfg.open = false
            if library.current_open == cfg then
                library.current_open = nil
            end
        end
    end)

    function cfg.set(value)
        if cfg.multi then
            if type(value) ~= "table" then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(find(value, data.name) ~= nil, true)
            end
        else
            local found = false
            for _, data in popup.order do
                if data.name == value then
                    found = true
                end
            end
            if not found and value ~= nil then
                return
            end
            cfg.value = value
            for _, data in popup.order do
                data:Set(data.name == value, true)
            end
        end
        cfg.report()
    end

    function cfg.refresh(list)
        for _, data in popup.order do
            data.row:Destroy()
        end
        popup.order = {}
        cfg.options = list
        for _, option in list do
            addRow(tostring(option))
        end
    end

    items["hit"].MouseButton1Down:Connect(function()
        cfg.open = not cfg.open
        cfg.set_visible(cfg.open)
    end)

    for _, option in cfg.options do
        addRow(tostring(option))
    end

    if cfg.default ~= nil then
        cfg.set(cfg.default)
    else
        cfg.report()
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:rangeslider(options)
    options = options or {}
    local cfg = {
        name = options.name or options.Name or "Range",
        min = tonumber(options.min or options.Min) or 0,
        max = tonumber(options.max or options.Max) or 100,
        float = tonumber(options.float or options.Float or options.Increment) or 1,
        min_gap = tonumber(options.min_gap or options.MinGap) or 0,
        suffix = options.suffix or options.Suffix or "",
        flag = options.flag or options.Flag or library:next_flag(),
        callback = options.callback or options.Callback or function() end,
        items = {},
    }
    local lo = tonumber(options.default_min or options.DefaultMin or cfg.min) or cfg.min
    local hi = tonumber(options.default_max or options.DefaultMax or cfg.max) or cfg.max
    lo = math.clamp(lo, cfg.min, cfg.max)
    hi = math.clamp(hi, cfg.min, cfg.max)
    if hi < lo then lo, hi = hi, lo end
    if hi - lo < cfg.min_gap then
        hi = math.min(cfg.max, lo + cfg.min_gap)
    end
    flags[cfg.flag] = { Min = lo, Max = hi }

    local items = cfg.items
    items.wrap = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 48),
        BorderSizePixel = 0,
    })
    items.name = library:create("TextLabel", {
        Parent = items.wrap,
        FontFace = fonts.font,
        Text = cfg.name,
        TextSize = 15,
        TextColor3 = themes.preset.dimtext,
        BackgroundTransparency = 1,
        Size = dim2(1, -90, 0, 16),
        Position = dim2(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
    })
    items.value = library:create("TextLabel", {
        Parent = items.wrap,
        FontFace = fonts.font,
        Text = tostring(lo) .. cfg.suffix .. " - " .. tostring(hi) .. cfg.suffix,
        TextSize = 13,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -6, 0, 0),
        Size = dim2(0, 120, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        BorderSizePixel = 0,
    })
    items.track = library:create("Frame", {
        Parent = items.wrap,
        BackgroundColor3 = themes.preset.light,
        Position = dim2(0, 5, 0, 28),
        Size = dim2(1, -10, 0, 6),
        BorderSizePixel = 0,
    })
    library:create("UICorner", { Parent = items.track, CornerRadius = dim(0, 3) })
    items.fill = library:create("Frame", {
        Parent = items.track,
        BackgroundColor3 = themes.preset.accent,
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
    })
    library:apply_theme(items.fill, "accent", "BackgroundColor3")
    library:create("UICorner", { Parent = items.fill, CornerRadius = dim(0, 3) })

    local function makeKnob()
        local k = library:create("Frame", {
            Parent = items.track,
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0, 0, 0.5, 0),
            Size = dim2(0, 14, 0, 14),
            BackgroundColor3 = rgb(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        library:create("UICorner", { Parent = k, CornerRadius = dim(1, 0) })
        library:create("UIStroke", { Parent = k, Color = themes.preset.line, Thickness = 1 })
        return k
    end
    local knobLo, knobHi = makeKnob(), makeKnob()

    local function quantize(v)
        local s = cfg.float
        return math.floor(v / s + 0.5) * s
    end

    local function apply(silent)
        local span = math.max(cfg.max - cfg.min, 1e-9)
        local a = (lo - cfg.min) / span
        local b = (hi - cfg.min) / span
        items.fill.Position = dim2(a, 0, 0, 0)
        items.fill.Size = dim2(math.max(b - a, 0), 0, 1, 0)
        knobLo.Position = dim2(a, 0, 0.5, 0)
        knobHi.Position = dim2(b, 0, 0.5, 0)
        items.value.Text = tostring(lo) .. cfg.suffix .. " - " .. tostring(hi) .. cfg.suffix
        flags[cfg.flag] = { Min = lo, Max = hi }
        if not silent then
            task.spawn(cfg.callback, lo, hi)
        end
    end

    local dragging = nil
    local function valueFromX(x)
        local absPos = items.track.AbsolutePosition.X
        local absSize = math.max(items.track.AbsoluteSize.X, 1)
        local rel = clamp((x - absPos) / absSize, 0, 1)
        return quantize(cfg.min + rel * (cfg.max - cfg.min))
    end

    items.track.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local v = valueFromX(input.Position.X)
        if math.abs(v - lo) <= math.abs(v - hi) then
            dragging = "lo"
            lo = math.min(v, hi - cfg.min_gap)
        else
            dragging = "hi"
            hi = math.max(v, lo + cfg.min_gap)
        end
        lo = clamp(lo, cfg.min, cfg.max)
        hi = clamp(hi, cfg.min, cfg.max)
        apply()
    end)
    knobLo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = "lo"
        end
    end)
    knobHi.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = "hi"
        end
    end)
    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = nil
        end
    end)
    library:connection(uis.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local v = valueFromX(input.Position.X)
        if dragging == "lo" then
            lo = clamp(math.min(v, hi - cfg.min_gap), cfg.min, cfg.max)
        else
            hi = clamp(math.max(v, lo + cfg.min_gap), cfg.min, cfg.max)
        end
        apply()
    end)

    function cfg.set(a, b, silent)
        if type(a) == "table" then
            b = a.Max or a[2]
            a = a.Min or a[1]
        end
        lo = clamp(quantize(tonumber(a) or lo), cfg.min, cfg.max)
        hi = clamp(quantize(tonumber(b) or hi), cfg.min, cfg.max)
        if hi < lo then
            lo, hi = hi, lo
        end
        if hi - lo < cfg.min_gap then
            hi = math.min(cfg.max, lo + cfg.min_gap)
        end
        apply(silent)
    end

    apply(true)
    config_flags[cfg.flag] = function(v)
        if type(v) == "table" then
            cfg.set(v.Min or v[1], v.Max or v[2], true)
        end
    end
    return setmetatable(cfg, library)
end

function library:button(options)
    options = options or {}
    local cfg = {
        name = options.name or options.Name or "Button",
        callback = options.callback or options.Callback or function() end,
        items = {},
    }

    local items = cfg.items
    items["button_element"] = library:create("Frame", {
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Parent = items["button_element"],
        Name = "\0",
        Position = dim2(1, -4, 0, 0),
        Size = dim2(1, -8, 0, 30),
        BorderSizePixel = 0,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["button"],
        CornerRadius = dim(0, 3),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["button"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["button"].MouseButton1Click:Connect(function()
        cfg.callback()
        items["name"].TextColor3 = themes.preset.accent
        library:tween(items["name"], { TextColor3 = themes.preset.text })
    end)

    return setmetatable(cfg, library)
end

function library:textbox(options)
    options = options or {}
    local cfg = {
        name = options.name or options.Name or "TextBox",
        placeholder = options.placeholder or options.Placeholder or options.placeholdertext or options.holder or "type here...",
        default = options.default or options.Default or "",
        flag = options.flag or options.Flag or library:next_flag(),
        callback = options.callback or options.Callback or function() end,
        items = {},
    }

    flags[cfg.flag] = cfg.default

    local items = cfg.items
    items["textbox"] = library:create("TextButton", {
        LayoutOrder = -1,
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = self.items["elements"],
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = items["textbox"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    items["right_components"] = library:create("Frame", {
        Parent = items["textbox"],
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 4, 0, 19),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    })

    items["input"] = library:create("TextBox", {
        FontFace = fonts.font,
        Text = "",
        Parent = items["right_components"],
        Name = "\0",
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        PlaceholderColor3 = themes.preset.dimtext,
        PlaceholderText = cfg.placeholder,
        ClearTextOnFocus = false,
        TextSize = 14,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Position = dim2(1, 0, 0, 0),
        Size = dim2(1, -4, 0, 30),
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["input"],
        CornerRadius = dim(0, 3),
    })

    library:create("UIPadding", {
        Parent = items["right_components"],
        PaddingTop = dim(0, 4),
        PaddingRight = dim(0, 4),
    })

    function cfg.set(text)
        flags[cfg.flag] = text
        items["input"].Text = text
        if not library.silent then
            cfg.callback(text)
        end
    end

    items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
        cfg.set(items["input"].Text)
    end)

    items["input"].Focused:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.text })
    end)

    items["input"].FocusLost:Connect(function()
        library:tween(items["input"], { TextColor3 = themes.preset.dimtext })
    end)

    if cfg.default ~= "" then
        cfg.set(cfg.default)
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:keybind(options)
    options = options or {}
    local cfg = {
        flag = options.flag or options.Flag or library:next_flag(),
        callback = options.callback or options.Callback or function() end,
        name = options.name or options.Name or nil,
        key = options.key or options.Key or (typeof(options.Default) == "EnumItem" and options.Default) or nil,
        mode = options.mode or options.Mode or "Toggle",
        active = options.active or false,
        open = false,
        binding = nil,
        items = {},
    }

    flags[cfg.flag] = {
        mode = cfg.mode,
        key = cfg.key,
        active = cfg.active,
    }

    local items = cfg.items
    local keybindParent = (self.items and (self.items["left_components"] or self.items["right_components"] or self.items["elements"])) or nil
    local inlineOnToggle = self.items and (self.items["left_components"] ~= nil or self.items["right_components"] ~= nil)
    items["keybind_element"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = keybindParent,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = inlineOnToggle and dim2(0, 48, 0, 18) or dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = inlineOnToggle and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255),
        LayoutOrder = 5,
        ZIndex = 8,
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.text,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name or "",
        Parent = items["keybind_element"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 16,
        BackgroundColor3 = rgb(255, 255, 255),
        Visible = not inlineOnToggle,
    })

    library:create("UIPadding", {
        Parent = items["name"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })
    if inlineOnToggle then
        -- compact key pill on the LEFT of the toggle row
        pcall(function()
            items["keybind_holder"].Parent = keybindParent
            items["keybind_holder"].Size = dim2(0, 46, 0, 18)
            items["keybind_holder"].AutomaticSize = Enum.AutomaticSize.X
            items["keybind_holder"].AnchorPoint = vec2(0, 0.5)
            items["keybind_holder"].Position = dim2(0, 0, 0.5, 0)
            items["keybind_holder"].ZIndex = 10
            items["keybind_element"].Visible = false
        end)
    end

    items["right_components"] = library:create("Frame", {
        Parent = items["keybind_element"],
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items["right_components"],
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    items["keybind_holder"] = library:create("TextButton", {
        FontFace = fonts.font,
        TextColor3 = rgb(0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = items["right_components"],
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0),
        Size = dim2(0, 0, 0, 16),
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 14,
        BackgroundColor3 = themes.preset.light,
    })

    library:create("UICorner", {
        Parent = items["keybind_holder"],
        CornerRadius = dim(0, 4),
    })

    items["key"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = "NONE",
        Parent = items["keybind_holder"],
        Name = "\0",
        Size = dim2(1, -12, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["key"],
        PaddingTop = dim(0, 1),
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(input)
        if type(input) == "boolean" then
            cfg.active = input
            if cfg.mode == "Always" then
                cfg.active = true
            end
        elseif tostring(input):find("Enum") then
            input = input.Name == "Escape" and "NONE" or input
            cfg.key = input or "NONE"
        elseif find({ "Toggle", "Hold", "Always" }, input) then
            if input == "Always" then
                cfg.active = true
            end
            cfg.mode = input
        elseif type(input) == "table" then
            input.key = type(input.key) == "string" and input.key ~= "NONE" and library:convert_enum(input.key) or input.key
            input.key = input.key == Enum.KeyCode.Escape and "NONE" or input.key
            cfg.key = input.key or "NONE"
            cfg.mode = input.mode or "Toggle"
            if input.active then
                cfg.active = input.active
            end
        end

        cfg.callback(cfg.active)

        local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
        local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
        items["key"].Text = __text or "NONE"

        flags[cfg.flag] = {
            mode = cfg.mode,
            key = cfg.key,
            active = cfg.active,
        }

        if cfg.flag == "menu_bind" and cfg.key and cfg.key ~= "NONE" then
            library.MenuKeybind = cfg.key
            local label = __text or "NONE"
            library.MenuKeyName = label
            pcall(function()
                if library.ProfileKeyBox then
                    library.ProfileKeyBox.Text = label
                end
            end)
        end
    end

    items["keybind_holder"].MouseButton1Down:Connect(function()
        task.wait()
        items["key"].Text = "..."
        cfg.binding = library:connection(uis.InputBegan, function(keycode)
            cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            cfg.binding:Disconnect()
            cfg.binding = nil
        end)
    end)

    local function keys_match(input)
        if not cfg.key or cfg.key == "NONE" then return false end
        local selected = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if selected == cfg.key then return true end
        if type(cfg.key) == "string" then
            local name = cfg.key:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", ""):gsub("KeyCode.", "")
            if selected.Name == name then return true end
            local ok, enumKey = pcall(function() return Enum.KeyCode[name] end)
            if ok and enumKey and selected == enumKey then return true end
        end
        return false
    end

    cfg.passive = options.passive == true or options.no_listen == true

    function cfg.set_active(on)
        cfg.active = on == true
        flags[cfg.flag] = flags[cfg.flag] or {}
        flags[cfg.flag].active = cfg.active
        flags[cfg.flag].key = cfg.key
        flags[cfg.flag].mode = cfg.mode
        if library.KeybindListInstance and library.KeybindListInstance.Refresh then
            pcall(library.KeybindListInstance.Refresh)
        end
    end

    if not cfg.passive then
        library:connection(uis.InputBegan, function(input, game_event)
            if game_event then return end
            if uis:GetFocusedTextBox() then return end
            if cfg.binding then return end
            if keys_match(input) then
                if cfg.mode == "Toggle" then
                    cfg.active = not cfg.active
                    flags[cfg.flag] = flags[cfg.flag] or {}
                    flags[cfg.flag].active = cfg.active
                    flags[cfg.flag].key = cfg.key
                    flags[cfg.flag].mode = cfg.mode
                    pcall(cfg.callback, cfg.active)
                    if library.KeybindListInstance and library.KeybindListInstance.Refresh then
                        pcall(library.KeybindListInstance.Refresh)
                    end
                elseif cfg.mode == "Hold" then
                    cfg.active = true
                    flags[cfg.flag] = flags[cfg.flag] or {}
                    flags[cfg.flag].active = true
                    pcall(cfg.callback, true)
                end
            end
        end)

        library:connection(uis.InputEnded, function(input, game_event)
            if game_event then return end
            if keys_match(input) and cfg.mode == "Hold" then
                cfg.active = false
                flags[cfg.flag] = flags[cfg.flag] or {}
                flags[cfg.flag].active = false
                pcall(cfg.callback, false)
            end
        end)
    end

    cfg.set({ mode = cfg.mode, active = cfg.active, key = cfg.key })

    if cfg.flag == "menu_bind" then
        local original_set = cfg.set
        cfg.set = function(input)
            original_set(input)
            local key = cfg.key
            if typeof(key) == "EnumItem" then
                library.MenuKeybind = key
                local label = keys[key] or key.Name
                if library.ProfileKeyBox and library.ProfileKeyBox.Parent then
                    library.ProfileKeyBox.Text = label
                end
            end
        end
    end

    config_flags[cfg.flag] = cfg.set

    do
        local entry = {
            flag = cfg.flag,
            name = cfg.name or cfg.flag,
            get_key = function()
                return cfg.key
            end,
            get_mode = function()
                return cfg.mode
            end,
            get_active = function()
                return cfg.active
            end,
            cfg = cfg,
        }

        local list = library.keybind_registry
        for i = #list, 1, -1 do
            if list[i].flag == cfg.flag then
                table.remove(list, i)
            end
        end
        table.insert(list, entry)

        local _set = cfg.set
        cfg.set = function(input)
            _set(input)
            if library.KeybindListInstance and library.KeybindListInstance.Refresh then
                pcall(library.KeybindListInstance.Refresh)
            end
        end
        config_flags[cfg.flag] = cfg.set

        if library.KeybindListInstance and library.KeybindListInstance.Refresh then
            pcall(library.KeybindListInstance.Refresh)
        end
    end

    return setmetatable(cfg, library)
end

function library:colorpicker(options)
    options = options or {}
    local cfg = {
        name = options.name or options.Name or "Color",
        flag = options.flag or options.Flag or library:next_flag(),
        color = options.color or options.Color or options.default or options.Default or themes.preset.accent,
        alpha = options.alpha or options.Alpha or options.transparency or options.Transparency or 0,
        callback = options.callback or options.Callback or function() end,
        items = {},
        open = false,
    }

    flags[cfg.flag] = { Color = cfg.color, Transparency = cfg.alpha }

    local items = cfg.items
    items["colorpicker"] = library:create("TextButton", {
        FontFace = fonts.small, TextColor3 = rgb(0, 0, 0), BorderColor3 = rgb(0, 0, 0),
        Text = "", AutoButtonColor = false, Parent = self.items["elements"], Name = "\0",
        BackgroundTransparency = 1, Size = dim2(1, 0, 0, 0), BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, BackgroundColor3 = rgb(255, 255, 255),
    })

    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font, TextColor3 = themes.preset.text, BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name, Parent = items["colorpicker"], Name = "\0", Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY, TextSize = 16, BackgroundColor3 = rgb(255, 255, 255),
    })
    library:create("UIPadding", { Parent = items["name"], PaddingRight = dim(0, 5), PaddingLeft = dim(0, 5) })

    items["swatch"] = library:create("TextButton", {
        FontFace = fonts.small, TextColor3 = rgb(0, 0, 0), BorderColor3 = rgb(0, 0, 0),
        Text = "", AutoButtonColor = false, AnchorPoint = vec2(1, 0), Parent = items["colorpicker"],
        Name = "\0", Position = dim2(1, 0, 0, 0), Size = dim2(0, 18, 0, 18),
        BorderSizePixel = 0, TextSize = 14, BackgroundColor3 = cfg.color,
    })
    library:create("UICorner", { Parent = items["swatch"], CornerRadius = dim(0, 4) })

    local h, s, v = Color3.toHSV(cfg.color)
    local popup = library:create("Frame", {
        Parent = library["other"], Name = "\0", Size = dim2(0, 200, 0, 0),
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, Visible = false,
        ZIndex = 90, ClipsDescendants = true,
    })
    library:create("UICorner", { Parent = popup, CornerRadius = dim(0, 8) })

    local satFrame = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 10, 0, 10), Size = dim2(0, 150, 0, 100),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
        Image = "rbxassetid://4155801252",
    })
    library:create("UICorner", { Parent = satFrame, CornerRadius = dim(0, 4) })

    local satCursor = library:create("Frame", {
        Parent = satFrame, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 8, 0, 8),
        Position = dim2(s, 0, 1 - v, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = satCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = satCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local hueBar = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 168, 0, 10), Size = dim2(0, 14, 0, 100),
        BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
        Image = "rbxassetid://3570695787", ScaleType = Enum.ScaleType.Stretch,
    })
    library:create("UICorner", { Parent = hueBar, CornerRadius = dim(0, 4) })
    local hueGrad = library:create("UIGradient", {
        Parent = hueBar,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, rgb(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, rgb(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, rgb(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, rgb(255, 0, 255)),
            ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
        }),
        Rotation = 90,
    })
    local hueCursor = library:create("Frame", {
        Parent = hueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(1, 4, 0, 4),
        Position = dim2(0.5, 0, h, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = hueCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = hueCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local alphaBar = library:create("ImageButton", {
        Parent = popup, Name = "\0", Position = dim2(0, 10, 0, 118), Size = dim2(0, 172, 0, 12),
        BackgroundColor3 = cfg.color, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 91,
    })
    library:create("UICorner", { Parent = alphaBar, CornerRadius = dim(0, 3) })
    local alphaCursor = library:create("Frame", {
        Parent = alphaBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 1, 4),
        Position = dim2(1 - cfg.alpha, 0, 0.5, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 92,
    })
    library:create("UICorner", { Parent = alphaCursor, CornerRadius = dim(1, 0) })
    library:create("UIStroke", { Parent = alphaCursor, Color = rgb(0, 0, 0), Thickness = 1 })

    local hexBox = library:create("TextBox", {
        Parent = popup, FontFace = fonts.font, Text = "", TextSize = 12,
        TextColor3 = themes.preset.text, BackgroundColor3 = themes.preset.light,
        Position = dim2(0, 10, 0, 140), Size = dim2(0, 172, 0, 22), BorderSizePixel = 0,
        ClearTextOnFocus = false, ZIndex = 91,
    })
    library:create("UICorner", { Parent = hexBox, CornerRadius = dim(0, 4) })
    library:create("UIPadding", { Parent = hexBox, PaddingLeft = dim(0, 6) })

    local function update_hex()
        local r = floor(cfg.color.R * 255)
        local g = floor(cfg.color.G * 255)
        local b = floor(cfg.color.B * 255)
        hexBox.Text = string.format("#%02X%02X%02X", r, g, b)
    end

    function cfg.set(color, alpha)
        if typeof(color) == "table" and color.Color then
            alpha = color.Transparency or alpha
            color = color.Color
        end
        if typeof(color) == "Color3" then
            cfg.color = color
            h, s, v = Color3.toHSV(color)
        end
        if type(alpha) == "number" then cfg.alpha = alpha end
        items["swatch"].BackgroundColor3 = cfg.color
        satFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satCursor.Position = dim2(s, 0, 1 - v, 0)
        hueCursor.Position = dim2(0.5, 0, h, 0)
        alphaBar.BackgroundColor3 = cfg.color
        alphaCursor.Position = dim2(1 - cfg.alpha, 0, 0.5, 0)
        update_hex()
        flags[cfg.flag] = { Color = cfg.color, Transparency = cfg.alpha }
        if not library.silent then
            cfg.callback(cfg.color, cfg.alpha)
        end
    end

    local function apply_hsv()
        cfg.set(Color3.fromHSV(h, s, v), cfg.alpha)
    end

    local dragging_sat, dragging_hue, dragging_alpha = false, false, false

    satFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_sat = true
            local relX = clamp((input.Position.X - satFrame.AbsolutePosition.X) / satFrame.AbsoluteSize.X, 0, 1)
            local relY = clamp((input.Position.Y - satFrame.AbsolutePosition.Y) / satFrame.AbsoluteSize.Y, 0, 1)
            s, v = relX, 1 - relY
            apply_hsv()
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_hue = true
            h = clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
            apply_hsv()
        end
    end)
    alphaBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_alpha = true
            cfg.alpha = 1 - clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            apply_hsv()
        end
    end)
    library:connection(uis.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if dragging_sat then
            local relX = clamp((input.Position.X - satFrame.AbsolutePosition.X) / satFrame.AbsoluteSize.X, 0, 1)
            local relY = clamp((input.Position.Y - satFrame.AbsolutePosition.Y) / satFrame.AbsoluteSize.Y, 0, 1)
            s, v = relX, 1 - relY
            apply_hsv()
        elseif dragging_hue then
            h = clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
            apply_hsv()
        elseif dragging_alpha then
            cfg.alpha = 1 - clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
            apply_hsv()
        end
    end)
    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_sat, dragging_hue, dragging_alpha = false, false, false
        end
    end)

    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:gsub("#", "")
        if #hex == 6 then
            local ok, col = pcall(Color3.fromHex, hex)
            if ok and col then cfg.set(col, cfg.alpha) end
        end
        update_hex()
    end)

    function cfg.set_visible(bool)
        cfg.open = bool
        if bool then
            local scale = 1
            local sp = items["swatch"].AbsolutePosition
            local ss = items["swatch"].AbsoluteSize
            local px = (sp.X + ss.X) / scale - 200
            local py = (sp.Y + ss.Y) / scale + 6
            popup.Size = dim2(0, 200, 0, 0)
            popup.Position = dim2(0, px, 0, py)
            popup.Parent = library["items"]
            popup.Visible = true
            library:tween(popup, { Size = dim2(0, 200, 0, 172) }, Enum.EasingStyle.Quint, 0.2)
            library:close_element(cfg)
        else
            library:tween(popup, { Size = dim2(0, 200, 0, 0) }, Enum.EasingStyle.Quint, 0.15)
            task.delay(0.17, function()
                if not cfg.open then
                    popup.Visible = false
                    popup.Parent = library["other"]
                end
            end)
        end
    end

    items["swatch"].MouseButton1Click:Connect(function()
        cfg.set_visible(not cfg.open)
    end)

    library:connection(uis.InputBegan, function(input)
        if not cfg.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local pAbs, pSize = popup.AbsolutePosition, popup.AbsoluteSize
        local sAbs, sSize = items["swatch"].AbsolutePosition, items["swatch"].AbsoluteSize
        local overPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
        local overSwatch = pos.X >= sAbs.X and pos.X <= sAbs.X + sSize.X and pos.Y >= sAbs.Y and pos.Y <= sAbs.Y + sSize.Y
        if not overPopup and not overSwatch then
            cfg.set_visible(false)
        end
    end)

    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

function library:label(options)
    local cfg = {
        name = options.name or "Label",
        items = {},
    }

    local items = cfg.items
    items["label"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = themes.preset.dimtext,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.items["elements"],
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 15,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIPadding", {
        Parent = items["label"],
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5),
    })

    function cfg.set(...)
        local args = {...}
        local text = args[#args]
        items["label"].Text = tostring(text)
    end
    cfg.Set = cfg.set

    return setmetatable(cfg, library)
end

function library:list(properties)
    local cfg = {
        items = {},
        options = properties.options or { "1", "2", "3" },
        flag = properties.flag or library:next_flag(),
        callback = properties.callback or function() end,
        data_store = {},
        current_element = nil,
    }

    local items = cfg.items
    items["list"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = rgb(255, 255, 255),
    })

    library:create("UIListLayout", {
        Parent = items["list"],
        Padding = dim(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    library:create("UIPadding", {
        Parent = items["list"],
        PaddingRight = dim(0, 4),
        PaddingLeft = dim(0, 4),
    })

    function cfg.refresh_options(options_to_refresh)
        for _, option in cfg.data_store do
            option:Destroy()
        end
        cfg.data_store = {}

        for _, option_data in options_to_refresh do
            local button = library:create("TextButton", {
                FontFace = fonts.small,
                TextColor3 = rgb(0, 0, 0),
                BorderColor3 = rgb(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = vec2(1, 0),
                Parent = items["list"],
                Name = "\0",
                Position = dim2(1, 0, 0, 0),
                Size = dim2(1, 0, 0, 30),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = themes.preset.light,
            })
            cfg.data_store[#cfg.data_store + 1] = button

            local name = library:create("TextLabel", {
                FontFace = fonts.font,
                TextColor3 = themes.preset.dimtext,
                BorderColor3 = rgb(0, 0, 0),
                Text = option_data,
                Parent = button,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 14,
                BackgroundColor3 = rgb(255, 255, 255),
            })

            library:create("UICorner", {
                Parent = button,
                CornerRadius = dim(0, 3),
            })

            button.MouseButton1Click:Connect(function()
                local current = cfg.current_element
                if current and current ~= name then
                    library:tween(current, { TextColor3 = themes.preset.dimtext })
                end
                flags[cfg.flag] = option_data
                cfg.callback(option_data)
                library:tween(name, { TextColor3 = themes.preset.text })
                cfg.current_element = name
            end)

            name.MouseEnter:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = rgb(140, 140, 140) })
            end)

            name.MouseLeave:Connect(function()
                if cfg.current_element == name then
                    return
                end
                library:tween(name, { TextColor3 = themes.preset.dimtext })
            end)
        end
    end

    cfg.refresh_options(cfg.options)
    return setmetatable(cfg, library)
end

function library:init_config(window)
    window:seperator({ name = "Settings" })

    local configsPage = window:tab({
        name = "Configs",
        icon = "folder",
        tabs = { "Configs" },
    })

    local left = configsPage:column({})
    local right = configsPage:column({})

    local createSec = left:section({ name = "Configs", icon = "folder", size = 1 })

    local createRow = library:create("Frame", {
        Parent = createSec.items["elements"],
        BackgroundTransparency = 1, Size = dim2(1, 0, 0, 32), BorderSizePixel = 0,
    })
    local nameBox = library:create("TextBox", {
        Parent = createRow, FontFace = fonts.font, Text = "", PlaceholderText = "config name",
        PlaceholderColor3 = themes.preset.dimtext, TextColor3 = themes.preset.text, TextSize = 14,
        BackgroundColor3 = themes.preset.light, ClearTextOnFocus = false,
        Position = dim2(0, 0, 0, 0), Size = dim2(1, -78, 1, 0), BorderSizePixel = 0,
    })
    library:create("UICorner", { Parent = nameBox, CornerRadius = dim(0, 6) })
    library:create("UIPadding", { Parent = nameBox, PaddingLeft = dim(0, 10), PaddingRight = dim(0, 10) })

    local createBtn = library:create("TextButton", {
        Parent = createRow, FontFace = fonts.font, Text = "Create", TextSize = 14,
        TextColor3 = themes.preset.text, AutoButtonColor = false, BackgroundColor3 = themes.preset.light,
        AnchorPoint = vec2(1, 0), Position = dim2(1, 0, 0, 0), Size = dim2(0, 70, 1, 0), BorderSizePixel = 0,
    })
    library:create("UICorner", { Parent = createBtn, CornerRadius = dim(0, 6) })

    local selected_config = nil
    local autoload_name = nil
    local config_rows = {}
    local show_info
    local refresh_list

    pcall(function()
        if isfile and isfile(library.directory .. "/autoload.txt") then
            autoload_name = readfile(library.directory .. "/autoload.txt")
        end
    end)

    createBtn.MouseButton1Click:Connect(function()
        local name = tostring(nameBox.Text or ""):gsub("[^%w _%-]", "")
        if name == "" then
            library:Notification({ Name = "Name required", Description = "Type a name before creating.", Icon = "triangle-alert" })
            return
        end
        local path = library.directory .. "/configs/" .. name .. ".json"
        if isfile and isfile(path) then
            library:Notification({ Name = "Already exists", Description = '"' .. name .. '" already exists.', Icon = "triangle-alert" })
            return
        end
        library:SaveConfigFile(name)
        nameBox.Text = ""
        selected_config = name
        refresh_list()
        show_info(name)
        library:Notification({ Name = "Config created", Description = '"' .. name .. '" saved.', Icon = "plus" })
    end)

    local listHolder = library:create("Frame", {
        Parent = createSec.items["elements"], Name = " ", BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
    })
    library:create("UIListLayout", { Parent = listHolder, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    local function make_icon_btn(parent, icon, x_offset, callback)
        local btn = library:create("TextButton", {
            Parent = parent, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            AnchorPoint = vec2(1, 0.5), Position = dim2(1, x_offset, 0.5, 0),
            Size = dim2(0, 22, 0, 22), BorderSizePixel = 0, ZIndex = 5,
        })
        local img = library:create("ImageLabel", {
            Parent = btn, BackgroundTransparency = 1, AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0), Size = dim2(0, 13, 0, 13),
            ImageColor3 = themes.preset.dimtext, BorderSizePixel = 0, ZIndex = 5,
        })
        ApplyIcon(img, icon)
        btn.MouseEnter:Connect(function() library:tween(img, { ImageColor3 = themes.preset.text }) end)
        btn.MouseLeave:Connect(function() library:tween(img, { ImageColor3 = themes.preset.dimtext }) end)
        btn.MouseButton1Click:Connect(callback)
        return btn, img
    end

    local function add_config_row(name)
        local row = library:create("Frame", {
            Parent = listHolder, Name = " ", Size = dim2(1, 0, 0, 36),
            BackgroundColor3 = themes.preset.light, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = row, CornerRadius = dim(0, 6) })

        local accent_bar = library:create("Frame", {
            Parent = row, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 0, 0.5, 0),
            Size = dim2(0, 3, 0, 0), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = accent_bar, CornerRadius = dim(0, 4) })
        library:apply_theme(accent_bar, "accent", "BackgroundColor3")

        local label = library:create("TextLabel", {
            Parent = row, FontFace = fonts.font, Text = name, TextSize = 14,
            TextColor3 = themes.preset.dimtext, BackgroundTransparency = 1,
            Position = dim2(0, 12, 0, 0), Size = dim2(1, -120, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0,
        })

        local autoIcon = library:create("ImageLabel", {
            Parent = row, BackgroundTransparency = 1,
            AnchorPoint = vec2(0, 0.5), Position = dim2(0, 12, 0.5, 0),
            Size = dim2(0, 0, 0, 0), ImageColor3 = themes.preset.accent,
            BorderSizePixel = 0, ZIndex = 4, Visible = false,
        })
        ApplyIcon(autoIcon, "star")
        library:apply_theme(autoIcon, "accent", "ImageColor3")

        local function update_auto_visual()
            if name == autoload_name then
                autoIcon.Visible = true
                autoIcon.Size = dim2(0, 12, 0, 12)
                label.Position = dim2(0, 28, 0, 0)
                label.Size = dim2(1, -136, 1, 0)
            else
                autoIcon.Visible = false
                autoIcon.Size = dim2(0, 0, 0, 0)
                label.Position = dim2(0, 12, 0, 0)
                label.Size = dim2(1, -120, 1, 0)
            end
        end
        update_auto_visual()

        local hit = library:create("TextButton", {
            Parent = row, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
            Size = dim2(1, -110, 1, 0), BorderSizePixel = 0, ZIndex = 3,
        })

        local function set_selected(active)
            label.TextColor3 = active and themes.preset.text or themes.preset.dimtext
            library:tween(accent_bar, { Size = dim2(0, 3, 0, active and 18 or 0) })
        end

        hit.MouseButton1Click:Connect(function()
            selected_config = name
            for _, r in config_rows do r.set_selected(r.name == name) end
            library:LoadConfigFile(name)
            show_info(name)
            library:Notification({ Name = "Config loaded", Description = 'Restored "' .. name .. '".', Icon = "check" })
        end)

        make_icon_btn(row, "download", -64, function()
            library:SaveConfigFile(name)
            show_info(name)
            library:Notification({ Name = "Config saved", Description = 'Overwrote "' .. name .. '".', Icon = "download" })
        end)
        make_icon_btn(row, "share-2", -42, function()
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) and setclipboard then
                setclipboard(readfile(path))
                library:Notification({ Name = "Config copied", Description = '"' .. name .. '" copied.', Icon = "share-2" })
            end
        end)
        make_icon_btn(row, "star", -20, function()
            if autoload_name == name then
                autoload_name = nil
                pcall(function()
                    if isfile(library.directory .. "/autoload.txt") then delfile(library.directory .. "/autoload.txt") end
                end)
                library:Notification({ Name = "Autoload cleared", Description = "No config will auto-load.", Icon = "star" })
            else
                autoload_name = name
                pcall(writefile, library.directory .. "/autoload.txt", name)
                library:Notification({ Name = "Autoload set", Description = '"' .. name .. '" will load on startup.', Icon = "star" })
            end

            for _, r in config_rows do
                r.update_auto()
            end
            if selected_config then show_info(selected_config) end
        end)
        make_icon_btn(row, "trash-2", 2, function()
            local path = library.directory .. "/configs/" .. name .. ".json"
            if isfile and isfile(path) then delfile(path) end
            if autoload_name == name then
                autoload_name = nil
                pcall(function()
                    if isfile(library.directory .. "/autoload.txt") then delfile(library.directory .. "/autoload.txt") end
                end)
            end
            if selected_config == name then
                selected_config = nil
                show_info(nil)
            end
            refresh_list()
            library:Notification({ Name = "Config deleted", Description = 'Removed "' .. name .. '".', Icon = "trash-2" })
        end)

        local data = {
            name = name, row = row, set_selected = set_selected,
            update_auto = update_auto_visual,
        }
        insert(config_rows, data)
        if name == selected_config then set_selected(true) end
        return data
    end

    refresh_list = function()
        for _, r in config_rows do r.row:Destroy() end
        config_rows = {}
        for _, name in library:ListConfigs() do
            add_config_row(name)
        end
    end
    refresh_list()

    local infoSec = right:section({ name = "Config info", icon = "info", size = 0.4 })
    local info_labels = {}
    local function add_info_row(key)
        local l = infoSec:label({ name = key .. ": -" })
        info_labels[key] = l
    end
    add_info_row("Config version")
    add_info_row("Compatibility")
    add_info_row("Created")
    add_info_row("Creator")
    add_info_row("Saved flags")
    add_info_row("Autoload")

    show_info = function(name)
        if not name then
            for k, l in pairs(info_labels) do l.set(k .. ": -") end
            return
        end
        local path = library.directory .. "/configs/" .. name .. ".json"
        local data = {}
        pcall(function() data = http_service:JSONDecode(readfile(path)) end)
        local count = 0
        for key in pairs(data) do
            if string.sub(tostring(key), 1, 2) ~= "__" then count = count + 1 end
        end
        local same = data.__version == library.version
        info_labels["Config version"].set("Config version: " .. (data.__version or "Unknown"))
        info_labels["Compatibility"].set("Compatibility: " .. (same and "Compatible" or "Outdated"))
        info_labels["Created"].set("Created: " .. (data.__created or "Unknown"))
        info_labels["Creator"].set("Creator: " .. (data.__creator or "Unknown"))
        info_labels["Saved flags"].set("Saved flags: " .. tostring(count) .. " flags")
        info_labels["Autoload"].set("Autoload: " .. ((autoload_name == name) and "Yes" or "No"))
    end
    show_info(nil)

    local themeSec = right:section({ name = "Theme", icon = "palette", size = 0.6 })
    themeSec:label({ name = "Presets" })

    local presets = {
        { name = "Default", color = rgb(155, 150, 219), bg = rgb(14, 14, 16), section = rgb(22, 22, 24), element = rgb(25, 25, 29), light = rgb(33, 33, 35) },
        { name = "Azure", color = rgb(96, 150, 255), bg = rgb(16, 20, 30), section = rgb(20, 25, 37), element = rgb(25, 31, 46), light = rgb(33, 41, 60) },
        { name = "Emerald", color = rgb(76, 214, 148), bg = rgb(14, 24, 20), section = rgb(18, 30, 25), element = rgb(23, 37, 31), light = rgb(30, 48, 40) },
        { name = "Ocean", color = rgb(72, 200, 214), bg = rgb(14, 23, 28), section = rgb(18, 28, 34), element = rgb(23, 35, 42), light = rgb(30, 45, 54) },
        { name = "Rose", color = rgb(240, 118, 150), bg = rgb(26, 17, 21), section = rgb(32, 21, 26), element = rgb(39, 26, 32), light = rgb(50, 33, 41) },
    }
    local dotsHolder = library:create("Frame", {
        Parent = themeSec.items["elements"], BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 24), BorderSizePixel = 0,
    })
    library:create("UIListLayout", {
        Parent = dotsHolder, FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left, Padding = dim(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for _, preset in presets do
        local dot = library:create("TextButton", {
            Parent = dotsHolder, Text = "", AutoButtonColor = false,
            Size = dim2(0, 18, 0, 18), BackgroundColor3 = preset.color, BorderSizePixel = 0,
        })
        library:create("UICorner", { Parent = dot, CornerRadius = dim(1, 0) })
        local stroke = library:create("UIStroke", { Parent = dot, Color = rgb(255, 255, 255), Thickness = 0 })
        dot.MouseButton1Click:Connect(function()
            library:update_theme("accent", preset.color)

            themes.preset.background = preset.bg or themes.preset.background
            themes.preset.section = preset.section or themes.preset.section
            themes.preset.element = preset.element or themes.preset.element
            themes.preset.light = preset.light or themes.preset.light

            library:update_theme("accent", preset.color)
            if config_flags["menu_accent"] then
                pcall(config_flags["menu_accent"], preset.color)
            else
                flags["menu_accent"] = { Color = preset.color, Transparency = 0 }
            end
            if config_flags["theme_bg"] then pcall(config_flags["theme_bg"], themes.preset.background) end
            if config_flags["theme_section"] then pcall(config_flags["theme_section"], themes.preset.section) end
            for _, child in dotsHolder:GetChildren() do
                if child:IsA("TextButton") then
                    local s = child:FindFirstChildOfClass("UIStroke")
                    if s then s.Thickness = (child == dot) and 2 or 0 end
                end
            end
        end)
    end

    themeSec:colorpicker({
        name = "Accent", flag = "menu_accent", color = themes.preset.accent,
        callback = function(color)
            library:update_theme("accent", color)
        end,
    })
    themeSec:colorpicker({
        name = "Background", flag = "theme_bg", color = themes.preset.background,
        callback = function(color) themes.preset.background = color end,
    })
    themeSec:colorpicker({
        name = "Section", flag = "theme_section", color = themes.preset.section,
        callback = function(color) themes.preset.section = color end,
    })
    themeSec:keybind({
        name = "Menu Bind", flag = "menu_bind",
        key = library.MenuKeybind or Enum.KeyCode.RightControl, mode = "Toggle",
        callback = function(bool)
            if window and window.toggle_menu then window.toggle_menu(bool) end
        end,
        default = true,
    })

    do
        local old_set = config_flags["menu_bind"]
        if old_set then
            config_flags["menu_bind"] = function(value)
                old_set(value)
                local key = value
                if type(value) == "table" then key = value.key or value[1] end
                if typeof(key) == "EnumItem" then
                    library.MenuKeybind = key
                    if library.ProfileKeyBox then
                        library.ProfileKeyBox.Text = keys[key] or key.Name
                    end
                end
            end
        end
    end

    if autoload_name then
        task.defer(function()
            if library:LoadConfigFile(autoload_name) then
                selected_config = autoload_name
                refresh_list()
                show_info(autoload_name)
            end
        end)
    end
end

function library:UserPanel(window)
    local userTab = window:tab({
        name = "User",
        icon = "user",
        tabs = { "Profile" },
    })

    local col = userTab:column({})
    local sec = col:section({ name = "Profile", icon = "user", size = 1 })

    local display = lp.DisplayName or lp.Name
    local uname = "@" .. (lp.Name or "unknown")
    local uid = tostring(lp.UserId or 0)

    local accountAge = "Unknown"
    pcall(function()
        accountAge = tostring(lp.AccountAge or 0) .. " days"
    end)

    sec:label({ name = display })
    sec:label({ name = uname })
    sec:label({ name = "User ID: " .. uid })
    sec:label({ name = "Account age: " .. accountAge })
    sec:label({ name = "Library: Noctro v" .. library.version })

    local menuKeyLabel = "RCtrl"
    pcall(function()
        local f = flags["menu_bind"]
        if type(f) == "table" and f.key then
            local k = f.key
            if typeof(k) == "EnumItem" then
                menuKeyLabel = keys[k] or k.Name
            else
                menuKeyLabel = tostring(k):gsub("Enum.KeyCode.", ""):gsub("KeyCode.", "")
            end
        end
    end)
    sec:label({ name = "Menu key: " .. tostring(menuKeyLabel) .. "  (change in Configs)" })

    sec:button({
        name = "Unload",
        callback = function()
            library:Notification({ Name = "Unloading", Description = "Noctro is shutting down.", Icon = "power" })
            task.wait(0.4)
            library:unload_menu()
        end,
    })

    return sec
end

local function clamp_panel_position(x, y, panel_w, panel_h)
    local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    panel_w = tonumber(panel_w) or 280
    panel_h = tonumber(panel_h) or 120
    local margin = 8
    local max_x = math.max(margin, vp.X - panel_w - margin)
    local max_y = math.max(margin, vp.Y - panel_h - margin)
    x = tonumber(x) or margin
    y = tonumber(y) or margin
    if x < -panel_w + 40 or x > vp.X - 40 or y < -40 or y > vp.Y - 40 then
        x, y = margin, math.floor(vp.Y * 0.35)
    end
    return math.clamp(x, margin, max_x), math.clamp(y, margin, max_y)
end

function library:KeybindList(params)
    params = params or {}
    if library.KeybindListInstance and library.KeybindListInstance.Gui then
        return library.KeybindListInstance
    end

    local title = params.Title or params.Name or "Keybind list"
    local position = params.Position or dim2(0, 18, 0.4, 0)
    local visible = params.Visible ~= false

    local pos_file = library.directory .. "/keybindlist_pos.json"
    pcall(function()
        if isfile and isfile(pos_file) then
            local data = http_service:JSONDecode(readfile(pos_file))
            if type(data) == "table" and data.x ~= nil and data.y ~= nil then
                local cx, cy = clamp_panel_position(data.x, data.y, 280, 200)
                position = dim2(0, cx, 0, cy)
            end
        end
    end)
    do
        local ox = position.X.Offset + (camera.ViewportSize.X * position.X.Scale)
        local oy = position.Y.Offset + (camera.ViewportSize.Y * position.Y.Scale)
        local cx, cy = clamp_panel_position(ox, oy, 280, 200)
        position = dim2(0, cx, 0, cy)
    end

    local gui = library:create("ScreenGui", {
        Parent = get_hui(),
        Name = "\0",
        Enabled = true,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9990,
    })

    local panel = library:create("Frame", {
        Parent = gui,
        Position = position,
        Size = dim2(0, 280, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 70,
        Active = true,
    })
    library:create("UICorner", { Parent = panel, CornerRadius = dim(0, 10) })

    local function save_keybindlist_pos()
        pcall(function()
            if not writefile then return end
            pcall(makefolder, library.directory)
            local p = panel.Position
            writefile(pos_file, http_service:JSONEncode({
                x = math.floor(p.X.Offset + 0.5),
                y = math.floor(p.Y.Offset + 0.5),
            }))
        end)
    end
    library:create("UIStroke", {
        Parent = panel,
        Color = rgb(30, 30, 36),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    library:create("UIPadding", {
        Parent = panel,
        PaddingTop = dim(0, 12),
        PaddingBottom = dim(0, 10),
        PaddingLeft = dim(0, 12),
        PaddingRight = dim(0, 12),
    })
    library:create("UIListLayout", {
        Parent = panel,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 8),
    })

    local header = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 22),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 0,
    })

    local listIcon = library:create("ImageButton", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = dim2(0, 16, 0, 16),
        Position = dim2(0, 0, 0.5, -8),
        ImageColor3 = themes.preset.accent,
        BorderSizePixel = 0,
        ZIndex = 73,
        ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(listIcon, "menu")
    library:apply_theme(listIcon, "accent", "ImageColor3")

    local titleLabel = library:create("TextLabel", {
        Parent = header,
        FontFace = fonts.font,
        Text = title,
        TextSize = 15,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 22, 0, 0),
        Size = dim2(1, -44, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 72,
    })

    local pinBtn = library:create("ImageButton", {
        Parent = header,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, 0, 0.5, 0),
        Size = dim2(0, 16, 0, 16),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 73,
        ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(pinBtn, "pin")

    local pinned = false
    pinBtn.MouseButton1Click:Connect(function()
        pinned = not pinned
        pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
    end)

    local cols = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 1,
        Name = "Cols",
    })

    local function colHeader(text, xScale, xOffset, width, align)
        return library:create("TextLabel", {
            Parent = cols,
            FontFace = fonts.font,
            Text = text,
            TextSize = 12,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(xScale, xOffset, 0, 0),
            Size = dim2(0, width, 1, 0),
            TextXAlignment = align or Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            ZIndex = 72,
        })
    end
    colHeader("Function", 0, 4, 100, Enum.TextXAlignment.Left)
    colHeader("Hotkey", 0.5, -10, 50, Enum.TextXAlignment.Center)
    colHeader("Status", 1, -70, 66, Enum.TextXAlignment.Right)

    local divider = library:create("Frame", {
        Parent = panel,
        Size = dim2(1, 0, 0, 1),
        BackgroundColor3 = themes.preset.line or rgb(21, 21, 23),
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 2,
        Name = "Divider",
    })

    local rowsFolder = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 3,
        Name = "Rows",
    })
    library:create("UIListLayout", {
        Parent = rowsFolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 2),
    })

    local collapsed = false
    local animating = false
    local body = library:create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 71,
        LayoutOrder = 1,
        ClipsDescendants = true,
        Name = "Body",
    })

    cols.Parent = body
    cols.LayoutOrder = 1
    divider.Parent = body
    divider.LayoutOrder = 2
    rowsFolder.Parent = body
    rowsFolder.LayoutOrder = 3
    library:create("UIListLayout", {
        Parent = body,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 8),
    })

    local function fade_descendants(root, transparency, t)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                library:tween(d, { TextTransparency = transparency }, Enum.EasingStyle.Quart, t)
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                library:tween(d, { ImageTransparency = transparency }, Enum.EasingStyle.Quart, t)
            elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then

            end
        end

        for _, d in ipairs(root:GetChildren()) do
            if d:IsA("TextLabel") then
                library:tween(d, { TextTransparency = transparency }, Enum.EasingStyle.Quart, t)
            end
        end
    end

    local function measure_body()

        local h = 0
        pcall(function()
            h = body.AbsoluteSize.Y
        end)
        if h < 1 then

            local rows = 0
            for _, ch in ipairs(rowsFolder:GetChildren()) do
                if ch:IsA("GuiObject") and ch.Visible then
                    rows = rows + ch.AbsoluteSize.Y + 2
                end
            end
            h = 16 + 1 + 8 + math.max(rows, 0)
        end
        return math.max(h, 0)
    end

    local function set_collapsed(state)
        if animating then return end
        local want = state == true
        if want == collapsed then return end
        animating = true
        collapsed = want

        local duration = 0.28

        if collapsed then

            body.AutomaticSize = Enum.AutomaticSize.None
            local h = measure_body()
            if h < 8 then h = 40 end
            body.Size = dim2(1, 0, 0, h)
            fade_descendants(body, 1, duration * 0.7)
            library:tween(body, { Size = dim2(1, 0, 0, 0) }, Enum.EasingStyle.Quart, duration)
            library:tween(listIcon, { ImageColor3 = themes.preset.dimtext, Rotation = -90 }, Enum.EasingStyle.Quart, duration)
            task.delay(duration, function()
                if collapsed then
                    cols.Visible = false
                    divider.Visible = false
                    rowsFolder.Visible = false
                end
                animating = false
            end)
        else
            cols.Visible = true
            divider.Visible = true
            rowsFolder.Visible = true

            body.AutomaticSize = Enum.AutomaticSize.None
            body.Size = dim2(1, 0, 0, 0)

            fade_descendants(body, 1, 0)
            task.defer(function()
                local target = measure_body()
                if target < 8 then

                    task.wait()
                    target = measure_body()
                end
                if target < 8 then target = 48 end
                library:tween(body, { Size = dim2(1, 0, 0, target) }, Enum.EasingStyle.Quart, duration)
                fade_descendants(body, 0, duration)
                library:tween(listIcon, { ImageColor3 = themes.preset.accent, Rotation = 0 }, Enum.EasingStyle.Quart, duration)
                task.delay(duration, function()
                    if not collapsed then
                        body.AutomaticSize = Enum.AutomaticSize.Y
                        body.Size = dim2(1, 0, 0, 0)
                    end
                    animating = false
                end)
            end)
        end
    end

    listIcon.MouseButton1Click:Connect(function()
        set_collapsed(not collapsed)
    end)

    local row_map = {}

    local function key_label(key)
        if not key or key == "NONE" then return "—" end
        if typeof(key) == "EnumItem" then
            return keys[key] or tostring(key.Name):gsub("KeyCode.", ""):gsub("UserInputType.", "")
        end
        return tostring(key)
            :gsub("Enum.KeyCode.", "")
            :gsub("Enum.UserInputType.", "")
            :gsub("KeyCode.", "")
    end

    local function read_active(entry)

        local active = false
        if entry.get_active then
            local ok, v = pcall(entry.get_active)
            if ok and v == true then return true end
            if ok and v == false then active = false end
        end
        local f = flags[entry.flag]
        if type(f) == "table" and f.active == true then return true end
        if entry.cfg and entry.cfg.active == true then return true end
        return active
    end

    local function ensure_row(entry, order)
        local flag = entry.flag
        local row = row_map[flag]
        if row and row.frame and row.frame.Parent then
            row.entry = entry
            row.frame.LayoutOrder = order or row.frame.LayoutOrder
            return row
        end

        local frame = library:create("TextButton", {
            Parent = rowsFolder,
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = themes.preset.element,
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 28),
            BorderSizePixel = 0,
            ZIndex = 72,
            LayoutOrder = order or 0,
        })
        library:create("UICorner", { Parent = frame, CornerRadius = dim(0, 6) })

        local nameLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = entry.name or flag,
            TextSize = 13,
            TextColor3 = themes.preset.text,
            BackgroundTransparency = 1,
            Position = dim2(0, 4, 0, 0),
            Size = dim2(0.42, -4, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        local keyLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = "—",
            TextSize = 13,
            TextColor3 = themes.preset.text,
            BackgroundTransparency = 1,
            Position = dim2(0.42, 0, 0, 0),
            Size = dim2(0.22, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        local statusLbl = library:create("TextLabel", {
            Parent = frame,
            FontFace = fonts.font,
            Text = "Toggle",
            TextSize = 13,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0.64, 0, 0, 0),
            Size = dim2(0.36, -4, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            BorderSizePixel = 0,
            ZIndex = 73,
        })

        frame.MouseEnter:Connect(function()
            if collapsed then return end
            local r = row_map[flag]
            if r then r._hovered = true end
            frame.BackgroundTransparency = 0
            frame.BackgroundColor3 = themes.preset.element
        end)
        frame.MouseLeave:Connect(function()
            local r = row_map[flag]
            if r then r._hovered = false end
            local active = false
            if r and r.entry then active = read_active(r.entry) end
            frame.BackgroundTransparency = active and 0.35 or 1
        end)

        row = {
            frame = frame,
            nameLbl = nameLbl,
            keyLbl = keyLbl,
            statusLbl = statusLbl,
            entry = entry,
            _hovered = false,
        }
        row_map[flag] = row
        return row
    end

    local function read_mode(entry)
        local mode = "Toggle"
        pcall(function()
            if entry.get_mode then
                mode = tostring(entry.get_mode() or mode)
            elseif entry.cfg and entry.cfg.mode then
                mode = tostring(entry.cfg.mode)
            elseif flags[entry.flag] and type(flags[entry.flag]) == "table" and flags[entry.flag].mode then
                mode = tostring(flags[entry.flag].mode)
            end
        end)
        mode = mode:gsub("^%l", string.upper)
        if mode ~= "Hold" and mode ~= "Always" then mode = "Toggle" end
        return mode
    end

    local function apply_row_state(row, active, key, mode)
        row.keyLbl.Text = key_label(key)
        mode = mode or read_mode(row.entry or {})

        if row.statusLbl then
            row.statusLbl.Text = mode
            row.statusLbl.TextColor3 = active and themes.preset.accent or themes.preset.dimtext
        end
        if active then
            row.nameLbl.TextColor3 = themes.preset.text
            row.keyLbl.TextColor3 = themes.preset.accent
            row.frame.BackgroundTransparency = 0.35
            row.frame.BackgroundColor3 = themes.preset.element
        else
            row.nameLbl.TextColor3 = themes.preset.text
            row.keyLbl.TextColor3 = themes.preset.text
            if not row._hovered then
                row.frame.BackgroundTransparency = 1
            end
        end
    end

    local function refresh()
        local seen = {}
        local order = 0
        for _, entry in ipairs(library.keybind_registry or {}) do
            if entry.name and entry.name ~= "" then
                order = order + 1
                seen[entry.flag] = true
                local row = ensure_row(entry, order)
                local active = read_active(entry)
                local key = "NONE"
                pcall(function()
                    if entry.get_key then key = entry.get_key() end
                end)
                row.nameLbl.Text = tostring(entry.name)
                local mode = read_mode(entry)
                apply_row_state(row, active, key, mode)
                row._was_active = active
                row._last_key = key
                row._last_mode = mode
            end
        end
        for flag, row in pairs(row_map) do
            if not seen[flag] then
                pcall(function() row.frame:Destroy() end)
                row_map[flag] = nil
            end
        end
    end

    do
        local dragging, start, start_pos
        local function begin_drag(input)
            if pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = input.Position
                start_pos = panel.Position
            end
        end
        header.InputBegan:Connect(begin_drag)
        titleLabel.InputBegan:Connect(begin_drag)
        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    save_keybindlist_pos()
                end
            end
        end)
        library:connection(uis.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    save_keybindlist_pos()
                end
            end
        end)
        library:connection(uis.InputChanged, function(input)
            if not dragging or pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local nx = start_pos.X.Offset + (input.Position.X - start.X)
                local ny = start_pos.Y.Offset + (input.Position.Y - start.Y)
                local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or 280
                local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or 120
                nx, ny = clamp_panel_position(nx, ny, pw, ph)
                panel.Position = dim2(0, nx, 0, ny)
            end
        end)
    end

    local _kbListAccum = 0
    library:connection(run.Heartbeat, function(dt)
        if not panel.Parent or not panel.Visible then return end
        _kbListAccum = _kbListAccum + (dt or 0.016)
        if _kbListAccum < 0.1 then return end
        _kbListAccum = 0

        for _, row in pairs(row_map) do
            local entry = row.entry
            if entry then
                local active = read_active(entry)
                local key = "NONE"
                pcall(function()
                    if entry.get_key then key = entry.get_key() end
                end)
                local mode = read_mode(entry)
                if row._was_active ~= active or row._last_key ~= key or row._last_mode ~= mode then
                    row._was_active = active
                    row._last_key = key
                    row._last_mode = mode
                    if not collapsed then
                        apply_row_state(row, active, key, mode)
                    end
                end
            end
        end
    end)

    local api = {
        Gui = gui,
        Panel = panel,
        Refresh = refresh,
        ResetPosition = function()
            local cx, cy = clamp_panel_position(18, math.floor((camera.ViewportSize.Y or 800) * 0.38), 280, 200)
            panel.Position = dim2(0, cx, 0, cy)
            save_keybindlist_pos()
        end,
        SetVisible = function(bool)
            visible = bool == true
            panel.Visible = visible
        end,
        SetCollapsed = set_collapsed,
        SetPinned = function(bool)
            pinned = bool == true
            pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
            if pinned then dock_to_main() end
        end,
        DockToMain = function()
            dock_to_main()
        end,
        SetTitle = function(t)
            titleLabel.Text = tostring(t)
        end,
        Destroy = function()
            pcall(function() gui:Destroy() end)
            library.KeybindListInstance = nil
        end,
    }

    library.KeybindListInstance = api
    refresh()
    task.defer(function()
        pcall(function()
            local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or 280
            local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or 120
            local cx, cy = clamp_panel_position(panel.AbsolutePosition.X, panel.AbsolutePosition.Y, pw, ph)
            panel.Position = dim2(0, cx, 0, cy)
            save_keybindlist_pos()
        end)
    end)
    return api
end

function library:Watermark(params)
    params = params or {}
    if library.WatermarkBar then
        return library.WatermarkBar
    end

    if not library["watermark_gui"] then
        library["watermark_gui"] = library:create("ScreenGui", {
            Parent = get_hui(),
            Name = "\0",
            Enabled = true,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 9999,
        })
    end

    local Icon = params.Icon or "layers"
    local Items = {}

    Items.Bar = library:create("Frame", {
        Parent = library["watermark_gui"],
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 0, 14),
        Size = dim2(0, 0, 0, 32),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 60,
        Active = false,
    })
    Items.Bar.AutomaticSize = Enum.AutomaticSize.X

    library:create("UICorner", {
        Parent = Items.Bar,
        CornerRadius = dim(0, 8),
    })

    library:create("UIPadding", {
        Parent = Items.Bar,
        PaddingLeft = dim(0, 12),
        PaddingRight = dim(0, 12),
    })

    library:create("UIListLayout", {
        Parent = Items.Bar,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = dim(0, 10),
    })

    local order = 0
    local function NextOrder()
        order = order + 1
        return order
    end

    local iconLabel = library:create("ImageLabel", {
        Parent = Items.Bar,
        BackgroundTransparency = 1,
        Size = dim2(0, 20, 0, 20),
        ImageColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 61,
        ScaleType = Enum.ScaleType.Fit,
    })
    iconLabel.LayoutOrder = NextOrder()
    library._logoTargets = library._logoTargets or {}
    table.insert(library._logoTargets, iconLabel)
    pcall(function()
        local id = library.LoadEmblemLogo and library.LoadEmblemLogo()
        if id then iconLabel.Image = id iconLabel.ImageColor3 = rgb(255,255,255) end
    end)
    ApplyIcon(iconLabel, Icon)

    local function Separator()
        local Sep = library:create("Frame", {
            Parent = Items.Bar,
            Size = dim2(0, 1, 0, 14),
            BackgroundColor3 = themes.preset.light,
            BorderSizePixel = 0,
            ZIndex = 61,
        })
        Sep.LayoutOrder = NextOrder()
    end

    local function Stat(Text)
        local Label = library:create("TextLabel", {
            Parent = Items.Bar,
            FontFace = fonts.font,
            Text = Text,
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Size = dim2(0, 0, 0, 16),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 61,
        })
        Label.LayoutOrder = NextOrder()
        return Label
    end

    local NameStat = Stat("Emblem")
    NameStat.TextColor3 = rgb(255, 255, 255)
    Separator()
    local GameStat = Stat("...")
    Separator()
    local UserStat = Stat((players.LocalPlayer and players.LocalPlayer.Name) or "Player")
    Separator()
    local FpsStat = Stat("0 fps")

    task.spawn(function()
        local Ok, Info = pcall(function()
            return marketplace:GetProductInfo(game.PlaceId)
        end)
        GameStat.Text = (Ok and Info and Info.Name) or "Unknown"
    end)

    local Frames = 0
    library:connection(run.RenderStepped, function()
        Frames = Frames + 1
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not Items.Bar or not Items.Bar.Parent then
                break
            end
            FpsStat.Text = tostring(Frames * 2) .. " fps"
            Frames = 0
        end
    end)

    Items.Bar.Active = false
    library.WatermarkBar = Items.Bar

    -- The bar has a fixed top-center screen position, but the main menu
    -- window is user-draggable and can end up anywhere - including
    -- right under the watermark's default spot, which is exactly what
    -- was happening here. Track the menu's live bounds each frame and
    -- nudge the bar below the menu whenever they'd actually overlap,
    -- rather than assuming a fixed position is always clear.
    local DEFAULT_POS = dim2(0.5, 0, 0, 14)
    library:connection(run.RenderStepped, function()
        if not Items.Bar or not Items.Bar.Parent then return end
        local main = library.items and library.items:FindFirstChild("main")
        if not (main and main.Parent and main.Visible) then
            if Items.Bar.Position ~= DEFAULT_POS then
                Items.Bar.Position = DEFAULT_POS
            end
            return
        end
        local mp, ms = main.AbsolutePosition, main.AbsoluteSize
        local bp, bs = Items.Bar.AbsolutePosition, Items.Bar.AbsoluteSize
        local overlaps = bp.X < mp.X + ms.X and bp.X + bs.X > mp.X
            and bp.Y < mp.Y + ms.Y and bp.Y + bs.Y > mp.Y
        if overlaps then
            Items.Bar.Position = UDim2.fromOffset(mp.X + ms.X * 0.5, mp.Y + ms.Y + 10)
            Items.Bar.AnchorPoint = vec2(0.5, 0)
        elseif Items.Bar.Position ~= DEFAULT_POS then
            Items.Bar.Position = DEFAULT_POS
        end
    end)

    local Watermark = { Instance = Items.Bar }

    function Watermark:SetIcon(NewIcon)
        ApplyIcon(iconLabel, NewIcon)
    end

    function Watermark:SetVisible(Bool)
        Items.Bar.Visible = Bool
    end

    return Watermark
end

library.Notifs = {}

function library:Notification(Params)
    if library.silent then return end

    Params = Params or {}
    local Title = Params.Name or Params.Title or "Notification"
    local Content = Params.Description or Params.Content or Params.info or ""
    local Icon = Params.Icon or Params.icon or "bell"
    local Accent = Params.Color or themes.preset.accent
    local Duration = Params.Duration or Params.lifetime or 5

    local CardW = 300
    local bodyH = 0
    if Content ~= "" then
        bodyH = math.max(18, math.ceil(#Content / 36) * 16)
    end
    local CardH = 38 + (Content ~= "" and bodyH + 6 or 0) + 18

    local parent = library["items"] or coregui

    local Frame = library:create("Frame", {
        Parent = parent,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, 340, 0, 15),
        Size = dim2(0, CardW, 0, CardH),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 80,
    })

    library:create("UICorner", {
        Parent = Frame,
        CornerRadius = dim(0, 10),
    })

    local IconImg = library:create("ImageLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Position = dim2(0, 13, 0, 11),
        Size = dim2(0, 18, 0, 18),
        ImageColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 81,
    })
    ApplyIcon(IconImg, Icon)

    library:create("TextLabel", {
        Parent = Frame,
        FontFace = fonts.font,
        Text = Title,
        TextSize = 15,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 40, 0, 10),
        Size = dim2(1, -70, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        ZIndex = 81,
    })

    local CloseImg = library:create("ImageLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -13, 0, 13),
        Size = dim2(0, 14, 0, 14),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 82,
    })
    ApplyIcon(CloseImg, "x")

    local CloseHit = library:create("TextButton", {
        Parent = Frame,
        Text = "",
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -8, 0, 8),
        Size = dim2(0, 24, 0, 24),
        BorderSizePixel = 0,
        ZIndex = 83,
    })

    if Content ~= "" then
        library:create("TextLabel", {
            Parent = Frame,
            FontFace = fonts.font,
            Text = Content,
            TextSize = 14,
            TextColor3 = themes.preset.dimtext,
            BackgroundTransparency = 1,
            Position = dim2(0, 13, 0, 35),
            Size = dim2(1, -26, 0, bodyH),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            BorderSizePixel = 0,
            ZIndex = 81,
        })
    end

    local BarBack = library:create("Frame", {
        Parent = Frame,
        Position = dim2(0, 13, 1, -12),
        Size = dim2(1, -26, 0, 5),
        BackgroundColor3 = themes.preset.element or themes.preset.light,
        BorderSizePixel = 0,
        ZIndex = 81,
    })
    library:create("UICorner", { Parent = BarBack, CornerRadius = dim(0, 4) })

    local BarFill = library:create("Frame", {
        Parent = BarBack,
        Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 82,
    })
    library:create("UICorner", { Parent = BarFill, CornerRadius = dim(0, 4) })
    library:apply_theme(BarFill, "accent", "BackgroundColor3")

    local Notif = {
        Frame = Frame,
        Dead = false,
        Height = CardH,
    }
    insert(library.Notifs, Notif)

    local function StackHeight(Stop)
        local Y = 15
        for _, Value in library.Notifs do
            if Value == Stop then break end
            if Value.Dead then continue end
            Y = Y + Value.Height + 10
        end
        return Y
    end

    local function Reflow()
        local Y = 15
        for _, Value in library.Notifs do
            if Value.Dead then continue end
            library:tween(Value.Frame, { Position = dim2(1, -15, 0, Y) }, Enum.EasingStyle.Quart, 0.3)
            Y = Y + Value.Height + 10
        end
    end

    local StartY = StackHeight(Notif)
    Frame.Position = dim2(1, 340, 0, StartY)
    library:tween(Frame, { Position = dim2(1, -15, 0, StartY) }, Enum.EasingStyle.Exponential, 0.45)

    local function Dismiss()
        if Notif.Dead then return end
        Notif.Dead = true
        local Current = Frame.Position
        library:tween(Frame, { Position = dim2(1, -15, 0, Current.Y.Offset - 14) }, Enum.EasingStyle.Quart, 0.25)
        library:tween(Frame, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
        for _, d in Frame:GetDescendants() do
            if d:IsA("TextLabel") then
                library:tween(d, { TextTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            elseif d:IsA("ImageLabel") then
                library:tween(d, { ImageTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            elseif d:IsA("Frame") then
                library:tween(d, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, 0.25)
            end
        end
        task.delay(0.3, function()
            local Index = find(library.Notifs, Notif)
            if Index then remove(library.Notifs, Index) end
            Frame:Destroy()
            Reflow()
        end)
    end

    CloseHit.MouseButton1Down:Connect(Dismiss)
    library:tween(BarFill, { Size = dim2(0, 0, 1, 0) }, Enum.EasingStyle.Linear, Duration)
    task.delay(Duration, Dismiss)
end

function library:EspPreview(options)
    options = options or {}
    if library.EspPreviewInstance and library.EspPreviewInstance.Gui and library.EspPreviewInstance.Gui.Parent then
        local existing = library.EspPreviewInstance
        if options.Visible ~= false then
            pcall(function()
                if existing.SetVisible then existing.SetVisible(true) end
                if existing.Refresh then existing.Refresh() end
            end)
        end
        return existing
    end

    local getVisuals = options.GetVisuals or options.getVisuals or function() return {} end
    local getPlayer = options.GetPlayer or options.getPlayer or function() return lp end
    local enabledFlag = options.Flag or options.flag or "esp_preview_enabled"
    local title = options.Title or options.Name or options.name or "ESP Preview"
    local height = tonumber(options.Height or options.height) or 320
    local width = tonumber(options.Width or options.width) or 260
    local visible = options.Visible ~= false
    local position = options.Position or dim2(1, -width - 18, 0.32, 0)

    local pos_file = library.directory .. "/esppreview_pos.json"
    pcall(function()
        if isfile and isfile(pos_file) then
            local data = http_service:JSONDecode(readfile(pos_file))
            if type(data) == "table" and data.x ~= nil and data.y ~= nil then
                local cx, cy = clamp_panel_position(data.x, data.y, width, height + 42)
                position = dim2(0, cx, 0, cy)
            end
        end
    end)
    do
        local ox = position.X.Offset + (camera.ViewportSize.X * position.X.Scale)
        local oy = position.Y.Offset + (camera.ViewportSize.Y * position.Y.Scale)
        local cx, cy = clamp_panel_position(ox, oy, width, height + 42)
        position = dim2(0, cx, 0, cy)
    end

    local gui = library:create("ScreenGui", {
        Parent = get_hui(),
        Name = "\0",
        Enabled = true,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9988,
    })

    local panel = library:create("Frame", {
        Parent = gui,
        Position = position,
        Size = dim2(0, width, 0, height + 42),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        Visible = visible,
        ZIndex = 70,
        Active = true,
        ClipsDescendants = true,
    })
    library:create("UICorner", { Parent = panel, CornerRadius = dim(0, 10) })
    library:create("UIStroke", {
        Parent = panel, Color = rgb(23, 23, 29), Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local function save_pos()
        pcall(function()
            if not writefile then return end
            pcall(makefolder, library.directory)
            local p = panel.Position
            writefile(pos_file, http_service:JSONEncode({
                x = math.floor(p.X.Offset + 0.5),
                y = math.floor(p.Y.Offset + 0.5),
            }))
        end)
    end

    local header = library:create("Frame", {
        Parent = panel, BackgroundTransparency = 1, Size = dim2(1, 0, 0, 36),
        BorderSizePixel = 0, ZIndex = 72, Active = true,
    })
    local listIcon = library:create("ImageButton", {
        Parent = header, BackgroundTransparency = 1, Position = dim2(0, 10, 0.5, -8),
        Size = dim2(0, 16, 0, 16), ImageColor3 = themes.preset.accent,
        BorderSizePixel = 0, ZIndex = 73, ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(listIcon, "eye")
    library:apply_theme(listIcon, "accent", "ImageColor3")

    local titleLabel = library:create("TextLabel", {
        Parent = header, FontFace = fonts.font, Text = title, TextSize = 15,
        TextColor3 = themes.preset.text, BackgroundTransparency = 1,
        Position = dim2(0, 32, 0, 0), Size = dim2(1, -110, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 72,
    })

    local pinned = true
    local DOCK_GAP = 12
    local function dock_to_main()
        if not panel or not panel.Parent then return end
        if not pinned then return end
        local main = nil
        pcall(function()
            if shared and shared._hostMenuMain and shared._hostMenuMain.Parent then
                main = shared._hostMenuMain
            end
        end)
        if not main then
            pcall(function()
                local sg = library.items
                if sg then
                    for _, ch in ipairs(sg:GetChildren()) do
                        if ch:IsA("Frame") and ch.AbsoluteSize.X > 400 then
                            main = ch
                            break
                        end
                    end
                end
            end)
        end
        if not main then return end
        local ap, asz = main.AbsolutePosition, main.AbsoluteSize
        local pw = (panel.AbsoluteSize.X > 10 and panel.AbsoluteSize.X) or width
        local ph = (panel.AbsoluteSize.Y > 10 and panel.AbsoluteSize.Y) or (height + 42)
        local menuH = asz.Y > 80 and asz.Y or 575
        local menuW = asz.X > 80 and asz.X or 720
        local x = ap.X + menuW + DOCK_GAP
        local y = ap.Y + menuH * 0.5 - ph * 0.5
        local vs = camera.ViewportSize
        if x + pw > vs.X - 6 then
            x = max(6, ap.X - pw - DOCK_GAP)
        end
        if y < 6 then y = 6 end
        if y + ph > vs.Y - 6 then
            y = max(6, vs.Y - ph - 6)
        end
        panel.Position = dim2(0, floor(x + 0.5), 0, floor(y + 0.5))

        pcall(function()
            local menuOn = true
            if library.items and library.items.Enabled == false then menuOn = false end
            if shared and shared._hostMenuOpen == false then menuOn = false end
            if main and main.Visible == false then menuOn = false end
            panel.Visible = state.open and menuOn
        end)
    end

    local pinBtn = { ImageColor3 = themes.preset.accent }

    local closeBtn = library:create("ImageButton", {
        Parent = header, BackgroundTransparency = 1, AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -10, 0.5, 0), Size = dim2(0, 14, 0, 14),
        ImageColor3 = themes.preset.dimtext, BorderSizePixel = 0, ZIndex = 73, ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(closeBtn, "x")

    local body = library:create("Frame", {
        Parent = panel, BackgroundTransparency = 1, Position = dim2(0, 8, 0, 36),
        Size = dim2(1, -16, 1, -44), BorderSizePixel = 0, ZIndex = 71, ClipsDescendants = true,
    })

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "Viewport"
    viewport.BackgroundColor3 = rgb(18, 18, 22)
    viewport.BorderSizePixel = 0
    viewport.Size = dim2(1, 0, 1, 0)
    viewport.ZIndex = 71
    viewport.Ambient = Color3.fromRGB(200, 200, 210)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-0.4, -1, -0.3)
    viewport.Parent = body
    library:create("UICorner", { Parent = viewport, CornerRadius = dim(0, 6) })

    local cam = Instance.new("Camera")
    cam.FieldOfView = 70
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local inputLayer = library:create("TextButton", {
        Parent = body, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 80, Active = true,
    })

    local statusLabel = library:create("TextLabel", {
        Parent = body, FontFace = fonts.font, Text = "Loading character...", TextSize = 13,
        TextColor3 = rgb(200, 200, 210), BackgroundTransparency = 1,
        Size = dim2(1, -16, 1, 0), Position = dim2(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true, BorderSizePixel = 0, Visible = true, ZIndex = 90,
    })

    local state = {
        open = visible == true,
        rotation = 0,
        clone = nil,
        focus = Vector3.new(0, 1.5, 0),
        lastCloneAt = 0,
        destroyed = false,
        idleTrack = nil,
        chamAdorns = {},
        skeletonBeams = {},
        nameBillboard = nil,
        distBillboard = nil,
        weaponBillboard = nil,
        boxAdorn = nil,
        hpBg = nil,
        hpFill = nil,
        lastVisKey = "",
        previewHighlight = nil,
        _skelEnabled = false,
        _skelColor = nil,
    }
    local ensureSkeletonBones, hideSkeletonBones, updateSkeletonBones, ensureSkeletonOverlay, hideSkeletonOverlay, updateSkeletonOverlay
    flags[enabledFlag] = state.open

    local function fireCallback(on)
        pcall(function() flags[enabledFlag] = on == true end)
        if type(options.Callback) == "function" or type(options.callback) == "function" then
            pcall(options.Callback or options.callback, on == true)
        end
    end

    local function findRoot(model)
        if not model then return nil end
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or model.PrimaryPart
    end

    local function clearEspObjects()
        for _, a in ipairs(state.chamAdorns) do pcall(function() a:Destroy() end) end
        state.chamAdorns = {}
        for _, b in ipairs(state.skeletonBeams) do
            pcall(function()
                if b.beam then b.beam:Destroy() end
                if b.a0 then b.a0:Destroy() end
                if b.a1 then b.a1:Destroy() end
            end)
        end
        state.skeletonBeams = {}
        for _, key in ipairs({"nameBillboard", "distBillboard", "weaponBillboard", "boxAdorn", "hpBg", "hpFill"}) do
            local obj = state[key]
            if obj then pcall(function() obj:Destroy() end) end
            state[key] = nil
        end
        state.lastVisKey = ""
    end

    local function destroyClone()
        if state.previewHighlight then
            pcall(function() state.previewHighlight:Destroy() end)
            state.previewHighlight = nil
        end
        pcall(hideSkeletonBones)
        clearEspObjects()
        if state.idleTrack then
            pcall(function() state.idleTrack:Stop(0) end)
            state.idleTrack = nil
        end
        if state.clone then
            pcall(function() state.clone:Destroy() end)
            state.clone = nil
        end
        for _, ch in ipairs(viewport:GetChildren()) do
            if ch ~= cam and (ch:IsA("Model") or ch:IsA("BasePart") or ch:IsA("WorldModel") or ch:IsA("Folder")) then
                pcall(function() ch:Destroy() end)
            end
        end
    end

    local IDLE_R15 = "rbxassetid://507766666"
    local IDLE_R6 = "rbxassetid://180435571"

    local function playIdleOnly(clone)
        if not clone then return end
        pcall(function()
            local hum = clone:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = hum
            end
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
            local isR15 = clone:FindFirstChild("UpperTorso") ~= nil
            local anim = Instance.new("Animation")
            anim.AnimationId = isR15 and IDLE_R15 or IDLE_R6
            local track = animator:LoadAnimation(anim)
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Action4
            track:Play(0, 1, 1)
            state.idleTrack = track
        end)
    end

    local function prepareClone(src)
        pcall(function() src.Archivable = true end)
        for _, d in ipairs(src:GetDescendants()) do
            pcall(function() d.Archivable = true end)
        end
        local ok, clone = pcall(function() return src:Clone() end)
        if not ok or not clone then return nil, "Clone() failed" end

        for _, d in ipairs(clone:GetDescendants()) do
            local cn = d.ClassName
            if cn == "BillboardGui" or cn == "SurfaceGui" or cn == "Highlight"
                or cn == "ForceField" or cn == "Sound" or cn == "ParticleEmitter"
                or cn == "Fire" or cn == "Smoke" or cn == "Sparkles"
                or cn == "BoxHandleAdornment" or cn == "LineHandleAdornment"
                or cn == "Beam" then
                pcall(function() d:Destroy() end)
            elseif cn == "Script" or cn == "LocalScript" or cn == "ModuleScript" then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                pcall(function()
                    d.Anchored = true
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                    d.CastShadow = true
                    d.Massless = true
                    d.AssemblyLinearVelocity = Vector3.zero
                    d.AssemblyAngularVelocity = Vector3.zero
                    if d.LocalTransparencyModifier and d.LocalTransparencyModifier ~= 0 then
                        d.LocalTransparencyModifier = 0
                    end
                end)
            elseif d:IsA("Humanoid") then
                pcall(function()
                    d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                    d.NameDisplayDistance = 0
                    d.HealthDisplayDistance = 0
                    d.AutoRotate = false
                    d.WalkSpeed = 0
                    d.JumpPower = 0
                end)
            end
        end

        local root = findRoot(clone)
        if root then pcall(function() clone.PrimaryPart = root end) end
        pcall(function() clone:PivotTo(CFrame.new(0, 0, 0)) end)

        root = findRoot(clone)
        local head = clone:FindFirstChild("Head")
        local focus = Vector3.new(0, 1.5, 0)
        if root and head then
            focus = Vector3.new(0, (root.Position.Y + head.Position.Y) * 0.5, 0)
        elseif root then
            focus = Vector3.new(0, root.Position.Y + 0.5, 0)
        end
        return clone, focus
    end

    local function normFill(v)
        local fill = tonumber(v)
        if fill == nil then fill = 0.55 end
        if fill > 1 then fill = fill / 100 end
        return clamp(fill, 0, 1)
    end

    local previewObjects = {}
    local function ensurePreviewFrames()
        if previewObjects.holder and previewObjects.holder.Parent then return previewObjects end
        local cache = library.cache or library.other
        if not cache then
            cache = library:create("Folder", { Parent = library.other or coregui, Name = "\0" })
        end
        local holder = library:create("Frame", {
            Parent = viewport,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = vec2(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 8),
            Size = dim2(0, 120, 0, 175),
            ZIndex = 80,
        })
        local name = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            FontFace = fonts.font, TextSize = 12, Text = "Player",
            TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            AnchorPoint = vec2(0, 1), Size = dim2(1, 0, 0, 0),
            Position = dim2(0, 0, 0, -4), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        local box_handler = library:create("Frame", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2), ZIndex = 81,
        })
        local box_stroke = library:create("UIStroke", {
            Parent = box_handler, Color = themes.preset.accent, Thickness = 1,
            LineJoinMode = Enum.LineJoinMode.Miter,
        })
        local box_fill = library:create("Frame", {
            Parent = box_handler, BackgroundColor3 = themes.preset.accent,
            BackgroundTransparency = 0.8, BorderSizePixel = 0, Size = dim2(1, 0, 1, 0), ZIndex = 80,
        })
        local corners = library:create("Frame", {
            Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = dim2(1, 0, 1, 0), ZIndex = 82,
        })
        local function mkCorner(anchor, pos, size)
            local outer = library:create("Frame", {
                Parent = corners, AnchorPoint = anchor, Position = pos, Size = size,
                BorderSizePixel = 0, BackgroundColor3 = rgb(0, 0, 0), ZIndex = 82,
            })
            library:create("Frame", {
                Parent = outer, Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2),
                BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent, ZIndex = 83,
            })
        end
        mkCorner(vec2(0, 0), dim2(0, 0, 0, -1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(0, 0), dim2(0, 0, 0, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(1, 0), dim2(1, 0, 0, -1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(1, 0), dim2(1, 0, 0, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(0, 1), dim2(0, 0, 1, 1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(0, 1), dim2(0, 0, 1, 0), dim2(0, 3, 0.25, 0))
        mkCorner(vec2(1, 1), dim2(1, 0, 1, 1), dim2(0.4, 0, 0, 3))
        mkCorner(vec2(1, 1), dim2(1, 0, 1, 0), dim2(0, 3, 0.25, 0))

        local hp_holder = library:create("Frame", {
            Parent = holder, AnchorPoint = vec2(1, 0), Position = dim2(0, -4, 0, 0),
            Size = dim2(0, 4, 1, 0), BorderSizePixel = 0, BackgroundColor3 = rgb(0, 0, 0), ZIndex = 82,
        })
        local hp_fill = library:create("Frame", {
            Parent = hp_holder, Position = dim2(0, 1, 0, 1), Size = dim2(1, -2, 1, -2),
            BorderSizePixel = 0, BackgroundColor3 = rgb(80, 255, 120), ZIndex = 83,
        })
        local dist = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, FontFace = fonts.font, TextSize = 11,
            Text = "0st", TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 1, 4), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        local weapon = library:create("TextLabel", {
            Parent = holder, BackgroundTransparency = 1, FontFace = fonts.font, TextSize = 11,
            Text = "None", TextColor3 = themes.preset.accent, TextStrokeTransparency = 0.3,
            Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 1, 16), AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 81,
        })
        previewObjects = {
            holder = holder, name = name, box_handler = box_handler, box_stroke = box_stroke,
            box_fill = box_fill, corners = corners, hp_holder = hp_holder, hp_fill = hp_fill,
            dist = dist, weapon = weapon, cache = cache,
        }
        return previewObjects
    end

    local function applyAllEsp(clone, vis)
        vis = vis or getVisuals() or {}
        local o = ensurePreviewFrames()
        local col = vis.Color or vis.ChamsColor or themes.preset.accent
        if typeof(col) ~= "Color3" then col = themes.preset.accent end
        if col.R > 0.92 and col.G > 0.92 and col.B > 0.92 then col = themes.preset.accent end

        local any = vis.Names or vis.Boxes or vis.BoxFilled or vis.HealthBar or vis.Distance or vis.Weapon
        o.holder.Visible = any == true

        o.name.Visible = vis.Names == true
        o.name.TextColor3 = col
        o.name.Text = "Player"

        local showBox = vis.Boxes == true or vis.BoxFilled == true
        o.box_handler.Visible = showBox
        o.box_stroke.Color = col
        o.box_stroke.Enabled = vis.Boxes == true
        o.box_fill.Visible = vis.BoxFilled == true
        o.box_fill.BackgroundColor3 = col
        o.corners.Visible = false

        o.hp_holder.Visible = vis.HealthBar == true
        o.hp_fill.BackgroundColor3 = vis.HealthColor or rgb(80, 255, 120)

        o.dist.Visible = vis.Distance == true
        o.dist.TextColor3 = col
        o.dist.Text = "0st"
        o.weapon.Visible = vis.Weapon == true
        o.weapon.TextColor3 = col
        o.weapon.Text = "None"
        o.weapon.Position = dim2(0, 0, 1, (vis.Distance == true) and 16 or 4)

        if clone then
            local fillCol = vis.ChamsColor or col
            if typeof(fillCol) ~= "Color3" then fillCol = col end
            if fillCol.R > 0.92 and fillCol.G > 0.92 and fillCol.B > 0.92 then
                fillCol = themes.preset.accent
            end
            local fill = tonumber(vis.ChamsFill) or 0.55
            if fill > 1 then fill = fill / 100 end
            fill = clamp(fill, 0, 1)

            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart")
                    and part.Name ~= "HumanoidRootPart"
                    and part.Name ~= "SkelBone"
                    and part.Name ~= "ChamsShellPart"
                then
                    pcall(function()
                        part.Color = Color3.fromRGB(163, 162, 165)
                        part.Material = Enum.Material.SmoothPlastic
                        part.Transparency = 0
                    end)
                end
            end

            for _, s in ipairs(state.chamShells or {}) do
                pcall(function() s:Destroy() end)
            end
            state.chamShells = {}
            state.chamShellTargets = {}

            if vis.Chams == true then
                local shellT = clamp(1 - fill, 0.15, 0.72)
                local folder = clone:FindFirstChild("ChamsShellsFolder")
                if folder then pcall(function() folder:Destroy() end) end
                folder = Instance.new("Folder")
                folder.Name = "ChamsShellsFolder"
                folder.Parent = clone
                state.chamShellFolder = folder

                for _, part in ipairs(clone:GetDescendants()) do
                    if part:IsA("BasePart")
                        and part.Name ~= "HumanoidRootPart"
                        and part.Transparency < 0.9
                        and part.Size.Magnitude > 0.08
                        and not string.find(part.Name, "ChamsShellPart", 1, true)
                    then
                        local shell = Instance.new("Part")
                        shell.Name = "ChamsShellPart"
                        shell.Anchored = true
                        shell.CanCollide = false
                        shell.CanQuery = false
                        shell.CanTouch = false
                        shell.CastShadow = false
                        shell.Material = Enum.Material.ForceField
                        shell.Color = fillCol
                        shell.Transparency = shellT
                        shell.Size = part.Size * 1.12
                        shell.CFrame = part.CFrame
                        shell.Parent = folder
                        state.chamShells[#state.chamShells + 1] = shell
                        state.chamShellTargets[#state.chamShellTargets + 1] = part
                    end
                end
            else
                local folder = clone:FindFirstChild("ChamsShellsFolder")
                if folder then pcall(function() folder:Destroy() end) end
            end

            if state.previewHighlight then
                pcall(function() state.previewHighlight:Destroy() end)
                state.previewHighlight = nil
            end
            pcall(function()
                local orphan = clone:FindFirstChild("NoctroPreviewChams")
                if orphan then orphan:Destroy() end
            end)

            hideSkeletonBones()

            state._skelEnabled = vis.Skeleton == true
            state._skelColor = (typeof(col) == "Color3" and col) or themes.preset.accent
            ensureSkeletonOverlay()
            if state._skelEnabled then
                pcall(updateSkeletonOverlay)
            else
                hideSkeletonOverlay()
            end
        else
            state._skelEnabled = false
            hideSkeletonBones()
            hideSkeletonOverlay()
        end
    end

    local SKELETON_PAIRS = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
    }

    ensureSkeletonBones = function() end
    hideSkeletonBones = function()
        if state.skelBones then
            for _, bone in ipairs(state.skelBones) do
                pcall(function() if bone then bone:Destroy() end end)
            end
        end
        state.skelBones = {}
        if state.skelFolder then
            pcall(function() state.skelFolder:Destroy() end)
            state.skelFolder = nil
        end
        pcall(function()
            if state.clone then
                local f = state.clone:FindFirstChild("PreviewSkeleton")
                if f then f:Destroy() end
            end
        end)
    end
    updateSkeletonBones = function()
        if state.chamShells and state.chamShellTargets then
            for i, shell in ipairs(state.chamShells) do
                local target = state.chamShellTargets[i]
                if shell and shell.Parent and target and target.Parent then
                    pcall(function()
                        shell.Size = target.Size * 1.12
                        shell.CFrame = target.CFrame
                    end)
                end
            end
        end
        pcall(updateSkeletonOverlay)
    end

    ensureSkeletonOverlay = function()
        if previewObjects.skelLines and #previewObjects.skelLines > 0 then
            local ok = true
            for _, line in ipairs(previewObjects.skelLines) do
                if not (line and line.Parent) then ok = false break end
            end
            if ok then return previewObjects.skelLines end
        end
        local lines = {}
        for i = 1, 18 do
            local line = library:create("Frame", {
                Parent = viewport,
                BackgroundColor3 = themes.preset.accent,
                BorderSizePixel = 0,
                AnchorPoint = vec2(0.5, 0.5),
                Position = dim2(0.5, 0, 0.5, 0),
                Size = dim2(0, 3, 0, 0),
                Visible = false,
                ZIndex = 100,
            })
            library:create("UICorner", { Parent = line, CornerRadius = dim(1, 0) })
            lines[i] = line
        end
        previewObjects.skelLines = lines
        return lines
    end

    hideSkeletonOverlay = function()
        local lines = previewObjects.skelLines
        if not lines then return end
        for _, line in ipairs(lines) do
            if line then line.Visible = false end
        end
    end

    updateSkeletonOverlay = function()
        if not state._skelEnabled or not state.clone or not state.clone.Parent then
            hideSkeletonOverlay()
            return
        end
        local lines = ensureSkeletonOverlay()
        local clone = state.clone
        local vfCam = viewport.CurrentCamera or cam
        if not vfCam then hideSkeletonOverlay() return end
        local col = state._skelColor or themes.preset.accent
        if typeof(col) ~= "Color3" then col = themes.preset.accent end

        local function findP(n)
            local p = clone:FindFirstChild(n, true)
            return (p and p:IsA("BasePart")) and p or nil
        end

        local function project(world)
            local sp, on = vfCam:WorldToViewportPoint(world)
            return Vector2.new(sp.X, sp.Y), on and sp.Z > 0
        end

        local li = 1
        for _, pair in ipairs(SKELETON_PAIRS) do
            if li > #lines then break end
            local line = lines[li]
            local p0, p1 = findP(pair[1]), findP(pair[2])
            if p0 and p1 and p0 ~= p1 then
                local pa, oa = project(p0.Position)
                local pb, ob = project(p1.Position)
                if oa and ob then
                    local dx, dy = pb.X - pa.X, pb.Y - pa.Y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 1.5 then
                        local midX = (pa.X + pb.X) * 0.5
                        local midY = (pa.Y + pb.Y) * 0.5
                        local angle = math.deg(math.atan2(dy, dx))
                        line.BackgroundColor3 = col
                        line.Visible = true
                        line.Size = dim2(0, len, 0, 3)
                        line.Position = dim2(0, midX, 0, midY)
                        line.Rotation = angle
                        li = li + 1
                    else
                        line.Visible = false
                        li = li + 1
                    end
                else
                    line.Visible = false
                    li = li + 1
                end
            else
                line.Visible = false
                li = li + 1
            end
        end
        for i = li, #lines do
            if lines[i] then lines[i].Visible = false end
        end
    end

    local function rebuildClone(force)
        if state.destroyed or not state.open then return end
        local now = tick()
        if not force and (now - state.lastCloneAt) < 1.0 then return end

        local src = nil
        local tempDefault = nil
        pcall(function()
            local plr = getPlayer()
            if plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                src = plr.Character
            end
        end)
        if not src then
            pcall(function()
                if lp.Character then
                    lp.Character.Archivable = true
                    src = lp.Character
                end
            end)
        end
        if not src and type(makeDefaultCharacter) == "function" then
            pcall(function()
                tempDefault = makeDefaultCharacter()
                src = tempDefault
            end)
        end
        if not src then
            statusLabel.Text = "No character yet"
            statusLabel.Visible = true
            destroyClone()
            return
        end
        if not src:FindFirstChildOfClass("Humanoid") or not findRoot(src) then
            statusLabel.Text = "Waiting for character..."
            statusLabel.Visible = true
            return
        end

        state.lastCloneAt = now
        destroyClone()

        local clone, focusOrErr = prepareClone(src)
        pcall(function() if tempDefault and tempDefault ~= src then tempDefault:Destroy() end end)
        if not clone then
            statusLabel.Text = "Clone failed — " .. tostring(focusOrErr)
            statusLabel.Visible = true
            return
        end

        clone.Name = "EspPreviewChar"
        local world = viewport:FindFirstChildOfClass("WorldModel")
        if not world then
            world = Instance.new("WorldModel")
            world.Name = "EspWorld"
            world.Parent = viewport
        end
        state.worldModel = world
        local parentOk, parentErr = pcall(function() clone.Parent = world end)
        if not parentOk then
            parentOk, parentErr = pcall(function() clone.Parent = viewport end)
        end
        if not parentOk then
            statusLabel.Text = "Parent failed — " .. tostring(parentErr)
            statusLabel.Visible = true
            pcall(function() clone:Destroy() end)
            return
        end

        state.clone = clone
        state.focus = typeof(focusOrErr) == "Vector3" and focusOrErr or Vector3.new(0, 1.5, 0)
        viewport.CurrentCamera = cam

        task.defer(function()
            if state.clone == clone then
                playIdleOnly(clone)
                end
        end)

        statusLabel.Visible = false
        task.defer(function()
            if state.clone == clone then
                applyAllEsp(clone, getVisuals() or {})
            end
        end)
    end

    local function updateCamera()
        if not state.clone or not state.clone.Parent then return end
        pcall(function()
            state.rotation = (state.rotation or 0) + 0.5
            local root = findRoot(state.clone)
            local cf = CFrame.new(Vector3.new(0, 1, -6)) * CFrame.Angles(0, math.rad(state.rotation), 0)
            if state.clone.PrimaryPart then
                pcall(function() state.clone:PivotTo(cf) end)
            elseif root then
                root.CFrame = cf
            end
            cam.CFrame = CFrame.new(Vector3.new(0, 1.5, 4), Vector3.new(0, 1, -6))
            viewport.CurrentCamera = cam
        end)
        pcall(updateSkeletonBones)
    end

    local function setOpen(bool)
        bool = bool == true
        state.open = bool
        panel.Visible = bool
        flags[enabledFlag] = bool
        if bool then
            statusLabel.Text = "Loading character..."
            statusLabel.Visible = true
            state.lastCloneAt = 0
            task.defer(function() rebuildClone(true) end)
        else
            destroyClone()
        end
        fireCallback(bool)
    end

    do
        local dragging, start, start_pos
        local function begin_drag(input)
            if pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = input.Position
                start_pos = panel.Position
            end
        end
        header.InputBegan:Connect(begin_drag)
        titleLabel.InputBegan:Connect(begin_drag)
        local function end_drag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then dragging = false; save_pos() end
            end
        end
        header.InputEnded:Connect(end_drag)
        library:connection(uis.InputEnded, end_drag)
        library:connection(uis.InputChanged, function(input)
            if not dragging or pinned then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local nx = start_pos.X.Offset + (input.Position.X - start.X)
                local ny = start_pos.Y.Offset + (input.Position.Y - start.Y)
                local pw = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or width
                local ph = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or (height + 42)
                nx, ny = clamp_panel_position(nx, ny, pw, ph)
                panel.Position = dim2(0, nx, 0, ny)
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        setOpen(false)
        pcall(function()
            flags[enabledFlag] = false
            flags["esp_preview_flag"] = false
            if type(options.Callback) == "function" then options.Callback(false) end
            if type(options.callback) == "function" then options.callback(false) end
            if config_flags and config_flags[enabledFlag] then pcall(config_flags[enabledFlag], false) end
            if config_flags and config_flags["esp_preview_flag"] then pcall(config_flags["esp_preview_flag"], false) end
            if shared then shared._espPreviewClosed = tick() end
        end)
    end)

    local accum = 0
    library:connection(run.RenderStepped, function(dt)
        if state.destroyed then return end
        if not panel or not panel.Parent then return end
        local menuOn = true
        pcall(function()
            if library.items and library.items.Enabled == false then menuOn = false end
            if shared and shared._hostMenuOpen == false then menuOn = false end
            if shared and shared._hostMenuMain and shared._hostMenuMain.Visible == false then menuOn = false end
        end)
        panel.Visible = state.open and menuOn
        if gui then gui.Enabled = state.open and menuOn end
        if not state.open or not menuOn then return end
        dock_to_main()
        updateCamera()
        accum = accum + (dt or 0.016)
        if accum < 0.2 then return end
        accum = 0
        if not state.clone or not state.clone.Parent then
            rebuildClone(true)
        elseif (tick() - state.lastCloneAt) > 12 then
            rebuildClone(true)
        else
            applyAllEsp(state.clone, getVisuals() or {})
        end
    end)

    library:connection(lp.CharacterAdded, function()
        task.delay(1, function()
            if state.open and not state.destroyed then rebuildClone(true) end
        end)
    end)

    if state.open then
        task.spawn(function()
            for _ = 1, 8 do
                if state.destroyed or not state.open then return end
                rebuildClone(true)
                if state.clone and state.clone.Parent then return end
                task.wait(0.35)
            end
        end)
    end

    local api = {
        Gui = gui,
        Panel = panel,
        Viewport = viewport,
        Camera = cam,
        GetClone = function() return state.clone end,
        GetCamera = function() return cam end,
        GetPanel = function() return panel end,
        GetViewport = function() return viewport end,
        GetRenderContext = function()
            if not state.open or not panel or not panel.Parent then return nil end
            local clone = state.clone
            if not clone or not clone.Parent then return nil end
            return {
                clone = clone,
                camera = cam,
                panel = panel,
                viewport = viewport,
                open = state.open,
            }
        end,
        ResetPosition = function()
            local vp = camera.ViewportSize
            local cx, cy = clamp_panel_position(vp.X - width - 18, math.floor(vp.Y * 0.32), width, height + 42)
            panel.Position = dim2(0, cx, 0, cy)
            save_pos()
        end,
        SetVisible = function(bool) setOpen(bool == true) end,
        SetEnabled = function(bool) setOpen(bool == true) end,
        IsEnabled = function() return state.open end,
        IsVisible = function() return state.open end,
        Refresh = function()
            state.lastCloneAt = 0
            state.lastVisKey = ""
            rebuildClone(true)
        end,
        DockToMain = function() dock_to_main() end,
        SetPinned = function(bool)
            pinned = bool == true
            pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
        end,
        SetTitle = function(t) titleLabel.Text = tostring(t) end,
        Destroy = function()
            state.destroyed = true
            state.open = false
            destroyClone()
            pcall(function() gui:Destroy() end)
            library.EspPreviewInstance = nil
        end,
    }

    if type(config_flags) == "table" then
        config_flags[enabledFlag] = function(v)
            if type(v) == "boolean" then
                setOpen(v)
            elseif type(v) == "table" and v.active ~= nil then
                setOpen(v.active == true)
            end
        end
    end

    library.EspPreviewInstance = api
    return api
end

-- ============================================================
-- PlayerCard — lock-target style panel (same look as KeybindList)
-- ============================================================
function library:PlayerCard(params)
    params = params or {}
    local width = tonumber(params.Width) or 220
    local height = tonumber(params.Height) or 118
    local position = params.Position or dim2(0.5, -width / 2, 0, 58)
    local pos_file = library.directory .. "/playercard_pos.json"
    local uidKey = params.Uid and tostring(params.Uid) or "default"

    -- per-uid positions stored as { [uid] = {x,y}, default = {x,y} }
    local function load_pos()
        local fallback = position
        local ok, result = pcall(function()
            if not (isfile and isfile(pos_file) and readfile) then return nil end
            local data = http_service:JSONDecode(readfile(pos_file))
            if type(data) ~= "table" then return nil end
            local entry = data[uidKey] or data.default
            if type(entry) == "table" and entry.x ~= nil and entry.y ~= nil then
                return dim2(0, tonumber(entry.x) or 0, 0, tonumber(entry.y) or 0)
            end
            if data.x ~= nil and data.y ~= nil then
                return dim2(0, tonumber(data.x) or 0, 0, tonumber(data.y) or 0)
            end
            return nil
        end)
        if ok and result then return result end
        return fallback
    end

    local function save_pos(panel)
        pcall(function()
            if not writefile then return end
            pcall(makefolder, library.directory)
            local all = {}
            if isfile and isfile(pos_file) and readfile then
                local ok, data = pcall(function() return http_service:JSONDecode(readfile(pos_file)) end)
                if ok and type(data) == "table" then all = data end
            end
            local p = panel.Position
            local entry = {
                x = math.floor(p.X.Offset + camera.ViewportSize.X * p.X.Scale + 0.5),
                y = math.floor(p.Y.Offset + camera.ViewportSize.Y * p.Y.Scale + 0.5),
            }
            all[uidKey] = entry
            all.default = entry
            writefile(pos_file, http_service:JSONEncode(all))
        end)
    end

    position = load_pos()

    local gui = library:create("ScreenGui", {
        Parent = get_hui(),
        Name = "\0",
        Enabled = true,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9991,
    })

    local panel = library:create("Frame", {
        Parent = gui,
        Position = position,
        Size = dim2(0, width, 0, height),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        Visible = params.Visible ~= false,
        ZIndex = 70,
        Active = true,
    })
    library:create("UICorner", { Parent = panel, CornerRadius = dim(0, 10) })
    library:create("UIStroke", {
        Parent = panel,
        Color = rgb(30, 30, 36),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    -- avatar
    local avHolder = library:create("Frame", {
        Parent = panel,
        Position = dim2(0, 12, 0, 12),
        Size = dim2(0, 48, 0, 48),
        BackgroundColor3 = themes.preset.light,
        BorderSizePixel = 0,
        ZIndex = 71,
    })
    library:create("UICorner", { Parent = avHolder, CornerRadius = dim(1, 0) })

    local avatar = library:create("ImageLabel", {
        Parent = avHolder,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 72,
    })
    library:create("UICorner", { Parent = avatar, CornerRadius = dim(1, 0) })

    local nameLabel = library:create("TextLabel", {
        Parent = panel,
        FontFace = fonts.font,
        Text = params.DisplayName or "Player",
        TextSize = 14,
        TextColor3 = themes.preset.text,
        BackgroundTransparency = 1,
        Position = dim2(0, 56, 0, 10),
        Size = dim2(1, -88, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        ZIndex = 72,
    })

    local userLabel = library:create("TextLabel", {
        Parent = panel,
        FontFace = fonts.font,
        Text = "@" .. tostring(params.Username or "user"),
        TextSize = 12,
        TextColor3 = themes.preset.dimtext,
        BackgroundTransparency = 1,
        Position = dim2(0, 56, 0, 26),
        Size = dim2(1, -88, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        ZIndex = 72,
    })

    local ageLabel = library:create("TextLabel", {
        Parent = panel,
        FontFace = fonts.font,
        Text = params.AgeText or "Age —",
        TextSize = 11,
        TextColor3 = themes.preset.dimtext,
        BackgroundTransparency = 1,
        Position = dim2(0, 56, 0, 40),
        Size = dim2(1, -88, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 72,
    })

    -- lucide pin (same as KeybindList)
    local pinBtn = library:create("ImageButton", {
        Parent = panel,
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -10, 0, 10),
        Size = dim2(0, 16, 0, 16),
        ImageColor3 = themes.preset.dimtext,
        BorderSizePixel = 0,
        ZIndex = 74,
        ScaleType = Enum.ScaleType.Fit,
    })
    ApplyIcon(pinBtn, "pin")

    local pinned = params.Pinned == true
    pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext

    local hpBg = library:create("Frame", {
        Parent = panel,
        Position = dim2(0, 12, 0, 56),
        Size = dim2(1, -24, 0, 3),
        BackgroundColor3 = themes.preset.element,
        BorderSizePixel = 0,
        ZIndex = 71,
    })
    library:create("UICorner", { Parent = hpBg, CornerRadius = dim(0, 2) })

    local hpFill = library:create("Frame", {
        Parent = hpBg,
        Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = rgb(80, 200, 120),
        BorderSizePixel = 0,
        ZIndex = 72,
    })
    library:create("UICorner", { Parent = hpFill, CornerRadius = dim(0, 2) })

    local hpLabel = library:create("TextLabel", {
        Parent = panel,
        FontFace = fonts.font,
        Text = "HP —",
        TextSize = 11,
        TextColor3 = themes.preset.dimtext,
        BackgroundTransparency = 1,
        Position = dim2(0, 12, 0, 60),
        Size = dim2(1, -24, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 72,
    })

    local function makeBtn(text, x)
        local b = library:create("TextButton", {
            Parent = panel,
            FontFace = fonts.font,
            Text = text,
            TextSize = 12,
            TextColor3 = themes.preset.text,
            AutoButtonColor = false,
            BackgroundColor3 = themes.preset.element,
            Position = dim2(0, x, 0, 84),
            Size = dim2(0, 62, 0, 24),
            BorderSizePixel = 0,
            ZIndex = 73,
        })
        library:create("UICorner", { Parent = b, CornerRadius = dim(0, 6) })
        b.MouseEnter:Connect(function()
            if b:GetAttribute("Active") ~= true then
                b.BackgroundColor3 = themes.preset.light
            end
        end)
        b.MouseLeave:Connect(function()
            if b:GetAttribute("Active") == true then
                b.BackgroundColor3 = themes.preset.accent
                b.TextColor3 = rgb(18, 18, 22)
            else
                b.BackgroundColor3 = themes.preset.element
                b.TextColor3 = themes.preset.text
            end
        end)
        return b
    end

    local btnRage = makeBtn("Rage", 12)
    local btnTP = makeBtn("Teleport", 80)
    local btnSpec = makeBtn("Spectate", 148)

    local function setBtnActive(btn, active, onText, offText)
        btn:SetAttribute("Active", active == true)
        if active then
            btn.BackgroundColor3 = themes.preset.accent
            btn.TextColor3 = rgb(18, 18, 22)
            if onText then btn.Text = onText end
        else
            btn.BackgroundColor3 = themes.preset.element
            btn.TextColor3 = themes.preset.text
            if offText then btn.Text = offText end
        end
    end

    -- drag (header area); ignore pin button
    do
        local dragging, start, start_pos
        panel.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local relY = input.Position.Y - panel.AbsolutePosition.Y
            if relY > 52 then return end
            local pAbs, pSz = pinBtn.AbsolutePosition, pinBtn.AbsoluteSize
            local px, py = input.Position.X, input.Position.Y
            if px >= pAbs.X and px <= pAbs.X + pSz.X and py >= pAbs.Y and py <= pAbs.Y + pSz.Y then
                return
            end
            dragging = true
            start = input.Position
            start_pos = panel.Position
        end)
        panel.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    save_pos(panel)
                end
            end
        end)
        library:connection(uis.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local nx = start_pos.X.Offset + (input.Position.X - start.X)
            local ny = start_pos.Y.Offset + (input.Position.Y - start.Y)
            panel.Position = dim2(0, nx, 0, ny)
        end)
    end

    local api = {
        Gui = gui,
        Panel = panel,
        PinButton = pinBtn,
        RageButton = btnRage,
        TeleportButton = btnTP,
        SpectateButton = btnSpec,
        IsPinned = function() return pinned end,
        SetPinned = function(bool)
            pinned = bool == true
            pinBtn.ImageColor3 = pinned and themes.preset.accent or themes.preset.dimtext
        end,
        SetVisible = function(bool)
            panel.Visible = bool == true
        end,
        SetIdentity = function(opts)
            opts = opts or {}
            if opts.DisplayName then nameLabel.Text = tostring(opts.DisplayName) end
            if opts.Username then userLabel.Text = "@" .. tostring(opts.Username) end
            if opts.AgeText then ageLabel.Text = tostring(opts.AgeText) end
            if opts.AvatarImage then avatar.Image = opts.AvatarImage end
        end,
        SetHealth = function(hp, maxHp)
            hp = tonumber(hp) or 0
            maxHp = math.max(tonumber(maxHp) or 100, 1)
            local pct = clamp(hp / maxHp, 0, 1)
            hpFill.Size = dim2(pct, 0, 1, 0)
            if pct > 0.5 then
                hpFill.BackgroundColor3 = rgb(80, 200, 120)
            elseif pct > 0.25 then
                hpFill.BackgroundColor3 = rgb(230, 180, 60)
            else
                hpFill.BackgroundColor3 = rgb(220, 70, 90)
            end
            hpLabel.Text = string.format("HP  %d / %d", math.floor(hp + 0.5), math.floor(maxHp + 0.5))
        end,
        SetRageActive = function(active)
            setBtnActive(btnRage, active, "Stop Rage", "Rage")
        end,
        SetSpectateActive = function(active)
            setBtnActive(btnSpec, active, "Unspectate", "Spectate")
        end,
        SetAvatarUserId = function(userId)
            task.spawn(function()
                local ok, content = pcall(function()
                    return players:GetUserThumbnailAsync(
                        userId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size150x150
                    )
                end)
                if ok and content then avatar.Image = content end
            end)
        end,
        SavePosition = function()
            save_pos(panel)
        end,
        Destroy = function()
            pcall(function() gui:Destroy() end)
        end,
    }

    pinBtn.MouseButton1Click:Connect(function()
        api.SetPinned(not pinned)
        if type(params.OnPin) == "function" then
            pcall(params.OnPin, pinned)
        end
    end)

    if type(params.OnRage) == "function" then
        btnRage.MouseButton1Click:Connect(function()
            pcall(params.OnRage)
        end)
    end
    if type(params.OnTeleport) == "function" then
        btnTP.MouseButton1Click:Connect(function()
            pcall(params.OnTeleport)
        end)
    end
    if type(params.OnSpectate) == "function" then
        btnSpec.MouseButton1Click:Connect(function()
            pcall(params.OnSpectate)
        end)
    end

    if params.UserId then
        api.SetAvatarUserId(params.UserId)
    end

    return api
end

function library:BindChatCommands()
    if library._chatCmdsBound then return end
    library._chatCmdsBound = true
    local Players = game:GetService("Players")
    local function handle(msg)
        if type(msg) ~= "string" then return end
        local m = string.lower(msg):gsub("^%s+", ""):gsub("%s+$", "")
        if m == "!rejoin" or m == "!rj" or m == "/rejoin" or m == "/rj" then
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            end)
        end
    end
    pcall(function()
        local lp = Players.LocalPlayer
        if lp then library:connection(lp.Chatted, handle) end
    end)
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs then
            library:connection(tcs.MessageReceived, function(message)
                local text = message and message.Text
                local src = message and message.TextSource
                local plr = Players.LocalPlayer
                if text and src and plr and src.UserId == plr.UserId then handle(text) end
            end)
        end
    end)
end
task.defer(function() pcall(function() library:BindChatCommands() end) end)

function library:Snow(enabled)
    if enabled == false then
        if library._snowConn then pcall(function() library._snowConn:Disconnect() end) library._snowConn = nil end
        if library._snowLayer then pcall(function() library._snowLayer:Destroy() end) library._snowLayer = nil end
        library._snowEnabled = false
        return
    end
    if library._snowEnabled then return end
    local host = library._menuMain
    if not host then return end
    library._snowEnabled = true
    local layer = library:create("Frame", {
        Parent = host, Name = "SnowLayer", Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 25, BorderSizePixel = 0,
    })
    library._snowLayer = layer
    local flakes, rnd = {}, math.random
    for i = 1, 28 do
        local f = library:create("Frame", {
            Parent = layer, Size = dim2(0, rnd(2, 4), 0, rnd(2, 4)),
            Position = dim2(rnd(0, 100) / 100, 0, 0, rnd(-20, 200)),
            BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = rnd(25, 60) / 100,
            BorderSizePixel = 0, ZIndex = 25,
        })
        library:create("UICorner", { Parent = f, CornerRadius = dim(1, 0) })
        flakes[i] = { f = f, speed = rnd(25, 70) / 100, x = rnd(0, 1000) / 1000, y = rnd(-50, 400), drift = rnd(-15, 15) / 100 }
    end
    library._snowConn = run.RenderStepped:Connect(function(dt)
        if not layer.Parent then return end
        local h = math.max(layer.AbsoluteSize.Y, 1)
        for _, s in ipairs(flakes) do
            s.y = s.y + s.speed * 55 * dt
            s.x = s.x + s.drift * 0.02 * dt
            if s.y > h + 8 then s.y = rnd(-30, -5); s.x = rnd(0, 1000) / 1000 end
            if s.x < 0 then s.x = 1 elseif s.x > 1 then s.x = 0 end
            s.f.Position = dim2(s.x, 0, 0, s.y)
        end
    end)
end

function library:Login(options)
    options = options or {}
    local fields = options.fields or options.Fields or { "key" }
    local cfg = {
        title = options.title or options.Title or "Noctro Login",
        fields = fields,
        remember = options.remember ~= false and options.Remember ~= false,
        onSubmit = options.onSubmit or options.OnSubmit or options.callback or options.Callback,
        onSuccess = options.onSuccess or options.OnSuccess or function() end,
        saveFile = library.directory .. "/login_" .. tostring(options.saveKey or options.SaveKey or "default") .. ".json",
        window = options.Window or options.window,
    }
    local wantUser, wantPass, wantKey = false, false, false
    for _, f in ipairs(fields) do
        f = string.lower(tostring(f))
        if f == "username" or f == "user" then wantUser = true end
        if f == "password" or f == "pass" then wantPass = true end
        if f == "key" or f == "license" then wantKey = true end
    end
    if not wantUser and not wantPass and not wantKey then wantKey = true end

    local saved = {}
    pcall(function()
        if isfile and isfile(cfg.saveFile) and readfile then
            saved = http_service:JSONDecode(readfile(cfg.saveFile)) or {}
        end
    end)

    local host
    if cfg.window and cfg.window.items and cfg.window.items["main"] then
        host = cfg.window.items["main"]
    end

    local card
    if host then
        for _, child in ipairs(host:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "LoginLayer" and child.Name ~= "SigningLayer" then
                child:SetAttribute("_preLoginVisible", child.Visible)
                child.Visible = false
            end
        end
        card = library:create("Frame", {
            Parent = host, Name = "LoginLayer", Size = dim2(1, 0, 1, 0),
            BackgroundColor3 = themes.preset.background, BorderSizePixel = 0,
            ClipsDescendants = true, ZIndex = 80,
        })
        library:create("UICorner", { Parent = card, CornerRadius = dim(0, 14) })
        library:create("UIStroke", {
            Parent = card, Color = rgb(23, 23, 29), Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    else
        return
    end

    local form = library:create("Frame", {
        Parent = card, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, ZIndex = 82,
    })

    library:create("TextLabel", {
        Parent = form, Size = dim2(1, 0, 0, 26), FontFace = fonts.font,
        Text = cfg.title, TextSize = 20, TextColor3 = themes.preset.text,
        BackgroundTransparency = 1, ZIndex = 83,
    })
    local underline = library:create("Frame", {
        Parent = form, AnchorPoint = vec2(0.5, 0), Position = dim2(0.5, 0, 0, 28),
        Size = dim2(0, 56, 0, 2), BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.accent, ZIndex = 83,
    })
    library:apply_theme(underline, "accent", "BackgroundColor3")

    local function makeInput(placeholder, iconName, y)
        local wrap = library:create("Frame", {
            Parent = form, Position = dim2(0, 0, 0, y), Size = dim2(1, 0, 0, 42),
            BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 83,
        })
        library:create("UICorner", { Parent = wrap, CornerRadius = dim(0, 8) })
        local icon = library:create("ImageLabel", {
            Parent = wrap, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 12, 0.5, 0),
            Size = dim2(0, 14, 0, 14), BackgroundTransparency = 1,
            ImageColor3 = themes.preset.dimicon, ZIndex = 84,
        })
        ApplyIcon(icon, iconName)
        local box = library:create("TextBox", {
            Parent = wrap, Position = dim2(0, 36, 0, 0), Size = dim2(1, -48, 1, 0),
            BackgroundTransparency = 1, PlaceholderText = placeholder, Text = "",
            PlaceholderColor3 = themes.preset.dimtext, TextColor3 = themes.preset.text,
            FontFace = fonts.font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, ZIndex = 84,
        })
        return box
    end

    local fieldY = 48
    local usernameBox, passwordBox, keyBox
    if wantUser then usernameBox = makeInput("Username", "user", fieldY); usernameBox.Text = tostring(saved.username or ""); fieldY = fieldY + 50 end
    if wantPass then passwordBox = makeInput("Password", "lock", fieldY); fieldY = fieldY + 50 end
    if wantKey then keyBox = makeInput("License", "key-round", fieldY); keyBox.Text = tostring(saved.key or ""); fieldY = fieldY + 50 end

    local signY = fieldY + 6
    local signInBtn = library:create("TextButton", {
        Parent = form, Position = dim2(0, 0, 0, signY), Size = dim2(1, 0, 0, 42),
        BackgroundColor3 = themes.preset.accent, AutoButtonColor = false, Text = "Sign in",
        FontFace = fonts.font, TextSize = 14, TextColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0, ZIndex = 83,
    })
    library:create("UICorner", { Parent = signInBtn, CornerRadius = dim(0, 8) })
    library:apply_theme(signInBtn, "accent", "BackgroundColor3")

    local errorLabel = library:create("TextLabel", {
        Parent = form, Position = dim2(0, 0, 0, signY + 48), Size = dim2(1, 0, 0, 14),
        Text = "", TextColor3 = rgb(240, 90, 90), FontFace = fonts.font, TextSize = 12,
        BackgroundTransparency = 1, ZIndex = 83,
    })

    local rememberOn = cfg.remember and saved.remember == true
    if cfg.remember then
        local rememberRow = library:create("Frame", {
            Parent = form, Position = dim2(0, 0, 0, signY + 52), Size = dim2(1, 0, 0, 18),
            BackgroundTransparency = 1, ZIndex = 83,
        })
        local rememberCheck = library:create("TextButton", {
            Parent = rememberRow, Size = dim2(0, 16, 0, 16), Text = "", AutoButtonColor = false,
            BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 83,
        })
        library:create("UICorner", { Parent = rememberCheck, CornerRadius = dim(0, 4) })
        library:create("UIStroke", { Parent = rememberCheck, Color = themes.preset.line, Thickness = 1 })
        local checkMark = library:create("ImageLabel", {
            Parent = rememberCheck, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 11, 0, 11), BackgroundTransparency = 1,
            ImageColor3 = rgb(255, 255, 255), ImageTransparency = 1, ZIndex = 84,
        })
        ApplyIcon(checkMark, "check")
        library:create("TextLabel", {
            Parent = rememberRow, Position = dim2(0, 22, 0, 0), Size = dim2(1, -22, 1, 0),
            Text = "Remember me", TextColor3 = themes.preset.dimtext, FontFace = fonts.font,
            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, ZIndex = 83,
        })
        local function setRemember(v)
            rememberOn = v
            library:tween(rememberCheck, { BackgroundColor3 = v and themes.preset.accent or themes.preset.element })
            library:tween(checkMark, { ImageTransparency = v and 0 or 1 }, Enum.EasingStyle.Quad, 0.12)
        end
        rememberCheck.MouseButton1Click:Connect(function() setRemember(not rememberOn) end)
        setRemember(rememberOn)
        errorLabel.Position = dim2(0, 0, 0, signY + 76)
    end

    local signing = library:create("Frame", {
        Parent = card, Name = "SigningLayer", Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0,
        Visible = false, ZIndex = 90,
    })
    library:create("UICorner", { Parent = signing, CornerRadius = dim(0, 14) })
    local spin = library:create("ImageLabel", {
        Parent = signing, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.48, 0),
        Size = dim2(0, 44, 0, 44), BackgroundTransparency = 1,
        ImageColor3 = themes.preset.accent, ZIndex = 91, Image = "rbxassetid://4965945816",
    })
    library:apply_theme(spin, "accent", "ImageColor3")
    library:create("TextLabel", {
        Parent = signing, AnchorPoint = vec2(0.5, 0), Position = dim2(0.5, 0, 0.48, 32),
        Size = dim2(0, 140, 0, 18), Text = "Signing in...", TextColor3 = themes.preset.dimtext,
        FontFace = fonts.font, TextSize = 13, BackgroundTransparency = 1, ZIndex = 91,
    })
    library:connection(run.RenderStepped, function(dt)
        if signing.Visible then spin.Rotation = (spin.Rotation + dt * 240) % 360 end
    end)

    local submitting = false
    local function restoreWindow()
        if host and host.Parent then
            for _, child in ipairs(host:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "LoginLayer" and child.Name ~= "SigningLayer" then
                    local prev = child:GetAttribute("_preLoginVisible")
                    if prev == nil then prev = true end
                    child.Visible = prev and true or false
                end
            end
        end
        pcall(function() if card and card.Parent then card:Destroy() end end)
    end

    local function submit()
        if submitting then return end
        local creds = {
            username = usernameBox and usernameBox.Text or nil,
            password = passwordBox and passwordBox.Text or nil,
            key = keyBox and keyBox.Text or nil,
        }
        if wantKey and (not creds.key or creds.key == "") then errorLabel.Text = "Enter a license key." return end
        errorLabel.Text = ""
        submitting = true
        form.Visible = false
        signing.Visible = true
        local function finish(success, message)
            if not card or not card.Parent then return end
            submitting = false
            if success then
                pcall(function()
                    if cfg.remember and rememberOn then
                        pcall(makefolder, library.directory)
                        writefile(cfg.saveFile, http_service:JSONEncode({ key = creds.key, username = creds.username, remember = true }))
                    end
                end)
                restoreWindow()
                pcall(cfg.onSuccess, creds)
            else
                signing.Visible = false
                form.Visible = true
                errorLabel.Text = message or "Invalid credentials."
            end
        end
        if type(cfg.onSubmit) == "function" then
            task.spawn(function()
                local ok, err = pcall(function() cfg.onSubmit(creds, finish) end)
                if not ok then finish(false, tostring(err)) end
            end)
        else
            finish(true)
        end
    end

    signInBtn.MouseButton1Click:Connect(submit)
    if keyBox then keyBox.FocusLost:Connect(function(e) if e then submit() end end) end
    return { close = restoreWindow, submit = submit }
end

-- PascalCase aliases (Noctro-style API, same Noctro face)
function library:Dropdown(o) return self:dropdown(o) end
function library:Toggle(o) return self:toggle(o) end
function library:Slider(o) return self:slider(o) end
function library:RangeSlider(o) return self:rangeslider(o) end
function library:Button(o) return self:button(o) end
function library:Textbox(o) return self:textbox(o) end
function library:Keybind(o) return self:keybind(o) end
function library:Colorpicker(o) return self:colorpicker(o) end
function library:Label(o) return self:label(o) end
function library:Section(o) return self:section(o) end
function library:Tab(o) return self:tab(o) end
function library:Window(o) return self:window(o) end
function library:SubTab(o) return self:sub_tab(o) end
function library:Notify(o)
    o = o or {}
    if type(self.notification) == "function" then
        return self:notification(o)
    end
    return nil
end

getgenv().Noctro = library
return library
