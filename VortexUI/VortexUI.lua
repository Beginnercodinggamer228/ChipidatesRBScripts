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

-- Приколюха №1: Цвет зависит от игрового времени (или просто меняется циклично)
local function getNeonColor()
	-- Берем время суток из Lighting, если оно есть, или используем системное время для эффекта
	local hour = Lighting:GetPropertyChangedSignal("ClockTime")
	local time = Lighting.ClockTime or 12
	-- От 0 до 24 часов -> цикл цветов: Синий (ночь) -> Оранжевый (закат) -> Голубой (день)
	if time > 6 and time < 12 then
		return Color3.fromRGB(0, 200, 255) -- День (Неон-голубой)
	elseif time >= 12 and time < 18 then
		return Color3.fromRGB(255, 150, 0) -- Закат (Огонь)
	else
		return Color3.fromRGB(200, 0, 255) -- Ночь (Фиолетовый)
	end
end

-- Настройки по умолчанию (динамические)
local config = {
	ThemeColor = getNeonColor(),
	GlitchEffect = true, -- Приколюха №2: Глитч при наведении
	PulseSpeed = 2
}

-- Создаем главное окно (синглтон)
local MainFrame
local ScreenGui
local Tabs = {}
local CurrentTab = nil

-- Вспомогательная функция для создания Tween
local function tweenObj(obj, props, time, style)
	style = style or Enum.EasingStyle.Quad
	local tween = TweenService:Create(obj, TweenInfo.new(time or 0.2, style, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- Функция создания кнопки с "глитчем"
local function createGlitchButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, 5)
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

	-- Приколюха: Эффект "глитч" (смещение текста)
	local glitchText = Instance.new("TextLabel")
	glitchText.Size = UDim2.new(1, 0, 1, 0)
	glitchText.Position = UDim2.new(0, 2, 0, 0) -- Слегка смещен
	glitchText.BackgroundTransparency = 1
	glitchText.Text = text
	glitchText.TextColor3 = Color3.fromRGB(255, 0, 100)
	glitchText.TextSize = 14
	glitchText.Font = Enum.Font.GothamBold
	glitchText.TextTransparency = 1
	glitchText.Parent = btn
	glitchText.ZIndex = 0

	local hoverTween = nil

	btn.MouseEnter:Connect(function()
		if config.GlitchEffect then
			-- Эффект глитча: на долю секунды показываем красное смещение
			glitchText.TextTransparency = 0.5
			tweenObj(glitchText, {TextTransparency = 1}, 0.1)
			-- Дрожание рамки
			tweenObj(btn, {BorderColor3 = Color3.fromRGB(255, 255, 255)}, 0.1)
		end
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.15)
	end)

	btn.MouseLeave:Connect(function()
		tweenObj(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 40), BorderColor3 = config.ThemeColor}, 0.2)
	end)

	btn.MouseButton1Click:Connect(function()
		-- Эффект нажатия (вдавливание)
		tweenObj(btn, {Size = UDim2.new(1, -10, 0, 28)}, 0.05)
		task.wait(0.05)
		tweenObj(btn, {Size = UDim2.new(1, -10, 0, 30)}, 0.05)
		if callback then callback() end
	end)

	return btn
end

-- === Публичные методы библиотеки ===

