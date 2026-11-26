local mod = get_mod("train_timer")

local HudElementMissionObjectiveFeed =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed")
local HudElementMissionObjectiveFeedSettings =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed_settings")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local add_definitions = function(definitions)
	if not definitions then
		return
	end

	definitions.scenegraph_definition = definitions.scenegraph_definition or {}
	definitions.widget_definitions = definitions.widget_definitions or {}

	local timer_new_text_style = table.clone(UIFontSettings.body)

	timer_new_text_style.text_color = Color.ui_terminal(25.5, true)
	timer_new_text_style.font_size = 94
	timer_new_text_style.font_type = "proxima_nova_medium"
	timer_new_text_style.text_vertical_alignment = "center"
	timer_new_text_style.text_horizontal_alignment = "center"

	local timer_active_new_text_style = table.clone(UIFontSettings.body)

	timer_active_new_text_style.text_color = Color.ui_terminal(255, true)
	timer_active_new_text_style.color = Color.ui_terminal(255, true)
	timer_active_new_text_style.font_size = 94
	timer_active_new_text_style.font_type = "proxima_nova_medium"
	timer_active_new_text_style.text_vertical_alignment = "center"
	timer_active_new_text_style.text_horizontal_alignment = "center"
	timer_active_new_text_style.offset = {
		0,
		0,
		0,
	}

	definitions.scenegraph_definition.timer_background = {
		horizontal_alignment = "right",
		parent = "background",
		vertical_alignment = "top",
		size = {
			234,
			90,
		},
		position = {
			-500,
			0,
			1,
		},
	}

	definitions.scenegraph_definition.timer_text = {
		horizontal_alignment = "left",
		parent = "timer_background",
		vertical_alignment = "center",
		size = {
			234,
			90,
		},
		position = {
			0,
			0,
			2,
		},
	}

	definitions.widget_definitions.timer_background = UIWidget.create_definition({
		{
			visible = false,
			pass_type = "texture",
			value = "content/ui/materials/hud/backgrounds/terminal_background_weapon",
			style = {
				vertical_alignment = "top",
				color = Color.terminal_background_gradient(255, true),
			},
		},
	}, "timer_background")

	definitions.widget_definitions.timer_text = UIWidget.create_definition({
		{
			visible = false,
			pass_type = "text",
			style_id = "text_background",
			value = ":",
			value_id = "text_background",
			style = timer_new_text_style,
		},
		{
			visible = false,
			pass_type = "text",
			style_id = "text",
			value = "",
			value_id = "text",
			style = timer_active_new_text_style,
		},
	}, "timer_text")
end

mod:hook_require(
	"scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed_definitions",
	function(definitions)
		add_definitions(definitions)
	end
)

local function addLeadingZeros(str)
	-- Check if the string length is already greater than or equal to 2
	if #str >= 2 then
		return str
	end

	-- Calculate the number of leading zeros to add
	local numZeros = 2 - #str

	-- Create a new string with the leading zeros
	local result = string.rep("0", numZeros) .. str

	return result
end

local ALERT_COLOR = {
	255,
	0,
	0,
	0,
}

-- Custom fuzzy match has_widget check.
HudElementMissionObjectiveFeed.has_objective = function(self, objectivename)
	local objectives = self._hud_objectives_sorted or {}

	for i = 1, #objectives do
		local hud_objective = objectives[i]
		local objective_name = hud_objective and hud_objective._objective_name

		if objective_name and string.find(objective_name, objectivename, 1, true) then
			return true
		end
	end

	return false
end

mod:hook_safe(
	CLASS.HudElementMissionObjectiveFeed,
	"update",
	function(self, dt, t, ui_renderer, render_settings, input_service)
		if
			self:has_objective("objective_flash_train_reach_locomotive")
			or self:has_objective("objective_flash_train_alert")
		then
			local widget = self._widgets_by_name["timer_text"]
			widget.content.visible = true

			local widget = self._widgets_by_name["timer_background"]
			widget.content.visible = true
		else
			local widget = self._widgets_by_name["timer_text"]
			widget.content.visible = false

			local widget = self._widgets_by_name["timer_background"]
			widget.content.visible = false
		end

		-- for debugging
		--Managers.time:set_local_scale("gameplay", 20)
	end
)

