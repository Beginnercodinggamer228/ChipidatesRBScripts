-- ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗
-- ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔══╝  ██║  ██║
-- ██║   ██║██║   ██║██████╔╝   ██║   █████╗  ███████║
-- ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝  ██╔══██║
--  ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██║  ██║
--   ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

local VortexUI = {}
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Настройки по умолчанию
local config = {
	ThemeColor = Color3.fromRGB(0, 200, 255),
	GlitchEffect = true,
}

-- Tween helper
local function tweenObj(obj, props, time)
	local tween = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- Глобальные переменные
local ScreenGui = nil
local MainFrame = nil
local TabContainer = nil
local ContentContainer = nil
local TabsList = {}
local CurrentTab = nil
local IsDragging = false
local DragStart = nil
local StartPos = nil

-- ====== ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ ======
local function setupDragging(frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = true
			DragStart = input.Position
			StartPos = frame.Position
		end
	end)
	
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - DragStart
			local viewport = workspace.CurrentCamera.ViewportSize
			
			local newX = math.clamp(StartPos.X.Offset + delta.X, -frame.AbsoluteSize.X + 20, viewport.X - 20)
			local newY = math.clamp(StartPos.Y.Offset + delta.Y, -frame.AbsoluteSize.Y + 20, viewport.Y - 20)
			
			frame.Position = UDim2.new(StartPos.X.Scale, newX, StartPos.Y.Scale, newY)
		end
	end)
end

-- ====== СОЗДАНИЕ КНОПКИ ======
local function createButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() * 35))
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.BorderSizePixel = 1
	btn.BorderColor3 = config.ThemeColor
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.Parent = parent
	btn.AutoButtonColor = false
	
	local glitchText = Instance.new("TextLabel")
	glitchText.Size = UDim2.new(1, 0, 1, 0)
	glitchText.Position = UDim2.new(0, 2, 0, 0)
	glitchText.BackgroundTransparency = 1
	glitchText.Text = text
	glitchText.TextColor3 = Color3.fromRGB(255, 0, 100)
	glitchText.TextSize = 14
	glitchText.Font = Enum.Font.GothamBold
	glitchText.TextTransparency = 1
	glitchText.Parent = btn
	glitchText.ZIndex = 0
	
	btn.MouseEnter:Connect(function()
		if config.GlitchEffect then
			glitchText.TextTransparency = 0.5
			task.wait(0.05)
			tweenObj(glitchText, {TextTransparency = 1}, 0.1)
		end
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.15)
	end)
	
	btn.MouseLeave:Connect(function()
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}, 0.2)
	end)
	
	btn.MouseButton1Click:Connect(function()
		tweenObj(btn, {Size = UDim2.new(1, -10, 0, 28)}, 0.05)
		task.wait(0.05)
		tweenObj(btn, {Size = UDim2.new(1, -10, 0, 30)}, 0.05)
		if callback then callback() end
	end)
	
	return btn
end

-- ====== СОЗДАНИЕ ТОГГЛА ======
local function createToggle(parent, text, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 30)
	frame.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() * 35))
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 50, 0, 22)
	btn.Position = UDim2.new(1, -55, 0.5, -11)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	btn.BorderSizePixel = 1
	btn.BorderColor3 = Color3.fromRGB(80, 80, 90)
	btn.Text = ""
	btn.Parent = frame
	btn.AutoButtonColor = false
	
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 18, 0, 18)
	indicator.Position = UDim2.new(0, 2, 0.5, -9)
	indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	indicator.BorderSizePixel = 0
	indicator.Parent = btn
	
	local state = default or false
	
	local function update()
		if state then
			tweenObj(btn, {BackgroundColor3 = config.ThemeColor}, 0.15)
			tweenObj(indicator, {Position = UDim2.new(1, -20, 0.5, -9)}, 0.15)
			indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.15)
			tweenObj(indicator, {Position = UDim2.new(0, 2, 0.5, -9)}, 0.15)
			indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end
		if callback then callback(state) end
	end
	
	btn.MouseButton1Click:Connect(function()
		state = not state
		update()
	end)
	
	update()
	return frame
end

