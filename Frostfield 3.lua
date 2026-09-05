--[[
	Frostfield
	Rayfield-compatible UI — ice neon chrome.
	Toggle: return false  or  :Set(false)  = no se enciende.
	RequiredFlags = {"Desync","SafeDesync"}  = no prende si faltan.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Frostfield = {
	Flags = {},
}

local Theme = {
	TextColor = Color3.fromRGB(240, 250, 255),
	TextMuted = Color3.fromRGB(190, 225, 250),
	Background = Color3.fromRGB(150, 195, 235),
	Topbar = Color3.fromRGB(165, 210, 245),
	TabBar = Color3.fromRGB(155, 200, 240),
	Element = Color3.fromRGB(170, 215, 250),
	ElementBorder = Color3.fromRGB(150, 220, 255),
	Highlight = Color3.fromRGB(130, 220, 255),
	Ice = Color3.fromRGB(180, 235, 255),
	Neon = Color3.fromRGB(70, 210, 255),
}

local LOGO_URL = "https://raw.githubusercontent.com/ftrevino739-ctrl/iOS-photo/main/IMG_5904.PNG"

local State = {
	gui = nil,
	window = nil,
	body = nil,
	sidebar = nil,
	content = nil,
	footer = nil,
	titleLabel = nil,
	chip = nil,
	noticeHolder = nil,
	visible = true,
	minimized = false,
	expanded = false,
	closed = false,
	tabs = {},
	activeTab = nil,
	config = nil,
	keybind = Enum.KeyCode.K,
	connections = {},
}

local function round(inst, px)
	local c = Instance.new("UICorner")
	if px == "pill" then
		c.CornerRadius = UDim.new(1, 0)
	else
		c.CornerRadius = UDim.new(0, px or 20)
	end
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.ElementBorder
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.45
	s.Parent = inst
	return s
end

local function pad(inst, px)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = inst
	return p
end

local function track(conn)
	table.insert(State.connections, conn)
	return conn
end

local function tween(obj, t, props, style, dir)
	local tw = TS:Create(
		obj,
		TweenInfo.new(t or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function saveConfig()
	local cfg = State.config
	if not (cfg and cfg.Enabled) then
		return
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Frostfield.Flags)
	if not ok then
		return
	end
	local folder = cfg.FolderName or "Frostfield"
	local file = (cfg.FileName or "Config") .. ".json"
	pcall(function()
		if isfolder and makefolder and not isfolder(folder) then
			makefolder(folder)
		end
		if writefile then
			writefile(folder .. "/" .. file, encoded)
		end
	end)
end

local function loadConfig()
	local cfg = State.config
	if not (cfg and cfg.Enabled) then
		return
	end
	local folder = cfg.FolderName or "Frostfield"
	local file = (cfg.FileName or "Config") .. ".json"
	pcall(function()
		if isfile and isfile(folder .. "/" .. file) then
			local raw = readfile(folder .. "/" .. file)
			local data = HttpService:JSONDecode(raw)
			if type(data) == "table" then
				for k, v in pairs(data) do
					Frostfield.Flags[k] = v
				end
			end
		end
	end)
end

local function makeIcon(parent, image)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(16, 16)
	img.ImageColor3 = Theme.Ice
	img.ScaleType = Enum.ScaleType.Fit
	if type(image) == "number" and image > 0 then
		img.Image = "rbxassetid://" .. tostring(image)
	elseif type(image) == "string" and image ~= "" and image ~= "0" then
		if string.sub(image, 1, 11) == "rbxassetid:" or string.sub(image, 1, 13) == "rbxassetid://" then
			img.Image = image
		else
			img.Image = "rbxassetid://7733960981"
		end
	else
		img.Image = "rbxassetid://7733960981"
	end
	img.Parent = parent
	return img
end

local function loadRemoteImage(imageLabel, url)
	task.spawn(function()
		pcall(function()
			local data = game:HttpGet(url)
			local path = "FrostHubLogo.png"
			if writefile then
				writefile(path, data)
			end
			local asset
			if getcustomasset then
				asset = getcustomasset(path)
			elseif getsynasset then
				asset = getsynasset(path)
			end
			if type(asset) == "string" and asset ~= "" then
				imageLabel.Image = asset
			end
		end)
	end)
end

local function drawGear(parent)
	local holder = Instance.new("Frame")
	holder.Name = "GearIcon"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(18, 18)
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 7)
	holder.Parent = parent
	local color = Color3.fromRGB(170, 230, 255)
	for i = 0, 5 do
		local tooth = Instance.new("Frame")
		tooth.Name = "Tooth"
		tooth.AnchorPoint = Vector2.new(0.5, 0.5)
		tooth.Position = UDim2.fromScale(0.5, 0.5)
		tooth.Size = UDim2.fromOffset(5, 18)
		tooth.Rotation = i * 30
		tooth.BackgroundColor3 = color
		tooth.BorderSizePixel = 0
		tooth.Parent = holder
		round(tooth, 2)
	end
	local disc = Instance.new("Frame")
	disc.Name = "Disc"
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Position = UDim2.fromScale(0.5, 0.5)
	disc.Size = UDim2.fromOffset(12, 12)
	disc.BackgroundColor3 = color
	disc.BorderSizePixel = 0
	disc.ZIndex = 2
	disc.Parent = holder
	round(disc, "pill")
	local hole = Instance.new("Frame")
	hole.Name = "Hole"
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Position = UDim2.fromScale(0.5, 0.5)
	hole.Size = UDim2.fromOffset(5, 5)
	hole.BackgroundColor3 = Color3.fromRGB(90, 150, 200)
	hole.BorderSizePixel = 0
	hole.ZIndex = 3
	hole.Parent = holder
	round(hole, "pill")
	return holder
end

local function paintGear(holder, color)
	if not holder then
		return
	end
	for _, d in ipairs(holder:GetDescendants()) do
		if d:IsA("Frame") and d.Name ~= "Hole" then
			d.BackgroundColor3 = color
		end
	end
end

function Frostfield:Notify(opts)
	opts = opts or {}
	if not State.noticeHolder then
		return
	end
	local duration = opts.Duration or 4
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(300, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.Topbar
	card.BackgroundTransparency = 0.22
	card.BorderSizePixel = 0
	card.Parent = State.noticeHolder
	round(card, 18)
	stroke(card, Theme.Neon, 1.5, 0.1)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 3, 1, 0)
	accent.BackgroundColor3 = Theme.Highlight
	accent.BorderSizePixel = 0
	accent.Parent = card
	round(accent, 2)

	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, -12, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.Position = UDim2.fromOffset(12, 0)
	wrap.Parent = card
	pad(wrap, 10)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = wrap

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TextColor
	title.Text = tostring(opts.Title or "Notice")
	title.Parent = wrap

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Theme.TextMuted
	body.Text = tostring(opts.Content or "")
	body.Parent = wrap

	task.delay(duration, function()
		if card and card.Parent then
			tween(card, 0.15, { BackgroundTransparency = 1 })
			task.wait(0.15)
			card:Destroy()
		end
	end)
end

function Frostfield:UpdateTheme(t)
	if type(t) ~= "table" then
		return
	end
	for k, v in pairs(t) do
		if Theme[k] ~= nil then
			Theme[k] = v
		end
	end
end

function Frostfield:SetVisibility(v)
	State.visible = v and true or false
	if State.window then
		State.window.Visible = State.visible and not State.closed
	end
	if State.chip then
		State.chip.Visible = (not State.visible) or State.closed
	end
end

function Frostfield:IsVisible()
	return State.visible and not State.closed
end

function Frostfield:Destroy()
	for _, c in ipairs(State.connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(State.connections)
	if State.gui then
		State.gui:Destroy()
	end
	State.gui = nil
	State.window = nil
end

local function setMinimized(v)
	State.minimized = v
	if not State.window then
		return
	end
	if v then
		State.body.Visible = false
		State.footer.Visible = false
		State.window.Size = UDim2.fromOffset(State.window.AbsoluteSize.X, 46)
	else
		local h = State.expanded and 640 or 492
		State.window.Size = UDim2.fromOffset(State.expanded and 608 or 552, h)
		State.body.Visible = true
		State.footer.Visible = true
	end
end

local function setExpanded(v)
	State.expanded = v
	if State.minimized then
		setMinimized(false)
		return
	end
	if v then
		State.window.Size = UDim2.fromOffset(608, 640)
	else
		State.window.Size = UDim2.fromOffset(552, 492)
	end
end

local function closeWindow()
	State.closed = true
	State.visible = false
	if State.window then
		State.window.Visible = false
	end
	if State.chip then
		State.chip.Visible = true
	end
end

local function openWindow()
	State.closed = false
	State.visible = true
	State.minimized = false
	if State.window then
		State.window.Visible = true
		State.body.Visible = true
		State.footer.Visible = true
		setExpanded(State.expanded)
	end
	if State.chip then
		State.chip.Visible = false
	end
end

local function bindDrag(handle, target)
	local dragging = false
	local startPos, startInput
	track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))
	track(UIS.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
end

local function makeTopButton(parent, text, order, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(30, 30)
	b.BackgroundTransparency = 1
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 16
	b.TextColor3 = Theme.TextColor
	b.AutoButtonColor = false
	b.LayoutOrder = order
	b.Parent = parent
	round(b, "pill")
	local st = stroke(b, Theme.Neon, 1.4, 0.35)
	track(b.MouseEnter:Connect(function()
		b.BackgroundTransparency = 0.72
		b.BackgroundColor3 = Theme.Ice
		st.Transparency = 0.05
	end))
	track(b.MouseLeave:Connect(function()
		b.BackgroundTransparency = 1
		st.Transparency = 0.35
	end))
	track(b.MouseButton1Click:Connect(callback))
	return b
end

local function makeElement(parent)
	local f = Instance.new("TextButton")
	f.AutoButtonColor = false
	f.Size = UDim2.new(1, 0, 0, 42)
	f.BackgroundColor3 = Theme.Element
	f.BackgroundTransparency = 0.28
	f.BorderSizePixel = 0
	f.Text = ""
	f.Parent = parent
	round(f, "pill")
	local st = stroke(f, Theme.Neon, 1.6, 0.12)
	track(f.MouseEnter:Connect(function()
		tween(f, 0.12, { BackgroundTransparency = 0.14 })
		st.Transparency = 0
		st.Color = Theme.Neon
	end))
	track(f.MouseLeave:Connect(function()
		tween(f, 0.12, { BackgroundTransparency = 0.28 })
		st.Transparency = 0.12
		st.Color = Theme.Neon
	end))
	return f, st
end

local function makeNeonButton(parent)
	local f, st = makeElement(parent)
	f.BackgroundColor3 = Color3.fromRGB(110, 190, 255)
	f.BackgroundTransparency = 0.18
	st.Color = Theme.Neon
	st.Thickness = 2
	st.Transparency = 0
	track(f.MouseEnter:Connect(function()
		st.Thickness = 2.4
		st.Transparency = 0
	end))
	track(f.MouseLeave:Connect(function()
		st.Thickness = 2
		st.Transparency = 0
	end))
	return f
end

local function makeLabel(parent, text)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -70, 1, 0)
	l.Position = UDim2.fromOffset(12, 0)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Theme.TextColor
	l.Text = text
	l.Parent = parent
	return l
end

local function switchTab(id)
	State.activeTab = id
	for key, tab in pairs(State.tabs) do
		local on = key == id
		tab.page.Visible = on
		tab.button.BackgroundTransparency = on and 0.35 or 1
		tab.button.TextColor3 = on and Theme.TextColor or Theme.TextMuted
		if tab.icon then
			if tab.icon:IsA("ImageLabel") then
				tab.icon.ImageColor3 = on and Theme.Ice or Theme.TextMuted
			else
				paintGear(tab.icon, on and Color3.fromRGB(170, 230, 255) or Theme.TextMuted)
			end
		end
	end
end

local function buildChrome(opts)
	if State.gui then
		State.gui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "Frostfield"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui
	State.gui = gui

	local notices = Instance.new("Frame")
	notices.Name = "Notices"
	notices.BackgroundTransparency = 1
	notices.AnchorPoint = Vector2.new(1, 0)
	notices.Position = UDim2.new(1, -16, 0, 16)
	notices.Size = UDim2.fromOffset(300, 400)
	notices.Parent = gui
	local nList = Instance.new("UIListLayout")
	nList.SortOrder = Enum.SortOrder.LayoutOrder
	nList.Padding = UDim.new(0, 8)
	nList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	nList.Parent = notices
	State.noticeHolder = notices

	local chip = Instance.new("TextButton")
	chip.Name = "ShowChip"
	chip.Visible = false
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Position = UDim2.new(0.5, 0, 0, 18)
	chip.Size = UDim2.fromOffset(140, 36)
	chip.BackgroundColor3 = Theme.Topbar
	chip.BackgroundTransparency = 0.28
	chip.Text = "  " .. (opts.ShowText or "Frost Hub")
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = 14
	chip.TextColor3 = Theme.TextColor
	chip.AutoButtonColor = false
	chip.Parent = gui
	round(chip, "pill")
	stroke(chip, Theme.Neon, 1.5, 0.08)
	State.chip = chip
	track(chip.MouseButton1Click:Connect(openWindow))

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(552, 492)
	window.BackgroundColor3 = Color3.fromRGB(175, 215, 245)
	window.BackgroundTransparency = 0.28
	window.BorderSizePixel = 0
	window.ClipsDescendants = true
	window.Parent = gui
	round(window, 24)
	stroke(window, Theme.Neon, 1.8, 0.08)
	State.window = window

	local frost = Instance.new("ImageLabel")
	frost.Name = "FrostBg"
	frost.BackgroundTransparency = 1
	frost.AnchorPoint = Vector2.new(0.5, 0.5)
	frost.Position = UDim2.fromScale(0.5, 0.5)
	frost.Size = UDim2.fromScale(0.92, 0.92)
	frost.ImageTransparency = 0.22
	frost.ImageColor3 = Color3.fromRGB(230, 245, 255)
	frost.ScaleType = Enum.ScaleType.Fit
	frost.ZIndex = 0
	frost.Parent = window
	local bg = opts.BackgroundImage
	if bg and bg ~= 0 and bg ~= "" then
		frost.Image = type(bg) == "number" and ("rbxassetid://" .. bg) or tostring(bg)
	else
		loadRemoteImage(frost, LOGO_URL)
	end

	local glass = Instance.new("Frame")
	glass.Name = "Glass"
	glass.Size = UDim2.fromScale(1, 1)
	glass.BackgroundColor3 = Color3.fromRGB(190, 225, 250)
	glass.BackgroundTransparency = 0.62
	glass.BorderSizePixel = 0
	glass.ZIndex = 1
	glass.Parent = window
	round(glass, 24)

	local top = Instance.new("Frame")
	top.Name = "Topbar"
	top.Size = UDim2.new(1, 0, 0, 46)
	top.BackgroundColor3 = Theme.Topbar
	top.BackgroundTransparency = 0.42
	top.BorderSizePixel = 0
	top.ZIndex = 2
	top.Parent = window

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(14, 0)
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TextColor
	title.Text = opts.Name or "Frostfield"
	title.ZIndex = 3
	title.Parent = top
	State.titleLabel = title

	local btns = Instance.new("Frame")
	btns.BackgroundTransparency = 1
	btns.AnchorPoint = Vector2.new(1, 0.5)
	btns.Position = UDim2.new(1, -8, 0.5, 0)
	btns.Size = UDim2.fromOffset(96, 30)
	btns.ZIndex = 3
	btns.Parent = top
	local bLay = Instance.new("UIListLayout")
	bLay.FillDirection = Enum.FillDirection.Horizontal
	bLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bLay.VerticalAlignment = Enum.VerticalAlignment.Center
	bLay.Padding = UDim.new(0, 2)
	bLay.Parent = btns

	makeTopButton(btns, "□", 1, function()
		setExpanded(not State.expanded)
	end)
	makeTopButton(btns, "—", 2, function()
		setMinimized(not State.minimized)
	end)
	makeTopButton(btns, "×", 3, function()
		closeWindow()
	end)

	bindDrag(top, window)
	track(top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- double-click minimize handled loosely
		end
	end))

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(0, 46)
	body.Size = UDim2.new(1, 0, 1, -74)
	body.BackgroundTransparency = 1
	body.ZIndex = 2
	body.Parent = window
	State.body = body

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 92, 1, 0)
	sidebar.BackgroundColor3 = Theme.TabBar
	sidebar.BackgroundTransparency = 0.48
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 2
	sidebar.ScrollBarImageColor3 = Theme.Ice
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.ZIndex = 2
	sidebar.Parent = body
	round(sidebar, 20)
	pad(sidebar, 6)
	local sLay = Instance.new("UIListLayout")
	sLay.Padding = UDim.new(0, 4)
	sLay.SortOrder = Enum.SortOrder.LayoutOrder
	sLay.Parent = sidebar
	State.sidebar = sidebar

	local content = Instance.new("ScrollingFrame")
	content.Name = "ContentHost"
	content.Position = UDim2.fromOffset(92, 0)
	content.Size = UDim2.new(1, -92, 1, 0)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 3
	content.ScrollBarImageColor3 = Theme.Ice
	content.ZIndex = 2
	content.Parent = body
	State.content = content

	local footer = Instance.new("TextLabel")
	footer.Name = "Footer"
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 0, 1, 0)
	footer.Size = UDim2.new(1, 0, 0, 28)
	footer.BackgroundColor3 = Theme.Topbar
	footer.BackgroundTransparency = 0.45
	footer.BorderSizePixel = 0
	footer.Font = Enum.Font.GothamBold
	footer.TextSize = 10
	footer.TextColor3 = Theme.Ice
	footer.Text = "  FROST HUB"
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.ZIndex = 2
	footer.Parent = window
	State.footer = footer

	track(UIS.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == State.keybind then
			if State.closed or not State.visible then
				openWindow()
			else
				closeWindow()
			end
		end
	end))
