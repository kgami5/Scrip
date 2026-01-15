
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
activity.setTitle("")
activity.setTheme(R.AndLua1)
activity.setContentView(loadlayout(layout))

import "android.graphics.drawable.ColorDrawable"
if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))


Update_UI=function(str)
  t1.Text=str
end

Start=function(str)
  require"import"
  function slg(str)
    --print(utf8.len(str))
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

thread(Start," 01010 connected ... Hello There its me @KGAMI5 from boost3000.fr | welcome for tiktok Instagram telegram and more social media go to the website www.boost3000.fr you Can buy followers views likes and more")-- add a space in the beginning








require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "AndLua"
import "http"
import "android.view.View"
import "android.content.Context"
import "android.content.Intent"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.graphics.Typeface"
import "android.widget.FrameLayout"
import 'android.net.Uri'
import "android.graphics.Paint"
import "android.graphics.Typeface"
import "android.graphics.Paint"
import "android.content.Context"
import "android.content.Intent"
import "android.graphics.*"
import "android.content.Context"
import "android.content.Intent"
import "android.content.pm.PackageManager"
import "android.net.Uri"
import "android.provider.Settings"
import "android.graphics.Typeface"
import "layout"
import "min"

activity.setContentView(loadlayout(layout))



import "android.content.Context"

do
amsm7abdo=activity.getSystemService(Context.WINDOW_SERVICE) --获取窗口管理器
HasFocus=false --是否有焦点
amsmParam =WindowManager.LayoutParams() --对象
amsmParam.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY --设置悬浮窗方式
import "android.graphics.PixelFormat" --导入
amsmParam.format =PixelFormat.RGBA_8888
amsmParam.flags=WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
amsmParam.gravity = Gravity.CENTER
amsmParam.x = 0
amsmParam.y = 0
amsmParam.width =WindowManager.LayoutParams.WRAP_CONTENT
amsmParam.height =WindowManager.LayoutParams.WRAP_CONTENT
if Build.VERSION.SDK_INT >= Build.VERSION_CODES.M&&!Settings.canDrawOverlays(this) then
  print("There are no floating window permissions, please open the permissions")
  intent=Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
  activity.startActivityForResult(intent, 100)
  os.exit()
 else
  amsm7min=loadlayout(amsmlay)
end
end

function CircleButton(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(5, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(9, InsideColor1)
  view.setBackgroundDrawable(drawable)
end
CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF)
CircleButtonA(mLinearLayout2,0xFFFF0000,100,0xFFFFFFFF)
CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF)








Date = "20260120"
date = os.date("%Y%m%d")
if date >= Date then
  dialog=AlertDialog.Builder(this)
  .setTitle("⚠️𝐈𝐍𝐉𝐄𝐂𝐓𝐎𝐑 𝐄𝐗𝐏𝐈𝐑𝐄𝐃⚠️")
  .setCancelable(false)
  .setMessage("UPDATE IS REQUIRED \n Telegram: @KGAMI5\n chat me if need update\n Wait for it....!!!")
  .setPositiveButton("EXIT",{onClick=function(v)
      os.exit()
    end})
  .setNeutralButton("CONTACT",{onClick = function(v)
      url = "https://t.me/KGAMI5"
      activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
      os.exit()
    end})
  .show()


  import "android.text.SpannableString"
  import "android.text.style.ForegroundColorSpan"
  import "android.text.Spannable"
  texttitle = SpannableString("⚠️𝐈𝐍𝐉𝐄𝐂𝐓𝐎𝐑 𝐄𝐗𝐏𝐈𝐑𝐄𝐃⚠️")
  texttitle.setSpan(ForegroundColorSpan(0xFFFF0000),0,#texttitle,Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
  dialog.setTitle(texttitle)
  return
end




--[[function YX(file)
  if os.execute("su") then
    path=activity.getLuaDir(file)
    os.execute("su -c chmod 777 "..path)
    Runtime.getRuntime().exec(""..path)
   else
    path=activity.getLuaDir(file)
    os.execute("chmod 777 "..path)
    Runtime.getRuntime().exec(""..path)
  end
end]]--


import "com.androlua.util.RootUtil"

-- Fonction robuste pour lancer le binaire C4droid
function AMSMEF(fileName)
  local path = activity.getLuaDir(fileName)
  
  -- 1. Vérification du fichier
  local f = io.open(path, "r")
  if f == nil then
    Toast.makeText(activity, "❌ Fichier binaire introuvable !", Toast.LENGTH_LONG).show()
    return
  else
    f:close()
  end

  -- 2. On donne les permissions (On essaie les deux méthodes : normal et root)
  os.execute("chmod 777 '" .. path .. "'")
  os.execute("su -c chmod 777 '" .. path .. "'")

  -- 3. Exécution FORCÉE (On ignore RootUtil)
  -- On lance la commande via "su -c" directement.
  -- Si l'espace virtuel a le root activé, ça passera.
  local cmd = "su -c 'nohup \"" .. path .. "\" > /dev/null 2>&1 &'"
  
  -- On tente aussi une exécution normale au cas où le binaire n'aurait pas besoin de su pour se lancer (rare pour un injecteur, mais possible pour tester)
  -- Mais pour /proc/mem, le 'su' est obligatoire.
  
  try
    Runtime.getRuntime().exec(cmd)
    Toast.makeText(activity, "💉 Injection lancée (Mode Force)", Toast.LENGTH_SHORT).show()
    print("Commande envoyée : " .. cmd)
  catch(e)
    Toast.makeText(activity, "Erreur d'exécution : " .. e, Toast.LENGTH_LONG).show()
  end
end
    

-- Ton bouton Cross optimisé
amsm7A = false
function Cross.onClick()
  if (amsm7A == false) then
    -- ON : Afficher le menu et lancer l'injecteur
    amsm7abdo.addView(amsm7min, amsmParam)
    CircleButtonA(Cross, 0xFF009F00, 200, 0xFFFFFFFF) -- Vert
    amsm7A = true
    
    -- Lancer le binaire qui est dans le dossier KGAMI5
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv") 

  else
    -- OFF : Cacher le menu et Tuer l'injecteur
    amsm7abdo.removeView(amsm7min)
    CircleButtonA(Cross, 0xFFBD0000, 200, 0xFFFFFFFF) -- Rouge
    amsm7A = false
    
    -- Optionnel : Tuer le processus pour arrêter le hack proprement
    if RootUtil.haveRoot() then
       -- On tue le processus par son nom
       Runtime.getRuntime().exec("su -c pkill -f ckxkdkkskkhgkkdkskkv")
    end
    
    Toast.makeText(activity, "Arrêt... 🛑", Toast.LENGTH_SHORT).show()
  end
end






