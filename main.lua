--[[
    VapeUI Library - Advanced Roblox UI Library
    Version: 2.0.0
    Author: VapeUI Team
    
    Features:
    - Multiple floating windows (Vape-style)
    - Sharp edges design
    - Mobile support
    - Advanced loading animation
    - Slider, Button, ColorPicker, Settings, List, Search
    - Config system
    - Customizable UI (rainbow border, transparency, background)
]]

local VapeUI = {}
VapeUI.__index = VapeUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Constants
local PLAYER = Players.LocalPlayer
local MOUSE = PLAYER:GetMouse()
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Utility Functions
local Utility = {}

function Utility.Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    for prop, value in pairs(properties or {}) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
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

function Utility.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

function Utility.HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return Color3.fromRGB(r * 255, g * 255, b * 255)
end

function Utility.RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
    
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

-- Theme System
local Theme = {
    Primary = Color3.fromRGB(30, 30, 35),
    Secondary = Color3.fromRGB(40, 40, 48),
    Tertiary = Color3.fromRGB(50, 50, 60),
    Accent = Color3.fromRGB(138, 43, 226),
    AccentDark = Color3.fromRGB(108, 33, 196),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(180, 180, 180),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Error = Color3.fromRGB(231, 76, 60),
    Border = Color3.fromRGB(60, 60, 70),
    
    BackgroundTransparency = 0.05,
    BorderTransparency = 0,
    UITransparency = 0,
    
    RainbowBorder = false,
    RainbowSpeed = 1,
    
    CustomBackground = nil
}

-- Config System
local ConfigSystem = {}
ConfigSystem.Configs = {}
ConfigSystem.CurrentConfig = "Default"
ConfigSystem.SaveFolder = "VapeUI_Configs"

function ConfigSystem:Initialize()
    if not isfolder then return end
    
    if not isfolder(self.SaveFolder) then
        makefolder(self.SaveFolder)
    end
    
    self:LoadAllConfigs()
end

function ConfigSystem:SaveConfig(name, data)
    if not writefile then return false end
    
    local fileName = self.SaveFolder .. "/" .. name .. ".json"
    local success, err = pcall(function()
        writefile(fileName, HttpService:JSONEncode(data))
    end)
    
    if success then
        self.Configs[name] = data
    end
    
    return success
end

function ConfigSystem:LoadConfig(name)
    if not readfile or not isfile then return nil end
    
    local fileName = self.SaveFolder .. "/" .. name .. ".json"
    
    if isfile(fileName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(fileName))
        end)
        
        if success then
            self.Configs[name] = data
            return data
        end
    end
    
    return nil
end

function ConfigSystem:LoadAllConfigs()
    if not listfiles then return end
    
    local files = listfiles(self.SaveFolder)
    for _, file in pairs(files) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            self:LoadConfig(name)
        end
    end
end

function ConfigSystem:DeleteConfig(name)
    if not delfile or not isfile then return false end
    
    local fileName = self.SaveFolder .. "/" .. name .. ".json"
    
    if isfile(fileName) then
        delfile(fileName)
        self.Configs[name] = nil
        return true
    end
    
    return false
end

function ConfigSystem:GetConfigList()
    local list = {}
    for name, _ in pairs(self.Configs) do
        table.insert(list, name)
    end
    return list
end

-- Animation System
local AnimationSystem = {}

function AnimationSystem.FadeIn(frame, duration)
    frame.BackgroundTransparency = 1
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = 1
            end
            if child:FindFirstChild("BackgroundTransparency") or child:IsA("Frame") or child:IsA("ImageLabel") then
                child.BackgroundTransparency = 1
            end
            if child:IsA("ImageLabel") then
                child.ImageTransparency = 1
            end
        end
    end
    
    Utility.Tween(frame, {BackgroundTransparency = Theme.BackgroundTransparency}, duration)
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            Utility.Tween(child, {TextTransparency = 0}, duration)
        end
        if child:IsA("Frame") then
            Utility.Tween(child, {BackgroundTransparency = 0}, duration)
        end
        if child:IsA("ImageLabel") then
            Utility.Tween(child, {ImageTransparency = 0, BackgroundTransparency = 1}, duration)
        end
    end
end

function AnimationSystem.FadeOut(frame, duration)
    Utility.Tween(frame, {BackgroundTransparency = 1}, duration)
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            Utility.Tween(child, {TextTransparency = 1}, duration)
        end
        if child:IsA("Frame") then
            Utility.Tween(child, {BackgroundTransparency = 1}, duration)
        end
        if child:IsA("ImageLabel") then
            Utility.Tween(child, {ImageTransparency = 1}, duration)
        end
    end
end

function AnimationSystem.SlideIn(frame, direction, duration)
    local originalPos = frame.Position
    
    if direction == "Left" then
        frame.Position = UDim2.new(-1, 0, originalPos.Y.Scale, originalPos.Y.Offset)
    elseif direction == "Right" then
        frame.Position = UDim2.new(1, 0, originalPos.Y.Scale, originalPos.Y.Offset)
    elseif direction == "Top" then
        frame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, -1, 0)
    elseif direction == "Bottom" then
        frame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, 1, 0)
    end
    
    Utility.Tween(frame, {Position = originalPos}, duration, Enum.EasingStyle.Back)
end

function AnimationSystem.ScaleIn(frame, duration)
    frame.Size = UDim2.new(0, 0, 0, 0)
    local originalSize = frame:GetAttribute("OriginalSize") or UDim2.new(0, 400, 0, 300)
    frame:SetAttribute("OriginalSize", originalSize)
    
    Utility.Tween(frame, {Size = originalSize}, duration, Enum.EasingStyle.Back)
end

function AnimationSystem.Bounce(frame, intensity, duration)
    local originalPos = frame.Position
    
    Utility.Tween(frame, {Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset - intensity)}, duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    task.delay(duration / 2, function()
        Utility.Tween(frame, {Position = originalPos}, duration / 2, Enum.EasingStyle.Bounce)
    end)
end

-- Loading Screen
local LoadingScreen = {}

