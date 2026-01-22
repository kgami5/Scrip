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

-- ================= CONFIGURATION =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    aim_assist = false,
    auto_strafe = false,
    recoil_force = 15,   -- Valeur basse pour haute sensi
    fire_rate = 60
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= MOTEUR PULSE (HIGH SENS) =================

function doTap(x, y)
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 1))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doRecoil(force)
    local p = Path()
    p.moveTo(Pos.centerX, Pos.centerY)
    p.lineTo(Pos.centerX, Pos.centerY + force)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

local angle = 0
function doAimAssist()
    local radius = 8
    local x = Pos.centerX + radius * math.cos(angle)
    local y = Pos.centerY + radius * math.sin(angle)
    local p = Path(); p.moveTo(Pos.centerX, Pos.centerY); p.lineTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 10))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
    angle = angle + 1
end

function doStrafe()
    local p = Path(); local span = 150
    p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 150))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        if config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        if config.anti_recoil then doRecoil(config.recoil_force) end
        if config.aim_assist then doAimAssist() end
        if config.auto_strafe then doStrafe() end
        handler.postDelayed(runLoop, config.fire_rate)
    end
end})

-- ================= UI SCROLLABLE SYSTEM =================

-- 1. CIBLES (TARGETS)
local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(10); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(110,110,2038,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+55,lp.y+55) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+55,y+55)
end
createTarget(0xAAFF0000, "TIR", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0xAA0000FF, "JOY", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- 2. BOUTON FLOTTANT (BUBBLE)
local bubble = Button(activity)
bubble.setText("ZEN")
bubble.setTextColor(Color.CYAN)
bubble.setBackground(GradientDrawable())
bubble.getBackground().setColor(0xFF4B0082)
bubble.getBackground().setCornerRadius(100)
local lpBubble = WindowManager.LayoutParams(140,140,2038,8,-3)
lpBubble.gravity=51; lpBubble.x=50; lpBubble.y=100

-- 3. MENU PRINCIPAL (SCROLLABLE)
local frame = LinearLayout(activity); frame.setOrientation(1); frame.setPadding(0,0,0,0)
local gdMenu = GradientDrawable(); gdMenu.setColor(0xEE111111); gdMenu.setStroke(3, 0xFF00FFFF); gdMenu.setCornerRadius(20)
frame.setBackground(gdMenu)
frame.setVisibility(View.GONE)

-- Header Fixe
local header = TextView(activity); header.setText("ZEN V8 - SCROLL"); header.setTextColor(-1); header.setGravity(17); header.setPadding(0,20,0,20)
frame.addView(header)

-- Zone de Scroll
local scroll = ScrollView(activity)
scroll.setFillViewport(true)
-- Limite la hauteur du scroll à 60% de l'écran pour éviter que ça sorte
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, SH * 0.6)) 
frame.addView(scroll)

-- Contenu Scrollable
local content = LinearLayout(activity); content.setOrientation(1); content.setPadding(20,0,20,20)
scroll.addView(content)

local lpMenu = WindowManager.LayoutParams(600, WindowManager.LayoutParams.WRAP_CONTENT, 2038, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=50

-- LOGIQUE BUBBLE
local bx, by, bt
bubble.setOnTouchListener(function(v,e)
    if e.getAction()==0 then bx=e.getRawX()-lpBubble.x; by=e.getRawY()-lpBubble.y; bt=System.currentTimeMillis(); return true
    elseif e.getAction()==2 then lpBubble.x=e.getRawX()-bx; lpBubble.y=e.getRawY()-by; wm.updateViewLayout(bubble,lpBubble); return true
    elseif e.getAction()==1 and (System.currentTimeMillis()-bt < 200) then
        if frame.getVisibility()==0 then frame.setVisibility(8) else frame.setVisibility(0) end
        return true
    end
    return false
end)

-- CONTROLES
local function addSw(t,k)
    local s = Switch(activity); s.setText(t); s.setTextColor(-1)
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) header.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) header.setTextColor(-1) end end
    end}); content.addView(s)
end
local function addSl(t,k,max)
    local tv = TextView(activity); tv.setText(t..": "..config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(t..": "..p) end}); content.addView(sk)
end

addSw("ACTIVATION (MASTER)", "active")
addSw("Rapid Fire (Tap)", "rapid_fire")
addSw("Anti-Recoil (Pulse)", "anti_recoil")
addSw("Aim Assist (Spirale)", "aim_assist")
addSw("Auto Strafe", "auto_strafe")

local sep = TextView(activity); sep.setText("\nREGLAGES"); sep.setTextColor(Color.YELLOW); content.addView(sep)

addSl("Force Recul (0-100)", "recoil_force", 100)
addSl("Vitesse (ms)", "fire_rate", 200)

local hideT = Button(activity); hideT.setText("CACHER/MONTRER CIBLES"); hideT.setOnClickListener(function()
    for _,t in pairs(targets) do if t.getVisibility()==0 then t.setVisibility(8) else t.setVisibility(0) end end
end); content.addView(hideT)

-- Bouton de fermeture en bas du scroll
local closeB = Button(activity); closeB.setText("FERMER MENU"); closeB.setTextColor(Color.RED); closeB.setOnClickListener(function()
    frame.setVisibility(View.GONE)
end); content.addView(closeB)

wm.addView(bubble, lpBubble)
wm.addView(frame, lpMenu)
print("✅ ZEN V8: MENU SCROLLABLE ACTIF")