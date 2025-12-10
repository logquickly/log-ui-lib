--[[
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         NexusUI Library v3.0                                   ║
║                    Vape-Style Modular UI Framework                             ║
║                        Created by log_quick                                    ║
╚═══════════════════════════════════════════════════════════════════════════════╝

特点:
- Vape风格的模块化界面
- 左侧类别栏 + 右侧模块网格
- 可展开的模块设置面板
- 科幻风格 + 彩虹边框
- 圆形调色盘
- 高级载入动画
- 完整配置系统
- 手机适配
]]

local NexusUI = {}
NexusUI.__index = NexusUI
NexusUI.Version = "3.0.0"
NexusUI.Author = "log_quick"

-- ============================================================================
-- Services
-- ============================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================================
-- Configuration
-- ============================================================================
local Config = {
    Theme = {
        Primary = Color3.fromRGB(0, 170, 255),
        Secondary = Color3.fromRGB(138, 43, 226),
        Accent = Color3.fromRGB(0, 255, 150),
        
        Background = Color3.fromRGB(20, 20, 30),
        BackgroundDark = Color3.fromRGB(15, 15, 22),
        BackgroundLight = Color3.fromRGB(30, 30, 45),
        
        ModuleEnabled = Color3.fromRGB(0, 170, 255),
        ModuleDisabled = Color3.fromRGB(45, 45, 60),
        
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 165),
        TextDisabled = Color3.fromRGB(100, 100, 115),
        
        Success = Color3.fromRGB(75, 255, 130),
        Error = Color3.fromRGB(255, 75, 85),
        Warning = Color3.fromRGB(255, 200, 75)
    },
    RainbowColors = {
        Color3.fromRGB(255, 0, 80),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 100),
        Color3.fromRGB(0, 170, 255),
        Color3.fromRGB(127, 0, 255),
        Color3.fromRGB(255, 0, 200)
    },
    Transparency = 0.05,
    AnimSpeed = 0.25,
    SoundEnabled = true,
    ConfigFolder = "NexusUI_Configs"
}

-- ============================================================================
-- Sound Library
-- ============================================================================
local Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079735",
    Toggle = "rbxassetid://6895079586",
    Success = "rbxassetid://6895079443",
    Error = "rbxassetid://6895079309",
    Whoosh = "rbxassetid://6895079182",
    Startup = "rbxassetid://5869673086",
    Notification = "rbxassetid://4590657391"
}

-- ============================================================================
-- Utility Module
-- ============================================================================
local Utility = {}

function Utility.Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties or {}) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or Config.AnimSpeed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utility.PlaySound(id, volume, pitch)
    if not Config.SoundEnabled then return end
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
    return sound
end

function Utility.Ripple(parent, x, y)
    local ripple = Utility.Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = parent.ZIndex + 5
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ripple})
    
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    Utility.Tween(ripple, {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1}, 0.4)
    task.delay(0.4, function() ripple:Destroy() end)
end

function Utility.UID()
    return HttpService:GenerateGUID(false)
end

function Utility.DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and Utility.DeepCopy(v) or v
    end
    return copy
end

-- ============================================================================
-- Rainbow Handler
-- ============================================================================
local Rainbow = {
    Objects = {},
    Running = false,
    Speed = 1,
    Hue = 0,
    Colors = nil
}

function Rainbow:Add(obj)
    table.insert(self.Objects, obj)
end

function Rainbow:Remove(obj)
    for i, o in ipairs(self.Objects) do
        if o == obj then table.remove(self.Objects, i) break end
    end
end

function Rainbow:SetColors(colors)
    self.Colors = colors
end

