print("hi openviz")
--[[
                                                                                                                            
                                                                                                                            
     OOOOOOOOO                                                           VVVVVVVV           VVVVVVVV iiii                   
   OO:::::::::OO                                                         V::::::V           V::::::Vi::::i                  
 OO:::::::::::::OO                                                       V::::::V           V::::::V iiii                   
O:::::::OOO:::::::O                                                      V::::::V           V::::::V                        
O::::::O   O::::::Oppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn V:::::V           V:::::Viiiiiii zzzzzzzzzzzzzzzzz
O:::::O     O:::::Op::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nnV:::::V         V:::::V i:::::i z:::::::::::::::z
O:::::O     O:::::Op:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nnV:::::V       V:::::V   i::::i z::::::::::::::z 
O:::::O     O:::::Opp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::nV:::::V     V:::::V    i::::i zzzzzzzz::::::z  
O:::::O     O:::::O p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n V:::::V   V:::::V     i::::i       z::::::z   
O:::::O     O:::::O p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n  V:::::V V:::::V      i::::i      z::::::z    
O:::::O     O:::::O p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n   V:::::V:::::V       i::::i     z::::::z     
O::::::O   O::::::O p:::::p    p::::::pe:::::::e             n::::n    n::::n    V:::::::::V        i::::i    z::::::z      
O:::::::OOO:::::::O p:::::ppppp:::::::pe::::::::e            n::::n    n::::n     V:::::::V        i::::::i  z::::::zzzzzzzz
 OO:::::::::::::OO  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n      V:::::V         i::::::i z::::::::::::::z
   OO:::::::::OO    p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n       V:::V          i::::::iz:::::::::::::::z
     OOOOOOOOO      p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn        VVV           iiiiiiiizzzzzzzzzzzzzzzzz
                    p:::::p                                                                                                 
                    p:::::p                                                                                                 
                   p:::::::p                                                                                                
                   p:::::::p                                                                                                
                   p:::::::p                                                                                                
                   ppppppppp                                                                                                
                                                                                                                            
]]
-- preset maker, press "P"
loadstring(game:HttpGet("https://raw.githubusercontent.com/3-7x/Preset-Maker/refs/heads/main/pm"))()
--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local orbiting = false
local orbitStartTime = tick()
local tracked = {}
local idxCounter = 0
local lookLocked = false
local targetPlayer = player

local audioVisualizerEnabled = true
local maxRadiusBoost = 8
local visualizerSensitivity = 1
local smoothingFactor = 0.15
local currentRadiusBoost = 0
local loudnessThreshold = 50

local currentSpeed = 1
local currentSize = 4
local currentHeight = 1
local netlessEnabled = true
local netlessVector = Vector3.new(0,0,-31)
local sessionSeed = math.random(1, 100000)

local audioId = nil
local dupeTargetAmount = 5
local dupeRunning = false
local antiFlingEnabled = false
local stealToolsEnabled = false

-- Clone / Wheel state
local clonePos = Vector3.new()
local cloneVel = Vector3.new()
local cloneLook = Vector3.new(0, 0, -1)
local cloneOnGround = false
local activeEmote = nil
local emoteStartTime = 0
local timeIdle = 0
local wheelRollAngle = 0

-- Camera part for R6Clone / Wheel view
local camPart = Instance.new("Part")
camPart.Name = "OpenVizCamPart"
camPart.Transparency = 1
camPart.CanCollide = false
camPart.Anchored = true
camPart.Size = Vector3.new(1, 1, 1)
camPart.Parent = workspace

local orbitPresets = {
    ["Circle"]        = {radius=5,   speed=0.5, circleH=true},
    ["Rolling Circle"]= {radius=5,   speed=0.5, circleH=true, rolling=true},
    ["Spinning circle thing"] = {radius=5, speed=1.2, pennyRoll=true},
    ["Infinity"]      = {radius=4,   speed=0.5, infinity=true},
    ["Rotating Infinity"] = {radius=4, speed=0.7, rotatingInfinity=true},
    ["Wings"]         = {radius=5,   speed=0.5, wingsV2=true},
    ["R6 Clone"]      = {r6Clone=true},
    ["Trefoil"]       = {radius=4,   speed=0.5, knot=true},
    ["Wavy Circle"]   = {radius=5,   speed=0.5, wavy=true},
    ["Wobbly"]        = {radius=5,   speed=0.7, wobbly=true},
    ["Back Infinity"] = {radius=4,   speed=0.52, backInfinity=true},
    ["Lissaj Curve"]  = {radius=4,   speed=0.5, lissajous=true},
    ["Sine Wave"]     = {radius=5,   speed=1,   sineWave=true},
    ["Heart"]         = {radius=4,   speed=1.5, heart=true},
    ["X"]             = {radius=5,   speed=0,   xSymbol=true},
    ["Helix"]         = {radius=4,   speed=1,   helix=true},
    ["wow circle up"] = {radius=5, speed=0.8, audioLiftCircle=true},
    ["Equalizer"]     = {radius=4,   speed=0,   equalizer=true},
    ["Pulse Ring"]    = {radius=5,   speed=0.5, pulseRing=true},
    ["Core Pulse"]    = {radius=3,   speed=0.8, corePulse=true},
}
local activePresetName = "Circle"
local activePreset = orbitPresets[activePresetName]

local customPresets = {}
local customPresetNames = {"None"}
local CustomPresetsDropdown = nil

local function buildNodeMap(preset)
    local map = {}
    for _, node in ipairs(preset.Nodes or {}) do map[node.ID] = node end
    for _, tool in ipairs(preset.Tools or {}) do map[tool.ID] = tool end
    return map
end

-- Evaluates the world CFrame of a node recursively, applying audio-reactive
-- scaling to Tool nodes and Y-spin to Rotator nodes.
local function getNodeWorldCF(nodeID, t, nodeMap, memo, hrpCF, audioPulse)
    if memo[nodeID] then return memo[nodeID] end

    if nodeID == "HRP" then
        memo["HRP"] = hrpCF
        return hrpCF
    end

    local node = nodeMap[nodeID]
    if not node then
        memo[nodeID] = CFrame.new()
        return CFrame.new()
    end

    local parentCF = getNodeWorldCF(node.ParentID, t, nodeMap, memo, hrpCF, audioPulse)

    local effectiveSens = 0
    -- Tools pulse; Rotators (have .Speed) do not.
    if node.Speed == nil then
        local parentNode = nodeMap[node.ParentID]
        if parentNode and parentNode.Sens ~= nil then
            effectiveSens = tonumber(parentNode.Sens) or 0
        elseif node.Sens ~= nil then
            effectiveSens = tonumber(node.Sens) or 0
        end
    end

    local pulseMult = 1 + ((audioPulse / 5) * (effectiveSens / 100))
    local relPos = Vector3.new(node.pos.x, node.pos.y, node.pos.z) * pulseMult
    local relCF  = CFrame.new(relPos) * CFrame.Angles(node.rot.x, node.rot.y, node.rot.z)

    local worldCF
    if node.Speed ~= nil then
        local spd = (node.Speed or 2) * currentSpeed * 0.15
        worldCF = parentCF * relCF * CFrame.Angles(0, t * spd, 0)
    else
        worldCF = parentCF * relCF
    end

    memo[nodeID] = worldCF
    return worldCF
end

-- Reads all .json files from the OpenViz/ folder.
-- Accepts ONLY the new NodeGraph format. Old spline files get a clear warning.
local function refreshCustomPresets()
    table.clear(customPresets)
    table.clear(customPresetNames)
    table.insert(customPresetNames, "None")

    if isfolder and isfolder("OpenViz") and listfiles then
        for _, filePath in ipairs(listfiles("OpenViz")) do
            if filePath:match("%.json$") then
                local ok, fileData = pcall(function() return readfile(filePath) end)
                if ok then
                    local ok2, decoded = pcall(function() return HttpService:JSONDecode(fileData) end)
                    if ok2 and decoded and decoded.Type == "NodeGraph" and decoded.Nodes and decoded.Tools then
                        local name = decoded.Name or filePath:match("([^/\\]+)%.json$")
                        decoded._nodeMap = buildNodeMap(decoded)
                        customPresets[name] = decoded
                        table.insert(customPresetNames, name)
                        print("OpenViz: Loaded NodeGraph preset -> " .. name)
                    elseif ok2 and decoded then
                        if decoded.Points then
                            warn("OpenViz: '" .. (filePath:match("([^/\\]+)%.json$") or filePath)
                                .. "' uses the OLD spline format. Re-export it from the new Preset Builder.")
                        else
                            warn("OpenViz: Unrecognised preset format in " .. filePath)
                        end
                    end
                end
            end
        end
    end

    if CustomPresetsDropdown then
        pcall(function() CustomPresetsDropdown:Refresh(customPresetNames) end)
        pcall(function() CustomPresetsDropdown:update(customPresetNames)  end)
        pcall(function() CustomPresetsDropdown:Update(customPresetNames)  end)
    end
end
refreshCustomPresets()

local activeCustomPresetName = "None"

task.spawn(function()
    local lastContent = ""
    while task.wait(1) do
        if activePreset and activePreset.Type == "NodeGraph" and activeCustomPresetName ~= "None" then
            local filePath = "OpenViz/" .. activeCustomPresetName .. ".json"
            if isfile and isfile(filePath) then
                local ok, fileData = pcall(readfile, filePath)
                if ok and fileData ~= lastContent then
                    local ok2, decoded = pcall(function() return HttpService:JSONDecode(fileData) end)
                    if ok2 and decoded and decoded.Type == "NodeGraph" and decoded.Nodes and decoded.Tools then
                        decoded._nodeMap = buildNodeMap(decoded)
                        activePreset.Nodes    = decoded.Nodes
                        activePreset.Tools    = decoded.Tools
                        activePreset._nodeMap = decoded._nodeMap
                        lastContent = fileData
                        print("OpenViz: Live-reloaded -> " .. activeCustomPresetName)
                    else
                        warn("OpenViz: Live-reload failed for " .. activeCustomPresetName .. " — check JSON syntax / NodeGraph format.")
                    end
                end
            end
        end
    end
end)
local function safePcall(fn, ...) return pcall(fn, ...) end
local function countTracked()
    local n = 0
    for _ in pairs(tracked) do n = n + 1 end
    return n
end

-- Loudness polling — checks all tracked tools AND the local character.
local function getMaxLoudness()
    local maxLoudness = 0
    for _, data in pairs(tracked) do
        if not data.sound or not data.sound.Parent then
            if data.handle and data.handle.Parent then
                data.sound = data.handle.Parent:FindFirstChildWhichIsA("Sound", true)
            end
        end
        if data.sound and data.sound.IsPlaying then
            if data.sound.PlaybackLoudness > maxLoudness then
                maxLoudness = data.sound.PlaybackLoudness
            end
        end
    end
    local myChar = player.Character
    if myChar then
        for _, item in ipairs(myChar:GetChildren()) do
            if item:IsA("Tool") then
                local s = item:FindFirstChildWhichIsA("Sound", true)
                if s and s.IsPlaying and s.PlaybackLoudness > maxLoudness then
                    maxLoudness = s.PlaybackLoudness
                end
            end
        end
    end
    return maxLoudness
