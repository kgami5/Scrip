
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

function AMSMEF(A0_24)
  if RootUtil.haveRoot() == true then
    kmn = activity.getLuaDir(A0_24)
    os.execute("su -c chmod 777 " .. kmn)
    Runtime.getRuntime().exec("su -c " .. kmn)
   else
    kmn = activity.getLuaDir(A0_24)
    os.execute("chmod 777 " .. kmn)
    Runtime.getRuntime().exec(" " .. kmn)
  end
end

--chmod 0760 "dir"777



function exec(cmd)
  local p=io.popen(string.format('%s',cmd))
  local s=p:read("*a")
  p:close()
  return s
end








amsm7A=false
function Cross.onClick()
  if (amsm7A==false) then
    amsm7abdo.addView(amsm7min,amsmParam)
    CircleButtonA(Cross,0xFF009F00,200,0xFFFFFFFF)
    amsm7A=true
    -- AMSMEF("KGAMI5/jfkzogljdkdlcjdkdlcjdjshkkckkx","🔰  ON 🔰")
    -- AMSMEF("KGAMI5/jgkdlflgjdklslfkcksksllfkc","🔰  ONunlocker 🔰")
    -- AMSMEF("KGAMI5/jgkdlflgjdklslfkcksksllfkc","🔰  anticheatanticheat unlocker 🔰")
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv","🔰  ON 🔰")
    -- AMSMEF("KGAMI5/jxkxkwkxlvlxlllwlclcllwlwllc","🔰  ON 🔰")
    --   AMSMEF("KGAMI5/udjgjfkdkkvkgkdkckvkdkk","🔰  Xa 🔰")
    -- AMSMEF("KGAMI5/kgoosoogollzlllgllldldldl","🔰  ON 🔰")
    --AMSMEF("KGAMI5/kgldofjdkdkgkdklskfk","🔰  ON 🔰")
    -- AMSMEF("KGAMI5/ugkdllglgkldllcldlwl","🔰  ON 🔰")

   elseif 
    amsm7abdo.removeView(amsm7min)
    CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF)
    amsm7A=false
    toast = Toast.makeText(activity,"ESP🟢", Toast.LENGTH_LONG)

  end
end







