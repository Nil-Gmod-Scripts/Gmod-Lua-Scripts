UtilityMenu = {}
UtilityMenu.Settings = {}

UtilityMenu.Config = {
	Colors = {
		White = Color(255, 255, 255), Cyan = Color(0, 255, 255), Yellow = Color(255, 255, 0), Green = Color(0, 255, 0),
		Black = Color(0, 0, 0), Purple = Color(180, 0, 180), Red = Color(255, 0, 0), Blue = Color(0, 0, 255)
	},
	EntityColors = {Prop = Color(0, 0, 255), NPC = Color(255, 255, 255), Player = Color(255, 255, 255)},
	MapSizes = {150, 200, 250, 300, 400},
	MapScales = {25, 50, 75, 100, 125},
	Gestures = {"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group", "halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"},
	PropKillProps = {
		[KEY_C] = "models/props_phx/construct/metal_plate4x4.mdl", [KEY_G] = "models/XQM/CoasterTrack/slope_225_3.mdl", [KEY_Q] = "models/props/cs_militia/refrigerator01.mdl",
		[KEY_R] = "models/props_canal/canal_bars004.mdl", [KEY_V] = "models/props/de_tides/gate_large.mdl", [KEY_X] = "models/props_junk/sawblade001a.mdl"
	},
	PkAllowedBinds = {
		"+attack", "+attack2", "+back", "+duck", "+forward", "+jump", "+moveleft", "+moveright", "+showscores", "+speed", "+use", "+walk", "gmod_undo", "gm_showteam",
		"impulse 100", "impulse 201", "kill", "messagemode", "open_utility_menu", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6", "toggle_freecam"
	},
	FreecamAllowedBinds = {"+showscores", "kill", "messagemode", "open_utility_menu", "toggle_freecam"},
	FreecamReleaseKeys = {"-forward", "-back", "-moveleft", "-moveright", "-jump", "-duck", "-attack", "-attack2", "-reload"},
	State = {
		ScriptRan = false, FreecamEnabled = false, FreecamPosition = Vector(0, 0, 0), FreecamAngle = Angle(0, 0, 0), FrozenViewAngle = Angle(0, 0, 0), LastCacheUpdate = 0,
		EntityCache = {Players = {}, NPCs = {}, Props = {}}, LastPropKeyState = {}, FreecamReleaseKeysState = false, LastAttackTime = 0
	}
}

function UtilityMenu.UpdateEntityCache()
	for _, cache in pairs(UtilityMenu.Config.State.EntityCache) do
		table.Empty(cache)
	end
	for _, ent in ipairs(ents.GetAll()) do
		if not IsValid(ent) then continue end
		if ent:GetClass():lower():find("prop_") then
			table.insert(UtilityMenu.Config.State.EntityCache.Props, ent)
		elseif ent:IsNPC() then
			table.insert(UtilityMenu.Config.State.EntityCache.NPCs, ent)
		elseif ent:IsPlayer() and ent ~= LocalPlayer() then
			table.insert(UtilityMenu.Config.State.EntityCache.Players, ent)
		end
	end
end

function UtilityMenu.MinimapProjection(position, yaw, scale, radius)
	local delta, angle = position - EyePos(), math.rad(-yaw - 90)
	local x, y = -(delta.x * math.cos(angle) - delta.y * math.sin(angle)), delta.x * math.sin(angle) + delta.y * math.cos(angle)
	x, y = x / scale, y / scale
	return math.Clamp(x, -radius, radius), math.Clamp(y, -radius, radius)
end

function UtilityMenu.DrawBones(entity, color)
	if not entity.BoneParents then
		entity.BoneParents = {}
		for i = 0, entity:GetBoneCount() - 1 do
			entity.BoneParents[i] = entity:GetBoneParent(i)
		end
	end
	local origin = entity:GetPos()
	for i = 0, entity:GetBoneCount() - 1 do
		local parent = entity.BoneParents[i]
		if not parent or parent == -1 then continue end
		local bonePos1, bonePos2 = entity:GetBonePosition(i), entity:GetBonePosition(parent)
		if bonePos1 and bonePos2 and bonePos1:DistToSqr(origin) > 1 and bonePos2:DistToSqr(origin) > 1 then
			render.DrawLine(bonePos1, bonePos2, color, false)
		end
	end
