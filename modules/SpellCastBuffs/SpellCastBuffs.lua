--[[
    LuiExtended
    License: The MIT License (MIT)
--]]

-- SpellCastBuffs namespace
LUIE.SpellCastBuffs = {}
local SpellCastBuffs = LUIE.SpellCastBuffs

local UI = LUIE.UI
local Effects = LUIE.Data.Effects
local Abilities = LUIE.Data.Abilities
local Tooltips = LUIE.Data.Tooltips

local printToChat = LUIE.PrintToChat
local zo_strformat = zo_strformat

local eventManager = EVENT_MANAGER
local sceneManager = SCENE_MANAGER
local windowManager = WINDOW_MANAGER

local moduleName = LUIE.name .. "SpellCastBuffs"

local hidePlayerEffects = { } -- Table of Effects to hide on Player - generated on load or updated from Menu
local hideTargetEffects = { } -- Table of Effects to hide on Target - generated on load or updated from Menu
local debuffDisplayOverrideId = { } -- Table of Effects (by id) that should show on the target regardless of who applied them.

local windowTitles = {
    playerb             = GetString(SI_LUIE_SCB_WINDOWTITLE_PLAYERBUFFS),
    playerd             = GetString(SI_LUIE_SCB_WINDOWTITLE_PLAYERDEBUFFS),
    player1             = GetString(SI_LUIE_SCB_WINDOWTITLE_PLAYERBUFFS),
    player2             = GetString(SI_LUIE_SCB_WINDOWTITLE_PLAYERDEBUFFS),
    player_long         = GetString(SI_LUIE_SCB_WINDOWTITLE_PLAYERLONGTERMEFFECTS),
    targetb             = GetString(SI_LUIE_SCB_WINDOWTITLE_TARGETBUFFS),
    targetd             = GetString(SI_LUIE_SCB_WINDOWTITLE_TARGETDEBUFFS),
    target1             = GetString(SI_LUIE_SCB_WINDOWTITLE_TARGETBUFFS),
    target2             = GetString(SI_LUIE_SCB_WINDOWTITLE_TARGETDEBUFFS),
    prominentbuffs      = GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTBUFFS),
    prominentdebuffs    = GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTDEBUFFS),
}

SpellCastBuffs.Enabled = false
SpellCastBuffs.Defaults = {
    ColorCosmetic                       = true,
    ColorUnbreakable                    = true,
    ColorCC                             = false,
    colors = {
        buff                            = { 0, 1, 0, 1 }, -- gren
        debuff                          = { 1, 0, 0, 1 }, -- red
        prioritybuff                    = { 1, 1, 0, 1 }, -- yellow
        prioritydebuff                  = { 1, 1, 0, 1 }, -- yellow
        unbreakable                     = { 0.88, 0.88, 1, 1 }, -- light grey
        cosmetic                        = { 0, .5, 0, 1 }, -- dark green
        nocc                            = { 0, 0, 0, 1 }, -- black
        stun                            = { 1, 0, 0, 1 }, -- red
        knockback                       = { 1, 0, 0, 1 }, -- red
        levitate                        = { 0, 0, 1, 1 }, -- dark blue
        disorient                       = { 0, 0.3137, 1, 1 }, -- blue
        fear                            = { 0.5607843137, 0.0352941176, 0.9254901961, 1 }, -- purple
        stagger                         = { 1, 0.9490196109, 0.1294117719, 1 }, -- yellow
        silence                         = { 0, 1, 1, 1 }, -- cyan
        snare                           = { 1, .6470, 0, 1 }, -- orange
        root                            = { 1, .6470, 0, 1 }, -- orange
    },
    IconSize                            = 40,
    LabelPosition                       = 0,
    BuffFontFace                        = "Fontin Regular",
    BuffFontStyle                       = "outline",
    BuffFontSize                        = 16,
    BuffShowLabel                       = true,
    AlignmentBuffsPlayer                = "Centered",
    SortBuffsPlayer                     = "Left to Right",
    AlignmentDebuffsPlayer              = "Centered",
    SortDebuffsPlayer                   = "Left to Right",
    AlignmentBuffsTarget                = "Centered",
    SortBuffsTarget                     = "Left to Right",
    AlignmentDebuffsTarget              = "Centered",
    SortDebuffsTarget                   = "Left to Right",
    AlignmentLongHorz                   = "Centered",
    SortLongHorz                        = "Left to Right",
    AlignmentLongVert                   = "Top",
    SortLongVert                        = "Top to Bottom",
    AlignmentPromBuffsHorz              = "Centered",
    SortPromBuffsHorz                   = "Left to Right",
    AlignmentPromBuffsVert              = "Bottom",
    SortPromBuffsVert                   = "Bottom to Top",
    AlignmentPromDebuffsHorz            = "Centered",
    SortPromDebuffsHorz                 = "Left to Right",
    AlignmentPromDebuffsVert            = "Bottom",
    SortPromDebuffsVert                 = "Bottom to Top",
    GlowIcons                           = false,
    RemainingText                       = true,
    RemainingTextColoured               = false,
    RemainingTextMillis                 = true,
    RemainingCooldown                   = true,
    FadeOutIcons                        = false,
    lockPositionToUnitFrames            = true,
    LongTermEffects_Player              = true,
    LongTermEffects_Target              = true,
    ShortTermEffects_Player             = true,
    ShortTermEffects_Target             = true,
    IgnoreMundusPlayer                  = false,
    IgnoreMundusTarget                  = false,
    IgnoreVampPlayer                    = false,
    IgnoreVampTarget                    = false,
    IgnoreLycanPlayer                   = false,
    IgnoreLycanTarget                   = false,
    IgnoreDiseasePlayer                 = false,
    IgnoreDiseaseTarget                 = false,
    IgnoreBitePlayer                    = false,
    IgnoreBiteTarget                    = false,
    IgnoreCyrodiilPlayer                = false,
    IgnoreCyrodiilTarget                = false,
    IgnoreBattleSpiritPlayer            = false,
    IgnoreBattleSpiritTarget            = false,
    IgnoreEsoPlusPlayer                 = true,
    IgnoreEsoPlusTarget                 = true,
    IgnoreSoulSummonsPlayer             = false,
    IgnoreSoulSummonsTarget             = false,
    IgnoreSetICDPlayer                  = false,
    IgnoreFoodPlayer                    = false,
    IgnoreFoodTarget                    = false,
    IgnoreExperiencePlayer              = false,
    IgnoreExperienceTarget              = false,
    IgnoreAllianceXPPlayer              = false,
    IgnoreAllianceXPTarget              = false,
    IgnoreDisguise                      = false,
    IgnoreCostume                       = true,
    IgnoreHat                           = true,
    IgnoreSkin                          = true,
    IgnorePolymorph                     = true,
    IgnoreAssistant                     = true,
    IgnorePet                           = true,
    PetDetail                           = true,
    IgnoreMountPlayer                   = false,
    IgnoreMountTarget                   = false,
    MountDetail                         = true,
    LongTermEffectsSeparate             = true,
    LongTermEffectsSeparateAlignment    = 2,
    ShowBlockPlayer                     = true,
    ShowBlockTarget                     = true,
    StealthStatePlayer                  = true,
    StealthStateTarget                  = true,
    DisguiseStatePlayer                 = true,
    DisguiseStateTarget                 = true,
    --ShowSprint                          = true,
    --ShowGallop                          = true,
    ShowResurrectionImmunity            = true,
    ShowRecall                          = true,
    ShowWerewolf                        = true,
    HidePlayerBuffs                     = false,
    HidePlayerDebuffs                   = false,
    HideTargetBuffs                     = false,
    HideTargetDebuffs                   = false,
    HideGroundEffects                   = false,
    ExtraBuffs                          = true,
    ExtraExpanded                       = false,
    ShowDebugCombat                     = false,
    ShowDebugEffect                     = false,
    ShowDebugFilter                     = false,
    ShowDebugAbilityId                  = false,
    HideReduce                          = true,
    GroundDamageAura                    = true,
    ProminentLabel                      = true,
    ProminentLabelFontFace              = "Univers 67",
    ProminentLabelFontStyle             = "outline",
    ProminentLabelFontSize              = 16,
    ProminentProgress                   = true,
    ProminentProgressTexture            = "Plain",
    ProminentProgressBuffC1             = { 0, 1, 0 },
    ProminentProgressBuffC2             = { 0, .4, 0 },
    ProminentProgressDebuffC1           = { 1, 0, 0 },
    ProminentProgressDebuffC2           = { .4, 0, 0 },
    ProminentProgressBuffPriorityC1     = { 1, 1, 0 },
    ProminentProgressBuffPriorityC2     = { .6, .6, 0 },
    ProminentProgressDebuffPriorityC1   = { 1, 1, 0 },
    ProminentProgressDebuffPriorityC2   = { .6, .6, 0 },
    ProminentBuffContainerAlignment     = 2,
    ProminentDebuffContainerAlignment   = 2,
    ProminentBuffLabelDirection         = "Left",
    ProminentDebuffLabelDirection       = "Right",
    PriorityBuffTable                   = {},
    PriorityDebuffTable                 = {},
    PromBuffTable                       = {},
    PromDebuffTable                     = {},
    BlacklistTable                      = {},
    TooltipEnable                       = true,
    TooltipSticky                       = 0,
    TooltipAbilityId                    = false,
    TooltipBuffType                     = false,
    GenericMajorMinor                   = false,
    UseDefaultIcon                      = false,
    DefaultIconOptions                  = 1,
    ShowSharedEffects                   = true,
    ShowSharedMajorMinor                = true,
}
SpellCastBuffs.SV = nil

SpellCastBuffs.EffectsList           = { player1 = {}, player2 = {}, reticleover1 = {}, reticleover2 = {}, ground = {}, saved = {}, promb_ground = {}, promb_target = {}, promb_player = {}, promd_ground = {}, promd_target = {}, promd_player = {} } -- Saved Effects

local uiTlw                          = {} -- GUI
local containerRouting               = {} -- Routing for Auras
local g_alignmentDirection           = {} -- Holds alignment direction for all containers
local g_sortDirection                = {} -- Holds sorting direction for all containers

local g_playerActive                 = false -- Player Active State
local g_playerDead                   = false -- Player Dead State
local g_playerResurrectStage         = nil -- Player resurrection sequence state

local g_buffsFont                    -- Buff font
local g_prominentFont                -- Prominent buffs label font
local g_padding                      = 0 -- Padding between icons
local g_protectAbilityRemoval        = {} -- AbilityId's set to a timestamp here to prevent removal of ground effects when refreshing ground auras from causing the aura to fade.
local g_ignoreAbilityId              = {} -- Ignored abilityId's on EVENT_COMBAT_EVENT, some events fire twice and we need to ignore every other one.

-- Add buff containers into LUIE namespace
SpellCastBuffs.BuffContainers = uiTlw

-- Quadratic easing out - decelerating to zero velocity (For buff fade)
local function EaseOutQuad(t, b, c, d)
    t = t / d
    return -c * t*(t-2) + b
end

function SpellCastBuffs.ShouldUseDefaultIcon(abilityId)
    if Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].cc then
        if SpellCastBuffs.SV.DefaultIconOptions == 1 then
            return true
        elseif SpellCastBuffs.SV.DefaultIconOptions == 2 then
            return Effects.EffectOverride[abilityId].isPlayerAbility and false or true
        elseif SpellCastBuffs.SV.DefaultIconOptions == 3 then
            return Effects.EffectOverride[abilityId].isPlayerAbility and true or false
        end
    end
end

function SpellCastBuffs.GetDefaultIcon(ccType)
    if ccType == LUIE_CC_TYPE_STUN then return LUIE_CC_ICON_STUN
    elseif ccType == LUIE_CC_TYPE_KNOCKDOWN then return LUIE_CC_ICON_STUN
    elseif ccType == LUIE_CC_TYPE_KNOCKBACK then return LUIE_CC_ICON_KNOCKBACK
    elseif ccType == LUIE_CC_TYPE_PULL then return LUIE_CC_ICON_PULL
    elseif ccType == LUIE_CC_TYPE_DISORIENT then return LUIE_CC_ICON_DISORIENT
    elseif ccType == LUIE_CC_TYPE_FEAR then return LUIE_CC_ICON_FEAR
    elseif ccType == LUIE_CC_TYPE_STAGGER then return LUIE_CC_ICON_SILENCE
    elseif ccType == LUIE_CC_TYPE_SILENCE then return LUIE_CC_ICON_SILENCE
    elseif ccType == LUIE_CC_TYPE_SNARE then return LUIE_CC_ICON_SNARE
    elseif ccType == LUIE_CC_TYPE_ROOT then return LUIE_CC_ICON_ROOT
    end
end

-- Function for determining container context for prominent effects
function SpellCastBuffs.DetermineContext(context, abilityId, abilityName, castByPlayer)
    if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[abilityName]) then
        if context == "player1" then
            context = "promd_player"
        elseif (context == "reticleover2" and castByPlayer == COMBAT_UNIT_TYPE_PLAYER) then
            context = "promd_target"
        end
    elseif (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[abilityName]) then
        if context == "player1" then
            context = "promb_player"
        elseif (context == "reticleover2" and castByPlayer == COMBAT_UNIT_TYPE_PLAYER) then
            context = "promb_target"
        end
    end
    return context
end

-- Function for determining container context for prominent effects (player only)
-- Used in cases where the effect will never be a debuff cast by the player (disguise/stealth state, collectible buffs, etc)
function SpellCastBuffs.DetermineContextSimple(context, abilityId, abilityName)
    if context == "player1" then
        if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[abilityName]) then
            context = "promd_player"
        elseif (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[abilityName]) then
            context = "promb_player"
        end
    end
    return context
end

-- Function for determining target for buff sorting
function SpellCastBuffs.DetermineTarget(context)
    if context == "player1" or context == "player2" then
        return "player"
    elseif context == "reticleover1" or context == "reticleover2" or context == "ground" or context == "saved" then
        return "reticleover"
    else
        return "prominent"
    end
end

-- Specifically for clearing a player buff, removes this buff from player1, promd_player, and promb_player containers
function SpellCastBuffs.ClearPlayerBuff(abilityId)
    local context = { "player1", "promd_player", "promb_player" }
    for _, v in pairs(context) do
        SpellCastBuffs.EffectsList[v][abilityId] = nil
    end
end

