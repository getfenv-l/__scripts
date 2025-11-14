getgenv().cloneref = cloneref or function(...)
    return ...
end

getgenv().__setref = setmetatable({}, {
    __index = function(__type, __name)
        rawset(__type, __name, cloneref(game:GetService(__name)))

        return rawget(__type, __name)
    end
})

-- // __variables
local __stats = __setref.Stats
local __debris = __setref.Debris
local __coregui = __setref.CoreGui
local __players = __setref.Players
local __runservice = __setref.RunService
local __tweenservice = __setref.TweenService
local __inputservice = __setref.UserInputService
local __replicatedstorage = __setref.ReplicatedStorage

local __localplayer = __players.LocalPlayer
local __mouse = __localplayer:GetMouse()

local __playergui = __localplayer:WaitForChild('PlayerGui', 5)
local __camera = workspace.CurrentCamera
local __is_mobile = table.find({
    Enum.Platform.IOS,
    Enum.Platform.Android
}, __inputservice:GetPlatform())

-- // refs
local __refs = {
    __cache = {
        __auto_parry = {
            __enabled = false,
            __animfix = false,
            __accuracy = 1,
        },
        __auto_spam = {
            __enabled = false,
            __animfix = false,
            __threshold = 1.5,
        },
        __manual_spam = {
            __enabled = false,
            __animfix = false,
            __count = 0,
            __rate = 240,
        },
        __triggerbot = {
            __enabled = false,
            __anim_fix = false,
            __is_parrying = false,
            __parry_delay = 0.5,
            __parries = 0,
        },
        __skin_changer = {
            __enabled = false,
            __name = '',
            __anim = '',
            __fx = ''
        },

        __dupe_ball = false,

        __deathslash = false,
        __infinity = false,
        __timehole = false,
        __phantom = false,

        __slashesoffury = false,
        __slashesoffury_count = 0,

        __parries = 0,
        __mode = 'Camera',
        __parried = false,
        __grab_anim = nil,
        __first_parry = false,
        __training_parried = false,
    },
    __detection = {
        __slashesoffury = false,
        __deathslash = false,
        __infinity = false,
        __timehole = false,
        __phantom = false,

        __ball_props = {
            __aerodynamic_time = tick(),
            __tornado_time = tick(),
            __last_warping = tick(),
            __lerp_radians = 0,
            __curving = tick()
        }
    },
    __funcs = {},
    __flags = {},
    __ui = {}
}

-- // bypass
local __remotes, __origin = {}, {}
local __pf, __sc

if __replicatedstorage:FindFirstChild('Controllers') then
    for _, __obj in __replicatedstorage.Controllers:GetChildren() do
        if __obj.Name == 'SwordsController' then
            __sc = __obj break
        end
    end
end

if __playergui:FindFirstChild('Hotbar') and __playergui.Hotbar:FindFirstChild('Block') then
    for _, __conn in next, getconnections(__playergui.Hotbar.Block.Activated) do
        if __sc and getfenv(__conn.Function).script == __sc then
            __pf = __conn.Function break
        end
    end
end

local function __is_valid(__args)
    return #__args == 7 and
        type(__args[2]) == 'string' and
        type(__args[3]) == 'number' and
        typeof(__args[4]) == 'CFrame' and
        type(__args[5]) == 'table' and
        type(__args[6]) == 'table' and
        type(__args[7]) == 'boolean'
end

local function __hook(__remote)
    if not __remotes[__remote] then
        if not __origin[getrawmetatable(__remote)] then
            __origin[getrawmetatable(__remote)] = true
            local __meta = getrawmetatable(__remote)
            setreadonly(__meta, false)

            local __old = __meta.__index

            __meta.__index = function(self, __key)
                if (__key == 'FireServer' and self:IsA('RemoteEvent')) or (__key == 'InvokeServer' and self:IsA('RemoteFunction')) then
                    return function(_, ...)
                        local __args = {...}

                        if __is_valid(__args) and not __remotes[self] then
                            __remotes[self] = __args
                        end

                        return __old(self, __key)(_, unpack(__args))
                    end
                end

                return __old(self, __key)
            end

            setreadonly(__meta, true)
        end
    end
end

