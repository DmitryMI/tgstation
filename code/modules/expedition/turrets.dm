#define HULL_TURRET_LETHAL_MODE 1
#define HULL_TURRET_SHOOT_ANOMALOUS (1<<4)
#define HULL_TURRET_SHOOT_BORGS (1<<6)

GLOBAL_LIST_EMPTY(hull_defense_map_consoles)
GLOBAL_LIST_EMPTY(hull_defense_map_turrets)

/// Frame-built defensive turret for Expedition and Syndicate vessels.
/obj/machinery/porta_turret/hull_defense
	name = "hull-defense turret"
	desc = "A configurable vessel-defense turret. It must be authorized with an Expedition or Syndicate ID before it will engage targets."
	circuit = /obj/item/circuitboard/machine/hull_defense_turret
	installation = null
	uses_stored = TRUE
	locked = FALSE
	mode = HULL_TURRET_LETHAL_MODE
	on = FALSE
	turret_flags = HULL_TURRET_SHOOT_ANOMALOUS | HULL_TURRET_SHOOT_BORGS
	/// Base automatic/manual sight radius before scanning-module bonuses.
	var/base_scan_range = 7
	/// Tiles contributed by each scanning-module tier.
	var/scan_range_per_tier = 2
	/// Maximum view-size increase used while manually controlling this turret.
	var/manual_view_cap = 17
	/// Number of rounds emitted during one weapon firing cycle.
	var/weapon_burst_size = 1
	/// Delay between rounds in a burst.
	var/weapon_burst_delay = 2 DECISECONDS
	/// Number of projectiles emitted by each round.
	var/weapon_pellets = 1
	/// Inherent ammunition spread added to the gun's spread.
	var/weapon_variance = 0
	/// Whether ammunition spread is randomized.
	var/weapon_randomspread = FALSE
	/// Cooldown copied from the weapon before capacitor modifiers are applied.
	var/base_weapon_cooldown = 1.5 SECONDS
	/// Installed capacitor tier, cached for inspection and firing-cycle calculations.
	var/capacitor_tier = 1
	/// Whether this turret has been permanently authorized.
	var/faction_configured = FALSE
	/// Integrity of iron-plated construction.
	var/base_material_integrity = 160
	/// Additional maximum integrity granted by every material tier after iron.
	var/integrity_per_material_tier = 40
	/// Tier of the five sheets used as structural plating.
	var/plating_tier = 1
	/// Timer used to keep firing at the acquired target between automatic target scans.
	var/automatic_fire_timer
	/// Target currently used by the automatic firing loop.
	var/datum/weakref/automatic_fire_target
	/// Time through which the current automatic target acquisition remains valid.
	var/automatic_fire_until = 0
	/// Portable turrets rescan for targets every two seconds; maintain fire for that interval.
	var/automatic_fire_window = 2 SECONDS

/obj/machinery/porta_turret/hull_defense/Initialize(mapload)
	scan_range = base_scan_range
	return ..()

/obj/machinery/porta_turret/hull_defense/Destroy()
	clear_automatic_fire_target()
	return ..()

/obj/machinery/porta_turret/hull_defense/examine(mob/user)
	. = ..()
	. += span_notice("Its tier [plating_tier] structural plating supports [max_integrity] maximum integrity.")
	. += span_notice("Its tier [capacitor_tier] capacitor provides a [DisplayTimeText(shot_delay)] firing-cycle cooldown.")

/obj/machinery/porta_turret/hull_defense/RefreshParts()
	. = ..()
	var/obj/item/circuitboard/machine/hull_defense_turret/turret_board = circuit
	var/plating_type = turret_board?.finalize_plating_requirement()
	plating_tier = get_hull_plating_tier(plating_type)
	var/target_max_integrity = base_material_integrity + ((plating_tier - 1) * integrity_per_material_tier)
	if(max_integrity != target_max_integrity)
		modify_max_integrity(target_max_integrity, can_break = FALSE)

	var/obj/item/gun/energy/component_gun = locate() in component_parts
	if(component_gun && component_gun != stored_gun)
		setup(component_gun)
		return

	capacitor_tier = 1
	var/scanner_tier = 0
	for(var/datum/stock_part/capacitor/capacitor in component_parts)
		capacitor_tier = max(capacitor_tier, capacitor.tier)
	for(var/datum/stock_part/scanning_module/scanner in component_parts)
		scanner_tier += scanner.tier

	// Tier 1 preserves the weapon's cooldown; tier 4 halves it.
	shot_delay = base_weapon_cooldown * (1 - ((capacitor_tier - 1) / 6))
	scan_range = base_scan_range + (scanner_tier * scan_range_per_tier)
	tracker?.current_range = scan_range
	tracker?.recalculate_field(full_recalc = TRUE)

