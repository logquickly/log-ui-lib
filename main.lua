--[[
    VapeUI Library v2.0 - Complete Rewrite
    
    Features:
    - Working Config System
    - Sound Effects
    - Smooth Animations
    - Main Menu with Expanding Sub-Menus
    - Auto-Scroll for Overflow Content
    - Transparent Background Option
    - Theme Flash on Config Load
    - Mobile Support
]]

local VapeUI = {}
VapeUI.__index = VapeUI

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- Player
local PLAYER = Players.LocalPlayer
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--============================================
-- SOUND SYSTEM
--============================================
local SoundSystem = {
    Enabled = true,
    Volume = 0.5,
    Sounds = {
        Click = "rbxassetid://6895079853",
        Hover = "rbxassetid://6895079527",
        Toggle = "rbxassetid://6895079736",
        Slider = "rbxassetid://6895079949",
        Open = "rbxassetid://6895079606",
        Close = "rbxassetid://6895079424",
        Success = "rbxassetid://6895079316",
        Error = "rbxassetid://6895079100",
        Notification = "rbxassetid://6895078860",
        ConfigLoad = "rbxassetid://5853908928",
        ConfigSave = "rbxassetid://6895079316",
        Whoosh = "rbxassetid://6895078649",
        Pop = "rbxassetid://6895078982"
    }
}

function SoundSystem:Play(soundName, volume)
    if not self.Enabled then return end
    
    local soundId = self.Sounds[soundName]
    if not soundId then return end
    
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = (volume or 1) * self.Volume
        sound.PlayOnRemove = false
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Wait()
        sound:Destroy()
    end)
end

--============================================
-- UTILITY FUNCTIONS
--============================================
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

function Utility.Tween(instance, properties, duration, easingStyle, easingDirection, callback)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(
            duration or 0.3, 
            easingStyle or Enum.EasingStyle.Quart, 
            easingDirection or Enum.EasingDirection.Out
        ),
        properties
    )
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

