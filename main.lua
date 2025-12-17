--[[
    Vape Style UI Library
    Author: log_quick
    Version: 1.0.0
    
    Features:
    - Mobile Support
    - Vape-style floating menu
    - Color picker, sliders, buttons
    - Config system with save/load
    - Search functionality
    - Smooth animations
]]

local VapeUI = {}
VapeUI.__index = VapeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Default Settings
local DefaultSettings = {
    MainColor = Color3.fromRGB(147, 112, 219), -- Purple theme
    BackgroundColor = Color3.fromRGB(25, 25, 35),
    BorderColor = Color3.fromRGB(80, 60, 120),
    TextColor = Color3.fromRGB(255, 255, 255),
    AccentColor = Color3.fromRGB(180, 140, 255),
    Font = Enum.Font.GothamBold,
    CornerRadius = UDim.new(0, 8),
    AnimationSpeed = 0.3
}

-- Utility Functions
local function CreateTween(instance, properties, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or DefaultSettings.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    return tween
end

local function CreateInstance(className, properties, children)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId or "rbxassetid://6026984224"
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    handle = handle or frame
    
    local function update(input)
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        CreateTween(frame, {Position = newPosition}, 0.1):Play()
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

-- Main Library
function VapeUI.new(title, authorInfo)
    local self = setmetatable({}, VapeUI)
    
    self.Title = title or "Vape UI"
    self.AuthorInfo = authorInfo or "Unknown"
    self.Settings = table.clone(DefaultSettings)
    self.Categories = {}
    self.ActivePanels = {}
    self.AllElements = {}
    self.Configs = {}
    self.ConfigFolder = "VapeUI_Configs"
    
    self:CreateUI()
    
    return self
end

function VapeUI:CreateUI()
    -- Main ScreenGui
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "VapeUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- Background blur effect
    self.BlurEffect = CreateInstance("BlurEffect", {
        Name = "VapeBlur",
        Size = 0,
        Parent = game:GetService("Lighting")
    })
    
    -- Main floating button
    local buttonSize = IsMobile() and 60 or 50
    self.MainButton = CreateInstance("ImageButton", {
        Name = "MainButton",
        Size = UDim2.new(0, buttonSize, 0, buttonSize),
        Position = UDim2.new(0.5, -buttonSize/2, 0, 10),
        BackgroundColor3 = self.Settings.MainColor,
        AutoButtonColor = false,
        Image = ""
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)}),
        CreateInstance("UIStroke", {
            Color = self.Settings.AccentColor,
            Thickness = 2,
            Transparency = 0.5
        }),
        CreateInstance("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "V",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = IsMobile() and 28 or 24,
            Font = Enum.Font.GothamBlack
        })
    })
    
    -- Glow effect for main button
    self.MainButtonGlow = CreateInstance("ImageLabel", {
        Name = "Glow",
        Size = UDim2.new(1.5, 0, 1.5, 0),
        Position = UDim2.new(-0.25, 0, -0.25, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = self.Settings.MainColor,
        ImageTransparency = 0.7,
        ZIndex = 0
    })
    self.MainButtonGlow.Parent = self.MainButton
    
    MakeDraggable(self.MainButton)
    
    -- Main dropdown menu
    self.MainMenu = CreateInstance("Frame", {
        Name = "MainMenu",
        Size = UDim2.new(0, IsMobile() and 200 or 180, 0, 0),
        Position = UDim2.new(0.5, IsMobile() and -100 or -90, 0, buttonSize + 15),
        BackgroundColor3 = self.Settings.BackgroundColor,
        ClipsDescendants = true,
        Visible = false
    }, {
        CreateInstance("UICorner", {CornerRadius = self.Settings.CornerRadius}),
        CreateInstance("UIStroke", {
            Color = self.Settings.BorderColor,
            Thickness = 2
        }),
        CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        }),
        CreateInstance("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })
    })
    
    -- Search bar for main menu
    self.SearchBar = self:CreateSearchBar(self.MainMenu, function(query)
        self:SearchAll(query)
    end)
    self.SearchBar.LayoutOrder = -1
    
    -- Container for active panels
    self.PanelContainer = CreateInstance("Frame", {
        Name = "PanelContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    })
    
    self.MainMenu.Parent = self.ScreenGui
    self.MainButton.Parent = self.ScreenGui
    self.PanelContainer.Parent = self.ScreenGui
    self.ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Main button click handler
    local menuOpen = false
    self.MainButton.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        self:ToggleMainMenu(menuOpen)
        PlaySound()
    end)
    
    -- Hover animation
    self.MainButton.MouseEnter:Connect(function()
        CreateTween(self.MainButton, {Size = UDim2.new(0, buttonSize + 5, 0, buttonSize + 5)}):Play()
        CreateTween(self.MainButtonGlow, {ImageTransparency = 0.4}):Play()
    end)
    
    self.MainButton.MouseLeave:Connect(function()
        CreateTween(self.MainButton, {Size = UDim2.new(0, buttonSize, 0, buttonSize)}):Play()
        CreateTween(self.MainButtonGlow, {ImageTransparency = 0.7}):Play()
    end)
    
    -- Pulse animation
    spawn(function()
        while self.ScreenGui.Parent do
            CreateTween(self.MainButtonGlow, {ImageTransparency = 0.5}, 1):Play()
            wait(1)
            CreateTween(self.MainButtonGlow, {ImageTransparency = 0.8}, 1):Play()
            wait(1)
        end
    end)
    
    -- Add settings category
    self:CreateSettingsCategory()
end

function VapeUI:ToggleMainMenu(open)
    self.MainMenu.Visible = true
    
    local listLayout = self.MainMenu:FindFirstChild("UIListLayout")
    local contentSize = listLayout.AbsoluteContentSize.Y + 10
    local maxSize = math.min(contentSize, 400)
    
    if open then
        CreateTween(self.MainMenu, {Size = UDim2.new(0, IsMobile() and 200 or 180, 0, maxSize)}):Play()
        CreateTween(self.BlurEffect, {Size = 6}):Play()
    else
        local tween = CreateTween(self.MainMenu, {Size = UDim2.new(0, IsMobile() and 200 or 180, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function()
            if self.MainMenu.Size.Y.Offset < 5 then
                self.MainMenu.Visible = false
            end
        end)
        CreateTween(self.BlurEffect, {Size = 0}):Play()
    end
end

function VapeUI:CreateSearchBar(parent, callback)
    local searchFrame = CreateInstance("Frame", {
        Name = "SearchBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        Parent = parent
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -35, 1, 0),
            Position = UDim2.new(0, 30, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search...",
            TextColor3 = self.Settings.TextColor,
            PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 14,
            Font = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false
        }),
        CreateInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 8, 0.5, -8),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031154871",
            ImageColor3 = Color3.fromRGB(150, 150, 150)
        })
    })
    
    local input = searchFrame:FindFirstChild("Input")
    input:GetPropertyChangedSignal("Text"):Connect(function()
        callback(input.Text)
    end)
    
    return searchFrame
