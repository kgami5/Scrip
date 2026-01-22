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

-- ================= FIX ANDLUA+ 7.0 =================
-- Sur la v7, il faut parfois définir cette fonction pour que le service démarre
function onAccessibilityEvent(event)
    -- Garder vide, sert juste à maintenir la connexion
end

-- Tentative de chargement sécurisé
pcall(function()
    import "com.androlua.LuaAccessibilityService"
    service = LuaAccessibilityService.service
end)

if service == nil then
    pcall(auto) -- Méthode classique en secours
end

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local FireX, FireY = SW * 0.8, SH * 0.7

-- ================= DIAGNOSTIC EN TÊTE =================
local debugText = TextView(activity)
debugText.setTextSize(16)
debugText.setTextColor(Color.WHITE)
debugText.setBackgroundColor(Color.BLACK)
debugText.setPadding(20, 20, 20, 20)
local lpDebug = WindowManager.LayoutParams(600, WindowManager.LayoutParams.WRAP_CONTENT, OVERLAY_TYPE, 8, -3)
lpDebug.gravity = 49 -- Haut Centre
lpDebug.y = 100

-- BOUCLE DE VERIFICATION (Le Cœur du problème)
local handler = Handler(Looper.getMainLooper())
local checkLoop = Runnable({ run = function()
    -- Essai de récupération brutale du service si nil
    if service == nil and activity.getLuaAccessibilityService then
        pcall(function() service = activity.getLuaAccessibilityService() end)
    end

    if service then
        debugText.setText("✅ SERVICE: ACTIF ("..tostring(service)..")\nAppuie sur le carré JAUNE pour tester.")
        debugText.setBackgroundColor(0xFF00AA00) -- Vert
    else
        debugText.setText("❌ SERVICE: NIL (Inactif)\nBug AndLua détecté.\nRéessaie OFF/ON dans paramètres.")
        debugText.setBackgroundColor(0xFFAA0000) -- Rouge
    end
    handler.postDelayed(checkLoop, 1000)
end})
handler.post(checkLoop)

-- ================= ACTION DE TIR =================
function tryClick()
    if not service then
        Toast.makeText(activity, "Service Inactif !", 0).show()
        -- Force ouverture param
        local intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
        return
    end

    -- Geste simple
    local p = Path()
    p.moveTo(FireX, FireY)
    local g = GestureDescription.Builder()
    g.addStroke(GestureDescription.StrokeDescription(p, 0, 80))
    
    local success = service:dispatchGesture(g:build(), nil, nil)
    if success then
        print("⚡ Geste envoyé !")
        debugText.setText("⚡ CLIC ENVOYÉ !")
    else
        print("⚠️ Geste refusé")
        debugText.setText("⚠️ BLOQUÉ PAR SYSTEME")
    end
end

-- ================= UI =================
local btn = Button(activity)
btn.setText("SHOOT TEST")
btn.setBackgroundColor(Color.YELLOW)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(300, 200, OVERLAY_TYPE, 8, -3)
lpBtn.gravity = 51; lpBtn.x = 200; lpBtn.y = 400

btn.setOnClickListener(function()
    tryClick()
end)

-- Target
local t = TextView(activity); t.setText("CIBLE"); t.setBackgroundColor(0x88FF0000); t.setGravity(17)
local lpT = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3)
lpT.gravity=51; lpT.x = FireX-50; lpT.y=FireY-50

-- Close
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpC = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3)
lpC.x=0; lpC.y=0
close.setOnClickListener(function()
    handler.removeCallbacks(checkLoop)
    pcall(function() wm.removeView(debugText) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(t) end)
    pcall(function() wm.removeView(close) end)
end)

pcall(function() wm.addView(debugText, lpDebug) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(t, lpT) end)
pcall(function() wm.addView(close, lpC) end)