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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5, minimum-scale=0.5, user-scalable=yes">
    <title>Landing Page - Jiagu360</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            color: #fff;
        }
        header {
            background: linear-gradient(135deg, #ff8c00, #ff6600);
            color: white;
            padding: 20px;
            text-align: center;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
            border-radius: 8px;
            margin: 10px;
        }
        .hero-section {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
            margin: 20px;
        }
        .hero-section img {
            width: 200px;
            height: auto;
            margin-bottom: 20px;
            animation: rotate3D 6s infinite;
        }
        /* Animation for image */
        @keyframes rotate3D {
            0% { transform: rotateY(0deg); }
            33% { transform: rotateY(360deg); } /* Rotate left-right in 2s */
            50% { transform: rotateY(360deg); } /* Pause for 1s */
            83% { transform: rotateX(360deg); } /* Rotate top-bottom in 3s */
            100% { transform: rotateX(360deg); }
        }
        .hero-section h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(90deg, #ff8c00, #e63946);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: 0 0 8px rgba(255, 140, 0, 0.8), 0 0 16px rgba(230, 57, 70, 0.6);
            padding: 10px 15px;
            border: 2px solid #ff8c00;
            border-radius: 8px;
            animation: flicker 2s infinite;
        }
        .hero-section p {
            font-size: 1.2em;
            max-width: 600px;
            text-align: center;
            background: rgba(255, 255, 255, 0.15);
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }
        .cta-button {
            margin-top: 20px;
            padding: 15px 30px;
            background: linear-gradient(135deg, #00b4db, #0083b0);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.3);
            transition: background 0.3s, box-shadow 0.3s;
        }
        .cta-button:hover {
            background: linear-gradient(135deg, #0083b0, #00b4db);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
        }
        footer {
            margin-top: 40px;
            padding: 10px 20px;
            background: linear-gradient(135deg, #ff8c00, #ff6600);
            color: white;
            text-align: center;
            border-radius: 8px;
        }
        /* Flicker effect */
        @keyframes flicker {
            0%, 19%, 21%, 23%, 25%, 54%, 56%, 100% {
                text-shadow: 0 0 8px rgba(255, 140, 0, 0.8), 0 0 16px rgba(230, 57, 70, 0.6);
            }
            20%, 24%, 55% {
                text-shadow: none;
            }
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // Button click redirection
            const ctaButton = document.querySelector('.cta-button');
            ctaButton.addEventListener('click', function(event) {
                event.preventDefault(); // Prevent default action
                window.open('https://jiagu.360.cn/#/global/index', '_self'); // Open in the same tab without zoom
            });
        });
    </script>
</head>
<body>
    <header>
        <h1>Welcome to Jiagu360</h1>
    </header>

    <main class="hero-section">
        <img src="https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif" alt="Diamond GIF">
        <h1>Optimize Your Experience with Jiagu360</h1>
        <p>Discover innovative solutions for digital transformation, security, and much more with Jiagu360.</p>
        <a href="#" class="cta-button">Learn More</a>
    </main>

    <footer>
        <p>&copy; 2024 Jiagu360 - All rights reserved.</p>
    </footer>
</body>
</html>
]]

-- Set up the WebView to display content
modMenuWebView.getSettings().setJavaScriptEnabled(true)
modMenuWebView.getSettings().setSupportZoom(true)
modMenuWebView.getSettings().setBuiltInZoomControls(true)
modMenuWebView.getSettings().setDisplayZoomControls(false)
modMenuWebView.setWebViewClient(WebViewClient())
modMenuWebView.loadData(htmlContent, "text/html", "UTF-8")
