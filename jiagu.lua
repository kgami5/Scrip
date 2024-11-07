require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.webkit.*"

-- Create a new layout to host the WebView
local mainLayout = {
  LinearLayout;
  orientation = "vertical";
  layout_width = "match_parent";
  layout_height = "match_parent";
  {
    WebView;
    id = "modMenuWebView";
    layout_width = "match_parent";
    layout_height = "match_parent";
  };
}

-- Set up the activity's content view
activity.setContentView(loadlayout(mainLayout))

-- HTML content for the WebView
local htmlContent = [[



<!DOCTYPE html>
<html>
<head>
<meta name="cryptomus" content="688e9f44" />






    <style type="text/css">
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
        }
        #q {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        #redirect-button {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            background-color: rgba(0, 0, 0, 0.5);
            color: #fff;
            border: none;
            border-radius: 5px;
            text-align: center;
            z-index: 1;
        }
    </style>
    <script>
        function TheMatrix() {
            const canvas = document.getElementById('q');
            const ctx = canvas.getContext('2d');
            const screen = window.screen;
            const w = canvas.width = screen.width;
            const h = canvas.height = screen.height;
            const p = [];
            for (let i = 0; i < 256; i++) {
                p[i] = 1;
            }
            function draw() {
                ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
                ctx.fillRect(0, 0, w, h);
                ctx.fillStyle = '#0F0';
                p.map(function (v, i) {
                    ctx.fillText(String.fromCharCode(3e4 + Math.random() * 33), i * 10, v);
                    p[i] = v > 758 + Math.random() * 1e4 ? 0 : v + 10;
                });
            }
            setInterval(draw, 33);
        }
        function redirectToLink() {
            window.location.href = 'https://jiagu.360.cn/#/global/index';
        }
    </script>
</head>
<body onload="TheMatrix();">
<canvas id="q"></canvas>
<button id="redirect-button" onclick="redirectToLink()">JIAGU</button>
</body>
</html>





]]

-- Set up the WebView to display content
modMenuWebView.getSettings().setJavaScriptEnabled(true)
modMenuWebView.setWebViewClient(WebViewClient())
modMenuWebView.loadData(htmlContent, "text/html", "UTF-8")