function LoadingScreen:Create(parent, options)
    options = options or {}
    local title = options.Title or "VapeUI"
    local subtitle = options.Subtitle or "Loading..."
    local duration = options.Duration or 3
    
    local loadingGui = Utility.Create("Frame", {
        Name = "LoadingScreen",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    -- Center Container
    local centerContainer = Utility.Create("Frame", {
        Name = "CenterContainer",
        Parent = loadingGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 300),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 101
    })
    
    -- Logo Container
    local logoContainer = Utility.Create("Frame", {
        Name = "LogoContainer",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.3, 0),
        Size = UDim2.new(0, 120, 0, 120),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 102
    })
    
    -- Animated Logo Rings
    for i = 1, 3 do
        local ring = Utility.Create("Frame", {
            Name = "Ring" .. i,
            Parent = logoContainer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 80 + i * 15, 0, 80 + i * 15),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 102
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = ring
        })
        
        Utility.Create("UIStroke", {
            Color = Theme.Accent,
            Thickness = 2,
            Transparency = 0.3 + i * 0.15,
            Parent = ring
        })
        
        -- Rotate rings
        task.spawn(function()
            local rotation = 0
            local direction = i % 2 == 0 and 1 or -1
            while ring.Parent do
                rotation = rotation + direction * (3 - i + 1)
                ring.Rotation = rotation
                task.wait()
            end
        end)
    end
    
    -- Center Icon
    local centerIcon = Utility.Create("Frame", {
        Name = "CenterIcon",
        Parent = logoContainer,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 50),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 103
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = centerIcon
    })
    
    -- Pulsing animation for center icon
    task.spawn(function()
        while centerIcon.Parent do
            Utility.Tween(centerIcon, {Size = UDim2.new(0, 55, 0, 55)}, 0.5)
            task.wait(0.5)
            Utility.Tween(centerIcon, {Size = UDim2.new(0, 50, 0, 50)}, 0.5)
            task.wait(0.5)
        end
    end)
    
    -- Title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.55, 0),
        Size = UDim2.new(1, 0, 0, 40),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 32,
        ZIndex = 102
    })
    
    -- Subtitle
    local subtitleLabel = Utility.Create("TextLabel", {
        Name = "Subtitle",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.65, 0),
        Size = UDim2.new(1, 0, 0, 25),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.TextDark,
        TextSize = 16,
        ZIndex = 102
    })
    
    -- Progress Bar Container
    local progressContainer = Utility.Create("Frame", {
        Name = "ProgressContainer",
        Parent = centerContainer,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0.5, 0, 0.8, 0),
        Size = UDim2.new(0.8, 0, 0, 6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 102
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressContainer
    })
    
    -- Progress Bar Fill
    local progressFill = Utility.Create("Frame", {
        Name = "ProgressFill",
        Parent = progressContainer,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 103
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressFill
    })
    
    -- Gradient on progress bar
    Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentDark)
        }),
        Parent = progressFill
    })
    
    -- Progress Text
    local progressText = Utility.Create("TextLabel", {
        Name = "ProgressText",
        Parent = centerContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.88, 0),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.GothamMedium,
        Text = "0%",
        TextColor3 = Theme.TextDark,
        TextSize = 14,
        ZIndex = 102
    })
    
    -- Particle Effects
    for i = 1, 20 do
        local particle = Utility.Create("Frame", {
            Name = "Particle" .. i,
            Parent = loadingGui,
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = math.random(5, 8) / 10,
            Position = UDim2.new(math.random(), 0, 1.1, 0),
            Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6)),
            ZIndex = 101
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle
        })
        
        task.spawn(function()
            local speed = math.random(50, 150) / 100
            local sway = math.random(-50, 50) / 100
            while particle.Parent do
                local newY = particle.Position.Y.Scale - 0.01 * speed
                local newX = particle.Position.X.Scale + math.sin(tick() * 2) * 0.002 * sway
                
                if newY < -0.1 then
                    newY = 1.1
                    newX = math.random()
                end
                
                particle.Position = UDim2.new(newX, 0, newY, 0)
                task.wait()
            end
        end)
    end
    
    -- Animate loading
    local loadingSteps = {
        {progress = 0.15, text = "Initializing..."},
        {progress = 0.30, text = "Loading modules..."},
        {progress = 0.50, text = "Setting up UI..."},
        {progress = 0.70, text = "Loading configs..."},
        {progress = 0.85, text = "Almost there..."},
        {progress = 1.00, text = "Complete!"}
    }
    
    task.spawn(function()
        local stepDuration = duration / #loadingSteps
        
        for _, step in ipairs(loadingSteps) do
            Utility.Tween(progressFill, {Size = UDim2.new(step.progress, 0, 1, 0)}, stepDuration * 0.8)
            subtitleLabel.Text = step.text
            progressText.Text = math.floor(step.progress * 100) .. "%"
            task.wait(stepDuration)
        end
        
        task.wait(0.3)
        
        -- Fade out
        Utility.Tween(loadingGui, {BackgroundTransparency = 1}, 0.5)
        for _, child in pairs(loadingGui:GetDescendants()) do
            if child:IsA("Frame") then
                Utility.Tween(child, {BackgroundTransparency = 1}, 0.5)
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then
                    Utility.Tween(stroke, {Transparency = 1}, 0.5)
                end
            elseif child:IsA("TextLabel") then
                Utility.Tween(child, {TextTransparency = 1}, 0.5)
            end
        end
        
        task.wait(0.5)
        loadingGui:Destroy()
    end)
    
    return loadingGui
end

-- Main UI Components
local Components = {}

-- Button Component
function Components.CreateButton(parent, options)
    options = options or {}
    local text = options.Text or "Button"
    local callback = options.Callback or function() end
    local size = options.Size or UDim2.new(1, -20, 0, 35)
    local position = options.Position or UDim2.new(0, 10, 0, 0)
    
    local buttonContainer = Utility.Create("Frame", {
        Name = "ButtonContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = size,
        Position = position,
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = buttonContainer
    })
    
    local button = Utility.Create("TextButton", {
        Name = "Button",
        Parent = buttonContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        AutoButtonColor = false
    })
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        Utility.Tween(buttonContainer, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utility.Tween(buttonContainer, {BackgroundColor3 = Theme.Tertiary}, 0.2)
    end)
    
    -- Click effect
    button.MouseButton1Click:Connect(function()
        local x, y = MOUSE.X, MOUSE.Y
        Utility.Ripple(buttonContainer, x, y)
        callback()
    end)
    
    -- Mobile support
    button.TouchTap:Connect(function(touchPositions)
        if #touchPositions > 0 then
            local touch = touchPositions[1]
            Utility.Ripple(buttonContainer, touch.X, touch.Y)
            callback()
        end
    end)
    
    return {
        Container = buttonContainer,
        Button = button,
        SetText = function(self, newText)
            button.Text = newText
        end,
        SetCallback = function(self, newCallback)
            callback = newCallback
        end
    }
end

-- Slider Component
function Components.CreateSlider(parent, options)
    options = options or {}
    local text = options.Text or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local callback = options.Callback or function() end
    local suffix = options.Suffix or ""
    
    local currentValue = default
    
    local sliderContainer = Utility.Create("Frame", {
        Name = "SliderContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = sliderContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = sliderContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0.5, -10, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = sliderContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 5),
        Size = UDim2.new(0.5, -10, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = tostring(currentValue) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderTrack = Utility.Create("Frame", {
        Name = "Track",
        Parent = sliderContainer,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 8)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderTrack
    })
    
    local sliderFill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = sliderTrack,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderFill
    })
    
    Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentDark),
            ColorSequenceKeypoint.new(1, Theme.Accent)
        }),
        Parent = sliderFill
    })
    
    local sliderButton = Utility.Create("Frame", {
        Name = "Button",
        Parent = sliderFill,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderButton
    })
    
    -- Slider logic
    local dragging = false
    
    local function updateSlider(input)
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackSize = sliderTrack.AbsoluteSize.X
        
        local relativePos = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
        local rawValue = min + (max - min) * relativePos
        local snappedValue = math.floor(rawValue / increment + 0.5) * increment
        snappedValue = math.clamp(snappedValue, min, max)
        
        if snappedValue ~= currentValue then
            currentValue = snappedValue
            local fillPercent = (currentValue - min) / (max - min)
            
            Utility.Tween(sliderFill, {Size = UDim2.new(fillPercent, 0, 1, 0)}, 0.1)
            valueLabel.Text = tostring(currentValue) .. suffix
            callback(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return {
        Container = sliderContainer,
        SetValue = function(self, value)
            currentValue = math.clamp(value, min, max)
            local fillPercent = (currentValue - min) / (max - min)
            sliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
            valueLabel.Text = tostring(currentValue) .. suffix
            callback(currentValue)
        end,
        GetValue = function(self)
            return currentValue
        end
    }
end

-- Toggle Component
function Components.CreateToggle(parent, options)
    options = options or {}
    local text = options.Text or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    
    local enabled = default
    
    local toggleContainer = Utility.Create("Frame", {
        Name = "ToggleContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = toggleContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = toggleContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleButton = Utility.Create("Frame", {
        Name = "ToggleButton",
        Parent = toggleContainer,
        BackgroundColor3 = enabled and Theme.Accent or Theme.Secondary,
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 20),
        AnchorPoint = Vector2.new(0, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleButton
    })
    
    local toggleIndicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = toggleButton,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleIndicator
    })
    
    local clickDetector = Utility.Create("TextButton", {
        Name = "ClickDetector",
        Parent = toggleContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false
    })
    
    local function toggle()
        enabled = not enabled
        
        Utility.Tween(toggleButton, {BackgroundColor3 = enabled and Theme.Accent or Theme.Secondary}, 0.2)
        Utility.Tween(toggleIndicator, {Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0)}, 0.2)
        
        callback(enabled)
    end
    
    clickDetector.MouseButton1Click:Connect(toggle)
    clickDetector.TouchTap:Connect(toggle)
    
    return {
        Container = toggleContainer,
        SetValue = function(self, value)
            if enabled ~= value then
                toggle()
            end
        end,
        GetValue = function(self)
            return enabled
        end
    }