end

function VapeUI:AddCategory(name, icon)
    local category = {
        Name = name,
        Icon = icon or "⚡",
        Elements = {},
        Panel = nil,
        Active = false,
        SubCategories = {}
    }
    
    -- Category button in main menu
    local buttonHeight = IsMobile() and 40 or 35
    local categoryButton = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        AutoButtonColor = false,
        Text = "",
        Parent = self.MainMenu
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("UIStroke", {
            Name = "Stroke",
            Color = self.Settings.BorderColor,
            Thickness = 1,
            Transparency = 0.8
        }),
        CreateInstance("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 25, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = icon or "⚡",
            TextColor3 = self.Settings.MainColor,
            TextSize = 16,
            Font = self.Settings.Font
        }),
        CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 35, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = self.Settings.TextColor,
            TextSize = 14,
            Font = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        CreateInstance("TextLabel", {
            Name = "Arrow",
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -25, 0, 0),
            BackgroundTransparency = 1,
            Text = "›",
            TextColor3 = self.Settings.TextColor,
            TextSize = 20,
            Font = self.Settings.Font
        })
    })
    
    -- Highlight overlay
    local highlight = CreateInstance("Frame", {
        Name = "Highlight",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Settings.MainColor,
        BackgroundTransparency = 1,
        ZIndex = 0
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    highlight.Parent = categoryButton
    
    category.Button = categoryButton
    
    -- Hover effects
    categoryButton.MouseEnter:Connect(function()
        CreateTween(highlight, {BackgroundTransparency = 0.9}):Play()
        CreateTween(categoryButton:FindFirstChild("Stroke"), {Transparency = 0.5}):Play()
    end)
    
    categoryButton.MouseLeave:Connect(function()
        if not category.Active then
            CreateTween(highlight, {BackgroundTransparency = 1}):Play()
            CreateTween(categoryButton:FindFirstChild("Stroke"), {Transparency = 0.8}):Play()
        end
    end)
    
    -- Click handler
    categoryButton.MouseButton1Click:Connect(function()
        category.Active = not category.Active
        self:ToggleCategoryPanel(category)
        PlaySound()
        
        if category.Active then
            CreateTween(highlight, {BackgroundTransparency = 0.85}):Play()
            CreateTween(categoryButton:FindFirstChild("Stroke"), {Color = self.Settings.MainColor, Transparency = 0.3}):Play()
        else
            CreateTween(highlight, {BackgroundTransparency = 1}):Play()
            CreateTween(categoryButton:FindFirstChild("Stroke"), {Color = self.Settings.BorderColor, Transparency = 0.8}):Play()
        end
    end)
    
    self.Categories[name] = category
    
    -- Update main menu size
    task.wait()
    local listLayout = self.MainMenu:FindFirstChild("UIListLayout")
    if listLayout then
        self.MainMenu.Size = UDim2.new(0, IsMobile() and 200 or 180, 0, math.min(listLayout.AbsoluteContentSize.Y + 15, 400))
    end
    
    return category
end

function VapeUI:ToggleCategoryPanel(category)
    if category.Active then
        -- Create panel if doesn't exist
        if not category.Panel then
            category.Panel = self:CreateCategoryPanel(category)
        end
        
        -- Position panel
        self:PositionPanel(category.Panel)
        category.Panel.Visible = true
        
        -- Animate in
        category.Panel.Size = UDim2.new(0, 0, 0, 0)
        CreateTween(category.Panel, {
            Size = UDim2.new(0, IsMobile() and 220 or 200, 0, 300)
        }):Play()
        
        self.ActivePanels[category.Name] = category.Panel
    else
        if category.Panel then
            local panel = category.Panel
            local tween = CreateTween(panel, {Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                panel.Visible = false
            end)
            
            self.ActivePanels[category.Name] = nil
        end
    end
    
    self:ReorganizePanels()
end

function VapeUI:CreateCategoryPanel(category)
    local panelWidth = IsMobile() and 220 or 200
    
    local panel = CreateInstance("Frame", {
        Name = category.Name .. "_Panel",
        Size = UDim2.new(0, panelWidth, 0, 300),
        BackgroundColor3 = self.Settings.BackgroundColor,
        ClipsDescendants = true,
        Parent = self.PanelContainer
    }, {
        CreateInstance("UICorner", {CornerRadius = self.Settings.CornerRadius}),
        CreateInstance("UIStroke", {
            Color = self.Settings.BorderColor,
            Thickness = 2
        })
    })
    
    -- Header
    local header = CreateInstance("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = self.Settings.MainColor,
        Parent = panel
    }, {
        CreateInstance("UICorner", {CornerRadius = self.Settings.CornerRadius}),
        CreateInstance("Frame", {
            Name = "BottomCover",
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = self.Settings.MainColor,
            BorderSizePixel = 0
        }),
        CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = category.Icon .. " " .. category.Name,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 14,
            Font = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        CreateInstance("TextButton", {
            Name = "Close",
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(1, -30, 0.5, -12.5),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 20,
            Font = self.Settings.Font
        })
    })
    
    -- Close button handler
    header:FindFirstChild("Close").MouseButton1Click:Connect(function()
        category.Active = false
        self:ToggleCategoryPanel(category)
        
        -- Update button appearance
        local highlight = category.Button:FindFirstChild("Highlight")
        CreateTween(highlight, {BackgroundTransparency = 1}):Play()
        CreateTween(category.Button:FindFirstChild("Stroke"), {Color = self.Settings.BorderColor, Transparency = 0.8}):Play()
        
        PlaySound()
    end)
    
    -- Content scroll frame
    local scrollFrame = CreateInstance("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -10, 1, -45),
        Position = UDim2.new(0, 5, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Settings.MainColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = panel
    }, {
        CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        }),
        CreateInstance("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5)
        })
    })
    
    -- Search bar for category
    local searchBar = self:CreateSearchBar(scrollFrame, function(query)
        self:SearchCategory(category, query)
    end)
    searchBar.LayoutOrder = -1
    
    MakeDraggable(panel, header)
    
    return panel