function Rainbow:Start()
    if self.Running then return end
    self.Running = true
    
    task.spawn(function()
        while self.Running do
            self.Hue = (self.Hue + 0.003 * self.Speed) % 1
            
            local color
            if self.Colors then
                local idx = math.floor(self.Hue * #self.Colors) + 1
                local nextIdx = (idx % #self.Colors) + 1
                local t = (self.Hue * #self.Colors) % 1
                color = self.Colors[idx]:Lerp(self.Colors[nextIdx], t)
            else
                color = Color3.fromHSV(self.Hue, 0.8, 1)
            end
            
            for _, obj in ipairs(self.Objects) do
                if obj and obj.Parent then
                    if obj:IsA("UIStroke") then
                        obj.Color = color
                    elseif obj:IsA("Frame") or obj:IsA("TextLabel") then
                        obj.BackgroundColor3 = color
                    end
                end
            end
            
            RunService.Heartbeat:Wait()
        end
    end)
end

function Rainbow:Stop()
    self.Running = false
end

function Rainbow:GetColor()
    if self.Colors then
        local idx = math.floor(self.Hue * #self.Colors) + 1
        local nextIdx = (idx % #self.Colors) + 1
        local t = (self.Hue * #self.Colors) % 1
        return self.Colors[idx]:Lerp(self.Colors[nextIdx], t)
    end
    return Color3.fromHSV(self.Hue, 0.8, 1)
end

-- ============================================================================
-- Config System
-- ============================================================================
local ConfigSystem = {}

function ConfigSystem:GetFolder()
    if not isfolder then return nil end
    if not isfolder(Config.ConfigFolder) then
        makefolder(Config.ConfigFolder)
    end
    return Config.ConfigFolder
end

function ConfigSystem:Save(name, data)
    local folder = self:GetFolder()
    if not folder then return false end
    writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    return true
end

function ConfigSystem:Load(name)
    local folder = self:GetFolder()
    if not folder then return nil end
    local path = folder .. "/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

function ConfigSystem:Delete(name)
    local folder = self:GetFolder()
    if not folder then return false end
    local path = folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

function ConfigSystem:List()
    local folder = self:GetFolder()
    if not folder then return {} end
    local configs = {}
    for _, file in ipairs(listfiles(folder)) do
        local name = file:match("([^/\\]+)%.json$")
        if name and name ~= "_autoload" then
            table.insert(configs, name)
        end
    end
    return configs
end

function ConfigSystem:SetAutoLoad(name)
    local folder = self:GetFolder()
    if folder then
        writefile(folder .. "/_autoload.txt", name or "")
    end
end

function ConfigSystem:GetAutoLoad()
    local folder = self:GetFolder()
    if not folder then return nil end
    local path = folder .. "/_autoload.txt"
    if isfile(path) then
        local name = readfile(path)
        return name ~= "" and name or nil
    end
    return nil
end

-- ============================================================================
-- Main Library
-- ============================================================================
function NexusUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, NexusUI)
    
    self.Name = options.Name or "NexusUI"
    self.Theme = Utility.DeepCopy(Config.Theme)
    self.Transparency = options.Transparency or Config.Transparency
    self.RainbowEnabled = options.RainbowBorder ~= false
    self.RainbowColors = options.RainbowColors or Config.RainbowColors
    self.BindKey = options.BindKey or Enum.KeyCode.RightControl
    self.MobileButton = options.MobileButton ~= false
    
    -- Apply custom theme
    if options.Theme then
        for k, v in pairs(options.Theme) do
            self.Theme[k] = v
        end
    end
    
    self.Categories = {}
    self.CurrentCategory = nil
    self.Modules = {}
    self.Elements = {}
    self.ConfigData = {}
    self.Connections = {}
    self.Visible = false
    self.SettingsOpen = false
    self.CurrentSettingsModule = nil
    
    Rainbow:SetColors(self.RainbowColors)
    
    self:Init()
    
    return self
end

function NexusUI:Init()
    -- Create ScreenGui
    self.Gui = Utility.Create("ScreenGui", {
        Name = "NexusUI_" .. Utility.UID(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
        IgnoreGuiInset = true
    })
    
    pcall(function() self.Gui.Parent = CoreGui end)
    if not self.Gui.Parent then
        self.Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self:CreateLoadingScreen()
end

-- ============================================================================
-- Loading Screen (保持原有的高级载入动画)
-- ============================================================================
function NexusUI:CreateLoadingScreen()
    local loading = Utility.Create("Frame", {
        Name = "Loading",
        Parent = self.Gui,
        BackgroundColor3 = Color3.fromRGB(8, 8, 15),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    -- Particles
    local particles = Utility.Create("Frame", {
        Parent = loading,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true
    })
    
    for i = 1, 60 do
        local p = Utility.Create("Frame", {
            Parent = particles,
            BackgroundColor3 = self.Theme.Primary,
            BackgroundTransparency = math.random(60, 90) / 100,
            Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5)),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            Rotation = math.random(0, 360),
            BorderSizePixel = 0
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = p})
        
        task.spawn(function()
            while p.Parent do
                Utility.Tween(p, {
                    Position = UDim2.new(math.random(), 0, math.random(), 0),
                    Rotation = math.random(0, 360)
                }, math.random(4, 8), Enum.EasingStyle.Sine)
                task.wait(math.random(4, 8))
            end
        end)
    end
    
    -- Center
    local center = Utility.Create("Frame", {
        Parent = loading,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 350, 0, 280)
    })
    
    -- Logo rings
    local logoHolder = Utility.Create("Frame", {
        Parent = center,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 120, 0, 120)
    })
    
    local outerRing = Utility.Create("Frame", {
        Parent = logoHolder,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 15, 1, 15)
    })
    local outerStroke = Utility.Create("UIStroke", {
        Parent = outerRing,
        Color = self.Theme.Primary,
        Thickness = 3,
        Transparency = 0.3
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = outerRing})
    Rainbow:Add(outerStroke)
    
    local innerRing = Utility.Create("Frame", {
        Parent = logoHolder,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -15, 1, -15)
    })
    Utility.Create("UIStroke", {
        Parent = innerRing,
        Color = self.Theme.Secondary,
        Thickness = 2,
        Transparency = 0.5
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = innerRing})
    
    local logoCenter = Utility.Create("Frame", {
        Parent = logoHolder,
        BackgroundColor3 = self.Theme.BackgroundDark,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 70)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = logoCenter})
    local centerStroke = Utility.Create("UIStroke", {
        Parent = logoCenter,
        Color = self.Theme.Primary,
        Thickness = 2
    })
    Rainbow:Add(centerStroke)
    
    local logoText = Utility.Create("TextLabel", {
        Parent = logoCenter,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "N",
        TextColor3 = self.Theme.Text,
        TextSize = 32
    })
    
    -- Title
    local title = Utility.Create("TextLabel", {
        Parent = center,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 135),
        Size = UDim2.new(1, 0, 0, 35),
        Font = Enum.Font.GothamBlack,
        Text = self.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 26,
        TextTransparency = 1
    })
    
    -- Subtitle
    local subtitle = Utility.Create("TextLabel", {
        Parent = center,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 168),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "VAPE STYLE • MODULAR UI",
        TextColor3 = self.Theme.TextDark,
        TextSize = 11,
        TextTransparency = 1
    })
    
    -- Loading bar
    local barBg = Utility.Create("Frame", {
        Parent = center,
        BackgroundColor3 = self.Theme.BackgroundLight,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 205),
        Size = UDim2.new(0.75, 0, 0, 6)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = barBg})
    
    local barFill = Utility.Create("Frame", {
        Parent = barBg,
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(0, 0, 1, 0)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = barFill})
    local barGradient = Utility.Create("UIGradient", {
        Parent = barFill,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Primary),
            ColorSequenceKeypoint.new(0.5, self.Theme.Secondary),
            ColorSequenceKeypoint.new(1, self.Theme.Primary)
        })
    })
    
    -- Status
    local status = Utility.Create("TextLabel", {
        Parent = center,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 220),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "Initializing...",
        TextColor3 = self.Theme.TextDark,
        TextSize = 12,
        TextTransparency = 1
    })
    
    -- Author
    local author = Utility.Create("TextLabel", {
        Parent = loading,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -15),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "Created by " .. NexusUI.Author,
        TextColor3 = self.Theme.TextDark,
        TextSize = 11,
        TextTransparency = 0.5
    })
    
    -- Animation
    task.spawn(function()
        Utility.PlaySound(Sounds.Startup, 0.6)
        
        -- Rotate rings
        task.spawn(function()
            while loading.Parent do
                Utility.Tween(outerRing, {Rotation = outerRing.Rotation + 360}, 4, Enum.EasingStyle.Linear)
                Utility.Tween(innerRing, {Rotation = innerRing.Rotation - 360}, 5, Enum.EasingStyle.Linear)
                Utility.Tween(logoCenter, {Rotation = logoCenter.Rotation + 90}, 2.5, Enum.EasingStyle.Quint)
                task.wait(4)
            end
        end)
        
        -- Gradient rotation
        task.spawn(function()
            while loading.Parent do
                Utility.Tween(barGradient, {Rotation = 360}, 1.5, Enum.EasingStyle.Linear)
                task.wait(1.5)
                barGradient.Rotation = 0
            end
        end)
        
        Rainbow:Start()
        
        task.wait(0.4)
        Utility.Tween(title, {TextTransparency = 0}, 0.4)
        Utility.PlaySound(Sounds.Whoosh, 0.3)
        
        task.wait(0.2)
        Utility.Tween(subtitle, {TextTransparency = 0.3}, 0.3)
        Utility.Tween(status, {TextTransparency = 0}, 0.3)
        
        -- Loading steps
        local steps = {
            {0.12, "Loading core systems..."},
            {0.28, "Initializing modules..."},
            {0.45, "Setting up UI framework..."},
            {0.62, "Configuring input handlers..."},
            {0.78, "Loading saved configs..."},
            {0.92, "Applying theme..."},
            {1.00, "Ready!"}
        }
        
        for _, step in ipairs(steps) do
            status.Text = step[2]
            Utility.Tween(barFill, {Size = UDim2.new(step[1], 0, 1, 0)}, 0.35)
            Utility.PlaySound(Sounds.Click, 0.15, 0.9 + step[1] * 0.3)
            task.wait(0.25)
        end
        
        task.wait(0.4)
        Utility.PlaySound(Sounds.Success, 0.5)
        
        -- Flash
        local flash = Utility.Create("Frame", {
            Parent = loading,
            BackgroundColor3 = self.Theme.Primary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 101
        })
        Utility.Tween(flash, {BackgroundTransparency = 0.4}, 0.08)
        task.wait(0.1)
        Utility.Tween(flash, {BackgroundTransparency = 1}, 0.25)
        
        task.wait(0.3)
        
        -- Fade out
        for _, child in ipairs(loading:GetDescendants()) do
            if child:IsA("Frame") then
                Utility.Tween(child, {BackgroundTransparency = 1}, 0.4)
            elseif child:IsA("TextLabel") then
                Utility.Tween(child, {TextTransparency = 1}, 0.4)
            elseif child:IsA("UIStroke") then
                Utility.Tween(child, {Transparency = 1}, 0.4)
            end
        end
        Utility.Tween(loading, {BackgroundTransparency = 1}, 0.4)
        
        task.wait(0.5)
        loading:Destroy()
        
        self:CreateMainUI()
        self:Show()
        
        -- Auto load
        local autoConfig = ConfigSystem:GetAutoLoad()
        if autoConfig then
            task.wait(0.3)
            self:LoadConfig(autoConfig)
        end
    end)
end

