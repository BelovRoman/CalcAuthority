local toWS,fromWS=userMods.ToWString,userMods.FromWString

local checkpoints = {}
local ClassColorsIcons = {
	["WARRIOR"]		= { r = 143/255; g = 119/255; b = 075/255; a = 1 },
	["PALADIN"]		= { r = 207/255; g = 220/255; b = 155/255; a = 1 },
	["STALKER"]		= { r = 150/255; g = 204/255; b = 086/255; a = 1 },
	["BARD"]		= { r = 106/255; g = 230/255; b = 223/255; a = 1 },
	["PRIEST"]		= { r = 255/255; g = 207/255; b = 123/255; a = 1 },
	["DRUID"]		= { r = 255/255; g = 118/255; b = 060/255; a = 1 },
	["PSIONIC"]		= { r = 221/255; g = 123/255; b = 245/255; a = 1 },
	["MAGE"]		= { r = 126/255; g = 159/255; b = 255/255; a = 1 },
	["NECROMANCER"]	= { r = 208/255; g = 069/255; b = 075/255; a = 1 },
	["ENGINEER"]	= { r = 140/255; g = 140/255; b = 120/255; a = 1 },
	["WARLOCK"]   	= { r = 125/255; g = 101/255; b = 219/255; a = 1 },
	["UNKNOWN"]		= { r = 127/255; g = 127/255; b = 127/255; a = 1 },
}
local membersTable = {}
local funSort = 2
---------------------------------------------------------------------------------
-- Виджеты
---------------------------------------------------------------------------------
--главная кнопка
local wtShowBtn 					= 	mainForm:GetChildChecked("ShowBtn", false)

-- основное окно
local wtMainPanel 			= mainForm:GetChildChecked("MainPanel", false)
local wtList 				= wtMainPanel:GetChildChecked("List", false)
local wtDateTimePanel 		= wtList:GetChildChecked("DateTimePanel", false):GetWidgetDesc();		wtList:GetChildChecked("DateTimePanel", false):DestroyWidget()

local wtTable				= wtMainPanel:GetChildChecked("Table", false)
local wtMemberPanel 		= wtTable:GetChildChecked("MemberPanel", false):GetWidgetDesc();		wtTable:GetChildChecked("MemberPanel", false):DestroyWidget()

function OnShowBtn( params )
	wtMainPanel:Show(not wtMainPanel:IsVisible())
end
---------------------------------------------------------------------------------
-- Слеш команды
---------------------------------------------------------------------------------
function OnSlash(p)
	local m = fromWS(p.text)
	if m == "/CAlog" then
		LogInfo(json.encode(membersTable))
	end
end

function OnAdd( params )
	local members = guild.GetMembers()
	local checkpoint = {}
	for k,v in pairs(members) do
		local memberInfo = guild.GetMemberInfo( v )
		table.insert(checkpoint, memberInfo)
	end
	table.insert(checkpoints, {dateTime=common.GetLocalDateTime(), check=checkpoint})
	userMods.SetGlobalConfigSection( common.GetAddonName().."Settings", checkpoints )
	reloadCheckpoints()
end

function OnDel( params )
	local count = wtList:GetElementCount()-1
	local wtParent = params.widget:GetParent()
	for i=0,count do
		if wtParent:IsEqual( wtList:At( i ) ) then
			table.remove(checkpoints, i+1)
			break
		end
	end
	userMods.SetGlobalConfigSection( common.GetAddonName().."Settings", checkpoints )
	reloadCheckpoints()
end

function OnCheck( params )
	local firstChecpoint, secondChecpoint = nil, nil
	local count = wtList:GetElementCount()-1
	local wtParent = params.widget:GetParent()
	for i=0,count do
		if wtParent:IsEqual( wtList:At( i ) ) then
			if params.widget:GetVariant()==1 then
				params.widget:SetVariant(0)
			else
				params.widget:SetVariant(1)
			end
		end
		if not firstChecpoint and wtList:At( i ):GetChildChecked("Check", false):GetVariant()==1 then
			firstChecpoint = i + 1
		elseif not secondChecpoint and wtList:At( i ):GetChildChecked("Check", false):GetVariant()==1 then
			secondChecpoint = i + 1
		else
			wtList:At( i ):GetChildChecked("Check", false):SetVariant(0)
		end
	end
	if firstChecpoint and secondChecpoint then
		Calc(firstChecpoint, secondChecpoint)
	end
