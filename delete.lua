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
    recoil_force = 30,   
    scan_force = 30,     
    speed_ms = 80, -- Vitesse de tir
    is_firing = false
}

local Pos = { fireX=0, fireY=0, camX=0, camY=0 }
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Positions par défaut
Pos.fireX, Pos.fireY = SW * 0.8, SH * 0.7
Pos.camX, Pos.camY = SW * 0.75, SH * 0.4

local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- ================= DEBUGGER =================
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

-- ================= MOTEUR VIRTUEL =================

function performShootingAction()
    if not accessibilityService then return end
    
    -- 1. CLIC SUR LE BOUTON TIR DU JEU
    showTouch(Pos.fireX, Pos.fireY) -- Preuve visuelle
    local p1 = Path(); p1.moveTo(Pos.fireX, Pos.fireY)
    local g1 = GestureDescription.Builder()
    g1.addStroke(GestureDescription.StrokeDescription(p1, 0, 50))
    pcall(function() accessibilityService:dispatchGesture(g1:build(), nil, nil) end)

    -- 2. MOUVEMENT CAMERA (Zone Vide)
    local moveY = Config.recoil_force
    local moveX = 0
    
    -- Effet Jitter (Aim Assist)
    if os.time() % 2 == 0 then moveX = Config.scan_force else moveX = -Config.scan_force end
    
    local p2 = Path()
    p2.moveTo(Pos.camX, Pos.camY)
    p2.lineTo(Pos.camX + moveX, Pos.camY + moveY)
    
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 70))
    pcall(function() accessibilityService:dispatchGesture(g2:build(), nil, nil) end)
end

-- BOUCLE DE TIR
local handler = Handler(Looper.getMainLooper())
local fireLoop = Runnable({ run = function()
    if Config.is_firing then
        performShootingAction()
        handler.postDelayed(fireLoop, Config.speed_ms)
    end
end})

-- ================= UI VIRTUELLE =================

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

-- Cibles de configuration
createTarget(0x88FF0000, "CIBLE\nTIR", SW*0.8, SH*0.6, function(x,y) Pos.fireX=x; Pos.fireY=y end)
createTarget(0x8800FFFF, "ZONE\nCAM", SW*0.7, SH*0.4, function(x,y) Pos.camX=x; Pos.camY=y end)


-- *** LE BOUTON MAGIQUE (TRIGGER) ***
local btnTrigger = Button(activity)
btnTrigger.setText("SHOOT")
btnTrigger.setTextColor(Color.BLACK)
btnTrigger.setTextSize(18)
local bgTrig = GradientDrawable()
bgTrig.setColor(0xFFFFD700) -- OR / JAUNE
bgTrig.setCornerRadius(100)
bgTrig.setStroke(5, Color.WHITE)
btnTrigger.setBackground(bgTrig)

local lpTrig = WindowManager.LayoutParams(180, 180, OVERLAY_TYPE, 8, -3) -- FLAG_NOT_TOUCH_MODAL
lpTrig.gravity = 51
lpTrig.x = SW * 0.85 -- Position par défaut (à la place de ton bouton tir habituel)
lpTrig.y = SH * 0.65

-- LOGIQUE DU BOUTON MAGIQUE
local tx, ty
btnTrigger.setOnTouchListener(function(v, event)
    local action = event.getAction()
    
    if action == MotionEvent.ACTION_DOWN then
        -- Quand on appuie : On active le tir
        Config.is_firing = true
        bgTrig.setColor(0xFFFF0000) -- Devient Rouge
        handler.post(fireLoop)
        
        -- Pour déplacer le bouton si besoin (optionnel)
        tx = event.getRawX() - lpTrig.x
        ty = event.getRawY() - lpTrig.y
        return true
        
    elseif action == MotionEvent.ACTION_UP then
        -- Quand on relâche : On arrête tout
        Config.is_firing = false
        bgTrig.setColor(0xFFFFD700) -- Revient Jaune
        handler.removeCallbacks(fireLoop)
        return true
        
    elseif action == MotionEvent.ACTION_MOVE then
        -- Déplacement du bouton (si on glisse loin)
        -- On ne déplace que si on bouge beaucoup pour ne pas gêner le tir
        if Math.abs(event.getRawX() - lpTrig.x - tx) > 20 then
             lpTrig.x = event.getRawX() - tx
             lpTrig.y = event.getRawY() - ty
             wm.updateViewLayout(btnTrigger, lpTrig)
        end
        return true
    end
    return false
end)

wm.addView(btnTrigger, lpTrig)


-- MENU REGLAGES
local menu = LinearLayout(activity); menu.setOrientation(1); menu.setPadding(10,10,10,10)
local bgMenu = GradientDrawable(); bgMenu.setColor(0xEE111111); bgMenu.setCornerRadius(10); bgMenu.setStroke(2, Color.YELLOW)
menu.setBackground(bgMenu); menu.setVisibility(8) -- Caché au début

local scroll = ScrollView(activity); scroll.setLayoutParams(LinearLayout.LayoutParams(-1, 300)); menu.addView(scroll)
local content = LinearLayout(activity); content.setOrientation(1); scroll.addView(content)

local t = TextView(activity); t.setText("VIRTUAL CONTROLLER"); t.setTextColor(Color.YELLOW); t.setGravity(17); content.addView(t)

local function addSl(txt,k,max)
    local tv = TextView(activity); tv.setText(txt..": "..Config[k]); tv.setTextColor(Color.LTGRAY); content.addView(tv)
    local sk = SeekBar(activity); sk.setMax(max); sk.setProgress(Config[k])
    sk.setOnSeekBarChangeListener({onProgressChanged=function(_,p) Config[k]=p; tv.setText(txt..": "..p) end}); content.addView(sk)
end

addSl("Force Recul", "recoil_force", 100)
addSl("Force Aim", "scan_force", 100)
addSl("Vitesse Tir", "speed_ms", 200)

local btnHide = Button(activity); btnHide.setText("CACHER CIBLES"); btnHide.setOnClickListener(function()
    for _,x in pairs(targets) do if x.getVisibility()==0 then x.setVisibility(8) else x.setVisibility(0) end end
end); content.addView(btnHide)

local btnClose = Button(activity); btnClose.setText("FERMER MENU"); btnClose.setOnClickListener(function() menu.setVisibility(8) end); content.addView(btnClose)

local lpMenu = WindowManager.LayoutParams(450, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=200; lpMenu.y=50

-- PETIT BOUTON MENU
local btnM = Button(activity); btnM.setText("⚙️"); 
local lpM = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3); lpM.gravity=51; lpM.x=50; lpM.y=50
btnM.setOnClickListener(function() if menu.getVisibility()==0 then menu.setVisibility(8) else menu.setVisibility(0) end end)

wm.addView(btnM, lpM)
wm.addView(menu, lpMenu)
print("✅ V23: UTILISE LE BOUTON JAUNE !")