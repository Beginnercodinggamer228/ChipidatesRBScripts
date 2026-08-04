-- RGLib (Roblox GUI Library) v2.1
-- Исправленная версия с корректными UDim2

local RGLib = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ===================== КОНФИГУРАЦИЯ =====================
local Config = {
    UseRBXHumb = true,
    Animations = true,
    AnimationSpeed = 0.25,
    SmoothScrolling = true,
}

-- ===================== ХРАНИЛИЩЕ =====================
local ActiveGUIs = {}
local IsLibraryActive = true
local Connections = {}

-- ===================== ТЕМА =====================
local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    BackgroundSecondary = Color3.fromRGB(28, 28, 34),
    BackgroundTertiary = Color3.fromRGB(38, 38, 46),
    
    Accent = Color3.fromRGB(100, 180, 255),
    AccentDark = Color3.fromRGB(70, 140, 220),
    AccentLight = Color3.fromRGB(140, 210, 255),
    
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 190, 200),
    TextMuted = Color3.fromRGB(120, 130, 140),
    
    Success = Color3.fromRGB(80, 220, 100),
    Warning = Color3.fromRGB(255, 200, 60),
    Error = Color3.fromRGB(255, 80, 80),
    Info = Color3.fromRGB(80, 180, 255),
    
    GradientStart = Color3.fromRGB(30, 30, 40),
    GradientEnd = Color3.fromRGB(20, 20, 28),
    
    Transparency = {
        Main = 0.92,
        Secondary = 0.85,
        Tertiary = 0.75,
        Hover = 0.5,
        Pressed = 0.3,
        Disabled = 0.95,
    },
    
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontSemiBold = Enum.Font.GothamSemibold,
    
    FontSize = {
        Small = 12,
        Medium = 14,
        Large = 16,
        Title = 20,
        Header = 24,
    },
    
    CornerRadius = {
        Small = UDim.new(0, 4),
        Medium = UDim.new(0, 8),
        Large = UDim.new(0, 12),
        Circle = UDim.new(1, 0),
    },
}

-- ===================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====================

local function CreateCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius.Medium
    corner.Parent = instance
    return corner
end

local function CreateStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.BackgroundTertiary
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = instance
    return stroke
end

local function CreateGradient(instance, color1, color2, direction)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1 or Theme.GradientStart),
        ColorSequenceKeypoint.new(1, color2 or Theme.GradientEnd),
    })
    gradient.Rotation = direction or 45
    gradient.Parent = instance
    return gradient
end

-- ===================== ИСПРАВЛЕННАЯ ФУНКЦИЯ ТЕНИ =====================
local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 12, 1, 12) -- Исправлено: UDim2 вместо UDim
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxhumb://shadow.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.Parent = parent
    shadow.ZIndex = 0
    return shadow
end

