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

-- DETECTE LA VERSION ANDROID
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

-- RECUPERE LE SERVICE
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)

-- POSITIONS
local FireX, FireY = SW/2, SH/2

-- FONCTION DE CLIC PURE
function forceClick()
    -- VERIFICATION 1 : Le service existe-t-il ?
    if not accessibilityService then
        print("❌ ERREUR CRITIQUE : Service Accessibilité ÉTEINT ou INACCESSIBLE !")
        Toast.makeText(activity, "Active l'Accessibilité pour cette app !", Toast.LENGTH_LONG).show()
        return
    end

    -- CLIC
    print("✅ Envoi de l'ordre de clic...")
    local p = Path()
    p.moveTo(FireX, FireY)
    local g = GestureDescription.Builder()
    -- Durée 80ms (Standard)
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 80))
    
    local success = accessibilityService:dispatchGesture(g:build(), nil, nil)
    
    if success then
        print("Signal envoyé au système.")
    else
        print("⚠️ Le système a reçu l'ordre mais l'a ignoré (Conflit ?)")
    end
end

-- ================= UI DE TEST =================

-- CIBLE ROUGE
local target = TextView(activity)
target.setText("CIBLE")
target.setGravity(17)
target.setTextColor(Color.WHITE)
target.setBackgroundColor(0x88FF0000) -- Rouge semi-transparent
local lpTarget = WindowManager.LayoutParams(150, 150, OVERLAY_TYPE, 8, -3)
lpTarget.gravity = 51
lpTarget.x = SW/2 - 75
lpTarget.y = SH/2 - 75

-- Deplacement Cible
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

-- BOUTON DECLENCHEUR
local btn = Button(activity)
btn.setText("TEST CLICK")
btn.setBackgroundColor(Color.YELLOW)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(300, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51
lpBtn.x = 100
lpBtn.y = 200

btn.setOnClickListener(function()
    btn.setBackgroundColor(Color.RED)
    forceClick()
    -- Remet en jaune après 100ms
    Handler().postDelayed(function() btn.setBackgroundColor(Color.YELLOW) end, 100)
end)

-- BOUTON FERMER
local close = Button(activity)
close.setText("X")
close.setBackgroundColor(Color.BLACK)
close.setTextColor(Color.WHITE)
local lpClose = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpClose.x = 0; lpClose.y = 0
close.setOnClickListener(function()
    wm.removeView(target)
    wm.removeView(btn)
    wm.removeView(close)
    print("Fermé")
end)

-- AJOUT A L'ECRAN
wm.addView(target, lpTarget)
wm.addView(btn, lpBtn)
wm.addView(close, lpClose)

print("🔍 MODE DIAGNOSTIC ACTIVÉ")
print("1. Place la CIBLE ROUGE sur une icône")
print("2. Appuie sur TEST CLICK")