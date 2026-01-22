require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.util.DisplayMetrics"
import "android.content.Context"

-- Configuration
local Config = {
    active = false,
    is_recording = false,
    offset_x = -52, -- DÉCALAGE GAUCHE
    box_size = 100,   -- Taille zone viseur
    speed = 30       -- ms
}

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local dm = DisplayMetrics()
wm.getDefaultDisplay().getRealMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels
local CX, CY = (SW / 2) + Config.offset_x, SH / 2

local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

-- Fonction de dessin
function CreateGD(col, stroke)
    local gd = GradientDrawable()
    gd.setShape(0)
    gd.setColor(col)
    gd.setCornerRadius(10)
    if stroke then gd.setStroke(5, stroke) end
    return gd
end

-- Barre de Statut
local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateGD(0xCC000000))
statusLayout.setPadding(25, 15, 25, 15)
local statusText = TextView(activity)
statusText.setText("1. CLIQUE SUR VISION")
statusText.setTextColor(-1)
statusLayout.addView(statusText)

local lpS = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 8, -3)
lpS.gravity = 49; lpS.y = 100
pcall(function() wm.addView(statusLayout, lpS) end)

function setTxt(t, c)
    activity.runOnUiThread(Runnable({run=function() 
        statusText.setText(t)
        if c then statusText.setTextColor(c) end
    end}))
end

-- Logique de Scan
function scanTarget()
    -- On utilise le module images global de Kgami
    if not images then return nil end
    local img = nil
    pcall(function() img = images.captureScreen() end)
    if not img then return nil end

    local scanX, scanY = CX - (Config.box_size/2), CY - (Config.box_size/2)
    
    for y = 0, Config.box_size, 6 do
        for x = 0, Config.box_size, 6 do
            local px = images.getPixel(img, scanX + x, scanY + y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- DÉTECTION ROUGE VISEUR
            if r > 210 and g < 70 and b < 70 then
                return {x = scanX + x, y = scanY + y}
            end
        end
    end
    return nil
end

local handler = Handler()
local mainLoop = nil
mainLoop = Runnable({run=function()
    if not Config.active then return end
    local target = scanTarget()
    if target then
        setTxt("🎯 LOCK ACTIF", Color.RED)
        box.setBackgroundDrawable(CreateGD(0, Color.GREEN))
        
        local moveX, moveY = (target.x - CX) * 0.8, (target.y - CY) * 0.8
        local s = service or auto
        if s then
            local b = luajava.bindClass("android.accessibilityservice.GestureDescription$Builder")()
            local p = Path()
            p.moveTo(CX, CY)
            p.lineTo(CX + moveX, CY + moveY)
            b.addStroke(luajava.bindClass("android.accessibilityservice.GestureDescription$StrokeDescription")(p, 0, 45))
            s.dispatchGesture(b.build(), nil, nil)
        end
    else
        setTxt("🔍 SCAN VISEUR...", -1)
        box.setBackgroundDrawable(CreateGD(0, Color.RED))
    end
    handler.postDelayed(mainLoop, Config.speed)
end})

-- UI Menu
local menu = LinearLayout(activity)
menu.setOrientation(1)
menu.setBackgroundDrawable(CreateGD(0xF0101010, Color.CYAN))
menu.setPadding(40, 40, 40, 40)
menu.setVisibility(8)

local btn1 = Button(activity)
btn1.setText("1. ALLUMER VISION")
btn1.setOnClickListener(function()
    setTxt("ACCEPTE LE POPUP ANDROID...", Color.CYAN)
    -- Commande de capture simplifiée
    if pcall(function() images.requestScreenCapture(false) end) then
        Config.is_recording = true
        btn1.setBackgroundColor(0xFF2E7D32)
        setTxt("VISION PRÊTE ✅", Color.GREEN)
    else
        setTxt("❌ ERREUR VISION", Color.RED)
    end
end)
menu.addView(btn1)

local btn2 = Button(activity)
btn2.setText("2. START AIM")
btn2.setOnClickListener(function()
    if not Config.is_recording then 
        setTxt("⚠️ ACTIVE VISION D'ABORD", Color.YELLOW)
        return 
    end
    Config.active = not Config.active
    btn2.setBackgroundColor(Config.active and 0xFF2E7D32 or 0xFFC62828)
    if Config.active then handler.post(mainLoop) end
end)
menu.addView(btn2)

pcall(function() wm.addView(menu, WindowManager.LayoutParams(600, -2, OVERLAY_TYPE, 8, -3)) end)

-- Le Carré (Offset -115)
box = View(activity)
box.setBackgroundDrawable(CreateGD(0, Color.RED))
local lpB = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpB.gravity = 17; lpB.x = Config.offset_x
pcall(function() wm.addView(box, lpB) end)

-- Bouton d'ouverture
local btnM = Button(activity)
btnM.setText("⚙️")
local lpM = WindowManager.LayoutParams(120, 120, OVERLAY_TYPE, 8, -3)
lpM.gravity = 51; lpM.x = 20; lpM.y = 250
btnM.setOnClickListener(function()
    menu.setVisibility(menu.getVisibility() == 0 and 8 or 0)
end)
pcall(function() wm.addView(btnM, lpM) end)