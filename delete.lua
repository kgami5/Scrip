-- Updated CODM macro overlay
-- Adds conditional anti‑recoil when firing, screen adaptation, left offset for CODM HUD

require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.provider.Settings"
import "android.accessibilityservice.*"
import "android.accessibilityservice.GestureDescription"
import "android.util.DisplayMetrics"
import "android.graphics.drawable.ColorDrawable"

-- ================= CONFIG =================
-- ================= CONFIG =================
local config = {
  anti_recoil = true,
  rapid_fire = true,
  aim_assist = false,
  fov_120 = false,       -- FOV toggle

  recoil_pixels = 6,
  recoil_delay = 6,

  offset_left = -80,
  offset_down = 0,
}

-- ================= OVERLAY PERMISSION =================
if not Settings.canDrawOverlays(activity) then
  activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
  print("Autorise Overlay puis relance l'app")
  return
end

-- ================= ACCESSIBILITY =================
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)
if not accessibilityService then
  print("Accessibility non active")
  return
end

-- ================= SCREEN METRICS =================
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

local FIRE_X = SW * 0.85 + config.offset_left
local FIRE_Y = SH * 0.65 + config.offset_down
local CENTER_X = SW * 0.5 + config.offset_left
local CENTER_Y = SH * 0.5

-- ================= GESTURES =================
function tap(x, y)
  local p = Path(); p.moveTo(x, y)
  local g = GestureDescription.Builder()
  g.addStroke(GestureDescription.StrokeDescription(p, 0, 1))
  pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

function swipe(x1,y1,x2,y2,d)
  local p = Path(); p.moveTo(x1,y1); p.lineTo(x2,y2)
  local g = GestureDescription.Builder()
  g.addStroke(GestureDescription.StrokeDescription(p, 0, d or 8))
  pcall(function() accessibilityService:dispatchGesture(g:build(), nil, nil) end)
end

-- ================= UI OVERLAY =================
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local overlay = LinearLayout(activity)
overlay.setOrientation(1)
overlay.setPadding(16,16,16,16)
overlay.setBackgroundColor(Color.argb(180,0,0,0))

local params = WindowManager.LayoutParams(
  WindowManager.LayoutParams.WRAP_CONTENT,
  WindowManager.LayoutParams.WRAP_CONTENT,
  2038,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
  PixelFormat.TRANSLUCENT
)

-- ================= DRAG & MOVE =================
overlay.setOnTouchListener{
  onTouch=function(v,event)
    if event.getAction() == MotionEvent.ACTION_DOWN then
      v.startX = event.getRawX() - params.x
      v.startY = event.getRawY() - params.y
      return true
    elseif event.getAction() == MotionEvent.ACTION_MOVE then
      params.x = event.getRawX() - v.startX
      params.y = event.getRawY() - v.startY
      wm.updateViewLayout(overlay, params)
      return true
    end
    return false
  end
}

-- ================= BUTTON CREATION =================
local function addBtn(txt, fn)
  local b = Button(activity)
  b.setText(txt)
  b.setTextColor(Color.WHITE)
  b.setBackgroundColor(Color.parseColor("#8A2BE2"))
  b.setOnClickListener(fn)
  overlay.addView(b)
end

-- Toggle buttons
addBtn("Anti‑Recoil", function() config.anti_recoil = not config.anti_recoil end)
addBtn("Rapid Fire", function() config.rapid_fire = not config.rapid_fire end)
addBtn("Aim Assist Max", function() config.aim_assist = not config.aim_assist end)
addBtn("FOV 120", function() config.fov_120 = not config.fov_120 end)

-- Offsets
addBtn("Left −", function() config.offset_left = config.offset_left - 10 end)
addBtn("Left +", function() config.offset_left = config.offset_left + 10 end)

-- Minimize button
addBtn("Minimize", function()
  overlay.setVisibility(View.GONE)
  local mini = Button(activity)
  mini.setText("Menu")
  mini.setTextColor(Color.WHITE)
  mini.setBackgroundColor(Color.parseColor("#4B0082"))
  local miniParams = WindowManager.LayoutParams(
    WindowManager.LayoutParams.WRAP_CONTENT,
    WindowManager.LayoutParams.WRAP_CONTENT,
    2038,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
    PixelFormat.TRANSLUCENT
  )
  miniParams.x, miniParams.y = params.x, params.y
  mini.setOnClickListener(function()
    overlay.setVisibility(View.VISIBLE)
    wm.removeView(mini)
  end)
  wm.addView(mini, miniParams)
end)

wm.addView(overlay, params)

-- ================= HANDLERS =================
local h = Handler(Looper.getMainLooper())

local rapid = Runnable({ run=function()
  if config.rapid_fire then tap(FIRE_X, FIRE_Y) end
  h.postDelayed(rapid, 45)
end })

local recoil = Runnable({ run=function()
  if config.anti_recoil and config.rapid_fire then
    swipe(CENTER_X, CENTER_Y, CENTER_X, CENTER_Y - config.recoil_pixels, 6)
  end
  h.postDelayed(recoil, config.recoil_delay)
end })

h.post(rapid)
h.post(recoil)





-- ================= FOV CIRCLE =================

import "android.graphics.drawable.ShapeDrawable"
import "android.graphics.drawable.shapes.OvalShape"

local fovCircle = View(activity)
fovCircle.setBackgroundDrawable(ShapeDrawable(OvalShape()))
fovCircle.getBackground().setColor(Color.argb(80,0,255,0)) -- vert translucide

-- taille initiale (radius)
local fovRadius = 200
fovCircle.layoutParams = LinearLayout.LayoutParams(fovRadius*2, fovRadius*2)

-- fonction pour mettre à jour la position et taille
local function updateFOV()
  local x = CENTER_X - fovRadius
  local y = CENTER_Y - fovRadius
  local lp = WindowManager.LayoutParams(
    fovRadius*2,
    fovRadius*2,
    2038,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
    PixelFormat.TRANSLUCENT
  )
  lp.x = x
  lp.y = y
  wm.updateViewLayout(fovCircle, lp)
end

-- Ajouter FOV Circle à l’écran
wm.addView(fovCircle, WindowManager.LayoutParams(
  fovRadius*2,
  fovRadius*2,
  2038,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
  PixelFormat.TRANSLUCENT
))

updateFOV()

-- ================= UI CONTROL FOV =================
addBtn("FOV +", function()
  fovRadius = fovRadius + 20
  updateFOV()
end)

addBtn("FOV −", function()
  fovRadius = math.max(50, fovRadius - 20)
  updateFOV()
end)

addBtn("Toggle FOV Circle", function()
  if fovCircle.getVisibility() == View.VISIBLE then
    fovCircle.setVisibility(View.GONE)
  else
    fovCircle.setVisibility(View.VISIBLE)
  end
end)

-- ================= AUTOMATIQUE =================
local aimAssistCheck = Runnable({ run=function()
  if config.aim_assist then
    fovCircle.setVisibility(View.VISIBLE)
  else
    fovCircle.setVisibility(View.GONE)
  end
  h.postDelayed(aimAssistCheck, 500) -- check toutes les 0.5s
end })
h.post(aimAssistCheck)






print("✅ CODM overlay ready – draggable menu, minimize, aim assist & FOV 120")
