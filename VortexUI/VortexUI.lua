-- ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗
-- ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔══╝  ██║  ██║
-- ██║   ██║██║   ██║██████╔╝   ██║   █████╗  ███████║
-- ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝  ██╔══██║
--  ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██║  ██║
--   ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

local VortexUI = {}
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Конфиг
local config = {
	ThemeColor = Color3.fromRGB(0, 200, 255),
	GlitchEffect = true,
	Draggable = true,
	Extensibility = {} -- Для расширений
}

-- Tween helper
local function tweenObj(obj, props, time, style)
	style = style or Enum.EasingStyle.Quad
	local tween = TweenService:Create(obj, TweenInfo.new(time or 0.2, style, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- Переменные UI
local MainFrame, ScreenGui, DragFrame
local Tabs = {}
local CurrentTab = nil
local TabButtons = {}

-- ====== ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ (FIXED) ======
local function makeDraggable(frame, dragFrame)
	local dragging = false
	local dragStart, startPos
	local connections = {}
	
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end
	
	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end
	
	local function onInputChanged(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local newX = startPos.X.Offset + delta.X
			local newY = startPos.Y.Offset + delta.Y
			
			-- Ограничения
			local viewport = game:GetService("Workspace").CurrentCamera.ViewportSize
			newX = math.max(-frame.AbsoluteSize.X + 50, math.min(newX, viewport.X - 50))
			newY = math.max(-frame.AbsoluteSize.Y + 50, math.min(newY, viewport.Y - 50))
			
			frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
		end
	end
	
	dragFrame.InputBegan:Connect(onInputBegan)
	dragFrame.InputEnded:Connect(onInputEnded)
	UserInputService.InputChanged:Connect(onInputChanged)
end

-- ====== СОЗДАНИЕ КНОПКИ ======
local function createButton(parent, text, callback, yOffset)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, yOffset or 5 + (#parent:GetChildren() * 35))
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.BorderSizePixel = 1
	btn.BorderColor3 = config.ThemeColor
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.Parent = parent
	btn.AutoButtonColor = false
	btn.ClipsDescendants = true

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
			tweenObj(btn, {BorderColor3 = Color3.fromRGB(255, 255, 255)}, 0.1)
		end
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.15)
	end)

	btn.MouseLeave:Connect(function()
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 40), BorderColor3 = config.ThemeColor}, 0.2)
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
local function createToggle(parent, text, default, callback, yOffset)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, -10, 0, 30)
	toggleFrame.Position = UDim2.new(0, 5, 0, yOffset or 5 + (#parent:GetChildren() * 35))
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 50, 0, 22)
	toggleBtn.Position = UDim2.new(1, -55, 0.5, -11)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	toggleBtn.BorderSizePixel = 1
	toggleBtn.BorderColor3 = Color3.fromRGB(80, 80, 90)
	toggleBtn.Text = ""
	toggleBtn.Parent = toggleFrame
	toggleBtn.AutoButtonColor = false

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 18, 0, 18)
	indicator.Position = UDim2.new(0, 2, 0.5, -9)
	indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	indicator.BorderSizePixel = 0
	indicator.Parent = toggleBtn

	local state = default or false
	
	local function updateToggle()
		if state then
			tweenObj(toggleBtn, {BackgroundColor3 = config.ThemeColor}, 0.15)
			tweenObj(indicator, {Position = UDim2.new(1, -20, 0.5, -9)}, 0.15)
			indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			tweenObj(toggleBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.15)
			tweenObj(indicator, {Position = UDim2.new(0, 2, 0.5, -9)}, 0.15)
			indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end
		
		if callback then
			callback(state)
		end
	end

	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		updateToggle()
	end)

	updateToggle()
	
	return toggleFrame
end

