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

-- ================= CONFIG & INSTALLATION =================
local BIN_SERVER = "KGAMI5/kgoslgjsjzbriguetdudh"
local BIN_CRYPT = "KGAMI5/gkglkdkdkkvkkdkdkc"
local PATH_SERVER = activity.getFilesDir().getPath().."/"..BIN_SERVER
local PATH_CRYPT = activity.getFilesDir().getPath().."/"..BIN_CRYPT

function installBinaries()
  local function cp(name, path)
    local src = activity.getLuaDir().."/"..name
    os.execute("cp "..src.." "..path)
    os.execute("chmod 755 "..path)
  end
  cp(BIN_SERVER, PATH_SERVER)
  cp(BIN_CRYPT, PATH_CRYPT)
end
installBinaries()

-- ================= UTILITAIRES =================
function getIP()
  try
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
  catch(e) end
  return "OFFLINE"
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
    text="Nécessite la permission de superposition",
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
p.width = 600 -- Assez large
p.height = WindowManager.LayoutParams.WRAP_CONTENT
p.x = 0
p.y = 100

-- Design du Panel
local panel_layout = {
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  background="#EE000000", -- Noir transparent
  padding="2dp",
  {
    LinearLayout, -- Header (Barre de titre)
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
    LinearLayout, -- Menu Onglets
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
    LinearLayout, -- Contenu SERVER
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
    LinearLayout, -- Contenu CRYPTO
    id="layout_crypt",
    orientation="vertical",
    layout_width="fill",
    padding="10dp",
    visibility=View.GONE, -- Caché par défaut
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
local serverThreadID = -1

-- ================= LOGIQUE DES ONGLETS =================
tab_server.onClick = function()
  layout_server.setVisibility(View.VISIBLE)
  layout_crypt.setVisibility(View.GONE)
end

tab_crypt.onClick = function()
  layout_server.setVisibility(View.GONE)
  layout_crypt.setVisibility(View.VISIBLE)
  
  -- Astuce: Pour pouvoir taper du texte dans l'overlay
  p.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  wm.updateViewLayout(panelView, p)
end

-- ================= LOGIQUE SERVER =================
local isServerOn = false

btn_server_action.onClick = function()
  if not isServerOn then
    -- Démarrer
    txt_ip.Text = "http://" .. getIP() .. ":8080"
    txt_status.Text = "Statut: ONLINE (Port 8080)"
    txt_status.setTextColor(0xFF00FF00)
    btn_server_action.Text = "STOP SERVER"
    btn_server_action.setTextColor(0xFFFF0000)
    isServerOn = true
    
    -- Lancer le binaire dans un thread
    serverThreadID = thread(function(path)
      os.execute(path) -- Ça va bloquer ce thread tant que le serveur tourne
    end, PATH_SERVER)
    
  else
    -- Arrêter (Méthode brutale car non root)
    -- On ne peut pas facilement tuer le process sans PID, 
    -- mais on va réinitialiser l'UI et espérer que l'OS nettoie ou on utilisera killall
    os.execute("killall server") -- Tente de tuer tous les processus nommés "server"
    
    txt_status.Text = "Statut: OFFLINE"
    txt_status.setTextColor(0xFF555555)
    btn_server_action.Text = "START SERVER"
    btn_server_action.setTextColor(0xFF00FF00)
    isServerOn = false
  end
end

-- ================= LOGIQUE CRYPTO =================
function runCrypt(mode)
  local txt = input_text.Text
  if txt == "" then return end
  
  -- Appel système au binaire C++
  -- On met le texte entre guillemets pour gérer les espaces
  local cmd = PATH_CRYPT .. " " .. mode .. " \"" .. txt .. "\""
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  
  output_text.setText(result)
end

btn_enc.onClick = function() runCrypt("enc") end
btn_dec.onClick = function() runCrypt("dec") end

-- ================= GESTION DU PANEL =================
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
    -- Si on ferme le panel, on tue le serveur par sécurité
    if isServerOn then
        os.execute("killall server")
        isServerOn = false
        btn_server_action.Text = "START SERVER"
    end
  end
end
