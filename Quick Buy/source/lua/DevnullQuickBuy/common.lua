--=== This file modifies Natural Selection 2, Copyright Unknown Worlds Entertainment. ============
--
-- BuyMenuHotKeys\dqb_common.lua
--
--    Created by:   Chris Baker (chris.l.baker@gmail.com)
--    License:      Public Domain
--
-- Public Domain license of this file does not supercede any Copyrights or Trademarks of Unknown
-- Worlds Entertainment, Inc. Natural Selection 2, its Assets, Source Code, Documentation, and
-- Utilities are Copyright Unknown Worlds Entertainment, Inc. All rights reserved.
-- ========= For more information, visit http:--www.unknownworlds.com ============================


kDQBStartMarker     = "dqb"
kDQBEvolveKey       = "dqb_evolve"
kDQBSkulkKey        = "dqb_skulk"
kDQBGorgeKey        = "dqb_gorge"
kDQBLerkKey         = "dqb_lerk"
kDQBFadeKey         = "dqb_fade"
kDQBOnosKey         = "dqb_onos"

kDQBCarapaceKey     = "dqb_carapace"
kDQBRegenerationKey = "dqb_regeneration"
kDQBVampirismKey    = "dqb_vampirism"
--kDQBPhantomKey      = "dqb_phantom"

kDQBAdrenalineKey   = "dqb_adrenaline"
kDQBCelerityKey     = "dqb_celerity"
kDQBCrushKey        = "dqb_crush"

kDQBCamouflageKey      = "dqb_camouflage"
kDQBFocusKey        = "dqb_focus"
kDQBAuraKey         = "dqb_aura"

kDQBWelderKey       = "dqb_welder"
kDQBMinesKey        = "dqb_mines"
kDQBShotgunKey      = "dqb_shotgun"
kDQBClusterKey      = "dqb_cluster"
kDQBNervegasKey     = "dqb_nervegas"
kDQBPulseKey        = "dqb_pulse"
kDQBGLKey           = "dqb_gl"
kDQBFlamethrowerKey = "dqb_flamethrower"
kDQBHMGKey          = "dqb_hmg"
kDQBJetpackKey      = "dqb_jetpack"
kDQBExominiKey      = "dqb_exomini"
kDQBExorailKey      = "dqb_exorail"
kDQBEnabled         = "dqb_enabled"
kDQBShowLabels 	 = "dqb_showlabels"
kDQBCloseOnBuy 	 = "dqb_closeonbuy"

--kDQBExodualKey      = "dqb_exodual"

kDQBDefaultUIScale = 0.750
kDQBMarineTextUIScale = 0.98
--kDQBDefaultShowLabels = true


-- There is a bug that affects scrolling very long forms due to having a fixed
-- CSS Height attribute. This routine will patch the form height to be
-- ContentSize + 20.
-- It will also export a global variable to prevent the fix from being applied
-- multiple times.
if not kLongFormScrollFix and ContentBox then
    -- Patch ContentBox:OnSlide to correct form height
    local originalCBOnSlide = ContentBox.OnSlide
    function ContentBox:OnSlide(slideFraction, align)
        --Print("ContentBox:OnSlide (%f)", slideFraction)
        for _, child in ipairs(self.children) do
            local desiredconheight = child:GetContentSize().y+20
            if child:isa("Form") and (child:GetHeight() ~= desiredconheight) then
                child:SetHeight(desiredconheight)
            end
        end
        originalCBOnSlide(self, slideFraction, align)
    end
    kLongFormScrollFix = 1
end

