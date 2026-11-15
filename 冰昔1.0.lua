local CG=game:GetService("CoreGui")
local PG=game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
for _,g in ipairs(CG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
for _,g in ipairs(PG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
task.wait(0.15)

local SG=PG
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer
local _safeMode=false
local FlyDir={up=false,down=false,left=false,right=false}

-- 原生通知替代 WUI:Notify
local NotifyGUI = Instance.new("ScreenGui")
NotifyGUI.Name = "NF_Notify"
NotifyGUI.ResetOnSpawn = false
NotifyGUI.Parent = SG
local function notify(t, x, d)
    local f = Instance.new("Frame", NotifyGUI)
    f.Size = UDim2.new(0, 250, 0, 50)
    f.Position = UDim2.new(1, -270, 1, -80)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local txt = Instance.new("TextLabel", f)
    txt.Size = UDim2.new(1, -10, 1, -10)
    txt.Position = UDim2.new(0, 5, 0, 5)
    txt.BackgroundTransparency = 1
    txt.Text = tostring(t).."\n"..tostring(x)
    txt.TextColor3 = Color3.new(1,1,1)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 13
    txt.TextYAlignment = Enum.TextYAlignment.Center
    txt.TextXAlignment = Enum.TextXAlignment.Left
    task.delay(d or 3, function()
        game:GetService("TweenService"):Create(f, TweenInfo.new(0.3), {Position = UDim2.new(1, 0, 1, -80)}):Play()
        task.wait(0.3)
        f:Destroy()
    end)
end
local function nTg(n,s)notify(n,s and "已开启" or "已关闭",2)end

local FlyUI=Instance.new("ScreenGui")
FlyUI.Name="NF_FlyUI"FlyUI.ResetOnSpawn=false FlyUI.DisplayOrder=150 FlyUI.Parent=SG FlyUI.Enabled=false
local function mkDirBtn(txt,pos,key)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(60,60)b.Position=pos b.AnchorPoint=Vector2.new(0.5,0.5)
    b.BackgroundColor3=Color3.fromRGB(30,30,40)b.BackgroundTransparency=0.3
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

local CFG={
    Aimbot={Enabled=false,IgnoreTeammate=true},
    Movement={Enabled=false,Speed=32,JumpEnabled=false,JumpPower=50,InfiniteJump=false,FlyEnabled=false,FlySpeed=60,FlyNoClip=false,NoClipFlySpeed=60},
    Invisible={Enabled=false,Alpha=1},
    Fall={Enabled=false},
    Obs={Target=nil,Mode="Third",Offset=6,Active=false},
    ESP={Enabled=false,TeamCheck=true,HideTeammate=false,ShowName=true,ShowHealth=true,ShowDistance=false,ShowCover=true,ShowDanger=true,MaxDistance=800,Chams=false},
    Aim={fovsize=150,distance=200,wallCheck=false,smoothness=5,aimSpeed=5,priority="Smart",bodyPart="头部",activate="自动",hotkey=Enum.KeyCode.LeftControl,StrongLock=false,LockView=false,AIPred=false,PredStrength=1.0,BulletSpeed=1200,PredVertical=0.7,PredSmooth=true},
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
local function doAim()
    if not CFG.Aimbot.Enabled then return end
    if CFG.Aim.activate=="按住"and not UIS:IsKeyDown(CFG.Aim.hotkey)then return end
    local t=best()if not t or not t.Character then return end
    local pt=getTP(t.Character)if not pt then return end
    if not inFOV(pt.Position)then return end
    local cm=cam()if not cm then return end
    local aimPos=predictPos(t,pt)
    local g=CFrame.new(cm.CFrame.Position,aimPos)
    if CFG.Aim.StrongLock then
        cm.CFrame=g
        if CFG.Aim.LockView then pcall(function()cm.Focus=CFrame.new(cm.CFrame.Position+cm.CFrame.LookVector*100)end)end
    else
        local a=math.clamp((CFG.Aim.aimSpeed/10)*(1/CFG.Aim.smoothness),0.02,0.8)
        cm.CFrame=cm.CFrame:Lerp(g,a)
        pcall(function()cm.Focus=CFrame.new(cm.CFrame.Position+cm.CFrame.LookVector*100)end)
    end
end
local _lastAim=0
RS.RenderStepped:Connect(function()
    if _safeMode then
        local now=tick()
        if now-_lastAim<(0.016+math.random()*0.02) then return end
        _lastAim=now
    end
    pcall(doAim)
end)

local DEF_WALK=16
local DEF_JUMP=50
local function recordDefaults()
    local c=LP.Character if not c then return end
    local h=c:WaitForChild("Humanoid",5)if not h then return end
    DEF_WALK=h.WalkSpeed
    if h.UseJumpPower then DEF_JUMP=h.JumpPower else DEF_JUMP=h.JumpHeight*7.5 end
end
LP.CharacterAdded:Connect(function()task.wait(0.5)recordDefaults()end)
task.spawn(function()task.wait(1)recordDefaults()end)

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
                if h.UseJumpPower then h.JumpPower=CFG.Movement.JumpPower else h.JumpHeight=CFG.Movement.JumpPower/7.5 end
            end)
        else
            pcall(function()
                if h.UseJumpPower then
                    if h.JumpPower~=DEF_JUMP then h.JumpPower=DEF_JUMP end
                else
                    local jh=DEF_JUMP/7.5
                    if h.JumpHeight~=jh then h.JumpHeight=jh end
                end
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

local BulletCandidate=nil
local BULLET_KEYS={"bullet","projectile","shot","pellet","arrow","missile","rocket","ball","ammo"}
local function isBulletPart(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Anchored then return false end
    local nm=obj.Name:lower()
    for _,k in ipairs(BULLET_KEYS) do if nm:find(k) then return true end end
    if obj.Size.Magnitude<2.5 then return true end
    return false
end
WS.DescendantAdded:Connect(function(obj)
    if not CFG.Emergency.Enabled then return end
    if not isBulletPart(obj) then return end
    task.wait(0.03)
    if not obj.Parent then return end
    local mc=LP.Character if not mc then return end
    local mh=mc:FindFirstChild("Head") or mc:FindFirstChild("HumanoidRootPart")
    if not mh then return end
    local vel=obj.AssemblyLinearVelocity
    if vel.Magnitude<5 then return end
    local dir=vel.Unit
    local toMe=(mh.Position-obj.Position).Unit
    if dir:Dot(toMe)<0.85 then return end
    local origin=obj.Position
    local best,bestD=nil,40
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) and not isMate(p) then
            local pc=p.Character
            if pc then
                local hand=pc:FindFirstChild("RightHand") or pc:FindFirstChild("LeftHand")
                local hrp=pc:FindFirstChild("HumanoidRootPart")
                local ref=hand or hrp
                if ref then
                    local d=(ref.Position-origin).Magnitude
                    if d<bestD then bestD=d best=p end
                end
            end
        end
    end
    if best then BulletCandidate={attacker=best,t=tick()} end
end)
local function emergencyAim(attacker)
    local ac=attacker.Character if not ac then return false end
    local ah=ac:FindFirstChild("Head") or ac:FindFirstChild("HumanoidRootPart")
    if not ah then return false end
    local cm=cam()if not cm then return false end
    pcall(function()
        cm.CFrame=CFrame.new(cm.CFrame.Position,ah.Position)
        if CFG.Emergency.LockView then cm.Focus=CFrame.new(cm.CFrame.Position+cm.CFrame.LookVector*100) end
    end)
    return true
end
local function pickFacing()
    local mc=LP.Character if not mc then return nil end
    local mh=mc:FindFirstChild("Head") or mc:FindFirstChild("HumanoidRootPart")
    if not mh then return nil end
    local best,bestScore=nil,-math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) and not isMate(p) then
            local ph=p.Character and p.Character:FindFirstChild("Head")
            if ph then
                local d=(ph.Position-mh.Position).Magnitude
                if d<=CFG.Emergency.Range then
                    local toMe=(mh.Position-ph.Position).Unit
                    local face=ph.CFrame.LookVector:Dot(toMe)
                    if face>0.75 then
                        local score=face*5+(1-d/CFG.Emergency.Range)*0.5
                        if score>bestScore then bestScore=score best=p end
                    end
                end
            end
        end
    end
    return best
end
task.spawn(function()
    local lastHP=-1
    while true do
        task.wait(0.05)
        local mc=LP.Character if not mc then lastHP=-1 continue end
        local mh=mc:FindFirstChildOfClass("Humanoid")if not mh then lastHP=-1 continue end
        if lastHP<0 then lastHP=mh.Health continue end
        if not CFG.Emergency.Enabled then lastHP=mh.Health continue end
        if mh.Health<lastHP and mh.Health>0 then
            local attacker=nil
            if BulletCandidate and tick()-BulletCandidate.t<CFG.Emergency.BulletWindow then
                local p=BulletCandidate.attacker
                if p and p.Parent and alive(p) then attacker=p end
            end
            if not attacker then attacker=pickFacing() end
            if attacker then emergencyAim(attacker)end
        end
        lastHP=mh.Health
    end
end)

local SubChase={orig=nil,mod=nil,on=false}
local function getBulletHandler()
    local ok,bh=pcall(function()
        return require(game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler)
    end)
    if ok and type(bh)=="table" then return bh end
    return nil
end
local function get_closest_target(range)
    local closest_part,closest_distance=nil,range
    for _,player in ipairs(Players:GetPlayers())do
        if player~=LP then
            local character=player.Character
            if character then
                local humanoid=character:FindFirstChild("Humanoid")
                local head=character:FindFirstChild("Head")
                if head and humanoid and humanoid.Health>0 then
                    local sp,on_screen=cam():WorldToViewportPoint(head.Position)
                    if on_screen then
                        local d=(Vector2.new(sp.X,sp.Y)-cam().ViewportSize/2).Magnitude
                        if d<closest_distance then closest_part=head closest_distance=d end
                    end
                end
            end
        end
    end
    return closest_part
end
local function enableSubChase()
    local mod=getBulletHandler()
    if not mod then notify("子追","require 失败：请进入对局后再开",4)return false end
    if type(mod.Fire)~="function" then notify("子追","Fire 不存在",4)return false end
    SubChase.mod=mod
    if not SubChase.orig then SubChase.orig=mod.Fire end
    mod.Fire=function(data)
        local closest=get_closest_target(999)
        if closest then
            data.Force=data.Force*1000
            data.Direction=(closest.Position-data.Origin).Unit
        end
        return SubChase.orig(data)
    end
    SubChase.on=true
    notify("子追","已开启",2)
    return true
end
local function disableSubChase()
    if SubChase.mod and SubChase.orig then pcall(function()SubChase.mod.Fire=SubChase.orig end)end
    SubChase.on=false
    notify("子追","已关闭",2)
end

do
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local Camera=WS.CurrentCamera
    local currentTarget=nil
    local lastShotTime=0
    local connection=nil
    local function getVisiblePart(targetCharacter)
        if not targetCharacter or not LP.Character then return nil end
        local localCharacter=LP.Character
        local humanoidRootPart=localCharacter:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return nil end
        local partNames={"Head","UpperTorso","Torso","LowerTorso","HumanoidRootPart"}
        local bestPart=nil
        local bestPosition=nil
        local bestOrigin=nil
        local minDistance=math.huge
        for _,partName in ipairs(partNames)do
            local part=targetCharacter:FindFirstChild(partName)
            if part and part:IsA("BasePart")then
                local targetPosition=part.Position
                for height=0,10.5,2 do
                    local startPos=humanoidRootPart.Position+Vector3.new(0,height,0)
                    local direction=(targetPosition-startPos).Unit
                    local forwardPos=startPos+direction*2.5
                    local rayParams=RaycastParams.new()
                    rayParams.FilterType=Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances={localCharacter,Camera}
                    rayParams.IgnoreWater=true
                    local ray=WS:Raycast(forwardPos,targetPosition-forwardPos,rayParams)
                    if not ray or ray.Instance:IsDescendantOf(targetCharacter) or ray.Instance.Transparency>=0.9 then
                        local distance=(targetPosition-forwardPos).Magnitude
                        if distance<minDistance then
                            minDistance=distance bestPart=part bestPosition=targetPosition bestOrigin=forwardPos
                        end
                    end
                end
            end
        end
        return bestPart,bestPosition,bestOrigin
    end
    local function isDead(player)
        if not player or not player.Character then return true end
        local humanoid=player.Character:FindFirstChild("Humanoid")
        return not humanoid or humanoid.Health<=0
    end
    local function createBeam(startPos,endPos)
        local part1=Instance.new("Part")part1.Anchored=true part1.CanCollide=false part1.Transparency=1
        part1.Size=Vector3.new(0.1,0.1,0.1)part1.Position=startPos part1.Parent=WS
        local part2=Instance.new("Part")part2.Anchored=true part2.CanCollide=false part2.Transparency=1
        part2.Size=Vector3.new(0.1,0.1,0.1)part2.Position=endPos part2.Parent=WS
        local a1=Instance.new("Attachment")a1.Parent=part1
        local a2=Instance.new("Attachment")a2.Parent=part2
        local b1=Instance.new("Beam")
        b1.Color=ColorSequence.new(Color3.fromRGB(0,0,0))b1.Transparency=NumberSequence.new(0)
        b1.Width0=0.25 b1.Width1=0.25 b1.Brightness=1 b1.FaceCamera=true
        b1.Attachment0=a1 b1.Attachment1=a2 b1.Parent=part1
        local b2=Instance.new("Beam")
        b2.Color=ColorSequence.new(Color3.fromRGB(180,200,255))b2.Transparency=NumberSequence.new(0.4)
        b2.Width0=0.12 b2.Width1=0.12 b2.Brightness=1.2 b2.FaceCamera=true
        b2.Attachment0=a1 b2.Attachment1=a2 b2.Parent=part1
        task.delay(0.5,function()pcall(function()part1:Destroy()end)pcall(function()part2:Destroy()end)end)
    end
    local function shoot(player,targetPart,targetPos,origin)
        local currentTime=tick()
        if currentTime-lastShotTime<0.56 then return false end
        local character=LP.Character
        if not character or not targetPart or not origin then return false end
        local direction=(targetPos-origin).Unit
        local time=tick()
        local cframe=CFrame.lookAt(origin,targetPos)
        local cr=LP:FindFirstChild("ClientRemotes")
        if cr then
            pcall(function()cr.CheckFire:FireServer(time,origin)end)
            pcall(function()cr.CheckShot:FireServer(0,0,1,0.8,cframe,targetPos,targetPart,11,time)end)
            pcall(function()cr.Reload:FireServer()end)
        end
        local gm=ReplicatedStorage:FindFirstChild("ModuleScripts")
        if gm then gm=gm:FindFirstChild("GunModules")
            if gm then gm=gm:FindFirstChild("Remote")
                if gm then
                    pcall(function()gm.ProjectileRender:FireServer(time,character,origin,direction*999999,360,0,Vector3.zero,5,"Bullet")end)
                    pcall(function()gm.ProjectileFinished:FireServer(time,CFrame.new(targetPos),"Gib_T",false,15,"rbxassetid://2814354338")end)
                end
            end
        end
        createBeam(origin,targetPos)
        lastShotTime=currentTime
        return true
    end
    local function getVisibleTargets()
        local targets={}
        local character=LP.Character if not character then return targets end
        local hrp=character:FindFirstChild("HumanoidRootPart")
        if not hrp then return targets end
        local origin=hrp.Position
        for _,player in ipairs(Players:GetPlayers())do
            if player~=LP and not isDead(player) and player.Character then
                local vp,vpos,opos=getVisiblePart(player.Character)
                if vp and vpos and opos then
                    table.insert(targets,{player=player,distance=(vpos-origin).Magnitude,part=vp,position=vpos,origin=opos})
                end
            end
        end
        table.sort(targets,function(a,b)return a.distance<b.distance end)
        return targets
    end
    local function startRage()
        if connection then return end
        connection=RS.Heartbeat:Connect(function()
            pcall(function()
                if currentTarget and not isDead(currentTarget)then
                    local tc=currentTarget.Character
                    if tc then
                        local vp,vpos,orig=getVisiblePart(tc)
                        if vp and vpos and orig then shoot(currentTarget,vp,vpos,orig)else currentTarget=nil end
                    end
                else currentTarget=nil end
                if not currentTarget then
                    local ts=getVisibleTargets()
                    if #ts>0 then currentTarget=ts[1].player end
                end
            end)
        end)
        notify("Ragebot","已开启",2)
    end
    local function stopRage()
        if connection then connection:Disconnect()connection=nil end
        currentTarget=nil lastShotTime=0
        notify("Ragebot","已关闭",2)
    end
    _G.RageStart=startRage
    _G.RageStop=stopRage
end

local HAS_DRAWING=false
if typeof(Drawing)=="table" and Drawing.new then
    local ok=pcall(function() local t=Drawing.new("Square") t:Remove() end)
    HAS_DRAWING=ok
end
local CO_GREEN=Color3.fromRGB(80,220,80)
local CO_RED=Color3.fromRGB(255,50,50)
local CO_YELLOW=Color3.fromRGB(255,200,0)
local CO_PINK=Color3.fromRGB(255,120,180)
local CO_WHITE=Color3.fromRGB(255,255,255)
local ESPGui=Instance.new("ScreenGui")
ESPGui.Name="NF_ESP_HL"ESPGui.ResetOnSpawn=false ESPGui.IgnoreGuiInset=true ESPGui.Parent=SG
local EC={}
local function mkLabel()
    local f=Instance.new("Frame")f.BackgroundTransparency=1 f.BorderSizePixel=0 f.Visible=false f.ZIndex=12 f.Parent=ESPGui
    local t=Instance.new("TextLabel")t.Size=UDim2.new(1,0,1,0)t.BackgroundTransparency=1 t.Text=""
    t.TextColor3=CO_WHITE t.TextStrokeTransparency=0 t.TextStrokeColor3=Color3.new(0,0,0)
    t.Font=Enum.Font.GothamBold t.TextSize=14 t.Parent=f
    return f,t
end
local function mkE(p)
    if EC[p]then
        local d=EC[p]
        for _,k in ipairs({"box","tracer","name","dist","hpBg","hpFill"})do
            if d[k]then pcall(function()d[k]:Remove()end)end
        end
        if d.coverFrame then d.coverFrame:Destroy()end
        if d.dangerFrame then d.dangerFrame:Destroy()end
        if d.hl then pcall(function()d.hl:Destroy()end)end
        EC[p]=nil
    end
    local d={}
    if HAS_DRAWING then
        local ok
        ok,d.box=pcall(Drawing.new,"Square")
        if ok and d.box then d.box.Thickness=1.5 d.box.Filled=false d.box.Transparency=1 d.box.Color=CO_PINK d.box.Visible=false d.box.ZIndex=10 end
        ok,d.tracer=pcall(Drawing.new,"Line")
        if ok and d.tracer then d.tracer.Thickness=1.5 d.tracer.Transparency=0.5 d.tracer.Visible=false d.tracer.ZIndex=9 end
        ok,d.name=pcall(Drawing.new,"Text")
        if ok and d.name then d.name.Size=13 d.name.Center=true d.name.Outline=true d.name.OutlineColor=Color3.new(0,0,0)d.name.Visible=false d.name.Font=2 d.name.ZIndex=11 end
        ok,d.dist=pcall(Drawing.new,"Text")
        if ok and d.dist then d.dist.Size=11 d.dist.Center=true d.dist.Outline=true d.dist.OutlineColor=Color3.new(0,0,0)d.dist.Color=CO_WHITE d.dist.Visible=false d.dist.Font=2 d.dist.ZIndex=11 end
        ok,d.hpBg=pcall(Drawing.new,"Line")
        if ok and d.hpBg then d.hpBg.Thickness=3 d.hpBg.Color=Color3.new(0,0,0)d.hpBg.Visible=false d.hpBg.ZIndex=10 end
        ok,d.hpFill=pcall(Drawing.new,"Line")
        if ok and d.hpFill then d.hpFill.Thickness=3 d.hpFill.Color=CO_GREEN d.hpFill.Visible=false d.hpFill.ZIndex=10 end
    end
    d.coverFrame,d.coverLabel=mkLabel()
    d.dangerFrame,d.dangerLabel=mkLabel()
    d.hl=Instance.new("Highlight")
    d.hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    d.hl.OutlineColor=CO_PINK d.hl.FillColor=CO_PINK d.hl.FillTransparency=0.5 d.hl.OutlineTransparency=0 d.hl.Enabled=false d.hl.Parent=ESPGui
    d.vis=false
    EC[p]=d
end
local function rmE(p)
    if EC[p]then
        local d=EC[p]
        for _,k in ipairs({"box","tracer","name","dist","hpBg","hpFill"})do
            if d[k]then pcall(function()d[k]:Remove()end)end
        end
        if d.coverFrame then d.coverFrame:Destroy()end
        if d.dangerFrame then d.dangerFrame:Destroy()end
        if d.hl then pcall(function()d.hl:Destroy()end)end
        EC[p]=nil
    end
    LOS_CACHE[p]=nil PredCache[p]=nil
end
for _,p in ipairs(Players:GetPlayers())do if p~=LP then mkE(p)end end
Players.PlayerAdded:Connect(function(p)if p~=LP then task.wait(0.3)mkE(p)end end)
Players.PlayerRemoving:Connect(rmE)
LP.CharacterAdded:Connect(function()
    task.wait(1)
    for _,p in ipairs(Players:GetPlayers())do if p~=LP and not EC[p]then mkE(p)end end
end)
local function hasWeapon(p)
    local c=p.Character if not c then return false end
    return c:FindFirstChildOfClass("Tool")~=nil
end
RS.RenderStepped:Connect(function()
    if not HAS_DRAWING then return end
    local cm=cam()if not cm then return end
    local camPos=cm.CFrame.Position
    local espOn=CFG.ESP.Enabled
    local maxDist=CFG.ESP.MaxDistance
    local teamCheck=CFG.ESP.TeamCheck
    local hideMate=CFG.ESP.HideTeammate
    local showName=CFG.ESP.ShowName
    local showHP=CFG.ESP.ShowHealth
    local showDist=CFG.ESP.ShowDistance
    local showCover=CFG.ESP.ShowCover
    local showDanger=CFG.ESP.ShowDanger
    local chams=CFG.ESP.Chams
    local vp=cm.ViewportSize
    local cx=vp.X/2 cy=vp.Y
    for p,d in pairs(EC)do
        if not d or not d.box then continue end
        if not p.Parent then rmE(p)continue end
        local c=p.Character
        local hd=c and c:FindFirstChild("Head")
        local hm=c and c:FindFirstChildOfClass("Humanoid")
        local dead=not hd or not hm or hm.Health<=0
        local ds=0
        if hd then ds=(camPos-hd.Position).Magnitude end
        local hid=teamCheck and isMate(p) and hideMate
        local wantVis=espOn and not dead and not hid and ds<=maxDist
        if not wantVis then
            if d.vis then
                d.vis=false d.box.Visible=false
                if d.tracer then d.tracer.Visible=false end
                d.name.Visible=false d.dist.Visible=false
                d.hpBg.Visible=false d.hpFill.Visible=false
                d.coverFrame.Visible=false d.dangerFrame.Visible=false
                if d.hl then d.hl.Enabled=false end
            end
            continue
        end
        if not d.vis then d.vis=true end
        local hp,onHead=cm:WorldToViewportPoint(hd.Position)
        if not onHead or hp.Z<=0 then
            d.box.Visible=false
            if d.tracer then d.tracer.Visible=false end
            d.name.Visible=false d.dist.Visible=false
            d.hpBg.Visible=false d.hpFill.Visible=false
            d.coverFrame.Visible=false d.dangerFrame.Visible=false
            continue
        end
        local footWorld=nil
        for _,fn in ipairs({"LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg"})do
            local f=c:FindFirstChild(fn)
            if f then footWorld=f.Position break end
        end
        if not footWorld then
            local hrp=c:FindFirstChild("HumanoidRootPart")
            if hrp then footWorld=hrp.Position-Vector3.new(0,3,0)else footWorld=hd.Position-Vector3.new(0,5,0)end
        end
        local fp,onFoot=cm:WorldToViewportPoint(footWorld)
        if not onFoot then fp=Vector3.new(hp.X,hp.Y+80,hp.Z)end
        local topY=hp.Y-14
        local botY=fp.Y+6
        local boxH=math.max(30,botY-topY)
        local boxW=boxH*0.55
        local x1=hp.X-boxW/2
        local mt=teamCheck and isMate(p)
        local armed=showDanger and hasWeapon(p)
        local clear=losCached(p,hd)
        local col
        if armed then col=CO_RED elseif mt then col=CO_GREEN else col=CO_PINK end
        d.box.Position=Vector2.new(x1,topY)
        d.box.Size=Vector2.new(boxW,boxH)
        d.box.Color=col d.box.Visible=true
        if d.tracer then
            d.tracer.From=Vector2.new(cx,cy)
            d.tracer.To=Vector2.new(hp.X,topY)
            d.tracer.Color=col d.tracer.Visible=true
        end
        d.name.Visible=showName
        if showName then
            d.name.Position=Vector2.new(hp.X,topY-16)
            d.name.Text=p.Name d.name.Color=col
        end
        d.dist.Visible=showDist
        if showDist then
            d.dist.Position=Vector2.new(hp.X,botY+2)
            d.dist.Text=math.floor(ds).."m" d.dist.Color=CO_WHITE
        end
        d.coverFrame.Visible=showCover
        if showCover then
            d.coverFrame.Position=UDim2.fromOffset(x1+boxW+6,topY+boxH/2-10)
            d.coverFrame.Size=UDim2.fromOffset(30,20)
            if clear then d.coverLabel.Text="无" d.coverLabel.TextColor3=CO_GREEN
            else d.coverLabel.Text="有" d.coverLabel.TextColor3=CO_RED end
        end
        d.dangerFrame.Visible=showDanger and armed
        if d.dangerFrame.Visible then
            d.dangerFrame.Position=UDim2.fromOffset(hp.X-boxW,topY-36)
            d.dangerFrame.Size=UDim2.fromOffset(boxW*2,18)
            d.dangerLabel.Text="⚠ 持武器"
            d.dangerLabel.TextColor3=CO_RED
        end
        d.hpBg.Visible=showHP
        d.hpFill.Visible=showHP
        if showHP then
            local hpP=math.clamp(hm.Health/hm.MaxHealth,0,1)
            local barX=x1-6
            d.hpBg.From=Vector2.new(barX,topY)
            d.hpBg.To=Vector2.new(barX,botY)
            local fillH=boxH*hpP
            d.hpFill.From=Vector2.new(barX,botY-fillH)
            d.hpFill.To=Vector2.new(barX,botY)
            d.hpFill.Color=(hpP>0.6 and CO_GREEN)or(hpP>0.3 and CO_YELLOW)or CO_RED
        end
        if d.hl then
            local wantChams=chams and not mt
            if wantChams then
                d.hl.Adornee=c d.hl.Enabled=true d.hl.FillTransparency=0.5
                d.hl.FillColor=CO_PINK d.hl.OutlineColor=CO_PINK
            else d.hl.Enabled=false d.hl.Adornee=nil end
        end
    end
end)
local FL={C1=nil,C2=nil,W=false}
local function bFL()
    local c=LP.Character if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")if not h then return end
    if FL.C1 then pcall(function()FL.C1:Disconnect()end)end
    if FL.C2 then pcall(function()FL.C2:Disconnect()end)end
    FL.W=false
    FL.C1=h.StateChanged:Connect(function(_,ns)
        if ns==Enum.HumanoidStateType.Freefall then FL.W=true
        elseif FL.W and(ns==Enum.HumanoidStateType.Landed or ns==Enum.HumanoidStateType.Running or ns==Enum.HumanoidStateType.GettingUp)then
            FL.W=false if CFG.Fall.Enabled and h.Parent then pcall(function()h.Health=h.MaxHealth end)end
        end
    end)
    FL.C2=h.HealthChanged:Connect(function()if CFG.Fall.Enabled and FL.W and h.Parent then pcall(function()h.Health=h.MaxHealth end)end end)
end
LP.CharacterAdded:Connect(function()task.wait(0.3)bFL()end)
task.spawn(function()task.wait(0.5)bFL()end)

task.spawn(function()
    while true do
        RS.Stepped:Wait()
        if not CFG.Movement.InfiniteJump or CFG.Movement.FlyEnabled then continue end
        local c=LP.Character if not c then continue end
        local h=c:FindFirstChildOfClass("Humanoid")
        local r=c:FindFirstChild("HumanoidRootPart")
        if not h or not r then continue end
        if not UIS:IsKeyDown(Enum.KeyCode.Space) then continue end
        pcall(function()h:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)h:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)end)
        local v=r.AssemblyLinearVelocity
        r.AssemblyLinearVelocity=Vector3.new(v.X,60,v.Z)
    end
end)