/obj/machinery/porta_turret/hull_defense/setup(obj/item/gun/turret_gun)
	if(!turret_gun)
		turret_gun = locate(/obj/item/gun/energy) in component_parts
	if(!istype(turret_gun, /obj/item/gun/energy) || (turret_gun.gun_flags & TURRET_INCOMPATIBLE))
		return

	var/list/gun_properties
	if(stored_gun == turret_gun)
		gun_properties = turret_gun.get_turret_properties()
	else
		gun_properties = ..(turret_gun)

	weapon_burst_size = max(1, turret_gun.burst_size)
	weapon_burst_delay = turret_gun.burst_delay
	base_weapon_cooldown = turret_gun.fire_delay
	if(!base_weapon_cooldown)
		base_weapon_cooldown = gun_properties["shot_delay"]
	if(!base_weapon_cooldown)
		base_weapon_cooldown = initial(shot_delay)

	var/obj/item/gun/energy/energy_gun = turret_gun
	if(length(energy_gun.ammo_type))
		var/ammo_index = min(2, length(energy_gun.ammo_type))
		var/obj/item/ammo_casing/energy/ammo = energy_gun.ammo_type[ammo_index]
		reqpower = ammo.e_cost
		weapon_pellets = max(1, ammo.pellets)
		weapon_variance = ammo.variance
		weapon_randomspread = ammo.randomspread
	RefreshParts()

/obj/machinery/porta_turret/hull_defense/on_construction(mob/user)
	. = ..()
	locked = FALSE
	name = "[initial(name)] [assign_random_name(4, prefix = "HD-")]"

/obj/machinery/porta_turret/proc/is_faction_authorized()
	return TRUE

/obj/machinery/porta_turret/hull_defense/is_faction_authorized()
	return faction_configured

/obj/machinery/porta_turret/hull_defense/supports_faction_configuration()
	return TRUE

/obj/machinery/porta_turret/hull_defense/get_faction_display_name()
	if(!faction_configured)
		return "Unconfigured"
	if(has_faction(FACTION_EXPEDITION))
		return "Expedition"
	if(has_faction(ROLE_SYNDICATE))
		return "Syndicate"
	return ..()

/obj/machinery/porta_turret/hull_defense/configure_faction_from_id(mob/living/user, obj/item/card/id/id)
	if(faction_configured)
		return reject_faction_scan(user, "Faction authorization already configured.")
	if(!id)
		return reject_faction_scan(user, "Hold a recognized ID card in your active hand.")
	if(istype(id, /obj/item/card/id/advanced/expedition) || istype(id, /obj/item/card/id/advanced/silver/expedition))
		return configure_faction(user, FACTION_EXPEDITION)
	if((ACCESS_SYNDICATE in id.access) || (ACCESS_SYNDICATE_LEADER in id.access))
		return configure_faction(user, ROLE_SYNDICATE)
	return reject_faction_scan(user, "ID contains no recognized vessel faction.")

/obj/machinery/porta_turret/hull_defense/proc/reject_faction_scan(mob/living/user, spoken_message)
	to_chat(user, span_warning("[src] rejects the ID scan."))
	say(spoken_message)
	playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 35, TRUE)
	return ITEM_INTERACT_BLOCKING

