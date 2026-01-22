require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- Tentative de récupération du module images
local imgMod = nil
pcall(function() imgMod = require("images") end)

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
    tolerance = 70,
    box_size = 300,
    speed_ms = 45,
    offset_x = -3 -- DÉCALAGE 3 PIXELS GAUCHE
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= BARRE DE STATUT =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xCC000000).setCornerRadius(12))
statusLayout.setPadding(30, 15, 30, 15)

local statusText = TextView(activity)
statusText.setText("ÉTAT : ATTENTE")
statusText.setTextColor(Color.WHITE)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 -- Haut
lpStatus.y = 100
wm.addView(statusLayout, lpStatus)

function setInfo(msg, col)
    statusText.setText(msg)
    if col then statusText.setTextColor(col) end
end

-- ================= LOGIQUE SCANNER =================

function getTarget()
    local img = nil
    -- Test de plusieurs méthodes de capture
    if imgMod and imgMod.captureScreen then
        img = imgMod.captureScreen()
    elseif captureScreen then
        img = captureScreen()
    end
    
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 15
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

    if count > 0 then
        setInfo("🎯 CIBLE : OK ("..count..")", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    setInfo("🔍 RECHERCHE...", Color.YELLOW)
    return nil
end

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0101010).setStroke(4, Color.YELLOW).setCornerRadius(20))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

-- BOUTON 1 : VISION (SANS THREADS)
btnRecord = Button(activity)
btnRecord.setText("1. ACTIVER VISION")
btnRecord.setOnClickListener(function()
    local success = false
    -- On essaie d'activer la capture proprement
    pcall(function()
        if imgMod and imgMod.requestScreenCapture then
            success = imgMod.requestScreenCapture(false)
        elseif requestScreenCapture then
            success = requestScreenCapture(false)
        end
    end)

    if success then
        Config.is_recording = true
        setInfo("✅ VISION ACTIVE", Color.GREEN)
        btnRecord.setBackgroundColor(0xFF2E7D32)
    else
        setInfo("❌ ERREUR CAPTURE (Vérifie réglages app)", Color.RED)
    end
end)
mainView.addView(btnRecord)

-- BOUTON 2 : AIM
btnScan = Button(activity)
btnScan.setText("2. START AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        setInfo("⚠️ ACTIVE VISION D'ABORD", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ (DÉCALÉ DE 3px GAUCHE)
boxView = View(activity)
boxStroke = GradientDrawable()
boxStroke.setShape(0)
boxStroke.setColor(0)
boxStroke.setStroke(5, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x -- POSITION : -3px
wm.addView(boxView, lpBox)

-- MENU ⚙️
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

-- ================= BOUCLE FINALE =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        boxStroke.setStroke(8, Color.GREEN)
        local moveX = (target.x - CX) * 0.7
        local moveY = (target.y - CY) * 0.7
        
        -- Envoi du mouvement (Accessibilité)
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxStroke.setStroke(4, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

setInfo("PRÊT - CLIQUE SUR VISION", Color.WHITE)