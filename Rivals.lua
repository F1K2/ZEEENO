-- Bibliothèque Rayfield
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local DrawingEnabled = pcall(function() return Drawing.new("Line") end)

-- Variables ESP
local ESPEnabled = false
local ESPShowName = true
local ESPShowBox = true
local ESPShowDistance = true
local ESPShowHealth = true
local ESPShowTeam = false
local ESPTeamColorToggle = true
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPTransparency = 0.8
local ESPTextSize = 14
local ESPMaxDistance = 1000
local ESPBoxes = {}
local ESPTexts = {}
local ESPHealthBars = {}

-- Variables Aimbot
local AimbotEnabled = false
local AimbotTeamCheck = true
local AimbotVisibilityCheck = true
local AimbotFOVEnabled = true
local AimbotFOVSize = 200
local AimbotFOVColor = Color3.fromRGB(255, 255, 255)
local AimbotFOVTransparency = 0.7
local AimbotFOVCircle = nil
local AimbotSmoothness = 2
local AimbotMaxDistance = 1000
local AimbotTargetPart = "Head"
local AimbotAimKey = Enum.UserInputType.MouseButton2  -- Changé pour clic droit
local AimbotToggleKey = Enum.KeyCode.LeftControl
local AimbotIsPressed = false
local AimbotTarget = nil
local AimbotAutoShoot = false
local AimbotPrediction = false
local AimbotPredictionAmount = 1

-- Variables Movement
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local NoClipEnabled = false
local FlyEnabled = false
local FlySpeed = 50
local DefaultWalkSpeed = 16
local DefaultJumpPower = 50
local NoClipConnection = nil
local FlyConnection = nil