end

-- AlignPosition + AlignOrientation setup for a tool handle.
local function setupMovers(handle)
    local att = Instance.new("Attachment")
    att.Name = "OrbitAtt"
    att.Parent = handle

    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = att
    alignPos.MaxForce = math.huge
    alignPos.Responsiveness = 200
    alignPos.ApplyAtCenterOfMass = true
    alignPos.Parent = handle

    local alignRot = Instance.new("AlignOrientation")
    alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignRot.Attachment0 = att
    alignRot.MaxTorque = math.huge
    alignRot.Responsiveness = 200
    alignRot.Parent = handle

    return alignPos, alignRot, att
end

local function trackTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tracked[tool] then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    local sound = tool:FindFirstChildWhichIsA("Sound", true)
    idxCounter = idxCounter + 1
    safePcall(function()
        handle.Massless = true
        handle.CanCollide = false
        handle.AssemblyLinearVelocity = Vector3.new(0, 4, 0)
    end)
    local ap, ao, att = setupMovers(handle)
    tracked[tool] = {
        handle = handle, sound = sound,
        alignPos = ap, alignRot = ao, att = att,
        index = idxCounter, netlessAllowed = false, startTime = tick()
    }
    task.delay(0.2, function() if tracked[tool] then tracked[tool].netlessAllowed = true end end)
end

local function untrackAndDestroy(tool)
    local data = tracked[tool]
    if not data then return end
    safePcall(function()
        if data.alignPos then data.alignPos:Destroy() end
        if data.alignRot then data.alignRot:Destroy() end
        if data.att      then data.att:Destroy()      end
    end)
    tracked[tool] = nil
end

local function setToolAnim(id)
    if not character then return end
    local animScript = character:FindFirstChild("Animate")
    if animScript then
        local toolNone = animScript:FindFirstChild("toolnone")
        if toolNone then
            local anim = toolNone:FindFirstChild("ToolNoneAnim")
            if anim then anim.AnimationId = id end
        end
    end
end

local function stopVisualizer()
    orbiting = false
    idxCounter = 0
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 16
        player.Character.Humanoid.JumpPower = 50
        workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
    end
    for tool, _ in pairs(tracked) do untrackAndDestroy(tool) end
    tracked = {}
    for _, jjj in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if jjj:IsA("Tool") then jjj.Parent = game.Players.LocalPlayer.Backpack end
    end
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        if player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            setToolAnim("http://www.roblox.com/asset/?id=507768375")
        elseif player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            setToolAnim("rbxassetid://182393478")
        end
    end
end

local function getWingSideInfo(index, total)
    if index == 1 then return 0, 0, 0, 1 end

    local wingIndex = index - 2
    local side = (wingIndex % 2 == 0) and -1 or 1
    local idx = math.floor(wingIndex / 2) + 1
    local sideTotal = side == -1
        and math.ceil((total - 1) / 2)
        or math.floor((total - 1) / 2)
    sideTotal = math.max(1, sideTotal)

    return side, idx, idx / sideTotal, sideTotal
end

local function getWingLocalPos(index, total, radius, t)
    t = t or 0
    if index == 1 then
        return Vector3.new(0, currentHeight + radius * 0.22, 2.45)
    end

    local side, _, progress = getWingSideInfo(index, total)
    local arc = progress * math.pi
    local flap = math.sin(t * currentSpeed * 3.2)
    local flapStrength = progress * radius * 0.42
    local x = side * (radius * 0.75 + progress * radius * 4.65)
    local y = currentHeight + radius * 0.24 + math.sin(arc) * radius * 0.95 - progress * radius * 0.18
        + flap * flapStrength
    local z = 2.45 + (1 - math.cos(arc)) * radius * 0.28
        - flap * progress * radius * 0.12

    return Vector3.new(x, y, z)
end

