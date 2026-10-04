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
local RS_2=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer
local CFG={
 Aimbot={Enabled=false,IgnoreTeammate=true},
 Movement={Enabled=false,Speed=32,JumpEnabled=false,JumpPower=50,InfiniteJump=false,FlyEnabled=false,FlySpeed=60,FlyNoClip=false},
 Fall={Enabled=false},
 Spin={Target=nil,Strength=5,Duration=3.0},
 Obs={Target=nil,Mode="Third",Offset=6,Active=false},
 ESP={Enabled=false,TeamCheck=true,HideTeammate=false,ShowName=true,ShowHealth=true,ShowDistance=false,ShowCover=true,MaxDistance=800,Chams=false,ChamsTeamColor=true,ChamsFillTransparency=0.5},
 Aim={fovsize=150,distance=200,wallCheck=false,smoothness=5,aimSpeed=5,priority="Smart",bodyPart="头部",activate="自动",hotkey=Enum.KeyCode.LeftControl,
      StrongLock=false,LockView=false,
      AIPred=false,PredStrength=1.0,BulletSpeed=1200,PredVertical=0.7,PredRelative=false,PredSmooth=true},
 Follow={Enabled=false,Target=nil},
 Alert={Aim=false,Nearby=false,LowHP=false,AimDist=300,NearbyDist=80,HPThresh=30,Cooldown=2},
 SubChase={Enabled=false},
 AngryBot={Enabled=false},
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
 local players=game:GetService("Players")
 local lp=players.LocalPlayer
 local camera=workspace.CurrentCamera
 local closest_part,closest_distance=nil,range
 for _,player in ipairs(players:GetPlayers())do
  if player~=lp then
   local character=player.Character
   if character then
    local humanoid=character:FindFirstChild("Humanoid")
    local head=character:FindFirstChild("Head")
    if head and humanoid and humanoid.Health>0 then
     local sp,on_screen=camera:WorldToViewportPoint(head.Position)
     if on_screen then
      local d=(Vector2.new(sp.X,sp.Y)-camera.ViewportSize/2).Magnitude
      if d<closest_distance then
       closest_part=head
       closest_distance=d
      end
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
 if SubChase.mod and SubChase.orig then
  pcall(function()SubChase.mod.Fire=SubChase.orig end)
 end
 SubChase.on=false
 notify("子追","已关闭",2)
end

-- Ragebot
do
 local Players=game:GetService("Players")
 local ReplicatedStorage=game:GetService("ReplicatedStorage")
 local Workspace=game:GetService("Workspace")
 local RunService=game:GetService("RunService")
 local LocalPlayer=Players.LocalPlayer
 local Camera=Workspace.CurrentCamera
 local currentTarget=nil
 local lastShotTime=0
 local connection=nil
 local function getVisiblePart(targetCharacter)
  if not targetCharacter or not LocalPlayer.Character then return nil end
  local localCharacter=LocalPlayer.Character
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
     local ray=Workspace:Raycast(forwardPos,targetPosition-forwardPos,rayParams)
     if not ray or ray.Instance:IsDescendantOf(targetCharacter) or ray.Instance.Transparency>=0.9 then
      local distance=(targetPosition-forwardPos).Magnitude
      if distance<minDistance then
       minDistance=distance
       bestPart=part
       bestPosition=targetPosition
       bestOrigin=forwardPos
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
 local function playShootSound()
  local sound=Instance.new("Sound")
  sound.SoundId="rbxassetid://6534948092"
  sound.Volume=1
  sound.Parent=Camera
  sound.PlayOnRemove=true
  sound:Destroy()
 end
 local function createBeam(startPos,endPos)
  local part1=Instance.new("Part")
  part1.Anchored=true part1.CanCollide=false part1.Transparency=1
  part1.Size=Vector3.new(0.1,0.1,0.1)part1.Position=startPos part1.Parent=Workspace
  local part2=Instance.new("Part")
  part2.Anchored=true part2.CanCollide=false part2.Transparency=1
  part2.Size=Vector3.new(0.1,0.1,0.1)part2.Position=endPos part2.Parent=Workspace
  local a1=Instance.new("Attachment")a1.Parent=part1
  local a2=Instance.new("Attachment")a2.Parent=part2
  local beam1=Instance.new("Beam")
  beam1.Color=ColorSequence.new(Color3.fromRGB(0,0,0))
  beam1.Transparency=NumberSequence.new(0)
  beam1.Width0=0.25 beam1.Width1=0.25
  beam1.Texture="rbxassetid://7136858729"
  beam1.TextureSpeed=0.8
  beam1.TextureMode=Enum.TextureMode.Wrap
  beam1.Brightness=1 beam1.LightEmission=0 beam1.FaceCamera=true
  beam1.Attachment0=a1 beam1.Attachment1=a2 beam1.Parent=part1
  local beam2=Instance.new("Beam")
  beam2.Color=ColorSequence.new(Color3.fromRGB(180,200,255))
  beam2.Transparency=NumberSequence.new(0.4)
  beam2.Width0=0.12 beam2.Width1=0.12
  beam2.Texture="rbxassetid://7136858729"
  beam2.TextureSpeed=1.2
  beam2.TextureMode=Enum.TextureMode.Wrap
  beam2.Brightness=1.2 beam2.LightEmission=0.6 beam2.FaceCamera=true
  beam2.Attachment0=a1 beam2.Attachment1=a2 beam2.Parent=part1
  local shaking=true
  task.spawn(function()
   while shaking and part1 and part1.Parent do
    a1.Position=Vector3.new(math.random(-3,3)/100,math.random(-3,3)/100,math.random(-3,3)/100)
    a2.Position=Vector3.new(math.random(-3,3)/100,math.random(-3,3)/100,math.random(-3,3)/100)
    task.wait(0.02)
   end
  end)
  task.delay(math.random(10,40)/10,function()
   shaking=false
   for i=0,1,0.05 do
    if not part1 or not part1.Parent then break end
    beam1.Transparency=NumberSequence.new(i)
    beam2.Transparency=NumberSequence.new(0.4+i*0.6)
    task.wait(0.03)
   end
   pcall(function()part1:Destroy()end)
   pcall(function()part2:Destroy()end)
  end)
 end
 local function shoot(player,targetPart,targetPos,origin)
  local currentTime=tick()
  if currentTime-lastShotTime<0.56 then return false end
  local character=LocalPlayer.Character
  if not character or not targetPart or not origin then return false end
  local direction=(targetPos-origin).Unit
  local time=tick()
  local cframe=CFrame.lookAt(origin,targetPos)
  local clientRemotes=LocalPlayer:FindFirstChild("ClientRemotes")
  if clientRemotes then
   pcall(function()clientRemotes.CheckFire:FireServer(time,origin)end)
   pcall(function()clientRemotes.CheckShot:FireServer(0,0,1,0.8,cframe,targetPos,targetPart,11,time)end)
   pcall(function()clientRemotes.Reload:FireServer()end)
  end
  local gun=ReplicatedStorage:FindFirstChild("ModuleScripts")
  if gun then
   gun=gun:FindFirstChild("GunModules")
   if gun then
    gun=gun:FindFirstChild("Remote")
    if gun then
     pcall(function()gun.ProjectileRender:FireServer(time,character,origin,direction*999999,360,0,Vector3.zero,5,"Bullet")end)
     pcall(function()gun.ProjectileFinished:FireServer(time,CFrame.new(targetPos),"Gib_T",false,15,"rbxassetid://2814354338")end)
    end
   end
  end
  createBeam(origin,targetPos)
  playShootSound()
  lastShotTime=currentTime
  return true
 end
 local function getVisibleTargets()
  local targets={}
  local character=LocalPlayer.Character
  if not character then return targets end
  local humanoidRootPart=character:FindFirstChild("HumanoidRootPart")
  if not humanoidRootPart then return targets end
  local origin=humanoidRootPart.Position
  for _,player in ipairs(Players:GetPlayers())do
   if player~=LocalPlayer and not isDead(player) and player.Character then
    local visiblePart,visiblePos,originPos=getVisiblePart(player.Character)
    if visiblePart and visiblePos and originPos then
     table.insert(targets,{player=player,distance=(visiblePos-origin).Magnitude,part=visiblePart,position=visiblePos,origin=originPos})
    end
   end
  end
  table.sort(targets,function(a,b)return a.distance<b.distance end)
  return targets
 end
 local function startRage()
  if connection then return end
  connection=RunService.Heartbeat:Connect(function()
   pcall(function()
    if currentTarget and not isDead(currentTarget)then
     local targetChar=currentTarget.Character
     if targetChar then
      local visiblePart,visiblePos,origin=getVisiblePart(targetChar)
      if visiblePart and visiblePos and origin then
       shoot(currentTarget,visiblePart,visiblePos,origin)
      else
       currentTarget=nil
      end
     end
    else
     currentTarget=nil
    end
    if not currentTarget then
     local targets=getVisibleTargets()
     if #targets>0 then currentTarget=targets[1].player end
    end
   end)
  end)
  notify("Ragebot","已开启（自动锁最近可见敌人）",2)
 end
 local function stopRage()
  if connection then connection:Disconnect()connection=nil end
  currentTarget=nil
  lastShotTime=0
  notify("Ragebot","已关闭",2)
 end
 _G.RageStart=startRage
 _G.RageStop=stopRage
end

local EG=Instance.new("ScreenGui")EG.Name="CSGOESP"EG.ResetOnSpawn=false EG.IgnoreGuiInset=true EG.Parent=SG
local EC={}
local CO_GREEN=Color3.fromRGB(120,220,130)
local CO_PINK=Color3.fromRGB(255,120,180)
local CO_YELLOW=Color3.fromRGB(255,200,0)
local CO_RED=Color3.fromRGB(220,40,40)
local CO_RED2=Color3.fromRGB(255,60,60)
local CO_GREEN2=Color3.fromRGB(60,220,60)
local CO_WHITE=Color3.fromRGB(200,200,200)
local function mkE(p)
 if EC[p]then if EC[p].bb then EC[p].bb:Destroy()end if EC[p].hl then EC[p].hl:Destroy()end EC[p]=nil end
 local bb=Instance.new("BillboardGui")bb.Size=UDim2.new(0,130,0,70)bb.StudsOffset=Vector3.new(0,3.4,0)bb.AlwaysOnTop=true bb.MaxDistance=CFG.ESP.MaxDistance bb.Parent=EG
 local rt=Instance.new("Frame")rt.Size=UDim2.new(1,0,1,0)rt.BackgroundTransparency=1 rt.Parent=bb
 local nm=Instance.new("TextLabel")nm.Size=UDim2.new(1,0,0,16)nm.BackgroundTransparency=1 nm.Text=p.Name nm.TextColor3=Color3.new(1,1,1)nm.TextStrokeTransparency=0 nm.TextStrokeColor3=Color3.new(0,0,0)nm.Font=Enum.Font.GothamBold nm.TextSize=13 nm.Parent=rt
 local hb=Instance.new("Frame")hb.Size=UDim2.new(1,-20,0,6)hb.Position=UDim2.new(0.5,0,0,18)hb.AnchorPoint=Vector2.new(0.5,0)hb.BackgroundColor3=Color3.fromRGB(20,20,20)hb.BorderSizePixel=0 hb.Parent=rt
 Instance.new("UICorner",hb).CornerRadius=UDim.new(1,0)
 local hf=Instance.new("Frame")hf.Size=UDim2.new(1,0,1,0)hf.BackgroundColor3=CO_PINK hf.BorderSizePixel=0 hf.Parent=hb
 Instance.new("UICorner",hf).CornerRadius=UDim.new(1,0)
 local dl=Instance.new("TextLabel")dl.Size=UDim2.new(1,0,0,14)dl.Position=UDim2.new(0,0,0,26)dl.BackgroundTransparency=1 dl.Text="0m"dl.TextColor3=CO_WHITE dl.TextStrokeTransparency=0 dl.TextStrokeColor3=Color3.new(0,0,0)dl.Font=Enum.Font.Gotham dl.TextSize=11 dl.Parent=rt
 local cl=Instance.new("TextLabel")cl.Size=UDim2.new(1,0,0,14)cl.Position=UDim2.new(0,0,0,40)cl.BackgroundTransparency=1 cl.Text="掩体: --"cl.TextColor3=Color3.new(1,1,1)cl.TextStrokeTransparency=0 cl.TextStrokeColor3=Color3.new(0,0,0)cl.Font=Enum.Font.GothamBold cl.TextSize=11 cl.Parent=rt
 local hl=Instance.new("Highlight")hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.OutlineColor=CO_PINK hl.OutlineTransparency=0 hl.FillColor=CO_PINK hl.FillTransparency=0.5 hl.Enabled=false hl.Parent=EG
 EC[p]={bb=bb,rt=rt,nm=nm,hf=hf,dl=dl,cl=cl,hl=hl,vis=false,lastHp=-1,lastDist=-1,lastCover=-1,lastChams=false}
end
local function rmE(p)
 if EC[p]then if EC[p].bb then EC[p].bb:Destroy()end if EC[p].hl then EC[p].hl:Destroy()end EC[p]=nil end
 LOS_CACHE[p]=nil PredCache[p]=nil
end
RS.RenderStepped:Connect(function()
 local cm=cam()if not cm then return end
 local camPos=cm.CFrame.Position
 local espOn=CFG.ESP.Enabled local maxDist=CFG.ESP.MaxDistance
 local teamCheck=CFG.ESP.TeamCheck local hideMate=CFG.ESP.HideTeammate
 local showName=CFG.ESP.ShowName local showHP=CFG.ESP.ShowHealth
 local showDist=CFG.ESP.ShowDistance local showCover=CFG.ESP.ShowCover
 local chams=CFG.ESP.Chams local chamsTrans=CFG.ESP.ChamsFillTransparency
 local chamsTeam=CFG.ESP.ChamsTeamColor
 for p,d in pairs(EC)do
  if not p.Parent then rmE(p)continue end
  local c=p.Character
  local hd=c and c:FindFirstChild("Head")
  local hm=c and c:FindFirstChildOfClass("Humanoid")
  if not hd or not hm or hm.Health<=0 then
   if d.vis then d.vis=false d.rt.Visible=false if d.hl then d.hl.Enabled=false end d.lastChams=false end
   continue
  end
  local ds=(camPos-hd.Position).Magnitude
  if ds>maxDist then
   if d.vis then d.vis=false d.rt.Visible=false if d.hl then d.hl.Enabled=false end d.lastChams=false end
   continue
  end
  local mt=teamCheck and isMate(p)
  local hid=hideMate and mt
  local wantVis=espOn and not hid
  if wantVis~=d.vis then
   d.vis=wantVis d.rt.Visible=wantVis
   if not wantVis and d.hl then d.hl.Enabled=false d.lastChams=false end
  end
  if not wantVis then continue end
  if d.bb.Adornee~=hd then d.bb.Adornee=hd end
  if d.bb.MaxDistance~=maxDist then d.bb.MaxDistance=maxDist end
  if d.nm.Visible~=showName then d.nm.Visible=showName end
  local col=mt and CO_GREEN or CO_PINK
  if d.nm.TextColor3~=col then d.nm.TextColor3=col end
  if d.hf.Visible~=showHP then d.hf.Visible=showHP end
  if showHP then
   local hp=math.clamp(hm.Health/hm.MaxHealth,0,1)
   if math.abs(hp-d.lastHp)>0.005 then
    d.lastHp=hp d.hf.Size=UDim2.new(hp,0,1,0)
    local hc=hp>0.6 and CO_GREEN or hp>0.3 and CO_YELLOW or CO_RED
    if d.hf.BackgroundColor3~=hc then d.hf.BackgroundColor3=hc end
   end
  end
  if d.dl.Visible~=showDist then d.dl.Visible=showDist end
  if showDist then
   local di=math.floor(ds)
   if di~=d.lastDist then d.lastDist=di d.dl.Text=di.."m" end
  end
  local needLOS=showCover or (chams and not hid)
  local clear=needLOS and losCached(p,hd) or false
  if d.cl then
   if d.cl.Visible~=showCover then d.cl.Visible=showCover end
   if showCover then
    local cs=clear and 0 or 1
    if cs~=d.lastCover then
     d.lastCover=cs
     if clear then d.cl.Text="掩体: 无"d.cl.TextColor3=CO_GREEN2
     else d.cl.Text="掩体: 有"d.cl.TextColor3=CO_RED2 end
    end
   end
  end
  if d.hl then
   local wantChams=chams and not hid and not clear
   if wantChams~=d.lastChams then
    d.lastChams=wantChams
    if wantChams then
     d.hl.Adornee=c d.hl.Enabled=true d.hl.FillTransparency=chamsTrans
     if chamsTeam then
      if mt then d.hl.FillColor=CO_GREEN d.hl.OutlineColor=CO_GREEN
      else d.hl.FillColor=CO_PINK d.hl.OutlineColor=CO_PINK end
     end
    else d.hl.Enabled=false d.hl.Adornee=nil end
   end
  end
 end
end)
Players.PlayerAdded:Connect(function(p)if p~=LP then mkE(p)end end)
Players.PlayerRemoving:Connect(rmE)
for _,p in ipairs(Players:GetPlayers())do if p~=LP then mkE(p)end end
LP.CharacterAdded:Connect(function()task.wait(0.6)for _,p in ipairs(Players:GetPlayers())do if p~=LP and not EC[p]then mkE(p)end end end)
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
task.spawn(function()while task.wait(0.1)do local c=LP.Character if c then local h=c:FindFirstChildOfClass("Humanoid")
 if h then
  if CFG.Movement.Enabled and h.WalkSpeed~=CFG.Movement.Speed then pcall(function()h.WalkSpeed=CFG.Movement.Speed end)end
  if CFG.Movement.JumpEnabled then pcall(function()if h.UseJumpPower then h.JumpPower=CFG.Movement.JumpPower else h.JumpHeight=CFG.Movement.JumpPower/7.5 end end)end
 end end end end)
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
local fu,fd,fl,fr=false,false,false,false
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
 FA=false fu=false fd=false fl=false fr=false
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
 getgenv().__F=workspace.FallenPartsDestroyHeight
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
     FPos(bp,CFrame.new(2.25,1.5,-2.25)+TH.MoveDirection*bp.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(A),0,0))task.wait()
     FPos(bp,CFrame.new(-2.25,-1.5,2.25)+TH.MoveDirection*bp.Velocity.Magnitude/1.25,CFrame.Angles(math.rad(A),0,0))task.wait()
    else
     FPos(bp,CFrame.new(0,1.5,TH.WalkSpeed),CFrame.Angles(math.rad(90),0,0))task.wait()
     FPos(bp,CFrame.new(0,-1.5,-TH.WalkSpeed),CFrame.Angles(0,0,0))task.wait()
    end
   else break end
  until bp.Velocity.Magnitude>500 or bp.Parent~=TC or T.Parent~=Players or TH.Sit or Humanoid.Health<=0 or tick()>T0+TW
 end
 pcall(function()
  workspace.FallenPartsDestroyHeight=0/0
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
  workspace.FallenPartsDestroyHeight=getgenv().__F
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
 local sp=s*80 local bpP=5000+s*2500 local mb=1+s*5 local dur=CFG.Spin.Duration local iv=1/(8+s*3)
 SF.A=true
 task.spawn(function()
  for _,p in ipairs(mc:GetDescendants())do if p:IsA("BasePart")then pcall(function()p.CanCollide=true p.Massless=false end)end end
  pcall(function()local pp=PhysicalProperties.new(1.0*mb,0.3,0.5,1,1)mr.CustomPhysicalProperties=pp end)
  local mh=mc:FindFirstChildOfClass("Humanoid")if mh then pcall(function()mh.PlatformStand=true end)end
  local bp=Instance.new("BodyPosition")bp.MaxForce=Vector3.new(1e7,1e7,1e7)bp.P=bpP bp.D=bpP*0.05 bp.Position=mr.Position bp.Parent=mr SF.BP=bp
  local bv=Instance.new("BodyVelocity")bv.MaxForce=Vector3.new(1e6,1e6,1e6)bv.Parent=mr SF.BV=bv
  local bav=Instance.new("BodyAngularVelocity")bav.MaxTorque=Vector3.new(1e6,1e6,1e6)bav.AngularVelocity=Vector3.new(0,80,0)bav.Parent=mr SF.BAV=bav
  local t0=tick()local ls=-999
  while SF.A and(tick()-t0<dur)do
   if not mr.Parent or not tr.Parent then break end
   if mh and mh.Parent and mh.Health<mh.MaxHealth then pcall(function()mh.Health=mh.MaxHealth end)end
   local now=tick()local tPos=tr.Position
   local d=tPos-mr.Position
   if d.Magnitude<0.1 then d=Vector3.new(0,1,0)end
   d=d.Unit local sd=(d+Vector3.new(0,0.6,0)).Unit
   bp.Position=tPos+Vector3.new(0,1,0)
   bv.Velocity=sd*sp
   bav.AngularVelocity=Vector3.new(math.random(-80,80),80,math.random(-80,80))
   if now-ls>=iv then ls=now bp.Position=tPos-sd*2.5+Vector3.new(0,1,0)end
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

-- ==================== 音乐播放器 ====================
if not _G.Music then
    _G.Music=Instance.new("Sound")
    _G.Music.Parent=game
end
local Audio=_G.Music
Audio.Volume=1
local MUSIC_CONFIG_FILE="YI_music_config.json"
local MCFG={
    favorites={},
    lyricPosition={x=0,y=50},
    currentLyricColor="白色",
    nextLyricColor="白色",
    volume=100,
    showLyrics=false,
    lyricLocked=true,
    loopMode=false
}
local function loadMusicConfig()
    local ok,data=pcall(readfile,MUSIC_CONFIG_FILE)
    if ok and data then
        local ok2,decoded=pcall(HttpService.JSONDecode,HttpService,data)
        if ok2 and type(decoded)=="table" then
            MCFG.favorites=decoded.favorites or {}
            MCFG.lyricPosition=decoded.lyricPosition or {x=0,y=50}
            MCFG.currentLyricColor=decoded.currentLyricColor or "白色"
            MCFG.nextLyricColor=decoded.nextLyricColor or "白色"
            MCFG.volume=decoded.volume or 100
            MCFG.showLyrics=decoded.showLyrics or false
            MCFG.lyricLocked=decoded.lyricLocked==nil and true or decoded.lyricLocked
            MCFG.loopMode=decoded.loopMode or false
        end
    end
end
local function saveMusicConfig()
    local ok,data=pcall(HttpService.JSONEncode,HttpService,MCFG)
    if ok then pcall(writefile,MUSIC_CONFIG_FILE,data) end
end
loadMusicConfig()
Audio.Volume=MCFG.volume/100

local lyricColorNames={"白色","红色","蓝色","绿色","黄色","紫色","青色","橙色","粉色","棕色","灰色","浅蓝","浅绿","深红","深蓝","金色"}
local lyricColorMap={
    ["白色"]=Color3.new(1,1,1),["红色"]=Color3.new(1,0,0),["蓝色"]=Color3.new(0,0,1),
    ["绿色"]=Color3.new(0,1,0),["黄色"]=Color3.new(1,1,0),["紫色"]=Color3.new(0.6,0,1),
    ["青色"]=Color3.new(0,1,1),["橙色"]=Color3.new(1,0.5,0),["粉色"]=Color3.new(1,0.75,0.8),
    ["棕色"]=Color3.new(0.6,0.4,0.2),["灰色"]=Color3.new(0.5,0.5,0.5),["浅蓝"]=Color3.new(0.5,0.8,1),
    ["浅绿"]=Color3.new(0.5,1,0.5),["深红"]=Color3.new(0.7,0,0),["深蓝"]=Color3.new(0,0,0.7),
    ["金色"]=Color3.new(1,0.84,0)
}

local songList={}
local songHistory={}
local currentSongIndex=nil
local isMusicPlaying=false
local isSearching=false
local searchInputText=""
local lastSearchData=nil
local searchDropdown=nil
local favDropdown=nil
local lyricsData={}
local currentLyricIndex=1
local lyricGui=nil
local lyricLabels={}
local lyricUpdateTask=nil
local dragging=false
local dragStart=nil
local dragStartPos=nil
local currentSongName="(未播放)"
local endedConn=nil

local function parseLRC(lrcText)
    if not lrcText then return {} end
    local out={}
    for line in lrcText:gmatch("[^\r\n]+")do
        for tag,txt in line:gmatch("%[(%d+:%d+%.?%d*)%](.*)")do
            local m,s=tag:match("(%d+):(%d+%.?%d*)")
            if m and s then
                local t=tonumber(m)*60+tonumber(s)
                txt=txt:gsub("^%s+",""):gsub("%s+$","")
                if txt~="" then table.insert(out,{time=t,text=txt})end
            end
        end
    end
    table.sort(out,function(a,b)return a.time<b.time end)
    return out
end
local function fetchLyrics(songId,callback)
    task.spawn(function()
        local url="https://music.163.com/api/song/lyric?os=pc&id="..tostring(songId).."&lv=-1&kv=-1&tv=-1"
        local ok,res=pcall(game.HttpGet,game,url)
        if not ok then callback({})return end
        local ok2,data=pcall(HttpService.JSONDecode,HttpService,res)
        if not ok2 then callback({})return end
        local lrc=(data.lrc and data.lrc.lyric)or data.lyric
        if lrc and lrc~="" then callback(parseLRC(lrc))else callback({})end
    end)
end
local function buildLyricGui()
    if lyricGui then return end
    local sg=Instance.new("ScreenGui")
    sg.Name="MusicLyrics"
    sg.ResetOnSpawn=false
    sg.Parent=LP:WaitForChild("PlayerGui")
    local container=Instance.new("Frame")
    container.Name="LyricContainer"
    container.Size=UDim2.new(1,0,0,60)
    container.Position=UDim2.new(0,MCFG.lyricPosition.x,0,MCFG.lyricPosition.y)
    container.BackgroundTransparency=1
    container.Parent=sg
    local cur=Instance.new("TextLabel")
    cur.Size=UDim2.new(1,0,0,30)
    cur.BackgroundTransparency=1
    cur.Font=Enum.Font.GothamBold
    cur.TextSize=22
    cur.TextColor3=lyricColorMap[MCFG.currentLyricColor]or Color3.new(1,1,1)
    cur.TextStrokeTransparency=0.3
    cur.TextStrokeColor3=Color3.new(0,0,0)
    cur.Text=""
    cur.Parent=container
    local nxt=Instance.new("TextLabel")
    nxt.Size=UDim2.new(1,0,0,30)
    nxt.Position=UDim2.new(0,0,0,30)
    nxt.BackgroundTransparency=1
    nxt.Font=Enum.Font.GothamBold
    nxt.TextSize=18
    nxt.TextColor3=lyricColorMap[MCFG.nextLyricColor]or Color3.new(1,1,1)
    nxt.TextStrokeTransparency=0.5
    nxt.TextStrokeColor3=Color3.new(0,0,0)
    nxt.TextTransparency=0.3
    nxt.Text=""
    nxt.Parent=container
    lyricGui=sg
    lyricLabels={current=cur,next=nxt,container=container}
    container.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            if not MCFG.lyricLocked then
                dragging=true
                dragStart=input.Position
                dragStartPos=container.Position
            end
        end
    end)
    container.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then
            local delta=input.Position-dragStart
            container.Position=UDim2.new(0,dragStartPos.X.Offset+delta.X,0,dragStartPos.Y.Offset+delta.Y)
        end
    end)
    container.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            if dragging then
                dragging=false
                MCFG.lyricPosition.x=container.Position.X.Offset
                MCFG.lyricPosition.y=container.Position.Y.Offset
                saveMusicConfig()
            end
        end
    end)
