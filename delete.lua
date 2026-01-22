-- ... (Gardez les imports du début) ...

local Config = {
    active = false,
    is_recording = false, -- État de la capture d'écran
    aim_assist = true,
    rapid_fire = true,
    
    -- Paramètres ajustables
    target_R = 255, target_G = 0, target_B = 0,
    tolerance = 60,
    box_size = 300,
    speed_ms = 45,
    is_shooting = false
}

-- ================= FONCTIONS DE COMMANDE =================

-- 1. START RECORD (Demander la permission de voir l'écran)
function startRecording()
    -- Note: 'requestScreenCapture' est la commande standard 
    -- pour les exécuteurs Lua type Auto.js / Hamibot
    threads.start(function()
        if requestScreenCapture(false) then -- Le 'false' évite de demander à chaque fois
            Config.is_recording = true
            print("📸 Capture d'écran activée !")
            toast("Capture d'écran activée")
            btnRecord.setText("RECORD: ON")
            btnRecord.setBackgroundColor(0xFF4CAF50) -- Vert
        else
            Config.is_recording = false
            print("❌ Permission refusée")
            toast("Permission refusée")
        end
    end)
end

-- 2. START SCAN (Lancer la boucle de détection)
function startScan()
    if not Config.is_recording then
        toast("⚠️ Active d'abord le RECORD !")
        return
    end
    Config.active = true
    handler.post(mainLoop)
    btnToggleScan.setText("SCAN: ACTIF")
    btnToggleScan.setBackgroundColor(0xFF4CAF50)
    boxView.setVisibility(0)
    print("🚀 Scan démarré")
end

-- 3. STOP ALL
function stopEverything()
    Config.active = false
    Config.is_shooting = false
    boxView.setVisibility(8)
    btnToggleScan.setText("DÉMARRER SCAN")
    btnToggleScan.setBackgroundColor(0xFFF44336) -- Rouge
    print("🛑 Tout est arrêté")
end

-- ================= INTERFACE (PANEL MIS À JOUR) =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackground(GradientDrawable().setColor(0xF0101010).setCornerRadius(20).setStroke(3, Color.CYAN))
mainView.setPadding(30, 30, 30, 30)
mainView.setVisibility(8)

-- SECTION : BOUTONS DE COMMANDE
local sectionTitle = TextView(activity)
sectionTitle.setText("--- SYSTÈME ---")
sectionTitle.setGravity(17)
sectionTitle.setTextColor(Color.CYAN)
mainView.addView(sectionTitle)

-- Bouton Record
btnRecord = Button(activity)
btnRecord.setText("1. ACTIVER RECORD")
btnRecord.setOnClickListener(function() startRecording() end)
mainView.addView(btnRecord)

-- Bouton Start Scan
btnToggleScan = Button(activity)
btnToggleScan.setText("2. DÉMARRER SCAN")
btnToggleScan.setOnClickListener(function() 
    if Config.active then stopEverything() else startScan() end 
end)
mainView.addView(btnToggleScan)

-- Espace
local space = View(activity); space.setLayoutParams(LinearLayout.LayoutParams(-1, 30)); mainView.addView(space)

-- SECTION : RÉGLAGES COULEURS (Déjà codé précédemment)
local colorTitle = TextView(activity)
colorTitle.setText("--- RÉGLAGES CIBLE ---")
colorTitle.setGravity(17); colorTitle.setTextColor(Color.YELLOW)
mainView.addView(colorTitle)

function addSlider(label, min, max, current, callback)
    local txt = TextView(activity); txt.setText(label .. " : " .. current); txt.setTextColor(-1)
    local sk = SeekBar(activity); sk.setMax(max-min); sk.setProgress(current-min)
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_, p)
        local val = p + min; txt.setText(label .. " : " .. val); callback(val)
    end})
    mainView.addView(txt); mainView.addView(sk)
end

addSlider("ROUGE", 0, 255, Config.target_R, function(v) Config.target_R = v end)
addSlider("TOLÉRANCE", 10, 150, Config.tolerance, function(v) Config.tolerance = v end)
addSlider("TAILLE CARRÉ", 100, 600, Config.box_size, function(v) 
    Config.box_size = v 
    lpBox.width = v; lpBox.height = v
    wm.updateViewLayout(boxView, lpBox)
end)

-- Bouton Fermer Menu
local btnHide = Button(activity); btnHide.setText("MASQUER MENU"); btnHide.setOnClickListener(function() mainView.setVisibility(8) end)
mainView.addView(btnHide)

-- [Ajouter ici le reste du code de gestion d'Overlay, BoxView et mainLoop du message précédent]

-- ================= PROCÉDURE D'UTILISATION =================
-- 1. Appuyer sur l'engrenage ⚙️
-- 2. Cliquer sur "1. ACTIVER RECORD" -> Accepter la fenêtre Android qui apparaît.
-- 3. Une fois que le bouton est VERT, cliquer sur "2. DÉMARRER SCAN".
-- 4. Le carré rouge apparaît : le script cherche maintenant la couleur.