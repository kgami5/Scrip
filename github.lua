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
import "android.graphics.drawable.GradientDrawable" -- Ajouté pour être sûr

activity.setTitle("")
activity.setTheme(R.AndLua1)
activity.setContentView(loadlayout(layout))

-- Configuration Barre de statut
import "android.graphics.drawable.ColorDrawable"
if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))

-- ==================================================
-- ⚠️ PARTIE AJOUTÉE : DÉFINITION DU MENU FLOTTANT
-- C'est ce qui manquait et causait le crash
-- ==================================================
amsmlay = {
  LinearLayout,
  orientation="vertical",
  layout_width="wrap_content",
  layout_height="wrap_content",
  id="mLinearLayout1", -- Le conteneur principal
  {
    TextView, -- Le bouton pour activer/désactiver
    id="Cross",
    text="☠️", -- Icône ou texte du bouton
    textSize="25sp",
    textColor="#FFFFFF",
    gravity="center",
    layout_width="60dp",
    layout_height="60dp",
  }
}
-- ==================================================


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
    -- C'est ici que ça plantait avant, maintenant amsmlay existe !
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

-- Appliquer les styles (Si les IDs existent)
if mLinearLayout1 then CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF) end
if Cross then CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF) end


-- ==========================================
-- FONCTION D'INJECTION (FORCE MODE VM)
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
  os.execute("chmod 777 '" .. path .. "'")
  os.execute("su -c chmod 777 '" .. path .. "'")

  -- 3. Exécution avec LOG (Debug)
  local logFile = activity.getLuaDir("error_log.txt")
  local cmd = "su -c 'nohup \"" .. path .. "\" > /dev/null 2> \"" .. logFile .. "\" &'"
  
  Toast.makeText(activity, "🚀 Tentative d'injection...", Toast.LENGTH_SHORT).show()

  -- 4. Exécution
  local p = Runtime.getRuntime().exec(cmd)
  
  -- Petit délai pour vérifier erreur immédiate
  Thread.sleep(500)
  
  -- Lecture du log d'erreur
  local errFile = io.open(logFile, "r")
  if errFile then
    local content = errFile:read("*a")
    errFile:close()
    if content and #content > 5 then
       if string.find(content, "Exec format error") then
           dialog=AlertDialog.Builder(this)
          .setTitle("ERREUR ARCHITECTURE")
          .setMessage("Problème 32bits vs 64bits.\nTon espace virtuel ne peut pas lancer ce fichier.")
          .show()
       else
           Toast.makeText(activity, "Erreur Logs: " .. content, Toast.LENGTH_LONG).show()
       end
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
    
    -- Tuer le processus
    Runtime.getRuntime().exec("su -c pkill -f ckxkdkkskkhgkkdkskkv")
    Runtime.getRuntime().exec("pkill -f ckxkdkkskkhgkkdkskkv")
    
    Toast.makeText(activity, "Arrêt... 🛑", Toast.LENGTH_SHORT).show()
  end
end
