local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local Notification

local function OpenVizNotify(title, text, duration)
    if not Notification then
        pcall(function()
            Notification = loadstring(game:HttpGet("https://api.irisapp.ca/Scripts/IrisBetterNotifications.lua"))()
        end)
    end

    if Notification and Notification.Notify then
        local shown = pcall(function()
            Notification.Notify(title or "OpenViz", text or "", "rbxassetid://91446372126057", {
                Duration = duration or 5,
                Main = {
                    Rounding = true,
                },
            })
        end)
        if shown then return end
    end

    local shown = false
    for _ = 1, 5 do
        shown = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title or "OpenViz",
                Text = text or "",
                Duration = duration or 5,
            })
        end)
        if shown then break end
        task.wait(0.4)
    end
    if not shown then
        print((title or "OpenViz") .. ": " .. (text or ""))
    end
end

local WHITELIST_URL = "https://raw.githubusercontent.com/12321h3uu91hrfoegrfq/openskid/refs/heads/main/whitelist.json"
local whitelistAllowed = false
local isOpenVizAdmin = false
local whitelistLoaded = false
local whitelistData = nil
local whitelistError = nil

local function userIdInList(list, userId)
    if type(list) ~= "table" then return false end
    userId = tonumber(userId)

    for key, listedId in pairs(list) do
        if tonumber(listedId) == userId or tonumber(key) == userId then
            return true
        end
        if tostring(key) == tostring(userId) and listedId == true then
            return true
        end
    end

    return false
end

local function loadWhitelist()
    local urls = {
        WHITELIST_URL .. "?cacheBust=" .. tostring(math.floor(tick())),
        WHITELIST_URL,
        "https://raw.githubusercontent.com/12321h3uu91hrfoegrfq/openskid/main/whitelist.json?cacheBust=" .. tostring(math.floor(tick())),
        "https://raw.githubusercontent.com/12321h3uu91hrfoegrfq/openskid/main/whitelist.json",
    }

    for _, url in ipairs(urls) do
        local fetchOk, body = pcall(function()
            return game:HttpGet(url)
        end)

        if fetchOk and type(body) == "string" and body ~= "" then
            local decodeOk, decoded = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            if decodeOk and type(decoded) == "table" then
                return true, decoded
            end
            whitelistError = "JSON decode failed"
        else
            whitelistError = tostring(body)
        end
    end

    return false, nil
end

whitelistLoaded, whitelistData = loadWhitelist()

if whitelistLoaded and whitelistData then
    if userIdInList(whitelistData.allowed, player.UserId) then
        whitelistAllowed = true
    elseif whitelistData[tostring(player.UserId)] == true or whitelistData[player.UserId] == true then
        whitelistAllowed = true
    end
    isOpenVizAdmin = userIdInList(whitelistData.admins, player.UserId)
end

if not whitelistAllowed then
    player:Kick("OpenViz: You are not whitelisted. UserId: " .. tostring(player.UserId))
    return
end

OpenVizNotify("OpenViz", "You are whitelisted! Userid: " .. tostring(player.UserId) .. " | Admin: " .. tostring(isOpenVizAdmin), 6)

print("\n \n Wlcme t o Openviz brah :heart: \n Press P to access Preset Maker!!!!!!!!!!! \n \n")
--[[
  Yo  ~ 1954real
             tuff
]]
-- preset maker, press "P"
loadstring(game:HttpGet("https://raw.githubusercontent.com/3-7x/Preset-Maker/refs/heads/main/pm"))()
-- 
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
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

local currentSpeed = 2
local currentSize = 5
local currentHeight = 3
local netlessEnabled = true
local netlessVector = Vector3.new(0,0,-31)
local sessionSeed = math.random(1, 100000)

