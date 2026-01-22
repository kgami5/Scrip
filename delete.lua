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

-- ================= ETAPE 1 : FORCER LE SERVICE =================
-- On essaie de lancer le service auto.
-- Si ça ne fait rien, tu devras aller l'activer manuellement dans les paramètres.
pcall(auto) 

-- ================= CONFIGURATION =================
local OVERLAY_TYPE
if Build.VERSION.SDK_INT >= 26 then
    OVERLAY_TYPE = 2038
else
    OVERLAY_TYPE = 2002
end

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local FireX, FireY = SW/2, SH/2

-- ================= FONCTION CLIC SECURISEE =================
function forceClick()
    -- VERIFICATION SIMPLE ET PUISSANTE
    -- On vérifie juste si la variable globale 'service' existe.
    if service == nil then
        print("❌ ERREUR : Le Service est DÉCONNECTÉ !")
        print("👉 Va dans Paramètres -> Accessibilité -> Ton App -> ACTIVE-LE.")
        Toast.makeText(activity, "Active l'Accessibilité pour ce script !", 1).show()
        
        -- Tentative de réouverture des paramètres
        local intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
        return
    end

    -- Si on est là, c'est que le service est connecté !
    print("✅ Service connecté. Envoi du clic...")
    
    local p = Path()
    p.moveTo(FireX, FireY)
    
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 50)) -- 50ms de clic
    
    -- On utilise le service directement
    local success = service:dispatchGesture(g:build(), nil, nil)
    
    if success then
        print("⚡ Commande envoyée au système.")
    else
        print("⚠️ Commande envoyée mais refusée par Android (Conflit ?)")
    end
end

-- ================= UI TEST =================

-- CIBLE (Pour viser)
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
        FireX = lpTarget.x + 75; FireY = lpTarget.y + 75
        wm.updateViewLayout(target, lpTarget) 
        return true 
    end
    return false
end)

-- BOUTON TEST
local btn = Button(activity)
btn.setText("TEST V28 (SAFE)")
btn.setBackgroundColor(Color.GREEN)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(400, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 100; lpBtn.y = 200

btn.setOnClickListener(function()
    forceClick()
end)

-- BOUTON FERMER
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, 8, -3)
lpClose.x = 0; lpClose.y = 0
close.setOnClickListener(function() 
    pcall(function() wm.removeView(target) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(close) end)
end)

-- AFFICHAGE
pcall(function() wm.addView(target, lpTarget) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(close, lpClose) end)

print("🔍 V28 LANCÉE (Crash Fixé)")
print("Place la cible rouge sur une icône et appuie sur le bouton VERT.")