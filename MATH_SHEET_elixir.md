# MIDNIGHT ELIXIR — Math Sheet (bozza certificata, 22 set 2026)

Slot **6×5 pay-anywhere + cascata (tumble)**, alta volatilità, tema alchimista.
Terza slot della serie *Midnight*. Modello e matematica **nuovi** (non è un riskin).

Questo documento è insieme la **specifica del motore** (da cui si scrive il GDScript,
identico numero per numero) e la **scheda per aggregatori/operatori**.

---

## 1. Struttura

- Griglia **6 colonne × 5 righe = 30 celle**.
- **Pay-anywhere**: si vince con **8+ simboli uguali ovunque** sulla griglia
  (non su linea). Scaglioni di conteggio: **8-9 / 10-11 / 12-14 / 15-29 / 30**.
- **Cascata (tumble)**: i simboli vincenti spariscono, quelli sopra scendono,
  nuovi simboli cadono dall'alto; se si forma un'altra vincita si ripaga.
  Avanti finché non cadono più vincite.
- Ogni cella è estratta **in modo indipendente** dai pesi qui sotto (i.i.d.).
- **Tetto vincita: 5.000×** la puntata, per spin e per episodio di free spin.

## 2. Simboli (cartella assets/symbols)

| Ruolo motore | File | Tipo |
|---|---|---|
| L1 fungo, L2 radice, L3 cristallo, L4 occhio | *_.png | bassi (4) |
| H1 rossa, H2 viola, H3 verde, H4 blu | pozione_*.png | alti (4) |
| WILD | wild.png | Pietra Filosofale (sostituto) |
| SCATTER | scatter.png | Libro (trigger free spin) |
| MULT | mult.png | Fiala moltiplicatore (**solo free spin**) |

- **WILD**: sostituisce le pozioni. In valutazione, **tutti i wild presenti si
  assegnano al gruppo dove aumentano di più la vincita** (non contano per ogni
  simbolo). Vengono rimossi con la vincita.
- **SCATTER**: non paga, non entra nella cascata; conta solo per i free spin.
- **MULT**: compare solo nei free spin; porta un valore che si somma al
  moltiplicatore globale (vedi §4).

## 3. Pesi per cella

| Simbolo | Peso base | Peso free spin |
|---|---|---|
| L1 fungo | 24 | 24 |
| L2 radice | 24 | 24 |
| L3 cristallo | 22 | 22 |
| L4 occhio | 20 | 20 |
| H1 rossa | 14 | 14 |
| H2 viola | 12 | 12 |
| H3 verde | 10 | 10 |
| H4 blu | 8 | 8 |
| WILD | 4,0 | 4,0 |
| SCATTER | 2,7 | 1,8 |
| MULT | — | 4,5 |

`p(scatter per cella) = 2,7 / 140,7 = 0,01919` (base).

## 4. Moltiplicatori

- **Gioco base — scala cascata** (per vincita nello spin, si azzera ogni spin):
  `[1, 1, 2, 2, 3, 4, 5, 6]` (dalla 8ª cascata in poi resta ×6).
- **Free spin — moltiplicatore globale ACCUMULANTE**: parte da ×1 e **non si
  azzera tra un giro e l'altro**. Ogni **fiala MULT** che atterra somma il suo
  valore al moltiplicatore globale, che moltiplica tutte le vincite successive
  dell'episodio (stile Gates of Olympus).
- **Valori fiala MULT** (solo FS): `2,3,4,5,6,8,10,15,20,25,50,100`
  con pesi `22,18,13,10,8,7,5,4,3,3,1,5,0,6`.

## 5. Free spin

- Trigger: **4 / 5 / 6+ scatter** sul drop iniziale → **10 / 15 / 20 giri**.
- **Ritrigger**: 3+ scatter durante i free spin → **+5 giri**.
- Frequenza di trigger (esatta, binomiale): **1 ogni 401 spin**.
  - P(4) = 2,246e-3 · P(5) = 2,285e-4 · P(≥6) = 1,995e-5.

