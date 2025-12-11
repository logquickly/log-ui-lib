--[[ 
    Vape-Like UI Library Implementation
    Style: Minimalist Dark / Vape V4 Inspiration
    Author: AI Assistant
    Version: 1.0.0
    
    Note: extensive logic for UI handling, animations, and input management.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

--/// CORE LIBRARY TABLE ///--
local Library = {
    Flags = {},
    Theme = {
        Main = Color3.fromRGB(24, 24, 24),
        Secondary = Color3.fromRGB(32, 32, 32),
        Accent = Color3.fromRGB(100, 255, 100), -- Vape Green
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Stroke = Color3.fromRGB(60, 60, 60)
    },
    Folder = "VapeCloneConfig",
    GuiKeybind = Enum.KeyCode.RightShift
}

--/// UTILITY FUNCTIONS ///--
local function Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

local function Tween(instance, info, propertyTable)
    local tween = TweenService:Create(instance, TweenInfo.new(unpack(info)), propertyTable)
    tween:Play()
    return tween
end

--/// CONFIG SYSTEM ///--
function Library:SaveConfig(name)
    local json = HttpService:JSONEncode(Library.Flags)
    if writefile then
        if not isfolder(Library.Folder) then makefolder(Library.Folder) end
        writefile(Library.Folder .. "/" .. name .. ".json", json)
    else
        print("[Config] Saved (Simulator):", json)
    end
end

function Library:LoadConfig(name)
    if readfile and isfile(Library.Folder .. "/" .. name .. ".json") then
        local json = readfile(Library.Folder .. "/" .. name .. ".json")
        local data = HttpService:JSONDecode(json)
        for flag, value in pairs(data) do
            if Library.Flags[flag] then
                Library.Flags[flag](value) -- Trigger callback
            end
        end
    else
        print("[Config] Cannot load or file missing.")
    end
end

--/// UI CONSTRUCTION ///--

function Library:Window(options)
    local Title = options.Name or "Vape Copy"
    local BgImage = options.BackgroundImage or nil -- Custom UI Background Interface
    
    -- Main ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "VapeUI",
        Parent = game.CoreGui or LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Library.Theme.Main,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = true
    })
    
    -- Custom Background Handling
    if BgImage then
        local ImageBg = Create("ImageLabel", {
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Image = BgImage,
            Size = UDim2.new(1,0,1,0),
            ZIndex = 0,
            ImageTransparency = 0.8
        })
    end

    local UICorner = Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 6)})
    
    -- Sidebar (Tabs)
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = MainFrame,
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 150, 1, 0)
    })
    local SidebarList = Create("UIListLayout", {
        Parent = Sidebar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    local SidebarPadding = Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0,10)})
    
    -- Title Text
    local TitleLabel = Create("TextLabel", {
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Text = Title,
        TextColor3 = Library.Theme.Accent,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        LayoutOrder = -1
    })

    -- Content Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 50), -- Offset for Search Bar
        Size = UDim2.new(1, -170, 1, -60)
    })

    -- Search Bar Interface
    local SearchFrame = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 160, 0, 10),
        Size = UDim2.new(1, -170, 0, 30)
    })
    Create("UICorner", {Parent = SearchFrame, CornerRadius = UDim.new(0,4)})
    
    local SearchBox = Create("TextBox", {
        Parent = SearchFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        PlaceholderText = "Search features...",
        Text = "",
        TextColor3 = Library.Theme.Text,
        PlaceholderColor3 = Library.Theme.TextDark,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Global Search Logic
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local input = SearchBox.Text:lower()
        for _, page in pairs(ContentArea:GetChildren()) do
            if page:IsA("ScrollingFrame") then
                for _, element in pairs(page:GetChildren()) do
                    if element:IsA("Frame") and element:FindFirstChild("Title") then
                        if string.find(element.Title.Text:lower(), input) then
                            element.Visible = true
                        else
                            element.Visible = false
                        end
                    end
                end
            end
        end
    end)

    MakeDraggable(Sidebar, MainFrame)

    -- Toggle UI Keybind
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Library.GuiKeybind then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    -- Window Methods
    local WindowFunctions = {}
    local FirstTab = true

    function WindowFunctions:Tab(name)
        -- Tab Button
        local TabButton = Create("TextButton", {
            Parent = Sidebar,
            BackgroundColor3 = Library.Theme.Main,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 0),
            Text = name,
            TextColor3 = Library.Theme.TextDark,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            AutoButtonColor = false
        })
        
        -- Tab Content Page
        local TabPage = Create("ScrollingFrame", {
            Name = name .. "_Page",
            Parent = ContentArea,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        })
        local TabList = Create("UIListLayout", {
            Parent = TabPage,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
        
        -- Auto Canvas Resize
        TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 10)
        end)

        -- Tab Selection Logic
        if FirstTab then
            TabButton.TextColor3 = Library.Theme.Text
            TabPage.Visible = true
            FirstTab = false
        end

        TabButton.MouseButton1Click:Connect(function()
            -- Reset all tabs
            for _, v in pairs(ContentArea:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(Sidebar:GetChildren()) do if v:IsA("TextButton") then Tween(v, {0.2}, {TextColor3 = Library.Theme.TextDark}) end end
            
            -- Activate current
            TabPage.Visible = true
            Tween(TabButton, {0.2}, {TextColor3 = Library.Theme.Text})
        end)

        local TabFunctions = {}

        --/// COMPONENT: SECTION ///--
        function TabFunctions:Section(text)
            local SectionFrame = Create("Frame", {
                Parent = TabPage,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 25)
            })
            local Label = Create("TextLabel", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                Text = text,
                TextColor3 = Library.Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        --/// COMPONENT: BUTTON ///--
        function TabFunctions:Button(text, callback)
            callback = callback or function() end
            
            local ButtonFrame = Create("Frame", {
                Name = "Button_"..text,
                Parent = TabPage,
                BackgroundColor3 = Library.Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35)
            })
            Create("UICorner", {Parent = ButtonFrame, CornerRadius = UDim.new(0,4)})
            
            local Title = Create("TextLabel", {
                Name = "Title",
                Parent = ButtonFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Text = text,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local BtnClick = Create("TextButton", {
                Parent = ButtonFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            BtnClick.MouseButton1Click:Connect(function()
                Tween(ButtonFrame, {0.1}, {BackgroundColor3 = Library.Theme.Stroke})
                wait(0.1)
                Tween(ButtonFrame, {0.1}, {BackgroundColor3 = Library.Theme.Secondary})
                pcall(callback)
            end)
        end

        --/// COMPONENT: TOGGLE ///--
        function TabFunctions:Toggle(text, default, callback)
            local toggled = default or false
            local ToggleFrame = Create("Frame", {
                Name = "Toggle_"..text,
                Parent = TabPage,
                BackgroundColor3 = Library.Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35)
            })
            Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0,4)})

            local Title = Create("TextLabel", {
                Name = "Title",
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Text = text,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Indicator = Create("Frame", {
                Parent = ToggleFrame,
                BackgroundColor3 = toggled and Library.Theme.Accent or Library.Theme.Main,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10)
            })
            Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1,0)})
            
            local Circle = Create("Frame", {
                Parent = Indicator,
                BackgroundColor3 = Color3.new(1,1,1),
                Size = UDim2.new(0, 16, 0, 16),
                Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            })
            Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1,0)})

            local BtnClick = Create("TextButton", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            local function UpdateToggle()
                Tween(Indicator, {0.2}, {BackgroundColor3 = toggled and Library.Theme.Accent or Library.Theme.Main})
                Tween(Circle, {0.2}, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                pcall(callback, toggled)
                Library.Flags[text] = toggled
            end

            BtnClick.MouseButton1Click:Connect(function()
                toggled = not toggled
                UpdateToggle()
            end)
            
            -- Add to Flags for Config
            Library.Flags[text] = function(val) 
                toggled = val 
                UpdateToggle() 
            end
        end

        --/// COMPONENT: SLIDER ///--
        function TabFunctions:Slider(text, min, max, default, callback)
            local value = default or min
            local SliderFrame = Create("Frame", {
                Name = "Slider_"..text,
                Parent = TabPage,
                BackgroundColor3 = Library.Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 50)
            })
            Create("UICorner", {Parent = SliderFrame, CornerRadius = UDim.new(0,4)})

            local Title = Create("TextLabel", {
                Name = "Title",
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 10, 0, 0),
                Text = text,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 50, 0, 25),
                Position = UDim2.new(1, -60, 0, 0),
                Text = tostring(value),
                TextColor3 = Library.Theme.TextDark,
                Font = Enum.Font.Gotham,
                TextSize = 14
            })

            local SliderBar = Create("Frame", {
                Parent = SliderFrame,
                BackgroundColor3 = Library.Theme.Main,
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 30)
            })
            Create("UICorner", {Parent = SliderBar, CornerRadius = UDim.new(1,0)})

            local Fill = Create("Frame", {
                Parent = SliderBar,
                BackgroundColor3 = Library.Theme.Accent,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            })
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1,0)})

            local SliderBtn = Create("TextButton", {
                Parent = SliderBar,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            local dragging = false

            local function UpdateSlider(input)
                local pos = UDim2.new(math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
                Fill.Size = pos
                
                local result = math.floor(min + ((max - min) * pos.X.Scale))
                ValueLabel.Text = tostring(result)
                pcall(callback, result)
                Library.Flags[text] = result
            end

            SliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
        end

        --/// COMPONENT: DROPDOWN (Searchable) ///--
        function TabFunctions:Dropdown(text, options, callback)
            local DropdownFrame = Create("Frame", {
                Name = "Dropdown_"..text,
                Parent = TabPage,
                BackgroundColor3 = Library.Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35),
                ClipsDescendants = true
            })
            Create("UICorner", {Parent = DropdownFrame, CornerRadius = UDim.new(0,4)})

            local Title = Create("TextLabel", {
                Name = "Title",
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 0, 35),
                Position = UDim2.new(0, 10, 0, 0),
                Text = text .. "...",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local Arrow = Create("ImageLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Image = "rbxassetid://6034818372", -- Down Arrow
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0, 7)
            })

            local DropBtn = Create("TextButton", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Text = ""
            })

            local ListFrame = Create("ScrollingFrame", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                CanvasSize = UDim2.new(0,0,0,0),
                ScrollBarThickness = 2
            })
            local ListLayout = Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})
            
            ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ListFrame.CanvasSize = UDim2.new(0,0,0,ListLayout.AbsoluteContentSize.Y)
            end)

            local isOpen = false
            
            local function RefreshList()
                -- Clear old
                for _,v in pairs(ListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                
                -- Add new
                for _, opt in pairs(options) do
                    local Item = Create("TextButton", {
                        Parent = ListFrame,
                        BackgroundColor3 = Library.Theme.Secondary,
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = opt,
                        TextColor3 = Library.Theme.TextDark,
                        Font = Enum.Font.Gotham,
                        TextSize = 14
                    })
                    
                    Item.MouseButton1Click:Connect(function()
                        Title.Text = text .. ": " .. opt
                        callback(opt)
                        isOpen = false
                        Tween(DropdownFrame, {0.3}, {Size = UDim2.new(1, 0, 0, 35)})
                        Tween(Arrow, {0.3}, {Rotation = 0})
                    end)
                end
            end

            DropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    RefreshList()
                    Tween(DropdownFrame, {0.3}, {Size = UDim2.new(1, 0, 0, 150)})
                    Tween(Arrow, {0.3}, {Rotation = 180})
                else
                    Tween(DropdownFrame, {0.3}, {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, {0.3}, {Rotation = 0})
                end
            end)
        end
        
        --/// COMPONENT: COLOR PICKER (HSV) ///--
        function TabFunctions:ColorPicker(text, default, callback)
            local color = default or Color3.fromRGB(255, 255, 255)
            
            local PickerFrame = Create("Frame", {
                Name = "Color_"..text,
                Parent = TabPage,
                BackgroundColor3 = Library.Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35), -- Expanded by click
                ClipsDescendants = true
            })
            Create("UICorner", {Parent = PickerFrame, CornerRadius = UDim.new(0,4)})
            
            local Title = Create("TextLabel", {
                Name = "Title",
                Parent = PickerFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 0, 35),
                Position = UDim2.new(0, 10, 0, 0),
                Text = text,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ColorPreview = Create("Frame", {
                Parent = PickerFrame,
                BackgroundColor3 = color,
                Size = UDim2.new(0, 30, 0, 20),
                Position = UDim2.new(1, -40, 0, 7)
            })
            Create("UICorner", {Parent = ColorPreview, CornerRadius = UDim.new(0,4)})
            
            local OpenBtn = Create("TextButton", {
                Parent = PickerFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Text = ""
            })
            
            -- Color Logic UI
            local HueBar = Create("ImageButton", {
                Parent = PickerFrame,
                Image = "rbxassetid://4155801252", -- Rainbow bar
                Size = UDim2.new(1, -20, 0, 15),
                Position = UDim2.new(0, 10, 0, 40)
            })
            
            local isOpen = false
            
            -- Simple Hue Logic for size constraint (Full HSV requires CanvasGroup)
            OpenBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    Tween(PickerFrame, {0.3}, {Size = UDim2.new(1, 0, 0, 70)})
                else
                    Tween(PickerFrame, {0.3}, {Size = UDim2.new(1, 0, 0, 35)})
                end
            end)
            
            local draggingHue = false
            HueBar.InputBegan:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end 
            end)
            UserInputService.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false end 
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if draggingHue and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local hue = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    color = Color3.fromHSV(hue, 1, 1)
                    ColorPreview.BackgroundColor3 = color
                    callback(color)
                end
            end)
        end

        return TabFunctions
    end

    return WindowFunctions
end

return Library