end

local function playLoading(opts, done)
	local gui = State.gui
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(7, 18, 38)
	overlay.BackgroundTransparency = 0.25
	overlay.ZIndex = 20
	overlay.Parent = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(340, 110)
	card.BackgroundColor3 = Theme.Background
	card.BackgroundTransparency = 0.22
	card.ZIndex = 21
	card.Parent = overlay
	round(card, 24)
	stroke(card, Theme.Neon, 1.6, 0.1)

	local t1 = Instance.new("TextLabel")
	t1.BackgroundTransparency = 1
	t1.Position = UDim2.fromOffset(20, 18)
	t1.Size = UDim2.new(1, -40, 0, 24)
	t1.Font = Enum.Font.GothamBold
	t1.TextSize = 18
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.TextColor3 = Theme.TextColor
	t1.Text = opts.LoadingTitle or "Loading..."
	t1.ZIndex = 22
	t1.Parent = card

	local t2 = Instance.new("TextLabel")
	t2.BackgroundTransparency = 1
	t2.Position = UDim2.fromOffset(20, 44)
	t2.Size = UDim2.new(1, -40, 0, 18)
	t2.Font = Enum.Font.Gotham
	t2.TextSize = 13
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.TextColor3 = Theme.TextMuted
	t2.Text = opts.LoadingSubtitle or "Frostfield"
	t2.ZIndex = 22
	t2.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(20, 78)
	barBg.Size = UDim2.new(1, -40, 0, 6)
	barBg.BackgroundColor3 = Theme.Topbar
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 22
	barBg.Parent = card
	round(barBg, "pill")

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Theme.Highlight
	bar.BorderSizePixel = 0
	bar.ZIndex = 23
	bar.Parent = barBg
	round(bar, "pill")

	tween(bar, 1.6, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quad)
	task.delay(1.7, function()
		overlay:Destroy()
		done()
	end)