-- Créer l'interface
local Window = Rayfield:CreateWindow({
    Name = "Zeno Rivals",
    LoadingTitle = "Chargement en cours...",
    LoadingSubtitle = "par 4444",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CombatHelper",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Créer les onglets
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483345998)
local MovementTab = Window:CreateTab("Movement", 4483345737) -- Nouvel onglet
local SettingsTab = Window:CreateTab("Paramètres", 4483345737)

-- Fonction pour créer les éléments de l'ESP pour un joueur
local function CreateESPItems(player)
    if player == Player then return end
    
    -- Créer le texte ESP
    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Font = 2
    text.Size = ESPTextSize
    text.Color = ESPColor
    text.Transparency = ESPTransparency
    ESPTexts[player] = text
    
    -- Créer la boîte ESP
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Filled = false
    box.Transparency = ESPTransparency
    box.Color = ESPColor
    ESPBoxes[player] = box
    
    -- Créer la barre de vie
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Transparency = ESPTransparency
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    ESPHealthBars[player] = healthBar
end

-- Fonction pour supprimer les éléments ESP d'un joueur
local function RemoveESPItems(player)
    if ESPTexts[player] then
        ESPTexts[player]:Remove()
        ESPTexts[player] = nil
    end
    
    if ESPBoxes[player] then
        ESPBoxes[player]:Remove()
        ESPBoxes[player] = nil
    end
    
    if ESPHealthBars[player] then
        ESPHealthBars[player]:Remove()
        ESPHealthBars[player] = nil
    end
end

-- Fonction pour déterminer si un joueur est un ennemi
local function IsEnemy(player)
    -- Logique pour déterminer si un joueur est un ennemi
    -- Cette logique dépend du jeu, donc vous devrez peut-être l'adapter
    if not player or not Player then return true end
    
    if player.Team and Player.Team then
        return player.Team ~= Player.Team
    end
    
    return player ~= Player
end

-- Fonction pour vérifier si un objet est visible
local function IsVisible(part)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 1000
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {Player.Character}
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if result and result.Instance and result.Instance:IsDescendantOf(part.Parent) then
        return true
    end
    
    return false
end

-- Fonction améliorée pour calculer les coins de la boîte ESP
local function GetBoxCorners(character)
    if not character then return nil end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Trouver toutes les parties du personnage
    local parts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    
    if #parts == 0 then return nil end
    
    -- Calculer les limites du modèle en utilisant toutes les parties
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in pairs(parts) do
        local size = part.Size
        local cf = part.CFrame
        
        local corners = {
            cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
        }
        
        for _, corner in pairs(corners) do
            local pos = corner.Position
            minX = math.min(minX, pos.X)
            minY = math.min(minY, pos.Y)
            minZ = math.min(minZ, pos.Z)
            maxX = math.max(maxX, pos.X)
            maxY = math.max(maxY, pos.Y)
            maxZ = math.max(maxZ, pos.Z)
        end
    end
    
    -- Convertir les coordonnées 3D en coordonnées d'écran 2D
    local topFrontLeft = Camera:WorldToViewportPoint(Vector3.new(minX, maxY, minZ))
    local topFrontRight = Camera:WorldToViewportPoint(Vector3.new(maxX, maxY, minZ))
    local bottomFrontLeft = Camera:WorldToViewportPoint(Vector3.new(minX, minY, minZ))
    local bottomFrontRight = Camera:WorldToViewportPoint(Vector3.new(maxX, minY, minZ))
    
    local topBackLeft = Camera:WorldToViewportPoint(Vector3.new(minX, maxY, maxZ))
    local topBackRight = Camera:WorldToViewportPoint(Vector3.new(maxX, maxY, maxZ))
    local bottomBackLeft = Camera:WorldToViewportPoint(Vector3.new(minX, minY, maxZ))
    local bottomBackRight = Camera:WorldToViewportPoint(Vector3.new(maxX, minY, maxZ))
    
    -- Trouver les limites 2D
    local boxCorners = {
        topFrontLeft, topFrontRight, bottomFrontLeft, bottomFrontRight,
        topBackLeft, topBackRight, bottomBackLeft, bottomBackRight
    }
    
    local minX2D, minY2D = math.huge, math.huge
    local maxX2D, maxY2D = -math.huge, -math.huge
    
    for _, corner in pairs(boxCorners) do
        if corner.Z > 0 then -- Vérifier si le point est devant la caméra
            minX2D = math.min(minX2D, corner.X)
            minY2D = math.min(minY2D, corner.Y)
            maxX2D = math.max(maxX2D, corner.X)
            maxY2D = math.max(maxY2D, corner.Y)
        end
    end
    
    -- Si un des points est derrière la caméra, utiliser une méthode plus simple
    if minX2D == math.huge then
        local head = character:FindFirstChild("Head")
        local rootPart = hrp
        
        if head and rootPart then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            local rootPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, -3, 0))
            
            local height = math.abs(headPos.Y - rootPos.Y)
            local width = height * 0.6
            
            minX2D = headPos.X - width / 2
            minY2D = headPos.Y - height * 0.1
            maxX2D = headPos.X + width / 2
            maxY2D = rootPos.Y
        else
            return nil
        end
    end
    
    return Vector2.new(minX2D, minY2D), Vector2.new(maxX2D - minX2D, maxY2D - minY2D)
end