end

-- Color Picker Component (Circular)
function Components.CreateColorPicker(parent, options)
    options = options or {}
    local text = options.Text or "Color"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local callback = options.Callback or function() end
    
    local currentColor = default
    local currentHue, currentSat, currentVal = Utility.RGBToHSV(default)
    local pickerOpen = false
    
    local colorContainer = Utility.Create("Frame", {
        Name = "ColorContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0),
        ClipsDescendants = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = colorContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local colorPreview = Utility.Create("Frame", {
        Name = "ColorPreview",
        Parent = colorContainer,
        BackgroundColor3 = currentColor,
        Position = UDim2.new(1, -40, 0.5, 0),
        Size = UDim2.new(0, 25, 0, 25),
        AnchorPoint = Vector2.new(0, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorPreview
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = colorPreview
    })
    
    -- Circular Color Picker Popup
    local pickerPopup = Utility.Create("Frame", {
        Name = "PickerPopup",
        Parent = colorContainer,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(1, 10, 0, 0),
        Size = UDim2.new(0, 200, 0, 230),
        Visible = false,
        ZIndex = 50
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = pickerPopup
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = pickerPopup
    })
    
    -- Circular Hue/Saturation Wheel
    local wheelSize = 150
    local wheelContainer = Utility.Create("Frame", {
        Name = "WheelContainer",
        Parent = pickerPopup,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 15),
        Size = UDim2.new(0, wheelSize, 0, wheelSize),
        AnchorPoint = Vector2.new(0.5, 0),
        ZIndex = 51
    })
    
    -- Create color wheel using ImageLabel
    local colorWheel = Utility.Create("ImageLabel", {
        Name = "ColorWheel",
        Parent = wheelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385", -- Color wheel image
        ZIndex = 51
    })
    
    -- Wheel selector
    local wheelSelector = Utility.Create("Frame", {
        Name = "WheelSelector",
        Parent = wheelContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 52
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = wheelSelector
    })
    
    Utility.Create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 2,
        Parent = wheelSelector
    })
    
    -- Value slider
    local valueSlider = Utility.Create("Frame", {
        Name = "ValueSlider",
        Parent = pickerPopup,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0.5, 0, 0, 175),
        Size = UDim2.new(0, wheelSize, 0, 15),
        AnchorPoint = Vector2.new(0.5, 0),
        ZIndex = 51
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = valueSlider
    })
    
    local valueGradient = Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Utility.HSVToRGB(currentHue, currentSat, 1))
        }),
        Parent = valueSlider
    })
    
    local valueIndicator = Utility.Create("Frame", {
        Name = "ValueIndicator",
        Parent = valueSlider,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(currentVal, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 52
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 3),
        Parent = valueIndicator
    })
    
    -- Hex input
    local hexInput = Utility.Create("TextBox", {
        Name = "HexInput",
        Parent = pickerPopup,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0.5, 0, 0, 200),
        Size = UDim2.new(0, wheelSize, 0, 25),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "#FFFFFF",
        Text = "#" .. string.format("%02X%02X%02X", currentColor.R * 255, currentColor.G * 255, currentColor.B * 255),
        TextColor3 = Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 51
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = hexInput
    })
    
    local function updateColor()
        currentColor = Utility.HSVToRGB(currentHue, currentSat, currentVal)
        colorPreview.BackgroundColor3 = currentColor
        valueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Utility.HSVToRGB(currentHue, currentSat, 1))
        })
        hexInput.Text = "#" .. string.format("%02X%02X%02X", currentColor.R * 255, currentColor.G * 255, currentColor.B * 255)
        callback(currentColor)
    end
    
    local function updateWheelSelector()
        local angle = currentHue * math.pi * 2
        local radius = currentSat * (wheelSize / 2 - 10)
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        wheelSelector.Position = UDim2.new(0.5, x, 0.5, y)
    end
    
    updateWheelSelector()
    
    -- Wheel input
    local wheelDragging = false
    
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
    
    local function updateWheelFromInput(input)
        local centerX = wheelContainer.AbsolutePosition.X + wheelSize / 2
        local centerY = wheelContainer.AbsolutePosition.Y + wheelSize / 2
        
        local dx = input.Position.X - centerX
        local dy = input.Position.Y - centerY
        local distance = math.sqrt(dx * dx + dy * dy)
        local maxRadius = wheelSize / 2 - 5
        
        distance = math.min(distance, maxRadius)
        
        local angle = math.atan2(dy, dx)
        if angle < 0 then angle = angle + math.pi * 2 end
        
        currentHue = angle / (math.pi * 2)
        currentSat = distance / maxRadius
        
        updateWheelSelector()
        updateColor()
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if wheelDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateWheelFromInput(input)
        end
    end)
    
    colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateWheelFromInput(input)
        end
    end)
    
    -- Value slider input
    local valueDragging = false
    
    valueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = true
            local relativeX = (input.Position.X - valueSlider.AbsolutePosition.X) / valueSlider.AbsoluteSize.X
            currentVal = math.clamp(relativeX, 0, 1)
            valueIndicator.Position = UDim2.new(currentVal, 0, 0.5, 0)
            updateColor()
        end
    end)
    
    valueSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if valueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = (input.Position.X - valueSlider.AbsolutePosition.X) / valueSlider.AbsoluteSize.X
            currentVal = math.clamp(relativeX, 0, 1)
            valueIndicator.Position = UDim2.new(currentVal, 0, 0.5, 0)
            updateColor()
        end
    end)
    
    -- Hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16) or 255
            local g = tonumber(hex:sub(3, 4), 16) or 255
            local b = tonumber(hex:sub(5, 6), 16) or 255
            currentColor = Color3.fromRGB(r, g, b)
            currentHue, currentSat, currentVal = Utility.RGBToHSV(currentColor)
            updateWheelSelector()
            valueIndicator.Position = UDim2.new(currentVal, 0, 0.5, 0)
            updateColor()
        end
    end)
    
    -- Toggle picker
    local previewButton = Utility.Create("TextButton", {
        Name = "PreviewButton",
        Parent = colorPreview,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 10
    })
    
    previewButton.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        pickerPopup.Visible = pickerOpen
    end)
    
    previewButton.TouchTap:Connect(function()
        pickerOpen = not pickerOpen
        pickerPopup.Visible = pickerOpen
    end)
    
    return {
        Container = colorContainer,
        SetColor = function(self, color)
            currentColor = color
            currentHue, currentSat, currentVal = Utility.RGBToHSV(color)
            colorPreview.BackgroundColor3 = color
            updateWheelSelector()
            valueIndicator.Position = UDim2.new(currentVal, 0, 0.5, 0)
            updateColor()
        end,
        GetColor = function(self)
            return currentColor
        end
    }
