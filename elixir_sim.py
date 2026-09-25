#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# elixir_sim.py - Simulatore/certificatore matematico di MIDNIGHT ELIXIR (gioco 3)
# Modello: pay-anywhere (8+ ovunque) su griglia 6x5 + cascata (tumble) +
# free spin con moltiplicatore ACCUMULANTE (stile Gates of Olympus). NIENTE linee.
# Alta volatilita': il free spin porta il peso. La logica qui e' quella che
# verra' portata IDENTICA in GDScript.
#
# Uso:  python3 elixir_sim.py [n_spin]

import sys, random, math
from collections import defaultdict

# ============================ CONFIG (tarabile) ============================
COLS, ROWS = 6, 5
CELLS = COLS * ROWS
TOTAL_BET = 1.0
MAX_WIN_X = 5000

L1, L2, L3, L4 = 0, 1, 2, 3          # bassi:  fungo, radice, cristallo, occhio
H1, H2, H3, H4 = 4, 5, 6, 7          # alti:   rossa, viola, verde, blu
WILD, SCAT, MULT = 8, 9, 10          # pietra, libro, fiala
PAY_SYMBOLS = (L1, L2, L3, L4, H1, H2, H3, H4)
NAMES = {L1:"fungo",L2:"radice",L3:"cristallo",L4:"occhio",
         H1:"rossa",H2:"viola",H3:"verde",H4:"blu",
         WILD:"wild",SCAT:"scatter",MULT:"mult"}

# ALTA VOLATILITA' (profilo Gates): scatter raro -> FS rari ma grossi
W_BASE = {L1:24, L2:24, L3:22, L4:20, H1:14, H2:12, H3:10, H4:8, WILD:4.0, SCAT:2.7}
W_FS   = {L1:24, L2:24, L3:22, L4:20, H1:14, H2:12, H3:10, H4:8, WILD:4.0, SCAT:1.8, MULT:4.5}

# paytable (x puntata) per scaglione: 8-9 / 10-11 / 12-14 / 15-29 / 30
TIERS = [(8,9),(10,11),(12,14),(15,29),(30,30)]
PAYTABLE = {
    L1: [0.20, 0.5, 1.2, 5,  15],
    L2: [0.20, 0.5, 1.2, 5,  15],
    L3: [0.30, 0.7, 1.5, 6,  18],
    L4: [0.40, 0.9, 2.0, 8,  25],
    H1: [0.70, 1.6, 5.0, 20, 80],
    H2: [0.90, 2.0, 6.0, 26, 110],
    H3: [1.30, 3.0, 9.0, 36, 160],
    H4: [2.50, 6.0, 16.0,60, 300],
}
# INTERRUTTORE RTP: cambia solo questo per versionare.
#   0.6578 -> 94,80% (serie/social)   |   0.6696 -> 96,50% (operatore)
PAY_SCALE = 0.6578

CASCADE_LADDER = [1, 1, 2, 2, 3, 4, 5, 6]   # base: gentile, non deve dominare

FS_AWARD = {4:10, 5:15, 6:20}
FS_RETRIGGER_MIN = 3
FS_RETRIGGER_ADD = 5
MULT_VALUES  = [2, 3, 4, 5, 6, 8, 10, 15, 20, 25, 50, 100]
MULT_WEIGHTS = [22, 18, 13, 10, 8, 7, 5, 4, 3, 3, 1.5, 0.6]

# ======================= PRECALCOLI (per velocita') =======================
def _cum_lists(weight_map):
    pop = list(weight_map.keys()); cw = []; a = 0.0
    for s in pop:
        a += weight_map[s]; cw.append(a)
    return pop, cw
B_POP, B_CW = _cum_lists(W_BASE)
F_POP, F_CW = _cum_lists(W_FS)

TIDX = [-1]*(CELLS+1)                 # indice scaglione per conteggio; -1 = sotto 8
for _c in range(CELLS+1):
    for i,(lo,hi) in enumerate(TIERS):
        if lo <= _c <= hi: TIDX[_c] = i; break
    if _c > TIERS[-1][1]: TIDX[_c] = len(TIERS)-1

