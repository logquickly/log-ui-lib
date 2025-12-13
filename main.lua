--[[
    VapeX Legacy UI Library
    Style: Vape V4 Inspired (Sharp Edges, Multi-Window)
    Platform: Desktop & Mobile
    Version: 1.0.0 Alpha
    
    Features:
    - Multiple Draggable Windows
    - Advanced Loading Animation
    - Circular Color Picker
    - Rainbow Borders & Custom Themes
    - Config System (Save/Load)
    - Smooth Tweening & Ripple Effects
    - Mobile Support
    - Searchable Dropdowns
    
    Credits: Generated for User Request
]]

--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

--// Optimization & Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize

--// Root Table
local Library = {
    Windows = {},
    Theme = {
        Accent = Color3.fromRGB(0, 255, 170),
        Background = Color3.fromRGB(20, 20, 20),
        ItemBack = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(0, 0, 0),
        RainbowBorder = false,
        UITransparency = 0,
        BackTransparency = 0.1,
        Scale = 1.0
    },
    Folder = "VapeXConfig",
    Flags = {},
    Connections = {},
    IsMobile = table.find({Enum.Platform.IOS, Enum.Platform.Android}, UserInputService:GetPlatform())
}

--// Protected Gui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VapeX_" .. tostring(math.random(1000, 9999))
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then 
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

--// Utility Functions
local Utility = {}

function Utility:Tween(obj, info, props)
    local anim = TweenService:Create(obj, info, props)
    anim:Play()
    return anim
end

function Utility:Validate(defaults, options)
    for i, v in pairs(defaults) do
        if options[i] == nil then
            options[i] = v
        end
    end
    return options
end

function Utility:GetTextSize(text, font, size)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

function Utility:Ripple(obj)
    spawn(function()
        local Ripple = Instance.new("ImageLabel")
        Ripple.Name = "Ripple"
        Ripple.Parent = obj
        Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Ripple.BackgroundTransparency = 1.000
        Ripple.BorderSizePixel = 0
        Ripple.Image = "rbxassetid://2708891598"
        Ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
        Ripple.ImageTransparency = 0.800
        Ripple.ScaleType = Enum.ScaleType.Fit
        
        local MouseLocation = UserInputService:GetMouseLocation()
        local RelativeX = MouseLocation.X - obj.AbsolutePosition.X
        local RelativeY = MouseLocation.Y - obj.AbsolutePosition.Y - 36 -- Offset
        
        Ripple.Position = UDim2.new(0, RelativeX, 0, RelativeY)
        Ripple.Size = UDim2.new(0, 0, 0, 0)
        
        local TweenInfo_Ripple = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        Utility:Tween(Ripple, TweenInfo_Ripple, {Size = UDim2.new(0, 300, 0, 300), ImageTransparency = 1})
        
        wait(0.5)
        Ripple:Destroy()
    end)
end

function Utility:MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        Utility:Tween(frame, TweenInfo.new(0.05), {Position = targetPos})
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

--// Signal Class (Custom Events)
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_funcs = {}}, Signal)
end

function Signal:Connect(func)
    local connection = {
        _func = func,
        _signal = self,
        Connected = true
    }
    table.insert(self._funcs, connection)
    
    function connection:Disconnect()
        self.Connected = false
        for i, v in ipairs(self._signal._funcs) do
            if v == self then
                table.remove(self._signal._funcs, i)
                break
            end
        end
    end
    
    return connection
end

function Signal:Fire(...)
    for _, connection in ipairs(self._funcs) do
        if connection.Connected then
            coroutine.wrap(connection._func)(...)
        end
    end
end

--// Config System
local SaveManager = {}
local ConfigSignal = Signal.new()

function SaveManager:Save(name)
    if not isfolder(Library.Folder) then makefolder(Library.Folder) end
    local json = HttpService:JSONEncode(Library.Flags)
    writefile(Library.Folder .. "/" .. name .. ".json", json)
    ConfigSignal:Fire()
