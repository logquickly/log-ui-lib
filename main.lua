--[[
    Vape V4 Style UI Library - Floating Module System
    
    设计理念：
    - 左侧竖排Category标签
    - 中间区域网格排列的模块按钮（可点击开关）
    - 右键/展开按钮打开模块设置面板
    - 底部HUD显示已启用模块列表
    - 最小化为小Logo按钮
    
    兼容性：尽量低UNC要求，纯Instance操作
]]

local VapeLib = {}

-- ══════════════════════════════════════════════
-- Services
-- ══════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════════════════
-- 配色方案 (Vape V4 风格)
-- ══════════════════════════════════════════════

local Colors = {
    -- 主色
    Accent             = Color3.fromRGB(137, 100, 255),
    AccentDark         = Color3.fromRGB(110, 75, 220),
    AccentLight        = Color3.fromRGB(165, 135, 255),
    AccentGlow         = Color3.fromRGB(137, 100, 255),

    -- 背景层级
    BG_Primary         = Color3.fromRGB(18, 18, 27),
    BG_Secondary       = Color3.fromRGB(24, 24, 36),
    BG_Tertiary        = Color3.fromRGB(30, 30, 45),
    BG_Elevated        = Color3.fromRGB(36, 36, 52),

    -- 模块卡片
    Module_Off         = Color3.fromRGB(32, 32, 48),
    Module_On          = Color3.fromRGB(137, 100, 255),
    Module_Hover       = Color3.fromRGB(42, 42, 60),

    -- 文字
    Text_Primary       = Color3.fromRGB(255, 255, 255),
    Text_Secondary     = Color3.fromRGB(185, 185, 205),
    Text_Tertiary      = Color3.fromRGB(120, 120, 150),
    Text_Disabled      = Color3.fromRGB(80, 80, 100),

    -- 控件
    Toggle_BG_Off      = Color3.fromRGB(55, 55, 75),
    Toggle_BG_On       = Color3.fromRGB(137, 100, 255),
    Slider_Track       = Color3.fromRGB(45, 45, 65),
    Slider_Fill        = Color3.fromRGB(137, 100, 255),
    Input_BG           = Color3.fromRGB(22, 22, 34),
    Divider            = Color3.fromRGB(50, 50, 68),
    
    -- HUD
    HUD_BG             = Color3.fromRGB(15, 15, 22),
    HUD_Module         = Color3.fromRGB(137, 100, 255),

    -- 阴影
    Shadow             = Color3.fromRGB(0, 0, 0),
}

-- ══════════════════════════════════════════════
-- 动画配置
-- ══════════════════════════════════════════════

local Anim = {
    Fast     = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Normal   = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth   = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Bounce   = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    Slow     = TweenInfo.new(0.5,  Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

-- ══════════════════════════════════════════════
-- 工具函数
-- ══════════════════════════════════════════════

local function Tween(instance, properties, tweenInfo)
    if not instance or not instance.Parent then return end
    tweenInfo = tweenInfo or Anim.Normal
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function Create(className, properties)
    local instance = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            if key ~= "Parent" and key ~= "Children" then
                pcall(function()
                    instance[key] = value
                end)
            end
        end
        if properties.Children then
            for _, child in ipairs(properties.Children) do
                child.Parent = instance
            end
        end
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end
    return instance
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Colors.Divider,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Padding(parent, t, r, b, l)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        Parent = parent,
    })
end

local function ListLayout(parent, padding, direction, alignment, sortOrder)
    return Create("UIListLayout", {
        Padding                  = UDim.new(0, padding or 4),
        FillDirection            = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment      = alignment or Enum.HorizontalAlignment.Left,
        SortOrder                = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function GridLayout(parent, cellSize, cellPadding)
    return Create("UIGridLayout", {
        CellSize     = cellSize or UDim2.new(0, 120, 0, 38),
        CellPadding  = cellPadding or UDim2.new(0, 6, 0, 6),
        SortOrder    = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 4,
        Parent = parent,
    })
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

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

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            Tween(frame, {Position = newPos}, Anim.Fast)
        end
    end)
end

local function GetTextBounds(text, fontSize, font, maxWidth)
    local success, result = pcall(function()
        return TextService:GetTextSize(text, fontSize, font, Vector2.new(maxWidth or 1000, 1000))
    end)
    if success then
        return result
    end
    return Vector2.new(#text * fontSize * 0.55, fontSize * 1.4)
end

-- ══════════════════════════════════════════════
-- 安全的GUI容器
-- ══════════════════════════════════════════════

local function CreateScreenGui(name)
    local gui = Create("ScreenGui", {
        Name = name or "VapeV4_" .. math.random(100000, 999999),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })

    -- 尝试CoreGui
    local success = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)

    if not success then
        -- 回退到PlayerGui
        pcall(function()
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    return gui
end

-- ══════════════════════════════════════════════
-- 通知系统
-- ══════════════════════════════════════════════

local NotificationContainer

local function InitNotifications(screenGui)
    NotificationContainer = Create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -15, 1, -15),
        Size = UDim2.new(0, 300, 0, 400),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })

    ListLayout(NotificationContainer, 6, Enum.FillDirection.Vertical,
               Enum.HorizontalAlignment.Right)
    Padding(NotificationContainer, 0, 0, 0, 0)
end

