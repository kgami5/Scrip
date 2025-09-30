require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.webkit.WebView"
import "android.webkit.WebViewClient"

-- Définir le layout avec une WebView
layout = {
  LinearLayout,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  {
    WebView,
    id = "web",
    layout_width = "fill",
    layout_height = "fill"
  }
}

-- Appliquer le thème et layout
--activity.setTheme(android.R.style.Theme_Holo_Light)
activity.setContentView(loadlayout(layout))

-- Config WebView
web.getSettings().setJavaScriptEnabled(true)
web.setWebViewClient(WebViewClient()) -- reste dans l’app

-- Exemple de code HTML
html = [[

<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Boost3000 — Découvrez la Magie</title>
  <meta name="description" content="Landing page féerique et marketing pour Boost3000." />
  <style>
    :root{
      --accent:#a29bff;
      --accent-2:#ffd1f0;
      --glass: rgba(255,255,255,0.06);
      --text: rgba(255,255,255,0.95);
      --shadow: 0 10px 30px rgba(16,12,40,0.6);
      --bg-grad: linear-gradient(135deg,#0b1020 0%, #08111b 50%, #061523 100%);
    }
    html,body{height:100%;margin:0;font-family:Inter, system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; background:var(--bg-grad); color:var(--text);}
    .wrap{position:relative;height:100vh;overflow:hidden;display:flex;align-items:center;justify-content:center}

    video.bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;filter:brightness(.6) contrast(1.05) saturate(1.15) blur(.2px);transform:scale(1.02)}
    .overlay{position:absolute;inset:0;background:radial-gradient(ellipse at 20% 10%, rgba(162,155,255,0.12),transparent 10%), radial-gradient(ellipse at 80% 90%, rgba(255,209,240,0.06),transparent 15%);} 

    .card{position:relative;z-index:6;backdrop-filter: blur(6px) saturate(1.2);background:linear-gradient(135deg, rgba(255,255,255,0.04), rgba(255,255,255,0.02));border-radius:20px;padding:28px 36px;box-shadow:var(--shadow);max-width:880px;width:calc(100% - 48px);display:flex;flex-direction:column;gap:24px;align-items:center;text-align:center}

    .title{font-size:clamp(26px,4vw,52px);line-height:1.1;margin:0;font-weight:700;letter-spacing: -0.02em}
    .subtitle{margin:0;color:rgba(255,255,255,0.85);font-size:clamp(14px,1.6vw,18px)}

    .cta{display:flex;flex-wrap:wrap;justify-content:center;gap:14px;margin-top:18px}
    .btn{padding:14px 22px;border-radius:14px;border:0;background:linear-gradient(90deg,var(--accent),#7ad0ff);color:#071026;font-weight:700;cursor:pointer;box-shadow:0 8px 20px rgba(115,95,240,0.18);font-size:16px;transition:transform .2s}
    .btn:hover{transform:scale(1.05)}
    .btn.secondary{background:transparent;border:1px solid rgba(255,255,255,0.08);color:var(--text);font-weight:600}

    /* Social icons */
    .socials{display:flex;gap:18px;justify-content:center;margin-top:20px}
    .socials a{color:white;font-size:24px;transition:opacity .2s}
    .socials a:hover{opacity:0.7}

    canvas#particles{position:absolute;inset:0;z-index:4;pointer-events:none}
    .sparkle{position:absolute;z-index:5;mix-blend-mode:screen;filter:blur(.3px);opacity:.95}
    footer.note{position:absolute;left:12px;bottom:12px;color:rgba(255,255,255,0.55);font-size:13px;z-index:7}

    @media (max-width:720px){.subtitle{font-size:14px}}
  </style>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" integrity="sha512-dx1uOy+tkWxppIqhzyapMI2vlA38nSxrdbidK4USsfx8bVsgcF6edSxnl2xe50Tzw9uQWGWpZ6YG1ChB7xTz+Q==" crossorigin="anonymous" referrerpolicy="no-referrer" />
</head>
<body>
  <div class="wrap" role="main">
    <video class="bg" autoplay muted playsinline loop>
      <source src="https://raw.githubusercontent.com/kgami5/Scrip/refs/heads/main/video1.mp4" type="video/mp4">
    </video>
    <div class="overlay"></div>
    <canvas id="particles"></canvas>

    <div class="card">
      <h1 class="title">Boostez votre univers avec Boost3000</h1>
      <p class="subtitle">Un sanctuaire féerique — où la magie rencontre le marketing. Découvrez la puissance de votre marque, amplifiée.</p>
      <div class="cta">
        <button class="btn" id="go">Découvrir Boost3000 →</button>
        <button class="btn secondary" id="soundToggle">Activer le son</button>
      </div>
      <div class="socials">
        <a href="https://facebook.com" target="_blank"><i class="fab fa-facebook"></i></a>
        <a href="https://twitter.com" target="_blank"><i class="fab fa-twitter"></i></a>
        <a href="https://instagram.com" target="_blank"><i class="fab fa-instagram"></i></a>
        <a href="https://linkedin.com" target="_blank"><i class="fab fa-linkedin"></i></a>
      </div>
      <p style="font-size:14px;color:rgba(255,255,255,0.7);margin-top:12px">Redirection automatique dans <span id="count">8</span>s</p>
    </div>

    <div class="sparkle" style="left:8%;top:12%;width:18px;height:18px;background:radial-gradient(circle,#fff,#ffd1f0);border-radius:50%"></div>
    <div class="sparkle" style="right:7%;top:28%;width:12px;height:12px;background:radial-gradient(circle,#fff,#a29bff);border-radius:50%"></div>
    <div class="sparkle" style="left:20%;bottom:18%;width:10px;height:10px;background:radial-gradient(circle,#fff,#7ad0ff);border-radius:50%"></div>

    <footer class="note">© Boost3000 — Marketing féerique</footer>
  </div>

  <script>
    const target = 'https://boost3000.fr';
    let countdown = 8;
    const countEl = document.getElementById('count');
    const goBtn = document.getElementById('go');
    const soundToggle = document.getElementById('soundToggle');

    const timer = setInterval(()=>{
      countdown--;
      countEl.textContent = countdown;
      if(countdown<=0){
        clearInterval(timer);
        window.location.href = target;
      }
    },1000);

    goBtn.addEventListener('click', ()=>{window.location.href = target});

    const canvas = document.getElementById('particles');
    const ctx = canvas.getContext('2d');
    let W, H; function resize(){W=canvas.width=innerWidth;H=canvas.height=innerHeight} resize(); addEventListener('resize', resize);
    function rand(min,max){return Math.random()*(max-min)+min}
    const particles = [];
    for(let i=0;i<120;i++){particles.push({x:rand(0,W),y:rand(0,H),r:rand(0.6,3.2),vx:rand(-0.2,0.6),vy:rand(-0.6,0.6),alpha:rand(0.2,0.9),h:rand(180,320)})}
    function frame(){ctx.clearRect(0,0,W,H);for(let p of particles){p.x+=p.vx;p.y+=p.vy;if(p.x>W+20)p.x=-20;if(p.x<-20)p.x=W+20;if(p.y>H+20)p.y=-20;if(p.y<-20)p.y=H+20;ctx.beginPath();ctx.fillStyle='hsla('+p.h+',85%,'+(50+Math.sin(p.x*0.01+p.y*0.01)*8)+'%,'+(p.alpha*0.9)+')';ctx.arc(p.x,p.y,p.r,0,Math.PI*2);ctx.fill()}requestAnimationFrame(frame)}frame();

    let audioCtx=null; let master=null;
    function startMelody(){if(audioCtx)return;audioCtx=new (window.AudioContext||window.webkitAudioContext)();master=audioCtx.createGain();master.gain.value=0.12;master.connect(audioCtx.destination);const base=220;const seq=[0,3,7,10,14,17,21];let i=0;function playNote(){const osc=audioCtx.createOscillator();const env=audioCtx.createGain();osc.type='sine';const freq=base*Math.pow(2,seq[i%seq.length]/12);osc.frequency.value=freq;env.gain.value=0;osc.connect(env);env.connect(master);const now=audioCtx.currentTime;env.gain.setValueAtTime(0,now);env.gain.linearRampToValueAtTime(1,now+0.12);env.gain.exponentialRampToValueAtTime(0.001,now+2.2);osc.start(now);osc.stop(now+2.4);i++;setTimeout(()=>{if(audioCtx)playNote()},400+Math.random()*800)}playNote()}

    soundToggle.addEventListener('click', ()=>{if(!audioCtx){startMelody();soundToggle.textContent='Son activé — profitez'} else {audioCtx.close();audioCtx=null;master=null;soundToggle.textContent='Activer le son'}});
  </script>
</body>
</html>
]]

-- Permet à JS d’appeler Lua
web.addJavascriptInterface({
  redirect = function(url)
    activity.runOnUiThread(function()
      web.loadUrl(url) -- ouvre boost3000.fr dans la WebView
    end)
  end
}, "Android")

-- Charger le HTML
web.loadDataWithBaseURL(nil, html, "text/html", "utf-8", nil)
