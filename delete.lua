require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.util.DisplayMetrics"

-- CLASSES ANDROID
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
    box_size = 300,
    speed_ms = 40,
    recoil = 20,
    offset_left = -3 -- Le carré est poussé de 3px vers la gauche
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= UTILS DESSIN =================

local function CreateShape(col, strokeCol)
    local gd = GradientDrawable()
    gd.setShape(0)
    gd.setColor(col)
    gd.setCornerRadius(10)
    if strokeCol then gd.setStroke(4, strokeCol) end
    return gd
end

-- ================= INTERFACE DE STATUS (NOUVEAU) =================
-- Cette petite barre en haut vous dira tout ce qu'il se passe

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0x88000000)) -- Fond noir semi-transparent
statusLayout.setPadding(20, 10, 20, 10)

local statusText = TextView(activity)
statusText.setText("STATUT: ATTENTE INITIALISATION...")
statusText.setTextColor(Color.WHITE)
statusText.setTextSize(12)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49 -- Top Center
lpStatus.y = 50
wm.addView(statusLayout, lpStatus)

function updateStatus(txt, color)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(txt)
        if color then statusText.setTextColor(color) end
    end}))
end

-- ================= LOGIQUE SCANNER =================

function getTarget()
    local img = captureScreen()
    if not img then 
        updateStatus("⚠️ ERREUR: CAPTURE IMPOSSIBLE", Color.RED)
        return nil 
    end

    local sumX, sumY, count = 0, 0, 0
    local step = 12 
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            local px = images.getPixel(img, startX + x, startY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            local diff = math.abs(r - Config.target_R) + math.abs(g - Config.target_G) + math.abs(b - Config.target_B)

            if diff < Config.tolerance then
                sumX = sumX + (startX + x)
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 0 then
        updateStatus("🎯 CIBLE DÉTECTÉE ("..count.." px)", Color.GREEN)
        return { x = sumX / count, y = sumY / count }
    else
        updateStatus("🔍 SCAN EN COURS... (AUCUNE CIBLE)", Color.YELLOW)
        return nil
    end
end

-- ================= MENU DE CONTROLE =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(CreateShape(0xF0151515, Color.CYAN))
mainView.setPadding(40, 40, 40, 40)
mainView.setVisibility(8)

-- Titre
local t = TextView(activity)
t.setText("SENSEI AIM - CONFIG")
t.setTextColor(Color.CYAN)
t.setGravity(1)
mainView.addView(t)

-- Bouton Record
btnRecord = Button(activity)
btnRecord.setText("1. ALLUMER VISION")
btnRecord.setOnClickListener(function()
    if requestScreenCapture(false) then
        Config.is_recording = true
        btnRecord.setText("✅ VISION ACTIVE")
        btnRecord.setBackgroundColor(0xFF2E7D32)
        updateStatus("VISION ACTIVE - PRÊT AU SCAN", Color.CYAN)
    else
        print("Erreur Record")
    end
end)
mainView.addView(btnRecord)

-- Bouton Scan
btnScan = Button(activity)
btnScan.setText("2. DÉMARRER AIM")
btnScan.setOnClickListener(function()
    if not Config.is_recording then 
        updateStatus("❌ CLIQUE SUR VISION D'ABORD !", Color.RED)
        return 
    end
    Config.active = not Config.active
    btnScan.setText(Config.active and "STOP AIM" or "DÉMARRER AIM")
    btnScan.setBackgroundColor(Config.active and 0xFFC62828 or 0xFF1565C0)
    
    if Config.active then 
        handler.post(mainLoop) 
    else
        updateStatus("AIM EN PAUSE", Color.WHITE)
    end
end)
mainView.addView(btnScan)

-- Carré de visée (Décalé de 3px à gauche)
boxView = View(activity)
boxStroke = CreateShape(0, Color.RED)
boxView.setBackgroundDrawable(boxStroke)
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
lpBox.x = Config.offset_left -- DECALAGE ICI
wm.addView(boxView, lpBox)

-- Bouton Menu Flottant (⚙️)
local btnMenu = Button(activity)
btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 250
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

-- ================= BOUCLE PRINCIPALE =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    
    if target then
        local moveX = (target.x - CX) * 0.75
        local moveY = (target.y - CY) * 0.75
        
        boxStroke.setStroke(6, Color.GREEN)

        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY + Config.recoil)
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxStroke.setStroke(2, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

print("✅ Interface de monitoring chargée.")
print("✅ Carré décalé de 3px à gauche.")