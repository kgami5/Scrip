require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.content.Context"
import "android.content.Intent"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.GradientDrawable"
import "com.androlua.util.RootUtil"

-- IMPORTANTS : On charge tes fichiers UI ici
import "layout"  -- Ton layout principal
import "min"     -- Ton menu flottant (amsmlay)

-- ===========================
-- 1. CONFIGURATION PRINCIPALE
-- ===========================
activity.setTitle("")
activity.setTheme(R.AndLua1)
-- On charge le layout principal
activity.setContentView(loadlayout(layout))

if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))

-- ===========================
-- 2. ANIMATION TEXTE (Ton code)
-- ===========================
Update_UI=function(str)
  if t1 then t1.Text=str end
end

Start=function(str)
  require"import"
  function slg(str)
    return(utf8.len(str))
  end
  function sgg(s,i,j)
    i,j=tonumber(i),tonumber(j)
    i=utf8.offset(s,i)
    j=((j or -1)==-1 and -1) or
    utf8.offset(s,j-1)+1
    return string.sub(s,i,j)
  end
  for i=1,slg(str) do
    call("Update_UI",sgg(str,1,i).."|")
    Thread.sleep(200)
  end
  while true do
    call("Update_UI",sgg(str,1,i).."|")
    Thread.sleep(400)
    call("Update_UI",sgg(str,1,i).."")
    Thread.sleep(400)
  end
end

thread(Start," 01010 connected ... Hello There its me @KGAMI5 from boost3000.fr | welcome for tiktok Instagram telegram and more social media go to the website www.boost3000.fr you Can buy followers views likes and more")


-- ===========================
-- 3. GESTION FENÊTRE FLOTTANTE
-- ===========================
do
  amsm7abdo=activity.getSystemService(Context.WINDOW_SERVICE)
  HasFocus=false
  amsmParam =WindowManager.LayoutParams()
  amsmParam.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
  amsmParam.format =PixelFormat.RGBA_8888
  amsmParam.flags=WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  amsmParam.gravity = Gravity.CENTER
  amsmParam.x = 0
  amsmParam.y = 0
  amsmParam.width =WindowManager.LayoutParams.WRAP_CONTENT
  amsmParam.height =WindowManager.LayoutParams.WRAP_CONTENT
  
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    print("Permission requise")
    intent=Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    activity.startActivityForResult(intent, 100)
    -- os.exit() 
  else
    -- C'est ici que ça plantait. Comme on a fait import "min" en haut, 
    -- amsmlay existe maintenant !
    if amsmlay then
        amsm7min=loadlayout(amsmlay)
    else
        print("ERREUR: amsmlay n'est pas trouvé dans min.lua")
        Toast.makeText(activity, "Erreur: UI 'min' introuvable", Toast.LENGTH_LONG).show()
    end
  end
end

-- ===========================
-- 4. STYLES BOUTONS
-- ===========================
function CircleButton(view,InsideColor,radiu,InsideColor1)
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(5, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(9, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

-- Application des styles (Vérifie que les IDs existent dans ton layout min)
if mLinearLayout1 then CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF) end
if mLinearLayout2 then CircleButtonA(mLinearLayout2,0xFFFF0000,100,0xFFFFFFFF) end
if Cross then CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF) end


-- ===========================
-- 5. VÉRIFICATION DATE
-- ===========================
Date = "20260120"
date = os.date("%Y%m%d")
if date >= Date then
  dialog=AlertDialog.Builder(this)
  .setTitle("⚠️ EXPIRED ⚠️")
  .setCancelable(false)
  .setMessage("UPDATE IS REQUIRED")
  .setPositiveButton("EXIT",{onClick=function(v) os.exit() end})
  .setNeutralButton("CONTACT",{onClick = function(v)
      url = "https://t.me/KGAMI5"
      activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
      os.exit()
    end})
  .show()
  return
end


-- ===========================
-- 6. FONCTION D'INJECTION (FORCE VM)
-- ===========================
function AMSMEF(fileName)
  local path = activity.getLuaDir(fileName)
  
  -- 1. On donne les droits (Normal + Root)
  os.execute("chmod 777 '" .. path .. "'")
  os.execute("su -c chmod 777 '" .. path .. "'")

  -- 2. On lance l'exécutable SANS vérifier RootUtil
  -- On ajoute 'nohup' pour que ça ne fige pas l'écran
  -- On ajoute '> /dev/null' pour vider le buffer
  local cmd = "su -c 'nohup \"" .. path .. "\" > /dev/null 2>&1 &'"
  
  -- Exécution
  Runtime.getRuntime().exec(cmd)
  
  print("Injection lancée : "..fileName)
end

-- ===========================
-- 7. CLIC BOUTON
-- ===========================
amsm7A=false
function Cross.onClick()
  if (amsm7A==false) then
    amsm7abdo.addView(amsm7min,amsmParam)
    CircleButtonA(Cross,0xFF009F00,200,0xFFFFFFFF)
    amsm7A=true
    
    -- Lancer l'injecteur
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv")

   else
    amsm7abdo.removeView(amsm7min)
    CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF)
    amsm7A=false
    
    -- Arrêter l'injecteur
    Runtime.getRuntime().exec("su -c pkill -f ckxkdkkskkhgkkdkskkv")
    
    Toast.makeText(activity,"ESP OFF 🔴", Toast.LENGTH_SHORT).show()
  end
end