local function computeTargetPos(index, t, hrp)
    local preset = activePreset
    local i = index or 1
    local total = math.max(1, countTracked())
    local baseVal = (preset.radius or 5)
    if baseVal == 0 then baseVal = 1 end
    local radiusMultiplier = 1 + (currentRadiusBoost / baseVal)

    if preset.circleH then
        local radius = currentSize * radiusMultiplier
        local angle = t * currentSpeed + ((2 * math.pi / total) * (i - 1))
        return hrp.CFrame:PointToWorldSpace(
            Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
            + Vector3.new(0, currentHeight, 0))

    elseif preset.pennyRoll then
        local radius = currentSize * radiusMultiplier
        local angle = t * currentSpeed * 2.4 + ((2 * math.pi / total) * (i - 1))
        local wobble = math.rad(18 + (math.sin(t * currentSpeed * 1.7) * 11))
        local precess = CFrame.Angles(0, t * currentSpeed * 0.55, 0)
        local lean = CFrame.Angles(wobble, 0, 0)
        local localPos = (precess * lean * CFrame.new(
            math.cos(angle) * radius,
            currentHeight + math.sin(t * currentSpeed * 3.1) * currentSize * 0.08,
            math.sin(angle) * radius
        )).Position
        return hrp.CFrame:PointToWorldSpace(localPos)

    elseif preset.infinity then
        local radius = currentSize * radiusMultiplier
        local loopAngle = (math.pi * 2 / total) * (i - 1) + (t * currentSpeed)
        return hrp.CFrame:PointToWorldSpace(
            Vector3.new(radius * math.sin(loopAngle), currentHeight,
                        radius * 0.7 * math.sin(loopAngle) * math.cos(loopAngle)))

    elseif preset.rotatingInfinity then
        local radius = currentSize * radiusMultiplier
        local loopAngle = (math.pi * 2 / total) * (i - 1)
        local lx = radius * math.sin(loopAngle)
        local lz = radius * 0.7 * math.sin(loopAngle) * math.cos(loopAngle)
        local spin = t * currentSpeed
        local x = (lx * math.cos(spin)) - (lz * math.sin(spin))
        local z = (lx * math.sin(spin)) + (lz * math.cos(spin))
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight, z))

    elseif preset.wingsV2 then
        local radius = currentSize * radiusMultiplier
        return hrp.CFrame:PointToWorldSpace(getWingLocalPos(i, total, radius, t))

    elseif preset.wavy then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local wave = math.sin(angle*2) * (currentSize*0.3)
        return hrp.CFrame:PointToWorldSpace(
            Vector3.new(math.cos(angle)*radius, currentHeight+wave, math.sin(angle)*radius))

    elseif preset.wobbly then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local wobble = math.rad(14 + (math.sin(t * currentSpeed * 1.7) * 10))
        local precess = CFrame.Angles(0, t * currentSpeed * 0.45, 0)
        local lean = CFrame.Angles(wobble, 0, math.sin(t * currentSpeed * 1.1) * 0.18)
        local localPos = (precess * lean * CFrame.new(
            math.cos(angle) * radius,
            currentHeight + math.sin(t * currentSpeed * 2.8) * currentSize * 0.08,
            math.sin(angle) * radius
        )).Position
        return hrp.CFrame:PointToWorldSpace(localPos)

    elseif preset.backInfinity then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local lx = radius * math.sin(angle)
        local ly = radius * 0.6 * math.sin(angle) * math.cos(angle)
        local lz = 3 - (math.abs(lx)*0.3)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(lx, currentHeight+ly, lz))

    elseif preset.knot then
        local radius = currentSize * radiusMultiplier * 0.4
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local lx = math.sin(angle) + 2*math.sin(2*angle)
        local ly = math.cos(angle) - 2*math.cos(2*angle)
        local lz = -math.sin(3*angle)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(lx*radius, currentHeight+ly*radius, lz*radius))

    elseif preset.lissajous then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.sin(3*angle)*radius,
            currentHeight + math.sin(4*angle)*radius,
            math.cos(5*angle)*radius))

    elseif preset.sineWave then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local waveHeight = math.sin((angle * 3) + (t * currentSpeed * 1.5)) * (currentSize * 0.45)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            currentHeight + waveHeight,
            math.sin(angle) * radius))

    elseif preset.heart then
        local angle = (i/total)*math.pi*2 + (t*currentSpeed*0.5)
        local x = 16 * math.pow(math.sin(angle), 3)
        local y = 13*math.cos(angle) - 5*math.cos(2*angle) - 2*math.cos(3*angle) - math.cos(4*angle)
        local scale = currentSize * 0.05 * radiusMultiplier
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x*scale, y*scale+currentHeight, 0))

    elseif preset.xSymbol then
        local denom = math.max(1, total - 1)
        local u = (i - 1) / denom
        local scale = currentSize * radiusMultiplier
        local width  = scale * 3.0
        local height = scale * 2.2
        local forward = 3.5 + scale * 0.35
        local diag = (i % 2 == 1)
        local p = u
        local x = (-0.5 + p) * width
        local y = diag and ((-0.5 + p) * height) or ((0.5 - p) * height)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight + y, forward))

    elseif preset.crossSymbol then
        local denom = math.max(1, total - 1)
        local u = (i - 1) / denom
        local scale = currentSize * radiusMultiplier
        local arm = scale * 1.6
        local forward = 3.5 + scale * 0.35
        local horizontal = (i % 2 == 1)
        local p = (u * 2) - 1
        if horizontal then
            return hrp.CFrame:PointToWorldSpace(Vector3.new(p * arm, currentHeight, forward))
        else
            return hrp.CFrame:PointToWorldSpace(Vector3.new(0, currentHeight + p * arm, forward))
        end

    elseif preset.starSymbol then
        local points = 5
        local pTotal = math.max(1, total)
        local seg = (i - 1) / pTotal
        local angle = (seg * points * math.pi * 2) + (t * currentSpeed)
        local r = (i % 2 == 0) and (currentSize * 0.4) or (currentSize * radiusMultiplier)
        local outerAngle = ((i - 1) / pTotal) * math.pi * 2 + (t * currentSpeed)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(outerAngle) * r,
            currentHeight,
            math.sin(outerAngle) * r))

    elseif preset.helix then
        local turns = 3
        local progress = (i - 1) / math.max(1, total - 1)
        local angle = progress * math.pi * 2 * turns + (t * currentSpeed)
        local radius = currentSize * radiusMultiplier * 0.6
        local height = currentHeight + (progress - 0.5) * currentSize * 4
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            height,
            math.sin(angle) * radius))

    elseif preset.audioLiftCircle then
        local radius = currentSize * radiusMultiplier
        local angle = t * currentSpeed + ((2 * math.pi / total) * (i - 1))
        local audioLift = audioVisualizerEnabled and (currentRadiusBoost * 1.35) or 0
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            -2.4 + currentHeight + audioLift,
            math.sin(angle) * radius))

    elseif preset.tornado then
        local spacing = (currentSize * radiusMultiplier) * 0.5
        local height = currentHeight + (i - 1) * spacing
        return hrp.CFrame:PointToWorldSpace(Vector3.new(0, height, 0))

    elseif preset.galaxy then
        local arms = 3
        local progress = (i - 1) / math.max(1, total)
        local armIdx = (i - 1) % arms
        local armOffset = (armIdx / arms) * math.pi * 2
        local angle = armOffset + progress * math.pi * 4 + (t * currentSpeed)
        local radius = currentSize * radiusMultiplier * (0.2 + progress * 1.6)
        local sag = math.sin(progress * math.pi) * 0.3
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            currentHeight + sag,
            math.sin(angle) * radius))

    elseif preset.shield then
        local totalSafe = math.max(1, total)
        local goldenAngle = math.pi * (3 - math.sqrt(5))
        local y = 1 - 2 * ((i - 0.5) / totalSafe)
        local r = math.sqrt(math.max(0, 1 - y * y))
        local theta = i * goldenAngle + (t * currentSpeed)
        local radius = currentSize * radiusMultiplier
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(theta) * r * radius,
            currentHeight + y * radius,
            math.sin(theta) * r * radius))

    elseif preset.wall then
        local cols = math.max(1, math.ceil(math.sqrt(total)))
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local rowsTotal = math.ceil(total / cols)
        local spacing = (currentSize * radiusMultiplier) * 0.6
        local x = (col - (cols - 1) / 2) * spacing
        local y = (row - (rowsTotal - 1) / 2) * spacing
        local forward = 3.5 + currentSize * 0.35
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight + y, forward))

    elseif preset.equalizer then
        local spacing = currentSize * 0.5
        local centerOffset = (i - (total / 2) - 0.5) * spacing
        local barPhase = (i * 0.7) + (t * 4)
        local audioPulse = audioVisualizerEnabled and (currentRadiusBoost * 0.4) or 0
        local barHeight = (math.abs(math.sin(barPhase)) * currentSize * 0.6) + audioPulse
        local forward = 3.5 + currentSize * 0.25
        return hrp.CFrame:PointToWorldSpace(Vector3.new(centerOffset, currentHeight + barHeight, forward))

    elseif preset.dna then
        local progress = (i - 1) / math.max(1, total - 1)
        local strand = (i % 2 == 0) and 1 or -1
        local turns = 3
        local angle = progress * math.pi * 2 * turns + (t * currentSpeed)
        local radius = currentSize * radiusMultiplier * 0.55
        local height = currentHeight + (progress - 0.5) * currentSize * 4
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius * strand,
            height,
            math.sin(angle) * radius))

    elseif preset.pulseRing then
        local angle = (math.pi * 2 / total) * (i - 1)
        local pulse = audioVisualizerEnabled and (currentRadiusBoost * 0.6) or 0
        local radius = (currentSize * radiusMultiplier) + pulse + math.sin(t * currentSpeed * 4) * (currentSize * 0.15)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            currentHeight,
            math.sin(angle) * radius))

    elseif preset.corePulse then
        local audioPulse = audioVisualizerEnabled and currentRadiusBoost or 0
        local angle = (math.pi * 2 / total) * (i - 1) + (t * currentSpeed * 0.25)
        local spread = audioPulse * 0.95
        local x = math.cos(angle) * spread
        local y = currentHeight + math.sin((angle * 4) + (t * currentSpeed * 3.5)) * spread * 0.12
        local z = math.sin(angle) * spread
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, y, z))

    elseif preset.atom then
        local ring = ((i - 1) % 3) + 1
        local idxInRing = math.floor((i - 1) / 3)
        local perRing = math.max(1, math.ceil(total / 3))
        local angle = (idxInRing / perRing) * math.pi * 2 + (t * currentSpeed)
        local radius = currentSize * radiusMultiplier
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        local pos
        if ring == 1 then
            pos = Vector3.new(x, currentHeight + y, 0)
        elseif ring == 2 then
            pos = Vector3.new(0, currentHeight + math.cos(angle) * radius, math.sin(angle) * radius)
        else
            pos = Vector3.new(x, currentHeight, y)
        end
        return hrp.CFrame:PointToWorldSpace(pos)

    elseif preset.cubeShape then
        local edges = 12
        local edge = ((i - 1) % edges) + 1
        local along = ((i - 1) / edges) % 1
        local s = currentSize * radiusMultiplier
        local h = s
        local function corner(ix, iy, iz) return Vector3.new(ix * s, iy * h, iz * s) end
        local edgeMap = {
            {corner(-1,-1,-1), corner( 1,-1,-1)},
            {corner( 1,-1,-1), corner( 1,-1, 1)},
            {corner( 1,-1, 1), corner(-1,-1, 1)},
            {corner(-1,-1, 1), corner(-1,-1,-1)},
            {corner(-1, 1,-1), corner( 1, 1,-1)},
            {corner( 1, 1,-1), corner( 1, 1, 1)},
            {corner( 1, 1, 1), corner(-1, 1, 1)},
            {corner(-1, 1, 1), corner(-1, 1,-1)},
            {corner(-1,-1,-1), corner(-1, 1,-1)},
            {corner( 1,-1,-1), corner( 1, 1,-1)},
            {corner( 1,-1, 1), corner( 1, 1, 1)},
            {corner(-1,-1, 1), corner(-1, 1, 1)},
        }
        local a, b = edgeMap[edge][1], edgeMap[edge][2]
        local pos = a:Lerp(b, along) + Vector3.new(0, currentHeight, 0)
        local spin = CFrame.Angles(0, t * currentSpeed, 0)
        return hrp.CFrame:PointToWorldSpace((spin * CFrame.new(pos)).Position)

    elseif preset.pyramid then
        local edges = 8
        local edge = ((i - 1) % edges) + 1
        local along = ((i - 1) / edges) % 1
        local s = currentSize * radiusMultiplier
        local apex = Vector3.new(0, s * 1.6, 0)
        local b1 = Vector3.new(-s,  0, -s)
        local b2 = Vector3.new( s,  0, -s)
        local b3 = Vector3.new( s,  0,  s)
        local b4 = Vector3.new(-s,  0,  s)
        local edgeMap = {
            {b1, b2}, {b2, b3}, {b3, b4}, {b4, b1},
            {b1, apex}, {b2, apex}, {b3, apex}, {b4, apex},
        }
        local a, b = edgeMap[edge][1], edgeMap[edge][2]
        local pos = a:Lerp(b, along) + Vector3.new(0, currentHeight, 0)
        local spin = CFrame.Angles(0, t * currentSpeed, 0)
        return hrp.CFrame:PointToWorldSpace((spin * CFrame.new(pos)).Position)

    elseif preset.arrow then
        local denom = math.max(1, total - 1)
        local u = (i - 1) / denom
        local s = currentSize * radiusMultiplier
        local shaftEnd = 0.6
        local x, z
        if u <= shaftEnd then
            local p = u / shaftEnd
            x = 0
            z = 1.5 + p * s * 2
        else
            local p = (u - shaftEnd) / (1 - shaftEnd)
            local side = (i % 2 == 0) and 1 or -1
            x = side * p * s * 0.9
            z = 1.5 + s * 2 - p * s * 0.9
        end
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight, z))

    elseif preset.triShape then
        local sides = 3
        local edges = sides
        local edge = ((i - 1) % edges)
        local along = ((i - 1) / edges) % 1
        local r = currentSize * radiusMultiplier
        local angA = (edge / sides) * math.pi * 2 + (t * currentSpeed)
        local angB = ((edge + 1) / sides) * math.pi * 2 + (t * currentSpeed)
        local a = Vector3.new(math.cos(angA) * r, currentHeight, math.sin(angA) * r)
        local b = Vector3.new(math.cos(angB) * r, currentHeight, math.sin(angB) * r)
        local pos = a:Lerp(b, along)
        return hrp.CFrame:PointToWorldSpace(pos)

    elseif preset.hexShape then
        local sides = 6
        local edges = sides
        local edge = ((i - 1) % edges)
        local along = ((i - 1) / edges) % 1
        local r = currentSize * radiusMultiplier
        local angA = (edge / sides) * math.pi * 2 + (t * currentSpeed)
        local angB = ((edge + 1) / sides) * math.pi * 2 + (t * currentSpeed)
        local a = Vector3.new(math.cos(angA) * r, currentHeight, math.sin(angA) * r)
        local b = Vector3.new(math.cos(angB) * r, currentHeight, math.sin(angB) * r)
        local pos = a:Lerp(b, along)
        return hrp.CFrame:PointToWorldSpace(pos)

    elseif preset.floorTile then
        local cols = math.max(1, math.ceil(math.sqrt(total)))
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local rowsTotal = math.ceil(total / cols)
        local spacing = (currentSize * radiusMultiplier) * 0.55
        local x = (col - (cols - 1) / 2) * spacing
        local z = (row - (rowsTotal - 1) / 2) * spacing
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight - 1.5, z))

    elseif preset.fountain then
        local lifespan = 2.0
        local seed = (i * 0.91) + sessionSeed
        local launchAngle = (seed % math.pi)
        local age = ((t * currentSpeed) + seed) % lifespan
        local norm = age / lifespan
        local outwardAngle = (i / math.max(1, total)) * math.pi * 2
        local horiz = math.sin(launchAngle) * (currentSize * radiusMultiplier) * norm
        local vert = math.cos(launchAngle) * (currentSize * 2.2) * (1 - (norm - 0.5) * (norm - 0.5) * 4)
        local x = math.cos(outwardAngle) * horiz
        local z = math.sin(outwardAngle) * horiz
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, currentHeight + vert, z))

    else
        local radius = currentSize * radiusMultiplier
        local angle = t*currentSpeed + i*0.5
        return hrp.Position + Vector3.new(
            math.cos(angle)*radius, currentHeight+i*0.25, math.sin(angle)*radius)
    end
end

local function getTargetLookPos(index, hrp)
    if lookLocked then return hrp.Position end
    if activePreset.wingsV2 then
        return hrp.Position + hrp.CFrame.LookVector * 50
    end
    return nil
end

local OPENVIZ_THEME = "Nebula"
local loadingGui, loadingHolder, loadingFill, loadingStatus, loadingPercent
local loadingStroke, loadingLogo, loadingLogoGradient, loadingFillGradient, loadingFillStroke

local loadingThemes = {
    Nebula = {
        accent = Color3.fromRGB(124, 92, 255),
        accent2 = Color3.fromRGB(92, 255, 236),
        accent3 = Color3.fromRGB(215, 64, 255),
        panel1 = Color3.fromRGB(12, 16, 23),
        panel2 = Color3.fromRGB(7, 10, 15),
        panel3 = Color3.fromRGB(15, 18, 27),
        muted = Color3.fromRGB(145, 151, 169),
    },
    Midnight = {
        accent = Color3.fromRGB(145, 125, 255),
        accent2 = Color3.fromRGB(95, 210, 255),
        accent3 = Color3.fromRGB(145, 125, 255),
        panel1 = Color3.fromRGB(18, 18, 28),
        panel2 = Color3.fromRGB(11, 12, 20),
        panel3 = Color3.fromRGB(24, 22, 38),
        muted = Color3.fromRGB(145, 140, 185),
    },
    Rose = {
        accent = Color3.fromRGB(255, 105, 150),
        accent2 = Color3.fromRGB(255, 155, 190),
        accent3 = Color3.fromRGB(210, 90, 255),
        panel1 = Color3.fromRGB(28, 16, 24),
        panel2 = Color3.fromRGB(18, 12, 18),
        panel3 = Color3.fromRGB(36, 20, 32),
        muted = Color3.fromRGB(185, 130, 155),
    },
    Emerald = {
        accent = Color3.fromRGB(60, 220, 150),
        accent2 = Color3.fromRGB(120, 255, 205),
        accent3 = Color3.fromRGB(55, 175, 255),
        panel1 = Color3.fromRGB(14, 24, 22),
        panel2 = Color3.fromRGB(10, 17, 16),
        panel3 = Color3.fromRGB(18, 34, 30),
        muted = Color3.fromRGB(120, 170, 155),
    },
}

