local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local SirismUI = {
    Connections = {},
    Flags = {},
    Theme = {
        Background = Color3.fromRGB(18, 17, 25),
        Panel = Color3.fromRGB(25, 24, 34),
        PanelSoft = Color3.fromRGB(32, 30, 43),
        Stroke = Color3.fromRGB(87, 82, 112),
        Text = Color3.fromRGB(238, 236, 246),
        Muted = Color3.fromRGB(160, 156, 176),
        Accent = Color3.fromRGB(255, 107, 214),
        Success = Color3.fromRGB(73, 212, 145),
    }
}

local function protect(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)

    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then
            gui.Parent = hui
            return
        end
    end

    gui.Parent = CoreGui
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(SirismUI.Connections, connection)
    return connection
end

local function tween(object, props, time)
    local info = TweenInfo.new(time or 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local t = TweenService:Create(object, info, props)
    t:Play()
    return t
end

local function new(className, props, children)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function corner(radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
end

local function stroke(color, transparency, thickness)
    return new("UIStroke", {
        Color = color or SirismUI.Theme.Stroke,
        Transparency = transparency or 0.15,
        Thickness = thickness or 1,
    })
end

local function label(text, size, bold)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        Text = text or "",
        TextColor3 = SirismUI.Theme.Text,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = true,
    })
end

local function buttonBase()
    return new("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
    })
end

local function makeDraggable(handle, frame)
    local dragging = false
    local dragStart
    local startPos

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        connect(input.Changed, function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

local function createRow(parent, height)
    local row = new("Frame", {
        Parent = parent,
        BackgroundColor3 = SirismUI.Theme.PanelSoft,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 38),
    }, {
        corner(6),
        stroke(SirismUI.Theme.Stroke, 0.45, 1),
    })
    return row
end

function SirismUI:Notify(title, text, duration)
    if not self.NotificationHolder then return end
    duration = duration or 4

    local item = new("Frame", {
        Parent = self.NotificationHolder,
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 64),
        Position = UDim2.new(0, 35, 0, 0),
    }, {
        corner(8),
        stroke(self.Theme.Stroke, 0.2, 1),
    })

    local accent = new("Frame", {
        Parent = item,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 10),
        Size = UDim2.new(0, 3, 1, -20),
    }, {corner(99)})

    local titleLabel = label(title or "Sirism", 13, true)
    titleLabel.Parent = item
    titleLabel.Position = UDim2.fromOffset(20, 7)
    titleLabel.Size = UDim2.new(1, -32, 0, 20)

    local textLabel = label(text or "", 12, false)
    textLabel.Parent = item
    textLabel.TextColor3 = self.Theme.Muted
    textLabel.TextWrapped = true
    textLabel.Position = UDim2.fromOffset(20, 28)
    textLabel.Size = UDim2.new(1, -32, 0, 28)

    tween(item, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)
    task.delay(duration, function()
        if item.Parent then
            tween(item, {Position = UDim2.new(0, 35, 0, 0), BackgroundTransparency = 1}, 0.25)
            task.wait(0.28)
            if item.Parent then item:Destroy() end
        end
    end)
end

