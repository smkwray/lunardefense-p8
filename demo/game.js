// Lunar Defense — Browser Port (from PICO-8 cart v6.3)
// Complete faithful JS port of lunar_defense.p8

// ===================================================================
// 1. PICO-8 API SHIM
// ===================================================================

const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
const IMG = ctx.createImageData(128, 128);
const PIX = IMG.data;

// PICO-8 16-color palette (RGBA)
const PAL = [
  [0,0,0],       // 0 black
  [29,43,83],    // 1 dark blue
  [126,37,83],   // 2 dark purple
  [0,135,81],    // 3 dark green
  [171,82,54],   // 4 brown
  [95,87,79],    // 5 dark gray
  [194,195,199], // 6 light gray
  [255,241,232], // 7 white
  [255,0,77],    // 8 red
  [255,163,0],   // 9 orange
  [255,236,39],  // 10 yellow
  [0,228,54],    // 11 green
  [41,173,255],  // 12 blue
  [131,118,156], // 13 lavender
  [255,119,168], // 14 pink
  [255,204,170], // 15 peach
];

function cls(c) {
  c = c || 0;
  const r = PAL[c][0], g = PAL[c][1], b = PAL[c][2];
  for (let i = 0; i < 128*128; i++) {
    PIX[i*4] = r; PIX[i*4+1] = g; PIX[i*4+2] = b; PIX[i*4+3] = 255;
  }
}

function pset(x, y, c) {
  x = Math.floor(x); y = Math.floor(y);
  if (x < 0 || x > 127 || y < 0 || y > 127) return;
  const i = (y * 128 + x) * 4;
  PIX[i] = PAL[c][0]; PIX[i+1] = PAL[c][1]; PIX[i+2] = PAL[c][2]; PIX[i+3] = 255;
}

function line(x0, y0, x1, y1, c) {
  x0=Math.floor(x0); y0=Math.floor(y0); x1=Math.floor(x1); y1=Math.floor(y1);
  let dx = Math.abs(x1-x0), dy = Math.abs(y1-y0);
  let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
  let err = dx - dy;
  while (true) {
    pset(x0, y0, c);
    if (x0 === x1 && y0 === y1) break;
    let e2 = 2*err;
    if (e2 > -dy) { err -= dy; x0 += sx; }
    if (e2 < dx) { err += dx; y0 += sy; }
  }
}

function circ(cx, cy, r, c) {
  cx=Math.floor(cx); cy=Math.floor(cy); r=Math.floor(r);
  if (r < 0) return;
  let x = r, y = 0, err = 1 - r;
  while (x >= y) {
    pset(cx+x,cy+y,c); pset(cx-x,cy+y,c);
    pset(cx+x,cy-y,c); pset(cx-x,cy-y,c);
    pset(cx+y,cy+x,c); pset(cx-y,cy+x,c);
    pset(cx+y,cy-x,c); pset(cx-y,cy-x,c);
    y++;
    if (err < 0) { err += 2*y+1; }
    else { x--; err += 2*(y-x)+1; }
  }
}

function circfill(cx, cy, r, c) {
  cx=Math.floor(cx); cy=Math.floor(cy); r=Math.floor(r);
  if (r < 0) return;
  if (r === 0) { pset(cx,cy,c); return; }
  let x = r, y = 0, err = 1 - r;
  while (x >= y) {
    for (let i = cx-x; i <= cx+x; i++) { pset(i,cy+y,c); pset(i,cy-y,c); }
    for (let i = cx-y; i <= cx+y; i++) { pset(i,cy+x,c); pset(i,cy-x,c); }
    y++;
    if (err < 0) { err += 2*y+1; }
    else { x--; err += 2*(y-x)+1; }
  }
}

function rect(x0,y0,x1,y1,c) {
  line(x0,y0,x1,y0,c); line(x1,y0,x1,y1,c);
  line(x1,y1,x0,y1,c); line(x0,y1,x0,y0,c);
}

function rectfill(x0,y0,x1,y1,c) {
  x0=Math.floor(x0); y0=Math.floor(y0); x1=Math.floor(x1); y1=Math.floor(y1);
  if (x0>x1) { let t=x0; x0=x1; x1=t; }
  if (y0>y1) { let t=y0; y0=y1; y1=t; }
  for (let yy=y0; yy<=y1; yy++) for (let xx=x0; xx<=x1; xx++) pset(xx,yy,c);
}

// PICO-8 font: 4px wide, 6px tall (3x5 glyph in 4x6 cell)
// Each glyph is 5 rows of 3-bit patterns (stored as array of ints, MSB=left)
const FONT_DATA = {};
(function(){
  // Accurate PICO-8 uppercase font glyphs (3px wide, 5px tall)
  const g = {
    'a':[7,5,7,5,5],'b':[6,5,6,5,6],'c':[7,4,4,4,7],'d':[6,5,5,5,6],
    'e':[7,4,6,4,7],'f':[7,4,6,4,4],'g':[7,4,5,5,7],'h':[5,5,7,5,5],
    'i':[7,2,2,2,7],'j':[3,1,1,5,7],'k':[5,6,4,6,5],'l':[4,4,4,4,7],
    'm':[5,7,7,5,5],'n':[5,7,7,7,5],'o':[7,5,5,5,7],'p':[7,5,7,4,4],
    'q':[7,5,5,7,1],'r':[6,5,6,5,5],'s':[7,4,7,1,7],'t':[7,2,2,2,2],
    'u':[5,5,5,5,7],'v':[5,5,5,5,2],'w':[5,5,7,7,5],'x':[5,5,2,5,5],
    'y':[5,5,7,2,2],'z':[7,1,2,4,7],
    '0':[7,5,5,5,7],'1':[6,2,2,2,7],'2':[7,1,7,4,7],'3':[7,1,7,1,7],
    '4':[5,5,7,1,1],'5':[7,4,7,1,7],'6':[7,4,7,5,7],'7':[7,1,1,1,1],
    '8':[7,5,7,5,7],'9':[7,5,7,1,7],
    ' ':[0,0,0,0,0],'.':[0,0,0,0,2],',':[0,0,0,2,4],'-':[0,0,7,0,0],
    '+':[0,2,7,2,0],':':[0,2,0,2,0],'!':[2,2,2,0,2],'/':[1,1,2,4,4],
    '(':[1,2,2,2,1],')':[4,2,2,2,4],'>':[4,2,1,2,4],'<':[1,2,4,2,1],
    '=':[0,7,0,7,0],'?':[7,1,2,0,2],'_':[0,0,0,0,7],"'":[2,2,0,0,0],
    '"':[5,5,0,0,0],
  };
  for (let ch in g) FONT_DATA[ch] = g[ch];
})();

function print(s, x, y, c) {
  s = String(s);
  x = Math.floor(x); y = Math.floor(y);
  for (let i = 0; i < s.length; i++) {
    let ch = s[i].toLowerCase();
    let g = FONT_DATA[ch];
    if (g) {
      for (let row = 0; row < 5; row++) {
        let bits = g[row];
        if (bits & 4) pset(x, y + row, c);
        if (bits & 2) pset(x + 1, y + row, c);
        if (bits & 1) pset(x + 2, y + row, c);
      }
    }
    x += 4;
  }
}

function print_center(s, y, col) {
  print(s, 64 - s.length * 2, y, col);
}

// Math shims — PICO-8 trig uses turns (0..1), NOT radians
function flr(x) { return Math.floor(x); }
function rnd(x) { return Math.random() * (x || 1); }
function mid(a, b, c) {
  let arr = [a,b,c].sort((x,y)=>x-y);
  return arr[1];
}
function sgn(x) { return x < 0 ? -1 : 1; }
function p8cos(t) { return Math.cos(t * Math.PI * 2); }
function p8sin(t) { return -Math.sin(t * Math.PI * 2); } // PICO-8 sin is inverted
function p8atan2(dx, dy) {
  // PICO-8 atan2(dx,dy) returns turns 0..1, with inverted Y
  let a = Math.atan2(-dy, dx) / (Math.PI * 2);
  return ((1 - a) % 1 + 1) % 1;
}
function p8sqrt(x) { return Math.sqrt(Math.max(0, x)); }
function p8abs(x) { return Math.abs(x); }
function p8min(a,b) { return Math.min(a,b); }
function p8max(a,b) { return Math.max(a,b); }

// Alias cos/sin/atan2/sqrt/abs/min/max to P8 versions for port consistency
const cos = p8cos, sin = p8sin, atan2 = p8atan2, sqrt = p8sqrt, abs = p8abs;
const min = p8min, max = p8max;

// Array helpers (PICO-8 style)
function add(t, v) { t.push(v); return v; }
function del(t, v) {
  let idx = t.indexOf(v);
  if (idx >= 0) t.splice(idx, 1);
}
function all(t) { return [...t]; }

// sub(s, i, j) — PICO-8 is 1-indexed
function sub(s, i, j) {
  if (j === undefined) return s.substring(i-1);
  return s.substring(i-1, j);
}

// Input
const _btn_state = [false,false,false,false,false,false,false];
const _btnp_state = [false,false,false,false,false,false,false];
const _btn_prev = [false,false,false,false,false,false,false];

function btn(n) { return _btn_state[n]; }
function btnp(n) { return _btnp_state[n]; }

function _update_input() {
  for (let i = 0; i < 7; i++) {
    _btnp_state[i] = _btn_state[i] && !_btn_prev[i];
    _btn_prev[i] = _btn_state[i];
  }
}

document.addEventListener('keydown', e => {
  switch(e.key) {
    case 'ArrowLeft': _btn_state[0]=true; break;
    case 'ArrowRight': _btn_state[1]=true; break;
    case 'ArrowUp': _btn_state[2]=true; break;
    case 'ArrowDown': _btn_state[3]=true; break;
    case 'z': case 'Z': case 'c': case 'C': case 'n': case 'N': _btn_state[4]=true; break;
    case 'x': case 'X': case 'v': case 'V': case 'm': case 'M': _btn_state[5]=true; break;
    case 'Enter': case 'p': case 'P': _btn_state[6]=true; break;
  }
  if (['ArrowLeft','ArrowRight','ArrowUp','ArrowDown',' '].includes(e.key)) e.preventDefault();
});

document.addEventListener('keyup', e => {
  switch(e.key) {
    case 'ArrowLeft': _btn_state[0]=false; break;
    case 'ArrowRight': _btn_state[1]=false; break;
    case 'ArrowUp': _btn_state[2]=false; break;
    case 'ArrowDown': _btn_state[3]=false; break;
    case 'z': case 'Z': case 'c': case 'C': case 'n': case 'N': _btn_state[4]=false; break;
    case 'x': case 'X': case 'v': case 'V': case 'm': case 'M': _btn_state[5]=false; break;
    case 'Enter': case 'p': case 'P': _btn_state[6]=false; break;
  }
});

// ===================================================================
// 2. WEB AUDIO ENGINE
// ===================================================================

let audioCtx = null;
let audioInitialized = false;

const SFX_DATA = [
  "000400001035018350203402833000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200002064314625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000600000866004650026400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000300002815030150341400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000500001865014650106400c63000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200003005038050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000500002066314653086450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "0014000015670106700c6730966304653000730007000070000600006000050000550004500045000350002500025000150000000000000000000000000000000000000000000000000000000000000000000000",
  "000500001866010653086350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00030000301502c153201350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000300002844034445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00040000102400c245000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00200000216701c6701867315673106730c6630967000070096600007009660000600965000060000600006000050000500005000055000450004500035000350002500025000150001500000000000000000000",
  "000200003024120235000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000300001065308053040350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00040000184501c4501f4502445024445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00140000090400000010040000000904000000100400000005040000000c0400000005040000000c040000000c0400000013040000000c04000000130400000007040000000e0400000007040000000e04000000",
  "0014000018520000001c5200000018520000001c5200000015520000001852000000155200000018520000001c520000001f520000001c520000001f5200000017520000001a5200000017520000001a52000000",
  "001400001c450000002145000000244500000021450000001d450000002145000000244500000021450000001c450000001f4500000024450000001f450000001a450000001f4500000023450000001f45000000",
  "001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00140000090400000010040000000904000000100400000005040000000c0400000005040000000c040000000c0400000010040000000c04000000100400000004040000000b0400000004040000000b04000000",
  "0014000018520000001c5200000018520000001c5200000015520000001852000000155200000018520000001c520000001f520000001c520000001f520000001452000000175200000014520000001752000000",
  "001400001c4501f45021450244502845024450214501f4501d450214502445028450294502845024450214501f4502345024450284502b4502845024450234502645023450214502045021450234502445023450",
  "0014000000000211200000024120000002812000000241200000021120000002412000000291200000024120000001f120000002412000000281200000024120000001f120000002312000000261200000023120",
  "001400001c450000002145000000244502345021450000001d450000002145000000244502345021450000001c450000001f4500000024450234501f450000001a450000001f4500000023450214501f45000000",
  "001400001c450000001f45021450244500000021450000001d450000001f45021450244500000021450000001c450000001d4501f45024450000001f450000001a450000001d4501f45023450000001f45000000",
  "001400001c450000002145000000244500000021450284501d450000002145000000244500000021450294501c450000001f4500000024450000001f450284501a450000001f4500000023450000001f45000000",
  "0014000021450244502845024450214501f4501c4501f45021450244502945024450214501d450214502445024450284502b4502845024450234501f450234502345026450234502145020450214502345026450",
  "001400001c450244501c45021450244502845024450214501d450244501d45021450244502945024450214501c450244501f45024450284502b45028450244501a450234501a4501f4502345026450234501f450",
  "001400002845024450214501f4501c4501f45021450244502945024450214501f4501d4502145024450284502b4502845024450234501f4502345024450284502645023450214501f4501a4501f4502145023450",
  "0010000009060000000000009050000000000004060000000c0600000000000000000905000000000000000009060000000000009050000000000007060000000c06000000000000000010050000000e05500000",
  "001000001863000000000000000018620000000000000000186300000000000000001862000000000000000018630000000000000000186200000000000000001863000000000000000018620000000000000000",
  "001000000906000000000000000000000090500000004060000000c0600000000000090500000004050000000906000000000000000000000070500000009060000000c060000000000000000000000e05010055",
  "001000001863000000000000000000000000000964300000186200000000000000000000000000096430000018630000000000000000000000000009643000001862000000000000000018630000000965300000",
  "0010000009060000000705000000040600000000000000000c0600000000000090500000000000000000000009060000000000004050000000000007060000000906000000000000000000000000000000000000",
  "001000001863000000000000000018620000000000000000186300000000000000001862000000000000000018630000000000000000186200000000000000001863000000000000000018630000001864000000",
  "0010000009260000000925000000042600925000000042600c2600000009250000000426000000092500000009260000000925000000072600925000000072600c260000000e2500000010260000000e2500c255",
  "001000001864000000186200000018630000000000009643186300000018620000001864000000000000965318640000001862000000186300000000000096431863000000186200000018640000000000009663",
  "0010000009260000000000015250000000000009260000001026000000000000426000000000000925000000092600000000000152500000000000072600000010260000000e250000000c260000000925000000",
  "001000001863000000000001863000000186200000000000186300000000000000000965300000000000000018630000000000018630000001862000000000001863000000000001864009653000000000000000",
  "0010000009260000000925000000042600000009250000000c2600000009250000000426000000072500000009260000000925000000042600000009250000000c260000000e2500000010260000000926300000",
  "00100000186400000018630000001c64000000000000000018630000001c6300965300000000000000000000186400000018630000001c6400000000000000001c64018630096530000000000000001864009653",
  "001000000936009350000000936000000000000436004350000000936000000000000935009360000000935009360093500000009360000000000007360073500000009360000000000010350000000c35009360",
  "001000001c64018620000001863018620000001c64018620000001863018620000001c6401862000000096531c64018620000001863018620000001c64018620000001863018620000001c6501c6401c63009663",
  "0010000009360093500000009360000000000003360033500000009360000000000009350093600000003360093600935000000093600000000000043600735000000093600000000000103600f3500c35009360",
  "001000001c640000001c6301c6200000018630000001c6401c6200000000000186300965300000186201c6401c630000001c6301c6200000018630000001c6401c62000000186301c64009663000001c65009653",
  "001000000936000000093500000007360000000735000000043600000004350000000236000000043500000009360000000935000000073600000007350000000436000000033600000004360000000936300000",
  "001000001c6401c630186201c6401c630186201c640096531c6501c6401c6301c6401c650096631c65009663",
  "000200000e042114320c0320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200000b140091300d1330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200001035014340183400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200001834015340113450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000200000207004063000530004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000100000c14110151131511814000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000800000007300073000700006000060000500004500035000250001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "0002000015670106730c6630965504635006250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000600000764004740026300073500625007250061500715000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "00200000216701c67015673106730c663096530007000070000700007000070000700006000060000600005000050000550004500045000350003500025000250001500015000000000000000000000000000000",
  "000200001c4301f535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "000100001533018330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
];

const MUSIC_DATA = [
  {flags:1, ch:[0x10,0x11,0x12,0x13]},
  {flags:0, ch:[0x14,0x15,0x16,0x17]},
  {flags:0, ch:[0x10,0x11,0x18,0x13]},
  {flags:0, ch:[0x14,0x15,0x1b,0x17]},
  {flags:0, ch:[0x10,0x11,0x19,0x13]},
  {flags:0, ch:[0x14,0x15,0x1c,0x17]},
  {flags:0, ch:[0x10,0x11,0x1a,0x13]},
  {flags:2, ch:[0x14,0x15,0x1d,0x17]},
  {flags:0, ch:[0x1e,0x1f,null,null]},
  {flags:0, ch:[0x20,0x1f,null,null]},
  {flags:0, ch:[0x1e,0x21,null,null]},
  {flags:4, ch:[0x22,0x23,null,null]},
  {flags:0, ch:[0x22,0x1f,null,null]},
  {flags:0, ch:[0x20,0x23,null,null]},
  {flags:0, ch:[0x22,0x21,null,null]},
  {flags:4, ch:[0x1e,0x23,null,null]},
  {flags:0, ch:[0x24,0x25,null,null]},
  {flags:0, ch:[0x26,0x25,null,null]},
  {flags:0, ch:[0x24,0x27,null,null]},
  {flags:4, ch:[0x28,0x29,null,null]},
  {flags:0, ch:[0x26,0x27,null,null]},
  {flags:0, ch:[0x28,0x25,null,null]},
  {flags:0, ch:[0x28,0x27,null,null]},
  {flags:4, ch:[0x24,0x29,null,null]},
  {flags:0, ch:[0x2a,0x2b,null,null]},
  {flags:0, ch:[0x2c,0x2b,null,null]},
  {flags:0, ch:[0x2a,0x2d,null,null]},
  {flags:4, ch:[0x2e,0x2f,null,null]},
  {flags:0, ch:[0x2c,0x2d,null,null]},
  {flags:0, ch:[0x2e,0x2b,null,null]},
  {flags:0, ch:[0x2e,0x2d,null,null]},
  {flags:4, ch:[0x2c,0x2f,null,null]},
];