local FBV,FBG,FA=nil,nil,false
local function sFly()
    local c=LP.Character if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
    if not r or not h then return end
    FA=true h.PlatformStand=true
    if not FBV or not FBV.Parent then FBV=Instance.new("BodyVelocity")FBV.MaxForce=Vector3.new(1e5,1e5,1e5)FBV.Parent=r end
    if not FBG or not FBG.Parent then FBG=Instance.new("BodyGyro")FBG.MaxTorque=Vector3.new(1e5,1e5,1e5)FBG.P=10000 FBG.D=500 FBG.Parent=r end
end
local function stFly()
    FA=false
    local c=LP.Character if c then local h=c:FindFirstChildOfClass("Humanoid")if h then h.PlatformStand=false end end
    if FBV then FBV:Destroy()FBV=nil end
    if FBG then FBG:Destroy()FBG=nil end
end
task.spawn(function()while true do RS.RenderStepped:Wait()
    if not CFG.Movement.FlyEnabled then if FA then stFly()end continue end
    local c=LP.Character if not c then if FA then stFly()end continue end
    local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
    if not r or not h then if FA then stFly()end continue end
    if not FA then sFly()end
    if not FBV or not FBV.Parent then sFly()end
    local cm=cam()if not cm then continue end
    local mv=Vector3.new(0,0,0)
    local md=h.MoveDirection
    if md.Magnitude>0.01 then mv=md*CFG.Movement.Speed end
    local right=cm.CFrame.RightVector
    if FlyDir.left then mv=mv-right*CFG.Movement.FlySpeed end
    if FlyDir.right then mv=mv+right*CFG.Movement.FlySpeed end
    local fv=Vector3.new(0,0,0)
    if UIS:IsKeyDown(Enum.KeyCode.Space) or FlyDir.up then fv=fv+Vector3.new(0,CFG.Movement.FlySpeed,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or FlyDir.down then fv=fv-Vector3.new(0,CFG.Movement.FlySpeed,0) end
    local fvv=mv+fv
    if FBV and FBV.Parent then FBV.Velocity=fvv end
    if FBG and FBG.Parent then FBG.CFrame=CFrame.new(r.Position,r.Position+cm.CFrame.LookVector)end
end end)

local NB={}local NCA=false
local NCBV=nil local NCBG=nil
local function apNC()
    local c=LP.Character if not c then return end
    NB={}for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then NB[p]=p.CanCollide pcall(function()p.CanCollide=false end)end end
    NCA=true
end
local function rmNC()
    for p,o in pairs(NB)do if p and p.Parent then pcall(function()p.CanCollide=o end)end end
    NB={}NCA=false
end
local function sNoClipFly()
    local c=LP.Character if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
    if not r or not h then return end
    h.PlatformStand=true
    if not NCBV or not NCBV.Parent then
        NCBV=Instance.new("BodyVelocity")
        NCBV.MaxForce=Vector3.new(1e5,1e5,1e5)
        NCBV.P=1e5 NCBV.D=1e4
        NCBV.Parent=r
    end
    if not NCBG or not NCBG.Parent then
        NCBG=Instance.new("BodyGyro")
        NCBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
        NCBG.P=10000 NCBG.D=500
        NCBG.Parent=r
    end
end
local function stNoClipFly()
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand=false end
    end
    if NCBV then NCBV:Destroy()NCBV=nil end
    if NCBG then NCBG:Destroy()NCBG=nil end
end
_G.__NCS=0
LP.CharacterAdded:Connect(function()NB={}NCA=false _G.__NCS=0 NCBV=nil NCBG=nil end)
local NC={STEP=0.55,MAX_PROBE=80,MAX_LAYER=12,GAP_MIN=0.25,GAP_MAX=0.9,GAP_SLOPE=0.18,MAX_TP=22,PRE=1.4,LAT=0.55,STUCK=90,BACK=2.0}
local HH={1.5,0,-1.5}
local function bP(c)
    local p=RaycastParams.new()p.FilterType=Enum.RaycastFilterType.Exclude
    local l={c}
    for _,pl in ipairs(Players:GetPlayers())do local ch=pl.Character if ch and ch~=c then table.insert(l,ch)end end
    p.FilterDescendantsInstances=l p.IgnoreWater=true return p
end
local function pr(o,d,dist,params)
    local n=nil
    for i,h in ipairs(HH)do
        local oo=o+Vector3.new(0,h,0)
        local ht=WS:Raycast(oo,d*dist,params)
        if ht and(not n or ht.Distance<n)then n=ht.Distance end
        if i==2 then
            local r=d:Cross(Vector3.new(0,1,0))
            if r.Magnitude>0.001 then r=r.Unit
                for _,s in ipairs({1,-1})do local o2=oo+r*(NC.LAT*s)local h2=WS:Raycast(o2,d*dist,params)if h2 and(not n or h2.Distance<n)then n=h2.Distance end end
            end
        end
    end
    return n
end
local function fG(o,d,params)
    local pb=o local tr=0
    for _=1,NC.MAX_LAYER do
        local rem=NC.MAX_PROBE-tr
        if rem<=0.1 then return nil end
        local hd=pr(pb,d,rem,params)
        if not hd then return pb end
        local gp=math.clamp(NC.GAP_MIN+hd*NC.GAP_SLOPE,NC.GAP_MIN,NC.GAP_MAX)
        local st=hd+gp
        pb=pb+d*st tr=tr+st
    end
    return nil
end
task.spawn(function()while true do RS.RenderStepped:Wait()
    if not CFG.Movement.FlyNoClip then
        if NCA then rmNC()end
        if NCBV or NCBG then stNoClipFly()end
        _G.__NCS=0
        continue
    end
    local c=LP.Character if not c then continue end
    local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
    if not r or not h then continue end
    if not NCA then apNC()end
    if not NCBV or not NCBV.Parent then sNoClipFly()end
    if not NCBG or not NCBG.Parent then sNoClipFly()end
    local cm=cam()if not cm then continue end
    local mv=Vector3.new(0,0,0)
    local md=h.MoveDirection
    local flySpeed=CFG.Movement.NoClipFlySpeed or 60
    if md.Magnitude>0.01 then mv=md*flySpeed end
    local fv=Vector3.new(0,0,0)
    if UIS:IsKeyDown(Enum.KeyCode.Space) then fv=fv+Vector3.new(0,flySpeed,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then fv=fv-Vector3.new(0,flySpeed,0) end
    local right=cm.CFrame.RightVector
    if FlyDir.left then mv=mv-right*flySpeed end
    if FlyDir.right then mv=mv+right*flySpeed end
    if FlyDir.up then fv=fv+Vector3.new(0,flySpeed,0) end
    if FlyDir.down then fv=fv-Vector3.new(0,flySpeed,0) end
    if NCBV and NCBV.Parent then NCBV.Velocity=mv+fv end
    if NCBG and NCBG.Parent then NCBG.CFrame=CFrame.new(r.Position,r.Position+cm.CFrame.LookVector) end
    local rd=h.MoveDirection
    if rd.Magnitude<0.01 then _G.__NCS=0 continue end
    local fmd=Vector3.new(rd.X,0,rd.Z)
    if fmd.Magnitude<0.001 then _G.__NCS=0 continue end
    fmd=fmd.Unit
    local P=bP(c)
    if not pr(r.Position,fmd,NC.PRE,P)then _G.__NCS=0 continue end
    local gp=fG(r.Position,fmd,P)
    if gp then
        _G.__NCS=0
        local dl=gp-r.Position
        if dl.Magnitude>NC.MAX_TP then gp=r.Position+dl.Unit*NC.MAX_TP end
        r.CFrame=r.CFrame-r.CFrame.Position+gp
    else
        _G.__NCS=_G.__NCS+1
        if _G.__NCS>=NC.STUCK then
            local bk=r.Position-fmd*NC.BACK
            r.CFrame=r.CFrame-r.CFrame.Position+bk
            _G.__NCS=0
        else
            local np=r.Position+fmd*NC.STEP
            r.CFrame=r.CFrame-r.CFrame.Position+np
        end
    end
end end)

local OB={B=false}
local function obsU(dt)
    if not CFG.Obs.Active then return end
    local t=CFG.Obs.Target
    if not t or not t.Parent then return end
    local cm=cam()if not cm then return end
    local tc=t.Character if not tc then return end
    local th=tc:FindFirstChild("Head")if not th then return end
    local m=CFG.Obs.Mode local o=CFG.Obs.Offset local g
    if m=="First"then g=CFrame.new(th.Position,th.Position+th.CFrame.LookVector)
    elseif m=="Third"then local b=th.CFrame.LookVector*-(5+o)g=CFrame.lookAt(th.Position+b+Vector3.new(0,1.5,0),th.Position)
    elseif m=="Top"then g=CFrame.lookAt(th.Position+Vector3.new(0,12+o,0),th.Position)
    elseif m=="Side"then local r=th.CFrame.RightVector g=CFrame.lookAt(th.Position+r*(5+o)+Vector3.new(0,2,0),th.Position)
    else return end
    cm.CFrame=cm.CFrame:Lerp(g,math.min(dt*12,1))
end
local function sObs(t)
    if not t or not t.Character or not t.Character:FindFirstChild("Head")then notify("观察","无效")return end
    local cm=cam()if not cm then return end
    CFG.Obs.Active=true CFG.Obs.Target=t cm.CameraType=Enum.CameraType.Scriptable
    if OB.B then pcall(function()RS:UnbindFromRenderStep("YI_Obs")end)end
    RS:BindToRenderStep("YI_Obs",Enum.RenderPriority.Camera.Value+1,obsU)
    OB.B=true notify("观察","锁定 "..t.Name)
end
local function stopObs()
    if not CFG.Obs.Active then return end
    CFG.Obs.Active=false CFG.Obs.Target=nil
    if OB.B then pcall(function()RS:UnbindFromRenderStep("YI_Obs")end)OB.B=false end
    local cm=cam()if cm then cm.CameraType=Enum.CameraType.Custom local mc=LP.Character if mc then local mh=mc:FindFirstChildOfClass("Humanoid")if mh then cm.CameraSubject=mh end end end
    notify("观察","退出")
end
Players.PlayerRemoving:Connect(function(p)if CFG.Obs.Active and CFG.Obs.Target==p then stopObs()end end)

local SF_Silent={Active=false,MyBAV=nil,MySP=nil,LastBump=0,ActiveTargets={}}
local function startSilentFlail()
    if SF_Silent.Active then return end
    local mc=LP.Character if not mc then return end
    local mr=mc:FindFirstChild("HumanoidRootPart") if not mr then return end
    SF_Silent.Active=true
    local bav=Instance.new("BodyAngularVelocity")
    bav.Name="__sfSpin" bav.MaxTorque=Vector3.new(9e9,9e9,9e9)
    bav.AngularVelocity=Vector3.new(0,CFG.SilentFlail.SpinSpeed,0) bav.P=1e6 bav.Parent=mr
    SF_Silent.MyBAV=bav
    local sp=Instance.new("BodyVelocity")
    sp.Name="__sfSP" sp.MaxForce=Vector3.new(9e9,9e9,9e9) sp.P=1e6 sp.D=1e5
    sp.Velocity=Vector3.new(0,0,0) sp.Parent=mr
    SF_Silent.MySP=sp SF_Silent.LastBump=0 SF_Silent.ActiveTargets={}
    notify("静默甩飞","已开启")
end
local function stopSilentFlail()
    if not SF_Silent.Active then return end
    SF_Silent.Active=false
    if SF_Silent.MyBAV then pcall(function()SF_Silent.MyBAV:Destroy()end)SF_Silent.MyBAV=nil end
    if SF_Silent.MySP then pcall(function()SF_Silent.MySP:Destroy()end)SF_Silent.MySP=nil end
    for p,data in pairs(SF_Silent.ActiveTargets) do
        if data.bv then pcall(function()data.bv:Destroy()end)end
        if data.bav then pcall(function()data.bav:Destroy()end)end
    end
    SF_Silent.ActiveTargets={}
    notify("静默甩飞","已关闭")
end
task.spawn(function()
    while task.wait(0.04) do
        if not SF_Silent.Active then continue end
        local mc=LP.Character if not mc then continue end
        local mr=mc:FindFirstChild("HumanoidRootPart")
        local myH=mc:FindFirstChildOfClass("Humanoid")
        if not mr or not myH then continue end
        for _,child in ipairs(mr:GetChildren()) do
            if child.Name~="__sfSpin" and child.Name~="__sfSP" then
                if child:IsA("BodyVelocity") or child:IsA("BodyPosition") or child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") or child:IsA("BodyGyro") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
        if myH.Health<myH.MaxHealth then pcall(function() myH.Health=myH.MaxHealth end) end
        if SF_Silent.MySP and SF_Silent.MySP.Parent then
            local md=myH.MoveDirection
            local curY=mr.AssemblyLinearVelocity.Y
            if curY>5 then curY=0 end
            if curY<-50 then curY=0 end
            if md.Magnitude>0.01 then
                SF_Silent.MySP.Velocity=Vector3.new(md.X*myH.WalkSpeed,curY,md.Z*myH.WalkSpeed)
            else
                SF_Silent.MySP.Velocity=Vector3.new(0,curY,0)
            end
        end
        local now=tick()
        if now-SF_Silent.LastBump<CFG.SilentFlail.Cooldown then continue end
        local power=math.clamp(CFG.SilentFlail.Power,100,5000)
        local range=CFG.SilentFlail.Range
        local closest=nil local closestHRP=nil local closestDist=range
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and not isMate(p) then
                local pc=p.Character
                local ph=pc and pc:FindFirstChildOfClass("Humanoid")
                local pr=pc and pc:FindFirstChild("HumanoidRootPart")
                if ph and pr and ph.Health>0 then
                    local d=(pr.Position-mr.Position).Magnitude
                    if d<closestDist then closestDist=d closest=p closestHRP=pr end
                end
            end
        end
        if closest and closestHRP then
            SF_Silent.LastBump=now
            pcall(function() closestHRP.AssemblyLinearVelocity=Vector3.new(math.random(-400,400),power,math.random(-400,400)) end)
            pcall(function() closestHRP.AssemblyAngularVelocity=Vector3.new(math.random(-800,800),math.random(-800,800),math.random(-800,800)) end)
            local oldB=closestHRP:FindFirstChild("__flailB") if oldB then pcall(function() oldB:Destroy() end) end
            local oldR=closestHRP:FindFirstChild("__flailR") if oldR then pcall(function() oldR:Destroy() end) end
            local bv=Instance.new("BodyVelocity") bv.Name="__flailB" bv.MaxForce=Vector3.new(9e9,9e9,9e9) bv.P=1e6 bv.D=1e5
            bv.Velocity=Vector3.new(math.random(-400,400),power,math.random(-400,400)) bv.Parent=closestHRP
            local bav=Instance.new("BodyAngularVelocity") bav.Name="__flailR" bav.MaxTorque=Vector3.new(9e9,9e9,9e9) bav.P=1e6
            bav.AngularVelocity=Vector3.new(math.random(-800,800),math.random(-800,800),math.random(-800,800)) bav.Parent=closestHRP
            SF_Silent.ActiveTargets[closest]={bv=bv,bav=bav}
            task.delay(1.2, function()
                if bv and bv.Parent then pcall(function() bv:Destroy() end) end
                if bav and bav.Parent then pcall(function() bav:Destroy() end) end
                if SF_Silent.ActiveTargets[closest] and SF_Silent.ActiveTargets[closest].bv==bv then SF_Silent.ActiveTargets[closest]=nil end
            end)
        end
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if SF_Silent.ActiveTargets[p] then
        local data=SF_Silent.ActiveTargets[p]
        if data.bv then pcall(function() data.bv:Destroy() end) end
        if data.bav then pcall(function() data.bav:Destroy() end) end
        SF_Silent.ActiveTargets[p]=nil
    end
end)
LP.CharacterAdded:Connect(function()
    if SF_Silent.Active then
        SF_Silent.Active=false SF_Silent.MyBAV=nil SF_Silent.MySP=nil
        for p,data in pairs(SF_Silent.ActiveTargets) do
            if data.bv then pcall(function() data.bv:Destroy() end) end
            if data.bav then pcall(function() data.bav:Destroy() end) end
        end
        SF_Silent.ActiveTargets={}
    end
end)

-- ==========================================
-- 原生 UI 复刻框架 (接管所有 UI)
-- ==========================================
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if parent then inst.Parent = parent end
    return inst
end

local MainGUI = New("ScreenGui", {Name = "CA_HUB", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = CoreGui})
local MainFrame = New("Frame", {
    Size = UDim2.new(0, 700, 0, 480), Position = UDim2.new(0.5, -350, 0.5, -240),
    BackgroundColor3 = Color3.fromRGB(35, 35, 40), BorderSizePixel = 0, Parent = MainGUI
})
New("UICorner", {CornerRadius = UDim.new(0, 10)}, MainFrame)
New("UIStroke", {Color = Color3.fromRGB(80, 80, 90), Thickness = 1}, MainFrame)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Sidebar = New("Frame", {Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = Color3.fromRGB(25, 25, 28), BorderSizePixel = 0, Parent = MainFrame})
New("UICorner", {CornerRadius = UDim.new(0, 10)}, Sidebar)
New("Frame", {Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Color3.fromRGB(25, 25, 28), BorderSizePixel = 0}, Sidebar)

local ContentArea = New("Frame", {Size = UDim2.new(1, -150, 1, 0), Position = UDim2.new(0, 150, 0, 0), BackgroundTransparency = 1, Parent = MainFrame})
local TitleBar = New("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = ContentArea})
local TitleLabel = New("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "通用类", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar})
local CloseBtn = New("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0, 5), BackgroundTransparency = 1, Text = "×", TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.GothamBold, TextSize = 24, Parent = TitleBar})
CloseBtn.MouseButton1Click:Connect(function() MainGUI:Destroy() end)

local PageContainer = New("Frame", {Size = UDim2.new(1, -20, 1, -50), Position = UDim2.new(0, 10, 0, 45), BackgroundTransparency = 1, Parent = ContentArea})
local pages = {}
local currentPage = nil
local function CreatePage(name)
    local p = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 800), Parent = PageContainer})
    pages[name] = p
    return p
end

local SideBtnContainer = New("Frame", {Size = UDim2.new(1, 0, 0, 400), Position = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1, Parent = Sidebar})
local function CreateSideButton(icon, text, pageName)
    local btn = New("TextButton", {Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0, 10, 0, #SideBtnContainer:GetChildren() * 40), BackgroundColor3 = Color3.fromRGB(35, 35, 40), BackgroundTransparency = 1, Text = "", Parent = SideBtnContainer})
    New("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    New("TextLabel", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 10, 0.5, -10), BackgroundTransparency = 1, Text = icon, TextSize = 16, TextColor3 = Color3.fromRGB(150,150,150), Parent = btn})
    New("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 40, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(150,150,150), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(SideBtnContainer:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundTransparency = 1
                b:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.fromRGB(150,150,150)
                b:GetChildren()[2].TextColor3 = Color3.fromRGB(150,150,150)
            end
        end
        btn.BackgroundTransparency = 0
        btn:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.fromRGB(255,255,255)
        btn:GetChildren()[2].TextColor3 = Color3.fromRGB(255,255,255)
        for n, p in pairs(pages) do p.Visible = (n == pageName) end
        TitleLabel.Text = text
    end)
    if not currentPage then currentPage = pageName btn.BackgroundTransparency = 0 btn:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.fromRGB(255,255,255) btn:GetChildren()[2].TextColor3 = Color3.fromRGB(255,255,255) end
end

local function CreateToggle(parent, text, default, callback)
    local frame = New("Frame", {Size = UDim2.new(0, 200, 0, 30), BackgroundTransparency = 1, Parent = parent})
    New("TextLabel", {Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame})
    local switch = New("Frame", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -36, 0.5, -10), BackgroundColor3 = Color3.fromRGB(60,60,60), Parent = frame})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, switch)
    local knob = New("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(200,200,200), Parent = switch})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local state = default
    local function update()
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0,150,100) or Color3.fromRGB(60,60,60)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
    end
    update()
    local btn = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame})
    btn.MouseButton1Click:Connect(function()
        state = not state
        update()
        if callback then callback(state) end
    end)
    return frame
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = New("Frame", {Size = UDim2.new(0, 200, 0, 45), BackgroundTransparency = 1, Parent = parent})
    local label = New("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text..": "..default, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame})
    local track = New("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(60,60,60), Parent = frame})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    local fill = New("Frame", {Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,150,100), Parent = track})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    local knob = New("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new((default-min)/(max-min), 0, 0.5, -6), BackgroundColor3 = Color3.new(1,1,1), Parent = track})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local dragging = false
    local function update(input)
        local p = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * p)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, -6)
        label.Text = text..": "..val
        if callback then callback(val) end
    end
    New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame}).InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true update(i) end end)
    UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    return frame
