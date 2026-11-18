# ================================================================
# menu.gd - MIDNIGHT ELIXIR - schermata iniziale (stile Heist/Case)
# fix iPhone (nov 2026): scelta lingua con tasto + elenco di tasti normali
#   (niente tendina di sistema: dopo il cambio lingua i tasti non rispondevano)
# lingue via lang.gd, tasti oro, legenda con immagini e vincite x puntata
# ================================================================
extends Node2D

const VW := 1152.0
const VH := 648.0
const ENG := preload("res://slot_engine.gd")
const LNG := preload("res://lang.gd")
const RIGA_W := 840.0

var mago: TextureRect = null
var mago_idle: Array = []
var idle_gap := 0.0
var idle_playing := false
var idle_play_t := 0.0
var music_player: AudioStreamPlayer = null

func _lang() -> String:
	return LNG.attiva()

func T(k: String) -> String:
	return LNG.t(k, _lang())

func _ready() -> void:
	_musica_menu()
	_build()
	set_process(true)

# ricostruisce tutto (serve al cambio lingua); la musica resta
func _build() -> void:
	for c in get_children():
		if not (c is AudioStreamPlayer):
			c.queue_free()
	mago = null
	mago_idle = []

	# sfondo specchiato (calderone a sinistra) + velo leggero
	if ResourceLoader.exists("res://assets/sfondo.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/sfondo.png")
		bg.flip_h = true
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = Vector2(VW, VH)
		add_child(bg)
		var veil := ColorRect.new()
		veil.color = Color(0.04, 0.02, 0.09, 0.24)
		veil.size = Vector2(VW, VH)
		add_child(veil)
	else:
		var bg := ColorRect.new()
		bg.color = Color("#1a1030")
		bg.size = Vector2(VW, VH)
		add_child(bg)

	# logo grande in alto al centro
	if ResourceLoader.exists("res://assets/logo.png"):
		var logo := TextureRect.new()
		logo.texture = load("res://assets/logo.png")
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.size = Vector2(560, 300)
		logo.position = Vector2(VW / 2.0 - 300, 6)
		add_child(logo)

	# mago a destra, fermo e ogni tanto animato
	for i in [1, 2, 3]:
		var pp := "res://assets/alchimista_idle_%d.png" % i
		if ResourceLoader.exists(pp):
			mago_idle.append(load(pp))
	var base_tex: Texture2D = null
	if mago_idle.size() >= 1:
		base_tex = mago_idle[0]
	elif ResourceLoader.exists("res://assets/alchimista_idle.png"):
		base_tex = load("res://assets/alchimista_idle.png")
	if base_tex != null:
		mago = TextureRect.new()
		mago.texture = base_tex
		mago.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mago.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mago.size = Vector2(400, 588)
		mago.position = Vector2(VW - 410, VH - 588)
		mago.modulate = Color(1.1, 1.1, 1.1)
		add_child(mago)

	# tasti: targa illustrata (tasto_menu.png, ~4:1) se c'e', altrimenti oro stile Case
	if ResourceLoader.exists("res://assets/tasto_menu.png"):
		var bx := VW / 2.0 - 175
		_gold_button(T("gioca"), bx, 300, 350, 92, 30, true).pressed.connect(_on_gioca)
		_gold_button(T("come"), bx, 400, 350, 92, 22, false).pressed.connect(_on_legend)
		_gold_button(T("esci"), bx, 500, 350, 92, 22, false).pressed.connect(_on_esci)
	else:
		var bx := VW / 2.0 - 160
		_gold_button(T("gioca"), bx, 312, 320, 64, 30, true).pressed.connect(_on_gioca)
		_gold_button(T("come"), bx, 392, 320, 56, 22, false).pressed.connect(_on_legend)
		_gold_button(T("esci"), bx, 464, 320, 52, 22, false).pressed.connect(_on_esci)

	# lingua: tasto + elenco fatto di normali Button (niente tendina di sistema:
	# su iPhone la tendina OptionButton bloccava i tocchi dopo il cambio lingua)
	_crea_scelta_lingua()

