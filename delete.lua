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

-- ================= FORCE START =================
pcall(auto) 

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local FireX, FireY = SW/2, SH/2

-- ================= UI MONITORING =================

-- BANNIERE DE STATUT (EN HAUT)
local statusPanel = TextView(activity)
statusPanel.setText("INITIALISATION...")
statusPanel.setTextSize(14)
statusPanel.setGravity(17)
statusPanel.setTextColor(Color.WHITE)
statusPanel.setBackgroundColor(Color.DKGRAY)
local lpStatus = WindowManager.LayoutParams(600, 150, OVERLAY_TYPE, 24, -3) -- 24 = Pas touche
lpStatus.gravity = 49 -- Top Center
lpStatus.y = 50

-- FONCTION QUI VERIFIE TOUTES LES 1 SECONDE
local handler = Handler(Looper.getMainLooper())
local checkLoop = Runnable({ run = function()
    if service == nil then
        -- SERVICE DECONNECTÉ
        statusPanel.setText("❌ SERVICE DÉCONNECTÉ\nFais OFF puis ON dans les paramètres !")
        statusPanel.setBackgroundColor(0xCCFF0000) -- ROUGE
    else
        -- SERVICE CONNECTÉ
        statusPanel.setText("✅ SERVICE CONNECTÉ\nPrêt à tirer !")
        statusPanel.setBackgroundColor(0xCC00FF00) -- VERT
    end
    handler.postDelayed(checkLoop, 1000) -- Vérifie chaque seconde
end})

-- Lancer la vérification
handler.post(checkLoop)

-- ================= FONCTION TIR =================
function forceClick()
    if service == nil then
        Toast.makeText(activity, "Je ne peux pas cliquer, service éteint !", 0).show()
        -- On force la réouverture des paramètres
        local intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
        return
    end

    local p = Path()
    p.moveTo(FireX, FireY)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    service:dispatchGesture(g:build(), nil, nil)
end

-- ================= ELEMENTS UI =================

local target = TextView(activity)
target.setText("CIBLE")
target.setGravity(17); target.setTextColor(Color.WHITE); target.setBackgroundColor(0x88FF0000)
local lpTarget = WindowManager.LayoutParams(150, 150, OVERLAY_TYPE, 8, -3)
lpTarget.gravity = 51; lpTarget.x = SW/2 - 75; lpTarget.y = SH/2 - 75

local tx, ty
target.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then tx=e.getRawX()-lpTarget.x; ty=e.getRawY()-lpTarget.y return true
    elseif e.getAction() == 2 then 
        lpTarget.x=e.getRawX()-tx; lpTarget.y=e.getRawY()-ty; 
        FireX = lpTarget.x + 75; FireY = lpTarget.y + 75
        wm.updateViewLayout(target, lpTarget) 
        return true 
    end
    return false
end)

local btn = Button(activity)
btn.setText("TEST CLIC")
btn.setBackgroundColor(Color.BLUE); btn.setTextColor(Color.WHITE)
local lpBtn = WindowManager.LayoutParams(300, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 100; lpBtn.y = 300
btn.setOnClickListener(function() forceClick() end)

local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpClose.x = 0; lpClose.y = 0
close.setOnClickListener(function() 
    handler.removeCallbacks(checkLoop)
    pcall(function() wm.removeView(statusPanel) end)
    pcall(function() wm.removeView(target) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(close) end)
end)

pcall(function() wm.addView(statusPanel, lpStatus) end)
pcall(function() wm.addView(target, lpTarget) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(close, lpClose) end)

print("🔍 V29 MONITORING")