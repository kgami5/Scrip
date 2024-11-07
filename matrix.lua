require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.webkit.*"

-- Create a new layout to host the WebView
Layout = {
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rotating Icon with Clickable Button</title>
    <style>
        /* General reset and styling */
        body, html {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background: transparent;
            overflow-x: hidden;
            color: #fff;
            text-align: center;
            height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }

        .central-image {
            width: 150px;
            height: 150px;
            border-radius: 50%;
            border: 5px solid #fff;
            background: url('https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif') no-repeat center center / cover;
            animation: rotateUpDown 2s infinite ease-in-out;
            z-index: 1; /* Ensure it stays behind the button */
        }

        @keyframes rotateUpDown {
            0% {
                transform: rotateX(0deg);
            }
            50% {
                transform: rotateX(180deg);
            }
            100% {
                transform: rotateX(0deg);
            }
        }

        .start-button {
            margin-top: 20px;
            padding: 15px 30px;
            font-size: 18px;
            color: #fff;
            background: #ff5722;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            transition: background 0.3s ease-in-out;
            z-index: 2; /* Ensure it is above the rotating image */
            position: relative; /* Makes z-index effective */
        }

        .start-button:hover {
            background: #e64a19;
        }
    </style>
</head>
<body>
    <!-- Non-clickable rotating central image -->
    <div class="central-image"></div>

    <!-- Clickable START button -->
    <a href="https://boost3000.fr" target="_blank" class="start-button">START</a>
</body>
</html>














<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
<meta name="google-adsense-account" content="ca-pub-7131382574412134">
</head>
<body>
</body>
</html>
































<!DOCTYPE html>
<html lang="en">
<head>







  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Compact Music Button with Modern Popup Controls</title>
  <!-- Remix Icon CDN -->
  <link href="https://cdn.jsdelivr.net/npm/remixicon/fonts/remixicon.css" rel="stylesheet">
  <style>
    /* Main container positioned at bottom left */
    .music-container {
      position: fixed;
      top: 70px;
      left: 130px;
      display: flex;
      flex-direction: column;
      align-items: center;
      z-index: 1000;
    }

    /* Spherical Music Button with pulse and rotation animation */
    .music-btn {
      position: relative;
      background-color: #1d1d1d;
      border: none;
      width: 50px;
      height: 50px;
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      font-size: 28px;
      color: #fff;
      cursor: pointer;
      transition: background-color 0.3s ease, transform 0.3s ease;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
      animation: pulse 2s infinite;
    }

    .music-btn::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border-radius: 50%;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
      z-index: -1;
    }

    .rotate-animation {
      animation: rotate 2s linear infinite;
    }

    .music-btn:hover {
      background-color: #ff5722;
      transform: scale(1.1);
    }

    @keyframes pulse {
      0% { transform: scale(1); box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3); }
      50% { transform: scale(1.15); box-shadow: 0 0 15px #ff5722; }
      100% { transform: scale(1); box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3); }
    }

    @keyframes rotate {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }

    .music-controls {
      display: none;
      position: absolute;
      bottom: 75px;
      background-color: #1d1d1d;
      padding: 8px 10px;
      border-radius: 15px;
      display: flex;
      gap: 10px;
      opacity: 0;
      transition: opacity 0.3s ease, transform 0.3s ease;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
    }

    .control-btn {
      background-color: #444;
      border: none;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      font-size: 18px;
      color: #fff;
      cursor: pointer;
      transition: background-color 0.3s ease, transform 0.3s ease;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }

    .control-btn:hover {
      background-color: #ff5722;
      transform: scale(1.1);
    }

    .music-container.active .music-controls {
      display: flex;
      opacity: 1;
      transform: translateY(-10px);
    }
  </style>
</head>
<body>

  <!-- Music Container -->
  <div class="music-container">
    <!-- Music Button -->
    <button class="music-btn" id="musicBtn"><i class="ri-music-2-fill"></i></button>

    <!-- Popup Controls -->
    <div class="music-controls" id="musicControls">
      <button id="backwardBtn" class="control-btn"><i class="ri-rewind-line"></i></button>
      <button id="playPauseBtn" class="control-btn"><i class="ri-play-fill"></i></button>
      <button id="forwardBtn" class="control-btn"><i class="ri-speed-line"></i></button>
    </div>
  </div>

  <!-- Audio Player -->
  <audio id="backgroundMusic" preload="auto"></audio>

