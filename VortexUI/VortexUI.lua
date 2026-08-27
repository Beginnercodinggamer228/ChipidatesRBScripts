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

-- Конфиг
local config = {
	ThemeColor = Color3.fromRGB(0, 200, 255),
	GlitchEffect = true,
	Draggable = true
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

-- ====== ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ ======
local function makeDraggable(frame, dragFrame)
	local dragging = false
	local dragStart, startPos
	
	dragFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	
	dragFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local newX = startPos.X.Offset + delta.X
			local newY = startPos.Y.Offset + delta.Y
			
			-- Ограничиваем чтобы не выходил за экран
			local maxX = 100
			local maxY = 100
			newX = math.max(-maxX, math.min(newX, 500))
			newY = math.max(-maxY, math.min(newY, 300))
			
			frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
		end
	end)
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

	-- Глитч эффект
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

	-- Состояние (по умолчанию false, а не true!)
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

	-- Устанавливаем начальное состояние
	updateToggle()
	
	return toggleFrame
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

	-- Главное окно (без затемнения!)
	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 500, 0, 400)
	MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = config.ThemeColor
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	MainFrame.ZIndex = 1

	-- Заголовок
	DragFrame = Instance.new("Frame")
	DragFrame.Size = UDim2.new(1, 0, 0, 30)
	DragFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	DragFrame.BorderSizePixel = 0
	DragFrame.Parent = MainFrame
	
	-- Перетаскивание (активно по умолчанию)
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

	-- Контейнер для содержимого
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -120, 1, -30)
	contentContainer.Position = UDim2.new(0, 120, 0, 30)
	contentContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = MainFrame

	VortexUI._tabContainer = tabContainer
	VortexUI._contentContainer = contentContainer
	VortexUI._mainFrame = MainFrame
	VortexUI._dragFrame = DragFrame

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
		
		AddLabel = function(self, text)
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -10, 0, 25)
			label.Position = UDim2.new(0, 5, 0, 5 + (#tabContent:GetChildren() * 30))
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.fromRGB(150, 150, 150)
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = tabContent
			return self
		end,
		
		AddSlider = function(self, text, min, max, default, callback)
			-- Слайдер для полноты
			local sliderFrame = Instance.new("Frame")
			sliderFrame.Size = UDim2.new(1, -10, 0, 40)
			sliderFrame.Position = UDim2.new(0, 5, 0, 5 + (#tabContent:GetChildren() * 35))
			sliderFrame.BackgroundTransparency = 1
			sliderFrame.Parent = tabContent
			
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
			
			local slider = Instance.new("Frame")
			slider.Size = UDim2.new(1, 0, 0, 4)
			slider.Position = UDim2.new(0, 0, 0.7, 0)
			slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			slider.BorderSizePixel = 0
			slider.Parent = sliderFrame
			
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(0.5, 0, 1, 0)
			fill.BackgroundColor3 = config.ThemeColor
			fill.BorderSizePixel = 0
			fill.Parent = slider
			
			local value = default or min
			local function updateSlider(val)
				value = math.clamp(val, min, max)
				local percent = (value - min) / (max - min)
				fill.Size = UDim2.new(percent, 0, 1, 0)
				valueLabel.Text = tostring(math.floor(value))
				if callback then callback(value) end
			end
			
			updateSlider(value)
			
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
end

return VortexUI
