--[[
    >>> ORION-VAPE ENGINE PRO <<<
    Version: 2.0.0 (Titanium)
    Type: Multi-Window Floating GUI (Vape Style)
    Platform: PC & Mobile Support
    Features: Rainbow Borders, Circular ColorPicker, Config System, Advanced Animations
    
    Author: AI Assistant
    License: MIT
]]

--/// SERVICES ///--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

--/// CONSTANTS & VARIABLES ///--
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize

local LIBRARY_NAME = "VapeClone_v2"
local FOLDER_NAME = "VapeConfigs"
local SETTINGS_FILE = "UISettings.json"

--/// LIBRARY TABLE ///--
local Library = {
    Windows = {},
    Flags = {},
    RainbowTable = {}, -- Objects that need rainbow effect
    Connections = {},
    Settings = {
        RainbowBorder = false,
        RainbowSpeed = 5,
        UIBorderColor = Color3.fromRGB(60, 60, 60),
        MainColor = Color3.fromRGB(20, 20, 20),
        AccentColor = Color3.fromRGB(0, 255, 170),
        Transparency = 0,
        BackgroundTransparency = 0.1,
        Font = Enum.Font.Gotham
    },
    IsMobile = UserInputService.TouchEnabled
}

--/// UTILITY FUNCTIONS ///--

local function GetAsset(id)
    return "rbxassetid://" .. tostring(id)
end

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X, 
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        TweenService:Create(object, TweenInfo.new(0.05), {Position = newPos}):Play()
    end

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
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

-- Math for Circular Color Picker
local function ToPolar(v)
    return math.atan2(v.Y, v.X), v.Magnitude
end

local function RadToDeg(x)
    return ((x + math.pi) / (2 * math.pi)) * 360
end

--/// LOADING ANIMATION SYSTEM ///--

function Library:LoadIntro()
    local IntroGui = Create("ScreenGui", {Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    local Background = Create("Frame", {
        Parent = IntroGui, Size = UDim2.new(1,0,1,0), 
        BackgroundColor3 = Color3.fromRGB(10,10,10), ZIndex = 999
    })
    
    local LogoContainer = Create("Frame", {
        Parent = Background, Size = UDim2.new(0, 200, 0, 200),
        Position = UDim2.new(0.5, -100, 0.5, -100), BackgroundTransparency = 1
    })
    
    local Spinner = Create("ImageLabel", {
        Parent = LogoContainer, Size = UDim2.new(1,0,1,0),
        Image = GetAsset(6925694263), -- Circular ring
        ImageColor3 = Library.Settings.AccentColor, BackgroundTransparency = 1
    })

    local Title = Create("TextLabel", {
        Parent = LogoContainer, Size = UDim2.new(1,0,1,0),
        Text = "VAPE\nCLONE", Font = Enum.Font.GothamBold, TextSize = 30,
        TextColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 1
    })

    -- Animation Sequence
    local SpinInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
    local SpinTween = TweenService:Create(Spinner, SpinInfo, {Rotation = 360})
    SpinTween:Play()
    
    wait(1.5)
    
    -- Collapse Animation
    SpinTween:Cancel()
    TweenService:Create(Spinner, TweenInfo.new(0.5), {Size = UDim2.new(0,0,0,0), ImageTransparency = 1}):Play()
    TweenService:Create(Title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(Background, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    
    wait(1)
    IntroGui:Destroy()
end

--/// SAVE/LOAD SYSTEM ///--

function Library:SaveConfig()
    if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
    local json = HttpService:JSONEncode(Library.Flags)
    writefile(FOLDER_NAME .. "/" .. "Default.json", json)
    
    -- Save Settings
    local settingsJson = HttpService:JSONEncode(Library.Settings)
    writefile(FOLDER_NAME .. "/" .. SETTINGS_FILE, settingsJson)
end

function Library:LoadConfig()
    if not isfolder(FOLDER_NAME) then return end
    
    -- Load UI Settings
    if isfile(FOLDER_NAME .. "/" .. SETTINGS_FILE) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FOLDER_NAME .. "/" .. SETTINGS_FILE))
        end)
        if success then
            for k,v in pairs(result) do Library.Settings[k] = v end
        end
    end
    
    -- Load Flags
    if isfile(FOLDER_NAME .. "/" .. "Default.json") then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FOLDER_NAME .. "/" .. "Default.json"))
        end)
        if success then
            Library.Flags = result
            -- Note: In a real implementation, you would trigger callbacks here
        end
    end
end

