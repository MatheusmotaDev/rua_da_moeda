const http=require('http'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../build/web');
const types={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.svg':'image/svg+xml','.wav':'audio/wav','.ttf':'font/ttf','.otf':'font/otf'};
http.createServer((req,res)=>{
  let file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
  if(file!==root&&!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
  if(file===root||file.endsWith(path.sep))file=path.join(file,'index.html');
  fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end('Not found');return;}res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});res.end(data);});
}).listen(8080,'127.0.0.1',()=>console.log('Rua da Moeda: http://127.0.0.1:8080'));