end

function VapeUI:PositionPanel(panel)
    local screenSize = self.ScreenGui.AbsoluteSize
    local panelSize = panel.Size
    
    -- Count active panels
    local panelCount = 0
    for _ in pairs(self.ActivePanels) do
        panelCount = panelCount + 1
    end
    
    -- Calculate position
    local panelWidth = IsMobile() and 220 or 200
    local spacing = 10
    local totalWidth = (panelCount + 1) * (panelWidth + spacing)
    local startX = (screenSize.X - totalWidth) / 2
    
    -- Ensure panels stay on screen
    local row = 0
    local col = panelCount
    local maxCols = math.floor(screenSize.X / (panelWidth + spacing))
    
    if col >= maxCols then
        row = math.floor(col / maxCols)
        col = col % maxCols
    end
    
    local xPos = startX + col * (panelWidth + spacing)
    local yPos = 100 + row * 320
    
    -- Keep on screen
    xPos = math.clamp(xPos, 10, screenSize.X - panelWidth - 10)
    yPos = math.clamp(yPos, 80, screenSize.Y - 320)
    
    panel.Position = UDim2.new(0, xPos, 0, yPos)
end

function VapeUI:ReorganizePanels()
    local screenSize = self.ScreenGui.AbsoluteSize
    local panelWidth = IsMobile() and 220 or 200
    local spacing = 10
    
    local index = 0
    for _, panel in pairs(self.ActivePanels) do
        local maxCols = math.floor(screenSize.X / (panelWidth + spacing))
        local row = math.floor(index / maxCols)
        local col = index % maxCols
        
        local totalWidth = math.min(#self.ActivePanels, maxCols) * (panelWidth + spacing)
        local startX = (screenSize.X - totalWidth) / 2
        
        local xPos = startX + col * (panelWidth + spacing)
        local yPos = 100 + row * 320
        
        xPos = math.clamp(xPos, 10, screenSize.X - panelWidth - 10)
        yPos = math.clamp(yPos, 80, screenSize.Y - 320)
        
        CreateTween(panel, {Position = UDim2.new(0, xPos, 0, yPos)}):Play()
        
        index = index + 1
    end
end

-- Element Creation Functions

function VapeUI:AddButton(category, options)
    local options = options or {}
    local name = options.Name or "Button"
    local callback = options.Callback or function() end
    local toggled = options.Default or false
    local buttonColor = options.Color or self.Settings.MainColor
    
    local cat = type(category) == "string" and self.Categories[category] or category
    if not cat or not cat.Panel then return end
    
    local scrollFrame = cat.Panel:FindFirstChild("Content")
    local buttonHeight = IsMobile() and 38 or 32
    
    local buttonFrame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        Parent = scrollFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("UIStroke", {
            Name = "Stroke",
            Color = self.Settings.BorderColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local button = CreateInstance("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = buttonFrame
    })
    
    local title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        Font = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = buttonFrame
    })
    
    local toggle = CreateInstance("Frame", {
        Name = "Toggle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -28, 0.5, -9),
        BackgroundColor3 = toggled and buttonColor or Color3.fromRGB(60, 60, 70),
        Parent = buttonFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("TextLabel", {
            Name = "Check",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = toggled and "✓" or "",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            Font = self.Settings.Font
        })
    })
    
    -- Highlight overlay
    local highlight = CreateInstance("Frame", {
        Name = "Highlight",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = buttonColor,
        BackgroundTransparency = toggled and 0.85 or 1,
        ZIndex = 0,
        Parent = buttonFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    local function updateState()
        if toggled then
            CreateTween(toggle, {BackgroundColor3 = buttonColor}):Play()
            toggle:FindFirstChild("Check").Text = "✓"
            CreateTween(highlight, {BackgroundTransparency = 0.85}):Play()
            CreateTween(buttonFrame:FindFirstChild("Stroke"), {Color = buttonColor, Transparency = 0.3}):Play()
        else
            CreateTween(toggle, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
            toggle:FindFirstChild("Check").Text = ""
            CreateTween(highlight, {BackgroundTransparency = 1}):Play()
            CreateTween(buttonFrame:FindFirstChild("Stroke"), {Color = self.Settings.BorderColor, Transparency = 0.7}):Play()
        end
    end
    
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        updateState()
        callback(toggled)
        PlaySound()
        
        -- Flash effect
        local flash = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.7,
            Parent = buttonFrame
        }, {
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        local tween = CreateTween(flash, {BackgroundTransparency = 1}, 0.3)
        tween:Play()
        tween.Completed:Connect(function()
            flash:Destroy()
        end)
    end)
    
    button.MouseEnter:Connect(function()
        CreateTween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        CreateTween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end)
    
    local element = {
        Name = name,
        Type = "Button",
        Frame = buttonFrame,
        Value = toggled,
        SetValue = function(self, value)
            toggled = value
            self.Value = value
            updateState()
        end,
        GetValue = function(self)
            return toggled
        end
    }
    
    table.insert(cat.Elements, element)
    table.insert(self.AllElements, element)
    
    return element
end

function VapeUI:AddSlider(category, options)
    local options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end
    local increment = options.Increment or 1
    
    local cat = type(category) == "string" and self.Categories[category] or category
    if not cat or not cat.Panel then return end
    
    local scrollFrame = cat.Panel:FindFirstChild("Content")
    local sliderHeight = IsMobile() and 55 or 48
    
    local sliderFrame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, sliderHeight),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        Parent = scrollFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("UIStroke", {
            Color = self.Settings.BorderColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Settings.TextColor,
        TextSize = 12,
        Font = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame
    })
    
    local valueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -55, 0, 5),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = self.Settings.MainColor,
        TextSize = 12,
        Font = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderFrame
    })
    
    local sliderBack = CreateInstance("Frame", {
        Name = "SliderBack",
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        Parent = sliderFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local sliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Settings.MainColor,
        Parent = sliderBack
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local sliderKnob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = sliderBack
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)}),
        CreateInstance("UIStroke", {
            Color = self.Settings.MainColor,
            Thickness = 2
        })
    })
    
    local value = default
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * pos
        value = math.floor(rawValue / increment + 0.5) * increment
        value = math.clamp(value, min, max)
        
        local displayPos = (value - min) / (max - min)
        CreateTween(sliderFill, {Size = UDim2.new(displayPos, 0, 1, 0)}, 0.1):Play()
        CreateTween(sliderKnob, {Position = UDim2.new(displayPos, -8, 0.5, -8)}, 0.1):Play()
        valueLabel.Text = tostring(value)
        
        callback(value)
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
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
    
    local element = {
        Name = name,
        Type = "Slider",
        Frame = sliderFrame,
        Value = value,
        SetValue = function(self, newValue)
            value = math.clamp(newValue, min, max)
            self.Value = value
            local displayPos = (value - min) / (max - min)
            CreateTween(sliderFill, {Size = UDim2.new(displayPos, 0, 1, 0)}, 0.1):Play()
            CreateTween(sliderKnob, {Position = UDim2.new(displayPos, -8, 0.5, -8)}, 0.1):Play()
            valueLabel.Text = tostring(value)
        end,
        GetValue = function(self)
            return value
        end
    }
    
    table.insert(cat.Elements, element)
    table.insert(self.AllElements, element)
    
    return element
