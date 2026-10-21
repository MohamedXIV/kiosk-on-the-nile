import {chromium} from 'playwright';
import {spawn} from 'node:child_process';
import {mkdir,readFile,writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const args=process.argv.slice(2);
const get=(key,fallback)=>args.includes(key)?args[args.indexOf(key)+1]:fallback;
const build=get('--build','/tmp/kiosk-port-web');
const scenario=get('--scenario','ink');
const server=spawn('python3',['tools/web/serve.py',build],{stdio:['ignore','pipe','inherit']});
let browser;
const originalClock=await readFile(`${build}/content/time.json`,"utf8");
const changedClock=JSON.parse(originalClock);changedClock.minutes_per_second=3;
await writeFile(`${build}/content/time.json`,JSON.stringify(changedClock));
try {
 const port=await new Promise((resolve,reject)=>{server.stdout.once('data',b=>resolve(Number(String(b).trim())));server.once('exit',c=>reject(Error(`HTTP server exited ${c}`)));});
 browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const page=await context.newPage();
 const errors=[];
 page.on('response',r=>{if(r.status()>=400) console.error('HTTP_FAILURE',r.status(),r.url());});
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error')errors.push({message:m.text(),location:m.location()});});
 const response=await page.goto(`http://127.0.0.1:${port}/index.html?qa=${scenario}`);
 assert.equal(response.status(),200,"exported qualification must exist");
 if(scenario==='spatial') {
  await page.waitForFunction(()=>window.spatialStatus?.ready || window.inkStatus?.phase==='ready',{},{timeout:45000});
  assert.equal(await page.evaluate(()=>window.spatialStatus?.ready),true,'spatial scene must boot');
 } else {
 await page.waitForFunction(()=>window.inkStatus?.phase==='ready',{},{timeout:45000});
 assert.equal(await page.evaluate(()=>window.inkStatus.rate),3,"sidecar JSON must override packed defaults without rebuilding");
 await page.mouse.click(640,265);
 await page.waitForFunction(()=>window.inkStatus?.phase==='choice');
 assert.equal(await page.evaluate(()=>window.inkStatus.choices),2);
 await page.waitForTimeout(1500);
 await page.reload();
 await page.waitForFunction(()=>window.inkStatus?.phase==='choice' && window.inkStatus.restored===true,{},{timeout:45000});
 await page.mouse.click(640,380);
 await page.waitForFunction(()=>window.inkStatus?.phase==='done');
 assert.equal(await page.evaluate(()=>window.inkStatus.text),'تسلم يا معلم.');
 }
 assert.deepEqual(errors,[]);
 await mkdir('/tmp/kiosk-port-evidence',{recursive:true});
 await page.screenshot({path:`/tmp/kiosk-port-evidence/${scenario}-arabic.png`});
 console.log(scenario==='spatial'?'SPATIAL_BROWSER_PASS: native character and counter depth': 'INK_BROWSER_PASS: real Ink, Arabic choice, persistent hard reload');
} finally {await writeFile(`${build}/content/time.json`,originalClock);await browser?.close();server.kill();}
