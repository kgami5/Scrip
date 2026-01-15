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
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.ColorDrawable"

-- ===========================
-- CONFIGURATION UI PRINCIPALE
-- ===========================
activity.setTitle("")
activity.setTheme(R.AndLua1)
activity.setContentView(loadlayout(layout))

if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))

-- Fonction Animation Texte
Update_UI=function(str)
  if t1 then t1.Text=str end
end

Start=function(str)
  require"import"
  function slg(str) return(utf8.len(str)) end
  function sgg(s,i,j)
    i,j=tonumber(i),tonumber(j)
    i=utf8.offset(s,i)
    j=((j or -1)==-1 and -1) or utf8.offset(s,j-1)+1
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

thread(Start," 01010 connected ... Hello There its me @KGAMI5 from boost3000.fr")

-- ===========================
-- DÉFINITION MENU FLOTTANT (C'était l'erreur "must be a table")
-- ===========================
amsmlay = {
  LinearLayout,
  orientation="vertical",
  layout_width="wrap_content",
  layout_height="wrap_content",
  id="mLinearLayout1",
  {
    TextView,
    id="Cross",
    text="☠️", -- Icône du bouton
    textSize="25sp",
    textColor="#FFFFFF",
    gravity="center",
    layout_width="60dp",
    layout_height="60dp",
  }
}

-- ===========================
-- GESTION FENÊTRE FLOTTANTE
-- ===========================
do
  amsm7abdo=activity.getSystemService(Context.WINDOW_SERVICE)
  amsmParam =WindowManager.LayoutParams()
  amsmParam.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
  amsmParam.format =PixelFormat.RGBA_8888
  amsmParam.flags=WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  amsmParam.gravity = Gravity.CENTER
  amsmParam.width =WindowManager.LayoutParams.WRAP_CONTENT
  amsmParam.height =WindowManager.LayoutParams.WRAP_CONTENT
  
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    print("Permission requise")
    intent=Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    activity.startActivityForResult(intent, 100)
  else
    amsm7min=loadlayout(amsmlay) -- Maintenant amsmlay existe, ça ne plantera plus
  end
end

-- Styles Graphiques
function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(9, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

-- Appliquer les styles
if mLinearLayout1 then CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF) end
if Cross then CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF) end

-- ===========================
-- SYSTÈME EXPIRATION
-- ===========================
Date = "20260120"
date = os.date("%Y%m%d")
if date >= Date then
  dialog=AlertDialog.Builder(this)
  .setTitle("⚠️ EXPIRED ⚠️")
  .setCancelable(false)
  .setMessage("UPDATE IS REQUIRED")
  .setPositiveButton("EXIT",{onClick=function(v) os.exit() end})
  .show()
  return
end

-- ===========================
-- FONCTION D'INJECTION (CORRIGÉE POUR VM)
-- ===========================
function AMSMEF(fileName)
  local path = activity.getLuaDir(fileName)
  
  -- 1. Vérification fichier
  local f = io.open(path, "r")
  if f == nil then
    Toast.makeText(activity, "❌ Fichier introuvable: "..fileName, Toast.LENGTH_LONG).show()
    return
  else
    f:close()
  end

  -- 2. Permissions (On force tout)
  os.execute("chmod 777 '" .. path .. "'")
  os.execute("su -c chmod 777 '" .. path .. "'")

  -- 3. Exécution FORCÉE (Spécial Virtual Space)
  -- On utilise nohup pour ne pas figer l'app
  -- On utilise su -c directement car les VM ne répondent pas toujours à RootUtil
  local cmd = "su -c 'nohup \"" .. path .. "\" > /dev/null 2>&1 &'"
  
  Runtime.getRuntime().exec(cmd)
  
  Toast.makeText(activity, "💉 Injection envoyée (Mode Force)", Toast.LENGTH_SHORT).show()
end

-- ===========================
-- BOUTON CLICK
-- ===========================
amsm7A=false
function Cross.onClick()
  if (amsm7A==false) then
    -- ACTIVE
    amsm7abdo.addView(amsm7min,amsmParam)
    CircleButtonA(Cross,0xFF009F00,200,0xFFFFFFFF) -- Vert
    amsm7A=true
    
    -- Lancer l'injecteur
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv")

   else
    -- DÉSACTIVE
    amsm7abdo.removeView(amsm7min)
    CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF) -- Rouge
    amsm7A=false
    
    -- Tuer le processus
    Runtime.getRuntime().exec("su -c pkill -f ckxkdkkskkhgkkdkskkv")
    
    Toast.makeText(activity,"ESP 🔴", Toast.LENGTH_SHORT).show()
  end
end
