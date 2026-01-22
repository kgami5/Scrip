require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.util.DisplayMetrics"
import "android.content.Context"

-- CHARGEMENT OBLIGATOIRE DU MODULE IMAGES
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
    box_size = 85,      -- Carré petit (juste le viseur)
    tolerance = 50,     -- Sensibilité pour le rouge du viseur
    speed_ms = 20,      -- Ultra réactif
    offset_x = -52,    -- RE-CENTRAGE : Pousse le carré vers la gauche
    magnet_power = 0.8  -- Force du verrouillage
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
-- Centre corrigé pour ton écran
local CX, CY = (SW / 2) + Config.offset_x, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= UTILS =================

local function CreateShape(color, strokeColor)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(5)
    if strokeColor then gd.setStroke(4, strokeColor) end
    return gd
end

-- ================= GESTION CAPTURE =================

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 and resultCode == -1 then
        -- Initialisation propre via le module images
        if images.requestScreenCapture(false) then
            Config.is_recording = true
            setInfo("✅ VISION CONNECTÉE", Color.GREEN)
            btnRecord.setBackgroundDrawable(CreateShape(0xFF2E7D32))
        end
    end
end

-- ================= STATUT =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0xCC000000))
statusLayout.setPadding(30, 10, 30, 10)

local statusText = TextView(activity)
statusText.setText("CLIQUE SUR 1. VISION")
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

-- ================= LOGIQUE RED CROSSHAIR LOCK =================

function getTarget()
    -- FIX : On utilise le module images pour capturer
    local img = images.captureScreen() 
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 4 -- Scan très précis
    
    local scanX = CX - (Config.box_size / 2)
    local scanY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, scanX + x, scanY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- DÉTECTION DU ROUGE DU VISEUR (Vif)
            if r > 210 and g < 60 and b < 60 then
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
        -- Aim assist magnétique
        local moveX = (target.x - CX) * Config.magnet_power
        local moveY = (target.y - CY) * Config.magnet_power
        
        setInfo("🔒 LOCK : ROUGE DÉTECTÉ", Color.parseColor("#FF0000"))
        boxView.setBackgroundDrawable(CreateShape(0, Color.GREEN))

        local s = service or auto
        if s then
            local builder = luajava.bindClass("android.accessibilityservice.GestureDescription$Builder")()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            local stroke = luajava.bindClass("android.accessibilityservice.GestureDescription$StrokeDescription")(p, 0, 40)
            builder.addStroke(stroke)
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        setInfo("🔍 SCAN VISEUR...", Color.WHITE)
        boxView.setBackgroundDrawable(CreateShape(0, Color.RED))
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

-- ================= INTERFACE =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(CreateShape(0xF0101010, Color.CYAN))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    local mManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
    activity.startActivityForResult(mManager.createScreenCaptureIntent(), 1)
end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START AIM LOCK")
btnScan.setOnClickListener(function()
    if not Config.is_recording then return end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFF2E7D32 or 0xFFC62828)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

pcall(function() wm.addView(mainView, WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)) end)

-- LE CARRÉ (DÉCALÉ À -115 PX POUR ÊTRE SUR LE VISEUR BLANC)
boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0, Color.RED))

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x 
pcall(function() wm.addView(boxView, lpBox) end)

local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 250
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
pcall(function() wm.addView(btnMenu, lpBtn) end)