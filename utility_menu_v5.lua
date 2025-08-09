if not istable(settings) then
	settings = {
		autobhop = false, speedometer = false, propbox = false, npcbox = false, npcbone = false, npcnametag = false,
		npchealth = false, npccursorline = false, playerbox = false, playerbone = false, playernametag = false,
		playerhealth = false, playercursorline = false, entitybox = false, entitynametag = false, entitycursorline = false,
		allfilter = ""
	}
end

if not istable(actlist) then
	actList = {
		"agree", "becon", "bow", "cheer", "dance", "disagree", "forward",
		"group", "halt", "laugh", "muscle", "robot", "salute", "wave", "zombie"
	}
end

hook.Add("CreateMove", "AutoBhop", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	end
end)

hook.Add("HUDPaint", "DrawSpeedometer", function()
	local ply = LocalPlayer()
	local speed = math.Round(ply:GetVelocity():Length())
	if settings.speedometer and ply:Alive() then
		draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2 - 45, ScrH() / 2 + 75, Color(255, 255, 255), TEXT_ALIGN_LEFT)
	end
end)

hook.Add("PostDrawOpaqueRenderables", "DrawEntityVisuals", function()
    local ply = LocalPlayer()
    local allents = ents.GetAll()
    local filter = (settings.allfilter or ""):lower()
    local enableBoxes = settings.entitybox or settings.propbox or settings.npcbox or settings.playerbox
    local enableBones = settings.npcbone or settings.playerbone
    if not (enableBoxes or enableBones) then return end
    for _, ent in ipairs(allents) do
        if not IsValid(ent) then continue end
        local class = ent:GetClass():lower()
        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        local obbMins, obbMaxs = ent:OBBMins(), ent:OBBMaxs()
		cam.IgnoreZ(true)
        if enableBoxes then
            if settings.entitybox and (filter == "" or class:find(filter)) then
                render.DrawWireframeBox(pos, ang, obbMins, obbMaxs, Color(255, 255, 255))
            end
            if settings.propbox and (class:find("prop_physics") or class:find("prop_dynamic")) then
                render.DrawWireframeBox(pos, ang, obbMins, obbMaxs, Color(0, 255, 255))
            end
            if settings.npcbox and ent:IsNPC() and ent:Alive() then
                render.DrawWireframeBox(pos, Angle(0, 0, 0), obbMins, obbMaxs, Color(255, 0, 0))
            end
            if settings.playerbox and ent:IsPlayer() and ent ~= ply and ent:Alive() then
                render.DrawWireframeBox(pos, Angle(0, 0, 0), obbMins, obbMaxs, Color(255, 255, 0))
            end
        end
        if enableBones then
            local bones = ent:GetBoneCount()
            if bones and bones > 0 then
                local origin = pos
                for i = 0, bones - 1 do
                    local parent = ent:GetBoneParent(i)
                    if parent ~= -1 then
                        local bonePos1 = ent:GetBonePosition(i)
                        local bonePos2 = ent:GetBonePosition(parent)
                        if bonePos1 and bonePos2 and bonePos1:DistToSqr(origin) > 1 and bonePos2:DistToSqr(origin) > 1 then
                            if settings.npcbone and ent:IsNPC() and ent:Alive() then
                                render.DrawLine(bonePos1, bonePos2, Color(255, 0, 0))
                            elseif settings.playerbone and ent:IsPlayer() and ent:Alive() and ent ~= ply then
                                render.DrawLine(bonePos1, bonePos2, Color(255, 255, 0))
                            end
                        end
                    end
                end
            end
        end
		cam.IgnoreZ(false)
    end
end)

