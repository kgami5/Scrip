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

-- ================= DEMARRAGE DOUX =================
-- On demande le service, mais on ne force pas d'import Java risqué
pcall(auto)

-- ================= CONFIGURATION =================
local OVERLAY_TYPE
if Build.VERSION.SDK_INT >= 26 then OVERLAY_TYPE = 2038 else OVERLAY_TYPE = 2002 end

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local SW = activity.getResources().getDisplayMetrics().widthPixels
local SH = activity.getResources().getDisplayMetrics().heightPixels

-- Positions par défaut
local Pos = { 
    fireX = SW * 0.8, 
    fireY = SH * 0.7,
    camX = SW * 0.75,
    camY = SH * 0.4
}

-- ================= FONCTION TIR SÉCURISÉE =================
function shoot()
    -- VÉRIFICATION SIMPLE : Est-ce que la variable 'service' existe ?
    if service == nil then
        Toast.makeText(activity, "⚠️ SERVICE DÉCONNECTÉ", 0).show()
        -- On relance la demande d'accès
        pcall(auto)
        return
    end

    -- Si on est ici, c'est que le service est là !
    local p = Path()
    p.moveTo(Pos.fireX, Pos.fireY)
    
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    
    -- Appel protégé pour éviter tout crash
    pcall(function() 
        service:dispatchGesture(g:build(), nil, nil) 
    end)
    
    -- Recul (Zone Cam)
    local p2 = Path()
    p2.moveTo(Pos.camX, Pos.camY)
    p2.lineTo(Pos.camX, Pos.camY + 35)
    
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 80))
    
    pcall(function() 
        service:dispatchGesture(g2:build(), nil, nil) 
    end)
end

-- ================= INTERFACE =================

-- CIBLE TIR
local tFire = TextView(activity); tFire.setText("TIR"); tFire.setBackgroundColor(0x88FF0000); tFire.setGravity(17); tFire.setTextColor(Color.WHITE)
local lpFire = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,8,-3)
lpFire.gravity=51; lpFire.x=Pos.fireX-65; lpFire.y=Pos.fireY-65
tFire.setOnTouchListener(function(v,e)
    if e.getAction()==2 then lpFire.x=e.getRawX()-65; lpFire.y=e.getRawY()-65; Pos.fireX=lpFire.x+65; Pos.fireY=lpFire.y+65; wm.updateViewLayout(tFire,lpFire) end
    return false
end)

-- CIBLE CAM
local tCam = TextView(activity); tCam.setText("ZONE\nCAM"); tCam.setBackgroundColor(0x8800FFFF); tCam.setGravity(17); tCam.setTextColor(Color.BLACK)
local lpCam = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,8,-3)
lpCam.gravity=51; lpCam.x=Pos.camX-65; lpCam.y=Pos.camY-65
tCam.setOnTouchListener(function(v,e)
    if e.getAction()==2 then lpCam.x=e.getRawX()-65; lpCam.y=e.getRawY()-65; Pos.camX=lpCam.x+65; Pos.camY=lpCam.y+65; wm.updateViewLayout(tCam,lpCam) end
    return false
end)

-- BOUTON SHOOT (JAUNE)
local btn = Button(activity)
btn.setText("SHOOT")
btn.setBackgroundColor(Color.YELLOW)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(250, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity=51; lpBtn.x=100; lpBtn.y=400

btn.setOnTouchListener(function(v, e)
    local action = e.getAction()
    if action == 0 then
        btn.setBackgroundColor(Color.RED)
        shoot()
    elseif action == 1 then
        btn.setBackgroundColor(Color.YELLOW)
    end
    return true
end)

-- BANNIERE ETAT (INDISPENSABLE POUR SAVOIR SI CA MARCHE)
local status = TextView(activity)
status.setText("SCAN DU SERVICE...")
status.setTextSize(14)
status.setGravity(17)
status.setTextColor(Color.WHITE)
status.setBackgroundColor(Color.BLACK)
local lpStatus = WindowManager.LayoutParams(600, 150, OVERLAY_TYPE, 24, -3)
lpStatus.gravity = 49; lpStatus.y = 50

-- BOUCLE DE VERIFICATION SANS CRASH
local handler = Handler(Looper.getMainLooper())
local loop = Runnable({ run = function()
    if service ~= nil then
        status.setText("✅ CONNECTÉ !\nTout est prêt.")
        status.setBackgroundColor(0xFF00AA00)
    else
        status.setText("❌ DÉCONNECTÉ\nRedémarre le téléphone si ça persiste.")
        status.setBackgroundColor(0xFFAA0000)
        -- On réessaie l'auto connect
        pcall(auto)
    end
    handler.postDelayed(loop, 1000)
end})
handler.post(loop)

-- FERMER
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3)
lpClose.x=0; lpClose.y=0
close.setOnClickListener(function()
    handler.removeCallbacks(loop)
    pcall(function() wm.removeView(tFire) end)
    pcall(function() wm.removeView(tCam) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(status) end)
    pcall(function() wm.removeView(close) end)
    activity.finish()
end)

pcall(function() wm.addView(tFire, lpFire) end)
pcall(function() wm.addView(tCam, lpCam) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(status, lpStatus) end)
pcall(function() wm.addView(close, lpClose) end)

print("✅ V41 STABLE CHARGÉE")