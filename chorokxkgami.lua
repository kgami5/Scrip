require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
--import "layout"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.content.Intent"
import "android.content.Context"



layout=
{
  LinearLayout;
  layout_width="fill";
  background="image/bg_bol.png";
  layout_height="fill";
  gravity="center";
  orientation="vertical";
  {
    LinearLayout;
    layout_width="match_parent";
    gravity="center";
    {
      TextView;
      layout_margin="5dp";
      textColor="0xFFFFFFFF";
      text=" CODM ";
      id="t2";
    };
    {
      TextView;
      textColor="0xFFFF0000";
      text=" GARENA ";
      id="t3";
    };
  };
  {
    CardView;
    layout_width="match_parent";
    backgroundColor="0xFF212121";
    radius="10dp";
    layout_marginRight="40dp";
    layout_marginLeft="40dp";
    {
      LinearLayout;
      layout_width="match_parent";
      layout_height="match_parent";
      gravity="center";
      orientation="vertical";
      {
        TextView;
        layout_margin="10dp";
        textColor="0xFFFFFFFF";
        text="LOGIN TO CONTINUE";
        id="t1";
      };
      {
        CardView;
        layout_width="70dp";
        layout_height="5dp";
        layout_margin="10dp";
        backgroundColor="0xFFFF0000";
      };
      {
        EditText;
        hintTextColor="0xFFFFFFFF";
        textColor="0xFFFFFFFF";
        layout_width="match_parent";
        background="none";
        layout_height="match_parent";
        id="pass";

        hint="Key 🔑";
        layout_margin="30dp";
      };
    };
  };
  {
    LinearLayout;
    layout_marginTop="20dp";
    {
      Button;
      layout_margin="10dp";
      id="getkey";
      textColor="0xFFFFFFFF";
      text="Get Key";
    };
    {
      Button;
      textColor="0xFFFFFFFF";
      text="Login";
      layout_margin="10dp";
      id="loginkey";
    };
  };
};


require "import"
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
--import "AndLua"
import "http"
import "com.androlua.LuaThread"
--import "android.view.View"
import "android.content.Context"
import "android.content.Intent"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.graphics.Typeface"
import "android.widget.FrameLayout"
--import "android.media.AudioManager"
import 'android.net.Uri'
import 'android.widget.MediaController'
import 'android.media.MediaPlayer'
import "android.graphics.Paint"
import "android.graphics.Typeface"



require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
--import "layout"

activity.setTheme(R.AndLua1)
activity.setTitle("@KGAMI5")
activity.setContentView(loadlayout(layout))
activity.overridePendingTransition(android.R.anim.fade_in,android.R.anim.fade_out);
if Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setNavigationBarColor(0xFF000000);
end
--if Build.VERSION.SDK_INT >= Build.VERSION_CODES.M then
--activity.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
--end
--activity.ActionBar.hide()
function CircleButton0(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(4, InsideColor1)
  view.setBackgroundDrawable(drawable)
end
import "android.graphics.Typeface"
--id.setTypeface(Typeface.createFromFile(activity.getLuaDir("FONT/Blogger_Sans.otf")))
t2.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
t3.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
t1.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
pass.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
loginkey.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
getkey.setTypeface(Typeface.createFromFile(activity.getLuaDir("font/title.ttf")))
CircleButton0(pass,0x8A212121,10,0xFFFFFFFF)
CircleButton0(getkey,0xFF212121,10,0xFF212121)
CircleButton0(loginkey,0xFFFF0000,10,0xFFFF0000)

function loginkey.onClick()
  key="@KGAMI5"---add your key here
  key1="chorokxkgami"
  key3="TEST"
  if pass.Text==key or pass.Text==key1 or pass.Text==key3 then
    activity.newActivity("server")--add your activity
    activity.finish()--activity finish
   else
    print("pass wrong")
  end
end
function getkey.onClick()

  url = "https://t.me/KGAMI5"
  activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
end


