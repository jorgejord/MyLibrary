-- ===========================================================
--  ZephyrUI - portable single-file Lua GUI library
--  For Roblox exploit / CoreGui context
--
--  Usage:
--    local Zephyr = loadstring(game:HttpGet(
--      "https://raw.githubusercontent.com/USER/REPO/main/ZephyrUI.lua"))()
--
--    local win = Zephyr.Window({ Title = "My Hub" })
--    local tab = win:Tab("Main")
--    tab:Section("General")
--    tab:Toggle({ Text = "Enable", Callback = function(v) end })
--
--  Public API:
--    Zephyr.Window(opts) -> Window
--    Zephyr.Notify(opts)
--    Zephyr.SetTheme(overrides)
--    Zephyr.Theme    (theme table)
--    Zephyr.Accents  (accent presets)
--  Window: :Tab :BindKey :SetAccent :Destroy
--  Tab:    :Section :Toggle :Button :Slider :Label :Dropdown :Keybind :Paragraph
-- ===========================================================


local TweenService     = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

local hasFS = (typeof(writefile) == "function")
	and (typeof(readfile) == "function")
	and (typeof(isfile) == "function")
local makeFolder = (typeof(makefolder) == "function") and makefolder or nil
local folderExists = (typeof(isfolder) == "function") and isfolder or nil
local setClip = (typeof(setclipboard) == "function") and setclipboard
	or (typeof(toclipboard) == "function") and toclipboard or nil

local function getContainer()
	if gethui then return gethui() end
	if syn and syn.protect_gui then
		local gui = Instance.new("ScreenGui")
		syn.protect_gui(gui)
		gui.Parent = game:GetService("CoreGui")
		return gui
	end
	local okCore = pcall(function()
		local g = Instance.new("ScreenGui")
		g.Name = "ZephyrUI_host"
		g.ResetOnSpawn = false
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.Parent = game:GetService("CoreGui")
		return g
	end)
	if okCore then
		local g = game:GetService("CoreGui"):FindFirstChild("ZephyrUI_host")
		if g then return g end
	end
	local gui = Instance.new("ScreenGui")
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local T = {
	BG          = Color3.fromRGB(23,  25,  32),
	SURFACE     = Color3.fromRGB(30,  33,  41),
	SURFACE2    = Color3.fromRGB(40,  44,  54),
	SURFACE3    = Color3.fromRGB(52,  57,  69),
	SIDEBAR     = Color3.fromRGB(26,  28,  36),
	BORDER      = Color3.fromRGB(55,  60,  73),
	BORDER2     = Color3.fromRGB(42,  46,  57),

	GRAD_TOP    = Color3.fromRGB(34,  37,  46),
	GRAD_BOT    = Color3.fromRGB(24,  26,  33),
	CARD_TOP    = Color3.fromRGB(35,  39,  48),
	CARD_BOT    = Color3.fromRGB(28,  31,  39),

	ACCENT      = Color3.fromRGB(99,  169, 240),
	ACCENT_H    = Color3.fromRGB(132, 191, 250),
	ACCENT_DIM  = Color3.fromRGB(41,  72,  112),

	TEXT        = Color3.fromRGB(233, 237, 243),
	TEXT_SUB    = Color3.fromRGB(174, 183, 198),
	TEXT_MUTED  = Color3.fromRGB(130, 140, 158),

	SUCCESS     = Color3.fromRGB(74,  201, 155),
	DANGER      = Color3.fromRGB(238, 111, 111),
	WARN        = Color3.fromRGB(240, 187, 89),
	INFO        = Color3.fromRGB(99,  169, 240),

	RADIUS      = 12,
	RADIUS_SM   = 9,
	RADIUS_LG   = 14,

	TWEEN_FAST  = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TWEEN_MED   = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	TWEEN_SLOW  = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),

	FONT        = Enum.Font.GothamMedium,
	FONT_BOLD   = Enum.Font.GothamBold,
	FONT_MONO   = Enum.Font.Code,
}

local ACCENT_PRESETS = {
	Azure   = { Color3.fromRGB(99,169,240),  Color3.fromRGB(132,191,250), Color3.fromRGB(41,72,112) },
	Indigo  = { Color3.fromRGB(99,102,241),  Color3.fromRGB(129,132,255), Color3.fromRGB(49,51,120) },
	Emerald = { Color3.fromRGB(16,185,129),  Color3.fromRGB(52,211,153),  Color3.fromRGB(6,78,59)   },
	Rose    = { Color3.fromRGB(244,63,94),   Color3.fromRGB(251,113,133), Color3.fromRGB(120,30,45) },
	Amber   = { Color3.fromRGB(245,158,11),  Color3.fromRGB(251,191,36),  Color3.fromRGB(120,75,10) },
	Sky     = { Color3.fromRGB(14,165,233),  Color3.fromRGB(56,189,248),  Color3.fromRGB(8,80,115)  },
	Violet  = { Color3.fromRGB(139,92,246),  Color3.fromRGB(167,139,250), Color3.fromRGB(70,40,120) },
}

local function tween(obj, props, info)
	local tw = TweenService:Create(obj, info or T.TWEEN_FAST, props)
	tw:Play()
	return tw
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or T.RADIUS)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or T.BORDER
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1 or T.GRAD_TOP, c2 or T.GRAD_BOT)
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

local function padding(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, l)
	p.PaddingRight  = UDim.new(0, r or l)
	p.PaddingTop    = UDim.new(0, t or l)
	p.PaddingBottom = UDim.new(0, b or t or l)
	p.Parent = parent
	return p
end