local function Notify(title, message, duration, notifType)
    if not NotificationContainer then return end

    duration = duration or 3.5
    notifType = notifType or "info"

    local accentColor = Colors.Accent
    if notifType == "success" then
        accentColor = Color3.fromRGB(80, 200, 120)
    elseif notifType == "error" then
        accentColor = Color3.fromRGB(240, 70, 70)
    elseif notifType == "warning" then
        accentColor = Color3.fromRGB(240, 180, 50)
    end

    local card = Create("Frame", {
        Name = "Notif",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Colors.BG_Secondary,
        ClipsDescendants = true,
        Parent = NotificationContainer,
    })
    Corner(card, 10)
    Stroke(card, accentColor, 1, 0.55)

    -- 顶部强调条
    local topBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = card,
    })

    -- 标题
    Create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = title or "Vape V4",
        TextColor3 = Colors.Text_Primary,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })

    -- 消息
    Create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 28),
        Size = UDim2.new(1, -24, 0, 26),
        BackgroundTransparency = 1,
        Text = message or "",
        TextColor3 = Colors.Text_Secondary,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })

    -- 底部进度条
    local progressBar = Create("Frame", {
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = card,
    })

    -- 入场动画
    card.BackgroundTransparency = 1
    card.Position = UDim2.new(1, 50, 0, 0)
    
    Tween(card, {BackgroundTransparency = 0.02, Position = UDim2.new(0, 0, 0, 0)}, Anim.Bounce)
    Tween(progressBar, {Size = UDim2.new(0, 0, 0, 2)}, TweenInfo.new(duration, Enum.EasingStyle.Linear))

    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, {BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0)}, Anim.Normal)
            task.delay(0.25, function()
                if card and card.Parent then
                    card:Destroy()
                end
            end)
        end
    end)
end

-- ══════════════════════════════════════════════
-- HUD 模块列表（右下角/左侧已启用模块竖排）
-- ══════════════════════════════════════════════

local HUD = {}

local function InitHUD(screenGui)
    HUD.Container = Create("Frame", {
        Name = "HUD_ModuleList",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.new(0, 200, 0, 600),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })

    HUD.Layout = ListLayout(HUD.Container, 1, Enum.FillDirection.Vertical,
                             Enum.HorizontalAlignment.Right)
    
    HUD.Modules = {}
end

local function HUD_AddModule(moduleName)
    if HUD.Modules[moduleName] then return end

    local textBounds = GetTextBounds(moduleName, 13, Enum.Font.GothamBold, 300)

    local label = Create("TextLabel", {
        Name = "HUD_" .. moduleName,
        Size = UDim2.new(0, textBounds.X + 16, 0, 20),
        BackgroundColor3 = Colors.HUD_BG,
        BackgroundTransparency = 0.3,
        Text = moduleName,
        TextColor3 = Colors.HUD_Module,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = HUD.Container,
    })
    Corner(label, 3)

    Padding(label, 0, 8, 0, 8)

    -- 入场动画
    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    Tween(label, {TextTransparency = 0, BackgroundTransparency = 0.3}, Anim.Normal)

    HUD.Modules[moduleName] = label
end

local function HUD_RemoveModule(moduleName)
    local label = HUD.Modules[moduleName]
    if not label then return end

    Tween(label, {TextTransparency = 1, BackgroundTransparency = 1}, Anim.Fast)
    task.delay(0.15, function()
        if label and label.Parent then
            label:Destroy()
        end
    end)
    HUD.Modules[moduleName] = nil
end

-- ══════════════════════════════════════════════
-- 设置面板（展开窗口）组件构建器
-- ══════════════════════════════════════════════

local SettingsBuilder = {}

-- Toggle
function SettingsBuilder.Toggle(parent, config)
    config = config or {}
    local name     = config.Name or "Toggle"
    local default  = config.Default or false
    local callback = config.Callback or function() end
    local desc     = config.Description

    local state = default
    local rowHeight = desc and 50 or 34

    local row = Create("Frame", {
        Name = "Toggle_" .. name,
        Size = UDim2.new(1, 0, 0, rowHeight),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.4,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    -- 名称
    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -62, 0, 34),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    -- 描述
    if desc then
        Create("TextLabel", {
            Position = UDim2.new(0, 10, 0, 28),
            Size = UDim2.new(1, -62, 0, 18),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = Colors.Text_Tertiary,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row,
        })
    end

    -- Toggle轨道
    local track = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 18),
        BackgroundColor3 = state and Colors.Toggle_BG_On or Colors.Toggle_BG_Off,
        Parent = row,
    })
    Corner(track, 9)

    local knob = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Colors.Text_Primary,
        Parent = track,
    })
    Corner(knob, 7)

    local function refresh()
        if state then
            Tween(track, {BackgroundColor3 = Colors.Toggle_BG_On}, Anim.Normal)
            Tween(knob, {Position = UDim2.new(1, -16, 0.5, 0)}, Anim.Bounce)
        else
            Tween(track, {BackgroundColor3 = Colors.Toggle_BG_Off}, Anim.Normal)
            Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, Anim.Bounce)
        end
        callback(state)
    end

    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, Anim.Fast)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.4}, Anim.Fast)
    end)
    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
    end)

    if default then
        task.defer(function() callback(true) end)
    end

    local control = {}
    function control:Set(val) state = val; refresh() end
    function control:Get() return state end
    return control
end