end

function SaveManager:Load(name)
    local path = Library.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        local json = readfile(path)
        local data = HttpService:JSONDecode(json)
        for flag, value in pairs(data) do
            if Library.Flags[flag] ~= nil then
                -- Trigger callback update here if needed
                -- For now we just update table, specific elements need SetValue logic
            end
        end
        return data -- Elements should hook into this or check flags
    end
    return nil
end

function SaveManager:GetConfigs()
    if not isfolder(Library.Folder) then makefolder(Library.Folder) end
    local files = listfiles(Library.Folder)
    local configs = {}
    for _, file in ipairs(files) do
        local name = file:match("([^/]+)%.json$")
        if name then table.insert(configs, name) end
    end
    return configs
end

--// Theme Manager (Rainbow & Updates)
local ThemeManager = {}
local RainbowObjects = {} -- Objects that need rainbow border

function ThemeManager:RegisterBorder(instance)
    table.insert(RainbowObjects, instance)
end

RunService.Heartbeat:Connect(function()
    if Library.Theme.RainbowBorder then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        for _, obj in pairs(RainbowObjects) do
            if obj:IsA("UIStroke") then
                obj.Color = color
            elseif obj:IsA("Frame") or obj:IsA("TextButton") then
                obj.BorderColor3 = color
            end
        end
    else
        -- Revert to static theme border
        for _, obj in pairs(RainbowObjects) do
             if obj:IsA("UIStroke") then
                obj.Color = Library.Theme.Border
            elseif obj:IsA("Frame") or obj:IsA("TextButton") then
                obj.BorderColor3 = Library.Theme.Border
            end
        end
    end
end)

function Library:UpdateTheme()
    -- Propagate theme changes to all windows
    for _, window in pairs(Library.Windows) do
        window.MainFrame.BackgroundColor3 = Library.Theme.Background
        window.MainFrame.BackgroundTransparency = Library.Theme.BackTransparency
        -- Update other elements recursively if needed
    end
end

