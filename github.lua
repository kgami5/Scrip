require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.PixelFormat"
import "android.graphics.Typeface"
import "java.net.NetworkInterface"
import "java.util.Collections"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.Context"
import "android.content.Intent"
-- ================= CONFIG & INSTALLATION =================
local BIN_SERVER = "KGAMI5/kgoslgjsjzbriguetdudh"
local BIN_CRYPT = "KGAMI5/gkglkdkdkkvkkdkdkc"
local PATH_SERVER = activity.getFilesDir().getPath().."/"..BIN_SERVER
local PATH_CRYPT = activity.getFilesDir().getPath().."/"..BIN_CRYPT

function installBinaries()
  local function cp(name, path)
    -- On vérifie si le fichier source existe avant de copier
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

-- ================= UTILITAIRES (CORRIGÉ) =================
function getIP()
  -- Utilisation de pcall au lieu de try/catch pour éviter l'erreur de syntaxe
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

  if status and result then
    return result
  else
    return "OFFLINE"
  end
end

-- ================= INTERFACE PRINCIPALE =================
activity.setTitle("Shadow Panel Launcher")
activity.setTheme(android.R.style.Theme_Material_Light)

main_layout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  {
    Button,
    text="ACTIVER SHADOW PANEL",
    id="btn_launch",
    padding="30dp",
    textSize="18sp",
    backgroundColor="#FF222222",
    textColor="#FFFFFFFF"
  },
  {
    TextView,
    text="Si rien ne s'affiche, vérifiez les permissions Overlay",
    layout_marginTop="20dp"
  }
}
activity.setContentView(loadlayout(main_layout))

-- ================= PANEL FLOTTANT (OVERLAY) =================
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local p = WindowManager.LayoutParams()

p.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
p.format = PixelFormat.RGBA_8888
p.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
p.gravity = Gravity.TOP | Gravity.CENTER
p.width = 600
p.height = WindowManager.LayoutParams.WRAP_CONTENT
p.x = 0
p.y = 100

local panel_layout = {
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  background="#EE000000",
  padding="2dp",
  {
    LinearLayout, 
    layout_width="fill",
    background="#FF004400",
    padding="5dp",
    gravity="center_vertical",
    {
      TextView,
      text="SHADOW PANEL",
      textColor="#FFFFFF",
      textSize="12sp",
      textStyle="bold",
      layout_weight=1
    },
    {
      TextView,
      text="X",
      id="btn_close_panel",
      textColor="#FF0000",
      textSize="14sp",
      padding="5dp"
    }
  },
  {
    LinearLayout, 
    layout_width="fill",
    {
      Button,
      text="GHOST SERVER",
      id="tab_server",
      layout_weight=1,
      textSize="10sp",
      backgroundColor="#333333"
    },
    {
      Button,
      text="CRYPTO",
      id="tab_crypt",
      layout_weight=1,
      textSize="10sp",
      backgroundColor="#333333"
    }
  },
  {
    LinearLayout,
    id="layout_server",
    orientation="vertical",
    layout_width="fill",
    padding="10dp",
    visibility=View.VISIBLE,
    {
      TextView,
      text="Statut: OFFLINE",
      id="txt_status",
      textColor="#FF555555",
      gravity="center"
    },
    {
      TextView,
      text="IP: ...",
      id="txt_ip",
      textColor="#FFFFFFFF",
      gravity="center",
      textSize="16sp",
      padding="10dp"
    },
    {
      Button,
      text="START SERVER",
      id="btn_server_action",
      textColor="#00FF00"
    }
  },
  {
    LinearLayout,
    id="layout_crypt",
    orientation="vertical",
    layout_width="fill",
    padding="10dp",
    visibility=View.GONE,
    {
      EditText,
      id="input_text",
      hint="Texte à chiffrer...",
      textColor="#FFFFFF",
      hintTextColor="#888888"
    },
    {
      LinearLayout,
      layout_width="fill",
      {
        Button,
        text="ENCRYPT",
        id="btn_enc",
        layout_weight=1
      },
      {
        Button,
        text="DECRYPT",
        id="btn_dec",
        layout_weight=1
      }
    },
    {
      EditText,
      id="output_text",
      hint="Résultat...",
      textColor="#00FF00",
      background="#111111"
    }
  }
}

local panelView = loadlayout(panel_layout)
local isPanelOpen = false

-- ================= LOGIQUE =================
tab_server.onClick = function()
  layout_server.setVisibility(View.VISIBLE)
  layout_crypt.setVisibility(View.GONE)
end

tab_crypt.onClick = function()
  layout_server.setVisibility(View.GONE)
  layout_crypt.setVisibility(View.VISIBLE)
  p.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  wm.updateViewLayout(panelView, p)
end

local isServerOn = false

btn_server_action.onClick = function()
  if not isServerOn then
    txt_ip.Text = "http://" .. getIP() .. ":8080"
    txt_status.Text = "Statut: ONLINE (Port 8080)"
    txt_status.setTextColor(0xFF00FF00)
    btn_server_action.Text = "STOP SERVER"
    btn_server_action.setTextColor(0xFFFF0000)
    isServerOn = true
    thread(function(path) os.execute(path) end, PATH_SERVER)
  else
    os.execute("killall server") 
    txt_status.Text = "Statut: OFFLINE"
    txt_status.setTextColor(0xFF555555)
    btn_server_action.Text = "START SERVER"
    btn_server_action.setTextColor(0xFF00FF00)
    isServerOn = false
  end
end

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

btn_launch.onClick = function()
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:"..activity.getPackageName()))
    activity.startActivity(intent)
    return
  end
  if not isPanelOpen then
    wm.addView(panelView, p)
    isPanelOpen = true
  end
end

btn_close_panel.onClick = function()
  if isPanelOpen then
    wm.removeView(panelView)
    isPanelOpen = false
    if isServerOn then
        os.execute("killall server")
        isServerOn = false
        btn_server_action.Text = "START SERVER"
    end
  end
end
