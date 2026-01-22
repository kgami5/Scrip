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

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    rapid_fire = false,
    smart_recoil = false,
    aim_assist = false,
    auto_strafe = false,
    recoil_force = 30,
    speed_ms = 100, -- Vitesse plus lente pour être sûr que ça clique
    box_x = 0,
    box_y = 0
}

local Pos = { fireX=0, fireY=0, joyX=0, joyY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Positions par défaut
Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.joyX, Pos.joyY = SW * 0.15, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

-- RECUPERATION DU SERVICE (CRITIQUE)
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= DEBUGGER VISUEL (TESTEUR) =================
local debugDot = View(activity)
local debugBg = GradientDrawable()
debugBg.setColor(0xFFFF0000) -- ROUGE
debugBg.setShape(1) -- Rond
debugDot.setBackground(debugBg)
local lpDebug = WindowManager.LayoutParams(60, 60, OVERLAY_TYPE, 24, -3) -- 24=Untouchable
lpDebug.gravity = 51 
wm.addView(debugDot, lpDebug)
debugDot.setVisibility(8)

function showTouch(x, y)
    activity.runOnUiThread(function()
        lpDebug.x = x - 30
        lpDebug.y = y - 30
        debugDot.setVisibility(0)
        wm.updateViewLayout(debugDot, lpDebug)
        Handler().postDelayed(function() debugDot.setVisibility(8) end, 150)
    end)
end

-- ================= VISUAL BOX (HUD) =================
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

-- ================= MOTEUR GESTURES (LENT & PUISSANT) =================

function doTap(x, y)
    -- On affiche le point AVANT de cliquer pour voir si le code s'exécute
    showTouch(x, y) 
    
    if not accessibilityService then return end -- Sécurité

    local p = Path()
    p.moveTo(x, y)
    local g = GestureDescription.Builder()
    -- 100ms : C'est très lent, mais c'est OBLIGATOIRE sur GameLoop
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 100))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function moveCameraZone(offsetX, offsetY)
    showTouch(Pos.camX, Pos.camY) 
    
    if not accessibilityService then return end

    local p = Path()
    p.moveTo(Pos.camX, Pos.camY)
    p.lineTo(Pos.camX + offsetX, Pos.camY + offsetY)
    
    local g = GestureDescription.Builder()
    -- Swipe de 150ms (lourd) pour bouger la caméra
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 150))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function doStrafe()
    local p = Path(); local span = 150; p.moveTo(Pos.joyX, Pos.joyY)
    if os.time()%2==0 then p.lineTo(Pos.joyX-span, Pos.joyY) else p.lineTo(Pos.joyX+span, Pos.joyY) end
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 300))
    pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= BOUCLE =================
local time_step = 0
local handler = Handler(Looper.getMainLooper())
local runLoop = Runnable({ run = function()
    if Config.active then
        
        -- Animation visuelle (Clignotement Carré)
        if time_step % 2 == 0 then boxPaint.setStroke(5, Color.GREEN) else boxPaint.setStroke(2, Color.GREEN) end
        
        -- 1. TIR
        if Config.rapid_fire then doTap(Pos.fireX, Pos.fireY) end
        
        -- 2. CAMERA
        local mx, my = 0, 0
        if Config.aim_assist then
            time_step = time_step + 1
            if time_step % 2 == 0 then mx = 30 else mx = -30 end
        end
        if Config.smart_recoil then my = Config.recoil_force end
        
        if mx ~= 0 or my ~= 0 then moveCameraZone(mx, my) end
        
        -- 3. STRAFE
        if Config.auto_strafe then doStrafe() end
        
        handler.postDelayed(runLoop, Config.speed_ms)
    else
        boxPaint.setStroke(2, Color.RED)
    end
end})

-- ================= UI V19 (MENU COURT) =================

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

-- BOUTON V19
local btnZen = Button(activity); btnZen.setText("V19"); btnZen.setTextSize(18); btnZen.setTextColor(Color.WHITE)
local bgZen = GradientDrawable(); bgZen.setColor(0xFF440000); bgZen.setCornerRadius(100); bgZen.setStroke(2, Color.RED)
btnZen.setBackground(bgZen)
local lpZen = WindowManager.LayoutParams(140,140,OVERLAY_TYPE,8,-3); lpZen.gravity=51; lpZen.x=50; lpZen.y=200

-- MENU MINI
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE110000); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.RED)
menu.setBackground(bgMenu); menu.setVisibility(8)

local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 350)); menu.addView(scroll) -- Hauteur réduite 350
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("SYSTEM V19"); t.setTextColor(Color.RED); t.setTextSize(16); t.setGravity(17); content.addView(t)

-- *** BOUTON TEST CRITIQUE ***
local btnTest = Button(activity); btnTest.setText("🛠️ TESTER LE CLIC"); btnTest.setBackgroundColor(Color.DKGRAY); btnTest.setTextColor(Color.WHITE)
btnTest.setOnClickListener(function()
    print("Test clic lancé sur la cible TIR...")
    doTap(Pos.fireX, Pos.fireY)
end)
content.addView(btnTest)
-- ****************************

local function addS(txt,k)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(16)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1); tv.setTextSize(12); tv.setLayoutParams(LinearLayout.LayoutParams(0,-2,1.0))
    local s = Switch(activity); 
    s.setOnCheckedChangeListener({onCheckedChanged=function(v,c) 
        if k=="active" then 
            Config.active = c
            if c then handler.post(runLoop) t.setTextColor(Color.GREEN) else handler.removeCallbacks(runLoop) t.setTextColor(Color.RED) end
        else Config[k]=c end
    end})
    h.addView(tv); h.addView(s); content.addView(h)
end

addS("MASTER", "active")
content.addView(TextView(activity))
addS("Smart Recoil (Zone Vide)", "smart_recoil")
addS("Aim Balayage (Zone Vide)", "aim_assist")
addS("Rapid Fire", "rapid_fire")

-- CALIBRAGE
local sep = TextView(activity); sep.setText("POS CARRE"); sep.setTextColor(Color.CYAN); sep.setGravity(17); content.addView(sep)
local function addCalib(txt, axis)
    local h = LinearLayout(activity); h.setOrientation(0); h.setGravity(17)
    local btnM = Button(activity); btnM.setText("←"); btnM.setOnClickListener(function() if axis=="x" then Config.box_x=Config.box_x-10 else Config.box_y=Config.box_y-10 end; updateBox() end)
    local tv = TextView(activity); tv.setText(txt); tv.setTextColor(-1)
    local btnP = Button(activity); btnP.setText("→"); btnP.setOnClickListener(function() if axis=="x" then Config.box_x=Config.box_x+10 else Config.box_y=Config.box_y+10 end; updateBox() end)
    h.addView(btnM); h.addView(tv); h.addView(btnP); content.addView(h)
end
addCalib("X", "x"); addCalib("Y", "y")

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addSl("Recul", "recoil_force", 100)
addSl("Vitesse", "speed_ms", 300)

local btnHide = Button(activity); btnHide.setText("CACHER SETUP"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local lpMenu = WindowManager.LayoutParams(450, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
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
print("✅ V19: SYSTEM WAKE UP")