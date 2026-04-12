pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- lunar defense v6.3

-- geometry
moon_x=64 moon_y=64 moon_r=9
earth_orbit_r=54 earth_r=9
earth_theta=0.029 earth_omega=0.00135
earth_x=64 earth_y=64
earth_spin=0
earth_core_hp=5 earth_core_exposed=false
module_ring_r=13 lunar_orbit_r=22
moon_craters={}
moon_bites={}
earth_damage={}
earth_damage_level=0
opener_marks={}
chunk_marks={}
p4_timer=0 p4_wave_count=0

-- continents (lon*100, lat*100)
-- eurasia, africa, n.america, s.america, australia
c_lon={3,6,9,12,15,18,0,3,6,9,12,15,18,21,3,6,9,12,15,18,21,24,6,9,12,15,18,21,24,9,12,15,18,9,12,15,12,15,12,15,12,45,48,51,54,57,60,45,48,51,54,57,60,48,51,54,57,51,54,54,54,57,54,57,54,54,30,33,36,33,36,39}
c_lat={-32,-32,-32,-32,-32,-32,-24,-24,-24,-24,-24,-24,-24,-24,-16,-16,-16,-16,-16,-16,-16,-16,-8,-8,-8,-8,-8,-8,-8,0,0,0,0,8,8,8,16,16,24,24,32,-32,-32,-32,-32,-32,-32,-24,-24,-24,-24,-24,-24,-16,-16,-16,-16,-8,-8,0,8,8,16,16,24,32,16,16,16,24,24,24}
grav_k=120
launch_spd=1.2
aim_rate=0.005

-- dev cheat flag: set true for fast testing (unlimited charge + boss skip key)
-- set to false for normal play
dev_mode=false

-- state
gtick=0 state="title" paused=false
sel_id=nil spec_i=1
packet_i=1 packet_tick=0 wave_i=1
score=0 moon_int=22 moon_max=22 moon_max_orig=22
salvage=0 prop=0
charge=1 max_charge=3
upgrades={} unlocked_specials={counter=true}
contacts={} interceptors={} heavies={} bombs={}
debris={} fx={} tug=nil inter=nil
aim=nil
stars={}
war_started=false opening_shot_fired=false
brief_page=1 brief_tick=0
help_page=1 earth_fall_t=0 moon_fall_t=0
moon_cracks={} moon_shards={} earth_halves={}
charge_regen_t=0 moon_heal_t=0
fire_denied_t=0

-- boss phase state (post-earth-death final fight)
boss=nil
boss_intro_t=0
boss_defeated=false
boss_phase_started=false
result_mode=nil
boss_shots={}
boss_pattern_i=1
boss_fire_cd=0
boss_hint_t=0
shield_deploy_t=0
-- two curved arc shields orbit the moon at shield_r; theta = center angle
shield_a=nil shield_b=nil
shield_r=14
boss_text=nil
boss_text_human=nil boss_text_machine=nil

-- audio conductor state
snd=nil
audio_prev_state=nil
audio_bank=nil
audio_hold_t=0
audio_react_t=0
audio_voice_chars=0
audio_voice_phase=0

-- display labels (internal kinds keep legacy names)
clabels={raider='raider',bus='wrecker',orbiter='sapper',screen='decoy'}

-- hidden route anchors (used for arc-shaping only, not cooldown buckets)
sites={
 {id='outpost',ang=0},
 {id='yard',ang=0.25},
 {id='vault',ang=0.5},
}
-- single global interceptor cooldown replaces the old per-site buckets
interceptor_cd=0

cdefs={
 raider={hp=1,spd=0.0075,idmg=1,salv=1,col=8},
 bus={hp=2,spd=0.0050,idmg=6,salv=2,col=10},
 orbiter={hp=2,spd=0.0060,idmg=3,salv=2,col=12,orbit=true},
 screen={hp=1,spd=0.0050,idmg=0,salv=0,col=5},
}

sdefs={
 counter={id='counter',label='intcpt',cost=1,cint=0,scost=0,dmg=1,col=12,lspd=1.1},
 sling={id='sling',label='sling',cost=2,cint=0,scost=0,dmg=2,col=6,lspd=0.65},
 moon_chunk={id='moon_chunk',label='chunk',cost=3,cint=3,scost=0,dmg=3,col=6,lspd=0.4},
}
special_order={'counter','sling','moon_chunk'}

mdefs={
 driver={hp=2,theta=0.013,omega=0.0032,col=8,label='shipyard',cool_init=150,cool_re=180},
 jammer={hp=2,theta=0.374,omega=0.0021,col=10,label='jammer',cool_init=100,cool_re=140},
 aegis={hp=4,theta=0.788,omega=0.0041,col=12,label='aegis',barc=0.07},
}

-- human-readable upgrade info (no underscores in labels).
-- label used in intermission; desc used in field manual.
upgrade_meta={
 fast_reload={label='fast reload',desc='charge regens faster'},
 reserve_tanks={label='reserve tanks',desc='raise max charge to 5'},
 patch_crews={label='patch crews',desc='better scrap repairs'},
 recycler={label='recycler',desc='faster tug, easier charges'},
 point_defense={label='point defense',desc='auto-zap near threats'},
 refinery={label='refinery',desc='delivered mass doubled'},
 mass_driver={label='mass driver',desc='chunks hit harder'},
 lunar_shielding={label='lunar shielding',desc='+2 max moon integrity'},
 pulse_array={label='pulse array',desc='long-range auto-zap'},
}
function upg_label(id)
 local m=upgrade_meta[id]
 return m and m.label or id
end

packets={
 {
  label='opening claim',
  mods={},unlock=nil,
  upgrades={'fast_reload','reserve_tanks','patch_crews'},
  waves={
   {80,'earth','raider','transfer','outpost'},
   {100,'earth','raider','transfer','yard'},
   {115,'earth','screen','transfer','outpost'},
   {130,'earth','raider','transfer','vault'},
   {170,'earth','raider','transfer','yard'},
   {220,'earth','raider','transfer','outpost'},
   {260,'earth','raider','transfer','yard'},
   {300,'earth','raider','transfer','vault'},
   {340,'earth','bus','transfer','outpost'},
   {345,'earth','raider','transfer','yard'},
   {350,'earth','raider','transfer','vault'},
   {390,'earth','raider','transfer','outpost'},
   {420,'earth','orbiter','orbit_then_dive','yard'},
   {460,'earth','raider','transfer','yard'},
   {480,'earth','raider','transfer','vault'},
  }
 },
 {
  label='orbital denial',
  mods={'driver','jammer'},unlock='sling',
  upgrades={'recycler','point_defense','refinery'},
  waves={
   {50,'earth','raider','transfer','outpost'},
   {80,'earth','raider','transfer','yard'},
   {130,'earth','bus','transfer','vault'},
   {170,'earth','orbiter','orbit_then_dive','vault'},
   {220,'earth','raider','transfer','vault'},
   {250,'earth','raider','transfer','outpost'},
   {270,'earth','screen','transfer','yard'},
   {310,'earth','orbiter','orbit_then_dive','yard'},
   {360,'earth','raider','transfer','outpost'},
   {400,'earth','screen','transfer','outpost'},
   {440,'earth','raider','transfer','outpost'},
   {470,'earth','raider','transfer','yard'},
   {490,'earth','bus','transfer','vault'},
   {520,'earth','raider','transfer','yard'},
   {540,'earth','orbiter','orbit_then_dive','outpost'},
   {560,'earth','raider','transfer','outpost'},
   {580,'earth','raider','transfer','vault'},
   {600,'earth','orbiter','orbit_then_dive','outpost'},
   {640,'earth','raider','transfer','yard'},
  }
 },
 {
  label='general war',
  mods={'driver','jammer'},unlock=nil,
  upgrades={'mass_driver','lunar_shielding','fast_reload'},
  waves={
   {40,'earth','raider','transfer','outpost'},
   {80,'earth','raider','transfer','vault'},
   {130,'earth','bus','transfer','yard'},
   {155,'earth','raider','transfer','outpost'},
   {170,'earth','orbiter','orbit_then_dive','vault'},
   {230,'earth','screen','transfer','outpost'},
   {270,'earth','bus','transfer','outpost'},
   {310,'earth','orbiter','orbit_then_dive','vault'},
   {340,'earth','raider','transfer','outpost'},
   {360,'earth','raider','transfer','vault'},
   {410,'earth','orbiter','orbit_then_dive','yard'},
   {460,'earth','raider','transfer','outpost'},
   {500,'earth','bus','transfer','vault'},
   {530,'earth','orbiter','orbit_then_dive','yard'},
   {560,'earth','raider','transfer','yard'},
   {590,'earth','orbiter','orbit_then_dive','outpost'},
   {620,'earth','raider','transfer','vault'},
   {650,'earth','raider','transfer','yard'},
  }
 },
 {
  label='aegis breach',
  mods={'driver','driver','jammer','aegis'},unlock='moon_chunk',
  upgrades={'pulse_array','mass_driver','reserve_tanks'},
  waves={
   {40,'earth','raider','transfer','outpost'},
   {80,'earth','raider','transfer','vault'},
   {130,'earth','bus','transfer','yard'},
   {200,'earth','raider','transfer','outpost'},
   {240,'earth','orbiter','orbit_then_dive','vault'},
   {275,'earth','raider','transfer','outpost'},
   {300,'earth','raider','transfer','yard'},
   {340,'earth','raider','transfer','yard'},
   {400,'earth','screen','transfer','outpost'},
   {440,'earth','raider','transfer','vault'},
   {460,'earth','bus','transfer','outpost'},
   {500,'earth','raider','transfer','yard'},
   {520,'earth','orbiter','orbit_then_dive','outpost'},
   {580,'earth','orbiter','orbit_then_dive','yard'},
   {640,'earth','raider','transfer','yard'},
   {700,'earth','bus','transfer','vault'},
   {740,'earth','raider','transfer','yard'},
   {780,'earth','raider','transfer','outpost'},
   {820,'earth','raider','transfer','outpost'},
  }
 },
 {
  label='core breach',
  mods={'driver','driver','jammer','jammer','aegis'},unlock=nil,
  upgrades={},core_strike=true,core_hp=8,
  waves={
   {40,'earth','bus','transfer','outpost'},
   {100,'earth','raider','transfer','yard'},
   {140,'earth','orbiter','orbit_then_dive','yard'},
   {220,'earth','raider','transfer','vault'},
   {260,'earth','bus','transfer','vault'},
   {320,'earth','raider','transfer','outpost'},
   {380,'earth','raider','transfer','outpost'},
   {440,'earth','bus','transfer','yard'},
   {500,'earth','orbiter','orbit_then_dive','vault'},
   {560,'earth','raider','transfer','yard'},
   {620,'earth','bus','transfer','yard'},
   {680,'earth','orbiter','orbit_then_dive','outpost'},
   {740,'earth','raider','transfer','outpost'},
   {800,'earth','raider','transfer','vault'},
   {860,'earth','bus','transfer','vault'},
  }
 },
}

mods={}

-- helpers
nxt_id=1
function nid() nxt_id+=1 return nxt_id end
function vsub(a,b) return {x=a.x-b.x,y=a.y-b.y} end
function vmul(a,k) return {x=a.x*k,y=a.y*k} end
function vlen(a) return sqrt(a.x*a.x+a.y*a.y) end
function vnorm(a)
 local l=vlen(a)
 if l<0.001 then return {x=0,y=0} end
 return {x=a.x/l,y=a.y/l}
