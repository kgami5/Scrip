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

-- ================= CONFIGURATION PREDATOR =================
local config = {
    active = false,
    rapid_fire = false,
    smart_recoil = false,
    aim_assist = false, -- Mode Balayage (Sticky)
    auto_strafe = false,
    scan_force = 20,    -- Force du balayage caméra
    recoil_force = 25,
    speed_ms = 50
}

-- Positions : Fire (Tir), Joy (Déplacement), Cam (Zone Vide)
local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Position par défaut de la zone vide (Milieu Droite)
Pos.camX = SW * 0.75
Pos.camY = SH * 0.5

local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= VISUAL BOX (HUD) =================
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(3, Color.RED) -- Rouge par défaut (Scan)
boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
-- Taille agrandie : 160x160
local lpBox = WindowManager.LayoutParams(160, 160, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

function setBoxColor(mode)
    if mode == "LOCKED" then
        boxPaint.setStroke(6, Color.GREEN) -- Vert épais = Action !
    else
        boxPaint.setStroke(2, Color.RED) -- Rouge fin = Veille
    end
end

-- ================= MOTEUR DANS LA "ZONE VIDE" =================

-- C'est ici la magie : On ne bouge plus le centre, on bouge la zone vide
function moveCameraZone(offsetX, offsetY)
    local p = Path()
    -- On part du centre de la zone vide
    p.moveTo(Pos.camX, Pos.camY)
    -- On glisse vers la direction voulue
    p.lineTo(Pos.camX + offsetX, Pos.camY + offsetY)
    
    local g = GestureDescription.Builder()
    -- Geste rapide (40ms) pour simuler un reflexe
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doStrafe()
    local p = Path(); local span = 150; p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 200))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= CERVEAU IA =================
local time_step = 0

local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        
        -- Indique que le système travaille
        if config.aim_assist or config.smart_recoil then setBoxColor("LOCKED") 
        else setBoxColor("SCAN") end
        
        -- 1. RAPID FIRE (Bouton Tir)
        if config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        
        -- 2. GESTION CAMERA (Zone Vide)
        local totalMoveX = 0
        local totalMoveY = 0
        
        -- A. Aim Assist "Balayage Magnetique"
        if config.aim_assist then
            -- Fait vibrer la caméra gauche/droite très vite
            -- Si un ennemi est dans le viseur, le jeu va ralentir ce mouvement
            time_step = time_step + 1
            if time_step % 2 == 0 then
                totalMoveX = totalMoveX + config.scan_force
            else
                totalMoveX = totalMoveX - config.scan_force
            end
        end
        
        -- B. Recul Intelligent
        if config.smart_recoil then
            totalMoveY = totalMoveY + config.recoil_force
        end
        
        -- Applique le mouvement combiné dans la ZONE VIDE
        if totalMoveX ~= 0 or totalMoveY ~= 0 then
            moveCameraZone(totalMoveX, totalMoveY)
        end
        
        -- 3. STRAFE
        if config.auto_strafe then doStrafe() end
        
        handler.postDelayed(runLoop, config.speed_ms)
    else
        setBoxColor("SCAN")
    end
end})

-- ================= UI PREDATOR =================

local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(9); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(1,-1); v.setBackground(gd)
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
-- NOUVELLE CIBLE : ZONE CAMERA
createTarget(0x8800FFFF, "ZONE\nCAM", SW*0.7, SH*0.4, function(x,y) Pos.camX=x; Pos.camY=y end)

-- BOUTON PREDATOR
local btnZen = Button(activity); btnZen.setText("👽"); btnZen.setTextSize(20)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF003333); bgZen.setCornerRadius(100); bgZen.setStroke(2, Color.CYAN)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=200

-- MENU
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE001111); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.CYAN)
menu.setBackground(bgMenu); menu.setVisibility(8)

local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 500)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("PREDATOR V17"); t.setTextColor(Color.CYAN); t.setTextSize(16); t.setGravity(17); content.addView(t)

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(13); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.CYAN) end end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addS("MASTER", "active")
content.addView(TextView(activity))
addS("Smart Recoil", "smart_recoil")
addS("Auto-Track (Balayage)", "aim_assist")
addS("Rapid Fire", "rapid_fire")

local sep = TextView(activity); sep.setText("\nPARAMETRES ZONE VIDE"); sep.setTextColor(Color.YELLOW); sep.setGravity(17); content.addView(sep)

addSl("Force Balayage", "scan_force", 80)
addSl("Force Recul", "recoil_force", 100)
addSl("Vitesse (ms)", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("CACHER SETUP"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local lpMenu = WindowManager.LayoutParams(600, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=50

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
print("✅ V17 PREDATOR: Zone Neuronale Activée")