/obj/effect/mob_spawn/ghost_role/human/usable_sleeper
	name = "cryogenic sleeper"
	desc = "A sealed sleeper pod with an occupant still inside."
	prompt_name = "a sleeper crewmember"
	density = FALSE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	mob_species = /datum/species/human
	spawner_job_path = /datum/job/ghost_role
	allow_custom_character = GHOSTROLE_TAKE_PREFS_APPEARANCE
	/// The sleeper type that replaces this spawner after a ghost claims it.
	var/unlocked_sleeper_type = /obj/machinery/sleeper/expedition

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/create(mob/mob_possessor, newname, apply_prefs)
	var/mob/living/carbon/human/spawned_human = ..()
	if(!istype(spawned_human))
		return spawned_human

	var/turf/spawn_turf = get_turf(src)
	var/obj/machinery/sleeper/unlocked_sleeper = new unlocked_sleeper_type(spawn_turf)
	unlocked_sleeper.setDir(dir)
	unlocked_sleeper.state_open = FALSE
	unlocked_sleeper.set_density(TRUE)
	unlocked_sleeper.set_occupant(spawned_human)
	spawned_human.forceMove(unlocked_sleeper)
	unlocked_sleeper.update_appearance()
	if(spawned_human.stat != DEAD)
		to_chat(spawned_human, unlocked_sleeper.enter_message)
	return spawned_human

/obj/effect/mob_spawn/ghost_role/human/usable_sleeper/admin
	name = "administrative cryogenic sleeper"
	prompt_name = "an expedition administrator"
	outfit = /datum/outfit/admin
