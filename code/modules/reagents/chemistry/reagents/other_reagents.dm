/datum/reagent/blood
	data = list(
		// Actually Relevant
		"viruses" = null, // Refernces to virus datums in this blood
		"blood_DNA" = null, // DNA of the guy who the blood came from
		"blood_type" = null, // /datum/blood_type of the blood
		"resistances" = null, // Viruses the blood is vaccinated against
		"immunity" = null,
		// Unused? (but cool)
		"trace_chem" = null, // Param list of all chems in the blood at the time the sample was taken (type to volume)
		// Used for podperson shit
		"mind" = null, // Ref to the mind of the guy who the blood came from
		"ckey" = null, // Ckey of the guy who the blood came from
		"gender" = null, // Gender of the guy when the blood was taken
		"real_name" = null, // Real name of the guy when the blood was taken
		"cloneable" = null, // Tracks if the guy who the blood came from suicided or not
		"factions" = null, // Factions the guy who the blood came from was in
		"quirks" = null, // Quirk typepaths of the guy who the blood came from had
		)
	name = "Blood"
	color = COLOR_BLOOD
	metabolization_rate = 12.5 * REAGENTS_METABOLISM //fast rate so it disappears fast.
	taste_description = "iron"
	taste_mult = 1.3
	penetrates_skin = NONE
	ph = 7.4
	default_container = /obj/item/reagent_containers/blood
	opacity = 230
	turf_exposure = TRUE
	chemical_flags = REAGENT_IGNORE_STASIS|REAGENT_DEAD_PROCESS

/datum/glass_style/shot_glass/blood
	required_drink_type = /datum/reagent/blood
	icon_state = "shotglassred"

/datum/glass_style/drinking_glass/blood
	required_drink_type = /datum/reagent/blood
	name = "glass of tomato juice"
	desc = "Are you sure this is tomato juice?"
	icon_state = "glass_red"

/datum/reagent/blood/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	for(var/datum/disease/strain as anything in data?["viruses"])
		if(istype(strain, /datum/disease/acute))
			var/datum/disease/acute/advanced = strain
			if(methods & (INJECT|INGEST|PATCH))
				exposed_mob.infect_disease(advanced, TRUE, "(Contact, splashed with infected blood)")
			if((methods & (TOUCH | VAPOR)) && (advanced.spread_flags & DISEASE_SPREAD_BLOOD))
				if(exposed_mob.check_bodypart_bleeding(BODY_ZONE_EVERYTHING))
					exposed_mob.infect_disease(advanced, notes="(Blood, splashed with infected blood)")

	var/datum/blood_type/blood = exposed_mob.get_blood_type()
	if(blood?.reagent_type == type && ((methods & INJECT) || ((methods & INGEST))))
		if(data["blood_type"] in blood.compatible_types)
			exposed_mob.blood_volume = min(exposed_mob.blood_volume + round(reac_volume, 0.1), BLOOD_VOLUME_MAXIMUM)
		else
			exposed_mob.reagents.add_reagent(/datum/reagent/toxin, reac_volume * 0.5)

		exposed_mob.reagents.remove_reagent(type, reac_volume) // Because we don't want blood to just lie around in the patient's blood, makes no sense.


/datum/reagent/blood/on_new(list/data)
	. = ..()
	if(istype(data))
		SetViruses(src, data)
		color = GLOB.blood_types[data["blood_type"]]?.color || COLOR_BLOOD

/datum/reagent/blood/on_merge(list/mix_data)
	if(data && mix_data)
		if(data["blood_DNA"] != mix_data["blood_DNA"])
			data["cloneable"] = 0 //On mix, consider the genetic sampling unviable for pod cloning if the DNA sample doesn't match.
		if(data["viruses"] || mix_data["viruses"])

			var/list/mix1 = data["viruses"]
			var/list/mix2 = mix_data["viruses"]

			// Stop issues with the list changing during mixing.
			var/list/to_mix = list()

			for(var/datum/disease/advance/AD in mix1)
				to_mix += AD
			for(var/datum/disease/advance/AD in mix2)
				to_mix += AD

			var/datum/disease/advance/AD = Advance_Mix(to_mix)
			if(AD)
				var/list/preserve = list(AD)
				for(var/D in data["viruses"])
					if(!istype(D, /datum/disease/advance))
						preserve += D
				data["viruses"] = preserve
	return 1

/datum/reagent/blood/proc/get_diseases()
	. = list()
	if(data && data["viruses"])
		for(var/thing in data["viruses"])
			var/datum/disease/D = thing
			. += D

/datum/reagent/blood/expose_turf(turf/exposed_turf, reac_volume)//splash the blood all over the place
	. = ..()
	if(!istype(exposed_turf))
		return
	if(reac_volume < 3)
		return

	var/obj/effect/decal/cleanable/blood/bloodsplatter = locate() in exposed_turf //find some blood here
	if(!bloodsplatter)
		bloodsplatter = new(exposed_turf, data["viruses"])
	else if(LAZYLEN(data["viruses"]))
		var/list/viri_to_add = list()
		for(var/datum/disease/virus in data["viruses"])
			if(virus.spread_flags & DISEASE_SPREAD_CONTACT_FLUIDS)
				viri_to_add += virus
		if(LAZYLEN(viri_to_add))
			bloodsplatter.AddComponent(/datum/component/infective, viri_to_add)
	if(data["blood_DNA"])
		bloodsplatter.add_blood_DNA(list(data["blood_DNA"] = data["blood_type"]))

/datum/reagent/consumable/liquidgibs
	name = "Liquid gibs"
	color = "#CC4633"
	description = "You don't even want to think about what's in here."
	taste_description = "gross iron"
	nutriment_factor = 2 * REAGENTS_METABOLISM
	material = /datum/material/meat
	ph = 7.45
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/glass_style/shot_glass/liquidgibs
	required_drink_type = /datum/reagent/consumable/liquidgibs
	icon_state = "shotglassred"

/datum/reagent/bone_dust
	name = "Bone Dust"
	color = "#dbcdcb"
	description = "Ground up bones, gross!"
	taste_description = "the most disgusting grain in existence"

/datum/reagent/vaccine
	//data must contain virus type
	name = "Vaccine"
	color = "#C81040" // rgb: 200, 16, 64
	taste_description = "slime"
	penetrates_skin = NONE

/datum/reagent/vaccine/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	if(!islist(data) || !(methods & (INGEST|INJECT)))
		return

	for(var/thing in exposed_mob.diseases)
		var/datum/disease/infection = thing
		if(infection.GetDiseaseID() in data)
			infection.cure()
	LAZYOR(exposed_mob.disease_resistances, data)

/datum/reagent/vaccine/on_merge(list/data)
	if(istype(data))
		src.data |= data.Copy()

/datum/reagent/vaccine/fungal_tb
	name = "Vaccine (Fungal Tuberculosis)"

/datum/reagent/vaccine/fungal_tb/New(data)
	. = ..()
	var/list/cached_data
	if(!data)
		cached_data = list()
	else
		cached_data = data
	cached_data |= "[/datum/disease/acute/premade/fungal_tb]"
	src.data = cached_data

/datum/reagent/water
	name = "Water"
	description = "An ubiquitous chemical substance that is composed of hydrogen and oxygen."
	color = "#00B8FF" // rgb: 170, 170, 170, 77 (alpha)
	taste_description = "water"
	evaporation_rate = 4 // water goes fast
	var/cooling_temperature = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_CLEANS
	default_container = /obj/item/reagent_containers/cup/glass/waterbottle

/datum/glass_style/shot_glass/water
	required_drink_type = /datum/reagent/water
	icon_state = "shotglassclear"

/datum/glass_style/drinking_glass/water
	required_drink_type = /datum/reagent/water
	name = "glass of water"
	desc = "The father of all refreshments."
	icon_state = "glass_clear"

/*
 * Water reaction to turf
 */