<script>
    // Array of song URLs
    const songs = [
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/ZHU%20%26%20Nero%20-%20Dreams.mp3",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/Vlog_No_Copyright_Music_Fredji_Happy_Life_Vlog_No_Copyright_Music.m4a",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/Fake%20-%20STXRBXTH.m4a",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/HUSSLE%20-%20LEVAN%20CREED.mp3",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/GAWIWI%20-%20Red%20Flag.mp3",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/Cypress%20Hill%20-%20Hits%20from%20the%20Bong%20(Official%20Audio).mp3",
      "https://raw.githubusercontent.com/Zelenskypilot/trndmsc1/main/Assassin's%20Creed%20Syndicate%20-%20On%20My%20Own%20%5BGMV%5D_FReeSAPLrak.mp3"
    ];

    let currentSongIndex = 0;
    const audio = document.getElementById('backgroundMusic');
    const playPauseBtn = document.getElementById('playPauseBtn');
    const playPauseIcon = playPauseBtn.querySelector('i');
    const forwardBtn = document.getElementById('forwardBtn');
    const backwardBtn = document.getElementById('backwardBtn');
    const musicContainer = document.querySelector('.music-container');
    const musicBtn = document.getElementById('musicBtn');
    const musicControls = document.getElementById('musicControls');

    // Load the first song
    audio.src = songs[currentSongIndex];

    // Toggle play/pause
    playPauseBtn.addEventListener('click', togglePlayPause);

    // Play next song
    forwardBtn.addEventListener('click', () => {
      currentSongIndex = (currentSongIndex + 1) % songs.length;
      loadSong();
    });

    // Play previous song
    backwardBtn.addEventListener('click', () => {
      currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
      loadSong();
    });

    // Load song function
    function loadSong() {
      audio.src = songs[currentSongIndex];
      audio.play();
      playPauseIcon.className = 'ri-pause-fill';
      musicBtn.classList.add('rotate-animation');
    }

    // Function to toggle play/pause and change icon
    function togglePlayPause() {
      if (audio.paused) {
        audio.play();
        playPauseIcon.className = 'ri-pause-fill';  // Change icon to pause
        musicBtn.classList.add('rotate-animation'); // Add rotation animation
      } else {
        audio.pause();
        playPauseIcon.className = 'ri-play-fill';  // Change icon to play
        musicBtn.classList.remove('rotate-animation'); // Remove rotation animation
      }
    }

    // Auto play on page load
    window.onload = function() {
      audio.play();
      playPauseIcon.className = 'ri-pause-fill';
      musicBtn.classList.add('rotate-animation');
    };

    // Autoplay behavior on audio start/stop
    audio.onplay = () => {
      playPauseIcon.className = 'ri-pause-fill';
      musicBtn.classList.add('rotate-animation');
    };

    audio.onpause = () => {
      playPauseIcon.className = 'ri-play-fill';
      musicBtn.classList.remove('rotate-animation');
    };

    // Toggle controls popup
    musicBtn.addEventListener('click', function(event) {
      event.stopPropagation(); // Prevent the event from bubbling up
      musicContainer.classList.toggle('active');
    });

    // Close popup when clicking outside the music container
    document.addEventListener('click', function(event) {
      if (!musicContainer.contains(event.target)) {
        musicContainer.classList.remove('active');
      }
    });

    // Prevent closing popup when clicking inside the music container
    musicContainer.addEventListener('click', function(event) {
      event.stopPropagation(); // Prevent the event from bubbling up
    });
</script>
</body>
</html>




<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title> icons snow</title>
  <style>


    #snowflakes {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: -1;
      pointer-events: none;
    }

    .snowflake {
      position: absolute;
      width: 100px;
      height: auto;
      opacity: 0.5;
      animation: fall linear infinite;
    }

    @keyframes fall {
      0% {
        opacity: 0.5;
        transform: translateY(-10px) rotate(0deg);
      }
      100% {
        opacity: 0.5;
        transform: translateY(110vh) rotate(360deg);
      }
    }
  </style>
