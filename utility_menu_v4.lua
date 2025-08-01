if CLIENT then

	-- #$%#$% LOCALS #$%#$%

	local settings = {autobhop = cookie.GetNumber("utility_autobhop", 0) == 1, propbox = cookie.GetNumber("utility_propbox", 0) == 1, npcbox = cookie.GetNumber("utility_npcbox", 0) == 1, playerbox = cookie.GetNumber("utility_playerbox", 0) == 1, speedometer = cookie.GetNumber("utility_speedometer", 0) == 1, npcnametag = cookie.GetNumber("utility_npcnametag", 0) == 1, npccursorline = cookie.GetNumber("utility_npccursorline", 0) == 1, playernametag = cookie.GetNumber("utility_playernametag", 0) == 1, playercursorline = cookie.GetNumber("utility_playercursorline", 0) == 1, playerbones = cookie.GetNumber("utility_playerbones", 0) == 1, npcbones = cookie.GetNumber("utility_npcbones", 0) == 1}
	local colors = {prop = Color(0, 255, 255), npc = Color(255, 0, 0), player = Color(255, 255, 0)}
	local freecamSettings = {sensitivity = 1.75, speed = 10, fastSpeed = 25, acceleration = 0}
	local utilityMenu = nil

	-- #$%#$% FUNCTIONS #$%#$%

	local function drawBox(ent, color, ang)
		cam.IgnoreZ(true)
		render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true)
		cam.IgnoreZ(false)
	end

	local function drawNametag(ent, name, color)
		local pos = ent:EyePos():ToScreen()
		draw.SimpleText(name, "BudgetLabel", pos.x, pos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	local function drawCursorLines(entities, color)
		local ply = LocalPlayer()
		local dir = gui.ScreenToVector(ScrW() / 2, ScrH() / 2)
		local startPos = ply:EyePos() + dir * 100
		for _, ent in ipairs(entities) do
			cam.IgnoreZ(true)
			render.DrawLine(startPos, ent:EyePos(), color, true)
			cam.IgnoreZ(false)
		end
	end

	local function drawPlayerBones(ply, color)
		local origin = ply:GetPos()
		local bones = ply:GetBoneCount()
		for i = 0, bones - 1 do
			local bonePos1 = ply:GetBonePosition(i)
			local parent = ply:GetBoneParent(i)
			if parent ~= -1 then
				local bonePos2 = ply:GetBonePosition(parent)
				if bonePos1 and bonePos2 and bonePos1:Distance(origin) > 1 and bonePos2:Distance(origin) > 1 then
					cam.IgnoreZ(true)
					render.DrawLine(bonePos1, bonePos2, color, true)
					cam.IgnoreZ(false)
				end
			end
		end
	end

	local function drawNPCBones(npc, color)
		local origin = npc:GetPos()
		local bones = npc:GetBoneCount()
		for i = 0, bones - 1 do
			local bonePos1 = npc:GetBonePosition(i)
			local parent = npc:GetBoneParent(i)
			if parent ~= -1 then
				local bonePos2 = npc:GetBonePosition(parent)
				if bonePos1 and bonePos2 and bonePos1:Distance(origin) > 1 and bonePos2:Distance(origin) > 1 then
					cam.IgnoreZ(true)
					render.DrawLine(bonePos1, bonePos2, color, true)
					cam.IgnoreZ(false)
				end
			end
		end
	end

	local function EnableFreecam()
		local ply = LocalPlayer()
		freecamEnabled = true
		freecamPos, freecamAng = ply:EyePos(), ply:EyeAngles()
		frozenPlayerViewAng = ply:EyeAngles()
		ply:SetMoveType(MOVETYPE_NONE)
		ply:SetVelocity(vector_origin)
		if ply.DrawViewModel then ply:DrawViewModel(false) end
		input.SetCursorPos(ScrW()/2, ScrH()/2)
		hook.Add("CalcView", "FreecamView", function(_,_,_,fov)
			return {origin = freecamPos, angles = freecamAng, fov = fov, drawviewer = true}
		end)
	end

	local function DisableFreecam()
		local ply = LocalPlayer()
		freecamEnabled = false
		ply:SetMoveType(MOVETYPE_WALK)
		if ply.DrawViewModel then ply:DrawViewModel(true) end
		hook.Remove("CalcView", "FreecamView")
	end

	-- #$%#$% HOOKS #$%#$%

	hook.Add("CreateMove", "autobhop", function(cmd)
		if settings.autobhop then
			local ply = LocalPlayer()
			local onGround = ply:OnGround()
			local inNoClip = ply:GetMoveType() == MOVETYPE_NOCLIP
			local inWater = ply:WaterLevel() >= 2
			if cmd:KeyDown(IN_JUMP) then
				if onGround or inNoClip or inWater then
					cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
				else
					cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
				end
			end
		end
	end)

	hook.Add("HUDPaint", "speedometer", function()
		if settings.speedometer then
			local ply = LocalPlayer()
			local speed = math.Round(ply:GetVelocity():Length())
			if not ply:Alive() then return end
			draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2 - 45, ScrH() / 2 + 75, colors.player, TEXT_ALIGN_LEFT)
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "box", function()
		if settings.propbox then
			for _, ent in ipairs(ents.FindByClass("prop_*")) do
				drawBox(ent, colors.prop)
			end
		end
		if settings.npcbox then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					drawBox(npc, colors.npc, Angle(0, 0, 0))
				end
			end
		end
		if settings.playerbox then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					drawBox(ply, colors.player, Angle(0, 0, 0))
				end
			end
		end
	end)

	hook.Add("HUDPaint", "nametag", function()
		if settings.npcnametag then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					drawNametag(npc, npc.PrintName or npc:GetClass(), colors.npc)
				end
			end
		end
		if settings.playernametag then
			local ply = LocalPlayer()
			for _, p in ipairs(player.GetAll()) do
				if p ~= ply and p:Alive() then
					drawNametag(p, p:Nick(), colors.player)
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "cursorline", function()
		local ply = LocalPlayer()
		if not ply:Alive() or ply:ShouldDrawLocalPlayer() then return end
		if settings.npccursorline then
			local npcs = {}
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					table.insert(npcs, npc)
				end
			end
			drawCursorLines(npcs, colors.npc)
		end
		if settings.playercursorline then
			local players = {}
			for _, p in ipairs(player.GetAll()) do
				if p ~= ply and p:Alive() then
					table.insert(players, p)
				end
			end
			drawCursorLines(players, colors.player)
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "npcbones", function()
		if settings.npcbones then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					drawNPCBones(npc, colors.npc)
				end
			end
		end
	end)

	hook.Add("CreateMove", "freecammove", function(cmd)
		if not freecamEnabled or vgui.GetKeyboardFocus() then return end
		local mouseX = cmd:GetMouseX()
		local mouseY = cmd:GetMouseY()
		local speed = (input.IsKeyDown(KEY_LSHIFT) and freecamSettings.fastSpeed or freecamSettings.speed)
		local wishMove = Vector()
		freecamAng.p = math.Clamp(freecamAng.p + mouseY * freecamSettings.sensitivity * 0.01, -89, 89)
		freecamAng.y = freecamAng.y - mouseX * freecamSettings.sensitivity * 0.01
		freecamAng.r = 0
		if input.IsKeyDown(KEY_W) then wishMove = wishMove + freecamAng:Forward() end
		if input.IsKeyDown(KEY_S) then wishMove = wishMove - freecamAng:Forward() end
		if input.IsKeyDown(KEY_D) then wishMove = wishMove + freecamAng:Right() end
		if input.IsKeyDown(KEY_A) then wishMove = wishMove - freecamAng:Right() end
		if input.IsKeyDown(KEY_SPACE) then wishMove = wishMove + freecamAng:Up() end
		if input.IsKeyDown(KEY_LCONTROL) then wishMove = wishMove - freecamAng:Up() end
		if wishMove:LengthSqr() > 0 then
			wishMove:Normalize()
			freecamPos = freecamPos + wishMove * speed
		end
		cmd:ClearButtons()
		cmd:ClearMovement()
		cmd:SetViewAngles(frozenPlayerViewAng)
	end)

	-- #$%#$% MENU #$%#$%

	local function createLabel(text, parent)
		local label = vgui.Create("DLabel", parent)
		label:SetText(text)
		label:SetFont("DermaDefaultBold")
		label:SetTextColor(color_white)
		label:SizeToContents()
		label:Dock(TOP)
		label:DockMargin(5, 5, 5, 0)
		return label
	end

	local function createCheckbox(text, parent, settingKey)
		local checkbox = vgui.Create("DCheckBoxLabel", parent)
		checkbox:SetText(text)
		checkbox:SetFont("DermaDefault")
		checkbox:SetTextColor(color_white)
		checkbox:SetValue(settings[settingKey] and 1 or 0)
		checkbox:SizeToContents()
		checkbox:Dock(TOP)
		checkbox:DockMargin(5, 5, 5, 0)
		checkbox.OnChange = function(_, val)
			settings[settingKey] = val
			cookie.Set("utility_" .. settingKey, val and "1" or "0")
		end
		return checkbox
	end

	local function createMenu()
		local frame = vgui.Create("DFrame")
		local tab = vgui.Create("DPropertySheet", frame)
		local scrollUtility = vgui.Create("DScrollPanel", tab)
		local scrollDisplay = vgui.Create("DScrollPanel", tab)

		frame.OnClose = function(self)
			gui.EnableScreenClicker(false)
		end

		frame:SetSize(300, 400)
		frame:Center()
		frame:SetTitle("Utility Menu")
		frame:SetDeleteOnClose(false)
		frame:SetVisible(false)

		tab:Dock(FILL)
		tab:SetFadeTime(0)

		createLabel("Miscellaneous Options:", scrollUtility)
		createCheckbox("Auto Bhop", scrollUtility, "autobhop")
		createLabel("Miscellaneous Options:", scrollDisplay)
		createCheckbox("Speedometer", scrollDisplay, "speedometer")
		createCheckbox("Prop Box", scrollDisplay, "propbox")
		createLabel("NPC Options:", scrollDisplay)
		createCheckbox("NPC Box", scrollDisplay, "npcbox")
		createCheckbox("NPC Bones", scrollDisplay, "npcbones")
		createCheckbox("NPC Nametag", scrollDisplay, "npcnametag")
		createCheckbox("NPC Cursor Line", scrollDisplay, "npccursorline")
		createLabel("Player Options:", scrollDisplay)
		createCheckbox("Player Box", scrollDisplay, "playerbox")
		createCheckbox("Player Bones", scrollDisplay, "playerbones")
		createCheckbox("Player Nametag", scrollDisplay, "playernametag")
		createCheckbox("Player Cursor Line", scrollDisplay, "playercursorline")

		tab:AddSheet("Utility", scrollUtility, "icon16/wrench.png")
		tab:AddSheet("Display", scrollDisplay, "icon16/monitor.png")

		return frame
	end

	-- #$%#$% COMMANDS #$%#$%

	concommand.Add("open_utility_menu", function()
		if IsValid(_G.utilityMenu) then
			_G.utilityMenu:SetVisible(true)
			gui.EnableScreenClicker(true)
		else
			_G.utilityMenu = createMenu()
			_G.utilityMenu:SetVisible(true)
			gui.EnableScreenClicker(true)
		end
	end)

	concommand.Add("toggle_freecam", function()
		if freecamEnabled then
			DisableFreecam()
		else
			EnableFreecam()
		end
	end)
end