/datum/reagent/water/expose_turf(turf/open/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return

	var/cool_temp = cooling_temperature
	if(reac_volume >= 5)
		exposed_turf.MakeSlippery(TURF_WET_WATER, 10 SECONDS, min(reac_volume*1.5 SECONDS, 60 SECONDS))

	for(var/mob/living/basic/slime/exposed_slime in exposed_turf)
		exposed_slime.apply_water()

	var/obj/effect/hotspot/hotspot = (locate(/obj/effect/hotspot) in exposed_turf)
	if(hotspot && !isspaceturf(exposed_turf))
		if(exposed_turf.air)
			var/datum/gas_mixture/air = exposed_turf.air
			air.temperature = max(min(air.temperature-(cool_temp*1000), air.temperature/cool_temp),TCMB)
			air.react(src)
			qdel(hotspot)

/*
 * Water reaction to an object
 */

/datum/reagent/water/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()
	exposed_obj.extinguish()
	exposed_obj.wash(CLEAN_TYPE_ACID)
	// Monkey cube
	if(istype(exposed_obj, /obj/item/food/monkeycube))
		var/obj/item/food/monkeycube/cube = exposed_obj
		cube.Expand()

	// Dehydrated carp
	else if(istype(exposed_obj, /obj/item/toy/plush/carpplushie/dehy_carp))
		var/obj/item/toy/plush/carpplushie/dehy_carp/dehy = exposed_obj
		dehy.Swell() // Makes a carp

	else if(istype(exposed_obj, /obj/item/stack/sheet/hairlesshide))
		var/obj/item/stack/sheet/hairlesshide/HH = exposed_obj
		new /obj/item/stack/sheet/wethide(get_turf(HH), HH.amount)
		qdel(HH)


/// How many wet stacks you get per units of water when it's applied by touch.
#define WATER_TO_WET_STACKS_FACTOR_TOUCH 0.5
/// How many wet stacks you get per unit of water when it's applied by vapor. Much less effective than by touch, of course.
#define WATER_TO_WET_STACKS_FACTOR_VAPOR 0.1


/**
 * Water reaction to a mob
 */
#define WAS_SPRAYED "was_sprayed" //monkestation edit

/datum/reagent/water/expose_mob(mob/living/exposed_mob, methods = TOUCH, reac_volume)//Splashing people with water can help put them out!
	. = ..()
	if(methods & TOUCH)
		exposed_mob.extinguish_mob() // extinguish removes all fire stacks
		exposed_mob.adjust_wet_stacks(reac_volume * WATER_TO_WET_STACKS_FACTOR_TOUCH) // Water makes you wet, at a 50% water-to-wet-stacks ratio. Which, in turn, gives you some mild protection from being set on fire!

	if(methods & VAPOR)
		exposed_mob.adjust_wet_stacks(reac_volume * WATER_TO_WET_STACKS_FACTOR_VAPOR) // Spraying someone with water with the hope to put them out is just simply too funny to me not to add it.

		exposed_mob.incapacitate(1) // startles the felinid, canceling any do_after
		exposed_mob.add_mood_event("watersprayed", /datum/mood_event/watersprayed)

	if(isoozeling(exposed_mob))
		if(HAS_TRAIT(exposed_mob, TRAIT_SLIME_HYDROPHOBIA))
			to_chat(exposed_mob, span_warning("Water splashes against your oily membrane and rolls right off your body!"))
			return
		exposed_mob.blood_volume = max(exposed_mob.blood_volume - 30, 0)
		to_chat(exposed_mob, span_warning("The water causes you to melt away!"))

	//MONKESTATION EDIT START
	if(!is_cat_enough(exposed_mob, include_all_anime = TRUE))
		return

	var/mob/living/victim = exposed_mob
	if((methods & (TOUCH|VAPOR)) && !victim.is_pepper_proof() && !HAS_TRAIT(victim, TRAIT_FEARLESS))
		victim.set_eye_blur_if_lower(3 SECONDS)
		victim.set_confusion_if_lower(5 SECONDS)
		if(ishuman(victim))
			victim.add_mood_event("watersprayed", /datum/mood_event/watersprayed/cat)
		victim.update_damage_hud()
		if(HAS_TRAIT(victim, WAS_SPRAYED))
			return
		ADD_TRAIT(victim, WAS_SPRAYED, TRAIT_GENERIC)
		if(prob(50))
			INVOKE_ASYNC(victim, TYPE_PROC_REF(/mob, emote), "hiss")
		else
			INVOKE_ASYNC(victim, TYPE_PROC_REF(/mob, emote), "scream")
		addtimer(TRAIT_CALLBACK_REMOVE(victim, WAS_SPRAYED, TRAIT_GENERIC), 1 SECONDS)
	//MONKESTATION EDIT STOP

#undef WAS_SPRAYED //monkestation edit

#undef WATER_TO_WET_STACKS_FACTOR_TOUCH
#undef WATER_TO_WET_STACKS_FACTOR_VAPOR


/datum/reagent/water/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	if(!HAS_TRAIT(affected_mob, TRAIT_NOBLOOD))
		affected_mob.blood_volume += 0.1 * REM * seconds_per_tick // water is good for you!

/datum/reagent/water/salt
	name = "Saltwater"
	description = "Water, but salty. Smells like... the station infirmary?"
	color = "#aaaaaa9d" // rgb: 170, 170, 170, 77 (alpha)
	taste_description = "the sea"
	cooling_temperature = 3
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_CLEANS
	default_container = /obj/item/reagent_containers/cup/glass/waterbottle

/datum/glass_style/shot_glass/water/salt
	required_drink_type = /datum/reagent/water/salt
	icon_state = "shotglassclear"

/datum/glass_style/drinking_glass/water/salt
	required_drink_type = /datum/reagent/water/salt
	name = "glass of saltwater"
	desc = "If you have a sore throat, gargle some saltwater and watch the pain go away. Can be used as a very improvised topical medicine against wounds."
	icon_state = "glass_clear"

/datum/reagent/water/salt/expose_mob(mob/living/exposed_mob, methods, reac_volume)
	. = ..()
	var/mob/living/carbon/carbies = exposed_mob
	if(!(methods & (PATCH|TOUCH|VAPOR)))
		return
	for(var/datum/wound/iter_wound as anything in carbies.all_wounds)
		iter_wound.on_saltwater(reac_volume, carbies)

// Mixed salt with water! All the help of salt with none of the irritation. Plus increased volume.
/datum/wound/proc/on_saltwater(reac_volume, mob/living/carbon/carbies)
	return

/datum/wound/pierce/bleed/on_saltwater(reac_volume, mob/living/carbon/carbies)
	adjust_blood_flow(-0.06 * reac_volume, initial_flow * 0.6)
	to_chat(carbies, span_notice("The salt water splashes over [lowertext(src)], soaking up the blood."))

/datum/wound/slash/flesh/on_saltwater(reac_volume, mob/living/carbon/carbies)
	adjust_blood_flow(-0.1 * reac_volume, initial_flow * 0.5)
	to_chat(carbies, span_notice("The salt water splashes over [lowertext(src)], soaking up the blood."))

/datum/wound/burn/flesh/on_saltwater(reac_volume)
	// Similar but better stats from normal salt.
	sanitization += VALUE_PER(0.6, 30) * reac_volume
	infestation -= max(VALUE_PER(0.5, 30) * reac_volume, 0)
	infestation_rate += VALUE_PER(0.07, 30) * reac_volume
	to_chat(victim, span_notice("The salt water splashes over [lowertext(src)], soaking up the... miscellaneous fluids. It feels somewhat better afterwards."))
	return

/datum/reagent/water/holywater
	name = "Holy Water"
	description = "Water blessed by some deity."
	color = "#E0E8EF" // rgb: 224, 232, 239
	self_consuming = TRUE //divine intervention won't be limited by the lack of a liver
	ph = 7.5 //God is alkaline
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_CLEANS
	default_container = /obj/item/reagent_containers/cup/glass/bottle/holywater
	turf_exposure = TRUE
	metabolized_traits = list(TRAIT_HOLY)

/datum/glass_style/drinking_glass/holywater
	required_drink_type = /datum/reagent/water/holywater
	name = "glass of holy water"
	desc = "A glass of holy water."
	icon_state = "glass_clear"

/datum/reagent/water/holywater/on_mob_add(mob/living/affected_mob, amount)
	. = ..()
	if(data)
		data["misc"] = 0

/datum/reagent/water/holywater/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(IS_CULTIST(exposed_mob))
		to_chat(exposed_mob, span_userdanger("A vile holiness begins to spread its shining tendrils through your mind, purging the Geometer of Blood's influence!"))
	if(IS_CLOCK(exposed_mob)) //monkestation edit
		to_chat(exposed_mob, span_userdanger("Your mind burns in agony as you feel the light of the Justicar being ripped away from you by something else!")) //monkestation edit

/datum/reagent/water/holywater/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	// monkestation edit start
	/* original - this version of the code depends on https://github.com/tgstation/tgstation/pull/78657 which has not been ported yet
	. = ..()

	data["deciseconds_metabolized"] += (seconds_per_tick * 1 SECONDS * REM)

	affected_mob.adjust_jitter_up_to(4 SECONDS * REM * seconds_per_tick, 20 SECONDS)
	var/need_mob_update = FALSE

	if(IS_CULTIST(affected_mob))
		for(var/datum/action/innate/cult/blood_magic/BM in affected_mob.actions)
			var/removed_any = FALSE
			for(var/datum/action/innate/cult/blood_spell/BS in BM.spells)
				removed_any = TRUE
				qdel(BS)
			if(removed_any)
				to_chat(affected_mob, span_cult_large("Your blood rites falter as holy water scours your body!"))

	if(data["deciseconds_metabolized"] >= (25 SECONDS)) // 10 units
		affected_mob.adjust_stutter_up_to(4 SECONDS * REM * seconds_per_tick, 20 SECONDS)
		affected_mob.set_dizzy_if_lower(10 SECONDS)
		if(IS_CULTIST(affected_mob) && SPT_PROB(10, seconds_per_tick))
			affected_mob.say(pick("Av'te Nar'Sie","Pa'lid Mors","INO INO ORA ANA","SAT ANA!","Daim'niodeis Arc'iai Le'eones","R'ge Na'sie","Diabo us Vo'iscum","Eld' Mon Nobis"), forced = "holy water")
			if(prob(10))
				affected_mob.visible_message(span_danger("[affected_mob] starts having a seizure!"), span_userdanger("You have a seizure!"))
				affected_mob.Unconscious(12 SECONDS)
				to_chat(affected_mob, span_cult_large("[pick("Your blood is your bond - you are nothing without it", "Do not forget your place", \
					"All that power, and you still fail?", "If you cannot scour this poison, I shall scour your meager life!")]."))
		else if(HAS_TRAIT(affected_mob, TRAIT_EVIL) && SPT_PROB(25, seconds_per_tick)) //Congratulations, your committment to evil has now made holy water a deadly poison to you!
			if(!IS_CULTIST(affected_mob) || affected_mob.mind?.holy_role != HOLY_ROLE_PRIEST)
				affected_mob.emote("scream")
				need_mob_update += affected_mob.adjustFireLoss(3 * REM * seconds_per_tick, updating_health = FALSE)

	if(data["deciseconds_metabolized"] >= (1 MINUTES)) // 24 units
		if(IS_CULTIST(affected_mob))
			affected_mob.mind.remove_antag_datum(/datum/antagonist/cult)
			affected_mob.Unconscious(10 SECONDS)
		else if(HAS_TRAIT(affected_mob, TRAIT_EVIL)) //At this much holy water, you're probably going to fucking melt. good luck
			if(!IS_CULTIST(affected_mob) || affected_mob.mind?.holy_role != HOLY_ROLE_PRIEST)
				need_mob_update += affected_mob.adjustFireLoss(10 * REM * seconds_per_tick, updating_health = FALSE)
		affected_mob.remove_status_effect(/datum/status_effect/jitter)
		affected_mob.remove_status_effect(/datum/status_effect/speech/stutter)
		holder?.remove_reagent(type, volume) // maybe this is a little too perfect and a max() cap on the statuses would be better??
	if(need_mob_update)
		return UPDATE_MOB_HEALTH
	*/
	if(affected_mob.blood_volume)
		affected_mob.blood_volume += 0.1 * REM * seconds_per_tick // water is good for you!
	if(!data)
		data = list("misc" = 0)

	data["misc"] += seconds_per_tick SECONDS * REM
	affected_mob.adjust_jitter_up_to(4 SECONDS * seconds_per_tick, 20 SECONDS)
	if(IS_CULTIST(affected_mob) || affected_mob.mind?.has_antag_datum(/datum/antagonist/clock_cultist))
		if(handle_cultists(affected_mob, seconds_per_tick)) //only returns TRUE on deconversion
			return
	holder.remove_reagent(type, 1 * REAGENTS_METABOLISM * seconds_per_tick) //fixed consumption to prevent balancing going out of whack

	var/need_mob_update = FALSE

	if (!HAS_TRAIT(affected_mob, TRAIT_EVIL) || IS_CULTIST(affected_mob) || affected_mob.mind?.holy_role == HOLY_ROLE_PRIEST)
		return
	if(data["misc"] >= (25 SECONDS)) // 10 units
		affected_mob.adjust_stutter_up_to(4 SECONDS * REM * seconds_per_tick, 20 SECONDS)
		affected_mob.set_dizzy_if_lower(10 SECONDS)
		if(SPT_PROB(25, seconds_per_tick)) //Congratulations, your committment to evil has now made holy water a deadly poison to you!
			affected_mob.emote("scream")
			need_mob_update += affected_mob.adjustFireLoss(3 * REM * seconds_per_tick, updating_health = FALSE)
	if(data["misc"] >= (1 MINUTES)) // 24 units
		need_mob_update += affected_mob.adjustFireLoss(10 * REM * seconds_per_tick, updating_health = FALSE)
		affected_mob.remove_status_effect(/datum/status_effect/jitter)
		affected_mob.remove_status_effect(/datum/status_effect/speech/stutter)
		holder?.remove_reagent(type, volume) // maybe this is a little too perfect and a max() cap on the statuses would be better??
	return need_mob_update
	// monkestation edit edit

/datum/reagent/water/holywater/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return
	if(reac_volume >= 10)
		for(var/obj/effect/rune/R in exposed_turf)
			qdel(R)
	exposed_turf.Bless()

//monkestation edit start
/datum/reagent/water/holywater/proc/handle_cultists(mob/living/carbon/affected_mob, seconds_per_tick)
	if(IS_CULTIST(affected_mob))
		for(var/datum/action/innate/cult/blood_magic/BM in affected_mob.actions)
			for(var/datum/action/innate/cult/blood_spell/BS in BM.spells)
				to_chat(affected_mob, span_cultlarge("Your blood rites falter as holy water scours your body!"))
				qdel(BS)

	var/list/phrase_list
	if(IS_CULTIST(affected_mob)) //snowflakey but it works
		var/datum/antagonist/cult/cult_datum = affected_mob.mind.has_antag_datum(/datum/antagonist/cult)
		phrase_list = cult_datum?.cultist_deconversion_phrases
	else if(IS_CLOCK(affected_mob))
		var/datum/antagonist/clock_cultist/servant_datum = affected_mob.mind.has_antag_datum(/datum/antagonist/clock_cultist)
		phrase_list = servant_datum?.servant_deconversion_phrases

	if(data["misc"] >= (25 SECONDS)) // 10 units
		affected_mob.adjust_stutter_up_to(4 SECONDS * seconds_per_tick, 20 SECONDS)
		affected_mob.set_dizzy_if_lower(10 SECONDS)
		if(SPT_PROB(10, seconds_per_tick))
			if(phrase_list)
				affected_mob.say(pick(phrase_list["spoken"]), forced = "holy water")
			if(prob(10))
				affected_mob.visible_message(span_danger("[affected_mob] starts having a seizure!"), span_userdanger("You have a seizure!"))
				affected_mob.Unconscious(12 SECONDS)
				var/span_type
				if(IS_CULTIST(affected_mob))
					span_type = "cultlarge"
				else if(IS_CLOCK(affected_mob))
					span_type = "big_brass"
				if(phrase_list)
					to_chat(affected_mob, "<span class=[span_type]>[pick(phrase_list["seizure"])].</span>")

	if(data["misc"] >= (1 MINUTES)) // 24 units
		if(IS_CULTIST(affected_mob))
			affected_mob.mind.remove_antag_datum(/datum/antagonist/cult)
		if(IS_CLOCK(affected_mob))
			affected_mob.mind.remove_antag_datum(/datum/antagonist/clock_cultist)
		affected_mob.Unconscious(10 SECONDS)
		affected_mob.remove_status_effect(/datum/status_effect/jitter)
		affected_mob.remove_status_effect(/datum/status_effect/speech/stutter)
		holder.remove_reagent(type, volume) // maybe this is a little too perfect and a max() cap on the statuses would be better??
		return TRUE
//monkestation edit end

/datum/reagent/water/hollowwater
	name = "Hollow Water"
	description = "An ubiquitous chemical substance that is composed of hydrogen and oxygen, but it looks kinda hollow."
	color = "#88878777"
	taste_description = "emptyiness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/hydrogen_peroxide
	name = "Hydrogen Peroxide"
	description = "An ubiquitous chemical substance that is composed of hydrogen and oxygen and oxygen." //intended intended
	color = "#AAAAAA77" // rgb: 170, 170, 170, 77 (alpha)
	taste_description = "burning water"
	var/cooling_temperature = 2
	ph = 6.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	turf_exposure = TRUE

/datum/glass_style/shot_glass/hydrogen_peroxide
	required_drink_type = /datum/reagent/hydrogen_peroxide
	icon_state = "shotglassclear"

/datum/glass_style/drinking_glass/hydrogen_peroxide
	required_drink_type = /datum/reagent/hydrogen_peroxide
	name = "glass of oxygenated water"
	desc = "The father of all refreshments. Surely it tastes great, right?"
	icon_state = "glass_clear"

/*
 * Water reaction to turf
 */

/datum/reagent/hydrogen_peroxide/expose_turf(turf/open/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return
	if(reac_volume >= 5)
		exposed_turf.MakeSlippery(TURF_WET_WATER, 10 SECONDS, min(reac_volume*1.5 SECONDS, 60 SECONDS))
/*
 * Water reaction to a mob
 */

/datum/reagent/hydrogen_peroxide/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)//Splashing people with h2o2 can burn them !
	. = ..()
	if(methods & TOUCH)
		exposed_mob.adjustFireLoss(2)

/datum/reagent/fuel/unholywater //if you somehow managed to extract this from someone, dont splash it on yourself and have a smoke
	name = "Unholy Water"
	description = "Something that shouldn't exist on this plane of existence."
	taste_description = "suffering"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM  //0.5u/second
	penetrates_skin = TOUCH|VAPOR
	ph = 6.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/fuel/unholywater/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(IS_CULTIST(affected_mob))
		affected_mob.adjust_drowsiness(-10 SECONDS * REM * seconds_per_tick)
		affected_mob.AdjustAllImmobility(-40 * REM * seconds_per_tick)
		affected_mob.stamina.adjust(10 * REM * seconds_per_tick, 0)
		affected_mob.adjustToxLoss(-2 * REM * seconds_per_tick, 0)
		affected_mob.adjustOxyLoss(-2 * REM * seconds_per_tick, 0)
		affected_mob.adjustBruteLoss(-2 * REM * seconds_per_tick, 0)
		affected_mob.adjustFireLoss(-2 * REM * seconds_per_tick, 0)
		affected_mob.cause_pain(BODY_ZONES_ALL, -8 * REM * seconds_per_tick) //MONKESTATION ADDITION
		if(ishuman(affected_mob) && affected_mob.blood_volume < BLOOD_VOLUME_NORMAL)
			affected_mob.blood_volume += 3 * REM * seconds_per_tick
	else  // Will deal about 90 damage when 50 units are thrown
		affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3 * REM * seconds_per_tick, 150)
		affected_mob.adjustToxLoss(1 * REM * seconds_per_tick, 0)
		affected_mob.adjustFireLoss(1 * REM * seconds_per_tick, 0)
		affected_mob.adjustOxyLoss(1 * REM * seconds_per_tick, 0)
		affected_mob.adjustBruteLoss(1 * REM * seconds_per_tick, 0)
	..()

/datum/reagent/hellwater //if someone has this in their system they've really pissed off an eldrich god
	name = "Hell Water"
	description = "YOUR FLESH! IT BURNS!"
	taste_description = "burning"
	ph = 0.1
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE
	process_flags = ORGANIC | SYNTHETIC


/datum/reagent/hellwater/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.set_fire_stacks(min(affected_mob.fire_stacks + (1.5 * seconds_per_tick), 5))
	affected_mob.ignite_mob() //Only problem with igniting people is currently the commonly available fire suits make you immune to being on fire
	affected_mob.adjustToxLoss(0.5*seconds_per_tick, 0)
	affected_mob.adjustFireLoss(0.5*seconds_per_tick, 0) //Hence the other damages... ain't I a bastard?
	affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2.5*seconds_per_tick, 150)
	holder.remove_reagent(type, 0.5*seconds_per_tick)

/datum/reagent/medicine/omnizine/godblood
	name = "Godblood"
	description = "Slowly heals all damage types. Has a rather high overdose threshold. Glows with mysterious power."
	overdose_threshold = 150
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

///Used for clownery
/datum/reagent/lube
	name = "Space Lube"
	description = "Lubricant is a substance introduced between two moving surfaces to reduce the friction and wear between them. giggity."
	color = "#009CA8" // rgb: 0, 156, 168
	taste_description = "cherry" // by popular demand
	var/lube_kind = TURF_WET_LUBE ///What kind of slipperiness gets added to turfs
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	turf_exposure = TRUE

