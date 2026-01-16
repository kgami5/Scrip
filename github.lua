require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.PixelFormat"
import "android.graphics.Typeface"
import "android.graphics.drawable.GradientDrawable" -- Pour le design
import "android.graphics.Color"
import "java.net.NetworkInterface"
import "java.util.Collections"
import "android.content.Context"

-- ================= 🎨 DESIGN SYSTEM =================
-- Fonction pour créer des fonds arrondis stylés rapidement
function styleView(view, color, radius, strokeColor, strokeWidth)
  local drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setColor(color)
  drawable.setCornerRadius(radius)
  if strokeColor then
    drawable.setStroke(strokeWidth or 2, strokeColor)
  end
  view.setBackground(drawable)
end

-- Supprimer la barre de titre (Full Screen)
activity.setTheme(android.R.style.Theme_Material_NoActionBar)
if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().setStatusBarColor(0xFF000000)
end

-- ================= ⚙️ INSTALLATION & OUTILS =================
local BIN_SERVER = "KGAMI5/kgoslgjsjzbriguetdudh"
local BIN_CRYPT = "KGAMI5/gkglkdkdkkvkkdkdkc"
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

-- ================= 📱 INTERFACE PRINCIPALE (LAUNCHER) =================
main_layout = {
  LinearLayout,
  orientation="vertical",
  gravity="center",
  layout_width="fill",
  layout_height="fill",
  backgroundColor="#FF0F0F0F", -- Fond noir profond
  {
    TextView,
    text="SHADOW PANEL",
    textSize="30sp",
    textColor="#FF00FF00", -- Vert Hacker
    typeface=Typeface.MONOSPACE,
    textStyle="bold",
    layout_marginBottom="50dp"
  },
  {
    Button,
    id="btn_launch",
    text="INITIALISER LE SYSTÈME",
    textColor="#FFFFFFFF",
    textSize="16sp",
    padding="20dp",
    layout_width="250dp"
  },
  {
    TextView,
    text="v2.0 | Access Restricted",
    textColor="#FF444444",
    layout_marginTop="20dp",
    textSize="10sp"
  }
}

activity.setContentView(loadlayout(main_layout))

-- Application du style au bouton principal
styleView(btn_launch, 0xFF1A1A1A, 50, 0xFF00FF00, 3)

-- ================= 🛸 OVERLAY (PANEL FLOTTANT) =================
local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local p = WindowManager.LayoutParams()

p.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
p.format = PixelFormat.RGBA_8888
p.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
p.gravity = Gravity.TOP | Gravity.CENTER
p.width = 650 -- Largeur confortable
p.height = WindowManager.LayoutParams.WRAP_CONTENT
p.x = 0
p.y = 150

-- Layout de l'Overlay
local panel_layout = {
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  id="main_panel_bg",
  padding="2dp", -- Pour la bordure
  {
    LinearLayout, -- Header
    layout_width="fill",
    gravity="center_vertical",
    padding="10dp",
    backgroundColor="#FF000000",
    {
      TextView,
      text="⚡ COMMAND CENTER",
      textColor="#FF00FF00",
      textSize="14sp",
      typeface=Typeface.MONOSPACE,
      layout_weight=1
    },
    {
      TextView,
      text="✖",
      id="btn_close_panel",
      textColor="#FFFF0000",
      textSize="18sp",
      padding="5dp",
      textStyle="bold"
    }
  },
  {
    LinearLayout, -- Barre d'onglets
    layout_width="fill",
    backgroundColor="#FF111111",
    {
      TextView,
      text="SERVER",
      id="tab_server",
      textColor="#FFFFFFFF",
      gravity="center",
      layout_weight=1,
      padding="10dp",
      typeface=Typeface.DEFAULT_BOLD
    },
    {
      TextView,
      text="CRYPTO",
      id="tab_crypt",
      textColor="#FF888888",
      gravity="center",
      layout_weight=1,
      padding="10dp",
      typeface=Typeface.DEFAULT_BOLD
    }
  },
  {
    LinearLayout, -- Contenu
    orientation="vertical",
    layout_width="fill",
    padding="15dp",
    backgroundColor="#DD000000", -- Noir transparent
    
    -- PAGE SERVER
    {
      LinearLayout,
      id="layout_server",
      orientation="vertical",
      layout_width="fill",
      visibility=View.VISIBLE,
      {
        TextView,
        text="GHOST SERVER CONTROL",
        textColor="#FF888888",
        textSize="10sp",
        layout_marginBottom="10dp"
      },
      {
         TextView,
         id="txt_ip",
         text="DISCONNECTED",
         textSize="22sp",
         textColor="#FFFFFFFF",
         gravity="center",
         layout_marginBottom="20dp",
         typeface=Typeface.MONOSPACE
      },
      {
        Button,
        id="btn_server_action",
        text="ACTIVER",
        textColor="#FF000000",
        layout_width="fill"
      }
    },
    
    -- PAGE CRYPTO
    {
      LinearLayout,
      id="layout_crypt",
      orientation="vertical",
      layout_width="fill",
      visibility=View.GONE,
      {
        EditText,
        id="input_text",
        hint="Message secret...",
        textColor="#FFFFFFFF",
        hintTextColor="#FF555555",
        textSize="14sp",
        layout_width="fill",
        backgroundColor="#FF222222",
        padding="10dp"
      },
      {
        LinearLayout,
        layout_width="fill",
        layout_marginTop="10dp",
        {
          Button,
          id="btn_enc",
          text="LOCK",
          layout_weight=1,
          textColor="#FFFFFFFF"
        },
        {
          Button,
          id="btn_dec",
          text="UNLOCK",
          layout_weight=1,
          textColor="#FFFFFFFF"
        }
      },
      {
         TextView,
         id="output_text",
         text="",
         textSize="14sp",
         textColor="#FF00FF00",
         layout_marginTop="15dp",
         typeface=Typeface.MONOSPACE
      }
    }
  }
}

