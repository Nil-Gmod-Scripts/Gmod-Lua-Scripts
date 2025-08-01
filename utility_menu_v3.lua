if CLIENT then
	local settings = {autobhop = false, speedometer = false, propbox = false, npcbox = false, playerbox = false, npcnametags = false, playernametags = false, npccursorlines = false, playercursorlines = false, playerbones = false, npcbones = false}
	local colors = {prop = Color(0, 255, 255), npc = Color(255, 0, 0), player = Color(255, 255, 0)}
	local freecamSettings = {sensitivity = 1.75, speed = 10, fastSpeed = 25, acceleration = 0}
	local actList = {"dance", "robot", "muscle", "zombie", "agree", "disagree", "cheer", "wave", "laugh", "forward", "group", "halt", "salute", "becon", "bow"}
	local freecamEnabled, freecamPos, freecamAng, frozenPlayerViewAng = false, Vector(), Angle(), Angle()
	local ROTATE_UP, ROTATE_DOWN, ROTATE_LEFT, ROTATE_RIGHT = KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT
	local util = {}
	local utilityMenu

	for k in pairs(settings) do settings[k] = cookie.GetNumber("utility_" .. k, 0) == 1 end

	function util.DrawBoundingBox(ent, color, ang)
		cam.IgnoreZ(true)
		render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true)
		cam.IgnoreZ(false)
	end
	function util.DrawNameTag(ent, name, color)
		local pos = ent:EyePos():ToScreen()
		draw.SimpleText(name, "BudgetLabel", pos.x, pos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
	function util.DrawCursorLines(entities, color, filter)
		local ply, dir = LocalPlayer(), gui.ScreenToVector(ScrW() / 2, ScrH() / 2)
		local startPos = ply:EyePos() + dir * 100
		for _, ent in ipairs(entities) do
			if not filter or filter(ent) then
				cam.IgnoreZ(true)
				render.DrawLine(startPos, ent:EyePos(), color, true)
				cam.IgnoreZ(false)
			end
		end
	end
	function util.DrawBoneLines(ent, color)
		render.SetColorMaterial()
		local n, origin = ent:GetBoneCount(), ent:GetPos()
		local pos = {}
		for i = 0, n - 1 do pos[i] = ent:GetBonePosition(i) end
		for i = 0, n - 1 do
			local parent = ent:GetBoneParent(i)
			if pos[i] and pos[parent] and pos[i]:Distance(origin) > 1 and pos[parent]:Distance(origin) > 1 then
				cam.IgnoreZ(true)
				render.DrawLine(pos[i], pos[parent], color, true)
				cam.IgnoreZ(false)
			end
		end
	end

	hook.Add("PostDrawOpaqueRenderables", "DrawBoxesAndBones", function()
		for _, ent in ipairs(ents.GetAll()) do
			local class = ent:GetClass()
			if settings.propbox and class:find("^prop_") then util.DrawBoundingBox(ent, colors.prop) end
			if settings.npcbox and class:find("^npc_") and ent:Alive() then util.DrawBoundingBox(ent, colors.npc, Angle(0,0,0)) end
		end
		for _, ply in ipairs(player.GetAll()) do
			if ply ~= LocalPlayer() and ply:Alive() then
				if settings.playerbox then util.DrawBoundingBox(ply, colors.player, Angle(0,0,0)) end
				if settings.playerbones then util.DrawBoneLines(ply, colors.player) end
			end
		end
		for _, npc in ipairs(ents.FindByClass("npc_*")) do
			if settings.npcbones and npc:Alive() then util.DrawBoneLines(npc, colors.npc) end
		end
	end)
	hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
		local ply = LocalPlayer()
		if not ply:Alive() or ply:ShouldDrawLocalPlayer() then return end
		if settings.npccursorlines then util.DrawCursorLines(ents.FindByClass("npc_*"), colors.npc, function(e) return e:Alive() end) end
		if settings.playercursorlines then util.DrawCursorLines(player.GetAll(), colors.player, function(p) return p ~= ply and p:Alive() end) end
	end)
	hook.Add("CreateMove", "CustomMovement", function(cmd)
		local ply = LocalPlayer()
		if settings.autobhop and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP and ply:WaterLevel() < 2 then
			if not ply:IsOnGround() and cmd:KeyDown(IN_JUMP) then cmd:RemoveKey(IN_JUMP) end
		end
	end)
	hook.Add("HUDPaint", "DrawSpeedAndNames", function()
		local ply = LocalPlayer()
		if IsValid(ply) and ply:Alive() then
			if settings.speedometer then
				draw.SimpleText("Speed: " .. math.Round(ply:GetVelocity():Length()) .. " u/s", "BudgetLabel", ScrW()/2 - 45, ScrH()/2 + 75, colors.player, TEXT_ALIGN_LEFT)
			end
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if settings.npcnametags and npc:Alive() then
					util.DrawNameTag(npc, npc.PrintName or npc:GetClass(), colors.npc)
				end
			end
			for _, p in ipairs(player.GetAll()) do
				if settings.playernametags and p ~= ply and p:Alive() then
					util.DrawNameTag(p, p:Nick(), colors.player)
				end
			end
		end
	end)
	hook.Add("CreateMove", "FreecamMove", function(cmd)
		if not freecamEnabled or vgui.GetKeyboardFocus() then return end
		local mouseX = cmd:GetMouseX()
		local mouseY = cmd:GetMouseY()
		freecamAng.p = math.Clamp(freecamAng.p + mouseY * freecamSettings.sensitivity * 0.01, -89, 89)
		freecamAng.y = freecamAng.y - mouseX * freecamSettings.sensitivity * 0.01
		freecamAng.r = 0
		local speed = (input.IsKeyDown(KEY_LSHIFT) and freecamSettings.fastSpeed or freecamSettings.speed)
		local wishMove = Vector()
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
	local function createLabel(p, t)
		local l = vgui.Create("DLabel", p)
		l:SetText(t)
		l:SetFont("DermaDefaultBold")
		l:SetTextColor(color_white)
		l:Dock(TOP)
		l:DockMargin(5, 5, 0, 5)
		l:SizeToContents()
		return l
	end
	local function createCheckbox(p, name, key)
		local c = vgui.Create("DCheckBoxLabel", p)
		c:SetText(name)
		c:SetValue(settings[key])
		c:Dock(TOP)
		c:DockMargin(10, 0, 0, 5)
		c:SetTextColor(color_white)
		c.OnChange = function(_, val) settings[key] = val; cookie.Set("utility_" .. key, val and "1" or "0") end
		return c
	end
	local function CreateUtilityMenu()
		local frame = vgui.Create("DFrame")
		frame:SetSize(300, 400)
		frame:Center()
		frame:SetTitle("Utility Menu")
		frame:SetDeleteOnClose(false)
		frame:SetVisible(false)
		local tabs = vgui.Create("DPropertySheet", frame)
		tabs:Dock(FILL)
		tabs:SetFadeTime(0)
		local scrollUtility, scrollDisplay, scrollAct, scrollHelp = vgui.Create("DScrollPanel"), vgui.Create("DScrollPanel"), vgui.Create("DScrollPanel")
		createLabel(scrollUtility, "Miscellaneous")
		createCheckbox(scrollUtility, "Auto Bhop", "autobhop")
		createLabel(scrollDisplay, "Miscellaneous")
		createCheckbox(scrollDisplay, "Speedometer", "speedometer")
		createCheckbox(scrollDisplay, "Prop Box", "propbox")
		createLabel(scrollDisplay, "NPC Options")
		createCheckbox(scrollDisplay, "NPC Box", "npcbox")
		createCheckbox(scrollDisplay, "NPC Bones", "npcbones")
		createCheckbox(scrollDisplay, "NPC Nametags", "npcnametags")
		createCheckbox(scrollDisplay, "NPC Cursor Lines", "npccursorlines")
		createLabel(scrollDisplay, "Player Options")
		createCheckbox(scrollDisplay, "Player Box", "playerbox")
		createCheckbox(scrollDisplay, "Player Bones", "playerbones")
		createCheckbox(scrollDisplay, "Player Nametags", "playernametags")
		createCheckbox(scrollDisplay, "Player Cursor Lines", "playercursorlines")
		createLabel(scrollAct, "Player Gestures")
		local grid = vgui.Create("DIconLayout", scrollAct)
		grid:Dock(TOP); grid:SetSpaceX(5); grid:SetSpaceY(5); grid:DockMargin(10, 0, 10, 0)
		for _, act in ipairs(actList) do
			local btn = grid:Add("DButton")
			btn:SetText(act:sub(1,1):upper() .. act:sub(2))
			btn:SetSize(55, 30)
			btn.DoClick = function() RunConsoleCommand("act", act) end
		end
		tabs:AddSheet(" Utility", scrollUtility, "icon16/wrench.png")
		tabs:AddSheet(" Display", scrollDisplay, "icon16/monitor.png")
		tabs:AddSheet(" Act", scrollAct, "icon16/user.png")
		return frame
	end

	concommand.Add("open_utility_menu", function()
		if not IsValid(utilityMenu) then utilityMenu = CreateUtilityMenu() end
		utilityMenu:SetVisible(true)
		utilityMenu:MakePopup()
	end)
	concommand.Add("toggle_freecam", function()
		if freecamEnabled then
			DisableFreecam()
		else
			EnableFreecam()
		end
	end)
end