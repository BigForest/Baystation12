// Areas.dm



// ===
/area
	var/global/global_uid = 0
	var/uid
	var/area_flags

/area/New()
	icon_state = "white"
	uid = ++global_uid
	blend_mode = BLEND_MULTIPLY

	if(!requires_power)
		power_light = 0
		power_equip = 0
		power_environ = 0

	if(dynamic_lighting)
		luminosity = 0
	else
		luminosity = 1

	//name = replacetextEx(name, "\improper", "")

	..()

/area/Initialize()
	. = ..()
	if(!requires_power || !apc)
		power_light = 0
		power_equip = 0
		power_environ = 0
	if(alwaysgravity == TRUE)
		has_gravity = 1
	else if(nevergravity == TRUE)
		has_gravity = 0
	power_change()		// all machines set to current power level, also updates lighting icon

/area/proc/get_contents()
	return contents

/area/proc/get_cameras()
	var/list/cameras = list()
	for (var/obj/machinery/camera/C in src)
		cameras += C
	return cameras

/area/proc/is_shuttle_locked()
	return 0

/area/proc/atmosalert(danger_level, var/alarm_source)
	if (danger_level == 0)
		atmosphere_alarm.clearAlarm(src, alarm_source)
	else
		atmosphere_alarm.triggerAlarm(src, alarm_source, severity = danger_level)

	//Check all the alarms before lowering atmosalm. Raising is perfectly fine.
	for (var/obj/machinery/alarm/AA in src)
		if (!(AA.stat & (NOPOWER|BROKEN)) && !AA.shorted && AA.report_danger_level)
			danger_level = max(danger_level, AA.danger_level)

	if(danger_level != atmosalm)
		if (danger_level < 1 && atmosalm >= 1)
			//closing the doors on red and opening on green provides a bit of hysteresis that will hopefully prevent fire doors from opening and closing repeatedly due to noise
			air_doors_open()
		else if (danger_level >= 2 && atmosalm < 2)
			air_doors_close()

		atmosalm = danger_level
		for (var/obj/machinery/alarm/AA in src)
			AA.update_icon()

		update_icon()

		return 1

	return 0

/area/proc/air_doors_close()
	if(!air_doors_activated)
		air_doors_activated = 1
		if(!all_doors)
			return
		for(var/obj/machinery/door/firedoor/E in all_doors)
			if(!E.blocked)
				if(E.operating)
					E.nextstate = FIREDOOR_CLOSED
				else if(!E.density)
					spawn(0)
						E.close()

/area/proc/air_doors_open()
	if(air_doors_activated)
		air_doors_activated = 0
		if(!all_doors)
			return
		for(var/obj/machinery/door/firedoor/E in all_doors)
			if(!E.blocked)
				if(E.operating)
					E.nextstate = FIREDOOR_OPEN
				else if(E.density)
					spawn(0)
						if(E.can_safely_open())
							E.open()


/area/proc/fire_alert()
	if(!fire)
		fire = 1	//used for firedoor checks
		update_icon()
		mouse_opacity = 0
		if(!all_doors)
			return
		for(var/obj/machinery/door/firedoor/D in all_doors)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_CLOSED
				else if(!D.density)
					spawn()
						D.close()

/area/proc/fire_reset()
	if (fire)
		fire = 0	//used for firedoor checks
		update_icon()
		mouse_opacity = 0
		if(!all_doors)
			return
		for(var/obj/machinery/door/firedoor/D in all_doors)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_OPEN
				else if(D.density)
					spawn(0)
					D.open()

/area/proc/readyalert()
	if(!eject)
		eject = 1
		update_icon()
	return

/area/proc/readyreset()
	if(eject)
		eject = 0
		update_icon()
	return

/area/proc/partyalert()
	if (!( party ))
		party = 1
		update_icon()
		mouse_opacity = 0
	return