end
local function refreshLyricGui()
    if not lyricGui then buildLyricGui()end
    lyricGui.Enabled=MCFG.showLyrics
    if lyricLabels.current then
        lyricLabels.current.TextColor3=lyricColorMap[MCFG.currentLyricColor]or Color3.new(1,1,1)
        lyricLabels.next.TextColor3=lyricColorMap[MCFG.nextLyricColor]or Color3.new(1,1,1)
    end
end
local function updateLyricDisplay()
    if not lyricLabels.current then return end
    if not MCFG.showLyrics or not isMusicPlaying or #lyricsData==0 then
        lyricLabels.current.Text=""
        lyricLabels.next.Text=""
        return
    end
    local curTime=Audio.TimePosition
    local idx=1
    for i=#lyricsData,1,-1 do
        if lyricsData[i].time<=curTime then idx=i break end
    end
    if idx~=currentLyricIndex then currentLyricIndex=idx end
    lyricLabels.current.Text=lyricsData[idx].text or ""
    if idx<#lyricsData then
        lyricLabels.next.Text=lyricsData[idx+1].text or ""
    else
        lyricLabels.next.Text=""
    end
end
local function stopMusic()
    if lyricUpdateTask then lyricUpdateTask:Disconnect()lyricUpdateTask=nil end
    if endedConn then pcall(function()endedConn:Disconnect()end)endedConn=nil end
    Audio:Stop()
    isMusicPlaying=false
    if lyricLabels.current then
        lyricLabels.current.Text=""
        lyricLabels.next.Text=""
    end
