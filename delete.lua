require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.Context"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.Intent"
import "android.media.projection.MediaProjectionManager"
import "android.media.ImageReader"
import "android.hardware.display.DisplayManager"
import "android.util.DisplayMetrics"
import "android.accessibilityservice.*"
import "android.accessibilityservice.GestureDescription"
import "android.graphics.Path"

-- ================= 1. SETUP UI PRINCIPAL =================
local mainLayout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  BackgroundColor="#101010",
  {
    TextView,
    text="☠️ ULTIMATE AIMLOCK ☠️",
    textSize="28sp",
    textStyle="bold",
    textColor="#FF3333",
    layout_marginBottom="10dp"
  },
  {
    TextView,
    text="Logic: 0.5s Delay -> Hard Lock",
    textSize="14sp",
    textColor="#888888",
    layout_marginBottom="30dp"
  },
  {
    CardView,
    radius=20,
    CardBackgroundColor="#222222",
    elevation=15,
    layout_width="85%w",
    {
      LinearLayout,
      orientation="vertical",
      padding="25dp",
      {
        Button,
        text="1. PERMISSION OVERLAY",
        id="btnPerm",
        layout_width="match_parent",
        BackgroundColor="#FF9800",
        textColor="#FFFFFF",
        layout_marginBottom="15dp"
      },
      {
        Button,
        text="2. START WIDGETS",
        id="btnStart",
        layout_width="match_parent",
        BackgroundColor="#4CAF50",
        textColor="#FFFFFF"
      }
    }
  },
  {
    TextView,
    id="logText",
    text="En attente...",
    textColor="#555555",
    layout_marginTop="20dp"
  }
}

activity.setTheme(android.R.style.Theme_Material_NoActionBar)
activity.setContentView(loadlayout(mainLayout))

-- ================= 2. CONFIGURATION =================
local Config = {
  active = false,
  box_size = 70,
  offset_x = -52, 
  scan_range = 70, 
  scan_step = 6,
  sensitivity = 0.0, 
  speed_ms = 15, -- Légèrement augmenté pour éviter le lag du dessin
  lock_delay = 350, -- 500ms environ
  recoil_compensation = 3 
}

local wmManager = activity.getSystemService(Context.WINDOW_SERVICE)
local mProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local displayMetrics = DisplayMetrics()
wmManager.getDefaultDisplay().getRealMetrics(displayMetrics)
local SW, SH = displayMetrics.widthPixels, displayMetrics.heightPixels

local CX = (SW / 2) + Config.offset_x
local CY = SH / 2

local widgetVisible = false
local FloatingWindow, BoxWindow, CameraOverlayWindow
local lockTimer = 0

-- === VARIABLES HUD & DESSIN (CORRIGÉES) ===
local HudWindow, HudImageView
local hudBitmap, hudCanvas, hudPaint, textPaint
local vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE)

-- Initialisation des outils de dessin
hudPaint = Paint()
hudPaint.setStrokeWidth(5)
hudPaint.setAntiAlias(true)
hudPaint.setStyle(Paint.Style.STROKE)

textPaint = Paint()
textPaint.setColor(Color.WHITE)
textPaint.setTextSize(35)
textPaint.setFakeBoldText(true)
textPaint.setShadowLayer(5, 0, 0, Color.BLACK)

-- ================= 3. LOGIQUE PERMISSION =================
btnPerm.onClick = function()
  if not Settings.canDrawOverlays(activity) then
    local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
    Uri.parse("package:" .. activity.getPackageName()))
    activity.startActivity(intent)
   else
    logText.setText("✅ Permission OK")
    btnPerm.setBackgroundColor(0xFF4CAF50)
  end
end

-- ================= 4. CREATION DES WIDGETS =================
function createAllWidgets()
  if widgetVisible then return end
  local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002

  -- A. Widget MENU
  local floatView = TextView(activity)
  floatView.setText("AIM")
  floatView.setTextColor(Color.WHITE)
  floatView.setTextSize(16)
  floatView.setTypeface(Typeface.DEFAULT_BOLD)
  floatView.setGravity(Gravity.CENTER)
  local gd = GradientDrawable()
  gd.setColor(0xFF0099FF) gd.setCornerRadius(100)
  gd.setStroke(2, 0xFFFFFFFF)
  floatView.setBackgroundDrawable(gd)

  FloatingWindow = floatView
  local wmParams = WindowManager.LayoutParams(140, 140, OVERLAY_TYPE,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT)
  wmParams.gravity = Gravity.LEFT | Gravity.TOP
  wmParams.y = 400
  wmManager.addView(FloatingWindow, wmParams)
  initTouchListener(FloatingWindow, wmParams, FloatingWindow)

  -- B. Widget CAMERA
  createCameraOverlay(OVERLAY_TYPE)

  -- C. Widget BOX
  createAimBox(OVERLAY_TYPE)

  -- D. Widget HUD (Lignes Laser)
  createTacticalHUD(OVERLAY_TYPE)

  widgetVisible = true