local function listLayout(parent, dir, spacing, align)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.Padding = UDim.new(0, spacing or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	if align then l.HorizontalAlignment = align end
	l.Parent = parent
	return l
end

local function newLabel(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextSize = size or 13
	l.TextColor3 = color or T.TEXT
	l.Font = font or T.FONT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Size = UDim2.new(1, 0, 0, size or 13)
	l.RichText = true
	l.Parent = parent
	return l
end

local function newFrame(parent, size, color)
	local f = Instance.new("Frame")
	f.Size = size or UDim2.new(1, 0, 0, 0)
	f.BackgroundColor3 = color or T.SURFACE
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function makeDraggable(handle, target, onDone)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if onDone then onDone() end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function class(t) t.__index = t return t end

local function normalize(a, b, c, d, e)
	if type(a) == "table" then return a end
	return { Text = a, Default = b, Callback = c, _p3 = d, _p4 = e }
end

local Tooltip = {}
do
	local gui, lbl
	function Tooltip.init(screenGui)
		if gui then return end
		gui = Instance.new("Frame")
		gui.Name = "ZephyrTooltip"
		gui.BackgroundColor3 = T.SURFACE3
		gui.BorderSizePixel = 0
		gui.Visible = false
		gui.ZIndex = 200
		gui.AutomaticSize = Enum.AutomaticSize.XY
		gui.Parent = screenGui
		corner(gui, 6)
		stroke(gui, T.BORDER, 1)
		padding(gui, 8, 8, 5, 5)
		lbl = newLabel(gui, "", 12, T.TEXT)
		lbl.ZIndex = 201
		lbl.AutomaticSize = Enum.AutomaticSize.XY
		lbl.Size = UDim2.new(0, 0, 0, 0)
	end
	function Tooltip.attach(target, text)
		if not text or text == "" then return end
		target.MouseEnter:Connect(function()
			if not gui then return end
			lbl.Text = text
			gui.Visible = true
		end)
		target.MouseMoved:Connect(function()
			if not gui or not gui.Visible then return end
			local m = UserInputService:GetMouseLocation()
			gui.Position = UDim2.fromOffset(m.X + 14, m.Y - 4)
		end)
		target.MouseLeave:Connect(function()
			if gui then gui.Visible = false end
		end)
	end
end

local Config = class({})
function Config.new(name)
	local self = setmetatable({}, Config)
	self.name = name
	self.flags = {}        
	self.values = {}       
	self.folder = "ZephyrUI"
	self.path = self.folder .. "/" .. tostring(name) .. ".json"
	self.enabled = hasFS and name ~= nil
	if self.enabled and makeFolder and folderExists then
		pcall(function()
			if not folderExists(self.folder) then makeFolder(self.folder) end
		end)
	end
	return self
end
function Config:register(flag, getter, setter)
	if not flag then return end
	self.flags[flag] = { get = getter, set = setter }
end
function Config:set(flag, v)
	if flag then self.values[flag] = v end
end
function Config:get(flag) return self.values[flag] end

local function encodeJSON(tbl)
	local okHS, HS = pcall(function() return game:GetService("HttpService") end)
	if okHS and HS then
		local ok, s = pcall(function() return HS:JSONEncode(tbl) end)
		if ok then return s end
	end
	return "{}"
end
local function decodeJSON(s)
	local okHS, HS = pcall(function() return game:GetService("HttpService") end)
	if okHS and HS then
		local ok, t = pcall(function() return HS:JSONDecode(s) end)
		if ok and type(t) == "table" then return t end
	end
	return {}
end

function Config:save()
	if not self.enabled then return false end
	local snap = {}
	for flag, fns in pairs(self.flags) do
		local ok, v = pcall(fns.get)
		if ok then
			
			if typeof(v) == "Color3" then
				snap[flag] = { __c3 = true, r = v.R, g = v.G, b = v.B }
			elseif typeof(v) == "EnumItem" then
				snap[flag] = { __enum = tostring(v) }
			else
				snap[flag] = v
			end
		end
	end
	local okW = pcall(function() writefile(self.path, encodeJSON(snap)) end)
	return okW
end

function Config:load()
	if not self.enabled then return false end
	local okR, raw = pcall(function()
		if isfile(self.path) then return readfile(self.path) end
	end)
	if not okR or not raw then return false end
	local data = decodeJSON(raw)
	for flag, v in pairs(data) do
		local fns = self.flags[flag]
		if fns then
			local val = v
			if type(v) == "table" and v.__c3 then
				val = Color3.new(v.r, v.g, v.b)
			elseif type(v) == "table" and v.__enum then
				
				local parts = string.split(v.__enum, ".")
				if #parts == 3 and Enum[parts[2]] then
					val = Enum[parts[2]][parts[3]]
				end
			end
			pcall(fns.set, val)
		end
	end
	return true
end

local Notif = {}
function Notif.show(screenGui, opts)
	opts = opts or {}
	local title    = opts.Title or ""
	local message  = opts.Text or opts.Content or ""
	local ntype    = opts.Type or "info"
	local duration = opts.Duration or 3
	local icons  = { success = "✅", danger = "❌", warn = "⚠️", info = "ℹ️" }
	local colors = { success = T.SUCCESS, danger = T.DANGER, warn = T.WARN, info = T.INFO }
	local accent = colors[ntype] or T.INFO
	local icon   = icons[ntype] or "ℹ️"

	local holder = screenGui:FindFirstChild("ZephyrNotifs")
	if not holder then
		holder = Instance.new("Frame")
		holder.Name = "ZephyrNotifs"
		holder.AnchorPoint = Vector2.new(1, 1)
		holder.Position = UDim2.new(1, -20, 1, -20)
		holder.Size = UDim2.new(0, 340, 1, -40)
		holder.BackgroundTransparency = 1
		holder.ZIndex = 150
		holder.Parent = screenGui
		local ll = Instance.new("UIListLayout")
		ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ll.Padding = UDim.new(0, 10)
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Parent = holder
	end

	local card = newFrame(holder, UDim2.new(1, 0, 0, 0), T.SURFACE)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundTransparency = 1
	card.ClipsDescendants = true
	card.ZIndex = 151
	corner(card, T.RADIUS)
	local cardStroke = stroke(card, accent, 1)
	cardStroke.Transparency = 0.5

	local sideBar = newFrame(card, UDim2.new(0, 3, 1, 0), accent)
	sideBar.Position = UDim2.new(0, 0, 0, 0); sideBar.ZIndex = 153

	local contentWrap = newFrame(card, UDim2.new(1, 0, 0, 0), T.SURFACE)
	contentWrap.BackgroundTransparency = 1
	contentWrap.AutomaticSize = Enum.AutomaticSize.Y
	contentWrap.ZIndex = 152
	padding(contentWrap, 14, 12, 10, 12)
	local cwLayout = Instance.new("UIListLayout")
	cwLayout.FillDirection = Enum.FillDirection.Vertical
	cwLayout.Padding = UDim.new(0, 4)
	cwLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cwLayout.Parent = contentWrap

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 20)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = 1
	row.ZIndex = 153
	row.Parent = contentWrap

	local iconLbl = newLabel(row, icon, 15, accent)
	iconLbl.Size = UDim2.new(0, 22, 0, 20); iconLbl.ZIndex = 154
	iconLbl.TextXAlignment = Enum.TextXAlignment.Left

	local titleLbl = newLabel(row, title, 14, T.TEXT, T.FONT_BOLD)
	titleLbl.Position = UDim2.new(0, 26, 0, 0)
	titleLbl.Size = UDim2.new(1, -26, 0, 20)
	titleLbl.AutomaticSize = Enum.AutomaticSize.Y
	titleLbl.TextWrapped = true; titleLbl.ZIndex = 154

	if message ~= "" then
		local msgLbl = newLabel(contentWrap, message, 12, T.TEXT_SUB)
		msgLbl.Size = UDim2.new(1, 0, 0, 14)
		msgLbl.TextWrapped = true
		msgLbl.AutomaticSize = Enum.AutomaticSize.Y
		msgLbl.LayoutOrder = 2
		msgLbl.ZIndex = 153
	end

	local progressBG = newFrame(card, UDim2.new(1, 0, 0, 3), T.SURFACE3)
	progressBG.AnchorPoint = Vector2.new(0, 1)
	progressBG.Position = UDim2.new(0, 0, 1, 0)
	progressBG.ZIndex = 153
	local progressBar = newFrame(progressBG, UDim2.new(1, 0, 1, 0), accent)
	progressBar.ZIndex = 154

	tween(card, { BackgroundTransparency = 0 }, T.TWEEN_MED)

	task.spawn(function()
		local steps = 60
		for i = steps, 0, -1 do
			if not progressBar.Parent then break end
			local ratio = i / steps
			progressBar.Size = UDim2.new(ratio, 0, 1, 0)
			task.wait(duration / steps)
		end
	end)

	task.delay(duration, function()
		tween(card, { BackgroundTransparency = 1 }, T.TWEEN_MED)
		task.wait(0.25)
		pcall(function() card:Destroy() end)
	end)
end

local function shortKeyName(kc)
	if not kc then return "Set" end
	local n = kc.Name
	local map = {
		RightControl = "RCtrl", LeftControl = "LCtrl",
		RightShift = "RShift", LeftShift = "LShift",
		RightAlt = "RAlt", LeftAlt = "LAlt",
		ButtonR1 = "R1", ButtonL1 = "L1",
	}
	return map[n] or n
end

local function mkToggle(parent, opts, ctx)
	local self = {}
	local state = opts.Default and true or false
	local keybind = opts.Keybind   
	local row = newFrame(parent, UDim2.new(1, 0, 0, 34), T.SURFACE2)
	corner(row, T.RADIUS_SM)
	padding(row, 10, 8, 0, 0)

	local lbl = newLabel(row, opts.Text or "Toggle", 13, T.TEXT)
	lbl.Size = UDim2.new(1, -90, 1, 0)

	local track = newFrame(row, UDim2.new(0, 40, 0, 20),
		state and T.ACCENT or T.BORDER)
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, 0, 0.5, 0)
	corner(track, 10)
	local knob = newFrame(track, UDim2.new(0, 16, 0, 16), Color3.new(1,1,1))
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = state and UDim2.new(1,-18,0.5,0) or UDim2.new(0,2,0.5,0)
	corner(knob, 8)

	local kbBtn
	if opts.Keybind ~= nil or opts.ShowKeybind then
		kbBtn = Instance.new("TextButton")
		kbBtn.Size = UDim2.new(0, 56, 0, 22)
		kbBtn.AnchorPoint = Vector2.new(1, 0.5)
		kbBtn.Position = UDim2.new(1, -56, 0.5, 0)   
		kbBtn.BackgroundColor3 = T.SURFACE3
		kbBtn.Font = T.FONT_BOLD
		kbBtn.TextSize = 10
		kbBtn.TextColor3 = T.TEXT_SUB
		kbBtn.Text = shortKeyName(keybind)
		kbBtn.AutoButtonColor = false
		kbBtn.ZIndex = 3
		kbBtn.Parent = row
		corner(kbBtn, 6)
		stroke(kbBtn, T.BORDER, 1)
		kbBtn.MouseEnter:Connect(function() tween(kbBtn,{BackgroundColor3=T.ACCENT_DIM}) end)
		kbBtn.MouseLeave:Connect(function() tween(kbBtn,{BackgroundColor3=T.SURFACE3}) end)
		lbl.Size = UDim2.new(1, -130, 1, 0)
		local listening = false
		kbBtn.MouseButton1Click:Connect(function()
			listening = true
			kbBtn.Text = "..."
			kbBtn.TextColor3 = T.ACCENT_H
		end)
		UserInputService.InputBegan:Connect(function(i, gpe)
			if listening and i.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				keybind = i.KeyCode
				kbBtn.Text = shortKeyName(keybind)
				kbBtn.TextColor3 = T.TEXT_SUB
			elseif keybind and not gpe and i.KeyCode == keybind then
				self:Set(not state)
			end
		end)
	end

	local function set(v, fromInit)
		state = v and true or false
		tween(track, { BackgroundColor3 = state and T.ACCENT or T.BORDER })
		tween(knob, { Position = state and UDim2.new(1,-18,0.5,0)
			or UDim2.new(0,2,0.5,0) })
		if ctx.config then ctx.config:set(opts.Flag, state) end
		if opts.Callback and not fromInit then task.spawn(opts.Callback, state) end
	end
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1; hit.Text = ""
	hit.Size = kbBtn and UDim2.new(1,-100,1,0) or UDim2.new(1,0,1,0)
	hit.Parent = row; hit.ZIndex = 2
	hit.MouseButton1Click:Connect(function() set(not state) end)

	if opts.Tooltip then Tooltip.attach(row, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return state end,
			function(v) set(v, true) end)
	end

	self.Set = function(_, v) set(v) end
	self.Get = function() return state end
	self._row = row
	self._label = opts.Text or "Toggle"
	return self
