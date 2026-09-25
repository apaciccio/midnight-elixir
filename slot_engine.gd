# ================================================================
# slot_engine.gd - MOTORE v1.0 (MIDNIGHT ELIXIR - gioco 3)
# Slot 6x5 PAY-ANYWHERE (8+ ovunque) + CASCATA (tumble). NIENTE linee.
# Motore e matematica NUOVI (non e' un riskin di Heist/Case).
#
# Port FEDELE del modello certificato in Python (elixir_sim.py / cert_fast.py):
#   v0.2 - scatter contati sulla griglia FINALE (come Sweet Bonanza/Gates)
#   RTP 94.8% +/- 0.7  (PAY_SCALE 0.5499) - alta volatilita', profilo Gates
#   base ~49% (52%) | free spin ~46% (48%)
#   trigger FS ~1/307 (simulato) | tetto 5000x
# Interruttore RTP: cambia solo PAY_SCALE (0.5499 = 94.8% ; 0.5597 = 96.5%).
# DA QUI IN POI LA MATEMATICA NON SI TOCCA SENZA RICERTIFICARE.
# ================================================================
class_name SlotEngine
extends RefCounted

const COLS := 6
const ROWS := 5
const CELLS := COLS * ROWS
const TOTAL_BET := 1.0
const MAX_WIN_X := 5000

# --- id simboli ---
const L1 := 0   # fungo
const L2 := 1   # radice
const L3 := 2   # cristallo
const L4 := 3   # occhio
const H1 := 4   # pozione rossa
const H2 := 5   # pozione viola
const H3 := 6   # pozione verde
const H4 := 7   # pozione blu
const WILD := 8   # pietra filosofale
const SCAT := 9   # libro (scatter)
const MULT := 10  # fiala moltiplicatore (solo free spin)

const PAY_SYMBOLS := [L1, L2, L3, L4, H1, H2, H3, H4]
const NAMES := {
	L1: "fungo", L2: "radice", L3: "cristallo", L4: "occhio",
	H1: "pozione_rossa", H2: "pozione_viola", H3: "pozione_verde", H4: "pozione_blu",
	WILD: "wild", SCAT: "scatter", MULT: "mult",
}
const FILE_SIMBOLI := {   # nomi file in assets/symbols/
	L1: "fungo", L2: "radice", L3: "cristallo", L4: "occhio",
	H1: "pozione_rossa", H2: "pozione_viola", H3: "pozione_verde", H4: "pozione_blu",
	WILD: "wild", SCAT: "scatter", MULT: "mult",
}

# --- pesi per cella (i.i.d.). [peso_base, peso_freespin] ---
const WEIGHTS := {
	L1:   [24.0, 24.0],
	L2:   [24.0, 24.0],
	L3:   [22.0, 22.0],
	L4:   [20.0, 20.0],
	H1:   [14.0, 14.0],
	H2:   [12.0, 12.0],
	H3:   [10.0, 10.0],
	H4:   [8.0,  8.0],
	WILD: [4.0,  4.0],
	SCAT: [2.0,  1.3],
	MULT: [0.0,  4.5],   # la fiala esiste solo nei free spin
}

# --- paytable (x puntata) per scaglione: 8-9 / 10-11 / 12-14 / 15-29 / 30 ---
const PAYTABLE := {
	L1: [0.20, 0.5, 1.2,  5,  15],
	L2: [0.20, 0.5, 1.2,  5,  15],
	L3: [0.30, 0.7, 1.5,  6,  18],
	L4: [0.40, 0.9, 2.0,  8,  25],
	H1: [0.70, 1.6, 5.0,  20, 80],
	H2: [0.90, 2.0, 6.0,  26, 110],
	H3: [1.30, 3.0, 9.0,  36, 160],
	H4: [2.50, 6.0, 16.0, 60, 300],
}
# INTERRUTTORE RTP (0.6578 -> 94.8% ; 0.6696 -> 96.5%)
const PAY_SCALE := 0.5499

# soglie di conteggio (indice scaglione)
const TIER_MIN := [8, 10, 12, 15, 30]

# moltiplicatore cascata nel gioco base (1a vincita = indice 0)
const CASCADE_LADDER := [1, 1, 2, 2, 3, 4, 5, 6]

# free spin
const FS_AWARD := {4: 10, 5: 15, 6: 20}
const FS_RETRIGGER_MIN := 3
const FS_RETRIGGER_ADD := 5
const MULT_VALUES  := [2, 3, 4, 5, 6, 8, 10, 15, 20, 25, 50, 100]
const MULT_WEIGHTS := [22.0, 18.0, 13.0, 10.0, 8.0, 7.0, 5.0, 4.0, 3.0, 3.0, 1.5, 0.6]