for _, __remote in pairs(__replicatedstorage:GetChildren()) do
    if __remote:IsA('RemoteEvent') or __remote:IsA('RemoteFunction') then
        __hook(__remote)
    end
end

__replicatedstorage.ChildAdded:Connect(function(__obj)
    if __obj:IsA('RemoteEvent') or __obj:IsA('RemoteFunction') then
        __hook(__obj)
    end
end)

-- // functions
function __refs.__funcs.__play_anim()
    local __char = __localplayer.Character

    if not __char then
        return
    end

    local __humanoid = __char:FindFirstChildOfClass('Humanoid')
    local __animator = __humanoid and __humanoid:FindFirstChildOfClass('Animator') or __humanoid

    if not __humanoid then
        return
    end

    local __name = __localplayer:GetAttribute('CurrentlyEquippedSword')

    if not __name then
        return
    end

    local __sword_api = __replicatedstorage.Shared.SwordAPI.Collection
    local __parry_anim = __sword_api.Default:FindFirstChild('GrabParry')

    if not __parry_anim then
        return
    end

    local __sword_data = __replicatedstorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(__name)

    if not __sword_data or not __sword_data['AnimationType'] then
        return
    end

    for _, __obj in __sword_api:GetChildren() do
        if __obj.Name == __sword_data['AnimationType'] then
            if __obj:FindFirstChild('GrabParry') or __obj:FindFirstChild('Grab') then
                local __type = __obj:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                __parry_anim = __obj[__type]
            end
        end
    end

    if __refs.__cache.__grab_anim and __refs.__cache.__grab_anim.IsPlaying then
        __refs.__cache.__grab_anim:Stop()
    end

    __refs.__cache.__grab_anim = __animator:LoadAnimation(__parry_anim)
    __refs.__cache.__grab_anim.Priority = Enum.AnimationPriority.Action4
    __refs.__cache.__grab_anim:Play()
end

-- // Get Balls
function __refs.__funcs.__get_ball()
    for _, __ball in workspace.Balls:GetChildren() do
        if __ball:GetAttribute('realBall') then
            __ball.CanCollide = false
            return __ball
        end
    end

    return nil
end

function __refs.__funcs.__get_balls()
    local __balls = {}

    for _, __ball in workspace.Balls:GetChildren() do
        if __ball:GetAttribute('realBall') then
            __ball.CanCollide = false
            table.insert(__balls, __ball)
        end
    end

    return __balls
end


function __refs.__funcs.__closest()
    local __closest, __max = nil, math.huge

    for _, __plr in workspace.Alive:GetChildren() do
        if __plr.Name ~= __localplayer.Name and __plr.PrimaryPart then
            local __dist = __localplayer:DistanceFromCharacter(__plr.PrimaryPart.Position)

            if __dist < __max then
                __max = __dist
                __closest = __plr
            end
        end
    end

    return __closest
end


function __refs.__funcs.__closest_to_cursor()
    if not workspace.Alive:FindFirstChild(__localplayer.Name) then
        return nil
    end

    local __closest, __min_dot = nil, -math.huge
    local __location = __inputservice:GetMouseLocation()

    local __point = __camera:ScreenPointToRay(__location.X, __location.Y)
    local __pointer = CFrame.lookAt(__point.Origin, __point.Origin + __point.Direction)

    for _, __plr in workspace.Alive:GetChildren() do
        if __plr.Name ~= __localplayer.Name and __plr.PrimaryPart then
            local __direction = (__plr.PrimaryPart.Position - __camera.CFrame.Position).Unit
            local __dot = __pointer.LookVector:Dot(__direction)

            if __dot > __min_dot then
                __min_dot = __dot
                __closest = __plr
            end
        end
    end

    return __closest
end


