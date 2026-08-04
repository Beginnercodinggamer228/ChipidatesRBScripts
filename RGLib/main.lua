-- RGLib (Roblox GUI Library)
-- Многофункциональная библиотека для создания GUI
-- Версия 1.1

local RGLib = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Хранилище всех созданных GUI
local ActiveGUIs = {}
local IsLibraryActive = true

-- Настройки по умолчанию
local DefaultTheme = {
    BackgroundColor = Color3.fromRGB(30, 30, 35),
    BackgroundTransparency = 0.95,
    BorderColor = Color3.fromRGB(60, 60, 70),
    AccentColor = Color3.fromRGB(0, 120, 255),
    AccentHoverColor = Color3.fromRGB(0, 150, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    SecondaryTextColor = Color3.fromRGB(200, 200, 200),
    DangerColor = Color3.fromRGB(255, 50, 50),
    SuccessColor = Color3.fromRGB(50, 255, 50),
    WarningColor = Color3.fromRGB(255, 200, 50),
    Font = Enum.Font.Gotham,
    FontSize = 14,
    CornerRadius = UDim.new(0, 6),
}

-- Вспомогательные функции
local function CreateCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or DefaultTheme.CornerRadius
    corner.Parent = instance
    return corner
end

local function CreateStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or DefaultTheme.BorderColor
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end

local function TweenObject(object, properties, duration, style)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle[style or "Quad"],
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Основной класс окна
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
    
    -- Добавляем GUI в список активных
    table.insert(ActiveGUIs, screenGui)
    
    -- Главный фрейм (окно)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = options.Size or UDim2.new(0, 500, 0, 400)
    mainFrame.Position = options.Position or UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = options.BackgroundColor or DefaultTheme.BackgroundColor
    mainFrame.BackgroundTransparency = options.BackgroundTransparency or DefaultTheme.BackgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Тень
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.Parent = mainFrame
    shadow.ZIndex = 0
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 8)
    shadowCorner.Parent = shadow
    
    -- Главный угол
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = options.HeaderColor or Color3.fromRGB(40, 40, 45)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 8)
    titleBarCorner.Parent = titleBar
    
    -- Только верхние углы скруглены
    local titleBarCorner2 = Instance.new("UICorner")
    titleBarCorner2.CornerRadius = UDim.new(0, 0)
    titleBarCorner2.Parent = titleBar
    
    -- Заголовок текст
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "RGLib Window"
    titleLabel.TextColor3 = DefaultTheme.TextColor
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = DefaultTheme.Font
    titleLabel.Parent = titleBar
    
    -- Кнопка закрытия
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.BackgroundTransparency = 0.8
    closeButton.Text = "✕"
    closeButton.TextColor3 = DefaultTheme.TextColor
    closeButton.TextSize = 20
    closeButton.Font = DefaultTheme.Font
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseEnter:Connect(function()
        TweenObject(closeButton, {BackgroundTransparency = 0.2}, 0.2)
    end)
    closeButton.MouseLeave:Connect(function()
        TweenObject(closeButton, {BackgroundTransparency = 0.8}, 0.2)
    end)
    closeButton.MouseButton1Click:Connect(function()
        -- Удаляем GUI из списка активных при закрытии
        for i, gui in pairs(ActiveGUIs) do
            if gui == screenGui then
                table.remove(ActiveGUIs, i)
                break
            end
        end
        TweenObject(mainFrame, {BackgroundTransparency = 1}, 0.3)
        TweenObject(screenGui, {Enabled = false}, 0.3)
        task.wait(0.3)
        screenGui:Destroy()
    end)
    
    -- Кнопка минимизации
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -80, 0, 5)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    minimizeButton.BackgroundTransparency = 0.8
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = DefaultTheme.TextColor
    minimizeButton.TextSize = 24
    minimizeButton.Font = DefaultTheme.Font
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = minimizeButton
    
    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenObject(mainFrame, {Size = UDim2.new(0, 500, 0, 40)}, 0.3)
            minimizeButton.Text = "□"
        else
            TweenObject(mainFrame, {Size = options.Size or UDim2.new(0, 500, 0, 400)}, 0.3)
            minimizeButton.Text = "−"
        end
    end)
    
    -- Контейнер для содержимого
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -10, 1, -50)
    contentContainer.Position = UDim2.new(0, 5, 0, 45)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Список для хранения всех элементов
    local elements = {}
    local tabs = {}
    local currentTab = nil
    
    -- Создание вкладок
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
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 6
        tabScroll.ScrollBarImageColor3 = DefaultTheme.AccentColor
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
        
        -- Создание кнопки вкладки в заголовке
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. name
        tabButton.Size = UDim2.new(0, 80, 1, -10)
        tabButton.Position = UDim2.new(0, #tabs * 85 + 10, 0, 5)
        tabButton.BackgroundTransparency = 1
        tabButton.Text = icon and icon .. " " .. name or name
        tabButton.TextColor3 = DefaultTheme.SecondaryTextColor
        tabButton.TextSize = 14
        tabButton.Font = DefaultTheme.Font
        tabButton.BorderSizePixel = 0
        tabButton.Parent = titleBar
        tabButton.ZIndex = 10
        
        local tabIndicator = Instance.new("Frame")
        tabIndicator.Name = "Indicator"
        tabIndicator.Size = UDim2.new(0.8, 0, 0, 3)
        tabIndicator.Position = UDim2.new(0.1, 0, 1, -3)
        tabIndicator.BackgroundColor3 = DefaultTheme.AccentColor
        tabIndicator.BackgroundTransparency = 1
        tabIndicator.BorderSizePixel = 0
        tabIndicator.Parent = tabButton
        
        tabButton.MouseEnter:Connect(function()
            TweenObject(tabButton, {TextColor3 = DefaultTheme.TextColor}, 0.2)
        end)
        tabButton.MouseLeave:Connect(function()
            if currentTab ~= tabData then
                TweenObject(tabButton, {TextColor3 = DefaultTheme.SecondaryTextColor}, 0.2)
            end
        end)
        
        tabButton.MouseButton1Click:Connect(function()
            RGLib:SelectTab(tabData)
        end)
        
        tabData.Button = tabButton
        tabData.Indicator = tabIndicator
        
        -- Если это первая вкладка, делаем её активной
        if #tabs == 1 then
            RGLib:SelectTab(tabData)
        end
        
        return tabData
    end
    
    -- Выбор вкладки
    function RGLib:SelectTab(tabData)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return
        end
        
        for _, tab in pairs(tabs) do
            tab.Container.Visible = false
            tab.Button.TextColor3 = DefaultTheme.SecondaryTextColor
            TweenObject(tab.Indicator, {BackgroundTransparency = 1}, 0.2)
        end
        
        tabData.Container.Visible = true
        tabData.Button.TextColor3 = DefaultTheme.TextColor
        TweenObject(tabData.Indicator, {BackgroundTransparency = 0}, 0.2)
        currentTab = tabData
    end
    
    -- Создание кнопки
    function RGLib:CreateButton(tab, text, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local button = Instance.new("TextButton")
        button.Name = "Button_" .. text
        button.Size = UDim2.new(0.95, 0, 0, 40)
        button.BackgroundColor3 = DefaultTheme.AccentColor
        button.BackgroundTransparency = 0.2
        button.Text = text
        button.TextColor3 = DefaultTheme.TextColor
        button.TextSize = DefaultTheme.FontSize
        button.Font = DefaultTheme.Font
        button.BorderSizePixel = 0
        button.Parent = tab.Scroll
        
        local corner = CreateCorner(button, UDim.new(0, 4))
        local stroke = CreateStroke(button, DefaultTheme.AccentColor, 1)
        
        button.MouseEnter:Connect(function()
            TweenObject(button, {BackgroundTransparency = 0.05}, 0.2)
        end)
        button.MouseLeave:Connect(function()
            TweenObject(button, {BackgroundTransparency = 0.2}, 0.2)
        end)
        
        button.MouseButton1Click:Connect(function()
            if callback then callback() end
            TweenObject(button, {BackgroundTransparency = 0.5}, 0.1)
            task.wait(0.1)
            TweenObject(button, {BackgroundTransparency = 0.2}, 0.1)
        end)
        
        table.insert(tab.Elements, button)
        RGLib:UpdateCanvas(tab)
        return button
    end
    
    -- Создание поля ввода
    function RGLib:CreateInput(tab, placeholder, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local container = Instance.new("Frame")
        container.Name = "InputContainer"
        container.Size = UDim2.new(0.95, 0, 0, 45)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local input = Instance.new("TextBox")
        input.Name = "Input"
        input.Size = UDim2.new(1, 0, 1, 0)
        input.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        input.BackgroundTransparency = 0.3
        input.PlaceholderText = placeholder or "Введите текст..."
        input.Text = ""
        input.TextColor3 = DefaultTheme.TextColor
        input.TextSize = DefaultTheme.FontSize
        input.Font = DefaultTheme.Font
        input.BorderSizePixel = 0
        input.Parent = container
        
        local corner = CreateCorner(input, UDim.new(0, 4))
        local stroke = CreateStroke(input, DefaultTheme.BorderColor, 1)
        
        input.Focused:Connect(function()
            TweenObject(input, {BackgroundTransparency = 0.1}, 0.2)
            TweenObject(stroke, {Color = DefaultTheme.AccentColor}, 0.2)
        end)
        
        input.FocusLost:Connect(function()
            TweenObject(input, {BackgroundTransparency = 0.3}, 0.2)
            TweenObject(stroke, {Color = DefaultTheme.BorderColor}, 0.2)
            if callback then callback(input.Text) end
        end)
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return input
    end
    
    -- Создание чекбокса
    function RGLib:CreateCheckbox(tab, text, default, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local container = Instance.new("Frame")
        container.Name = "CheckboxContainer"
        container.Size = UDim2.new(0.95, 0, 0, 35)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local checkbox = Instance.new("TextButton")
        checkbox.Name = "Checkbox"
        checkbox.Size = UDim2.new(0, 24, 0, 24)
        checkbox.Position = UDim2.new(0, 5, 0, 5)
        checkbox.BackgroundColor3 = default and DefaultTheme.AccentColor or Color3.fromRGB(50, 50, 55)
        checkbox.BackgroundTransparency = 0.3
        checkbox.Text = default and "✓" or ""
        checkbox.TextColor3 = DefaultTheme.TextColor
        checkbox.TextSize = 18
        checkbox.Font = DefaultTheme.Font
        checkbox.BorderSizePixel = 0
        checkbox.Parent = container
        
        local corner = CreateCorner(checkbox, UDim.new(0, 4))
        local stroke = CreateStroke(checkbox, default and DefaultTheme.AccentColor or DefaultTheme.BorderColor, 1)
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -35, 1, 0)
        label.Position = UDim2.new(0, 35, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text or "Checkbox"
        label.TextColor3 = DefaultTheme.TextColor
        label.TextSize = DefaultTheme.FontSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = DefaultTheme.Font
        label.Parent = container
        
        local checked = default or false
        
        checkbox.MouseButton1Click:Connect(function()
            checked = not checked
            checkbox.Text = checked and "✓" or ""
            TweenObject(checkbox, {BackgroundColor3 = checked and DefaultTheme.AccentColor or Color3.fromRGB(50, 50, 55)}, 0.2)
            TweenObject(stroke, {Color = checked and DefaultTheme.AccentColor or DefaultTheme.BorderColor}, 0.2)
            if callback then callback(checked) end
        end)
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return checkbox
    end
    
    -- Создание слайдера
    function RGLib:CreateSlider(tab, text, min, max, default, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        min = min or 0
        max = max or 100
        default = default or 50
        
        local container = Instance.new("Frame")
        container.Name = "SliderContainer"
        container.Size = UDim2.new(0.95, 0, 0, 55)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(default)
        label.TextColor3 = DefaultTheme.TextColor
        label.TextSize = DefaultTheme.FontSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = DefaultTheme.Font
        label.Parent = container
        
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Size = UDim2.new(1, 0, 0, 8)
        sliderTrack.Position = UDim2.new(0, 0, 0, 30)
        sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        sliderTrack.BackgroundTransparency = 0.3
        sliderTrack.BorderSizePixel = 0
        sliderTrack.Parent = container
        
        local trackCorner = CreateCorner(sliderTrack, UDim.new(0, 4))
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = DefaultTheme.AccentColor
        sliderFill.BackgroundTransparency = 0.5
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderTrack
        
        local fillCorner = CreateCorner(sliderFill, UDim.new(0, 4))
        
        local sliderButton = Instance.new("TextButton")
        sliderButton.Name = "SliderButton"
        sliderButton.Size = UDim2.new(0, 20, 0, 20)
        sliderButton.Position = UDim2.new((default - min) / (max - min), -10, 0, -6)
        sliderButton.BackgroundColor3 = DefaultTheme.AccentColor
        sliderButton.Text = ""
        sliderButton.BorderSizePixel = 0
        sliderButton.Parent = container
        
        local buttonCorner = CreateCorner(sliderButton, UDim.new(0, 10))
        local buttonStroke = CreateStroke(sliderButton, DefaultTheme.AccentColor, 2)
        
        local value = default
        local dragging = false
        
        local function UpdateSlider(newValue)
            value = math.clamp(newValue, min, max)
            local percent = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderButton.Position = UDim2.new(percent, -10, 0, -6)
            label.Text = text .. ": " .. math.round(value)
            if callback then callback(value) end
        end
        
        sliderButton.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        sliderButton.MouseEnter:Connect(function()
            TweenObject(sliderButton, {Size = UDim2.new(0, 24, 0, 24)}, 0.2)
            TweenObject(buttonStroke, {Thickness = 3}, 0.2)
        end)
        
        sliderButton.MouseLeave:Connect(function()
            TweenObject(sliderButton, {Size = UDim2.new(0, 20, 0, 20)}, 0.2)
            TweenObject(buttonStroke, {Thickness = 2}, 0.2)
        end)
        
        Mouse.Move:Connect(function()
            if dragging then
                local mouseX = Mouse.X
                local absX = sliderTrack.AbsolutePosition.X
                local width = sliderTrack.AbsoluteSize.X
                local percent = math.clamp((mouseX - absX) / width, 0, 1)
                local newValue = min + (max - min) * percent
                UpdateSlider(newValue)
            end
        end)
        
        UpdateSlider(default)
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return sliderButton
    end
    
    -- Создание выпадающего списка
    function RGLib:CreateDropdown(tab, text, options, default, callback)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local container = Instance.new("Frame")
        container.Name = "DropdownContainer"
        container.Size = UDim2.new(0.95, 0, 0, 45)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text or "Выберите:"
        label.TextColor3 = DefaultTheme.TextColor
        label.TextSize = DefaultTheme.FontSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = DefaultTheme.Font
        label.Parent = container
        
        local dropdown = Instance.new("TextButton")
        dropdown.Name = "Dropdown"
        dropdown.Size = UDim2.new(0.6, 0, 1, 0)
        dropdown.Position = UDim2.new(0.4, 5, 0, 0)
        dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        dropdown.BackgroundTransparency = 0.3
        dropdown.Text = default or "Выберите..."
        dropdown.TextColor3 = DefaultTheme.TextColor
        dropdown.TextSize = DefaultTheme.FontSize
        dropdown.TextXAlignment = Enum.TextXAlignment.Left
        dropdown.Font = DefaultTheme.Font
        dropdown.BorderSizePixel = 0
        dropdown.Parent = container
        
        local corner = CreateCorner(dropdown, UDim.new(0, 4))
        local stroke = CreateStroke(dropdown, DefaultTheme.BorderColor, 1)
        
        local dropdownArrow = Instance.new("TextLabel")
        dropdownArrow.Name = "Arrow"
        dropdownArrow.Size = UDim2.new(0, 20, 1, 0)
        dropdownArrow.Position = UDim2.new(1, -25, 0, 0)
        dropdownArrow.BackgroundTransparency = 1
        dropdownArrow.Text = "▼"
        dropdownArrow.TextColor3 = DefaultTheme.TextColor
        dropdownArrow.TextSize = 14
        dropdownArrow.Font = DefaultTheme.Font
        dropdownArrow.Parent = dropdown
        
        local dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Name = "List"
        dropdownList.Size = UDim2.new(1, 0, 0, 0)
        dropdownList.Position = UDim2.new(0, 0, 1, 2)
        dropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        dropdownList.BackgroundTransparency = 0.1
        dropdownList.BorderSizePixel = 0
        dropdownList.ScrollBarThickness = 4
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
        dropdownList.Visible = false
        dropdownList.Parent = dropdown
        
        local listCorner = CreateCorner(dropdownList, UDim.new(0, 4))
        local listStroke = CreateStroke(dropdownList, DefaultTheme.BorderColor, 1)
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Name = "Layout"
        listLayout.Padding = UDim.new(0, 2)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = dropdownList
        
        local isOpen = false
        
        -- Создание элементов списка
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
                item.Size = UDim2.new(1, -10, 0, 30)
                item.Position = UDim2.new(0, 5, 0, canvasHeight)
                item.BackgroundTransparency = 0.5
                item.Text = option
                item.TextColor3 = DefaultTheme.TextColor
                item.TextSize = DefaultTheme.FontSize
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.Font = DefaultTheme.Font
                item.BorderSizePixel = 0
                item.Parent = dropdownList
                
                local itemCorner = CreateCorner(item, UDim.new(0, 3))
                
                item.MouseEnter:Connect(function()
                    TweenObject(item, {BackgroundTransparency = 0.2}, 0.2)
                end)
                item.MouseLeave:Connect(function()
                    TweenObject(item, {BackgroundTransparency = 0.5}, 0.2)
                end)
                
                item.MouseButton1Click:Connect(function()
                    dropdown.Text = option
                    if callback then callback(option) end
                    dropdownList.Visible = false
                    isOpen = false
                    dropdownArrow.Text = "▼"
                end)
                
                canvasHeight = canvasHeight + 32
            end
            
            dropdownList.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
            local maxHeight = math.min(canvasHeight, 150)
            dropdownList.Size = UDim2.new(1, 0, 0, maxHeight)
        end
        
        UpdateDropdownList()
        
        dropdown.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropdownList.Visible = isOpen
            dropdownArrow.Text = isOpen and "▲" or "▼"
            if isOpen then
                dropdownList.ZIndex = 20
            end
        end)
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return dropdown
    end
    
    -- Создание разделителя
    function RGLib:CreateSeparator(tab, text)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return nil
        end
        
        local container = Instance.new("Frame")
        container.Name = "SeparatorContainer"
        container.Size = UDim2.new(0.95, 0, 0, 30)
        container.BackgroundTransparency = 1
        container.Parent = tab.Scroll
        
        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = DefaultTheme.BorderColor
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.Parent = container
        
        if text then
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(0, 200, 1, 0)
            label.Position = UDim2.new(0.5, -100, 0, 0)
            label.BackgroundColor3 = DefaultTheme.BackgroundColor
            label.BackgroundTransparency = DefaultTheme.BackgroundTransparency
            label.Text = text
            label.TextColor3 = DefaultTheme.SecondaryTextColor
            label.TextSize = 12
            label.Font = DefaultTheme.Font
            label.Parent = container
            
            label.ZIndex = 2
            line.ZIndex = 1
        end
        
        table.insert(tab.Elements, container)
        RGLib:UpdateCanvas(tab)
        return container
    end
    
    -- Обновление размера скролла
    function RGLib:UpdateCanvas(tab)
        local totalHeight = 0
        for _, element in pairs(tab.Elements) do
            totalHeight = totalHeight + element.Size.Y.Offset + 8
        end
        tab.Scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
    
    -- Создание уведомления
    function RGLib:Notify(message, duration, type)
        if not IsLibraryActive then
            error("Библиотека RGLib была выгружена!")
            return
        end
        
        duration = duration or 3
        type = type or "info"
        
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Size = UDim2.new(0, 300, 0, 60)
        notification.Position = UDim2.new(1, -320, 0, 20)
        notification.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        notification.BackgroundTransparency = 0.1
        notification.BorderSizePixel = 0
        notification.Parent = screenGui
        
        local corner = CreateCorner(notification, UDim.new(0, 6))
        local stroke = CreateStroke(notification, DefaultTheme.BorderColor, 1)
        
        -- Цветовая индикация
        local color = DefaultTheme.AccentColor
        if type == "success" then color = DefaultTheme.SuccessColor
        elseif type == "error" then color = DefaultTheme.DangerColor
        elseif type == "warning" then color = DefaultTheme.WarningColor end
        
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 4, 1, 0)
        indicator.BackgroundColor3 = color
        indicator.BorderSizePixel = 0
        indicator.Parent = notification
        
        local indCorner = CreateCorner(indicator, UDim.new(0, 2))
        
        local text = Instance.new("TextLabel")
        text.Name = "Text"
        text.Size = UDim2.new(1, -20, 1, 0)
        text.Position = UDim2.new(0, 15, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = message
        text.TextColor3 = DefaultTheme.TextColor
        text.TextSize = DefaultTheme.FontSize
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextWrapped = true
        text.Font = DefaultTheme.Font
        text.Parent = notification
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "Close"
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -25, 0, 5)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = DefaultTheme.TextColor
        closeBtn.TextSize = 14
        closeBtn.Font = DefaultTheme.Font
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = notification
        
        closeBtn.MouseButton1Click:Connect(function()
            TweenObject(notification, {Position = UDim2.new(1, -320, 0, -100)}, 0.3)
            task.wait(0.3)
            notification:Destroy()
        end)
        
        -- Анимация появления
        notification.Position = UDim2.new(1, -320, 0, -100)
        TweenObject(notification, {Position = UDim2.new(1, -320, 0, 20)}, 0.3)
        
        task.wait(duration)
        TweenObject(notification, {Position = UDim2.new(1, -320, 0, -100)}, 0.3)
        task.wait(0.3)
        notification:Destroy()
    end
    
    -- Функции для работы с окном
    local windowAPI = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentContainer = contentContainer,
        Elements = elements,
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
        
        Destroy = function()
            -- Удаляем GUI из списка активных
            for i, gui in pairs(ActiveGUIs) do
                if gui == screenGui then
                    table.remove(ActiveGUIs, i)
                    break
                end
            end
            screenGui:Destroy()
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
    }
    
    return windowAPI
end

-- Глобальная функция уведомления
function RGLib:Notify(message, duration, type)
    if not IsLibraryActive then
        error("Библиотека RGLib была выгружена!")
        return
    end
    
    -- Если нет активного GUI, создаём временный
    local tempGui = Instance.new("ScreenGui")
    tempGui.Name = "RGNotify"
    tempGui.Parent = LocalPlayer.PlayerGui
    tempGui.ResetOnSpawn = false
    
    -- Добавляем в список активных
    table.insert(ActiveGUIs, tempGui)
    
    -- Создаём уведомление
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = tempGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = DefaultTheme.BorderColor
    stroke.Thickness = 1
    stroke.Parent = notification
    
    -- Цветовая индикация
    local color = DefaultTheme.AccentColor
    if type == "success" then color = DefaultTheme.SuccessColor
    elseif type == "error" then color = DefaultTheme.DangerColor
    elseif type == "warning" then color = DefaultTheme.WarningColor end
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 4, 1, 0)
    indicator.BackgroundColor3 = color
    indicator.BorderSizePixel = 0
    indicator.Parent = notification
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 2)
    indCorner.Parent = indicator
    
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 15, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = DefaultTheme.TextColor
    text.TextSize = DefaultTheme.FontSize
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Font = DefaultTheme.Font
    text.Parent = notification
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = DefaultTheme.TextColor
    closeBtn.TextSize = 14
    closeBtn.Font = DefaultTheme.Font
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = notification
    
    closeBtn.MouseButton1Click:Connect(function()
        TweenObject(notification, {Position = UDim2.new(1, -320, 0, -100)}, 0.3)
        task.wait(0.3)
        -- Удаляем из списка активных
        for i, gui in pairs(ActiveGUIs) do
            if gui == tempGui then
                table.remove(ActiveGUIs, i)
                break
            end
        end
        tempGui:Destroy()
    end)
    
    -- Анимация появления
    notification.Position = UDim2.new(1, -320, 0, -100)
    TweenObject(notification, {Position = UDim2.new(1, -320, 0, 20)}, 0.3)
    
    task.wait(duration or 3)
    TweenObject(notification, {Position = UDim2.new(1, -320, 0, -100)}, 0.3)
    task.wait(0.3)
    -- Удаляем из списка активных
    for i, gui in pairs(ActiveGUIs) do
        if gui == tempGui then
            table.remove(ActiveGUIs, i)
            break
        end
    end
    tempGui:Destroy()
