return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`train_timer` encountered an error loading the Darktide Mod Framework.")

		new_mod("train_timer", {
			mod_script       = "train_timer/scripts/mods/train_timer/train_timer",
			mod_data         = "train_timer/scripts/mods/train_timer/train_timer_data",
			mod_localization = "train_timer/scripts/mods/train_timer/train_timer_localization",
		})
	end,
	packages = {},
}