-- patch the bindings data (can we do this by using ReplaceLocals?)
local binding_data_patched = false
if (nil ~= BindingsUI_GetBindingsData) then
    local tempbd = BindingsUI_GetBindingsData()
    for i,line in ipairs(tempbd) do
      if (line==kDQBStartMarker) then
        binding_data_patched = true
        break
      end
    end

    if (not binding_data_patched) then
        local additionalDefaultBindings =
        {
            {kDQBEvolveKey,       "NumPadEnter"},
            {kDQBGorgeKey,        "1"},
            {kDQBSkulkKey,        "2"},
            {kDQBLerkKey,         "3"},
            {kDQBFadeKey,         "4"},
            {kDQBOnosKey,         "5"},
            
			{kDQBRegenerationKey, "NumPad1"},
            {kDQBCarapaceKey,     "NumPad2"},
			{kDQBVampirismKey,    "NumPad3"},
            {kDQBAdrenalineKey,   "NumPad4"},
            {kDQBCelerityKey,     "NumPad5"},
			{kDQBCrushKey,        "NumPad6"},
            {kDQBCamouflageKey,   "NumPad7"},
			{kDQBFocusKey,        "NumPad8"},
            {kDQBAuraKey,         "NumPad9"},
            {kDQBWelderKey,       "1"},
            {kDQBMinesKey,        "2"},
            {kDQBShotgunKey,      "3"},
            {kDQBClusterKey,      "4"},
            {kDQBNervegasKey,     "5"},
            {kDQBPulseKey,        "6"},
            {kDQBGLKey,           "7"},
            {kDQBFlamethrowerKey, "8"},
            {kDQBHMGKey,          "9"},
            {kDQBJetpackKey,      "1"},
            {kDQBExominiKey,      "2"},
            {kDQBExorailKey,      "3"},
            --{kDQBExodualKey,      "1"},
        } -- additionalDefaultBindings

        local additionalControlBindings =
        {
            kDQBStartMarker,     "title", "Buy Menu Hotkeys",          "Key Binding for Buy Menu Hotkeys Mod",
            kDQBEvolveKey,       "input", "Buy Menu Evolve",           "NumPadEnter",
            kDQBGorgeKey,        "input", "Select Gorge",              "1",            
            kDQBSkulkKey,        "input", "Select Skulk",              "2",
            kDQBLerkKey,         "input", "Select Lerk",               "3",
            kDQBFadeKey,         "input", "Select Fade",               "4",
            kDQBOnosKey,         "input", "Select Onos",               "5",

			kDQBRegenerationKey, "input", "Select Regeneration",       "NumPad1",
            kDQBCarapaceKey,     "input", "Select Carapace",           "NumPad2",
			kDQBVampirismKey,    "input", "Select Vampirism",          "NumPad3",
            kDQBAdrenalineKey,   "input", "Select Adrenaline",         "NumPad4",
            kDQBCelerityKey,     "input", "Select Celerity",           "NumPad5",
			kDQBCrushKey,        "input", "Select Crush",              "NumPad6",
			kDQBCamouflageKey,   "input", "Select Camouflage",         "NumPad7",
            kDQBFocusKey,        "input", "Select Focus",              "NumPad8",
            kDQBAuraKey,         "input", "Select Aura",               "NumPad9",

            kDQBWelderKey,       "input", "Purchase Welder",           "1",
            kDQBMinesKey,        "input", "Purchase Mines",            "2",
            kDQBShotgunKey,      "input", "Purchase Shotgun",          "3",
            kDQBClusterKey,      "input", "Purchase Cluster Grenades", "4",
            kDQBNervegasKey,     "input", "Purchase Nerve Gas",        "5",
            kDQBPulseKey,        "input", "Purchase Pulse Grenades",   "6",
            kDQBGLKey,           "input", "Purchase Grenade Launcher", "7",
            kDQBFlamethrowerKey, "input", "Purchase Flamethrower",     "8",
            kDQBHMGKey,          "input", "Purchase HMG",              "9",
            kDQBJetpackKey,      "input", "Purchase Jetpack",          "1",
            kDQBExominiKey,      "input", "Purchase Minigun Exo",      "2",
            kDQBExorailKey,      "input", "Purchase Railgun Exo",      "3",
            --kDQBExodualKey,      "input", "Purchase Dual-Exo Upgrade", "1",
        } -- additionalControlBindings

        for i,line in ipairs(additionalControlBindings) do
          table.insert(tempbd, line)
        end

        -- We will extend GetDefaultInputValue
        local originalBindingsGetDefault = GetDefaultInputValue
        function GetDefaultInputValue(controlId)
            local rc = nil
            for index, pair in ipairs(additionalDefaultBindings) do
                if(pair[1] == controlId) then
                    rc = pair[2]
                    break
                end
            end

            if (rc == nil) then
                rc = originalBindingsGetDefault(controlId)
            end
            return rc
        end -- GetDefaultInputValue
    end -- if binding data not yet patched
 end -- BindingsUI_GetBindingsData not nil
