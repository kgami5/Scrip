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
    box_size = 120,    -- Carré plus petit car on se concentre sur le viseur
    tolerance = 60,     -- Tolérance pour le rouge du viseur
    speed_ms = 25,      -- Vitesse ultra rapide (25ms)
    offset_x = -52,     -- RE-CENTRAGE : Décalage vers la gauche pour aligner le viseur
    lock_strength = 0.9 -- Puissance du magnétisme (0.1 à 1.0)
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = (SW / 2) + Config.offset_x, SH / 2 -- Centre corrigé avec l'offset

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= UTILS DESSIN =================

local function CreateShape(color, strokeColor, strokeWidth)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(10)
    if strokeColor then gd.setStroke(strokeWidth or 4, strokeColor) end
    return gd
end

-- ================= GESTION CAPTURE =================

local mMediaProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local mMediaProjection = nil

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 and resultCode == -1 then
        pcall(function()
            mMediaProjection = mMediaProjectionManager.getMediaProjection(resultCode, data)
        end)
        if mMediaProjection or requestScreenCapture(false) then
            Config.is_recording = true
            setInfo("✅ VISION : CONNECTÉE", Color.GREEN)
        end
    end
end

-- ================= BARRE DE STATUT =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0xCC000000))
statusLayout.setPadding(30, 15, 30, 15)

local statusText = TextView(activity)
statusText.setText("PRÊT - ACTIVE LA VISION")
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

-- ================= LOGIQUE "CROSSHAIR RED LOCK" =================

function getTarget()
    local img = captureScreen() 
    if not img then return nil end

    local sumX, sumY, count = 0, 0, 0
    local step = 6 -- Scan très fin pour le viseur
    
    -- Zone de scan réduite autour du viseur centré
    local scanX = CX - (Config.box_size / 2)
    local scanY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, scanX + x, scanY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- Détection du rouge spécifique du réticule activé
            if r > 200 and g < 70 and b < 70 then
                sumX = sumX + (scanX + x)
                sumY = sumY + (scanY + y)
                count = count + 1
            end
        end
    end

    if count > 1 then
        return { x = sumX / count, y = sumY / count }
    end
    return nil
end

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        -- Calcul du mouvement pour suivre la cible rouge
        local moveX = (target.x - CX) * Config.lock_strength
        local moveY = (target.y - CY) * Config.lock_strength
        
        setInfo("🔒 LOCK : ON TARGET", Color.parseColor("#FF0000"))
        boxView.setBackgroundDrawable(CreateShape(0, Color.GREEN, 8))

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
btnScan.setText("2. START AIM LOCK")
btnScan.setOnClickListener(function()
    if not Config.is_recording then return end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFF2E7D32 or 0xFFC62828)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

pcall(function() wm.addView(mainView, WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)) end)

-- LE CARRÉ (DÉCALÉ À -52 PX POUR ÊTRE SUR LE VISEUR)
boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0, Color.RED, 4))

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