end

-- Dropdown/List Component
function Components.CreateDropdown(parent, options)
    options = options or {}
    local text = options.Text or "Dropdown"
    local items = options.Items or {}
    local default = options.Default or (items[1] or "")
    local callback = options.Callback or function() end
    local multiSelect = options.MultiSelect or false
    
    local selected = multiSelect and {} or default
    local dropdownOpen = false
    
    if multiSelect and type(default) == "table" then
        for _, item in pairs(default) do
            selected[item] = true
        end
    end
    
    local dropdownContainer = Utility.Create("Frame", {
        Name = "DropdownContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0),
        ClipsDescendants = false,
        ZIndex = 2
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = dropdownContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = dropdownContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2
    })
    
    local selectedLabel = Utility.Create("TextLabel", {
        Name = "Selected",
        Parent = dropdownContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -30, 1, 0),
        Font = Enum.Font.Gotham,
        Text = multiSelect and "Select..." or default,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2
    })
    
    local dropdownArrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdownContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        ZIndex = 2
    })
    
    local dropdownList = Utility.Create("Frame", {
        Name = "DropdownList",
        Parent = dropdownContainer,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, math.min(#items * 30, 150)),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 100
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = dropdownList
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = dropdownList
    })
    
    local listScroll = Utility.Create("ScrollingFrame", {
        Name = "ListScroll",
        Parent = dropdownList,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, #items * 30),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ZIndex = 101
    })
    
    local listLayout = Utility.Create("UIListLayout", {
        Parent = listScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0)
    })
    
    local function updateSelectedText()
        if multiSelect then
            local selectedItems = {}
            for item, isSelected in pairs(selected) do
                if isSelected then
                    table.insert(selectedItems, item)
                end
            end
            selectedLabel.Text = #selectedItems > 0 and table.concat(selectedItems, ", ") or "Select..."
        else
            selectedLabel.Text = selected
        end
    end
    
    local function createItem(itemName)
        local itemButton = Utility.Create("TextButton", {
            Name = itemName,
            Parent = listScroll,
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 102
        })
        
        local itemLabel = Utility.Create("TextLabel", {
            Name = "Label",
            Parent = itemButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = Enum.Font.Gotham,
            Text = itemName,
            TextColor3 = Theme.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102
        })
        
        local checkmark = Utility.Create("TextLabel", {
            Name = "Checkmark",
            Parent = itemButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -30, 0, 0),
            Size = UDim2.new(0, 25, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "✓",
            TextColor3 = Theme.Accent,
            TextSize = 14,
            Visible = multiSelect and selected[itemName] or selected == itemName,
            ZIndex = 102
        })
        
        itemButton.MouseEnter:Connect(function()
            Utility.Tween(itemButton, {BackgroundTransparency = 0.2}, 0.1)
        end)
        
        itemButton.MouseLeave:Connect(function()
            Utility.Tween(itemButton, {BackgroundTransparency = 0.5}, 0.1)
        end)
        
        itemButton.MouseButton1Click:Connect(function()
            if multiSelect then
                selected[itemName] = not selected[itemName]
                checkmark.Visible = selected[itemName]
                updateSelectedText()
                callback(selected)
            else
                selected = itemName
                for _, child in pairs(listScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        local cm = child:FindFirstChild("Checkmark")
                        if cm then
                            cm.Visible = child.Name == itemName
                        end
                    end
                end
                updateSelectedText()
                dropdownOpen = false
                dropdownList.Visible = false
                Utility.Tween(dropdownArrow, {Rotation = 0}, 0.2)
                callback(selected)
            end
        end)
        
        return itemButton
    end
    
    for _, itemName in pairs(items) do
        createItem(itemName)
    end
    
    local toggleButton = Utility.Create("TextButton", {
        Name = "ToggleButton",
        Parent = dropdownContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 3
    })
    
    toggleButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        dropdownList.Visible = dropdownOpen
        Utility.Tween(dropdownArrow, {Rotation = dropdownOpen and 180 or 0}, 0.2)
    end)
    
    toggleButton.TouchTap:Connect(function()
        dropdownOpen = not dropdownOpen
        dropdownList.Visible = dropdownOpen
        Utility.Tween(dropdownArrow, {Rotation = dropdownOpen and 180 or 0}, 0.2)
    end)
    
    return {
        Container = dropdownContainer,
        SetItems = function(self, newItems)
            items = newItems
            for _, child in pairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            for _, itemName in pairs(items) do
                createItem(itemName)
            end
            listScroll.CanvasSize = UDim2.new(0, 0, 0, #items * 30)
            dropdownList.Size = UDim2.new(1, 0, 0, math.min(#items * 30, 150))
        end,
        GetSelected = function(self)
            return selected
        end,
        SetSelected = function(self, value)
            if multiSelect then
                selected = value
            else
                selected = value
            end
            updateSelectedText()
        end
    }
end

-- Search Component
function Components.CreateSearch(parent, options)
    options = options or {}
    local placeholder = options.Placeholder or "Search..."
    local callback = options.Callback or function() end
    
    local searchContainer = Utility.Create("Frame", {
        Name = "SearchContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = searchContainer
    })
    
    local searchIcon = Utility.Create("TextLabel", {
        Name = "SearchIcon",
        Parent = searchContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 25, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "🔍",
        TextColor3 = Theme.TextDark,
        TextSize = 14
    })
    
    local searchInput = Utility.Create("TextBox", {
        Name = "SearchInput",
        Parent = searchContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextDark,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    local clearButton = Utility.Create("TextButton", {
        Name = "ClearButton",
        Parent = searchContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "✕",
        TextColor3 = Theme.TextDark,
        TextSize = 14,
        Visible = false
    })
    
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        clearButton.Visible = #searchInput.Text > 0
        callback(searchInput.Text)
    end)
    
    clearButton.MouseButton1Click:Connect(function()
        searchInput.Text = ""
        callback("")
    end)
    
    clearButton.TouchTap:Connect(function()
        searchInput.Text = ""
        callback("")
    end)
    
    return {
        Container = searchContainer,
        GetText = function(self)
            return searchInput.Text
        end,
        SetText = function(self, text)
            searchInput.Text = text
        end,
        Clear = function(self)
            searchInput.Text = ""
        end
    }
end

-- Keybind Component
function Components.CreateKeybind(parent, options)
    options = options or {}
    local text = options.Text or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local callback = options.Callback or function() end
    
    local currentKey = default
    local listening = false
    
    local keybindContainer = Utility.Create("Frame", {
        Name = "KeybindContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = keybindContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = keybindContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.6, -10, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local keyButton = Utility.Create("TextButton", {
        Name = "KeyButton",
        Parent = keybindContainer,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(1, -90, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 25),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamMedium,
        Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None",
        TextColor3 = Theme.Text,
        TextSize = 11,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = keyButton
    })
    
    keyButton.MouseButton1Click:Connect(function()
        listening = true
        keyButton.Text = "..."
        Utility.Tween(keyButton, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    keyButton.TouchTap:Connect(function()
        listening = true
        keyButton.Text = "..."
        Utility.Tween(keyButton, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keyButton.Text = currentKey.Name
                listening = false
                Utility.Tween(keyButton, {BackgroundColor3 = Theme.Secondary}, 0.2)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- Cancel if clicked elsewhere
                if input.Position.X < keyButton.AbsolutePosition.X or
                   input.Position.X > keyButton.AbsolutePosition.X + keyButton.AbsoluteSize.X or
                   input.Position.Y < keyButton.AbsolutePosition.Y or
                   input.Position.Y > keyButton.AbsolutePosition.Y + keyButton.AbsoluteSize.Y then
                    listening = false
                    keyButton.Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None"
                    Utility.Tween(keyButton, {BackgroundColor3 = Theme.Secondary}, 0.2)
                end
            end
        else
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                callback(currentKey)
            end
        end
    end)
    
    return {
        Container = keybindContainer,
        GetKey = function(self)
            return currentKey
        end,
        SetKey = function(self, key)
            currentKey = key
            keyButton.Text = key.Name ~= "Unknown" and key.Name or "None"
        end
    }
end

-- TextInput Component
function Components.CreateTextInput(parent, options)
    options = options or {}
    local text = options.Text or "Input"
    local placeholder = options.Placeholder or "Enter text..."
    local default = options.Default or ""
    local callback = options.Callback or function() end
    
    local inputContainer = Utility.Create("Frame", {
        Name = "InputContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -20, 0, 55),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = inputContainer
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = inputContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local inputBox = Utility.Create("TextBox", {
        Name = "InputBox",
        Parent = inputContainer,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 10, 0, 28),
        Size = UDim2.new(1, -20, 0, 22),
        Font = Enum.Font.Gotham,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextDark,
        Text = default,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = inputBox
    })
    
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = inputBox
    })
    
    inputBox.FocusLost:Connect(function(enterPressed)
        callback(inputBox.Text, enterPressed)
    end)
    
    return {
        Container = inputContainer,
        GetText = function(self)
            return inputBox.Text
        end,
        SetText = function(self, newText)
            inputBox.Text = newText
        end
    }
end

-- Label Component
function Components.CreateLabel(parent, options)
    options = options or {}
    local text = options.Text or "Label"
    
    local labelContainer = Utility.Create("Frame", {
        Name = "LabelContainer",
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = labelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    return {
        Container = labelContainer,
        SetText = function(self, newText)
            label.Text = newText
        end
    }
end

-- Separator Component
function Components.CreateSeparator(parent)
    local separator = Utility.Create("Frame", {
        Name = "Separator",
        Parent = parent,
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, 0)
    })
    
    return {
        Container = separator
    }
end

-- Main Window Class
local Window = {}
Window.__index = Window

function Window.new(library, options)
    local self = setmetatable({}, Window)
    
    options = options or {}
    self.Title = options.Title or "Window"
    self.Size = options.Size or UDim2.new(0, 300, 0, 400)
    self.Position = options.Position or UDim2.new(0.5, -150, 0.5, -200)
    self.Library = library
    self.Tabs = {}
    self.CurrentTab = nil
    self.Minimized = false
    self.Elements = {}
    
    -- Create window frame
    self.Frame = Utility.Create("Frame", {
        Name = "Window_" .. self.Title,
        Parent = library.ScreenGui,
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = Theme.BackgroundTransparency,
        Position = self.Position,
        Size = self.Size,
        ClipsDescendants = true
    })
    
    self.Frame:SetAttribute("OriginalSize", self.Size)
    
    -- Border
    self.Border = Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = Theme.BorderTransparency,
        Parent = self.Frame
    })
    
    -- Title bar
    self.TitleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        Parent = self.Frame,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 35)
    })
    
    self.TitleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = self.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Window controls
    local controlsContainer = Utility.Create("Frame", {
        Name = "Controls",
        Parent = self.TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 0),
        Size = UDim2.new(0, 65, 1, 0)
    })
    
    -- Minimize button
    local minimizeBtn = Utility.Create("TextButton", {
        Name = "Minimize",
        Parent = controlsContainer,
        BackgroundColor3 = Theme.Warning,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 25, 0, 25),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextColor3 = Theme.Text,
        TextSize = 16,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = minimizeBtn
    })
    
    -- Close button
    local closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        Parent = controlsContainer,
        BackgroundColor3 = Theme.Error,
        Position = UDim2.new(0, 30, 0.5, 0),
        Size = UDim2.new(0, 25, 0, 25),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.Text,
        TextSize = 18,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    -- Button hover effects
    minimizeBtn.MouseEnter:Connect(function()
        Utility.Tween(minimizeBtn, {BackgroundColor3 = Color3.fromRGB(255, 220, 50)}, 0.2)
    end)
    
    minimizeBtn.MouseLeave:Connect(function()
        Utility.Tween(minimizeBtn, {BackgroundColor3 = Theme.Warning}, 0.2)
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Utility.Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Utility.Tween(closeBtn, {BackgroundColor3 = Theme.Error}, 0.2)
    end)
    
    -- Minimize functionality
    minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    minimizeBtn.TouchTap:Connect(function()
        self:ToggleMinimize()
    end)
    
    -- Close functionality
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    closeBtn.TouchTap:Connect(function()
        self:Close()
    end)
    
    -- Tab container
    self.TabContainer = Utility.Create("Frame", {
        Name = "TabContainer",
        Parent = self.Frame,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(0, 120, 1, -35)
    })
    
    self.TabScroll = Utility.Create("ScrollingFrame", {
        Name = "TabScroll",
        Parent = self.TabContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    Utility.Create("UIListLayout", {
        Parent = self.TabScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    -- Content container
    self.ContentContainer = Utility.Create("Frame", {
        Name = "ContentContainer",
        Parent = self.Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 125, 0, 40),
        Size = UDim2.new(1, -130, 1, -45)
    })
    
    -- Make draggable
    Utility.MakeDraggable(self.Frame, self.TitleBar)
    
    -- Rainbow border effect
    if Theme.RainbowBorder then
        self:StartRainbowBorder()
    end
    
    -- Entrance animation
    AnimationSystem.SlideIn(self.Frame, "Top", 0.5)
    
    return self
end

function Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    
    if self.Minimized then
        self.OriginalSize = self.Frame.Size
        Utility.Tween(self.Frame, {Size = UDim2.new(0, self.Size.X.Offset, 0, 35)}, 0.3)
        self.TabContainer.Visible = false
        self.ContentContainer.Visible = false
    else
        Utility.Tween(self.Frame, {Size = self.OriginalSize or self.Size}, 0.3)
        task.delay(0.2, function()
            self.TabContainer.Visible = true
            self.ContentContainer.Visible = true
        end)
    end
end

function Window:Close()
    AnimationSystem.FadeOut(self.Frame, 0.3)
    task.delay(0.3, function()
        self.Frame:Destroy()
    end)
end

function Window:Show()
    self.Frame.Visible = true
    AnimationSystem.FadeIn(self.Frame, 0.3)
end

function Window:Hide()
    AnimationSystem.FadeOut(self.Frame, 0.3)
    task.delay(0.3, function()
        self.Frame.Visible = false
    end)
end

function Window:StartRainbowBorder()
    task.spawn(function()
        local hue = 0
        while self.Frame and self.Frame.Parent do
            hue = (hue + 0.005 * Theme.RainbowSpeed) % 1
            local color = Color3.fromHSV(hue, 0.8, 1)
            self.Border.Color = color
            task.wait()
        end
    end)
end

function Window:SetBorderColor(color)
    Theme.RainbowBorder = false
    self.Border.Color = color
end

function Window:SetRainbowBorder(enabled, speed)
    Theme.RainbowBorder = enabled
    Theme.RainbowSpeed = speed or 1
    if enabled then
        self:StartRainbowBorder()
    end
end

function Window:SetTransparency(transparency)
    Theme.BackgroundTransparency = transparency
    self.Frame.BackgroundTransparency = transparency
end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Window:CreateTab(options)
    options = options or {}
    local tab = setmetatable({}, Tab)
    
    tab.Name = options.Name or "Tab"
    tab.Icon = options.Icon or ""
    tab.Window = self
    tab.Elements = {}
    tab.Sections = {}
    
    -- Tab button
    tab.Button = Utility.Create("TextButton", {
        Name = "Tab_" .. tab.Name,
        Parent = self.TabScroll,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 35),
        Font = Enum.Font.GothamMedium,
        Text = (tab.Icon ~= "" and tab.Icon .. "  " or "") .. tab.Name,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = tab.Button
    })
    
    -- Tab content
    tab.Content = Utility.Create("ScrollingFrame", {
        Name = "Content_" .. tab.Name,
        Parent = self.ContentContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    Utility.Create("UIListLayout", {
        Parent = tab.Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        Parent = tab.Content
    })
    
    -- Tab selection
    local function selectTab()
        -- Deselect all tabs
        for _, t in pairs(self.Tabs) do
            t.Button.BackgroundTransparency = 0.5
            t.Button.TextColor3 = Theme.TextDark
            t.Content.Visible = false
        end
        
        -- Select this tab
        tab.Button.BackgroundTransparency = 0
        tab.Button.TextColor3 = Theme.Text
        tab.Content.Visible = true
        self.CurrentTab = tab
        
        Utility.Tween(tab.Button, {BackgroundColor3 = Theme.Accent}, 0.2)
    end
    
    tab.Button.MouseButton1Click:Connect(selectTab)
    tab.Button.TouchTap:Connect(selectTab)
    
    -- Hover effect
    tab.Button.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 0.3}, 0.1)
        end
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            Utility.Tween(tab.Button, {BackgroundTransparency = 0.5}, 0.1)
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Select first tab
    if #self.Tabs == 1 then
        selectTab()
    end
    
    return tab
end

-- Section Class
local Section = {}
Section.__index = Section

function Tab:CreateSection(options)
    options = options or {}
    local section = setmetatable({}, Section)
    
    section.Name = options.Name or "Section"
    section.Tab = self
    section.Elements = {}
    section.Collapsed = false
    
    -- Section container
    section.Container = Utility.Create("Frame", {
        Name = "Section_" .. section.Name,
        Parent = self.Content,
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = section.Container
    })
    
    -- Section header
    section.Header = Utility.Create("Frame", {
        Name = "Header",
        Parent = section.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30)
    })
    
    section.TitleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = section.Header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = section.Name,
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    section.CollapseButton = Utility.Create("TextButton", {
        Name = "Collapse",
        Parent = section.Header,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 25, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = Theme.TextDark,
        TextSize = 10
    })
    
    -- Section content
    section.Content = Utility.Create("Frame", {
        Name = "Content",
        Parent = section.Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    Utility.Create("UIListLayout", {
        Parent = section.Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 10),
        Parent = section.Content
    })
    
    -- Collapse functionality
    local function toggleCollapse()
        section.Collapsed = not section.Collapsed
        section.Content.Visible = not section.Collapsed
        section.CollapseButton.Text = section.Collapsed and "▶" or "▼"
        Utility.Tween(section.CollapseButton, {Rotation = section.Collapsed and -90 or 0}, 0.2)
    end
    
    section.CollapseButton.MouseButton1Click:Connect(toggleCollapse)
    section.CollapseButton.TouchTap:Connect(toggleCollapse)
    
    table.insert(self.Sections, section)
    
    return section
end

-- Add elements to Section
function Section:AddButton(options)
    return Components.CreateButton(self.Content, options)
end

function Section:AddSlider(options)
    return Components.CreateSlider(self.Content, options)
end

function Section:AddToggle(options)
    return Components.CreateToggle(self.Content, options)
end

function Section:AddColorPicker(options)
    return Components.CreateColorPicker(self.Content, options)
end

function Section:AddDropdown(options)
    return Components.CreateDropdown(self.Content, options)
end

function Section:AddSearch(options)
    return Components.CreateSearch(self.Content, options)
end

function Section:AddKeybind(options)
    return Components.CreateKeybind(self.Content, options)
end

function Section:AddTextInput(options)
    return Components.CreateTextInput(self.Content, options)
end

function Section:AddLabel(options)
    return Components.CreateLabel(self.Content, options)
end

function Section:AddSeparator()
    return Components.CreateSeparator(self.Content)
end

-- Add elements directly to Tab (creates auto section)
function Tab:AddButton(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddButton(options)
end

function Tab:AddSlider(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddSlider(options)
end

function Tab:AddToggle(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddToggle(options)
end

function Tab:AddColorPicker(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddColorPicker(options)
end

function Tab:AddDropdown(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddDropdown(options)
end

function Tab:AddSearch(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddSearch(options)
end

function Tab:AddKeybind(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddKeybind(options)
end

function Tab:AddTextInput(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddTextInput(options)
end

function Tab:AddLabel(options)
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddLabel(options)
end

function Tab:AddSeparator()
    if #self.Sections == 0 then
        self:CreateSection({Name = "General"})
    end
    return self.Sections[#self.Sections]:AddSeparator()
end

-- Settings Window
local SettingsWindow = {}
SettingsWindow.__index = SettingsWindow

function VapeUI:CreateSettingsWindow()
    local settingsWindow = Window.new(self, {
        Title = "⚙️ Settings",
        Size = UDim2.new(0, 350, 0, 450),
        Position = UDim2.new(0.5, 200, 0.5, -225)
    })
    
    -- UI Settings Tab
    local uiTab = settingsWindow:CreateTab({Name = "UI", Icon = "🎨"})
    
    local uiSection = uiTab:CreateSection({Name = "Appearance"})
    
    uiSection:AddSlider({
        Text = "UI Transparency",
        Min = 0,
        Max = 100,
        Default = Theme.BackgroundTransparency * 100,
        Suffix = "%",
        Callback = function(value)
            Theme.BackgroundTransparency = value / 100
            self:UpdateAllWindows()
        end
    })
    
    uiSection:AddSlider({
        Text = "Border Transparency",
        Min = 0,
        Max = 100,
        Default = Theme.BorderTransparency * 100,
        Suffix = "%",
        Callback = function(value)
            Theme.BorderTransparency = value / 100
            self:UpdateAllWindows()
        end
    })
    
    uiSection:AddToggle({
        Text = "Rainbow Border",
        Default = Theme.RainbowBorder,
        Callback = function(value)
            Theme.RainbowBorder = value
            for _, window in pairs(self.Windows) do
                if value then
                    window:StartRainbowBorder()
                else
                    window.Border.Color = Theme.Border
                end
            end
        end
    })
    
    uiSection:AddSlider({
        Text = "Rainbow Speed",
        Min = 1,
        Max = 10,
        Default = Theme.RainbowSpeed,
        Callback = function(value)
            Theme.RainbowSpeed = value
        end
    })
    
    uiSection:AddColorPicker({
        Text = "Accent Color",
        Default = Theme.Accent,
        Callback = function(color)
            Theme.Accent = color
            self:UpdateAllWindows()
        end
    })
    
    uiSection:AddColorPicker({
        Text = "Border Color",
        Default = Theme.Border,
        Callback = function(color)
            if not Theme.RainbowBorder then
                Theme.Border = color
                for _, window in pairs(self.Windows) do
                    window.Border.Color = color
                end
            end
        end
    })
    
    -- Theme Section
    local themeSection = uiTab:CreateSection({Name = "Themes"})
    
    themeSection:AddDropdown({
        Text = "Select Theme",
        Items = {"Dark", "Light", "Purple", "Blue", "Red", "Green"},
        Default = "Dark",
        Callback = function(theme)
            self:ApplyTheme(theme)
        end
    })
    
    -- Config Tab
    local configTab = settingsWindow:CreateTab({Name = "Configs", Icon = "💾"})
    
    local configSection = configTab:CreateSection({Name = "Configuration"})
    
    local configList = configSection:AddDropdown({
        Text = "Saved Configs",
        Items = ConfigSystem:GetConfigList(),
        Default = ConfigSystem.CurrentConfig,
        Callback = function(selected)
            ConfigSystem.CurrentConfig = selected
        end
    })
    
    configSection:AddTextInput({
        Text = "Config Name",
        Placeholder = "Enter config name...",
        Callback = function(text, enterPressed)
            if enterPressed and text ~= "" then
                -- Will be used for saving
            end
        end
    })
    
    configSection:AddButton({
        Text = "Save Config",
        Callback = function()
            local data = self:GetCurrentSettings()
            ConfigSystem:SaveConfig(ConfigSystem.CurrentConfig, data)
            configList:SetItems(ConfigSystem:GetConfigList())
            self:Notify("Success", "Config saved successfully!", 3)
        end
    })
    
    configSection:AddButton({
        Text = "Load Config",
        Callback = function()
            local data = ConfigSystem:LoadConfig(ConfigSystem.CurrentConfig)
            if data then
                self:ApplySettings(data)
                self:Notify("Success", "Config loaded successfully!", 3)
            else
                self:Notify("Error", "Failed to load config!", 3)
            end
        end
    })
    
    configSection:AddButton({
        Text = "Delete Config",
        Callback = function()
            if ConfigSystem:DeleteConfig(ConfigSystem.CurrentConfig) then
                configList:SetItems(ConfigSystem:GetConfigList())
                self:Notify("Success", "Config deleted!", 3)
            end
        end
    })
    
    configSection:AddButton({
        Text = "Refresh List",
        Callback = function()
            ConfigSystem:LoadAllConfigs()
            configList:SetItems(ConfigSystem:GetConfigList())
        end
    })
    
    -- Info Tab
    local infoTab = settingsWindow:CreateTab({Name = "Info", Icon = "ℹ️"})
    
    local infoSection = infoTab:CreateSection({Name = "About"})
    
    infoSection:AddLabel({Text = "VapeUI Library v2.0.0"})
    infoSection:AddLabel({Text = "Advanced Roblox UI Library"})
    infoSection:AddSeparator()
    infoSection:AddLabel({Text = "Features:"})
    infoSection:AddLabel({Text = "• Multiple floating windows"})
    infoSection:AddLabel({Text = "• Mobile support"})
    infoSection:AddLabel({Text = "• Config system"})
    infoSection:AddLabel({Text = "• Rainbow borders"})
    infoSection:AddLabel({Text = "• Customizable themes"})
    
    return settingsWindow
end

-- Notification System
local NotificationContainer = nil

function VapeUI:Notify(title, message, duration)
    duration = duration or 3
    
    if not NotificationContainer then
        NotificationContainer = Utility.Create("Frame", {
            Name = "NotificationContainer",
            Parent = self.ScreenGui,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.new(0, 300, 1, -20),
            AnchorPoint = Vector2.new(1, 0),
            ZIndex = 1000
        })
        
        Utility.Create("UIListLayout", {
            Parent = NotificationContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    end
    
    local notification = Utility.Create("Frame", {
        Name = "Notification",
        Parent = NotificationContainer,
        BackgroundColor3 = Theme.Primary,
        Size = UDim2.new(0, 280, 0, 70),
        Position = UDim2.new(1, 300, 0, 0),
        ZIndex = 1001
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = notification
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 1,
        Parent = notification
    })
    
    -- Accent bar
    local accentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        Parent = notification,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 4, 1, 0),
        ZIndex = 1002
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = accentBar
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 8),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002
    })
    
    local messageLabel = Utility.Create("TextLabel", {
        Name = "Message",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 28),
        Size = UDim2.new(1, -20, 0, 35),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 1002
    })
    
    -- Progress bar
    local progressBar = Utility.Create("Frame", {
        Name = "Progress",
        Parent = notification,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        ZIndex = 1002
    })
    
    -- Slide in
    Utility.Tween(notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
    
    -- Progress animation
    Utility.Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration)
    
    -- Slide out and destroy
    task.delay(duration, function()
        Utility.Tween(notification, {Position = UDim2.new(1, 300, 0, 0)}, 0.3)
        task.delay(0.3, function()
            notification:Destroy()
        end)
    end)
end

-- Mobile Toggle Button
function VapeUI:CreateMobileToggle()
    if not IS_MOBILE then return end
    
    local toggleButton = Utility.Create("TextButton", {
        Name = "MobileToggle",
        Parent = self.ScreenGui,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 50),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "≡",
        TextColor3 = Theme.Text,
        TextSize = 24,
        ZIndex = 999
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = toggleButton
    })
    
    local uiVisible = true
    
    toggleButton.TouchTap:Connect(function()
        uiVisible = not uiVisible
        for _, window in pairs(self.Windows) do
            window.Frame.Visible = uiVisible
        end
        
        Utility.Tween(toggleButton, {
            BackgroundColor3 = uiVisible and Theme.Accent or Theme.Error
        }, 0.2)
    end)
    
    -- Make toggle draggable
    Utility.MakeDraggable(toggleButton)
    
    return toggleButton
end

-- Theme Presets
local ThemePresets = {
    Dark = {
        Primary = Color3.fromRGB(30, 30, 35),
        Secondary = Color3.fromRGB(40, 40, 48),
        Tertiary = Color3.fromRGB(50, 50, 60),
        Accent = Color3.fromRGB(138, 43, 226),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(60, 60, 70)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(230, 230, 235),
        Tertiary = Color3.fromRGB(220, 220, 225),
        Accent = Color3.fromRGB(138, 43, 226),
        Text = Color3.fromRGB(30, 30, 35),
        TextDark = Color3.fromRGB(100, 100, 110),
        Border = Color3.fromRGB(200, 200, 210)
    },
    Purple = {
        Primary = Color3.fromRGB(35, 25, 45),
        Secondary = Color3.fromRGB(45, 35, 55),
        Tertiary = Color3.fromRGB(55, 45, 65),
        Accent = Color3.fromRGB(180, 100, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(200, 180, 220),
        Border = Color3.fromRGB(80, 60, 100)
    },
    Blue = {
        Primary = Color3.fromRGB(20, 30, 45),
        Secondary = Color3.fromRGB(30, 40, 55),
        Tertiary = Color3.fromRGB(40, 50, 65),
        Accent = Color3.fromRGB(66, 165, 245),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 200, 220),
        Border = Color3.fromRGB(50, 70, 100)
    },
    Red = {
        Primary = Color3.fromRGB(40, 25, 25),
        Secondary = Color3.fromRGB(50, 35, 35),
        Tertiary = Color3.fromRGB(60, 45, 45),
        Accent = Color3.fromRGB(239, 83, 80),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(220, 180, 180),
        Border = Color3.fromRGB(100, 60, 60)
    },
    Green = {
        Primary = Color3.fromRGB(25, 40, 30),
        Secondary = Color3.fromRGB(35, 50, 40),
        Tertiary = Color3.fromRGB(45, 60, 50),
        Accent = Color3.fromRGB(102, 187, 106),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 220, 190),
        Border = Color3.fromRGB(60, 100, 70)
    }
}

function VapeUI:ApplyTheme(themeName)
    local preset = ThemePresets[themeName]
    if not preset then return end
    
    for key, value in pairs(preset) do
        Theme[key] = value
    end
    
    self:UpdateAllWindows()
    self:Notify("Theme Applied", "Changed theme to " .. themeName, 2)
end

function VapeUI:UpdateAllWindows()
    for _, window in pairs(self.Windows) do
        window.Frame.BackgroundColor3 = Theme.Primary
        window.Frame.BackgroundTransparency = Theme.BackgroundTransparency
        window.Border.Color = Theme.Border
        window.Border.Transparency = Theme.BorderTransparency
        window.TitleBar.BackgroundColor3 = Theme.Secondary
        window.TitleLabel.TextColor3 = Theme.Text
        window.TabContainer.BackgroundColor3 = Theme.Secondary
        
        -- Update all elements recursively
        for _, descendant in pairs(window.Frame:GetDescendants()) do
            if descendant:IsA("Frame") and descendant.Name:find("Container") then
                if descendant.BackgroundTransparency < 0.9 then
                    descendant.BackgroundColor3 = Theme.Tertiary
                end
            elseif descendant:IsA("TextLabel") then
                if descendant.TextColor3 == Color3.fromRGB(255, 255, 255) or 
                   descendant.TextColor3 == Theme.Text then
                    descendant.TextColor3 = Theme.Text
                end
            elseif descendant:IsA("UIStroke") then
                if descendant.Color ~= Theme.Accent then
                    descendant.Color = Theme.Border
                end
            end
        end
    end
end

function VapeUI:GetCurrentSettings()
    local settings = {
        Theme = {
            Primary = {Theme.Primary.R, Theme.Primary.G, Theme.Primary.B},
            Secondary = {Theme.Secondary.R, Theme.Secondary.G, Theme.Secondary.B},
            Accent = {Theme.Accent.R, Theme.Accent.G, Theme.Accent.B},
            BackgroundTransparency = Theme.BackgroundTransparency,
            BorderTransparency = Theme.BorderTransparency,
            RainbowBorder = Theme.RainbowBorder,
            RainbowSpeed = Theme.RainbowSpeed
        },
        Windows = {}
    }
    
    for i, window in pairs(self.Windows) do
        settings.Windows[i] = {
            Position = {
                window.Frame.Position.X.Scale,
                window.Frame.Position.X.Offset,
                window.Frame.Position.Y.Scale,
                window.Frame.Position.Y.Offset
            },
            Size = {
                window.Frame.Size.X.Scale,
                window.Frame.Size.X.Offset,
                window.Frame.Size.Y.Scale,
                window.Frame.Size.Y.Offset
            }
        }
    end
    
    return settings
end

function VapeUI:ApplySettings(settings)
    if settings.Theme then
        if settings.Theme.Primary then
            Theme.Primary = Color3.new(unpack(settings.Theme.Primary))
        end
        if settings.Theme.Secondary then
            Theme.Secondary = Color3.new(unpack(settings.Theme.Secondary))
        end
        if settings.Theme.Accent then
            Theme.Accent = Color3.new(unpack(settings.Theme.Accent))
        end
        if settings.Theme.BackgroundTransparency then
            Theme.BackgroundTransparency = settings.Theme.BackgroundTransparency
        end
        if settings.Theme.BorderTransparency then
            Theme.BorderTransparency = settings.Theme.BorderTransparency
        end
        if settings.Theme.RainbowBorder ~= nil then
            Theme.RainbowBorder = settings.Theme.RainbowBorder
        end
        if settings.Theme.RainbowSpeed then
            Theme.RainbowSpeed = settings.Theme.RainbowSpeed
        end
    end
    
    self:UpdateAllWindows()
end

-- Custom Background
function VapeUI:SetCustomBackground(imageId)
    Theme.CustomBackground = imageId
    
    for _, window in pairs(self.Windows) do
        local existingBg = window.Frame:FindFirstChild("CustomBackground")
        if existingBg then
            existingBg:Destroy()
        end
        
        if imageId then
            local bg = Utility.Create("ImageLabel", {
                Name = "CustomBackground",
                Parent = window.Frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = imageId,
                ImageTransparency = 0.8,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 0
            })
        end
    end
end

-- Main Library Initialization
function VapeUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, VapeUI)
    
    self.Windows = {}
    self.Elements = {}
    self.Connections = {}
    
    -- Initialize config system
    ConfigSystem:Initialize()
    
    -- Create ScreenGui
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "VapeUI_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    
    -- Parent to CoreGui or PlayerGui
    local success = pcall(function()
        self.ScreenGui.Parent = CoreGui
    end)
    
    if not success then
        self.ScreenGui.Parent = PLAYER:WaitForChild("PlayerGui")
    end
    
    -- Show loading screen if enabled
    if options.LoadingScreen ~= false then
        LoadingScreen:Create(self.ScreenGui, {
            Title = options.Title or "VapeUI",
            Subtitle = options.Subtitle or "Loading...",
            Duration = options.LoadingDuration or 3
        })
        
        -- Wait for loading to complete
        task.wait((options.LoadingDuration or 3) + 0.5)
    end
    
    -- Create mobile toggle
    if IS_MOBILE then
        self:CreateMobileToggle()
    end
    
    -- Keybind to toggle UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == (options.ToggleKey or Enum.KeyCode.RightShift) then
            for _, window in pairs(self.Windows) do
                window.Frame.Visible = not window.Frame.Visible
            end
        end
    end)
    
    return self
end

function VapeUI:CreateWindow(options)
    local window = Window.new(self, options)
    table.insert(self.Windows, window)
    return window
end

function VapeUI:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Expose components for external use
VapeUI.Components = Components
VapeUI.Utility = Utility
VapeUI.Theme = Theme
VapeUI.ConfigSystem = ConfigSystem
VapeUI.AnimationSystem = AnimationSystem

-- Return library
return VapeUI