-- Fonction pour mettre à jour l'ESP
local function UpdateESP()
    if not ESPEnabled then
        -- Cacher tous les éléments ESP
        for _, text in pairs(ESPTexts) do
            text.Visible = false
        end
        
        for _, box in pairs(ESPBoxes) do
            box.Visible = false
        end
        
        for _, healthBar in pairs(ESPHealthBars) do
            healthBar.Visible = false
        end
        
        return
    end
    
    -- Mettre à jour les éléments ESP pour chaque joueur
    for _, player in pairs(Players:GetPlayers()) do
        -- Créer les éléments ESP s'ils n'existent pas
        if not ESPTexts[player] and player ~= Player then
            CreateESPItems(player)
        end
        
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
           player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            -- Vérifier si le joueur est un ennemi
            local isEnemy = IsEnemy(player)
            
            -- Ne pas afficher les membres de l'équipe si désactivé
            if not ESPShowTeam and not isEnemy then
                if ESPTexts[player] then ESPTexts[player].Visible = false end
                if ESPBoxes[player] then ESPBoxes[player].Visible = false end
                if ESPHealthBars[player] then ESPHealthBars[player].Visible = false end
                continue
            end
            
            local rootPart = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head")
            
            if not rootPart or not humanoid or not head then continue end
            
            -- Calculer la position à l'écran
            local rootPos, rootOnScreen = Camera:WorldToScreenPoint(rootPart.Position)
            
            -- Vérifier si le joueur est à l'écran et dans la distance maximale
            local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
            if not rootOnScreen or distance > ESPMaxDistance then
                if ESPTexts[player] then ESPTexts[player].Visible = false end
                if ESPBoxes[player] then ESPBoxes[player].Visible = false end
                if ESPHealthBars[player] then ESPHealthBars[player].Visible = false end
                continue
            end
            
            -- Déterminer la couleur en fonction de l'équipe
            local color = ESPColor
            if ESPTeamColorToggle and player.Team then
                color = player.TeamColor.Color
            elseif not isEnemy then
                color = Color3.fromRGB(0, 255, 0) -- Vert pour les alliés
            end
            
            -- Mettre à jour le texte ESP
            if ESPTexts[player] then
                local textInfo = ""
                
                if ESPShowName then
                    textInfo = player.Name
                end
                
                if ESPShowDistance then
                    textInfo = textInfo .. (ESPShowName and " [" or "") .. math.floor(distance) .. "m" .. (ESPShowName and "]" or "")
                end
                
                if ESPShowHealth then
                    textInfo = textInfo .. "\nVie: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                end
                
                ESPTexts[player].Text = textInfo
                ESPTexts[player].Position = Vector2.new(rootPos.X, rootPos.Y - 40)
                ESPTexts[player].Color = color
                ESPTexts[player].Size = ESPTextSize
                ESPTexts[player].Transparency = ESPTransparency
                ESPTexts[player].Visible = true
            end
            
            -- Calculer les dimensions de la boîte ESP avec la nouvelle fonction
            if ESPShowBox and ESPBoxes[player] then
                local boxPos, boxSize = GetBoxCorners(player.Character)
                
                if boxPos and boxSize then
                    ESPBoxes[player].Position = boxPos
                    ESPBoxes[player].Size = boxSize
                    ESPBoxes[player].Color = color
                    ESPBoxes[player].Transparency = ESPTransparency
                    ESPBoxes[player].Visible = true
                else
                    ESPBoxes[player].Visible = false
                end
            else
                if ESPBoxes[player] then
                    ESPBoxes[player].Visible = false
                end
            end
            
            -- Mettre à jour la barre de vie
            if ESPShowHealth and ESPHealthBars[player] and ESPBoxes[player].Visible then
                local boxPos = ESPBoxes[player].Position
                local boxSize = ESPBoxes[player].Size
                
                local healthBarWidth = 4
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                local healthBarHeight = boxSize.Y * healthPercentage
                
                -- Couleur de la barre de vie du vert au rouge en fonction de la santé
                local healthColor = Color3.fromRGB(
                    255 * (1 - healthPercentage),
                    255 * healthPercentage,
                    0
                )
                
                ESPHealthBars[player].Size = Vector2.new(healthBarWidth, healthBarHeight)
                ESPHealthBars[player].Position = Vector2.new(boxPos.X - healthBarWidth * 2, boxPos.Y + (boxSize.Y - healthBarHeight))
                ESPHealthBars[player].Color = healthColor
                ESPHealthBars[player].Transparency = ESPTransparency
                ESPHealthBars[player].Visible = true
            else
                if ESPHealthBars[player] then
                    ESPHealthBars[player].Visible = false
                end
            end
        else
            -- Cacher les éléments ESP si le joueur n'est pas visible
            if ESPTexts[player] then ESPTexts[player].Visible = false end
            if ESPBoxes[player] then ESPBoxes[player].Visible = false end
            if ESPHealthBars[player] then ESPHealthBars[player].Visible = false end
        end
    end