function VortexUI:CreateWindow(title)
	if MainFrame then return end -- Уже создано

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.Name = "VortexUI"
	ScreenGui.ResetOnSpawn = false

	-- Затемнение (Background)
	local dim = Instance.new("Frame")
	dim.Size = UDim2.new(1, 0, 1, 0)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.5
	dim.Parent = ScreenGui
	dim.ZIndex = 0

	-- Главное окно
	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 500, 0, 400)
	MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = config.ThemeColor
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	MainFrame.ZIndex = 1

	-- Заголовок (с возможностью перетаскивания, но для простоты пропустим)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 30)
	topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	topBar.BorderSizePixel = 0
	topBar.Parent = MainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Vortex UI"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.Parent = topBar

	-- Кнопка закрытия (с глитч-эффектом)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 1, 0)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 1
	closeBtn.BorderColor3 = Color3.fromRGB(100, 0, 0)
	closeBtn.Parent = topBar
	closeBtn.MouseButton1Click:Connect(function()
		VortexUI:Destroy()
	end)

	-- Контейнер для табов (левая панель)
	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(0, 120, 1, -30)
	tabContainer.Position = UDim2.new(0, 0, 0, 30)
	tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	tabContainer.BorderSizePixel = 0
	tabContainer.Parent = MainFrame

	-- Контейнер для содержимого (правая панель)
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -120, 1, -30)
	contentContainer.Position = UDim2.new(0, 120, 0, 30)
	contentContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = MainFrame

	-- Сохраняем ссылки
	VortexUI._tabContainer = tabContainer
	VortexUI._contentContainer = contentContainer
	VortexUI._mainFrame = MainFrame

	-- Пульсация границы (Приколюха №3)
	task.spawn(function()
		while MainFrame and MainFrame.Parent do
			local color = getNeonColor()
			config.ThemeColor = color
			tweenObj(MainFrame, {BorderColor3 = color}, 1)
			task.wait(3) -- Меняем цвет каждые 3 секунды (или можно привязать к времени)
		end
	end)

	return VortexUI
end

function VortexUI:CreateTab(name, icon)
	if not MainFrame then return end
	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, -10, 0, 30)
	tabBtn.Position = UDim2.new(0, 5, 0, #Tabs * 35 + 10)
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

	table.insert(Tabs, {
		Button = tabBtn,
		Content = tabContent,
		Name = name
	})

	if not CurrentTab then
		CurrentTab = Tabs[#Tabs]
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
		CurrentTab = {Button = tabBtn, Content = tabContent}
	end)

	return {
		AddButton = function(self, text, callback)
			createGlitchButton(tabContent, text, callback)
		end,
		AddToggle = function(self, text, default, callback)
			local toggleFrame = Instance.new("Frame")
			toggleFrame.Size = UDim2.new(1, -10, 0, 30)
			toggleFrame.Position = UDim2.new(0, 5, 0, 5 + (#tabContent:GetChildren() * 35))
			toggleFrame.BackgroundTransparency = 1
			toggleFrame.Parent = tabContent

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.8, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.fromRGB(255,255,255)
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = toggleFrame

			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(0, 50, 0, 20)
			toggleBtn.Position = UDim2.new(1, -55, 0.5, -10)
			toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			toggleBtn.BorderColor3 = config.ThemeColor
			toggleBtn.Text = ""
			toggleBtn.Parent = toggleFrame

			local state = default or false
			local indicator = Instance.new("Frame")
			indicator.Size = UDim2.new(0, 18, 0, 18)
			indicator.Position = UDim2.new(0, 1, 0.5, -9)
			indicator.BackgroundColor3 = Color3.fromRGB(255,255,255)
			indicator.BorderSizePixel = 0
			indicator.Parent = toggleBtn

			local function updateToggle()
				if state then
					tweenObj(toggleBtn, {BackgroundColor3 = config.ThemeColor}, 0.1)
					tweenObj(indicator, {Position = UDim2.new(1, -19, 0.5, -9)}, 0.15)
					indicator.BackgroundColor3 = Color3.fromRGB(255,255,255)
				else
					tweenObj(toggleBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.1)
					tweenObj(indicator, {Position = UDim2.new(0, 1, 0.5, -9)}, 0.15)
					indicator.BackgroundColor3 = Color3.fromRGB(150,150,150)
				end
				if callback then callback(state) end
			end

			toggleBtn.MouseButton1Click:Connect(function()
				state = not state
				updateToggle()
			end)

			updateToggle() -- Установить начальное состояние
		end
	}
end

function VortexUI:Destroy()
	if ScreenGui then ScreenGui:Destroy() end
	MainFrame = nil
	ScreenGui = nil
	Tabs = {}
	CurrentTab = nil
end

-- Приколюха №4: Если игрок заходит в игру ночью (реальное время), UI будет темнее
-- Обновляем цвет при изменении Lighting
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	config.ThemeColor = getNeonColor()
	if MainFrame then
		tweenObj(MainFrame, {BorderColor3 = config.ThemeColor}, 0.5)
	end
end)

return VortexUI