end

function Calc( i, j )
	membersTable = {}
	local firstChecpoint, secondChecpoint = table.copy(checkpoints[i].check), table.copy(checkpoints[j].check)
	local firstFlag, secondFlag = {}, {}
	for k1,v1 in ipairs(firstChecpoint) do
		for k2,v2 in ipairs(secondChecpoint) do
			if fromWS(v1.name)==fromWS(v2.name) then
				AddMember(v1.name, v1.sysClassName, v2.sysClassName, v1.sysTabardType, v2.sysTabardType, v2.authority-v1.authority, v2.loyalty-v1.loyalty,"")
				firstFlag[fromWS(v1.name)] = true
				secondFlag[fromWS(v2.name)] = true
			end
		end
	end
	for k1,v1 in pairs(firstChecpoint) do
		for k2,v2 in ipairs(secondChecpoint) do
			if GetDateString(v1.joinTime)==GetDateString(v2.joinTime) and v1.authority < v2.authority and not firstFlag[fromWS(v1.name)] and not secondFlag[fromWS(v2.name)] then
				AddMember(v2.name, v1.sysClassName, v2.sysClassName, v1.sysTabardType, v2.sysTabardType, v2.authority-v1.authority, v2.loyalty-v1.loyalty, "Ренейм "..fromWS(v1.name))
				firstFlag[fromWS(v1.name)] = true
				secondFlag[fromWS(v2.name)] = true
			end
		end
	end
	for k1,v1 in pairs(firstChecpoint) do
		if not firstFlag[fromWS(v1.name)] then
			AddMember(v1.name, v1.sysClassName, v1.sysClassName, v1.sysTabardType, "ENUM_TabardType_None", v1.authority-v1.authority, v1.loyalty-v1.loyalty, "Покинул гильдию")
			firstFlag[fromWS(v1.name)] = true
		end
	end
	for k2,v2 in pairs(secondChecpoint) do
		if not secondFlag[fromWS(v2.name)] then
			AddMember(v2.name, v2.sysClassName, v2.sysClassName, "ENUM_TabardType_None", v2.sysTabardType, v2.authority, v2.loyalty-10, "Новый")
			secondFlag[fromWS(v2.name)] = true
		end
	end
	DrawMembers()
end

function AddMember( name, oldClass, newClass, oldTabard, newTabard, authority, loyalty,comment )
	local tmp = {}
	tmp.name = name
	tmp.oldClass = oldClass
	tmp.newClass = newClass
	tmp.oldTabard = oldTabard
	tmp.newTabard = newTabard
	tmp.authority = authority
	tmp.authorityWithout = authority
	if newTabard=="ENUM_TabardType_Champion" then
		tmp.authorityWithout = math.round(authority / 2, 0.0)
	elseif newTabard=="ENUM_TabardType_Common" then
		tmp.authorityWithout = math.round(authority / 1.5, 0.0)
	end	
	tmp.loyalty = loyalty
	tmp.comment = comment
	table.insert(membersTable, tmp)
end

function DrawMembers( )
	wtTable:RemoveItems()
	if funSort == 1 then
		table.sort(membersTable, function(a, b) return (a.newClass < b.newClass) end)
	elseif funSort == 2 then
		table.sort(membersTable, function(a, b) return (fromWS(a.name) < fromWS(b.name)) end)
	elseif funSort == 3 then
		table.sort(membersTable, function(a, b) return (a.newTabard < b.newTabard)  end)
	elseif funSort == 4 then
		table.sort(membersTable, function(a, b) return (a.authority > b.authority) end)
	elseif funSort == 5 then
		table.sort(membersTable, function(a, b) return (a.authorityWithout > b.authorityWithout) end)
	elseif funSort == 6 then
		table.sort(membersTable, function(a, b) return (a.loyalty > b.loyalty) end)
	end
	for k,v in pairs(membersTable) do
		local wtTmp = mainForm:CreateWidgetByDesc(wtMemberPanel)
		wtTmp:GetChildChecked("Name", false):GetChildChecked("Text", false):SetVal( "value", v.name)
		wtTmp:GetChildChecked("OldClass", false):SetBackgroundTexture(common.GetAddonRelatedTexture( v.oldClass) )
		wtTmp:GetChildChecked("OldClass", false):SetBackgroundColor(ClassColorsIcons[v.oldClass])
		wtTmp:GetChildChecked("NewClass", false):SetBackgroundTexture(common.GetAddonRelatedTexture( v.newClass) )
		wtTmp:GetChildChecked("NewClass", false):SetBackgroundColor(ClassColorsIcons[v.newClass])
		wtTmp:GetChildChecked("OldTabard", false):SetBackgroundTexture(common.GetAddonRelatedTexture( v.oldTabard) )
		wtTmp:GetChildChecked("NewTabard", false):SetBackgroundTexture(common.GetAddonRelatedTexture( v.newTabard) )
		wtTmp:GetChildChecked("Authority", false):GetChildChecked("Text", false):SetVal( "value", tostring(v.authority) )
		wtTmp:GetChildChecked("AuthorityWithout", false):GetChildChecked("Text", false):SetVal( "value", tostring(v.authorityWithout))
		wtTmp:GetChildChecked("Loyalty", false):GetChildChecked("Text", false):SetVal( "value", tostring(v.loyalty))
		wtTmp:GetChildChecked("Comment", false):GetChildChecked("Text", false):SetVal( "value", v.comment)
		wtTable:Insert( wtTable:GetElementCount() , wtTmp )
	end
