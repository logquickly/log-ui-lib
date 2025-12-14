--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    VAPOR UI LIBRARY V2.0                      ║
    ║              Advanced Roblox Exploit UI Library               ║
    ║                   Similar to Vape V4 Style                    ║
    ║                                                               ║
    ║  Features:                                                    ║
    ║  • Multiple Floating Windows                                  ║
    ║  • Config System with Auto-Load                               ║
    ║  • Rainbow/Custom Borders                                     ║
    ║  • Circular Color Picker                                      ║
    ║  • Mobile Support                                             ║
    ║  • Sound Effects & Animations                                 ║
    ║  • Screen Adaptation                                          ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

-- ═══════════════════════════════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════════════════════════════

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local VaporLib = {}
VaporLib.__index = VaporLib
VaporLib.Windows = {}
VaporLib.Flags = {}
VaporLib.Connections = {}
VaporLib.ConfigFolder = "VaporUI"
VaporLib.ThemeColor = Color3.fromRGB(138, 43, 226)
VaporLib.Opened = true

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local Utility = {}

function Utility.Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

function Utility.Tween(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quart, easingDirection or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
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
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Utility.Tween(ripple, {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1}, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utility.IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utility.GetScreenSize()
    return Camera.ViewportSize
end

function Utility.Draggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or frame
    
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        
        -- Screen bounds checking
        local screenSize = Utility.GetScreenSize()
        local frameSize = frame.AbsoluteSize
        
        local clampedX = math.clamp(newPos.X.Offset, 0, screenSize.X - frameSize.X)
        local clampedY = math.clamp(newPos.Y.Offset, 0, screenSize.Y - frameSize.Y)
        
        Utility.Tween(frame, {Position = UDim2.new(0, clampedX, 0, clampedY)}, 0.1)
    end
    
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
            update(input)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- SOUND SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local SoundManager = {}
SoundManager.Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079735",
    Toggle = "rbxassetid://6895079949",
    Slider = "rbxassetid://6895079590",
    Open = "rbxassetid://6895079476",
    Close = "rbxassetid://6895079216",
    ConfigLoad = "rbxassetid://5865372628",
    ConfigSave = "rbxassetid://6895079332",
    Error = "rbxassetid://6895079098",
    Success = "rbxassetid://6895080024"
}

function SoundManager.Play(soundName, volume)
    local soundId = SoundManager.Sounds[soundName]
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- EFFECT SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local EffectManager = {}

function EffectManager.FlashScreen(color, duration)
    local flash = Utility.Create("Frame", {
        Name = "FlashEffect",
        Parent = VaporLib.ScreenGui,
        BackgroundColor3 = color or VaporLib.ThemeColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 9999
    })
    
    Utility.Tween(flash, {BackgroundTransparency = 1}, duration or 0.5)
    
    task.delay(duration or 0.5, function()
        flash:Destroy()
    end)
end

function EffectManager.Glow(frame, color, intensity)
    local glow = Utility.Create("ImageLabel", {
        Name = "Glow",
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 30, 1, 30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://5028857084",
        ImageColor3 = color or VaporLib.ThemeColor,
        ImageTransparency = 1 - (intensity or 0.3),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = frame.ZIndex - 1
    })
    return glow
end

function EffectManager.Particles(frame, color, amount)
    for i = 1, (amount or 10) do
        local particle = Utility.Create("Frame", {
            Name = "Particle",
            Parent = frame,
            BackgroundColor3 = color or VaporLib.ThemeColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6)),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            ZIndex = frame.ZIndex + 10
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle
        })
        
        local targetY = particle.Position.Y.Scale - math.random(20, 50) / 100
        Utility.Tween(particle, {
            Position = UDim2.new(particle.Position.X.Scale + (math.random(-20, 20) / 100), 0, targetY, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        }, math.random(5, 15) / 10)
        
        task.delay(1.5, function()
            particle:Destroy()
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- RAINBOW SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local RainbowManager = {}
RainbowManager.Enabled = false
RainbowManager.Speed = 1
RainbowManager.Objects = {}
RainbowManager.Hue = 0

function RainbowManager.Add(object, property)
    table.insert(RainbowManager.Objects, {Object = object, Property = property})
end

function RainbowManager.Remove(object)
    for i, v in pairs(RainbowManager.Objects) do
        if v.Object == object then
            table.remove(RainbowManager.Objects, i)
            break
        end
    end
end

function RainbowManager.Start()
    RainbowManager.Enabled = true
    task.spawn(function()
        while RainbowManager.Enabled do
            RainbowManager.Hue = (RainbowManager.Hue + 0.001 * RainbowManager.Speed) % 1
            local color = Color3.fromHSV(RainbowManager.Hue, 0.8, 1)
            
            for _, data in pairs(RainbowManager.Objects) do
                if data.Object and data.Object.Parent then
                    pcall(function()
                        data.Object[data.Property] = color
                    end)
                end
            end
            
            task.wait()
        end
    end)
end

function RainbowManager.Stop()
    RainbowManager.Enabled = false
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local ConfigManager = {}
ConfigManager.AutoLoad = true
ConfigManager.CurrentConfig = nil

function ConfigManager.GetConfigPath()
    return VaporLib.ConfigFolder
end

function ConfigManager.EnsureFolder()
    if not isfolder then return false end
    
    if not isfolder(ConfigManager.GetConfigPath()) then
        makefolder(ConfigManager.GetConfigPath())
    end
    return true
end

function ConfigManager.GetConfigs()
    if not isfolder or not listfiles then return {} end
    ConfigManager.EnsureFolder()
    
    local configs = {}
    local files = listfiles(ConfigManager.GetConfigPath())
    
    for _, file in pairs(files) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(configs, name)
        end
    end
    
    return configs
end

function ConfigManager.SaveConfig(name)
    if not writefile then 
        warn("VaporUI: File system not available")
        return false 
    end
    
    ConfigManager.EnsureFolder()
    
    local configData = {
        Flags = {},
        WindowPositions = {},
        UISettings = {
            ThemeColor = {VaporLib.ThemeColor.R, VaporLib.ThemeColor.G, VaporLib.ThemeColor.B},
            RainbowBorder = RainbowManager.Enabled,
            RainbowSpeed = RainbowManager.Speed
        }
    }
    
    -- Save flags
    for flagName, flagData in pairs(VaporLib.Flags) do
        configData.Flags[flagName] = flagData.Value
    end
    
    -- Save window positions
    for windowName, windowData in pairs(VaporLib.Windows) do
        if windowData.Frame then
            configData.WindowPositions[windowName] = {
                X = windowData.Frame.Position.X.Offset,
                Y = windowData.Frame.Position.Y.Offset
            }
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(configData)
    end)
    
    if success then
        writefile(ConfigManager.GetConfigPath() .. "/" .. name .. ".json", encoded)
        SoundManager.Play("ConfigSave")
        EffectManager.FlashScreen(Color3.fromRGB(0, 255, 0), 0.3)
        return true
    end
    
    return false
end

function ConfigManager.LoadConfig(name)
    if not readfile or not isfile then
        warn("VaporUI: File system not available")
        return false
    end
    
    local path = ConfigManager.GetConfigPath() .. "/" .. name .. ".json"
    
    if not isfile(path) then
        warn("VaporUI: Config not found: " .. name)
        return false
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    
    if not success then
        SoundManager.Play("Error")
        return false
    end
    
    -- Flash screen effect
    SoundManager.Play("ConfigLoad")
    EffectManager.FlashScreen(VaporLib.ThemeColor, 0.5)
    EffectManager.Particles(VaporLib.ScreenGui, VaporLib.ThemeColor, 30)
    
    -- Load flags
    if data.Flags then
        for flagName, value in pairs(data.Flags) do
            if VaporLib.Flags[flagName] then
                VaporLib.Flags[flagName]:Set(value)
            end
        end
    end
    
    -- Load window positions
    if data.WindowPositions then
        for windowName, pos in pairs(data.WindowPositions) do
            if VaporLib.Windows[windowName] and VaporLib.Windows[windowName].Frame then
                VaporLib.Windows[windowName].Frame.Position = UDim2.new(0, pos.X, 0, pos.Y)
            end
        end
    end
    
    -- Load UI settings
    if data.UISettings then
        if data.UISettings.ThemeColor then
            VaporLib.ThemeColor = Color3.new(
                data.UISettings.ThemeColor[1],
                data.UISettings.ThemeColor[2],
                data.UISettings.ThemeColor[3]
            )
        end
        
        if data.UISettings.RainbowBorder then
            RainbowManager.Start()
        end
        
        if data.UISettings.RainbowSpeed then
            RainbowManager.Speed = data.UISettings.RainbowSpeed
        end
    end
    
    ConfigManager.CurrentConfig = name
    return true
end

function ConfigManager.DeleteConfig(name)
    if not delfile then return false end
    
    local path = ConfigManager.GetConfigPath() .. "/" .. name .. ".json"
    
    if isfile(path) then
        delfile(path)
        return true
    end
    
    return false
end

function ConfigManager.SetAutoLoad(configName)
    if not writefile then return false end
    
    ConfigManager.EnsureFolder()
    writefile(ConfigManager.GetConfigPath() .. "/autoload.txt", configName)
    return true
end

function ConfigManager.GetAutoLoad()
    if not readfile or not isfile then return nil end
    
    local path = ConfigManager.GetConfigPath() .. "/autoload.txt"
    
    if isfile(path) then
        return readfile(path)
    end
    
    return nil
end

function ConfigManager.TryAutoLoad()
    local autoLoadConfig = ConfigManager.GetAutoLoad()
    if autoLoadConfig then
        task.delay(0.5, function()
            ConfigManager.LoadConfig(autoLoadConfig)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- LOADING ANIMATION
-- ═══════════════════════════════════════════════════════════════════

local LoadingScreen = {}

function LoadingScreen.Show(callback)
    local screenGui = Utility.Create("ScreenGui", {
        Name = "VaporLoadingScreen",
        Parent = (syn and syn.protect_gui and gethui()) or game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    local background = Utility.Create("Frame", {
        Name = "Background",
        Parent = screenGui,
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    local container = Utility.Create("Frame", {
        Name = "Container",
        Parent = background,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 300, 0, 200),
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    -- Logo
    local logo = Utility.Create("TextLabel", {
        Name = "Logo",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.3, 0),
        Size = UDim2.new(1, 0, 0, 50),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "VAPOR UI",
        TextColor3 = VaporLib.ThemeColor,
        TextSize = 36,
        TextTransparency = 1
    })
    
    -- Loading bar container
    local barContainer = Utility.Create("Frame", {
        Name = "BarContainer",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.6, 0),
        Size = UDim2.new(0.8, 0, 0, 6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = barContainer
    })
    
    local bar = Utility.Create("Frame", {
        Name = "Bar",
        Parent = barContainer,
        BackgroundColor3 = VaporLib.ThemeColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = bar
    })
    
    Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, VaporLib.ThemeColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        }),
        Parent = bar
    })
    
    -- Status text
    local status = Utility.Create("TextLabel", {
        Name = "Status",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.75, 0),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Font = Enum.Font.Gotham,
        Text = "Initializing...",
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 14,
        TextTransparency = 1
    })
    
    -- Particles
    for i = 1, 20 do
        local particle = Utility.Create("Frame", {
            Name = "Particle" .. i,
            Parent = background,
            BackgroundColor3 = VaporLib.ThemeColor,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5)),
            Position = UDim2.new(math.random(), 0, 1.1, 0)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle
        })
        
        -- Animate particles
        task.spawn(function()
            while particle.Parent do
                local duration = math.random(3, 8)
                local tween = Utility.Tween(particle, {
                    Position = UDim2.new(math.random(), 0, -0.1, 0)
                }, duration, Enum.EasingStyle.Linear)
                tween.Completed:Wait()
                particle.Position = UDim2.new(math.random(), 0, 1.1, 0)
            end
        end)
    end
    
    -- Animation sequence
    task.spawn(function()
        -- Fade in logo
        Utility.Tween(logo, {TextTransparency = 0}, 0.5)
        task.wait(0.3)
        
        -- Fade in status
        Utility.Tween(status, {TextTransparency = 0}, 0.3)
        
        -- Loading stages
        local stages = {
            {progress = 0.2, text = "Loading modules..."},
            {progress = 0.4, text = "Initializing UI..."},
            {progress = 0.6, text = "Setting up components..."},
            {progress = 0.8, text = "Preparing interface..."},
            {progress = 1.0, text = "Complete!"}
        }
        
        for _, stage in ipairs(stages) do
            Utility.Tween(bar, {Size = UDim2.new(stage.progress, 0, 1, 0)}, 0.4)
            status.Text = stage.text
            task.wait(0.3)
        end
        
        task.wait(0.3)
        
        -- Fade out
        Utility.Tween(background, {BackgroundTransparency = 1}, 0.5)
        Utility.Tween(logo, {TextTransparency = 1}, 0.3)
        Utility.Tween(status, {TextTransparency = 1}, 0.3)
        Utility.Tween(barContainer, {BackgroundTransparency = 1}, 0.3)
        Utility.Tween(bar, {BackgroundTransparency = 1}, 0.3)
        
        task.wait(0.5)
        screenGui:Destroy()
        
        if callback then
            callback()
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN LIBRARY
-- ═══════════════════════════════════════════════════════════════════

function VaporLib:Init(config)
    config = config or {}
    self.Title = config.Title or "Vapor UI"
    self.ThemeColor = config.ThemeColor or Color3.fromRGB(138, 43, 226)
    self.ConfigFolder = config.ConfigFolder or "VaporUI"
    
    -- Create main ScreenGui
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "VaporUI",
        Parent = (syn and syn.protect_gui and gethui()) or game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    -- Mobile toggle button
    if Utility.IsMobile() then
        self:CreateMobileToggle()
    end
    
    -- Keybind to toggle UI
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
            self:Toggle()
        end
    end)
    
    -- Show loading screen
    LoadingScreen.Show(function()
        SoundManager.Play("Open")
        ConfigManager.TryAutoLoad()
    end)
    
    return self