function __refs.__funcs.__get_curve()
    local __root = __localplayer.Character and __localplayer.Character.PrimaryPart

    if not __root then
        return __camera.CFrame
    end

    local __closest, __plrPart = __refs.__funcs.__closest_to_cursor()

    if __closest and __closest.PrimaryPart then
        __plrPart = __closest.PrimaryPart
    end

    local __pos = __plrPart and __plrPart.Position or (__root.Position + __camera.CFrame.LookVector * 100)
    local __direction = (__pos - __root.Position).Unit

    local __curve = __refs.__cache.__mode:lower()

    if __curve == 'camera' then
        return __camera.CFrame
    elseif __curve == 'random' then
        local __offsets

        repeat
            __offsets = Vector3.new(
                math.random(-4000, 4000),
                math.random(-4000, 4000),
                math.random(-4000, 4000)
            )
        until __direction:Dot(__pos + __offsets - __root.Positiin).Unit < 0.95

        return CFrame.new(__root.Position, __pos + __offsets)
    elseif __curve == 'accelerated' then
        return CFrame.new(__root.Position, __pos + Vector3.new(0, 5, 0))
    elseif __curve == 'backwards' then
        local __backwards = -__pos

        return CFrame.new(__camera.CFrame.Position, __root.Position + __backwards * 10000 + Vector3.new(0, 1000, 0))
    elseif __curve == 'slow' then
        return CFrame.new(__root.Position, __pos + Vector3.new(0, -9e18, 0))
    end

    return CFrame.new(__root.Position, __pos + Vector3.new(0, 9e18, 0))
end


function __refs.__funcs.__parry()
    local __location = __mouse:GetMouseLocation()
    local __vector2 = {__location.X, __location.Y}
    local __curve = __refs.__funcs.__get_curve()

    local __points = {}

    for _, __entity in workspace.Alive:GetChildren() do
        if __entity.PrimaryPart then
            local __sucess, __point = pcall(function()
                return __camera:WorldToScreenPoint(__entity.PrimaryPart.Position)
            end)

            if __sucess then
                __points[__entity.Name] = __point
            end
        end
    end

    if not __refs.__cache.__first_parry then
        __refs.__cache.__first_parry = true
        return __pf()
    end

    local __target = __is_mobile and {__camera.ViewportSize.X / 2, __camera.ViewportSize.Y / 2} or __vector2

    for __remote, __args in __remotes do
        local __modified = {
            __args[1],
            __args[2],
            __args[3],
            __curve,
            __points,
            __target,
            __args[7]
        }

        if __remote:IsA('RemoteEvent') then
            __remote:FireServer(unpack(__modified))
        elseif __remote:IsA('RemoteFunction') then
            __remote:InvokeServer(unpack(__modified))
        end
    end

    if __refs.__cache.__parries > 10000 then
        return
    end

    __refs.__cache.__parries += 1

    task.delay(0.5, function()
        if __refs.__cache.__parries > 0 then
            __refs.__cache.__parries -= 1
        end
    end)
end

function __refs.__funcs.__keypress()
    if __refs.__cache.__parries > 10000 or not workspace.Alive:FindFirstChild(__localplayer.Name) then
        return
    end

    __pf()

    if __refs.__cache.__parries > 10000 then
        return
    end

    __refs.__cache.__parries += 1

    task.delay(0.5, function()
        if __refs.__cache.__parries > 0 then
            __refs.__cache.__parries -= 1
        end
    end)
end


function __refs.__detection.__predict(a, b, __time)
    return a + (b - a) * __time
end

function __refs.__detection.__is_curved()
    local __ball_props = __refs.__detection.__ball_props
    local __ball = __refs.__funcs.__get_ball()

    if not __ball then
        return false
    end

    local __zoomies = __ball:FindFirstChild('zoomies')

    if not __zoomies then
        return false
    end

    local __velocity = __zoomies.VectorVelocity
    local __ball_direction = __velocity.Unit

    local __direction = (__localplayer.Character.PrimaryPart.Position - __ball.Position).Unit
    local __dot = __direction:Dot(__ball_direction)

    local __speed = __velocity.Magnitude
    local __speed_threshold = math.min(__speed / 100, 40)

    local __direction_difference = (__ball_direction - __velocity).Unit
    local __direction_similarity = __direction:Dot(__direction_difference)

    local __dot_difference = __dot - __direction_similarity
    local __distance = (__localplayer.Character.PrimaryPart.Position - __ball.Position).Magnitude

    local __ping = __stats.Network.ServerStatsItem['Data Ping']:GetValue()

    local __dot_threshold = 0.5 - (__ping / 1000)
    local __reach_time = __distance / __speed - (__ping / 1000)

    local __ball_distance_threshold = 15 - math.min(__distance / 1000, 15) + __speed_threshold

    local __clamped_dot = math.clamp(__dot, -1, 1)
    local __radians = math.rad(math.asin(__clamped_dot))

    __ball_props.__lerp_radians = __refs.__detection.__linear_predict(__ball_props.__lerp_radians, __radians, 0.8)

    if __speed > 0 and __reach_time > __ping / 10 then
        __ball_distance_threshold = math.max(__ball_distance_threshold - 15, 15)
    end

    if __distance < __ball_distance_threshold then
        return false
    end

    if __dot_difference < __dot_threshold then
        return true
    end

    if __ball_props.__lerp_radians < 0.018 then
        __ball_props.__last_warping = tick()
    end

    if (tick() - __ball_props.__last_warping) < (__reach_time / 1.5) then
        return true
    end

    if (tick() - __ball_props.__curving) < (__reach_time / 1.5) then
        return true
    end

    return __dot < __dot_threshold
