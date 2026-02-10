--[[
    Log UI Library
    Vape V4 Style
    Version 1.0.2
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

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
    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

function Utility.MakeDraggable(frame, handle)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
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

local Themes = {}

Themes["Vape Dark"] = {
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
}

Themes["Midnight Purple"] = {
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
}

Themes["Ocean Blue"] = {
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
}

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

local Library = {}
Library.__index = Library
Library.Version = "1.0.2"
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

    pcall(function()
        if syn and syn.protect_gui then
            self.ScreenGui = Instance.new("ScreenGui")
            self.ScreenGui.Name = "LogUILib_" .. tostring(math.random(100000, 999999))
            self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            self.ScreenGui.ResetOnSpawn = false
            self.ScreenGui.DisplayOrder = 999
            syn.protect_gui(self.ScreenGui)
            self.ScreenGui.Parent = CoreGui
        end
    end)

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

    if not self.ScreenGui then
        self.ScreenGui = Instance.new("ScreenGui")
        self.ScreenGui.Name = "LogUILib"
        self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self.ScreenGui.ResetOnSpawn = false
        self.ScreenGui.DisplayOrder = 999
        self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end

    self.NotificationHolder = Utility.Create("Frame", {
        Name = "Notifications",
        Parent = self.ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 9999
    })

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notifLayout.Parent = self.NotificationHolder

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then
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

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local nType = options.Type or "Info"
    local duration = options.Duration or 3
    local theme = self.CurrentTheme

    local accentColor = theme.NotifyInfo
    if nType == "Success" then
        accentColor = theme.NotifySuccess
    elseif nType == "Error" then
        accentColor = theme.NotifyError
    elseif nType == "Warning" then
        accentColor = theme.NotifyWarning
    end

    local icon = "ℹ"
    if nType == "Success" then
        icon = "✓"
    elseif nType == "Error" then
        icon = "✗"
    elseif nType == "Warning" then
        icon = "⚠"
    end

    local notifFrame = Utility.Create("Frame", {
        Name = "Notification",
        Parent = self.NotificationHolder,
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BackgroundTransparency = 0.05,
        ZIndex = 9999,
    })

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = theme.CornerRadius
    notifCorner.Parent = notifFrame

    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = accentColor
    notifStroke.Thickness = 1
    notifStroke.Transparency = 0.5
    notifStroke.Parent = notifFrame

    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.BackgroundColor3 = accentColor
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 10000
    accentBar.Parent = notifFrame

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.BackgroundTransparency = 1
    iconLabel.Position = UDim2.new(0, 12, 0, 10)
    iconLabel.Size = UDim2.new(0, 20, 0, 20)
    iconLabel.Text = icon
    iconLabel.TextColor3 = accentColor
    iconLabel.TextSize = 16
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.ZIndex = 10000
    iconLabel.Parent = notifFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 38, 0, 8)
    titleLabel.Size = UDim2.new(1, -50, 0, 18)
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.TextPrimary
    titleLabel.TextSize = theme.TextSizeBody
    titleLabel.Font = theme.FontTitle
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 10000
    titleLabel.Parent = notifFrame

    local targetHeight = 38
    if content ~= "" then
        targetHeight = 52
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Name = "Content"
        contentLabel.BackgroundTransparency = 1
        contentLabel.Position = UDim2.new(0, 38, 0, 26)
        contentLabel.Size = UDim2.new(1, -50, 0, 16)
        contentLabel.Text = content
        contentLabel.TextColor3 = theme.TextSecondary
        contentLabel.TextSize = theme.TextSizeSmall
        contentLabel.Font = theme.FontBody
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextTruncate = Enum.TextTruncate.AtEnd
        contentLabel.ZIndex = 10000
        contentLabel.Parent = notifFrame
    end

    local progressBar = Instance.new("Frame")
    progressBar.Name = "Progress"
    progressBar.BackgroundColor3 = accentColor
    progressBar.BackgroundTransparency = 0.5
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 10000
    progressBar.Parent = notifFrame

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

    window.Frame = Instance.new("Frame")
    window.Frame.Name = "Window"
    window.Frame.BackgroundColor3 = theme.Background
    window.Frame.BackgroundTransparency = theme.WindowTransparency
    window.Frame.Position = position
    window.Frame.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0)
    window.Frame.ClipsDescendants = true
    window.Frame.ZIndex = 1
    window.Frame.Parent = self.ScreenGui

    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, 8)
    windowCorner.Parent = window.Frame

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 0
    shadow.Parent = window.Frame

    window.TitleBar = Instance.new("Frame")
    window.TitleBar.Name = "TitleBar"
    window.TitleBar.BackgroundColor3 = theme.TitleBar
    window.TitleBar.Size = UDim2.new(1, 0, 0, 36)
    window.TitleBar.BorderSizePixel = 0
    window.TitleBar.ZIndex = 5
    window.TitleBar.Parent = window.Frame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 8)
    tbCorner.Parent = window.TitleBar

    local tbCover = Instance.new("Frame")
    tbCover.Name = "BottomCover"
    tbCover.BackgroundColor3 = theme.TitleBar
    tbCover.Position = UDim2.new(0, 0, 1, -8)
    tbCover.Size = UDim2.new(1, 0, 0, 8)
    tbCover.BorderSizePixel = 0
    tbCover.ZIndex = 5
    tbCover.Parent = window.TitleBar

    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.BackgroundTransparency = 1
    titleText.Position = UDim2.new(0, 14, 0, 0)
    titleText.Size = UDim2.new(0.5, 0, 1, 0)
    titleText.Text = title
    titleText.TextColor3 = theme.TextPrimary
    titleText.TextSize = theme.TextSizeTitle
    titleText.Font = theme.FontTitle
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 6
    titleText.Parent = window.TitleBar

    local subtitleText = Instance.new("TextLabel")
    subtitleText.Name = "Subtitle"
    subtitleText.BackgroundTransparency = 1
    subtitleText.Position = UDim2.new(0, #title * 8 + 14, 0, 0)
    subtitleText.Size = UDim2.new(0.3, 0, 1, 0)
    subtitleText.Text = subtitle
    subtitleText.TextColor3 = theme.TextDimmed
    subtitleText.TextSize = theme.TextSizeSmall
    subtitleText.Font = theme.FontBody
    subtitleText.TextXAlignment = Enum.TextXAlignment.Left
    subtitleText.ZIndex = 6
    subtitleText.Parent = window.TitleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -36, 0, 0)
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = theme.TextSecondary
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 7
    closeBtn.Parent = window.TitleBar

    closeBtn.MouseEnter:Connect(function()
        Utility.Tween(closeBtn, {TextColor3 = theme.NotifyError}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Utility.Tween(closeBtn, {TextColor3 = theme.TextSecondary}, 0.15)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        window:Hide()
    end)

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinBtn"
    minBtn.BackgroundTransparency = 1
    minBtn.Position = UDim2.new(1, -68, 0, 0)
    minBtn.Size = UDim2.new(0, 32, 0, 36)
    minBtn.Text = "—"
    minBtn.TextColor3 = theme.TextSecondary
    minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold
    minBtn.ZIndex = 7
    minBtn.Parent = window.TitleBar

    minBtn.MouseEnter:Connect(function()
        Utility.Tween(minBtn, {TextColor3 = theme.TextPrimary}, 0.15)
    end)
    minBtn.MouseLeave:Connect(function()
        Utility.Tween(minBtn, {TextColor3 = theme.TextSecondary}, 0.15)
    end)
    minBtn.MouseButton1Click:Connect(function()
        window:ToggleMinimize()
    end)

    Utility.MakeDraggable(window.Frame, window.TitleBar)

    window.ContentFrame = Instance.new("Frame")
    window.ContentFrame.Name = "Content"
    window.ContentFrame.BackgroundTransparency = 1
    window.ContentFrame.Position = UDim2.new(0, 0, 0, 36)
    window.ContentFrame.Size = UDim2.new(1, 0, 1, -36)
    window.ContentFrame.ZIndex = 2
    window.ContentFrame.ClipsDescendants = true
    window.ContentFrame.Parent = window.Frame

    window.Sidebar = Instance.new("Frame")
    window.Sidebar.Name = "Sidebar"
    window.Sidebar.BackgroundColor3 = theme.SidebarBackground
    window.Sidebar.Size = UDim2.new(0, theme.SidebarWidth, 1, 0)
    window.Sidebar.BorderSizePixel = 0
    window.Sidebar.ZIndex = 3
    window.Sidebar.Parent = window.ContentFrame

    local sidebarSep = Instance.new("Frame")
    sidebarSep.Name = "Separator"
    sidebarSep.BackgroundColor3 = theme.ElementBorder
    sidebarSep.BackgroundTransparency = 0.5
    sidebarSep.Position = UDim2.new(1, 0, 0, 0)
    sidebarSep.Size = UDim2.new(0, 1, 1, 0)
    sidebarSep.BorderSizePixel = 0
    sidebarSep.ZIndex = 4
    sidebarSep.Parent = window.Sidebar

    window.TabButtonContainer = Instance.new("ScrollingFrame")
    window.TabButtonContainer.Name = "TabButtons"
    window.TabButtonContainer.BackgroundTransparency = 1
    window.TabButtonContainer.Position = UDim2.new(0, 0, 0, 8)
    window.TabButtonContainer.Size = UDim2.new(1, 0, 1, -16)
    window.TabButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    window.TabButtonContainer.ScrollBarThickness = 2
    window.TabButtonContainer.ScrollBarImageColor3 = theme.ScrollbarColor
    window.TabButtonContainer.ScrollBarImageTransparency = 0.5
    window.TabButtonContainer.BorderSizePixel = 0
    window.TabButtonContainer.ZIndex = 4
    window.TabButtonContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    window.TabButtonContainer.Parent = window.Sidebar

    local tabBtnLayout = Instance.new("UIListLayout")
    tabBtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabBtnLayout.Padding = UDim.new(0, 2)
    tabBtnLayout.Parent = window.TabButtonContainer

    local tabBtnPadding = Instance.new("UIPadding")
    tabBtnPadding.PaddingLeft = UDim.new(0, 6)
    tabBtnPadding.PaddingRight = UDim.new(0, 6)
    tabBtnPadding.PaddingTop = UDim.new(0, 2)
    tabBtnPadding.Parent = window.TabButtonContainer

    window.TabContentArea = Instance.new("Frame")
    window.TabContentArea.Name = "TabContent"
    window.TabContentArea.BackgroundTransparency = 1
    window.TabContentArea.Position = UDim2.new(0, theme.SidebarWidth + 1, 0, 0)
    window.TabContentArea.Size = UDim2.new(1, -(theme.SidebarWidth + 1), 1, 0)
    window.TabContentArea.ZIndex = 2
    window.TabContentArea.ClipsDescendants = true
    window.TabContentArea.Parent = window.ContentFrame

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
    local targetTab = nil
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

    tab.Button = Instance.new("TextButton")
    tab.Button.Name = "Tab_" .. tab.Name
    tab.Button.BackgroundColor3 = theme.SidebarBackground
    tab.Button.BackgroundTransparency = 1
    tab.Button.Size = UDim2.new(1, 0, 0, 34)
    tab.Button.Text = ""
    tab.Button.LayoutOrder = tab.Order
    tab.Button.ZIndex = 5
    tab.Button.AutoButtonColor = false
    tab.Button.Parent = self.TabButtonContainer

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = tab.Button

    tab.ButtonIcon = nil
    if tab.Icon ~= "" then
        tab.ButtonIcon = Instance.new("TextLabel")
        tab.ButtonIcon.Name = "Icon"
        tab.ButtonIcon.BackgroundTransparency = 1
        tab.ButtonIcon.Position = UDim2.new(0, 10, 0, 0)
        tab.ButtonIcon.Size = UDim2.new(0, 20, 1, 0)
        tab.ButtonIcon.Text = tab.Icon
        tab.ButtonIcon.TextColor3 = theme.TextSecondary
        tab.ButtonIcon.TextSize = 14
        tab.ButtonIcon.Font = Enum.Font.GothamBold
        tab.ButtonIcon.ZIndex = 6
        tab.ButtonIcon.Parent = tab.Button
    end

    local labelX = 10
    if tab.Icon ~= "" then
        labelX = 34
    end

    tab.ButtonLabel = Instance.new("TextLabel")
    tab.ButtonLabel.Name = "Label"
    tab.ButtonLabel.BackgroundTransparency = 1
    tab.ButtonLabel.Position = UDim2.new(0, labelX, 0, 0)
    tab.ButtonLabel.Size = UDim2.new(1, -(labelX + 10), 1, 0)
    tab.ButtonLabel.Text = tab.Name
    tab.ButtonLabel.TextColor3 = theme.TextSecondary
    tab.ButtonLabel.TextSize = theme.TextSizeBody
    tab.ButtonLabel.Font = theme.FontBody
    tab.ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
    tab.ButtonLabel.TextTruncate = Enum.TextTruncate.AtEnd
    tab.ButtonLabel.ZIndex = 6
    tab.ButtonLabel.Parent = tab.Button

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

    tab.ContentPage = Instance.new("CanvasGroup")
    tab.ContentPage.Name = "Page_" .. tab.Name
    tab.ContentPage.BackgroundTransparency = 1
    tab.ContentPage.Size = UDim2.new(1, 0, 1, 0)
    tab.ContentPage.Visible = false
    tab.ContentPage.ZIndex = 2
    tab.ContentPage.GroupTransparency = 0
    tab.ContentPage.Parent = self.TabContentArea

    tab.ContentScroll = Instance.new("ScrollingFrame")
    tab.ContentScroll.Name = "Scroll"
    tab.ContentScroll.BackgroundTransparency = 1
    tab.ContentScroll.Size = UDim2.new(1, 0, 1, 0)
    tab.ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.ContentScroll.ScrollBarThickness = 3
    tab.ContentScroll.ScrollBarImageColor3 = theme.ScrollbarColor
    tab.ContentScroll.ScrollBarImageTransparency = 0.3
    tab.ContentScroll.BorderSizePixel = 0
    tab.ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.ContentScroll.ZIndex = 2
    tab.ContentScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    tab.ContentScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    tab.ContentScroll.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    tab.ContentScroll.Parent = tab.ContentPage

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 6)
    scrollLayout.Parent = tab.ContentScroll

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingLeft = UDim.new(0, 12)
    scrollPadding.PaddingRight = UDim.new(0, 12)
    scrollPadding.PaddingTop = UDim.new(0, 10)
    scrollPadding.PaddingBottom = UDim.new(0, 10)
    scrollPadding.Parent = tab.ContentScroll

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

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

    section.Frame = Instance.new("Frame")
    section.Frame.Name = "Section_" .. section.Name
    section.Frame.BackgroundTransparency = 1
    section.Frame.Size = UDim2.new(1, 0, 0, 0)
    section.Frame.AutomaticSize = Enum.AutomaticSize.Y
    section.Frame.LayoutOrder = section.Order
    section.Frame.ZIndex = 3
    section.Frame.Parent = self.ContentScroll

    local yOffset = 0
    if name and name ~= "" then
        local headerFrame = Instance.new("Frame")
        headerFrame.Name = "Header"
        headerFrame.BackgroundTransparency = 1
        headerFrame.Size = UDim2.new(1, 0, 0, 24)
        headerFrame.ZIndex = 3
        headerFrame.Parent = section.Frame

        local headerTitle = Instance.new("TextLabel")
        headerTitle.Name = "Title"
        headerTitle.BackgroundTransparency = 1
        headerTitle.Size = UDim2.new(0, 0, 1, 0)
        headerTitle.AutomaticSize = Enum.AutomaticSize.X
        headerTitle.Text = string.upper(section.Name)
        headerTitle.TextColor3 = theme.TextDimmed
        headerTitle.TextSize = theme.TextSizeSmall
        headerTitle.Font = theme.FontTitle
        headerTitle.TextXAlignment = Enum.TextXAlignment.Left
        headerTitle.ZIndex = 4
        headerTitle.Parent = headerFrame

        local headerLine = Instance.new("Frame")
        headerLine.Name = "Line"
        headerLine.BackgroundColor3 = theme.SectionLine
        headerLine.BackgroundTransparency = 0.5
        headerLine.Position = UDim2.new(0, 0, 1, -1)
        headerLine.Size = UDim2.new(1, 0, 0, 1)
        headerLine.BorderSizePixel = 0
        headerLine.ZIndex = 4
        headerLine.Parent = headerFrame

        yOffset = 28
    end

    section.ComponentContainer = Instance.new("Frame")
    section.ComponentContainer.Name = "Components"
    section.ComponentContainer.BackgroundTransparency = 1
    section.ComponentContainer.Size = UDim2.new(1, 0, 0, 0)
    section.ComponentContainer.AutomaticSize = Enum.AutomaticSize.Y
    section.ComponentContainer.Position = UDim2.new(0, 0, 0, yOffset)
    section.ComponentContainer.ZIndex = 3
    section.ComponentContainer.Parent = section.Frame

    local compLayout = Instance.new("UIListLayout")
    compLayout.SortOrder = Enum.SortOrder.LayoutOrder
    compLayout.Padding = UDim.new(0, 4)
    compLayout.Parent = section.ComponentContainer

    table.insert(self.Sections, section)
    return section