function Utility.Spring(instance, properties, duration)
    return Utility.Tween(instance, properties, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Utility.Bounce(instance, properties, duration)
    return Utility.Tween(instance, properties, duration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
end

function Utility.Elastic(instance, properties, duration)
    return Utility.Tween(instance, properties, duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
end

function Utility.Ripple(parent, x, y, color)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        Parent = parent,
        BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = parent.ZIndex + 5
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    
    Utility.Tween(ripple, {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1
    }, 0.6, Enum.EasingStyle.Quart)
    
    task.delay(0.6, function()
        ripple:Destroy()
    end)
end

function Utility.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        Utility.Tween(frame, {Position = newPos}, 0.08)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
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
    local h, s, v = 0, 0, max
    
    local d = max - min
    s = max == 0 and 0 or d / max
    
    if max ~= min then
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

--============================================
-- THEME SYSTEM
--============================================
local Theme = {
    -- Main Colors
    Primary = Color3.fromRGB(25, 25, 30),
    Secondary = Color3.fromRGB(35, 35, 42),
    Tertiary = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(130, 80, 245),
    AccentDark = Color3.fromRGB(100, 60, 200),
    AccentLight = Color3.fromRGB(160, 110, 255),
    
    -- Text Colors
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(170, 170, 180),
    TextMuted = Color3.fromRGB(120, 120, 130),
    
    -- Status Colors
    Success = Color3.fromRGB(80, 220, 130),
    Warning = Color3.fromRGB(255, 200, 60),
    Error = Color3.fromRGB(255, 90, 90),
    Info = Color3.fromRGB(80, 180, 255),
    
    -- Border
    Border = Color3.fromRGB(55, 55, 65),
    BorderLight = Color3.fromRGB(70, 70, 85),
    
    -- Transparency
    BackgroundTransparency = 0.02,
    MenuBackgroundTransparency = 0,
    ExpandedMenuTransparent = false,
    
    -- Effects
    RainbowBorder = false,
    RainbowSpeed = 1,
    
    -- Fonts
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    
    -- Sizes
    CornerRadius = 6,
    BorderThickness = 1
}

local ThemePresets = {
    Dark = {
        Primary = Color3.fromRGB(25, 25, 30),
        Secondary = Color3.fromRGB(35, 35, 42),
        Tertiary = Color3.fromRGB(45, 45, 55),
        Accent = Color3.fromRGB(130, 80, 245),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(55, 55, 65)
    },
    Light = {
        Primary = Color3.fromRGB(245, 245, 250),
        Secondary = Color3.fromRGB(235, 235, 242),
        Tertiary = Color3.fromRGB(225, 225, 232),
        Accent = Color3.fromRGB(100, 60, 220),
        Text = Color3.fromRGB(30, 30, 40),
        Border = Color3.fromRGB(200, 200, 210)
    },
    Purple = {
        Primary = Color3.fromRGB(30, 20, 45),
        Secondary = Color3.fromRGB(45, 30, 60),
        Tertiary = Color3.fromRGB(55, 40, 75),
        Accent = Color3.fromRGB(180, 100, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(80, 50, 110)
    },
    Blue = {
        Primary = Color3.fromRGB(15, 25, 45),
        Secondary = Color3.fromRGB(25, 40, 65),
        Tertiary = Color3.fromRGB(35, 55, 85),
        Accent = Color3.fromRGB(60, 150, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(45, 70, 110)
    },
    Red = {
        Primary = Color3.fromRGB(35, 20, 20),
        Secondary = Color3.fromRGB(50, 30, 30),
        Tertiary = Color3.fromRGB(65, 40, 40),
        Accent = Color3.fromRGB(255, 80, 80),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(90, 50, 50)
    },
    Green = {
        Primary = Color3.fromRGB(15, 30, 25),
        Secondary = Color3.fromRGB(25, 45, 35),
        Tertiary = Color3.fromRGB(35, 60, 50),
        Accent = Color3.fromRGB(80, 220, 130),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(50, 85, 65)
    },
    Midnight = {
        Primary = Color3.fromRGB(10, 10, 18),
        Secondary = Color3.fromRGB(18, 18, 28),
        Tertiary = Color3.fromRGB(28, 28, 40),
        Accent = Color3.fromRGB(100, 120, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(40, 40, 60)
    }
}

--============================================
-- CONFIG SYSTEM (WORKING)
--============================================
local ConfigSystem = {}
ConfigSystem.Configs = {}
ConfigSystem.CurrentConfig = "Default"
ConfigSystem.SaveFolder = "VapeUI"
ConfigSystem.Elements = {} -- Store all configurable elements

function ConfigSystem:Initialize()
    -- Check if file system is available
    if not isfolder or not makefolder or not writefile or not readfile then
        warn("VapeUI: File system not available. Configs will not persist.")
        return false
    end
    
    -- Create save folder
    if not isfolder(self.SaveFolder) then
        makefolder(self.SaveFolder)
    end
    
    -- Load existing configs
    self:LoadAllConfigs()
    return true
end

function ConfigSystem:RegisterElement(id, elementData)
    self.Elements[id] = elementData
end

function ConfigSystem:GetAllValues()
    local values = {}
    
    for id, element in pairs(self.Elements) do
        if element.GetValue then
            local success, value = pcall(function()
                return element:GetValue()
            end)
            if success then
                -- Handle Color3
                if typeof(value) == "Color3" then
                    values[id] = {
                        Type = "Color3",
                        R = value.R,
                        G = value.G,
                        B = value.B
                    }
                -- Handle KeyCode
                elseif typeof(value) == "EnumItem" then
                    values[id] = {
                        Type = "KeyCode",
                        Name = value.Name
                    }
                -- Handle tables (multi-select)
                elseif type(value) == "table" then
                    values[id] = {
                        Type = "Table",
                        Data = value
                    }
                else
                    values[id] = {
                        Type = "Simple",
                        Value = value
                    }
                end
            end
        end
    end
    
    -- Also save theme settings
    values["_Theme"] = {
        Type = "Theme",
        Accent = {Theme.Accent.R, Theme.Accent.G, Theme.Accent.B},
        RainbowBorder = Theme.RainbowBorder,
        RainbowSpeed = Theme.RainbowSpeed,
        BackgroundTransparency = Theme.BackgroundTransparency,
        ExpandedMenuTransparent = Theme.ExpandedMenuTransparent
    }
    
    return values
end

function ConfigSystem:ApplyValues(values)
    for id, data in pairs(values) do
        if id == "_Theme" then
            -- Apply theme settings
            if data.Accent then
                Theme.Accent = Color3.new(data.Accent[1], data.Accent[2], data.Accent[3])
            end
            if data.RainbowBorder ~= nil then
                Theme.RainbowBorder = data.RainbowBorder
            end
            if data.RainbowSpeed then
                Theme.RainbowSpeed = data.RainbowSpeed
            end
            if data.BackgroundTransparency then
                Theme.BackgroundTransparency = data.BackgroundTransparency
            end
            if data.ExpandedMenuTransparent ~= nil then
                Theme.ExpandedMenuTransparent = data.ExpandedMenuTransparent
            end
        else
            local element = self.Elements[id]
            if element and element.SetValue then
                local success = pcall(function()
                    if data.Type == "Color3" then
                        element:SetValue(Color3.new(data.R, data.G, data.B))
                    elseif data.Type == "KeyCode" then
                        element:SetValue(Enum.KeyCode[data.Name])
                    elseif data.Type == "Table" then
                        element:SetValue(data.Data)
                    else
                        element:SetValue(data.Value)
                    end
                end)
                
                if not success then
                    warn("VapeUI: Failed to apply value for", id)
                end
            end
        end
    end
end

function ConfigSystem:SaveConfig(name)
    if not writefile then return false end
    
    local values = self:GetAllValues()
    local json = HttpService:JSONEncode(values)
    
    local success = pcall(function()
        writefile(self.SaveFolder .. "/" .. name .. ".json", json)
    end)
    
    if success then
        self.Configs[name] = values
        self.CurrentConfig = name
    end
    
    return success
end

function ConfigSystem:LoadConfig(name)
    local values = self.Configs[name]
    
    if not values and readfile and isfile then
        local path = self.SaveFolder .. "/" .. name .. ".json"
        if isfile(path) then
            local success, json = pcall(function()
                return readfile(path)
            end)
            
            if success then
                local decodeSuccess, decoded = pcall(function()
                    return HttpService:JSONDecode(json)
                end)
                
                if decodeSuccess then
                    values = decoded
                    self.Configs[name] = values
                end
            end
        end
    end
    
    if values then
        self.CurrentConfig = name
        self:ApplyValues(values)
        return true
    end
    
    return false
end

function ConfigSystem:DeleteConfig(name)
    if not delfile or not isfile then return false end
    
    local path = self.SaveFolder .. "/" .. name .. ".json"
    
    if isfile(path) then
        local success = pcall(function()
            delfile(path)
        end)
        
        if success then
            self.Configs[name] = nil
            return true
        end
    end
    
    return false
end

function ConfigSystem:LoadAllConfigs()
    if not listfiles then return end
    
    local success, files = pcall(function()
        return listfiles(self.SaveFolder)
    end)
    
    if success and files then
        for _, file in pairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                self:LoadConfig(name)
            end
        end
    end
end

function ConfigSystem:GetConfigList()
    local list = {}
    
    for name, _ in pairs(self.Configs) do
        table.insert(list, name)
    end
    
    -- Also check files if available
    if listfiles and isfolder and isfolder(self.SaveFolder) then
        local success, files = pcall(function()
            return listfiles(self.SaveFolder)
        end)
        
        if success then
            for _, file in pairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name and not self.Configs[name] then
                    table.insert(list, name)
                end
            end
        end
    end
    
    return list
end

--============================================
-- ANIMATION SYSTEM
--============================================
local AnimationSystem = {}

function AnimationSystem.FadeIn(frame, duration, callback)
    frame.BackgroundTransparency = 1
    frame.Visible = true
    
    local descendants = frame:GetDescendants()
    local originalTransparencies = {}
    
    for _, child in pairs(descendants) do
        if child:IsA("GuiObject") then
            originalTransparencies[child] = {
                Background = child.BackgroundTransparency,
                Text = child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") 
                    and child.TextTransparency or nil,
                Image = child:IsA("ImageLabel") or child:IsA("ImageButton") 
                    and child.ImageTransparency or nil
            }
            
            child.BackgroundTransparency = 1
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                child.TextTransparency = 1
            end
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                child.ImageTransparency = 1
            end
        end
    end
    
    Utility.Tween(frame, {BackgroundTransparency = Theme.BackgroundTransparency}, duration)
    
    for child, transparencies in pairs(originalTransparencies) do
        if child.Parent then
            Utility.Tween(child, {BackgroundTransparency = transparencies.Background}, duration)
            if transparencies.Text then
                Utility.Tween(child, {TextTransparency = 0}, duration)
            end
            if transparencies.Image then
                Utility.Tween(child, {ImageTransparency = 0}, duration)
            end
        end
    end
    
    if callback then
        task.delay(duration, callback)
    end
end

function AnimationSystem.FadeOut(frame, duration, callback)
    Utility.Tween(frame, {BackgroundTransparency = 1}, duration)
    
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            Utility.Tween(child, {BackgroundTransparency = 1}, duration)
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                Utility.Tween(child, {TextTransparency = 1}, duration)
            end
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                Utility.Tween(child, {ImageTransparency = 1}, duration)
            end
        end
    end
    
    if callback then
        task.delay(duration, function()
            frame.Visible = false
            callback()
        end)
    else
        task.delay(duration, function()
            frame.Visible = false
        end)
    end
end

function AnimationSystem.SlideIn(frame, direction, duration)
    local originalPos = frame.Position
    frame.Visible = true
    
    local offsets = {
        Left = UDim2.new(-1, 0, originalPos.Y.Scale, originalPos.Y.Offset),
        Right = UDim2.new(1.5, 0, originalPos.Y.Scale, originalPos.Y.Offset),
        Top = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, -1, 0),
        Bottom = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, 1.5, 0)
    }
    
    frame.Position = offsets[direction] or offsets.Top
    Utility.Spring(frame, {Position = originalPos}, duration)
end

function AnimationSystem.SlideOut(frame, direction, duration, callback)
    local offsets = {
        Left = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset),
        Right = UDim2.new(1.5, 0, frame.Position.Y.Scale, frame.Position.Y.Offset),
        Top = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0),
        Bottom = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1.5, 0)
    }
    
    Utility.Tween(frame, {Position = offsets[direction] or offsets.Top}, duration, 
        Enum.EasingStyle.Back, Enum.EasingDirection.In, callback)
end

function AnimationSystem.ScaleIn(frame, duration)
    frame.Visible = true
    local originalSize = frame.Size
    frame.Size = UDim2.new(0, 0, 0, 0)
    Utility.Spring(frame, {Size = originalSize}, duration)
end

function AnimationSystem.ScaleOut(frame, duration, callback)
    Utility.Tween(frame, {Size = UDim2.new(0, 0, 0, 0)}, duration,
        Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
            frame.Visible = false
            if callback then callback() end
        end)
end

function AnimationSystem.Pulse(frame, scale, duration)
    local originalSize = frame.Size
    
    Utility.Tween(frame, {
        Size = UDim2.new(
            originalSize.X.Scale * scale,
            originalSize.X.Offset * scale,
            originalSize.Y.Scale * scale,
            originalSize.Y.Offset * scale
        )
    }, duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        Utility.Tween(frame, {Size = originalSize}, duration / 2, Enum.EasingStyle.Quad)
    end)
end

function AnimationSystem.Shake(frame, intensity, duration)
    local originalPos = frame.Position
    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then
            frame.Position = originalPos
            connection:Disconnect()
            return
        end
        
        local progress = elapsed / duration
        local currentIntensity = intensity * (1 - progress)
        
        frame.Position = UDim2.new(
            originalPos.X.Scale,
            originalPos.X.Offset + math.random(-currentIntensity, currentIntensity),
            originalPos.Y.Scale,
            originalPos.Y.Offset + math.random(-currentIntensity, currentIntensity)
        )
    end)
end

function AnimationSystem.ThemeFlash(screenGui, color, duration)
    local flash = Utility.Create("Frame", {
        Name = "ThemeFlash",
        Parent = screenGui,
        BackgroundColor3 = color or Theme.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 9999
    })
    
    Utility.Tween(flash, {BackgroundTransparency = 1}, duration or 0.5)
    
    task.delay(duration or 0.5, function()
        flash:Destroy()
    end)
end

--============================================
-- LOADING SCREEN
--============================================
local LoadingScreen = {}

