require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- Pas de "require", on utilise les fonctions globales de l'app
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local Color = luajava.bindClass("android.graphics.Color")
local Path = luajava.bindClass("android.graphics.Path")
local WindowManager = luajava.bindClass("android.view.WindowManager")
local Context = luajava.bindClass("android.content.Context")
local GestureDescription = luajava.bindClass("android.accessibilityservice.GestureDescription")

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    target_R = 255, -- Couleur rouge
    tolerance = 70,
    box_size = 300,
    speed_ms = 40,
    offset_left = -3 -- DÉCALAGE 3 PIXELS GAUCHE
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= BARRE D'INFOS EN HAUT =================

local infoLayout = LinearLayout(activity)
infoLayout.setBackgroundDrawable(GradientDrawable().setColor(0xCC000000).setCornerRadius(10))
infoLayout.setPadding(30, 10, 30, 10)

local infoText = TextView(activity)
infoText.setText("STATUT : EN ATTENTE")
infoText.setTextColor(Color.WHITE)
infoText.setTextSize(13)
infoLayout.addView(infoText)

local lpInfo = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpInfo.gravity = 49 -- Haut Centre
lpInfo.y = 100
wm.addView(infoLayout, lpInfo)

function showStatus(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        infoText.setText(msg)
        if col then infoText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE SCANNER PIXELS =================

function getTarget()
    -- On essaie de capturer l'écran de façon universelle
    local img = nil
    pcall(function() img = captureScreen() end)
    
    if not img then 
        showStatus("ERREUR: CAPTURE IMPOSSIBLE", Color.RED)
        return nil 
    end

    local sumX, sumY, count = 0, 0, 0
    local step = 15 -- Performance
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, startX + x, startY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- Détection du rouge
            if r > 150 and g < 90 and b < 90 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 1 then
        showStatus("🎯 CIBLE DÉTECTÉE", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    
    showStatus("🔍 RECHERCHE CIBLE...", Color.YELLOW)
    return nil
end

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0101010).setStroke(3, Color.CYAN).setCornerRadius(25))
mainView.setPadding(45, 45, 45, 45)
mainView.setVisibility(8)

-- BOUTON 1 : INITIALISATION (FIXÉ)
btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    -- Utilisation de threads pour éviter le crash
    threads.start(function()
        showStatus("DEMANDE DE VISION...", Color.CYAN)
        -- Test de la fonction de capture
        local ok = false
        if pcall(function() ok = requestScreenCapture(false) end) then
            if ok then
                Config.is_recording = true
                showStatus("✅ VISION ACTIVE", Color.GREEN)
                activity.runOnUiThread(Runnable({run=function() btnRecord.setBackgroundColor(0xFF2E7D32) end}))
            else
                showStatus("❌ REFUSÉ", Color.RED)
            end
        else
            showStatus("❌ FONCTION NON TROUVÉE", Color.RED)
        end
    end)
end)
mainView.addView(btnRecord)

-- BOUTON 2 : START
btnScan = Button(activity)
btnScan.setText("2. LANCER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        showStatus("⚠️ ALLUME LA VISION !", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ ROUGE (DÉCALÉ DE 3px GAUCHE)
boxView = View(activity)
local boxStroke = GradientDrawable()
boxStroke.setShape(0)
boxStroke.setColor(0)
boxStroke.setStroke(5, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_left -- LE DÉCALAGE DE 3 PIXELS VERS LA GAUCHE
wm.addView(boxView, lpBox)

-- MENU FLOTTANT ⚙️
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 220
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

-- ================= BOUCLE DE MOUVEMENT =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        boxStroke.setStroke(8, Color.GREEN)
        
        -- Calculer le déplacement
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        -- Envoi du geste
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxStroke.setStroke(4, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

showStatus("SENSEI AIM PRÊT", Color.WHITE)