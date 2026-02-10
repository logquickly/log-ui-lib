-- ═══════════════════════════════════════════════════════════════
-- Console Module for Vape V4 UI Library
-- 捕获 Roblox 输出 + Delta API 输入/输出 + 搜索过滤
-- ═══════════════════════════════════════════════════════════════

-- 在你的示例脚本底部（Settings category之后）添加以下代码：

-- ═══════════════════════════════════════════════════════════════
-- CONSOLE CATEGORY
-- ═══════════════════════════════════════════════════════════════

local Console = Window:CreateCategory({
    Name = "Console",
    Icon = "📋",
    Order = 7,
})

-- ═══════════════════════════════════════════════════════════════
-- Console 核心实现
-- 因为控制台不是普通的"模块卡片"，我们需要自定义构建
-- ═══════════════════════════════════════════════════════════════

do
    local LogService = game:GetService("LogService")
    local ScriptContext = game:GetService("ScriptContext")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- ═══ 控制台状态 ═══
    local ConsoleState = {
        Logs = {},               -- 所有日志条目
        MaxLogs = 500,           -- 最大日志数
        AutoScroll = true,       -- 自动滚动到底部
        ShowOutput = true,       -- 显示普通输出
        ShowWarnings = true,     -- 显示警告
        ShowErrors = true,       -- 显示错误
        ShowInfo = true,         -- 显示信息
        SearchQuery = "",        -- 搜索关键词
        CommandHistory = {},     -- 命令历史
        HistoryIndex = 0,        -- 历史导航索引
        IsOpen = false,          -- 控制台面板是否打开
        Paused = false,          -- 暂停日志捕获
    }

    -- ═══ 颜色定义 ═══
    local LogColors = {
        Output   = Color3.fromRGB(220, 220, 235),    -- 白色 - print
        Info     = Color3.fromRGB(100, 180, 255),     -- 蓝色 - info
        Warning  = Color3.fromRGB(255, 200, 60),      -- 黄色 - warn
        Error    = Color3.fromRGB(255, 75, 75),        -- 红色 - error
        Input    = Color3.fromRGB(137, 100, 255),      -- 紫色 - 用户输入
        System   = Color3.fromRGB(80, 220, 150),       -- 绿色 - 系统消息
        Stack    = Color3.fromRGB(180, 120, 120),      -- 暗红 - 堆栈跟踪
        Timestamp = Color3.fromRGB(90, 90, 120),       -- 灰色 - 时间戳
    }

    local BG = {
        Primary   = Color3.fromRGB(12, 12, 18),
        Secondary = Color3.fromRGB(18, 18, 28),
        Tertiary  = Color3.fromRGB(26, 26, 38),
        Elevated  = Color3.fromRGB(34, 34, 50),
        Input     = Color3.fromRGB(16, 16, 24),
        Accent    = Color3.fromRGB(137, 100, 255),
        Divider   = Color3.fromRGB(45, 45, 65),
        Text      = Color3.fromRGB(200, 200, 220),
        TextDim   = Color3.fromRGB(100, 100, 130),
    }

    local AnimFast = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local AnimNormal = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local AnimBounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local function QuickTween(obj, props, info)
        if not obj or not obj.Parent then return end
        local t = TweenService:Create(obj, info or AnimNormal, props)
        t:Play()
        return t
    end

    local function Make(class, props)
        local obj = Instance.new(class)
        if props then
            for k, v in pairs(props) do
                if k ~= "Parent" and k ~= "Children" then
                    pcall(function() obj[k] = v end)
                end
            end
            if props.Children then
                for _, c in ipairs(props.Children) do
                    c.Parent = obj
                end
            end
            if props.Parent then
                obj.Parent = props.Parent
            end
        end
        return obj
    end

    local function AddCorner(p, r)
        return Make("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p })
    end

    local function AddStroke(p, c, t, tr)
        return Make("UIStroke", {
            Color = c or BG.Divider,
            Thickness = t or 1,
            Transparency = tr or 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = p,
        })
    end

    -- ═══════════════════════════════════════════════════════════
    -- 获取当前时间戳
    -- ═══════════════════════════════════════════════════════════

    local function GetTimestamp()
        local now = os.clock()
        local hours = math.floor(now / 3600) % 24
        local minutes = math.floor(now / 60) % 60
        local seconds = math.floor(now) % 60
        local millis = math.floor((now % 1) * 100)
        return string.format("%02d:%02d:%02d.%02d", hours, minutes, seconds, millis)
    end

    -- ═══════════════════════════════════════════════════════════
    -- 分类日志类型
    -- ═══════════════════════════════════════════════════════════

    local function ClassifyMessageType(message, messageType)
        -- Roblox MessageType enum
        if messageType == Enum.MessageType.MessageOutput then
            return "Output"
        elseif messageType == Enum.MessageType.MessageInfo then
            return "Info"
        elseif messageType == Enum.MessageType.MessageWarning then
            return "Warning"
        elseif messageType == Enum.MessageType.MessageError then
            return "Error"
        end

        -- 基于内容的额外分类
        local lower = string.lower(message)
        if string.find(lower, "stack begin") or string.find(lower, "stack end") or
           string.find(lower, "script '") then
            return "Stack"
        end

        return "Output"
    end

    -- ═══════════════════════════════════════════════════════════
    -- 获取日志类型的图标
    -- ═══════════════════════════════════════════════════════════

    local function GetLogIcon(logType)
        if logType == "Output" then return "›" end
        if logType == "Info" then return "ℹ" end
        if logType == "Warning" then return "⚠" end
        if logType == "Error" then return "✕" end
        if logType == "Input" then return "»" end
        if logType == "System" then return "★" end
        if logType == "Stack" then return "│" end
        return "›"
    end

    local function GetLogColor(logType)
        return LogColors[logType] or LogColors.Output
    end

    -- ═══════════════════════════════════════════════════════════
    -- 判断日志是否应该显示
    -- ═══════════════════════════════════════════════════════════

    local function ShouldShowLog(entry)
        -- 类型过滤
        if entry.Type == "Output" and not ConsoleState.ShowOutput then return false end
        if entry.Type == "Warning" and not ConsoleState.ShowWarnings then return false end
        if entry.Type == "Error" and not ConsoleState.ShowErrors then return false end
        if entry.Type == "Stack" and not ConsoleState.ShowErrors then return false end
        if entry.Type == "Info" and not ConsoleState.ShowInfo then return false end

        -- 搜索过滤
        if ConsoleState.SearchQuery ~= "" then
            local query = string.lower(ConsoleState.SearchQuery)
            local msg = string.lower(entry.Message)
            if not string.find(msg, query, 1, true) then
                return false
            end
        end

        return true
    end

    -- ═══════════════════════════════════════════════════════════
    -- 创建控制台面板
    -- 这是一个自定义的全屏面板，不是普通的模块卡片
    -- ═══════════════════════════════════════════════════════════

    -- 先创建一个触发模块
    local ConsoleModule = Console:CreateModule({
        Name = "Console",
        Description = "Output & script console",
        Default = false,
        Callback = function(enabled)
            ConsoleState.IsOpen = enabled
            if ConsolePanel then
                if enabled then
                    ConsolePanel.Visible = true
                    QuickTween(ConsolePanel, {
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        BackgroundTransparency = 0,
                    }, AnimBounce)
                else
                    QuickTween(ConsolePanel, {
                        Position = UDim2.new(0.5, 0, 1.5, 0),
                        BackgroundTransparency = 0.5,
                    }, AnimNormal)
                    task.delay(0.25, function()
                        if not ConsoleState.IsOpen and ConsolePanel then
                            ConsolePanel.Visible = false
                        end
                    end)
                end
            end
        end,
    })

    ConsoleModule
        :AddLabel({ Text = "Filters" })
        :AddToggle({
            Name = "Show Output",
            Default = true,
            Callback = function(val)
                ConsoleState.ShowOutput = val
                if RefreshConsoleDisplay then RefreshConsoleDisplay() end
            end,
        })
        :AddToggle({
            Name = "Show Warnings",
            Default = true,
            Callback = function(val)
                ConsoleState.ShowWarnings = val
                if RefreshConsoleDisplay then RefreshConsoleDisplay() end
            end,
        })
        :AddToggle({
            Name = "Show Errors",
            Default = true,
            Callback = function(val)
                ConsoleState.ShowErrors = val
                if RefreshConsoleDisplay then RefreshConsoleDisplay() end
            end,
        })
        :AddToggle({
            Name = "Show Info",
            Default = true,
            Callback = function(val)
                ConsoleState.ShowInfo = val
                if RefreshConsoleDisplay then RefreshConsoleDisplay() end
            end,
        })
        :AddDivider()
        :AddLabel({ Text = "Options" })
        :AddToggle({
            Name = "Auto Scroll",
            Default = true,
            Callback = function(val)
                ConsoleState.AutoScroll = val
            end,
        })
        :AddToggle({
            Name = "Pause Logging",
            Default = false,
            Callback = function(val)
                ConsoleState.Paused = val
                if val then
                    Window:Notify("Console", "Logging paused", 2, "warning")
                else
                    Window:Notify("Console", "Logging resumed", 2, "success")
                end
            end,
        })
        :AddSlider({
            Name = "Max Logs",
            Min = 50,
            Max = 2000,
            Default = 500,
            Increment = 50,
            Callback = function(val)
                ConsoleState.MaxLogs = val
            end,
        })
        :AddDivider()
        :AddLabel({ Text = "Actions" })
        :AddButton({
            Name = "Clear Console",
            Callback = function()
                ConsoleState.Logs = {}
                if RefreshConsoleDisplay then RefreshConsoleDisplay() end
                Window:Notify("Console", "Console cleared", 1.5)
            end,
        })
        :AddButton({
            Name = "Copy All Logs",
            Callback = function()
                local text = ""
                for _, entry in ipairs(ConsoleState.Logs) do
                    text = text .. string.format("[%s] [%s] %s\n", entry.Timestamp, entry.Type, entry.Message)
                end
                pcall(function()
                    if setclipboard then
                        setclipboard(text)
                        Window:Notify("Console", "Copied " .. #ConsoleState.Logs .. " log entries", 2, "success")
                    else
                        Window:Notify("Console", "Clipboard not available", 2, "error")
                    end
                end)
            end,
        })
        :AddButton({
            Name = "Copy Errors Only",
            Callback = function()
                local text = ""
                local count = 0
                for _, entry in ipairs(ConsoleState.Logs) do
                    if entry.Type == "Error" or entry.Type == "Stack" then
                        text = text .. string.format("[%s] %s\n", entry.Timestamp, entry.Message)
                        count = count + 1
                    end
                end
                pcall(function()
                    if setclipboard then
                        setclipboard(text)
                        Window:Notify("Console", "Copied " .. count .. " error entries", 2, "success")
                    end
                end)
            end,
        })

    -- ═══════════════════════════════════════════════════════════
    -- 构建控制台面板 UI
    -- ═══════════════════════════════════════════════════════════

    -- 主面板（独立浮动窗口）
    ConsolePanel = Make("Frame", {
        Name = "ConsolePanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1.5, 0),  -- 初始在屏幕外
        Size = UDim2.new(0, 720, 0, 440),
        BackgroundColor3 = BG.Primary,
        Visible = false,
        ZIndex = 10,
        Parent = Window.ScreenGui,
    })
    AddCorner(ConsolePanel, 12)
    AddStroke(ConsolePanel, BG.Accent, 1, 0.65)

    -- ─── 标题栏 ──────────────────────────────────────────────

    local titleBar = Make("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = BG.Secondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })
    AddCorner(titleBar, 12)

    -- 修复圆角底部（让底部是直角）
    Make("Frame", {
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = BG.Secondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = titleBar,
    })

    -- 标题
    Make("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        BackgroundTransparency = 1,
        Text = "📋",
        TextSize = 14,
        Font = Enum.Font.Gotham,
        ZIndex = 12,
        Parent = titleBar,
    })

    Make("TextLabel", {
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Text = "Console",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = titleBar,
    })

    -- 日志计数器
    local logCounter = Make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 200, 0, 20),
        BackgroundTransparency = 1,
        Text = "0 entries",
        TextColor3 = BG.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ZIndex = 12,
        Parent = titleBar,
    })

    -- ─── 统计标签（错误/警告/输出计数）──────────────────────

    local function MakeCountBadge(parent, posX, color, icon, initialCount)
        local badge = Make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, posX, 0.5, 0),
            Size = UDim2.new(0, 55, 0, 22),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.85,
            ZIndex = 12,
            Parent = parent,
        })
        AddCorner(badge, 5)

        local label = Make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = icon .. " " .. tostring(initialCount),
            TextColor3 = color,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            ZIndex = 13,
            Parent = badge,
        })

        return label
    end

    local errorCount = MakeCountBadge(titleBar, 260, LogColors.Error, "✕", 0)
    local warnCount = MakeCountBadge(titleBar, 320, LogColors.Warning, "⚠", 0)
    local outputCount = MakeCountBadge(titleBar, 380, LogColors.Output, "›", 0)

    -- ─── 标题栏按钮 ──────────────────────────────────────────

    -- 清除按钮
    local clearBtn = Make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -76, 0.5, 0),
        Size = UDim2.new(0, 55, 0, 24),
        BackgroundColor3 = BG.Elevated,
        BackgroundTransparency = 0.3,
        Text = "Clear",
        TextColor3 = BG.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = titleBar,
    })
    AddCorner(clearBtn, 5)

    clearBtn.MouseEnter:Connect(function()
        QuickTween(clearBtn, { BackgroundTransparency = 0 }, AnimFast)
    end)
    clearBtn.MouseLeave:Connect(function()
        QuickTween(clearBtn, { BackgroundTransparency = 0.3 }, AnimFast)
    end)
    clearBtn.MouseButton1Click:Connect(function()
        ConsoleState.Logs = {}
        if RefreshConsoleDisplay then RefreshConsoleDisplay() end
    end)

    -- 暂停/继续按钮
    local pauseBtn = Make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -136, 0.5, 0),
        Size = UDim2.new(0, 55, 0, 24),
        BackgroundColor3 = BG.Elevated,
        BackgroundTransparency = 0.3,
        Text = "Pause",
        TextColor3 = BG.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = titleBar,
    })
    AddCorner(pauseBtn, 5)

    pauseBtn.MouseEnter:Connect(function()
        QuickTween(pauseBtn, { BackgroundTransparency = 0 }, AnimFast)
    end)
    pauseBtn.MouseLeave:Connect(function()
        QuickTween(pauseBtn, { BackgroundTransparency = 0.3 }, AnimFast)
    end)
    pauseBtn.MouseButton1Click:Connect(function()
        ConsoleState.Paused = not ConsoleState.Paused
        pauseBtn.Text = ConsoleState.Paused and "Resume" or "Pause"
        QuickTween(pauseBtn, {
            BackgroundColor3 = ConsoleState.Paused and LogColors.Warning or BG.Elevated,
        }, AnimFast)
    end)

    -- 关闭按钮
    local closeBtn = Make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = BG.Elevated,
        BackgroundTransparency = 0.5,
        Text = "×",
        TextColor3 = BG.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = titleBar,
    })
    AddCorner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function()
        QuickTween(closeBtn, {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(220, 60, 60),
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }, AnimFast)
    end)
    closeBtn.MouseLeave:Connect(function()
        QuickTween(closeBtn, {
            BackgroundTransparency = 0.5,
            BackgroundColor3 = BG.Elevated,
            TextColor3 = BG.Text,
        }, AnimFast)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        ConsoleState.IsOpen = false
        ConsoleModule:SetEnabled(false)
        QuickTween(ConsolePanel, {
            Position = UDim2.new(0.5, 0, 1.5, 0),
        }, AnimNormal)
        task.delay(0.25, function()
            if not ConsoleState.IsOpen then
                ConsolePanel.Visible = false
            end
        end)
    end)

    -- ─── 分隔线 ──────────────────────────────────────────────

    Make("Frame", {
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = BG.Divider,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })

    -- ─── 搜索 + 过滤栏 ──────────────────────────────────────

    local filterBar = Make("Frame", {
        Position = UDim2.new(0, 0, 0, 39),
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = BG.Secondary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })

    -- 搜索框
    local searchBG = Make("Frame", {
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0, 250, 0, 24),
        BackgroundColor3 = BG.Input,
        ZIndex = 12,
        Parent = filterBar,
    })
    AddCorner(searchBG, 5)
    AddStroke(searchBG, BG.Divider, 1, 0.6)

    Make("TextLabel", {
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextSize = 10,
        TextColor3 = BG.TextDim,
        Font = Enum.Font.Gotham,
        ZIndex = 13,
        Parent = searchBG,
    })

    local searchInput = Make("TextBox", {
        Position = UDim2.new(0, 24, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search logs...",
        PlaceholderColor3 = BG.TextDim,
        TextColor3 = BG.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 13,
        Parent = searchBG,
    })

    searchInput.Focused:Connect(function()
        local stroke = searchBG:FindFirstChildOfClass("UIStroke")
        if stroke then
            QuickTween(stroke, { Color = BG.Accent, Transparency = 0.2 }, AnimFast)
        end
    end)

    searchInput.FocusLost:Connect(function()
        local stroke = searchBG:FindFirstChildOfClass("UIStroke")
        if stroke then
            QuickTween(stroke, { Color = BG.Divider, Transparency = 0.6 }, AnimFast)
        end
    end)

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        ConsoleState.SearchQuery = searchInput.Text
        if RefreshConsoleDisplay then RefreshConsoleDisplay() end
    end)

    -- 快速过滤按钮
    local function MakeFilterBtn(parent, posX, text, color, default, stateKey)
        local active = default

        local btn = Make("TextButton", {
            Position = UDim2.new(0, posX, 0, 5),
            Size = UDim2.new(0, 50, 0, 24),
            BackgroundColor3 = color,
            BackgroundTransparency = active and 0.7 or 0.92,
            Text = text,
            TextColor3 = active and color or BG.TextDim,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            ZIndex = 12,
            Parent = parent,
        })
        AddCorner(btn, 5)

        btn.MouseButton1Click:Connect(function()
            active = not active
            ConsoleState[stateKey] = active

            QuickTween(btn, {
                BackgroundTransparency = active and 0.7 or 0.92,
                TextColor3 = active and color or BG.TextDim,
            }, AnimFast)

            if RefreshConsoleDisplay then RefreshConsoleDisplay() end
        end)

        return btn
    end

    MakeFilterBtn(filterBar, 280, "Output", LogColors.Output, true, "ShowOutput")
    MakeFilterBtn(filterBar, 336, "Warn", LogColors.Warning, true, "ShowWarnings")
    MakeFilterBtn(filterBar, 392, "Error", LogColors.Error, true, "ShowErrors")
    MakeFilterBtn(filterBar, 448, "Info", LogColors.Info, true, "ShowInfo")

    -- Auto scroll toggle
    local autoScrollBtn = Make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 5),
        Size = UDim2.new(0, 75, 0, 24),
        BackgroundColor3 = BG.Accent,
        BackgroundTransparency = 0.7,
        Text = "Auto Scroll",
        TextColor3 = BG.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = filterBar,
    })
    AddCorner(autoScrollBtn, 5)

    autoScrollBtn.MouseButton1Click:Connect(function()
        ConsoleState.AutoScroll = not ConsoleState.AutoScroll
        QuickTween(autoScrollBtn, {
            BackgroundTransparency = ConsoleState.AutoScroll and 0.7 or 0.92,
            TextColor3 = ConsoleState.AutoScroll and BG.Accent or BG.TextDim,
        }, AnimFast)
    end)

    -- 分隔线
    Make("Frame", {
        Position = UDim2.new(0, 0, 0, 73),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = BG.Divider,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })

    -- ─── 日志显示区域 ────────────────────────────────────────

    local logContainer = Make("ScrollingFrame", {
        Name = "LogContainer",
        Position = UDim2.new(0, 0, 0, 74),
        Size = UDim2.new(1, 0, 1, -114),  -- 留出底部输入栏空间
        BackgroundColor3 = BG.Primary,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = BG.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 10,
        Parent = ConsolePanel,
    })

    Make("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = logContainer,
    })

    Make("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = logContainer,
    })

    -- ─── 底部分隔线 ──────────────────────────────────────────

    Make("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -40),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = BG.Divider,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })

    -- ─── 输入栏（执行脚本）──────────────────────────────────

    local inputBar = Make("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = BG.Secondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = ConsolePanel,
    })
    AddCorner(inputBar, 12)

    -- 底部圆角修复
    Make("Frame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = BG.Secondary,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = inputBar,
    })

    -- 输入提示符
    Make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        BackgroundTransparency = 1,
        Text = "»",
        TextColor3 = BG.Accent,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        ZIndex = 12,
        Parent = inputBar,
    })

    local commandInput = Make("TextBox", {
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Execute Lua code... (Enter to run)",
        PlaceholderColor3 = BG.TextDim,
        TextColor3 = Color3.fromRGB(200, 220, 255),
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 12,
        Parent = inputBar,
    })

    -- 执行按钮
    local execBtn = Make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 52, 0, 26),
        BackgroundColor3 = BG.Accent,
        BackgroundTransparency = 0.15,
        Text = "Run",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 12,
        Parent = inputBar,
    })
    AddCorner(execBtn, 6)

    execBtn.MouseEnter:Connect(function()
        QuickTween(execBtn, { BackgroundTransparency = 0, Size = UDim2.new(0, 56, 0, 28) }, AnimFast)
    end)
    execBtn.MouseLeave:Connect(function()
        QuickTween(execBtn, { BackgroundTransparency = 0.15, Size = UDim2.new(0, 52, 0, 26) }, AnimFast)
    end)

    -- ─── 拖拽控制台面板 ──────────────────────────────────────

    do
        local dragging = false
        local dragStart, startPos

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = ConsolePanel.Position
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
                QuickTween(ConsolePanel, {
                    Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    ),
                }, AnimFast)
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    -- 日志条目创建
    -- ═══════════════════════════════════════════════════════════

    local logEntryPool = {}  -- 对象池，减少创建开销
    local activeEntries = {}

    local function CreateLogEntry(entry, layoutOrder)
        local icon = GetLogIcon(entry.Type)
        local color = GetLogColor(entry.Type)
        local isStack = (entry.Type == "Stack")
        local isError = (entry.Type == "Error")
        local isInput = (entry.Type == "Input")

        -- 计算文本需要的行数
        local textWidth = logContainer.AbsoluteSize.X - 100
        if textWidth < 100 then textWidth = 500 end

        local bounds = nil
        pcall(function()
            bounds = game:GetService("TextService"):GetTextSize(
                entry.Message,
                11,
                Enum.Font.Code,
                Vector2.new(textWidth, 10000)
            )
        end)

        local textHeight = bounds and bounds.Y or 14
        local rowHeight = math.max(18, textHeight + 6)

        local row = Make("Frame", {
            Name = "Log_" .. layoutOrder,
            Size = UDim2.new(1, 0, 0, rowHeight),
            BackgroundColor3 = isError and Color3.fromRGB(40, 18, 18) or
                               isStack and Color3.fromRGB(35, 20, 20) or
                               isInput and Color3.fromRGB(25, 20, 40) or
                               (layoutOrder % 2 == 0 and BG.Primary or Color3.fromRGB(15, 15, 22)),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            LayoutOrder = layoutOrder,
            ZIndex = 10,
            ClipsDescendants = true,
            Parent = logContainer,
        })

        -- 左侧颜色条
        Make("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BackgroundTransparency = isStack and 0.6 or 0.2,
            BorderSizePixel = 0,
            ZIndex = 11,
            Parent = row,
        })

        -- 时间戳
        Make("TextLabel", {
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(0, 72, 0, rowHeight),
            BackgroundTransparency = 1,
            Text = entry.Timestamp,
            TextColor3 = LogColors.Timestamp,
            TextSize = 9,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
            Parent = row,
        })

        -- 类型图标
        Make("TextLabel", {
            Position = UDim2.new(0, 80, 0, 0),
            Size = UDim2.new(0, 14, 0, rowHeight),
            BackgroundTransparency = 1,
            Text = icon,
            TextColor3 = color,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            ZIndex = 11,
            Parent = row,
        })

        -- 消息文本
        local msgLabel = Make("TextLabel", {
            Position = UDim2.new(0, 98, 0, 3),
            Size = UDim2.new(1, -108, 0, rowHeight - 6),
            BackgroundTransparency = 1,
            Text = entry.Message,
            TextColor3 = color,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 11,
            Parent = row,
        })

        -- Hover效果
        local hoverBtn = Make("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 12,
            Parent = row,
        })

        hoverBtn.MouseEnter:Connect(function()
            QuickTween(row, { BackgroundTransparency = 0 }, AnimFast)
        end)
        hoverBtn.MouseLeave:Connect(function()
            QuickTween(row, { BackgroundTransparency = 0.1 }, AnimFast)
        end)

        -- 右键复制
        hoverBtn.MouseButton2Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(entry.Message)
                    Window:Notify("Console", "Copied to clipboard", 1.5, "success")
                end
            end)
        end)

        -- 入场动画
        row.BackgroundTransparency = 1
        msgLabel.TextTransparency = 1
        QuickTween(row, { BackgroundTransparency = 0.1 }, AnimFast)
        QuickTween(msgLabel, { TextTransparency = 0 }, AnimNormal)

        return row
    end

    -- ═══════════════════════════════════════════════════════════
    -- 刷新控制台显示
    -- ═══════════════════════════════════════════════════════════

    local isRefreshing = false

    function RefreshConsoleDisplay()
        if isRefreshing then return end
        isRefreshing = true

        -- 清空现有条目
        for _, child in ipairs(logContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        activeEntries = {}

        -- 更新计数
        local errC, warnC, outC = 0, 0, 0
        for _, entry in ipairs(ConsoleState.Logs) do
            if entry.Type == "Error" or entry.Type == "Stack" then errC = errC + 1 end
            if entry.Type == "Warning" then warnC = warnC + 1 end
            if entry.Type == "Output" or entry.Type == "Info" then outC = outC + 1 end
        end
        errorCount.Text = "✕ " .. errC
        warnCount.Text = "⚠ " .. warnC
        outputCount.Text = "› " .. outC

        -- 过滤并创建条目
        local visibleCount = 0
        for i, entry in ipairs(ConsoleState.Logs) do
            if ShouldShowLog(entry) then
                visibleCount = visibleCount + 1
                local row = CreateLogEntry(entry, visibleCount)
                table.insert(activeEntries, row)
            end
        end

        logCounter.Text = visibleCount .. " / " .. #ConsoleState.Logs .. " entries"

        -- 自动滚动
        if ConsoleState.AutoScroll then
            task.defer(function()
                task.wait(0.05)
                if logContainer and logContainer.Parent then
                    logContainer.CanvasPosition = Vector2.new(0, logContainer.AbsoluteCanvasSize.Y)
                end
            end)
        end

        isRefreshing = false
    end

    -- ═══════════════════════════════════════════════════════════
    -- 添加单条日志（增量更新，不全量刷新）
    -- ═══════════════════════════════════════════════════════════

    local function AddLogEntry(message, logType, skipRefresh)
        local entry = {
            Timestamp = GetTimestamp(),
            Message = message,
            Type = logType or "Output",
            Index = #ConsoleState.Logs + 1,
        }

        table.insert(ConsoleState.Logs, entry)

        -- 超出限制时移除最旧的
        while #ConsoleState.Logs > ConsoleState.MaxLogs do
            table.remove(ConsoleState.Logs, 1)
        end

        -- 更新计数
        local errC, warnC, outC = 0, 0, 0
        for _, e in ipairs(ConsoleState.Logs) do
            if e.Type == "Error" or e.Type == "Stack" then errC = errC + 1 end
            if e.Type == "Warning" then warnC = warnC + 1 end
            if e.Type == "Output" or e.Type == "Info" then outC = outC + 1 end
        end
        errorCount.Text = "✕ " .. errC
        warnCount.Text = "⚠ " .. warnC
        outputCount.Text = "› " .. outC
        logCounter.Text = #activeEntries .. " / " .. #ConsoleState.Logs .. " entries"

        -- 如果不应该显示，跳过
        if not ShouldShowLog(entry) then return end

        -- 增量添加（不全量刷新）
        if not skipRefresh and ConsolePanel.Visible then
            local row = CreateLogEntry(entry, #activeEntries + 1)
            table.insert(activeEntries, row)

            logCounter.Text = #activeEntries .. " / " .. #ConsoleState.Logs .. " entries"

            -- 如果活跃条目太多，移除最旧的可见条目
            if #activeEntries > ConsoleState.MaxLogs then
                local oldest = table.remove(activeEntries, 1)
                if oldest and oldest.Parent then
                    oldest:Destroy()
                end
            end

            -- 自动滚动
            if ConsoleState.AutoScroll then
                task.defer(function()
                    if logContainer and logContainer.Parent then
                        logContainer.CanvasPosition = Vector2.new(0, logContainer.AbsoluteCanvasSize.Y)
                    end
                end)
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- 执行脚本函数
    -- ═══════════════════════════════════════════════════════════

    local function ExecuteCode(code)
        if code == "" or code == nil then return end

        -- 记录到命令历史
        table.insert(ConsoleState.CommandHistory, code)
        ConsoleState.HistoryIndex = #ConsoleState.CommandHistory + 1

        -- 记录输入
        AddLogEntry(">> " .. code, "Input")

        -- 尝试执行
        local func, compileError = loadstring(code)
        if not func then
            AddLogEntry("Compile Error: " .. tostring(compileError), "Error")
            return
        end

        -- 捕获 print 输出
        local success, runtimeError = pcall(func)
        if not success then
            AddLogEntry("Runtime Error: " .. tostring(runtimeError), "Error")
        else
            AddLogEntry("Executed successfully", "System")
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- 输入栏事件
    -- ═══════════════════════════════════════════════════════════

    commandInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local code = commandInput.Text
            commandInput.Text = ""
            if code ~= "" then
                ExecuteCode(code)
            end
        end
    end)

    execBtn.MouseButton1Click:Connect(function()
        local code = commandInput.Text
        commandInput.Text = ""
        if code ~= "" then
            ExecuteCode(code)
        end
    end)

    -- 上下键导航命令历史
    UserInputService.InputBegan:Connect(function(input, processed)
        if not commandInput:IsFocused() then return end

        if input.KeyCode == Enum.KeyCode.Up then
            if #ConsoleState.CommandHistory > 0 then
                ConsoleState.HistoryIndex = math.max(1, ConsoleState.HistoryIndex - 1)
                commandInput.Text = ConsoleState.CommandHistory[ConsoleState.HistoryIndex] or ""
                commandInput.CursorPosition = #commandInput.Text + 1
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if ConsoleState.HistoryIndex < #ConsoleState.CommandHistory then
                ConsoleState.HistoryIndex = ConsoleState.HistoryIndex + 1
                commandInput.Text = ConsoleState.CommandHistory[ConsoleState.HistoryIndex] or ""
                commandInput.CursorPosition = #commandInput.Text + 1
            else
                ConsoleState.HistoryIndex = #ConsoleState.CommandHistory + 1
                commandInput.Text = ""
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════
    -- 钩入 Roblox LogService（核心：捕获所有输出）
    -- ═══════════════════════════════════════════════════════════

    -- 获取已有的历史日志
    pcall(function()
        local history = LogService:GetLogHistory()
        for _, logEntry in ipairs(history) do
            if not ConsoleState.Paused then
                local msgType = ClassifyMessageType(logEntry.message, logEntry.messageType)
                AddLogEntry(logEntry.message, msgType, true)
            end
        end
    end)

    -- 全量刷新一次
    task.defer(function()
        task.wait(0.1)
        RefreshConsoleDisplay()
    end)

    -- 监听新的日志输出
    pcall(function()
        LogService.MessageOut:Connect(function(message, messageType)
            if ConsoleState.Paused then return end
            local logType = ClassifyMessageType(message, messageType)
            AddLogEntry(message, logType)
        end)
    end)

    -- 备用：ScriptContext.Error 捕获脚本错误
    pcall(function()
        ScriptContext.Error:Connect(function(message, stackTrace, script)
            if ConsoleState.Paused then return end

            -- 避免重复（LogService可能已经捕获）
            local isDuplicate = false
            for i = math.max(1, #ConsoleState.Logs - 5), #ConsoleState.Logs do
                if ConsoleState.Logs[i] and ConsoleState.Logs[i].Message == message then
                    isDuplicate = true
                    break
                end
            end

            if not isDuplicate then
                AddLogEntry(message, "Error")
                if stackTrace and stackTrace ~= "" then
                    for line in string.gmatch(stackTrace, "[^\n]+") do
                        AddLogEntry(line, "Stack")
                    end
                end
            end
        end)
    end)

    -- ═══════════════════════════════════════════════════════════
    -- Delta API 集成（如果可用）
    -- ═══════════════════════════════════════════════════════════

    -- 检测Delta执行器环境
    local isDelta = false
    pcall(function()
        isDelta = (getexecutorname and string.lower(getexecutorname()) == "delta") or
                  (identifyexecutor and string.find(string.lower(identifyexecutor()), "delta")) or
                  (Delta ~= nil)
    end)

    if isDelta then
        AddLogEntry("Delta executor detected - Enhanced features enabled", "System")

        -- Delta特定API钩入
        pcall(function()
            -- rconsoleprint 钩入
            if rconsoleprint then
                local oldRConsolePrint = rconsoleprint
                rconsoleprint = function(msg)
                    AddLogEntry("[rconsole] " .. tostring(msg), "Output")
                    return oldRConsolePrint(msg)
                end
            end

            -- rconsolewarn
            if rconsolewarn then
                local oldWarn = rconsolewarn
                rconsolewarn = function(msg)
                    AddLogEntry("[rconsole] " .. tostring(msg), "Warning")
                    return oldWarn(msg)
                end
            end

            -- rconsoleerr
            if rconsoleerr then
                local oldErr = rconsoleerr
                rconsoleerr = function(msg)
                    AddLogEntry("[rconsole] " .. tostring(msg), "Error")
                    return oldErr(msg)
                end
            end

            -- rconsoleinfo
            if rconsoleinfo then
                local oldInfo = rconsoleinfo
                rconsoleinfo = function(msg)
                    AddLogEntry("[rconsole] " .. tostring(msg), "Info")
                    return oldInfo(msg)
                end
            end
        end)
    else
        -- 检测其他执行器
        local executorName = "Unknown"
        pcall(function()
            if identifyexecutor then
                executorName = identifyexecutor()
            elseif getexecutorname then
                executorName = getexecutorname()
            end
        end)
        AddLogEntry("Executor: " .. executorName, "System")
    end

    -- ═══════════════════════════════════════════════════════════
    -- 钩入全局 print/warn/error（捕获脚本内的输出）
    -- ═══════════════════════════════════════════════════════════

    -- 注意：这些会被LogService.MessageOut也捕获到
    -- 我们使用去重逻辑避免重复显示

    -- ═══════════════════════════════════════════════════════════
    -- 系统信息日志
    -- ═══════════════════════════════════════════════════════════

    AddLogEntry("═══════════════════════════════════════", "System")
    AddLogEntry("Vape V4 Console initialized", "System")
    AddLogEntry("Game: " .. tostring(game.PlaceId) .. " | JobId: " .. string.sub(game.JobId, 1, 8) .. "...", "System")
    AddLogEntry("Player: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")", "System")

    pcall(function()
        local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if gameInfo then
            AddLogEntry("Game Name: " .. (gameInfo.Name or "Unknown"), "System")
        end
    end)

    AddLogEntry("═══════════════════════════════════════", "System")
    AddLogEntry("Type Lua code below and press Enter to execute", "Info")
    AddLogEntry("Right-click any log entry to copy it", "Info")
    AddLogEntry("Use ↑↓ arrow keys to navigate command history", "Info")
    AddLogEntry("═══════════════════════════════════════", "System")

    -- 初始全量刷新
    task.defer(function()
        task.wait(0.2)
        RefreshConsoleDisplay()
    end)

    -- ═══════════════════════════════════════════════════════════
    -- Executor Console Module（第二个模块卡片 - 快速执行）
    -- ═══════════════════════════════════════════════════════════

    local ExecModule = Console:CreateModule({
        Name = "Quick Execute",
        Description = "Run scripts quickly",
        Default = true,
        Callback = function() end,
    })

    ExecModule
        :AddLabel({ Text = "Quick Scripts" })
        :AddButton({
            Name = "Print All Players",
            Callback = function()
                local code = [[
for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
    print(plr.Name .. " | " .. plr.DisplayName .. " | UserId: " .. plr.UserId)
end
]]
                ExecuteCode(code)
            end,
        })
        :AddButton({
            Name = "Print Workspace Children",
            Callback = function()
                local code = [[
for _, obj in ipairs(workspace:GetChildren()) do
    print(obj.ClassName .. ": " .. obj.Name)
end
]]
                ExecuteCode(code)
            end,
        })
        :AddButton({
            Name = "Print Character Info",
            Callback = function()
                local code = [[
local char = game.Players.LocalPlayer.Character
if char then
    for _, part in ipairs(char:GetChildren()) do
        print(part.ClassName .. ": " .. part.Name)
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        print("Health: " .. hum.Health .. "/" .. hum.MaxHealth)
        print("WalkSpeed: " .. hum.WalkSpeed)
        print("JumpPower: " .. hum.JumpPower)
    end
end
]]
                ExecuteCode(code)
            end,
        })
        :AddButton({
            Name = "Print RemoteEvents",
            Callback = function()
                local code = [[
local count = 0
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        print("[RemoteEvent] " .. obj:GetFullName())
        count = count + 1
    end
end
print("Total RemoteEvents: " .. count)
]]
                ExecuteCode(code)
            end,
        })
        :AddButton({
            Name = "Print Services",
            Callback = function()
                local code = [[
for _, service in ipairs(game:GetChildren()) do
    print("[Service] " .. service.ClassName .. " (" .. service.Name .. ")")
end
]]
                ExecuteCode(code)
            end,
        })
        :AddDivider()
        :AddLabel({ Text = "Custom Script" })
        :AddTextbox({
            Name = "Script URL",
            Placeholder = "https://raw.githubusercontent.com/...",
            Callback = function(text, enter)
                if enter and text ~= "" then
                    AddLogEntry("Loading script from URL: " .. text, "Info")
                    pcall(function()
                        local code = game:HttpGet(text)
                        if code and code ~= "" then
                            AddLogEntry("Script loaded (" .. #code .. " chars), executing...", "Info")
                            ExecuteCode(code)
                        else
                            AddLogEntry("Failed to load script - empty response", "Error")
                        end
                    end)
                end
            end,
        })

    -- ═══════════════════════════════════════════════════════════
    -- Log Monitor Module（第三个模块卡片 - 实时监控）
    -- ═══════════════════════════════════════════════════════════

    local MonitorModule = Console:CreateModule({
        Name = "Log Monitor",
        Description = "Monitor specific patterns",
        Default = false,
        Callback = function(enabled)
            if enabled then
                Window:Notify("Console", "Log Monitor enabled - watching for patterns", 2)
            end
        end,
    })

    local monitorPatterns = {}

    MonitorModule
        :AddLabel({ Text = "Watch Patterns" })
        :AddTextbox({
            Name = "Pattern 1",
            Placeholder = "e.g. error, kick, ban...",
            Callback = function(text)
                monitorPatterns[1] = text ~= "" and string.lower(text) or nil
            end,
        })
        :AddTextbox({
            Name = "Pattern 2",
            Placeholder = "e.g. teleport, remote...",
            Callback = function(text)
                monitorPatterns[2] = text ~= "" and string.lower(text) or nil
            end,
        })
        :AddTextbox({
            Name = "Pattern 3",
            Placeholder = "e.g. anticheat, detect...",
            Callback = function(text)
                monitorPatterns[3] = text ~= "" and string.lower(text) or nil
            end,
        })
        :AddDivider()
        :AddToggle({
            Name = "Alert on Match",
            Default = true,
            Description = "Show notification when pattern is found",
            Callback = function(val) end,
        })
        :AddToggle({
            Name = "Sound Alert",
            Default = false,
            Callback = function(val) end,
        })

    -- 在日志添加时检查监控模式
    local originalAddLog = AddLogEntry
    AddLogEntry = function(message, logType, skipRefresh)
        originalAddLog(message, logType, skipRefresh)

        -- 模式监控检查
        if MonitorModule:IsEnabled() and message then
            local lower = string.lower(message)
            for _, pattern in pairs(monitorPatterns) do
                if pattern and string.find(lower, pattern, 1, true) then
                    Window:Notify("⚠ Log Monitor",
                        "Pattern '" .. pattern .. "' detected:\n" .. string.sub(message, 1, 80),
                        4, "warning")
                    break
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- 完成通知
    -- ═══════════════════════════════════════════════════════════

    Window:Notify("Console", "Console module loaded. Click 'Console' module card to open.", 3, "success")

end -- do block 结束
