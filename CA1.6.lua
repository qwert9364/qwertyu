local CG=game:GetService("CoreGui")
local PG=game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
for _,g in ipairs(CG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
for _,g in ipairs(PG:GetChildren())do pcall(function()if g:IsA("ScreenGui")and(g.Name:find("CSGO")or g.Name:find("YI_")or g.Name:find("csgo")or g.Name:find("NF_"))then g:Destroy()end end)end
task.wait(0.15)
local SG=PG
local WUI=loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
WUI.TransparencyValue=0.2 WUI:SetTheme("Dark")
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local LP=Players.LocalPlayer
local CFG={
 Aimbot={Enabled=false,IgnoreTeammate=true},
 Movement={Enabled=false,Speed=32,JumpEnabled=false,JumpPower=50,InfiniteJump=false,FlyEnabled=false,FlySpeed=60,FlyNoClip=false},
 Invisible={Enabled=false,Alpha=1},
 Fall={Enabled=false},
 Spin={Target=nil,Strength=5,Duration=3.0},
 Obs={Target=nil,Mode="Third",Offset=6,Active=false},
 ESP={Enabled=false,TeamCheck=true,HideTeammate=false,ShowName=true,ShowHealth=true,ShowDistance=false,ShowCover=true,ShowDanger=true,MaxDistance=800,Chams=false,ChamsTeamColor=true,ChamsFillTransparency=0.5},
 Aim={fovsize=150,distance=200,wallCheck=false,smoothness=5,aimSpeed=5,priority="Smart",bodyPart="头部",activate="自动",hotkey=Enum.KeyCode.LeftControl,
      StrongLock=false,LockView=false,
      AIPred=false,PredStrength=1.0,BulletSpeed=1200,PredVertical=0.7,PredRelative=false,PredSmooth=true},
 Follow={Enabled=false,Target=nil},
 Alert={Aim=false,Nearby=false,LowHP=false,AimDist=300,NearbyDist=80,HPThresh=30,Cooldown=2},
 SubChase={Enabled=false},
 AngryBot={Enabled=false},
 Emergency={Enabled=false,LockView=true,Range=300,BulletWindow=1.2},
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
 if CFG.Aim.PredRelative then
  local mc=LP.Character
  local mr=mc and mc:FindFirstChild("HumanoidRootPart")
  if mr then vel=vel-mr.AssemblyLinearVelocity end
 end
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
RS.RenderStepped:Connect(function()pcall(doAim)end)

local DEF_WALK=16
local DEF_JUMP=50
local function recordDefaults()
 local c=LP.Character
 if not c then return end
 local h=c:WaitForChild("Humanoid",5)
 if not h then return end
 DEF_WALK=h.WalkSpeed
 if h.UseJumpPower then DEF_JUMP=h.JumpPower
 else DEF_JUMP=h.JumpHeight*7.5 end
end
LP.CharacterAdded:Connect(function()task.wait(0.5)recordDefaults()end)
task.spawn(function()task.wait(1)recordDefaults()end)

-- 移动 / 跳跃
task.spawn(function()
 while task.wait(0.1)do
  local c=LP.Character
  if not c then continue end
  local h=c:FindFirstChildOfClass("Humanoid")
  if not h then continue end
  if CFG.Movement.Enabled then
   if h.WalkSpeed~=CFG.Movement.Speed then pcall(function()h.WalkSpeed=CFG.Movement.Speed end)end
  else
   if DEF_WALK~=CFG.Movement.Speed and h.WalkSpeed~=DEF_WALK then
    pcall(function()h.WalkSpeed=DEF_WALK end)
   end
  end
  if CFG.Movement.JumpEnabled then
   pcall(function()
    if h.UseJumpPower then h.JumpPower=CFG.Movement.JumpPower
    else h.JumpHeight=CFG.Movement.JumpPower/7.5 end
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

-- ==================== 隐身 ====================
task.spawn(function()
 while task.wait(0.05)do
  local c=LP.Character
  if not c then continue end
  for _,part in ipairs(c:GetDescendants())do
   if part:IsA("BasePart") then
    if CFG.Invisible.Enabled then
     pcall(function()part.LocalTransparencyModifier=CFG.Invisible.Alpha end)
    else
     if part.LocalTransparencyModifier~=0 then
      pcall(function()part.LocalTransparencyModifier=0 end)
     end
    end
   elseif part:IsA("Decal") then
    if CFG.Invisible.Enabled then
     pcall(function()part.Transparency=CFG.Invisible.Alpha end)
    else
     if part.Transparency~=0 then
      pcall(function()part.Transparency=0 end)
     end
    end
   end
  end
 end
end)

-- ==================== 应急反应 ====================
local BulletCandidate=nil
local BULLET_KEYS={"bullet","projectile","shot","pellet","arrow","missile","rocket","ball","ammo"}
local function isBulletPart(obj)
 if not obj:IsA("BasePart") then return false end
 if obj.Anchored then return false end
 local nm=obj.Name:lower()
 for _,k in ipairs(BULLET_KEYS) do
  if nm:find(k) then return true end
 end
 if obj.Size.Magnitude<2.5 then return true end
 return false
end
WS.DescendantAdded:Connect(function(obj)
 if not CFG.Emergency.Enabled then return end
 if not isBulletPart(obj) then return end
 task.wait(0.03)
 if not obj.Parent then return end
 local mc=LP.Character
 if not mc then return end
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
 local ac=attacker.Character
 if not ac then return false end
 local ah=ac:FindFirstChild("Head") or ac:FindFirstChild("HumanoidRootPart")
 if not ah then return false end
 local cm=cam()
 if not cm then return false end
 pcall(function()
  cm.CFrame=CFrame.new(cm.CFrame.Position,ah.Position)
  if CFG.Emergency.LockView then
   cm.Focus=CFrame.new(cm.CFrame.Position+cm.CFrame.LookVector*100)
  end
 end)
 return true
end
local function pickFacing()
 local mc=LP.Character
 if not mc then return nil end
 local mh=mc:FindFirstChild("Head") or mc:FindFirstChild("HumanoidRootPart")
 if not mh then return nil end
 local best,bestScore=nil,-math.huge
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and alive(p) and not isMate(p) then
   local pc=p.Character
   local ph=pc and pc:FindFirstChild("Head")
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
  local mc=LP.Character
  if not mc then lastHP=-1 continue end
  local mh=mc:FindFirstChildOfClass("Humanoid")
  if not mh then lastHP=-1 continue end
  if lastHP<0 then lastHP=mh.Health continue end
  if not CFG.Emergency.Enabled then lastHP=mh.Health continue end
  if mh.Health<lastHP and mh.Health>0 then
   local attacker=nil
   if BulletCandidate and tick()-BulletCandidate.t<CFG.Emergency.BulletWindow then
    local p=BulletCandidate.attacker
    if p and p.Parent and alive(p) then attacker=p end
   end
   if not attacker then attacker=pickFacing() end
   if attacker then
    emergencyAim(attacker)
    notify("应急反应","锁定 "..attacker.Name,1.5)
   end
  end
  lastHP=mh.Health
 end
end)

-- 子追
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

-- Ragebot
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
  local character=LP.Character
  if not character then return targets end
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

-- ==================== ESP ====================
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
 local c=p.Character
 if not c then return false end
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
 local chamsTrans=CFG.ESP.ChamsFillTransparency
 local vp=cm.ViewportSize
 local cx=vp.X/2
 local cy=vp.Y
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
    d.vis=false
    d.box.Visible=false
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
  if armed then col=CO_RED
  elseif mt then col=CO_GREEN
  else col=CO_PINK end
  d.box.Position=Vector2.new(x1,topY)
  d.box.Size=Vector2.new(boxW,boxH)
  d.box.Color=col
  d.box.Visible=true
  if d.tracer then
   d.tracer.From=Vector2.new(cx,cy)
   d.tracer.To=Vector2.new(hp.X,topY)
   d.tracer.Color=col
   d.tracer.Visible=true
  end
  d.name.Visible=showName
  if showName then
   d.name.Position=Vector2.new(hp.X,topY-16)
   d.name.Text=p.Name
   d.name.Color=col
  end
  d.dist.Visible=showDist
  if showDist then
   d.dist.Position=Vector2.new(hp.X,botY+2)
   d.dist.Text=math.floor(ds).."m"
   d.dist.Color=CO_WHITE
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
    d.hl.Adornee=c d.hl.Enabled=true d.hl.FillTransparency=chamsTrans
    d.hl.FillColor=CO_PINK d.hl.OutlineColor=CO_PINK
   else d.hl.Enabled=false d.hl.Adornee=nil end
  end
 end
end)

-- ==================== 其他 ====================
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
 local fv=Vector3.new(0,0,0)
 if UIS:IsKeyDown(Enum.KeyCode.Space)then fv=fv+Vector3.new(0,CFG.Movement.FlySpeed,0)end
 if UIS:IsKeyDown(Enum.KeyCode.LeftShift)then fv=fv-Vector3.new(0,CFG.Movement.FlySpeed,0)end
 local fvv=mv+fv
 if FBV and FBV.Parent then FBV.Velocity=fvv end
 if FBG and FBG.Parent then FBG.CFrame=CFrame.new(r.Position,r.Position+cm.CFrame.LookVector)end
end end)

local NB={}local NCA=false
local function apNC()
 local c=LP.Character if not c then return end
 NB={}for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then NB[p]=p.CanCollide pcall(function()p.CanCollide=false end)end end
 NCA=true
end
local function rmNC()
 for p,o in pairs(NB)do if p and p.Parent then pcall(function()p.CanCollide=o end)end end
 NB={}NCA=false
end
_G.__NCS=0
LP.CharacterAdded:Connect(function()NB={}NCA=false _G.__NCS=0 end)
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
task.spawn(function()while true do RS.Stepped:Wait()
 if not CFG.Movement.FlyNoClip then if NCA then rmNC()end _G.__NCS=0 continue end
 local c=LP.Character if not c then continue end
 local r=c:FindFirstChild("HumanoidRootPart")local h=c:FindFirstChildOfClass("Humanoid")
 if not r or not h then continue end
 if not NCA then apNC()end
 local rd=h.MoveDirection
 if rd.Magnitude<0.01 then _G.__NCS=0 continue end
 local md=Vector3.new(rd.X,0,rd.Z)
 if md.Magnitude<0.001 then _G.__NCS=0 continue end
 md=md.Unit
 local P=bP(c)
 if not pr(r.Position,md,NC.PRE,P)then _G.__NCS=0 continue end
 local gp=fG(r.Position,md,P)
 if gp then _G.__NCS=0 local dl=gp-r.Position if dl.Magnitude>NC.MAX_TP then gp=r.Position+dl.Unit*NC.MAX_TP end r.CFrame=r.CFrame-r.CFrame.Position+gp
 else _G.__NCS=_G.__NCS+1
  if _G.__NCS>=NC.STUCK then local bk=r.Position-md*NC.BACK r.CFrame=r.CFrame-r.CFrame.Position+bk _G.__NCS=0
  else local np=r.Position+md*NC.STEP r.CFrame=r.CFrame-r.CFrame.Position+np end
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

local skidFling=function(T)
 local Character=LP.Character
 local Humanoid=Character and Character:FindFirstChildOfClass("Humanoid")
 local RootPart=Humanoid and Humanoid.RootPart
 if not(Character and Humanoid and RootPart)then return false end
 local TC=T.Character if not TC then return false end
 local TH=TC:FindFirstChildOfClass("Humanoid")
 local TR=TH and TH.RootPart
 local THead=TC:FindFirstChild("Head")
 if not TC:FindFirstChildWhichIsA("BasePart")then return false end
 getgenv().__P=RootPart.CFrame
 getgenv().__F=WS.FallenPartsDestroyHeight
 local function FPos(bp,pos,ang)
  RootPart.CFrame=CFrame.new(bp.Position)*pos*ang
  if Character.PrimaryPart then pcall(function()Character:SetPrimaryPartCFrame(CFrame.new(bp.Position)*pos*ang)end)end
  RootPart.Velocity=Vector3.new(9e7,9e7*10,9e7)
  RootPart.RotVelocity=Vector3.new(9e8,9e8,9e8)
 end
 local function SFBP(bp)
  if not bp then return end
  local TW=2 local T0=tick() local A=0
  repeat
   if RootPart and TH and bp.Parent then
    if bp.Velocity.Magnitude<50 then
     A=A+100
     FPos(bp,CFrame.new(0,1.5,0)+TH.MoveDirection*bp.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(A),0,0))task.wait()
     FPos(bp,CFrame.new(0,-1.5,0)+TH.MoveDirection*bp.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(A),0,0))task.wait()
    else
     FPos(bp,CFrame.new(0,1.5,TH.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()
     FPos(bp,CFrame.new(0,-1.5,-TH.WalkSpeed),CFrame.Angles(0,0,0))task.wait()
    end
   else break end
  until bp.Velocity.Magnitude>500 or bp.Parent~=TC or T.Parent~=Players or TH.Sit or Humanoid.Health<=0 or tick()>T0+TW
 end
 pcall(function()
  WS.FallenPartsDestroyHeight=0/0
  local BV=Instance.new("BodyVelocity")BV.Parent=RootPart BV.Velocity=Vector3.new(9e8,9e8,9e8)BV.MaxForce=Vector3.new(1/0,1/0,1/0)
  Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
  if TR and THead then
   if(TR.CFrame.p-THead.CFrame.p).Magnitude>5 then SFBP(THead)else SFBP(TR)end
  elseif TR then SFBP(TR)
  elseif THead then SFBP(THead)end
  BV:Destroy()
  Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
 end)
 task.wait(0.5)
 pcall(function()
  local cnt=0
  repeat
   RootPart.CFrame=getgenv().__P*CFrame.new(0,0.5,0)
   if Character.PrimaryPart then pcall(function()Character:SetPrimaryPartCFrame(getgenv().__P*CFrame.new(0,0.5,0))end)end
   pcall(function()Humanoid:ChangeState("GettingUp")end)
   for _,x in ipairs(Character:GetChildren())do if x:IsA("BasePart")then x.Velocity,x.RotVelocity=Vector3.new(),Vector3.new()end end
   cnt=cnt+1 task.wait()
  until(RootPart.Position-getgenv().__P.p).Magnitude<25 or cnt>60
  WS.FallenPartsDestroyHeight=getgenv().__F
 end)
 return true
end
local function flailAll()
 task.spawn(function()
  local list={}
  for _,p in ipairs(Players:GetPlayers())do if p~=LP then table.insert(list,p)end end
  notify("甩全部","共 "..#list)
  for _,p in ipairs(list)do if p.Character then pcall(function()skidFling(p)end)task.wait(0.3)end end
  notify("甩全部","完成")
 end)
end
local SF={A=false,BP=nil,BV=nil,BAV=nil}
local function clSF()
 if SF.BP then pcall(function()SF.BP:Destroy()end)SF.BP=nil end
 if SF.BV then pcall(function()SF.BV:Destroy()end)SF.BV=nil end
 if SF.BAV then pcall(function()SF.BAV:Destroy()end)SF.BAV=nil end
 local c=LP.Character
 if c then local h=c:FindFirstChildOfClass("Humanoid")if h then pcall(function()h.PlatformStand=false end)end end
 SF.A=false
end
local function spFl(t)
 if not t or not t.Character then notify("甩飞","无效")return end
 if SF.A then notify("甩飞","进行中")return end
 local tc=t.Character
 local tr=tc:FindFirstChild("HumanoidRootPart")if not tr then notify("甩飞","无HRP")return end
 local mc=LP.Character if not mc then return end
 local mr=mc:FindFirstChild("HumanoidRootPart")if not mr then return end
 local s=math.clamp(CFG.Spin.Strength,1,10)
 local sp=s*80 local bpP=5000+s*2500 local mb=1+s*5 local dur=CFG.Spin.Duration
 SF.A=true
 task.spawn(function()
  for _,p in ipairs(mc:GetDescendants())do if p:IsA("BasePart")then pcall(function()p.CanCollide=true p.Massless=false end)end end
  pcall(function()local pp=PhysicalProperties.new(1.0*mb,0.3,0.5,1,1)mr.CustomPhysicalProperties=pp end)
  local mh=mc:FindFirstChildOfClass("Humanoid")if mh then pcall(function()mh.PlatformStand=true end)end
  local bp=Instance.new("BodyPosition")bp.MaxForce=Vector3.new(1e7,1e7,1e7)bp.P=bpP bp.D=bpP*0.05 bp.Position=mr.Position bp.Parent=mr SF.BP=bp
  local bv=Instance.new("BodyVelocity")bv.MaxForce=Vector3.new(1e6,1e6,1e6)bv.Parent=mr SF.BV=bv
  local bav=Instance.new("BodyAngularVelocity")bav.MaxTorque=Vector3.new(1e6,1e6,1e6)bav.AngularVelocity=Vector3.new(0,80,0)bav.Parent=mr SF.BAV=bav
  local t0=tick()
  while SF.A and(tick()-t0<dur)do
   if not mr.Parent or not tr.Parent then break end
   if mh and mh.Parent and mh.Health<mh.MaxHealth then pcall(function()mh.Health=mh.MaxHealth end)end
   local tPos=tr.Position
   local d=tPos-mr.Position
   if d.Magnitude<0.1 then d=Vector3.new(0,1,0)end
   d=d.Unit local sd=(d+Vector3.new(0,0.6,0)).Unit
   bp.Position=tPos+Vector3.new(0,1,0)
   bv.Velocity=sd*sp
   bav.AngularVelocity=Vector3.new(math.random(-80,80),80,math.random(-80,80))
   RS.Stepped:Wait()
  end
  clSF()notify("甩飞","完成")
 end)
 notify("甩飞","强度 "..CFG.Spin.Strength.." → "..t.Name)
end
local function tpTo(p)
 if not p or not p.Character then return end
 local hd=p.Character:FindFirstChild("Head")or p.Character:FindFirstChild("HumanoidRootPart")
 if not hd then return end
 local mc=LP.Character if not mc then return end
 local mr=mc:FindFirstChild("HumanoidRootPart")if not mr then return end
 mr.CFrame=CFrame.new(hd.Position+Vector3.new(0,3,0))
 notify("传送","已传送到 "..p.Name)
end
RS.Heartbeat:Connect(function()
 if not CFG.Follow.Enabled then return end
 local p=CFG.Follow.Target
 if not p or not p.Parent or not p.Character then return end
 local hd=p.Character:FindFirstChild("HumanoidRootPart")if not hd then return end
 local mc=LP.Character if not mc then return end
 local mr=mc:FindFirstChild("HumanoidRootPart")if not mr then return end
 local back=hd.CFrame.LookVector*-5
 mr.CFrame=CFrame.new(hd.Position+back+Vector3.new(0,2,0))
end)

local function getNames()local l={}for _,p in ipairs(Players:GetPlayers())do if p~=LP then table.insert(l,p.Name)end end if #l==0 then table.insert(l,"(无玩家)")end return l end

local UNIQUE_FOLDER="NF_Script_"..tostring(os.time())
local W=WUI:CreateWindow({Title="CA-HUB",Icon="crosshair",Author="奶佛",Folder=UNIQUE_FOLDER,Size=UDim2.fromOffset(680,480),Theme="Dark",User={Enabled=true,Anonymous=true,Callback=function()WUI:Notify({Title="关于",Content="CA-HUB",Duration=3})end},SideBarWidth=180,ScrollBarEnabled=true})
local MS=W:Section({Title="主要功能",Opened=true})
local AT=MS:Tab({Title="自瞄",Icon="crosshair"})
local MT=MS:Tab({Title="主要类",Icon="zap"})
local ET=MS:Tab({Title="透视",Icon="eye"})
local FT=MS:Tab({Title="甩飞",Icon="wind"})
local BT=MS:Tab({Title="子追",Icon="target"})
local AB=MS:Tab({Title="Ragebot",Icon="flame"})
local OT=MS:Tab({Title="观察者",Icon="video"})
local PT=MS:Tab({Title="玩家列表",Icon="users"})
local EFT=MS:Tab({Title="特效",Icon="sparkles"})

AT:Toggle({Title="自瞄开关",Value=false,Callback=function(v)CFG.Aimbot.Enabled=v nTg("自瞄",v)end})
AT:Toggle({Title="不瞄队友",Value=true,Callback=function(v)CFG.Aimbot.IgnoreTeammate=v end})
AT:Dropdown({Title="锁定部位",Values={"头部","躯干","左臂","右臂","左腿","右腿"},Callback=function(v)CFG.Aim.bodyPart=v end})
AT:Dropdown({Title="优先级",Values={"Smart","Distance","Crosshair","Speed"},Callback=function(v)CFG.Aim.priority=v end})
AT:Dropdown({Title="激活方式",Values={"自动","按住"},Callback=function(v)CFG.Aim.activate=v end})
AT:Slider({Title="瞄准速度",Value={Min=1,Max=20,Default=5},Callback=function(v)CFG.Aim.aimSpeed=v end})
AT:Slider({Title="平滑度",Value={Min=1,Max=20,Default=5},Callback=function(v)CFG.Aim.smoothness=v end})
AT:Slider({Title="FOV",Value={Min=20,Max=500,Default=150},Callback=function(v)CFG.Aim.fovsize=v end})
AT:Slider({Title="最大距离",Value={Min=50,Max=2000,Default=200},Callback=function(v)CFG.Aim.distance=v end})
AT:Toggle({Title="掩体识别",Value=false,Callback=function(v)CFG.Aim.wallCheck=v end})
AT:Divider()
AT:Toggle({Title="强锁",Value=false,Callback=function(v)CFG.Aim.StrongLock=v nTg("强锁",v)end})
AT:Toggle({Title="锁死视角",Value=false,Callback=function(v)CFG.Aim.LockView=v nTg("锁死视角",v)end})
AT:Divider()
AT:Toggle({Title="AI预判",Value=false,Callback=function(v)CFG.Aim.AIPred=v nTg("AI预判",v)end})
AT:Slider({Title="预判强度",Value={Min=0.1,Max=3,Default=1},Callback=function(v)CFG.Aim.PredStrength=v end})
AT:Slider({Title="子弹速度",Value={Min=200,Max=3000,Default=1200},Callback=function(v)CFG.Aim.BulletSpeed=v end})
AT:Slider({Title="垂直预判比例",Value={Min=0,Max=1,Default=0.7},Callback=function(v)CFG.Aim.PredVertical=v end})
AT:Toggle({Title="相对速度补偿",Value=false,Callback=function(v)CFG.Aim.PredRelative=v nTg("相对速度",v)end})
AT:Toggle({Title="速度平滑",Value=true,Callback=function(v)CFG.Aim.PredSmooth=v end})

MT:Toggle({Title="加速",Value=false,Callback=function(v)CFG.Movement.Enabled=v nTg("加速",v)end})
MT:Slider({Title="移动速度",Value={Min=16,Max=300,Default=32},Callback=function(v)CFG.Movement.Speed=v end})
MT:Paragraph({Title="提示",Content="关闭后自动恢复默认移速。"})
MT:Toggle({Title="跳跃增强",Value=false,Callback=function(v)CFG.Movement.JumpEnabled=v nTg("跳跃",v)end})
MT:Slider({Title="跳跃力",Value={Min=50,Max=300,Default=50},Callback=function(v)CFG.Movement.JumpPower=v end})
MT:Toggle({Title="无限连跳",Value=false,Callback=function(v)CFG.Movement.InfiniteJump=v nTg("无限连跳",v)end})
MT:Toggle({Title="飞行",Value=false,Callback=function(v)CFG.Movement.FlyEnabled=v nTg("飞行",v)end})
MT:Slider({Title="飞行速度",Value={Min=20,Max=500,Default=60},Callback=function(v)CFG.Movement.FlySpeed=v end})
MT:Toggle({Title="飞行穿墙",Value=false,Callback=function(v)CFG.Movement.FlyNoClip=v nTg("穿墙",v)end})
MT:Toggle({Title="免疫摔伤",Value=false,Callback=function(v)CFG.Fall.Enabled=v nTg("免疫摔",v)end})
MT:Divider()
MT:Toggle({Title="隐身",Value=false,Callback=function(v)CFG.Invisible.Enabled=v nTg("隐身",v)end})
MT:Paragraph({Title="说明",Content="本地隐身：自己视角下角色变透明。透明度 1 完全消失，0.5 半透明。这是本地效果，别人看不到你变化。"})
MT:Slider({Title="隐身透明度",Value={Min=0,Max=1,Default=1},Callback=function(v)CFG.Invisible.Alpha=v end})
MT:Divider()
MT:Toggle({Title="应急反应",Value=false,Callback=function(v)CFG.Emergency.Enabled=v nTg("应急反应",v)end})
MT:Paragraph({Title="说明",Content="被击中时镜头瞬间瞄向攻击者。优先通过朝你飞来的子弹反推发射者，找不到才回退到附近最正对你的敌人。"})
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
  local now=tick()
  local cd=CFG.Alert.Cooldown
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
       if prr.CFrame.LookVector:Dot(toMe)>0.985 and los(ph) then
        AL.LastAim=now
        notify("被瞄预警",p.Name.." 正瞄准你 ( "..math.floor(dist).."m )",2)
        break
       end
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
      if dist<=CFG.Alert.NearbyDist then AL.LastNear=now notify("附近预警",p.Name.." 靠近 ( "..math.floor(dist).."m )",2)break end
     end
    end
   end
  end
 end
end)

ET:Toggle({Title="透视开关",Value=false,Callback=function(v)CFG.ESP.Enabled=v nTg("透视",v)end})
ET:Toggle({Title="队伍识别",Value=true,Callback=function(v)CFG.ESP.TeamCheck=v end})
ET:Toggle({Title="屏蔽队友",Value=false,Callback=function(v)CFG.ESP.HideTeammate=v end})
ET:Toggle({Title="显示名字",Value=true,Callback=function(v)CFG.ESP.ShowName=v end})
ET:Toggle({Title="显示血量",Value=true,Callback=function(v)CFG.ESP.ShowHealth=v end})
ET:Toggle({Title="显示距离",Value=false,Callback=function(v)CFG.ESP.ShowDistance=v end})
ET:Toggle({Title="显示掩体状态",Value=true,Callback=function(v)CFG.ESP.ShowCover=v end})
ET:Paragraph({Title="说明",Content="框右侧：「有」=掩体后，「无」=暴露。"})
ET:Toggle({Title="显示危险状态",Value=true,Callback=function(v)CFG.ESP.ShowDanger=v end})
ET:Paragraph({Title="说明",Content="目标手持武器时框变红，头顶显示「⚠ 持武器」。"})
ET:Slider({Title="最大距离",Value={Min=100,Max=5000,Default=800},Callback=function(v)CFG.ESP.MaxDistance=v end})
ET:Toggle({Title="Chams 内透",Value=false,Callback=function(v)CFG.ESP.Chams=v nTg("Chams",v)end})
ET:Slider({Title="填充透明",Value={Min=0,Max=1,Default=0.5},Callback=function(v)CFG.ESP.ChamsFillTransparency=v end})

local FDD=FT:Dropdown({Title="选择目标",Values=getNames(),Callback=function(v)for _,p in ipairs(Players:GetPlayers())do if p.Name==v then CFG.Spin.Target=p break end end end})
FT:Button({Title="刷新",Callback=function()if type(FDD.Refresh)=="function"then pcall(function()FDD:Refresh(getNames())end)end end})
FT:Slider({Title="强度",Value={Min=1,Max=10,Default=5},Callback=function(v)CFG.Spin.Strength=v end})
FT:Slider({Title="持续",Value={Min=1,Max=10,Default=3},Callback=function(v)CFG.Spin.Duration=v end})
FT:Button({Title="甩飞",Callback=function()spFl(CFG.Spin.Target)end})
FT:Button({Title="停止",Callback=function()clSF()notify("甩飞","停止")end})
FT:Divider()
FT:Button({Title="SkidFling 单个",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Character or t==LP then notify("单个","无效")return end
 task.spawn(function()pcall(function()skidFling(t)end)end)
end})
FT:Button({Title="SkidFling 全部",Callback=function()flailAll()end})

BT:Toggle({Title="子追开关",Value=false,Callback=function(v)
 CFG.SubChase.Enabled=v
 if v then enableSubChase() else disableSubChase() end
end})
BT:Paragraph({Title="要求",Content="必须先进对局拿到枪再开。"})

AB:Toggle({Title="Ragebot 开关",Value=false,Callback=function(v)
 if v then _G.RageStart() else _G.RageStop() end
end})
AB:Paragraph({Title="要求",Content="必须先进对局拿到枪再开。"})

local ODD=OT:Dropdown({Title="选择目标",Values=getNames(),Callback=function(v)for _,p in ipairs(Players:GetPlayers())do if p.Name==v then CFG.Obs.Target=p break end end end})
OT:Button({Title="刷新",Callback=function()if type(ODD.Refresh)=="function"then pcall(function()ODD:Refresh(getNames())end)end end})
OT:Dropdown({Title="视角",Values={"First","Third","Top","Side"},Callback=function(v)CFG.Obs.Mode=v end})
OT:Slider({Title="偏移",Value={Min=0,Max=20,Default=6},Callback=function(v)CFG.Obs.Offset=v end})
OT:Button({Title="观察",Callback=function()sObs(CFG.Obs.Target)end})
OT:Button({Title="退出",Callback=function()stopObs()end})

local PTDD=PT:Dropdown({Title="选择玩家",Values=getNames(),Callback=function(v)
 for _,p in ipairs(Players:GetPlayers())do if p.Name==v then CFG.Spin.Target=p break end end
end})
PT:Button({Title="刷新玩家列表",Callback=function()
 if type(PTDD.Refresh)=="function"then pcall(function()PTDD:Refresh(getNames())end)end
 notify("玩家列表","已刷新",2)
end})
PT:Divider()
PT:Button({Title="传送到选中玩家",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Parent then notify("传送","未选择目标",2)return end
 tpTo(t)
end})
PT:Button({Title="持续追敌",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Parent then notify("跟随","未选择目标",2)return end
 if CFG.Follow.Target==t and CFG.Follow.Enabled then
  CFG.Follow.Enabled=false CFG.Follow.Target=nil notify("跟随","已停止",2)
 else
  CFG.Follow.Target=t CFG.Follow.Enabled=true notify("跟随","追踪 "..t.Name,2)
 end
end})
PT:Button({Title="甩飞选中玩家",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Parent then notify("甩飞","未选择目标",2)return end
 spFl(t)
end})
PT:Button({Title="SkidFling 选中玩家",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Character or not t.Parent or t==LP then notify("SkidFling","未选择目标",2)return end
 task.spawn(function()pcall(function()skidFling(t)end)end)
end})

EFT:Toggle({Title="夜视",Value=false,Callback=function(v)
 local L=game:GetService("Lighting")
 if v then
  getgenv().__NV={B=L.Brightness,A=L.Ambient,OA=L.OutdoorAmbient,C=L.ClockTime,F=L.FogEnd}
  L.Brightness=3 L.Ambient=Color3.fromRGB(180,180,180)L.OutdoorAmbient=Color3.fromRGB(180,180,180)L.ClockTime=14 L.FogEnd=100000
  nTg("夜视",true)
 else
  local o=getgenv().__NV
  if o then L.Brightness=o.B L.Ambient=o.A L.OutdoorAmbient=o.OA L.ClockTime=o.C L.FogEnd=o.F end
  nTg("夜视",false)
 end
end})

notify("CA-HUB","加载完成",3)
notify("子追/Ragebot","进入对局拿到枪再开",4)