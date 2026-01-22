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
import "java.lang.Math" -- Import vital pour la logique Cronus

-- ================= CONFIGURATION CRONUS =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    aim_assist = false,   -- Mode "Avenged V4" (Cercle)
    auto_strafe = false,
    shake_radius = 20,    -- Rayon du cercle Aim Assist
    recoil_force = 30,    -- Force verticale
    speed_ms = 60         -- Vitesse de la boucle
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= MOTEUR MATHEMATIQUE (CRONUS LOGIC) =================

-- Variable pour la rotation (0 à 360 degrés)
local angle_rad = 0

-- Fonction convertie du script GPC (Combo_AimAssistv4)
function getCronusOffset(radius)
    -- On fait avancer l'angle
    angle_rad = angle_rad + 0.8 -- Vitesse de rotation
    if angle_rad > 6.28 then angle_rad = 0 end -- 2*PI

    -- Calcul polaire comme sur le Zen
    local offsetX = Math.cos(angle_rad) * radius
    local offsetY = Math.sin(angle_rad) * radius
    
    return offsetX, offsetY
end

-- ================= GESTURES ANDROID =================

-- 1. TIR SIMPLE
function doTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- 2. MOUVEMENT COMPLEXE (RECUL + AIM ASSIST ROTATIF)
function doCronusMove()
    local p = Path()
    p.moveTo(Pos.centerX, Pos.centerY)
    
    local endX = Pos.centerX
    local endY = Pos.centerY
    
    -- AJOUT AIM ASSIST (Cercle)
    if config.aim_assist then
        local offX, offY = getCronusOffset(config.shake_radius)
        endX = endX + offX
        endY = endY + offY
    end
    
    -- AJOUT RECUL (Vertical constant)
    if config.anti_recoil then
        endY = endY + config.recoil_force
    end
    
    -- Si on a bougé (donc une option est active)
    if endX ~= Pos.centerX or endY ~= Pos.centerY then
        p.lineTo(endX, endY)
        local g = GestureDescription.Builder()
        -- 50ms est le "Sweet Spot" pour que Unity Engine capte le mouvement rotatif
        g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
        pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
    end
end

-- 3. STRAFE (Mouvement Latéral)
function doStrafe()
    local p = Path(); local span = 150
    p.moveTo(Pos.joyX, Pos.joyY)
    -- Mouvement gauche/droite basé sur le temps
    if os.time()%2 == 0 then 
        p.lineTo(Pos.joyX - span, Pos.joyY) 
    else 
        p.lineTo(Pos.joyX + span, Pos.joyY) 
    end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 200))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- BOUCLE PRINCIPALE
local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        
        -- RAPID FIRE (Indépendant)
        if config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        
        -- MOUVEMENT VISEUR (Recul + Aim Assist combinés pour fluidité)
        if config.anti_recoil or config.aim_assist then
            doCronusMove()
        end
        
        -- MOUVEMENT PERSO
        if config.auto_strafe then doStrafe() end
        
        handler.postDelayed(runLoop, config.speed_ms)
    end
end})

-- ================= INTERFACE GRAPHIQUE (UI) =================

-- CIBLES
local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(9); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(120,120,2038,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+60,lp.y+60) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+60,y+60)
end
createTarget(0x88FF0000, "TIR", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x880000FF, "JOY", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- BOUTON FLOTTANT ZEN
local btnZen = Button(activity)
btnZen.setText("ZEN")
btnZen.setTextColor(Color.CYAN)
btnZen.setBackground(GradientDrawable())
btnZen.getBackground().setColor(0xFF222222)
btnZen.getBackground().setCornerRadius(100)
btnZen.getBackground().setStroke(3, Color.CYAN)
local lpZen = WindowManager.LayoutParams(150,150,2038,8,-3)
lpZen.gravity=51; lpZen.x=50; lpZen.y=200

-- MENU
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(20,20,20,20)
local bg = GradientDrawable(); bg.setColor(0xEE000000); bg.setCornerRadius(20); bg.setStroke(2, Color.MAGENTA)
menu.setBackground(bg)
menu.setVisibility(8)

-- SCROLLVIEW INTEGRE
local scroll = ScrollView(activity)
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, SH*0.55)) -- Max 55% hauteur écran
menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1)
scroll.addView(content)

-- Header
local t = TextView(activity); t.setText("CRONUS V11 - POLAR"); t.setTextColor(Color.MAGENTA); t.setTextSize(16); t.setGravity(17)
content.addView(t)

-- Commandes
local function addS(txt,k)
    local s = Switch(activity); s.setText(txt); s.setTextColor(-1); s.setPadding(0,15,0,15)
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.MAGENTA) end end
    end}); content.addView(s)
end
local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addS("MASTER (ON/OFF)", "active")
content.addView(TextView(activity))
addS("🔥 Rapid Fire", "rapid_fire")
addS("📉 Anti-Recoil (Smart)", "anti_recoil")
addS("🌀 Aim Assist (Cronus)", "aim_assist")
addS("🏃 Auto-Strafe", "auto_strafe")

local sep = TextView(activity); sep.setText("\nREGLAGES CRONUS"); sep.setTextColor(Color.YELLOW); content.addView(sep)
addSl("Rayon Cercle (Aim)", "shake_radius", 100)
addSl("Force Recul", "recoil_force", 100)
addSl("Vitesse (ms)", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("CACHER CIBLES"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local lpMenu = WindowManager.LayoutParams(650, WindowManager.LayoutParams.WRAP_CONTENT, 2038, 8, -3)
lpMenu.gravity=51; lpMenu.x=220; lpMenu.y=100

-- LOGIQUE BOUTON ZEN
local zx,zy,zt
btnZen.setOnTouchListener(function(v,e)
    if e.getAction()==0 then zx=e.getRawX()-lpZen.x; zy=e.getRawY()-lpZen.y; zt=System.currentTimeMillis(); return true
    elseif e.getAction()==2 then lpZen.x=e.getRawX()-zx; lpZen.y=e.getRawY()-zy; wm.updateViewLayout(btnZen,lpZen); return true
    elseif e.getAction()==1 and (System.currentTimeMillis()-zt < 250) then
        if menu.getVisibility()==0 then menu.setVisibility(8) else menu.setVisibility(0) end
        return true
    end
    return false
end)

wm.addView(btnZen, lpZen)
wm.addView(menu, lpMenu)
print("✅ V11: ENGINE CRONUS ACTIVÉ")