end

function VapeUI:AddColorPicker(category, options)
    local options = options or {}
    local name = options.Name or "Color"
    local default = options.Default or Color3.new(1, 1, 1)
    local callback = options.Callback or function() end
    
    local cat = type(category) == "string" and self.Categories[category] or category
    if not cat or not cat.Panel then return end
    
    local scrollFrame = cat.Panel:FindFirstChild("Content")
    
    local pickerFrame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        ClipsDescendants = true,
        Parent = scrollFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("UIStroke", {
            Color = self.Settings.BorderColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 0, 35),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        Font = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = pickerFrame
    })
    
    local colorPreview = CreateInstance("Frame", {
        Name = "Preview",
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -35, 0.5, -12.5),
        BackgroundColor3 = default,
        Parent = pickerFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 5)}),
        CreateInstance("UIStroke", {
            Color = Color3.new(1, 1, 1),
            Thickness = 1,
            Transparency = 0.5
        })
    })
    
    -- Expanded picker
    local expanded = false
    local expandedHeight = 180
    
    local pickerContent = CreateInstance("Frame", {
        Name = "PickerContent",
        Size = UDim2.new(1, -10, 0, 140),
        Position = UDim2.new(0, 5, 0, 38),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = pickerFrame
    })
    
    -- Color wheel (simplified as a grid)
    local colorWheel = CreateInstance("ImageLabel", {
        Name = "Wheel",
        Size = UDim2.new(0, 100, 0, 100),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Image = "rbxassetid://4155801252",
        Parent = pickerContent
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local wheelCursor = CreateInstance("Frame", {
        Name = "Cursor",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0.5, -5, 0.5, -5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = colorWheel
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0)}),
        CreateInstance("UIStroke", {
            Color = Color3.new(0, 0, 0),
            Thickness = 2
        })
    })
    
    -- Brightness slider
    local brightnessBar = CreateInstance("Frame", {
        Name = "Brightness",
        Size = UDim2.new(0, 15, 0, 100),
        Position = UDim2.new(0, 115, 0, 0),
        Parent = pickerContent
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)),
            Rotation = 90
        })
    })
    
    local brightnessCursor = CreateInstance("Frame", {
        Name = "Cursor",
        Size = UDim2.new(1, 4, 0, 5),
        Position = UDim2.new(-0.15, 0, 0, -2.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = brightnessBar
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 2)}),
        CreateInstance("UIStroke", {
            Color = Color3.new(0, 0, 0),
            Thickness = 1
        })
    })
    
    -- Preset colors
    local presetColors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(127, 0, 255),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(128, 128, 128),
        Color3.fromRGB(0, 0, 0),
        Color3.fromRGB(147, 112, 219)
    }
    
    local presetFrame = CreateInstance("Frame", {
        Name = "Presets",
        Size = UDim2.new(0, 50, 0, 100),
        Position = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        Parent = pickerContent
    }, {
        CreateInstance("UIGridLayout", {
            CellSize = UDim2.new(0, 22, 0, 22),
            CellPadding = UDim2.new(0, 3, 0, 3)
        })
    })
    
    for _, color in ipairs(presetColors) do
        local preset = CreateInstance("TextButton", {
            Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = color,
            Text = "",
            Parent = presetFrame
        }, {
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        preset.MouseButton1Click:Connect(function()
            currentColor = color
            colorPreview.BackgroundColor3 = color
            callback(color)
        end)
    end
    
    -- Hex input
    local hexInput = CreateInstance("TextBox", {
        Name = "HexInput",
        Size = UDim2.new(1, -10, 0, 25),
        Position = UDim2.new(0, 5, 0, 108),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        Text = "#" .. default:ToHex():upper(),
        TextColor3 = self.Settings.TextColor,
        TextSize = 12,
        Font = self.Settings.Font,
        Parent = pickerContent
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)})
    })
    
    local currentColor = default
    local h, s, v = default:ToHSV()
    
    -- Click to expand/collapse
    local clickButton = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "",
        Parent = pickerFrame
    })
    
    clickButton.MouseButton1Click:Connect(function()
        expanded = not expanded
        pickerContent.Visible = expanded
        
        local targetSize = expanded and UDim2.new(1, 0, 0, expandedHeight) or UDim2.new(1, 0, 0, 35)
        CreateTween(pickerFrame, {Size = targetSize}):Play()
        
        PlaySound()
    end)
    
    -- Color wheel interaction
    local wheelDragging = false
    
    colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if wheelDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = Vector2.new(input.Position.X, input.Position.Y)
            local wheelPos = Vector2.new(colorWheel.AbsolutePosition.X, colorWheel.AbsolutePosition.Y)
            local wheelSize = Vector2.new(colorWheel.AbsoluteSize.X, colorWheel.AbsoluteSize.Y)
            local center = wheelPos + wheelSize / 2
            
            local relative = (pos - center) / (wheelSize / 2)
            local distance = math.min(relative.Magnitude, 1)
            local angle = math.atan2(relative.Y, relative.X)
            
            h = (angle + math.pi) / (2 * math.pi)
            s = distance
            
            currentColor = Color3.fromHSV(h, s, v)
            colorPreview.BackgroundColor3 = currentColor
            hexInput.Text = "#" .. currentColor:ToHex():upper()
            
            local cursorX = 0.5 + math.cos(angle) * distance * 0.5
            local cursorY = 0.5 + math.sin(angle) * distance * 0.5
            wheelCursor.Position = UDim2.new(cursorX, -5, cursorY, -5)
            
            callback(currentColor)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = false
        end
    end)
    
    -- Brightness bar interaction
    local brightnessDragging = false
    
    brightnessBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            brightnessDragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if brightnessDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeY = math.clamp((input.Position.Y - brightnessBar.AbsolutePosition.Y) / brightnessBar.AbsoluteSize.Y, 0, 1)
            v = 1 - relativeY
            
            currentColor = Color3.fromHSV(h, s, v)
            colorPreview.BackgroundColor3 = currentColor
            hexInput.Text = "#" .. currentColor:ToHex():upper()
            brightnessCursor.Position = UDim2.new(-0.15, 0, relativeY, -2.5)
            
            callback(currentColor)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            brightnessDragging = false
        end
    end)
    
    -- Hex input handling
    hexInput.FocusLost:Connect(function()
        local text = hexInput.Text:gsub("#", "")
        local success, color = pcall(function()
            return Color3.fromHex(text)
        end)
        
        if success then
            currentColor = color
            colorPreview.BackgroundColor3 = color
            h, s, v = color:ToHSV()
            callback(color)
        else
            hexInput.Text = "#" .. currentColor:ToHex():upper()
        end
    end)
    
    local element = {
        Name = name,
        Type = "ColorPicker",
        Frame = pickerFrame,
        Value = currentColor,
        SetValue = function(self, color)
            currentColor = color
            self.Value = color
            colorPreview.BackgroundColor3 = color
            hexInput.Text = "#" .. color:ToHex():upper()
            h, s, v = color:ToHSV()
        end,
        GetValue = function(self)
            return currentColor
        end
    }
    
    table.insert(cat.Elements, element)
    table.insert(self.AllElements, element)
    
    return element