end

-- Fonction pour créer le cercle FOV de l'Aimbot
local function CreateAimbotFOVCircle()
    if AimbotFOVCircle then
        AimbotFOVCircle:Remove()
    end
    
    AimbotFOVCircle = Drawing.new("Circle")
    AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
    AimbotFOVCircle.Radius = AimbotFOVSize
    AimbotFOVCircle.Color = AimbotFOVColor
    AimbotFOVCircle.Thickness = 1
    AimbotFOVCircle.Filled = false
    AimbotFOVCircle.Transparency = AimbotFOVTransparency
    AimbotFOVCircle.NumSides = 60
    AimbotFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Fonction pour trouver la cible de l'Aimbot
local function GetAimbotTarget()
    local closestPlayer = nil
    local shortestDistance = AimbotFOVEnabled and AimbotFOVSize or math.huge
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0 then
            
            -- Vérifier si le joueur est un ennemi
            if AimbotTeamCheck and not IsEnemy(player) then
                continue
            end
            
            local targetPart = player.Character:FindFirstChild(AimbotTargetPart)
            if not targetPart then
                targetPart = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if not targetPart then
                    continue
                end
            end
            
            -- Vérifier la visibilité
            if AimbotVisibilityCheck and not IsVisible(targetPart) then
                continue
            end
            
            -- Calculer la position à l'écran
            local targetPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if not onScreen then
                continue
            end
            
            -- Vérifier la distance
            local distance3D = (Player.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
            if distance3D > AimbotMaxDistance then
                continue
            end
            
            -- Calculer la distance sur l'écran
            local screenDistance = (Vector2.new(targetPos.X, targetPos.Y) - mousePos).Magnitude
            
            -- Vérifier si c'est la cible la plus proche
            if screenDistance < shortestDistance then
                shortestDistance = screenDistance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer
end

-- Fonction pour calculer la position prédite pour l'Aimbot
local function GetPredictedPosition(targetPart)
    if not AimbotPrediction or not targetPart or not targetPart.Parent then return targetPart.Position end
    
    local player = Players:GetPlayerFromCharacter(targetPart.Parent)
    if not player then return targetPart.Position end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return targetPart.Position end
    
    local velocity = humanoid.MoveDirection * humanoid.WalkSpeed
    return targetPart.Position + (velocity * AimbotPredictionAmount)
end

-- Fonction pour l'Aimbot
local function AimbotUpdate()
    if not AimbotEnabled or not AimbotIsPressed then
        AimbotTarget = nil
        return
    end
    
    AimbotTarget = GetAimbotTarget()
    
    if AimbotTarget and AimbotTarget.Character then
        local targetPart = AimbotTarget.Character:FindFirstChild(AimbotTargetPart)
        if not targetPart then
            targetPart = AimbotTarget.Character:FindFirstChild("Head") or AimbotTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetPart then
                return
            end
        end
        
        local predictedPos = GetPredictedPosition(targetPart)
        local targetPos = Camera:WorldToViewportPoint(predictedPos)
        
        if targetPos.Z < 0 then
            return
        end
        
        -- Calculer la nouvelle position du curseur
        local targetVector = Vector2.new(targetPos.X, targetPos.Y)
        local mousePos = UserInputService:GetMouseLocation()
        local moveVector = (targetVector - mousePos) / AimbotSmoothness
        
        -- Déplacer le curseur
        mousemoverel(moveVector.X, moveVector.Y)
        
        -- Auto tir si activé
        if AimbotAutoShoot and Player.Character and Player.Character:FindFirstChildOfClass("Tool") then
            local tool = Player.Character:FindFirstChildOfClass("Tool")
            if tool:FindFirstChild("Fire") and tool:FindFirstChild("Fire"):IsA("RemoteEvent") then
                tool.Fire:FireServer(predictedPos)
            end
        end
    end
end

-- Fonction pour mettre à jour Walk Speed
local function UpdateWalkSpeed()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        if WalkSpeedEnabled then
            Player.Character.Humanoid.WalkSpeed = WalkSpeedValue
        else
            Player.Character.Humanoid.WalkSpeed = DefaultWalkSpeed
        end
    end
end

-- Fonction pour mettre à jour Jump Power
local function UpdateJumpPower()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        if JumpPowerEnabled then
            Player.Character.Humanoid.JumpPower = JumpPowerValue
        else
            Player.Character.Humanoid.JumpPower = DefaultJumpPower
        end
    end
end

-- Fonction pour No Clip
local function SetupNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    
    if NoClipEnabled then
        NoClipConnection = RunService.Stepped:Connect(function()
            if Player.Character then
                for _, part in pairs(Player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if Player.Character then
            for _, part in pairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Fonction pour Fly
local function SetupFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    if FlyEnabled then
        local flyPart = Instance.new("BodyVelocity")
        flyPart.Name = "FlyVelocity"
        flyPart.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyPart.Velocity = Vector3.new(0, 0, 0)
        
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            flyPart.Parent = Player.Character.HumanoidRootPart
        end
        
        FlyConnection = RunService.RenderStepped:Connect(function()
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                local flyVel = Player.Character.HumanoidRootPart:FindFirstChild("FlyVelocity")
                if not flyVel then
                    flyVel = flyPart:Clone()
                    flyVel.Parent = Player.Character.HumanoidRootPart
                end
                
                local camera = workspace.CurrentCamera
                local movementDirection = Vector3.new(0, 0, 0)
                
                -- Déplacement selon les touches
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    movementDirection = movementDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    movementDirection = movementDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    movementDirection = movementDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    movementDirection = movementDirection + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    movementDirection = movementDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    movementDirection = movementDirection - Vector3.new(0, 1, 0)
                end
                
                -- Normaliser et appliquer la vitesse
                if movementDirection.Magnitude > 0 then
                    movementDirection = movementDirection.Unit * FlySpeed
                end
                
                flyVel.Velocity = movementDirection
            end
        end)
    else
        if Player.Character then
            local flyVel = Player.Character:FindFirstChild("HumanoidRootPart") and 
                           Player.Character.HumanoidRootPart:FindFirstChild("FlyVelocity")
            if flyVel then
                flyVel:Destroy()
            end
        end
    end
end

-- Gestion des joueurs
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then
        CreateESPItems(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESPItems(player)
end)

-- Mise à jour de l'ESP et de l'Aimbot à chaque frame
RunService.RenderStepped:Connect(function()
    UpdateESP()
    
    -- Mettre à jour la position du cercle FOV
    if AimbotFOVCircle then
        AimbotFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
    end
    
    AimbotUpdate()
end)

-- Gérer les changements de personnage
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    
    -- Mettre à jour les valeurs de mouvement lorsque le personnage change
    if WalkSpeedEnabled then
        Humanoid.WalkSpeed = WalkSpeedValue
    end
    
    if JumpPowerEnabled then
        Humanoid.JumpPower = JumpPowerValue
    end
    
    -- Réappliquer No Clip et Fly si activés
    if NoClipEnabled then
        SetupNoClip()
    end
    
    if FlyEnabled then
        SetupFly()
    end
end)

-- Gestion des entrées
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.UserInputType == AimbotAimKey then  -- Modifié pour clic droit
            AimbotIsPressed = true
        elseif input.KeyCode == AimbotToggleKey then
            AimbotEnabled = not AimbotEnabled
            if AimbotFOVCircle then
                AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.UserInputType == AimbotAimKey then  -- Modifié pour clic droit
            AimbotIsPressed = false
        end
    end
end)

-- Créer des éléments ESP pour les joueurs existants
for _, player in pairs(Players:GetPlayers()) do
    if player ~= Player then
        CreateESPItems(player)
    end
end

-- Créer le cercle FOV de l'Aimbot
CreateAimbotFOVCircle()

-- UI pour l'onglet ESP
ESPTab:CreateToggle({
    Name = "Activer ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        ESPEnabled = Value
    end
})

ESPTab:CreateToggle({
    Name = "Afficher noms",
    CurrentValue = true,
    Flag = "ESPShowName",
    Callback = function(Value)
        ESPShowName = Value
    end
})

ESPTab:CreateToggle({
    Name = "Afficher boîtes",
    CurrentValue = true,
    Flag = "ESPShowBox",
    Callback = function(Value)
        ESPShowBox = Value
    end
})

ESPTab:CreateToggle({
    Name = "Afficher distance",
    CurrentValue = true,
    Flag = "ESPShowDistance",
    Callback = function(Value)
        ESPShowDistance = Value
    end
})

ESPTab:CreateToggle({
    Name = "Afficher vie",
    CurrentValue = true,
    Flag = "ESPShowHealth",
    Callback = function(Value)
        ESPShowHealth = Value
    end
})

ESPTab:CreateToggle({
    Name = "Afficher équipe",
    CurrentValue = false,
    Flag = "ESPShowTeam",
    Callback = function(Value)
        ESPShowTeam = Value
    end
})

ESPTab:CreateToggle({
    Name = "Couleur d'équipe",
    CurrentValue = true,
    Flag = "ESPTeamColorToggle",
    Callback = function(Value)
        ESPTeamColorToggle = Value
    end
})

ESPTab:CreateSlider({
    Name = "Taille du texte",
    Range = {10, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 14,
    Flag = "ESPTextSize",
    Callback = function(Value)
        ESPTextSize = Value
    end
})

ESPTab:CreateSlider({
    Name = "Transparence",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.8,
    Flag = "ESPTransparency",
    Callback = function(Value)
        ESPTransparency = Value
    end
})

ESPTab:CreateSlider({
    Name = "Distance maximale",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "m",
    CurrentValue = 1000,
    Flag = "ESPMaxDistance",
    Callback = function(Value)
        ESPMaxDistance = Value
    end
})

ESPTab:CreateColorPicker({
    Name = "Couleur ESP",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Value)
        ESPColor = Value
    end
})

-- UI pour l'onglet Aimbot
AimbotTab:CreateToggle({
    Name = "Activer Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(Value)
        AimbotEnabled = Value
        if AimbotFOVCircle then
            AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Vérification équipe",
    CurrentValue = true,
    Flag = "AimbotTeamCheck",
    Callback = function(Value)
        AimbotTeamCheck = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Vérification visibilité",
    CurrentValue = true,
    Flag = "AimbotVisibilityCheck",
    Callback = function(Value)
        AimbotVisibilityCheck = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Activer FOV",
    CurrentValue = true,
    Flag = "AimbotFOVEnabled",
    Callback = function(Value)
        AimbotFOVEnabled = Value
        if AimbotFOVCircle then
            AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Tir automatique",
    CurrentValue = false,
    Flag = "AimbotAutoShoot",
    Callback = function(Value)
        AimbotAutoShoot = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Prédiction",
    CurrentValue = false,
    Flag = "AimbotPrediction",
    Callback = function(Value)
        AimbotPrediction = Value
    end
})

AimbotTab:CreateSlider({
    Name = "Taille FOV",
    Range = {50, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "AimbotFOVSize",
    Callback = function(Value)
        AimbotFOVSize = Value
        if AimbotFOVCircle then
            AimbotFOVCircle.Radius = Value
        end
    end
})

AimbotTab:CreateSlider({
    Name = "Fluidité",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "",
    CurrentValue = 2,
    Flag = "AimbotSmoothness",
    Callback = function(Value)
        AimbotSmoothness = Value
    end
})

AimbotTab:CreateSlider({
    Name = "Distance maximale",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "m",
    CurrentValue = 1000,
    Flag = "AimbotMaxDistance",
    Callback = function(Value)
        AimbotMaxDistance = Value
    end
})

AimbotTab:CreateSlider({
    Name = "Valeur de prédiction",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "AimbotPredictionAmount",
    Callback = function(Value)
        AimbotPredictionAmount = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "Partie ciblée",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Flag = "AimbotTargetPart",
    Callback = function(Value)
        AimbotTargetPart = Value
    end
})

AimbotTab:CreateColorPicker({
    Name = "Couleur FOV",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "AimbotFOVColor",
    Callback = function(Value)
        AimbotFOVColor = Value
        if AimbotFOVCircle then
            AimbotFOVCircle.Color = Value
        end
    end
})

-- UI pour l'onglet Movement
MovementTab:CreateToggle({
    Name = "Walk Speed",
    CurrentValue = false,
    Flag = "WalkSpeedEnabled",
    Callback = function(Value)
        WalkSpeedEnabled = Value
        UpdateWalkSpeed()
    end
})

MovementTab:CreateSlider({
    Name = "Vitesse",
    Range = {16, 200},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeedValue",
    Callback = function(Value)
        WalkSpeedValue = Value
        UpdateWalkSpeed()
    end
})

MovementTab:CreateToggle({
    Name = "Jump Power",
    CurrentValue = false,
    Flag = "JumpPowerEnabled",
    Callback = function(Value)
        JumpPowerEnabled = Value
        UpdateJumpPower()
    end
})

MovementTab:CreateSlider({
    Name = "Puissance saut",
    Range = {50, 300},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPowerValue",
    Callback = function(Value)
        JumpPowerValue = Value
        UpdateJumpPower()
    end
})

MovementTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClipEnabled",
    Callback = function(Value)
        NoClipEnabled = Value
        SetupNoClip()
    end
})

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(Value)
        FlyEnabled = Value
        SetupFly()
    end
})