end

function Section:AddLabel(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local label = {}
    label.Type = "Label"
    label.Text = options.Text or "Label"

    label.Frame = Instance.new("Frame")
    label.Frame.Name = "Label"
    label.Frame.BackgroundTransparency = 1
    label.Frame.Size = UDim2.new(1, 0, 0, 22)
    label.Frame.LayoutOrder = #self.Components + 1
    label.Frame.ZIndex = 4
    label.Frame.Parent = self.ComponentContainer

    label.TextLabel = Instance.new("TextLabel")
    label.TextLabel.Name = "Text"
    label.TextLabel.BackgroundTransparency = 1
    label.TextLabel.Size = UDim2.new(1, 0, 1, 0)
    label.TextLabel.Text = label.Text
    label.TextLabel.TextColor3 = theme.TextSecondary
    label.TextLabel.TextSize = theme.TextSizeBody
    label.TextLabel.Font = theme.FontBody
    label.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    label.TextLabel.ZIndex = 5
    label.TextLabel.Parent = label.Frame

    function label:Set(text)
        self.Text = text
        self.TextLabel.Text = text
    end

    table.insert(self.Components, label)
    return label
end

function Section:AddParagraph(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local para = {}
    para.Type = "Paragraph"
    para.Title = options.Title or "Paragraph"
    para.Content = options.Content or ""

    para.Frame = Instance.new("Frame")
    para.Frame.Name = "Paragraph"
    para.Frame.BackgroundColor3 = theme.ElementBackground
    para.Frame.Size = UDim2.new(1, 0, 0, 0)
    para.Frame.AutomaticSize = Enum.AutomaticSize.Y
    para.Frame.LayoutOrder = #self.Components + 1
    para.Frame.ZIndex = 4
    para.Frame.Parent = self.ComponentContainer

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = theme.CornerRadius
    pCorner.Parent = para.Frame

    local pPad = Instance.new("UIPadding")
    pPad.PaddingLeft = UDim.new(0, 10)
    pPad.PaddingRight = UDim.new(0, 10)
    pPad.PaddingTop = UDim.new(0, 8)
    pPad.PaddingBottom = UDim.new(0, 8)
    pPad.Parent = para.Frame

    para.TitleLabel = Instance.new("TextLabel")
    para.TitleLabel.Name = "Title"
    para.TitleLabel.BackgroundTransparency = 1
    para.TitleLabel.Size = UDim2.new(1, 0, 0, 18)
    para.TitleLabel.Text = para.Title
    para.TitleLabel.TextColor3 = theme.TextPrimary
    para.TitleLabel.TextSize = theme.TextSizeBody
    para.TitleLabel.Font = theme.FontTitle
    para.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    para.TitleLabel.ZIndex = 5
    para.TitleLabel.Parent = para.Frame

    para.ContentLabel = Instance.new("TextLabel")
    para.ContentLabel.Name = "Content"
    para.ContentLabel.BackgroundTransparency = 1
    para.ContentLabel.Position = UDim2.new(0, 0, 0, 20)
    para.ContentLabel.Size = UDim2.new(1, 0, 0, 0)
    para.ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
    para.ContentLabel.Text = para.Content
    para.ContentLabel.TextColor3 = theme.TextSecondary
    para.ContentLabel.TextSize = theme.TextSizeSmall
    para.ContentLabel.Font = theme.FontBody
    para.ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    para.ContentLabel.TextWrapped = true
    para.ContentLabel.ZIndex = 5
    para.ContentLabel.Parent = para.Frame

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

function Section:AddButton(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local button = {}
    button.Type = "Button"
    button.Name = options.Name or "Button"
    button.Callback = options.Callback or function() end

    button.Frame = Instance.new("Frame")
    button.Frame.Name = "Button_" .. button.Name
    button.Frame.BackgroundColor3 = theme.ElementBackground
    button.Frame.Size = UDim2.new(1, 0, 0, 34)
    button.Frame.LayoutOrder = #self.Components + 1
    button.Frame.ZIndex = 4
    button.Frame.ClipsDescendants = true
    button.Frame.Parent = self.ComponentContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = theme.CornerRadius
    bCorner.Parent = button.Frame

    button.Button = Instance.new("TextButton")
    button.Button.Name = "Btn"
    button.Button.BackgroundTransparency = 1
    button.Button.Size = UDim2.new(1, 0, 1, 0)
    button.Button.Text = ""
    button.Button.ZIndex = 6
    button.Button.AutoButtonColor = false
    button.Button.Parent = button.Frame

    button.Label = Instance.new("TextLabel")
    button.Label.Name = "Label"
    button.Label.BackgroundTransparency = 1
    button.Label.Position = UDim2.new(0, 12, 0, 0)
    button.Label.Size = UDim2.new(1, -24, 1, 0)
    button.Label.Text = button.Name
    button.Label.TextColor3 = theme.TextPrimary
    button.Label.TextSize = theme.TextSizeBody
    button.Label.Font = theme.FontBody
    button.Label.TextXAlignment = Enum.TextXAlignment.Left
    button.Label.ZIndex = 5
    button.Label.Parent = button.Frame

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

    slider.Frame = Instance.new("Frame")
    slider.Frame.Name = "Slider_" .. slider.Name
    slider.Frame.BackgroundColor3 = theme.ElementBackground
    slider.Frame.Size = UDim2.new(1, 0, 0, 46)
    slider.Frame.LayoutOrder = order
    slider.Frame.ZIndex = 4
    slider.Frame.Parent = parent

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = theme.CornerRadius
    sCorner.Parent = slider.Frame

    slider.Label = Instance.new("TextLabel")
    slider.Label.Name = "Label"
    slider.Label.BackgroundTransparency = 1
    slider.Label.Position = UDim2.new(0, 12, 0, 2)
    slider.Label.Size = UDim2.new(0.6, -12, 0, 20)
    slider.Label.Text = slider.Name
    slider.Label.TextColor3 = theme.TextPrimary
    slider.Label.TextSize = theme.TextSizeBody
    slider.Label.Font = theme.FontBody
    slider.Label.TextXAlignment = Enum.TextXAlignment.Left
    slider.Label.ZIndex = 5
    slider.Label.Parent = slider.Frame

    slider.ValueLabel = Instance.new("TextLabel")
    slider.ValueLabel.Name = "Value"
    slider.ValueLabel.BackgroundTransparency = 1
    slider.ValueLabel.Position = UDim2.new(0.6, 0, 0, 2)
    slider.ValueLabel.Size = UDim2.new(0.4, -12, 0, 20)
    slider.ValueLabel.Text = Utility.FormatNumber(slider.Value, slider.Increment) .. slider.Suffix
    slider.ValueLabel.TextColor3 = theme.Accent
    slider.ValueLabel.TextSize = theme.TextSizeBody
    slider.ValueLabel.Font = theme.FontTitle
    slider.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    slider.ValueLabel.ZIndex = 5
    slider.ValueLabel.Parent = slider.Frame

    slider.Track = Instance.new("Frame")
    slider.Track.Name = "Track"
    slider.Track.BackgroundColor3 = theme.SliderBackground
    slider.Track.Position = UDim2.new(0, 12, 0, 26)
    slider.Track.Size = UDim2.new(1, -24, 0, 12)
    slider.Track.ZIndex = 5
    slider.Track.Parent = slider.Frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = slider.Track

    local range = slider.Max - slider.Min
    local fillPct = 0
    if range > 0 then
        fillPct = math.clamp((slider.Value - slider.Min) / range, 0, 1)
    end

    slider.Fill = Instance.new("Frame")
    slider.Fill.Name = "Fill"
    slider.Fill.BackgroundColor3 = theme.SliderFill
    slider.Fill.Size = UDim2.new(fillPct, 0, 1, 0)
    slider.Fill.ZIndex = 6
    slider.Fill.Parent = slider.Track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = slider.Fill

    slider.Input = Instance.new("TextButton")
    slider.Input.Name = "Input"
    slider.Input.BackgroundTransparency = 1
    slider.Input.Size = UDim2.new(1, 0, 1, 10)
    slider.Input.Position = UDim2.new(0, 0, 0, -5)
    slider.Input.Text = ""
    slider.Input.ZIndex = 8
    slider.Input.AutoButtonColor = false
    slider.Input.Parent = slider.Track

    local dragging = false

    local function updateSlider(input)
        local trackPos = slider.Track.AbsolutePosition.X
        local trackSize = slider.Track.AbsoluteSize.X
        if trackSize <= 0 then
            return
        end
        local pos = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
        local rawValue = slider.Min + (slider.Max - slider.Min) * pos
        local value = Utility.SnapValue(rawValue, slider.Min, slider.Max, slider.Increment)

        slider.Value = value
        slider.ValueLabel.Text = Utility.FormatNumber(value, slider.Increment) .. slider.Suffix

        local r = slider.Max - slider.Min
        local pct = 0
        if r > 0 then
            pct = math.clamp((value - slider.Min) / r, 0, 1)
        end
        Utility.Tween(slider.Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.06, Enum.EasingStyle.Linear)

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
                local sel = {}
                for _, v in ipairs(dropdown.Options) do
                    if dropdown.Value[v] then
                        table.insert(sel, v)
                    end
                end
                if #sel == 0 then
                    return "None"
                end
                return table.concat(sel, ", ")
            end
            return "None"
        else
            return tostring(dropdown.Value)
        end
    end

    dropdown.Frame = Instance.new("Frame")
    dropdown.Frame.Name = "Dropdown_" .. dropdown.Name
    dropdown.Frame.BackgroundColor3 = theme.ElementBackground
    dropdown.Frame.Size = UDim2.new(1, 0, 0, 34)
    dropdown.Frame.LayoutOrder = order
    dropdown.Frame.ZIndex = 4
    dropdown.Frame.ClipsDescendants = true
    dropdown.Frame.Parent = parent

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = theme.CornerRadius
    dCorner.Parent = dropdown.Frame

    dropdown.Label = Instance.new("TextLabel")
    dropdown.Label.Name = "Label"
    dropdown.Label.BackgroundTransparency = 1
    dropdown.Label.Position = UDim2.new(0, 12, 0, 0)
    dropdown.Label.Size = UDim2.new(0.45, 0, 0, 34)
    dropdown.Label.Text = dropdown.Name
    dropdown.Label.TextColor3 = theme.TextPrimary
    dropdown.Label.TextSize = theme.TextSizeBody
    dropdown.Label.Font = theme.FontBody
    dropdown.Label.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.Label.ZIndex = 5
    dropdown.Label.Parent = dropdown.Frame

    dropdown.SelectedLabel = Instance.new("TextLabel")
    dropdown.SelectedLabel.Name = "Selected"
    dropdown.SelectedLabel.BackgroundColor3 = theme.DropdownBackground
    dropdown.SelectedLabel.Position = UDim2.new(0.45, 4, 0, 5)
    dropdown.SelectedLabel.Size = UDim2.new(0.55, -20, 0, 24)
    dropdown.SelectedLabel.Text = getDisplayText()
    dropdown.SelectedLabel.TextColor3 = theme.Accent
    dropdown.SelectedLabel.TextSize = theme.TextSizeSmall
    dropdown.SelectedLabel.Font = theme.FontBody
    dropdown.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Center
    dropdown.SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
    dropdown.SelectedLabel.ZIndex = 5
    dropdown.SelectedLabel.Parent = dropdown.Frame

    local selCorner = Instance.new("UICorner")
    selCorner.CornerRadius = UDim.new(0, 4)
    selCorner.Parent = dropdown.SelectedLabel

    dropdown.ArrowLabel = Instance.new("TextLabel")
    dropdown.ArrowLabel.Name = "Arrow"
    dropdown.ArrowLabel.BackgroundTransparency = 1
    dropdown.ArrowLabel.Position = UDim2.new(1, -20, 0, 0)
    dropdown.ArrowLabel.Size = UDim2.new(0, 14, 0, 34)
    dropdown.ArrowLabel.Text = "▼"
    dropdown.ArrowLabel.TextColor3 = theme.TextDimmed
    dropdown.ArrowLabel.TextSize = 8
    dropdown.ArrowLabel.Font = Enum.Font.GothamBold
    dropdown.ArrowLabel.ZIndex = 5
    dropdown.ArrowLabel.Parent = dropdown.Frame

    dropdown.OptionsFrame = Instance.new("Frame")
    dropdown.OptionsFrame.Name = "Options"
    dropdown.OptionsFrame.BackgroundColor3 = theme.DropdownBackground
    dropdown.OptionsFrame.Position = UDim2.new(0, 6, 0, 38)
    dropdown.OptionsFrame.Size = UDim2.new(1, -12, 0, 0)
    dropdown.OptionsFrame.AutomaticSize = Enum.AutomaticSize.Y
    dropdown.OptionsFrame.Visible = false
    dropdown.OptionsFrame.ZIndex = 10
    dropdown.OptionsFrame.ClipsDescendants = true
    dropdown.OptionsFrame.Parent = dropdown.Frame

    local optCorner = Instance.new("UICorner")
    optCorner.CornerRadius = UDim.new(0, 4)
    optCorner.Parent = dropdown.OptionsFrame

    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Padding = UDim.new(0, 1)
    optLayout.Parent = dropdown.OptionsFrame

    local optPad = Instance.new("UIPadding")
    optPad.PaddingTop = UDim.new(0, 2)
    optPad.PaddingBottom = UDim.new(0, 2)
    optPad.Parent = dropdown.OptionsFrame

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

            local optBtn = Instance.new("TextButton")
            optBtn.Name = "Option_" .. option
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.Text = ""
            optBtn.LayoutOrder = i
            optBtn.ZIndex = 11
            optBtn.AutoButtonColor = false
            optBtn.Parent = dropdown.OptionsFrame

            if isSelected then
                optBtn.BackgroundColor3 = theme.Accent
                optBtn.BackgroundTransparency = 0.8
            else
                optBtn.BackgroundColor3 = theme.DropdownBackground
                optBtn.BackgroundTransparency = 1
            end

            local optLabel = Instance.new("TextLabel")
            optLabel.Name = "Label"
            optLabel.BackgroundTransparency = 1
            optLabel.Position = UDim2.new(0, 10, 0, 0)
            optLabel.Size = UDim2.new(1, -20, 1, 0)
            optLabel.Text = option
            optLabel.TextSize = theme.TextSizeSmall
            optLabel.TextXAlignment = Enum.TextXAlignment.Left
            optLabel.ZIndex = 12
            optLabel.Parent = optBtn

            if isSelected then
                optLabel.TextColor3 = theme.Accent
                optLabel.Font = theme.FontTitle
            else
                optLabel.TextColor3 = theme.TextSecondary
                optLabel.Font = theme.FontBody
            end

            if isSelected then
                local check = Instance.new("TextLabel")
                check.Name = "Check"
                check.BackgroundTransparency = 1
                check.Position = UDim2.new(1, -24, 0, 0)
                check.Size = UDim2.new(0, 14, 1, 0)
                check.Text = "✓"
                check.TextColor3 = theme.Accent
                check.TextSize = 12
                check.Font = Enum.Font.GothamBold
                check.ZIndex = 12
                check.Parent = optBtn
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
        local count = math.min(#self.Options, 6)
        local h = 34 + 8 + (count * 27) + 8
        Utility.Tween(self.Frame, {Size = UDim2.new(1, 0, 0, h)}, 0.2)
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

    local clickBtn = Instance.new("TextButton")
    clickBtn.Name = "ClickArea"
    clickBtn.BackgroundTransparency = 1
    clickBtn.Size = UDim2.new(1, 0, 0, 34)
    clickBtn.Text = ""
    clickBtn.ZIndex = 8
    clickBtn.AutoButtonColor = false
    clickBtn.Parent = dropdown.Frame

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

    textbox.Frame = Instance.new("Frame")
    textbox.Frame.Name = "TextBox_" .. textbox.Name
    textbox.Frame.BackgroundColor3 = theme.ElementBackground
    textbox.Frame.Size = UDim2.new(1, 0, 0, 34)
    textbox.Frame.LayoutOrder = #self.Components + 1
    textbox.Frame.ZIndex = 4
    textbox.Frame.Parent = self.ComponentContainer

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = theme.CornerRadius
    tbCorner.Parent = textbox.Frame

    textbox.Label = Instance.new("TextLabel")
    textbox.Label.Name = "Label"
    textbox.Label.BackgroundTransparency = 1
    textbox.Label.Position = UDim2.new(0, 12, 0, 0)
    textbox.Label.Size = UDim2.new(0.4, 0, 1, 0)
    textbox.Label.Text = textbox.Name
    textbox.Label.TextColor3 = theme.TextPrimary
    textbox.Label.TextSize = theme.TextSizeBody
    textbox.Label.Font = theme.FontBody
    textbox.Label.TextXAlignment = Enum.TextXAlignment.Left
    textbox.Label.ZIndex = 5
    textbox.Label.Parent = textbox.Frame

    textbox.Input = Instance.new("TextBox")
    textbox.Input.Name = "Input"
    textbox.Input.BackgroundColor3 = theme.InputBackground
    textbox.Input.Position = UDim2.new(0.4, 4, 0, 5)
    textbox.Input.Size = UDim2.new(0.6, -16, 0, 24)
    textbox.Input.Text = textbox.Value
    textbox.Input.PlaceholderText = textbox.PlaceholderText
    textbox.Input.PlaceholderColor3 = theme.TextDimmed
    textbox.Input.TextColor3 = theme.TextPrimary
    textbox.Input.TextSize = theme.TextSizeSmall
    textbox.Input.Font = theme.FontBody
    textbox.Input.ClearTextOnFocus = textbox.ClearOnFocus
    textbox.Input.ZIndex = 6
    textbox.Input.BorderSizePixel = 0
    textbox.Input.Parent = textbox.Frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = textbox.Input

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = theme.InputBorder
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5
    inputStroke.Parent = textbox.Input

    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, 6)
    inputPad.PaddingRight = UDim.new(0, 6)
    inputPad.Parent = textbox.Input

    textbox.Input.Focused:Connect(function()
        Utility.Tween(inputStroke, {Color = theme.Accent, Transparency = 0}, 0.15)
    end)
    textbox.Input.FocusLost:Connect(function()
        Utility.Tween(inputStroke, {Color = theme.InputBorder, Transparency = 0.5}, 0.15)
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

    keybind.Frame = Instance.new("Frame")
    keybind.Frame.Name = "Keybind_" .. keybind.Name
    keybind.Frame.BackgroundColor3 = theme.ElementBackground
    keybind.Frame.Size = UDim2.new(1, 0, 0, 34)
    keybind.Frame.LayoutOrder = order
    keybind.Frame.ZIndex = 4
    keybind.Frame.Parent = parent

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = theme.CornerRadius
    kCorner.Parent = keybind.Frame

    keybind.Label = Instance.new("TextLabel")
    keybind.Label.Name = "Label"
    keybind.Label.BackgroundTransparency = 1
    keybind.Label.Position = UDim2.new(0, 12, 0, 0)
    keybind.Label.Size = UDim2.new(0.6, 0, 1, 0)
    keybind.Label.Text = keybind.Name
    keybind.Label.TextColor3 = theme.TextPrimary
    keybind.Label.TextSize = theme.TextSizeBody
    keybind.Label.Font = theme.FontBody
    keybind.Label.TextXAlignment = Enum.TextXAlignment.Left
    keybind.Label.ZIndex = 5
    keybind.Label.Parent = keybind.Frame

    local keyName = "None"
    if keybind.Value ~= Enum.KeyCode.Unknown then
        keyName = keybind.Value.Name
    end

    keybind.KeyButton = Instance.new("TextButton")
    keybind.KeyButton.Name = "KeyBtn"
    keybind.KeyButton.BackgroundColor3 = theme.InputBackground
    keybind.KeyButton.Position = UDim2.new(1, -80, 0, 5)
    keybind.KeyButton.Size = UDim2.new(0, 68, 0, 24)
    keybind.KeyButton.Text = "[" .. keyName .. "]"
    keybind.KeyButton.TextColor3 = theme.Accent
    keybind.KeyButton.TextSize = theme.TextSizeSmall
    keybind.KeyButton.Font = theme.FontMono
    keybind.KeyButton.ZIndex = 6
    keybind.KeyButton.AutoButtonColor = false
    keybind.KeyButton.Parent = keybind.Frame

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 4)
    keyCorner.Parent = keybind.KeyButton

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = theme.InputBorder
    keyStroke.Thickness = 1
    keyStroke.Transparency = 0.5
    keyStroke.Parent = keybind.KeyButton

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
                    local n = "None"
                    if keybind.Value ~= Enum.KeyCode.Unknown then
                        n = keybind.Value.Name
                    end
                    keybind.KeyButton.Text = "[" .. n .. "]"
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
        local n = "None"
        if key ~= Enum.KeyCode.Unknown then
            n = key.Name
        end
        self.KeyButton.Text = "[" .. n .. "]"
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

    toggle.Frame = Instance.new("Frame")
    toggle.Frame.Name = "SubToggle_" .. toggle.Name
    toggle.Frame.BackgroundColor3 = theme.ElementBackground
    toggle.Frame.Size = UDim2.new(1, 0, 0, 30)
    toggle.Frame.LayoutOrder = order
    toggle.Frame.ZIndex = 4
    toggle.Frame.Parent = parent

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 4)
    stCorner.Parent = toggle.Frame

    toggle.Label = Instance.new("TextLabel")
    toggle.Label.Name = "Label"
    toggle.Label.BackgroundTransparency = 1
    toggle.Label.Position = UDim2.new(0, 8, 0, 0)
    toggle.Label.Size = UDim2.new(1, -54, 1, 0)
    toggle.Label.Text = toggle.Name
    toggle.Label.TextColor3 = theme.TextSecondary
    toggle.Label.TextSize = theme.TextSizeSmall
    toggle.Label.Font = theme.FontBody
    toggle.Label.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Label.ZIndex = 5
    toggle.Label.Parent = toggle.Frame

    local switchBg = theme.ToggleDisabled
    local circlePos = UDim2.new(0, 2, 0.5, -5)
    if toggle.Value then
        switchBg = theme.ToggleEnabled
        circlePos = UDim2.new(1, -12, 0.5, -5)
    end

    toggle.SwitchFrame = Instance.new("Frame")
    toggle.SwitchFrame.Name = "Switch"
    toggle.SwitchFrame.BackgroundColor3 = switchBg
    toggle.SwitchFrame.Position = UDim2.new(1, -42, 0.5, -7)
    toggle.SwitchFrame.Size = UDim2.new(0, 32, 0, 14)
    toggle.SwitchFrame.ZIndex = 5
    toggle.SwitchFrame.Parent = toggle.Frame

    local stSwitchCorner = Instance.new("UICorner")
    stSwitchCorner.CornerRadius = UDim.new(1, 0)
    stSwitchCorner.Parent = toggle.SwitchFrame

    toggle.SwitchCircle = Instance.new("Frame")
    toggle.SwitchCircle.Name = "Circle"
    toggle.SwitchCircle.BackgroundColor3 = theme.ToggleCircle
    toggle.SwitchCircle.Position = circlePos
    toggle.SwitchCircle.Size = UDim2.new(0, 10, 0, 10)
    toggle.SwitchCircle.ZIndex = 6
    toggle.SwitchCircle.Parent = toggle.SwitchFrame

    local stCircleCorner = Instance.new("UICorner")
    stCircleCorner.CornerRadius = UDim.new(1, 0)
    stCircleCorner.Parent = toggle.SwitchCircle

    local clickBtn = Instance.new("TextButton")
    clickBtn.Name = "Click"
    clickBtn.BackgroundTransparency = 1
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.Text = ""
    clickBtn.ZIndex = 7
    clickBtn.AutoButtonColor = false
    clickBtn.Parent = toggle.Frame

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

function Section._createColorPicker(parent, order, options, theme, library)
    options = options or {}
    local cp = {}
    cp.Type = "ColorPicker"
    cp.Name = options.Name or "Color"
    cp.Value = options.Default or Color3.fromRGB(255, 0, 0)
    cp.Callback = options.Callback or function() end
    cp.Flag = options.Flag
    cp._open = false

    if cp.Flag and library.ConfigManager then
        library.ConfigManager:RegisterFlag(cp.Flag, cp.Value)
        local saved = library.ConfigManager:GetValue(cp.Flag)
        if saved ~= nil then
            cp.Value = saved
        end
    end
    if cp.Flag then
        library.Flags[cp.Flag] = cp
    end

    local h, s, v = cp.Value:ToHSV()

    cp.Frame = Instance.new("Frame")
    cp.Frame.Name = "ColorPicker_" .. cp.Name
    cp.Frame.BackgroundColor3 = theme.ElementBackground
    cp.Frame.Size = UDim2.new(1, 0, 0, 34)
    cp.Frame.LayoutOrder = order
    cp.Frame.ZIndex = 4
    cp.Frame.ClipsDescendants = true
    cp.Frame.Parent = parent

    local cpCorner = Instance.new("UICorner")
    cpCorner.CornerRadius = theme.CornerRadius
    cpCorner.Parent = cp.Frame

    cp.Label = Instance.new("TextLabel")
    cp.Label.Name = "Label"
    cp.Label.BackgroundTransparency = 1
    cp.Label.Position = UDim2.new(0, 12, 0, 0)
    cp.Label.Size = UDim2.new(0.6, 0, 0, 34)
    cp.Label.Text = cp.Name
    cp.Label.TextColor3 = theme.TextPrimary
    cp.Label.TextSize = theme.TextSizeBody
    cp.Label.Font = theme.FontBody
    cp.Label.TextXAlignment = Enum.TextXAlignment.Left
    cp.Label.ZIndex = 5
    cp.Label.Parent = cp.Frame

    cp.Preview = Instance.new("TextButton")
    cp.Preview.Name = "Preview"
    cp.Preview.BackgroundColor3 = cp.Value
    cp.Preview.Position = UDim2.new(1, -42, 0, 7)
    cp.Preview.Size = UDim2.new(0, 30, 0, 20)
    cp.Preview.Text = ""
    cp.Preview.ZIndex = 6
    cp.Preview.AutoButtonColor = false
    cp.Preview.Parent = cp.Frame

    local prevCorner = Instance.new("UICorner")
    prevCorner.CornerRadius = UDim.new(0, 4)
    prevCorner.Parent = cp.Preview

    local prevStroke = Instance.new("UIStroke")
    prevStroke.Color = theme.InputBorder
    prevStroke.Thickness = 1
    prevStroke.Parent = cp.Preview

    cp.Panel = Instance.new("Frame")
    cp.Panel.Name = "Panel"
    cp.Panel.BackgroundColor3 = theme.DropdownBackground
    cp.Panel.Position = UDim2.new(0, 6, 0, 38)
    cp.Panel.Size = UDim2.new(1, -12, 0, 130)
    cp.Panel.Visible = false
    cp.Panel.ZIndex = 10
    cp.Panel.Parent = cp.Frame

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 4)
    panelCorner.Parent = cp.Panel

    cp.SVFrame = Instance.new("ImageLabel")
    cp.SVFrame.Name = "SV"
    cp.SVFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    cp.SVFrame.Position = UDim2.new(0, 8, 0, 8)
    cp.SVFrame.Size = UDim2.new(1, -40, 0, 85)
    cp.SVFrame.Image = "rbxassetid://4155801252"
    cp.SVFrame.ZIndex = 11
    cp.SVFrame.Parent = cp.Panel

    local svCorner = Instance.new("UICorner")
    svCorner.CornerRadius = UDim.new(0, 3)
    svCorner.Parent = cp.SVFrame

    cp.SVCursor = Instance.new("Frame")
    cp.SVCursor.Name = "Cursor"
    cp.SVCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    cp.SVCursor.Position = UDim2.new(s, -5, 1 - v, -5)
    cp.SVCursor.Size = UDim2.new(0, 10, 0, 10)
    cp.SVCursor.ZIndex = 13
    cp.SVCursor.Parent = cp.SVFrame

    local svCursorCorner = Instance.new("UICorner")
    svCursorCorner.CornerRadius = UDim.new(1, 0)
    svCursorCorner.Parent = cp.SVCursor

    local svCursorStroke = Instance.new("UIStroke")
    svCursorStroke.Color = Color3.new(0, 0, 0)
    svCursorStroke.Thickness = 1
    svCursorStroke.Parent = cp.SVCursor

    cp.HueFrame = Instance.new("Frame")
    cp.HueFrame.Name = "Hue"
    cp.HueFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    cp.HueFrame.Position = UDim2.new(1, -26, 0, 8)
    cp.HueFrame.Size = UDim2.new(0, 18, 0, 85)
    cp.HueFrame.ZIndex = 11
    cp.HueFrame.Parent = cp.Panel

    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(0, 3)
    hueCorner.Parent = cp.HueFrame

    -- Build hue gradient without nesting
    local hueKP = {}
    table.insert(hueKP, ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)))
    table.insert(hueKP, ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)))
    table.insert(hueKP, ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)))
    table.insert(hueKP, ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)))
    table.insert(hueKP, ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)))
    table.insert(hueKP, ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)))
    table.insert(hueKP, ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)))
    local hueSeq = ColorSequence.new(hueKP)

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = hueSeq
    hueGrad.Rotation = 90
    hueGrad.Parent = cp.HueFrame

    cp.HueCursor = Instance.new("Frame")
    cp.HueCursor.Name = "HueCursor"
    cp.HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    cp.HueCursor.Position = UDim2.new(0, -2, h, -3)
    cp.HueCursor.Size = UDim2.new(1, 4, 0, 6)
    cp.HueCursor.ZIndex = 13
    cp.HueCursor.Parent = cp.HueFrame

    local hueCursorCorner = Instance.new("UICorner")
    hueCursorCorner.CornerRadius = UDim.new(0, 2)
    hueCursorCorner.Parent = cp.HueCursor

    local hueCursorStroke = Instance.new("UIStroke")
    hueCursorStroke.Color = Color3.new(0, 0, 0)
    hueCursorStroke.Thickness = 1
    hueCursorStroke.Parent = cp.HueCursor

    cp.HexInput = Instance.new("TextBox")
    cp.HexInput.Name = "Hex"
    cp.HexInput.BackgroundColor3 = theme.InputBackground
    cp.HexInput.Position = UDim2.new(0, 8, 0, 100)
    cp.HexInput.Size = UDim2.new(1, -16, 0, 22)
    cp.HexInput.Text = Utility.Color3ToHex(cp.Value)
    cp.HexInput.PlaceholderText = "#FF0000"
    cp.HexInput.PlaceholderColor3 = theme.TextDimmed
    cp.HexInput.TextColor3 = theme.TextPrimary
    cp.HexInput.TextSize = theme.TextSizeSmall
    cp.HexInput.Font = theme.FontMono
    cp.HexInput.ZIndex = 12
    cp.HexInput.BorderSizePixel = 0
    cp.HexInput.Parent = cp.Panel

    local hexCorner = Instance.new("UICorner")
    hexCorner.CornerRadius = UDim.new(0, 3)
    hexCorner.Parent = cp.HexInput

    local hexPad = Instance.new("UIPadding")
    hexPad.PaddingLeft = UDim.new(0, 6)
    hexPad.Parent = cp.HexInput

    local function updateColor(newH, newS, newV)
        if newH then h = newH end
        if newS then s = newS end
        if newV then v = newV end
        cp.Value = Color3.fromHSV(h, s, v)
        cp.Preview.BackgroundColor3 = cp.Value
        cp.SVFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cp.SVCursor.Position = UDim2.new(s, -5, 1 - v, -5)
        cp.HueCursor.Position = UDim2.new(0, -2, h, -3)
        cp.HexInput.Text = Utility.Color3ToHex(cp.Value)
        if cp.Flag and library.ConfigManager then
            library.ConfigManager:SetValue(cp.Flag, cp.Value)
        end
        pcall(cp.Callback, cp.Value)
    end

    local svDragging = false
    local svBtn = Instance.new("TextButton")
    svBtn.Name = "SVInput"
    svBtn.BackgroundTransparency = 1
    svBtn.Size = UDim2.new(1, 0, 1, 0)
    svBtn.Text = ""
    svBtn.ZIndex = 14
    svBtn.AutoButtonColor = false
    svBtn.Parent = cp.SVFrame

    svBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
        end
    end)
    svBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)

    local hueDragging = false
    local hueBtn = Instance.new("TextButton")
    hueBtn.Name = "HueInput"
    hueBtn.BackgroundTransparency = 1
    hueBtn.Size = UDim2.new(1, 0, 1, 0)
    hueBtn.Text = ""
    hueBtn.ZIndex = 14
    hueBtn.AutoButtonColor = false
    hueBtn.Parent = cp.HueFrame

    hueBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
        end
    end)
    hueBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local absPos = cp.SVFrame.AbsolutePosition
                local absSize = cp.SVFrame.AbsoluteSize
                if absSize.X > 0 and absSize.Y > 0 then
                    local ns = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
                    local nv = math.clamp(1 - (input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    updateColor(nil, ns, nv)
                end
            end
            if hueDragging then
                local absPos = cp.HueFrame.AbsolutePosition
                local absSize = cp.HueFrame.AbsoluteSize
                if absSize.Y > 0 then
                    local nh = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    updateColor(nh, nil, nil)
                end
            end
        end
    end)

    cp.HexInput.FocusLost:Connect(function()
        local text = cp.HexInput.Text
        local success, color = pcall(Utility.HexToColor3, text)
        if success and color then
            local nh, ns, nv = color:ToHSV()
            updateColor(nh, ns, nv)
        else
            cp.HexInput.Text = Utility.Color3ToHex(cp.Value)
        end
    end)

    cp.Preview.MouseButton1Click:Connect(function()
        cp._open = not cp._open
        cp.Panel.Visible = cp._open
        local targetH = 34
        if cp._open then
            targetH = 176
        end
        Utility.Tween(cp.Frame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.2)
    end)

    cp.Frame.MouseEnter:Connect(function()
        Utility.Tween(cp.Frame, {BackgroundColor3 = theme.ElementBackgroundHover}, 0.15)
    end)
    cp.Frame.MouseLeave:Connect(function()
        Utility.Tween(cp.Frame, {BackgroundColor3 = theme.ElementBackground}, 0.15)
    end)

    function cp:Set(color)
        local nh, ns, nv = color:ToHSV()
        updateColor(nh, ns, nv)
    end

    function cp:GetValue()
        return self.Value
    end

    return cp
end

function Section:AddColorPicker(options)
    local theme = self.Library.CurrentTheme
    local cp = Section._createColorPicker(self.ComponentContainer, #self.Components + 1, options, theme, self.Library)
    table.insert(self.Components, cp)
    return cp
end

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

    toggle.Frame = Instance.new("Frame")
    toggle.Frame.Name = "Toggle_" .. toggle.Name
    toggle.Frame.BackgroundColor3 = theme.ElementBackground
    toggle.Frame.Size = UDim2.new(1, 0, 0, 34)
    toggle.Frame.AutomaticSize = Enum.AutomaticSize.Y
    toggle.Frame.LayoutOrder = #self.Components + 1
    toggle.Frame.ZIndex = 4
    toggle.Frame.ClipsDescendants = true
    toggle.Frame.Parent = self.ComponentContainer

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = theme.CornerRadius
    tCorner.Parent = toggle.Frame

    toggle.MainRow = Instance.new("Frame")
    toggle.MainRow.Name = "MainRow"
    toggle.MainRow.BackgroundTransparency = 1
    toggle.MainRow.Size = UDim2.new(1, 0, 0, 34)
    toggle.MainRow.ZIndex = 4
    toggle.MainRow.Parent = toggle.Frame

    toggle.Arrow = Instance.new("TextLabel")
    toggle.Arrow.Name = "Arrow"
    toggle.Arrow.BackgroundTransparency = 1
    toggle.Arrow.Position = UDim2.new(0, 8, 0, 0)
    toggle.Arrow.Size = UDim2.new(0, 16, 1, 0)
    toggle.Arrow.Text = "▶"
    toggle.Arrow.TextColor3 = theme.TextDimmed
    toggle.Arrow.TextSize = 8
    toggle.Arrow.Font = Enum.Font.GothamBold
    toggle.Arrow.Visible = false
    toggle.Arrow.ZIndex = 5
    toggle.Arrow.Parent = toggle.MainRow

    toggle.Label = Instance.new("TextLabel")
    toggle.Label.Name = "Label"
    toggle.Label.BackgroundTransparency = 1
    toggle.Label.Position = UDim2.new(0, 12, 0, 0)
    toggle.Label.Size = UDim2.new(1, -70, 1, 0)
    toggle.Label.Text = toggle.Name
    toggle.Label.TextColor3 = theme.TextPrimary
    toggle.Label.TextSize = theme.TextSizeBody
    toggle.Label.Font = theme.FontBody
    toggle.Label.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Label.ZIndex = 5
    toggle.Label.Parent = toggle.MainRow

    local switchBg = theme.ToggleDisabled
    local circlePos = UDim2.new(0, 2, 0.5, -7)
    if toggle.Value then
        switchBg = theme.ToggleEnabled
        circlePos = UDim2.new(1, -16, 0.5, -7)
    end

    toggle.SwitchFrame = Instance.new("Frame")
    toggle.SwitchFrame.Name = "Switch"
    toggle.SwitchFrame.BackgroundColor3 = switchBg
    toggle.SwitchFrame.Position = UDim2.new(1, -50, 0.5, -9)
    toggle.SwitchFrame.Size = UDim2.new(0, 38, 0, 18)
    toggle.SwitchFrame.ZIndex = 5
    toggle.SwitchFrame.Parent = toggle.MainRow

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = toggle.SwitchFrame

    toggle.SwitchCircle = Instance.new("Frame")
    toggle.SwitchCircle.Name = "Circle"
    toggle.SwitchCircle.BackgroundColor3 = theme.ToggleCircle
    toggle.SwitchCircle.Position = circlePos
    toggle.SwitchCircle.Size = UDim2.new(0, 14, 0, 14)
    toggle.SwitchCircle.ZIndex = 6
    toggle.SwitchCircle.Parent = toggle.SwitchFrame

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggle.SwitchCircle

    toggle.ClickBtn = Instance.new("TextButton")
    toggle.ClickBtn.Name = "Click"
    toggle.ClickBtn.BackgroundTransparency = 1
    toggle.ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    toggle.ClickBtn.Text = ""
    toggle.ClickBtn.ZIndex = 7
    toggle.ClickBtn.AutoButtonColor = false
    toggle.ClickBtn.Parent = toggle.MainRow

    toggle.SubContainer = Instance.new("Frame")
    toggle.SubContainer.Name = "SubComponents"
    toggle.SubContainer.BackgroundTransparency = 1
    toggle.SubContainer.Position = UDim2.new(0, 0, 0, 34)
    toggle.SubContainer.Size = UDim2.new(1, 0, 0, 0)
    toggle.SubContainer.AutomaticSize = Enum.AutomaticSize.Y
    toggle.SubContainer.Visible = false
    toggle.SubContainer.ZIndex = 4
    toggle.SubContainer.ClipsDescendants = true
    toggle.SubContainer.Parent = toggle.Frame

    toggle.SubLine = Instance.new("Frame")
    toggle.SubLine.Name = "SubLine"
    toggle.SubLine.BackgroundColor3 = theme.Accent
    toggle.SubLine.BackgroundTransparency = 0.6
    toggle.SubLine.Position = UDim2.new(0, 10, 0, 2)
    toggle.SubLine.Size = UDim2.new(0, 2, 1, -4)
    toggle.SubLine.BorderSizePixel = 0
    toggle.SubLine.ZIndex = 5
    toggle.SubLine.Parent = toggle.SubContainer

    toggle.SubLayout = Instance.new("Frame")
    toggle.SubLayout.Name = "SubLayout"
    toggle.SubLayout.BackgroundTransparency = 1
    toggle.SubLayout.Position = UDim2.new(0, 20, 0, 0)
    toggle.SubLayout.Size = UDim2.new(1, -28, 0, 0)
    toggle.SubLayout.AutomaticSize = Enum.AutomaticSize.Y
    toggle.SubLayout.ZIndex = 4
    toggle.SubLayout.Parent = toggle.SubContainer

    local subListLayout = Instance.new("UIListLayout")
    subListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    subListLayout.Padding = UDim.new(0, 4)
    subListLayout.Parent = toggle.SubLayout

    local subPad = Instance.new("UIPadding")
    subPad.PaddingTop = UDim.new(0, 4)
    subPad.PaddingBottom = UDim.new(0, 4)
    subPad.Parent = toggle.SubLayout

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

    function toggle:AddSlider(subOpts)
        subOpts = subOpts or {}
        local comp = Section._createSlider(self.SubLayout, #self.SubComponents + 1, subOpts, theme, lib)
        table.insert(self.SubComponents, comp)
        updateArrowVisibility()
        return comp
    end

    function toggle:AddDropdown(subOpts)
        subOpts = subOpts or {}
        local comp = Section._createDropdown(self.SubLayout, #self.SubComponents + 1, subOpts, theme, lib)
        table.insert(self.SubComponents, comp)
        updateArrowVisibility()
        return comp
    end

    function toggle:AddToggle(subOpts)
        subOpts = subOpts or {}
        local comp = Section._createSubToggle(self.SubLayout, #self.SubComponents + 1, subOpts, theme, lib)
        table.insert(self.SubComponents, comp)
        updateArrowVisibility()
        return comp
    end

    function toggle:AddKeybind(subOpts)
        subOpts = subOpts or {}
        local comp = Section._createKeybind(self.SubLayout, #self.SubComponents + 1, subOpts, theme, lib)
        table.insert(self.SubComponents, comp)
        updateArrowVisibility()
        return comp
    end

    function toggle:AddColorPicker(subOpts)
        subOpts = subOpts or {}
        local comp = Section._createColorPicker(self.SubLayout, #self.SubComponents + 1, subOpts, theme, lib)
        table.insert(self.SubComponents, comp)
        updateArrowVisibility()
        return comp
    end

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

    if toggle.Value then
        task.defer(function()
            pcall(toggle.Callback, toggle.Value)
        end)
    end

    table.insert(self.Components, toggle)
    return toggle
end

function Window:CreateConfigTab(options)
    options = options or {}
    local theme = self.Library.CurrentTheme
    local lib = self.Library

    local configTab = self:CreateTab({
        Name = options.Name or "Settings",
        Icon = options.Icon or "⚙",
        Order = 999,
    })

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
                    local ok = lib.ConfigManager:Save(configName)
                    if ok then
                        lib:Notify({Title = "Config Saved", Content = "Saved '" .. configName .. "'", Type = "Success", Duration = 3})
                    else
                        lib:Notify({Title = "Save Failed", Content = "Could not save", Type = "Error", Duration = 3})
                    end
                else
                    lib:Notify({Title = "Error", Content = "Enter a config name", Type = "Error", Duration = 2})
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
                    local ok = lib.ConfigManager:Load(configName)
                    if ok then
                        for id, comp in pairs(lib.Flags) do
                            local saved = lib.ConfigManager:GetValue(id)
                            if saved ~= nil and comp.Set then
                                comp:Set(saved)
                            end
                        end
                        lib:Notify({Title = "Config Loaded", Content = "Loaded '" .. configName .. "'", Type = "Success", Duration = 3})
                    else
                        lib:Notify({Title = "Load Failed", Content = "Could not load", Type = "Error", Duration = 3})
                    end
                end
            end
        })

        configSection:AddButton({
            Name = "Refresh List",
            Callback = function()
                configDropdown:SetOptions(lib.ConfigManager:GetConfigs())
            end
        })

        configSection:AddButton({
            Name = "Delete Config",
            Callback = function()
                if configName ~= "" then
                    local ok = lib.ConfigManager:Delete(configName)
                    configDropdown:SetOptions(lib.ConfigManager:GetConfigs())
                    if ok then
                        lib:Notify({Title = "Deleted", Content = "Deleted '" .. configName .. "'", Type = "Success", Duration = 3})
                    else
                        lib:Notify({Title = "Delete Failed", Content = "Could not delete", Type = "Error", Duration = 3})
                    end
                end
            end
        })
    end

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

function Library:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end
    self.Windows = {}
    self.Flags = {}
    self.OnThemeChanged:Destroy()
end

return Library
