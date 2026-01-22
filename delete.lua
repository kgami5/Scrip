require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.provider.Settings"
import "android.net.Uri"
import "android.accessibilityservice.*"
import "android.util.DisplayMetrics"
import "java.lang.Math"

-- ================= CONFIGURATION FINALE =================
local Config = {
    active = true,
    rapid_fire = true,
    smart_recoil = true,
    aim_assist = true,
    recoil_force = 30,
    scan_force = 20,
    speed_ms = 75,
    box_size = 150,
    box_x = 0,
    box_y = 0,
    is_shooting = false
}

local Pos = { fireX=0, fireY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Positions par défaut
Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= MOTEUR DE GESTES =================

function performAction()
    local s = service or auto -- Support pour différents environnements
    if s == nil then return end
    
    local builder = GestureDescription.Builder()
    local strokeAdded = false

    -- 1. TIR (Rapid Fire)
    if Config.rapid_fire then
        local p1 = Path()
        p1.moveTo(Pos.fireX, Pos.fireY)
        builder.addStroke(GestureDescription.StrokeDescription(p1, 0, 45))
        strokeAdded = true
    end
    
    -- 2. RECUL ET AIM ASSIST
    if Config.smart_recoil or Config.aim_assist then
        local mx = 0
        local my = 0
        if Config.smart_recoil then my = Config.recoil_force end
        if Config.aim_assist then 
            mx = (math.random(-1, 1) * Config.scan_force) 
        end
        
        local p2 = Path()
        p2.moveTo(Pos.camX, Pos.camY)
        p2.lineTo(Pos.camX + mx, Pos.camY + my)
        builder.addStroke(GestureDescription.StrokeDescription(p2, 0, 65))
        strokeAdded = true
    end
    
    if strokeAdded then
        pcall(function() s.dispatchGesture(builder:build(), nil, nil) end)
    end
end

-- ================= UI : CARRÉ CENTRAL (CORTEX) =================
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(3, Color.RED); boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

function updateBoxState()
    if not Config.active then boxPaint.setStroke(2, Color.GRAY)
    elseif Config.is_shooting then boxPaint.setStroke(6, Color.GREEN)
    else boxPaint.setStroke(2, Color.RED) end
    lpBox.x = Config.box_x
    lpBox.y = Config.box_y
    wm.updateViewLayout(boxView, lpBox)
end

-- ================= BOUCLE DE TIR =================
local handler = Handler(Looper.getMainLooper())
local loop = nil
loop = Runnable({ run = function()
    if Config.is_shooting and Config.active then
        performAction()
        updateBoxState()
        handler.postDelayed(loop, Config.speed_ms)
    else
        updateBoxState()
    end
end})

-- ================= INTERCEPTION VOLUME =================
function onKeyDown(code, event)
    if string.find(tostring(event), "KEYCODE_VOLUME_UP") then
        if not Config.is_shooting then
            Config.is_shooting = true
            handler.post(loop)
        end
        return true
    end
end

function onKeyUp(code, event)
    if string.find(tostring(event), "KEYCODE_VOLUME_UP") then
        Config.is_shooting = false
        return true
    end
end

-- ================= CIBLES DE CALIBRAGE DÉPLAÇABLES =================
local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(9); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3); lp.gravity=51; lp.x=x; lp.y=y
    local tx, ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then 
            lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty
            wm.updateViewLayout(v,lp)
            cb(lp.x+60, lp.y+60) 
            return true 
        end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v)
end

createTarget(0x88FF0000, "TIR", Pos.fireX-60, Pos.fireY-60, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x8800FFFF, "CAM", Pos.camX-60, Pos.camY-60, function(x,y) Pos.camX=x; Pos.camY=y end)

-- ================= MENU ET FIX SYSTÈME =================
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(20, 20, 20, 20)
local bgM = GradientDrawable(); bgM.setColor(0xF0101010); bgM.setCornerRadius(20); bgM.setStroke(3, Color.YELLOW)
menu.setBackground(bgM); menu.setVisibility(8)