local function TweenObject(object, properties, duration, style, direction)
    if not Config.Animations then
        for prop, value in pairs(properties) do
            object[prop] = value
        end
        return
    end
    
    local tweenInfo = TweenInfo.new(
        duration or Config.AnimationSpeed,
        Enum.EasingStyle[style or "Quad"],
        Enum.EasingDirection[direction or "Out"]
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function ConnectSafe(event, callback)
    local connection = event:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

-- ===================== ИСПРАВЛЕННАЯ ФУНКЦИЯ ИКОНОК =====================
local function CreateIcon(parent, iconName, size, color)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = size or UDim2.new(0, 20, 0, 20)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxhumb://" .. iconName .. ".png"
    icon.ImageColor3 = color or Theme.TextSecondary
    icon.Parent = parent
    return icon
end

-- ===================== ОСНОВНОЙ КЛАСС ОКНА =====================

function RGLib:NewWindow(title, options)
    if not IsLibraryActive then
        error("Библиотека RGLib была выгружена!")
        return nil
    end
    
    options = options or {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = options.Name or "RGLibGUI"
    screenGui.Parent = options.Parent or LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = options.IgnoreGuiInset or true
    
    table.insert(ActiveGUIs, screenGui)
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = options.Size or UDim2.new(0, 550, 0, 450)
    mainFrame.Position = options.Position or UDim2.new(0.5, -275, 0.5, -225)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BackgroundTransparency = Theme.Transparency.Main
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.ClipsDescendants = true
    
    -- Тень (исправлено)
    local shadow = CreateShadow(mainFrame)
    
    local mainCorner = CreateCorner(mainFrame, Theme.CornerRadius.Large)
    local mainStroke = CreateStroke(mainFrame, Theme.BackgroundTertiary, 1, 0.3)
    local mainGradient = CreateGradient(mainFrame, Theme.GradientStart, Theme.GradientEnd, 135)
    
    -- ===================== ЗАГОЛОВОК =====================
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Theme.BackgroundSecondary
    titleBar.BackgroundTransparency = Theme.Transparency.Secondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleBarCorner = CreateCorner(titleBar, Theme.CornerRadius.Large)
    local titleBarCorner2 = Instance.new("UICorner")
    titleBarCorner2.CornerRadius = Theme.CornerRadius.Medium
    titleBarCorner2.Parent = titleBar
    
    local titleSeparator = Instance.new("Frame")
    titleSeparator.Name = "Separator"
    titleSeparator.Size = UDim2.new(1, -20, 0, 1)
    titleSeparator.Position = UDim2.new(0, 10, 1, 0)
    titleSeparator.BackgroundColor3 = Theme.BackgroundTertiary
    titleSeparator.BackgroundTransparency = 0.5
    titleSeparator.BorderSizePixel = 0
    titleSeparator.Parent = titleBar
    
    if options.Icon then
        local titleIcon = CreateIcon(titleBar, options.Icon, UDim2.new(0, 24, 0, 24), Theme.Accent)
        titleIcon.Position = UDim2.new(0, 15, 0.5, -12)
        titleIcon.ZIndex = 2
    end
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -110, 1, 0)
    titleLabel.Position = UDim2.new(0, options.Icon and 50 or 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "RGLib Window"
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = Theme.FontSize.Title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Theme.FontBold
    titleLabel.Parent = titleBar
    
    -- ===================== КНОПКИ УПРАВЛЕНИЯ =====================
    local buttonSize = UDim2.new(0, 30, 0, 30)
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = buttonSize
    closeButton.Position = UDim2.new(1, -45, 0.5, -15)
    closeButton.BackgroundColor3 = Theme.Error
    closeButton.BackgroundTransparency = 0.8
    closeButton.Text = "✕"
    closeButton.TextColor3 = Theme.TextPrimary
    closeButton.TextSize = 18
    closeButton.Font = Theme.Font
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    closeButton.ZIndex = 2
    
    local closeCorner = CreateCorner(closeButton, Theme.CornerRadius.Circle)
    
    ConnectSafe(closeButton.MouseEnter, function()
        TweenObject(closeButton, {BackgroundTransparency = 0.2}, 0.15)
        TweenObject(closeButton, {Size = UDim2.new(0, 32, 0, 32)}, 0.15)
    end)
    
    ConnectSafe(closeButton.MouseLeave, function()
        TweenObject(closeButton, {BackgroundTransparency = 0.8}, 0.15)
        TweenObject(closeButton, {Size = UDim2.new(0, 30, 0, 30)}, 0.15)
    end)
    
    ConnectSafe(closeButton.MouseButton1Click, function()
        TweenObject(mainFrame, {BackgroundTransparency = 1}, 0.3)
        TweenObject(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.35)
        screenGui:Destroy()
        
        for i, gui in pairs(ActiveGUIs) do
            if gui == screenGui then
                table.remove(ActiveGUIs, i)
                break
            end
        end
    end)
    
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = buttonSize
    minimizeButton.Position = UDim2.new(1, -85, 0.5, -15)
    minimizeButton.BackgroundColor3 = Theme.Warning
    minimizeButton.BackgroundTransparency = 0.8
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = Theme.TextPrimary
    minimizeButton.TextSize = 24
    minimizeButton.Font = Theme.Font
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = titleBar
    minimizeButton.ZIndex = 2
    
    local minCorner = CreateCorner(minimizeButton, Theme.CornerRadius.Circle)
    
    ConnectSafe(minimizeButton.MouseEnter, function()
        TweenObject(minimizeButton, {BackgroundTransparency = 0.2}, 0.15)
        TweenObject(minimizeButton, {Size = UDim2.new(0, 32, 0, 32)}, 0.15)
    end)
    
    ConnectSafe(minimizeButton.MouseLeave, function()
        TweenObject(minimizeButton, {BackgroundTransparency = 0.8}, 0.15)
        TweenObject(minimizeButton, {Size = UDim2.new(0, 30, 0, 30)}, 0.15)
    end)
    
    local isMinimized = false
    ConnectSafe(minimizeButton.MouseButton1Click, function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenObject(mainFrame, {Size = UDim2.new(0, 550, 0, 50)}, 0.3)
            minimizeButton.Text = "□"
        else
            TweenObject(mainFrame, {Size = options.Size or UDim2.new(0, 550, 0, 450)}, 0.3)
            minimizeButton.Text = "−"
        end
    end)
    
    -- ===================== КОНТЕЙНЕР ВКЛАДОК =====================
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None
    tabScroll.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Name = "TabLayout"
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabScroll
    
    -- ===================== КОНТЕЙНЕР СОДЕРЖИМОГО =====================
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -100)
    contentContainer.Position = UDim2.new(0, 10, 0, 90)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- ===================== СИСТЕМА ВКЛАДОК =====================
    local tabs = {}
    local currentTab = nil
    
    function RGLib:CreateTab(name, icon)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local tabContainer = Instance.new("Frame")
        tabContainer.Name = name .. "Tab"
        tabContainer.Size = UDim2.new(1, 0, 1, 0)
        tabContainer.BackgroundTransparency = 1
        tabContainer.Parent = contentContainer
        tabContainer.Visible = false
        
        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = "ScrollFrame"
        tabScroll.Size = UDim2.new(1, 0, 1, -5)
        tabScroll.Position = UDim2.new(0, 0, 0, 5)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 4
        tabScroll.ScrollBarImageColor3 = Theme.Accent
        tabScroll.ScrollBarImageTransparency = 0.5
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabScroll.Parent = tabContainer
        
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Name = "Layout"
        tabLayout.Padding = UDim.new(0, 8)
        tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabScroll
        
        local tabData = {
            Container = tabContainer,
            Scroll = tabScroll,
            Layout = tabLayout,
            Elements = {},
            Name = name,
            Icon = icon or "",
        }
        
        table.insert(tabs, tabData)
        
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. name
        tabButton.Size = UDim2.new(0, 0, 1, -8)
        tabButton.Position = UDim2.new(0, 0, 0, 4)
        tabButton.BackgroundTransparency = 1
        tabButton.Text = icon and icon .. " " .. name or name
        tabButton.TextColor3 = Theme.TextMuted
        tabButton.TextSize = Theme.FontSize.Medium
        tabButton.Font = Theme.FontSemiBold
        tabButton.BorderSizePixel = 0
        tabButton.Parent = tabScroll
        tabButton.AutoButtonColor = false
        
        local tabIndicator = Instance.new("Frame")
        tabIndicator.Name = "Indicator"
        tabIndicator.Size = UDim2.new(0.8, 0, 0, 3)
        tabIndicator.Position = UDim2.new(0.1, 0, 1, -3)
        tabIndicator.BackgroundColor3 = Theme.Accent
        tabIndicator.BackgroundTransparency = 1
        tabIndicator.BorderSizePixel = 0
        tabIndicator.Parent = tabButton
        
        local indicatorCorner = CreateCorner(tabIndicator, Theme.CornerRadius.Small)
        
        ConnectSafe(tabButton.MouseEnter, function()
            if currentTab ~= tabData then
                TweenObject(tabButton, {TextColor3 = Theme.TextSecondary}, 0.2)
            end
        end)
        
        ConnectSafe(tabButton.MouseLeave, function()
            if currentTab ~= tabData then
                TweenObject(tabButton, {TextColor3 = Theme.TextMuted}, 0.2)
            end
        end)
        
        ConnectSafe(tabButton.MouseButton1Click, function()
            RGLib:SelectTab(tabData)
        end)
        
        tabData.Button = tabButton
        tabData.Indicator = tabIndicator
        
        local function UpdateButtonSize()
            local textSize = tabButton.TextBounds.X + 30
            tabButton.Size = UDim2.new(0, math.max(textSize, 60), 1, -8)
        end
        UpdateButtonSize()
        tabButton:GetPropertyChangedSignal("Text"):Connect(UpdateButtonSize)
        
        local function UpdateTabScroll()
            local totalWidth = 0
            for _, child in pairs(tabScroll:GetChildren()) do
                if child:IsA("TextButton") and child.Name:match("Tab_") then
                    totalWidth = totalWidth + child.Size.X.Offset + 5
                end
            end
            tabScroll.CanvasSize = UDim2.new(0, totalWidth + 10, 0, 0)
        end
        
        tabScroll:GetPropertyChangedSignal("CanvasSize"):Connect(UpdateTabScroll)
        task.wait()
        UpdateTabScroll()
        
        if #tabs == 1 then
            RGLib:SelectTab(tabData)
        end
        
        return tabData
    end
    
    function RGLib:SelectTab(tabData)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return
        end
        
        for _, tab in pairs(tabs) do
            tab.Container.Visible = false
            tab.Button.TextColor3 = Theme.TextMuted
            TweenObject(tab.Indicator, {BackgroundTransparency = 1}, 0.2)
        end
        
        tabData.Container.Visible = true
        tabData.Button.TextColor3 = Theme.Accent
        TweenObject(tabData.Indicator, {BackgroundTransparency = 0}, 0.2)
        currentTab = tabData
    end
    
    -- ===================== СОЗДАНИЕ ЭЛЕМЕНТОВ =====================
    
    local function CreateCard(parent, size)
        local card = Instance.new("Frame")
        card.Name = "Card"
        card.Size = size or UDim2.new(0.95, 0, 0, 50)
        card.BackgroundColor3 = Theme.BackgroundSecondary
        card.BackgroundTransparency = Theme.Transparency.Secondary
        card.BorderSizePixel = 0
        card.Parent = parent
        
        local cardCorner = CreateCorner(card, Theme.CornerRadius.Medium)
        local cardStroke = CreateStroke(card, Theme.BackgroundTertiary, 1, 0.3)
        
        return card
    end
    
    function RGLib:CreateButton(tab, text, callback, icon)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local card = CreateCard(tab.Scroll, UDim2.new(0.95, 0, 0, 45))
        
        local button = Instance.new("TextButton")
        button.Name = "Button_" .. text
        button.Size = UDim2.new(1, -20, 1, -8)
        button.Position = UDim2.new(0, 10, 0, 4)
        button.BackgroundColor3 = Theme.Accent
        button.BackgroundTransparency = 0.85
        button.Text = text
        button.TextColor3 = Theme.TextPrimary
        button.TextSize = Theme.FontSize.Medium
        button.Font = Theme.FontSemiBold
        button.BorderSizePixel = 0
        button.Parent = card
        button.AutoButtonColor = false
        
        local buttonCorner = CreateCorner(button, Theme.CornerRadius.Medium)
        local buttonStroke = CreateStroke(button, Theme.Accent, 1, 0.3)
        
        if icon then
            local btnIcon = CreateIcon(button, icon, UDim2.new(0, 18, 0, 18), Theme.TextPrimary)
            btnIcon.Position = UDim2.new(0, 15, 0.5, -9)
            btnIcon.ZIndex = 2
            button.Text = "  " .. text
        end
        
        ConnectSafe(button.MouseEnter, function()
            TweenObject(button, {BackgroundTransparency = 0.4}, 0.2)
            TweenObject(buttonStroke, {Transparency = 0.1}, 0.2)
            TweenObject(button, {Size = UDim2.new(1, -16, 1, -4)}, 0.2)
        end)
        
        ConnectSafe(button.MouseLeave, function()
            TweenObject(button, {BackgroundTransparency = 0.85}, 0.2)
            TweenObject(buttonStroke, {Transparency = 0.3}, 0.2)
            TweenObject(button, {Size = UDim2.new(1, -20, 1, -8)}, 0.2)
        end)
        
        ConnectSafe(button.MouseButton1Click, function()
            if callback then 
                local success, err = pcall(callback)
                if not success then
                    RGLib:Notify("Ошибка: " .. err, 3, "error")
                end
            end
            
            TweenObject(button, {BackgroundTransparency = 0.6}, 0.1)
            TweenObject(button, {Size = UDim2.new(1, -24, 1, -12)}, 0.1)
            task.wait(0.1)
            TweenObject(button, {BackgroundTransparency = 0.85}, 0.1)
            TweenObject(button, {Size = UDim2.new(1, -20, 1, -8)}, 0.1)
        end)
        
        table.insert(tab.Elements, card)
        RGLib:UpdateCanvas(tab)
        return button
    end
    
    function RGLib:CreateInput(tab, placeholder, callback, multiline)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local height = multiline and 80 or 45
        local card = CreateCard(tab.Scroll, UDim2.new(0.95, 0, 0, height))
        
        local input = Instance.new("TextBox")
        input.Name = "Input"
        input.Size = UDim2.new(1, -20, 1, -8)
        input.Position = UDim2.new(0, 10, 0, 4)
        input.BackgroundColor3 = Theme.Background
        input.BackgroundTransparency = Theme.Transparency.Tertiary
        input.PlaceholderText = placeholder or "Введите текст..."
        input.Text = ""
        input.TextColor3 = Theme.TextPrimary
        input.TextSize = Theme.FontSize.Medium
        input.Font = Theme.Font
        input.BorderSizePixel = 0
        input.MultiLine = multiline or false
        input.Parent = card
        
        local inputCorner = CreateCorner(input, Theme.CornerRadius.Medium)
        local inputStroke = CreateStroke(input, Theme.BackgroundTertiary, 1, 0.3)
        
        local inputIcon = CreateIcon(input, "search", UDim2.new(0, 16, 0, 16), Theme.TextMuted)
        inputIcon.Position = UDim2.new(0, 10, 0.5, -8)
        inputIcon.ZIndex = 2
        input.PlaceholderText = "  " .. (placeholder or "Введите текст...")
        input.TextXAlignment = Enum.TextXAlignment.Left
        
        ConnectSafe(input.Focused, function()
            TweenObject(input, {BackgroundTransparency = 0.4}, 0.2)
            TweenObject(inputStroke, {Color = Theme.Accent, Transparency = 0.1}, 0.2)
        end)
        
        ConnectSafe(input.FocusLost, function()
            TweenObject(input, {BackgroundTransparency = Theme.Transparency.Tertiary}, 0.2)
            TweenObject(inputStroke, {Color = Theme.BackgroundTertiary, Transparency = 0.3}, 0.2)
            if callback and input.Text ~= "" then
                pcall(callback, input.Text)
            end
        end)
        
        table.insert(tab.Elements, card)
        RGLib:UpdateCanvas(tab)
        return input
    end
    
    function RGLib:CreateCheckbox(tab, text, default, callback, description)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local card = CreateCard(tab.Scroll, UDim2.new(0.95, 0, 0, description and 65 or 45))
        
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, -20, 1, -8)
        container.Position = UDim2.new(0, 10, 0, 4)
        container.BackgroundTransparency = 1
        container.Parent = card
        
        local checkbox = Instance.new("TextButton")
        checkbox.Name = "Checkbox"
        checkbox.Size = UDim2.new(0, 26, 0, 26)
        checkbox.Position = UDim2.new(0, 0, 0.5, -13)
        checkbox.BackgroundColor3 = default and Theme.Accent or Theme.Background
        checkbox.BackgroundTransparency = default and 0.3 or Theme.Transparency.Tertiary
        checkbox.Text = default and "✓" or ""
        checkbox.TextColor3 = Theme.TextPrimary
        checkbox.TextSize = 18
        checkbox.Font = Theme.FontBold
        checkbox.BorderSizePixel = 0
        checkbox.Parent = container
        checkbox.AutoButtonColor = false
        
        local checkCorner = CreateCorner(checkbox, Theme.CornerRadius.Small)
        local checkStroke = CreateStroke(checkbox, default and Theme.Accent or Theme.BackgroundTertiary, 2, default and 0.3 or 0.5)
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -35, 0, description and 20 or 30)
        label.Position = UDim2.new(0, 35, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text or "Checkbox"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = Theme.FontSize.Medium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Theme.FontSemiBold
        label.Parent = container
        
        if description then
            local desc = Instance.new("TextLabel")
            desc.Name = "Description"
            desc.Size = UDim2.new(1, -35, 0, 20)
            desc.Position = UDim2.new(0, 35, 0, 25)
            desc.BackgroundTransparency = 1
            desc.Text = description
            desc.TextColor3 = Theme.TextMuted
            desc.TextSize = Theme.FontSize.Small
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Font = Theme.Font
            desc.Parent = container
        end
        
        local checked = default or false
        
        local function ToggleCheckbox()
            checked = not checked
            checkbox.Text = checked and "✓" or ""
            TweenObject(checkbox, {
                BackgroundColor3 = checked and Theme.Accent or Theme.Background,
                BackgroundTransparency = checked and 0.3 or Theme.Transparency.Tertiary
            }, 0.2)
            TweenObject(checkStroke, {
                Color = checked and Theme.Accent or Theme.BackgroundTertiary,
                Transparency = checked and 0.3 or 0.5
            }, 0.2)
            if callback then pcall(callback, checked) end
            
            TweenObject(checkbox, {Size = UDim2.new(0, 30, 0, 30)}, 0.1)
            task.wait(0.1)
            TweenObject(checkbox, {Size = UDim2.new(0, 26, 0, 26)}, 0.1)
        end
        
        ConnectSafe(checkbox.MouseButton1Click, ToggleCheckbox)
        ConnectSafe(label.MouseButton1Click, ToggleCheckbox)
        
        ConnectSafe(checkbox.MouseEnter, function()
            TweenObject(checkbox, {BackgroundTransparency = checked and 0.15 or 0.4}, 0.2)
        end)
        ConnectSafe(checkbox.MouseLeave, function()
            TweenObject(checkbox, {BackgroundTransparency = checked and 0.3 or Theme.Transparency.Tertiary}, 0.2)
        end)
        
        table.insert(tab.Elements, card)
        RGLib:UpdateCanvas(tab)
        return checkbox
    end
    
    -- ===================== ИСПРАВЛЕННЫЙ СЛАЙДЕР =====================
    function RGLib:CreateSlider(tab, text, min, max, default, callback, format)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        min = min or 0
        max = max or 100
        default = math.clamp(default or 50, min, max)
        format = format or function(v) return tostring(math.round(v)) end
        
        local card = CreateCard(tab.Scroll, UDim2.new(0.95, 0, 0, 65))
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.7, 0, 0, 22)
        label.Position = UDim2.new(0, 15, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text or "Slider"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = Theme.FontSize.Medium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Theme.FontSemiBold
        label.Parent = card
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0.3, -20, 0, 22)
        valueLabel.Position = UDim2.new(0.7, 5, 0, 5)
        valueLabel.BackgroundColor3 = Theme.Background
        valueLabel.BackgroundTransparency = Theme.Transparency.Tertiary
        valueLabel.Text = format(default)
        valueLabel.TextColor3 = Theme.Accent
        valueLabel.TextSize = Theme.FontSize.Medium
        valueLabel.Font = Theme.FontBold
        valueLabel.Parent = card
        
        local valCorner = CreateCorner(valueLabel, Theme.CornerRadius.Small)
        
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Size = UDim2.new(1, -30, 0, 6)
        sliderTrack.Position = UDim2.new(0, 15, 0, 40)
        sliderTrack.BackgroundColor3 = Theme.Background
        sliderTrack.BackgroundTransparency = Theme.Transparency.Tertiary
        sliderTrack.BorderSizePixel = 0
        sliderTrack.Parent = card
        
        local trackCorner = CreateCorner(sliderTrack, Theme.CornerRadius.Circle)
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.Accent
        sliderFill.BackgroundTransparency = 0.2
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderTrack
        
        local fillCorner = CreateCorner(sliderFill, Theme.CornerRadius.Circle)
        
        local sliderButton = Instance.new("TextButton")
        sliderButton.Name = "SliderButton"
        sliderButton.Size = UDim2.new(0, 18, 0, 18)
        sliderButton.Position = UDim2.new((default - min) / (max - min), -9, 0, -6)
        sliderButton.BackgroundColor3 = Theme.Accent
        sliderButton.Text = ""
        sliderButton.BorderSizePixel = 0
        sliderButton.Parent = card
        sliderButton.AutoButtonColor = false
        
        local buttonCorner = CreateCorner(sliderButton, Theme.CornerRadius.Circle)
        local buttonStroke = CreateStroke(sliderButton, Theme.AccentLight, 2, 0.2)
        
        local buttonShadow = Instance.new("Frame")
        buttonShadow.Name = "Shadow"
        buttonShadow.Size = UDim2.new(1, 6, 1, 6)
        buttonShadow.Position = UDim2.new(0, -3, 0, -3)
        buttonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        buttonShadow.BackgroundTransparency = 0.5
        buttonShadow.BorderSizePixel = 0
        buttonShadow.Parent = sliderButton
        buttonShadow.ZIndex = 0
        
        local shadowCorner = CreateCorner(buttonShadow, Theme.CornerRadius.Circle)
        
        local value = default
        local dragging = false
        
        local function UpdateSlider(newValue)
            value = math.clamp(newValue, min, max)
            local percent = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderButton.Position = UDim2.new(percent, -9, 0, -6)
            valueLabel.Text = format(value)
            if callback then pcall(callback, value) end
        end
        
        local function GetSliderValue(mouseX)
            local absX = sliderTrack.AbsolutePosition.X
            local width = sliderTrack.AbsoluteSize.X
            if width == 0 then return value end
            local percent = math.clamp((mouseX - absX) / width, 0, 1)
            return min + (max - min) * percent
        end
        
        ConnectSafe(sliderButton.MouseButton1Down, function()
            dragging = true
            TweenObject(sliderButton, {Size = UDim2.new(0, 22, 0, 22)}, 0.15)
            TweenObject(buttonStroke, {Thickness = 3}, 0.15)
        end)
        
        ConnectSafe(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                dragging = false
                TweenObject(sliderButton, {Size = UDim2.new(0, 18, 0, 18)}, 0.15)
                TweenObject(buttonStroke, {Thickness = 2}, 0.15)
            end
        end)
        
        ConnectSafe(sliderButton.MouseEnter, function()
            TweenObject(sliderButton, {Size = UDim2.new(0, 22, 0, 22)}, 0.15)
            TweenObject(buttonStroke, {Thickness = 3}, 0.15)
        end)
        
        ConnectSafe(sliderButton.MouseLeave, function()
            if not dragging then
                TweenObject(sliderButton, {Size = UDim2.new(0, 18, 0, 18)}, 0.15)
                TweenObject(buttonStroke, {Thickness = 2}, 0.15)
            end
        end)
        
        ConnectSafe(sliderTrack.MouseButton1Click, function()
            local mouseX = Mouse.X
            UpdateSlider(GetSliderValue(mouseX))
        end)
        
        ConnectSafe(Mouse.Move, function()
            if dragging then
                UpdateSlider(GetSliderValue(Mouse.X))
            end
        end)
        
        UpdateSlider(default)
        
        table.insert(tab.Elements, card)
        RGLib:UpdateCanvas(tab)
        return sliderButton
    end
    
    function RGLib:CreateDropdown(tab, text, options, default, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local card = CreateCard(tab.Scroll, UDim2.new(0.95, 0, 0, 50))
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.35, 0, 1, -8)
        label.Position = UDim2.new(0, 10, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = text or "Выберите:"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = Theme.FontSize.Medium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Theme.FontSemiBold
        label.Parent = card
        
        local dropdown = Instance.new("TextButton")
        dropdown.Name = "Dropdown"
        dropdown.Size = UDim2.new(0.6, -10, 1, -8)
        dropdown.Position = UDim2.new(0.38, 5, 0, 4)
        dropdown.BackgroundColor3 = Theme.Background
        dropdown.BackgroundTransparency = Theme.Transparency.Tertiary
        dropdown.Text = default or "Выберите..."
        dropdown.TextColor3 = Theme.TextSecondary
        dropdown.TextSize = Theme.FontSize.Medium
        dropdown.TextXAlignment = Enum.TextXAlignment.Left
        dropdown.Font = Theme.Font
        dropdown.BorderSizePixel = 0
        dropdown.Parent = card
        dropdown.AutoButtonColor = false
        
        local dropCorner = CreateCorner(dropdown, Theme.CornerRadius.Medium)
        local dropStroke = CreateStroke(dropdown, Theme.BackgroundTertiary, 1, 0.3)
        
        local dropdownArrow = Instance.new("TextLabel")
        dropdownArrow.Name = "Arrow"
        dropdownArrow.Size = UDim2.new(0, 25, 1, 0)
        dropdownArrow.Position = UDim2.new(1, -30, 0, 0)
        dropdownArrow.BackgroundTransparency = 1
        dropdownArrow.Text = "▼"
        dropdownArrow.TextColor3 = Theme.TextMuted
        dropdownArrow.TextSize = 14
        dropdownArrow.Font = Theme.Font
        dropdownArrow.Parent = dropdown
        
        local dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Name = "List"
        dropdownList.Size = UDim2.new(1, 0, 0, 0)
        dropdownList.Position = UDim2.new(0, 0, 1, 2)
        dropdownList.BackgroundColor3 = Theme.BackgroundSecondary
        dropdownList.BackgroundTransparency = Theme.Transparency.Secondary
        dropdownList.BorderSizePixel = 0
        dropdownList.ScrollBarThickness = 3
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
        dropdownList.Visible = false
        dropdownList.Parent = dropdown
        dropdownList.ZIndex = 10
        
        local listCorner = CreateCorner(dropdownList, Theme.CornerRadius.Medium)
        local listStroke = CreateStroke(dropdownList, Theme.BackgroundTertiary, 1, 0.5)
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Name = "Layout"
        listLayout.Padding = UDim.new(0, 2)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = dropdownList
        
        local isOpen = false
        local selected = default
        
        local function UpdateDropdownList()
            for _, child in pairs(dropdownList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            local canvasHeight = 0
            for i, option in pairs(options) do
                local item = Instance.new("TextButton")
                item.Name = "Item_" .. option
                item.Size = UDim2.new(1, -10, 0, 32)
                item.Position = UDim2.new(0, 5, 0, canvasHeight)
                item.BackgroundTransparency = 0.8
                item.Text = option
                item.TextColor3 = option == selected and Theme.Accent or Theme.TextSecondary
                item.TextSize = Theme.FontSize.Medium
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.Font = option == selected and Theme.FontBold or Theme.Font
                item.BorderSizePixel = 0
                item.Parent = dropdownList
                item.ZIndex = 11
                
                local itemCorner = CreateCorner(item, Theme.CornerRadius.Small)
                
                ConnectSafe(item.MouseEnter, function()
                    TweenObject(item, {BackgroundTransparency = 0.4}, 0.15)
                end)
                
                ConnectSafe(item.MouseLeave, function()
                    TweenObject(item, {BackgroundTransparency = 0.8}, 0.15)
                end)
                
                ConnectSafe(item.MouseButton1Click, function()
                    selected = option
                    dropdown.Text = option
                    dropdown.TextColor3 = Theme.TextPrimary
                    if callback then pcall(callback, option) end
                    dropdownList.Visible = false
                    isOpen = false
                    dropdownArrow.Text = "▼"
                    TweenObject(dropdown, {BackgroundTransparency = Theme.Transparency.Tertiary}, 0.15)
                    UpdateDropdownList()
                end)
                
                canvasHeight = canvasHeight + 34
            end
            
            dropdownList.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
            local maxHeight = math.min(canvasHeight, 200)
            dropdownList.Size = UDim2.new(1, 0, 0, maxHeight)
        end
        
        UpdateDropdownList()
        
        ConnectSafe(dropdown.MouseButton1Click, function()
            isOpen = not isOpen
            dropdownList.Visible = isOpen
            dropdownArrow.Text = isOpen and "▲" or "▼"
            if isOpen then
                dropdownList.ZIndex = 20
                TweenObject(dropdown, {BackgroundTransparency = 0.2}, 0.15)
            else
                TweenObject(dropdown, {BackgroundTransparency = Theme.Transparency.Tertiary}, 0.15)
            end
        end)
        
        ConnectSafe(UserInputService.InputBegin, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                local absPos = dropdownList.AbsolutePosition
                local absSize = dropdownList.AbsoluteSize
                if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                        mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                    dropdownList.Visible = false
                    isOpen = false
                    dropdownArrow.Text = "▼"
                    TweenObject(dropdown, {BackgroundTransparency = Theme.Transparency.Tertiary}, 0.15)
                end
            end
        end)
        
        table.insert(tab.Elements, card)
        RGLib:UpdateCanvas(tab)
        return dropdown
    end
    
    function RGLib:CreateSeparator(tab, text)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local container = Instance.new("Frame")
        container.Name = "SeparatorContainer"
        container.Size = UDim2.new(0.95, 0, 0, 35)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = Theme.BackgroundTertiary
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.Parent = container
        
        if text then
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(0, 200, 1, 0)
            label.Position = UDim2.new(0.5, -100, 0, 0)
            label.BackgroundColor3 = Theme.Background
            label.BackgroundTransparency = Theme.Transparency.Main
            label.Text = text
            label.TextColor3 = Theme.TextMuted
            label.TextSize = Theme.FontSize.Small
            label.Font = Theme.FontSemiBold
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Parent = container
            label.ZIndex = 2
            
            line.ZIndex = 1
        end
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return container
    end
    
    -- ===================== ОБНОВЛЕНИЕ КАНВАСА =====================
    function RGLib:UpdateCanvas(tab)
        local totalHeight = 0
        for _, element in pairs(tab.Elements) do
            totalHeight = totalHeight + element.Size.Y.Offset + 8
        end
        tab.Scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
    end
    
    -- ===================== УВЕДОМЛЕНИЯ =====================
    function RGLib:Notify(message, duration, type)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return
        end
        
        duration = duration or 3
        type = type or "info"
        
        local tempGui = Instance.new("ScreenGui")
        tempGui.Name = "RGNotify"
        tempGui.Parent = LocalPlayer.PlayerGui
        tempGui.ResetOnSpawn = false
        tempGui.IgnoreGuiInset = true
        
        table.insert(ActiveGUIs, tempGui)
        
        local colors = {
            info = Theme.Info,
            success = Theme.Success,
            error = Theme.Error,
            warning = Theme.Warning,
        }
        local color = colors[type] or Theme.Info
        
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Size = UDim2.new(0, 350, 0, 60)
        notification.Position = UDim2.new(1, -370, 0, 20)
        notification.BackgroundColor3 = Theme.BackgroundSecondary
        notification.BackgroundTransparency = Theme.Transparency.Secondary
        notification.BorderSizePixel = 0
        notification.Parent = tempGui
        
        local notCorner = CreateCorner(notification, Theme.CornerRadius.Medium)
        local notStroke = CreateStroke(notification, Theme.BackgroundTertiary, 1, 0.5)
        
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 4, 1, 0)
        indicator.BackgroundColor3 = color
        indicator.BackgroundTransparency = 0.3
        indicator.BorderSizePixel = 0
        indicator.Parent = notification
        
        local indCorner = CreateCorner(indicator, Theme.CornerRadius.Small)
        
        local icons = {
            info = "info",
            success = "check",
            error = "error",
            warning = "warning",
        }
        local iconName = icons[type] or "info"
        local icon = CreateIcon(notification, iconName, UDim2.new(0, 20, 0, 20), color)
        icon.Position = UDim2.new(0, 15, 0.5, -10)
        icon.ZIndex = 2
        
        local text = Instance.new("TextLabel")
        text.Name = "Text"
        text.Size = UDim2.new(1, -55, 1, 0)
        text.Position = UDim2.new(0, 45, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = message
        text.TextColor3 = Theme.TextPrimary
        text.TextSize = Theme.FontSize.Medium
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextWrapped = true
        text.Font = Theme.Font
        text.Parent = notification
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "Close"
        closeBtn.Size = UDim2.new(0, 24, 0, 24)
        closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Theme.TextMuted
        closeBtn.TextSize = 14
        closeBtn.Font = Theme.Font
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = notification
        closeBtn.ZIndex = 2
        
        ConnectSafe(closeBtn.MouseEnter, function()
            TweenObject(closeBtn, {TextColor3 = Theme.TextPrimary}, 0.2)
        end)
        ConnectSafe(closeBtn.MouseLeave, function()
            TweenObject(closeBtn, {TextColor3 = Theme.TextMuted}, 0.2)
        end)
        
        ConnectSafe(closeBtn.MouseButton1Click, function()
            TweenObject(notification, {Position = UDim2.new(1, -370, 0, -100)}, 0.3)
            task.wait(0.35)
            for i, gui in pairs(ActiveGUIs) do
                if gui == tempGui then
                    table.remove(ActiveGUIs, i)
                    break
                end
            end
            tempGui:Destroy()
        end)
        
        notification.Position = UDim2.new(1, -370, 0, -100)
        TweenObject(notification, {Position = UDim2.new(1, -370, 0, 20)}, 0.4)
        
        task.wait(duration)
        TweenObject(notification, {Position = UDim2.new(1, -370, 0, -100)}, 0.4)
        task.wait(0.4)
        for i, gui in pairs(ActiveGUIs) do
            if gui == tempGui then
                table.remove(ActiveGUIs, i)
                break
            end
        end
        tempGui:Destroy()
    end
    
    -- ===================== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ =====================
    
    function RGLib:ToggleVisibility(visible)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return
        end
        mainFrame.Visible = (visible ~= nil) and visible or not mainFrame.Visible
    end
    
    function RGLib:Show()
        RGLib:ToggleVisibility(true)
    end
    
    function RGLib:Hide()
        RGLib:ToggleVisibility(false)
    end
    
    -- ===================== API ОКНА =====================
    local windowAPI = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentContainer = contentContainer,
        Elements = {},
        Tabs = tabs,
        
        CreateTab = RGLib.CreateTab,
        CreateButton = RGLib.CreateButton,
        CreateInput = RGLib.CreateInput,
        CreateCheckbox = RGLib.CreateCheckbox,
        CreateSlider = RGLib.CreateSlider,
        CreateDropdown = RGLib.CreateDropdown,
        CreateSeparator = RGLib.CreateSeparator,
        Notify = RGLib.Notify,
        SelectTab = RGLib.SelectTab,
        UpdateCanvas = RGLib.UpdateCanvas,
        
        ToggleVisibility = RGLib.ToggleVisibility,
        Show = RGLib.Show,
        Hide = RGLib.Hide,
        
        Destroy = function()
            TweenObject(mainFrame, {BackgroundTransparency = 1}, 0.3)
            TweenObject(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
            task.wait(0.35)
            screenGui:Destroy()
            for i, gui in pairs(ActiveGUIs) do
                if gui == screenGui then
                    table.remove(ActiveGUIs, i)
                    break
                end
            end
        end,
        
        SetSize = function(size)
            TweenObject(mainFrame, {Size = size}, 0.3)
        end,
        
        SetPosition = function(position)
            TweenObject(mainFrame, {Position = position}, 0.3)
        end,
        
        SetTitle = function(title)
            titleLabel.Text = title
        end,
        
        SetTheme = function(newTheme)
            for key, value in pairs(newTheme) do
                Theme[key] = value
            end
        end,
    }
    
    return windowAPI
end

-- ===================== ГЛОБАЛЬНЫЕ ФУНКЦИИ =====================

function RGLib:Notify(message, duration, type)
    if not IsLibraryActive then
        error("Библиотека RGLib была выгружена!")
        return
    end
    
    local tempGui = Instance.new("ScreenGui")
    tempGui.Name = "RGNotify"
    tempGui.Parent = LocalPlayer.PlayerGui
    tempGui.ResetOnSpawn = false
    tempGui.IgnoreGuiInset = true
    
    table.insert(ActiveGUIs, tempGui)
    
    local colors = {
        info = Theme.Info,
        success = Theme.Success,
        error = Theme.Error,
        warning = Theme.Warning,
    }
    local color = colors[type] or Theme.Info
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 60)
    notification.Position = UDim2.new(1, -370, 0, 20)
    notification.BackgroundColor3 = Theme.BackgroundSecondary
    notification.BackgroundTransparency = Theme.Transparency.Secondary
    notification.BorderSizePixel = 0
    notification.Parent = tempGui
    
    local notCorner = CreateCorner(notification, Theme.CornerRadius.Medium)
    local notStroke = CreateStroke(notification, Theme.BackgroundTertiary, 1, 0.5)
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 4, 1, 0)
    indicator.BackgroundColor3 = color
    indicator.BackgroundTransparency = 0.3
    indicator.BorderSizePixel = 0
    indicator.Parent = notification
    
    local indCorner = CreateCorner(indicator, Theme.CornerRadius.Small)
    
    local icons = {
        info = "info",
        success = "check",
        error = "error",
        warning = "warning",
    }
    local iconName = icons[type] or "info"
    local icon = CreateIcon(notification, iconName, UDim2.new(0, 20, 0, 20), color)
    icon.Position = UDim2.new(0, 15, 0.5, -10)
    icon.ZIndex = 2
    
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -55, 1, 0)
    text.Position = UDim2.new(0, 45, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Theme.TextPrimary
    text.TextSize = Theme.FontSize.Medium
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Font = Theme.Font
    text.Parent = notification
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextMuted
    closeBtn.TextSize = 14
    closeBtn.Font = Theme.Font
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = notification
    closeBtn.ZIndex = 2
    
    ConnectSafe(closeBtn.MouseEnter, function()
        TweenObject(closeBtn, {TextColor3 = Theme.TextPrimary}, 0.2)
    end)
    ConnectSafe(closeBtn.MouseLeave, function()
        TweenObject(closeBtn, {TextColor3 = Theme.TextMuted}, 0.2)
    end)
    
    ConnectSafe(closeBtn.MouseButton1Click, function()
        TweenObject(notification, {Position = UDim2.new(1, -370, 0, -100)}, 0.3)
        task.wait(0.35)
        for i, gui in pairs(ActiveGUIs) do
            if gui == tempGui then
                table.remove(ActiveGUIs, i)
                break
            end
        end
        tempGui:Destroy()
    end)
    
    notification.Position = UDim2.new(1, -370, 0, -100)
    TweenObject(notification, {Position = UDim2.new(1, -370, 0, 20)}, 0.4)
    
    task.wait(duration or 3)
    TweenObject(notification, {Position = UDim2.new(1, -370, 0, -100)}, 0.4)
    task.wait(0.4)
    for i, gui in pairs(ActiveGUIs) do
        if gui == tempGui then
            table.remove(ActiveGUIs, i)
            break
        end
    end
    tempGui:Destroy()
end

-- ===================== ПОЛНАЯ ВЫГРУЗКА =====================
function RGLib:KillMain()
    if not IsLibraryActive then
        return
    end
    
    print("[RGLib] Начинается выгрузка библиотеки...")
    
    for _, connection in pairs(Connections) do
        if connection and connection.Disconnect then
            pcall(connection.Disconnect, connection)
        end
    end
    Connections = {}
    
    for i = #ActiveGUIs, 1, -1 do
        local gui = ActiveGUIs[i]
        if gui and gui.Parent then
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("Frame") or child:IsA("TextButton") or 
                   child:IsA("TextLabel") or child:IsA("ImageLabel") then
                    pcall(function()
                        TweenObject(child, {BackgroundTransparency = 1}, 0.2)
                        if child:IsA("ImageLabel") then
                            TweenObject(child, {ImageTransparency = 1}, 0.2)
                        end
                    end)
                end
            end
            task.wait(0.2)
            pcall(gui.Destroy, gui)
        end
        table.remove(ActiveGUIs, i)
    end
    
    ActiveGUIs = {}
    IsLibraryActive = false
    
    local function DisableTable(tbl)
        for key, value in pairs(tbl) do
            if type(value) == "function" then
                tbl[key] = function()
                    error("Библиотека RGLib была выгружена! Используйте loadstring для перезагрузки.")
                end
            elseif type(value) == "table" then
                DisableTable(value)
            end
        end
    end
    
    DisableTable(RGLib)
    
    if _G.RGLib then
        _G.RGLib = nil
    end
    
    print("[RGLib] Библиотека полностью выгружена!")
end

return RGLib
