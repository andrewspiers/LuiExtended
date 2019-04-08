--[[
    LuiExtended
    License: The MIT License (MIT)
--]]

local CI            = LUIE.CombatInfo
local UI            = LUIE.UI
local C             = LUIE.CombatTextConstants
local E             = LUIE.Effects
local AlertT        = LUIE.AlertTable
local callLater = zo_callLater
local refireDelay = { }
local CT     = LUIE.CombatText
local alertTypes = LUIE.CombatTextConstants.alertType

local eventManager  = EVENT_MANAGER
local sceneManager  = SCENE_MANAGER
local windowManager = WINDOW_MANAGER
local strfmt = string.format

local moduleName    = LUIE.name .. "_CombatInfo"

local uiTlw         = {} -- GUI
local g_alertFont -- Font for Alerts

-- Create Alert Frame - basic setup for now
function CI.CreateAlertFrame()

    CI.ApplyFontAlert()

    -- Create Top Level Controls
    uiTlw.alertFrame = UI.TopLevel( nil, nil )

    -- Create 3 alert labels
    local anchor = { CENTER, CENTER, 0, 0, uiTlw.alertFrame }
    local height = (CI.SV.AlertFontSize * 2)
    for i = 1, 3 do
        local alert = UI.Control( uiTlw.alertFrame, anchor, { nil, height }, false, "LUIE_Alert" .. i )

        alert.data = {
            ["available"] = true,
            ["textName"] = "TEST NAME",
            ["textMitigation"] = "TEST MITIGATION MESSAGE",
            ["duration"] = 0,
            ["showDuration"] = false,
            ["ccType"] = nil,
        }

        alert.name = UI.Label( alert, nil, nil, nil, g_alertFont, alert.data.textName, false )
        alert.name:SetAnchor(LEFT, alert, LEFT, 0, 0 )

        alert.icon = UI.Backdrop( alert.name, nil, nil, {0,0,0,0.5}, {0,0,0,1}, false )
        alert.icon:SetDimensions(40, 40)
        alert.icon:SetAnchor(LEFT, alert.name, RIGHT, 6, 0 )

        alert.icon.back = UI.Texture( alert.icon, nil, nil, "/esoui/art/actionbar/abilityframe64_up.dds", nil, false )
        alert.icon.back:SetAnchor(TOPLEFT, alert.icon, TOPLEFT)
        alert.icon.back:SetAnchor(BOTTOMRIGHT, alert.icon, BOTTOMRIGHT)

        alert.icon.iconbg = UI.Texture( alert.icon, nil, nil, "/esoui/art/actionbar/abilityinset.dds", DL_CONTROLS, false )
        alert.icon.iconbg = UI.Backdrop( alert.icon, nil, nil, {0,0,0,0.9}, {0,0,0,0.9}, false )
        alert.icon.iconbg:SetDrawLevel(DL_CONTROLS)
        alert.icon.iconbg:SetAnchor( TOPLEFT, alert.icon, TOPLEFT, 3, 3)
        alert.icon.iconbg:SetAnchor( BOTTOMRIGHT, alert.icon, BOTTOMRIGHT, -3, -3)

        alert.icon.cd = windowManager:CreateControl(nil, alert.icon, CT_COOLDOWN)
        alert.icon.cd:SetAnchor( TOPLEFT, alert.icon, TOPLEFT, 1, 1 )
        alert.icon.cd:SetAnchor( BOTTOMRIGHT, alert.icon, BOTTOMRIGHT, -1, -1 )
        alert.icon.cd:SetFillColor( 0,1,0,1 )
        alert.icon.cd:StartCooldown(0, 0, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, false )
        alert.icon.cd:SetDrawLayer(DL_BACKGROUND)

        alert.icon.icon = UI.Texture( alert.icon, nil, nil, "/esoui/art/icons/icon_missing.dds", DL_CONTROLS, false )
        alert.icon.icon:SetAnchor( TOPLEFT, alert.icon, TOPLEFT, 3, 3 )
        alert.icon.icon:SetAnchor( BOTTOMRIGHT, alert.icon, BOTTOMRIGHT, -3, -3 )

        alert.mitigation = UI.Label( alert.icon, nil, nil, nil, g_alertFont, alert.data.textMitigation, false )
        alert.mitigation:SetAnchor(LEFT, alert.icon, RIGHT, 6, 0 )

        alert:SetDimensions(alert.name:GetTextWidth() + 6 + alert.icon:GetWidth() + 6 + alert.mitigation:GetTextWidth(), height )
        alert:SetHidden(false)
        alert.icon:SetHidden(false)

        anchor = { TOP, BOTTOM, 0, 0, alert }

    end

    uiTlw.alertFrame:SetDimensions(500, height * 3)

    -- Setup Preview
    uiTlw.alertFrame.preview = LUIE.UI.Backdrop( uiTlw.alertFrame, "fill", nil, nil, nil, true )
    uiTlw.alertFrame.previewLabel = UI.Label( uiTlw.alertFrame.preview, {CENTER,CENTER}, nil, nil, "ZoFontGameMedium", "Alerts Frame", false )

    -- Callback used to hide anchor coords preview label on movement start
    local tlwOnMoveStart = function(self)
        eventManager:RegisterForUpdate( moduleName .. "previewMoveAlert", 200, function()
            self.preview.anchorLabel:SetText(strformat("<<1>>, <<2>>", self:GetLeft(), self:GetTop()))
        end)
    end
    -- Callback used to save new position of frames
    local tlwOnMoveStop = function(self)
        eventManager:UnregisterForUpdate( moduleName .. "previewMoveAlert" )
        CI.SV.AlertFrameOffsetX = self:GetLeft()
        CI.SV.AlertFrameOffsetY = self:GetTop()
        CI.SV.AlertFrameCustomPosition = { self:GetLeft(), self:GetTop() }
    end

    uiTlw.alertFrame.preview.anchorTexture = UI.Texture( uiTlw.alertFrame.preview, {TOPLEFT,TOPLEFT}, {16,16}, "/esoui/art/reticle/border_topleft.dds", DL_OVERLAY, false )
    uiTlw.alertFrame.preview.anchorTexture:SetColor(1, 1, 0, 0.9)

    uiTlw.alertFrame.preview.anchorLabel = UI.Label( uiTlw.alertFrame.preview, {BOTTOMLEFT,TOPLEFT,0,-1}, nil, {0,2}, "ZoFontGameSmall", "xxx, yyy", false )
    uiTlw.alertFrame.preview.anchorLabel:SetColor(1, 1, 0 , 1)
    uiTlw.alertFrame.preview.anchorLabel:SetDrawLayer(DL_OVERLAY)
    uiTlw.alertFrame.preview.anchorLabel:SetDrawTier(1)
    uiTlw.alertFrame.preview.anchorLabelBg = UI.Backdrop(  uiTlw.alertFrame.preview.anchorLabel, "fill", nil, {0,0,0,1}, {0,0,0,1}, false )
    uiTlw.alertFrame.preview.anchorLabelBg:SetDrawLayer(DL_OVERLAY)
    uiTlw.alertFrame.preview.anchorLabelBg:SetDrawTier(0)

    uiTlw.alertFrame:SetHandler( "OnMoveStart", tlwOnMoveStart )
    uiTlw.alertFrame:SetHandler( "OnMoveStop", tlwOnMoveStop )

    local fragment = ZO_HUDFadeSceneFragment:New(uiTlw.alertFrame, 0, 0)

    sceneManager:GetScene("hud"):AddFragment( fragment )
    sceneManager:GetScene("hudui"):AddFragment( fragment )
    sceneManager:GetScene("siegeBar"):AddFragment( fragment )
    sceneManager:GetScene("siegeBarUI"):AddFragment( fragment )

    -- Register Events
    eventManager:RegisterForEvent(moduleName, EVENT_PLAYER_ACTIVATED, CI.OnPlayerActivated)
    eventManager:RegisterForEvent(moduleName, EVENT_COMBAT_EVENT, CI.OnCombatIn)
    eventManager:AddFilterForEvent(moduleName .. "Combat", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    eventManager:RegisterForEvent(moduleName, EVENT_EFFECT_CHANGED, CI.EffectChanged)

    for abilityId, data in pairs (AlertT) do
        if data.eventdetect == true then
            eventManager:RegisterForEvent(moduleName .. abilityId, EVENT_COMBAT_EVENT, CI.OnCombatAlert)
            eventManager:AddFilterForEvent(moduleName .. abilityId, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, abilityId, REGISTER_FILTER_IS_ERROR, false)
        end
    end

    eventManager:RegisterForUpdate(moduleName.."CI_ALERT_UPDATE", 100, CI.AlertUpdate )

end

function CI.ResetAlertFramePosition()
    if not CI.Enabled then
        return
    end
    CI.SV.AlertFrameOffsetX = nil
    CI.SV.AlertFrameOffsetY = nil
    CI.SV.AlertFrameCustomPosition = nil
    CI.SetAlertFramePosition()
end

function CI.SetAlertFramePosition()
    if uiTlw.alertFrame and uiTlw.alertFrame:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.alertFrame:ClearAnchors()

        if CI.SV.AlertFrameOffsetX ~= nil and CI.SV.AlertFrameOffsetY ~= nil then
            uiTlw.alertFrame:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, CI.SV.AlertFrameOffsetX, CI.SV.AlertFrameOffsetY )
        else
            uiTlw.alertFrame:SetAnchor( CENTER, GuiRoot, CENTER, 0, -250 )
        end
    end

    local savedPos = CI.SV.AlertFrameCustomPosition
    uiTlw.alertFrame.preview.anchorLabel:SetText( ( savedPos ~= nil and #savedPos == 2 ) and strformat("<<1>>, <<2>>", savedPos[1], savedPos[2]) or "default" )
end

function CI.SetMovingStateAlert(state)
    if not CI.Enabled then
        return
    end
    CI.AlertFrameUnlocked = state
    if uiTlw.alertFrame and uiTlw.alertFrame:GetType() == CT_TOPLEVELCONTROL then
        CI.GenerateAlertFramePreview(state)
        uiTlw.alertFrame:SetMouseEnabled( state )
        uiTlw.alertFrame:SetMovable( state )
    end
end

-- Called by CI.SetMovingState from the menu as well as by CI.OnUpdateCastbar when preview is enabled
function CI.GenerateAlertFramePreview(state)
    -- TODO: ITERATE HERE AND ADD TEST ALERTS
    --[[local previewIcon = 'esoui/art/icons/icon_missing.dds'
    castbar.icon:SetTexture(previewIcon)
    if CI.SV.CastBarLabel then
        local previewName = "Test"
        castbar.bar.name:SetText(previewName)
        castbar.bar.name:SetHidden( not state )
    end
    if CI.SV.CastBarTimer then
        castbar.bar.timer:SetText( strfmt("1.0") )
        castbar.bar.timer:SetHidden ( not state )
    end
    castbar.bar.bar:SetValue( 1 )]]--

    uiTlw.alertFrame.preview:SetHidden( not state )
    uiTlw.alertFrame:SetHidden( not state )
end

-- Update ticker for Alerts
function CI.AlertUpdate()
    for i = 1, 3 do
        if _G["LUIE_Alert" .. i].data.duration then

            --[[
            if i > 1 and _G["LUIE_Alert" .. i - 1].data.available == true then
                _G["LUIE_Alert" .. i - 1].data.duration = _G["LUIE_Alert" .. i].data.duration
                _G["LUIE_Alert" .. i - 1].data.showDuration = _G["LUIE_Alert" .. i].data.showDuration
                _G["LUIE_Alert" .. i - 1].data.textMitigation = _G["LUIE_Alert" .. i].data.textMitigation
                _G["LUIE_Alert" .. i - 1].data.available = false
                _G["LUIE_Alert" .. i - 1]:SetHidden(false)
                _G["LUIE_Alert" .. i].data.available = true
                _G["LUIE_Alert" .. i]:SetHidden(true)
                _G["LUIE_Alert" .. i].data.textMitigation = nil
                _G["LUIE_Alert" .. i].data.duration = nil
                _G["LUIE_Alert" .. i].data.showDuration = nil
                i = i - 1
            end
            ]]--

            _G["LUIE_Alert" .. i].data.duration = _G["LUIE_Alert" .. i].data.duration - 100
            if _G["LUIE_Alert" .. i].data.showDuration then
                _G["LUIE_Alert" .. i].mitigation:SetText(_G["LUIE_Alert" .. i].data.textMitigation .. " " .. strfmt("%.1f", _G["LUIE_Alert" .. i].data.duration/1000) )
            end
            if _G["LUIE_Alert" .. i].data.duration <= 0 then
                _G["LUIE_Alert" .. i]:SetHidden(true)
                _G["LUIE_Alert" .. i].data.textMitigation = nil
                _G["LUIE_Alert" .. i].data.duration = nil
                _G["LUIE_Alert" .. i].data.available = true
            end
        end
    end
end

local drawLocation = 1

function CI.SetupSingleAlertFrame(textName, textMitigation, abilityIcon, duration, showDuration)
    for i = 1, 3 do
        if _G["LUIE_Alert" .. i].data.available then
            _G["LUIE_Alert" .. i].data.textMitigation =  textMitigation
            _G["LUIE_Alert" .. i].data.textName =  textName
            _G["LUIE_Alert" .. i].icon.icon:SetTexture(abilityIcon)
            _G["LUIE_Alert" .. i].data.duration = duration
            _G["LUIE_Alert" .. i].data.showDuration = showDuration
            _G["LUIE_Alert" .. i].name:SetText(textName)
            _G["LUIE_Alert" .. i].mitigation:SetText(showDuration and (textMitigation .. " " .. strfmt("%.1f", duration/1000)) or textMitigation)
            _G["LUIE_Alert" .. i]:SetHidden(false)
            _G["LUIE_Alert" .. i].data.available = false
            drawLocation = 1 -- As long as this text is filling an available spot, we reset the draw over location to slot 1. If all slots are filled then the draw over code below will cycle and handle abilities.
            return
        end
    end
    -- If no alert frame is available, then draw over in the first spot
    _G["LUIE_Alert" .. drawLocation].data.textMitigation = textMitigation
    _G["LUIE_Alert" .. drawLocation].data.textName = textName
    _G["LUIE_Alert" .. drawLocation].icon.icon:SetTexture(abilityIcon)
    _G["LUIE_Alert" .. drawLocation].data.duration = duration
    _G["LUIE_Alert" .. drawLocation].data.showDuration = showDuration
    _G["LUIE_Alert" .. drawLocation].name:SetText(textName)
    _G["LUIE_Alert" .. drawLocation].mitigation:SetText(showDuration and (textMitigation .. " " .. strfmt("%.1f", duration/1000)) or textMitigation)
    _G["LUIE_Alert" .. drawLocation]:SetHidden(false)
    _G["LUIE_Alert" .. drawLocation].data.available = false
    drawLocation = drawLocation +1
    if drawLocation > 3 then
        drawLocation = 1
    end
end

function CI.RealignAlerts()
    local height = (CI.SV.AlertFontSize * 2)
    for i = 1, 3 do
        alert = _G["LUIE_Alert" .. i]
        alert:SetDimensions(alert.name:GetTextWidth() + 6 + alert.icon:GetWidth() + 6 + alert.mitigation:GetTextWidth(), height )
    end
end

function CI.ProcessAlert(abilityId, unitName)
    local S = LUIE.CombatText.SV

    -- Just in case
    if not AlertT[abilityId] then return end
    -- Ignore this event if we are on refire delay (whether from delay input in the table or from a "bad" event processing)
    if refireDelay[abilityId] then return end

    -- Setup refire delay
    if AlertT[abilityId].refire then
        refireDelay[abilityId] = true
        callLater(function() refireDelay[abilityId] = nil end, AlertT[abilityId].refire) --buffer by X time
    end

    -- Auto refire for auras to stop events when both reticleover and the unit exist
    if AlertT[abilityId].auradetect then
        refireDelay[abilityId] = true
        callLater(function() refireDelay[abilityId] = nil end, 250) --buffer by X time
    end

    -- Get Ability Name & Icon
    local abilityName = GetAbilityName(abilityId)
    local abilityIcon = GetAbilityIcon(abilityId)
    unitName = zo_strformat("<<t:1>>", unitName)

    -- Handle effects that override by UnitName
    if E.EffectOverrideByName[abilityId] then
        if E.EffectOverrideByName[abilityId][unitName] then
            if E.EffectOverrideByName[abilityId][unitName].icon then
                abilityIcon = E.EffectOverrideByName[abilityId][unitName].icon
            end
            if E.EffectOverrideByName[abilityId][unitName].name then
                abilityName = E.EffectOverrideByName[abilityId][unitName].name
            end
        end
    end

    -- Handle effects that override by ZoneId
    if E.MapDataOverride[abilityId] then
        local index = GetCurrentMapZoneIndex()
        if E.MapDataOverride[abilityId][index] then
            if E.MapDataOverride[abilityId][index].name then
                abilityName = E.MapDataOverride[abilityId][index].name
            end
            if E.MapDataOverride[abilityId][index].icon then
                abilityIcon = E.MapDataOverride[abilityId][index].icon
            end
        end
    end

    -- Override unitName here if we utilize a fakeName / bossName
    unitName = zo_strformat("<<t:1>>", unitName)

    if AlertT[abilityId].fakeName then
        unitName = AlertT[abilityId].fakeName
    end
    if AlertT[abilityId].bossName and DoesUnitExist('boss1') then
        unitName = zo_strformat("<<t:1>>", GetUnitName('boss1'))
    end

    if AlertT[abilityId].bossMatch then
        for i = 1, 4 do
            local bossName = DoesUnitExist('boss' .. i) and zo_strformat("<<t:1>>", GetUnitName('boss' .. i)) or ""
            if bossName == AlertT[abilityId].bossMatch then
                unitName = AlertT[abilityId].bossMatch
            end
        end
    end

    local isDirect
    local block
    local blockstagger
    local dodge
    local avoid
    local interrupt
    local power
    local destroy
    local summon
    local unmit
    local duration

    if AlertT[abilityId].notDirect then
        isDirect = false
    else
        isDirect = true
    end

    if (S.toggles.showAlertMitigate) == true then
        if AlertT[abilityId].block == true then
            if AlertT[abilityId].bs then
                blockstagger = true
            else
                block = true
            end
        end
        if AlertT[abilityId].dodge == true then
            dodge = true
        end
        if AlertT[abilityId].avoid == true then
            avoid = true
        end
        if AlertT[abilityId].interrupt == true then
            interrupt = true
        end
    end

    if AlertT[abilityId].unmit and (S.toggles.showAlertUnmit) == true then
        unmit = true
    end
    if AlertT[abilityId].power and (S.toggles.showAlertPower) == true then
        power = true
    end
    if AlertT[abilityId].destroy and (S.toggles.showAlertDestroy) == true then
        destroy = true
    end
    if AlertT[abilityId].summon and (S.toggles.showAlertSummon) == true then
        summon = true
    end
    if AlertT[abilityId].duration then
        duration = AlertT[abilityId].duration
    end

    if not (power == true or destroy == true or summon == true or unmit == true) then
        CI.OnEvent(C.alertType.SHARED, abilityName, abilityIcon, unitName, isDirect, duration, block, blockstagger, dodge, avoid, interrupt)
    end
end

function CI.EffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, castByPlayer)
    local S, combatType, togglesInOut = LUIE.CombatText.SV, nil, nil

    if S.toggles.showAlertMitigation and (S.toggles.mitigationAura or IsUnitInDungeon("player") ) and AlertT[abilityId] and AlertT[abilityId].auradetect then

        if changeType == EFFECT_RESULT_FADED then return end

        -- Don't duplicate events if unitTag is player and in a group.
        if GetGroupSize() > 1 and unitTag == 'player' then return end
        if AlertT[abilityId].noSelf and unitName == LUIE.PlayerNameRaw then return end

        if changeType == EFFECT_RESULT_UPDATED and AlertT[abilityId].ignoreRefresh then return end

        callLater(function() CI.ProcessAlert(abilityId, unitName) end, 50)

    end
end

function CI.OnCombatIn(eventCode, resultType, isError, abilityName, abilityGraphic, abilityAction_slotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    local S = LUIE.CombatText.SV
    local combatType, togglesInOut = C.combatType.INCOMING, S.toggles.incoming
    abilityName = zo_strformat("<<C:1>>", GetAbilityName(abilityId))
    local abilityIcon = GetAbilityIcon(abilityId)

    -- TODO: Fix this so we only process this information once when also sending to the alert printer.

    local sourceNameCheck = zo_strformat("<<t:1>>", sourceName)

    -- Handle effects that override by UnitName
    if E.EffectOverrideByName[abilityId] then
        if E.EffectOverrideByName[abilityId][sourceNameCheck] then
            if E.EffectOverrideByName[abilityId][sourceNameCheck].icon then
                abilityIcon = E.EffectOverrideByName[abilityId][sourceNameCheck].icon
            end
            if E.EffectOverrideByName[abilityId][sourceNameCheck].name then
                abilityName = E.EffectOverrideByName[abilityId][sourceNameCheck].name
            end
        end
    end

    -- Handle effects that override by ZoneId
    if E.MapDataOverride[abilityId] then
        local index = GetCurrentMapZoneIndex()
        if E.MapDataOverride[abilityId][index] then
            if E.MapDataOverride[abilityId][index].name then
                abilityName = E.MapDataOverride[abilityId][index].name
            end
            if E.MapDataOverride[abilityId][index].icon then
                abilityIcon = E.MapDataOverride[abilityId][index].icon
            end
        end
    end

    -- NEW ALERTS
    if S.toggles.showAlertMitigation and AlertT[abilityId] then
        if sourceName ~= nil and sourceName ~= "" then

            -- Return if any results occur which we absolutely don't want to display alerts for & stop spam when enemy is out of line of sight, etc and trying to cast
            if resultType == ACTION_RESULT_EFFECT_FADED
               or resultType == ACTION_RESULT_ABILITY_ON_COOLDOWN
               or resultType == ACTION_RESULT_BAD_TARGET
               or resultType == ACTION_RESULT_BUSY
               or resultType == ACTION_RESULT_FAILED
               or resultType == ACTION_RESULT_INVALID
               or resultType == ACTION_RESULT_CANT_SEE_TARGET
               or resultType == ACTION_RESULT_TARGET_DEAD
               or resultType == ACTION_RESULT_TARGET_OUT_OF_RANGE
               or resultType == ACTION_RESULT_TARGET_TOO_CLOSE
               or resultType == ACTION_RESULT_TARGET_NOT_IN_VIEW
            then
                refireDelay[abilityId] = true
                callLater(function() refireDelay[abilityId] = nil end, 1000) --buffer by X time
                return
            end

            -- Filter when only a certain event type should fire this
            if AlertT[abilityId].result and resultType ~= AlertT[abilityId].result then return end
            if AlertT[abilityId].eventdetect or AlertT[abilityId].auradetect then return end -- Don't create a duplicate warning if event/aura detection already handles this.
            if AlertT[abilityId].noSelf and targetName == LUIE.PlayerNameRaw then return end -- Don't create alert for self in cases where this is true.

            if AlertT[abilityId].block or AlertT[abilityId].dodge or AlertT[abilityId].avoid or AlertT[abilityId].interrupt or AlertT[abilityId].unmit or AlertT[abilityId].power or AlertT[abilityId].destroy or AlertT[abilityId].summon then

                -- Filter by priority
                if (S.toggles.mitigationDungeon and not IsUnitInDungeon("player")) or not S.toggles.mitigationDungeon then
                    if AlertT[abilityId].priority == 3 and not S.toggles.mitigationRank3 then return end
                    if AlertT[abilityId].priority == 2 and not S.toggles.mitigationRank2 then return end
                    if AlertT[abilityId].priority == 1 and not S.toggles.mitigationRank1 then return end
                end

                callLater(function() CI.ProcessAlert(abilityId, sourceName) end, 50)

            end

        end

    end
end

function CI.OnCombatAlert(eventCode, resultType, isError, abilityName, abilityGraphic, abilityAction_slotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    local S = LUIE.CombatText.SV
    local combatType, togglesInOut = C.combatType.INCOMING, S.toggles.incoming

    -- NEW ALERTS
    if S.toggles.showAlertMitigation and (S.toggles.mitigationAura or IsUnitInDungeon("player") ) then
        if not refireDelay[abilityId] then

            -- Return if any results occur which we absolutely don't want to display alerts for & stop spam when enemy is out of line of sight, etc and trying to cast
            if resultType == ACTION_RESULT_EFFECT_FADED
               or resultType == ACTION_RESULT_ABILITY_ON_COOLDOWN
               or resultType == ACTION_RESULT_BAD_TARGET
               or resultType == ACTION_RESULT_BUSY
               or resultType == ACTION_RESULT_FAILED
               or resultType == ACTION_RESULT_INVALID
               or resultType == ACTION_RESULT_CANT_SEE_TARGET
               or resultType == ACTION_RESULT_TARGET_DEAD
               or resultType == ACTION_RESULT_TARGET_OUT_OF_RANGE
               or resultType == ACTION_RESULT_TARGET_TOO_CLOSE
               or resultType == ACTION_RESULT_TARGET_NOT_IN_VIEW
            then
                refireDelay[abilityId] = true
                callLater(function() refireDelay[abilityId] = nil end, 1000) --buffer by X time
                return
            end

            -- Filter when only a certain event type should fire this
            if AlertT[abilityId].result and resultType ~= AlertT[abilityId].result then return end
            if AlertT[abilityId].auradetect then return end -- Don't create a duplicate warning if aura detection already handles this.
            if AlertT[abilityId].noSelf and targetName == LUIE.PlayerNameRaw then return end -- Don't create alert for self in cases where this is true.


            if AlertT[abilityId].block or AlertT[abilityId].dodge or AlertT[abilityId].avoid or AlertT[abilityId].interrupt or AlertT[abilityId].unmit or AlertT[abilityId].power or AlertT[abilityId].destroy or AlertT[abilityId].summon then
                -- Filter by priority
                if (S.toggles.mitigationDungeon and not IsUnitInDungeon("player")) or not S.toggles.mitigationDungeon then
                    if AlertT[abilityId].priority == 3 and not S.toggles.mitigationRank3 then return end
                    if AlertT[abilityId].priority == 2 and not S.toggles.mitigationRank2 then return end
                    if AlertT[abilityId].priority == 1 and not S.toggles.mitigationRank1 then return end
                end

                callLater(function() CI.ProcessAlert(abilityId, sourceName) end, 50)

            end
        end
    end
end

function CI.FormatAlertString(inputFormat, params)
    return string.gsub(inputFormat, '%%.', function(x)
        if (x == '%n') then
            return params.source or ''
        elseif (x == '%t') then
            return params.ability or ''
        else
            return x
        end
    end)
end

-- VIEWER
function CI.OnEvent(alertType, abilityName, abilityIcon, sourceName, isDirect, duration, block, blockstagger, dodge, avoid, interrupt)
    local S = LUIE.CombatText.SV

    local size, text
    local labelColor = S.colors.alertShared
	local prefix = (sourceName ~= "" and sourceName ~= nil and sourceName ~= "Offline") and S.toggles.mitigationPrefixN or S.toggles.mitigationPrefix
    local mitigationSuffix = (isDirect and S.toggles.mitigationDefaultSuffix ~= "") and zo_strformat(" <<1>>", S.toggles.mitigationDefaultSuffix) or ""

    -- First we handle Exploit because these messages are always individual
    if (alertType == alertTypes.EXPLOIT) then
        labelColor = S.colors.alertExploit
        size = S.fontSizes.alert
        text = S.formats.alertExploit
    elseif (alertType == alertTypes.SHARED) then

        size = S.fontSizes.alert

        local spacer = "-"
        local stringBlock
        local stringDodge
        local stringAvoid
        local stringInterrupt
        local color = CT.AlertColors.alertColorBlock

        -- Quickly set only one of these to true for priority color formatting.
        -- PRIORITY: INTERRUPT > BLOCK STAGGER > DODGE > BLOCK > AVOID
        if blockstagger then block = false end

		if not S.toggles.hideMitigation then
			if avoid then
				local color = CT.AlertColors.alertColorAvoid
				stringAvoid = zo_strformat("|c<<1>><<2>>|r <<3>> ", color, S.formats.alertAvoid, spacer)
			else
				stringAvoid = ""
			end

			if block then
				local color = CT.AlertColors.alertColorBlock
				stringBlock = zo_strformat("|c<<1>><<2>>|r <<3>> ", color, S.formats.alertBlock, spacer)
			end

			if dodge then
				local color = CT.AlertColors.alertColorDodge
				stringDodge = zo_strformat("|c<<1>><<2>>|r <<3>> ", color, S.formats.alertDodge, spacer)
			else
				stringDodge = ""
			end

			if blockstagger then
				local color = CT.AlertColors.alertColorBlock
				stringBlock = zo_strformat("|c<<1>><<2>>|r <<3>> ", color, S.formats.alertBlockStagger, spacer)
			end

			if interrupt then
				local color = CT.AlertColors.alertColorInterrupt
				stringInterrupt = zo_strformat("|c<<1>><<2>>|r <<3>> ", color, S.formats.alertInterrupt, spacer)
			else
				stringInterrupt = ""
			end

			if not block and not blockstagger then
				stringBlock = ""
			end
		end

        textName = zo_strformat("|cffffff<<1>>|r", CI.FormatAlertString(prefix, { source = sourceName, ability = abilityName }))
        textMitigation = S.toggles.hideMitigation and "" or zo_strformat(" <<1>> <<2>><<3>><<4>><<5>>", spacer, stringBlock, stringDodge, stringAvoid, stringInterrupt)

        text = zo_strformat("<<1>><<2>><<3>>", stringPart1, stringPart2, stringPart3)
	-- UNMIT
	elseif (alertType == alertTypes.UNMIT) then
		local color = CT.AlertColors.alertColorUnmit
		size = S.fontSizes.alert
		textName = CI.FormatAlertString(prefix, { source = sourceName, ability = abilityName })
        textMitigation = zo_strformat("|c<<1>><<2>>|r", color, S.formats.alertUnmit)
		text = zo_strformat("<<1>><<2>> - <<3>> - ", stringPart1, stringPart2, stringPart3)
    -- POWER
    elseif (alertType == alertTypes.POWER) then
        local color = CT.AlertColors.alertColorPower
		prefix = (sourceName ~= "" and sourceName ~= nil and sourceName ~= "Offline") and S.toggles.mitigationPowerPrefixN or S.toggles.mitigationPowerPrefix
        size = S.fontSizes.alert
        textName = CI.FormatAlertString(prefix, { source = sourceName, ability = abilityName })
        textMitigation = zo_strformat("|c<<1>><<2>>|r", color, S.formats.alertPower)
        text = zo_strformat("<<1>> <<2>>", stringPart1, stringPart2)
    -- DESTROY
    elseif (alertType == alertTypes.DESTROY) then
        local color = CT.AlertColors.alertColorDestroy
		prefix = (sourceName ~= "" and sourceName ~= nil and sourceName ~= "Offline") and S.toggles.mitigationDestroyPrefixN or S.toggles.mitigationDestroyPrefix
        size = S.fontSizes.alert
        textName = CI.FormatAlertString(prefix, { source = sourceName, ability = abilityName })
        textMitigation = zo_strformat("|c<<1>><<2>>|r", color, S.formats.alertDestroy)
        text = zo_strformat("<<1>> <<2>>", stringPart1, stringPart2)
    -- SUMMON
    elseif (alertType == alertTypes.SUMMON) then
        local color = CT.AlertColors.alertColorSummon
		prefix = (sourceName ~= "" and sourceName ~= nil and sourceName ~= "Offline") and S.toggles.mitigationSummonPrefixN or S.toggles.mitigationSummonPrefix
        size = S.fontSizes.alert
        textName = CI.FormatAlertString(prefix, { source = sourceName, ability = abilityName })
        textMitigation = zo_strformat("|c<<1>><<2>>|r", color, S.formats.alertSummon)
        text = zo_strformat("<<1>> <<2>>", stringPart1, stringPart2)
    end

    local showDuration = duration and true or false
    if not duration then duration = 4000 end

    CI.SetupSingleAlertFrame(textName, textMitigation, abilityIcon, duration, showDuration, ccType)
    CI.RealignAlerts()

end

-- Updates local variables with new font
function CI.ApplyFontAlert()
    if not CI.Enabled then
        return
    end

    -- Setup Alerts Font
    local alertFontName = LUIE.Fonts[CI.SV.AlertFontFace]
    if not alertFontName or alertFontName == "" then
        printToChat(GetString(SI_LUIE_ERROR_FONT), true)
        alertFontName = "$(MEDIUM_FONT)"
    end

    local alertFontStyle = ( CI.SV.AlertFontStyle and CI.SV.AlertFontStyle ~= "" ) and CI.SV.AlertFontStyle or "soft-shadow-thin"
    local alertFontSize = ( CI.SV.AlertFontSize and CI.SV.AlertFontSize > 0 ) and CI.SV.AlertFontSize or 16

    g_alertFont = alertFontName .. "|" .. alertFontSize .. "|" .. alertFontStyle
end