/datum/reagent/lube/expose_turf(turf/open/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return
	if(reac_volume >= 1)
		exposed_turf.MakeSlippery(lube_kind, 15 SECONDS, min(reac_volume * 2 SECONDS, 120))

///Stronger kind of lube. Applies TURF_WET_SUPERLUBE.
/datum/reagent/lube/superlube
	name = "Super Duper Lube"
	description = "This \[REDACTED\] has been outlawed after the incident on \[DATA EXPUNGED\]."
	lube_kind = TURF_WET_SUPERLUBE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/spraytan
	name = "Spray Tan"
	description = "A substance applied to the skin to darken the skin."
	color = "#FFC080" // rgb: 255, 196, 128  Bright orange
	metabolization_rate = 10 * REAGENTS_METABOLISM // very fast, so it can be applied rapidly.  But this changes on an overdose
	overdose_threshold = 11 //Slightly more than one un-nozzled spraybottle.
	taste_description = "sour oranges"
	ph = 5
	fallback_icon = 'icons/obj/drinks/drink_effects.dmi'
	fallback_icon_state = "spraytan_fallback"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/spraytan/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE)
	. = ..()
	if(ishuman(exposed_mob))
		if(methods & (PATCH|VAPOR))
			var/mob/living/carbon/human/exposed_human = exposed_mob
			if(exposed_human.dna.species.id == SPECIES_HUMAN)
				switch(exposed_human.skin_tone)
					if("african1")
						exposed_human.skin_tone = "african2"
					if("indian")
						exposed_human.skin_tone = "african1"
					if("arab")
						exposed_human.skin_tone = "indian"
					if("asian2")
						exposed_human.skin_tone = "arab"
					if("asian1")
						exposed_human.skin_tone = "asian2"
					if("mediterranean")
						exposed_human.skin_tone = "african1"
					if("latino")
						exposed_human.skin_tone = "mediterranean"
					if("caucasian3")
						exposed_human.skin_tone = "mediterranean"
					if("caucasian2")
						exposed_human.skin_tone = pick("caucasian3", "latino")
					if("caucasian1")
						exposed_human.skin_tone = "caucasian2"
					if ("albino")
						exposed_human.skin_tone = "caucasian1"

			if(HAS_TRAIT(exposed_human, TRAIT_MUTANT_COLORS)) //take current alien color and darken it slightly
				var/newcolor = ""
				var/datum/color_palette/generic_colors/located = exposed_human.dna.color_palettes[/datum/color_palette/generic_colors]
				var/string = located.return_color(MUTANT_COLOR)
				var/len = length(string)
				var/char = ""
				var/ascii = 0
				for(var/i=1, i <= len, i += length(char))
					char = string[i]
					ascii = text2ascii(char)
					switch(ascii)
						if(48)
							newcolor += "0"
						if(49 to 57)
							newcolor += ascii2text(ascii-1) //numbers 1 to 9
						if(97)
							newcolor += "9"
						if(98 to 102)
							newcolor += ascii2text(ascii-1) //letters b to f lowercase
						if(65)
							newcolor += "9"
						if(66 to 70)
							newcolor += ascii2text(ascii+31) //letters B to F - translates to lowercase
						else
							break
				if(ReadHSV(newcolor)[3] >= ReadHSV("#7F7F7F")[3])
					located.mutant_color = newcolor
			exposed_human.update_body(is_creating = TRUE)

		if((methods & INGEST) && show_message)
			to_chat(exposed_mob, span_notice("That tasted horrible."))


/datum/reagent/spraytan/overdose_process(mob/living/affected_mob, seconds_per_tick, times_fired)
	metabolization_rate = 1 * REAGENTS_METABOLISM

	if(ishuman(affected_mob))
		var/mob/living/carbon/human/affected_human = affected_mob
		var/obj/item/bodypart/head/head = affected_human.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			head.head_flags |= HEAD_HAIR //No hair? No problem!
		if(!HAS_TRAIT(affected_human, TRAIT_SHAVED))
			affected_human.set_facial_hairstyle("Shaved", update = FALSE)
		affected_human.set_facial_haircolor("#000000", update = FALSE)
		if(!HAS_TRAIT(affected_human, TRAIT_BALD))
			affected_human.set_hairstyle("Spiky", update = FALSE)
		affected_human.set_haircolor("#000000", update = FALSE)
		if(HAS_TRAIT(affected_human, TRAIT_USES_SKINTONES))
			affected_human.skin_tone = "orange"
		else if(HAS_TRAIT(affected_human, TRAIT_MUTANT_COLORS)) //Aliens with custom colors simply get turned orange
			var/datum/color_palette/generic_colors/located = affected_human.dna.color_palettes[/datum/color_palette/generic_colors]
			located.mutant_color = "#ff8800"
		affected_human.update_body(is_creating = TRUE)
		if(SPT_PROB(3.5, seconds_per_tick))
			if(affected_human.w_uniform)
				affected_mob.visible_message(pick("<b>[affected_mob]</b>'s collar pops up without warning.</span>", "<b>[affected_mob]</b> flexes [affected_mob.p_their()] arms."))
			else
				affected_mob.visible_message("<b>[affected_mob]</b> flexes [affected_mob.p_their()] arms.")
	if(SPT_PROB(5, seconds_per_tick))
		affected_mob.say(pick("Shit was SO cash.", "You are everything bad in the world.", "Don???t be a stranger. Just hit me with your best shot.", "My name is John and I hate every single one of you."), forced = /datum/reagent/spraytan) //Monkestation edit
	..()
	return

#define MUT_MSG_IMMEDIATE 1
#define MUT_MSG_EXTENDED 2
#define MUT_MSG_ABOUT2TURN 3

/datum/reagent/mutationtoxin
	name = "Stable Mutation Toxin"
	description = "A humanizing toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	metabolization_rate = 0.5 * REAGENTS_METABOLISM //metabolizes to prevent micro-dosage
	taste_description = "slime"
	var/race = /datum/species/human
	process_flags = ORGANIC | SYNTHETIC
	var/list/mutationtexts = list( "You don't feel very well." = MUT_MSG_IMMEDIATE,
									"Your skin feels a bit abnormal." = MUT_MSG_IMMEDIATE,
									"Your limbs begin to take on a different shape." = MUT_MSG_EXTENDED,
									"Your appendages begin morphing." = MUT_MSG_EXTENDED,
									"You feel as though you're about to change at any moment!" = MUT_MSG_ABOUT2TURN)
	var/cycles_to_turn = 20 //the current_cycle threshold / iterations needed before one can transform

/datum/reagent/mutationtoxin/on_mob_life(mob/living/carbon/human/affected_mob, seconds_per_tick, times_fired)
	. = TRUE
	if(!istype(affected_mob))
		return
	if(!(affected_mob.dna?.species) || !(affected_mob.mob_biotypes & MOB_ORGANIC))
		return

	if(SPT_PROB(5, seconds_per_tick))
		var/list/pick_ur_fav = list()
		var/filter = NONE
		if(current_cycle <= (cycles_to_turn*0.3))
			filter = MUT_MSG_IMMEDIATE
		else if(current_cycle <= (cycles_to_turn*0.8))
			filter = MUT_MSG_EXTENDED
		else
			filter = MUT_MSG_ABOUT2TURN

		for(var/i in mutationtexts)
			if(mutationtexts[i] == filter)
				pick_ur_fav += i
		to_chat(affected_mob, span_warning("[pick(pick_ur_fav)]"))

	if(current_cycle >= cycles_to_turn)
		var/datum/species/species_type = race
		affected_mob.set_species(species_type)
		holder.del_reagent(type)
		to_chat(affected_mob, span_warning("You've become \a [lowertext(initial(species_type.name))]!"))
		return
	..()

/datum/reagent/mutationtoxin/classic //The one from plasma on green slimes
	name = "Mutation Toxin"
	description = "A corruptive toxin."
	color = "#13BC5E" // rgb: 19, 188, 94
	race = /datum/species/oozeling/slime
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/mutationtoxin/lizard
	name = "Lizard Mutation Toxin"
	description = "A lizarding toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/lizard
	taste_description = "dragon's breath but not as cool"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/mutationtoxin/fly
	name = "Fly Mutation Toxin"
	description = "An insectifying toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/fly
	taste_description = "trash"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/moth
	name = "Moth Mutation Toxin"
	description = "A glowing toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/moth
	taste_description = "clothing"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/pod
	name = "Podperson Mutation Toxin"
	description = "A vegetalizing toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/pod
	taste_description = "flowers"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/jelly
	name = "Imperfect Mutation Toxin"
	description = "A jellyfying toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/oozeling
	taste_description = "grandma's gelatin"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/mutationtoxin/jelly/on_mob_life(mob/living/carbon/human/affected_mob, seconds_per_tick, times_fired)
	if(isoozeling(affected_mob))
		to_chat(affected_mob, span_warning("Your jelly shifts and morphs, turning you into another subspecies!"))
		var/species_type = pick(subtypesof(/datum/species/oozeling))
		affected_mob.set_species(species_type)
		holder.del_reagent(type)
		return TRUE
	if(current_cycle >= cycles_to_turn) //overwrite since we want subtypes of jelly
		var/datum/species/species_type = pick(subtypesof(race))
		affected_mob.set_species(species_type)
		holder.del_reagent(type)
		to_chat(affected_mob, span_warning("You've become \a [initial(species_type.name)]!"))
		return TRUE
	return ..()

/datum/reagent/mutationtoxin/golem
	name = "Golem Mutation Toxin"
	description = "A crystal toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/golem
	taste_description = "rocks"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/golem/on_mob_metabolize()
	var/static/list/random_golem_types
	random_golem_types = subtypesof(/datum/species/golem) - type
	for(var/i in random_golem_types)
		var/datum/species/golem/golem = i
		if(!initial(golem.random_eligible))
			random_golem_types -= golem
	race = pick(random_golem_types)
	..()

/datum/reagent/mutationtoxin/abductor
	name = "Abductor Mutation Toxin"
	description = "An alien toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/abductor
	taste_description = "something out of this world... no, universe!"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/android
	name = "Android Mutation Toxin"
	description = "A robotic toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/android
	taste_description = "circuitry and steel"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

//BLACKLISTED RACES
/datum/reagent/mutationtoxin/skeleton
	name = "Skeleton Mutation Toxin"
	description = "A scary toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/skeleton
	taste_description = "milk... and lots of it"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/zombie
	name = "Zombie Mutation Toxin"
	description = "An undead toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/zombie //Not the infectious kind. The days of xenobio zombie outbreaks are long past.
	taste_description = "brai...nothing in particular"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/ash
	name = "Ash Mutation Toxin"
	description = "An ashen toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/lizard/ashwalker
	taste_description = "savagery"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

//DANGEROUS RACES
/datum/reagent/mutationtoxin/shadow
	name = "Shadow Mutation Toxin"
	description = "A dark toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/shadow
	taste_description = "the night"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/plasma
	name = "Plasma Mutation Toxin"
	description = "A plasma-based toxin."
	color = "#5EFF3B" //RGB: 94, 255, 59
	race = /datum/species/plasmaman
	taste_description = "plasma"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/mutationtoxin/oni
	name = "Oni Mutation Toxin"
	description = "A demonic toxin."
	color = "#F11514" // RGB: 241, 21, 20
	race = /datum/species/oni
	taste_description = "hellfire"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED | REAGENT_NO_RANDOM_RECIPE

#undef MUT_MSG_IMMEDIATE
#undef MUT_MSG_EXTENDED
#undef MUT_MSG_ABOUT2TURN

/datum/reagent/mulligan
	name = "Mulligan Toxin"
	description = "This toxin will rapidly change the DNA of humanoid beings. Commonly used by Syndicate spies and assassins in need of an emergency ID change."
	color = "#5EFF3B" //RGB: 94, 255, 59
	metabolization_rate = INFINITY
	taste_description = "slime"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/mulligan/on_mob_life(mob/living/carbon/human/affected_mob, seconds_per_tick, times_fired)
	..()
	if (!istype(affected_mob))
		return
	to_chat(affected_mob, span_warning("<b>You grit your teeth in pain as your body rapidly mutates!</b>"))
	affected_mob.visible_message("<b>[affected_mob]</b> suddenly transforms!")
	randomize_human(affected_mob)

/datum/reagent/aslimetoxin
	name = "Advanced Mutation Toxin"
	description = "An advanced corruptive toxin produced by slimes."
	color = "#13BC5E" // rgb: 19, 188, 94
	taste_description = "slime"
	penetrates_skin = NONE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/aslimetoxin/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	if(methods & ~TOUCH)
		exposed_mob.infect_disease_predefined(DISEASE_SLIME, TRUE, "[ROUND_TIME()] Advanced Mutation Toxin Infections [key_name(exposed_mob)]")

/datum/reagent/gluttonytoxin
	name = "Gluttony's Blessing"
	description = "An advanced corruptive toxin produced by something terrible."
	color = "#5EFF3B" //RGB: 94, 255, 59
	taste_description = "decay"
	penetrates_skin = NONE

/datum/reagent/gluttonytoxin/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	if(reac_volume >= 1)//This prevents microdosing from infecting masses of people
		exposed_mob.infect_disease_predefined(DISEASE_MORPH, TRUE, "[ROUND_TIME()] Gluttony Toxin Infections [key_name(exposed_mob)]")

/datum/reagent/serotrotium
	name = "Serotrotium"
	description = "A chemical compound that promotes concentrated production of the serotonin neurotransmitter in humans."
	color = "#202040" // rgb: 20, 20, 40
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	taste_description = "bitterness"
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/serotrotium/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(ishuman(affected_mob))
		if(SPT_PROB(3.5, seconds_per_tick))
			affected_mob.emote(pick("twitch","drool","moan","gasp"))
	..()

/datum/reagent/oxygen
	name = "Oxygen"
	description = "A colorless, odorless gas. Grows on trees but is still pretty valuable."
	reagent_state = GAS
	color = "#808080" // rgb: 128, 128, 128
	taste_mult = 0 // oderless and tasteless
	ph = 9.2//It's acutally a huge range and very dependant on the chemistry but ph is basically a made up var in it's implementation anyways
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/copper
	name = "Copper"
	description = "A highly ductile metal. Things made out of copper aren't very durable, but it makes a decent material for electrical wiring."
	reagent_state = SOLID
	color = "#6E3B08" // rgb: 110, 59, 8
	taste_description = "metal"
	ph = 5.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/copper/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()
	if(!istype(exposed_obj, /obj/item/stack/sheet/iron))
		return

	var/obj/item/stack/sheet/iron/metal = exposed_obj
	reac_volume = min(reac_volume, metal.amount)
	new/obj/item/stack/sheet/bronze(get_turf(metal), reac_volume)
	metal.use(reac_volume)

/datum/reagent/nitrogen
	name = "Nitrogen"
	description = "A colorless, odorless, tasteless gas. A simple asphyxiant that can silently displace vital oxygen."
	reagent_state = GAS
	color = "#808080" // rgb: 128, 128, 128
	taste_mult = 0
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/hydrogen
	name = "Hydrogen"
	description = "A colorless, odorless, nonmetallic, tasteless, highly combustible diatomic gas."
	reagent_state = GAS
	color = "#808080" // rgb: 128, 128, 128
	taste_mult = 0
	ph = 0.1//Now I'm stuck in a trap of my own design. Maybe I should make -ve phes? (not 0 so I don't get div/0 errors)
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/potassium
	name = "Potassium"
	description = "A soft, low-melting solid that can easily be cut with a knife. Reacts violently with water."
	reagent_state = SOLID
	color = "#A0A0A0" // rgb: 160, 160, 160
	taste_description = "sweetness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/mercury
	name = "Mercury"
	description = "A curious metal that's a liquid at room temperature. Neurodegenerative and very bad for the mind."
	color = "#484848" // rgb: 72, 72, 72A
	taste_mult = 0 // apparently tasteless.
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/mercury/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && !isspaceturf(affected_mob.loc))
		step(affected_mob, pick(GLOB.cardinals))
	if(SPT_PROB(3.5, seconds_per_tick))
		affected_mob.emote(pick("twitch","drool","moan"))
	affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.5*seconds_per_tick)
	..()

