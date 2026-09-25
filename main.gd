# ================================================================
# main.gd - MIDNIGHT ELIXIR (gioco 3) - v1.0
# Griglia 6x5 pay-anywhere + cascata. Consuma i "passi" del motore
# (slot_engine.gd, collect=true) per animare il tumble.
# Convenzioni HUD/tasti riprese da Midnight Case.
# ================================================================
extends Node2D

# DEBUG: true = il tasto F forza i free spin (SOLO per collaudo, mai in release)
const DEBUG_FS_KEY := false

const ENG := preload("res://slot_engine.gd")
const LNG := preload("res://lang.gd")

func T(k: String) -> String:
	return LNG.t(k, LNG.attiva())

const VW := 1152.0
const VH := 648.0
const COLS := 6
const ROWS := 5
const CELL := 80
const GRID_W := COLS * CELL
const GRID_H := ROWS * CELL
const GRID_X := 185.0
const GRID_Y := 140.0
# mago: altezza costante per tutte le pose (idle/cast/win) cosi' non rimpicciolisce
const MAGO_H := 500.0
const MAGO_W := 330.0
const MAGO_RIGHT := 10.0
# buco della cornice (frazioni dell'immagine cornice.png, misurate)
const HX0 := 0.0518
const HX1 := 0.9471
const HY0 := 0.0725
const HY1 := 0.9290

# tempi (secondi); piu' alti = piu' "peso". turbo li accorcia
const FLASH_T := 0.42
const DROP_T := 0.46
const WIN_HOLD := 0.55

var engine
var rng := RandomNumberGenerator.new()

var grid_root: Node2D = null
var cells: Array = []          # cells[c] = Array[TextureRect] (indice 0 = alto)
var tex: Dictionary = {}       # sym -> Texture2D

var balance := 1000.0
var bet := 10.0
var spinning := false
var turbo := false
var autospin_left := 0

# HUD
var lbl_balance: Label
var lbl_win: Label
var lbl_bet: Label
var win_pop: Label
var fs_banner: Label
var spin_hitbox: BaseButton
var turbo_btn: BaseButton
var auto_button: BaseButton
var bet_chip: BaseButton
var bet_num: Label
var turbo_tex_off: Texture2D
var turbo_tex_on: Texture2D
var auto_layer: Control = null
var auto_badge: Label = null
var mult_badge: Control = null
var mult_lbl: Label = null
var mult_last := 1
var fs_counter: Label = null
var fs_pill: Panel = null
# audio
var music_player: AudioStreamPlayer = null
var sfx_players: Array = []
var audio_cache: Dictionary = {}
const MUSIC_DB := -9.0
const SFX_DB := -4.0

# personaggio
var mago: TextureRect
var mago_idle: Array = []
var mago_idle_static: Texture2D
var mago_win: Texture2D
var mago_cast: Texture2D
var mago_state := "idle"
var idle_t := 0.0
var idle_i := 0
var idle_gap := 0.0
var idle_playing := false
var idle_play_t := 0.0

func _spd(t: float) -> float:
	return t * 0.5 if turbo else t

# ------------------------------------------------------------------
func _ready() -> void:
	rng.randomize()
	engine = ENG.new()
	engine.rng = rng
	_load_textures()
	_build_background()
	_build_grid()
	_build_hud()
	_build_mago()
	_build_audio()
	if Engine.has_meta("me_bet"):
		bet = float(Engine.get_meta("me_bet"))
	Engine.set_meta("me_bet", bet)
	_update_hud()
	_play_music("music_base")
	# griglia iniziale a caso
	var g = engine.new_grid(false)
	_set_grid_instant(g)
	set_process(true)

func _load_textures() -> void:
	for sym in engine.FILE_SIMBOLI.keys():
		var p := "res://assets/symbols/%s.png" % engine.FILE_SIMBOLI[sym]
		if ResourceLoader.exists(p):
			tex[sym] = load(p)
	for i in [1, 2, 3]:
		var pp := "res://assets/alchimista_idle_%d.png" % i
		if ResourceLoader.exists(pp):
			mago_idle.append(load(pp))
	if mago_idle.size() >= 1:
		mago_idle_static = mago_idle[0]
	elif ResourceLoader.exists("res://assets/alchimista_idle.png"):
		mago_idle_static = load("res://assets/alchimista_idle.png")
	if ResourceLoader.exists("res://assets/alchimista_win.png"):
		mago_win = load("res://assets/alchimista_win.png")
	if ResourceLoader.exists("res://assets/alchimista_cast.png"):
		mago_cast = load("res://assets/alchimista_cast.png")