local function applyLoadingTheme(themeName)
    local theme = loadingThemes[themeName or OPENVIZ_THEME] or loadingThemes.Nebula
    if loadingStroke then loadingStroke.Color = theme.accent end
    if loadingLogo then loadingLogo.BackgroundColor3 = Color3.fromRGB(9, 12, 18) end
    if loadingStatus then loadingStatus.TextColor3 = Color3.fromRGB(165, 180, 210) end
    if loadingPercent then loadingPercent.TextColor3 = theme.accent end
    if loadingLogoGradient then
        loadingLogoGradient.Color = ColorSequence.new(Color3.fromRGB(15, 20, 30), Color3.fromRGB(9, 12, 18))
    end
    if loadingFill then loadingFill.BackgroundColor3 = theme.accent end
    if loadingFillGradient then
        loadingFillGradient.Color = ColorSequence.new(theme.accent2, theme.accent3)
    end
    if loadingFillStroke then loadingFillStroke.Color = theme.accent2 end

    local holder = loadingGui and loadingGui:FindFirstChild("Holder")
    local holderGradient = holder and holder:FindFirstChild("ThemeGradient")
    local subtitle = holder and holder:FindFirstChild("Subtitle")
    if holder then holder.BackgroundColor3 = theme.panel2 end
    if subtitle then subtitle.TextColor3 = theme.muted end
    if holderGradient then
        holderGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.panel1),
            ColorSequenceKeypoint.new(0.55, theme.panel2),
            ColorSequenceKeypoint.new(1, theme.panel3),
        })
    end
end

local function createLoadingBar()
    local parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
    loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "OpenVizLoading"
    loadingGui.ResetOnSpawn = false
    loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loadingGui.Parent = parent

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    loadingHolder = holder
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.new(0.5, 0, 0.5, 0)
    holder.Size = UDim2.new(0, 520, 0, 170)
    holder.BackgroundColor3 = Color3.fromRGB(7, 10, 15)
    holder.BackgroundTransparency = 0.02
    holder.BorderSizePixel = 0
    holder.Parent = loadingGui

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 8)
    shadow.Size = UDim2.new(1, 42, 1, 42)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = holder.ZIndex - 1
    shadow.Parent = holder

    loadingStroke = Instance.new("UIStroke")
    loadingStroke.Color = Color3.fromRGB(90, 160, 255)
    loadingStroke.Thickness = 1
    loadingStroke.Transparency = 0.18
    loadingStroke.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = holder

    local gradient = Instance.new("UIGradient")
    gradient.Name = "ThemeGradient"
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 21, 30)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 15, 22)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 27, 38)),
    })
    gradient.Rotation = 24
    gradient.Parent = holder

    local sideRail = Instance.new("Frame")
    sideRail.Name = "SideRail"
    sideRail.Position = UDim2.new(0, 0, 0, 0)
    sideRail.Size = UDim2.new(0, 154, 1, 0)
    sideRail.BackgroundColor3 = Color3.fromRGB(10, 14, 21)
    sideRail.BackgroundTransparency = 0.04
    sideRail.BorderSizePixel = 0
    sideRail.Parent = holder

    local railCorner = Instance.new("UICorner")
    railCorner.CornerRadius = UDim.new(0, 9)
    railCorner.Parent = sideRail

    local railLine = Instance.new("Frame")
    railLine.Position = UDim2.new(1, -1, 0, 12)
    railLine.Size = UDim2.new(0, 1, 1, -24)
    railLine.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
    railLine.BorderSizePixel = 0
    railLine.Parent = sideRail

    loadingLogo = Instance.new("Frame")
    loadingLogo.Position = UDim2.new(0, 22, 0, 22)
    loadingLogo.Size = UDim2.new(0, 48, 0, 48)
    loadingLogo.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
    loadingLogo.BorderSizePixel = 0
    loadingLogo.Parent = holder

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(1, 0)
    logoCorner.Parent = loadingLogo

    loadingLogoGradient = Instance.new("UIGradient")
    loadingLogoGradient.Color = ColorSequence.new(Color3.fromRGB(120, 190, 255), Color3.fromRGB(70, 120, 255))
    loadingLogoGradient.Rotation = 35
    loadingLogoGradient.Parent = loadingLogo

    local logoText = Instance.new("TextLabel")
    logoText.BackgroundTransparency = 1
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.Font = Enum.Font.GothamBlack
    logoText.Text = "OV"
    logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoText.TextSize = 15
    logoText.Parent = loadingLogo

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 84, 0, 24)
    title.Size = UDim2.new(0, 220, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.Text = "OpenViz"
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = holder

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 24, 0, 86)
    subtitle.Size = UDim2.new(0, 110, 0, 18)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Text = "Starlight build"
    subtitle.TextColor3 = Color3.fromRGB(110, 130, 165)
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = holder

    loadingStatus = Instance.new("TextLabel")
    loadingStatus.BackgroundTransparency = 1
    loadingStatus.Position = UDim2.new(0, 178, 0, 42)
    loadingStatus.Size = UDim2.new(1, -210, 0, 18)
    loadingStatus.Font = Enum.Font.GothamMedium
    loadingStatus.Text = "Starting..."
    loadingStatus.TextColor3 = Color3.fromRGB(165, 180, 210)
    loadingStatus.TextSize = 12
    loadingStatus.TextXAlignment = Enum.TextXAlignment.Left
    loadingStatus.Parent = holder

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 178, 0, 95)
    bar.Size = UDim2.new(1, -210, 0, 4)
    bar.BackgroundColor3 = Color3.fromRGB(25, 29, 40)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    loadingFill = Instance.new("Frame")
    loadingFill.Size = UDim2.new(0, 0, 1, 0)
    loadingFill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
    loadingFill.BorderSizePixel = 0
    loadingFill.Parent = bar

    loadingFillGradient = Instance.new("UIGradient")
    loadingFillGradient.Color = ColorSequence.new(Color3.fromRGB(105, 210, 255), Color3.fromRGB(90, 120, 255))
    loadingFillGradient.Rotation = 0
    loadingFillGradient.Parent = loadingFill

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = loadingFill

    loadingFillStroke = Instance.new("UIStroke")
    loadingFillStroke.Color = Color3.fromRGB(180, 230, 255)
    loadingFillStroke.Thickness = 1
    loadingFillStroke.Transparency = 0.55
    loadingFillStroke.Parent = loadingFill

    loadingPercent = Instance.new("TextLabel")
    loadingPercent.BackgroundTransparency = 1
    loadingPercent.Position = UDim2.new(0, 178, 0, 114)
    loadingPercent.Size = UDim2.new(1, -210, 0, 16)
    loadingPercent.Font = Enum.Font.GothamMedium
    loadingPercent.Text = "0%"
    loadingPercent.TextColor3 = Color3.fromRGB(90, 160, 255)
    loadingPercent.TextSize = 12
    loadingPercent.TextXAlignment = Enum.TextXAlignment.Right
    loadingPercent.Parent = holder

    local loadingCaption = Instance.new("TextLabel")
    loadingCaption.BackgroundTransparency = 1
    loadingCaption.Position = UDim2.new(0, 178, 0, 70)
    loadingCaption.Size = UDim2.new(1, -210, 0, 16)
    loadingCaption.Font = Enum.Font.Gotham
    loadingCaption.Text = "Preparing visualizer modules"
    loadingCaption.TextColor3 = Color3.fromRGB(90, 97, 115)
    loadingCaption.TextSize = 11
    loadingCaption.TextXAlignment = Enum.TextXAlignment.Left
    loadingCaption.Parent = holder

    applyLoadingTheme(OPENVIZ_THEME)
end

