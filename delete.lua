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

-- ================= DEMARRAGE SERVICE =================
-- On essaie simplement d'activer le service standard
pcall(auto)

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- Positions par défaut
local Pos = {
    fireX = SW * 0.8, fireY = SH * 0.7,
    camX = SW * 0.75, camY = SH * 0.4
}

-- ================= FONCTION TIR SECURISEE =================
function shoot()
    -- On vérifie UNIQUEMENT la variable globale 'service'
    -- C'est la seule qui est sûre à 100%
    if service == nil then
        Toast.makeText(activity, "Service OFF ! Réinstalle l'app ou active Accessibilité", 1).show()
        local intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
        return
    end

    -- 1. TIR
    local p = Path()
    p.moveTo(Pos.fireX, Pos.fireY)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    service:dispatchGesture(g:build(), nil, nil)
    
    -- 2. RECUL (Zone Cam)
    local p2 = Path()
    p2.moveTo(Pos.camX, Pos.camY)
    p2.lineTo(Pos.camX, Pos.camY + 30)
    local g2 = GestureDescription.Builder()
    g2.addStroke(GestureDescription.StrokeDescription(p2, 0, 80))
    service:dispatchGesture(g2:build(), nil, nil)
end

-- ================= UI & DEPLACEMENT =================

-- Fonction générique pour déplacer n'importe quelle fenêtre
function addDragListener(view, layoutParams, callback)
    local touchX, touchY
    view.setOnTouchListener(function(v, event)
        if event.getAction() == MotionEvent.ACTION_DOWN then
            touchX = event.getRawX() - layoutParams.x
            touchY = event.getRawY() - layoutParams.y
            return true
        elseif event.getAction() == MotionEvent.ACTION_MOVE then
            layoutParams.x = event.getRawX() - touchX
            layoutParams.y = event.getRawY() - touchY
            wm.updateViewLayout(view, layoutParams)
            if callback then callback(layoutParams.x, layoutParams.y) end
            return true
        end
        return false
    end)
end

-- 1. CIBLE ROUGE (TIR)
local tFire = TextView(activity)
tFire.setText("TIR")
tFire.setGravity(17)
tFire.setTextColor(Color.WHITE)
tFire.setBackgroundColor(0x88FF0000) -- Rouge semi-transparent
local lpFire = WindowManager.LayoutParams(130, 130, OVERLAY_TYPE, 8, -3)
lpFire.gravity = 51
lpFire.x = Pos.fireX - 65
lpFire.y = Pos.fireY - 65

-- Ajout du déplacement
addDragListener(tFire, lpFire, function(x, y)
    Pos.fireX = x + 65
    Pos.fireY = y + 65
end)

-- 2. CIBLE CYAN (CAM)
local tCam = TextView(activity)
tCam.setText("ZONE\nCAM")
tCam.setGravity(17)
tCam.setTextColor(Color.BLACK)
tCam.setBackgroundColor(0x8800FFFF) -- Cyan
local lpCam = WindowManager.LayoutParams(130, 130, OVERLAY_TYPE, 8, -3)
lpCam.gravity = 51
lpCam.x = Pos.camX - 65
lpCam.y = Pos.camY - 65

-- Ajout du déplacement
addDragListener(tCam, lpCam, function(x, y)
    Pos.camX = x + 65
    Pos.camY = y + 65
end)

-- 3. BOUTON JAUNE (SHOOT)
local btn = Button(activity)
btn.setText("SHOOT")
btn.setTextColor(Color.BLACK)
btn.setBackgroundColor(Color.YELLOW)
local lpBtn = WindowManager.LayoutParams(200, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51
lpBtn.x = 100
lpBtn.y = 400

-- Logique Tir + Déplacement du bouton
local bx, by
btn.setOnTouchListener(function(v, e)
    if e.getAction() == MotionEvent.ACTION_DOWN then
        bx = e.getRawX() - lpBtn.x
        by = e.getRawY() - lpBtn.y
        btn.setBackgroundColor(Color.RED)
        shoot() -- Action de tir
        return true
    elseif e.getAction() == MotionEvent.ACTION_MOVE then
        -- Si on bouge beaucoup, on déplace le bouton
        if Math.abs(e.getRawX() - bx - lpBtn.x) > 10 then
            lpBtn.x = e.getRawX() - bx
            lpBtn.y = e.getRawY() - by
            wm.updateViewLayout(btn, lpBtn)
        end
        return true
    elseif e.getAction() == MotionEvent.ACTION_UP then
        btn.setBackgroundColor(Color.YELLOW)
        return true
    end
    return false
end)

-- 4. BANNIERE DIAGNOSTIC
local status = TextView(activity)
status.setText("CHARGEMENT...")
status.setBackgroundColor(Color.BLACK)
status.setTextColor(Color.WHITE)
status.setGravity(17)
local lpStatus = WindowManager.LayoutParams(500, 100, OVERLAY_TYPE, 24, -3) -- 24=Pas touche
lpStatus.gravity = 49
lpStatus.y = 50

-- 5. BOUTON FERMER
local close = Button(activity)
close.setText("X")
close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpClose.x = 0; lpClose.y = 0
close.setOnClickListener(function()
    pcall(function() wm.removeView(tFire) end)
    pcall(function() wm.removeView(tCam) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(status) end)
    pcall(function() wm.removeView(close) end)
    activity.finish()
end)

-- AFFICHAGE
pcall(function() wm.addView(tFire, lpFire) end)
pcall(function() wm.addView(tCam, lpCam) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(status, lpStatus) end)
pcall(function() wm.addView(close, lpClose) end)

-- BOUCLE DE CHECK (Est-ce que init.lua a marché ?)
local handler = Handler(Looper.getMainLooper())
local check = Runnable({ run = function()
    if service then
        status.setText("✅ SERVICE OK (V34)")
        status.setBackgroundColor(0xFF00AA00)
    else
        status.setText("❌ SERVICE NUL")
        status.setBackgroundColor(0xFFAA0000)
    end
    handler.postDelayed(check, 1000)
end})
handler.post(check)

print("✅ V34 NO-CRASH")