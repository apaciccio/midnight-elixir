#!/usr/bin/env python3
# audio.py - MIDNIGHT ELIXIR: mette i suoni generati al posto giusto, col nome giusto
# (gemello di quello di Heist/Case, con la lista suoni della cascata)
#
# Uso:
#   python3 ~/midnight-elixir/audio.py --gioco elixir ~/Downloads/audio_elixir/
#   python3 ~/midnight-elixir/audio.py --lista elixir
#
# Basta che il NOME del file scaricato contenga la parola chiave
# (es. "menu.mp3" -> music_menu.mp3; "tumble.wav" -> sfx_tumble.wav).
# Formati: mp3, ogg, wav. Destinazione: ~/midnight-elixir/assets/audio
import os, sys, shutil, re

GIOCHI = {"elixir": os.path.expanduser("~/midnight-elixir/assets/audio")}

# nome file (senza estensione) -> parole chiave accettate. Le piu' specifiche PRIMA.
SUONI = [
    ("music_menu",       ["music_menu", "menu", "candlelit"]),
    ("music_tension",    ["music_tension", "tension", "tensione", "suspense_music"]),
    ("music_bonus",      ["music_bonus", "bonus_music", "bonusmusic", "freespin", "free_spins", "musica_bonus"]),
    ("music_base",       ["music_base", "base", "gioco", "gameplay", "sparkle"]),
    ("sfx_fs_trigger",   ["fs_trigger", "fstrigger", "free_spins_trigger", "trigger"]),
    ("sfx_anticipation", ["anticipation", "suspense", "attesa", "riser"]),
    ("sfx_scatter",      ["scatter", "libro", "spellbook", "book"]),
    ("sfx_fiala",        ["fiala", "vial", "potion_land"]),
    ("sfx_mult",         ["mult", "moltiplicatore", "multiplier", "powerup", "power_up"]),
    ("sfx_win_big",      ["win_big", "winbig", "big_win", "bigwin", "grande_vincita"]),
    ("sfx_win_small",    ["win_small", "winsmall", "small_win", "piccola_vincita"]),
    ("sfx_tumble",       ["tumble", "cascata", "cascade", "dissolve"]),
    ("sfx_drop",         ["drop", "land", "atterr", "clink"]),
    ("sfx_spin",         ["spin"]),
    ("sfx_count",        ["count", "conteggio", "contatore", "coins"]),
    ("sfx_cast",         ["cast", "spell", "incantesimo"]),
    ("sfx_on",           ["sfx_on", "click", "tasto", "button"]),
    ("sfx_whoosh",       ["whoosh", "swoosh"]),
    ("sfx_nome",         ["nome", "title", "reveal", "stamp"]),
]

def normalizza(nome):
    b = os.path.splitext(os.path.basename(nome))[0].lower()
    return re.sub(r"[^a-z0-9]+", "_", b)

def abbina(nomefile):
    b = normalizza(nomefile)
    for n, _ in SUONI:
        if b == n: return n
    for n, chiavi in SUONI:
        for k in chiavi:
            if k in b: return n
    return None

if __name__ == "__main__":
    a = sys.argv[1:]
    if "--lista" in a:
        print("File attesi per Elixir (nome -> parole chiave accettate):")
        for n, k in SUONI: print("  %-18s <- %s" % (n, ", ".join(k)))
        sys.exit(0)
    if "--gioco" not in a:
        print("Uso: python3 audio.py --gioco elixir CARTELLA_O_FILE [--no-sovrascrivi]"); sys.exit(1)
    gioco = a[a.index("--gioco") + 1]
    if gioco not in GIOCHI: print("gioco sconosciuto:", gioco); sys.exit(1)
    sovr = "--no-sovrascrivi" not in a
    src = [x for x in a if x not in ("--gioco", gioco, "--no-sovrascrivi")]
    files = []
    for s in src:
        s = os.path.expanduser(s)
        if os.path.isdir(s):
            files += [os.path.join(s, f) for f in sorted(os.listdir(s)) if f.lower().endswith((".mp3", ".ogg", ".wav"))]
        elif os.path.isfile(s): files.append(s)
    dest = GIOCHI[gioco]; os.makedirs(dest, exist_ok=True)
    fatti = {}; ignorati = []
    for f in files:
        n = abbina(f)
        if n is None: ignorati.append(os.path.basename(f)); continue
        ext = os.path.splitext(f)[1].lower()
        out = os.path.join(dest, n + ext)
        for e in (".mp3", ".ogg", ".wav"):
            if e != ext and os.path.exists(os.path.join(dest, n + e)): os.remove(os.path.join(dest, n + e))
        if os.path.exists(out) and not sovr: print("  gia' presente, salto:", n + ext); continue
        shutil.copy2(f, out); fatti[n] = os.path.basename(f); print("  ok  %-18s <- %s" % (n + ext, os.path.basename(f)))
    if ignorati:
        print("\nNON riconosciuti (rinominali con una parola chiave):"); [print("   ", i) for i in ignorati]
    mancanti = [n for n, _ in SUONI if not any(os.path.exists(os.path.join(dest, n + e)) for e in (".mp3", ".ogg", ".wav"))]
    print("\nInstallati ora: %d. Mancano ancora in %s:" % (len(fatti), dest))
    for m in mancanti: print("   ", m)
    if not mancanti: print("    (nessuno: audio completo)")