-- Slider
function SettingsBuilder.Slider(parent, config)
    config = config or {}
    local name      = config.Name or "Slider"
    local min       = config.Min or 0
    local max       = config.Max or 100
    local default   = config.Default or min
    local increment = config.Increment or 1
    local suffix    = config.Suffix or ""
    local callback  = config.Callback or function() end

    local value = math.clamp(default, min, max)

    local row = Create("Frame", {
        Name = "Slider_" .. name,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.4,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    -- 名称
    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 2),
        Size = UDim2.new(0.5, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    -- 数值
    local valueLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 2),
        Size = UDim2.new(0.4, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(value) .. suffix,
        TextColor3 = Colors.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    -- 轨道
    local trackBG = Create("Frame", {
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = Colors.Slider_Track,
        Parent = row,
    })
    Corner(trackBG, 3)

    local percent = (value - min) / math.max(max - min, 0.001)

    local fill = Create("Frame", {
        Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0),
        BackgroundColor3 = Colors.Slider_Fill,
        Parent = trackBG,
    })
    Corner(fill, 3)

    local knobFrame = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(math.clamp(percent, 0, 1), 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Colors.Text_Primary,
        ZIndex = 2,
        Parent = trackBG,
    })
    Corner(knobFrame, 6)
    Stroke(knobFrame, Colors.Accent, 2, 0)

    local sliding = false

    local function update(inputX)
        local relX = math.clamp(
            (inputX - trackBG.AbsolutePosition.X) / math.max(trackBG.AbsoluteSize.X, 1),
            0, 1
        )
        local rawValue = min + (max - min) * relX
        value = math.floor(rawValue / increment + 0.5) * increment
        value = math.clamp(value, min, max)

        local p = (value - min) / math.max(max - min, 0.001)
        Tween(fill, {Size = UDim2.new(p, 0, 1, 0)}, Anim.Fast)
        Tween(knobFrame, {Position = UDim2.new(p, 0, 0.5, 0)}, Anim.Fast)
        valueLabel.Text = tostring(value) .. suffix
        callback(value)
    end

    trackBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, Anim.Fast)
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.4}, Anim.Fast)
    end)

    local control = {}
    function control:Set(val)
        value = math.clamp(val, min, max)
        local p = (value - min) / math.max(max - min, 0.001)
        Tween(fill, {Size = UDim2.new(p, 0, 1, 0)}, Anim.Normal)
        Tween(knobFrame, {Position = UDim2.new(p, 0, 0.5, 0)}, Anim.Normal)
        valueLabel.Text = tostring(value) .. suffix
        callback(value)
    end
    function control:Get() return value end
    return control
end

-- Dropdown
function SettingsBuilder.Dropdown(parent, config)
    config = config or {}
    local name     = config.Name or "Dropdown"
    local options  = config.Options or {}
    local default  = config.Default or (options[1] or "")
    local callback = config.Callback or function() end

    local selected = default
    local opened   = false

    local row = Create("Frame", {
        Name = "Dropdown_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.4,
        ClipsDescendants = true,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    -- 名称
    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.45, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    -- 当前选中值
    local selectedLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        Size = UDim2.new(0.4, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = selected,
        TextColor3 = Colors.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    -- 箭头
    local arrow = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 18, 0, 34),
        BackgroundTransparency = 1,
        Text = "▾",
        TextColor3 = Colors.Text_Tertiary,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Rotation = 0,
        Parent = row,
    })

    -- 选项容器
    local optionContainer = Create("Frame", {
        Position = UDim2.new(0, 4, 0, 38),
        Size = UDim2.new(1, -8, 0, #options * 28 + (#options - 1) * 2),
        BackgroundTransparency = 1,
        Parent = row,
    })
    ListLayout(optionContainer, 2)

    local optionButtons = {}

    local function refreshOptions()
        for _, btn in pairs(optionButtons) do
            if btn and btn.Parent then
                local isSelected = (btn.Name == selected)
                Tween(btn, {
                    TextColor3 = isSelected and Colors.Accent or Colors.Text_Secondary,
                }, Anim.Fast)
            end
        end
    end

    for i, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Name = opt,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Colors.BG_Tertiary,
            BackgroundTransparency = 0.3,
            Text = opt,
            TextColor3 = (opt == selected) and Colors.Accent or Colors.Text_Secondary,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = optionContainer,
        })
        Corner(optBtn, 4)
        table.insert(optionButtons, optBtn)

        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundTransparency = 0}, Anim.Fast)
        end)
        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, {BackgroundTransparency = 0.3}, Anim.Fast)
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selectedLabel.Text = selected
            refreshOptions()
            callback(selected)

            -- 收起
            opened = false
            Tween(row, {Size = UDim2.new(1, 0, 0, 34)}, Anim.Bounce)
            Tween(arrow, {Rotation = 0}, Anim.Normal)
        end)
    end

    -- Header点击
    local headerBtn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
        Parent = row,
    })

    headerBtn.MouseButton1Click:Connect(function()
        opened = not opened
        if opened then
            local totalH = 42 + #options * 28 + math.max(0, #options - 1) * 2
            Tween(row, {Size = UDim2.new(1, 0, 0, totalH)}, Anim.Bounce)
            Tween(arrow, {Rotation = 180}, Anim.Normal)
        else
            Tween(row, {Size = UDim2.new(1, 0, 0, 34)}, Anim.Bounce)
            Tween(arrow, {Rotation = 0}, Anim.Normal)
        end
    end)

    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, Anim.Fast)
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.4}, Anim.Fast)
    end)

    local control = {}
    function control:Set(val) selected = val; selectedLabel.Text = val; refreshOptions(); callback(val) end
    function control:Get() return selected end
    function control:Refresh(newOpts)
        options = newOpts
        for _, btn in pairs(optionButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        optionButtons = {}
        for i, opt in ipairs(options) do
            local optBtn = Create("TextButton", {
                Name = opt,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Colors.BG_Tertiary,
                BackgroundTransparency = 0.3,
                Text = opt,
                TextColor3 = Colors.Text_Secondary,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = optionContainer,
            })
            Corner(optBtn, 4)
            table.insert(optionButtons, optBtn)
            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                selectedLabel.Text = selected
                refreshOptions()
                callback(selected)
                opened = false
                Tween(row, {Size = UDim2.new(1, 0, 0, 34)}, Anim.Bounce)
                Tween(arrow, {Rotation = 0}, Anim.Normal)
            end)
        end
        optionContainer.Size = UDim2.new(1, -8, 0, #options * 28 + math.max(0, #options - 1) * 2)
    end
    return control
end

-- Button
function SettingsBuilder.Button(parent, config)
    config = config or {}
    local name     = config.Name or "Button"
    local callback = config.Callback or function() end

    local row = Create("Frame", {
        Name = "Button_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.3,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Text = "→",
        TextColor3 = Colors.Text_Tertiary,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = row,
    })

    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.1}, Anim.Fast)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.3}, Anim.Fast)
    end)
    btn.MouseButton1Click:Connect(function()
        Tween(row, {BackgroundColor3 = Colors.Accent}, Anim.Fast)
        task.delay(0.15, function()
            Tween(row, {BackgroundColor3 = Colors.BG_Elevated}, Anim.Normal)
        end)
        callback()
    end)