func _build_background() -> void:
	if ResourceLoader.exists("res://assets/sfondo.png"):
		var bgt := TextureRect.new()
		bgt.texture = load("res://assets/sfondo.png")
		bgt.flip_h = true   # specchiato: calderone a sinistra, mago a destra
		bgt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bgt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bgt.size = Vector2(VW, VH)
		add_child(bgt)
	else:
		var bg := ColorRect.new()
		bg.color = Color("#1a1030")
		bg.size = Vector2(VW, VH)
		add_child(bg)
	# pannello scuro dietro la griglia per far risaltare i simboli
	var backdrop := Panel.new()
	backdrop.position = Vector2(GRID_X - 22, GRID_Y - 22)
	backdrop.size = Vector2(GRID_W + 44, GRID_H + 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.12, 0.66)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.55, 0.42, 0.75, 0.55)
	backdrop.add_theme_stylebox_override("panel", sb)
	add_child(backdrop)
	if ResourceLoader.exists("res://assets/logo.png"):
		var logo := TextureRect.new()
		logo.texture = load("res://assets/logo.png")
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.size = Vector2(424, 222)
		logo.position = Vector2(VW - 434, -10)
		add_child(logo)
	else:
		var title := Label.new()
		title.text = "MIDNIGHT  ELIXIR"
		title.position = Vector2(GRID_X, 34)
		title.size = Vector2(GRID_W, 40)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 34)
		title.add_theme_color_override("font_color", Color("#e8c86a"))
		add_child(title)

func _build_grid() -> void:
	grid_root = Node2D.new()
	grid_root.position = Vector2(GRID_X, GRID_Y)
	add_child(grid_root)
	if ResourceLoader.exists("res://assets/cornice.png"):
		var t: Texture2D = load("res://assets/cornice.png")
		var tw := float(t.get_width())
		var th := float(t.get_height())
		var hwr := HX1 - HX0
		var hhr := HY1 - HY0
		var sc: float = max(GRID_W / (tw * hwr), GRID_H / (th * hhr))
		var fw := tw * sc
		var fh := th * sc
		var hw := tw * hwr * sc
		var hh := th * hhr * sc
		var cor := TextureRect.new()
		cor.texture = t
		cor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cor.size = Vector2(fw, fh)
		cor.position = Vector2(-(hw - GRID_W) / 2.0 - HX0 * fw, -(hh - GRID_H) / 2.0 - HY0 * fh)
		grid_root.add_child(cor)
	else:
		var frame := Panel.new()
		frame.position = Vector2(-16, -16)
		frame.size = Vector2(GRID_W + 32, GRID_H + 32)
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Color(0.06, 0.035, 0.12, 0.94)
		fsb.set_corner_radius_all(24)
		fsb.set_border_width_all(4)
		fsb.border_color = Color(0.80, 0.64, 0.35)
		fsb.shadow_size = 14
		fsb.shadow_color = Color(0, 0, 0, 0.6)
		frame.add_theme_stylebox_override("panel", fsb)
		grid_root.add_child(frame)
		var inner := Panel.new()
		inner.position = Vector2(-6, -6)
		inner.size = Vector2(GRID_W + 12, GRID_H + 12)
		var isb := StyleBoxFlat.new()
		isb.bg_color = Color(0, 0, 0, 0)
		isb.set_corner_radius_all(18)
		isb.set_border_width_all(2)
		isb.border_color = Color(0.92, 0.80, 0.46, 0.65)
		inner.add_theme_stylebox_override("panel", isb)
		grid_root.add_child(inner)
		var gem_cols := [Color("#a24ae0"), Color("#4a7ae0"), Color("#e04a5a"), Color("#4ae07a")]
		var pts := [
			Vector2(-16, -16), Vector2(GRID_W + 16, -16),
			Vector2(GRID_W + 16, GRID_H + 16), Vector2(-16, GRID_H + 16),
			Vector2(GRID_W / 2.0, -16), Vector2(GRID_W / 2.0, GRID_H + 16),
			Vector2(-16, GRID_H / 2.0), Vector2(GRID_W + 16, GRID_H / 2.0),
		]
		for i in range(pts.size()):
			_gemma(pts[i], gem_cols[i % gem_cols.size()])
	# celle "vetro" scuro, bordo caldo tenue
	for c in range(COLS):
		for r in range(ROWS):
			var panel := Panel.new()
			panel.position = Vector2(c * CELL + 4, r * CELL + 4)
			panel.size = Vector2(CELL - 8, CELL - 8)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			sb.set_corner_radius_all(14)
			sb.set_border_width_all(1)
			sb.border_color = Color(0.78, 0.68, 0.92, 0.13)
			panel.add_theme_stylebox_override("panel", sb)
			grid_root.add_child(panel)
	for c in range(COLS):
		cells.append([])

func _cell_pos(c: int, r: int) -> Vector2:
	return Vector2(c * CELL, r * CELL)

func _make_tile(sym: int) -> TextureRect:
	var t := TextureRect.new()
	t.set_meta("sym", sym)
	t.size = Vector2(CELL, CELL)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex.has(sym):
		t.texture = tex[sym]
	else:
		# placeholder (es. MULT: nessun asset ancora)
		t.modulate = Color(0.8, 0.6, 1.0)
		var ph := ColorRect.new()
		ph.color = Color(0.4, 0.2, 0.6, 0.5)
		ph.size = Vector2(CELL - 20, CELL - 20)
		ph.position = Vector2(10, 10)
		t.add_child(ph)
		var q := Label.new()
		q.text = "×"
		q.position = Vector2(CELL / 2.0 - 8, CELL / 2.0 - 16)
		q.add_theme_font_size_override("font_size", 30)
		t.add_child(q)
	return t

