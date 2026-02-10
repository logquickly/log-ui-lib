## 示例代码（Example.lua）

```lua
--[[
    ╔══════════════════════════════════════════╗
    ║    Log UI Library - Complete Demo        ║
    ║    Demonstrates ALL available APIs       ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- 1. LOAD LIBRARY
-- ═══════════════════════════════════════════
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/log-ui-lib/refs/heads/main/main.lua"))()

-- ═══════════════════════════════════════════
-- 2. CREATE WINDOW
-- ═══════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Log UI Demo",                      -- 窗口标题
    Subtitle = "v1.0.0",                        -- 副标题
    Theme = "Vape Dark",                        -- 主题: "Vape Dark" / "Midnight Purple" / "Ocean Blue"
    Size = UDim2.new(0, 600, 0, 420),           -- 窗口大小
    Position = UDim2.new(0.5, -300, 0.5, -210), -- 窗口位置
    ToggleKey = Enum.KeyCode.RightShift,        -- 显示/隐藏快捷键
    SaveConfig = true,                          -- 启用配置保存
    ConfigFolder = "LogUIDemoConfigs"            -- 配置文件夹名
})

-- ═══════════════════════════════════════════
-- 3. NOTIFICATION SYSTEM (通知系统)
-- ═══════════════════════════════════════════

-- 成功通知
Library:Notify({
    Title = "Welcome!",
    Content = "Demo loaded successfully. Press RightShift to toggle.",
    Type = "Success",   -- "Success" / "Error" / "Warning" / "Info"
    Duration = 5        -- 秒数，悬停时暂停倒计时
})

-- ═══════════════════════════════════════════
-- 4. TAB: TOGGLES (开关演示)
-- ═══════════════════════════════════════════
local ToggleTab = Window:CreateTab({
    Name = "Toggles",
    Icon = "⚡",        -- 支持 emoji 或留空
    Order = 1           -- 排序顺序
})

-- Section: 基础开关
local basicSection = ToggleTab:CreateSection("Basic Toggles")

-- 基础 Toggle
local toggle1 = basicSection:AddToggle({
    Name = "Simple Toggle",
    Default = false,
    Flag = "SimpleToggle",          -- 用于配置保存的唯一标识
    Callback = function(value)
        print("[Toggle] Simple Toggle:", value)
    end
})

-- 带快捷键的 Toggle
local toggle2 = basicSection:AddToggle({
    Name = "Toggle with Keybind",
    Default = false,
    Flag = "KeybindToggle",
    Keybind = Enum.KeyCode.G,       -- 按 G 键切换
    Callback = function(value)
        print("[Toggle] Keybind Toggle:", value)
    end
})

-- Section: 带子选项的开关
local subSection = ToggleTab:CreateSection("Toggles with Sub-Options")

-- Toggle + 子组件（右键展开）
local advancedToggle = basicSection:AddToggle({
    Name = "Kill Aura (Right-Click to Expand)",
    Default = false,
    Flag = "KillAura",
    Callback = function(value)
        print("[Toggle] Kill Aura:", value)
    end
})

-- 子选项: Slider
advancedToggle:AddSlider({
    Name = "Range",
    Min = 1,
    Max = 20,
    Default = 4.5,
    Increment = 0.5,
    Suffix = " studs",
    Flag = "KillAuraRange",
    Callback = function(value)
        print("  [Sub-Slider] Range:", value)
    end
})

-- 子选项: Dropdown
advancedToggle:AddDropdown({
    Name = "Mode",
    Options = {"Switch", "Single", "Multi"},
    Default = "Switch",
    Flag = "KillAuraMode",
    Callback = function(option)
        print("  [Sub-Dropdown] Mode:", option)
    end
})

-- 子选项: Sub-Toggle
advancedToggle:AddToggle({
    Name = "Show Target",
    Default = true,
    Flag = "ShowTarget",
    Callback = function(value)
        print("  [Sub-Toggle] Show Target:", value)
    end
})

-- 子选项: Keybind
advancedToggle:AddKeybind({
    Name = "Activation Key",
    Default = Enum.KeyCode.R,
    Flag = "KillAuraKey",
    Callback = function(key)
        print("  [Sub-Keybind] Pressed:", key)
    end,
    ChangedCallback = function(newKey)
        print("  [Sub-Keybind] Changed to:", newKey)
    end
})

-- 子选项: ColorPicker
advancedToggle:AddColorPicker({
    Name = "Hit Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "HitColor",
    Callback = function(color)
        print("  [Sub-ColorPicker] Color:", color)
    end
})

-- ═══════════════════════════════════════════
-- 5. TAB: SLIDERS (滑块演示)
-- ═══════════════════════════════════════════
local SliderTab = Window:CreateTab({
    Name = "Sliders",
    Icon = "📊",
    Order = 2
})

local sliderSection = SliderTab:CreateSection("Slider Examples")

-- 整数滑块
local speedSlider = sliderSection:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,              -- 步进值
    Flag = "WalkSpeed",
    Callback = function(value)
        print("[Slider] Walk Speed:", value)
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
        end)
    end
})

-- 浮点滑块
local precisionSlider = sliderSection:AddSlider({
    Name = "Precision Value",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Increment = 0.01,           -- 精确到小数点后两位
    Flag = "PrecisionVal",
    Callback = function(value)
        print("[Slider] Precision:", value)
    end
})

-- 带后缀的滑块
local fovSlider = sliderSection:AddSlider({
    Name = "FOV",
    Min = 30,
    Max = 120,
    Default = 70,
    Increment = 5,
    Suffix = "°",               -- 后缀显示
    Flag = "FOV",
    Callback = function(value)
        print("[Slider] FOV:", value)
        pcall(function()
            workspace.CurrentCamera.FieldOfView = value
        end)
    end
})

-- 大范围滑块
local jumpSlider = sliderSection:AddSlider({
    Name = "Jump Power",
    Min = 0,
    Max = 500,
    Default = 50,
    Increment = 10,
    Suffix = " force",
    Flag = "JumpPower",
    Callback = function(value)
        print("[Slider] Jump Power:", value)
    end
})

-- ═══════════════════════════════════════════
-- 6. TAB: DROPDOWNS (下拉菜单演示)
-- ═══════════════════════════════════════════
local DropdownTab = Window:CreateTab({
    Name = "Dropdowns",
    Icon = "📋",
    Order = 3
})

local ddSection = DropdownTab:CreateSection("Single Select")

-- 单选下拉
local singleDropdown = ddSection:AddDropdown({
    Name = "Select Mode",
    Options = {"Mode A", "Mode B", "Mode C", "Mode D"},
    Default = "Mode A",
    Flag = "SelectedMode",
    Callback = function(selected)
        print("[Dropdown] Selected:", selected)
    end
})

-- 多选下拉
local multiSection = DropdownTab:CreateSection("Multi Select")

local multiDropdown = multiSection:AddDropdown({
    Name = "ESP Types",
    Options = {"Box", "Name", "Health Bar", "Tracers", "Skeleton"},
    Default = {},                   -- 多选默认值为 table
    Multi = true,                   -- 启用多选
    Flag = "ESPTypes",
    Callback = function(selected)
        print("[Dropdown Multi] Selected:")
        for option, enabled in pairs(selected) do
            if enabled then
                print("  -", option)
            end
        end
    end
})

-- 动态选项下拉
local dynamicSection = DropdownTab:CreateSection("Dynamic Options")

local playerDropdown = dynamicSection:AddDropdown({
    Name = "Select Player",
    Options = {},
    Default = "",
    Flag = "SelectedPlayer",
    Callback = function(selected)
        print("[Dropdown] Player:", selected)
    end
})

-- 刷新玩家列表按钮
dynamicSection:AddButton({
    Name = "Refresh Player List",
    Callback = function()
        local playerNames = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            table.insert(playerNames, player.Name)
        end
        playerDropdown:SetOptions(playerNames)  -- 动态更新选项
        Library:Notify({
            Title = "Refreshed",
            Content = "Found " .. #playerNames .. " players",
            Type = "Info",
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════════
-- 7. TAB: INPUTS (输入组件演示)
-- ═══════════════════════════════════════════
local InputTab = Window:CreateTab({
    Name = "Inputs",
    Icon = "⌨",
    Order = 4
})

-- TextBox Section
local textSection = InputTab:CreateSection("Text Input")

local textBox1 = textSection:AddTextBox({
    Name = "Username",
    Default = "",
    PlaceholderText = "Enter username...",
    Flag = "TargetUsername",
    ClearOnFocus = false,           -- 聚焦时不清空
    Callback = function(text)
        print("[TextBox] Username:", text)
    end
})

local textBox2 = textSection:AddTextBox({
    Name = "Chat Message",
    Default = "Hello!",
    PlaceholderText = "Type message...",
    Flag = "ChatMessage",
    ClearOnFocus = true,            -- 聚焦时清空
    Callback = function(text)
        print("[TextBox] Message:", text)
    end
})

-- Keybind Section
local keybindSection = InputTab:CreateSection("Keybind")

local flyKeybind = keybindSection:AddKeybind({
    Name = "Fly Toggle",
    Default = Enum.KeyCode.F,
    Flag = "FlyKey",
    Callback = function(key)
        -- 按下绑定的键时触发
        print("[Keybind] Fly triggered! Key:", key)
        Library:Notify({
            Title = "Fly",
            Content = "Key pressed: " .. key.Name,
            Type = "Info",
            Duration = 1
        })
    end,
    ChangedCallback = function(newKey)
        -- 键位变更时触发
        print("[Keybind] Fly key changed to:", newKey)
    end
})

local noclipKeybind = keybindSection:AddKeybind({
    Name = "Noclip Toggle",
    Default = Enum.KeyCode.N,
    Flag = "NoclipKey",
    Callback = function(key)
        print("[Keybind] Noclip triggered!")
    end,
    ChangedCallback = function(newKey)
        print("[Keybind] Noclip key changed to:", newKey)
    end
})

-- ColorPicker Section
local colorSection = InputTab:CreateSection("Color Picker")

local espColor = colorSection:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(0, 255, 0),
    Flag = "ESPColor",
    Callback = function(color)
        print("[ColorPicker] ESP Color:", color)
    end
})

local crosshairColor = colorSection:AddColorPicker({
    Name = "Crosshair Color",
    Default = Color3.fromRGB(255, 255, 0),
    Flag = "CrosshairColor",
    Callback = function(color)
        print("[ColorPicker] Crosshair:", color)
    end
})

-- ═══════════════════════════════════════════
-- 8. TAB: DISPLAY (展示组件演示)
-- ═══════════════════════════════════════════
local DisplayTab = Window:CreateTab({
    Name = "Display",
    Icon = "📝",
    Order = 5
})

-- Buttons Section
local btnSection = DisplayTab:CreateSection("Buttons")

btnSection:AddButton({
    Name = "Simple Button",
    Callback = function()
        print("[Button] Clicked!")
        Library:Notify({
            Title = "Button Clicked",
            Content = "You pressed the button!",
            Type = "Success",
            Duration = 2
        })
    end
})

btnSection:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        Library:Notify({
            Title = "Rejoining...",
            Content = "Please wait...",
            Type = "Warning",
            Duration = 2
        })
        task.wait(2)
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
        end)
    end
})

btnSection:AddButton({
    Name = "Copy Game ID",
    Callback = function()
        pcall(function()
            setclipboard(tostring(game.PlaceId))
        end)
        Library:Notify({
            Title = "Copied!",
            Content = "Game ID: " .. game.PlaceId,
            Type = "Success",
            Duration = 2
        })
    end
})

-- Labels Section
local labelSection = DisplayTab:CreateSection("Labels")

local dynamicLabel = labelSection:AddLabel({
    Text = "Player: " .. game.Players.LocalPlayer.Name
})

labelSection:AddLabel({
    Text = "Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
})

local fpsLabel = labelSection:AddLabel({
    Text = "FPS: Calculating..."
})

-- Paragraph Section
local paraSection = DisplayTab:CreateSection("Paragraphs")

paraSection:AddParagraph({
    Title = "About This Library",
    Content = "Log UI Library is a Vape V4 styled UI framework for Roblox.\nFeatures smooth animations, multiple themes, config saving, and more."
})

paraSection:AddParagraph({
    Title = "Controls",
    Content = "• RightShift - Toggle UI\n• Right-Click toggles to expand sub-options\n• Click keybind button then press a key to bind\n• ESC to cancel keybind, Delete to clear"
})

-- ═══════════════════════════════════════════
-- 9. TAB: NOTIFICATIONS (通知演示)
-- ═══════════════════════════════════════════
local NotifyTab = Window:CreateTab({
    Name = "Notifications",
    Icon = "🔔",
    Order = 6
})

local notifySection = NotifyTab:CreateSection("Send Notifications")

notifySection:AddButton({
    Name = "Success Notification",
    Callback = function()
        Library:Notify({
            Title = "Success!",
            Content = "Operation completed successfully.",
            Type = "Success",
            Duration = 3
        })
    end
})

notifySection:AddButton({
    Name = "Error Notification",
    Callback = function()
        Library:Notify({
            Title = "Error!",
            Content = "Something went wrong.",
            Type = "Error",
            Duration = 3
        })
    end
})

notifySection:AddButton({
    Name = "Warning Notification",
    Callback = function()
        Library:Notify({
            Title = "Warning!",
            Content = "Proceed with caution.",
            Type = "Warning",
            Duration = 3
        })
    end
})

notifySection:AddButton({
    Name = "Info Notification",
    Callback = function()
        Library:Notify({
            Title = "Information",
            Content = "This is an info notification.",
            Type = "Info",
            Duration = 3
        })
    end
})

notifySection:AddButton({
    Name = "Long Duration (10s, hover to pause)",
    Callback = function()
        Library:Notify({
            Title = "Long Notification",
            Content = "This stays for 10 seconds. Hover to pause!",
            Type = "Info",
            Duration = 10
        })
    end
})

notifySection:AddButton({
    Name = "No Content Notification",
    Callback = function()
        Library:Notify({
            Title = "Title Only!",
            Type = "Success",
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════════
-- 10. TAB: API CONTROL (编程式控制演示)
-- ═══════════════════════════════════════════
local APITab = Window:CreateTab({
    Name = "API Control",
    Icon = "🔧",
    Order = 7
})

local apiSection = APITab:CreateSection("Programmatic Control")

-- Set values via code
apiSection:AddButton({
    Name = "Set Toggle1 = true",
    Callback = function()
        toggle1:Set(true)
    end
})

apiSection:AddButton({
    Name = "Set Toggle1 = false",
    Callback = function()
        toggle1:Set(false)
    end
})

apiSection:AddButton({
    Name = "Set Speed Slider = 100",
    Callback = function()
        speedSlider:Set(100)
    end
})

apiSection:AddButton({
    Name = "Set FOV Slider = 90",
    Callback = function()
        fovSlider:Set(90)
    end
})

apiSection:AddButton({
    Name = "Set Dropdown = 'Mode C'",
    Callback = function()
        singleDropdown:Set("Mode C")
    end
})

apiSection:AddButton({
    Name = "Set TextBox = 'Hello World'",
    Callback = function()
        textBox1:Set("Hello World")
    end
})

apiSection:AddButton({
    Name = "Set Keybind = H",
    Callback = function()
        flyKeybind:Set(Enum.KeyCode.H)
    end
})

apiSection:AddButton({
    Name = "Set ESP Color = Blue",
    Callback = function()
        espColor:Set(Color3.fromRGB(0, 100, 255))
    end
})

apiSection:AddButton({
    Name = "Update Label Text",
    Callback = function()
        dynamicLabel:Set("Updated at: " .. os.date("%H:%M:%S"))
    end
})

-- Get values
local getSection = APITab:CreateSection("Get Values")

getSection:AddButton({
    Name = "Print All Values",
    Callback = function()
        print("========== Current Values ==========")
        print("Toggle1:", toggle1:GetState())
        print("Speed:", speedSlider:GetValue())
        print("FOV:", fovSlider:GetValue())
        print("Dropdown:", singleDropdown:GetValue())
        print("TextBox:", textBox1:GetValue())
        print("Keybind:", flyKeybind:GetValue())
        print("ESP Color:", espColor:GetValue())
        print("====================================")
        Library:Notify({
            Title = "Values Printed",
            Content = "Check console (F9) for output",
            Type = "Info",
            Duration = 3
        })
    end
})

-- Window control
local windowSection = APITab:CreateSection("Window Control")

windowSection:AddButton({
    Name = "Switch to Toggles Tab",
    Callback = function()
        Window:SelectTab("Toggles")     -- 通过名称切换
    end
})

windowSection:AddButton({
    Name = "Switch to Display Tab",
    Callback = function()
        Window:SelectTab(DisplayTab)    -- 通过引用切换
    end
})

windowSection:AddButton({
    Name = "Minimize Window",
    Callback = function()
        Window:ToggleMinimize()
    end
})

windowSection:AddButton({
    Name = "Hide Window (Show with RightShift)",
    Callback = function()
        Window:Hide()
    end
})

windowSection:AddButton({
    Name = "Destroy UI Completely",
    Callback = function()
        Library:Notify({
            Title = "Goodbye!",
            Content = "Destroying UI in 2 seconds...",
            Type = "Warning",
            Duration = 2
        })
        task.wait(2)
        Library:Destroy()
    end
})

-- ═══════════════════════════════════════════
-- 11. BUILT-IN SETTINGS/CONFIG TAB
-- ═══════════════════════════════════════════
-- 自动创建主题切换 + 配置管理 Tab
Window:CreateConfigTab({
    Name = "Settings",              -- Tab名称 (默认 "Settings")
    Icon = "⚙"                     -- 图标 (默认 "⚙")
})

-- ═══════════════════════════════════════════
-- 12. DYNAMIC UPDATES (运行时动态更新)
-- ═══════════════════════════════════════════

-- FPS Counter (持续更新 Label)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
            fpsLabel:Set("FPS: " .. fps)
        end)
    end
end)

-- ═══════════════════════════════════════════
-- 13. ACCESSING FLAGS GLOBALLY
-- ═══════════════════════════════════════════
--[[
    所有设置了 Flag 的组件都可以通过 Library.Flags 访问:
    
    Library.Flags["SimpleToggle"]:GetState()
    Library.Flags["WalkSpeed"]:GetValue()
    Library.Flags["SelectedMode"]:GetValue()
    Library.Flags["FlyKey"]:GetValue()
    Library.Flags["ESPColor"]:GetValue()
    
    Library.Flags["SimpleToggle"]:Set(true)
    Library.Flags["WalkSpeed"]:Set(50)
]]

print("═══════════════════════════════════════")
print("  Log UI Library Demo Loaded!")
print("  Press RightShift to toggle UI")
print("  Right-click toggles for sub-options")
print("═══════════════════════════════════════")
```

