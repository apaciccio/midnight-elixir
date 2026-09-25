# MIDNIGHT ELIXIR v1.0 — nota di chiusura (25 set 2026)

Terza slot della serie Midnight. 6×5 pay-anywhere + cascata, tema alchimista. Godot 4.6.3.
Progetto: ~/midnight-elixir (vetrina: ~/Desktop/slot/midnight-elixir → link).

## Stato: CHIUSA (v1.0)
- Motore: slot_engine.gd v1.0, RTP 94,8% (PAY_SCALE 0,5499; 0,5597 = 96,5% operatore).
  Alta volatilità profilo Gates: base ~52% / free spin ~48%, bonus ~1 ogni 307 spin,
  libri contati sulla griglia FINALE (come Sweet Bonanza/Gates), tetto 5.000×.
  Certificato in Python (elixir_sim.py + cert_fast.py) e verificato in Godot (parità).
- Gioco: main.gd v1.0 (cascata, popup vincita, badge moltiplicatore, free spin a
  schermo con ingresso/contatore/fiale/ritrigger/uscita, autoplay con scelta giri,
  turbo, bet 10/20/50/100/200, 7 lingue, audio completo), menu.gd (targhe illustrate,
  lingua, legenda con immagini e vincite per puntata), lang.gd (it en es de fr pt ru).
- Collaudo: raffica 60 s di click veri sotto Xvfb → 0 errori, 0 spin bloccati.
- Tasto F (forza free spin) SPENTO: DEBUG_FS_KEY=false in main.gd.

## Comandi
- Build Mac:  bash ~/midnight-elixir/build_mac.sh   (log in ~/me_log.txt)
- Audio:      python3 ~/midnight-elixir/audio.py --gioco elixir CARTELLA
- Certifica:  python3 ~/midnight-elixir/cert_fast.py 6000000 150000

## Aperto (opzionale, non bloccante)
- music_tension / music_bonus: ci sono i placeholder (derivati); sostituibili con audio.py.
- Targhe illustrate del menu anche per Heist e Case (stesso aggancio: tasto_menu.png).
- Volatilità: se il base drena troppo, spostare lo split verso 60/40 e ricertificare.
- Google Play quando arriva la partita IVA (come Heist/Case).