func _clear_tiles() -> void:
	for c in range(COLS):
		for tile in cells[c]:
			if is_instance_valid(tile):
				tile.queue_free()
		cells[c] = []

func _set_grid_instant(grid: Array) -> void:
	_clear_tiles()
	for c in range(COLS):
		var col: Array = []
		for r in range(ROWS):
			var t := _make_tile(grid[c][r])
			grid_root.add_child(t)
			t.position = _cell_pos(c, r)
			col.append(t)
		cells[c] = col

func _drop_in_grid(grid: Array) -> void:
	_clear_tiles()
	for c in range(COLS):
		var col: Array = []
		for r in range(ROWS):
			var t := _make_tile(grid[c][r])
			grid_root.add_child(t)
			t.position = _cell_pos(c, r - ROWS - 1)
			var tw := create_tween()
			tw.tween_interval(c * 0.03)
			tw.tween_property(t, "position", _cell_pos(c, r), _spd(DROP_T)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			col.append(t)
		cells[c] = col
	await get_tree().create_timer(_spd(DROP_T) + 0.12).timeout

# ------------------------------------------------------------------
func _flash_cells(remove: Array) -> void:
	for idx in remove:
		var c: int = idx / ROWS
		var r: int = idx % ROWS
		if r < cells[c].size():
			var tile: TextureRect = cells[c][r]
			if is_instance_valid(tile):
				tile.pivot_offset = Vector2(CELL / 2.0, CELL / 2.0)
				var tw := create_tween()
				tw.tween_property(tile, "scale", Vector2(1.18, 1.18), _spd(FLASH_T) * 0.4)
				tw.parallel().tween_property(tile, "modulate", Color(1.6, 1.6, 1.6), _spd(FLASH_T) * 0.4)
				tw.tween_property(tile, "scale", Vector2(1, 1), _spd(FLASH_T) * 0.3)
	await get_tree().create_timer(_spd(FLASH_T)).timeout

func _tumble(remove: Array, after: Array) -> void:
	var rem_by_col := {}
	for c in range(COLS):
		rem_by_col[c] = []
	for idx in remove:
		var c: int = idx / ROWS
		var r: int = idx % ROWS
		rem_by_col[c].append(r)
	for c in range(COLS):
		var removed: Array = rem_by_col[c]
		if removed.is_empty():
			continue
		var survivors: Array = []
		for r in range(ROWS):
			var tile: TextureRect = cells[c][r]
			if removed.has(r):
				var tf := create_tween()
				tf.tween_property(tile, "modulate:a", 0.0, _spd(0.14))
				tf.tween_callback(tile.queue_free)
			else:
				survivors.append(tile)
		var n_rem: int = removed.size()
		var new_tiles: Array = []
		for i in range(n_rem):
			var t := _make_tile(after[c][i])
			grid_root.add_child(t)
			t.position = _cell_pos(c, i - n_rem)
			new_tiles.append(t)
		var col_tiles: Array = new_tiles + survivors
		cells[c] = col_tiles
		for r in range(ROWS):
			var tile: TextureRect = col_tiles[r]
			var tw := create_tween()
			tw.tween_property(tile, "position", _cell_pos(c, r), _spd(DROP_T)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(_spd(DROP_T) + 0.05).timeout

# ------------------------------------------------------------------
func _on_spin_pressed() -> void:
	if spinning:
		return
	_do_spin()

func _on_turbo_pressed() -> void:
	_sfx("on")
	turbo = not turbo
	if turbo_btn is TextureButton and turbo_tex_on != null and turbo_tex_off != null:
		turbo_btn.texture_normal = turbo_tex_on if turbo else turbo_tex_off
	else:
		turbo_btn.modulate = Color("#e8c86a") if turbo else Color.WHITE

func _on_auto_pressed() -> void:
	_sfx("on")
	if autospin_left > 0:
		autospin_left = 0
		_update_auto_badge()
		return
	if spinning:
		return
	_mostra_auto_picker()

func _mostra_auto_picker() -> void:
	if auto_layer != null:
		return
	auto_layer = Control.new()
	auto_layer.size = Vector2(VW, VH)
	add_child(auto_layer)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.55)
	veil.size = Vector2(VW, VH)
	auto_layer.add_child(veil)
	var panel := Panel.new()
	panel.size = Vector2(360, 250)
	panel.position = Vector2(VW / 2.0 - 180, VH / 2.0 - 140)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.06, 0.18, 0.98)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.72, 0.58, 0.32, 0.9)
	panel.add_theme_stylebox_override("panel", sb)
	auto_layer.add_child(panel)
	var tit := Label.new()
	tit.text = T("auto_scegli")
	tit.position = Vector2(0, 18)
	tit.size = Vector2(360, 30)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 24)
	tit.add_theme_color_override("font_color", Color("#e8c86a"))
	panel.add_child(tit)
	var opzioni := [10, 25, 50, 100]
	for idx in range(opzioni.size()):
		var n: int = opzioni[idx]
		var bx := 30 + (idx % 2) * 170
		var byy := 66 + (idx / 2) * 84
		var b := Button.new()
		b.text = str(n)
		b.position = Vector2(bx, byy)
		b.size = Vector2(150, 70)
		b.focus_mode = Control.FOCUS_NONE
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color("#4a3a72")
		bsb.set_corner_radius_all(12)
		bsb.set_border_width_all(2)
		bsb.border_color = Color("#7a6aaa")
		b.add_theme_stylebox_override("normal", bsb)
		b.add_theme_color_override("font_color", Color("#fdf6e3"))
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(_start_auto.bind(n))
		panel.add_child(b)