function SirismUI:MakeWindow(config)
    config = config or {}
    config.Name = config.Name or "Sirism"
    config.Subtitle = config.Subtitle or "visualizer suite"
    config.Bind = config.Bind or Enum.KeyCode.RightShift

    local existingName = "SirismCustomUI"
    local roots = {}
    pcall(function() table.insert(roots, CoreGui) end)
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(roots, hui) end
    end
    for _, root in ipairs(roots) do
        local old = root:FindFirstChild(existingName)
        if old then old:Destroy() end
    end

    local gui = new("ScreenGui", {
        Name = existingName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    protect(gui)
    self.Gui = gui

    local notifications = new("Frame", {
        Parent = gui,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(280, 360),
    }, {
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })
    self.NotificationHolder = notifications

    local main = new("Frame", {
        Parent = gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(680, 420),
        ClipsDescendants = true,
    }, {
        corner(8),
        stroke(self.Theme.Stroke, 0.05, 1),
        new("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 29, 42)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
            })
        })
    })

    local topbar = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
    })
    makeDraggable(topbar, main)

    local menuIcon = label("S", 19, true)
    menuIcon.Parent = topbar
    menuIcon.TextColor3 = self.Theme.Accent
    menuIcon.Position = UDim2.fromOffset(18, 0)
    menuIcon.Size = UDim2.fromOffset(28, 46)

    local title = label(config.Name, 15, true)
    title.Parent = topbar
    title.Position = UDim2.fromOffset(54, 6)
    title.Size = UDim2.new(1, -150, 0, 20)

    local subtitle = label(config.Subtitle, 12, false)
    subtitle.Parent = topbar
    subtitle.TextColor3 = self.Theme.Muted
    subtitle.Position = UDim2.fromOffset(54, 25)
    subtitle.Size = UDim2.new(1, -150, 0, 16)

    local close = buttonBase()
    close.Parent = topbar
    close.Position = UDim2.new(1, -42, 0, 10)
    close.Size = UDim2.fromOffset(28, 28)
    close.BackgroundTransparency = 0
    close.BackgroundColor3 = self.Theme.PanelSoft
    new("UICorner", {CornerRadius = UDim.new(0, 7), Parent = close})
    new("UIStroke", {Color = self.Theme.Stroke, Transparency = 0.45, Parent = close})
    local closeText = label("X", 13, true)
    closeText.Parent = close
    closeText.TextXAlignment = Enum.TextXAlignment.Center
    closeText.Size = UDim2.fromScale(1, 1)

    local nav = new("Frame", {
        Parent = main,
        BackgroundColor3 = Color3.fromRGB(17, 16, 24),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 46),
        Size = UDim2.new(0, 158, 1, -46),
    }, {
        stroke(self.Theme.Stroke, 0.7, 1),
    })

    local navList = new("UIListLayout", {
        Parent = nav,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    new("UIPadding", {
        Parent = nav,
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })

    local content = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(158, 46),
        Size = UDim2.new(1, -158, 1, -46),
    })

    local window = {
        Gui = gui,
        Main = main,
        Tabs = {},
        CurrentTab = nil,
        Hidden = false,
    }

    connect(close.MouseButton1Click, function()
        window.Hidden = true
        main.Visible = false
        SirismUI:Notify("Sirism UI", "Press " .. config.Bind.Name .. " to reopen.", 4)
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if processed or input.KeyCode ~= config.Bind then return end
        window.Hidden = not window.Hidden
        main.Visible = not window.Hidden
    end)

    function window:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"

        local tabButton = buttonBase()
        tabButton.Parent = nav
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = SirismUI.Theme.PanelSoft
        tabButton.BackgroundTransparency = 1
        new("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})

        local tabText = label(tabConfig.Name, 13, true)
        tabText.Parent = tabButton
        tabText.Position = UDim2.fromOffset(12, 0)
        tabText.Size = UDim2.new(1, -18, 1, 0)
        tabText.TextColor3 = SirismUI.Theme.Muted

        local page = new("ScrollingFrame", {
            Parent = content,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = SirismUI.Theme.Accent,
            Visible = false,
            CanvasSize = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(1, 1),
        }, {
            new("UIPadding", {
                PaddingTop = UDim.new(0, 14),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                PaddingBottom = UDim.new(0, 14),
            }),
            new("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
        })

        connect(page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            page.CanvasSize = UDim2.fromOffset(0, page.UIListLayout.AbsoluteContentSize.Y + 28)
        end)

        local tab = {}

        local function selectTab()
            for _, other in ipairs(window.Tabs) do
                other.Page.Visible = false
                tween(other.Button, {BackgroundTransparency = 1}, 0.14)
                tween(other.Text, {TextColor3 = SirismUI.Theme.Muted}, 0.14)
            end
            page.Visible = true
            tween(tabButton, {BackgroundTransparency = 0}, 0.14)
            tween(tabText, {TextColor3 = SirismUI.Theme.Text}, 0.14)
            window.CurrentTab = tab
        end

        connect(tabButton.MouseButton1Click, selectTab)

        local function addSection(titleText)
            local section = new("Frame", {
                Parent = page,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, {
                new("UIListLayout", {
                    Padding = UDim.new(0, 7),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })
            })

            local header = label(titleText or "Section", 12, true)
            header.Parent = section
            header.TextColor3 = SirismUI.Theme.Muted
            header.Size = UDim2.new(1, 0, 0, 20)

            local api = {}

            function api:AddLabel(textValue)
                local row = createRow(section, 34)
                local l = label(textValue or "Label", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -24, 1, 0)
                return {Set = function(_, value) l.Text = tostring(value) end}
            end

            function api:AddButton(cfg)
                cfg = cfg or {}
                local row = createRow(section, 36)
                local l = label(cfg.Name or cfg.name or "Button", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -24, 1, 0)
                local click = buttonBase()
                click.Parent = row
                click.Size = UDim2.fromScale(1, 1)
                connect(click.MouseEnter, function() tween(row, {BackgroundColor3 = Color3.fromRGB(38, 35, 50)}, 0.12) end)
                connect(click.MouseLeave, function() tween(row, {BackgroundColor3 = SirismUI.Theme.PanelSoft}, 0.12) end)
                connect(click.MouseButton1Click, function()
                    if cfg.Callback then cfg.Callback() elseif cfg.callback then cfg.callback() end
                end)
                return {Set = function(_, value) l.Text = tostring(value) end}
            end

            function api:AddToggle(cfg)
                cfg = cfg or {}
                local value = cfg.Default or cfg.default or false
                local row = createRow(section, 38)
                local l = label(cfg.Name or cfg.name or "Toggle", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(1, -70, 1, 0)

                local box = new("Frame", {
                    Parent = row,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = value and SirismUI.Theme.Accent or Color3.fromRGB(48, 46, 62),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(34, 20),
                }, {corner(99)})
                local dot = new("Frame", {
                    Parent = box,
                    BackgroundColor3 = SirismUI.Theme.Text,
                    BorderSizePixel = 0,
                    Position = value and UDim2.new(1, -18, 0, 3) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(14, 14),
                }, {corner(99)})

                local toggle = {}
                function toggle:Set(v)
                    value = not not v
                    tween(box, {BackgroundColor3 = value and SirismUI.Theme.Accent or Color3.fromRGB(48, 46, 62)}, 0.14)
                    tween(dot, {Position = value and UDim2.new(1, -18, 0, 3) or UDim2.fromOffset(3, 3)}, 0.14)
                    if cfg.Callback then cfg.Callback(value) elseif cfg.callback then cfg.callback(value) end
                end
                function toggle:Get() return value end

                local click = buttonBase()
                click.Parent = row
                click.Size = UDim2.fromScale(1, 1)
                connect(click.MouseButton1Click, function() toggle:Set(not value) end)
                if cfg.Flag then SirismUI.Flags[cfg.Flag] = toggle end
                return toggle
            end

            function api:AddSlider(cfg)
                cfg = cfg or {}
                local min = cfg.Min or cfg.min or 0
                local max = cfg.Max or cfg.max or 100
                local value = cfg.Default or cfg.default or min
                local dragging = false
                local row = createRow(section, 58)
                local l = label(cfg.Name or cfg.name or "Slider", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 5)
                l.Size = UDim2.new(1, -86, 0, 20)
                local valueLabel = label("", 12, true)
                valueLabel.Parent = row
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.TextColor3 = SirismUI.Theme.Muted
                valueLabel.Position = UDim2.new(1, -76, 5, 0)
                valueLabel.Size = UDim2.fromOffset(64, 20)

                local bar = new("Frame", {
                    Parent = row,
                    BackgroundColor3 = Color3.fromRGB(46, 43, 58),
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(12, 34),
                    Size = UDim2.new(1, -24, 0, 8),
                }, {corner(99)})
                local fill = new("Frame", {
                    Parent = bar,
                    BackgroundColor3 = SirismUI.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(0, 1),
                }, {corner(99)})

                local slider = {}
                local function setFromAlpha(alpha)
                    slider:Set(min + ((max - min) * math.clamp(alpha, 0, 1)))
                end
                function slider:Set(v)
                    value = math.clamp(v, min, max)
                    local alpha = (value - min) / math.max(1, max - min)
                    fill.Size = UDim2.fromScale(alpha, 1)
                    valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
                    if cfg.Callback then cfg.Callback(value) elseif cfg.callback then cfg.callback(value) end
                end
                function slider:Get() return value end

                connect(bar.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
                    end
                end)
                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                connect(UserInputService.InputChanged, function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
                    end
                end)
                slider:Set(value)
                if cfg.Flag then SirismUI.Flags[cfg.Flag] = slider end
                return slider
            end

            function api:AddTextbox(cfg)
                cfg = cfg or {}
                local row = createRow(section, 38)
                local l = label(cfg.Name or cfg.name or "Textbox", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(0.45, -12, 1, 0)
                local box = new("TextBox", {
                    Parent = row,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.fromRGB(18, 17, 25),
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Font = Enum.Font.GothamMedium,
                    PlaceholderText = cfg.Placeholder or cfg.placeholder or "Input",
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0.5, -8, 0, 26),
                    Text = cfg.Default or cfg.default or "",
                    TextColor3 = SirismUI.Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, {corner(5), stroke(SirismUI.Theme.Stroke, 0.55, 1)})
                new("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
                connect(box.FocusLost, function()
                    if cfg.Callback then cfg.Callback(box.Text) elseif cfg.callback then cfg.callback(box.Text) end
                end)
                return {Set = function(_, value) box.Text = tostring(value) end, Get = function() return box.Text end}
            end

            function api:AddDropdown(cfg)
                cfg = cfg or {}
                local options = cfg.Options or cfg.options or {}
                local selected = cfg.Default or cfg.default or options[1] or "None"
                local open = false
                local row = createRow(section, 38)
                row.ClipsDescendants = true
                local l = label(cfg.Name or cfg.name or "Dropdown", 13, true)
                l.Parent = row
                l.Position = UDim2.fromOffset(12, 0)
                l.Size = UDim2.new(0.45, -12, 0, 38)
                local selectedLabel = label(tostring(selected), 12, false)
                selectedLabel.Parent = row
                selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
                selectedLabel.TextColor3 = SirismUI.Theme.Muted
                selectedLabel.Position = UDim2.new(0.45, 0, 0, 0)
                selectedLabel.Size = UDim2.new(0.55, -36, 0, 38)
                local list = new("Frame", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 40),
                    Size = UDim2.new(1, 0, 0, 0),
                }, {
                    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
                    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
                })

                local dropdown = {}
                local function rebuild()
                    for _, child in ipairs(list:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, option in ipairs(options) do
                        local opt = buttonBase()
                        opt.Parent = list
                        opt.BackgroundTransparency = 0
                        opt.BackgroundColor3 = Color3.fromRGB(38, 35, 50)
                        opt.Size = UDim2.new(1, 0, 0, 26)
                        corner(5).Parent = opt
                        local t = label(tostring(option), 12, option == selected)
                        t.Parent = opt
                        t.Position = UDim2.fromOffset(8, 0)
                        t.Size = UDim2.new(1, -16, 1, 0)
                        connect(opt.MouseButton1Click, function()
                            dropdown:Set(option)
                            open = false
                            tween(row, {Size = UDim2.new(1, 0, 0, 38)}, 0.14)
                        end)
                    end
                end
                function dropdown:Set(value)
                    selected = value
                    selectedLabel.Text = tostring(value)
                    if cfg.Callback then cfg.Callback(value) elseif cfg.callback then cfg.callback(value) end
                    rebuild()
                end
                function dropdown:Refresh(newOptions)
                    options = newOptions or options
                    rebuild()
                end
                function dropdown:Get() return selected end

                local click = buttonBase()
                click.Parent = row
                click.Size = UDim2.new(1, 0, 0, 38)
                connect(click.MouseButton1Click, function()
                    open = not open
                    local rows = math.min(#options, 5)
                    tween(row, {Size = open and UDim2.new(1, 0, 0, 42 + rows * 30) or UDim2.new(1, 0, 0, 38)}, 0.14)
                end)
                rebuild()
                return dropdown
            end

            return api
        end

        function tab:AddSection(sectionConfig)
            if type(sectionConfig) == "table" then
                return addSection(sectionConfig.Name or sectionConfig.name)
            end
            return addSection(sectionConfig)
        end

        table.insert(window.Tabs, {Button = tabButton, Text = tabText, Page = page, Api = tab})
        if not window.CurrentTab then selectTab() end
        return tab
    end

    function window:Destroy()
        gui:Destroy()
    end

    return window
end

function SirismUI:Destroy()
    for _, connection in ipairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.Connections)
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

return SirismUI