end

function VaporLib:CreateMobileToggle()
    local toggleBtn = Utility.Create("ImageButton", {
        Name = "MobileToggle",
        Parent = self.ScreenGui,
        BackgroundColor3 = self.ThemeColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 45, 0, 45),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(324, 124),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = toggleBtn
    })
    
    Utility.Draggable(toggleBtn)
    
    toggleBtn.MouseButton1Click:Connect(function()
        SoundManager.Play("Click")
        self:Toggle()
    end)
end

function VaporLib:Toggle()
    self.Opened = not self.Opened
    SoundManager.Play(self.Opened and "Open" or "Close")
    
    for _, windowData in pairs(self.Windows) do
        if windowData.Frame then
            Utility.Tween(windowData.Frame, {
                Size = self.Opened and windowData.OriginalSize or UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = self.Opened and 0.05 or 1
            }, 0.3)
            
            for _, child in pairs(windowData.Frame:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    Utility.Tween(child, {TextTransparency = self.Opened and 0 or 1}, 0.2)
                elseif child:IsA("Frame") and child.Name ~= "Border" then
                    Utility.Tween(child, {BackgroundTransparency = self.Opened and (child:GetAttribute("OriginalTransparency") or 0) or 1}, 0.2)
                elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    Utility.Tween(child, {ImageTransparency = self.Opened and 0 or 1}, 0.2)
                end
            end
        end
    end
end

function VaporLib:Destroy()
    RainbowManager.Stop()
    
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- WINDOW SYSTEM
-- ═══════════════════════════════════════════════════════════════════

function VaporLib:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Window"
    local windowSize = config.Size or UDim2.new(0, 220, 0, 350)
    local windowPosition = config.Position
    
    -- Calculate position for mobile (grid layout)
    if not windowPosition then
        local windowCount = 0
        for _ in pairs(self.Windows) do
            windowCount = windowCount + 1
        end
        
        local screenSize = Utility.GetScreenSize()
        local isMobile = Utility.IsMobile()
        local columns = isMobile and 2 or 4
        local padding = 10
        
        local col = windowCount % columns
        local row = math.floor(windowCount / columns)
        
        local startX = padding
        local startY = padding
        
        local windowWidth = windowSize.X.Offset
        local windowHeight = windowSize.Y.Offset
        
        local x = startX + (col * (windowWidth + padding))
        local y = startY + (row * (windowHeight + padding))
        
        -- Check if exceeds screen
        if x + windowWidth > screenSize.X then
            x = padding
            y = y + windowHeight + padding
        end
        
        windowPosition = UDim2.new(0, x, 0, y)
    end
    
    local Window = {}
    Window.Name = windowName
    Window.Elements = {}
    Window.Sections = {}
    
    -- Main window frame
    Window.Frame = Utility.Create("Frame", {
        Name = windowName,
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),
        BorderSizePixel = 0,
        Position = windowPosition,
        Size = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true
    })
    
    Window.OriginalSize = windowSize
    
    -- Window corner
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Window.Frame
    })
    
    -- Border
    Window.Border = Utility.Create("UIStroke", {
        Name = "Border",
        Parent = Window.Frame,
        Color = self.ThemeColor,
        Thickness = 2
    })
    
    -- Add to rainbow if enabled
    RainbowManager.Add(Window.Border, "Color")
    
    -- Title bar
    Window.TitleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Parent = Window.Frame,
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Window.TitleBar
    })
    
    -- Title cover for bottom corners
    Utility.Create("Frame", {
        Name = "BottomCover",
        Parent = Window.TitleBar,
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8)
    })
    
    -- Title text
    Window.TitleText = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = Window.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = windowName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Close button
    local closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        Parent = Window.TitleBar,
        BackgroundColor3 = Color3.fromRGB(255, 70, 70),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        SoundManager.Play("Close")
        Utility.Tween(Window.Frame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    end)
    
    -- Minimize button
    local minimizeBtn = Utility.Create("TextButton", {
        Name = "Minimize",
        Parent = Window.TitleBar,
        BackgroundColor3 = Color3.fromRGB(255, 180, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = minimizeBtn
    })
    
    Window.Minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        SoundManager.Play("Click")
        
        if Window.Minimized then
            Utility.Tween(Window.Frame, {Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 35)}, 0.3)
        else
            Utility.Tween(Window.Frame, {Size = windowSize}, 0.3)
        end
    end)
    
    -- Content container
    Window.Content = Utility.Create("ScrollingFrame", {
        Name = "Content",
        Parent = Window.Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 40),
        Size = UDim2.new(1, -10, 1, -45),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.ThemeColor,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    Utility.Create("UIListLayout", {
        Parent = Window.Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    Utility.Create("UIPadding", {
        Parent = Window.Content,
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5)
    })
    
    -- Make window draggable
    Utility.Draggable(Window.Frame, Window.TitleBar)
    
    -- Animate window open
    Utility.Tween(Window.Frame, {Size = windowSize}, 0.5, Enum.EasingStyle.Back)
    
    -- Store window
    self.Windows[windowName] = Window
    
    -- ═══════════════════════════════════════════════════════════════
    -- WINDOW ELEMENTS
    -- ═══════════════════════════════════════════════════════════════
    
    function Window:CreateSection(name)
        local Section = {}
        Section.Name = name
        
        local sectionFrame = Utility.Create("Frame", {
            Name = name,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(30, 30, 35),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = sectionFrame
        })
        
        Utility.Create("TextLabel", {
            Parent = sectionFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "▼ " .. name,
            TextColor3 = VaporLib.ThemeColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        Section.Frame = sectionFrame
        table.insert(Window.Sections, Section)
        
        return Section
    end
    
    -- Button
    function Window:CreateButton(config)
        config = config or {}
        local buttonName = config.Name or "Button"
        local callback = config.Callback or function() end
        
        local buttonFrame = Utility.Create("Frame", {
            Name = buttonName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35),
            ClipsDescendants = true
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = buttonFrame
        })
        
        local button = Utility.Create("TextButton", {
            Name = "Button",
            Parent = buttonFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = buttonName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13
        })
        
        button.MouseEnter:Connect(function()
            SoundManager.Play("Hover", 0.3)
            Utility.Tween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            Utility.Tween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2)
        end)
        
        button.MouseButton1Click:Connect(function()
            SoundManager.Play("Click")
            Utility.Ripple(buttonFrame, Mouse.X, Mouse.Y)
            callback()
        end)
        
        return buttonFrame
    end
    
    -- Toggle
    function Window:CreateToggle(config)
        config = config or {}
        local toggleName = config.Name or "Toggle"
        local default = config.Default or false
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local Toggle = {Value = default}
        
        local toggleFrame = Utility.Create("Frame", {
            Name = toggleName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = toggleFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = toggleFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = toggleName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local toggleButton = Utility.Create("Frame", {
            Name = "ToggleButton",
            Parent = toggleFrame,
            BackgroundColor3 = Color3.fromRGB(50, 50, 55),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -45, 0.5, 0),
            Size = UDim2.new(0, 35, 0, 18),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = toggleButton
        })
        
        local indicator = Utility.Create("Frame", {
            Name = "Indicator",
            Parent = toggleButton,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 14, 0, 14),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = indicator
        })
        
        local function updateToggle()
            if Toggle.Value then
                Utility.Tween(toggleButton, {BackgroundColor3 = VaporLib.ThemeColor}, 0.2)
                Utility.Tween(indicator, {Position = UDim2.new(1, -16, 0.5, 0)}, 0.2)
            else
                Utility.Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}, 0.2)
                Utility.Tween(indicator, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.2)
            end
        end
        
        function Toggle:Set(value)
            Toggle.Value = value
            updateToggle()
            callback(value)
        end
        
        toggleFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                SoundManager.Play("Toggle")
                Toggle.Value = not Toggle.Value
                updateToggle()
                callback(Toggle.Value)
            end
        end)
        
        -- Set default
        updateToggle()
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = Toggle
        end
        
        table.insert(Window.Elements, Toggle)
        return Toggle
    end
    
    -- Slider
    function Window:CreateSlider(config)
        config = config or {}
        local sliderName = config.Name or "Slider"
        local min = config.Min or 0
        local max = config.Max or 100
        local default = config.Default or min
        local increment = config.Increment or 1
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local Slider = {Value = default}
        
        local sliderFrame = Utility.Create("Frame", {
            Name = sliderName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 50)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = sliderFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = sliderFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(0.6, 0, 0, 15),
            Font = Enum.Font.GothamSemibold,
            Text = sliderName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local valueLabel = Utility.Create("TextLabel", {
            Parent = sliderFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -50, 0, 5),
            Size = UDim2.new(0, 40, 0, 15),
            Font = Enum.Font.GothamSemibold,
            Text = tostring(default),
            TextColor3 = VaporLib.ThemeColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        
        local sliderBar = Utility.Create("Frame", {
            Name = "SliderBar",
            Parent = sliderFrame,
            BackgroundColor3 = Color3.fromRGB(50, 50, 55),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 0, 8)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = sliderBar
        })
        
        local sliderFill = Utility.Create("Frame", {
            Name = "Fill",
            Parent = sliderBar,
            BackgroundColor3 = VaporLib.ThemeColor,
            BorderSizePixel = 0,
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = sliderFill
        })
        
        local sliderButton = Utility.Create("Frame", {
            Name = "Button",
            Parent = sliderBar,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
            Size = UDim2.new(0, 14, 0, 14),
            AnchorPoint = Vector2.new(0.5, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = sliderButton
        })
        
        local dragging = false
        
        local function updateSlider(input)
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
            value = math.clamp(value, min, max)
            
            Slider.Value = value
            valueLabel.Text = tostring(value)
            
            Utility.Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
            Utility.Tween(sliderButton, {Position = UDim2.new(pos, 0, 0.5, 0)}, 0.1)
            
            callback(value)
        end
        
        function Slider:Set(value)
            value = math.clamp(value, min, max)
            Slider.Value = value
            valueLabel.Text = tostring(value)
            
            local pos = (value - min) / (max - min)
            Utility.Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.2)
            Utility.Tween(sliderButton, {Position = UDim2.new(pos, 0, 0.5, 0)}, 0.2)
            
            callback(value)
        end
        
        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                SoundManager.Play("Slider", 0.3)
                updateSlider(input)
            end
        end)
        
        sliderBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = Slider
        end
        
        table.insert(Window.Elements, Slider)
        return Slider
    end
    
    -- Dropdown
    function Window:CreateDropdown(config)
        config = config or {}
        local dropdownName = config.Name or "Dropdown"
        local options = config.Options or {}
        local default = config.Default or options[1]
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local Dropdown = {Value = default, Options = options, Open = false}
        
        local dropdownFrame = Utility.Create("Frame", {
            Name = dropdownName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35),
            ClipsDescendants = true
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = dropdownFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = dropdownFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0.5, 0, 0, 35),
            Font = Enum.Font.GothamSemibold,
            Text = dropdownName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local selectedLabel = Utility.Create("TextLabel", {
            Parent = dropdownFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, -30, 0, 35),
            Font = Enum.Font.Gotham,
            Text = default or "Select...",
            TextColor3 = VaporLib.ThemeColor,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        
        local arrow = Utility.Create("TextLabel", {
            Parent = dropdownFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -25, 0, 0),
            Size = UDim2.new(0, 20, 0, 35),
            Font = Enum.Font.GothamBold,
            Text = "▼",
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 10
        })
        
        local optionsContainer = Utility.Create("Frame", {
            Name = "Options",
            Parent = dropdownFrame,
            BackgroundColor3 = Color3.fromRGB(30, 30, 35),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 5, 0, 40),
            Size = UDim2.new(1, -10, 0, 0),
            ClipsDescendants = true
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = optionsContainer
        })
        
        Utility.Create("UIListLayout", {
            Parent = optionsContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        })
        
        local function createOption(optionName)
            local optionBtn = Utility.Create("TextButton", {
                Name = optionName,
                Parent = optionsContainer,
                BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 25),
                Font = Enum.Font.Gotham,
                Text = optionName,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 11
            })
            
            Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = optionBtn
            })
            
            optionBtn.MouseEnter:Connect(function()
                Utility.Tween(optionBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}, 0.1)
            end)
            
            optionBtn.MouseLeave:Connect(function()
                Utility.Tween(optionBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}, 0.1)
            end)
            
            optionBtn.MouseButton1Click:Connect(function()
                SoundManager.Play("Click")
                Dropdown.Value = optionName
                selectedLabel.Text = optionName
                Dropdown:Toggle()
                callback(optionName)
            end)
        end
        
        for _, option in ipairs(options) do
            createOption(option)
        end
        
        function Dropdown:Toggle()
            Dropdown.Open = not Dropdown.Open
            SoundManager.Play("Click", 0.3)
            
            local optionCount = #Dropdown.Options
            local targetHeight = Dropdown.Open and (35 + 5 + (optionCount * 27)) or 35
            
            Utility.Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
            Utility.Tween(arrow, {Rotation = Dropdown.Open and 180 or 0}, 0.3)
        end
        
        function Dropdown:Set(value)
            if table.find(Dropdown.Options, value) then
                Dropdown.Value = value
                selectedLabel.Text = value
                callback(value)
            end
        end
        
        function Dropdown:Refresh(newOptions)
            Dropdown.Options = newOptions
            
            for _, child in pairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            for _, option in ipairs(newOptions) do
                createOption(option)
            end
        end
        
        dropdownFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local relativeY = input.Position.Y - dropdownFrame.AbsolutePosition.Y
                if relativeY <= 35 then
                    Dropdown:Toggle()
                end
            end
        end)
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = Dropdown
        end
        
        table.insert(Window.Elements, Dropdown)
        return Dropdown
    end
    
    -- Color Picker (Circular)
    function Window:CreateColorPicker(config)
        config = config or {}
        local pickerName = config.Name or "Color Picker"
        local default = config.Default or Color3.fromRGB(255, 255, 255)
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local ColorPicker = {Value = default, Open = false}
        
        local pickerFrame = Utility.Create("Frame", {
            Name = pickerName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35),
            ClipsDescendants = true
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = pickerFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = pickerFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -50, 0, 35),
            Font = Enum.Font.GothamSemibold,
            Text = pickerName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local colorPreview = Utility.Create("Frame", {
            Name = "Preview",
            Parent = pickerFrame,
            BackgroundColor3 = default,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -35, 0.5, 0),
            Size = UDim2.new(0, 25, 0, 25),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = colorPreview
        })
        
        Utility.Create("UIStroke", {
            Parent = colorPreview,
            Color = Color3.fromRGB(60, 60, 65),
            Thickness = 1
        })
        
        -- Color wheel container
        local wheelContainer = Utility.Create("Frame", {
            Name = "WheelContainer",
            Parent = pickerFrame,
            BackgroundColor3 = Color3.fromRGB(30, 30, 35),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 45),
            Size = UDim2.new(0, 150, 0, 150),
            AnchorPoint = Vector2.new(0.5, 0)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = wheelContainer
        })
        
        -- Color wheel image
        local colorWheel = Utility.Create("ImageLabel", {
            Name = "ColorWheel",
            Parent = wheelContainer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 140, 0, 140),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://6020299385"
        })
        
        local wheelIndicator = Utility.Create("Frame", {
            Name = "Indicator",
            Parent = colorWheel,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 10, 0, 10),
            AnchorPoint = Vector2.new(0.5, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = wheelIndicator
        })
        
        Utility.Create("UIStroke", {
            Parent = wheelIndicator,
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2
        })
        
        -- Brightness slider
        local brightnessBar = Utility.Create("Frame", {
            Name = "BrightnessBar",
            Parent = pickerFrame,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 205),
            Size = UDim2.new(0, 140, 0, 15),
            AnchorPoint = Vector2.new(0.5, 0)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = brightnessBar
        })
        
        Utility.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            }),
            Parent = brightnessBar
        })
        
        local brightnessIndicator = Utility.Create("Frame", {
            Name = "Indicator",
            Parent = brightnessBar,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 8, 0, 20),
            AnchorPoint = Vector2.new(0.5, 0.5)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = brightnessIndicator
        })
        
        local hue, sat, val = 0, 1, 1
        
        local function updateColor()
            local color = Color3.fromHSV(hue, sat, val)
            ColorPicker.Value = color
            colorPreview.BackgroundColor3 = color
            callback(color)
        end
        
        local wheelDragging = false
        local brightnessDragging = false
        
        colorWheel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                wheelDragging = true
            end
        end)
        
        colorWheel.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                wheelDragging = false
            end
        end)
        
        brightnessBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                brightnessDragging = true
            end
        end)
        
        brightnessBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                brightnessDragging = false
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
                    
                    if distance > radius then
                        dx = dx / distance * radius
                        dy = dy / distance * radius
                        distance = radius
                    end
                    
                    hue = (math.atan2(dy, dx) / (2 * math.pi) + 0.5) % 1
                    sat = math.clamp(distance / radius, 0, 1)
                    
                    wheelIndicator.Position = UDim2.new(0.5 + dx / colorWheel.AbsoluteSize.X, 0, 0.5 + dy / colorWheel.AbsoluteSize.Y, 0)
                    updateColor()
                end
                
                if brightnessDragging then
                    val = math.clamp((input.Position.X - brightnessBar.AbsolutePosition.X) / brightnessBar.AbsoluteSize.X, 0, 1)
                    brightnessIndicator.Position = UDim2.new(val, 0, 0.5, 0)
                    updateColor()
                end
            end
        end)
        
        function ColorPicker:Toggle()
            ColorPicker.Open = not ColorPicker.Open
            SoundManager.Play("Click", 0.3)
            
            local targetHeight = ColorPicker.Open and 240 or 35
            Utility.Tween(pickerFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
        end
        
        function ColorPicker:Set(color)
            ColorPicker.Value = color
            colorPreview.BackgroundColor3 = color
            
            local h, s, v = Color3.toHSV(color)
            hue, sat, val = h, s, v
            
            local angle = hue * 2 * math.pi
            local radius = sat * (colorWheel.AbsoluteSize.X / 2)
            local dx = math.cos(angle) * radius
            local dy = math.sin(angle) * radius
            
            wheelIndicator.Position = UDim2.new(0.5 + dx / colorWheel.AbsoluteSize.X, 0, 0.5 + dy / colorWheel.AbsoluteSize.Y, 0)
            brightnessIndicator.Position = UDim2.new(val, 0, 0.5, 0)
            
            callback(color)
        end
        
        pickerFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local relativeY = input.Position.Y - pickerFrame.AbsolutePosition.Y
                if relativeY <= 35 then
                    ColorPicker:Toggle()
                end
            end
        end)
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = ColorPicker
        end
        
        table.insert(Window.Elements, ColorPicker)
        return ColorPicker
    end
    
    -- Text Input
    function Window:CreateTextbox(config)
        config = config or {}
        local textboxName = config.Name or "Textbox"
        local default = config.Default or ""
        local placeholder = config.Placeholder or "Enter text..."
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local Textbox = {Value = default}
        
        local textboxFrame = Utility.Create("Frame", {
            Name = textboxName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 55)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = textboxFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = textboxFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 15),
            Font = Enum.Font.GothamSemibold,
            Text = textboxName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local inputFrame = Utility.Create("Frame", {
            Parent = textboxFrame,
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 25),
            Size = UDim2.new(1, -20, 0, 25)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = inputFrame
        })
        
        local textBox = Utility.Create("TextBox", {
            Parent = inputFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Font = Enum.Font.Gotham,
            Text = default,
            PlaceholderText = placeholder,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false
        })
        
        textBox.FocusLost:Connect(function(enterPressed)
            Textbox.Value = textBox.Text
            callback(textBox.Text, enterPressed)
        end)
        
        function Textbox:Set(value)
            Textbox.Value = value
            textBox.Text = value
            callback(value)
        end
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = Textbox
        end
        
        table.insert(Window.Elements, Textbox)
        return Textbox
    end
    
    -- Keybind
    function Window:CreateKeybind(config)
        config = config or {}
        local keybindName = config.Name or "Keybind"
        local default = config.Default or Enum.KeyCode.Unknown
        local flag = config.Flag
        local callback = config.Callback or function() end
        
        local Keybind = {Value = default, Listening = false}
        
        local keybindFrame = Utility.Create("Frame", {
            Name = keybindName,
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 35)
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = keybindFrame
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = keybindFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0.6, 0, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = keybindName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local keyButton = Utility.Create("TextButton", {
            Parent = keybindFrame,
            BackgroundColor3 = Color3.fromRGB(45, 45, 50),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -70, 0.5, 0),
            Size = UDim2.new(0, 60, 0, 25),
            AnchorPoint = Vector2.new(0, 0.5),
            Font = Enum.Font.Gotham,
            Text = default.Name,
            TextColor3 = VaporLib.ThemeColor,
            TextSize = 11
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = keyButton
        })
        
        keyButton.MouseButton1Click:Connect(function()
            Keybind.Listening = true
            keyButton.Text = "..."
            SoundManager.Play("Click")
        end)
        
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            
            if Keybind.Listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Keybind.Value = input.KeyCode
                    keyButton.Text = input.KeyCode.Name
                    Keybind.Listening = false
                    SoundManager.Play("Toggle")
                end
            else
                if input.KeyCode == Keybind.Value then
                    callback(Keybind.Value)
                end
            end
        end)
        
        function Keybind:Set(key)
            Keybind.Value = key
            keyButton.Text = key.Name
        end
        
        -- Register flag
        if flag then
            VaporLib.Flags[flag] = Keybind
        end
        
        table.insert(Window.Elements, Keybind)
        return Keybind
    end
    
    -- Label
    function Window:CreateLabel(text)
        local labelFrame = Utility.Create("Frame", {
            Name = "Label",
            Parent = Window.Content,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25)
        })
        
        local label = Utility.Create("TextLabel", {
            Parent = labelFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = text,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Label = {}
        
        function Label:Set(newText)
            label.Text = newText
        end
        
        return Label
    end
    
    -- Paragraph
    function Window:CreateParagraph(config)
        config = config or {}
        local title = config.Title or "Paragraph"
        local content = config.Content or ""
        
        local paraFrame = Utility.Create("Frame", {
            Name = "Paragraph",
            Parent = Window.Content,
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 60),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = paraFrame
        })
        
        local titleLabel = Utility.Create("TextLabel", {
            Parent = paraFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = VaporLib.ThemeColor,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local contentLabel = Utility.Create("TextLabel", {
            Parent = paraFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 25),
            Size = UDim2.new(1, -20, 0, 0),
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        
        local Paragraph = {}
        
        function Paragraph:Set(newTitle, newContent)
            titleLabel.Text = newTitle or titleLabel.Text
            contentLabel.Text = newContent or contentLabel.Text
        end
        
        return Paragraph
    end
    
    return Window
end

-- ═══════════════════════════════════════════════════════════════════
-- SETTINGS WINDOW
-- ═══════════════════════════════════════════════════════════════════

function VaporLib:CreateSettingsWindow()
    local Settings = self:CreateWindow({
        Name = "⚙ Settings",
        Size = UDim2.new(0, 250, 0, 400)
    })
    
    -- Config Section
    Settings:CreateSection("Config System")
    
    -- Config name input
    local configNameBox = Settings:CreateTextbox({
        Name = "Config Name",
        Placeholder = "Enter config name..."
    })
    
    -- Save Config
    Settings:CreateButton({
        Name = "💾 Save Config",
        Callback = function()
            local name = configNameBox.Value
            if name and name ~= "" then
                if ConfigManager.SaveConfig(name) then
                    SoundManager.Play("Success")
                else
                    SoundManager.Play("Error")
                end
            end
        end
    })
    
    -- Config list dropdown
    local configDropdown = Settings:CreateDropdown({
        Name = "Saved Configs",
        Options = ConfigManager.GetConfigs(),
        Callback = function(selected)
            configNameBox:Set(selected)
        end
    })
    
    -- Load Config
    Settings:CreateButton({
        Name = "📂 Load Config",
        Callback = function()
            local name = configNameBox.Value
            if name and name ~= "" then
                ConfigManager.LoadConfig(name)
            end
        end
    })
    
    -- Delete Config
    Settings:CreateButton({
        Name = "🗑 Delete Config",
        Callback = function()
            local name = configNameBox.Value
            if name and name ~= "" then
                if ConfigManager.DeleteConfig(name) then
                    SoundManager.Play("Success")
                    configDropdown:Refresh(ConfigManager.GetConfigs())
                end
            end
        end
    })
    
    -- Auto Load Toggle
    Settings:CreateToggle({
        Name = "Auto Load Config",
        Default = false,
        Callback = function(value)
            if value then
                local name = configNameBox.Value
                if name and name ~= "" then
                    ConfigManager.SetAutoLoad(name)
                end
            end
        end
    })
    
    -- Refresh configs
    Settings:CreateButton({
        Name = "🔄 Refresh Configs",
        Callback = function()
            configDropdown:Refresh(ConfigManager.GetConfigs())
            SoundManager.Play("Click")
        end
    })
    
    -- UI Settings Section
    Settings:CreateSection("UI Customization")
    
    -- Theme Color
    Settings:CreateColorPicker({
        Name = "Theme Color",
        Default = self.ThemeColor,
        Callback = function(color)
            self.ThemeColor = color
            
            -- Update all borders
            for _, window in pairs(self.Windows) do
                if window.Border then
                    window.Border.Color = color
                end
            end
        end
    })
    
    -- Rainbow Border
    Settings:CreateToggle({
        Name = "Rainbow Border",
        Default = false,
        Callback = function(value)
            if value then
                RainbowManager.Start()
            else
                RainbowManager.Stop()
                -- Reset colors
                for _, window in pairs(self.Windows) do
                    if window.Border then
                        window.Border.Color = self.ThemeColor
                    end
                end
            end
        end
    })
    
    -- Rainbow Speed
    Settings:CreateSlider({
        Name = "Rainbow Speed",
        Min = 0.1,
        Max = 5,
        Default = 1,
        Increment = 0.1,
        Callback = function(value)
            RainbowManager.Speed = value
        end
    })
    
    -- UI Transparency
    Settings:CreateSlider({
        Name = "Window Opacity",
        Min = 0,
        Max = 100,
        Default = 95,
        Callback = function(value)
            for _, window in pairs(self.Windows) do
                if window.Frame then
                    window.Frame.BackgroundTransparency = 1 - (value / 100)
                end
            end
        end
    })
    
    -- Border Thickness
    Settings:CreateSlider({
        Name = "Border Thickness",
        Min = 0,
        Max = 5,
        Default = 2,
        Callback = function(value)
            for _, window in pairs(self.Windows) do
                if window.Border then
                    window.Border.Thickness = value
                end
            end
        end
    })
    
    -- Sound Effects
    Settings:CreateToggle({
        Name = "Sound Effects",
        Default = true,
        Callback = function(value)
            for soundName, _ in pairs(SoundManager.Sounds) do
                -- Toggle sounds (simple implementation)
            end
        end
    })
    
    -- Misc Section
    Settings:CreateSection("Miscellaneous")
    
    -- Reset Positions
    Settings:CreateButton({
        Name = "🔧 Reset Window Positions",
        Callback = function()
            local padding = 10
            local col, row = 0, 0
            local columns = Utility.IsMobile() and 2 or 4
            
            for _, window in pairs(self.Windows) do
                if window.Frame then
                    local x = padding + (col * (220 + padding))
                    local y = padding + (row * (350 + padding))
                    
                    window.Frame.Position = UDim2.new(0, x, 0, y)
                    
                    col = col + 1
                    if col >= columns then
                        col = 0
                        row = row + 1
                    end
                end
            end
            
            SoundManager.Play("Success")
        end
    })
    
    -- Destroy UI
    Settings:CreateButton({
        Name = "❌ Destroy UI",
        Callback = function()
            self:Destroy()
        end
    })
    
    return Settings
end

-- ═══════════════════════════════════════════════════════════════════
-- SEARCH WINDOW
-- ═══════════════════════════════════════════════════════════════════

function VaporLib:CreateSearchWindow()
    local Search = self:CreateWindow({
        Name = "🔍 Search",
        Size = UDim2.new(0, 250, 0, 300)
    })
    
    local searchResults = {}
    
    local searchBox = Search:CreateTextbox({
        Name = "Search",
        Placeholder = "Search elements...",
        Callback = function(text)
            -- Clear previous results display
            for _, result in pairs(searchResults) do
                if result.Parent then
                    result:Destroy()
                end
            end
            searchResults = {}
            
            if text == "" then return end
            
            -- Search through all windows and elements
            for windowName, window in pairs(self.Windows) do
                for _, element in pairs(window.Elements) do
                    -- Search logic would go here
                end
            end
        end
    })
    
    return Search
end

-- ═══════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════

function VaporLib:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 5
    local notifType = config.Type or "Info"
    
    local colors = {
        Info = Color3.fromRGB(138, 43, 226),
        Success = Color3.fromRGB(0, 200, 0),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 50, 50)
    }
    
    local notifContainer = self.ScreenGui:FindFirstChild("NotifContainer")
    if not notifContainer then
        notifContainer = Utility.Create("Frame", {
            Name = "NotifContainer",
            Parent = self.ScreenGui,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.new(0, 280, 1, -20),
            AnchorPoint = Vector2.new(1, 0)
        })
        
        Utility.Create("UIListLayout", {
            Parent = notifContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    end
    
    local notif = Utility.Create("Frame", {
        Name = "Notification",
        Parent = notifContainer,
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(1, 50, 0, 0),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notif
    })
    
    Utility.Create("UIStroke", {
        Parent = notif,
        Color = colors[notifType] or colors.Info,
        Thickness = 2
    })
    
    local accent = Utility.Create("Frame", {
        Parent = notif,
        BackgroundColor3 = colors[notifType] or colors.Info,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0)
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 8),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local contentLabel = Utility.Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 28),
        Size = UDim2.new(1, -20, 0, 35),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    
    -- Progress bar
    local progress = Utility.Create("Frame", {
        Parent = notif,
        BackgroundColor3 = colors[notifType] or colors.Info,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3)
    })
    
    -- Animate in
    SoundManager.Play("Open", 0.3)
    Utility.Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
    
    -- Progress animation
    Utility.Tween(progress, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
    
    -- Remove after duration
    task.delay(duration, function()
        Utility.Tween(notif, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- RETURN LIBRARY
-- ═══════════════════════════════════════════════════════════════════

return VaporLib