func _chiudi_auto_picker() -> void:
	if auto_layer != null:
		auto_layer.queue_free()
		auto_layer = null

func _start_auto(n: int) -> void:
	_chiudi_auto_picker()
	autospin_left = n
	_update_auto_badge()
	if not spinning:
		_do_spin()

func _update_auto_badge() -> void:
	if auto_badge == null:
		return
	if autospin_left > 0:
		auto_badge.text = str(autospin_left)
		auto_badge.visible = true
	else:
		auto_badge.visible = false

func _apri_bet() -> void:
	_sfx("on")
	var livelli := [10.0, 20.0, 50.0, 100.0, 200.0]
	var i := livelli.find(bet)
	bet = livelli[(i + 1) % livelli.size()]
	Engine.set_meta("me_bet", bet)
	_update_hud()

func _do_spin() -> void:
	if spinning:
		return
	if balance < bet:
		return
	spinning = true
	balance -= bet
	lbl_win.text = ""
	_set_mult(1)
	_update_hud()
	_sfx("spin")

	var res: Dictionary = engine.play_spin(true)
	await _drop_in_grid(res["grid_start"])
	_sfx("drop")
	_pulse_scatters()
	await get_tree().create_timer(_spd(0.28)).timeout

	var spin_win := 0.0
	var steps: Array = res["steps"]
	if steps.size() > 1:
		_set_mago("cast")
	for k in range(1, steps.size()):
		var st: Dictionary = steps[k]
		_sfx("win_small")
		await _flash_cells(st["remove"])
		spin_win += st["win"]
		lbl_win.text = "%.2f" % (spin_win * bet)
		_set_mult(int(st["mult"]))
		_popup_win(st["win"] * bet)
		await get_tree().create_timer(_spd(0.34)).timeout
		var after: Array = steps[k + 1]["grid"] if k + 1 < steps.size() else res["grid_final"]
		_sfx("tumble")
		await _tumble(st["remove"], after)

	# i libri contano sulla griglia finale: pulsano li' (e se sono 4+ parte il bonus)
	_pulse_scatters()
	if res["trigger_fs"]:
		await get_tree().create_timer(_spd(0.9)).timeout
		var fw: float = await _play_freespins(res["n_scatter"])
		spin_win += fw

	if spin_win > 0.0:
		balance += spin_win * bet
		lbl_win.text = "%.2f" % (spin_win * bet)
		_sfx("count")
		if spin_win >= 15.0:
			_sfx("win_big")
			_set_mago("win")
			await get_tree().create_timer(_spd(0.8)).timeout
	_set_mago("idle")
	_set_mult(1)
	_update_hud()
	spinning = false

	if autospin_left > 0:
		autospin_left -= 1
		_update_auto_badge()
		await get_tree().create_timer(_spd(1.0)).timeout
		if autospin_left > 0 and not spinning:
			_do_spin()

func _play_freespins(n_scatter: int) -> float:
	var fr: Dictionary = engine.run_freespins(n_scatter, true)
	_sfx("fs_trigger")
	_play_music("music_bonus")
	_set_mago("win")
	var award: int = int(engine.FS_AWARD.get(min(n_scatter, 6), 10))
	await _fs_splash(T("fs_intro"), T("fs_giri") % award, _spd(2.2))
	_set_mago("idle")
	fs_pill.visible = true
	var tot_giri := award
	var gmult := 1
	_set_mult(1, true)
	var k := 0
	var fs_win := 0.0
	for sp in fr["spins"]:
		k += 1
		fs_counter.text = T("giro") % [k, tot_giri]
		var sp_steps: Array = sp["steps"]
		await _drop_in_grid(sp_steps[0]["grid"])
		_sfx("drop")
		await get_tree().create_timer(_spd(0.45)).timeout
		for kk in range(1, sp_steps.size()):
			var st: Dictionary = sp_steps[kk]
			_set_mago("cast")
			_sfx("win_small")
			await _flash_cells(st["remove"])
			fs_win += st["win"]
			lbl_win.text = "%.2f" % (fs_win * bet)
			_popup_win(st["win"] * bet)
			await get_tree().create_timer(_spd(0.3)).timeout
			var after: Array = sp_steps[kk + 1]["grid"] if kk + 1 < sp_steps.size() else sp["grid_final"]
			_sfx("tumble")
			await _tumble(st["remove"], after)
		_set_mago("idle")
		# le FIALE: mostrano il loro x N e volano sul badge, che si gonfia
		for v in sp["vials"]:
			await _vial_fly(int(v["idx"]), int(v["value"]))
			gmult += int(v["value"])
			_set_mult(gmult, true)
			await get_tree().create_timer(_spd(0.18)).timeout
		# ritrigger: +5 giri
		if sp["retrigger"]:
			tot_giri += engine.FS_RETRIGGER_ADD
			fs_counter.text = T("giro") % [k, tot_giri]
			_sfx("fs_trigger")
			_popup_text(T("retrigger") % engine.FS_RETRIGGER_ADD, Color("#a0f0ff"), 50)
			await get_tree().create_timer(_spd(1.0)).timeout
		await get_tree().create_timer(_spd(0.9)).timeout
	fs_pill.visible = false
	# uscita: totale del bonus
	_set_mago("win")
	_sfx("win_big")
	await _fs_splash(T("fs_vinto"), "%.2f" % (float(fr["total_win"]) * bet), _spd(2.6))
	_set_mago("idle")
	_set_mult(1)
	_play_music("music_base")
	return float(fr["total_win"])

