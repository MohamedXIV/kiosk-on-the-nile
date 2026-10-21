import {chromium} from 'playwright';
import {spawn} from 'node:child_process';
import {mkdir} from 'node:fs/promises';
const server=spawn('python3',['tools/web/serve.py',process.cwd()],{stdio:['ignore','pipe','inherit']});
let browser;
try {
 const port=await new Promise((resolve,reject)=>{server.stdout.once('data',b=>resolve(Number(String(b).trim())));server.once('exit',c=>reject(Error(String(c))));});
 browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 await page.route('https://fonts.googleapis.com/**',route=>route.fulfill({contentType:'text/css',body:`@font-face{font-family:Cairo;font-weight:100 1000;src:url('http://127.0.0.1:${port}/assets/fonts/Cairo.ttf') format('truetype')}`}));
 await page.goto(`http://127.0.0.1:${port}/kiosk_on_the_nile_2d_three_quarter_top_down.html`);
 await page.evaluate(()=>document.fonts.ready);
 await page.locator('#btn-start-game').click();
 await mkdir('/tmp/kiosk-port-evidence',{recursive:true});
 for(const room of ['kiosk','rooftop']) {
  await page.evaluate(room=>{
   const app=window.kiosk2DApp;
   app.state.location=room==='kiosk'?'KIOSK':'ROOFTOP';
   app.state.timeMinutes=930;
   app.state.kioskOpen=false;
   app.updateClockAndNeeds=()=>{};
   app.updateSocialDirector=()=>{};
   app.clearAllNPCs();
   app.syncSceneToLocation();
   for(const id of ['ui-layer','world-overlays','toast-container'])document.getElementById(id).style.display='none';
  },room);
  await page.waitForTimeout(100);
  await page.screenshot({path:`/tmp/kiosk-port-evidence/html-${room}.png`});
 }
 console.log('HTML_REFERENCE_CAPTURED: unchanged source, common viewport and fixed afternoon state');
} finally {await browser?.close();server.kill();}