-- ============================================================================
-- Main UI (Vape Style)
-- ============================================================================
function NexusUI:CreateMainUI()
    -- Main Container
    self.Main = Utility.Create("Frame", {
        Name = "Main",
        Parent = self.Gui,
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = self.Transparency,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = IsMobile and UDim2.new(0.95, 0, 0.88, 0) or UDim2.new(0, 750, 0, 500),
        Visible = false,
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Main})
    
    -- Border
    self.MainStroke = Utility.Create("UIStroke", {
        Parent = self.Main,
        Color = self.Theme.Primary,
        Thickness = 2
    })
    if self.RainbowEnabled then
        Rainbow:Add(self.MainStroke)
    end
    
    -- Shadow
    Utility.Create("ImageLabel", {
        Parent = self.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 60, 1, 60),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1
    })
    
    -- ========== Title Bar ==========
    local titleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Parent = self.Main,
        BackgroundColor3 = self.Theme.BackgroundDark,
        Size = UDim2.new(1, 0, 0, 40),
        BorderSizePixel = 0
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = titleBar})
    Utility.Create("Frame", {
        Parent = titleBar,
        BackgroundColor3 = self.Theme.BackgroundDark,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BorderSizePixel = 0
    })
    
    -- Logo
    local logo = Utility.Create("Frame", {
        Parent = titleBar,
        BackgroundColor3 = self.Theme.Primary,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 28, 0, 28)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = logo})
    if self.RainbowEnabled then Rainbow:Add(logo) end
    
    Utility.Create("TextLabel", {
        Parent = logo,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "N",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 16
    })
    
    -- Title
    Utility.Create("TextLabel", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 48, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Window controls
    local controls = Utility.Create("Frame", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 26)
    })
    Utility.Create("UIListLayout", {
        Parent = controls,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    local function createControl(text, color, callback)
        local btn = Utility.Create("TextButton", {
            Parent = controls,
            BackgroundColor3 = color,
            BackgroundTransparency = 0.8,
            Size = UDim2.new(0, 26, 0, 26),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = self.Theme.Text,
            TextSize = 14,
            AutoButtonColor = false
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})
        
        btn.MouseEnter:Connect(function()
            Utility.Tween(btn, {BackgroundTransparency = 0.4}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Utility.Tween(btn, {BackgroundTransparency = 0.8}, 0.15)
        end)
        btn.MouseButton1Click:Connect(function()
            Utility.PlaySound(Sounds.Click, 0.4)
            callback()
        end)
        return btn
    end
    
    createControl("−", self.Theme.Warning, function() self:Hide() end)
    createControl("×", self.Theme.Error, function() self:Hide() end)
    
    -- Dragging
    self:SetupDrag(titleBar)
    
    -- ========== Category Sidebar ==========
    self.Sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        Parent = self.Main,
        BackgroundColor3 = self.Theme.BackgroundDark,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 8, 0, 48),
        Size = UDim2.new(0, 130, 1, -56)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Sidebar})
    
    self.CategoryList = Utility.Create("ScrollingFrame", {
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Primary,
        BorderSizePixel = 0
    })
    
    self.CategoryLayout = Utility.Create("UIListLayout", {
        Parent = self.CategoryList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    
    -- ========== Module Grid ==========
    self.ModuleContainer = Utility.Create("Frame", {
        Name = "ModuleContainer",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 148, 0, 48),
        Size = UDim2.new(1, -156, 1, -56)
    })
    
    -- ========== Settings Panel (Right Side) ==========
    self.SettingsPanel = Utility.Create("Frame", {
        Name = "SettingsPanel",
        Parent = self.Main,
        BackgroundColor3 = self.Theme.BackgroundDark,
        BackgroundTransparency = 0.1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 300, 0, 48),
        Size = UDim2.new(0, 280, 1, -56),
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.SettingsPanel})
    
    -- Settings Header
    local settingsHeader = Utility.Create("Frame", {
        Parent = self.SettingsPanel,
        BackgroundColor3 = self.Theme.BackgroundLight,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 40)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = settingsHeader})
    Utility.Create("Frame", {
        Parent = settingsHeader,
        BackgroundColor3 = self.Theme.BackgroundLight,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BorderSizePixel = 0
    })
    
    self.SettingsTitle = Utility.Create("TextLabel", {
        Parent = settingsHeader,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Module Settings",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local closeSettings = Utility.Create("TextButton", {
        Parent = settingsHeader,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = self.Theme.TextDark,
        TextSize = 20
    })
    closeSettings.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        self:CloseSettings()
    end)
    
    -- Settings Content
    self.SettingsContent = Utility.Create("ScrollingFrame", {
        Parent = self.SettingsPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 45),
        Size = UDim2.new(1, -10, 1, -50),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Primary,
        BorderSizePixel = 0
    })
    
    self.SettingsLayout = Utility.Create("UIListLayout", {
        Parent = self.SettingsContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    
    Utility.Create("UIPadding", {
        Parent = self.SettingsContent,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    
    self.SettingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.SettingsContent.CanvasSize = UDim2.new(0, 0, 0, self.SettingsLayout.AbsoluteContentSize.Y + 15)
    end)
    
    -- ========== Mobile Button ==========
    if IsMobile and self.MobileButton then
        self:CreateMobileButton()
    end
    
    -- Input handling
    self:SetupInput()
end

function NexusUI:SetupDrag(handle)
    local dragging, dragStart, startPos = false, nil, nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end

function NexusUI:CreateMobileButton()
    self.MobileBtn = Utility.Create("TextButton", {
        Name = "MobileToggle",
        Parent = self.Gui,
        BackgroundColor3 = self.Theme.Primary,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 15, 0.5, -25),
        Size = UDim2.new(0, 50, 0, 50),
        Font = Enum.Font.GothamBlack,
        Text = "N",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 22,
        AutoButtonColor = false,
        ZIndex = 50
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.MobileBtn})
    local mobileStroke = Utility.Create("UIStroke", {Parent = self.MobileBtn, Color = self.Theme.Primary, Thickness = 2})
    if self.RainbowEnabled then Rainbow:Add(mobileStroke) Rainbow:Add(self.MobileBtn) end
    
    -- Drag mobile button
    local dragging, dragStart, startPos = false, nil, nil
    self.MobileBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MobileBtn.Position
        end
    end)
    
    self.MobileBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if dragging and (input.Position - dragStart).Magnitude < 15 then
                self:Toggle()
                Utility.PlaySound(Sounds.Click, 0.4)
            end
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            self.MobileBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function NexusUI:SetupInput()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.BindKey then
            self:Toggle()
            Utility.PlaySound(Sounds.Whoosh, 0.35)
        end
    end))
end

-- ============================================================================
-- Show/Hide/Toggle
-- ============================================================================
function NexusUI:Show()
    if self.Visible then return end
    self.Visible = true
    
    self.Main.Visible = true
    self.Main.BackgroundTransparency = 1
    self.MainStroke.Transparency = 1
    self.Main.Size = IsMobile and UDim2.new(0.9, 0, 0.82, 0) or UDim2.new(0, 700, 0, 460)
    
    Utility.Tween(self.Main, {
        Size = IsMobile and UDim2.new(0.95, 0, 0.88, 0) or UDim2.new(0, 750, 0, 500),
        BackgroundTransparency = self.Transparency
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Utility.Tween(self.MainStroke, {Transparency = 0}, 0.25)
    
    if self.MobileBtn then
        Utility.Tween(self.MobileBtn, {BackgroundTransparency = 0.6}, 0.2)
    end
end

function NexusUI:Hide()
    if not self.Visible then return end
    self.Visible = false
    
    if self.SettingsOpen then
        self:CloseSettings()
    end
    
    Utility.Tween(self.Main, {
        Size = IsMobile and UDim2.new(0.9, 0, 0.82, 0) or UDim2.new(0, 700, 0, 460),
        BackgroundTransparency = 1
    }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    Utility.Tween(self.MainStroke, {Transparency = 1}, 0.2)
    
    if self.MobileBtn then
        Utility.Tween(self.MobileBtn, {BackgroundTransparency = 0.2}, 0.2)
    end
    
    task.delay(0.25, function()
        if not self.Visible then
            self.Main.Visible = false
        end
    end)
end

function NexusUI:Toggle()
    if self.Visible then self:Hide() else self:Show() end
end

-- ============================================================================
-- Settings Panel
-- ============================================================================
function NexusUI:OpenSettings(module)
    if self.SettingsOpen and self.CurrentSettingsModule == module then
        self:CloseSettings()
        return
    end
    
    self.SettingsOpen = true
    self.CurrentSettingsModule = module
    self.SettingsTitle.Text = module.Name .. " Settings"
    
    -- Clear old settings
    for _, child in ipairs(self.SettingsContent:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    -- Populate settings
    for _, element in ipairs(module.Settings) do
        element.Container.Parent = self.SettingsContent
        element.Container.Visible = true
    end
    
    -- Animate in
    self.ModuleContainer.Size = UDim2.new(1, -446, 1, -56)
    Utility.Tween(self.SettingsPanel, {Position = UDim2.new(1, -8, 0, 48)}, 0.3, Enum.EasingStyle.Quint)
    
    Utility.PlaySound(Sounds.Whoosh, 0.3)
end

function NexusUI:CloseSettings()
    if not self.SettingsOpen then return end
    self.SettingsOpen = false
    
    Utility.Tween(self.SettingsPanel, {Position = UDim2.new(1, 300, 0, 48)}, 0.25, Enum.EasingStyle.Quint)
    
    task.delay(0.25, function()
        if not self.SettingsOpen then
            self.ModuleContainer.Size = UDim2.new(1, -156, 1, -56)
            
            -- Move elements back to storage
            if self.CurrentSettingsModule then
                for _, element in ipairs(self.CurrentSettingsModule.Settings) do
                    element.Container.Parent = nil
                end
            end
            self.CurrentSettingsModule = nil
        end
    end)
end

-- ============================================================================
-- Category Creation (Tab equivalent)
-- ============================================================================
function NexusUI:CreateCategory(options)
    options = options or {}
    
    local category = {
        Name = options.Name or "Category",
        Icon = options.Icon or "◆",
        Modules = {},
        Container = nil,
        Button = nil
    }
    
    -- Category Button
    category.Button = Utility.Create("TextButton", {
        Name = category.Name,
        Parent = self.CategoryList,
        BackgroundColor3 = self.Theme.BackgroundLight,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, 0, 0, 36),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = category.Button})
    
    local btnStroke = Utility.Create("UIStroke", {
        Parent = category.Button,
        Color = self.Theme.Primary,
        Thickness = 1,
        Transparency = 1
    })
    
    -- Icon
    Utility.Create("TextLabel", {
        Parent = category.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 22, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = category.Icon,
        TextColor3 = self.Theme.TextDark,
        TextSize = 13,
        Name = "Icon"
    })
    
    -- Name
    Utility.Create("TextLabel", {
        Parent = category.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 35, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.Gotham,
        Text = category.Name,
        TextColor3 = self.Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Name = "Name"
    })
    
    -- Module Grid Container
    category.Container = Utility.Create("ScrollingFrame", {
        Name = category.Name .. "_Container",
        Parent = self.ModuleContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Primary,
        Visible = false,
        BorderSizePixel = 0
    })
    
    local grid = Utility.Create("UIGridLayout", {
        Parent = category.Container,
        CellSize = UDim2.new(0, 175, 0, 85),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left
    })
    
    Utility.Create("UIPadding", {
        Parent = category.Container,
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5)
    })
    
    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        category.Container.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 15)
    end)
    
    -- Button events
    category.Button.MouseButton1Click:Connect(function()
        self:SelectCategory(category)
        Utility.PlaySound(Sounds.Click, 0.35)
    end)
    
    category.Button.MouseEnter:Connect(function()
        if self.CurrentCategory ~= category then
            Utility.Tween(category.Button, {BackgroundTransparency = 0.4}, 0.15)
            Utility.Tween(btnStroke, {Transparency = 0.7}, 0.15)
        end
        Utility.PlaySound(Sounds.Hover, 0.15)
    end)
    
    category.Button.MouseLeave:Connect(function()
        if self.CurrentCategory ~= category then
            Utility.Tween(category.Button, {BackgroundTransparency = 0.7}, 0.15)
            Utility.Tween(btnStroke, {Transparency = 1}, 0.15)
        end
    end)
    
    -- Update canvas
    self.CategoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.CategoryList.CanvasSize = UDim2.new(0, 0, 0, self.CategoryLayout.AbsoluteContentSize.Y + 10)
    end)
    
    table.insert(self.Categories, category)
    
    -- Select first category
    if #self.Categories == 1 then
        self:SelectCategory(category)
    end
    
    -- Return category with module creation methods
    local categoryObj = setmetatable({}, {__index = self})
    categoryObj._category = category
    
    function categoryObj:AddModule(opts)
        return NexusUI.CreateModule(self, category, opts)
    end
    
    return categoryObj
