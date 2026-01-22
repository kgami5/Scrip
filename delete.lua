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

-- ================= CONFIGURATION V24 =================
local Config = {
    active = true,        -- Activé par défaut
    rapid_fire = true,    -- Rapid Fire Activé
    smart_recoil = true,  -- Recul Activé
    aim_assist = true,    -- Aim Assist Activé
    auto_strafe = false,
    
    recoil_force = 30,
    scan_force = 30,
    speed_ms = 80,        -- Vitesse moyenne stable
    
    box_size = 150,       -- Taille du carré central
    box_x = 0,
    box_y = 0,
    
    is_shooting = false   -- Etat du tir
}

local Pos = { fireX=0, fireY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= DEBUG VISUEL =================
local debugDot = View(activity)
local debugBg = GradientDrawable(); debugBg.setColor(0xFFFF0000); debugBg.setShape(1)
debugDot.setBackground(debugBg)
local lpDebug = WindowManager.LayoutParams(40, 40, OVERLAY_TYPE, 24, -3)
lpDebug.gravity = 51; wm.addView(debugDot, lpDebug); debugDot.setVisibility(8)

function showTouch(x, y)
    activity.runOnUiThread(function()
        lpDebug.x, lpDebug.y = x-20, y-20
        debugDot.setVisibility(0)
        wm.updateViewLayout(debugDot, lpDebug)
        Handler().postDelayed(function() debugDot.setVisibility(8) end, 100)
    end)
end

-- ================= CARRE CENTRAL (CORTEX) =================
local boxView = View(activity)
local boxPaint = GradientDrawable()
boxPaint.setStroke(3, Color.RED); boxPaint.setColor(0x00000000)
boxView.setBackground(boxPaint)
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = 17 
wm.addView(boxView, lpBox)

function updateBoxState()
    if Config.is_shooting then
        boxPaint.setStroke(6, Color.GREEN) -- TIR EN COURS
    elseif Config.active then
        boxPaint.setStroke(2, Color.RED)   -- VEILLE
    else
        boxPaint.setStroke(2, Color.GRAY)  -- DESACTIVE
    end
    -- Mise à jour position
    lpBox.x = Config.box_x
    lpBox.y = Config.box_y
    wm.updateViewLayout(boxView, lpBox)
end

-- ================= MOTEUR D'ACTION =================

function performAction()
    if not accessibilityService then return end
    
    -- 1. TIR
    if Config.rapid_fire then
        showTouch(Pos.fireX, Pos.fireY)
        local p = Path(); p.moveTo(Pos.fireX, Pos.fireY)
        local g = GestureDescription.Builder()
        g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
        pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
    end
    
    -- 2. MOUVEMENT (Aim/Recoil)
    local mx, my = 0, 0
    
    if Config.aim_assist then
        -- Balayage en spirale ou gauche/droite
        if os.time() % 2 == 0 then mx = Config.scan_force else mx = -Config.scan_force end
    end
    
    if Config.smart_recoil then
        my = Config.recoil_force
    end
    
    if mx ~= 0 or my ~= 0 then
        -- Mouvement dans la zone vide
        local p2 = Path()
        p2.moveTo(Pos.camX, Pos.camY)
        p2.lineTo(Pos.camX + mx, Pos.camY + my)
        local g2 = GestureDescription.Builder()
        g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 70))
        pcall(function() accessibilityService:dispatchGesture(g2:build(), nil, nil) end)
    end
end

-- BOUCLE DE TIR
local handler = Handler(Looper.getMainLooper())
local loop = Runnable({ run = function()
    if Config.is_shooting and Config.active then
        performAction()
        updateBoxState()
        handler.postDelayed(loop, Config.speed_ms)
    else
        updateBoxState()
    end
end})

-- ================= INTERCEPTION VOLUME =================
-- Ceci permet d'utiliser le bouton Volume Haut pour tirer
function onKeyDown(code, event)
    if string.find(tostring(event), "KEYCODE_VOLUME_UP") then
        if not Config.is_shooting then
            Config.is_shooting = true
            handler.post(loop)
        end
        return true -- Bloque le son pour ne pas gêner
    end
end

function onKeyUp(code, event)
    if string.find(tostring(event), "KEYCODE_VOLUME_UP") then
        Config.is_shooting = false
        return true
    end
end

-- ================= UI =================

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
createTarget(0x8800FFFF, "ZONE\nCAM", SW*0.7, SH*0.4, function(x,y) Pos.camX=x; Pos.camY=y end)

-- BOUTON VIRTUEL (JAUNE)
local btnShoot = Button(activity); btnShoot.setText("SHOOT"); btnShoot.setTextColor(Color.BLACK)
local bgS = GradientDrawable(); bgS.setColor(0xFFFFD700); bgS.setCornerRadius(100); bgS.setStroke(3, Color.WHITE)
btnShoot.setBackground(bgS)
local lpS = WindowManager.LayoutParams(160,160,OVERLAY_TYPE,8,-3); lpS.gravity=51; lpS.x=SW*0.85; lpS.y=SH*0.65

btnShoot.setOnTouchListener(function(v,e)
    if e.getAction() == 0 then
        Config.is_shooting = true
        bgS.setColor(0xFFFF0000)
        handler.post(loop)
    elseif e.getAction() == 1 then
        Config.is_shooting = false
        bgS.setColor(0xFFFFD700)
    end
    return true -- Consume l'event pour éviter le conflit
end)
wm.addView(btnShoot, lpS)


-- MENU REGLAGES
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE111111); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.YELLOW)
menu.setBackground(bgMenu); menu.setVisibility(8)
local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 500)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("V24 ULTIMATE"); t.setTextColor(Color.YELLOW); t.setGravity(17); content.addView(t)

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); s.setChecked(Config[k])
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) Config[k]=c end})
    h.addView(tv); h.addView(s); content.addView(h)
end

addS("ACTIVATION", "active")
content.addView(TextView(activity))
addS("Rapid Fire", "rapid_fire")
addS("Recoil Control", "smart_recoil")
addS("Aim Assist", "aim_assist")

local sep = TextView(activity); sep.setText("\nCALIBRAGE CARRE"); sep.setTextColor(Color.CYAN); sep.setGravity(17); content.addView(sep)
local function addCalib(txt, axis)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(17)
    local btnM = Button(activity); btnM.setText("←"); btnM.setOnClickListener(function() if axis=="x" then Config.box_x=Config.box_x-10 else Config.box_y=Config.box_y-10 end; updateBoxState() end)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1)
    local btnP = Button(activity); btnP.setText("→"); btnP.setOnClickListener(function() if axis=="x" then Config.box_x=Config.box_x+10 else Config.box_y=Config.box_y+10 end; updateBoxState() end)
    h.addView(btnM); h.addView(tv); h.addView(btnP); content.addView(h)
end
addCalib("X", "x"); addCalib("Y", "y")

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addSl("Recul", "recoil_force", 100)
addSl("Aim Shake", "scan_force", 100)
addSl("Vitesse", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("CACHER SETUP"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local lpMenu = WindowManager.LayoutParams(600, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=50

-- PETIT BOUTON MENU
local btnM = Button(activity); btnM.setText("⚙️"); 
local lpM = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3); lpM.gravity=51; lpM.x=50; lpM.y=50
btnM.setOnClickListener(function() if menu.getVisibility()==0 then menu.setVisibility(8) else menu.setVisibility(0) end end)

wm.addView(btnM, lpM)
wm.addView(menu, lpMenu)
print("✅ V24 CHARGÉE : Essaie le bouton VOLUME HAUT !")