# schermata a tutto schermo (ingresso / uscita free spin)
func _fs_splash(titolo: String, sotto: String, hold: float) -> void:
	var lay := Control.new()
	lay.size = Vector2(VW, VH)
	lay.z_index = 30
	add_child(lay)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.6)
	veil.size = Vector2(VW, VH)
	lay.add_child(veil)
	var t1 := Label.new()
	t1.text = titolo
	t1.size = Vector2(VW, 96)
	t1.position = Vector2(0, VH / 2.0 - 100)
	t1.pivot_offset = Vector2(VW / 2.0, 48)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 68)
	t1.add_theme_color_override("font_color", Color("#ffd24a"))
	t1.add_theme_color_override("font_outline_color", Color(0.2, 0.05, 0.0, 1.0))
	t1.add_theme_constant_override("outline_size", 12)
	t1.scale = Vector2(0.4, 0.4)
	lay.add_child(t1)
	var t2 := Label.new()
	t2.text = sotto
	t2.size = Vector2(VW, 70)
	t2.position = Vector2(0, VH / 2.0 + 6)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 46)
	t2.add_theme_color_override("font_color", Color("#fff3c8"))
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	t2.add_theme_constant_override("outline_size", 8)
	t2.modulate.a = 0.0
	lay.add_child(t2)
	var tw := create_tween()
	tw.tween_property(t1, "scale", Vector2(1.15, 1.15), _spd(0.35)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(t1, "scale", Vector2(1.0, 1.0), _spd(0.15))
	tw.parallel().tween_property(t2, "modulate:a", 1.0, _spd(0.3))
	await get_tree().create_timer(hold).timeout
	var tf := create_tween()
	tf.tween_property(lay, "modulate:a", 0.0, _spd(0.35))
	await tf.finished
	lay.queue_free()

# la fiala mostra il suo valore, pulsa, poi il numero vola sul badge del moltiplicatore
func _vial_fly(idx: int, value: int) -> void:
	var c: int = idx / ROWS
	var r: int = idx % ROWS
	if r >= cells[c].size():
		return
	var tile: TextureRect = cells[c][r]
	if not is_instance_valid(tile):
		return
	var num := Label.new()
	num.text = "×%d" % value
	num.size = Vector2(CELL, CELL)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 26)
	num.add_theme_color_override("font_color", Color("#3a2a08"))
	num.add_theme_color_override("font_outline_color", Color("#ffe9a0"))
	num.add_theme_constant_override("outline_size", 4)
	tile.add_child(num)
	_sfx("fiala")
	tile.pivot_offset = Vector2(CELL / 2.0, CELL / 2.0)
	var tw := create_tween()
	tw.tween_property(tile, "scale", Vector2(1.2, 1.2), _spd(0.18))
	tw.tween_property(tile, "scale", Vector2(1.0, 1.0), _spd(0.14))
	await tw.finished
	await get_tree().create_timer(_spd(0.28)).timeout
	var fly := Label.new()
	fly.text = "×%d" % value
	fly.size = Vector2(90, 40)
	fly.pivot_offset = Vector2(45, 20)
	fly.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fly.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fly.add_theme_font_size_override("font_size", 32)
	fly.add_theme_color_override("font_color", Color("#ffe27a"))
	fly.add_theme_color_override("font_outline_color", Color(0.2, 0.05, 0.0, 1.0))
	fly.add_theme_constant_override("outline_size", 8)
	fly.z_index = 25
	fly.position = grid_root.position + tile.position + Vector2(CELL / 2.0 - 45, CELL / 2.0 - 20)
	add_child(fly)
	var target: Vector2 = mult_badge.position + Vector2(38 - 45, 38 - 20)
	var t2 := create_tween()
	t2.tween_property(fly, "position", target, _spd(0.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t2.parallel().tween_property(fly, "scale", Vector2(0.6, 0.6), _spd(0.5))
	await t2.finished
	fly.queue_free()
	if is_instance_valid(num):
		num.queue_free()

# DEMO: forza i giri gratis (tasto F) - non tocca la matematica, e' solo un innesco
func _debug_freespins() -> void:
	if spinning:
		return
	spinning = true
	lbl_win.text = ""
	_set_mult(1)
	# griglia con 4 LIBRI, come succede davvero
	var g: Array = engine.new_grid(false)
	for c in range(COLS):
		for r in range(ROWS):
			if g[c][r] == engine.SCAT:
				g[c][r] = engine.L1
	for pos in [Vector2i(0, 1), Vector2i(2, 3), Vector2i(3, 0), Vector2i(5, 2)]:
		g[pos.x][pos.y] = engine.SCAT
	_sfx("spin")
	await _drop_in_grid(g)
	_sfx("drop")
	_pulse_scatters()
	await get_tree().create_timer(_spd(1.4)).timeout
	var fw: float = await _play_freespins(4)
	balance += fw * bet
	lbl_win.text = "%.2f" % (fw * bet)
	_update_hud()
	spinning = false

# ------------------------------------------------------------------
func _build_hud() -> void:
	# ---- barra inferiore: contatori + tasti, sotto la cornice (mai sopra) ----
	var bar := Panel.new()
	bar.position = Vector2(0, 578)
	bar.size = Vector2(752, 70)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.05, 0.03, 0.10, 0.80)
	bsb.corner_radius_top_right = 24
	bsb.border_width_top = 2
	bsb.border_color = Color(0.78, 0.62, 0.34, 0.9)
	bar.add_theme_stylebox_override("panel", bsb)
	add_child(bar)

	_cap(T("saldo"), 16, 584)
	lbl_balance = _mk_label("1000", 16, 600, 140, 34, Color("#ffe9b0"))
	lbl_balance.add_theme_font_size_override("font_size", 26)
	_outline(lbl_balance)

	bet_chip = _btn_img("chip_bet", 158, 584, 58, 58, T("bet"), Color("#3b3168"))
	bet_chip.pressed.connect(_apri_bet)
	if bet_chip is TextureButton:
		bet_num = Label.new()
		bet_num.text = "%.0f" % bet
		bet_num.size = Vector2(58, 58)
		bet_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bet_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bet_num.add_theme_font_size_override("font_size", 21)
		bet_num.add_theme_color_override("font_color", Color("#3a2a08"))
		bet_chip.add_child(bet_num)
	auto_button = _btn_img("tasto_auto", 224, 584, 58, 58, T("auto"), Color("#4a3a72"))
	auto_button.pressed.connect(_on_auto_pressed)
	auto_badge = Label.new()
	auto_badge.size = Vector2(58, 58)
	auto_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auto_badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	auto_badge.add_theme_font_size_override("font_size", 17)
	auto_badge.add_theme_color_override("font_color", Color("#ffe9b0"))
	_outline(auto_badge)
	auto_badge.visible = false
	auto_button.add_child(auto_badge)
	turbo_btn = _btn_img("tasto_turbo_off", 290, 584, 58, 58, T("turbo"), Color("#4a3a72"))
	turbo_btn.pressed.connect(_on_turbo_pressed)
	if ResourceLoader.exists("res://assets/tasto_turbo_off.png"):
		turbo_tex_off = load("res://assets/tasto_turbo_off.png")
	if ResourceLoader.exists("res://assets/tasto_turbo_on.png"):
		turbo_tex_on = load("res://assets/tasto_turbo_on.png")

	_cap(T("vincita"), 372, 584)
	lbl_win = _mk_label("", 372, 598, 200, 36, Color("#ffdf5a"))
	lbl_win.add_theme_font_size_override("font_size", 28)
	_outline(lbl_win)

	_cap(T("puntata"), 566, 584)
	lbl_bet = _mk_label("10", 566, 600, 80, 34, Color("#cbb8ee"))
	lbl_bet.add_theme_font_size_override("font_size", 24)
	_outline(lbl_bet)

	spin_hitbox = _btn_img("tasto_spin", 664, 574, 80, 80, T("spin"), Color("#caa23a"))
	if spin_hitbox is Button:
		spin_hitbox.add_theme_font_size_override("font_size", 28)
	spin_hitbox.pressed.connect(_on_spin_pressed)

	_build_mult_badge()

	# tasto MENU (torna alla schermata iniziale), in alto a sinistra
	var mb := _btn_img("tasto_menu", 14, 12, 150, 40, T("menu"), Color("#3a3258"))
	if mb is TextureButton:
		var ml := Label.new()
		ml.text = T("menu")
		ml.size = Vector2(150, 40)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ml.add_theme_font_size_override("font_size", 17)
		ml.add_theme_color_override("font_color", Color("#fff3d0"))
		_outline(ml)
		ml.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mb.add_child(ml)
	mb.pressed.connect(func() -> void:
		if not spinning:
			_sfx("on")
			get_tree().change_scene_to_file("res://menu.tscn"))

	fs_banner = _mk_label("", GRID_X, GRID_Y + GRID_H / 2.0 - 24, GRID_W, 48, Color("#ffd24a"))
	fs_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fs_banner.add_theme_font_size_override("font_size", 44)
	_outline(fs_banner)
	fs_banner.visible = false
	fs_pill = Panel.new()
	fs_pill.size = Vector2(230, 44)
	fs_pill.position = Vector2(GRID_X + GRID_W / 2.0 - 115, GRID_Y - 96)
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.08, 0.04, 0.16, 0.94)
	fsb.set_corner_radius_all(22)
	fsb.set_border_width_all(2)
	fsb.border_color = Color(0.85, 0.68, 0.36)
	fsb.shadow_size = 8
	fsb.shadow_color = Color(0, 0, 0, 0.55)
	fs_pill.add_theme_stylebox_override("panel", fsb)
	fs_pill.z_index = 8
	fs_pill.visible = false
	add_child(fs_pill)
	fs_counter = Label.new()
	fs_counter.size = Vector2(230, 44)
	fs_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fs_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fs_counter.add_theme_font_size_override("font_size", 24)
	fs_counter.add_theme_color_override("font_color", Color("#ffe9b0"))
	_outline(fs_counter)
	fs_pill.add_child(fs_counter)

