require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.util.DisplayMetrics"

-- FORÇAGE DES CLASSES (Correction de l'erreur nil graphics)
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local Color = luajava.bindClass("android.graphics.Color")
local Path = luajava.bindClass("android.graphics.Path")
local WindowManager = luajava.bindClass("android.view.WindowManager")

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    is_recording = false,
    aim_assist = true,
    rapid_fire = true,
    target_R = 255, target_G = 0, target_B = 0,
    tolerance = 60,
    box_size = 300,
    recoil = 30,
    speed_ms = 45,
    is_shooting = false
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = SW / 2, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= FONCTIONS SYSTÈME =================

function startRecording()
    -- Cette fonction appelle l'activité de capture définie dans ton manifest
    -- Note: Selon ton moteur Lua, l'appel peut varier
    pcall(function()
        if requestScreenCapture(false) then 
            Config.is_recording = true
            btnRecord.setText("RECORD: OK")
            btnRecord.setBackgroundColor(0xFF4CAF50)
            print("✅ Vision prête")
        else
            print("❌ Échec Record")
        end
    end)
end

function startScan()
    if not Config.is_recording then
        print("⚠️ Active RECORD d'abord")
        return
    end
    Config.active = true
    handler.post(mainLoop)
    btnScan.setText("SCAN: ON")
    btnScan.setBackgroundColor(0xFF4CAF50)
    boxView.setVisibility(0)
end

-- ================= LOGIQUE AIM (PIXELS) =================

function getTarget()
    local img = captureScreen()
    if not img then return nil end

    local leftX, rightX, sumY, count = nil, nil, 0, 0
    local step = 10
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
            -- Utilisation sécurisée de getPixel
            local px = images.getPixel(img, startX + x, startY + y)
            local r = math.abs(Color.red(px) - Config.target_R)
            local g = math.abs(Color.green(px) - Config.target_G)
            local b = math.abs(Color.blue(px) - Config.target_B)

            if (r + g + b) < Config.tolerance then
                local cx = startX + x
                if not leftX or cx < leftX then leftX = cx end
                if not rightX or cx > rightX then rightX = cx end
                sumY = sumY + (startY + y)
                count = count + 1
            end
        end
    end

    if count > 2 and leftX then
        return { x = (leftX + rightX) / 2, y = sumY / count }
    end
    return nil
end

-- ================= UI (CORRIGÉE) =================


local function CreateShape(color, strokeCol, strokeWidth)
    local gd = GradientDrawable() -- Appelle la classe liée plus haut
    gd.setShape(0) -- 0 = Rectangle
    gd.setColor(color)
    gd.setCornerRadius(20)
    if strokeCol then 
        gd.setStroke(strokeWidth or 3, strokeCol) 
    end
    return gd
end



-- Correction de l'erreur GradientDrawable : on utilise le chemin complet
local function getShape(col)
    local gd = android.graphics.drawable.GradientDrawable()
    gd.setColor(col)
    gd.setCornerRadius(20)
    gd.setStroke(3, Color.CYAN)
    return gd
end

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackground(getShape(0xEF101010)) -- Utilise la fonction corrigée
mainView.setPadding(30, 30, 30, 30)
mainView.setVisibility(8)

-- Boutons Record & Scan
btnRecord = Button(activity)
btnRecord.setText("1. START RECORD")
btnRecord.setOnClickListener(function() startRecording() end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START SCAN")
btnScan.setOnClickListener(function() startScan() end)
mainView.addView(btnScan)

-- Sliders
function addSlider(label, min, max, current, cb)
    local t = TextView(activity); t.setText(label.." : "..current); t.setTextColor(-1)
    local s = SeekBar(activity); s.setMax(max-min); s.setProgress(current-min)
    s.setOnSeekBarChangeListener({onProgressChanged=function(_,p)
        local v=p+min; t.setText(label.." : "..v); cb(v)
    end})
    mainView.addView(t); mainView.addView(s)
end

addSlider("ROUGE", 0, 255, Config.target_R, function(v) Config.target_R = v end)
addSlider("TOLÉRANCE", 10, 150, Config.tolerance, function(v) Config.tolerance = v end)

-- Overlay du menu
local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

-- Bouton d'ouverture ⚙️
local btnMenu = Button(activity); btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 200
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

-- Carré de visée
-- Carré de visée central
boxView = View(activity)
boxPaint = GradientDrawable() -- Utilisation directe de la classe liée
boxPaint.setShape(0)
boxPaint.setStroke(3, Color.RED)
boxPaint.setColor(0) -- Transparent

boxView.setBackground(boxPaint)

local lpBox = WindowManager.LayoutParams(
    Config.box_size, 
    Config.box_size, 
    OVERLAY_TYPE, 
    24, 
    -3
)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

-- ================= BOUCLE FINALE =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    local moveX, moveY = 0, 0
    
    if target then
        moveX = (target.x - CX) * 0.7
        moveY = (target.y - CY) * 0.7
        boxPaint.setStroke(5, Color.GREEN)
    else
        boxPaint.setStroke(2, Color.RED)
    end
    
    -- Simulation de geste (DispatchGesture)
    -- [Insérer ici ta logique dispatchGesture habituelle]
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

print("✅ Fix appliqué. Ouvrez le menu avec ⚙️")