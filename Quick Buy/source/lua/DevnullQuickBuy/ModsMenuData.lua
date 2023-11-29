-- define OP_TT_ColorPicker just incase ns2plus hasn't been loaded
--Script.Load("lua/menu2/widgets/GUIMenuColorPickerWidget.lua") -- doesn't get loaded by vanilla menu
--OP_TT_ColorPicker = OP_TT_ColorPicker or GetMultiWrappedClass(GUIMenuColorPickerWidget, {"Option", "Tooltip"})

local menu =
{
	categoryName = "Quick Buy",
	entryConfig =
	{
		name = "dqbEntry",
		class = GUIMenuCategoryDisplayBoxEntry,
		params =
		{
			label = "Quick Buy Options",
		},
	},
	contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
	{
		layoutName = "BuyMenuHotkeysOptions",
		contents =
		{
			-----General
			{
				name = "kDQBHeaderGeneral",
				class = GUIMenuText,
				params = {
					text = "General Options"
				},
			},
			{
				name = "dqb_enabled",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "dqb_enabled",
					optionType = "bool",
					default = false,
					tooltip = "Enable quickbuy functionality",
				},
			
				properties =
				{
					{"Label", "Enable quickbuy functionality"},
				},
			},
			{
				name = "dqb_showlabels",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "dqb_showlabels",
					optionType = "bool",
					default = true,
					tooltip = "Shows Keybind labels in all buymenus",
				},
			
				properties =
				{
					{"Label", "Show Quick Buy Labels"},
				},
			},
			{
				name = "dqb_closeonbuy",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "dqb_closeonbuy",
					optionType = "bool",
					default = true,
					tooltip = "Closes armory/proto menu after each purchase.",
				},
			
				properties =
				{
					{"Label", "Close menu on marine purchase"},
				},
			},
			-----Aliens
			{
				name = "kDQBHeaderAliens",
				class = GUIMenuText,
				params = {
					text = "ALIEN BUY MENU HOTKEYS"
				},
			},
			{
				name = "dqb_evolve",
				class = OP_Keybind,
				params = {
					optionPath = "input/dqb_evolve",
					optionType = "string",
					default = "NumPadEnter",

					bindGroup = "dqb_alien",
				},
				properties = {
					{ "Label", "Evolve Key" },
				},
			},
			-----Lifeforms
			{
				name = "dqb_gorge",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_gorge",
					optionType = "string",
					default = "1",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Gorge"},
				},
			},
			{
				name = "dqb_skulk",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_skulk",
					optionType = "string",
					default = "2",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Skulk"},
				},
			},
			{
				name = "dqb_lerk",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_lerk",
					optionType = "string",
					default = "3",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Lerk"},
				},
			},
			{
				name = "dqb_fade",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_fade",
					optionType = "string",
					default = "4",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Fade"},
				},
			},
			{
				name = "dqb_onos",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_onos",
					optionType = "string",
					default = "5",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Onos"},
				},
			},
			-----Abilities Shells
			{
				name = "dqb_regeneration",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_regeneration",
					optionType = "string",
					default = "NumPad1",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Regeneration"},
				},
			},
			{
				name = "dqb_carapace",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_carapace",
					optionType = "string",
					default = "NumPad2",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Carapace"},
				},
			},
			{
				name = "dqb_vampirism",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_vampirism",
					optionType = "string",
					default = "NumPad3",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Vampirism"},
				},
			},
			-----Abilities Spurs
			{
				name = "dqb_adrenaline",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_adrenaline",
					optionType = "string",
					default = "NumPad4",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Adrenaline"},
				},
			},
			{
				name = "dqb_celerity",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_celerity",
					optionType = "string",
					default = "NumPad5",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Celerity"},
				},
			},
			{
				name = "dqb_crush",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_crush",
					optionType = "string",
					default = "NumPad6",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Crush"},
				},
			},
			-----Abilities Veils
			{
				name = "dqb_camouflage",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_camouflage",
					optionType = "string",
					default = "NumPad7",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Camouflage"},
				},
			},
			{
				name = "dqb_focus",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_focus",
					optionType = "string",
					default = "NumPad8",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Focus"},
				},
			},
			{
				name = "dqb_aura",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_aura",
					optionType = "string",
					default = "NumPad9",

					bindGroup = "dqb_alien",
				},
				properties =
				{
					{"Label", "Select Aura"},
				},
			},
			-----Marines
			-----Armory
			{
				name = "kDQBHeaderMarinesArmory",
				class = GUIMenuText,
				params = {
					text = "ARMORY BUY MENU HOTKEYS"
				},
			},
			{
				name = "dqb_welder",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_welder",
					optionType = "string",
					default = "1",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Welder"},
				},
			},
			{
				name = "dqb_mines",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_mines",
					optionType = "string",
					default = "2",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Mines"},
				},
			},
			{
				name = "dqb_shotgun",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_shotgun",
					optionType = "string",
					default = "3",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Shotgun"},
				},
			},
			{
				name = "dqb_cluster",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_cluster",
					optionType = "string",
					default = "4",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Cluster Grenades"},
				},
			},
			{
				name = "dqb_nervegas",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_nervegas",
					optionType = "string",
					default = "5",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Nerve Gas"},
				},
			},
			{
				name = "dqb_pulse",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_pulse",
					optionType = "string",
					default = "6",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Pulse Grenades"},
				},
			},
			{
				name = "dqb_gl",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_gl",
					optionType = "string",
					default = "7",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Grenade Launcher"},
				},
			},
			{
				name = "dqb_flamethrower",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_flamethrower",
					optionType = "string",
					default = "8",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase Flamethrower"},
				},
			},
			{
				name = "dqb_hmg",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_hmg",
					optionType = "string",
					default = "9",

					bindGroup = "dqb_armory",
				},
				properties =
				{
					{"Label", "Purchase HMG"},
				},
			},
            -----Prototype Lab
			{
				name = "kDQBHeaderMarinesPrototypeLab",
				class = GUIMenuText,
				params = {
					text = "PROTOTYPELAB BUY MENU HOTKEYS"
				},
			},
			{
				name = "dqb_jetpack",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_jetpack",
					optionType = "string",
					default = "1",

					bindGroup = "dqb_protolab",
				},
				properties =
				{
					{"Label", "Purchase Jetpack"},
				},
			},
			{
				name = "dqb_exomini",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_exomini",
					optionType = "string",
					default = "2",

					bindGroup = "dqb_protolab",
				},
				properties =
				{
					{"Label", "Purchase Minigun Exo"},
				},
			},
			{
				name = "dqb_exorail",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/dqb_exorail",
					optionType = "string",
					default = "3",

					bindGroup = "dqb_protolab",
				},
				properties =
				{
					{"Label", "Purchase Railgun Exo"},
				},
			},
		},
	}
}
table.insert(gModsCategories, menu)