/datum/reagent/sulfur
	name = "Sulfur"
	description = "A sickly yellow solid mostly known for its nasty smell. It's actually much more helpful than it looks in biochemisty."
	reagent_state = SOLID
	color = "#BF8C00" // rgb: 191, 140, 0
	taste_description = "rotten eggs"
	ph = 4.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/carbon
	name = "Carbon"
	description = "A crumbly black solid that, while unexciting on a physical level, forms the base of all known life. Kind of a big deal."
	reagent_state = SOLID
	color = "#1C1300" // rgb: 30, 20, 0
	taste_description = "sour chalk"
	ph = 5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/carbon/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	if(isspaceturf(exposed_turf))
		return

	var/obj/effect/decal/cleanable/dirt/dirt_decal = (locate() in exposed_turf.contents)
	if(!dirt_decal)
		dirt_decal = new(exposed_turf)

/datum/reagent/chlorine
	name = "Chlorine"
	description = "A pale yellow gas that's well known as an oxidizer. While it forms many harmless molecules in its elemental form it is far from harmless."
	reagent_state = GAS
	color = "#FFFB89" //pale yellow? let's make it light gray
	taste_description = "chlorine"
	ph = 7.4
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED


/datum/reagent/chlorine/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.take_bodypart_damage(0.5*REM*seconds_per_tick, 0)
	. = TRUE
	..()

/datum/reagent/fluorine
	name = "Fluorine"
	description = "A comically-reactive chemical element. The universe does not want this stuff to exist in this form in the slightest."
	reagent_state = GAS
	color = "#808080" // rgb: 128, 128, 128
	taste_description = "acid"
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/fluorine/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjustToxLoss(0.5*REM*seconds_per_tick, 0)
	. = TRUE
	..()

/datum/reagent/sodium
	name = "Sodium"
	description = "A soft silver metal that can easily be cut with a knife. It's not salt just yet, so refrain from putting it on your chips."
	reagent_state = SOLID
	color = "#808080" // rgb: 128, 128, 128
	taste_description = "salty metal"
	ph = 11.6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/phosphorus
	name = "Phosphorus"
	description = "A ruddy red powder that burns readily. Though it comes in many colors, the general theme is always the same."
	reagent_state = SOLID
	color = "#832828" // rgb: 131, 40, 40
	taste_description = "vinegar"
	ph = 6.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/lithium
	name = "Lithium"
	description = "A silver metal, its claim to fame is its remarkably low density. Using it is a bit too effective in calming oneself down."
	reagent_state = SOLID
	color = "#808080" // rgb: 128, 128, 128
	taste_description = "metal"
	ph = 11.3
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/lithium/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(!HAS_TRAIT(affected_mob, TRAIT_IMMOBILIZED) && !isspaceturf(affected_mob.loc) && isturf(affected_mob.loc))
		step(affected_mob, pick(GLOB.cardinals))
	if(SPT_PROB(2.5, seconds_per_tick))
		affected_mob.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/glycerol
	name = "Glycerol"
	description = "Glycerol is a simple polyol compound. Glycerol is sweet-tasting and of low toxicity."
	color = "#D3B913"
	taste_description = "sweetness"
	ph = 9
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/space_cleaner/sterilizine
	name = "Sterilizine"
	description = "Sterilizes wounds in preparation for surgery."
	color = "#D0EFEE" // space cleaner but lighter
	taste_description = "bitterness"
	ph = 10.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_AFFECTS_WOUNDS

/datum/reagent/space_cleaner/sterilizine/expose_mob(mob/living/carbon/exposed_carbon, methods=TOUCH, reac_volume)
	. = ..()
	if(!(methods & (TOUCH|VAPOR|PATCH)))
		return

	for(var/datum/surgery/surgery as anything in exposed_carbon.surgeries)
		surgery.speed_modifier = max(0.2, surgery.speed_modifier)

/datum/reagent/space_cleaner/sterilizine/on_burn_wound_processing(datum/wound/burn/flesh/burn_wound)
	burn_wound.sanitization += 0.9

/datum/reagent/iron
	name = "Iron"
	description = "Pure iron is a metal."
	reagent_state = SOLID
	taste_description = "iron"
	material = /datum/material/iron
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	color = "#606060" //pure iron? let's make it violet of course
	ph = 6
	restricted = TRUE

/datum/reagent/iron/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(affected_mob.blood_volume < BLOOD_VOLUME_NORMAL)
		affected_mob.blood_volume += 0.25 * seconds_per_tick
	..()

/datum/reagent/gold
	name = "Gold"
	description = "Gold is a dense, soft, shiny metal and the most malleable and ductile metal known."
	reagent_state = SOLID
	color = "#F7C430" // rgb: 247, 196, 48
	taste_description = "expensive metal"
	material = /datum/material/gold
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/silver
	name = "Silver"
	description = "A soft, white, lustrous transition metal, it has the highest electrical conductivity of any element and the highest thermal conductivity of any metal."
	reagent_state = SOLID
	color = "#D0D0D0" // rgb: 208, 208, 208
	taste_description = "expensive yet reasonable metal"
	material = /datum/material/silver
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/uranium
	name ="Uranium"
	description = "A jade-green metallic chemical element in the actinide series, weakly radioactive."
	reagent_state = SOLID
	color = "#5E9964" //this used to be silver, but liquid uranium can still be green and it's more easily noticeable as uranium like this so why bother?
	taste_description = "the inside of a reactor"
	/// How much tox damage to deal per tick
	var/tox_damage = 0.5
	process_flags = ORGANIC | SYNTHETIC
	ph = 4
	material = /datum/material/uranium
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	default_container = /obj/effect/decal/cleanable/greenglow

/datum/reagent/uranium/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjustToxLoss(tox_damage * seconds_per_tick * REM)
	..()

/datum/reagent/uranium/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	if((reac_volume < 3) || isspaceturf(exposed_turf))
		return

	var/obj/effect/decal/cleanable/greenglow/glow = locate() in exposed_turf.contents
	if(!glow)
		glow = new(exposed_turf)
	if(!QDELETED(glow))
		glow.reagents.add_reagent(type, reac_volume)

/datum/reagent/uranium/generate_infusion_values(datum/reagents/chems)
	if(chems.has_reagent(src.type, 1))
		var/list/generated_values = list()
		var/amount = chems.get_reagent_amount(src.type)
		generated_values["damage"] = amount * rand(8, 22) * 0.1
		generated_values["maturation_change"] = amount * rand(-10, 10) * 0.1
		generated_values["production_change"] = amount * rand(-10, 10) * 0.1
		generated_values["potency_change"] = amount * rand(-10, 10) * 0.1
		generated_values["yield_change"] = amount * rand(-10, 10) * 0.1
		generated_values["lifespan_change"] = amount * rand(-10, 10) * 0.1
		generated_values["endurance_change"] = amount * rand(-10, 10) * 0.1
		return generated_values

/datum/reagent/uranium/radium
	name = "Radium"
	description = "Radium is an alkaline earth metal. It is extremely radioactive."
	reagent_state = SOLID
	color = "#00CC00" // ditto
	taste_description = "the colour blue and regret"
	tox_damage = 2*REM
	process_flags = ORGANIC | SYNTHETIC
	material = null
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/uranium/radium/generate_infusion_values(datum/reagents/chems)
	if(chems.has_reagent(src.type, 1))
		var/list/generated_values = list()
		var/amount = chems.get_reagent_amount(src.type)
		generated_values["damage"] = amount * rand(8, 22) * 0.1
		generated_values["maturation_change"] = amount * rand(-10, 10) * 0.1
		generated_values["production_change"] = amount * rand(-10, 10) * 0.1
		generated_values["potency_change"] = amount * rand(-10, 10) * 0.1
		generated_values["yield_change"] = amount * rand(-10, 10) * 0.1
		generated_values["lifespan_change"] = amount * rand(-10, 10) * 0.1
		generated_values["endurance_change"] = amount * rand(-10, 10) * 0.1
		return generated_values

/datum/reagent/bluespace
	name = "Bluespace Dust"
	description = "A dust composed of microscopic bluespace crystals, with minor space-warping properties."
	reagent_state = SOLID
	color = "#0000CC"
	taste_description = "fizzling blue"
	process_flags = ORGANIC | SYNTHETIC
	material = /datum/material/bluespace
	ph = 12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/bluespace/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(methods & (TOUCH|VAPOR))
		do_teleport(exposed_mob, get_turf(exposed_mob), (reac_volume / 5), asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE) //4 tiles per crystal

/datum/reagent/bluespace/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(current_cycle > 10 && SPT_PROB(7.5, seconds_per_tick))
		to_chat(affected_mob, span_warning("You feel unstable..."))
		affected_mob.set_jitter_if_lower(2 SECONDS)
		current_cycle = 1
		addtimer(CALLBACK(affected_mob, TYPE_PROC_REF(/mob/living, bluespace_shuffle)), 30)
	..()

/mob/living/proc/bluespace_shuffle()
	do_teleport(src, get_turf(src), 5, asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)

/datum/reagent/aluminium
	name = "Aluminium"
	description = "A silvery white and ductile member of the boron group of chemical elements."
	reagent_state = SOLID
	color = "#A8A8A8" // rgb: 168, 168, 168
	taste_description = "metal"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/silicon
	name = "Silicon"
	description = "A tetravalent metalloid, silicon is less reactive than its chemical analog carbon."
	reagent_state = SOLID
	color = "#A8A8A8" // rgb: 168, 168, 168
	taste_mult = 0
	material = /datum/material/glass
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	restricted = TRUE

/datum/reagent/fuel
	name = "Welding Fuel"
	description = "Required for welders. Flammable."
	color = "#660000" // rgb: 102, 0, 0
	taste_description = "gross metal"
	penetrates_skin = NONE
	ph = 4
	process_flags = ORGANIC | SYNTHETIC
	burning_temperature = 1725 //more refined than oil
	burning_volume = 0.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/alcohol = 4)
	liquid_fire_power = 25

/datum/glass_style/drinking_glass/fuel
	required_drink_type = /datum/reagent/fuel
	name = "glass of welder fuel"
	desc = "Unless you're an industrial tool, this is probably not safe for consumption."
	icon_state = "dr_gibb_glass"

/datum/reagent/fuel/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)//Splashing people with welding fuel to make them easy to ignite!
	. = ..()
	if(methods & (TOUCH|VAPOR))
		exposed_mob.adjust_fire_stacks(reac_volume / 10)

/datum/reagent/fuel/on_mob_life(mob/living/carbon/victim, seconds_per_tick, times_fired)
	victim.adjustToxLoss(0.5 * seconds_per_tick, FALSE, required_biotype = affected_biotype)
	..()
	return TRUE

/datum/reagent/fuel/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()

	if(!istype(exposed_turf) || isspaceturf(exposed_turf))
		return

	if((reac_volume < 5))
		return

	new /obj/effect/decal/cleanable/fuel_pool(exposed_turf, round(reac_volume / 5))

/datum/reagent/space_cleaner
	name = "Space Cleaner"
	description = "A compound used to clean things. Now with 50% more sodium hypochlorite! Can be used to clean wounds, but it's not really meant for that."
	color = "#A5F0EE" // rgb: 165, 240, 238
	taste_description = "sourness"
	reagent_weight = 0.6 //so it sprays further
	penetrates_skin = VAPOR
	var/clean_types = CLEAN_WASH
	ph = 5.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_CLEANS|REAGENT_AFFECTS_WOUNDS
	turf_exposure = TRUE

/datum/reagent/space_cleaner/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()
	exposed_obj?.wash(clean_types)

/datum/reagent/space_cleaner/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	if(reac_volume < 1)
		return

	exposed_turf.wash(clean_types)
	for(var/am in exposed_turf)
		var/atom/movable/movable_content = am
		if(ismopable(movable_content)) // Mopables will be cleaned anyways by the turf wash
			continue
		movable_content.wash(clean_types)

	for(var/mob/living/basic/slime/exposed_slime in exposed_turf)
		exposed_slime.adjustToxLoss(rand(5,10))

/datum/reagent/space_cleaner/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	if(methods & (TOUCH|VAPOR))
		exposed_mob.wash(clean_types)

/datum/reagent/space_cleaner/on_burn_wound_processing(datum/wound/burn/flesh/burn_wound)
	burn_wound.sanitization += 0.3
	if(prob(5))
		to_chat(burn_wound.victim, span_notice("Your [burn_wound] stings and burns from the [src] covering it! It does look pretty clean though."))
		burn_wound.victim.adjustToxLoss(0.5)
		burn_wound.limb.receive_damage(burn = 0.5, wound_bonus = CANT_WOUND)

/datum/reagent/space_cleaner/ez_clean
	name = "EZ Clean"
	description = "A powerful, acidic cleaner sold by Waffle Co. Affects organic matter while leaving other objects unaffected."
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	taste_description = "acid"
	penetrates_skin = VAPOR
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/space_cleaner/ez_clean/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjustBruteLoss(1.665*seconds_per_tick)
	affected_mob.adjustFireLoss(1.665*seconds_per_tick)
	affected_mob.adjustToxLoss(1.665*seconds_per_tick)
	..()

/datum/reagent/space_cleaner/ez_clean/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if((methods & (TOUCH|VAPOR)) && !issilicon(exposed_mob))
		exposed_mob.adjustBruteLoss(1.5)
		exposed_mob.adjustFireLoss(1.5)

/datum/reagent/cryptobiolin
	name = "Cryptobiolin"
	description = "Cryptobiolin causes confusion and dizziness."
	color = "#ADB5DB" //i hate default violets and 'crypto' keeps making me think of cryo so it's light blue now
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	taste_description = "sourness"
	ph = 11.9
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/cryptobiolin/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.set_dizzy_if_lower(2 SECONDS)

	// Cryptobiolin adjusts the mob's confusion down to 20 seconds if it's higher,
	// or up to 1 second if it's lower, but will do nothing if it's in between
	var/confusion_left = affected_mob.get_timed_status_effect_duration(/datum/status_effect/confusion)
	if(confusion_left < 1 SECONDS)
		affected_mob.set_confusion(1 SECONDS)

	else if(confusion_left > 20 SECONDS)
		affected_mob.set_confusion(20 SECONDS)

	..()

/datum/reagent/impedrezene
	name = "Impedrezene"
	description = "Impedrezene is a narcotic that impedes one's ability by slowing down the higher brain cell functions."
	color = "#E07DDD" // pink = happy = dumb
	taste_description = "numbness"
	ph = 9.1
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/opioids = 10)

/datum/reagent/impedrezene/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjust_jitter(-5 SECONDS * seconds_per_tick)
	if(SPT_PROB(55, seconds_per_tick))
		affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	if(SPT_PROB(30, seconds_per_tick))
		affected_mob.adjust_drowsiness(6 SECONDS)
	if(SPT_PROB(5, seconds_per_tick))
		affected_mob.emote("drool")
	..()