end
local function startLyricLoop()
    if lyricUpdateTask then lyricUpdateTask:Disconnect()end
    lyricUpdateTask=RS.Heartbeat:Connect(function()
        if not MCFG.showLyrics then return end
        updateLyricDisplay()
    end)
end
local function playSong(songId,soundId,songName)
    stopMusic()
    task.wait(0.1)
    Audio.SoundId=""
    Audio.TimePosition=0
    task.wait(0.08)
    Audio.SoundId=soundId
    Audio.Volume=MCFG.volume/100
    local t0=tick()
    while not Audio.IsLoaded and tick()-t0<4 do
        task.wait(0.05)
    end
    if Audio.TimeLength<=0 then
        WUI:Notify({Title="播放失败",Content="音频加载异常，请重试",Duration=3})
        return
    end
    Audio:Play()
    isMusicPlaying=true
    currentSongName=songName
    if songName then WUI:Notify({Title="正在播放",Content=songName,Duration=2})end
    endedConn=Audio.Ended:Connect(function()
        if not isMusicPlaying then return end
        if MCFG.loopMode then
            playSong(songId,soundId,songName)
        else
            if currentSongIndex and currentSongIndex<#songHistory then
                currentSongIndex=currentSongIndex+1
                local s=songHistory[currentSongIndex]
                if s.soundId then
                    playSong(s.songId,s.soundId,s.songName)
                else
                    _G.MusicLoadAndPlay(s.songId,s.songName)
                end
            end
        end
    end)
    if MCFG.showLyrics and #lyricsData>0 then startLyricLoop()end