-- Initialization
function SpellCastBuffs.Initialize(enabled)
    -- Load settings
    local isCharacterSpecific = LUIESV.Default[GetDisplayName()]['$AccountWide'].CharacterSpecificSV
    if isCharacterSpecific then
        SpellCastBuffs.SV = ZO_SavedVars:New(LUIE.SVName, LUIE.SVVer, "SpellCastBuffs", SpellCastBuffs.Defaults)
    else
        SpellCastBuffs.SV = ZO_SavedVars:NewAccountWide(LUIE.SVName, LUIE.SVVer, "SpellCastBuffs", SpellCastBuffs.Defaults)
    end

    -- Correct read values
    if SpellCastBuffs.SV.IconSize < 30 or SpellCastBuffs.SV.IconSize > 60 then
        SpellCastBuffs.SV.IconSize = SpellCastBuffs.Defaults.IconSize
    end

    -- Disable module if setting not toggled on
    if not enabled then
        return
    end
    SpellCastBuffs.Enabled = true

    -- Before we start creating controls, update icons font
    SpellCastBuffs.ApplyFont()

    -- Create controls
    -- Create temporary table to store references to scenes locally
    local fragments = { }

    -- We will not create TopLevelWindows when buff frames are locked to Custom Unit Frames
    if SpellCastBuffs.SV.lockPositionToUnitFrames and LUIE.UnitFrames.CustomFrames.player and LUIE.UnitFrames.CustomFrames.player.buffs and LUIE.UnitFrames.CustomFrames.player.debuffs then
        uiTlw.player1 = LUIE.UnitFrames.CustomFrames.player.buffs
        uiTlw.player2 = LUIE.UnitFrames.CustomFrames.player.debuffs
        containerRouting.player1 = "player1"
        containerRouting.player2 = "player2"
    else
        uiTlw.playerb = UI.TopLevel( nil, nil )
        uiTlw.playerb:SetHandler( "OnMoveStop", function(self)
                SpellCastBuffs.SV.playerbOffsetX = self:GetLeft()
                SpellCastBuffs.SV.playerbOffsetY = self:GetTop()
            end )
        uiTlw.playerd = UI.TopLevel( nil, nil )
        uiTlw.playerd:SetHandler( "OnMoveStop", function(self)
                SpellCastBuffs.SV.playerdOffsetX = self:GetLeft()
                SpellCastBuffs.SV.playerdOffsetY = self:GetTop()
            end )
        containerRouting.player1 = "playerb"
        containerRouting.player2 = "playerd"

        local fragment1 = ZO_HUDFadeSceneFragment:New(uiTlw.playerb, 0, 0)
        local fragment2 = ZO_HUDFadeSceneFragment:New(uiTlw.playerd, 0, 0)
        table.insert(fragments, fragment1)
        table.insert(fragments, fragment2)
    end

    -- Create TopLevelWindows for buff frames when NOT locked to Custom Unit Frames
    if SpellCastBuffs.SV.lockPositionToUnitFrames and LUIE.UnitFrames.CustomFrames.reticleover and LUIE.UnitFrames.CustomFrames.reticleover.buffs and LUIE.UnitFrames.CustomFrames.reticleover.debuffs then
        uiTlw.target1 = LUIE.UnitFrames.CustomFrames.reticleover.buffs
        uiTlw.target2 = LUIE.UnitFrames.CustomFrames.reticleover.debuffs
        containerRouting.reticleover1 = "target1"
        containerRouting.reticleover2 = "target2"
        containerRouting.ground = "target2"
    else
        uiTlw.targetb = UI.TopLevel( nil, nil )
        uiTlw.targetb:SetHandler( "OnMoveStop", function(self)
                SpellCastBuffs.SV.targetbOffsetX = self:GetLeft()
                SpellCastBuffs.SV.targetbOffsetY = self:GetTop()
            end )
        uiTlw.targetd = UI.TopLevel( nil, nil )
        uiTlw.targetd:SetHandler( "OnMoveStop", function(self)
                SpellCastBuffs.SV.targetdOffsetX = self:GetLeft()
                SpellCastBuffs.SV.targetdOffsetY = self:GetTop()
            end )
        containerRouting.reticleover1 = "targetb"
        containerRouting.reticleover2 = "targetd"
        containerRouting.ground = "targetd"

        local fragment1 = ZO_HUDFadeSceneFragment:New(uiTlw.targetb, 0, 0)
        local fragment2 = ZO_HUDFadeSceneFragment:New(uiTlw.targetd, 0, 0)
        table.insert(fragments, fragment1)
        table.insert(fragments, fragment2)
    end

    -- Create TopLevelWindows for Prominent Buffs
    uiTlw.prominentbuffs = UI.TopLevel( nil, nil )
    uiTlw.prominentbuffs:SetHandler( "OnMoveStop", function(self)
            if self.alignVertical then
                SpellCastBuffs.SV.prominentbVOffsetX = self:GetLeft()
                SpellCastBuffs.SV.prominentbVOffsetY = self:GetTop()
            else
                SpellCastBuffs.SV.prominentbHOffsetX = self:GetLeft()
                SpellCastBuffs.SV.prominentbHOffsetY = self:GetTop()
            end
        end )
    uiTlw.prominentdebuffs = UI.TopLevel( nil, nil )
    uiTlw.prominentdebuffs:SetHandler( "OnMoveStop", function(self)
            if self.alignVertical then
                SpellCastBuffs.SV.prominentdVOffsetX = self:GetLeft()
                SpellCastBuffs.SV.prominentdVOffsetY = self:GetTop()
            else
                SpellCastBuffs.SV.prominentdHOffsetX = self:GetLeft()
                SpellCastBuffs.SV.prominentdHOffsetY = self:GetTop()
            end
        end )

    if SpellCastBuffs.SV.ProminentBuffContainerAlignment == 1 then
        uiTlw.prominentbuffs.alignVertical = false
    elseif SpellCastBuffs.SV.ProminentBuffContainerAlignment == 2 then
        uiTlw.prominentbuffs.alignVertical = true
    end
    if SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 1 then
        uiTlw.prominentdebuffs.alignVertical = false
    elseif SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 2 then
        uiTlw.prominentdebuffs.alignVertical = true
    end

    containerRouting.promb_ground = "prominentbuffs"
    containerRouting.promb_target = "prominentbuffs"
    containerRouting.promb_player = "prominentbuffs"
    containerRouting.promd_ground = "prominentdebuffs"
    containerRouting.promd_target = "prominentdebuffs"
    containerRouting.promd_player = "prominentdebuffs"

    local fragmentP1 = ZO_HUDFadeSceneFragment:New(uiTlw.prominentbuffs, 0, 0)
    local fragmentP2 = ZO_HUDFadeSceneFragment:New(uiTlw.prominentdebuffs, 0, 0)
    table.insert(fragments, fragmentP1)
    table.insert(fragments, fragmentP2)

    -- Separate container for players long term buffs
    if true then
        uiTlw.player_long = UI.TopLevel( nil, nil )
        uiTlw.player_long:SetHandler( "OnMoveStop", function(self)
                if self.alignVertical then
                    SpellCastBuffs.SV.playerVOffsetX = self:GetLeft()
                    SpellCastBuffs.SV.playerVOffsetY = self:GetTop()
                else
                    SpellCastBuffs.SV.playerHOffsetX = self:GetLeft()
                    SpellCastBuffs.SV.playerHOffsetY = self:GetTop()
                end
            end )

        if SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 1 then
            uiTlw.player_long.alignVertical = false
        elseif SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 2 then
            uiTlw.player_long.alignVertical = true
        end
        uiTlw.player_long.skipUpdate = 0
        containerRouting.player_long = "player_long"

        local fragment = ZO_HUDFadeSceneFragment:New(uiTlw.player_long, 0, 0)
        table.insert(fragments, fragment)
    else
        containerRouting.player_long = containerRouting.player1
    end

    -- Loop over table of fragments to add them to relevant UI Scenes
    for _,v in pairs(fragments) do
        sceneManager:GetScene("hud"):AddFragment( v )
        sceneManager:GetScene("hudui"):AddFragment( v )
        sceneManager:GetScene("siegeBar"):AddFragment( v )
        sceneManager:GetScene("siegeBarUI"):AddFragment( v )
    end

    -- Set Buff Container Positions
    SpellCastBuffs.SetTlwPosition()

    -- Loop over created controls to...
    for _, v in pairs(containerRouting) do
        -- Set Draw Priority
        uiTlw[v]:SetDrawLayer(DL_BACKDROP)
        uiTlw[v]:SetDrawTier(DT_LOW)
        uiTlw[v]:SetDrawLevel(1)
        if uiTlw[v].preview == nil then
            -- Create background areas for preview position purposes
            --uiTlw[v].preview = UI.Backdrop( uiTlw[v], "fill", nil, nil, nil, true )
            uiTlw[v].preview = UI.Texture( uiTlw[v], "fill", nil, "/esoui/art/miscellaneous/inset_bg.dds", DL_BACKGROUND, true )
            uiTlw[v].previewLabel = UI.Label( uiTlw[v].preview, {CENTER,CENTER}, nil, nil, "ZoFontGameMedium", windowTitles[v] .. (SpellCastBuffs.SV.lockPositionToUnitFrames and (v ~= "player_long" and v ~= "prominentbuffs" and v ~= "prominentdebuffs") and " (locked)" or ""), false )

            -- Create control that will hold the icons
            uiTlw[v].prevIconsCount = 0
            -- We need this container only for icons that are aligned in one row/column automatically.
            -- Thus we do not create containers for player and target buffs/debuffs on custom frames
            if v ~= "player1" and v ~= "player2" and v ~= "target1" and v ~= "target2" then
                uiTlw[v].iconHolder = UI.Control( uiTlw[v], nil, nil, false )
            end
            -- Create table to store created contols for icons
            uiTlw[v].icons = {}

            -- add this top level window to global controls list, so it can be hidden
            if uiTlw[v]:GetType() == CT_TOPLEVELCONTROL then LUIE.Components[moduleName .. v] = uiTlw[v] end
        end
    end

    SpellCastBuffs.Reset()
    SpellCastBuffs.UpdateContextHideList()
    SpellCastBuffs.UpdateDisplayOverrideIdList()
    SpellCastBuffs.UpdateMajorMinorList()

    -- Register events
    eventManager:RegisterForUpdate(moduleName, 100, SpellCastBuffs.OnUpdate )

    -- Target Events
    eventManager:RegisterForEvent(moduleName, EVENT_TARGET_CHANGE, SpellCastBuffs.OnTargetChange )
    eventManager:RegisterForEvent(moduleName, EVENT_RETICLE_TARGET_CHANGED, SpellCastBuffs.OnReticleTargetChanged )
    eventManager:RegisterForEvent(moduleName .. "Disposition", EVENT_DISPOSITION_UPDATE, SpellCastBuffs.OnDispositionUpdate )
    eventManager:AddFilterForEvent(moduleName .. "Disposition", EVENT_DISPOSITION_UPDATE, REGISTER_FILTER_UNIT_TAG, "reticleover" )

    -- Buff Events
    eventManager:RegisterForEvent(moduleName .. "Player", EVENT_EFFECT_CHANGED, SpellCastBuffs.OnEffectChanged )
    eventManager:RegisterForEvent(moduleName .. "Target", EVENT_EFFECT_CHANGED, SpellCastBuffs.OnEffectChanged )
    eventManager:AddFilterForEvent(moduleName .. "Player", EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player" )
    eventManager:AddFilterForEvent(moduleName .. "Target", EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover" )

    -- GROUND & MINE EFFECTS - add a filtered event for each AbilityId
    for k, v in pairs(Effects.EffectGroundDisplay) do
        eventManager:RegisterForEvent(moduleName .. "Ground" .. k, EVENT_EFFECT_CHANGED, SpellCastBuffs.OnEffectChangedGround )
        eventManager:AddFilterForEvent(moduleName .. "Ground" .. k, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER, REGISTER_FILTER_ABILITY_ID, k )
    end
    for k, v in pairs(Effects.LinkedGroundMine) do
        eventManager:RegisterForEvent(moduleName .. "Ground" .. k, EVENT_EFFECT_CHANGED, SpellCastBuffs.OnEffectChangedGround )
        eventManager:AddFilterForEvent(moduleName .. "Ground" .. k, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER, REGISTER_FILTER_ABILITY_ID, k )
    end

    -- Combat Events
    eventManager:RegisterForEvent(moduleName .. "Event1", EVENT_COMBAT_EVENT, SpellCastBuffs.OnCombatEventIn )
    eventManager:RegisterForEvent(moduleName .. "Event2", EVENT_COMBAT_EVENT, SpellCastBuffs.OnCombatEventOut )
    eventManager:RegisterForEvent(moduleName .. "Event3", EVENT_COMBAT_EVENT, SpellCastBuffs.OnCombatEventOut )
    eventManager:AddFilterForEvent(moduleName .. "Event1", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER, REGISTER_FILTER_IS_ERROR, false) -- Target -> Player
    eventManager:AddFilterForEvent(moduleName .. "Event2", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER, REGISTER_FILTER_IS_ERROR, false) -- Player -> Target
    eventManager:AddFilterForEvent(moduleName .. "Event3", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER_PET, REGISTER_FILTER_IS_ERROR, false) -- Player Pet -> Target
    for k, v in pairs(Effects.AddNameOnEvent) do
        eventManager:RegisterForEvent(moduleName .. "Event4" .. k, EVENT_COMBAT_EVENT, SpellCastBuffs.OnCombatAddNameEvent )
        eventManager:AddFilterForEvent(moduleName .. "Event4" .. k, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, k )
    end
    eventManager:RegisterForEvent(moduleName, EVENT_BOSSES_CHANGED, SpellCastBuffs.AddNameOnBossEngaged )

    -- Stealth Events
    eventManager:RegisterForEvent(moduleName .. "Player",          EVENT_STEALTH_STATE_CHANGED, SpellCastBuffs.StealthStateChanged )
    eventManager:RegisterForEvent(moduleName .. "Reticleover",     EVENT_STEALTH_STATE_CHANGED, SpellCastBuffs.StealthStateChanged )
    eventManager:AddFilterForEvent(moduleName .. "Player",         EVENT_STEALTH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "player" )
    eventManager:AddFilterForEvent(moduleName .. "Reticleover",    EVENT_STEALTH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover" )

    -- Disguise Events
    eventManager:RegisterForEvent(moduleName .. "Player",          EVENT_DISGUISE_STATE_CHANGED, SpellCastBuffs.DisguiseStateChanged )
    eventManager:RegisterForEvent(moduleName .. "Reticleover",     EVENT_DISGUISE_STATE_CHANGED, SpellCastBuffs.DisguiseStateChanged )
    eventManager:AddFilterForEvent(moduleName .. "Player",         EVENT_DISGUISE_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "player" )
    eventManager:AddFilterForEvent(moduleName .. "Reticleover",    EVENT_DISGUISE_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover" )

    -- Artificial Effects Handling
    eventManager:RegisterForEvent(moduleName, EVENT_ARTIFICIAL_EFFECT_ADDED, SpellCastBuffs.ArtificialEffectUpdate)
    eventManager:RegisterForEvent(moduleName, EVENT_ARTIFICIAL_EFFECT_REMOVED, SpellCastBuffs.ArtificialEffectUpdate)

    -- Activate/Deactivate Player, Player Dead/Alive, Vibration, and Unit Death
    eventManager:RegisterForEvent(moduleName, EVENT_PLAYER_ACTIVATED,   SpellCastBuffs.OnPlayerActivated )
    eventManager:RegisterForEvent(moduleName, EVENT_PLAYER_DEACTIVATED, SpellCastBuffs.OnPlayerDeactivated )
    eventManager:RegisterForEvent(moduleName, EVENT_PLAYER_ALIVE, SpellCastBuffs.OnPlayerAlive )
    eventManager:RegisterForEvent(moduleName, EVENT_PLAYER_DEAD,  SpellCastBuffs.OnPlayerDead )
    eventManager:RegisterForEvent(moduleName, EVENT_VIBRATION,    SpellCastBuffs.OnVibration )
    eventManager:RegisterForEvent(moduleName, EVENT_UNIT_DEATH_STATE_CHANGED,  SpellCastBuffs.OnDeath )

    -- Mount Events
    eventManager:RegisterForEvent(moduleName, EVENT_MOUNTED_STATE_CHANGED, SpellCastBuffs.MountStatus)
    eventManager:RegisterForEvent(moduleName, EVENT_COLLECTIBLE_USE_RESULT, SpellCastBuffs.CollectibleUsed)

    -- Inventory Events
    eventManager:RegisterForEvent(moduleName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SpellCastBuffs.DisguiseItem)
    eventManager:AddFilterForEvent(moduleName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN )

    -- Duel (For resolving Target Battle Spirit Status)
    eventManager:RegisterForEvent(moduleName, EVENT_DUEL_STARTED, SpellCastBuffs.DuelStart)
    eventManager:RegisterForEvent(moduleName, EVENT_DUEL_FINISHED, SpellCastBuffs.DuelEnd)

    -- Register event to update icons/names/tooltips for some abilities where we pull information from the currently learned morph
    eventManager:RegisterForEvent(moduleName, EVENT_SKILLS_FULL_UPDATE, Effects.UpdateEffectOnSkillUpdate)

    -- Werewolf
    SpellCastBuffs.RegisterWerewolfEvents()

    -- Debug
    SpellCastBuffs.RegisterDebugEvents()
end

function SpellCastBuffs.RegisterWerewolfEvents()
    eventManager:UnregisterForEvent(moduleName, EVENT_POWER_UPDATE)
    eventManager:UnregisterForUpdate(moduleName .. "WerewolfTicker")
    eventManager:UnregisterForEvent(moduleName, EVENT_WEREWOLF_STATE_CHANGED)
    if SpellCastBuffs.SV.ShowWerewolf then
        eventManager:RegisterForEvent(moduleName, EVENT_WEREWOLF_STATE_CHANGED, SpellCastBuffs.WerewolfState)
        if IsWerewolf() then
            SpellCastBuffs.WerewolfState(nil, true, true)
        end
    end
end

function SpellCastBuffs.RegisterDebugEvents()
    eventManager:UnregisterForEvent(moduleName .. "DebugCombat", EVENT_COMBAT_EVENT)
    eventManager:UnregisterForEvent(moduleName .. "DebugEffect", EVENT_EFFECT_CHANGED)
    if SpellCastBuffs.SV.ShowDebugCombat then
        eventManager:RegisterForEvent(moduleName .. "DebugCombat", EVENT_COMBAT_EVENT, SpellCastBuffs.EventCombatDebug)
    end
    if SpellCastBuffs.SV.ShowDebugEffect then
        eventManager:RegisterForEvent(moduleName .. "DebugEffect", EVENT_EFFECT_CHANGED, SpellCastBuffs.EventEffectDebug)
    end

    -- Debugs only enabled for my accounts
    if LUIE.PlayerDisplayName == "@ArtOfShredPTS" or LUIE.PlayerDisplayName == "@ArtOfShredLegacy" then
        eventManager:RegisterForEvent(moduleName .. "AuthorDebugCombat", EVENT_COMBAT_EVENT, SpellCastBuffs.AuthorCombatDebug)
        eventManager:RegisterForEvent(moduleName .. "AuthorDebugEffect", EVENT_EFFECT_CHANGED, SpellCastBuffs.AuthorEffectDebug)
    end

end

-- Bulk list add from menu buttons
function SpellCastBuffs.AddBulkToCustomList(list, table)
    if table ~= nil then
        for k, v in pairs(table) do
            SpellCastBuffs.AddToCustomList(list, k)
        end
    end
end

function SpellCastBuffs.ClearCustomList(list)
    local listRef = list == SpellCastBuffs.SV.BlacklistTable and GetString(SI_LUIE_CUSTOM_LIST_AURA_BLACKLIST) or ""
    for k, v in pairs(list) do
        list[k] = nil
    end
    CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
    printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_CLEARED), listRef), true)
end

-- List Handling (Add) for Prominent Auras & Blacklist
function SpellCastBuffs.AddToCustomList(list, input)
    local id = tonumber(input)
    local listRef =
        list == SpellCastBuffs.SV.PromBuffTable and GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTBUFFS) or
        list == SpellCastBuffs.SV.PromDebuffTable and GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTDEBUFFS) or
        list == SpellCastBuffs.SV.PriorityBuffTable and GetString(SI_LUIE_CUSTOM_LIST_PRIORITY_BUFFS) or
        list == SpellCastBuffs.SV.PriorityDebuffTable and GetString(SI_LUIE_CUSTOM_LIST_PRIORITY_DEBUFFS) or
        list == SpellCastBuffs.SV.BlacklistTable and GetString(SI_LUIE_CUSTOM_LIST_AURA_BLACKLIST) or ""
    if id and id > 0 then
        local name = zo_strformat("<<C:1>>", GetAbilityName(id))
        if name ~= nil and name ~= "" then
            local icon = zo_iconFormat(GetAbilityIcon(id), 16, 16)
            list[id] = true
            CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
            printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_ADDED_ID), icon, id, name, listRef), true)
        else
            CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
            printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_ADDED_FAILED), input, listRef), true)
        end
    else
        if input ~= "" then
            list[input] = true
            CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
            printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_ADDED_NAME), input, listRef), true)
        end
    end
    SpellCastBuffs.ReloadEffects("player")
end

-- List Handling (Remove) for Prominent Auras & Blacklist
function SpellCastBuffs.RemoveFromCustomList(list, input)
    local id = tonumber(input)
    local listRef =
        list == SpellCastBuffs.SV.PromBuffTable and GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTBUFFS) or
        list == SpellCastBuffs.SV.PromDebuffTable and GetString(SI_LUIE_SCB_WINDOWTITLE_PROMINENTDEBUFFS) or
        list == SpellCastBuffs.SV.PriorityBuffTable and GetString(SI_LUIE_CUSTOM_LIST_PRIORITY_BUFFS) or
        list == SpellCastBuffs.SV.PriorityDebuffTable and GetString(SI_LUIE_CUSTOM_LIST_PRIORITY_DEBUFFS) or
        list == SpellCastBuffs.SV.BlacklistTable and GetString(SI_LUIE_CUSTOM_LIST_AURA_BLACKLIST) or ""
    if id and id > 0 then
        local name = zo_strformat("<<C:1>>", GetAbilityName(id))
        local icon = zo_iconFormat(GetAbilityIcon(id), 16, 16)
        list[id] = nil
        CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
        printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_REMOVED_ID), icon, id, name, listRef), true)
    else
        if input ~= "" then
            list[input] = nil
            CHAT_SYSTEM:Maximize() CHAT_SYSTEM.primaryContainer:FadeIn()
            printToChat(zo_strformat(GetString(SI_LUIE_CUSTOM_LIST_REMOVED_NAME), input, listRef), true)
        end
    end
    SpellCastBuffs.ReloadEffects("player")
end

-- Set g_alignmentDirection table to equal the values from our SV Table & converts string values to proper alignment values. Called from Settings Menu & on Initialize
function SpellCastBuffs.SetupContainerAlignment()
    g_alignmentDirection = { }

    g_alignmentDirection.player1 = SpellCastBuffs.SV.AlignmentBuffsPlayer -- No icon holder for anchored buffs/debuffs - This value gets passed to SpellCastBuffs.updateIcons()
    g_alignmentDirection.playerb = SpellCastBuffs.SV.AlignmentBuffsPlayer
    g_alignmentDirection.player2 = SpellCastBuffs.SV.AlignmentDebuffsPlayer -- No icon holder for anchored buffs/debuffs - This value gets passed to SpellCastBuffs.updateIcons()
    g_alignmentDirection.playerd = SpellCastBuffs.SV.AlignmentDebuffsPlayer
    g_alignmentDirection.target1 = SpellCastBuffs.SV.AlignmentBuffsTarget -- No icon holder for anchored buffs/debuffs - This value gets passed to SpellCastBuffs.updateIcons()
    g_alignmentDirection.targetb = SpellCastBuffs.SV.AlignmentBuffsTarget
    g_alignmentDirection.target2 = SpellCastBuffs.SV.AlignmentDebuffsTarget -- No icon holder for anchored buffs/debuffs - This value gets passed to SpellCastBuffs.updateIcons()
    g_alignmentDirection.targetd = SpellCastBuffs.SV.AlignmentDebuffsTarget

    -- Set Long Term Effects Alignment
    if SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 1 then -- Horizontal
        g_alignmentDirection.player_long = SpellCastBuffs.SV.AlignmentLongHorz
    elseif SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 2 then -- Vertical
        g_alignmentDirection.player_long = SpellCastBuffs.SV.AlignmentLongVert
    end

    -- Set Prominent Buffs Alignment
    if SpellCastBuffs.SV.ProminentBuffContainerAlignment == 1 then -- Horizontal
        g_alignmentDirection.prominentbuffs = SpellCastBuffs.SV.AlignmentPromBuffsHorz
    elseif SpellCastBuffs.SV.ProminentBuffContainerAlignment == 2 then -- Vertical
        g_alignmentDirection.prominentbuffs = SpellCastBuffs.SV.AlignmentPromBuffsVert
    end

    -- Set Prominent Debuffs Alignment
    if SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 1 then -- Horizontal
        g_alignmentDirection.prominentdebuffs = SpellCastBuffs.SV.AlignmentPromDebuffsHorz
    elseif SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 2 then -- Vertical
        g_alignmentDirection.prominentdebuffs = SpellCastBuffs.SV.AlignmentPromDebuffsVert
    end

    for k, v in pairs(g_alignmentDirection) do
        if v == "Left" then
            g_alignmentDirection[k] = LEFT
        elseif v == "Right" then
            g_alignmentDirection[k] = RIGHT
        elseif v == "Centered" then
            g_alignmentDirection[k] = CENTER
        elseif v == "Top" then
            g_alignmentDirection[k] = TOP
        elseif v == "Bottom" then
            g_alignmentDirection[k] = BOTTOM
        else
            g_alignmentDirection[k] = CENTER -- Fallback
        end
    end

    for k, v in pairs(containerRouting) do
        if uiTlw[v].iconHolder and g_alignmentDirection[v] then
            uiTlw[v].iconHolder:ClearAnchors()
            uiTlw[v].iconHolder:SetAnchor(g_alignmentDirection[v])
        end
    end
end

-- Set g_sortDirection table to equal the values from our SV table. Called from Settings Menu & on Initialize
function SpellCastBuffs.SetupContainerSort()

    -- Clear the sort direction table
    g_sortDirection = { }

    -- Set sort order for player/target containers
    g_sortDirection.player1 = SpellCastBuffs.SV.SortBuffsPlayer
    g_sortDirection.playerb = SpellCastBuffs.SV.SortBuffsPlayer
    g_sortDirection.player2 = SpellCastBuffs.SV.SortDebuffsPlayer
    g_sortDirection.playerd = SpellCastBuffs.SV.SortDebuffsPlayer
    g_sortDirection.target1 = SpellCastBuffs.SV.SortBuffsTarget
    g_sortDirection.targetb = SpellCastBuffs.SV.SortBuffsTarget
    g_sortDirection.target2 = SpellCastBuffs.SV.SortDebuffsTarget
    g_sortDirection.targetd = SpellCastBuffs.SV.SortDebuffsTarget

    -- Set Long Term Effects Sort Order
    if SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 1 then -- Horizontal
        g_sortDirection.player_long = SpellCastBuffs.SV.SortLongHorz
    elseif SpellCastBuffs.SV.LongTermEffectsSeparateAlignment == 2 then -- Vertical
        g_sortDirection.player_long = SpellCastBuffs.SV.SortLongVert
    end

    -- Set Prominent Buffs Sort Order
    if SpellCastBuffs.SV.ProminentBuffContainerAlignment == 1 then -- Horizontal
        g_sortDirection.prominentbuffs = SpellCastBuffs.SV.SortPromBuffsHorz
    elseif SpellCastBuffs.SV.ProminentBuffContainerAlignment == 2 then -- Vertical
        g_sortDirection.prominentbuffs = SpellCastBuffs.SV.SortPromBuffsVert
    end

    -- Set Prominent Debuffs Sort Order
    if SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 1 then -- Horizontal
        g_sortDirection.prominentdebuffs = SpellCastBuffs.SV.SortPromDebuffsHorz
    elseif SpellCastBuffs.SV.ProminentDebuffContainerAlignment == 2 then -- Vertical
        g_sortDirection.prominentdebuffs = SpellCastBuffs.SV.SortPromDebuffsVert
    end

end

