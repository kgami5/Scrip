require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.util.DisplayMetrics"
import "java.lang.Runtime"

-- ================= CONFIGURATION =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local SW = activity.getResources().getDisplayMetrics().widthPixels
local SH = activity.getResources().getDisplayMetrics().heightPixels

local Pos = { x = SW * 0.8, y = SH * 0.7 }

-- ================= MOTEUR SHELL (LE BÉLIER) =================
function shoot()
    -- On essaie d'envoyer une commande Linux directe
    -- "input tap X Y"
    local cmd = "input tap " .. math.floor(Pos.x) .. " " .. math.floor(Pos.y)
    
    print("Tentative Shell: " .. cmd)
    
    -- Exécution
    pcall(function()
        Runtime.getRuntime().exec(cmd)
    end)
    
    -- Note : Cette méthode nécessite souvent le ROOT.
    -- Si ça ne marche pas, c'est que ton téléphone est verrouillé à 100%.
end

-- ================= UI SIMPLIFIÉE =================

-- TARGET
local t = TextView(activity); t.setText("TIR"); t.setBackgroundColor(0x88FF0000); t.setGravity(17)
local lpT = WindowManager.LayoutParams(130,130,OVERLAY_TYPE,8,-3)
lpT.gravity=51; lpT.x=Pos.x-65; lpT.y=Pos.y-65
t.setOnTouchListener(function(v,e)
    if e.getAction()==2 then lpT.x=e.getRawX()-65; lpT.y=e.getRawY()-65; Pos.x=lpT.x+65; Pos.y=lpT.y+65; wm.updateViewLayout(t,lpT) end
    return false
end)

-- BOUTON SHOOT
local btn = Button(activity)
btn.setText("SHOOT (SHELL)")
btn.setBackgroundColor(Color.YELLOW)
btn.setTextColor(Color.BLACK)
local lpBtn = WindowManager.LayoutParams(250, 150, OVERLAY_TYPE, 8, -3)
lpBtn.gravity=51; lpBtn.x=100; lpBtn.y=400

btn.setOnClickListener(function()
    btn.setBackgroundColor(Color.RED)
    shoot()
    Handler().postDelayed(function() btn.setBackgroundColor(Color.YELLOW) end, 200)
end)

-- FERMER
local close = Button(activity); close.setText("X"); close.setBackgroundColor(Color.RED)
local lpClose = WindowManager.LayoutParams(100,100,OVERLAY_TYPE,8,-3)
lpClose.x=0; lpClose.y=0
close.setOnClickListener(function()
    pcall(function() wm.removeView(t) end)
    pcall(function() wm.removeView(btn) end)
    pcall(function() wm.removeView(close) end)
    activity.finish()
end)

pcall(function() wm.addView(t, lpT) end)
pcall(function() wm.addView(btn, lpBtn) end)
pcall(function() wm.addView(close, lpClose) end)

print("✅ V44 SHELL MODE")