# ---- scelta lingua (v. fix iPhone) ----------------------------------------
# Tasto in alto a sinistra che apre un elenco di 7 tasti normali. Toccando
# una lingua si chiude l'elenco e, un frame dopo, il menu si ricostruisce.
# Tocco fuori dall'elenco = chiude. Nessuna finestra/popup di sistema.
var _rifacendo := false

func _stile_lingua(colore: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colore
	sb.border_color = Color(0.96, 0.72, 0.25, 0.8)
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 12; sb.content_margin_right = 12
	return sb

func _crea_scelta_lingua() -> void:
	# il tasto vecchio e' in coda di cancellazione: gli cambio nome per liberare "TastoLingua"
	var vecchio := get_node_or_null("TastoLingua")
	if vecchio != null:
		vecchio.name = "TastoLingua_vecchio"
	var tasto := Button.new()
	tasto.name = "TastoLingua"
	tasto.text = LNG.NOMI[_lang()]
	tasto.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tasto.focus_mode = Control.FOCUS_NONE
	tasto.add_theme_font_size_override("font_size", 15)
	tasto.add_theme_stylebox_override("normal", _stile_lingua(Color(0.05, 0.06, 0.1, 0.85)))
	tasto.add_theme_stylebox_override("hover", _stile_lingua(Color(0.1, 0.12, 0.2, 0.95)))
	tasto.add_theme_stylebox_override("pressed", _stile_lingua(Color(0.15, 0.17, 0.28, 0.95)))
	add_child(tasto)
	tasto.position = Vector2(20, 20)
	tasto.size = Vector2(150, 38)
	# freccina disegnata (non dipende dal font)
	var fr := Polygon2D.new()
	fr.polygon = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(5, 6)])
	fr.color = Color(0.96, 0.72, 0.25)
	fr.position = Vector2(128, 16)
	tasto.add_child(fr)
	tasto.pressed.connect(_apri_lingue)

func _apri_lingue() -> void:
	if _rifacendo: return
	var aperto := get_node_or_null("SceltaLingua")
	if aperto != null:
		aperto.name = "SceltaLingua_chiusa"
		aperto.queue_free()
		return
	var velo := Control.new()
	velo.name = "SceltaLingua"
	velo.size = Vector2(VW, VH)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	velo.z_index = 100
	velo.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.is_pressed():
			velo.name = "SceltaLingua_chiusa"
			velo.queue_free())
	var pan := Panel.new()
	pan.add_theme_stylebox_override("panel", _stile_lingua(Color(0.05, 0.06, 0.1, 0.96)))
	velo.add_child(pan)
	pan.position = Vector2(20, 62)
	pan.size = Vector2(150, LNG.LINGUE.size() * 36 + 10)
	for i in LNG.LINGUE.size():
		var code: String = LNG.LINGUE[i]
		var b := Button.new()
		b.text = LNG.NOMI[code]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.flat = code != _lang()
		b.add_theme_font_size_override("font_size", 15)
		pan.add_child(b)
		b.position = Vector2(5, 5 + i * 36)
		b.size = Vector2(140, 34)
		b.pressed.connect(_scegli_lingua.bind(code))
	add_child(velo)

func _scegli_lingua(code: String) -> void:
	if _rifacendo: return
	_rifacendo = true
	Engine.set_meta("mh_lang", code)
	var aperto := get_node_or_null("SceltaLingua")
	if aperto != null:
		aperto.name = "SceltaLingua_chiusa"
		aperto.queue_free()
	await get_tree().process_frame
	_build()
	_rifacendo = false