-- Check if the objective names match using a fuzzy approach (ignore prefixes or numbers)
local function fuzzy_match(objective_name, match_name)
	-- Strip out leading numbers or underscores
	local clean_objective_name = objective_name:match("^[^%w]*(%w+.*)$") -- remove leading non-alphanumeric chars
	local clean_match_name = match_name:match("^[^%w]*(%w+.*)$") -- same for match name

	return clean_objective_name == clean_match_name
end

HudElementMissionObjectiveFeed._update_widgets = function(self, dt, t)
	local objective_widgets = self._objective_widgets
	local objectives = self._hud_objectives_sorted or {}

	for i = 1, #objectives do
		local hud_objective = objectives[i]
		local objective = hud_objective and hud_objective.objective and hud_objective:objective()
		local widget = objective and objective_widgets and objective_widgets[objective]

		if widget then
			local content = widget.content
			local ui_state = hud_objective:state()
			local objective_name = hud_objective._objective_name
			content.ui_state = ui_state

			-- If train mission with timer then add clock
			if
				fuzzy_match(objective_name, "objective_flash_train_reach_locomotive")
				or fuzzy_match(objective_name, "objective_flash_train_alert")
			then
				-- update clock timer
				local timerwidget = self._widgets_by_name.timer_text
				local maxtime = hud_objective._max_counter_amount
				local time_left = 0
				if fuzzy_match(objective_name, "objective_flash_train_reach_locomotive") then
					local completed_seconds = hud_objective._progression * maxtime
					maxtime = maxtime + 30
					completed_seconds = completed_seconds
					time_left = maxtime - completed_seconds
				elseif fuzzy_match(objective_name, "objective_flash_train_alert") then
					if hud_objective._time_left then
						time_left = hud_objective._time_left
					end
				end

				local seconds = time_left % 60
				local minutes = math.floor(time_left / 60)

				local minutes_time_to_string = tostring(math.ceil(minutes))
				local seconds_time_to_string = tostring(math.floor(seconds))

				-- pad zeroes
				minutes_time_to_string = addLeadingZeros(minutes_time_to_string)
				seconds_time_to_string = addLeadingZeros(seconds_time_to_string)

				local symbols = self._alfs_timer_symbols

				if not symbols then
					symbols = {}
					self._alfs_timer_symbols = symbols
				end

				local symbol_count = 0

				for i = 1, #minutes_time_to_string do
					symbol_count = symbol_count + 1
					local number = tonumber(string.sub(minutes_time_to_string, i, i))
					symbols[symbol_count] = UISettings.digital_clock_numbers[number]
				end

				symbol_count = symbol_count + 1
				symbols[symbol_count] = ":"

				for i = 1, #seconds_time_to_string do
					symbol_count = symbol_count + 1
					local number = tonumber(string.sub(seconds_time_to_string, i, i))
					symbols[symbol_count] = UISettings.digital_clock_numbers[number]
				end

				for i = symbol_count + 1, #symbols do
					symbols[i] = nil
				end

				-- Add alert flashing to new timer
				if ui_state == "alert" then
					local neutral_color = HudElementMissionObjectiveFeedSettings.colors_by_category.default.bar
					local lerp = math.sin(t * 10) / 2 + 0.5

					ALERT_COLOR[2] = math.lerp(neutral_color[2], 255, lerp)
					ALERT_COLOR[3] = math.lerp(neutral_color[3], 151, lerp)
					ALERT_COLOR[4] = math.lerp(neutral_color[4], 29, lerp)

					local style = timerwidget.style

					style.text.text_color = ALERT_COLOR
				end

				local symbols_text = table.concat(symbols, "", 1, symbol_count)

				if timerwidget.content.text ~= symbols_text then
					timerwidget.content.text = symbols_text
				end
			end

			if ui_state == "alert" then
				local style = widget.style
				local neutral_color = HudElementMissionObjectiveFeedSettings.colors_by_category.default.bar
				local alert_color = style.bar.alert_color or HudElementMissionObjectiveFeedSettings.alert_color
				local lerp = math.sin(t * 10) / 2 + 0.5

				ALERT_COLOR[2] = math.lerp(neutral_color[2], alert_color[2], lerp)
				ALERT_COLOR[3] = math.lerp(neutral_color[3], alert_color[3], lerp)
				ALERT_COLOR[4] = math.lerp(neutral_color[4], alert_color[4], lerp)

				if content.show_bar then
					style.bar.color = ALERT_COLOR
				end

				if content.show_timer then
					style.timer_text.text_color = ALERT_COLOR
				end
			end

			if content.show_timer then
				self:_update_timer_progress(hud_objective, widget, dt)
			end
		end
	end
end
