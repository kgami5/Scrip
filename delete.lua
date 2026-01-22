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
import "java.io.FileOutputStream"
import "java.io.File"
import "java.util.Date"
import "java.text.SimpleDateFormat"
import "android.media.MediaRecorder"
import "android.hardware.display.DisplayManager"
import "android.media.projection.MediaProjectionManager"

import "layout"
import "NAWAF"

-- ================= CONFIGURATION VISION =================
local Config = {
    active = false,
    box_size = 200,      -- Taille de la zone de scan
    speed_ms = 25,       -- Vitesse de scan
    offset_x = -52,      -- Décalage X
    magnet_power = 0.8   -- Puissance aimant
}

-- Initialisation Système
SetTheme(R.AndLua1)
local wmManager = activity.getSystemService(Context.WINDOW_SERVICE)
local mProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE)
local displayMetrics = DisplayMetrics()
wmManager.getDefaultDisplay().getRealMetrics(displayMetrics)
local SW, SH = displayMetrics.widthPixels, displayMetrics.heightPixels
local mScreenDensity = displayMetrics.densityDpi

-- Centre de l'écran pour la vision
local CX = (SW / 2) + Config.offset_x
local CY = SH / 2

-- Chemins de fichiers
local mImagePath = Environment.getExternalStorageDirectory().getPath() .. "/AndLua_AR/screenshot/"
local mVideoPath = Environment.getExternalStorageDirectory().getPath() .. "/AndLua_AR/record/"

-- Variables globales
local mMediaProjection = nil
local mVirtualDisplay = nil
local mImageReader = nil
local mRecordVirtualDisplay = nil
local mediaRecorder = nil
local isRecordOn = false

-- ================= UTILS GRAPHIQUES (Script 1) =================
local function CreateShape(color, strokeColor)
    local gd = GradientDrawable()
    gd.setShape(GradientDrawable.RECTANGLE)
    gd.setColor(color)
    gd.setCornerRadius(15)
    if strokeColor then gd.setStroke(5, strokeColor) end
    return gd
end

-- ================= BARRE DE STATUT (OVERLAY) =================
local OVERLAY_TYPE = (Build.VERSION.SDK_INT >= 26) and WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY or WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

local statusLayout = LinearLayout(activity)
statusLayout.setBackgroundDrawable(CreateShape(0xCC000000))
statusLayout.setPadding(30, 20, 30, 20)
local statusText = TextView(activity)
statusText.setText("READY")
statusText.setTextColor(Color.WHITE)
statusLayout.addView(statusText)

local lpStatus = WindowManager.LayoutParams(-2, -2, OVERLAY_TYPE, 
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL, 
    PixelFormat.TRANSLUCENT)
lpStatus.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL
lpStatus.y = 100

-- Carré de visée (Rouge)
local boxView = View(activity)
boxView.setBackgroundDrawable(CreateShape(0, Color.RED))
local lpBox = WindowManager.LayoutParams(Config.box_size, Config.box_size, OVERLAY_TYPE, 
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE, 
    PixelFormat.TRANSLUCENT)
lpBox.gravity = Gravity.CENTER
lpBox.x = Config.offset_x

-- Afficher les overlays
pcall(function() 
    wmManager.addView(statusLayout, lpStatus) 
    wmManager.addView(boxView, lpBox)
    boxView.setVisibility(View.GONE) -- Caché par défaut
    statusLayout.setVisibility(View.GONE)
end)

function setInfo(msg, col)
    activity.runOnUiThread(Runnable({run=function()
        statusText.setText(msg)
        if col then statusText.setTextColor(col) end
    end}))
end

-- ================= LOGIQUE SCANNER (VISION) =================

