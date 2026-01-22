require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- Récupération du module images
local images = nil
pcall(function() images = require "images" end)

local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local Color = luajava.bindClass("android.graphics.Color")
local Path = luajava.bindClass("android.graphics.Path")
local Typeface = luajava.bindClass("android.graphics.Typeface")
local WindowManager = luajava.bindClass("android.view.WindowManager")
local Context = luajava.bindClass("android.content.Context")
local GestureDescription = luajava.bindClass("android.accessibilityservice.GestureDescription")

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    tolerance = 75,
    box_size = 280,
    speed_ms = 40,
    offset_left = -3 -- DÉCALAGE DE 3 PIXELS VERS LA GAUCHE APPLIQUÉ
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= STATUT VISUEL (BARRE EN HAUT) =================

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(GradientDrawable().setColor(0xCC000000).setCornerRadius(15))
statusLayout.setPadding(30, 20, 30, 20)

local statusText = TextView(activity)
statusText.setText("PRÊT - CLIQUE SUR VISION")
statusText.setTextColor(Color.WHITE)
statusText.setTypeface(Typeface.DEFAULT_BOLD)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 
lpStatus.y = 120
wm.addView(statusLayout, lpStatus)

function setInfo(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE SCAN & BOUCLE =================

local handler = Handler(Looper.getMainLooper())

function getTarget()
    if not images then return nil end
    local img = nil
    pcall(function() img = images.captureScreen() end)
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

            -- Cible le rouge
            if r > 165 and g < 90 and b < 90 then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        setInfo("🎯 CIBLE TROUVÉE", Color.GREEN)
        return { x = (sumX / count), y = (sumY / count) }
    end
    setInfo("🔍 RECHERCHE...", Color.YELLOW)
    return nil
end

local mainLoop = nil -- Déclaration préalable
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    if target then
        -- Mouvement Aim
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
    end
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

-- ================= INTERFACE MENU =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(GradientDrawable().setColor(0xF0101010).setStroke(4, Color.CYAN).setCornerRadius(25))
mainView.setPadding(45, 45, 45, 45)
mainView.setVisibility(8)

btnRecord = Button(activity)
btnRecord.setText("1. ACTIVER VISION")
btnRecord.setOnClickListener(function()
    setInfo("ACCEPTE L'AUTORISATION ANDROID", Color.CYAN)
    pcall(function()
        if images and images.requestScreenCapture then
            images.requestScreenCapture(false)
        elseif requestScreenCapture then
            requestScreenCapture(false)
        end
    end)
    Config.is_recording = true
    btnRecord.setBackgroundColor(0xFF2E7D32)
    btnRecord.setText("VISION : INITIALISÉE")
end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then
        setInfo("⚠️ ACTIVE LA VISION D'ABORD !", Color.RED)
        return
    end
    Config.active = not Config.active
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    if Config.active then 
        setInfo("AIM LANCÉ ✅", Color.GREEN)
        handler.post(mainLoop) 
    else
        setInfo("AIM STOPPÉ 🛑", Color.WHITE)
    end
end)
mainView.addView(btnScan)

-- LE CARRÉ DE VISÉE (DÉCALÉ À GAUCHE DE 3 PX)
boxView = View(activity)
boxStroke = GradientDrawable()
boxStroke.setShape(0)
boxStroke.setColor(0)
boxStroke.setStroke(5, Color.RED)
boxView.setBackgroundDrawable(boxStroke)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_left -- DECALAGE APPLIQUÉ
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