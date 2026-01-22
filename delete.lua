require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.util.DisplayMetrics"
import "android.content.Context"

-- On récupère les modules internes sans 'require'
local imgMod = images 

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    box_size = 70,      -- Taille du scan
    speed_ms = 25,      -- Réactivité
    offset_x = -115,    -- TON DÉCALAGE (Viseur à gauche)
    magnet_power = 0.8  -- Force du lock
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Position exacte de TON viseur
local CX = (SW / 2) + Config.offset_x
local CY = SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= UTILS UI =================

local function CreateShape(color, strokeColor)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(10)
    if strokeColor then gd.setStroke(5, strokeColor) end
    return gd
end

-- Barre de statut
local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0xCC000000))
statusLayout.setPadding(30, 15, 30, 15)

local statusText = TextView(activity)
statusText.setText("1. CLIQUE SUR VISION")
statusText.setTextColor(Color.WHITE)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 
lpStatus.y = 100
pcall(function() wm.addView(statusLayout, lpStatus) end)

function setInfo(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE SCANNER =================

function getTarget()
    if not imgMod then return nil end
    
    local img = nil
    pcall(function() img = imgMod.captureScreen() end)
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 4 
    
    local scanX = CX - (Config.box_size / 2)
    local scanY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = imgMod.getPixel(img, scanX + x, scanY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- DÉTECTION VISEUR DEVIENT ROUGE
            if r > 200 and g < 70 and b < 70 then
                sumX = sumX + (scanX + x)
                sumY = sumY + (scanY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        return { x = sumX / count, y = sumY / count }
    end
    return nil
end

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        local moveX = (target.x - CX) * Config.magnet_power
        local moveY = (target.y - CY) * Config.magnet_power
        
        setInfo("🔒 LOCK ACTIF (ROUGE)", Color.RED)
        boxView.setBackgroundDrawable(CreateShape(0, Color.GREEN))

        local s = service or auto
        if s then
            local builder = luajava.bindClass("android.accessibilityservice.GestureDescription$Builder")()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            local stroke = luajava.bindClass("android.accessibilityservice.GestureDescription$StrokeDescription")(p, 0, 45)
            builder.addStroke(stroke)
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        setInfo("🔍 SCAN VISEUR...", Color.WHITE)
        boxView.setBackgroundDrawable(CreateShape(0, Color.RED))
    end
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(CreateShape(0xF0101010, Color.CYAN))
mainView.setPadding(45, 45, 45, 45)
mainView.setVisibility(8)

-- BOUTON VISION (FORCE ACTIVATE)
btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    setInfo("PATIENTEZ... (POPUP ANDROID)", Color.CYAN)
    
    -- On utilise un handler pour laisser Android afficher le popup sans bloquer
    handler.postDelayed(Runnable({run=function()
        local success = false
        pcall(function()
            -- Méthode 1
            success = imgMod.requestScreenCapture(false)
            -- Méthode 2 (secours)
            if not success then
                local mpManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
                activity.startActivityForResult(mpManager.createScreenCaptureIntent(), 1)
            end
        end)
        
        Config.is_recording = true -- On force l'état pour le bouton 2
        btnRecord.setBackgroundColor(0xFF2E7D32)
        btnRecord.setText("VISION : INITIALISÉE")
        setInfo("SI POPUP ACCEPTÉ, CLIQUE SUR START", Color.WHITE)
    end}), 500)
end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START LOCK")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        setInfo("⚠️ ACTIVE LA VISION D'ABORD", Color.YELLOW)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFF2E7D32 or 0xFFC62828)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- Callback de secours pour startActivityForResult
function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 and resultCode == -1 then
        pcall(function() imgMod.requestScreenCapture(false) end)
        setInfo("✅ VISION CONNECTÉE", Color.GREEN)
    end
end

pcall(function() wm.addView(mainView, WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)) end)

-- LE CARRÉ (OFFSET -115)
boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0, Color.RED))
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x 
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