local panelView = loadlayout(panel_layout)
local isPanelOpen = false

-- Styles dynamiques de l'Overlay
styleView(main_panel_bg, 0x00000000, 20, 0xFF00FF00, 2) -- Bordure verte néon
styleView(input_text, 0xFF222222, 10)
styleView(btn_server_action, 0xFF00FF00, 10) -- Bouton vert
styleView(btn_enc, 0xFF333333, 10)
styleView(btn_dec, 0xFF333333, 10)

-- ================= 🕹️ LOGIQUE =================

-- Changement d'onglet
tab_server.onClick = function()
  layout_server.setVisibility(View.VISIBLE)
  layout_crypt.setVisibility(View.GONE)
  tab_server.setTextColor(0xFFFFFFFF)
  tab_crypt.setTextColor(0xFF888888)
end

tab_crypt.onClick = function()
  layout_server.setVisibility(View.GONE)
  layout_crypt.setVisibility(View.VISIBLE)
  tab_server.setTextColor(0xFF888888)
  tab_crypt.setTextColor(0xFFFFFFFF)
  -- Permettre la saisie clavier
  p.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  wm.updateViewLayout(panelView, p)
end

-- Logique Serveur
local isServerOn = false
btn_server_action.onClick = function()
  if not isServerOn then
    txt_ip.Text = "http://" .. getIP() .. ":8080"
    txt_ip.setTextColor(0xFF00FF00)
    btn_server_action.Text = "ARRETER"
    styleView(btn_server_action, 0xFFFF0000, 10) -- Devient rouge
    isServerOn = true
    thread(function(path) os.execute(path) end, PATH_SERVER)
  else
    os.execute("killall server")
    txt_ip.Text = "DISCONNECTED"
    txt_ip.setTextColor(0xFFFF0000)
    btn_server_action.Text = "ACTIVER"
    styleView(btn_server_action, 0xFF00FF00, 10) -- Devient vert
    isServerOn = false
  end
end

-- Logique Crypto
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

-- Lancement Overlay (AVEC CORRECTIF INTENT)
btn_launch.onClick = function()
  -- CORRECTION ICI : On lie la classe manuellement pour éviter l'erreur "nil"
  local Settings = luajava.bindClass("android.provider.Settings")
  local Intent = luajava.bindClass("android.content.Intent")
  local Uri = luajava.bindClass("android.net.Uri")

  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    -- Création de l'intent blindée
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

btn_close_panel.onClick = function()
  if isPanelOpen then
    wm.removeView(panelView)
    isPanelOpen = false
    if isServerOn then
        os.execute("killall server")
        isServerOn = false
        btn_server_action.Text = "ACTIVER"
        styleView(btn_server_action, 0xFF00FF00, 10)
    end
  end
end