// Parsed SFX cache
let parsedSFX = [];

function parseSFXData() {
  parsedSFX = [];
  for (let i = 0; i < SFX_DATA.length; i++) {
    const raw = SFX_DATA[i];
    const speed = parseInt(raw.substring(2,4), 16);
    const loopStart = parseInt(raw.substring(4,6), 16);
    const loopEnd = parseInt(raw.substring(6,8), 16);
    const notes = [];
    for (let n = 0; n < 32; n++) {
      const off = 8 + n * 5;
      if (off + 5 > raw.length) { notes.push({pitch:0,waveform:0,volume:0,effect:0}); continue; }
      const noteStr = raw.substring(off, off+5);
      const pitch = parseInt(noteStr.substring(0,2), 16);
      const waveform = parseInt(noteStr[2], 16);
      const volume = parseInt(noteStr[3], 16);
      const effect = parseInt(noteStr[4], 16);
      notes.push({pitch, waveform, volume, effect});
    }
    parsedSFX.push({speed, loopStart, loopEnd, notes});
  }
}

function sfx(n) {
  if (!audioCtx || n < 0 || n >= parsedSFX.length) return;
  const s = parsedSFX[n];
  if (!s) return;
  const now = audioCtx.currentTime;
  let noteCount = 0;
  for (let i = 0; i < s.notes.length; i++) {
    if (s.notes[i].volume > 0) noteCount = i + 1;
  }
  if (noteCount === 0) return;
  const tickDur = s.speed / 120;
  for (let i = 0; i < noteCount; i++) {
    const note = s.notes[i];
    if (note.volume === 0) continue;
    const freq = 65.41 * Math.pow(2, note.pitch / 12);
    const vol = note.volume / 7 * 0.08;
    const startTime = now + i * tickDur;
    const dur = tickDur * 0.9;
    if (note.waveform === 6) {
      const bufSize = Math.floor(audioCtx.sampleRate * dur);
      if (bufSize <= 0) continue;
      const buf = audioCtx.createBuffer(1, bufSize, audioCtx.sampleRate);
      const data = buf.getChannelData(0);
      let last = 0;
      const cutoff = Math.min(1, freq / 2000);
      for (let j = 0; j < bufSize; j++) {
        const white = Math.random() * 2 - 1;
        last = last + cutoff * (white - last);
        data[j] = last;
      }
      const src = audioCtx.createBufferSource();
      src.buffer = buf;
      const gain = audioCtx.createGain();
      gain.gain.setValueAtTime(vol, startTime);
      gain.gain.linearRampToValueAtTime(0, startTime + dur);
      src.connect(gain).connect(audioCtx.destination);
      src.start(startTime);
      src.stop(startTime + dur);
    } else {
      const osc = audioCtx.createOscillator();
      const waveTypes = ['triangle','sawtooth','sawtooth','square','square','sine','sine','sawtooth'];
      osc.type = waveTypes[note.waveform] || 'triangle';
      osc.frequency.setValueAtTime(freq, startTime);
      if (note.effect === 1) {
        const vib = freq * 0.02;
        osc.frequency.linearRampToValueAtTime(freq + vib, startTime + dur*0.25);
        osc.frequency.linearRampToValueAtTime(freq - vib, startTime + dur*0.75);
        osc.frequency.linearRampToValueAtTime(freq, startTime + dur);
      } else if (note.effect === 2 && i < noteCount - 1) {
        const nextFreq = 65.41 * Math.pow(2, s.notes[i+1].pitch / 12);
        osc.frequency.linearRampToValueAtTime(nextFreq, startTime + dur);
      }
      const gain = audioCtx.createGain();
      gain.gain.setValueAtTime(vol, startTime);
      gain.gain.linearRampToValueAtTime(vol * 0.3, startTime + dur * 0.8);
      gain.gain.linearRampToValueAtTime(0, startTime + dur);
      osc.connect(gain).connect(audioCtx.destination);
      osc.start(startTime);
      osc.stop(startTime + dur + 0.01);
    }
  }
}

// Music system
let currentMusicPattern = -1;
let musicTimeout = null;
let musicPlaying = false;
let musicLoopStart = -1;

function music(n, fade) {
  if (musicTimeout) { clearTimeout(musicTimeout); musicTimeout = null; }
  if (n < 0) { currentMusicPattern = -1; musicPlaying = false; return; }
  currentMusicPattern = n;
  musicPlaying = true;
  musicLoopStart = n;
  for (let i = n; i >= 0; i--) {
    if (i < MUSIC_DATA.length && (MUSIC_DATA[i].flags & 1)) { musicLoopStart = i; break; }
  }
  playMusicPattern(n);
}

function playMusicPattern(n) {
  if (!musicPlaying || n < 0 || n >= MUSIC_DATA.length) { musicPlaying = false; currentMusicPattern = -1; return; }
  const pat = MUSIC_DATA[n];
  currentMusicPattern = n;
  let maxDur = 0;
  for (let ch = 0; ch < 4; ch++) {
    const sfxIdx = pat.ch[ch];
    if (sfxIdx === null || sfxIdx >= parsedSFX.length) continue;
    sfx(sfxIdx);
    const s = parsedSFX[sfxIdx];
    if (s) {
      let nc = 0;
      for (let j = 0; j < s.notes.length; j++) { if (s.notes[j].volume > 0) nc = j+1; }
      maxDur = Math.max(maxDur, nc * s.speed / 120);
    }
  }
  if (maxDur < 0.1) maxDur = 2;
  musicTimeout = setTimeout(() => {
    if (!musicPlaying) return;
    if (pat.flags & 4) { musicPlaying = false; currentMusicPattern = -1; return; }
    if (pat.flags & 2) { playMusicPattern(musicLoopStart); }
    else { playMusicPattern(n + 1); }
  }, maxDur * 1000);
}

function stat(n) {
  if (n === 54) return currentMusicPattern;
  return 0;
}

// ===================================================================
// 3. GAME STATE & DATA
// ===================================================================

let moon_x=64, moon_y=64, moon_r=9;
let earth_orbit_r=54, earth_r=9;
let earth_theta=0.029, earth_omega=0.00135;
let earth_x=64, earth_y=64;
let earth_spin=0;
let earth_core_hp=5, earth_core_exposed=false;
let module_ring_r=13, lunar_orbit_r=22;
let moon_craters=[];
let moon_bites=[];
let earth_damage=[];
let earth_damage_level=0;
let opener_marks=[];
let chunk_marks=[];
let p4_timer=0, p4_wave_count=0;

const c_lon=[3,6,9,12,15,18,0,3,6,9,12,15,18,21,3,6,9,12,15,18,21,24,6,9,12,15,18,21,24,9,12,15,18,9,12,15,12,15,12,15,12,45,48,51,54,57,60,45,48,51,54,57,60,48,51,54,57,51,54,54,54,57,54,57,54,54,30,33,36,33,36,39];
const c_lat=[-32,-32,-32,-32,-32,-32,-24,-24,-24,-24,-24,-24,-24,-24,-16,-16,-16,-16,-16,-16,-16,-16,-8,-8,-8,-8,-8,-8,-8,0,0,0,0,8,8,8,16,16,24,24,32,-32,-32,-32,-32,-32,-32,-24,-24,-24,-24,-24,-24,-16,-16,-16,-16,-8,-8,0,8,8,16,16,24,32,16,16,16,24,24,24];
let grav_k=120;
let launch_spd=1.2;
let dev_mode=false;

let gtick=0, state="title", paused=false;
let sel_id=null, spec_i=1;
let packet_i=1, packet_tick=0, wave_i=1;
let score=0, moon_int=22, moon_max=22, moon_max_orig=22;
let salvage=0, prop=0;
let charge=1, max_charge=3;
let upgrades={}, unlocked_specials={counter:true};
let contacts=[], interceptors=[], heavies=[], bombs=[];
let debris=[], fx=[], tug=null, inter=null;
let aim=null;
let stars=[];
let war_started=false, opening_shot_fired=false;
let brief_page=1, brief_tick=0;
let help_page=1, earth_fall_t=0, moon_fall_t=0;
let moon_cracks=[], moon_shards=[], earth_halves=[];
let charge_regen_t=0, moon_heal_t=0;
let fire_denied_t=0;
let moon_heal_p=0;

let boss=null;
let boss_intro_t=0;
let boss_defeated=false;
let boss_phase_started=false;
let result_mode=null;
let boss_shots=[];
let boss_pattern_i=1;
let boss_fire_cd=0;
let boss_hint_t=0;
let shield_deploy_t=0;
let shield_a=null, shield_b=null;
let shield_r=14;
let boss_text=null;
let boss_text_human=null, boss_text_machine=null;

let snd=null;
let audio_prev_state=null;
let audio_bank=null;
let audio_hold_t=0;
let audio_react_t=0;
let audio_voice_chars=0;
let audio_voice_phase=0;

const clabels={raider:'raider',bus:'wrecker',orbiter:'sapper',screen:'decoy'};

const sites=[{id:'outpost',ang:0},{id:'yard',ang:0.25},{id:'vault',ang:0.5}];
let interceptor_cd=0;

const cdefs={
  raider:{hp:1,spd:0.0075,idmg:1,salv:1,col:8},
  bus:{hp:2,spd:0.0050,idmg:6,salv:2,col:10},
  orbiter:{hp:2,spd:0.0060,idmg:3,salv:2,col:12,orbit:true},
  screen:{hp:1,spd:0.0050,idmg:0,salv:0,col:5},
};

const sdefs={
  counter:{id:'counter',label:'intcpt',cost:1,cint:0,scost:0,dmg:1,col:12,lspd:1.1},
  sling:{id:'sling',label:'sling',cost:2,cint:0,scost:0,dmg:2,col:6,lspd:0.65},
  moon_chunk:{id:'moon_chunk',label:'chunk',cost:3,cint:3,scost:0,dmg:3,col:6,lspd:0.4},
};
const special_order=['counter','sling','moon_chunk'];

const mdefs={
  driver:{hp:2,theta:0.013,omega:0.0032,col:8,label:'shipyard',cool_init:150,cool_re:180},
  jammer:{hp:2,theta:0.374,omega:0.0021,col:10,label:'jammer',cool_init:100,cool_re:140},
  aegis:{hp:4,theta:0.788,omega:0.0041,col:12,label:'aegis',barc:0.07},
};

const upgrade_meta={
  fast_reload:{label:'fast reload',desc:'charge regens faster'},
  reserve_tanks:{label:'reserve tanks',desc:'raise max charge to 5'},
  patch_crews:{label:'patch crews',desc:'better scrap repairs'},
  recycler:{label:'recycler',desc:'faster tug, easier charges'},
  point_defense:{label:'point defense',desc:'auto-zap near threats'},
  refinery:{label:'refinery',desc:'delivered mass doubled'},
  mass_driver:{label:'mass driver',desc:'chunks hit harder'},
  lunar_shielding:{label:'lunar shielding',desc:'+2 max moon integrity'},
  pulse_array:{label:'pulse array',desc:'long-range auto-zap'},
};

function upg_label(id) { const m=upgrade_meta[id]; return m?m.label:id; }

