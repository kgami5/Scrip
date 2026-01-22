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

-- ================= CONFIGURATION SYSTEME =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    aim_assist = false,
    auto_strafe = false,
    recoil_force = 15,    -- Sensi 140 = Valeur basse (10-20)
    fire_rate = 100       -- 100ms = Plus lent mais plus fiable pour le jeu
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= MOTEUR "UNITY COMPATIBLE" =================
-- Le secret : On augmente la durée (duration) pour que le jeu capte le mouvement

function gameTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    -- 40ms : Durée minimale pour qu'un clic soit validé par CODM
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function gameRecoil(force)
    local p = Path()
    -- On part du centre
    p.moveTo(Pos.centerX, Pos.centerY)
    -- On descend vers le bas
    p.lineTo(Pos.centerX, Pos.centerY + force)
    
    local g = GestureDescription.Builder()
    -- 50ms : C'est un "Drag" humain. Moins que ça, le jeu l'ignore souvent.
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function gameAimAssist()
    -- Shake horizontal (Gauche Droite) pour activer l'aim assist
    local p = Path()
    local shake = 10 
    p.moveTo(Pos.centerX, Pos.centerY)
    p.lineTo(Pos.centerX + shake, Pos.centerY)
    p.lineTo(Pos.centerX - shake, Pos.centerY)
    
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 60))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function gameStrafe()
    local p = Path(); local span = 200
    p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 300)) -- Strafe long
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= INDICATEUR D'ETAT (Status) =================
-- Permet de savoir si le script tourne
local statusText = nil -- Sera défini plus bas

local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        -- Feedback visuel (Clignote Vert/Rouge)
        if statusText then statusText.setTextColor(Color.RED) end
        
        -- EXECUTION DES ACTIONS
        if config.rapid_fire then gameTap(Pos.fireX, Pos.fireY) end
        
        if config.anti_recoil then 
            -- On combine Aim Assist et Recul pour éviter les conflits
            if config.aim_assist then
                 -- Petit saut bas + coté
                 gameRecoil(config.recoil_force)
                 gameAimAssist()
            else
                 gameRecoil(config.recoil_force)
            end
        end
        
        if config.auto_strafe then gameStrafe() end
        
        -- Remet le texte en vert après un court instant
        handler.postDelayed(function() if statusText then statusText.setTextColor(Color.GREEN) end end, 50)
        
        handler.postDelayed(runLoop, config.fire_rate)
    end
end})

-- ================= UI (INTERFACE CORRIGÉE) =================

-- 1. CIBLES (TARGETS)
local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(10); v.setTextColor(Color.BLACK)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,Color.WHITE); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(120,120,2038,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+60,lp.y+60) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+60,y+60)
end
createTarget(0xAAFF0000, "TIR\n(Place ici)", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0xAA0000FF, "JOY\n(Place ici)", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- 2. MENU FLOTTANT (FIXED SCROLL)
local mainLayout = LinearLayout(activity); mainLayout.setOrientation(1)
local bg = GradientDrawable(); bg.setColor(0xEE1a1a1a); bg.setCornerRadius(30); bg.setStroke(4, 0xFF6200EA); 
mainLayout.setBackground(bg)
mainLayout.setPadding(20,20,20,20)

-- HEADER
local headerBox = LinearLayout(activity); headerBox.setOrientation(0); headerBox.setGravity(16)
local title = TextView(activity); title.setText("ZEN V9 FIX"); title.setTextColor(Color.CYAN); title.setTextSize(16); title.setTypeface(Typeface.DEFAULT_BOLD)
statusText = TextView(activity); statusText.setText(" ●"); statusText.setTextColor(Color.GRAY); statusText.setTextSize(20)
headerBox.addView(title); headerBox.addView(statusText)
mainLayout.addView(headerBox)

-- SCROLLVIEW (TAILLE FIXE)
local scroll = ScrollView(activity)
-- IMPORTANT : On force la hauteur du scroll à 400 pixels pour être sûr qu'on peut scroller
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 500)) 
scroll.setFillViewport(true)
mainLayout.addView(scroll)

-- CONTENU DU SCROLL
local content = LinearLayout(activity); content.setOrientation(1)
scroll.addView(content)

-- FONCTIONS UI
local function addS(t,k)
    local s = Switch(activity); s.setText(t); s.setTextColor(-1); s.setPadding(0,15,0,15)
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then 
            if c then handler.post(runLoop) statusText.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) statusText.setTextColor(Color.GRAY) end 
        end
    end}); content.addView(s)
end

local function addSl(t,k,max)
    local tv = TextView(activity); tv.setText(t..": "..config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(t..": "..p) end}); content.addView(sk)
end

-- REMPLISSAGE
addS("✅ ACTIVER (MASTER)", "active")
content.addView(TextView(activity)) -- Espace
addS("🔥 Rapid Fire", "rapid_fire")
addS("📉 Anti-Recoil", "anti_recoil")
addS("🎯 Aim Assist (Shake)", "aim_assist")
addS("🏃 Auto-Strafe", "auto_strafe")

local sep = TextView(activity); sep.setText("\nREGLAGES (SCROLL EN BAS ↓)"); sep.setTextColor(Color.MAGENTA); content.addView(sep)

addSl("Force Recul (10-50)", "recoil_force", 100)
addSl("Délai (ms)", "fire_rate", 300)

local btnHide = Button(activity); btnHide.setText("CACHER CIBLES"); btnHide.setOnClickListener(function()
    for _,t in pairs(targets) do if t.getVisibility()==0 then t.setVisibility(8) else t.setVisibility(0) end end
end); content.addView(btnHide)

local btnClose = Button(activity); btnClose.setText("FERMER MENU"); btnClose.setTextColor(Color.RED); btnClose.setOnClickListener(function()
    mainLayout.setVisibility(8)
end); content.addView(btnClose)

-- MINI BOUTON POUR ROUVRIR
local mini = Button(activity); mini.setText("ZEN"); mini.setBackgroundColor(0xFF6200EA); mini.setTextColor(-1)
mini.setLayoutParams(WindowManager.LayoutParams(150,150,2038,8,-3))
local lpMini = WindowManager.LayoutParams(150,150,2038,8,-3); lpMini.gravity=51; lpMini.x=0; lpMini.y=200

mini.setOnClickListener(function()
    if mainLayout.getVisibility()==0 then mainLayout.setVisibility(8) else mainLayout.setVisibility(0) end
end)
-- Drag mini
local mx,my
mini.setOnTouchListener(function(v,e)
    if e.getAction()==0 then mx=e.getRawX()-lpMini.x; my=e.getRawY()-lpMini.y return true
    elseif e.getAction()==2 then lpMini.x=e.getRawX()-mx; lpMini.y=e.getRawY()-my; wm.updateViewLayout(mini,lpMini) return true end
    return false
end)

-- WINDOW MANAGER MENU
local lpMenu = WindowManager.LayoutParams(600, WindowManager.LayoutParams.WRAP_CONTENT, 2038, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=100

-- Drag Menu
local dx,dy
headerBox.setOnTouchListener(function(v,e)
    if e.getAction()==0 then dx=e.getRawX()-lpMenu.x; dy=e.getRawY()-lpMenu.y return true
    elseif e.getAction()==2 then lpMenu.x=e.getRawX()-dx; lpMenu.y=e.getRawY()-dy; wm.updateViewLayout(mainLayout,lpMenu) return true end
    return false
end)

wm.addView(mini, lpMini)
wm.addView(mainLayout, lpMenu)
print("✅ V9 CHARGÉE - Teste le Point Vert !")