end

-- Textbox
function SettingsBuilder.Textbox(parent, config)
    config = config or {}
    local name        = config.Name or "Input"
    local default     = config.Default or ""
    local placeholder = config.Placeholder or "Type here..."
    local callback    = config.Callback or function() end

    local row = Create("Frame", {
        Name = "Textbox_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.4,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.38, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local inputBG = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.55, 0, 0, 24),
        BackgroundColor3 = Colors.Input_BG,
        Parent = row,
    })
    Corner(inputBG, 5)
    Stroke(inputBG, Colors.Divider, 1, 0.6)

    local input = Create("TextBox", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Colors.Text_Disabled,
        TextColor3 = Colors.Text_Secondary,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBG,
    })

    input.Focused:Connect(function()
        Tween(inputBG, {BackgroundColor3 = Colors.BG_Tertiary}, Anim.Fast)
        local strokeObj = inputBG:FindFirstChildOfClass("UIStroke")
        if strokeObj then
            Tween(strokeObj, {Color = Colors.Accent, Transparency = 0.2}, Anim.Fast)
        end
    end)

    input.FocusLost:Connect(function(enterPressed)
        Tween(inputBG, {BackgroundColor3 = Colors.Input_BG}, Anim.Fast)
        local strokeObj = inputBG:FindFirstChildOfClass("UIStroke")
        if strokeObj then
            Tween(strokeObj, {Color = Colors.Divider, Transparency = 0.6}, Anim.Fast)
        end
        callback(input.Text, enterPressed)
    end)

    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, Anim.Fast)
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.4}, Anim.Fast)
    end)

    local control = {}
    function control:Set(val) input.Text = val end
    function control:Get() return input.Text end
    return control
end

-- Keybind
function SettingsBuilder.Keybind(parent, config)
    config = config or {}
    local name     = config.Name or "Keybind"
    local default  = config.Default or Enum.KeyCode.Unknown
    local callback = config.Callback or function() end

    local currentKey = default
    local listening  = false

    local row = Create("Frame", {
        Name = "Keybind_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Colors.BG_Elevated,
        BackgroundTransparency = 0.4,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Corner(row, 6)

    Create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.55, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text_Primary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local keyBtn = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 65, 0, 22),
        BackgroundColor3 = Colors.Input_BG,
        Text = currentKey ~= Enum.KeyCode.Unknown and currentKey.Name or "None",
        TextColor3 = Colors.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = row,
    })
    Corner(keyBtn, 4)
    Stroke(keyBtn, Colors.Divider, 1, 0.6)

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, {BackgroundColor3 = Colors.Accent}, Anim.Fast)
        Tween(keyBtn, {TextColor3 = Colors.Text_Primary}, Anim.Fast)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                currentKey = Enum.KeyCode.Unknown
                keyBtn.Text = "None"
            else
                currentKey = input.KeyCode
                keyBtn.Text = currentKey.Name
            end
            listening = false
            Tween(keyBtn, {BackgroundColor3 = Colors.Input_BG}, Anim.Fast)
            Tween(keyBtn, {TextColor3 = Colors.Accent}, Anim.Fast)
            callback(currentKey)
        end
    end)

    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = 0.2}, Anim.Fast)
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 0.4}, Anim.Fast)
    end)

    local control = {}
    function control:Get() return currentKey end
    function control:Set(key)
        currentKey = key
        keyBtn.Text = key ~= Enum.KeyCode.Unknown and key.Name or "None"
        callback(key)
    end
    return control
end

