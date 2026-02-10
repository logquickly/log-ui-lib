--[[
    ╔══════════════════════════════════════════╗
    ║         Log UI Library                  ║
    ║         Vape V4 Style                   ║
    ║         Version 1.0.1                   ║
    ╚══════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════

local Utility = {}

function Utility.Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    if properties then
        for prop, value in pairs(properties) do
            if prop ~= "Parent" then
                pcall(function()
                    instance[prop] = value
                end)
            end
        end
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

function Utility.Tween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility.MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos

    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Utility.Tween(frame, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }, 0.06, Enum.EasingStyle.Linear)
        end
    end)
end

function Utility.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utility.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Utility.FormatNumber(value, increment)
    if increment >= 1 then
        return tostring(math.floor(value + 0.5))
    end
    local decimals = 0
    local inc = increment
    while inc < 1 do
        decimals = decimals + 1
        inc = inc * 10
    end
    return string.format("%." .. decimals .. "f", value)
end

function Utility.SnapValue(value, min, max, increment)
    local snapped = math.floor(value / increment + 0.5) * increment
    snapped = math.clamp(snapped, min, max)
    return tonumber(Utility.FormatNumber(snapped, increment))
end

function Utility.Color3ToHex(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Utility.HexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- ═══════════════════════════════════════════
-- SIGNAL
-- ═══════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_connections = {}}, Signal)
end

function Signal:Connect(fn)
    table.insert(self._connections, fn)
    return {
        Disconnect = function()
            for i, v in ipairs(self._connections) do
                if v == fn then
                    table.remove(self._connections, i)
                    break
                end
            end
        end
    }
end

function Signal:Fire(...)
    for _, fn in ipairs(self._connections) do
        task.spawn(fn, ...)
    end
end

function Signal:Destroy()
    self._connections = {}
end

-- ═══════════════════════════════════════════
-- THEMES
-- ═══════════════════════════════════════════

local Themes = {
    ["Vape Dark"] = {
        Name = "Vape Dark",
        Background = Color3.fromRGB(20, 20, 35),
        SidebarBackground = Color3.fromRGB(15, 15, 28),
        TitleBar = Color3.fromRGB(25, 25, 42),
        Accent = Color3.fromRGB(233, 69, 96),
        AccentDark = Color3.fromRGB(180, 50, 75),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(150, 150, 170),
        TextDimmed = Color3.fromRGB(100, 100, 120),
        ElementBackground = Color3.fromRGB(30, 30, 52),
        ElementBackgroundHover = Color3.fromRGB(38, 38, 62),
        ElementBorder = Color3.fromRGB(50, 50, 75),
        ToggleBackground = Color3.fromRGB(45, 45, 70),
        ToggleEnabled = Color3.fromRGB(233, 69, 96),
        ToggleDisabled = Color3.fromRGB(60, 60, 85),
        ToggleCircle = Color3.fromRGB(255, 255, 255),
        SliderBackground = Color3.fromRGB(40, 40, 65),
        SliderFill = Color3.fromRGB(233, 69, 96),
        DropdownBackground = Color3.fromRGB(25, 25, 44),
        DropdownOptionHover = Color3.fromRGB(40, 40, 65),
        InputBackground = Color3.fromRGB(25, 25, 44),
        InputBorder = Color3.fromRGB(60, 60, 90),
        ScrollbarColor = Color3.fromRGB(60, 60, 90),
        Shadow = Color3.fromRGB(0, 0, 0),
        NotifySuccess = Color3.fromRGB(46, 204, 113),
        NotifyError = Color3.fromRGB(231, 76, 60),
        NotifyWarning = Color3.fromRGB(241, 196, 15),
        NotifyInfo = Color3.fromRGB(52, 152, 219),
        SectionLine = Color3.fromRGB(50, 50, 80),
        CornerRadius = UDim.new(0, 6),
        FontTitle = Enum.Font.GothamBold,
        FontBody = Enum.Font.Gotham,
        FontMono = Enum.Font.Code,
        TextSizeTitle = 14,
        TextSizeBody = 13,
        TextSizeSmall = 11,
        TweenSpeed = 0.25,
        EasingStyle = Enum.EasingStyle.Quart,
        EasingDirection = Enum.EasingDirection.Out,
        WindowTransparency = 0.02,
        SidebarWidth = 140,
    },
    ["Midnight Purple"] = {
        Name = "Midnight Purple",
        Background = Color3.fromRGB(18, 12, 30),
        SidebarBackground = Color3.fromRGB(14, 8, 25),
        TitleBar = Color3.fromRGB(22, 15, 38),
        Accent = Color3.fromRGB(138, 43, 226),
        AccentDark = Color3.fromRGB(100, 30, 170),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(160, 145, 180),
        TextDimmed = Color3.fromRGB(110, 95, 130),
        ElementBackground = Color3.fromRGB(28, 20, 46),
        ElementBackgroundHover = Color3.fromRGB(36, 26, 58),
        ElementBorder = Color3.fromRGB(55, 40, 80),
        ToggleBackground = Color3.fromRGB(40, 30, 60),
        ToggleEnabled = Color3.fromRGB(138, 43, 226),
        ToggleDisabled = Color3.fromRGB(55, 45, 75),
        ToggleCircle = Color3.fromRGB(255, 255, 255),
        SliderBackground = Color3.fromRGB(35, 25, 55),
        SliderFill = Color3.fromRGB(138, 43, 226),
        DropdownBackground = Color3.fromRGB(22, 15, 38),
        DropdownOptionHover = Color3.fromRGB(38, 28, 60),
        InputBackground = Color3.fromRGB(22, 15, 38),
        InputBorder = Color3.fromRGB(60, 45, 85),
        ScrollbarColor = Color3.fromRGB(60, 45, 85),
        Shadow = Color3.fromRGB(0, 0, 0),
        NotifySuccess = Color3.fromRGB(46, 204, 113),
        NotifyError = Color3.fromRGB(231, 76, 60),
        NotifyWarning = Color3.fromRGB(241, 196, 15),
        NotifyInfo = Color3.fromRGB(138, 43, 226),
        SectionLine = Color3.fromRGB(50, 38, 72),
        CornerRadius = UDim.new(0, 6),
        FontTitle = Enum.Font.GothamBold,
        FontBody = Enum.Font.Gotham,
        FontMono = Enum.Font.Code,
        TextSizeTitle = 14,
        TextSizeBody = 13,
        TextSizeSmall = 11,
        TweenSpeed = 0.25,
        EasingStyle = Enum.EasingStyle.Quart,
        EasingDirection = Enum.EasingDirection.Out,
        WindowTransparency = 0.02,
        SidebarWidth = 140,
    },
    ["Ocean Blue"] = {
        Name = "Ocean Blue",
        Background = Color3.fromRGB(12, 20, 35),
        SidebarBackground = Color3.fromRGB(8, 15, 28),
        TitleBar = Color3.fromRGB(15, 25, 42),
        Accent = Color3.fromRGB(0, 150, 255),
        AccentDark = Color3.fromRGB(0, 110, 200),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(140, 160, 180),
        TextDimmed = Color3.fromRGB(90, 110, 130),
        ElementBackground = Color3.fromRGB(18, 30, 50),
        ElementBackgroundHover = Color3.fromRGB(25, 38, 60),
        ElementBorder = Color3.fromRGB(35, 55, 80),
        ToggleBackground = Color3.fromRGB(25, 40, 60),
        ToggleEnabled = Color3.fromRGB(0, 150, 255),
        ToggleDisabled = Color3.fromRGB(40, 55, 75),
        ToggleCircle = Color3.fromRGB(255, 255, 255),
        SliderBackground = Color3.fromRGB(22, 35, 55),
        SliderFill = Color3.fromRGB(0, 150, 255),
        DropdownBackground = Color3.fromRGB(14, 22, 38),
        DropdownOptionHover = Color3.fromRGB(25, 40, 60),
        InputBackground = Color3.fromRGB(14, 22, 38),
        InputBorder = Color3.fromRGB(40, 60, 90),
        ScrollbarColor = Color3.fromRGB(40, 60, 90),
        Shadow = Color3.fromRGB(0, 0, 0),
        NotifySuccess = Color3.fromRGB(46, 204, 113),
        NotifyError = Color3.fromRGB(231, 76, 60),
        NotifyWarning = Color3.fromRGB(241, 196, 15),
        NotifyInfo = Color3.fromRGB(0, 150, 255),
        SectionLine = Color3.fromRGB(35, 55, 80),
        CornerRadius = UDim.new(0, 6),
        FontTitle = Enum.Font.GothamBold,
        FontBody = Enum.Font.Gotham,
        FontMono = Enum.Font.Code,
        TextSizeTitle = 14,
        TextSizeBody = 13,
        TextSizeSmall = 11,
        TweenSpeed = 0.25,
        EasingStyle = Enum.EasingStyle.Quart,
        EasingDirection = Enum.EasingDirection.Out,
        WindowTransparency = 0.02,
        SidebarWidth = 140,
    },
}