end

local function mkSlider(parent, opts, ctx)
	local self = {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local decimals = opts.Decimals or 0
	local value = math.clamp(opts.Default or min, min, max)
	local suffix = opts.Suffix or ""

	local function round(v)
		if decimals <= 0 then return math.floor(v + 0.5) end
		local m = 10 ^ decimals
		return math.floor(v * m + 0.5) / m
	end

	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 46), T.SURFACE2)
	corner(wrap, T.RADIUS_SM)
	padding(wrap, 10, 10, 6, 0)

	local lbl = newLabel(wrap, opts.Text or "Slider", 12, T.TEXT)
	lbl.Size = UDim2.new(1, -60, 0, 14)
	local valLbl = newLabel(wrap, tostring(value) .. suffix, 12,
		T.ACCENT_H, T.FONT_BOLD)
	valLbl.Size = UDim2.new(0, 56, 0, 14)
	valLbl.Position = UDim2.new(1, -56, 0, 0)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = newFrame(wrap, UDim2.new(1, 0, 0, 6), T.BORDER)
	track.Position = UDim2.new(0, 0, 0, 26)
	corner(track, 3)
	local fill = newFrame(track, UDim2.new((value-min)/(max-min), 0, 1, 0), T.ACCENT)
	corner(fill, 3)
	local knob = newFrame(track, UDim2.new(0, 12, 0, 12), Color3.new(1,1,1))
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new((value-min)/(max-min), 0, 0.5, 0)
	corner(knob, 6)
	knob.ZIndex = 3

	local dragging = false
	local function setFromX(px, fire)
		local rel = math.clamp((px - track.AbsolutePosition.X)
			/ math.max(track.AbsoluteSize.X, 1), 0, 1)
		value = round(min + rel * (max - min))
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		valLbl.Text = tostring(value) .. suffix
		if ctx.config then ctx.config:set(opts.Flag, value) end
		if fire and opts.Callback then task.spawn(opts.Callback, value) end
	end
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1; hit.Text = ""
	hit.Size = UDim2.new(1, 0, 0, 22); hit.Position = UDim2.new(0,0,0,18)
	hit.Parent = wrap; hit.ZIndex = 4
	hit.MouseButton1Down:Connect(function()
		dragging = true
		setFromX(UserInputService:GetMouseLocation().X, true)
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(i.Position.X, true)
		end
	end)

	if opts.Tooltip then Tooltip.attach(wrap, opts.Tooltip) end
	local function setVal(v, fire)
		value = math.clamp(round(v), min, max)
		local rel = (value-min)/(max-min)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		valLbl.Text = tostring(value) .. suffix
		if ctx.config then ctx.config:set(opts.Flag, value) end
		if fire and opts.Callback then task.spawn(opts.Callback, value) end
	end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return value end,
			function(v) setVal(v, false) end)
	end

	self.Set = function(_, v) setVal(v, true) end
	self.Get = function() return value end
	self._row = wrap
	self._label = opts.Text or "Slider"
	return self
end

