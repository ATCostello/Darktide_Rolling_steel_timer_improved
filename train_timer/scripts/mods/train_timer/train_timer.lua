local mod = get_mod("train_timer")

local UIManager = require("scripts/managers/ui/ui_manager")
local UIHud = require("scripts/managers/ui/ui_hud")
local HudElementObjectiveProgressBar =
	require("scripts/ui/hud/elements/objective_progress_bar/hud_element_objective_progress_bar")
local HudElementMissionObjectiveFeed =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed")
local HudElementMissionObjectiveFeedSettings =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed_settings")
local HudElementMissionObjectiveFeedDefinitions =
	require("scripts/ui/hud/elements/mission_objective_feed/hud_element_mission_objective_feed_definitions")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local DialogueEventQueue = require("scripts/extension_systems/dialogue/dialogue_event_queue")

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
	for _, hud_objective in pairs(self._hud_objectives_sorted) do
		local objective_name = hud_objective._objective_name

		if string.find(objective_name, objectivename, 1, true) then
			return true
		end
	end

	return false
end

local find_widget = function(self, widget_name)
	for _, widget in pairs(self._widgets_by_name) do
		if widget then
			local name = widget.name

			if string.find(name, widget_name, 1, true) then
				return widget
			end
		end
	end
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

	local objective_widgets = self._objective_widgets

	for _, hud_objective in pairs(self._hud_objectives_sorted) do
		objective_name = hud_objective._objective_name
		local widget = find_widget(self, objective_name)

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

				local minutes_time_string_to_array = {}
				local seconds_time_string_to_array = {}

				for mem in string.gmatch(minutes_time_to_string, "%w") do
					table.insert(minutes_time_string_to_array, mem)
				end

				for mem in string.gmatch(seconds_time_to_string, "%w") do
					table.insert(seconds_time_string_to_array, mem)
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

				local symbols_text = ""

				-- Add minutes symbols
				for i = 1, #minutes_time_string_to_array do
					local number = tonumber(minutes_time_string_to_array[i])
					local symbol = UISettings.digital_clock_numbers[number]

					symbols_text = symbols_text .. symbol
				end

				symbols_text = symbols_text .. ":"

				-- Add seconds symbols
				for i = 1, #seconds_time_string_to_array do
					local number = tonumber(seconds_time_string_to_array[i])
					local symbol = UISettings.digital_clock_numbers[number]

					symbols_text = symbols_text .. symbol
				end

				timerwidget.content.text = symbols_text
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

-- helper to compute text width safely across different game versions
local function get_text_width_safe(ui_renderer, text, text_style, optional_size)
	-- Try UIWidget.get_text_dimensions
	if UIWidget and UIWidget.get_text_dimensions and ui_renderer then
		local text_width = UIWidget.get_text_dimensions(ui_renderer, text, text_style, optional_size)
		-- Some builds return multiple values: width, height, caret
		if type(text_width) == "number" then
			return text_width
		else
			local w = select(1, UIWidget.get_text_dimensions(ui_renderer, text, text_style, optional_size))
			if type(w) == "number" then
				return w
			end
		end
	end

	-- Try UIRenderer.text_size
	if rawget(_G, "UIRenderer") and UIRenderer.text_size and ui_renderer then
		local font_type = text_style.font_type
		local font_size = text_style.font_size
		local material = text_style.material
		local w = select(1, UIRenderer.text_size(ui_renderer, text, font_type, font_size, material, optional_size))
		if type(w) == "number" then
			return w
		end
	end

	-- Fallback to zero to avoid crashes; alignment will be default
	return 0
end

--[[HudElementMissionObjectiveFeed._update_timer_progress = function(self, hud_objective, widget, dt, realign)
	local content = widget.content
	local show_minutes = content.show_minutes
	local show_hours = content.show_hours
	local time_left = math.max(hud_objective:time_left(dt), 0)
	local text

	if show_hours then
		local use_short = true
		local allow_skip = false
		local max_detail

		text = TextUtilities.format_time_span_localized(time_left, use_short, allow_skip, max_detail)
	elseif show_minutes then
		local millis = math.floor(time_left % 1 * 100)

		text = string.format("%.2d:%.2d:%.2d", time_left / 60 % 60, time_left % 60, millis)
	else
		local millis = math.floor(time_left % 1 * 100)

		text = string.format("%.2d:%.2d", time_left % 60, millis)
	end

	if realign then
		local realignment_text

		if show_hours then
			realignment_text = text
		else
			realignment_text = show_minutes and "00:00:00" or "00:00"
		end

		local style = widget.style
		local text_style = style.timer_text
		local optional_size = {
			500,
			40,
		}
		local ui_renderer = self._parent and self._parent.ui_renderer and self._parent:ui_renderer() or nil

		-- Safe text width measurement; do not call nonexistent _text_size_for_style
		local width = get_text_width_safe(ui_renderer, realignment_text, text_style, optional_size)

		-- Guard default_offset access
		local base_x = (text_style.default_offset and text_style.default_offset[1])
			or (text_style.offset and text_style.offset[1])
			or 0
		text_style.offset = text_style.offset or { 0, 0, 0 }
		text_style.offset[1] = base_x - (width or 0)
	end

	content.timer_text = text
end]]
