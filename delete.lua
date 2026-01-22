require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.Context"
import "android.os.Environment"
import "android.media.ImageReader"
import "android.util.DisplayMetrics"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.Intent"
import "java.io.File"
import "java.util.Date"
import "java.text.SimpleDateFormat"
import "android.media.MediaRecorder"
import "android.hardware.display.DisplayManager"
import "android.media.projection.MediaProjectionManager"

-- ================= CONFIGURATION =================
local Config = {
    active = false,
    box_size = 200,      
    speed_ms = 25,       
    offset_x = -52,      
    magnet_power = 0.8   
}

local wmManager = activity.getSystemService(Context.WINDOW_SERVICE)
local mProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local displayMetrics = DisplayMetrics()
wmManager.getDefaultDisplay().getRealMetrics(displayMetrics)
local SW, SH = displayMetrics.widthPixels, displayMetrics.heightPixels
local CX = (SW / 2) + Config.offset_x
local CY = SH / 2

-- Vérification Permission Superposition
if not Settings.canDrawOverlays(activity) then
    print("⚠️ Active la permission 'Superposition' (Draw over apps)")
    local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" .. activity.getPackageName()))
    activity.startActivity(intent)
end

-- ================= UTILS GRAPHIQUES =================
local function CreateShape(color, radius)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(radius or 15)
    return gd
end

-- ================= OVERLAYS (Scan & Status) =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2003 -- TYPE_APPLICATION_OVERLAY

-- 1. Barre de status (Texte en haut)
local statusText = TextView(activity)
statusText.setText("READY")
statusText.setTextColor(Color.WHITE)
statusText.setPadding(20, 10, 20, 10)
statusText.setBackgroundDrawable(CreateShape(0x99000000))

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 24, -3) -- Flag not focusable
lpStatus.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL
lpStatus.y = 100

-- 2. Carré de visée (Scanner)
local boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0x00000000)) -- Transparent au début
local gdBox = GradientDrawable()
gdBox.setStroke(5, Color.RED)
gdBox.setCornerRadius(10)
boxView.setBackgroundDrawable(gdBox)

local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 24, -3)
lpBox.gravity = Gravity.CENTER
lpBox.x = Config.offset_x

-- Affichage sécurisé
pcall(function() 
    wmManager.addView(statusText, lpStatus) 
    wmManager.addView(boxView, lpBox)
    boxView.setVisibility(View.GONE)
    statusText.setVisibility(View.GONE)
end)

function setInfo(msg, color)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if color then statusText.setTextColor(color) end
        
        -- Change la couleur du carré
        local gd = GradientDrawable()
        gd.setStroke(5, color or Color.WHITE)
        gd.setCornerRadius(10)
        boxView.setBackgroundDrawable(gd)
    end}))
end

-- ================= LOGIQUE AIMBOT =================
local mImageReader = nil
local mMediaProjection = nil
local mVirtualDisplay = nil

function scanTarget(bitmap)
    if not bitmap then return nil end
    local sumX, sumY, count = 0, 0, 0
    local step = 8 -- Scan plus rapide (saute des pixels)
    
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)
    if startX < 0 then startX = 0 end
    if startY < 0 then startY = 0 end
    
    -- Limite la boucle pour éviter le lag
    local endX = math.min(startX + Config.box_size, SW)
    local endY = math.min(startY + Config.box_size, SH)

    for y = startY, endY, step do
        for x = startX, endX, step do
            local px = bitmap.getPixel(x, y)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- DETECTION ROUGE
            if r > 180 and g < 80 and b < 80 then
                sumX = sumX + x
                sumY = sumY + y
                count = count + 1
            end
        end
    end
    if count > 0 then return { x = sumX / count, y = sumY / count } end
    return nil
end