end

function createCameraOverlay(type)
  local camView = TextView(activity)
  camView.setText("📷")
  camView.setTextSize(20)
  camView.setGravity(Gravity.CENTER)
  camView.setTextColor(Color.LTGRAY)
  local gd = GradientDrawable()
  gd.setColor(0xAA000000)
  gd.setStroke(3, 0xFFFFFFFF)
  gd.setCornerRadius(100)
  camView.setBackgroundDrawable(gd)
  CameraOverlayWindow = camView
  local lp = WindowManager.LayoutParams(130, 130, type,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
  PixelFormat.TRANSLUCENT)
  lp.gravity = Gravity.RIGHT | Gravity.CENTER_VERTICAL
  lp.x = 60
  wmManager.addView(CameraOverlayWindow, lp)
  CameraOverlayWindow.setVisibility(View.GONE)
end

function createAimBox(type)
  local boxView = View(activity)
  local gd = GradientDrawable()
  gd.setStroke(4, Color.RED)
  gd.setCornerRadius(20)
  boxView.setBackgroundDrawable(gd)
  local lp = WindowManager.LayoutParams(Config.box_size, Config.box_size, type,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
  PixelFormat.TRANSLUCENT)
  lp.gravity = Gravity.CENTER
  lp.x = Config.offset_x
  BoxWindow = boxView
  wmManager.addView(BoxWindow, lp)
  BoxWindow.setVisibility(View.GONE)
end

-- === MODIFICATION HUD : Utilisation d'ImageView + Bitmap ===
function createTacticalHUD(type)
  HudImageView = ImageView(activity)
  
  -- Création du Canvas Bitmap Fullscreen
  hudBitmap = Bitmap.createBitmap(SW, SH, Bitmap.Config.ARGB_8888)
  hudCanvas = Canvas(hudBitmap)
  HudImageView.setImageBitmap(hudBitmap)

  local lp = WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT, type,
  WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
  PixelFormat.TRANSLUCENT)
  
  HudWindow = HudImageView
  wmManager.addView(HudWindow, lp)
  HudWindow.setVisibility(View.GONE)
end

function initTouchListener(view, params, window)
  local startX, startY, rawX, rawY
  view.setOnTouchListener(View.OnTouchListener{
    onTouch = function(v, event)
      if event.getAction() == MotionEvent.ACTION_DOWN then
        startX, startY = params.x, params.y
        rawX, rawY = event.getRawX(), event.getRawY()
        return true
       elseif event.getAction() == MotionEvent.ACTION_MOVE then
        params.x = startX + (event.getRawX() - rawX)
        params.y = startY + (event.getRawY() - rawY)
        wmManager.updateViewLayout(window, params)
        return true
       elseif event.getAction() == MotionEvent.ACTION_UP then
        if math.abs(event.getRawX() - rawX) < 10 then toggleScan() end
        return true
      end
      return false
    end
  })
end

function toggleScan()
  if not Config.active then
    local intent = mProjectionManager.createScreenCaptureIntent()
    activity.startActivityForResult(intent, 101)
   else
    stopScan()
  end
end

-- ================= 5. FONCTION MOUVEMENT =================
function moveCamera(targetX, targetY)
  if not service then return end
  local path = Path()
  path.moveTo(CX, CY)
  local dx = (targetX - CX) * Config.sensitivity
  local dy = (targetY - CY) * Config.sensitivity
  dy = dy + Config.recoil_compensation
  path.lineTo(CX + dx, CY + dy)
  local builder = GestureDescription.Builder()
  local stroke = GestureDescription.StrokeDescription(path, 0, 1)
  builder.addStroke(stroke)
  pcall(function() service.dispatchGesture(builder.build(), nil, nil) end)
end

-- ================= 6. SCAN LOOP & DESSIN =================
local mImageReader, mMediaProjection
local handler = Handler(Looper.getMainLooper())

function startScan(resultCode, data)
  Config.active = true
  
  -- Visuels ON
  local gd = GradientDrawable()
  gd.setColor(0xFF4CAF50) gd.setCornerRadius(100) gd.setStroke(2, 0xFFFFFFFF)
  FloatingWindow.setBackgroundDrawable(gd)
  
  BoxWindow.setVisibility(View.VISIBLE)
  CameraOverlayWindow.setVisibility(View.VISIBLE)
  HudWindow.setVisibility(View.VISIBLE) -- HUD Visible

  mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data)
  mImageReader = ImageReader.newInstance(SW, SH, PixelFormat.RGBA_8888, 2)
  mMediaProjection.createVirtualDisplay("Scan", SW, SH, displayMetrics.densityDpi,
  DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, mImageReader.getSurface(), nil, nil)

  handler.post(scanLoop)
