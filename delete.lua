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

-- ================= CONFIGURATION GOD MODE =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    jitter_mode = false, -- NOUVEAU: Tremblement pour Aim Assist
    auto_strafe = false,
    recoil_force = 40,   -- Force verticale
    jitter_force = 15,   -- Force du tremblement horizontal
    fire_rate = 60       -- Vitesse de boucle (plus bas = plus rapide)
}

-- Positions (Mises à jour par les cibles)
local Pos = {
    fireX = 0, fireY = 0,
    joyX = 0, joyY = 0,
    centerX = 0, centerY = 0
}

-- INIT SYSTEM
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2

local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= MOTEUR GESTURES AGRESSIF =================

-- 1. SUPER TAP (Instantanné)
function godTap(x, y)
    local p = Path()
    p.moveTo(x, y)
    local g = GestureDescription.Builder()
    -- Stroke de 1ms pour spammer comme un fou
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 1)) 
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- 2. JITTER RECOIL (Le secret du "Sticky Aim")
function godRecoil(forceV, forceH)
    local p = Path()
    p.moveTo(Pos.centerX, Pos.centerY)
    
    -- Calcul du tremblement aléatoire (Gauche/Droite)
    local noise = math.random(-forceH, forceH)
    
    -- On tire vers le bas (forceV) + un peu de bruit horizontal (noise)
    p.lineTo(Pos.centerX + noise, Pos.centerY + forceV)
    
    local g = GestureDescription.Builder()
    -- Geste très rapide (20ms) pour ne pas gêner la visée manuelle
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 20))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- 3. STRAFE (Mouvements erratiques)
function godStrafe()
    local p = Path()
    local span = 180
    p.moveTo(Pos.joyX, Pos.joyY)
    
    -- Mouvement aléatoire pour être imprévisible
    if math.random(0, 100) > 50 then
        p.lineTo(Pos.joyX - span, Pos.joyY) -- Gauche
    else
        p.lineTo(Pos.joyX + span, Pos.joyY) -- Droite
    end
    
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 150))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= BOUCLE DE TRICHE =================
local handler = Handler(Looper.getMainLooper())
local loopRunnable = Runnable({ run = function()
    if config.active then
        
        -- TAPTAP
        if config.rapid_fire then
            godTap(Pos.fireX, Pos.fireY)
        end

        -- RECUL & JITTER
        if config.anti_recoil then
            if config.jitter_mode then
                -- Mode Dinguerie : Recul + Tremblement
                godRecoil(config.recoil_force, config.jitter_force)
            else
                -- Mode Classique : Juste bas
                godRecoil(config.recoil_force, 0)
            end
        end

        -- STRAFE
        if config.auto_strafe then
            godStrafe()
        end

        -- Relance ultra rapide
        handler.postDelayed(loopRunnable, config.fire_rate)
    end
end})

-- ================= TARGET SYSTEM (CIBLES) =================
local targets = {}

local function createTarget(color, label, defX, defY, cb)
    local tv = TextView(activity)
    tv.setText(label)
    tv.setTextColor(Color.WHITE)
    tv.setTextSize(9)
    tv.setGravity(17)
    
    local gd = GradientDrawable()
    gd.setColor(color); gd.setShape(1); gd.setStroke(2, -1) -- Ovale avec bord blanc
    tv.setBackground(gd)

    local lp = WindowManager.LayoutParams(120, 120, 2038, 8, -3)
    lp.gravity = 51; lp.x = defX; lp.y = defY

    local tx, ty
    tv.setOnTouchListener(function(v,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y; return true
        elseif e.getAction()==2 then 
            lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(tv,lp)
            cb(lp.x+60, lp.y+60) -- +60 car taille 120/2
            return true 
        end
        return false
    end)
    
    wm.addView(tv, lp)
    table.insert(targets, tv)
    cb(defX+60, defY+60)
end

-- CIBLE ROUGE (TIR)
createTarget(0xAAFF0000, "AIM\nHERE", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
-- CIBLE BLEUE (JOYSTICK)
createTarget(0xAA0000FF, "JOY\nHERE", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- ================= MENU UI =================
local layout = LinearLayout(activity)
layout.setOrientation(1)
local gdMenu = GradientDrawable()
gdMenu.setColor(0xEE120024); gdMenu.setCornerRadius(20); gdMenu.setStroke(4, 0xFF9900FF)
layout.setBackground(gdMenu)
layout.setPadding(30,30,30,30)

local title = TextView(activity)
title.setText("💀 POCKET ZEN V6 💀")
title.setTextColor(Color.MAGENTA)
title.setTypeface(Typeface.DEFAULT_BOLD)
title.setGravity(17)
layout.addView(title)

local btnHide = Button(activity)
btnHide.setText("👁️ CACHER CIBLES")
btnHide.setTextColor(Color.CYAN)
btnHide.setBackgroundColor(0)
btnHide.setOnClickListener(function()
    for _,t in pairs(targets) do 
        if t.getVisibility()==0 then t.setVisibility(8) else t.setVisibility(0) end 
    end
end)
layout.addView(btnHide)

local function addSw(txt, k)
    local s = Switch(activity)
    s.setText(txt); s.setTextColor(-1)
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) 
        config[k]=c 
        if k=="active" then 
            if c then handler.post(loopRunnable); title.setTextColor(Color.GREEN) 
            else handler.removeCallbacks(loopRunnable); title.setTextColor(Color.MAGENTA) end
        end
    end})
    layout.addView(s)
end

local function addSl(txt, k, max)
    local t = TextView(activity); t.setText(txt..": "..config[k]); t.setTextColor(Color.LTGRAY); layout.addView(t)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(s,p) config[k]=p; t.setText(txt..": "..p) end})
    layout.addView(sk)
end

addSw("ACTIVATION (MASTER)", "active")
addSw("🔥 Rapid Fire (God Tap)", "rapid_fire")
addSw("📉 Anti-Recoil", "anti_recoil")
addSw("🫨 Jitter Aim (Sticky)", "jitter_mode")
addSw("🏃 Auto-Strafe", "auto_strafe")

local sep = TextView(activity); sep.setText("\nREGLAGES PUISSANCE"); sep.setTextColor(Color.YELLOW); layout.addView(sep)

addSl("Force Verticale", "recoil_force", 150)
addSl("Force Jitter (Shake)", "jitter_force", 50)
addSl("Vitesse Script (ms)", "fire_rate", 150)

-- FENETRE
local wp = WindowManager.LayoutParams(750, -2, 2038, 8, -3)
wp.gravity=51; wp.x=100; wp.y=100

-- Minimiser logic
local minBtn = Button(activity); minBtn.setText("−"); minBtn.setTextColor(Color.RED); 
layout.addView(minBtn)
minBtn.setOnClickListener(function()
    if layout.getChildAt(2).getVisibility()==0 then
        for i=1, layout.getChildCount()-1 do if i~=0 then layout.getChildAt(i).setVisibility(8) end end
        wp.width=300; wm.updateViewLayout(layout,wp)
    else
        for i=1, layout.getChildCount()-1 do layout.getChildAt(i).setVisibility(0) end
        wp.width=750; wm.updateViewLayout(layout,wp)
    end
end)

-- Drag
local dx, dy
title.setOnTouchListener(function(v,e)
    if e.getAction()==0 then dx=e.getRawX()-wp.x; dy=e.getRawY()-wp.y; return true
    elseif e.getAction()==2 then wp.x=e.getRawX()-dx; wp.y=e.getRawY()-dy; wm.updateViewLayout(layout,wp); return true end
    return false
end)

wm.addView(layout, wp)
print("✅ GOD MODE CHARGÉ")