---

## README.md

```markdown
# Log UI Library

<div align="center">

**A Vape V4 styled UI library for Roblox script hubs**

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Roblox-red)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

## ✨ Features

- 🎨 **Vape V4 Inspired Design** — Clean, dark, floating window with sidebar navigation
- 🧩 **10+ UI Components** — Toggle, Slider, Dropdown, Button, TextBox, Keybind, ColorPicker, Label, Paragraph, Section
- 📁 **Config System** — Save/load/delete configurations with JSON
- 🎭 **3 Built-in Themes** — Vape Dark, Midnight Purple, Ocean Blue
- 🔔 **Notification System** — 4 notification types with auto-dismiss and hover pause
- 🖱️ **Draggable Windows** — Smooth dragging with TweenService
- ⌨️ **Keybind System** — Toggle UI visibility, per-component keybinds
- 🔗 **Sub-Components** — Nest Sliders, Dropdowns, ColorPickers inside Toggles
- 🚀 **Executor Compatible** — Synapse X, Script-Ware, Fluxus, and more
- 💾 **Flag System** — Global state management across all components

---

## 📦 Installation

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/log-ui-lib/refs/heads/main/main.lua"))()
```

---

## 🚀 Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/log-ui-lib/refs/heads/main/main.lua"))()

-- Create window
local Window = Library:CreateWindow({
    Title = "My Script Hub",
    Subtitle = "v1.0",
    Theme = "Vape Dark",
    ToggleKey = Enum.KeyCode.RightShift,
    SaveConfig = true,
    ConfigFolder = "MyHub"
})