end
local function isValidMp3(data)
    if #data<3 then return false end
    if string.sub(data,1,3)=="ID3" then return true end
    local b1,b2=string.byte(data,1),string.byte(data,2)
    if b1==0xFF and (b2==0xFB or b2==0xFA)then return true end
    return false
end
local function musicLoadAndPlay(songId,songName)
    if not songId or not songName then return end
    if isSearching then
        WUI:Notify({Title="提示",Content="正在处理其他请求",Duration=2})
        return
    end
    isSearching=true
    local token=tick()
    _G.__musicToken=token
    task.delay(20,function()
        if _G.__musicToken==token and isSearching then
            isSearching=false
            warn("[音乐] 超时强制解锁 isSearching")
        end
    end)
    WUI:Notify({Title="请稍等",Content="正在加载音频...",Duration=3})
    task.defer(function()
        local ok,err=pcall(function()
            local id=tostring(songId)
            local fileName=id..".mp3"
            local soundId=nil
            local cached=pcall(readfile,fileName)
            if cached then
                local fileData=readfile(fileName)
                if isValidMp3(fileData)then
                    local assetOk,asset=pcall(getcustomasset,fileName)
                    if assetOk then soundId=asset end
                end
            end
            if not soundId then
                local url="https://music.163.com/song/media/outer/url?id="..id..".mp3"
                local ok2,mp3=pcall(game.HttpGet,game,url)
                if not ok2 or not mp3 or #mp3<100000 or not isValidMp3(mp3)then
                    WUI:Notify({Title="无法播放",Content="无版权或文件损坏",Duration=3})
                    isSearching=false
                    return
                end
                local writeOk=pcall(writefile,fileName,mp3)
                if not writeOk then
                    WUI:Notify({Title="错误",Content="无法保存音频文件",Duration=3})
                    isSearching=false
                    return
                end
                local assetOk,asset=pcall(getcustomasset,fileName)
                if not assetOk then
                    WUI:Notify({Title="错误",Content="无法加载音频文件",Duration=3})
                    isSearching=false
                    return
                end
                soundId=asset
            end
            if not soundId then
                WUI:Notify({Title="错误",Content="无法获取有效音频文件",Duration=3})
                isSearching=false
                return
            end
            table.insert(songHistory,{songId=id,soundId=soundId,songName=songName})
            currentSongIndex=#songHistory
            playSong(id,soundId,songName)
            fetchLyrics(id,function(lyrics)
                lyricsData=lyrics
                currentLyricIndex=1
                if MCFG.showLyrics then
                    refreshLyricGui()
                    if not lyricUpdateTask and #lyricsData>0 then startLyricLoop()end
                end
            end)
        end,function(err)
            warn("播放出错:",err)
            WUI:Notify({Title="错误",Content="播放过程中发生异常",Duration=3})
        end)
        isSearching=false
    end)