--// UI Loading Animation
function Library:LoadAnimation()
    local LoadScreen = Instance.new("Frame")
    LoadScreen.Name = "Loader"
    LoadScreen.Parent = ScreenGui
    LoadScreen.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    LoadScreen.Size = UDim2.new(1, 0, 1, 0)
    LoadScreen.ZIndex = 9999
    
    local Logo = Instance.new("ImageLabel")
    Logo.Parent = LoadScreen
    Logo.AnchorPoint = Vector2.new(0.5, 0.5)
    Logo.Position = UDim2.new(0.5, 0, 0.5, -50)
    Logo.Size = UDim2.new(0, 0, 0, 0) -- Start small
    Logo.Image = "rbxassetid://7072729817" -- Example logo
    Logo.BackgroundTransparency = 1
    
    local BarBack = Instance.new("Frame")
    BarBack.Parent = LoadScreen
    BarBack.AnchorPoint = Vector2.new(0.5, 0.5)
    BarBack.Position = UDim2.new(0.5, 0, 0.5, 50)
    BarBack.Size = UDim2.new(0, 300, 0, 6)
    BarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BarBack.BorderSizePixel = 0
    
    local BarFill = Instance.new("Frame")
    BarFill.Parent = BarBack
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Library.Theme.Accent
    BarFill.BorderSizePixel = 0
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Parent = LoadScreen
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 80)
    TextLabel.Size = UDim2.new(0, 200, 0, 20)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "Initializing VapeX..."
    TextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    TextLabel.Font = Enum.Font.Code
    TextLabel.TextSize = 14
    
    -- Animation Sequence
    Utility:Tween(Logo, TweenInfo.new(1, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 100, 0, 100)})
    wait(0.5)
    Utility:Tween(BarFill, TweenInfo.new(2, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 1, 0)})
    
    local texts = {"Loading Modules...", "Hooking Events...", "Bypassing...", "Ready!"}
    for _, t in ipairs(texts) do
        TextLabel.Text = t
        wait(0.4)
    end
    
    wait(0.5)
    Utility:Tween(LoadScreen, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    Utility:Tween(Logo, TweenInfo.new(0.5), {ImageTransparency = 1})
    Utility:Tween(BarBack, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    Utility:Tween(BarFill, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    Utility:Tween(TextLabel, TweenInfo.new(0.5), {TextTransparency = 1})
    
    wait(0.5)
    LoadScreen:Destroy()
end

--// Main Window Creation
function Library:Window(name)
    local Window = {}
    local WindowExpanded = true
    
    -- Frame Setup
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = name .. "_Window"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Library.Theme.Background
    MainFrame.BackgroundTransparency = Library.Theme.BackTransparency
    MainFrame.BorderSizePixel = 0 -- We use UIStroke for sharp edges
    MainFrame.Position = UDim2.new(0, 50 + (#Library.Windows * 220), 0, 50)
    MainFrame.Size = UDim2.new(0, 200, 0, 300) -- Initial Size
    
    -- Sharp Border
    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Parent = MainFrame
    BorderStroke.Thickness = 1
    BorderStroke.Color = Library.Theme.Border
    BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:RegisterBorder(BorderStroke)
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Text = name
    Title.Font = Enum.Font.Sarpanch -- Sharp futuristic font
    Title.TextColor3 = Library.Theme.Text
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Expand/Collapse Button
    local ExpandBtn = Instance.new("TextButton")
    ExpandBtn.Parent = TopBar
    ExpandBtn.BackgroundTransparency = 1
    ExpandBtn.Position = UDim2.new(1, -25, 0, 0)
    ExpandBtn.Size = UDim2.new(0, 25, 0, 30)
    ExpandBtn.Text = "-"
    ExpandBtn.TextColor3 = Library.Theme.Text
    ExpandBtn.TextSize = 20
    ExpandBtn.Font = Enum.Font.Code
    
    -- Content Container
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Parent = MainFrame
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.new(0, 0, 0, 31)
    Content.Size = UDim2.new(1, 0, 1, -31)
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = Library.Theme.Accent
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = Content
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 4)
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.Parent = Content
    UIPadding.PaddingTop = UDim.new(0, 4)
    UIPadding.PaddingLeft = UDim.new(0, 4)
    UIPadding.PaddingRight = UDim.new(0, 4)
    
    -- Auto Resize
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Toggle Logic
    ExpandBtn.MouseButton1Click:Connect(function()
        WindowExpanded = not WindowExpanded
        if WindowExpanded then
            Utility:Tween(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 300)})
            ExpandBtn.Text = "-"
            Content.Visible = true
        else
            Utility:Tween(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 30)})
            ExpandBtn.Text = "+"
            Content.Visible = false
        end
    end)
    
    Utility:MakeDraggable(MainFrame, TopBar)
    table.insert(Library.Windows, {MainFrame = MainFrame})
    
    --// Elements
    
    -- 1. Button
    function Window:Button(text, callback)
        callback = callback or function() end
        
        local BtnObj = Instance.new("TextButton")
        BtnObj.Parent = Content
        BtnObj.BackgroundColor3 = Library.Theme.ItemBack
        BtnObj.Size = UDim2.new(1, 0, 0, 30)
        BtnObj.Text = text
        BtnObj.TextColor3 = Library.Theme.Text
        BtnObj.Font = Enum.Font.Gotham
        BtnObj.TextSize = 14
        BtnObj.AutoButtonColor = false
        
        -- Sharp Border for Button
        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Parent = BtnObj
        BtnStroke.Thickness = 1
        BtnStroke.Color = Color3.fromRGB(40,40,40)
        BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        BtnObj.MouseEnter:Connect(function()
            Utility:Tween(BtnObj, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)})
        end)
        
        BtnObj.MouseLeave:Connect(function()
            Utility:Tween(BtnObj, TweenInfo.new(0.2), {BackgroundColor3 = Library.Theme.ItemBack})
        end)
        
        BtnObj.MouseButton1Click:Connect(function()
            Utility:Ripple(BtnObj)
            callback()
        end)
        
        return BtnObj
    end
    
    -- 2. Toggle
    function Window:Toggle(text, configName, default, callback)
        callback = callback or function() end
        local state = default or false
        Library.Flags[configName] = state
        
        local ToggleFrame = Instance.new("TextButton")
        ToggleFrame.Parent = Content
        ToggleFrame.BackgroundColor3 = Library.Theme.ItemBack
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.Text = ""
        ToggleFrame.AutoButtonColor = false
        
        local Title = Instance.new("TextLabel")
        Title.Parent = ToggleFrame
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.Size = UDim2.new(0.7, 0, 1, 0)
        Title.Text = text
        Title.TextColor3 = Library.Theme.Text
        Title.Font = Enum.Font.Gotham
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left
        
        local CheckBox = Instance.new("Frame")
        CheckBox.Parent = ToggleFrame
        CheckBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        CheckBox.Position = UDim2.new(1, -25, 0.5, -7.5)
        CheckBox.Size = UDim2.new(0, 15, 0, 15)
        CheckBox.BorderSizePixel = 0
        
        local CheckStroke = Instance.new("UIStroke")
        CheckStroke.Parent = CheckBox
        CheckStroke.Color = Color3.fromRGB(60,60,60)
        CheckStroke.Thickness = 1
        
        local Indicator = Instance.new("Frame")
        Indicator.Parent = CheckBox
        Indicator.BackgroundColor3 = Library.Theme.Accent
        Indicator.Size = UDim2.new(1, 0, 1, 0)
        Indicator.BackgroundTransparency = state and 0 or 1
        Indicator.BorderSizePixel = 0
        
        local function Update()
            state = not state
            Library.Flags[configName] = state
            Utility:Tween(Indicator, TweenInfo.new(0.2), {BackgroundTransparency = state and 0 or 1})
            callback(state)
        end
        
        ToggleFrame.MouseButton1Click:Connect(function()
            Update()
        end)
        
        -- Load Config Hook
        if default then callback(state) end
        
        return {
            Set = function(val)
                state = not val -- flip because Update flips it back
                Update()
            end
        }
    end
    
    -- 3. Slider
    function Window:Slider(text, configName, min, max, default, callback)
        callback = callback or function() end
        local value = default or min
        Library.Flags[configName] = value
        
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Parent = Content
        SliderFrame.BackgroundColor3 = Library.Theme.ItemBack
        SliderFrame.Size = UDim2.new(1, 0, 0, 45)
        SliderFrame.BorderSizePixel = 0
        
        local Title = Instance.new("TextLabel")
        Title.Parent = SliderFrame
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 10, 0, 5)
        Title.Size = UDim2.new(1, -20, 0, 15)
        Title.Text = text .. ": " .. value
        Title.TextColor3 = Library.Theme.Text
        Title.Font = Enum.Font.Gotham
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left
        
        local Bar = Instance.new("Frame")
        Bar.Parent = SliderFrame
        Bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        Bar.Position = UDim2.new(0, 10, 0, 25)
        Bar.Size = UDim2.new(1, -20, 0, 10)
        Bar.BorderSizePixel = 0
        
        local Fill = Instance.new("Frame")
        Fill.Parent = Bar
        Fill.BackgroundColor3 = Library.Theme.Accent
        Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        Fill.BorderSizePixel = 0
        
        local isDragging = false
        
        local function UpdateSlide(input)
            local SizeX = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local NewValue = math.floor(min + ((max - min) * SizeX))
            Library.Flags[configName] = NewValue
            Title.Text = text .. ": " .. NewValue
            Utility:Tween(Fill, TweenInfo.new(0.1), {Size = UDim2.new(SizeX, 0, 1, 0)})
            callback(NewValue)
        end
        
        Bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                UpdateSlide(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateSlide(input)
            end
        end)
    end
    
    -- 4. Circular Color Picker
    function Window:ColorPicker(text, configName, default, callback)
        callback = callback or function() end
        local currentColor = default or Color3.fromRGB(255, 255, 255)
        Library.Flags[configName] = currentColor
        local open = false
        
        local PickerBtn = Instance.new("TextButton")
        PickerBtn.Parent = Content
        PickerBtn.BackgroundColor3 = Library.Theme.ItemBack
        PickerBtn.Size = UDim2.new(1, 0, 0, 30)
        PickerBtn.Text = text
        PickerBtn.TextColor3 = Library.Theme.Text
        PickerBtn.Font = Enum.Font.Gotham
        PickerBtn.TextSize = 14
        
        local ColorPreview = Instance.new("Frame")
        ColorPreview.Parent = PickerBtn
        ColorPreview.Position = UDim2.new(1, -25, 0.5, -7.5)
        ColorPreview.Size = UDim2.new(0, 15, 0, 15)
        ColorPreview.BackgroundColor3 = currentColor
        ColorPreview.BorderSizePixel = 1
        ColorPreview.BorderColor3 = Color3.new(0,0,0)
        
        -- Container for Palette
        local PaletteFrame = Instance.new("Frame")
        PaletteFrame.Parent = Content
        PaletteFrame.BackgroundColor3 = Library.Theme.ItemBack
        PaletteFrame.Size = UDim2.new(1, 0, 0, 0) -- Hidden
        PaletteFrame.Visible = false
        PaletteFrame.ClipsDescendants = true
        PaletteFrame.BorderSizePixel = 0
        
        -- Circular Wheel (Using Image)
        local Wheel = Instance.new("ImageButton")
        Wheel.Parent = PaletteFrame
        Wheel.Name = "Wheel"
        Wheel.Image = "rbxassetid://6020299385" -- Standard color wheel asset
        Wheel.Position = UDim2.new(0.5, -60, 0, 10)
        Wheel.Size = UDim2.new(0, 120, 0, 120)
        Wheel.BackgroundTransparency = 1
        
        local Cursor = Instance.new("Frame")
        Cursor.Parent = Wheel
        Cursor.Size = UDim2.new(0, 8, 0, 8)
        Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        Cursor.Position = UDim2.new(0.5, 0, 0.5, 0)
        Cursor.BackgroundColor3 = Color3.new(1,1,1)
        Cursor.BorderSizePixel = 1
        Cursor.BorderColor3 = Color3.new(0,0,0)
        
        -- Value Slider
        local ValSlider = Instance.new("Frame")
        ValSlider.Parent = PaletteFrame
        ValSlider.Position = UDim2.new(0.1, 0, 0, 140)
        ValSlider.Size = UDim2.new(0.8, 0, 0, 10)
        ValSlider.BackgroundColor3 = Color3.new(1,1,1)
        
        local ValGradient = Instance.new("UIGradient")
        ValGradient.Parent = ValSlider
        ValGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        }
        
        local ValIndicator = Instance.new("Frame")
        ValIndicator.Parent = ValSlider
        ValIndicator.Size = UDim2.new(0, 2, 1, 4)
        ValIndicator.Position = UDim2.new(1, 0, 0, -2)
        ValIndicator.BackgroundColor3 = Color3.new(1,0,0)
        ValIndicator.BorderSizePixel = 0
        
        -- Logic
        local h, s, v = Color3.toHSV(currentColor)
        local draggingWheel = false
        local draggingVal = false
        
        local function UpdateColor()
            currentColor = Color3.fromHSV(h, s, v)
            ColorPreview.BackgroundColor3 = currentColor
            Library.Flags[configName] = currentColor
            callback(currentColor)
            
            -- If user links this to UI settings
            if configName == "UI_Accent" then Library.Theme.Accent = currentColor end
            if configName == "UI_Border" then Library.Theme.Border = currentColor end
        end
        
        -- Wheel Logic
        Wheel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingWheel = true
            end
        end)
        
        -- Value Logic
        ValSlider.InputBegan:Connect(function(input)
             if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingVal = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingWheel = false
                draggingVal = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if draggingWheel then
                    local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize / 2)
                    local mousePos = UserInputService:GetMouseLocation()
                    local rel = mousePos - center
                    
                    local angle = math.atan2(rel.Y, rel.X)
                    local dist = math.min(rel.Magnitude, Wheel.AbsoluteSize.X / 2)
                    
                    local newPos = Vector2.new(math.cos(angle), math.sin(angle)) * dist
                    Cursor.Position = UDim2.new(0.5, newPos.X, 0.5, newPos.Y)
                    
                    h = (math.deg(angle) + 180) / 360
                    s = dist / (Wheel.AbsoluteSize.X / 2)
                    UpdateColor()
                elseif draggingVal then
                    local relX = math.clamp((input.Position.X - ValSlider.AbsolutePosition.X) / ValSlider.AbsoluteSize.X, 0, 1)
                    v = relX
                    ValIndicator.Position = UDim2.new(relX, 0, 0, -2)
                    UpdateColor()
                end
            end
        end)
        
        PickerBtn.MouseButton1Click:Connect(function()
            open = not open
            PaletteFrame.Visible = open
            if open then
                Utility:Tween(PaletteFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 160)})
            else
                Utility:Tween(PaletteFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)})
            end
        end)
    end
    
    -- 5. Dropdown with Search
    function Window:Dropdown(text, configName, options, callback)
        callback = callback or function() end
        local open = false
        
        local DropBtn = Instance.new("TextButton")
        DropBtn.Parent = Content
        DropBtn.BackgroundColor3 = Library.Theme.ItemBack
        DropBtn.Size = UDim2.new(1, 0, 0, 30)
        DropBtn.Text = text .. " [V]"
        DropBtn.TextColor3 = Library.Theme.Text
        DropBtn.Font = Enum.Font.Gotham
        DropBtn.TextSize = 14
        
        local DropFrame = Instance.new("ScrollingFrame")
        DropFrame.Parent = Content
        DropFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
        DropFrame.Size = UDim2.new(1, 0, 0, 0)
        DropFrame.Visible = false
        DropFrame.ScrollBarThickness = 2
        DropFrame.CanvasSize = UDim2.new(0,0,0,0)
        
        local DropLayout = Instance.new("UIListLayout")
        DropLayout.Parent = DropFrame
        DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- Search Box
        local SearchBox = Instance.new("TextBox")
        SearchBox.Parent = DropFrame
        SearchBox.Size = UDim2.new(1, 0, 0, 20)
        SearchBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        SearchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
        SearchBox.PlaceholderText = "Search..."
        SearchBox.Text = ""
        
        local function RefreshOptions(filter)
            for _, child in pairs(DropFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            local count = 0
            for _, opt in ipairs(options) do
                if filter == "" or string.find(string.lower(opt), string.lower(filter)) then
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Parent = DropFrame
                    OptBtn.Size = UDim2.new(1, 0, 0, 20)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    OptBtn.Text = opt
                    OptBtn.TextColor3 = Color3.fromRGB(200,200,200)
                    OptBtn.BorderSizePixel = 0
                    
                    OptBtn.MouseButton1Click:Connect(function()
                        DropBtn.Text = text .. ": " .. opt
                        Library.Flags[configName] = opt
                        callback(opt)
                        open = false
                        Utility:Tween(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)})
                        wait(0.2)
                        DropFrame.Visible = false
                    end)
                    count = count + 1
                end
            end
            DropFrame.CanvasSize = UDim2.new(0, 0, 0, count * 20 + 25)
        end
        
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            RefreshOptions(SearchBox.Text)
        end)
        
        DropBtn.MouseButton1Click:Connect(function()
            open = not open
            DropFrame.Visible = true
            RefreshOptions("")
            if open then
                Utility:Tween(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 100)})
            else
                Utility:Tween(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)})
                wait(0.3)
                DropFrame.Visible = false
            end
        end)
        
        return {
            Refresh = function(newOpts)
                options = newOpts
                RefreshOptions("")
            end
        }
    end
    
    return Window
