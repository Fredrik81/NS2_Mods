
local menu =
{
	categoryName = "Enhanced Hud",
	entryConfig =
	{
		name = "AH_Option",
		class = GUIMenuCategoryDisplayBoxEntry,
		params =
		{
			label = "ENHANCED HUD",
		},
	},
	contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
	{
		layoutName = "AH_Option",
		contents =
		{
			{
				name = "a_hud_enabled",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "a_hud_enabled",
					optionType = "bool",
					default = true,
					tooltip = "Deathcount, Suppy and Tres will change their color from white->yellow->orange->red",
				},
			
				properties =
				{
					{"Label", "Topbar number coloration"},
				},
			},
			{
				name = "wd_enabled",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "wd_enabled",
					optionType = "bool",
					default = true,
				},
			
				properties =
				{
					{"Label", "[Marine] Show weapons on the ground"},
				},
				postInit = function(self)
					self:HookEvent(self, "OnValueChanged", function(this)
						wd_enabled = this:GetValue()
					end)
				end
			},
			{
                name = "a_hud_selectall",
                class = OP_TT_Checkbox,
                params =
                {
                    optionPath = "a_hud_selectall",
                    optionType = "bool",
                    default = true,
                    tooltip = "Mac, Arc and Observatory 'Select all' button will appear once available",
                },
            
                properties =
                {
                    {"Label", "[Marine Comm] Additional 'Select all' buttons"},
                },
            },
			
			{
				name = "wd_comm_enabled",
				class = OP_TT_Checkbox,
				params =
				{
					optionPath = "wd_comm_enabled",
					optionType = "bool",
					default = true,
				},
			
				properties =
				{
					{"Label", "[Marine Comm] Show amount of loaded bullets"},
				},
				postInit = function(self)
					self:HookEvent(self, "OnValueChanged", function(this)
						wd_comm_enabled = this:GetValue()
					end)
				end
			},
		},

	},

	
}
table.insert(gModsCategories, menu)