end
function dist(a,b) return sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
function d2(ax,ay,bx,by) local dx=ax-bx local dy=ay-by return dx*dx+dy*dy end
function lerp(a,b,t) return a+(b-a)*t end
function print_center(s,y,col) print(s,64-#s*2,y,col) end

-- tiny "action denied" cue: flash the weapon label and a moon-center blink
function trigger_denied()
 fire_denied_t=6
 add(fx,{kind='denied_blink',x=moon_x,y=moon_y,t=6,mt=6})
 sfx(11)
end

-- site position from tidal lock (on moon edge)
function site_scr(s)
 local a=(earth_theta+s.ang)%1
 return moon_x+cos(a)*moon_r,moon_y+sin(a)*moon_r
end

function moon_site_pos(id)
 for s in all(sites) do
  if s.id==id then return site_scr(s) end
 end
 return moon_x,moon_y
end

function upd_earth_orbit()
 earth_theta=(earth_theta+earth_omega)%1
 earth_x=moon_x+cos(earth_theta)*earth_orbit_r
 earth_y=moon_y+sin(earth_theta)*earth_orbit_r
 earth_spin=(earth_spin+0.003)%1
end

function mod_pos(m)
 return earth_x+cos(m.theta)*module_ring_r,
        earth_y+sin(m.theta)*module_ring_r
end

function upd_mods()
 for m in all(mods) do
  if m.hp>0 then m.theta=(m.theta+m.omega)%1 end
 end
end

function bez2(a,b,c,t)
 local abx=lerp(a.x,b.x,t) local aby=lerp(a.y,b.y,t)
 local bcx=lerp(b.x,c.x,t) local bcy=lerp(b.y,c.y,t)
 return {x=lerp(abx,bcx,t),y=lerp(aby,bcy,t)}
end

function arc_ctl(a,b,lift)
 local mx=(a.x+b.x)*0.5 local my=(a.y+b.y)*0.5
 local ox=mx-moon_x local oy=my-moon_y
 local ol=sqrt(ox*ox+oy*oy)
 if ol<0.001 then ol=1 end
 ox/=ol oy/=ol
 return {x=mx+ox*lift,y=my+oy*lift}
end

function source_pos(src)
 if src=='earth' then return earth_x,earth_y end
 if sub(src,1,7)=='module:' then
  local kind=sub(src,8)
  for m in all(mods) do
   if m.kind==kind and m.hp>0 then return mod_pos(m) end
  end
 end
 return earth_x,earth_y
end

function spawn_contact(src,kind,plan,target_id)
 local d=cdefs[kind]
 local sx,sy=source_pos(src)
 local tx,ty=moon_site_pos(target_id)
 local start={x=sx,y=sy}
 local pend={x=tx,y=ty}
 local lift=24
 if target_id=='vault' then lift=-18 end
 if plan=='orbit_then_dive' then
  local ang=atan2(sx-moon_x,sy-moon_y)
  local entry_ang=(ang+0.15)%1
  pend={x=moon_x+cos(entry_ang)*lunar_orbit_r,y=moon_y+sin(entry_ang)*lunar_orbit_r}
  lift=28
 end
 local ctl=arc_ctl(start,pend,lift)
 add(contacts,{
  uid=nid(),kind=kind,hp=d.hp,mhp=d.hp,spd=d.spd,
  idmg=d.idmg,salv=d.salv,col=d.col,
  plan=plan,target_id=target_id,state='transfer',u=0,
  start=start,ctl=ctl,pend=pend,
  otheta=0,odir=(nxt_id%2==0) and 1 or -1,otick=0,
  dstart=nil,dctl=nil,dend=nil,
 })
end

function contact_pos(c)
 if c.state=='transfer' then return bez2(c.start,c.ctl,c.pend,min(1,c.u))
 elseif c.state=='orbit' then
  return {x=moon_x+cos(c.otheta)*lunar_orbit_r,y=moon_y+sin(c.otheta)*lunar_orbit_r}
 elseif c.state=='dive' then return bez2(c.dstart,c.dctl,c.dend,min(1,c.u))
 end
 return {x=c.pend.x,y=c.pend.y}
end

function step_contact(c,predict)
 if c.hp<=0 then return end
 if c.state=='transfer' then
  -- wreckers start slow and accelerate over time. kill them early or
  -- they become hard to hit as they pick up speed.
  if c.kind=='bus' then
   c.accel_mul=min(1.8,(c.accel_mul or 0.6)+0.0065)
   c.u+=c.spd*c.accel_mul
  else
   c.u+=c.spd
  end
  -- early impact if bezier path clips the moon body (non-orbit plans only)
  if c.plan~='orbit_then_dive' and not cdefs[c.kind].orbit then
   local tp=contact_pos(c)
   local tmx=tp.x-moon_x local tmy=tp.y-moon_y
   if tmx*tmx+tmy*tmy<=(moon_r+1)*(moon_r+1) then
    if not predict then impact_contact(c) end
    return
   end
  end
  if c.u>=1 then
   if c.plan=='orbit_then_dive' or cdefs[c.kind].orbit then
    -- compute incoming tangent to preserve direction and speed
    local t_near=max(0,c.u-c.spd)
    local p_near=bez2(c.start,c.ctl,c.pend,t_near)
    local vx=c.pend.x-p_near.x
    local vy=c.pend.y-p_near.y
    local vmag=sqrt(vx*vx+vy*vy)
    c.state='orbit' c.otick=280 c.pulse_t=45 c.bombs_left=5
    c.otheta=atan2(c.pend.x-moon_x,c.pend.y-moon_y)
    -- match angular velocity to incoming linear speed (2x for snappy feel)
    c.orbit_omega=max(0.003,vmag/(6.28*lunar_orbit_r))
    -- match rotation direction via 2d cross product
    local dx=c.pend.x-moon_x
    local dy=c.pend.y-moon_y
    local cross=dx*vy-dy*vx
    c.odir=cross<0 and 1 or -1
   else
    if not predict then impact_contact(c) end
   end
  end
 elseif c.state=='orbit' then
  c.otheta=(c.otheta+(c.orbit_omega or 0.002)*c.odir)%1
  c.otick-=1
  if not predict and c.pulse_t and (c.bombs_left or 0)>0 then
   c.pulse_t-=1
   if c.pulse_t<=0 then
    c.pulse_t=45
    local p=contact_pos(c)
    spawn_bomb(p.x,p.y)
    c.bombs_left-=1
   end
  end
  -- once bombs are spent or the orbit timer expires, commit to the dive
  if c.otick<=0 or (c.bombs_left and c.bombs_left<=0 and c.pulse_t<=8) then
   c.dstart=contact_pos(c)
   c.state='dive' c.u=0
   local tx,ty=moon_site_pos(c.target_id)
   c.dend={x=tx,y=ty}
   c.dctl=arc_ctl(c.dstart,c.dend,6)
  end
 elseif c.state=='dive' then
  c.u+=c.spd*1.25
  local dp=contact_pos(c)
  local dmx=dp.x-moon_x local dmy=dp.y-moon_y
  if dmx*dmx+dmy*dmy<=(moon_r+1)*(moon_r+1) or c.u>=1 then
   if not predict then impact_contact(c) end
  end
 end
end

function impact_contact(c)
 c.hp=0
 moon_int=max(0,moon_int-c.idmg)
 local p=contact_pos(c)
 local dmx=p.x-moon_x local dmy=p.y-moon_y
 local dl=sqrt(dmx*dmx+dmy*dmy)
 local ix,iy
 if dl>0.01 then
  ix=moon_x+dmx/dl*moon_r iy=moon_y+dmy/dl*moon_r
 else
  ix=moon_x iy=moon_y
 end
 if c.idmg>0 then
  add(fx,{kind='impact',x=ix,y=iy,t=12,mt=12})
  -- wrecker = medium bang (SFX 6); sapper = medium bang; raider = thud (SFX 2)
  if c.kind=='bus' or c.kind=='orbiter' then sfx(6) else sfx(2) end
  -- sapper: secondary explosion + sparks
  if c.kind=='orbiter' then
   add(fx,{kind='explosion',x=ix,y=iy,t=20,mt=20})
   for i=0,4 do
    local sa=i/5+rnd(0.08)
    local sr=moon_r+1+flr(rnd(3))
    add(fx,{kind='fizz',x=moon_x+cos(sa)*sr,y=moon_y+sin(sa)*sr,t=12+flr(rnd(6)),mt=18})
   end
  end
  -- wrecker: massive multi-explosion impact + shockwave debris
  if c.kind=='bus' then
   add(fx,{kind='explosion',x=ix,y=iy,t=28,mt=28})
   add(fx,{kind='impact',x=ix,y=iy,t=22,mt=22})
   -- radiating sparks around the impact point
   for i=0,7 do
    local sa=i/8+rnd(0.05)
    local sr=moon_r+2+flr(rnd(4))
    add(fx,{kind='fizz',x=moon_x+cos(sa)*sr,y=moon_y+sin(sa)*sr,t=16+flr(rnd(6)),mt=22})
   end
   -- extra craters on the surface around the impact
   for i=1,3 do
    local oa=rnd(0.2)-0.1
    local or_=rnd(2)
    add_moon_crater(ix+cos(oa)*or_,iy+sin(oa)*or_,2)
   end
  end
  add_moon_crater(ix,iy,c.idmg)
  check_moon_bites()
 else
  -- harmless clutter: tiny fizz, no damage visuals
  add(fx,{kind='fizz',x=ix,y=iy,t=8,mt=8})
 end
end

function predict_contact(c,frames)
 local p={
  kind=c.kind,hp=c.hp,spd=c.spd,idmg=c.idmg,salv=c.salv,col=c.col,
  plan=c.plan,target_id=c.target_id,state=c.state,u=c.u,
  start={x=c.start.x,y=c.start.y},ctl={x=c.ctl.x,y=c.ctl.y},
  pend={x=c.pend.x,y=c.pend.y},
  otheta=c.otheta,odir=c.odir,otick=c.otick,orbit_omega=c.orbit_omega,
  dstart=c.dstart and {x=c.dstart.x,y=c.dstart.y} or nil,
  dctl=c.dctl and {x=c.dctl.x,y=c.dctl.y} or nil,
  dend=c.dend and {x=c.dend.x,y=c.dend.y} or nil
 }
 for i=1,frames do step_contact(p,true) end
 return contact_pos(p)
end

function destroy_contact(c)
 local p=contact_pos(c) c.hp=0 score+=10
 audio_on_contact_kill(c.kind)
 if dist(p,{x=moon_x,y=moon_y})<34 and c.salv>0 then
  local ang=atan2(p.x-moon_x,p.y-moon_y)
  add(debris,{uid=nid(),theta=ang,omega=((nxt_id%2==0) and 0.004 or -0.004),
   ttl=220,hot=24,mass=c.salv,claimed=false})
 end
end

function upd_contacts()
 for c in all(contacts) do step_contact(c,false) end
 for c in all(contacts) do if c.hp<=0 then del(contacts,c) end end
end

function launch_auto_lock(uid)
 if charge<1 then
  trigger_denied() return
 end
 -- interceptor_cd is a tiny visual-spacing floor (≤1 frame), not a gate.
 -- charge is the real pacing constraint; spam at will when you have it.
 if interceptor_cd>0 then return end
 local target=nil
 for c in all(contacts) do if c.uid==uid and c.hp>0 then target=c end end
 if not target then return end
 charge-=1
 local turn=0.25
 add(interceptors,{uid=nid(),x=moon_x,y=moon_y,vx=0,vy=0,
  cur_speed=0,max_speed=1.35,accel=0.05,
  turn=turn,ttl=300,target_uid=uid})
 interceptor_cd=2
 add(fx,{kind='launch',x=moon_x,y=moon_y,t=8,mt=8})
 sfx(0)
 audio_on_player_launch('counter',false)
end

function upd_interceptors()
 for it in all(interceptors) do
  it.ttl-=1
  -- orphaned: target died. coast briefly and fizz out gracefully.
  if it.orphan_t then
   it.orphan_t-=1
   it.x+=it.vx it.y+=it.vy
   -- slow decay
   it.vx*=0.94 it.vy*=0.94
   if it.orphan_t<=0 then
    add(fx,{kind='fizz',x=it.x,y=it.y,t=10,mt=10})
    del(interceptors,it)
   end
  else
   local target=nil
   for c in all(contacts) do if c.uid==it.target_uid and c.hp>0 then target=c end end
   if not target then
    -- target just died — start the graceful orphan coast
    it.orphan_t=14
    add(fx,{kind='fizz',x=it.x,y=it.y,t=8,mt=8})
   else
    it.cur_speed=min(it.cur_speed+it.accel,it.max_speed)
    local tp=contact_pos(target)
    -- homing aim: use prediction when far, current position when close.
    -- this prevents "leading" overshoot on close-range dives.
    local d_cur=dist({x=it.x,y=it.y},tp)
    local ap
    if d_cur<14 then
     ap=tp
    else
     local pf=10
     ap=predict_contact(target,pf)
    end
    local des=vnorm(vsub(ap,{x=it.x,y=it.y}))
    -- slow down when close so we don't overshoot in one frame
    local spd=it.cur_speed
    if d_cur<10 then spd=spd*max(0.5,d_cur/10) end
    des=vmul(des,spd)
    it.vx=lerp(it.vx,des.x,it.turn) it.vy=lerp(it.vy,des.y,it.turn)
    it.x+=it.vx it.y+=it.vy
    -- hit check: radius + swept-line for fast passes
    local hit=false
    if dist({x=it.x,y=it.y},tp)<5 then
     hit=true
    else
     local pvx=it.x-it.vx local pvy=it.y-it.vy
     local sx=it.x-pvx    local sy=it.y-pvy
     local sl=sx*sx+sy*sy
     if sl>0.01 then
      local t=((tp.x-pvx)*sx+(tp.y-pvy)*sy)/sl
      t=mid(0,t,1)
      local cx=pvx+sx*t local cy=pvy+sy*t
      if (tp.x-cx)^2+(tp.y-cy)^2<25 then hit=true end
     end
    end
    if hit then
     target.hp-=1
     if target.hp<=0 then destroy_contact(target) end
     add(fx,{kind='explosion',x=it.x,y=it.y,t=14,mt=14})
     sfx(1)
     del(interceptors,it)
    elseif it.ttl<=0 then
     add(fx,{kind='miss',x=it.x,y=it.y,t=8,mt=8})
     del(interceptors,it)
    end
   end
  end
 end
end

function unlocked_list()
 local list={}
 for sid in all(special_order) do
  if unlocked_specials[sid] then add(list,sid) end
 end
 return list
end

function current_special()
 local list=unlocked_list()
 if #list==0 then return nil end
 if spec_i<1 then spec_i=#list end
 if spec_i>#list then spec_i=1 end
 return sdefs[list[spec_i]]
end

function set_special(id)
 local list=unlocked_list()
 for i=1,#list do
  if list[i]==id then spec_i=i return end
 end
 spec_i=1
end

function can_pay_special(sp)
 if not sp then return false end
 if charge<sp.cost then return false end
 if moon_int<=sp.cint then return false end
 if sp.scost>0 and salvage<sp.scost then return false end
 return true
end

-- aim mode: L/R/U/D adjust a hidden direction point near the moon.
-- the angle is recomputed each input, so small step = small rotation.
function enter_aim(target)
 local sp=current_special()
 if not sp then return end
 if war_started and not can_pay_special(sp) then trigger_denied() return end
 local tx,ty=earth_x,earth_y
 if target.type=='module' and target.ref then
  tx,ty=mod_pos(target.ref)
 elseif target.type=='boss' and target.ref then
  tx,ty=target.ref.x,target.ref.y
 end
 local dx=tx-moon_x local dy=ty-moon_y
 local dl=sqrt(dx*dx+dy*dy)
 if dl<0.1 then dl=1 end
 -- place the direction point 25px from moon toward target
 local cx=moon_x+dx/dl*25
 local cy=moon_y+dy/dl*25
 local ang=atan2(cx-moon_x,cy-moon_y)
 aim={ang=ang,sp=sp,target=target,cx=cx,cy=cy}
end

function fire_aimed()
 if not aim then return end
 local sp=aim.sp
 local opener=not war_started
 if not opener then
  if not can_pay_special(sp) then trigger_denied() return end
  charge-=sp.cost moon_int-=sp.cint
  if sp.scost>0 then salvage-=sp.scost end
 end
 sfx(4)
 audio_on_player_launch(sp.id,opener)
 if sp.id=='moon_chunk' then
  -- launching a chunk also permanently reduces the moon's max integrity
  if not opener then
   moon_max=max(8,moon_max-3)
   if moon_int>moon_max then moon_int=moon_max end
  end
  -- bite a chunk out of the moon at launch direction
  add(moon_bites,{a=(aim.ang-earth_theta)%1,sz=2})
  check_moon_bites()
  add(fx,{kind='chunk_tear',x=moon_x,y=moon_y,t=10,mt=10})
 elseif sp.cint>0 then
  check_moon_bites()
 end
 local spd=sp.lspd or launch_spd
 local sz=1
 if sp.id=='moon_chunk' then sz=3 end
 -- opening salvo: slow start, gravity does the work
 if opener then spd=0.22 sz=3 end
 -- launch from outside moon surface in aim direction
 local lx=moon_x+cos(aim.ang)*(moon_r+3)
 local ly=moon_y+sin(aim.ang)*(moon_r+3)
 local motor_t=0
 if sp.id=='moon_chunk' and not opener then motor_t=26 end
 -- boss phase: shots fly in a straight line with no gravity
 local straight=(state=='boss_play')
 if straight then
  -- slow, readable speed so the boss has time to react
  spd=(sp.id=='moon_chunk') and 0.55 or 0.9
 end
 add(heavies,{
  uid=nid(),kind=sp.id,
  x=lx,y=ly,
  vx=cos(aim.ang)*spd,vy=sin(aim.ang)*spd,
  dmg=sp.dmg,col=sp.col,size=sz,
  tkind=aim.target.type,tid=aim.target.id,
  age=0,max_age=straight and 240 or 480,trail={},opener=opener,
  motor_t=motor_t,
  straight=straight
 })
 if opener then opening_shot_fired=true end
 add(fx,{kind='launch_heavy',x=lx,y=ly,t=10,mt=10})
 aim=nil
end

function sim_gravity(px,py,pvx,pvy)
 local dx=earth_x-px local dy=earth_y-py
 local d=sqrt(dx*dx+dy*dy)
 if d<1 then d=1 end
 local g=min(grav_k/(d*d),0.15)
 pvx+=dx/d*g pvy+=dy/d*g
 return px+pvx,py+pvy,pvx,pvy
end

function is_land(lon,lat)
 for i=1,#c_lon do
  local clon=c_lon[i]/100
  local clat=c_lat[i]/100
  local dlon=clon-lon
  if dlon>0.5 then dlon-=1 end
  if dlon<-0.5 then dlon+=1 end
  if abs(dlon)<0.035 and abs(clat-lat)<0.06 then return true end
 end
 return false
end

function get_earth_colors()
 -- ocean, land dark, land highlight
 -- global atmosphere changes very slowly; individual chunk hits leave large
 -- regional dead patches (chunk_marks) that tell the main damage story.
 local d=earth_damage_level
 if d<20 then return 12,3,11 end
 if d<45 then return 12,4,3 end
 if d<70 then return 1,4,3 end
 if d<95 then return 5,4,4 end   -- pre-death: brownish-gray, visibly dying
 return 5,2,4                    -- dead: gray + dark purple veins + brown
end

function gen_moon_craters()
 moon_craters={}
 moon_bites={}
 for i=1,3 do
  add(moon_craters,{a=rnd(1),r=rnd(moon_r-3)+2,sz=1})
 end
end

function check_moon_bites()
 -- percent-based so progression scales with lunar_shielding
 local dmg=moon_max-moon_int
 local target=flr(dmg*6/max(1,moon_max))
 while #moon_bites<target do
  add(moon_bites,{a=rnd(1),sz=1+flr(rnd(2))})
 end
end

function add_moon_crater(hx,hy,sz)
 local dx=hx-moon_x local dy=hy-moon_y
 local dr=sqrt(dx*dx+dy*dy)
 if dr>=moon_r then dr=moon_r-1 end
 local ca=atan2(dx,dy)
 add(moon_craters,{a=(ca-earth_theta)%1,r=dr,sz=sz or 1})
 if #moon_craters>30 then del(moon_craters,moon_craters[1]) end
end

function add_earth_damage(hx,hy,weight,no_smoke)
 local dx=hx-earth_x local dy=hy-earth_y
 -- project external impact points back onto earth surface
 local d=sqrt(dx*dx+dy*dy)
 if d>earth_r then
  dx=dx/d*earth_r dy=dy/d*earth_r
 end
 local lat=dy/(earth_r*2.5)
 local rel_approx=(dx/earth_r)*0.25
 local lon=(earth_spin+rel_approx)%1
 local land=is_land(lon,lat)
 add(earth_damage,{lon=lon,lat=lat,land=land})
 if #earth_damage>40 then del(earth_damage,earth_damage[1]) end
 earth_damage_level+=weight or 1
 -- impact fx
 if land then
  add(fx,{kind='land_hit',ex=dx,ey=dy,t=14,mt=14})
  if not no_smoke then
   for i=1,3 do
    add(fx,{kind='smoke',ex=dx+rnd(3)-1.5,ey=dy+rnd(2)-1,
     vx=(rnd(1)-0.5)*0.1,vy=-0.06-rnd(0.08),
     t=40+flr(rnd(20)),mt=60,col=5})
   end
  end
 else
  add(fx,{kind='splash',ex=dx,ey=dy,t=20,mt=20})
  if not no_smoke then
   for i=1,2 do
    add(fx,{kind='smoke',ex=dx+rnd(4)-2,ey=dy+rnd(2)-1,
     vx=(rnd(1)-0.5)*0.08,vy=-0.08-rnd(0.06),
     t=30+flr(rnd(15)),mt=45,col=6})
   end
  end
 end
end

function spawn_opener_mark(hx,hy)
 local dx=hx-earth_x local dy=hy-earth_y
 local d=sqrt(dx*dx+dy*dy)
 if d>earth_r then dx=dx/d*earth_r dy=dy/d*earth_r end
 local lat=dy/(earth_r*2.5)
 local rel_approx=(dx/earth_r)*0.25
 local lon=(earth_spin+rel_approx)%1
 add(opener_marks,{lon=lon,lat=lat,age=0,max_age=1500})
end

function upd_opener_marks()
 for m in all(opener_marks) do
  m.age+=1
  if m.age>=m.max_age then del(opener_marks,m) end
 end
end

function spawn_chunk_mark(hx,hy)
 local dx=hx-earth_x local dy=hy-earth_y
 local d=sqrt(dx*dx+dy*dy)
 if d>earth_r then dx=dx/d*earth_r dy=dy/d*earth_r end
 local lat=dy/(earth_r*2.5)
 local rel_approx=(dx/earth_r)*0.25
 local lon=(earth_spin+rel_approx)%1
 add(chunk_marks,{lon=lon,lat=lat})
 if #chunk_marks>30 then del(chunk_marks,chunk_marks[1]) end
end

function spawn_bomb(x,y)
 local dx=moon_x-x local dy=moon_y-y
 local d=sqrt(dx*dx+dy*dy)
 if d<0.1 then d=1 end
 add(bombs,{x=x,y=y,vx=dx/d*0.35,vy=dy/d*0.35,age=0})
end

function upd_bombs()
 for b in all(bombs) do
  b.x+=b.vx b.y+=b.vy
  b.age+=1
  local mx=b.x-moon_x local my=b.y-moon_y
  if mx*mx+my*my<=(moon_r+1)*(moon_r+1) then
   -- real integrity damage plus salvage drain
   moon_int=max(0,moon_int-3)
   if salvage>0 then salvage-=1
   else charge_regen_t=max(0,charge_regen_t-30) end
   local ml=sqrt(mx*mx+my*my)
   local ix,iy
   if ml>0.01 then ix=moon_x+mx/ml*moon_r iy=moon_y+my/ml*moon_r
   else ix=moon_x iy=moon_y end
   add(fx,{kind='impact',x=ix,y=iy,t=14,mt=14})
   add(fx,{kind='sabot',x=ix,y=iy,t=16,mt=16})
   add_moon_crater(ix,iy,2)
   sfx(6)
   del(bombs,b)
  elseif b.age>260 then del(bombs,b) end
 end
end

function draw_bombs()
 for b in all(bombs) do
  pset(b.x,b.y,13)
  pset(b.x-1,b.y,1) pset(b.x+1,b.y,1)
  pset(b.x,b.y-1,6) pset(b.x,b.y+1,1)
 end
end

function on_module_killed(m,mx,my)
 -- module death: loud orbital detonation + visible harm to earth
 score+=50
 add(fx,{kind='explosion',x=mx,y=my,t=20,mt=20})
 -- debris burst radiating outward
 for i=1,8 do
  local a=i/8
  add(fx,{kind='smoke',ex=(mx-earth_x)+cos(a)*3,ey=(my-earth_y)+sin(a)*3,
   vx=cos(a)*0.3,vy=sin(a)*0.3,t=30+flr(rnd(15)),mt=45,col=m.col or 5})
 end
 -- earth gets scarred where the module fell (project toward earth center)
 local dx=mx-earth_x local dy=my-earth_y
 local dl=sqrt(dx*dx+dy*dy)
 if dl<0.1 then dl=1 end
 local hx=earth_x+dx/dl*(earth_r-1)
 local hy=earth_y+dy/dl*(earth_r-1)
 add_earth_damage(hx,hy,2)
 add(fx,{kind='earth_flash',ex=hx-earth_x,ey=hy-earth_y,t=16,mt=16})
end

function upd_heavies()
 for h in all(heavies) do
  h.age+=1
  -- chunk rocket motor: brief thrust along current velocity direction
  if h.motor_t and h.motor_t>0 and not h.straight then
   local vl=sqrt(h.vx*h.vx+h.vy*h.vy)
   if vl>0.01 then
    h.vx+=h.vx/vl*0.011
    h.vy+=h.vy/vl*0.011
   end
   h.motor_t-=1
  end
  local dx,dy,d
  if h.straight then
   -- straight-line flight: no gravity, no velocity cap
   dx=earth_x-h.x dy=earth_y-h.y
   d=sqrt(dx*dx+dy*dy)
   if d<1 then d=1 end
  else
   -- gravity step (sling has reduced pull for aimability)
   dx=earth_x-h.x dy=earth_y-h.y
   d=sqrt(dx*dx+dy*dy)
   if d<1 then d=1 end
   local g=min(grav_k/(d*d),0.15)
   if h.kind=='sling' then g*=0.4 end
   h.vx+=dx/d*g h.vy+=dy/d*g
   -- velocity caps
   if h.kind=='sling' then
    local sp=sqrt(h.vx*h.vx+h.vy*h.vy)
    if sp>1.1 then h.vx=h.vx/sp*1.1 h.vy=h.vy/sp*1.1 end
   elseif h.kind=='moon_chunk' and not h.opener then
    local sp=sqrt(h.vx*h.vx+h.vy*h.vy)
    if sp>0.78 then h.vx=h.vx/sp*0.78 h.vy=h.vy/sp*0.78 end
   end
  end
  -- trail (longer for chunks so the shot reads heavier)
  add(h.trail,{x=h.x,y=h.y})
  local tlim=(h.kind=='moon_chunk' and not h.opener) and 14 or 8
  if #h.trail>tlim then del(h.trail,h.trail[1]) end
  h.x+=h.vx h.y+=h.vy
  -- pass-through: sling and chunk shred any contacts on their flight path
  if not h.opener and (h.kind=='sling' or h.kind=='moon_chunk') then
   for c in all(contacts) do
    if c.hp>0 then
     local cp=contact_pos(c)
     if (h.x-cp.x)^2+(h.y-cp.y)^2<25 then
      destroy_contact(c)
      add(fx,{kind='explosion',x=cp.x,y=cp.y,t=12,mt=12})
      sfx(1)
     end
    end
   end
  end
  -- boss phase: heavy hit on the capital ship takes priority
  local handled=false
  if state=='boss_play' and boss and not h.opener and not boss.dying then
   -- rotated hit box: use stable orbit-tangent forward vector
   local fwx=boss.fwx or 1
   local fwy=boss.fwy or 0
   local pxd=-fwy local pyd=fwx
   local rx=h.x-boss.x local ry=h.y-boss.y
   local lu=rx*fwx+ry*fwy  -- along motion axis
   local lv=rx*pxd+ry*pyd  -- perpendicular
   if abs(lu)<=9 and abs(lv)<=4 then
    boss_take_hit(h.dmg,h.kind)
    add(fx,{kind='explosion',x=h.x,y=h.y,t=14,mt=14})
    del(heavies,h)
    handled=true
   elseif d<earth_r+3 then
    -- earth is gone: a shot that would have hit earth is just a clean miss
    add(fx,{kind='miss',x=h.x,y=h.y,t=8,mt=8})
    del(heavies,h)
    handled=true
   end
  end
  if not handled then
   -- aegis arc block (between earth surface and module ring) — but close-range hits bypass
   local blocked=false
   if not h.opener then
    local ned=sqrt((h.x-earth_x)^2+(h.y-earth_y)^2)
    if ned>earth_r+3 and ned<earth_r+module_ring_r+2 then
     for m in all(mods) do
      if m.kind=='aegis' and m.hp>0 then
       local amx,amy=mod_pos(m)
       local mod_d=sqrt((h.x-amx)^2+(h.y-amy)^2)
       -- skip the arc block if we're close enough to hit the module directly
       if mod_d>=8 then
        local hang=atan2(h.x-earth_x,h.y-earth_y)
        local diff=(hang-m.theta+0.5)%1-0.5
        if abs(diff)<(m.barc or 0.07) then
         blocked=true
         add(fx,{kind='block',x=h.x,y=h.y,t=14,mt=14})
         sfx(5)
        end
       end
       break
      end
     end
    end
   end
   if blocked then
    del(heavies,h)
   -- check earth impact
   elseif d<earth_r+3 then
    if h.opener then
     -- opening salvo: isolated localized scar + big flash, no global damage
     spawn_opener_mark(h.x,h.y)
     add(fx,{kind='earth_flash',ex=h.x-earth_x,ey=h.y-earth_y,t=30,mt=30})
     -- smoke plume at impact — gray haze around hit zone
     local rex,rey=h.x-earth_x,h.y-earth_y
     for si=1,14 do
      local sc=(si<=7) and 6 or 13
      add(fx,{kind='smoke',ex=rex+(rnd(8)-4),ey=rey+(rnd(8)-4),
       vx=(rnd(0.5)-0.25),vy=-(rnd(0.25)+0.05),
       t=40+flr(rnd(30)),mt=70,col=sc})
     end
     sfx(57)
     if not war_started then
      war_started=true packet_tick=0
     end
    else
     local w=1
     if h.kind=='sling' then w=0
     elseif h.kind=='moon_chunk' then w=4 end
     add_earth_damage(h.x,h.y,w)
     if h.kind=='moon_chunk' then
      spawn_chunk_mark(h.x,h.y)
      add(fx,{kind='chunk_impact',ex=h.x-earth_x,ey=h.y-earth_y,t=22,mt=22})
      sfx(7)  -- big boom: chunk hits earth
      audio_big_boom('hero')
     else
      sfx(6)  -- medium bang: sling hits earth surface
     end
     resolve_heavy_hit(h)
    end
    del(heavies,h)
   -- check module impact
   else
    local hit_mod=false
    for m in all(mods) do
     if m.hp>0 then
      local mx,my=mod_pos(m)
      if dist({x=h.x,y=h.y},{x=mx,y=my})<5 then
       local pre=m.hp
       m.hp=max(0,m.hp-h.dmg) score+=30
       add(fx,{kind='impact',x=mx,y=my,t=14,mt=14})
       -- medium bang on contact; big boom if the module is killed
       if pre>0 and m.hp<=0 then on_module_killed(m,mx,my) sfx(7) audio_big_boom('hero')
       else sfx(6) end
       del(heavies,h) hit_mod=true break
      end
     end
    end
    if not hit_mod then
     -- boomerang: hit moon (with grace period for escape)
     if dist({x=h.x,y=h.y},{x=moon_x,y=moon_y})<moon_r+2 and h.age>15 then
      -- opener self-hit = instant loss (moon splits)
      if h.opener then
       moon_int=0
      else
       moon_int=max(0,moon_int-1)
      end
      add(fx,{kind='impact',x=h.x,y=h.y,t=12,mt=12})
      add_moon_crater(h.x,h.y,h.size or 2)
      check_moon_bites()
      -- self-hit sting: medium bang so the player feels the mistake
      sfx(6)
      del(heavies,h)
     -- TTL only (no screen edge kill — gravity can bring it back)
     elseif h.age>h.max_age then
      del(heavies,h)
     end
    end
   end
  end
 end
end

function resolve_heavy_hit(h)
 if h.opener then return end
 if earth_core_exposed and h.kind=='moon_chunk' then
  earth_core_hp=max(0,earth_core_hp-h.dmg)
  -- core hits ramp earth's atmosphere toward pre-death colors so the planet
  -- visibly decays over the 3-4 hit kill sequence
  earth_damage_level=min(99,earth_damage_level+22)
  add(fx,{kind='earth_flash',ex=h.x-earth_x,ey=h.y-earth_y,t=10,mt=10})
  if earth_core_hp<=0 then
   -- transition to earth death sequence
   earth_fall_t=0
   earth_halves={}
   state='earth_fall'
  end
 end
 if h.kind=='sling' then score+=15
 elseif h.kind=='moon_chunk' then score+=25 end
end

function upd_debris()
 for d in all(debris) do
  d.theta=(d.theta+d.omega)%1
  if d.hot>0 then d.hot-=1 end
 end
end

function best_debris()
 -- prefer hot (recent) debris first so tug chases urgent scrap, then higher
 -- mass, then lower uid for a deterministic tie-break. no debris expiry.
 local best=nil
 for d in all(debris) do
  if not d.claimed then
   if not best then best=d
   else
    local dh=(d.hot>0) and 1 or 0
    local bh=(best.hot>0) and 1 or 0
    if dh>bh or (dh==bh and d.mass>best.mass) or
       (dh==bh and d.mass==best.mass and d.uid<best.uid) then
     best=d
    end
   end
  end
 end
 return best
end

function auto_tug()
 if tug then return end
 local d=best_debris()
 if not d then return end
 d.claimed=true
 -- recycler gives the tug a meaningful approach speed boost
 local tt=upgrades.recycler and 14 or 22
 tug={tid=d.uid,st='out',t=tt,mt=tt,carry=0,lx=0,ly=0}
end

function deliver_salv(mass)
 -- refinery upgrade doubles the mass extracted from each debris load
 if upgrades.refinery then mass*=2 end
 salvage+=mass
 prop+=mass
 local thresh=upgrades.recycler and 1 or 2
 local pre_charge=charge
 while prop>=thresh and charge<max_charge do
  prop-=thresh
  charge+=1
 end
 if charge>pre_charge then sfx(10) audio_on_charge_gain() end
 -- cap prop so it doesn't balloon when charge is full
 if prop>thresh*2 then prop=thresh*2 end
 -- scrap delivery slowly repairs the moon. patch_crews makes it more efficient.
 moon_heal_p=(moon_heal_p or 0)+mass
 local heal_thresh=upgrades.patch_crews and 3 or 5
 local healed=false
 while moon_heal_p>=heal_thresh and moon_int<moon_max do
  moon_heal_p-=heal_thresh
  moon_int+=1
  healed=true
 end
 if moon_heal_p>heal_thresh*2 then moon_heal_p=heal_thresh*2 end
 -- tiny delivery cue: metallic ping + sparkle at yard anchor on moon edge
 local yx,yy=moon_site_pos('yard')
 add(fx,{kind='deliver_ping',x=yx,y=yy,t=10,mt=10})
 sfx(3)
 if healed then
  local ra=rnd(1)
  add(fx,{kind='repair_spark',x=moon_x+cos(ra)*moon_r,y=moon_y+sin(ra)*moon_r,t=14,mt=14})
 end
end

function upd_tug()
 if not tug then return end
 tug.t-=1
 local target=nil
 for d in all(debris) do if d.uid==tug.tid then target=d end end
 if tug.st=='out' and tug.t<=0 then
  local gt=upgrades.recycler and 12 or 20
  tug.st='grab' tug.t=gt tug.mt=gt
  add(fx,{kind='tug_grab',x=tug.lx,y=tug.ly,t=6,mt=6})
 elseif tug.st=='grab' and tug.t<=0 then
  -- save departure point before debris is removed
  tug.back_x=tug.lx tug.back_y=tug.ly
  if target then tug.carry=target.mass del(debris,target) end
  local bt=upgrades.recycler and 10 or 16
  tug.st='back' tug.t=bt tug.mt=bt
  add(fx,{kind='tug_grab',x=tug.lx,y=tug.ly,t=8,mt=8})
 elseif tug.st=='back' and tug.t<=0 then
  deliver_salv(tug.carry or 0) tug=nil
 end
end

function build_targets()
 if not war_started then
  if opening_shot_fired then return {} end
  return {{type='earth_surface',id='earth_surface',ref={label='earth'},label='earth'}}
 end
 local list={}
 local sp=current_special()
 local wid=sp and sp.id or 'counter'
 if wid=='counter' then
  -- collect contacts tagged with their moon distance so cycling order is
  -- deterministic by proximity rather than spawn/insertion order. decoys stay.
  local raw={}
  for c in all(contacts) do
   local p=contact_pos(c)
   local dm=d2(p.x,p.y,moon_x,moon_y)
   add(raw,{c=c,d=dm})
  end
  -- insertion sort: nearest first, tie-break by uid ascending
  for i=2,#raw do
   local j=i
   while j>1 do
    local a=raw[j-1] local b=raw[j]
    if b.d<a.d or (b.d==a.d and b.c.uid<a.c.uid) then
     raw[j-1]=b raw[j]=a
     j-=1
    else break end
   end
  end
  for r in all(raw) do
   local c=r.c
   add(list,{type='contact',id=c.uid,ref=c,label=clabels[c.kind] or c.kind})
  end
 elseif wid=='sling' then
  for m in all(mods) do
   if m.hp>0 then add(list,{type='module',id=m.uid,ref=m,label=m.label}) end
  end
  add(list,{type='earth_surface',id='earth_surface',ref={label='earth'},label='earth'})
 elseif wid=='moon_chunk' then
  if earth_core_exposed then
   add(list,{type='earth',id='earth_core',ref={label='core'},label='core'})
  else
   add(list,{type='earth_surface',id='earth_surface',ref={label='earth'},label='earth'})
  end
 end
 return list
end

function sel_target()
 local list=build_targets()
 if #list==0 then sel_id=nil return nil end
 -- find the previously selected target by identity
 if sel_id then
  for it in all(list) do
   if it.id==sel_id then return it end
  end
 end
 -- selection missing (dead or weapon changed): default to first
 sel_id=list[1].id
 return list[1]
end

function cycle_target(dir)
 local list=build_targets()
 if #list==0 then sel_id=nil return end
 -- locate current selection in the list
 local cur=1
 if sel_id then
  for i=1,#list do
   if list[i].id==sel_id then cur=i break end
  end
 end
 local new_i=(cur-1+dir+#list)%#list+1
 sel_id=list[new_i].id
end

function cycle_special(dir)
 local list=unlocked_list()
 if #list==0 then return end
 spec_i=(spec_i-1+dir+#list)%#list+1
 sel_id=nil  -- new weapon, new target list: reset selection
end

function upd_module_pressure()
 local sites_by={'outpost','yard','vault'}
 for m in all(mods) do
  if m.hp>0 and m.cool then
   m.cool-=1
   if m.cool<=0 then
    local tgt=sites_by[(flr(gtick/60)%3)+1]
    if m.kind=='driver' then
     spawn_contact('module:driver','raider','transfer',tgt)
     m.cool=m.cool_re
    elseif m.kind=='jammer' then
     spawn_contact('module:jammer','screen','transfer',tgt)
     m.cool=m.cool_re
    else
     m.cool=m.cool_re or 240
    end
   end
  end
 end
end

function upd_charge_regen()
 -- dev mode: unlimited charge for fast testing
 if dev_mode then charge=max_charge charge_regen_t=0 return end
 if charge>=max_charge then charge_regen_t=0 return end
 charge_regen_t+=1
 -- fast_reload now speeds up charge regen (the real pacing gate)
 local thresh=upgrades.fast_reload and 23 or 35
 if charge_regen_t>=thresh then
  charge+=1 charge_regen_t=0
  sfx(10)
  audio_on_charge_gain()
 end
end

function upd_moon_heal()
 -- patch_crews: passive slow repair on top of the scrap-based healing
 if not upgrades.patch_crews then moon_heal_t=0 return end
 if moon_int>=moon_max then moon_heal_t=0 return end
 moon_heal_t+=1
 if moon_heal_t>=800 then
  moon_int+=1 moon_heal_t=0
 end
end

function pd_fire(range,dmg)
 local best=nil local bd=range*range
 for c in all(contacts) do
  -- skip harmless decoys so pd/pulse don't waste shots on drones
  if c.hp>0 and c.kind~='screen' then
   local p=contact_pos(c)
   local dx=p.x-moon_x local dy=p.y-moon_y
   local d2v=dx*dx+dy*dy
   if d2v<=bd then best=c bd=d2v end
  end
 end
 if best then
  best.hp=max(0,best.hp-dmg)
  if best.hp<=0 then destroy_contact(best) end
  local p=contact_pos(best)
  add(fx,{kind='pd_beam',x0=moon_x,y0=moon_y,x=p.x,y=p.y,t=15,mt=15})
  sfx(13)
 end
end

function upd_point_defense()
 -- regular point defense: short range, 2 damage, every 120 frames
 if upgrades.point_defense and gtick%100==0 then
  pd_fire(lunar_orbit_r+4,2)
 end
 -- pulse array: independent system with its own timer. longer range, 1 dmg,
 -- offset by half a period so it doesn't fire the same frame as regular pd
 if upgrades.pulse_array and gtick%100==50 then
  pd_fire(lunar_orbit_r+16,1)
 end
end

-- packet / intermission
function start_packet(idx)
 packet_i=idx packet_tick=0 wave_i=1
 contacts={} interceptors={} heavies={} bombs={} debris={} tug=nil aim=nil mods={}
 local p=packets[packet_i]
 if not p then state='result' return end
 -- duplicates of the same module get offset by half a turn so they sit
 -- on opposite sides of earth instead of stacking
 local kind_count={}
 for kind in all(p.mods) do
  local d=mdefs[kind]
  local n=kind_count[kind] or 0
  local theta_off=n*0.5
  kind_count[kind]=n+1
  add(mods,{uid=nid(),kind=kind,hp=d.hp,mhp=d.hp,
   theta=(d.theta+theta_off)%1,omega=d.omega,col=d.col,label=d.label,barc=d.barc,
   cool=d.cool_init,cool_re=d.cool_re})
 end
 if p.unlock then unlocked_specials[p.unlock]=true end
 earth_core_hp=p.core_hp or 5
 earth_core_exposed=p.core_strike or false
end

function packet_done()
 local p=packets[packet_i]
 if not p then return false end
 -- final packet only ends when the earth core is destroyed
 if p.core_strike and earth_core_hp>0 then return false end
 if wave_i<=#p.waves then return false end
 -- decoys don't count: if only drones are left, the phase completes.
 -- debris and tug also don't block — the packet ends as soon as the
 -- threats are gone.
 local active=0
 for c in all(contacts) do
  if c.hp>0 and c.kind~='screen' then active+=1 end
 end
 return active==0 and #interceptors==0 and #heavies==0
end

function start_intermission()
 -- always offer 3 options: start with the current packet's unowned upgrades,
 -- then fill any empty slots with unowned upgrades from earlier packets.
 local opts={}
 local seen={}
 for u in all(packets[packet_i].upgrades) do
  if not upgrades[u] and not seen[u] then
   add(opts,u) seen[u]=true
  end
 end
 -- fill from earlier packets (most recent first) until we have 3
 for pi=packet_i-1,1,-1 do
  if #opts>=3 then break end
  for u in all(packets[pi].upgrades) do
   if not upgrades[u] and not seen[u] then
    add(opts,u) seen[u]=true
    if #opts>=3 then break end
   end
  end
 end
 inter={opts=opts,oi=1}
 sfx(15)
 state='inter'
end

function apply_upgrade(id)
 if id then upgrades[id]=true end
 if id=='reserve_tanks' then max_charge=5
 elseif id=='lunar_shielding' then moon_max+=2 moon_max_orig+=2 moon_int+=2
 elseif id=='mass_driver' then sdefs.moon_chunk.dmg+=1 end
end

function gen_stars()
 stars={}
 for i=1,35 do
  add(stars,{x=flr(rnd(128)),y=flr(rnd(128)),
   phase=rnd(1),rate=0.008+rnd(0.02),bright=flr(rnd(3))})
 end
end

function reset_run()
 score=0 moon_int=22 moon_max=22 moon_max_orig=22 salvage=0 prop=0 charge=1 max_charge=3
 upgrades={} unlocked_specials={counter=true}
 -- reset mutable sdef numbers that upgrades may have bumped
 sdefs.moon_chunk.dmg=3 sdefs.sling.lspd=0.65
 sdefs.counter.scost=0 sdefs.sling.scost=0 sdefs.moon_chunk.scost=0
 earth_damage={} earth_damage_level=0 opener_marks={} chunk_marks={}
 p4_timer=0 p4_wave_count=0
 gen_moon_craters()
 spec_i=1 sel_id=nil aim=nil
 war_started=false opening_shot_fired=false
 brief_page=1 brief_tick=0 help_page=1
 charge_regen_t=0 moon_heal_t=0 moon_heal_p=0
 interceptor_cd=0
 earth_fall_t=0
 moon_fall_t=0 moon_cracks={} moon_shards={}
 earth_halves={}
 -- boss phase reset
 boss=nil boss_intro_t=0 boss_defeated=false boss_phase_started=false
 result_mode=nil
 boss_shots={}
 boss_pattern_i=1 boss_fire_cd=0 boss_hint_t=0
 shield_a=nil shield_b=nil boss_text=nil
 boss_text_human=nil boss_text_machine=nil
 audio_reset()
 start_packet(1)
end

-- audio conductor
function audio_boot()
 snd={
  gameplay_music_ready=true,
  boss_music_ready=true,
  reactive_sfx_ready=true,

  mus_calm={8,12},
  mus_alert={16,20},
  mus_boss={24,28},

  human_a=48,
  human_b=49,
  machine_a=50,
  machine_b=51,
  bass_stab=52,
  launch_stab=53,
  boom_low=54,
  boom_top=55,
  boom_tail=56,
  opener=57,
  charge=58,
  pd=59,
 }
 audio_reset()
end

function audio_reset()
 audio_prev_state=nil
 audio_bank=nil
 audio_hold_t=0
 audio_react_t=0
 audio_voice_chars=0
 audio_voice_phase=0
end

function audio_state_enter(ns)
 if ns=='title' then
  music(0,500)
  audio_bank=0
 elseif ns=='play' then
  -- start gameplay music immediately
  audio_bank=nil
  audio_hold_t=0
 elseif ns=='brief' or ns=='help' or ns=='inter' then
  music(-1,400)
  audio_bank=nil
 elseif ns=='earth_fall' or ns=='boss_intro' then
  music(-1,120)
  audio_bank=nil
  audio_voice_chars=0
  audio_voice_phase=0
 elseif ns=='boss_play' then
  music(-1,60)
  audio_bank=nil
  audio_hold_t=0
 elseif ns=='result' then
  music(-1,250)
  audio_bank=nil
 end
end

function audio_danger_level()
 local n=#contacts
 n+=#bombs*2
 if packet_i>=3 then n+=1 end
 if packet_i>=4 then n+=2 end
 if earth_core_exposed then n+=2 end
 if moon_int<=moon_max/2 then n+=1 end
 return mid(0,n/8,1)
end

function audio_pick_bank(set)
 if #set<1 then return end
 local pick=set[1+flr(rnd(#set))]
 if #set>1 and pick==audio_bank then
  pick=set[(pick==set[1]) and 2 or 1]
 end
 audio_bank=pick
 music(pick)
 -- hold for ~16 sec (4 patterns × 4 sec each at speed 16)
 audio_hold_t=480
end

function audio_update_music()
 if audio_hold_t>0 then audio_hold_t-=1 end
 if state=='title' then return end
 if state=='play' then
  if not snd.gameplay_music_ready then return end
  if audio_hold_t<=0 then
   if audio_danger_level()>0.55 then audio_pick_bank(snd.mus_alert)
   else audio_pick_bank(snd.mus_calm) end
  end
  return
 end
 if state=='boss_play' then
  if not snd.boss_music_ready then return end
  if audio_hold_t<=0 then
   audio_pick_bank(snd.mus_boss)
  end
 end
end

function audio_try_react(slot)
 if not snd.reactive_sfx_ready then return end
 if audio_react_t>0 then return end
 sfx(slot)
 audio_react_t=4
end

function audio_on_player_launch(kind,opener)
 if kind=='moon_chunk' or opener then
  audio_try_react(snd.launch_stab)
 end
end

function audio_on_contact_kill(kind)
 if state~='play' and state~='boss_play' then return end
 audio_try_react(snd.bass_stab)
end

function audio_on_charge_gain()
 if state~='play' and state~='boss_play' then return end
 audio_try_react(snd.charge)
end

function audio_big_boom(kind)
 if not snd.reactive_sfx_ready then return end
 if kind=='hero' then
  sfx(snd.boom_low)
 elseif kind=='tail' then
  sfx(snd.boom_tail)
 end
end

-- boss comm typewriter system
function boss_comm_info()
 if boss_intro_t<132 then
  return boss_text_human,15,12,1,6
 end
 return boss_text_machine,132,12,2,12
end

function boss_comm_line(txt,rt)
 if boss_intro_t<rt then return '' end
 local n=flr((boss_intro_t-rt)/2)+1
 if n<0 then n=0 end
 if n>#txt then n=#txt end
 return sub(txt,1,n)
end

function boss_comm_visible_chars()
 local lines,start_t,step,phase=boss_comm_info()
 if not lines then return 0,0 end
 local n=0
 for i=1,#lines do
  local txt=lines[i]
  if txt~='' then
   local rt=start_t+(i-1)*step
   if boss_intro_t>=rt then
    local c=flr((boss_intro_t-rt)/2)+1
    if c<0 then c=0 end
    if c>#txt then c=#txt end
    n+=c
   end
  end
 end
 return n,phase
end

function audio_update_comm_voice()
 if not snd.reactive_sfx_ready then return end
 local chars,phase=boss_comm_visible_chars()
 if phase~=audio_voice_phase then
  audio_voice_phase=phase
  audio_voice_chars=0
 end
 if chars>audio_voice_chars then
  for i=audio_voice_chars+1,chars do
   if i%3==0 then
    if phase==1 then
     sfx((i%6==0) and snd.human_b or snd.human_a)
    else
     sfx((i%6==0) and snd.machine_b or snd.machine_a)
    end
   end
  end
  audio_voice_chars=chars
 end
end

function draw_comm_panel()
 local px0=8 local py0=22 local px1=120 local py1=82
 local lines,start_t,step,phase,border_col=boss_comm_info()
 if not lines then return end
 rectfill(px0,py0,px1,py1,0)
 rect(px0,py0,px1,py1,border_col)
 for i=1,#lines do
  local yy=py0+6+i*7
  local rt=start_t+(i-1)*step
  local txt=lines[i]
  if txt~='' then
   local shown=boss_comm_line(txt,rt)
   if phase==1 and i==5 then
    -- "long live earth." — dual color
    local pre="long live "
    local suf="earth."
    local x=64-(#pre+#suf)*2
    local np=min(#shown,#pre)
    if np>0 then print(sub(pre,1,np),x,yy,8) end
    if #shown>#pre then print(sub(suf,1,#shown-#pre),x+#pre*4,yy,11) end
   elseif phase==1 and i==6 then
    -- "long live humanity." — dual color
    local pre="long live "
    local suf="humanity."
    local x=64-(#pre+#suf)*2
    local np=min(#shown,#pre)
    if np>0 then print(sub(pre,1,np),x,yy,8) end
    if #shown>#pre then print(sub(suf,1,#shown-#pre),x+#pre*4,yy,12) end
   else
    local col
    if phase==1 then col=(i<=2) and 7 or 8
    else col=(i==1) and 6 or 12 end
    print_center(shown,yy,col)
   end
  end
 end
end

function audio_update()
 if not snd then return end
 if audio_prev_state~=state then
  audio_state_enter(state)
  audio_prev_state=state
 end
 if audio_react_t>0 then audio_react_t-=1 end
 if state=='boss_intro' then audio_update_comm_voice() end
 audio_update_music()
end

-- update
function update_title()
 upd_earth_orbit() upd_mods()
 if btnp(4) then
  music(-1,400)
  reset_run() state='brief'
 elseif btnp(5) then
  help_page=1 state='help'
 elseif dev_mode and btnp(2) then
  -- dev cheat: skip to the earth split sequence, which hands off to boss
  reset_run()
  war_started=true
  earth_core_hp=0
  earth_fall_t=0
  earth_halves={}
  state='earth_fall'
 end
end

function update_help()
 upd_earth_orbit() upd_mods()
 if btnp(4) then
  music(-1,400)
  reset_run() state='brief'
 elseif btnp(5) then
  help_page+=1
  if help_page>5 then help_page=1 end
 end
end

function update_brief()
 upd_earth_orbit() upd_mods()
 brief_tick+=1
 if btnp(4) or btnp(5) then
  brief_page+=1 brief_tick=0
  if brief_page>2 then
   state='play'
   -- auto-enter aim mode for the opening salvo
   enter_aim({type='earth_surface',id='earth_surface',ref={label='earth'},label='earth'})
  end
 end
end

function update_intermission()
 upd_earth_orbit() upd_mods()
 if btnp(2) then inter.oi=max(1,inter.oi-1) end
 if btnp(3) then inter.oi=min(max(1,#inter.opts),inter.oi+1) end
 if btnp(4) then
  if #inter.opts>0 then apply_upgrade(inter.opts[inter.oi]) end
  inter=nil start_packet(packet_i+1) state='play'
 end
end

-- earth death sequence:
--   phase 1 (0-38): final hammering, wounds pile on, ramping damage
--   phase 2 (t=38): SPLIT — explosion, aegis killed, earth splits in half
--   phase 3 (38+): two halves drift apart, red glow between
function update_earth_fall()
 earth_fall_t+=1
 -- do NOT advance earth orbit (freeze in place for emphasis)
 upd_mods()
 -- phase 1: keep hammering
 if earth_fall_t<38 then
  if earth_damage_level<90 then earth_damage_level+=2 end
  if earth_fall_t%3==0 then
   add(chunk_marks,{lon=rnd(1),lat=(rnd(1)-0.5)*0.8})
  end
  if earth_fall_t%6==0 then
   local a=rnd(1)
   local ex=cos(a)*earth_r*0.8
   local ey=sin(a)*earth_r*0.8
   add(fx,{kind='earth_flash',ex=ex,ey=ey,t=18,mt=18})
  end
  if earth_fall_t%3==0 then
   add(fx,{kind='smoke',ex=rnd(earth_r*1.6)-earth_r*0.8,ey=rnd(earth_r*1.4)-earth_r*0.7,
    vx=(rnd(1)-0.5)*0.1,vy=-0.1-rnd(0.06),
    t=60+flr(rnd(20)),mt=80,col=5})
  end
 end
 -- phase 2 trigger: split the earth, destroy all modules (including aegis)
 if earth_fall_t==38 then
  earth_damage_level=100
  sfx(12)
  sfx(7)
  audio_big_boom('hero')
  -- kill every orbital structure — shield goes down with the planet
  for m in all(mods) do m.hp=0 end
  -- precompute jagged cut edges so they stay stable across frames
  local jl={} local jr={}
  for i=0,earth_r*2 do
   add(jl,flr(rnd(3)))
   add(jr,flr(rnd(3)))
  end
  add(earth_halves,{x=earth_x,y=earth_y,vx=-0.18,vy=-0.04,rot=0,rspd=-0.003,side='l',age=0,jagged=jl})
  add(earth_halves,{x=earth_x,y=earth_y,vx=0.18,vy=0.04,rot=0,rspd=0.003,side='r',age=0,jagged=jr})
  -- big split explosion
  add(fx,{kind='explosion',x=earth_x,y=earth_y,t=30,mt=30})
  -- ring of debris flying outward
  for i=1,14 do
   local a=i/14
   add(fx,{kind='smoke',ex=cos(a)*earth_r,ey=sin(a)*earth_r,
    vx=cos(a)*0.35,vy=sin(a)*0.35,
    t=40+flr(rnd(20)),mt=60,col=(i%2==0 and 9 or 5)})
  end
 end
 -- phase 3: drift halves
 for h in all(earth_halves) do
  h.x+=h.vx
  h.y+=h.vy
  h.vy+=0.0015
  h.rot+=h.rspd
  h.age+=1
 end
 -- tick fx
 for f in all(fx) do
  if f.kind=='smoke' then f.ex+=f.vx or 0 f.ey+=f.vy or 0 end
  f.t-=1
  if f.t<=0 then del(fx,f) end
 end
 -- hand off to the post-earth boss phase instead of going straight to result
 if earth_fall_t>=96 and not boss_phase_started then
  init_boss_phase()
 end
end

-- draw one half of the broken earth with a clean+jagged cut edge
function draw_earth_half(h)
 local oc,lc,lhl=get_earth_colors()
 local x=h.x local y=h.y
 -- base ocean circle
 circfill(x,y,earth_r,oc)
 -- inner darker land blob, offset by rotation for visual variety
 local lox=cos(h.rot)*1
 local loy=sin(h.rot)*1
 circfill(x+lox,y+loy,earth_r-3,lc)
 circfill(x-lox*0.5,y-loy*0.5,earth_r-5,lhl)
 -- cut the other half off with a rectangular mask
 if h.side=='l' then
  rectfill(x+1,y-earth_r-1,x+earth_r+2,y+earth_r+1,0)
 else
  rectfill(x-earth_r-2,y-earth_r-1,x-1,y+earth_r+1,0)
 end
 -- jagged cut edge
 for i=1,#h.jagged do
  local dy=i-earth_r-1
  local bite=h.jagged[i]
  for j=0,bite do
   if h.side=='l' then
    pset(x-j,y+dy,0)
   else
    pset(x+j,y+dy,0)
   end
  end
 end
 -- red lava glow rim along the cut edge (fades as halves drift apart)
 local glow_life=max(0,1-h.age/100)
 if glow_life>0 then
  for i=1,#h.jagged do
   local dy=i-earth_r-1
   local bite=h.jagged[i]
   if i%2==1 then
    local gc=(h.age<20 and 10) or (h.age<50 and 9 or 8)
    if h.side=='l' then
     pset(x-bite-1,y+dy,gc)
    else
     pset(x+bite+1,y+dy,gc)
    end
   end
  end
 end
 -- a few scattered chunk scars that rode with the half
 for si=0,3 do
  local sa=h.rot+si*0.25
  local sx=x+cos(sa)*(earth_r*0.5)
  local sy=y+sin(sa)*(earth_r*0.4)
  local dxr=sx-x local dyr=sy-y
  -- only draw if on this side of the cut
  if (h.side=='l' and dxr<=0) or (h.side=='r' and dxr>=0) then
   if dxr*dxr+dyr*dyr<=(earth_r-2)*(earth_r-2) then
    pset(sx,sy,5)
    pset(sx+1,sy,4)
   end
  end
 end
end

-- moon death sequence: pockmark ramp → cracks → split shards → result
function update_moon_fall()
 moon_fall_t+=1
 upd_earth_orbit() upd_mods()
 -- phase 1 (0-40): quiet pockmark ramp, craters and bites filling in
 if moon_fall_t<=40 and moon_fall_t%2==0 then
  local a=rnd(1)
  local r=rnd(moon_r-1)+1
  add(moon_craters,{a=a,r=r,sz=1+flr(rnd(2))})
  if #moon_craters>60 then del(moon_craters,moon_craters[1]) end
  if moon_fall_t%4==0 then
   add(moon_bites,{a=rnd(1),sz=1+flr(rnd(2))})
  end
 end
 -- phase 2 (40-80): cracks appear and deepen silently
 if moon_fall_t==40 then
  for i=1,5 do
   add(moon_cracks,{a=rnd(1),len=0,max=moon_r+1+flr(rnd(3))})
  end
 end
 if moon_fall_t>40 and moon_fall_t<=80 then
  for cr in all(moon_cracks) do
   if cr.len<cr.max then cr.len+=0.3 end
  end
 end
 -- phase 3 (t=80): SHATTER — spawn large chunks and debris particles
 if moon_fall_t==80 then
  -- SHATTER sound: replay the catastrophic rumble + big boom
  sfx(12)
  sfx(7)
  -- 8 large rock chunks, slightly offset from center so they look like they came from the moon
  for i=1,8 do
   local outa=(i/8)+rnd(0.06)-0.03
   local sa=rnd(1)
   local sr=rnd(moon_r*0.55)
   local spd=0.18+rnd(0.28)
   add(moon_shards,{
    x=moon_x+cos(sa)*sr,
    y=moon_y+sin(sa)*sr,
    vx=cos(outa)*spd,vy=sin(outa)*spd,
    sz=2+flr(rnd(3)),
    rot=rnd(1),rspd=(rnd(1)-0.5)*0.025,
    age=0,trail={}
   })
  end
  -- 18 small fast-moving debris particles
  for i=1,18 do
   local a=rnd(1)
   local spd=0.6+rnd(0.7)
   add(moon_shards,{
    x=moon_x+(rnd(4)-2),y=moon_y+(rnd(4)-2),
    vx=cos(a)*spd,vy=sin(a)*spd,
    sz=0,rot=0,rspd=0,
    age=0,trail={}
   })
  end
 end
 -- move shards (slow drift for chunks, full speed for particles)
 for s in all(moon_shards) do
  s.x+=s.vx s.y+=s.vy
  s.rot+=s.rspd
  s.age+=1
  s.vy+=0.0015
  if s.sz>0 and s.age<80 then
   add(s.trail,{x=s.x,y=s.y})
   if #s.trail>6 then del(s.trail,s.trail[1]) end
  end
 end
 -- tick fx
 for f in all(fx) do
  if f.kind=='smoke' then f.ex+=f.vx or 0 f.ey+=f.vy or 0 end
  f.t-=1
  if f.t<=0 then del(fx,f) end
 end
 if moon_fall_t>=200 then
  -- respawn a fresh scatter of slowly-drifting shards for the loss screen
  moon_shards={}
  for i=1,9 do
   local a=i/9
   local r=4+rnd(14)
   local spd=0.04+rnd(0.05)
   add(moon_shards,{
    x=moon_x+cos(a)*r,
    y=moon_y+sin(a)*r,
    vx=cos(a)*spd,vy=sin(a)*spd,
    sz=2+flr(rnd(3)),
    rot=rnd(1),rspd=(rnd(1)-0.5)*0.015,
    age=40,trail={}
   })
  end
  state='result'
 end
end

function draw_moon_fall()
 -- screen flash on the first break
 if moon_fall_t<8 then
  local c=moon_fall_t%2==0 and 7 or 8
  rectfill(0,0,127,127,c)
  return
 end
 cls(0) draw_stars()
 -- earth only if it's still alive (skip it during/after boss phase)
 if earth_core_hp>0 then draw_earth_system() end
 -- moon body (only before full shatter at t=80)
 if moon_fall_t<80 then
  -- body: dim gray, heavy pockmarks
  circfill(moon_x,moon_y,moon_r,5)
  circfill(moon_x,moon_y,moon_r-2,1)
  local ba=earth_theta
  local mr2=(moon_r-1)*(moon_r-1)
  for cr in all(moon_craters) do
   local ca=(ba+cr.a)%1
   local cx=moon_x+cos(ca)*cr.r
   local cy=moon_y+sin(ca)*cr.r
   local dx=cx-moon_x local dy=cy-moon_y
   if dx*dx+dy*dy<=mr2 then
    pset(cx,cy,0)
    pset(cx+1,cy,0) pset(cx,cy+1,0)
    if cr.sz>=2 then pset(cx-1,cy,0) pset(cx,cy-1,0) end
   end
  end
  circ(moon_x,moon_y,moon_r,6)
  for b in all(moon_bites) do
   local ca=(ba+b.a)%1
   local bx=moon_x+cos(ca)*moon_r
   local by=moon_y+sin(ca)*moon_r
   circfill(bx,by,b.sz,0)
  end
  for cr in all(moon_cracks) do
   local bx=moon_x+cos(cr.a)*cr.len
   local by=moon_y+sin(cr.a)*cr.len
   line(moon_x,moon_y,bx,by,0)
   local ja=cr.a+0.01
   line(moon_x+cos(ja)*cr.len*0.5,moon_y+sin(ja)*cr.len*0.5,bx,by,0)
   if cr.len>2 then
    pset(bx,by,8)
    pset(bx-1,by,9)
    pset(bx,by-1,9)
   end
  end
  if moon_fall_t>60 then
   circ(moon_x,moon_y,moon_r-3,8)
   pset(moon_x,moon_y,9)
  end
 end
 -- SHATTER BLAST at t=80..115: multi-ring explosion, central flash, hot ejecta
 if moon_fall_t>=80 and moon_fall_t<115 then
  local dt=moon_fall_t-80
  local p=dt/35
  -- expanding shockwave ring (two-color, wide)
  if dt<25 then
   local r=moon_r+flr(p*36)
   local c1=dt<6 and 7 or (dt<14 and 10 or 9)
   local c2=dt<6 and 10 or (dt<14 and 9 or 8)
   circ(moon_x,moon_y,r,c1)
   if r>1 then circ(moon_x,moon_y,r-1,c2) end
   if r>3 then circ(moon_x,moon_y,r-3,8) end
  end
  -- bright central flash sphere, shrinking
  if dt<18 then
   local fr=flr((1-dt/18)*9)
   if fr>=0 then
    circfill(moon_x,moon_y,fr,dt<4 and 7 or (dt<10 and 10 or 9))
    if fr>2 then circfill(moon_x,moon_y,fr-2,7) end
   end
  end
  -- radiating hot ejecta lines for the first 10 frames
  if dt<10 then
   for i=0,11 do
    local ea=i/12+dt*0.01
    local r0=moon_r+1+dt*0.5
    local r1=moon_r+2+dt*2.2
    local x0=moon_x+cos(ea)*r0
    local y0=moon_y+sin(ea)*r0
    local x1=moon_x+cos(ea)*r1
    local y1=moon_y+sin(ea)*r1
    line(x0,y0,x1,y1,dt<4 and 7 or (dt<7 and 10 or 9))
   end
  end
 end
 -- lingering dust ring at original moon position, fades ~120 frames
 if moon_fall_t>=88 then
  local dt=moon_fall_t-88
  local df=max(0,1-dt/100)
  if df>0.05 then
   local dc=dt<20 and 5 or 1
   local n=10
   for i=0,n-1 do
    local da=i/n+dt*0.004
    local dr=moon_r+2+dt*0.08
    local dx=cos(da)*dr local dy=sin(da)*dr
    pset(moon_x+dx,moon_y+dy,dc)
    pset(moon_x+dx*0.6,moon_y+dy*0.6,dc)
   end
  end
 end
 draw_moon_shards()
 draw_fx()
 if moon_fall_t>120 then
  rectfill(28,54,100,66,0)
  print("moon broken",40,58,8)
 end
end

function draw_moon_shards()
 for s in all(moon_shards) do
  if s.sz==0 then
   local pc=5
   if s.age<8 then pc=7
   elseif s.age<16 then pc=10
   elseif s.age<28 then pc=9 end
   pset(s.x,s.y,pc)
   if s.age<12 then
    pset(s.x-s.vx,s.y-s.vy,s.age<6 and 10 or 8)
   end
  else
   for i=1,#s.trail do
    local tp=s.trail[i]
    local frac=i/#s.trail
    local tc=1
    if frac>0.6 then tc=5 end
    if s.age<20 and frac>0.4 then tc=(frac>0.7 and 9 or 8) end
    pset(tp.x,tp.y,tc)
   end
   local sz=s.sz
   local x=s.x local y=s.y
   circfill(x,y,sz,5)
   circfill(x,y,max(0,sz-1),6)
   if sz>=3 then pset(x,y,1) end
   for i=0,4 do
    local ba=s.rot+i/5
    local cx=x+cos(ba)*sz
    local cy=y+sin(ba)*sz
    pset(cx,cy,0)
    if sz>=3 then pset(x+cos(ba)*(sz-1),y+sin(ba)*(sz-1),1) end
   end
   pset(x-sz,y,0)
   pset(x+sz,y,0)
   pset(x,y-sz,0)
   pset(x,y+sz,0)
   if s.age<28 then
    local gc=s.age<10 and 10 or (s.age<20 and 9 or 8)
    pset(x,y,gc)
    if sz>=3 then
     pset(x-1,y,gc) pset(x,y-1,gc)
    end
   end
  end
 end
end

function draw_earth_fall()
 -- initial screen flash
 if earth_fall_t<10 then
  local c=earth_fall_t%2==0 and 7 or 9
  rectfill(0,0,127,127,c)
  return
 end
 cls(0) draw_stars() draw_moon_system()
 -- orbit ring: pulse red pre-split, fade out after
 if earth_fall_t<60 then
  local ringc=1
  if (earth_fall_t%10)<5 then ringc=8 end
  circ(moon_x,moon_y,earth_orbit_r,ringc)
 end
 if earth_fall_t<38 then
  -- phase 1: intact wounded earth being hammered
  draw_earth_system()
  -- bright shockwave pulses expanding from earth
  local pr=(earth_fall_t%18)/18
  local r=earth_r+flr(pr*22)
  circ(earth_x,earth_y,r,9)
  if r>4 then circ(earth_x,earth_y,r-3,8) end
 else
  -- phase 2+3: split. Big split flash in the first frames, then halves
  local dt=earth_fall_t-38
  if dt<18 then
   -- expanding shockwave ring from the split point
   local r=earth_r+flr((dt/18)*32)
   local c1=dt<6 and 7 or (dt<12 and 10 or 9)
   circ(earth_x,earth_y,r,c1)
   if r>2 then circ(earth_x,earth_y,r-2,8) end
  end
  -- draw the two halves
  for h in all(earth_halves) do
   draw_earth_half(h)
  end
  -- bright central seam flash just after split
  if dt<6 then
   circfill(earth_x,earth_y,6-dt,7)
  end
 end
 draw_fx()
 -- title
 if earth_fall_t>55 then
  rectfill(26,54,102,66,0)
  print("earth silenced",32,58,8)
 end
end

function update_play()
 if btnp(6) then paused=not paused end
 if paused then return end
 upd_earth_orbit() upd_mods()

 if aim then
  -- L/R fine horizontal, U/D coarse vertical on a hidden direction point
  if btnp(0) then aim.cx-=4 end
  if btnp(1) then aim.cx+=4 end
  if btnp(2) then aim.cy-=10 end
  if btnp(3) then aim.cy+=10 end
  aim.cx=mid(2,aim.cx,126)
  aim.cy=mid(2,aim.cy,126)
  aim.ang=atan2(aim.cx-moon_x,aim.cy-moon_y)
  if btnp(4) then fire_aimed() end
  -- X: cancel aim immediately and arm interceptor (blocked during opening salvo)
  if btnp(5) and war_started then
   aim=nil
   set_special('counter')
   sel_id=nil
  end
 else
  -- normal mode: L/R OR U/D both cycle targets
  if btnp(0) or btnp(2) then cycle_target(-1) end
  if btnp(1) or btnp(3) then cycle_target(1) end
  if btnp(5) then cycle_special(1) end
  if btnp(4) then
   local t=sel_target()
   if t then
    if t.type=='contact' then launch_auto_lock(t.id)
    else enter_aim(t) end
   end
  end
 end

 if interceptor_cd>0 then interceptor_cd-=1 end
 if fire_denied_t>0 then fire_denied_t-=1 end

 if war_started then
  local p=packets[packet_i]
  while wave_i<=#p.waves and packet_tick>=p.waves[wave_i][1] do
   local w=p.waves[wave_i]
   spawn_contact(w[2],w[3],w[4],w[5])
   wave_i+=1
  end
  -- endless escalating pressure in the final packet (always active)
  if p.core_strike then
   p4_timer+=1
   local interval=max(50,140-p4_wave_count*5)
   if p4_timer>=interval then
    p4_timer=0
    local sl={'outpost','yard','vault'}
    local tgt=sl[(p4_wave_count%3)+1]
    local kind=(p4_wave_count%4==3) and 'bus' or 'raider'
    spawn_contact('earth',kind,'transfer',tgt)
    p4_wave_count+=1
   end
  end
 end

 upd_contacts() upd_interceptors() upd_heavies() upd_bombs()
 upd_debris() upd_point_defense() auto_tug() upd_tug()
 upd_opener_marks()
 -- upd_heavies may have triggered the earth death sequence — bail before the
 -- packet_done check below clobbers state back to 'result'
 if state~='play' then return end
 if war_started then upd_charge_regen() upd_module_pressure() upd_moon_heal() end

 for f in all(fx) do
  if f.kind=='smoke' then
   f.ex+=f.vx or 0
   f.ey+=f.vy or 0
  end
  f.t-=1
  if f.t<=0 then del(fx,f) end
 end

 -- moon death check runs regardless of war_started so the opener self-hit lands here too
 if moon_int<=0 then
  moon_fall_t=0 moon_cracks={} moon_shards={}
  sfx(12)
  state='moon_fall' return
 end
 if war_started then
  if packet_done() then
   if packet_i<#packets then start_intermission()
   else state='result' end
   return
  end
  packet_tick+=1
 end
 gtick+=1
end

-- draw
function draw_stars()
 for s in all(stars) do
  s.phase+=s.rate
  if s.phase>=1 then s.phase-=1 end
  local b=s.phase<0.5 and s.phase*2 or (1-s.phase)*2
  local col
  if s.bright==2 then col=b>0.6 and 7 or b>0.3 and 6 or 5
  elseif s.bright==1 then col=b>0.5 and 6 or 5
  else col=b>0.4 and 5 or 1 end
  pset(s.x,s.y,col)
 end
end

function draw_moon_system()
 -- moon body base
 circfill(moon_x,moon_y,moon_r,6)
 -- highlight on upper-left (light source)
 pset(moon_x-3,moon_y-3,7)
 pset(moon_x-4,moon_y-2,7)
 pset(moon_x-2,moon_y-4,7)
 -- shadow on lower-right
 pset(moon_x+3,moon_y+3,5)
 pset(moon_x+4,moon_y+2,5)
 pset(moon_x+2,moon_y+4,5)
 -- craters (pockmarks + accumulated damage, rotate with tidal lock)
 local ba=earth_theta
 local mr2=(moon_r-1)*(moon_r-1)
 for cr in all(moon_craters) do
  local ca=(ba+cr.a)%1
  local cx=moon_x+cos(ca)*cr.r
  local cy=moon_y+sin(ca)*cr.r
  local dx=cx-moon_x local dy=cy-moon_y
  if dx*dx+dy*dy<=mr2 then
   if cr.sz>=2 then
    pset(cx,cy,0) pset(cx+1,cy,1)
    pset(cx,cy+1,1) pset(cx+1,cy+1,5)
   else
    pset(cx,cy,1) pset(cx+1,cy,5)
   end
  end
 end
 -- dynamic cracks scale with current damage ratio and automatically shrink
 -- as integrity regenerates. threshold + gradual ramp so light damage is subtle.
 local dmg_f=1-moon_int/max(1,moon_max_orig)
 local eff=max(0,dmg_f-0.2)
 if eff>0 then
  local n_cracks=flr(eff*8)
  for i=1,n_cracks do
   local a=((i*0.137)+earth_theta*0.3)%1
   local l_end=(moon_r-1)-((i%3)*0.6)
   local l_start=(i%4)*0.8+1
   local x1=moon_x+cos(a)*l_start
   local y1=moon_y+sin(a)*l_start
   local x2=moon_x+cos(a+0.02)*l_end
   local y2=moon_y+sin(a+0.02)*l_end
   line(x1,y1,x2,y2,0)
   if dmg_f>0.55 then
    local mx=(x1+x2)/2 local my=(y1+y2)/2
    pset(mx,my,1)
   end
  end
 end
 -- outline
 circ(moon_x,moon_y,moon_r,5)
 -- BITES: chunks missing from moon (drawn last, cuts silhouette)
 for b in all(moon_bites) do
  local ca=(ba+b.a)%1
  local bx=moon_x+cos(ca)*moon_r
  local by=moon_y+sin(ca)*moon_r
  circfill(bx,by,b.sz,0)
  -- jagged edge rim
  pset(bx-b.sz,by,5)
  pset(bx+b.sz,by,5)
  pset(bx,by-b.sz,5)
  pset(bx,by+b.sz,5)
 end
end

function draw_earth_system()
 -- dynamic ocean/land colors based on damage
 local oc,lc,lhl=get_earth_colors()
 -- ocean base
 circfill(earth_x,earth_y,earth_r,oc)
 -- continents (projection), stretched latitude for full coverage
 local er2=(earth_r-1)*(earth_r-1)
 for i=1,#c_lon do
  local lon=c_lon[i]/100
  local lat=c_lat[i]/100
  local rel=(lon-earth_spin)%1
  if rel>0.5 then rel-=1 end
  if abs(rel)<0.25 then
   local x=earth_x-sin(rel)*earth_r
   local y=earth_y+lat*earth_r*2.5
   local dx=x-earth_x local dy=y-earth_y
   if dx*dx+dy*dy<=er2 then
    local b=cos(rel)
    local col=b>0.85 and lhl or lc
    pset(x,y,col)
    local dx2=(x+1)-earth_x
    if dx2*dx2+dy*dy<=er2 then pset(x+1,y,col) end
    local dy2=(y+1)-earth_y
    if dx*dx+dy2*dy2<=er2 and b>0.5 then pset(x,y+1,col) end
   end
  end
 end
 -- persistent damage marks (2x2 clusters, visible per-hit)
 for d in all(earth_damage) do
  local rel=(d.lon-earth_spin)%1
  if rel>0.5 then rel-=1 end
  if abs(rel)<0.25 then
   local x=earth_x-sin(rel)*earth_r
   local y=earth_y+d.lat*earth_r*2.5
   local dx=x-earth_x local dy=y-earth_y
   if dx*dx+dy*dy<=er2 then
    local cc,cb
    if d.land then cc=4 cb=9 else cc=1 cb=0 end
    pset(x,y,cc)
    local dx2=(x+1)-earth_x
    local dy2=(y+1)-earth_y
    if dx2*dx2+dy*dy<=er2 then pset(x+1,y,cc) end
    if dx*dx+dy2*dy2<=er2 then pset(x,y+1,cb) end
    if dx2*dx2+dy2*dy2<=er2 then pset(x+1,y+1,cc) end
   end
  end
 end
 -- chunk marks (persistent purplish wound, bigger than sling scar)
 for m in all(chunk_marks) do
  local rel=(m.lon-earth_spin)%1
  if rel>0.5 then rel-=1 end
  if abs(rel)<0.25 then
   local mx=earth_x-sin(rel)*earth_r
   local my=earth_y+m.lat*earth_r*2.5
   local dxc=mx-earth_x local dyc=my-earth_y
   if dxc*dxc+dyc*dyc<=er2 then
    -- regional dead patch: filled grayish-brown blob, clipped to earth surface
    for ddy=-3,3 do
     for ddx=-3,3 do
      local d2=ddx*ddx+ddy*ddy
      if d2<=9 then
       local px=mx+ddx local py=my+ddy
       local eex=px-earth_x local eey=py-earth_y
       if eex*eex+eey*eey<=er2 then
        local pc
        if d2<=1 then pc=0        -- deepest core: black crater
        elseif d2<=4 then pc=5    -- dark gray ash
        elseif d2<=6 then pc=4    -- brown scorch
        else pc=5 end             -- outer gray feathering
        pset(px,py,pc)
       end
      end
     end
    end
   end
  end
 end
 -- opener marks (large fading localized scar)
 for m in all(opener_marks) do
  local rel=(m.lon-earth_spin)%1
  if rel>0.5 then rel-=1 end
  if abs(rel)<0.25 then
   local mx=earth_x-sin(rel)*earth_r
   local my=earth_y+m.lat*earth_r*2.5
   local dxc=mx-earth_x local dyc=my-earth_y
   if dxc*dxc+dyc*dyc<=er2 then
    local life=1-(m.age/m.max_age)
    local col
    if life>0.66 then col=5
    elseif life>0.33 then col=4
    else col=1 end
    for ddx=-1,1 do
     for ddy=-1,1 do
      local px=mx+ddx local py=my+ddy
      local dx2=px-earth_x local dy2=py-earth_y
      if dx2*dx2+dy2*dy2<=er2 then pset(px,py,col) end
     end
    end
   end
  end
 end
 -- polar ice caps (dim as earth dies)
 local ice=earth_damage_level>70 and 6 or 7
 pset(earth_x,earth_y-earth_r+1,ice)
 pset(earth_x-1,earth_y-earth_r+1,ice)
 pset(earth_x+1,earth_y-earth_r+1,ice)
 pset(earth_x,earth_y+earth_r-1,ice)
 -- modules
 -- aegis shield arc (visible cyan barrier)
 for m in all(mods) do
  if m.kind=='aegis' and m.hp>0 then
   local half=m.barc or 0.07
   local steps=14
   for i=0,steps do
    local a=(m.theta-half+i*(2*half/steps))%1
    local cx=cos(a) local cy=sin(a)
    pset(earth_x+cx*(earth_r+3),earth_y+cy*(earth_r+3),12)
    pset(earth_x+cx*(earth_r+4),earth_y+cy*(earth_r+4),12)
    pset(earth_x+cx*(earth_r+5),earth_y+cy*(earth_r+5),1)
   end
  end
 end
 for m in all(mods) do
  if m.hp>0 then
   local x,y=mod_pos(m)
   -- outward unit vector from earth through the module (u axis) and its
   -- perpendicular (v axis) so shapes can be oriented facing outward
   local dxe=x-earth_x local dye=y-earth_y
   local dl=sqrt(dxe*dxe+dye*dye)
   if dl<0.1 then dl=1 end
   local ox=dxe/dl  local oy=dye/dl       -- u: outward from earth
   local vx=-oy     local vy=ox            -- v: tangent
   local function mp(u,v,c)
    pset(x+u*ox+v*vx,y+u*oy+v*vy,c)
   end
   if m.kind=='driver' then
    -- lowercase "t" shipyard: crossbar near the outward end, stem toward earth
    -- u = outward offset, v = tangent offset
    mp(2,0,m.col)         -- top of t
    mp(1,-2,m.col) mp(1,-1,m.col) mp(1,0,m.col) mp(1,1,m.col) mp(1,2,m.col)  -- wide crossbar
    mp(0,0,m.col)         -- stem
    mp(-1,0,m.col)
    mp(-2,0,m.col)
   elseif m.kind=='jammer' then
    -- satellite dish: bowl opens outward (away from earth), stem toward earth
    mp(2,-2,m.col) mp(2,-1,m.col) mp(2,0,m.col) mp(2,1,m.col) mp(2,2,m.col)  -- rim
    mp(1,-1,m.col) mp(1,0,m.col) mp(1,1,m.col)   -- bowl interior
    mp(0,0,m.col)          -- focal / stem top
    mp(-1,0,m.col)         -- stem
   else
    circfill(x,y,2,m.col)
    -- aegis keeps the hp dots so you can read its health under the shield arc
    for i=0,m.mhp-1 do pset(x-1+i*2,y+4,i<m.hp and m.col or 5) end
   end
  end
 end
end

function contact_dir(c)
 if c.state=='transfer' then
  local t2=min(1,c.u+0.02)
  local p1=bez2(c.start,c.ctl,c.pend,c.u)
  local p2=bez2(c.start,c.ctl,c.pend,t2)
  return p2.x-p1.x,p2.y-p1.y
 elseif c.state=='orbit' then
  local t2=c.otheta+0.005*c.odir
  return (cos(t2)-cos(c.otheta))*lunar_orbit_r,
         (sin(t2)-sin(c.otheta))*lunar_orbit_r
 elseif c.state=='dive' then
  local t2=min(1,c.u+0.02)
  local p1=bez2(c.dstart,c.dctl,c.dend,c.u)
  local p2=bez2(c.dstart,c.dctl,c.dend,t2)
  return p2.x-p1.x,p2.y-p1.y
 end
 return 1,0
end

function draw_enemy(c,px,py)
 local vx,vy=contact_dir(c)
 if vx*vx+vy*vy<0.01 then vx=1 vy=0 end
 local sp=sqrt(vx*vx+vy*vy)
 local nx=vx/sp local ny=vy/sp
 local prpx=-ny local prpy=nx
 local col=cdefs[c.kind].col
 if c.kind=='raider' then
  pset(px+nx*2,py+ny*2,col)
  pset(px+nx,py+ny,col)
  pset(px,py,col)
  pset(px-nx+prpx,py-ny+prpy,col)
  pset(px-nx-prpx,py-ny-prpy,col)
  pset(px-nx*2,py-ny*2,9)
 elseif c.kind=='bus' then
  -- wrecker: yellow triangular warhead + dark engine block + dynamic thrust
  local am=c.accel_mul or 0.6
  -- triangle tip: 1 -> 3 -> 5 tapering rows, all yellow
  pset(px+nx*3,py+ny*3,col)                              -- tip (1 wide)
  pset(px+nx*2+prpx,py+ny*2+prpy,col)                    -- middle row (3 wide)
  pset(px+nx*2,py+ny*2,col)
  pset(px+nx*2-prpx,py+ny*2-prpy,col)
  pset(px+nx+prpx*2,py+ny+prpy*2,col)                    -- base row (5 wide)
  pset(px+nx+prpx,py+ny+prpy,col)
  pset(px+nx,py+ny,col)
  pset(px+nx-prpx,py+ny-prpy,col)
  pset(px+nx-prpx*2,py+ny-prpy*2,col)
  -- neck (single pixel connecting warhead to engine)
  pset(px,py,col)
  -- dark engine block (not yellow)
  pset(px-nx,py-ny,5)
  -- dynamic thrust: length scales with accel_mul, flickers with gtick
  local base_len=1+flr((am-0.55)*2)
  local flicker=(gtick+c.uid)%4
  local flame_len=min(3,max(1,base_len+(flicker<2 and 1 or 0)))
  for i=1,flame_len do
   local fxp=px-nx*(1+i)
   local fyp=py-ny*(1+i)
   local fc
   if i==1 then fc=10
   elseif i<=flame_len-1 then fc=9
   else fc=8 end
   pset(fxp,fyp,fc)
   if i<=1 then
    pset(fxp+prpx,fyp+prpy,9)
    pset(fxp-prpx,fyp-prpy,9)
   end
  end
  -- random ember sparks when under thrust
  if am>0.8 and ((gtick+c.uid*2)%5)==0 then
   local sj=rnd(3)-1
   pset(px-nx*(flame_len+2)+prpx*sj,py-ny*(flame_len+2)+prpy*sj,8)
  end
 elseif c.kind=='orbiter' then
  pset(px+nx*2,py+ny*2,col)
  pset(px+nx,py+ny,col)
  pset(px,py,col)
  pset(px+prpx,py+prpy,13)
  pset(px-prpx,py-prpy,13)
  pset(px-nx,py-ny,col)
  pset(px-nx-prpx,py-ny-prpy,col)
  pset(px-nx+prpx,py-ny+prpy,col)
 else
  pset(px+nx*2,py+ny*2,col)
  pset(px+nx,py+ny,col)
  pset(px,py,6)
  pset(px-nx,py-ny,col)
 end
end

function draw_contacts()
 local sel=sel_target()
 for c in all(contacts) do
  local p=contact_pos(c)
  draw_enemy(c,p.x,p.y)
  if sel and sel.type=='contact' and sel.id==c.uid then
   rect(p.x-4,p.y-4,p.x+4,p.y+4,7)
  end
 end
end

-- small directional ship: body + tip + wings + optional engine flame
function draw_ship(x,y,vx,vy,col,thrust)
 local sp=sqrt(vx*vx+vy*vy)
 if sp<0.01 then sp=1 end
 local nx=vx/sp local ny=vy/sp
 local px=-ny local py=nx
 -- ship body: tip, center, two wings
 pset(x+nx*2,y+ny*2,col)
 pset(x+nx,y+ny,col)
 pset(x,y,col)
 pset(x-nx+px,y-ny+py,col)
 pset(x-nx-px,y-ny-py,col)
 if thrust then
  pset(x-nx*2,y-ny*2,10)
  pset(x-nx*3,y-ny*3,9)
 end
end

function draw_interceptors()
 for it in all(interceptors) do
  local vx=it.vx local vy=it.vy
  -- point away from moon if stationary
  if vx*vx+vy*vy<0.01 then
   vx=it.x-moon_x vy=it.y-moon_y
  end
  -- engine on while inside scrap zone, then coasting
  local d=dist({x=it.x,y=it.y},{x=moon_x,y=moon_y})
  draw_ship(it.x,it.y,vx,vy,11,d<28)
 end
end

function draw_heavies()
 for h in all(heavies) do
  if h.kind=='moon_chunk' and not h.opener then
   -- chunk: thick tapered gray+white trail with scatter
   local n=#h.trail
   for i=1,n do
    local tp=h.trail[i]
    local k=i/n
    local c=k<0.5 and 1 or (k<0.8 and 5 or 6)
    pset(tp.x,tp.y,c)
    if k>0.6 then pset(tp.x+1,tp.y,c) end
    if k>0.7 then pset(tp.x,tp.y+1,c) end
    if k>0.5 and i%2==0 then pset(tp.x-1,tp.y,5) end
   end
  else
   local tc=1
   if h.kind=='sling' then tc=5 end
   if h.opener then tc=9 end
   for i=1,#h.trail do
    local tp=h.trail[i]
    pset(tp.x,tp.y,tc)
   end
  end
  local bc=h.col
  if h.opener then bc=10 end
  circfill(h.x,h.y,h.size,bc)
  if h.opener then
   circfill(h.x,h.y,1,7)
   pset(h.x-2,h.y,9) pset(h.x+2,h.y,9)
   pset(h.x,h.y-2,9) pset(h.x,h.y+2,9)
  elseif h.kind=='moon_chunk' then
   -- rocky highlight pattern
   circfill(h.x,h.y,h.size-1,5)
   pset(h.x-1,h.y-1,6)
   pset(h.x+1,h.y-1,7)
   pset(h.x+1,h.y+1,1)
   pset(h.x-1,h.y+1,1)
   pset(h.x+2,h.y,5)
   pset(h.x,h.y+2,5)
   -- rocket motor flame while burning
   if h.motor_t and h.motor_t>0 then
    local vl=sqrt(h.vx*h.vx+h.vy*h.vy)
    if vl>0.01 then
     local nx=h.vx/vl local ny=h.vy/vl
     -- back direction from motion
     local bx=h.x-nx*(h.size+1)
     local by=h.y-ny*(h.size+1)
     -- wide flame core (orange)
     circfill(bx,by,1,9)
     pset(bx,by,10)
     -- longer yellow tip
     local bx2=h.x-nx*(h.size+2)
     local by2=h.y-ny*(h.size+2)
     pset(bx2,by2,10)
     -- red scatter at the outer edge
     local bx3=h.x-nx*(h.size+3)
     local by3=h.y-ny*(h.size+3)
     -- perpendicular jitter for flame width
     local px=-ny local py=nx
     if (h.motor_t%3)==0 then
      pset(bx3,by3,8)
      pset(bx2+px,by2+py,9)
      pset(bx2-px,by2-py,9)
     else
      pset(bx2+px,by2+py,8)
      pset(bx2-px,by2-py,8)
     end
    end
   end
  end
 end
end

function draw_debris()
 for d in all(debris) do
  local r=d.mass>1 and lunar_orbit_r or 16
  local x=moon_x+cos(d.theta)*r local y=moon_y+sin(d.theta)*r
  local hot=d.hot>0
  -- cold scrap: gray pixel body with a dim dark-blue outline; reads as metal.
  -- hot scrap: same gray but with a single warm accent pixel.
  local c1=6      -- bright gray (core)
  local c2=5      -- mid gray (edge)
  local c3=13     -- cool lavender-gray (shadow)
  -- irregular scrap shape based on uid
  local s=d.uid%4
  if s==0 then
   pset(x,y,c1) pset(x+1,y,c2) pset(x,y+1,c3) pset(x+1,y-1,c2)
  elseif s==1 then
   pset(x-1,y,c2) pset(x,y,c1) pset(x+1,y,c3) pset(x,y+1,c2)
  elseif s==2 then
   pset(x,y-1,c2) pset(x-1,y,c3) pset(x,y,c1) pset(x,y+1,c2)
  else
   pset(x,y,c1) pset(x+1,y+1,c2) pset(x-1,y-1,c2) pset(x+1,y-1,c3)
  end
  -- single small warm accent for hot debris (one pixel, no big yellow cluster)
  if hot then pset(x,y,10) end
  -- claimed markers: dim gray corner pips so they don't read as gold
  if d.claimed then
   pset(x-2,y-2,5) pset(x+2,y-2,5) pset(x-2,y+2,5) pset(x+2,y+2,5)
  end
 end
end

function draw_tug()
 if not tug then return end
 local yx,yy=moon_site_pos('yard')
 -- find current debris position (or use saved back point)
 local tx,ty=yx,yy
 local has_debris=false
 for d in all(debris) do
  if d.uid==tug.tid then
   local r=d.mass>1 and lunar_orbit_r or 16
   tx=moon_x+cos(d.theta)*r ty=moon_y+sin(d.theta)*r
   has_debris=true
  end
 end
 if tug.st=='back' and not has_debris then
  tx=tug.back_x or yx ty=tug.back_y or yy
 end
 local f=1-(tug.t/max(1,tug.mt))
 local mx=(yx+tx)*0.5 local my=(yy+ty)*0.5
 local ox=-(my-moon_y)*0.15 local oy=(mx-moon_x)*0.15
 local x,y
 if tug.st=='out' then
  -- approach stops short of debris (3px toward yard)
  local ddx=yx-tx local ddy=yy-ty
  local dl=sqrt(ddx*ddx+ddy*ddy)
  local apx,apy=tx,ty
  if dl>0.5 then apx=tx+ddx/dl*3 apy=ty+ddy/dl*3 end
  x=lerp(lerp(yx,mx+ox,f),lerp(mx+ox,apx,f),f)
  y=lerp(lerp(yy,my+oy,f),lerp(my+oy,apy,f),f)
 elseif tug.st=='grab' then
  -- park offset from debris toward yard
  local ddx=yx-tx local ddy=yy-ty
  local dl=sqrt(ddx*ddx+ddy*ddy)
  if dl>0.5 then
   x=tx+ddx/dl*3 y=ty+ddy/dl*3
  else
   x=tx-3 y=ty
  end
 else
  -- back: interpolate from saved back point to yard
  x=lerp(lerp(tx,mx+ox,f),lerp(mx+ox,yx,f),f)
  y=lerp(lerp(ty,my+oy,f),lerp(my+oy,yy,f),f)
 end
 tug.lx=x tug.ly=y
 -- tug ship: yellow triangle shape
 if tug.st=='out' then
  draw_ship(x,y,tx-x,ty-y,10,true)
 elseif tug.st=='back' then
  draw_ship(x,y,yx-x,yy-y,10,true)
  -- visible cargo attached (gray scrap, not bright yellow)
  if tug.carry>0 then
   local ddx=yx-x local ddy=yy-y
   local ddl=sqrt(ddx*ddx+ddy*ddy)
   if ddl>0.5 then
    local bx=x-ddx/ddl*2 local by=y-ddy/ddl*2
    pset(bx,by,6) pset(bx-1,by,13) pset(bx,by-1,5)
   end
  end
 else
  -- grab: stationary small cross
  pset(x,y,10) pset(x+1,y,10) pset(x-1,y,10)
  pset(x,y+1,10) pset(x,y-1,10)
 end
 -- processing: pulsing yellow cutting beam + orbiting sparks
 if tug.st=='grab' then
  local t=tug.t
  if t%3<2 then line(x,y,tx,ty,10) end
  for i=0,3 do
   local sa=(t*0.02+i*0.25)%1
   local sr=2+(i%2)
   pset(tx+cos(sa)*sr,ty+sin(sa)*sr,i%2==0 and 10 or 9)
  end
 end
end

function draw_aim_preview()
 if not aim then return end
 -- boss phase: shots fly straight, so preview is a dotted straight line
 if state=='boss_play' then
  local px=moon_x+cos(aim.ang)*(moon_r+3)
  local py=moon_y+sin(aim.ang)*(moon_r+3)
  local dx=cos(aim.ang) local dy=sin(aim.ang)
  for i=1,80 do
   px+=dx py+=dy
   if i%3==0 then pset(px,py,7) end
   if px<0 or px>127 or py<0 or py>127 then break end
  end
  -- short aim line from moon surface
  local lx0=moon_x+cos(aim.ang)*moon_r
  local ly0=moon_y+sin(aim.ang)*moon_r
  local lx1=moon_x+cos(aim.ang)*(moon_r+6)
  local ly1=moon_y+sin(aim.ang)*(moon_r+6)
  line(lx0,ly0,lx1,ly1,7)
  return
 end
 local spd=aim.sp.lspd or launch_spd
 local is_sling=aim.sp.id=='sling'
 local is_chunk=aim.sp.id=='moon_chunk'
 local mot_t=is_chunk and 26 or 0
 -- start preview from outside moon surface
 local px=moon_x+cos(aim.ang)*(moon_r+3)
 local py=moon_y+sin(aim.ang)*(moon_r+3)
 local pvx=cos(aim.ang)*spd local pvy=sin(aim.ang)*spd
 for i=1,120 do
  -- chunk motor thrust
  if mot_t>0 then
   local vl=sqrt(pvx*pvx+pvy*pvy)
   if vl>0.01 then
    pvx+=pvx/vl*0.011
    pvy+=pvy/vl*0.011
   end
   mot_t-=1
  end
  local dx=earth_x-px local dy=earth_y-py
  local d=sqrt(dx*dx+dy*dy)
  if d<1 then d=1 end
  local g=min(grav_k/(d*d),0.15)
  if is_sling then g*=0.4 end
  pvx+=dx/d*g pvy+=dy/d*g
  -- velocity caps to match runtime
  if is_sling then
   local pvl=sqrt(pvx*pvx+pvy*pvy)
   if pvl>1.1 then pvx=pvx/pvl*1.1 pvy=pvy/pvl*1.1 end
  elseif is_chunk then
   local pvl=sqrt(pvx*pvx+pvy*pvy)
   if pvl>0.78 then pvx=pvx/pvl*0.78 pvy=pvy/pvl*0.78 end
  end
  px+=pvx py+=pvy
  if i%2==0 then pset(px,py,7) end
  if px<-5 or px>132 or py<-5 or py>132 then break end
  if d<earth_r+3 then
   circ(px,py,3,10) break
  end
 end
 -- aim line from moon surface
 local lx0=moon_x+cos(aim.ang)*moon_r
 local ly0=moon_y+sin(aim.ang)*moon_r
 local lx1=moon_x+cos(aim.ang)*(moon_r+6)
 local ly1=moon_y+sin(aim.ang)*(moon_r+6)
 line(lx0,ly0,lx1,ly1,7)
end

function draw_fx()
 for f in all(fx) do
  local p=1-(f.t/(f.mt or 10))
  if f.kind=='impact' then
   circ(f.x,f.y,flr(p*5),8)
   if p<0.3 then circfill(f.x,f.y,1,7) end
  elseif f.kind=='hit' then circ(f.x,f.y,flr(p*3),11)
  elseif f.kind=='explosion' then
   local r=flr(p*5)
   circ(f.x,f.y,r,9)
   if r>=2 then circ(f.x,f.y,r-2,10) end
   if p<0.4 then circfill(f.x,f.y,1,8) end
   if p>0.1 and p<0.5 then
    pset(f.x+flr(rnd(5))-2,f.y+flr(rnd(5))-2,10)
    pset(f.x+flr(rnd(5))-2,f.y+flr(rnd(5))-2,9)
   end
  elseif f.kind=='miss' then
   local r=flr(p*3)
   line(f.x-r,f.y-r,f.x+r,f.y+r,9) line(f.x+r,f.y-r,f.x-r,f.y+r,9)
  elseif f.kind=='fizz' then
   -- harmless scrape/spark: faint, small, decays fast
   if p<0.5 then pset(f.x,f.y,6) end
   if p<0.3 then
    pset(f.x+1,f.y,5) pset(f.x,f.y+1,5)
    pset(f.x-1,f.y,5) pset(f.x,f.y-1,5)
   end
  elseif f.kind=='block' then
   local r=flr(p*6)
   circ(f.x,f.y,r,12)
   if r>=2 then circ(f.x,f.y,r-2,1) end
   if p<0.4 then pset(f.x,f.y,7) end
  elseif f.kind=='pd_beam' then
   -- laser beam from moon center to target, alternating red/green each frame
   local c=(f.t%2==0) and 8 or 11
   line(f.x0,f.y0,f.x,f.y,c)
   -- thicker beam using perpendicular offsets
   local dx=f.x-f.x0 local dy=f.y-f.y0
   local dl=sqrt(dx*dx+dy*dy)
   if dl>0.5 then
    local px=-dy/dl local py=dx/dl
    line(f.x0+px,f.y0+py,f.x,f.y,c)
    line(f.x0-px,f.y0-py,f.x,f.y,c)
   end
   -- single impact burst: only visible for the first few frames then just a pixel
   if f.t>f.mt-4 then
    circfill(f.x,f.y,2,c)
    pset(f.x,f.y,7)
   else
    pset(f.x,f.y,c)
   end
  elseif f.kind=='muzzle' then
   -- yellow/orange cannon flash
   local r=flr(p*3)
   circfill(f.x,f.y,r,10)
   if r>=1 then circ(f.x,f.y,r+1,9) end
   if p<0.4 then pset(f.x,f.y,7) end
   -- a few bright sparks radiating out briefly
   if p<0.5 then
    local sa=f.t*0.13
    pset(f.x+cos(sa)*(r+2),f.y+sin(sa)*(r+2),10)
    pset(f.x-cos(sa)*(r+2),f.y-sin(sa)*(r+2),10)
   end
  elseif f.kind=='sabot' then
   local r=flr(p*4)
   circ(f.x,f.y,r,14) circ(f.x,f.y,r+1,2)
   pset(f.x+flr(rnd(3))-1,f.y+flr(rnd(3))-1,8)
  elseif f.kind=='denied_blink' then
   -- tiny "no fire" cue near moon center: small red cross
   if p<0.5 then
    pset(f.x,f.y,8)
    pset(f.x-1,f.y,8) pset(f.x+1,f.y,8)
    pset(f.x,f.y-1,8) pset(f.x,f.y+1,8)
   end
  elseif f.kind=='deliver_ping' then
   -- tiny ping at moon edge when scrap lands
   local r=flr(p*4)
   circ(f.x,f.y,r,10)
   if p<0.4 then pset(f.x,f.y,7) end
  elseif f.kind=='repair_spark' then
   -- single tiny cyan sparkle on moon edge when integrity restored
   if p<0.6 then
    pset(f.x,f.y,7)
    pset(f.x+1,f.y,12) pset(f.x-1,f.y,12)
    pset(f.x,f.y+1,12) pset(f.x,f.y-1,12)
   end
  elseif f.kind=='launch' then circ(f.x,f.y,flr(p*4),11)
  elseif f.kind=='launch_heavy' then circ(moon_x,moon_y,moon_r+flr(p*4),10)
  elseif f.kind=='heavy_miss' then pset(f.x+rnd(4)-2,f.y+rnd(4)-2,9)
  elseif f.kind=='chunk_tear' then
   -- violent moon-crack flash: layered rings + jagged ejecta
   local r1=moon_r+flr(p*6)
   circ(moon_x,moon_y,r1,8)
   circ(moon_x,moon_y,max(0,r1-2),9)
   if p<0.5 then circ(moon_x,moon_y,max(0,r1-4),10) end
   -- ejecta specks radiating from moon edge
   if p<0.7 then
    for i=0,7 do
     local ea=i/8+p*0.1
     local er=moon_r+1+flr(p*8)
     pset(moon_x+cos(ea)*er,moon_y+sin(ea)*er,5)
    end
   end
  elseif f.kind=='tug_grab' then circ(f.x,f.y,flr(p*3),10)
  elseif f.kind=='land_hit' then
   -- dust burst + flash on landmass
   local sx=earth_x+(f.ex or 0)
   local sy=earth_y+(f.ey or 0)
   local r=flr(p*4)
   circ(sx,sy,r,9)
   if p<0.3 then pset(sx,sy,7) pset(sx+1,sy,7) end
   if p<0.5 then pset(sx,sy-1,8) end
  elseif f.kind=='splash' then
   -- expanding water ring
   local sx=earth_x+(f.ex or 0)
   local sy=earth_y+(f.ey or 0)
   local r=flr(p*6)
   circ(sx,sy,r,7)
   circ(sx,sy,max(0,r-2),12)
   if p<0.25 then
    circfill(sx,sy,1,7)
    pset(sx,sy-1,7)
    pset(sx-1,sy,7)
    pset(sx+1,sy,7)
   end
  elseif f.kind=='chunk_impact' then
   -- heavy purple shockwave + bright core + radiating dust
   local life=f.t/f.mt
   local sx=earth_x+(f.ex or 0)
   local sy=earth_y+(f.ey or 0)
   local rr=flr(p*10)
   circ(sx,sy,rr,14)
   circ(sx,sy,max(0,rr-2),2)
   circ(earth_x,earth_y,earth_r+2+flr(p*3),14)
   circ(earth_x,earth_y,earth_r+1,2)
   if life>0.6 then
    circfill(sx,sy,3,7)
    circfill(sx,sy,2,10)
   elseif life>0.3 then
    circfill(sx,sy,2,9)
    pset(sx,sy,7)
   else
    pset(sx,sy,8)
   end
   -- scatter debris
   if life>0.2 and life<0.8 then
    for i=0,3 do
     local a=(f.ex or 0)*0.1+i*0.25+p
     pset(sx+cos(a)*(rr+1),sy+sin(a)*(rr+1),5)
    end
   end
  elseif f.kind=='earth_flash' then
   local life=f.t/f.mt
   local sx=earth_x+(f.ex or 0)
   local sy=earth_y+(f.ey or 0)
   if life>0.6 then
    circfill(sx,sy,5,7)
    circ(earth_x,earth_y,earth_r+2,10)
   elseif life>0.3 then
    circfill(sx,sy,3,10)
    circ(earth_x,earth_y,earth_r+1,9)
   else
    circfill(sx,sy,1,9)
   end
  elseif f.kind=='smoke' then
   local sx=earth_x+(f.ex or 0)
   local sy=earth_y+(f.ey or 0)
   local life=f.t/f.mt
   local col=f.col or 5
   if life<0.3 then col=1 end
   pset(sx,sy,col)
   if life>0.3 then pset(sx+1,sy,col) end
   if life>0.5 then pset(sx,sy-1,col) end
   if life>0.7 then pset(sx-1,sy,col) pset(sx,sy+1,col) end
  end
 end
end

function draw_weapon_border()
 local sp=current_special()
 if not sp then return end
 local bc=11
 if sp.id=='sling' then bc=10
 elseif sp.id=='moon_chunk' then bc=8 end
 rect(0,0,127,127,bc)
end

function draw_hud()
 print("int",1,1,8)
 -- bar scales against moon_max_orig so the "lost max" from chunk launches
 -- stays visibly grayed out on the right side of the frame
 local om=max(1,moon_max_orig)
 local bw=flr(moon_int*8/om)
 local mw=flr(moon_max*8/om)
 if bw>0 then rectfill(13,1,13+bw,4,8) end
 -- purplish-gray fill for the lost-max portion (col 13 = lavender)
 if mw<8 then rectfill(14+mw,2,20,3,13) end
 rect(13,1,21,4,5)
 print("chg",26,1,12)
 for i=0,max_charge-1 do rectfill(38+i*2,1,38+i*2,4,i<charge and 12 or 1) end
 -- prop pips: progress toward next charge, drawn below the charge bar
 local pthresh=upgrades.recycler and 1 or 2
 for i=0,pthresh-1 do pset(38+i*2,6,i<prop and 9 or 1) end
 local cbx=38+max_charge*2+2
 if state=='boss_play' then
  print("human revenge",cbx+10,1,8)
 else
  print(packet_i,cbx+10,1,6)
  print(packets[packet_i].label,cbx+16,1,7)
 end
 local sp=current_special()
 if aim then
  print("aiming \142fire \151cancel",1,122,10)
 else
  local sp_txt=sp and sp.label or "---"
  local sp_col=sp and (can_pay_special(sp) and 3 or 2) or 5
  if fire_denied_t>0 and (fire_denied_t%2==0) then sp_col=8 end
  print("\151"..sp_txt,1,122,sp_col)
  if salvage>0 then print("s"..salvage,42,122,10) end
  if state~='boss_play' then
   local sel=sel_target()
   print(sel and ">"..sel.label or "no tgt",54,122,sel and 7 or 5)
  end
  print("sc"..score,98,122,7)
 end
end

function draw_title()
 cls(0) draw_stars() draw_earth_system() draw_moon_system()
 print_center("lunar defense",20,7)
 print_center("earth approaches the line",38,8)
 print_center("\142 begin briefing",86,11)
 print_center("\151 field manual",98,3)
 if dev_mode then
  print_center("[dev] \131 skip to boss",112,13)
 end
end

function draw_help()
 cls(0) draw_stars() draw_earth_system() draw_moon_system()
 rectfill(6,14,122,110,0) rect(6,14,122,110,6)
 print("field manual  "..help_page.."/5",28,18,7)
 if help_page==1 then
  print("controls",46,30,11)
  print("\139\145  select target",14,44,12)
  print("\142  fire / confirm",14,56,11)
  print("\151  switch weapon",14,68,3)
  print("enter pause",14,80,6)
 elseif help_page==2 then
  print("enemy glossary",34,30,11)
  -- raider icon + label
  circfill(14,46,1,8) pset(16,46,8) pset(18,46,8)
  print("raider    fast strike",22,44,7)
  -- wrecker icon
  circfill(14,58,2,10) pset(17,58,8) pset(11,58,9)
  print("wrecker   heavy hit",22,56,7)
  -- sapper icon (orbiter)
  circfill(14,70,2,12) circ(14,70,3,1)
  print("sapper    orbits first",22,68,7)
  -- decoy icon
  pset(13,82,5) pset(14,82,5) pset(15,82,5) pset(14,81,5) pset(14,83,5)
  print("decoy     no damage",22,80,6)
 elseif help_page==3 then
  print("weapons \174 economy",26,30,11)
  print("intcpt  auto defense",12,42,12)
  print("sling   aim at modules",12,52,6)
  print("chunk   late heavy hit",12,62,8)
  print("salvage fuels charges",10,74,10)
  print("tug auto-grabs debris",6,84,6)
 elseif help_page==4 then
  print("upgrades 1/2",36,30,11)
  local list={'fast_reload','reserve_tanks','patch_crews','recycler','point_defense'}
  for i=1,#list do
   local m=upgrade_meta[list[i]]
   local y=40+(i-1)*12
   print(m.label,10,y,12)
   print(m.desc,10,y+6,6)
  end
 else
  print("upgrades 2/2",36,30,11)
  local list={'refinery','mass_driver','lunar_shielding','pulse_array'}
  for i=1,#list do
   local m=upgrade_meta[list[i]]
   local y=42+(i-1)*14
   print(m.label,10,y,12)
   print(m.desc,10,y+6,6)
  end
 end
 print("\151 next  \142 start",20,100,10)
end

function draw_brief()
 cls(0) draw_stars() draw_earth_system() draw_moon_system()
 rectfill(8,30,120,94,0) rect(8,30,120,94,1)
 if brief_page==1 then
  print_center("lunar defense command",36,8)
  print_center("earth refused withdrawal",54,6)
  print_center("counterforce approved",66,12)
 else
  print_center("directive",36,11)
  print_center("open with defensive salvo",50,7)
  print_center("silence the ring",62,12)
  print_center("hold the moon",74,10)
 end
 print_center("\142 continue",88,6)
end

function draw_intermission()
 cls(0) draw_stars() draw_earth_system() draw_moon_system()
 rectfill(12,20,116,108,0) rect(12,20,116,108,6)
 print("packet clear",32,26,11) print("choose upgrade",26,36,7)
 if #inter.opts==0 then print("\142 continue",34,74,7)
 else
  for i=1,#inter.opts do
   local lab=upg_label(inter.opts[i])
   print((i==inter.oi and ">" or " ")..lab,20,48+i*10,i==inter.oi and 7 or 5)
  end
  print("\131\140 select  \142 ok",18,96,6)
 end
end

function draw_result()
 cls(0) draw_stars()
 -- earth only if it's still there (moon loss case, earth not yet destroyed)
 if earth_core_hp>0 then draw_earth_system() end
 if moon_int<=0 then
  -- moon is broken: show drifting shards where the moon was
  draw_moon_shards()
 else
  draw_moon_system()
 end
 local msg,mc
 if moon_int<=0 then msg="moon lost" mc=8
 elseif boss_defeated then msg="earth silenced" mc=11
 else msg="mission clear" mc=11 end
 print_center(msg,34,mc)
 print_center("score "..score,50,7)
 print_center("salvage "..salvage,60,10)
 print_center("\142/\151 title",102,7)
end

-- =============================================================
-- boss phase: post-earth final fight. separate control scheme
-- and isolated update/draw pipeline.
-- =============================================================

function init_boss_phase()
 -- clear old combat systems (no more earth war running in bg)
 contacts={} interceptors={} heavies={} bombs={}
 debris={} tug=nil inter=nil aim=nil
 -- moon integrity, charge, and upgrades carry over from the main game
 -- (dev mode starts from reset_run defaults, which is fine)
 -- boss orbits the moon; start angle = direction of earth's death position
 local dx=earth_x-moon_x
 local dy=earth_y-moon_y
 local start_theta=atan2(dx,dy)
 local init_omega=0.0011
 local orbit_r=52
 -- initialize prev position one frame back so delta-based forward is valid on frame 1
 local prev_theta=start_theta-init_omega
 boss={
  theta=start_theta,
  omega=init_omega,         -- current orbital speed (turns/frame) — slow cruise
  target_omega=init_omega,  -- drifts toward this
  cruise_omega=init_omega,  -- default speed to return to after dodge
  orbit_r=orbit_r,
  x=moon_x+cos(start_theta)*orbit_r,
  y=moon_y+sin(start_theta)*orbit_r,
  prev_x=moon_x+cos(prev_theta)*orbit_r,
  prev_y=moon_y+sin(prev_theta)*orbit_r,
  fwx=1, fwy=0,
  hp=15, max_hp=15,
  hit_flash=0, invuln_t=0, dodge_lock_t=0, dodge_t=0,
  fire_t=40,                -- initial delay before first salvo
  salvo_i=0, salvo_t=0, salvo_pattern=1, salvo_count=0,
  thrust_t=0,               -- extra thrust burn frames after correction/dodge
  turn_t=0,                 -- time since last direction change
  reveal=0,                 -- 0..1 fade-in factor
  dying=false, dying_t=0,
  damage={}                 -- list of {u,v} crack marks in ship-local coords
 }
 -- two curved arc shields orbiting the moon; each ~0.055 of a full turn wide
 shield_a={theta=0.75,arc=0.055,spd=0.006,col=12}
 shield_b={theta=0.25,arc=0.055,spd=0.006,col=12}
 -- deploy beat: shields animate outward over ~24 frames at fight start
 shield_deploy_t=24
 boss_shots={}
 boss_pattern_i=1
 boss_fire_cd=0
 boss_hint_t=240
 -- ensure the boss-phase weapons are available regardless of entry path
 unlocked_specials.sling=true
 unlocked_specials.moon_chunk=true
 -- lock player weapon to sling at start of boss phase
 set_special('sling')
 aim=nil
 boss_text_human={
  "incoming transmission...",
  "origin: earth civil defense",
  "",
  "darn you clankers!",
  "long live earth.",
  "long live humanity."
 }
 boss_text_machine={
  "",
  "transmission received.",
  "defense authorized."
 }
 boss_text=boss_text_human
 audio_voice_chars=0
 audio_voice_phase=0
 boss_intro_t=0
 boss_phase_started=true
 state='boss_intro'
end

function update_boss_intro()
 boss_intro_t+=1
 -- let the earth halves keep drifting
 for h in all(earth_halves) do
  h.x+=h.vx h.y+=h.vy h.vy+=0.0015
  h.rot+=h.rspd h.age+=1
 end
 -- fade fx
 for f in all(fx) do
  if f.kind=='smoke' then f.ex+=f.vx or 0 f.ey+=f.vy or 0 end
  f.t-=1
  if f.t<=0 then del(fx,f) end
 end
 -- fade-in curve (0..1 from t=30 to t=160)
 if boss_intro_t<30 then boss.reveal=0
 elseif boss_intro_t<160 then boss.reveal=(boss_intro_t-30)/130
 else boss.reveal=1 end
 -- boss drifts onto its orbit, already moving
 boss.prev_x=boss.x boss.prev_y=boss.y
 boss.theta=(boss.theta+boss.omega)%1
 boss.x=moon_x+cos(boss.theta)*boss.orbit_r
 boss.y=moon_y+sin(boss.theta)*boss.orbit_r
 -- compute stable forward vector so the cutscene ship has the same
 -- orientation as the in-fight ship
 local eps=0.0008
 local ex1=moon_x+cos(boss.theta-eps)*boss.orbit_r
 local ey1=moon_y+sin(boss.theta-eps)*boss.orbit_r
 local ex2=moon_x+cos(boss.theta+eps)*boss.orbit_r
 local ey2=moon_y+sin(boss.theta+eps)*boss.orbit_r
 local tdx=ex2-ex1 local tdy=ey2-ey1
 local tdl=sqrt(tdx*tdx+tdy*tdy)
 if tdl>0.001 then
  local s=(boss.omega>=0) and 1 or -1
  boss.fwx=tdx/tdl*s
  boss.fwy=tdy/tdl*s
 end
 -- proceed to fight once transmission has been visible long enough
 if boss_intro_t>=220 then
  earth_halves={}   -- clear the halves when the fight actually starts
  state='boss_play'
 end
 -- skip key for dev
 if dev_mode and btnp(4) then
  earth_halves={}
  boss.reveal=1
  state='boss_play'
 end
end

function draw_boss_intro()
 cls(0) draw_stars()
 -- drifting earth halves fade out as the transmission plays
 local show_halves=true
 if boss_intro_t>=180 then show_halves=false
 elseif boss_intro_t>=140 then show_halves=(boss_intro_t%3==0)
 elseif boss_intro_t>=90 then show_halves=(boss_intro_t%2==0)
 end
 if show_halves then
  for h in all(earth_halves) do draw_earth_half(h) end
 end
 draw_moon_system()
 -- boss silhouette emerging
 draw_boss()
 draw_comm_panel()
 draw_fx()
end

-- ----- boss combat -----

function update_boss_play()
 if btnp(6) then paused=not paused end
 if paused then return end
 if aim then
  -- aim mode: same controls as main game
  if btnp(0) then aim.cx-=4 end
  if btnp(1) then aim.cx+=4 end
  if btnp(2) then aim.cy-=10 end
  if btnp(3) then aim.cy+=10 end
  aim.cx=mid(2,aim.cx,126)
  aim.cy=mid(2,aim.cy,126)
  aim.ang=atan2(aim.cx-moon_x,aim.cy-moon_y)
  if btnp(4) then fire_aimed() end
  if btnp(5) then aim=nil end
 else
  -- shields use held input (d-pad rotates arcs around the moon)
  if btn(0) then shield_a.theta=(shield_a.theta-shield_a.spd)%1 end
  if btn(1) then shield_a.theta=(shield_a.theta+shield_a.spd)%1 end
  if btn(2) then shield_b.theta=(shield_b.theta-shield_b.spd)%1 end
  if btn(3) then shield_b.theta=(shield_b.theta+shield_b.spd)%1 end
  -- weapon toggle: sling <-> chunk
  if btnp(5) then
   local sp=current_special()
   if sp and sp.id=='sling' then set_special('moon_chunk')
   else set_special('sling') end
  end
  -- z enters aim at the boss
  if btnp(4) then
   enter_aim({type='boss',id='boss',ref=boss,label='ship'})
  end
 end
 -- heavies (slings, chunks) tick normally; boss collision added in upd_heavies
 upd_heavies()
 upd_charge_regen()
 -- boss ai + projectiles (skip ai spawning while dying)
 if not boss.dying then update_boss_ai() end
 update_boss_shots()
 -- fx tick
 for f in all(fx) do
  if f.kind=='smoke' then f.ex+=f.vx or 0 f.ey+=f.vy or 0 end
  f.t-=1
  if f.t<=0 then del(fx,f) end
 end
 -- timers
 if boss.hit_flash>0 then boss.hit_flash-=1 end
 if boss.dodge_lock_t>0 then boss.dodge_lock_t-=1 end
 if boss.invuln_t>0 then boss.invuln_t-=1 end
 if boss_hint_t>0 then boss_hint_t-=1 end
 if shield_deploy_t>0 then shield_deploy_t-=1 end
 if fire_denied_t>0 then fire_denied_t-=1 end
 -- death routing
 if moon_int<=0 then
  moon_fall_t=0 moon_cracks={} moon_shards={}
  result_mode='moon_lost'
  sfx(12)
  state='moon_fall' return
 end
 if boss.hp<=0 and not boss.dying then
  boss.dying=true boss.dying_t=0
  -- first big blast
  add(fx,{kind='explosion',x=boss.x,y=boss.y,t=30,mt=30})
  add(fx,{kind='explosion',x=boss.x,y=boss.y,t=24,mt=24})
  sfx(7)
  audio_big_boom('hero')
  -- eject debris chunks from the hull in all directions
  for i=1,16 do
   local a=i/16+rnd(0.04)
   local sp=0.4+rnd(0.6)
   add(bombs,{
    boss_debris=true,
    x=boss.x+(rnd(1)-0.5)*6,
    y=boss.y+(rnd(1)-0.5)*6,
    vx=cos(a)*sp,vy=sin(a)*sp,
    ttl=120+flr(rnd(40)),
    col=(i%3==0 and 9 or (i%3==1 and 8 or 5)),
    sz=1+flr(rnd(2))
   })
  end
 end
 if boss.dying then
  boss.dying_t+=1
  -- rolling chain of explosions along the hull during death
  if boss.dying_t%5==0 then
   local dx=(rnd(1)-0.5)*18
   local dy=(rnd(1)-0.5)*10
   add(fx,{kind='explosion',x=boss.x+dx,y=boss.y+dy,t=16+flr(rnd(12)),mt=26})
  end
  -- bright chain flashes every 15 frames
  if boss.dying_t%15==0 then
   add(fx,{kind='explosion',x=boss.x,y=boss.y,t=22,mt=22})
   -- small explosions radiating from the boss (absolute coords, not earth-relative)
   for j=1,4 do
    local a=rnd(1)
    add(fx,{kind='explosion',x=boss.x+cos(a)*6,y=boss.y+sin(a)*6,t=12,mt=12})
   end
   sfx(6)
   audio_big_boom('tail')
  end
  -- update boss debris particles
  for b in all(bombs) do
   if b.boss_debris then
    b.x+=b.vx b.y+=b.vy
    b.vx*=0.98 b.vy*=0.98
    b.ttl-=1
    if b.ttl<=0 then del(bombs,b) end
   end
  end
  -- coast: keep drifting, slowing down
  boss.omega*=0.96
  boss.theta=(boss.theta+boss.omega)%1
  boss.x=moon_x+cos(boss.theta)*boss.orbit_r
  boss.y=moon_y+sin(boss.theta)*boss.orbit_r
  -- final blast at t=120 (2 seconds in)
  if boss.dying_t==120 then
   for i=1,6 do
    add(fx,{kind='explosion',x=boss.x+(rnd(1)-0.5)*8,y=boss.y+(rnd(1)-0.5)*8,t=36,mt=36})
   end
   sfx(7)
   audio_big_boom('hero')
  end
  -- afterglow fade, then transition
  if boss.dying_t>=170 then
   boss_defeated=true
   result_mode='boss_win'
   state='result'
  end
 end
 gtick+=1
end

function update_boss_ai()
 -- orbit motion: boss theta advances toward target_omega with smooth lerp
 boss.omega=lerp(boss.omega,boss.target_omega,0.05)
 boss.prev_x=boss.x boss.prev_y=boss.y
 boss.theta=(boss.theta+boss.omega)%1
 boss.x=moon_x+cos(boss.theta)*boss.orbit_r
 boss.y=moon_y+sin(boss.theta)*boss.orbit_r
 -- stable forward vector from orbit tangent (not frame-to-frame delta, which
 -- jitters during direction changes). sampled empirically to dodge the PICO-8
 -- inverted-sin quirk.
 local eps=0.0008
 local ex1=moon_x+cos(boss.theta-eps)*boss.orbit_r
 local ey1=moon_y+sin(boss.theta-eps)*boss.orbit_r
 local ex2=moon_x+cos(boss.theta+eps)*boss.orbit_r
 local ey2=moon_y+sin(boss.theta+eps)*boss.orbit_r
 local tdx=ex2-ex1 local tdy=ey2-ey1
 local tdl=sqrt(tdx*tdx+tdy*tdy)
 if tdl>0.001 then
  local s=(boss.omega>=0) and 1 or -1
  boss.fwx=tdx/tdl*s
  boss.fwy=tdy/tdl*s
 end
 -- thrust burn fades
 if boss.thrust_t>0 then boss.thrust_t-=1 end
 -- dodge timer: after dodge expires, ease target back to cruise
 if boss.dodge_t>0 then
  boss.dodge_t-=1
  if boss.dodge_t==0 then
   -- preserve sign of omega, return to cruise speed magnitude
   local sgn=(boss.target_omega>=0) and 1 or -1
   boss.target_omega=sgn*boss.cruise_omega
  end
 end
 -- occasional direction change (adds unpredictability + visible thrusters)
 boss.turn_t+=1
 if boss.dodge_t<=0 and boss.turn_t>260+flr(rnd(160)) then
  -- flip direction at cruise speed
  local sgn=(boss.target_omega>=0) and -1 or 1
  boss.target_omega=sgn*boss.cruise_omega
  boss.thrust_t=28
  boss.turn_t=0
 end
 -- fire cadence: long lulls between salvos
 if boss.salvo_count>0 then
  -- firing a salvo: stagger shots within
  boss.salvo_t-=1
  if boss.salvo_t<=0 and boss.salvo_i<boss.salvo_count then
   spawn_boss_shot(boss.salvo_pattern,boss.salvo_i)
   boss.salvo_i+=1
   boss.salvo_t=16+flr(rnd(6))
  end
  if boss.salvo_i>=boss.salvo_count and boss.salvo_t<=0 then
   boss.salvo_count=0
   boss.fire_t=90+flr(rnd(45))    -- lull between salvos
  end
 else
  boss.fire_t-=1
  if boss.fire_t<=0 then
   boss.salvo_pattern=boss_pattern_i
   boss.salvo_count=4              -- one shot per cannon
   boss.salvo_i=0
   boss.salvo_t=0
   boss_pattern_i=(boss_pattern_i%3)+1
  end
 end
 -- chunk dodge (can nudge omega to accelerate/reverse)
 boss_try_dodge()
end

function boss_try_dodge()
 if boss.dodge_lock_t>0 then return end
 local best_d=99999
 local best_heavy=nil
 for s in all(heavies) do
  if s.straight and not s.opener and not s.dodged then
   for i=1,60 do
    local px=s.x+s.vx*i
    local py=s.y+s.vy*i
    local th=boss.theta+boss.omega*i
    local bx=moon_x+cos(th)*boss.orbit_r
    local by=moon_y+sin(th)*boss.orbit_r
    local dd=d2(px,py,bx,by)
    if dd<best_d then
     best_d=dd best_heavy=s
    end
   end
  end
 end
 -- dodge if the predicted closest approach is within 18 px
 if best_d<324 and best_heavy then
  -- mark this shot so it can't trigger another dodge later
  best_heavy.dodged=true
  -- always reverse direction: most visible "get out of the way" motion
  local cur_sgn=(boss.target_omega>=0) and 1 or -1
  local sgn=-cur_sgn
  local dodge_speed=0.0038
  -- instant initial jolt so the direction change is visible immediately,
  -- then lerp toward full dodge speed
  boss.omega=sgn*0.002
  boss.target_omega=sgn*dodge_speed
  boss.thrust_t=48
  boss.dodge_lock_t=10
  boss.dodge_t=60
 end
end

-- cannonball-style boss shots: each of 4 cannons fires one projectile per salvo
-- cannons line the moon-facing edge of the hull. u = along ship tangent,
-- v = offset toward moon (always positive = inward from ship centerline).
boss_cannon_pos={
 {u=-5,v=3},
 {u=-2,v=3},
 {u= 2,v=3},
 {u= 5,v=3},
}

function spawn_boss_shot(pattern,index)
 -- resolve cannon local position -> world.
 -- u axis is the ship's tangent (forward); v axis is the unit vector from
 -- boss toward moon (so v>0 is always on the moon-facing side regardless
 -- of where the boss is on its orbit).
 local cannon=boss_cannon_pos[((index-1)%4)+1]
 local fwx=boss.fwx or 1 local fwy=boss.fwy or 0
 local tmx=moon_x-boss.x local tmy=moon_y-boss.y
 local tml=sqrt(tmx*tmx+tmy*tmy)
 if tml<0.1 then tml=1 end
 tmx/=tml tmy/=tml
 local wx=boss.x+cannon.u*fwx+cannon.v*tmx
 local wy=boss.y+cannon.u*fwy+cannon.v*tmy
 -- each cannon aims with a different angular offset so shots fan across the moon
 local tx=moon_x-wx
 local ty=moon_y-wy
 local ang=atan2(tx,ty)
 local off
 if index==1 then
  -- first shot always goes straight at the moon
  off=0
 elseif pattern==1 then
  -- flanking fan (wider than before)
  off=(index-2.5)*0.11              -- -0.165 .. +0.165
 elseif pattern==2 then
  -- hard flanks: shots pushed well to the sides
  off=((index%2==0) and 0.19 or -0.19)+(rnd(0.05)-0.025)
 else
  -- rolling broadside
  off=(index-2.5)*0.14
 end
 local shoot_ang=ang+off
 local speed=0.45+rnd(0.08)
 add(boss_shots,{
  physics=true,
  x=wx, y=wy,
  cannon_u=cannon.u, cannon_v=cannon.v,  -- so telegraph stays at the cannon
  vx=cos(shoot_ang)*speed,
  vy=sin(shoot_ang)*speed,
  dmg=2,
  ttl=180,
  tel_t=20,
  age=0,
  trail={}
 })
end

function update_boss_shots()
 for s in all(boss_shots) do
  if s.tel_t and s.tel_t>0 then
   s.tel_t-=1
   -- keep the telegraph glued to the cannon on the moving ship
   if s.cannon_u and boss.fwx then
    local tmx=moon_x-boss.x local tmy=moon_y-boss.y
    local tml=sqrt(tmx*tmx+tmy*tmy)
    if tml<0.1 then tml=1 end
    tmx/=tml tmy/=tml
    s.x=boss.x+s.cannon_u*boss.fwx+s.cannon_v*tmx
    s.y=boss.y+s.cannon_u*boss.fwy+s.cannon_v*tmy
   else
    s.x=boss.x s.y=boss.y
   end
   -- spawn a muzzle flash on the frame the shot launches
   if s.tel_t==0 then
    add(fx,{kind='muzzle',x=s.x,y=s.y,t=10,mt=10})
    sfx(14)
   end
  else
   -- physics: moon gravity pulls the shot (inverse square, capped)
   local dx=moon_x-s.x local dy=moon_y-s.y
   local dm2=dx*dx+dy*dy
   local d=sqrt(dm2)
   if d<1 then d=1 end
   local g=min(0.12,20/dm2)
   s.vx+=dx/d*g s.vy+=dy/d*g
   -- light drag: just enough to prevent perfect orbits
   s.vx*=0.997
   s.vy*=0.997
   -- short trail
   add(s.trail,{x=s.x,y=s.y})
   if #s.trail>3 then del(s.trail,s.trail[1]) end
   s.x+=s.vx s.y+=s.vy
   s.ttl=(s.ttl or 180)-1
   s.age=(s.age or 0)+1
   if boss_shot_hits_shield(s) then
    add(fx,{kind='block',x=s.x,y=s.y,t=14,mt=14})
    sfx(5)
    del(boss_shots,s)
   elseif dm2<=(moon_r+1)*(moon_r+1) then
    local ix,iy=s.x,s.y
    if d>0.01 then
     ix=moon_x-dx/d*(moon_r+1)
     iy=moon_y-dy/d*(moon_r+1)
    end
    moon_int=max(0,moon_int-(s.dmg or 1))
    add(fx,{kind='explosion',x=ix,y=iy,t=18,mt=18})
    add(fx,{kind='impact',x=ix,y=iy,t=20,mt=20})
    add_moon_crater(ix,iy,1)
    sfx(8)
    del(boss_shots,s)
   elseif s.ttl<=0 or s.x<-12 or s.x>139 or s.y<-12 or s.y>139 then
    del(boss_shots,s)
   end
  end
 end
end

-- arc shield collision: shot blocked if its angle from moon is inside either
-- shield arc and its radial distance is near the shield ring
function boss_shot_hits_shield(s)
 local dx=s.x-moon_x local dy=s.y-moon_y
 local rr=sqrt(dx*dx+dy*dy)
 if rr<shield_r-3 or rr>shield_r+3 then return false end
 local sa=atan2(dx,dy)
 for sh in all({shield_a,shield_b}) do
  local diff=(sa-sh.theta+0.5)%1-0.5
  if abs(diff)<sh.arc then return true end
 end
 return false
end

function boss_take_hit(dmg,kind)
 if boss.invuln_t>0 or boss.dying then return end
 boss.hp=max(0,boss.hp-dmg)
 boss.hit_flash=6
 boss.invuln_t=2
 sfx(9)
 -- leave visible cracks on the hull
 local marks=1+dmg
 for i=1,marks do
  add(boss.damage,{
   u=(rnd(1)-0.5)*14,
   v=(rnd(1)-0.5)*5,
   sz=(kind=='moon_chunk') and 1 or 0
  })
 end
end

-- ----- boss draw -----

function draw_boss_play()
 cls(0) draw_stars()
 draw_moon_system()
 draw_shields()
 draw_heavies()
 -- hide the ship itself in the late stage of the death sequence
 if not boss.dying or boss.dying_t<120 then
  draw_boss()
 end
 -- draw boss debris chunks if dying
 if boss.dying then
  for b in all(bombs) do
   if b.boss_debris then
    local lf=b.ttl/160
    local col=b.col
    if lf<0.3 then col=5 end
    if b.sz>=2 then
     circfill(b.x,b.y,1,col)
     pset(b.x-b.vx,b.y-b.vy,5)
    else
     pset(b.x,b.y,col)
    end
   end
  end
  -- screen-edge flash on the big final blast
  if boss.dying_t>=120 and boss.dying_t<140 then
   local ff=1-(boss.dying_t-120)/20
   if ff>0.6 then
    rectfill(0,0,127,127,7)
   elseif ff>0.3 then
    rect(0,0,127,127,10) rect(1,1,126,126,9)
   end
  end
 end
 draw_boss_shots()
 draw_aim_preview()
 draw_fx()
 draw_hud()
 draw_weapon_border()
 if paused then
  rectfill(16,36,112,92,0) rect(16,36,112,92,6)
  print_center("paused",40,7)
  print_center("defend the moon",52,6)
 end
end

-- draw one curved arc shield orbiting the moon
function draw_arc_shield(sh)
 -- deploy beat: during the first 24 frames the shields rise out of the moon
 local dep=1
 if shield_deploy_t>0 then dep=1-(shield_deploy_t/24) end
 local rmid=moon_r+1+(shield_r-moon_r-1)*dep
 local arc=sh.arc*dep
 local n=14
 for i=0,n do
  local f=(i/n-0.5)*2   -- -1..1 across the arc
  local a=sh.theta+f*arc
  local ri=rmid-1
  local ro=rmid+1
  local cx=cos(a) local sy=sin(a)
  local xi=moon_x+cx*ri local yi=moon_y+sy*ri
  local xo=moon_x+cx*ro local yo=moon_y+sy*ro
  -- center line (bright)
  local xm=moon_x+cx*rmid
  local ym=moon_y+sy*rmid
  pset(xm,ym,7)
  pset(xi,yi,sh.col)
  pset(xo,yo,sh.col)
 end
 -- bright end caps (only once the arc has opened)
 if dep>0.3 then
  local af=sh.theta-arc
  local ab=sh.theta+arc
  pset(moon_x+cos(af)*rmid,moon_y+sin(af)*rmid,12)
  pset(moon_x+cos(ab)*rmid,moon_y+sin(ab)*rmid,12)
 end
end

function draw_shields()
 draw_arc_shield(shield_a)
 draw_arc_shield(shield_b)
end

function draw_boss()
 if not boss then return end
 local rv=boss.reveal or 1
 if rv<=0 then return end
 local stipple=(rv<1)
 local function rvpset(x,y,c)
  if stipple then
   local k=(flr(x)+flr(y)+flr(boss_intro_t*0.5))%10
   if k>=flr(rv*10) then return end
  end
  pset(x,y,c)
 end
 -- use stable orbit-tangent forward vector (updated in update_boss_ai)
 local fwx=boss.fwx or 1
 local fwy=boss.fwy or 0
 -- motion magnitude (for thruster length, not for forward direction)
 local mdx=boss.x-boss.prev_x
 local mdy=boss.y-boss.prev_y
 local mdl=sqrt(mdx*mdx+mdy*mdy)
 -- perpendicular (rotate forward 90° CCW for local "up")
 local pxd=-fwy local pyd=fwx
 -- local (u,v) to screen: u along forward, v perpendicular
 local function bp(u,v)
  return boss.x+u*fwx+v*pxd, boss.y+u*fwy+v*pyd
 end
 -- hull colors pulse on hit
 local hc=(boss.hit_flash>0) and 8 or 13
 local hl=(boss.hit_flash>0) and 14 or 6
 local hd=(boss.hit_flash>0) and 2 or 1
 -- symmetric rectangular hull
 for u=-7,7 do
  for v=-2,2 do
   local c=hc
   if v==-2 or v==2 then c=hl end
   if u==-7 or u==7 then c=hd end
   local px,py=bp(u,v)
   rvpset(px,py,c)
  end
 end
 -- engine nozzles stick out on BOTH ends, symmetric
 for v=-1,1 do
  local lx,ly=bp(-9,v)  rvpset(lx,ly,hd)
  local rx,ry=bp( 9,v)  rvpset(rx,ry,hd)
 end
 local lx2,ly2=bp(-8,0) rvpset(lx2,ly2,5)
 local rx2,ry2=bp( 8,0) rvpset(rx2,ry2,5)
 -- mirror-symmetric top/bottom pods
 for u=-2,2 do
  local au,av=bp(u,-3) rvpset(au,av,6)
  local bu,bv=bp(u, 3) rvpset(bu,bv,6)
 end
 local tcu,tcv=bp(0,-3) rvpset(tcu,tcv,7)
 local bcu,bcv=bp(0, 3) rvpset(bcu,bcv,7)
 -- visible damage marks (black cracks in ship-local coords)
 for d in all(boss.damage) do
  local du,dv=bp(d.u,d.v)
  pset(du,dv,0)
  if d.sz>=1 then
   local da,db=bp(d.u+0.5,d.v)
   pset(da,db,0)
   local dc,dd2=bp(d.u,d.v+0.5)
   pset(dc,dd2,0)
  end
 end
 -- thrusters: REAR is at u=-9 (opposite of forward/motion). flame extends
 -- further in the -u direction = behind the ship.
 -- base burn length scales with actual motion; capped so it never dominates
 local spd_f=min(1,mdl*40)
 local base_len=1+flr(spd_f*1.5)
 local boost=(boss.thrust_t>0) and flr(boss.thrust_t/12) or 0
 local burn_len=min(5,base_len+boost)
 for i=1,burn_len do
  local bu=-9-i
  local bx,by=bp(bu,0)
  local c=i<=1 and 10 or (i<=burn_len-1 and 9 or 8)
  rvpset(bx,by,c)
  if i<=min(2,burn_len-1) then
   local ba_x,ba_y=bp(bu,-1)
   local bb_x,bb_y=bp(bu, 1)
   rvpset(ba_x,ba_y,9)
   rvpset(bb_x,bb_y,9)
  end
 end
 -- white-hot core at the nozzle mouth while boosting
 if boss.thrust_t>8 then
  local cu,cv=bp(-9,0)
  rvpset(cu,cv,7)
 end
end

function draw_boss_shots()
 for s in all(boss_shots) do
  if s.tel_t and s.tel_t>0 then
   -- pre-launch cannon charge-up: small building glow
   if (s.tel_t%3)<2 then
    pset(s.x,s.y,9)
   end
  else
   local age=s.age or 0
   -- bright yellow launch tail for the first ~12 frames, then fades
   if s.trail and age<20 then
    local n=#s.trail
    for i=1,n do
     local tp=s.trail[i]
     local k=i/n
     local c
     if age<6 then
      -- fresh launch: bright yellow tapering to orange
      if k<0.3 then c=9
      elseif k<0.7 then c=10
      else c=7 end
     elseif age<12 then
      -- fading: yellow-orange to gray
      if k<0.4 then c=5
      elseif k<0.75 then c=9
      else c=10 end
     else
      -- tail fully faded to gray smoke
      if k<0.5 then c=5 else c=6 end
     end
     pset(tp.x,tp.y,c)
    end
   end
   -- projectile core: 2x2 solid square for visibility
   local cc
   if age<6 then cc=10                    -- bright yellow
   elseif age<16 then cc=9                 -- orange
   elseif age<45 then cc=8                 -- red (settled cannonball)
   else cc=13 end                          -- cooled to purplish-gray
   rectfill(s.x-1,s.y-1,s.x,s.y,cc)
   -- hot pixel in the center for extra readability
   if age<10 then pset(s.x,s.y,7) end
  end
 end
end

function draw_boss_hud()
 -- moon hp (bottom-left)
 print("moon "..moon_int.."/"..moon_max,4,122,6)
 -- charge (bottom-center)
 print("chg "..charge.."/"..max_charge,48,122,11)
 -- weapon label (bottom-right)
 local sp=current_special()
 local lab=sp and sp.label or "sling"
 local wc=(sp and sp.col) or 6
 print(lab,100,122,wc)
end

function _init()
 gen_stars() gen_moon_craters() upd_earth_orbit() start_packet(1) state='title'
 audio_boot()
 music(0,500)
end

function _update()
 if state=='title' then update_title()
 elseif state=='help' then update_help()
 elseif state=='brief' then update_brief()
 elseif state=='play' then update_play()
 elseif state=='inter' then update_intermission()
 elseif state=='earth_fall' then update_earth_fall()
 elseif state=='boss_intro' then update_boss_intro()
 elseif state=='boss_play' then update_boss_play()
 elseif state=='moon_fall' then update_moon_fall()
 elseif state=='result' then
  upd_earth_orbit() upd_mods()
  -- keep moon shards drifting gently if the moon was broken
  if moon_int<=0 then
   for s in all(moon_shards) do
    s.x+=s.vx s.y+=s.vy
    s.rot+=s.rspd
    s.age+=1
    -- wrap shards that drift off-screen so they stay visible
    if s.x<-4 then s.x=131 end
    if s.x>131 then s.x=-4 end
    if s.y<-4 then s.y=131 end
    if s.y>131 then s.y=-4 end
   end
  end
  if btnp(4) or btnp(5) then
   music(0,500)
   state='title'
  end
 end
 audio_update()
end

function _draw()
 if state=='title' then draw_title()
 elseif state=='help' then draw_help()
 elseif state=='brief' then draw_brief()
 elseif state=='play' then
  cls(0) draw_stars() draw_earth_system() draw_moon_system()
  draw_contacts() draw_interceptors() draw_heavies()
  draw_bombs() draw_debris() draw_tug() draw_aim_preview() draw_fx() draw_hud()
  draw_weapon_border()
  if paused then
   rectfill(16,36,112,92,0) rect(16,36,112,92,6)
   print("paused",48,40,7)
   print("\139\145 cycle target",24,52,12)
   print("\142 act on target",22,62,11)
   print("\151 switch weapon",24,72,3)
   print("aim to strike earth",18,82,6)
  end
 elseif state=='inter' then draw_intermission()
 elseif state=='earth_fall' then draw_earth_fall()
 elseif state=='boss_intro' then draw_boss_intro()
 elseif state=='boss_play' then draw_boss_play()
 elseif state=='moon_fall' then draw_moon_fall()
 elseif state=='result' then draw_result()
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000000a9a00000ccc000000500000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008880000a999a000c050c000050500000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0880880009aaa9000c5c5c00050005000b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008880000a999a000c050c000050500000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000000a9a00000ccc000000500000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400001035018350203402833000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002064314625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000866004650026400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002815030150341400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001865014650106400c63000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003005038050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002066314653086450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0014000015670106700c6730966304653000730007000070000600006000050000550004500045000350002500025000150000000000000000000000000000000000000000000000000000000000000000000000
000500001866010653086350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000301502c153201350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002844034445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000102400c245000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000216701c6701867315673106730c6630967000070096600007009660000600965000060000600006000050000500005000055000450004500035000350002500025000150001500000000000000000000
000200003024120235000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001065308053040350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000184501c4501f4502445024445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00140000090400000010040000000904000000100400000005040000000c0400000005040000000c040000000c0400000013040000000c04000000130400000007040000000e0400000007040000000e04000000
0014000018520000001c5200000018520000001c5200000015520000001852000000155200000018520000001c520000001f520000001c520000001f5200000017520000001a5200000017520000001a52000000
001400001c450000002145000000244500000021450000001d450000002145000000244500000021450000001c450000001f4500000024450000001f450000001a450000001f4500000023450000001f45000000
001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00140000090400000010040000000904000000100400000005040000000c0400000005040000000c040000000c0400000010040000000c04000000100400000004040000000b0400000004040000000b04000000
0014000018520000001c5200000018520000001c5200000015520000001852000000155200000018520000001c520000001f520000001c520000001f520000001452000000175200000014520000001752000000
001400001c4501f45021450244502845024450214501f4501d450214502445028450294502845024450214501f4502345024450284502b4502845024450234502645023450214502045021450234502445023450
0014000000000211200000024120000002812000000241200000021120000002412000000291200000024120000001f120000002412000000281200000024120000001f120000002312000000261200000023120
001400001c450000002145000000244502345021450000001d450000002145000000244502345021450000001c450000001f4500000024450234501f450000001a450000001f4500000023450214501f45000000
001400001c450000001f45021450244500000021450000001d450000001f45021450244500000021450000001c450000001d4501f45024450000001f450000001a450000001d4501f45023450000001f45000000
001400001c450000002145000000244500000021450284501d450000002145000000244500000021450294501c450000001f4500000024450000001f450284501a450000001f4500000023450000001f45000000
0014000021450244502845024450214501f4501c4501f45021450244502945024450214501d450214502445024450284502b4502845024450234501f450234502345026450234502145020450214502345026450
001400001c450244501c45021450244502845024450214501d450244501d45021450244502945024450214501c450244501f45024450284502b45028450244501a450234501a4501f4502345026450234501f450
001400002845024450214501f4501c4501f45021450244502945024450214501f4501d4502145024450284502b4502845024450234501f4502345024450284502645023450214501f4501a4501f4502145023450
0010000009060000000000009050000000000004060000000c0600000000000000000905000000000000000009060000000000009050000000000007060000000c06000000000000000010050000000e05500000
001000001863000000000000000018620000000000000000186300000000000000001862000000000000000018630000000000000000186200000000000000001863000000000000000018620000000000000000
001000000906000000000000000000000090500000004060000000c0600000000000090500000004050000000906000000000000000000000070500000009060000000c060000000000000000000000e05010055
001000001863000000000000000000000000000964300000186200000000000000000000000000096430000018630000000000000000000000000009643000001862000000000000000018630000000965300000
0010000009060000000705000000040600000000000000000c0600000000000090500000000000000000000009060000000000004050000000000007060000000906000000000000000000000000000000000000
001000001863000000000000000018620000000000000000186300000000000000001862000000000000000018630000000000000000186200000000000000001863000000000000000018630000001864000000
0010000009260000000925000000042600925000000042600c2600000009250000000426000000092500000009260000000925000000072600925000000072600c260000000e2500000010260000000e2500c255
001000001864000000186200000018630000000000009643186300000018620000001864000000000000965318640000001862000000186300000000000096431863000000186200000018640000000000009663
0010000009260000000000015250000000000009260000001026000000000000426000000000000925000000092600000000000152500000000000072600000010260000000e250000000c260000000925000000
001000001863000000000001863000000186200000000000186300000000000000000965300000000000000018630000000000018630000001862000000000001863000000000001864009653000000000000000
0010000009260000000925000000042600000009250000000c2600000009250000000426000000072500000009260000000925000000042600000009250000000c260000000e2500000010260000000926300000
00100000186400000018630000001c64000000000000000018630000001c6300965300000000000000000000186400000018630000001c6400000000000000001c64018630096530000000000000001864009653
001000000936009350000000936000000000000436004350000000936000000000000935009360000000935009360093500000009360000000000007360073500000009360000000000010350000000c35009360
001000001c64018620000001863018620000001c64018620000001863018620000001c6401862000000096531c64018620000001863018620000001c64018620000001863018620000001c6501c6401c63009663
0010000009360093500000009360000000000003360033500000009360000000000009350093600000003360093600935000000093600000000000043600735000000093600000000000103600f3500c35009360
001000001c640000001c6301c6200000018630000001c6401c6200000000000186300965300000186201c6401c630000001c6301c6200000018630000001c6401c62000000186301c64009663000001c65009653
001000000936000000093500000007360000000735000000043600000004350000000236000000043500000009360000000935000000073600000007350000000436000000033600000004360000000936300000
001000001c6401c630186201c6401c630186201c6400965300000000001c6400965300000000001c650096631c6401c630186201c6401c630186201c640096531c6501c6401c6301c6401c650096631c65009663
000200000e042114320c0320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000b140091300d1330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001035014340183400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001834015340113450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000207004063000530004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c14110151131511814000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000007300073000700006000060000500004500035000250001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000015670106730c6630965504635006250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000764004740026300073500625007250061500715000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000216701c67015673106730c663096530007000070000700007000070000700006000060000600005000050000550004500045000350003500025000250001500015000000000000000000000000000000
000200001c4301f535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001533018330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 10111213
00 14151617
00 10111813
00 14151b17
00 10111913
00 14151c17
00 10111a13
02 14151d17
00 1e1f4141
00 201f4141
00 1e214141
04 22234141
00 221f4141
00 20234141
00 22214141
04 1e234141
00 24254141
00 26254141
00 24274141
04 28294141
00 26274141
00 28254141
00 28274141
04 24294141
00 2a2b4141
00 2c2b4141
00 2a2d4141
04 2e2f4141
00 2c2d4141
00 2e2b4141
00 2e2d4141
04 2c2f4141
