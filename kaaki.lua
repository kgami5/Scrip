require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "com.androlua.LuaDrawable"
import "android.graphics.drawable.ColorDrawable"


activity.setTheme(R.AndLua10)
activity.ActionBar.setTitle("PIN")
activity.ActionBar.hide()
activity.overridePendingTransition(android.R.anim.fade_in,android.R.anim.fade_out)
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF131416);
activity.setRequestedOrientation(1)

layout={
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  layout_height="fill",
  backgroundColor="0xFF131416";
  gravity="center",
  {
    LinearLayout,
    layout_width="fill",
    layout_height="20%h",
    gravity="center";
    orientation="vertical",
    {
      ImageView;
      layout_height="70dp";
      id="";
      layout_width="70dp";
      padding="5dp";
      layout_gravity="center";
      src="icon/lock.png";
      colorFilter="0xFFFFFFFF";
    };
    {
      TextView,
      text="Enter PIN To Continue",
      textSize="25sp",
      layout_width="fill",
      layout_height="wrap",
      textColor="0xFFFFFFFF",
      gravity="center";
      padding="10dp";
    },
  };

  {
    LinearLayout,
    layout_weight=0;
    layout_width="fill",
    layout_height="20%h",
    gravity="center";
    backgroundColor="0x00000000";
    layout_marginTop="10%h";
    id="pinX";
    {
      TextView,
      textSize="50sp",
      layout_width="15%w",
      layout_height="fill",
      gravity="center";
      textColor="0xFFFFFFFF",
      id="a",
    },
    {
      TextView,
      textSize="50sp",
      layout_width="15%w",
      layout_height="fill",
      gravity="center",
      textColor="0xFFFFFFFF",
      id="b",
    },
    {
      TextView,
      textSize="50sp",
      layout_width="15%w",
      layout_height="fill",
      gravity="center",
      textColor="0xFFFFFFFF",
      id="c",
    },
    {
      TextView,
      textSize="50sp",
      layout_width="15%w",
      layout_height="fill",
      gravity="center",
      textColor="0xFFFFFFFF",
      id="d",
    },
  },
  {
    LinearLayout,
    layout_weight=1;
    layout_width="fill",
    layout_height="fill",
    gravity="center";
    backgroundColor="0x00000000";
    {
      GridView,
      layout_width="fill",
      layout_height="fill",
      numColumns=3,
      id="mGridView",
    },
  }
}


activity.setContentView(loadlayout(layout))






mActivityWidth = activity.width
mActivityHight = activity.height



item=
{
  TextView,
  layout_width=mActivityWidth/3,
  layout_height="10%h",
  Gravity="center",
  id="btn",
  textColor="0xFFFFFFFF";
  textSize="20sp";
}



keyboard_nums = {
  "J","2","3",
  "4","G","I",
  "A","8","9",
  "Back","U","Delete",
}
adp=LuaAdapter(activity,item)
mGridView.setAdapter(adp)

for k,v in pairs(keyboard_nums) do
  adp.add{btn=v}
end




function judge_verification_code(num)
  verification_code_1 = a.Text
  verification_code_2 = b.Text
  verification_code_3 = c.Text
  verification_code_4 = d.Text
verification_code_5 = e.Text
  if verification_code_1 == "" then
    a.Text = num
    return true
  end
  if verification_code_2 == "" then
    b.Text = num
    return true
  end
  if verification_code_3 == "" then
    c.Text = num
    return true
  end
  if verification_code_4 == "" then
    d.Text = num
    return true
  end
  if verification_code_5 == "" then
    e.Text = num
    return true
  end
end



function delete_verification_code()
  verification_code_1 = a.Text
  verification_code_2 = b.Text
  verification_code_3 = c.Text
  verification_code_4 = d.Text