/obj/machinery/porta_turret/hull_defense/proc/configure_faction(mob/living/user, new_faction)
	set_faction(list(new_faction))
	faction_configured = TRUE
	say("[new_faction] defensive profile authorized.")
	playsound(src, 'sound/machines/ping.ogg', 35, TRUE)
	toggle_on(TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/porta_turret/hull_defense/proc/clear_faction()
	toggle_on(FALSE)
	set_faction(list(FACTION_TURRET))
	faction_configured = FALSE
	say("Faction authorization cleared. Automatic targeting disabled.")
	playsound(src, 'sound/machines/terminal/terminal_off.ogg', 35, TRUE)

/obj/machinery/porta_turret/hull_defense/check_should_process()
	if(!faction_configured)
		if(datum_flags & DF_ISPROCESSING)
			end_processing()
		return FALSE
	return ..()

/obj/machinery/porta_turret/hull_defense/toggle_on(turn_on = TRUE)
	if(turn_on && !faction_configured)
		return
	return ..()

/obj/machinery/porta_turret/hull_defense/setState(on, new_mode, shoot_cyborgs)
	return ..(on, HULL_TURRET_LETHAL_MODE, shoot_cyborgs)

/obj/machinery/porta_turret/hull_defense/assess_perp(mob/living/carbon/human/perp)
	if(has_faction(ROLE_SYNDICATE))
		return 10
	if(has_faction(FACTION_EXPEDITION))
		if(perp.has_faction(FACTION_HOLY))
			return 0
		if(length(perp.get_faction()))
			return 10
	return ..()

/obj/machinery/porta_turret/hull_defense/shootAt(atom/target)
	if(!raised || !stored_gun || !lethal_projectile || (machine_stat & BROKEN))
		return
	if(last_fired + shot_delay > world.time)
		return
	last_fired = world.time
	update_appearance()
	for(var/shot in 1 to weapon_burst_size)
		addtimer(CALLBACK(src, PROC_REF(fire_weapon_round), target), (shot - 1) * weapon_burst_delay)
	if(!manual_control)
		schedule_automatic_fire(target)

/obj/machinery/porta_turret/hull_defense/target(atom/target)
	if(!manual_control)
		var/atom/previous_target = automatic_fire_target?.resolve()
		if(previous_target != target)
			clear_automatic_fire_target()
		automatic_fire_target = WEAKREF(target)
		automatic_fire_until = world.time + automatic_fire_window
	return ..()

/obj/machinery/porta_turret/hull_defense/proc/schedule_automatic_fire(atom/target)
	var/effective_delay = CEILING(shot_delay, world.tick_lag)
	if(world.time + effective_delay > automatic_fire_until)
		return
	if(automatic_fire_timer)
		deltimer(automatic_fire_timer)
	automatic_fire_timer = addtimer(CALLBACK(src, PROC_REF(continue_automatic_fire), WEAKREF(target)), effective_delay, TIMER_STOPPABLE)

/obj/machinery/porta_turret/hull_defense/proc/continue_automatic_fire(datum/weakref/target_ref)
	automatic_fire_timer = null
	var/atom/target = target_ref?.resolve()
	if(!is_valid_automatic_fire_target(target))
		clear_automatic_fire_target()
		return
	setDir(get_dir(base, target))
	shootAt(target)

/obj/machinery/porta_turret/hull_defense/proc/is_valid_automatic_fire_target(atom/target)
	if(!target || target != automatic_fire_target?.resolve())
		return FALSE
	if(world.time > automatic_fire_until || manual_control || !on || !anchored || !powered() || (machine_stat & BROKEN))
		return FALSE
	if(get_dist(base, target) > scan_range || !can_see(base, target, scan_range))
		return FALSE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		if(in_faction(movable_target))
			return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat == DEAD)
			return FALSE
		if(ishuman(living_target))
			var/mob/living/carbon/human/human_target = living_target
			if(assess_perp(human_target) < 4)
				return FALSE
	return TRUE

/obj/machinery/porta_turret/hull_defense/proc/clear_automatic_fire_target()
	if(automatic_fire_timer)
		deltimer(automatic_fire_timer)
	automatic_fire_timer = null
	automatic_fire_target = null
	automatic_fire_until = 0

/obj/machinery/porta_turret/hull_defense/proc/fire_weapon_round(atom/target)
	if(QDELETED(target) || !anchored || !powered() || !stored_gun || (machine_stat & BROKEN))
		return
	var/turf/source_turf = get_turf(src)
	if(!source_turf)
		return
	use_energy(reqpower)
	playsound(loc, lethal_projectile_sound, 75, TRUE)
	for(var/pellet in 1 to weapon_pellets)
		var/obj/projectile/projectile = new lethal_projectile(source_turf)
		// Source immunity normally comes from projectile.firer, but marking the turret
		// as already impacted also protects point-blank and explicitly targeted turf shots.
		projectile.impacted[WEAKREF(src)] = TRUE
		projectile.damage *= stored_gun.projectile_damage_multiplier
		projectile.stamina *= stored_gun.projectile_damage_multiplier
		projectile.speed *= stored_gun.projectile_speed_multiplier
		projectile.wound_bonus += stored_gun.projectile_wound_bonus
		projectile.exposed_wound_bonus += stored_gun.projectile_wound_bonus
		var/shot_spread = 0
		if(stored_gun.spread)
			shot_spread += rand(-round(stored_gun.spread / 2), round(stored_gun.spread / 2))
		if(weapon_variance)
			shot_spread += weapon_randomspread ? rand(-round(weapon_variance / 2), round(weapon_variance / 2)) : round((pellet - ((weapon_pellets + 1) / 2)) * weapon_variance / weapon_pellets)
		projectile.aim_projectile(target, source_turf, deviation = shot_spread)
		projectile.firer = src
		projectile.fired_from = src
		if(ignore_faction)
			APPLY_FACTION_AND_ALLIES_FROM(projectile, src)
		projectile.fire()