/datum/reagent/cyborg_mutation_nanomachines
	name = "Nanomachines"
	description = "Microscopic construction robots. Nanomachines son!"
	color = "#535E66" // rgb: 83, 94, 102
	taste_description = "sludge"
	penetrates_skin = NONE

/datum/reagent/cyborg_mutation_nanomachines/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		exposed_mob.infect_disease_predefined(DISEASE_ROBOT, TRUE, "[ROUND_TIME()] Nanomachine Infections [key_name(exposed_mob)]")

/datum/reagent/xenomicrobes
	name = "Xenomicrobes"
	description = "Microbes with an entirely alien cellular structure."
	color = "#535E66" // rgb: 83, 94, 102
	taste_description = "sludge"
	penetrates_skin = NONE

/datum/reagent/xenomicrobes/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		exposed_mob.infect_disease_predefined(DISEASE_XENO, TRUE, "[ROUND_TIME()] Xenomicrobes Infections [key_name(exposed_mob)]")

/datum/reagent/fungalspores
	name = "Tubercle Bacillus Cosmosis Microbes"
	description = "Active fungal spores."
	color = "#92D17D" // rgb: 146, 209, 125
	taste_description = "slime"
	penetrates_skin = NONE
	ph = 11
	restricted = TRUE //so they cant roll on maint pills, if this has other sides effects then this can be reworked to a global blacklist

/datum/reagent/fungalspores/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		exposed_mob.infect_disease_predefined(DISEASE_FUNGUS, TRUE, "[ROUND_TIME()] Tubercle Bacillus Cosmosis Microbes Infections [key_name(exposed_mob)]")  //Monkestation Edit: TB Patho

/datum/reagent/snail
	name = "Agent-S"
	description = "Virological agent that infects the subject with Gastrolosis."
	color = "#003300" // rgb(0, 51, 0)
	taste_description = "goo"
	penetrates_skin = NONE
	ph = 11

/datum/reagent/snail/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		return
		//exposed_mob.ForceContractDisease(new /datum/disease/gastrolosis(), FALSE, TRUE)  //TODO VIROLOGY SLIME TRANS

/datum/reagent/fluorosurfactant//foam precursor
	name = "Fluorosurfactant"
	description = "A perfluoronated sulfonic acid that forms a foam when mixed with water."
	color = "#9E6B38" // rgb: 158, 107, 56
	taste_description = "metal"
	ph = 11
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/foaming_agent// Metal foaming agent. This is lithium hydride. Add other recipes (e.g. LiH + H2O -> LiOH + H2) eventually.
	name = "Foaming Agent"
	description = "An agent that yields metallic foam when mixed with light metal and a strong acid."
	reagent_state = SOLID
	color = "#664B63" // rgb: 102, 75, 99
	taste_description = "metal"
	ph = 11.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/smart_foaming_agent //Smart foaming agent. Functions similarly to metal foam, but conforms to walls.
	name = "Smart Foaming Agent"
	description = "An agent that yields metallic foam which conforms to area boundaries when mixed with light metal and a strong acid."
	reagent_state = SOLID
	color = "#664B63" // rgb: 102, 75, 99
	taste_description = "metal"
	ph = 11.8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/ammonia
	name = "Ammonia"
	description = "A caustic substance commonly used in fertilizer or household cleaners."
	reagent_state = GAS
	color = "#404030" // rgb: 64, 64, 48
	taste_description = "mordant"
	ph = 11.6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/ammonia/generate_infusion_values(datum/reagents/chems)
	. = ..()
	if(chems.has_reagent(src.type, 1))
		var/list/generated_values = list()
		var/amount = chems.get_reagent_amount(src.type)
		generated_values["damage"] = (amount * rand(13, 27) * 0.1)
		generated_values["maturation_change"] = (amount * rand(5, 10) * 0.1)
		generated_values["production_change"] = (amount * rand(2, 5) * 0.1)
		return generated_values

/datum/reagent/diethylamine
	name = "Diethylamine"
	description = "A secondary amine, mildly corrosive."
	color = "#604030" // rgb: 96, 64, 48
	taste_description = "iron"
	ph = 12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carbondioxide
	name = "Carbon Dioxide"
	reagent_state = GAS
	description = "A gas commonly produced by burning carbon fuels. You're constantly producing this in your lungs."
	color = "#B0B0B0" // rgb : 192, 192, 192
	taste_description = "something unknowable"
	ph = 6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/nitrous_oxide
	name = "Nitrous Oxide"
	description = "A potent oxidizer used as fuel in rockets and as an anaesthetic during surgery. As it is an anticoagulant, nitrous oxide is best \
		used alongside sanguirite to allow blood clotting to continue."
	reagent_state = LIQUID
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	color = "#808080"
	taste_description = "sweetness"
	ph = 5.8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED


/datum/reagent/nitrous_oxide/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(methods & VAPOR)
		// apply 2 seconds of drowsiness per unit applied, with a min duration of 4 seconds
		var/drowsiness_to_apply = max(round(reac_volume, 1) * 2 SECONDS, 4 SECONDS)
		exposed_mob.adjust_drowsiness(drowsiness_to_apply)

/datum/reagent/nitrous_oxide/on_mob_metabolize(mob/living/affected_mob)
	if(!HAS_TRAIT(affected_mob, TRAIT_COAGULATING)) //IF the mob does not have a coagulant in them, we add the blood mess trait to make the bleed quicker
		ADD_TRAIT(affected_mob, TRAIT_BLOODY_MESS, type)
	return ..()

/datum/reagent/nitrous_oxide/on_mob_end_metabolize(mob/living/affected_mob)
	REMOVE_TRAIT(affected_mob, TRAIT_BLOODY_MESS, type)
	return ..()

/datum/reagent/nitrous_oxide/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjust_drowsiness(4 SECONDS * REM * seconds_per_tick)

	if(!HAS_TRAIT(affected_mob, TRAIT_BLOODY_MESS) && !HAS_TRAIT(affected_mob, TRAIT_COAGULATING)) //So long as they do not have a coagulant, if they did not have the bloody mess trait, they do now
		ADD_TRAIT(affected_mob, TRAIT_BLOODY_MESS, type)

	else if(HAS_TRAIT(affected_mob, TRAIT_COAGULATING)) //if we find they now have a coagulant, we remove the trait
		REMOVE_TRAIT(affected_mob, TRAIT_BLOODY_MESS, type)

	if(SPT_PROB(10, seconds_per_tick))
		affected_mob.losebreath += 2
		affected_mob.adjust_confusion_up_to(2 SECONDS, 5 SECONDS)
	..()

/////////////////////////Colorful Powder////////////////////////////
//For colouring in /proc/mix_color_from_reagents

/datum/reagent/colorful_reagent/powder
	name = "Mundane Powder" //the name's a bit similar to the name of colorful reagent, but hey, they're practically the same chem anyway
	var/colorname = "none"
	description = "A powder that is used for coloring things."
	reagent_state = SOLID
	color = "#FFFFFF" // rgb: 207, 54, 0
	taste_description = "the back of class"

/datum/reagent/colorful_reagent/powder/New()
	if(colorname == "none")
		description = "A rather mundane-looking powder. It doesn't look like it'd color much of anything..."
	else if(colorname == "invisible")
		description = "An invisible powder. Unfortunately, since it's invisible, it doesn't look like it'd color much of anything..."
	else
		description = "\An [colorname] powder, used for coloring things [colorname]."
	return ..()

/datum/reagent/colorful_reagent/powder/red
	name = "Red Powder"
	colorname = "red"
	color = "#DA0000" // red
	random_color_list = list("#FC7474")
	ph = 0.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/orange
	name = "Orange Powder"
	colorname = "orange"
	color = "#FF9300" // orange
	random_color_list = list("#FF9300")
	ph = 2

/datum/reagent/colorful_reagent/powder/yellow
	name = "Yellow Powder"
	colorname = "yellow"
	color = "#FFF200" // yellow
	random_color_list = list("#FFF200")
	ph = 5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/green
	name = "Green Powder"
	colorname = "green"
	color = "#A8E61D" // green
	random_color_list = list("#A8E61D")
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/blue
	name = "Blue Powder"
	colorname = "blue"
	color = "#00B7EF" // blue
	random_color_list = list("#71CAE5")
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/purple
	name = "Purple Powder"
	colorname = "purple"
	color = "#DA00FF" // purple
	random_color_list = list("#BD8FC4")
	ph = 13
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/invisible
	name = "Invisible Powder"
	colorname = "invisible"
	color = "#FFFFFF00" // white + no alpha
	random_color_list = list("#FFFFFF") //because using the powder color turns things invisible
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/black
	name = "Black Powder"
	colorname = "black"
	color = "#1C1C1C" // not quite black
	random_color_list = list("#8D8D8D") //more grey than black, not enough to hide your true colors
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/white
	name = "White Powder"
	colorname = "white"
	color = "#FFFFFF" // white
	random_color_list = list("#FFFFFF") //doesn't actually change appearance at all
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/* used by crayons, can't color living things but still used for stuff like food recipes */

/datum/reagent/colorful_reagent/powder/red/crayon
	name = "Red Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/orange/crayon
	name = "Orange Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/yellow/crayon
	name = "Yellow Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/green/crayon
	name = "Green Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/blue/crayon
	name = "Blue Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/purple/crayon
	name = "Purple Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

//datum/reagent/colorful_reagent/powder/invisible/crayon

/datum/reagent/colorful_reagent/powder/black/crayon
	name = "Black Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent/powder/white/crayon
	name = "White Crayon Powder"
	can_colour_mobs = FALSE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

//////////////////////////////////Hydroponics stuff///////////////////////////////

/datum/reagent/plantnutriment
	name = "Generic Nutriment"
	description = "Some kind of nutriment. You can't really tell what it is. You should probably report it, along with how you obtained it."
	color = "#000000" // RBG: 0, 0, 0
	var/tox_prob = 0
	taste_description = "plant food"
	ph = 3

/datum/reagent/plantnutriment/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(SPT_PROB(tox_prob, seconds_per_tick))
		affected_mob.adjustToxLoss(1, FALSE, required_biotype = affected_biotype)
		. = TRUE
	..()

/datum/reagent/plantnutriment/eznutriment
	name = "E-Z Nutrient"
	description = "Contains electrolytes. It's what plants crave. It makes plants slowly gain potency and yield"
	color = "#376400" // RBG: 50, 100, 0
	tox_prob = 5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/plantnutriment/left4zednutriment
	name = "Left 4 Zed"
	description = "Unstable nutriment that makes plants wilt quickly but increases all stats while doing so."
	color = "#1A1E4D" // RBG: 26, 30, 77
	tox_prob = 13
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/plantnutriment/robustharvestnutriment
	name = "Robust Harvest"
	description = "Very potent nutriment that slows plants from mutating whilst also making them grow faster."
	color = "#9D9D00" // RBG: 157, 157, 0
	tox_prob = 8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/plantnutriment/robustharvestnutriment/generate_infusion_values(datum/reagents/chems)

	. = ..()

	if(chems.has_reagent(src.type, 1))

		var/list/generated_values = list()
		var/amount = chems.get_reagent_amount(src.type)
		generated_values["yield_change"] = (amount * (rand(1, 4) * 0.1))
		generated_values["damage"] = (amount * (rand(3, 7) * 0.1))
		generated_values["lifespan_change"] = (amount * (rand(-2, 0) * 0.1))
		return generated_values

/datum/reagent/plantnutriment/endurogrow
	name = "Enduro Grow"
	description = "A specialized nutriment, which decreases product quantity and potency, but strengthens the plants endurance."
	color = "#a06fa7" // RBG: 160, 111, 167
	tox_prob = 8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/plantnutriment/liquidearthquake
	name = "Liquid Earthquake"
	description = "A specialized nutriment, which increases the plant's production speed, as well as it's susceptibility to weeds."
	color = "#912e00" // RBG: 145, 46, 0
	tox_prob = 13
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

// GOON OTHERS



/datum/reagent/fuel/oil
	name = "Oil"
	description = "Burns in a small smoky fire, can be used to get Ash."
	reagent_state = LIQUID
	color = "#2D2D2D"
	taste_description = "oil"
	burning_temperature = 1200//Oil is crude
	burning_volume = 0.05 //but has a lot of hydrocarbons
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = null
	default_container = /obj/effect/decal/cleanable/oil
	liquid_fire_power = 15

/datum/reagent/stable_plasma
	name = "Stable Plasma"
	description = "Non-flammable plasma locked into a liquid form that cannot ignite or become gaseous/solid."
	reagent_state = LIQUID
	color = "#8228a0c6" //monkestation edit
	taste_description = "bitterness"
	taste_mult = 1.5
	ph = 1.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/stable_plasma/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjustPlasma(10 * REM * seconds_per_tick)
	..()

/datum/reagent/iodine
	name = "Iodine"
	description = "Commonly added to table salt as a nutrient. On its own it tastes far less pleasing."
	reagent_state = LIQUID
	color = "#BC8A00"
	taste_description = "metal"
	ph = 4.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet
	name = "Carpet"
	description = "For those that need a more creative way to roll out a red carpet."
	reagent_state = LIQUID
	color = "#771100"
	taste_description = "carpet" // Your tounge feels furry.
	var/carpet_type = /turf/open/floor/carpet
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	turf_exposure = TRUE

/datum/reagent/carpet/expose_turf(turf/exposed_turf, reac_volume)
	if(isopenturf(exposed_turf) && exposed_turf.turf_flags & IS_SOLID && !istype(exposed_turf, /turf/open/floor/carpet))
		exposed_turf.PlaceOnTop(carpet_type, flags = CHANGETURF_INHERIT_AIR)
	..()

/datum/reagent/carpet/black
	name = "Black Carpet"
	description = "The carpet also comes in... BLAPCK" //yes, the typo is intentional
	color = "#1E1E1E"
	taste_description = "licorice"
	carpet_type = /turf/open/floor/carpet/black
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/blue
	name = "Blue Carpet"
	description = "For those that really need to chill out for a while."
	color = "#0000DC"
	taste_description = "frozen carpet"
	carpet_type = /turf/open/floor/carpet/blue
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/cyan
	name = "Cyan Carpet"
	description = "For those that need a throwback to the years of using poison as a construction material. Smells like asbestos."
	color = "#00B4FF"
	taste_description = "asbestos"
	carpet_type = /turf/open/floor/carpet/cyan
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/green
	name = "Green Carpet"
	description = "For those that need the perfect flourish for green eggs and ham."
	color = "#A8E61D"
	taste_description = "Green" //the caps is intentional
	carpet_type = /turf/open/floor/carpet/green
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/orange
	name = "Orange Carpet"
	description = "For those that prefer a healthy carpet to go along with their healthy diet."
	color = "#E78108"
	taste_description = "orange juice"
	carpet_type = /turf/open/floor/carpet/orange
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/purple
	name = "Purple Carpet"
	description = "For those that need to waste copious amounts of healing jelly in order to look fancy."
	color = "#91D865"
	taste_description = "jelly"
	carpet_type = /turf/open/floor/carpet/purple
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/red
	name = "Red Carpet"
	description = "For those that need an even redder carpet."
	color = "#731008"
	taste_description = "blood and gibs"
	carpet_type = /turf/open/floor/carpet/red
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/royal
	name = "Royal Carpet?"
	description = "For those that break the game and need to make an issue report."

