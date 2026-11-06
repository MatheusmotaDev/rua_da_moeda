// Original deterministic chiptune compositions and effects; no samples.
const fs = require('fs');
const path = require('path');
const target = path.join(__dirname, '..', 'assets', 'audio');
fs.mkdirSync(target, { recursive: true });
const rate=22050;
function wave(name,seconds,sample) {
  const n=Math.floor(rate*seconds),b=Buffer.alloc(44+n*2);
  b.write('RIFF');b.writeUInt32LE(36+n*2,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(n*2,40);
  for(let i=0;i<n;i++)b.writeInt16LE(Math.round(Math.max(-1,Math.min(1,sample(i/rate,i)))*28000),44+i*2);
  fs.writeFileSync(path.join(target,name+'.wav'),b);
}
const hz=n=>440*Math.pow(2,(n-69)/12);
const pulse=(f,t)=>Math.sin(2*Math.PI*f*t)>0?.4:-.4;
function music(name,notes,tempo) {
  const beat=60/tempo/2,duration=notes.length*beat;
  wave(name,duration,(t,i)=>{
    const k=Math.floor(t/beat),u=t%beat,env=Math.min(1,u/.012)*Math.max(0,1-u/beat);
    const melody=notes[k]>=0?pulse(hz(notes[k]),t)*env*.34:0;
    const bass=Math.sin(2*Math.PI*hz([48,53,55,48][Math.floor(k/8)%4])*t)*Math.exp(-u*7)*.15;
    const sync=[0,3,6].includes(k%8)?Math.sin(2*Math.PI*(82-35*u/beat)*u)*Math.exp(-u*30)*.15:0;
    const noise=((Math.sin(i*127.1)*43758.5453)%1)*Math.exp(-u*80)*.035;
    return melody+bass+sync+noise;
  });
}
music('marco_zero',[72,76,79,81,79,76,74,72,74,77,81,84,81,79,77,74,76,79,83,86,84,83,79,76,79,76,74,71,72,-1,67,-1],112);
music('interior',[72,-1,76,79,76,-1,74,72,69,-1,72,77,76,-1,72,69,71,-1,74,79,77,-1,74,71,72,76,79,76,72,-1,67,-1],90);
wave('interact',.12,t=>Math.sin(2*Math.PI*660*t)*Math.exp(-t*35)*.25);
wave('step',.06,(t,i)=>Math.sin(i*19.87)*Math.exp(-t*100)*.08);
wave('success',.65,t=>{const k=Math.min(3,Math.floor(t/.15));return pulse(hz([72,76,79,84][k]),t)*Math.exp(-(t% .15)*10)*.45;});
console.log('Generated 5 original WAV assets.');
