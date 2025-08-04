if CLIENT then
    local settings = {
        npcOutline = false,
        propOutline = false,
        playerOutline = false,
        nameTags = false,
        cursorLine = false,
    }

    local npcColor = Color(255, 0, 0)
    local propColor = Color(0, 255, 255)
    local playerColor = Color(0, 255, 0)

    local function DrawBoundingBox(ent, color, overrideAng)
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        local ang = overrideAng or ent:GetAngles()
        local pos = ent:GetPos()

		cam.IgnoreZ(true)
        render.DrawWireframeBox(pos, ang, mins, maxs, Color(color.r, color.g, color.b, 255), true)
		cam.IgnoreZ(false)
    end

    hook.Add("PostDrawOpaqueRenderables", "CustomBoxHighlights", function()
		
        if settings.npcOutline then
            for _, ent in ipairs(ents.FindByClass("npc_*")) do
                if ent:Health() > 0 then
                    DrawBoundingBox(ent, npcColor, Angle(0, 0, 0))
                end
            end
        end

        if settings.propOutline then
            for _, ent in ipairs(ents.GetAll()) do
                if ent:GetClass():find("^prop_") then
                    DrawBoundingBox(ent, propColor)
                end
            end
        end

        if settings.playerOutline then
            for _, ply in ipairs(player.GetAll()) do
                if ply ~= LocalPlayer() and ply:Alive() then
                    DrawBoundingBox(ply, playerColor, Angle(0, 0, 0))
                end
            end
        end
    end)

    hook.Add("HUDPaint", "DrawConstantNameTags", function()
        if not settings.nameTags then return end

        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() or ply == LocalPlayer() then continue end

            local headPos = ply:EyePos() + Vector(0, 0, 10)
            local screenPos = headPos:ToScreen()

            if not screenPos.visible then continue end

            local name = ply:Nick()
            draw.SimpleTextOutlined(
                name,
                "Trebuchet24",
                screenPos.x,
                screenPos.y,
                team.GetColor(ply:Team()),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_BOTTOM,
                1,
                Color(0, 0, 0, 255)
            )
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "DrawLinesToPlayers", function()
        if not settings.cursorLine then return end
		
		cam.IgnoreZ(true)

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local tr = ply:GetEyeTrace()
        local hitPos = tr.HitPos

        for _, other in ipairs(player.GetAll()) do
            if other ~= ply and other:Alive() then
                render.DrawLine(hitPos, other:EyePos(), Color(255, 255, 0), true)
            end
        end
		
		cam.IgnoreZ(false)
    end)

    local actList = {
        "dance", "robot", "muscle", "zombie", "agree", "disagree", "cheer",
        "wave", "laugh", "forward", "group", "halt", "salute", "becon", "bow"
    }

    local UtilityMenu

    local function CreateUtilityMenu()
        UtilityMenu = vgui.Create("DFrame")
        UtilityMenu:SetSize(350, 350)
        UtilityMenu:Center()
        UtilityMenu:SetTitle("Utility & Act Menu")
        UtilityMenu:SetDraggable(true)
        UtilityMenu:SetDeleteOnClose(false)
        UtilityMenu:SetVisible(false)
        UtilityMenu:ShowCloseButton(false)

        local scroll = vgui.Create("DScrollPanel", UtilityMenu)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)
		
		local utilabel = vgui.Create("DLabel", scroll)
        utilabel:SetText("Utility Options:")
        utilabel:SetFont("DermaDefaultBold")
        utilabel:Dock(TOP)
        utilabel:DockMargin(0, 0, 0, 5)
        utilabel:SizeToContents()

        local options = {
			{ label = "NPC Outline", var = "npcOutline" },
			{ label = "Prop Outline", var = "propOutline" },
			{ label = "Player Outline", var = "playerOutline" },
			{ label = "Player Name Tags", var = "nameTags" },
			{ label = "Line to Players", var = "cursorLine" }
        }

        for _, opt in ipairs(options) do
            local cb = vgui.Create("DCheckBoxLabel", scroll)
            cb:SetText(opt.label)
            cb:SetValue(settings[opt.var])
            cb:Dock(TOP)
            cb:DockMargin(0, 0, 0, 5)
            cb.OnChange = function(_, val)
                settings[opt.var] = val
            end
            cb:SizeToContents()
        end

        local actlabel = vgui.Create("DLabel", scroll)
        actlabel:SetText("Act Options:")
        actlabel:SetFont("DermaDefaultBold")
        actlabel:Dock(TOP)
        actlabel:DockMargin(0, 10, 0, 5)
        actlabel:SizeToContents()

        local grid = vgui.Create("DIconLayout", scroll)
        grid:Dock(TOP)
        grid:SetSpaceX(5)
        grid:SetSpaceY(3)

        for _, act in ipairs(actList) do
            local btn = grid:Add("DButton")
            btn:SetSize(60, 30)
            btn:SetText(act)
            btn.DoClick = function()
                LocalPlayer():ConCommand("act " .. act)
            end
        end
    end

    local lastKeyState = false
    hook.Add("Think", "UtilityMenuThink", function()
        local keyDown = input.IsKeyDown(KEY_F7)

        if keyDown and not lastKeyState then
            if not IsValid(UtilityMenu) then
                CreateUtilityMenu()
            end

            local isVisible = UtilityMenu:IsVisible()
            UtilityMenu:SetVisible(not isVisible)

            if not isVisible then
                UtilityMenu:MakePopup()
            end
        end
		
        lastKeyState = keyDown
    end)
end