hook.Add("HUDPaint", "DrawEntityInfo", function()
    local ply = LocalPlayer()
    local allents = ents.GetAll()
    local filter = (settings.allfilter or ""):lower()
    local showNPCHealth = settings.npchealth
    local showPlayerHealth = settings.playerhealth
    local showEntityNametag = settings.entitynametag
    local showNPCNametag = settings.npcnametag
    local showPlayerNametag = settings.playernametag
    if not (showNPCHealth or showPlayerHealth or showEntityNametag or showNPCNametag or showPlayerNametag) then return end
    local npcOffset = showNPCNametag and -10 or 0
    local playerOffset = showPlayerNametag and -10 or 0
    for _, ent in ipairs(allents) do
        if not IsValid(ent) then continue end
        local pos = ent:EyePos():ToScreen()
        if showNPCHealth and ent:IsNPC() and ent:Alive() then
            draw.SimpleText("HP: " .. ent:Health(), "BudgetLabel", pos.x, pos.y + npcOffset, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
        if showPlayerHealth and ent:IsPlayer() and ent ~= ply and ent:Alive() then
            draw.SimpleText("HP: " .. ent:Health(), "BudgetLabel", pos.x, pos.y + playerOffset, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
        if showEntityNametag then
            local class = ent:GetClass():lower()
            if filter == "" or class:find(filter) then
                draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end
        if showNPCNametag and ent:IsNPC() and ent:Alive() then
            draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
        if showPlayerNametag and ent:IsPlayer() and ent ~= ply and ent:Alive() then
            draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
    local ply = LocalPlayer()
    local allents = ents.GetAll()
    local eyepos = ply:EyePos()
    local aimvec = ply:GetAimVector()
    local startpos = eyepos + aimvec * 50
    local filter = (settings.allfilter or ""):lower()
    local showEntityCursor = settings.entitycursorline
    local showNPCCursor = settings.npccursorline
    local showPlayerCursor = settings.playercursorline
    if not (showEntityCursor or showNPCCursor or showPlayerCursor) then return end
	cam.IgnoreZ(true)
    for _, ent in ipairs(allents) do
        if not IsValid(ent) then continue end
        local class = ent:GetClass():lower()
        local endPos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
        if showEntityCursor and (filter == "" or class:find(filter)) then
            render.DrawLine(startpos, endPos, Color(255, 255, 255))
        end
        if showNPCCursor and ent:IsNPC() and ent:Alive() then
            render.DrawLine(startpos, endPos, Color(255, 0, 0))
        end
        if showPlayerCursor and ent:IsPlayer() and ent:Alive() and ent ~= ply then
            render.DrawLine(startpos, endPos, Color(255, 255, 0))
        end
    end
	cam.IgnoreZ(false)
end)

local function createlabel(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefaultBold")
	label:SetTextColor(color_white)
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(5, 5, 0, 0)
	return label
end

local function createcheckbox(text, parent, setting)
	local checkbox = vgui.Create("DCheckBoxLabel", parent)
	checkbox:SetText(text)
	checkbox:SetFont("DermaDefault")
	checkbox:SetTextColor(color_white)
	checkbox:SetValue(settings[setting] and true or false)
	checkbox:SizeToContents()
	checkbox:Dock(TOP)
	checkbox:DockMargin(10, 5, 0, 0)
	checkbox.OnChange = function(self, val) settings[setting] = val and true or false end
	return checkbox
end

local function createmenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	local scrollutility = vgui.Create("DScrollPanel", tab)
	local scrolldisplay = vgui.Create("DScrollPanel", tab)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	createlabel("Miscellaneous Options:", scrollutility)
	createcheckbox("Auto Bhop", scrollutility, "autobhop")
	createlabel("Player Gestures:", scrollutility)
	local grid = vgui.Create("DIconLayout", scrollutility)
	grid:Dock(TOP)
	grid:SetSpaceX(5)
	grid:SetSpaceY(5)
	grid:CenterHorizontal()
	grid:DockMargin(9, 5, 0, 0)
	for _, act in ipairs(actList) do
		local button = grid:Add("DButton")
		button:SetText(act:sub(1,1):upper() .. act:sub(2):lower())
		button:SetSize(60, 30)
		button.DoClick = function()
			RunConsoleCommand("act", act)
		end
	end
	createlabel("Miscellaneous Options:", scrolldisplay)
	createcheckbox("Speedometer", scrolldisplay, "speedometer")
	createcheckbox("Prop Boxes", scrolldisplay, "propbox")
	createlabel("NPC Options:", scrolldisplay)
	createcheckbox("NPC Boxes", scrolldisplay, "npcbox")
	createcheckbox("NPC Bones", scrolldisplay, "npcbone")
	createcheckbox("NPC Health", scrolldisplay, "npchealth")
	createcheckbox("NPC Nametags", scrolldisplay, "npcnametag")
	createcheckbox("NPC Cursor Lines", scrolldisplay, "npccursorline")
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Player Boxes", scrolldisplay, "playerbox")
	createcheckbox("Player Bones", scrolldisplay, "playerbone")
	createcheckbox("Player Health", scrolldisplay, "playerhealth")
	createcheckbox("Player Nametags", scrolldisplay, "playernametag")
	createcheckbox("Player Cursor Lines", scrolldisplay, "playercursorline")
	createlabel("Entity Options:", scrolldisplay)
	createcheckbox("Entity Boxes", scrolldisplay, "entitybox")
	createcheckbox("Entity Nametags", scrolldisplay, "entitynametag")
	createcheckbox("Entity Cursor Lines", scrolldisplay, "entitycursorline")
	local searchbox = vgui.Create("DTextEntry", scrolldisplay)
	searchbox:Dock(TOP)
	searchbox:DockMargin(5, 5, 5, 0)
	searchbox:SetPlaceholderText("Filter entities by class (e.g. npc_, prop_)")
	searchbox.OnChange = function(self) settings.allfilter = self:GetValue() or "" end
	return frame
end

concommand.Add("open_utility_menu", function()
	if IsValid(utilitymenu) then
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	else
		utilitymenu = createmenu()
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	end
end)