-- Label/Header
function SettingsBuilder.Label(parent, config)
    config = config or {}
    local text = config.Text or "Section"

    local label = Create("TextLabel", {
        Name = "Label_" .. text,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = Colors.Text_Tertiary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
    Padding(label, 0, 0, 0, 4)

    local control = {}
    function control:Set(val) label.Text = string.upper(val) end
    return control
end

-- Divider
function SettingsBuilder.Divider(parent)
    Create("Frame", {
        Name = "Divider",
        Size = UDim2.new(0.92, 0, 0, 1),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })
end

-- ══════════════════════════════════════════════
-- 核心：创建Window（Vape V4主界面）
-- ══════════════════════════════════════════════

function VapeLib:CreateWindow(config)
    config = config or {}

    local Window = {
        Title       = config.Title or "Vape V4",
        Subtitle    = config.Subtitle or "",
        ToggleKey   = config.ToggleKey or Enum.KeyCode.RightShift,
        Categories  = {},
        ActiveCategory = nil,
        ActiveSettingsPanel = nil,
        IsOpen      = true,
        Modules     = {},  -- 所有模块数据
    }

    -- ScreenGui
    Window.ScreenGui = CreateScreenGui("VapeV4")
    InitNotifications(Window.ScreenGui)
    InitHUD(Window.ScreenGui)

    -- ═══════════════════════════════════════
    -- 主面板
    -- ═══════════════════════════════════════

    Window.MainFrame = Create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 620, 0, 420),
        BackgroundColor3 = Colors.BG_Primary,
        ClipsDescendants = true,
        Parent = Window.ScreenGui,
    })
    Corner(Window.MainFrame, 12)
    Stroke(Window.MainFrame, Colors.Accent, 1, 0.75)

    -- ═══════════════════════════════════════
    -- 左侧 Category 导航栏
    -- ═══════════════════════════════════════

    Window.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 155, 1, 0),
        BackgroundColor3 = Colors.BG_Secondary,
        BorderSizePixel = 0,
        Parent = Window.MainFrame,
    })

    -- 右侧分隔线
    Create("Frame", {
        Name = "SidebarDivider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = Window.Sidebar,
    })

    -- Logo区域
    local logoArea = Create("Frame", {
        Name = "Logo",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = Window.Sidebar,
    })

    -- 顶部渐变条
    local accentLine = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Parent = logoArea,
    })
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Colors.Accent),
            ColorSequenceKeypoint.new(1, Colors.AccentLight),
        }),
        Parent = accentLine,
    })

    -- Logo "V"
    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = Colors.Accent,
        Text = "V",
        TextColor3 = Colors.Text_Primary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = logoArea,
        Children = {
            Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        },
    })

    Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 12),
        Size = UDim2.new(1, -60, 0, 18),
        BackgroundTransparency = 1,
        Text = Window.Title,
        TextColor3 = Colors.Text_Primary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = logoArea,
    })

    if Window.Subtitle ~= "" then
        Create("TextLabel", {
            Position = UDim2.new(0, 50, 0, 32),
            Size = UDim2.new(1, -60, 0, 14),
            BackgroundTransparency = 1,
            Text = Window.Subtitle,
            TextColor3 = Colors.Text_Tertiary,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = logoArea,
        })
    end

    -- 分隔线
    Create("Frame", {
        Position = UDim2.new(0.08, 0, 1, -1),
        Size = UDim2.new(0.84, 0, 0, 1),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = logoArea,
    })

    -- Category列表
    Window.CategoryList = Create("ScrollingFrame", {
        Name = "CategoryList",
        Position = UDim2.new(0, 0, 0, 65),
        Size = UDim2.new(1, 0, 1, -110),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Window.Sidebar,
    })
    ListLayout(Window.CategoryList, 2)
    Padding(Window.CategoryList, 4, 8, 4, 8)

    -- 底部用户信息
    local userArea = Create("Frame", {
        Name = "UserInfo",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = Window.Sidebar,
    })

    Create("Frame", {
        Position = UDim2.new(0.08, 0, 0, 0),
        Size = UDim2.new(0.84, 0, 0, 1),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = userArea,
    })

    local avatar = Create("ImageLabel", {
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Colors.BG_Tertiary,
        Parent = userArea,
    })
    Corner(avatar, 12)
    pcall(function()
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=48&h=48"
    end)

    Create("TextLabel", {
        Position = UDim2.new(0, 42, 0, 10),
        Size = UDim2.new(1, -54, 0, 24),
        BackgroundTransparency = 1,
        Text = LocalPlayer.DisplayName,
        TextColor3 = Colors.Text_Secondary,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = userArea,
    })

    -- ═══════════════════════════════════════
    -- 右侧内容区域
    -- ═══════════════════════════════════════

    Window.ContentArea = Create("Frame", {
        Name = "ContentArea",
        Position = UDim2.new(0, 155, 0, 0),
        Size = UDim2.new(1, -155, 1, 0),
        BackgroundTransparency = 1,
        Parent = Window.MainFrame,
    })

    -- 顶部栏（标题 + 搜索）
    local topBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = Window.ContentArea,
    })

    Window.ContentTitle = Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.45, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Modules",
        TextColor3 = Colors.Text_Primary,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    -- 搜索框
    local searchContainer = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 160, 0, 28),
        BackgroundColor3 = Colors.BG_Tertiary,
        Parent = topBar,
    })
    Corner(searchContainer, 6)

    Create("TextLabel", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextSize = 11,
        TextColor3 = Colors.Text_Tertiary,
        Font = Enum.Font.Gotham,
        Parent = searchContainer,
    })

    Window.SearchBox = Create("TextBox", {
        Position = UDim2.new(0, 24, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = Colors.Text_Disabled,
        TextColor3 = Colors.Text_Secondary,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchContainer,
    })

    -- TopBar底部分隔线
    Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0.94, 0, 0, 1),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = topBar,
    })

    -- ═══════════════════════════════════════
    -- 模块网格区域
    -- ═══════════════════════════════════════

    Window.ModuleGrid = Create("ScrollingFrame", {
        Name = "ModuleGrid",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Colors.Accent,
        ScrollBarImageTransparency = 0.6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Window.ContentArea,
    })
    Padding(Window.ModuleGrid, 8, 10, 8, 10)

    -- ═══════════════════════════════════════
    -- 设置面板（右侧展开）
    -- ═══════════════════════════════════════

    Window.SettingsPanel = Create("Frame", {
        Name = "SettingsPanel",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 320, 0, 0),  -- 初始隐藏在右侧外
        Size = UDim2.new(0, 260, 1, 0),
        BackgroundColor3 = Colors.BG_Secondary,
        ClipsDescendants = true,
        ZIndex = 5,
        Parent = Window.MainFrame,
    })
    Corner(Window.SettingsPanel, 0)
    
    -- 设置面板左边界
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = Window.SettingsPanel,
    })

    -- 设置面板标题
    local settingsTitleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = Window.SettingsPanel,
    })

    Window.SettingsTitle = Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = "Settings",
        TextColor3 = Colors.Text_Primary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = settingsTitleBar,
    })

    -- 关闭按钮
    local closeSettingsBtn = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = Colors.BG_Tertiary,
        BackgroundTransparency = 0.5,
        Text = "×",
        TextColor3 = Colors.Text_Secondary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = settingsTitleBar,
    })
    Corner(closeSettingsBtn, 6)

    closeSettingsBtn.MouseEnter:Connect(function()
        Tween(closeSettingsBtn, {BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(240, 80, 80)}, Anim.Fast)
    end)
    closeSettingsBtn.MouseLeave:Connect(function()
        Tween(closeSettingsBtn, {BackgroundTransparency = 0.5, TextColor3 = Colors.Text_Secondary}, Anim.Fast)
    end)
    closeSettingsBtn.MouseButton1Click:Connect(function()
        Window:CloseSettings()
    end)

    -- 分隔线
    Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0.88, 0, 0, 1),
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = settingsTitleBar,
    })

    -- 设置内容滚动区域
    Window.SettingsContent = Create("ScrollingFrame", {
        Name = "SettingsContent",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Colors.Accent,
        ScrollBarImageTransparency = 0.6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Window.SettingsPanel,
    })
    ListLayout(Window.SettingsContent, 4)
    Padding(Window.SettingsContent, 6, 10, 6, 10)

    -- ═══════════════════════════════════════
    -- 最小化Logo按钮
    -- ═══════════════════════════════════════

    Window.LogoButton = Create("TextButton", {
        Name = "LogoButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 48, 0, 48),
        BackgroundColor3 = Colors.Accent,
        BackgroundTransparency = 0.05,
        Text = "V",
        TextColor3 = Colors.Text_Primary,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Visible = false,
        Parent = Window.ScreenGui,
    })
    Corner(Window.LogoButton, 24)
    Stroke(Window.LogoButton, Colors.AccentLight, 2, 0.4)

    -- Logo按钮拖拽
    MakeDraggable(Window.LogoButton)

    -- Logo hover效果
    Window.LogoButton.MouseEnter:Connect(function()
        Tween(Window.LogoButton, {Size = UDim2.new(0, 54, 0, 54)}, Anim.Bounce)
    end)
    Window.LogoButton.MouseLeave:Connect(function()
        Tween(Window.LogoButton, {Size = UDim2.new(0, 48, 0, 48)}, Anim.Normal)
    end)
    Window.LogoButton.MouseButton1Click:Connect(function()
        Window:Open()
    end)

    -- ═══════════════════════════════════════
    -- 拖拽主窗口
    -- ═══════════════════════════════════════

    MakeDraggable(Window.MainFrame, topBar)
    MakeDraggable(Window.MainFrame, logoArea)

    -- ═══════════════════════════════════════
    -- 搜索过滤
    -- ═══════════════════════════════════════

    Window.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(Window.SearchBox.Text)
        for _, moduleData in ipairs(Window.Modules) do
            if moduleData.Card and moduleData.Card.Parent then
                local match = query == "" or string.find(string.lower(moduleData.Name), query, 1, true)
                moduleData.Card.Visible = (match ~= nil)
            end
        end
    end)

    -- ═══════════════════════════════════════
    -- 快捷键切换
    -- ═══════════════════════════════════════

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Window.ToggleKey then
            if Window.IsOpen then
                Window:Close()
            else
                Window:Open()
            end
        end
    end)

    -- ═══════════════════════════════════════
    -- Window 方法
    -- ═══════════════════════════════════════

    function Window:Open()
        self.IsOpen = true
        self.MainFrame.Visible = true
        self.LogoButton.Visible = false

        -- 展开动画
        self.MainFrame.Size = UDim2.new(0, 620, 0, 0)
        self.MainFrame.BackgroundTransparency = 0.8
        Tween(self.MainFrame, {
            Size = UDim2.new(0, 620, 0, 420),
            BackgroundTransparency = 0,
        }, Anim.Bounce)
    end

    function Window:Close()
        self.IsOpen = false
        self:CloseSettings()

        Tween(self.MainFrame, {
            Size = UDim2.new(0, 620, 0, 0),
            BackgroundTransparency = 0.8,
        }, Anim.Smooth)

        task.delay(0.35, function()
            if not self.IsOpen then
                self.MainFrame.Visible = false
                self.LogoButton.Visible = true

                -- Logo弹入动画
                self.LogoButton.Size = UDim2.new(0, 0, 0, 0)
                Tween(self.LogoButton, {Size = UDim2.new(0, 48, 0, 48)}, Anim.Bounce)
            end
        end)
    end

    function Window:OpenSettings(moduleData)
        if self.ActiveSettingsPanel == moduleData.Name then return end

        self.ActiveSettingsPanel = moduleData.Name
        self.SettingsTitle.Text = moduleData.Name

        -- 清空旧内容
        for _, child in ipairs(self.SettingsContent:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        -- 填充新内容
        if moduleData.SettingsBuilder then
            moduleData.SettingsBuilder(self.SettingsContent)
        end

        -- 滑入动画
        Tween(self.SettingsPanel, {
            Position = UDim2.new(1, 0, 0, 0),
        }, Anim.Bounce)

        -- 主内容区域缩窄
        Tween(self.ModuleGrid, {
            Size = UDim2.new(1, -260, 1, -44),
        }, Anim.Smooth)
    end

    function Window:CloseSettings()
        self.ActiveSettingsPanel = nil

        Tween(self.SettingsPanel, {
            Position = UDim2.new(1, 320, 0, 0),
        }, Anim.Smooth)

        Tween(self.ModuleGrid, {
            Size = UDim2.new(1, 0, 1, -44),
        }, Anim.Smooth)
    end

    function Window:SwitchCategory(categoryData)
        if self.ActiveCategory == categoryData then return end

        -- 取消旧category
        if self.ActiveCategory then
            local old = self.ActiveCategory
            Tween(old.Button, {BackgroundTransparency = 1}, Anim.Normal)
            Tween(old.Indicator, {BackgroundTransparency = 1}, Anim.Normal)
            Tween(old.Label, {TextColor3 = Colors.Text_Secondary}, Anim.Normal)
            Tween(old.IconLabel, {TextColor3 = Colors.Text_Tertiary}, Anim.Normal)
        end

        self.ActiveCategory = categoryData

        -- 激活新category
        Tween(categoryData.Button, {
            BackgroundTransparency = 0.5,
            BackgroundColor3 = Colors.BG_Elevated,
        }, Anim.Normal)
        Tween(categoryData.Indicator, {BackgroundTransparency = 0}, Anim.Normal)
        Tween(categoryData.Label, {TextColor3 = Colors.Text_Primary}, Anim.Normal)
        Tween(categoryData.IconLabel, {TextColor3 = Colors.Accent}, Anim.Normal)

        self.ContentTitle.Text = categoryData.Name

        -- 关闭设置面板
        self:CloseSettings()

        -- 显示/隐藏模块卡片
        for _, moduleData in ipairs(self.Modules) do
            if moduleData.Card then
                local shouldShow = (moduleData.Category == categoryData.Name)
                if shouldShow then
                    moduleData.Card.Visible = true
                    moduleData.Card.BackgroundTransparency = 1
                    Tween(moduleData.Card, {BackgroundTransparency = 0}, Anim.Normal)
                else
                    moduleData.Card.Visible = false
                end
            end
        end
    end

    function Window:Notify(title, message, duration, notifType)
        Notify(title, message, duration, notifType)
    end

    function Window:Destroy()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end

    -- ═══════════════════════════════════════
    -- CreateCategory
    -- ═══════════════════════════════════════

    function Window:CreateCategory(config)
        config = config or {}

        local catData = {
            Name  = config.Name or "Category",
            Icon  = config.Icon or "⚡",
            Order = config.Order or (#self.Categories + 1),
        }

        -- Category按钮
        catData.Button = Create("TextButton", {
            Name = "Cat_" .. catData.Name,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Colors.BG_Elevated,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = catData.Order,
            Parent = self.CategoryList,
        })
        Corner(catData.Button, 7)

        -- 左侧活跃指示条
        catData.Indicator = Create("Frame", {
            Position = UDim2.new(0, 0, 0.15, 0),
            Size = UDim2.new(0, 3, 0.7, 0),
            BackgroundColor3 = Colors.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = catData.Button,
        })
        Corner(catData.Indicator, 2)

        -- 图标
        catData.IconLabel = Create("TextLabel", {
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 22, 1, 0),
            BackgroundTransparency = 1,
            Text = catData.Icon,
            TextColor3 = Colors.Text_Tertiary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            Parent = catData.Button,
        })

        -- 名称
        catData.Label = Create("TextLabel", {
            Position = UDim2.new(0, 38, 0, 0),
            Size = UDim2.new(1, -46, 1, 0),
            BackgroundTransparency = 1,
            Text = catData.Name,
            TextColor3 = Colors.Text_Secondary,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = catData.Button,
        })

        -- Hover
        catData.Button.MouseEnter:Connect(function()
            if self.ActiveCategory ~= catData then
                Tween(catData.Button, {BackgroundTransparency = 0.7}, Anim.Fast)
            end
        end)
        catData.Button.MouseLeave:Connect(function()
            if self.ActiveCategory ~= catData then
                Tween(catData.Button, {BackgroundTransparency = 1}, Anim.Fast)
            end
        end)

        -- 点击切换
        catData.Button.MouseButton1Click:Connect(function()
            self:SwitchCategory(catData)
        end)

        table.insert(self.Categories, catData)

        -- ═══════════════════════════════════════
        -- Category对象方法
        -- ═══════════════════════════════════════

        local Category = {}
        Category._data = catData
        Category._window = self

        -- 创建模块（核心：Vape V4的悬浮模块按钮）
        function Category:CreateModule(moduleConfig)
            moduleConfig = moduleConfig or {}

            local moduleData = {
                Name        = moduleConfig.Name or "Module",
                Description = moduleConfig.Description or "",
                Category    = catData.Name,
                Enabled     = moduleConfig.Default or false,
                Callback    = moduleConfig.Callback or function() end,
                Settings    = {},
                Card        = nil,
                SettingsBuilder = nil,
            }

            -- 模块卡片Grid容器
            -- 先检查有没有这个category对应的grid frame
            local gridFrame = self._window.ModuleGrid:FindFirstChild("Grid_" .. catData.Name)
            if not gridFrame then
                gridFrame = Create("Frame", {
                    Name = "Grid_" .. catData.Name,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible = (self._window.ActiveCategory == catData),
                    Parent = self._window.ModuleGrid,
                })

                local grid = Create("UIGridLayout", {
                    CellSize = UDim2.new(0, 140, 0, 56),
                    CellPadding = UDim2.new(0, 8, 0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    Parent = gridFrame,
                })
            end

            -- 模块卡片
            local card = Create("Frame", {
                Name = "Module_" .. moduleData.Name,
                BackgroundColor3 = moduleData.Enabled and Colors.Module_On or Colors.Module_Off,
                LayoutOrder = #self._window.Modules + 1,
                Parent = gridFrame,
            })
            Corner(card, 10)
            Stroke(card, moduleData.Enabled and Colors.AccentLight or Colors.Divider, 1,
                   moduleData.Enabled and 0.4 or 0.7)

            -- 模块名称
            local moduleLabel = Create("TextLabel", {
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -44, 0, 18),
                BackgroundTransparency = 1,
                Text = moduleData.Name,
                TextColor3 = Colors.Text_Primary,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = card,
            })

            -- 描述
            if moduleData.Description ~= "" then
                Create("TextLabel", {
                    Position = UDim2.new(0, 12, 0, 28),
                    Size = UDim2.new(1, -44, 0, 20),
                    BackgroundTransparency = 1,
                    Text = moduleData.Description,
                    TextColor3 = moduleData.Enabled and
                        Color3.fromRGB(220, 220, 240) or Colors.Text_Tertiary,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = card,
                })
            end

            -- 设置齿轮按钮（右上角）
            local gearBtn = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -6, 0, 6),
                Size = UDim2.new(0, 24, 0, 24),
                BackgroundColor3 = Colors.BG_Tertiary,
                BackgroundTransparency = 0.6,
                Text = "⚙",
                TextColor3 = Colors.Text_Tertiary,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                ZIndex = 3,
                Parent = card,
            })
            Corner(gearBtn, 6)

            gearBtn.MouseEnter:Connect(function()
                Tween(gearBtn, {BackgroundTransparency = 0, TextColor3 = Colors.Accent}, Anim.Fast)
            end)
            gearBtn.MouseLeave:Connect(function()
                Tween(gearBtn, {BackgroundTransparency = 0.6, TextColor3 = Colors.Text_Tertiary}, Anim.Fast)
            end)

            -- 点击齿轮 -> 打开设置面板
            gearBtn.MouseButton1Click:Connect(function()
                if self._window.ActiveSettingsPanel == moduleData.Name then
                    self._window:CloseSettings()
                else
                    self._window:OpenSettings(moduleData)
                end
            end)

            -- 底部小状态条
            local statusBar = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -4),
                Size = UDim2.new(0.7, 0, 0, 3),
                BackgroundColor3 = moduleData.Enabled and Colors.AccentLight or Colors.Divider,
                BackgroundTransparency = moduleData.Enabled and 0 or 0.5,
                BorderSizePixel = 0,
                Parent = card,
            })
            Corner(statusBar, 2)

            moduleData.Card = card
            moduleData.StatusBar = statusBar
            moduleData.GearBtn = gearBtn
            moduleData.DescLabel = card:FindFirstChild("") -- 用于后续更新颜色

            -- 主点击区域（开关模块）
            local clickBtn = Create("TextButton", {
                Size = UDim2.new(1, -32, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2,
                Parent = card,
            })

            local function refreshCard()
                local strokeObj = card:FindFirstChildOfClass("UIStroke")
                if moduleData.Enabled then
                    Tween(card, {BackgroundColor3 = Colors.Module_On}, Anim.Normal)
                    if strokeObj then
                        Tween(strokeObj, {Color = Colors.AccentLight, Transparency = 0.4}, Anim.Normal)
                    end
                    Tween(statusBar, {
                        BackgroundColor3 = Colors.AccentLight,
                        BackgroundTransparency = 0,
                        Size = UDim2.new(0.7, 0, 0, 3),
                    }, Anim.Bounce)

                    -- HUD添加
                    HUD_AddModule(moduleData.Name)

                    -- 更新描述文字颜色
                    for _, child in ipairs(card:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= moduleLabel then
                            Tween(child, {TextColor3 = Color3.fromRGB(220, 220, 240)}, Anim.Fast)
                        end
                    end
                else
                    Tween(card, {BackgroundColor3 = Colors.Module_Off}, Anim.Normal)
                    if strokeObj then
                        Tween(strokeObj, {Color = Colors.Divider, Transparency = 0.7}, Anim.Normal)
                    end
                    Tween(statusBar, {
                        BackgroundColor3 = Colors.Divider,
                        BackgroundTransparency = 0.5,
                        Size = UDim2.new(0.3, 0, 0, 3),
                    }, Anim.Normal)

                    -- HUD移除
                    HUD_RemoveModule(moduleData.Name)

                    for _, child in ipairs(card:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= moduleLabel then
                            Tween(child, {TextColor3 = Colors.Text_Tertiary}, Anim.Fast)
                        end
                    end
                end

                moduleData.Callback(moduleData.Enabled)
            end

            -- Hover
            clickBtn.MouseEnter:Connect(function()
                if not moduleData.Enabled then
                    Tween(card, {BackgroundColor3 = Colors.Module_Hover}, Anim.Fast)
                end
            end)
            clickBtn.MouseLeave:Connect(function()
                if not moduleData.Enabled then
                    Tween(card, {BackgroundColor3 = Colors.Module_Off}, Anim.Fast)
                end
            end)

            -- 左键点击开关
            clickBtn.MouseButton1Click:Connect(function()
                moduleData.Enabled = not moduleData.Enabled
                refreshCard()
            end)

            -- 如果默认开启
            if moduleData.Enabled then
                task.defer(function()
                    refreshCard()
                end)
            end

            -- 储存
            table.insert(self._window.Modules, moduleData)

            -- ═══════════════════════════════════════
            -- Module 对象方法
            -- ═══════════════════════════════════════

            local Module = {}
            Module._data = moduleData
            Module._window = self._window
            Module._settingsElements = {}

            -- 设置面板构建函数
            local settingsBuildFns = {}

            -- 注册设置面板中的组件
            function Module:AddToggle(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Toggle(container, cfg)
                end)
                return self
            end

            function Module:AddSlider(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Slider(container, cfg)
                end)
                return self
            end

            function Module:AddDropdown(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Dropdown(container, cfg)
                end)
                return self
            end

            function Module:AddButton(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Button(container, cfg)
                end)
                return self
            end

            function Module:AddTextbox(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Textbox(container, cfg)
                end)
                return self
            end

            function Module:AddKeybind(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Keybind(container, cfg)
                end)
                return self
            end

            function Module:AddLabel(cfg)
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Label(container, cfg)
                end)
                return self
            end

            function Module:AddDivider()
                table.insert(settingsBuildFns, function(container)
                    return SettingsBuilder.Divider(container)
                end)
                return self
            end

            function Module:SetEnabled(val)
                moduleData.Enabled = val
                refreshCard()
            end

            function Module:IsEnabled()
                return moduleData.Enabled
            end

            -- 构建设置面板的函数
            moduleData.SettingsBuilder = function(container)
                self._settingsElements = {}
                for _, buildFn in ipairs(settingsBuildFns) do
                    local control = buildFn(container)
                    if control then
                        table.insert(self._settingsElements, control)
                    end
                end
            end

            return Module
        end

        -- 第一个Category自动选中
        if #self._window.Categories == 1 then
            self._window:SwitchCategory(catData)
        end

        return Category
    end

    -- ═══════════════════════════════════════
    -- 入场动画
    -- ═══════════════════════════════════════

    Window.MainFrame.Size = UDim2.new(0, 620, 0, 0)
    Window.MainFrame.BackgroundTransparency = 0.8

    task.defer(function()
        task.wait(0.05)
        Tween(Window.MainFrame, {
            Size = UDim2.new(0, 620, 0, 420),
            BackgroundTransparency = 0,
        }, Anim.Bounce)
    end)

    return Window
end

-- ══════════════════════════════════════════════
-- 返回
-- ══════════════════════════════════════════════

return VapeLib