local function mkDropdown(parent, opts, ctx)
	local self = {}
	local options = opts.Options or {}
	local selected = opts.Default or options[1] or ""
	local open = false

	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 32), T.SURFACE2)
	corner(wrap, T.RADIUS_SM)

	local lbl = newLabel(wrap, opts.Text or "Dropdown", 12, T.TEXT_SUB)
	lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.5, -10, 1, 0)
	local valLbl = newLabel(wrap, tostring(selected), 12, T.TEXT, T.FONT_BOLD)
	valLbl.Position = UDim2.new(0.5, 0, 0, 0)
	valLbl.Size = UDim2.new(0.5, -28, 1, 0)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	local arrow = newLabel(wrap, "▼", 9, T.TEXT_MUTED)
	arrow.Position = UDim2.new(1, -20, 0, 0); arrow.Size = UDim2.new(0, 14, 1, 0)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local ddContainer
	if gethui then ddContainer = gethui()
	else
		local ok, cg = pcall(function() return game:GetService("CoreGui") end)
		ddContainer = ok and cg or getContainer()
	end
	local ddSg = Instance.new("ScreenGui")
	ddSg.Name = "ZephyrDD_dropdown"; ddSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ddSg.ResetOnSpawn = false; ddSg.DisplayOrder = 999
	pcall(function() ddSg.Parent = ddContainer end)
	if not ddSg.Parent then ddSg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local listOuter = newFrame(ddSg, UDim2.new(0, 0, 0, 0), T.SURFACE)
	listOuter.Visible = false; listOuter.ZIndex = 1
	corner(listOuter, T.RADIUS_SM); stroke(listOuter, T.BORDER, 1)

	local ROW_H = 30
	local MAX_LIST_H = 220

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = T.ACCENT_DIM
	listFrame.CanvasSize = UDim2.new(0,0,0,0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Size = UDim2.new(1, 0, 1, 0)
	listFrame.ZIndex = 2
	listFrame.Parent = listOuter
	padding(listFrame, 4, 4, 4, 4)
	listLayout(listFrame, Enum.FillDirection.Vertical, 2)

	local function closeList()
		open = false; listOuter.Visible = false; arrow.Text = "▼"
	end

	local function positionList()
		local abs = wrap.AbsolutePosition
		local absSize = wrap.AbsoluteSize
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
			or Vector2.new(1280, 720)
		local fullH = #options * (ROW_H + 2) + 8
		local listH = math.min(fullH, MAX_LIST_H)
		local belowY = abs.Y + absSize.Y + 4
		
		if belowY + listH > vp.Y - 10 then
			local aboveY = abs.Y - listH - 4
			if aboveY < 10 then
				
				listH = math.max(120, vp.Y - belowY - 10)
				listOuter.Position = UDim2.fromOffset(abs.X, belowY)
			else
				listOuter.Position = UDim2.fromOffset(abs.X, aboveY)
			end
		else
			listOuter.Position = UDim2.fromOffset(abs.X, belowY)
		end
		listOuter.Size = UDim2.fromOffset(absSize.X, listH)
	end

	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1; btn.Text = ""
	btn.Size = UDim2.new(1, 0, 0, 32); btn.Parent = wrap; btn.ZIndex = 3

	local function rebuild()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(options) do
			local o = Instance.new("TextButton")
			o.Size = UDim2.new(1, 0, 0, ROW_H)
			o.BackgroundColor3 = T.SURFACE2
			o.BackgroundTransparency = (opt == selected) and 0 or 1
			o.Text = "  " .. tostring(opt)
			o.TextXAlignment = Enum.TextXAlignment.Left
			o.TextColor3 = (opt == selected) and T.ACCENT_H or T.TEXT
			o.Font = T.FONT; o.TextSize = 12; o.AutoButtonColor = false
			o.ZIndex = 3; o.Parent = listFrame
			corner(o, T.RADIUS_SM)
			o.MouseEnter:Connect(function()
				if opt ~= selected then tween(o,{BackgroundTransparency=0.5}) end end)
			o.MouseLeave:Connect(function()
				if opt ~= selected then tween(o,{BackgroundTransparency=1}) end end)
			
			o.Activated:Connect(function()
				selected = opt; valLbl.Text = tostring(opt)
				closeList(); rebuild()
				if ctx.config then ctx.config:set(opts.Flag, selected) end
				if opts.Callback then task.spawn(opts.Callback, opt) end
			end)
		end
	end
	rebuild()

	btn.MouseButton1Click:Connect(function()
		open = not open
		if open then
			rebuild(); positionList()
			listOuter.Visible = true; arrow.Text = "▲"
		else
			closeList()
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if not open then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		task.defer(function()
			if not open then return end
			local mp = game:GetService("UserInputService"):GetMouseLocation()
			local lpos, lsize = listOuter.AbsolutePosition, listOuter.AbsoluteSize
			local wpos, wsize = wrap.AbsolutePosition, wrap.AbsoluteSize
			local onList = mp.X >= lpos.X and mp.X <= lpos.X + lsize.X
				and mp.Y >= lpos.Y and mp.Y <= lpos.Y + lsize.Y
			local onWrap = mp.X >= wpos.X and mp.X <= wpos.X + wsize.X
				and mp.Y >= wpos.Y and mp.Y <= wpos.Y + wsize.Y
			if not onList and not onWrap then closeList() end
		end)
	end)

	if opts.Tooltip then Tooltip.attach(wrap, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return selected end,
			function(v) selected = v; valLbl.Text = tostring(v); rebuild() end)
	end

	self.Set = function(_, v) selected = v; valLbl.Text = tostring(v); rebuild()
		if opts.Callback then task.spawn(opts.Callback, v) end end
	self.Get = function() return selected end
	self.SetOptions = function(_, o) options = o or {}; rebuild() end
	self._row = wrap
	self._label = opts.Text or "Dropdown"
	return self
end

local function mkMultiDropdown(parent, opts, ctx)
	local self = {}
	local options = opts.Options or {}
	local chosen = {}
	for _, v in ipairs(opts.Default or {}) do chosen[v] = true end
	local open = false

	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 32), T.SURFACE2)
	corner(wrap, T.RADIUS_SM); wrap.ClipsDescendants = false
	local lbl = newLabel(wrap, opts.Text or "Select", 12, T.TEXT_SUB)
	lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.45, -10, 1, 0)
	local valLbl = newLabel(wrap, "", 12, T.TEXT, T.FONT_BOLD)
	valLbl.Position = UDim2.new(0.45, 0, 0, 0)
	valLbl.Size = UDim2.new(0.55, -28, 1, 0)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	local arrow = newLabel(wrap, "▼", 9, T.TEXT_MUTED)
	arrow.Position = UDim2.new(1, -20, 0, 0); arrow.Size = UDim2.new(0, 14, 1, 0)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local function summary()
		local n = 0; for _ in pairs(chosen) do n = n + 1 end
		if n == 0 then return "None" end
		if n <= 2 then
			local parts = {}
			for k in pairs(chosen) do parts[#parts+1] = tostring(k) end
			return table.concat(parts, ", ")
		end
		return n .. " selected"
	end
	valLbl.Text = summary()

	local listFrame = newFrame(wrap, UDim2.new(1, 0, 0, 0), T.SURFACE)
	listFrame.Position = UDim2.new(0, 0, 1, 4); listFrame.Visible = false
	listFrame.ZIndex = 30; listFrame.AutomaticSize = Enum.AutomaticSize.Y
	corner(listFrame, T.RADIUS_SM); stroke(listFrame, T.BORDER, 1)
	padding(listFrame, 4, 4, 4, 4)
	listLayout(listFrame, Enum.FillDirection.Vertical, 2)

	local function fire()
		valLbl.Text = summary()
		local arr = {}
		for k in pairs(chosen) do arr[#arr+1] = k end
		if ctx.config then ctx.config:set(opts.Flag, arr) end
		if opts.Callback then task.spawn(opts.Callback, arr) end
	end
	for _, opt in ipairs(options) do
		local o = Instance.new("TextButton")
		o.Size = UDim2.new(1, 0, 0, 26); o.BackgroundTransparency = 1
		o.Text = "  " .. tostring(opt); o.TextXAlignment = Enum.TextXAlignment.Left
		o.TextColor3 = T.TEXT; o.Font = T.FONT; o.TextSize = 12
		o.AutoButtonColor = false; o.ZIndex = 31; o.Parent = listFrame
		corner(o, 4)
		local tick = newLabel(o, chosen[opt] and "☑" or "☐", 13,
			chosen[opt] and T.ACCENT_H or T.TEXT_MUTED)
		tick.Position = UDim2.new(1, -22, 0, 0); tick.Size = UDim2.new(0, 18, 1, 0)
		tick.ZIndex = 32
		o.MouseButton1Click:Connect(function()
			chosen[opt] = not chosen[opt] or nil
			tick.Text = chosen[opt] and "☑" or "☐"
			tick.TextColor3 = chosen[opt] and T.ACCENT_H or T.TEXT_MUTED
			fire()
		end)
	end
	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1; btn.Text = ""
	btn.Size = UDim2.new(1, 0, 0, 32); btn.Parent = wrap; btn.ZIndex = 3
	btn.MouseButton1Click:Connect(function()
		open = not open; listFrame.Visible = open
		arrow.Text = open and "▲" or "▼"; wrap.ZIndex = open and 30 or 1
	end)

	if opts.Tooltip then Tooltip.attach(wrap, opts.Tooltip) end
	self.Get = function() local a={} for k in pairs(chosen) do a[#a+1]=k end return a end
	self._row = wrap
	self._label = opts.Text or "Select"
	return self
end

local function mkButton(parent, opts, ctx)
	local self = {}
	local variant = opts.Variant or "primary"
	local colors = { primary=T.ACCENT, danger=T.DANGER, ghost=T.SURFACE2, success=T.SUCCESS }
	local base = colors[variant] or T.ACCENT
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32); btn.BackgroundColor3 = base
	btn.Text = opts.Text or "Button"; btn.Font = T.FONT_BOLD; btn.TextSize = 13
	btn.TextColor3 = (variant == "ghost") and T.TEXT or Color3.new(1,1,1)
	btn.AutoButtonColor = false; btn.Parent = parent
	corner(btn, T.RADIUS_SM)
	if variant == "ghost" then stroke(btn, T.BORDER, 1) end
	btn.MouseEnter:Connect(function()
		tween(btn,{BackgroundColor3=(variant=="ghost") and T.BORDER or T.ACCENT_H}) end)
	btn.MouseLeave:Connect(function() tween(btn,{BackgroundColor3=base}) end)
	btn.MouseButton1Click:Connect(function()
		if opts.Callback then task.spawn(opts.Callback) end end)
	if opts.Tooltip then Tooltip.attach(btn, opts.Tooltip) end
	self.SetText = function(_, t) btn.Text = t end
	self._row = btn
	self._label = opts.Text or "Button"
	return self
end

local function mkLabel(parent, opts)
	local text = type(opts) == "table" and (opts.Text or "") or tostring(opts)
	local l = newLabel(parent, text, 12, T.TEXT_SUB)
	l.Size = UDim2.new(1, 0, 0, 16); l.TextWrapped = true
	l.AutomaticSize = Enum.AutomaticSize.Y
	return { Set = function(_, t) l.Text = tostring(t) end, _row = l, _label = text }
end

local function mkParagraph(parent, opts, ctx)
	opts = type(opts) == "table" and opts or { Title = tostring(opts) }
	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 0), T.SURFACE2)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	corner(wrap, T.RADIUS_SM); padding(wrap, 10, 10, 8, 8)
	listLayout(wrap, Enum.FillDirection.Vertical, 3)
	local titleLbl
	if opts.Title and opts.Title ~= "" then
		titleLbl = newLabel(wrap, opts.Title, 13, T.TEXT, T.FONT_BOLD)
		titleLbl.Size = UDim2.new(1,0,0,15); titleLbl.AutomaticSize = Enum.AutomaticSize.Y
		titleLbl.TextWrapped = true
	end
	local bodyLbl = newLabel(wrap, opts.Content or "", 12, T.TEXT_SUB)
	bodyLbl.Size = UDim2.new(1,0,0,14); bodyLbl.TextWrapped = true
	bodyLbl.AutomaticSize = Enum.AutomaticSize.Y
	return {
		Set = function(_, t) bodyLbl.Text = tostring(t) end,
		SetTitle = function(_, t) if titleLbl then titleLbl.Text = tostring(t) end end,
		_row = wrap, _label = (opts.Title or "") .. " " .. (opts.Content or ""),
	}
