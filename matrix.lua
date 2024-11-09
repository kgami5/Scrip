require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.webkit.*"



-- Create a new layout to host the WebView
local MainLayout = {
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
activity.setContentView(loadlayout(MainLayout))

-- HTML content for the WebView
local htmlContent = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D Rotating Icon with Shiny Button</title>
    <style>
        /* General reset and styling */
        body, html {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background: rgba(0, 0, 0, 0.8);
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
            border: 5px solid rgba(255, 255, 255, 0); /* Transparent border */
            background: url('https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/rainbow-diamond.gif') no-repeat center center / cover;
            animation: rotateUpDown 3s infinite cubic-bezier(0.25, 1, 0.5, 1);
            transform-origin: center;
            perspective: 1000px;
            z-index: 1;
        }

        @keyframes rotateUpDown {
            0% {
                transform: rotateX(0deg) rotateY(0deg);
            }
            50% {
                transform: rotateX(180deg) rotateY(180deg);
            }
            100% {
                transform: rotateX(0deg) rotateY(360deg);
            }
        }

        .start-button {
            margin-top: 20px;
            padding: 15px 35px;
            font-size: 20px;
            color: #fff;
            background: linear-gradient(135deg, #ff5722, #e64a19);
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            position: relative;
            overflow: hidden;
            z-index: 2;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .start-button::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: rgba(255, 255, 255, 0.4);
            transform: rotate(45deg);
            transition: all 0.5s ease-in-out;
            opacity: 0;
            pointer-events: none;
        }

        .start-button::after {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 200%;
            height: 100%;
            background: rgba(255, 255, 255, 0.2);
            transform: skewX(-45deg);
            z-index: 1;
            transition: all 0.5s ease-in-out;
        }

        .start-button:hover {
            transform: translateY(-5px) scale(1.05);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
        }

        .start-button:hover::before {
            opacity: 0.6;
            transform: rotate(45deg) scale(1.2);
        }

        .start-button::after {
            animation: shine 2.5s infinite linear;
        }

        @keyframes shine {
            0% {
                left: -150%;
            }
            50% {
                left: 100%;
            }
            100% {
                left: 150%;
            }
        }
    </style>
</head>
<body>
    <!-- Non-clickable rotating central image -->
    <div class="central-image"></div>

    <!-- Clickable START button with countdown and redirect -->
    <button class="start-button" id="startButton" onclick="startCountdown()">START</button>

    <script>
        function startCountdown() {
            const button = document.getElementById('startButton');
            let countdownValue = 3;
            button.textContent = countdownValue; // Set initial countdown value

            const interval = setInterval(() => {
                countdownValue--;
                if (countdownValue > 0) {
                    button.textContent = countdownValue; // Update button text
                } else {
                    button.textContent = 'Started!';
                    clearInterval(interval);

                    // Redirect to the specified URL after 1 second delay
                    setTimeout(() => {
                        window.location.href = "https://boost3000.fr";
                    }, 1000);
                }
            }, 1000);
        }
    </script>
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











]]

-- Set up the WebView to display content
modMenuWebView.getSettings().setJavaScriptEnabled(true)
modMenuWebView.setWebViewClient(WebViewClient())
modMenuWebView.loadData(htmlContent, "text/html", "UTF-8")