end

local function createPage()
	local page = Instance.new("Frame")
	page.BackgroundTransparency = 1
	page.Size = UDim2.fromScale(1, 1)
	page.Visible = false
	page.Parent = State.content

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(1, 1)
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = Theme.Ice
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.BorderSizePixel = 0
	list.Parent = page
	pad(list, 10)

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = list

	return page, list
end

local TabApi = {}
TabApi.__index = TabApi

function TabApi:CreateToggle(opts)
	opts = opts or {}
	local flag = opts.Flag
	local value = opts.CurrentValue and true or false
	if flag and Frostfield.Flags[flag] ~= nil then
		value = Frostfield.Flags[flag] and true or false
	end

	local row = makeElement(self._list)
	row.Size = UDim2.new(1, 0, 0, 44)
	local name = makeLabel(row, opts.Name or "Toggle")

	local sw = Instance.new("Frame")
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -12, 0.5, 0)
	sw.Size = UDim2.fromOffset(38, 20)
	sw.BackgroundColor3 = value and Theme.Highlight or Color3.fromRGB(8, 16, 32)
	sw.BorderSizePixel = 0
	sw.Parent = row
	round(sw, "pill")
	stroke(sw, Theme.Ice, 1, value and 0.25 or 0.6)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Theme.TextColor
	knob.BorderSizePixel = 0
	knob.Parent = sw
	round(knob, "pill")

	local api = {}
	local busy = false
	local blocked = false

	local function paint(v)
		sw.BackgroundColor3 = v and Theme.Highlight or Color3.fromRGB(8, 16, 32)
		knob.Position = v and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3)
	end

	local function write(v)
		value = v and true or false
		if flag then
			Frostfield.Flags[flag] = value
			saveConfig()
		end
		paint(value)
	end

	function api:Set(v)
		local on = v and true or false
		if busy then
			if not on then
				blocked = true
			end
			write(on)
			return
		end
		if on == value then
			write(on)
			return
		end
		if on then
			if opts.RequiredFlags then
				local req = opts.RequiredFlags
				if type(req) == "string" then
					req = { req }
				end
				local ready = false
				for _, f in ipairs(req) do
					if Frostfield.Flags[f] then
						ready = true
						if not opts.RequiredAll then
							break
						end
					elseif opts.RequiredAll then
						ready = false
						break
					end
				end
				if not ready then
					busy = true
					pcall(function()
						if opts.Callback then
							opts.Callback(true)
						end
					end)
					busy = false
					write(false)
					return
				end
			end
			blocked = false
			busy = true
			local ok, result = pcall(function()
				if opts.Callback then
					return opts.Callback(true)
				end
				return true
			end)
			busy = false
			if blocked or (ok and result == false) then
				write(false)
				return
			end
			write(true)
			return
		end
		write(false)
		if opts.Callback then
			busy = true
			pcall(opts.Callback, false)
			busy = false
		end
	end

	track(row.MouseButton1Click:Connect(function()
		api:Set(not value)
	end))

	if flag then
		Frostfield.Flags[flag] = value
	end
	if opts.Callback and value then
		task.defer(function()
			pcall(opts.Callback, value)
		end)
	end
	return api
