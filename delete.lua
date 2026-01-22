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
-- Imports pour le Tir et le Lock
import "android.accessibilityservice.*"
import "android.accessibilityservice.GestureDescription"
import "android.graphics.Path"

-- ================= 1. INTERFACE PRINCIPALE =================
local mainLayout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  BackgroundColor="#222222",
  {
    TextView,
    text="AIMBOT + LOCK (-52)",
    textSize="25sp",
    textStyle="bold",
    textColor="#FFFFFF",
    layout_marginBottom="30dp"
  },
  {
    CardView,
    radius=20,
    CardBackgroundColor="#444444",
    elevation=10,
    layout_width="80%w",
    {
      LinearLayout,
      orientation="vertical",
      padding="20dp",
      {
        Button,
        text="1. PERMISSION REQUIS",
        id="btnPerm",
        layout_width="match_parent",
        BackgroundColor="#FF9800",
        textColor="#FFFFFF",
        layout_marginBottom="10dp"
      },
      {
        Button,
        text="2. LANCER LE WIDGET",
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
    textColor="#AAAAAA",
    layout_marginTop="20dp"
  }
}

activity.setTheme(android.R.style.Theme_Material_NoActionBar)
activity.setContentView(loadlayout(mainLayout))

-- ================= 2. CONFIGURATION GLOBALE =================
local Config = {
    active = false,
    box_size = 200,      -- Taille visuelle du carré
    offset_x = -52,      -- DÉCALAGE DEMANDÉ
    scan_range = 60,     -- Rayon de recherche du rouge
    scan_step = 5,       -- Précision
    sensitivity = 0.8,   -- Force du Aimlock
    speed_ms = 10        -- Vitesse boucle
}

local wmManager = activity.getSystemService(Context.WINDOW_SERVICE)
local mProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local displayMetrics = DisplayMetrics()
wmManager.getDefaultDisplay().getRealMetrics(displayMetrics)
local SW, SH = displayMetrics.widthPixels, displayMetrics.heightPixels

-- CALCUL DU CENTRE AVEC LE DÉCALAGE (-52)
local CX = (SW / 2) + Config.offset_x
local CY = SH / 2

local widgetVisible = false
local FloatingWindow, BoxWindow

-- ================= 3. GESTION PERMISSION =================
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

-- ================= 4. WIDGET & VISUEL =================
function createFloatingWidget()
    if widgetVisible then return end
    local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002 

    local floatLayout = {
      LinearLayout,
      {
          CardView,
          radius=30, CardBackgroundColor="#00AAFF", elevation=10,
          layout_width="60dp", layout_height="60dp", id="floatBtn",
          {
              TextView, text="AIM", textSize="20sp", textStyle="bold", textColor="#FFFFFF",
              gravity="center", layout_width="fill", layout_height="fill"
          }
      }
    }
    
    FloatingWindow = loadlayout(floatLayout)
    local wmParams = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT)
    wmParams.gravity = Gravity.LEFT | Gravity.TOP
    wmParams.y = 300

    wmManager.addView(FloatingWindow, wmParams)
    widgetVisible = true
    initTouchListener(floatBtn, wmParams, FloatingWindow)
    createAimBox(OVERLAY_TYPE)
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
                if math.abs(event.getRawX() - rawX) < 10 then toggleMenu() end
                return true
            end
            return false
        end
    })
end

function toggleMenu()
    if not Config.active then
        local intent = mProjectionManager.createScreenCaptureIntent()
        activity.startActivityForResult(intent, 101)
    else
        stopScan()
    end
end

function createAimBox(type)
    local boxView = View(activity)
    local gd = GradientDrawable()
    gd.setStroke(4, Color.RED)
    gd.setCornerRadius(15)
    boxView.setBackgroundDrawable(gd)
    
    local lp = WindowManager.LayoutParams(Config.box_size, Config.box_size, type, 
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE, 
        PixelFormat.TRANSLUCENT)
    
    -- CENTRAGE DU CARRÉ AVEC OFFSET
    lp.gravity = Gravity.CENTER
    lp.x = Config.offset_x  -- Ici on applique le -52 au visuel
    
    BoxWindow = boxView
    wmManager.addView(BoxWindow, lp)
    BoxWindow.setVisibility(View.GONE)
end

-- ================= 5. LOGIQUE AIMLOCK & TIR =================
function aimAndShoot(targetX, targetY)
    if not service then return end

    local path = Path()
    path.moveTo(CX, CY) -- Départ du centre décalé (-52)
    
    -- Calcul du Lock
    local dx = (targetX - CX) * Config.sensitivity
    local dy = (targetY - CY) * Config.sensitivity
    
    path.lineTo(CX + dx, CY + dy)

    local builder = GestureDescription.Builder()
    local stroke = GestureDescription.StrokeDescription(path, 0, 10)
    builder.addStroke(stroke)
    
    pcall(function() service.dispatchGesture(builder.build(), nil, nil) end)
end

-- ================= 6. SCANNER INTELLIGENT =================
local mImageReader, mMediaProjection
local handler = Handler(Looper.getMainLooper())

function startScan(resultCode, data)
    Config.active = true
    floatBtn.CardBackgroundColor = 0xFF4CAF50 -- Vert
    BoxWindow.setVisibility(View.VISIBLE)
    
    mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data)
    mImageReader = ImageReader.newInstance(SW, SH, PixelFormat.RGBA_8888, 2)
    mMediaProjection.createVirtualDisplay("Scan", SW, SH, displayMetrics.densityDpi, 
        DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, mImageReader.getSurface(), nil, nil)
        
    handler.post(scanLoop)
end

function stopScan()
    Config.active = false
    floatBtn.CardBackgroundColor = 0xFF00AAFF
    BoxWindow.setVisibility(View.GONE)
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
        
        -- SCAN AUTOUR DU CENTRE DÉCALÉ (CX)
        local totalX, totalY, count = 0, 0, 0
        local range = Config.scan_range
        
        for x = CX - range, CX + range, Config.scan_step do
            for y = CY - range, CY + range, Config.scan_step do
                -- Vérif pour ne pas sortir de l'image
                if x > 0 and x < width and y > 0 and y < height then
                    local pixel = bitmap.getPixel(x, y)
                    local r = (pixel >> 16) & 0xFF
                    local g = (pixel >> 8) & 0xFF
                    local b = pixel & 0xFF
                    
                    -- DÉTECTION ROUGE
                    if r > 180 and r > (g + 60) and r > (b + 60) then
                        totalX = totalX + x
                        totalY = totalY + y
                        count = count + 1
                    end
                end
            end
        end
        
        if count > 0 then
            local targetX = totalX / count
            local targetY = totalY / count
            
            -- VISUEL VERT
            local gd = GradientDrawable()
            gd.setStroke(6, Color.GREEN)
            BoxWindow.setBackgroundDrawable(gd)
            
            -- ACTION : TIR + LOCK
            aimAndShoot(targetX, targetY)
        else
            -- VISUEL ROUGE
            local gd = GradientDrawable()
            gd.setStroke(4, Color.RED)
            BoxWindow.setBackgroundDrawable(gd)
        end
        
        bitmap.recycle()
    end
    handler.postDelayed(scanLoop, Config.speed_ms)
end})

-- ================= 7. CALLBACKS =================
btnStart.onClick = function()
    if Settings.canDrawOverlays(activity) then
        createFloatingWidget()
    else
        print("Il faut la permission d'abord !")
    end
end

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 101 and resultCode == -1 then
        startScan(resultCode, data)
    end
end