-- Reset position of windows. Called from Settings Menu.
function SpellCastBuffs.ResetTlwPosition()
    if not SpellCastBuffs.Enabled then
        return
    end
    SpellCastBuffs.SV.playerbOffsetX = nil
    SpellCastBuffs.SV.playerbOffsetY = nil
    SpellCastBuffs.SV.playerdOffsetX = nil
    SpellCastBuffs.SV.playerdOffsetY = nil
    SpellCastBuffs.SV.targetbOffsetX = nil
    SpellCastBuffs.SV.targetbOffsetY = nil
    SpellCastBuffs.SV.targetdOffsetX = nil
    SpellCastBuffs.SV.targetdOffsetY = nil
    SpellCastBuffs.SV.playerVOffsetX = nil
    SpellCastBuffs.SV.playerVOffsetY = nil
    SpellCastBuffs.SV.playerHOffsetX = nil
    SpellCastBuffs.SV.playerHOffsetY = nil
    SpellCastBuffs.SV.prominentbVOffsetX = nil
    SpellCastBuffs.SV.prominentbVOffsetY = nil
    SpellCastBuffs.SV.prominentbHOffsetX = nil
    SpellCastBuffs.SV.prominentbHOffsetY = nil
    SpellCastBuffs.SV.prominentdVOffsetX = nil
    SpellCastBuffs.SV.prominentdVOffsetY = nil
    SpellCastBuffs.SV.prominentdHOffsetX = nil
    SpellCastBuffs.SV.prominentdHOffsetY = nil
    SpellCastBuffs.SetTlwPosition()
end

-- Set position of windows. Called from .Initialize() and .ResetTlwPosition()
function SpellCastBuffs.SetTlwPosition()
    -- If icons are locked to custom frames, i.e. uiTlw[] is a CT_CONTROL of LUIE.UnitFrames.CustomFrames.player we do not have to do anything here. so just bail out
    -- Otherwise set position of uiTlw[] which are CT_TOPLEVELCONTROLs to saved or default positions
    if uiTlw.playerb and uiTlw.playerb:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.playerb:ClearAnchors()
        if not SpellCastBuffs.SV.lockPositionToUnitFrames and SpellCastBuffs.SV.playerbOffsetX ~= nil and SpellCastBuffs.SV.playerbOffsetY ~= nil then
            uiTlw.playerb:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.playerbOffsetX, SpellCastBuffs.SV.playerbOffsetY )
        else
            uiTlw.playerb:SetAnchor( BOTTOM, ZO_PlayerAttributeHealth, TOP, 0, -10 )
        end
    end

    if uiTlw.playerd and uiTlw.playerd:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.playerd:ClearAnchors()
        if not SpellCastBuffs.SV.lockPositionToUnitFrames and SpellCastBuffs.SV.playerdOffsetX ~= nil and SpellCastBuffs.SV.playerdOffsetY ~= nil then
            uiTlw.playerd:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.playerdOffsetX, SpellCastBuffs.SV.playerdOffsetY )
        else
            uiTlw.playerd:SetAnchor( BOTTOM, ZO_PlayerAttributeHealth, TOP, 0, -60 )
        end
    end

    if uiTlw.targetb and uiTlw.targetb:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.targetb:ClearAnchors()
        if not SpellCastBuffs.SV.lockPositionToUnitFrames and SpellCastBuffs.SV.targetbOffsetX ~= nil and SpellCastBuffs.SV.targetbOffsetY ~= nil then
            uiTlw.targetb:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.targetbOffsetX, SpellCastBuffs.SV.targetbOffsetY )
        else
            uiTlw.targetb:SetAnchor( TOP, ZO_TargetUnitFramereticleover, BOTTOM, 0, 60 )
        end
    end

    if uiTlw.targetd and uiTlw.targetd:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.targetd:ClearAnchors()
        if not SpellCastBuffs.SV.lockPositionToUnitFrames and SpellCastBuffs.SV.targetdOffsetX ~= nil and SpellCastBuffs.SV.targetdOffsetY ~= nil then
            uiTlw.targetd:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.targetdOffsetX, SpellCastBuffs.SV.targetdOffsetY )
        else
            uiTlw.targetd:SetAnchor( TOP, ZO_TargetUnitFramereticleover, BOTTOM, 0, 110 )
        end
    end

    if uiTlw.player_long then
        uiTlw.player_long:ClearAnchors()
        if uiTlw.player_long.alignVertical then
            if SpellCastBuffs.SV.playerVOffsetX ~= nil and SpellCastBuffs.SV.playerVOffsetY ~= nil then
                uiTlw.player_long:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.playerVOffsetX, SpellCastBuffs.SV.playerVOffsetY )
            else
                uiTlw.player_long:SetAnchor( BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -3, -75 )
            end
        else
            if SpellCastBuffs.SV.playerHOffsetX ~= nil and SpellCastBuffs.SV.playerHOffsetY ~= nil then
                uiTlw.player_long:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.playerHOffsetX, SpellCastBuffs.SV.playerHOffsetY )
            else
                uiTlw.player_long:SetAnchor( BOTTOM, ZO_PlayerAttributeHealth, TOP, 0, -70 )
            end
        end
    end

    -- Setup Prominent Buffs Position
    if uiTlw.prominentbuffs then
        uiTlw.prominentbuffs:ClearAnchors()
        if uiTlw.prominentbuffs.alignVertical then
            if SpellCastBuffs.SV.prominentbVOffsetX ~= nil and SpellCastBuffs.SV.prominentbVOffsetY ~= nil then
                uiTlw.prominentbuffs:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.prominentbVOffsetX, SpellCastBuffs.SV.prominentbVOffsetY )
            else
                uiTlw.prominentbuffs:SetAnchor( CENTER, GuiRoot, CENTER, -340, -100 )
            end
        else
            if SpellCastBuffs.SV.prominentbHOffsetX ~= nil and SpellCastBuffs.SV.prominentbHOffsetY ~= nil then
                uiTlw.prominentbuffs:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.prominentbHOffsetX, SpellCastBuffs.SV.prominentbHOffsetY )
            else
                uiTlw.prominentbuffs:SetAnchor( CENTER, GuiRoot, CENTER, -340, -100 )
            end
        end
    end

    if uiTlw.prominentdebuffs then
        uiTlw.prominentdebuffs:ClearAnchors()
        if uiTlw.prominentdebuffs.alignVertical then
            if SpellCastBuffs.SV.prominentdVOffsetX ~= nil and SpellCastBuffs.SV.prominentdVOffsetY ~= nil then
                uiTlw.prominentdebuffs:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.prominentdVOffsetX, SpellCastBuffs.SV.prominentdVOffsetY )
            else
                uiTlw.prominentdebuffs:SetAnchor( CENTER, GuiRoot, CENTER, 340, -100 )
            end
        else
            if SpellCastBuffs.SV.prominentdHOffsetX ~= nil and SpellCastBuffs.SV.prominentdHOffsetY ~= nil then
                uiTlw.prominentdebuffs:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, SpellCastBuffs.SV.prominentdHOffsetX, SpellCastBuffs.SV.prominentdHOffsetY )
            else
                uiTlw.prominentdebuffs:SetAnchor( CENTER, GuiRoot, CENTER, 340, -100 )
            end
        end
    end
end

-- Unlock windows for moving. Called from Settings Menu.
function SpellCastBuffs.SetMovingState(state)
    if not SpellCastBuffs.Enabled then
        return
    end

    -- Set moving state
    if uiTlw.playerb and uiTlw.playerb:GetType() == CT_TOPLEVELCONTROL and not SpellCastBuffs.SV.lockPositionToUnitFrames then
        uiTlw.playerb:SetMouseEnabled( state )
        uiTlw.playerb:SetMovable( state )
    end
    if uiTlw.playerd and uiTlw.playerd:GetType() == CT_TOPLEVELCONTROL and not SpellCastBuffs.SV.lockPositionToUnitFrames then
        uiTlw.playerd:SetMouseEnabled( state )
        uiTlw.playerd:SetMovable( state )
    end
    if uiTlw.targetb and uiTlw.targetb:GetType() == CT_TOPLEVELCONTROL and not SpellCastBuffs.SV.lockPositionToUnitFrames then
        uiTlw.targetb:SetMouseEnabled( state )
        uiTlw.targetb:SetMovable( state )
    end
    if uiTlw.targetd and uiTlw.targetd:GetType() == CT_TOPLEVELCONTROL and not SpellCastBuffs.SV.lockPositionToUnitFrames then
        uiTlw.targetd:SetMouseEnabled( state )
        uiTlw.targetd:SetMovable( state )
    end
    if uiTlw.player_long then
        uiTlw.player_long:SetMouseEnabled( state )
        uiTlw.player_long:SetMovable( state )
    end
    if uiTlw.prominentbuffs then
        uiTlw.prominentbuffs:SetMouseEnabled( state )
        uiTlw.prominentbuffs:SetMovable( state )
    end
    if uiTlw.prominentdebuffs then
        uiTlw.prominentdebuffs:SetMouseEnabled( state )
        uiTlw.prominentdebuffs:SetMovable( state )
    end

    -- Show/hide preview
    for _, v in pairs(containerRouting) do
        uiTlw[v].preview:SetHidden( not state )
    end

    -- Now create or remove test-effects icons
    if state then
        SpellCastBuffs.MenuPreview()
    else
        SpellCastBuffs.Reset()
    end
end

-- Reset all buff containers
function SpellCastBuffs.Reset()
    if not SpellCastBuffs.Enabled then
        return
    end

    -- Update padding between icons
    g_padding = math.floor(0.5 + SpellCastBuffs.SV.IconSize / 13)

    -- Set size of top level window
    -- Player
    if uiTlw.playerb and uiTlw.playerb:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.playerb:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
        uiTlw.playerd:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
    else
        uiTlw.player2:SetHeight( SpellCastBuffs.SV.IconSize )
        uiTlw.player2.firstAnchor = { TOPLEFT, TOP }
        uiTlw.player2.maxIcons = math.floor(  (uiTlw.player2:GetWidth()-4*g_padding) / (SpellCastBuffs.SV.IconSize+g_padding) )

        uiTlw.player1:SetHeight( SpellCastBuffs.SV.IconSize)
        uiTlw.player1.firstAnchor = { TOPLEFT, TOP }
        uiTlw.player1.maxIcons = math.floor(  (uiTlw.player1:GetWidth()-4*g_padding) / (SpellCastBuffs.SV.IconSize+g_padding) )
    end

    -- Target
    if uiTlw.targetb and uiTlw.targetb:GetType() == CT_TOPLEVELCONTROL then
        uiTlw.targetb:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
        uiTlw.targetd:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
    else
        uiTlw.target2:SetHeight( SpellCastBuffs.SV.IconSize )
        uiTlw.target2.firstAnchor = { TOPLEFT, TOP }
        uiTlw.target2.maxIcons = math.floor(  (uiTlw.target2:GetWidth()-4*g_padding) / (SpellCastBuffs.SV.IconSize+g_padding) )

        uiTlw.target1:SetHeight( SpellCastBuffs.SV.IconSize)
        uiTlw.target1.firstAnchor = { TOPLEFT, TOP }
        uiTlw.target1.maxIcons = math.floor(  (uiTlw.target1:GetWidth()-4*g_padding) / (SpellCastBuffs.SV.IconSize+g_padding) )
    end

    -- Player long buffs
    if uiTlw.player_long then
        if uiTlw.player_long.alignVertical then
            uiTlw.player_long:SetDimensions( SpellCastBuffs.SV.IconSize + 6, 400 )
        else
            uiTlw.player_long:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
        end
    end

    -- Prominent buffs & debuffs
    if uiTlw.prominentbuffs then
        if uiTlw.prominentbuffs.alignVertical then
            uiTlw.prominentbuffs:SetDimensions( SpellCastBuffs.SV.IconSize + 6, 400 )
        else
            uiTlw.prominentbuffs:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
        end
        if uiTlw.prominentdebuffs.alignVertical then
            uiTlw.prominentdebuffs:SetDimensions( SpellCastBuffs.SV.IconSize + 6, 400 )
        else
            uiTlw.prominentdebuffs:SetDimensions( 500, SpellCastBuffs.SV.IconSize + 6 )
        end
    end

    -- Set Alignment and Sort Direction
    SpellCastBuffs.SetupContainerAlignment()
    SpellCastBuffs.SetupContainerSort()

    local needs_reset = {}
    -- And reset sizes of already existing icons
    for _, container in pairs(containerRouting) do
        needs_reset[container] = true
    end
    for _, container in pairs(containerRouting) do
        if needs_reset[container] then
            for i = 1, #uiTlw[container].icons do
                SpellCastBuffs.ResetSingleIcon( container, uiTlw[container].icons[i], uiTlw[container].icons[i-1] )
            end
        end
        needs_reset[container] = false
    end

    if g_playerActive then
        SpellCastBuffs.ReloadEffects("player")
    end
end

-- Reset only a single icon
function SpellCastBuffs.ResetSingleIcon( container, buff, AnchorItem )
    local buffSize = SpellCastBuffs.SV.IconSize
    local frameSize = 2 * buffSize + 4

    buff:SetHidden( true )
    --buff:SetAlpha( 1 )
    buff:SetDimensions( buffSize, buffSize )
    buff.frame:SetDimensions( frameSize, frameSize )
    buff.back:SetHidden( SpellCastBuffs.SV.GlowIcons )
    buff.frame:SetHidden( not SpellCastBuffs.SV.GlowIcons )
    buff.label:SetAnchor(TOPLEFT, buff, LEFT, -g_padding, -SpellCastBuffs.SV.LabelPosition)
    buff.label:SetAnchor(BOTTOMRIGHT, buff, BOTTOMRIGHT, g_padding, -2)
    buff.label:SetHidden( not SpellCastBuffs.SV.RemainingText )
    buff.stack:SetAnchor(CENTER, buff, BOTTOMLEFT, 0, 0)
    buff.stack:SetAnchor(CENTER, buff, TOPRIGHT, -g_padding * 3, g_padding * 3)
    buff.stack:SetHidden( true )

    if buff.name ~= nil then
        buff.name:SetHidden( not SpellCastBuffs.SV.ProminentLabel )
    end

    if buff.bar ~= nil then
        buff.bar.backdrop:SetHidden( not SpellCastBuffs.SV.ProminentProgress )
        buff.bar.bar:SetHidden( not SpellCastBuffs.SV.ProminentProgress )
    end

    if buff.cd ~= nil then
        buff.cd:SetHidden( not SpellCastBuffs.SV.RemainingCooldown )
        -- We do not need black icon background when there is no Cooldown control present
        buff.iconbg:SetHidden( not SpellCastBuffs.SV.RemainingCooldown )
    end

    if buff.abilityId ~= nil then
        buff.abilityId:SetHidden( not SpellCastBuffs.SV.ShowDebugAbilityId )
    end

    local inset = (SpellCastBuffs.SV.RemainingCooldown and buff.cd ~= nil) and 3 or 1

    buff.drop:ClearAnchors()
    buff.drop:SetAnchor( TOPLEFT, buff, TOPLEFT, inset, inset )
    buff.drop:SetAnchor( BOTTOMRIGHT, buff, BOTTOMRIGHT, -inset, -inset )

    buff.icon:ClearAnchors()
    buff.icon:SetAnchor( TOPLEFT, buff, TOPLEFT, inset, inset )
    buff.icon:SetAnchor( BOTTOMRIGHT, buff, BOTTOMRIGHT, -inset, -inset )
    if buff.iconbg ~= nil then
        buff.iconbg:ClearAnchors()
        buff.iconbg:SetAnchor( TOPLEFT, buff, TOPLEFT, inset, inset)
        buff.iconbg:SetAnchor( BOTTOMRIGHT, buff, BOTTOMRIGHT, -inset, -inset)
    end

    if container == "prominentbuffs" then
        if SpellCastBuffs.SV.ProminentBuffLabelDirection == "Left" then
            buff.name:ClearAnchors()
            buff.name:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, -(SpellCastBuffs.SV.IconSize * .25) +2 )
            buff.name:SetAnchor(TOPRIGHT, buff, TOPLEFT, -4, -(SpellCastBuffs.SV.IconSize * .25) +2 )

            buff.bar.backdrop:ClearAnchors()
            buff.bar.backdrop:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, 0 )
            buff.bar.backdrop:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, 0 )

            buff.bar.bar:SetTexture(LUIE.StatusbarTextures[SpellCastBuffs.SV.ProminentProgressTexture])
            buff.bar.bar:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
            buff.bar.bar:ClearAnchors()
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
        else
            buff.name:ClearAnchors()
            buff.name:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, -(SpellCastBuffs.SV.IconSize * .25) +2 )
            buff.name:SetAnchor(TOPLEFT, buff, TOPRIGHT, 4, -(SpellCastBuffs.SV.IconSize * .25) +2 )

            buff.bar.backdrop:ClearAnchors()
            buff.bar.backdrop:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, 0 )
            buff.bar.backdrop:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, 0 )

            buff.bar.bar:SetTexture(LUIE.StatusbarTextures[SpellCastBuffs.SV.ProminentProgressTexture])
            buff.bar.bar:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
            buff.bar.bar:ClearAnchors()
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
        end
    end

    if container == "prominentdebuffs" then
        if SpellCastBuffs.SV.ProminentDebuffLabelDirection == "Right" then
            buff.name:ClearAnchors()
            buff.name:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, -(SpellCastBuffs.SV.IconSize * .25) +2 )
            buff.name:SetAnchor(TOPLEFT, buff, TOPRIGHT, 4, -(SpellCastBuffs.SV.IconSize * .25) +2 )

            buff.bar.backdrop:ClearAnchors()
            buff.bar.backdrop:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, 0 )
            buff.bar.backdrop:SetAnchor(BOTTOMLEFT, buff, BOTTOMRIGHT, 4, 0 )

            buff.bar.bar:SetTexture(LUIE.StatusbarTextures[SpellCastBuffs.SV.ProminentProgressTexture])
            buff.bar.bar:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
            buff.bar.bar:ClearAnchors()
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
        else
            buff.name:ClearAnchors()
            buff.name:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, -(SpellCastBuffs.SV.IconSize * .25) +2 )
            buff.name:SetAnchor(TOPRIGHT, buff, TOPLEFT, -4, -(SpellCastBuffs.SV.IconSize * .25) +2 )

            buff.bar.backdrop:ClearAnchors()
            buff.bar.backdrop:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, 0 )
            buff.bar.backdrop:SetAnchor(BOTTOMRIGHT, buff, BOTTOMLEFT, -4, 0 )

            buff.bar.bar:SetTexture(LUIE.StatusbarTextures[SpellCastBuffs.SV.ProminentProgressTexture])
            buff.bar.bar:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
            buff.bar.bar:ClearAnchors()
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
            buff.bar.bar:SetAnchor(CENTER, buff.bar.backdrop, CENTER, 0, 0)
        end
    end

    -- Position all items except first one to the right of it's neighbor
    -- First icon is positioned automatically if the container is present
    buff:ClearAnchors()
    if AnchorItem == nil then
        -- First Icon is positioned only when the container is present,
        if uiTlw[container].iconHolder then
            if uiTlw[container].alignVertical then
                buff:SetAnchor( BOTTOM, uiTlw[container].iconHolder, BOTTOM, 0, 0 )
            else
                buff:SetAnchor( LEFT, uiTlw[container].iconHolder, LEFT, 0, 0 )
            end
        end

    -- For container without holder we will reanchor first icon all the time
    -- Rest icons go one after another.
    else
        if uiTlw[container].alignVertical then
            buff:SetAnchor( BOTTOM, AnchorItem, TOP, 0, -g_padding )
        else
            buff:SetAnchor( LEFT, AnchorItem, RIGHT, g_padding, 0 )
        end
    end
end

-- Right Click Cancel Buff function
function SpellCastBuffs.Buff_OnMouseUp(self, button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT and self.buffSlot and not self.isArtificial then
        CancelBuff(self.buffSlot)
    end
end

local function ClearStickyTooltip()
    ClearTooltip(GameTooltip)
    eventManager:UnregisterForUpdate(moduleName .. "StickyTooltip")
end

local buffTypes = {
    [1] = "Buff",
    [2] = "Debuff",
    [3] = "Unbreakable Buff",
    [4] = "Unbreakable Debuff",
    [5] = "None",
}

function SpellCastBuffs.TooltipBottomLine(control, detailsLine, artificial)
    -- Add bottom divider and info if present:
    if SpellCastBuffs.SV.TooltipAbilityId or SpellCastBuffs.SV.TooltipBuffType then
        ZO_Tooltip_AddDivider(GameTooltip)
        GameTooltip:SetVerticalPadding(4)
        GameTooltip:AddLine("", "", ZO_NORMAL_TEXT:UnpackRGB())
        -- Add Ability ID Line
        if SpellCastBuffs.SV.TooltipAbilityId then
            local labelAbilityId = control.effectId and control.effectId or "None"
            if labelAbilityId == "Fake" then
                artificial = true
            end
            if artificial then
                labelAbilityId = "Artificial"
            end
            GameTooltip:AddHeaderLine("Ability ID", "ZoFontWinT1", detailsLine, TOOLTIP_HEADER_SIDE_LEFT, ZO_NORMAL_TEXT:UnpackRGB())
            GameTooltip:AddHeaderLine(labelAbilityId, "ZoFontWinT1", detailsLine, TOOLTIP_HEADER_SIDE_RIGHT, 1, 1, 1)
            detailsLine = detailsLine + 1
        end

        -- Add Buff Type Line
        if SpellCastBuffs.SV.TooltipBuffType then
            local buffType = control.buffType and control.buffType or 5
            if control.effectId and Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].unbreakable then
                buffType = buffType + 2
            end
            GameTooltip:AddHeaderLine("Type", "ZoFontWinT1", detailsLine, TOOLTIP_HEADER_SIDE_LEFT, ZO_NORMAL_TEXT:UnpackRGB())
            GameTooltip:AddHeaderLine(buffTypes[buffType], "ZoFontWinT1", detailsLine, TOOLTIP_HEADER_SIDE_RIGHT, 1, 1, 1)
            detailsLine = detailsLine + 1
        end
    end
end

