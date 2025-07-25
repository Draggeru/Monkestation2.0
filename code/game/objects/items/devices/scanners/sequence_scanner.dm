/obj/item/sequence_scanner
	name = "genetic sequence scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "gene"
	inhand_icon_state = "healthanalyzer"
	worn_icon_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held scanner for analyzing someones gene sequence on the fly. Use on a DNA console to update the internal database."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*2)

	var/list/discovered = list() //hit a dna console to update the scanners database
	var/list/buffer
	var/ready = TRUE
	var/cooldown = 200

/obj/item/sequence_scanner/attack(mob/living/target, mob/living/carbon/human/user)
	add_fingerprint(user)
	//no scanning if its a husk or DNA-less Species
	if (!HAS_TRAIT(target, TRAIT_GENELESS) && !HAS_TRAIT(target, TRAIT_BADDNA))
		user.visible_message(span_notice("[user] analyzes [target]'s genetic sequence."))
		balloon_alert(user, "sequence analyzed")
		playsound(user.loc, 'sound/items/healthanalyzer.ogg', 50) // close enough
		gene_scan(target, user)
	else
		user.visible_message(span_notice("[user] fails to analyze [target]'s genetic sequence."), span_warning("[target] has no readable genetic sequence!"))

/obj/item/sequence_scanner/attack_self(mob/user)
	display_sequence(user)

/obj/item/sequence_scanner/attack_self_tk(mob/user)
	return

/obj/item/sequence_scanner/afterattack(obj/object, mob/user, proximity)
	. = ..()
	var/obj/machinery/computer/dna_console/console = object
	if(!istype(console) || !proximity)
		return
	if(console.stored_research)
		to_chat(user, span_notice("[name] linked to central research database."))
		discovered = console.stored_research.discovered_mutations
	else
		to_chat(user, span_warning("No database to update from."))

/obj/item/sequence_scanner/proc/gene_scan(mob/living/carbon/target, mob/living/user)
	if(!iscarbon(target) || !target.has_dna())
		return

	//add target mutations to list as well as extra mutations.
	//dupe list as scanner could modify target data
	buffer = LAZYLISTDUPLICATE(target.dna.mutation_index)
	var/list/active_mutations = list()
	for(var/datum/mutation/mutation in target.dna.mutations)
		LAZYOR(buffer, mutation.type)
		active_mutations.Add(mutation.type)

	var/list/lines = list()
	lines += span_notice("Subject [span_name(target.name)]'s DNA sequence has been saved to buffer.")
	lines += span_boldnotice("Genetic Stability: ") + "[target.dna.stability]%"
	for(var/mutation in buffer)
		//highlight activated mutations
		if(LAZYFIND(active_mutations, mutation))
			lines += span_boldnotice("[get_display_name(mutation)]")
		else
			lines += span_notice("[get_display_name(mutation)]")
	var/title = "<img class='icon bigicon' src='\ref[icon]?state=[url_encode(icon_state)]'> " + span_bold("Genetic Sequence Analysis")
	to_chat(user, fieldset_block(title, jointext(lines, "<br>"), "boxed_message blue_box"), type = MESSAGE_TYPE_INFO)

/obj/item/sequence_scanner/proc/display_sequence(mob/living/user)
	if(!LAZYLEN(buffer) || !ready)
		return
	var/list/options = list()
	for(var/mutation in buffer)
		options += get_display_name(mutation)

	var/answer = tgui_input_list(user, "Analyze Potential", "Sequence Analyzer", sort_list(options))
	if(isnull(answer))
		return
	if(!ready || !user.can_perform_action(src, NEED_LITERACY|NEED_LIGHT|FORBID_TELEKINESIS_REACH))
		return

	var/sequence
	for(var/mutation in buffer) //this physically hurts but i dont know what anything else short of an assoc list
		if(get_display_name(mutation) == answer)
			sequence = buffer[mutation]
			break

	if(sequence)
		var/display
		for(var/i in 0 to length_char(sequence) / DNA_MUTATION_BLOCKS-1)
			if(i)
				display += "-"
			display += copytext_char(sequence, 1 + i*DNA_MUTATION_BLOCKS, DNA_MUTATION_BLOCKS*(1+i) + 1)

		to_chat(user, "[span_boldnotice("[display]")]<br>")

	ready = FALSE
	icon_state = "[icon_state]_recharging"
	addtimer(CALLBACK(src, PROC_REF(recharge)), cooldown, TIMER_UNIQUE)

/obj/item/sequence_scanner/proc/recharge()
	icon_state = initial(icon_state)
	ready = TRUE

/obj/item/sequence_scanner/proc/get_display_name(mutation)
	var/datum/mutation/mutation_instance = GET_INITIALIZED_MUTATION(mutation)
	if(!mutation_instance)
		return "ERROR"
	if(mutation in discovered)
		return  "[mutation_instance.name] ([mutation_instance.alias])"
	else
		return mutation_instance.alias
