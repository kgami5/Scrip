require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.util.DisplayMetrics"
import "android.content.Context"
import "android.media.projection.MediaProjectionManager"

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    box_size = 300, -- Taille de la zone de scan
    tolerance = 80,  -- Sensibilité au rouge
    speed_ms = 30,   -- Plus rapide (30ms)
    offset_x = -20   -- DÉCALAGE FORT VERS LA GAUCHE (-20 pixels)
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= FONCTIONS DE DESSIN =================

local function CreateShape(color, strokeColor, strokeWidth)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(10)
    if strokeColor then gd.setStroke(strokeWidth or 4, strokeColor) end
    return gd
end

-- ================= GESTION CAPTURE PROPRE =================

local mMediaProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local mMediaProjection = nil

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 and resultCode == -1 then
        -- Initialisation de la capture d'écran système
        pcall(function()
            mMediaProjection = mMediaProjectionManager.getMediaProjection(resultCode, data)
        end)
        if mMediaProjection or requestScreenCapture(false) then
            Config.is_recording = true
            setInfo("✅ VISION : CONNECTÉE", Color.GREEN)
            btnRecord.setBackgroundDrawable(CreateShape(0xFF2E7D32))
        end
    else
        setInfo("❌ ÉCHEC INITIALISATION", Color.RED)
    end
end

-- ================= BARRE DE STATUT (MONITORING) =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0xDD000000))
statusLayout.setPadding(30, 15, 30, 15)

local statusText = TextView(activity)
statusText.setText("PRÊT - LANCE LA VISION")
statusText.setTextColor(Color.WHITE)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 
lpStatus.y = 80
pcall(function() wm.addView(statusLayout, lpStatus) end)

function setInfo(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE AIM (RECODÉE) =================

function getTarget()
    local img = captureScreen() -- Utilise le moteur de scan interne
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 12 -- Scan plus précis
    
    -- Zone de scan décalée
    local scanX = (CX - (Config.box_size / 2)) + Config.offset_x
    local scanY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            -- Lecture des pixels
            local px = images.getPixel(img, scanX + x, scanY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- Cible le ROUGE vif des ennemis (CODM)
            if r > 180 and g < 100 and b < 100 then
                sumX = sumX + (scanX + x)
                sumY = sumY + (scanY + y)
                count = count + 1
            end
        end
    end

    if count > 2 then -- Il faut au moins 3 pixels rouges pour valider
        return { x = sumX / count, y = sumY / count }
    end
    return nil
end

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        -- Mouvement magnétique
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        setInfo("🎯 CIBLE DÉTECTÉE", Color.GREEN)
        boxView.setBackgroundDrawable(CreateShape(0, Color.GREEN, 8))

        local s = service or auto
        if s then
            local builder = luajava.bindClass("android.accessibilityservice.GestureDescription$Builder")()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            local stroke = luajava.bindClass("android.accessibilityservice.GestureDescription$StrokeDescription")(p, 0, 50)
            builder.addStroke(stroke)
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        setInfo("🔍 SCAN ACTIF (RIEN)", Color.YELLOW)
        boxView.setBackgroundDrawable(CreateShape(0, Color.RED, 4))
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(CreateShape(0xF0101010, Color.CYAN))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    activity.startActivityForResult(mMediaProjectionManager.createScreenCaptureIntent(), 1)
end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        setInfo("⚠️ ACTIVE LA VISION !", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundDrawable(Config.active and CreateShape(0xFF2E7D32) or CreateShape(0xFFC62828))
    btnScan.setText(Config.active and "AIM : ON" or "2. START AIM")
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
pcall(function() wm.addView(mainView, lpPanel) end)

-- LE CARRÉ DE VISÉE (DÉCALÉ À GAUCHE DE 20 PX)
boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0, Color.RED, 4))

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x -- POSITION : -20 PIXELS GAUCHE
pcall(function() wm.addView(boxView, lpBox) end)

-- BOUTON MENU ⚙️
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 250
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
pcall(function() wm.addView(btnMenu, lpBtn) end)