end

--// Initialization & Built-in Settings
function Library:Init()
    Library:LoadAnimation()
    
    -- Create Settings Window
    local SettingsWin = Library:Window("Settings")
    
    SettingsWin:Button("Save Config", function()
        SaveManager:Save("VapeX_Autosave")
    end)
    
    SettingsWin:Button("Load Config", function()
        SaveManager:Load("VapeX_Autosave")
    end)
    
    SettingsWin:Slider("UI Transparency", "UI_Trans", 0, 100, 0, function(v)
        Library.Theme.UITransparency = v / 100
        -- Apply to all windows (simplified loop)
        for _, w in pairs(Library.Windows) do
            w.MainFrame.BackgroundTransparency = Library.Theme.BackTransparency + (v/200) -- mixed math
        end
    end)
    
    SettingsWin:Toggle("Rainbow Borders", "Rainbow_Mode", false, function(v)
        Library.Theme.RainbowBorder = v
    end)
    
    SettingsWin:ColorPicker("Border Color", "UI_Border", Library.Theme.Border, function(c)
        Library.Theme.Border = c
    end)
    
    SettingsWin:ColorPicker("Accent Color", "UI_Accent", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
    end)
    
    SettingsWin:Button("Unload UI", function()
        ScreenGui:Destroy()
    end)
    
    -- Mobile Toggle Button
    if Library.IsMobile then
        local ToggleBtn = Instance.new("ImageButton")
        ToggleBtn.Parent = ScreenGui
        ToggleBtn.Name = "MobileToggle"
        ToggleBtn.Position = UDim2.new(1, -60, 0.5, -25)
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
        ToggleBtn.Image = "rbxassetid://6031091004"
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = ToggleBtn
        
        ToggleBtn.MouseButton1Click:Connect(function()
            for _, w in pairs(Library.Windows) do
                w.MainFrame.Visible = not w.MainFrame.Visible
            end
        end)
    end
    
    -- Keybind Toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            for _, w in pairs(Library.Windows) do
                w.MainFrame.Visible = not w.MainFrame.Visible
            end
        end
    end)
end

--// EXAMPLE USAGE (This part would be in your script using the library)
--// In a real scenario, you would remove this block and `return Library`
--// For "One File" request, we include the usage here.

Library:Init()

local MainWin = Library:Window("Combat")
MainWin:Toggle("Killaura", "KA_Enabled", false, function(v)
    print("Killaura:", v)
end)
MainWin:Slider("Range", "KA_Range", 1, 25, 15, function(v)
    print("Range:", v)
end)
MainWin:Dropdown("Target Mode", "KA_Mode", {"Player", "NPC", "All"}, function(v)
    print("Mode:", v)
end)

local VisualsWin = Library:Window("Visuals")
VisualsWin:Toggle("ESP", "ESP_Enabled", false, function(v) end)
VisualsWin:Toggle("Tracers", "Tracers_Enabled", false, function(v) end)
VisualsWin:ColorPicker("ESP Color", "ESP_Color", Color3.fromRGB(255,0,0), function(c) end)

local MiscWin = Library:Window("Misc")
MiscWin:Button("Fly (Press F)", function()
    -- Fly logic stub
end)
MiscWin:Slider("Fly Speed", "Fly_Speed", 10, 100, 25, function(v) end)

--// End of Script
return Library