/datum/reagent/carpet/royal/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	var/obj/item/organ/internal/liver/liver = affected_mob.get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver)
		// Heads of staff and the captain have a "royal metabolism"
		if(HAS_TRAIT(liver, TRAIT_ROYAL_METABOLISM))
			if(SPT_PROB(5, seconds_per_tick))
				to_chat(affected_mob, "You feel like royalty.")
			if(SPT_PROB(2.5, seconds_per_tick))
				affected_mob.say(pick("Peasants..","This carpet is worth more than your contracts!","I could fire you at any time..."), forced = "royal carpet")

		// The quartermaster, as a semi-head, has a "pretender royal" metabolism
		else if(HAS_TRAIT(liver, TRAIT_PRETENDER_ROYAL_METABOLISM))
			if(SPT_PROB(8, seconds_per_tick))
				to_chat(affected_mob, "You feel like an impostor...")

/datum/reagent/carpet/royal/black
	name = "Royal Black Carpet"
	description = "For those that feel the need to show off their timewasting skills."
	color = "#000000"
	taste_description = "royalty"
	carpet_type = /turf/open/floor/carpet/royalblack
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/royal/blue
	name = "Royal Blue Carpet"
	description = "For those that feel the need to show off their timewasting skills.. in BLUE."
	color = "#5A64C8"
	taste_description = "blueyalty" //also intentional
	carpet_type = /turf/open/floor/carpet/royalblue
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/carpet/neon
	name = "Neon Carpet"
	description = "For those who like the 1980s, vegas, and debugging."
	color = COLOR_ALMOST_BLACK
	taste_description = "neon"
	ph = 6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon

/datum/reagent/carpet/neon/simple_white
	name = "Simple White Neon Carpet"
	description = "For those who like fluorescent lighting."
	color = LIGHT_COLOR_HALOGEN
	taste_description = "sodium vapor"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/white

/datum/reagent/carpet/neon/simple_red
	name = "Simple Red Neon Carpet"
	description = "For those who like a bit of uncertainty."
	color = COLOR_RED
	taste_description = "neon hallucinations"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/red

/datum/reagent/carpet/neon/simple_orange
	name = "Simple Orange Neon Carpet"
	description = "For those who like some sharp edges."
	color = COLOR_ORANGE
	taste_description = "neon spines"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/orange

/datum/reagent/carpet/neon/simple_yellow
	name = "Simple Yellow Neon Carpet"
	description = "For those who need a little stability in their lives."
	color = COLOR_YELLOW
	taste_description = "stabilized neon"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/yellow

/datum/reagent/carpet/neon/simple_lime
	name = "Simple Lime Neon Carpet"
	description = "For those who need a little bitterness."
	color = COLOR_LIME
	taste_description = "neon citrus"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/lime

/datum/reagent/carpet/neon/simple_green
	name = "Simple Green Neon Carpet"
	description = "For those who need a little bit of change in their lives."
	color = COLOR_GREEN
	taste_description = "radium"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/green

/datum/reagent/carpet/neon/simple_teal
	name = "Simple Teal Neon Carpet"
	description = "For those who need a smoke."
	color = COLOR_TEAL
	taste_description = "neon tobacco"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/teal

/datum/reagent/carpet/neon/simple_cyan
	name = "Simple Cyan Neon Carpet"
	description = "For those who need to take a breath."
	color = COLOR_DARK_CYAN
	taste_description = "neon air"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/cyan

/datum/reagent/carpet/neon/simple_blue
	name = "Simple Blue Neon Carpet"
	description = "For those who need to feel joy again."
	color = COLOR_NAVY
	taste_description = "neon blue"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/blue

/datum/reagent/carpet/neon/simple_purple
	name = "Simple Purple Neon Carpet"
	description = "For those that need a little bit of exploration."
	color = COLOR_PURPLE
	taste_description = "neon hell"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/purple

/datum/reagent/carpet/neon/simple_violet
	name = "Simple Violet Neon Carpet"
	description = "For those who want to temp fate."
	color = COLOR_VIOLET
	taste_description = "neon hell"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/violet

/datum/reagent/carpet/neon/simple_pink
	name = "Simple Pink Neon Carpet"
	description = "For those just want to stop thinking so much."
	color = COLOR_PINK
	taste_description = "neon pink"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/pink

/datum/reagent/carpet/neon/simple_black
	name = "Simple Black Neon Carpet"
	description = "For those who need to catch their breath."
	color = COLOR_BLACK
	taste_description = "neon ash"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	carpet_type = /turf/open/floor/carpet/neon/simple/black

/datum/reagent/bromine
	name = "Bromine"
	description = "A brownish liquid that's highly reactive. Useful for stopping free radicals, but not intended for human consumption."
	reagent_state = LIQUID
	color = "#D35415"
	taste_description = "chemicals"
	ph = 7.8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/pentaerythritol
	name = "Pentaerythritol"
	description = "Slow down, it ain't no spelling bee!"
	reagent_state = SOLID
	color = "#E66FFF"
	taste_description = "acid"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/acetaldehyde
	name = "Acetaldehyde"
	description = "Similar to plastic. Tastes like dead people."
	reagent_state = SOLID
	color = "#EEEEEF"
	taste_description = "dead people" //made from formaldehyde, ya get da joke ?
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/acetone_oxide
	name = "Acetone Oxide"
	description = "Enslaved oxygen"
	reagent_state = LIQUID
	color = "#C8A5DC"
	taste_description = "acid"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/acetone_oxide/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)//Splashing people kills people!
	. = ..()
	if(methods & TOUCH)
		exposed_mob.adjustFireLoss(2)
		exposed_mob.adjust_fire_stacks((reac_volume / 10))

/datum/reagent/phenol
	name = "Phenol"
	description = "An aromatic ring of carbon with a hydroxyl group. A useful precursor to some medicines, but has no healing properties on its own."
	reagent_state = LIQUID
	color = "#E7EA91"
	taste_description = "acid"
	ph = 5.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/ash
	name = "Ash"
	description = "Supposedly phoenixes rise from these, but you've never seen it."
	reagent_state = LIQUID
	color = "#515151"
	taste_description = "ash"
	ph = 6.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	default_container = /obj/effect/decal/cleanable/ash

/datum/reagent/acetone
	name = "Acetone"
	description = "A slick, slightly carcinogenic liquid. Has a multitude of mundane uses in everyday life."
	reagent_state = LIQUID
	color = "#AF14B7"
	taste_description = "acid"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/colorful_reagent
	name = "Colorful Reagent"
	description = "Thoroughly sample the rainbow."
	reagent_state = LIQUID
	var/list/random_color_list = list("#00aedb","#a200ff","#f47835","#d41243","#d11141","#00b159","#00aedb","#f37735","#ffc425","#008744","#0057e7","#d62d20","#ffa700")
	color = "#C8A5DC"
	taste_description = "rainbows"
	var/can_colour_mobs = TRUE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	var/datum/callback/color_callback

/datum/reagent/colorful_reagent/New()
	color_callback = CALLBACK(src, PROC_REF(UpdateColor))
	SSticker.OnRoundstart(color_callback)
	return ..()

/datum/reagent/colorful_reagent/Destroy()
	LAZYREMOVE(SSticker.round_end_events, color_callback) //Prevents harddels during roundstart
	color_callback = null //Fly free little callback
	return ..()

/datum/reagent/colorful_reagent/proc/UpdateColor()
	color_callback = null
	color = pick(random_color_list)

/datum/reagent/colorful_reagent/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(can_colour_mobs)
		affected_mob.add_atom_colour(pick(random_color_list), WASHABLE_COLOUR_PRIORITY)
	return ..()

/// Colors anything it touches a random color.
/datum/reagent/colorful_reagent/expose_atom(atom/exposed_atom, reac_volume)
	. = ..()
	if(!isliving(exposed_atom) || can_colour_mobs)
		exposed_atom.add_atom_colour(pick(random_color_list), WASHABLE_COLOUR_PRIORITY)

/datum/reagent/hair_dye
	name = "Quantum Hair Dye"
	description = "Has a high chance of making you look like a mad scientist."
	reagent_state = LIQUID
	var/list/potential_colors = list("#00aadd","#aa00ff","#ff7733","#dd1144","#dd1144","#00bb55","#00aadd","#ff7733","#ffcc22","#008844","#0055ee","#dd2222","#ffaa00") // fucking hair code
	color = "#C8A5DC"
	taste_description = "sourness"
	penetrates_skin = NONE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/hair_dye/New()
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(UpdateColor)))
	return ..()

/datum/reagent/hair_dye/proc/UpdateColor()
	color = pick(potential_colors)

/datum/reagent/hair_dye/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=FALSE)
	. = ..()
	if(!(methods & (TOUCH|VAPOR)) || !ishuman(exposed_mob))
		return

	var/mob/living/carbon/human/exposed_human = exposed_mob
	exposed_human.set_facial_haircolor(pick(potential_colors), update = FALSE)
	exposed_human.set_haircolor(pick(potential_colors), update = TRUE)

/datum/reagent/barbers_aid
	name = "Barber's Aid"
	description = "A solution to hair loss across the world."
	reagent_state = LIQUID
	color = "#A86B45" //hair is brown
	taste_description = "sourness"
	penetrates_skin = NONE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/barbers_aid/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=FALSE)
	. = ..()
	if(!(methods & (TOUCH|VAPOR)) || !ishuman(exposed_mob) || HAS_TRAIT(exposed_mob, TRAIT_BALD) || HAS_TRAIT(exposed_mob, TRAIT_SHAVED))
		return

	var/mob/living/carbon/human/exposed_human = exposed_mob
	var/datum/sprite_accessory/hair/picked_hair = pick(GLOB.roundstart_hairstyles_list)
	var/datum/sprite_accessory/facial_hair/picked_beard = pick(GLOB.facial_hairstyles_list)
	to_chat(exposed_human, span_notice("Hair starts sprouting from your scalp."))
	exposed_human.set_facial_hairstyle(picked_beard, update = FALSE)
	exposed_human.set_hairstyle(picked_hair, update = TRUE)

/datum/reagent/concentrated_barbers_aid
	name = "Concentrated Barber's Aid"
	description = "A concentrated solution to hair loss across the world."
	reagent_state = LIQUID
	color = "#7A4E33" //hair is dark browmn
	taste_description = "sourness"
	penetrates_skin = NONE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/concentrated_barbers_aid/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=FALSE)
	. = ..()
	if(!(methods & (TOUCH|VAPOR)) || !ishuman(exposed_mob) || HAS_TRAIT(exposed_mob, TRAIT_BALD) || HAS_TRAIT(exposed_mob, TRAIT_SHAVED))
		return

	var/mob/living/carbon/human/exposed_human = exposed_mob
	to_chat(exposed_human, span_notice("Your hair starts growing at an incredible speed!"))
	exposed_human.set_facial_hairstyle("Beard (Very Long)", update = FALSE)
	exposed_human.set_hairstyle("Very Long Hair", update = TRUE)

/datum/reagent/concentrated_barbers_aid/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	if(current_cycle > 20 / creation_purity)
		if(!ishuman(affected_mob))
			return
		var/mob/living/carbon/human/human_mob = affected_mob
		if(creation_purity == 1 && human_mob.has_quirk(/datum/quirk/item_quirk/bald))
			human_mob.remove_quirk(/datum/quirk/item_quirk/bald)
		var/obj/item/bodypart/head/head = human_mob.get_bodypart(BODY_ZONE_HEAD)
		if(!head || (head.head_flags & HEAD_HAIR))
			return
		head.head_flags |= HEAD_HAIR
		var/message
		if(HAS_TRAIT(affected_mob, TRAIT_BALD))
			message = span_warning("You feel your scalp mutate, but you are still hopelessly bald.")
		else
			message = span_notice("Your scalp mutates, a full head of hair sprouting from it.")
		to_chat(affected_mob, message)
		human_mob.update_body_parts()

/datum/reagent/baldium
	name = "Baldium"
	description = "A major cause of hair loss across the world."
	reagent_state = LIQUID
	color = "#ecb2cf"
	taste_description = "bitterness"
	penetrates_skin = NONE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/baldium/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=FALSE)
	. = ..()
	if(!(methods & (TOUCH|VAPOR)) || !ishuman(exposed_mob))
		return

	var/mob/living/carbon/human/exposed_human = exposed_mob
	to_chat(exposed_human, span_danger("Your hair is falling out in clumps!"))
	exposed_human.set_facial_hairstyle("Shaved", update = FALSE)
	exposed_human.set_hairstyle("Bald", update = TRUE)

/datum/reagent/saltpetre
	name = "Saltpetre"
	description = "Volatile. Controversial. Third Thing."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	taste_description = "cool salt"
	ph = 11.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/saltpetre/generate_infusion_values(datum/reagents/chems)
	. = ..()
	if(chems.has_reagent(src.type, 1))
		var/list/generated_values = list()
		var/amount = chems.get_reagent_amount(src.type)
		generated_values["potency_change"] = (amount * (rand(2, 8) * 0.2))
		generated_values["damage"] = (amount * (rand(3, 7) * 0.1))
		generated_values["yield_change"] = (amount * (rand(0,2) * 0.2))
		return generated_values

/datum/reagent/lye
	name = "Lye"
	description = "Also known as sodium hydroxide. As a profession making this is somewhat underwhelming."
	reagent_state = LIQUID
	color = "#FFFFD6" // very very light yellow
	taste_description = "acid"
	ph = 11.9
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/drying_agent
	name = "Drying Agent"
	description = "A desiccant. Can be used to dry things."
	reagent_state = LIQUID
	color = "#A70FFF"
	taste_description = "dryness"
	ph = 10.7
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	turf_exposure = TRUE

