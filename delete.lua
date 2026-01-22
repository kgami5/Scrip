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

-- ================= 1. INTERFACE PRINCIPALE (STOPPE L'ÉCRAN BLANC) =================
local mainLayout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  BackgroundColor="#222222",
  {
    TextView,
    text="AIMBOT CONTROLLER",
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
        text="1. VÉRIFIER PERMISSION",
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

-- AFFICHE L'INTERFACE PRINCIPALE IMMÉDIATEMENT
activity.setTheme(android.R.style.Theme_Material_NoActionBar)
activity.setContentView(loadlayout(mainLayout))

-- ================= 2. CONFIGURATION GLOBALE =================
local Config = {
    active = false,
    box_size = 200,      
    speed_ms = 30,       
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

local widgetVisible = false
local FloatingWindow, BoxWindow, StatusWindow

-- ================= 3. GESTION PERMISSION =================
btnPerm.onClick = function()
    if not Settings.canDrawOverlays(activity) then
        logText.setText("Demande permission superposition...")
        local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, 
            Uri.parse("package:" .. activity.getPackageName()))
        activity.startActivity(intent)
    else
        logText.setText("✅ Permission OK")
        btnPerm.setBackgroundColor(0xFF4CAF50)
        btnPerm.setText("PERMISSION : OK")
    end
end

-- ================= 4. CRÉATION DU WIDGET FLOTTANT =================
function createFloatingWidget()
    if widgetVisible then return end
    
    local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002 

    -- LAYOUT FLOTTANT
    local floatLayout = {
      LinearLayout,
      {
          CardView,
          radius=30,
          CardBackgroundColor="#00AAFF",
          elevation=10,
          layout_width="60dp",
          layout_height="60dp",
          id="floatBtn",
          {
              TextView,
              text="M",
              textSize="24sp",
              textStyle="bold",
              textColor="#FFFFFF",
              gravity="center",
              layout_width="fill",
              layout_height="fill"
          }
      }
    }
    
    FloatingWindow = loadlayout(floatLayout)
    
    local wmParams = WindowManager.LayoutParams()
    wmParams.type = OVERLAY_TYPE
    wmParams.format = PixelFormat.RGBA_8888
    wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
    wmParams.gravity = Gravity.LEFT | Gravity.TOP
    wmParams.x = 0
    wmParams.y = 300
    wmParams.width = -2
    wmParams.height = -2

    -- AJOUT SÉCURISÉ
    local success, err = pcall(function()
        wmManager.addView(FloatingWindow, wmParams)
    end)
    
    if success then
        widgetVisible = true
        logText.setText("✅ Widget affiché sur l'écran")
        -- Initialiser le mouvement du bouton
        initTouchListener(floatBtn, wmParams, FloatingWindow)
        -- Créer la boite de visée (cachée)
        createAimBox(OVERLAY_TYPE)
    else
        logText.setText("❌ Erreur Widget: " .. tostring(err))
    end
end

-- Mouvement du bouton flottant
function initTouchListener(view, params, window)
    local startX, startY, rawX, rawY
    view.setOnTouchListener(View.OnTouchListener{
        onTouch = function(v, event)
            if event.getAction() == MotionEvent.ACTION_DOWN then
                startX = params.x
                startY = params.y
                rawX = event.getRawX()
                rawY = event.getRawY()
                return true
            elseif event.getAction() == MotionEvent.ACTION_MOVE then
                params.x = startX + (event.getRawX() - rawX)
                params.y = startY + (event.getRawY() - rawY)
                wmManager.updateViewLayout(window, params)
                return true
            elseif event.getAction() == MotionEvent.ACTION_UP then
                if math.abs(event.getRawX() - rawX) < 10 then
                   toggleMenu() -- Simple clic
                end
                return true
            end
            return false
        end
    })
end

-- ================= 5. MENU ET LOGIQUE (Simplifiée) =================
function toggleMenu()
    -- Ici tu pourrais ouvrir un sous-menu. 
    -- Pour l'instant, le bouton sert de ON/OFF pour la détection
    if not Config.active then
        -- Démarrer
        local intent = mProjectionManager.createScreenCaptureIntent()
        activity.startActivityForResult(intent, 101)
    else
        -- Arrêter
        stopScan()
    end
end

function createAimBox(type)
    local boxView = View(activity)
    local gd = GradientDrawable()
    gd.setStroke(5, Color.RED)
    gd.setCornerRadius(15)
    boxView.setBackgroundDrawable(gd)
    
    local lp = WindowManager.LayoutParams(Config.box_size, Config.box_size, type, 
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | 
        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE, 
        PixelFormat.TRANSLUCENT)
    lp.gravity = Gravity.CENTER
    lp.x = Config.offset_x
    
    BoxWindow = boxView
    wmManager.addView(BoxWindow, lp)
    BoxWindow.setVisibility(View.GONE)
end

-- ================= 6. SCANNER LOGIQUE =================
local mImageReader, mVirtualDisplay, mMediaProjection
local handler = Handler(Looper.getMainLooper())

function startScan(resultCode, data)
    Config.active = true
    floatBtn.CardBackgroundColor = 0xFF4CAF50 -- Vert
    BoxWindow.setVisibility(View.VISIBLE)
    
    mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data)
    mImageReader = ImageReader.newInstance(SW, SH, PixelFormat.RGBA_8888, 2)
    mVirtualDisplay = mMediaProjection.createVirtualDisplay("Scan", SW, SH, 
        displayMetrics.densityDpi, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, 
        mImageReader.getSurface(), nil, nil)
        
    handler.post(scanLoop)
end

function stopScan()
    Config.active = false
    floatBtn.CardBackgroundColor = 0xFF00AAFF -- Bleu
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
        
        -- Conversion simplifiée Bitmap (Attention performance)
        local bitmap = Bitmap.createBitmap(width + (rowStride - pixelStride * width) / pixelStride, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(buffer)
        img.close()
        
        -- SCAN RAPIDE AU CENTRE
        local found = false
        local centerPixel = bitmap.getPixel(CX, CY)
        local r = (centerPixel >> 16) & 0xFF
        
        -- Si pixel rouge au centre
        if r > 200 then
            local gd = GradientDrawable()
            gd.setStroke(5, Color.GREEN)
            BoxWindow.setBackgroundDrawable(gd)
            -- ICI METTRE LE CLIC AUTO
        else
            local gd = GradientDrawable()
            gd.setStroke(5, Color.RED)
            BoxWindow.setBackgroundDrawable(gd)
        end
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