func _gold_button(text: String, x: float, y: float, w: float, h: float, fsize: int, gold: bool = true) -> BaseButton:
	# tasto ILLUSTRATO se c'e' assets/tasto_menu.png (targa vuota: il testo lo scrive il codice)
	if ResourceLoader.exists("res://assets/tasto_menu.png"):
		var tb := TextureButton.new()
		tb.texture_normal = load("res://assets/tasto_menu.png")
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tb.focus_mode = Control.FOCUS_NONE
		tb.modulate = Color(1, 1, 1) if gold else Color(0.82, 0.78, 0.95)
		add_child(tb)
		tb.position = Vector2(x, y)
		tb.size = Vector2(w, h)
		tb.pivot_offset = Vector2(w / 2.0, h / 2.0)
		var lb := Label.new()
		lb.text = text
		lb.size = Vector2(w, h)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb.add_theme_font_size_override("font_size", fsize)
		lb.add_theme_color_override("font_color", Color("#2a1c05") if gold else Color("#fff3d0"))
		lb.add_theme_color_override("font_outline_color", Color("#ffe9a0") if gold else Color(0, 0, 0, 0.9))
		lb.add_theme_constant_override("outline_size", 4)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tb.add_child(lb)
		tb.button_down.connect(func() -> void: tb.scale = Vector2(0.96, 0.96))
		tb.button_up.connect(func() -> void: tb.scale = Vector2.ONE)
		return tb
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fsize)
	var sb := StyleBoxFlat.new()
	if gold:
		sb.bg_color = Color("#e3a93c")
		b.add_theme_color_override("font_color", Color("#2a1c05"))
	else:
		sb.bg_color = Color("#3a3258")
		b.add_theme_color_override("font_color", Color("#ffffff"))
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color("#ffe89a") if gold else Color("#9a8ac0")
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	b.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate()
	sh.bg_color = Color("#ffc85a") if gold else Color("#4c4470")
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	add_child(b)
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	return b

func _on_gioca() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_esci() -> void:
	get_tree().quit()

# ------------------------------ LEGENDA ------------------------------
func _icona_bb(file: String, dim: int = 44) -> String:
	var p := "res://assets/symbols/%s.png" % file
	if ResourceLoader.exists(p):
		return "[img=%d]%s[/img]  " % [dim, p]
	return ""

func _rtl(vb: VBoxContainer, bb: String, fsize: int = 16) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", fsize)
	r.add_theme_font_size_override("bold_font_size", fsize)
	r.custom_minimum_size = Vector2(RIGA_W, 0)
	vb.add_child(r)
	r.text = bb
	return r

func _sezione(vb: VBoxContainer, testo: String) -> void:
	_rtl(vb, "\n[color=#f5b73f]%s[/color]" % testo, 22)

