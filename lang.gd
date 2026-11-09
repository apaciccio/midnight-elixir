# lang.gd - LINGUE DI MIDNIGHT ELIXIR v1.0 (tema alchimista; base: Midnight Case lang v1.0)
# UN SOLO FILE per tutti i testi del gioco (main e menu), in 7 lingue:
# it, en, es, de, fr, pt, ru. La lingua si RILEVA dal dispositivo
# (OS.get_locale_language); se non e' supportata si usa l'inglese.
# Il testo mancante ricade su inglese, poi italiano.
class_name Lingue

const LINGUE := ["it", "en", "es", "de", "fr", "pt", "ru"]
const NOMI := {"it": "Italiano", "en": "English", "es": "Español", "de": "Deutsch", "fr": "Français", "pt": "Português", "ru": "Русский"}

static func rileva() -> String:
	var l := OS.get_locale_language()
	return l if LINGUE.has(l) else "en"

static func attiva() -> String:
	if Engine.has_meta("mh_lang"):
		return Engine.get_meta("mh_lang")
	return rileva()

static func t(k: String, lang: String) -> String:
	if not TESTI.has(k):
		return k
	var v: Dictionary = TESTI[k]
	if v.has(lang): return v[lang]
	if v.has("en"): return v["en"]
	return v["it"]