-- OnMouseEnter for Buff Tooltips
function SpellCastBuffs.Buff_OnMouseEnter(control)
    eventManager:UnregisterForUpdate(moduleName .. "StickyTooltip")

    InitializeTooltip(GameTooltip, control, BOTTOM, 0, -5, TOP)
    -- Setup Text
    local tooltipText = ""
    local detailsLine
    local colorText = ZO_NORMAL_TEXT
    local tooltipTitle = zo_strformat(SI_ABILITY_TOOLTIP_NAME, control.effectName)
    if control.isArtificial then
        tooltipText = GetArtificialEffectTooltipText(control.effectId)
        GameTooltip:AddLine(tooltipTitle, "ZoFontHeader2",1,1,1, nil)
        detailsLine = 3
        if SpellCastBuffs.SV.TooltipEnable then
            GameTooltip:SetVerticalPadding(1)
            ZO_Tooltip_AddDivider(GameTooltip)
            GameTooltip:SetVerticalPadding(5)
            GameTooltip:AddLine(tooltipText, "", colorText:UnpackRGBA())
            detailsLine = 5
        end
        SpellCastBuffs.TooltipBottomLine(control, detailsLine, true)
    else
        if not SpellCastBuffs.SV.TooltipEnable then
            GameTooltip:AddLine(tooltipTitle, "ZoFontHeader2",1,1,1, nil)
            detailsLine = 3
            SpellCastBuffs.TooltipBottomLine(control, detailsLine)
            return
        end

        if control.tooltip then
            tooltipText = control.tooltip
        else
            local duration
            if type(control.effectId) == "number" then
                duration = control.duration / 1000
                local value2
                local value3
                if Effects.EffectOverride[control.effectId] then
                    if Effects.EffectOverride[control.effectId].tooltipValue2 then
                        value2 = Effects.EffectOverride[control.effectId].tooltipValue2
                    elseif Effects.EffectOverride[control.effectId].tooltipValue2Mod then
                        value2 = math.floor( duration + Effects.EffectOverride[control.effectId].tooltipValue2Mod + 0.5 )
                    elseif Effects.EffectOverride[control.effectId].tooltipValue2Id then
                        value2 = math.floor(GetAbilityDuration(Effects.EffectOverride[control.effectId].tooltipValue2Id) + 0.5) / 1000
                    else
                        value2 = 0
                    end
                else
                    value2 = 0
                end
                if Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].tooltipValue3 then
                    value3 = Effects.EffectOverride[control.effectId].tooltipValue3
                else
                    value3 = 0
                end
                duration = math.floor((duration * 10) + 0.5) / 10

                tooltipText = (Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].tooltip) and zo_strformat(Effects.EffectOverride[control.effectId].tooltip, duration, value2, value3) or ""

                -- Use separate Veteran difficulty tooltip if applicable.
                if LUIE.ResolveVeteranDifficulty() == true and Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].tooltipVet then
                    tooltipText = zo_strformat(Effects.EffectOverride[control.effectId].tooltipVet, duration, value2, value3)
                end
                -- Use separate Ground tooltip if applicable (only applies to buffs not debuffs)
                if Effects.EffectGroundDisplay[control.effectId] and Effects.EffectGroundDisplay[control.effectId].tooltip and control.buffType == BUFF_EFFECT_TYPE_BUFF then
                    tooltipText = zo_strformat(Effects.EffectGroundDisplay[control.effectId].tooltip, duration, value2, value3)
                end

                -- Display Default Tooltip Description if no custom tooltip is present
                if tooltipText == "" or tooltipText == nil then
                    if GetAbilityEffectDescription(control.buffSlot) ~= "" then
                        tooltipText = GetAbilityEffectDescription(control.buffSlot)
                    end
                end

                -- Display Default Description if no internal effect description is present
                if tooltipText == "" or tooltipText == nil then
                    if GetAbilityDescription(control.effectId) ~= "" then
                        tooltipText = GetAbilityDescription(control.effectId)
                    end
                end

                -- Dynamic Tooltip if present
                if Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].dynamicTooltip then
                    tooltipText = LUIE.DynamicTooltip(control.effectId)
                end

            else
                duration = 0
            end
        end

        if Effects.TooltipUseDefault[control.effectId] then
            if GetAbilityEffectDescription(control.buffSlot) ~= "" then
                tooltipText = GetAbilityEffectDescription(control.buffSlot)
                tooltipText = LUIE.UpdateMundusTooltipSyntax(control.effectId, tooltipText)
            end
        end

        local thirdLine
        local duration = control.duration / 1000
        if Effects.EffectOverride[control.effectId] and Effects.EffectOverride[control.effectId].tooltipDurFix then
            duration = duration + Effects.EffectOverride[control.effectId].tooltipDurFix
        end
        if Effects.TooltipNameOverride[control.effectName] then
            thirdLine = zo_strformat(Effects.TooltipNameOverride[control.effectName], duration)
        end
        if Effects.TooltipNameOverride[control.effectId] then
            thirdLine = zo_strformat(Effects.TooltipNameOverride[control.effectId], duration)
        end
        -- Have to trim trailing spaces on the end of tooltips
        if tooltipText ~= "" then
            tooltipText = string.match(tooltipText, ".*%S")
        end
        if thirdLine ~="" and thirdLine ~= nil then
            colorText = control.buffType == BUFF_EFFECT_TYPE_DEBUFF and ZO_ERROR_COLOR or ZO_SUCCEEDED_TEXT
        end

        detailsLine = 5

        GameTooltip:AddLine(tooltipTitle, "ZoFontHeader2",1,1,1, nil)
        if tooltipText ~= "" and tooltipText ~= nil then
            GameTooltip:SetVerticalPadding(1)
            ZO_Tooltip_AddDivider(GameTooltip)
            GameTooltip:SetVerticalPadding(5)
            GameTooltip:AddLine(tooltipText, "", colorText:UnpackRGBA())
        end
        if thirdLine ~="" and thirdLine ~= nil then
            if tooltipText == "" or tooltipText == nil then
                GameTooltip:SetVerticalPadding(1)
                ZO_Tooltip_AddDivider(GameTooltip)
                GameTooltip:SetVerticalPadding(5)
            end
            detailsLine = 7
            GameTooltip:AddLine(thirdLine, "", ZO_NORMAL_TEXT:UnpackRGB())
        end

        SpellCastBuffs.TooltipBottomLine(control, detailsLine)

        -- Tooltip Debug
        -- GameTooltip:SetAbilityId(117391)

    end
end

-- OnMouseExit for Buff Tooltips
function SpellCastBuffs.Buff_OnMouseExit(control)
    if SpellCastBuffs.SV.TooltipSticky > 0 then
        eventManager:RegisterForUpdate(moduleName .. "StickyTooltip", SpellCastBuffs.SV.TooltipSticky, ClearStickyTooltip )
    else
        ClearTooltip(GameTooltip)
    end
end

-- Create a Single Buff Icon
function SpellCastBuffs.CreateSingleIcon(container, AnchorItem, effectType)
    local buff = UI.Backdrop( uiTlw[container], nil, nil, {0,0,0,0.5}, {0,0,0,1}, false )

    -- Enable tooltip
    buff:SetMouseEnabled( true )
    buff:SetHandler("OnMouseEnter", SpellCastBuffs.Buff_OnMouseEnter)
    buff:SetHandler("OnMouseExit",  SpellCastBuffs.Buff_OnMouseExit)
    buff:SetHandler("OnMouseUp",  SpellCastBuffs.Buff_OnMouseUp)

    -- Border
    buff.back   = UI.Texture( buff, nil, nil, "/esoui/art/actionbar/abilityframe64_up.dds", nil, false )
    buff.back:SetAnchor(TOPLEFT, buff, TOPLEFT)
    buff.back:SetAnchor(BOTTOMRIGHT, buff, BOTTOMRIGHT)
    -- Glow border
    buff.frame  = UI.Texture( buff, {CENTER,CENTER}, nil, nil, nil, false )
    -- Background
    if container ~= "player_long" then
        buff.iconbg = UI.Texture( buff, nil, nil, "/esoui/art/actionbar/abilityinset.dds", DL_CONTROLS, true )
        buff.iconbg = UI.Backdrop( buff, nil, nil, {0,0,0,0.9}, {0,0,0,0.9}, false )
        buff.iconbg:SetDrawLevel(DL_CONTROLS)
    end
    -- Drop for collectible/mount
    buff.drop   = UI.Texture( buff, nil, nil, "LuiExtended/media/icons/abilities/ability_innate_background.dds", DL_BACKGROUND, true )
    -- Icon itself
    buff.icon   = UI.Texture( buff, nil, nil, "/esoui/art/icons/icon_missing.dds", DL_CONTROLS, false )
    -- Remaining text label
    buff.label = UI.Label( buff, nil, nil, nil, g_buffsFont, nil, false )
    buff.label:SetAnchor(TOPLEFT, buff, LEFT, -g_padding, -SpellCastBuffs.SV.LabelPosition)
    buff.label:SetAnchor(BOTTOMRIGHT, buff, BOTTOMRIGHT, g_padding, -2)
    -- AbilityId Debug label
    buff.abilityId = UI.Label( buff, nil, nil, nil, g_buffsFont, nil, false )
    buff.abilityId:SetAnchor(CENTER, buff, CENTER, 0, 0)
    buff.abilityId:SetAnchor(CENTER, buff, CENTER, 0, 0)
    -- Stack label
    buff.stack = UI.Label( buff, nil, nil, nil, g_buffsFont, nil, false )
    buff.stack:SetAnchor(CENTER, buff, BOTTOMLEFT, 0, 0)
    buff.stack:SetAnchor(CENTER, buff, TOPRIGHT, -g_padding * 3, g_padding * 3)
    -- Cooldown circular control
    if buff.iconbg ~= nil then
        buff.cd = windowManager:CreateControl(nil, buff, CT_COOLDOWN)
        buff.cd:SetAnchor( TOPLEFT, buff, TOPLEFT, 1, 1 )
        buff.cd:SetAnchor( BOTTOMRIGHT, buff, BOTTOMRIGHT, -1, -1 )
        buff.cd:SetDrawLayer(DL_BACKGROUND)
    end

    if container == "prominentbuffs" then
        buff.effectType = effectType
        buff.name = UI.Label( buff, nil, nil, nil, g_prominentFont, nil, false )
        buff.bar = {
            ["backdrop"] = UI.Backdrop( buff, nil, {154, 16}, nil, nil, false ),
            ["bar"]     = UI.StatusBar( buff, nil, {150, 12}, nil, false ),
        }
        buff.bar.backdrop:SetEdgeTexture("",8,2,2)
        buff.bar.backdrop:SetDrawLayer(DL_BACKDROP)
        buff.bar.backdrop:SetDrawLevel(1)
        buff.bar.bar:SetMinMax(0, 1)
    end

    if container == "prominentdebuffs" then
        buff.effectType = effectType
        buff.name = UI.Label( buff, nil, nil, nil, g_prominentFont, nil, false )
        buff.bar = {
            ["backdrop"]= UI.Backdrop( buff, nil, {154, 16}, nil, nil, false ),
            ["bar"]     = UI.StatusBar( buff, nil, {150, 12}, nil, false ),
        }
        buff.bar.backdrop:SetEdgeTexture("",8,2,2)
        buff.bar.backdrop:SetDrawLayer(DL_BACKDROP)
        buff.bar.backdrop:SetDrawLevel(1)
        buff.bar.bar:SetMinMax(0, 1)
    end

    SpellCastBuffs.ResetSingleIcon(container, buff, AnchorItem)
    return buff
end

 -- Set proper color of border and text on single buff element
function SpellCastBuffs.SetSingleIconBuffType(buff, buffType, unbreakable, id)

    local contextType
    local fillColor

    if buffType == BUFF_EFFECT_TYPE_BUFF then
        contextType = "buff"
    else
        contextType = "debuff"
    end

    local abilityName = GetAbilityName(id)

    if contextType == "buff" then
        if SpellCastBuffs.SV.PriorityBuffTable[id] or SpellCastBuffs.SV.PriorityBuffTable[abilityName] then
            fillColor = SpellCastBuffs.SV.colors.prioritybuff
        elseif unbreakable == 1 and SpellCastBuffs.SV.ColorCosmetic then
            fillColor = SpellCastBuffs.SV.colors.cosmetic
        else
            fillColor = SpellCastBuffs.SV.colors.buff
        end
    elseif contextType == "debuff" then
        if SpellCastBuffs.SV.PriorityDebuffTable[id] or SpellCastBuffs.SV.PriorityDebuffTable[abilityName] then
            fillColor = SpellCastBuffs.SV.colors.prioritydebuff
        elseif unbreakable == 1 and SpellCastBuffs.SV.ColorUnbreakable then
            fillColor = SpellCastBuffs.SV.colors.unbreakable
        else
            -- If color by CC type is enabled then color by the crowd control type if detected
            if SpellCastBuffs.SV.ColorCC then
                if Effects.EffectOverride[id] and Effects.EffectOverride[id].cc then
                    local cc = Effects.EffectOverride[id].cc
                    if cc == LUIE_CC_TYPE_STUN or cc == LUIE_CC_TYPE_KNOCKDOWN then
                        fillColor = SpellCastBuffs.SV.colors.stun
                    elseif cc == LUIE_CC_TYPE_KNOCKBACK then
                        fillColor = SpellCastBuffs.SV.colors.knockback
                    elseif cc == LUIE_CC_TYPE_PULL then
                        fillColor = SpellCastBuffs.SV.colors.levitate
                    elseif cc == LUIE_CC_TYPE_DISORIENT then
                        fillColor = SpellCastBuffs.SV.colors.disorient
                    elseif cc == LUIE_CC_TYPE_FEAR then
                        fillColor = SpellCastBuffs.SV.colors.fear
                    elseif cc == LUIE_CC_TYPE_SILENCE then
                        fillColor = SpellCastBuffs.SV.colors.silence
                    elseif cc == LUIE_CC_TYPE_STAGGER then
                        fillColor = SpellCastBuffs.SV.colors.stagger
                    elseif cc == LUIE_CC_TYPE_SNARE then
                        fillColor = SpellCastBuffs.SV.colors.snare
                    elseif cc == LUIE_CC_TYPE_ROOT then
                        fillColor = SpellCastBuffs.SV.colors.root
                    else
                        fillColor = SpellCastBuffs.SV.colors.nocc
                    end
                else
                    fillColor = SpellCastBuffs.SV.colors.nocc
                end
            else
                fillColor = SpellCastBuffs.SV.colors.debuff
            end
        end
    end

    buff.frame:SetTexture("/esoui/art/actionbar/" .. contextType .. "_frame.dds")
    local labelColor = contextType == "buff" and SpellCastBuffs.SV.colors.buff or SpellCastBuffs.SV.colors.debuff
    buff.label:SetColor( unpack( SpellCastBuffs.SV.RemainingTextColoured and labelColor or {1,1,1,1} ) )
    buff.stack:SetColor( unpack( SpellCastBuffs.SV.RemainingTextColoured and labelColor or {1,1,1,1} ) )
    if buff.cd ~= nil then
        buff.cd:SetFillColor(unpack(fillColor))
    end

    if buff.bar then
        if buffType == BUFF_EFFECT_TYPE_DEBUFF then
            if SpellCastBuffs.SV.PriorityDebuffTable[id] or SpellCastBuffs.SV.PriorityDebuffTable[abilityName] then
                buff.bar.backdrop:SetCenterColor((0.1*SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[1]), (0.1*SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[2]), (0.1*SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[3]), 0.75)
                buff.bar.bar:SetGradientColors( SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[1], SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[2], SpellCastBuffs.SV.ProminentProgressDebuffPriorityC2[3], 1, SpellCastBuffs.SV.ProminentProgressDebuffPriorityC1[1], SpellCastBuffs.SV.ProminentProgressDebuffPriorityC1[2], SpellCastBuffs.SV.ProminentProgressDebuffPriorityC1[3], 1)
            else
                buff.bar.backdrop:SetCenterColor((0.1*SpellCastBuffs.SV.ProminentProgressDebuffC2[1]), (0.1*SpellCastBuffs.SV.ProminentProgressDebuffC2[2]), (0.1*SpellCastBuffs.SV.ProminentProgressDebuffC2[3]), 0.75)
                buff.bar.bar:SetGradientColors( SpellCastBuffs.SV.ProminentProgressDebuffC2[1], SpellCastBuffs.SV.ProminentProgressDebuffC2[2], SpellCastBuffs.SV.ProminentProgressDebuffC2[3], 1, SpellCastBuffs.SV.ProminentProgressDebuffC1[1], SpellCastBuffs.SV.ProminentProgressDebuffC1[2], SpellCastBuffs.SV.ProminentProgressDebuffC1[3], 1)
            end
        elseif buffType == BUFF_EFFECT_TYPE_BUFF then
            if SpellCastBuffs.SV.PriorityBuffTable[id] or SpellCastBuffs.SV.PriorityBuffTable[abilityName] then
                buff.bar.backdrop:SetCenterColor((0.1*SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[1]), (0.1*SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[2]), (0.1*SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[3]), 0.75)
                buff.bar.bar:SetGradientColors( SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[1], SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[2], SpellCastBuffs.SV.ProminentProgressBuffPriorityC2[3], 1, SpellCastBuffs.SV.ProminentProgressBuffPriorityC1[1], SpellCastBuffs.SV.ProminentProgressBuffPriorityC1[2], SpellCastBuffs.SV.ProminentProgressBuffPriorityC1[3], 1)
            else
                buff.bar.backdrop:SetCenterColor((0.1*SpellCastBuffs.SV.ProminentProgressBuffC2[1]), (0.1*SpellCastBuffs.SV.ProminentProgressBuffC2[2]), (0.1*SpellCastBuffs.SV.ProminentProgressBuffC2[3]), 0.75)
                buff.bar.bar:SetGradientColors( SpellCastBuffs.SV.ProminentProgressBuffC2[1], SpellCastBuffs.SV.ProminentProgressBuffC2[2], SpellCastBuffs.SV.ProminentProgressBuffC2[3], 1, SpellCastBuffs.SV.ProminentProgressBuffC1[1], SpellCastBuffs.SV.ProminentProgressBuffC1[2], SpellCastBuffs.SV.ProminentProgressBuffC1[3], 1)
            end
        end
    end
end

-- Updates local variable with new font and resets all existing icons
function SpellCastBuffs.ApplyFont()
    if not SpellCastBuffs.Enabled then
        return
    end

    -- Font setup for standard Buffs & Debuffs
    local fontName = LUIE.Fonts[SpellCastBuffs.SV.BuffFontFace]
    if not fontName or fontName == "" then
        printToChat(GetString(SI_LUIE_ERROR_FONT), true)
        fontName = "$(MEDIUM_FONT)"
    end
    local fontStyle = ( SpellCastBuffs.SV.BuffFontStyle and SpellCastBuffs.SV.BuffFontStyle ~= "" ) and SpellCastBuffs.SV.BuffFontStyle or "outline"
    local fontSize = ( SpellCastBuffs.SV.BuffFontSize and SpellCastBuffs.SV.BuffFontSize > 0 ) and SpellCastBuffs.SV.BuffFontSize or 17
    g_buffsFont = fontName .. "|" .. fontSize .. "|" .. fontStyle

    -- Font Setup for Prominent Buffs & Debuffs
    local prominentName = LUIE.Fonts[SpellCastBuffs.SV.ProminentLabelFontFace]
    if not prominentName or prominentName == "" then
        printToChat(GetString(SI_LUIE_ERROR_FONT), true)
        prominentName = "$(MEDIUM_FONT)"
    end
    local prominentStyle = ( SpellCastBuffs.SV.ProminentLabelFontStyle and SpellCastBuffs.SV.ProminentLabelFontStyle ~= "" ) and SpellCastBuffs.SV.ProminentLabelFontStyle or "outline"
    local prominentSize = ( SpellCastBuffs.SV.ProminentLabelFontSize and SpellCastBuffs.SV.ProminentLabelFontSize > 0 ) and SpellCastBuffs.SV.ProminentLabelFontSize or 17
    g_prominentFont = prominentName .. "|" .. prominentSize .. "|" .. prominentStyle

    local needs_reset = {}
    -- And reset sizes of already existing icons
    for _, container in pairs(containerRouting) do
        needs_reset[container] = true
    end
    for _, container in pairs(containerRouting) do
        if needs_reset[container] then
            for i = 1, #uiTlw[container].icons do
                -- Set label font
                uiTlw[container].icons[i].label:SetFont(g_buffsFont)
                -- Set prominent buff label font
                if uiTlw[container].icons[i].name then
                    uiTlw[container].icons[i].name:SetFont(g_prominentFont)
                end
            end
        end
        needs_reset[container] = false
    end
end