function LoadingScreen:Create(parent, options)
    options = options or {}
    local title = options.Title or "VapeUI"
    local subtitle = options.Subtitle or "Loading..."
    local duration = options.Duration or 3
    
    SoundSystem:Play("Open", 0.8)
    
    local container = Utility.Create("Frame", {
        Name = "LoadingScreen",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(10, 10, 15),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    -- Animated background particles
    for i = 1, 30 do
        local particle = Utility.Create("Frame", {
            Name = "Particle" .. i,
            Parent = container,
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = math.random(70, 90) / 100,
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            Size = UDim2.new(0, math.random(2, 8), 0, math.random(2, 8)),
            ZIndex = 101
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle
        })
        
        task.spawn(function()
            while particle.Parent do
                local targetX = math.random()
                local targetY = math.random()
                Utility.Tween(particle, {
                    Position = UDim2.new(targetX, 0, targetY, 0),
                    BackgroundTransparency = math.random(60, 95) / 100
                }, math.random(20, 50) / 10)
                task.wait(math.random(20, 50) / 10)
            end
        end)
    end
    
    -- Center container
    local centerFrame = Utility.Create("Frame", {
        Name = "Center",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 300),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 102
    })
    
    -- Animated logo rings
    local logoContainer = Utility.Create("Frame", {
        Name = "Logo",
        Parent = centerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.35, 0),
        Size = UDim2.new(0, 150, 0, 150),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 103
    })
    
    for i = 1, 4 do
        local ring = Utility.Create("Frame", {
            Name = "Ring" .. i,
            Parent = logoContainer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 60 + i * 25, 0, 60 + i * 25),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 103
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = ring
        })
        
        local stroke = Utility.Create("UIStroke", {
            Color = Theme.Accent,
            Thickness = 2,
            Transparency = 0.2 + i * 0.15,
            Parent = ring
        })
        
        task.spawn(function()
            local rotation = math.random(0, 360)
            local direction = i % 2 == 0 and 1 or -1
            local speed = (5 - i) * 0.8
            
            while ring.Parent do
                rotation = rotation + direction * speed
                ring.Rotation = rotation
                task.wait()
            end
        end)
    end
    
    -- Center icon
    local centerIcon = Utility.Create("Frame", {
        Name = "Icon",
        Parent = logoContainer,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 50),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 104
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = centerIcon
    })
    
    -- Pulsing animation
    task.spawn(function()
        while centerIcon.Parent do
            Utility.Tween(centerIcon, {
                Size = UDim2.new(0, 60, 0, 60),
                BackgroundTransparency = 0.2
            }, 0.8)
            task.wait(0.8)
            Utility.Tween(centerIcon, {
                Size = UDim2.new(0, 50, 0, 50),
                BackgroundTransparency = 0
            }, 0.8)
            task.wait(0.8)
        end
    end)
    
    -- Title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = centerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.58, 0),
        Size = UDim2.new(1, 0, 0, 50),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 36,
        ZIndex = 103
    })
    
    -- Subtitle
    local subtitleLabel = Utility.Create("TextLabel", {
        Name = "Subtitle",
        Parent = centerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.68, 0),
        Size = UDim2.new(1, 0, 0, 25),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Theme.Font,
        Text = subtitle,
        TextColor3 = Theme.TextDark,
        TextSize = 16,
        ZIndex = 103
    })
    
    -- Progress bar
    local progressContainer = Utility.Create("Frame", {
        Name = "ProgressContainer",
        Parent = centerFrame,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0.5, 0, 0.82, 0),
        Size = UDim2.new(0.7, 0, 0, 8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 103
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressContainer
    })
    
    local progressFill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = progressContainer,
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 104
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressFill
    })
    
    Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentLight)
        }),
        Parent = progressFill
    })
    
    -- Progress text
    local progressText = Utility.Create("TextLabel", {
        Name = "ProgressText",
        Parent = centerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.9, 0),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Theme.Font,
        Text = "0%",
        TextColor3 = Theme.TextMuted,
        TextSize = 14,
        ZIndex = 103
    })
    
    -- Loading steps
    local steps = {
        {progress = 0.2, text = "Initializing..."},
        {progress = 0.4, text = "Loading modules..."},
        {progress = 0.6, text = "Setting up UI..."},
        {progress = 0.8, text = "Loading configs..."},
        {progress = 0.95, text = "Almost ready..."},
        {progress = 1.0, text = "Complete!"}
    }
    
    task.spawn(function()
        local stepDuration = duration / #steps
        
        for _, step in ipairs(steps) do
            Utility.Tween(progressFill, {Size = UDim2.new(step.progress, 0, 1, 0)}, stepDuration * 0.8)
            subtitleLabel.Text = step.text
            progressText.Text = math.floor(step.progress * 100) .. "%"
            
            if step.progress < 1 then
                SoundSystem:Play("Hover", 0.3)
            else
                SoundSystem:Play("Success", 0.6)
            end
            
            task.wait(stepDuration)
        end
        
        task.wait(0.3)
        
        -- Fade out
        AnimationSystem.FadeOut(container, 0.5, function()
            container:Destroy()
        end)
    end)
    
    return container
end

--============================================
-- NOTIFICATION SYSTEM
--============================================
local NotificationSystem = {}
NotificationSystem.Container = nil

function NotificationSystem:Initialize(parent)
    self.Container = Utility.Create("Frame", {
        Name = "NotificationContainer",
        Parent = parent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 320, 1, -20),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 9000
    })
    
    Utility.Create("UIListLayout", {
        Parent = self.Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top
    })
end

