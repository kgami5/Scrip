require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "android.content.Context"
import "android.graphics.PixelFormat"
import "android.provider.Settings"
import "android.content.Intent"
import "android.net.Uri"

import "min"
activity.setTitle("")
activity.setTheme(R.AndLua1)
activity.setContentView(loadlayout(layout))

-- Configuration Barre de statut
import "android.graphics.drawable.ColorDrawable"
if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))


-- Gestion Fenêtre Flottante
do
  amsm7abdo=activity.getSystemService(Context.WINDOW_SERVICE)
  amsmParam =WindowManager.LayoutParams()
  amsmParam.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
  amsmParam.format =PixelFormat.RGBA_8888
  amsmParam.flags=WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  amsmParam.gravity = Gravity.CENTER
  amsmParam.width =WindowManager.LayoutParams.WRAP_CONTENT
  amsmParam.height =WindowManager.LayoutParams.WRAP_CONTENT
  
  -- Vérification permission Overlay
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    print("Permission Overlay requise")
    intent=Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    activity.startActivityForResult(intent, 100)
    Toast.makeText(activity, "Active la permission et relance l'app", Toast.LENGTH_LONG).show()
  else
    amsm7min=loadlayout(amsmlay)
  end
end

-- Styles Boutons
function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(9, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

-- Appliquer les styles
CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF)
CircleButtonA(mLinearLayout2,0xFFFF0000,100,0xFFFFFFFF)
CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF)


-- ==========================================
-- FONCTION D'INJECTION (CORRIGÉE POUR VM)
-- ==========================================
function AMSMEF(fileName)
  local path = activity.getLuaDir(fileName)
  
  -- 1. Vérification existence fichier
  local f = io.open(path, "r")
  if f == nil then
    Toast.makeText(activity, "⚠️ Binaire introuvable: "..fileName, Toast.LENGTH_LONG).show()
    return
  else
    f:close()
  end

  -- 2. Donner les permissions (Force brute)
  -- On le fait via os.execute pour être sûr
  os.execute("chmod 777 '" .. path .. "'")
  os.execute("su -c chmod 777 '" .. path .. "'")

  -- 3. Préparation commande avec LOG pour débogage
  -- On utilise sh pour lancer su pour éviter les soucis de path
  -- On redirige les erreurs vers un fichier temp pour voir pourquoi ça plante
  local logFile = activity.getLuaDir("error_log.txt")
  local cmd = "su -c 'nohup \"" .. path .. "\" > /dev/null 2> \"" .. logFile .. "\" &'"
  
  Toast.makeText(activity, "🚀 Tentative d'injection...", Toast.LENGTH_SHORT).show()

  -- 4. Exécution
  local p = Runtime.getRuntime().exec(cmd)
  
  -- Petit délai pour vérifier si ça a crashé tout de suite
  Thread.sleep(500)
  
  -- Lecture du log d'erreur
  local errFile = io.open(logFile, "r")
  if errFile then
    local content = errFile:read("*a")
    errFile:close()
    if content and #content > 5 then
       print("⚠️ ERREUR DÉTECTÉE : " .. content)
       if string.find(content, "Exec format error") then
           dialog=AlertDialog.Builder(this)
          .setTitle("ERREUR ARCHITECTURE")
          .setMessage("Ton binaire est compilé en 64 bits mais ta VM est en 32 bits.\n\nSolution: Utilise une VM 64 bits (ex: F1VM 64bit) ou compile en 32 bits.")
          .show()
       else
           Toast.makeText(activity, "Erreur: " .. content, Toast.LENGTH_LONG).show()
       end
    else
       print("✅ Injection semblée OK (Pas d'erreur logguée)")
    end
  end
end


-- ==========================================
-- BOUTON CROSS (ON/OFF)
-- ==========================================
amsm7A = false
function Cross.onClick()
  if (amsm7A == false) then
    -- ON
    if amsm7min then amsm7abdo.addView(amsm7min, amsmParam) end
    CircleButtonA(Cross, 0xFF009F00, 200, 0xFFFFFFFF) -- Vert
    amsm7A = true
    
    -- Lancer l'injecteur
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv") 

  else
    -- OFF
    if amsm7min then amsm7abdo.removeView(amsm7min) end
    CircleButtonA(Cross, 0xFFBD0000, 200, 0xFFFFFFFF) -- Rouge
    amsm7A = false
    
    -- Tuer le processus (Force brute, pas de check root)
    Runtime.getRuntime().exec("su -c pkill -f ckxkdkkskkhgkkdkskkv")
    Runtime.getRuntime().exec("pkill -f ckxkdkkskkhgkkdkskkv")
    
    Toast.makeText(activity, "Arrêt... 🛑", Toast.LENGTH_SHORT).show()
  end
end
    