end
_G.MusicLoadAndPlay=musicLoadAndPlay

-- ==================== 窗口 ====================
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

AT:Paragraph({Title="本页作用",Content="让屏幕中间出现敌人时，镜头自动往他身上贴。适合手动瞄准不太准的情况。"})
AT:Toggle({Title="自瞄开关",Value=false,Callback=function(v)CFG.Aimbot.Enabled=v nTg("自瞄",v)end})
AT:Toggle({Title="不瞄队友",Value=true,Callback=function(v)CFG.Aimbot.IgnoreTeammate=v end})
AT:Dropdown({Title="锁定部位",Values={"头部","躯干","左臂","右臂","左腿","右腿"},Callback=function(v)CFG.Aim.bodyPart=v end})
AT:Paragraph({Title="选项说明",Content="头部伤害最高但容易被队友挡；躯干稳定，推荐新手先用躯干。"})
AT:Dropdown({Title="优先级",Values={"Smart","Distance","Crosshair","Speed"},Callback=function(v)CFG.Aim.priority=v end})
AT:Paragraph({Title="选项说明",Content="多个敌人时先瞄谁。Smart 综合判断最智能。"})
AT:Dropdown({Title="激活方式",Values={"自动","按住"},Callback=function(v)CFG.Aim.activate=v end})
AT:Paragraph({Title="选项说明",Content="自动=一直工作；按住=松开左Ctrl就停止。"})
AT:Slider({Title="瞄准速度",Value={Min=1,Max=20,Default=5},Callback=function(v)CFG.Aim.aimSpeed=v end})
AT:Paragraph({Title="调节说明",Content="数值越大镜头贴过去越快。太快会像瞬移。"})
AT:Slider({Title="平滑度",Value={Min=1,Max=20,Default=5},Callback=function(v)CFG.Aim.smoothness=v end})
AT:Paragraph({Title="调节说明",Content="和瞄准速度反着用。数值越大镜头走得越慢越柔。"})
AT:Slider({Title="FOV",Value={Min=20,Max=500,Default=150},Callback=function(v)CFG.Aim.fovsize=v end})
AT:Paragraph({Title="调节说明",Content="屏幕中间多大范围的敌人才会被自瞄。"})
AT:Slider({Title="最大距离",Value={Min=50,Max=2000,Default=200},Callback=function(v)CFG.Aim.distance=v end})
AT:Paragraph({Title="调节说明",Content="超过这个距离的敌人不瞄。"})
AT:Toggle({Title="掩体识别",Value=false,Callback=function(v)CFG.Aim.wallCheck=v end})
AT:Paragraph({Title="使用提示",Content="开启后被墙挡住的敌人不瞄。"})
AT:Divider()
AT:Toggle({Title="强锁",Value=false,Callback=function(v)CFG.Aim.StrongLock=v nTg("强锁",v)end})
AT:Paragraph({Title="使用提示",Content="完全跳过过渡，镜头瞬间贴到敌人身上。"})
AT:Toggle({Title="锁死视角",Value=false,Callback=function(v)CFG.Aim.LockView=v nTg("锁死视角",v)end})
AT:Paragraph({Title="使用提示",Content="自己转鼠标也没用，镜头被钉死在敌人身上。"})
AT:Divider()
AT:Toggle({Title="AI预判",Value=false,Callback=function(v)CFG.Aim.AIPred=v nTg("AI预判",v)end})
AT:Paragraph({Title="使用提示",Content="敌人边跑边开枪时，镜头提前对准他前方。"})
AT:Slider({Title="预判强度",Value={Min=0.1,Max=3,Default=1},Callback=function(v)CFG.Aim.PredStrength=v end})
AT:Paragraph({Title="调节说明",Content="打偏身后就加大，打偏身前就减小。"})
AT:Slider({Title="子弹速度",Value={Min=200,Max=3000,Default=1200},Callback=function(v)CFG.Aim.BulletSpeed=v end})
AT:Paragraph({Title="调节说明",Content="按武器子弹飞行速度填。手枪约 800，步枪约 1200。"})
AT:Slider({Title="垂直预判比例",Value={Min=0,Max=1,Default=0.7},Callback=function(v)CFG.Aim.PredVertical=v end})
AT:Paragraph({Title="调节说明",Content="只在地面战斗填 0；敌人频繁跳跃填 0.8~1。"})
AT:Toggle({Title="相对速度补偿",Value=false,Callback=function(v)CFG.Aim.PredRelative=v nTg("相对速度",v)end})
AT:Paragraph({Title="使用提示",Content="你自己也在移动时开启，命中率更高。"})
AT:Toggle({Title="速度平滑",Value=true,Callback=function(v)CFG.Aim.PredSmooth=v end})
AT:Paragraph({Title="使用提示",Content="消除瞄准时的细微抖动。"})

