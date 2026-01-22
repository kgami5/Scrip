require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- CLASSES
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
    tolerance = 75,
    box_size = 300,
    speed_ms = 35,
    recoil = 20,
    offset_x = -3 -- DÉCALAGE DEMANDÉ (Gaucher/2-3 pixels)
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= UI STATUS (POUR SAVOIR SI ÇA MARCHE) =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xAA000000).setCornerRadius(10))
statusLayout.setPadding(30, 15, 30, 15)

local statusText = TextView(activity)
statusText.setText("ÉTAT : ATTENTE ACTION")
statusText.setTextColor(Color.WHITE)
statusText.setTextStyle(Typeface.BOLD)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 -- Haut milieu
lpStatus.y = 100
wm.addView(statusLayout, lpStatus)

function updateStatus(msg, color)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if color then statusText.setTextColor(color) end
    end}))
end

-- ================= LOGIQUE SCANNER =================

function getTarget()
    if not Config.is_recording then return nil end
    local img = captureScreen()
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 12 
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    -- Scan de la zone
    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, startX + x, startY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            if math.abs(r - Config.target_R) < Config.tolerance and g < 100 and b < 100 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        updateStatus("🎯 CIBLE DÉTECTÉE !", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    updateStatus("🔍 SCAN EN COURS...", Color.YELLOW)
    return nil
end

-- ================= INTERFACE PRINCIPALE =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0101010).setStroke(3, Color.CYAN).setCornerRadius(20))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

-- BOUTON VISION (CORRIGÉ)
btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    -- On lance dans un nouveau thread pour éviter le freeze
    threads.start(function()
        updateStatus("DEMANDE DE PERMISSION...", Color.CYAN)
        if requestScreenCapture(false) then
            Config.is_recording = true
            updateStatus("✅ VISION ACTIVE", Color.GREEN)
            activity.runOnUiThread(Runnable({run=function() 
                btnRecord.setText("VISION : OK")
                btnRecord.setBackgroundColor(0xFF2E7D32)
            end}))
        else
            updateStatus("❌ PERMISSION REFUSÉE", Color.RED)
        end
    end)
end)
mainView.addView(btnRecord)

-- BOUTON SCAN
btnScan = Button(activity)
btnScan.setText("2. DÉMARRER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then
        updateStatus("⚠️ ACTIVE LA VISION D'ABORD", Color.RED)
        return
    end
    Config.active = not Config.active
    btnScan.setText(Config.active and "STOP AIM" or "DÉMARRER AIM")
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ (DÉCALÉ À GAUCHE)
boxView = View(activity)
local boxDrawable = GradientDrawable()
boxDrawable.setShape(0)
boxDrawable.setColor(0)
boxDrawable.setStroke(4, Color.RED)
boxView.setBackgroundDrawable(boxDrawable)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x -- ICI LE DÉCALAGE DE -3 PIXELS
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

-- ================= BOUCLE FINALE =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        -- Mouvement
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY + Config.recoil)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

updateStatus("LOGICIEL PRÊT", Color.WHITE)