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

-- ================= FORCE SERVICE RECOVERY =================
-- Cette commande tente de relancer le service interne
pcall(auto) 

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Position du tir et de la caméra (Zone vide)
local FireX, FireY = SW * 0.8, SH * 0.7
local CamX, CamY = SW * 0.75, SH * 0.4

-- ================= INTERFACE DE CONTROLE =================

-- BANNIERE ETAT
local status = TextView(activity)
status.setText("⏳ CHARGEMENT...")
status.setBackgroundColor(Color.DKGRAY)
status.setTextColor(Color.WHITE)
status.setGravity(17)
local lpStatus = WindowManager.LayoutParams(500, 150, OVERLAY_TYPE, 8, -3)
lpStatus.gravity = 49; lpStatus.y = 50

-- FONCTION DE VERIFICATION CONTINUE
local handler = Handler(Looper.getMainLooper())
local loop = Runnable({ run = function()
    -- On essaie de détecter le service
    if service then
        status.setText("✅ CONNECTÉ !\nAppuie sur SHOOT")
        status.setBackgroundColor(0xFF00AA00) -- Vert
    else
        status.setText("❌ DÉCONNECTÉ\n1. Redémarre le téléphone\n2. Active Accessibilité")
        status.setBackgroundColor(0xFFAA0000) -- Rouge
    end
    handler.postDelayed(loop, 1000)
end})
handler.post(loop)

-- ================= MOTEUR DE TIR (HYBRIDE) =================
function shoot()
    if not service then
        Toast.makeText(activity, "Service éteint ! Redémarre le tel.", 0).show()
        -- Ouvre les paramètres pour toi
        local intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
        return
    end

    -- 1. CLIC (TIR)
    local p = Path(); p.moveTo(FireX, FireY)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    service:dispatchGesture(g:build(), nil, nil)
    
    -- 2. RECUL (CAMERA)
    local p2 = Path(); p2.moveTo(CamX, CamY)
    p2.lineTo(CamX, CamY + 30) -- Descente de 30 pixels
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 80))
    service:dispatchGesture(g2:build(), nil, nil)
end

-- ================= CIBLES ET BOUTONS =================

-- CIBLE TIR
local tFire = TextView(activity); tFire.setText("TIR"); tFire.setBackgroundColor(0x88FF0000); tFire.setGravity(17)
local lpFire = WindowManager.LayoutParams(120,120,OVERLAY_TYPE,8,-3)
lpFire.gravity=51; lpFire.x=FireX-60; lpFire.y=FireY-60
-- Drag Tir
local tfx, tfy
tFire.setOnTouchListener(function(v,e)
    if e.getAction()==0 then tfx=e.getRawX()-lpFire.x; tfy=e.getRawY()-lpFire.y return true
    elseif e.getAction()==2 then lpFire.x=e.getRawX()-tfx; lpFire.y=e.getRawY()-tfy; FireX=lpFire.x+60; FireY=lpFire.y+60; wm.updateViewLayout(tFire,lpFire) return true end
    return false
end)

-- CIBLE CAM
local tCam = TextView(activity); tCam.setText("CAM"); tCam.setBackgroundColor(0x8800FFFF); tCam.setGravity(17)
local lpCam = WindowManager.LayoutParams(120,120,OVERLAY_TYPE,8,-3)
lpCam.gravity=51; lpCam.x=CamX-60; lpCam.y=CamY-60
-- Drag Cam
local tcx, tcy
tCam.setOnTouchListener(function(v,e)
    if e.getAction()==0 then tcx=e.getRawX()-lpCam.x; tcy=e.getRawY()-lpCam.y return true
    elseif e.getAction()==2 then lpCam.x=e.getRawX()-tcx; lpCam.y=e.getRawY()-tcy; CamX=lpCam.x+60; CamY=lpCam.y+60; wm.updateViewLayout(tCam,lpCam) return true end
    return false
end)

-- BOUTON SHOOT (JAUNE)
local btn = Button(activity); btn.setText("SHOOT"); btn.setBackgroundColor(Color.YELLOW); btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(200, 200, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 100; lpBtn.y = 300

btn.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then
        btn.setBackgroundColor(Color.RED)
        shoot() -- Tire une fois
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
    handler.removeCallbacks(loop)
    pcall(function() wm.removeView(status); wm.removeView(tFire); wm.removeView(tCam); wm.removeView(btn); wm.removeView(close) end)
end)

-- AJOUT
pcall(function() wm.addView(status, lpStatus) end)
pcall(function() wm.addView(tFire, lpFire) end)
pcall(function() wm.addView(tCam, lpCam) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(close, lpClose) end)

print("✅ V31 RECOVERY LANCÉE")