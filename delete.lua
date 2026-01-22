require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.accessibilityservice.*"
import "android.util.DisplayMetrics"
import "android.os.Build"

-- 1. CONNEXION SERVICE
pcall(auto)

-- 2. CONFIGURATION ECRAN
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local SW = activity.getResources().getDisplayMetrics().widthPixels
local SH = activity.getResources().getDisplayMetrics().heightPixels

-- Positions par défaut
local Pos = { 
    fireX = SW * 0.5, -- Milieu
    fireY = SH * 0.5
}

-- 3. MOTEUR DE CLIC (MÉTHODE "GC")
function doClick()
    -- On récupère le service global
    local s = service
    
    if not s then
        Toast.makeText(activity, "⚠️ SERVICE OFF - Relance l'accessibilité", 0).show()
        return
    end

    -- Construction du Geste (Méthode Native Android)
    local path = Path()
    path.moveTo(Pos.fireX, Pos.fireY)
    
    -- Le secret de GC : Un stroke simple et propre
    local stroke = GestureDescription.StrokeDescription(path, 0, 50) -- 0ms delay, 50ms duration
    local builder = GestureDescription.Builder()
    builder.addStroke(stroke)
    
    -- Envoi
    s:dispatchGesture(builder:build(), nil, nil)
end

-- ================= INTERFACE =================

-- CIBLE (MODE FANTOME - IMPORTANNNT)
-- FLAG_NOT_TOUCHABLE (16) + FLAG_NOT_FOCUSABLE (8)
-- Cela rend la fenêtre "transparente" pour Android. Le système ne sait même pas qu'elle est là.
local FLAGS_GHOST = 24 -- (16 | 8)
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

local tFire = TextView(activity)
tFire.setText("") -- Vide pour pas gêner
tFire.setBackgroundDrawable(GradientDrawable())
tFire.getBackground().setStroke(5, 0xFFFF0000) -- Juste un cadre Rouge
tFire.getBackground().setColor(0x00000000) -- Fond transparent

local lpFire = WindowManager.LayoutParams(100, 100, OVERLAY_TYPE, FLAGS_GHOST, -3)
lpFire.gravity = 51
lpFire.x = Pos.fireX - 50
lpFire.y = Pos.fireY - 50

-- FONCTION DE MISE A JOUR POS
function updatePos()
    lpFire.x = Pos.fireX - 50
    lpFire.y = Pos.fireY - 50
    wm.updateViewLayout(tFire, lpFire)
end

-- MENU DE CONTROLE (PAD)
local menu = LinearLayout(activity)
menu.setOrientation(1)
menu.setBackgroundColor(0xEE222222)
menu.setPadding(10,10,10,10)
-- FLAG_NOT_TOUCH_MODAL (32) pour pouvoir cliquer à côté
local lpMenu = WindowManager.LayoutParams(350, 600, OVERLAY_TYPE, 8, -3)
lpMenu.gravity = 51
lpMenu.x = 50
lpMenu.y = 200

-- TITRE
local title = TextView(activity)
title.setText("GC CLONE V45")
title.setTextColor(Color.CYAN)
title.setGravity(17)
menu.addView(title)

-- BOUTON SHOOT (LE DECLENCHEUR)
local btnShoot = Button(activity)
btnShoot.setText("SHOOT")
btnShoot.setBackgroundColor(0xFFFFD700) -- Or
btnShoot.setTextColor(Color.BLACK)
btnShoot.setOnClickListener(function()
    btnShoot.setBackgroundColor(Color.RED)
    doClick()
    -- Remet la couleur après 100ms
    Handler().postDelayed(function() btnShoot.setBackgroundColor(0xFFFFD700) end, 100)
end)
menu.addView(btnShoot)

-- PAD DIRECTIONNEL (Pour bouger la cible fantôme)
local padLabel = TextView(activity); padLabel.setText("\nDÉPLACER CIBLE :"); padLabel.setTextColor(Color.LTGRAY); menu.addView(padLabel)

local row1 = LinearLayout(activity); row1.setGravity(17); menu.addView(row1)
local btnUp = Button(activity); btnUp.setText("⬆️"); btnUp.setOnClickListener(function() Pos.fireY=Pos.fireY-20; updatePos() end)
row1.addView(btnUp)

local row2 = LinearLayout(activity); row2.setGravity(17); menu.addView(row2)
local btnLeft = Button(activity); btnLeft.setText("⬅️"); btnLeft.setOnClickListener(function() Pos.fireX=Pos.fireX-20; updatePos() end)
local btnRight = Button(activity); btnRight.setText("➡️"); btnRight.setOnClickListener(function() Pos.fireX=Pos.fireX+20; updatePos() end)
row2.addView(btnLeft); row2.addView(btnRight)

local row3 = LinearLayout(activity); row3.setGravity(17); menu.addView(row3)
local btnDown = Button(activity); btnDown.setText("⬇️"); btnDown.setOnClickListener(function() Pos.fireY=Pos.fireY+20; updatePos() end)
row3.addView(btnDown)

-- BOUTON FERMER
local close = Button(activity); close.setText("FERMER APP"); close.setBackgroundColor(Color.RED)
close.setOnClickListener(function()
    pcall(function() wm.removeView(tFire) end)
    pcall(function() wm.removeView(menu) end)
    activity.finish()
end)
menu.addView(close)

-- AJOUT ECRAN
pcall(function() wm.addView(tFire, lpFire) end)
pcall(function() wm.addView(menu, lpMenu) end)

print("✅ V45: CLONE GC CHARGÉ")