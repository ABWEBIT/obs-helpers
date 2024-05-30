obs = obslua
source_name = ""

totalTime = 0
cur_seconds = 0

showHours = true
showTimer = true
activated = false

function script_description()
	return "Таймер обратного отсчёта"
end

function set_time_text()
	local seconds = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes = math.floor(total_minutes % 60)
	local hours = math.floor(total_minutes / 60)
  local text

  if showHours == true 
    then text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else text = string.format("%02d:%02d", minutes, seconds)
  end

  if cur_seconds < 1
    then if showTimer == false then text = "" end
  end

  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
  end
end

function timer_callback()
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		obs.remove_current_callback()
		cur_seconds = 0
	end

	set_time_text()
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		cur_seconds = totalTime
		set_time_text()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function script_properties()
	local props = obs.obs_properties_create()
  obs.obs_properties_add_int(props, "input_hours", "Часы", 0, 24, 1)
  obs.obs_properties_add_bool(props, "show_hours", "Показывать часы")

  obs.obs_properties_add_int(props, "input_minutes", "Минуты", 0, 60, 1)
  obs.obs_properties_add_int(props, "input_seconds", "Секунды", 0, 60, 1)
  
	local p = obs.obs_properties_add_list(props, "source", "Источник", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)
  obs.obs_properties_add_bool(props, "show_timer", "Показывать таймер по завершению")

	return props
end

function script_update(settings)
	activate(false)
  local hours = obs.obs_data_get_int(settings, "input_hours") * 60 * 60
  local minutes = obs.obs_data_get_int(settings, "input_minutes") * 60
  local seconds = obs.obs_data_get_int(settings, "input_seconds")
	totalTime = hours + minutes + seconds

  if obs.obs_data_get_bool(settings, "show_hours") == true
    then showHours = true
    else showHours = false
  end
  
  if obs.obs_data_get_bool(settings, "show_timer") == true
    then showTimer = true
    else showTimer = false
  end

	source_name = obs.obs_data_get_string(settings, "source")
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function script_defaults(settings)
  showHours = true
  obs.obs_data_set_default_int(settings, "input_hours", 0)
  obs.obs_data_set_default_bool(settings, "show_hours", true)
  obs.obs_data_set_default_int(settings, "input_minutes", 0)
  obs.obs_data_set_default_int(settings, "input_seconds", 0)
  showTimer = true
  obs.obs_data_set_default_bool(settings, "show_timer", true)
end

function script_load(settings)
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)
end
