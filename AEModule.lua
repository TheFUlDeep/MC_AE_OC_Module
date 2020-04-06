AEModule = AEModule or {}

local cmp = require("component")

AEModule.AEModuleCraftItem = AEModule.AEModuleCraftItem or {}
AEModule.AEModuleEmitRedstoneOnCount = AEModule.AEModuleEmitRedstoneOnCount or {}
AEModule.AEModuleTIMERDELAY = AEModule.AEModuleTIMERDELAY or 1

local function PrintTable(tbl,sdvig)
	if not sdvig then sdvig = "" end
	for k,v in pairs(tbl) do
		print(sdvig..tostring(k)..":",v)
		if type(v) == "table" then AEModule.PrintTable(v,sdvig.."	") end
	end
end 


local function FindItem(interface,label)
  local res = {}
  for k,v in pairs(interface.getCraftables({label = label})) do
      if type(v) == "table" and v.getItemStack then res[#res+1] = v end
  end
  return res
end

local function GetCount(me,label,isfluid)
  local count = 0
  for _,v in pairs(isfluid and me.getFluidsInNetwork({label = label}) or me.getItemsInNetwork({label = label})) do
    if type(v) == "table" and v.size then count = count + v.size end
  end
  return isfluid and count/1000 or count
end

local function IsFreeCpuExists(interface)
  for k,v in pairs(interface.getCpus()) do
    if type(v) == "table" and v.busy == false then return true end
  end
  return false
end


function AEModule.EmitRedstouneOnCount(addr,name,count,less,side,isfluid)
  local block = cmp.proxy(cmp.get(addr))
  if not block then print("введен неверный адрес!") return end

  local n = #(AEModule.AEModuleEmitRedstoneOnCount)+1
  AEModule.AEModuleEmitRedstoneOnCount[n] = {}
  AEModule.AEModuleEmitRedstoneOnCount[n].name = name
  AEModule.AEModuleEmitRedstoneOnCount[n].count = count
  AEModule.AEModuleEmitRedstoneOnCount[n].less = less
  AEModule.AEModuleEmitRedstoneOnCount[n].side = side
  AEModule.AEModuleEmitRedstoneOnCount[n].isfluid = isfluid
  AEModule.AEModuleEmitRedstoneOnCount[n].block = block
end

local function Notification(msg,hz,len)
  if msg then print(msg) end
  if hz and len then
    cmp.computer.beep(hz,len)
  else cmp.computer.beep(1000,0.5)
  end
end

function AEModule.CraftItem(name,count)
  local n = #(AEModule.AEModuleCraftItem)+1
  AEModule.AEModuleCraftItem[n] = {}
  AEModule.AEModuleCraftItem[n].name = name
  AEModule.AEModuleCraftItem[n].count = count
end

--AEModule.Start = function()
require("thread").create(function()
    local interface = require("component").me_interface
    while true do
		os.sleep(AEModule.AEModuleTIMERDELAY)
		--Redstone
		for _,v in pairs(AEModule.AEModuleEmitRedstoneOnCount) do
			local count1 = GetCount(interface,v.name,v.isfluid)
			local emit
			if v.less then emit = count1 < v.count
			else emit = count1 > v.count
			end
			v.block.setOutput(v.side,emit and 15 or 0)
		end
      
		--Craft
		for _,v in pairs(AEModule.AEModuleCraftItem) do
			if v.processing then
			  if not v.processing.isDone() and not v.processing.isCanceled() then goto CONTINUE end
			  if v.processing.isDone() then Notification(v.processingcount.." "..v.name.." READY") v.processing = nil goto CONTINUE end
			  if v.processing.isCanceled() then Notification(v.processingcount.." "..v.name.." CANCELED") v.processing = nil goto CONTINUE end
			  goto CONTINUE      
			end
			if not IsFreeCpuExists(interface) then goto CONTINUE end
			
			local count1 = GetCount(interface,v.name)
			if count1 >= v.count then goto CONTINUE end
			
			local item = FindItem(interface,v.name)[1]
			if not item then goto CONTINUE end
			
			v.processingcount = v.count - count1
			v.processing = item.request(v.processingcount)
			Notification("REQUESTED "..v.processingcount.." "..v.name)
			::CONTINUE::
		end
	end
end):detach()
--end

return AEModule