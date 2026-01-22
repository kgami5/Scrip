require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.provider.Settings"
import "android.accessibilityservice.*"
import "android.util.DisplayMetrics"
import "java.lang.Math"
import "android.os.Build"

-- ================= CONFIGURATION ET ETAT =================
local Config = {
    active = true,
    rapid_fire = true,
    smart_recoil = true,
    aim_assist = true,
    recoil_force = 25,
    scan_force = 15,
    speed_ms = 70, -- Vitesse de boucle
    box_size = 150,
    is_shooting = false
}

local Pos = { fireX=0, fireY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Positions par défaut (80% largeur, 70% hauteur pour le tir)
Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= FONCTION DE TIR (CORE) =================

function performAction()
    -- IMPORTANT: 'service' est l'objet d'accessibilité global injecté par l'app
    if not service then 
        -- Si 'service' est nul, on essaie de le récupérer via l'activité
        service = activity.getService() 
        if not service then return end
    end
    
    -- 1. GESTURE BUILDER
    local builder = GestureDescription.Builder()
    
    -- 2. RAPID FIRE (CLIC)
    if Config.rapid_fire then
        local p1 = Path()
        p1.moveTo(Pos.fireX, Pos.fireY)
        builder.addStroke(GestureDescription.StrokeDescription(p1, 0, 40))
    end
    
    -- 3. RECUL ET AIM ASSIST (MOUVEMENT CAMÉRA)
    if Config.smart_recoil or Config.aim_assist then
        local mx = 0
        local my = 0
        
        if Config.smart_recoil then my = my + Config.recoil_force end
        if Config.aim_assist then
            -- Oscillation gauche/droite
            mx = (math.random(-1, 1) * Config.scan_force)
        end
        
        local p2 = Path()
        p2.moveTo(Pos.camX, Pos.camY)
        p2.lineTo(Pos.camX + mx, Pos.camY + my)
        builder.addStroke(GestureDescription.StrokeDescription(p2, 0, 60))
    end
    
    -- 4. ENVOI DES GESTES
    service.dispatchGesture(builder:build(), nil, nil)
end

-- ================= BOUCLE DE TIR =================
local handler = Handler(Looper.getMainLooper())
local loop = nil
loop = Runnable({ 
    run = function()
        if Config.is_shooting and Config.active then
            performAction()
            updateBoxColor(true)
            handler.postDelayed(loop, Config.speed_ms)
        else
            updateBoxColor(false)
        end
    end 
})

-- ================= INTERFACE VISUELLE =================

-- Carré Central
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(4, Color.RED)
boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

function updateBoxColor(shooting)
    if shooting then boxPaint.setStroke(6, Color.GREEN) 
    else boxPaint.setStroke(4, Color.RED) end
    wm.updateViewLayout(boxView, lpBox)
end

-- Bouton de tir flottant (Jaune)
local btnShoot = Button(activity)
btnShoot.setText("TIR")
local bgS = GradientDrawable()
bgS.setColor(0xFFFFD700)
bgS.setCornerRadius(100)
btnShoot.setBackground(bgS)

local lpS = WindowManager.LayoutParams(180, 180, OVERLAY_TYPE, 8, -3)
lpS.gravity = 51; lpS.x = SW * 0.8; lpS.y = SH * 0.6

btnShoot.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then -- Down
        Config.is_shooting = true
        bgS.setColor(0xFFFF0000)
        handler.post(loop)
    elseif e.getAction() == 1 then -- Up
        Config.is_shooting = false
        bgS.setColor(0xFFFFD700)
    end
    return true
end)
wm.addView(btnShoot, lpS)

-- ================= TARGETS DE CALIBRAGE =================
local targets = {}
function createTarget(col, txt, x, y, callback)
    local v = TextView(activity)
    v.setText(txt); v.setGravity(17); v.setTextColor(-1); v.setTextSize(10)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2, -1)
    v.setBackground(gd)
    local lp = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
    lp.gravity = 51; lp.x = x; lp.y = y
    local tx, ty
    v.setOnTouchListener(function(_, e)
        if e.getAction() == 0 then tx = e.getRawX() - lp.x; ty = e.getRawY() - lp.y
        elseif e.getAction() == 2 then 
            lp.x = e.getRawX() - tx; lp.y = e.getRawY() - ty
            wm.updateViewLayout(v, lp)
            callback(lp.x + 60, lp.y + 60)
        end
        return true
    end)
    wm.addView(v, lp)
    table.insert(targets, v)
end

createTarget(0x88FF0000, "BOUTON\nFEU", Pos.fireX-60, Pos.fireY-60, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x8800FFFF, "ZONE\nCAM", Pos.camX-60, Pos.camY-60, function(x,y) Pos.camX=x; Pos.camY=y end)

-- ================= MENU DE RÉGLAGES =================
local menu = LinearLayout(activity)
menu.setOrientation(1)
menu.setPadding(20, 20, 20, 20)
local bgM = GradientDrawable(); bgM.setColor(0xF0101010); bgM.setCornerRadius(20); bgM.setStroke(2, Color.YELLOW)
menu.setBackground(bgM)
menu.setVisibility(8)

local function addToggle(txt, key)
    local h = LinearLayout(activity)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    local sw = Switch(activity); sw.setChecked(Config[key])
    sw.setOnCheckedChangeListener({onCheckedChanged=function(_, c) Config[key]=c end})
    h.addView(tv); h.addView(sw); menu.addView(h)
end

addToggle("Activer Macro", "active")
addToggle("Rapid Fire", "rapid_fire")
addToggle("Anti-Recul", "smart_recoil")
addToggle("Aim Assist", "aim_assist")

local lpMenu = WindowManager.LayoutParams(550, -2, OVERLAY_TYPE, 8, -3)
lpMenu.gravity = 51; lpMenu.x = 50; lpMenu.y = 200
wm.addView(menu, lpMenu)

-- Petit bouton de menu (Engrenage)
local btnM = Button(activity); btnM.setText("⚙️")
local lpBtnM = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpBtnM.gravity = 51; lpBtnM.x = 20; lpBtnM.y = 100
btnM.setOnClickListener(function()
    if menu.getVisibility() == 0 then menu.setVisibility(8) else menu.setVisibility(0) end
end)
wm.addView(btnM, lpBtnM)

-- ================= INITIALISATION =================
print("🔥 V24 PRO CHARGÉE")
print("1. Activez l'Accessibilité")
print("2. Placez les cibles rouges/bleues sur vos touches")
print("3. Appuyez sur le bouton JAUNE pour tirer")