-- ═══════════════════════════════════════════
-- CONFIG MANAGER
-- ═══════════════════════════════════════════

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(folder)
    local self = setmetatable({}, ConfigManager)
    self.Folder = folder or "LogUILib"
    self.Flags = {}
    self._hasFileSystem = false
    pcall(function()
        if writefile and readfile and isfile and makefolder then
            self._hasFileSystem = true
        end
    end)
    if self._hasFileSystem then
        pcall(function()
            if not isfolder(self.Folder) then
                makefolder(self.Folder)
            end
        end)
    end
    return self
end

function ConfigManager:RegisterFlag(id, default)
    if not self.Flags[id] then
        self.Flags[id] = {Value = default, Default = default}
    end
end

function ConfigManager:SetValue(id, value)
    if self.Flags[id] then
        self.Flags[id].Value = value
    end
end

function ConfigManager:GetValue(id)
    if self.Flags[id] then
        return self.Flags[id].Value
    end
    return nil
end

function ConfigManager:Save(name)
    if not self._hasFileSystem then
        return false
    end
    name = name or "default"
    local data = {}
    for id, flag in pairs(self.Flags) do
        local value = flag.Value
        if typeof(value) == "Color3" then
            data[id] = {_type = "Color3", R = value.R, G = value.G, B = value.B}
        elseif typeof(value) == "EnumItem" then
            data[id] = {_type = "EnumItem", Type = tostring(value.EnumType), Name = value.Name}
        else
            data[id] = value
        end
    end
    local success = pcall(function()
        writefile(self.Folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return success
end

function ConfigManager:Load(name)
    if not self._hasFileSystem then
        return false
    end
    name = name or "default"
    local path = self.Folder .. "/" .. name .. ".json"
    local exists = false
    pcall(function()
        exists = isfile(path)
    end)
    if not exists then
        return false
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not success or not data then
        return false
    end
    for id, value in pairs(data) do
        if type(value) == "table" and value._type then
            if value._type == "Color3" then
                value = Color3.new(value.R, value.G, value.B)
            elseif value._type == "EnumItem" then
                pcall(function()
                    value = Enum[value.Type][value.Name]
                end)
            end
        end
        if self.Flags[id] then
            self.Flags[id].Value = value
        end
    end
    return true
end

function ConfigManager:GetConfigs()
    if not self._hasFileSystem then
        return {}
    end
    local configs = {}
    pcall(function()
        if isfolder(self.Folder) then
            for _, file in ipairs(listfiles(self.Folder)) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(configs, name)
                end
            end
        end
    end)
    return configs
end

function ConfigManager:Delete(name)
    if not self._hasFileSystem then
        return false
    end
    local path = self.Folder .. "/" .. name .. ".json"
    local success = false
    pcall(function()
        if isfile(path) then
            delfile(path)
            success = true
        end
    end)
    return success
end

-- ═══════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════

local Library = {}
Library.__index = Library
Library.Version = "1.0.1"
Library.Windows = {}
Library.ToggleKey = Enum.KeyCode.RightShift
Library.Visible = true
Library.CurrentTheme = nil
Library.ScreenGui = nil
Library.ConfigManager = nil
Library.OnThemeChanged = Signal.new()
Library.Flags = {}

function Library:Init()
    if self.ScreenGui then
        return
    end

    local guiParent = nil

    -- Try syn.protect_gui
    pcall(function()
        if syn and syn.protect_gui then
            self.ScreenGui = Instance.new("ScreenGui")
            self.ScreenGui.Name = "LogUILib_" .. tostring(math.random(100000, 999999))
            self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            self.ScreenGui.ResetOnSpawn = false
            self.ScreenGui.DisplayOrder = 999
            syn.protect_gui(self.ScreenGui)
            self.ScreenGui.Parent = CoreGui
            guiParent = CoreGui
        end
    end)

    -- Try gethui
    if not self.ScreenGui then
        pcall(function()
            if gethui then
                self.ScreenGui = Instance.new("ScreenGui")
                self.ScreenGui.Name = "LogUILib_" .. tostring(math.random(100000, 999999))
                self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                self.ScreenGui.ResetOnSpawn = false
                self.ScreenGui.DisplayOrder = 999
                self.ScreenGui.Parent = gethui()
            end
        end)
    end

    -- Try CoreGui direct
    if not self.ScreenGui then
        pcall(function()
            self.ScreenGui = Instance.new("ScreenGui")
            self.ScreenGui.Name = "LogUILib_" .. tostring(math.random(100000, 999999))
            self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            self.ScreenGui.ResetOnSpawn = false
            self.ScreenGui.DisplayOrder = 999
            self.ScreenGui.Parent = CoreGui
        end)
    end

    -- Fallback PlayerGui
    if not self.ScreenGui then
        self.ScreenGui = Instance.new("ScreenGui")
        self.ScreenGui.Name = "LogUILib"
        self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self.ScreenGui.ResetOnSpawn = false
        self.ScreenGui.DisplayOrder = 999
        self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end

    -- Notification holder
    self.NotificationHolder = Utility.Create("Frame", {
        Name = "NotificationHolder",
        Parent = self.ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 9999
    })
    Utility.Create("UIListLayout", {
        Parent = self.NotificationHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    -- Toggle key listener
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == self.ToggleKey then
            self:ToggleVisibility()
        end
    end)
end

function Library:SetTheme(themeName)
    local theme = Themes[themeName]
    if not theme then
        return
    end
    self.CurrentTheme = Utility.DeepCopy(theme)
    self.OnThemeChanged:Fire(self.CurrentTheme)
end

function Library:GetTheme()
    return self.CurrentTheme
end

function Library:GetThemes()
    local names = {}
    for name in pairs(Themes) do
        table.insert(names, name)
    end
    return names
end

function Library:AddTheme(name, themeData)
    Themes[name] = themeData
end

function Library:ToggleVisibility()
    self.Visible = not self.Visible
    for _, window in ipairs(self.Windows) do
        window.Frame.Visible = self.Visible
    end
end

-- ═══════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local nType = options.Type or "Info"
    local duration = options.Duration or 3
    local theme = self.CurrentTheme

    local typeColors = {
        Success = theme.NotifySuccess,
        Error = theme.NotifyError,
        Warning = theme.NotifyWarning,
        Info = theme.NotifyInfo
    }
    local typeIcons = {
        Success = "✓",
        Error = "✗",
        Warning = "⚠",
        Info = "ℹ"
    }

    local accentColor = typeColors[nType] or theme.Accent
    local icon = typeIcons[nType] or "ℹ"

    local notifFrame = Utility.Create("Frame", {
        Name = "Notification",
        Parent = self.NotificationHolder,
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BackgroundTransparency = 0.05,
        ZIndex = 9999,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = notifFrame})
    Utility.Create("UIStroke", {
        Parent = notifFrame,
        Color = accentColor,
        Thickness = 1,
        Transparency = 0.5,
    })

    Utility.Create("Frame", {
        Name = "AccentBar",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 10000,
    })

    Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(0, 20, 0, 20),
        Text = icon,
        TextColor3 = accentColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        ZIndex = 10000,
    })

    Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 8),
        Size = UDim2.new(1, -50, 0, 18),
        Text = title,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontTitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10000,
    })

    if content ~= "" then
        Utility.Create("TextLabel", {
            Name = "Content",
            Parent = notifFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0, 26),
            Size = UDim2.new(1, -50, 0, 16),
            Text = content,
            TextColor3 = theme.TextSecondary,
            TextSize = theme.TextSizeSmall,
            Font = theme.FontBody,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 10000,
        })
    end

    local progressBar = Utility.Create("Frame", {
        Name = "Progress",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 10000,
    })

    local targetHeight = 38
    if content ~= "" then
        targetHeight = 52
    end

    Utility.Tween(notifFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
    Utility.Tween(progressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    local paused = false
    notifFrame.MouseEnter:Connect(function()
        paused = true
    end)
    notifFrame.MouseLeave:Connect(function()
        paused = false
    end)

    task.spawn(function()
        local elapsed = 0
        while elapsed < duration do
            if not paused then
                elapsed = elapsed + task.wait()
            else
                task.wait()
            end
        end
        Utility.Tween(notifFrame, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        if notifFrame and notifFrame.Parent then
            notifFrame:Destroy()
        end
    end)

    return notifFrame
end

-- ═══════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════

local Window = {}
Window.__index = Window

function Library:CreateWindow(options)
    self:Init()

    options = options or {}
    local title = options.Title or "Log UI Library"
    local subtitle = options.Subtitle or "v" .. self.Version
    local size = options.Size or UDim2.new(0, 600, 0, 420)
    local position = options.Position or UDim2.new(0.5, -300, 0.5, -210)
    local themeName = options.Theme or "Vape Dark"
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local saveConfig = options.SaveConfig or false
    local configFolder = options.ConfigFolder or "LogUILib"

    self.ToggleKey = toggleKey
    self:SetTheme(themeName)

    if saveConfig then
        self.ConfigManager = ConfigManager.new(configFolder)
    end

    local theme = self.CurrentTheme
    local window = setmetatable({}, Window)
    window.Library = self
    window.Tabs = {}
    window.ActiveTab = nil
    window._minimized = false
    window._originalSize = size

    -- Main frame
    window.Frame = Utility.Create("Frame", {
        Name = "Window",
        Parent = self.ScreenGui,
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = theme.WindowTransparency,
        Position = position,
        Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0),
        ClipsDescendants = true,
        ZIndex = 1,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = window.Frame})

    -- Shadow
    Utility.Create("ImageLabel", {
        Name = "Shadow",
        Parent = window.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
    })

    -- Title bar
    window.TitleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Parent = window.Frame,
        BackgroundColor3 = theme.TitleBar,
        Size = UDim2.new(1, 0, 0, 36),
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = window.TitleBar})
    Utility.Create("Frame", {
        Name = "BottomCover",
        Parent = window.TitleBar,
        BackgroundColor3 = theme.TitleBar,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 5,
    })

    -- Title text
    Utility.Create("TextLabel", {
        Name = "Title",
        Parent = window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = title,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeTitle,
        Font = theme.FontTitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })

    -- Subtitle
    local titleWidth = #title * 8 + 14
    Utility.Create("TextLabel", {
        Name = "Subtitle",
        Parent = window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, titleWidth, 0, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        Text = subtitle,
        TextColor3 = theme.TextDimmed,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })

    -- Close button
    local closeBtn = Utility.Create("TextButton", {
        Name = "CloseBtn",
        Parent = window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -36, 0, 0),
        Size = UDim2.new(0, 36, 0, 36),
        Text = "×",
        TextColor3 = theme.TextSecondary,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        ZIndex = 7,
    })
    closeBtn.MouseEnter:Connect(function()
        Utility.Tween(closeBtn, {TextColor3 = theme.NotifyError}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Utility.Tween(closeBtn, {TextColor3 = theme.TextSecondary}, 0.15)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        window:Hide()
    end)

    -- Minimize button
    local minBtn = Utility.Create("TextButton", {
        Name = "MinBtn",
        Parent = window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -68, 0, 0),
        Size = UDim2.new(0, 32, 0, 36),
        Text = "—",
        TextColor3 = theme.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 7,
    })
    minBtn.MouseEnter:Connect(function()
        Utility.Tween(minBtn, {TextColor3 = theme.TextPrimary}, 0.15)
    end)
    minBtn.MouseLeave:Connect(function()
        Utility.Tween(minBtn, {TextColor3 = theme.TextSecondary}, 0.15)
    end)
    minBtn.MouseButton1Click:Connect(function()
        window:ToggleMinimize()
    end)

    -- Draggable
    Utility.MakeDraggable(window.Frame, window.TitleBar)

    -- Content frame
    window.ContentFrame = Utility.Create("Frame", {
        Name = "Content",
        Parent = window.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        ZIndex = 2,
        ClipsDescendants = true,
    })

    -- Sidebar
    window.Sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        Parent = window.ContentFrame,
        BackgroundColor3 = theme.SidebarBackground,
        Size = UDim2.new(0, theme.SidebarWidth, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    Utility.Create("Frame", {
        Name = "Separator",
        Parent = window.Sidebar,
        BackgroundColor3 = theme.ElementBorder,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 4,
    })

    -- Tab button container
    window.TabButtonContainer = Utility.Create("ScrollingFrame", {
        Name = "TabButtons",
        Parent = window.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 8),
        Size = UDim2.new(1, 0, 1, -16),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.ScrollbarColor,
        ScrollBarImageTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Utility.Create("UIListLayout", {
        Parent = window.TabButtonContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    Utility.Create("UIPadding", {
        Parent = window.TabButtonContainer,
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 2),
    })

    -- Tab content area
    window.TabContentArea = Utility.Create("Frame", {
        Name = "TabContent",
        Parent = window.ContentFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, theme.SidebarWidth + 1, 0, 0),
        Size = UDim2.new(1, -(theme.SidebarWidth + 1), 1, 0),
        ZIndex = 2,
        ClipsDescendants = true,
    })

    -- Animate open
    Utility.Tween(window.Frame, {Size = size}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    table.insert(self.Windows, window)
    return window
end

function Window:Hide()
    Utility.Tween(self.Frame, {
        Size = UDim2.new(self._originalSize.X.Scale, self._originalSize.X.Offset, 0, 0),
        BackgroundTransparency = 1
    }, 0.3)
    task.delay(0.3, function()
        self.Frame.Visible = false
        self.Frame.BackgroundTransparency = self.Library.CurrentTheme.WindowTransparency
    end)
end

function Window:Show()
    self.Frame.Visible = true
    self.Frame.Size = UDim2.new(self._originalSize.X.Scale, self._originalSize.X.Offset, 0, 0)
    Utility.Tween(self.Frame, {Size = self._originalSize}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Window:ToggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        Utility.Tween(self.Frame, {
            Size = UDim2.new(self._originalSize.X.Scale, self._originalSize.X.Offset, 0, 36)
        }, 0.3)
        self.ContentFrame.Visible = false
    else
        self.ContentFrame.Visible = true
        Utility.Tween(self.Frame, {Size = self._originalSize}, 0.3)
    end
end

function Window:SelectTab(tabNameOrTab)
    local targetTab
    if type(tabNameOrTab) == "string" then
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == tabNameOrTab then
                targetTab = tab
                break
            end
        end
    else
        targetTab = tabNameOrTab
    end

    if not targetTab then
        return
    end
    if self.ActiveTab == targetTab then
        return
    end

    local theme = self.Library.CurrentTheme

    if self.ActiveTab then
        Utility.Tween(self.ActiveTab.Button, {BackgroundColor3 = theme.SidebarBackground, BackgroundTransparency = 1}, 0.2)
        Utility.Tween(self.ActiveTab.ButtonLabel, {TextColor3 = theme.TextSecondary}, 0.2)
        if self.ActiveTab.ButtonIcon then
            Utility.Tween(self.ActiveTab.ButtonIcon, {TextColor3 = theme.TextSecondary}, 0.2)
        end
        self.ActiveTab.ContentPage.Visible = false
    end

    self.ActiveTab = targetTab
    Utility.Tween(targetTab.Button, {BackgroundColor3 = theme.Accent, BackgroundTransparency = 0.85}, 0.2)
    Utility.Tween(targetTab.ButtonLabel, {TextColor3 = theme.TextPrimary}, 0.2)
    if targetTab.ButtonIcon then
        Utility.Tween(targetTab.ButtonIcon, {TextColor3 = theme.Accent}, 0.2)
    end
    targetTab.ContentPage.Visible = true
    targetTab.ContentPage.GroupTransparency = 1
    Utility.Tween(targetTab.ContentPage, {GroupTransparency = 0}, 0.25)
end

-- ═══════════════════════════════════════════
-- TAB
-- ═══════════════════════════════════════════

local Tab = {}
Tab.__index = Tab

function Window:CreateTab(options)
    options = options or {}
    local theme = self.Library.CurrentTheme

    local tab = setmetatable({}, Tab)
    tab.Name = options.Name or "Tab"
    tab.Icon = options.Icon or ""
    tab.Order = options.Order or (#self.Tabs + 1)
    tab.Sections = {}
    tab.Window = self
    tab.Library = self.Library

    -- Tab button
    tab.Button = Utility.Create("TextButton", {
        Name = "Tab_" .. tab.Name,
        Parent = self.TabButtonContainer,
        BackgroundColor3 = theme.SidebarBackground,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = "",
        LayoutOrder = tab.Order,
        ZIndex = 5,
        AutoButtonColor = false,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = tab.Button})

    if tab.Icon ~= "" then
        tab.ButtonIcon = Utility.Create("TextLabel", {
            Name = "Icon",
            Parent = tab.Button,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0, 20, 1, 0),
            Text = tab.Icon,
            TextColor3 = theme.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 6,
        })
    end

    local labelOffset = 10
    if tab.Icon ~= "" then
        labelOffset = 34
    end
    tab.ButtonLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = tab.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, labelOffset, 0, 0),
        Size = UDim2.new(1, -(labelOffset + 10), 1, 0),
        Text = tab.Name,
        TextColor3 = theme.TextSecondary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 6,
    })

    tab.Button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 0.9, BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
        end
    end)
    tab.Button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 1}, 0.15)
        end
    end)
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    -- Content page
    tab.ContentPage = Utility.Create("CanvasGroup", {
        Name = "Page_" .. tab.Name,
        Parent = self.TabContentArea,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 2,
        GroupTransparency = 0,
    })

    tab.ContentScroll = Utility.Create("ScrollingFrame", {
        Name = "Scroll",
        Parent = tab.ContentPage,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.ScrollbarColor,
        ScrollBarImageTransparency = 0.3,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 2,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
    })
    Utility.Create("UIListLayout", {
        Parent = tab.ContentScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    Utility.Create("UIPadding", {
        Parent = tab.ContentScroll,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

-- ═══════════════════════════════════════════
-- SECTION
-- ═══════════════════════════════════════════

local Section = {}
Section.__index = Section

function Tab:CreateSection(name)
    local theme = self.Library.CurrentTheme

    local section = setmetatable({}, Section)
    section.Name = name or "Section"
    section.Tab = self
    section.Library = self.Library
    section.Components = {}
    section.Order = #self.Sections + 1

    section.Frame = Utility.Create("Frame", {
        Name = "Section_" .. section.Name,
        Parent = self.ContentScroll,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = section.Order,
        ZIndex = 3,
    })

    if name and name ~= "" then
        local headerFrame = Utility.Create("Frame", {
            Name = "Header",
            Parent = section.Frame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            ZIndex = 3,
        })
        Utility.Create("TextLabel", {
            Name = "Title",
            Parent = headerFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = string.upper(section.Name),
            TextColor3 = theme.TextDimmed,
            TextSize = theme.TextSizeSmall,
            Font = theme.FontTitle,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        })
        Utility.Create("Frame", {
            Name = "Line",
            Parent = headerFrame,
            BackgroundColor3 = theme.SectionLine,
            BackgroundTransparency = 0.5,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            ZIndex = 4,
        })
    end

    local yOffset = 0
    if name and name ~= "" then
        yOffset = 28
    end

    section.ComponentContainer = Utility.Create("Frame", {
        Name = "Components",
        Parent = section.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, yOffset),
        ZIndex = 3,
    })
    Utility.Create("UIListLayout", {
        Parent = section.ComponentContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    table.insert(self.Sections, section)
    return section
end

-- ═══════════════════════════════════════════
-- LABEL
-- ═══════════════════════════════════════════

function Section:AddLabel(options)
    options = options or {}
    local theme = self.Library.CurrentTheme

    local label = {}
    label.Type = "Label"
    label.Text = options.Text or "Label"

    label.Frame = Utility.Create("Frame", {
        Name = "Label",
        Parent = self.ComponentContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = #self.Components + 1,
        ZIndex = 4,
    })
    label.TextLabel = Utility.Create("TextLabel", {
        Name = "Text",
        Parent = label.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = label.Text,
        TextColor3 = theme.TextSecondary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    function label:Set(text)
        self.Text = text
        self.TextLabel.Text = text
    end

    table.insert(self.Components, label)
    return label
end

-- ═══════════════════════════════════════════
-- PARAGRAPH
-- ═══════════════════════════════════════════

function Section:AddParagraph(options)
    options = options or {}
    local theme = self.Library.CurrentTheme

    local para = {}
    para.Type = "Paragraph"
    para.Title = options.Title or "Paragraph"
    para.Content = options.Content or ""

    para.Frame = Utility.Create("Frame", {
        Name = "Paragraph",
        Parent = self.ComponentContainer,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Components + 1,
        ZIndex = 4,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = para.Frame})
    Utility.Create("UIPadding", {
        Parent = para.Frame,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    })

    para.TitleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = para.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Text = para.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontTitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })
    para.ContentLabel = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = para.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = para.Content,
        TextColor3 = theme.TextSecondary,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 5,
    })

    function para:Set(title, content)
        if title then
            self.Title = title
            self.TitleLabel.Text = title
        end
        if content then
            self.Content = content
            self.ContentLabel.Text = content
        end
    end

    table.insert(self.Components, para)
    return para
end

-- ═══════════════════════════════════════════
-- BUTTON
-- ═══════════════════════════════════════════

function Section:AddButton(options)
    options = options or {}
    local theme = self.Library.CurrentTheme

    local button = {}
    button.Type = "Button"
    button.Name = options.Name or "Button"
    button.Callback = options.Callback or function() end

    button.Frame = Utility.Create("Frame", {
        Name = "Button_" .. button.Name,
        Parent = self.ComponentContainer,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = #self.Components + 1,
        ZIndex = 4,
        ClipsDescendants = true,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = button.Frame})

    button.Button = Utility.Create("TextButton", {
        Name = "Btn",
        Parent = button.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 6,
        AutoButtonColor = false,
    })
    button.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = button.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = button.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    button.Button.MouseEnter:Connect(function()
        Utility.Tween(button.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    button.Button.MouseLeave:Connect(function()
        Utility.Tween(button.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)
    button.Button.MouseButton1Click:Connect(function()
        Utility.Tween(button.Frame, {BackgroundColor3 = theme.Accent}, 0.1)
        task.delay(0.15, function()
            Utility.Tween(button.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.2)
        end)
        pcall(button.Callback)
    end)

    function button:SetCallback(fn)
        self.Callback = fn
    end

    table.insert(self.Components, button)
    return button
end

-- ═══════════════════════════════════════════
-- SLIDER (shared builder)
-- ═══════════════════════════════════════════

function Section._createSlider(parent, order, options, theme, library)
    options = options or {}
    local slider = {}
    slider.Type = "Slider"
    slider.Name = options.Name or "Slider"
    slider.Min = options.Min or 0
    slider.Max = options.Max or 100
    slider.Default = options.Default or slider.Min
    slider.Increment = options.Increment or 1
    slider.Value = slider.Default
    slider.Callback = options.Callback or function() end
    slider.Flag = options.Flag
    slider.Suffix = options.Suffix or ""

    if slider.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(slider.Flag, slider.Value)
        local saved = library.ConfigManager:GetValue(slider.Flag)
        if saved ~= nil then
            slider.Value = saved
        end
    end
    if slider.Flag then
        library.Flags[slider.Flag] = slider
    end

    slider.Frame = Utility.Create("Frame", {
        Name = "Slider_" .. slider.Name,
        Parent = parent,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 46),
        LayoutOrder = order,
        ZIndex = 4,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = slider.Frame})

    slider.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = slider.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 2),
        Size = UDim2.new(0.6, -12, 0, 20),
        Text = slider.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local displayText = Utility.FormatNumber(slider.Value, slider.Increment) .. slider.Suffix
    slider.ValueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = slider.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 2),
        Size = UDim2.new(0.4, -12, 0, 20),
        Text = displayText,
        TextColor3 = theme.Accent,
        TextSize = theme.TextSizeBody,
        Font = theme.FontTitle,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5,
    })

    slider.Track = Utility.Create("Frame", {
        Name = "Track",
        Parent = slider.Frame,
        BackgroundColor3 = theme.SliderBackground,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -24, 0, 12),
        ZIndex = 5,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = slider.Track})

    local range = slider.Max - slider.Min
    local fillPercent = 0
    if range > 0 then
        fillPercent = math.clamp((slider.Value - slider.Min) / range, 0, 1)
    end

    slider.Fill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = slider.Track,
        BackgroundColor3 = theme.SliderFill,
        Size = UDim2.new(fillPercent, 0, 1, 0),
        ZIndex = 6,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = slider.Fill})

    slider.Input = Utility.Create("TextButton", {
        Name = "Input",
        Parent = slider.Track,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 10),
        Position = UDim2.new(0, 0, 0, -5),
        Text = "",
        ZIndex = 8,
        AutoButtonColor = false,
    })

    local dragging = false

    local function updateSlider(input)
        local trackAbsPos = slider.Track.AbsolutePosition.X
        local trackAbsSize = slider.Track.AbsoluteSize.X

        if trackAbsSize <= 0 then
            return
        end

        local pos = math.clamp((input.Position.X - trackAbsPos) / trackAbsSize, 0, 1)
        local rawValue = slider.Min + (slider.Max - slider.Min) * pos
        local value = Utility.SnapValue(rawValue, slider.Min, slider.Max, slider.Increment)

        slider.Value = value
        slider.ValueLabel.Text = Utility.FormatNumber(value, slider.Increment) .. slider.Suffix

        local newRange = slider.Max - slider.Min
        local newPercent = 0
        if newRange > 0 then
            newPercent = math.clamp((value - slider.Min) / newRange, 0, 1)
        end
        Utility.Tween(slider.Fill, {Size = UDim2.new(newPercent, 0, 1, 0)}, 0.06, Enum.EasingStyle.Linear)

        if slider.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(slider.Flag, value)
        end

        pcall(slider.Callback, value)
    end

    slider.Input.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    slider.Input.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input)
            end
        end
    end)

    slider.Input.MouseEnter:Connect(function()
        Utility.Tween(slider.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    slider.Input.MouseLeave:Connect(function()
        if not dragging then
            Utility.Tween(slider.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
        end
    end)

    function slider:Set(value)
        value = Utility.SnapValue(value, self.Min, self.Max, self.Increment)
        self.Value = value
        self.ValueLabel.Text = Utility.FormatNumber(value, self.Increment) .. self.Suffix
        local r = self.Max - self.Min
        local pct = 0
        if r > 0 then
            pct = math.clamp((value - self.Min) / r, 0, 1)
        end
        Utility.Tween(self.Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.15)
        if self.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(self.Flag, value)
        end
        pcall(self.Callback, value)
    end

    function slider:GetValue()
        return self.Value
    end

    return slider
end

function Section:AddSlider(options)
    local theme = self.Library.CurrentTheme
    local slider = Section._createSlider(self.ComponentContainer, #self.Components + 1, options, theme, self.Library)
    table.insert(self.Components, slider)
    return slider
end

-- ═══════════════════════════════════════════
-- DROPDOWN (shared builder)
-- ═══════════════════════════════════════════

function Section._createDropdown(parent, order, options, theme, library)
    options = options or {}
    local dropdown = {}
    dropdown.Type = "Dropdown"
    dropdown.Name = options.Name or "Dropdown"
    dropdown.Options = options.Options or {}
    dropdown.Multi = options.Multi or false
    dropdown.Callback = options.Callback or function() end
    dropdown.Flag = options.Flag
    dropdown._open = false

    if dropdown.Multi then
        dropdown.Value = options.Default or {}
    else
        dropdown.Value = options.Default or (dropdown.Options[1] or "")
    end

    if dropdown.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(dropdown.Flag, dropdown.Value)
        local saved = library.ConfigManager:GetValue(dropdown.Flag)
        if saved ~= nil then
            dropdown.Value = saved
        end
    end
    if dropdown.Flag then
        library.Flags[dropdown.Flag] = dropdown
    end

    local function getDisplayText()
        if dropdown.Multi then
            if type(dropdown.Value) == "table" then
                local selected = {}
                for _, v in ipairs(dropdown.Options) do
                    if dropdown.Value[v] then
                        table.insert(selected, v)
                    end
                end
                if #selected == 0 then
                    return "None"
                end
                return table.concat(selected, ", ")
            end
            return "None"
        else
            return tostring(dropdown.Value)
        end
    end

    dropdown.Frame = Utility.Create("Frame", {
        Name = "Dropdown_" .. dropdown.Name,
        Parent = parent,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = order,
        ZIndex = 4,
        ClipsDescendants = true,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = dropdown.Frame})

    dropdown.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = dropdown.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.45, 0, 0, 34),
        Text = dropdown.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    dropdown.SelectedLabel = Utility.Create("TextLabel", {
        Name = "Selected",
        Parent = dropdown.Frame,
        BackgroundColor3 = theme.DropdownBackground,
        Position = UDim2.new(0.45, 4, 0, 5),
        Size = UDim2.new(0.55, -20, 0, 24),
        Text = getDisplayText(),
        TextColor3 = theme.Accent,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdown.SelectedLabel})

    dropdown.ArrowLabel = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdown.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.new(0, 14, 0, 34),
        Text = "▼",
        TextColor3 = theme.TextDimmed,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        ZIndex = 5,
    })

    dropdown.OptionsFrame = Utility.Create("Frame", {
        Name = "Options",
        Parent = dropdown.Frame,
        BackgroundColor3 = theme.DropdownBackground,
        Position = UDim2.new(0, 6, 0, 38),
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 10,
        ClipsDescendants = true,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdown.OptionsFrame})
    Utility.Create("UIListLayout", {
        Parent = dropdown.OptionsFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    })
    Utility.Create("UIPadding", {
        Parent = dropdown.OptionsFrame,
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    })

    local function buildOptions()
        for _, child in ipairs(dropdown.OptionsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for i, option in ipairs(dropdown.Options) do
            local isSelected = false
            if dropdown.Multi then
                isSelected = (dropdown.Value[option] == true)
            else
                isSelected = (dropdown.Value == option)
            end

            local optBg = theme.DropdownBackground
            local optTrans = 1
            if isSelected then
                optBg = theme.Accent
                optTrans = 0.8
            end

            local optBtn = Utility.Create("TextButton", {
                Name = "Option_" .. option,
                Parent = dropdown.OptionsFrame,
                BackgroundColor3 = optBg,
                BackgroundTransparency = optTrans,
                Size = UDim2.new(1, 0, 0, 26),
                Text = "",
                LayoutOrder = i,
                ZIndex = 11,
                AutoButtonColor = false,
            })

            local optFont = theme.FontBody
            local optColor = theme.TextSecondary
            if isSelected then
                optFont = theme.FontTitle
                optColor = theme.Accent
            end

            Utility.Create("TextLabel", {
                Name = "Label",
                Parent = optBtn,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                Text = option,
                TextColor3 = optColor,
                TextSize = theme.TextSizeSmall,
                Font = optFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12,
            })

            if isSelected then
                Utility.Create("TextLabel", {
                    Name = "Check",
                    Parent = optBtn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -24, 0, 0),
                    Size = UDim2.new(0, 14, 1, 0),
                    Text = "✓",
                    TextColor3 = theme.Accent,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 12,
                })
            end

            optBtn.MouseEnter:Connect(function()
                if not isSelected then
                    Utility.Tween(optBtn, {BackgroundTransparency = 0.85, BackgroundColor3 = theme.DropdownOptionHover}, 0.1)
                end
            end)
            optBtn.MouseLeave:Connect(function()
                if not isSelected then
                    Utility.Tween(optBtn, {BackgroundTransparency = 1}, 0.1)
                end
            end)

            optBtn.MouseButton1Click:Connect(function()
                if dropdown.Multi then
                    if type(dropdown.Value) ~= "table" then
                        dropdown.Value = {}
                    end
                    if dropdown.Value[option] then
                        dropdown.Value[option] = nil
                    else
                        dropdown.Value[option] = true
                    end
                    dropdown.SelectedLabel.Text = getDisplayText()
                    buildOptions()
                    if dropdown.Flag and library.ConfigManager then
                        library.ConfigManager:SetValue(dropdown.Flag, dropdown.Value)
                    end
                    pcall(dropdown.Callback, dropdown.Value)
                else
                    dropdown.Value = option
                    dropdown.SelectedLabel.Text = option
                    if dropdown.Flag and library.ConfigManager then
                        library.ConfigManager:SetValue(dropdown.Flag, dropdown.Value)
                    end
                    pcall(dropdown.Callback, option)
                    dropdown:Close()
                end
            end)
        end
    end

    buildOptions()

    function dropdown:Open()
        self._open = true
        self.OptionsFrame.Visible = true
        local optCount = math.min(#self.Options, 6)
        local targetHeight = 34 + 8 + (optCount * 27) + 8
        Utility.Tween(self.Frame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
        Utility.Tween(self.ArrowLabel, {Rotation = 180}, 0.2)
    end

    function dropdown:Close()
        self._open = false
        Utility.Tween(self.Frame, {Size = UDim2.new(1, 0, 0, 34)}, 0.2)
        Utility.Tween(self.ArrowLabel, {Rotation = 0}, 0.2)
        task.delay(0.2, function()
            self.OptionsFrame.Visible = false
        end)
    end

    function dropdown:Toggle()
        if self._open then
            self:Close()
        else
            self:Open()
        end
    end

    local clickBtn = Utility.Create("TextButton", {
        Name = "ClickArea",
        Parent = dropdown.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = "",
        ZIndex = 8,
        AutoButtonColor = false,
    })
    clickBtn.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    clickBtn.MouseEnter:Connect(function()
        Utility.Tween(dropdown.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    clickBtn.MouseLeave:Connect(function()
        Utility.Tween(dropdown.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function dropdown:Set(value)
        self.Value = value
        self.SelectedLabel.Text = getDisplayText()
        buildOptions()
        if self.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(self.Flag, value)
        end
        pcall(self.Callback, value)
    end

    function dropdown:SetOptions(newOptions, keepValue)
        self.Options = newOptions
        if not keepValue then
            if self.Multi then
                self.Value = {}
            else
                self.Value = newOptions[1] or ""
            end
        end
        self.SelectedLabel.Text = getDisplayText()
        buildOptions()
    end

    function dropdown:GetValue()
        return self.Value
    end

    return dropdown
end

function Section:AddDropdown(options)
    local theme = self.Library.CurrentTheme
    local dropdown = Section._createDropdown(self.ComponentContainer, #self.Components + 1, options, theme, self.Library)
    table.insert(self.Components, dropdown)
    return dropdown
end

-- ═══════════════════════════════════════════
-- TEXTBOX
-- ═══════════════════════════════════════════

function Section:AddTextBox(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local lib = self.Library

    local textbox = {}
    textbox.Type = "TextBox"
    textbox.Name = options.Name or "TextBox"
    textbox.Default = options.Default or ""
    textbox.PlaceholderText = options.PlaceholderText or "Enter text..."
    textbox.Callback = options.Callback or function() end
    textbox.ClearOnFocus = options.ClearOnFocus or false
    textbox.Flag = options.Flag
    textbox.Value = textbox.Default
    textbox.Library = lib

    if textbox.Flag and lib.ConfigManager then
        lib.ConfigManager:RegisterFlag(textbox.Flag, textbox.Value)
        local saved = lib.ConfigManager:GetValue(textbox.Flag)
        if saved ~= nil then
            textbox.Value = saved
        end
    end
    if textbox.Flag then
        lib.Flags[textbox.Flag] = textbox
    end

    textbox.Frame = Utility.Create("Frame", {
        Name = "TextBox_" .. textbox.Name,
        Parent = self.ComponentContainer,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = #self.Components + 1,
        ZIndex = 4,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = textbox.Frame})

    textbox.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = textbox.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Text = textbox.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    textbox.Input = Utility.Create("TextBox", {
        Name = "Input",
        Parent = textbox.Frame,
        BackgroundColor3 = theme.InputBackground,
        Position = UDim2.new(0.4, 4, 0, 5),
        Size = UDim2.new(0.6, -16, 0, 24),
        Text = textbox.Value,
        PlaceholderText = textbox.PlaceholderText,
        PlaceholderColor3 = theme.TextDimmed,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontBody,
        ClearTextOnFocus = textbox.ClearOnFocus,
        ZIndex = 6,
        BorderSizePixel = 0,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = textbox.Input})
    Utility.Create("UIStroke", {
        Parent = textbox.Input,
        Color = theme.InputBorder,
        Thickness = 1,
        Transparency = 0.5,
    })
    Utility.Create("UIPadding", {
        Parent = textbox.Input,
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    })

    textbox.Input.Focused:Connect(function()
        local stroke = textbox.Input:FindFirstChildOfClass("UIStroke")
        if stroke then
            Utility.Tween(stroke, {Color = theme.Accent, Transparency = 0}, 0.15)
        end
    end)

    textbox.Input.FocusLost:Connect(function()
        local stroke = textbox.Input:FindFirstChildOfClass("UIStroke")
        if stroke then
            Utility.Tween(stroke, {Color = theme.InputBorder, Transparency = 0.5}, 0.15)
        end
        textbox.Value = textbox.Input.Text
        if textbox.Flag and lib.ConfigManager then
            lib.ConfigManager:SetValue(textbox.Flag, textbox.Value)
        end
        pcall(textbox.Callback, textbox.Input.Text)
    end)

    textbox.Frame.MouseEnter:Connect(function()
        Utility.Tween(textbox.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    textbox.Frame.MouseLeave:Connect(function()
        Utility.Tween(textbox.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function textbox:Set(text)
        self.Value = text
        self.Input.Text = text
        if self.Flag and self.Library and self.Library.ConfigManager then
            self.Library.ConfigManager:SetValue(self.Flag, text)
        end
    end

    function textbox:GetValue()
        return self.Value
    end

    table.insert(self.Components, textbox)
    return textbox
end

-- ═══════════════════════════════════════════
-- KEYBIND (shared builder)
-- ═══════════════════════════════════════════

function Section._createKeybind(parent, order, options, theme, library)
    options = options or {}
    local keybind = {}
    keybind.Type = "Keybind"
    keybind.Name = options.Name or "Keybind"
    keybind.Value = options.Default or Enum.KeyCode.Unknown
    keybind.Callback = options.Callback or function() end
    keybind.ChangedCallback = options.ChangedCallback or function() end
    keybind.Flag = options.Flag
    keybind._listening = false

    if keybind.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(keybind.Flag, keybind.Value)
    end
    if keybind.Flag then
        library.Flags[keybind.Flag] = keybind
    end

    keybind.Frame = Utility.Create("Frame", {
        Name = "Keybind_" .. keybind.Name,
        Parent = parent,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = order,
        ZIndex = 4,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = keybind.Frame})

    keybind.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = keybind.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = keybind.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local keyDisplayName = "None"
    if keybind.Value ~= Enum.KeyCode.Unknown then
        keyDisplayName = keybind.Value.Name
    end

    keybind.KeyButton = Utility.Create("TextButton", {
        Name = "KeyBtn",
        Parent = keybind.Frame,
        BackgroundColor3 = theme.InputBackground,
        Position = UDim2.new(1, -80, 0, 5),
        Size = UDim2.new(0, 68, 0, 24),
        Text = "[" .. keyDisplayName .. "]",
        TextColor3 = theme.Accent,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontMono,
        ZIndex = 6,
        AutoButtonColor = false,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = keybind.KeyButton})
    Utility.Create("UIStroke", {
        Parent = keybind.KeyButton,
        Color = theme.InputBorder,
        Thickness = 1,
        Transparency = 0.5,
    })

    keybind.KeyButton.MouseButton1Click:Connect(function()
        keybind._listening = true
        keybind.KeyButton.Text = "[...]"
        Utility.Tween(keybind.KeyButton, {BackgroundColor3 = theme.Accent}, 0.15)
        Utility.Tween(keybind.KeyButton, {TextColor3 = theme.TextPrimary}, 0.15)
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if keybind._listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    keybind._listening = false
                    local name = "None"
                    if keybind.Value ~= Enum.KeyCode.Unknown then
                        name = keybind.Value.Name
                    end
                    keybind.KeyButton.Text = "[" .. name .. "]"
                    Utility.Tween(keybind.KeyButton, {BackgroundColor3 = theme.InputBackground}, 0.15)
                    Utility.Tween(keybind.KeyButton, {TextColor3 = theme.Accent}, 0.15)
                    return
                end
                if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
                    keybind.Value = Enum.KeyCode.Unknown
                    keybind._listening = false
                    keybind.KeyButton.Text = "[None]"
                    Utility.Tween(keybind.KeyButton, {BackgroundColor3 = theme.InputBackground}, 0.15)
                    Utility.Tween(keybind.KeyButton, {TextColor3 = theme.Accent}, 0.15)
                    if keybind.Flag and library.ConfigManager then
                        library.ConfigManager:SetValue(keybind.Flag, keybind.Value)
                    end
                    pcall(keybind.ChangedCallback, keybind.Value)
                    return
                end

                keybind.Value = input.KeyCode
                keybind._listening = false
                keybind.KeyButton.Text = "[" .. input.KeyCode.Name .. "]"
                Utility.Tween(keybind.KeyButton, {BackgroundColor3 = theme.InputBackground}, 0.15)
                Utility.Tween(keybind.KeyButton, {TextColor3 = theme.Accent}, 0.15)
                if keybind.Flag and library.ConfigManager then
                    library.ConfigManager:SetValue(keybind.Flag, keybind.Value)
                end
                pcall(keybind.ChangedCallback, keybind.Value)
            end
        else
            if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == keybind.Value and keybind.Value ~= Enum.KeyCode.Unknown then
                    pcall(keybind.Callback, keybind.Value)
                end
            end
        end
    end)

    keybind.Frame.MouseEnter:Connect(function()
        Utility.Tween(keybind.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    keybind.Frame.MouseLeave:Connect(function()
        Utility.Tween(keybind.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function keybind:Set(key)
        self.Value = key
        local name = "None"
        if key ~= Enum.KeyCode.Unknown then
            name = key.Name
        end
        self.KeyButton.Text = "[" .. name .. "]"
        if self.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(self.Flag, key)
        end
    end

    function keybind:GetValue()
        return self.Value
    end

    return keybind
end

function Section:AddKeybind(options)
    local theme = self.Library.CurrentTheme
    local keybind = Section._createKeybind(self.ComponentContainer, #self.Components + 1, options, theme, self.Library)
    table.insert(self.Components, keybind)
    return keybind
end

-- ═══════════════════════════════════════════
-- SUB-TOGGLE (for nesting inside Toggle)
-- ═══════════════════════════════════════════

function Section._createSubToggle(parent, order, options, theme, library)
    options = options or {}
    local toggle = {}
    toggle.Type = "Toggle"
    toggle.Name = options.Name or "Toggle"
    toggle.Value = options.Default or false
    toggle.Callback = options.Callback or function() end
    toggle.Flag = options.Flag

    if toggle.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(toggle.Flag, toggle.Value)
        local saved = library.ConfigManager:GetValue(toggle.Flag)
        if saved ~= nil then
            toggle.Value = saved
        end
    end
    if toggle.Flag then
        library.Flags[toggle.Flag] = toggle
    end

    toggle.Frame = Utility.Create("Frame", {
        Name = "SubToggle_" .. toggle.Name,
        Parent = parent,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = order,
        ZIndex = 4,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = toggle.Frame})

    toggle.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = toggle.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -54, 1, 0),
        Text = toggle.Name,
        TextColor3 = theme.TextSecondary,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local switchBg = theme.ToggleDisabled
    if toggle.Value then
        switchBg = theme.ToggleEnabled
    end

    toggle.SwitchFrame = Utility.Create("Frame", {
        Name = "Switch",
        Parent = toggle.Frame,
        BackgroundColor3 = switchBg,
        Position = UDim2.new(1, -42, 0.5, -7),
        Size = UDim2.new(0, 32, 0, 14),
        ZIndex = 5,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchFrame})

    local circlePos = UDim2.new(0, 2, 0.5, -5)
    if toggle.Value then
        circlePos = UDim2.new(1, -12, 0.5, -5)
    end

    toggle.SwitchCircle = Utility.Create("Frame", {
        Name = "Circle",
        Parent = toggle.SwitchFrame,
        BackgroundColor3 = theme.ToggleCircle,
        Position = circlePos,
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 6,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchCircle})

    local clickBtn = Utility.Create("TextButton", {
        Name = "Click",
        Parent = toggle.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 7,
        AutoButtonColor = false,
    })

    local function setToggle(value)
        toggle.Value = value
        local bg = theme.ToggleDisabled
        local pos = UDim2.new(0, 2, 0.5, -5)
        if value then
            bg = theme.ToggleEnabled
            pos = UDim2.new(1, -12, 0.5, -5)
        end
        Utility.Tween(toggle.SwitchFrame, {BackgroundColor3 = bg}, 0.2)
        Utility.Tween(toggle.SwitchCircle, {Position = pos}, 0.2)
        if toggle.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(toggle.Flag, value)
        end
        pcall(toggle.Callback, value)
    end

    clickBtn.MouseButton1Click:Connect(function()
        setToggle(not toggle.Value)
    end)

    function toggle:Set(value)
        setToggle(value)
    end

    function toggle:GetState()
        return self.Value
    end

    return toggle
end

-- ═══════════════════════════════════════════
-- COLOR PICKER (shared builder)
-- ═══════════════════════════════════════════

function Section._createColorPicker(parent, order, options, theme, library)
    options = options or {}
    local colorPicker = {}
    colorPicker.Type = "ColorPicker"
    colorPicker.Name = options.Name or "Color"
    colorPicker.Value = options.Default or Color3.fromRGB(255, 0, 0)
    colorPicker.Callback = options.Callback or function() end
    colorPicker.Flag = options.Flag
    colorPicker._open = false

    if colorPicker.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(colorPicker.Flag, colorPicker.Value)
        local saved = library.ConfigManager:GetValue(colorPicker.Flag)
        if saved ~= nil then
            colorPicker.Value = saved
        end
    end
    if colorPicker.Flag then
        library.Flags[colorPicker.Flag] = colorPicker
    end

    local h, s, v = colorPicker.Value:ToHSV()

    colorPicker.Frame = Utility.Create("Frame", {
        Name = "ColorPicker_" .. colorPicker.Name,
        Parent = parent,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = order,
        ZIndex = 4,
        ClipsDescendants = true,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = colorPicker.Frame})

    colorPicker.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = colorPicker.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 0, 34),
        Text = colorPicker.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    colorPicker.Preview = Utility.Create("TextButton", {
        Name = "Preview",
        Parent = colorPicker.Frame,
        BackgroundColor3 = colorPicker.Value,
        Position = UDim2.new(1, -42, 0, 7),
        Size = UDim2.new(0, 30, 0, 20),
        Text = "",
        ZIndex = 6,
        AutoButtonColor = false,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = colorPicker.Preview})
    Utility.Create("UIStroke", {
        Parent = colorPicker.Preview,
        Color = theme.InputBorder,
        Thickness = 1,
    })

    colorPicker.Panel = Utility.Create("Frame", {
        Name = "Panel",
        Parent = colorPicker.Frame,
        BackgroundColor3 = theme.DropdownBackground,
        Position = UDim2.new(0, 6, 0, 38),
        Size = UDim2.new(1, -12, 0, 130),
        Visible = false,
        ZIndex = 10,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = colorPicker.Panel})

    colorPicker.SVFrame = Utility.Create("ImageLabel", {
        Name = "SV",
        Parent = colorPicker.Panel,
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -40, 0, 85),
        Image = "rbxassetid://4155801252",
        ZIndex = 11,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = colorPicker.SVFrame})

    colorPicker.SVCursor = Utility.Create("Frame", {
        Name = "Cursor",
        Parent = colorPicker.SVFrame,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(s, -5, 1 - v, -5),
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 13,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = colorPicker.SVCursor})
    Utility.Create("UIStroke", {
        Parent = colorPicker.SVCursor,
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
    })

    colorPicker.HueFrame = Utility.Create("Frame", {
        Name = "Hue",
        Parent = colorPicker.Panel,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(1, -26, 0, 8),
        Size = UDim2.new(0, 18, 0, 85),
        ZIndex = 11,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = colorPicker.HueFrame})
    Utility.Create("UIGradient", {
        Parent = colorPicker.HueFrame,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Rotation = 90,
    })

    colorPicker.HueCursor = Utility.Create("Frame", {
        Name = "HueCursor",
        Parent = colorPicker.HueFrame,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, -2, h, -3),
        Size = UDim2.new(1, 4, 0, 6),
        ZIndex = 13,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = colorPicker.HueCursor})
    Utility.Create("UIStroke", {
        Parent = colorPicker.HueCursor,
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
    })

    colorPicker.HexInput = Utility.Create("TextBox", {
        Name = "Hex",
        Parent = colorPicker.Panel,
        BackgroundColor3 = theme.InputBackground,
        Position = UDim2.new(0, 8, 0, 100),
        Size = UDim2.new(1, -16, 0, 22),
        Text = Utility.Color3ToHex(colorPicker.Value),
        PlaceholderText = "#FF0000",
        PlaceholderColor3 = theme.TextDimmed,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeSmall,
        Font = theme.FontMono,
        ZIndex = 12,
        BorderSizePixel = 0,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = colorPicker.HexInput})
    Utility.Create("UIPadding", {
        Parent = colorPicker.HexInput,
        PaddingLeft = UDim.new(0, 6),
    })

    local function updateColor(newH, newS, newV)
        if newH then h = newH end
        if newS then s = newS end
        if newV then v = newV end
        colorPicker.Value = Color3.fromHSV(h, s, v)
        colorPicker.Preview.BackgroundColor3 = colorPicker.Value
        colorPicker.SVFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        colorPicker.SVCursor.Position = UDim2.new(s, -5, 1 - v, -5)
        colorPicker.HueCursor.Position = UDim2.new(0, -2, h, -3)
        colorPicker.HexInput.Text = Utility.Color3ToHex(colorPicker.Value)
        if colorPicker.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(colorPicker.Flag, colorPicker.Value)
        end
        pcall(colorPicker.Callback, colorPicker.Value)
    end

    local svDragging = false
    local svInput = Utility.Create("TextButton", {
        Name = "SVInput",
        Parent = colorPicker.SVFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 14,
        AutoButtonColor = false,
    })
    svInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
        end
    end)
    svInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)

    local hueDragging = false
    local hueInput = Utility.Create("TextButton", {
        Name = "HueInput",
        Parent = colorPicker.HueFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 14,
        AutoButtonColor = false,
    })
    hueInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
        end
    end)
    hueInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local absPos = colorPicker.SVFrame.AbsolutePosition
                local absSize = colorPicker.SVFrame.AbsoluteSize
                if absSize.X > 0 and absSize.Y > 0 then
                    local newS = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
                    local newV = math.clamp(1 - (input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    updateColor(nil, newS, newV)
                end
            end
            if hueDragging then
                local absPos = colorPicker.HueFrame.AbsolutePosition
                local absSize = colorPicker.HueFrame.AbsoluteSize
                if absSize.Y > 0 then
                    local newH = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    updateColor(newH, nil, nil)
                end
            end
        end
    end)

    colorPicker.HexInput.FocusLost:Connect(function()
        local text = colorPicker.HexInput.Text
        local success, color = pcall(Utility.HexToColor3, text)
        if success and color then
            local nh, ns, nv = color:ToHSV()
            updateColor(nh, ns, nv)
        else
            colorPicker.HexInput.Text = Utility.Color3ToHex(colorPicker.Value)
        end
    end)

    colorPicker.Preview.MouseButton1Click:Connect(function()
        colorPicker._open = not colorPicker._open
        colorPicker.Panel.Visible = colorPicker._open
        local targetHeight = 34
        if colorPicker._open then
            targetHeight = 176
        end
        Utility.Tween(colorPicker.Frame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
    end)

    colorPicker.Frame.MouseEnter:Connect(function()
        Utility.Tween(colorPicker.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    colorPicker.Frame.MouseLeave:Connect(function()
        Utility.Tween(colorPicker.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function colorPicker:Set(color)
        local nh, ns, nv = color:ToHSV()
        updateColor(nh, ns, nv)
    end

    function colorPicker:GetValue()
        return self.Value
    end

    return colorPicker
end

function Section:AddColorPicker(options)
    local theme = self.Library.CurrentTheme
    local colorPicker = Section._createColorPicker(self.ComponentContainer, #self.Components + 1, options, theme, self.Library)
    table.insert(self.Components, colorPicker)
    return colorPicker
end

-- ═══════════════════════════════════════════
-- TOGGLE (main component)
-- ═══════════════════════════════════════════

function Section:AddToggle(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local lib = self.Library

    local toggle = {}
    toggle.Type = "Toggle"
    toggle.Name = options.Name or "Toggle"
    toggle.Value = options.Default or false
    toggle.Callback = options.Callback or function() end
    toggle.Flag = options.Flag
    toggle.SubComponents = {}
    toggle._expanded = false

    if toggle.Flag and lib.ConfigManager then
        lib.ConfigManager:RegisterFlag(toggle.Flag, toggle.Value)
        local saved = lib.ConfigManager:GetValue(toggle.Flag)
        if saved ~= nil then
            toggle.Value = saved
        end
    end
    if toggle.Flag then
        lib.Flags[toggle.Flag] = toggle
    end

    toggle.Frame = Utility.Create("Frame", {
        Name = "Toggle_" .. toggle.Name,
        Parent = self.ComponentContainer,
        BackgroundColor3 = theme.ElementBackground,
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Components + 1,
        ZIndex = 4,
        ClipsDescendants = true,
    })
    Utility.Create("UICorner", {CornerRadius = theme.CornerRadius, Parent = toggle.Frame})

    toggle.MainRow = Utility.Create("Frame", {
        Name = "MainRow",
        Parent = toggle.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        ZIndex = 4,
    })

    toggle.Arrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = toggle.MainRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        Text = "▶",
        TextColor3 = theme.TextDimmed,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        Visible = false,
        ZIndex = 5,
    })

    toggle.Label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = toggle.MainRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Text = toggle.Name,
        TextColor3 = theme.TextPrimary,
        TextSize = theme.TextSizeBody,
        Font = theme.FontBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local switchBg = theme.ToggleDisabled
    if toggle.Value then
        switchBg = theme.ToggleEnabled
    end

    toggle.SwitchFrame = Utility.Create("Frame", {
        Name = "Switch",
        Parent = toggle.MainRow,
        BackgroundColor3 = switchBg,
        Position = UDim2.new(1, -50, 0.5, -9),
        Size = UDim2.new(0, 38, 0, 18),
        ZIndex = 5,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchFrame})

    local circlePos = UDim2.new(0, 2, 0.5, -7)
    if toggle.Value then
        circlePos = UDim2.new(1, -16, 0.5, -7)
    end

    toggle.SwitchCircle = Utility.Create("Frame", {
        Name = "Circle",
        Parent = toggle.SwitchFrame,
        BackgroundColor3 = theme.ToggleCircle,
        Position = circlePos,
        Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 6,
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchCircle})

    toggle.ClickBtn = Utility.Create("TextButton", {
        Name = "Click",
        Parent = toggle.MainRow,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 7,
        AutoButtonColor = false,
    })

    -- Sub-component container
    toggle.SubContainer = Utility.Create("Frame", {
        Name = "SubComponents",
        Parent = toggle.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 4,
        ClipsDescendants = true,
    })

    toggle.SubLine = Utility.Create("Frame", {
        Name = "SubLine",
        Parent = toggle.SubContainer,
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.6,
        Position = UDim2.new(0, 10, 0, 2),
        Size = UDim2.new(0, 2, 1, -4),
        BorderSizePixel = 0,
        ZIndex = 5,
    })

    toggle.SubLayout = Utility.Create("Frame", {
        Name = "SubLayout",
        Parent = toggle.SubContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
    })
    Utility.Create("UIListLayout", {
        Parent = toggle.SubLayout,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })
    Utility.Create("UIPadding", {
        Parent = toggle.SubLayout,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
    })

    local function setToggle(value, skipCallback)
        toggle.Value = value
        local bg = theme.ToggleDisabled
        local pos = UDim2.new(0, 2, 0.5, -7)
        if value then
            bg = theme.ToggleEnabled
            pos = UDim2.new(1, -16, 0.5, -7)
        end
        Utility.Tween(toggle.SwitchFrame, {BackgroundColor3 = bg}, theme.TweenSpeed)
        Utility.Tween(toggle.SwitchCircle, {Position = pos}, theme.TweenSpeed)

        if toggle.Flag and lib.ConfigManager then
            lib.ConfigManager:SetValue(toggle.Flag, value)
        end

        if not skipCallback then
            pcall(toggle.Callback, value)
        end
    end

    toggle.ClickBtn.MouseButton1Click:Connect(function()
        setToggle(not toggle.Value)
    end)

    toggle.ClickBtn.MouseEnter:Connect(function()
        Utility.Tween(toggle.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    toggle.ClickBtn.MouseLeave:Connect(function()
        Utility.Tween(toggle.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function toggle:Set(value)
        setToggle(value)
    end

    function toggle:GetState()
        return self.Value
    end

    function toggle:ToggleExpand()
        self._expanded = not self._expanded
        self.SubContainer.Visible = self._expanded
        local rot = 0
        if self._expanded then
            rot = 90
        end
        Utility.Tween(self.Arrow, {Rotation = rot}, 0.2)
    end

    local function updateArrowVisibility()
        if #toggle.SubComponents > 0 then
            toggle.Arrow.Visible = true
            toggle.Label.Position = UDim2.new(0, 26, 0, 0)
            toggle.Label.Size = UDim2.new(1, -84, 1, 0)
        end
    end

    toggle.ClickBtn.MouseButton2Click:Connect(function()
        if #toggle.SubComponents > 0 then
            toggle:ToggleExpand()
        end
    end)

    function toggle:AddSlider(subOptions)
        subOptions = subOptions or {}
        local s = Section._createSlider(self.SubLayout, #self.SubComponents + 1, subOptions, theme, lib)
        table.insert(self.SubComponents, s)
        updateArrowVisibility()
        return s
    end

    function toggle:AddDropdown(subOptions)
        subOptions = subOptions or {}
        local d = Section._createDropdown(self.SubLayout, #self.SubComponents + 1, subOptions, theme, lib)
        table.insert(self.SubComponents, d)
        updateArrowVisibility()
        return d
    end

    function toggle:AddToggle(subOptions)
        subOptions = subOptions or {}
        local t = Section._createSubToggle(self.SubLayout, #self.SubComponents + 1, subOptions, theme, lib)
        table.insert(self.SubComponents, t)
        updateArrowVisibility()
        return t
    end

    function toggle:AddKeybind(subOptions)
        subOptions = subOptions or {}
        local k = Section._createKeybind(self.SubLayout, #self.SubComponents + 1, subOptions, theme, lib)
        table.insert(self.SubComponents, k)
        updateArrowVisibility()
        return k
    end

    function toggle:AddColorPicker(subOptions)
        subOptions = subOptions or {}
        local c = Section._createColorPicker(self.SubLayout, #self.SubComponents + 1, subOptions, theme, lib)
        table.insert(self.SubComponents, c)
        updateArrowVisibility()
        return c
    end

    -- Keybind for the toggle itself
    if options.Keybind then
        toggle._keybind = options.Keybind
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then
                return
            end
            if input.KeyCode == toggle._keybind then
                setToggle(not toggle.Value)
            end
        end)
    end

    -- Fire initial callback if default is true
    if toggle.Value then
        task.defer(function()
            pcall(toggle.Callback, toggle.Value)
        end)
    end

    table.insert(self.Components, toggle)
    return toggle
end

-- ═══════════════════════════════════════════
-- CONFIG TAB (built-in)
-- ═══════════════════════════════════════════

function Window:CreateConfigTab(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local lib = self.Library

    local configTab = self:CreateTab({
        Name = options.Name or "Settings",
        Icon = options.Icon or "⚙",
        Order = 999,
    })

    -- Theme section
    local themeSection = configTab:CreateSection("Theme")
    themeSection:AddDropdown({
        Name = "Theme",
        Options = lib:GetThemes(),
        Default = theme.Name,
        Callback = function(selected)
            lib:SetTheme(selected)
            lib:Notify({
                Title = "Theme Changed",
                Content = "Switched to " .. selected,
                Type = "Info",
                Duration = 2,
            })
        end
    })

    -- Config section
    if lib.ConfigManager then
        local configSection = configTab:CreateSection("Configuration")

        local configName = ""
        configSection:AddTextBox({
            Name = "Config Name",
            PlaceholderText = "Enter config name...",
            Callback = function(text)
                configName = text
            end
        })

        configSection:AddButton({
            Name = "Save Config",
            Callback = function()
                if configName ~= "" then
                    local success = lib.ConfigManager:Save(configName)
                    local msg = "Saved as '" .. configName .. "'"
                    local t = "Success"
                    if not success then
                        msg = "Could not save config"
                        t = "Error"
                    end
                    lib:Notify({Title = success and "Config Saved" or "Save Failed", Content = msg, Type = t, Duration = 3})
                else
                    lib:Notify({Title = "Error", Content = "Please enter a config name", Type = "Error", Duration = 2})
                end
            end
        })

        local configDropdown
        configDropdown = configSection:AddDropdown({
            Name = "Load Config",
            Options = lib.ConfigManager:GetConfigs(),
            Default = "",
            Callback = function(selected)
                configName = selected
            end
        })

        configSection:AddButton({
            Name = "Load Config",
            Callback = function()
                if configName ~= "" then
                    local success = lib.ConfigManager:Load(configName)
                    if success then
                        for id, component in pairs(lib.Flags) do
                            local saved = lib.ConfigManager:GetValue(id)
                            if saved ~= nil and component.Set then
                                component:Set(saved)
                            end
                        end
                    end
                    local msg = success and ("Loaded '" .. configName .. "'") or "Could not load config"
                    local t = success and "Success" or "Error"
                    lib:Notify({Title = success and "Config Loaded" or "Load Failed", Content = msg, Type = t, Duration = 3})
                end
            end
        })

        configSection:AddButton({
            Name = "Refresh Config List",
            Callback = function()
                configDropdown:SetOptions(lib.ConfigManager:GetConfigs())
            end
        })

        configSection:AddButton({
            Name = "Delete Config",
            Callback = function()
                if configName ~= "" then
                    local success = lib.ConfigManager:Delete(configName)
                    configDropdown:SetOptions(lib.ConfigManager:GetConfigs())
                    local msg = success and ("Deleted '" .. configName .. "'") or "Could not delete config"
                    local t = success and "Success" or "Error"
                    lib:Notify({Title = success and "Config Deleted" or "Delete Failed", Content = msg, Type = t, Duration = 3})
                end
            end
        })
    end

    -- Info section
    local infoSection = configTab:CreateSection("Information")

    infoSection:AddParagraph({
        Title = "UI Library",
        Content = "Log UI Library v" .. Library.Version .. "\nToggle Key: " .. lib.ToggleKey.Name
    })

    infoSection:AddLabel({
        Text = "Player: " .. Player.Name
    })

    infoSection:AddButton({
        Name = "Destroy UI",
        Callback = function()
            lib:Destroy()
        end
    })

    return configTab
end

-- ═══════════════════════════════════════════
-- DESTROY
-- ═══════════════════════════════════════════

function Library:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end
    self.Windows = {}
    self.Flags = {}
    self.OnThemeChanged:Destroy()
end

-- ═══════════════════════════════════════════
-- RETURN
-- ═══════════════════════════════════════════

return Library
