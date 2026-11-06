// Optional local browser smoke check; Node 22+ and a Chromium CDP port required.
const fs=require('fs'),path=require('path');
const output=path.join(__dirname,'../output');fs.mkdirSync(output,{recursive:true});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 const tabs=await(await fetch('http://127.0.0.1:9222/json')).json();
 const page=tabs.find(t=>t.type==='page'); const ws=new WebSocket(page.webSocketDebuggerUrl);
 await new Promise((r,j)=>{ws.onopen=r;ws.onerror=j;});
 let serial=0;const pending=new Map(),errors=[];
 ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);if(p){pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result);}}else if(m.method==='Runtime.exceptionThrown'){errors.push(m.params.exceptionDetails);}};
 const send=(method,params={})=>new Promise((resolve,reject)=>{const id=++serial;pending.set(id,{resolve,reject});ws.send(JSON.stringify({id,method,params}));});
 await send('Page.enable');await send('Runtime.enable');
 await send('Emulation.setDeviceMetricsOverride',{width:1280,height:800,deviceScaleFactor:1,mobile:false});
 await send('Page.navigate',{url:'http://127.0.0.1:8080'});await delay(1000);
 await send('Runtime.evaluate',{expression:'localStorage.clear()'});await send('Page.reload',{ignoreCache:true});await delay(10000);
 const shot=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(path.join(output,'browser-menu.png'),Buffer.from(shot.data,'base64'));
 const info=await send('Runtime.evaluate',{expression:'JSON.stringify({title:document.title,canvas:document.querySelectorAll("canvas").length,body:document.body.innerText.slice(0,600)})',returnByValue:true});
 async function click(x,y){await send('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});await send('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});await delay(700);}
 await click(250,495);
 const creation=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(path.join(output,'browser-creation.png'),Buffer.from(creation.data,'base64'));
 await click(250,575);await delay(2500);
 const world=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(path.join(output,'browser-world.png'),Buffer.from(world.data,'base64'));
 await send('Input.dispatchKeyEvent',{type:'keyDown',key:'d',code:'KeyD',windowsVirtualKeyCode:68});await delay(280);await send('Input.dispatchKeyEvent',{type:'keyUp',key:'d',code:'KeyD',windowsVirtualKeyCode:68});await delay(200);
 await send('Input.dispatchKeyEvent',{type:'keyDown',key:'e',code:'KeyE',windowsVirtualKeyCode:69});await send('Input.dispatchKeyEvent',{type:'keyUp',key:'e',code:'KeyE',windowsVirtualKeyCode:69});await delay(500);
 const dialog=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(path.join(output,'browser-dialogue.png'),Buffer.from(dialog.data,'base64'));
 console.log(JSON.stringify({info:info.result.value,errors},null,2));ws.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