/obj/machinery/porta_turret/hull_defense/crowbar_act(mob/living/user, obj/item/tool)
	if(!(machine_stat & BROKEN))
		return default_deconstruction_crowbar(user, tool)
	to_chat(user, span_notice("You begin prying the ruined turret out of its frame..."))
	if(!tool.use_tool(src, user, 2 SECONDS, volume = 50))
		return ITEM_INTERACT_BLOCKING
	deconstruct(disassembled = FALSE)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/porta_turret/hull_defense/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/porta_turret/hull_defense/wrench_act(mob/living/user, obj/item/tool)
	if(raising)
		balloon_alert(user, "turret is moving")
		return ITEM_INTERACT_BLOCKING
	if(anchored)
		remove_control(FALSE)
		if(on)
			toggle_on(FALSE)
		else if(raised)
			popDown()
	return ..()

/obj/machinery/porta_turret/hull_defense/welder_act(mob/living/user, obj/item/tool)
	if(user.combat_mode)
		return ITEM_INTERACT_SKIP_TO_ATTACK
	if(get_integrity() >= max_integrity)
		balloon_alert(user, "turret is undamaged")
		return ITEM_INTERACT_BLOCKING
	if(!tool.tool_start_check(user, amount = 1, heat_required = HIGH_TEMPERATURE_REQUIRED))
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "repairing turret...")
	while(get_integrity() < max_integrity && tool.use_tool(src, user, 2.5 SECONDS, volume = 50, amount = 1))
		repair_damage(20)
		if(get_integrity() >= max_integrity)
			balloon_alert(user, "turret repaired")
			return ITEM_INTERACT_SUCCESS
		balloon_alert(user, "turret partially repaired")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/porta_turret/hull_defense/on_deconstruction(disassembled)
	// The inherited portable turret deletes stored_gun in Destroy(). Let machinery deconstruction eject it instead.
	stored_gun = null
	return ..()

/obj/item/circuitboard/machine/hull_defense_turret
	name = "Hull-Defense Turret (Machine Board)"
	build_path = /obj/machinery/porta_turret/hull_defense
	req_components = list(
		/datum/stock_part/capacitor = 1,
		/datum/stock_part/scanning_module = 1,
		/obj/item/gun/energy = 1,
		/obj/item/stack/sheet = 5,
	)
	/// Concrete sheet type selected for this board's five structural sheets.
	var/plating_type

/obj/item/circuitboard/machine/hull_defense_turret/proc/get_sheet_plating_type(obj/item/component, component_type = component?.type)
	if(ispath(component_type, /obj/item/stack/sheet/iron))
		return /obj/item/stack/sheet/iron
	if(ispath(component_type, /obj/item/stack/sheet/mineral/titanium))
		return /obj/item/stack/sheet/mineral/titanium
	if(ispath(component_type, /obj/item/stack/sheet/plasteel))
		return /obj/item/stack/sheet/plasteel
	if(ispath(component_type, /obj/item/stack/sheet/mineral/plastitanium))
		return /obj/item/stack/sheet/mineral/plastitanium
	return null

/obj/item/circuitboard/machine/hull_defense_turret/can_accept_frame_component(obj/structure/frame/machine/install_frame, obj/item/component, required_path)
	if(required_path != /obj/item/stack/sheet)
		return ..()
	var/candidate_type = get_sheet_plating_type(component)
	if(!candidate_type)
		install_frame.balloon_alert_to_viewers("invalid plating material!")
		return FALSE
	if(plating_type && plating_type != candidate_type)
		install_frame.balloon_alert_to_viewers("plating materials must match!")
		return FALSE
	return TRUE

