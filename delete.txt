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

-- ================= CONFIGURATION =================
local Config = {
    active = true,
    rapid_fire = true,
    smart_recoil = true,
    aim_assist = true,
    recoil_force = 25,
    scan_force = 15,
    speed_ms = 70,
    box_size = 150,
    is_shooting = false
}

local Pos = { fireX=0, fireY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= MOTEUR DE CLIC =================

function performAction()
    -- On cherche l'instance du service d'accessibilité (auto ou service)
    local s = service or auto 
    
    if s == nil then return end -- Si pas de service, on ne fait rien
    
    local builder = GestureDescription.Builder()
    local strokeAdded = false

    -- 1. CLIC DE TIR
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
        if Config.aim_assist then mx = (math.random(-1, 1) * Config.scan_force) end
        
        local p2 = Path()
        p2.moveTo(Pos.camX, Pos.camY)
        p2.lineTo(Pos.camX + mx, Pos.camY + my)
        builder.addStroke(GestureDescription.StrokeDescription(p2, 0, 65))
        strokeAdded = true
    end
    
    if strokeAdded then
        s.dispatchGesture(builder:build(), nil, nil)
    end
end

-- ================= BOUCLE ET UI =================
local handler = Handler(Looper.getMainLooper())
local loop = nil
loop = Runnable({ run = function()
    if Config.is_shooting and Config.active then
        performAction()
        handler.postDelayed(loop, Config.speed_ms)
    end
end})

-- Bouton Tir (Jaune)
local btnShoot = Button(activity)
btnShoot.setText("TIR")
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

-- ================= MENU ET FIX SYSTEME =================
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(30, 30, 30, 30)
local bgM = GradientDrawable(); bgM.setColor(0xF0151515); bgM.setCornerRadius(20); bgM.setStroke(3, Color.CYAN)
menu.setBackground(bgM); menu.setVisibility(8)

-- Fonction pour créer des boutons de réglages système
local function addSystemFix(txt, action)
    local btn = Button(activity); btn.setText(txt); btn.setTextSize(10)
    btn.setOnClickListener(function()
        local intent = Intent(action)
        if action == Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS then
            intent.setData(Uri.parse("package:" .. activity.getPackageName()))
        end
        activity.startActivity(intent)
    end)
    menu.addView(btn)
end

local title = TextView(activity); title.setText("--- FIX SYSTÈME ---"); title.setTextColor(Color.CYAN); title.setGravity(17)
menu.addView(title)

addSystemFix("1. ACTIVER ACCESSIBILITÉ", Settings.ACTION_ACCESSIBILITY_SETTINGS)
addSystemFix("2. AUTORISER OVERLAY", Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
addSystemFix("3. STOP OPTIMISATION BATTERIE", Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)

local title2 = TextView(activity); title2.setText("\n--- OPTIONS MACRO ---"); title2.setTextColor(Color.WHITE); title2.setGravity(17)
menu.addView(title2)

local function addToggle(txt, key)
    local h = LinearLayout(activity)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    local sw = Switch(activity); sw.setChecked(Config[key])
    sw.setOnCheckedChangeListener({onCheckedChanged=function(_, c) Config[key]=c end})
    h.addView(tv); h.addView(sw); menu.addView(h)
end

addToggle("Rapid Fire", "rapid_fire")
addToggle("Anti-Recul", "smart_recoil")

-- Bouton d'ouverture Menu
local lpMenu = WindowManager.LayoutParams(600, -2, OVERLAY_TYPE, 8, -3)
lpMenu.gravity = 51; lpMenu.x = 50; lpMenu.y = 300
wm.addView(menu, lpMenu)

local btnM = Button(activity); btnM.setText("⚙️ FIX")
local lpBtnM = WindowManager.LayoutParams(150, 100, OVERLAY_TYPE, 8, -3)
lpBtnM.gravity = 51; lpBtnM.x = 20; lpBtnM.y = 100
btnM.setOnClickListener(function()
    if menu.getVisibility() == 0 then menu.setVisibility(8) else menu.setVisibility(0) end
end)
wm.addView(btnM, lpBtnM)

print("✅ SCRIPT CHARGÉ : Utilisez le bouton ⚙️ FIX pour tout autoriser")