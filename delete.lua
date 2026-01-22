require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- Chargement du module images (Crucial pour Kgami/Zen)
local images = require "images"

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
    target_R = 255, target_G = 0, target_B = 0,
    tolerance = 70,
    box_size = 280,
    speed_ms = 40,
    recoil = 15,
    offset_left = -3 -- Décalage de 3 pixels vers la gauche
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= BARRE D'INFOS (POUR NE PLUS ÊTRE PERDU) =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xBB000000).setCornerRadius(10))
statusLayout.setPadding(20, 10, 20, 10)

local statusText = TextView(activity)
statusText.setText("STATUT : ATTENTE CONFIG")
statusText.setTextColor(Color.WHITE)
statusText.setTextSize(12)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 -- Haut au milieu
lpStatus.y = 80
wm.addView(statusLayout, lpStatus)

function setInfo(txt, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(txt)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE DE VISION =================

function getTarget()
    -- Utilisation du module images sécurisé
    local img = images.captureScreen()
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 12
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, startX + x, startY + y)
            -- Extraction rapide des couleurs
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- Détection du rouge (ajustable)
            if r > 160 and g < 100 and b < 100 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        setInfo("🎯 CIBLE VERROUILLÉE ("..count.." px)", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    setInfo("🔍 SCAN EN COURS...", Color.YELLOW)
    return nil
end

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0121212).setStroke(3, Color.MAGENTA).setCornerRadius(20))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

-- BOUTON 1 : INITIALISER VISION (FIXÉ)
btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    threads.start(function()
        setInfo("DEMANDE DE PERMISSION...", Color.CYAN)
        -- Correction ici : on utilise images.requestScreenCapture
        if images.requestScreenCapture(false) then
            Config.is_recording = true
            setInfo("✅ VISION OK", Color.GREEN)
            activity.runOnUiThread(Runnable({run=function() btnRecord.setBackgroundColor(0xFF388E3C) end}))
        else
            setInfo("❌ ÉCHEC PERMISSION", Color.RED)
        end
    end)
end)
mainView.addView(btnRecord)

-- BOUTON 2 : START SCAN
btnScan = Button(activity)
btnScan.setText("2. DÉMARRER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        setInfo("⚠️ CLIQUE SUR VISION D'ABORD", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFFD32F2F or 0xFF1976D2)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ DE VISÉE (DÉCALÉ À GAUCHE)
boxView = View(activity)
boxStroke = GradientDrawable()
boxStroke.setShape(0)
boxStroke.setColor(0)
boxStroke.setStroke(5, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_left -- DECALAGE GAUCHE APPLIQUÉ ICI
wm.addView(boxView, lpBox)

-- BOUTON MENU ⚙️
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 200
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

-- ================= BOUCLE DE FONCTIONNEMENT =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        boxStroke.setStroke(8, Color.GREEN)
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY + Config.recoil)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 45))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxStroke.setStroke(4, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

setInfo("PRÊT - CLIQUEZ SUR ALLUMER VISION", Color.WHITE)