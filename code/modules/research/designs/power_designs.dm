////////////////////////////////////////
//////////////////Power/////////////////
////////////////////////////////////////

/datum/design/basic_cell
	name = "Basic Power Cell"
	desc = "A basic power cell that holds 1 MJ of energy."
	id = "basic_cell"
	build_type = PROTOLATHE | AWAY_LATHE | AUTOLATHE |MECHFAB
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass =SMALL_MATERIAL_AMOUNT * 0.5)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/empty
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_1
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/high_cell
	name = "High-Capacity Power Cell"
	desc = "A power cell that holds 10 MJ of energy."
	id = "high_cell"
	build_type = PROTOLATHE | AWAY_LATHE | AUTOLATHE | MECHFAB
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 0.6)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/high/empty
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_1
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/super_cell
	name = "Super-Capacity Power Cell"
	desc = "A power cell that holds 20 MJ of energy."
	id = "super_cell"
	build_type = PROTOLATHE | AWAY_LATHE | MECHFAB
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 0.7)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/super/empty
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_2
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/hyper_cell
	name = "Hyper-Capacity Power Cell"
	desc = "A power cell that holds 30 MJ of energy."
	id = "hyper_cell"
	build_type = PROTOLATHE | AWAY_LATHE | MECHFAB
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 1.5, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 1.5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 0.8)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/hyper/empty
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_3
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/bluespace_cell
	name = "Bluespace Power Cell"
	desc = "A power cell that holds 40 MJ of energy."
	id = "bluespace_cell"
	build_type = PROTOLATHE | AWAY_LATHE | MECHFAB
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 1.2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 1.6, /datum/material/diamond = SMALL_MATERIAL_AMOUNT * 1.6, /datum/material/titanium =SMALL_MATERIAL_AMOUNT * 3, /datum/material/bluespace =SMALL_MATERIAL_AMOUNT)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/bluespace/empty
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_4
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/inducer
	name = "Inducer"
	desc = "The NT-75 Electromagnetic Power Inducer can wirelessly induce electric charge in an object, allowing you to recharge power cells without having to remove them."
	id = "inducer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/inducer/sci
	category = list(
		RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/pacman
	name = "PACMAN Board"
	desc = "The circuit board for a PACMAN-type portable generator."
	id = "pacman"
	build_path = /obj/item/circuitboard/machine/pacman
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/turbine_part_compressor
	name = "Turbine Compressor"
	desc = "The basic tier of a compressor blade."
	id = "turbine_part_compressor"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5)
	construction_time = 100
	build_path = /obj/item/turbine_parts/compressor
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_TURBINE
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/turbine_part_rotor
	name = "Turbine Rotor"
	desc = "The basic tier of a rotor shaft."
	id = "turbine_part_rotor"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron =SMALL_MATERIAL_AMOUNT*5)
	construction_time = 100
	build_path = /obj/item/turbine_parts/rotor
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_TURBINE
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/turbine_part_stator
	name = "Turbine Stator"
	desc = "The basic tier of a stator."
	id = "turbine_part_stator"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT*5)
	construction_time = 100
	build_path = /obj/item/turbine_parts/stator
	category = list(
		RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_TURBINE
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