function NotificationSystem:Notify(title, message, duration, notifType)
    if not self.Container then return end
    
    duration = duration or 3
    notifType = notifType or "Info"
    
    local colors = {
        Info = Theme.Info,
        Success = Theme.Success,
        Warning = Theme.Warning,
        Error = Theme.Error
    }
    
    local accentColor = colors[notifType] or Theme.Accent
    
    SoundSystem:Play("Notification", 0.6)
    
    local notification = Utility.Create("Frame", {
        Name = "Notification",
        Parent = self.Container,
        BackgroundColor3 = Theme.Primary,
        Size = UDim2.new(0, 300, 0, 0),
        ClipsDescendants = true,
        ZIndex = 9001
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notification
    })
    
    Utility.Create("UIStroke", {
        Color = accentColor,
        Thickness = 1,
        Transparency = 0.5,
        Parent = notification
    })
    
    -- Accent bar
    Utility.Create("Frame", {
        Name = "AccentBar",
        Parent = notification,
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 4, 1, 0),
        ZIndex = 9002
    })
    
    -- Title
    Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -50, 0, 22),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9002
    })
    
    -- Close button
    local closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 10),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Theme.FontBold,
        Text = "×",
        TextColor3 = Theme.TextDark,
        TextSize = 18,
        ZIndex = 9002
    })
    
    -- Message
    Utility.Create("TextLabel", {
        Name = "Message",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 32),
        Size = UDim2.new(1, -25, 0, 40),
        Font = Theme.Font,
        Text = message,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 9002
    })
    
    -- Progress bar
    local progressBar = Utility.Create("Frame", {
        Name = "Progress",
        Parent = notification,
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        ZIndex = 9002
    })
    
    -- Animate in
    Utility.Spring(notification, {Size = UDim2.new(0, 300, 0, 80)}, 0.4)
    
    -- Progress animation
    task.delay(0.1, function()
        Utility.Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration - 0.1)
    end)
    
    -- Close function
    local function closeNotification()
        SoundSystem:Play("Close", 0.4)
        Utility.Tween(notification, {
            Size = UDim2.new(0, 300, 0, 0),
            BackgroundTransparency = 1
        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            notification:Destroy()
        end)
    end
    
    closeBtn.MouseButton1Click:Connect(closeNotification)
    closeBtn.TouchTap:Connect(closeNotification)
    
    -- Auto close
    task.delay(duration, function()
        if notification.Parent then
            closeNotification()
        end
    end)
    
    return notification
end

--============================================
-- COMPONENT BUILDERS
--============================================
local Components = {}

-- Button Component
function Components.CreateButton(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Button"
    local callback = options.Callback or function() end
    
    local container = Utility.Create("Frame", {
        Name = "ButtonContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38),
        ClipsDescendants = true
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local button = Utility.Create("TextButton", {
        Name = "Button",
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14
    })
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        SoundSystem:Play("Hover", 0.3)
        Utility.Tween(container, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utility.Tween(container, {BackgroundColor3 = Theme.Tertiary}, 0.2)
    end)
    
    button.MouseButton1Click:Connect(function()
        SoundSystem:Play("Click", 0.5)
        local mousePos = UserInputService:GetMouseLocation()
        Utility.Ripple(container, mousePos.X, mousePos.Y, Theme.Text)
        AnimationSystem.Pulse(container, 0.95, 0.15)
        callback()
    end)
    
    button.TouchTap:Connect(function(touchPositions)
        SoundSystem:Play("Click", 0.5)
        if #touchPositions > 0 then
            Utility.Ripple(container, touchPositions[1].X, touchPositions[1].Y, Theme.Text)
        end
        AnimationSystem.Pulse(container, 0.95, 0.15)
        callback()
    end)
    
    return {
        Container = container,
        Button = button,
        SetText = function(self, newText)
            button.Text = newText
        end,
        SetCallback = function(self, newCallback)
            callback = newCallback
        end
    }
end

-- Toggle Component
function Components.CreateToggle(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    
    local enabled = default
    
    local container = Utility.Create("Frame", {
        Name = "ToggleContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleBg = Utility.Create("Frame", {
        Name = "ToggleBg",
        Parent = container,
        BackgroundColor3 = enabled and Theme.Accent or Theme.Secondary,
        Position = UDim2.new(1, -55, 0.5, 0),
        Size = UDim2.new(0, 44, 0, 24),
        AnchorPoint = Vector2.new(0, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleBg
    })
    
    local toggleIndicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = toggleBg,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(0, enabled and 22 or 3, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleIndicator
    })
    
    local clickButton = Utility.Create("TextButton", {
        Name = "Click",
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    local function updateVisual()
        Utility.Spring(toggleBg, {
            BackgroundColor3 = enabled and Theme.Accent or Theme.Secondary
        }, 0.3)
        Utility.Spring(toggleIndicator, {
            Position = UDim2.new(0, enabled and 22 or 3, 0.5, 0)
        }, 0.3)
    end
    
    local function toggle()
        enabled = not enabled
        SoundSystem:Play("Toggle", 0.5)
        updateVisual()
        callback(enabled)
    end
    
    clickButton.MouseButton1Click:Connect(toggle)
    clickButton.TouchTap:Connect(toggle)
    
    local elementMethods = {
        Container = container,
        SetValue = function(self, value)
            if enabled ~= value then
                enabled = value
                updateVisual()
                callback(enabled)
            end
        end,
        GetValue = function(self)
            return enabled
        end
    }
    
    -- Register for config
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- Slider Component
function Components.CreateSlider(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local suffix = options.Suffix or ""
    local callback = options.Callback or function() end
    
    local currentValue = default
    
    local container = Utility.Create("Frame", {
        Name = "SliderContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 55)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(0.5, -12, 0, 20),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 6),
        Size = UDim2.new(0.5, -12, 0, 20),
        Font = Theme.FontBold,
        Text = tostring(currentValue) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderTrack = Utility.Create("Frame", {
        Name = "Track",
        Parent = container,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -24, 0, 10)
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
    
    local sliderKnob = Utility.Create("Frame", {
        Name = "Knob",
        Parent = sliderFill,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderKnob
    })
    
    -- Drop shadow for knob
    Utility.Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 2,
        Transparency = 0.5,
        Parent = sliderKnob
    })
    
    local dragging = false
    
    local function updateSlider(input)
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackSize = sliderTrack.AbsoluteSize.X
        
        local relativePos = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
        local rawValue = min + (max - min) * relativePos
        local snappedValue = math.floor(rawValue / increment + 0.5) * increment
        snappedValue = math.clamp(snappedValue, min, max)
        
        -- Round to avoid floating point issues
        snappedValue = math.floor(snappedValue * 1000 + 0.5) / 1000
        
        if snappedValue ~= currentValue then
            currentValue = snappedValue
            local fillPercent = (currentValue - min) / (max - min)
            
            Utility.Tween(sliderFill, {Size = UDim2.new(fillPercent, 0, 1, 0)}, 0.1)
            valueLabel.Text = tostring(currentValue) .. suffix
            
            SoundSystem:Play("Slider", 0.2)
            callback(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local elementMethods = {
        Container = container,
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
    
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- Dropdown Component
function Components.CreateDropdown(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Dropdown"
    local items = options.Items or {}
    local default = options.Default or (items[1] or "")
    local multiSelect = options.MultiSelect or false
    local callback = options.Callback or function() end
    
    local selected = multiSelect and {} or default
    local isOpen = false
    
    if multiSelect and type(default) == "table" then
        for _, item in pairs(default) do
            selected[item] = true
        end
    end
    
    local container = Utility.Create("Frame", {
        Name = "DropdownContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38),
        ClipsDescendants = false,
        ZIndex = 10
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.4, -12, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10
    })
    
    local selectedLabel = Utility.Create("TextLabel", {
        Name = "Selected",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -35, 1, 0),
        Font = Theme.Font,
        Text = multiSelect and "Select..." or default,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10
    })
    
    local arrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Theme.FontBold,
        Text = "▼",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        ZIndex = 10
    })
    
    local dropdownList = Utility.Create("Frame", {
        Name = "List",
        Parent = container,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 100
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = dropdownList
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = dropdownList
    })
    
    local listScroll = Utility.Create("ScrollingFrame", {
        Name = "Scroll",
        Parent = dropdownList,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ZIndex = 101
    })
    
    Utility.Create("UIListLayout", {
        Parent = listScroll,
        SortOrder = Enum.SortOrder.LayoutOrder
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
        local itemBtn = Utility.Create("TextButton", {
            Name = itemName,
            Parent = listScroll,
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 32),
            Font = Theme.Font,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 102
        })
        
        local itemLabel = Utility.Create("TextLabel", {
            Name = "Label",
            Parent = itemBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -35, 1, 0),
            Font = Theme.Font,
            Text = itemName,
            TextColor3 = Theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102
        })
        
        local checkmark = Utility.Create("TextLabel", {
            Name = "Check",
            Parent = itemBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -28, 0, 0),
            Size = UDim2.new(0, 20, 1, 0),
            Font = Theme.FontBold,
            Text = "✓",
            TextColor3 = Theme.Accent,
            TextSize = 14,
            Visible = multiSelect and selected[itemName] or selected == itemName,
            ZIndex = 102
        })
        
        itemBtn.MouseEnter:Connect(function()
            SoundSystem:Play("Hover", 0.2)
            Utility.Tween(itemBtn, {BackgroundTransparency = 0.2}, 0.15)
        end)
        
        itemBtn.MouseLeave:Connect(function()
            Utility.Tween(itemBtn, {BackgroundTransparency = 0.5}, 0.15)
        end)
        
        itemBtn.MouseButton1Click:Connect(function()
            SoundSystem:Play("Click", 0.4)
            
            if multiSelect then
                selected[itemName] = not selected[itemName]
                checkmark.Visible = selected[itemName]
                updateSelectedText()
                callback(selected)
            else
                selected = itemName
                for _, child in pairs(listScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        local cm = child:FindFirstChild("Check")
                        if cm then
                            cm.Visible = child.Name == itemName
                        end
                    end
                end
                updateSelectedText()
                
                -- Close dropdown
                isOpen = false
                arrow.Rotation = 0
                Utility.Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, 
                    Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                        dropdownList.Visible = false
                    end)
                
                callback(selected)
            end
        end)
        
        return itemBtn
    end
    
    local function refreshItems()
        for _, child in pairs(listScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, itemName in pairs(items) do
            createItem(itemName)
        end
        
        local itemHeight = 32
        local maxHeight = math.min(#items * itemHeight, 160)
        listScroll.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight)
        
        return maxHeight
    end
    
    local maxHeight = refreshItems()
    
    local toggleBtn = Utility.Create("TextButton", {
        Name = "Toggle",
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 11
    })
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        SoundSystem:Play(isOpen and "Open" or "Close", 0.4)
        
        if isOpen then
            dropdownList.Visible = true
            Utility.Tween(arrow, {Rotation = 180}, 0.2)
            Utility.Spring(dropdownList, {Size = UDim2.new(1, 0, 0, maxHeight)}, 0.3)
        else
            Utility.Tween(arrow, {Rotation = 0}, 0.2)
            Utility.Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2,
                Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                    dropdownList.Visible = false
                end)
        end
    end)
    
    local elementMethods = {
        Container = container,
        SetItems = function(self, newItems)
            items = newItems
            maxHeight = refreshItems()
        end,
        GetSelected = function(self)
            return selected
        end,
        SetValue = function(self, value)
            if multiSelect then
                selected = value
                for _, child in pairs(listScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        local cm = child:FindFirstChild("Check")
                        if cm then
                            cm.Visible = selected[child.Name] or false
                        end
                    end
                end
            else
                selected = value
                for _, child in pairs(listScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        local cm = child:FindFirstChild("Check")
                        if cm then
                            cm.Visible = child.Name == value
                        end
                    end
                end
            end
            updateSelectedText()
        end,
        GetValue = function(self)
            return selected
        end
    }
    
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- Color Picker Component
function Components.CreateColorPicker(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Color"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local callback = options.Callback or function() end
    
    local currentColor = default
    local h, s, v = Utility.RGBToHSV(default)
    local isOpen = false
    
    local container = Utility.Create("Frame", {
        Name = "ColorPickerContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38),
        ClipsDescendants = false,
        ZIndex = 10
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -55, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10
    })
    
    local colorPreview = Utility.Create("Frame", {
        Name = "Preview",
        Parent = container,
        BackgroundColor3 = currentColor,
        Position = UDim2.new(1, -42, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 10
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = colorPreview
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 2,
        Parent = colorPreview
    })
    
    -- Picker popup
    local pickerPopup = Utility.Create("Frame", {
        Name = "Picker",
        Parent = container,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(1, 10, 0, 0),
        Size = UDim2.new(0, 220, 0, 260),
        Visible = false,
        ZIndex = 200
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = pickerPopup
    })
    
    Utility.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = pickerPopup
    })
    
    -- Color wheel
    local wheelSize = 160
    local wheelContainer = Utility.Create("Frame", {
        Name = "Wheel",
        Parent = pickerPopup,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 20),
        Size = UDim2.new(0, wheelSize, 0, wheelSize),
        AnchorPoint = Vector2.new(0.5, 0),
        ZIndex = 201
    })
    
    local colorWheel = Utility.Create("ImageLabel", {
        Name = "WheelImage",
        Parent = wheelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385",
        ZIndex = 201
    })
    
    local wheelSelector = Utility.Create("Frame", {
        Name = "Selector",
        Parent = wheelContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 202
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
        Position = UDim2.new(0.5, 0, 0, 190),
        Size = UDim2.new(0, wheelSize, 0, 18),
        AnchorPoint = Vector2.new(0.5, 0),
        ZIndex = 201
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = valueSlider
    })
    
    local valueGradient = Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Utility.HSVToRGB(h, s, 1))
        }),
        Parent = valueSlider
    })
    
    local valueIndicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = valueSlider,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new(v, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 22),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 202
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = valueIndicator
    })
    
    -- Hex input
    local hexInput = Utility.Create("TextBox", {
        Name = "HexInput",
        Parent = pickerPopup,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0.5, 0, 0, 220),
        Size = UDim2.new(0, wheelSize, 0, 28),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Theme.Font,
        PlaceholderText = "#FFFFFF",
        Text = "#" .. string.format("%02X%02X%02X", 
            math.floor(currentColor.R * 255), 
            math.floor(currentColor.G * 255), 
            math.floor(currentColor.B * 255)),
        TextColor3 = Theme.Text,
        TextSize = 13,
        ClearTextOnFocus = false,
        ZIndex = 201
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = hexInput
    })
    
    local function updateColor()
        currentColor = Utility.HSVToRGB(h, s, v)
        colorPreview.BackgroundColor3 = currentColor
        valueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Utility.HSVToRGB(h, s, 1))
        })
        hexInput.Text = "#" .. string.format("%02X%02X%02X", 
            math.floor(currentColor.R * 255), 
            math.floor(currentColor.G * 255), 
            math.floor(currentColor.B * 255))
        callback(currentColor)
    end
    
    local function updateWheelSelector()
        local angle = h * math.pi * 2
        local radius = s * (wheelSize / 2 - 10)
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        wheelSelector.Position = UDim2.new(0.5, x, 0.5, y)
    end
    
    updateWheelSelector()
    
    -- Wheel input
    local wheelDragging = false
    
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
        
        h = angle / (math.pi * 2)
        s = distance / maxRadius
        
        updateWheelSelector()
        updateColor()
        SoundSystem:Play("Slider", 0.15)
    end
    
    colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = true
            updateWheelFromInput(input)
        end
    end)
    
    colorWheel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = false
        end
    end)
    
    -- Value slider input
    local valueDragging = false
    
    valueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = true
            local relativeX = math.clamp(
                (input.Position.X - valueSlider.AbsolutePosition.X) / valueSlider.AbsoluteSize.X, 0, 1)
            v = relativeX
            valueIndicator.Position = UDim2.new(v, 0, 0.5, 0)
            updateColor()
        end
    end)
    
    valueSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            if wheelDragging then
                updateWheelFromInput(input)
            elseif valueDragging then
                local relativeX = math.clamp(
                    (input.Position.X - valueSlider.AbsolutePosition.X) / valueSlider.AbsoluteSize.X, 0, 1)
                v = relativeX
                valueIndicator.Position = UDim2.new(v, 0, 0.5, 0)
                updateColor()
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = false
            valueDragging = false
        end
    end)
    
    -- Hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            
            if r and g and b then
                currentColor = Color3.fromRGB(r, g, b)
                h, s, v = Utility.RGBToHSV(currentColor)
                updateWheelSelector()
                valueIndicator.Position = UDim2.new(v, 0, 0.5, 0)
                updateColor()
                SoundSystem:Play("Success", 0.4)
            end
        end
    end)
    
    -- Toggle picker
    local previewBtn = Utility.Create("TextButton", {
        Name = "PreviewBtn",
        Parent = colorPreview,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 11
    })
    
    previewBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        SoundSystem:Play(isOpen and "Open" or "Close", 0.4)
        
        if isOpen then
            pickerPopup.Visible = true
            AnimationSystem.ScaleIn(pickerPopup, 0.3)
        else
            AnimationSystem.ScaleOut(pickerPopup, 0.2)
        end
    end)
    
    local elementMethods = {
        Container = container,
        SetValue = function(self, color)
            currentColor = color
            h, s, v = Utility.RGBToHSV(color)
            colorPreview.BackgroundColor3 = color
            updateWheelSelector()
            valueIndicator.Position = UDim2.new(v, 0, 0.5, 0)
            updateColor()
        end,
        SetColor = function(self, color)
            self:SetValue(color)
        end,
        GetValue = function(self)
            return currentColor
        end,
        GetColor = function(self)
            return currentColor
        end
    }
    
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- Keybind Component
function Components.CreateKeybind(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local callback = options.Callback or function() end
    
    local currentKey = default
    local listening = false
    
    local container = Utility.Create("Frame", {
        Name = "KeybindContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.55, -12, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local keyBtn = Utility.Create("TextButton", {
        Name = "KeyBtn",
        Parent = container,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(1, -100, 0.5, 0),
        Size = UDim2.new(0, 88, 0, 26),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Theme.Font,
        Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None",
        TextColor3 = Theme.Text,
        TextSize = 12,
        AutoButtonColor = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = keyBtn
    })
    
    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        SoundSystem:Play("Click", 0.4)
        Utility.Tween(keyBtn, {BackgroundColor3 = Theme.Accent}, 0.2)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keyBtn.Text = currentKey.Name
                listening = false
                SoundSystem:Play("Success", 0.4)
                Utility.Tween(keyBtn, {BackgroundColor3 = Theme.Secondary}, 0.2)
            end
        else
            if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and 
               input.KeyCode == currentKey then
                callback(currentKey)
            end
        end
    end)
    
    local elementMethods = {
        Container = container,
        SetValue = function(self, key)
            currentKey = key
            keyBtn.Text = key.Name ~= "Unknown" and key.Name or "None"
        end,
        SetKey = function(self, key)
            self:SetValue(key)
        end,
        GetValue = function(self)
            return currentKey
        end,
        GetKey = function(self)
            return currentKey
        end
    }
    
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- TextInput Component
function Components.CreateTextInput(parent, options, elementId)
    options = options or {}
    local text = options.Text or "Input"
    local placeholder = options.Placeholder or "Enter text..."
    local default = options.Default or ""
    local callback = options.Callback or function() end
    
    local container = Utility.Create("Frame", {
        Name = "TextInputContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 60)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 0, 20),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local inputBox = Utility.Create("TextBox", {
        Name = "Input",
        Parent = container,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 24),
        Font = Theme.Font,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextMuted,
        Text = default,
        TextColor3 = Theme.Text,
        TextSize = 13,
        ClearTextOnFocus = false
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = inputBox
    })
    
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = inputBox
    })
    
    inputBox.Focused:Connect(function()
        SoundSystem:Play("Click", 0.3)
        Utility.Tween(inputBox, {BackgroundColor3 = Theme.Tertiary}, 0.2)
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        Utility.Tween(inputBox, {BackgroundColor3 = Theme.Secondary}, 0.2)
        callback(inputBox.Text, enterPressed)
    end)
    
    local elementMethods = {
        Container = container,
        SetValue = function(self, value)
            inputBox.Text = value
        end,
        SetText = function(self, value)
            inputBox.Text = value
        end,
        GetValue = function(self)
            return inputBox.Text
        end,
        GetText = function(self)
            return inputBox.Text
        end
    }
    
    if elementId then
        ConfigSystem:RegisterElement(elementId, elementMethods)
    end
    
    return elementMethods