end

local function mkCheckbox(parent, opts, ctx)
	local self = {}
	local state = opts.Default and true or false
	local row = newFrame(parent, UDim2.new(1, 0, 0, 28), T.SURFACE2)
	corner(row, T.RADIUS_SM); padding(row, 10, 8, 0, 0)
	local box = newFrame(row, UDim2.new(0,16,0,16), state and T.ACCENT or T.BORDER)
	box.AnchorPoint = Vector2.new(0,0.5); box.Position = UDim2.new(0,0,0.5,0)
	corner(box, 4)
	local check = newLabel(box, "✓", 11, Color3.new(1,1,1), T.FONT_BOLD)
	check.Size = UDim2.new(1,0,1,0); check.TextXAlignment = Enum.TextXAlignment.Center
	check.Visible = state
	local lbl = newLabel(row, opts.Text or "Checkbox", 12, T.TEXT)
	lbl.Position = UDim2.new(0,24,0,0); lbl.Size = UDim2.new(1,-24,1,0)
	local function set(v, fromInit)
		state = v and true or false
		box.BackgroundColor3 = state and T.ACCENT or T.BORDER; check.Visible = state
		if ctx.config then ctx.config:set(opts.Flag, state) end
		if opts.Callback and not fromInit then task.spawn(opts.Callback, state) end
	end
	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1; btn.Text = ""
	btn.Size = UDim2.new(1,0,1,0); btn.Parent = row; btn.ZIndex = 2
	btn.MouseButton1Click:Connect(function() set(not state) end)
	if opts.Tooltip then Tooltip.attach(row, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return state end,
			function(v) set(v, true) end)
	end
	self.Set = function(_, v) set(v) end
	self.Get = function() return state end
	self._row = row; self._label = opts.Text or "Checkbox"
	return self
end

local function mkInput(parent, opts, ctx)
	local self = {}
	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 32), T.SURFACE2)
	corner(wrap, T.RADIUS_SM); padding(wrap, 10, 10, 0, 0)
	local hasLabel = opts.Text and opts.Text ~= ""
	if hasLabel then
		local l = newLabel(wrap, opts.Text, 11, T.TEXT_MUTED)
		l.Position = UDim2.new(0,0,0,3); l.Size = UDim2.new(0,80,1,-6)
	end
	local box = Instance.new("TextBox")
	box.BackgroundTransparency = 1
	box.Size = UDim2.new(1, hasLabel and -84 or 0, 1, 0)
	box.Position = UDim2.new(0, hasLabel and 84 or 0, 0, 0)
	box.PlaceholderText = opts.Placeholder or ""
	box.PlaceholderColor3 = T.TEXT_MUTED
	box.Text = opts.Default or ""
	box.TextColor3 = T.TEXT; box.Font = T.FONT_MONO; box.TextSize = 12
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false; box.Parent = wrap
	box.FocusLost:Connect(function(enter)
		if ctx.config then ctx.config:set(opts.Flag, box.Text) end
		if opts.Callback then task.spawn(opts.Callback, box.Text, enter) end
	end)
	if opts.Tooltip then Tooltip.attach(wrap, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return box.Text end,
			function(v) box.Text = tostring(v) end)
	end
	self.Get = function() return box.Text end
	self.Set = function(_, v) box.Text = tostring(v) end
	self._row = wrap; self._label = opts.Text or "Input"
	return self
end

local function mkKeybind(parent, opts, ctx)
	local self = {}
	local key = opts.Default   
	local listening = false
	local row = newFrame(parent, UDim2.new(1, 0, 0, 32), T.SURFACE2)
	corner(row, T.RADIUS_SM); padding(row, 10, 8, 0, 0)
	local lbl = newLabel(row, opts.Text or "Keybind", 13, T.TEXT)
	lbl.Size = UDim2.new(1, -70, 1, 0)
	local chip = Instance.new("TextButton")
	chip.Size = UDim2.new(0, 56, 0, 22); chip.AnchorPoint = Vector2.new(1,0.5)
	chip.Position = UDim2.new(1, 0, 0.5, 0); chip.BackgroundColor3 = T.SURFACE3
	chip.Font = T.FONT; chip.TextSize = 11; chip.TextColor3 = T.TEXT_SUB
	chip.Text = key and key.Name or "None"; chip.AutoButtonColor = false
	chip.Parent = row; corner(chip, 4)
	chip.MouseButton1Click:Connect(function()
		listening = true; chip.Text = "..."; chip.TextColor3 = T.ACCENT_H
	end)
	UserInputService.InputBegan:Connect(function(i, gpe)
		if listening and i.KeyCode ~= Enum.KeyCode.Unknown then
			listening = false; key = i.KeyCode
			chip.Text = key.Name; chip.TextColor3 = T.TEXT_SUB
			if ctx.config then ctx.config:set(opts.Flag, key) end
			if opts.Changed then task.spawn(opts.Changed, key) end
		elseif key and not gpe and not listening and i.KeyCode == key then
			if opts.Callback then task.spawn(opts.Callback, key) end
		end
	end)
	if opts.Tooltip then Tooltip.attach(row, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return key end,
			function(v) key = v; chip.Text = (v and v.Name) or "None" end)
	end
	self.Get = function() return key end
	self.Set = function(_, v) key = v; chip.Text = (v and v.Name) or "None" end
	self._row = row; self._label = opts.Text or "Keybind"
	return self
end

local function mkColorPicker(parent, opts, ctx)
	local self = {}
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = Color3.toHSV(color)
	local open = false

	local row = newFrame(parent, UDim2.new(1, 0, 0, 32), T.SURFACE2)
	corner(row, T.RADIUS_SM); padding(row, 10, 8, 0, 0); row.ClipsDescendants = false
	local lbl = newLabel(row, opts.Text or "Color", 13, T.TEXT)
	lbl.Size = UDim2.new(1, -44, 1, 0)
	local swatch = newFrame(row, UDim2.new(0, 28, 0, 18), color)
	swatch.AnchorPoint = Vector2.new(1, 0.5); swatch.Position = UDim2.new(1, 0, 0.5, 0)
	corner(swatch, 4); stroke(swatch, T.BORDER, 1)

	local panel = newFrame(row, UDim2.new(1, 0, 0, 96), T.SURFACE)
	panel.Position = UDim2.new(0, 0, 1, 4); panel.Visible = false; panel.ZIndex = 30
	corner(panel, T.RADIUS_SM); stroke(panel, T.BORDER, 1)
	padding(panel, 8, 8, 8, 8); listLayout(panel, Enum.FillDirection.Vertical, 6)

	local function refresh(fire)
		color = Color3.fromHSV(h, s, v); swatch.BackgroundColor3 = color
		if ctx.config then ctx.config:set(opts.Flag, color) end
		if fire and opts.Callback then task.spawn(opts.Callback, color) end
	end
	local function hsvSlider(name, get, setf)
		local sl = newFrame(panel, UDim2.new(1, 0, 0, 22), T.SURFACE2)
		corner(sl, 4); padding(sl, 6, 6, 0, 0)
		local nm = newLabel(sl, name, 10, T.TEXT_SUB); nm.Size = UDim2.new(0, 14, 1, 0)
		local tr = newFrame(sl, UDim2.new(1, -22, 0, 5), T.BORDER)
		tr.AnchorPoint = Vector2.new(0,0.5); tr.Position = UDim2.new(0,18,0.5,0)
		corner(tr, 3)
		local fl = newFrame(tr, UDim2.new(get(), 0, 1, 0), T.ACCENT); corner(fl, 3)
		local dragging = false
		local function upd(px)
			local rel = math.clamp((px-tr.AbsolutePosition.X)/math.max(tr.AbsoluteSize.X,1),0,1)
			fl.Size = UDim2.new(rel,0,1,0); setf(rel); refresh(true)
		end
		local hit = Instance.new("TextButton"); hit.BackgroundTransparency=1; hit.Text=""
		hit.Size = UDim2.new(1,0,1,0); hit.Parent = sl; hit.ZIndex = 3
		hit.MouseButton1Down:Connect(function() dragging=true; upd(UserInputService:GetMouseLocation().X) end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
		return function() fl.Size = UDim2.new(get(),0,1,0) end
	end
	hsvSlider("H", function() return h end, function(r) h = r end)
	hsvSlider("S", function() return s end, function(r) s = r end)
	hsvSlider("V", function() return v end, function(r) v = r end)

	local btn = Instance.new("TextButton"); btn.BackgroundTransparency=1; btn.Text=""
	btn.Size = UDim2.new(1,0,0,32); btn.Parent = row; btn.ZIndex = 2
	btn.MouseButton1Click:Connect(function()
		open = not open; panel.Visible = open; row.ZIndex = open and 30 or 1 end)

	if opts.Tooltip then Tooltip.attach(row, opts.Tooltip) end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return color end,
			function(c) h,s,v = Color3.toHSV(c); refresh(false) end)
	end
	self.Get = function() return color end
	self.Set = function(_, c) h,s,v = Color3.toHSV(c); refresh(true) end
	self._row = row; self._label = opts.Text or "Color"
	return self