-- ====== СОЗДАНИЕ LABEL С ОПЦИЯМИ ======
local function createLabel(parent, text, options)
	options = options or {}
	
	local labelFrame = Instance.new("Frame")
	labelFrame.Size = UDim2.new(1, -10, 0, options.Height or 25)
	labelFrame.Position = UDim2.new(0, 5, 0, options.Position or 5 + (#parent:GetChildren() * (options.Height or 30)))
	labelFrame.BackgroundTransparency = 1
	labelFrame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = options.Color or Color3.fromRGB(200, 200, 200)
	label.TextSize = options.Size or 14
	label.Font = options.Font or Enum.Font.GothamMedium
	label.TextXAlignment = options.Alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = labelFrame

	-- Если гиперссылка
	if options.Link then
		label.TextColor3 = Color3.fromRGB(100, 200, 255)
		label.Text = text .. " 🔗"
		
		local linkBtn = Instance.new("TextButton")
		linkBtn.Size = UDim2.new(1, 0, 1, 0)
		linkBtn.BackgroundTransparency = 1
		linkBtn.Text = ""
		linkBtn.Parent = labelFrame
		
		linkBtn.MouseButton1Click:Connect(function()
			if options.Link:match("^https?://") then
				setclipboard(options.Link)
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "Ссылка скопирована!",
					Text = options.Link,
					Duration = 3
				})
			end
		end)
		
		linkBtn.MouseEnter:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)
		
		linkBtn.MouseLeave:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(100, 200, 255)}, 0.2)
		end)
	end

	-- Если кнопка с действием
	if options.Action then
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(1, 0, 1, 0)
		actionBtn.BackgroundTransparency = 1
		actionBtn.Text = ""
		actionBtn.Parent = labelFrame
		
		actionBtn.MouseButton1Click:Connect(options.Action)
		
		actionBtn.MouseEnter:Connect(function()
			tweenObj(label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)
		
		actionBtn.MouseLeave:Connect(function()
			tweenObj(label, {TextColor3 = options.Color or Color3.fromRGB(200, 200, 200)}, 0.2)
		end)
	end

	return labelFrame
end

-- ====== СОЗДАНИЕ СЛАЙДЕРА С ПОЛЗУНКОМ (FIXED) ======
local function createSlider(parent, text, min, max, default, callback, yOffset)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(1, -10, 0, 40)
	sliderFrame.Position = UDim2.new(0, 5, 0, yOffset or 5 + (#parent:GetChildren() * 40))
	sliderFrame.BackgroundTransparency = 1
	sliderFrame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0.5, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = sliderFrame
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default or min)
	valueLabel.TextColor3 = config.ThemeColor
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = sliderFrame
	
	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 4)
	sliderBg.Position = UDim2.new(0, 0, 0.7, 0)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = sliderFrame
	
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = config.ThemeColor
	fill.BorderSizePixel = 0
	fill.Parent = sliderBg
	
	-- ПОЛЗУНОК (добавили)
	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Size = UDim2.new(0, 16, 0, 16)
	sliderBtn.Position = UDim2.new(0.5, -8, 0.7, -8)
	sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderBtn.BorderSizePixel = 0
	sliderBtn.Text = ""
	sliderBtn.Parent = sliderFrame
	
	local dragging = false
	local value = default or min
	
	local function updateSlider(val)
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
	
	sliderFrame.MouseEnter:Connect(function()
		sliderBtn.BackgroundColor3 = config.ThemeColor
	end)
	
	sliderFrame.MouseLeave:Connect(function()
		sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position.X
			local absPos = sliderFrame.AbsolutePosition.X
			local absSize = sliderFrame.AbsoluteSize.X
			local percent = math.clamp((mousePos - absPos) / absSize, 0, 1)
			local newValue = min + (max - min) * percent
			updateSlider(newValue)
		end
	end)
	
	updateSlider(value)
	
	return sliderFrame
end

-- ====== ОСНОВНЫЕ ФУНКЦИИ ======

function VortexUI:CreateWindow(title, options)
	options = options or {}
	
	if MainFrame then 
		VortexUI:Destroy()
		task.wait(0.1)
	end

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.Name = "VortexUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Главное окно
	MainFrame = Instance.new("Frame")
	MainFrame.Size = options.Size or UDim2.new(0, 500, 0, 400)
	MainFrame.Position = options.Position or UDim2.new(0.5, -250, 0.5, -200)
	MainFrame.BackgroundColor3 = options.BackgroundColor or Color3.fromRGB(20, 20, 30)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = config.ThemeColor
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	MainFrame.ZIndex = 1
	MainFrame.BackgroundTransparency = options.Transparency or 0

	-- Заголовок
	DragFrame = Instance.new("Frame")
	DragFrame.Size = UDim2.new(1, 0, 0, 30)
	DragFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	DragFrame.BorderSizePixel = 0
	DragFrame.Parent = MainFrame
	
	-- Перетаскивание
	if options.Draggable == nil or options.Draggable == true then
		makeDraggable(MainFrame, DragFrame)
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Vortex UI"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.Parent = DragFrame

	-- Кнопка закрытия
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 1, 0)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = DragFrame
	closeBtn.MouseButton1Click:Connect(function()
		VortexUI:Destroy()
	end)

	-- Контейнер для табов
	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(0, 120, 1, -30)
	tabContainer.Position = UDim2.new(0, 0, 0, 30)
	tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = MainFrame
	tabContainer.Name = "TabContainer"

	-- Контейнер для содержимого
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -120, 1, -30)
	contentContainer.Position = UDim2.new(0, 120, 0, 30)
	contentContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = MainFrame
	contentContainer.Name = "ContentContainer"

	VortexUI._tabContainer = tabContainer
	VortexUI._contentContainer = contentContainer
	VortexUI._mainFrame = MainFrame
	VortexUI._dragFrame = DragFrame

	-- Сохраняем опции
	config.Extensibility = options.Extensibility or {}

	-- Пульсация границы
	task.spawn(function()
		while MainFrame and MainFrame.Parent do
			local color = config.ThemeColor
			tweenObj(MainFrame, {BorderColor3 = color}, 1)
			task.wait(3)
		end
	end)

	return VortexUI