MT:Paragraph({Title="本页作用",Content="改变自己角色的移动能力，以及别人瞄准你、靠近你时的提醒。"})
MT:Toggle({Title="加速",Value=false,Callback=function(v)CFG.Movement.Enabled=v nTg("加速",v)end})
MT:Slider({Title="移动速度",Value={Min=16,Max=300,Default=32},Callback=function(v)CFG.Movement.Speed=v end})
MT:Paragraph({Title="调节说明",Content="游戏默认是 16。默认填的 32 就是两倍速。"})
MT:Toggle({Title="跳跃增强",Value=false,Callback=function(v)CFG.Movement.JumpEnabled=v nTg("跳跃",v)end})
MT:Slider({Title="跳跃力",Value={Min=50,Max=300,Default=50},Callback=function(v)CFG.Movement.JumpPower=v end})
MT:Paragraph({Title="调节说明",Content="数值越大跳得越高。超过 200 容易被判定异常。"})
MT:Toggle({Title="无限连跳",Value=false,Callback=function(v)CFG.Movement.InfiniteJump=v nTg("无限连跳",v)end})
MT:Paragraph({Title="使用提示",Content="按住空格会一直往上飞。"})
MT:Toggle({Title="飞行",Value=false,Callback=function(v)CFG.Movement.FlyEnabled=v nTg("飞行",v)end})
MT:Paragraph({Title="使用提示",Content="空格上升，左Shift下降。"})
MT:Slider({Title="飞行速度",Value={Min=20,Max=500,Default=60},Callback=function(v)CFG.Movement.FlySpeed=v end})
MT:Toggle({Title="飞行穿墙",Value=false,Callback=function(v)CFG.Movement.FlyNoClip=v nTg("穿墙",v)end})
MT:Paragraph({Title="使用提示",Content="飞行时可以穿过墙壁，只和飞行一起用。"})
MT:Toggle({Title="免疫摔伤",Value=false,Callback=function(v)CFG.Fall.Enabled=v nTg("免疫摔",v)end})
MT:Paragraph({Title="使用提示",Content="从高处落地不掉血。"})
MT:Divider()
MT:Toggle({Title="被瞄准预警",Value=false,Callback=function(v)CFG.Alert.Aim=v nTg("被瞄预警",v)end})
MT:Slider({Title="被瞄检测距离",Value={Min=50,Max=1000,Default=300},Callback=function(v)CFG.Alert.AimDist=v end})
MT:Paragraph({Title="调节说明",Content="只在这么近的敌人瞄你时才提醒。"})
MT:Divider()
MT:Toggle({Title="附近敌人预警",Value=false,Callback=function(v)CFG.Alert.Nearby=v nTg("附近预警",v)end})
MT:Slider({Title="附近检测距离",Value={Min=20,Max=500,Default=80},Callback=function(v)CFG.Alert.NearbyDist=v end})
MT:Paragraph({Title="调节说明",Content="敌人进入这个距离就提醒。默认 80 大约是两三个身位。"})
MT:Divider()
MT:Toggle({Title="低血量预警",Value=false,Callback=function(v)CFG.Alert.LowHP=v nTg("血量预警",v)end})
MT:Slider({Title="血量阈值(%)",Value={Min=5,Max=90,Default=30},Callback=function(v)CFG.Alert.HPThresh=v end})
MT:Paragraph({Title="调节说明",Content="血量降到这个百分比时开始提示。"})
MT:Slider({Title="提示冷却(秒)",Value={Min=0.5,Max=10,Default=2},Callback=function(v)CFG.Alert.Cooldown=v end})
MT:Paragraph({Title="调节说明",Content="两次提示之间的间隔，防止刷屏。"})
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
   if hp<=CFG.Alert.HPThresh then AL.LastHP=now notify("⚠ 血量预警","当前血量 "..math.floor(hp).."%",2) end
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
        notify("⚠ 被瞄预警",p.Name.." 正瞄准你 ( "..math.floor(dist).."m )",2)
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
      if dist<=CFG.Alert.NearbyDist then AL.LastNear=now notify("⚠ 附近预警",p.Name.." 靠近 ( "..math.floor(dist).."m )",2)break end
     end
    end
   end
  end
 end
end)

ET:Paragraph({Title="本页作用",Content="把房间里所有玩家的位置在屏幕上标出来，隔着墙也能看到。"})
ET:Toggle({Title="透视开关",Value=false,Callback=function(v)CFG.ESP.Enabled=v nTg("透视",v)end})
ET:Toggle({Title="队伍识别",Value=true,Callback=function(v)CFG.ESP.TeamCheck=v end})
ET:Paragraph({Title="使用提示",Content="队友的标记会显示成绿色。"})
ET:Toggle({Title="屏蔽队友",Value=false,Callback=function(v)CFG.ESP.HideTeammate=v end})
ET:Paragraph({Title="使用提示",Content="开启后完全看不到队友的标记。"})
ET:Toggle({Title="显示名字",Value=true,Callback=function(v)CFG.ESP.ShowName=v end})
ET:Toggle({Title="显示血量",Value=true,Callback=function(v)CFG.ESP.ShowHealth=v end})
ET:Toggle({Title="显示距离",Value=false,Callback=function(v)CFG.ESP.ShowDistance=v end})
ET:Toggle({Title="显示掩体状态",Value=true,Callback=function(v)CFG.ESP.ShowCover=v end})
ET:Paragraph({Title="使用提示",Content="显示敌人有没有被墙挡住。"})
ET:Slider({Title="最大距离",Value={Min=100,Max=5000,Default=800},Callback=function(v)CFG.ESP.MaxDistance=v end})
ET:Paragraph({Title="调节说明",Content="超过这个距离的敌人不显示。"})
ET:Toggle({Title="Chams 内透",Value=false,Callback=function(v)CFG.ESP.Chams=v nTg("Chams",v)end})
ET:Paragraph({Title="使用提示",Content="被墙挡住的敌人会显示一层彩色轮廓。"})
ET:Slider({Title="填充透明",Value={Min=0,Max=1,Default=0.5},Callback=function(v)CFG.ESP.ChamsFillTransparency=v end})
ET:Paragraph({Title="调节说明",Content="调整色块的透明度。"})

FT:Paragraph({Title="本页作用",Content="把其他玩家整个人甩到天上乱转，纯恶搞。"})
local FDD=FT:Dropdown({Title="选择目标",Values=getNames(),Callback=function(v)for _,p in ipairs(Players:GetPlayers())do if p.Name==v then CFG.Spin.Target=p break end end end})
FT:Button({Title="刷新",Callback=function()if type(FDD.Refresh)=="function"then pcall(function()FDD:Refresh(getNames())end)end end})
FT:Paragraph({Title="操作提示",Content="重新拉取当前房间里的玩家名字。"})
FT:Slider({Title="强度",Value={Min=1,Max=10,Default=5},Callback=function(v)CFG.Spin.Strength=v end})
FT:Slider({Title="持续",Value={Min=1,Max=10,Default=3},Callback=function(v)CFG.Spin.Duration=v end})
FT:Paragraph({Title="调节说明",Content="持续多少秒后自动停。"})
FT:Button({Title="甩飞",Callback=function()spFl(CFG.Spin.Target)end})
FT:Button({Title="停止",Callback=function()clSF()notify("甩飞","停止")end})
FT:Divider()
FT:Button({Title="SkidFling 单个",Callback=function()
 local t=CFG.Spin.Target
 if not t or not t.Character or t==LP then notify("单个","无效")return end
 task.spawn(function()pcall(function()skidFling(t)end)end)
end})
FT:Paragraph({Title="操作提示",Content="更暴力的甩法，只针对选中的一个人。"})
FT:Button({Title="SkidFling 全部",Callback=function()flailAll()end})
FT:Paragraph({Title="操作提示",Content="一次性把房间里所有其他玩家都甩一遍。"})

