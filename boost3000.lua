require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"

activity.overridePendingTransition(android.R.anim.fade_in,android.R.anim.fade_out)
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
activity.setContentView(loadlayout(layout))
activity.setRequestedOrientation(1)

webviewid.loadUrl("https://boost3000.fr")
webviewid.getTitle()
webviewid.getUrl()
webviewid.requestFocusFromTouch()
webviewid.getSettings().setJavaScriptEnabled(true)
webviewid.getSettings().setSupportZoom(true)