const TESTI := {
	# ---- HUD ----
	"saldo":   {"it": "SALDO", "en": "BALANCE", "es": "SALDO", "de": "GUTHABEN", "fr": "SOLDE", "pt": "SALDO", "ru": "БАЛАНС"},
	"puntata": {"it": "PUNTATA", "en": "BET", "es": "APUESTA", "de": "EINSATZ", "fr": "MISE", "pt": "APOSTA", "ru": "СТАВКА"},
	"vincita": {"it": "VINCITA", "en": "WIN", "es": "GANANCIA", "de": "GEWINN", "fr": "GAIN", "pt": "GANHO", "ru": "ВЫИГРЫШ"},
	"bet":     {"it": "BET", "en": "BET", "es": "APUESTA", "de": "EINSATZ", "fr": "MISE", "pt": "APOSTA", "ru": "СТАВКА"},
	"auto":    {"it": "AUTO", "en": "AUTO", "es": "AUTO", "de": "AUTO", "fr": "AUTO", "pt": "AUTO", "ru": "АВТО"},
	"turbo":   {"it": "TURBO", "en": "TURBO", "es": "TURBO", "de": "TURBO", "fr": "TURBO", "pt": "TURBO", "ru": "ТУРБО"},
	"spin":    {"it": "SPIN", "en": "SPIN", "es": "GIRAR", "de": "DREHEN", "fr": "TOURNER", "pt": "GIRAR", "ru": "СПИН"},
	"auto_scegli": {"it": "GIRI AUTOMATICI", "en": "AUTO SPINS", "es": "TIRADAS AUTOMÁTICAS", "de": "AUTO-SPINS", "fr": "TOURS AUTOMATIQUES", "pt": "RODADAS AUTOMÁTICAS", "ru": "АВТОСПИНЫ"},
	"freespins": {"it": "GIRI GRATIS  ×%d", "en": "FREE SPINS  ×%d", "es": "GIROS GRATIS  ×%d", "de": "FREISPIELE  ×%d", "fr": "TOURS GRATUITS  ×%d", "pt": "RODADAS GRÁTIS  ×%d", "ru": "БЕСПЛАТНЫЕ СПИНЫ  ×%d"},
	"giro":     {"it": "GIRO %d / %d", "en": "SPIN %d / %d", "es": "GIRO %d / %d", "de": "SPIN %d / %d", "fr": "TOUR %d / %d", "pt": "RODADA %d / %d", "ru": "СПИН %d / %d"},
	"retrigger": {"it": "+%d GIRI!", "en": "+%d SPINS!", "es": "+%d GIROS!", "de": "+%d SPINS!", "fr": "+%d TOURS !", "pt": "+%d RODADAS!", "ru": "+%d СПИНОВ!"},
	"fs_intro": {"it": "GIRI GRATIS!", "en": "FREE SPINS!", "es": "¡GIROS GRATIS!", "de": "FREISPIELE!", "fr": "TOURS GRATUITS !", "pt": "RODADAS GRÁTIS!", "ru": "БЕСПЛАТНЫЕ СПИНЫ!"},
	"fs_giri":  {"it": "%d GIRI", "en": "%d SPINS", "es": "%d GIROS", "de": "%d SPINS", "fr": "%d TOURS", "pt": "%d RODADAS", "ru": "%d СПИНОВ"},
	"fs_vinto": {"it": "HAI VINTO", "en": "YOU WON", "es": "HAS GANADO", "de": "GEWONNEN", "fr": "TU AS GAGNÉ", "pt": "GANHASTE", "ru": "ВЫ ВЫИГРАЛИ"},
	"menu":     {"it": "MENU", "en": "MENU", "es": "MENÚ", "de": "MENÜ", "fr": "MENU", "pt": "MENU", "ru": "МЕНЮ"},
	"ricarica": {"it": "+1.000 CREDITI DI CORTESIA", "en": "+1,000 COURTESY CREDITS", "es": "+1.000 CRÉDITOS DE CORTESÍA", "de": "+1.000 GRATIS-CREDITS", "fr": "+1 000 CRÉDITS OFFERTS", "pt": "+1.000 CRÉDITOS DE CORTESIA", "ru": "+1 000 БОНУСНЫХ КРЕДИТОВ"},
	"finite":  {"it": "Crediti finiti!", "en": "Out of credits!", "es": "¡Sin créditos!", "de": "Kein Guthaben mehr!", "fr": "Plus de crédits !", "pt": "Acabaram os créditos!", "ru": "Кредиты кончились!"},

	# ---- MENU ----
	"gioca":  {"it": "GIOCA", "en": "PLAY", "es": "JUGAR", "de": "SPIELEN", "fr": "JOUER", "pt": "JOGAR", "ru": "ИГРАТЬ"},
	"come":   {"it": "COME SI GIOCA", "en": "HOW TO PLAY", "es": "CÓMO SE JUEGA", "de": "SPIELREGELN", "fr": "COMMENT JOUER", "pt": "COMO JOGAR", "ru": "КАК ИГРАТЬ"},
	"esci":   {"it": "ESCI", "en": "QUIT", "es": "SALIR", "de": "BEENDEN", "fr": "QUITTER", "pt": "SAIR", "ru": "ВЫХОД"},
	"chiudi": {"it": "CHIUDI", "en": "CLOSE", "es": "CERRAR", "de": "SCHLIESSEN", "fr": "FERMER", "pt": "FECHAR", "ru": "ЗАКРЫТЬ"},
	"musica": {"it": "MUSICA", "en": "MUSIC", "es": "MÚSICA", "de": "MUSIK", "fr": "MUSIQUE", "pt": "MÚSICA", "ru": "МУЗЫКА"},
	"effetti": {"it": "EFFETTI", "en": "SFX", "es": "EFECTOS", "de": "EFFEKTE", "fr": "EFFETS", "pt": "EFEITOS", "ru": "ЭФФЕКТЫ"},

	# ---- LEGENDA ----
	"titolo_regole": {"it": "COME SI GIOCA", "en": "HOW TO PLAY", "es": "CÓMO SE JUEGA", "de": "SPIELREGELN", "fr": "COMMENT JOUER", "pt": "COMO JOGAR", "ru": "КАК ИГРАТЬ"},
	"scopo": {
		"it": "Griglia 6×5. Si vince con [b]8 o più simboli uguali OVUNQUE[/b] sulla griglia: non contano le linee, contano quanti ce ne sono. Più simboli uguali cadono, più paga.",
		"en": "6×5 grid. You win with [b]8 or more matching symbols ANYWHERE[/b] on the grid: lines don't matter, only how many there are. The more matching symbols land, the more it pays.",
		"es": "Cuadrícula 6×5. Ganas con [b]8 o más símbolos iguales EN CUALQUIER LUGAR[/b] de la cuadrícula: no cuentan las líneas, cuenta cuántos hay. Cuantos más símbolos iguales caigan, más paga.",
		"de": "6×5-Raster. Du gewinnst mit [b]8 oder mehr gleichen Symbolen IRGENDWO[/b] im Raster: Linien zählen nicht, nur die Anzahl. Je mehr gleiche Symbole landen, desto höher die Auszahlung.",
		"fr": "Grille 6×5. Tu gagnes avec [b]8 symboles identiques ou plus N'IMPORTE OÙ[/b] sur la grille : les lignes ne comptent pas, seul leur nombre compte. Plus il y en a, plus ça paie.",
		"pt": "Grelha 6×5. Ganhas com [b]8 ou mais símbolos iguais EM QUALQUER LUGAR[/b] da grelha: as linhas não contam, conta quantos são. Quantos mais símbolos iguais caírem, mais paga.",
		"ru": "Сетка 6×5. Выигрыш при [b]8 и более одинаковых символах В ЛЮБОМ МЕСТЕ[/b] сетки: линии не важны, важно количество. Чем больше одинаковых символов, тем больше выплата."
	},
	"sez_paytable": {"it": "TABELLA VINCITE", "en": "PAYTABLE", "es": "TABLA DE PAGOS", "de": "AUSZAHLUNGSTABELLE", "fr": "TABLE DES GAINS", "pt": "TABELA DE PAGAMENTOS", "ru": "ТАБЛИЦА ВЫПЛАТ"},
	"pt_nota": {
		"it": "Vincite in crediti con puntata %d. Ogni simbolo paga in base a QUANTI ne cadono: 8-9, 10-11, 12-14, 15-29, 30.",
		"en": "Wins in credits at bet %d. Each symbol pays by HOW MANY land: 8-9, 10-11, 12-14, 15-29, 30.",
		"es": "Ganancias en créditos con apuesta %d. Cada símbolo paga según CUÁNTOS caen: 8-9, 10-11, 12-14, 15-29, 30.",
		"de": "Gewinne in Credits bei Einsatz %d. Jedes Symbol zahlt je nach ANZAHL: 8-9, 10-11, 12-14, 15-29, 30.",
		"fr": "Gains en crédits pour une mise de %d. Chaque symbole paie selon COMBIEN tombent : 8-9, 10-11, 12-14, 15-29, 30.",
		"pt": "Ganhos em créditos com aposta %d. Cada símbolo paga conforme QUANTOS caem: 8-9, 10-11, 12-14, 15-29, 30.",
		"ru": "Выигрыши в кредитах при ставке %d. Каждый символ платит по КОЛИЧЕСТВУ: 8-9, 10-11, 12-14, 15-29, 30."
	},
	"sez_bonus": {"it": "I BONUS", "en": "THE BONUSES", "es": "LOS BONUS", "de": "DIE BONI", "fr": "LES BONUS", "pt": "OS BÓNUS", "ru": "БОНУСЫ"},
	"b_cascata": {
		"it": "[b]CASCATA[/b] — i simboli vincenti spariscono, gli altri scendono e ne cadono di nuovi: se si forma un'altra vincita, ripaga. Il moltiplicatore sale a ogni cascata: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"en": "[b]CASCADE[/b] — winning symbols vanish, the others drop and new ones fall in: if a new win forms, it pays again. The multiplier rises with each cascade: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"es": "[b]CASCADA[/b] — los símbolos ganadores desaparecen, los demás bajan y caen nuevos: si se forma otra ganancia, vuelve a pagar. El multiplicador sube en cada cascada: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"de": "[b]KASKADE[/b] — Gewinnsymbole verschwinden, die anderen rutschen nach und neue fallen nach: entsteht ein neuer Gewinn, zahlt er erneut. Der Multiplikator steigt mit jeder Kaskade: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"fr": "[b]CASCADE[/b] — les symboles gagnants disparaissent, les autres descendent et de nouveaux tombent : si un nouveau gain se forme, il paie encore. Le multiplicateur monte à chaque cascade : ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"pt": "[b]CASCATA[/b] — os símbolos vencedores desaparecem, os outros descem e caem novos: se se formar outro ganho, paga de novo. O multiplicador sobe a cada cascata: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6.",
		"ru": "[b]КАСКАД[/b] — выигрышные символы исчезают, остальные опускаются, падают новые: если образуется новый выигрыш, он снова платит. Множитель растёт с каждым каскадом: ×1, ×1, ×2, ×2, ×3, ×4, ×5, ×6."
	},
	"b_scatter": {
		"it": "[b]IL LIBRO[/b] — 4 / 5 / 6+ libri sulla griglia (alla fine delle cascate) attivano [b]10 / 15 / 20 GIRI GRATIS[/b]. Durante i giri gratis, 3+ libri ne regalano altri 5.",
		"en": "[b]THE BOOK[/b] — 4 / 5 / 6+ books on the grid (after the cascades) trigger [b]10 / 15 / 20 FREE SPINS[/b]. During free spins, 3+ books award 5 more.",
		"es": "[b]EL LIBRO[/b] — 4 / 5 / 6+ libros en la cuadrícula (al final de las cascadas) activan [b]10 / 15 / 20 GIROS GRATIS[/b]. Durante los giros gratis, 3+ libros regalan otros 5.",
		"de": "[b]DAS BUCH[/b] — 4 / 5 / 6+ Bücher im Raster (nach den Kaskaden) lösen [b]10 / 15 / 20 FREISPIELE[/b] aus. Während der Freispiele geben 3+ Bücher 5 weitere.",
		"fr": "[b]LE LIVRE[/b] — 4 / 5 / 6+ livres sur la grille (à la fin des cascades) déclenchent [b]10 / 15 / 20 TOURS GRATUITS[/b]. Pendant les tours gratuits, 3+ livres en offrent 5 de plus.",
		"pt": "[b]O LIVRO[/b] — 4 / 5 / 6+ livros na grelha (no fim das cascatas) ativam [b]10 / 15 / 20 RODADAS GRÁTIS[/b]. Durante as rodadas grátis, 3+ livros dão mais 5.",
		"ru": "[b]КНИГА[/b] — 4 / 5 / 6+ книг на сетке (после каскадов) запускают [b]10 / 15 / 20 БЕСПЛАТНЫХ СПИНОВ[/b]. Во время бесплатных спинов 3+ книги дают ещё 5."
	},
	"b_fsmult": {
		"it": "[b]MOLTIPLICATORE ACCUMULANTE[/b] — nei giri gratis il moltiplicatore NON si azzera tra un giro e l'altro: continua a salire per tutto il bonus.",
		"en": "[b]ACCUMULATING MULTIPLIER[/b] — in free spins the multiplier does NOT reset between spins: it keeps growing for the whole bonus.",
		"es": "[b]MULTIPLICADOR ACUMULATIVO[/b] — en los giros gratis el multiplicador NO se reinicia entre giros: sigue subiendo durante todo el bonus.",
		"de": "[b]KUMULIERENDER MULTIPLIKATOR[/b] — in den Freispielen wird der Multiplikator zwischen den Spins NICHT zurückgesetzt: er wächst den ganzen Bonus lang.",
		"fr": "[b]MULTIPLICATEUR CUMULATIF[/b] — pendant les tours gratuits, le multiplicateur ne se réinitialise PAS entre les tours : il continue de monter pendant tout le bonus.",
		"pt": "[b]MULTIPLICADOR ACUMULATIVO[/b] — nas rodadas grátis o multiplicador NÃO reinicia entre rodadas: continua a subir durante todo o bónus.",
		"ru": "[b]НАКОПИТЕЛЬНЫЙ МНОЖИТЕЛЬ[/b] — в бесплатных спинах множитель НЕ сбрасывается между спинами: он растёт весь бонус."
	},
	"b_fiala": {
		"it": "[b]LA FIALA[/b] — solo nei giri gratis: atterra con un valore (×2 … ×100) che si SOMMA al moltiplicatore accumulante.",
		"en": "[b]THE VIAL[/b] — free spins only: it lands with a value (×2 … ×100) that is ADDED to the accumulating multiplier.",
		"es": "[b]EL FRASCO[/b] — solo en los giros gratis: cae con un valor (×2 … ×100) que se SUMA al multiplicador acumulativo.",
		"de": "[b]DIE PHIOLE[/b] — nur in den Freispielen: sie landet mit einem Wert (×2 … ×100), der zum kumulierenden Multiplikator ADDIERT wird.",
		"fr": "[b]LA FIOLE[/b] — tours gratuits uniquement : elle tombe avec une valeur (×2 … ×100) qui s'AJOUTE au multiplicateur cumulatif.",
		"pt": "[b]O FRASCO[/b] — só nas rodadas grátis: cai com um valor (×2 … ×100) que se SOMA ao multiplicador acumulativo.",
		"ru": "[b]ФИАЛ[/b] — только в бесплатных спинах: выпадает со значением (×2 … ×100), которое ПРИБАВЛЯЕТСЯ к накопительному множителю."
	},
	"b_wild": {
		"it": "[b]LA PIETRA FILOSOFALE[/b] — è il jolly: sostituisce qualsiasi pozione o ingrediente per completare una vincita.",
		"en": "[b]THE PHILOSOPHER'S STONE[/b] — the wild: it substitutes for any potion or ingredient to complete a win.",
		"es": "[b]LA PIEDRA FILOSOFAL[/b] — es el comodín: sustituye cualquier poción o ingrediente para completar una ganancia.",
		"de": "[b]DER STEIN DER WEISEN[/b] — das Wild: ersetzt jeden Trank oder jede Zutat, um einen Gewinn zu vervollständigen.",
		"fr": "[b]LA PIERRE PHILOSOPHALE[/b] — le joker : elle remplace n'importe quelle potion ou ingrédient pour compléter un gain.",
		"pt": "[b]A PEDRA FILOSOFAL[/b] — é o coringa: substitui qualquer poção ou ingrediente para completar um ganho.",
		"ru": "[b]ФИЛОСОФСКИЙ КАМЕНЬ[/b] — дикий символ: заменяет любое зелье или ингредиент для завершения выигрыша."
	},
	"b_max": {"it": "Vincita massima: 5.000× la puntata.", "en": "Max win: 5,000× the bet.", "es": "Ganancia máxima: 5.000× la apuesta.", "de": "Maximalgewinn: 5.000× der Einsatz.", "fr": "Gain max : 5 000× la mise.", "pt": "Ganho máximo: 5.000× a aposta.", "ru": "Макс. выигрыш: 5 000× ставки."},
	"sez_comandi": {"it": "COMANDI", "en": "CONTROLS", "es": "CONTROLES", "de": "STEUERUNG", "fr": "COMMANDES", "pt": "COMANDOS", "ru": "УПРАВЛЕНИЕ"},
	"comandi": {
		"it": "SPIN o BARRA SPAZIATRICE per girare · TURBO velocizza · AUTO sceglie quanti giri · BET cambia la puntata · ESC torna al menu.",
		"en": "SPIN or SPACEBAR to spin · TURBO speeds up · AUTO picks how many spins · BET changes the bet · ESC returns to the menu.",
		"es": "GIRAR o BARRA ESPACIADORA para girar · TURBO acelera · AUTO elige cuántas tiradas · APUESTA cambia la apuesta · ESC vuelve al menú.",
		"de": "DREHEN oder LEERTASTE zum Drehen · TURBO beschleunigt · AUTO wählt die Anzahl der Spins · EINSATZ ändert den Einsatz · ESC zurück zum Menü.",
		"fr": "TOURNER ou BARRE D'ESPACE pour lancer · TURBO accélère · AUTO choisit le nombre de tours · MISE change la mise · ÉCHAP revient au menu.",
		"pt": "GIRAR ou BARRA DE ESPAÇO para girar · TURBO acelera · AUTO escolhe quantas rodadas · APOSTA muda a aposta · ESC volta ao menu.",
		"ru": "СПИН или ПРОБЕЛ — крутить · ТУРБО — быстрее · АВТО — число спинов · СТАВКА — сменить ставку · ESC — в меню."
	},
}