-- ====== СОЗДАНИЕ LABEL ======
local function createLabel(parent, text, options)
	options = options or {}
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, options.Height or 25)
	frame.Position = UDim2.new(0, 5, 0, options.Position or 5 + (#parent:GetChildren() * (options.Height or 30)))
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = options.Color or Color3.fromRGB(200, 200, 200)
	label.TextSize = options.Size or 14
	label.Font = options.Font or Enum.Font.GothamMedium
	label.TextXAlignment = options.Alignment or Enum.TextXAlignment.Left
	label.Parent = frame
	
	-- Гиперссылка (открывает сайт)
	if options.Link then
		label.TextColor3 = Color3.fromRGB(100, 200, 255)
		label.Text = text .. " 🔗"
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = frame
		
		btn.MouseButton1Click:Connect(function()
			if options.Link:match("^https?://") then
				-- Пытаемся открыть ссылку
				local success, err = pcall(function()
					-- Для Roblox используем setclipboard если ссылка
					setclipboard(options.Link)
					game:GetService("StarterGui"):SetCore("SendNotification", {
						Title = "Ссылка скопирована!",
						Text = "Открой в браузере: " .. options.Link,
						Duration = 5
					})
				end)
				if not success then
					print("Не удалось скопировать ссылку")
				end
			end
		end)
		
		btn.MouseEnter:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)
		
		btn.MouseLeave:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(100, 200, 255)}, 0.2)
		end)
	end
	
	-- Копирование в буфер обмена
	if options.CopyToClipboard then
		label.TextColor3 = Color3.fromRGB(200, 255, 200)
		label.Text = text .. " 📋"
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = frame
		
		btn.MouseButton1Click:Connect(function()
			local success, err = pcall(function()
				setclipboard(text)
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "Скопировано!",
					Text = "Текст скопирован в буфер обмена",
					Duration = 2
				})
			end)
			if not success then
				print("Не удалось скопировать текст")
			end
		end)
		
		btn.MouseEnter:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)
		
		btn.MouseLeave:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(200, 255, 200)}, 0.2)
		end)
	end
	
	-- Действие при нажатии
	if options.Action then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = frame
		
		btn.MouseButton1Click:Connect(options.Action)
		
		btn.MouseEnter:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)
		
		btn.MouseLeave:Connect(function()
			tweenObj(label, {TextColor3 = options.Color or Color3.fromRGB(200, 200, 200)}, 0.2)
		end)
	end
	
	return frame
end

-- ====== СОЗДАНИЕ СЛАЙДЕРА ======
local function createSlider(parent, text, min, max, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 40)
	frame.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() * 40))
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0.5, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default or min)
	valueLabel.TextColor3 = config.ThemeColor
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 4)
	bg.Position = UDim2.new(0, 0, 0.7, 0)
	bg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bg.BorderSizePixel = 0
	bg.Parent = frame
	
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = config.ThemeColor
	fill.BorderSizePixel = 0
	fill.Parent = bg
	
	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Size = UDim2.new(0, 16, 0, 16)
	sliderBtn.Position = UDim2.new(0.5, -8, 0.7, -8)
	sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderBtn.BorderSizePixel = 0
	sliderBtn.Text = ""
	sliderBtn.Parent = frame
	
	local dragging = false
	local value = default or min
	
	local function update(val)
		value = math.clamp(val, min, max)
		local percent = (value - min) / (max - min)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		sliderBtn.Position = UDim2.new(percent, -8, 0.7, -8)
		valueLabel.Text = tostring(math.floor(value))
		if callback then callback(value) end
	end
	
	sliderBtn.MouseButton1Down:Connect(function()
		dragging = true
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local pos = input.Position.X
			local absPos = frame.AbsolutePosition.X
			local absSize = frame.AbsoluteSize.X
			local percent = math.clamp((pos - absPos) / absSize, 0, 1)
			update(min + (max - min) * percent)
		end
	end)
	
	update(value)
	return frame
end

