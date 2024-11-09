require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.graphics.Typeface"
import "android.graphics.Paint"
import "android.net.*"
import "android.provider.Settings"
import "android.content.Context"
import "android.view.animation.*"
import "AndLua"
import "http"
--import "layout"

activity.setTheme(R.AndLua1)
--activity.setContentView(loadlayout(layout))
activity.actionBar.hide()
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);






layout2={
  LinearLayout;
  layout_height="wrap";
  layout_width="wrap";
  {
    CardView;
    layout_height = "wrap";
    layout_width = "wrap";
    backgroundColor="0xffD1D1D1";--"#22000000";
    id="menu"; -- 				Layout max
    {
      LinearLayout;
      layout_height = "wrap";
      layout_width = "wrap";
      Orientation="vertical";
      {
        LinearLayout;
        orientation="horizontal";
        id="win_mainview1",
        layout_height="27dp";
        layout_width="93%w";
        background="transparent",
        {

          ImageView;
          id="img1";
          layout_width="45";
          layout_height="65";
          layout_marginLeft="7dp";
          layout_gravity="left|center";
          padding="3";
          src="ic_to_top.png";
          colorFilter="0xFF000000";
        };
        {
          TextView;
          textColor="0xFF000000";
          textSize="13.5dp";
          layout_marginLeft="10dp";
          text="Chorok X KGAMI";
          layout_gravity="center";
          gravity="center";
          id="win_move";
        };
      };


      {
        LinearLayout;
        Orientation="vertical";
        layout_height = "220dp";
        layout_width = "93%w";
        visibility="gone";
        backgroundColor="0xFFF1F1F1";
        id="cheatMenu";
        {
          LinearLayout;
          id="";
          Orientation="vertical";
          layout_height = "fill";
          layout_width = "fill";
          layout_gravity="center";
          padding="5dp";
          {
            HorizontalScrollView;
            layout_width="320dp";
            layout_height="38dp",
            layout_gravity="center";
            id="QQ";

            {
              LinearLayout;
              layout_height="-1";
              layout_width="-1";
              orientation="horizontal";
              background="transparent";
              {
                TextView;
                text="Basic";
                id="menu1",
                layout_gravity="center";
                gravity="center";
                textSize="13dp";
                textColor="0xFF000000";
                layout_height="3.4%h";
                layout_width="14%w";
              };
              {
                LinearLayout;
                layout_height=".5%h";
                layout_width="2%w";
                background="transparent",
              };
              {
                TextView;
                text="Esp";
                id="menu2",
                textSize="13dp";
                layout_gravity="center";
                gravity="center";
                textColor="0xFF000000";
                background="#ff252525";
                layout_height="3.4%h";
                layout_width="20%w";
              };
              {
                LinearLayout;
                layout_height=".5%h";
                layout_width="2%w";
                background="transparent",
              };
              {
                TextView;
                text="Aim";
                id="menu3",
                textSize="13dp";
                layout_gravity="center";
                gravity="center";
                textColor="0xFF000000";
                background="#ff252525";
                layout_height="3.4%h";
                layout_width="13%w";
              };
            };
          };

          {
            LinearLayout,
            layout_height = "1.5dp",
            layout_width = "fill",
            backgroundColor = "0xFFC5C9E4",
            layout_marginTop="-6.5dp";
            layout_marginLeft = "9dp",
            layout_marginRight = "9dp",
          },
          {
            LinearLayout;
            layout_height="0.5%h";
            layout_width="fill";
          };
          {
            PageView,
            id="pg",
            layout_width="fill",
            layout_height="fill",
            pages={
              {
                LinearLayout;
                orientation="vertical";
                padding="5";
                {
                  ScrollView;
                  layout_width="fill_parent";
                  layout_height="fill",
                  layout_gravity="center_horizontal";
                  {
                    LinearLayout;
                    layout_height="-1";
                    layout_width="-1";
                    orientation="vertical";
                    {
                      LinearLayout;
                      id="_drawer_header";
                      layout_height="-2";
                      layout_width="-1";
                      orientation="vertical";
                      {
                        LinearLayout;
                        layout_height="-1";
                        layout_width="-1";
                        orientation="vertical";
                        padding="0";
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="10";
                          layout_width="-1";
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="7.5%w";
                          layout_width="fill";
                          layout_gravity="center";
                          id="basic";
                          {
                            ImageView;
                            id="img2";
                            layout_width="45";
                            layout_height="65";
                            layout_marginLeft="7dp";
                            layout_gravity="left|center";
                            padding="3";
                            src="ic_to_top.png";
                            colorFilter="0xFF000000";
                          };
                          {
                            TextView;
                            textColor="0xFF000000";
                            textSize="13.5dp";
                            layout_marginLeft="10dp";
                            text="Anticheat Basic              Active";
                            gravity="center";
                            layout_gravity="center";
                            id="";

                          };
                        };
                        {
                          LinearLayout;
                          layout_marginTop="7dp";
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Bypass";
                            textColor="0xFF000000";
                            id="sawed1";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          --[[ {
                            CheckBox;
                            text="Bone";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Line";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Info";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Resource";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Box";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Car";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="LV-3";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Med";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Energy";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          layout_height="0.5%h";
                          layout_width="fill";
                        };
                        {
                          LinearLayout,
                          layout_height = "1dp",
                          layout_width = "fill",
                          backgroundColor = "0xFF000000",
                        },
                        {
                          LinearLayout;
                          layout_height="0.5%h";
                          layout_width="fill";
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="I'm not Hacker";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="HandCam";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {

                          LinearLayout;
                          orientation="horizontal";
                          layout_marginTop="8dp";
                          layout_height="7.5%w";
                          layout_width="fill";
                          layout_gravity="center";
                          id="aimbot";
                          {
                            ImageView;
                            id="img3";
                            layout_width="45";
                            layout_height="65";
                            layout_marginLeft="7dp";
                            layout_gravity="left|center";
                            padding="3";
                            src="ic_to_top.png";
                            colorFilter="0xFF000000";
                          };
                          {
                            TextView;
                            textColor="0xFF000000";
                            textSize="13.5dp";
                            layout_marginLeft="10dp";
                            text="Aimbot Setting";
                            gravity="center";
                            layout_gravity="center";
                            id="";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Streaming";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Bullet Track";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Aimbot";
                            textColor="0xFF000000";
                            id="vz61";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="No Recoil";
                            textColor="0xFF000000";
                            id="p92";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";
                          layout_marginTop="7dp";

                          {
                            TextView;
                            text="Set Fire Button";
                            id="fire",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="26%w";
                          };
                          {
                            LinearLayout;
                            layout_height=".5%h";
                            layout_width="2%w";
                            background="transparent",
                          };
                          {
                            TextView;
                            text="Save Setting";
                            id="save",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="20%w";

                          };]]--
                        };
                      };
                    };
                  };
                };
              };
              {
                LinearLayout;
                orientation="vertical";
                padding="5";
                {
                  ScrollView;
                  layout_width="fill_parent";
                  layout_height="fill",
                  layout_gravity="center_horizontal";
                  {
                    LinearLayout;
                    layout_height="-1";
                    layout_width="-1";
                    orientation="vertical";
                    {
                      LinearLayout;
                      id="_drawer_header";
                      layout_height="-2";
                      layout_width="-1";
                      orientation="vertical";
                      {
                        LinearLayout;
                        layout_height="-1";
                        layout_width="-1";
                        orientation="vertical";
                        padding="0";
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="10";
                          layout_width="-1";
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Wallhack";
                            textColor="0xFF000000";
                            id="sawed2";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          --[[  {
                            CheckBox;
                            text="Show Rader";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_marginTop="8dp";
                          layout_height="7.5%w";
                          layout_width="fill";
                          layout_gravity="center";
                          id="sniper";
                          {
                            ImageView;
                            id="img4";
                            layout_width="45";
                            layout_height="65";
                            layout_marginLeft="7dp";
                            layout_gravity="left|center";
                            padding="3";
                            src="ic_to_top.png";
                            colorFilter="0xFF000000";
                          };
                          {
                            TextView;
                            textColor="0xFF000000";
                            textSize="13.5dp";
                            layout_marginLeft="10dp";
                            text="Sniper";
                            gravity="center";
                            layout_gravity="center";
                            id="";
                          };
                        };
                        {

                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Mosin";
                            textColor="0xFF000000";
                            id="sawed";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="M24";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Kar98K";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Mini14";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Win94";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_marginTop="8dp";
                          layout_height="7.5%w";
                          layout_width="fill";
                          layout_gravity="center";
                          id="attachments";
                          {
                            ImageView;
                            id="img5";
                            layout_width="45";
                            layout_height="65";
                            layout_marginLeft="7dp";
                            layout_gravity="left|center";
                            padding="3";
                            src="ic_to_top.png";
                            colorFilter="0xFF000000";
                          };
                          {
                            TextView;
                            textColor="0xFF000000";
                            textSize="13.5dp";
                            layout_marginLeft="10dp";
                            text="Attachments";
                            gravity="center";
                            layout_gravity="center";
                            id="";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="3X";
                            textColor="0xFF000000";
                            id="sawed";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="4X";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="6X";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="8X";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Red Dot";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Mag";
                            textColor="0xFF000000";
                            id="sawed";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Silencer";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                          {
                            CheckBox;
                            text="Grenade";
                            textColor="0xFF000000";
                            id="r1895";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";
                          layout_marginTop="7dp";

                          {
                            TextView;
                            text="Save Setting";
                            id="savee",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="20%w";
                          };
                        };
                        {
                          LinearLayout;
                          layout_height="0.8%h";
                          layout_width="fill";
                        };
                        {
                          LinearLayout,
                          layout_height = "1dp",
                          layout_width = "fill",
                          backgroundColor = "0xFF000000",
                        },
                        {
                          LinearLayout;
                          layout_height="0.8%h";
                          layout_width="fill";
                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            TextView;
                            text="Logout Account";
                            id="log",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="26%w";
                          };
                          {
                            LinearLayout;
                            layout_height=".5%h";
                            layout_width="2%w";
                            background="transparent",
                          };
                          {
                            TextView;
                            text="Restore PUBGM";
                            id="res",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="26%w";
                          };
                          {
                            LinearLayout;
                            layout_height=".5%h";
                            layout_width="2%w";
                            background="transparent",
                          };
                          {
                            TextView;
                            text="Fix Device Ban";
                            id="fix",
                            textSize="13.5dp";
                            layout_gravity="center";
                            gravity="center";
                            textColor="0xFF000000";
                            layout_height="3.4%h";
                            layout_width="26%w";
                          };]]--
                        };
                      };
                    };
                  };
                };
              };
              {
                LinearLayout;
                orientation="vertical";
                padding="5";
                {
                  ScrollView;
                  layout_width="fill_parent";
                  layout_height="fill",
                  layout_gravity="center_horizontal";
                  {
                    LinearLayout;
                    layout_height="-1";
                    layout_width="-1";
                    orientation="vertical";
                    {
                      LinearLayout;
                      id="_drawer_header";
                      layout_height="-2";
                      layout_width="-1";
                      orientation="vertical";
                      {
                        LinearLayout;
                        layout_height="-1";
                        layout_width="-1";
                        orientation="vertical";
                        padding="0";
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="10";
                          layout_width="-1";
                        };
                        {
                          TextView;
                          text="Assist";
                          id="delet";
                          layout_gravity="center";
                          gravity="center";
                          textColor="0xFF000000";
                          layout_width="85%w";




                        };
                        {
                          LinearLayout;
                          orientation="horizontal";
                          layout_height="wrap";
                          layout_width="wrap";

                          {
                            CheckBox;
                            text="Aimbot";
                            textColor="0xFF000000";
                            id="sawed3";
                            layout_gravity="center";
                            textSize="13.5sp";
                            layout_width="fill";
                            layout_height="wrap";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
};





minlay2={
  LinearLayout;
  layout_width="20dp";
  layout_height="30dp";
  id="jumpmenu";
  {
    ImageView;
    layout_width="50dp";
    src="a.png";
    id="Win_minWindow11";
    layout_height="50dp";
  };
};
-------PARAMETER----------



LayoutVIP1=activity.getSystemService(Context.WINDOW_SERVICE)
HasFocus=false
WmHz1=WindowManager.LayoutParams()
if Build.VERSION.SDK_INT >= 26 then WmHz1.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
 else WmHz1.type =WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
end
import "android.graphics.PixelFormat"
WmHz1.format =PixelFormat.RGBA_8888
WmHz1.flags=WindowManager.LayoutParams().FLAG_NOT_FOCUSABLE
WmHz1.gravity = Gravity.LEFT| Gravity.TOP
WmHz1.x = 0
WmHz1.y = 0
WmHz1.width = WindowManager.LayoutParams.WRAP_CONTENT
WmHz1.height = WindowManager.LayoutParams.WRAP_CONTENT
mainWindow1 = loadlayout(layout2)
isMax1=true

function menu.OnTouchListener(v,event)
  if event.getAction()==MotionEvent.ACTION_DOWN then
    firstX=event.getRawX()
    firstY=event.getRawY()
    wmX=WmHz1.x
    wmY=WmHz1.y
   elseif event.getAction()==MotionEvent.ACTION_MOVE then
    WmHz1.x=wmX+(event.getRawX()-firstX)
    WmHz1.y=wmY+(event.getRawY()-firstY)
    LayoutVIP1.updateViewLayout(mainWindow1,WmHz1)
   elseif event.getAction()==MotionEvent.ACTION_UP then
  end return true
end
function win_move.OnTouchListener(v,event)
  if event.getAction()==MotionEvent.ACTION_DOWN then
    firstX=event.getRawX()
    firstY=event.getRawY()
    wmX=WmHz1.x
    wmY=WmHz1.y
   elseif event.getAction()==MotionEvent.ACTION_MOVE then
    WmHz1.x=wmX+(event.getRawX()-firstX)
    WmHz1.y=wmY+(event.getRawY()-firstY)
    LayoutVIP1.updateViewLayout(mainWindow1,WmHz1)
   elseif event.getAction()==MotionEvent.ACTION_UP then
  end return true
end


function Waterdropanimation(Controls,time)
  import "android.animation.ObjectAnimator"
  ObjectAnimator().ofFloat(Controls,"scaleX",{1,.8,1.3,.9,1}).setDuration(time).start()
  ObjectAnimator().ofFloat(Controls,"scaleY",{1,.8,1.3,.9,1}).setDuration(time).start()
end





function CircleButton(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(2, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

function CircleButton3(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radii, radii, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(5, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, 0, 0, 0, 0})
  drawable.setColor(InsideColor)
  drawable.setStroke(5, InsideColor1)
  view.setBackgroundDrawable(drawable)
end



function CircleButton1(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radii, radii, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(4, InsideColor1)
  view.setBackgroundDrawable(drawable)
end


function CircleButton2(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({20, 20, 20, 20, 0, 20, 0, 20})
  drawable.setColor(InsideColor)
  drawable.setStroke(2, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

function CircleButtonY(view,InsideColor,radiu,InsideColor1)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, 0, 0, 0, 0})
  drawable.setColor(InsideColor)
  drawable.setStroke(5, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

CircleButton(start,0xFF0068FF,30,0xFF0068FF)

CircleButton(delet,0xffFA8482,20,0xffFA8482)

function start.OnCheckedChangeListener()
  CircleButton(start,0xFF0068FF,30,0xFF0068FF)
  if start.checked then
    CircleButton(start,0xFFFF0000,30,0xFFFF0000)
    HasLaunch=false
    if HasLaunch==true then return else
      if Settings.canDrawOverlays(activity) then else intent=Intent("android.settings.action.MANAGE_OVERLAY_PERMISSION");
        intent.setData(Uri.parse("package:" .. this.getPackageName())); this.startActivity(intent); end HasLaunch=true
      local ret={pcall(function() LayoutVIP1.addView(mainWindow1,WmHz1) end)}
      if ret[1]==false then end end import "java.io.*" file,err=io.open("/data/data/com.acnologia.mod/files/Memory.lua")
   else
    LayoutVIP1.removeView(mainWindow1)
  end
end





import "android.graphics.drawable.BitmapDrawable"



isMax=false
function img1.onClick()
  if isMax==false then
    isMax=true
    img1.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_bottom.png")))
    cheatMenu.setVisibility(View.VISIBLE)
   else
    isMax=false
    img1.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_top.png")))
    cheatMenu.setVisibility(View.GONE)
  end
end

isMax=false
function img2.onClick()
  if isMax==false then
    isMax=true
    img2.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_bottom.png")))
   else
    isMax=false
    img2.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_top.png")))
  end
end
--[[
isMax=false
function img3.onClick()
  if isMax==false then
    isMax=true
    img3.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_bottom.png")))
   else
    isMax=false
    img3.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_top.png")))
  end
end

isMax=false
function img4.onClick()
  if isMax==false then
    isMax=true
    img4.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_bottom.png")))
   else
    isMax=false
    img4.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_top.png")))
  end
end

isMax=false
function img5.onClick()
  if isMax==false then
    isMax=true
    img5.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_bottom.png")))
   else
    isMax=false
    img5.setImageDrawable(BitmapDrawable(loadbitmap("ic_to_top.png")))
  end
endend]]--

CircleButton(basic,0xffBAD5F3,12,0xffBAD5F3)
--[[CircleButton(aimbot,0xffBAD5F3,12,0xffBAD5F3)
CircleButton(save,0xffBAD5F3,0,0xffBAD5F3)
CircleButton(fire,0xffBAD5F3,0,0xffBAD5F3)
CircleButton(attachments,0xffBAD5F3,12,0xffBAD5F3)
CircleButton(sniper,0xffBAD5F3,12,0xffBAD5F3)
CircleButton(savee,0xffBAD5F3,0,0xffBAD5F3)
CircleButton(res,0xffFA8482,0,0xffFA8482)
CircleButton(fix,0xffFA8482,0,0xffFA8482)
CircleButton(log,0xffBAD5F3,0,0xffBAD5F3)
]]--
import "android.graphics.Typeface"
CircleButton2(menu1,0xff96B2E1,20,0xff96B2E1)
pg.showPage(0)
menu1.onClick=function()
  pg.showPage(0)
  CircleButton2(menu1,0xff96B2E1,0,0xff96B2E1)
  CircleButton2(menu2,0xffBFC6D0,0,0xffBFC6D0)
  CircleButton2(menu3,0xffBFC6D0,0,0xffBFC6D0)
end
menu2.onClick=function()
  pg.showPage(1)
  CircleButton2(menu2,0xff96B2E1,0,0xff96B2E1)
  CircleButton2(menu1,0xffBFC6D0,0,0xffBFC6D0)
  CircleButton2(menu3,0xffBFC6D0,0,0xffBFC6D0)
end
menu3.onClick=function()
  pg.showPage(2)
  CircleButton2(menu3,0xff96B2E1,0,0xff96B2E1)
  CircleButton2(menu2,0xffBFC6D0,0,0xffBFC6D0)
  CircleButton2(menu1,0xffBFC6D0,0,0xffBFC6D0)
end
pg.addOnPageChangeListener{
  onPageScrolled=function(a,b,c)
  end,
  onPageSelected=function(page)
    if page==0 then
      CircleButton2(menu1,0xff96B2E1,0,0xff96B2E1)
      CircleButton2(menu2,0xffBFC6D0,0,0xffBFC6D0)
      CircleButton2(menu3,0xffBFC6D0,0,0xffBFC6D0)
      --CircleButton(menu6,0x00000000,20,0x00000000)
    end
    if page==1 then
      CircleButton2(menu2,0xff96B2E1,0,0xff96B2E1)
      CircleButton2(menu1,0xffBFC6D0,0,0xffBFC6D0)
      CircleButton2(menu3,0xffBFC6D0,0,0xffBFC6D0)
      --CircleButton(menu6,0x00000000,20,0x00000000)
    end
    if page==2 then
      CircleButton2(menu3,0xff96B2E1,0,0xff96B2E1)
      CircleButton2(menu2,0xffBFC6D0,0,0xffBFC6D0)
      CircleButton2(menu1,0xffBFC6D0,0,0xffBFC6D0)
      --CircleButton(menu6,0x00000000,20,0xFF474A8D)
    end
  end,
  onPageScrollStateChanged=function(state)
  end,
}


Date = "20241115"
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











sawed1.onClick=function()

  AMSMEF("KGAMI5/jfkfosoljkkslfkflsllflclld","🔰  ON 🔰")





end

sawed2.onClick=function()

  AMSMEF("KGAMI5/jgkfkslgoppspfucjfkllk","🔰  ON 🔰")





end



sawed3.onClick=function()

  AMSMEF("KGAMI5/jflsojgjfkslflflldlglglldl","🔰  ON 🔰")





end