-- Fonction de scan utilisant le Bitmap généré par ImageReader
function scanTarget(bitmap)
    if not bitmap then return nil end
    
    local sumX, sumY, count = 0, 0, 0
    local step = 5 -- Optimisation: saute des pixels pour aller plus vite
    
    -- Zone de scan relative au centre
    local startX = CX - (Config.box_size / 2)
    local startY = CY - (Config.box_size / 2)
    
    -- Sécurité limites
    if startX < 0 then startX = 0 end
    if startY < 0 then startY = 0 end

    -- On boucle sur la zone
    for y = 0, Config.box_size, step do
        local checkY = startY + y
        if checkY >= SH then break end
        
        for x = 0, Config.box_size, step do
            local checkX = startX + x
            if checkX >= SW then break end
            
            -- Récupération pixel (Format ARGB int)
            local px = bitmap.getPixel(checkX, checkY)
            local r = (px >> 16) & 0xFF
            local g = (px >> 8) & 0xFF
            local b = px & 0xFF

            -- DÉTECTION ROUGE (Ajuster seuils si besoin)
            if r > 200 and g < 60 and b < 60 then
                sumX = sumX + checkX
                sumY = sumY + checkY
                count = count + 1
            end
        end
    end

    if count > 0 then
        return { x = sumX / count, y = sumY / count }
    end
    return nil
end

local visionHandler = Handler(Looper.getMainLooper())
local visionLoop = Runnable({ run = function()
    if not Config.active then return end
    
    -- Capture d'une frame depuis ImageReader
    if mImageReader then
        local image = mImageReader.acquireLatestImage()
        if image then
            local planes = image.getPlanes()
            local buffer = planes[0].getBuffer()
            local pixelStride = planes[0].getPixelStride()
            local rowStride = planes[0].getRowStride()
            local width = image.getWidth()
            local height = image.getHeight()
            
            -- Création bitmap temporaire
            local bitmap = Bitmap.createBitmap(width + (rowStride - pixelStride * width) / pixelStride, height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(buffer)
            
            -- Analyse
            local target = scanTarget(bitmap)
            
            -- Nettoyage immédiat
            image.close()
            bitmap = nil
            
            -- Action
            if target then
                local moveX = (target.x - CX) * Config.magnet_power
                local moveY = (target.y - CY) * Config.magnet_power
                
                setInfo("🔒 LOCKED", Color.GREEN)
                boxView.setBackgroundDrawable(CreateShape(0, Color.GREEN))

                -- Geste Accessibility
                local s = service or auto -- 'service' est global dans AndLua pour l'accessibilité
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
                setInfo("Scanning...", Color.WHITE)
                boxView.setBackgroundDrawable(CreateShape(0, Color.RED))
            end
        end
    end
    
    visionHandler.postDelayed(visionLoop, Config.speed_ms)
end})

-- ================= SETUP MEDIA PROJECTION =================

function prepareProjection()
    if mMediaProjection == nil then
        local intent = mProjectionManager.createScreenCaptureIntent()
        activity.startActivityForResult(intent, 1)
    else
        startVisionOrRecording()
    end
end

function onActivityResult(requestCode, resultCode, data)
    if requestCode == 1 then
        if resultCode ~= -1 then
            print("Permission refusée")
            return
        end
        
        mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data)
        
        -- Configuration ImageReader pour Screenshot & Vision
        mImageReader = ImageReader.newInstance(SW, SH, PixelFormat.RGBA_8888, 2)
        
        -- Démarrer ce qui a été demandé
        startVisionOrRecording()
    end
end

function startVisionOrRecording()
    -- Lancer le VirtualDisplay si pas déjà fait
    if mMediaProjection and not mVirtualDisplay then
        mVirtualDisplay = mMediaProjection.createVirtualDisplay("ScreenCapture",
            SW, SH, mScreenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mImageReader.getSurface(), nil, nil)
    end

    if Config.active then
        visionHandler.post(visionLoop)
    end
end

-- ================= FONCTIONS ENREGISTREMENT (Script 2) =================