end

local function mkRadio(parent, opts, ctx)
	local self = {}
	local options = opts.Options or {}
	local selected = opts.Default or options[1]
	local container = newFrame(parent, UDim2.new(1,0,0,0), T.SURFACE2)
	container.AutomaticSize = Enum.AutomaticSize.Y; corner(container, T.RADIUS_SM)
	padding(container, 8, 8, 6, 6); listLayout(container, Enum.FillDirection.Vertical, 4)
	if opts.Text then
		local h = newLabel(container, string.upper(opts.Text), 10, T.TEXT_MUTED, T.FONT_BOLD)
		h.Size = UDim2.new(1,0,0,12)
	end
	local buttons = {}
	local function refresh()
		for opt, b in pairs(buttons) do
			b.dot.Visible = (opt == selected)
			b.ring.BackgroundColor3 = (opt == selected) and T.ACCENT or T.BORDER
		end
	end
	for _, opt in ipairs(options) do
		local r = newFrame(container, UDim2.new(1,0,0,24), T.SURFACE3); corner(r,4)
		padding(r, 8, 8, 0, 0)
		local ring = newFrame(r, UDim2.new(0,14,0,14), T.BORDER)
		ring.AnchorPoint = Vector2.new(0,0.5); ring.Position = UDim2.new(0,0,0.5,0); corner(ring,7)
		local dot = newFrame(ring, UDim2.new(0,6,0,6), Color3.new(1,1,1))
		dot.AnchorPoint = Vector2.new(0.5,0.5); dot.Position = UDim2.new(0.5,0,0.5,0); corner(dot,3)
		dot.Visible = (opt==selected)
		local l = newLabel(r, opt, 12, T.TEXT); l.Position=UDim2.new(0,22,0,0); l.Size=UDim2.new(1,-22,1,0)
		local btn = Instance.new("TextButton"); btn.BackgroundTransparency=1; btn.Text=""
		btn.Size=UDim2.new(1,0,1,0); btn.Parent=r; btn.ZIndex=2
		btn.MouseButton1Click:Connect(function()
			selected = opt; refresh()
			if ctx.config then ctx.config:set(opts.Flag, selected) end
			if opts.Callback then task.spawn(opts.Callback, opt) end
		end)
		buttons[opt] = { dot=dot, ring=ring }
	end
	if ctx.config and opts.Flag then
		ctx.config:register(opts.Flag, function() return selected end,
			function(v) selected = v; refresh() end)
	end
	self.Get = function() return selected end
	self.Set = function(_, v) selected = v; refresh() end
	self._row = container; self._label = opts.Text or "Radio"
	return self
end

local function mkScrollList(parent, opts, ctx)
	local self = {}
	local items = opts.Items or {}
	if opts.Text then
		local h = newLabel(parent, string.upper(opts.Text), 10, T.TEXT_MUTED, T.FONT_BOLD)
		h.Size = UDim2.new(1,0,0,12)
	end
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 0, opts.Height or 100)
	scroll.BackgroundColor3 = T.BG; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = T.ACCENT_DIM
	scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent; corner(scroll, T.RADIUS_SM); padding(scroll, 4, 4, 4, 4)
	listLayout(scroll, Enum.FillDirection.Vertical, 2)
	local function rebuild()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end end
		for _, it in ipairs(items) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,24); b.BackgroundColor3 = T.SURFACE2
			b.BackgroundTransparency = 1; b.Text = "  "..tostring(it)
			b.TextXAlignment = Enum.TextXAlignment.Left; b.TextColor3 = T.TEXT
			b.Font = T.FONT; b.TextSize = 12; b.AutoButtonColor = false; b.Parent = scroll
			corner(b, 4)
			b.MouseEnter:Connect(function() tween(b,{BackgroundTransparency=0.4}) end)
			b.MouseLeave:Connect(function() tween(b,{BackgroundTransparency=1}) end)
			b.MouseButton1Click:Connect(function()
				if opts.Callback then task.spawn(opts.Callback, it) end end)
		end
	end
	rebuild()
	self.SetItems = function(_, t) items = t or {}; rebuild() end
	self._row = scroll; self._label = opts.Text or "List"
	return self
end

local function mkSeparator(parent, opts)
	local label = type(opts) == "table" and opts.Text or opts
	if label and label ~= "" then
		local l = newLabel(parent, string.upper(label), 10, T.TEXT_MUTED, T.FONT_BOLD)
		l.Size = UDim2.new(1,0,0,12)
	end
	local line = newFrame(parent, UDim2.new(1,0,0,1), T.BORDER2)
	return { _row = line, _label = label or "" }
end

local Section = class({})
function Section.new(parent, title, ctx)
	local self = setmetatable({}, Section)
	self._ctx = ctx
	self._elements = {}

	local wrap = newFrame(parent, UDim2.new(1, 0, 0, 0), T.SURFACE)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.ClipsDescendants = true
	corner(wrap, T.RADIUS); stroke(wrap, T.BORDER2, 1)
	gradient(wrap, T.CARD_TOP, T.CARD_BOT, 90)

	if title and title ~= "" then
		local acBar = newFrame(wrap, UDim2.new(0, 3, 1, -8), T.ACCENT)
		acBar.AnchorPoint = Vector2.new(0, 0.5)
		acBar.Position = UDim2.new(0, 0, 0.5, 0); acBar.ZIndex = 3
	end

	local inner = newFrame(wrap, UDim2.new(1, 0, 0, 0), T.SURFACE)
	inner.BackgroundTransparency = 1; inner.AutomaticSize = Enum.AutomaticSize.Y
	padding(inner, 14, 10, 8, 10)
	local ll = listLayout(inner, Enum.FillDirection.Vertical, 6)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	if title and title ~= "" then
		local header = newLabel(inner, string.upper(title), 10, T.ACCENT_H, T.FONT_BOLD)
		header.LayoutOrder = -1; header.Size = UDim2.new(1,0,0,14)
	end
	self._inner = inner; self._wrap = wrap
	return self
end

