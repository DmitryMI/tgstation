/**
 * Expedition config
 * code\modules\expedition
 */

/// Whether Expedition vessel content and its ghost roles are available.
/datum/config_entry/flag/expedition_enabled
	default = TRUE

/// Expedition vessel shuttle ignition time in deciseconds.
/datum/config_entry/number/expedition_ignition_time
	default = 10
	min_val = 0
	integer = FALSE

/// Expedition vessel shuttle call time in deciseconds.
/datum/config_entry/number/expedition_call_time
	default = 10
	min_val = 0
	integer = FALSE

/// Expedition navigation destination designation time in deciseconds.
/datum/config_entry/number/expedition_designate_time
	default = 5
	min_val = 0
	integer = FALSE

/// Whether Expedition navigation displays configured z-level names instead of sector numbers.
/datum/config_entry/flag/expedition_use_z_level_real_names

/// Whether non-Commander Expedition crew share access to the vessel outside its cockpit.
/datum/config_entry/flag/expedition_bays_shared_access

/// Whether all Expedition crew can access the cockpit and communications console.
/datum/config_entry/flag/expedition_cockpit_all_access

/// Maximum number of ruin objectives in an Expedition mission report.
/datum/config_entry/number/expedition_max_objectives
	default = 5
	min_val = 0

/// Syndicate Chaser shuttle ignition time in deciseconds.
/datum/config_entry/number/chaser_ignition_time
	default = 30
	min_val = 0
	integer = FALSE

/// Syndicate Chaser shuttle call time in deciseconds.
/datum/config_entry/number/chaser_call_time
	default = 10
	min_val = 0
	integer = FALSE

/// Syndicate Chaser navigation destination designation time in deciseconds.
/datum/config_entry/number/chaser_designate_time
	default = 5
	min_val = 0
	integer = FALSE

/// How long a Chaser pursuit disrupts Expedition travel, in deciseconds.
/datum/config_entry/number/chaser_hostile_disruption_time
	default = 900
	min_val = 0
	integer = FALSE

/// How long activating the Chaser disruptor prevents the Chaser from travelling again, in deciseconds.
/datum/config_entry/number/chaser_self_disruption_time
	default = 4500
	min_val = 0
	integer = FALSE

/// Delay between Chaser creation and its warning report, in deciseconds.
/datum/config_entry/number/chaser_spawn_warning_delay
	default = 50
	min_val = 0
	integer = FALSE