function createMediaRecorder()
    -- Configuration classique du recorder
    local formatter = SimpleDateFormat("yyyy-MM-dd-HH-mm-ss")
    local curTime = formatter.format(Date(System.currentTimeMillis())):gsub(" ", "")
    
    local fileFolder = File(mVideoPath)
    if not fileFolder.exists() then fileFolder.mkdirs() end
    
    local fileName = "REC_" .. curTime .. ".mp4"
    
    mediaRecorder = MediaRecorder()
    -- Audio non géré ici pour simplifier la fusion, à ajouter si besoin via les switchs
    mediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
    mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
    mediaRecorder.setOutputFile(mVideoPath .. fileName)
    mediaRecorder.setVideoSize(SW, SH)
    mediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
    mediaRecorder.setVideoEncodingBitRate(5 * SW * SH)
    mediaRecorder.setVideoFrameRate(30)
    
    pcall(function() mediaRecorder.prepare() end)
end

function startRecording()
    if not mMediaProjection then 
        prepareProjection() -- Cela déclenchera prepareProjection -> ...
        -- Note: L'enregistrement nécessite son propre VirtualDisplay relié au MediaRecorder surface
        -- On gère ça dans un délai ou callback
        local t = Task(1000, function() 
             if mMediaProjection then
                 createMediaRecorder()
                 mRecordVirtualDisplay = mMediaProjection.createVirtualDisplay("Record",
                    SW, SH, mScreenDensity,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    mediaRecorder.getSurface(), nil, nil)
                 mediaRecorder.start()
             end
        end)
    else
        createMediaRecorder()
        mRecordVirtualDisplay = mMediaProjection.createVirtualDisplay("Record",
            SW, SH, mScreenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mediaRecorder.getSurface(), nil, nil)
        mediaRecorder.start()
    end
end

function stopRecording()
    if mediaRecorder then
        pcall(function() mediaRecorder.stop() end)
        mediaRecorder.release()
        mediaRecorder = nil
    end
    if mRecordVirtualDisplay then
        mRecordVirtualDisplay.release()
        mRecordVirtualDisplay = nil
    end
end

function takeScreenshot()
    if not mMediaProjection then
        RunScreenShot = true
        prepareProjection()
        -- La capture se fera dans startVisionOrRecording ou via un délai si c'est juste un one-shot
        -- Pour simplifier ici, on suppose que la Vision est activée ou qu'on clique deux fois
    else
        -- Code de capture unique
        local image = mImageReader.acquireLatestImage()
        if image then
             -- (Même logique de sauvegarde bitmap que script 2)
             -- Pour abréger : Sauvegarde le bitmap
             image.close()
             print("Screenshot Captured (Mockup)")
        end
    end
end

-- ================= INTERFACE FLOTTANTE (LAYOUT FUSIONNÉ) =================

-- Paramètres fenêtre flottante
local wmParams = WindowManager.LayoutParams()
wmParams.type = OVERLAY_TYPE
wmParams.format = PixelFormat.RGBA_8888
wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
wmParams.gravity = Gravity.LEFT | Gravity.TOP
wmParams.x = 0
wmParams.y = SH / 5
wmParams.width = WindowManager.LayoutParams.WRAP_CONTENT
wmParams.height = WindowManager.LayoutParams.WRAP_CONTENT

