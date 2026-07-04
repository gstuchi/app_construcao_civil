/* Globo-múndi em pontos — continentes reais via polígonos (zero imagem, 100% offline).
   Terra brilha, oceano é grade tênue. Gira devagar; para com aba oculta;
   estático com prefers-reduced-motion. */
'use strict';
(function(){
  const cv = document.getElementById('globe');
  if(!cv) return;
  const ctx = cv.getContext('2d');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---- continentes (lon,lat) — aproximados, validados em ASCII ---- */
  const CONTINENTS = [
    [[-168,66],[-140,70],[-125,71],[-110,72],[-95,72],[-80,68],[-75,62],[-58,50],[-65,45],[-74,40],[-80,32],[-81,25],[-90,19],[-97,16],[-105,20],[-111,24],[-117,33],[-124,41],[-128,50],[-140,60],[-155,58],[-165,60],[-168,66]],
    [[-52,60],[-42,60],[-22,70],[-18,76],[-30,82],[-58,80],[-68,76],[-60,66],[-52,60]],
    [[-79,9],[-70,12],[-60,9],[-52,4],[-44,-3],[-35,-6],[-38,-13],[-48,-26],[-56,-35],[-65,-41],[-71,-52],[-75,-48],[-73,-37],[-71,-18],[-77,-6],[-80,0],[-79,9]],
    [[-9,37],[-8,43],[-2,48],[0,52],[7,58],[12,56],[18,55],[25,58],[30,60],[40,66],[55,68],[60,60],[50,50],[40,47],[30,46],[25,40],[15,38],[5,36],[-9,37]],
    [[-17,15],[-10,25],[-6,35],[10,37],[20,32],[32,31],[35,22],[43,11],[51,12],[45,0],[40,-10],[35,-20],[32,-29],[25,-34],[18,-34],[14,-22],[12,-8],[8,0],[-8,5],[-13,9],[-17,15]],
    [[30,46],[40,47],[50,50],[60,60],[55,68],[70,73],[90,76],[110,77],[130,72],[145,70],[160,68],[178,66],[178,62],[162,58],[155,52],[142,46],[135,43],[128,39],[122,34],[120,26],[110,18],[103,8],[98,12],[92,20],[88,22],[80,12],[73,18],[68,24],[60,26],[50,28],[40,36],[33,40],[30,46]],
    [[114,-22],[117,-16],[124,-13],[133,-11],[142,-13],[147,-19],[151,-25],[153,-30],[148,-38],[139,-37],[131,-33],[122,-33],[114,-27],[114,-22]],
    [[95,5],[105,3],[115,0],[125,-3],[135,-5],[140,-8],[130,-9],[118,-9],[108,-7],[98,-2],[95,5]],
    [[130,32],[135,34],[140,36],[142,42],[144,44],[140,40],[136,35],[130,32]],
  ];
  function inPoly(lon,lat,poly){
    let inside=false;
    for(let i=0,j=poly.length-1;i<poly.length;j=i++){
      const xi=poly[i][0],yi=poly[i][1],xj=poly[j][0],yj=poly[j][1];
      if((yi>lat)!==(yj>lat) && lon < (xj-xi)*(lat-yi)/(yj-yi)+xi) inside=!inside;
    }
    return inside;
  }
  const isLand=(lon,lat)=> lat<-72 ? true : CONTINENTS.some(p=>inPoly(lon,lat,p));

  /* ---- pré-computa pontos na esfera (uma vez) ---- */
  const D2R = Math.PI/180;
  const land=[], ocean=[];
  const latStep = window.innerWidth<700 ? 2.2 : 1.7;   // grade densa (inspiração)
  for(let lat=-84; lat<=84; lat+=latStep){
    const cosL=Math.cos(lat*D2R);
    const lonStep=Math.max(latStep, latStep/Math.max(cosL,0.08));
    for(let lon=-180; lon<180; lon+=lonStep){
      const p={ x:cosL*Math.cos(lon*D2R), y:Math.sin(lat*D2R), z:cosL*Math.sin(lon*D2R) };
      (isLand(lon,lat) ? land : ocean).push(p);       // grade completa: esfera com silhueta
    }
  }

  let W,H,R,cx,cy;
  function resize(){
    const dpr=Math.min(1.75, window.devicePixelRatio||1);
    W=window.innerWidth; H=window.innerHeight;
    cv.width=W*dpr; cv.height=H*dpr;
    ctx.setTransform(dpr,0,0,dpr,0,0);
    R=Math.min(H*0.46, W*0.55);
    cx=W*0.80; cy=H*0.42;                    // esfera com curvatura visível, à direita
  }
  window.addEventListener('resize',resize);
  resize();

  function drawSet(pts, sin, cos, bright){
    for(const p of pts){
      const x=p.x*cos - p.z*sin;
      const z=p.x*sin + p.z*cos;
      if(z<0.02) continue;                    // só o hemisfério da frente
      const sx=cx+x*R, sy=cy-p.y*R;
      if(sx<-6||sx>W+6||sy<-6||sy>H+6) continue;
      const depth=z;                          // 0 borda → 1 centro-frente
      const a=bright ? 0.30+depth*0.62 : 0.10+depth*0.20;
      const s=bright ? 1.5+depth*1.7 : 1.1+depth*1.0;
      ctx.fillStyle = bright
        ? (depth>0.7 ? `rgba(160,196,255,${a})` : `rgba(96,140,255,${a})`)
        : `rgba(78,114,224,${a})`;
      ctx.fillRect(sx-s/2, sy-s/2, s, s);
    }
  }

  function draw(t){
    ctx.clearRect(0,0,W,H);
    // halo atmosférico
    const g=ctx.createRadialGradient(cx,cy,R*0.4,cx,cy,R*1.35);
    g.addColorStop(0,'rgba(58,100,245,0.26)');
    g.addColorStop(0.7,'rgba(58,100,245,0.08)');
    g.addColorStop(1,'rgba(58,100,245,0)');
    ctx.fillStyle=g;
    ctx.fillRect(0,0,W,H);
    // aro da esfera — dá a leitura de "planeta"
    ctx.beginPath();
    ctx.arc(cx,cy,R*1.01,0,6.2832);
    ctx.strokeStyle='rgba(100,140,255,0.20)';
    ctx.lineWidth=1.2;
    ctx.stroke();
    const sin=Math.sin(t), cos=Math.cos(t);
    drawSet(ocean,sin,cos,false);
    drawSet(land,sin,cos,true);
  }

  if(reduced){ draw(1.2); return; }

  let angle=1.2, last=performance.now(), running=true;
  function loop(now){
    if(!running) return;
    angle += (now-last)*0.00004;              // giro calmo
    last=now;
    draw(angle);
    requestAnimationFrame(loop);
  }
  document.addEventListener('visibilitychange',()=>{
    running=!document.hidden;
    if(running){ last=performance.now(); requestAnimationFrame(loop); }
  });
  requestAnimationFrame(loop);
})();