end

function VapeUI:AddSubCategory(category, options)
    local options = options or {}
    local name = options.Name or "Sub Category"
    local icon = options.Icon or "▸"
    
    local cat = type(category) == "string" and self.Categories[category] or category
    if not cat or not cat.Panel then return end
    
    local scrollFrame = cat.Panel:FindFirstChild("Content")
    
    local subFrame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        ClipsDescendants = true,
        Parent = scrollFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)}),
        CreateInstance("UIStroke", {
            Color = self.Settings.BorderColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local header = CreateInstance("TextButton", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "",
        Parent = subFrame
    })
    
    local iconLabel = CreateInstance("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 20, 0, 35),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = icon,
        TextColor3 = self.Settings.MainColor,
        TextSize = 14,
        Font = self.Settings.Font,
        Parent = subFrame
    })
    
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -60, 0, 35),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        Font = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = subFrame
    })
    
    local arrow = CreateInstance("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 0, 35),
        Position = UDim2.new(1, -25, 0, 0),
        BackgroundTransparency = 1,
        Text = "▾",
        TextColor3 = self.Settings.TextColor,
        TextSize = 12,
        Font = self.Settings.Font,
        Rotation = -90,
        Parent = subFrame
    })
    
    local content = CreateInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 5, 0, 38),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = subFrame
    }, {
        CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3)
        })
    })
    
    local subCategory = {
        Name = name,
        Frame = subFrame,
        Content = content,
        Elements = {},
        Expanded = false
    }
    
    local function updateSize()
        local listLayout = content:FindFirstChild("UIListLayout")
        local contentHeight = listLayout and listLayout.AbsoluteContentSize.Y or 0
        local targetHeight = subCategory.Expanded and (40 + contentHeight + 10) or 35
        
        CreateTween(subFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
        CreateTween(content, {Size = UDim2.new(1, -10, 0, contentHeight)}):Play()
        CreateTween(arrow, {Rotation = subCategory.Expanded and 0 or -90}):Play()
    end
    
    header.MouseButton1Click:Connect(function()
        subCategory.Expanded = not subCategory.Expanded
        updateSize()
        PlaySound()
    end)
    
    -- Methods to add elements to subcategory
    subCategory.AddButton = function(self, options)
        local element = VapeUI:CreateSubElement("Button", self.Content, options)
        table.insert(self.Elements, element)
        task.wait()
        updateSize()
        return element
    end
    
    subCategory.AddSlider = function(self, options)
        local element = VapeUI:CreateSubElement("Slider", self.Content, options)
        table.insert(self.Elements, element)
        task.wait()
        updateSize()
        return element
    end
    
    table.insert(cat.SubCategories, subCategory)
    
    return subCategory
end

function VapeUI:CreateSubElement(elementType, parent, options)
    -- Simplified element creation for subcategories
    local options = options or {}
    
    if elementType == "Button" then
        local buttonFrame = CreateInstance("Frame", {
            Name = options.Name or "Button",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            Parent = parent
        }, {
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        local button = CreateInstance("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = options.Name or "Button",
            TextColor3 = self.Settings.TextColor,
            TextSize = 11,
            Font = self.Settings.Font,
            Parent = buttonFrame
        })
        
        local toggled = options.Default or false
        
        button.MouseButton1Click:Connect(function()
            toggled = not toggled
            buttonFrame.BackgroundColor3 = toggled and self.Settings.MainColor or Color3.fromRGB(45, 45, 55)
            if options.Callback then options.Callback(toggled) end
            PlaySound()
        end)
        
        return {Name = options.Name, Type = "Button", Frame = buttonFrame, Value = toggled}
    elseif elementType == "Slider" then
        -- Similar to main slider but compact
        local sliderFrame = CreateInstance("Frame", {
            Name = options.Name or "Slider",
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            Parent = parent
        }, {
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        return {Name = options.Name, Type = "Slider", Frame = sliderFrame}
    end
end

function VapeUI:SearchCategory(category, query)
    query = query:lower()
    
    for _, element in ipairs(category.Elements) do
        if element.Frame then
            local visible = query == "" or element.Name:lower():find(query)
            element.Frame.Visible = visible
        end
    end
end

function VapeUI:SearchAll(query)
    query = query:lower()
    
    for _, element in ipairs(self.AllElements) do
        if element.Frame then
            local visible = query == "" or element.Name:lower():find(query)
            element.Frame.Visible = visible
        end
    end
end

function VapeUI:CreateSettingsCategory()
    local settings = self:AddCategory("Settings", "⚙")
    
    -- Wait for panel to be created
    task.spawn(function()
        repeat task.wait() until settings.Panel
        
        local scrollFrame = settings.Panel:FindFirstChild("Content")
        
        -- UI Settings Section
        local uiSection = CreateInstance("Frame", {
            Name = "UISection",
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundTransparency = 1,
            Parent = scrollFrame
        })
        
        local sectionLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "UI Settings",
            TextColor3 = self.Settings.MainColor,
            TextSize = 12,
            Font = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = uiSection
        })
        
        -- Theme Color
        self:AddColorPicker(settings, {
            Name = "Theme Color",
            Default = self.Settings.MainColor,
            Callback = function(color)
                self.Settings.MainColor = color
                self:UpdateTheme()
            end
        })
        
        -- Background Color
        self:AddColorPicker(settings, {
            Name = "Background Color",
            Default = self.Settings.BackgroundColor,
            Callback = function(color)
                self.Settings.BackgroundColor = color
                self:UpdateTheme()
            end
        })
        
        -- Border Color
        self:AddColorPicker(settings, {
            Name = "Border Color",
            Default = self.Settings.BorderColor,
            Callback = function(color)
                self.Settings.BorderColor = color
                self:UpdateTheme()
            end
        })
        
        -- Config Section
        local configSection = CreateInstance("Frame", {
            Name = "ConfigSection",
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundTransparency = 1,
            LayoutOrder = 100,
            Parent = scrollFrame
        })
        
        CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "Config",
            TextColor3 = self.Settings.MainColor,
            TextSize = 12,
            Font = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = configSection
        })
        
        -- Save Config Button
        self:AddButton(settings, {
            Name = "Save Config",
            Callback = function(enabled)
                if enabled then
                    self:SaveConfig("default")
                    self:FlashScreen()
                end
            end
        }).Frame.LayoutOrder = 101
        
        -- Load Config Button
        self:AddButton(settings, {
            Name = "Load Config",
            Callback = function(enabled)
                if enabled then
                    self:LoadConfig("default")
                    self:FlashScreen()
                    PlaySound("rbxassetid://6026984224")
                end
            end
        }).Frame.LayoutOrder = 102
        
        -- Auto Load Toggle
        self:AddButton(settings, {
            Name = "Auto Load Config",
            Callback = function(enabled)
                self.AutoLoadConfig = enabled
            end
        }).Frame.LayoutOrder = 103
        
        -- Author Info Section
        local authorSection = CreateInstance("Frame", {
            Name = "AuthorSection",
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(35, 35, 45),
            LayoutOrder = 200,
            Parent = scrollFrame
        }, {
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 5),
            BackgroundTransparency = 1,
            Text = "Script by: " .. self.AuthorInfo,
            TextColor3 = self.Settings.TextColor,
            TextSize = 11,
            Font = self.Settings.Font,
            Parent = authorSection
        })
        
        CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 25),
            BackgroundTransparency = 1,
            Text = "UI Library by: log_quick",
            TextColor3 = self.Settings.AccentColor,
            TextSize = 11,
            Font = self.Settings.Font,
            Parent = authorSection
        })
        
        CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 15),
            Position = UDim2.new(0, 0, 0, 42),
            BackgroundTransparency = 1,
            Text = "v1.0.0",
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = 10,
            Font = self.Settings.Font,
            Parent = authorSection
        })
    end)