/datum/reagent/drying_agent/expose_turf(turf/open/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return
	// We want one spray of this stuff (5u) to take out a wet floor. Feels better that way
	exposed_turf.MakeDry(ALL, TRUE, reac_volume * 10 SECONDS)

/datum/reagent/drying_agent/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()
	if(exposed_obj.type != /obj/item/clothing/shoes/galoshes)
		return
	var/t_loc = get_turf(exposed_obj)
	qdel(exposed_obj)
	new /obj/item/clothing/shoes/galoshes/dry(t_loc)

// Virology virus food chems.

/datum/reagent/toxin/mutagen/mutagenvirusfood
	name = "Mutagenic Agar"
	color = "#A3C00F" // rgb: 163,192,15
	taste_description = "sourness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/toxin/mutagen/mutagenvirusfood/sugar
	name = "Sucrose Agar"
	color = "#41B0C0" // rgb: 65,176,192
	taste_description = "sweetness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/synaptizine/synaptizinevirusfood
	name = "Virus Rations"
	color = "#D18AA5" // rgb: 209,138,165
	taste_description = "bitterness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/toxin/plasma/plasmavirusfood
	name = "Virus Plasma"
	color = "#A270A8" // rgb: 166,157,169
	taste_description = "bitterness"
	taste_mult = 1.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/toxin/plasma/plasmavirusfood/weak
	name = "Weakened Virus Plasma"
	color = "#A28CA5" // rgb: 206,195,198
	taste_description = "bitterness"
	taste_mult = 1.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/uranium/uraniumvirusfood
	name = "Decaying Uranium Gel"
	color = "#67ADBA" // rgb: 103,173,186
	taste_description = "the inside of a reactor"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/uranium/uraniumvirusfood/unstable
	name = "Unstable Uranium Gel"
	color = "#2FF2CB" // rgb: 47,242,203
	taste_description = "the inside of a reactor"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/uranium/uraniumvirusfood/stable
	name = "Stable Uranium Gel"
	color = "#04506C" // rgb: 4,80,108
	taste_description = "the inside of a reactor"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

// Bee chemicals

/datum/reagent/royal_bee_jelly
	name = "Royal Bee Jelly"
	description = "Royal Bee Jelly, if injected into a Queen Space Bee said bee will split into two bees."
	color = "#00ff80"
	taste_description = "strange honey"
	ph = 3
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/royal_bee_jelly/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(SPT_PROB(1, seconds_per_tick))
		affected_mob.say(pick("Bzzz...","BZZ BZZ","Bzzzzzzzzzzz..."), forced = "royal bee jelly")
	..()

//Misc reagents

/datum/reagent/romerol
	name = "Romerol"
	// the REAL zombie powder
	description = "Romerol is a highly experimental bioterror agent \
		which causes dormant nodules to be etched into the grey matter of \
		the subject. These nodules only become active upon death of the \
		host, upon which, the secondary structures activate and take control \
		of the host body."
	color = "#123524" // RGB (18, 53, 36)
	metabolization_rate = INFINITY
	taste_description = "brains"
	ph = 0.5

/datum/reagent/romerol/expose_mob(mob/living/carbon/human/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	// Silently add the zombie infection organ to be activated upon death
	if(!exposed_mob.get_organ_slot(ORGAN_SLOT_ZOMBIE))
		var/obj/item/organ/internal/zombie_infection/nodamage/ZI = new()
		ZI.Insert(exposed_mob)

/datum/reagent/magillitis
	name = "Magillitis"
	description = "An experimental serum which causes rapid muscular growth in Hominidae. Side-affects may include hypertrichosis, violent outbursts, and an unending affinity for bananas."
	reagent_state = LIQUID
	color = "#00f041"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/magillitis/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	..()
	if((ishuman(affected_mob)) && current_cycle >= 10)
		affected_mob.gorillize()

/datum/reagent/growthserum
	name = "Growth Serum"
	description = "A commercial chemical designed to help older men in the bedroom."//not really it just makes you a giant
	color = "#ff0000"//strong red. rgb 255, 0, 0
	var/current_size = RESIZE_DEFAULT_SIZE
	taste_description = "bitterness" // apparently what viagra tastes like
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/growthserum/feed_interaction(mob/living/basic/chicken/target, volume, mob/user)
	. = ..()
	target.egg_laying_boosting += min(volume, 25)

/datum/reagent/growthserum/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	var/newsize = current_size
	switch(volume)
		if(0 to 19)
			newsize = 1.25*RESIZE_DEFAULT_SIZE
		if(20 to 49)
			newsize = 1.5*RESIZE_DEFAULT_SIZE
		if(50 to 99)
			newsize = 2*RESIZE_DEFAULT_SIZE
		if(100 to 199)
			newsize = 2.5*RESIZE_DEFAULT_SIZE
		if(200 to INFINITY)
			newsize = 3.5*RESIZE_DEFAULT_SIZE

	affected_mob.update_transform(newsize/current_size)
	current_size = newsize
	..()

/datum/reagent/growthserum/on_mob_end_metabolize(mob/living/affected_mob)
	affected_mob.update_transform(RESIZE_DEFAULT_SIZE/current_size)
	current_size = RESIZE_DEFAULT_SIZE
	..()

/datum/reagent/plastic_polymers
	name = "Plastic Polymers"
	description = "the petroleum based components of plastic."
	color = "#f7eded"
	taste_description = "plastic"
	ph = 6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/glitter
	name = "Generic Glitter"
	description = "if you can see this description, contact a coder."
	color = "#FFFFFF" //pure white
	taste_description = "plastic"
	reagent_state = SOLID
	var/glitter_type = /obj/effect/decal/cleanable/glitter
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/glitter/expose_turf(turf/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf))
		return
	new glitter_type(exposed_turf)

/datum/reagent/glitter/pink
	name = "Pink Glitter"
	description = "pink sparkles that get everywhere"
	color = "#ff8080" //A light pink color
	glitter_type = /obj/effect/decal/cleanable/glitter/pink
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/glitter/white
	name = "White Glitter"
	description = "white sparkles that get everywhere"
	glitter_type = /obj/effect/decal/cleanable/glitter/white
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/glitter/blue
	name = "Blue Glitter"
	description = "blue sparkles that get everywhere"
	color = "#4040FF" //A blueish color
	glitter_type = /obj/effect/decal/cleanable/glitter/blue
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/glitter/confetti
	name = "Confetti"
	description = "Tiny plastic flakes that are impossible to sweep up."
	color = "#7dd87b"
	glitter_type = /obj/effect/decal/cleanable/confetti
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/pax
	name = "Pax"
	description = "A colorless liquid that suppresses violence in its subjects."
	color = "#aaaaaaff"
	taste_description = "water"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	ph = 15
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	metabolized_traits = list(TRAIT_PACIFISM)

/datum/reagent/bz_metabolites
	name = "BZ Metabolites"
	description = "A harmless metabolite of BZ gas."
	color = "#FAFF00"
	taste_description = "acrid cinnamon"
	metabolization_rate = 0.2 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE
	metabolized_traits = list(TRAIT_CHANGELING_HIVEMIND_MUTE)

/datum/reagent/bz_metabolites/on_mob_life(mob/living/carbon/target, seconds_per_tick, times_fired)
	if(target.mind)
		var/datum/antagonist/changeling/changeling = target.mind.has_antag_datum(/datum/antagonist/changeling)
		if(changeling)
			changeling.adjust_chemicals(-2 * REM * seconds_per_tick)
	return ..()

/datum/reagent/pax/peaceborg
	name = "Synthpax"
	description = "A colorless liquid that suppresses violence in its subjects. Cheaper to synthesize than normal Pax, but wears off faster."
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/peaceborg/confuse
	name = "Dizzying Solution"
	description = "Makes the target off balance and dizzy"
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	taste_description = "dizziness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/peaceborg/confuse/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	affected_mob.adjust_confusion_up_to(3 SECONDS * REM * seconds_per_tick, 5 SECONDS)
	affected_mob.adjust_dizzy_up_to(6 SECONDS * REM * seconds_per_tick, 12 SECONDS)

	if(SPT_PROB(10, seconds_per_tick))
		to_chat(affected_mob, "You feel confused and disoriented.")
	..()

/datum/reagent/peaceborg/tire
	name = "Tiring Solution"
	description = "An extremely weak stamina-toxin that tires out the target. Completely harmless."
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	taste_description = "tiredness"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/peaceborg/tire/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	var/healthcomp = (100 - affected_mob.health) //DOES NOT ACCOUNT FOR ADMINBUS THINGS THAT MAKE YOU HAVE MORE THAN 200/210 HEALTH, OR SOMETHING OTHER THAN A HUMAN PROCESSING THIS.
	if(affected_mob.stamina.loss < (45 - healthcomp)) //At 50 health you would have 200 - 150 health meaning 50 compensation. 60 - 50 = 10, so would only do 10-19 stamina.)
		affected_mob.stamina.adjust(-10 * REM * seconds_per_tick)
	if(SPT_PROB(16, seconds_per_tick))
		to_chat(affected_mob, "You should sit down and take a rest...")
	..()

/datum/reagent/gondola_mutation_toxin
	name = "Tranquility"
	description = "A highly mutative liquid of unknown origin."
	color = "#9A6750" //RGB: 154, 103, 80
	taste_description = "inner peace"
	penetrates_skin = NONE
	var/disease_cat = DISEASE_GONDOLA

/datum/reagent/gondola_mutation_toxin/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		exposed_mob.infect_disease_predefined(disease_cat, TRUE, "[ROUND_TIME()] Gondola Reagent Infections [key_name(exposed_mob)]")
		//exposed_mob.ForceContractDisease(new gondola_disease, FALSE, TRUE)  //TODO VIROLOGY SLIME TRANS


/datum/reagent/spider_extract
	name = "Spider Extract"
	description = "A highly specialized extract coming from the Australicus sector, used to create broodmother spiders."
	color = "#ED2939"
	taste_description = "upside down"

/// Improvised reagent that induces vomiting. Created by dipping a dead mouse in welder fluid.
/datum/reagent/yuck
	name = "Organic Slurry"
	description = "A mixture of various colors of fluid. Induces vomiting."
	color = "#545000"
	taste_description = "insides"
	taste_mult = 4
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	var/yuck_cycle = 0 //! The `current_cycle` when puking starts.

/datum/glass_style/drinking_glass/yuck
	required_drink_type = /datum/reagent/yuck
	name = "glass of ...yuck!"
	desc = "It smells like a carcass, and doesn't look much better."

/datum/reagent/yuck/on_mob_add(mob/living/affected_mob)
	. = ..()
	if(HAS_TRAIT(affected_mob, TRAIT_NOHUNGER)) //they can't puke
		holder.del_reagent(type)

#define YUCK_PUKE_CYCLES 3 // every X cycle is a puke
#define YUCK_PUKES_TO_STUN 3 // hit this amount of pukes in a row to start stunning
/datum/reagent/yuck/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(!yuck_cycle)
		if(SPT_PROB(4, seconds_per_tick))
			var/dread = pick("Something is moving in your stomach...", \
				"A wet growl echoes from your stomach...", \
				"For a moment you feel like your surroundings are moving, but it's your stomach...")
			to_chat(affected_mob, span_userdanger("[dread]"))
			yuck_cycle = current_cycle
	else
		var/yuck_cycles = current_cycle - yuck_cycle
		if(yuck_cycles % YUCK_PUKE_CYCLES == 0)
			if(yuck_cycles >= YUCK_PUKE_CYCLES * YUCK_PUKES_TO_STUN)
				holder.remove_reagent(type, 5)
			affected_mob.vomit(rand(14, 26), stun = yuck_cycles >= YUCK_PUKE_CYCLES * YUCK_PUKES_TO_STUN)
	if(holder)
		return ..()
#undef YUCK_PUKE_CYCLES
#undef YUCK_PUKES_TO_STUN

/datum/reagent/yuck/on_mob_end_metabolize(mob/living/affected_mob)
	yuck_cycle = 0 // reset vomiting
	return ..()

/datum/reagent/yuck/on_transfer(atom/A, methods=TOUCH, trans_volume)
	if((methods & INGEST) || !iscarbon(A))
		return ..()

	A.reagents.remove_reagent(type, trans_volume)
	A.reagents.add_reagent(/datum/reagent/fuel, trans_volume * 0.75)
	A.reagents.add_reagent(/datum/reagent/water, trans_volume * 0.25)

	return ..()

//monkey powder heehoo
/datum/reagent/monkey_powder
	name = "Monkey Powder"
	description = "Just add water!"
	color = "#9C5A19"
	taste_description = "bananas"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/plasma_oxide
	name = "Hyper-Plasmium Oxide"
	description = "Compound created deep in the cores of demon-class planets. Commonly found through deep geysers."
	color = "#470750" // rgb: 255, 255, 255
	taste_description = "hell"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/exotic_stabilizer
	name = "Exotic Stabilizer"
	description = "Advanced compound created by mixing stabilizing agent and hyper-plasmium oxide."
	color = "#180000" // rgb: 255, 255, 255
	taste_description = "blood"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/wittel
	name = "Wittel"
	description = "An extremely rare metallic-white substance only found on demon-class planets."
	color = "#FFFFFF" // rgb: 255, 255, 255
	taste_mult = 0 // oderless and tasteless
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/metalgen
	name = "Metalgen"
	data = list("material"=null)
	description = "A purple metal morphic liquid, said to impose it's metallic properties on whatever it touches."
	color = "#b000aa"
	taste_mult = 0 // oderless and tasteless
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE
	/// The material flags used to apply the transmuted materials
	var/applied_material_flags = MATERIAL_EFFECTS | MATERIAL_ADD_PREFIX | MATERIAL_COLOR
	/// The amount of materials to apply to the transmuted objects if they don't contain materials
	var/default_material_amount = 100
	turf_exposure = TRUE

/datum/reagent/metalgen/expose_obj(obj/exposed_obj, volume)
	. = ..()
	metal_morph(exposed_obj)

/datum/reagent/metalgen/expose_turf(turf/exposed_turf, volume)
	. = ..()
	metal_morph(exposed_turf)

///turn an object into a special material
/datum/reagent/metalgen/proc/metal_morph(atom/A)
	var/metal_ref = data["material"]
	if(!metal_ref)
		return

	var/metal_amount = 0
	var/list/materials_to_transmute = A.get_material_composition(BREAKDOWN_INCLUDE_ALCHEMY)
	for(var/metal_key in materials_to_transmute) //list with what they're made of
		metal_amount += materials_to_transmute[metal_key]

	if(!metal_amount)
		metal_amount = default_material_amount //some stuff doesn't have materials at all. To still give them properties, we give them a material. Basically doesn't exist

	var/list/metal_dat = list((metal_ref) = metal_amount)
	A.material_flags = applied_material_flags
	A.set_custom_materials(metal_dat)
	ADD_TRAIT(A, TRAIT_MAT_TRANSMUTED, type)

/datum/reagent/gravitum
	name = "Gravitum"
	description = "A rare kind of null fluid, capable of temporalily removing all weight of whatever it touches." //i dont even
	color = "#050096" // rgb: 5, 0, 150
	taste_mult = 0 // oderless and tasteless
	metabolization_rate = 0.1 * REAGENTS_METABOLISM //20 times as long, so it's actually viable to use
	var/time_multiplier = 1 MINUTES //1 minute per unit of gravitum on objects. Seems overpowered, but the whole thing is very niche
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	self_consuming = TRUE //this works on objects, so it should work on skeletons and robots too

/datum/reagent/gravitum/expose_obj(obj/exposed_obj, volume)
	. = ..()
	exposed_obj.AddElement(/datum/element/forced_gravity, 0)
	addtimer(CALLBACK(exposed_obj, PROC_REF(_RemoveElement), list(/datum/element/forced_gravity, 0, can_override = TRUE)), volume * time_multiplier)

/datum/reagent/gravitum/on_mob_metabolize(mob/living/affected_mob)
	affected_mob.AddElement(/datum/element/forced_gravity, 0, can_override = TRUE) //0 is the gravity, and in this case weightless
	return ..()

/datum/reagent/gravitum/on_mob_end_metabolize(mob/living/affected_mob)
	. = ..()
	affected_mob.RemoveElement(/datum/element/forced_gravity, 0, can_override = TRUE)

/datum/reagent/cellulose
	name = "Cellulose Fibers"
	description = "A crystaline polydextrose polymer, plants swear by this stuff."
	reagent_state = SOLID
	color = "#E6E6DA"
	taste_mult = 0
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

// "Second wind" reagent generated when someone suffers a wound. Epinephrine, adrenaline, and stimulants are all already taken so here we are
/datum/reagent/determination
	name = "Determination"
	description = "For when you need to push on a little more. Do NOT allow near plants."
	reagent_state = LIQUID
	color = "#D2FFFA"
	metabolization_rate = 0.75 * REAGENTS_METABOLISM // 5u (WOUND_DETERMINATION_CRITICAL) will last for ~34 seconds
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	self_consuming = TRUE
	metabolized_traits = list(TRAIT_ANALGESIA)
	/// Whether we've had at least WOUND_DETERMINATION_SEVERE (2.5u) of determination at any given time. No damage slowdown immunity or indication we're having a second wind if it's just a single moderate wound
	var/significant = FALSE

/datum/reagent/determination/on_mob_end_metabolize(mob/living/carbon/affected_mob)
	if(significant)
		var/stam_crash = 0
		for(var/thing in affected_mob.all_wounds)
			var/datum/wound/W = thing
			stam_crash += (W.severity + 1) * 3 // spike of 3 stam damage per wound severity (moderate = 6, severe = 9, critical = 12) when the determination wears off if it was a combat rush
		affected_mob.stamina.adjust(-stam_crash)
	affected_mob.remove_status_effect(/datum/status_effect/determined)
	..()

/datum/reagent/determination/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(!significant && volume >= WOUND_DETERMINATION_SEVERE)
		significant = TRUE
		affected_mob.apply_status_effect(/datum/status_effect/determined) // in addition to the slight healing, limping cooldowns are divided by 4 during the combat high

	volume = min(volume, WOUND_DETERMINATION_MAX)

	for(var/thing in affected_mob.all_wounds)
		var/datum/wound/W = thing
		var/obj/item/bodypart/wounded_part = W.limb
		if(wounded_part)
			wounded_part.heal_damage(0.25 * REM * seconds_per_tick, 0.25 * REM * seconds_per_tick)
		affected_mob.stamina.adjust(0.25 * REM * seconds_per_tick) // the more wounds, the more stamina regen
	..()

// unholy water, but for heretics.
// why couldn't they have both just used the same reagent?
// who knows.
// maybe nar'sie is considered to be too "mainstream" of a god to worship in the heretic community.
/datum/reagent/eldritch
	name = "Eldritch Essence"
	description = "A strange liquid that defies the laws of physics. \
		It re-energizes and heals those who can see beyond this fragile reality, \
		but is incredibly harmful to the closed-minded. It metabolizes very quickly."
	taste_description = "Ag'hsj'saje'sh"
	color = "#1f8016"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM  //0.5u/second
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED|REAGENT_NO_RANDOM_RECIPE

/datum/reagent/eldritch/on_mob_life(mob/living/carbon/drinker, seconds_per_tick, times_fired)
	if(IS_HERETIC(drinker))
		drinker.adjust_drowsiness(-10 * REM * seconds_per_tick)
		drinker.AdjustAllImmobility(-40 * REM * seconds_per_tick)
		drinker.stamina.adjust(10 * REM * seconds_per_tick, TRUE)
		drinker.adjustToxLoss(-2 * REM * seconds_per_tick, FALSE, forced = TRUE)
		drinker.adjustOxyLoss(-2 * REM * seconds_per_tick, FALSE)
		drinker.adjustBruteLoss(-2 * REM * seconds_per_tick, FALSE)
		drinker.adjustFireLoss(-2 * REM * seconds_per_tick, FALSE)
		drinker.cause_pain(BODY_ZONES_ALL, -5 * REM * seconds_per_tick) // MONKESTATION ADDITION
		drinker.fully_heal(HEAL_NEGATIVE_DISEASES)
		if(drinker.blood_volume < BLOOD_VOLUME_NORMAL)
			drinker.blood_volume += 3 * REM * seconds_per_tick
	else
		drinker.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3 * REM * seconds_per_tick, 150)
		drinker.adjustToxLoss(2 * REM * seconds_per_tick, FALSE)
		drinker.adjustFireLoss(2 * REM * seconds_per_tick, FALSE)
		drinker.adjustOxyLoss(2 * REM * seconds_per_tick, FALSE)
		drinker.adjustBruteLoss(2 * REM * seconds_per_tick, FALSE)
		drinker.fully_heal(HEAL_POSTIVE_DISEASES)
	..()
	return TRUE

