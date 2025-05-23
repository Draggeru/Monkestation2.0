/obj/item/storage/drone_tools
	name = "built-in tools"
	desc = "Access your built-in tools."
	icon = 'icons/hud/screen_drone.dmi'
	icon_state = "tool_storage"
	item_flags = ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/item/storage/drone_tools/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

	var/static/list/drone_builtins = list(
		/obj/item/crowbar/drone,
		/obj/item/screwdriver/drone,
		/obj/item/wrench/drone,
		/obj/item/weldingtool/drone,
		/obj/item/wirecutters/drone,
		/obj/item/multitool/drone,
		/obj/item/pipe_dispenser,
		/obj/item/t_scanner,
		/obj/item/analyzer,
	)
	atom_storage.max_total_storage = 80
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY
	atom_storage.max_slots = 18
	atom_storage.rustle_sound = FALSE
	atom_storage.set_holdable(cant_hold_list = list(/obj/item/storage/backpack/satchel/flat))


/obj/item/storage/drone_tools/PopulateContents()
	var/list/builtintools = list()
	builtintools += new /obj/item/crowbar/drone(src)
	builtintools += new /obj/item/screwdriver/drone(src)
	builtintools += new /obj/item/wrench/drone(src)
	builtintools += new /obj/item/weldingtool/drone(src)
	builtintools += new /obj/item/wirecutters/drone(src)
	builtintools += new /obj/item/multitool/drone(src)
	builtintools += new /obj/item/pipe_dispenser(src)
	builtintools += new /obj/item/t_scanner(src)
	builtintools += new /obj/item/analyzer(src)

	for(var/obj/item/tool as anything in builtintools)
		tool.AddComponent(/datum/component/holderloving, src, TRUE)


/obj/item/crowbar/drone
	name = "built-in crowbar"
	desc = "A crowbar built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "crowbar_cyborg"
	inhand_icon_state = "crowbar"
	item_flags = NO_MAT_REDEMPTION
	toolspeed = 0.5 //Monke, drone tools are as fast as borg tools.

/obj/item/screwdriver/drone
	name = "built-in screwdriver"
	desc = "A screwdriver built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "screwdriver_cyborg"
	inhand_icon_state = "screwdriver"
	item_flags = NO_MAT_REDEMPTION
	random_color = FALSE
	toolspeed = 0.5 //Monke, drone tools are as fast as borg tools.


/obj/item/screwdriver/drone/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file)
	. = ..()
	if(!isinhands)
		return

	var/mutable_appearance/head = mutable_appearance(icon_file, "screwdriver_head")
	head.appearance_flags = RESET_COLOR
	. += head

/obj/item/wrench/drone
	name = "built-in wrench"
	desc = "A wrench built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "wrench_cyborg"
	inhand_icon_state = "wrench"
	item_flags = NO_MAT_REDEMPTION
	toolspeed = 0.5 //Monke, drone tools are as fast as borg tools.

/obj/item/weldingtool/drone
	name = "built-in welding tool"
	desc = "A welding tool built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "indwelder_cyborg"
	item_flags = NO_MAT_REDEMPTION
	toolspeed = 0.5 //Monke, drone tools are as fast as borg tools.
	max_fuel = 40 //And have large welding tanks.

/obj/item/wirecutters/drone
	name = "built-in wirecutters"
	desc = "Wirecutters built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "wirecutters_cyborg"
	inhand_icon_state = "cutters"
	item_flags = NO_MAT_REDEMPTION
	random_color = FALSE
	toolspeed = 0.5 //Monke, drone tools are as fast as borg tools.

/obj/item/multitool/drone
	name = "built-in multitool"
	desc = "A multitool built into your chassis."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "multitool_cyborg"
	item_flags = NO_MAT_REDEMPTION
	toolspeed = 0.5
