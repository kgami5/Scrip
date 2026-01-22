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
import "android.os.Build"

-- ================= FORCE SERVICE =================
pcall(auto)

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local SW = activity.getResources().getDisplayMetrics().widthPixels
local SH = activity.getResources().getDisplayMetrics().heightPixels

-- FLAGS
local FLAG_MOVE = 8 -- Focusable
local FLAG_GHOST = 8 + 16 -- Not Touchable

local isLocked = false
local offsetY = 0 -- Correction hauteur

local Pos = { 
    fireX = SW * 0.8, 
    fireY = SH * 0.7,
    camX = SW * 0.75,
    camY = SH * 0.4
}

-- ================= DEBUGGER (POINT D'IMPACT) =================
local debugView = View(activity)
local debugBg = GradientDrawable()
debugBg.setColor(0xFFFFFFFF) -- BLANC
debugBg.setShape(1) -- Rond
debugView.setBackground(debugBg)
-- On utilise FLAG_LAYOUT_NO_LIMITS (512) pour ignorer les bords
local lpDebug = WindowManager.LayoutParams(40, 40, OVERLAY_TYPE, 24 + 512, -3)
lpDebug.gravity = 51 -- Top Left
wm.addView(debugView, lpDebug)
debugView.setVisibility(8)

function showImpact(x, y)
    activity.runOnUiThread(function()
        lpDebug.x = x - 20
        lpDebug.y = y - 20
        debugView.setVisibility(0)
        wm.updateViewLayout(debugView, lpDebug)
        Handler().postDelayed(function() debugView.setVisibility(8) end, 200)
    end)
end

-- ================= FONCTION TIR =================
function shoot()
    if service == nil then
        Toast.makeText(activity, "Service OFF", 0).show()
        return
    end

    -- Application de la correction Y
    local finalX = Pos.fireX
    local finalY = Pos.fireY + offsetY

    -- Montre où ça clique vraiment
    showImpact(finalX, finalY)

    -- 1. TIR
    local p = Path()
    p.moveTo(finalX, finalY)
    local g = GestureDescription.Builder()
    -- Clic plus long (100ms) pour être sûr
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 100))
    service:dispatchGesture(g:build(), nil, nil)
    
    -- 2. RECUL
    local p2 = Path()
    p2.moveTo(Pos.camX, Pos.camY)
    p2.lineTo(Pos.camX, Pos.camY + 35)
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 100))
    service:dispatchGesture(g2:build(), nil, nil)
end

-- ================= UI =================

-- TARGET TIR
local tFire = TextView(activity); tFire.setText("TIR"); tFire.setBackgroundColor(0x88FF0000); tFire.setGravity(17); tFire.setTextColor(Color.WHITE)
local lpFire = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,FLAG_MOVE,-3)
lpFire.gravity=51; lpFire.x=Pos.fireX-65; lpFire.y=Pos.fireY-65
tFire.setOnTouchListener(function(v,e)
    if isLocked then return false end
    if e.getAction()==2 then lpFire.x=e.getRawX()-65; lpFire.y=e.getRawY()-65; Pos.fireX=lpFire.x+65; Pos.fireY=lpFire.y+65; wm.updateViewLayout(tFire,lpFire) end
    return false
end)

-- TARGET CAM
local tCam = TextView(activity); tCam.setText("CAM"); tCam.setBackgroundColor(0x8800FFFF); tCam.setGravity(17); tCam.setTextColor(Color.BLACK)
local lpCam = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,FLAG_MOVE,-3)
lpCam.gravity=51; lpCam.x=Pos.camX-65; lpCam.y=Pos.camY-65
tCam.setOnTouchListener(function(v,e)
    if isLocked then return false end
    if e.getAction()==2 then lpCam.x=e.getRawX()-65; lpCam.y=e.getRawY()-65; Pos.camX=lpCam.x+65; Pos.camY=lpCam.y+65; wm.updateViewLayout(tCam,lpCam) end
    return false
end)

-- MENU CALIBRAGE
local menu = LinearLayout(activity)
menu.setOrientation(1); menu.setBackgroundColor(Color.DKGRAY); menu.setPadding(10,10,10,10)
local lpMenu = WindowManager.LayoutParams(400, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpMenu.gravity=51; lpMenu.x=50; lpMenu.y=100

-- TEXTE OFFSET
local tvOffset = TextView(activity)
tvOffset.setText("Décalage Y: 0px")
tvOffset.setTextColor(Color.WHITE)
tvOffset.setGravity(17)
menu.addView(tvOffset)

-- BOUTONS OFFSET
local hLayout = LinearLayout(activity); hLayout.setOrientation(0); hLayout.setGravity(17)
local btnUp = Button(activity); btnUp.setText("Haut"); btnUp.setOnClickListener(function() offsetY=offsetY-10; tvOffset.setText("Décalage Y: "..offsetY.."px") end)
local btnDown = Button(activity); btnDown.setText("Bas"); btnDown.setOnClickListener(function() offsetY=offsetY+10; tvOffset.setText("Décalage Y: "..offsetY.."px") end)
hLayout.addView(btnUp); hLayout.addView(btnDown)
menu.addView(hLayout)

-- BOUTON LOCK
local btnLock = Button(activity); btnLock.setText("VERROUILLER"); btnLock.setBackgroundColor(Color.LTGRAY)
btnLock.setOnClickListener(function()
    if isLocked then
        isLocked = false; btnLock.setText("VERROUILLER"); btnLock.setBackgroundColor(Color.LTGRAY)
        lpFire.flags = FLAG_MOVE; lpCam.flags = FLAG_MOVE; tFire.setText("TIR"); tCam.setText("CAM")
    else
        isLocked = true; btnLock.setText("DÉVERROUILLER"); btnLock.setBackgroundColor(Color.GREEN)
        lpFire.flags = FLAG_GHOST; lpCam.flags = FLAG_GHOST; tFire.setText(""); tCam.setText("")
    end
    wm.updateViewLayout(tFire, lpFire); wm.updateViewLayout(tCam, lpCam)
end)
menu.addView(btnLock)

-- BOUTON SHOOT
local btn = Button(activity); btn.setText("SHOOT"); btn.setBackgroundColor(Color.YELLOW); btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(250, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity=51; lpBtn.x=100; lpBtn.y=500

btn.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then
        btn.setBackgroundColor(Color.RED)
        if isLocked then shoot() else Toast.makeText(activity, "VERROUILLE D'ABORD !", 0).show() end
    elseif e.getAction() == 1 then
        btn.setBackgroundColor(Color.YELLOW)
    end
    return true
end)

-- BOUTON FERMER
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
close.setOnClickListener(function()
    pcall(function() wm.removeView(tFire); wm.removeView(tCam); wm.removeView(menu); wm.removeView(btn); wm.removeView(debugView) end)
    activity.finish()
end)
menu.addView(close)

pcall(function() wm.addView(tFire, lpFire); wm.addView(tCam, lpCam); wm.addView(menu, lpMenu); wm.addView(btn, lpBtn) end)

print("✅ V43 CALIBRATION")