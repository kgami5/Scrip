require "import"
import "android.app.*"
import "android.os.*"
import "android.view.*"
import "android.webkit.*"
import "android.speech.tts.TextToSpeech"
import "android.content.Intent"
import "android.speech.RecognizerIntent"
import "java.util.Locale"

-- === Configuration de la fenêtre ===
activity.setTitle("ObscurGPT")
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT)

-- === Création WebView ===
local webView = WebView(activity)
activity.setContentView(webView)

local settings = webView.getSettings()
settings.setJavaScriptEnabled(true)
settings.setSupportZoom(true)
settings.setDomStorageEnabled(true)
settings.setBuiltInZoomControls(false)

-- === Initialisation Text-To-Speech ===
local tts
tts = TextToSpeech(activity, TextToSpeech.OnInitListener{
  onInit = function(status)
    if status == TextToSpeech.SUCCESS then
      tts.setLanguage(Locale.FRANCE) -- ou Locale.US si tu veux anglais
    end
  end
})

-- Fonction pour faire parler l’IA
function speakText(text)
  if text and #text > 0 then
    tts.speak(text, TextToSpeech.QUEUE_FLUSH, nil, "ObscurGPT_TTS")
  end
end

-- === Initialisation Speech-To-Text ===
local REQUEST_CODE_STT = 1001

function startRecognition()
  local intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
  intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Parlez maintenant...")
  activity.startActivityForResult(intent, REQUEST_CODE_STT)
end

function onActivityResult(requestCode, resultCode, data)
  if requestCode == REQUEST_CODE_STT and resultCode == Activity.RESULT_OK then
    local matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
    if matches and matches.size() > 0 then
      local spokenText = matches.get(0)
      -- On renvoie le texte reconnu dans le JS
      webView.post(function()
        webView.evaluateJavascript("window.onSpeechResult && window.onSpeechResult("..string.format("%q", spokenText)..");", nil)
      end)
    end
  end
end

-- === Interface exposée au JavaScript ===
local bridge = {}

-- Fonction appelée depuis JS pour parler
function bridge.speak(text)
  activity.runOnUiThread(function()
    speakText(text)
  end)
end

-- Fonction appelée depuis JS pour lancer la reconnaissance vocale
function bridge.listen(dummy)
  activity.runOnUiThread(function()
    startRecognition()
  end)
end

webView.addJavascriptInterface(bridge, "AndroidBridge")

-- === Charger ton site ===
webView.loadUrl("https://obscurgpt.com")