function SpellCastBuffs.OnEffectChangedGround(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, castByPlayer)

    if SpellCastBuffs.SV.HideGroundEffects then return end

    -- Mines with multiple auras have to be linked into one id for the purpose of tracking stacks
    if Effects.LinkedGroundMine[abilityId] then
        abilityId = Effects.LinkedGroundMine[abilityId]
    end

    -- Bail out if this ability is blacklisted
    if SpellCastBuffs.SV.BlacklistTable[abilityId] or SpellCastBuffs.SV.BlacklistTable[effectName] then
        return
    end

    -- Create fake ground aura
    local groundType = { }
    groundType[1] = { info = Effects.EffectGroundDisplay[abilityId].buff, context = "player1", promB = "promb_player", promD = "promd_player", type = 1 }
    groundType[2] = { info = Effects.EffectGroundDisplay[abilityId].debuff, context = "player2", promB = "promb_target", promD = "promd_target", type = BUFF_EFFECT_TYPE_DEBUFF }
    groundType[3] = { info = Effects.EffectGroundDisplay[abilityId].ground, context = "ground", promB = "promb_ground", promD = "promd_ground", type = BUFF_EFFECT_TYPE_DEBUFF }

    if changeType == EFFECT_RESULT_FADED then
        if Effects.EffectGroundDisplay[abilityId] and Effects.EffectGroundDisplay[abilityId].noRemove then return end -- Ignore some abilities
        local currentTime = GetGameTimeMilliseconds()
        if not g_protectAbilityRemoval[abilityId] or g_protectAbilityRemoval[abilityId] < currentTime then
            for i = 1, 3 do
                if groundType[i].info == true then
                    -- Set container context
                    local context
                    if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName]) then
                        context = groundType[i].promD
                    elseif (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
                        context = groundType[i].promB
                    else
                        context = groundType[i].context
                    end
                    if (Effects.IsGroundMineAura[abilityId] or Effects.IsGroundMineStack[abilityId]) then
                        -- Check to make sure aura exists in case of reloadUI
                        if SpellCastBuffs.EffectsList[context][abilityId] then
                            SpellCastBuffs.EffectsList[context][abilityId].stack = SpellCastBuffs.EffectsList[context][abilityId].stack - Effects.EffectGroundDisplay[abilityId].stackRemove
                            if SpellCastBuffs.EffectsList[context][abilityId].stack == 0 then SpellCastBuffs.EffectsList[context][abilityId] = nil end
                        end
                    else
                        SpellCastBuffs.EffectsList[context][abilityId] = nil
                    end
                end
            end
        end
    elseif changeType == EFFECT_RESULT_GAINED then

        local currentTime = GetGameTimeMilliseconds()
        g_protectAbilityRemoval[abilityId] = currentTime + 150

        local duration = endTime - beginTime
        local groundLabel = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].groundLabel or false
        local toggle = Effects.IsToggle[abilityId] or false
        iconName = Effects.EffectGroundDisplay[abilityId].icon or iconName
        effectName = Effects.EffectGroundDisplay[abilityId].name or effectName

        for i = 1, 3 do
            if groundType[i].info == true then
                -- Set container context
                local context
                if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName]) then
                    context = groundType[i].promD
                elseif (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
                    context = groundType[i].promB
                else
                    context = groundType[i].context
                end
                if Effects.IsGroundMineAura[abilityId] then
                    stackCount = Effects.EffectGroundDisplay[abilityId].stackReset
                    if Effects.HideGroundMineStacks[abilityId] then
                        stackCount = 0
                    end
                elseif Effects.IsGroundMineStack[abilityId] then
                    if SpellCastBuffs.EffectsList[context][abilityId] then
                        stackCount = SpellCastBuffs.EffectsList[context][abilityId].stack + Effects.EffectGroundDisplay[abilityId].stackRemove
                    else
                        stackCount = 1
                    end
                    if stackCount > Effects.EffectGroundDisplay[abilityId].stackReset then stackCount = Effects.EffectGroundDisplay[abilityId].stackReset end
                end

                SpellCastBuffs.EffectsList[context][abilityId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=groundType[i].type,
                    id=abilityId, name=effectName, icon=iconName,
                    dur=1000*duration, starts=1000*beginTime, ends=(duration > 0) and (1000*endTime) or nil,
                    forced=nil,
                    restart=true, iconNum=0,
                    unbreakable=0,
                    stack = stackCount,
                    buffSlot = effectSlot,
                    groundLabel = groundLabel,
                    toggle = toggle,
                }
            end
        end
    end

end

-- Runs on the EVENT_EFFECT_CHANGED listener.
-- This handler fires every long-term effect added or removed
function SpellCastBuffs.OnEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, castByPlayer)

    --d(effectName .. " - " .. castByPlayer)

    -- Change the effect type / name before we determine if we want to filter anything else.
    if Effects.EffectOverride[abilityId] then
        effectName = Effects.EffectOverride[abilityId].name or effectName
        effectType = Effects.EffectOverride[abilityId].type or effectType
        -- Bail out now if we hide ground snares and other effects because we are showing Damaging Auras (Only do this for the player, we don't want effects on targets to stop showing up).
        if Effects.EffectOverride[abilityId].hideGround and SpellCastBuffs.SV.GroundDamageAura and unitTag == "player" then
            return
        end
    end

    -- Bail out if the abilityId is on the Blacklist Table
    if SpellCastBuffs.SV.BlacklistTable[abilityId] then
        return
    end

    -- Hide effects if chosen in the options menu
    if hidePlayerEffects[abilityId] and unitTag == "player" then
        return
    end

    if hideTargetEffects[abilityId] and unitTag == "reticleover" then
        return
    end

    -- If the source of the buff isn't the player or the buff is not on the AbilityId or AbilityName override list then we don't display it
    if unitTag ~= "player" then
        if effectType == 2 and not (castByPlayer == 1) and not (debuffDisplayOverrideId[abilityId] or Effects.DebuffDisplayOverrideName[effectName]) then
            return
        end
    end

    -- Ignore Siphoner on non-player targets
    if abilityId == 92428 and unitTag == "reticleover" and not IsUnitPlayer('reticleover') then
        return
    end

    -- If this effect isn't a prominent buff or debuff and we have certain buffs set to hidden - then hide those.
    if not (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName] or SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
        if SpellCastBuffs.SV.HidePlayerBuffs and effectType == 1 and unitTag == "player" then
            return
        end
        if SpellCastBuffs.SV.HidePlayerDebuffs and effectType == 2 and unitTag == "player" then
            return
        end
        if SpellCastBuffs.SV.HideTargetBuffs and effectType == 1 and unitTag ~= "player" then
            return
        end
        if SpellCastBuffs.SV.HideTargetDebuffs and effectType == 2 and unitTag ~= "player" then
            return
        end
    end

    local unbreakable = 0

    -- Grim Focus Stack counter
    if Effects.IsGrimFocus[abilityId] or Effects.IsGrimFocusOverride[abilityId] then
        local context
        if unitTag == "player" then
            context = { SpellCastBuffs.EffectsList["player1"], SpellCastBuffs.EffectsList["promb_player"], SpellCastBuffs.EffectsList["promd_player"] }
        else
            context = { SpellCastBuffs.EffectsList["reticleover1"] }
        end

        -- Set stack count when Grim Focus counter changes
        if Effects.IsGrimFocus[abilityId] then
            for _, effectsList in pairs(context) do
                for k, v in pairs(effectsList) do
                    if Effects.IsGrimFocusOverride[v.id] then
                        if changeType == EFFECT_RESULT_FADED then
                            v.stack = 0
                        else
                            v.stack = stackCount
                        end
                    end
                end
            end
        end

        -- Set stack count when Grim Focus duration buff changes
        if Effects.IsGrimFocusOverride[abilityId] then
            for i = 1, GetNumBuffs(unitTag) do
                local _, _, _, _, stack, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
                if Effects.IsGrimFocus[abilityId] then
                    stackCount = stack
                end
            end
        end
    end

    -- Simmering Frenzy Stack counter
    if Effects.IsSimmeringFrenzy[abilityId] or Effects.IsSimmeringFrenzyOverride[abilityId] then
        local context
        if unitTag == "player" then
            context = { SpellCastBuffs.EffectsList["player1"], SpellCastBuffs.EffectsList["promb_player"], SpellCastBuffs.EffectsList["promd_player"] }
        else
            context = { SpellCastBuffs.EffectsList["reticleover1"] }
        end

        -- Set stack count when Grim Focus counter changes
        if Effects.IsSimmeringFrenzy[abilityId] then
            for _, effectsList in pairs(context) do
                for k, v in pairs(effectsList) do
                    if Effects.IsSimmeringFrenzyOverride[v.id] then
                        if changeType == EFFECT_RESULT_FADED then
                            v.stack = 0
                        else
                            v.stack = stackCount
                        end
                    end
                end
            end
        end

        -- Set stack count when Simmering Frenzy duration buff changes
        if Effects.IsSimmeringFrenzyOverride[abilityId] then
            for i = 1, GetNumBuffs(unitTag) do
                local _, _, _, _, stack, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
                if Effects.IsSimmeringFrenzy[abilityId] then
                    stackCount = stack
                end
            end
        end
    end

    -- Set Override data from Effects.lua
    if Effects.EffectOverride[abilityId] then
        if Effects.EffectOverride[abilityId].hide == true then
            return
        end
        if Effects.EffectOverride[abilityId].hideReduce == true and SpellCastBuffs.SV.HideReduce then
            return
        end
        if Effects.EffectOverride[abilityId].isDisguise and SpellCastBuffs.SV.IgnoreDisguise then -- For Monk's Disguise / other buff based Disguise hiding.
            return
        end
        iconName = Effects.EffectOverride[abilityId].icon or iconName
        unbreakable = Effects.EffectOverride[abilityId].unbreakable or 0
        stackCount = Effects.EffectOverride[abilityId].stack or stackCount
        -- Destroy other effects of the same type if we don't want to show duplicates at all.
        if Effects.EffectOverride[abilityId].noDuplicate then
            for context, effectsList in pairs( SpellCastBuffs.EffectsList ) do
                for k, v in pairs(effectsList) do
                    -- Only remove the lower duration effects that were cast previously or simultaneously.
                    if v.id == abilityId and v.ends <= (1000*endTime) then
                        SpellCastBuffs.EffectsList[context][k] = nil
                    end
                end
            end
        end
        -- Bail out if this effect should only appear on Refresh
        if Effects.EffectOverride[abilityId].refreshOnly then
            if changeType ~= EFFECT_RESULT_UPDATED and changeType ~= EFFECT_RESULT_FULL_REFRESH and changeType ~= EFFECT_RESULT_FADED then
                return
            end
        end
    end

    -- Bail out if the effectName is hidden in the Blacklist Table
    if SpellCastBuffs.SV.BlacklistTable[effectName] then
        return
    end

    -- Override name, icon, or hide based on MapZoneIndex
    if Effects.ZoneDataOverride[abilityId] then
        local index = GetZoneId(GetCurrentMapZoneIndex())
        local zoneName = GetPlayerLocationName()
        if Effects.ZoneDataOverride[abilityId][index] then
            if Effects.ZoneDataOverride[abilityId][index].icon then
                iconName = Effects.ZoneDataOverride[abilityId][index].icon
            end
            if Effects.ZoneDataOverride[abilityId][index].name then
                effectName = Effects.ZoneDataOverride[abilityId][index].name
            end
            if Effects.ZoneDataOverride[abilityId][index].hide then
                return
            end
        end
        if Effects.ZoneDataOverride[abilityId][zoneName] then
            if Effects.ZoneDataOverride[abilityId][zoneName].icon then
                iconName = Effects.ZoneDataOverride[abilityId][zoneName].icon
            end
            if Effects.ZoneDataOverride[abilityId][zoneName].name then
                effectName = Effects.ZoneDataOverride[abilityId][zoneName].name
            end
            if Effects.ZoneDataOverride[abilityId][zoneName].hide then
                return
            end
        end
    end

    -- Override name, icon, or hide based on Map Name
    if Effects.MapDataOverride[abilityId] then
        local mapName = GetMapName()
        if Effects.MapDataOverride[abilityId][mapName] then
            if Effects.MapDataOverride[abilityId][mapName].icon then
                iconName = Effects.MapDataOverride[abilityId][mapName].icon
            end
            if Effects.MapDataOverride[abilityId][mapName].name then
                effectName = Effects.MapDataOverride[abilityId][mapName].name
            end
            if Effects.MapDataOverride[abilityId][mapName].hide then
                return
            end
        end
    end

    -- Override name or icon based off unitName
    if Effects.EffectOverrideByName[abilityId] then
        unitName = zo_strformat("<<C:1>>", unitName)
        if Effects.EffectOverrideByName[abilityId][unitName] then
            if Effects.EffectOverrideByName[abilityId][unitName].hide then
                return
            end
            iconName = Effects.EffectOverrideByName[abilityId][unitName].icon or iconName
            effectName = Effects.EffectOverrideByName[abilityId][unitName].name or effectName
        end
    end

    --Override icon with default if enabled
    if SpellCastBuffs.SV.UseDefaultIcon and SpellCastBuffs.ShouldUseDefaultIcon(abilityId) == true then
        iconName = SpellCastBuffs.GetDefaultIcon(Effects.EffectOverride[abilityId].cc)
    end

    local forcedType = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].forcedContainer or nil
    local savedEffectSlot = effectSlot
    effectSlot = Effects.EffectMergeId[abilityId] or Effects.EffectMergeName[effectName] or effectSlot

    -- Where the new icon will go into
    local context = unitTag .. effectType

    -- Override for Off-Balance Immunity to show it as a prominent debuff for tracking.
    if abilityId == 134599 then
        if context == "reticleover1" then
            if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName]) then
                context = "promd_target"
            end
        elseif context == "player1" then
            if (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
                context = "promb_player"
            end
        end
    else
        context = SpellCastBuffs.DetermineContext(context, abilityId, effectName, castByPlayer)
    end

    -- Exit here if there is no container to hold this effect
    if not containerRouting[context] then
        return
    end

    if changeType == EFFECT_RESULT_FADED then -- delete Effect
        SpellCastBuffs.EffectsList[context][effectSlot] = nil
        if Effects.EffectCreateSkillAura[abilityId] and Effects.EffectCreateSkillAura [abilityId].removeOnEnd then
            local id = Effects.EffectCreateSkillAura[abilityId].abilityId

            local name = zo_strformat("<<C:1>>", GetAbilityName(id))
            local fakeEffectType = Effects.EffectOverride[id] and Effects.EffectOverride[id].type or effectType
            if not (SpellCastBuffs.SV.BlacklistTable[name] or SpellCastBuffs.SV.BlacklistTable[id]) then
                local simulatedContext = unitTag .. fakeEffectType
                simulatedContext = SpellCastBuffs.DetermineContext(simulatedContext, id, name, castByPlayer)
                SpellCastBuffs.EffectsList[simulatedContext][Effects.EffectCreateSkillAura[abilityId].abilityId] = nil
            end
        end

    -- Create Effect
    else
        local duration = endTime - beginTime
        local groundLabel = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].groundLabel or false
        local toggle = Effects.IsToggle[abilityId] or false

        if Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].duration then
            if Effects.EffectOverride[abilityId].duration == 0 then
                duration = 0
            else
               duration = duration - Effects.EffectOverride[abilityId].duration
            end
            endTime = endTime - Effects.EffectOverride[abilityId].duration
        end

        -- Outdated and unused - might be useful in the future
        -- Specific override for old version of Mend Spirit -- Updates Major Resolve to use the remaining duration of Mend Spirit.
        --[[
        if Effects.EffectPullDuration[abilityId] then
            local matchId = Effects.EffectPullDuration[abilityId]
            for i = 1, GetNumBuffs(unitTag) do
                local _, timeStarted, timeEnding, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
                if abilityId == matchId then
                    duration = timeEnding - timeStarted
                    beginTime = timeStarted
                    endTime = timeEnding
                end
            end
        end
        ]]--

        --EffectCreateSkillAura
        if Effects.EffectCreateSkillAura[abilityId] then
            if (not Effects.EffectCreateSkillAura[abilityId].requiredStack) or (Effects.EffectCreateSkillAura[abilityId].requiredStack and stackCount == Effects.EffectCreateSkillAura[abilityId].requiredStack) then
                local id = Effects.EffectCreateSkillAura[abilityId].abilityId
                local name = zo_strformat("<<C:1>>", GetAbilityName(id))
                local fakeEffectType = Effects.EffectOverride[id] and Effects.EffectOverride[id].type or effectType
                local fakeUnbreakable = Effects.EffectOverride[id] and Effects.EffectOverride[id].unbreakable or 0
                if not (SpellCastBuffs.SV.BlacklistTable[name] or SpellCastBuffs.SV.BlacklistTable[id]) then
                    local simulatedContext = unitTag .. fakeEffectType
                    simulatedContext = SpellCastBuffs.DetermineContext(simulatedContext, id, name, castByPlayer)

                    -- Create Buff
                    local icon = Effects.EffectCreateSkillAura[abilityId].icon or GetAbilityIcon(id)
                    SpellCastBuffs.EffectsList[simulatedContext][Effects.EffectCreateSkillAura[abilityId].abilityId] = {
                        target=SpellCastBuffs.DetermineTarget(simulatedContext), type=fakeEffectType,
                        id=id, name=name, icon=icon,
                        dur=1000*duration, starts=1000*beginTime, ends=(duration > 0) and (1000*endTime) or nil,
                        forced=forcedType,
                        restart=true, iconNum=0,
                        stack = 0,
                        unbreakable=fakeUnbreakable,
                        groundLabel = groundLabel,
                        toggle = toggle,
                    }
                end
            end
        end

        -- If this effect doesn't properly display stacks - then add them.
        if Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].displayStacks then
            for context, effectsList in pairs( SpellCastBuffs.EffectsList ) do
                for k, v in pairs(effectsList) do
                    -- Add stacks
                    if v.id == abilityId then
                        stackCount = v.stack + 1
                        -- Stop stacks from going over a certain amount.
                        if stackCount > Effects.EffectOverride[abilityId].maxStacks then
                            stackCount = Effects.EffectOverride[abilityId].maxStacks
                        end
                    end
                end
            end
        end

        -- Limit stacks for certain abilities.
        if Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].stackMax then
            if stackCount > Effects.EffectOverride[abilityId].stackMax then
                stackCount = Effects.EffectOverride[abilityId].stackMax
            end
        end

        -- Buffs are created based on their effectSlot, this allows multiple buffs/debuffs of the same type to appear.
        SpellCastBuffs.EffectsList[context][effectSlot] = {
            target=SpellCastBuffs.DetermineTarget(context), type=effectType,
            id=abilityId, name=effectName, icon=iconName,
            dur=1000*duration, starts=1000*beginTime, ends=(duration > 0) and (1000*endTime) or nil,
            forced=forcedType,
            restart=true, iconNum=0,
            stack = stackCount,
            unbreakable=unbreakable,
            buffSlot = savedEffectSlot,
            groundLabel = groundLabel,
            toggle = toggle,
        }
    end
end

-- Runs on the EVENT_ARTIFICIAL_EFFECT_ADDED / EVENT_ARTIFICIAL_EFFECT_REMOVED listener.
-- This handler fires whenever an ArtificialEffectId is added or removed
function SpellCastBuffs.ArtificialEffectUpdate(eventCode, effectId)
    if SpellCastBuffs.SV.HidePlayerBuffs then
        return
    end

    if effectId then
        local removeEffect = effectId
        -- Battle Spirit handling, set this id to a fake id so it matches the target display
        if effectId == 0 or effectId == 2 then
            removeEffect = 999014
        end
        local context = SpellCastBuffs.DetermineContextSimple("player1", removeEffect, displayName)
        SpellCastBuffs.EffectsList[context][removeEffect] = nil
    end

    for effectId in ZO_GetNextActiveArtificialEffectIdIter do
        -- Bail out if we don't have Battle Spirit display for the player on
        if (effectId == 0 or effectId == 2) and SpellCastBuffs.SV.IgnoreBattleSpiritPlayer then
            return
        end

        local displayName, iconFile, effectType, _, startTime = GetArtificialEffectInfo(effectId)
        local duration = 0
        local endTime = nil

        if (effectId == 3) then
            duration = 300000
            startTime = GetGameTimeMilliseconds()
            endTime = startTime + ( GetLFGCooldownTimeRemainingSeconds(LFG_COOLDOWN_BATTLEGROUND_DESERTED) * 1000 )
            effectType = BUFF_EFFECT_TYPE_BUFF -- Set to buff so it shows in long duration effects
        end

        local tooltip = nil
        local artificial = true
        -- Battle Spirit handling, set this id to a fake id so it matches the target display
        if effectId == 0 or effectId == 2 then
            if effectId == 0 then
                tooltip = Tooltips.Innate_Battle_Spirit
            else
                tooltip = Tooltips.Innate_Battle_Spirit_Imperial_City
            end
            effectId = 999014
            artificial = false
        end

        local context = SpellCastBuffs.DetermineContextSimple("player1", effectId, displayName)
        SpellCastBuffs.EffectsList[context][effectId] = {
            target=SpellCastBuffs.DetermineTarget(context), type=effectType,
            id=effectId, name = displayName, icon = iconFile, tooltip = tooltip,
            dur=duration, starts=startTime, ends=endTime,
            forced="long",
            restart=true, iconNum=0,
            artificial = artificial,
        }
    end
end

--[[
 * Runs on the EVENT_COMBAT_EVENT listener.
 * This handler fires every time ANY combat activity happens. Very-very often.
 * We use it to remove mines from active target debuffs
 * As well as create fake buffs/debuffs for events with no active effect present.
 ]]--

-- Counter variable for ACTION_RESULT_EFFECT_GAINED / ACTION_RESULT_EFFECT_FADED tracking for some buffs that are broken
-- Handles buffs that rather than refreshing on reapplication create an individual instance and therefore have GAINED/FADED events every single time the effect ticks.
local InternalStackCounter = { }

