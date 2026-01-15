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