-- ====== СОЗДАНИЕ ДРОПДАУНА ======
local function createDropdown(parent, text, options, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 30)
	frame.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() * 35))
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.4, 0, 1, 0)
	btn.Position = UDim2.new(0.6, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.BorderSizePixel = 1
	btn.BorderColor3 = config.ThemeColor
	btn.Text = default or options[1] or "Выбери"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamMedium
	btn.Parent = frame
	
	local selected = default or options[1]
	local index = 1
	
	for i, opt in ipairs(options) do
		if opt == selected then
			index = i
			break
		end
	end
	
	btn.MouseButton1Click:Connect(function()
		index = index % #options + 1
		selected = options[index]
		btn.Text = selected
		if callback then callback(selected) end
	end)
	
	return frame
end

-- ====== ОСНОВНЫЕ ФУНКЦИИ БИБЛИОТЕКИ ======

function VortexUI:CreateWindow(title, options)
	options = options or {}
	
	-- Удаляем старое окно
	if ScreenGui then
		ScreenGui:Destroy()
		ScreenGui = nil
		MainFrame = nil
		TabsList = {}
		CurrentTab = nil
		task.wait(0.1)
	end
	
	-- Создаём ScreenGui
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.Name = "VortexUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Создаём главное окно
	MainFrame = Instance.new("Frame")
	MainFrame.Size = options.Size or UDim2.new(0, 500, 0, 400)
	MainFrame.Position = options.Position or UDim2.new(0.5, -250, 0.5, -200)
	MainFrame.BackgroundColor3 = options.BackgroundColor or Color3.fromRGB(20, 20, 30)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = config.ThemeColor
	MainFrame.BackgroundTransparency = options.Transparency or 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	MainFrame.ZIndex = 1
	
	-- Заголовок
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = MainFrame
	
	-- Перетаскивание
	if options.Draggable == nil or options.Draggable == true then
		setupDragging(MainFrame)
	end
	
	-- Заголовок текст
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Vortex UI"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	
	-- Кнопка закрытия
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 1, 0)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar
	closeBtn.MouseButton1Click:Connect(function()
		VortexUI:Destroy()
	end)
	
	-- Кнопка сворачивания (Expand/Collapse)
	if options.Expandable then
		local expandBtn = Instance.new("TextButton")
		expandBtn.Size = UDim2.new(0, 30, 1, 0)
		expandBtn.Position = UDim2.new(1, -60, 0, 0)
		expandBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		expandBtn.BorderSizePixel = 0
		expandBtn.Text = "−"
		expandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		expandBtn.TextSize = 16
		expandBtn.Font = Enum.Font.GothamBold
		expandBtn.Parent = titleBar
		
		local isExpanded = true
		local originalSize = MainFrame.Size
		
		expandBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			if isExpanded then
				expandBtn.Text = "−"
				tweenObj(MainFrame, {Size = originalSize}, 0.3)
			else
				expandBtn.Text = "+"
				tweenObj(MainFrame, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 30)}, 0.3)
			end
		end)
	end
	
	-- Контейнер для табов
	TabContainer = Instance.new("Frame")
	TabContainer.Size = UDim2.new(0, 120, 1, -30)
	TabContainer.Position = UDim2.new(0, 0, 0, 30)
	TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	TabContainer.BorderSizePixel = 0
	TabContainer.Parent = MainFrame
	TabContainer.Name = "TabContainer"
	
	-- Контейнер для содержимого
	ContentContainer = Instance.new("Frame")
	ContentContainer.Size = UDim2.new(1, -120, 1, -30)
	ContentContainer.Position = UDim2.new(0, 120, 0, 30)
	ContentContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	ContentContainer.BorderSizePixel = 0
	ContentContainer.Parent = MainFrame
	ContentContainer.Name = "ContentContainer"
	
	-- Сохраняем ссылки
	VortexUI._mainFrame = MainFrame
	VortexUI._tabContainer = TabContainer
	VortexUI._contentContainer = ContentContainer
	
	-- Анимация границы
	task.spawn(function()
		while MainFrame and MainFrame.Parent do
			tweenObj(MainFrame, {BorderColor3 = config.ThemeColor}, 1)
			task.wait(3)
		end
	end)
	
	return VortexUI
end

function VortexUI:CreateTab(name, icon)
	if not MainFrame then
		warn("Сначала создай окно через CreateWindow()")
		return nil
	end
	
	-- Кнопка таба
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 5 + #TabsList * 35, 0)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.BorderSizePixel = 1
	btn.BorderColor3 = Color3.fromRGB(40, 40, 50)
	btn.Text = "  " .. (icon or "•") .. " " .. name
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.GothamMedium
	btn.Parent = TabContainer
	btn.AutoButtonColor = false
	
	-- Контент таба
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -20, 1, -20)
	content.Position = UDim2.new(0, 10, 0, 10)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.Parent = ContentContainer
	
	-- Сохраняем данные таба
	local tabData = {
		Button = btn,
		Content = content,
		Name = name
	}
	table.insert(TabsList, tabData)
	
	-- Если это первый таб - показываем его
	if not CurrentTab then
		CurrentTab = tabData
		content.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		btn.BorderColor3 = config.ThemeColor
	end
	
	-- Обработчик клика по табу
	btn.MouseButton1Click:Connect(function()
		-- Скрываем все табы
		for _, tab in ipairs(TabsList) do
			tab.Content.Visible = false
			tab.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			tab.Button.BorderColor3 = Color3.fromRGB(40, 40, 50)
		end
		
		-- Показываем выбранный
		content.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		btn.BorderColor3 = config.ThemeColor
		CurrentTab = tabData
	end)
	
	-- Возвращаем объект с методами
	local tabObject = {
		AddButton = function(self, text, callback)
			createButton(content, text, callback)
			return self
		end,
		
		AddToggle = function(self, text, default, callback)
			createToggle(content, text, default, callback)
			return self
		end,
		
		AddLabel = function(self, text, options)
			createLabel(content, text, options or {})
			return self
		end,
		
		AddSlider = function(self, text, min, max, default, callback)
			createSlider(content, text, min, max, default, callback)
			return self
		end,
		
		AddDropdown = function(self, text, options, default, callback)
			createDropdown(content, text, options, default, callback)
			return self
		end
	}
	
	return tabObject
end

function VortexUI:Destroy()
	if ScreenGui then
		ScreenGui:Destroy()
	end
	ScreenGui = nil
	MainFrame = nil
	TabContainer = nil
	ContentContainer = nil
	TabsList = {}
	CurrentTab = nil
end

-- Обновление цвета при смене времени
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	local time = Lighting.ClockTime or 12
	if time > 6 and time < 12 then
		config.ThemeColor = Color3.fromRGB(0, 200, 255)
	elseif time >= 12 and time < 18 then
		config.ThemeColor = Color3.fromRGB(255, 150, 0)
	else
		config.ThemeColor = Color3.fromRGB(200, 0, 255)
	end
end)

return VortexUI
