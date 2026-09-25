# test_raffica.gd - MIDNIGHT ELIXIR: 60 s di click VERI a caso sui tasti.
# Esito: 0 SCRIPT ERROR, spin mai bloccato, griglia sempre 30 tile, saldo >= 0.
extends SceneTree
var main
var rng := RandomNumberGenerator.new()
var click_tot := 0
var max_stuck := 0.0
var stuck_t := 0.0
var problemi := 0

func _initialize() -> void:
	rng.seed = 424242
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run()

func _click(ctrl: Control) -> void:
	if ctrl == null or not is_instance_valid(ctrl) or not ctrl.visible:
		return
	var p: Vector2 = ctrl.global_position + ctrl.size / 2.0
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = p; ev.global_position = p; ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	click_tot += 1

func _space() -> void:
	var k := InputEventKey.new()
	k.keycode = KEY_SPACE; k.pressed = true
	Input.parse_input_event(k)
	var k2 := k.duplicate(); k2.pressed = false
	Input.parse_input_event(k2)
	click_tot += 1

func _run() -> void:
	await create_timer(1.0).timeout
	main.turbo = true
	var t := 0.0
	var DUR := 60.0
	var was_spinning := false
	while t < DUR:
		var dt := 0.25
		await create_timer(dt).timeout
		t += dt
		# --- controlli ---
		if main.spinning:
			stuck_t += dt
			max_stuck = max(max_stuck, stuck_t)
		else:
			stuck_t = 0.0
		var n_tiles := 0
		for c in range(main.COLS):
			n_tiles += main.cells[c].size()
		if not main.spinning and n_tiles != 30:
			problemi += 1
			print("PROBLEMA t=%.1f tile=%d (attesi 30)" % [t, n_tiles])
		if main.balance < -0.001:
			problemi += 1
			print("PROBLEMA t=%.1f saldo negativo %.2f" % [t, main.balance])
		# --- click a caso ---
		if main.auto_layer != null:
			# selettore autoplay aperto: scelgo un'opzione
			for ch in main.auto_layer.get_children():
				if ch is Panel:
					var opts := []
					for b in ch.get_children():
						if b is Button: opts.append(b)
					if opts.size() > 0:
						_click(opts[rng.randi() % opts.size()])
			continue
		var r := rng.randf()
		if r < 0.40:
			_click(main.spin_hitbox)
		elif r < 0.55:
			_space()
		elif r < 0.68:
			_click(main.turbo_btn)
		elif r < 0.80:
			_click(main.bet_chip)
		elif r < 0.90:
			_click(main.auto_button)
		else:
			# click "a vuoto" in un punto a caso dello schermo
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.position = Vector2(rng.randf() * 1152.0, rng.randf() * 648.0)
			ev.global_position = ev.position; ev.pressed = true
			Input.parse_input_event(ev)
			var ev2 := ev.duplicate(); ev2.pressed = false
			Input.parse_input_event(ev2)
	# attendo che finisca l'eventuale spin in corso (max 60 s)
	var w := 0.0
	while main.spinning and w < 60.0:
		await create_timer(0.5).timeout
		w += 0.5
	print("RAFFICA_FINE click=%d  spin_bloccato_max=%.1fs  problemi=%d  spinning_finale=%s  saldo=%.2f  bet=%.0f  turbo=%s" % [click_tot, max_stuck, problemi, str(main.spinning), main.balance, main.bet, str(main.turbo)])
	quit()