end

-- Alias for compatibility
NexusUI.CreateTab = NexusUI.CreateCategory

function NexusUI:SelectCategory(category)
    if self.CurrentCategory == category then return end
    
    -- Close settings when switching
    if self.SettingsOpen then
        self:CloseSettings()
    end
    
    -- Deselect old
    if self.CurrentCategory then
        self.CurrentCategory.Container.Visible = false
        local btn = self.CurrentCategory.Button
        Utility.Tween(btn, {BackgroundTransparency = 0.7}, 0.2)
        Utility.Tween(btn:FindFirstChild("Icon"), {TextColor3 = self.Theme.TextDark}, 0.2)
        Utility.Tween(btn:FindFirstChild("Name"), {TextColor3 = self.Theme.TextDark}, 0.2)
    end
    
    -- Select new
    self.CurrentCategory = category
    category.Container.Visible = true
    
    local btn = category.Button
    Utility.Tween(btn, {BackgroundTransparency = 0.3}, 0.2)
    Utility.Tween(btn:FindFirstChild("Icon"), {TextColor3 = self.Theme.Primary}, 0.2)
    Utility.Tween(btn:FindFirstChild("Name"), {TextColor3 = self.Theme.Text}, 0.2)
end

-- ============================================================================
-- Module Creation (Vape-style module cards)
-- ============================================================================
function NexusUI.CreateModule(ui, category, options)
    options = options or {}
    
    local module = {
        Name = options.Name or "Module",
        Description = options.Description or "",
        Enabled = options.Default or false,
        Keybind = options.Keybind,
        Settings = {},
        OnEnabled = options.OnEnabled,
        OnDisabled = options.OnDisabled,
        Flag = options.Flag
    }
    
    -- Module Card
    module.Card = Utility.Create("Frame", {
        Name = module.Name,
        Parent = category.Container,
        BackgroundColor3 = module.Enabled and ui.Theme.ModuleEnabled or ui.Theme.ModuleDisabled,
        Size = UDim2.new(0, 175, 0, 85),
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = module.Card})
    
    local cardStroke = Utility.Create("UIStroke", {
        Parent = module.Card,
        Color = module.Enabled and ui.Theme.Primary or ui.Theme.BackgroundLight,
        Thickness = 1.5,
        Transparency = module.Enabled and 0 or 0.5
    })
    
    -- Enabled indicator bar
    local indicator = Utility.Create("Frame", {
        Parent = module.Card,
        BackgroundColor3 = ui.Theme.Primary,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(module.Enabled and 1 or 0, 0, 0, 3)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = indicator})
    if ui.RainbowEnabled and module.Enabled then Rainbow:Add(indicator) end
    
    -- Module name
    local nameLabel = Utility.Create("TextLabel", {
        Parent = module.Card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 12),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = module.Name,
        TextColor3 = module.Enabled and ui.Theme.Text or ui.Theme.TextDark,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    -- Description
    local descLabel = Utility.Create("TextLabel", {
        Parent = module.Card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 32),
        Size = UDim2.new(1, -20, 0, 28),
        Font = Enum.Font.Gotham,
        Text = module.Description,
        TextColor3 = ui.Theme.TextDisabled,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    -- Bottom bar
    local bottomBar = Utility.Create("Frame", {
        Parent = module.Card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -25),
        Size = UDim2.new(1, 0, 0, 25)
    })
    
    -- Settings button
    local settingsBtn = Utility.Create("TextButton", {
        Parent = bottomBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 25, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "⚙",
        TextColor3 = ui.Theme.TextDisabled,
        TextSize = 14
    })
    
    -- Keybind display
    local keybindLabel = Utility.Create("TextLabel", {
        Parent = bottomBar,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 50, 1, 0),
        Font = Enum.Font.Gotham,
        Text = module.Keybind and ("[" .. module.Keybind.Name .. "]") or "",
        TextColor3 = ui.Theme.TextDisabled,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    -- Toggle button (invisible overlay)
    local toggleBtn = Utility.Create("TextButton", {
        Parent = module.Card,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -25),
        Text = "",
        ZIndex = 2
    })
    
    -- Toggle function
    local function setEnabled(value, skipCallback)
        module.Enabled = value
        
        if value then
            Utility.Tween(module.Card, {BackgroundColor3 = ui.Theme.ModuleEnabled}, 0.2)
            Utility.Tween(cardStroke, {Color = ui.Theme.Primary, Transparency = 0}, 0.2)
            Utility.Tween(indicator, {Size = UDim2.new(1, 0, 0, 3)}, 0.25)
            Utility.Tween(nameLabel, {TextColor3 = ui.Theme.Text}, 0.2)
            if ui.RainbowEnabled then Rainbow:Add(indicator) end
            
            if not skipCallback and module.OnEnabled then
                module.OnEnabled()
            end
        else
            Utility.Tween(module.Card, {BackgroundColor3 = ui.Theme.ModuleDisabled}, 0.2)
            Utility.Tween(cardStroke, {Color = ui.Theme.BackgroundLight, Transparency = 0.5}, 0.2)
            Utility.Tween(indicator, {Size = UDim2.new(0, 0, 0, 3)}, 0.2)
            Utility.Tween(nameLabel, {TextColor3 = ui.Theme.TextDark}, 0.2)
            Rainbow:Remove(indicator)
            
            if not skipCallback and module.OnDisabled then
                module.OnDisabled()
            end
        end
        
        if module.Flag then
            ui.ConfigData[module.Flag] = value
        end
    end
    
    -- Initialize if default enabled
    if module.Enabled then
        indicator.Size = UDim2.new(1, 0, 0, 3)
        cardStroke.Color = ui.Theme.Primary
        cardStroke.Transparency = 0
        nameLabel.TextColor3 = ui.Theme.Text
        if ui.RainbowEnabled then Rainbow:Add(indicator) end
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Toggle, 0.4)
        setEnabled(not module.Enabled)
    end)
    
    toggleBtn.MouseEnter:Connect(function()
        Utility.Tween(module.Card, {BackgroundColor3 = (module.Enabled and ui.Theme.ModuleEnabled or ui.Theme.ModuleDisabled):Lerp(Color3.new(1,1,1), 0.08)}, 0.15)
    end)
    
    toggleBtn.MouseLeave:Connect(function()
        Utility.Tween(module.Card, {BackgroundColor3 = module.Enabled and ui.Theme.ModuleEnabled or ui.Theme.ModuleDisabled}, 0.15)
    end)
    
    settingsBtn.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.35)
        ui:OpenSettings(module)
    end)
    
    settingsBtn.MouseEnter:Connect(function()
        Utility.Tween(settingsBtn, {TextColor3 = ui.Theme.Primary}, 0.15)
    end)
    
    settingsBtn.MouseLeave:Connect(function()
        Utility.Tween(settingsBtn, {TextColor3 = ui.Theme.TextDisabled}, 0.15)
    end)
    
    -- Keybind handling
    if module.Keybind then
        table.insert(ui.Connections, UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == module.Keybind then
                Utility.PlaySound(Sounds.Toggle, 0.3)
                setEnabled(not module.Enabled)
            end
        end))
    end
    
    table.insert(category.Modules, module)
    table.insert(ui.Modules, module)
    
    -- Module object with setting methods
    local moduleObj = {
        _module = module,
        _ui = ui
    }
    
    function moduleObj:Set(value)
        setEnabled(value)
    end
    
    function moduleObj:Get()
        return module.Enabled
    end
    
    function moduleObj:SetKeybind(key)
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        module.Keybind = key
        keybindLabel.Text = key and ("[" .. key.Name .. "]") or ""
    end
    
    -- Setting creation methods
    function moduleObj:AddToggle(opts)
        return NexusUI.CreateSettingToggle(ui, module, opts)
    end
    
    function moduleObj:AddSlider(opts)
        return NexusUI.CreateSettingSlider(ui, module, opts)
    end
    
    function moduleObj:AddDropdown(opts)
        return NexusUI.CreateSettingDropdown(ui, module, opts)
    end
    
    function moduleObj:AddColorPicker(opts)
        return NexusUI.CreateSettingColorPicker(ui, module, opts)
    end
    
    function moduleObj:AddTextbox(opts)
        return NexusUI.CreateSettingTextbox(ui, module, opts)
    end
    
    function moduleObj:AddKeybind(opts)
        return NexusUI.CreateSettingKeybind(ui, module, opts)
    end
    
    function moduleObj:AddButton(opts)
        return NexusUI.CreateSettingButton(ui, module, opts)
    end
    
    function moduleObj:AddLabel(opts)
        return NexusUI.CreateSettingLabel(ui, module, opts)
    end
    
    function moduleObj:AddDivider(opts)
        return NexusUI.CreateSettingDivider(ui, module, opts)
    end
    
    if module.Flag then
        ui.Elements[module.Flag] = moduleObj
    end
    
    return moduleObj
