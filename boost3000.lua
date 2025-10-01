require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"

activity.overridePendingTransition(android.R.anim.fade_in,android.R.anim.fade_out)
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
activity.setRequestedOrientation(1)

-- Fonction d'affichage du popup de divulgation
function showAccessibilityDialog()
  local builder = AlertDialog.Builder(activity)
  builder.setTitle("Boost3000 et le service d’accessibilité")
  builder.setMessage(
    "Boost3000 a besoin d’accéder au service d’accessibilité afin d’activer certaines fonctionnalités internes de l’application.\n\n" ..
    "➝ Cette permission n’est utilisée que pour le fonctionnement de Boost3000.\n" ..
    "➝ Aucune donnée personnelle n’est collectée, stockée ou partagée."
  )
  builder.setPositiveButton("Accepter",{onClick=function(v)
    -- Si accepté, on charge le layout + webview
    activity.setContentView(loadlayout(layout))
    webviewid.loadUrl("https://boost3000.fr")
    webviewid.getSettings().setJavaScriptEnabled(true)
    webviewid.getSettings().setSupportZoom(true)
    webviewid.requestFocusFromTouch()
  end})
  builder.setNegativeButton("Annuler",{onClick=function(v)
    activity.finish()
  end})
  builder.setCancelable(false) -- empêche de fermer en dehors du popup
  builder.show()
end

-- Au démarrage on montre le popup
showAccessibilityDialog()