local function track(self, el)
	if el and el._row then self._elements[#self._elements+1] = el end
	return el
end

function Section:Toggle(a,b,c)       return track(self, mkToggle(self._inner, normalize(a,b,c), self._ctx)) end
function Section:Slider(a,b,c,d,e)
	if type(a)=="table" then return track(self, mkSlider(self._inner, a, self._ctx)) end
	return track(self, mkSlider(self._inner, {Text=a,Min=b,Max=c,Default=d,Callback=e}, self._ctx))
end
function Section:Dropdown(a,b,c,d)
	if type(a)=="table" then return track(self, mkDropdown(self._inner, a, self._ctx)) end
	return track(self, mkDropdown(self._inner, {Text=a,Options=b,Default=c,Callback=d}, self._ctx))
end
function Section:MultiDropdown(o)     return track(self, mkMultiDropdown(self._inner, o, self._ctx)) end
function Section:Button(a,b,c)
	if type(a)=="table" then return track(self, mkButton(self._inner, a, self._ctx)) end
	return track(self, mkButton(self._inner, {Text=a,Callback=b,Variant=c}, self._ctx))
end
function Section:Label(a,b,c)         return track(self, mkLabel(self._inner, type(a)=="table" and a or {Text=a})) end
function Section:Paragraph(o)         return track(self, mkParagraph(self._inner, o, self._ctx)) end
function Section:Checkbox(a,b,c)      return track(self, mkCheckbox(self._inner, normalize(a,b,c), self._ctx)) end
function Section:TextInput(a,b,c,d)
	if type(a)=="table" then return track(self, mkInput(self._inner, a, self._ctx)) end
	return track(self, mkInput(self._inner, {Text=a,Placeholder=b,Callback=d}, self._ctx))
end
function Section:Keybind(o)           return track(self, mkKeybind(self._inner, type(o)=="table" and o or {Text=o}, self._ctx)) end
function Section:ColorPicker(o)       return track(self, mkColorPicker(self._inner, type(o)=="table" and o or {Text=o}, self._ctx)) end
function Section:RadioGroup(a,b,c,d)
	if type(a)=="table" then return track(self, mkRadio(self._inner, a, self._ctx)) end
	return track(self, mkRadio(self._inner, {Text=a,Options=b,Default=c,Callback=d}, self._ctx))
end
function Section:ScrollList(a,b,c,d)
	if type(a)=="table" then return track(self, mkScrollList(self._inner, a, self._ctx)) end
	return track(self, mkScrollList(self._inner, {Text=a,Items=b,Height=c,Callback=d}, self._ctx))
end
function Section:Separator(a)         return track(self, mkSeparator(self._inner, a)) end

function Section:_filter(term)
	local anyVisible = false
	for _, el in ipairs(self._elements) do
		local match = term == ""
			or string.find(string.lower(el._label or ""), term, 1, true) ~= nil
		if el._row then el._row.Visible = match end
		if match then anyVisible = true end
	end
	self._wrap.Visible = anyVisible
end

local Window = class({})
local SIDEBAR_W = 156
local TITLE_H = 42

function Window.new(opts)
	local self = setmetatable({}, Window)
	opts = opts or {}
	local title    = opts.Title or "ZephyrUI"
	local subtitle = opts.Subtitle or ""
	local W = opts.Width or 580
	local H = opts.Height or 440
	self._minW, self._minH = 420, 280
	self._W, self._H = W, H
	self._tabs = {}
	self._open = true
	self._collapsed = false

	if opts.Accent and ACCENT_PRESETS[opts.Accent] then
		local p = ACCENT_PRESETS[opts.Accent]
		T.ACCENT, T.ACCENT_H, T.ACCENT_DIM = p[1], p[2], p[3]
	end

	local sg = getContainer()
	self._sg = sg
	Tooltip.init(sg)
	self._config = Config.new(opts.ConfigName)

	local win = newFrame(sg, UDim2.new(0, W, 0, H), T.BG)
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Position = UDim2.new(0.5, 0, 0.5, 0)
	win.ClipsDescendants = true   
	win.ZIndex = 2
	corner(win, T.RADIUS_LG)
	stroke(win, T.BORDER, 1)
	gradient(win, T.GRAD_TOP, T.GRAD_BOT, 90)
	self._win = win

	win.BackgroundTransparency = 1
	tween(win, { BackgroundTransparency = 0 }, T.TWEEN_MED)

	local titleBar = newFrame(win, UDim2.new(1, 0, 0, TITLE_H), T.SURFACE)
	titleBar.ZIndex = 5
	corner(titleBar, T.RADIUS_LG)
	local tbFiller = newFrame(titleBar, UDim2.new(1, 0, 0, T.RADIUS_LG), T.SURFACE)
	tbFiller.Position = UDim2.new(0, 0, 1, -T.RADIUS_LG); tbFiller.ZIndex = 5

	local iconCircle = newFrame(titleBar, UDim2.new(0, 28, 0, 28), T.ACCENT_DIM)
	iconCircle.Position = UDim2.new(0, 12, 0.5, -13); iconCircle.ZIndex = 6
	corner(iconCircle, 14)
	local iconLbl = newLabel(iconCircle, "👁", 14, T.TEXT)
	iconLbl.Size = UDim2.new(1,0,1,0); iconLbl.TextXAlignment = Enum.TextXAlignment.Center; iconLbl.ZIndex = 7

	local tbLabel = newLabel(titleBar, title, 14, T.TEXT, T.FONT_BOLD)
	tbLabel.Position = UDim2.new(0, 48, 0, subtitle ~= "" and 8 or 1)
	tbLabel.Size = UDim2.new(1, -150, 0, subtitle ~= "" and 16 or TITLE_H)
	tbLabel.TextYAlignment = subtitle ~= "" and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	tbLabel.ZIndex = 6
	if subtitle ~= "" then
		local sub = newLabel(titleBar, subtitle, 10, T.TEXT_MUTED)
		sub.Position = UDim2.new(0, 48, 0, 25); sub.Size = UDim2.new(1, -150, 0, 12); sub.ZIndex = 6
	end

	local function makeTitleBtn(glyph, xOff, hoverColor)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 28, 0, 28)
		b.Position = UDim2.new(1, xOff, 0.5, -14)
		b.BackgroundColor3 = T.SURFACE3
		b.Text = glyph; b.Font = T.FONT_BOLD; b.TextSize = 15
		b.TextColor3 = T.TEXT_SUB; b.AutoButtonColor = false
		b.ZIndex = 7; b.Parent = titleBar
		corner(b, 14)
		stroke(b, T.BORDER, 1)
		b.MouseEnter:Connect(function()
			tween(b, { BackgroundColor3 = hoverColor, TextColor3 = Color3.new(1,1,1) })
		end)
		b.MouseLeave:Connect(function()
			tween(b, { BackgroundColor3 = T.SURFACE3, TextColor3 = T.TEXT_SUB })
		end)
		return b
	end
	
	local closeBtn = makeTitleBtn("X", -40, T.DANGER)   
	local hideBtn  = makeTitleBtn("–", -76, T.WARN)     
	closeBtn.MouseButton1Click:Connect(function()
		if self._onClose then pcall(self._onClose) end
		self:Destroy()
	end)
	hideBtn.MouseButton1Click:Connect(function() self:Hide() end)

	makeDraggable(titleBar, win)

	local sidebarBG = newFrame(win, UDim2.new(0, SIDEBAR_W, 1, -TITLE_H), T.SIDEBAR)
	sidebarBG.Position = UDim2.new(0, 0, 0, TITLE_H); sidebarBG.ZIndex = 4
	corner(sidebarBG, T.RADIUS_LG)
	
	local sbFillTop = newFrame(sidebarBG, UDim2.new(1, 0, 0, T.RADIUS_LG), T.SIDEBAR)
	sbFillTop.Position = UDim2.new(0, 0, 0, 0); sbFillTop.ZIndex = 4
	local sbFillRight = newFrame(sidebarBG, UDim2.new(0, T.RADIUS_LG, 1, 0), T.SIDEBAR)
	sbFillRight.Position = UDim2.new(1, -T.RADIUS_LG, 0, 0); sbFillRight.ZIndex = 4

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Size = UDim2.new(1, 0, 1, 0)
	sidebar.Position = UDim2.new(0, 0, 0, 0)
	sidebar.BackgroundTransparency = 1; sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 2; sidebar.ScrollBarImageColor3 = T.ACCENT_DIM
	sidebar.CanvasSize = UDim2.new(0,0,0,0); sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.ZIndex = 5; sidebar.Parent = sidebarBG
	padding(sidebar, 8, 8, 8, 8)
	listLayout(sidebar, Enum.FillDirection.Vertical, 4)
	self._sidebar = sidebar

	local divider = newFrame(win, UDim2.new(0, 1, 1, -TITLE_H - T.RADIUS_LG), T.BORDER2)
	divider.Position = UDim2.new(0, SIDEBAR_W, 0, TITLE_H); divider.ZIndex = 4
	self._divider = divider

	local content = newFrame(win, UDim2.new(1, -SIDEBAR_W-1, 1, -TITLE_H), T.BG)
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, SIDEBAR_W+1, 0, TITLE_H); content.ZIndex = 3
	content.Parent = win
	self._content = content

	if opts.Search ~= false then
		local searchWrap = newFrame(content, UDim2.new(1, -20, 0, 28), T.SURFACE2)
		searchWrap.Position = UDim2.new(0, 10, 0, 8); searchWrap.ZIndex = 4
		corner(searchWrap, T.RADIUS_SM); padding(searchWrap, 10, 10, 0, 0)
		local icon = newLabel(searchWrap, "🔍", 12, T.TEXT_MUTED)
		icon.Size = UDim2.new(0, 18, 1, 0)
		local sbox = Instance.new("TextBox")
		sbox.BackgroundTransparency = 1; sbox.Size = UDim2.new(1, -22, 1, 0)
		sbox.Position = UDim2.new(0, 22, 0, 0); sbox.PlaceholderText = "Search..."
		sbox.PlaceholderColor3 = T.TEXT_MUTED; sbox.Text = ""; sbox.TextColor3 = T.TEXT
		sbox.Font = T.FONT; sbox.TextSize = 12; sbox.TextXAlignment = Enum.TextXAlignment.Left
		sbox.ClearTextOnFocus = false; sbox.ZIndex = 5; sbox.Parent = searchWrap
		sbox:GetPropertyChangedSignal("Text"):Connect(function()
			local term = string.lower(sbox.Text)
			if self._activeTab then
				for _, sec in ipairs(self._activeTab._sections) do sec:_filter(term) end
			end
		end)
		self._searchOffset = 44
	else
		self._searchOffset = 8
	end

	if opts.Resizable ~= false then
		local grip = Instance.new("TextButton")
		grip.Size = UDim2.new(0, 16, 0, 16); grip.AnchorPoint = Vector2.new(1,1)
		grip.Position = UDim2.new(1, -2, 1, -2); grip.BackgroundTransparency = 1
		grip.Text = "◢"; grip.TextColor3 = T.TEXT_MUTED; grip.TextSize = 12
		grip.Font = T.FONT_BOLD; grip.ZIndex = 10; grip.Parent = win
		local rz, startM, startS = false
		grip.MouseButton1Down:Connect(function()
			rz = true; startM = UserInputService:GetMouseLocation(); startS = win.AbsoluteSize end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then rz = false end end)
		UserInputService.InputChanged:Connect(function(i)
			if rz and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - Vector2.new(startM.X, startM.Y)
				local nw = math.max(self._minW, startS.X + d.X)
				local nh = math.max(self._minH, startS.Y + d.Y)
				self._W, self._H = nw, nh
				win.Size = UDim2.new(0, nw, 0, nh)
			end
		end)
	end

	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(i, gpe)
		if not gpe and i.KeyCode == toggleKey then self:Toggle() end
	end)

	return self
