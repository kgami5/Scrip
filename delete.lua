require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"
import "android.content.Context"
import "android.media.projection.MediaProjectionManager"
import "android.media.ImageReader"
import "android.provider.Settings"
import "android.net.Uri"

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    box_size = 280,
    tolerance = 70,
    speed_ms = 40,
    offset_x = -3 -- DÉCALAGE DE 3 PIXELS VERS LA GAUCHE
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= SYSTÈME DE CAPTURE (PROJECTION) =================

local mMediaProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local mMediaProjection = nil

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 and resultCode == -1 then
        mMediaProjection = mMediaProjectionManager.getMediaProjection(resultCode, data)
        if mMediaProjection then
            Config.is_recording = true
            setInfo("✅ VISION INITIALISÉE", Color.GREEN)
            btnRecord.setBackgroundColor(0xFF2E7D32)
        end
    else
        setInfo("❌ AUTORISATION REFUSÉE", Color.RED)
    end
end

-- ================= BARRE DE STATUT =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xCC000000).setCornerRadius(15))
statusLayout.setPadding(30, 20, 30, 20)

local statusText = TextView(activity)
statusText.setText("1. ACTIVEZ LA VISION")
statusText.setTextColor(Color.WHITE)
statusText.setTypeface(Typeface.DEFAULT_BOLD)
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

-- ================= LOGIQUE AIM =================

function getTarget()
    -- Utilise la fonction de capture du système Pocket ZEN / Kgami
    local img = nil
    pcall(function() img = captureScreen() end)
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

            -- Détection du rouge (ennemis)
            if r > 160 and g < 90 and b < 90 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        setInfo("🎯 CIBLE DÉTECTÉE", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    end
    setInfo("🔍 SCAN EN COURS...", Color.YELLOW)
    return nil
end

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        local moveX = (target.x - CX) * 0.8
        local moveY = (target.y - CY) * 0.8
        
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    end
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0101010).setStroke(4, Color.CYAN).setCornerRadius(25))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

btnRecord = Button(activity)
btnRecord.setText("1. ACTIVER VISION")
btnRecord.setOnClickListener(function()
    -- Permission Superposition (pour Oppo/Xiaomi)
    if not Settings.canDrawOverlays(activity) then
        local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        intent.setData(Uri.parse("package:" .. activity.getPackageName()))
        activity.startActivity(intent)
        return
    end
    -- Demande de Projection (comme dans ton script)
    activity.startActivityForResult(mMediaProjectionManager.createScreenCaptureIntent(), 1)
end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. DÉMARRER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        setInfo("⚠️ ACTIVE LA VISION !", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFF2E7D32 or 0xFFC62828)
    if Config.active then handler.post(mainLoop) end
end)
mainView.addView(btnScan)

-- LE CARRÉ DE VISÉE (DÉCALÉ À GAUCHE DE 3 PX)
boxView = View(activity)
local boxStroke = GradientDrawable().setColor(0).setStroke(5, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_x -- POSITION : -3 PIXELS À GAUCHE
pcall(function() wm.addView(boxView, lpBox) end)

-- BOUTON MENU ⚙️
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 200
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
pcall(function() wm.addView(btnMenu, lpBtn) end)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
pcall(function() wm.addView(mainView, lpPanel) end)