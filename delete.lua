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

-- ================= CONFIGURATION NEURONALE =================
local Config = {
    active = false,
    rapid_fire = false,
    smart_recoil = false,
    aim_assist = false, -- Mode Balayage Zone Vide
    auto_strafe = false,
    scan_force = 20,
    recoil_force = 30,
    speed_ms = 80, -- Ralenti pour fiabilité
    box_x = 0,     -- Décalage Carré X
    box_y = 0      -- Décalage Carré Y
}

-- Positions : Fire, Joy, Cam (Zone Vide)
local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Position par défaut
Pos.camX, Pos.camY = SW * 0.75, SH * 0.5

local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= DEBUGGER VISUEL (LE POINT ROUGE) =================
-- Ce point apparaitra là où le script clique vraiment
local debugDot = View(activity)
local debugBg = GradientDrawable()
debugBg.setColor(0xFFFF0000) -- ROUGE VIF
debugBg.setShape(1) -- Rond
debugDot.setBackground(debugBg)
local lpDebug = WindowManager.LayoutParams(40, 40, OVERLAY_TYPE, 24, -3) -- 24=Untouchable
lpDebug.gravity = 51 -- Top Left
wm.addView(debugDot, lpDebug)
debugDot.setVisibility(8) -- Caché au début

function showTouch(x, y)
    -- Affiche le point rouge pendant 50ms pour prouver que ça clique
    activity.runOnUiThread(function()
        lpDebug.x = x - 20
        lpDebug.y = y - 20
        debugDot.setVisibility(0)
        wm.updateViewLayout(debugDot, lpDebug)
        Handler().postDelayed(function() debugDot.setVisibility(8) end, 100)
    end)
end

-- ================= VISUAL BOX (CARRÉ VISEUR) =================
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(3, Color.RED)
boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
local lpBox = WindowManager.LayoutParams(160, 160, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

function updateBox()
    lpBox.x = Config.box_x
    lpBox.y = Config.box_y
    wm.updateViewLayout(boxView, lpBox)
end

function setBoxColor(active)
    if active then boxPaint.setStroke(5, Color.GREEN) else boxPaint.setStroke(2, Color.RED) end
end

-- ================= MOTEUR ROBUSTE (SLOW-MO) =================

function doTap(x, y)
    showTouch(x, y) -- Preuve visuelle
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    -- AUGMENTÉ À 60ms (GameLoop a besoin de ça pour capter le clic)
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 60))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function moveCameraZone(offsetX, offsetY)
    showTouch(Pos.camX, Pos.camY) -- Preuve visuelle dans la zone vide
    local p = Path()
    p.moveTo(Pos.camX, Pos.camY)
    p.lineTo(Pos.camX + offsetX, Pos.camY + offsetY)
    
    local g = GestureDescription.Builder()
    -- Swipe plus long (80ms) pour être sûr que ça bouge
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 80))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doStrafe()
    local p = Path(); local span = 150; p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 200))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= BOUCLE LOGIQUE =================
local time_step = 0
local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if Config.active then
        
        -- Indique activité (Vert = Actif)
        if Config.aim_assist or Config.smart_recoil or Config.rapid_fire then 
            setBoxColor(true) 
        else 
            setBoxColor(false) 
        end
        
        -- 1. TIR
        if Config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        
        -- 2. CAMERA (ZONE VIDE)
        local mx, my = 0, 0
        
        if Config.aim_assist then
            time_step = time_step + 1
            if time_step % 2 == 0 then mx = Config.scan_force else mx = -Config.scan_force end
        end
        
        if Config.smart_recoil then
            my = Config.recoil_force
        end
        
        if mx ~= 0 or my ~= 0 then
            moveCameraZone(mx, my)
        end
        
        -- 3. STRAFE
        if Config.auto_strafe then doStrafe() end
        
        handler.postDelayed(runLoop, Config.speed_ms)
    else
        setBoxColor(false)
    end
end})

-- ================= UI V18 =================

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
createTarget(0x8800FFFF, "ZONE\nVIDE", SW*0.7, SH*0.4, function(x,y) Pos.camX=x; Pos.camY=y end)

-- BOUTON LAUNCH
local btnZen = Button(activity); btnZen.setText("V18"); btnZen.setTextSize(18); btnZen.setTextColor(Color.YELLOW)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF222200); bgZen.setCornerRadius(100); bgZen.setStroke(2, Color.YELLOW)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(140,140,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=200

-- MENU
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE111100); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.YELLOW)
menu.setBackground(bgMenu); menu.setVisibility(8)

local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 550)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("NEURAL V18"); t.setTextColor(Color.YELLOW); t.setTextSize(16); t.setGravity(17); content.addView(t)

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(13); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) 
        if k=="active" then 
            Config.active = c
            if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.YELLOW) end
        else
            Config[k]=c 
        end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

addS("MASTER", "active")
content.addView(TextView(activity))
addS("Smart Recoil (Zone Vide)", "smart_recoil")
addS("Aim Balayage (Zone Vide)", "aim_assist")
addS("Rapid Fire", "rapid_fire")

-- CALIBRAGE CARRE (RETOUR)
local sep = TextView(activity); sep.setText("\nCALIBRAGE CARRE"); sep.setTextColor(Color.CYAN); sep.setGravity(17); content.addView(sep)

local function addCalib(txt, axis)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(17)
    local btnM = Button(activity); btnM.setText("←"); btnM.setOnClickListener(function() 
        if axis=="x" then Config.box_x=Config.box_x-10 else Config.box_y=Config.box_y-10 end; updateBox()
    end)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setPadding(20,0,20,0)
    local btnP = Button(activity); btnP.setText("→"); btnP.setOnClickListener(function() 
        if axis=="x" then Config.box_x=Config.box_x+10 else Config.box_y=Config.box_y+10 end; updateBox()
    end)
    h.addView(btnM); h.addView(tv); h.addView(btnP); content.addView(h)
end
addCalib("Position X", "x")
addCalib("Position Y", "y")

local sep2 = TextView(activity); sep2.setText("\nPUISSANCE"); sep2.setTextColor(Color.MAGENTA); sep2.setGravity(17); content.addView(sep2)

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

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
print("✅ V18: DEBUGGER VISUEL ACTIVÉ")