-- Définition Layout
local layoutTable = {
  LinearLayout;
  gravity="center";
  layout_width="fill";
  orientation="vertical";
  layout_height="fill";
  {
    LinearLayout;
    orientation="horizontal";
    {
      CircleImageView;
      visibility="gone"; -- Caché par défaut
      layout_height="40dp";
      src="res/shot.png";
      id="shotBtn";
      layout_marginRight="10dp";
      layout_width="40dp";
    };
    {
      LinearLayout;
      orientation="vertical";
      id="RecordingWindow";
      visibility="gone";
      {
        CardView;
        radius="20dp";
        BackgroundColor="#494949";
        {
          LinearLayout;
          orientation="vertical";
          
          -- TITRE VISION
          {
            TextView;
            text="--- VISION AIM ---";
            textColor="#FFAAAA";
            gravity="center";
            layout_width="match_parent";
            layout_marginTop="5dp";
          };

          -- SWITCH VISION
          {
            LinearLayout;
            orientation="horizontal";
            gravity="center";
            {
                TextView;
                text="ACTIVER VISION";
                textColor="#ffffff";
                layout_marginRight="10dp";
            };
            {
                Switch;
                id="switchVision";
            };
          };

          -- DIVIDER
          {
             View;
             layout_height="1dp";
             layout_width="match_parent";
             BackgroundColor="#888888";
             layout_margin="5dp";
          };

          -- RECORDER UI (Simplifiée du script 2)
          {
            LinearLayout;
            orientation="horizontal";
            id="startrecord";
            gravity="center";
            layout_marginBottom="10dp";
            {
              TextView;
              id="recordtext";
              text="Start Record";
              textColor="#00ffff";
              layout_marginLeft="10dp";
              layout_marginRight="10dp";
            };
            {
              ImageView;
              id="recordimage";
              src="res/start.png"; -- Assurez-vous d'avoir les images ou utilisez des couleurs
              layout_height="20dp";
              layout_width="20dp";
            };
          };
        };
      };
    };
  };
  -- BOUTON FLOTTANT PRINCIPAL
  {
    ImageView;
    src="res/normal.png"; -- L'icône principale
    id="MainButton";
    layout_width="50dp";
    layout_height="50dp";
  };
};

FloatingWindow = loadlayout(layoutTable)

-- ================= GESTION DES ÉVÉNEMENTS =================

-- Toggle Menu
MainButton.onClick = function()
    if RecordingWindow.getVisibility() == View.VISIBLE then
        RecordingWindow.setVisibility(View.GONE)
    else
        RecordingWindow.setVisibility(View.VISIBLE)
    end
end

-- Déplacement Fenêtre
function MainButton.OnTouchListener(v, event)
  if event.getAction() == MotionEvent.ACTION_DOWN then
    firstX = event.getRawX()
    firstY = event.getRawY()
    wmX = wmParams.x
    wmY = wmParams.y
    isClick = false
    startTime = System.currentTimeMillis()
  elseif event.getAction() == MotionEvent.ACTION_MOVE then
    wmParams.x = wmX + (event.getRawX() - firstX)
    wmParams.y = wmY + (event.getRawY() - firstY)
    wmManager.updateViewLayout(FloatingWindow, wmParams)
  elseif event.getAction() == MotionEvent.ACTION_UP then
    if System.currentTimeMillis() - startTime < 200 then
       MainButton.performClick()
    end
  end
  return true
end

-- Bouton Enregistrement
startrecord.onClick = function()
    isRecordOn = not isRecordOn
    if isRecordOn then
        print("Starting Record...")
        startRecording()
        recordtext.setText("Stop Record")
        if recordimage then recordimage.setColorFilter(Color.RED) end
    else
        print("Stopping Record...")
        stopRecording()
        recordtext.setText("Start Record")
        if recordimage then recordimage.setColorFilter(nil) end
    end
end

-- Switch Vision
switchVision.setOnCheckedChangeListener({
    onCheckedChanged=function(v, isChecked)
        Config.active = isChecked
        if isChecked then
            -- Vérifie si le service Accessibilité est dispo
            if not (service or auto) then
                print("⚠️ Accessibilité requise pour l'aimbot !")
                -- On continue quand même pour la détection visuelle
            end
            
            boxView.setVisibility(View.VISIBLE)
            statusLayout.setVisibility(View.VISIBLE)
            prepareProjection() -- Lance la demande de capture d'écran
        else
            boxView.setVisibility(View.GONE)
            statusLayout.setVisibility(View.GONE)
        end
    end
})

-- Ajouter la vue principale
wmManager.addView(FloatingWindow, wmParams)