/obj/machinery/atmospherics/components/binary/pressure_valve
	icon_state = "pvalve_map-3"
	name = "pressure valve"
	desc = "An activable one way valve that let gas pass through if the pressure on the input side is higher than the set pressure."
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	construction_type = /obj/item/pipe/directional
	pipe_state = "pvalve"
	use_power = NO_POWER_USE
	///Amount of pressure needed before the valve for it to open
	var/target_pressure = ONE_ATMOSPHERE
	///Check if the gas is moving from one pipenet to the other
	var/is_gas_flowing = FALSE

/obj/machinery/atmospherics/components/binary/pressure_valve/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_ALT_CLICK_BLOCKER, INNATE_TRAIT)
	register_context()

/obj/machinery/atmospherics/components/binary/pressure_valve/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	context[SCREENTIP_CONTEXT_CTRL_LMB] = "Turn [on ? "off" : "on"]"
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Set to maximum recommended target pressure"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/atmospherics/components/binary/pressure_valve/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		balloon_alert(user, "turned [on ? "on" : "off"]")
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/binary/pressure_valve/AltClick(mob/user)
	if(can_interact(user))
		target_pressure = MAX_OUTPUT_PRESSURE
		investigate_log("was set to [target_pressure] kPa by [key_name(user)]", INVESTIGATE_ATMOS)
		balloon_alert(user, "target pressure set to [target_pressure] kPa")
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/binary/pressure_valve/update_icon_nopipes()
	if(on && is_operational && is_gas_flowing)
		icon_state = "pvalve_flow-[set_overlay_offset(piping_layer)]"
	else if(on && is_operational && !is_gas_flowing)
		icon_state = "pvalve_on-[set_overlay_offset(piping_layer)]"
	else
		icon_state = "pvalve_off-[set_overlay_offset(piping_layer)]"

/obj/machinery/atmospherics/components/binary/pressure_valve/process_atmos()

	if(!on || !is_operational)
		return

	var/datum/gas_mixture/input_air = airs[1]
	var/datum/gas_mixture/output_air = airs[2]
	var/datum/gas_mixture/output_pipenet_air = parents[2].air

	if(input_air.return_pressure() > target_pressure)
		if(input_air.release_gas_to(output_air, input_air.return_pressure(), output_pipenet_air = output_pipenet_air))
			update_parents()
			is_gas_flowing = TRUE
	else
		is_gas_flowing = FALSE
	update_icon_nopipes()

/obj/machinery/atmospherics/components/binary/pressure_valve/relaymove(mob/living/user, direction)
	if(!on || direction != dir)
		return
	. = ..()

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosPump", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_data()
	var/data = list()
	data["on"] = on
	data["pressure"] = round(target_pressure)
	data["max_pressure"] = round(MAX_PASSIVE_OUTPUT_PRESSURE)
	return data

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "max")
				pressure = MAX_PASSIVE_OUTPUT_PRESSURE
				. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				target_pressure = clamp(pressure, 0, MAX_PASSIVE_OUTPUT_PRESSURE)
				investigate_log("was set to [target_pressure] kPa by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_appearance()

/obj/machinery/atmospherics/components/binary/pressure_valve/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, span_warning("You cannot unwrench [src], turn it off first!"))
		return FALSE


/obj/machinery/atmospherics/components/binary/pressure_valve/layer2
	piping_layer = 2
	icon_state= "pvalve_map-2"

/obj/machinery/atmospherics/components/binary/pressure_valve/layer4
	piping_layer = 4
	icon_state= "pvalve_map-4"

/obj/machinery/atmospherics/components/binary/pressure_valve/on
	on = TRUE
	icon_state = "pvalve_on_map-3"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer2
	piping_layer = 2
	icon_state= "pvalve_on_map-2"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer4
	piping_layer = 4
	icon_state= "pvalve_on_map-4"