end

function GetDateString( date )
	local dateString = ""
	if date.d<10 then
		dateString = dateString.."0"..tostring(date.d)
	else
		dateString = dateString..tostring(date.d)
	end
	dateString = dateString.."."

	if date.m<10 then
		dateString = dateString.."0"..tostring(date.m)
	else
		dateString = dateString..tostring(date.m)
	end
	dateString = dateString.."."..tostring(date.y).." "

	if date.h then
		if date.h<10 then
			dateString = dateString.."0"..tostring(date.h)
		else
			dateString = dateString..tostring(date.h)
		end
		dateString = dateString..":"
	end

	if date.min then
		if date.min<10 then
			dateString = dateString.."0"..tostring(date.min)
		else
			dateString = dateString..tostring(date.min)
		end
		dateString = dateString..":"
	end

	if date.s then
		if date.s<10 then
			dateString = dateString.."0"..tostring(date.s)
		else
			dateString = dateString..tostring(date.s)
		end
	end

	return dateString
end

function reloadCheckpoints( )
	wtList:RemoveItems()
	wtTable:RemoveItems()
	for k,v in pairs(checkpoints) do
		local wtTmp = mainForm:CreateWidgetByDesc(wtDateTimePanel)
		wtTmp:GetChildChecked("Time", false):SetVal( "value", toWS( GetDateString( v.dateTime ) ) )
		wtList:Insert( wtList:GetElementCount() , wtTmp )
	end
end

function table.copy (originalTable)
 local copyTable = {}
  for k,v in pairs(originalTable) do
    copyTable[k] = v
  end
 return copyTable
end

function OnClass( params )
	funSort = 1
	DrawMembers()
end
function OnName( params )
	funSort = 2
	DrawMembers()
end
function OnTabard( params )
	funSort = 3
	DrawMembers()
end
function OnAuthority( params )
	funSort = 4
	DrawMembers()
end
function OnAuthorityWithout( params )
	funSort = 5
	DrawMembers()
end
function OnLoyalty( params )
	funSort = 6
	DrawMembers()
end
--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function Init()
	local section = userMods.GetGlobalConfigSection( common.GetAddonName().."Settings" )
	if section then
	 	checkpoints = section
	end
	reloadCheckpoints()
	common.RegisterReactionHandler( OnShowBtn, "ShowBtn" )
	common.RegisterReactionHandler( OnAdd, "Add" )
	common.RegisterReactionHandler( OnDel, "Delete" )
	common.RegisterReactionHandler( OnCheck, "Check" )

	common.RegisterReactionHandler( OnClass, "Class" )
	common.RegisterReactionHandler( OnName, "Name" )
	common.RegisterReactionHandler( OnTabard, "Tabard" )
	common.RegisterReactionHandler( OnAuthority, "Authority" )
	common.RegisterReactionHandler( OnAuthorityWithout, "AuthorityWithout" )
	common.RegisterReactionHandler( OnLoyalty, "Loyalty" )

	common.RegisterEventHandler( OnSlash, "EVENT_UNKNOWN_SLASH_COMMAND" )

	DnD.Init( wtShowBtn, wtShowBtn, true )
	DnD.Init( wtMainPanel, wtMainPanel, true )
end
if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end
--------------------------------------------------------------------------------