-- Combat Event - Add Name Aura to Target
function SpellCastBuffs.OnCombatAddNameEvent( eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId )
    -- Get the name of the target to apply the buff to
    local name = Effects.AddNameOnEvent[abilityId].name
    local id = Effects.AddNameOnEvent[abilityId].id
    -- Bail out if we have no name
    if not name then return end

    -- NOTE: We may eventually need to iterate here, for the time being though we can just relatively reliably put this in slot 2 since slot 1 should be CC Immunity.
    -- NOTE: We may eventually add a function handler to do other things, like make certain abilities change their CC types etc like the example below.
    if Effects.AddNameAura[name] then
        if result == ACTION_RESULT_EFFECT_GAINED then
            -- Get stack value if its saved.
            local stack = Effects.AddNameAura[name][2] and Effects.AddNameAura[name][2].stack
            Effects.AddNameAura[name][2] = {}
            Effects.AddNameAura[name][2].id = id
            if Effects.AddStackOnEvent[abilityId] then
                if stack then
                    Effects.AddNameAura[name][2].stack = stack + 1
                else
                    Effects.AddNameAura[name][2].stack = Effects.AddStackOnEvent[abilityId]
                end
            end
            -- Specific to Crypt of Hearts I (Ignite Colossus)
            if id == 46680 then
                LUIE.Data.AlertTable[22527].cc = LUIE_CC_TYPE_UNBREAKABLE
                LUIE.Data.AlertTable[22527].block = nil
                LUIE.Data.AlertTable[22527].dodge = nil
                LUIE.Data.AlertTable[22527].avoid = true
            end
        elseif result == ACTION_RESULT_EFFECT_FADED then
            -- Check to make sure the current added aura here is the same id. If something else overrides the previous one we don't need to worry about removing the previous one.
            if Effects.AddNameAura[name] and Effects.AddNameAura[name][2] and Effects.AddNameAura[name][2].id == id then
                Effects.AddNameAura[name][2] = nil
                -- Specific to Crypt of Hearts I (Ignite Colossus)
                if id == 46680 then
                    LUIE.Data.AlertTable[22527].cc = nil
                    LUIE.Data.AlertTable[22527].block = true
                    LUIE.Data.AlertTable[22527].dodge = true
                    LUIE.Data.AlertTable[22527].avoid = false
                end
            end
        end

        -- Reload Effects on current target
        if not SpellCastBuffs.SV.HideTargetBuffs then
            SpellCastBuffs.AddNameAura()
        end
    end
end

-- EVENT_BOSSES_CHANGED handler
function SpellCastBuffs.AddNameOnBossEngaged(eventCode)

    -- Clear any names we've added this way
    for k, _ in pairs(Effects.AddNameOnBossEngaged) do
        for name, _ in pairs(Effects.AddNameOnBossEngaged[k]) do
            if Effects.AddNameAura[name] then
                Effects.AddNameAura[name] = nil
            end
        end
    end

    -- Check for bosses and add name auras when engaged.
    for i = 1, 4 do
        local bossName = DoesUnitExist('boss' .. i) and zo_strformat("<<C:1>>", GetUnitName('boss' .. i)) or ""
        if Effects.AddNameOnBossEngaged[bossName] then
            for k, v in pairs(Effects.AddNameOnBossEngaged[bossName]) do
                Effects.AddNameAura[k] = {}
                Effects.AddNameAura[k][1] = {}
                Effects.AddNameAura[k][1].id = v
            end
        end
    end

    -- Reload Effects on current target
    if not SpellCastBuffs.SV.HideTargetBuffs then
        SpellCastBuffs.AddNameAura()
    end
end

-- Called from EVENT_PLAYER_ACTIVATED
function SpellCastBuffs.AddZoneBuffs()

    local zoneId = GetZoneId(GetCurrentMapZoneIndex())
    if Effects.ZoneBuffs[zoneId] then
        local abilityId = Effects.ZoneBuffs[zoneId]
        local abilityName = GetAbilityName(abilityId)
        local abilityIcon = GetAbilityIcon(abilityId)
        local beginTime = GetGameTimeMilliseconds()

        local context = SpellCastBuffs.DetermineContextSimple("player1", abilityId, abilityName)
        SpellCastBuffs.EffectsList["player1"][abilityId] = {
            target=SpellCastBuffs.DetermineTarget(context), type=1,
            id=abilityId, name=abilityName, icon=abilityIcon,
            dur=0, starts=beginTime, ends=nil,
            forced = "long",
            restart=true, iconNum=0,
            unbreakable=0,
            stack = stack,
            groundLabel = groundLabel,
            toggle = toggle,
        }
    end

end

 -- Combat Event (Target = Player)
