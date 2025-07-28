if CLIENT then
	local settings = {autobhop = false, speedometer = false, propbox = false, npcbox = false, playerbox = false, npcnametags = false, playernametags = false, npccursorlines = false, playercursorlines = false}

	for k in pairs(settings) do settings[k] = cookie.GetNumber("utility_" .. k, 0) == 1 end

	local function DrawBoundingBox(ent, color, ang)
		cam.IgnoreZ(true)
		render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true)
		cam.IgnoreZ(false)
	end

	local function DrawNameTag(ent, name, color)

		local eyePos = ent:EyePos()
		local tagPos = eyePos + Vector(0, 0, 10)
		local screenPos = tagPos:ToScreen()

		draw.SimpleText(name, "Trebuchet24", screenPos.x, screenPos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	local function DrawCursorLines(entities, color, filter)
		local cursorPos = LocalPlayer():GetEyeTrace().HitPos

		for _, ent in ipairs(entities) do
			if not filter or filter(ent) then
				render.DrawLine(cursorPos, ent:EyePos(), color, true)
			end
		end
	end

	hook.Add("PostDrawOpaqueRenderables", "CustomBox", function()
		if settings.propbox or settings.npcbox or settings.playerbox then
			for _, ent in ipairs(ents.GetAll()) do
				local class = ent:GetClass()
				if settings.propbox and class:find("^prop_") then
					DrawBoundingBox(ent, Color(0, 255, 255))
				elseif settings.npcbox and class:find("^npc_") and ent:Alive() then
					DrawBoundingBox(ent, Color(255, 0, 0), Angle(0, 0, 0))
				end
			end

			if settings.playerbox then
				for _, ply in ipairs(player.GetAll()) do
					if ply ~= LocalPlayer() and ply:Alive() then
						DrawBoundingBox(ply, Color(255, 255, 0), Angle(0, 0, 0))
					end
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "DrawLinesToEntities", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
			cam.IgnoreZ(true)
			if settings.npccursorlines then DrawCursorLines(ents.FindByClass("npc_*"), Color(255, 0, 0), function(npc) return npc:Health() > 0 end) end
			if settings.playercursorlines then DrawCursorLines(player.GetAll(), Color(255,255,0), function(ply) return ply~=LocalPlayer() and ply:Alive() end) end
			cam.IgnoreZ(false)
	end)

	hook.Add("CreateMove", "CustomMovementControls", function(cmd)
		local ply = LocalPlayer()
		if ply:Alive() and settings.autobhop and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
			if not ply:IsOnGround() and cmd:KeyDown(IN_JUMP) then
				cmd:RemoveKey(IN_JUMP)
			end
		end
	end)

	hook.Add("HUDPaint", "ShowPlayerSpeed", function()
		local ply = LocalPlayer()
		if IsValid(ply) and ply:Alive() and settings.speedometer then
			draw.SimpleText(("Speed: %d u/s"):format(math.Round(ply:GetVelocity():Length())), "Trebuchet24", 600, 400, Color(255, 255, 0), TEXT_ALIGN_LEFT)
		end
	end)

	hook.Add("HUDPaint", "DrawNameTags", function()
		if settings.npcnametags then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Health() > 0 then
					local npcName = npc.GetName and npc:GetName() or npc:GetClass()
					DrawNameTag(npc, npcName, Color(255, 0, 0))
				end
			end
		end

		if settings.playernametags then
			for _, ply in ipairs(player.GetAll()) do
				if ply:Alive() and IsValid(ply) then
					DrawNameTag(ply, ply:Nick(), Color(255, 255, 0))
				end
			end
		end
	end)

	local utilityMenu

	local function createLabel(parent, text, font, color, margin)
		local label = vgui.Create("DLabel", parent)
		label:SetText(text)
		label:SetFont(font or "DermaDefaultBold")
		label:SetTextColor(color or color_white)
		label:Dock(TOP)
		label:DockMargin(margin or 10, 5, 0, margin or 5)
		label:SizeToContents()
		return label
	end

	local function createCheckbox(parent, name, settingKey)
		local check = vgui.Create("DCheckBoxLabel", parent)
		check:SetText(name)
		check:SetValue(settings[settingKey])
		check:Dock(TOP)
		check:DockMargin(15, 0, 0, 5)
		check:SetTextColor(color_white)
		check.OnChange = function(_, val)
			settings[settingKey] = val
			cookie.Set("utility_" .. settingKey, val and "1" or "0")
		end
		return check
	end

	local function CreateUtilityMenu()
		utilityMenu = vgui.Create("DFrame")
		utilityMenu:SetSize(290, 400)
		utilityMenu:Center()
		utilityMenu:SetTitle("Utility Menu")
		utilityMenu:SetVisible(false)
		utilityMenu:SetDeleteOnClose(false)

		local tabs = vgui.Create("DPropertySheet", utilityMenu)
		tabs:Dock(FILL)
		tabs:SetFadeTime(0)

		local utilityPanel = vgui.Create("DPanel")
		utilityPanel:Dock(FILL)
		utilityPanel.Paint = nil
		local scrollUtility = vgui.Create("DScrollPanel", utilityPanel)
		scrollUtility:Dock(FILL)

		createLabel(scrollUtility, "Miscellaneous")
		createCheckbox(scrollUtility, "Auto Bhop", "autobhop")

		local displayPanel = vgui.Create("DPanel")
		displayPanel:Dock(FILL)
		displayPanel.Paint = nil
		local scrollDisplay = vgui.Create("DScrollPanel", displayPanel)
		scrollDisplay:Dock(FILL)

		createLabel(scrollDisplay, "Miscellaneous")
		createCheckbox(scrollDisplay, "Speedometer", "speedometer")
		createCheckbox(scrollDisplay, "Prop Box", "propbox")

		createLabel(scrollDisplay, "NPC Options")
		createCheckbox(scrollDisplay, "NPC Box", "npcbox")
		createCheckbox(scrollDisplay, "NPC Nametags", "npcnametags")
		createCheckbox(scrollDisplay, "NPC Cursor Lines", "npccursorlines")

		createLabel(scrollDisplay, "Player Options")
		createCheckbox(scrollDisplay, "Player Box", "playerbox")
		createCheckbox(scrollDisplay, "Player Nametags", "playernametags")
		createCheckbox(scrollDisplay, "Player Cursor Lines", "playercursorlines")

		tabs:AddSheet(" Utility", utilityPanel, "icon16/user.png")
		tabs:AddSheet(" Display", displayPanel, "icon16/eye.png")
	end

	concommand.Add("open_utility_menu", function()
		if not IsValid(utilityMenu) then CreateUtilityMenu() end
		utilityMenu:SetVisible(true) utilityMenu:MakePopup()
	end)
end