end

-- Search Component
function Components.CreateSearch(parent, options)
    options = options or {}
    local placeholder = options.Placeholder or "Search..."
    local callback = options.Callback or function() end
    
    local container = Utility.Create("Frame", {
        Name = "SearchContainer",
        Parent = parent,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, -16, 0, 38)
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, Theme.CornerRadius),
        Parent = container
    })
    
    local searchIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 25, 1, 0),
        Font = Theme.FontBold,
        Text = "🔍",
        TextColor3 = Theme.TextDark,
        TextSize = 16
    })
    
    local searchInput = Utility.Create("TextBox", {
        Name = "Input",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Theme.Font,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    local clearBtn = Utility.Create("TextButton", {
        Name = "Clear",
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Theme.FontBold,
        Text = "✕",
        TextColor3 = Theme.TextDark,
        TextSize = 14,
        Visible = false
    })
    
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        clearBtn.Visible = #searchInput.Text > 0
        callback(searchInput.Text)
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchInput.Text = ""
        SoundSystem:Play("Click", 0.3)
    end)
    
    return {
        Container = container,
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

-- Label Component
function Components.CreateLabel(parent, options)
    options = options or {}
    local text = options.Text or "Label"
    
    local container = Utility.Create("Frame", {
        Name = "LabelContainer",
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 25)
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    return {
        Container = container,
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
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -32, 0, 1)
    })
    
    return {
        Container = separator
    }
end

--============================================
-- MAIN MENU SYSTEM
--============================================
local MenuSystem = {}

function MenuSystem:CreateMainMenu(screenGui, options)
    options = options or {}
    
    local mainMenu = {
        ScreenGui = screenGui,
        SubMenus = {},
        IsOpen = true,
        CurrentSubMenu = nil
    }
    
    -- Main menu button (collapsed state)
    local menuButton = Utility.Create("Frame", {
        Name = "MainMenuButton",
        Parent = screenGui,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(0, 20, 0.5, -30),
        Size = UDim2.new(0, 60, 0, 60),
        ZIndex = 500
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = menuButton
    })
    
    local menuStroke = Utility.Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 2,
        Parent = menuButton
    })
    
    local menuIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Parent = menuButton,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.FontBold,
        Text = "☰",
        TextColor3 = Theme.Text,
        TextSize = 28,
        ZIndex = 501
    })
    
    local menuClickBtn = Utility.Create("TextButton", {
        Name = "Click",
        Parent = menuButton,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 502
    })
    
    Utility.MakeDraggable(menuButton)
    
    -- Rainbow border effect
    if Theme.RainbowBorder then
        task.spawn(function()
            local hue = 0
            while menuButton.Parent do
                hue = (hue + 0.005 * Theme.RainbowSpeed) % 1
                menuStroke.Color = Color3.fromHSV(hue, 0.8, 1)
                task.wait()
            end
        end)
    end
    
    -- Pulsing animation
    task.spawn(function()
        while menuButton.Parent do
            Utility.Tween(menuButton, {Size = UDim2.new(0, 65, 0, 65)}, 1)
            task.wait(1)
            Utility.Tween(menuButton, {Size = UDim2.new(0, 60, 0, 60)}, 1)
            task.wait(1)
        end
    end)
    
    -- Menu container (expanded state)
    local menuContainer = Utility.Create("Frame", {
        Name = "MenuContainer",
        Parent = screenGui,
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = Theme.MenuBackgroundTransparency,
        Position = UDim2.new(0, 20, 0.5, -200),
        Size = UDim2.new(0, 0, 0, 400),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = menuContainer
    })
    
    local containerStroke = Utility.Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 2,
        Parent = menuContainer
    })
    
    -- Rainbow border for container
    if Theme.RainbowBorder then
        task.spawn(function()
            local hue = 0
            while menuContainer.Parent do
                hue = (hue + 0.005 * Theme.RainbowSpeed) % 1
                containerStroke.Color = Color3.fromHSV(hue, 0.8, 1)
                task.wait()
            end
        end)
    end
    
    -- Header
    local header = Utility.Create("Frame", {
        Name = "Header",
        Parent = menuContainer,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 101
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = header
    })
    
    -- Fix corner for header bottom
    Utility.Create("Frame", {
        Name = "CornerFix",
        Parent = header,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        ZIndex = 101
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.FontBold,
        Text = options.Title or "VapeUI",
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102
    })
    
    local closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        Parent = header,
        BackgroundColor3 = Theme.Error,
        Position = UDim2.new(1, -42, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Theme.FontBold,
        Text = "×",
        TextColor3 = Theme.Text,
        TextSize = 20,
        AutoButtonColor = false,
        ZIndex = 102
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = closeBtn
    })
    
    -- Menu items scroll
    local menuScroll = Utility.Create("ScrollingFrame", {
        Name = "MenuScroll",
        Parent = menuContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 55),
        Size = UDim2.new(1, 0, 1, -60),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 101
    })
    
    Utility.Create("UIListLayout", {
        Parent = menuScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = menuScroll
    })
    
    -- Toggle menu function
    local function toggleMenu()
        mainMenu.IsOpen = not mainMenu.IsOpen
        SoundSystem:Play(mainMenu.IsOpen and "Open" or "Close", 0.5)
        
        if mainMenu.IsOpen then
            menuButton.Visible = false
            menuContainer.Visible = true
            menuContainer.Size = UDim2.new(0, 0, 0, 400)
            Utility.Spring(menuContainer, {Size = UDim2.new(0, 280, 0, 400)}, 0.4)
        else
            -- Close any open submenus
            if mainMenu.CurrentSubMenu then
                mainMenu.CurrentSubMenu:Close()
                mainMenu.CurrentSubMenu = nil
            end
            
            Utility.Tween(menuContainer, {Size = UDim2.new(0, 0, 0, 400)}, 0.3, 
                Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
                    menuContainer.Visible = false
                    menuButton.Visible = true
                end)
        end
    end
    
    menuClickBtn.MouseButton1Click:Connect(toggleMenu)
    menuClickBtn.TouchTap:Connect(toggleMenu)
    
    closeBtn.MouseButton1Click:Connect(function()
        SoundSystem:Play("Close", 0.5)
        toggleMenu()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Utility.Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Utility.Tween(closeBtn, {BackgroundColor3 = Theme.Error}, 0.2)
    end)
    
    -- Create submenu function
    function mainMenu:CreateSubMenu(options)
        options = options or {}
        local name = options.Name or "Menu"
        local icon = options.Icon or "📁"
        
        local subMenu = {
            Name = name,
            IsOpen = false,
            Sections = {},
            Elements = {}
        }
        
        -- Menu item button
        local menuItemBtn = Utility.Create("TextButton", {
            Name = "MenuItem_" .. name,
            Parent = menuScroll,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(1, 0, 0, 45),
            Font = Theme.Font,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 102
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = menuItemBtn
        })
        
        local iconLabel = Utility.Create("TextLabel", {
            Name = "Icon",
            Parent = menuItemBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 30, 1, 0),
            Font = Theme.Font,
            Text = icon,
            TextSize = 20,
            ZIndex = 103
        })
        
        local nameLabel = Utility.Create("TextLabel", {
            Name = "Name",
            Parent = menuItemBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 48, 0, 0),
            Size = UDim2.new(1, -80, 1, 0),
            Font = Theme.Font,
            Text = name,
            TextColor3 = Theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 103
        })
        
        local arrowLabel = Utility.Create("TextLabel", {
            Name = "Arrow",
            Parent = menuItemBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -30, 0, 0),
            Size = UDim2.new(0, 25, 1, 0),
            Font = Theme.FontBold,
            Text = "→",
            TextColor3 = Theme.TextDark,
            TextSize = 16,
            ZIndex = 103
        })
        
        -- Submenu window (independent floating window)
        local subMenuWindow = Utility.Create("Frame", {
            Name = "SubMenu_" .. name,
            Parent = screenGui,
            BackgroundColor3 = Theme.Primary,
            BackgroundTransparency = Theme.ExpandedMenuTransparent and 0.1 or Theme.BackgroundTransparency,
            Position = UDim2.new(0, 320, 0.5, -250),
            Size = UDim2.new(0, 350, 0, 500),
            Visible = false,
            ZIndex = 200
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = subMenuWindow
        })
        
        local subMenuStroke = Utility.Create("UIStroke", {
            Color = Theme.Accent,
            Thickness = 2,
            Parent = subMenuWindow
        })
        
        -- Rainbow effect for submenu
        if Theme.RainbowBorder then
            task.spawn(function()
                local hue = 0
                while subMenuWindow.Parent do
                    hue = (hue + 0.005 * Theme.RainbowSpeed) % 1
                    subMenuStroke.Color = Color3.fromHSV(hue, 0.8, 1)
                    task.wait()
                end
            end)
        end
        
        -- Submenu header
        local subHeader = Utility.Create("Frame", {
            Name = "Header",
            Parent = subMenuWindow,
            BackgroundColor3 = Theme.Secondary,
            Size = UDim2.new(1, 0, 0, 45),
            ZIndex = 201
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = subHeader
        })
        
        Utility.Create("Frame", {
            Name = "CornerFix",
            Parent = subHeader,
            BackgroundColor3 = Theme.Secondary,
            Position = UDim2.new(0, 0, 1, -10),
            Size = UDim2.new(1, 0, 0, 10),
            ZIndex = 201
        })
        
        Utility.Create("TextLabel", {
            Name = "Icon",
            Parent = subHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 30, 1, 0),
            Font = Theme.Font,
            Text = icon,
            TextSize = 20,
            ZIndex = 202
        })
        
        Utility.Create("TextLabel", {
            Name = "Title",
            Parent = subHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 48, 0, 0),
            Size = UDim2.new(1, -100, 1, 0),
            Font = Theme.FontBold,
            Text = name,
            TextColor3 = Theme.Text,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 202
        })
        
        local subCloseBtn = Utility.Create("TextButton", {
            Name = "Close",
            Parent = subHeader,
            BackgroundColor3 = Theme.Error,
            Position = UDim2.new(1, -38, 0.5, 0),
            Size = UDim2.new(0, 26, 0, 26),
            AnchorPoint = Vector2.new(0, 0.5),
            Font = Theme.FontBold,
            Text = "×",
            TextColor3 = Theme.Text,
            TextSize = 18,
            AutoButtonColor = false,
            ZIndex = 202
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = subCloseBtn
        })
        
        -- Content scroll (auto-expand for overflow)
        local contentScroll = Utility.Create("ScrollingFrame", {
            Name = "Content",
            Parent = subMenuWindow,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 50),
            Size = UDim2.new(1, 0, 1, -55),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 201
        })
        
        Utility.Create("UIListLayout", {
            Parent = contentScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = contentScroll
        })
        
        Utility.MakeDraggable(subMenuWindow, subHeader)
        
        -- Open submenu function
        function subMenu:Open()
            if self.IsOpen then return end
            self.IsOpen = true
            
            -- Close other submenus
            if mainMenu.CurrentSubMenu and mainMenu.CurrentSubMenu ~= self then
                mainMenu.CurrentSubMenu:Close()
            end
            mainMenu.CurrentSubMenu = self
            
            SoundSystem:Play("Whoosh", 0.5)
            subMenuWindow.Visible = true
            subMenuWindow.Size = UDim2.new(0, 0, 0, 500)
            subMenuWindow.Position = UDim2.new(0, 320, 0.5, -250)
            
            Utility.Spring(subMenuWindow, {Size = UDim2.new(0, 350, 0, 500)}, 0.4)
            
            Utility.Tween(menuItemBtn, {BackgroundColor3 = Theme.Accent}, 0.2)
            arrowLabel.Text = "✓"
        end
        
        -- Close submenu function
        function subMenu:Close()
            if not self.IsOpen then return end
            self.IsOpen = false
            
            SoundSystem:Play("Close", 0.4)
            
            Utility.Tween(subMenuWindow, {Size = UDim2.new(0, 0, 0, 500)}, 0.25, 
                Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
                    subMenuWindow.Visible = false
                end)
            
            Utility.Tween(menuItemBtn, {BackgroundColor3 = Theme.Tertiary}, 0.2)
            arrowLabel.Text = "→"
            
            if mainMenu.CurrentSubMenu == self then
                mainMenu.CurrentSubMenu = nil
            end
        end
        
        -- Toggle submenu
        function subMenu:Toggle()
            if self.IsOpen then
                self:Close()
            else
                self:Open()
            end
        end
        
        -- Hover effects
        menuItemBtn.MouseEnter:Connect(function()
            SoundSystem:Play("Hover", 0.2)
            if not subMenu.IsOpen then
                Utility.Tween(menuItemBtn, {BackgroundColor3 = Theme.AccentDark}, 0.2)
            end
        end)
        
        menuItemBtn.MouseLeave:Connect(function()
            if not subMenu.IsOpen then
                Utility.Tween(menuItemBtn, {BackgroundColor3 = Theme.Tertiary}, 0.2)
            end
        end)
        
        menuItemBtn.MouseButton1Click:Connect(function()
            SoundSystem:Play("Click", 0.5)
            Utility.Ripple(menuItemBtn, UserInputService:GetMouseLocation().X, 
                UserInputService:GetMouseLocation().Y, Theme.Accent)
            subMenu:Toggle()
        end)
        
        subCloseBtn.MouseButton1Click:Connect(function()
            subMenu:Close()
        end)
        
        subCloseBtn.MouseEnter:Connect(function()
            Utility.Tween(subCloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
        end)
        
        subCloseBtn.MouseLeave:Connect(function()
            Utility.Tween(subCloseBtn, {BackgroundColor3 = Theme.Error}, 0.2)
        end)
        
        -- Create Section function
        function subMenu:CreateSection(options)
            options = options or {}
            local sectionName = options.Name or "Section"
            
            local section = {
                Name = sectionName,
                Elements = {}
            }
            
            local sectionFrame = Utility.Create("Frame", {
                Name = "Section_" .. sectionName,
                Parent = contentScroll,
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 0.3,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 202
            })
            
            Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = sectionFrame
            })
            
            local sectionHeader = Utility.Create("TextLabel", {
                Name = "Header",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 25),
                Font = Theme.FontBold,
                Text = sectionName,
                TextColor3 = Theme.Accent,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 203
            })
            
            local sectionContent = Utility.Create("Frame", {
                Name = "Content",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 30),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 202
            })
            
            Utility.Create("UIListLayout", {
                Parent = sectionContent,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            })
            
            Utility.Create("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = sectionContent
            })
            
            -- Component factory functions
            local elementCounter = 0
            local function getElementId()
                elementCounter = elementCounter + 1
                return name .. "_" .. sectionName .. "_" .. elementCounter
            end
            
            function section:AddButton(opts)
                return Components.CreateButton(sectionContent, opts, getElementId())
            end
            
            function section:AddToggle(opts)
                return Components.CreateToggle(sectionContent, opts, getElementId())
            end
            
            function section:AddSlider(opts)
                return Components.CreateSlider(sectionContent, opts, getElementId())
            end
            
            function section:AddDropdown(opts)
                return Components.CreateDropdown(sectionContent, opts, getElementId())
            end
            
            function section:AddColorPicker(opts)
                return Components.CreateColorPicker(sectionContent, opts, getElementId())
            end
            
            function section:AddKeybind(opts)
                return Components.CreateKeybind(sectionContent, opts, getElementId())
            end
            
            function section:AddTextInput(opts)
                return Components.CreateTextInput(sectionContent, opts, getElementId())
            end
            
            function section:AddSearch(opts)
                return Components.CreateSearch(sectionContent, opts)
            end
            
            function section:AddLabel(opts)
                return Components.CreateLabel(sectionContent, opts)
            end
            
            function section:AddSeparator()
                return Components.CreateSeparator(sectionContent)
            end
            
            table.insert(subMenu.Sections, section)
            return section
        end
        
        table.insert(self.SubMenus, subMenu)
        return subMenu
    end
    
    -- Toggle visibility
    function mainMenu:Toggle()
        toggleMenu()
    end
    
    function mainMenu:Show()
        if not self.IsOpen then
            toggleMenu()
        end
    end
    
    function mainMenu:Hide()
        if self.IsOpen then
            toggleMenu()
        end
    end
    
    return mainMenu