local audioId = nil
local dupeTargetAmount = 5
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
    ["Random"]        = {radius=5,   speed=0.5, randommish=true},
    ["Infinity"]      = {radius=4,   speed=0.5, infinity=true},
    ["X Ring"]        = {radius=6,   speed=0.5, xRing=true},
    ["Wings"]         = {radius=1,   speed=0.5, wingsV2=true},
    ["R6 Clone"]      = {r6Clone=true},
    ["Wheel"]         = {wheelClone=true},
    ["Trefoil"]       = {radius=4,   speed=0.5, knot=true},
    ["Wavy Circle"]   = {radius=5,   speed=0.5, wavy=true},
    ["Wobbly"]        = {radius=5,   speed=0.7, wobbly=true},
    ["Wobbly Orbit"]  = {radius=5,   speed=0.85, wobblyOrbit=true},
    ["Back Infinity"] = {radius=4,   speed=0.52, backInfinity=true},
    ["Torus Knot"]    = {radius=3,   speed=0.5, torusKnot=true},
    ["Lissaj Curve"]  = {radius=4,   speed=0.5, lissajous=true},
    ["Line"]          = {radius=2,   speed=3,   line=true},
    ["Heart"]         = {radius=4,   speed=1.5, heart=true},
    ["dih"]           = {radius=1.2, speed=0,   theThing=true},
    ["Layered"]       = {radius=6,   speed=1,   layered=true},
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

local function isOpenVizAdminUser(userId)
    return whitelistLoaded and whitelistData and userIdInList(whitelistData.admins, tonumber(userId))
end

local function getOpenVizAdminName(userId)
    local p = Players:GetPlayerByUserId(tonumber(userId) or 0)
    return p and p.Name or ("UserId " .. tostring(userId))
end