PT = {s: [v*PAY_SCALE for v in PAYTABLE[s]] for s in PAY_SYMBOLS}

def tier_pay(sym, count):
    if count < 8: return 0.0
    return PT[sym][TIDX[count]]

_M_POP = MULT_VALUES
_M_CW = []
_a = 0.0
for _w in MULT_WEIGHTS:
    _a += _w; _M_CW.append(_a)
def draw_mult_value():
    return random.choices(_M_POP, cum_weights=_M_CW, k=1)[0]

# ============================ MOTORE ============================
def new_grid(fs):
    pop, cw = (F_POP, F_CW) if fs else (B_POP, B_CW)
    flat = random.choices(pop, cum_weights=cw, k=CELLS)
    return [flat[c*ROWS:(c+1)*ROWS] for c in range(COLS)]

def evaluate(grid):
    """Pay-anywhere + wild al gruppo migliore. Fast-path se non c'e' vincita.
    Ritorna (win_units, set_indici_da_togliere | None)."""
    counts = [0]*11
    for col in grid:
        for s in col:
            counts[s] += 1
    nw = counts[WILD]
    best_c = 0
    for s in PAY_SYMBOLS:
        cs = counts[s]
        if cs > best_c: best_c = cs
    if best_c + nw < 8:
        return 0.0, None

    base_pay = {}
    for s in PAY_SYMBOLS:
        base_pay[s] = tier_pay(s, counts[s])
    best_g = -1; best_delta = 0.0
    if nw > 0:
        for s in PAY_SYMBOLS:
            if counts[s] == 0: continue
            d = tier_pay(s, counts[s] + nw) - base_pay[s]
            if d > best_delta:
                best_delta = d; best_g = s

    total = 0.0; winners = set()
    for s in PAY_SYMBOLS:
        p = base_pay[s]
        if s == best_g and nw > 0:
            p = tier_pay(s, counts[s] + nw)
        if p > 0.0:
            total += p; winners.add(s)
    if total <= 0.0:
        return 0.0, None

    remove_wild = (best_g in winners) and nw > 0
    remove = set()
    for c in range(COLS):
        col = grid[c]; base = c*ROWS
        for r in range(ROWS):
            s = col[r]
            if s in winners or (remove_wild and s == WILD):
                remove.add(base + r)
    return total, remove

def apply_tumble(grid, remove, fs):
    pop, cw = (F_POP, F_CW) if fs else (B_POP, B_CW)
    for c in range(COLS):
        col = grid[c]; base = c*ROWS
        kept = [col[r] for r in range(ROWS) if (base + r) not in remove]
        missing = ROWS - len(kept)
        if missing:
            grid[c] = random.choices(pop, cum_weights=cw, k=missing) + kept

def play_spin(fs, g_mult):
    grid = new_grid(fs)
    n_scat = 0
    for col in grid:
        for s in col:
            if s == SCAT: n_scat += 1
    win = 0.0; cascade = 0
    while True:
        pay, remove = evaluate(grid)
        if pay <= 0.0: break
        cascade += 1
        if fs:
            mult = g_mult
        else:
            li = cascade if cascade < len(CASCADE_LADDER) else len(CASCADE_LADDER)
            mult = CASCADE_LADDER[li-1]
        win += pay * mult
        apply_tumble(grid, remove, fs)
    delta_g = 0
    if fs:
        for col in grid:
            for s in col:
                if s == MULT: delta_g += draw_mult_value()
    cap = MAX_WIN_X * TOTAL_BET
    if win > cap: win = cap
    return win, n_scat, delta_g

def run_freespins(n_scatter):
    fs_left = FS_AWARD[min(n_scatter, 6)]
    g_mult = 1; tot = 0.0; giri = 0; max_g = 1; safety = 0
    while fs_left > 0 and safety < 3000:
        safety += 1; fs_left -= 1; giri += 1
        win, ns, delta_g = play_spin(True, g_mult)
        tot += win
        if delta_g > 0:
            g_mult += delta_g
            if g_mult > max_g: max_g = g_mult
        if ns >= FS_RETRIGGER_MIN:
            fs_left += FS_RETRIGGER_ADD
    cap = MAX_WIN_X * TOTAL_BET
    if tot > cap: tot = cap
    return tot, giri, max_g