func _on_legend() -> void:
	if has_node("LegendPanel"):
		return
	var bet: float = float(Engine.get_meta("me_bet")) if Engine.has_meta("me_bet") else 10.0

	var root := ColorRect.new()
	root.name = "LegendPanel"
	add_child(root)
	root.color = Color(0, 0, 0, 0.8)
	root.size = Vector2(VW, VH)

	var PW := 920.0
	var PH := 616.0
	var panel := Panel.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.04, 0.11, 1.0)
	psb.border_color = Color("#f5b73f")
	psb.set_border_width_all(3)
	psb.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", psb)
	root.add_child(panel)
	panel.position = Vector2((VW - PW) / 2.0, (VH - PH) / 2.0)
	panel.size = Vector2(PW, PH)

	var title := Label.new()
	title.text = T("titolo_regole")
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color("#f5b73f")
	panel.add_child(title)
	title.position = Vector2(34, 14)
	title.size = Vector2(PW - 68, 34)

	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	sc.position = Vector2(34, 56)
	sc.size = Vector2(PW - 68, PH - 132)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(RIGA_W, 0)
	sc.add_child(vb)

	_rtl(vb, T("scopo"))

	# ----- TABELLA VINCITE: immagine + quante ne devono cadere + vincita con la puntata -----
	_sezione(vb, T("sez_paytable"))
	_rtl(vb, "[color=#c8c8c8]%s[/color]" % (T("pt_nota") % int(bet)), 14)
	# riga puntate: clicchi e la tabella si ricalcola
	var riga_bet := HBoxContainer.new()
	riga_bet.add_theme_constant_override("separation", 10)
	vb.add_child(riga_bet)
	var lp := Label.new()
	lp.text = T("puntata") + ":"
	lp.add_theme_font_size_override("font_size", 17)
	lp.add_theme_color_override("font_color", Color("#f5b73f"))
	riga_bet.add_child(lp)
	for lv in [10, 20, 50, 100, 200]:
		var bb := Button.new()
		bb.text = str(lv)
		bb.focus_mode = Control.FOCUS_NONE
		bb.custom_minimum_size = Vector2(66, 34)
		bb.add_theme_font_size_override("font_size", 17)
		var ssb := StyleBoxFlat.new()
		ssb.bg_color = Color("#e3a93c") if int(bet) == lv else Color("#3a3258")
		ssb.set_corner_radius_all(10)
		ssb.set_border_width_all(2)
		ssb.border_color = Color("#ffe89a") if int(bet) == lv else Color("#9a8ac0")
		bb.add_theme_stylebox_override("normal", ssb)
		bb.add_theme_stylebox_override("hover", ssb)
		bb.add_theme_stylebox_override("pressed", ssb)
		bb.add_theme_color_override("font_color", Color("#2a1c05") if int(bet) == lv else Color("#ffffff"))
		bb.pressed.connect(func() -> void:
			Engine.set_meta("me_bet", float(lv))
			root.name = "LegendPanelOld"
			root.queue_free()
			call_deferred("_on_legend"))
		riga_bet.add_child(bb)
	var ordine := [ENG.H4, ENG.H3, ENG.H2, ENG.H1, ENG.L4, ENG.L3, ENG.L2, ENG.L1]
	for sym in ordine:
		var pt: Array = ENG.PAYTABLE[sym]
		var v := []
		for i in range(5):
			v.append(float(pt[i]) * ENG.PAY_SCALE * bet)
		var riga := _icona_bb(ENG.FILE_SIMBOLI[sym], 46)
		riga += "[color=#ffd991]8-9: %.2f    10-11: %.2f    12-14: %.2f    15-29: %.2f    30: %.2f[/color]" % [v[0], v[1], v[2], v[3], v[4]]
		_rtl(vb, riga, 17)

	# ----- I BONUS -----
	_sezione(vb, T("sez_bonus"))
	_rtl(vb, T("b_cascata"))
	_rtl(vb, _icona_bb("scatter") + T("b_scatter"))
	_rtl(vb, T("b_fsmult"))
	_rtl(vb, _icona_bb("mult") + T("b_fiala"))
	_rtl(vb, _icona_bb("wild") + T("b_wild"))
	_rtl(vb, "[color=#ffd991]" + T("b_max") + "[/color]")

	# ----- COMANDI -----
	_sezione(vb, T("sez_comandi"))
	_rtl(vb, T("comandi"), 15)

	var close := _gold_button(T("chiudi"), 0, 0, 180, 46, 20, true)
	remove_child(close)
	panel.add_child(close)
	close.position = Vector2((PW - 180) / 2.0, PH - 62)
	close.pressed.connect(func() -> void: root.queue_free())

# ------------------------------ MUSICA ------------------------------
func _musica_menu() -> void:
	var p := ""
	for e in ["mp3", "ogg", "wav"]:
		var c := "res://assets/audio/music_menu.%s" % e
		if ResourceLoader.exists(c):
			p = c
			break
	if p == "":
		return
	var s: AudioStream = load(p)
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	elif s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player = AudioStreamPlayer.new()
	music_player.stream = s
	music_player.volume_db = -9.0
	add_child(music_player)
	music_player.play()

# ------------------------------ MAGO ------------------------------
func _process(delta: float) -> void:
	if mago == null or mago_idle.size() < 3:
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