local handler = Handler(Looper.getMainLooper())
local loopRunnable = Runnable({ run = function()
    if not Config.active or not mImageReader then return end
    
    local img = mImageReader.acquireLatestImage()
    if img then
        local planes = img.getPlanes()
        local buffer = planes[0].getBuffer()
        local pixelStride = planes[0].getPixelStride()
        local rowStride = planes[0].getRowStride()
        local width = img.getWidth()
        local height = img.getHeight()
        
        -- Conversion rapide
        local bitmap = Bitmap.createBitmap(width + (rowStride - pixelStride * width) / pixelStride, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(buffer)
        img.close()
        
        local target = scanTarget(bitmap)
        
        if target then
            setInfo("LOCKED", Color.GREEN)
            local moveX = (target.x - CX) * Config.magnet_power
            local moveY = (target.y - CY) * Config.magnet_power
            
            -- Simulation geste
            local s = service or auto -- Service accessibilité
            if s then
                local builder = luajava.bindClass("android.accessibilityservice.GestureDescription$Builder")()
                local p = Path()
                p.moveTo(CX, CY)
                p.lineTo(CX + moveX, CY + moveY)
                local stroke = luajava.bindClass("android.accessibilityservice.GestureDescription$StrokeDescription")(p, 0, 50)
                builder.addStroke(stroke)
                s.dispatchGesture(builder.build(), nil, nil)
            end
        else
            setInfo("SCANNING...", Color.RED)
        end
    end
    handler.postDelayed(loopRunnable, Config.speed_ms)
end})

-- ================= INTERFACE MENU (Sans Images) =================

-- Layout Table
local layout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  {
      LinearLayout,
      orientation="vertical",
      id="MenuContainer",
      visibility="gone", -- Menu caché au départ
      {
          CardView,
          CardBackgroundColor=0xFF222222,
          radius=20,
          elevation=10,
          layout_width="200dp",
          {
              LinearLayout,
              orientation="vertical",
              padding="10dp",
              {
                  TextView,
                  text="MENU BOT",
                  textSize="18sp",
                  textColor=0xFFFFFFFF,
                  gravity="center",
                  layout_marginBottom="10dp"
              },
              -- SWITCH VISION
              {
                  Switch,
                  text="Vision Aim  ",
                  textColor=0xFFEEEEEE,
                  id="swVision",
                  layout_gravity="center"
              },
              -- BOUTON RECORD
              {
                  Button,
                  text="REC ECRAN",
                  id="btnRecord",
                  backgroundColor=0xFF444444,
                  textColor=0xFFFFFFFF,
                  layout_width="match_parent",
                  layout_marginTop="10dp"
              },
          }
      }
  },
  -- BOUTON FLOTTANT (Le rond visible)
  {
      CardView,
      radius=30,
      CardBackgroundColor=0xFF00AAFF, -- Bleu
      elevation=5,
      layout_width="60dp",
      layout_height="60dp",
      id="FloatingBtn",
      {
          TextView,
          text="M",
          textSize="24sp",
          textStyle="bold",
          textColor=0xFFFFFFFF,
          gravity="center",
          layout_width="match_parent",
          layout_height="match_parent"
      }
  }
}

FloatingWindow = loadlayout(layout)

-- Paramètres fenêtre Menu
local wmParams = WindowManager.LayoutParams()
wmParams.type = OVERLAY_TYPE
wmParams.format = PixelFormat.RGBA_8888
wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
wmParams.gravity = Gravity.LEFT | Gravity.TOP
wmParams.x = 0
wmParams.y = SH / 4
wmParams.width = WindowManager.LayoutParams.WRAP_CONTENT
wmParams.height = WindowManager.LayoutParams.WRAP_CONTENT

-- Ajout au gestionnaire
wmManager.addView(FloatingWindow, wmParams)

-- ================= LOGIQUE BOUTONS =================

-- Ouvrir/Fermer Menu
FloatingBtn.onClick = function()
    if MenuContainer.getVisibility() == View.VISIBLE then
        MenuContainer.setVisibility(View.GONE)
    else
        MenuContainer.setVisibility(View.VISIBLE)
    end
end

-- Déplacer le bouton
local startX, startY, initialTouchX, initialTouchY
FloatingBtn.setOnTouchListener(View.OnTouchListener{
    onTouch = function(v, event)
        if event.getAction() == MotionEvent.ACTION_DOWN then
            startX = wmParams.x
            startY = wmParams.y
            initialTouchX = event.getRawX()
            initialTouchY = event.getRawY()
            return true -- Consomme l'event
        elseif event.getAction() == MotionEvent.ACTION_MOVE then
            wmParams.x = startX + (event.getRawX() - initialTouchX)
            wmParams.y = startY + (event.getRawY() - initialTouchY)
            wmManager.updateViewLayout(FloatingWindow, wmParams)
            return true
        elseif event.getAction() == MotionEvent.ACTION_UP then
            -- Click simulé si peu de mouvement
            if math.abs(event.getRawX() - initialTouchX) < 10 then
                FloatingBtn.performClick()
            end
            return true
        end
        return false
    end
})

-- Activer Vision
swVision.setOnCheckedChangeListener({
    onCheckedChanged = function(v, isChecked)
        Config.active = isChecked
        if isChecked then
            -- Lancer la permission Capture d'écran
            if not mMediaProjection then
                local intent = mProjectionManager.createScreenCaptureIntent()
                activity.startActivityForResult(intent, 101)
            else
                startScan()
            end
        else
            boxView.setVisibility(View.GONE)
            statusText.setVisibility(View.GONE)
        end
    end
})

function startScan()
    boxView.setVisibility(View.VISIBLE)
    statusText.setVisibility(View.VISIBLE)
    
    if not mVirtualDisplay then
        mImageReader = ImageReader.newInstance(SW, SH, PixelFormat.RGBA_8888, 2)
        mVirtualDisplay = mMediaProjection.createVirtualDisplay("ScreenCapture",
            SW, SH, displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mImageReader.getSurface(), nil, nil)
    end
    handler.post(loopRunnable)
end

-- Retour permission (OnActivityResult)
function onActivityResult(requestCode, resultCode, data)
    if requestCode == 101 and resultCode == -1 then
        mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data)
        startScan()
    elseif requestCode == 101 then
        swVision.setChecked(false)
        print("Capture refusée")
    end
end