local function updateLoadingBar(progress, status)
    if not loadingGui then return end
    progress = math.clamp(progress or 0, 0, 1)
    if loadingStatus then loadingStatus.Text = status or loadingStatus.Text end
    if loadingPercent then loadingPercent.Text = tostring(math.floor(progress * 100 + 0.5)) .. "%" end
    if loadingFill then
        TweenService:Create(loadingFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
    end
end

local function finishLoadingBar(status)
    updateLoadingBar(1, status or "Ready")
    task.delay(0.45, function()
        if loadingGui then
            loadingGui:Destroy()
            loadingGui = nil
        end
    end)
end

createLoadingBar()
updateLoadingBar(0.08, "Loading Starlight...")
print("[OpenViz] UI: loading Starlight...")
task.spawn(function()
    task.wait(8)
    warn("[OpenViz] UI: still loading... if you're stuck here, your executor/HTTP is blocking raw.nebulasoftworks.xyz")
end)

local Starlight
do
    local ok, res = pcall(function()
        local src = game:HttpGet("https://raw.nebulasoftworks.xyz/starlight")
        local fn = loadstring(src)
        return fn and fn() or nil
    end)
    if not ok or not res then
        updateLoadingBar(1, "Failed to load Starlight")
        warn("[OpenViz] UI: failed to load Starlight")
        warn(res)
        return
    end
    Starlight = res
end

updateLoadingBar(0.42, "Loading icons...")
print("[OpenViz] UI: loading NebulaIcons...")
local NebulaIcons
do
    local ok, res = pcall(function()
        local src = game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader")
        local fn = loadstring(src)
        return fn and fn() or nil
    end)
    if not ok or not res then
        updateLoadingBar(1, "Failed to load icons")
        warn("[OpenViz] UI: failed to load NebulaIcons")
        warn(res)
        return
    end
    NebulaIcons = res
end

updateLoadingBar(0.68, "Building window...")
print("[OpenViz] UI: libraries loaded")

local OpenVizIcon = NebulaIcons:GetIcon("moon_stars", "Symbols")
local VisualizerIcon = NebulaIcons:GetIcon("view_in_ar", "Material")

local Window = Starlight:CreateWindow({
    Name = "OpenViz-bh",
    Subtitle = "THIS IS NOT ORIGINAL",
    Icon = OpenVizIcon,
    LoadingSettings = {
        Title = "OpenViz",
        Subtitle = "Loading...",
        Logo = OpenVizIcon,
    },
    FileSettings = {
        ConfigFolder = "OpenViz"
    },
})

updateLoadingBar(0.82, "Creating tabs...")
local TabSection = Window:CreateTabSection("OpenViz")
Window:CreateHomeTab({
    SupportedExecutors = {
        "Madium",
        "Volt",
        "Isaeva",
        "Potassium",
        "Velocity",
        "Synapse Z",
        "Seliware",
        "Sirhurt",
    },
    UnsupportedExecutors = {
        "Solara",
        "Wave",
        "Xeno",
        "Delta",
        "Cryptic",
        "Vega X",
    },
    DiscordInvite = "hgtb5WUGc5",
    Backdrop = 0,
    IconStyle = 1,
    Changelog = {
        {
            Title = "OpenViz Modded",
            Date = os.date("%B %d, %Y"),
            Description = "Added Starlight UI, custom presets, audio logging, theme/config settings, and new visualizer presets.",
        },
        {
            Title = "Visualizer Recovery",
            Date = os.date("%B %d, %Y"),
            Description = "Restored the original OpenViz visualizer mechanics from og_openviz while keeping the newer UI changes.",
        },
    },
})
local VisualizerTab = TabSection:CreateTab({
    Name = "Visualizer",
    Icon = VisualizerIcon,
    Columns = 2,
}, "OpenViz_Visualizer")
local UtilitiesTab = TabSection:CreateTab({
    Name = "Utilities",
    Icon = NebulaIcons:GetIcon("sparkle", "Material"),
    Columns = 1,
}, "OpenViz_Utilities")
local AudioTab = TabSection:CreateTab({
    Name = "Audio Logs",
    Icon = NebulaIcons:GetIcon("sparkle", "Material"),
    Columns = 2,
}, "OpenViz_AudioLogs")
local SettingsSection = Window:CreateTabSection("Settings")
local SettingsTab = SettingsSection:CreateTab({
    Name = "Settings",
    Icon = NebulaIcons:GetIcon("settings", "Lucide"),
    Columns = 2,
}, "OpenViz_SettingsTab")

SettingsTab:BuildThemeGroupbox(1)
SettingsTab:BuildConfigGroupbox(2)
Starlight:SetTheme(OPENVIZ_THEME)
Starlight:LoadAutoloadTheme()
applyLoadingTheme(OPENVIZ_THEME)
Starlight:LoadAutoloadConfig()

local function starlightCompat(groupbox, idPrefix)
    local compat = {}

    function compat:dropdown(cfg)
        local label = groupbox:CreateLabel({Name = cfg.name}, idPrefix .. "_" .. cfg.name .. "_Label")
        local dropdown = label:AddDropdown({
            Options = cfg.options or {},
            CurrentOptions = {cfg.def},
            Placeholder = cfg.def or "Select",
            Callback = function(options)
                local val = (type(options) == "table" and options[1]) or options
                if cfg.callback then cfg.callback(val) end
            end,
        }, idPrefix .. "_" .. cfg.name)
        if cfg.oncreate then cfg.oncreate(dropdown) end
        return dropdown
    end

    function compat:button(cfg)
        return groupbox:CreateButton({
            Name = cfg.name,
            Callback = cfg.callback,
        }, idPrefix .. "_" .. cfg.name)
    end

    function compat:slider(cfg)
        return groupbox:CreateSlider({
            Name = cfg.name,
            Range = {cfg.min or 0, cfg.max or 100},
            Increment = cfg.rounding and 1 or 0.1,
            CurrentValue = cfg.def,
            Callback = cfg.callback,
        }, idPrefix .. "_" .. cfg.name)
    end

    function compat:toggle(cfg)
        return groupbox:CreateToggle({
            Name = cfg.name,
            CurrentValue = cfg.def,
            Style = 2,
            Callback = cfg.callback,
        }, idPrefix .. "_" .. cfg.name)
    end

    function compat:textbox(cfg)
        return groupbox:CreateInput({
            Name = cfg.name,
            CurrentValue = cfg.def or "",
            PlaceholderText = cfg.placeholder or "",
            Callback = cfg.callback,
        }, idPrefix .. "_" .. cfg.name)
    end

    return compat
end

local ControlsSec = starlightCompat(VisualizerTab:CreateGroupbox({Name = "Controls", Column = 1}, "OpenViz_Controls"), "OpenViz_Controls")
local SettingsSec = starlightCompat(VisualizerTab:CreateGroupbox({Name = "Settings", Column = 2}, "OpenViz_Settings"), "OpenViz_Settings")
local AudioControlsSec = starlightCompat(AudioTab:CreateGroupbox({Name = "Audio Logger", Column = 1}, "OpenViz_AudioLogger"), "OpenViz_AudioLogger")
local AudioListBox = AudioTab:CreateGroupbox({Name = "Playing Audio", Column = 2}, "OpenViz_AudioList")
local MiscSec = starlightCompat(UtilitiesTab:CreateGroupbox({Name = "Utilities", Column = 1}, "OpenViz_Utilities_Box"), "OpenViz_Utilities")
local MainTab = {openpage = function() end}
updateLoadingBar(0.9, "Adding controls...")

-- Built-in presets dropdown
local presetOptions = {}
for k in pairs(orbitPresets) do table.insert(presetOptions, k) end
table.sort(presetOptions)

SettingsSec:dropdown({
    name = "Presets",
    def = "Circle",
    max = 5,
    options = presetOptions,
    callback = function(val)

        activePresetName = val
        activePreset = orbitPresets[val]
        activeCustomPresetName = "None"
        if val == "Random" then sessionSeed = math.random(1, 100000) end
        if orbiting and character and character:FindFirstChild("Humanoid") then
            if activePreset.r6Clone or activePreset.wheelClone then
                character.Humanoid.WalkSpeed = 0
                character.Humanoid.JumpPower = 0
                if character:FindFirstChild("HumanoidRootPart") then
                    clonePos = character.HumanoidRootPart.Position
                              + character.HumanoidRootPart.CFrame.LookVector * -3
                    cloneLook = character.HumanoidRootPart.CFrame.LookVector
                end
                workspace.CurrentCamera.CameraSubject = camPart
            else
                character.Humanoid.WalkSpeed = 16
                character.Humanoid.JumpPower = 50
                workspace.CurrentCamera.CameraSubject = character.Humanoid
            end
        end
    end
})

SettingsSec:dropdown({
    name = "Custom Presets",
    def = "None",
    max = 5,
    options = customPresetNames,
    callback = function(val)
        activeCustomPresetName = val
        if val == "None" then
            activePreset = orbitPresets[activePresetName]
        else
            local cp = customPresets[val]
            if cp then

                activePreset = cp
                activePreset.custom = true
                print("Switched to custom preset -> " .. val)
            end
        end
    end,
    oncreate = function(obj) CustomPresetsDropdown = obj end
})

SettingsSec:button({
    name = "Refresh",
    callback = function()
        refreshCustomPresets()
        print("OpenViz: Custom presets refreshed. Found " .. (#customPresetNames - 1) .. " preset(s).")
    end
})

SettingsSec:slider({name="Speed",  def=1,   max=20,  min=1,   rounding=true, callback=function(v) currentSpeed  = v*0.25 end})
SettingsSec:slider({name="Size",   def=4,   max=50,  min=1,   rounding=true, callback=function(v) currentSize   = v      end})
SettingsSec:slider({name="Height", def=1,   max=30,  min=-10, rounding=true, callback=function(v) currentHeight = v      end})
SettingsSec:slider({name="Visualizer Sensitivity", def=100, max=100, min=0, rounding=true, callback=function(v) visualizerSensitivity = v/100 end})
SettingsSec:toggle({name="Audio Visualize (React)", def=true,  callback=function(b) audioVisualizerEnabled = b end})
SettingsSec:toggle({name="Netless",                  def=true,  callback=function(b) netlessEnabled         = b end})

ControlsSec:textbox({name="Target Player", def="", callback=function(text)
    if text == "" then targetPlayer = player; return end
    for _, p in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(p.Name),        1, #text) == string.lower(text)
        or string.sub(string.lower(p.DisplayName), 1, #text) == string.lower(text) then
            targetPlayer = p; return
        end
    end
    if not targetPlayer then targetPlayer = player end
end})

ControlsSec:textbox({name="Audio ID", def="", callback=function(text)
    local id = string.match(text, "%d+")
    if id then
        audioId = tonumber(id)
        if player.Character then
            for _, tool in ipairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Remote") then
                    tool.Remote:FireServer("PlaySong", audioId)
                end
            end
        end
    end
end})

ControlsSec:button({name = "Clear Audio ID", callback = function()
    audioId = nil
    print("OpenViz: Audio ID cleared")
end})

ControlsSec:button({name = "Sync Audio", callback = function()
    if not audioId then return end
    local char = player.Character
    if not char then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local remote = tool:FindFirstChild("Remote")
            if remote then
                remote:FireServer("PlaySong", audioId)
            end
        end
    end
end})

ControlsSec:button({name = "Mass Play", callback = function()
    if not audioId then 
        print("OpenViz: No audio ID set")
        return 
    end

    task.spawn(function()
        local char = player.Character
        if not char or not char:FindFirstChild("Humanoid") then return end

        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then tool.Parent = char end
            end
        end

        -- Wait until all tools are confirmed in character (max 60 frames)
        local waited = 0
        repeat
            task.wait()
            waited += 1
        until (function()
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and not t:FindFirstChild("Handle") then return false end
            end
            return true
        end)() or waited >= 60

        local success = 0
        local tools = {}
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end

        -- Fire all remotes in the same frame for tightest sync
        for _, tool in ipairs(tools) do
            local playAudio = tool:FindFirstChild("PlayAudio")
            if playAudio and playAudio:IsA("RemoteFunction") then
                task.spawn(function()
                    pcall(function()
                        playAudio:InvokeServer("PlayAudio", tostring(audioId), "1", "0", "0")
                        success += 1
                    end)
                end)
            else
                local remote = tool:FindFirstChild("Remote")
                if remote then
                    pcall(function() remote:FireServer("PlaySong", audioId) end)
                end
            end
        end

        task.wait(0.1)
        print("Mass Play finished → " .. #tools .. " boomboxes triggered")
    end)
end})


ControlsSec:textbox({name="Dupe Amount", def="5", callback=function(text)
    local n = tonumber(text)
    if n and n > 0 then dupeTargetAmount = n end
end})

local function moveTools(source, destination)
    if not source or not destination then return 0 end
    local moved = 0
    for _, item in ipairs(source:GetChildren()) do
        if item:IsA("Tool") then
            item.Parent = destination
            moved += 1
        end
    end
    return moved
end

local function equipWorkspaceTools(humanoid)
    if not humanoid then return 0 end
    local equipped = 0
    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("Tool") then
            pcall(function() humanoid:EquipTool(item) end)
            equipped += 1
        end
    end
    return equipped
end

local function waitUntil(fn, timeout)
    local start = tick()
    repeat
        if fn() then return true end
        task.wait()
    until tick() - start >= (timeout or 0.5)
    return false
end

ControlsSec:button({name="Start Dupe", callback=function()
    if dupeRunning then
        print("OpenViz: Dupe already running")
        return
    end
    dupeRunning = true

    task.spawn(function()
        local me = game.Players.LocalPlayer
        local initialChar = me.Character or me.CharacterAdded:Wait()
        local hrcf = initialChar:WaitForChild("HumanoidRootPart").CFrame
        local oldgrav = workspace.Gravity
        local completed = 0

        local ok, err = pcall(function()
            workspace.Gravity = 0

            for count = 1, dupeTargetAmount do
                local ch = me.Character or me.CharacterAdded:Wait()
                local hum = ch:WaitForChild("Humanoid")
                local hrp = ch:WaitForChild("HumanoidRootPart")
                local backpack = me:WaitForChild("Backpack")

                equipWorkspaceTools(hum)
                hrp.CFrame = CFrame.new(0, 3000, 0)

                waitUntil(function()
                    return #backpack:GetChildren() > 0 or not ch.Parent
                end, 0.35)

                moveTools(backpack, ch)
                task.wait(0.06)
                moveTools(ch, workspace)

                completed = count
                hum.Health = 0
                me.CharacterAdded:Wait()
                task.wait(0.04)
            end

            local finalChar = me.Character or me.CharacterAdded:Wait()
            local finalhum  = finalChar:WaitForChild("Humanoid")
            equipWorkspaceTools(finalhum)
            finalChar:WaitForChild("HumanoidRootPart").CFrame = hrcf
        end)

        workspace.Gravity = oldgrav
        dupeRunning = false

        if ok then
            print("OpenViz: dupe finished -> " .. completed .. "/" .. dupeTargetAmount)
        else
            warn("OpenViz: dupe stopped -> " .. tostring(err))
        end
    end)
end})

ControlsSec:button({name="Visualize", callback=function()
    stopVisualizer()
    orbiting = true
    orbitStartTime = tick()
    idxCounter = 0
    sessionSeed = math.random(1, 100000)
    setToolAnim("rbxassetid://0")

    for _, jjj in ipairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if jjj:IsA("Tool") then jjj.Parent = game.Players.LocalPlayer.Backpack end
    end

    if (activePreset.r6Clone or activePreset.wheelClone)
    and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.Humanoid.WalkSpeed = 0
        player.Character.Humanoid.JumpPower = 0
        clonePos = player.Character.HumanoidRootPart.Position
                  + player.Character.HumanoidRootPart.CFrame.LookVector * -3
        cloneLook = player.Character.HumanoidRootPart.CFrame.LookVector
        activeEmote = nil
        timeIdle = 0
        wheelRollAngle = 0
        workspace.CurrentCamera.CameraSubject = camPart
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
        end
    end

    if player.Backpack then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then tool.Parent = player.Character end
        end
    end
    for _, jjj in ipairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if jjj:IsA("Tool") then jjj.Parent = game.Players.LocalPlayer.Backpack end
    end

    for _, tool in ipairs(player:WaitForChild("Backpack"):GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            tool.Parent = player.Character
            tool.Parent = player.Backpack
            tool.Parent = player.Character
            tool.Parent = player.Backpack
            if player.Character:FindFirstChild("Humanoid") then
                tool.Parent = player.Character:FindFirstChild("Humanoid")
            end
            tool.Parent = player.Character
            RunService.Heartbeat:Wait()
            trackTool(tool)
        end
    end
end})


MiscSec:toggle({name="Anti Fling",   def=false, callback=function(b) antiFlingEnabled  = b end})
MiscSec:toggle({name="Steal Tools",  def=false, callback=function(b) stealToolsEnabled = b end})

local audioSpyEnabled = false
local audioListAutoRefresh = true
local spyTracked = {}
local nameCache = {}
local SPY_RANGE = 40
local audioListRows = {}
local AUDIO_LIST_MAX_ROWS = 12

local BLACKLIST = {
    ["Climbing"]=true,["Died"]=true,["GettingUp"]=true,["Swimming"]=true,
    ["Jumping"]=true,["Landing"]=true,["Splash"]=true,["FreeFalling"]=true,
    ["Running"]=true
}

local spyScreenGui = Instance.new("ScreenGui")
spyScreenGui.Name = "AudioSpyCore"
spyScreenGui.ResetOnSpawn = false
spyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
spyScreenGui.Parent = (syn and syn.protect_gui and syn.protect_gui(spyScreenGui) and player:WaitForChild("PlayerGui"))
                   or (gethui and gethui())
                   or player:WaitForChild("PlayerGui")

local function fmtTime(s)
    s = s or 0
    return string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
end
local function extractId(s)
    s = tostring(s or "")
    return tonumber(s:match("rbxassetid://(%d+)"))
        or tonumber(s:match("[?&]id=(%d+)"))
        or tonumber(s:match("(%d+)"))
        or 0
end
local function getName(id)
    if id <= 0 then return "Unknown" end
    if nameCache[id] then return nameCache[id] end
    pcall(function() nameCache[id] = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset).Name end)
    return nameCache[id] or "Unknown ("..id..")"
end
local function findValidAudio(char)
    for _, obj in ipairs(char:GetDescendants()) do
        if not BLACKLIST[obj.Name] then
            if obj:IsA("Sound") and obj.IsPlaying then
                local id = extractId(obj.SoundId)
                if id > 0 then
                    return obj, id, obj.Parent:IsA("BasePart") and obj.Parent or char:FindFirstChild("Head")
                end
            elseif obj:IsA("AudioPlayer") then
                local id = extractId(obj.AssetId)
                if id > 0 then return obj, id, char:FindFirstChild("Head") end
            end
        end
    end
end

local function collectPlayingAudios()
    local results = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local obj, id = findValidAudio(p.Character)
            if id then
                table.insert(results, {
                    player = p,
                    id = id,
                    name = getName(id),
                    loudness = (obj:IsA("Sound") and obj.PlaybackLoudness) or 0,
                    curT = (obj:IsA("Sound") and obj.TimePosition) or 0,
                    maxT = (obj:IsA("Sound") and obj.TimeLength) or 0,
                })
            end
        end
    end

    table.sort(results, function(a, b)
        if a.player.Name == b.player.Name then return a.id < b.id end
        return a.player.Name < b.player.Name
    end)

    return results
end

local function formatAudioLine(entry)
    return entry.name .. " | ID: " .. entry.id
        .. " | " .. fmtTime(entry.curT) .. "/" .. fmtTime(entry.maxT)
        .. " | L: " .. math.floor(entry.loudness or 0)
end

local function setAudioListRow(row, text)
    if not row then return end
    pcall(function() row:Set(text) end)
    pcall(function() row:SetText(text) end)
    pcall(function() row:Update(text) end)
    pcall(function() row.Text = text end)
    pcall(function() row.Name = text end)
    pcall(function()
        if row.Instance then row.Instance.Text = text end
    end)
    pcall(function()
        if row.Label then row.Label.Text = text end
    end)
    pcall(function()
        if row.TextLabel then row.TextLabel.Text = text end
    end)
end

local function refreshAudioList()
    local entries = collectPlayingAudios()
    for _, row in ipairs(audioListRows) do
        pcall(function() row:Destroy() end)
        pcall(function() if row.Instance then row.Instance:Destroy() end end)
        pcall(function() if row.Label then row.Label:Destroy() end end)
        pcall(function() if row.TextLabel then row.TextLabel:Destroy() end end)
    end
    table.clear(audioListRows)

    for i = 1, AUDIO_LIST_MAX_ROWS do
        local entry = entries[i]
        local text
        if entry then
            text = formatAudioLine(entry)
        elseif i == 1 then
            text = "No playing audio found"
        else
            break
        end
        table.insert(audioListRows, AudioListBox:CreateLabel({
            Name = text
        }, "OpenViz_AudioList_Row_" .. i .. "_" .. tostring(tick())))
        if entry then
            table.insert(audioListRows, AudioListBox:CreateButton({
                Name = "Copy ID: " .. tostring(entry.id),
                Callback = function()
                    local idText = tostring(entry.id)
                    if setclipboard then setclipboard(idText) elseif toclipboard then toclipboard(idText) end
                    print("OpenViz: Copied audio ID -> " .. idText)
                end,
            }, "OpenViz_AudioList_Copy_" .. i .. "_" .. tostring(tick())))
        end
    end

    if #entries > AUDIO_LIST_MAX_ROWS then
        local text = "+" .. (#entries - AUDIO_LIST_MAX_ROWS + 1) .. " more audio(s). Use Copy Full Audio List."
        table.insert(audioListRows, AudioListBox:CreateLabel({
            Name = text
        }, "OpenViz_AudioList_More_" .. tostring(tick())))
    end

    return entries
end

local function copyAudioEntries(entries)
    entries = entries or collectPlayingAudios()
    if #entries == 0 then
        print("OpenViz: No playing audio found")
        return
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        table.insert(lines, formatAudioLine(entry))
    end

    local str = table.concat(lines, "\n")
    if setclipboard then setclipboard(str) elseif toclipboard then toclipboard(str) end
    print("OpenViz: Copied " .. #entries .. " audio log(s)")
end

local function makeSpyBB(adornee)
    local bb = Instance.new("BillboardGui", spyScreenGui)
    bb.Size, bb.StudsOffset, bb.AlwaysOnTop, bb.Adornee = UDim2.new(0,210,0,90), Vector3.new(0,2.5,0), true, adornee
    bb.Active = true
    local m = Instance.new("Frame", bb)
    m.Size, m.BackgroundColor3, m.BorderColor3, m.BorderSizePixel, m.BackgroundTransparency =
        UDim2.new(1,0,1,-15), Color3.fromRGB(20,20,25), Color3.fromRGB(90,160,255), 1, 0.1
    m.Active = true
    local pad = Instance.new("UIPadding", m)
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0,8), UDim.new(0,8)
    pad.PaddingTop,  pad.PaddingBottom = UDim.new(0,5), UDim.new(0,5)
    local nameLbl = Instance.new("TextLabel", m)
    nameLbl.Size, nameLbl.BackgroundTransparency, nameLbl.Font, nameLbl.TextColor3,
    nameLbl.TextSize, nameLbl.Text, nameLbl.TextTruncate =
        UDim2.new(1,0,0,20), 1, Enum.Font.GothamBold, Color3.fromRGB(90,160,255),
        14, "Loading...", Enum.TextTruncate.AtEnd
    local idRow = Instance.new("Frame", m)
    idRow.Size, idRow.Position, idRow.BackgroundTransparency =
        UDim2.new(1,0,0,24), UDim2.new(0,0,0,22), 1
    local idLbl = Instance.new("TextLabel", idRow)
    idLbl.Size, idLbl.BackgroundTransparency, idLbl.Font, idLbl.TextColor3,
    idLbl.TextSize, idLbl.TextXAlignment, idLbl.Text =
        UDim2.new(1,-75,1,0), 1, Enum.Font.Gotham, Color3.fromRGB(200,200,200),
        12, Enum.TextXAlignment.Left, "ID: ..."
    local copyBtn = Instance.new("TextButton", idRow)
    copyBtn.Name, copyBtn.Size, copyBtn.Position, copyBtn.BackgroundColor3,
    copyBtn.BorderSizePixel, copyBtn.Font, copyBtn.TextColor3,
    copyBtn.TextSize, copyBtn.Text, copyBtn.Active, copyBtn.Selectable =
        "CopyBtn", UDim2.new(0,70,1,0), UDim2.new(1,-70,0,0), Color3.fromRGB(40,40,50),
        0, Enum.Font.GothamBold, Color3.new(1,1,1), 10, "COPY ID", true, true
    local statLbl = Instance.new("TextLabel", m)
    statLbl.Name, statLbl.Size, statLbl.Position, statLbl.BackgroundTransparency,
    statLbl.Font, statLbl.TextColor3, statLbl.TextSize, statLbl.Text =
        "Stats", UDim2.new(1,0,0,18), UDim2.new(0,0,0,48), 1,
        Enum.Font.GothamMedium, Color3.fromRGB(150,150,150), 11, "0:00 / 0:00 ~~ L: 0"
    return bb, nameLbl, idLbl, statLbl, copyBtn
end

AudioControlsSec:toggle({name="Toggle Audio Spy", def=false, callback=function(b)
    audioSpyEnabled = b
    if not b then
        for _,d in pairs(spyTracked) do if d.bb then d.bb:Destroy() end end
        table.clear(spyTracked)
    end
end})

AudioControlsSec:button({name="Refresh Audio List", callback=function()
    local entries = refreshAudioList()
    print("OpenViz: Audio list refreshed -> " .. #entries .. " found")
end})

AudioControlsSec:button({name="Copy Id's in Server", callback=function()
    copyAudioEntries(refreshAudioList())
end})

AudioControlsSec:button({name="Copy Full Audio List", callback=function()
    copyAudioEntries(refreshAudioList())
end})

AudioControlsSec:toggle({name="Auto Refresh List", def=true, callback=function(b)
    audioListAutoRefresh = b
end})

MiscSec:button({name="Panic Cleanup", callback=function()
    stopVisualizer()
    antiFlingEnabled = false
    stealToolsEnabled = false
    audioSpyEnabled = false
    dupeRunning = false

    for _, d in pairs(spyTracked) do
        if d.bb then d.bb:Destroy() end
    end
    table.clear(spyTracked)

    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            workspace.CurrentCamera.CameraSubject = hum
        end
    end

    workspace.Gravity = 196.2
    print("OpenViz: Cleanup complete")
end})

task.spawn(function()
    while task.wait(1.5) do
        if audioListAutoRefresh then
            refreshAudioList()
        end
    end
end)

-- Audio Spy heartbeat
RunService.Heartbeat:Connect(function()
    if not audioSpyEnabled or not player.Character then return end
    local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local activePlrs = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (myRoot.Position - hrp.Position).Magnitude <= SPY_RANGE then
                local obj, id, parentPart = findValidAudio(p.Character)
                if id then
                    activePlrs[p] = true
                    if not spyTracked[p] then
                        local bb, nLbl, iLbl, sLbl, btn = makeSpyBB(parentPart or hrp)
                        spyTracked[p] = {bb=bb, nLbl=nLbl, iLbl=iLbl, sLbl=sLbl, fetch=0, cur=0}
                        btn.MouseButton1Click:Connect(function()
                            local s = tostring(spyTracked[p].cur)
                            if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end
                            btn.Text = "COPIED!" btn.BackgroundColor3 = Color3.fromRGB(90,160,255)
                            task.delay(1, function()
                                pcall(function() btn.Text="COPY ID" btn.BackgroundColor3=Color3.fromRGB(40,40,50) end)
                            end)
                        end)
                    end
                    local d = spyTracked[p]
                    if d then
                        d.cur = id
                        d.bb.Adornee = parentPart or hrp
                        if d.fetch ~= id then
                            d.fetch = id d.nLbl.Text = "Fetching..."
                            task.spawn(function()
                                local nm = getName(id)
                                if d.fetch == id and d.bb.Parent then d.nLbl.Text = nm end
                            end)
                        end
                        d.iLbl.Text = "ID: "..id
                        local loudness = (obj:IsA("Sound") and obj.PlaybackLoudness) or 0
                        local curT = (obj:IsA("Sound") and obj.TimePosition)   or 0
                        local maxT = (obj:IsA("Sound") and obj.TimeLength)      or 0
                        d.sLbl.Text = fmtTime(curT).." / "..fmtTime(maxT).." ~~ L: "..math.floor(loudness)
                    end
                end
            end
        end
    end
    for p, d in pairs(spyTracked) do
        if not activePlrs[p] then if d.bb then d.bb:Destroy() end spyTracked[p] = nil end
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if spyTracked[p] then spyTracked[p].bb:Destroy() spyTracked[p] = nil end
end)

-- Open the visualizer tab by default
MainTab:openpage()
finishLoadingBar("Ready")

player.CharacterAdded:Connect(function(char)
    character = char
    targetPlayer = player
    stopVisualizer()
end)

-- Emote keybinds (only active while R6 Clone is running)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not orbiting or not activePreset.r6Clone then return end
    if input.KeyCode == Enum.KeyCode.E then activeEmote="Dance2";   emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.T then activeEmote="Pharaoh";  emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.Y then activeEmote="Vibe";     emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.U then activeEmote="Robot";    emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.R then activeEmote="ChillSway";emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.F then activeEmote="HeadPlay"; emoteStartTime=tick()
    elseif input.KeyCode==Enum.KeyCode.G then activeEmote="StepTouch";emoteStartTime=tick()
    end
end)

-- Anti Fling loop
task.spawn(function()
    while task.wait(0.3) do
        if antiFlingEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.Massless = true
                        end
                    end
                end
            end
        end
    end
end)

-- Steal Tools loop
task.spawn(function()
    while task.wait(0.1) do
        if stealToolsEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
            for _, j in ipairs(workspace:GetChildren()) do
                if j:IsA("Tool") then
                    player.Character.Humanoid:EquipTool(j)
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not orbiting or not player.Character then return end

    -- Stop if any tool escaped to backpack
    local lostTool = false
    for tool, _ in pairs(tracked) do
        if not tool.Parent or tool.Parent == player.Backpack then
            lostTool = true; break
        end
    end
    if lostTool then stopVisualizer(); print("boi a tool gone so i stop :heart:"); return end

    local tChar = (targetPlayer and targetPlayer.Parent) and targetPlayer.Character or player.Character
    local hrp   = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not hrp or (tChar:FindFirstChild("Humanoid") and tChar.Humanoid.Health <= 0) then return end

    local t = tick() - orbitStartTime

    -- Audio visualizer radius boost
    if audioVisualizerEnabled then
        local loudness = getMaxLoudness()
        local activeMaxBoost = maxRadiusBoost * visualizerSensitivity
        currentRadiusBoost = currentRadiusBoost
            + ((loudness > loudnessThreshold
                and math.min((loudness - loudnessThreshold) / 450, 1) * activeMaxBoost
                or 0)
               - currentRadiusBoost) * smoothingFactor
    else
        currentRadiusBoost = 0
    end

    local headSpin, headTilt, torsoTwist, rArmPitch, rArmRoll, lArmPitch, lArmRoll = 0, 0, 0, 0, 0, 0, 0
    local rLegPitch, lLegPitch, extraBob, extraY = 0, 0, 0, 0
    local headX, headY, headZ, torsoPitch, torsoRoll, rLegRoll, lLegRoll = 0, 0, 0, 0, 0, 0, 0
    local isMoving, swing, bob = false, 0, 0

    if (activePreset.r6Clone or activePreset.wheelClone) and targetPlayer == player then
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new()
        local manualInput = false

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector;  manualInput=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector;  manualInput=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector; manualInput=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector; manualInput=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then manualInput=true end

        if manualInput then activeEmote=nil; timeIdle=0 else timeIdle=timeIdle+dt end

        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        if moveDir.Magnitude > 0.01 then
            moveDir = moveDir.Unit
            cloneLook = cloneLook:Lerp(moveDir, 15*dt)
        end

        local targetSpeed = moveDir * (8 * currentSpeed)
        cloneVel = Vector3.new(
            cloneVel.X + (targetSpeed.X - cloneVel.X) * 15 * dt,
            cloneVel.Y - workspace.Gravity * dt,
            cloneVel.Z + (targetSpeed.Z - cloneVel.Z) * 15 * dt)

        if activePreset.wheelClone then
            local forwardSpeed = Vector3.new(cloneVel.X, 0, cloneVel.Z):Dot(cloneLook)
            wheelRollAngle = wheelRollAngle - (forwardSpeed * dt / math.max(0.5, currentSize))
        end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {character}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then table.insert(filterList, p.Character) end
        end
        for tool, _ in pairs(tracked) do table.insert(filterList, tool) end
        rayParams.FilterDescendantsInstances = filterList

        cloneOnGround = false
        local verticalOffset = activePreset.wheelClone and math.max(1, currentSize) or 4
        local ray = workspace:Raycast(clonePos + Vector3.new(0,3,0), Vector3.new(0,-10,0), rayParams)
        if ray then
            local targetY = ray.Position.Y + verticalOffset
            if cloneVel.Y <= 0.1 and clonePos.Y <= targetY+1 then
                clonePos = Vector3.new(clonePos.X, targetY, clonePos.Z)
                cloneVel = Vector3.new(cloneVel.X, 0, cloneVel.Z)
                cloneOnGround = true
            end
        end

        if cloneOnGround and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            cloneVel = Vector3.new(cloneVel.X, 50, cloneVel.Z)
            cloneOnGround = false
            clonePos += Vector3.new(0, 0.5, 0)
        end

        clonePos += cloneVel * dt
        camPart.CFrame = CFrame.new(clonePos + Vector3.new(0, 3, 0))

        isMoving = Vector3.new(cloneVel.X, 0, cloneVel.Z).Magnitude > 2

        if not cloneOnGround then swing = 0.5
        elseif isMoving then
            swing = math.sin(t*10) * 0.8
            bob   = math.abs(math.sin(t*10)) * 0.1
        else
            swing = math.sin(t*2) * 0.08
            bob   = math.sin(t*2) * 0.05
        end

        -- Emote math
        if activeEmote == "Dance2" then
            local eTime = t - emoteStartTime
            local sway = math.sin(eTime*4)
            torsoRoll = sway*0.15; extraBob = math.abs(math.sin(eTime*8))*0.2
            rArmPitch = math.rad(90); rArmRoll = math.rad(45)+sway*0.6
            lArmPitch = math.rad(90); lArmRoll = math.rad(-45)+sway*0.6
            rLegRoll  = sway*0.1;    lLegRoll = sway*0.1; headTilt = -sway*0.1
        elseif activeEmote == "ChillSway" then
            local eTime = t - emoteStartTime
            local sway = math.sin(eTime*2)
            torsoRoll = sway*0.1; headTilt = -sway*0.05
            rArmPitch = math.rad(10)-sway*0.1; rArmRoll = math.rad(-5)
            lArmPitch = math.rad(10)+sway*0.1; lArmRoll = math.rad(5)
            rLegPitch = sway*0.05; lLegPitch = -sway*0.05
        elseif activeEmote == "Vibe" then
            local eTime = t - emoteStartTime
            local beat = math.sin(eTime*5)
            headTilt = math.rad(15)+beat*0.1; extraBob = math.abs(math.sin(eTime*5))*0.15
            rArmPitch = math.rad(20); rArmRoll = math.rad(-15)
            lArmPitch = math.rad(20); lArmRoll = math.rad(15)
            torsoRoll = beat*0.05
        elseif activeEmote == "StepTouch" then
            local eTime = t - emoteStartTime
            local step = math.sin(eTime*3)
            torsoTwist = step*0.2; extraBob = math.abs(math.sin(eTime*6))*0.2
            rArmPitch = math.rad(45)+math.sin(eTime*6)*0.2; rArmRoll = math.rad(-20)
            lArmPitch = math.rad(45)+math.sin(eTime*6)*0.2; lArmRoll = math.rad(20)
        elseif activeEmote == "Pharaoh" then
            local eTime = t - emoteStartTime
            local wave = math.sin(eTime*4)
            torsoTwist = math.rad(40); headSpin = math.rad(-40)
            extraBob = math.abs(math.sin(eTime*8))*0.2
            rArmPitch = math.rad(45)+wave*math.rad(45); rArmRoll = math.rad(45)
            lArmPitch = math.rad(45)-wave*math.rad(45); lArmRoll = math.rad(-45)
        elseif activeEmote == "Robot" then
            local eTime = t - emoteStartTime
            local snap = math.floor(eTime*5)/5
            headSpin  = math.sin(snap*3)*0.6
            rArmPitch = math.rad(90)+math.sin(snap*5)*0.5
            lArmPitch = math.rad(90)+math.cos(snap*5)*0.5
            torsoTwist = math.cos(snap*2)*0.3
        elseif activeEmote == "HeadPlay" then
            local eTime = t - emoteStartTime
            local cycle = eTime % 5
            if cycle < 1 then
                rArmPitch = math.rad(150)*cycle; rArmRoll = math.rad(-20)*cycle
            elseif cycle < 2.5 then
                rArmPitch = math.rad(150)+math.sin(t*15)*0.1
                headX = 1.2; headY = -1.2+math.sin(t*15)*0.3; headZ = -0.5
            elseif cycle < 3.5 then
                local tTime = cycle-2.5
                rArmPitch = math.rad(150)-math.rad(150)*tTime
                headX = 1.2*(1-tTime); headY = 4*math.sin(tTime*math.pi)
                headZ = -0.5*(1-tTime); headSpin = tTime*math.pi*6
            else
                rArmPitch = math.rad(135); rArmRoll = math.rad(45)
                lArmPitch = math.rad(135); lArmRoll = math.rad(-45)
                headY = math.sin(t*5)*0.1
            end
        elseif activeEmote == nil and timeIdle > 10 then
            local p = timeIdle - 10
            if p < 5 then
                headSpin = math.sin(p*2)*0.6
                if p > 1 and p < 4 then rArmPitch = math.rad(135)+math.sin(p*12)*0.4; rArmRoll = math.rad(-20) end
            else
                timeIdle = 0
            end
        end
    end

    if activePreset and activePreset.custom and activePreset.Type == "NodeGraph" then
        local nodeMap  = activePreset._nodeMap
        local tools    = activePreset.Tools or {}
        local numSlots = #tools
        local audioPulse = currentRadiusBoost

        local toolSlots = {}
        for i, toolEntry in ipairs(tools) do toolSlots[i] = toolEntry end

        local memo = {}

        for tool, data in pairs(tracked) do
            local h = data.handle
            if not (h and h.Parent) then
                untrackAndDestroy(tool)
            else
                safePcall(function()
                    h.Massless = true
                    h.CanCollide = false
                    if netlessEnabled and data.netlessAllowed then
                        h.AssemblyLinearVelocity = netlessVector
                    end
                end)

                local tPos, tRot

                if numSlots > 0 then
                    local slotIdx  = ((data.index - 1) % numSlots) + 1
                    local slotTool = toolSlots[slotIdx]
                    local boomCF   = getNodeWorldCF(slotTool.ID, t, nodeMap, memo, hrp.CFrame, audioPulse)
                    local finalPos = boomCF.Position + Vector3.new(0, currentHeight, 0)
                    tPos = finalPos
                    tRot = CFrame.new(finalPos) * boomCF.Rotation
                else
                    tPos = hrp.Position + Vector3.new(0, currentHeight + 3, 0)
                    tRot = hrp.CFrame
                end

                safePcall(function()
                    data.alignPos.Position = tPos
                    data.alignRot.CFrame   = tRot
                end)
            end
        end

    else
        for tool, data in pairs(tracked) do
            local h = data.handle
            if not (h and h.Parent) then
                untrackAndDestroy(tool)
            else
                safePcall(function()
                    h.Massless = true
                    h.CanCollide = false
                    if netlessEnabled and data.netlessAllowed then
                        h.AssemblyLinearVelocity = netlessVector
                    end
                end)

                local tPos, tRot

                if activePreset.r6Clone then
                    local map = data.index % 7
                    if map == 0 then map = 7 end
                    local rootRot      = CFrame.lookAt(clonePos, clonePos + cloneLook)
                    local upperBodyRot = CFrame.Angles(torsoPitch, torsoTwist, torsoRoll)
                    local offset = CFrame.new()
                    if map==1 then offset = CFrame.new(0,0.25+bob+extraBob+extraY,0)*upperBodyRot*CFrame.Angles(0,0,math.rad(180))
                    elseif map==2 then offset = CFrame.new(0,-0.75+bob+extraBob+extraY,0)*upperBodyRot
                    elseif map==3 then offset = CFrame.new(headX,2.2+bob+extraBob+extraY+headY,headZ)*upperBodyRot*CFrame.Angles(headTilt,headSpin,0)
                    elseif map==4 then offset = upperBodyRot*CFrame.new(1.8,1+bob+extraBob+extraY,0)*CFrame.Angles(swing+rArmPitch,0,rArmRoll)*CFrame.new(0,-1.2,0)*CFrame.Angles(0,0,math.rad(90))
                    elseif map==5 then offset = upperBodyRot*CFrame.new(-1.8,1+bob+extraBob+extraY,0)*CFrame.Angles(-swing+lArmPitch,0,lArmRoll)*CFrame.new(0,-1.2,0)*CFrame.Angles(0,0,math.rad(-90))
                    elseif map==6 then offset = CFrame.new(0.6,-1.5,0)*CFrame.Angles((isMoving and -swing or -swing*0.5)+rLegPitch,0,rLegRoll)*CFrame.new(0,-1.2,0)*CFrame.Angles(0,0,math.rad(90))
                    elseif map==7 then offset = CFrame.new(-0.6,-1.5,0)*CFrame.Angles((isMoving and swing or swing*0.5)+lLegPitch,0,lLegRoll)*CFrame.new(0,-1.2,0)*CFrame.Angles(0,0,math.rad(-90))
                    end
                    local finalCFrame = rootRot * offset
                    tPos = finalCFrame.Position
                    tRot = finalCFrame

                elseif activePreset.wheelClone then
                    local total = math.max(1, countTracked())
                    local angle = (math.pi*2/total) * (data.index-1)
                    local rootRot   = CFrame.lookAt(clonePos, clonePos+cloneLook)
                                    * CFrame.Angles(0, 0, isMoving and 0 or (math.sin(t*1.5)*0.08))
                    local centerPos = rootRot * CFrame.new(0, (isMoving and 0 or math.sin(t*3)*0.1)+0.5, 0)
                    local rollCFrame = centerPos * CFrame.Angles(wheelRollAngle, 0, 0)
                    local finalCFrame = rollCFrame * CFrame.Angles(angle,0,0)
                                      * CFrame.new(0, currentSize, 0)
                                      * CFrame.Angles(0, math.rad(90), 0)
                    tPos = finalCFrame.Position
                    tRot = finalCFrame

                else
                    tPos = computeTargetPos(data.index, t, hrp)
                    local tLP = getTargetLookPos(data.index, hrp)
                    if activePreset.wingsV2 then
                        local baseVal = activePreset.radius or 5
                        if baseVal == 0 then baseVal = 1 end
                        local radiusMultiplier = 1 + (currentRadiusBoost / baseVal)
                        local radius = currentSize * radiusMultiplier
                        if data.index == 1 or countTracked() <= 1 then
                            tRot = CFrame.lookAt(tPos, hrp.Position)
                        else
                            local total = countTracked()
                            local side, idx, _, sideTotal = getWingSideInfo(data.index, total)
                            local prevIdx = (idx > 1) and (data.index - 2) or 1
                            local nextIdx = (idx < sideTotal) and (data.index + 2) or data.index
                            local prevPos = hrp.CFrame:PointToWorldSpace(getWingLocalPos(prevIdx, total, radius, t))
                            local nextPos = hrp.CFrame:PointToWorldSpace(getWingLocalPos(nextIdx, total, radius, t))
                            local tangent = nextPos - prevPos

                            if tangent.Magnitude < 0.01 then
                                tangent = hrp.CFrame.RightVector * side
                            end

                            tRot = CFrame.lookAt(tPos, tPos + tangent.Unit)
                        end
                    elseif activePreset.pennyRoll then
                        local nextPos = computeTargetPos(data.index + 1, t + 0.03, hrp)
                        local tangent = nextPos - tPos
                        if tangent.Magnitude > 0.01 then
                            tRot = CFrame.lookAt(tPos, tPos + tangent.Unit) * CFrame.Angles(0, 0, t * currentSpeed * 4)
                        else
                            tRot = CFrame.new(tPos, hrp.Position)
                        end
                    elseif activePreset.wobbly then
                        local nextPos = computeTargetPos(data.index + 1, t + 0.03, hrp)
                        local tangent = nextPos - tPos
                        if tangent.Magnitude > 0.01 then
                            tRot = CFrame.lookAt(tPos, tPos + tangent.Unit)
                                * CFrame.Angles(
                                    math.sin(t*currentSpeed*2.8 + data.index) * 0.25,
                                    0,
                                    0
                                )
                        else
                            tRot = CFrame.new(tPos, hrp.Position)
                        end
                    elseif activePreset.layered then
                        local layer = math.floor((data.index-1)/8)
                        local layerHeight = currentHeight + (layer*4)
                        local centerPos = hrp.CFrame:PointToWorldSpace(Vector3.new(0, layerHeight, 0))
                        tRot = CFrame.lookAt(tPos, centerPos)
                    else
                        tRot = tLP and CFrame.new(tPos, tLP) or CFrame.new(tPos, hrp.Position)
                    end
                    if activePreset.rolling and not lookLocked and not activePreset.wingsV2 then
                        tRot = CFrame.new(tPos, hrp.Position)
                             * CFrame.Angles((tPos - hrp.Position).Magnitude * 0.85, 0, 0)
                    end
                    if activePreset.knot or activePreset.torusKnot or activePreset.lissajous then
                        tRot = tRot * CFrame.Angles(data.index*0.5, data.index*0.3, data.index*0.7)
                    end
                end

                safePcall(function()
                    data.alignPos.Position = tPos
                    data.alignRot.CFrame   = tRot
                end)
            end
        end
    end
end)