BT:Paragraph({Title="本页作用",Content="开启后你打出的子弹会自动拐弯，追着屏幕中间最近的敌人飞。"})
BT:Toggle({Title="子追开关",Value=false,Callback=function(v)
 CFG.SubChase.Enabled=v
 if v then enableSubChase() else disableSubChase() end
end})
BT:Paragraph({Title="使用前提",Content="必须先进对局、拿到枪再开。在等待大厅或没装备武器时开不出来。"})
BT:Paragraph({Title="操作步骤",Content="1. 进对局 → 2. 拿到枪 → 3. 打开开关 → 4. 正常开枪，子弹会自动拐弯。"})

AB:Paragraph({Title="本页作用",Content="全自动开火。开启后你不用按任何键，脚本帮你锁最近的敌人并开枪。"})
AB:Toggle({Title="Ragebot 开关",Value=false,Callback=function(v)
 if v then _G.RageStart() else _G.RageStop() end
end})
AB:Paragraph({Title="使用前提",Content="必须先进对局、拿到枪再开。"})
AB:Paragraph({Title="操作步骤",Content="1. 进对局 → 2. 拿到枪 → 3. 打开开关 → 4. 什么都不用做，它会自己打。"})

OT:Paragraph({Title="本页作用",Content="把镜头挂到别的玩家身上，从他的视角看他怎么操作。"})
local ODD=OT:Dropdown({Title="选择目标",Values=getNames(),Callback=function(v)for _,p in ipairs(Players:GetPlayers())do if p.Name==v then CFG.Obs.Target=p break end end end})
OT:Button({Title="刷新",Callback=function()if type(ODD.Refresh)=="function"then pcall(function()ODD:Refresh(getNames())end)end end})
OT:Dropdown({Title="视角",Values={"First","Third","Top","Side"},Callback=function(v)CFG.Obs.Mode=v end})
OT:Paragraph({Title="选项说明",Content="First 目标第一人称；Third 背后跟随；Top 头顶俯视；Side 侧面。"})
OT:Slider({Title="偏移",Value={Min=0,Max=20,Default=6},Callback=function(v)CFG.Obs.Offset=v end})
OT:Button({Title="观察",Callback=function()sObs(CFG.Obs.Target)end})
OT:Button({Title="退出",Callback=function()stopObs()end})
OT:Paragraph({Title="操作提示",Content="退出后把镜头交还给自己。"})

PT:Paragraph({Title="本页作用",Content="选中一个玩家，对他执行传送、追敌、甩飞等操作。全部在主窗口里完成，不再有独立悬浮面板。"})
local PTDD=PT:Dropdown({
    Title="选择玩家",
    Values=getNames(),
    Callback=function(v)
        for _,p in ipairs(Players:GetPlayers())do
            if p.Name==v then CFG.Spin.Target=p break end
        end
    end
})
PT:Paragraph({Title="选项说明",Content="从下拉框选一个要操作的玩家。"})
PT:Button({Title="刷新玩家列表",Callback=function()
    if type(PTDD.Refresh)=="function"then pcall(function()PTDD:Refresh(getNames())end)end
    notify("玩家列表","已刷新",2)
end})
PT:Paragraph({Title="操作提示",Content="有新玩家进入房间后点一下刷新。"})
PT:Divider()
PT:Button({Title="传送到选中玩家",Callback=function()
    local t=CFG.Spin.Target
    if not t or not t.Parent then notify("传送","未选择目标",2)return end
    tpTo(t)
end})
PT:Paragraph({Title="效果说明",Content="瞬间移动到选中玩家身边。"})
PT:Button({Title="持续追敌",Callback=function()
    local t=CFG.Spin.Target
    if not t or not t.Parent then notify("跟随","未选择目标",2)return end
    if CFG.Follow.Target==t and CFG.Follow.Enabled then
        CFG.Follow.Enabled=false CFG.Follow.Target=nil notify("跟随","已停止",2)
    else
        CFG.Follow.Target=t CFG.Follow.Enabled=true notify("跟随","追踪 "..t.Name,2)
    end
end})
PT:Paragraph({Title="效果说明",Content="自己一直跟着选中的玩家跑。再点一次关闭。"})
PT:Button({Title="甩飞选中玩家",Callback=function()
    local t=CFG.Spin.Target
    if not t or not t.Parent then notify("甩飞","未选择目标",2)return end
    spFl(t)
end})
PT:Paragraph({Title="效果说明",Content="把选中的玩家甩到天上乱转。力度和持续时间去「甩飞」页调。"})
PT:Button({Title="SkidFling 选中玩家",Callback=function()
    local t=CFG.Spin.Target
    if not t or not t.Character or not t.Parent or t==LP then notify("SkidFling","未选择目标",2)return end
    task.spawn(function()pcall(function()skidFling(t)end)end)
end})
PT:Paragraph({Title="效果说明",Content="用更暴力的方式甩选中的玩家。"})

EFT:Paragraph({Title="本页作用",Content="改变游戏画面的整体显示效果。"})
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
EFT:Paragraph({Title="使用提示",Content="把黑暗环境提亮，关掉会恢复原样。"})

-- ==================== 音乐 Section ====================
local MUS=W:Section({Title="音乐",Opened=false})
local MInfo=MUS:Tab({Title="音乐信息",Icon="info"})
local MSearch=MUS:Tab({Title="搜索播放",Icon="search"})
local MSet=MUS:Tab({Title="播放设置",Icon="settings"})
local MFav=MUS:Tab({Title="我的收藏",Icon="heart"})

MInfo:Paragraph({Title="简介",Content="基于网易云 API 的音乐播放器。可以搜歌、收藏、看歌词。"})
MInfo:Paragraph({Title="使用步骤",Content="1. 去「搜索播放」输入歌名 → 2. 点搜索 → 3. 从下拉框选歌播放 → 4. 想留着就点「加入收藏」。"})
MInfo:Paragraph({Title="注意事项",Content="歌曲必须有版权才能播，无版权的会提示「无法播放」。第一次播放某首歌要下载，会慢一点。"})