</head>
<body>
  
  <div id="snowflakes"></div>
  <script>
    const snowflakeImages = [
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif',
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/1730819768305.png',
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif',
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/1728824074991.png',
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/1730819768305.png',
      'https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif'
    ];

    function createSnowflake() {
      const snowflake = document.createElement('img');
      const randomImage = snowflakeImages[Math.floor(Math.random() * snowflakeImages.length)];
      snowflake.src = randomImage;
      snowflake.classList.add('snowflake');
      snowflake.style.left = `${Math.random() * window.innerWidth}px`;
      snowflake.style.animationDuration = `${Math.random() * 5 + 5}s`;
      document.getElementById('snowflakes').appendChild(snowflake);

      setTimeout(() => {
        snowflake.remove();
      }, 100000); // Remove snowflake after 100 seconds
    }

    setInterval(createSnowflake, 600); // Create a new snowflake every 0.3 seconds
  </script>
</body>
</html>













<!DOCTYPE html>
<html lang="en" >
<head>
  <meta charset="UTF-8">
  <title>animated  bubble </title>
  <link rel="stylesheet" href="./style.css">
<style>

.bubbles{
  position:absolute;
  width:100%;
  height: 100%;
  z-index:0;
  overflow:hidden;
  top:0;
  left:0;
}
.bubble{
  position: absolute;
  bottom:-100px;
  width:40px;
  height: 40px;
  background:#ADD8E6;
  border-radius:50%;
  opacity:0.5;
  animation: rise 10s infinite ease-in;
}
.bubble:nth-child(1){
  width:40px;
  height:40px;
  left:10%;
  animation-duration:8s;
}
.bubble:nth-child(2){
  width:20px;
  height:20px;
  left:20%;
  animation-duration:5s;
  animation-delay:1s;
}
.bubble:nth-child(3){
  width:50px;
  height:50px;
  left:35%;
  animation-duration:7s;
  animation-delay:2s;
}
.bubble:nth-child(4){
  width:80px;
  height:80px;
  left:50%;
  animation-duration:11s;
  animation-delay:0s;
}
.bubble:nth-child(5){
  width:35px;
  height:35px;
  left:55%;
  animation-duration:6s;
  animation-delay:1s;
}
.bubble:nth-child(6){
  width:45px;
  height:45px;
  left:65%;
  animation-duration:8s;
  animation-delay:3s;
}
.bubble:nth-child(7){
  width:90px;
  height:90px;
  left:70%;
  animation-duration:12s;
  animation-delay:2s;
}
.bubble:nth-child(8){
  width:25px;
  height:25px;
  left:80%;
  animation-duration:6s;
  animation-delay:2s;
}
.bubble:nth-child(9){
  width:15px;
  height:15px;
  left:70%;
  animation-duration:5s;
  animation-delay:1s;
}
.bubble:nth-child(10){
  width:90px;
  height:90px;
  left:25%;
  animation-duration:10s;
  animation-delay:4s;
}
@keyframes rise{
  0%{
    bottom:-100px;
    transform:translateX(0);
  }
  50%{
    transform:translate(100px);
  }
  100%{
    bottom:1080px;
    transform:translateX(-200px);
  }
}
</style>
</head>
<body>
<!-- partial:index.partial #E0FFFF #ADD8E6 html -->
<section class="sticky">
  <div class="bubbles">
      <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    <div class="bubble"></div>
    
  </div>
</section>
<!-- partial -->
  
</body>
</html>






<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"/>
    <title>Dynamic Toast Notification with Progress Bar</title> 
    
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');

        .Xv_toast {
            position: fixed;
            bottom: 190px;
            right: 20px;
            border-radius: 12px;
            background: white;
            padding: 10px 20px;
            box-shadow: 0 5px 10px rgba(0,0,0,0.1);
            border-left: 6px solid #F3BA2F;
            overflow: hidden;
            transform: translateX(calc(100% + 30px));
            transition: all 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.35);
            z-index: 1000;
        }

        .Xv_toast.Xv_active {
            transform: translateX(0%);
        }

        .Xv_toast .Xv_toast-content {
            display: flex;
            align-items: center;
        }

        .Xv_toast-content .Xv_icon {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 35px;
            width: 35px;
            background-color: #F3BA2F;
            color: #fff;
            font-size: 15px;
            border-radius: 50%;
        }

        .Xv_toast-content .Xv_message {
            display: flex;
            flex-direction: column;
            margin: 0 20px;
        }

        .Xv_message .Xv_text {
            font-size: 15px;
            font-weight: 400;
            color:#333 ;
        }

        .Xv_message .Xv_text.Xv_text-1 {
            font-weight: 200;
            font-size: 13px;
            color: #1e1e1e;
        }

        .Xv_message .Xv_text.Xv_text-2 {
            font-weight: bold;
            font-size: 15px;
            color: #1e1e1e;
        }

        .Xv_message .Xv_text.Xv_text-3 {
            font-weight: 200;
            font-size: 13px;
            color: #1e1e1e;
        }

        .Xv_toast .Xv_close {
            position: absolute;
            top: 5px;
            color: #F3BA2F;
            right: 10px;
            padding: 5px;
            cursor: pointer;
            opacity: 0.7;
        }

        .Xv_toast .Xv_close:hover {
            opacity: 1;
        }

        .Xv_toast .Xv_progress {
            position: absolute;
            bottom: 0;
            left: 0;
            height: 3px;
            width: 100%;
            background: #ddd;
        }

        .Xv_toast .Xv_progress:before {
            content: '';
            position: absolute;
            bottom: 0;
            right: 0;
            height: 100%;
            width: 100%;
            background-color: #F3BA2F;
        }

        .Xv_progress.Xv_active:before {
            animation: Xv_progress 5s linear forwards;
        }

        @keyframes Xv_progress {
            100% {
                right: 100%;
            }
        }
    </style>