/obj/item/circuitboard/machine/hull_defense_turret/on_frame_component_added(obj/structure/frame/machine/install_frame, obj/item/component, required_path, amount, component_type)
	if(required_path == /obj/item/stack/sheet)
		plating_type = get_sheet_plating_type(component, component_type)
		var/remaining_sheets = install_frame.req_components[/obj/item/stack/sheet]
		install_frame.req_components -= /obj/item/stack/sheet
		install_frame.req_components[plating_type] = remaining_sheets
		install_frame.req_component_names -= /obj/item/stack/sheet
		var/obj/item/stack/sheet/plating_path = plating_type
		install_frame.req_component_names[plating_type] = initial(plating_path.singular_name)
		req_components -= /obj/item/stack/sheet
		req_components[plating_type] = 5
	return ..()

/obj/item/circuitboard/machine/hull_defense_turret/proc/finalize_plating_requirement()
	if(!plating_type)
		plating_type = /obj/item/stack/sheet/iron
	if(/obj/item/stack/sheet in req_components)
		req_components -= /obj/item/stack/sheet
		req_components[plating_type] = 5
	return plating_type

/obj/item/circuitboard/machine/hull_defense_turret/completion_requirements(obj/structure/frame/machine/install_frame, mob/living/user)
	for(var/obj/item/gun/energy/gun in install_frame.components)
		if(gun.gun_flags & TURRET_INCOMPATIBLE)
			install_frame.balloon_alert(user, "weapon incompatible!")
			return FALSE
	finalize_plating_requirement()
	return TRUE

/// Returns the structural tier represented by one of the supported sheet types.
/proc/get_hull_plating_tier(plating_type)
	switch(plating_type)
		if(/obj/item/stack/sheet/mineral/titanium)
			return 2
		if(/obj/item/stack/sheet/plasteel)
			return 3
		if(/obj/item/stack/sheet/mineral/plastitanium)
			return 4
	return 1

/// Map-ready preset with basic parts, iron plating, an assault Type 5, and Expedition authorization.
/obj/machinery/porta_turret/hull_defense/expedition
	name = "expedition hull-defense turret"
	circuit = /obj/item/circuitboard/machine/hull_defense_turret/expedition
	faction = list(FACTION_EXPEDITION)
	faction_configured = TRUE
	on = TRUE

/obj/item/circuitboard/machine/hull_defense_turret/expedition
	build_path = /obj/machinery/porta_turret/hull_defense/expedition
	plating_type = /obj/item/stack/sheet/iron
	def_components = list(
		/obj/item/gun/energy = /obj/item/gun/energy/laser/assault,
	)

/datum/design/board/hull_defense_turret
	name = "Hull-Defense Turret Board"
	desc = "A control board for a configurable vessel-defense turret."
	id = "hull_defense_turret"
	build_path = /obj/item/circuitboard/machine/hull_defense_turret
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/obj/machinery/computer/hull_defense_control
	name = "hull-defense control console"
	desc = "Links and remotely operates defensive turrets."
	circuit = /obj/item/circuitboard/computer/hull_defense_control
	var/list/linked_turrets = list()
	/// Turret selected for preview in the console UI.
	var/datum/weakref/selected_turret
	/// Turret currently under manual control.
	var/datum/weakref/active_turret
	/// User currently operating active_turret.
	var/mob/living/current_operator
	var/datum/action/hull_defense_cycle/previous/previous_turret_action
	var/datum/action/hull_defense_cycle/next/next_turret_action
	var/atom/movable/screen/map_view/camera/cam_screen

/obj/machinery/computer/hull_defense_control/Initialize(mapload)
	. = ..()
	cam_screen = new
	cam_screen.generate_view("hull_defense_[REF(src)]_map")

/obj/machinery/computer/hull_defense_control/Destroy()
	var/obj/machinery/porta_turret/controlled = active_turret?.resolve()
	controlled?.remove_control(FALSE)
	for(var/datum/weakref/turret_ref in linked_turrets.Copy())
		var/obj/machinery/porta_turret/turret = turret_ref.resolve()
		if(turret?.linked_control_console?.resolve() == src)
			turret.linked_control_console = null
	linked_turrets.Cut()
	QDEL_NULL(previous_turret_action)
	QDEL_NULL(next_turret_action)
	QDEL_NULL(cam_screen)
	return ..()

