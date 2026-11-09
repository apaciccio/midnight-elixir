# Pubblicazione delle tre slot Midnight — checklist (5 nov 2026)

Ordine consigliato: **Google Play prima** (revisione più semplice, puoi provare la build sul telefono senza account Apple),
poi App Store. Prima versione **gratis e senza acquisti in-app** (v1.1): i crediti si ricaricano da soli
("+1.000 crediti di cortesia"). Gli acquisti arrivano con la v1.2, DOPO che gli account esistono: senza account
non si possono nemmeno testare.

---------------------------------------------------------------------------------------------------
## A. Da fare UNA VOLTA sola (adesso, senza aspettare niente)
---------------------------------------------------------------------------------------------------

### A1. Privacy policy online (obbligatoria per entrambi gli store)
File pronto: `store-kit/privacy/index.html`. **Prima** apri il file e sostituisci `EMAIL_DA_INSERIRE` (2 volte)
con l'email che vuoi usare per il supporto. Poi la pubblichi con GitHub Pages (gratis, 1 minuto):

    mkdir -p ~/midnight-privacy && cp ~/Downloads/store-kit/privacy/index.html ~/midnight-privacy/
    cd ~/midnight-privacy && git init -q && git add -A && git commit -qm "privacy policy" && git branch -M main
    gh repo create apaciccio/midnight-privacy --public --source=. --remote=origin --push
    gh api -X POST repos/apaciccio/midnight-privacy/pages -f "source[branch]=main" -f "source[path]=/"

URL da mettere negli store (attivo dopo ~1 minuto): **https://apaciccio.github.io/midnight-privacy/**

### A2. Keystore Android (la "firma" dell'app: UNA per tutta la vita della serie)
Lo crea `build_android.sh` al primo avvio in `~/midnight-keys/midnight_upload.keystore`.
Ti chiede una password: **scrivila** nel gestore password e **copia il file** su iCloud/USB.
Se lo perdi, NON potrai mai più aggiornare le app pubblicate.

### A3. Strumenti sul Mac (una tantum)
    brew install openjdk@17
    # Android Studio: https://developer.android.com/studio  -> installa, apri, lascia scaricare l'SDK
    # In Android Studio: More Actions -> SDK Manager -> SDK Tools -> spunta "Android SDK Command-line Tools" -> Apply
    # In Godot: Editor -> Manage Export Templates -> Download and Install

### A4. Account
- **Google Play Console**: https://play.google.com/console — 25 $ una tantum. Tipo account: **organizzazione**
  (con la partita IVA) → ti chiede dati fiscali, un indirizzo e un telefono verificabili, e per le
  organizzazioni un documento (visura/certificato P.IVA). Mettilo in conto: la verifica può richiedere giorni.
- **Apple Developer**: https://developer.apple.com/programs/ — 99 $/anno. Come **individuo/ditta individuale**
  basta l'Apple ID + carta; come "organizzazione" servirebbe il numero D-U-N-S (settimane). Per una ditta
  individuale iscriviti come individuo: il nome venditore sarà il tuo nome.

---------------------------------------------------------------------------------------------------
## B. Preparare i tre progetti (per ciascuno: Elixir è già fatto, Heist e Case con gli stessi script)
---------------------------------------------------------------------------------------------------
Per Elixir è tutto nel pacchetto `elixir_game_v1.1.zip`. Per Heist e Case:

    # 1) grafiche da store (icone, feature graphic, screenshot nei formati giusti)
    mkdir -p ~/slot-mvp/store/shots          # mettici 4-6 screenshot del gioco (menu, gioco, bonus...)
    python3 ~/strumenti/store_assets.py --gioco heist --logo ~/slot-mvp/assets/logo.png \
        --sfondo ~/slot-mvp/assets/background.png --shot ~/slot-mvp/store/shots --out ~/slot-mvp/store
    cp ~/slot-mvp/store/icon.png ~/slot-mvp/icon.png
    # 2) impostazioni mobile in project.godot (orientamento orizzontale, icona, versione)
    python3 ~/strumenti/mobile_setup.py ~/slot-mvp --versione 1.2.0
    # 3) stesso per Case (logo e sfondo: controlla i nomi dei file in assets/)
    python3 ~/strumenti/store_assets.py --gioco case --logo ~/midnight-case/assets/logo.png \
        --sfondo ~/midnight-case/assets/background.png --shot ~/midnight-case/store/shots --out ~/midnight-case/store
    cp ~/midnight-case/store/icon.png ~/midnight-case/icon.png
    python3 ~/strumenti/mobile_setup.py ~/midnight-case --versione 1.9.0

Poi mandami uno screenshot delle icone generate (`store/icon_512.png`) per controllare che il logo ci stia bene.
Il preset Android e `build_android.sh` per Heist e Case li preparo io quando mi dai conferma dei nomi
dei file (logo/sfondo) e che il gioco gira in orizzontale col tocco: **provali prima su Mac** dopo mobile_setup.

### Prova vera sul telefono Android (consigliata, prima di caricare)
    bash ~/midnight-elixir/build_android.sh --debug
    # poi, col telefono collegato via USB e "Debug USB" attivo nelle opzioni sviluppatore:
    ~/Library/Android/sdk/platform-tools/adb install -r ~/midnight-elixir/export/android/MidnightElixir_debug.apk