end

function VapeUI:UpdateTheme()
    -- Update main button
    self.MainButton.BackgroundColor3 = self.Settings.MainColor
    self.MainButtonGlow.ImageColor3 = self.Settings.MainColor
    
    -- Update main menu
    self.MainMenu.BackgroundColor3 = self.Settings.BackgroundColor
    local stroke = self.MainMenu:FindFirstChild("UIStroke")
    if stroke then stroke.Color = self.Settings.BorderColor end
    
    -- Update all panels
    for _, panel in pairs(self.ActivePanels) do
        panel.BackgroundColor3 = self.Settings.BackgroundColor
        local panelStroke = panel:FindFirstChild("UIStroke")
        if panelStroke then panelStroke.Color = self.Settings.BorderColor end
        
        local header = panel:FindFirstChild("Header")
        if header then
            header.BackgroundColor3 = self.Settings.MainColor
            local bottomCover = header:FindFirstChild("BottomCover")
            if bottomCover then bottomCover.BackgroundColor3 = self.Settings.MainColor end
        end
    end
end

function VapeUI:FlashScreen()
    local flash = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Settings.MainColor,
        BackgroundTransparency = 0.8,
        ZIndex = 100,
        Parent = self.ScreenGui
    })
    
    local tween = CreateTween(flash, {BackgroundTransparency = 1}, 0.5)
    tween:Play()
    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