/obj/machinery/computer/hull_defense_control/process()
	var/obj/machinery/porta_turret/turret = active_turret?.resolve()
	if(!turret || !is_turret_on_same_z(turret) || !turret.anchored || (turret.machine_stat & BROKEN) || !is_active_operator(turret, current_operator) || !can_interact(current_operator) || !powered() || !turret.powered())
		turret?.remove_control()
		return PROCESS_KILL

/obj/machinery/computer/hull_defense_control/proc/is_turret_on_same_z(obj/machinery/porta_turret/turret)
	var/turf/console_turf = get_turf(src)
	var/turf/turret_turf = get_turf(turret)
	return console_turf && turret_turf && console_turf.z == turret_turf.z

/obj/machinery/computer/hull_defense_control/proc/is_active_operator(obj/machinery/porta_turret/turret, mob/living/user)
	return turret && user && active_turret?.resolve() == turret && current_operator == user && turret.remote_controller == user && turret.linked_control_console?.resolve() == src

/obj/machinery/computer/hull_defense_control/proc/get_manual_view_offset(obj/machinery/porta_turret/turret, mob/living/user)
	var/requested_range = turret.scan_range
	if(istype(turret, /obj/machinery/porta_turret/hull_defense))
		var/obj/machinery/porta_turret/hull_defense/hull_turret = turret
		requested_range = min(hull_turret.scan_range, hull_turret.manual_view_cap)
	var/list/default_view = getviewsize(user.client.view_size.default)
	var/default_radius = (min(default_view[1], default_view[2]) - 1) / 2
	return max(0, requested_range - default_radius)

/obj/machinery/computer/hull_defense_control/proc/on_control_started(obj/machinery/porta_turret/turret, mob/living/user)
	active_turret = WEAKREF(turret)
	current_operator = user
	if(!previous_turret_action)
		previous_turret_action = new(src)
	if(!next_turret_action)
		next_turret_action = new(src)
	previous_turret_action.Grant(user)
	next_turret_action.Grant(user)
	begin_processing()

/obj/machinery/computer/hull_defense_control/proc/on_control_ended(obj/machinery/porta_turret/turret)
	if(active_turret?.resolve() != turret)
		return
	previous_turret_action?.Remove(current_operator)
	next_turret_action?.Remove(current_operator)
	active_turret = null
	current_operator = null
	end_processing()

/obj/machinery/computer/hull_defense_control/proc/cycle_controlled_turret(mob/living/user, direction)
	var/obj/machinery/porta_turret/current = active_turret?.resolve()
	if(!is_active_operator(current, user))
		return FALSE
	var/list/available = list()
	for(var/datum/weakref/turret_ref in linked_turrets.Copy())
		var/obj/machinery/porta_turret/turret = turret_ref.resolve()
		if(!turret)
			linked_turrets -= turret_ref
			continue
		available += turret
	if(length(available) < 2)
		return FALSE
	var/current_index = available.Find(current)
	for(var/offset in 1 to length(available) - 1)
		var/candidate_index = 1 + ((current_index - 1 + (offset * direction) + (length(available) * 2)) % length(available))
		var/obj/machinery/porta_turret/candidate = available[candidate_index]
		if(!candidate.can_accept_console_control(src, user, allow_console_switch = TRUE))
			continue
		current.remove_control(FALSE)
		return candidate.give_console_control(src, user)
	return FALSE

/obj/machinery/computer/hull_defense_control/proc/unlink_turret(obj/machinery/porta_turret/turret)
	if(!turret)
		return FALSE
	if(turret.manual_control && turret.linked_control_console?.resolve() == src)
		turret.remove_control(FALSE)
	linked_turrets -= WEAKREF(turret)
	if(turret.linked_control_console?.resolve() == src)
		turret.linked_control_console = null
	if(selected_turret?.resolve() == turret)
		selected_turret = null
		cam_screen.cam_background.color = null
		cam_screen.set_position(1, 1)
		cam_screen?.show_camera_static()
	return TRUE

/obj/machinery/computer/hull_defense_control/proc/link_turret(obj/machinery/porta_turret/turret)
	if(!turret)
		return FALSE
	var/obj/machinery/computer/hull_defense_control/old_console = turret.linked_control_console?.resolve()
	if(old_console && old_console != src)
		return FALSE
	turret.linked_control_console = WEAKREF(src)
	linked_turrets |= WEAKREF(turret)
	if(!selected_turret)
		selected_turret = WEAKREF(turret)
	return TRUE