Controlla: tocco sui tasti, orientamento, audio, che il saldo resti dopo chiusura e riapertura.

---------------------------------------------------------------------------------------------------
## C. Google Play Console — per ogni gioco
---------------------------------------------------------------------------------------------------
1. **Crea app** → nome (vedi SCHEDE_STORE), lingua predefinita Italiano, "Gioco", "Gratuita".
2. **Impostazione app** (pannello "Configura la tua app"), rispondi così:
   - Privacy policy: l'URL del punto A1.
   - Accesso all'app: "Tutte le funzionalità sono disponibili senza restrizioni" (niente login).
   - Annunci: **No** (nessuna pubblicità nella v1.1).
   - **Classificazione contenuti** (questionario IARC): categoria "Gioco". Risposte:
       - Violenza: Heist → "violenza da cartone animato/fantasy, lieve" (dinamite, sirena); Case e Elixir → nessuna.
       - Armi: Case ha un revolver tra i simboli (solo raffigurato, mai usato) → rispondi sì alla domanda
         sulle "armi raffigurate" se presente. Heist: no (attrezzi da scasso non sono armi).
       - Sesso/nudità, linguaggio, droghe: no. Elixir: le "pozioni" non sono droghe, rispondi no.
       - **Gioco d'azzardo simulato: SÌ** (è la domanda chiave; dà da sola il rating più alto: PEGI 18 / ESRB).
       - Gioco d'azzardo con denaro reale: NO. Acquisti in-app: NO (finché non arriva la v1.2).
       - Condivisione posizione / dati personali / interazione tra utenti: no.
   - **Pubblico di destinazione**: 18 e oltre. "App rivolta ai bambini": no.
   - Sicurezza dei dati: "Nessun dato raccolto, nessun dato condiviso". Crittografia: non applicabile.
   - App governativa: no. App finanziaria: no. Salute: no.
   - **Categoria**: Gioco → Casinò. Tag: slot, casinò.
3. **Scheda dello store principale**: titolo/breve/completa da `SCHEDE_STORE_7_LINGUE.md`;
   icona `store/icon_512.png`; feature graphic `store/feature_1024x500.png`;
   screenshot telefono: `store/shots_android/` (min 2, consigliati 5); tablet 7"/10": gli stessi file vanno bene.
   Poi "Aggiungi traduzioni" → incolla le altre 6 lingue.
4. **Release**: Test → **Test interno** → Crea release → carica l'`.aab` di `build_android.sh` → note di release
   ("Prima versione") → avvia. Installalo dal link di test sul tuo telefono, gioca 10 minuti.
5. **Produzione** → Crea release → stesso .aab → Paesi: tutti → Invia per la revisione (1-7 giorni).

Ogni aggiornamento successivo: alza `version/code` (+1) e `version/name` nel preset Android, rifai la build, carica.

---------------------------------------------------------------------------------------------------
## D. App Store — per ogni gioco (dopo l'account Apple Developer)
---------------------------------------------------------------------------------------------------
1. In Godot: preset **iOS** (lo preparo io come quello Android) → export → si apre un progetto Xcode.
2. Xcode: Signing & Capabilities → Team = il tuo account → Product → Archive → Distribute → App Store Connect.
3. App Store Connect → Le mie app → "+" → nome, bundle ID `com.apaciccio.midnightelixir`, SKU = bundle ID.
4. Informazioni app: categoria **Giochi > Casinò**, classificazione per età: nel questionario Apple
   "Gioco d'azzardo simulato: **Frequente/Intenso**" → risulta **17+**. Privacy: "Dati non raccolti".
5. Scheda: nome, sottotitolo, descrizione, parole chiave da `SCHEDE_STORE_7_LINGUE.md`; URL privacy;
   screenshot iPhone 6,7" da `store/shots_iphone67/`, iPad 13" da `store/shots_ipad13/`.
6. Note per la revisione (campo "Note"): "Social casino game: no real-money gambling, virtual credits only,
   credits refill automatically, no account required, no purchases in this version."
7. Invia per la revisione (1-3 giorni). Apple controlla con più attenzione i giochi da casinò:
   le frasi obbligatorie nella descrizione e il rating 17+ sono quello che guardano.

---------------------------------------------------------------------------------------------------
## E. Dopo la pubblicazione: v1.2 con gli acquisti (crediti)
---------------------------------------------------------------------------------------------------
Da fare quando gli account esistono (serve per creare i prodotti e testare con account sandbox):
- 5 pacchetti di crediti (es. 10k / 50k / 150k / 500k / 2M) definiti in Play Console e App Store Connect,
  stesso ID su entrambi (`crediti_10k`, …).
- Negozio nel gioco (schermata "Crediti" dal menu e automatica a saldo zero, accanto alla ricarica gratuita).
- Plugin Godot: Google Play Billing (Android) e StoreKit (iOS) — ti darò i file e il codice `shop.gd`
  con l'interruttore: su Mac dà crediti finti per provare, sul telefono compra davvero.
- Aggiornare: questionario rating ("acquisti in-app: sì"), privacy (già scritta per questo caso), descrizione.
- Fisco: le vendite arrivano come compensi Apple/Google (trattengono il 15% fino a 1 M$/anno);
  parlane col commercialista per come registrarle nel forfettario.