/area/proc/partyreset()
	if (party)
		party = 0
		mouse_opacity = 0
		update_icon()
		for(var/obj/machinery/door/firedoor/D in src)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_OPEN
				else if(D.density)
					spawn(0)
					D.open()
	return

#define DO_PARTY(COLOR) animate(color = COLOR, time = 0.5 SECONDS, easing = QUAD_EASING)
/area/update_icon()
	if((atmosalm || fire || eject || party) && (!requires_power||power_environ) && !istype(src, /area/space))//If it doesn't require power, can still activate this proc.
		if(fire && !atmosalm && !eject && !party) // FIRE
			color = "#ff9292"
			animate(src)	// stop any current animations.
			animate(src, color = "#ffa5b2", time = 1 SECOND, loop = -1, easing = SINE_EASING)
			animate(color = "#ff9292", time = 1 SECOND, easing = SINE_EASING)
		else if(atmosalm && !fire && !eject && !party) // ATMOS
			color = "#b3dfff"
			animate(src)
			animate(src, color = "#78dfff", time = 3 SECOND, loop = -1, easing = SINE_EASING)
			animate(color = "#b3dfff", time = 3 SECOND, easing = SINE_EASING)
		else if(eject && !atmosalm && !fire && !party) // EJECT
			color = "#ff9292"
			animate(src)
			animate(src, color = "#bc8a81", time = 1 SECOND, loop = -1, easing = EASE_IN|CUBIC_EASING)
			animate(color = "#ff9292", time = 0.5 SECOND, easing = EASE_OUT|CUBIC_EASING)
		else if(party && !atmosalm && !fire && !eject) // PARTY
			color = "#ff728e"
			animate(src)
			animate(src, color = "#7272ff", time = 0.5 SECONDS, loop = -1, easing = QUAD_EASING)
			DO_PARTY("#72aaff")
			DO_PARTY("#ffc68e")
			DO_PARTY("#72c6ff")
			DO_PARTY("#ff72e2")
			DO_PARTY("#72ff8e")
			DO_PARTY("#ffff8e")
			DO_PARTY("#ff728e")
		else
			color = "#ffb2b2"
			animate(src)
			animate(src, color = "#b3dfff", time = 0.5 SECOND, loop = -1, easing = SINE_EASING)
			animate(color = "#ffb2b2", time = 0.5 SECOND, loop = -1, easing = SINE_EASING)
	else
		animate(src, color = "#ffffff", time = 0.5 SECONDS, easing = QUAD_EASING)	// Stop the animation.

#undef DO_PARTY

/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel

	if(!requires_power)
		return 1
	if(always_unpowered)
		return 0
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0

// called when power status changes
/area/proc/power_change()
	for(var/obj/machinery/M in src)	// for each machine in the area
		M.power_change()			// reverify power status (to update icons etc.)
	if (atmosalm || fire || eject || party)
		update_icon()

/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ
	return used

/area/proc/clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(var/amount, var/chan)
	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount

/area/proc/set_lightswitch(var/new_switch)
	if(lightswitch != new_switch)
		lightswitch = new_switch
		for(var/obj/machinery/light_switch/L in src)
			L.sync_state()
		update_icon()
		power_change()

/area/proc/set_emergency_lighting(var/enable)
	for(var/obj/machinery/light/M in src)
		M.set_emergency_lighting(enable)


var/list/mob/living/forced_ambiance_list = new

/area/Entered(A)
	if(!istype(A,/mob/living))	return

	var/mob/living/L = A
	if(!L.ckey)	return

	if(!L.lastarea)
		L.lastarea = get_area(L.loc)
	var/area/newarea = get_area(L.loc)
	var/area/oldarea = L.lastarea
	if(oldarea.has_gravity != newarea.has_gravity)
		if(newarea.has_gravity == 1 && L.m_intent == M_RUN) // Being ready when you change areas allows you to avoid falling.
			thunk(L)
		L.update_floating()

	play_ambience(L)
	L.lastarea = newarea
	
