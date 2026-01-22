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

-- ================= CONFIGURATION V10 =================
local config = {
    active = false,
    rapid_fire = false,
    anti_recoil = false,
    aim_assist = false,
    auto_strafe = false,
    recoil_force = 20,
    fire_rate = 80
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, centerX=0, centerY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
Pos.centerX, Pos.centerY = SW/2, SH/2
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= DEBUGGER VISUEL =================
-- Crée un point rouge qui s'affiche quand le script clique
local debugPointer = View(activity)
local debugBg = GradientDrawable()
debugBg.setColor(0xAAFF0000) -- Rouge semi-transparent
debugBg.setShape(1) -- Ovale
debugPointer.setBackground(debugBg)
local lpDebug = WindowManager.LayoutParams(50,50,2038,24,-3) -- Not focusable, not touchable
lpDebug.gravity = 51
wm.addView(debugPointer, lpDebug)
debugPointer.setVisibility(8) -- Caché par défaut

function showClickVisual(x, y)
    -- Déplace le point rouge là où le script tape
    activity.runOnUiThread(function()
        lpDebug.x = x - 25
        lpDebug.y = y - 25
        debugPointer.setVisibility(0)
        wm.updateViewLayout(debugPointer, lpDebug)
        -- Le cacher après 50ms
        Handler().postDelayed(function() debugPointer.setVisibility(8) end, 50)
    end)
end

-- ================= MOTEUR DE TIR =================

function gameTap(x, y)
    showClickVisual(x, y) -- Montre où ça tape !
    local p = Path(); p.moveTo(x, y)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function gameRecoil(force)
    local p = Path(); p.moveTo(Pos.centerX, Pos.centerY); p.lineTo(Pos.centerX, Pos.centerY + force)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 40))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function gameStrafe()
    local p = Path(); local span = 200
    p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 300))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if config.active then
        if config.rapid_fire then gameTap(Pos.fireX, Pos.fireY) end
        if config.anti_recoil then gameRecoil(config.recoil_force) end
        if config.auto_strafe then gameStrafe() end
        handler.postDelayed(runLoop, config.fire_rate)
    end
end})

-- ================= UI ROBUSTE =================

-- 1. CIBLES DE REGLAGE
local targets = {}
local function createTarget(col, txt, x, y, cb)
    local v = TextView(activity); v.setText(txt); v.setGravity(17); v.setTextSize(10); v.setTextColor(-1)
    local gd = GradientDrawable(); gd.setColor(col); gd.setShape(1); gd.setStroke(2,-1); v.setBackground(gd)
    local lp = WindowManager.LayoutParams(130,130,2038,8,-3); lp.gravity=51; lp.x=x; lp.y=y
    local tx,ty
    v.setOnTouchListener(function(_,e)
        if e.getAction()==0 then tx=e.getRawX()-lp.x; ty=e.getRawY()-lp.y return true
        elseif e.getAction()==2 then lp.x=e.getRawX()-tx; lp.y=e.getRawY()-ty; wm.updateViewLayout(v,lp); cb(lp.x+65,lp.y+65) return true end
        return false
    end)
    wm.addView(v,lp); table.insert(targets,v); cb(x+65,y+65)
end
createTarget(0xAAFF0000, "TIR\n(Cible)", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0xAA0000FF, "JOY\n(Move)", SW*0.15, SH*0.7, function(x,y) Pos.joyX=x; Pos.joyY=y end)

-- 2. LE BOUTON "ZEN" (Handle)
local btnZen = Button(activity)
btnZen.setText("ZEN")
btnZen.setTextColor(Color.WHITE)
btnZen.setBackground(GradientDrawable())
btnZen.getBackground().setColor(0xFF6200EA) -- Violet
btnZen.getBackground().setCornerRadius(100)
btnZen.getBackground().setStroke(4, Color.CYAN)
local lpZen = WindowManager.LayoutParams(160,160,2038,8,-3)
lpZen.gravity=51; lpZen.x=50; lpZen.y=200
wm.addView(btnZen, lpZen)

-- 3. LE MENU (Séparé)
local menu = LinearLayout(activity); menu.setOrientation(1)
local bg = GradientDrawable(); bg.setColor(0xEE111111); bg.setCornerRadius(20); bg.setStroke(3, Color.MAGENTA)
menu.setBackground(bg); menu.setPadding(20,20,20,20)
menu.setVisibility(8) -- Caché au début

-- ScrollView pour éviter que ça coupe
local scroll = ScrollView(activity)
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, SH*0.6))
menu.addView(scroll)

local content = LinearLayout(activity); content.setOrientation(1)
scroll.addView(content)

-- Header
local t = TextView(activity); t.setText("ZEN V10 ULTIME"); t.setTextColor(Color.CYAN); t.setTextSize(18); t.setGravity(17)
content.addView(t)

-- Options
local function addS(txt,k)
    local s = Switch(activity); s.setText(txt); s.setTextColor(-1); s.setPadding(0,20,0,20)
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) config[k]=c 
        if k=="active" then if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.CYAN) end end
    end}); content.addView(s)
end
local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..config[k]); tv.setTextColor(-1); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addS("MASTER (ON/OFF)", "active")
addS("🔥 Rapid Fire", "rapid_fire")
addS("📉 Anti-Recoil", "anti_recoil")
addS("🏃 Auto-Strafe", "auto_strafe")
addSl("Force Recul", "recoil_force", 100)
addSl("Vitesse (ms)", "fire_rate", 200)

local btnHide = Button(activity); btnHide.setText("CACHER CIBLES ROUGE/BLEU"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

-- Params Menu
local lpMenu = WindowManager.LayoutParams(700, WindowManager.LayoutParams.WRAP_CONTENT, 2038, 8, -3)
lpMenu.gravity=51; lpMenu.x=250; lpMenu.y=100
wm.addView(menu, lpMenu)

-- LOGIQUE INTELLIGENTE BOUTON ZEN
-- Si on clique court -> Toggle Menu
-- Si on glisse -> Bouge le bouton
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

print("✅ V10 PRÊT. Utilise le bouton rond pour ouvrir/fermer !")