--/// RAINBOW RENDERER ///--
RunService.RenderStepped:Connect(function()
    if Library.Settings.RainbowBorder then
        local hue = tick() % Library.Settings.RainbowSpeed / Library.Settings.RainbowSpeed
        local color = Color3.fromHSV(hue, 1, 1)
        for _, obj in pairs(Library.RainbowTable) do
            if obj:IsA("UIStroke") then
                obj.Color = color
            elseif obj:IsA("Frame") or obj:IsA("ImageLabel") then
                obj.BackgroundColor3 = color -- Can be adjusted
            end
        end
    end
end)

--/// MAIN GUI CREATION ///--

local ScreenGui = Create("ScreenGui", {
    Name = LIBRARY_NAME,
    Parent = CoreGui,
    ResetOnSpawn = false
})

function Library:Window(name)
    -- Dynamic positioning based on window count
    local xOffset = 50 + (#Library.Windows * 220)
    
    local WindowFrame = Create("Frame", {
        Name = "Window_" .. name,
        Parent = ScreenGui,
        BackgroundColor3 = Library.Settings.MainColor,
        BackgroundTransparency = Library.Settings.BackgroundTransparency,
        Position = UDim2.new(0, xOffset, 0, 50),
        Size = UDim2.new(0, 200, 0, 300), -- Initial Size
        BorderSizePixel = 0
    })
    
    local Stroke = Create("UIStroke", {
        Parent = WindowFrame,
        Color = Library.Settings.UIBorderColor,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    table.insert(Library.RainbowTable, Stroke)

    local Corner = Create("UICorner", {Parent = WindowFrame, CornerRadius = UDim.new(0, 6)})

    -- Topbar
    local Topbar = Create("Frame", {
        Parent = WindowFrame,
        BackgroundColor3 = Library.Settings.MainColor,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 35),
        BorderSizePixel = 0
    })
    Create("UICorner", {Parent = Topbar, CornerRadius = UDim.new(0, 6)})
    
    -- Fix bottom corners of topbar
    local FixPatch = Create("Frame", {
        Parent = Topbar,
        BackgroundColor3 = Library.Settings.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0,0,1,-10)
    })

    local Title = Create("TextLabel", {
        Parent = Topbar,
        Text = name:upper(),
        TextColor3 = Library.Settings.AccentColor,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Expand/Collapse Button
    local ExpandBtn = Create("ImageButton", {
        Parent = Topbar,
        BackgroundTransparency = 1,
        Image = GetAsset(6031094678), -- Chevron
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0, 7)
    })

    -- Container for elements
    local Container = Create("ScrollingFrame", {
        Parent = WindowFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -45),
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    local Layout = Create("UIListLayout", {
        Parent = Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    local Padding = Create("UIPadding", {
        Parent = Container, 
        PaddingLeft = UDim.new(0, 5), 
        PaddingRight = UDim.new(0, 5)
    })

    -- Logic for Dragging and Expanding
    MakeDraggable(Topbar, WindowFrame)
    table.insert(Library.Windows, WindowFrame)
    
    local Expanded = true
    ExpandBtn.MouseButton1Click:Connect(function()
        Expanded = not Expanded
        if Expanded then
            TweenService:Create(WindowFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 300)}):Play()
            TweenService:Create(ExpandBtn, TweenInfo.new(0.3), {Rotation = 0}):Play()
            Container.Visible = true
        else
            TweenService:Create(WindowFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 35)}):Play()
            TweenService:Create(ExpandBtn, TweenInfo.new(0.3), {Rotation = 180}):Play()
            Container.Visible = false
        end
    end)
    
    -- Auto-Resize Canvas
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Container.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
    end)

    -- Elements Functions
    local Elements = {}

    --/// BUTTON COMPONENT ///--
    function Elements:Button(text, callback)
        local BtnFrame = Create("Frame", {
            Parent = Container,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Size = UDim2.new(1, 0, 0, 32)
        })
        Create("UICorner", {Parent = BtnFrame, CornerRadius = UDim.new(0, 4)})
        
        local BtnTitle = Create("TextLabel", {
            Parent = BtnFrame,
            Text = text,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        })
        
        local Click = Create("TextButton", {
            Parent = BtnFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""
        })
        
        Click.MouseButton1Click:Connect(function()
            -- Ripple effect or color flash
            TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Library.Settings.AccentColor}):Play()
            task.wait(0.1)
            TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
            pcall(callback)
        end)
    end

    --/// TOGGLE COMPONENT ///--
    function Elements:Toggle(text, default, callback)
        local toggled = default or false
        Library.Flags[text] = toggled
        
        local ToggleFrame = Create("Frame", {
            Parent = Container,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Size = UDim2.new(1, 0, 0, 32)
        })
        Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 4)})
        
        local ToggleText = Create("TextLabel", {
            Parent = ToggleFrame,
            Text = text,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local SwitchBg = Create("Frame", {
            Parent = ToggleFrame,
            BackgroundColor3 = toggled and Library.Settings.AccentColor or Color3.fromRGB(50, 50, 50),
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -45, 0.5, -9)
        })
        Create("UICorner", {Parent = SwitchBg, CornerRadius = UDim.new(1, 0)})
        
        local SwitchDot = Create("Frame", {
            Parent = SwitchBg,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 14, 0, 14),
            Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        })
        Create("UICorner", {Parent = SwitchDot, CornerRadius = UDim.new(1, 0)})
        
        local Click = Create("TextButton", {Parent = ToggleFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""})
        
        local function Update()
            toggled = not toggled
            Library.Flags[text] = toggled
            
            local targetColor = toggled and Library.Settings.AccentColor or Color3.fromRGB(50, 50, 50)
            local targetPos = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            
            TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(SwitchDot, TweenInfo.new(0.2), {Position = targetPos}):Play()
            
            pcall(callback, toggled)
        end
        
        Click.MouseButton1Click:Connect(Update)
    end

    --/// SLIDER COMPONENT ///--
    function Elements:Slider(text, min, max, default, callback)
        local value = default or min
        local dragging = false
        
        local SliderFrame = Create("Frame", {
            Parent = Container,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Size = UDim2.new(1, 0, 0, 45)
        })
        Create("UICorner", {Parent = SliderFrame, CornerRadius = UDim.new(0, 4)})
        
        local SliderTitle = Create("TextLabel", {
            Parent = SliderFrame,
            Text = text,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Size = UDim2.new(1, -10, 0, 20),
            Position = UDim2.new(0, 10, 0, 2),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local ValueLabel = Create("TextLabel", {
            Parent = SliderFrame,
            Text = tostring(value),
            TextColor3 = Color3.fromRGB(150, 150, 150),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(1, -50, 0, 2),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        
        local Track = Create("Frame", {
            Parent = SliderFrame,
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Size = UDim2.new(1, -20, 0, 4),
            Position = UDim2.new(0, 10, 0, 30)
        })
        Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
        
        local Fill = Create("Frame", {
            Parent = Track,
            BackgroundColor3 = Library.Settings.AccentColor,
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        })
        Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
        
        local Click = Create("TextButton", {Parent = SliderFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""})
        
        local function Update(input)
            local pos = UDim2.new(math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1), 0, 1, 0)
            Fill.Size = pos
            local result = math.floor(min + ((max - min) * pos.X.Scale))
            ValueLabel.Text = tostring(result)
            Library.Flags[text] = result
            pcall(callback, result)
        end
        
        Click.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                Update(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                Update(input)
            end
        end)
    end

    --/// CIRCULAR COLOR PICKER (ADVANCED) ///--
    function Elements:ColorPicker(text, default, callback)
        local color = default or Color3.fromRGB(255, 255, 255)
        local isOpen = false
        
        local PickerFrame = Create("Frame", {
            Parent = Container,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Size = UDim2.new(1, 0, 0, 32),
            ClipsDescendants = true
        })
        Create("UICorner", {Parent = PickerFrame, CornerRadius = UDim.new(0, 4)})
        
        local Title = Create("TextLabel", {
            Parent = PickerFrame,
            Text = text,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Size = UDim2.new(1, -40, 0, 32),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Preview = Create("Frame", {
            Parent = PickerFrame,
            BackgroundColor3 = color,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -30, 0, 6)
        })
        Create("UICorner", {Parent = Preview, CornerRadius = UDim.new(0, 4)}) -- Rounded square preview
        
        local Click = Create("TextButton", {Parent = PickerFrame, Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Text = ""})
        
        -- The Palette Container
        local Palette = Create("Frame", {
            Parent = PickerFrame,
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            Size = UDim2.new(1, -10, 0, 140),
            Position = UDim2.new(0, 5, 0, 35),
            BackgroundTransparency = 1
        })
        
        -- Circular Hue Wheel
        local Wheel = Create("ImageButton", {
            Parent = Palette,
            Image = GetAsset(6020299385), -- RGB Wheel
            Size = UDim2.new(0, 120, 0, 120),
            Position = UDim2.new(0.5, -60, 0, 10),
            BackgroundTransparency = 1
        })
        
        -- Selector Dot
        local Selector = Create("Frame", {
            Parent = Wheel,
            BackgroundColor3 = Color3.new(1,1,1),
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        Create("UICorner", {Parent = Selector, CornerRadius = UDim.new(1,0)})
        Create("UIStroke", {Parent = Selector, Thickness = 1, Color = Color3.new(0,0,0)})
        
        local dragging = false
        
        local function UpdateColor(input)
            local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize/2)
            local vector = Vector2.new(input.Position.X, input.Position.Y) - center
            
            -- Calculate rotation (Hue)
            local angle = math.atan2(vector.Y, vector.X)
            local hue = (math.deg(angle) + 180) / 360
            
            -- Calculate saturation (Distance from center)
            local dist = math.min(vector.Magnitude, Wheel.AbsoluteSize.X/2)
            local sat = dist / (Wheel.AbsoluteSize.X/2)
            
            -- Move selector visually
            local realDist = math.min(vector.Magnitude, Wheel.AbsoluteSize.X/2 - 5)
            local offsetX = math.cos(angle) * realDist
            local offsetY = math.sin(angle) * realDist
            
            Selector.Position = UDim2.new(0.5, offsetX - 5, 0.5, offsetY - 5)
            
            -- Update Value
            color = Color3.fromHSV(hue, sat, 1)
            Preview.BackgroundColor3 = color
            pcall(callback, color)
        end
        
        Wheel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                UpdateColor(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateColor(input) end
        end)
        
        Click.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                TweenService:Create(PickerFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 180)}):Play()
            else
                TweenService:Create(PickerFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 32)}):Play()
            end
        end)
    end

    --/// DROPDOWN WITH SEARCH ///--
    function Elements:Dropdown(text, list, callback)
        local isOpen = false
        
        local DropFrame = Create("Frame", {
            Parent = Container,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Size = UDim2.new(1, 0, 0, 32),
            ClipsDescendants = true
        })
        Create("UICorner", {Parent = DropFrame, CornerRadius = UDim.new(0, 4)})
        
        local Title = Create("TextLabel", {
            Parent = DropFrame,
            Text = text,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Size = UDim2.new(1, -30, 0, 32),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Arrow = Create("ImageLabel", {
            Parent = DropFrame,
            Image = GetAsset(6034818372),
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -25, 0, 8),
            BackgroundTransparency = 1
        })
        
        local Click = Create("TextButton", {Parent = DropFrame, Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Text = ""})
        
        -- Search Bar
        local SearchBar = Create("TextBox", {
            Parent = DropFrame,
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            PlaceholderText = "Search...",
            TextColor3 = Color3.new(1,1,1),
            Text = "",
            Visible = false
        })
        Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 4)})
        
        local ListFrame = Create("ScrollingFrame", {
            Parent = DropFrame,
            Size = UDim2.new(1, 0, 1, -65),
            Position = UDim2.new(0, 0, 0, 65),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 2
        })
        local ListLayout = Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})
        
        local function Populate(filter)
            for _, child in pairs(ListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            
            for _, item in pairs(list) do
                if not filter or string.find(string.lower(item), string.lower(filter)) then
                    local ItemBtn = Create("TextButton", {
                        Parent = ListFrame,
                        Size = UDim2.new(1, 0, 0, 25),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                        Text = item,
                        TextColor3 = Color3.fromRGB(180, 180, 180),
                        Font = Enum.Font.Gotham
                    })
                    
                    ItemBtn.MouseButton1Click:Connect(function()
                        Title.Text = text .. ": " .. item
                        pcall(callback, item)
                        isOpen = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 32)}):Play()
                        TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                    end)
                end
            end
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end
        
        SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
            Populate(SearchBar.Text)
        end)
        
        Click.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                SearchBar.Visible = true
                Populate("")
                TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 200)}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
            else
                TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 32)}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                SearchBar.Visible = false
            end
        end)
    end

    return Elements
end

--/// UI CUSTOMIZATION INTERFACE ///--

function Library:InitSettingsWindow()
    local SetWin = Library:Window("Settings")
    
    SetWin:Button("Save Config", function() Library:SaveConfig() end)
    SetWin:Button("Load Config", function() Library:LoadConfig() end)
    
    SetWin:Toggle("Rainbow Borders", false, function(v)
        Library.Settings.RainbowBorder = v
    end)
    
    SetWin:Slider("Rainbow Speed", 1, 10, 5, function(v)
        Library.Settings.RainbowSpeed = v
    end)
    
    SetWin:Slider("UI Transparency", 0, 100, 10, function(v)
        for _, win in pairs(Library.Windows) do
            win.BackgroundTransparency = v / 100
        end
    end)
    
    SetWin:ColorPicker("Accent Color", Library.Settings.AccentColor, function(c)
        Library.Settings.AccentColor = c
        -- Note: Realtime updating all existing elements is complex without observers, 
        -- but new elements will use this color.
    end)
    
    SetWin:Button("Unload GUI", function()
        ScreenGui:Destroy()
    end)
end

--/// EXECUTION ///--

Library:LoadIntro()
Library:InitSettingsWindow()

return Library