end

function VortexUI:CreateTab(name, icon)
	if not MainFrame then 
		warn("Сначала создай окно через CreateWindow!")
		return 
	end
	
	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, -10, 0, 30)
	tabBtn.Position = UDim2.new(0, 5, 5 + #Tabs * 35, 0)
	tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	tabBtn.BorderSizePixel = 1
	tabBtn.BorderColor3 = Color3.fromRGB(40, 40, 50)
	tabBtn.Text = "  " .. (icon or "•") .. " " .. name
	tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	tabBtn.TextSize = 14
	tabBtn.TextXAlignment = Enum.TextXAlignment.Left
	tabBtn.Font = Enum.Font.GothamMedium
	tabBtn.Parent = VortexUI._tabContainer
	tabBtn.AutoButtonColor = false
	tabBtn.Name = name

	local tabContent = Instance.new("Frame")
	tabContent.Size = UDim2.new(1, -20, 1, -20)
	tabContent.Position = UDim2.new(0, 10, 0, 10)
	tabContent.BackgroundTransparency = 1
	tabContent.Visible = false
	tabContent.Parent = VortexUI._contentContainer
	tabContent.Name = name

	local tabData = {
		Button = tabBtn,
		Content = tabContent,
		Name = name
	}
	table.insert(Tabs, tabData)
	table.insert(TabButtons, tabBtn)

	if not CurrentTab then
		CurrentTab = tabData
		tabContent.Visible = true
		tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		tabBtn.BorderColor3 = config.ThemeColor
	end

	tabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(Tabs) do
			t.Content.Visible = false
			t.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			t.Button.BorderColor3 = Color3.fromRGB(40, 40, 50)
		end
		tabContent.Visible = true
		tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		tabBtn.BorderColor3 = config.ThemeColor
		CurrentTab = tabData
	end)

	-- Возвращаем объект с методами
	return {
		AddButton = function(self, text, callback)
			createButton(tabContent, text, callback)
			return self
		end,
		
		AddToggle = function(self, text, default, callback)
			createToggle(tabContent, text, default, callback)
			return self
		end,
		
		AddLabel = function(self, text, options)
			createLabel(tabContent, text, options or {})
			return self
		end,
		
		AddSlider = function(self, text, min, max, default, callback)
			createSlider(tabContent, text, min, max, default, callback)
			return self
		end,
		
		AddDropdown = function(self, text, options, default, callback)
			-- Дропдаун для полноты
			local dropdownFrame = Instance.new("Frame")
			dropdownFrame.Size = UDim2.new(1, -10, 0, 30)
			dropdownFrame.Position = UDim2.new(0, 5, 0, 5 + (#tabContent:GetChildren() * 35))
			dropdownFrame.BackgroundTransparency = 1
			dropdownFrame.Parent = tabContent
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.5, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = dropdownFrame
			
			local dropdownBtn = Instance.new("TextButton")
			dropdownBtn.Size = UDim2.new(0.4, 0, 1, 0)
			dropdownBtn.Position = UDim2.new(0.6, 0, 0, 0)
			dropdownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			dropdownBtn.BorderSizePixel = 1
			dropdownBtn.BorderColor3 = config.ThemeColor
			dropdownBtn.Text = default or options[1] or "Выбери"
			dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			dropdownBtn.TextSize = 13
			dropdownBtn.Font = Enum.Font.GothamMedium
			dropdownBtn.Parent = dropdownFrame
			
			local selected = default or options[1]
			
			dropdownBtn.MouseButton1Click:Connect(function()
				-- Простой выбор (можно сделать выпадающий список, но это сложнее)
				local newIndex = 1
				for i, opt in ipairs(options) do
					if opt == selected then
						newIndex = i % #options + 1
						break
					end
				end
				selected = options[newIndex]
				dropdownBtn.Text = selected
				if callback then callback(selected) end
			end)
			
			return self
		end,
		
		AddBoxSlider = function(self, text, options)
			-- BoxSlider для точного размещения (таблица с параметрами)
			local boxFrame = Instance.new("Frame")
			boxFrame.Size = UDim2.new(1, -10, 0, options.Height or 30)
			boxFrame.Position = UDim2.new(0, 5, 0, options.Position or 5 + (#tabContent:GetChildren() * 35))
			boxFrame.BackgroundColor3 = options.BackgroundColor or Color3.fromRGB(20, 20, 30)
			boxFrame.BorderSizePixel = options.Border or 1
			boxFrame.BorderColor3 = options.BorderColor or config.ThemeColor
			boxFrame.Parent = tabContent
			
			if options.Title then
				local title = Instance.new("TextLabel")
				title.Size = UDim2.new(1, 0, 0, 20)
				title.BackgroundTransparency = 1
				title.Text = options.Title
				title.TextColor3 = Color3.fromRGB(200, 200, 200)
				title.TextSize = options.TitleSize or 12
				title.Font = Enum.Font.GothamMedium
				title.Parent = boxFrame
			end
			
			-- Добавляем элементы из таблицы
			for _, element in ipairs(options.Elements or {}) do
				if element.Type == "button" then
					createButton(boxFrame, element.Text, element.Callback)
				elseif element.Type == "toggle" then
					createToggle(boxFrame, element.Text, element.Default, element.Callback)
				elseif element.Type == "label" then
					createLabel(boxFrame, element.Text, element.Options or {})
				end
			end
			
			return self
		end
	}
end

function VortexUI:Destroy()
	if ScreenGui then 
		ScreenGui:Destroy() 
	end
	MainFrame = nil
	ScreenGui = nil
	Tabs = {}
	CurrentTab = nil
	TabButtons = {}
end

return VortexUI