end

function TabApi:CreateButton(opts)
	opts = opts or {}
	local row = makeNeonButton(self._list)
	local name = makeLabel(row, opts.Name or "Button")
	name.Size = UDim2.new(1, -24, 1, 0)

	local api = {}
	function api:Set(text)
		name.Text = tostring(text)
	end

	track(row.MouseButton1Click:Connect(function()
		if opts.Callback then
			local ok, result = pcall(opts.Callback)
			if ok and result == false then
				return
			end
		end
	end))
	return api
end

function TabApi:CreateParagraph(opts)
	opts = opts or {}
	local row = makeElement(self._list)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 58)
	row.Active = false
	row.AutoButtonColor = false

	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, -24, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.Position = UDim2.fromOffset(12, 8)
	wrap.Parent = row

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.Parent = wrap

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TextColor
	title.Text = opts.Title or ""
	title.Parent = wrap

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextColor3 = Theme.TextMuted
	body.Text = opts.Content or ""
	body.Parent = wrap

	local spacer = Instance.new("Frame")
	spacer.BackgroundTransparency = 1
	spacer.Size = UDim2.new(1, 0, 0, 8)
	spacer.Parent = wrap
	return {}
end

function TabApi:CreateSlider(opts)
	opts = opts or {}
	local minV = (opts.Range and opts.Range[1]) or 0
	local maxV = (opts.Range and opts.Range[2]) or 100
	local step = opts.Increment or 1
	local value = opts.CurrentValue or minV
	local flag = opts.Flag
	if flag and type(Frostfield.Flags[flag]) == "number" then
		value = Frostfield.Flags[flag]
	end
	value = math.clamp(value, minV, maxV)

	local row = makeElement(self._list)
	row.Size = UDim2.new(1, 0, 0, 58)
	row.Active = false

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Position = UDim2.fromOffset(12, 6)
	header.Size = UDim2.new(1, -24, 0, 18)
	header.Parent = row

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -50, 1, 0)
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 14
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Theme.TextColor
	name.Text = opts.Name or "Slider"
	name.Parent = header

	local val = Instance.new("TextLabel")
	val.BackgroundTransparency = 1
	val.AnchorPoint = Vector2.new(1, 0)
	val.Position = UDim2.fromScale(1, 0)
	val.Size = UDim2.fromOffset(50, 18)
	val.Font = Enum.Font.GothamMedium
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.TextColor3 = Theme.Ice
	val.Text = tostring(value)
	val.Parent = header

	local trackF = Instance.new("Frame")
	trackF.Position = UDim2.fromOffset(12, 34)
	trackF.Size = UDim2.new(1, -24, 0, 6)
	trackF.BackgroundColor3 = Color3.fromRGB(8, 16, 32)
	trackF.BorderSizePixel = 0
	trackF.Parent = row
	round(trackF, "pill")

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((value - minV) / math.max(maxV - minV, 1), 0, 1, 0)
	fill.BackgroundColor3 = Theme.Highlight
	fill.BorderSizePixel = 0
	fill.Parent = trackF
	round(fill, "pill")

	local api = {}
	local function apply(v)
		local snapped = math.floor((v / step) + 0.5) * step
		snapped = math.clamp(snapped, minV, maxV)
		value = snapped
		val.Text = tostring(value)
		fill.Size = UDim2.new((value - minV) / math.max(maxV - minV, 1), 0, 1, 0)
		if flag then
			Frostfield.Flags[flag] = value
			saveConfig()
		end
		if opts.Callback then
			pcall(opts.Callback, value)
		end
	end

	function api:Set(v)
		apply(v)
	end

	local sliding = false
	local function fromX(x)
		local abs = trackF.AbsolutePosition.X
		local w = trackF.AbsoluteSize.X
		local a = math.clamp((x - abs) / math.max(w, 1), 0, 1)
		apply(minV + a * (maxV - minV))
	end

	track(trackF.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			fromX(input.Position.X)
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end))
	track(UIS.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end))

	if flag then
		Frostfield.Flags[flag] = value
	end
	return api
