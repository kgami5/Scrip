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

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local SW = activity.getResources().getDisplayMetrics().widthPixels
local SH = activity.getResources().getDisplayMetrics().heightPixels

-- FLAGS IMPORTANTS
-- FLAG_NOT_FOCUSABLE (8) = On peut déplacer
-- FLAG_NOT_TOUCHABLE (16) = Les clics passent à travers (Ghost)
local FLAG_MOVE = 8
local FLAG_GHOST = 8 + 16 

local isLocked = false -- Par défaut, on peut bouger les cibles

local Pos = { 
    fireX = SW * 0.8, 
    fireY = SH * 0.7,
    camX = SW * 0.75,
    camY = SH * 0.4
}

-- ================= FONCTION TIR =================
function shoot()
    if service == nil then
        Toast.makeText(activity, "Service OFF - Relance l'app", 0).show()
        return
    end

    -- 1. TIR
    local p = Path()
    p.moveTo(Pos.fireX, Pos.fireY)
    local g = GestureDescription.Builder()
    -- Durée 80ms pour être sûr que ça enregistre
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 80))
    service:dispatchGesture(g:build(), nil, nil)
    
    -- 2. RECUL
    local p2 = Path()
    p2.moveTo(Pos.camX, Pos.camY)
    p2.lineTo(Pos.camX, Pos.camY + 35)
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 80))
    service:dispatchGesture(g2:build(), nil, nil)
end

-- ================= UI =================

-- TARGET TIR
local tFire = TextView(activity); tFire.setText("TIR"); tFire.setBackgroundColor(0x88FF0000); tFire.setGravity(17); tFire.setTextColor(Color.WHITE)
local lpFire = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,FLAG_MOVE,-3)
lpFire.gravity=51; lpFire.x=Pos.fireX-65; lpFire.y=Pos.fireY-65
tFire.setOnTouchListener(function(v,e)
    if isLocked then return false end -- Si verrouillé, on ne bouge plus
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

-- BOUTON LOCK (VERROUILLAGE)
local btnLock = Button(activity)
btnLock.setText("🔓")
btnLock.setBackgroundColor(Color.LTGRAY)
local lpLock = WindowManager.LayoutParams(150, 150, OVERLAY_TYPE, 8, -3)
lpLock.gravity=51; lpLock.x=100; lpLock.y=200

btnLock.setOnClickListener(function()
    if isLocked then
        -- ON DEVERROUILLE (Mode Setup)
        isLocked = false
        btnLock.setText("🔓")
        btnLock.setBackgroundColor(Color.LTGRAY)
        
        -- On rend les cibles tactiles
        lpFire.flags = FLAG_MOVE
        lpCam.flags = FLAG_MOVE
        tFire.setText("TIR") -- On remet le texte
        tCam.setText("CAM")
    else
        -- ON VERROUILLE (Mode Jeu)
        isLocked = true
        btnLock.setText("🔒")
        btnLock.setBackgroundColor(Color.GREEN)
        
        -- On rend les cibles "Fantômes" (Clic traverse)
        lpFire.flags = FLAG_GHOST
        lpCam.flags = FLAG_GHOST
        tFire.setText("") -- On cache le texte pour mieux voir
        tCam.setText("")
    end
    -- Mise à jour des fenêtres
    wm.updateViewLayout(tFire, lpFire)
    wm.updateViewLayout(tCam, lpCam)
end)

-- BOUTON SHOOT
local btn = Button(activity)
btn.setText("SHOOT")
btn.setBackgroundColor(Color.YELLOW)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(250, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity=51; lpBtn.x=100; lpBtn.y=400

btn.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then
        btn.setBackgroundColor(Color.RED)
        if isLocked then
            shoot()
        else
            Toast.makeText(activity, "🔒 VERROUILLE D'ABORD !", 0).show()
        end
    elseif e.getAction() == 1 then
        btn.setBackgroundColor(Color.YELLOW)
    end
    return true
end)

-- FERMER
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3)
lpClose.x=0; lpClose.y=0
close.setOnClickListener(function()
    pcall(function() wm.removeView(tFire) end)
    pcall(function() wm.removeView(tCam) end)
    pcall(function() wm.removeView(btnLock) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(close) end)
    activity.finish()
end)

pcall(function() wm.addView(tFire, lpFire) end)
pcall(function() wm.addView(tCam, lpCam) end)
pcall(function() wm.addView(btnLock, lpLock) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(close, lpClose) end)

print("✅ V42 GHOST MODE")