# ============================ CERTIFICAZIONE ============================
def certifica(n):
    random.seed(20260922)
    base_tot = 0.0; fs_tot = 0.0
    n_fs = 0; giri_fs = 0; fs_max_g = 1
    hit = 0; max_spin = 0.0
    sum_x = 0.0; sum_x2 = 0.0
    n_ge_100 = 0; n_ge_500 = 0; n_ge_1000 = 0
    win_dist = defaultdict(int)
    order = ["0","0-1","1-2","2-5","5-10","10-20","20-50","50-100","100-500","500+"]

    for i in range(n):
        win, n_scat, _ = play_spin(False, 1)
        base_tot += win
        spin_win = win
        if n_scat >= 4:
            fw, g, mg = run_freespins(n_scat)
            fs_tot += fw; n_fs += 1; giri_fs += g
            if mg > fs_max_g: fs_max_g = mg
            spin_win += fw
        if spin_win > 0: hit += 1
        if spin_win > max_spin: max_spin = spin_win
        x = spin_win / TOTAL_BET
        sum_x += x; sum_x2 += x*x
        if x >= 100: n_ge_100 += 1
        if x >= 500: n_ge_500 += 1
        if x >= 1000: n_ge_1000 += 1
        if   x == 0: b = "0"
        elif x < 1:  b = "0-1"
        elif x < 2:  b = "1-2"
        elif x < 5:  b = "2-5"
        elif x < 10: b = "5-10"
        elif x < 20: b = "10-20"
        elif x < 50: b = "20-50"
        elif x < 100:b = "50-100"
        elif x < 500:b = "100-500"
        else:        b = "500+"
        win_dist[b] += 1

    mean = sum_x / n
    var = max(sum_x2 / n - mean*mean, 0.0)
    se = math.sqrt(var / n)
    ci = 1.96 * se * 100
    rtp = mean * 100

    print("="*60)
    print(f"MIDNIGHT ELIXIR - certificazione  ({n:,} spin)".replace(",", "."))
    print(f"PAY_SCALE = {PAY_SCALE}")
    print("="*60)
    print(f"RTP TOTALE ............ {rtp:6.2f}%   (IC 95%: +/-{ci:.2f})")
    print(f"  gioco base .......... {base_tot/n*100:6.2f}%")
    print(f"  free spin ........... {fs_tot/n*100:6.2f}%   ({fs_tot/(base_tot+fs_tot)*100:.1f}% dell'RTP)")
    print("-"*60)
    print(f"Hit frequency ......... {hit/n*100:6.2f}%  (1 vincita ogni {n/max(hit,1):.2f} spin)")
    print(f"Free spin ............. 1 ogni {n/max(n_fs,1):.0f} spin  ({n_fs} episodi)")
    if n_fs:
        print(f"  giri medi / episodio {giri_fs/n_fs:6.2f}")
        print(f"  vincita media FS .... {fs_tot/n_fs/TOTAL_BET:6.1f}x")
        print(f"  molt. globale max ... x{fs_max_g}")
    print(f"Vincita max singolo spin {max_spin/TOTAL_BET:8.1f}x   (tetto {MAX_WIN_X}x)")
    print(f"  >= 100x ............. 1 ogni {n/max(n_ge_100,1):,.0f} spin".replace(",", "."))
    print(f"  >= 500x ............. 1 ogni {n/max(n_ge_500,1):,.0f} spin".replace(",", "."))
    print(f"  >= 1000x ............ 1 ogni {n/max(n_ge_1000,1):,.0f} spin".replace(",", "."))
    print("-"*60)
    print("Distribuzione vincite (x puntata):")
    for b in order:
        print(f"  {b:>8} : {win_dist.get(b,0)/n*100:6.2f}%")
    print("="*60)
    return rtp, ci

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1_000_000
    certifica(n)