end

--============================================
-- SETTINGS MENU
--============================================
function VapeUI:CreateSettingsMenu(mainMenu)
    local settingsMenu = mainMenu:CreateSubMenu({
        Name = "Settings",
        Icon = "⚙️"
    })
    
    -- UI Settings Section
    local uiSection = settingsMenu:CreateSection({Name = "UI Settings"})
    
    uiSection:AddToggle({
        Text = "Rainbow Border",
        Default = Theme.RainbowBorder,
        Callback = function(value)
            Theme.RainbowBorder = value
        end
    })
    
    uiSection:AddSlider({
        Text = "Rainbow Speed",
        Min = 1,
        Max = 10,
        Default = Theme.RainbowSpeed,
        Increment = 1,
        Suffix = "x",
        Callback = function(value)
            Theme.RainbowSpeed = value
        end
    })
    
    uiSection:AddSlider({
        Text = "Background Transparency",
        Min = 0,
        Max = 90,
        Default = math.floor(Theme.BackgroundTransparency * 100),
        Increment = 5,
        Suffix = "%",
        Callback = function(value)
            Theme.BackgroundTransparency = value / 100
        end
    })
    
    uiSection:AddToggle({
        Text = "Expanded Menu Transparent",
        Default = Theme.ExpandedMenuTransparent,
        Callback = function(value)
            Theme.ExpandedMenuTransparent = value
        end
    })
    
    uiSection:AddColorPicker({
        Text = "Accent Color",
        Default = Theme.Accent,
        Callback = function(color)
            Theme.Accent = color
            Theme.AccentDark = Color3.fromRGB(
                math.max(0, color.R * 255 - 30),
                math.max(0, color.G * 255 - 30),
                math.max(0, color.B * 255 - 30)
            )
            Theme.AccentLight = Color3.fromRGB(
                math.min(255, color.R * 255 + 30),
                math.min(255, color.G * 255 + 30),
                math.min(255, color.B * 255 + 30)
            )
        end
    })
    
    -- Sound Settings Section
    local soundSection = settingsMenu:CreateSection({Name = "Sound Settings"})
    
    soundSection:AddToggle({
        Text = "Enable Sounds",
        Default = SoundSystem.Enabled,
        Callback = function(value)
            SoundSystem.Enabled = value
        end
    })
    
    soundSection:AddSlider({
        Text = "Volume",
        Min = 0,
        Max = 100,
        Default = math.floor(SoundSystem.Volume * 100),
        Increment = 5,
        Suffix = "%",
        Callback = function(value)
            SoundSystem.Volume = value / 100
        end
    })
    
    -- Theme Presets Section
    local themeSection = settingsMenu:CreateSection({Name = "Theme Presets"})
    
    themeSection:AddDropdown({
        Text = "Select Theme",
        Items = {"Dark", "Light", "Purple", "Blue", "Red", "Green", "Midnight"},
        Default = "Dark",
        Callback = function(themeName)
            local preset = ThemePresets[themeName]
            if preset then
                for key, value in pairs(preset) do
                    Theme[key] = value
                end
                SoundSystem:Play("Success", 0.5)
                self:Notify("Theme Applied", "Changed theme to " .. themeName, 2)
            end
        end
    })
    
    -- Config Section
    local configSection = settingsMenu:CreateSection({Name = "Configurations"})
    
    local configName = "Default"
    
    configSection:AddTextInput({
        Text = "Config Name",
        Placeholder = "Enter config name...",
        Default = "Default",
        Callback = function(text)
            if text ~= "" then
                configName = text
            end
        end
    })
    
    local configList = ConfigSystem:GetConfigList()
    local configDropdown = configSection:AddDropdown({
        Text = "Saved Configs",
        Items = #configList > 0 and configList or {"No configs"},
        Default = configList[1] or "No configs",
        Callback = function(selected)
            if selected ~= "No configs" then
                configName = selected
            end
        end
    })
    
    configSection:AddButton({
        Text = "💾 Save Config",
        Callback = function()
            if configName ~= "" then
                if ConfigSystem:SaveConfig(configName) then
                    SoundSystem:Play("ConfigSave", 0.6)
                    self:Notify("✅ Saved", "Config '" .. configName .. "' saved!", 3)
                    
                    -- Refresh dropdown
                    local newList = ConfigSystem:GetConfigList()
                    configDropdown:SetItems(#newList > 0 and newList or {"No configs"})
                else
                    self:Notify("❌ Error", "Failed to save config!", 3, "Error")
                end
            end
        end
    })
    
    configSection:AddButton({
        Text = "📂 Load Config",
        Callback = function()
            if ConfigSystem:LoadConfig(configName) then
                SoundSystem:Play("ConfigLoad", 0.6)
                
                -- Theme flash effect
                AnimationSystem.ThemeFlash(self.ScreenGui, Theme.Accent, 0.4)
                
                self:Notify("✅ Loaded", "Config '" .. configName .. "' loaded!", 3)
            else
                self:Notify("❌ Error", "Config not found!", 3, "Error")
            end
        end
    })
    
    configSection:AddButton({
        Text = "🗑️ Delete Config",
        Callback = function()
            if ConfigSystem:DeleteConfig(configName) then
                SoundSystem:Play("Success", 0.5)
                self:Notify("✅ Deleted", "Config '" .. configName .. "' deleted!", 3)
                
                local newList = ConfigSystem:GetConfigList()
                configDropdown:SetItems(#newList > 0 and newList or {"No configs"})
            else
                self:Notify("❌ Error", "Failed to delete config!", 3, "Error")
            end
        end
    })
    
    configSection:AddButton({
        Text = "🔄 Refresh List",
        Callback = function()
            ConfigSystem:LoadAllConfigs()
            local newList = ConfigSystem:GetConfigList()
            configDropdown:SetItems(#newList > 0 and newList or {"No configs"})
            SoundSystem:Play("Success", 0.4)
            self:Notify("🔄 Refreshed", "Config list updated!", 2)
        end
    })
    
    return settingsMenu
end

--============================================
-- MAIN LIBRARY
--============================================
function VapeUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, VapeUI)
    
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
    
    -- Initialize notification system
    NotificationSystem:Initialize(self.ScreenGui)
    
    -- Show loading screen
    if options.LoadingScreen ~= false then
        LoadingScreen:Create(self.ScreenGui, {
            Title = options.Title or "VapeUI",
            Subtitle = options.Subtitle or "Loading...",
            Duration = options.LoadingDuration or 3
        })
        
        task.wait((options.LoadingDuration or 3) + 0.5)
    end
    
    -- Create main menu
    self.MainMenu = MenuSystem:CreateMainMenu(self.ScreenGui, {
        Title = options.Title or "VapeUI"
    })
    
    -- Create settings menu
    self:CreateSettingsMenu(self.MainMenu)
    
    -- Toggle key
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == toggleKey then
            self.MainMenu:Toggle()
        end
    end)
    
    -- Mobile toggle button
    if IS_MOBILE then
        local mobileToggle = Utility.Create("TextButton", {
            Name = "MobileToggle",
            Parent = self.ScreenGui,
            BackgroundColor3 = Theme.Accent,
            Position = UDim2.new(1, -60, 0, 10),
            Size = UDim2.new(0, 50, 0, 50),
            Font = Theme.FontBold,
            Text = "≡",
            TextColor3 = Theme.Text,
            TextSize = 26,
            ZIndex = 9999
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = mobileToggle
        })
        
        Utility.MakeDraggable(mobileToggle)
        
        mobileToggle.TouchTap:Connect(function()
            self.MainMenu:Toggle()
        end)
    end
    
    return self
end

-- Create SubMenu wrapper
function VapeUI:CreateSubMenu(options)
    return self.MainMenu:CreateSubMenu(options)
end

-- Notification wrapper
function VapeUI:Notify(title, message, duration, notifType)
    return NotificationSystem:Notify(title, message, duration, notifType)
end

-- Theme flash
function VapeUI:FlashTheme(color, duration)
    AnimationSystem.ThemeFlash(self.ScreenGui, color or Theme.Accent, duration or 0.4)
end

-- Destroy
function VapeUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Expose systems
VapeUI.Theme = Theme
VapeUI.ConfigSystem = ConfigSystem
VapeUI.SoundSystem = SoundSystem
VapeUI.AnimationSystem = AnimationSystem
VapeUI.Utility = Utility
VapeUI.Components = Components

return VapeUI