</head>

<body>
    <div class="Xv_toast">
        <div class="Xv_toast-content">
            <i class="ri-shopping-cart-line Xv_icon"></i>
            <div class="Xv_message">
                <span class="Xv_text Xv_text-1">Placeholder message</span>
                <span class="Xv_text Xv_text-2">Item</span>
                <span class="Xv_text Xv_text-3">Time ago</span>
            </div>
        </div>
        <i class="ri-close-line Xv_close"></i>
        <div class="Xv_progress"></div>
    </div>

    <script>
        const toast = document.querySelector(".Xv_toast"),
              closeIcon = document.querySelector(".Xv_close"),
              progress = document.querySelector(".Xv_progress");

        const items = ['Youtube', 'TikTok', 'Instagram', 'TikTok', 'Telegram', 'TikTok'];
        const times = ['3 minutes ago', '40 minutes ago', '1 hour ago', '3 hours ago', '45 minutes ago', '30 minutes ago'];
        const countries = ['United States', 'India', 'Brazil', 'Nigeria', 'Germany', 'China', 'Japan', 'Russia', 'Canada', 'United Kingdom', 'France', 'Italy', 'Australia', 'Spain', 'Mexico', 'Ukraine', 'Kenya', 'Lebanon', 'Tanzania', 'Pakistan', 'Uganda'];

        function showToast() {
            const isSignup = Math.random() >= 0.5; // 50% chance for signup toast

            if (isSignup) {
                // Signup message
                document.querySelector('.Xv_icon').className = 'ri-user-line Xv_icon';
                document.querySelector('.Xv_text.Xv_text-1').textContent = "New user just signed up";
                document.querySelector('.Xv_text.Xv_text-2').textContent = countries[Math.floor(Math.random() * countries.length)];
                document.querySelector('.Xv_text.Xv_text-3').textContent = times[Math.floor(Math.random() * times.length)];
            } else {
                // Shopping cart message
                document.querySelector('.Xv_icon').className = 'ri-shopping-cart-line Xv_icon';
                document.querySelector('.Xv_text.Xv_text-1').textContent = "Someone new just bought";
                document.querySelector('.Xv_text.Xv_text-2').textContent = items[Math.floor(Math.random() * items.length)];
                document.querySelector('.Xv_text.Xv_text-3').textContent = times[Math.floor(Math.random() * times.length)];
            }

            // Show the toast
            toast.classList.add("Xv_active");
            progress.classList.add("Xv_active");

            // Hide the toast after a timeout
            timer1 = setTimeout(() => {
                toast.classList.remove("Xv_active");
            }, 5000);

            timer2 = setTimeout(() => {
                progress.classList.remove("Xv_active");
            }, 5300);
        }

        closeIcon.addEventListener("click", () => {
            toast.classList.remove("Xv_active");
            clearTimeout(timer1);
            clearTimeout(timer2);
            setTimeout(() => {
                progress.classList.remove("Xv_active");
            }, 300);
        });

        // Show toast on page load
        window.onload = function() {
            setTimeout(() => showToast(), 500);  // Slight delay for first notification
            // Repeat every 7 seconds
            setInterval(showToast, 14000);
        };
    </script>
</body>
</html>






]]

-- Set up the WebView to display content
modMenuWebView.getSettings().setJavaScriptEnabled(true)
modMenuWebView.setWebViewClient(WebViewClient())
modMenuWebView.loadData(htmlContent, "text/html", "UTF-8")
