--[[
    Vape Style UI Library for Roblox
    作者: Assistant
    版本: 1.0
]]

local VapeUI = {}
VapeUI.__index = VapeUI

-- 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 配置
local Config = {
    MainColor = Color3.fromRGB(147, 112, 219), -- 紫色主题
    SecondaryColor = Color3.fromRGB(180, 150, 230),
    BackgroundColor = Color3.fromRGB(25, 25, 35),
    SidebarColor = Color3.fromRGB(30, 30, 42),
    TextColor = Color3.fromRGB(255, 255, 255),
    SubTextColor = Color3.fromRGB(180, 180, 180),
    ToggleOnColor = Color3.fromRGB(147, 112, 219),
    ToggleOffColor = Color3.fromRGB(60, 60, 75),
    Font = Enum.Font.GothamSemibold,
    TweenSpeed = 0.2
}

-- 工具函数
local function CreateTween(instance, properties, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or Config.TweenSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    return tween
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function AddCorner(instance, radius)
    return CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = instance
    })
end

local function AddStroke(instance, color, thickness)
    return CreateInstance("UIStroke", {
        Color = color or Config.MainColor,
        Thickness = thickness or 1,
        Transparency = 0.5,
        Parent = instance
    })
end

-- 主函数：创建窗口
function VapeUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "Vape V4"
    local subtitle = options.Subtitle or "made for roblox"
    
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    
    -- 创建ScreenGui
    local ScreenGui = CreateInstance("ScreenGui", {
        Name = "VapeUI_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- 尝试放入CoreGui，失败则放入PlayerGui
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- 主窗口
    local MainFrame = CreateInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 650, 0, 450),
        Position = UDim2.new(0.5, -325, 0.5, -225),
        BackgroundColor3 = Config.BackgroundColor,
        BorderSizePixel = 0,
        Parent = ScreenGui
    })
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, Config.MainColor, 1)
    
    -- 添加阴影
    local Shadow = CreateInstance("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = -1,
        Parent = MainFrame
    })
    
    -- 顶部栏
    local TopBar = CreateInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Config.SidebarColor,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(TopBar, 8)
    
    -- 修复圆角
    local TopBarFix = CreateInstance("Frame", {
        Name = "Fix",
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Config.SidebarColor,
        BorderSizePixel = 0,
        Parent = TopBar
    })
    
    -- Logo/标题
    local TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.MainColor,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })
    
    local SubtitleLabel = CreateInstance("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 15, 0, 30),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = Config.SubTextColor,
        TextSize = 11,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })
    
    -- 关闭按钮
    local CloseButton = CreateInstance("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Parent = TopBar
    })
    AddCorner(CloseButton, 6)
    
    CloseButton.MouseButton1Click:Connect(function()
        local tween = CreateTween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        tween:Play()
        tween.Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)
    
    -- 最小化按钮
    local MinimizeButton = CreateInstance("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -75, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 200, 80),
        Text = "—",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = TopBar
    })
    AddCorner(MinimizeButton, 6)
    
    local minimized = false
    local originalSize = MainFrame.Size
    
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            CreateTween(MainFrame, {Size = UDim2.new(0, 650, 0, 50)}):Play()
        else
            CreateTween(MainFrame, {Size = originalSize}):Play()
        end
    end)
    
    -- 侧边栏
    local Sidebar = CreateInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -60),
        Position = UDim2.new(0, 5, 0, 55),
        BackgroundColor3 = Config.SidebarColor,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    AddCorner(Sidebar, 6)
    
    local TabList = CreateInstance("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Config.MainColor,
        BorderSizePixel = 0,
        Parent = Sidebar
    })
    
    local TabListLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabList
    })
    
    -- 内容区域
    local ContentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -170, 1, -65),
        Position = UDim2.new(0, 160, 0, 55),
        BackgroundColor3 = Config.SidebarColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainFrame
    })
    AddCorner(ContentArea, 6)
    
    -- 拖动功能
    local dragging, dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- 创建标签页函数
    function Window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local name = tabOptions.Name or "Tab"
        local icon = tabOptions.Icon or "rbxassetid://3926305904"
        
        local Tab = {}
        Tab.Elements = {}
        
        -- 标签按钮
        local TabButton = CreateInstance("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Config.ToggleOffColor,
            Text = "",
            Parent = TabList
        })
        AddCorner(TabButton, 6)
        
        local TabIcon = CreateInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 10, 0.5, -9),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = Config.SubTextColor,
            Parent = TabButton
        })
        
        local TabLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 35, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Config.SubTextColor,
            TextSize = 13,
            Font = Config.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })
        
        -- 标签内容页
        local TabPage = CreateInstance("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Config.MainColor,
            Visible = false,
            BorderSizePixel = 0,
            Parent = ContentArea
        })
        
        local PageLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = TabPage
        })
        
        local PagePadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 5),
            Parent = TabPage
        })
        
        -- 自动调整Canvas大小
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- 选择标签
        local function SelectTab()
            -- 取消选择其他标签
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Config.ToggleOffColor
                tab.Icon.ImageColor3 = Config.SubTextColor
                tab.Label.TextColor3 = Config.SubTextColor
                tab.Page.Visible = false
            end
            
            -- 选择当前标签
            TabButton.BackgroundColor3 = Config.MainColor
            TabIcon.ImageColor3 = Config.TextColor
            TabLabel.TextColor3 = Config.TextColor
            TabPage.Visible = true
            Window.CurrentTab = Tab
        end
        
        TabButton.MouseButton1Click:Connect(SelectTab)
        
        -- 悬停效果
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                CreateTween(TabButton, {BackgroundColor3 = Color3.fromRGB(70, 70, 90)}):Play()
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                CreateTween(TabButton, {BackgroundColor3 = Config.ToggleOffColor}):Play()
            end
        end)
        
        -- 保存标签信息
        Tab.Button = TabButton
        Tab.Icon = TabIcon
        Tab.Label = TabLabel
        Tab.Page = TabPage
        table.insert(Window.Tabs, Tab)
        
        -- 如果是第一个标签，自动选择
        if #Window.Tabs == 1 then
            SelectTab()
        end
        
        -- 创建Section
        function Tab:CreateSection(sectionOptions)
            sectionOptions = sectionOptions or {}
            local sectionName = sectionOptions.Name or "Section"
            
            local Section = {}
            
            local SectionFrame = CreateInstance("Frame", {
                Name = sectionName .. "Section",
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = Config.BackgroundColor,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = TabPage
            })
            AddCorner(SectionFrame, 6)
            
            local SectionTitle = CreateInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Config.MainColor,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SectionFrame
            })
            
            local SectionContent = CreateInstance("Frame", {
                Name = "Content",
                Size = UDim2.new(1, -10, 0, 0),
                Position = UDim2.new(0, 5, 0, 30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = SectionFrame
            })
            
            local ContentLayout = CreateInstance("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = SectionContent
            })
            
            local ContentPadding = CreateInstance("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                Parent = SectionContent
            })
            
            -- 创建Toggle
            function Section:CreateToggle(toggleOptions)
                toggleOptions = toggleOptions or {}
                local toggleName = toggleOptions.Name or "Toggle"
                local default = toggleOptions.Default or false
                local callback = toggleOptions.Callback or function() end
                
                local Toggle = {}
                Toggle.Value = default
                
                local ToggleFrame = CreateInstance("Frame", {
                    Name = toggleName .. "Toggle",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.SidebarColor,
                    Parent = SectionContent
                })
                AddCorner(ToggleFrame, 6)
                
                local ToggleLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -60, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = toggleName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })
                
                local ToggleButton = CreateInstance("Frame", {
                    Name = "Button",
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = default and Config.ToggleOnColor or Config.ToggleOffColor,
                    Parent = ToggleFrame
                })
                AddCorner(ToggleButton, 10)
                
                local ToggleCircle = CreateInstance("Frame", {
                    Name = "Circle",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = ToggleButton
                })
                AddCorner(ToggleCircle, 8)
                
                local ToggleClickButton = CreateInstance("TextButton", {
                    Name = "Click",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ToggleFrame
                })
                
                local function UpdateToggle()
                    if Toggle.Value then
                        CreateTween(ToggleButton, {BackgroundColor3 = Config.ToggleOnColor}):Play()
                        CreateTween(ToggleCircle, {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                    else
                        CreateTween(ToggleButton, {BackgroundColor3 = Config.ToggleOffColor}):Play()
                        CreateTween(ToggleCircle, {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                    end
                    callback(Toggle.Value)
                end
                
                ToggleClickButton.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    UpdateToggle()
                end)
                
                function Toggle:Set(value)
                    Toggle.Value = value
                    UpdateToggle()
                end
                
                -- 初始化
                if default then
                    callback(true)
                end
                
                return Toggle
            end
            
            -- 创建Slider
            function Section:CreateSlider(sliderOptions)
                sliderOptions = sliderOptions or {}
                local sliderName = sliderOptions.Name or "Slider"
                local min = sliderOptions.Min or 0
                local max = sliderOptions.Max or 100
                local default = sliderOptions.Default or min
                local callback = sliderOptions.Callback or function() end
                
                local Slider = {}
                Slider.Value = default
                
                local SliderFrame = CreateInstance("Frame", {
                    Name = sliderName .. "Slider",
                    Size = UDim2.new(1, -10, 0, 50),
                    BackgroundColor3 = Config.SidebarColor,
                    Parent = SectionContent
                })
                AddCorner(SliderFrame, 6)
                
                local SliderLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -60, 0, 25),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = sliderName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderFrame
                })
                
                local SliderValue = CreateInstance("TextLabel", {
                    Name = "Value",
                    Size = UDim2.new(0, 50, 0, 25),
                    Position = UDim2.new(1, -55, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default),
                    TextColor3 = Config.MainColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = SliderFrame
                })
                
                local SliderBar = CreateInstance("Frame", {
                    Name = "Bar",
                    Size = UDim2.new(1, -20, 0, 8),
                    Position = UDim2.new(0, 10, 0, 32),
                    BackgroundColor3 = Config.ToggleOffColor,
                    Parent = SliderFrame
                })
                AddCorner(SliderBar, 4)
                
                local SliderFill = CreateInstance("Frame", {
                    Name = "Fill",
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Config.MainColor,
                    Parent = SliderBar
                })
                AddCorner(SliderFill, 4)
                
                local SliderButton = CreateInstance("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = SliderBar
                })
                
                local dragging = false
                
                local function UpdateSlider(input)
                    local relativeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    Slider.Value = math.floor(min + (max - min) * relativeX)
                    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    SliderValue.Text = tostring(Slider.Value)
                    callback(Slider.Value)
                end
                
                SliderButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateSlider(input)
                    end
                end)
                
                SliderButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(input)
                    end
                end)
                
                function Slider:Set(value)
                    value = math.clamp(value, min, max)
                    Slider.Value = value
                    local relativeX = (value - min) / (max - min)
                    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    SliderValue.Text = tostring(value)
                    callback(value)
                end
                
                return Slider
            end
            
            -- 创建Button
            function Section:CreateButton(buttonOptions)
                buttonOptions = buttonOptions or {}
                local buttonName = buttonOptions.Name or "Button"
                local callback = buttonOptions.Callback or function() end
                
                local Button = {}
                
                local ButtonFrame = CreateInstance("TextButton", {
                    Name = buttonName .. "Button",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.MainColor,
                    Text = buttonName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    Parent = SectionContent
                })
                AddCorner(ButtonFrame, 6)
                
                ButtonFrame.MouseButton1Click:Connect(function()
                    -- 点击动画
                    local originalColor = ButtonFrame.BackgroundColor3
                    CreateTween(ButtonFrame, {BackgroundColor3 = Config.SecondaryColor}, 0.1):Play()
                    task.wait(0.1)
                    CreateTween(ButtonFrame, {BackgroundColor3 = originalColor}, 0.1):Play()
                    callback()
                end)
                
                -- 悬停效果
                ButtonFrame.MouseEnter:Connect(function()
                    CreateTween(ButtonFrame, {BackgroundColor3 = Config.SecondaryColor}):Play()
                end)
                
                ButtonFrame.MouseLeave:Connect(function()
                    CreateTween(ButtonFrame, {BackgroundColor3 = Config.MainColor}):Play()
                end)
                
                return Button
            end
            
            -- 创建Dropdown
            function Section:CreateDropdown(dropdownOptions)
                dropdownOptions = dropdownOptions or {}
                local dropdownName = dropdownOptions.Name or "Dropdown"
                local options = dropdownOptions.Options or {}
                local default = dropdownOptions.Default or (options[1] or "")
                local callback = dropdownOptions.Callback or function() end
                
                local Dropdown = {}
                Dropdown.Value = default
                Dropdown.Open = false
                
                local DropdownFrame = CreateInstance("Frame", {
                    Name = dropdownName .. "Dropdown",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.SidebarColor,
                    ClipsDescendants = true,
                    Parent = SectionContent
                })
                AddCorner(DropdownFrame, 6)
                
                local DropdownLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -40, 0, 35),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = dropdownName .. ": " .. default,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownFrame
                })
                
                local DropdownArrow = CreateInstance("TextLabel", {
                    Name = "Arrow",
                    Size = UDim2.new(0, 20, 0, 35),
                    Position = UDim2.new(1, -30, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    TextColor3 = Config.MainColor,
                    TextSize = 10,
                    Font = Config.Font,
                    Parent = DropdownFrame
                })
                
                local DropdownButton = CreateInstance("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = DropdownFrame
                })
                
                local OptionContainer = CreateInstance("Frame", {
                    Name = "Options",
                    Size = UDim2.new(1, -10, 0, #options * 30),
                    Position = UDim2.new(0, 5, 0, 40),
                    BackgroundTransparency = 1,
                    Parent = DropdownFrame
                })
                
                local OptionLayout = CreateInstance("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                    Parent = OptionContainer
                })
                
                for _, option in ipairs(options) do
                    local OptionButton = CreateInstance("TextButton", {
                        Name = option,
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = Config.ToggleOffColor,
                        Text = option,
                        TextColor3 = Config.TextColor,
                        TextSize = 12,
                        Font = Config.Font,
                        Parent = OptionContainer
                    })
                    AddCorner(OptionButton, 4)
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        Dropdown.Value = option
                        DropdownLabel.Text = dropdownName .. ": " .. option
                        Dropdown.Open = false
                        CreateTween(DropdownFrame, {Size = UDim2.new(1, -10, 0, 35)}):Play()
                        CreateTween(DropdownArrow, {Rotation = 0}):Play()
                        callback(option)
                    end)
                    
                    OptionButton.MouseEnter:Connect(function()
                        CreateTween(OptionButton, {BackgroundColor3 = Config.MainColor}):Play()
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        CreateTween(OptionButton, {BackgroundColor3 = Config.ToggleOffColor}):Play()
                    end)
                end
                
                DropdownButton.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    if Dropdown.Open then
                        CreateTween(DropdownFrame, {Size = UDim2.new(1, -10, 0, 45 + #options * 30)}):Play()
                        CreateTween(DropdownArrow, {Rotation = 180}):Play()
                    else
                        CreateTween(DropdownFrame, {Size = UDim2.new(1, -10, 0, 35)}):Play()
                        CreateTween(DropdownArrow, {Rotation = 0}):Play()
                    end
                end)
                
                function Dropdown:Set(value)
                    Dropdown.Value = value
                    DropdownLabel.Text = dropdownName .. ": " .. value
                    callback(value)
                end
                
                -- 初始化回调
                if default ~= "" then
                    callback(default)
                end
                
                return Dropdown
            end
            
            -- 创建Keybind
            function Section:CreateKeybind(keybindOptions)
                keybindOptions = keybindOptions or {}
                local keybindName = keybindOptions.Name or "Keybind"
                local default = keybindOptions.Default or Enum.KeyCode.Unknown
                local callback = keybindOptions.Callback or function() end
                
                local Keybind = {}
                Keybind.Value = default
                Keybind.Listening = false
                
                local KeybindFrame = CreateInstance("Frame", {
                    Name = keybindName .. "Keybind",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.SidebarColor,
                    Parent = SectionContent
                })
                AddCorner(KeybindFrame, 6)
                
                local KeybindLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -80, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = keybindName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeybindFrame
                })
                
                local KeybindButton = CreateInstance("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(0, 60, 0, 25),
                    Position = UDim2.new(1, -70, 0.5, -12.5),
                    BackgroundColor3 = Config.ToggleOffColor,
                    Text = default.Name or "None",
                    TextColor3 = Config.MainColor,
                    TextSize = 11,
                    Font = Config.Font,
                    Parent = KeybindFrame
                })
                AddCorner(KeybindButton, 4)
                
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    KeybindButton.Text = "..."
                    CreateTween(KeybindButton, {BackgroundColor3 = Config.MainColor}):Play()
                    KeybindButton.TextColor3 = Config.TextColor
                end)
                
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if Keybind.Listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Keybind.Value = input.KeyCode
                            KeybindButton.Text = input.KeyCode.Name
                            Keybind.Listening = false
                            CreateTween(KeybindButton, {BackgroundColor3 = Config.ToggleOffColor}):Play()
                            KeybindButton.TextColor3 = Config.MainColor
                        end
                    elseif input.KeyCode == Keybind.Value and not gameProcessed then
                        callback(Keybind.Value)
                    end
                end)
                
                function Keybind:Set(key)
                    Keybind.Value = key
                    KeybindButton.Text = key.Name
                end
                
                return Keybind
            end
            
            -- 创建TextBox
            function Section:CreateTextBox(textboxOptions)
                textboxOptions = textboxOptions or {}
                local textboxName = textboxOptions.Name or "TextBox"
                local default = textboxOptions.Default or ""
                local placeholder = textboxOptions.Placeholder or "Enter text..."
                local callback = textboxOptions.Callback or function() end
                
                local TextBox = {}
                TextBox.Value = default
                
                local TextBoxFrame = CreateInstance("Frame", {
                    Name = textboxName .. "TextBox",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.SidebarColor,
                    Parent = SectionContent
                })
                AddCorner(TextBoxFrame, 6)
                
                local TextBoxLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = textboxName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TextBoxFrame
                })
                
                local TextBoxInput = CreateInstance("TextBox", {
                    Name = "Input",
                    Size = UDim2.new(0.5, -10, 0, 25),
                    Position = UDim2.new(0.5, 0, 0.5, -12.5),
                    BackgroundColor3 = Config.ToggleOffColor,
                    Text = default,
                    PlaceholderText = placeholder,
                    TextColor3 = Config.TextColor,
                    PlaceholderColor3 = Config.SubTextColor,
                    TextSize = 12,
                    Font = Config.Font,
                    ClearTextOnFocus = false,
                    Parent = TextBoxFrame
                })
                AddCorner(TextBoxInput, 4)
                
                TextBoxInput.FocusLost:Connect(function(enterPressed)
                    TextBox.Value = TextBoxInput.Text
                    callback(TextBoxInput.Text, enterPressed)
                end)
                
                function TextBox:Set(text)
                    TextBox.Value = text
                    TextBoxInput.Text = text
                end
                
                return TextBox
            end
            
            -- 创建ColorPicker
            function Section:CreateColorPicker(colorOptions)
                colorOptions = colorOptions or {}
                local colorName = colorOptions.Name or "Color"
                local default = colorOptions.Default or Color3.fromRGB(255, 255, 255)
                local callback = colorOptions.Callback or function() end
                
                local ColorPicker = {}
                ColorPicker.Value = default
                ColorPicker.Open = false
                
                local ColorFrame = CreateInstance("Frame", {
                    Name = colorName .. "Color",
                    Size = UDim2.new(1, -10, 0, 35),
                    BackgroundColor3 = Config.SidebarColor,
                    ClipsDescendants = true,
                    Parent = SectionContent
                })
                AddCorner(ColorFrame, 6)
                
                local ColorLabel = CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -50, 0, 35),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = colorName,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ColorFrame
                })
                
                local ColorPreview = CreateInstance("Frame", {
                    Name = "Preview",
                    Size = UDim2.new(0, 25, 0, 25),
                    Position = UDim2.new(1, -35, 0, 5),
                    BackgroundColor3 = default,
                    Parent = ColorFrame
                })
                AddCorner(ColorPreview, 4)
                AddStroke(ColorPreview, Color3.fromRGB(255, 255, 255), 1)
                
                local ColorButton = CreateInstance("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ColorFrame
                })
                
                -- 颜色选择器面板
                local PickerPanel = CreateInstance("Frame", {
                    Name = "Picker",
                    Size = UDim2.new(1, -10, 0, 120),
                    Position = UDim2.new(0, 5, 0, 40),
                    BackgroundColor3 = Config.BackgroundColor,
                    Parent = ColorFrame
                })
                AddCorner(PickerPanel, 6)
                
                -- HSV滑块
                local HueSlider = CreateInstance("Frame", {
                    Name = "Hue",
                    Size = UDim2.new(1, -10, 0, 15),
                    Position = UDim2.new(0, 5, 0, 5),
                    Parent = PickerPanel
                })
                AddCorner(HueSlider, 4)
                
                -- 创建彩虹渐变
                local HueGradient = CreateInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }),
                    Parent = HueSlider
                })
                
                local SatValPicker = CreateInstance("Frame", {
                    Name = "SatVal",
                    Size = UDim2.new(1, -10, 0, 80),
                    Position = UDim2.new(0, 5, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                    Parent = PickerPanel
                })
                AddCorner(SatValPicker, 4)
                
                local SatGradient = CreateInstance("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Parent = SatValPicker
                })
                
                local ValOverlay = CreateInstance("Frame", {
                    Name = "ValOverlay",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 1,
                    Parent = SatValPicker
                })
                AddCorner(ValOverlay, 4)
                
                local ValGradient = CreateInstance("UIGradient", {
                    Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0)
                    }),
                    Rotation = 90,
                    Parent = ValOverlay
                })
                
                local h, s, v = Color3.toHSV(default)
                
                ColorButton.MouseButton1Click:Connect(function()
                    ColorPicker.Open = not ColorPicker.Open
                    if ColorPicker.Open then
                        CreateTween(ColorFrame, {Size = UDim2.new(1, -10, 0, 170)}):Play()
                    else
                        CreateTween(ColorFrame, {Size = UDim2.new(1, -10, 0, 35)}):Play()
                    end
                end)
                
                local draggingHue = false
                local draggingSatVal = false
                
                HueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingHue = true
                    end
                end)
                
                HueSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingHue = false
                    end
                end)
                
                SatValPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSatVal = true
                    end
                end)
                
                SatValPicker.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSatVal = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if draggingHue then
                            h = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                            SatValPicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            ColorPicker.Value = Color3.fromHSV(h, s, v)
                            ColorPreview.BackgroundColor3 = ColorPicker.Value
                            callback(ColorPicker.Value)
                        elseif draggingSatVal then
                            s = math.clamp((input.Position.X - SatValPicker.AbsolutePosition.X) / SatValPicker.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((input.Position.Y - SatValPicker.AbsolutePosition.Y) / SatValPicker.AbsoluteSize.Y, 0, 1)
                            ColorPicker.Value = Color3.fromHSV(h, s, v)
                            ColorPreview.BackgroundColor3 = ColorPicker.Value
                            callback(ColorPicker.Value)
                        end
                    end
                end)
                
                function ColorPicker:Set(color)
                    ColorPicker.Value = color
                    ColorPreview.BackgroundColor3 = color
                    h, s, v = Color3.toHSV(color)
                    SatValPicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    callback(color)
                end
                
                return ColorPicker
            end
            
            return Section
        end
        
        return Tab
    end
    
    -- 通知系统
    function Window:Notify(options)
        options = options or {}
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = options.Duration or 3
        
        local NotifyFrame = CreateInstance("Frame", {
            Name = "Notification",
            Size = UDim2.new(0, 250, 0, 70),
            Position = UDim2.new(1, 10, 1, -80),
            BackgroundColor3 = Config.BackgroundColor,
            Parent = ScreenGui
        })
        AddCorner(NotifyFrame, 6)
        AddStroke(NotifyFrame, Config.MainColor, 1)
        
        local NotifyTitle = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -10, 0, 25),
            Position = UDim2.new(0, 10, 0, 5),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Config.MainColor,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = NotifyFrame
        })
        
        local NotifyContent = CreateInstance("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -20, 0, 35),
            Position = UDim2.new(0, 10, 0, 28),
            BackgroundTransparency = 1,
            Text = content,
            TextColor3 = Config.TextColor,
            TextSize = 12,
            Font = Config.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = NotifyFrame
        })
        
        -- 进度条
        local NotifyProgress = CreateInstance("Frame", {
            Name = "Progress",
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = Config.MainColor,
            Parent = NotifyFrame
        })
        
        -- 动画进入
        CreateTween(NotifyFrame, {Position = UDim2.new(1, -260, 1, -80)}):Play()
        
        -- 进度条动画
        CreateTween(NotifyProgress, {Size = UDim2.new(0, 0, 0, 3)}, duration):Play()
        
        -- 自动消失
        task.delay(duration, function()
            local exitTween = CreateTween(NotifyFrame, {Position = UDim2.new(1, 10, 1, -80)})
            exitTween:Play()
            exitTween.Completed:Connect(function()
                NotifyFrame:Destroy()
            end)
        end)
    end
    
    -- 开场动画
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    CreateTween(MainFrame, {Size = UDim2.new(0, 650, 0, 450), Position = UDim2.new(0.5, -325, 0.5, -225)}, 0.4):Play()
    
    return Window
end

return VapeUI