func _cap(t: String, x: float, y: float) -> void:
	var l := _mk_label(t, x, y, 140, 16, Color("#b8a8d8"))
	l.add_theme_font_size_override("font_size", 13)
	_outline(l)

# --- moltiplicatore: badge sopra la cornice (immagine mult_badge.png se c'e') ---
func _build_mult_badge() -> void:
	mult_badge = Control.new()
	mult_badge.size = Vector2(76, 76)
	mult_badge.position = Vector2(GRID_X + GRID_W - 64, GRID_Y - 112)
	mult_badge.pivot_offset = Vector2(38, 38)
	mult_badge.z_index = 8
	add_child(mult_badge)
	if ResourceLoader.exists("res://assets/mult_badge.png"):
		var t := TextureRect.new()
		t.texture = load("res://assets/mult_badge.png")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.size = Vector2(76, 76)
		mult_badge.add_child(t)
	else:
		var p := Panel.new()
		p.size = Vector2(76, 76)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.05, 0.24, 0.96)
		sb.set_corner_radius_all(38)
		sb.set_border_width_all(3)
		sb.border_color = Color(0.88, 0.70, 0.36)
		sb.shadow_size = 10
		sb.shadow_color = Color(0.6, 0.3, 1.0, 0.55)
		p.add_theme_stylebox_override("panel", sb)
		mult_badge.add_child(p)
	mult_lbl = Label.new()
	mult_lbl.size = Vector2(76, 76)
	mult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mult_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mult_lbl.add_theme_font_size_override("font_size", 27)
	mult_lbl.add_theme_color_override("font_color", Color("#ffe27a"))
	_outline(mult_lbl)
	mult_badge.add_child(mult_lbl)
	mult_badge.visible = false