MSearch:Input({
    Title="歌曲搜索",
    Placeholder="输入歌名后点搜索",
    Callback=function(s) searchInputText=s end
})
MSearch:Button({
    Title="搜索",
    Callback=function()
        local s=string.gsub(searchInputText,"%s+","")
        if s=="" then
            WUI:Notify({Title="提示",Content="请先输入歌曲名称",Duration=2})
            return
        end
        if isSearching then
            WUI:Notify({Title="提示",Content="正在搜索中，请稍候",Duration=2})
            return
        end
        isSearching=true
        WUI:Notify({Title="搜索中",Content="正在检索歌曲...",Duration=1})
        task.defer(function()
            local ok,err=pcall(function()
                local url="https://music.163.com/api/search/get?s="..HttpService:UrlEncode(s).."&type=1&limit=50"
                local ok2,res=pcall(game.HttpGet,game,url)
                if not ok2 then
                    WUI:Notify({Title="错误",Content="搜索请求失败",Duration=3})
                    return
                end
                local ok3,data=pcall(HttpService.JSONDecode,HttpService,res)
                if not ok3 or not data.result or not data.result.songs or #data.result.songs==0 then
                    WUI:Notify({Title="提示",Content="未找到相关歌曲",Duration=2})
                    return
                end
                songList={}
                for i,v in ipairs(data.result.songs)do
                    songList[i]=v.name.." - "..(v.artists[1] and v.artists[1].name or "未知歌手")
                end
                lastSearchData=data
                if searchDropdown then pcall(function() searchDropdown:Destroy()end)searchDropdown=nil end
                searchDropdown=MSearch:Dropdown({
                    Title="选择歌曲",
                    Values=songList,
                    Callback=function(selected)
                        if not lastSearchData then return end
                        local idx=table.find(songList,selected)
                        if not idx then return end
                        local song=lastSearchData.result.songs[idx]
                        musicLoadAndPlay(song.id,selected)
                    end
                })
                WUI:Notify({Title="搜索成功",Content="选择下拉框里的歌播放",Duration=2})
            end,function(err)
                warn("搜索出错:",err)
                WUI:Notify({Title="错误",Content="搜索异常",Duration=3})
            end)
            isSearching=false
        end)
    end
})
MSearch:Paragraph({Title="使用提示",Content="输入歌名 → 点搜索 → 从下拉框里选歌。搜索结果来自网易云，歌曲无版权会播放失败。"})
MSearch:Button({
    Title="加入收藏",
    Callback=function()
        if not searchDropdown or not searchDropdown.Value then
            WUI:Notify({Title="提示",Content="请先从下拉框选一首歌",Duration=2})
            return
        end
        local selectedName=searchDropdown.Value
        if not lastSearchData then return end
        local foundId=nil
        for _,song in ipairs(lastSearchData.result.songs)do
            local full=song.name.." - "..(song.artists[1] and song.artists[1].name or "未知歌手")
            if full==selectedName then foundId=song.id break end
        end
        if not foundId then
            WUI:Notify({Title="错误",Content="无法获取歌曲ID",Duration=2})
            return
        end
        for _,item in ipairs(MCFG.favorites)do
            if item.id==tostring(foundId)then
                WUI:Notify({Title="提示",Content="已经在收藏里了",Duration=2})
                return
            end
        end
        table.insert(MCFG.favorites,{id=tostring(foundId),name=selectedName})
        saveMusicConfig()
        if favDropdown then pcall(function() favDropdown:Destroy()end)favDropdown=nil end
        local names={}
        for _,item in ipairs(MCFG.favorites)do table.insert(names,item.name)end
        if #names==0 then table.insert(names,"(空)")end
        favDropdown=MFav:Dropdown({Title="收藏列表",Values=names,Callback=function() end})
        WUI:Notify({Title="收藏成功",Content=selectedName,Duration=2})
    end
})

MSet:Toggle({
    Title="显示歌词",
    Value=MCFG.showLyrics,
    Callback=function(state)
        MCFG.showLyrics=state
        saveMusicConfig()
        refreshLyricGui()
        if state and isMusicPlaying and #lyricsData>0 then startLyricLoop()end
    end
})
MSet:Paragraph({Title="使用提示",Content="开启后屏幕上方会显示当前播放歌曲的歌词。"})
MSet:Toggle({
    Title="锁定歌词位置",
    Value=MCFG.lyricLocked,
    Callback=function(state)
        MCFG.lyricLocked=state
        saveMusicConfig()
    end
})
MSet:Paragraph({Title="使用提示",Content="关掉后可以用鼠标拖动歌词到任何地方。"})
MSet:Toggle({
    Title="单曲循环",
    Value=MCFG.loopMode,
    Callback=function(state)
        MCFG.loopMode=state
        saveMusicConfig()
    end
})
MSet:Paragraph({Title="使用提示",Content="开启后当前歌播完会重新播放。"})
MSet:Dropdown({
    Title="上行颜色",
    Values=lyricColorNames,
    Callback=function(name)
        MCFG.currentLyricColor=name
        saveMusicConfig()
        if lyricLabels.current then
            lyricLabels.current.TextColor3=lyricColorMap[name]or Color3.new(1,1,1)
        end
    end
})
MSet:Paragraph({Title="选项说明",Content="当前正在唱的那句歌词的颜色。"})
MSet:Dropdown({
    Title="下行颜色",
    Values=lyricColorNames,
    Callback=function(name)
        MCFG.nextLyricColor=name
        saveMusicConfig()
        if lyricLabels.next then
            lyricLabels.next.TextColor3=lyricColorMap[name]or Color3.new(1,1,1)
        end
    end
})
MSet:Paragraph({Title="选项说明",Content="即将唱的那句歌词的颜色。"})
MSet:Slider({
    Title="音量",
    Value={Min=0,Max=100,Default=MCFG.volume},
    Callback=function(v)
        MCFG.volume=v
        saveMusicConfig()
        Audio.Volume=v/100
    end
})
MSet:Paragraph({Title="调节说明",Content="控制音乐音量。"})
MSet:Divider()
MSet:Button({
    Title="继续播放",
    Callback=function()
        if currentSongIndex and songHistory[currentSongIndex]then
            Audio:Resume()
            isMusicPlaying=true
        else
            WUI:Notify({Title="提示",Content="没有可继续的歌曲",Duration=2})
        end
    end
})
MSet:Button({
    Title="暂停播放",
    Callback=function()
        if isMusicPlaying then
            Audio:Pause()
            isMusicPlaying=false
            WUI:Notify({Title="已暂停",Content=currentSongName,Duration=2})
        else
            WUI:Notify({Title="提示",Content="当前没有播放",Duration=2})
        end
    end
})
MSet:Button({
    Title="停止播放",
    Callback=function()
        stopMusic()
        WUI:Notify({Title="已停止",Content="音乐已停止",Duration=2})
    end
})
MSet:Paragraph({Title="控制说明",Content="继续=接着暂停位置播；暂停=临时停；停止=完全重置。"})

local favInitNames={}
for _,item in ipairs(MCFG.favorites)do table.insert(favInitNames,item.name)end
if #favInitNames==0 then table.insert(favInitNames,"(空)")end
favDropdown=MFav:Dropdown({
    Title="收藏列表",
    Values=favInitNames,
    Callback=function() end
})
MFav:Button({
    Title="播放选中歌曲",
    Callback=function()
        if not favDropdown or not favDropdown.Value or favDropdown.Value=="(空)"then
            WUI:Notify({Title="提示",Content="请先选一首歌",Duration=2})
            return
        end
        local sel=favDropdown.Value
        for _,item in ipairs(MCFG.favorites)do
            if item.name==sel then
                musicLoadAndPlay(item.id,item.name)
                return
            end
        end
        WUI:Notify({Title="错误",Content="未找到该歌曲",Duration=2})
    end
})
MFav:Button({
    Title="播放全部收藏",
    Callback=function()
        if #MCFG.favorites==0 then
            WUI:Notify({Title="提示",Content="收藏列表为空",Duration=2})
            return
        end
        songHistory={}
        for _,item in ipairs(MCFG.favorites)do
            table.insert(songHistory,{songId=item.id,soundId=nil,songName=item.name})
        end
        currentSongIndex=1
        musicLoadAndPlay(songHistory[1].songId,songHistory[1].songName)
    end
})
MFav:Button({
    Title="删除选中歌曲",
    Callback=function()
        if not favDropdown or not favDropdown.Value or favDropdown.Value=="(空)"then
            WUI:Notify({Title="提示",Content="请先选一首歌",Duration=2})
            return
        end
        local sel=favDropdown.Value
        for i,item in ipairs(MCFG.favorites)do
            if item.name==sel then
                table.remove(MCFG.favorites,i)
                break
            end
        end
        saveMusicConfig()
        if favDropdown then pcall(function() favDropdown:Destroy()end)favDropdown=nil end
        local names={}
        for _,item in ipairs(MCFG.favorites)do table.insert(names,item.name)end
        if #names==0 then table.insert(names,"(空)")end
        favDropdown=MFav:Dropdown({Title="收藏列表",Values=names,Callback=function() end})
        WUI:Notify({Title="删除成功",Content=sel,Duration=2})
    end
})

notify("CA-HUB","加载完成",3)
notify("子追/Ragebot","进入对局拿到枪后再开",4)