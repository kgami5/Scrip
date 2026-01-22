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

-- ================= GAMELOOP FIX =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= CORTEX AI (MEMOIRE & LOGIQUE) =================
local Cortex = {
    active = false,
    learning = true,      -- Mode apprentissage activé
    firing_time = 0,      -- Durée du tir actuel
    memory_recoil = 0,    -- Ajustement dynamique
    state = "VEILLE",     -- État du cerveau
    box_offset_x = 0,     -- Correction manuelle centre X
    box_offset_y = 0      -- Correction manuelle centre Y
}

local Config = {
    rapid_fire = false,
    smart_recoil = false, -- Recul adaptatif
    aim_assist = false,
    auto_strafe = false,
    base_force = 30,
    speed_ms = 50
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
-- Centre théorique (sera ajusté par le calibrage)
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= VISUAL CORTEX (Le Carré) =================
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(3, Color.RED) -- Rouge par défaut (Scanning)
boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
local lpBox = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 24, -3) -- 24=NotTouchable
lpBox.gravity = 17 -- Center Gravity
wm.addView(boxView, lpBox)

-- Fonction pour mettre à jour la couleur du cerveau
function updateCortexState(isFiring)
    if isFiring then
        boxPaint.setStroke(5, Color.GREEN) -- VERROUILLÉ (Tir en cours)
        Cortex.state = "LOCKED"
    else
        boxPaint.setStroke(2, Color.RED) -- SCANNING (Recherche)
        Cortex.state = "SCAN..."
        Cortex.firing_time = 0 -- Reset mémoire quand on arrête de tirer
    end
end

-- Fonction pour déplacer le carré (Calibrage)
function updateBoxPosition()
    lpBox.x = Cortex.box_offset_x
    lpBox.y = Cortex.box_offset_y
    wm.updateViewLayout(boxView, lpBox)
    -- Met à jour le centre logique pour le script
    Pos.centerX = (SW/2) + Cortex.box_offset_x
    Pos.centerY = (SH/2) + Cortex.box_offset_y
end

-- ================= MOTEUR INTELLIGENT =================

function smartRecoilEngine()
    -- C'est ici que l'IA simule l'adaptation
    Cortex.firing_time = Cortex.firing_time + 1
    
    local dynamic_force = Config.base_force
    
    -- PHASE 1 : Le "Kick" initial (les 5 premières balles montent vite)
    if Cortex.firing_time < 5 then
        dynamic_force = Config.base_force * 1.2
        
    -- PHASE 2 : Stabilisation (le recul se calme)
    elseif Cortex.firing_time < 15 then
        dynamic_force = Config.base_force
        
    -- PHASE 3 : Chaos (l'arme bouge sur les côtés, on ajoute du Jitter)
    else
        -- Ajoute un mouvement aléatoire gauche/droite pour contrer le spray horizontal
        local jitter = Math.random(-10, 10)
        doGest(Pos.centerX + jitter, Pos.centerY + (Config.base_force * 0.8))
        return -- On sort pour utiliser le geste custom
    end
    
    doGest(Pos.centerX, Pos.centerY + dynamic_force)
end

function doGest(x, y)
    local p = Path(); p.moveTo(Pos.centerX, Pos.centerY); p.lineTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- BOUCLE NEURONALE
local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if Cortex.active then
        
        -- Si RapidFire ou Recoil activé, on considère qu'on tire
        local isAction = Config.rapid_fire or Config.smart_recoil
        updateCortexState(isAction)
        
        if Config.rapid_fire then 
            doTap(Pos.fireX, Pos.fireY) 
        end
        
        if Config.smart_recoil then 
            smartRecoilEngine() 
        end
        
        if Config.aim_assist then
            -- Mouvement hélicoïdal pour "accrocher" l'aim assist
            local t = os.clock() * 5
            local offX = Math.cos(t) * 20
            local offY = Math.sin(t) * 20
            doGest(Pos.centerX + offX, Pos.centerY + offY)
        end
        
        handler.postDelayed(runLoop, Config.speed_ms)
    else
        updateCortexState(false)
    end
end})

-- ================= UI "IRON MAN" EDITION =================

local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(10); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(110,110,OVERLAY_TYPE,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+55,lp.y+55) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+55,y+55)
end
createTarget(0x88FF0000, "TIR", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x880000FF, "JOY", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- BOUTON NEURAL (Launch)
local btnZen = Button(activity); btnZen.setText("🧠"); btnZen.setTextSize(20)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF110022); bgZen.setCornerRadius(100); bgZen.setStroke(3, Color.CYAN)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(140,140,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=200

-- MENU LARGE (FIX)
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(15,15,15,15)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE050505); bgMenu.setCornerRadius(15); bgMenu.setStroke(2, Color.CYAN)
menu.setBackground(bgMenu); menu.setVisibility(8)

-- ScrollView
local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 500)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

-- Header
local t = TextView(activity); t.setText("CORTEX AI V16"); t.setTextColor(Color.CYAN); t.setTextSize(16); t.setGravity(17); content.addView(t)
local status = TextView(activity); status.setText("STATUS: VEILLE"); status.setTextColor(Color.DKGRAY); status.setGravity(17); content.addView(status)

-- Controls
local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(14); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) 
        if k=="active" then 
            Cortex.active = c
            if c then handler.post(runLoop) status.setText("STATUS: ONLINE") status.setTextColor(Color.GREEN)
            else handler.removeCallbacks(runLoop) status.setText("STATUS: OFFLINE") status.setTextColor(Color.RED) end
        else
            Config[k]=c 
        end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

addS("ACTIVATION (MASTER)", "active")
content.addView(TextView(activity))
addS("Smart Recoil (Memory)", "smart_recoil")
addS("Aim Assist (Spiral)", "aim_assist")
addS("Rapid Fire", "rapid_fire")

-- CALIBRATION DU CARRE (NOUVEAU)
local sep = TextView(activity); sep.setText("\nCALIBRAGE CARRE (VISUEL)"); sep.setTextColor(Color.YELLOW); sep.setGravity(17); content.addView(sep)

local function addCalib(txt, axis)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(17)
    local btnM = Button(activity); btnM.setText("←"); btnM.setOnClickListener(function() 
        if axis=="x" then Cortex.box_offset_x=Cortex.box_offset_x-5 else Cortex.box_offset_y=Cortex.box_offset_y-5 end
        updateBoxPosition()
    end)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setPadding(20,0,20,0)
    local btnP = Button(activity); btnP.setText("→"); btnP.setOnClickListener(function() 
        if axis=="x" then Cortex.box_offset_x=Cortex.box_offset_x+5 else Cortex.box_offset_y=Cortex.box_offset_y+5 end
        updateBoxPosition()
    end)
    h.addView(btnM); h.addView(tv); h.addView(btnP); content.addView(h)
end

addCalib("Position X (Gauche/Droite)", "x")
addCalib("Position Y (Haut/Bas)", "y")

-- REGLAGES FORCE
local sep2 = TextView(activity); sep2.setText("\nPUISSANCE CORTEX"); sep2.setTextColor(Color.MAGENTA); sep2.setGravity(17); content.addView(sep2)

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addSl("Force Base Recul", "base_force", 100)
addSl("Vitesse Scan (ms)", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("CACHER CIBLES SETUP"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local lpMenu = WindowManager.LayoutParams(650, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=50

-- Logique Bouton
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
print("✅ CORTEX AI V16: Neural Engine Loaded")