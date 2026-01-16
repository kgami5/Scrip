require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.PixelFormat"
import "android.graphics.Typeface"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.Color"
import "java.net.NetworkInterface"
import "java.util.Collections"
import "android.content.Context"
import "android.content.Intent" 
-- FORCE IMPORT CLASSES
local Intent = luajava.bindClass("android.content.Intent")
local Settings = luajava.bindClass("android.provider.Settings")
local Uri = luajava.bindClass("android.net.Uri")

-- ================= DESIGN =================
function styleView(view, color, radius, strokeColor, strokeWidth)
  local drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setColor(color)
  drawable.setCornerRadius(radius)
  if strokeColor then drawable.setStroke(strokeWidth or 2, strokeColor) end
  view.setBackground(drawable)
end

activity.setTheme(android.R.style.Theme_Material_NoActionBar)
if Build.VERSION.SDK_INT >= 21 then activity.getWindow().setStatusBarColor(0xFF000000) end

-- ================= INSTALLATION =================
local BIN_SERVER = "KGAMI5/jfkdlkgkgkkdkkvkgk"
local BIN_CRYPT = "KGAMI5/jgkfkdlkgkgklslv"
local PATH_SERVER = activity.getFilesDir().getPath().."/"..BIN_SERVER
local PATH_CRYPT = activity.getFilesDir().getPath().."/"..BIN_CRYPT

function installBinaries()
  local function cp(name, path)
    local src = activity.getLuaDir().."/"..name
    local f = io.open(src, "r")
    if f then
        f:close()
        os.execute("cp "..src.." "..path)
        os.execute("chmod 755 "..path)
    end
  end
  cp(BIN_SERVER, PATH_SERVER)
  cp(BIN_CRYPT, PATH_CRYPT)
end
installBinaries()

function getIP()
  local status, result = pcall(function()
      local interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
      for i = 0, interfaces.size() - 1 do
        local intf = interfaces.get(i)
        local addrs = Collections.list(intf.getInetAddresses())
        for j = 0, addrs.size() - 1 do
          local addr = addrs.get(j)
          if not addr.isLoopbackAddress() and addr.getHostAddress():find(":") == nil then
            return addr.getHostAddress()
          end
        end
      end
      return nil
  end)
  return (status and result) and result or "OFFLINE"
end

-- ================= INTERFACE LANCEUR =================
main_layout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  backgroundColor="#FF000000",
  {
    TextView,
    text="SHIELD V3.0",
    textSize="30sp",
    textColor="#FF00FF00",
    typeface=Typeface.MONOSPACE,
    textStyle="bold",
    layout_marginBottom="50dp"
  },
  {
    Button,
    id="btn_launch",
    text="ACTIVER LE PROTOCOLE",
    textColor="#FF000000",
    textSize="14sp",
    padding="15dp",
    layout_width="220dp"
  }
}

activity.setContentView(loadlayout(main_layout))
styleView(btn_launch, 0xFF00FF00, 10)

-- ================= OVERLAY =================
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local p = WindowManager.LayoutParams()
p.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
p.format = PixelFormat.RGBA_8888
p.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
p.gravity = Gravity.TOP | Gravity.CENTER
p.width = 650
p.height = WindowManager.LayoutParams.WRAP_CONTENT
p.x = 0
p.y = 150