/datum/reagent/universal_indicator
	name = "Universal Indicator"
	description = "A solution that can be used to create pH paper booklets, or sprayed on things to colour them by their pH."
	taste_description = "a strong chemical taste"
	color = "#1f8016"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

//Colours things by their pH
/datum/reagent/universal_indicator/expose_atom(atom/exposed_atom, reac_volume)
	. = ..()
	if(exposed_atom.reagents)
		var/color
		CONVERT_PH_TO_COLOR(exposed_atom.reagents.ph, color)
		exposed_atom.add_atom_colour(color, WASHABLE_COLOUR_PRIORITY)

// [Original ants concept by Keelin on Goon]
/datum/reagent/ants
	name = "Ants"
	description = "A genetic crossbreed between ants and termites, their bites land at a 3 on the Schmidt Pain Scale."
	reagent_state = SOLID
	color = "#993333"
	taste_mult = 1.3
	taste_description = "tiny legs scuttling down the back of your throat"
	metabolization_rate = 5 * REAGENTS_METABOLISM //1u per second
	ph = 4.6 // Ants contain Formic Acid
	evaporation_rate = 10
	/// How much damage the ants are going to be doing (rises with each tick the ants are in someone's body)
	var/ant_damage = 0
	/// Tells the debuff how many ants we are being covered with.
	var/amount_left = 0
	/// List of possible common statements to scream when eating ants
	var/static/list/ant_screams = list(
		"THEY'RE UNDER MY SKIN!!",
		"GET THEM OUT OF ME!!",
		"HOLY HELL THEY BURN!!",
		"MY GOD THEY'RE INSIDE ME!!",
		"GET THEM OUT!!",
	)

/datum/glass_style/drinking_glass/ants
	required_drink_type = /datum/reagent/ants
	name = "glass of ants"
	desc = "Bottoms up...?"

/datum/reagent/ants/on_mob_life(mob/living/carbon/victim, seconds_per_tick)
	victim.adjustBruteLoss(max(0.1, round((ant_damage * 0.025),0.1))) //Scales with time. Roughly 32 brute with 100u.
	ant_damage++
	if(ant_damage < 5) // Makes ant food a little more appetizing, since you won't be screaming as much.
		return ..()
	if(SPT_PROB(5, seconds_per_tick))
		if(SPT_PROB(5, seconds_per_tick)) //Super rare statement
			victim.say("AUGH NO NOT THE ANTS! NOT THE ANTS! AAAAUUGH THEY'RE IN MY EYES! MY EYES! AUUGH!!", forced = /datum/reagent/ants)
		else
			victim.say(pick(ant_screams), forced = /datum/reagent/ants)
	if(SPT_PROB(15, seconds_per_tick))
		victim.emote("scream")
	if(SPT_PROB(2, seconds_per_tick)) // Stuns, but purges ants.
		victim.vomit(rand(5,10), FALSE, TRUE, 1, TRUE, FALSE, purge_ratio = 1)
	return ..()

/datum/reagent/ants/on_mob_end_metabolize(mob/living/living_anthill)
	ant_damage = 0
	to_chat(living_anthill, "<span class='notice'>You feel like the last of the ants are out of your system.</span>")
	return ..()

/datum/reagent/ants/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(!iscarbon(exposed_mob) || (methods & (INGEST|INJECT)))
		return
	if(methods & (PATCH|TOUCH|VAPOR))
		amount_left = round(reac_volume,0.1)
		exposed_mob.apply_status_effect(/datum/status_effect/ants, amount_left)

/datum/reagent/ants/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()

	//Stream cancelled due to ants in your fire alarm.
	if(istype(exposed_obj,/obj/machinery/firealarm))
		var/obj/machinery/firealarm/alarm = exposed_obj
		if(alarm.ants_remaining)
			alarm.ants_remaining += round(reac_volume)
		else
			alarm.ants_remaining += round(reac_volume)
			alarm.ant_trigger()

	var/turf/open/my_turf = exposed_obj.loc // No dumping ants on an object in a storage slot
	if(!istype(my_turf)) //Are we actually in an open turf?
		return
	var/static/list/accepted_types = typecacheof(list(/obj/machinery/atmospherics, /obj/structure/cable, /obj/structure/disposalpipe))
	if(!accepted_types[exposed_obj.type]) // Bypasses pipes, vents, and cables to let people create ant mounds on top easily.
		return
	expose_turf(my_turf, reac_volume)

/datum/reagent/ants/evaporate(turf/exposed_turf, reac_volume)
	. = ..()
	if(!istype(exposed_turf) || isspaceturf(exposed_turf)) // Is the turf valid
		return

	var/obj/effect/decal/cleanable/ants/pests = locate() in range(5, exposed_turf)
	if(!pests)
		pests = new(exposed_turf)
	var/spilled_ants = (round(reac_volume,1) - 5) // To account for ant decals giving 3-5 ants on initialize.
	pests.reagents.add_reagent(/datum/reagent/ants, spilled_ants)
	pests.update_ant_damage()

//This is intended to a be a scarce reagent to gate certain drugs and toxins with. Do not put in a synthesizer. Renewable sources of this reagent should be inefficient.
/datum/reagent/lead
	name = "Lead"
	description = "A dull metalltic element with a low melting point."
	taste_description = "metal"
	reagent_state = SOLID
	color = "#80919d"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM

/datum/reagent/lead/on_mob_life(mob/living/carbon/victim)
	. = ..()
	victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.5)

//The main feedstock for kronkaine production, also a shitty stamina healer.
/datum/reagent/kronkus_extract
	name = "Kronkus Extract"
	description = "A frothy extract made from fermented kronkus vine pulp.\nHighly bitter due to the presence of a variety of kronkamines."
	taste_description = "bitterness"
	color = "#228f63"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 5)

/datum/reagent/kronkus_extract/on_mob_life(mob/living/carbon/kronkus_enjoyer)
	. = ..()
	kronkus_enjoyer.adjustOrganLoss(ORGAN_SLOT_HEART, 0.1)
	kronkus_enjoyer.stamina.adjust(2, FALSE)

/datum/reagent/brimdust
	name = "Brimdust"
	description = "A brimdemon's dust. Consumption is not recommended, although plants like it."
	reagent_state = SOLID
	color = "#522546"
	taste_description = "burning"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/brimdust/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	affected_mob.adjustFireLoss((ispodperson(affected_mob) ? -1 : 1) * seconds_per_tick)

// I made this food....with love.
// Reagent added to food by chef's with a chef's kiss. Makes people happy.
/datum/reagent/love
	name = "Love"
	description = "This food's been made... with love."
	color = "#ff7edd"
	taste_description = "love"
	taste_mult = 10
	overdose_threshold = 50 // too much love is a bad thing

/datum/reagent/love/expose_mob(mob/living/exposed_mob, methods, reac_volume, show_message, touch_protection)
	. = ..()
	// A syringe is not grandma's cooking
	if(methods & ~INGEST)
		exposed_mob.reagents.del_reagent(type)

/datum/reagent/love/on_mob_metabolize(mob/living/metabolizer)
	. = ..()
	metabolizer.add_mood_event(name, /datum/mood_event/love_reagent)

/datum/reagent/love/on_mob_delete(mob/living/deleted_from)
	. = ..()
	// When we exit the system we'll leave the moodlet based on the amount we had
	var/duration_of_moodlet = current_cycle * 20 SECONDS
	deleted_from.clear_mood_event(name)
	deleted_from.add_mood_event(name, /datum/mood_event/love_reagent, duration_of_moodlet)

/datum/reagent/love/overdose_process(mob/living/metabolizer, seconds_per_tick, times_fired)
	var/mob/living/carbon/carbon_metabolizer = metabolizer
	if(!istype(carbon_metabolizer) || !carbon_metabolizer.can_heartattack() || carbon_metabolizer.undergoing_cardiac_arrest())
		metabolizer.reagents.del_reagent(type)
		return

	if(SPT_PROB(10, seconds_per_tick))
		carbon_metabolizer.set_heartattack(TRUE)

/datum/reagent/hauntium
	name = "Hauntium"
	color = "#3B3B3BA3"
	description = "An eerie liquid created by purifying the prescence of ghosts. If it happens to get in your body, it starts hurting your soul." //soul as in mood and heart
	taste_description = "evil spirits"
	metabolization_rate = 0.75 * REAGENTS_METABOLISM
	material = /datum/material/hauntium
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/hauntium/expose_obj(obj/exposed_obj, reac_volume) //gives 20 seconds of haunting effect for every unit of it that touches an object
	. = ..()
	if(!isitem(exposed_obj))
		return
	if(HAS_TRAIT_FROM(exposed_obj, TRAIT_HAUNTED, HAUNTIUM_REAGENT_TRAIT))
		return
	exposed_obj.make_haunted(HAUNTIUM_REAGENT_TRAIT, "#f8f8ff")
	addtimer(CALLBACK(exposed_obj, TYPE_PROC_REF(/atom/movable/, remove_haunted), HAUNTIUM_REAGENT_TRAIT), reac_volume * 20 SECONDS)

/datum/reagent/hauntium/on_mob_metabolize(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	to_chat(affected_mob, span_userdanger("You feel an evil presence inside you!"))
	if(affected_mob.mob_biotypes & MOB_UNDEAD) //monkestation temp removal: || HAS_MIND_TRAIT(affected_mob, TRAIT_MORBID))
		affected_mob.add_mood_event("morbid_hauntium", /datum/mood_event/morbid_hauntium, name) //8 minutes of slight mood buff if undead or morbid
	else
		affected_mob.add_mood_event("hauntium_spirits", /datum/mood_event/hauntium_spirits, name) //8 minutes of mood debuff

/datum/reagent/hauntium/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	if(affected_mob.mob_biotypes & MOB_UNDEAD) //if morbid or undead, acts like an addiction-less drug //monkestation temp removal: || HAS_MIND_TRAIT(affected_mob, TRAIT_MORBID))
		affected_mob.remove_status_effect(/datum/status_effect/jitter)
		affected_mob.AdjustStun(-50 * REM * seconds_per_tick)
		affected_mob.AdjustKnockdown(-50 * REM * seconds_per_tick)
		affected_mob.AdjustUnconscious(-50 * REM * seconds_per_tick)
		affected_mob.AdjustParalyzed(-50 * REM * seconds_per_tick)
		affected_mob.AdjustImmobilized(-50 * REM * seconds_per_tick)
		..()
	else
		affected_mob.adjustOrganLoss(ORGAN_SLOT_HEART, REM * seconds_per_tick) //1 heart damage per tick
		if(SPT_PROB(10, seconds_per_tick))
			affected_mob.emote(pick("twitch","choke","shiver","gag"))
		..()
