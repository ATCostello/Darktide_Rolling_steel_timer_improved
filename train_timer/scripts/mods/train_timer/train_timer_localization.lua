local mod = get_mod("train_timer")
mod.version = "1.3.05"
mod:info("Rolling Steel Timer Improved (Train Timer) is installed, using version: " .. tostring(mod.version))

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function utf8_chars(s)
	local chars = {}
	for char in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(chars, char)
	end
	return chars
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local chars = utf8_chars(text)
	local visibleIndex = 0

	for _, char in ipairs(chars) do
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for _, char in ipairs(chars) do
		if not colorSpaces and char == " " then
			result = result .. char
		else
			currentIndex = currentIndex + 1
			local t = (visibleIndex <= 1) and 0 or (currentIndex - 1) / (visibleIndex - 1)

			local r = math.floor(lerp(startColor[1], endColor[1], t))
			local g = math.floor(lerp(startColor[2], endColor[2], t))
			local b = math.floor(lerp(startColor[3], endColor[3], t))

			result = result .. string.format("{#color(%d,%d,%d)}%s", r, g, b, char)
		end
	end

	result = "{#color(" .. colours.title .. ")}" .. result .. "{#reset()}"
	return result
end

local mod_name = {
	en = "Rolling Steel Timer Improved",
	ru = "Таймер поезда",
	["zh-cn"] = "钢铁列车计时器增强版",
	["zh-tw"] = "鋼鐵列車計時器增強版",
}

mod.localisation = {

	mod_name = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 255, 140, 0 }, { 255, 255, 0 }, true),
		ru = mod.gradientText(mod_name["ru"], { 255, 140, 0 }, { 255, 255, 0 }, true),
		["zh-cn"] = mod.gradientText(mod_name["zh-cn"], { 255, 140, 0 }, { 255, 255, 0 }, true),
		["zh-tw"] = mod.gradientText(mod_name["zh-tw"], { 255, 140, 0 }, { 255, 255, 0 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
	},

	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "Adds a numerical timer to the 'Rolling Steel' *train* operation mission alongside the normal progress bar."
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Author: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Version: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
		ru = "Train timer - Добавляет числовой таймер на миссии *поезда* «Стальной экспресс» наряду с обычной шкалой прогресса.",
		["zh-cn"] = "为「钢铁列车」任务中的列车行动添加数字计时器，与普通进度条并排显示。",
		["zh-tw"] = "為「鋼鐵列車」任務中的列車行動添加數字計時器，與普通進度條並排顯示。",
	},

	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
		ru = "Включить красочные имена",
		["zh-cn"] = "启用名称特效",
		["zh-tw"] = "啟用名稱特效",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужный эффект для текста имени мода. Требуется перезагрузка.\nЕсли включено, вы будете получать небольшой эйфорический опыт каждый раз, когда прокручиваете меню модов.\nЕсли выключено - вы будете Джоном Дарктайдом и без радужных посыпок (но я все равно буду вас любить).",
		["zh-cn"] = "切换模组名称的彩虹颜色效果。需要重新加载。\n启用后，每次滚动模组菜单时你都会获得小小的愉悦体验。\n禁用后，你将失去彩虹点缀（但我仍然爱你）。",
		["zh-tw"] = "切換模組名稱的彩虹顏色效果。需要重新載入。\n啟用後，每次滾動模組選單時你都會獲得小小的愉悅體驗。\n停用後，你將成為一般的黑暗潮汐玩家，失去彩虹點綴（但我仍然愛你）。",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}通用设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}一般設定{#reset()}",
	},
	placeholder = {
		en = "",
		["zh-cn"] = "",
		["zh-tw"] = "",
	},
	placeholder_tooltip = {
		en = "A placeholder entry to initialise the mod menu, does not do anything yet.\nMore features may be added at some point.",
		ru = "Заглушка для инициализации меню мода, пока ничего не делает.\nВозможно, в будущем будут добавлены дополнительные функции.",
		["zh-cn"] = "用于初始化模组菜单的占位符，目前没有任何功能。\n后续可能会添加更多功能。",
		["zh-tw"] = "用於初始化模組選單的佔位符，目前沒有任何功能。\n後續可能會添加更多功能。",
	},
}

mod.toggle_pizazz = function()
	for key, values in pairs(mod.localisation) do
		if key == "mod_name" then
			for language, text in pairs(values) do
				if mod:get("mod_name_pizazz_toggle") then
					mod.localisation[key][language] = mod.localisation["mod_name_pizazz"][language]
				else
					mod.localisation[key][language] = mod.localisation["mod_name_boring"][language]
				end
			end
		end
	end
end

mod.toggle_pizazz()

return mod.localisation