end

function stopScan()
  Config.active = false -- Correction du falsefalse
  
  -- Visuels OFF
  local gd = GradientDrawable()
  gd.setColor(0xFF0099FF) gd.setCornerRadius(100) gd.setStroke(2, 0xFFFFFFFF)
  FloatingWindow.setBackgroundDrawable(gd)

  BoxWindow.setVisibility(View.GONE)
  CameraOverlayWindow.setVisibility(View.GONE)
  HudWindow.setVisibility(View.GONE)

  -- Nettoyage du dessin
  if hudCanvas then
    hudCanvas.drawColor(0, PorterDuff.Mode.CLEAR)
    HudImageView.invalidate()
  end

  if mMediaProjection then mMediaProjection.stop() end
end

scanLoop = Runnable({ run = function()
    if not Config.active then return end

    local img = mImageReader.acquireLatestImage()
    if img then
      local planes = img.getPlanes()
      local buffer = planes[0].getBuffer()
      local pixelStride = planes[0].getPixelStride()
      local rowStride = planes[0].getRowStride()
      local width = img.getWidth()
      local height = img.getHeight()

      local bitmap = Bitmap.createBitmap(width + (rowStride - pixelStride * width) / pixelStride, height, Bitmap.Config.ARGB_8888)
      bitmap.copyPixelsFromBuffer(buffer)
      img.close()

      local totalX, totalY, count = 0, 0, 0
      local range = Config.scan_range

      for x = CX - range, CX + range, Config.scan_step do
        for y = CY - range, CY + range, Config.scan_step do
          if x > 0 and x < width and y > 0 and y < height then
            local pixel = bitmap.getPixel(x, y)
            local r = (pixel >> 16) & 0xFF
            local g = (pixel >> 8) & 0xFF
            local b = pixel & 0xFF

            if r > 160 and r > (g + 50) and r > (b + 50) then
              totalX = totalX + x
              totalY = totalY + y
              count = count + 1
            end
          end
        end
      end
      
      -- === PARTIE DESSIN & LOGIQUE ===
      -- On nettoie le canvas HUD à chaque frame (transparent)
      hudCanvas.drawColor(0, PorterDuff.Mode.CLEAR)

      if count > 0 then
        -- Cible trouvée
        local targetX = totalX / count
        local targetY = totalY / count
        lockTimer = lockTimer + Config.speed_ms

        -- 1. Configuration du style selon l'état
        if lockTimer >= Config.lock_delay then
          -- ÉTAT: LOCKED
          hudPaint.setColor(Color.GREEN)
          hudPaint.setShadowLayer(10, 0, 0, Color.GREEN)
          hudCanvas.drawText("⚡ LOCKED", targetX + 30, targetY - 30, textPaint)
          
          -- Vibration unique à l'activation du lock
          if lockTimer == Config.lock_delay then 
             vibrator.vibrate(50) 
          end
          
          -- Désactiver overlay caméra
          if CameraOverlayWindow.getVisibility() == View.VISIBLE then
            CameraOverlayWindow.setVisibility(View.INVISIBLE)
          end
          
          moveCamera(targetX, targetY)
        else
          -- ÉTAT: DETECTED (Pre-lock)
          hudPaint.setColor(Color.RED)
          hudPaint.setShadowLayer(0, 0, 0, 0)
          
           if CameraOverlayWindow.getVisibility() ~= View.VISIBLE then
            CameraOverlayWindow.setVisibility(View.VISIBLE)
          end
        end

        -- 2. DESSINER LA LIGNE (Du centre à la cible)
        hudCanvas.drawLine(CX, CY, targetX, targetY, hudPaint)
        
        -- Carré Vert
        local gdBox = GradientDrawable()
        gdBox.setStroke(6, Color.GREEN)
        gdBox.setCornerRadius(20)
        BoxWindow.setBackgroundDrawable(gdBox)

      else
        -- Pas de cible
        lockTimer = 0
        local gdBox = GradientDrawable()
        gdBox.setStroke(4, Color.RED)
        gdBox.setCornerRadius(20)
        BoxWindow.setBackgroundDrawable(gdBox)
        
        if CameraOverlayWindow.getVisibility() ~= View.VISIBLE then
          CameraOverlayWindow.setVisibility(View.VISIBLE)
        end
      end

      -- Appliquer les dessins
      HudImageView.invalidate()
      bitmap.recycle()
    end
    handler.postDelayed(scanLoop, Config.speed_ms)
  end})

-- ================= 7. START =================
btnStart.onClick = function()
  if Settings.canDrawOverlays(activity) then
    createAllWidgets()
   else
    print("Permission refusée")
  end
end

function onActivityResult(requestCode, resultCode, data)
  if requestCode == 101 and resultCode == -1 then
    startScan(resultCode, data)
  end
end