const packets=[
  {label:'opening claim',mods:[],unlock:null,upgrades:['fast_reload','reserve_tanks','patch_crews'],
   waves:[{t:80,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:100,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:115,src:'earth',kind:'screen',plan:'transfer',tid:'outpost'},{t:130,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:170,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:220,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:260,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:300,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:340,src:'earth',kind:'bus',plan:'transfer',tid:'outpost'},{t:345,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:350,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:390,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:420,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:460,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:480,src:'earth',kind:'raider',plan:'transfer',tid:'vault'}]},
  {label:'orbital denial',mods:['driver','jammer'],unlock:'sling',upgrades:['recycler','point_defense','refinery'],
   waves:[{t:50,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:80,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:130,src:'earth',kind:'bus',plan:'transfer',tid:'vault'},{t:170,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'vault'},{t:220,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:250,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:270,src:'earth',kind:'screen',plan:'transfer',tid:'yard'},{t:310,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:360,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:400,src:'earth',kind:'screen',plan:'transfer',tid:'outpost'},{t:440,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:470,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:490,src:'earth',kind:'bus',plan:'transfer',tid:'vault'},{t:520,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:540,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'outpost'},{t:560,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:580,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:600,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'outpost'},{t:640,src:'earth',kind:'raider',plan:'transfer',tid:'yard'}]},
  {label:'general war',mods:['driver','jammer'],unlock:null,upgrades:['mass_driver','lunar_shielding','fast_reload'],
   waves:[{t:40,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:80,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:130,src:'earth',kind:'bus',plan:'transfer',tid:'yard'},{t:155,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:170,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'vault'},{t:230,src:'earth',kind:'screen',plan:'transfer',tid:'outpost'},{t:270,src:'earth',kind:'bus',plan:'transfer',tid:'outpost'},{t:310,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'vault'},{t:340,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:360,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:410,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:460,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:500,src:'earth',kind:'bus',plan:'transfer',tid:'vault'},{t:530,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:560,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:590,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'outpost'},{t:620,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:650,src:'earth',kind:'raider',plan:'transfer',tid:'yard'}]},
  {label:'aegis breach',mods:['driver','driver','jammer','aegis'],unlock:'moon_chunk',upgrades:['pulse_array','mass_driver','reserve_tanks'],
   waves:[{t:40,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:80,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:130,src:'earth',kind:'bus',plan:'transfer',tid:'yard'},{t:200,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:240,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'vault'},{t:275,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:300,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:340,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:400,src:'earth',kind:'screen',plan:'transfer',tid:'outpost'},{t:440,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:460,src:'earth',kind:'bus',plan:'transfer',tid:'outpost'},{t:500,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:520,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'outpost'},{t:580,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:640,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:700,src:'earth',kind:'bus',plan:'transfer',tid:'vault'},{t:740,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:780,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:820,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'}]},
  {label:'core breach',mods:['driver','driver','jammer','jammer','aegis'],unlock:null,upgrades:[],core_strike:true,core_hp:8,
   waves:[{t:40,src:'earth',kind:'bus',plan:'transfer',tid:'outpost'},{t:100,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:140,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'yard'},{t:220,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:260,src:'earth',kind:'bus',plan:'transfer',tid:'vault'},{t:320,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:380,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:440,src:'earth',kind:'bus',plan:'transfer',tid:'yard'},{t:500,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'vault'},{t:560,src:'earth',kind:'raider',plan:'transfer',tid:'yard'},{t:620,src:'earth',kind:'bus',plan:'transfer',tid:'yard'},{t:680,src:'earth',kind:'orbiter',plan:'orbit_then_dive',tid:'outpost'},{t:740,src:'earth',kind:'raider',plan:'transfer',tid:'outpost'},{t:800,src:'earth',kind:'raider',plan:'transfer',tid:'vault'},{t:860,src:'earth',kind:'bus',plan:'transfer',tid:'vault'}]},
];

let mods=[];

// ===================================================================
// 4. ALL GAME FUNCTIONS
// ===================================================================

let nxt_id=1;
function nid() { nxt_id+=1; return nxt_id; }
function vsub(a,b) { return {x:a.x-b.x,y:a.y-b.y}; }
function vmul(a,k) { return {x:a.x*k,y:a.y*k}; }
function vlen(a) { return sqrt(a.x*a.x+a.y*a.y); }
function vnorm(a) { const l=vlen(a); if(l<0.001)return{x:0,y:0}; return{x:a.x/l,y:a.y/l}; }
function dist(a,b) { return sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)); }
function d2(ax,ay,bx,by) { const dx=ax-bx,dy=ay-by; return dx*dx+dy*dy; }
function lerp(a,b,t) { return a+(b-a)*t; }

function trigger_denied() { fire_denied_t=6; add(fx,{kind:'denied_blink',x:moon_x,y:moon_y,t:6,mt:6}); sfx(11); }

function site_scr(s) { const a=(earth_theta+s.ang)%1; return [moon_x+cos(a)*moon_r,moon_y+sin(a)*moon_r]; }
function moon_site_pos(id) { for(const s of sites){if(s.id===id)return site_scr(s);} return [moon_x,moon_y]; }

function upd_earth_orbit() { earth_theta=(earth_theta+earth_omega)%1; earth_x=moon_x+cos(earth_theta)*earth_orbit_r; earth_y=moon_y+sin(earth_theta)*earth_orbit_r; earth_spin=(earth_spin+0.003)%1; }
function mod_pos(m) { return [earth_x+cos(m.theta)*module_ring_r,earth_y+sin(m.theta)*module_ring_r]; }
function upd_mods() { for(const m of mods){if(m.hp>0)m.theta=(m.theta+m.omega)%1;} }

function bez2(a,b,c,t) { const abx=lerp(a.x,b.x,t),aby=lerp(a.y,b.y,t); const bcx=lerp(b.x,c.x,t),bcy=lerp(b.y,c.y,t); return{x:lerp(abx,bcx,t),y:lerp(aby,bcy,t)}; }
function arc_ctl(a,b,lift) { const mx=(a.x+b.x)*0.5,my=(a.y+b.y)*0.5; let ox=mx-moon_x,oy=my-moon_y; let ol=sqrt(ox*ox+oy*oy); if(ol<0.001)ol=1; ox/=ol;oy/=ol; return{x:mx+ox*lift,y:my+oy*lift}; }

function source_pos(src) {
  if(src==='earth')return[earth_x,earth_y];
  if(src.substring(0,7)==='module:'){const kind=src.substring(7);for(const m of mods){if(m.kind===kind&&m.hp>0)return mod_pos(m);}}
  return[earth_x,earth_y];
}

function spawn_contact(src,kind,plan,target_id) {
  const d=cdefs[kind]; const[sx,sy]=source_pos(src); let[tx,ty]=moon_site_pos(target_id);
  let start={x:sx,y:sy}; let pend={x:tx,y:ty}; let lift=24;
  if(target_id==='vault')lift=-18;
  if(plan==='orbit_then_dive'){const ang=atan2(sx-moon_x,sy-moon_y);const entry_ang=(ang+0.15)%1;pend={x:moon_x+cos(entry_ang)*lunar_orbit_r,y:moon_y+sin(entry_ang)*lunar_orbit_r};lift=28;}
  const ctl=arc_ctl(start,pend,lift);
  contacts.push({uid:nid(),kind:kind,hp:d.hp,mhp:d.hp,spd:d.spd,idmg:d.idmg,salv:d.salv,col:d.col,plan:plan,target_id:target_id,state:'transfer',u:0,start:start,ctl:ctl,pend:pend,otheta:0,odir:(nxt_id%2===0)?1:-1,otick:0,dstart:null,dctl:null,dend:null,accel_mul:kind==='bus'?0.6:undefined});
}

function contact_pos(c) {
  if(c.state==='transfer')return bez2(c.start,c.ctl,c.pend,min(1,c.u));
  else if(c.state==='orbit')return{x:moon_x+cos(c.otheta)*lunar_orbit_r,y:moon_y+sin(c.otheta)*lunar_orbit_r};
  else if(c.state==='dive')return bez2(c.dstart,c.dctl,c.dend,min(1,c.u));
  return{x:c.pend.x,y:c.pend.y};
}

function step_contact(c,predict) {
  if(c.hp<=0)return;
  if(c.state==='transfer'){
    if(c.kind==='bus'){c.accel_mul=min(1.8,(c.accel_mul||0.6)+0.0065);c.u+=c.spd*c.accel_mul;}else{c.u+=c.spd;}
    if(c.plan!=='orbit_then_dive'&&!cdefs[c.kind].orbit){const tp=contact_pos(c);const tmx=tp.x-moon_x,tmy=tp.y-moon_y;if(tmx*tmx+tmy*tmy<=(moon_r+1)*(moon_r+1)){if(!predict)impact_contact(c);return;}}
    if(c.u>=1){
      if(c.plan==='orbit_then_dive'||cdefs[c.kind].orbit){
        const t_near=max(0,c.u-c.spd);const p_near=bez2(c.start,c.ctl,c.pend,t_near);
        const vx2=c.pend.x-p_near.x,vy2=c.pend.y-p_near.y;
        c.state='orbit';c.otick=280;c.pulse_t=45;c.bombs_left=5;
        c.otheta=atan2(c.pend.x-moon_x,c.pend.y-moon_y);
        c.orbit_omega=max(0.003,sqrt(vx2*vx2+vy2*vy2)/(6.28*lunar_orbit_r));
        const dx2=c.pend.x-moon_x,dy2=c.pend.y-moon_y;
        const cross=dx2*vy2-dy2*vx2;
        c.odir=cross<0?1:-1;
      }else{if(!predict)impact_contact(c);}
    }
  }else if(c.state==='orbit'){
    c.otheta=((c.otheta+(c.orbit_omega||0.002)*c.odir)%1+1)%1;c.otick-=1;
    if(!predict&&c.pulse_t!==undefined&&(c.bombs_left||0)>0){c.pulse_t-=1;if(c.pulse_t<=0){c.pulse_t=45;const p=contact_pos(c);spawn_bomb(p.x,p.y);c.bombs_left-=1;}}
    if(c.otick<=0||(c.bombs_left!==undefined&&c.bombs_left<=0&&c.pulse_t<=8)){c.dstart=contact_pos(c);c.state='dive';c.u=0;const[tx2,ty2]=moon_site_pos(c.target_id);c.dend={x:tx2,y:ty2};c.dctl=arc_ctl(c.dstart,c.dend,6);}
  }else if(c.state==='dive'){
    c.u+=c.spd*1.25;const dp=contact_pos(c);const dmx=dp.x-moon_x,dmy=dp.y-moon_y;
    if(dmx*dmx+dmy*dmy<=(moon_r+1)*(moon_r+1)||c.u>=1){if(!predict)impact_contact(c);}
  }
}

function impact_contact(c) {
  c.hp=0;moon_int=max(0,moon_int-c.idmg);const p=contact_pos(c);
  const dmx=p.x-moon_x,dmy=p.y-moon_y;const dl=sqrt(dmx*dmx+dmy*dmy);
  let ix,iy;if(dl>0.01){ix=moon_x+dmx/dl*moon_r;iy=moon_y+dmy/dl*moon_r;}else{ix=moon_x;iy=moon_y;}
  if(c.idmg>0){
    add(fx,{kind:'impact',x:ix,y:iy,t:12,mt:12});
    if(c.kind==='bus'||c.kind==='orbiter')sfx(6);else sfx(2);
    if(c.kind==='orbiter'){add(fx,{kind:'explosion',x:ix,y:iy,t:20,mt:20});for(let i=0;i<5;i++){const sa=i/5+rnd(0.08);const sr=moon_r+1+flr(rnd(3));add(fx,{kind:'fizz',x:moon_x+cos(sa)*sr,y:moon_y+sin(sa)*sr,t:12+flr(rnd(6)),mt:18});}}
    if(c.kind==='bus'){add(fx,{kind:'explosion',x:ix,y:iy,t:28,mt:28});add(fx,{kind:'impact',x:ix,y:iy,t:22,mt:22});for(let i=0;i<8;i++){const sa=i/8+rnd(0.05);const sr=moon_r+2+flr(rnd(4));add(fx,{kind:'fizz',x:moon_x+cos(sa)*sr,y:moon_y+sin(sa)*sr,t:16+flr(rnd(6)),mt:22});}for(let i=0;i<3;i++){add_moon_crater(ix+cos(rnd(0.2)-0.1)*rnd(2),iy+sin(rnd(0.2)-0.1)*rnd(2),2);}}
    add_moon_crater(ix,iy,c.idmg);check_moon_bites();
  }else{add(fx,{kind:'fizz',x:ix,y:iy,t:8,mt:8});}
}

function predict_contact(c,frames) {
  const p={kind:c.kind,hp:c.hp,spd:c.spd,idmg:c.idmg,salv:c.salv,col:c.col,plan:c.plan,target_id:c.target_id,state:c.state,u:c.u,start:{x:c.start.x,y:c.start.y},ctl:{x:c.ctl.x,y:c.ctl.y},pend:{x:c.pend.x,y:c.pend.y},otheta:c.otheta,odir:c.odir,otick:c.otick,orbit_omega:c.orbit_omega,accel_mul:c.accel_mul,dstart:c.dstart?{x:c.dstart.x,y:c.dstart.y}:null,dctl:c.dctl?{x:c.dctl.x,y:c.dctl.y}:null,dend:c.dend?{x:c.dend.x,y:c.dend.y}:null};
  for(let i=0;i<frames;i++)step_contact(p,true);return contact_pos(p);
}

function destroy_contact(c) {
  const p=contact_pos(c);c.hp=0;score+=10;audio_on_contact_kill(c.kind);
  if(dist(p,{x:moon_x,y:moon_y})<34&&c.salv>0){const ang=atan2(p.x-moon_x,p.y-moon_y);add(debris,{uid:nid(),theta:ang,omega:((nxt_id%2===0)?0.004:-0.004),ttl:220,hot:24,mass:c.salv,claimed:false});}
}

function upd_contacts() { for(const c of all(contacts))step_contact(c,false); for(const c of all(contacts)){if(c.hp<=0)del(contacts,c);} }

function launch_auto_lock(uid) {
  if(charge<1){trigger_denied();return;} if(interceptor_cd>0)return;
  let target=null;for(const c of contacts){if(c.uid===uid&&c.hp>0)target=c;} if(!target)return;
  charge-=1;interceptors.push({uid:nid(),x:moon_x,y:moon_y,vx:0,vy:0,cur_speed:0,max_speed:1.35,accel:0.05,turn:0.25,ttl:300,target_uid:uid});
  interceptor_cd=2;add(fx,{kind:'launch',x:moon_x,y:moon_y,t:8,mt:8});sfx(0);audio_on_player_launch('counter',false);
}

function upd_interceptors() {
  for(const it of all(interceptors)){
    it.ttl-=1;
    if(it.orphan_t!==undefined){it.orphan_t-=1;it.x+=it.vx;it.y+=it.vy;it.vx*=0.94;it.vy*=0.94;if(it.orphan_t<=0){add(fx,{kind:'fizz',x:it.x,y:it.y,t:10,mt:10});del(interceptors,it);}
    }else{
      let target=null;for(const c of contacts){if(c.uid===it.target_uid&&c.hp>0)target=c;}
      if(!target){it.orphan_t=14;add(fx,{kind:'fizz',x:it.x,y:it.y,t:8,mt:8});}
      else{
        it.cur_speed=min(it.cur_speed+it.accel,it.max_speed);
        const tp=contact_pos(target);const d_cur=dist({x:it.x,y:it.y},tp);
        let ap;if(d_cur<14)ap=tp;else ap=predict_contact(target,10);
        const des=vnorm(vsub(ap,{x:it.x,y:it.y}));let spd=it.cur_speed;if(d_cur<10)spd=spd*max(0.5,d_cur/10);
        const desV=vmul(des,spd);it.vx=lerp(it.vx,desV.x,it.turn);it.vy=lerp(it.vy,desV.y,it.turn);it.x+=it.vx;it.y+=it.vy;
        let hit=false;if(dist({x:it.x,y:it.y},tp)<5)hit=true;
        else{const pvx=it.x-it.vx,pvy=it.y-it.vy;const sx2=it.x-pvx,sy2=it.y-pvy;const sl=sx2*sx2+sy2*sy2;if(sl>0.01){let t=((tp.x-pvx)*sx2+(tp.y-pvy)*sy2)/sl;t=mid(0,t,1);const cx=pvx+sx2*t,cy=pvy+sy2*t;if((tp.x-cx)*(tp.x-cx)+(tp.y-cy)*(tp.y-cy)<25)hit=true;}}
        if(hit){target.hp-=1;if(target.hp<=0)destroy_contact(target);add(fx,{kind:'explosion',x:it.x,y:it.y,t:14,mt:14});sfx(1);del(interceptors,it);}
        else if(it.ttl<=0){add(fx,{kind:'miss',x:it.x,y:it.y,t:8,mt:8});del(interceptors,it);}
      }
    }
  }
}

function unlocked_list() { const list=[];for(const sid of special_order){if(unlocked_specials[sid])list.push(sid);}return list; }
function current_special() { const list=unlocked_list();if(list.length===0)return null;if(spec_i<1)spec_i=list.length;if(spec_i>list.length)spec_i=1;return sdefs[list[spec_i-1]]; }
function set_special(id) { const list=unlocked_list();for(let i=0;i<list.length;i++){if(list[i]===id){spec_i=i+1;return;}}spec_i=1; }
function can_pay_special(sp) { if(!sp)return false;if(charge<sp.cost)return false;if(moon_int<=sp.cint)return false;if(sp.scost>0&&salvage<sp.scost)return false;return true; }

function enter_aim(target) {
  const sp=current_special();if(!sp)return;if(war_started&&!can_pay_special(sp)){trigger_denied();return;}
  let tx=earth_x,ty=earth_y;
  if(target.type==='module'&&target.ref){const[mx2,my2]=mod_pos(target.ref);tx=mx2;ty=my2;}
  else if(target.type==='boss'&&target.ref){tx=target.ref.x;ty=target.ref.y;}
  const dx=tx-moon_x,dy=ty-moon_y;let dl=sqrt(dx*dx+dy*dy);if(dl<0.1)dl=1;
  const cx=moon_x+dx/dl*25,cy=moon_y+dy/dl*25;const ang=atan2(cx-moon_x,cy-moon_y);
  aim={ang:ang,sp:sp,target:target,cx:cx,cy:cy};
}

function fire_aimed() {
  if(!aim)return;const sp=aim.sp;const opener=!war_started;
  if(!opener){if(!can_pay_special(sp)){trigger_denied();return;}charge-=sp.cost;moon_int-=sp.cint;if(sp.scost>0)salvage-=sp.scost;}
  sfx(4);audio_on_player_launch(sp.id,opener);
  if(sp.id==='moon_chunk'){if(!opener){moon_max=max(8,moon_max-3);if(moon_int>moon_max)moon_int=moon_max;}add(moon_bites,{a:(aim.ang-earth_theta+1)%1,sz:2});check_moon_bites();add(fx,{kind:'chunk_tear',x:moon_x,y:moon_y,t:10,mt:10});}
  else if(sp.cint>0)check_moon_bites();
  let spd=sp.lspd||launch_spd;let sz=1;if(sp.id==='moon_chunk')sz=3;if(opener){spd=0.22;sz=3;}
  const lx=moon_x+cos(aim.ang)*(moon_r+3),ly=moon_y+sin(aim.ang)*(moon_r+3);
  let motor_t=0;if(sp.id==='moon_chunk'&&!opener)motor_t=26;
  const straight=(state==='boss_play');if(straight)spd=(sp.id==='moon_chunk')?0.55:0.9;
  heavies.push({uid:nid(),kind:sp.id,x:lx,y:ly,vx:cos(aim.ang)*spd,vy:sin(aim.ang)*spd,dmg:sp.dmg,col:sp.col,size:sz,tkind:aim.target.type,tid:aim.target.id,age:0,max_age:straight?240:480,trail:[],opener:opener,motor_t:motor_t,straight:straight});
  if(opener)opening_shot_fired=true;add(fx,{kind:'launch_heavy',x:lx,y:ly,t:10,mt:10});aim=null;
}

function is_land(lon,lat) { for(let i=0;i<c_lon.length;i++){const clon=c_lon[i]/100,clat=c_lat[i]/100;let dlon=clon-lon;if(dlon>0.5)dlon-=1;if(dlon<-0.5)dlon+=1;if(abs(dlon)<0.035&&abs(clat-lat)<0.06)return true;}return false; }
function get_earth_colors() { const d=earth_damage_level;if(d<20)return[12,3,11];if(d<45)return[12,4,3];if(d<70)return[1,4,3];if(d<95)return[5,4,4];return[5,2,4]; }
function gen_moon_craters() { moon_craters=[];moon_bites=[];for(let i=0;i<3;i++)add(moon_craters,{a:rnd(1),r:rnd(moon_r-3)+2,sz:1}); }
function check_moon_bites() { const dmg=moon_max-moon_int;const target=flr(dmg*6/max(1,moon_max));while(moon_bites.length<target)add(moon_bites,{a:rnd(1),sz:1+flr(rnd(2))}); }
function add_moon_crater(hx,hy,sz) { const dx=hx-moon_x,dy=hy-moon_y;let dr=sqrt(dx*dx+dy*dy);if(dr>=moon_r)dr=moon_r-1;const ca=atan2(dx,dy);add(moon_craters,{a:(ca-earth_theta+1)%1,r:dr,sz:sz||1});if(moon_craters.length>30)moon_craters.splice(0,1); }

function add_earth_damage(hx,hy,weight,no_smoke) {
  let dx=hx-earth_x,dy=hy-earth_y;const d=sqrt(dx*dx+dy*dy);if(d>earth_r){dx=dx/d*earth_r;dy=dy/d*earth_r;}
  const lat=dy/(earth_r*2.5);const rel_approx=(dx/earth_r)*0.25;const lon=(earth_spin+rel_approx+1)%1;const land=is_land(lon,lat);
  add(earth_damage,{lon:lon,lat:lat,land:land});if(earth_damage.length>40)earth_damage.splice(0,1);earth_damage_level+=(weight||1);
  if(land){add(fx,{kind:'land_hit',ex:dx,ey:dy,t:14,mt:14});if(!no_smoke){for(let i=0;i<3;i++)add(fx,{kind:'smoke',ex:dx+rnd(3)-1.5,ey:dy+rnd(2)-1,vx:(rnd(1)-0.5)*0.1,vy:-0.06-rnd(0.08),t:40+flr(rnd(20)),mt:60,col:5});}}
  else{add(fx,{kind:'splash',ex:dx,ey:dy,t:20,mt:20});if(!no_smoke){for(let i=0;i<2;i++)add(fx,{kind:'smoke',ex:dx+rnd(4)-2,ey:dy+rnd(2)-1,vx:(rnd(1)-0.5)*0.08,vy:-0.08-rnd(0.06),t:30+flr(rnd(15)),mt:45,col:6});}}
}

function spawn_opener_mark(hx,hy) { let dx=hx-earth_x,dy=hy-earth_y;const d=sqrt(dx*dx+dy*dy);if(d>earth_r){dx=dx/d*earth_r;dy=dy/d*earth_r;}const lat=dy/(earth_r*2.5);const lon=(earth_spin+(dx/earth_r)*0.25+1)%1;add(opener_marks,{lon:lon,lat:lat,age:0,max_age:1500}); }
function upd_opener_marks() { for(const m of all(opener_marks)){m.age+=1;if(m.age>=m.max_age)del(opener_marks,m);} }
function spawn_chunk_mark(hx,hy) { let dx=hx-earth_x,dy=hy-earth_y;const d=sqrt(dx*dx+dy*dy);if(d>earth_r){dx=dx/d*earth_r;dy=dy/d*earth_r;}const lat=dy/(earth_r*2.5);const lon=(earth_spin+(dx/earth_r)*0.25+1)%1;add(chunk_marks,{lon:lon,lat:lat});if(chunk_marks.length>30)chunk_marks.splice(0,1); }
function spawn_bomb(x,y) { const dx=moon_x-x,dy=moon_y-y;let d=sqrt(dx*dx+dy*dy);if(d<0.1)d=1;add(bombs,{x:x,y:y,vx:dx/d*0.35,vy:dy/d*0.35,age:0}); }

function upd_bombs() { for(const b of all(bombs)){if(b.boss_debris)continue;b.x+=b.vx;b.y+=b.vy;b.age+=1;const mx=b.x-moon_x,my=b.y-moon_y;if(mx*mx+my*my<=(moon_r+1)*(moon_r+1)){moon_int=max(0,moon_int-3);if(salvage>0)salvage-=1;else charge_regen_t=max(0,charge_regen_t-30);const ml=sqrt(mx*mx+my*my);let ix2,iy2;if(ml>0.01){ix2=moon_x+mx/ml*moon_r;iy2=moon_y+my/ml*moon_r;}else{ix2=moon_x;iy2=moon_y;}add(fx,{kind:'impact',x:ix2,y:iy2,t:14,mt:14});add(fx,{kind:'sabot',x:ix2,y:iy2,t:16,mt:16});add_moon_crater(ix2,iy2,2);sfx(6);del(bombs,b);}else if(b.age>260)del(bombs,b);} }

function draw_bombs() { for(const b of bombs){if(b.boss_debris)continue;pset(b.x,b.y,13);pset(b.x-1,b.y,1);pset(b.x+1,b.y,1);pset(b.x,b.y-1,6);pset(b.x,b.y+1,1);} }

function on_module_killed(m,mx2,my2) { score+=50;add(fx,{kind:'explosion',x:mx2,y:my2,t:20,mt:20});for(let i=0;i<8;i++){const a=i/8;add(fx,{kind:'smoke',ex:(mx2-earth_x)+cos(a)*3,ey:(my2-earth_y)+sin(a)*3,vx:cos(a)*0.3,vy:sin(a)*0.3,t:30+flr(rnd(15)),mt:45,col:m.col||5});}let dx=mx2-earth_x,dy=my2-earth_y;let dl=sqrt(dx*dx+dy*dy);if(dl<0.1)dl=1;const hx=earth_x+dx/dl*(earth_r-1),hy=earth_y+dy/dl*(earth_r-1);add_earth_damage(hx,hy,2);add(fx,{kind:'earth_flash',ex:hx-earth_x,ey:hy-earth_y,t:16,mt:16}); }

function upd_heavies() {
  for(const h of all(heavies)){
    h.age+=1;if(h.motor_t&&h.motor_t>0&&!h.straight){const vl=sqrt(h.vx*h.vx+h.vy*h.vy);if(vl>0.01){h.vx+=h.vx/vl*0.011;h.vy+=h.vy/vl*0.011;}h.motor_t-=1;}
    let dx,dy,d;
    if(h.straight){dx=earth_x-h.x;dy=earth_y-h.y;d=sqrt(dx*dx+dy*dy);if(d<1)d=1;}
    else{dx=earth_x-h.x;dy=earth_y-h.y;d=sqrt(dx*dx+dy*dy);if(d<1)d=1;let g=min(grav_k/(d*d),0.15);if(h.kind==='sling')g*=0.4;h.vx+=dx/d*g;h.vy+=dy/d*g;if(h.kind==='sling'){const sp2=sqrt(h.vx*h.vx+h.vy*h.vy);if(sp2>1.1){h.vx=h.vx/sp2*1.1;h.vy=h.vy/sp2*1.1;}}else if(h.kind==='moon_chunk'&&!h.opener){const sp2=sqrt(h.vx*h.vx+h.vy*h.vy);if(sp2>0.78){h.vx=h.vx/sp2*0.78;h.vy=h.vy/sp2*0.78;}}}
    h.trail.push({x:h.x,y:h.y});const tlim=(h.kind==='moon_chunk'&&!h.opener)?14:8;if(h.trail.length>tlim)h.trail.splice(0,1);h.x+=h.vx;h.y+=h.vy;
    if(!h.opener&&(h.kind==='sling'||h.kind==='moon_chunk')){for(const c of all(contacts)){if(c.hp>0){const cp=contact_pos(c);if((h.x-cp.x)*(h.x-cp.x)+(h.y-cp.y)*(h.y-cp.y)<25){destroy_contact(c);add(fx,{kind:'explosion',x:cp.x,y:cp.y,t:12,mt:12});sfx(1);}}}}
    let handled=false;
    if(state==='boss_play'&&boss&&!h.opener&&!boss.dying){const fwx=boss.fwx||1,fwy=boss.fwy||0;const pxd=-fwy,pyd=fwx;const rx=h.x-boss.x,ry=h.y-boss.y;const lu=rx*fwx+ry*fwy,lv=rx*pxd+ry*pyd;if(abs(lu)<=9&&abs(lv)<=4){boss_take_hit(h.dmg,h.kind);add(fx,{kind:'explosion',x:h.x,y:h.y,t:14,mt:14});del(heavies,h);handled=true;}else if(d<earth_r+3){add(fx,{kind:'miss',x:h.x,y:h.y,t:8,mt:8});del(heavies,h);handled=true;}}
    if(!handled){
      let blocked=false;
      if(!h.opener){const ned=sqrt((h.x-earth_x)*(h.x-earth_x)+(h.y-earth_y)*(h.y-earth_y));if(ned>earth_r+3&&ned<earth_r+module_ring_r+2){for(const m of mods){if(m.kind==='aegis'&&m.hp>0){const[amx,amy]=mod_pos(m);const mod_d=sqrt((h.x-amx)*(h.x-amx)+(h.y-amy)*(h.y-amy));if(mod_d>=8){const hang=atan2(h.x-earth_x,h.y-earth_y);let diff=(hang-m.theta+0.5+1)%1-0.5;if(abs(diff)<(m.barc||0.07)){blocked=true;add(fx,{kind:'block',x:h.x,y:h.y,t:14,mt:14});sfx(5);}}break;}}}}
      if(blocked){del(heavies,h);}
      else if(d<earth_r+3){
        if(h.opener){spawn_opener_mark(h.x,h.y);add(fx,{kind:'earth_flash',ex:h.x-earth_x,ey:h.y-earth_y,t:30,mt:30});const rex=h.x-earth_x,rey=h.y-earth_y;for(let si=0;si<14;si++){const sc=(si<7)?6:13;add(fx,{kind:'smoke',ex:rex+(rnd(8)-4),ey:rey+(rnd(8)-4),vx:(rnd(0.5)-0.25),vy:-(rnd(0.25)+0.05),t:40+flr(rnd(30)),mt:70,col:sc});}sfx(57);if(!war_started){war_started=true;packet_tick=0;}}
        else{let w=1;if(h.kind==='sling')w=0;else if(h.kind==='moon_chunk')w=4;add_earth_damage(h.x,h.y,w);if(h.kind==='moon_chunk'){spawn_chunk_mark(h.x,h.y);add(fx,{kind:'chunk_impact',ex:h.x-earth_x,ey:h.y-earth_y,t:22,mt:22});sfx(7);audio_big_boom('hero');}else sfx(6);resolve_heavy_hit(h);}
        del(heavies,h);
      }else{
        let hit_mod=false;for(const m of all(mods)){if(m.hp>0){const[mx2,my2]=mod_pos(m);if(dist({x:h.x,y:h.y},{x:mx2,y:my2})<5){const pre=m.hp;m.hp=max(0,m.hp-h.dmg);score+=30;add(fx,{kind:'impact',x:mx2,y:my2,t:14,mt:14});if(pre>0&&m.hp<=0){on_module_killed(m,mx2,my2);sfx(7);audio_big_boom('hero');}else sfx(6);del(heavies,h);hit_mod=true;break;}}}
        if(!hit_mod){if(dist({x:h.x,y:h.y},{x:moon_x,y:moon_y})<moon_r+2&&h.age>15){if(h.opener)moon_int=0;else moon_int=max(0,moon_int-1);add(fx,{kind:'impact',x:h.x,y:h.y,t:12,mt:12});add_moon_crater(h.x,h.y,h.size||2);check_moon_bites();sfx(6);del(heavies,h);}else if(h.age>h.max_age)del(heavies,h);}
      }
    }
  }
}

function resolve_heavy_hit(h) { if(h.opener)return;if(earth_core_exposed&&h.kind==='moon_chunk'){earth_core_hp=max(0,earth_core_hp-h.dmg);earth_damage_level=min(99,earth_damage_level+22);add(fx,{kind:'earth_flash',ex:h.x-earth_x,ey:h.y-earth_y,t:10,mt:10});if(earth_core_hp<=0){earth_fall_t=0;earth_halves=[];state='earth_fall';}}if(h.kind==='sling')score+=15;else if(h.kind==='moon_chunk')score+=25; }

function upd_debris() { for(const d of debris){d.theta=(d.theta+d.omega+1)%1;if(d.hot>0)d.hot-=1;} }
function best_debris() { let best=null;for(const d of debris){if(!d.claimed){if(!best)best=d;else{const dh=(d.hot>0)?1:0,bh=(best.hot>0)?1:0;if(dh>bh||(dh===bh&&d.mass>best.mass)||(dh===bh&&d.mass===best.mass&&d.uid<best.uid))best=d;}}}return best; }
function auto_tug() { if(tug)return;const d=best_debris();if(!d)return;d.claimed=true;const tt=upgrades.recycler?14:22;tug={tid:d.uid,st:'out',t:tt,mt:tt,carry:0,lx:0,ly:0}; }

function deliver_salv(mass) {
  if(upgrades.refinery)mass*=2;salvage+=mass;prop+=mass;const thresh=upgrades.recycler?1:2;const pre_charge=charge;
  while(prop>=thresh&&charge<max_charge){prop-=thresh;charge+=1;}if(charge>pre_charge){sfx(10);audio_on_charge_gain();}if(prop>thresh*2)prop=thresh*2;
  moon_heal_p=(moon_heal_p||0)+mass;const heal_thresh=upgrades.patch_crews?3:5;let healed=false;while(moon_heal_p>=heal_thresh&&moon_int<moon_max){moon_heal_p-=heal_thresh;moon_int+=1;healed=true;}if(moon_heal_p>heal_thresh*2)moon_heal_p=heal_thresh*2;
  const[yx,yy]=moon_site_pos('yard');add(fx,{kind:'deliver_ping',x:yx,y:yy,t:10,mt:10});sfx(3);
  if(healed){const ra=rnd(1);add(fx,{kind:'repair_spark',x:moon_x+cos(ra)*moon_r,y:moon_y+sin(ra)*moon_r,t:14,mt:14});}
}

function upd_tug() {
  if(!tug)return;tug.t-=1;let target=null;for(const d of debris){if(d.uid===tug.tid)target=d;}
  if(tug.st==='out'&&tug.t<=0){const gt=upgrades.recycler?12:20;tug.st='grab';tug.t=gt;tug.mt=gt;add(fx,{kind:'tug_grab',x:tug.lx,y:tug.ly,t:6,mt:6});}
  else if(tug.st==='grab'&&tug.t<=0){tug.back_x=tug.lx;tug.back_y=tug.ly;if(target){tug.carry=target.mass;del(debris,target);}const bt=upgrades.recycler?10:16;tug.st='back';tug.t=bt;tug.mt=bt;add(fx,{kind:'tug_grab',x:tug.lx,y:tug.ly,t:8,mt:8});}
  else if(tug.st==='back'&&tug.t<=0){deliver_salv(tug.carry||0);tug=null;}
}

function build_targets() {
  if(!war_started){if(opening_shot_fired)return[];return[{type:'earth_surface',id:'earth_surface',ref:{label:'earth'},label:'earth'}];}
  const list=[];const sp=current_special();const wid=sp?sp.id:'counter';
  if(wid==='counter'){const raw=[];for(const c of contacts){const p=contact_pos(c);raw.push({c:c,d:d2(p.x,p.y,moon_x,moon_y)});}for(let i=1;i<raw.length;i++){let j=i;while(j>0){const a=raw[j-1],b=raw[j];if(b.d<a.d||(b.d===a.d&&b.c.uid<a.c.uid)){raw[j-1]=b;raw[j]=a;j--;}else break;}}for(const r of raw)list.push({type:'contact',id:r.c.uid,ref:r.c,label:clabels[r.c.kind]||r.c.kind});}
  else if(wid==='sling'){for(const m of mods){if(m.hp>0)list.push({type:'module',id:m.uid,ref:m,label:m.label});}list.push({type:'earth_surface',id:'earth_surface',ref:{label:'earth'},label:'earth'});}
  else if(wid==='moon_chunk'){if(earth_core_exposed)list.push({type:'earth',id:'earth_core',ref:{label:'core'},label:'core'});else list.push({type:'earth_surface',id:'earth_surface',ref:{label:'earth'},label:'earth'});}
  return list;
}

function sel_target() { const list=build_targets();if(list.length===0){sel_id=null;return null;}if(sel_id!==null){for(const it of list){if(it.id===sel_id)return it;}}sel_id=list[0].id;return list[0]; }
function cycle_target(dir) { const list=build_targets();if(list.length===0){sel_id=null;return;}let cur=0;if(sel_id!==null){for(let i=0;i<list.length;i++){if(list[i].id===sel_id){cur=i;break;}}}const new_i=((cur+dir)%list.length+list.length)%list.length;sel_id=list[new_i].id; }
function cycle_special(dir) { const list=unlocked_list();if(list.length===0)return;spec_i=((spec_i-1+dir)%list.length+list.length)%list.length+1;sel_id=null; }

function upd_module_pressure() { const sites_by=['outpost','yard','vault'];for(const m of mods){if(m.hp>0&&m.cool!==undefined){m.cool-=1;if(m.cool<=0){const tgt=sites_by[flr(gtick/60)%3];if(m.kind==='driver'){spawn_contact('module:driver','raider','transfer',tgt);m.cool=m.cool_re;}else if(m.kind==='jammer'){spawn_contact('module:jammer','screen','transfer',tgt);m.cool=m.cool_re;}else m.cool=m.cool_re||240;}}} }
function upd_charge_regen() { if(dev_mode){charge=max_charge;charge_regen_t=0;return;}if(charge>=max_charge){charge_regen_t=0;return;}charge_regen_t+=1;const thresh=upgrades.fast_reload?23:35;if(charge_regen_t>=thresh){charge+=1;charge_regen_t=0;sfx(10);audio_on_charge_gain();} }
function upd_moon_heal() { if(!upgrades.patch_crews){moon_heal_t=0;return;}if(moon_int>=moon_max){moon_heal_t=0;return;}moon_heal_t+=1;if(moon_heal_t>=800){moon_int+=1;moon_heal_t=0;} }

function pd_fire(range,dmg) { let best=null,bd=range*range;for(const c of contacts){if(c.hp>0&&c.kind!=='screen'){const p=contact_pos(c);const dx=p.x-moon_x,dy=p.y-moon_y;const d2v=dx*dx+dy*dy;if(d2v<=bd){best=c;bd=d2v;}}}if(best){best.hp=max(0,best.hp-dmg);if(best.hp<=0)destroy_contact(best);const p=contact_pos(best);add(fx,{kind:'pd_beam',x0:moon_x,y0:moon_y,x:p.x,y:p.y,t:15,mt:15});sfx(13);} }
function upd_point_defense() { if(upgrades.point_defense&&gtick%100===0)pd_fire(lunar_orbit_r+4,2);if(upgrades.pulse_array&&gtick%100===50)pd_fire(lunar_orbit_r+16,1); }

function start_packet(idx) {
  packet_i=idx;packet_tick=0;wave_i=0;contacts=[];interceptors=[];heavies=[];bombs=[];debris=[];tug=null;aim=null;mods=[];
  const p=packets[packet_i-1];if(!p){state='result';return;}
  const kind_count={};for(const kind of p.mods){const d=mdefs[kind];const n=kind_count[kind]||0;kind_count[kind]=n+1;mods.push({uid:nid(),kind:kind,hp:d.hp,mhp:d.hp,theta:(d.theta+n*0.5)%1,omega:d.omega,col:d.col,label:d.label,barc:d.barc,cool:d.cool_init,cool_re:d.cool_re});}
  if(p.unlock)unlocked_specials[p.unlock]=true;earth_core_hp=p.core_hp||5;earth_core_exposed=p.core_strike||false;
}

function packet_done() { const p=packets[packet_i-1];if(!p)return false;if(p.core_strike&&earth_core_hp>0)return false;if(wave_i<p.waves.length)return false;let active=0;for(const c of contacts){if(c.hp>0&&c.kind!=='screen')active++;}return active===0&&interceptors.length===0&&heavies.length===0; }

function start_intermission() {
  const opts=[],seen={};const curPkt=packets[packet_i-1];
  for(const u of curPkt.upgrades){if(!upgrades[u]&&!seen[u]){opts.push(u);seen[u]=true;}}
  for(let pi=packet_i-2;pi>=0;pi--){if(opts.length>=3)break;for(const u of packets[pi].upgrades){if(!upgrades[u]&&!seen[u]){opts.push(u);seen[u]=true;if(opts.length>=3)break;}}}
  inter={opts:opts,oi:0};sfx(15);state='inter';
}

function apply_upgrade(id) { if(id)upgrades[id]=true;if(id==='reserve_tanks')max_charge=5;else if(id==='lunar_shielding'){moon_max+=2;moon_max_orig+=2;moon_int+=2;}else if(id==='mass_driver')sdefs.moon_chunk.dmg+=1; }
function gen_stars() { stars=[];for(let i=0;i<35;i++)stars.push({x:flr(rnd(128)),y:flr(rnd(128)),phase:rnd(1),rate:0.008+rnd(0.02),bright:flr(rnd(3))}); }

function reset_run() {
  score=0;moon_int=22;moon_max=22;moon_max_orig=22;salvage=0;prop=0;charge=1;max_charge=3;
  upgrades={};unlocked_specials={counter:true};sdefs.moon_chunk.dmg=3;sdefs.sling.lspd=0.65;sdefs.counter.scost=0;sdefs.sling.scost=0;sdefs.moon_chunk.scost=0;
  earth_damage=[];earth_damage_level=0;opener_marks=[];chunk_marks=[];p4_timer=0;p4_wave_count=0;gen_moon_craters();
  spec_i=1;sel_id=null;aim=null;war_started=false;opening_shot_fired=false;brief_page=1;brief_tick=0;help_page=1;
  charge_regen_t=0;moon_heal_t=0;moon_heal_p=0;interceptor_cd=0;earth_fall_t=0;moon_fall_t=0;moon_cracks=[];moon_shards=[];earth_halves=[];
  boss=null;boss_intro_t=0;boss_defeated=false;boss_phase_started=false;result_mode=null;boss_shots=[];boss_pattern_i=1;boss_fire_cd=0;boss_hint_t=0;
  shield_a=null;shield_b=null;boss_text=null;boss_text_human=null;boss_text_machine=null;audio_reset();start_packet(1);
}

// audio conductor
function audio_boot() { snd={gameplay_music_ready:true,boss_music_ready:true,reactive_sfx_ready:true,mus_calm:[8,12],mus_alert:[16,20],mus_boss:[24,28],human_a:48,human_b:49,machine_a:50,machine_b:51,bass_stab:52,launch_stab:53,boom_low:54,boom_top:55,boom_tail:56,opener:57,charge:58,pd:59};audio_reset(); }
function audio_reset() { audio_prev_state=null;audio_bank=null;audio_hold_t=0;audio_react_t=0;audio_voice_chars=0;audio_voice_phase=0; }
function audio_state_enter(ns) { if(ns==='title'){music(0,500);audio_bank=0;}else if(ns==='play'){audio_bank=null;audio_hold_t=0;}else if(ns==='brief'||ns==='help'||ns==='inter'){music(-1,400);audio_bank=null;}else if(ns==='earth_fall'||ns==='boss_intro'){music(-1,120);audio_bank=null;audio_voice_chars=0;audio_voice_phase=0;}else if(ns==='boss_play'){music(-1,60);audio_bank=null;audio_hold_t=0;}else if(ns==='result'){music(-1,250);audio_bank=null;} }
function audio_danger_level() { let n=contacts.length;n+=bombs.length*2;if(packet_i>=3)n+=1;if(packet_i>=4)n+=2;if(earth_core_exposed)n+=2;if(moon_int<=moon_max/2)n+=1;return mid(0,n/8,1); }
function audio_pick_bank(set) { if(set.length<1)return;let pick=set[flr(rnd(set.length))];if(set.length>1&&pick===audio_bank)pick=set[(pick===set[0])?1:0];audio_bank=pick;music(pick);audio_hold_t=480; }
function audio_update_music() { if(audio_hold_t>0)audio_hold_t-=1;if(state==='title')return;if(state==='play'){if(!snd.gameplay_music_ready)return;if(audio_hold_t<=0){if(audio_danger_level()>0.55)audio_pick_bank(snd.mus_alert);else audio_pick_bank(snd.mus_calm);}return;}if(state==='boss_play'){if(!snd.boss_music_ready)return;if(audio_hold_t<=0)audio_pick_bank(snd.mus_boss);} }
function audio_try_react(slot) { if(!snd.reactive_sfx_ready)return;if(audio_react_t>0)return;sfx(slot);audio_react_t=4; }
function audio_on_player_launch(kind,opener) { if(kind==='moon_chunk'||opener)audio_try_react(snd.launch_stab); }
function audio_on_contact_kill(kind) { if(state!=='play'&&state!=='boss_play')return;audio_try_react(snd.bass_stab); }
function audio_on_charge_gain() { if(state!=='play'&&state!=='boss_play')return;audio_try_react(snd.charge); }
function audio_big_boom(kind) { if(!snd.reactive_sfx_ready)return;if(kind==='hero')sfx(snd.boom_low);else if(kind==='tail')sfx(snd.boom_tail); }

function boss_comm_info() { if(boss_intro_t<132)return[boss_text_human,15,12,1,6];return[boss_text_machine,132,12,2,12]; }
function boss_comm_line(txt,rt) { if(boss_intro_t<rt)return'';let n=flr((boss_intro_t-rt)/2)+1;if(n<0)n=0;if(n>txt.length)n=txt.length;return txt.substring(0,n); }
function boss_comm_visible_chars() { const[lines,start_t,step,phase]=boss_comm_info();if(!lines)return[0,0];let n=0;for(let i=0;i<lines.length;i++){const txt=lines[i];if(txt!==''){const rt=start_t+i*step;if(boss_intro_t>=rt){let c=flr((boss_intro_t-rt)/2)+1;if(c<0)c=0;if(c>txt.length)c=txt.length;n+=c;}}}return[n,phase]; }

function audio_update_comm_voice() { if(!snd.reactive_sfx_ready)return;const[chars,phase]=boss_comm_visible_chars();if(phase!==audio_voice_phase){audio_voice_phase=phase;audio_voice_chars=0;}if(chars>audio_voice_chars){for(let i=audio_voice_chars+1;i<=chars;i++){if(i%3===0){if(phase===1)sfx((i%6===0)?snd.human_b:snd.human_a);else sfx((i%6===0)?snd.machine_b:snd.machine_a);}}audio_voice_chars=chars;} }

function draw_comm_panel() {
  const px0=8,py0=22,px1=120,py1=82;const[lines,start_t,step,phase,border_col]=boss_comm_info();if(!lines)return;
  rectfill(px0,py0,px1,py1,0);rect(px0,py0,px1,py1,border_col);
  for(let i=0;i<lines.length;i++){const yy=py0+6+(i+1)*7;const rt=start_t+i*step;const txt=lines[i];if(txt!==''){const shown=boss_comm_line(txt,rt);if(phase===1&&i===4){const pre="long live ",suf2="earth.";const x=64-(pre.length+suf2.length)*2;const np=min(shown.length,pre.length);if(np>0)print(pre.substring(0,np),x,yy,8);if(shown.length>pre.length)print(suf2.substring(0,shown.length-pre.length),x+pre.length*4,yy,11);}else if(phase===1&&i===5){const pre="long live ",suf2="humanity.";const x=64-(pre.length+suf2.length)*2;const np=min(shown.length,pre.length);if(np>0)print(pre.substring(0,np),x,yy,8);if(shown.length>pre.length)print(suf2.substring(0,shown.length-pre.length),x+pre.length*4,yy,12);}else{let col;if(phase===1)col=(i<2)?7:8;else col=(i===0)?6:12;print_center(shown,yy,col);}}}
}

function audio_update() { if(!snd)return;if(audio_prev_state!==state){audio_state_enter(state);audio_prev_state=state;}if(audio_react_t>0)audio_react_t-=1;if(state==='boss_intro')audio_update_comm_voice();audio_update_music(); }

// update functions
function update_title() { upd_earth_orbit();upd_mods();if(btnp(4)){music(-1,400);reset_run();state='brief';}else if(btnp(5)){help_page=1;state='help';} }
function update_help() { upd_earth_orbit();upd_mods();if(btnp(4)){music(-1,400);reset_run();state='brief';}else if(btnp(5)){help_page+=1;if(help_page>5)help_page=1;} }
function update_brief() { upd_earth_orbit();upd_mods();brief_tick+=1;if(btnp(4)||btnp(5)){brief_page+=1;brief_tick=0;if(brief_page>2){state='play';enter_aim({type:'earth_surface',id:'earth_surface',ref:{label:'earth'},label:'earth'});}} }
function update_intermission() { upd_earth_orbit();upd_mods();if(btnp(2))inter.oi=max(0,inter.oi-1);if(btnp(3))inter.oi=min(max(0,inter.opts.length-1),inter.oi+1);if(btnp(4)){if(inter.opts.length>0)apply_upgrade(inter.opts[inter.oi]);inter=null;start_packet(packet_i+1);state='play';} }

function update_earth_fall() {
  earth_fall_t+=1;upd_mods();
  if(earth_fall_t<38){if(earth_damage_level<90)earth_damage_level+=2;if(earth_fall_t%3===0)add(chunk_marks,{lon:rnd(1),lat:(rnd(1)-0.5)*0.8});if(earth_fall_t%6===0){const a=rnd(1);add(fx,{kind:'earth_flash',ex:cos(a)*earth_r*0.8,ey:sin(a)*earth_r*0.8,t:18,mt:18});}if(earth_fall_t%3===0)add(fx,{kind:'smoke',ex:rnd(earth_r*1.6)-earth_r*0.8,ey:rnd(earth_r*1.4)-earth_r*0.7,vx:(rnd(1)-0.5)*0.1,vy:-0.1-rnd(0.06),t:60+flr(rnd(20)),mt:80,col:5});}
  if(earth_fall_t===38){earth_damage_level=100;sfx(12);sfx(7);audio_big_boom('hero');for(const m of mods)m.hp=0;const jl=[],jr=[];for(let i=0;i<=earth_r*2;i++){jl.push(flr(rnd(3)));jr.push(flr(rnd(3)));}earth_halves.push({x:earth_x,y:earth_y,vx:-0.18,vy:-0.04,rot:0,rspd:-0.003,side:'l',age:0,jagged:jl});earth_halves.push({x:earth_x,y:earth_y,vx:0.18,vy:0.04,rot:0,rspd:0.003,side:'r',age:0,jagged:jr});add(fx,{kind:'explosion',x:earth_x,y:earth_y,t:30,mt:30});for(let i=0;i<14;i++){const a=i/14;add(fx,{kind:'smoke',ex:cos(a)*earth_r,ey:sin(a)*earth_r,vx:cos(a)*0.35,vy:sin(a)*0.35,t:40+flr(rnd(20)),mt:60,col:(i%2===0?9:5)});}}
  for(const h of earth_halves){h.x+=h.vx;h.y+=h.vy;h.vy+=0.0015;h.rot+=h.rspd;h.age+=1;}
  for(const f of all(fx)){if(f.kind==='smoke'){f.ex+=(f.vx||0);f.ey+=(f.vy||0);}f.t-=1;if(f.t<=0)del(fx,f);}
  if(earth_fall_t>=96&&!boss_phase_started)init_boss_phase();
}

function draw_earth_half(h) {
  const[oc,lc,lhl]=get_earth_colors();circfill(h.x,h.y,earth_r,oc);const lox=cos(h.rot),loy=sin(h.rot);circfill(h.x+lox,h.y+loy,earth_r-3,lc);circfill(h.x-lox*0.5,h.y-loy*0.5,earth_r-5,lhl);
  if(h.side==='l')rectfill(h.x+1,h.y-earth_r-1,h.x+earth_r+2,h.y+earth_r+1,0);else rectfill(h.x-earth_r-2,h.y-earth_r-1,h.x-1,h.y+earth_r+1,0);
  for(let i=0;i<h.jagged.length;i++){const dy=i-earth_r;const bite=h.jagged[i];for(let j=0;j<=bite;j++){if(h.side==='l')pset(h.x-j,h.y+dy,0);else pset(h.x+j,h.y+dy,0);}}
  if(max(0,1-h.age/100)>0){for(let i=0;i<h.jagged.length;i++){const dy=i-earth_r;if(i%2===0){const gc=(h.age<20)?10:(h.age<50?9:8);if(h.side==='l')pset(h.x-h.jagged[i]-1,h.y+dy,gc);else pset(h.x+h.jagged[i]+1,h.y+dy,gc);}}}
  for(let si=0;si<4;si++){const sa=h.rot+si*0.25;const sx=h.x+cos(sa)*(earth_r*0.5),sy=h.y+sin(sa)*(earth_r*0.4);const dxr=sx-h.x,dyr=sy-h.y;if((h.side==='l'&&dxr<=0)||(h.side==='r'&&dxr>=0)){if(dxr*dxr+dyr*dyr<=(earth_r-2)*(earth_r-2)){pset(sx,sy,5);pset(sx+1,sy,4);}}}
}

function update_moon_fall() {
  moon_fall_t+=1;upd_earth_orbit();upd_mods();
  if(moon_fall_t<=40&&moon_fall_t%2===0){add(moon_craters,{a:rnd(1),r:rnd(moon_r-1)+1,sz:1+flr(rnd(2))});if(moon_craters.length>60)moon_craters.splice(0,1);if(moon_fall_t%4===0)add(moon_bites,{a:rnd(1),sz:1+flr(rnd(2))});}
  if(moon_fall_t===40){for(let i=0;i<5;i++)add(moon_cracks,{a:rnd(1),len:0,max:moon_r+1+flr(rnd(3))});}
  if(moon_fall_t>40&&moon_fall_t<=80){for(const cr of moon_cracks){if(cr.len<cr.max)cr.len+=0.3;}}
  if(moon_fall_t===80){sfx(12);sfx(7);for(let i=0;i<8;i++){const outa=(i/8)+rnd(0.06)-0.03,sa=rnd(1),sr=rnd(moon_r*0.55),spd=0.18+rnd(0.28);moon_shards.push({x:moon_x+cos(sa)*sr,y:moon_y+sin(sa)*sr,vx:cos(outa)*spd,vy:sin(outa)*spd,sz:2+flr(rnd(3)),rot:rnd(1),rspd:(rnd(1)-0.5)*0.025,age:0,trail:[]});}for(let i=0;i<18;i++){const a=rnd(1),spd=0.6+rnd(0.7);moon_shards.push({x:moon_x+(rnd(4)-2),y:moon_y+(rnd(4)-2),vx:cos(a)*spd,vy:sin(a)*spd,sz:0,rot:0,rspd:0,age:0,trail:[]});}}
  for(const s of moon_shards){s.x+=s.vx;s.y+=s.vy;s.rot+=s.rspd;s.age+=1;s.vy+=0.0015;if(s.sz>0&&s.age<80){s.trail.push({x:s.x,y:s.y});if(s.trail.length>6)s.trail.splice(0,1);}}
  for(const f of all(fx)){if(f.kind==='smoke'){f.ex+=(f.vx||0);f.ey+=(f.vy||0);}f.t-=1;if(f.t<=0)del(fx,f);}
  if(moon_fall_t>=200){moon_shards=[];for(let i=0;i<9;i++){const a=i/9,r=4+rnd(14),spd=0.04+rnd(0.05);moon_shards.push({x:moon_x+cos(a)*r,y:moon_y+sin(a)*r,vx:cos(a)*spd,vy:sin(a)*spd,sz:2+flr(rnd(3)),rot:rnd(1),rspd:(rnd(1)-0.5)*0.015,age:40,trail:[]});}state='result';}
}

// === DRAW FUNCTIONS ===
function draw_stars() { for(const s of stars){s.phase+=s.rate;if(s.phase>=1)s.phase-=1;const b=s.phase<0.5?s.phase*2:(1-s.phase)*2;let col;if(s.bright===2)col=b>0.6?7:b>0.3?6:5;else if(s.bright===1)col=b>0.5?6:5;else col=b>0.4?5:1;pset(s.x,s.y,col);} }

function draw_moon_system() {
  circfill(moon_x,moon_y,moon_r,6);pset(moon_x-3,moon_y-3,7);pset(moon_x-4,moon_y-2,7);pset(moon_x-2,moon_y-4,7);pset(moon_x+3,moon_y+3,5);pset(moon_x+4,moon_y+2,5);pset(moon_x+2,moon_y+4,5);
  const ba=earth_theta,mr2=(moon_r-1)*(moon_r-1);for(const cr of moon_craters){const ca=(ba+cr.a)%1,cx=moon_x+cos(ca)*cr.r,cy=moon_y+sin(ca)*cr.r,dx=cx-moon_x,dy=cy-moon_y;if(dx*dx+dy*dy<=mr2){if(cr.sz>=2){pset(cx,cy,0);pset(cx+1,cy,1);pset(cx,cy+1,1);pset(cx+1,cy+1,5);}else{pset(cx,cy,1);pset(cx+1,cy,5);}}}
  const dmg_f=1-moon_int/max(1,moon_max_orig),eff=max(0,dmg_f-0.2);if(eff>0){const n_cracks=flr(eff*8);for(let i=1;i<=n_cracks;i++){const a=((i*0.137)+earth_theta*0.3)%1;line(moon_x+cos(a)*((i%4)*0.8+1),moon_y+sin(a)*((i%4)*0.8+1),moon_x+cos(a+0.02)*((moon_r-1)-((i%3)*0.6)),moon_y+sin(a+0.02)*((moon_r-1)-((i%3)*0.6)),0);if(dmg_f>0.55){const mx2=(moon_x+cos(a)*((i%4)*0.8+1)+moon_x+cos(a+0.02)*((moon_r-1)-((i%3)*0.6)))/2,my2=(moon_y+sin(a)*((i%4)*0.8+1)+moon_y+sin(a+0.02)*((moon_r-1)-((i%3)*0.6)))/2;pset(mx2,my2,1);}}}
  circ(moon_x,moon_y,moon_r,5);for(const b of moon_bites){const ca=(ba+b.a)%1,bx=moon_x+cos(ca)*moon_r,by=moon_y+sin(ca)*moon_r;circfill(bx,by,b.sz,0);pset(bx-b.sz,by,5);pset(bx+b.sz,by,5);pset(bx,by-b.sz,5);pset(bx,by+b.sz,5);}
}

function draw_earth_system() {
  const[oc,lc,lhl]=get_earth_colors();circfill(earth_x,earth_y,earth_r,oc);const er2=(earth_r-1)*(earth_r-1);
  for(let i=0;i<c_lon.length;i++){const lon=c_lon[i]/100,lat=c_lat[i]/100;let rel=(lon-earth_spin+1)%1;if(rel>0.5)rel-=1;if(abs(rel)<0.25){const x=earth_x-sin(rel)*earth_r,y=earth_y+lat*earth_r*2.5,dx=x-earth_x,dy=y-earth_y;if(dx*dx+dy*dy<=er2){const b=cos(rel),col=b>0.85?lhl:lc;pset(x,y,col);if((x+1-earth_x)*(x+1-earth_x)+dy*dy<=er2)pset(x+1,y,col);if(dx*dx+(y+1-earth_y)*(y+1-earth_y)<=er2&&b>0.5)pset(x,y+1,col);}}}
  for(const d of earth_damage){let rel=(d.lon-earth_spin+1)%1;if(rel>0.5)rel-=1;if(abs(rel)<0.25){const x=earth_x-sin(rel)*earth_r,y=earth_y+d.lat*earth_r*2.5,dx=x-earth_x,dy=y-earth_y;if(dx*dx+dy*dy<=er2){let cc,cb;if(d.land){cc=4;cb=9;}else{cc=1;cb=0;}pset(x,y,cc);if((x+1-earth_x)*(x+1-earth_x)+dy*dy<=er2)pset(x+1,y,cc);if(dx*dx+(y+1-earth_y)*(y+1-earth_y)<=er2)pset(x,y+1,cb);if((x+1-earth_x)*(x+1-earth_x)+(y+1-earth_y)*(y+1-earth_y)<=er2)pset(x+1,y+1,cc);}}}
  for(const m of chunk_marks){let rel=(m.lon-earth_spin+1)%1;if(rel>0.5)rel-=1;if(abs(rel)<0.25){const mx2=earth_x-sin(rel)*earth_r,my2=earth_y+m.lat*earth_r*2.5,dxc=mx2-earth_x,dyc=my2-earth_y;if(dxc*dxc+dyc*dyc<=er2){for(let ddy=-3;ddy<=3;ddy++)for(let ddx=-3;ddx<=3;ddx++){const d2v=ddx*ddx+ddy*ddy;if(d2v<=9){const px=mx2+ddx,py=my2+ddy,eex=px-earth_x,eey=py-earth_y;if(eex*eex+eey*eey<=er2)pset(px,py,d2v<=1?0:d2v<=4?5:d2v<=6?4:5);}}}}}
  for(const m of opener_marks){let rel=(m.lon-earth_spin+1)%1;if(rel>0.5)rel-=1;if(abs(rel)<0.25){const mx2=earth_x-sin(rel)*earth_r,my2=earth_y+m.lat*earth_r*2.5,dxc=mx2-earth_x,dyc=my2-earth_y;if(dxc*dxc+dyc*dyc<=er2){const life=1-(m.age/m.max_age);let col;if(life>0.66)col=5;else if(life>0.33)col=4;else col=1;for(let ddx=-1;ddx<=1;ddx++)for(let ddy=-1;ddy<=1;ddy++){const px=mx2+ddx,py=my2+ddy;if((px-earth_x)*(px-earth_x)+(py-earth_y)*(py-earth_y)<=er2)pset(px,py,col);}}}}
  const ice=earth_damage_level>70?6:7;pset(earth_x,earth_y-earth_r+1,ice);pset(earth_x-1,earth_y-earth_r+1,ice);pset(earth_x+1,earth_y-earth_r+1,ice);pset(earth_x,earth_y+earth_r-1,ice);
  for(const m of mods){if(m.kind==='aegis'&&m.hp>0){const half=m.barc||0.07;for(let i=0;i<=14;i++){const a=(m.theta-half+i*(2*half/14)+1)%1,cx=cos(a),cy=sin(a);pset(earth_x+cx*(earth_r+3),earth_y+cy*(earth_r+3),12);pset(earth_x+cx*(earth_r+4),earth_y+cy*(earth_r+4),12);pset(earth_x+cx*(earth_r+5),earth_y+cy*(earth_r+5),1);}}}
  for(const m of mods){if(m.hp>0){const[x,y]=mod_pos(m);const dxe=x-earth_x,dye=y-earth_y;let dl=sqrt(dxe*dxe+dye*dye);if(dl<0.1)dl=1;const ox=dxe/dl,oy=dye/dl,vx=-oy,vy=ox;const mp=(u,v,c)=>{pset(x+u*ox+v*vx,y+u*oy+v*vy,c);};if(m.kind==='driver'){mp(2,0,m.col);mp(1,-2,m.col);mp(1,-1,m.col);mp(1,0,m.col);mp(1,1,m.col);mp(1,2,m.col);mp(0,0,m.col);mp(-1,0,m.col);mp(-2,0,m.col);}else if(m.kind==='jammer'){mp(2,-2,m.col);mp(2,-1,m.col);mp(2,0,m.col);mp(2,1,m.col);mp(2,2,m.col);mp(1,-1,m.col);mp(1,0,m.col);mp(1,1,m.col);mp(0,0,m.col);mp(-1,0,m.col);}else{circfill(x,y,2,m.col);for(let i=0;i<m.mhp;i++)pset(x-1+i*2,y+4,i<m.hp?m.col:5);}}}
}

function contact_dir(c) { if(c.state==='transfer'){const t2=min(1,c.u+0.02),p1=bez2(c.start,c.ctl,c.pend,c.u),p2=bez2(c.start,c.ctl,c.pend,t2);return[p2.x-p1.x,p2.y-p1.y];}else if(c.state==='orbit'){const t2=c.otheta+0.005*c.odir;return[(cos(t2)-cos(c.otheta))*lunar_orbit_r,(sin(t2)-sin(c.otheta))*lunar_orbit_r];}else if(c.state==='dive'){const t2=min(1,c.u+0.02),p1=bez2(c.dstart,c.dctl,c.dend,c.u),p2=bez2(c.dstart,c.dctl,c.dend,t2);return[p2.x-p1.x,p2.y-p1.y];}return[1,0]; }

function draw_enemy(c,px,py) {
  let[vx,vy]=contact_dir(c);if(vx*vx+vy*vy<0.01){vx=1;vy=0;}const sp=sqrt(vx*vx+vy*vy),nx=vx/sp,ny=vy/sp,prpx=-ny,prpy=nx,col=cdefs[c.kind].col;
  if(c.kind==='raider'){pset(px+nx*2,py+ny*2,col);pset(px+nx,py+ny,col);pset(px,py,col);pset(px-nx+prpx,py-ny+prpy,col);pset(px-nx-prpx,py-ny-prpy,col);pset(px-nx*2,py-ny*2,9);}
  else if(c.kind==='bus'){const am=c.accel_mul||0.6;pset(px+nx*3,py+ny*3,col);pset(px+nx*2+prpx,py+ny*2+prpy,col);pset(px+nx*2,py+ny*2,col);pset(px+nx*2-prpx,py+ny*2-prpy,col);pset(px+nx+prpx*2,py+ny+prpy*2,col);pset(px+nx+prpx,py+ny+prpy,col);pset(px+nx,py+ny,col);pset(px+nx-prpx,py+ny-prpy,col);pset(px+nx-prpx*2,py+ny-prpy*2,col);pset(px,py,col);pset(px-nx,py-ny,5);const base_len=1+flr((am-0.55)*2),flicker=(gtick+c.uid)%4,flame_len=min(3,max(1,base_len+(flicker<2?1:0)));for(let i=1;i<=flame_len;i++){const fxp=px-nx*(1+i),fyp=py-ny*(1+i);let fc;if(i===1)fc=10;else if(i<=flame_len-1)fc=9;else fc=8;pset(fxp,fyp,fc);if(i<=1){pset(fxp+prpx,fyp+prpy,9);pset(fxp-prpx,fyp-prpy,9);}}if(am>0.8&&((gtick+c.uid*2)%5)===0){const sj=rnd(3)-1;pset(px-nx*(flame_len+2)+prpx*sj,py-ny*(flame_len+2)+prpy*sj,8);}}
  else if(c.kind==='orbiter'){pset(px+nx*2,py+ny*2,col);pset(px+nx,py+ny,col);pset(px,py,col);pset(px+prpx,py+prpy,13);pset(px-prpx,py-prpy,13);pset(px-nx,py-ny,col);pset(px-nx-prpx,py-ny-prpy,col);pset(px-nx+prpx,py-ny+prpy,col);}
  else{pset(px+nx*2,py+ny*2,col);pset(px+nx,py+ny,col);pset(px,py,6);pset(px-nx,py-ny,col);}
}

function draw_contacts() { const sel=sel_target();for(const c of contacts){const p=contact_pos(c);draw_enemy(c,p.x,p.y);if(sel&&sel.type==='contact'&&sel.id===c.uid)rect(p.x-4,p.y-4,p.x+4,p.y+4,7);} }
function draw_ship(x,y,vx,vy,col,thrust) { let sp=sqrt(vx*vx+vy*vy);if(sp<0.01)sp=1;const nx=vx/sp,ny=vy/sp,px=-ny,py=nx;pset(x+nx*2,y+ny*2,col);pset(x+nx,y+ny,col);pset(x,y,col);pset(x-nx+px,y-ny+py,col);pset(x-nx-px,y-ny-py,col);if(thrust){pset(x-nx*2,y-ny*2,10);pset(x-nx*3,y-ny*3,9);} }
function draw_interceptors() { for(const it of interceptors){let vx=it.vx,vy=it.vy;if(vx*vx+vy*vy<0.01){vx=it.x-moon_x;vy=it.y-moon_y;}draw_ship(it.x,it.y,vx,vy,11,dist({x:it.x,y:it.y},{x:moon_x,y:moon_y})<28);} }

function draw_heavies() {
  for(const h of heavies){if(h.kind==='moon_chunk'&&!h.opener){const n=h.trail.length;for(let i=0;i<n;i++){const tp=h.trail[i],k=(i+1)/n,c=k<0.5?1:(k<0.8?5:6);pset(tp.x,tp.y,c);if(k>0.6)pset(tp.x+1,tp.y,c);if(k>0.7)pset(tp.x,tp.y+1,c);if(k>0.5&&(i+1)%2===0)pset(tp.x-1,tp.y,5);}}else{let tc=1;if(h.kind==='sling')tc=5;if(h.opener)tc=9;for(const tp of h.trail)pset(tp.x,tp.y,tc);}
  let bc=h.col;if(h.opener)bc=10;circfill(h.x,h.y,h.size,bc);
  if(h.opener){circfill(h.x,h.y,1,7);pset(h.x-2,h.y,9);pset(h.x+2,h.y,9);pset(h.x,h.y-2,9);pset(h.x,h.y+2,9);}
  else if(h.kind==='moon_chunk'){circfill(h.x,h.y,h.size-1,5);pset(h.x-1,h.y-1,6);pset(h.x+1,h.y-1,7);pset(h.x+1,h.y+1,1);pset(h.x-1,h.y+1,1);pset(h.x+2,h.y,5);pset(h.x,h.y+2,5);if(h.motor_t&&h.motor_t>0){const vl=sqrt(h.vx*h.vx+h.vy*h.vy);if(vl>0.01){const nx=h.vx/vl,ny=h.vy/vl;circfill(h.x-nx*(h.size+1),h.y-ny*(h.size+1),1,9);pset(h.x-nx*(h.size+1),h.y-ny*(h.size+1),10);pset(h.x-nx*(h.size+2),h.y-ny*(h.size+2),10);}}}}
}

function draw_debris() { for(const d of debris){const r=d.mass>1?lunar_orbit_r:16,x=moon_x+cos(d.theta)*r,y=moon_y+sin(d.theta)*r;const s=d.uid%4;if(s===0){pset(x,y,6);pset(x+1,y,5);pset(x,y+1,13);pset(x+1,y-1,5);}else if(s===1){pset(x-1,y,5);pset(x,y,6);pset(x+1,y,13);pset(x,y+1,5);}else if(s===2){pset(x,y-1,5);pset(x-1,y,13);pset(x,y,6);pset(x,y+1,5);}else{pset(x,y,6);pset(x+1,y+1,5);pset(x-1,y-1,5);pset(x+1,y-1,13);}if(d.hot>0)pset(x,y,10);if(d.claimed){pset(x-2,y-2,5);pset(x+2,y-2,5);pset(x-2,y+2,5);pset(x+2,y+2,5);}} }

function draw_tug() {
  if(!tug)return;const[yx,yy]=moon_site_pos('yard');let tx=yx,ty=yy,has_debris=false;
  for(const d of debris){if(d.uid===tug.tid){const r=d.mass>1?lunar_orbit_r:16;tx=moon_x+cos(d.theta)*r;ty=moon_y+sin(d.theta)*r;has_debris=true;}}
  if(tug.st==='back'&&!has_debris){tx=tug.back_x||yx;ty=tug.back_y||yy;}
  const f=1-(tug.t/max(1,tug.mt)),mx=(yx+tx)*0.5,my=(yy+ty)*0.5,ox=-(my-moon_y)*0.15,oy=(mx-moon_x)*0.15;let x,y;
  if(tug.st==='out'){let ddx=yx-tx,ddy=yy-ty,dl=sqrt(ddx*ddx+ddy*ddy),apx=tx,apy=ty;if(dl>0.5){apx=tx+ddx/dl*3;apy=ty+ddy/dl*3;}x=lerp(lerp(yx,mx+ox,f),lerp(mx+ox,apx,f),f);y=lerp(lerp(yy,my+oy,f),lerp(my+oy,apy,f),f);}
  else if(tug.st==='grab'){let ddx=yx-tx,ddy=yy-ty,dl=sqrt(ddx*ddx+ddy*ddy);if(dl>0.5){x=tx+ddx/dl*3;y=ty+ddy/dl*3;}else{x=tx-3;y=ty;}}
  else{x=lerp(lerp(tx,mx+ox,f),lerp(mx+ox,yx,f),f);y=lerp(lerp(ty,my+oy,f),lerp(my+oy,yy,f),f);}
  tug.lx=x;tug.ly=y;
  if(tug.st==='out')draw_ship(x,y,tx-x,ty-y,10,true);
  else if(tug.st==='back'){draw_ship(x,y,yx-x,yy-y,10,true);if(tug.carry>0){let ddx=yx-x,ddy=yy-y,ddl=sqrt(ddx*ddx+ddy*ddy);if(ddl>0.5){const bx=x-ddx/ddl*2,by=y-ddy/ddl*2;pset(bx,by,6);pset(bx-1,by,13);pset(bx,by-1,5);}}}
  else{pset(x,y,10);pset(x+1,y,10);pset(x-1,y,10);pset(x,y+1,10);pset(x,y-1,10);}
  if(tug.st==='grab'){if(tug.t%3<2)line(x,y,tx,ty,10);for(let i=0;i<4;i++){const sa=(tug.t*0.02+i*0.25)%1,sr=2+(i%2);pset(tx+cos(sa)*sr,ty+sin(sa)*sr,i%2===0?10:9);}}
}

function draw_aim_preview() {
  if(!aim)return;
  if(state==='boss_play'){let px=moon_x+cos(aim.ang)*(moon_r+3),py=moon_y+sin(aim.ang)*(moon_r+3);const dx=cos(aim.ang),dy=sin(aim.ang);for(let i=1;i<=80;i++){px+=dx;py+=dy;if(i%3===0)pset(px,py,7);if(px<0||px>127||py<0||py>127)break;}line(moon_x+cos(aim.ang)*moon_r,moon_y+sin(aim.ang)*moon_r,moon_x+cos(aim.ang)*(moon_r+6),moon_y+sin(aim.ang)*(moon_r+6),7);return;}
  let spd=aim.sp.lspd||launch_spd;const is_sling=aim.sp.id==='sling',is_chunk=aim.sp.id==='moon_chunk';let mot_t=is_chunk?26:0;
  let px=moon_x+cos(aim.ang)*(moon_r+3),py=moon_y+sin(aim.ang)*(moon_r+3),pvx=cos(aim.ang)*spd,pvy=sin(aim.ang)*spd;
  for(let i=1;i<=120;i++){if(mot_t>0){const vl=sqrt(pvx*pvx+pvy*pvy);if(vl>0.01){pvx+=pvx/vl*0.011;pvy+=pvy/vl*0.011;}mot_t-=1;}const dx=earth_x-px,dy=earth_y-py;let d=sqrt(dx*dx+dy*dy);if(d<1)d=1;let g=min(grav_k/(d*d),0.15);if(is_sling)g*=0.4;pvx+=dx/d*g;pvy+=dy/d*g;if(is_sling){const pvl=sqrt(pvx*pvx+pvy*pvy);if(pvl>1.1){pvx=pvx/pvl*1.1;pvy=pvy/pvl*1.1;}}else if(is_chunk){const pvl=sqrt(pvx*pvx+pvy*pvy);if(pvl>0.78){pvx=pvx/pvl*0.78;pvy=pvy/pvl*0.78;}}px+=pvx;py+=pvy;if(i%2===0)pset(px,py,7);if(px<-5||px>132||py<-5||py>132)break;if(d<earth_r+3){circ(px,py,3,10);break;}}
  line(moon_x+cos(aim.ang)*moon_r,moon_y+sin(aim.ang)*moon_r,moon_x+cos(aim.ang)*(moon_r+6),moon_y+sin(aim.ang)*(moon_r+6),7);
}

function draw_fx() {
  for(const f of fx){const p=1-(f.t/(f.mt||10));
  if(f.kind==='impact'){circ(f.x,f.y,flr(p*5),8);if(p<0.3)circfill(f.x,f.y,1,7);}
  else if(f.kind==='explosion'){const r=flr(p*5);circ(f.x,f.y,r,9);if(r>=2)circ(f.x,f.y,r-2,10);if(p<0.4)circfill(f.x,f.y,1,8);if(p>0.1&&p<0.5){pset(f.x+flr(rnd(5))-2,f.y+flr(rnd(5))-2,10);pset(f.x+flr(rnd(5))-2,f.y+flr(rnd(5))-2,9);}}
  else if(f.kind==='miss'){const r=flr(p*3);line(f.x-r,f.y-r,f.x+r,f.y+r,9);line(f.x+r,f.y-r,f.x-r,f.y+r,9);}
  else if(f.kind==='fizz'){if(p<0.5)pset(f.x,f.y,6);if(p<0.3){pset(f.x+1,f.y,5);pset(f.x,f.y+1,5);pset(f.x-1,f.y,5);pset(f.x,f.y-1,5);}}
  else if(f.kind==='block'){const r=flr(p*6);circ(f.x,f.y,r,12);if(r>=2)circ(f.x,f.y,r-2,1);if(p<0.4)pset(f.x,f.y,7);}
  else if(f.kind==='pd_beam'){const c=(f.t%2===0)?8:11;line(f.x0,f.y0,f.x,f.y,c);const dx=f.x-f.x0,dy=f.y-f.y0,dl=sqrt(dx*dx+dy*dy);if(dl>0.5){line(f.x0-dy/dl,f.y0+dx/dl,f.x,f.y,c);line(f.x0+dy/dl,f.y0-dx/dl,f.x,f.y,c);}if(f.t>f.mt-4){circfill(f.x,f.y,2,c);pset(f.x,f.y,7);}else pset(f.x,f.y,c);}
  else if(f.kind==='muzzle'){const r=flr(p*3);circfill(f.x,f.y,r,10);if(r>=1)circ(f.x,f.y,r+1,9);if(p<0.4)pset(f.x,f.y,7);if(p<0.5){const sa=f.t*0.13;pset(f.x+cos(sa)*(r+2),f.y+sin(sa)*(r+2),10);pset(f.x-cos(sa)*(r+2),f.y-sin(sa)*(r+2),10);}}
  else if(f.kind==='sabot'){const r=flr(p*4);circ(f.x,f.y,r,14);circ(f.x,f.y,r+1,2);pset(f.x+flr(rnd(3))-1,f.y+flr(rnd(3))-1,8);}
  else if(f.kind==='denied_blink'){if(p<0.5){pset(f.x,f.y,8);pset(f.x-1,f.y,8);pset(f.x+1,f.y,8);pset(f.x,f.y-1,8);pset(f.x,f.y+1,8);}}
  else if(f.kind==='deliver_ping'){circ(f.x,f.y,flr(p*4),10);if(p<0.4)pset(f.x,f.y,7);}
  else if(f.kind==='repair_spark'){if(p<0.6){pset(f.x,f.y,7);pset(f.x+1,f.y,12);pset(f.x-1,f.y,12);pset(f.x,f.y+1,12);pset(f.x,f.y-1,12);}}
  else if(f.kind==='launch')circ(f.x,f.y,flr(p*4),11);
  else if(f.kind==='launch_heavy')circ(moon_x,moon_y,moon_r+flr(p*4),10);
  else if(f.kind==='chunk_tear'){const r1=moon_r+flr(p*6);circ(moon_x,moon_y,r1,8);circ(moon_x,moon_y,max(0,r1-2),9);if(p<0.5)circ(moon_x,moon_y,max(0,r1-4),10);if(p<0.7)for(let i=0;i<8;i++){const ea=i/8+p*0.1;pset(moon_x+cos(ea)*(moon_r+1+flr(p*8)),moon_y+sin(ea)*(moon_r+1+flr(p*8)),5);}}
  else if(f.kind==='tug_grab')circ(f.x,f.y,flr(p*3),10);
  else if(f.kind==='land_hit'){const sx=earth_x+(f.ex||0),sy=earth_y+(f.ey||0);circ(sx,sy,flr(p*4),9);if(p<0.3){pset(sx,sy,7);pset(sx+1,sy,7);}if(p<0.5)pset(sx,sy-1,8);}
  else if(f.kind==='splash'){const sx=earth_x+(f.ex||0),sy=earth_y+(f.ey||0),r=flr(p*6);circ(sx,sy,r,7);circ(sx,sy,max(0,r-2),12);if(p<0.25){circfill(sx,sy,1,7);pset(sx,sy-1,7);pset(sx-1,sy,7);pset(sx+1,sy,7);}}
  else if(f.kind==='chunk_impact'){const life=f.t/f.mt,sx=earth_x+(f.ex||0),sy=earth_y+(f.ey||0),rr=flr(p*10);circ(sx,sy,rr,14);circ(sx,sy,max(0,rr-2),2);circ(earth_x,earth_y,earth_r+2+flr(p*3),14);if(life>0.6){circfill(sx,sy,3,7);circfill(sx,sy,2,10);}else if(life>0.3){circfill(sx,sy,2,9);pset(sx,sy,7);}else pset(sx,sy,8);if(life>0.2&&life<0.8)for(let i=0;i<4;i++)pset(sx+cos((f.ex||0)*0.1+i*0.25+p)*(rr+1),sy+sin((f.ex||0)*0.1+i*0.25+p)*(rr+1),5);}
  else if(f.kind==='earth_flash'){const life=f.t/f.mt,sx=earth_x+(f.ex||0),sy=earth_y+(f.ey||0);if(life>0.6){circfill(sx,sy,5,7);circ(earth_x,earth_y,earth_r+2,10);}else if(life>0.3){circfill(sx,sy,3,10);circ(earth_x,earth_y,earth_r+1,9);}else circfill(sx,sy,1,9);}
  else if(f.kind==='smoke'){const sx=earth_x+(f.ex||0),sy=earth_y+(f.ey||0),life=f.t/f.mt;let col=f.col||5;if(life<0.3)col=1;pset(sx,sy,col);if(life>0.3)pset(sx+1,sy,col);if(life>0.5)pset(sx,sy-1,col);if(life>0.7){pset(sx-1,sy,col);pset(sx,sy+1,col);}}}
}

function draw_weapon_border() { const sp=current_special();if(!sp)return;let bc=11;if(sp.id==='sling')bc=10;else if(sp.id==='moon_chunk')bc=8;rect(0,0,127,127,bc); }

function draw_hud() {
  print("int",1,1,8);const om=max(1,moon_max_orig),bw=flr(moon_int*8/om),mw=flr(moon_max*8/om);if(bw>0)rectfill(13,1,13+bw,4,8);if(mw<8)rectfill(14+mw,2,20,3,13);rect(13,1,21,4,5);
  print("chg",26,1,12);for(let i=0;i<max_charge;i++)rectfill(38+i*2,1,38+i*2,4,i<charge?12:1);
  const pthresh=upgrades.recycler?1:2;for(let i=0;i<pthresh;i++)pset(38+i*2,6,i<prop?9:1);
  const cbx=38+max_charge*2+2;if(state==='boss_play')print("human revenge",cbx+10,1,8);else{print(""+packet_i,cbx+10,1,6);print(packets[packet_i-1].label,cbx+16,1,7);}
  const sp=current_special();if(aim)print("aiming  z fire  x cancel",1,122,10);
  else{const sp_txt=sp?sp.label:"---";let sp_col=sp?(can_pay_special(sp)?3:2):5;if(fire_denied_t>0&&(fire_denied_t%2===0))sp_col=8;print("x "+sp_txt,1,122,sp_col);if(salvage>0)print("s"+salvage,42,122,10);if(state!=='boss_play'){const sel=sel_target();print(sel?">"+sel.label:"no tgt",54,122,sel?7:5);}print("sc"+score,98,122,7);}
}

function draw_title() { cls(0);draw_stars();draw_earth_system();draw_moon_system();print_center("lunar defense",20,7);print_center("earth approaches the line",38,8);print_center("z begin briefing",86,11);print_center("x field manual",98,3); }
function draw_help() { cls(0);draw_stars();draw_earth_system();draw_moon_system();rectfill(6,14,122,110,0);rect(6,14,122,110,6);print("field manual  "+help_page+"/5",28,18,7);if(help_page===1){print("controls",46,30,11);print("l/r  select target",14,44,12);print("z  fire / confirm",14,56,11);print("x  switch weapon",14,68,3);print("enter pause",14,80,6);}else if(help_page===2){print("enemy glossary",34,30,11);circfill(14,46,1,8);pset(16,46,8);pset(18,46,8);print("raider    fast strike",22,44,7);circfill(14,58,2,10);pset(17,58,8);pset(11,58,9);print("wrecker   heavy hit",22,56,7);circfill(14,70,2,12);circ(14,70,3,1);print("sapper    orbits first",22,68,7);pset(13,82,5);pset(14,82,5);pset(15,82,5);pset(14,81,5);pset(14,83,5);print("decoy     no damage",22,80,6);}else if(help_page===3){print("weapons + economy",26,30,11);print("intcpt  auto defense",12,42,12);print("sling   aim at modules",12,52,6);print("chunk   late heavy hit",12,62,8);print("salvage fuels charges",10,74,10);print("tug auto-grabs debris",6,84,6);}else if(help_page===4){print("upgrades 1/2",36,30,11);const list=['fast_reload','reserve_tanks','patch_crews','recycler','point_defense'];for(let i=0;i<list.length;i++){const m=upgrade_meta[list[i]];print(m.label,10,40+i*12,12);print(m.desc,10,46+i*12,6);}}else{print("upgrades 2/2",36,30,11);const list=['refinery','mass_driver','lunar_shielding','pulse_array'];for(let i=0;i<list.length;i++){const m=upgrade_meta[list[i]];print(m.label,10,42+i*14,12);print(m.desc,10,48+i*14,6);}}print("x next  z start",20,100,10); }
function draw_brief() { cls(0);draw_stars();draw_earth_system();draw_moon_system();rectfill(8,30,120,94,0);rect(8,30,120,94,1);if(brief_page===1){print_center("lunar defense command",36,8);print_center("earth refused withdrawal",54,6);print_center("counterforce approved",66,12);}else{print_center("directive",36,11);print_center("open with defensive salvo",50,7);print_center("silence the ring",62,12);print_center("hold the moon",74,10);}print_center("z continue",88,6); }
function draw_intermission() { cls(0);draw_stars();draw_earth_system();draw_moon_system();rectfill(12,20,116,108,0);rect(12,20,116,108,6);print("packet clear",32,26,11);print("choose upgrade",26,36,7);if(inter.opts.length===0)print("z continue",34,74,7);else{for(let i=0;i<inter.opts.length;i++)print((i===inter.oi?">":"  ")+upg_label(inter.opts[i]),20,48+(i+1)*10,i===inter.oi?7:5);print("u/d select  z ok",18,96,6);} }
function draw_result() { cls(0);draw_stars();if(earth_core_hp>0)draw_earth_system();if(moon_int<=0)draw_moon_shards();else draw_moon_system();let msg,mc;if(moon_int<=0){msg="moon lost";mc=8;}else if(boss_defeated){msg="earth silenced";mc=11;}else{msg="mission clear";mc=11;}print_center(msg,34,mc);print_center("score "+score,50,7);print_center("salvage "+salvage,60,10);print_center("z/x title",102,7); }

function draw_moon_fall() {
  if(moon_fall_t<8){rectfill(0,0,127,127,moon_fall_t%2===0?7:8);return;}
  cls(0);draw_stars();if(earth_core_hp>0)draw_earth_system();
  if(moon_fall_t<80){circfill(moon_x,moon_y,moon_r,5);circfill(moon_x,moon_y,moon_r-2,1);const ba=earth_theta,mr2=(moon_r-1)*(moon_r-1);for(const cr of moon_craters){const ca=(ba+cr.a)%1,cx=moon_x+cos(ca)*cr.r,cy=moon_y+sin(ca)*cr.r;if((cx-moon_x)*(cx-moon_x)+(cy-moon_y)*(cy-moon_y)<=mr2){pset(cx,cy,0);pset(cx+1,cy,0);pset(cx,cy+1,0);if(cr.sz>=2){pset(cx-1,cy,0);pset(cx,cy-1,0);}}}circ(moon_x,moon_y,moon_r,6);for(const b of moon_bites){const ca=(ba+b.a)%1;circfill(moon_x+cos(ca)*moon_r,moon_y+sin(ca)*moon_r,b.sz,0);}for(const cr of moon_cracks){const bx=moon_x+cos(cr.a)*cr.len,by=moon_y+sin(cr.a)*cr.len;line(moon_x,moon_y,bx,by,0);line(moon_x+cos(cr.a+0.01)*cr.len*0.5,moon_y+sin(cr.a+0.01)*cr.len*0.5,bx,by,0);if(cr.len>2){pset(bx,by,8);pset(bx-1,by,9);pset(bx,by-1,9);}}if(moon_fall_t>60){circ(moon_x,moon_y,moon_r-3,8);pset(moon_x,moon_y,9);}}
  if(moon_fall_t>=80&&moon_fall_t<115){const dt=moon_fall_t-80,p2=dt/35;if(dt<25){const r=moon_r+flr(p2*36);circ(moon_x,moon_y,r,dt<6?7:dt<14?10:9);if(r>1)circ(moon_x,moon_y,r-1,dt<6?10:dt<14?9:8);if(r>3)circ(moon_x,moon_y,r-3,8);}if(dt<18){const fr=flr((1-dt/18)*9);if(fr>=0){circfill(moon_x,moon_y,fr,dt<4?7:dt<10?10:9);if(fr>2)circfill(moon_x,moon_y,fr-2,7);}}if(dt<10)for(let i=0;i<12;i++){const ea=i/12+dt*0.01;line(moon_x+cos(ea)*(moon_r+1+dt*0.5),moon_y+sin(ea)*(moon_r+1+dt*0.5),moon_x+cos(ea)*(moon_r+2+dt*2.2),moon_y+sin(ea)*(moon_r+2+dt*2.2),dt<4?7:dt<7?10:9);}}
  if(moon_fall_t>=88){const dt=moon_fall_t-88,df=max(0,1-dt/100);if(df>0.05){const dc=dt<20?5:1;for(let i=0;i<10;i++){const da=i/10+dt*0.004,dr=moon_r+2+dt*0.08;pset(moon_x+cos(da)*dr,moon_y+sin(da)*dr,dc);pset(moon_x+cos(da)*dr*0.6,moon_y+sin(da)*dr*0.6,dc);}}}
  draw_moon_shards();draw_fx();if(moon_fall_t>120){rectfill(28,54,100,66,0);print("moon broken",40,58,8);}
}

function draw_moon_shards() {
  for(const s of moon_shards){if(s.sz===0){let pc=5;if(s.age<8)pc=7;else if(s.age<16)pc=10;else if(s.age<28)pc=9;pset(s.x,s.y,pc);if(s.age<12)pset(s.x-s.vx,s.y-s.vy,s.age<6?10:8);}
  else{for(let i=0;i<s.trail.length;i++){const frac=(i+1)/s.trail.length;let tc=1;if(frac>0.6)tc=5;if(s.age<20&&frac>0.4)tc=(frac>0.7?9:8);pset(s.trail[i].x,s.trail[i].y,tc);}circfill(s.x,s.y,s.sz,5);circfill(s.x,s.y,max(0,s.sz-1),6);if(s.sz>=3)pset(s.x,s.y,1);for(let i=0;i<5;i++){const ba=s.rot+i/5;pset(s.x+cos(ba)*s.sz,s.y+sin(ba)*s.sz,0);if(s.sz>=3)pset(s.x+cos(ba)*(s.sz-1),s.y+sin(ba)*(s.sz-1),1);}pset(s.x-s.sz,s.y,0);pset(s.x+s.sz,s.y,0);pset(s.x,s.y-s.sz,0);pset(s.x,s.y+s.sz,0);if(s.age<28){const gc=s.age<10?10:s.age<20?9:8;pset(s.x,s.y,gc);if(s.sz>=3){pset(s.x-1,s.y,gc);pset(s.x,s.y-1,gc);}}}}
}

function draw_earth_fall() {
  if(earth_fall_t<10){rectfill(0,0,127,127,earth_fall_t%2===0?7:9);return;}
  cls(0);draw_stars();draw_moon_system();
  if(earth_fall_t<60){let ringc=1;if((earth_fall_t%10)<5)ringc=8;circ(moon_x,moon_y,earth_orbit_r,ringc);}
  if(earth_fall_t<38){draw_earth_system();const pr=(earth_fall_t%18)/18,r=earth_r+flr(pr*22);circ(earth_x,earth_y,r,9);if(r>4)circ(earth_x,earth_y,r-3,8);}
  else{const dt=earth_fall_t-38;if(dt<18){const r=earth_r+flr((dt/18)*32);circ(earth_x,earth_y,r,dt<6?7:dt<12?10:9);if(r>2)circ(earth_x,earth_y,r-2,8);}for(const h of earth_halves)draw_earth_half(h);if(dt<6)circfill(earth_x,earth_y,6-dt,7);}
  draw_fx();if(earth_fall_t>55){rectfill(26,54,102,66,0);print("earth silenced",32,58,8);}
}

function update_play() {
  if(btnp(6))paused=!paused;if(paused)return;upd_earth_orbit();upd_mods();
  if(aim){if(btnp(0))aim.cx-=4;if(btnp(1))aim.cx+=4;if(btnp(2))aim.cy-=10;if(btnp(3))aim.cy+=10;aim.cx=mid(2,aim.cx,126);aim.cy=mid(2,aim.cy,126);aim.ang=atan2(aim.cx-moon_x,aim.cy-moon_y);if(btnp(4))fire_aimed();if(btnp(5)&&war_started){aim=null;set_special('counter');sel_id=null;}}
  else{if(btnp(0)||btnp(2))cycle_target(-1);if(btnp(1)||btnp(3))cycle_target(1);if(btnp(5))cycle_special(1);if(btnp(4)){const t=sel_target();if(t){if(t.type==='contact')launch_auto_lock(t.id);else enter_aim(t);}}}
  if(interceptor_cd>0)interceptor_cd-=1;if(fire_denied_t>0)fire_denied_t-=1;
  if(war_started){const p=packets[packet_i-1];while(wave_i<p.waves.length&&packet_tick>=p.waves[wave_i].t){const w=p.waves[wave_i];spawn_contact(w.src,w.kind,w.plan,w.tid);wave_i+=1;}if(p.core_strike){p4_timer+=1;const interval=max(50,140-p4_wave_count*5);if(p4_timer>=interval){p4_timer=0;const sl=['outpost','yard','vault'];spawn_contact('earth',(p4_wave_count%4===3)?'bus':'raider','transfer',sl[p4_wave_count%3]);p4_wave_count+=1;}}}
  upd_contacts();upd_interceptors();upd_heavies();upd_bombs();upd_debris();upd_point_defense();auto_tug();upd_tug();upd_opener_marks();
  if(state!=='play')return;if(war_started){upd_charge_regen();upd_module_pressure();upd_moon_heal();}
  for(const f of all(fx)){if(f.kind==='smoke'){f.ex+=(f.vx||0);f.ey+=(f.vy||0);}f.t-=1;if(f.t<=0)del(fx,f);}
  if(moon_int<=0){moon_fall_t=0;moon_cracks=[];moon_shards=[];sfx(12);state='moon_fall';return;}
  if(war_started){if(packet_done()){if(packet_i<packets.length)start_intermission();else state='result';return;}packet_tick+=1;}
  gtick+=1;
}

// Boss phase
const boss_cannon_pos=[{u:-5,v:3},{u:-2,v:3},{u:2,v:3},{u:5,v:3}];

function init_boss_phase() {
  contacts=[];interceptors=[];heavies=[];bombs=[];debris=[];tug=null;inter=null;aim=null;
  const dx=earth_x-moon_x,dy=earth_y-moon_y;const start_theta=atan2(dx,dy),init_omega=0.0011,orbit_r=52;
  boss={theta:start_theta,omega:init_omega,target_omega:init_omega,cruise_omega:init_omega,orbit_r:orbit_r,x:moon_x+cos(start_theta)*orbit_r,y:moon_y+sin(start_theta)*orbit_r,prev_x:moon_x+cos(start_theta-init_omega)*orbit_r,prev_y:moon_y+sin(start_theta-init_omega)*orbit_r,fwx:1,fwy:0,hp:15,max_hp:15,hit_flash:0,invuln_t:0,dodge_lock_t:0,dodge_t:0,fire_t:40,salvo_i:0,salvo_t:0,salvo_pattern:1,salvo_count:0,thrust_t:0,turn_t:0,reveal:0,dying:false,dying_t:0,damage:[]};
  shield_a={theta:0.75,arc:0.055,spd:0.006,col:12};shield_b={theta:0.25,arc:0.055,spd:0.006,col:12};shield_deploy_t=24;boss_shots=[];boss_pattern_i=1;boss_fire_cd=0;boss_hint_t=240;
  unlocked_specials.sling=true;unlocked_specials.moon_chunk=true;set_special('sling');aim=null;
  boss_text_human=["incoming transmission...","origin: earth civil defense","","darn you clankers!","long live earth.","long live humanity."];boss_text_machine=["","transmission received.","defense authorized."];boss_text=boss_text_human;audio_voice_chars=0;audio_voice_phase=0;boss_intro_t=0;boss_phase_started=true;state='boss_intro';
}

function update_boss_intro() {
  boss_intro_t+=1;for(const h of earth_halves){h.x+=h.vx;h.y+=h.vy;h.vy+=0.0015;h.rot+=h.rspd;h.age+=1;}
  for(const f of all(fx)){if(f.kind==='smoke'){f.ex+=(f.vx||0);f.ey+=(f.vy||0);}f.t-=1;if(f.t<=0)del(fx,f);}
  if(boss_intro_t<30)boss.reveal=0;else if(boss_intro_t<160)boss.reveal=(boss_intro_t-30)/130;else boss.reveal=1;
  boss.prev_x=boss.x;boss.prev_y=boss.y;boss.theta=(boss.theta+boss.omega)%1;boss.x=moon_x+cos(boss.theta)*boss.orbit_r;boss.y=moon_y+sin(boss.theta)*boss.orbit_r;
  const eps=0.0008,ex1=moon_x+cos(boss.theta-eps)*boss.orbit_r,ey1=moon_y+sin(boss.theta-eps)*boss.orbit_r,ex2=moon_x+cos(boss.theta+eps)*boss.orbit_r,ey2=moon_y+sin(boss.theta+eps)*boss.orbit_r;let tdx=ex2-ex1,tdy=ey2-ey1,tdl=sqrt(tdx*tdx+tdy*tdy);if(tdl>0.001){const s=(boss.omega>=0)?1:-1;boss.fwx=tdx/tdl*s;boss.fwy=tdy/tdl*s;}
  if(boss_intro_t>=220){earth_halves=[];state='boss_play';}
}

function draw_boss_intro() { cls(0);draw_stars();let show=true;if(boss_intro_t>=180)show=false;else if(boss_intro_t>=140)show=(boss_intro_t%3===0);else if(boss_intro_t>=90)show=(boss_intro_t%2===0);if(show)for(const h of earth_halves)draw_earth_half(h);draw_moon_system();draw_boss();draw_comm_panel();draw_fx(); }

function update_boss_play() {
  if(btnp(6))paused=!paused;if(paused)return;
  if(aim){if(btnp(0))aim.cx-=4;if(btnp(1))aim.cx+=4;if(btnp(2))aim.cy-=10;if(btnp(3))aim.cy+=10;aim.cx=mid(2,aim.cx,126);aim.cy=mid(2,aim.cy,126);aim.ang=atan2(aim.cx-moon_x,aim.cy-moon_y);if(btnp(4))fire_aimed();if(btnp(5))aim=null;}
  else{if(btn(0))shield_a.theta=(shield_a.theta-shield_a.spd+1)%1;if(btn(1))shield_a.theta=(shield_a.theta+shield_a.spd)%1;if(btn(2))shield_b.theta=(shield_b.theta-shield_b.spd+1)%1;if(btn(3))shield_b.theta=(shield_b.theta+shield_b.spd)%1;if(btnp(5)){const sp=current_special();if(sp&&sp.id==='sling')set_special('moon_chunk');else set_special('sling');}if(btnp(4))enter_aim({type:'boss',id:'boss',ref:boss,label:'ship'});}
  upd_heavies();upd_charge_regen();if(!boss.dying)update_boss_ai();update_boss_shots();
  for(const f of all(fx)){if(f.kind==='smoke'){f.ex+=(f.vx||0);f.ey+=(f.vy||0);}f.t-=1;if(f.t<=0)del(fx,f);}
  if(boss.hit_flash>0)boss.hit_flash-=1;if(boss.dodge_lock_t>0)boss.dodge_lock_t-=1;if(boss.invuln_t>0)boss.invuln_t-=1;if(boss_hint_t>0)boss_hint_t-=1;if(shield_deploy_t>0)shield_deploy_t-=1;if(fire_denied_t>0)fire_denied_t-=1;
  if(moon_int<=0){moon_fall_t=0;moon_cracks=[];moon_shards=[];result_mode='moon_lost';sfx(12);state='moon_fall';return;}
  if(boss.hp<=0&&!boss.dying){boss.dying=true;boss.dying_t=0;add(fx,{kind:'explosion',x:boss.x,y:boss.y,t:30,mt:30});add(fx,{kind:'explosion',x:boss.x,y:boss.y,t:24,mt:24});sfx(7);audio_big_boom('hero');for(let i=0;i<16;i++){const a=i/16+rnd(0.04),sp=0.4+rnd(0.6);add(bombs,{boss_debris:true,x:boss.x+(rnd(1)-0.5)*6,y:boss.y+(rnd(1)-0.5)*6,vx:cos(a)*sp,vy:sin(a)*sp,ttl:120+flr(rnd(40)),col:(i%3===0?9:i%3===1?8:5),sz:1+flr(rnd(2))});}}
  if(boss.dying){boss.dying_t+=1;if(boss.dying_t%5===0)add(fx,{kind:'explosion',x:boss.x+(rnd(1)-0.5)*18,y:boss.y+(rnd(1)-0.5)*10,t:16+flr(rnd(12)),mt:26});if(boss.dying_t%15===0){add(fx,{kind:'explosion',x:boss.x,y:boss.y,t:22,mt:22});for(let j=0;j<4;j++)add(fx,{kind:'explosion',x:boss.x+cos(rnd(1))*6,y:boss.y+sin(rnd(1))*6,t:12,mt:12});sfx(6);audio_big_boom('tail');}for(const b of all(bombs)){if(b.boss_debris){b.x+=b.vx;b.y+=b.vy;b.vx*=0.98;b.vy*=0.98;b.ttl-=1;if(b.ttl<=0)del(bombs,b);}}boss.omega*=0.96;boss.theta=(boss.theta+boss.omega)%1;boss.x=moon_x+cos(boss.theta)*boss.orbit_r;boss.y=moon_y+sin(boss.theta)*boss.orbit_r;if(boss.dying_t===120){for(let i=0;i<6;i++)add(fx,{kind:'explosion',x:boss.x+(rnd(1)-0.5)*8,y:boss.y+(rnd(1)-0.5)*8,t:36,mt:36});sfx(7);audio_big_boom('hero');}if(boss.dying_t>=170){boss_defeated=true;result_mode='boss_win';state='result';}}
  gtick+=1;
}

function update_boss_ai() {
  boss.omega=lerp(boss.omega,boss.target_omega,0.05);boss.prev_x=boss.x;boss.prev_y=boss.y;boss.theta=(boss.theta+boss.omega)%1;boss.x=moon_x+cos(boss.theta)*boss.orbit_r;boss.y=moon_y+sin(boss.theta)*boss.orbit_r;
  const eps=0.0008,ex1=moon_x+cos(boss.theta-eps)*boss.orbit_r,ey1=moon_y+sin(boss.theta-eps)*boss.orbit_r,ex2=moon_x+cos(boss.theta+eps)*boss.orbit_r,ey2=moon_y+sin(boss.theta+eps)*boss.orbit_r;let tdx=ex2-ex1,tdy=ey2-ey1,tdl=sqrt(tdx*tdx+tdy*tdy);if(tdl>0.001){const s=(boss.omega>=0)?1:-1;boss.fwx=tdx/tdl*s;boss.fwy=tdy/tdl*s;}
  if(boss.thrust_t>0)boss.thrust_t-=1;if(boss.dodge_t>0){boss.dodge_t-=1;if(boss.dodge_t===0){const sg=(boss.target_omega>=0)?1:-1;boss.target_omega=sg*boss.cruise_omega;}}
  boss.turn_t+=1;if(boss.dodge_t<=0&&boss.turn_t>260+flr(rnd(160))){boss.target_omega=((boss.target_omega>=0)?-1:1)*boss.cruise_omega;boss.thrust_t=28;boss.turn_t=0;}
  if(boss.salvo_count>0){boss.salvo_t-=1;if(boss.salvo_t<=0&&boss.salvo_i<boss.salvo_count){spawn_boss_shot(boss.salvo_pattern,boss.salvo_i);boss.salvo_i+=1;boss.salvo_t=16+flr(rnd(6));}if(boss.salvo_i>=boss.salvo_count&&boss.salvo_t<=0){boss.salvo_count=0;boss.fire_t=90+flr(rnd(45));}}
  else{boss.fire_t-=1;if(boss.fire_t<=0){boss.salvo_pattern=boss_pattern_i;boss.salvo_count=4;boss.salvo_i=0;boss.salvo_t=0;boss_pattern_i=(boss_pattern_i%3)+1;}}
  boss_try_dodge();
}

function boss_try_dodge() { if(boss.dodge_lock_t>0)return;let best_d=99999,best_heavy=null;for(const s of heavies){if(s.straight&&!s.opener&&!s.dodged){for(let i=1;i<=60;i++){const px=s.x+s.vx*i,py=s.y+s.vy*i,th=boss.theta+boss.omega*i;const dd=d2(px,py,moon_x+cos(th)*boss.orbit_r,moon_y+sin(th)*boss.orbit_r);if(dd<best_d){best_d=dd;best_heavy=s;}}}}if(best_d<324&&best_heavy){best_heavy.dodged=true;const sg=-((boss.target_omega>=0)?1:-1);boss.omega=sg*0.002;boss.target_omega=sg*0.0038;boss.thrust_t=48;boss.dodge_lock_t=10;boss.dodge_t=60;} }

function spawn_boss_shot(pattern,index) { const cannon=boss_cannon_pos[index%4],fwx=boss.fwx||1,fwy=boss.fwy||0;let tmx=moon_x-boss.x,tmy=moon_y-boss.y,tml=sqrt(tmx*tmx+tmy*tmy);if(tml<0.1)tml=1;tmx/=tml;tmy/=tml;const wx=boss.x+cannon.u*fwx+cannon.v*tmx,wy=boss.y+cannon.u*fwy+cannon.v*tmy;const ang=atan2(moon_x-wx,moon_y-wy);let off;if(index===0)off=0;else if(pattern===1)off=(index-2.5)*0.11;else if(pattern===2)off=((index%2===0)?0.19:-0.19)+(rnd(0.05)-0.025);else off=(index-2.5)*0.14;boss_shots.push({physics:true,x:wx,y:wy,cannon_u:cannon.u,cannon_v:cannon.v,vx:cos(ang+off)*(0.45+rnd(0.08)),vy:sin(ang+off)*(0.45+rnd(0.08)),dmg:2,ttl:180,tel_t:20,age:0,trail:[]}); }

function update_boss_shots() {
  for(const s of all(boss_shots)){if(s.tel_t!==undefined&&s.tel_t>0){s.tel_t-=1;if(s.cannon_u!==undefined&&boss.fwx!==undefined){let tmx=moon_x-boss.x,tmy=moon_y-boss.y,tml=sqrt(tmx*tmx+tmy*tmy);if(tml<0.1)tml=1;tmx/=tml;tmy/=tml;s.x=boss.x+s.cannon_u*boss.fwx+s.cannon_v*tmx;s.y=boss.y+s.cannon_u*boss.fwy+s.cannon_v*tmy;}if(s.tel_t===0){add(fx,{kind:'muzzle',x:s.x,y:s.y,t:10,mt:10});sfx(14);}}
  else{const dx=moon_x-s.x,dy=moon_y-s.y,dm2=dx*dx+dy*dy;let d=sqrt(dm2);if(d<1)d=1;s.vx+=dx/d*min(0.12,20/dm2);s.vy+=dy/d*min(0.12,20/dm2);s.vx*=0.997;s.vy*=0.997;s.trail.push({x:s.x,y:s.y});if(s.trail.length>3)s.trail.splice(0,1);s.x+=s.vx;s.y+=s.vy;s.ttl-=1;s.age+=1;
  if(boss_shot_hits_shield(s)){add(fx,{kind:'block',x:s.x,y:s.y,t:14,mt:14});sfx(5);del(boss_shots,s);}
  else if(dm2<=(moon_r+1)*(moon_r+1)){let ix=s.x,iy=s.y;if(d>0.01){ix=moon_x-dx/d*(moon_r+1);iy=moon_y-dy/d*(moon_r+1);}moon_int=max(0,moon_int-(s.dmg||1));add(fx,{kind:'explosion',x:ix,y:iy,t:18,mt:18});add(fx,{kind:'impact',x:ix,y:iy,t:20,mt:20});add_moon_crater(ix,iy,1);sfx(8);del(boss_shots,s);}
  else if(s.ttl<=0||s.x<-12||s.x>139||s.y<-12||s.y>139)del(boss_shots,s);}}
}

function boss_shot_hits_shield(s) { const dx=s.x-moon_x,dy=s.y-moon_y,rr=sqrt(dx*dx+dy*dy);if(rr<shield_r-3||rr>shield_r+3)return false;const sa=atan2(dx,dy);for(const sh of[shield_a,shield_b]){if(abs((sa-sh.theta+0.5+1)%1-0.5)<sh.arc)return true;}return false; }
function boss_take_hit(dmg,kind) { if(boss.invuln_t>0||boss.dying)return;boss.hp=max(0,boss.hp-dmg);boss.hit_flash=6;boss.invuln_t=2;sfx(9);for(let i=0;i<1+dmg;i++)boss.damage.push({u:(rnd(1)-0.5)*14,v:(rnd(1)-0.5)*5,sz:(kind==='moon_chunk')?1:0}); }

function draw_boss_play() {
  cls(0);draw_stars();draw_moon_system();draw_shields();draw_heavies();if(!boss.dying||boss.dying_t<120)draw_boss();
  if(boss.dying){for(const b of bombs){if(b.boss_debris){const col=(b.ttl/160<0.3)?5:b.col;if(b.sz>=2){circfill(b.x,b.y,1,col);pset(b.x-b.vx,b.y-b.vy,5);}else pset(b.x,b.y,col);}}if(boss.dying_t>=120&&boss.dying_t<140){const ff=1-(boss.dying_t-120)/20;if(ff>0.6)rectfill(0,0,127,127,7);else if(ff>0.3){rect(0,0,127,127,10);rect(1,1,126,126,9);}}}
  draw_boss_shots();draw_aim_preview();draw_fx();draw_hud();draw_weapon_border();
  if(paused){rectfill(16,36,112,92,0);rect(16,36,112,92,6);print_center("paused",40,7);print_center("defend the moon",52,6);}
}

function draw_arc_shield(sh) { let dep=1;if(shield_deploy_t>0)dep=1-(shield_deploy_t/24);const rmid=moon_r+1+(shield_r-moon_r-1)*dep,arc=sh.arc*dep;for(let i=0;i<=14;i++){const f2=(i/14-0.5)*2,a=sh.theta+f2*arc,cx=cos(a),sy2=sin(a);pset(moon_x+cx*rmid,moon_y+sy2*rmid,7);pset(moon_x+cx*(rmid-1),moon_y+sy2*(rmid-1),sh.col);pset(moon_x+cx*(rmid+1),moon_y+sy2*(rmid+1),sh.col);}if(dep>0.3){pset(moon_x+cos(sh.theta-arc)*rmid,moon_y+sin(sh.theta-arc)*rmid,12);pset(moon_x+cos(sh.theta+arc)*rmid,moon_y+sin(sh.theta+arc)*rmid,12);} }
function draw_shields() { draw_arc_shield(shield_a);draw_arc_shield(shield_b); }

function draw_boss() {
  if(!boss)return;const rv=boss.reveal||1;if(rv<=0)return;const stipple=(rv<1);
  const rvpset=(x,y,c)=>{if(stipple){if((flr(x)+flr(y)+flr(boss_intro_t*0.5))%10>=flr(rv*10))return;}pset(x,y,c);};
  const fwx=boss.fwx||1,fwy=boss.fwy||0,mdx=boss.x-boss.prev_x,mdy=boss.y-boss.prev_y,mdl=sqrt(mdx*mdx+mdy*mdy);const pxd=-fwy,pyd=fwx;
  const bp=(u,v)=>[boss.x+u*fwx+v*pxd,boss.y+u*fwy+v*pyd];
  const hc=(boss.hit_flash>0)?8:13,hl=(boss.hit_flash>0)?14:6,hd=(boss.hit_flash>0)?2:1;
  for(let u=-7;u<=7;u++)for(let v=-2;v<=2;v++){let c=hc;if(v===-2||v===2)c=hl;if(u===-7||u===7)c=hd;const[px,py]=bp(u,v);rvpset(px,py,c);}
  for(let v=-1;v<=1;v++){const[lx,ly]=bp(-9,v);rvpset(lx,ly,hd);const[rx,ry]=bp(9,v);rvpset(rx,ry,hd);}
  rvpset(...bp(-8,0),5);rvpset(...bp(8,0),5);
  for(let u=-2;u<=2;u++){rvpset(...bp(u,-3),6);rvpset(...bp(u,3),6);}rvpset(...bp(0,-3),7);rvpset(...bp(0,3),7);
  for(const d of boss.damage){const[du,dv]=bp(d.u,d.v);pset(du,dv,0);if(d.sz>=1){pset(...bp(d.u+0.5,d.v),0);pset(...bp(d.u,d.v+0.5),0);}}
  const burn_len=min(5,1+flr(min(1,mdl*40)*1.5)+((boss.thrust_t>0)?flr(boss.thrust_t/12):0));
  for(let i=1;i<=burn_len;i++){rvpset(...bp(-9-i,0),i<=1?10:(i<=burn_len-1?9:8));if(i<=min(2,burn_len-1)){rvpset(...bp(-9-i,-1),9);rvpset(...bp(-9-i,1),9);}}
  if(boss.thrust_t>8)rvpset(...bp(-9,0),7);
}

function draw_boss_shots() {
  for(const s of boss_shots){if(s.tel_t!==undefined&&s.tel_t>0){if((s.tel_t%3)<2)pset(s.x,s.y,9);}
  else{const age=s.age||0;if(s.trail&&age<20){for(let i=0;i<s.trail.length;i++){const k=(i+1)/s.trail.length;let c;if(age<6)c=k<0.3?9:k<0.7?10:7;else if(age<12)c=k<0.4?5:k<0.75?9:10;else c=k<0.5?5:6;pset(s.trail[i].x,s.trail[i].y,c);}}rectfill(s.x-1,s.y-1,s.x,s.y,age<6?10:age<16?9:age<45?8:13);if(age<10)pset(s.x,s.y,7);}}
}

// ===================================================================
// 5. MAIN LOOP
// ===================================================================

function _init() { parseSFXData();gen_stars();gen_moon_craters();upd_earth_orbit();start_packet(1);state='title';audio_boot(); }

function _update() {
  _update_input();
  if(state==='title')update_title();else if(state==='help')update_help();else if(state==='brief')update_brief();else if(state==='play')update_play();else if(state==='inter')update_intermission();else if(state==='earth_fall')update_earth_fall();else if(state==='boss_intro')update_boss_intro();else if(state==='boss_play')update_boss_play();else if(state==='moon_fall')update_moon_fall();
  else if(state==='result'){upd_earth_orbit();upd_mods();if(moon_int<=0){for(const s of moon_shards){s.x+=s.vx;s.y+=s.vy;s.rot+=s.rspd;s.age+=1;if(s.x<-4)s.x=131;if(s.x>131)s.x=-4;if(s.y<-4)s.y=131;if(s.y>131)s.y=-4;}}if(btnp(4)||btnp(5)){music(0,500);state='title';}}
  audio_update();
}

function _draw() {
  if(state==='title')draw_title();else if(state==='help')draw_help();else if(state==='brief')draw_brief();
  else if(state==='play'){cls(0);draw_stars();draw_earth_system();draw_moon_system();draw_contacts();draw_interceptors();draw_heavies();draw_bombs();draw_debris();draw_tug();draw_aim_preview();draw_fx();draw_hud();draw_weapon_border();if(paused){rectfill(16,36,112,92,0);rect(16,36,112,92,6);print("paused",48,40,7);print("l/r cycle target",24,52,12);print("z act on target",22,62,11);print("x switch weapon",24,72,3);print("aim to strike earth",18,82,6);}}
  else if(state==='inter')draw_intermission();else if(state==='earth_fall')draw_earth_fall();else if(state==='boss_intro')draw_boss_intro();else if(state==='boss_play')draw_boss_play();else if(state==='moon_fall')draw_moon_fall();else if(state==='result')draw_result();
  ctx.putImageData(IMG,0,0);
}

// Canvas scaling
function resizeCanvas() { const w=window.innerWidth,h=window.innerHeight-60;const s=Math.max(1,Math.floor(Math.min(w/128,h/128)));canvas.style.width=(128*s)+'px';canvas.style.height=(128*s)+'px'; }
window.addEventListener('resize',resizeCanvas);resizeCanvas();

// Start button / Audio init
const startBtn=document.getElementById('start-btn');
startBtn.style.display='block';
startBtn.addEventListener('click',()=>{
  if(!audioCtx){audioCtx=new(window.AudioContext||window.webkitAudioContext)();audioInitialized=true;}
  startBtn.style.display='none';_init();
  const FRAME_MS=1000/20;
  let lastTick=performance.now();
  function gameLoop(){
    const now=performance.now();
    if(now-lastTick>=FRAME_MS){
      lastTick=now;
      _update();
      _draw();
    }
    requestAnimationFrame(gameLoop);
  }
  requestAnimationFrame(gameLoop);music(0,500);
});