end

function TabApi:CreateDropdown(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local current = opts.CurrentOption
	if type(current) == "table" then
		current = current[1] or options[1]
	end
	current = current or options[1] or "None"
	local flag = opts.Flag
	if flag and Frostfield.Flags[flag] then
		local saved = Frostfield.Flags[flag]
		if type(saved) == "table" then
			current = saved[1] or current
		elseif type(saved) == "string" then
			current = saved
		end
	end

	local row = makeElement(self._list)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 44)

	local head = Instance.new("TextButton")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 44)
	head.Text = ""
	head.AutoButtonColor = false
	head.Parent = row

	local name = makeLabel(head, opts.Name or "Dropdown")
	local valueLbl = Instance.new("TextLabel")
	valueLbl.BackgroundTransparency = 1
	valueLbl.AnchorPoint = Vector2.new(1, 0.5)
	valueLbl.Position = UDim2.new(1, -14, 0.5, 0)
	valueLbl.Size = UDim2.fromOffset(120, 20)
	valueLbl.Font = Enum.Font.Gotham
	valueLbl.TextSize = 13
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right
	valueLbl.TextColor3 = Theme.Ice
	valueLbl.Text = tostring(current)
	valueLbl.Parent = head

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(8, 44)
	holder.Size = UDim2.new(1, -16, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Visible = false
	holder.Parent = row
	local hLay = Instance.new("UIListLayout")
	hLay.Padding = UDim.new(0, 4)
	hLay.Parent = holder

	local open = false
	local api = {}

	local function selectOpt(opt)
		current = opt
		valueLbl.Text = tostring(opt)
		if flag then
			Frostfield.Flags[flag] = { opt }
			saveConfig()
		end
		if opts.Callback then
			pcall(opts.Callback, { opt })
		end
		open = false
		holder.Visible = false
	end

	local function rebuild(list)
		holder:ClearAllChildren()
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 4)
		lay.Parent = holder
		for _, opt in ipairs(list) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 28)
			b.BackgroundColor3 = Theme.Background
			b.BackgroundTransparency = 0.3
			b.Text = "  " .. tostring(opt)
			b.Font = Enum.Font.Gotham
			b.TextSize = 13
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextColor3 = Theme.TextColor
			b.AutoButtonColor = false
			b.Parent = holder
			round(b, "pill")
			track(b.MouseButton1Click:Connect(function()
				selectOpt(opt)
			end))
		end
	end

	rebuild(options)

	function api:Set(opt)
		if type(opt) == "table" then
			opt = opt[1]
		end
		selectOpt(opt)
	end
	function api:Refresh(list)
		options = list or options
		rebuild(options)
	end

	track(head.MouseButton1Click:Connect(function()
		open = not open
		holder.Visible = open
	end))

	if flag then
		Frostfield.Flags[flag] = { current }
	end
	return api