var rng := RandomNumberGenerator.new()

# precalcoli per l'estrazione pesata
var _pop_base: Array = []
var _cum_base: Array = []
var _tot_base := 0.0
var _pop_fs: Array = []
var _cum_fs: Array = []
var _tot_fs := 0.0
var _mult_cum: Array = []
var _mult_tot := 0.0

func _init() -> void:
	rng.randomize()
	var a := 0.0
	for s in WEIGHTS.keys():
		var w: float = WEIGHTS[s][0]
		if w > 0.0:
			a += w; _pop_base.append(s); _cum_base.append(a)
	_tot_base = a
	a = 0.0
	for s in WEIGHTS.keys():
		var w: float = WEIGHTS[s][1]
		if w > 0.0:
			a += w; _pop_fs.append(s); _cum_fs.append(a)
	_tot_fs = a
	a = 0.0
	for w in MULT_WEIGHTS:
		a += w; _mult_cum.append(a)
	_mult_tot = a

# --------------------------- estrazioni ---------------------------
func _pick(fs: bool) -> int:
	var cum: Array = _cum_fs if fs else _cum_base
	var pop: Array = _pop_fs if fs else _pop_base
	var tot: float = _tot_fs if fs else _tot_base
	var r := rng.randf() * tot
	for i in range(cum.size()):
		if r <= cum[i]:
			return pop[i]
	return pop[pop.size() - 1]

func _pick_mult_value() -> int:
	var r := rng.randf() * _mult_tot
	for i in range(_mult_cum.size()):
		if r <= _mult_cum[i]:
			return MULT_VALUES[i]
	return MULT_VALUES[MULT_VALUES.size() - 1]

func _tier_pay(sym: int, count: int) -> float:
	if count < 8:
		return 0.0
	var idx := 0
	for i in range(TIER_MIN.size()):
		if count >= TIER_MIN[i]:
			idx = i
	return float(PAYTABLE[sym][idx]) * PAY_SCALE

# --------------------------- griglia ---------------------------
func new_grid(fs: bool) -> Array:
	var grid: Array = []
	for c in range(COLS):
		var col: Array = []
		for r in range(ROWS):
			col.append(_pick(fs))
		grid.append(col)
	return grid

func count_scatter(grid: Array) -> int:
	var n := 0
	for c in range(COLS):
		for r in range(ROWS):
			if grid[c][r] == SCAT:
				n += 1
	return n

# --------------------------- valutazione ---------------------------
# Ritorna {"win": float, "remove": Array[int]} dove remove sono indici c*ROWS+r.
func evaluate(grid: Array) -> Dictionary:
	var counts := {}
	for s in PAY_SYMBOLS:
		counts[s] = 0
	var nw := 0
	for c in range(COLS):
		for r in range(ROWS):
			var s: int = grid[c][r]
			if s == WILD:
				nw += 1
			elif counts.has(s):
				counts[s] += 1

	# fast-path: nessun gruppo puo' raggiungere 8
	var best_c := 0
	for s in PAY_SYMBOLS:
		if counts[s] > best_c:
			best_c = counts[s]
	if best_c + nw < 8:
		return {"win": 0.0, "remove": []}

	var base_pay := {}
	for s in PAY_SYMBOLS:
		base_pay[s] = _tier_pay(s, counts[s])

	# tutti i wild al gruppo dove il delta e' massimo
	var best_g := -1
	var best_delta := 0.0
	if nw > 0:
		for s in PAY_SYMBOLS:
			if counts[s] == 0:
				continue
			var d: float = _tier_pay(s, counts[s] + nw) - base_pay[s]
			if d > best_delta:
				best_delta = d; best_g = s

	var total := 0.0
	var winners := {}
	for s in PAY_SYMBOLS:
		var p: float = base_pay[s]
		if s == best_g and nw > 0:
			p = _tier_pay(s, counts[s] + nw)
		if p > 0.0:
			total += p
			winners[s] = true
	if total <= 0.0:
		return {"win": 0.0, "remove": []}

	var remove_wild := winners.has(best_g) and nw > 0
	var remove: Array = []
	for c in range(COLS):
		for r in range(ROWS):
			var s: int = grid[c][r]
			if winners.has(s) or (remove_wild and s == WILD):
				remove.append(c * ROWS + r)
	return {"win": total, "remove": remove}

# toglie le celle vincenti, fa scendere, riempie dall'alto
func apply_tumble(grid: Array, remove: Array, fs: bool) -> void:
	var rem := {}
	for idx in remove:
		rem[idx] = true
	for c in range(COLS):
		var kept: Array = []
		for r in range(ROWS):
			if not rem.has(c * ROWS + r):
				kept.append(grid[c][r])
		var missing := ROWS - kept.size()
		var newtop: Array = []
		for i in range(missing):
			newtop.append(_pick(fs))
		grid[c] = newtop + kept