/area/proc/play_ambience(var/mob/living/L)
	// Ambience goes down here -- make sure to list each area seperately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(!(L && L.get_preference_value(/datum/client_preference/play_ambiance) == GLOB.PREF_YES))	return

	var/turf/T = get_turf(L)
	var/hum = 0
	if(!L.ear_deaf && !always_unpowered && power_environ)
		for(var/obj/machinery/atmospherics/unary/vent_pump/vent in src)
			if(vent.can_pump())
				hum = 1
				break
	if(hum)
		if(!L.client.ambience_playing)
			L.client.ambience_playing = 1
			L.playsound_local(T,sound('sound/ambience/vents.ogg', repeat = 1, wait = 0, volume = 20, channel = 2))
	else
		if(L.client.ambience_playing)
			L.client.ambience_playing = 0
			sound_to(L, sound(null, channel = 2))
	
	if(L.lastarea != src)
		if(LAZYLEN(forced_ambience))
			forced_ambiance_list |= L
			var/volume = 25
			if(istype(src, /area/space))
				volume = 100
			L.playsound_local(T,sound(pick(forced_ambience), repeat = 1, wait = 0, volume = volume, channel = 1))
		else	//stop any old area's forced ambience, and try to play our non-forced ones
			sound_to(L, sound(null, channel = 1))
			forced_ambiance_list -= L
			if(ambience.len && prob(35) && (world.time >= L.client.played + 3 MINUTES))
				L.playsound_local(T, sound(pick(ambience), repeat = 0, wait = 0, volume = 15, channel = 1))
				L.client.played = world.time

/area/proc/gravitychange(var/gravitystate = 0)
	has_gravity = gravitystate

	for(var/mob/M in src)
		if(has_gravity)
			thunk(M)
		M.update_floating()

/area/proc/thunk(mob/mob)
	if(istype(get_turf(mob), /turf/space)) // Can't fall onto nothing.
		return

	if(mob.Check_Shoegrip())
		return

	if(istype(mob,/mob/living/carbon/human/))
		var/mob/living/carbon/human/H = mob
		if(prob(H.skill_fail_chance(SKILL_EVA, 100, SKILL_PROF)))
			if(H.m_intent == M_RUN)
				H.AdjustStunned(6)
				H.AdjustWeakened(6)
			else
				H.AdjustStunned(3)
				H.AdjustWeakened(3)
			to_chat(mob, "<span class='notice'>The sudden appearance of gravity makes you fall to the floor!</span>")

/area/proc/prison_break()
	var/obj/machinery/power/apc/theAPC = get_apc()
	if(theAPC && theAPC.operating)
		for(var/obj/machinery/power/apc/temp_apc in src)
			temp_apc.overload_lighting(70)
		for(var/obj/machinery/door/airlock/temp_airlock in src)
			temp_airlock.prison_open()
		for(var/obj/machinery/door/window/temp_windoor in src)
			temp_windoor.open()

/area/proc/has_gravity()
	return has_gravity

/area/space/has_gravity()
	return 0

/proc/has_gravity(atom/AT, turf/T)
	if(!T)
		T = get_turf(AT)
	var/area/A = get_area(T)
	if(istype(T, /turf/space)) //because space
		return 0
	else if(A && A.has_gravity)
		return 1
	else
		if(T && length(SSmachines.gravity_generators))
			return 1
	return 0

/area/proc/get_dimensions()
	var/list/res = list("x"=1,"y"=1)
	var/list/min = list("x"=world.maxx,"y"=world.maxy)
	for(var/turf/T in src)
		res["x"] = max(T.x, res["x"])
		res["y"] = max(T.y, res["y"])
		min["x"] = min(T.x, min["x"])
		min["y"] = min(T.y, min["y"])
	res["x"] = res["x"] - min["x"] + 1
	res["y"] = res["y"] - min["y"] + 1
	return res

/area/proc/has_turfs()
	return !!(locate(/turf) in src)