end

function TabApi:CreateLabel(opts)
	return self:CreateParagraph({ Title = opts and opts.Name or "", Content = "" })
end

function TabApi:CreateSection(opts)
	return self:CreateParagraph({ Title = type(opts) == "string" and opts or (opts and opts.Name) or "Section", Content = "" })
end

function TabApi:CreateInput(opts)
	opts = opts or {}
	local row = makeElement(self._list)
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Active = false
	makeLabel(row, opts.Name or "Input").Size = UDim2.new(0.45, 0, 1, 0)

	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -12, 0.5, 0)
	box.Size = UDim2.new(0.48, 0, 0, 26)
	box.BackgroundColor3 = Theme.Background
	box.BackgroundTransparency = 0.25
	box.Font = Enum.Font.Gotham
	box.TextSize = 13
	box.TextColor3 = Theme.TextColor
	box.PlaceholderText = opts.PlaceholderText or ""
	box.Text = opts.CurrentValue or ""
	box.ClearTextOnFocus = false
	box.Parent = row
	round(box, "pill")
	stroke(box, Theme.Neon, 1.4, 0.12)

	local api = {}
	function api:Set(t)
		box.Text = tostring(t)
		if opts.Callback then
			pcall(opts.Callback, box.Text)
		end
	end
	track(box.FocusLost:Connect(function()
		if opts.Callback then
			pcall(opts.Callback, box.Text)
		end
		if opts.RemoveTextAfterFocusLost then
			box.Text = ""
		end
	end))
	return api