end

function UtilityMenu.SetupHooks()
	hook.Add("HUDPaint", "UtilityMenu_EyeAngleUpdater", function()
		local _ = EyeAngles(), EyePos()
	end)
	hook.Add("Think", "UtilityMenu_UpdateCache", function()
		if CurTime() - UtilityMenu.Config.State.LastCacheUpdate > 0.1 then
			UtilityMenu.UpdateEntityCache()
			UtilityMenu.Config.State.LastCacheUpdate = CurTime()
		end
	end)
	hook.Add("CreateMove", "UtilityMenu_Freecam", function(cmd)
		if not UtilityMenu.Config.State.FreecamEnabled then
			UtilityMenu.Config.State.FreecamReleaseKeysState = false
			hook.Remove("CalcView", "UtilityMenu_FreecamView")
			hook.Remove("PlayerBindPress", "UtilityMenu_FreecamBlockKeys")
			return
		end
		if vgui.GetKeyboardFocus() or gui.IsGameUIVisible() then return end
		if not UtilityMenu.Config.State.FreecamReleaseKeysState then
			for _, cmdStr in ipairs(UtilityMenu.Config.FreecamReleaseKeys) do
				LocalPlayer():ConCommand(cmdStr)
			end
			UtilityMenu.Config.State.FreecamReleaseKeysState = true
		end
		local baseSpeed = cookie.GetNumber("basespeed", 1)
		local sensitivity = 0.0175
		local mouseX, mouseY = cmd:GetMouseX() * sensitivity, cmd:GetMouseY() * sensitivity
		local speed = input.IsKeyDown(KEY_LSHIFT) and baseSpeed * 10 or baseSpeed
		local ang = UtilityMenu.Config.State.FreecamAngle
		ang.p, ang.y = math.Clamp(ang.p + mouseY, -89, 89), ang.y - mouseX
		cmd:SetViewAngles(UtilityMenu.Config.State.FrozenViewAngle)
		local wishMove = Vector()
		if input.IsKeyDown(KEY_W) then wishMove = wishMove + ang:Forward() end
		if input.IsKeyDown(KEY_S) then wishMove = wishMove - ang:Forward() end
		if input.IsKeyDown(KEY_D) then wishMove = wishMove + ang:Right() end
		if input.IsKeyDown(KEY_A) then wishMove = wishMove - ang:Right() end
		if input.IsKeyDown(KEY_SPACE) then wishMove = wishMove + ang:Up() end
		if input.IsKeyDown(KEY_LCONTROL) then wishMove = wishMove - ang:Up() end
		if wishMove:LengthSqr() > 0 then
			wishMove:Normalize()
			UtilityMenu.Config.State.FreecamPosition = UtilityMenu.Config.State.FreecamPosition + wishMove * speed
		end
		hook.Add("PlayerBindPress", "UtilityMenu_FreecamBlockKeys", function(_, bind)
			for _, blocked in ipairs(UtilityMenu.Config.FreecamAllowedBinds) do
				if string.find(bind, blocked) then
					return false
				end
			end
			return true
		end)
	end)
	hook.Add("CreateMove", "UtilityMenu_AutoBhop", function(cmd)
		if not UtilityMenu.Settings.autobhop then return end
		local ply = LocalPlayer()
		if cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
			cmd:RemoveKey(IN_JUMP)
		end
	end)
	hook.Add("Think", "UtilityMenu_FlashlightSpam", function()
		if not UtilityMenu.Settings.flashlightspam or UtilityMenu.Config.State.FreecamEnabled then return end
		if not input.IsKeyDown(KEY_F) or vgui.GetKeyboardFocus() or gui.IsGameUIVisible() then return end
		RunConsoleCommand("impulse", "100")
	end)
	hook.Add("Think", "UtilityMenu_AttackSpam", function()
		if not UtilityMenu.Settings.Attackspam or UtilityMenu.Config.State.FreecamEnabled then return end
		if not input.IsMouseDown(MOUSE_LEFT) or vgui.GetKeyboardFocus() or gui.IsGameUIVisible() then return end
		if not UtilityMenu.Config.State.LastAttackTime then
			UtilityMenu.Config.State.LastAttackTime = 0
		end
		local currentTime = CurTime()
		if currentTime - UtilityMenu.Config.State.LastAttackTime > 0.0334 then
			RunConsoleCommand("+attack")
			timer.Simple(0, function()
				RunConsoleCommand("-attack")
			end)
			UtilityMenu.Config.State.LastAttackTime = currentTime
		end
	end)
	hook.Add("Think", "UtilityMenu_PropKillSpawner", function()
		if not UtilityMenu.Settings.pkbinds or UtilityMenu.Config.State.FreecamEnabled then
			hook.Remove("PlayerBindPress", "UtilityMenu_PropKillBlockKeys")
			return
		end
		if vgui.GetKeyboardFocus() or gui.IsGameUIVisible() then return end
		for key, model in pairs(UtilityMenu.Config.PropKillProps) do
			local isDown = input.IsKeyDown(key)
			if isDown and not UtilityMenu.Config.State.LastPropKeyState[key] then
				RunConsoleCommand("gm_spawn", model)
			end
			UtilityMenu.Config.State.LastPropKeyState[key] = isDown
		end
		hook.Add("PlayerBindPress", "UtilityMenu_PropKillBlockKeys", function(_, bind)
			for _, blocked in ipairs(UtilityMenu.Config.PkAllowedBinds) do
				if string.find(bind, blocked) then return false end
			end
			return true
		end)
	end)
	hook.Add("PostDrawOpaqueRenderables", "UtilityMenu_DrawEntityBoxes", function()
		local drawFunctions = {
			propbox = {cache = UtilityMenu.Config.State.EntityCache.Props, color = UtilityMenu.Config.EntityColors.Prop, useAngle = true},
			npcbox = {cache = UtilityMenu.Config.State.EntityCache.NPCs, color = UtilityMenu.Config.EntityColors.NPC, checkAlive = true},
			playerbox = {cache = UtilityMenu.Config.State.EntityCache.Players, color = UtilityMenu.Config.EntityColors.Player, checkAlive = true}
		}
		for setting, data in pairs(drawFunctions) do
			if not UtilityMenu.Settings[setting] then continue end
			for _, ent in ipairs(data.cache) do
				if not IsValid(ent) then continue end
				if data.checkAlive and not ent:Alive() then continue end
				render.DrawWireframeBox(ent:GetPos(), data.useAngle and ent:GetAngles() or Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), data.color, false)
			end
		end
	end)
	hook.Add("PostDrawTranslucentRenderables", "UtilityMenu_DrawLinesAndBones", function()
		local ply = LocalPlayer()
		local startPos = ply:EyePos() + ply:GetAimVector() * 50
		local lineFunctions, boneFunctions = {
			npcline = {cache = UtilityMenu.Config.State.EntityCache.NPCs, color = UtilityMenu.Config.EntityColors.NPC},
			playerline = {cache = UtilityMenu.Config.State.EntityCache.Players, color = UtilityMenu.Config.EntityColors.Player}
		}, {
			npcbones = {cache = UtilityMenu.Config.State.EntityCache.NPCs, color = UtilityMenu.Config.EntityColors.NPC},
			playerbones = {cache = UtilityMenu.Config.State.EntityCache.Players, color = UtilityMenu.Config.EntityColors.Player}
		}
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			for setting, data in pairs(lineFunctions) do
				if not UtilityMenu.Settings[setting] then continue end
				for _, ent in ipairs(data.cache) do
					if not IsValid(ent) or not ent:Alive() then continue end
					local endPos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
					render.DrawLine(startPos, endPos, data.color, false)
				end
			end
		end
		for setting, data in pairs(boneFunctions) do
			if not UtilityMenu.Settings[setting] then continue end
			for _, ent in ipairs(data.cache) do
				if not IsValid(ent) or not ent:Alive() then continue end
				if setting == "playerbones" and ent == LocalPlayer() then continue end
				UtilityMenu.DrawBones(ent, data.color)
			end
		end
	end)
	hook.Add("HUDPaint", "UtilityMenu_DrawHUD", function()
		local ply = LocalPlayer()
		local screenWidth, screenHeight = ScrW(), ScrH()
		if UtilityMenu.Settings.clientinfo and ply:Alive() then
			local fps = math.floor(1 / FrameTime())
			local infoDisplay = cookie.GetNumber("infodisplay", 1)
			local offset = infoDisplay == 3 and 75 or 87
			if infoDisplay == 1 or infoDisplay == 2 then
				draw.SimpleText(
					"Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", screenWidth / 2,
					screenHeight / 2 + 75, UtilityMenu.Config.Colors.White, TEXT_ALIGN_CENTER
				)
			end
			if infoDisplay == 1 or infoDisplay == 3 then
				local fpsColor = Color(255 - math.min(fps / 60, 1) * 255, math.min(fps / 60, 1) * 255, 0)
				draw.SimpleText("FPS:" .. fps, "BudgetLabel", screenWidth / 2, screenHeight / 2 + offset, fpsColor, TEXT_ALIGN_CENTER)
			end
		end
		if UtilityMenu.Settings.npcinfo then
			for _, npc in ipairs(UtilityMenu.Config.State.EntityCache.NPCs) do
				if not IsValid(npc) or not npc:Alive() then continue end
				local pos = npc:LocalToWorld(Vector(0, 0, npc:OBBMaxs().z)):ToScreen()
				local maxHealth, health = npc:GetMaxHealth() or 100, npc:Health()
				local healthColor
				if maxHealth <= 0 then
					healthColor = Color(0, 255, 0)
				else
					local healthRatio = math.Clamp(health / maxHealth, 0, 1)
					healthColor = Color(255 - healthRatio * 255, healthRatio * 255, 0)
				end
				local npcInfoDisplay = cookie.GetNumber("npcinfodisplay", 1)
				local offset = (npcInfoDisplay >= 2) and 0 or 12
				if npcInfoDisplay == 1 or npcInfoDisplay == 2 then
					draw.SimpleText(npc:GetClass(), "BudgetLabel", pos.x, pos.y - offset, UtilityMenu.Config.EntityColors.NPC, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if npcInfoDisplay == 1 or npcInfoDisplay == 3 then
					draw.SimpleText("HP:" .. health, "BudgetLabel", pos.x, pos.y, healthColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if UtilityMenu.Settings.playerinfo then
			for _, player in ipairs(UtilityMenu.Config.State.EntityCache.Players) do
				if not IsValid(player) or not player:Alive() then continue end
				local pos = player:LocalToWorld(Vector(0, 0, player:OBBMaxs().z)):ToScreen()
				local maxHealth, health = player:GetMaxHealth() or 100, player:Health()
				local healthRatio = health / maxHealth
				local healthColor, statusColor, statusText = Color(255 - healthRatio * 255, healthRatio * 255, 0), UtilityMenu.Config.Colors.White, ""
				local playerInfoDisplay = cookie.GetNumber("playerinfodisplay", 1)
				if player:VoiceVolume() > 0.02 then
					statusText = "*speaking*"
					statusColor = UtilityMenu.Config.Colors.Yellow
				elseif player:IsTyping() then
					statusText = "*typing*"
					statusColor = UtilityMenu.Config.Colors.Cyan
				elseif (playerInfoDisplay == 5 or playerInfoDisplay == 11) then
					statusColor = team.GetColor(player:Team())
				end
				local offset = (playerInfoDisplay >= 7) and 0 or 12
				local nameTagColor = (playerInfoDisplay == 2 or playerInfoDisplay == 5 or playerInfoDisplay == 8 or playerInfoDisplay == 11) and statusColor
				      or ((playerInfoDisplay >= 4 and playerInfoDisplay <= 6) or (playerInfoDisplay >= 10 and playerInfoDisplay <= 12)) and team.GetColor(player:Team())
					  or UtilityMenu.Config.Colors.White
				if (playerInfoDisplay == 1 or playerInfoDisplay == 4 or playerInfoDisplay == 7 or playerInfoDisplay == 10) then
					draw.SimpleText(statusText, "BudgetLabel", pos.x, pos.y - offset - 12, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if playerInfoDisplay != 13 then
					draw.SimpleText(player:Nick(), "BudgetLabel", pos.x, pos.y - offset, nameTagColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if (playerInfoDisplay >= 1 and playerInfoDisplay <= 6) or playerInfoDisplay == 13 then
					local infoText = "HP:" .. health
					if player:Armor() > 0 then
						infoText = infoText .. "|AP:" .. player:Armor()
					end
					draw.SimpleText(infoText, "BudgetLabel", pos.x, pos.y, healthColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if UtilityMenu.Settings.minimap then
			local sizeIndex, scaleIndex, posIndex = cookie.GetNumber("mapsize", 1), cookie.GetNumber("mapscale", 1), cookie.GetNumber("mappos", 1)
			local size, scale = UtilityMenu.Config.MapSizes[sizeIndex] or 150, UtilityMenu.Config.MapScales[scaleIndex] or 25
			local radius = size / 2
			local corners = {
				{x = 16 + radius, y = 16 + radius}, {x = screenWidth - 16 - radius, y = 16 + radius},
				{x = 16 + radius, y = screenHeight - 16 - radius}, {x = screenWidth - 16 - radius, y = screenHeight - 16 - radius}
			}
			local centerX, centerY, yaw = corners[posIndex].x, corners[posIndex].y, EyeAngles().y
			surface.SetDrawColor(0, 0, 0, 225)
			surface.DrawRect(centerX - radius, centerY - radius, radius * 2, radius * 2)
			for _, npc in ipairs(UtilityMenu.Config.State.EntityCache.NPCs) do
				if not IsValid(npc) or not npc:Alive() then continue end
				local x, y = UtilityMenu.MinimapProjection(npc:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(UtilityMenu.Config.Colors.Red)
				surface.DrawRect(centerX + x - 2, centerY + y - 2, 4, 4)
			end
			for _, player in ipairs(UtilityMenu.Config.State.EntityCache.Players) do
				if not IsValid(player) or player == ply or not player:Alive() then continue end
				local x, y = UtilityMenu.MinimapProjection(player:GetPos(), yaw, scale, radius)
				local markerColorSetting, markerColor = cookie.GetNumber("playermarkercolor", 1), UtilityMenu.Config.EntityColors.Player
				if markerColorSetting == 2 then
					if player:VoiceVolume() > 0.02 then
						markerColor = UtilityMenu.Config.Colors.Yellow
					elseif player:IsTyping() then
						markerColor = UtilityMenu.Config.Colors.Cyan
					end
				end
				surface.SetDrawColor(markerColor)
				surface.DrawRect(centerX + x - 2, centerY + y - 2, 4, 4)
				draw.SimpleText(player:Nick(), "BudgetLabel", centerX + x, centerY + y, markerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
			surface.SetDrawColor(UtilityMenu.Config.Colors.Green)
			surface.DrawLine(centerX, centerY - 4, centerX - 4, centerY + 4)
			surface.DrawLine(centerX, centerY - 4, centerX + 4, centerY + 4)
			surface.DrawLine(centerX - 4, centerY + 4, centerX + 4, centerY + 4)
		end
	end)
	hook.Add("CalcView", "UtilityMenu_FixedCamera", function(ply, pos, angles, fov)
		if not (UtilityMenu.Settings.noshake or UtilityMenu.Settings.norecoil) then return end
		if UtilityMenu.Settings.norecoil then
			local playerMeta = FindMetaTable("Player")
			if not playerMeta.OriginalSetEyeAngles then
				playerMeta.OriginalSetEyeAngles = playerMeta.SetEyeAngles
				playerMeta.SetEyeAngles = function(self, angle)
					local source = debug.getinfo(2).short_src or ""
					if string.find(string.lower(source), "/weapons/") then return end
					self:OriginalSetEyeAngles(angle)
				end
			end
		else
			local playerMeta = FindMetaTable("Player")
			if playerMeta.OriginalSetEyeAngles then
				playerMeta.SetEyeAngles = playerMeta.OriginalSetEyeAngles
				playerMeta.OriginalSetEyeAngles = nil
			end
		end
		if UtilityMenu.Settings.noshake then
			if not (UtilityMenu.Config.State.FreecamEnabled or ply:ShouldDrawLocalPlayer() or ply:InVehicle() or not ply:Alive()) then
				angles.r = 0
				return {origin = pos, angles = angles, fov = cookie.GetNumber("noshakefov", 75)}
			end
		end
	end)
end

function UtilityMenu.CreateLabel(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefaultBold")
	label:SetTextColor(UtilityMenu.Config.Colors.White)
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(5, 5, 0, 0)
	return label
end

function UtilityMenu.CreateCheckbox(text, key, parent)
	local checkbox = vgui.Create("DCheckBoxLabel", parent)
	checkbox:SetText(text)
	checkbox:SetFont("DermaDefault")
	checkbox:SetTextColor(UtilityMenu.Config.Colors.White)
	local savedValue = cookie.GetNumber(key, 0) == 1
	UtilityMenu.Settings[key] = UtilityMenu.Settings[key] ~= nil and UtilityMenu.Settings[key] or savedValue
	checkbox:SetValue(UtilityMenu.Settings[key])
	checkbox:Dock(TOP)
	checkbox:SizeToContents()
	checkbox:DockMargin(10, 5, 0, 0)
	checkbox.OnChange = function(self, value)
		UtilityMenu.Settings[key] = value
		cookie.Set(key, value and 1 or 0)
	end
	return checkbox
end

function UtilityMenu.CreateButtonGrid(items, onClick, parent)
	local grid = vgui.Create("DIconLayout", parent)
	grid:Dock(TOP)
	grid:SetSpaceX(5)
	grid:SetSpaceY(5)
	grid:CenterHorizontal()
	grid:DockMargin(9, 5, 0, 0)
	for _, item in ipairs(items) do
		local button = grid:Add("DButton")
		button:SetText(item:sub(1, 1):upper() .. item:sub(2):lower())
		button:SetSize(60, 30)
		button.DoClick = function()
			onClick(item)
		end
	end
	return grid
end

function UtilityMenu.CreateSlider(label, min, max, key, parent)
	local slider = vgui.Create("DNumSlider", parent)
	slider:SetText(label)
	slider.Label:SetFont("DermaDefault")
	slider.Label:SetTextColor(UtilityMenu.Config.Colors.White)
	slider:Dock(TOP)
	slider:DockMargin(10, 5, 0, 0)
	slider:SetTall(15)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(0)
	local savedValue = cookie.GetNumber(key, min)
	slider:SetValue(savedValue)
	function slider:OnValueChanged(value)
		local roundedValue = math.Round(value)
		slider:SetValue(roundedValue)
		cookie.Set(key, roundedValue)
	end
	return slider
end

function UtilityMenu.CreateMenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu V8")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	local utilityScroll, displayScroll, settingsScroll = vgui.Create("DScrollPanel", tab), vgui.Create("DScrollPanel", tab), vgui.Create("DScrollPanel", tab)
	tab:AddSheet("Utility", utilityScroll, "icon16/wrench.png")
	tab:AddSheet("Display", displayScroll, "icon16/monitor.png")
	tab:AddSheet("Settings", settingsScroll, "icon16/cog.png")
	UtilityMenu.CreateLabel("Miscellaneous options:", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle auto bhop", "autobhop", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle Attack spam", "Attackspam", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle flashlight spam", "flashlightspam", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle freecam", "freecam", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle no recoil", "norecoil", utilityScroll)
	UtilityMenu.CreateCheckbox("Toggle pk binds", "pkbinds", utilityScroll)
	UtilityMenu.CreateLabel("Player gestures:", utilityScroll)
	UtilityMenu.CreateButtonGrid(UtilityMenu.Config.Gestures, function(gesture) RunConsoleCommand("act", gesture) end, utilityScroll)
	UtilityMenu.CreateLabel("Miscellaneous options:", displayScroll)
	UtilityMenu.CreateCheckbox("Draw client info", "clientinfo", displayScroll)
	UtilityMenu.CreateCheckbox("Draw prop boxes", "propbox", displayScroll)
	UtilityMenu.CreateCheckbox("Show minimap", "minimap", displayScroll)
	UtilityMenu.CreateCheckbox("Toggle no shake", "noshake", displayScroll)
	UtilityMenu.CreateLabel("NPC options:", displayScroll)
	UtilityMenu.CreateCheckbox("Draw NPC bones", "npcbones", displayScroll)
	UtilityMenu.CreateCheckbox("Draw NPC boxes", "npcbox", displayScroll)
	UtilityMenu.CreateCheckbox("Draw NPC info", "npcinfo", displayScroll)
	UtilityMenu.CreateCheckbox("Draw NPC lines", "npcline", displayScroll)
	UtilityMenu.CreateLabel("Player Options:", displayScroll)
	UtilityMenu.CreateCheckbox("Draw player bones", "playerbones", displayScroll)
	UtilityMenu.CreateCheckbox("Draw player boxes", "playerbox", displayScroll)
	UtilityMenu.CreateCheckbox("Draw player info", "playerinfo", displayScroll)
	UtilityMenu.CreateCheckbox("Draw player lines", "playerline", displayScroll)
	UtilityMenu.CreateLabel("Freecam settings:", settingsScroll)
	UtilityMenu.CreateSlider("Speed:", 1, 50, "basespeed", settingsScroll)
	UtilityMenu.CreateLabel("Client info settings:", settingsScroll)
	UtilityMenu.CreateSlider("Info:", 1, 3, "infodisplay", settingsScroll)
	UtilityMenu.CreateLabel("Map settings:", settingsScroll)
	UtilityMenu.CreateSlider("Pos:", 1, 4, "mappos", settingsScroll)
	UtilityMenu.CreateSlider("Scale:", 1, 5, "mapscale", settingsScroll)
	UtilityMenu.CreateSlider("Size:", 1, 5, "mapsize", settingsScroll)
	UtilityMenu.CreateSlider("Player status:", 1, 2, "playermarkercolor", settingsScroll)
	UtilityMenu.CreateLabel("No shake:", settingsScroll)
	UtilityMenu.CreateSlider("FOV", 75, 120, "noshakefov", settingsScroll)
	UtilityMenu.CreateLabel("NPC info settings:", settingsScroll)
	UtilityMenu.CreateSlider("Info:", 1, 3, "npcinfodisplay", settingsScroll)
	UtilityMenu.CreateLabel("Player info settings:", settingsScroll)
	UtilityMenu.CreateSlider("Info:", 1, 13, "playerinfodisplay", settingsScroll)
	return frame
end

concommand.Add("open_utility_menu", function()
	UtilityMenu.Menu:SetVisible(true)
	UtilityMenu.Menu:MakePopup()
end)

concommand.Add("toggle_freecam", function()
	local ply = LocalPlayer()
	if not UtilityMenu.Settings.freecam then return end
	if UtilityMenu.Config.State.FreecamEnabled then
		UtilityMenu.Config.State.FreecamEnabled = false
		hook.Remove("CalcView", "UtilityMenu_FreecamView")
		hook.Remove("PlayerBindPress", "UtilityMenu_FreecamBlockKeys")
	else
		UtilityMenu.Config.State.FreecamEnabled = true
		UtilityMenu.Config.State.FreecamPosition = EyePos()
		UtilityMenu.Config.State.FreecamAngle = Angle(EyeAngles().p, EyeAngles().y, 0)
		UtilityMenu.Config.State.FrozenViewAngle = ply:EyeAngles()
		hook.Add("CalcView", "UtilityMenu_FreecamView", function(_, _, _, fov)
			return {origin = UtilityMenu.Config.State.FreecamPosition, angles = UtilityMenu.Config.State.FreecamAngle, fov = fov, drawviewer = true}
		end)
	end
end)

hook.Add("InitPostEntity", "UtilityMenu_AutoCreate", function()
    if not UtilityMenu.Menu or not IsValid(UtilityMenu.Menu) then
        UtilityMenu.Menu = UtilityMenu.CreateMenu()
    end
end)

if not UtilityMenu.Config.State.ScriptRan then
	UtilityMenu.Config.State.ScriptRan = true
	print("\nRun 'open_utility_menu' to open the menu!\n")
end

UtilityMenu.SetupHooks()