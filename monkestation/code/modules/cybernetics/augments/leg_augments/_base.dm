/obj/item/organ/internal/cyberimp/leg
	name = "leg-mounted implant"
	desc = "You shouldn't see this! Adminhelp and report this as an issue on github!"
	zone = BODY_ZONE_R_LEG
	icon_state = "implant-toolkit"
	w_class = WEIGHT_CLASS_SMALL
	organ_flags = ORGAN_ROBOTIC
	/// The "base" typepath if this implant needs to be in both legs.
	/// This is a typepath and not true/false so we can properly check subtypes.
	var/double_legged_type = null

/obj/item/organ/internal/cyberimp/leg/Initialize()
	. = ..()
	update_icon()
	SetSlotFromZone()

/obj/item/organ/internal/cyberimp/leg/proc/SetSlotFromZone()
	switch(zone)
		if(BODY_ZONE_R_LEG)
			slot = ORGAN_SLOT_LEFT_LEG_AUG
		if(BODY_ZONE_L_LEG)
			slot = ORGAN_SLOT_RIGHT_LEG_AUG
		else
			CRASH("Invalid zone for [type]")

/obj/item/organ/internal/cyberimp/leg/update_icon()
	. = ..()
	if(zone == BODY_ZONE_R_LEG)
		transform = null
	else // Mirroring the icon
		transform = matrix(-1, 0, 0, 0, 1, 0)

/obj/item/organ/internal/cyberimp/leg/examine(mob/user)
	. = ..()
	. += span_info("[src] is assembled in the [zone == BODY_ZONE_R_LEG ? "right" : "left"] LEG configuration. You can use a screwdriver to reassemble it.")

/obj/item/organ/internal/cyberimp/leg/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return TRUE
	I.play_tool_sound(src)
	if(zone == BODY_ZONE_R_LEG)
		zone = BODY_ZONE_L_LEG
	else
		zone = BODY_ZONE_R_LEG
	SetSlotFromZone()
	to_chat(user, span_notice("You modify [src] to be installed on the [zone == BODY_ZONE_R_LEG ? "right" : "left"] leg."))
	update_icon()

/obj/item/organ/internal/cyberimp/leg/on_insert(mob/living/carbon/organ_owner, special, drop_if_replaced)
	. = ..()
	if(double_legged_type)
		var/other_leg_zone = zone == BODY_ZONE_L_LEG ? BODY_ZONE_R_LEG : BODY_ZONE_L_LEG
		var/in_other_leg = FALSE
		for(var/obj/item/organ/internal/cyberimp/leg/implant as anything in organ_owner.organs)
			if(implant == src || !istype(implant, double_legged_type))
				continue
			if(implant.zone == other_leg_zone)
				in_other_leg = TRUE
				break
		if(!in_other_leg)
			return
	on_full_insert(organ_owner, special, drop_if_replaced)

/obj/item/organ/internal/cyberimp/leg/proc/on_full_insert(mob/living/carbon/organ_owner, special, drop_if_replaced)
	return

/obj/item/organ/internal/cyberimp/leg/emp_act(severity)
	. = ..()
	owner.apply_damage(10,BURN,zone)