-- Create tab
local Tab = Window:CreateTab({ Name = "Main", Icon = "⚡" })

-- Create section
local Section = Tab:CreateSection("Features")

-- Add components
Section:AddToggle({
    Name = "Feature",
    Default = false,
    Flag = "MyFeature",
    Callback = function(value)
        print("Feature:", value)
    end
})

-- Built-in settings tab
Window:CreateConfigTab()
```

---

## 📖 Full API Reference

### Library

| Method | Description |
|--------|-------------|
| `Library:CreateWindow(options)` | Create a new window |
| `Library:Notify(options)` | Show a notification |
| `Library:SetTheme(name)` | Change theme at runtime |
| `Library:GetTheme()` | Get current theme table |
| `Library:GetThemes()` | Get list of theme names |
| `Library:AddTheme(name, data)` | Register a custom theme |
| `Library:ToggleVisibility()` | Toggle all windows visible/hidden |
| `Library:Destroy()` | Destroy entire UI |
| `Library.Flags` | Table of all flagged components |

---

### Window

```lua
local Window = Library:CreateWindow({
    Title = "Title",                            -- string
    Subtitle = "v1.0",                          -- string
    Theme = "Vape Dark",                        -- "Vape Dark" | "Midnight Purple" | "Ocean Blue"
    Size = UDim2.new(0, 600, 0, 420),           -- UDim2 (optional)
    Position = UDim2.new(0.5, -300, 0.5, -210), -- UDim2 (optional)
    ToggleKey = Enum.KeyCode.RightShift,        -- Enum.KeyCode (optional)
    SaveConfig = true,                          -- boolean (optional)
    ConfigFolder = "FolderName"                 -- string (optional)
})
```

| Method | Description |
|--------|-------------|
| `Window:CreateTab(options)` | Create a new tab |
| `Window:CreateConfigTab(options)` | Create built-in settings/config tab |
| `Window:SelectTab(name)` | Switch to tab by name |
| `Window:SelectTab(tabRef)` | Switch to tab by reference |
| `Window:ToggleMinimize()` | Minimize / restore window |
| `Window:Hide()` | Hide window with animation |
| `Window:Show()` | Show window with animation |

---

### Tab

```lua
local Tab = Window:CreateTab({
    Name = "Tab Name",   -- string
    Icon = "⚡",         -- string (emoji or empty)
    Order = 1            -- number (sort order)
})
```

| Method | Description |
|--------|-------------|
| `Tab:CreateSection(name)` | Create a section within the tab |

---

### Section

```lua
local Section = Tab:CreateSection("Section Title")
```

| Method | Returns | Description |
|--------|---------|-------------|
| `Section:AddToggle(options)` | Toggle | Add a toggle switch |
| `Section:AddSlider(options)` | Slider | Add a slider |
| `Section:AddDropdown(options)` | Dropdown | Add a dropdown menu |
| `Section:AddButton(options)` | Button | Add a clickable button |
| `Section:AddTextBox(options)` | TextBox | Add a text input field |
| `Section:AddKeybind(options)` | Keybind | Add a keybind selector |
| `Section:AddColorPicker(options)` | ColorPicker | Add a color picker |
| `Section:AddLabel(options)` | Label | Add a text label |
| `Section:AddParagraph(options)` | Paragraph | Add a titled paragraph |

---

### Components

#### Toggle

```lua
local Toggle = Section:AddToggle({
    Name = "Toggle Name",          -- string
    Default = false,               -- boolean
    Flag = "UniqueFlag",           -- string (optional, for config saving)
    Keybind = Enum.KeyCode.G,      -- Enum.KeyCode (optional, quick toggle)
    Callback = function(value)     -- function(boolean)
        print(value)
    end
})
```

| Method | Description |
|--------|-------------|
| `Toggle:Set(bool)` | Set toggle state |
| `Toggle:GetState()` | Get current state → `boolean` |
| `Toggle:ToggleExpand()` | Expand/collapse sub-components |
| `Toggle:AddSlider(options)` | Add sub-slider |
| `Toggle:AddDropdown(options)` | Add sub-dropdown |
| `Toggle:AddToggle(options)` | Add sub-toggle |
| `Toggle:AddKeybind(options)` | Add sub-keybind |
| `Toggle:AddColorPicker(options)` | Add sub-color picker |

> **💡 Tip:** Right-click a toggle with sub-components to expand/collapse them.

---

#### Slider

```lua
local Slider = Section:AddSlider({
    Name = "Slider Name",         -- string
    Min = 0,                      -- number
    Max = 100,                    -- number
    Default = 50,                 -- number
    Increment = 1,                -- number (step size, e.g. 0.1 for floats)
    Suffix = " units",            -- string (optional, appended to display)
    Flag = "UniqueFlag",          -- string (optional)
    Callback = function(value)    -- function(number)
        print(value)
    end
})
```

| Method | Description |
|--------|-------------|
| `Slider:Set(number)` | Set slider value |
| `Slider:GetValue()` | Get current value → `number` |

---

#### Dropdown

```lua
-- Single select
local Dropdown = Section:AddDropdown({
    Name = "Dropdown Name",              -- string
    Options = {"A", "B", "C"},           -- table
    Default = "A",                       -- string
    Flag = "UniqueFlag",                 -- string (optional)
    Callback = function(selected)        -- function(string)
        print(selected)
    end
})

