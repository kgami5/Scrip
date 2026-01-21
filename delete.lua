require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.*"
import "android.graphics.drawable.ShapeDrawable"
import "android.graphics.drawable.shapes.OvalShape"
import "android.provider.Settings"
import "android.accessibilityservice.*"
import "android.accessibilityservice.GestureDescription"
import "android.util.DisplayMetrics"

-- ================= CONFIG =================
local config = {
  anti_recoil = true,
  rapid_fire = true,
  aim_assist = false,
  fov_radius = 200,
  offset_left = -80,
  offset_down = 0,
}

-- ================= OVERLAY PERMISSION =================
if not Settings.canDrawOverlays(activity) then
  activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
  print("Autorise Overlay puis relance l'app")
  return
end

-- ================= SCREEN METRICS =================
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getMetrics(dm)
local SW, SH = dm.widthPixels, dm.heightPixels

local CENTER_X, CENTER_Y = SW/2, SH/2
local FIRE_X, FIRE_Y = SW*0.85 + config.offset_left, SH*0.65

-- ================= ACCESSIBILITY =================
local accessibilityService = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)
if not accessibilityService then
  print("Accessibility non active")
  return
end

-- ================= GESTURES =================
function tap(x, y)
  local p = Path(); p.moveTo(x, y)
  local g = GestureDescription.Builder()
  g.addStroke(GestureDescription.StrokeDescription(p,0,1))
  pcall(function() accessibilityService:dispatchGesture(g:build(),nil,nil) end)
end

function swipe(x1,y1,x2,y2,d)
  local p = Path(); p.moveTo(x1,y1); p.lineTo(x2,y2)
  local g = GestureDescription.Builder()
  g.addStroke(GestureDescription.StrokeDescription(p,0,d or 8))
  pcall(function() accessibilityService:dispatchGesture(g:build(),nil,nil) end)
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

-- Drag & move
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

-- Button helper
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
addBtn("Aim Assist", function()
  config.aim_assist = not config.aim_assist
  fovCircle.setVisibility(config.aim_assist and View.VISIBLE or View.GONE)
end)
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

-- ================= HANDLER =================
local h = Handler(Looper.getMainLooper())

local rapid = Runnable({run=function()
  if config.rapid_fire then tap(FIRE_X,FIRE_Y) end
  h.postDelayed(rapid,45)
end})

local recoil = Runnable({run=function()
  if config.anti_recoil and config.rapid_fire then
    swipe(CENTER_X,CENTER_Y,CENTER_X,CENTER_Y-6,6)
  end
  h.postDelayed(recoil,6)
end})

h.post(rapid)
h.post(recoil)

-- ================= FOV CIRCLE =================
local fovCircle = View(activity)
fovCircle.setBackgroundDrawable(ShapeDrawable(OvalShape()))
fovCircle.getBackground().setColor(Color.argb(80,0,255,0))
fovCircle.setVisibility(View.GONE)

local function updateFOV()
  local lp = WindowManager.LayoutParams(
    config.fov_radius*2,
    config.fov_radius*2,
    2038,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
    PixelFormat.TRANSLUCENT
  )
  lp.x = CENTER_X - config.fov_radius
  lp.y = CENTER_Y - config.fov_radius
  wm.updateViewLayout(fovCircle, lp)
end

wm.addView(fovCircle, WindowManager.LayoutParams(
  config.fov_radius*2,
  config.fov_radius*2,
  2038,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
  PixelFormat.TRANSLUCENT
))
updateFOV()

-- FOV + / −
addBtn("FOV +", function()
  config.fov_radius = config.fov_radius + 20
  updateFOV()
end)

addBtn("FOV −", function()
  config.fov_radius = math.max(50, config.fov_radius - 20)
  updateFOV()
end)

print("✅ Overlay CODM fonctionnel avec FOV rond, draggable et minimize")