end

-- ============================================================================
-- Setting Elements (for module settings panel)
-- ============================================================================

-- Toggle Setting
function NexusUI.CreateSettingToggle(ui, module, options)
    options = options or {}
    local value = options.Default or false
    local flag = options.Flag
    
    local container = Utility.Create("Frame", {
        Name = "Toggle_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local title = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Toggle",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleBox = Utility.Create("Frame", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 20)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBox})
    local toggleStroke = Utility.Create("UIStroke", {Parent = toggleBox, Color = ui.Theme.TextDark, Thickness = 1, Transparency = 0.5})
    
    local toggleKnob = Utility.Create("Frame", {
        Parent = toggleBox,
        BackgroundColor3 = ui.Theme.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleKnob})
    
    local function update(val, skip)
        value = val
        if value then
            Utility.Tween(toggleKnob, {Position = UDim2.new(1, -17, 0.5, 0), BackgroundColor3 = ui.Theme.Primary}, 0.2)
            Utility.Tween(toggleStroke, {Color = ui.Theme.Primary}, 0.2)
            Utility.Tween(toggleBox, {BackgroundColor3 = ui.Theme.Primary:Lerp(ui.Theme.BackgroundDark, 0.6)}, 0.2)
        else
            Utility.Tween(toggleKnob, {Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = ui.Theme.TextDark}, 0.2)
            Utility.Tween(toggleStroke, {Color = ui.Theme.TextDark}, 0.2)
            Utility.Tween(toggleBox, {BackgroundColor3 = ui.Theme.BackgroundDark}, 0.2)
        end
        
        if flag then ui.ConfigData[flag] = value end
        if not skip and options.Callback then options.Callback(value) end
    end
    
    if value then update(true, true) end
    
    local btn = Utility.Create("TextButton", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    btn.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Toggle, 0.35)
        update(not value)
    end)
    
    local setting = {Container = container, Type = "Toggle"}
    function setting:Set(v) update(v) end
    function setting:Get() return value end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- Slider Setting
function NexusUI.CreateSettingSlider(ui, module, options)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    local value = math.clamp(options.Default or min, min, max)
    local increment = options.Increment or 1
    local suffix = options.Suffix or ""
    local flag = options.Flag
    
    local container = Utility.Create("Frame", {
        Name = "Slider_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 50),
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local title = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0.6, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Slider",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 5),
        Size = UDim2.new(0.4, -10, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = tostring(value) .. suffix,
        TextColor3 = ui.Theme.Primary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local barBg = Utility.Create("Frame", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 10)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = barBg})
    
    local barFill = Utility.Create("Frame", {
        Parent = barBg,
        BackgroundColor3 = ui.Theme.Primary,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = barFill})
    Utility.Create("UIGradient", {
        Parent = barFill,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ui.Theme.Primary),
            ColorSequenceKeypoint.new(1, ui.Theme.Secondary)
        })
    })
    
    local knob = Utility.Create("Frame", {
        Parent = barFill,
        BackgroundColor3 = ui.Theme.Text,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})
    Utility.Create("UIStroke", {Parent = knob, Color = ui.Theme.Primary, Thickness = 2})
    
    local function update(val, skip)
        val = math.clamp(val, min, max)
        val = math.floor(val / increment + 0.5) * increment
        value = val
        
        valueLabel.Text = tostring(value) .. suffix
        local pct = (value - min) / (max - min)
        Utility.Tween(barFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.08)
        
        if flag then ui.ConfigData[flag] = value end
        if not skip and options.Callback then options.Callback(value) end
    end
    
    local dragging = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * pct)
        end
    end)
    barBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    table.insert(ui.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * pct)
        end
    end))
    
    local setting = {Container = container, Type = "Slider"}
    function setting:Set(v) update(v) end
    function setting:Get() return value end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- Dropdown Setting
