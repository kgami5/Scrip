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

-- ================= CORRECTIF CRITIQUE =================
-- On demande à l'appli de charger le module Auto
-- Si une popup demande l'accès, dis OUI.
pcall(auto) 

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- POSITIONS
local FireX, FireY = SW/2, SH/2

-- ================= FONCTION DE CLIC CORRIGÉE =================
function forceClick()
    -- C'EST ICI QUE CA CHANGE
    -- On n'utilise plus getSystemService. On utilise la variable globale 'service'.
    -- 'service' est l'instance magique fournie par AndLua.
    local myService = service 

    -- Si 'service' est vide, on essaie de récupérer le contexte d'activité (solution de secours)
    if not myService then
        myService = activity.getLuaAccessibilityService and activity.getLuaAccessibilityService()
    end

    if not myService then
        print("❌ ERREUR : Le Service est INTROUVABLE !")
        print("💡 Solution : Vérifie que tu as lancé le script en mode 'Accessibilité' dans ton app.")
        Toast.makeText(activity, "Service Accessibilité non détecté", Toast.LENGTH_LONG).show()
        return
    end

    -- CLIC
    print("✅ Tentative de clic via le Service...")
    local p = Path()
    p.moveTo(FireX, FireY)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50))
    
    -- On appelle dispatchGesture sur le BON objet cette fois
    local success = myService:dispatchGesture(g:build(), nil, nil)
    
    if success then
        print("⚡ Signal envoyé !")
    else
        print("⚠️ Échec de l'envoi (Bloqué par le système ?)")
    end
end

-- ================= UI DE TEST =================

local target = TextView(activity)
target.setText("CIBLE")
target.setGravity(17)
target.setTextColor(Color.WHITE)
target.setBackgroundColor(0x88FF0000)
local lpTarget = WindowManager.LayoutParams(150, 150, OVERLAY_TYPE, 8, -3)
lpTarget.gravity = 51
lpTarget.x = SW/2 - 75
lpTarget.y = SH/2 - 75

local tx, ty
target.setOnTouchListener(function(v, e)
    if e.getAction() == 0 then tx=e.getRawX()-lpTarget.x; ty=e.getRawY()-lpTarget.y return true
    elseif e.getAction() == 2 then 
        lpTarget.x=e.getRawX()-tx; lpTarget.y=e.getRawY()-ty; 
        FireX = lpTarget.x + 75
        FireY = lpTarget.y + 75
        wm.updateViewLayout(target, lpTarget) 
        return true 
    end
    return false
end)

local btn = Button(activity)
btn.setText("TEST V26")
btn.setBackgroundColor(Color.CYAN)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(300, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51
lpBtn.x = 100; lpBtn.y = 200

btn.setOnClickListener(function()
    forceClick()
end)

local close = Button(activity)
close.setText("X")
close.setBackgroundColor(Color.BLACK); close.setTextColor(Color.WHITE)
local lpClose = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpClose.x = 0; lpClose.y = 0
close.setOnClickListener(function() wm.removeView(target); wm.removeView(btn); wm.removeView(close) end)

wm.addView(target, lpTarget)
wm.addView(btn, lpBtn)
wm.addView(close, lpClose)

print("🔍 V26 LANCÉE")
print("Appuie sur TEST V26")