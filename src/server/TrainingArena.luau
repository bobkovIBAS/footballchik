local Kit = require(script.Parent:WaitForChild("WorldKit"))
local Arena = {}
local v, c = Vector3.new, Color3.fromRGB
local navy, cobalt, cyan = c(17, 30, 64), c(25, 77, 195), c(52, 208, 255)
local cream, gold = c(241, 237, 214), c(255, 196, 80)
local metal, stone = Enum.Material.Metal, Enum.Material.Concrete
local frame = CFrame.new(-59, 0, 30) * CFrame.Angles(0, math.pi / 2, 0)

function Arena.install(zone)
 if zone:GetAttribute("FutsalVersion") == 2 then return end
 local model = Instance.new("Model")
 model.Name = "FutsalArena"
 local function part(name, size, at, color, material, solid, rotation)
  local p = Kit.part(model, name, size, frame * CFrame.new(at) * (rotation or CFrame.identity), color, material, solid)
  p.CastShadow = size.Y > 0.4 and name ~= "Seat" and name ~= "SeatBack"
  return p
 end
 local function beam(name, a, b, width, color, material)
  return Kit.beam(model, name, frame:PointToWorldSpace(a), frame:PointToWorldSpace(b), width, width, color, material)
 end
 local function line(a,b,width,color)
  return beam("CourtLine",a,b,width or 0.085,color or cream,Enum.Material.SmoothPlastic)
 end
 local function circle(x,z,r,first,last)
  local old
  for i=0,40 do
   local a=first+(last-first)*i/40
   local p=v(x+math.cos(a)*r,0.237,z+math.sin(a)*r)
   if old then line(old,p) end
   old=p
  end
 end
 part("Foundation",v(40,0.30,38),v(0,0.06,0),navy,stone,true)
 part("CourtUnderlay",v(24.2,0.05,30.2),v(0,0.17,0),c(116,62,29),Enum.Material.Wood)
 -- Staggered individual maple boards retain the native wood grain at close range.
 for row=0,23 do
  local offset=(row%2)*2.5
  for col=-1,5 do
   local start=math.max(-15,-15+col*5+offset)
   local finish=math.min(15,-10+col*5+offset)
   if finish>start then
    local tone=(row*7+col*11)%9
    local p=part("MaplePlank",v(0.985,0.036,finish-start-0.025),v(-11.5+row,0.193,(start+finish)/2),c(184+tone*5,106+tone*5,49+tone*3),Enum.Material.Wood)
    p.Reflectance=0.075
   end
  end
 end
 for _,x in {-12,12} do
  line(v(x,0.237,-15),v(x,0.237,15))
  part("BlueApron",v(1.4,0.06,34),v(x*1.07,0.20,0),cobalt)
  part("CourtGlow",v(0.10,0.07,33),v(x*1.13,0.24,0),cyan,Enum.Material.Neon)
 end
 for _,z in {-15,15} do line(v(-12,0.237,z),v(12,0.237,z)) end
 line(v(-12,0.237,0),v(12,0.237,0))
 circle(0,0,3.3,0,math.pi*2)
 circle(0,-15,6,0,math.pi)
 circle(0,15,6,math.pi,math.pi*2)
 for _,z in {-15,15} do
  line(v(-4.5,0.237,z),v(-4.5,0.237,z-math.sign(z)*3))
  line(v(4.5,0.237,z),v(4.5,0.237,z-math.sign(z)*3))
  line(v(-4.5,0.237,z-math.sign(z)*3),v(4.5,0.237,z-math.sign(z)*3))
 end
 task.wait()
 -- Three real seating tiers with a central stair aisle on each side.
 for _,side in {-1,1} do
  for row=1,3 do
   local x=side*(13.7+row*1.55)
   local y=row*0.85
   part("BleacherRiser",v(1.55,y,27),v(x,y/2,-0.7),cream,stone,true)
   part("RiserFace",v(0.05,0.57,27),v(x-side*0.78,y-0.28,-0.7),c(56,86,138),metal)
   for k=0,10 do
    local z=-12.5+k*2.35
    if math.abs(z)>1.6 then
     local tint=(k+row)%3==0 and cyan or cobalt
     part("Seat",v(1.12,0.17,1.70),v(x,y+0.16,z),tint)
     part("SeatBack",v(0.17,0.85,1.70),v(x+side*0.49,y+0.63,z),tint)
    end
   end
   for step=0,1 do
    local h=y-0.42+step*0.42
    part("AisleStep",v(0.78,h,2.7),v(x-side*0.39+side*step*0.78,h/2,0),cream,stone,true)
   end
  end
  for _,z in {-14,13} do
   for x=14,19,2.5 do beam("RailPost",v(side*x,2.5,z),v(side*x,4,z),0.10,cream,metal) end
   beam("Handrail",v(side*14,4,z),v(side*19,4,z),0.12,cream,metal)
  end
  for _,z in {-14,0,13} do
   part("ColumnFoot",v(1.3,0.5,1.3),v(side*19,0.3,z),cream,stone)
   part("SteelColumn",v(0.5,10.5,0.5),v(side*19,5.55,z),navy,metal,true)
   beam("RoofBrace",v(side*19,7.3,z),v(side*15.4,10.6,z),0.22,c(74,100,145),metal)
   part("WarmLamp",v(0.48,0.8,0.48),v(side*19,6.8,z),gold,Enum.Material.Neon)
  end
  part("SideRoof",v(7.6,0.35,30),v(side*16.4,10.6,-0.5),navy,metal,false,CFrame.Angles(0,0,side*0.12))
  beam("BlueEave",v(side*12.6,10.33,-15.5),v(side*12.6,10.33,14.5),0.14,cyan,Enum.Material.Neon)
  for _,z in {-11,0,10} do
   local lamp=part("CeilingPanel",v(2.7,0.09,1.1),v(side*16.5,10.18,z),cream,Enum.Material.Neon)
   if z==0 then
    local light=Instance.new("SurfaceLight")
    light.Face=Enum.NormalId.Bottom light.Range=13 light.Brightness=0.65 light.Angle=110 light.Color=gold light.Parent=lamp
   end
  end
  for _,z in {-11,10} do
   local sign=part("BannerBadge",v(2,4.1,0.08),v(side*14.0,7.6,z),cobalt,Enum.Material.Fabric)
   Kit.lettering(sign,"⚽",nil,gold)
   beam("BannerHem",v(side*14-1,5.6,z+0.1),v(side*14+1,5.6,z+0.1),0.10,gold,metal)
  end
 end
 task.wait()
 for row=1,3 do
  local y=row*0.72
  part("RearTier",v(25,y,1.35),v(0,y/2,-16-row*1.2),cream,stone)
  for i=-6,6 do part("RearSeat",v(1.5,0.65,0.7),v(i*1.8,y+0.4,-16-row*1.2),i%3==0 and cyan or cobalt) end
 end
 for _,side in {-1,1} do
  part("RearPier",v(0.65,12.8,0.7),v(side*12.5,6.4,-16),navy,metal,true)
  part("MainRoof",v(14.1,0.45,12.8),v(side*6.5,14.5,-13),navy,metal,false,CFrame.Angles(0,0,-side*0.22))
  beam("GableLight",v(0,16,-6.5),v(side*13.5,13,-6.5),0.16,cyan,Enum.Material.Neon)
  beam("RoofGoldEdge",v(0,16.1,-19.5),v(side*13.5,13.1,-19.5),0.12,gold,metal)
  beam("Truss",v(side*12.5,10.2,-16),v(0,15.7,-16),0.24,c(62,92,144),metal)
 end
 local sign=part("TrainingFascia",v(24,3.3,0.65),v(0,13.5,-6.35),navy,metal)
 Kit.lettering(sign,"ТРЕНИРОВКА",nil,cyan)
 sign.Lettering.CanvasSize=Vector2.new(600,90)
 for _,side in {-1,1} do
  beam("SignBevel",v(side*12,11.8,-5.96),v(side*14,13.3,-5.96),0.22,cyan,Enum.Material.Neon)
  beam("RoofRib",v(side*14,13.3,-5.96),v(side*7,15.5,-5.96),0.22,cyan,Enum.Material.Neon)
 end
 beam("SignLowerGlow",v(-12,11.8,-5.98),v(12,11.8,-5.98),0.12,cyan,Enum.Material.Neon)
 Kit.football(model,frame:PointToWorldSpace(v(0,17,-8)),1.75,false)
 local display=part("ReplayScreen",v(10,4,0.3),v(0,8.2,-18.3),navy,metal)
 Kit.lettering(display,"⚽", "FOOTBALL ACADEMY",cyan)
 for _,x in {-5,5} do beam("ScreenEdge",v(x,6.2,-18.08),v(x,10.2,-18.08),0.075,cyan,Enum.Material.Neon) end
 -- Small goal with individual rear and side net strands.
 for _,x in {-4,4} do beam("GoalPost",v(x,0.1,-14.4),v(x,4.8,-14.4),0.20,cream,metal) end
 beam("GoalCrossbar",v(-4,4.8,-14.4),v(4,4.8,-14.4),0.20,cream,metal)
 for x=-4,4,0.4 do beam("NetCord",v(x,0.12,-16),v(x,4.8,-14.55),0.026,cream) end
 for y=0.2,4.7,0.4 do
  local z=-16+y/4.8*1.45
  beam("NetCord",v(-4,y,z),v(4,y,z),0.026,cream)
  for _,x in {-4,4} do beam("SideNet",v(x,y,z),v(x,y,-14.4),0.026,cream) end
 end
 for _,side in {-1,1} do
  local x=side*17
  part("EntryPlanter",v(4,1.4,3.4),v(x,0.7,17),cream,stone,true)
  part("PlanterGlow",v(4.1,0.08,3.5),v(x,0.18,17),gold,Enum.Material.Neon)
  for j=-1,1 do
   local pos=frame:PointToWorldSpace(v(x+j,1.4,17))
   Kit.shrub(model,pos.X,pos.Y,pos.Z,0.9)
  end
  local pole=frame:PointToWorldSpace(v(side*20,0,-12))
  Kit.beam(model,"FloodlightMast",pole,pole+v(0,18,0),0.18,0.18,navy,metal)
  part("FloodlightBack",v(3,2.5,0.28),v(side*20,18,-12),navy,metal)
  for i=0,2 do for j=0,1 do part("FloodLens",v(0.72,0.85,0.08),v(side*20-0.9+i*0.9,17.5+j,-11.8),cream,Enum.Material.Neon) end end
 end
 for i=0,2 do
  local x=-10+i*1.25
  part("ConeFoot",v(0.85,0.09,0.85),v(x,0.11,16.7),c(249,123,28))
  for tier=0,3 do
   local width=0.65-tier*0.14
   part("ConeTier",v(width,0.29,width),v(x,0.25+tier*0.27,16.7),tier==2 and cream or c(250,125,31))
  end
 end
 -- A wheeled ball rack sits outside the clear entry lane.
 part("BallRackTray",v(3.6,0.18,2.2),v(8.9,0.75,17),navy,metal)
 for _,x in {7.2,10.6} do for _,z in {16,18} do
  beam("RackUpright",v(x,0.5,z),v(x,2.3,z),0.12,cobalt,metal)
  part("RackWheel",v(0.32,0.42,0.42),v(x,0.24,z),navy,Enum.Material.Rubber)
 end end
 for _,z in {16,18} do beam("RackRail",v(7.2,2.3,z),v(10.6,2.3,z),0.12,cobalt,metal) end
 for i=0,2 do Kit.football(model,frame:PointToWorldSpace(v(7.7+i*1.15,1.35,17)),0.53,false) end
 task.wait()
 -- Local western backdrop stays behind this arena.
 for i=-1,1 do
  local x=i*12
  part("BackdropRock",v(11,17+i*3,10),v(x,6,-29-math.abs(i)*2),c(91+i*8,109+i*5,148),Enum.Material.Slate,false,CFrame.Angles(0,0,i*0.12))
  part("RockShoulder",v(8,15,8),v(x-4,4,-28),c(103,121,158),Enum.Material.Slate,false,CFrame.Angles(0,0,-0.24))
  part("GrassCrown",v(11.8,1.3,10.8),v(x,14.6+i*1.5,-29-math.abs(i)*2),c(91,160,53),Enum.Material.Grass)
  local pos=frame:PointToWorldSpace(v(x,15+i*1.5,-30))
  Kit.pine(model,pos.X,pos.Y,pos.Z,1.2)
 end
 for i=0,2 do
  local p=part("WaterfallRibbon",v(0.78,15,0.12),v(5+i*0.73,6.7,-23.6),c(104+i*25,211+i*9,245),Enum.Material.SmoothPlastic)
  p.Transparency=0.22 p.CastShadow=false
 end
 local keep={RhythmStation=true,RhythmStationCap=true,StationBase=true,StationColumn=true,RhythmBounds=true}
 for _,child in zone:GetChildren() do if not keep[child.Name] then child:Destroy() end end
 zone.RhythmStation.Transparency=1
 for _,gui in zone.RhythmStation:GetChildren() do if gui:IsA("SurfaceGui") then gui.Enabled=false end end
 zone.RhythmStationCap.Transparency=1 zone.StationBase.Transparency=1 zone.StationColumn.Transparency=1
 local instruction=part("EntryInstructions",v(6.5,2.6,0.3),v(13.4,3.1,17.6),navy,metal)
 Kit.lettering(instruction,"НАБИВАЙ МЯЧ", "И ПОЛУЧАЙ СИЛУ",gold)
 zone:SetAttribute("RhythmFloorY",0.21)
 -- Remove the old garden pieces only where the replacement arena occupies their ground.
 local grounds=zone.Parent.Parent:FindFirstChild("Grounds")
 if grounds then
  local removeNames={TreeTrunk=true,Canopy=true,PlanterWall=true,PlanterCoping=true,PlantedBed=true,Leaves=true,
   BenchLeg=true,BenchBackPost=true,BenchSlat=true,BackrestSlat=true,LampFoot=true,LampPost=true,LampGlass=true,LampCap=true,LampBase=true}
  for _,p in grounds:GetDescendants() do
   if p:IsA("BasePart") and removeNames[p.Name] then
    local q=frame:PointToObjectSpace(p.Position)
    if math.abs(q.X)<22 and math.abs(q.Z)<20 then p:Destroy() end
   end
  end
 end
 model.Parent=zone
 zone:SetAttribute("FutsalVersion",2)
end
return Arena
