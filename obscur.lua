require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"

--activity.setTheme(R.Theme_Blue)
activity.setTitle("@KGAMI5")
activity.overridePendingTransition(android.R.anim.fade_in,android.R.anim.fade_out)
--activity.ActionBar.hide()
--activity.ActionBar.setElevation(0)
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
activity.setContentView(loadlayout(layout))
activity.setRequestedOrientation(1)

--webviewid.loadUrl("https://emupedia.net/beta/emuos/")
webviewid.loadUrl("https://boostland.fr/ia/ai")

--webviewid.loadUrl("https://mytoolstown.com/youtube")
webviewid.getTitle()
webviewid.getUrl()
webviewid.requestFocusFromTouch()
webviewid.getSettings().setJavaScriptEnabled(true)
webviewid.getSettings().setSupportZoom(true)