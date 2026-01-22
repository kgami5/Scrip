require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- Tentative forcée d'importer le module d'images
local images = nil
pcall(function() images = require "images" end)

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
    tolerance = 75,
    box_size = 280, -- Taille du carré
    speed_ms = 40,
    offset_left = -3 -- LE DÉCALAGE DE 3 PIXELS GAUCHE
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= BARRE DE STATUT (MONITORING) =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xDD000000).setCornerRadius(15))
statusLayout.setPadding(35, 20, 35, 20)

local statusText = TextView(activity)
statusText.setText("1. CLIQUEZ SUR 'ACTIVER VISION'")
statusText.setTextColor(Color.WHITE)
statusText.setTextStyle(Typeface.BOLD)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 -- Tout en haut
lpStatus.y = 100
wm.addView(statusLayout, lpStatus)

function updateUI(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE SCANNER =================

function getTarget()
    if not images then return nil end
    local img = nil
    pcall(function() img = images.captureScreen() end)
    
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 15 -- Pas de scan
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, startX + x, startY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- Cible le rouge vif
            if r > 160 and g < 80 and b < 80 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        updateUI("🎯 CIBLE VERROUILLÉE", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    updateUI("🔍 RECHERCHE ENNEMI...", Color.YELLOW)
    return nil
end

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0151515).setStroke(5, Color.CYAN).setCornerRadius(30))
mainView.setPadding(50, 50, 50, 50)
mainView.setVisibility(8)

-- BOUTON 1 : VISION (CRITIQUE)
btnRecord = Button(activity)
btnRecord.setText("1. ACTIVER VISION")
btnRecord.setOnClickListener(function()
    local success = false
    -- Test de la capture
    if images and images.requestScreenCapture then
        success = images.requestScreenCapture(false)
    elseif requestScreenCapture then
        success = requestScreenCapture(false)
    end

    if success then
        Config.is_recording = true
        updateUI("✅ VISION ACTIVE ! LANCEZ L'AIM", Color.GREEN)
        btnRecord.setBackgroundColor(0xFF2E7D32)
        btnRecord.setText("VISION : OK")
    else
        updateUI("❌ ERREUR : ACCÈS ÉCRAN REFUSÉ", Color.RED)
        print("Vérifiez l'autorisation 'Enregistrement d'écran' dans Android")
    end
end)
mainView.addView(btnRecord)

-- BOUTON 2 : AIM
btnScan = Button(activity)
btnScan.setText("2. DÉMARRER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        updateUI("⚠️ ERREUR : FAITES L'ÉTAPE 1 D'ABORD", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ DE VISÉE (DÉCALÉ DE 3px GAUCHE)
boxView = View(activity)
boxStroke = GradientDrawable()
boxStroke.setShape(0)
boxStroke.setColor(0)
boxStroke.setStroke(6, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_left -- DECALAGE GAUCHE ICI
wm.addView(boxView, lpBox)

-- MENU FLOTTANT (⚙️)
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(130, 130, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 250
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

-- ================= BOUCLE FINALE =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        boxStroke.setStroke(10, Color.GREEN)
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 45))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxStroke.setStroke(4, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

updateUI("LOGICIEL PRÊT - ÉTAPE 1 REQUISE", Color.WHITE)