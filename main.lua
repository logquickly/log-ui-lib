
## 📄 NexusUI.lua (主库文件 - 1500+ 行)

```lua
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     NexusUI Library v2.0                       ║
    ║              Futuristic Sci-Fi UI Framework                    ║
    ║                   Created by log_quick                         ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Features:
    - Sci-fi futuristic design with holographic effects
    - Rainbow gradient borders (customizable colors)
    - Semi-transparent menus with blur effects
    - Circular color picker with presets
    - Advanced loading animations with crisp sounds
    - Config system with auto-load functionality
    - Full mobile support with gesture controls
    - Rejoin and close functionality
]]

local NexusUI = {}
NexusUI.__index = NexusUI
NexusUI.Version = "2.0.0"
NexusUI.Author = "log_quick"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- Player Info
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Device Detection
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Configuration
local Config = {
    Theme = {
        Primary = Color3.fromRGB(0, 200, 255),
        Secondary = Color3.fromRGB(138, 43, 226),
        Background = Color3.fromRGB(15, 15, 25),
        BackgroundSecondary = Color3.fromRGB(25, 25, 40),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(0, 255, 150),
        Error = Color3.fromRGB(255, 75, 75),
        Success = Color3.fromRGB(75, 255, 150),
        Warning = Color3.fromRGB(255, 200, 75)
    },
    RainbowColors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(75, 0, 130),
        Color3.fromRGB(148, 0, 211)
    },
    Transparency = 0.15,
    BorderSize = 2,
    CornerRadius = 8,
    AnimationSpeed = 0.3,
    SoundEnabled = true,
    ConfigFolder = "NexusUI_Configs"
}

-- Sound Library
local Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079735",
    Toggle = "rbxassetid://6895079586",
    Success = "rbxassetid://6895079443",
    Error = "rbxassetid://6895079309",
    Load = "rbxassetid://5869673086",
    Notification = "rbxassetid://4590657391",
    Whoosh = "rbxassetid://6895079182",
    ConfigLoad = "rbxassetid://5869673086",
    Startup = "rbxassetid://5869673086"
}

-- Utility Functions
local Utility = {}

function Utility.Create(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(object, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or Config.AnimationSpeed,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility.PlaySound(soundId, volume, pitch)
    if not Config.SoundEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

function Utility.Ripple(button, x, y)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 1
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    Utility.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utility.GenerateUID()
    return HttpService:GenerateGUID(false)
end

function Utility.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utility.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Rainbow Border Handler
local RainbowHandler = {}
RainbowHandler.Objects = {}
RainbowHandler.Running = false
RainbowHandler.Speed = 1
RainbowHandler.CustomColors = nil

function RainbowHandler:Register(stroke)
    table.insert(self.Objects, stroke)
end

function RainbowHandler:Unregister(stroke)
    for i, obj in ipairs(self.Objects) do
        if obj == stroke then
            table.remove(self.Objects, i)
            break
        end
    end
end

function RainbowHandler:SetColors(colors)
    self.CustomColors = colors
end

function RainbowHandler:Start()
    if self.Running then return end
    self.Running = true
    
    task.spawn(function()
        local hue = 0
        while self.Running do
            hue = (hue + 0.005 * self.Speed) % 1
            
            local color
            if self.CustomColors then
                local index = math.floor(hue * #self.CustomColors) + 1
                local nextIndex = (index % #self.CustomColors) + 1
                local t = (hue * #self.CustomColors) % 1
                color = self.CustomColors[index]:Lerp(self.CustomColors[nextIndex], t)
            else
                color = Color3.fromHSV(hue, 0.8, 1)
            end
            
            for _, stroke in ipairs(self.Objects) do
                if stroke and stroke.Parent then
                    stroke.Color = color
                end
            end
            
            RunService.Heartbeat:Wait()
        end
    end)
end

function RainbowHandler:Stop()
    self.Running = false
end

-- Config System
local ConfigSystem = {}
ConfigSystem.CurrentConfig = {}
ConfigSystem.AutoLoad = nil

function ConfigSystem:GetFolder()
    if not isfolder(Config.ConfigFolder) then
        makefolder(Config.ConfigFolder)
    end
    return Config.ConfigFolder
end

function ConfigSystem:Save(name, data)
    local path = self:GetFolder() .. "/" .. name .. ".json"
    local jsonData = HttpService:JSONEncode(data)
    writefile(path, jsonData)
    Utility.PlaySound(Sounds.Success, 0.6)
end

function ConfigSystem:Load(name, flashCallback)
    local path = self:GetFolder() .. "/" .. name .. ".json"
    if isfile(path) then
        local jsonData = readfile(path)
        local data = HttpService:JSONDecode(jsonData)
        
        -- Flash effect
        if flashCallback then
            flashCallback()
        end
        
        Utility.PlaySound(Sounds.ConfigLoad, 0.8, 1.2)
        return data
    end
    return nil
end

function ConfigSystem:Delete(name)
    local path = self:GetFolder() .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

function ConfigSystem:GetList()
    local configs = {}
    local folder = self:GetFolder()
    for _, file in ipairs(listfiles(folder)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(configs, name)
        end
    end
    return configs
end

function ConfigSystem:SetAutoLoad(name)
    self.AutoLoad = name
    writefile(self:GetFolder() .. "/_autoload.txt", name)
end

function ConfigSystem:GetAutoLoad()
    local path = self:GetFolder() .. "/_autoload.txt"
    if isfile(path) then
        return readfile(path)
    end
    return nil
end

-- Main Library
function NexusUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, NexusUI)
    
    self.Name = options.Name or "NexusUI"
    self.Theme = Utility.DeepCopy(Config.Theme)
    self.Transparency = options.Transparency or Config.Transparency
    self.RainbowBorder = options.RainbowBorder ~= false
    self.RainbowColors = options.RainbowColors or Config.RainbowColors
    self.BindKey = options.BindKey or Enum.KeyCode.RightControl
    self.MobileButton = options.MobileButton ~= false
    
    self.Tabs = {}
    self.CurrentTab = nil
    self.Visible = false
    self.ConfigData = {}
    self.Elements = {}
    self.Connections = {}
    
    -- Apply custom theme
    if options.Theme then
        for key, value in pairs(options.Theme) do
            self.Theme[key] = value
        end
    end
    
    -- Set rainbow colors
    if self.RainbowColors then
        RainbowHandler:SetColors(self.RainbowColors)
    end
    
    self:CreateGui()
    self:SetupInput()
    
    if self.RainbowBorder then
        RainbowHandler:Start()
    end
    
    return self
end

function NexusUI:CreateGui()
    -- Main ScreenGui
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "NexusUI_" .. Utility.GenerateUID(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
        IgnoreGuiInset = true
    })
    
    -- Try to parent to CoreGui
    pcall(function()
        self.ScreenGui.Parent = CoreGui
    end)
    
    if not self.ScreenGui.Parent then
        self.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Loading Screen
    self:CreateLoadingScreen()
end

function NexusUI:CreateLoadingScreen()
    local loadingFrame = Utility.Create("Frame", {
        Name = "LoadingScreen",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(5, 5, 15),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1000
    })
    
    -- Particle Effect Container
    local particleContainer = Utility.Create("Frame", {
        Name = "Particles",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true
    })
    
    -- Create floating particles
    for i = 1, 50 do
        local particle = Utility.Create("Frame", {
            Name = "Particle_" .. i,
            Parent = particleContainer,
            BackgroundColor3 = self.Theme.Primary,
            BackgroundTransparency = math.random(50, 90) / 100,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6)),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            Rotation = math.random(0, 360)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle
        })
        
        -- Animate particles
        task.spawn(function()
            while particle.Parent do
                local targetPos = UDim2.new(math.random(), 0, math.random(), 0)
                local tween = Utility.Tween(particle, {
                    Position = targetPos,
                    Rotation = math.random(0, 360),
                    BackgroundTransparency = math.random(50, 90) / 100
                }, math.random(3, 8), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tween.Completed:Wait()
            end
        end)
    end
    
    -- Center Container
    local centerContainer = Utility.Create("Frame", {
        Name = "CenterContainer",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 300)
    })
    
    -- Logo Container with glow
    local logoContainer = Utility.Create("Frame", {
        Name = "LogoContainer",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 150, 0, 150)
    })
    
    -- Outer ring animation
    local outerRing = Utility.Create("Frame", {
        Name = "OuterRing",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 20, 1, 20)
    })
    
    local outerStroke = Utility.Create("UIStroke", {
        Parent = outerRing,
        Color = self.Theme.Primary,
        Thickness = 3,
        Transparency = 0.5
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = outerRing
    })
    
    RainbowHandler:Register(outerStroke)
    
    -- Inner ring
    local innerRing = Utility.Create("Frame", {
        Name = "InnerRing",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -20, 1, -20)
    })
    
    local innerStroke = Utility.Create("UIStroke", {
        Parent = innerRing,
        Color = self.Theme.Secondary,
        Thickness = 2,
        Transparency = 0.3
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = innerRing
    })
    
    -- Hexagon center
    local hexCenter = Utility.Create("Frame", {
        Name = "HexCenter",
        Parent = logoContainer,
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 80),
        Rotation = 0
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 15),
        Parent = hexCenter
    })
    
    local hexStroke = Utility.Create("UIStroke", {
        Parent = hexCenter,
        Color = self.Theme.Primary,
        Thickness = 2
    })
    
    RainbowHandler:Register(hexStroke)
    
    -- Logo Text
    local logoText = Utility.Create("TextLabel", {
        Name = "LogoText",
        Parent = hexCenter,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextColor3 = self.Theme.Text,
        TextSize = 36,
        TextTransparency = 0
    })
    
    -- Title
    local title = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 170),
        Size = UDim2.new(1, 0, 0, 40),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 28,
        TextTransparency = 1
    })
    
    local titleStroke = Utility.Create("UIStroke", {
        Parent = title,
        Color = self.Theme.Primary,
        Thickness = 1,
        Transparency = 0.5
    })
    
    -- Loading Bar Container
    local loadingBarContainer = Utility.Create("Frame", {
        Name = "LoadingBarContainer",
        Parent = centerContainer,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 220),
        Size = UDim2.new(0.8, 0, 0, 8)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = loadingBarContainer
    })
    
    local loadingBar = Utility.Create("Frame", {
        Name = "LoadingBar",
        Parent = loadingBarContainer,
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(0, 0, 1, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = loadingBar
    })
    
    local loadingBarGradient = Utility.Create("UIGradient", {
        Parent = loadingBar,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Primary),
            ColorSequenceKeypoint.new(0.5, self.Theme.Secondary),
            ColorSequenceKeypoint.new(1, self.Theme.Primary)
        }),
        Rotation = 0
    })
    
    -- Loading Status
    local loadingStatus = Utility.Create("TextLabel", {
        Name = "LoadingStatus",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 240),
        Size = UDim2.new(1, 0, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "Initializing...",
        TextColor3 = self.Theme.TextDark,
        TextSize = 14,
        TextTransparency = 1
    })
    
    -- Author Info
    local authorInfo = Utility.Create("TextLabel", {
        Name = "AuthorInfo",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -20),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "Created by " .. NexusUI.Author,
        TextColor3 = self.Theme.TextDark,
        TextSize = 12,
        TextTransparency = 1
    })
    
    -- Animation sequence
    task.spawn(function()
        -- Play startup sound
        Utility.PlaySound(Sounds.Startup, 0.7, 1)
        
        -- Animate rings
        task.spawn(function()
            while loadingFrame.Parent do
                Utility.Tween(outerRing, {Rotation = outerRing.Rotation + 360}, 3, Enum.EasingStyle.Linear)
                Utility.Tween(innerRing, {Rotation = innerRing.Rotation - 360}, 4, Enum.EasingStyle.Linear)
                Utility.Tween(hexCenter, {Rotation = hexCenter.Rotation + 90}, 2, Enum.EasingStyle.Quad)
                task.wait(3)
            end
        end)
        
        -- Animate gradient
        task.spawn(function()
            while loadingFrame.Parent do
                Utility.Tween(loadingBarGradient, {Rotation = 360}, 2, Enum.EasingStyle.Linear)
                task.wait(2)
                loadingBarGradient.Rotation = 0
            end
        end)
        
        task.wait(0.5)
        
        -- Fade in title
        Utility.Tween(title, {TextTransparency = 0}, 0.5)
        Utility.PlaySound(Sounds.Whoosh, 0.4)
        
        task.wait(0.3)
        
        -- Fade in status and author
        Utility.Tween(loadingStatus, {TextTransparency = 0}, 0.3)
        Utility.Tween(authorInfo, {TextTransparency = 0.5}, 0.3)
        
        -- Loading sequence
        local loadingSteps = {
            {progress = 0.15, status = "Loading core modules..."},
            {progress = 0.30, status = "Initializing UI framework..."},
            {progress = 0.45, status = "Setting up input handlers..."},
            {progress = 0.60, status = "Loading configurations..."},
            {progress = 0.75, status = "Applying theme..."},
            {progress = 0.90, status = "Finalizing..."},
            {progress = 1.00, status = "Ready!"}
        }
        
        for _, step in ipairs(loadingSteps) do
            loadingStatus.Text = step.status
            Utility.Tween(loadingBar, {Size = UDim2.new(step.progress, 0, 1, 0)}, 0.4)
            Utility.PlaySound(Sounds.Click, 0.2, 1 + step.progress * 0.3)
            task.wait(0.3)
        end
        
        task.wait(0.5)
        
        -- Success sound
        Utility.PlaySound(Sounds.Success, 0.6)
        
        -- Flash effect
        local flash = Utility.Create("Frame", {
            Name = "Flash",
            Parent = loadingFrame,
            BackgroundColor3 = self.Theme.Primary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 1001
        })
        
        Utility.Tween(flash, {BackgroundTransparency = 0.5}, 0.1)
        task.wait(0.1)
        Utility.Tween(flash, {BackgroundTransparency = 1}, 0.3)
        
        task.wait(0.3)
        
        -- Fade out loading screen
        Utility.Tween(loadingFrame, {BackgroundTransparency = 1}, 0.5)
        for _, child in ipairs(loadingFrame:GetDescendants()) do
            if child:IsA("Frame") then
                Utility.Tween(child, {BackgroundTransparency = 1}, 0.5)
            elseif child:IsA("TextLabel") then
                Utility.Tween(child, {TextTransparency = 1}, 0.5)
            elseif child:IsA("UIStroke") then
                Utility.Tween(child, {Transparency = 1}, 0.5)
            end
        end
        
        task.wait(0.6)
        loadingFrame:Destroy()
        
        -- Create main interface
        self:CreateMainInterface()
        self:Show()
        
        -- Auto load config
        local autoLoadConfig = ConfigSystem:GetAutoLoad()
        if autoLoadConfig then
            task.wait(0.5)
            self:LoadConfig(autoLoadConfig)
        end
    end)
end

function NexusUI:CreateMainInterface()
    -- Main Container
    self.MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        Parent = self.ScreenGui,
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = self.Transparency,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 650, 0, 450),
        ClipsDescendants = true,
        Visible = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Config.CornerRadius + 4),
        Parent = self.MainFrame
    })
    
    -- Rainbow border
    self.MainStroke = Utility.Create("UIStroke", {
        Parent = self.MainFrame,
        Color = self.Theme.Primary,
        Thickness = Config.BorderSize,
        Transparency = 0
    })
    
    if self.RainbowBorder then
        RainbowHandler:Register(self.MainStroke)
    end
    
    -- Blur effect
    self.BlurEffect = Utility.Create("BlurEffect", {
        Name = "NexusUIBlur",
        Parent = Lighting,
        Size = 0,
        Enabled = true
    })
    
    -- Shadow
    local shadow = Utility.Create("ImageLabel", {
        Name = "Shadow",
        Parent = self.MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 50, 1, 50),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1
    })
    
    -- Title Bar
    local titleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Parent = self.MainFrame,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, 45),
        BorderSizePixel = 0
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Config.CornerRadius + 4),
        Parent = titleBar
    })
    
    -- Fix bottom corners of title bar
    local titleBarFix = Utility.Create("Frame", {
        Name = "Fix",
        Parent = titleBar,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BorderSizePixel = 0
    })
    
    -- Title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "◈ " .. self.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local titleGlow = Utility.Create("UIStroke", {
        Parent = titleLabel,
        Color = self.Theme.Primary,
        Thickness = 0,
        Transparency = 0.5
    })
    
    -- Close Button
    local closeButton = Utility.Create("TextButton", {
        Name = "CloseButton",
        Parent = titleBar,
        BackgroundColor3 = self.Theme.Error,
        BackgroundTransparency = 0.8,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = self.Theme.Text,
        TextSize = 20,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = closeButton
    })
    
    closeButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.5)
        self:Hide()
    end)
    
    closeButton.MouseEnter:Connect(function()
        Utility.Tween(closeButton, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utility.Tween(closeButton, {BackgroundTransparency = 0.8}, 0.2)
    end)
    
    -- Minimize Button
    local minimizeButton = Utility.Create("TextButton", {
        Name = "MinimizeButton",
        Parent = titleBar,
        BackgroundColor3 = self.Theme.Warning,
        BackgroundTransparency = 0.8,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextColor3 = self.Theme.Text,
        TextSize = 20,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = minimizeButton
    })
    
    minimizeButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.5)
        self:Hide()
    end)
    
    minimizeButton.MouseEnter:Connect(function()
        Utility.Tween(minimizeButton, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        Utility.Tween(minimizeButton, {BackgroundTransparency = 0.8}, 0.2)
    end)
    
    -- Tab Container
    self.TabContainer = Utility.Create("Frame", {
        Name = "TabContainer",
        Parent = self.MainFrame,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 10, 0, 55),
        Size = UDim2.new(0, 140, 1, -65),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Config.CornerRadius),
        Parent = self.TabContainer
    })
    
    -- Tab List
    self.TabList = Utility.Create("ScrollingFrame", {
        Name = "TabList",
        Parent = self.TabContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Primary,
        BorderSizePixel = 0
    })
    
    self.TabListLayout = Utility.Create("UIListLayout", {
        Parent = self.TabList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    -- Content Container
    self.ContentContainer = Utility.Create("Frame", {
        Name = "ContentContainer",
        Parent = self.MainFrame,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0, 160, 0, 55),
        Size = UDim2.new(1, -170, 1, -65),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Config.CornerRadius),
        Parent = self.ContentContainer
    })
    
    -- Dragging
    self:SetupDragging()
    
    -- Mobile Button
    if IsMobile and self.MobileButton then
        self:CreateMobileButton()
    end
end

function NexusUI:SetupDragging()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local titleBar = self.MainFrame:FindFirstChild("TitleBar")
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function NexusUI:CreateMobileButton()
    self.MobileToggle = Utility.Create("TextButton", {
        Name = "MobileToggle",
        Parent = self.ScreenGui,
        BackgroundColor3 = self.Theme.Primary,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 10, 0.5, -25),
        Size = UDim2.new(0, 50, 0, 50),
        Font = Enum.Font.GothamBold,
        Text = "◈",
        TextColor3 = self.Theme.Text,
        TextSize = 24,
        AutoButtonColor = false,
        ZIndex = 100
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.MobileToggle
    })
    
    local mobileStroke = Utility.Create("UIStroke", {
        Parent = self.MobileToggle,
        Color = self.Theme.Primary,
        Thickness = 2
    })
    
    if self.RainbowBorder then
        RainbowHandler:Register(mobileStroke)
    end
    
    -- Draggable mobile button
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    self.MobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MobileToggle.Position
        end
    end)
    
    self.MobileToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if dragging and (input.Position - dragStart).Magnitude < 10 then
                self:Toggle()
                Utility.PlaySound(Sounds.Click, 0.5)
            end
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            self.MobileToggle.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function NexusUI:SetupInput()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == self.BindKey then
            self:Toggle()
            Utility.PlaySound(Sounds.Whoosh, 0.4)
        end
    end))
end

function NexusUI:Show()
    if self.Visible then return end
    self.Visible = true
    
    self.MainFrame.Visible = true
    self.MainFrame.Size = IsMobile and UDim2.new(0.9, 0, 0.8, 0) or UDim2.new(0, 600, 0, 400)
    self.MainFrame.BackgroundTransparency = 1
    self.MainStroke.Transparency = 1
    
    Utility.Tween(self.MainFrame, {
        Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 650, 0, 450),
        BackgroundTransparency = self.Transparency
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    Utility.Tween(self.MainStroke, {Transparency = 0}, 0.3)
    Utility.Tween(self.BlurEffect, {Size = 10}, 0.3)
    
    if self.MobileToggle then
        Utility.Tween(self.MobileToggle, {BackgroundTransparency = 0.7}, 0.3)
    end
end

function NexusUI:Hide()
    if not self.Visible then return end
    self.Visible = false
    
    Utility.Tween(self.MainFrame, {
        Size = IsMobile and UDim2.new(0.9, 0, 0.8, 0) or UDim2.new(0, 600, 0, 400),
        BackgroundTransparency = 1
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    
    Utility.Tween(self.MainStroke, {Transparency = 1}, 0.2)
    Utility.Tween(self.BlurEffect, {Size = 0}, 0.3)
    
    if self.MobileToggle then
        Utility.Tween(self.MobileToggle, {BackgroundTransparency = 0.3}, 0.3)
    end
    
    task.delay(0.3, function()
        if not self.Visible then
            self.MainFrame.Visible = false
        end
    end)
end

function NexusUI:Toggle()
    if self.Visible then
        self:Hide()
    else
        self:Show()
    end
end

-- Tab Creation
function NexusUI:CreateTab(options)
    options = options or {}
    
    local tab = {
        Name = options.Name or "Tab",
        Icon = options.Icon or "◆",
        Elements = {},
        Visible = false
    }
    
    -- Tab Button
    tab.Button = Utility.Create("TextButton", {
        Name = tab.Name .. "_Button",
        Parent = self.TabList,
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 40),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = tab.Button
    })
    
    local tabStroke = Utility.Create("UIStroke", {
        Parent = tab.Button,
        Color = self.Theme.Primary,
        Thickness = 1,
        Transparency = 0.8
    })
    
    -- Tab Icon
    local tabIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = tab.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 25, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tab.Icon,
        TextColor3 = self.Theme.TextDark,
        TextSize = 14
    })
    
    -- Tab Title
    local tabTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = tab.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -45, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tab.Name,
        TextColor3 = self.Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    -- Tab Content
    tab.Content = Utility.Create("ScrollingFrame", {
        Name = tab.Name .. "_Content",
        Parent = self.ContentContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Primary,
        Visible = false,
        BorderSizePixel = 0
    })
    
    tab.ContentLayout = Utility.Create("UIListLayout", {
        Parent = tab.Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    Utility.Create("UIPadding", {
        Parent = tab.Content,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    
    -- Update canvas size
    tab.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Tab Button Click
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
        Utility.PlaySound(Sounds.Click, 0.4)
        Utility.Ripple(tab.Button, Mouse.X, Mouse.Y)
    end)
    
    tab.Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 0.3}, 0.2)
            Utility.Tween(tabStroke, {Transparency = 0.5}, 0.2)
        end
        Utility.PlaySound(Sounds.Hover, 0.2)
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 0.5}, 0.2)
            Utility.Tween(tabStroke, {Transparency = 0.8}, 0.2)
        end
    end)
    
    -- Update tab list canvas
    self.TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabList.CanvasSize = UDim2.new(0, 0, 0, self.TabListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Select first tab
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    -- Return tab object with element creation methods
    local tabObject = {}
    
    function tabObject:AddSection(options)
        return NexusUI.CreateSection(self, tab, options)
    end
    
    function tabObject:AddButton(options)
        return NexusUI.CreateButton(self, tab, options)
    end
    
    function tabObject:AddToggle(options)
        return NexusUI.CreateToggle(self, tab, options)
    end
    
    function tabObject:AddSlider(options)
        return NexusUI.CreateSlider(self, tab, options)
    end
    
    function tabObject:AddDropdown(options)
        return NexusUI.CreateDropdown(self, tab, options)
    end
    
    function tabObject:AddColorPicker(options)
        return NexusUI.CreateColorPicker(self, tab, options)
    end
    
    function tabObject:AddTextbox(options)
        return NexusUI.CreateTextbox(self, tab, options)
    end
    
    function tabObject:AddKeybind(options)
        return NexusUI.CreateKeybind(self, tab, options)
    end
    
    function tabObject:AddLabel(options)
        return NexusUI.CreateLabel(self, tab, options)
    end
    
    function tabObject:AddParagraph(options)
        return NexusUI.CreateParagraph(self, tab, options)
    end
    
    setmetatable(tabObject, {__index = self})
    return tabObject
end

function NexusUI:SelectTab(tab)
    if self.CurrentTab == tab then return end
    
    -- Deselect current tab
    if self.CurrentTab then
        self.CurrentTab.Content.Visible = false
        local button = self.CurrentTab.Button
        Utility.Tween(button, {BackgroundTransparency = 0.5}, 0.2)
        Utility.Tween(button:FindFirstChild("Icon"), {TextColor3 = self.Theme.TextDark}, 0.2)
        Utility.Tween(button:FindFirstChild("Title"), {TextColor3 = self.Theme.TextDark}, 0.2)
    end
    
    -- Select new tab
    self.CurrentTab = tab
    tab.Content.Visible = true
    
    local button = tab.Button
    Utility.Tween(button, {BackgroundTransparency = 0.2}, 0.2)
    Utility.Tween(button:FindFirstChild("Icon"), {TextColor3 = self.Theme.Primary}, 0.2)
    Utility.Tween(button:FindFirstChild("Title"), {TextColor3 = self.Theme.Text}, 0.2)
end

-- Section Element
function NexusUI.CreateSection(ui, tab, options)
    options = options or {}
    
    local section = Utility.Create("Frame", {
        Name = "Section",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, 0, 0, 35)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = section
    })
    
    local sectionTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = section,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = options.Name or "Section",
        TextColor3 = ui.Theme.Primary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local line = Utility.Create("Frame", {
        Name = "Line",
        Parent = section,
        BackgroundColor3 = ui.Theme.Primary,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2)
    })
    
    local lineGradient = Utility.Create("UIGradient", {
        Parent = line,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ui.Theme.Primary),
            ColorSequenceKeypoint.new(0.5, ui.Theme.Secondary),
            ColorSequenceKeypoint.new(1, ui.Theme.Primary)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.1, 0),
            NumberSequenceKeypoint.new(0.9, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    
    return section
end

-- Button Element
function NexusUI.CreateButton(ui, tab, options)
    options = options or {}
    
    local button = Utility.Create("TextButton", {
        Name = "Button",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = button
    })
    
    local buttonStroke = Utility.Create("UIStroke", {
        Parent = button,
        Color = ui.Theme.Primary,
        Thickness = 1,
        Transparency = 0.7
    })
    
    local buttonIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = options.Icon or "▶",
        TextColor3 = ui.Theme.Primary,
        TextSize = 12
    })
    
    local buttonTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Button",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    button.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.5)
        Utility.Ripple(button, Mouse.X, Mouse.Y)
        
        -- Visual feedback
        Utility.Tween(button, {BackgroundTransparency = 0.2}, 0.1)
        Utility.Tween(buttonStroke, {Transparency = 0.3}, 0.1)
        
        task.delay(0.15, function()
            Utility.Tween(button, {BackgroundTransparency = 0.5}, 0.2)
            Utility.Tween(buttonStroke, {Transparency = 0.7}, 0.2)
        end)
        
        if options.Callback then
            options.Callback()
        end
    end)
    
    button.MouseEnter:Connect(function()
        Utility.Tween(button, {BackgroundTransparency = 0.3}, 0.2)
        Utility.Tween(buttonStroke, {Transparency = 0.5}, 0.2)
        Utility.PlaySound(Sounds.Hover, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utility.Tween(button, {BackgroundTransparency = 0.5}, 0.2)
        Utility.Tween(buttonStroke, {Transparency = 0.7}, 0.2)
    end)
    
    return button
end

-- Toggle Element
function NexusUI.CreateToggle(ui, tab, options)
    options = options or {}
    
    local toggled = options.Default or false
    local flag = options.Flag
    
    local toggle = Utility.Create("TextButton", {
        Name = "Toggle",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = toggle
    })
    
    local toggleTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = toggle,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Toggle",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleContainer = Utility.Create("Frame", {
        Name = "ToggleContainer",
        Parent = toggle,
        BackgroundColor3 = ui.Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 46, 0, 24)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleContainer
    })
    
    local toggleStroke = Utility.Create("UIStroke", {
        Parent = toggleContainer,
        Color = ui.Theme.TextDark,
        Thickness = 1,
        Transparency = 0.5
    })
    
    local toggleIndicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = toggleContainer,
        BackgroundColor3 = ui.Theme.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleIndicator
    })
    
    local function updateToggle(value, skipCallback)
        toggled = value
        
        if toggled then
            Utility.Tween(toggleIndicator, {
                Position = UDim2.new(1, -22, 0.5, 0),
                BackgroundColor3 = ui.Theme.Primary
            }, 0.2)
            Utility.Tween(toggleStroke, {Color = ui.Theme.Primary}, 0.2)
            Utility.Tween(toggleContainer, {BackgroundColor3 = ui.Theme.Primary:Lerp(ui.Theme.Background, 0.7)}, 0.2)
        else
            Utility.Tween(toggleIndicator, {
                Position = UDim2.new(0, 4, 0.5, 0),
                BackgroundColor3 = ui.Theme.TextDark
            }, 0.2)
            Utility.Tween(toggleStroke, {Color = ui.Theme.TextDark}, 0.2)
            Utility.Tween(toggleContainer, {BackgroundColor3 = ui.Theme.Background}, 0.2)
        end
        
        if flag then
            ui.ConfigData[flag] = toggled
        end
        
        if not skipCallback and options.Callback then
            options.Callback(toggled)
        end
    end
    
    -- Initialize
    if toggled then
        updateToggle(true, true)
    end
    
    toggle.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Toggle, 0.4)
        updateToggle(not toggled)
    end)
    
    toggle.MouseEnter:Connect(function()
        Utility.Tween(toggle, {BackgroundTransparency = 0.3}, 0.2)
        Utility.PlaySound(Sounds.Hover, 0.2)
    end)
    
    toggle.MouseLeave:Connect(function()
        Utility.Tween(toggle, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    -- Return toggle object
    local toggleObj = {Frame = toggle}
    
    function toggleObj:Set(value)
        updateToggle(value)
    end
    
    function toggleObj:Get()
        return toggled
    end
    
    if flag then
        ui.Elements[flag] = toggleObj
    end
    
    return toggleObj
end

-- Slider Element
function NexusUI.CreateSlider(ui, tab, options)
    options = options or {}
    
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local suffix = options.Suffix or ""
    local flag = options.Flag
    
    local value = math.clamp(default, min, max)
    
    local slider = Utility.Create("Frame", {
        Name = "Slider",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 55)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = slider
    })
    
    local sliderTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = slider,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 5),
        Size = UDim2.new(0.6, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Slider",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local sliderValue = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = slider,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 5),
        Size = UDim2.new(0.4, -12, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = tostring(value) .. suffix,
        TextColor3 = ui.Theme.Primary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderBar = Utility.Create("Frame", {
        Name = "Bar",
        Parent = slider,
        BackgroundColor3 = ui.Theme.Background,
        Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -24, 0, 12)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderBar
    })
    
    local sliderFill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = sliderBar,
        BackgroundColor3 = ui.Theme.Primary,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderFill
    })
    
    local sliderGradient = Utility.Create("UIGradient", {
        Parent = sliderFill,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ui.Theme.Primary),
            ColorSequenceKeypoint.new(1, ui.Theme.Secondary)
        })
    })
    
    local sliderKnob = Utility.Create("Frame", {
        Name = "Knob",
        Parent = sliderFill,
        BackgroundColor3 = ui.Theme.Text,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderKnob
    })
    
    local knobStroke = Utility.Create("UIStroke", {
        Parent = sliderKnob,
        Color = ui.Theme.Primary,
        Thickness = 2
    })
    
    local function updateSlider(newValue, skipCallback)
        newValue = math.clamp(newValue, min, max)
        newValue = math.floor(newValue / increment + 0.5) * increment
        
        value = newValue
        sliderValue.Text = tostring(value) .. suffix
        
        local percent = (value - min) / (max - min)
        Utility.Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
        
        if flag then
            ui.ConfigData[flag] = value
        end
        
        if not skipCallback and options.Callback then
            options.Callback(value)
        end
    end
    
    local dragging = false
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            
            local percent = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            updateSlider(min + (max - min) * percent)
            
            Utility.PlaySound(Sounds.Click, 0.3)
        end
    end)
    
    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            updateSlider(min + (max - min) * percent)
        end
    end)
    
    -- Initialize
    updateSlider(value, true)
    
    -- Return slider object
    local sliderObj = {Frame = slider}
    
    function sliderObj:Set(newValue)
        updateSlider(newValue)
    end
    
    function sliderObj:Get()
        return value
    end
    
    if flag then
        ui.Elements[flag] = sliderObj
    end
    
    return sliderObj
end

-- Dropdown Element
function NexusUI.CreateDropdown(ui, tab, options)
    options = options or {}
    
    local items = options.Items or {}
    local default = options.Default
    local multi = options.Multi or false
    local flag = options.Flag
    
    local selected = multi and {} or nil
    local open = false
    
    if default then
        if multi then
            for _, item in ipairs(default) do
                selected[item] = true
            end
        else
            selected = default
        end
    end
    
    local dropdown = Utility.Create("Frame", {
        Name = "Dropdown",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = dropdown
    })
    
    local dropdownButton = Utility.Create("TextButton", {
        Name = "Button",
        Parent = dropdown,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false
    })
    
    local dropdownTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = dropdownButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Dropdown",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local dropdownSelected = Utility.Create("TextLabel", {
        Name = "Selected",
        Parent = dropdownButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -35, 1, 0),
        Font = Enum.Font.Gotham,
        Text = multi and "None selected" or (selected or "Select..."),
        TextColor3 = ui.Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    local dropdownArrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdownButton,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = ui.Theme.Primary,
        TextSize = 10
    })
    
    local dropdownList = Utility.Create("Frame", {
        Name = "List",
        Parent = dropdown,
        BackgroundColor3 = ui.Theme.Background,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 5, 0, 43),
        Size = UDim2.new(1, -10, 0, 0),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = dropdownList
    })
    
    local dropdownListLayout = Utility.Create("UIListLayout", {
        Parent = dropdownList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    
    Utility.Create("UIPadding", {
        Parent = dropdownList,
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3)
    })
    
    local function updateDisplay()
        if multi then
            local selectedItems = {}
            for item, isSelected in pairs(selected) do
                if isSelected then
                    table.insert(selectedItems, item)
                end
            end
            dropdownSelected.Text = #selectedItems > 0 and table.concat(selectedItems, ", ") or "None selected"
        else
            dropdownSelected.Text = selected or "Select..."
        end
    end
    
    local function createItem(name)
        local item = Utility.Create("TextButton", {
            Name = name,
            Parent = dropdownList,
            BackgroundColor3 = ui.Theme.BackgroundSecondary,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = ui.Theme.Text,
            TextSize = 12,
            AutoButtonColor = false
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = item
        })
        
        if multi then
            local itemCheck = Utility.Create("TextLabel", {
                Name = "Check",
                Parent = item,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = selected[name] and "✓" or "",
                TextColor3 = ui.Theme.Primary,
                TextSize = 14
            })
            
            item.MouseButton1Click:Connect(function()
                selected[name] = not selected[name]
                itemCheck.Text = selected[name] and "✓" or ""
                
                if selected[name] then
                    Utility.Tween(item, {BackgroundColor3 = ui.Theme.Primary:Lerp(ui.Theme.Background, 0.7)}, 0.2)
                else
                    Utility.Tween(item, {BackgroundColor3 = ui.Theme.BackgroundSecondary}, 0.2)
                end
                
                updateDisplay()
                Utility.PlaySound(Sounds.Click, 0.3)
                
                if flag then
                    local selectedList = {}
                    for k, v in pairs(selected) do
                        if v then table.insert(selectedList, k) end
                    end
                    ui.ConfigData[flag] = selectedList
                end
                
                if options.Callback then
                    options.Callback(selected)
                end
            end)
        else
            item.MouseButton1Click:Connect(function()
                selected = name
                updateDisplay()
                
                -- Close dropdown
                open = false
                Utility.Tween(dropdown, {Size = UDim2.new(1, 0, 0, 38)}, 0.3)
                Utility.Tween(dropdownArrow, {Rotation = 0}, 0.3)
                
                Utility.PlaySound(Sounds.Click, 0.3)
                
                if flag then
                    ui.ConfigData[flag] = selected
                end
                
                if options.Callback then
                    options.Callback(selected)
                end
            end)
        end
        
        item.MouseEnter:Connect(function()
            Utility.Tween(item, {BackgroundTransparency = 0.3}, 0.2)
        end)
        
        item.MouseLeave:Connect(function()
            Utility.Tween(item, {BackgroundTransparency = 0.5}, 0.2)
        end)
        
        return item
    end
    
    -- Create items
    for _, itemName in ipairs(items) do
        createItem(itemName)
    end
    
    -- Toggle dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        open = not open
        Utility.PlaySound(Sounds.Click, 0.4)
        
        if open then
            local listHeight = math.min(#items * 32 + 10, 150)
            Utility.Tween(dropdown, {Size = UDim2.new(1, 0, 0, 38 + listHeight + 10)}, 0.3)
            Utility.Tween(dropdownList, {Size = UDim2.new(1, -10, 0, listHeight)}, 0.3)
            Utility.Tween(dropdownArrow, {Rotation = 180}, 0.3)
        else
            Utility.Tween(dropdown, {Size = UDim2.new(1, 0, 0, 38)}, 0.3)
            Utility.Tween(dropdownList, {Size = UDim2.new(1, -10, 0, 0)}, 0.3)
            Utility.Tween(dropdownArrow, {Rotation = 0}, 0.3)
        end
    end)
    
    -- Initialize
    updateDisplay()
    
    -- Return dropdown object
    local dropdownObj = {Frame = dropdown}
    
    function dropdownObj:Set(value)
        if multi then
            selected = {}
            for _, item in ipairs(value) do
                selected[item] = true
            end
        else
            selected = value
        end
        updateDisplay()
        
        if options.Callback then
            options.Callback(selected)
        end
    end
    
    function dropdownObj:Get()
        if multi then
            local result = {}
            for k, v in pairs(selected) do
                if v then table.insert(result, k) end
            end
            return result
        end
        return selected
    end
    
    function dropdownObj:Refresh(newItems)
        items = newItems
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, itemName in ipairs(items) do
            createItem(itemName)
        end
    end
    
    if flag then
        ui.Elements[flag] = dropdownObj
    end
    
    return dropdownObj
end

-- Color Picker Element (Circular)
function NexusUI.CreateColorPicker(ui, tab, options)
    options = options or {}
    
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local presets = options.Presets or {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(127, 0, 255),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(0, 0, 0)
    }
    local flag = options.Flag
    
    local currentColor = default
    local hue, sat, val = Color3.toHSV(default)
    local open = false
    
    local colorPicker = Utility.Create("Frame", {
        Name = "ColorPicker",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = colorPicker
    })
    
    local pickerButton = Utility.Create("TextButton", {
        Name = "Button",
        Parent = colorPicker,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false
    })
    
    local pickerTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = pickerButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Color Picker",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local colorPreview = Utility.Create("Frame", {
        Name = "Preview",
        Parent = pickerButton,
        BackgroundColor3 = currentColor,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 24)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorPreview
    })
    
    local previewStroke = Utility.Create("UIStroke", {
        Parent = colorPreview,
        Color = ui.Theme.Text,
        Thickness = 1,
        Transparency = 0.5
    })
    
    -- Picker Container
    local pickerContainer = Utility.Create("Frame", {
        Name = "Container",
        Parent = colorPicker,
        BackgroundColor3 = ui.Theme.Background,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 5, 0, 43),
        Size = UDim2.new(1, -10, 0, 0),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = pickerContainer
    })
    
    -- Circular Color Wheel
    local wheelContainer = Utility.Create("Frame", {
        Name = "WheelContainer",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 150, 0, 150)
    })
    
    local colorWheel = Utility.Create("ImageLabel", {
        Name = "ColorWheel",
        Parent = wheelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385", -- Color wheel image
        ImageTransparency = 0
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = colorWheel
    })
    
    local wheelSelector = Utility.Create("Frame", {
        Name = "Selector",
        Parent = colorWheel,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 5
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = wheelSelector
    })
    
    local wheelSelectorStroke = Utility.Create("UIStroke", {
        Parent = wheelSelector,
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 2
    })
    
    -- Value/Brightness Slider
    local valueSlider = Utility.Create("Frame", {
        Name = "ValueSlider",
        Parent = pickerContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 170, 0, 10),
        Size = UDim2.new(0, 20, 0, 150)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = valueSlider
    })
    
    local valueGradient = Utility.Create("UIGradient", {
        Parent = valueSlider,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        }),
        Rotation = 90
    })
    
    local valueSelector = Utility.Create("Frame", {
        Name = "Selector",
        Parent = valueSlider,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 6, 0, 6),
        ZIndex = 5
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = valueSelector
    })
    
    local valueSelectorStroke = Utility.Create("UIStroke", {
        Parent = valueSelector,
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 2
    })
    
    -- Preset Colors
    local presetContainer = Utility.Create("Frame", {
        Name = "Presets",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 170),
        Size = UDim2.new(1, -20, 0, 25)
    })
    
    local presetLayout = Utility.Create("UIListLayout", {
        Parent = presetContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    
    -- Hex Input
    local hexContainer = Utility.Create("Frame", {
        Name = "HexContainer",
        Parent = pickerContainer,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 10, 0, 200),
        Size = UDim2.new(1, -20, 0, 30)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = hexContainer
    })
    
    local hexLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = hexContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "HEX:",
        TextColor3 = ui.Theme.TextDark,
        TextSize = 12
    })
    
    local hexInput = Utility.Create("TextBox", {
        Name = "Input",
        Parent = hexContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 0),
        Size = UDim2.new(1, -55, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "#FFFFFF",
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    -- RGB Inputs
    local rgbContainer = Utility.Create("Frame", {
        Name = "RGBContainer",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 235),
        Size = UDim2.new(1, -20, 0, 25)
    })
    
    local function createRGBInput(name, position)
        local container = Utility.Create("Frame", {
            Name = name .. "Container",
            Parent = rgbContainer,
            BackgroundColor3 = ui.Theme.BackgroundSecondary,
            BackgroundTransparency = 0.5,
            Position = position,
            Size = UDim2.new(0.3, -5, 1, 0)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = container
        })
        
        local label = Utility.Create("TextLabel", {
            Name = "Label",
            Parent = container,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(0, 15, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = name:sub(1, 1),
            TextColor3 = name == "R" and Color3.fromRGB(255, 100, 100) or (name == "G" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 255)),
            TextSize = 12
        })
        
        local input = Utility.Create("TextBox", {
            Name = "Input",
            Parent = container,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 0),
            Size = UDim2.new(1, -27, 1, 0),
            Font = Enum.Font.Gotham,
            Text = "255",
            TextColor3 = ui.Theme.Text,
            TextSize = 12,
            ClearTextOnFocus = false
        })
        
        return input
    end
    
    local rInput = createRGBInput("R", UDim2.new(0, 0, 0, 0))
    local gInput = createRGBInput("G", UDim2.new(0.35, 0, 0, 0))
    local bInput = createRGBInput("B", UDim2.new(0.7, 0, 0, 0))
    
    -- Update functions
    local function updateColor(newColor, skipCallback)
        currentColor = newColor
        hue, sat, val = Color3.toHSV(newColor)
        
        colorPreview.BackgroundColor3 = newColor
        
        -- Update hex
        local r, g, b = math.floor(newColor.R * 255), math.floor(newColor.G * 255), math.floor(newColor.B * 255)
        hexInput.Text = string.format("#%02X%02X%02X", r, g, b)
        
        -- Update RGB inputs
        rInput.Text = tostring(r)
        gInput.Text = tostring(g)
        bInput.Text = tostring(b)
        
        -- Update wheel selector position
        local angle = hue * math.pi * 2
        local radius = sat * 0.45
        wheelSelector.Position = UDim2.new(0.5 + math.cos(angle) * radius, 0, 0.5 + math.sin(angle) * radius, 0)
        
        -- Update value selector position
        valueSelector.Position = UDim2.new(0.5, 0, 1 - val, 0)
        
        -- Update value gradient color
        valueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        })
        
        if flag then
            ui.ConfigData[flag] = {R = newColor.R, G = newColor.G, B = newColor.B}
        end
        
        if not skipCallback and options.Callback then
            options.Callback(newColor)
        end
    end
    
    -- Color wheel input
    local wheelDragging = false
    
    colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = true
            
            local centerX = colorWheel.AbsolutePosition.X + colorWheel.AbsoluteSize.X / 2
            local centerY = colorWheel.AbsolutePosition.Y + colorWheel.AbsoluteSize.Y / 2
            local radius = colorWheel.AbsoluteSize.X / 2
            
            local dx = input.Position.X - centerX
            local dy = input.Position.Y - centerY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= radius then
                hue = (math.atan2(dy, dx) / (math.pi * 2) + 0.5) % 1
                sat = math.min(distance / radius, 1)
                updateColor(Color3.fromHSV(hue, sat, val))
            end
        end
    end)
    
    colorWheel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = false
        end
    end)
    
    -- Value slider input
    local valueDragging = false
    
    valueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = true
            
            local percent = math.clamp((input.Position.Y - valueSlider.AbsolutePosition.Y) / valueSlider.AbsoluteSize.Y, 0, 1)
            val = 1 - percent
            updateColor(Color3.fromHSV(hue, sat, val))
        end
    end)
    
    valueSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if wheelDragging then
                local centerX = colorWheel.AbsolutePosition.X + colorWheel.AbsoluteSize.X / 2
                local centerY = colorWheel.AbsolutePosition.Y + colorWheel.AbsoluteSize.Y / 2
                local radius = colorWheel.AbsoluteSize.X / 2
                
                local dx = input.Position.X - centerX
                local dy = input.Position.Y - centerY
                local distance = math.sqrt(dx * dx + dy * dy)
                
                hue = (math.atan2(dy, dx) / (math.pi * 2) + 0.5) % 1
                sat = math.min(distance / radius, 1)
                updateColor(Color3.fromHSV(hue, sat, val))
            elseif valueDragging then
                local percent = math.clamp((input.Position.Y - valueSlider.AbsolutePosition.Y) / valueSlider.AbsoluteSize.Y, 0, 1)
                val = 1 - percent
                updateColor(Color3.fromHSV(hue, sat, val))
            end
        end
    end)
    
    -- Create preset buttons
    for i, preset in ipairs(presets) do
        local presetButton = Utility.Create("TextButton", {
            Name = "Preset" .. i,
            Parent = presetContainer,
            BackgroundColor3 = preset,
            Size = UDim2.new(0, 22, 0, 22),
            Text = "",
            AutoButtonColor = false
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = presetButton
        })
        
        local presetStroke = Utility.Create("UIStroke", {
            Parent = presetButton,
            Color = ui.Theme.Text,
            Thickness = 1,
            Transparency = 0.7
        })
        
        presetButton.MouseButton1Click:Connect(function()
            updateColor(preset)
            Utility.PlaySound(Sounds.Click, 0.3)
        end)
        
        presetButton.MouseEnter:Connect(function()
            Utility.Tween(presetStroke, {Transparency = 0}, 0.2)
        end)
        
        presetButton.MouseLeave:Connect(function()
            Utility.Tween(presetStroke, {Transparency = 0.7}, 0.2)
        end)
    end
    
    -- Hex input handler
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
    
    -- RGB input handlers
    local function handleRGBInput()
        local r = tonumber(rInput.Text) or 0
        local g = tonumber(gInput.Text) or 0
        local b = tonumber(bInput.Text) or 0
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b = math.clamp(b, 0, 255)
        updateColor(Color3.fromRGB(r, g, b))
    end
    
    rInput.FocusLost:Connect(handleRGBInput)
    gInput.FocusLost:Connect(handleRGBInput)
    bInput.FocusLost:Connect(handleRGBInput)
    
    -- Toggle picker
    pickerButton.MouseButton1Click:Connect(function()
        open = not open
        Utility.PlaySound(Sounds.Click, 0.4)
        
        if open then
            Utility.Tween(colorPicker, {Size = UDim2.new(1, 0, 0, 310)}, 0.3)
            Utility.Tween(pickerContainer, {Size = UDim2.new(1, -10, 0, 260)}, 0.3)
        else
            Utility.Tween(colorPicker, {Size = UDim2.new(1, 0, 0, 38)}, 0.3)
            Utility.Tween(pickerContainer, {Size = UDim2.new(1, -10, 0, 0)}, 0.3)
        end
    end)
    
    -- Initialize
    updateColor(currentColor, true)
    
    -- Return color picker object
    local pickerObj = {Frame = colorPicker}
    
    function pickerObj:Set(color)
        updateColor(color)
    end
    
    function pickerObj:Get()
        return currentColor
    end
    
    if flag then
        ui.Elements[flag] = pickerObj
    end
    
    return pickerObj
end

-- Textbox Element
function NexusUI.CreateTextbox(ui, tab, options)
    options = options or {}
    
    local default = options.Default or ""
    local placeholder = options.Placeholder or "Enter text..."
    local flag = options.Flag
    
    local textbox = Utility.Create("Frame", {
        Name = "Textbox",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = textbox
    })
    
    local textboxTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = textbox,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Textbox",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local textboxInput = Utility.Create("TextBox", {
        Name = "Input",
        Parent = textbox,
        BackgroundColor3 = ui.Theme.Background,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0.55, -10, 0, 26),
        Font = Enum.Font.Gotham,
        PlaceholderText = placeholder,
        PlaceholderColor3 = ui.Theme.TextDark,
        Text = default,
        TextColor3 = ui.Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = textboxInput
    })
    
    local inputStroke = Utility.Create("UIStroke", {
        Parent = textboxInput,
        Color = ui.Theme.Primary,
        Thickness = 1,
        Transparency = 0.7
    })
    
    textboxInput.Focused:Connect(function()
        Utility.Tween(inputStroke, {Transparency = 0}, 0.2)
        Utility.PlaySound(Sounds.Click, 0.3)
    end)
    
    textboxInput.FocusLost:Connect(function(enterPressed)
        Utility.Tween(inputStroke, {Transparency = 0.7}, 0.2)
        
        if flag then
            ui.ConfigData[flag] = textboxInput.Text
        end
        
        if options.Callback then
            options.Callback(textboxInput.Text, enterPressed)
        end
    end)
    
    -- Return textbox object
    local textboxObj = {Frame = textbox}
    
    function textboxObj:Set(value)
        textboxInput.Text = value
        if flag then
            ui.ConfigData[flag] = value
        end
    end
    
    function textboxObj:Get()
        return textboxInput.Text
    end
    
    if flag then
        ui.Elements[flag] = textboxObj
    end
    
    return textboxObj
end

-- Keybind Element
function NexusUI.CreateKeybind(ui, tab, options)
    options = options or {}
    
    local default = options.Default or Enum.KeyCode.Unknown
    local flag = options.Flag
    local currentKey = default
    local listening = false
    
    local keybind = Utility.Create("Frame", {
        Name = "Keybind",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = keybind
    })
    
    local keybindTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = keybind,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Name or "Keybind",
        TextColor3 = ui.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local keybindButton = Utility.Create("TextButton", {
        Name = "Button",
        Parent = keybind,
        BackgroundColor3 = ui.Theme.Background,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 26),
        Font = Enum.Font.Gotham,
        Text = currentKey.Name,
        TextColor3 = ui.Theme.Primary,
        TextSize = 12,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = keybindButton
    })
    
    local buttonStroke = Utility.Create("UIStroke", {
        Parent = keybindButton,
        Color = ui.Theme.Primary,
        Thickness = 1,
        Transparency = 0.7
    })
    
    keybindButton.MouseButton1Click:Connect(function()
        listening = true
        keybindButton.Text = "..."
        Utility.Tween(buttonStroke, {Transparency = 0}, 0.2)
        Utility.PlaySound(Sounds.Click, 0.4)
    end)
    
    table.insert(ui.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keybindButton.Text = currentKey.Name
                listening = false
                Utility.Tween(buttonStroke, {Transparency = 0.7}, 0.2)
                Utility.PlaySound(Sounds.Success, 0.4)
                
                if flag then
                    ui.ConfigData[flag] = currentKey.Name
                end
                
                if options.Callback then
                    options.Callback(currentKey)
                end
            end
        else
            if not processed and input.KeyCode == currentKey then
                if options.OnActivate then
                    options.OnActivate()
                end
            end
        end
    end))
    
    -- Return keybind object
    local keybindObj = {Frame = keybind}
    
    function keybindObj:Set(key)
        if type(key) == "string" then
            currentKey = Enum.KeyCode[key]
        else
            currentKey = key
        end
        keybindButton.Text = currentKey.Name
    end
    
    function keybindObj:Get()
        return currentKey
    end
    
    if flag then
        ui.Elements[flag] = keybindObj
    end
    
    return keybindObj
end

-- Label Element
function NexusUI.CreateLabel(ui, tab, options)
    options = options or {}
    
    local label = Utility.Create("Frame", {
        Name = "Label",
        Parent = tab.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25)
    })
    
    local labelText = Utility.Create("TextLabel", {
        Name = "Text",
        Parent = label,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = Enum.Font.Gotham,
        Text = options.Text or "Label",
        TextColor3 = ui.Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Return label object
    local labelObj = {Frame = label}
    
    function labelObj:Set(text)
        labelText.Text = text
    end
    
    return labelObj
end

-- Paragraph Element
function NexusUI.CreateParagraph(ui, tab, options)
    options = options or {}
    
    local paragraph = Utility.Create("Frame", {
        Name = "Paragraph",
        Parent = tab.Content,
        BackgroundColor3 = ui.Theme.BackgroundSecondary,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, 0, 0, 70)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = paragraph
    })
    
    local paragraphTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = paragraph,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = options.Title or "Title",
        TextColor3 = ui.Theme.Primary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local paragraphContent = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = paragraph,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 35),
        Font = Enum.Font.Gotham,
        Text = options.Content or "Content",
        TextColor3 = ui.Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    
    -- Auto-size
    local textBounds = paragraphContent.TextBounds
    paragraph.Size = UDim2.new(1, 0, 0, math.max(70, 35 + textBounds.Y + 10))
    
    -- Return paragraph object
    local paragraphObj = {Frame = paragraph}
    
    function paragraphObj:Set(title, content)
        paragraphTitle.Text = title
        paragraphContent.Text = content
    end
    
    return paragraphObj
end

-- Settings Tab (Built-in)
function NexusUI:CreateSettingsTab()
    local settingsTab = self:CreateTab({
        Name = "Settings",
        Icon = "⚙"
    })
    
    -- Config Section
    settingsTab:AddSection({Name = "Configuration"})
    
    -- Config Name Input
    local configNameInput = settingsTab:AddTextbox({
        Name = "Config Name",
        Placeholder = "Enter config name...",
        Callback = function(text)
            -- Store for save
        end
    })
    
    -- Config List
    local configList = settingsTab:AddDropdown({
        Name = "Saved Configs",
        Items = ConfigSystem:GetList(),
        Callback = function(selected)
            -- Store selected config
        end
    })
    
    -- Save Config Button
    settingsTab:AddButton({
        Name = "Save Config",
        Icon = "💾",
        Callback = function()
            local name = configNameInput:Get()
            if name and name ~= "" then
                ConfigSystem:Save(name, self.ConfigData)
                configList:Refresh(ConfigSystem:GetList())
                self:Notify({
                    Title = "Config Saved",
                    Content = "Configuration '" .. name .. "' has been saved!",
                    Duration = 3,
                    Type = "Success"
                })
            else
                self:Notify({
                    Title = "Error",
                    Content = "Please enter a config name!",
                    Duration = 3,
                    Type = "Error"
                })
            end
        end
    })
    
    -- Load Config Button
    settingsTab:AddButton({
        Name = "Load Config",
        Icon = "📂",
        Callback = function()
            local selected = configList:Get()
            if selected then
                self:LoadConfig(selected)
            else
                self:Notify({
                    Title = "Error",
                    Content = "Please select a config to load!",
                    Duration = 3,
                    Type = "Error"
                })
            end
        end
    })
    
    -- Delete Config Button
    settingsTab:AddButton({
        Name = "Delete Config",
        Icon = "🗑️",
        Callback = function()
            local selected = configList:Get()
            if selected then
                ConfigSystem:Delete(selected)
                configList:Refresh(ConfigSystem:GetList())
                self:Notify({
                    Title = "Config Deleted",
                    Content = "Configuration '" .. selected .. "' has been deleted!",
                    Duration = 3,
                    Type = "Warning"
                })
            end
        end
    })
    
    -- Auto Load Toggle
    settingsTab:AddToggle({
        Name = "Auto Load Config",
        Default = false,
        Callback = function(value)
            if value then
                local selected = configList:Get()
                if selected then
                    ConfigSystem:SetAutoLoad(selected)
                    self:Notify({
                        Title = "Auto Load Set",
                        Content = "'" .. selected .. "' will be loaded automatically!",
                        Duration = 3,
                        Type = "Success"
                    })
                end
            end
        end
    })
    
    -- UI Section
    settingsTab:AddSection({Name = "Interface"})
    
    -- Transparency Slider
    settingsTab:AddSlider({
        Name = "UI Transparency",
        Min = 0,
        Max = 0.9,
        Default = self.Transparency,
        Increment = 0.05,
        Callback = function(value)
            self.Transparency = value
            self.MainFrame.BackgroundTransparency = value
        end
    })
    
    -- Rainbow Border Toggle
    settingsTab:AddToggle({
        Name = "Rainbow Border",
        Default = self.RainbowBorder,
        Callback = function(value)
            self.RainbowBorder = value
            if value then
                RainbowHandler:Register(self.MainStroke)
                RainbowHandler:Start()
            else
                RainbowHandler:Unregister(self.MainStroke)
                self.MainStroke.Color = self.Theme.Primary
            end
        end
    })
    
    -- Sound Toggle
    settingsTab:AddToggle({
        Name = "UI Sounds",
        Default = Config.SoundEnabled,
        Callback = function(value)
            Config.SoundEnabled = value
        end
    })
    
    -- Theme Color
    settingsTab:AddColorPicker({
        Name = "Theme Color",
        Default = self.Theme.Primary,
        Callback = function(color)
            self.Theme.Primary = color
            -- Update UI elements with new color
        end
    })
    
    -- Actions Section
    settingsTab:AddSection({Name = "Actions"})
    
    -- Rejoin Button
    settingsTab:AddButton({
        Name = "Rejoin Server",
        Icon = "🔄",
        Callback = function()
            self:Notify({
                Title = "Rejoining",
                Content = "Teleporting back to server...",
                Duration = 2,
                Type = "Warning"
            })
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    -- Close All Button
    settingsTab:AddButton({
        Name = "Close All Features",
        Icon = "⏹️",
        Callback = function()
            -- Disable all toggles
            for flag, element in pairs(self.Elements) do
                if element.Set and type(element.Frame) == "userdata" then
                    local toggle = element.Frame:FindFirstChild("ToggleContainer")
                    if toggle then
                        element:Set(false)
                    end
                end
            end
            self:Notify({
                Title = "All Disabled",
                Content = "All features have been disabled!",
                Duration = 3,
                Type = "Success"
            })
        end
    })
    
    -- Destroy UI Button
    settingsTab:AddButton({
        Name = "Destroy UI",
        Icon = "❌",
        Callback = function()
            self:Destroy()
        end
    })
    
    -- Author Info
    settingsTab:AddSection({Name = "Information"})
    
    settingsTab:AddParagraph({
        Title = "NexusUI v" .. NexusUI.Version,
        Content = "Created by " .. NexusUI.Author .. "\n\nA futuristic sci-fi UI library with rainbow gradients, circular color picker, and advanced animations."
    })
    
    return settingsTab
end

-- Config Loading with Flash Effect
function NexusUI:LoadConfig(name)
    local data = ConfigSystem:Load(name, function()
        self:FlashScreen(self.Theme.Primary)
    end)
    
    if data then
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
            Content = "Configuration '" .. name .. "' has been loaded!",
            Duration = 3,
            Type = "Success"
        })
    end
end

-- Flash Screen Effect
function NexusUI:FlashScreen(color)
    local flash = Utility.Create("Frame", {
        Name = "Flash",
        Parent = self.ScreenGui,
        BackgroundColor3 = color,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 999
    })
    
    Utility.PlaySound(Sounds.Whoosh, 0.6, 1.2)
    
    Utility.Tween(flash, {BackgroundTransparency = 0.3}, 0.1)
    task.wait(0.15)
    Utility.Tween(flash, {BackgroundTransparency = 1}, 0.3)
    task.wait(0.3)
    flash:Destroy()
end

-- Notification System
function NexusUI:Notify(options)
    options = options or {}
    
    local notifContainer = self.ScreenGui:FindFirstChild("NotificationContainer")
    if not notifContainer then
        notifContainer = Utility.Create("Frame", {
            Name = "NotificationContainer",
            Parent = self.ScreenGui,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 300, 0, 400)
        })
        
        Utility.Create("UIListLayout", {
            Parent = notifContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 10)
        })
    end
    
    local typeColors = {
        Success = self.Theme.Success,
        Error = self.Theme.Error,
        Warning = self.Theme.Warning,
        Info = self.Theme.Primary
    }
    
    local typeIcons = {
        Success = "✓",
        Error = "✕",
        Warning = "⚠",
        Info = "ℹ"
    }
    
    local color = typeColors[options.Type] or self.Theme.Primary
    local icon = typeIcons[options.Type] or "ℹ"
    
    local notification = Utility.Create("Frame", {
        Name = "Notification",
        Parent = notifContainer,
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notification
    })
    
    local notifStroke = Utility.Create("UIStroke", {
        Parent = notification,
        Color = color,
        Thickness = 2,
        Transparency = 0.3
    })
    
    local notifIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(0, 25, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = color,
        TextSize = 18
    })
    
    local notifTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 10),
        Size = UDim2.new(1, -55, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = options.Title or "Notification",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local notifContent = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 32),
        Size = UDim2.new(1, -55, 0, 30),
        Font = Enum.Font.Gotham,
        Text = options.Content or "",
        TextColor3 = self.Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    local progressBar = Utility.Create("Frame", {
        Name = "Progress",
        Parent = notification,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3)
    })
    
    -- Animate in
    Utility.PlaySound(Sounds.Notification, 0.5)
    Utility.Tween(notification, {Size = UDim2.new(1, 0, 0, 70)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Progress animation
    local duration = options.Duration or 5
    Utility.Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration)
    
    -- Remove after duration
    task.delay(duration, function()
        Utility.Tween(notification, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        notification:Destroy()
    end)
end

-- Destroy UI
function NexusUI:Destroy()
    RainbowHandler:Stop()
    
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    
    if self.BlurEffect then
        self.BlurEffect:Destroy()
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Initialize and Return
return NexusUI