end

-- // library
local __fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()

local __window = __fluent:CreateWindow({
    Title = 'UwU Testes Gozadores',
    SubTitle = "by Beto",
    Search = true,
    Icon = 'sword',
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Grape",
    MinimizeKey = Enum.KeyCode.LeftControl,
    UserInfo = false,
})

__library:CreateMinimizer({
  Icon = 'sword',
  Size = UDim2.fromOffset(44, 44),
  Position = UDim2.fromOffset(15, 0),
  Acrylic = true,
  Corner = 10,
  Transparency = 1,
  Draggable = true,
  Visible = true
})

do
    local __main = __window:AddTab({Title = 'Main', Icon = 'sword'})

    local __drop = __main:AddDropdown("Dropdown", {
        Title = "curves",
        Values = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'},
        Description = 'escolhe a porra'
        Multi = false,
        Search = false,
        Default = 1,
        Callback = function(__val)
            __refs.__cache.__mode = __val
        end
    })

    local __curves = {
        {key = Enum.KeyCode.One, name = "Camera"},
        {key = Enum.KeyCode.Two, name = "Random"},
        {key = Enum.KeyCode.Three, name = "Accelerated"},
        {key = Enum.KeyCode.Four, name = "Backwards"},
        {key = Enum.KeyCode.Five, name = "Slow"},
        {key = Enum.KeyCode.Six, name = "High"}
    }

    __inputservice.InputBegan:Connect(function(__input, __event)
        if __event then
            return
        end

        for _, __curve in __curves do
            if __input.KeyCode == __curve.key then
                __drop:SetValue(__curve.name)
                break
            end
        end
    end)

    __main:AddSlider("Slider", {
        Title = "accuracy",
        Description = "só muda a porra",
        Default = 1,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(__val)
            __refs.__cache.__accuracy = 0.75 + (tonumber(__val) - 1) * (3 / 99)
        end
    })

    __main:AddToggle('', {
        Title = 'Ap',
        Default = false,
        Callback = function(__val)
            __refs.__cache.__auto_spam_enabled = __val
        end
    })
end