-- Multi select
local MultiDropdown = Section:AddDropdown({
    Name = "Multi Dropdown",
    Options = {"X", "Y", "Z"},
    Default = {},                        -- table (for multi-select)
    Multi = true,                        -- boolean
    Flag = "UniqueFlag",
    Callback = function(selected)        -- function(table: {[option] = true})
        for opt, enabled in pairs(selected) do
            print(opt, enabled)
        end
    end
})
```

| Method | Description |
|--------|-------------|
| `Dropdown:Set(value)` | Set selected value (string or table) |
| `Dropdown:GetValue()` | Get current value → `string` or `table` |
| `Dropdown:SetOptions(newOptions, keepValue?)` | Replace options list |
| `Dropdown:Open()` | Open dropdown |
| `Dropdown:Close()` | Close dropdown |
| `Dropdown:Toggle()` | Toggle open/close |

---

#### Button

```lua
local Button = Section:AddButton({
    Name = "Button Name",         -- string
    Callback = function()         -- function()
        print("Clicked!")
    end
})
```

| Method | Description |
|--------|-------------|
| `Button:SetCallback(fn)` | Replace callback function |

---

#### TextBox

```lua
local TextBox = Section:AddTextBox({
    Name = "TextBox Name",               -- string
    Default = "",                        -- string
    PlaceholderText = "Enter text...",   -- string
    ClearOnFocus = false,                -- boolean (optional)
    Flag = "UniqueFlag",                 -- string (optional)
    Callback = function(text)            -- function(string) - fires on focus lost
        print(text)
    end
})
```

| Method | Description |
|--------|-------------|
| `TextBox:Set(string)` | Set text value |
| `TextBox:GetValue()` | Get current text → `string` |

---

#### Keybind

```lua
local Keybind = Section:AddKeybind({
    Name = "Keybind Name",                  -- string
    Default = Enum.KeyCode.F,               -- Enum.KeyCode
    Flag = "UniqueFlag",                    -- string (optional)
    Callback = function(key)                -- function(Enum.KeyCode) - fires when key pressed
        print("Pressed:", key)
    end,
    ChangedCallback = function(newKey)       -- function(Enum.KeyCode) - fires when rebound
        print("Changed to:", newKey)
    end
})
```

| Method | Description |
|--------|-------------|
| `Keybind:Set(Enum.KeyCode)` | Set keybind |
| `Keybind:GetValue()` | Get current key → `Enum.KeyCode` |

> **Keybind Controls:**
> - Click the keybind button → press any key to bind
> - Press `Escape` to cancel
> - Press `Delete` or `Backspace` to clear (set to None)

---

#### ColorPicker

```lua
local ColorPicker = Section:AddColorPicker({
    Name = "Color Name",                    -- string
    Default = Color3.fromRGB(255, 0, 0),    -- Color3
    Flag = "UniqueFlag",                    -- string (optional)
    Callback = function(color)              -- function(Color3)
        print(color)
    end
})
```

| Method | Description |
|--------|-------------|
| `ColorPicker:Set(Color3)` | Set color value |
| `ColorPicker:GetValue()` | Get current color → `Color3` |

> Click the color preview square to expand the HSV picker panel. Supports hex input.

---

#### Label

```lua
local Label = Section:AddLabel({
    Text = "Label text"    -- string
})
```

| Method | Description |
|--------|-------------|
| `Label:Set(string)` | Update label text |

---

#### Paragraph

```lua
local Paragraph = Section:AddParagraph({
    Title = "Title",       -- string
    Content = "Body text"  -- string (supports \n)
})
```

| Method | Description |
|--------|-------------|
| `Paragraph:Set(title?, content?)` | Update title and/or content |

---

### Notifications

```lua
Library:Notify({
    Title = "Notification Title",   -- string
    Content = "Description text",   -- string (optional)
    Type = "Success",               -- "Success" | "Error" | "Warning" | "Info"
    Duration = 3                    -- number (seconds)
})
```

| Type | Icon | Color |
|------|------|-------|
| `Success` | ✓ | Green |
| `Error` | ✗ | Red |
| `Warning` | ⚠ | Yellow |
| `Info` | ℹ | Blue |

> **💡 Hover over a notification to pause the auto-dismiss timer.**

---

### Built-in Config Tab

```lua
Window:CreateConfigTab({
    Name = "Settings",    -- string (optional, default "Settings")
    Icon = "⚙"           -- string (optional, default "⚙")
})
```

Automatically creates a tab with:
- **Theme Selector** — Switch between all available themes
- **Config Save/Load/Delete** — Full configuration management
- **Player Info** — Displays current player name
- **Destroy UI Button** — Clean removal of UI

> ⚠️ Config saving requires `SaveConfig = true` in `CreateWindow` and a supported executor with file system APIs (`writefile`, `readfile`, `isfile`, `makefolder`).

---

### Themes

#### Available Themes

| Theme | Description |
|-------|-------------|
| `Vape Dark` | Default dark theme with red accents |
| `Midnight Purple` | Deep purple dark theme |
| `Ocean Blue` | Dark blue oceanic theme |

#### Switching Themes

```lua
Library:SetTheme("Midnight Purple")
```

#### Custom Theme

```lua
Library:AddTheme("My Theme", {
    Name = "My Theme",
    Background = Color3.fromRGB(20, 20, 20),
    Accent = Color3.fromRGB(255, 100, 0),
    -- ... (see source for full theme structure)
})
Library:SetTheme("My Theme")
```

---

### Flag System

All components with a `Flag` property are stored in `Library.Flags`:

```lua
-- Access any flagged component globally
Library.Flags["WalkSpeed"]:Set(100)
Library.Flags["WalkSpeed"]:GetValue()   -- 100

