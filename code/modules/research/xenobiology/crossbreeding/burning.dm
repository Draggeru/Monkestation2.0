/*
Burning extracts:
	Have a unique, primarily offensive effect when
	filled with 10u plasma and activated in-hand.
*/
/obj/item/slimecross/burning
	name = "burning extract"
	desc = "It's boiling over with barely-contained energy."
	effect = "burning"
	icon_state = "burning"

/obj/item/slimecross/burning/Initialize(mapload)
	. = ..()
	create_reagents(10, INJECTABLE | DRAWABLE)

/obj/item/slimecross/burning/attack_self(mob/user)
	if(!reagents.has_reagent(/datum/reagent/toxin/plasma,10))
		to_chat(user, span_warning("This extract needs to be full of plasma to activate!"))
		return
	reagents.remove_reagent(/datum/reagent/toxin/plasma,10)
	to_chat(user, span_notice("You squeeze the extract, and it absorbs the plasma!"))
	playsound(src, 'sound/effects/bubbles.ogg', 50, TRUE)
	playsound(src, 'sound/magic/fireball.ogg', 50, TRUE)
	do_effect(user)

/obj/item/slimecross/burning/proc/do_effect(mob/user) //If, for whatever reason, you don't want to delete the extract, don't do ..()
	qdel(src)
	return

/obj/item/slimecross/burning/grey
	colour = "grey"
	effect_desc = "Creates a hungry and speedy slime that will love you forever."

/obj/item/slimecross/burning/grey/do_effect(mob/user)
	var/mob/living/basic/slime/S = new(get_turf(user))
	S.visible_message(span_danger("A baby slime emerges from [src], and it nuzzles [user] before burbling hungrily!"))
	SEND_SIGNAL(S, COMSIG_FRIENDSHIP_CHANGE, user, 110)
	S.bodytemperature = T0C + 400 //We gonna step on the gas.
	..()

/obj/item/slimecross/burning/orange
	colour = "orange"
	effect_desc = "Expels pepperspray in a radius when activated."

/obj/item/slimecross/burning/orange/do_effect(mob/user)
	user.visible_message(span_danger("[src] boils over with a caustic gas!"))
	var/datum/reagents/tmp_holder = new/datum/reagents(100)
	tmp_holder.add_reagent(/datum/reagent/consumable/condensedcapsaicin, 100)

	var/datum/effect_system/fluid_spread/smoke/chem/smoke = new
	smoke.set_up(7, holder = src, location = get_turf(user), carry = tmp_holder)
	smoke.start(log = TRUE)
	..()

/obj/item/slimecross/burning/purple
	colour = "purple"
	effect_desc = "Creates a clump of invigorating gel, it has healing properties and makes you feel good."

/obj/item/slimecross/burning/purple/do_effect(mob/user)
	user.visible_message(span_notice("[src] fills with a bubbling liquid!"))
	new /obj/item/slimecrossbeaker/autoinjector/slimestimulant(get_turf(user))
	..()

/obj/item/slimecross/burning/blue
	colour = "blue"
	effect_desc = "Freezes the floor around you and chills nearby people."

/obj/item/slimecross/burning/blue/do_effect(mob/user)
	user.visible_message(span_danger("[src] flash-freezes the area!"))
	for(var/turf/open/T in range(3, get_turf(user)))
		T.MakeSlippery(TURF_WET_PERMAFROST, min_wet_time = 10, wet_time_to_add = 5)
	for(var/mob/living/carbon/M in range(5, get_turf(user)))
		if(M == user)
			continue
		M.adjust_bodytemperature(-INFINITY, min_temp = M.bodytemp_cold_damage_limit + 5 KELVIN)
		to_chat(M, span_danger("You feel a chill run down your spine, and the floor feels a bit slippery with frost..."))
	..()

/obj/item/slimecross/burning/metal
	colour = "metal"
	effect_desc = "Instantly ignites adjacent walls as if thermite were applied to them."

/obj/item/slimecross/burning/metal/do_effect(mob/user)
	var/turf/our_turf = get_turf(src)
	if(GLOB.clock_ark && on_reebe(our_turf) && get_dist(our_turf, GLOB.clock_ark) <= ARK_TURF_DESTRUCTION_BLOCK_RANGE)
		balloon_alert(user, "a near by energy source is stopping \the [src] from activating!")
		return FALSE
	for(var/turf/closed/wall/wall in RANGE_TURFS(1, our_turf))
		var/datum/component/thermite/thermite = wall.AddComponent(/datum/component/thermite)
		thermite.thermite_melt(user)
		playsound(wall, 'sound/effects/break_stone.ogg', vol = 50, vary = TRUE)
	user.visible_message(span_danger("[src] pulses violently, beginning to melt the walls around it!"))
	..()

/obj/item/slimecross/burning/yellow
	colour = "yellow"
	effect_desc = "Shocks nearby people with a burst of energy, heavily disorienting them for a short while."