function VapeUI:SaveConfig(name)
    local config = {
        Settings = self.Settings,
        Elements = {}
    }
    
    for _, element in ipairs(self.AllElements) do
        if element.GetValue then
            local value = element:GetValue()
            if typeof(value) == "Color3" then
                value = {R = value.R, G = value.G, B = value.B, Type = "Color3"}
            end
            config.Elements[element.Name] = value
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    
    if success then
        if writefile then
            writefile(self.ConfigFolder .. "/" .. name .. ".json", encoded)
        end
        print("[VapeUI] Config saved: " .. name)
    end
end

function VapeUI:LoadConfig(name)
    local success, content = pcall(function()
        if readfile then
            return readfile(self.ConfigFolder .. "/" .. name .. ".json")
        end
    end)
    
    if success and content then
        local config = HttpService:JSONDecode(content)
        
        -- Load settings
        if config.Settings then
            for key, value in pairs(config.Settings) do
                if typeof(value) == "table" and value.Type == "Color3" then
                    self.Settings[key] = Color3.new(value.R, value.G, value.B)
                else
                    self.Settings[key] = value
                end
            end
            self:UpdateTheme()
        end
        
        -- Load element values
        if config.Elements then
            for _, element in ipairs(self.AllElements) do
                local value = config.Elements[element.Name]
                if value ~= nil and element.SetValue then
                    if typeof(value) == "table" and value.Type == "Color3" then
                        value = Color3.new(value.R, value.G, value.B)
                    end
                    element:SetValue(value)
                end
            end
        end
        
        print("[VapeUI] Config loaded: " .. name)
    end
end

function VapeUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    if self.BlurEffect then
        self.BlurEffect:Destroy()
    end
end

return VapeUI
