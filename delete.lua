require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.util.DisplayMetrics"

-- FORÇAGE DES CLASSES (Indispensable pour éviter l'erreur nil graphics)
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

-- ================= FONCTION DE DESSIN CORRIGÉE =================

local function CreateShape(col, strokeCol)
    local gd = GradientDrawable()
    gd.setShape(0) -- Rectangle
    gd.setColor(col)
    gd.setCornerRadius(20)
    if strokeCol then
        gd.setStroke(3, strokeCol)
    end
    return gd
end

-- ================= FONCTIONS SYSTÈME =================

function startRecording()
    pcall(function()
        if requestScreenCapture(false) then 
            Config.is_recording = true
            btnRecord.setText("RECORD: OK")
            btnRecord.setBackgroundDrawable(CreateShape(0xFF4CAF50))
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
    Config.active = not Config.active -- Toggle ON/OFF
    btnScan.setText(Config.active and "SCAN: ON" or "SCAN: OFF")
    btnScan.setBackgroundDrawable(Config.active and CreateShape(0xFF4CAF50) or CreateShape(0xFFF44336))
    if Config.active then handler.post(mainLoop) end
end

-- ================= LOGIQUE AIM (PIXELS) =================

function getTarget()
    local img = captureScreen()
    if not img then return nil end

    local leftX, rightX, sumY, count = nil, nil, 0, 0
    local step = 12 -- Plus rapide
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)

    for y = 0, Config.box_size, step do
        for x = 0, Config.box_size, step do
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

-- ================= UI =================

local mainView = LinearLayout(activity)
mainView.setOrientation(1)
mainView.setBackgroundDrawable(CreateShape(0xEF101010, Color.CYAN))
mainView.setPadding(30, 30, 30, 30)
mainView.setVisibility(8)

btnRecord = Button(activity)
btnRecord.setText("1. START RECORD")
btnRecord.setOnClickListener(function() startRecording() end)
mainView.addView(btnRecord)

btnScan = Button(activity)
btnScan.setText("2. START SCAN")
btnScan.setOnClickListener(function() startScan() end)
mainView.addView(btnScan)

function addSlider(label, min, max, current, cb)
    local t = TextView(activity); t.setText(label.." : "..current); t.setTextColor(-1)
    local s = SeekBar(activity); s.setMax(max-min); s.setProgress(current-min)
    s.setOnSeekBarChangeListener({onProgressChanged=function(_,p)
        local v=p+min; t.setText(label.." : "..v); cb(v)
    end})
    mainView.addView(t); mainView.addView(s)
end

addSlider("ROUGE", 0, 255, Config.target_R, function(v) Config.target_R = v end)
addSlider("TOLÉRANCE", 10, 200, Config.tolerance, function(v) Config.tolerance = v end)

local lpPanel = WindowManager.LayoutParams(650, -2, OVERLAY_TYPE, 8, -3)
lpPanel.gravity = 17
wm.addView(mainView, lpPanel)

local btnMenu = Button(activity); btnMenu.setText("⚙️")
local lpBtn = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 20; lpBtn.y = 200
btnMenu.setOnClickListener(function()
    mainView.setVisibility(mainView.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnMenu, lpBtn)

-- Carré de visée central
boxView = View(activity)
boxPaint = CreateShape(0, Color.RED)
boxView.setBackgroundDrawable(boxPaint)
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

-- ================= BOUCLE FINALE AVEC GESTES =================

local handler = Handler(Looper.getMainLooper())
mainLoop = Runnable({ run = function()
    if not Config.active then return end
    
    local target = getTarget()
    local moveX, moveY = 0, 0
    
    if target then
        -- Calcul du mouvement (Magnet)
        moveX = (target.x - CX) * 0.75
        moveY = (target.y - CY) * 0.75
        boxPaint.setStroke(6, Color.GREEN)
        
        -- EXECUTION DU GESTE (Le Magnétisme réel)
        local s = service or auto
        if s then
            local builder = GestureDescription.Builder()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY + Config.recoil) -- Ajout du recul si besoin
            builder.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
            s.dispatchGesture(builder.build(), nil, nil)
        end
    else
        boxPaint.setStroke(2, Color.RED)
    end
    
    handler.postDelayed(mainLoop, Config.speed_ms)
end})

print("✅ TOUT CORRIGÉ. Prêt à l'emploi.")