end

function Window:Tab(name, icon)
	local idx = #self._tabs + 1
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34); btn.BackgroundColor3 = T.ACCENT_DIM
	btn.BackgroundTransparency = 1; btn.Text = ""; btn.AutoButtonColor = false
	btn.ZIndex = 5; btn.Parent = self._sidebar; corner(btn, T.RADIUS_SM)

	local indicator = newFrame(btn, UDim2.new(0, 3, 0.55, 0), T.ACCENT)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.Position = UDim2.new(0, 0, 0.5, 0)
	indicator.Visible = false; indicator.ZIndex = 7
	corner(indicator, 2)

	local iconLbl
	if icon then
		iconLbl = newLabel(btn, icon, 13, T.TEXT_SUB)
		iconLbl.Position = UDim2.new(0, 16, 0, 0)
		iconLbl.Size = UDim2.new(0, 20, 1, 0)
		iconLbl.TextXAlignment = Enum.TextXAlignment.Center
		iconLbl.ZIndex = 6
	end

	local lbl = newLabel(btn, tostring(name), 12, T.TEXT_SUB, T.FONT_BOLD)
	lbl.Position = UDim2.new(0, icon and 42 or 16, 0, 0)
	lbl.Size = UDim2.new(1, icon and -48 or -20, 1, 0)
	lbl.ZIndex = 6

	local body = Instance.new("ScrollingFrame")
	body.Size = UDim2.new(1, 0, 1, -self._searchOffset)
	body.Position = UDim2.new(0, 0, 0, self._searchOffset)
	body.BackgroundTransparency = 1; body.BorderSizePixel = 0
	body.ScrollBarThickness = 4; body.ScrollBarImageColor3 = T.ACCENT_DIM
	body.CanvasSize = UDim2.new(0,0,0,0); body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.Visible = false; body.ZIndex = 3; body.Parent = self._content
	padding(body, 10, 10, 10, 16)
	listLayout(body, Enum.FillDirection.Vertical, 8)

	local tabObj = { _window = self, _body = body, _btn = btn, _lbl = lbl,
		_index = idx, _sections = {} }
	function tabObj:Section(stitle)
		local s = Section.new(self._body, stitle, self._window._config)
		self._sections[#self._sections+1] = s
		return s
	end

	local function select()
		for _, t in ipairs(self._tabs) do
			t._body.Visible = false
			tween(t._btn, { BackgroundTransparency = 1 })
			tween(t._lbl, { TextColor3 = T.TEXT_SUB })
			if t._indicator then t._indicator.Visible = false end
			if t._iconLbl   then tween(t._iconLbl, { TextColor3 = T.TEXT_SUB }) end
		end
		body.Visible = true
		tween(btn, { BackgroundTransparency = 0.75 })
		tween(lbl, { TextColor3 = Color3.new(1,1,1) })
		indicator.Visible = true
		if iconLbl then tween(iconLbl, { TextColor3 = T.ACCENT_H }) end
		self._activeTab = tabObj
	end
	tabObj.Select   = select
	tabObj._indicator = indicator
	tabObj._iconLbl   = iconLbl
	btn.MouseButton1Click:Connect(select)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= tabObj then
			tween(btn, { BackgroundTransparency = 0.88 })
			tween(lbl, { TextColor3 = T.TEXT })
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= tabObj then
			tween(btn, { BackgroundTransparency = 1 })
			tween(lbl, { TextColor3 = T.TEXT_SUB })
		end
	end)

	self._tabs[idx] = tabObj
	if idx == 1 then select() end
	return tabObj
end

function Window:TabGroup(name)
	local h = newLabel(self._sidebar, string.upper(name), 9, T.TEXT_MUTED, T.FONT_BOLD)
	h.Size = UDim2.new(1, 0, 0, 18); h.TextXAlignment = Enum.TextXAlignment.Left
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 10)
	p.PaddingTop = UDim.new(0, 6); p.Parent = h
end

function Window:Section(title)   
	if not self._implicitTab then self._implicitTab = self:Tab("Main") end
	return self._implicitTab:Section(title)
end

function Window:Notify(opts) Notif.show(self._sg, opts) end
function Window:Toggle()
	self._open = not self._open
	self._win.Visible = self._open
end
function Window:Show()
	self._open = true
	self._win.Visible = true
end
function Window:Hide()
	self._open = false
	self._win.Visible = false
end
function Window:OnClose(fn) self._onClose = fn end
function Window:Destroy()
	pcall(function() if self._win then self._win:Destroy() end end)
	
	if self._dropdownSGs then
		for _, sg in ipairs(self._dropdownSGs) do
			pcall(function() sg:Destroy() end)
		end
	end
	
	pcall(function()
		if self._sg and self._sg:IsA("ScreenGui") and self._sg.Name == "ZephyrUI_host" then
			self._sg:Destroy()
		end
	end)
	
	pcall(function()
		local hosts = {}
		if gethui then table.insert(hosts, gethui()) end
		local okCG, cg = pcall(function() return game:GetService("CoreGui") end)
		if okCG then table.insert(hosts, cg) end
		pcall(function() table.insert(hosts, LocalPlayer:FindFirstChild("PlayerGui")) end)
		for _, h in ipairs(hosts) do
			if h then
				for _, c in ipairs(h:GetChildren()) do
					if c.Name == "ZephyrDD_dropdown" then c:Destroy() end
				end
			end
		end
	end)
end
function Window:BindKey(key)
	UserInputService.InputBegan:Connect(function(i, gpe)
		if not gpe and i.KeyCode == key then self:Toggle() end end)
end

function Window:LoadConfig() if self._config then return self._config:load() end end
function Window:SaveConfig() if self._config then return self._config:save() end end
function Window:AutoSave(interval)
	if not self._config or not self._config.enabled then return end
	task.spawn(function()
		while self._win and self._win.Parent do
			task.wait(interval or 20); pcall(function() self._config:save() end)
		end
	end)
end

function Window:SetAccent(name)
	if ACCENT_PRESETS[name] then
		local p = ACCENT_PRESETS[name]
		T.ACCENT, T.ACCENT_H, T.ACCENT_DIM = p[1], p[2], p[3]
	end
end

local ZephyrUI = {}
ZephyrUI.Window = Window.new
ZephyrUI.Theme  = T
ZephyrUI.Accents = ACCENT_PRESETS
ZephyrUI.Notify = function(opts)
	
	local sg = getContainer()
	Notif.show(sg, opts)
end
function ZephyrUI.SetTheme(overrides)
	for k, v in pairs(overrides) do T[k] = v end
end

return ZephyrUI
