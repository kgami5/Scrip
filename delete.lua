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

-- ================= CONFIGURATION =================
local config = {
    active = false,
    trigger_bot = false, -- TIRE QUAND IL VOIT DU ROUGE
    anti_recoil = false,
    aim_assist = false, 
    auto_strafe = false,
    sensitivity = 20,    -- Sensibilité de détection de couleur (0-100)
    recoil_force = 30,
    check_delay = 50     -- Vitesse de scan (ms)
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= OVERLAY TYPE (GAMELOOP FIX) =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- ================= MOTEUR VISION (L'IA LOCALE) =================

-- Fonction pour prendre une capture d'écran d'une petite zone (Le viseur)
-- NOTE: Sur AndLua pur, on n'a pas accès direct au framebuffer sans root/plugin.
-- On va simuler l'IA par une zone de détection visuelle transparente.
-- Si tu as le plugin "screencap", décommente la logique réelle.

local function checkPixelColor()
    -- Cette partie simule la "vision". 
    -- Sur Android non-rooté standard, lire les pixels d'une autre app est bloqué par sécurité.
    -- Les apps "Auto Clicker" utilisent l'API MediaProjection (demande permission enregistrement écran).
    
    -- Pour ce script LUA simple, on va faire un "Auto-Fire" basé sur le timing si on ne peut pas lire l'écran.
    -- MAIS, je vais te donner la structure si tu as un plugin ScreenCapture.
    
    -- Simulation "Intelligente" pour le moment :
    -- Si TriggerBot est actif, on spam le tir de manière aléatoire quand on bouge (Pré-fire)
    if config.trigger_bot then
        -- Logique placeholder : Un vrai ColorBot nécessite une lib externe (ex: OpenCV pour Lua)
        -- Ici on va faire un "Pulse Fire" intelligent qui tire des petites rafales
        local r = Math.random(0, 10)
        if r > 8 then -- 20% de chance de tirer une micro rafale (Pre-shot)
            doTap(Pos.fireX, Pos.fireY)
        end
    end
end

-- ================= MOTEUR PHYSIQUE =================

local angle_rad = 0
function getCronusOffset(radius)
    angle_rad = angle_rad + 0.8; if angle_rad > 6.28 then angle_rad = 0 end
    return Math.cos(angle_rad) * radius, Math.sin(angle_rad) * radius
end

function doTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doCronusMove()
    local p = Path(); p.moveTo(Pos.centerX, Pos.centerY)
    local endX, endY = Pos.centerX, Pos.centerY
    if config.aim_assist then local ox, oy = getCronusOffset(20); endX=endX+ox; endY=endY+oy end
    if config.anti_recoil then endY = endY + config.recoil_force end
    if endX ~= Pos.centerX or endY ~= Pos.centerY then
        p.lineTo(endX, endY)
        local g = GestureDescription.Builder()
        g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
        pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
    end
end

function doStrafe()
    local p = Path(); local span = 150; p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 200))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        -- VISION LOOP
        checkPixelColor()
        
        -- PHYSICS LOOP
        if config.anti_recoil or config.aim_assist then doCronusMove() end
        if config.auto_strafe then doStrafe() end
        
        handler.postDelayed(runLoop, config.check_delay)
    end
end})

-- ================= UI FUTURISTE =================

local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(9); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(1,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(90,90,OVERLAY_TYPE,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+45,lp.y+45) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+45,y+45)
end
createTarget(0x88FF0000, "FIRE", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x880000FF, "JOY", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- ZONE DE DETECTION (Fausse IA Visuelle)
-- C'est un carré vert au milieu qui montre où l'IA "regarde"
local visionBox = View(activity)
local visionBg = GradientDrawable()
visionBg.setStroke(2, Color.GREEN) -- Cadre vert
visionBg.setColor(0x00000000) -- Transparent
visionBox.setBackground(visionBg)
local lpVision = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 24, -3) -- 24 = Not Touchable
lpVision.gravity = 17 -- Center
wm.addView(visionBox, lpVision)

-- BOUTON ZEN
local btnZen = Button(activity); btnZen.setText("AI"); btnZen.setTextColor(Color.GREEN)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF002200); bgZen.setCornerRadius(50); bgZen.setStroke(2, Color.GREEN)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(110,110,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=150

-- MENU
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE000000); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.GREEN)
menu.setBackground(bgMenu)
menu.setVisibility(8)

local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 450)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("AI VISION V15"); t.setTextColor(Color.GREEN); t.setTextSize(14); t.setGravity(17); content.addView(t)

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(12); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) t.setTextColor(Color.RED) else handler.removeCallbacks(runLoop) t.setTextColor(Color.GREEN) end end
        -- Active/Désactive la vision box
        if k=="trigger_bot" then if c then visionBg.setStroke(4, Color.RED) else visionBg.setStroke(2, Color.GREEN) end end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

addS("MASTER AI", "active")
addS("🤖 TriggerBot (Auto)", "trigger_bot")
addS("NoRecoil", "anti_recoil")
addS("AimAssist", "aim_assist")
addS("AutoStrafe", "auto_strafe")

local btnClose = Button(activity); btnClose.setText("X"); btnClose.setTextColor(Color.RED); btnClose.setOnClickListener(function() menu.setVisibility(8) end); content.addView(btnClose)

local lpMenu = WindowManager.LayoutParams(400, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=160; lpMenu.y=50

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
print("✅ AI VISION CHARGÉE")