function SpellCastBuffs.OnCombatEventIn( eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId )
    if not (Effects.FakeExternalBuffs[abilityId] or Effects.FakeExternalDebuffs[abilityId] or Effects.FakePlayerBuffs[abilityId] or Effects.FakeStagger[abilityId] or Effects.AddGroundDamageAura[abilityId]) then
        return
    end

    -- If the ability is blacklisted
    if SpellCastBuffs.SV.BlacklistTable[abilityId] or SpellCastBuffs.SV.BlacklistTable[abilityName] then
        return
    end

    -- Create ground auras for damaging effects if toggled on
    if SpellCastBuffs.SV.GroundDamageAura and Effects.AddGroundDamageAura[abilityId] then
        -- Return if this isn't damage or healing, or blocked, dodged, or shielded.
        if result ~= ACTION_RESULT_DAMAGE and
           result ~= ACTION_RESULT_DAMAGE_SHIELDED and
           result ~= ACTION_RESULT_DODGED and
           result ~= ACTION_RESULT_CRITICAL_DAMAGE and
           result ~= ACTION_RESULT_CRITICAL_HEAL and
           result ~= ACTION_RESULT_HEAL and
           result ~= ACTION_RESULT_BLOCKED and
           result ~= ACTION_RESULT_BLOCKED_DAMAGE and
           result ~= ACTION_RESULT_HOT_TICK and
           result ~= ACTION_RESULT_HOT_TICK_CRITICAL and
           result ~= ACTION_RESULT_DOT_TICK and
           result ~= ACTION_RESULT_DOT_TICK_CRITICAL and
           not Effects.AddGroundDamageAura[abilityId].exception then
            return
        end

        -- Only allow exceptions through if flagged as such
        if Effects.AddGroundDamageAura[abilityId].exception and result ~= Effects.AddGroundDamageAura[abilityId].exception then
            return
        end

        local iconName = GetAbilityIcon(abilityId)
        local effectName
        local unbreakable
        local duration = Effects.AddGroundDamageAura[abilityId].duration
        local effectType = Effects.AddGroundDamageAura[abilityId].type
        local buffSlot
        local groundLabel = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].groundLabel or false
        local toggle = Effects.IsToggle[abilityId] or false

        if Effects.EffectOverride[abilityId] then
            effectName = Effects.EffectOverride[abilityId].name or abilityName
            unbreakable = Effects.EffectOverride[abilityId].unbreakable or 0
            stack = Effects.EffectOverride[abilityId].stack or 0
        else
            effectName = abilityName
            unbreakable = 0
            stack = 0
        end

        -- Override name, icon, or hide based on MapZoneIndex
        if Effects.ZoneDataOverride[abilityId] then
            local index = GetZoneId(GetCurrentMapZoneIndex())
            local zoneName = GetPlayerLocationName()
            if Effects.ZoneDataOverride[abilityId][index] then
                if Effects.ZoneDataOverride[abilityId][index].icon then
                    iconName = Effects.ZoneDataOverride[abilityId][index].icon
                end
                if Effects.ZoneDataOverride[abilityId][index].name then
                    effectName = Effects.ZoneDataOverride[abilityId][index].name
                end
                if Effects.ZoneDataOverride[abilityId][index].hide then
                    return
                end
            end
            if Effects.ZoneDataOverride[abilityId][zoneName] then
                if Effects.ZoneDataOverride[abilityId][zoneName].icon then
                    iconName = Effects.ZoneDataOverride[abilityId][zoneName].icon
                end
                if Effects.ZoneDataOverride[abilityId][zoneName].name then
                    effectName = Effects.ZoneDataOverride[abilityId][zoneName].name
                end
                if Effects.ZoneDataOverride[abilityId][zoneName].hide then
                    return
                end
            end
        end

        -- Override name, icon, or hide based on Map Name
        if Effects.MapDataOverride[abilityId] then
            local mapName = GetMapName()
            if Effects.MapDataOverride[abilityId][mapName] then
                if Effects.MapDataOverride[abilityId][mapName].icon then
                    iconName = Effects.MapDataOverride[abilityId][mapName].icon
                end
                if Effects.MapDataOverride[abilityId][mapName].name then
                    effectName = Effects.MapDataOverride[abilityId][mapName].name
                end
                if Effects.MapDataOverride[abilityId][mapName].hide then
                    return
                end
            end
        end

        -- Override name or icon based off unitName
        if Effects.EffectOverrideByName[abilityId] then
            local unitName = zo_strformat("<<C:1>>", sourceName)
            if Effects.EffectOverrideByName[abilityId][unitName] then
                if Effects.EffectOverrideByName[abilityId][unitName].hide then
                    if Effects.EffectOverrideByName[abilityId][unitName].zone then
                        local zones = Effects.EffectOverrideByName[abilityId][unitName].zone
                        local index = GetZoneId(GetCurrentMapZoneIndex())
                        for k, v in pairs(zones) do
                            d(k)
                            d(index)
                            if k == index then
                                return
                            end
                        end
                    else
                        return
                    end
                end
                iconName = Effects.EffectOverrideByName[abilityId][unitName].icon or iconName
                effectName = Effects.EffectOverrideByName[abilityId][unitName].name or effectName
            end
        end

        if Effects.AddGroundDamageAura[abilityId].merge then
            buffSlot = "GroundDamageAura" .. tostring(Effects.AddGroundDamageAura[abilityId].merge)
        else
            buffSlot = abilityId
        end

        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local context = "player" .. effectType

        -- Stack Resolution
        if SpellCastBuffs.EffectsList[context][buffSlot] and Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].stackAdd then
            if Effects.EffectOverride[abilityId].stackMax then
                if not (SpellCastBuffs.EffectsList[context][buffSlot].stack == Effects.EffectOverride[abilityId].stackMax) then
                    stack = SpellCastBuffs.EffectsList[context][buffSlot].stack + Effects.EffectOverride[abilityId].stackAdd
                else
                    stack = SpellCastBuffs.EffectsList[context][buffSlot].stack
                end
            else
                stack = SpellCastBuffs.EffectsList[context][buffSlot].stack + Effects.EffectOverride[abilityId].stackAdd
            end
        end

        -- TODO: May need to update this to support prominent
        SpellCastBuffs.EffectsList[context][buffSlot] = {
            target=SpellCastBuffs.DetermineTarget(context), type=effectType,
            id=abilityId, name=effectName, icon=iconName,
            dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
            forced = "short",
            restart=true, iconNum=0,
            unbreakable=unbreakable,
            fakeDuration=true,
            groundLabel = groundLabel,
            toggle = toggle,
            stack = stack,
        }
    end

    -- Special handling for Crystallized Shield + Morphs
    if abilityId == 92068 or abilityId == 92168 or abilityId == 92170 then
        if result == ACTION_RESULT_DAMAGE_SHIELDED then
            local context = "player" .. effectType
            context = SpellCastBuffs.DetermineContext(context, abilityId, effectName)

            if SpellCastBuffs.EffectsList[context][abilityId] then
                SpellCastBuffs.EffectsList[context][abilityId].stack = SpellCastBuffs.EffectsList[context][abilityId].stack - 1
                if SpellCastBuffs.EffectsList[context][abilityId].stack == 0 then
                    SpellCastBuffs.EffectsList[context][abilityId] = nil
                end
            end
        end
    end

    -- If the action result isn't a starting/ending event then we ignore it.
    if (result ~= ACTION_RESULT_BEGIN and result ~= ACTION_RESULT_EFFECT_GAINED and result ~= ACTION_RESULT_EFFECT_GAINED_DURATION and result ~= ACTION_RESULT_EFFECT_FADED) then
        return
    end

    -- Toggled on when we need to ignore double events from some ids
    if g_ignoreAbilityId[abilityId] then
        g_ignoreAbilityId[abilityId] = nil
        return
    end

    local unbreakable
    local stack
    local internalStack
    local iconName
    local effectName
    local duration
    local groundLabel = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].groundLabel or false

    if Effects.EffectOverride[abilityId] then
        if Effects.EffectOverride[abilityId].hideReduce and SpellCastBuffs.SV.HideReduce then
            return
        end
        unbreakable = Effects.EffectOverride[abilityId].unbreakable or 0
        stack = Effects.EffectOverride[abilityId].stack or 0
        internalStack = Effects.EffectOverride[abilityId].internalStack or nil
    else
        unbreakable = 0
        stack = 0
        internalStack = nil
    end

    -- Creates fake buff icons for buffs without an aura - These refresh on reapplication/removal (Applied on player by target)
    if Effects.FakeExternalBuffs[abilityId] and (sourceType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_PLAYER) then
        -- Bail out if we ignore begin events
        if Effects.FakeExternalBuffs[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakeExternalBuffs[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakeExternalBuffs[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HidePlayerBuffs then
            return
        end


        iconName = Effects.FakeExternalBuffs[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakeExternalBuffs[abilityId].name or GetAbilityName(abilityId)
        local context = SpellCastBuffs.DetermineContextSimple("player1", abilityId, effectName)
        SpellCastBuffs.EffectsList[context][abilityId] = nil
        overrideDuration = Effects.FakeExternalBuffs[abilityId].overrideDuration
        duration = Effects.FakeExternalBuffs[abilityId].duration
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        if source ~= "" and target == LUIE.PlayerNameFormatted then
            SpellCastBuffs.EffectsList[context][abilityId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=1,
                id=abilityId, name=effectName, icon=iconName,
                dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                forced = "short",
                restart=true, iconNum=0,
                unbreakable=unbreakable,
                fakeDuration = overrideDuration,
                groundLabel = groundLabel,
            }
        end
    end

    -- Creates fake debuff icons for debuffs without an aura - These refresh on reapplication/removal (Applied on player by target)
    if Effects.FakeExternalDebuffs[abilityId] and (sourceType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_PLAYER) then
        -- Bail out if we ignore begin events
        if Effects.FakeExternalDebuffs[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakeExternalDebuffs[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakeExternalDebuffs[abilityId].ignoreFade == true and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HidePlayerDebuffs then
            return
        end
        -- Bail out if we hide ground snares/etc to replace them with auras for damage
        if SpellCastBuffs.SV.GroundDamageAura and Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].hideGround then
            return
        end

        local context = "player2"

        -- Stack handling
        if SpellCastBuffs.EffectsList[context][abilityId] and Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].stackAdd then -- Before removing old effect, if this effect is currently present and stack is set to increment on event, then add to stack counter
            if Effects.EffectOverride[abilityId].stackMax then
                if not (SpellCastBuffs.EffectsList[context][abilityId].stack == Effects.EffectOverride[abilityId].stackMax) then
                    stack = SpellCastBuffs.EffectsList[context][abilityId].stack + Effects.EffectOverride[abilityId].stackAdd
                else
                    stack = SpellCastBuffs.EffectsList[context][abilityId].stack
                end
            else
                stack = SpellCastBuffs.EffectsList[context][abilityId].stack + Effects.EffectOverride[abilityId].stackAdd
            end
        end

        if internalStack then
            if not InternalStackCounter[abilityId] then InternalStackCounter[abilityId] = 0 end -- Create stack if it doesn't exist
            if result == ACTION_RESULT_EFFECT_FADED then
                InternalStackCounter[abilityId] = InternalStackCounter[abilityId] - 1
            elseif result == ACTION_RESULT_EFFECT_GAINED_DURATION then
                InternalStackCounter[abilityId] = InternalStackCounter[abilityId] + 1
            end
            if SpellCastBuffs.EffectsList[context][abilityId] then
                if InternalStackCounter[abilityId] <= 0 then
                    SpellCastBuffs.EffectsList[context][abilityId] = nil
                    InternalStackCounter[abilityId] = nil
                end
            end
        else
            SpellCastBuffs.EffectsList[context][abilityId] = nil
        end

        iconName = Effects.FakeExternalDebuffs[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakeExternalDebuffs[abilityId].name or GetAbilityName(abilityId)
        duration = Effects.FakeExternalDebuffs[abilityId].duration
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)

        if Effects.ZoneDataOverride[abilityId] then
            local index = GetZoneId(GetCurrentMapZoneIndex())
            local zoneName = GetPlayerLocationName()
            if Effects.ZoneDataOverride[abilityId][index] then
                if Effects.ZoneDataOverride[abilityId][index].icon then
                    iconName = Effects.ZoneDataOverride[abilityId][index].icon
                end
                if Effects.ZoneDataOverride[abilityId][index].name then
                    effectName = Effects.ZoneDataOverride[abilityId][index].name
                end
                if Effects.ZoneDataOverride[abilityId][index].hide then
                    return
                end
            end
            if Effects.ZoneDataOverride[abilityId][zoneName] then
                if Effects.ZoneDataOverride[abilityId][zoneName].icon then
                    iconName = Effects.ZoneDataOverride[abilityId][zoneName].icon
                end
                if Effects.ZoneDataOverride[abilityId][zoneName].name then
                    effectName = Effects.ZoneDataOverride[abilityId][zoneName].name
                end
                if Effects.ZoneDataOverride[abilityId][zoneName].hide then
                    return
                end
            end
        end

        -- Override name, icon, or hide based on Map Name
        if Effects.MapDataOverride[abilityId] then
            local mapName = GetMapName()
            if Effects.MapDataOverride[abilityId][mapName] then
                if Effects.MapDataOverride[abilityId][mapName].icon then
                    iconName = Effects.MapDataOverride[abilityId][mapName].icon
                end
                if Effects.MapDataOverride[abilityId][mapName].name then
                    effectName = Effects.MapDataOverride[abilityId][mapName].name
                end
                if Effects.MapDataOverride[abilityId][mapName].hide then
                    return
                end
            end
        end

        --Override icon with default if enabled
        if SpellCastBuffs.SV.UseDefaultIcon and SpellCastBuffs.ShouldUseDefaultIcon(abilityId) == true then
            iconName = SpellCastBuffs.GetDefaultIcon(Effects.EffectOverride[abilityId].cc)
        end

        -- TODO: Temp - converts icon for Helljoint, might be other abilities that need this in the future
        if abilityId == 14523 then
            if source == "Jackal" then
                iconName = 'LuiExtended/media/icons/abilities/ability_jackal_helljoint.dds'
            end
        end

        if source ~= "" and target == LUIE.PlayerNameFormatted then
            SpellCastBuffs.EffectsList[context][abilityId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=BUFF_EFFECT_TYPE_DEBUFF,
                id=abilityId, name=effectName, icon=iconName,
                dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                forced = "short",
                restart=true, iconNum=0,
                unbreakable=unbreakable,
                groundLabel = groundLabel,
                stack = stack,
            }
        end
    end

    -- Creates fake buff icons for buffs without an aura - These refresh on reapplication/removal (Applied on player by player)
    if Effects.FakePlayerBuffs[abilityId] and (sourceType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_PLAYER) then
         -- Bail out if we ignore begin events
        if Effects.FakePlayerBuffs[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakePlayerBuffs[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakePlayerBuffs[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HidePlayerBuffs and not (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName] or SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
            return
        end
        if Effects.FakePlayerBuffs[abilityId].onlyExtra and not SpellCastBuffs.SV.ExtraBuffs then
            return
        end
        if Effects.FakePlayerBuffs[abilityId].onlyExtended and not (SpellCastBuffs.SV.ExtraBuffs and SpellCastBuffs.SV.ExtraExpanded) then
            return
        end

        -- If this is a fake set ICD then don't display if we have Set ICD's disabled.
        if Effects.IsSetICD[abilityId] and SpellCastBuffs.SV.IgnoreSetICDPlayer then return end

        -- Prominent Support
        local effectType = Effects.FakePlayerBuffs[abilityId].debuff and BUFF_EFFECT_TYPE_DEBUFF or BUFF_EFFECT_TYPE_BUFF -- TODO: Expand this for below instead of calling again
        local context = "player" .. effectType

        if SpellCastBuffs.EffectsList[context][abilityId] and Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].stackAdd then -- Before removing old effect, if this effect is currently present and stack is set to increment on event, then add to stack counter
            stack = SpellCastBuffs.EffectsList[context][abilityId].stack + Effects.EffectOverride[abilityId].stackAdd
        end
        if abilityId == 26406 then g_ignoreAbilityId[abilityId] = true end

        local toggle = Effects.IsToggle[abilityId] or false

        iconName = Effects.FakePlayerBuffs[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakePlayerBuffs[abilityId].name or GetAbilityName(abilityId)
        duration = Effects.FakePlayerBuffs[abilityId].duration
        if duration == "GET" then duration = GetAbilityDuration(abilityId) end
        local finalId = Effects.FakePlayerBuffs[abilityId].shiftId or abilityId
        if Effects.FakePlayerBuffs[abilityId].shiftId then
            iconName = Effects.FakePlayerBuffs[finalId] and Effects.FakePlayerBuffs[finalId].icon or GetAbilityIcon(finalId)
            effectName = Effects.FakePlayerBuffs[finalId] and Effects.FakePlayerBuffs[finalId].name or GetAbilityName(finalId)
        end
        -- TODO: Do we want to enable self debuffs from this to show as prominent (ICD for sets for example?)
        context = SpellCastBuffs.DetermineContextSimple(context, finalId, effectName)
        SpellCastBuffs.EffectsList[context][finalId] = nil
        local forcedType = Effects.FakePlayerBuffs[abilityId].long and "long" or "short"
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        -- Pull unbreakable info from Shift Id if present
        unbreakable = (Effects.EffectOverride[finalId] and Effects.EffectOverride[finalId].unbreakable) or unbreakable
        if source == LUIE.PlayerNameFormatted and target == LUIE.PlayerNameFormatted then
            SpellCastBuffs.EffectsList[context][finalId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=effectType,
                id=finalId, name=effectName, icon=iconName,
                dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                forced = forcedType,
                restart=true, iconNum=0,
                unbreakable=unbreakable,
                stack = stack,
                groundLabel = groundLabel,
                toggle = toggle,
            }
        end
    end

    -- Simulates fake debuff icons for stagger effects - works for both (target -> player) and (player -> target) - DOES NOT REFRESH - Only expiration condition is the timer
    if Effects.FakeStagger[abilityId] then
        -- Bail out if we ignore begin events
        if Effects.FakeStagger[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakeStagger[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakeStagger[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HidePlayerDebuffs then
            return
        end
        iconName = Effects.FakeStagger[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakeStagger[abilityId].name or GetAbilityName(abilityId)
        duration = Effects.FakeStagger[abilityId].duration
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        local unitName = zo_strformat("<<C:1>>", GetUnitName("reticleover") )
        local context = "player2"
        if source ~= "" and target == LUIE.PlayerNameFormatted then
            SpellCastBuffs.EffectsList[context][abilityId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=BUFF_EFFECT_TYPE_DEBUFF,
                id=abilityId, name=effectName, icon=iconName,
                dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                forced = "short",
                restart=true, iconNum=0,
                unbreakable=unbreakable,
                groundLabel = groundLabel,
            }
        end
    end
end

 -- Combat Event (Source = Player)
function SpellCastBuffs.OnCombatEventOut( eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId )
    if targetType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_PLAYER_PET then
        return
    end

    -- If the ability is blacklisted
    if SpellCastBuffs.SV.BlacklistTable[abilityId] or SpellCastBuffs.SV.BlacklistTable[abilityName] then
        return
    end

    if not (Effects.FakePlayerOfflineAura[abilityId] or Effects.FakePlayerDebuffs[abilityId] or Effects.FakeStagger[abilityId]) then
        return
    end

    -- If the action result isn't a starting/ending event then we ignore it.
    if result ~= ACTION_RESULT_BEGIN and result ~= ACTION_RESULT_EFFECT_GAINED and result ~= ACTION_RESULT_EFFECT_GAINED_DURATION and result ~= ACTION_RESULT_EFFECT_FADED then
        return
    end

    local unbreakable
    local stack
    local iconName
    local effectName
    local duration
    local effectType
    local groundLabel = Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].groundLabel or false

    if Effects.EffectOverride[abilityId] then
        if Effects.EffectOverride[abilityId].hideReduce and SpellCastBuffs.SV.HideReduce then return end
        unbreakable = Effects.EffectOverride[abilityId].unbreakable or 0
        stack = Effects.EffectOverride[abilityId].stack or 0
    else
        unbreakable = 0
        stack = 0
    end

    -- Fake offline auras created by the player
    if Effects.FakePlayerOfflineAura[abilityId] and sourceType == COMBAT_UNIT_TYPE_PLAYER then
         -- Bail out if we ignore begin events
        if Effects.FakePlayerOfflineAura[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakePlayerOfflineAura[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakePlayerOfflineAura[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HidePlayerBuffs and not (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName] or SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName] or Effects.FakePlayerOfflineAura[abilityId].ground) then
            return
        end

        -- Prominent Support
        local context
        if Effects.FakePlayerOfflineAura[abilityId].ground then
            context = "ground"
        else
            context = "player1"
        end
        if (SpellCastBuffs.SV.PromDebuffTable[abilityId] or SpellCastBuffs.SV.PromDebuffTable[effectName]) then
            context = "promd_player"
        elseif (SpellCastBuffs.SV.PromBuffTable[abilityId] or SpellCastBuffs.SV.PromBuffTable[effectName]) then
            context = "promb_player"
        end

        if SpellCastBuffs.EffectsList[context][abilityId] and Effects.EffectOverride[abilityId] and Effects.EffectOverride[abilityId].stackAdd then -- Before removing old effect, if this effect is currently present and stack is set to increment on event, then add to stack counter
            stack = SpellCastBuffs.EffectsList[context][abilityId].stack + Effects.EffectOverride[abilityId].stackAdd
        end

        SpellCastBuffs.EffectsList[context][abilityId] = nil

        local toggle = Effects.IsToggle[abilityId] or false

        iconName = Effects.FakePlayerOfflineAura[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakePlayerOfflineAura[abilityId].name or GetAbilityName(abilityId)
        duration = Effects.FakePlayerOfflineAura[abilityId].duration
        if duration == "GET" then duration = GetAbilityDuration(abilityId) end
        local finalId = Effects.FakePlayerOfflineAura[abilityId].shiftId or abilityId
        if Effects.FakePlayerOfflineAura[abilityId].shiftId then
            iconName = Effects.FakePlayerOfflineAura and Effects.FakePlayerOfflineAura[finalId].icon or GetAbilityIcon(finalId)
            effectName = Effects.FakePlayerOfflineAura and Effects.FakePlayerOfflineAura[finalId].name or GetAbilityName(finalId)
        end
        local forcedType = Effects.FakePlayerOfflineAura[abilityId].long and "long" or "short"
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        -- Pull unbreakable info from Shift Id if present
        unbreakable = Effects.EffectOverride[finalId].unbreakable or unbreakable
        if source == LUIE.PlayerNameFormatted then
            -- If the "buff" is flagged as a debuff, then display it here instead
            if Effects.FakePlayerOfflineAura[abilityId].ground == true then
                SpellCastBuffs.EffectsList[context][finalId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=BUFF_EFFECT_TYPE_DEBUFF,
                    id=finalId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = "short",
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    stack = stack,
                    groundLabel = groundLabel,
                    toggle = toggle,
                }
            -- Otherwise, display as a normal buff
            else
                SpellCastBuffs.EffectsList[context][finalId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=1,
                    id=finalId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = forcedType,
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    stack = stack,
                    groundLabel = groundLabel,
                    toggle = toggle,
                }
            end
        end
    end

    -- Creates fake debuff icons for debuffs without an aura - These refresh on reapplication/removal (Applied on target by player)
    if Effects.FakePlayerDebuffs[abilityId] and (sourceType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_PLAYER) then
        -- Bail out if we ignore begin events
        if Effects.FakePlayerDebuffs[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakePlayerDebuffs[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakePlayerDebuffs[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HideTargetDebuffs then
            return
        end
        if not DoesUnitExist("reticleover") then end
        --if GetUnitReaction("reticleover") ~= UNIT_REACTION_HOSTILE then return end
        if IsUnitDead(unitTag) then return end
        iconName = Effects.FakePlayerDebuffs[abilityId].icon or GetAbilityIcon(abilityId)

        --Override icon with default if enabled
        if SpellCastBuffs.SV.UseDefaultIcon and SpellCastBuffs.ShouldUseDefaultIcon(abilityId) == true then
            iconName = SpellCastBuffs.GetDefaultIcon(Effects.EffectOverride[abilityId].cc)
        end

        effectName = Effects.FakePlayerDebuffs[abilityId].name or GetAbilityName(abilityId)
        local context = "reticleover2" -- NOTE: TODO - No prominent support here and probably won't add
        duration = Effects.FakePlayerDebuffs[abilityId].duration
        overrideDuration = Effects.FakePlayerDebuffs[abilityId].overrideDuration
        effectType = BUFF_EFFECT_TYPE_DEBUFF
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        local unitName = zo_strformat("<<C:1>>", GetUnitName("reticleover") )
        --if unitName ~= target then return end
        if source == LUIE.PlayerNameFormatted and target ~= nil then
            if SpellCastBuffs.SV.HideTargetDebuffs then
                return
            end
            if unitName == target then
                SpellCastBuffs.EffectsList["ground"][abilityId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=effectType,
                    id=abilityId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = "short",
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    savedName = zo_strformat("<<C:1>>", targetName),
                    fakeDuration = overrideDuration,
                    groundLabel = groundLabel,
                }
            else
                SpellCastBuffs.EffectsList["saved"][abilityId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=effectType,
                    id=abilityId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = "short",
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    savedName = zo_strformat("<<C:1>>", targetName),
                    fakeDuration = overrideDuration,
                    groundLabel = groundLabel,
                }
            end
        end
    end

    -- Simulates fake debuff icons for stagger effects - works for both (target -> player) and (player -> target) - DOES NOT REFRESH - Only expiration condition is the timer
    if Effects.FakeStagger[abilityId] then
        -- Bail out if we ignore begin events
        if Effects.FakeStagger[abilityId].ignoreBegin and (result == ACTION_RESULT_BEGIN) then
            return
        end
        if Effects.FakeStagger[abilityId].refreshOnly and (result == ACTION_RESULT_BEGIN or result == ACTION_RESULT_EFFECT_GAINED) then
            return
        end
        if Effects.FakeStagger[abilityId].ignoreFade and (result == ACTION_RESULT_FADED or result == ACTION_RESULT_EFFECT_FADED) then
            return
        end
        if SpellCastBuffs.SV.HideTargetDebuffs then
            return
        end
        iconName = Effects.FakeStagger[abilityId].icon or GetAbilityIcon(abilityId)
        effectName = Effects.FakeStagger[abilityId].name or GetAbilityName(abilityId)
        local context = "reticleover2" -- NOTE: TODO - No prominent support here and probably won't add
        duration = Effects.FakeStagger[abilityId].duration
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + duration
        local source = zo_strformat("<<C:1>>",sourceName)
        local target = zo_strformat("<<C:1>>",targetName)
        local unitName = zo_strformat("<<C:1>>", GetUnitName("reticleover") )
        if source == LUIE.PlayerNameFormatted and target ~= nil then
            if SpellCastBuffs.SV.HideTargetDebuffs then
                return
            end
            if unitName == target then
                SpellCastBuffs.EffectsList["ground"][abilityId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=BUFF_EFFECT_TYPE_DEBUFF,
                    id=abilityId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = "short",
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    savedName = zo_strformat("<<C:1>>", targetName),
                    groundLabel = groundLabel,
                }
            else
                SpellCastBuffs.EffectsList["saved"][abilityId] = {
                    target=SpellCastBuffs.DetermineTarget(context), type=BUFF_EFFECT_TYPE_DEBUFF,
                    id=abilityId, name=effectName, icon=iconName,
                    dur=duration, starts=beginTime, ends=(duration > 0) and (endTime) or nil,
                    forced = "short",
                    restart=true, iconNum=0,
                    unbreakable=unbreakable,
                    savedName = zo_strformat("<<C:1>>", targetName),
                    groundLabel = groundLabel,
                }
            end
        end
    end
end

-- Runs on the EVENT_UNIT_DEATH_STATE_CHANGED listener.
-- This handler fires every time a valid unitTag dies or is resurrected
function SpellCastBuffs.OnDeath(eventCode, unitTag, isDead)
    -- Wipe buffs
    if isDead then
        if unitTag == "player" then
            -- Clear all player/ground/prominent containers
            local context = { "player1", "player2", "ground", "promb_ground", "promd_ground", "promb_player", "promd_player" }
            for _, v in pairs(context) do
                SpellCastBuffs.EffectsList[v] = { }
            end

            -- If werewolf is active, reset the icon so it's not removed (otherwise it flashes off for about a second until the trailer function picks up on the fact that no power drain has occurred.
            if SpellCastBuffs.SV.ShowWerewolf and IsWerewolf() then
                SpellCastBuffs.WerewolfState(nil, true, true)
            end
        else
            -- TODO: Do we need to clear prominent target containers here? (Don't think so)
            for effectType = 1, 2 do
                SpellCastBuffs.EffectsList[unitTag .. effectType] = {}
            end
        end
    end
end

-- Runs on the EVENT_DISPOSITION_UPDATE listener.
-- This handler fires when the disposition of a reticleover unitTag changes. We filter for only this case.
function SpellCastBuffs.OnDispositionUpdate(eventCode, unitTag)
    if not SpellCastBuffs.SV.HideTargetBuffs then
        SpellCastBuffs.AddNameAura()
    end
end

-- Runs on the EVENT_TARGET_CHANGE listener.
-- This handler fires every time someone target changes.
-- This function is needed in case the player teleports via Way Shrine
function SpellCastBuffs.OnTargetChange(eventCode, unitTag)
    if unitTag ~= "player" then
        return
    end
    SpellCastBuffs.OnReticleTargetChanged(eventCode)
end

-- Runs on the EVENT_RETICLE_TARGET_CHANGED listener.
-- This handler fires every time the player's reticle target changes
function SpellCastBuffs.OnReticleTargetChanged(eventCode)
    SpellCastBuffs.ReloadEffects("reticleover")
end

-- Used to clear existing .effectsList.unitTag and to request game API to fill it again
function SpellCastBuffs.ReloadEffects(unitTag)

    -- Bail if this isn't reticleover or player
    if unitTag ~= "player" and unitTag ~= "reticleover" then
        return
    end

    -- Clear existing base containers
    for effectType = 1, 2 do
        SpellCastBuffs.EffectsList[unitTag .. effectType] = {}
    end
    -- Clear prominent containers
    if unitTag == "player" then
        local context = { "promb_player", "promb_ground", "promd_player", "promd_ground" }
        for _, v in pairs(context) do
            SpellCastBuffs.EffectsList[v] = { }
        end
    else
        local context = { "promb_target", "promd_target" }
        for _, v in pairs(context) do
            SpellCastBuffs.EffectsList[v] = { }
        end
    end

    -- Stop doing anything else if we moused off a target
    if GetUnitName(unitTag) == "" then
        return
    end

    -- Bail out if the target is dead
    if IsUnitDead(unitTag) then return end

    -- Get unitName to pass to OnEffectChanged
    local unitName = GetRawUnitName(unitTag)
    -- Fill it again
    for i = 1, GetNumBuffs(unitTag) do
        local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo(unitTag, i)
        -- Fudge this value to send to SpellCastBuffs.OnEffectChanged if this is a debuff
        if castByPlayer == true then
            castByPlayer = 1
        else
            castByPlayer = 5
        end
        SpellCastBuffs.OnEffectChanged(0, 3, buffSlot, buffName, unitTag, timeStarted, timeEnding, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, unitName, 0--[[unitId]], abilityId, castByPlayer)
    end
    -- Display Disguise State (note that this function handles filtering player/target buffs if hidden)
    SpellCastBuffs.DisguiseStateChanged(nil, unitTag, GetUnitDisguiseState(unitTag))
    -- Display Stealth State (note that this function handles filtering player/target buffs if hidden)
    SpellCastBuffs.StealthStateChanged(nil, unitTag, GetUnitStealthState(unitTag))

    -- Player Specific
    if unitTag == "player" and not SpellCastBuffs.SV.HidePlayerBuffs then
        -- Display Assistant/Non-Combat Pet/Mount Icon
        SpellCastBuffs.CollectibleBuff()
        SpellCastBuffs.MountStatus("", true)
        -- Display Disguise Icon (if disguised)
        if not SpellCastBuffs.SV.IgnoreDisguise then
            SpellCastBuffs.SetDisguiseItem()
        end
        -- Update Artificial Effects
        SpellCastBuffs.ArtificialEffectUpdate()
        -- Display Recall Cooldown
        if SpellCastBuffs.SV.ShowRecall and not SpellCastBuffs.SV.HidePlayerDebuffs then
            SpellCastBuffs.ShowRecallCooldown()
        end
    end

    -- Target Specific
    if unitTag == "reticleover" and not SpellCastBuffs.SV.HideTargetBuffs then
        -- Handle FAKE DEBUFFS between targets
        SpellCastBuffs.RestoreSavedFakeEffects()
        -- Add Name Auras
        SpellCastBuffs.AddNameAura()
        -- Display Battle Spirit
        SpellCastBuffs.LoadBattleSpiritTarget()
    end
end

-- Called by SpellCastBuffs.ReloadEffects - Displays recall cooldown
function SpellCastBuffs.ShowRecallCooldown()
    local recallRemain, _ = GetRecallCooldown()
    if recallRemain > 0 then
        local currentTime = GetGameTimeMilliseconds()
        local abilityId = 999016
        local abilityName = Abilities.Innate_Recall_Penalty
        local context = SpellCastBuffs.DetermineContextSimple("player1", abilityId, abilityName)
        SpellCastBuffs.EffectsList[context][abilityName] = {
            target=SpellCastBuffs.DetermineTarget(context), type=1,
            id=abilityId, name=abilityName, icon='LuiExtended/media/icons/abilities/ability_innate_recall_cooldown.dds',
            dur=600000, starts=currentTime, ends=currentTime+recallRemain,
            forced = "long",
            restart=true, iconNum=0,
            -- unbreakable=1 -- TODO: Maybe re-enable this? It makes prominent show as unbreakable blue since its a buff technically
        }
    end
end

-- Called by EVENT_RETICLE_TARGET_CHANGED listener - Saves active FAKE debuffs on enemies and moves them back and forth between the active container or hidden.
function SpellCastBuffs.RestoreSavedFakeEffects()
    -- Restore Ground Effects
    for _, effectsList in pairs( {SpellCastBuffs.EffectsList["ground"], SpellCastBuffs.EffectsList["saved"]} ) do
        --local container = containerRouting[context]
        for k, v in pairs(effectsList) do
            if v.savedName ~= nil then
                local unitName = zo_strformat("<<C:1>>", GetUnitName('reticleover'))
                if unitName == v.savedName then
                    if SpellCastBuffs.EffectsList["saved"][k] then
                        SpellCastBuffs.EffectsList["ground"][k] = SpellCastBuffs.EffectsList["saved"][k]
                        SpellCastBuffs.EffectsList["ground"][k].iconNum = 0
                        SpellCastBuffs.EffectsList["saved"][k] = nil
                    end
                else
                    if SpellCastBuffs.EffectsList["ground"][k] then
                        SpellCastBuffs.EffectsList["saved"][k] = SpellCastBuffs.EffectsList["ground"][k]
                        SpellCastBuffs.EffectsList["ground"][k] = nil
                    end
                end
            end
        end
    end
end

-- Called by EVENT_RETICLE_TARGET_CHANGED listener - Displays fake buffs based off unitName (primarily for displaying Boss Immunities)
function SpellCastBuffs.AddNameAura()
    local unitName = GetUnitName('reticleover')
    -- We need to check to make sure the mob is not dead, and also check to make sure the unitTag is not the player (just in case someones name exactly matches that of a boss NPC)
    if Effects.AddNameAura[unitName] and GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE and not IsUnitPlayer('reticleover') and not IsUnitDead('reticleover') then
        for k, v in ipairs(Effects.AddNameAura[unitName]) do
            local abilityName = GetAbilityName(v.id)
            local abilityIcon = GetAbilityIcon(v.id)

            -- Bail out if this ability is blacklisted
            if SpellCastBuffs.SV.BlacklistTable[v.id] or SpellCastBuffs.SV.BlacklistTable[abilityName] then
                return
            end

            stack = v.stack or 0

            local zone = v.zone
            if zone then
                local flag = false
                for k, v in pairs(zone) do
                    if GetZoneId(GetCurrentMapZoneIndex()) == k then
                        flag = true
                    end
                end
                if not flag then return end
            end

            local buffType = v.debuff or 1
            local context = v.debuff and "reticleover2" or "reticleover1"
            context = SpellCastBuffs.DetermineContext(context, abilityId, abilityName)
            SpellCastBuffs.EffectsList[context]["Name Specific Buff" .. k] = {
                target=SpellCastBuffs.DetermineTarget(context), type=buffType,
                id= v.id, name= abilityName, icon= abilityIcon,
                dur=0, starts=1, ends=nil,
                forced = "short",
                restart=true, iconNum=0,
                stack = stack
            }
        end
    end
    -- TODO: Unused, possibly remove. Probably needs some adjustments (type is set to BUFF_EFFECT_TYPE_DEBUFF for example)
    --[[
    if Effects.AddNameAuraAlways[unitName] then
        for k, v in ipairs(Effects.AddNameAuraAlways[unitName]) do
            local abilityName = GetAbilityName(v.id)
            local abilityIcon = GetAbilityIcon(v.id)
            local zone = v.zone
            -- Bail out of there is a zone requirement that is not met.
            if zone and GetZoneId(GetCurrentMapZoneIndex()) ~= zone then
                return
            end
            -- Bail out if this ability is blacklisted
            if SpellCastBuffs.SV.BlacklistTable[v.id] or SpellCastBuffs.SV.BlacklistTable[abilityName] then
                return
            end
            SpellCastBuffs.EffectsList["reticleover2"]["Name Specific Buff" .. k] = {
                target="reticleover", type=BUFF_EFFECT_TYPE_DEBUFF,
                id= v.id, name= abilityName, icon= abilityIcon,
                dur=0, starts=1, ends=nil,
                forced = "short",
                restart=true, iconNum=0
            }
        end
    end
    ]]
end

-- Called by menu to preview icon positions. Simply iterates through all containers other than player_long and adds dummy test buffs into them.
function SpellCastBuffs.MenuPreview()
    local currentTime = GetGameTimeMilliseconds()
    local routing = { "player1", "reticleover1", "promb_player", "player2", "reticleover2", "promd_player" }
    local testEffectDurationList = { 22, 44, 55, 300, 1800000 }
    local abilityId = 999000
    local icon = "/esoui/art/icons/icon_missing.dds"

    for i = 1, 5 do
        for c = 1, 6 do
            local context = routing[c]
            local type = c < 4 and 1 or 2
            local name = ("Test Effect: " .. i )
            local duration = testEffectDurationList[i]
            SpellCastBuffs.EffectsList[context][abilityId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=type,
                id=16415, name=name, icon=icon,
                dur = duration * 1000,
                starts = currentTime,
                ends = currentTime + (duration * 1000),
                forced="short",
                restart=true, iconNum=0,
            }
            abilityId = abilityId + 1
        end
    end
end

-- Helper function to sort buffs
local function buffSort(x, y)
    local xDuration = (x.ends == nil or x.dur == 0 or x.groundLabel or x.toggle) and 0 or x.dur
    local yDuration = (y.ends == nil or y.dur == 0 or y.groundLabel or y.toggle) and 0 or y.dur
    -- Sort toggle effects
    if x.toggle or y.toggle then
        if xDuration == 0 and yDuration == 0 then
            if x.toggle and y.toggle then
                return (x.name < y.name)
            elseif x.toggle and not y.toggle then
                return (xDuration == 0)
            end
        else
            return (xDuration == 0)
        end
    -- Sort permanent/ground effects (might separate these at some point but for now want the sorting function simplified)
    elseif xDuration == 0 and yDuration == 0 then
        return (x.name < y.name)
    -- Both non-permanent
    elseif xDuration ~= 0 and yDuration ~= 0 then
        return (x.starts == y.starts) and (x.name < y.name) or (x.ends > y.ends)
    -- One permanent, one not
    else
        return (xDuration == 0)
    end
end

-- Runs OnUpdate - 100 ms buffer
function SpellCastBuffs.OnUpdate(currentTime)
    -- local currentTime = GetGameTimeMilliseconds()
    local buffsSorted = {}
    local needs_update = {}
    local isProminent = {}
    -- And reset sizes of already existing icons
    for _, container in pairs(containerRouting) do
        needs_update[container] = true
        -- Prepare sort container
        if buffsSorted[container] == nil then
            buffsSorted[container] = {}
        end

        -- Refresh prominent buff labels on each update tick
        if container == "prominentbuffs" or container == "prominentdebuffs" then
            isProminent[container] = true
        end
    end

    -- Filter expired events. and build array for sorting
    for context, effectsList in pairs(SpellCastBuffs.EffectsList) do
        local container = containerRouting[context]
        for k, v in pairs(effectsList) do
            -- Remove effect (that is not permanent and has duration)
            if v.ends ~= nil and v.dur > 0 and v.ends < currentTime then
                effectsList[k] = nil
            -- Or append to correct container
            elseif container then
                -- Add icons to to-be-sorted list only if effect already started
                if v.starts < currentTime then
                    -- Filter Effects
                    -- Always show prominent effects
                    if v.target == "prominent" then
                        table.insert(buffsSorted[container], v)
                    -- If the effect is not flagged as long or 0 duration and flagged to display in short container, then display normally.
                    elseif v.type == 2 or v.forced == "short" or not (v.forced == "long" or v.ends == nil or v.dur == 0) then
                        table.insert(buffsSorted[container], v)
                    -- If the effect is a long term effect on the target then use Long Term Target settings.
                    elseif v.target == "reticleover" and SpellCastBuffs.SV.LongTermEffects_Target then
                        table.insert(buffsSorted[container], v)
                    -- If the effect is a long term effect on the player then use Long Term Player settings.
                    elseif v.target == "player" and SpellCastBuffs.SV.LongTermEffects_Player then
                        -- Choose container for long-term player buffs
                        if SpellCastBuffs.SV.LongTermEffectsSeparate and not (container == "prominentbuffs" or container == "prominentdebuffs") then
                            table.insert(buffsSorted.player_long, v)
                        else
                            table.insert(buffsSorted[container], v)
                        end
                    end
                end
            end
        end
    end

    -- Sort effects in container and draw them on screen
    for _, container in pairs(containerRouting) do
        if needs_update[container] then
            table.sort(buffsSorted[container], buffSort)
            SpellCastBuffs.updateIcons( currentTime, buffsSorted[container], container )
        end
        needs_update[container] = false
    end
    for _, container in pairs(containerRouting) do
        if isProminent then
            SpellCastBuffs.updateBar( currentTime, buffsSorted[container], container )
        end
    end

    -- TODO: Fix implementation if possible
    --[[
    -- Display Block buff for player if enabled
    if SpellCastBuffs.SV.ShowBlockPlayer and not SpellCastBuffs.SV.HidePlayerBuffs then
        if IsBlockActive() and not IsPlayerStunned() then -- Is Block Active returns true when the player is stunned currently.
            local abilityId = 974
            local abilityName = Abilities.Innate_Brace
            local context = SpellCastBuffs.DetermineContextSimple("player1", abilityId, abilityName)
            SpellCastBuffs.EffectsList[context][abilityId] = {
                target=SpellCastBuffs.DetermineTarget(context), type=1,
                id=abilityId, name=abilityName, icon='LuiExtended/media/icons/abilities/ability_innate_block.dds',
                dur=0, starts=currentTime, ends=nil,
                restart=true, iconNum=0,
                forced = "short",
                toggle = true,
            }
        else
            SpellCastBuffs.ClearPlayerBuff(974)
        end
    end
    ]]--

end

function SpellCastBuffs.updateBar(currentTime, sortedList, container)
    local iconsNum = #sortedList
    local istart, iend, istep

    if g_sortDirection[container] then
        if g_sortDirection[container] == "Left to Right" or g_sortDirection[container] == "Bottom to Top" then
            istart, iend, istep = 1, iconsNum, 1
        end
        if g_sortDirection[container] == "Right to Left" or g_sortDirection[container] == "Top to Bottom" then
            istart, iend, istep = iconsNum, 1, -1
        end
    -- Fall back in case for some strange reason the container doesn't exist
    else
        istart, iend, istep = 1, iconsNum, 1
    end

    local index = 0 -- Global icon counter
    for i = istart, iend, istep do
        index = index + 1
        -- Get current buff definition
        local effect = sortedList[i]

        local ground = effect.groundLabel
        local remain = ( effect.ends ~= nil ) and ( effect.ends - currentTime ) or nil
        local buff = uiTlw[container].icons[index]
        local auraStarts = effect.starts or nil
        local auraEnds = effect.ends or nil
        -- Modify recall penalty to show forced max duration
        if effect.id == 999016 then
            auraStarts = auraEnds - 600000
        end

        -- If this isn't a permanent duration buff then update the bar on every tick
        if buff and buff.bar and buff.bar.bar then
            if auraStarts and auraEnds and remain > 0 and not ground then
                buff.bar.bar:SetValue(1 - ((currentTime - auraStarts) / (auraEnds - auraStarts)))
            elseif effect.werewolf then
                buff.bar.bar:SetValue(effect.werewolf)
            else
                buff.bar.bar:SetValue(1)
            end
        end
    end
end

function SpellCastBuffs.updateIcons(currentTime, sortedList, container)

    -- Special workaround for container with player long buffs. We do not need to update it every 100ms, but rather 3 times less often
    if uiTlw[container].skipUpdate then
        uiTlw[container].skipUpdate = uiTlw[container].skipUpdate + 1
        if uiTlw[container].skipUpdate > 1 then
            uiTlw[container].skipUpdate = 0
        else
            return
        end
    end

    local iconsNum = #sortedList
    local istart, iend, istep

    -- Set Sort Direction
    if g_sortDirection[container] then
        if g_sortDirection[container] == "Left to Right" or g_sortDirection[container] == "Bottom to Top" then
            istart, iend, istep = 1, iconsNum, 1
        end
        if g_sortDirection[container] == "Right to Left" or g_sortDirection[container] == "Top to Bottom" then
            istart, iend, istep = iconsNum, 1, -1
        end
    -- Fall back in case there is no sort direction for the container somehow
    else
        istart, iend, istep = 1, iconsNum, 1
    end

    -- Size of icon+padding
    local iconSize = SpellCastBuffs.SV.IconSize + g_padding

    -- Set width of contol that holds icons. This will make alignment automatic
    if uiTlw[container].iconHolder then
        if uiTlw[container].alignVertical then
            uiTlw[container].iconHolder:SetDimensions( 0, iconSize*iconsNum - g_padding )
        else
            uiTlw[container].iconHolder:SetDimensions( iconSize*iconsNum - g_padding, 0 )
        end
    end

    -- Prepare variables for manual alignment of icons
    local row = 0   -- row counter for multi-row placement
    local next_row_break = 1

    -- Iterate over list of sorted icons
    local index = 0 -- Global icon counter
    for i = istart, iend, istep do
        -- Get current buff definition
        local effect = sortedList[i]
        index = index + 1
        -- Check if the icon for buff #index exists otherwise create new icon
        if uiTlw[container].icons[index] == nil then
            uiTlw[container].icons[index] = SpellCastBuffs.CreateSingleIcon(container, uiTlw[container].icons[index-1], effect.type)
        end

        -- Calculate remaining time
        local remain = ( effect.ends ~= nil ) and ( effect.ends - currentTime ) or nil
        local name = ( effect.name ~= nil) and effect.name or nil

        local buff = uiTlw[container].icons[index]

        -- Perform manual alignment
        if not uiTlw[container].iconHolder then
            if iconsNum ~= uiTlw[container].prevIconsCount and index == next_row_break --[[and horizontal orientation of container]] then
                -- Padding of first icon in a row
                local anchor, leftPadding

                if g_alignmentDirection[container] then
                    if g_alignmentDirection[container] == LEFT then
                        anchor = TOPLEFT
                        leftPadding = g_padding
                    elseif g_alignmentDirection[container] == RIGHT then
                        anchor = TOPRIGHT
                        leftPadding = - math.min(uiTlw[container].maxIcons, iconsNum-uiTlw[container].maxIcons*row) * iconSize - g_padding
                    else
                        anchor = TOP
                        leftPadding = - 0.5 * ( math.min(uiTlw[container].maxIcons, iconsNum-uiTlw[container].maxIcons*row) * iconSize - g_padding )
                    end
                else -- Fallback
                    anchor = TOP
                    leftPadding = - 0.5 * ( math.min(uiTlw[container].maxIcons, iconsNum-uiTlw[container].maxIcons*row) * iconSize - g_padding )
                end

                buff:ClearAnchors()
                buff:SetAnchor( TOPLEFT, uiTlw[container], anchor, leftPadding, row*iconSize )
                -- Determine if we need to make next row
                if uiTlw[container].maxIcons then
                    -- If buffs then stack down
                    if container == "player1" or container == "target1" then
                        row = row + 1
                    -- If debuffs then stack up
                    elseif container == "player2"  or container == "target2" then
                        row = row -1
                    end
                    next_row_break = next_row_break + uiTlw[container].maxIcons
                end
            end
        end

        -- If previously this icon was used for different effect, then setup it again
        if effect.iconNum ~= index then
            effect.iconNum = index
            effect.restart = true
            SpellCastBuffs.SetSingleIconBuffType(buff, effect.type, effect.unbreakable, effect.id)

            -- Setup Info for Tooltip function to pull
            buff.effectId = effect.id
            buff.effectName = effect.name
            buff.buffType = effect.type
            buff.buffSlot = effect.buffSlot
            buff.tooltip = effect.tooltip
            buff.isArtificial = effect.artificial
            buff.duration = effect.dur or 0

            if effect.backdrop then
                buff.drop:SetHidden(false)
            else
                buff.drop:SetHidden(true)
            end
            buff.icon:SetTexture(effect.icon)
            buff:SetAlpha(1)
            buff:SetHidden(false)
            if not remain or effect.fakeDuration then
                if effect.toggle then
                    buff.label:SetText("T")
                elseif effect.groundLabel then
                    buff.label:SetText("G")
                else
                    buff.label:SetText(nil)
                end
            end

            if buff.abilityId and effect.id then
                buff.abilityId:SetText(effect.id)
            end

            if buff.name then
                buff.name:SetText(zo_strformat("<<C:1>>", effect.name))
            end

        end

        if effect.stack and effect.stack > 0 then
            buff.stack:SetText( string.format("%s", effect.stack) )
            buff.stack:SetHidden(false)
        else
            buff.stack:SetHidden(true)
        end

        -- For update remaining text. For temporary effects this is not very efficient, but we have not much such effects
        if remain and not effect.fakeDuration then
            if remain > 86400000 then -- more then 1 day
                buff.label:SetText( string.format("%d d", math.floor( remain/86400000 )) )
            elseif remain > 6000000 then -- over 100 minutes - display XXh
                buff.label:SetText( string.format("%dh", math.floor( remain/3600000 )) )
            elseif remain > 600000 then -- over 10 minutes - display XXm
                buff.label:SetText( string.format("%dm", math.floor( remain/60000 )) )
            elseif remain > 60000 or container == "player_long" then
                local m = math.floor( remain/60000 )
                local s = remain/1000 - 60*m
                buff.label:SetText( string.format("%d:%.2d", m, s) )
            else
                buff.label:SetText( string.format(SpellCastBuffs.SV.RemainingTextMillis and "%.1f" or "%.1d", remain/1000) )
            end
        end
        if effect.restart and buff.cd ~= nil then
            -- Modify recall penalty to show forced max duration
            if effect.id == 999016 then
                effect.dur = 600000
            end
            if remain == nil or effect.dur == nil or effect.dur == 0 or effect.fakeDuration then
                buff.cd:StartCooldown(0, 0, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, false )
            else
                buff.cd:StartCooldown(remain, effect.dur, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, false )
                effect.restart = false
            end
        end

        -- Now possibly fade out expiring icon
        if SpellCastBuffs.SV.FadeOutIcons and remain ~= nil and remain < 2000 then
            --buff:SetAlpha( 0.05 + remain/2106 )
            buff:SetAlpha(EaseOutQuad(remain, 0, 1, 2000))
        end
    end

    -- Hide rest of icons
    for i = iconsNum+1, #uiTlw[container].icons do
        uiTlw[container].icons[i]:SetHidden(true)
    end

    -- Save icon number processed to compare in next update iteration
    uiTlw[container].prevIconsCount = iconsNum
end

-- Runs on EVENT_PLAYER_ACTIVATED listener
function SpellCastBuffs.OnPlayerActivated(eventCode)
    g_playerActive = true
    g_playerResurrectStage = nil

    -- Reload Effects
    SpellCastBuffs.ReloadEffects("player")
    SpellCastBuffs.AddNameOnBossEngaged()

    -- Load Zone Specific Buffs
    if not SpellCastBuffs.SV.HidePlayerBuffs then
        SpellCastBuffs.AddZoneBuffs()
    end

    -- Resolve Duel Target
    SpellCastBuffs.DuelStart()

    -- Resolve Mounted icon
    if not SpellCastBuffs.SV.IgnoreMountPlayer and IsMounted() then
        zo_callLater(function() SpellCastBuffs.MountStatus("", true) end, 50)
    end

    -- Resolve Disguise Icon
    if not SpellCastBuffs.SV.IgnoreDisguise then
        zo_callLater(function() SpellCastBuffs.DisguiseItem(nil, BAG_WORN, 10) end, 50)
    end

    -- Resolve Assistant Icon
    if not SpellCastBuffs.SV.IgnorePet or not SpellCastBuffs.SV.IgnoreAssistant then
        zo_callLater(function() SpellCastBuffs.CollectibleBuff() end, 50)
    end

    -- Resolve Werewolf
    if SpellCastBuffs.SV.ShowWerewolf and IsWerewolf() then
        SpellCastBuffs.WerewolfState(nil, true, true)
    end

    -- Sets the player to dead if reloading UI or loading in while dead.
    if IsUnitDead("player") then
        g_playerDead = true
    end
end

-- Runs on the EVENT_PLAYER_DEACTIVATED listener
function SpellCastBuffs.OnPlayerDeactivated(eventCode)
    g_playerActive = false
    g_playerResurrectStage = nil
end

-- Runs on the EVENT_PLAYER_ALIVE listener
function SpellCastBuffs.OnPlayerAlive(eventCode)
    --[[-- If player clicks "Resurrect at Wayshrine", then player is first deactivated, then he is transferred to new position, then he becomes alive (this event) then player is activated again.
    To register resurrection we need to work in this function if player is already active. --]]--
    if not g_playerActive or not g_playerDead then
        return
    end

    g_playerDead = false

    -- This is a good place to reload player buffs, as they were wiped on death
    SpellCastBuffs.ReloadEffects( "player" )

    -- Reload werewolf effects
    if SpellCastBuffs.SV.ShowWerewolf and IsWerewolf() then
        SpellCastBuffs.WerewolfState(nil, true, true)
    end

    -- Start Resurrection Sequence
    g_playerResurrectStage = 1
    --[[If it was self resurrection, then there will be 4 EVENT_VIBRATION:
    First - 600ms, Second - 0ms to switch first one off, Third - 350ms, Fourth - 0ms to switch third one off.
    So now we'll listen in the vibration event and progress g_playerResurrectStage with first 2 events and then on correct third event we'll create a buff. --]]
end

-- Runs on the EVENT_PLAYER_DEAD listener
function SpellCastBuffs.OnPlayerDead(eventCode)
    if not g_playerActive then
        return
    end
    g_playerDead = true
end

-- Runs on the EVENT_VIBRATION listener (detects player resurrection stage)
function SpellCastBuffs.OnVibration(eventCode, duration, coarseMotor, fineMotor, leftTriggerMotor, rightTriggerMotor)
    if not g_playerResurrectStage then
        return
    end
    if SpellCastBuffs.SV.HidePlayerBuffs then
        return
    end
    if g_playerResurrectStage == 1 and duration == 600 then
        g_playerResurrectStage = 2
    elseif g_playerResurrectStage == 2 and duration == 0 then
        g_playerResurrectStage = 3
    elseif g_playerResurrectStage == 3 and duration == 350 and SpellCastBuffs.SV.ShowResurrectionImmunity then
        -- We got correct sequence, so let us create a buff and reset the g_playerResurrectStage
        g_playerResurrectStage = nil
        local currentTime = GetGameTimeMilliseconds()
        local abilityId = 14646
        local abilityName = Abilities.Innate_Resurrection_Immunity
        local context = SpellCastBuffs.DetermineContextSimple("player1", abilityId, abilityName)
        SpellCastBuffs.EffectsList[context][abilityId] = {
            target=SpellCastBuffs.DetermineTarget(context), type=1,
            id=abilityId, name=abilityName, icon='LuiExtended/media/icons/abilities/ability_innate_resurrection_immunity.dds',
            dur=10000, starts=currentTime, ends=currentTime+10000,
            restart=true, iconNum=0,
        }
    else
        -- This event does not seem to have anything to do with player self-resurrection
        g_playerResurrectStage = nil
    end
end

-- Called from the menu and on initialize to build the table of hidden effects.
function SpellCastBuffs.UpdateContextHideList()
    hidePlayerEffects = { }
    hideTargetEffects = { }

    if SpellCastBuffs.SV.IgnoreMundusPlayer then
        for k, v in pairs(Effects.IsBoon) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreMundusTarget then
        for k, v in pairs(Effects.IsBoon) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreVampPlayer then
        for k, v in pairs(Effects.IsVamp) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreVampTarget then
        for k, v in pairs(Effects.IsVamp) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreLycanPlayer then
        for k, v in pairs(Effects.IsLycan) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreLycanTarget then
        for k, v in pairs(Effects.IsLycan) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreDiseasePlayer then
        for k, v in pairs(Effects.IsVampLycanDisease) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreDiseaseTarget then
        for k, v in pairs(Effects.IsVampLycanDisease) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreBitePlayer then
        for k, v in pairs(Effects.IsVampLycanBite) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreBiteTarget then
        for k, v in pairs(Effects.IsVampLycanBite) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreCyrodiilPlayer then
        for k, v in pairs(Effects.IsCyrodiil) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreCyrodiilTarget then
        for k, v in pairs(Effects.IsCyrodiil) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreEsoPlusPlayer then
        hidePlayerEffects[63601] = true
    end
    if SpellCastBuffs.SV.IgnoreEsoPlusTarget then
        hideTargetEffects[63601] = true
    end
    if SpellCastBuffs.SV.IgnoreSoulSummonsPlayer then
        for k, v in pairs(Effects.IsSoulSummons) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreSoulSummonsTarget then
        for k, v in pairs(Effects.IsSoulSummons) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreFoodPlayer then
        for k, v in pairs(Effects.IsFoodBuff) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreFoodTarget then
        for k, v in pairs(Effects.IsFoodBuff) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreExperiencePlayer then
        for k, v in pairs(Effects.IsExperienceBuff) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreExperienceTarget then
        for k, v in pairs(Effects.IsExperienceBuff) do
            hideTargetEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreAllianceXPPlayer then
        for k, v in pairs(Effects.IsAllianceXPBuff) do
            hidePlayerEffects[k] = v
        end
    end
    if SpellCastBuffs.SV.IgnoreAllianceXPTarget then
        for k, v in pairs(Effects.IsAllianceXPBuff) do
            hideTargetEffects[k] = v
        end
    end
    if not SpellCastBuffs.SV.ShowBlockPlayer then
        for k, v in pairs(Effects.IsBlock) do
            hidePlayerEffects[k] = v
        end
    end
    if not SpellCastBuffs.SV.ShowBlockTarget then
        for k, v in pairs(Effects.IsBlock) do
            hideTargetEffects[k] = v
        end
    end
end

-- Called from the menu and on initialize to build the table of effects we should show regardless of source (by id).
function SpellCastBuffs.UpdateDisplayOverrideIdList()
    -- Clear the list
    debuffDisplayOverrideId = { }

    -- Add effects from table if enabled
    if SpellCastBuffs.SV.ShowSharedEffects then
        for k, v in pairs(Effects.DebuffDisplayOverrideId) do
            debuffDisplayOverrideId[k] = v
        end
    end
    -- Always show NPC self applied debuffs
    for k, v in pairs(Effects.DebuffDisplayOverrideIdAlways) do
        debuffDisplayOverrideId[k] = v
    end
    -- Major/Minor
    if SpellCastBuffs.SV.ShowSharedMajorMinor then
        for k, v in pairs(Effects.DebuffDisplayOverrideMajorMinor) do
            for k, v in pairs(Effects.DebuffDisplayOverrideMajorMinor) do
                debuffDisplayOverrideId[k] = v
            end
        end
    end
end

-- Called from the menu and on initialize to build major/minor generic icon overrides.
function SpellCastBuffs.UpdateMajorMinorList(menu)
    if LUIE.SpellCastBuffs.SV.GenericMajorMinor then
        for k, v in pairs(Effects.MajorMinorIconTable) do
            if v.normalize then
                Effects.EffectOverride[k].icon = v.normalize
            end
        end
    -- Minimize the amount of iterating we need to do, we only need to toggle back if we're disabling the setting from the menu.
    elseif menu and not LUIE.SpellCastBuffs.SV.GenericMajorMinor then
        for k, v in pairs(Effects.MajorMinorIconTable) do
            if v.icon then
                Effects.EffectOverride[k].icon = v.icon
            end
        end
    end
end