## 6. Paytable

Valori = paytable di progetto × `PAY_SCALE` (interruttore RTP, §8).
Effettivi alla versione **94,8%** (`PAY_SCALE 0,6578`), in **× puntata totale**:

| Simbolo | 8-9 | 10-11 | 12-14 | 15-29 | 30 |
|---|---|---|---|---|---|
| L1 fungo | 0,13 | 0,33 | 0,79 | 3,29 | 9,87 |
| L2 radice | 0,13 | 0,33 | 0,79 | 3,29 | 9,87 |
| L3 cristallo | 0,20 | 0,46 | 0,99 | 3,95 | 11,84 |
| L4 occhio | 0,26 | 0,59 | 1,32 | 5,26 | 16,45 |
| H1 rossa | 0,46 | 1,05 | 3,29 | 13,16 | 52,62 |
| H2 viola | 0,59 | 1,32 | 3,95 | 17,10 | 72,36 |
| H3 verde | 0,86 | 1,97 | 5,92 | 23,68 | 105,25 |
| H4 blu | 1,64 | 3,95 | 10,52 | 39,47 | 197,34 |

*(nel motore si memorizza la paytable di progetto + la costante `PAY_SCALE`;
questi sono i valori risultanti da mostrare al giocatore)*

## 7. Certificazione (varianza ridotta: trigger esatto + FS simulati)

Versione **94,8%** (`PAY_SCALE 0,6578`):

| Metrica | Valore |
|---|---|
| **RTP totale** | **94,80% ± 0,19** (IC 95%) |
| di cui gioco base | 54,8% (57,8% dell'RTP) |
| di cui free spin | 40,0% (42,2% dell'RTP) |
| Hit frequency | ~62% (molte vincite piccole, tipico dei tumble) |
| Trigger free spin | 1 ogni 401 spin (esatto) |
| Giri medi / episodio | ~10,9 |
| Valore medio FS 10 giri | ~140× |
| Valore medio FS 15 giri | ~323× |
| Valore medio FS 20 giri | ~580× |
| Moltiplicatore globale max osservato | ~×657 |
| Vincite ≥ 100× | ~1 ogni 700 spin |
| Vincite ≥ 500× | ~1 ogni 11.000 spin |
| Vincite ≥ 1000× | ~1 ogni 125.000 spin |
| Tetto | 5.000× |

Profilo: **alta volatilità**, free spin protagonista — allineato ai benchmark
di genere (Gates of Olympus / Sweet Bonanza / Sugar Rush).

> Nota: l'IC ±0,19 è più largo dei ±0,12 di Case perché il moltiplicatore
> accumulante alza la varianza. La firma della certificazione finale sul Mac
> girerà comunque un campione grande per la coda profonda (≥1000×).

## 8. Interruttore RTP (versioni per operatore)

Stesso motore certificato, si cambia **solo** `PAY_SCALE`:

| Versione | PAY_SCALE | RTP |
|---|---|---|
| Serie / social | 0,6578 | 94,80% |
| Operatore | 0,6696 | 96,50% |

Altre soglie (92%, 95,5%…) si ricavano linearmente: `PAY_SCALE = 0,6578 × RTP_target / 94,80`.

## 9. Da fare (prossimi passi)

1. **Motore GDScript** (`slot_engine.gd` nuovo per Elixir): griglia 6×5,
   valutazione pay-anywhere + wild al gruppo migliore, cascata, moltiplicatori
   base/FS, fiale MULT. Collaudo con la raffica (0 errori) prima della consegna.
2. Scocca riusata da Heist/Case: HUD, tasti illustrati, menu, lingue, audio,
   `build_mac.sh`, pipeline `verde.py`/`audio.py`.
3. Asset su Gemini (tu): 4 alti + wild + scatter + alchimista_idle per lo stile,
   poi il resto.
4. Firma certificazione finale + math sheet PDF impaginato.