function NexusUI.CreateSettingDropdown(ui, module, options)
    options = options or {}
    local items = options.Items or {}
    local multi = options.Multi or false
    local selected = multi and {} or nil
    local flag = options.Flag
    local open = false
    
    if options.Default then
        if multi then
            for _, item in ipairs(options.Default) do
                selected[item] = true
            end
        else
            selected = options.Default
        end
    end
    
    local container = Utility.Create("Frame", {
        Name = "Dropdown_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        ClipsDescendants = true,
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local header = Utility.Create("TextButton", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Text = "",
        AutoButtonColor = false
    })
    
    local title = Utility.Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.45, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Dropdown",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local function getDisplayText()
        if multi then
            local list = {}
            for item, enabled in pairs(selected) do
                if enabled then table.insert(list, item) end
            end
            return #list > 0 and table.concat(list, ", ") or "None"
        end
        return selected or "Select..."
    end
    
    local selectedLabel = Utility.Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.45, 0, 0, 0),
        Size = UDim2.new(0.55, -30, 1, 0),
        Font = Enum.Font.Gotham,
        Text = getDisplayText(),
        TextColor3 = ui.Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    local arrow = Utility.Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = ui.Theme.Primary,
        TextSize = 10
    })
    
    local listFrame = Utility.Create("Frame", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 5, 0, 40),
        Size = UDim2.new(1, -10, 0, 0),
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = listFrame})
    
    local listLayout = Utility.Create("UIListLayout", {
        Parent = listFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    Utility.Create("UIPadding", {
        Parent = listFrame,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    
    local function createItem(name)
        local item = Utility.Create("TextButton", {
            Name = name,
            Parent = listFrame,
            BackgroundColor3 = ui.Theme.BackgroundLight,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.Gotham,
            Text = "  " .. name,
            TextColor3 = ui.Theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = item})
        
        if multi then
            local check = Utility.Create("TextLabel", {
                Parent = item,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
                Font = Enum.Font.GothamBold,
                Text = selected[name] and "✓" or "",
                TextColor3 = ui.Theme.Primary,
                TextSize = 12
            })
            
            if selected[name] then
                item.BackgroundColor3 = ui.Theme.Primary:Lerp(ui.Theme.BackgroundLight, 0.7)
            end
            
            item.MouseButton1Click:Connect(function()
                selected[name] = not selected[name]
                check.Text = selected[name] and "✓" or ""
                Utility.Tween(item, {BackgroundColor3 = selected[name] and ui.Theme.Primary:Lerp(ui.Theme.BackgroundLight, 0.7) or ui.Theme.BackgroundLight}, 0.15)
                selectedLabel.Text = getDisplayText()
                Utility.PlaySound(Sounds.Click, 0.25)
                
                if flag then
                    local list = {}
                    for k, v in pairs(selected) do if v then table.insert(list, k) end end
                    ui.ConfigData[flag] = list
                end
                if options.Callback then options.Callback(selected) end
            end)
        else
            item.MouseButton1Click:Connect(function()
                selected = name
                selectedLabel.Text = getDisplayText()
                Utility.PlaySound(Sounds.Click, 0.25)
                
                -- Close dropdown
                open = false
                Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 36)}, 0.25)
                Utility.Tween(arrow, {Rotation = 0}, 0.25)
                
                if flag then ui.ConfigData[flag] = selected end
                if options.Callback then options.Callback(selected) end
            end)
        end
        
        item.MouseEnter:Connect(function()
            Utility.Tween(item, {BackgroundTransparency = 0.2}, 0.12)
        end)
        item.MouseLeave:Connect(function()
            Utility.Tween(item, {BackgroundTransparency = 0.5}, 0.12)
        end)
        
        return item
    end
    
    for _, name in ipairs(items) do
        createItem(name)
    end
    
    header.MouseButton1Click:Connect(function()
        open = not open
        Utility.PlaySound(Sounds.Click, 0.3)
        
        if open then
            local height = math.min(#items * 30 + 10, 140)
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 36 + height + 8)}, 0.25)
            Utility.Tween(listFrame, {Size = UDim2.new(1, -10, 0, height)}, 0.25)
            Utility.Tween(arrow, {Rotation = 180}, 0.25)
        else
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
            Utility.Tween(listFrame, {Size = UDim2.new(1, -10, 0, 0)}, 0.2)
            Utility.Tween(arrow, {Rotation = 0}, 0.2)
        end
    end)
    
    local setting = {Container = container, Type = "Dropdown"}
    
    function setting:Set(val)
        if multi then
            selected = {}
            for _, item in ipairs(val) do selected[item] = true end
        else
            selected = val
        end
        selectedLabel.Text = getDisplayText()
        if options.Callback then options.Callback(selected) end
    end
    
    function setting:Get()
        if multi then
            local list = {}
            for k, v in pairs(selected) do if v then table.insert(list, k) end end
            return list
        end
        return selected
    end
    
    function setting:Refresh(newItems)
        items = newItems
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, name in ipairs(items) do createItem(name) end
    end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- ColorPicker Setting (Circular)
function NexusUI.CreateSettingColorPicker(ui, module, options)
    options = options or {}
    local currentColor = options.Default or Color3.fromRGB(255, 255, 255)
    local presets = options.Presets or {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255)
    }
    local flag = options.Flag
    local open = false
    local h, s, v = Color3.toHSV(currentColor)
    
    local container = Utility.Create("Frame", {
        Name = "ColorPicker_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        ClipsDescendants = true,
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local header = Utility.Create("TextButton", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Text = "",
        AutoButtonColor = false
    })
    
    local title = Utility.Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Color",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local preview = Utility.Create("Frame", {
        Parent = header,
        BackgroundColor3 = currentColor,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 22)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = preview})
    Utility.Create("UIStroke", {Parent = preview, Color = ui.Theme.Text, Thickness = 1, Transparency = 0.6})
    
    -- Picker Panel
    local pickerPanel = Utility.Create("Frame", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 5, 0, 40),
        Size = UDim2.new(1, -10, 0, 0),
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = pickerPanel})
    
    -- Color Wheel
    local wheelHolder = Utility.Create("Frame", {
        Parent = pickerPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 120, 0, 120)
    })
    
    local wheel = Utility.Create("ImageLabel", {
        Parent = wheelHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385"
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = wheel})
    
    local wheelSelector = Utility.Create("Frame", {
        Parent = wheel,
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 5
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = wheelSelector})
    Utility.Create("UIStroke", {Parent = wheelSelector, Color = Color3.new(0, 0, 0), Thickness = 2})
    
    -- Value Slider
    local valueBar = Utility.Create("Frame", {
        Parent = pickerPanel,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, 140, 0, 10),
        Size = UDim2.new(0, 18, 0, 120)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = valueBar})
    local valueGradient = Utility.Create("UIGradient", {
        Parent = valueBar,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
        }),
        Rotation = 90
    })
    
    local valueSelector = Utility.Create("Frame", {
        Parent = valueBar,
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1 - v, 0),
        Size = UDim2.new(1, 4, 0, 5),
        ZIndex = 5
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = valueSelector})
    Utility.Create("UIStroke", {Parent = valueSelector, Color = Color3.new(0, 0, 0), Thickness = 1})
    
    -- Presets
    local presetHolder = Utility.Create("Frame", {
        Parent = pickerPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 140),
        Size = UDim2.new(1, -20, 0, 22)
    })
    Utility.Create("UIListLayout", {
        Parent = presetHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    
    -- Hex Input
    local hexHolder = Utility.Create("Frame", {
        Parent = pickerPanel,
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 10, 0, 170),
        Size = UDim2.new(1, -20, 0, 28)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = hexHolder})
    
    Utility.Create("TextLabel", {
        Parent = hexHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 35, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "HEX:",
        TextColor3 = ui.Theme.TextDark,
        TextSize = 11
    })
    
    local hexInput = Utility.Create("TextBox", {
        Parent = hexHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "#FFFFFF",
        TextColor3 = ui.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    local function updateColor(color, skipCallback)
        currentColor = color
        h, s, v = Color3.toHSV(color)
        
        preview.BackgroundColor3 = color
        
        local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
        hexInput.Text = string.format("#%02X%02X%02X", r, g, b)
        
        local angle = h * math.pi * 2
        local radius = s * 0.45
        wheelSelector.Position = UDim2.new(0.5 + math.cos(angle) * radius, 0, 0.5 + math.sin(angle) * radius, 0)
        
        valueSelector.Position = UDim2.new(0.5, 0, 1 - v, 0)
        valueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
        })
        
        if flag then
            ui.ConfigData[flag] = {R = color.R, G = color.G, B = color.B}
        end
        
        if not skipCallback and options.Callback then
            options.Callback(color)
        end
    end
    
    -- Wheel dragging
    local wheelDrag = false
    wheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDrag = true
            local cx = wheel.AbsolutePosition.X + wheel.AbsoluteSize.X / 2
            local cy = wheel.AbsolutePosition.Y + wheel.AbsoluteSize.Y / 2
            local radius = wheel.AbsoluteSize.X / 2
            local dx = input.Position.X - cx
            local dy = input.Position.Y - cy
            local dist = math.sqrt(dx * dx + dy * dy)
            
            h = (math.atan2(dy, dx) / (math.pi * 2) + 0.5) % 1
            s = math.min(dist / radius, 1)
            updateColor(Color3.fromHSV(h, s, v))
        end
    end)
    wheel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDrag = false
        end
    end)
    
    -- Value bar dragging
    local valueDrag = false
    valueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDrag = true
            local pct = math.clamp((input.Position.Y - valueBar.AbsolutePosition.Y) / valueBar.AbsoluteSize.Y, 0, 1)
            v = 1 - pct
            updateColor(Color3.fromHSV(h, s, v))
        end
    end)
    valueBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDrag = false
        end
    end)
    
    table.insert(ui.Connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if wheelDrag then
                local cx = wheel.AbsolutePosition.X + wheel.AbsoluteSize.X / 2
                local cy = wheel.AbsolutePosition.Y + wheel.AbsoluteSize.Y / 2
                local radius = wheel.AbsoluteSize.X / 2
                local dx = input.Position.X - cx
                local dy = input.Position.Y - cy
                local dist = math.sqrt(dx * dx + dy * dy)
                
                h = (math.atan2(dy, dx) / (math.pi * 2) + 0.5) % 1
                s = math.min(dist / radius, 1)
                updateColor(Color3.fromHSV(h, s, v))
            elseif valueDrag then
                local pct = math.clamp((input.Position.Y - valueBar.AbsolutePosition.Y) / valueBar.AbsoluteSize.Y, 0, 1)
                v = 1 - pct
                updateColor(Color3.fromHSV(h, s, v))
            end
        end
    end))
    
    -- Presets
    for i, color in ipairs(presets) do
        local presetBtn = Utility.Create("TextButton", {
            Parent = presetHolder,
            BackgroundColor3 = color,
            Size = UDim2.new(0, 20, 0, 20),
            Text = "",
            AutoButtonColor = false
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = presetBtn})
        local presetStroke = Utility.Create("UIStroke", {Parent = presetBtn, Color = ui.Theme.Text, Thickness = 1, Transparency = 0.7})
        
        presetBtn.MouseButton1Click:Connect(function()
            updateColor(color)
            Utility.PlaySound(Sounds.Click, 0.25)
        end)
        presetBtn.MouseEnter:Connect(function()
            Utility.Tween(presetStroke, {Transparency = 0}, 0.12)
        end)
        presetBtn.MouseLeave:Connect(function()
            Utility.Tween(presetStroke, {Transparency = 0.7}, 0.12)
        end)
    end
    
    -- Hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            if r and g and b then
                updateColor(Color3.fromRGB(r, g, b))
            end
        end
    end)
    
    header.MouseButton1Click:Connect(function()
        open = not open
        Utility.PlaySound(Sounds.Click, 0.3)
        
        if open then
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 250)}, 0.25)
            Utility.Tween(pickerPanel, {Size = UDim2.new(1, -10, 0, 205)}, 0.25)
        else
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
            Utility.Tween(pickerPanel, {Size = UDim2.new(1, -10, 0, 0)}, 0.2)
        end
    end)
    
    -- Initialize
    updateColor(currentColor, true)
    
    local setting = {Container = container, Type = "ColorPicker"}
    function setting:Set(color) updateColor(color) end
    function setting:Get() return currentColor end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- Textbox Setting