end

local function CreateRadio(parent, text, group, default, callback)
    local frame = New("Frame", {Size = UDim2.new(0, 200, 0, 25), BackgroundTransparency = 1, Parent = parent})
    local circle = New("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = Color3.fromRGB(60,60,60), Parent = frame})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, circle)
    local dot = New("Frame", {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0.5, -4, 0.5, -4), BackgroundColor3 = Color3.new(1,1,1), Visible = default, Parent = circle})
    New("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
    New("TextLabel", {Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 25, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame})
    local btn = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame})
    btn.MouseButton1Click:Connect(function()
        for _, child in pairs(parent:GetChildren()) do
            if child:GetAttribute("Group") == group then
                child:FindFirstChild("Frame"):FindFirstChildOfClass("Frame").Visible = false
            end
        end
        dot.Visible = true
        if callback then callback() end
    end)
    frame:SetAttribute("Group", group)
    return frame
end

local function CreateCheckbox(parent, text, default, callback)
    local frame = New("Frame", {Size = UDim2.new(0, 200, 0, 25), BackgroundTransparency = 1, Parent = parent})
    local box = New("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = default and Color3.fromRGB(0,150,100) or Color3.fromRGB(60,60,60), Parent = frame})
    New("UICorner", {CornerRadius = UDim.new(0, 4)}, box)
    New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✓", TextColor3 = Color3.new(1,1,1), TextSize = 12, Visible = default, Parent = box})
    New("TextLabel", {Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 25, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame})
    local state = default
    local btn = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame})
    btn.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and Color3.fromRGB(0,150,100) or Color3.fromRGB(60,60,60)
        box:FindFirstChildOfClass("TextLabel").Visible = state
        if callback then callback(state) end
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = New("TextButton", {Size = UDim2.new(0, 200, 0, 30), BackgroundColor3 = Color3.fromRGB(50,50,55), Text = text, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 13, Parent = parent})
    New("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 通用类
local generalPage = CreatePage("General")
CreateSideButton("🏠", "通用类", "General")
CreateToggle(generalPage, "防闪退", false, function(v) _safeMode = v end).Position = UDim2.new(0, 0, 0, 0)
CreateButton(generalPage, "查看手持物品ID", function() local c = LP.Character; if c then local t = c:FindFirstChildOfClass("Tool"); if t then notify("手持物品", t.Name, 3) end end end).Position = UDim2.new(0, 0, 0, 40)
CreateSlider(generalPage, "最高帧数", 30, 240, 144, function(v) pcall(function() setfpscap(v) end) end).Position = UDim2.new(0, 0, 0, 80)

-- 战斗类
local combatPage = CreatePage("Combat")
CreateSideButton("⚔️", "战斗类", "Combat")
CreateToggle(combatPage, "Ragebot (刀暴)", false, function(v) if v then _G.RageStart() else _G.RageStop() end end).Position = UDim2.new(0, 0, 0, 0)
CreateToggle(combatPage, "子追", false, function(v) CFG.SubChase.Enabled = v if v then enableSubChase() else disableSubChase() end end).Position = UDim2.new(0, 0, 0, 40)
CreateToggle(combatPage, "静默甩飞", false, function(v) CFG.SilentFlail.Enabled = v if v then startSilentFlail() else stopSilentFlail() end end).Position = UDim2.new(0, 0, 0, 80)
CreateSlider(combatPage, "甩飞力度", 100, 800, 400, function(v) CFG.SilentFlail.Power = v end).Position = UDim2.new(0, 0, 0, 120)

-- 移动类
local movePage = CreatePage("Move")
CreateSideButton("🏃", "移动类", "Move")
CreateToggle(movePage, "人物加速", false, function(v) CFG.Movement.Enabled = v end).Position = UDim2.new(0, 0, 0, 0)
CreateSlider(movePage, "移动速度", 16, 100, 32, function(v) CFG.Movement.Speed = v end).Position = UDim2.new(0, 0, 0, 40)
CreateToggle(movePage, "无限连跳", false, function(v) CFG.Movement.InfiniteJump = v end).Position = UDim2.new(0, 0, 0, 90)
CreateToggle(movePage, "飞行", false, function(v) CFG.Movement.FlyEnabled = v FlyUI.Enabled = v end).Position = UDim2.new(0, 0, 0, 130)
CreateSlider(movePage, "飞行速度", 20, 200, 60, function(v) CFG.Movement.FlySpeed = v end).Position = UDim2.new(0, 0, 0, 170)
CreateToggle(movePage, "飞行穿墙", false, function(v) CFG.Movement.FlyNoClip = v end).Position = UDim2.new(0, 0, 0, 220)
CreateToggle(movePage, "免疫摔伤", false, function(v) CFG.Fall.Enabled = v end).Position = UDim2.new(0, 0, 0, 260)
CreateToggle(movePage, "隐身", false, function(v) CFG.Invisible.Enabled = v end).Position = UDim2.new(0, 0, 0, 300)

-- 瞄准类
local aimPage = CreatePage("Aim")
CreateSideButton("🎯", "瞄准类", "Aim")
CreateToggle(aimPage, "自动瞄准", false, function(v) CFG.Aimbot.Enabled = v end).Position = UDim2.new(0, 0, 0, 0)
CreateCheckbox(aimPage, "开火判断(掩体识别)", false, function(v) CFG.Aim.wallCheck = v end).Position = UDim2.new(0, 0, 0, 40)
CreateCheckbox(aimPage, "瞄准队友", false, function(v) CFG.Aimbot.IgnoreTeammate = not v end).Position = UDim2.new(0, 0, 0, 70)
CreateCheckbox(aimPage, "弹道模式(预判)", false, function(v) CFG.Aim.AIPred = v end).Position = UDim2.new(0, 0, 0, 100)
CreateSlider(aimPage, "自瞄范围", 20, 500, 150, function(v) CFG.Aim.fovsize = v end).Position = UDim2.new(0, 0, 0, 140)
CreateSlider(aimPage, "瞄准部位(平滑度)", 1, 20, 5, function(v) CFG.Aim.smoothness = v end).Position = UDim2.new(0, 0, 0, 190)
CreateSlider(aimPage, "瞄准距离", 50, 2000, 200, function(v) CFG.Aim.distance = v end).Position = UDim2.new(0, 0, 0, 240)
CreateSlider(aimPage, "预判强度", 1, 10, 1, function(v) CFG.Aim.PredStrength = v end).Position = UDim2.new(0, 0, 0, 290)
CreateRadio(aimPage, "头部", "Part", true, function() CFG.Aim.bodyPart = "头部" end).Position = UDim2.new(0, 0, 0, 340)
CreateRadio(aimPage, "躯干", "Part", false, function() CFG.Aim.bodyPart = "躯干" end).Position = UDim2.new(0, 0, 0, 370)

-- 视觉类
local visPage = CreatePage("Visual")
CreateSideButton("👁️", "视觉类", "Visual")
CreateToggle(visPage, "绘制(透视)", false, function(v) CFG.ESP.Enabled = v end).Position = UDim2.new(0, 0, 0, 0)
CreateCheckbox(visPage, "绘制方框", false, function(v) end).Position = UDim2.new(0, 0, 0, 40)
CreateCheckbox(visPage, "绘制信息(名字)", true, function(v) CFG.ESP.ShowName = v end).Position = UDim2.new(0, 0, 0, 70)
CreateCheckbox(visPage, "绘制距离", false, function(v) CFG.ESP.ShowDistance = v end).Position = UDim2.new(0, 0, 0, 100)
CreateCheckbox(visPage, "绘制血量", true, function(v) CFG.ESP.ShowHealth = v end).Position = UDim2.new(0, 0, 0, 130)
CreateSlider(visPage, "绘制距离", 100, 5000, 800, function(v) CFG.ESP.MaxDistance = v end).Position = UDim2.new(0, 0, 0, 170)
CreateButton(visPage, "第一人称", function() CFG.Obs.Mode = "First" end).Position = UDim2.new(0, 0, 0, 220)
CreateButton(visPage, "第三人称", function() CFG.Obs.Mode = "Third" end).Position = UDim2.new(0, 0, 0, 260)
CreateToggle(visPage, "人物透视(Chams)", false, function(v) CFG.ESP.Chams = v end).Position = UDim2.new(0, 0, 0, 300)
CreateButton(visPage, "重置设置", function() notify("提示", "需重新执行脚本以重置", 3) end).Position = UDim2.new(0, 0, 0, 340)

-- 快捷类
local quickPage = CreatePage("Quick")
CreateSideButton("⚡", "快捷类", "Quick")
local quickList = {
    {"无限连跳", function(v) CFG.Movement.InfiniteJump = v end},
    {"人物加速", function(v) CFG.Movement.Enabled = v end},
    {"自瞄", function(v) CFG.Aimbot.Enabled = v end},
    {"快速搭路(飞行)", function(v) CFG.Movement.FlyEnabled = v end},
    {"近战范围(甩飞)", function(v) CFG.SilentFlail.Enabled = v end},
    {"刀暴(Ragebot)", function(v) if v then _G.RageStart() else _G.RageStop() end end},
    {"观察者模式", function(v) if v and CFG.Obs.Target then sObs(CFG.Obs.Target) else stopObs() end end}
}
for i, item in ipairs(quickList) do
    CreateToggle(quickPage, item[1], false, item[2]).Position = UDim2.new(0, 0, 0, (i-1) * 35)
end

for n, p in pairs(pages) do p.Visible = (n == "General") end
notify("CA-HUB", "UI 加载完成", 3)