local scroll = ScrollView(activity); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

-- Section FIX
local t1 = TextView(activity); t1.setText("--- FIX SYSTÈME ---"); t1.setTextColor(Color.CYAN); t1.setGravity(17)
content.addView(t1)

local function addSystemFix(txt, action)
    local btn = Button(activity); btn.setText(txt); btn.setTextSize(10)
    btn.setOnClickListener(function()
        local intent = Intent(action)
        if action == Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS then
            intent.setData(Uri.parse("package:" .. activity.getPackageName()))
        end
        activity.startActivity(intent)
    end)
    content.addView(btn)
end

addSystemFix("1. ACCESSIBILITÉ", Settings.ACTION_ACCESSIBILITY_SETTINGS)
addSystemFix("2. OVERLAY PERMISSION", Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
addSystemFix("3. OPTIMISATION BATTERIE", Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)

-- Section MACRO
local t2 = TextView(activity); t2.setText("\n--- OPTIONS MACRO ---"); t2.setTextColor(Color.YELLOW); t2.setGravity(17)
content.addView(t2)

local function addToggle(txt, key)
    local h = LinearLayout(activity)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    local sw = Switch(activity); sw.setChecked(Config[key])
    sw.setOnCheckedChangeListener({onCheckedChanged=function(_, c) Config[key]=c; updateBoxState() end})
    h.addView(tv); h.addView(sw); content.addView(h)
end

addToggle("ACTIVER TOUT", "active")
addToggle("Rapid Fire", "rapid_fire")
addToggle("Anti-Recul", "smart_recoil")
addToggle("Aim Assist", "aim_assist")

local function addSlider(txt, key, max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[key]); tv.setTextColor(Color.LTGRAY)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[key])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[key]=p; tv.setText(txt..": "..p) end})
    content.addView(tv); content.addView(sk)
end

addSlider("Force Recul", "recoil_force", 100)
addSlider("Vitesse (ms)", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("MASQUER CIBLES"); btnHide.setOnClickListener(function()
    for _,v in pairs(targets) do 
        v.setVisibility(v.getVisibility() == 0 and 8 or 0)
    end
end); content.addView(btnHide)

-- Boutons Flottants
local lpMenu = WindowManager.LayoutParams(600, 800, OVERLAY_TYPE, 8, -3)
lpMenu.gravity = 51; lpMenu.x = 100; lpMenu.y = 200
wm.addView(menu, lpMenu)

local btnM = Button(activity); btnM.setText("⚙️"); btnM.setTextColor(Color.BLACK)
local bgBtn = GradientDrawable(); bgBtn.setColor(0xFFFFFFFF); bgBtn.setShape(1)
btnM.setBackground(bgBtn)
local lpBtnM = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpBtnM.gravity = 51; lpBtnM.x = 30; lpBtnM.y = 100
btnM.setOnClickListener(function()
    menu.setVisibility(menu.getVisibility() == 0 and 8 or 0)
end)
wm.addView(btnM, lpBtnM)

-- Bouton Tir Virtuel
local btnShoot = Button(activity); btnShoot.setText("FIRE")
local bgS = GradientDrawable(); bgS.setColor(0xFFFFD700); bgS.setCornerRadius(100)
btnShoot.setBackground(bgS)
local lpS = WindowManager.LayoutParams(180, 180, OVERLAY_TYPE, 8, -3)
lpS.gravity = 51; lpS.x = SW * 0.85; lpS.y = SH * 0.65
btnShoot.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then Config.is_shooting = true; bgS.setColor(0xFFFF0000); handler.post(loop)
    elseif e.getAction() == 1 then Config.is_shooting = false; bgS.setColor(0xFFFFD700) end
    return true
end)
wm.addView(btnShoot, lpS)

print("✅ TOUT-EN-UN CHARGÉ\n1. Cliquez sur ⚙️\n2. Faites les 3 FIX\n3. Placez les cibles")