func _set_mult(m: int, force_show := false) -> void:
	if mult_badge == null:
		return
	if m <= 1 and not force_show:
		mult_badge.visible = false
		mult_last = 1
		return
	mult_lbl.text = "×%d" % m
	mult_badge.visible = true
	if m == mult_last:
		return
	mult_last = m
	if m > 1:
		_sfx("mult")
	mult_badge.scale = Vector2(0.55, 0.55)
	var tw := create_tween()
	tw.tween_property(mult_badge, "scale", Vector2(1.3, 1.3), _spd(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mult_badge, "scale", Vector2(1.0, 1.0), _spd(0.14))

# --- popup vincita: esce ogni volta che i simboli si collegano ---
func _popup_win(credits: float) -> void:
	_popup_text("+%.2f" % credits, Color("#ffe27a"), 46)

func _popup_text(testo: String, col: Color, fsize := 46) -> void:
	var l := Label.new()
	l.text = testo
	l.size = Vector2(420, 70)
	l.position = Vector2(GRID_X + GRID_W / 2.0 - 210, GRID_Y + GRID_H / 2.0 - 35)
	l.pivot_offset = Vector2(210, 35)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.05, 0.0, 1.0))
	l.add_theme_constant_override("outline_size", 9)
	l.z_index = 20
	l.scale = Vector2(0.5, 0.5)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.18, 1.18), _spd(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), _spd(0.1))
	tw.tween_interval(_spd(0.32))
	tw.tween_property(l, "position:y", l.position.y - 56.0, _spd(0.4))
	tw.parallel().tween_property(l, "modulate:a", 0.0, _spd(0.4))
	tw.tween_callback(l.queue_free)

# --- i LIBRI (scatter) pulsano quando ne atterrano 2 o 3: "ci sei quasi" ---
func _pulse_scatters() -> void:
	var tiles: Array = []
	for c in range(COLS):
		for r in range(ROWS):
			if r < cells[c].size():
				var t: TextureRect = cells[c][r]
				if is_instance_valid(t) and t.has_meta("sym") and int(t.get_meta("sym")) == engine.SCAT:
					tiles.append(t)
	if tiles.size() < 2:
		return
	_sfx("scatter")
	if tiles.size() >= 3:
		_sfx("anticipation")
	for t in tiles:
		t.pivot_offset = Vector2(CELL / 2.0, CELL / 2.0)
		var tw := create_tween().set_loops(2)
		tw.tween_property(t, "scale", Vector2(1.16, 1.16), _spd(0.22))
		tw.parallel().tween_property(t, "modulate", Color(1.6, 1.45, 1.0), _spd(0.22))
		tw.tween_property(t, "scale", Vector2(1, 1), _spd(0.22))
		tw.parallel().tween_property(t, "modulate", Color.WHITE, _spd(0.22))