local panel_layout = {
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  id="main_bg",
  padding="2dp",
  {
    LinearLayout, 
    layout_width="fill",
    gravity="center_vertical",
    padding="10dp",
    backgroundColor="#FF111111",
    {
      TextView,
      text="🛡️ SECURE SHELL",
      textColor="#FF00FF00",
      textSize="12sp",
      typeface=Typeface.MONOSPACE,
      layout_weight=1
    },
    {
      TextView,
      text="KILL",
      id="btn_panic",
      textColor="#FFFFFFFF",
      textSize="10sp",
      padding="8dp",
      backgroundColor="#FFFF0000"
    }
  },
  {
    LinearLayout,
    layout_width="fill",
    backgroundColor="#FF000000",
    {
      TextView, text="NET-TRAP", id="tab_server", textColor="#FFFFFFFF", gravity="center", layout_weight=1, padding="10dp", typeface=Typeface.DEFAULT_BOLD
    },
    {
      TextView, text="ENIGMA", id="tab_crypt", textColor="#FF555555", gravity="center", layout_weight=1, padding="10dp", typeface=Typeface.DEFAULT_BOLD
    }
  },
  {
    LinearLayout, 
    orientation="vertical",
    layout_width="fill",
    padding="15dp",
    backgroundColor="#EE000000",
    {
      LinearLayout, id="layout_server", orientation="vertical", layout_width="fill", visibility=View.VISIBLE,
      {
        TextView, text="HONEYPOT STATUS", textColor="#FF888888", textSize="10sp"
      },
      {
         TextView, id="txt_ip", text="INACTIF", textSize="20sp", textColor="#FF555555", gravity="center", layout_marginTop="10dp", layout_marginBottom="20dp", typeface=Typeface.MONOSPACE
      },
      {
        Button, id="btn_server_action", text="ACTIVER LE PIÈGE", textColor="#FF000000", layout_width="fill"
      }
    },
    {
      LinearLayout, id="layout_crypt", orientation="vertical", layout_width="fill", visibility=View.GONE,
      {
        EditText, id="input_text", hint="Données sensibles...", textColor="#FFFFFFFF", hintTextColor="#FF444444", textSize="12sp", layout_width="fill", backgroundColor="#FF1A1A1A", padding="10dp"
      },
      {
        LinearLayout, layout_width="fill", layout_marginTop="10dp",
        { Button, id="btn_enc", text="HEX-LOCK", layout_weight=1, textColor="#FFFFFFFF" },
        { Button, id="btn_dec", text="UNLOCK", layout_weight=1, textColor="#FFFFFFFF" }
      },
      {
         TextView, id="output_text", text="", textSize="12sp", textColor="#FF00FF00", layout_marginTop="15dp", typeface=Typeface.MONOSPACE
      }
    }
  }
}

local panelView = loadlayout(panel_layout)
local isPanelOpen = false

styleView(main_bg, 0x00000000, 15, 0xFF333333, 2)
styleView(btn_panic, 0xFFFF0000, 5) -- Panic Button Rouge
styleView(input_text, 0xFF1A1A1A, 5)
styleView(btn_server_action, 0xFF00FF00, 5)
styleView(btn_enc, 0xFF333333, 5)
styleView(btn_dec, 0xFF333333, 5)

-- ================= LOGIQUE =================
tab_server.onClick = function()
  layout_server.setVisibility(View.VISIBLE)
  layout_crypt.setVisibility(View.GONE)
  tab_server.setTextColor(0xFFFFFFFF)
  tab_crypt.setTextColor(0xFF555555)
end

tab_crypt.onClick = function()
  layout_server.setVisibility(View.GONE)
  layout_crypt.setVisibility(View.VISIBLE)
  tab_server.setTextColor(0xFF555555)
  tab_crypt.setTextColor(0xFFFFFFFF)
  p.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  wm.updateViewLayout(panelView, p)
end

local isServerOn = false
btn_server_action.onClick = function()
  if not isServerOn then
    txt_ip.Text = "MONITORING...\n" .. getIP() .. ":8080"
    txt_ip.setTextColor(0xFF00FF00)
    btn_server_action.Text = "DÉSACTIVER"
    styleView(btn_server_action, 0xFFFF0000, 5)
    isServerOn = true
    thread(function(path) os.execute(path) end, PATH_SERVER)
  else
    os.execute("killall server")
    txt_ip.Text = "SÉCURISÉ"
    txt_ip.setTextColor(0xFF555555)
    btn_server_action.Text = "ACTIVER LE PIÈGE"
    styleView(btn_server_action, 0xFF00FF00, 5)
    isServerOn = false
  end
end

-- Crypto Hexadécimale
function runCrypt(mode)
  local txt = input_text.Text
  if txt == "" then return end
  local cmd = PATH_CRYPT .. " " .. mode .. " \"" .. txt .. "\""
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  output_text.setText(result)
end
btn_enc.onClick = function() runCrypt("enc") end
btn_dec.onClick = function() runCrypt("dec") end

-- Bouton PANIC KILL (Ferme tout direct)
btn_panic.onClick = function()
  os.execute("killall server")
  wm.removeView(panelView)
  isPanelOpen = false
  isServerOn = false
  print("PANIC: Tous les systèmes coupés.")
end

btn_launch.onClick = function()
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    intent.setData(Uri.parse("package:"..activity.getPackageName()))
    activity.startActivity(intent)
    return
  end
  if not isPanelOpen then
    wm.addView(panelView, p)
    isPanelOpen = true
  end
end