end

-- Функция полной выгрузки библиотеки
function RGLib:KillMain()
    if not IsLibraryActive then
        return
    end
    
    print("[RGLib] Начинается выгрузка библиотеки...")
    
    -- Уничтожаем все активные GUI
    for i = #ActiveGUIs, 1, -1 do
        local gui = ActiveGUIs[i]
        if gui and gui.Parent then
            -- Плавное исчезновение
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
                    TweenObject(child, {BackgroundTransparency = 1}, 0.3)
                end
            end
            task.wait(0.2)
            gui:Destroy()
        end
        table.remove(ActiveGUIs, i)
    end
    
    -- Очищаем хранилище
    ActiveGUIs = {}
    
    -- Деактивируем библиотеку
    IsLibraryActive = false
    
    -- Очищаем все функции библиотеки
    local function ClearTable(tbl)
        for key, value in pairs(tbl) do
            if type(value) == "function" then
                tbl[key] = function() 
                    error("Библиотека RGLib была выгружена! Используйте loadstring для перезагрузки.")
                end
            elseif type(value) == "table" then
                ClearTable(value)
            end
        end
    end
    
    ClearTable(RGLib)
    
    -- Очищаем глобальные переменные
    if _G.RGLib then
        _G.RGLib = nil
    end
    
    print("[RGLib] Библиотека полностью выгружена!")
    print("[RGLib] Все GUI элементы уничтожены.")
end

-- Возвращаем библиотеку
return RGLib
