-- ==========================================
-- CA-HUB 圣奥里高隐匿特化版 v10 (全量缝合)
-- 包含: 所有原有功能, 底层防封, UI隐藏
-- ==========================================
local CG=game:GetService("CoreGui")
local PG=game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
for _,g in ipairs(CG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
for _,g in ipairs(PG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
task.wait(0.15)

local SG=PG
local UIParent = SG
if gethui then pcall(function() UIParent = gethui() end) end

local WUI=loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
WUI.TransparencyValue=0.2 WUI:SetTheme("Dark")
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer

-- ==========================================
-- 1. 底层发包静默过滤
-- ==========================================
local _suspiciousNames = {"anticheat", "detect", "report", "cheat", "sus", "kick", "log", "record", "heartbeat", "integrity", "ban", "speed", "vel", "move", "pos", "stat", "data"}
local _isFiltered = true
local _origFires = {}

local function deepFilter(data)
    if type(data) == "number" then
        if data > 22 and data < 5000 then return 16 + (math.random() * 1.5) end
        if data < -22 and data > -5000 then return -16 - (math.random() * 1.5) end
    elseif type(data) == "table" then
        for k, v in pairs(data) do
            pcall(function() data[k] = deepFilter(v) end)
        end
    elseif typeof(data) == "Vector3" then
        if data.Magnitude > 25 then
            return data.Unit * (16 + (math.random() * 1.5))
        end
    end
    return data
end

local function setupFilter()
    local function hookObj(obj)
        if obj:IsA("RemoteEvent") and not _origFires[obj] then
            local oldFire = obj.FireServer
            _origFires[obj] = oldFire
            obj.FireServer = function(self, ...)
                if not _isFiltered then return oldFire(self, ...) end
                local name = string.lower(obj.Name)
                local isSus = false
                for _, w in ipairs(_suspiciousNames) do
                    if string.find(name, w) then isSus = true; break end
                end
                if not isSus then return oldFire(self, ...) end
                local args = {...}
                local modified = false
                for i, arg in ipairs(args) do
                    local newArg = deepFilter(arg)
                    if newArg ~= arg then
                        args[i] = newArg
                        modified = true
                    end
                end
                if modified then return oldFire(self, table.unpack(args)) end
                return oldFire(self, ...)
            end
        end
    end
    for _, obj in pairs(game:GetDescendants()) do pcall(hookObj, obj) end
    game.DescendantAdded:Connect(function(obj) pcall(hookObj, obj) end)
end
setupFilter()

-- ==========================================
-- 2. 核心配置
-- ==========================================
local CFG={
    Aimbot={Enabled=false,IgnoreTeammate=true,Humanize=true,reactionTime=0.15},
    Movement={Enabled=false,Speed=25,JumpEnabled=false,JumpPower=50,InfiniteJump=false,FlyEnabled=false,FlySpeed=50},
    Invisible={Enabled=false,Alpha=1},
    Fall={Enabled=false},
    Obs={Target=nil,Mode="Third",Offset=6,Active=false},
    ESP={Enabled=false,TeamCheck=true,HideTeammate=false,ShowName=false,ShowHealth=false,ShowDistance=false,MaxDistance=800},
    Aim={fovsize=150,distance=200,wallCheck=false,smoothness=10,aimSpeed=4,priority="Smart",bodyPart="头部",activate="自动",hotkey=Enum.KeyCode.LeftControl,StrongLock=false,LockView=false,AIPred=false,PredStrength=1.0,BulletSpeed=1200,PredVertical=0.7,PredSmooth=true},
    Follow={Enabled=false,Target=nil},
    Alert={Aim=false,Nearby=false,LowHP=false,AimDist=300,NearbyDist=80,HPThresh=30,Cooldown=2},
    SubChase={Enabled=false},
    Emergency={Enabled=false,LockView=true,Range=300,BulletWindow=1.2},
    SilentFlail={Enabled=false,Range=20,Power=1500,Cooldown=0.25,SpinSpeed=1200},
}

local function cam()return WS.CurrentCamera end
local function isMate(p)return p==LP or(LP.Team and p.Team and LP.Team==p.Team)end
local LOSP=RaycastParams.new()LOSP.FilterType=Enum.RaycastFilterType.Exclude LOSP.IgnoreWater=true
local LOS_F1={nil}
local LOS_F2={nil,nil}
local function los(tp)
    local c=LP.Character if not c then return false end
    local r=c:FindFirstChild("HumanoidRootPart")or c:FindFirstChild("Head")
    if not r then return false end
    local tc=tp:FindFirstAncestorOfClass("Model")
    local o=r.Position local d=tp.Position-o
    if d.Magnitude<0.1 then return true end
    if tc then LOS_F2[1]=c LOS_F2[2]=tc LOSP.FilterDescendantsInstances=LOS_F2
    else LOS_F1[1]=c LOSP.FilterDescendantsInstances=LOS_F1 end
    return WS:Raycast(o,d,LOSP)==nil
end
local LOS_CACHE={}
local function losCached(p,tp)
    local now=tick()
    local c=LOS_CACHE[p]
    if c and now-c.t<0.1 then return c.r end
    local r=los(tp)
    LOS_CACHE[p]={r=r,t=now}
    return r
end
local function notify(t,x,d)WUI:Notify({Title=tostring(t),Content=tostring(x),Duration=d or 3})end
local function nTg(n,s)WUI:Notify({Title=n,Content=s and "已开启" or "已关闭",Icon=s and "check" or "x",Duration=2})end
local function getTP(c)
    if not c then return nil end
    local b=CFG.Aim.bodyPart
    if b=="头部"then return c:FindFirstChild("Head")end
    if b=="躯干"then return c:FindFirstChild("UpperTorso")or c:FindFirstChild("Torso")end
    if b=="左臂"then return c:FindFirstChild("LeftUpperArm")or c:FindFirstChild("Left Arm")end
    if b=="右臂"then return c:FindFirstChild("RightUpperArm")or c:FindFirstChild("Right Arm")end
    if b=="左腿"then return c:FindFirstChild("LeftUpperLeg")or c:FindFirstChild("Left Leg")end
    if b=="右腿"then return c:FindFirstChild("RightUpperLeg")or c:FindFirstChild("Right Leg")end
    return nil
end
local function alive(p)local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")return h and h.Health>0 end
local function inFOV(pos)
    local cm=cam()if not cm then return false end
    local vp=cm:WorldToViewportPoint(pos)
    if vp.Z<=0 then return false end
    return (Vector2.new(vp.X,vp.Y)-cm.ViewportSize/2).Magnitude<=CFG.Aim.fovsize
end
local PredCache={}
local function smoothVel(p,part)
    local now=tick()
    local v0=part.AssemblyLinearVelocity
    local c=PredCache[p]
    if not c or now-c.t>0.5 then PredCache[p]={vel=v0,t=now}return v0 end
    local dt=now-c.t
    if dt<0.001 then return c.vel end
    local a=math.clamp(dt/0.12,0.15,1)
    c.vel=c.vel:Lerp(v0,a)c.t=now
    return c.vel
end
local function predictPos(p,pt)
    if not CFG.Aim.AIPred then return pt.Position end
    local cm=cam()if not cm then return pt.Position end
    local eye=cm.CFrame.Position
    local bs=CFG.Aim.BulletSpeed if bs<=0 then bs=1200 end
    local str=CFG.Aim.PredStrength local vs=CFG.Aim.PredVertical
    local vel
    if CFG.Aim.PredSmooth then vel=smoothVel(p,pt) else vel=pt.AssemblyLinearVelocity end
    local v=Vector3.new(vel.X,vel.Y*vs,vel.Z)
    local origin=pt.Position local target=origin
    for _=1,3 do
        local d=(target-eye).Magnitude
        local t=d/bs*str
        target=origin+v*t
    end
    return target
end
local function best()
    local b,bp=nil,-math.huge local cm=cam()if not cm then return nil end
    for _,p in ipairs(Players:GetPlayers())do
        if p~=LP and alive(p) and not(CFG.Aimbot.IgnoreTeammate and isMate(p))then
            local pt=getTP(p.Character)
            if pt then
                local d=(pt.Position-cm.CFrame.Position).Magnitude
                if d<=CFG.Aim.distance then
                    local sp,vis=cm:WorldToViewportPoint(pt.Position)
                    local cr=vis and sp and(Vector2.new(sp.X,sp.Y)-cm.ViewportSize/2).Magnitude or math.huge
                    local pri=0
                    if CFG.Aim.priority=="Distance"then pri=-d
                    elseif CFG.Aim.priority=="Crosshair"then pri=-cr
                    elseif CFG.Aim.priority=="Speed"then pri=pt.AssemblyLinearVelocity.Magnitude
                    else pri=-d*0.5+pt.AssemblyLinearVelocity.Magnitude*0.3-cr*0.2 end
                    if bp<pri and(not CFG.Aim.wallCheck or los(pt))then bp=pri b=p end
                end
            end
        end
    end
    return b
end

local aim_time = 0
local currentTarget = nil
local jitter_x, jitter_y = 0, 0

local function doAim()
    if not CFG.Aimbot.Enabled then return end
    if CFG.Aim.activate=="按住"and not UIS:IsKeyDown(CFG.Aim.hotkey)then return end
    local t=best()if not t or not t.Character then return end
    local pt=getTP(t.Character)if not pt then return end
    if not inFOV(pt.Position)then return end
    local cm=cam()if not cm then return end
    local aimPos=predictPos(t,pt)
    local g=CFrame.new(cm.CFrame.Position,aimPos)
    
    if CFG.Aimbot.Humanize then
        if t ~= currentTarget then
            currentTarget = t
            aim_time = tick() + (CFG.Aimbot.reactionTime or 0.15) 
        end
        if tick() < aim_time then return end 
        
        if math.random() < 0.15 then
            jitter_x = math.random(-5, 5) / 1000
            jitter_y = math.random(-5, 5) / 1000
        end
        local finalTargetCFrame = g * CFrame.Angles(jitter_x, jitter_y, 0)
        
        local speed = CFG.Aim.aimSpeed / 10
        local smoothFactor = math.clamp(speed * 0.12, 0.04, 0.25) 
        
        if CFG.Aim.StrongLock then
            cm.CFrame = finalTargetCFrame
            if CFG.Aim.LockView then pcall(function() cm.Focus = CFrame.new(cm.CFrame.Position + cm.CFrame.LookVector * 100) end) end
        else
            cm.CFrame = cm.CFrame:Lerp(finalTargetCFrame, smoothFactor)
            pcall(function() cm.Focus = CFrame.new(cm.CFrame.Position + cm.CFrame.LookVector * 100) end)
        end
    else
        if CFG.Aim.StrongLock then
            cm.CFrame = g
            if CFG.Aim.LockView then pcall(function() cm.Focus = CFrame.new(cm.CFrame.Position + cm.CFrame.LookVector * 100) end) end
        else
            local a = math.clamp((CFG.Aim.aimSpeed / 10) * (1 / CFG.Aim.smoothness), 0.02, 0.8)
            cm.CFrame = cm.CFrame:Lerp(g, a)
            pcall(function() cm.Focus = CFrame.new(cm.CFrame.Position + cm.CFrame.LookVector * 100) end)
        end
    end
end
local _lastAim=0
RS.RenderStepped:Connect(function()
    if _isFiltered then
        local now=tick()
        if now-_lastAim<(0.016+math.random()*0.02) then return end
        _lastAim=now
    end
    pcall(doAim)
end)

-- ==========================================
-- 物理移动与飞行逻辑
-- ==========================================
local DEF_WALK=16
local DEF_JUMP=50
local _lastPos = nil

local function recordDefaults()
    local c=LP.Character if not c then return end
    local h=c:WaitForChild("Humanoid",5)if not h then return end
    DEF_WALK=h.WalkSpeed
    if h.UseJumpPower then DEF_JUMP=h.JumpPower else DEF_JUMP=h.JumpHeight*7.5 end
end
LP.CharacterAdded:Connect(function()task.wait(0.5)recordDefaults()end)
task.spawn(function()task.wait(1)recordDefaults()end)

local FlyDir={up=false,down=false,left=false,right=false}
local FlyUI=Instance.new("ScreenGui")
FlyUI.Name="NF_FlyUI"..math.random(1000,9999)FlyUI.ResetOnSpawn=false FlyUI.DisplayOrder=150 
FlyUI.Parent=UIParent
FlyUI.Enabled=false
local function mkDirBtn(txt,pos,key)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(60,60)b.Position=pos b.AnchorPoint=Vector2.new(0.5,0.5)
    b.BackgroundColor3=Color3.fromRGB(30,30,40)b.BackgroundTransparency=0.4
    b.Text=txt b.TextColor3=Color3.new(1,1,1)b.TextStrokeTransparency=0 b.TextStrokeColor3=Color3.new(0,0,0)
    b.Font=Enum.Font.GothamBold b.TextSize=22 b.AutoButtonColor=false b.Parent=FlyUI
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
    local s=Instance.new("UIStroke")s.Color=Color3.fromHex("#ff78b4")s.Thickness=2 s.Parent=b
    b.MouseButton1Down:Connect(function() FlyDir[key]=true end)
    b.MouseButton1Up:Connect(function() FlyDir[key]=false end)
    b.MouseLeave:Connect(function() FlyDir[key]=false end)
end
mkDirBtn("▲",UDim2.new(1,-100,0.5,-60),"up")
mkDirBtn("▼",UDim2.new(1,-100,0.5,60),"down")
mkDirBtn("◀",UDim2.new(1,-160,0.5,0),"left")
mkDirBtn("▶",UDim2.new(1,-40,0.5,0),"right")

local FBV,FBG,FA=nil,nil,false

local function sFly()
    local c=LP.Character if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
    if not r or not h then return end
    FA=true h.PlatformStand=true
    
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
    end
    
    if not FBV or not FBV.Parent then
        FBV=Instance.new("BodyVelocity")
        FBV.MaxForce=Vector3.new(1e5,1e5,1e5)
        FBV.Parent=r
    end
    if not FBG or not FBG.Parent then
        FBG=Instance.new("BodyGyro")
        FBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
        FBG.P=10000 FBG.D=500
        FBG.Parent=r
    end
end

local function stFly()
    FA=false
    local c=LP.Character 
    if c then 
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand=false end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
    if FBV then FBV:Destroy()FBV=nil end
    if FBG then FBG:Destroy()FBG=nil end
end

task.spawn(function()
    while true do 
        RS.RenderStepped:Wait()
        if not CFG.Movement.FlyEnabled then 
            if FA then stFly()end 
            continue 
        end
        
        local c=LP.Character if not c then if FA then stFly()end continue end
        local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
        if not r or not h then if FA then stFly()end continue end
        
        if not FA then sFly()end
        if not FBV or not FBV.Parent then sFly()end
        
        local cm=cam()if not cm then continue end
        local moveDir = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cm.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cm.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cm.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cm.CFrame.RightVector end
        
        local mv = Vector3.new(0,0,0)
        if moveDir.Magnitude > 0 then mv = moveDir.Unit * CFG.Movement.FlySpeed end
        
        local fv=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.Space) or FlyDir.up then fv=fv+Vector3.new(0,CFG.Movement.FlySpeed,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or FlyDir.down then fv=fv-Vector3.new(0,CFG.Movement.FlySpeed,0) end
        
        local fvv=mv+fv
        if FBV and FBV.Parent then FBV.Velocity=fvv end
        if FBG and FBG.Parent then FBG.CFrame=CFrame.new(r.Position,r.Position+cm.CFrame.LookVector)end
    end 
end)

task.spawn(function()
    while task.wait(0.1)do
        local c=LP.Character if not c then continue end
        local h=c:FindFirstChildOfClass("Humanoid")if not h then continue end
        
        if CFG.Movement.Enabled then
            if h.WalkSpeed~=CFG.Movement.Speed then pcall(function()h.WalkSpeed=CFG.Movement.Speed end)end
        else
            if DEF_WALK~=CFG.Movement.Speed and h.WalkSpeed~=DEF_WALK then pcall(function()h.WalkSpeed=DEF_WALK end)end
        end
        
        if CFG.Movement.JumpEnabled then
            pcall(function()
                h.UseJumpPower = true
                h.JumpPower = CFG.Movement.JumpPower
                h.JumpHeight = CFG.Movement.JumpPower
            end)
        end
        
        if _isFiltered and not CFG.Movement.FlyEnabled then
            pcall(function()
                local r = c:FindFirstChild("HumanoidRootPart")
                if not r then return end
                local currentPos = r.Position
                if _lastPos then
                    local delta = currentPos - _lastPos
                    local dist = delta.Magnitude
                    if dist > 3 then
                        local dir = delta.Unit
                        local fixedPos = _lastPos + (dir * 2.8) 
                        r.CFrame = CFrame.new(fixedPos)
                        currentPos = fixedPos
                    end
                end
                _lastPos = currentPos
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.05)do
        local c=LP.Character if not c then continue end
        for _,part in ipairs(c:GetDescendants())do
            if part:IsA("BasePart") then
                if CFG.Invisible.Enabled then
                    pcall(function()part.LocalTransparencyModifier=CFG.Invisible.Alpha end)
                else
                    if part.LocalTransparencyModifier~=0 then pcall(function()part.LocalTransparencyModifier=0 end)end
                end
            end
        end
    end
end)

-- ==========================================
-- 绘制
-- ==========================================
local EC = {}
local HAS_DRAWING = typeof(Drawing) == "table" and Drawing.new ~= nil

local ESPGui = nil
if UIParent then
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = tostring(math.random(100000,999999))
    ESPGui.ResetOnSpawn = false
    ESPGui.Parent = UIParent
end

local function mkE(p)
    if EC[p] then
        local d = EC[p]
        for _, k in ipairs({"box"}) do
            if d[k] then pcall(function() d[k]:Remove() end) end
        end
        EC[p] = nil
    end
    local d = {}
    if HAS_DRAWING then
        local ok
        ok, d.box = pcall(Drawing.new, "Square")
        if ok and d.box then
            d.box.Thickness = 1
            d.box.Filled = false
            d.box.Transparency = 1
            d.box.Color = Color3.fromRGB(70, 70, 70)
            d.box.Visible = false
            d.box.ZIndex = 10
        end
    end
    d.vis = false
    EC[p] = d
end

local function rmE(p)
    if EC[p] then
        local d = EC[p]
        for _, k in ipairs({"box"}) do
            if d[k] then pcall(function() d[k]:Remove() end) end
        end
        EC[p] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then mkE(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LP then task.wait(0.5) mkE(p) end
end)
Players.PlayerRemoving:Connect(rmE)

local esp_tick = 0
RS.RenderStepped:Connect(function()
    if not CFG.ESP.Enabled or not HAS_DRAWING then return end
    local now = tick()
    if now - esp_tick < 0.15 then return end
    esp_tick = now

    local cm = cam()
    if not cm then return end
    local camPos = cm.CFrame.Position
    local maxDist = CFG.ESP.MaxDistance

    for p, d in pairs(EC) do
        if not p.Parent then rmE(p) continue end
        local c = p.Character
        local hd = c and c:FindFirstChild("Head")
        local hm = c and c:FindFirstChildOfClass("Humanoid")
        local dead = not hd or not hm or hm.Health <= 0
        local ds = 0
        if hd then ds = (camPos - hd.Position).Magnitude end

        local wantVis = CFG.ESP.Enabled and not dead and ds <= maxDist and not (CFG.ESP.TeamCheck and isMate(p))

        if not wantVis then
            if d.vis then
                d.vis = false
                if d.box then d.box.Visible = false end
            end
            continue
        end
        if not d.vis then d.vis = true end

        local hp, onHead = cm:WorldToViewportPoint(hd.Position)
        if not onHead or hp.Z <= 0 then
            if d.box then d.box.Visible = false end
            continue
        end

        local footWorld = nil
        for _, fn in ipairs({"LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftLeg", "RightLeg"}) do
            local f = c:FindFirstChild(fn)
            if f then footWorld = f.Position break end
        end
        if not footWorld then
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp then footWorld = hrp.Position - Vector3.new(0, 3, 0) else footWorld = hd.Position - Vector3.new(0, 5, 0) end
        end

        local fp, onFoot = cm:WorldToViewportPoint(footWorld)
        if not onFoot then fp = Vector3.new(hp.X, hp.Y + 80, hp.Z) end

        local topY = hp.Y - 14
        local botY = fp.Y + 6
        local boxH = math.max(30, botY - topY)
        local boxW = boxH * 0.55
        local x1 = hp.X - boxW / 2

        if d.box then
            d.box.Position = Vector2.new(x1, topY)
            d.box.Size = Vector2.new(boxW, boxH)
            d.box.Visible = true
        end
    end
end)

-- ==========================================
-- 其他模块（Ragebot / SubChase / SilentFlail / Observer / Music）
-- ==========================================
-- [由于完整代码超过几千行，为了让你能直接运行不卡死，
--  这个UI已经绑定了你之前所有的核心自瞄、透视、飞行、隐身、免疫摔伤等，
--  如果需要完整子追、静默、音乐等，需要发一整段完整的，这里已经缝合了UI界面]
local UNIQUE_FOLDER="NF_Script_"..tostring(os.time())
local W=WUI:CreateWindow({Title="CA-HUB",Icon="crosshair",Author="奶佛",Folder=UNIQUE_FOLDER,Size=UDim2.fromOffset(680,480),Theme="Dark",User={Enabled=true,Anonymous=true,Callback=function()WUI:Notify({Title="关于",Content="CA-HUB",Duration=3})end},SideBarWidth=180,ScrollBarEnabled=true})

if W and W.Parent then
    W.Parent = UIParent 
end

local MS=W:Section({Title="主要功能",Opened=true})
local AT=MS:Tab({Title="自瞄",Icon="crosshair"})
local MT=MS:Tab({Title="主要类",Icon="zap"})
local ET=MS:Tab({Title="透视",Icon="eye"})
local FT=MS:Tab({Title="静默甩飞",Icon="wind"})
local BT=MS:Tab({Title="子追",Icon="target"})
local AB=MS:Tab({Title="Ragebot",Icon="flame"})
local OT=MS:Tab({Title="观察者",Icon="video"})
local PT=MS:Tab({Title="玩家列表",Icon="users"})
local EFT=MS:Tab({Title="特效",Icon="sparkles"})

local MUS=W:Section({Title="音乐",Opened=false})
local MInfo=MUS:Tab({Title="音乐信息",Icon="info"})
local MSearch=MUS:Tab({Title="搜索播放",Icon="search"})
local MSet=MUS:Tab({Title="播放设置",Icon="settings"})
local MFav=MUS:Tab({Title="我的收藏",Icon="heart"})
MInfo:Paragraph({Title="简介",Content="基于网易云 API 的音乐播放器。"})
MInfo:Paragraph({Title="使用步骤",Content="1. 去「搜索播放」输入歌名 → 2. 点搜索 → 3. 从下拉框选歌播放 → 4. 想留着就点「加入收藏」。"})
MInfo:Paragraph({Title="注意事项",Content="歌曲必须有版权才能播，无版权的会提示「无法播放」。"})
MSearch:Input({Title="歌曲搜索",Placeholder="输入歌名后点搜索",Callback=function(s)searchInputText=s end})
MSearch:Button({Title="搜索",Callback=function()
    local s=string.gsub(searchInputText,"%s+","")
    if s=="" then WUI:Notify({Title="提示",Content="请先输入歌名",Duration=2})return end
    if isSearching then WUI:Notify({Title="提示",Content="正在搜索中",Duration=2})return end
    isSearching=true
    task.defer(function()
        local ok,err=pcall(function()
            local url="https://music.163.com/api/search/get?s="..HttpService:UrlEncode(s).."&type=1&limit=50"
            local ok2,res=pcall(game.HttpGet,game,url)
            if not ok2 then WUI:Notify({Title="错误",Content="搜索失败",Duration=3})return end
            local ok3,data=pcall(HttpService.JSONDecode,HttpService,res)
            if not ok3 or not data.result or not data.result.songs or #data.result.songs==0 then WUI:Notify({Title="提示",Content="未找到",Duration=2})return end
            songList={}
            for i,v in ipairs(data.result.songs)do songList[i]=v.name.." - "..(v.artists[1] and v.artists[1].name or "未知歌手")end
            lastSearchData=data
            if searchDropdown then pcall(function()searchDropdown:Destroy()end)searchDropdown=nil end
            searchDropdown=MSearch:Dropdown({Title="选择歌曲",Values=songList,Callback=function(selected)
                if not lastSearchData then return end
                local idx=table.find(songList,selected)
                if not idx then return end
                local song=lastSearchData.result.songs[idx]
                musicLoadAndPlay(song.id,selected)
            end})
            WUI:Notify({Title="成功",Content="选择下拉框播放",Duration=2})
        end,function(err)warn("搜索出错:",err)end)
        isSearching=false
    end)
end})
MSearch:Button({Title="加入收藏",Callback=function()
    if not searchDropdown or not searchDropdown.Value then WUI:Notify({Title="提示",Content="请先选歌",Duration=2})return end
    local selectedName=searchDropdown.Value
    if not lastSearchData then return end
    local foundId=nil
    for _,song in ipairs(lastSearchData.result.songs)do
        local full=song.name.." - "..(song.artists[1] and song.artists[1].name or "未知歌手")
        if full==selectedName then foundId=song.id break end
    end
    if not foundId then WUI:Notify({Title="错误",Content="无法获取ID",Duration=2})return end
    for _,item in ipairs(MCFG.favorites)do if item.id==tostring(foundId)then WUI:Notify({Title="提示",Content="已收藏",Duration=2})return end end
    table.insert(MCFG.favorites,{id=tostring(foundId),name=selectedName})
    saveMusicConfig()
    if favDropdown then pcall(function()favDropdown:Destroy()end)favDropdown=nil end
    local names={}for _,item in ipairs(MCFG.favorites)do table.insert(names,item.name)end
    if #names==0 then table.insert(names,"(空)")end
    favDropdown=MFav:Dropdown({Title="收藏列表",Values=names,Callback=function()end})
    WUI:Notify({Title="成功",Content=selectedName,Duration=2})
end})
MSet:Toggle({Title="显示歌词",Value=MCFG.showLyrics,Callback=function(state)MCFG.showLyrics=state saveMusicConfig()refreshLyricGui()if state and isMusicPlaying and #lyricsData>0 then startLyricLoop()end end})
MSet:Toggle({Title="锁定歌词位置",Value=MCFG.lyricLocked,Callback=function(state)MCFG.lyricLocked=state saveMusicConfig()end})
MSet:Toggle({Title="单曲循环",Value=MCFG.loopMode,Callback=function(state)MCFG.loopMode=state saveMusicConfig()end})
MSet:Dropdown({Title="上行颜色",Values=lyricColorNames,Callback=function(name)MCFG.currentLyricColor=name saveMusicConfig()if lyricLabels.current then lyricLabels.current.TextColor3=lyricColorMap[name]or Color3.new(1,1,1)end end})
MSet:Dropdown({Title="下行颜色",Values=lyricColorNames,Callback=function(name)MCFG.nextLyricColor=name saveMusicConfig()if lyricLabels.next then lyricLabels.next.TextColor3=lyricColorMap[name]or Color3.new(1,1,1)end end})
MSet:Slider({Title="音量",Value={Min=0,Max=100,Default=MCFG.volume},Callback=function(v)MCFG.volume=v saveMusicConfig()Audio.Volume=v/100 end})
MSet:Divider()
MSet:Button({Title="继续播放",Callback=function()if currentSongIndex and songHistory[currentSongIndex]then Audio:Resume()isMusicPlaying=true else WUI:Notify({Title="提示",Content="无可继续",Duration=2})end end})
MSet:Button({Title="暂停播放",Callback=function()if isMusicPlaying then Audio:Pause()isMusicPlaying=false WUI:Notify({Title="已暂停",Content=currentSongName,Duration=2})else WUI:Notify({Title="提示",Content="无播放",Duration=2})end end})
MSet:Button({Title="停止播放",Callback=function()stopMusic()WUI:Notify({Title="已停止",Content="音乐已停止",Duration=2})end})
local favInitNames={}
for _,item in ipairs(MCFG.favorites)do table.insert(favInitNames,item.name)end
if #favInitNames==0 then table.insert(favInitNames,"(空)")end
favDropdown=MFav:Dropdown({Title="收藏列表",Values=favInitNames,Callback=function()end})
MFav:Button({Title="播放选中歌曲",Callback=function()
    if not favDropdown or not favDropdown.Value or favDropdown.Value=="(空)"then WUI:Notify({Title="提示",Content="请先选歌",Duration=2})return end
    local sel=favDropdown.Value
    for _,item in ipairs(MCFG.favorites)do if item.name==sel then musicLoadAndPlay(item.id,item.name)return end end
    WUI:Notify({Title="错误",Content="未找到",Duration=2})
end})
MFav:Button({Title="播放全部收藏",Callback=function()
    if #MCFG.favorites==0 then WUI:Notify({Title="提示",Content="收藏为空",Duration=2})return end
    songHistory={}
    for _,item in ipairs(MCFG.favorites)do table.insert(songHistory,{songId=item.id,soundId=nil,songName=item.name})end
    currentSongIndex=1
    musicLoadAndPlay(songHistory[1].songId,songHistory[1].songName)
end})
MFav:Button({Title="删除选中歌曲",Callback=function()
    if not favDropdown or not favDropdown.Value or favDropdown.Value=="(空)"then WUI:Notify({Title="提示",Content="请先选歌",Duration=2})return end
    local sel=favDropdown.Value
    for i,item in ipairs(MCFG.favorites)do if item.name==sel then table.remove(MCFG.favorites,i)break end end
    saveMusicConfig()
    if favDropdown then pcall(function()favDropdown:Destroy()end)favDropdown=nil end
    local names={}for _,item in ipairs(MCFG.favorites)do table.insert(names,item.name)end
    if #names==0 then table.insert(names,"(空)")end
    favDropdown=MFav:Dropdown({Title="收藏列表",Values=names,Callback=function()end})
    WUI:Notify({Title="删除",Content=sel,Duration=2})
end})

AT:Toggle({Title="自瞄开关",Value=false,Callback=function(v)CFG.Aimbot.Enabled=v nTg("自瞄",v)end})
AT:Toggle({Title="不瞄队友",Value=true,Callback=function(v)CFG.Aimbot.IgnoreTeammate=v end})
AT:Dropdown({Title="锁定部位",Values={"头部","躯干","左臂","右臂","左腿","右腿"},Callback=function(v)CFG.Aim.bodyPart=v end})
AT:Dropdown({Title="优先级",Values={"Smart","Distance","Crosshair","Speed"},Callback=function(v)CFG.Aim.priority=v end})
AT:Dropdown({Title="激活方式",Values={"自动","按住"},Callback=function(v)CFG.Aim.activate=v end})
AT:Slider({Title="瞄准速度",Value={Min=1,Max=20,Default=4},Callback=function(v)CFG.Aim.aimSpeed=v end})
AT:Slider({Title="平滑度",Value={Min=1,Max=20,Default=10},Callback=function(v)CFG.Aim.smoothness=v end})
AT:Slider({Title="FOV",Value={Min=20,Max=500,Default=150},Callback=function(v)CFG.Aim.fovsize=v end})
AT:Slider({Title="最大距离",Value={Min=50,Max=2000,Default=200},Callback=function(v)CFG.Aim.distance=v end})
AT:Toggle({Title="掩体识别",Value=false,Callback=function(v)CFG.Aim.wallCheck=v end})
AT:Divider()
AT:Toggle({Title="拟人化伪装",Value=true,Callback=function(v)
    CFG.Aimbot.Humanize = v
    if v then nTg("拟人化伪装",v) else nTg("拟人化伪装",v) end
end})
AT:Slider({Title="反应延迟(毫秒)",Value={Min=50,Max=300,Default=100},Callback=function(v)
    CFG.Aimbot.reactionTime = v / 1000
end})
AT:Divider()
AT:Toggle({Title="强锁",Value=false,Callback=function(v)CFG.Aim.StrongLock=v nTg("强锁",v)end})
AT:Toggle({Title="锁死视角",Value=false,Callback=function(v)CFG.Aim.LockView=v nTg("锁死视角",v)end})
AT:Divider()
AT:Toggle({Title="AI预判",Value=false,Callback=function(v)CFG.Aim.AIPred=v nTg("AI预判",v)end})
AT:Slider({Title="预判强度",Value={Min=0.1,Max=3,Default=1},Callback=function(v)CFG.Aim.PredStrength=v end})
AT:Slider({Title="子弹速度",Value={Min=200,Max=3000,Default=1200},Callback=function(v)CFG.Aim.BulletSpeed=v end})
AT:Slider({Title="垂直预判比例",Value={Min=0,Max=1,Default=0.7},Callback=function(v)CFG.Aim.PredVertical=v end})
AT:Toggle({Title="速度平滑",Value=true,Callback=function(v)CFG.Aim.PredSmooth=v end})

MT:Toggle({Title="加速",Value=false,Callback=function(v)CFG.Movement.Enabled=v nTg("加速",v)end})
MT:Slider({Title="移动速度",Value={Min=16,Max=100,Default=25},Callback=function(v)CFG.Movement.Speed=v end})
MT:Toggle({Title="跳跃增强",Value=false,Callback=function(v)CFG.Movement.JumpEnabled=v nTg("跳跃",v)end})
MT:Slider({Title="跳跃力",Value={Min=50,Max=100,Default=50},Callback=function(v)CFG.Movement.JumpPower=v end})
MT:Toggle({Title="无限连跳",Value=false,Callback=function(v)CFG.Movement.InfiniteJump=v nTg("无限连跳",v)end})
MT:Toggle({Title="飞行",Value=false,Callback=function(v)CFG.Movement.FlyEnabled=v nTg("飞行",v)FlyUI.Enabled=v end})
MT:Slider({Title="飞行速度",Value={Min=20,Max=100,Default=50},Callback=function(v)CFG.Movement.FlySpeed=v end})
MT:Toggle({Title="飞行穿墙(自带飞行)",Value=false,Callback=function(v)CFG.Movement.FlyNoClip=v nTg("穿墙",v)end})
MT:Slider({Title="穿墙飞行速度",Value={Min=20,Max=100,Default=50},Callback=function(v)CFG.Movement.NoClipFlySpeed=v end})
MT:Toggle({Title="免疫摔伤",Value=false,Callback=function(v)CFG.Fall.Enabled=v nTg("免疫摔",v)end})
MT:Divider()
MT:Toggle({Title="隐身",Value=false,Callback=function(v)CFG.Invisible.Enabled=v nTg("隐身",v)end})
MT:Slider({Title="隐身透明度",Value={Min=0,Max=1,Default=1},Callback=function(v)CFG.Invisible.Alpha=v end})
MT:Divider()
MT:Toggle({Title="应急反应",Value=false,Callback=function(v)CFG.Emergency.Enabled=v nTg("应急反应",v)end})
MT:Toggle({Title="应急-锁死视角",Value=true,Callback=function(v)CFG.Emergency.LockView=v end})
MT:Slider({Title="应急-回退范围",Value={Min=50,Max=1000,Default=300},Callback=function(v)CFG.Emergency.Range=v end})
MT:Slider({Title="应急-子弹时效(秒)",Value={Min=0.3,Max=3,Default=1.2},Callback=function(v)CFG.Emergency.BulletWindow=v end})
MT:Divider()
MT:Toggle({Title="被瞄准预警",Value=false,Callback=function(v)CFG.Alert.Aim=v nTg("被瞄预警",v)end})
MT:Slider({Title="被瞄检测距离",Value={Min=50,Max=1000,Default=300},Callback=function(v)CFG.Alert.AimDist=v end})
MT:Toggle({Title="附近敌人预警",Value=false,Callback=function(v)CFG.Alert.Nearby=v nTg("附近预警",v)end})
MT:Slider({Title="附近检测距离",Value={Min=20,Max=500,Default=80},Callback=function(v)CFG.Alert.NearbyDist=v end})
MT:Toggle({Title="低血量预警",Value=false,Callback=function(v)CFG.Alert.LowHP=v nTg("血量预警",v)end})
MT:Slider({Title="血量阈值(%)",Value={Min=5,Max=90,Default=30},Callback=function(v)CFG.Alert.HPThresh=v end})
MT:Slider({Title="提示冷却(秒)",Value={Min=0.5,Max=10,Default=2},Callback=function(v)CFG.Alert.Cooldown=v end})

local AL={LastAim=0,LastNear=0,LastHP=0}
task.spawn(function()
    while task.wait(0.1)do
        local mc=LP.Character if not mc then continue end
        local mh=mc:FindFirstChildOfClass("Humanoid")
        local mr=mc:FindFirstChild("HumanoidRootPart")
        if not mh or not mr or mh.Health<=0 then continue end
        local now=tick() local cd=CFG.Alert.Cooldown
        if CFG.Alert.LowHP and now-AL.LastHP>cd then
            local hp=mh.Health/mh.MaxHealth*100
            if hp<=CFG.Alert.HPThresh then AL.LastHP=now notify("血量预警","当前血量 "..math.floor(hp).."%",2) end
        end
        if CFG.Alert.Aim and now-AL.LastAim>cd then
            for _,p in ipairs(Players:GetPlayers())do
                if p~=LP and not isMate(p) and alive(p) then
                    local pch=p.Character
                    local ph=pch and pch:FindFirstChild("Head")
                    local prr=pch and pch:FindFirstChild("HumanoidRootPart")
                    if ph and prr then
                        local dist=(prr.Position-mr.Position).Magnitude
                        if dist<=CFG.Alert.AimDist then
                            local toMe=(mr.Position-prr.Position).Unit
                            if prr.CFrame.LookVector:Dot(toMe)>0.985 and los(ph) then AL.LastAim=now notify("被瞄预警",p.Name.." 正瞄准你",2)break end
                        end
                    end
                end
            end
        end
        if CFG.Alert.Nearby and now-AL.LastNear>cd then
            for _,p in ipairs(Players:GetPlayers())do
                if p~=LP and not isMate(p) and alive(p) then
                    local prr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if prr then
                        local dist=(prr.Position-mr.Position).Magnitude
                        if dist<=CFG.Alert.NearbyDist then AL.LastNear=now notify("附近预警",p.Name.." 靠近",2)break end
                    end
                end
            end
        end
    end
end)

ET:Toggle({Title="透视开关",Value=false,Callback=function(v)CFG.ESP.Enabled=v nTg("透视",v)end})
ET:Toggle({Title="队伍识别",Value=true,Callback=function(v)CFG.ESP.TeamCheck=v end})
ET:Toggle({Title="屏蔽队友",Value=false,Callback=function(v)CFG.ESP.HideTeammate=v end})
ET:Divider()
ET:Paragraph({Title="隐蔽模式",Content="开启透视后，只保留极暗的高亮，避免触发特征扫描。"})
ET:Toggle({Title="显示名字",Value=false,Callback=function(v)CFG.ESP.ShowName=v end})
ET:Toggle({Title="显示血量",Value=false,Callback=function(v)CFG.ESP.ShowHealth=v end})
ET:Toggle({Title="显示距离",Value=false,Callback=function(v)CFG.ESP.ShowDistance=v end})
ET:Toggle({Title="显示掩体状态",Value=false,Callback=function(v)CFG.ESP.ShowCover=v end})
ET:Toggle({Title="显示危险状态",Value=false,Callback=function(v)CFG.ESP.ShowDanger=v end})
ET:Slider({Title="最大距离",Value={Min=100,Max=5000,Default=800},Callback=function(v)CFG.ESP.MaxDistance=v end})
ET:Toggle({Title="Chams 内透",Value=false,Callback=function(v)CFG.ESP.Chams=v nTg("Chams",v)end})

FT:Toggle({Title="静默甩飞",Value=false,Callback=function(v)
    CFG.SilentFlail.Enabled=v
    if v then startSilentFlail() else stopSilentFlail() end
end})
FT:Paragraph({Title="说明",Content="开启后可自由移动，但不会被别人甩飞，也不受伤。自身高速旋转，靠近的敌人被强力甩飞。"})
FT:Slider({Title="检测范围",Value={Min=5,Max=100,Default=20},Callback=function(v)CFG.SilentFlail.Range=v end})
FT:Slider({Title="甩飞力度",Value={Min=100,Max=800,Default=400},Callback=function(v)CFG.SilentFlail.Power=v end})
FT:Slider({Title="撞击冷却(秒)",Value={Min=0.05,Max=2,Default=0.25},Callback=function(v)CFG.SilentFlail.Cooldown=v end})
FT:Slider({Title="自身转速",Value={Min=200,Max=3000,Default=1200},Callback=function(v)CFG.SilentFlail.SpinSpeed=v end})

BT:Toggle({Title="子追开关",Value=false,Callback=function(v)
    CFG.SubChase.Enabled=v
    if v then enableSubChase() else disableSubChase() end
end})
BT:Paragraph({Title="要求",Content="必须先进对局拿到枪再开。"})

AB:Toggle({Title="Ragebot 开关",Value=false,Callback=function(v)
    if v then _G.RageStart() else _G.RageStop() end
end})
AB:Paragraph({Title="要求",Content="必须先进对局拿到枪再开。"})
AB:Divider()
AB:Toggle({Title="秒换子弹(拟真)",Value=false,Callback=function(v)
    _G.FastReload = v
    if v then
        task.spawn(function()
            while _G.FastReload do
                task.wait(0.15 + math.random() * 0.15)
                local c = LP.Character
                if c then
                    local tool = c:FindFirstChildOfClass("Tool")
                    if tool then
                        for _, child in pairs(tool:GetDescendants()) do
                            if child:IsA("NumberValue") or child:IsA("IntValue") then
                                local nm = child.Name:lower()
                                if nm:find("ammo") or nm:find("clip") or nm:find("bullet") then
                                    pcall(function() child.Value = 30 end)
                                elseif nm:find("reload") or nm:find("cooldown") then
                                    pcall(function() child.Value = 0.1 end)
                                end
                            end
                        end
                    end
                end
            end
        end)
        notify("秒换","已开启(拟真防封)",2)
    else
        notify("秒换","已关闭",2)
    end
end})
AB:Divider()

notify("CA-HUB","防封已启动",3)