function NexusUI.CreateSettingTextbox(ui, module, options)
    options = options or {}
    local value = options.Default or ""
    local flag = options.Flag
    
    local container = Utility.Create("Frame", {
        Name = "Textbox_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local title = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Input",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local inputBox = Utility.Create("TextBox", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.55, -10, 0, 24),
        Font = Enum.Font.Gotham,
        PlaceholderText = options.Placeholder or "Enter...",
        PlaceholderColor3 = ui.Theme.TextDisabled,
        Text = value,
        TextColor3 = ui.Theme.Text,
        TextSize = 11,
        ClearTextOnFocus = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = inputBox})
    local inputStroke = Utility.Create("UIStroke", {Parent = inputBox, Color = ui.Theme.Primary, Thickness = 1, Transparency = 0.7})
    
    inputBox.Focused:Connect(function()
        Utility.Tween(inputStroke, {Transparency = 0}, 0.15)
        Utility.PlaySound(Sounds.Click, 0.25)
    end)
    
    inputBox.FocusLost:Connect(function(enter)
        Utility.Tween(inputStroke, {Transparency = 0.7}, 0.15)
        value = inputBox.Text
        if flag then ui.ConfigData[flag] = value end
        if options.Callback then options.Callback(value, enter) end
    end)
    
    local setting = {Container = container, Type = "Textbox"}
    function setting:Set(v) inputBox.Text = v; value = v end
    function setting:Get() return value end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- Keybind Setting
function NexusUI.CreateSettingKeybind(ui, module, options)
    options = options or {}
    local key = options.Default or Enum.KeyCode.Unknown
    local flag = options.Flag
    local listening = false
    
    local container = Utility.Create("Frame", {
        Name = "Keybind_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local title = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Keybind",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local keyBtn = Utility.Create("TextButton", {
        Parent = container,
        BackgroundColor3 = ui.Theme.BackgroundDark,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 24),
        Font = Enum.Font.Gotham,
        Text = key.Name,
        TextColor3 = ui.Theme.Primary,
        TextSize = 11,
        AutoButtonColor = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = keyBtn})
    local keyStroke = Utility.Create("UIStroke", {Parent = keyBtn, Color = ui.Theme.Primary, Thickness = 1, Transparency = 0.7})
    
    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        Utility.Tween(keyStroke, {Transparency = 0}, 0.15)
        Utility.PlaySound(Sounds.Click, 0.3)
    end)
    
    table.insert(ui.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            keyBtn.Text = key.Name
            listening = false
            Utility.Tween(keyStroke, {Transparency = 0.7}, 0.15)
            Utility.PlaySound(Sounds.Success, 0.35)
            
            if flag then ui.ConfigData[flag] = key.Name end
            if options.Callback then options.Callback(key) end
        elseif not processed and input.KeyCode == key then
            if options.OnActivate then options.OnActivate() end
        end
    end))
    
    local setting = {Container = container, Type = "Keybind"}
    function setting:Set(k)
        if type(k) == "string" then k = Enum.KeyCode[k] end
        key = k
        keyBtn.Text = key.Name
    end
    function setting:Get() return key end
    
    table.insert(module.Settings, setting)
    if flag then ui.Elements[flag] = setting end
    
    return setting
end

-- Button Setting
function NexusUI.CreateSettingButton(ui, module, options)
    options = options or {}
    
    local container = Utility.Create("Frame", {
        Name = "Button_" .. (options.Name or ""),
        BackgroundColor3 = ui.Theme.BackgroundLight,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 36),
        Visible = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
    
    local btn = Utility.Create("TextButton", {
        Parent = container,
        BackgroundColor3 = ui.Theme.Primary,
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0, 8, 0, 5),
        Size = UDim2.new(1, -16, 1, -10),
        Font = Enum.Font.GothamBold,
        Text = options.Name or "Button",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        AutoButtonColor = false
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = btn})
    
    btn.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.4)
        Utility.Ripple(btn, Mouse.X, Mouse.Y)
        
        Utility.Tween(btn, {BackgroundTransparency = 0.3}, 0.1)
        task.delay(0.12, function()
            Utility.Tween(btn, {BackgroundTransparency = 0.7}, 0.15)
        end)
        
        if options.Callback then options.Callback() end
    end)
    
    btn.MouseEnter:Connect(function()
        Utility.Tween(btn, {BackgroundTransparency = 0.5}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Utility.Tween(btn, {BackgroundTransparency = 0.7}, 0.12)
    end)
    
    local setting = {Container = container, Type = "Button"}
    table.insert(module.Settings, setting)
    
    return setting
end

-- Label Setting
function NexusUI.CreateSettingLabel(ui, module, options)
    options = options or {}
    
    local container = Utility.Create("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Visible = false
    })
    
    local label = Utility.Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Text or "Label",
        TextColor3 = ui.Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local setting = {Container = container, Type = "Label"}
    function setting:Set(text) label.Text = text end
    
    table.insert(module.Settings, setting)
    return setting
end

-- Divider Setting
function NexusUI.CreateSettingDivider(ui, module, options)
    options = options or {}
    
    local container = Utility.Create("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        Visible = false
    })
    
    local line = Utility.Create("Frame", {
        Parent = container,
        BackgroundColor3 = ui.Theme.Primary,
        BackgroundTransparency = 0.6,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -20, 0, 1)
    })
    
    if options.Text then
        local divLabel = Utility.Create("TextLabel", {
            Parent = container,
            BackgroundColor3 = ui.Theme.BackgroundDark,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 80, 0, 18),
            Font = Enum.Font.GothamBold,
            Text = options.Text,
            TextColor3 = ui.Theme.Primary,
            TextSize = 10
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = divLabel})
    end
    
    local setting = {Container = container, Type = "Divider"}
    table.insert(module.Settings, setting)
    return setting
end