verification_code_5 = e.Text
  if verification_code_5 ~= "" then
    e.Text = ""
    return true
  end
  if verification_code_4 ~= "" then
    d.Text = ""
    return true
  end
  if verification_code_3 ~= "" then
    c.Text = ""
    return true
  end
  if verification_code_2 ~= "" then
    b.Text = ""
    return true
  end
  if verification_code_1 ~= "" then
    a.Text = ""
    return true
  end
end

function ann()
  import "com.daimajia.androidanimations.library.Techniques"
  import "com.daimajia.androidanimations.library.YoYo"

  YoYo.with(Techniques.Shake)
  .duration(500)
  .playOn(pinX)
end



function set_input_status()
  verification_code_1 = a.Text
  verification_code_2 = b.Text
  verification_code_3 = c.Text
  verification_code_4 = d.Text
  verification_code_5 = e.Text
  if verification_code_1 == "" then
    a.background=ordinary_status_dra
    b.background=ordinary_status_dra
    c.background=ordinary_status_dra
    d.background=ordinary_status_dra
    e.background=ordinary_status_dra
    
    return true
  end
  if verification_code_2 == "" then
    a.background=nil
    b.background=input_status_dra
    c.background=ordinary_status_dra
    d.background=ordinary_status_dra
    e.background=ordinary_status_dra
    return true
  end
  if verification_code_3 == "" then
    a.background=nil
    b.background=nil
    c.background=input_status_dra
    d.background=ordinary_status_dra
    e.background=ordinary_status_dra
    return true
  end
  if verification_code_4 == "" then
    a.background=nil
    b.background=nil
    c.background=nil
    d.background=input_status_dra
    e.background=ordinary_status_dra
    return true
  end
if verification_code_5 == "" then
    a.background=nil
    b.background=nil
    c.background=nil
    d.background=nil
    e.background=ordinary_status_dra
    return true
  end
  a.background=nil
  b.background=nil
  c.background=nil
  d.background=nil
  e.background=nil
end



input_status_dra=LuaDrawable(function(mCanvas,mPaint,mDrawable)
  mPaint1 = Paint();
  mPaint1.setStrokeWidth(5)
  mPaint1.setAntiAlias(true)
  mPaint1.setStyle(Paint.Style.FILL)
  mPaint1.setColor(0xFFFFFFFF)
  local w = mDrawable.getBounds().right
  local h = mDrawable.getBounds().bottom
  mCanvas.drawCircle(w/2, h/2 , w/7,mPaint1)
end)




ordinary_status_dra=LuaDrawable(function(mCanvas,mPaint,mDrawable)
  mPaint1 = Paint();
  mPaint1.setStrokeWidth(5)
  mPaint1.setAntiAlias(true)
  mPaint1.setStyle(Paint.Style.STROKE)
  mPaint1.setColor(0x60FFFFFF)
  local w = mDrawable.getBounds().right
  local h = mDrawable.getBounds().bottom
  mCanvas.drawCircle(w/2, h/2 , w/8,mPaint1)
end)





function clearall()
  e.Text = ""
  d.Text = ""
  c.Text = ""
  b.Text = ""
  a.Text = ""
  set_input_status()
  ann()
end

set_input_status()

d.addTextChangedListener{
  onTextChanged=function(s)
    if e.Text == "U" && d.Text == "G" && c.Text == "A" && b.Text == "I" && a.Text == "J" then
      print("LOGGING IN")

      activity.newActivity("SERVER")--add your activity
      activity.finish()--activity finish


      --[[
     elseif d.Text != "" then
      for k in pairs(keyboard_nums) do
        keyboard_nums[k] = nilnil

      endend]]--
      -- clearall()
      import "android.content.Context"
      vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE)
      vibrator.vibrate( long{10,50} ,-1)

    end
  end}


mGridView.onItemClick=function(l,v,p,i)
  local keyboard_num = v.Text
  if keyboard_num == "Delete" then
    delete_verification_code()
    set_input_status()
   elseif keyboard_num == "Back" then
    activity.finish()
   else
    judge_verification_code(v.Text)
    set_input_status()
  end
  return true
end