MovementTab:CreateSlider({
    Name = "Vitesse de vol",
    Range = {10, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        FlySpeed = Value
    end
})

-- UI pour l'onglet Paramètres
SettingsTab:CreateSection("Commandes")

SettingsTab:CreateLabel("Aimbot: Clic droit (maintenir)")
SettingsTab:CreateLabel("Activer/Désactiver Aimbot: LeftControl")
SettingsTab:CreateLabel("Fly: W,A,S,D + Space/Shift")

SettingsTab:CreateSection("Sauvegarde")

SettingsTab:CreateButton({
    Name = "Sauvegarder config",
    Callback = function()
        -- Sauvegarder la configuration
        Rayfield:SaveConfiguration()
        
        -- Notifier l'utilisateur
        Rayfield:Notify({
            Title = "Sauvegarde",
            Content = "Configuration sauvegardée avec succès!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateButton({
    Name = "Réinitialiser config",
    Callback = function()
        -- Demander confirmation
        local confirmed = false
        
        Rayfield:Notify({
            Title = "Confirmation",
            Content = "Êtes-vous sûr de vouloir réinitialiser la configuration?",
            Duration = 5,
            Image = 4483362458,
            Actions = {
                Confirm = {
                    Name = "Confirmer",
                    Callback = function()
                        confirmed = true
                        
                        -- Réinitialiser les valeurs
                        ESPEnabled = false
                        ESPShowName = true
                        ESPShowBox = true
                        ESPShowDistance = true
                        ESPShowHealth = true
                        ESPShowTeam = false
                        ESPTeamColorToggle = true
                        ESPColor = Color3.fromRGB(255, 0, 0)
                        ESPTransparency = 0.8
                        ESPTextSize = 14
                        ESPMaxDistance = 1000
                        
                        AimbotEnabled = false
                        AimbotTeamCheck = true
                        AimbotVisibilityCheck = true
                        AimbotFOVEnabled = true
                        AimbotFOVSize = 200
                        AimbotFOVColor = Color3.fromRGB(255, 255, 255)
                        AimbotFOVTransparency = 0.7
                        AimbotSmoothness = 2
                        AimbotMaxDistance = 1000
                        AimbotTargetPart = "Head"
                        AimbotAimKey = Enum.UserInputType.MouseButton2
                        AimbotToggleKey = Enum.KeyCode.LeftControl
                        AimbotAutoShoot = false
                        AimbotPrediction = false
                        AimbotPredictionAmount = 1
                        
                        WalkSpeedEnabled = false
                        WalkSpeedValue = 16
                        JumpPowerEnabled = false
                        JumpPowerValue = 50
                        NoClipEnabled = false
                        FlyEnabled = false
                        FlySpeed = 50
                        
                        -- Mettre à jour l'interface
                        Rayfield:LoadConfiguration()
                        
                        -- Mettre à jour le cercle FOV
                        if AimbotFOVCircle then
                            AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
                            AimbotFOVCircle.Radius = AimbotFOVSize
                            AimbotFOVCircle.Color = AimbotFOVColor
                        end
                        
                        -- Mettre à jour les mouvements
                        UpdateWalkSpeed()
                        UpdateJumpPower()
                        SetupNoClip()
                        SetupFly()
                        
                        Rayfield:Notify({
                            Title = "Réinitialisation",
                            Content = "Configuration réinitialisée avec succès!",
                            Duration = 3,
                            Image = 4483362458
                        })
                    end
                },
                Cancel = {
                    Name = "Annuler",
                    Callback = function()
                        confirmed = false
                    end
                }
            }
        })
    end
})

SettingsTab:CreateButton({
    Name = "Quitter",
    Callback = function()
        -- Fermer l'interface
        Rayfield:Destroy()
        
        -- Nettoyer
        if AimbotFOVCircle then
            AimbotFOVCircle:Remove()
            AimbotFOVCircle = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            RemoveESPItems(player)
        end
        
        -- Réinitialiser les mouvements
        WalkSpeedEnabled = false
        JumpPowerEnabled = false
        NoClipEnabled = false
        FlyEnabled = false
        
        UpdateWalkSpeed()
        UpdateJumpPower()
        
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
        end
        
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        
        if Player.Character then
            local flyVel = Player.Character:FindFirstChild("HumanoidRootPart") and 
                          Player.Character.HumanoidRootPart:FindFirstChild("FlyVelocity")
            if flyVel then
                flyVel:Destroy()
            end
        end
    end
})

-- Charger la configuration sauvegardée
Rayfield:LoadConfiguration()

-- Saluer l'utilisateur
Rayfield:Notify({
    Title = "Advanced Combat Helper",
    Content = "Bienvenue! Appuyez sur Insérer pour ouvrir/fermer l'interface.",
    Duration = 5,
    Image = 4483362458
})

-- Fonction d'initialisation pour s'assurer que tout est correctement configuré
local function InitializeScript()
    -- Mettre à jour le cercle FOV
    if AimbotFOVCircle then
        AimbotFOVCircle.Visible = AimbotFOVEnabled and AimbotEnabled
        AimbotFOVCircle.Radius = AimbotFOVSize
        AimbotFOVCircle.Color = AimbotFOVColor
    else
        CreateAimbotFOVCircle()
    end
    
    -- Mettre à jour les mouvements
    UpdateWalkSpeed()
    UpdateJumpPower()
    
    -- Configurer No Clip et Fly s'ils sont activés
    if NoClipEnabled then
        SetupNoClip()
    end
    
    if FlyEnabled then
        SetupFly()
    end
end

-- Exécuter l'initialisation
InitializeScript()

-- Fin du script
print("Advanced Combat Helper chargé avec succès!")