/obj/machinery/computer/hull_defense_control/proc/update_preview()
	var/obj/machinery/porta_turret/turret = selected_turret?.resolve()
	if(!turret || !(WEAKREF(turret) in linked_turrets) || !is_turret_on_same_z(turret) || !turret.powered() || (turret.machine_stat & BROKEN))
		cam_screen.cam_background.color = null
		cam_screen.set_position(1, 1)
		cam_screen.show_camera_static()
		return
	var/turf/center_turf = get_turf(turret.base)
	if(!center_turf)
		cam_screen.cam_background.color = null
		cam_screen.set_position(1, 1)
		cam_screen.show_camera_static()
		return
	var/list/visible_turfs = list()
	for(var/turf/visible_turf in view(turret.scan_range, center_turf))
		visible_turfs += visible_turf
	if(!length(visible_turfs))
		cam_screen.cam_background.color = null
		cam_screen.set_position(1, 1)
		cam_screen.show_camera_static()
		return
	// Keep the preview centered and consistently scaled even when walls make the
	// visible-turf bounding box asymmetric. The background represents unseen tiles.
	var/preview_size = (turret.scan_range * 2) + 1
	var/list/visible_bounds = get_bbox_of_atoms(visible_turfs)
	var/content_x = turret.scan_range + 1 - (center_turf.x - visible_bounds[1])
	var/content_y = turret.scan_range + 1 - (center_turf.y - visible_bounds[2])
	cam_screen.set_position(content_x, content_y)
	cam_screen.show_camera(visible_turfs, preview_size, preview_size)

/obj/machinery/computer/hull_defense_control/ui_interact(mob/user, datum/tgui/ui)
	if(!user.client)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	if(!selected_turret)
		for(var/datum/weakref/turret_ref in linked_turrets)
			if(turret_ref.resolve())
				selected_turret = turret_ref
				break
	update_preview()
	ui = new(user, src, "HullDefenseControl", name)
	ui.open()
	cam_screen.display_to(user, ui.window)

/obj/machinery/computer/hull_defense_control/ui_close(mob/user)
	. = ..()
	cam_screen?.hide_from(user)

/obj/machinery/computer/hull_defense_control/ui_static_data(mob/user)
	return list("mapRef" = cam_screen.assigned_map)

/obj/machinery/computer/hull_defense_control/ui_data(mob/user)
	var/list/data = list("turrets" = list(), "selected" = null)
	var/obj/machinery/porta_turret/selected = selected_turret?.resolve()
	if(selected)
		data["selected"] = REF(selected)
	for(var/datum/weakref/turret_ref in linked_turrets.Copy())
		var/obj/machinery/porta_turret/turret = turret_ref.resolve()
		if(!turret)
			linked_turrets -= turret_ref
			continue
		data["turrets"] += list(list(
			"ref" = REF(turret),
			"name" = turret.name,
			"powered" = turret.powered(),
			"automatic" = turret.on,
			"configured" = turret.is_faction_authorized(),
			"clearable" = istype(turret, /obj/machinery/porta_turret/hull_defense) && turret.is_faction_authorized(),
			"sameZ" = is_turret_on_same_z(turret),
			"range" = turret.scan_range,
		))
	update_preview()
	return data

/obj/machinery/computer/hull_defense_control/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	var/obj/machinery/porta_turret/turret = locate(params["ref"])
	if(!istype(turret) || !(WEAKREF(turret) in linked_turrets) || !can_interact(user))
		return
	switch(action)
		if("select")
			selected_turret = WEAKREF(turret)
			update_preview()
			return TRUE
		if("control")
			if(turret.give_console_control(src, user))
				ui.close()
				return TRUE
		if("automatic")
			if(!turret.on && !turret.is_faction_authorized())
				turret.balloon_alert(user, "faction not configured")
				return
			turret.toggle_on(!turret.on)
			return TRUE
		if("clear_faction")
			if(!istype(turret, /obj/machinery/porta_turret/hull_defense))
				return
			var/obj/machinery/porta_turret/hull_defense/hull_turret = turret
			if(!hull_turret.faction_configured)
				return
			hull_turret.clear_faction()
			return TRUE
		if("unlink")
			return unlink_turret(turret)