-- ============================================================================
-- Notification System
-- ============================================================================
function NexusUI:Notify(options)
    options = options or {}
    
    local notifHolder = self.Gui:FindFirstChild("NotifHolder")
    if not notifHolder then
        notifHolder = Utility.Create("Frame", {
            Name = "NotifHolder",
            Parent = self.Gui,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -15, 1, -15),
            Size = UDim2.new(0, 280, 0, 400)
        })
        Utility.Create("UIListLayout", {
            Parent = notifHolder,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8)
        })
    end
    
    local colors = {
        Success = self.Theme.Success,
        Error = self.Theme.Error,
        Warning = self.Theme.Warning,
        Info = self.Theme.Primary
    }
    local icons = {Success = "✓", Error = "✕", Warning = "⚠", Info = "ℹ"}
    local color = colors[options.Type] or self.Theme.Primary
    local icon = icons[options.Type] or "ℹ"
    
    local notif = Utility.Create("Frame", {
        Parent = notifHolder,
        BackgroundColor3 = self.Theme.BackgroundDark,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = notif})
    Utility.Create("UIStroke", {Parent = notif, Color = color, Thickness = 1.5, Transparency = 0.3})
    
    -- Accent bar
    local accent = Utility.Create("Frame", {
        Parent = notif,
        BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, 0)
    })
    Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = accent})
    
    -- Icon
    Utility.Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(0, 22, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = color,
        TextSize = 16
    })
    
    -- Title
    Utility.Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 10),
        Size = UDim2.new(1, -52, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = options.Title or "Notification",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Content
    Utility.Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 30),
        Size = UDim2.new(1, -52, 0, 28),
        Font = Enum.Font.Gotham,
        Text = options.Content or "",
        TextColor3 = self.Theme.TextDark,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    -- Progress
    local progress = Utility.Create("Frame", {
        Parent = notif,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2)
    })
    
    -- Animate in
    Utility.PlaySound(Sounds.Notification, 0.45)
    Utility.Tween(notif, {Size = UDim2.new(1, 0, 0, 65)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    local duration = options.Duration or 4
    Utility.Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration)
    
    task.delay(duration, function()
        Utility.Tween(notif, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.25)
        task.wait(0.25)
        notif:Destroy()
    end)
end

-- ============================================================================
-- Flash Screen Effect
-- ============================================================================
function NexusUI:FlashScreen(color)
    local flash = Utility.Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = color or self.Theme.Primary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 99
    })
    
    Utility.PlaySound(Sounds.Whoosh, 0.5, 1.1)
    Utility.Tween(flash, {BackgroundTransparency = 0.35}, 0.08)
    task.wait(0.12)
    Utility.Tween(flash, {BackgroundTransparency = 1}, 0.25)
    task.wait(0.25)
    flash:Destroy()
end

-- ============================================================================
-- Config System Integration
-- ============================================================================
function NexusUI:SaveConfig(name)
    if ConfigSystem:Save(name, self.ConfigData) then
        Utility.PlaySound(Sounds.Success, 0.5)
        return true
    end
    return false
end

function NexusUI:LoadConfig(name)
    local data = ConfigSystem:Load(name)
    if data then
        self:FlashScreen(self.Theme.Primary)
        Utility.PlaySound(Sounds.Success, 0.5, 1.15)
        
        for flag, value in pairs(data) do
            local element = self.Elements[flag]
            if element and element.Set then
                if type(value) == "table" and value.R then
                    element:Set(Color3.new(value.R, value.G, value.B))
                else
                    element:Set(value)
                end
            end
        end
        
        self:Notify({
            Title = "Config Loaded",
            Content = "'" .. name .. "' has been loaded!",
            Duration = 3,
            Type = "Success"
        })
        return true
    end
    return false
end

function NexusUI:DeleteConfig(name)
    return ConfigSystem:Delete(name)
end

function NexusUI:GetConfigs()
    return ConfigSystem:List()
end

function NexusUI:SetAutoLoad(name)
    ConfigSystem:SetAutoLoad(name)
end

-- ============================================================================
-- Settings Tab (Built-in)
-- ============================================================================
function NexusUI:CreateSettingsTab()
    local settingsCategory = self:CreateCategory({
        Name = "Settings",
        Icon = "⚙"
    })
    
    -- Config Module
    local configModule = settingsCategory:AddModule({
        Name = "Configurations",
        Description = "Save & load settings",
        Default = true
    })
    
    local configNameInput = configModule:AddTextbox({
        Name = "Config Name",
        Placeholder = "Enter name...",
        Flag = "_ConfigName"
    })
    
    local configList = configModule:AddDropdown({
        Name = "Saved Configs",
        Items = self:GetConfigs(),
        Flag = "_ConfigSelect"
    })
    
    configModule:AddButton({
        Name = "💾 Save Config",
        Callback = function()
            local name = configNameInput:Get()
            if name and name ~= "" then
                if self:SaveConfig(name) then
                    configList:Refresh(self:GetConfigs())
                    self:Notify({Title = "Saved", Content = "Config '" .. name .. "' saved!", Duration = 3, Type = "Success"})
                end
            else
                self:Notify({Title = "Error", Content = "Enter a config name!", Duration = 3, Type = "Error"})
            end
        end
    })
    
    configModule:AddButton({
        Name = "📂 Load Config",
        Callback = function()
            local name = configList:Get()
            if name then
                self:LoadConfig(name)
            else
                self:Notify({Title = "Error", Content = "Select a config!", Duration = 3, Type = "Error"})
            end
        end
    })
    
    configModule:AddButton({
        Name = "🗑️ Delete Config",
        Callback = function()
            local name = configList:Get()
            if name then
                self:DeleteConfig(name)
                configList:Refresh(self:GetConfigs())
                self:Notify({Title = "Deleted", Content = "Config removed!", Duration = 3, Type = "Warning"})
            end
        end
    })
    
    configModule:AddToggle({
        Name = "Auto Load",
        Default = false,
        Callback = function(value)
            if value then
                local name = configList:Get()
                if name then
                    self:SetAutoLoad(name)
                    self:Notify({Title = "Auto Load", Content = "'" .. name .. "' will auto-load!", Duration = 3, Type = "Success"})
                end
            else
                self:SetAutoLoad(nil)
            end
        end
    })
    
    -- UI Module
    local uiModule = settingsCategory:AddModule({
        Name = "Interface",
        Description = "UI customization",
        Default = true
    })
    
    uiModule:AddSlider({
        Name = "Transparency",
        Min = 0,
        Max = 90,
        Default = self.Transparency * 100,
        Increment = 5,
        Suffix = "%",
        Callback = function(value)
            self.Transparency = value / 100
            self.Main.BackgroundTransparency = self.Transparency
        end
    })
    
    uiModule:AddToggle({
        Name = "Rainbow Border",
        Default = self.RainbowEnabled,
        Callback = function(value)
            self.RainbowEnabled = value
            if value then
                Rainbow:Add(self.MainStroke)
                Rainbow:Start()
            else
                Rainbow:Remove(self.MainStroke)
                self.MainStroke.Color = self.Theme.Primary
            end
        end
    })
    
    uiModule:AddToggle({
        Name = "UI Sounds",
        Default = Config.SoundEnabled,
        Callback = function(value)
            Config.SoundEnabled = value
        end
    })
    
    uiModule:AddColorPicker({
        Name = "Theme Color",
        Default = self.Theme.Primary,
        Callback = function(color)
            self.Theme.Primary = color
            self.Theme.ModuleEnabled = color
        end
    })
    
    -- Actions Module
    local actionsModule = settingsCategory:AddModule({
        Name = "Actions",
        Description = "Quick actions",
        Default = true
    })
    
    actionsModule:AddButton({
        Name = "🔄 Rejoin Server",
        Callback = function()
            self:Notify({Title = "Rejoining", Content = "Teleporting...", Duration = 2, Type = "Warning"})
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    actionsModule:AddButton({
        Name = "⏹️ Disable All Modules",
        Callback = function()
            for _, mod in ipairs(self.Modules) do
                if mod.Enabled and mod.OnDisabled then
                    mod.OnDisabled()
                end
                mod.Enabled = false
                -- Update visual
                if mod.Card then
                    Utility.Tween(mod.Card, {BackgroundColor3 = self.Theme.ModuleDisabled}, 0.2)
                end
            end
            self:Notify({Title = "Disabled", Content = "All modules disabled!", Duration = 3, Type = "Success"})
        end
    })
    
    actionsModule:AddButton({
        Name = "❌ Destroy UI",
        Callback = function()
            self:Destroy()
        end
    })
    
    actionsModule:AddDivider({Text = "INFO"})
    
    actionsModule:AddLabel({
        Text = "NexusUI v" .. NexusUI.Version
    })
    
    actionsModule:AddLabel({
        Text = "Created by " .. NexusUI.Author
    })
    
    return settingsCategory
end

-- ============================================================================
-- Destroy
-- ============================================================================
function NexusUI:Destroy()
    Rainbow:Stop()
    
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    
    if self.Gui then
        self.Gui:Destroy()
    end
end

-- ============================================================================
-- Return Library
-- ============================================================================
return NexusUI