func _mk_label(t: String, x: float, y: float, w: float, h: float, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = Vector2(x, y)
	l.size = Vector2(w, h)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _btn_img(nome: String, x: float, y: float, w: float, h: float, riserva: String, col: Color) -> BaseButton:
	var p := "res://assets/%s.png" % nome
	if not ResourceLoader.exists(p):
		return _mk_button(riserva, x, y, w, h, col)
	var b := TextureButton.new()
	b.texture_normal = load(p)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = Vector2(w, h)
	b.position = Vector2(x, y)
	b.pivot_offset = Vector2(w / 2.0, h / 2.0)
	b.focus_mode = Control.FOCUS_NONE
	b.button_down.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2(0.94, 0.94))
	b.button_up.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2.ONE)
	add_child(b)
	return b

func _mk_button(t: String, x: float, y: float, w: float, h: float, col: Color) -> Button:
	var b := Button.new()
	b.text = t
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = col.lightened(0.4)
	sb.shadow_size = 5
	sb.shadow_color = Color(0, 0, 0, 0.45)
	var sbh := sb.duplicate()
	sbh.bg_color = col.lightened(0.18)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_color_override("font_color", Color("#fdf6e3"))
	b.add_theme_font_size_override("font_size", 22)
	add_child(b)
	return b

func _gemma(pos: Vector2, col: Color) -> void:
	var s := 13.0
	var back := Polygon2D.new()
	back.polygon = PackedVector2Array([Vector2(0, -s - 3), Vector2(s + 3, 0), Vector2(0, s + 3), Vector2(-s - 3, 0)])
	back.color = Color(0.80, 0.64, 0.35)
	back.position = pos
	grid_root.add_child(back)
	var g := Polygon2D.new()
	g.polygon = PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)])
	g.color = col
	g.position = pos
	grid_root.add_child(g)

# ------------------------------ AUDIO ------------------------------
func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = MUSIC_DB
	add_child(music_player)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		sfx_players.append(p)

func _audio_path(nome: String) -> String:
	for e in ["mp3", "ogg", "wav"]:
		var p := "res://assets/audio/%s.%s" % [nome, e]
		if ResourceLoader.exists(p):
			return p
	return ""

func _load_audio(nome: String, loop: bool) -> AudioStream:
	if audio_cache.has(nome):
		return audio_cache[nome]
	var p := _audio_path(nome)
	if p == "":
		audio_cache[nome] = null
		return null
	var s: AudioStream = load(p)
	if loop:
		if s is AudioStreamMP3:
			(s as AudioStreamMP3).loop = true
		elif s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		elif s is AudioStreamWAV:
			(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio_cache[nome] = s
	return s

func _play_music(nome: String) -> void:
	if music_player == null:
		return
	var s := _load_audio(nome, true)
	if s == null:
		return
	if music_player.stream == s and music_player.playing:
		return
	music_player.stream = s
	music_player.play()

func _sfx(nome: String) -> void:
	var s := _load_audio("sfx_" + nome, false)
	if s == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = s
			p.play()
			return
	sfx_players[0].stream = s
	sfx_players[0].play()

func _outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	l.add_theme_constant_override("outline_size", 5)

func _update_hud() -> void:
	lbl_balance.text = "%.2f" % balance
	lbl_bet.text = "%.0f" % bet
	if bet_num != null:
		bet_num.text = "%.0f" % bet

# ------------------------------------------------------------------
func _build_mago() -> void:
	if mago_idle_static == null:
		return
	mago = TextureRect.new()
	mago.texture = mago_idle_static
	mago.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mago.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(mago)
	_mago_box(false)

# pose alte (idle) vs pose quadrate (cast/win): stessa altezza, piedi allineati a destra
func _mago_box(square: bool) -> void:
	if square:
		mago.size = Vector2(MAGO_H, MAGO_H)
		mago.position = Vector2(VW - MAGO_RIGHT - MAGO_H, VH - MAGO_H)
	else:
		mago.size = Vector2(MAGO_W, MAGO_H)
		mago.position = Vector2(VW - MAGO_RIGHT - MAGO_W, VH - MAGO_H)

func _set_mago(state: String) -> void:
	if mago == null:
		return
	mago_state = state
	if state == "win" and mago_win != null:
		mago.texture = mago_win
		_mago_box(true)
	elif state == "cast" and mago_cast != null:
		mago.texture = mago_cast
		_mago_box(true)
		_sfx("cast")
	elif state == "idle" and mago_idle_static != null:
		mago.texture = mago_idle_static
		_mago_box(false)
		idle_playing = false   # il tempo gia' accumulato resta: la gif parte appena e' fermo da 4 s

func _process(delta: float) -> void:
	if mago == null or mago_state != "idle" or mago_idle.size() < 3:
		return
	if idle_playing:
		# la "gif": ciclo delle scintille (frame 1-2-3 a 6 fps) per ~2,5 s
		idle_play_t += delta
		if idle_play_t >= 2.5:
			idle_playing = false
			mago.texture = mago_idle[0]
		else:
			mago.texture = mago_idle[int(idle_play_t * 6.0) % 3]
	else:
		# fermo per 4 s, poi riparte la gif
		idle_gap += delta
		if idle_gap >= 4.0:
			idle_gap = 0.0
			idle_playing = true
			idle_play_t = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_spin_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not spinning:
			get_tree().change_scene_to_file("res://menu.tscn")
	elif DEBUG_FS_KEY and event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_debug_freespins()