/obj/item/slimecross/burning/yellow/do_effect(mob/user)
	user.visible_message(span_danger("[src] explodes into an energy field, shocking others nearby!"))
	playsound(get_turf(src), 'sound/weapons/zapbang.ogg', 50, TRUE)
	// nothing here should deal actual damage - it's just painful and disorienting
	for(var/mob/living/victim in range(4, get_turf(user)) - user)
		victim.cause_pain(BODY_ZONES_ALL, 10, BURN)
		victim.set_confusion_if_lower(10 SECONDS)
		victim.set_eye_blur_if_lower(10 SECONDS)
		ADD_TRAIT(victim, TRAIT_POOR_AIM, type)
		addtimer(TRAIT_CALLBACK_REMOVE(victim, TRAIT_POOR_AIM, type), 15 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		to_chat(victim, span_userdanger("You feel a sharp, painful pulse of energy throughout your body!"))
		user.Beam(victim, icon_state = "sm_arc", time = 0.5 SECONDS)
		log_combat(user, victim, "disoriented (burning yellow extract)")
	..()

/obj/item/slimecross/burning/darkpurple
	colour = "dark purple"
	effect_desc = "Creates a cloud of plasma."

/obj/item/slimecross/burning/darkpurple/do_effect(mob/user)
	user.visible_message(span_danger("[src] sublimates into a cloud of plasma!"))
	var/turf/T = get_turf(user)
	T.atmos_spawn_air("plasma=60")
	..()

/obj/item/slimecross/burning/darkblue
	colour = "dark blue"
	effect_desc = "Expels a burst of chilling smoke while also filling you with regenerative jelly."

/obj/item/slimecross/burning/darkblue/do_effect(mob/user)
	user.visible_message(span_danger("[src] releases a burst of chilling smoke!"))
	var/datum/reagents/tmp_holder = new/datum/reagents(100)
	tmp_holder.add_reagent(/datum/reagent/consumable/frostoil, 40)
	user.reagents.add_reagent(/datum/reagent/medicine/regen_jelly, 10)
	var/datum/effect_system/fluid_spread/smoke/chem/smoke = new
	smoke.set_up(7, holder = src, location = get_turf(user), carry = tmp_holder)
	smoke.start(log = TRUE)
	..()

/obj/item/slimecross/burning/silver
	colour = "silver"
	effect_desc = "Creates a few pieces of slime jelly laced food."

/obj/item/slimecross/burning/silver/do_effect(mob/user)
	var/amount = rand(3,6)
	var/list/turfs = list()
	for(var/turf/open/T in range(1,get_turf(user)))
		turfs += T
	for(var/i in 1 to amount)
		var/path = get_random_food()
		var/obj/item/food/food = new path(pick(turfs))
		food.reagents.add_reagent(/datum/reagent/toxin/slimejelly,5) //Oh god it burns
		ADD_TRAIT(food, TRAIT_FOOD_SILVER, INNATE_TRAIT)
		if(prob(50))
			food.desc += " It smells strange..."
	user.visible_message(span_danger("[src] produces a few pieces of food!"))
	..()

/obj/item/slimecross/burning/bluespace
	colour = "bluespace"
	effect_desc = "Teleports anyone directly next to you."

/obj/item/slimecross/burning/bluespace/do_effect(mob/user)
	user.visible_message(span_danger("[src] sparks, and lets off a shockwave of bluespace energy!"))
	for(var/mob/living/L in range(1, get_turf(user)))
		if(L != user)
			do_teleport(L, get_turf(L), 6, asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE) //Somewhere between the effectiveness of fake and real BS crystal
			new /obj/effect/particle_effect/sparks(get_turf(L))
			playsound(get_turf(L), SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	..()

/obj/item/slimecross/burning/sepia
	colour = "sepia"
	effect_desc = "Turns into a special camera that rewinds time when used."

/obj/item/slimecross/burning/sepia/do_effect(mob/user)
	user.visible_message(span_notice("[src] shapes itself into a camera!"))
	new /obj/item/camera/rewind(get_turf(user))
	..()

/obj/item/slimecross/burning/cerulean
	colour = "cerulean"
	effect_desc = "Produces an extract cloning potion, which copies an extract, as well as its extra uses."

/obj/item/slimecross/burning/cerulean/do_effect(mob/user)
	user.visible_message(span_notice("[src] produces a potion!"))
	new /obj/item/slimepotion/extract_cloner(get_turf(user))
	..()

/obj/item/slimecross/burning/pyrite
	colour = "pyrite"
	effect_desc = "Shatters all lights in the current room."

/obj/item/slimecross/burning/pyrite/do_effect(mob/user)
	var/area/user_area = get_area(user)
	if(isnull(user_area.apc))
		user.visible_message(span_danger("[src] releases a colorful wave of energy, but nothing seems to happen."))
		return

	user_area.apc.break_lights()
	user.visible_message(span_danger("[src] releases a colorful wave of energy, which shatters the lights!"))
	..()

/obj/item/slimecross/burning/red
	colour = "red"
	effect_desc = "Makes nearby slimes rabid, and they'll also attack their friends."

/obj/item/slimecross/burning/red/do_effect(mob/user)
	user.visible_message(span_danger("[src] pulses a hazy red aura for a moment, which wraps around [user]!"))
	for(var/mob/living/basic/slime/S in view(7, get_turf(user)))
		/*
		if(user in S.Friends)
			var/friendliness = S.Friends[user]
			S.clear_friends()
			S.set_friendship(user, friendliness)
		else
			S.clear_friends()
		*/
		ADD_TRAIT(S, TRAIT_SLIME_RABID, "burning-red")
		S.visible_message(span_danger("The [S] is driven into a dangerous frenzy!"))
	..()

/obj/item/slimecross/burning/green
	colour = "green"
	effect_desc = "The user gets a dull arm blade in the hand it is used in."

/obj/item/slimecross/burning/green/do_effect(mob/user)
	var/which_hand = "l_hand"
	if(!(user.active_hand_index % 2))
		which_hand = "r_hand"
	var/mob/living/L = user
	if(!istype(user))
		return
	var/obj/item/held = L.get_active_held_item() //This should be itself, but just in case...
	L.dropItemToGround(held)
	var/obj/item/melee/arm_blade/slime/blade = new(user)
	if(!L.put_in_hands(blade))
		qdel(blade)
		user.visible_message(span_warning("[src] melts onto [user]'s arm, boiling the flesh horribly!"))
	else
		user.visible_message(span_danger("[src] sublimates the flesh around [user]'s arm, transforming the bone into a gruesome blade!"))
	user.emote("scream")
	L.apply_damage(30,BURN,which_hand)
	..()

/obj/item/slimecross/burning/pink
	colour = "pink"
	effect_desc = "Creates a beaker of synthpax."

/obj/item/slimecross/burning/pink/do_effect(mob/user)
	user.visible_message(span_notice("[src] shrinks into a small, gel-filled pellet!"))
	new /obj/item/slimecrossbeaker/pax(get_turf(user))
	..()

/obj/item/slimecross/burning/gold
	colour = "gold"
	effect_desc = "Creates a gank squad of monsters that are friendly to the user."

/obj/item/slimecross/burning/gold/do_effect(mob/user)
	user.visible_message(span_danger("[src] shudders violently, and summons an army for [user]!"))
	for(var/i in 1 to 3) //Less than gold normally does, since it's safer and faster.
		var/mob/living/spawned_mob = create_random_mob(get_turf(user), HOSTILE_SPAWN)
		spawned_mob.faction |= "[REF(user)]"
		if(prob(50))
			for(var/j in 1 to rand(1, 3))
				step(spawned_mob, pick(NORTH,SOUTH,EAST,WEST))
	..()

/obj/item/slimecross/burning/oil
	colour = "oil"
	effect_desc = "Creates an explosion after a few seconds."

/obj/item/slimecross/burning/oil/do_effect(mob/user)
	user.visible_message(span_warning("[user] activates [src]. It's going to explode!"), span_danger("You activate [src]. It crackles in anticipation"))
	addtimer(CALLBACK(src, PROC_REF(boom)), 50)

/// Inflicts a blastwave upon every mob within a small radius.
/obj/item/slimecross/burning/oil/proc/boom()
	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/explosion2.ogg', 200, TRUE)
	for(var/mob/living/target in range(2, T))
		new /obj/effect/temp_visual/explosion(get_turf(target))
		SSexplosions.med_mov_atom += target
	qdel(src)

/obj/item/slimecross/burning/black
	colour = "black"
	effect_desc = "Gives the user a one-time use slime transformation ability. They can transform back at will and do not lose any items." // monkestation edit: same here

/obj/item/slimecross/burning/black/do_effect(mob/user)
	if(!isliving(user))
		return
	user.visible_message(span_danger("[user] absorbs \the [src]!")) // monkestation edit: slight change to reflect the cast removal
	var/datum/action/cooldown/spell/shapeshift/slime_form/transform = new(user.mind || user)
	transform.remove_on_restore = TRUE
	transform.Grant(user)
	//transform.cast(user) // monkestation removal: embrace the choice (it was broken anyway for whatever reason)
	return ..()

/obj/item/slimecross/burning/lightpink
	colour = "light pink"
	effect_desc = "Paxes everyone in sight."

/obj/item/slimecross/burning/lightpink/do_effect(mob/user)
	user.visible_message(span_danger("[src] lets off a hypnotizing pink glow!"))
	for(var/mob/living/carbon/C in view(7, get_turf(user)))
		C.reagents.add_reagent(/datum/reagent/pax,5)
	..()

/obj/item/slimecross/burning/adamantine
	colour = "adamantine"
	effect_desc = "Creates a mighty adamantine shield."

/obj/item/slimecross/burning/adamantine/do_effect(mob/user)
	user.visible_message(span_notice("[src] crystallizes into a large shield!"))
	new /obj/item/shield/adamantineshield(get_turf(user))
	..()

/obj/item/slimecross/burning/rainbow
	colour = "rainbow"
	effect_desc = "Creates the Rainbow Knife, a kitchen knife that deals random types of damage."

/obj/item/slimecross/burning/rainbow/do_effect(mob/user)
	user.visible_message(span_notice("[src] flattens into a glowing rainbow blade."))
	new /obj/item/knife/rainbowknife(get_turf(user))
	..()