/obj/machinery/computer/hull_defense_control/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(istype(tool.buffer, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/turret = tool.buffer
		if(!link_turret(turret))
			balloon_alert(user, "turret already linked")
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "turret linked")
		return ITEM_INTERACT_SUCCESS
	return ..()

/// Place one helper on a turret and another on its console, giving both helpers the same link_id.
/obj/effect/mapping_helpers/hull_defense_link
	name = "hull-defense link helper"
	icon_state = "airalarm_link_helper"
	late = TRUE
	var/link_id = ""

/obj/effect/mapping_helpers/hull_defense_link/LateInitialize()
	if(!length(link_id))
		log_mapping("[src] at [AREACOORD(src)] has no link_id.")
		qdel(src)
		return
	var/obj/machinery/porta_turret/turret = locate() in loc
	var/obj/machinery/computer/hull_defense_control/console = locate() in loc
	if(!!turret == !!console)
		log_mapping("[src] at [AREACOORD(src)] must share a turf with exactly one turret or hull-defense console.")
		qdel(src)
		return
	if(turret)
		register_map_turret(turret)
	else
		register_map_console(console)
	qdel(src)

/obj/effect/mapping_helpers/hull_defense_link/proc/register_map_turret(obj/machinery/porta_turret/turret)
	var/list/turrets = GLOB.hull_defense_map_turrets[link_id]
	if(!turrets)
		turrets = list()
		GLOB.hull_defense_map_turrets[link_id] = turrets
	turrets |= WEAKREF(turret)
	var/datum/weakref/console_ref = GLOB.hull_defense_map_consoles[link_id]
	var/obj/machinery/computer/hull_defense_control/console = console_ref?.resolve()
	if(console && !console.link_turret(turret))
		log_mapping("[src] could not link [turret] at [AREACOORD(turret)] to [console].")

/obj/effect/mapping_helpers/hull_defense_link/proc/register_map_console(obj/machinery/computer/hull_defense_control/console)
	var/datum/weakref/existing_ref = GLOB.hull_defense_map_consoles[link_id]
	var/obj/machinery/computer/hull_defense_control/existing_console = existing_ref?.resolve()
	if(existing_console && existing_console != console)
		log_mapping("[src] found multiple hull-defense consoles using link_id '[link_id]'.")
		return
	GLOB.hull_defense_map_consoles[link_id] = WEAKREF(console)
	for(var/datum/weakref/turret_ref in GLOB.hull_defense_map_turrets[link_id])
		var/obj/machinery/porta_turret/turret = turret_ref.resolve()
		if(turret && !console.link_turret(turret))
			log_mapping("[src] could not link [turret] at [AREACOORD(turret)] to [console].")

/datum/action/hull_defense_cycle
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_cycle_equip_off"
	var/direction = 1

/datum/action/hull_defense_cycle/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/obj/machinery/computer/hull_defense_control/console = target
	if(istype(console))
		console.cycle_controlled_turret(clicker, direction)

/datum/action/hull_defense_cycle/previous
	name = "Previous Turret"
	direction = -1

/datum/action/hull_defense_cycle/next
	name = "Next Turret"
	direction = 1

/obj/item/circuitboard/computer/hull_defense_control
	name = "Hull-Defense Control Console (Computer Board)"
	build_path = /obj/machinery/computer/hull_defense_control

/datum/design/board/hull_defense_control
	name = "Hull-Defense Control Console Board"
	desc = "A console board for linking and manually operating defensive turrets."
	id = "hull_defense_control"
	build_path = /obj/item/circuitboard/computer/hull_defense_control
	category = list(RND_CATEGORY_COMPUTER + RND_SUBCATEGORY_COMPUTER_SECURITY)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/techweb_node/expedition_turrets
	id = TECHWEB_NODE_EXPEDITION_TURRETS
	display_name = "Expeditionary Hull Defense"
	description = "Vessel-scale defensive automation compatible with the Type 5 energy-weapon platform."
	prereq_ids = list(TECHWEB_NODE_EXP_LASER_RIFLES)
	design_ids = list("hull_defense_turret", "hull_defense_control")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)
	hidden = TRUE
	announce_channels = list(RADIO_CHANNEL_SECURITY)

#undef HULL_TURRET_LETHAL_MODE
#undef HULL_TURRET_SHOOT_ANOMALOUS
#undef HULL_TURRET_SHOOT_BORGS
