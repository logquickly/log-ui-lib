--[[
    高级 UI 库 v1.0
    模仿 Vape 风格的多窗口注入器
    支持手机端操作
    作者: Advanced UI Library
]]

local Library = {}
Library.Version = "1.0.0"
Library.Windows = {}
Library.Themes = {}
Library.Configs = {}
Library.Settings = {
    BorderColor = Color3.fromRGB(100, 100, 255),
    BackgroundColor = Color3.fromRGB(20, 20, 25),
    BackgroundTransparency = 0.1,
    BorderTransparency = 0,
    RainbowMode = false,
    AccentColor = Color3.fromRGB(100, 100, 255),
    UIScale = 1,
    AnimationSpeed = 0.3,
    CustomBackground = nil
}

-- 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- 实用工具函数
local Utils = {}

function Utils:Create(className, properties)
    local object = Instance.new(className)
    for i, v in pairs(properties) do
        if i ~= "Parent" then
            object[i] = v
        end
    end
    object.Parent = properties.Parent
    return object
end

function Utils:Tween(object, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or Library.Settings.AnimationSpeed,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utils:Ripple(object, x, y)
    local ripple = Utils:Create("Frame", {
        Parent = object,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = 1000,
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    Utils:Create("UICorner", {
        Parent = ripple,
        CornerRadius = UDim.new(1, 0)
    })
    
    Utils:Tween(ripple, {
        Size = UDim2.new(0, 100, 0, 100),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utils:MakeDraggable(frame, dragFrame)
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragFrame = dragFrame or frame
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Utils:Tween(frame, {
                Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            }, 0.1)
        end
    end)
end

function Utils:Rainbow(object, property)
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not object or not object.Parent then
            connection:Disconnect()
            return
        end
        local hue = tick() % 5 / 5
        object[property] = Color3.fromHSV(hue, 1, 1)
    end)
    return connection
end

function Utils:IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- 载入动画系统
local LoadingAnimation = {}

function LoadingAnimation:Create()
    local ScreenGui = Utils:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "UILibraryLoading",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    
    local Background = Utils:Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(10, 10, 15),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    local Container = Utils:Create("Frame", {
        Parent = Background,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 200),
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    -- Logo/标题
    local Title = Utils:Create("TextLabel", {
        Parent = Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 50),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.GothamBold,
        Text = "UI LIBRARY",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 32,
        TextTransparency = 1
    })
    
    local SubTitle = Utils:Create("TextLabel", {
        Parent = Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 55),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.Gotham,
        Text = "Advanced Injection System v" .. Library.Version,
        TextColor3 = Color3.fromRGB(150, 150, 150),
        TextSize = 14,
        TextTransparency = 1
    })
    
    -- 进度条容器
    local ProgressBarBG = Utils:Create("Frame", {
        Parent = Container,
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 100),
        Size = UDim2.new(0.8, 0, 0, 4),
        AnchorPoint = Vector2.new(0.5, 0)
    })
    
    Utils:Create("UICorner", {
        Parent = ProgressBarBG,
        CornerRadius = UDim.new(0, 2)
    })
    
    local ProgressBar = Utils:Create("Frame", {
        Parent = ProgressBarBG,
        BackgroundColor3 = Library.Settings.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0)
    })
    
    Utils:Create("UICorner", {
        Parent = ProgressBar,
        CornerRadius = UDim.new(0, 2)
    })
    
    -- 加载文本
    local LoadingText = Utils:Create("TextLabel", {
        Parent = Container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 115),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.Gotham,
        Text = "Initializing...",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        TextTransparency = 1
    })
    
    -- 粒子效果
    local ParticlesContainer = Utils:Create("Frame", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    -- 动画序列
    Utils:Tween(Title, {TextTransparency = 0}, 0.5)
    Utils:Tween(SubTitle, {TextTransparency = 0}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    Utils:Tween(LoadingText, {TextTransparency = 0}, 0.5)
    
    local loadingSteps = {
        {text = "Initializing components...", progress = 0.2},
        {text = "Loading modules...", progress = 0.4},
        {text = "Setting up interface...", progress = 0.6},
        {text = "Configuring settings...", progress = 0.8},
        {text = "Finalizing...", progress = 1}
    }
    
    task.spawn(function()
        for i = 1, 20 do
            local particle = Utils:Create("Frame", {
                Parent = ParticlesContainer,
                BackgroundColor3 = Library.Settings.AccentColor,
                BorderSizePixel = 0,
                Position = UDim2.new(math.random(), 0, math.random(), 0),
                Size = UDim2.new(0, 3, 0, 3),
                BackgroundTransparency = 0.5
            })
            
            Utils:Create("UICorner", {
                Parent = particle,
                CornerRadius = UDim.new(1, 0)
            })
            
            task.spawn(function()
                while particle.Parent do
                    Utils:Tween(particle, {
                        Position = UDim2.new(math.random(), 0, math.random(), 0)
                    }, 2)
                    task.wait(2)
                end
            end)
        end
    end)
    
    return {
        ScreenGui = ScreenGui,
        ProgressBar = ProgressBar,
        LoadingText = LoadingText,
        Steps = loadingSteps
    }
end

function LoadingAnimation:Play(callback)
    local animation = self:Create()
    
    task.spawn(function()
        for _, step in ipairs(animation.Steps) do
            animation.LoadingText.Text = step.text
            Utils:Tween(animation.ProgressBar, {
                Size = UDim2.new(step.progress, 0, 1, 0)
            }, 0.5)
            task.wait(0.3)
        end
        
        task.wait(0.5)
        
        Utils:Tween(animation.ScreenGui.Frame, {
            BackgroundTransparency = 1
        }, 0.5)
        
        for _, obj in ipairs(animation.ScreenGui.Frame:GetDescendants()) do
            if obj:IsA("TextLabel") then
                Utils:Tween(obj, {TextTransparency = 1}, 0.5)
            elseif obj:IsA("Frame") then
                Utils:Tween(obj, {BackgroundTransparency = 1}, 0.5)
            end
        end
        
        task.wait(0.5)
        animation.ScreenGui:Destroy()
        
        if callback then
            callback()
        end
    end)
end

-- 配置管理系统
local ConfigManager = {}
ConfigManager.ConfigFolder = "UILibrary_Configs"

function ConfigManager:Save(name, data)
    local success, result = pcall(function()
        local encoded = HttpService:JSONEncode(data)
        writefile(self.ConfigFolder .. "/" .. name .. ".json", encoded)
    end)
    return success
end

function ConfigManager:Load(name)
    local success, result = pcall(function()
        local data = readfile(self.ConfigFolder .. "/" .. name .. ".json")
        return HttpService:JSONDecode(data)
    end)
    return success and result or nil
end

function ConfigManager:Delete(name)
    local success = pcall(function()
        delfile(self.ConfigFolder .. "/" .. name .. ".json")
    end)
    return success
end

function ConfigManager:List()
    local configs = {}
    local success = pcall(function()
        if not isfolder(self.ConfigFolder) then
            makefolder(self.ConfigFolder)
        end
        for _, file in ipairs(listfiles(self.ConfigFolder)) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end)
    return configs
end

function ConfigManager:Init()
    pcall(function()
        if not isfolder(self.ConfigFolder) then
            makefolder(self.ConfigFolder)
        end
    end)
end

-- 主UI库
function Library:CreateWindow(options)
    options = options or {}
    local windowName = options.Name or "Window"
    local windowSize = options.Size or UDim2.new(0, 500, 0, 600)
    local windowPosition = options.Position or UDim2.new(0.5, 0, 0.5, 0)
    
    local Window = {
        Tabs = {},
        Elements = {},
        Minimized = false,
        Visible = true
    }
    
    -- 创建ScreenGui
    local ScreenGui = Utils:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "UILibrary_" .. windowName,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })
    
    -- 主窗口框架
    local MainFrame = Utils:Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Library.Settings.BackgroundColor,
        BackgroundTransparency = Library.Settings.BackgroundTransparency,
        BorderSizePixel = 0,
        Position = windowPosition,
        Size = windowSize,
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true
    })
    
    -- 添加阴影效果
    local Shadow = Utils:Create("ImageLabel", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = 0,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277)
    })
    
    -- 边框
    local Border = Utils:Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 10
    })
    
    local BorderTop = Utils:Create("Frame", {
        Parent = Border,
        BackgroundColor3 = Library.Settings.BorderColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundTransparency = Library.Settings.BorderTransparency
    })
    
    local BorderBottom = Utils:Create("Frame", {
        Parent = Border,
        BackgroundColor3 = Library.Settings.BorderColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundTransparency = Library.Settings.BorderTransparency
    })
    
    local BorderLeft = Utils:Create("Frame", {
        Parent = Border,
        BackgroundColor3 = Library.Settings.BorderColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundTransparency = Library.Settings.BorderTransparency
    })
    
    local BorderRight = Utils:Create("Frame", {
        Parent = Border,
        BackgroundColor3 = Library.Settings.BorderColor,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -2, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundTransparency = Library.Settings.BorderTransparency
    })
    
    -- 彩虹边框支持
    if Library.Settings.RainbowMode then
        Utils:Rainbow(BorderTop, "BackgroundColor3")
        Utils:Rainbow(BorderBottom, "BackgroundColor3")
        Utils:Rainbow(BorderLeft, "BackgroundColor3")
        Utils:Rainbow(BorderRight, "BackgroundColor3")
    end
    
    -- 标题栏
    local TitleBar = Utils:Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 5
    })
    
    local TitleLabel = Utils:Create("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = windowName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- 窗口控制按钮
    local ControlsFrame = Utils:Create("Frame", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 100, 1, 0)
    })
    
    -- 最小化按钮
    local MinimizeButton = Utils:Create("TextButton", {
        Parent = ControlsFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "_",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 20
    })
    
    MinimizeButton.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Utils:Tween(MainFrame, {Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 40)}, 0.3)
        else
            Utils:Tween(MainFrame, {Size = windowSize}, 0.3)
        end
    end)
    
    -- 关闭按钮
    local CloseButton = Utils:Create("TextButton", {
        Parent = ControlsFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 35, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextSize = 24
    })
    
    CloseButton.MouseButton1Click:Connect(function()
        Utils:Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- 可见性切换按钮
    local ToggleButton = Utils:Create("TextButton", {
        Parent = ControlsFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 70, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "◉",
        TextColor3 = Library.Settings.AccentColor,
        TextSize = 16
    })
    
    ToggleButton.MouseButton1Click:Connect(function()
        Window.Visible = not Window.Visible
        MainFrame.Visible = Window.Visible
    end)
    
    -- 使窗口可拖动
    Utils:MakeDraggable(MainFrame, TitleBar)
    
    -- Tab容器
    local TabContainer = Utils:Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Color3.fromRGB(18, 18, 23),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 150, 1, -40)
    })
    
    local TabList = Utils:Create("ScrollingFrame", {
        Parent = TabContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.Settings.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    Utils:Create("UIListLayout", {
        Parent = TabList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    -- 内容容器
    local ContentContainer = Utils:Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 150, 0, 40),
        Size = UDim2.new(1, -150, 1, -40)
    })
    
    -- Tab 功能
    function Window:CreateTab(tabName, icon)
        local Tab = {
            Elements = {},
            Visible = false
        }
        
        -- Tab 按钮
        local TabButton = Utils:Create("TextButton", {
            Parent = TabList,
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BorderSizePixel = 0,
            Size = UDim2.new(1, -10, 0, 40),
            Font = Enum.Font.Gotham,
            Text = "  " .. tabName,
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        })
        
        Utils:Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0, 4)
        })
        
        -- Tab 内容框架
        local TabFrame = Utils:Create("ScrollingFrame", {
            Parent = ContentContainer,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Library.Settings.AccentColor,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        
        local TabLayout = Utils:Create("UIListLayout", {
            Parent = TabFrame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        
        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 10)
        end)
        
        Utils:Create("UIPadding", {
            Parent = TabFrame,
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
        
        TabButton.MouseButton1Click:Connect(function()
            -- 隐藏所有标签页
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                tab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
                tab.Frame.Visible = false
                tab.Visible = false
            end
            
            -- 显示当前标签页
            TabButton.BackgroundColor3 = Library.Settings.AccentColor
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabFrame.Visible = true
            Tab.Visible = true
            
            Utils:Ripple(TabButton, TabButton.AbsoluteSize.X/2, TabButton.AbsoluteSize.Y/2)
        end)
        
        -- 按钮悬停效果
        TabButton.MouseEnter:Connect(function()
            if not Tab.Visible then
                Utils:Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if not Tab.Visible then
                Utils:Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}, 0.2)
            end
        end)
        
        Tab.Button = TabButton
        Tab.Frame = TabFrame
        
        -- 创建按钮元素
        function Tab:CreateButton(options)
            options = options or {}
            local buttonText = options.Name or "Button"
            local callback = options.Callback or function() end
            
            local ButtonFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40)
            })
            
            Utils:Create("UICorner", {
                Parent = ButtonFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local Button = Utils:Create("TextButton", {
                Parent = ButtonFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = buttonText,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14
            })
            
            Button.MouseButton1Click:Connect(function()
                Utils:Ripple(ButtonFrame, Mouse.X - ButtonFrame.AbsolutePosition.X, Mouse.Y - ButtonFrame.AbsolutePosition.Y)
                pcall(callback)
            end)
            
            Button.MouseEnter:Connect(function()
                Utils:Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Utils:Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(28, 28, 33)}, 0.2)
            end)
            
            return {Frame = ButtonFrame, Button = Button}
        end
        
        -- 创建切换开关
        function Tab:CreateToggle(options)
            options = options or {}
            local toggleText = options.Name or "Toggle"
            local default = options.Default or false
            local callback = options.Callback or function() end
            
            local toggled = default
            
            local ToggleFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40)
            })
            
            Utils:Create("UICorner", {
                Parent = ToggleFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local ToggleLabel = Utils:Create("TextLabel", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Font = Enum.Font.Gotham,
                Text = toggleText,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ToggleButton = Utils:Create("TextButton", {
                Parent = ToggleFrame,
                BackgroundColor3 = toggled and Library.Settings.AccentColor or Color3.fromRGB(50, 50, 55),
                Position = UDim2.new(1, -50, 0.5, 0),
                Size = UDim2.new(0, 40, 0, 20),
                AnchorPoint = Vector2.new(0, 0.5),
                Text = "",
                AutoButtonColor = false
            })
            
            Utils:Create("UICorner", {
                Parent = ToggleButton,
                CornerRadius = UDim.new(1, 0)
            })
            
            local ToggleCircle = Utils:Create("Frame", {
                Parent = ToggleButton,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                AnchorPoint = Vector2.new(0, 0.5)
            })
            
            Utils:Create("UICorner", {
                Parent = ToggleCircle,
                CornerRadius = UDim.new(1, 0)
            })
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                Utils:Tween(ToggleButton, {
                    BackgroundColor3 = toggled and Library.Settings.AccentColor or Color3.fromRGB(50, 50, 55)
                }, 0.2)
                
                Utils:Tween(ToggleCircle, {
                    Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                }, 0.2)
                
                pcall(callback, toggled)
            end)
            
            return {
                Frame = ToggleFrame,
                SetValue = function(value)
                    toggled = value
                    ToggleButton.BackgroundColor3 = toggled and Library.Settings.AccentColor or Color3.fromRGB(50, 50, 55)
                    ToggleCircle.Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                end
            }
        end
        
        -- 创建滑块
        function Tab:CreateSlider(options)
            options = options or {}
            local sliderText = options.Name or "Slider"
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or 50
            local increment = options.Increment or 1
            local callback = options.Callback or function() end
            
            local value = default
            
            local SliderFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 60)
            })
            
            Utils:Create("UICorner", {
                Parent = SliderFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local SliderLabel = Utils:Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 5),
                Size = UDim2.new(1, -30, 0, 20),
                Font = Enum.Font.Gotham,
                Text = sliderText,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local SliderValue = Utils:Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -15, 0, 5),
                Size = UDim2.new(0, 0, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = tostring(value),
                TextColor3 = Library.Settings.AccentColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local SliderBar = Utils:Create("Frame", {
                Parent = SliderFrame,
                BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 15, 1, -25),
                Size = UDim2.new(1, -30, 0, 6)
            })
            
            Utils:Create("UICorner", {
                Parent = SliderBar,
                CornerRadius = UDim.new(1, 0)
            })
            
            local SliderFill = Utils:Create("Frame", {
                Parent = SliderBar,
                BackgroundColor3 = Library.Settings.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            })
            
            Utils:Create("UICorner", {
                Parent = SliderFill,
                CornerRadius = UDim.new(1, 0)
            })
            
            local SliderButton = Utils:Create("Frame", {
                Parent = SliderBar,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                AnchorPoint = Vector2.new(0.5, 0.5)
            })
            
            Utils:Create("UICorner", {
                Parent = SliderButton,
                CornerRadius = UDim.new(1, 0)
            })
            
            local dragging = false
            
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pos / increment + 0.5) * increment
                value = math.clamp(value, min, max)
                
                SliderValue.Text = tostring(value)
                SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                SliderButton.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
                
                pcall(callback, value)
            end
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            SliderBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            return {
                Frame = SliderFrame,
                SetValue = function(val)
                    value = math.clamp(val, min, max)
                    SliderValue.Text = tostring(value)
                    SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    SliderButton.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
                end
            }
        end
        
        -- 创建下拉列表
        function Tab:CreateDropdown(options)
            options = options or {}
            local dropdownText = options.Name or "Dropdown"
            local items = options.Items or {}
            local default = options.Default or items[1]
            local callback = options.Callback or function() end
            
            local selected = default
            local opened = false
            
            local DropdownFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                ClipsDescendants = true
            })
            
            Utils:Create("UICorner", {
                Parent = DropdownFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local DropdownButton = Utils:Create("TextButton", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Font = Enum.Font.Gotham,
                Text = "",
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14
            })
            
            local DropdownLabel = Utils:Create("TextLabel", {
                Parent = DropdownButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -50, 1, 0),
                Font = Enum.Font.Gotham,
                Text = dropdownText .. ": " .. tostring(selected),
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local DropdownIcon = Utils:Create("TextLabel", {
                Parent = DropdownButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 30, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = "▼",
                TextColor3 = Library.Settings.AccentColor,
                TextSize = 12
            })
            
            local ItemsList = Utils:Create("ScrollingFrame", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 40),
                Size = UDim2.new(1, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Library.Settings.AccentColor,
                CanvasSize = UDim2.new(0, 0, 0, #items * 35)
            })
            
            Utils:Create("UIListLayout", {
                Parent = ItemsList,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2)
            })
            
            for _, item in ipairs(items) do
                local ItemButton = Utils:Create("TextButton", {
                    Parent = ItemsList,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    Font = Enum.Font.Gotham,
                    Text = tostring(item),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 13,
                    AutoButtonColor = false
                })
                
                Utils:Create("UICorner", {
                    Parent = ItemButton,
                    CornerRadius = UDim.new(0, 4)
                })
                
                ItemButton.MouseButton1Click:Connect(function()
                    selected = item
                    DropdownLabel.Text = dropdownText .. ": " .. tostring(selected)
                    opened = false
                    Utils:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
                    Utils:Tween(DropdownIcon, {Rotation = 0}, 0.2)
                    pcall(callback, selected)
                end)
                
                ItemButton.MouseEnter:Connect(function()
                    Utils:Tween(ItemButton, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.1)
                end)
                
                ItemButton.MouseLeave:Connect(function()
                    Utils:Tween(ItemButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.1)
                end)
            end
            
            DropdownButton.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    local height = math.min(#items * 35, 150)
                    Utils:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40 + height)}, 0.2)
                    Utils:Tween(ItemsList, {Size = UDim2.new(1, 0, 0, height)}, 0.2)
                    Utils:Tween(DropdownIcon, {Rotation = 180}, 0.2)
                else
                    Utils:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
                    Utils:Tween(DropdownIcon, {Rotation = 0}, 0.2)
                end
            end)
            
            return {
                Frame = DropdownFrame,
                SetValue = function(val)
                    selected = val
                    DropdownLabel.Text = dropdownText .. ": " .. tostring(selected)
                end
            }
        end
        
        -- 创建颜色选择器（圆形）
        function Tab:CreateColorPicker(options)
            options = options or {}
            local pickerText = options.Name or "Color"
            local default = options.Default or Color3.fromRGB(255, 255, 255)
            local callback = options.Callback or function() end
            
            local selectedColor = default
            
            local PickerFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40)
            })
            
            Utils:Create("UICorner", {
                Parent = PickerFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local PickerLabel = Utils:Create("TextLabel", {
                Parent = PickerFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Font = Enum.Font.Gotham,
                Text = pickerText,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ColorDisplay = Utils:Create("Frame", {
                Parent = PickerFrame,
                BackgroundColor3 = selectedColor,
                Position = UDim2.new(1, -45, 0.5, 0),
                Size = UDim2.new(0, 30, 0, 30),
                AnchorPoint = Vector2.new(0, 0.5)
            })
            
            Utils:Create("UICorner", {
                Parent = ColorDisplay,
                CornerRadius = UDim.new(1, 0)
            })
            
            Utils:Create("UIStroke", {
                Parent = ColorDisplay,
                Color = Color3.fromRGB(60, 60, 65),
                Thickness = 2
            })
            
            local ColorPickerPopup = Utils:Create("Frame", {
                Parent = ScreenGui,
                BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Visible = false,
                ZIndex = 100
            })
            
            Utils:Create("UICorner", {
                Parent = ColorPickerPopup,
                CornerRadius = UDim.new(0, 8)
            })
            
            local PopupTitle = Utils:Create("TextLabel", {
                Parent = ColorPickerPopup,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Font = Enum.Font.GothamBold,
                Text = "选择颜色",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 15
            })
            
            -- 圆形颜色选择器
            local ColorWheel = Utils:Create("ImageLabel", {
                Parent = ColorPickerPopup,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0, 50),
                Size = UDim2.new(0, 180, 0, 180),
                AnchorPoint = Vector2.new(0.5, 0),
                Image = "rbxassetid://698052001",
                ImageColor3 = Color3.fromRGB(255, 255, 255)
            })
            
            local WheelCursor = Utils:Create("Frame", {
                Parent = ColorWheel,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 8, 0, 8),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 101
            })
            
            Utils:Create("UICorner", {
                Parent = WheelCursor,
                CornerRadius = UDim.new(1, 0)
            })
            
            Utils:Create("UIStroke", {
                Parent = WheelCursor,
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2
            })
            
            -- 亮度滑块
            local BrightnessSlider = Utils:Create("Frame", {
                Parent = ColorPickerPopup,
                BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                Position = UDim2.new(0.5, 0, 0, 250),
                Size = UDim2.new(0.8, 0, 0, 20),
                AnchorPoint = Vector2.new(0.5, 0)
            })
            
            Utils:Create("UICorner", {
                Parent = BrightnessSlider,
                CornerRadius = UDim.new(0, 10)
            })
            
            Utils:Create("UIGradient", {
                Parent = BrightnessSlider,
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                }
            })
            
            local BrightnessCursor = Utils:Create("Frame", {
                Parent = BrightnessSlider,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 6, 1, 8),
                AnchorPoint = Vector2.new(0.5, 0.5)
            })
            
            Utils:Create("UICorner", {
                Parent = BrightnessCursor,
                CornerRadius = UDim.new(1, 0)
            })
            
            -- 确认和取消按钮
            local ButtonContainer = Utils:Create("Frame", {
                Parent = ColorPickerPopup,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 1, -45),
                Size = UDim2.new(1, 0, 0, 35)
            })
            
            local ConfirmButton = Utils:Create("TextButton", {
                Parent = ButtonContainer,
                BackgroundColor3 = Library.Settings.AccentColor,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0.48, -10, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = "确认",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                AutoButtonColor = false
            })
            
            Utils:Create("UICorner", {
                Parent = ConfirmButton,
                CornerRadius = UDim.new(0, 6)
            })
            
            local CancelButton = Utils:Create("TextButton", {
                Parent = ButtonContainer,
                BackgroundColor3 = Color3.fromRGB(60, 60, 65),
                Position = UDim2.new(0.52, 0, 0, 0),
                Size = UDim2.new(0.48, -10, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = "取消",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                AutoButtonColor = false
            })
            
            Utils:Create("UICorner", {
                Parent = CancelButton,
                CornerRadius = UDim.new(0, 6)
            })
            
            ColorDisplay.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    ColorPickerPopup.Visible = true
                    Utils:Tween(ColorPickerPopup, {Size = UDim2.new(0, 250, 0, 320)}, 0.3)
                end
            end)
            
            ConfirmButton.MouseButton1Click:Connect(function()
                ColorDisplay.BackgroundColor3 = selectedColor
                pcall(callback, selectedColor)
                Utils:Tween(ColorPickerPopup, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
                task.wait(0.2)
                ColorPickerPopup.Visible = false
            end)
            
            CancelButton.MouseButton1Click:Connect(function()
                Utils:Tween(ColorPickerPopup, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
                task.wait(0.2)
                ColorPickerPopup.Visible = false
            end)
            
            local draggingWheel = false
            local draggingBrightness = false
            local hue, sat, val = 0, 1, 1
            
            ColorWheel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingWheel = true
                end
            end)
            
            ColorWheel.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingWheel = false
                end
            end)
            
            BrightnessSlider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingBrightness = true
                end
            end)
            
            BrightnessSlider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingBrightness = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if draggingWheel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local center = ColorWheel.AbsolutePosition + ColorWheel.AbsoluteSize / 2
                    local mouse = Vector2.new(input.Position.X, input.Position.Y)
                    local delta = mouse - center
                    local radius = ColorWheel.AbsoluteSize.X / 2
                    
                    local distance = math.min(delta.Magnitude, radius)
                    local angle = math.atan2(delta.Y, delta.X)
                    
                    hue = (angle + math.pi) / (2 * math.pi)
                    sat = distance / radius
                    
                    local x = math.cos(angle) * distance
                    local y = math.sin(angle) * distance
                    
                    WheelCursor.Position = UDim2.new(0.5, x, 0.5, y)
                    selectedColor = Color3.fromHSV(hue, sat, val)
                    ColorDisplay.BackgroundColor3 = selectedColor
                end
                
                if draggingBrightness and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = math.clamp((input.Position.X - BrightnessSlider.AbsolutePosition.X) / BrightnessSlider.AbsoluteSize.X, 0, 1)
                    val = pos
                    BrightnessCursor.Position = UDim2.new(pos, 0, 0.5, 0)
                    selectedColor = Color3.fromHSV(hue, sat, val)
                    ColorDisplay.BackgroundColor3 = selectedColor
                end
            end)
            
            return {
                Frame = PickerFrame,
                SetValue = function(color)
                    selectedColor = color
                    ColorDisplay.BackgroundColor3 = color
                end
            }
        end
        
        -- 创建文本框
        function Tab:CreateTextBox(options)
            options = options or {}
            local boxText = options.Name or "TextBox"
            local placeholder = options.Placeholder or "输入文本..."
            local default = options.Default or ""
            local callback = options.Callback or function() end
            
            local TextBoxFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(28, 28, 33),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 70)
            })
            
            Utils:Create("UICorner", {
                Parent = TextBoxFrame,
                CornerRadius = UDim.new(0, 6)
            })
            
            local BoxLabel = Utils:Create("TextLabel", {
                Parent = TextBoxFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 5),
                Size = UDim2.new(1, -30, 0, 20),
                Font = Enum.Font.Gotham,
                Text = boxText,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local TextBoxContainer = Utils:Create("Frame", {
                Parent = TextBoxFrame,
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Position = UDim2.new(0, 15, 0, 30),
                Size = UDim2.new(1, -30, 0, 30)
            })
            
            Utils:Create("UICorner", {
                Parent = TextBoxContainer,
                CornerRadius = UDim.new(0, 4)
            })
            
            local TextBox = Utils:Create("TextBox", {
                Parent = TextBoxContainer,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                Font = Enum.Font.Gotham,
                PlaceholderText = placeholder,
                PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
                Text = default,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            })
            
            TextBox.FocusLost:Connect(function(enter)
                if enter then
                    pcall(callback, TextBox.Text)
                end
            end)
            
            return {
                Frame = TextBoxFrame,
                TextBox = TextBox
            }
        end
        
        -- 创建标签
        function Tab:CreateLabel(text)
            local LabelFrame = Utils:Create("Frame", {
                Parent = TabFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 25)
            })
            
            local Label = Utils:Create("TextLabel", {
                Parent = LabelFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 0),
                Size = UDim2.new(1, -10, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = text,
                TextColor3 = Library.Settings.AccentColor,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            return {
                Frame = LabelFrame,
                Label = Label,
                SetText = function(newText)
                    Label.Text = newText
                end
            }
        end
        
        table.insert(Window.Tabs, Tab)
        
        -- 默认显示第一个标签页
        if #Window.Tabs == 1 then
            TabButton.BackgroundColor3 = Library.Settings.AccentColor
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabFrame.Visible = true
            Tab.Visible = true
        end
        
        return Tab
    end
    
    -- 创建设置标签页
    function Window:CreateSettingsTab()
        local SettingsTab = self:CreateTab("设置", "⚙️")
        
        SettingsTab:CreateLabel("═══ UI 设置 ═══")
        
        -- UI 透明度
        SettingsTab:CreateSlider({
            Name = "UI 透明度",
            Min = 0,
            Max = 100,
            Default = (1 - Library.Settings.BackgroundTransparency) * 100,
            Increment = 1,
            Callback = function(value)
                Library.Settings.BackgroundTransparency = 1 - (value / 100)
                MainFrame.BackgroundTransparency = Library.Settings.BackgroundTransparency
            end
        })
        
        -- 边框透明度
        SettingsTab:CreateSlider({
            Name = "边框透明度",
            Min = 0,
            Max = 100,
            Default = (1 - Library.Settings.BorderTransparency) * 100,
            Increment = 1,
            Callback = function(value)
                Library.Settings.BorderTransparency = 1 - (value / 100)
                for _, border in pairs(Border:GetChildren()) do
                    if border:IsA("Frame") then
                        border.BackgroundTransparency = Library.Settings.BorderTransparency
                    end
                end
            end
        })
        
        -- 彩虹边框
        SettingsTab:CreateToggle({
            Name = "彩虹边框",
            Default = Library.Settings.RainbowMode,
            Callback = function(value)
                Library.Settings.RainbowMode = value
                if value then
                    Utils:Rainbow(BorderTop, "BackgroundColor3")
                    Utils:Rainbow(BorderBottom, "BackgroundColor3")
                    Utils:Rainbow(BorderLeft, "BackgroundColor3")
                    Utils:Rainbow(BorderRight, "BackgroundColor3")
                else
                    for _, border in pairs(Border:GetChildren()) do
                        if border:IsA("Frame") then
                            border.BackgroundColor3 = Library.Settings.BorderColor
                        end
                    end
                end
            end
        })
        
        -- 主题色
        SettingsTab:CreateColorPicker({
            Name = "主题色",
            Default = Library.Settings.AccentColor,
            Callback = function(color)
                Library.Settings.AccentColor = color
                -- 更新所有使用主题色的元素
            end
        })
        
        SettingsTab:CreateLabel("═══ 配置管理 ═══")
        
        -- 配置名称输入
        local configNameBox = SettingsTab:CreateTextBox({
            Name = "配置名称",
            Placeholder = "输入配置名称...",
            Default = "",
            Callback = function() end
        })
        
        -- 保存配置按钮
        SettingsTab:CreateButton({
            Name = "💾 保存配置",
            Callback = function()
                local configName = configNameBox.TextBox.Text
                if configName ~= "" then
                    ConfigManager:Save(configName, Library.Settings)
                    print("配置已保存: " .. configName)
                end
            end
        })
        
        -- 加载配置下拉
        local configs = ConfigManager:List()
        if #configs > 0 then
            SettingsTab:CreateDropdown({
                Name = "加载配置",
                Items = configs,
                Default = configs[1],
                Callback = function(selected)
                    local data = ConfigManager:Load(selected)
                    if data then
                        for key, value in pairs(data) do
                            Library.Settings[key] = value
                        end
                        print("配置已加载: " .. selected)
                    end
                end
            })
        end
        
        SettingsTab:CreateLabel("═══ 其他 ═══")
        
        -- 销毁UI按钮
        SettingsTab:CreateButton({
            Name = "🗑️ 销毁UI",
            Callback = function()
                ScreenGui:Destroy()
            end
        })
        
        return SettingsTab
    end
    
    Window.ScreenGui = ScreenGui
    Window.MainFrame = MainFrame
    
    table.insert(Library.Windows, Window)
    
    return Window
end

-- 初始化配置管理器
ConfigManager:Init()

-- 手机端支持优化
if Utils:IsMobile() then
    Library.Settings.UIScale = 1.2
    print("检测到移动设备，UI已优化")
end

-- 彩虹循环
task.spawn(function()
    while true do
        if Library.Settings.RainbowMode then
            -- 彩虹效果已在 Utils:Rainbow 中处理
        end
        task.wait(0.1)
    end
end)

return Library