# --------------------------- spin ---------------------------
# collect=false: solo valore (per simulazione/certificazione).
# collect=true: include "steps" per l'animazione.
func play_spin(collect := false) -> Dictionary:
	var grid := new_grid(false)
	var steps: Array = []
	if collect:
		steps.append({"grid": _copy(grid), "remove": [], "win": 0.0, "mult": 0})
	var win := 0.0
	var cascade := 0
	while true:
		var ev := evaluate(grid)
		if ev["win"] <= 0.0:
			break
		cascade += 1
		var li: int = cascade if cascade < CASCADE_LADDER.size() else CASCADE_LADDER.size()
		var mult: int = CASCADE_LADDER[li - 1]
		var cw: float = ev["win"] * mult
		win += cw
		if collect:
			steps.append({"grid": _copy(grid), "remove": ev["remove"], "win": cw, "mult": mult})
		apply_tumble(grid, ev["remove"], false)
	# scatter contati sulla griglia FINALE (i libri restano e ne cadono di nuovi)
	var n_scat := count_scatter(grid)
	var cap := MAX_WIN_X * TOTAL_BET
	if win > cap:
		win = cap
	var res := {
		"win": win,
		"n_scatter": n_scat,
		"trigger_fs": n_scat >= 4,
		"fs_award": int(FS_AWARD.get(min(n_scat, 6), 0)),
	}
	if collect:
		res["grid_start"] = steps[0]["grid"] if steps.size() > 0 else grid
		res["steps"] = steps
		res["grid_final"] = grid
	return res

# un singolo giro DENTRO i free spin, con moltiplicatore globale g_mult
func _fs_spin(g_mult: int, collect: bool) -> Dictionary:
	var grid := new_grid(true)
	var steps: Array = []
	if collect:
		steps.append({"grid": _copy(grid), "remove": [], "win": 0.0, "mult": g_mult})
	var win := 0.0
	while true:
		var ev := evaluate(grid)
		if ev["win"] <= 0.0:
			break
		var cw: float = ev["win"] * g_mult
		win += cw
		if collect:
			steps.append({"grid": _copy(grid), "remove": ev["remove"], "win": cw, "mult": g_mult})
		apply_tumble(grid, ev["remove"], true)
	# fiale MULT rimaste sulla griglia finale -> sommano al moltiplicatore globale
	# (registro anche il valore di OGNI fiala per l'animazione: stessi tiri, stessa matematica)
	var delta_g := 0
	var vials: Array = []
	for c in range(COLS):
		for r in range(ROWS):
			if grid[c][r] == MULT:
				var v := _pick_mult_value()
				delta_g += v
				vials.append({"idx": c * ROWS + r, "value": v})
	var cap := MAX_WIN_X * TOTAL_BET
	if win > cap:
		win = cap
	var n_scat := count_scatter(grid)   # ritrigger sulla griglia FINALE
	var res := {"win": win, "delta_g": delta_g, "n_scatter": n_scat}
	if collect:
		res["steps"] = steps
		res["vials"] = vials
		res["grid_final"] = grid
	return res

func run_freespins(n_scatter: int, collect := false) -> Dictionary:
	var fs_left: int = int(FS_AWARD.get(min(n_scatter, 6), 10))
	var g_mult := 1
	var tot := 0.0
	var giri := 0
	var g_max := 1
	var spins: Array = []
	var safety := 0
	while fs_left > 0 and safety < 3000:
		safety += 1; fs_left -= 1; giri += 1
		var sp := _fs_spin(g_mult, collect)
		tot += sp["win"]
		if sp["delta_g"] > 0:
			g_mult += sp["delta_g"]
			if g_mult > g_max:
				g_max = g_mult
		if sp["n_scatter"] >= FS_RETRIGGER_MIN:
			fs_left += FS_RETRIGGER_ADD
		if collect:
			spins.append({
				"win": sp["win"], "g_mult": g_mult, "steps": sp.get("steps", []),
				"vials": sp.get("vials", []), "grid_final": sp.get("grid_final", []),
				"retrigger": sp["n_scatter"] >= FS_RETRIGGER_MIN,
			})
	var cap := MAX_WIN_X * TOTAL_BET
	if tot > cap:
		tot = cap
	var res := {"total_win": tot, "giri": giri, "g_mult_max": g_max}
	if collect:
		res["spins"] = spins
	return res

func _copy(grid: Array) -> Array:
	var g: Array = []
	for c in range(COLS):
		g.append(grid[c].duplicate())
	return g