Library.Flags["KillAura"]:Set(true)
Library.Flags["KillAura"]:GetState()    -- true
```

---

### Config System

```lua
-- Save
Library.ConfigManager:Save("my_config")

-- Load
Library.ConfigManager:Load("my_config")

-- List configs
local configs = Library.ConfigManager:GetConfigs()  -- {"my_config", "default", ...}

-- Delete
Library.ConfigManager:Delete("my_config")
```

Configs are saved as JSON in: `<ConfigFolder>/<name>.json`

Supported types: `boolean`, `number`, `string`, `table`, `Color3`, `EnumItem`

---

## 🎮 Controls

| Key / Action | Function |
|-------------|----------|
| `RightShift` (default) | Toggle UI visibility |
| `Drag title bar` | Move window |
| `—` button | Minimize/restore window |
| `×` button | Hide window |
| `Right-click` toggle | Expand/collapse sub-options |
| `Click` keybind button | Enter listen mode |
| `Escape` | Cancel keybind listen |
| `Delete` / `Backspace` | Clear keybind |
| `Click` color preview | Open/close color picker |

---

## 📁 Project Structure

```
log-ui-lib/
├── main.lua          # Full UI library (single file)
├── example.lua       # Complete demo script
└── README.md         # Documentation
```

---

## ⚙️ Executor Compatibility

The library automatically detects and uses the best available method:

| Priority | Method | Executor |
|----------|--------|----------|
| 1 | `syn.protect_gui` → `CoreGui` | Synapse X |
| 2 | `gethui()` | Script-Ware, Hydrogen |
| 3 | `CoreGui` (direct) | Most executors |
| 4 | `PlayerGui` (fallback) | Basic executors |

File system APIs needed for config saving:
- `writefile` / `readfile` / `isfile` / `isfolder` / `makefolder` / `listfiles` / `delfile`

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

<div align="center">

**Made by [logquickly](https://github.com/logquickly)**

</div>