end

function TabApi:CreateKeybind(opts)
	return self:CreateButton({
		Name = (opts and opts.Name or "Keybind") .. "  [" .. tostring(opts and opts.CurrentKeybind or "None") .. "]",
		Callback = opts and opts.Callback,
	})
end

function TabApi:CreateColorPicker(opts)
	return self:CreateButton({
		Name = opts and opts.Name or "Color",
		Callback = function()
			if opts and opts.Callback then
				pcall(opts.Callback, opts.Color or Theme.Highlight)
			end
		end,
	})
end

local WindowApi = {}
WindowApi.__index = WindowApi

function WindowApi:CreateTab(name, image)
	local id = HttpService:GenerateGUID(false)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 54)
	btn.BackgroundTransparency = 1
	btn.BackgroundColor3 = Theme.Highlight
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = State.sidebar
	round(btn, "pill")
	stroke(btn, Theme.Neon, 1.2, 0.45)

	local icon
	if string.lower(tostring(name or "")):find("setting") then
		icon = drawGear(btn)
	else
		icon = makeIcon(btn, image)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 8)
	end

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(2, 28)
	label.Size = UDim2.new(1, -4, 0, 22)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 10
	label.TextWrapped = true
	label.TextColor3 = Theme.TextMuted
	label.Text = tostring(name or "Tab")
	label.Parent = btn
	btn.TextColor3 = Theme.TextMuted

	local page, list = createPage()
	State.tabs[id] = { button = btn, page = page, icon = icon, name = name }

	track(btn.MouseButton1Click:Connect(function()
		switchTab(id)
	end))

	if not State.activeTab then
		switchTab(id)
	end

	return setmetatable({ _list = list, _id = id, Name = name }, TabApi)
end

function Frostfield:CreateWindow(opts)
	opts = opts or {}
	State.config = opts.ConfigurationSaving
	if opts.ToggleUIKeybind then
		local k = opts.ToggleUIKeybind
		if typeof(k) == "EnumItem" then
			State.keybind = k
		elseif type(k) == "string" then
			State.keybind = Enum.KeyCode[k] or Enum.KeyCode.K
		end
	end
	loadConfig()
	buildChrome(opts)

	if opts.Theme and type(opts.Theme) == "table" then
		self:UpdateTheme(opts.Theme)
	end

	State.window.Visible = false
	playLoading(opts, function()
		if State.window then
			State.window.Visible = true
		end
	end)

	return setmetatable({}, WindowApi)
end

return Frostfield