RunService.PreSimulation:Connect(function()
    if not __refs.__cache.__autoparry.__enabled or not __localplayer.Character or not __localplayer.Character.PrimaryPart then
        return
    end

    local __balls = __refs.__funcs.__get_balls()
    local __ball = __refs.__funcs.__get_ball()

    local __train_ball

    for _, __obj in workspace.TrainingBalls:GetChildren() do
        if __obj:GetAttribute("realBall") then
            __train_ball = __obj break
        end
    end

    for _, __obj in __balls do
        if __refs.__cache.__triggerbot.__enabled or __refs.__cache.__dupe_ball then
            return
        end

        if not ball then
            continue
        end

        local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then continue end
            
            ball:GetAttributeChangedSignal('target'):Once(function()
                System.__properties.__parried = false
            end)
            
            if System.__properties.__parried then continue end
            
            local ball_target = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            
            local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            
            local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
            local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            
            local curved = System.detection.is_curved()
            
            if ball:FindFirstChild('AeroDynamicSlashVFX') then
                ball.AeroDynamicSlashVFX:Destroy()
                System.__properties.__tornado_time = tick()
            end
            
            if Runtime:FindFirstChild('Tornado') then
                if (tick() - System.__properties.__tornado_time) < 
                   (Runtime.Tornado:GetAttribute('TornadoTime') or 1) + 0.314159 then
                    continue
                end
            end
            
            if one_ball and one_ball:GetAttribute('target') == LocalPlayer.Name and curved then
                continue
            end
            
            if ball:FindFirstChild('ComboCounter') then continue end
            
            if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            
            if System.__config.__detections.__infinity and System.__properties.__infinity_active then continue end
            if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then continue end
            if System.__config.__detections.__timehole and System.__properties.__timehole_active then continue end
            if System.__config.__detections.__slashesoffury and System.__properties.__slashesoffury_active then continue end
            
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().CooldownProtection then
                    local ParryCD = LocalPlayer.PlayerGui.Hotbar.Block.UIGradient
                    if ParryCD.Offset.Y < 0.4 then
                        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                        continue
                    end
                end
                
                if getgenv().AutoAbility then
                    local AbilityCD = LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient
                    if AbilityCD.Offset.Y == 0.5 then
                        if LocalPlayer.Character.Abilities:FindFirstChild("Raging Deflection") and LocalPlayer.Character.Abilities["Raging Deflection"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Rapture") and LocalPlayer.Character.Abilities["Rapture"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Calming Deflection") and LocalPlayer.Character.Abilities["Calming Deflection"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Aerodynamic Slash") and LocalPlayer.Character.Abilities["Aerodynamic Slash"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Fracture") and LocalPlayer.Character.Abilities["Fracture"].Enabled or
                           LocalPlayer.Character.Abilities:FindFirstChild("Death Slash") and LocalPlayer.Character.Abilities["Death Slash"].Enabled then
                            System.__properties.__parried = true
                            ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                            task.wait(2.432)
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
                            continue
                        end
                    end
                end
            end
            
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().AutoParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute_action()
                end
                System.__properties.__parried = true
            end
            
            local last_parrys = tick()
            repeat
                RunService.Stepped:Wait()
            until (tick() - last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
        end

        if training_ball then
            local zoomies = training_ball:FindFirstChild('zoomies')
            if zoomies then
                training_ball:GetAttributeChangedSignal('target'):Once(function()
                    System.__properties.__training_parried = false
                end)
                
                if not System.__properties.__training_parried then
                    local ball_target = training_ball:GetAttribute('target')
                    local velocity = zoomies.VectorVelocity
                    local distance = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local speed = velocity.Magnitude
                    
                    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
                    local ping_threshold = math.clamp(ping / 10, 5, 17)
                    
                    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
                    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
                    local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
                    
                    if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                        if getgenv().AutoParryMode == "Keypress" then
                            System.parry.keypress()
                        else
                            System.parry.execute_action()
                        end
                        System.__properties.__training_parried = true
                        
                        local last_parrys = tick()
                        repeat
                            RunService.Stepped:Wait()
                        until (tick() - last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried = false
                    end
                end
            end
        end
    end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if root.Parent and root.Parent ~= LocalPlayer.Character then
        if not Alive or root.Parent.Parent ~= Alive then
            return
        end
    end
    
    local closest = System.player.get_closest()
    local ball = System.ball.get()
    
    if not ball or not closest then return end
    
    local target_distance = (LocalPlayer.Character.PrimaryPart.Position - closest.PrimaryPart.Position).Magnitude
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(ball.AssemblyLinearVelocity.Unit)
    
    local curve_detected = System.detection.is_curved()
    
    if target_distance < 15 and distance < 15 and dot > -0.25 then
        if curve_detected then
            System.parry.execute_action()
        end
    end
    
    if System.__properties.__grab_animation then
        System.__properties.__grab_animation:Stop()
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if not Alive or LocalPlayer.Character.Parent ~= Alive then
        return
    end
    
    if System.__properties.__grab_animation then
        System.__properties.__grab_animation:Stop()
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(a, b)
    local Primary_Part = LocalPlayer.Character.PrimaryPart
    local Ball = System.ball.get()

    if not Ball then
        return
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return
    end

    local Speed = Zoomies.VectorVelocity.Magnitude

    local Distance = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Velocity = Zoomies.VectorVelocity

    local Ball_Direction = Velocity.Unit

    local Direction = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Pings = Stats.Network.ServerStatsItem['Data Ping']:GetValue()

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 1
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    if b ~= Primary_Part and Distance > Ball_Distance_Threshold then
        System.detection.__ball_properties.__curving = tick()
    end
end)
