local mod = get_mod("train_timer")

local HudElementMissionObjectiveFeed =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed")
local HudElementMissionObjectiveFeedSettings =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed_settings")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local DIGITAL_CLOCK_NUMBERS = UISettings and UISettings.digital_clock_numbers
local PADDED_NUMBERS = {}

for i = 0, 99 do
	PADDED_NUMBERS[i] = string.format("%02d", i)
end

local math_floor = math.floor
local math_lerp = math.lerp
local math_max = math.max
local math_sin = math.sin
local string_find = string.find
local string_sub = string.sub
local table_concat = table.concat
local tonumber = tonumber
local tostring = tostring

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

local function padded_number(value)
	if type(value) ~= "number" then
		return "00"
	end

	local integer = math_floor(value)

	return PADDED_NUMBERS[integer] or tostring(integer)
end

local ALERT_COLOR = {
	255,
	0,
	0,
	0,
}

HudElementMissionObjectiveFeed.has_objective = function(self, objectivename)
	if type(objectivename) ~= "string" then
		return false
	end

	local objectives = self._hud_objectives_sorted

	if not objectives then
		return false
	end

	for i = 1, #objectives do
		local hud_objective = objectives[i]
		local objective_name = hud_objective and hud_objective._objective_name

		if type(objective_name) == "string" and string_find(objective_name, objectivename, 1, true) then
			return true
		end
	end

	return false
end

mod:hook_safe(CLASS.HudElementMissionObjectiveFeed, "update", function(self)
	local show_timer = self:has_objective("objective_flash_train_reach_locomotive")
		or self:has_objective("objective_flash_train_alert")
	local widgets_by_name = self._widgets_by_name
	local timer_text = widgets_by_name and widgets_by_name.timer_text
	local timer_background = widgets_by_name and widgets_by_name.timer_background

	if timer_text and timer_text.content then
		timer_text.content.visible = show_timer
	end

	if timer_background and timer_background.content then
		timer_background.content.visible = show_timer
	end
end)

local function fuzzy_match(objective_name, match_name)
	if type(objective_name) ~= "string" or type(match_name) ~= "string" then
		return false
	end

	local clean_objective_name = objective_name:match("^[^%w]*(%w+.*)$")
	local clean_match_name = match_name:match("^[^%w]*(%w+.*)$")

	return clean_objective_name ~= nil and clean_objective_name == clean_match_name
end

HudElementMissionObjectiveFeed._update_widgets = function(self, dt, t)
	local objective_widgets = self._objective_widgets
	local objectives = self._hud_objectives_sorted

	if not objectives then
		return
	end

	local settings = HudElementMissionObjectiveFeedSettings
	local categories = settings and settings.colors_by_category
	local default_category = categories and categories.default
	local alert_color = settings and settings.alert_color
	local widgets_by_name = self._widgets_by_name

	for i = 1, #objectives do
		local hud_objective = objectives[i]

		if hud_objective and hud_objective.state then
			local objective = hud_objective.objective and hud_objective:objective()
			local widget = objective and objective_widgets and objective_widgets[objective]

			if widget and widget.content then
				local content = widget.content
				local ui_state = hud_objective:state()
				local objective_name = hud_objective._objective_name

				content.ui_state = ui_state

				if
					fuzzy_match(objective_name, "objective_flash_train_reach_locomotive")
					or fuzzy_match(objective_name, "objective_flash_train_alert")
				then
					local timerwidget = widgets_by_name and widgets_by_name.timer_text

					if timerwidget and timerwidget.content and timerwidget.style then
						local maxtime = hud_objective._max_counter_amount
						local progression = hud_objective._progression
						local time_left = 0

						if type(maxtime) == "number" and type(progression) == "number" then
							if fuzzy_match(objective_name, "objective_flash_train_reach_locomotive") then
								time_left = maxtime + 30 - progression * maxtime
							else
								local alert_time_left = hud_objective._time_left

								if type(alert_time_left) == "number" then
									time_left = alert_time_left
								end
							end
						end

						time_left = math_max(time_left, 0)

						local seconds = time_left % 60
						local minutes = math_floor(time_left / 60)
						local minutes_time_to_string = padded_number(minutes)
						local seconds_time_to_string = padded_number(seconds)
						local symbols = self._alfs_timer_symbols
						local symbol_count = 0

						if not symbols then
							symbols = {}
							self._alfs_timer_symbols = symbols
						end

						for j = 1, #minutes_time_to_string do
							symbol_count = symbol_count + 1
							local number = tonumber(string_sub(minutes_time_to_string, j, j))
							symbols[symbol_count] = (DIGITAL_CLOCK_NUMBERS and DIGITAL_CLOCK_NUMBERS[number]) or ""
						end

						symbol_count = symbol_count + 1
						symbols[symbol_count] = ":"

						for j = 1, #seconds_time_to_string do
							symbol_count = symbol_count + 1
							local number = tonumber(string_sub(seconds_time_to_string, j, j))
							symbols[symbol_count] = (DIGITAL_CLOCK_NUMBERS and DIGITAL_CLOCK_NUMBERS[number]) or ""
						end

						for j = symbol_count + 1, #symbols do
							symbols[j] = nil
						end

						if ui_state == "alert" then
							local text_style = timerwidget.style.text
							local neutral_color = default_category and default_category.bar

							if text_style and neutral_color and alert_color then
								local lerp = math_sin(t * 10) / 2 + 0.5

								ALERT_COLOR[2] = math_lerp(neutral_color[2], alert_color[2], lerp)
								ALERT_COLOR[3] = math_lerp(neutral_color[3], alert_color[3], lerp)
								ALERT_COLOR[4] = math_lerp(neutral_color[4], alert_color[4], lerp)

								text_style.text_color = ALERT_COLOR
							end
						end

						local symbols_text = table_concat(symbols, "", 1, symbol_count)

						if timerwidget.content.text ~= symbols_text then
							timerwidget.content.text = symbols_text
						end
					end
				end

				if ui_state == "alert" then
					local style = widget.style
					local bar_style = style and style.bar
					local timer_style = style and style.timer_text
					local neutral_color = default_category and default_category.bar
					local objective_alert_color = (bar_style and bar_style.alert_color) or alert_color

					if neutral_color and objective_alert_color then
						local lerp = math_sin(t * 10) / 2 + 0.5

						ALERT_COLOR[2] = math_lerp(neutral_color[2], objective_alert_color[2], lerp)
						ALERT_COLOR[3] = math_lerp(neutral_color[3], objective_alert_color[3], lerp)
						ALERT_COLOR[4] = math_lerp(neutral_color[4], objective_alert_color[4], lerp)

						if content.show_bar and bar_style then
							bar_style.color = ALERT_COLOR
						end

						if content.show_timer and timer_style then
							timer_style.text_color = ALERT_COLOR
						end
					end
				end

				if content.show_timer then
					self:_update_timer_progress(hud_objective, widget, dt)
				end
			end
		end
	end
end
