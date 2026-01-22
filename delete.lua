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

-- ================= GAMELOOP FIX (WINDOW TYPE) =================
local OVERLAY_TYPE
if Build.VERSION.SDK_INT >= 26 then
    OVERLAY_TYPE = 2038 -- Android 8+
else
    OVERLAY_TYPE = 2002 -- Android 7- (GameLoop Standard)
end

-- ================= CONFIGURATION =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    aim_assist = false, 
    auto_strafe = false,
    shake_radius = 20,
    recoil_force = 30,
    speed_ms = 60
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= FONCTION LANCEMENT JEU =================
function launchGame()
    local pm = activity.getPackageManager()
    local intent = pm.getLaunchIntentForPackage("com.activision.callofduty.shooter")
    if intent then
        print("🚀 Lancement de CODM...")
        activity.startActivity(intent)
    else
        print("⚠️ Erreur: CODM (Global) non trouvé !")
        -- Essai version Garena au cas où
        intent = pm.getLaunchIntentForPackage("com.garena.game.codm")
        if intent then activity.startActivity(intent) end
    end
end

-- ================= MOTEUR MATH (CRONUS) =================

local angle_rad = 0
function getCronusOffset(radius)
    angle_rad = angle_rad + 0.8
    if angle_rad > 6.28 then angle_rad = 0 end
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
    
    if config.aim_assist then
        local ox, oy = getCronusOffset(config.shake_radius)
        endX = endX + ox; endY = endY + oy
    end
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
        if config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        if config.anti_recoil or config.aim_assist then doCronusMove() end
        if config.auto_strafe then doStrafe() end
        handler.postDelayed(runLoop, config.speed_ms)
    end
end})

-- ================= UI GAMELOOP + LAUNCHER =================

local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(10); v.setTextColor(-1)
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
createTarget(0x88FF0000, "TIR", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x880000FF, "JOY", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- BOUTON ZEN
local btnZen = Button(activity); btnZen.setText("ZEN"); btnZen.setTextColor(Color.CYAN)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF220033); bgZen.setCornerRadius(50); bgZen.setStroke(2, Color.CYAN)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(120,120,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=150

-- MENU
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE000000); bgMenu.setCornerRadius(15); bgMenu.setStroke(2, Color.MAGENTA)
menu.setBackground(bgMenu)
menu.setVisibility(8)

local scroll = ScrollView(activity)
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 400)) 
menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1)
scroll.addView(content)

-- TITRE
local t = TextView(activity); t.setText("GAMELOOP V14"); t.setTextColor(Color.MAGENTA); t.setTextSize(14); t.setGravity(17)
content.addView(t)

-- *** BOUTON LANCER JEU ***
local btnLaunch = Button(activity)
btnLaunch.setText("🚀 LANCER CODM")
btnLaunch.setTextColor(Color.WHITE)
btnLaunch.setTextSize(12)
local bgLaunch = GradientDrawable()
bgLaunch.setColor(0xFFFF8800) -- Orange vif
bgLaunch.setCornerRadius(10)
btnLaunch.setBackground(bgLaunch)
btnLaunch.setOnClickListener(function()
    launchGame()
end)
content.addView(btnLaunch)
-- *************************

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(12); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.MAGENTA) end end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..config[k]); tv.setTextColor(Color.LTGRAY); tv.setTextSize(12); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setLayoutParams(LinearLayout.LayoutParams(-1, 50)) 
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addS("MASTER", "active")
addS("RapidFire", "rapid_fire")
addS("NoRecoil", "anti_recoil")
addS("AimAssist", "aim_assist")
addS("Strafe", "auto_strafe")

local sep = TextView(activity); sep.setText("---"); sep.setGravity(17); sep.setTextColor(Color.DKGRAY); content.addView(sep)

addSl("Rayon", "shake_radius", 80)
addSl("Recul", "recoil_force", 100)
addSl("Vitesse", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("Cacher Cibles"); btnHide.setTextSize(12); btnHide.setHeight(80)
btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local btnClose = Button(activity); btnClose.setText("Fermer Menu"); btnClose.setTextSize(12); btnClose.setTextColor(Color.RED); btnClose.setHeight(80)
btnClose.setOnClickListener(function() menu.setVisibility(8) end); content.addView(btnClose)

local lpMenu = WindowManager.LayoutParams(450, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=150; lpMenu.y=50

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
print("✅ V14: BOUTON 'LANCER CODM' AJOUTÉ")