local function openVizAdminTargetMatches(target, issuerUserId)
    target = string.lower(tostring(target or ""))
    if target == "" then return false end
    if target == "all" then return true end
    if target == "others" then return player.UserId ~= issuerUserId end
    if tonumber(target) == player.UserId then return true end

    local myName = string.lower(player.Name or "")
    local myDisplay = string.lower(player.DisplayName or "")
    return string.sub(myName, 1, #target) == target
        or string.sub(myDisplay, 1, #target) == target
end

local function runOpenVizAdminCommand(action, issuerUserId, target)
    issuerUserId = tonumber(issuerUserId)
    if not issuerUserId or not isOpenVizAdminUser(issuerUserId) then return end
    if not openVizAdminTargetMatches(target, issuerUserId) then return end

    action = string.lower(tostring(action or ""))
    local issuerName = getOpenVizAdminName(issuerUserId)
    if action == "stop" or action == "off" then
        stopVisualizer()
        OpenVizNotify("OpenViz Admin", "Visualizer stopped by " .. issuerName, 4)
    elseif action == "reset" or action == "respawn" then
        stopVisualizer()
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            hum.Health = 0
        elseif char then
            char:BreakJoints()
        end
        OpenVizNotify("OpenViz Admin", "Reset by " .. issuerName, 4)
    elseif action == "kick" then
        player:Kick("OpenViz: Kicked by admin " .. issuerName)
    end
end

local lastOpenVizCommandId = nil

local function loadOpenVizCommandData()
    local loaded, data = loadWhitelist()
    if loaded and data then
        whitelistLoaded = loaded
        whitelistData = data
        isOpenVizAdmin = userIdInList(whitelistData.admins, player.UserId)
        return data.command
    end
    return nil
end

task.spawn(function()
    while task.wait(4) do
        local command = loadOpenVizCommandData()
        if type(command) == "table" then
            local commandId = command.id or command.Id or command.ID
            if commandId and commandId ~= lastOpenVizCommandId then
                lastOpenVizCommandId = commandId
                runOpenVizAdminCommand(command.action, command.issuer or command.issuerUserId, command.target or "others")
            end
        end
    end
end)

local function sendOpenVizAdminCommand(action, target)
    local commandJson = HttpService:JSONEncode({
        id = tostring(player.UserId) .. "-" .. tostring(os.time()),
        issuer = player.UserId,
        action = tostring(action),
        target = tostring(target or "others"),
    })

    if setclipboard then setclipboard(commandJson) elseif toclipboard then toclipboard(commandJson) end
    OpenVizNotify("OpenViz Admin", "Command copied. Paste it as whitelist.json command.", 6)
    print('OpenViz Admin: Paste this into whitelist.json as "command": ' .. commandJson)
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

    elseif preset.randommish then
        local seed = (i * 82.55) + sessionSeed
        local angle = (t * currentSpeed) + (math.sin(seed) * math.pi * 2)
        local y = currentHeight + (math.cos(seed * 1.3) * 2.0)
        local r = currentSize * radiusMultiplier
        return hrp.CFrame:PointToWorldSpace(Vector3.new(r * math.cos(angle), y, r * math.sin(angle)))

    elseif preset.infinity then
        local radius = currentSize * radiusMultiplier
        local loopAngle = (math.pi * 2 / total) * (i - 1) + (t * currentSpeed)
        return hrp.CFrame:PointToWorldSpace(
            Vector3.new(radius * math.sin(loopAngle), currentHeight,
                        radius * 0.7 * math.sin(loopAngle) * math.cos(loopAngle)))

    elseif preset.xRing then
        local radius = currentSize * radiusMultiplier
        local half = math.ceil(total/2)
        local ringIndex = (i > half) and (i - half) or i
        local ringTotal = (i > half) and (total - half) or half
        local angle = (t * currentSpeed) + ((ringIndex-1)/ringTotal) * math.pi * 2
        local tilt = (i > half) and -math.rad(12.5) or math.rad(12.5)
        return hrp.CFrame:PointToWorldSpace(
            (CFrame.Angles(tilt, 0, 0) * Vector3.new(
                math.cos(angle)*radius, 0, math.sin(angle)*radius))
            + Vector3.new(0, currentHeight, 0))

    elseif preset.wingsV2 then
        local leftCount = math.ceil(total / 2)
        local rightCount = total - leftCount
        local isRight = i > leftCount
        local side = isRight and 1 or -1
        local sideIndex = isRight and (i - leftCount) or i
        local sideTotal = math.max(1, isRight and rightCount or leftCount)
        local progress = (sideIndex - 1) / math.max(1, sideTotal - 1)
        local featherCurve = progress ^ 0.82
        local flap = math.sin((t * currentSpeed * 1.7) - progress * 2.35)
        local ripple = math.sin((t * currentSpeed * 3.2) + sideIndex * 0.55)

        local rootX = 1.15 * side
        local span = math.max(3.2, currentSize * 1.35)
        local sweep = math.sin(progress * math.pi) * math.max(0.8, currentSize * 0.28)
        local x = rootX + side * (featherCurve * span + sweep)
        local y = currentHeight
            + 0.35
            + math.sin(progress * math.pi) * math.max(1.6, currentSize * 0.42)
            - (progress ^ 1.7) * math.max(0.45, currentSize * 0.16)
            + flap * (0.28 + progress * 0.55)
            + ripple * 0.08
        local z = 1.35
            + (progress ^ 1.25) * math.max(1.2, currentSize * 0.22)
            - math.sin(progress * math.pi) * 0.45

        return hrp.CFrame:PointToWorldSpace(Vector3.new(x, y, z))

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

    elseif preset.wobblyOrbit then
        local radius = currentSize * radiusMultiplier
        local progress = (i - 1) / math.max(1, total)
        local angle = progress * math.pi * 2 + (t * currentSpeed)
        local tiltX = math.rad(38 + math.sin(t * currentSpeed * 1.2) * 18)
        local tiltZ = math.rad(math.cos(t * currentSpeed * 1.5) * 22)
        local spin = CFrame.Angles(
            t * currentSpeed * 0.35,
            t * currentSpeed * 0.95,
            t * currentSpeed * 0.25
        )
        local localPos = (spin
            * CFrame.Angles(tiltX, 0, tiltZ)
            * CFrame.new(
                math.cos(angle) * radius,
                currentHeight + math.sin(angle * 3 + t * currentSpeed * 2.2) * currentSize * 0.18,
                math.sin(angle) * radius
            )
        ).Position
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

    elseif preset.torusKnot then
        local radius = currentSize * radiusMultiplier * 0.5
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        local p, q = 3, 4
        local r_torus = math.cos(q*angle) + 2
        local lx = r_torus * math.cos(p*angle)
        local lz = r_torus * math.sin(p*angle)
        local ly = -math.sin(q*angle)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(lx*radius, currentHeight+ly*radius, lz*radius))

    elseif preset.lissajous then
        local radius = currentSize * radiusMultiplier
        local angle = (math.pi*2/total)*(i-1) + (t*currentSpeed)
        return hrp.CFrame:PointToWorldSpace(Vector3.new(
            math.sin(3*angle)*radius,
            currentHeight + math.sin(4*angle)*radius,
            math.cos(5*angle)*radius))

    elseif preset.line then
        local spacing = (currentSize*0.4) + (audioVisualizerEnabled and (currentRadiusBoost*0.2) or 0)
        local centerOffset = (i - (total/2) - 0.5) * spacing
        local waveVal = math.sin((t*currentSpeed) + (i*0.5)) * 1.5
        return hrp.CFrame:PointToWorldSpace(Vector3.new(centerOffset, waveVal+currentHeight, 0))

    elseif preset.heart then
        local angle = (i/total)*math.pi*2 + (t*currentSpeed*0.5)
        local x = 16 * math.pow(math.sin(angle), 3)
        local y = 13*math.cos(angle) - 5*math.cos(2*angle) - 2*math.cos(3*angle) - math.cos(4*angle)
        local scale = currentSize * 0.05 * radiusMultiplier
        return hrp.CFrame:PointToWorldSpace(Vector3.new(x*scale, y*scale+currentHeight, 0))

    elseif preset.theThing then
        local spacing = currentSize + (audioVisualizerEnabled and (currentRadiusBoost*0.2) or 0)
        local totalDist = 0.03 + (i*spacing)
        local yOffset = (i==1) and (currentHeight-0.7) or currentHeight
        return hrp.Position + (hrp.CFrame.LookVector*totalDist) + Vector3.new(0, yOffset, 0)

    elseif preset.layered then
        local layer = math.floor((i-1)/8)
        local indexInLayer = (i-1)%8
        local toolsInThisLayer = math.min(8, total-(layer*8))
        local radius = currentSize * radiusMultiplier
        local angle = t*currentSpeed + ((2*math.pi/math.max(1,toolsInThisLayer))*indexInLayer)
        local layerHeight = currentHeight + (layer*4)
        return hrp.CFrame:PointToWorldSpace(
            Vector3.new(math.cos(angle)*radius, layerHeight, math.sin(angle)*radius))

    else
        local radius = currentSize * radiusMultiplier
        local angle = t*currentSpeed + i*0.5
        return hrp.Position + Vector3.new(
            math.cos(angle)*radius, currentHeight+i*0.25, math.sin(angle)*radius)
    end
end

local function getTargetLookPos(index, hrp)
    if lookLocked then return hrp.Position end
    if activePreset.wingsV2 or activePreset.theThing then
        return hrp.Position + hrp.CFrame.LookVector * 50
    end
    if activePreset.randommish then
        local seed = (index * 45.1) + sessionSeed
        return hrp.Position + Vector3.new(
            math.sin(seed)*50, math.cos(seed*0.5)*50, math.sin(seed*1.5)*50)
    end
    return nil
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()

local OpenVizGui = Library:create({
    Theme = Library.Themes.Serika
})

local MainTab = OpenVizGui:tab({
    Icon = "rbxassetid://6034996695",
    Name = "Visualizer"
})
local MiscTab = OpenVizGui:tab({
    Icon = "rbxassetid://6034509993",
    Name = "Misc"
})
local AdminTab = nil
if isOpenVizAdmin then
    AdminTab = OpenVizGui:tab({
        Icon = "rbxassetid://6034287518",
        Name = "Admin"
    })
end

local function sectionCompat(tab, sectionName)
    local compat = {}
    pcall(function()
        if tab.label then
            tab:label({Name = sectionName})
        end
    end)

    function compat:dropdown(cfg)
        local created
        local options = cfg.options or {}
        pcall(function()
            if tab.dropdown then
                created = tab:dropdown({
                    Name = cfg.name,
                    StartingText = cfg.def or cfg.name,
                    Items = options,
                    Callback = function(v)
                        if type(v) == "table" then v = v[2] or v[1] end
                        if cfg.callback then cfg.callback(v) end
                    end
                })
            end
        end)

        local state = {}
        function state:Refresh(newOptions)
            options = newOptions or options
            if created then
                pcall(function() if created.Refresh then created:Refresh(options) end end)
                pcall(function() if created.Update then created:Update(options) end end)
                pcall(function() if created.SetList then created:SetList(options) end end)
            end
        end
        function state:update(newOptions) self:Refresh(newOptions) end
        function state:Update(newOptions) self:Refresh(newOptions) end
        if cfg.oncreate then cfg.oncreate(state) end
        return state
    end

    function compat:button(cfg)
        local created
        pcall(function()
            if tab.button then
                created = tab:button({
                    Name = cfg.name,
                    Callback = cfg.callback or function() end
                })
            end
        end)
        return created
    end

    function compat:slider(cfg)
        local created
        pcall(function()
            if tab.slider then
                created = tab:slider({
                    Name = cfg.name,
                    Min = cfg.min or 0,
                    Max = cfg.max or 100,
                    Default = cfg.def or cfg.value,
                    Callback = function(v)
                        if cfg.callback then cfg.callback(v) end
                    end
                })
                if cfg.callback and (cfg.def ~= nil or cfg.value ~= nil) then
                    cfg.callback(cfg.def or cfg.value)
                end
            end
        end)
        return created
    end

    function compat:toggle(cfg)
        local state = cfg.def == true
        local created
        pcall(function()
            if tab.button then
                created = tab:button({
                    Name = cfg.name,
                    Callback = function()
                        state = not state
                        if cfg.callback then cfg.callback(state) end
                    end
                })
                if state and cfg.callback then cfg.callback(true) end
            end
        end)
        return created
    end

    function compat:textbox(cfg)
        local created
        pcall(function()
            if tab.textbox then
                created = tab:textbox({
                    Name = cfg.name,
                    Callback = function(v)
                        if cfg.callback then cfg.callback(v) end
                    end
                })
            end
        end)
        return created
    end

    return compat
end

local ControlsSec = sectionCompat(MainTab, "Controls")
local SettingsSec = sectionCompat(MainTab, "Settings")
local MiscSec     = sectionCompat(MiscTab, "Misc")
local AdminSec    = AdminTab and sectionCompat(AdminTab, "Remote Controls") or nil

if AdminSec then
    local adminTarget = "others"
    AdminSec:textbox({name="Target", def="others", callback=function(text)
        if text and text ~= "" then
            adminTarget = text
        else
            adminTarget = "others"
        end
    end})
    AdminSec:button({name="Copy Stop Command", callback=function()
        sendOpenVizAdminCommand("stop", adminTarget)
    end})
    AdminSec:button({name="Copy Reset Command", callback=function()
        sendOpenVizAdminCommand("reset", adminTarget)
    end})
end

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

SettingsSec:slider({name="Speed",  def=2,   max=20,  min=1,   rounding=true, callback=function(v) currentSpeed  = v*0.25 end})
SettingsSec:slider({name="Size",   def=5,   max=50,  min=1,   rounding=true, callback=function(v) currentSize   = v      end})
SettingsSec:slider({name="Height", def=3,   max=30,  min=-10, rounding=true, callback=function(v) currentHeight = v      end})
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

local function isBoomboxTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local lowerName = string.lower(tool.Name or "")
    return lowerName:find("boombox", 1, true) ~= nil
        or tool:FindFirstChild("PlayAudio", true) ~= nil
        or tool:FindFirstChild("Remote", true) ~= nil
end

local function collectBoomboxTools()
    local tools = {}
    local seen = {}
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if isBoomboxTool(tool) and not seen[tool] then
                seen[tool] = true
                table.insert(tools, tool)
            end
        end
    end

    scan(player.Character)
    scan(player:FindFirstChild("Backpack"))
    return tools
end

local function playBoomboxTool(tool, id)
    if not tool or not id then return false end
    local played = false
    local playAudio = tool:FindFirstChild("PlayAudio", true)
    if playAudio and playAudio:IsA("RemoteFunction") then
        played = pcall(function()
            playAudio:InvokeServer("PlayAudio", tostring(id), "1", "0", "0")
        end)
        if not played then
            played = pcall(function()
                playAudio:InvokeServer(id)
            end)
        end
    end

    if not played then
        local remote = tool:FindFirstChild("Remote", true)
        if remote then
            played = pcall(function()
                remote:FireServer("PlaySong", id)
            end)
        end
    end

    return played
end

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

ControlsSec:button({name = "Drop All Boomboxes", callback = function()
    local dropped = 0
    for _, tool in ipairs(collectBoomboxTools()) do
        pcall(function()
            local handle = tool:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.Massless = true
                handle.CanCollide = false
            end
            tool.Parent = workspace
            dropped += 1
        end)
    end
    print("OpenViz: Dropped " .. tostring(dropped) .. " boombox(es)")
end})

ControlsSec:button({name = "Sync Audio", callback = function()
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
                if isBoomboxTool(tool) then
                    pcall(function() tool.Parent = char end)
                end
            end
        end

        RunService.Heartbeat:Wait()

        local tools = {}
        for _, tool in ipairs(collectBoomboxTools()) do
            if tool.Parent == char then
                table.insert(tools, tool)
            end
        end

        local success = 0
        for _, tool in ipairs(tools) do
            task.spawn(function()
                if playBoomboxTool(tool, audioId) then
                    success += 1
                end
            end)
        end

        task.wait(0.15)
        print("OpenViz: Sync Audio sent to " .. tostring(success) .. "/" .. tostring(#tools) .. " boombox(es)")
    end)
end})

ControlsSec:button({name = "Mass Play", callback = function()
    _G.OpenVizMassPlay = _G.OpenVizMassPlay or function(id)
        local prev = audioId
        audioId = id
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("Humanoid") then return end

            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if isBoomboxTool(tool) then tool.Parent = char end
                end
            end

            local tools = {}
            for _, tool in ipairs(char:GetChildren()) do
                if isBoomboxTool(tool) then table.insert(tools, tool) end
            end
            for _, tool in ipairs(tools) do
                local playAudio = tool:FindFirstChild("PlayAudio")
                if playAudio and playAudio:IsA("RemoteFunction") then
                    task.spawn(function()
                        pcall(function() playAudio:InvokeServer(audioId) end)
                    end)
                else
                    local remote = tool:FindFirstChild("Remote")
                    if remote then
                        task.spawn(function()
                            pcall(function() remote:FireServer("PlaySong", audioId) end)
                        end)
                    end
                end
            end
        end)
        audioId = prev
    end

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
                if isBoomboxTool(tool) then tool.Parent = char end
            end
        end

        local waited = 0
        repeat
            task.wait()
            waited += 1
        until (function()
            for _, t in ipairs(char:GetChildren()) do
                if isBoomboxTool(t) and not t:FindFirstChild("Handle") then return false end
            end
            return true
        end)() or waited >= 60

        local tools = {}
        for _, tool in ipairs(char:GetChildren()) do
            if isBoomboxTool(tool) then table.insert(tools, tool) end
        end

        for _, tool in ipairs(tools) do
            local playAudio = tool:FindFirstChild("PlayAudio")
            if playAudio and playAudio:IsA("RemoteFunction") then
                task.spawn(function()
                    pcall(function()
                        playAudio:InvokeServer("PlayAudio", tostring(audioId), "1", "0", "0")
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
        print("Mass Play finished -> " .. #tools .. " boomboxes triggered")
    end)
end})

ControlsSec:textbox({name="Dupe Amount", def="5", callback=function(text)
    local n = tonumber(text)
    if n and n > 0 then dupeTargetAmount = n end
end})

ControlsSec:button({name="Start Dupe", callback=function()
    task.spawn(function()
        local me = game.Players.LocalPlayer
        local count = 0
        local initialChar = me.Character or me.CharacterAdded:Wait()
        local hrcf = initialChar:WaitForChild("HumanoidRootPart").CFrame
        local oldgrav = workspace.Gravity

        while count < dupeTargetAmount do
            local ch  = me.Character or me.CharacterAdded:Wait()
            local hum = ch:WaitForChild("Humanoid")
            for _, j in pairs(workspace:GetChildren()) do
                if j:IsA("Tool") then hum:EquipTool(j) end
            end
            ch:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(0, 3000, 0)
            workspace.Gravity = 0
            task.wait(0.7)
            for _, v in pairs(me.Backpack:GetChildren()) do
                if v:IsA("Tool") then v.Parent = ch end
            end
            task.wait(0.1954)
            for _, v in pairs(ch:GetChildren()) do
                if v:IsA("Tool") then v.Parent = workspace end
            end
            task.wait(0.2)
            count = count + 1
            hum.Health = 0
            me.CharacterAdded:Wait()
            task.wait(0.1)
        end

        local finalChar = me.Character or me.CharacterAdded:Wait()
        local finalhum  = finalChar:WaitForChild("Humanoid")
        for _, j in pairs(workspace:GetChildren()) do
            if j:IsA("Tool") then finalhum:EquipTool(j) end
        end
        finalChar:WaitForChild("HumanoidRootPart").CFrame = hrcf
        workspace.Gravity = oldgrav
        print("yo dupe donezo brah :heart:")
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
local spyTracked = {}
local nameCache = {}
local SPY_RANGE = 40

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

MiscSec:toggle({name="Toggle Audio Spy", def=false, callback=function(b)
    audioSpyEnabled = b
    if not b then
        for _,d in pairs(spyTracked) do if d.bb then d.bb:Destroy() end end
        table.clear(spyTracked)
    end
end})

MiscSec:button({name="Copy Id's in Server", callback=function()
    local lines = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local obj, id = findValidAudio(p.Character)
            if id then
                table.insert(lines, p.Name.." was playing \""..id.."\", \""..(nameCache[id] or "Unknown Name").."\" atm")
            end
        end
    end
    if #lines > 0 then
        local str = table.concat(lines, "\n")
        if setclipboard then setclipboard(str) elseif toclipboard then toclipboard(str) end
    end
end})

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
                    data.alignPos.Position = tPos + Vector3.new(math.random()*0.01-0.005, 0, 0)
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
                        local total = math.max(1, countTracked())
                        local leftCount = math.ceil(total / 2)
                        local rightCount = total - leftCount
                        local isRight = data.index > leftCount
                        local side = isRight and 1 or -1
                        local sideIndex = isRight and (data.index - leftCount) or data.index
                        local sideTotal = math.max(1, isRight and rightCount or leftCount)
                        local progress = (sideIndex - 1) / math.max(1, sideTotal - 1)
                        local flapRoll = math.sin((t * currentSpeed * 1.7) - progress * 2.35) * math.rad(10 + progress * 18)
                        local yaw = math.rad(18 + progress * 28) * side
                        local roll = math.rad(74 - progress * 22) * side + flapRoll
                        local pitch = math.rad(-8 + progress * 12)

                        tRot = CFrame.lookAt(tPos, tPos + hrp.CFrame.LookVector)
                            * CFrame.Angles(pitch, yaw, roll)
                    elseif activePreset.layered then
                        local layer = math.floor((data.index-1)/8)
                        local layerHeight = currentHeight + (layer*4)
                        local centerPos = hrp.CFrame:PointToWorldSpace(Vector3.new(0, layerHeight, 0))
                        tRot = CFrame.lookAt(tPos, centerPos)
                    elseif activePreset.theThing and data.index > 1 then
                        tRot = (tLP and CFrame.new(tPos, tLP) or CFrame.new(tPos, hrp.Position))
                             * CFrame.Angles(0, math.rad(90), 0)
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
                    data.alignPos.Position = tPos + Vector3.new(math.random()*0.01-0.005, 0, 0)
                    data.alignRot.CFrame   = tRot
                end)
            end
        end
    end
end)
