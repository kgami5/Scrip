require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.content.Context"
import "android.content.Intent"
import "android.provider.Settings"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.GradientDrawable"

-- IMPORTANTS : On charge tes fichiers UI ici
import "layout"  -- Ton layout principal
import "min"     -- Ton menu flottant (amsmlay)

-- ===========================
-- 1. CONFIGURATION PRINCIPALE
-- ===========================
activity.setTitle("")
activity.setTheme(R.AndLua1)
activity.setContentView(loadlayout(layout))

if Build.VERSION.SDK_INT >= 21 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xFF000000);
end
activity.ActionBar.setBackgroundDrawable(ColorDrawable(0xFF000000))

-- ===========================
-- 2. ANIMATION TEXTE
-- ===========================
Update_UI=function(str)
  if t1 then t1.Text=str end
end

Start=function(str)
  require"import"
  function slg(str)
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

thread(Start," 01010 connected ... Hello There its me @KGAMI5 from boost3000.fr")


-- ===========================
-- 3. GESTION FENÊTRE FLOTTANTE
-- ===========================
do
  amsm7abdo=activity.getSystemService(Context.WINDOW_SERVICE)
  HasFocus=false
  amsmParam =WindowManager.LayoutParams()
  amsmParam.type =WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
  amsmParam.format =PixelFormat.RGBA_8888
  amsmParam.flags=WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
  amsmParam.gravity = Gravity.CENTER
  amsmParam.x = 0
  amsmParam.y = 0
  amsmParam.width =WindowManager.LayoutParams.WRAP_CONTENT
  amsmParam.height =WindowManager.LayoutParams.WRAP_CONTENT
  
  if Build.VERSION.SDK_INT >= 23 and not Settings.canDrawOverlays(activity) then
    print("Permission requise")
    intent=Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
    activity.startActivityForResult(intent, 100)
  else
    if amsmlay then
        amsm7min=loadlayout(amsmlay)
    else
        -- Au cas où min.lua est vide, on crée un bouton de secours pour éviter le crash
        amsm7min = loadlayout({
            LinearLayout,
            {TextView, text="ERROR", textColor="red"}
        })
    end
  end
end

-- ===========================
-- 4. STYLES BOUTONS
-- ===========================
function CircleButtonA(view,InsideColor,radiu,InsideColor1)
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setCornerRadii({radiu, radiu, radiu, radiu, radiu, radiu, radiu, radiu})
  drawable.setColor(InsideColor)
  drawable.setStroke(9, InsideColor1)
  view.setBackgroundDrawable(drawable)
end

if mLinearLayout1 then CircleButtonA(mLinearLayout1,0xFFBD0000,200,0xFFFFFFFF) end
if mLinearLayout2 then CircleButtonA(mLinearLayout2,0xFFFF0000,100,0xFFFFFFFF) end
if Cross then CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF) end


-- ===========================
-- 5. VÉRIFICATION DATE
-- ===========================
Date = "20260120"
date = os.date("%Y%m%d")
if date >= Date then
  dialog=AlertDialog.Builder(this)
  .setTitle("⚠️ EXPIRED ⚠️")
  .setCancelable(false)
  .setMessage("UPDATE IS REQUIRED")
  .setPositiveButton("EXIT",{onClick=function(v) os.exit() end})
  .show()
  return
end


-- ===========================
-- 6. FONCTION D'INJECTION (ANTI-CRASH & MULTI-CHEMINS)
-- ===========================
function AMSMEF(fileName)
  local path = activity.getLuaDir(fileName)
  
  -- 1. Donner les droits au fichier
  os.execute("chmod 777 '" .. path .. "'")

  -- 2. Liste des chemins possibles pour 'su'
  -- L'erreur venait du fait que le système ne trouvait pas "su" tout court
  local su_candidates = {
      "su",               -- Standard
      "/system/bin/su",   -- Souvent utilisé dans les VM
      "/system/xbin/su",  -- Ancien standard root
      "/sbin/su",         -- Magisk systemless
      "sh"                -- Dernier recours (si pas root mais shell suffisant)
  }

  local success = false
  
  -- 3. On teste les chemins un par un
  for i, binary in ipairs(su_candidates) do
      if success then break end -- Si ça a marché, on arrête
      
      -- Commande : binaire -c "commande"
      -- On ajoute nohup et redirection erreur
      local cmd_string = binary .. " -c 'nohup \"" .. path .. "\" > /dev/null 2>&1 &'"
      
      -- Si c'est juste "sh", on lance sans le "-c" complexe parfois
      if binary == "sh" then
         cmd_string = "nohup \"" .. path .. "\" > /dev/null 2>&1 &"
      end

      -- PCALL : C'est la protection magique.
      -- Si Runtime.exec plante, ça ne fera PAS d'écran rouge, ça renvoie juste false.
      local status, err = pcall(function() 
          Runtime.getRuntime().exec(cmd_string) 
      end)

      if status then
          print("✅ Injection réussie via : " .. binary)
          success = true
      else
          print("⚠️ Echec avec " .. binary)
      end
  end

  if success then
      Toast.makeText(activity, "💉 Injection Lancée", Toast.LENGTH_SHORT).show()
  else
      -- Si tout a échoué
      Toast.makeText(activity, "❌ Erreur: ROOT introuvable (Error=2)", Toast.LENGTH_LONG).show()
      
      -- Tentative désespérée sans su ni sh (directement le fichier)
      pcall(function() Runtime.getRuntime().exec(path) end)
  end
end

-- ===========================
-- 7. CLIC BOUTON
-- ===========================
amsm7A=false
function Cross.onClick()
  if (amsm7A==false) then
    amsm7abdo.addView(amsm7min,amsmParam)
    CircleButtonA(Cross,0xFF009F00,200,0xFFFFFFFF)
    amsm7A=true
    
    -- Lancer l'injecteur
    AMSMEF("KGAMI5/ckxkdkkskkhgkkdkskkv")

   else
    amsm7abdo.removeView(amsm7min)
    CircleButtonA(Cross,0xFFBD0000,200,0xFFFFFFFF)
    amsm7A=false
    
    -- Arrêter l'injecteur (Safe kill)
    local kill_cmds = {"su -c pkill -f ckxkdkkskkhgkkdkskkv", "pkill -f ckxkdkkskkhgkkdkskkv"}
    for _, cmd in ipairs(kill_cmds) do
        pcall(function() Runtime.getRuntime().exec(cmd) end)
    end
    
    Toast.makeText(activity,"ESP OFF 🔴", Toast.LENGTH_SHORT).show()
  end
end
