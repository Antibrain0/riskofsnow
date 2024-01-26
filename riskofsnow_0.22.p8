pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- [initialization]
-- evercore v2.3.0
poke(0x5f2d, 0x1)
function vector(x,y)
	return {x=x,y=y}
end

function rectangle(x,y,w,h)
	return {x=x,y=y,w=w,h=h}
end

--global tables
objects,got_fruit={},{}
--global timers
freeze,delay_restart,sfx_timer,music_timer,ui_timer=0,0,0,0,-99
--global camera values
draw_x,draw_y,cam_x,cam_y,cam_spdx,cam_spdy,cam_gain=0,0,0,0,0,0,0.25
_pal=pal
-- [entry point]

function _init()
	frames,start_game_flash=0,0
	music(40,0,7)
	lvl_id=0
end

function begin_game()
	max_djump=1
	deaths,frames,seconds,minutes,music_timer,time_ticking,fruit_count,bg_col,cloud_col=0,0,0,0,0,true,0,0,1
	music(0,0,7)
	load_level(1)
end

function is_title()
	return lvl_id==0
end

-- [effects]

clouds={}
for i=0,16 do
	add(clouds,{
		x=rnd"128",
		y=rnd"128",
		spd=1+rnd"4",
	w=32+rnd"32"})
end

particles={}
for i=0,24 do
	add(particles,{
		x=rnd"128",
		y=rnd"128",
		s=flr(rnd"1.25"),
		spd=0.25+rnd"5",
		off=rnd(),
		c=6+rnd"2",
	})
end

dead_particles={}

-- [function library]

function psfx(num)
	if sfx_timer<=0 then
		sfx(num)
	end
end

function round(x)
	return flr(x+0.5)
end

function appr(val,target,amount)
	return val>target and max(val-amount,target) or min(val+amount,target)
end

function sign(v)
	return v~=0 and sgn(v) or 0
end

function two_digit_str(x)
	return x<10 and "0"..x or x
end

function tile_at(x,y)
	return mget(lvl_x+x,lvl_y+y)
end

function spikes_at(x1,y1,x2,y2,xspd,yspd)
	for i=max(0,x1\8),min(lvl_w-1,x2/8) do
		for j=max(0,y1\8),min(lvl_h-1,y2/8) do
			if({[57]=y2%8>=6 and yspd>=0,
			[58]=y1%8<=2 and yspd<=0,
			[59]=x1%8<=2 and xspd<=0,
			[60]=x2%8>=6 and xspd>=0})[tile_at(i,j)] then
				return true
			end
		end
	end
end
-->8
-- [update loop]

function _update()
 handle_keypresses()
	frames+=1
	if time_ticking then
		seconds+=frames\30
		minutes+=seconds\60
		seconds%=60
	end
	frames%=30

	if music_timer>0 then
		music_timer-=1
		if music_timer<=0 then
			music(10,0,7)
		end
	end

	if sfx_timer>0 then
		sfx_timer-=1
	end

	-- cancel if freeze
	if freeze>0 then
		freeze-=1
		return
	end

	-- restart (soon)
	if delay_restart>0 then
		cam_spdx,cam_spdy=0,0
		delay_restart-=1
		if delay_restart==0 then
			load_level(lvl_id)
		end
	end

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y,0);
		(obj.type.update or stat)(obj)
	end)

	--move camera to player
	foreach(objects,function(obj)
		if obj.type==player or obj.type==player_spawn then
			move_camera(obj)
		end
	end)

	-- start game
	if is_title() then
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				begin_game()
			end
		elseif btn(🅾️) or btn(❎) then
			music"-1"
			start_game_flash,start_game=50,true
			sfx"38"
		end
	else
	if not healing then
	 hp=flr(hp)
	end
	 spawn_enmys()
  diff+=0.0333
	end
	damaged=false
end
-->8
-- [draw loop]

function _draw()
	if freeze>0 then
		return
	end

	-- reset all palette values
	pal()

	-- start game flash
	if is_title() then
		if start_game then
			for i=1,15 do
				pal(i, start_game_flash<=10 and ceil(max(start_game_flash)/5) or frames%10<5 and 7 or i)
			end
		end

		cls()

		-- credits
		sspr(unpack(split"72,32,56,32,36,32"))
		?"🅾️/❎",55,80,5
		?"maddy thorson",40,96,5
		?"noel berry",46,102,5

		-- particles
		foreach(particles,draw_particle)
	for i in all(key) do
  print(i)
 end
		return
	end

	-- draw bg color
	cls(flash_bg and frames/5 or bg_col)

	-- bg clouds effect
	foreach(clouds,function(c)
		c.x+=c.spd-cam_spdx
		rectfill(c.x,c.y,c.x+c.w,c.y+16-c.w*0.1875,cloud_col)
		if c.x>128 then
			c.x=-c.w
			c.y=rnd"120"
		end
	end)

	--set cam draw position
	draw_x=round(cam_x)-64
	draw_y=round(cam_y)-64
	camera(draw_x,draw_y)

	-- draw bg terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,4)
	
  -- draw outlines
  for i=0,15 do pal(i,1) end
  pal=stat
  foreach(objects,function(o)
    if o.outline!=false then
      for dx=-1,1 do for dy=-1,1 do if dx==0 or dy==0 then
        camera(draw_x+dx,draw_y+dy) draw_object(o)
      end end end
    end
  end)
  pal=_pal
  camera(draw_x,draw_y)
  pal()	
	--set draw layering
	--positive layers draw after player
	--layer 0 draws before player, after terrain
	--negative layers draw before terrain
	local pre_draw,post_draw={},{}
	foreach(objects,function(obj)
		local draw_grp=obj.layer<0 and pre_draw or post_draw
		for k,v in ipairs(draw_grp) do
			if obj.layer<=v.layer then
				add(draw_grp,obj,k)
				return
			end
		end
		add(draw_grp,obj)
	end)

	-- draw bg objects
	foreach(pre_draw,draw_object)
	
	-- draw terrain
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,2)
	
	-- draw fg objects
	foreach(post_draw,draw_object)

	-- draw jumpthroughs
	map(lvl_x,lvl_y,0,0,lvl_w,lvl_h,8)

	-- particles
	foreach(particles,draw_particle)

	-- dead particles
	foreach(dead_particles,function(p)
		p.x+=p.dx
		p.y+=p.dy
		p.t-=0.2
		if p.t<=0 then
			del(dead_particles,p)
		end
		rectfill(p.x-p.t,p.y-p.t,p.x+p.t,p.y+p.t,14+5*p.t%2)
	end)

	-- draw level title
	camera()
	if ui_timer>=-30 then
		if ui_timer<0 then
			draw_ui()
		end
		ui_timer-=1
	end

 draw_cui(1,1)
end

function draw_particle(p)
	p.x+=p.spd-cam_spdx
	p.y+=sin(p.off)-cam_spdy
	p.off+=min(0.05,p.spd/32)
	rectfill(p.x+draw_x,p.y%128+draw_y,p.x+p.s+draw_x,p.y%128+p.s+draw_y,p.c)
	if p.x>132 then
		p.x=-4
		p.y=rnd"128"
	elseif p.x<-4 then
		p.x=128
		p.y=rnd"128"
	end
end

--draw custom ui
function draw_cui(x,y)
 --draw time
	rectfill(x,y,x+32,y+12,0)
	?two_digit_str(minutes\60)..":"..two_digit_str(minutes%60)..":"..two_digit_str(seconds),x+1,y+1,7
 color(11)
 --draw cash
 ?"$"..cash
 --health bar
 rectfill(x,y+117,x+32,y+125,0)
 rectfill(x+1,y+118,x+(hp/max_hp)*30,y+124,hp>max_hp/2 and 11 or hp>max_hp/5 and 10 or hp>0 and 8 or 0)
 ?hp>0 and flr(hp) or "x_x",x+14-(hp>0 and #tostr(flr(hp)) or 3),y+119,7
 --difficulty meter
 rectfill(x+93,y,x+126,y+8,0)
 for i=1,32 do
  line(x+93+i,y+1,x+93+i,y+7,diff>600 and 0 or (1+((i)+(diff))/40))
 end
 --debug scaling display
-- ?flr(diff).." "..mid(1,(diff/10),max_hp/3),x+95,y+2,0
end

function draw_ui()
	rectfill(24,58,104,70,0)
	local title=lvl_title or lvl_id.."00 m"
	?title,64-#title*2,62,7
end
-->8
-- [player class]
player={
	init=function(this)
		this.grace,this.jbuffer=0,0
		this.djump=max_djump
		this.dash_time,this.dash_effect_time=0,0
		this.dash_target_x,this.dash_target_y=0,0
		this.dash_accel_x,this.dash_accel_y=0,0
		this.hitbox=rectangle(1,3,6,5)
		this.spr_off=0
		this.collides=true
		this.healtimer=0
		this._hitbox=this.hitbox
  chp=hp
  this.atkcooldown=0
		create_hair(this)
		this.layer=1
		this.ucooldown=0
		this._hitbox=this.hitbox
	end,
	update=function(this)
	 mspd=_mspd or mspd
	 _mspd=mspd
	 tesla_active=seconds%20>10
	 this.hitbox=this._hitbox
		if pause_player then
			return
		end
		
		if not was_hurt and not this.matk then		 
		 mspd=_mspd+0.1*(whip_stack)
		end
		
		if tesla_buff and tesla_active then
		 if frames>15 then
		 this.hitbox=rectangle(-16,-16,40,40)
		 local hit=this.check_all(enemy,0,0)
   if hit then
    for i=1,min(#hit,(3+(2*(tesla_stack-1)))) do
     damage_object(hit[i],sdmg*2)
     hit[i].line2=hit
     hit[i].line1=vector(this.x,this.y)
     _draw()
    end
   end 
   end 
		end
		this.hitbox=this._hitbox
				
		-- horizontal input
		local h_input=btn(➡️) and 1 or btn(⬅️) and -1 or 0
  this.h_oinput=btn(➡️) and 1 or btn(⬅️) and -1 or 0
		-- spike collision / bottom death
		if spikes_at(this.left(),this.top(),this.right(),this.bottom(),this.spd.x,this.spd.y) or this.y>lvl_ph then
			kill_player(this)
		end

		-- on ground checks
		on_ground=this.is_solid(0,1)

		-- landing smoke
		if on_ground and not this.was_on_ground then
			this.init_smoke(0,4)
		end

		-- jump and dash input
		local jump,dash=btn(🅾️) and not this.p_jump,btn(❎) and not this.p_dash
		this.p_jump,this.p_dash=btn(🅾️),btn(❎)

		-- jump buffer
		if jump then
			this.jbuffer=4
		elseif this.jbuffer>0 then
			this.jbuffer-=1
		end

		-- grace frames and dash restoration
		if on_ground then
			this.grace=6
			if this.djump<max_djump then
				psfx"54"
				this.djump=max_djump
			end
		elseif this.grace>0 then
			this.grace-=1
		end

		-- dash effect timer (for dash-triggered events, e.g., berry blocks)
		this.dash_effect_time-=1

		-- dash startup period, accel toward dash target speed
		if this.dash_time>0 then
			this.init_smoke()
			this.dash_time-=1
			this.spd=vector(appr(this.spd.x,this.dash_target_x,this.dash_accel_x),appr(this.spd.y,this.dash_target_y,this.dash_accel_y))
		else
			-- x movement
			local maxrun=mspd
			local accel=this.is_ice(0,1) and 0.05 or on_ground and 0.6 or 0.4
			local deccel=mspd/1.4

			-- set x speed
			this.spd.x=abs(this.spd.x)<=mspd and
			appr(this.spd.x,h_input*maxrun,accel) or
			appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)

			-- facing direction
			if this.spd.x~=0 then
				this.flip.x=this.spd.x<0
			end

			-- y movement
			local maxfall=mfall

			-- wall slide
			if h_input~=0 and this.is_solid(h_input,0) and not this.is_ice(h_input,0) then
				maxfall=0.2
				-- wall slide smoke
				if rnd"10"<2 then
					this.init_smoke(h_input*6)
				end
			end

			-- apply gravity
			if not on_ground then
				this.spd.y=appr(this.spd.y,maxfall,abs(this.spd.y)>0.15 and 0.21 or 0.105)
			end

			-- jump
			if this.jbuffer>0 then
				if this.grace>0 then
					-- normal jump
					psfx"1"
					this.jbuffer=0
					this.grace=0
					this.spd.y=jspd
					this.init_smoke(0,4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir~=0 then
						psfx"2"
						this.jbuffer=0
						this.spd=vector(wall_dir*(-.15-maxrun),mid(-1,jspd*1.5,-2.6))
						if not this.is_ice(wall_dir*3,0) then
							-- wall jump smoke
							this.init_smoke(wall_dir*6)
						end
					end
				end
			end

			-- dash
			local d_full=dspd
			local d_half=dspd/2

			if this.djump>0 and dash and not this.matk then
				this.init_smoke()
				this.djump-=1
				this.dash_time=4
				has_dashed=true
				this.dash_effect_time=10
				-- vertical input
				local v_input=btn(⬆️) and -1 or btn(⬇️) and 1 or 0
				-- calculate dash speeds
				this.spd=vector(h_input~=0 and
					h_input*(v_input~=0 and d_half or d_full) or
					(v_input~=0 and 0 or this.flip.x and -1 or 1)
				,v_input~=0 and v_input*(h_input~=0 and d_half or d_full) or 0)
				-- effects
				psfx"3"
				freeze=2
				-- dash target speeds and accels
				this.dash_target_x=2*sign(this.spd.x)
				this.dash_target_y=(this.spd.y>=0 and 2 or 1.5)*sign(this.spd.y)
				this.dash_accel_x=this.spd.y==0 and 1.5 or 1.06066017177 -- 1.5 * sqrt()
				this.dash_accel_y=this.spd.x==0 and 1.5 or 1.06066017177
			elseif this.djump<=0 and dash then
				-- failed dash smoke
				psfx"9"
				this.init_smoke()
			end
		end

		-- animation
		this.spr_off+=mid(0.05,mspd/4,1)
		this.spr = not on_ground and (this.is_solid(h_input,0) and 68 or 66) or	-- wall slide or mid air
		btn(⬇️) and 69 or -- crouch
		btn(⬆️) and 70 or -- look up
		this.spd.x~=0 and h_input~=0 and 64+this.spr_off%4 or 64 -- walk or stand

		-- exit level off the top (except summit)
		if this.y<-4 and levels[lvl_id+1] then
--			next_level()
		end

		-- was on the ground
		this.was_on_ground=on_ground
		moff=moff or 0
		-- melee attack
		if btn("ソ") and not this.matk then
		  this.matk=true
		  this.spd.y=jspd*1.6 		 
	 elseif on_ground then
	  this.matk=false
	  bc=false
		end
		
		--ranged attack
		if btn("c") and this.atkcooldown==0 then
		 for i=1,multishot do
		  init_object(bullet,this.x+4,this.y+4,vector(this.flip.x and -1 or 1,rnd(sspread)-rnd(sspread)))
	  end
		 this.atkcooldown=cdown
		end
		
		if this.atkcooldown>0 then
		 this.atkcooldown-=0.0333
		else
		 this.atkcooldown=0
		end
		
	
		
		--healing
		if damaged then was_hurt=true end
		
		if (hp<max_hp and was_hurt) then
		 this.healtimer=30+mid(30,diff,150)
		 was_hurt=false
		end
		if this.healtimer>0 then
		 this.healtimer-=1
		end
		if this.healtimer<=0 and hp<max_hp then
		 --heal 2% of max hp every frame
		 heal_player(regen/60)
		 healing=true
		end
		if hp>=max_hp then
		 hp=max_hp
		 healing=false
		end
				
		if btn("/") and this.equipment and this.ucooldown<=0 then 
   this.equipment.trigger(this)
   this.ucooldown=this.equipment.cooldown
		end
		
		if this.ucooldown>0 then
		 this.ucooldown-=0.0333
		end
										
		update_hair(this)
		update_items(this)
	end,
	
	draw=function(this)
	 this.outline=true
		-- clamp in screen
		local clamped=mid(this.x,-1,lvl_pw-7)
		if this.x~=clamped then
			this.x=clamped
			this.spd.x=0
		end
		
		if this.matk then
			local x=this.x
		 local y=this.y
		 moff=moff or 0
		 moff+=0.1
		 this.outline=false
		 for ox=-1,1 do
		  for oy=-1,1 do
		   if ox!=oy then
		    line(4+x+ox,4+y+oy,4+ox+x+sin(moff)*10,4+oy+y+cos(moff)*10,7)
		   end
		  end
		 end
		end
		
		if this.equipment then
		rectfill(draw_x+109,draw_y+109,draw_x+126,draw_y+126,0)
			if this.ucooldown>0 then
		  for i=1,15 do
		   pal(i,1)
		  end 
		 end
		 sspr(this.equipment.sx,this.equipment.sy,8,8,110+draw_x,110+draw_y,16,16)
		 pal()
		 if this.ucooldown>0 then
		 	?"\^w\^t"..flr(this.ucooldown),draw_x+111-(#tostr(flr(this.ucooldown))>1 and 0 or -4),draw_y+113,7
		 end
		 
		end
		
		pal()
		-- draw player hair and sprite
		set_hair_color(this.djump)
		draw_hair(this)
		draw_obj_sprite(this)
		pal()
		if this.equipment and this.ucooldown>0 then
		 this.equipment.draw(obj)
		end
	end,
	
	on_move=function(this,dx,dy)
  px,py=this.x,this.y
  pdx,pdy=dx,dy
  if this.matk then
		 this.hitbox=rectangle(-8,-8,20,20)
		 --damage hit enemy
		 local hit=this.check(enemy,0,0)
		 if hit then
		  damage_object(hit,sdmg*2)
    this.spd.y=-2
    this.hitbox=this._hitbox
		 end
		 	this.hitbox=this._hitbox
		end
 end
}

function create_hair(obj)
	obj.hair={}
	for i=1,5 do
		add(obj.hair,vector(obj.x,obj.y))
	end
end

function set_hair_color(djump)
	pal(8,djump==1 and 8 or djump==2 and 7+frames\3%2*4 or 12)
end

function update_hair(obj)
  local last=vector(obj.x+4-(obj.flip.x and-2 or 3),obj.y+(btn(⬇️) and 4 or 2.9))
  for h in all(obj.hair) do
    h.x+=(last.x-h.x)/1.5
    h.y+=(last.y+0.5-h.y)/1.5
    last=h
  end
end

function draw_hair(obj)
  for i,h in pairs(obj.hair) do
    circfill(round(h.x),round(h.y),mid(4-i,1,2),8)
  end
end

function kill_player(obj,dmg)
--if no damage is given, default to 20
dmg=dmg or 20
--damage is middle value of 1,scaled_dmg,max_hp/3 (to prevent 1shots)
dmg=mid(1,(diff/10)+dmg,max_hp/3)
if hp>0 then
 hp-=dmg
 if on_ground then
  --bounce player back to fix clip deaths
  obj.spd.y=1
 end
 --bounce player away
 obj.spd.x=-obj.h_oinput*2.6
 obj.spd.y=-obj.spd.y*1.2
end
--if no hp left, kill player
if hp<=0 then
	sfx_timer=12
	sfx"0"
	deaths+=1
	destroy_object(obj)
	--dead_particles={}
	for dir=0,0.875,0.125 do
		add(dead_particles,{
			x=obj.x+4,
			y=obj.y+4,
			t=2,
			dx=sin(dir)*3,
			dy=cos(dir)*3
		})
	end
	-- todo: end screen+start new run
--	delay_restart=15
end
damaged=true --tell player that it was damaged incase they missed it
took_damage=true --tell player that it was damaged incase they missed it
end

player_spawn={
	init=function(this)
		sfx"4"
		this.spr=66
		this.target=this.y
		this.y=min(this.y+48,lvl_ph)
		cam_x,cam_y=mid(this.x+4,64,lvl_pw-64),mid(this.y,64,lvl_ph-64)
		this.spd.y=-4
		this.state=0
		this.delay=0
		create_hair(this)
		this.djump=max_djump
		hp=max_hp
		this.layer=1
	end,
	update=function(this)
		-- jumping up
		if this.state==0 and this.y<this.target+16 then
			this.state=1
			this.delay=3
			-- falling
		elseif this.state==1 then
			this.spd.y+=0.5
			if this.spd.y>0 then
				if this.delay>0 then
					-- stall at peak
					this.spd.y=0
					this.delay-=1
				elseif this.y>this.target then
					-- clamp at target y
					this.y=this.target
					this.spd=vector(0,0)
					this.state=2
					this.delay=5
					this.init_smoke(0,4)
					sfx"5"
				end
			end
			-- landing and spawning player object
		elseif this.state==2 then
			this.delay-=1
			this.spr=69
			if this.delay<0 then
				destroy_object(this)
				init_object(player,this.x,this.y)
			end
		end
		update_hair(this)
	end,
	draw= player.draw
}

function bounce(obj)
 obj.spd=vector(obj.spd.x*-1.2,obj.spd.y*-1.2)
	obj.move(obj.spd.x,obj.spd.y,0)
end

function heal_player(health)
 hp+=min(health*(rack_stack+1),max_hp)
end
-->8
-- [objects]

spring={
	init=function(this)
		this.delta=0
		this.dir=this.spr==41 and 0 or this.is_solid(-1,0) and 1 or -1
		this.show=true
		this.layer=-1
	end,
	update=function(this)
		this.delta=this.delta*0.75
		local hit=this.player_here()
		
		if this.show and hit and this.delta<=1 then
			if this.dir==0 then
				hit.move(0,this.y-hit.y-4,1)
				hit.spd.x*=0.2
				hit.spd.y=-3
			else
				hit.move(this.x+this.dir*4-hit.x,0,1)
				hit.spd=vector(this.dir*3,-1.5)
			end
			hit.dash_time=0
			hit.dash_effect_time=0
			hit.djump=max_djump
			this.delta=8
			psfx"8"
			this.init_smoke()
			
			break_fall_floor(this.check(fall_floor,-this.dir,this.dir==0 and 1 or 0))
		end
	end,
	draw=function(this)
		if this.show then
			local delta=min(flr(this.delta),4)
			if this.dir==0 then
				sspr(72,16,8,8,this.x,this.y+delta)
			else
				spr(42,this.dir==-1 and this.x+delta or this.x,this.y,1-delta/8,1,this.dir==1)
			end
		end
end
}

fall_floor={
	init=function(this)
		this.solid_obj=true
		this.state=0
	end,
	update=function(this)
		-- idling
		if this.state==0 then
			for i=0,2 do
				if this.check(player,i-1,-(i%2)) then
					break_fall_floor(this)
				end
			end
		-- shaking
		elseif this.state==1 then
			this.delay-=1
			if this.delay<=0 then
				this.state=2
				this.delay=60--how long it hides for
				this.collideable=false
				set_springs(this,false)
			end
			-- invisible, waiting to reset
		elseif this.state==2 then
			this.delay-=1
			if this.delay<=0 and not this.player_here() then
				psfx"7"
				this.state=0
				this.collideable=true
				this.init_smoke()
				set_springs(this,true)
			end
		end
	end,
	draw=function(this)
		spr(this.state==1 and 28-this.delay/5 or this.state==0 and 25,this.x,this.y) --add an if statement if you use sprite 0 (other stuff also breaks if you do this i think)
	end,
}

function break_fall_floor(obj)
	if obj and obj.state==0 then
		psfx"15"
		obj.state=1
		obj.delay=15--how long until it falls
		obj.init_smoke()
	end
end

function set_springs(obj,state)
	obj.hitbox=rectangle(-2,-2,12,8)
	local springs=obj.check_all(spring,0,0)
	foreach(springs,function(s) s.show=state end)
	obj.hitbox=rectangle(0,0,8,8)
end

balloon={
	init=function(this)
		this.offset=rnd()
		this.start=this.y
		this.timer=0
		this.hitbox=rectangle(-1,-1,10,10)
	end,
	update=function(this)
		if this.spr==44 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit=this.player_here()
			if hit and hit.djump<max_djump then
				psfx"6"
				this.init_smoke()
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else
			psfx"7"
			this.init_smoke()
			this.spr=44
		end
	end,
	draw=function(this)
		if this.spr==44 then
			for i=7,13 do
				pset(this.x+4+sin(this.offset*2+i/10),this.y+i,6)
			end
			draw_obj_sprite(this)
		end
	end
}

smoke={
	init=function(this)
		this.spd=vector(0.3+rnd"0.2",-0.1)
		this.x+=-1+rnd"2"
		this.y+=-1+rnd"2"
		this.flip=vector(rnd()<0.5,rnd()<0.5)
		this.layer=3
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=14 then
			destroy_object(this)
		end
	end
}

fruit={
	check_fruit=true,
	init=function(this)
		this.start=this.y
		this.off=0
	end,
	update=function(this)
		check_fruit(this)
		this.off+=0.025
		this.y=this.start+sin(this.off)*2.5
	end
}

fly_fruit={
	check_fruit=true,
	init=function(this)
		this.start=this.y
		this.step=0.5
		this.sfx_delay=8
	end,
	update=function(this)
		--fly away
		if has_dashed then
			if this.sfx_delay>0 then
				this.sfx_delay-=1
				if this.sfx_delay<=0 then
					sfx_timer=20
					sfx"14"
				end
			end
			this.spd.y=appr(this.spd.y,-3.5,0.25)
			if this.y<-16 then
				destroy_object(this)
			end
			-- wait
		else
			this.step+=0.05
			this.spd.y=sin(this.step)*0.5
		end
		-- collect
		check_fruit(this)
	end,
	draw=function(this)
		spr(43,this.x,this.y)
		for ox=-6,6,12 do
			spr((has_dashed or sin(this.step)>=0) and 28 or this.y>this.start and 30 or 29,this.x+ox,this.y-2,1,1,ox==-6)
		end
	end
}

function check_fruit(this)
	local hit=this.player_here()
	if hit then
		sfx_timer=20
		sfx"13"
		got_fruit[this.fruit_id]=true
		init_object(lifeup,this.x,this.y)
		destroy_object(this)
		if time_ticking then
			fruit_count+=1
		end
	end
end

lifeup={
	init=function(this)
		this.spd.y=-0.25
		this.duration=30
		this.flash=0
	end,
	update=function(this)
		this.duration-=1
		if this.duration<=0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		this.flash+=0.5
		?"1000",this.x-4,this.y-4,7+this.flash%2
	end
}

bullet={
 init=function(this)
  this.dx=this.spr.x*sspd
  this.dy=this.spr.y*sspd
  this.timer=0
  --bullet size can be from 1,4
  this.r=mid(1,sdmg,4)
  this.hitbox=rectangle(0,0,this.r*2,this.r*2)
  this.spd.x=this.dx
  this.spd.y=this.dy
 end,
 update=function(this)
  this.timer+=1
  --after 4secs, delete this obj
  if this.timer>120 then
   destroy_object(this)
  end
  --also del if hits solid tile
  if fget(tile_at(this.x/8,this.y/8),0) or this.check(fall_floor,0,0) then
   destroy_object(this)
  end
  
  local hit=this.check(enemy,0,0) 
  if hit then
   --damage hit enemy
   damage_object(hit,sdmg,ukulele_buff and 3 or false)
   destroy_object(this)
  end

 end,
 
 draw=function(this)
  --draw bullet
  circfill(this.x-this.spr.x,this.y,this.r,7)
  circfill(this.x,this.y,this.r,8)
 end,
 
}

--enemy
enemy={

 init=function(this)
  local types={
   wisp={
    hp=170,
    dmg=17,
    spr=45,
   }  
  }
  
  this.etype=types["wisp"]
  this.hitbox=rectangle(0,0,8,8)
  this.hp=this.etype.hp
  this.pts=6*(diff/20)
  this.dmg=this.etype.dmg
  this.max_hp=this.hp
  this.showtimer=0
  this._hitbox=this.hitbox
 end, 
 
 update=function(this)
   this.hitbox=this._hitbox
  local hit=this.player_here()

  if this.etype==wisp then
  
  
  end
 
 
 
 --enemy functions (shared)
  if hit then
   --damage player
   kill_player(hit,this.dmg)
  end
  if this.was_hurt and this.showtimer<=0 then
   this.showtimer=180
  end
  if this.showtimer>0 then
   this.showtimer-=1
  end
  if this.showtimer<=0 then
   this.was_hurt=false
  end
  if this.showtimer<170 then
    this.line1,this.line2=nil,nil
  end
  if this.onfire then
   if not this.blast then
    damage_object(this,sdmg*1.5,true)
    this.blast=true
   end
   this.firetime-=1
   if this.firetime<=0 then
    this.onfire=false
   end
   damage_object(this,this.firedmg,true)
  end
  this.hitbox=this._hitbox
 end, 
 
 draw=function(this)
 
   spr(this.etype.spr,this.x,this.y)
 
 --hp bar/fire
  if this.was_hurt then
   rectfill(this.x-3,this.y-3,this.x+11,this.y-3,0)
   line(this.x-3,this.y-3,this.x+flr(((flr(this.hp)/this.max_hp)*11)),this.y-3,8)
  end
  if this.onfire then
   spr(71,this.x,this.y,1,1,seconds%2==0)
  end
  if this.line1 and this.line2 then
   for i=1,#this.line2 do
    line(this.line1.x+4,this.line1.y+4,this.line2[i].x+4,this.line2[i].y+4,7)
   end
  end 
 end,


}

hporb={
 init=function(this)
  this.timer=60
  this.off=0
 end,
 
 update=function(this)
  local hit=this.player_here()
  if hit then
   heal_player((max_hp/50)*necklace_stack)
   destroy_object(this)
  end
 end,
 
 draw=function(this)
  this.off+=0.002
  circfill(this.x+sin(this.off)*2,this.y+cos(this.off)*2,2,11)
 end,

}

chest={

init=function(this)
 --chest data library
 local sprites={
 small={sx=56,sy=40,sw=12,sh=8,base_price=25},
 large={sx=56,sy=48,sw=18,sh=16,base_price=50}
 }
 
 this.t=this.spr==87 and "small" or "large"
 
 --set sprite location to matching chest in library
 this.sx=sprites[this.t].sx
 this.sy=sprites[this.t].sy
 this.sw=sprites[this.t].sw
 this.sh=sprites[this.t].sh
 
 this.hitbox=rectangle(0,0,this.sw,this.sh)
 --base cost+scaling=scaled price
 this.price=sprites[this.t].base_price+flr(min(flr(diff)+rnd(50)),300)
end,

update=function(this)
 local hit=this.player_here()
 
 if hit then
  --if space+can afford
  if btn(" ") and cash>=this.price then
   --bill player
   cash-=this.price
   
   init_object(item,this.x+(this.t=="large" and 5 or 0),this.y-16,this.t)
   destroy_object(this)
  end
  this.drawprice=true
 else
  this.drawprice=false
 end
end,

draw=function(this)
 if this.drawprice then
  --show price
  print("$"..this.price,this.x,this.y-10,10)
 end
 sspr(this.sx,this.sy,this.sw,this.sh,this.x,this.y-this.sh+8)
end

}

wispbomb={

init=function(this)
 this.dmg=sdmg*(3.5+(2.8*(wisp_stack-1)))
 this.r=12+(3*wisp_stack-1)
 this.timer=30
 this.hitbox=rectangle(-this.r/2,-25,this.r*1.5,33)
end,

update=function(this)
 this.timer-=1
 if this.timer>0 then return end
 
 local hit=this.check_all(enemy,0,0)
 
 for i in all(hit) do
  damage_object(i,this.dmg)
 end
 
 if this.timer<-10 then 
  destroy_object(this)
 end
 
end,

draw=function(this)
if this.timer>0 then return end
 rectfill(this.x-(this.r/2),this.y+8,this.x+(this.r),this.y-25,9-(((frames/5)%2)*3)%2)
end

}

rocket={

init=function(this)
 this.spd.y=-2*(rnd(0.4)+1)
 this.spd.x=this.spr==true and -1 or 1
 this.spd.x*=(rnd(0.4)+1)
 this.hitbox=rectangle(0,0,4,4)
end,

update=function(this)
 this.spd.y+=0.1
 local hit=this.check_all(enemy,0,0) or this.check(fall_floor,0,0)

 if this.explode then
  this.hitbox=rectangle(-16,-16,40,40)
  for i in all(hit) do
   if i.type==enemy then
    damage_object(i,sdmg*3)
   end
  end
  destroy_object(this)
 end
 
 if fget(tile_at(this.x/8,this.y/8),0) or hit then
  this.explode=true
 end
 
end,

draw=function(this)
 circfill(this.x,this.y,2,9)
 
 if this.explode then
  circfill(this.x,this.y,6,8)
 end
end

}

molotov={

init=function(this)
 this.spd.x=this.spr.d and -0.5 or 0.5
 this.spd.y=-0.5-rnd(2)
 this.spd.x*=rnd(1)+1
 this.x=this.spr.x
 this.y=this.spr.y
 this.hitbox=rectangle(0,0,8,8)
end,

update=function(this)
 this.spd.y+=0.1
 
 if this.explode then
  this.hitbox=rectangle(-4,-4,16,16)
  local hit=this.check_all(enemy,0,0)
  for i in all(hit) do
   i.onfire=true
   i.firetime=60
   i.firedmg=sdmg*2
   damage_object(i,sdmg*5)
  end
  
  destroy_object(this)
 end
 local hit=this.check(enemy,0,0)
 if hit or fget(tile_at(this.x/8,this.y/8),0) or this.check(fall_floor,0,0) then
  this.explode=true
 end
end,

draw=function(this)
 spr(118,this.x,this.y)
 if this.explode then
  circfill(this.x+4,this.y+4,5,8)
 end
end,
}

item={

init=function(this)
 
 this.cq=rnd(100)
 
 local common={
  {name="bison",spr=80},
  {name="crowbar",spr=96},
  {name="focus",spr=112},
  {name="mocha",spr=81},
  {name="medkit",spr=97},
  {name="soldier",spr=113},
  {name="necklace",spr=82},
  {name="gasoline",spr=98},
  {name="hoof",spr=114},
  {name="energy",spr=83}
 }
 
 local uncommon={
  {name="hoppo",spr=99},
  {name="wisp",spr=115},
  {name="ukulele",spr=100},
  {nane="guillotine",spr=116},
  {name="whip",spr=101},
  {name="ignite",spr=117}
 }
 
 local rare={
  {name="tesla",spr=84},
  {name="rack",spr=85}
 }
 
 local equipment={
  {name="rocket",spr=86,sx=48,sy=40,cooldown=30,
  trigger=function(obj)
   for i=1,12 do
    init_object(rocket,obj.x,obj.y,obj.flip)
   end
  end,
  draw=function(obj) end
  },
  {name="fruit",spr=102,sx=48,sy=48,cooldown=15,
  trigger=function(obj) heal_player(max_hp/2) end,
  draw=function(obj) end
  },
  {name="molotov",spr=118,sx=48,sy=56,cooldown=20,
  trigger=function(obj) 
   for i=1,5 do
    init_object(molotov,this.x,this.y,{d=obj.flip.x,x=obj.x,y=obj.y})
   end
  end,
  draw=function(obj) end}
 }
 
 if this.spr=="large" then
  this.uc=80
  this.ec=20
  this.rc=10
 else
  this.cc=70
  this.uc=29
  this.rc=2
 end
 
 local qc=rnd(100)
 if qc<=this.rc then
  this.rarity=rare
 elseif qc<=this.uc then
  this.rarity=uncommon
 elseif this.ec and qc<this.ec then
  this.rarity=equipment
  this.j=true
 else
  this.rarity=common
 end
 this.rarity=equipment
 this.j=true
 
 
 ic=flr(rnd(#this.rarity))+1
 
 this.item=this.rarity[ic]
 
 this.spd.y=-2
 
end,

update=function(this)
 this.spd.y/=2
 
 local hit=this.player_here()
 
 if hit and not this.j then
  add(items,this.item.name)
  destroy_object(this)
 end
 
 if hit and this.j then
   hit.equipment=this.item
   destroy_object(this)
 end
end,

draw=function(this)
 
 spr(this.item.spr,this.x,this.y)
 
end




}

-- [object class]

function init_object(type,x,y,tile)
	--generate and check berry id
	local id=x..","..y..","..lvl_id
	if type.check_fruit and got_fruit[id] then
		return
	end

	local obj={
		type=type,
		collideable=true,
		--collides=false,
		spr=tile,
		flip=vector(),--false,false
		x=x,
		y=y,
		hitbox=rectangle(0,0,8,8),
		spd=vector(0,0),
		rem=vector(0,0),
		layer=0,
		
		fruit_id=id,
	}

	function obj.left() return obj.x+obj.hitbox.x end
	function obj.right() return obj.left()+obj.hitbox.w-1 end
	function obj.top() return obj.y+obj.hitbox.y end
	function obj.bottom() return obj.top()+obj.hitbox.h-1 end

	function obj.is_solid(ox,oy)
		for o in all(objects) do
			if o!=obj and (o.solid_obj or o.semisolid_obj and not obj.objcollide(o,ox,0) and oy>0) and obj.objcollide(o,ox,oy) then
				return true
			end
		end
		return oy>0 and not obj.is_flag(ox,0,3) and obj.is_flag(ox,oy,3) or -- jumpthrough or
		obj.is_flag(ox,oy,0) -- solid terrain
	end

	function obj.is_ice(ox,oy)
		return obj.is_flag(ox,oy,4)
	end

	function obj.is_flag(ox,oy,flag)
		for i=max(0,(obj.left()+ox)\8),min(lvl_w-1,(obj.right()+ox)/8) do
			for j=max(0,(obj.top()+oy)\8),min(lvl_h-1,(obj.bottom()+oy)/8) do
				if fget(tile_at(i,j),flag) then
					return true
				end
			end
		end
	end

	function obj.objcollide(other,ox,oy)
		return other.collideable and
		other.right()>=obj.left()+ox and
		other.bottom()>=obj.top()+oy and
		other.left()<=obj.right()+ox and
		other.top()<=obj.bottom()+oy
	end

	--returns first object of type colliding with obj
	function obj.check(type,ox,oy)
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				return other
			end
		end
	end
	
	--returns all objects of type colliding with obj
	function obj.check_all(type,ox,oy)
		local tbl={}
		for other in all(objects) do
			if other and other.type==type and other~=obj and obj.objcollide(other,ox,oy) then
				add(tbl,other)
			end
		end
		
		if #tbl>0 then return tbl end
	end

	function obj.player_here()
		return obj.check(player,0,0)
	end

	function obj.move(ox,oy,start,brk)
		for axis in all{"x","y"} do
			obj.rem[axis]+=axis=="x" and ox or oy
			local amt=round(obj.rem[axis])
			obj.rem[axis]-=amt
			local upmoving=axis=="y" and amt<0
			local riding=not obj.player_here() and obj.check(player,0,upmoving and amt or -1)
			local movamt
			if obj.collides then
				local step=sign(amt)
				local d=axis=="x" and step or 0
				local p=obj[axis]
				for i=start,abs(amt) do
				  --⬇️ thanks meep :d 
     if obj.type.on_move and obj.type.on_move(obj,ox,oy) then
      return 
     end
     if not obj.is_solid(d,step-d) then
						obj[axis]+=step
					else
						obj.spd[axis],obj.rem[axis]=0,0
						break
					end
				end
				movamt=obj[axis]-p --save how many px moved to use later for solids
			else
				movamt=amt
				if (obj.solid_obj or obj.semisolid_obj) and upmoving and riding then
					movamt+=obj.top()-riding.bottom()-1
					local hamt=round(riding.spd.y+riding.rem.y)
					hamt+=sign(hamt)
					if movamt<hamt then
						riding.spd.y=max(riding.spd.y,0)
					else
						movamt=0
					end
				end
				obj[axis]+=amt
			end
			if (obj.solid_obj or obj.semisolid_obj) and obj.collideable then
				obj.collideable=false
				local hit=obj.player_here()
				if hit and obj.solid_obj then
					hit.move(axis=="x" and (amt>0 and obj.right()+1-hit.left() or amt<0 and obj.left()-hit.right()-1) or 0,
									axis=="y" and (amt>0 and obj.bottom()+1-hit.top() or amt<0 and obj.top()-hit.bottom()-1) or 0,
									1)
					if obj.player_here() then
						kill_player(hit)
					end
				elseif riding then
					riding.move(axis=="x" and movamt or 0, axis=="y" and movamt or 0,1)
				end
				obj.collideable=true
			end
		end
	end

	function obj.init_smoke(ox,oy)
		init_object(smoke,obj.x+(ox or 0),obj.y+(oy or 0),12)
	end
	
	add(objects,obj);

	(obj.type.init or stat)(obj)

	return obj
end

function destroy_object(obj)
	del(objects,obj)
end

function damage_object(obj,dmg,safe)
 --deal dmg damage
 obj.hp-=dmg
 if obj.hp<=0 then
  --award player with money
  cash+=obj.pts
  if necklace_buff then
   init_object(hporb,obj.x,obj.y)
  end
  if wisp_buff then
   init_object(wispbomb,obj.x,obj.y)
  end
  destroy_object(obj)
 end
 if gasoline_buff and not safe then
  obj.onfire=true
  obj.firetime=90+(45*gasoline_stack-1)
  obj.firedmg=sdmg*((1.5+(.75*gasoline_stack-1)))
 end
 if ukulele_buff and safe and type(safe)=="number" and safe>0 then
  obj.hitbox=rectangle(-16,-16,40,40)
  local hit=obj.check_all(enemy,0,0)
   if hit then
    for i=1,min(#hit,(3+(ukulele_stack)-1)) do
     damage_object(hit[i],sdmg-(sdmg/5))
     obj.line2=hit
     obj.line1=vector(obj.x,obj.y)
     _draw()
    end
   end  
 end
 if guillotine_buff and not safe then
  if obj.hp<(flr(obj.max_hp*(0.05*guillotine_stack))) then
   damage_object(obj,obj.hp,true)
  end
 end
 if obj.firedmg then
  obj.firedmg/=30
 end
 if obj.firedmg and ignite_stack>0 then
  obj.firedmg*=3*ignite_stack
 end
 obj.was_hurt=true
 if obj._hitbox then
  obj.hitbox=obj._hitbox
 end
end

function move_camera(obj)
	cam_spdx=cam_gain*(4+obj.x-cam_x)
	cam_spdy=cam_gain*(4+obj.y-cam_y)

	cam_x+=cam_spdx
	cam_y+=cam_spdy

	--clamp camera to level boundaries
	local clamped=mid(cam_x,64,lvl_pw-64)
	if cam_x~=clamped then
		cam_spdx=0
		cam_x=clamped
	end
	clamped=mid(cam_y,64,lvl_ph-64)
	if cam_y~=clamped then
		cam_spdy=0
		cam_y=clamped
	end
end

function draw_object(obj)
	(obj.type.draw or draw_obj_sprite)(obj)
end

function draw_obj_sprite(obj)
	spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
end
-->8
-- [level loading]

function next_level()
	local next_lvl=lvl_id+1

	--check for music trigger
	if music_switches[next_lvl] then
		music(music_switches[next_lvl],500,7)
	end

	load_level(next_lvl)
end

function load_level(id)
	has_dashed,has_key= false

	--remove existing objects
	foreach(objects,destroy_object)

	--reset camera speed
	cam_spdx,cam_spdy=0,0

	local diff_level=lvl_id~=id

	--set level index
	lvl_id=id

	--set level globals
	local tbl=split(levels[lvl_id])
	for i=1,4 do
		_ENV[split"lvl_x,lvl_y,lvl_w,lvl_h"[i]]=tbl[i]*16
	end
	lvl_title=tbl[5]
	lvl_pw,lvl_ph=lvl_w*8,lvl_h*8

	--level title setup
	ui_timer=5

	--reload map
	if diff_level then
		reload()
		--check for mapdata strings
		if mapdata[lvl_id] then
			replace_mapdata(lvl_x,lvl_y,lvl_w,lvl_h,mapdata[lvl_id])
		end
	end

	-- entities
	for tx=0,lvl_w-1 do
		for ty=0,lvl_h-1 do
			local tile=tile_at(tx,ty)
			if tiles[tile] then
				init_object(tiles[tile],tx*8,ty*8,tile)
			end
		end
	end
end

--replace mapdata with hex
function replace_mapdata(x,y,w,h,data)
	for i=1,#data,2 do
		mset(x+i\2%w,y+i\2\w,"0x"..sub(data,i,i+1))
	end
end
-->8
-- [metadata]

--@begin
--level table
--"x,y,w,h,title"
levels={
	"0,0,1,1",
	"0,0,1,1,summit",
}

--mapdata string table
--assigned levels will load from here instead of the map
mapdata={

}

--list of music switch triggers
--assigned levels will start the tracks set here
music_switches={

}

--@end

--tiles stack
--assigned objects will spawn from tiles set here
tiles={}
foreach(split([[
64,player_spawn
41,spring
42,spring
44,balloon
25,fall_floor
43,fruit
28,fly_fruit
45,enemy
87,chest
119,chest

]],"\n"),function(t)
 local tile,obj=unpack(split(t))
 tiles[tile]=_ENV[obj]
end)



--[[

short on tokens?
everything below this comment
is just for grabbing data
rather than loading it
and can be safely removed!

--]]

--copy mapdata string to clipboard
function get_mapdata(x,y,w,h)
	local reserve=""
	for i=0,w*h-1 do
		reserve..=num2hex(mget(i%w,i\w))
	end
	printh(reserve,"@clip")
end

--convert mapdata to memory data
function num2hex(v)
	return sub(tostr(v,true),5,6)
end
-->8
--mod stuff

--stats
	 jspd=-1
		dspd=1
		mspd=0.7
		mfall=1.8
		sspread=0.15
		cdown=.1
		sspd=2
		sdmg=1
		cash=75
		max_hp=250
		hp=max_hp
		diff=0
		multishot=1
		regen=20


--extended keyboard input
key=""
function handle_keypresses()
 --placeholder, just one max keystroke.
  key=stat(31)
  
end

--extended btn

--remember old btn
_btn=btn
btn=function(b)
 
 --normal btn
 if type(b)=="number" then
   return _btn(b)
 end
 
 --extended btn
 return b==key

end

--enemy spawn
function spawn_enmys()
 if est==nil or est<=0 then
  est=mid(60,diff>>-diff,60)
  
  local ex=rnd(lvl_pw)
  local ey=rnd(lvl_ph)
  
  init_object(enemy,lvl_x+ex,lvl_y+ey)
 end
 
 
 
 
 est-=1
end
-->8
--items
crowbar_stack=0
necklace_stack=0
rack_stack=0
gasoline_stack=0
ukulele_stack=0
guillotine_stack=0
whip_stack=0
ignite_stack=0
wisp_stack=0
tesla_stack=0
items={}

function update_items(obj)
foreach(items,function(item)
 if item=="bison" then
  max_hp+=25
  del(items,"bison")
 end
 if item=="crowbar" then
  crowbar_stack+=1
  del(items,"crowbar")
 end
 if item=="focus" then
  sdmg+=0.2
  del(items,"focus")
 end
 if item=="mocha" then
  cdown-=0.01
  mspd+=0.1
  del(items,"mocha")
 end
 if item=="medkit" then
  add(items,"medkit_buff")
  regen+=5
  del(items,"medkit")
 end
 if item=="medkit_buff" then
  local buffed=buffed or true
  if took_damage and not buffed then
   took_damage=false
   buffed=true
   used_buff=false
  end
  if healing and not buffed then
   buffed=true
  end
  if healing and buffed and not used_buff then
   hp+=20
   used_buff=true
  end
  if hp>=max_hp then
   buffed=true
   used_buff=false
  end
 end
 if item=="soldier" then
  cdown-=0.02
  del(items,"soldier")
 end
 if item=="necklace" then
  necklace_buff=true
  necklace_stack+=1
  del(items,"necklace")
 end
 if item=="gasoline" then
  gasoline_buff=true
  gasoline_stack+=1
  del(items,"gasoline")
 end
 if item=="hoof" then
  mspd+=0.14
  del(items,"hoof")
 end
 if item=="energy" then
  mspd+=0.25
  del(items,"energy")
 end
 if item=="ukulele" then
  ukulele_buff=true
  ukulele_stack+=1
  del(items,"ukulele")
 end
 if item=="guillotine" then
  guillotine_stack+=1
  guillotine_buff=true
  del(items,"guillotine")
 end
 if item=="rack" then
  rack_stack+=1
  del(items,"rack")
 end
 if item=="whip" then
  whip_buff=true
  whip_stack+=1
  del(items,"whip")
 end
 if item=="ignite" then
  ignite_stack+=1
  ignite_buff=true
  del(items,"ignite")
 end
 if item=="hoppo" then
  max_djump+=1
  jspd-=0.5
  del(items,"hoppo")
 end
 if item=="wisp" then
  wisp_buff=true
  wisp_stack+=1
  del(items,"wisp")
 end
 if item=="tesla" then
  tesla_buff=true
  tesla_stack+=1
  del(items,"tesla")
 end
end)
end
__gfx__
00000000577777777777777777777775577777750777777777777777777777700777777049494949494949494949494900000000000000007000000000000000
00000000777777777777777777777777777777777000077700007770000077777000777722222222222222222222222200770000077007000700000700000000
000000007777ccccc777777ccccc77777777777770cc777cccc777ccccc7770770c7770700042000000000000002400000777070077700000000000000000000
00000000777cccccccc77cccccccc777777cc77770c777cccc777ccccc777c0770777c0700420000000000000000240007777770077000000000000000000000
0000000077cccccccccccccccccccc7777cccc777077700007770000077700077777000704200000000000000000024007777770000070000000000000000000
0000000077cc77ccccccccccccc7cc7777cccc777777000077700000777000077770000742000000000000000000002407777770000007700000000000000000
0000000077cc77cccccccccccccccc7777c7cc777000000000000000000c000770000c0720000000000000000000000207077700000707700700007000000000
0000000077cccccccccccccccccccc7777cccc777000000000000000000000077000000700000000000000000000000000000000700000000000000000000000
0000000077cccccccccccccccccccc7777cccc777000000000000000000000077000000749999994499999944999099400000000000000000000000000000000
00000000777cccccccccccccccccc777777ccc777000000c000000000000000770cc000791111119911141199114091900077777000000000000000000000000
00000000777cccccccccccccccccc777777ccc7770000000000cc0000000000770cc000791111119911191194940041900776670000000000000000000000000
000000007777cccccccccccccccc777777ccc77770c00000000cc00000000c0770000c0791111119949404190000004407677700000000000000000000000000
000000007777cccccccccccccccc777777ccc7777000000000000000000000077000000791111119911409499400000007766000077777000000000000000000
00000000777cccccccccccccccccc777777cc77770000000000000000000000770c0000791111119911191199140049907777000077776700770000000000000
00000000777cccccccccccccccccc777777cc77770000000c0000000000000077000000791111119911411199140411907000000070000770777777000000000
0000000077cccccccccccccccccccc7777cccc777000000000000000000000077000c00749999994499999944400499400000000000000000007777700000000
0000000077cccccccccccccccccccc77777ccc777000000000000000000000077000000700000000000000000300b0b000888800000000000000000000000000
0000000077cccccccccccccccccccc77777cc777700000000000000000000007700c00070000000000040000003b330008888880000550000000000000000000
0000000077cc7cccccccccccc77ccc77777cc777700000000000c000000000077000000700000000000950500288882008788880055555500000000000000000
0000000077ccccccccccccccc77ccc7777ccc7777000000cc0000000000000077000cc0704999940000905050898888008888880051919500000000000000000
00000000777cccccccc77cccccccc77777cccc777000000cc0000000000c00077000cc0700500500000905050888898008888880059999500000000000000000
000000007777ccccc777777ccccc777777cccc7770c00000000000000000000770c0000700055000000950500889888008888880055555500000000000000000
00000000777777777777777777777777777cc7777000000000000000000000077000000700500500000400000288882000888800005005000000000000000000
00000000577777777777777777777775577777750777777777777777777777700777777000055000000000000028820000000000005005000000000000000000
00000000577777777777777777777775577777750777777777777777777777700777777000000000666566655500000000000666000000000000000000000000
00000000777777777777777777777777777777777000777000007770000077777000777700000000676567656670000000077776000000000000000000000000
000000007777ccc7777777777ccc7777777c777770c777ccccc777ccccc7770770c7770700000000677067706777700000000766000000000000000000000000
00000000777ccccc7c7777ccccccc77777cccc7770777ccccc777ccccc777c0770777c0700700070070007006660000000000055000000000000000000000000
00000000777ccccccc7777c7ccccc77777cccc777777000007770000077700077777000700700070070007005500000000000666000000000000000000000000
000000007777ccc7777777777ccc7777777cc77777700000777000007770000777700c0706770677000000006670000000077776000000000000000000000000
00000000777777777777777777777777777777777000000000000000000000077000000756765676000000006777700000000766000000000000000000000000
00000000577777777777777777777775577777750777777777777777777777700777777056665666000000006660000000000055000000000000000000000000
00000000000000000888888000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000
08888880088888808888888808888880088888000000000008888880005000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888888ffff888888888888888800888888088f1ff18000008000000000000000000000000000000000000000000000000000000000000000000
888ffff8888ffff888f1ff18888ffff88ffff8808888888888fffff8080008800000000000000000000000000000000000000000000000000000000000000000
88f1ff1888f1ff1808fffff088f1ff1881ff1f80888ffff888fffff8088088800000000000000000000000000000000000000000000000000000000000000000
08fffff008fffff00033330008fffff00fffff8088fffff808333380088888880000000000000000000000000000000000000000000000000000000000000000
003333000033330007000070073333000033337008f1ff1000333300888988880000000000000000000000000000000000000000000000000000000000000000
00700700007000700000000000000700000070000773337000700700889999990000000000000000000000000000000000000000000000000000000000000000
088880000000000004000040000037c0000550007000000700000000006600066000000000000000000000000000000000000000000000000000000000000000
8ffff8000077000040444404000bb37000500500b007070b000041910d66ddd66d00000000000000000000000000000000000000000000000000000000000000
8f8f8f800666600040000004003bbb3705011050bbb000bb00449999dd66ddd66dd0000000000000000000000000000000000000000000000000000000000000
8f88f8f807777000f400004f0b3bb3c3501611050b7007b304949191ddddd1ddddd0000000000000000000000000000000000000000000000000000000000000
8fff88f8044440000f4004f03b3b3cc0055292500300000404994440111117111110000000000000000000000000000000000000000000000000000000000000
0888f8f80045540000044000b3b3c70000255200043b0b04a5544059ddddd1ddddd0000000000000000000000000000000000000000000000000000000000000
00008ff800444400000ff000bb3c7000002992000040034095400559666666666660000000000000000000000000000000000000000000000000000000000000
00000880007777000000f00003c70000000252000044044055444440ddddddddddd0000000000000000000000000000000000000000000000000000000000000
00005550000000000000000000c00000000000640022121100330330000000000000000000000000000000000000000000000000000000000000000000000000
0005005000666000000880000cc10000000006460200001003003003000000000000000000000000000000000000000000000000000000000000000000000000
00050005060006000082880001cc00000000456020052000000bbb00000000000000000000000000000000000000000000000000000000000000000000000000
0005500007d7d7009100808000cc1000044454002050020009bbb9b0000000000000000000000000000000000000000000000000000000000000000000000000
008850007663667001822208001cc00044154000205050200bb9bbb0006660066600666000000000000000000000000000000000000000000000000000000000
088000008833367002882888000cc10041514000200550200b9bb9b000666dd666dd666000000000000000000000000000000000000000000000000000000000
8800000078836670002888800001cc00041440000200002000bb9bb00d666dd666dd666d00000000000000000000000000000000000000000000000000000000
5000000007ddd70000028800000060000044000000222200009bbb00dd666dd666dd666dd0000000000000000000000000000000000000000000000000000000
000ee000000dd0550dd0000000cc0000004400000000077000007700116661166611666110000000000000000000000000000000000000000000000000000000
00e77e000000dd15dd6000000ccccc00054450000008880000002770dd676dd676dd676dd0000000000000000000000000000000000000000000000000000000
0e7e77e000001dd006ff0000010cc100554555000007780000022290dd666dd666dd666dd0000000000000000000000000000000000000000000000000000000
e8ee77ee000a51dd00ff700001072100555554000088700000088890ddddddddddddddddd0000000000000000000000000000000000000000000000000000000
e288888e00baa00d000f770001777100054444000087800000099800ddddddddddddddddd0000000000000000000000000000000000000000000000000000000
0e8282e00bab000000007f0000127010044444400788000000899000666666666666666660000000000000000000000000000000000000000000000000000000
00e22e0005b000000000ff4000100010004544448777000000888000dddddd11111dddddd0000000000000000000000000000000000000000000000000000000
000ee000500000000000444000111110000444440880000000222000ddddddddddddddddd0000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777077700000777077700000777077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707070700700707070700700707007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707070700000707070700000707007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707070700700707070700700707007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777077700000777077700000777077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbb0bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb00b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bb0b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbb0b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000000000001111111111177111111111111111111111111111111111111111110000000000000000000000000000000111111111111111111111111111111
00000000000001111111111177111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000
00000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000
00000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000
00000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000
00000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000
00000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000006000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111100000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000
00000000000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000070000000000000
00000000000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000
00000000000000000001111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000
11111111111111118888888111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000
11111111111111188888888811111111111111111111111111111111111111111111111110000000000000000000000001001010000000000000000000000000
1111111111111118888ffff81111111111111111111111111111111111111111111111111000000000000000000000001311b1b1000000000000000000000000
111111111111111888f1ff18111110000000000010000000000000000000000001001010000000000000000000000000013b3310000000000000000000000000
111111111111111888fffff111111000000000018100000000000000000000001311b1b100000000000000000000000112888821100000000000000000000000
1111111111111111883333111111100000000018881000000000000000000000013b331000000000000000000001111778988887711110000000000000000000
11111111111111111171171111111000000000018100000000000000000000001288882100000000000000000017777778888987777771000000000011111111
11111666577777777777777777777775000010001000000000000000000000001898888100000000000000000177777118898881177777100000000011111111
00077776777777777777777777777777010141000000111111111111111111111888898111111111111111111011111012888821011111000000000011111111
000007667777ccccc777777ccccc7777151591000000111111111111111111111889888111111111111111111000000001288210000000000000000011111111
00000055777cccccccc77cccccccc777515191000000111111111111111111111688882111111171111111111000000000111100000000000000000011111111
0000066677cccccccccccccccccccc77515191000000111111111111111111111128821111111111111111111000000000000000000000000000000011111111
0007777677cc77ccccccccccccc7cc77151591000000111111111111111111111111111111111111111111111000000000111100000000000000000011111111
1111176677cc77cccccccccccccccc77010141000000111111111111111111111111111111111111111111111000000001888810000000000000000011111111
1111115577cccccccccccccccccccc77000010000000111111111111111111111111111111111111111111111000000018888881000000000000000011111111
1111166677cccccccccccccccccccc77550000000000111111111111111111111111111111111111111111111000000018788881000000000000000011111111
11177776777cccccccccccccccccc777667000000000111111111111111111111111111111111111111111111111111118888881111111111111111111111111
11111766777cccccccccccccccccc777677770000000000000000000000000001111111111111111111111111111111118888881111111111111111111111111
111111557777cccccccccccccccc7777666000000000000000000000000000001111111111111111111111111111111118888881111111111111111111111111
000006667777cccccccccccccccc7777550000000000000000000000000000001111111111111111111111111111111111888811111111111111111111111111
00077776777ccccccccccccccccc6777667000000000000000000000000000001111111111111111111111111111111111116111111111111111111111111111
00000766777cccccccccccccccccc777677770000000000000000000000000000000000000000000000000000000000000016100000000000000000000000000
0000005577cccccccccccccccccccc77666000000000000000000000000000000006000000000000000000000000000000016100000000000000000000000000
0000066677cccccccccccccccccccc77550000000000000000000000000000000000000000000000000000000000000000016100000000000001100000000000
00077776777cccccccccccccccccc777667000000000000000000000000000000000000000000000000000000000000000016100000000000115511000000000
00000766777cccccccccccccccccc777677771111111111111111111111111111111111111111111111110000000000000161000000000001555555100000000
000001557777cccccccccccccccc7777666111111111111111111111111111111499994111711171111110000000000000161000000000001519195100000000
000006667777cccccccccccccccc7777551111111111111111111111111111111151151111711171111110000000000000610000000000001599995100000000
11177776777cccccccccccccccccc777667111111111111111111111111111111115511116771677111110000000000000000000000000001555555100000000
11111766777cccccccccccccccccc777677771111111111111111111111111111151151156765676111110000000000000000000000000000151151000000000
1111115577cccccccccccccccccccc77666111111111111111111111111111111115511156665666111111111111111111111111000000000151661000000000
1111166677cccccccccccccccccccc77494949494949494911111111177777777777777777777771499999944999999449999994577777777777667777777775
11177776777cccccccccccccccccc777222222222222222211111111711117771111777111117777911111199111111991111119777777777767777777777777
11111766777cccccccccccccccccc77700042000000000000000000070cc777cccc777ccccc777079111111991111119911111197777ccccc777777ccccc7777
111111557777cccccccccccccccc777711421111111100000000000070c777cccc777ccccc777c07911111199111111991111119777cccccccc77cccccccc777
111116667777cccccccccccccccc777714211111111100000000000070777700077700000777000791111119911111199111111977cccccccccccccccccccc77
11177776777cccccccccccccccccc77742111111111100000000000077770000777000007770000791111119911111199111111977cc77ccccccccccccc7cc77
11111766777cccccccccccccccccc7772111111111110000000000007000000000000000000c000791111119911111199111111977cc77cccccccccccccccc77
1111115577cccccccccccccccccccc7711111111111100000000000070000000000000000000000749999994499999944999999477cccccccccccccccccccc77
0000066677cccccccccccccccccccc7711111111111100000000000070000000000000000000000711111111111117111111111177cccccccccccccccccccc77
00077776777cccccccccccccccccc7771111111111110000000000007000000c0000000000000007000000000000000000000000777cccccccccccccccccc777
00000766777cccccccccccccccccc77711111111111100000000000070000000000cc00000000007000000000000000000000000777cccccccccccccccccc777
000001557777cc7ccccccccccccc777711111111111100000070007070c00000000cc00000000c070000000000000000000000007777cccccccccccccccc7777
000006667777cccccccccccccccc77771111111111110000007000707000000000000000000000070000000000000000000000007777cccccccccccccccc7777
00077776777cccccccccccccccccc777000000000000000006770677700000000000000000000007000000000000000000000000777cccccccccccccccccc777
00000766777cccccccccccccccccc77700000000000000005676567670000000c000000000000007000000000000000000000000777cccccccccccccccccc777
0000005577cccccccccccccccccccc7700000000000000005666566670000000000000000000000700000000000000000000000077cccccccccccccccccccc77
1111166677cccccccccccccccccccc7711111111494949494949494970000000000000000000000700000000000000000000000077cccccccccccccccccccc77
1117777677ccccccccccc6cccccccc7711111111222222222222222270000000000000000000000700000000000000000000000077cccccccccccccccccccc77
1111176677cc7cccccccccccc77ccc77111111111111110000024000700000000000c0000000000700000000000000000000000077cc7cccccccccccc77ccc77
1111115577ccccccccccccccc77ccc771111111111111100000024007000000cc00000000000000700000000000000000000000077ccccccccccccccc77ccc77
11111666777cccccccc77cccccccc7771111111111111100000002407000000cc0000000000c0007000000000000000000000000777cccccccc77cccccccc777
000777767777ccccc777777ccccc777700000000000000000000002470c0000000000000000000070000000000000000000000007777ccccc777777ccccc7777
00000766777777777777777777777777000000000000000000000002700000000000000000000007000000000000000000000000777777777777777777777777
00000055577777777777777777777775000000001111111111111111177777777777777777777771111111111111000000000000577777777777777777777775
00000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00bbbbbbbbbb77bb777b777bbbbbbbbbb00000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00bbbbbbbbbbb7bb7b7b7b7bbbbbbbbbb00000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00bbbbbbbbbbb7bb7b7b7b7bbbbbbbbbb00000001111111111111111111111111111111111111111111111111111000000000000000000000000000000000000
00bbbbbbbbbbb7bb7b7b7b7bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbbbbbbb777b777b777bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0003030303131313130808080000000000030303031313131300000000000000000303030313131313000000000000000003030303131313130202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000570057005700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000343434343400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003a3a3a3a3a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000400000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c0102032a0000002b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c1112133b000000000000002c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c1112133b000000293900000000000000000000000057000000000000005700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c111213090a000506071919190102033b0000003c0102031212121212121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c1112130000391516170000001112133b0000003c1112130000000000000000000000001212120000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c212223000a0b25262700000021222339393939392122230000000000000000000000001212120000121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001020102030000000000000000000000000000001212120000121212000012121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000011121112130000000000000000000077000000001212120000121212000012121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000021222122231212121212121257001212121200001212120000121212000012121200001212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000121212121212121212121212121200001212120000121212000012121200001212121212121212120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000077000077000077000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000012121212121212121212121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000012121212121212121212121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
002000001d0401d0401d0301d020180401804018030180201b0301b02022040220461f0351f03016040160401d0401d0401d002130611803018030180021f061240502202016040130201d0401b0221804018040
00100000070700706007050110000707007060030510f0700a0700a0600a0500a0000a0700a0600505005040030700306003000030500c0700c0601105016070160600f071050500a07005050030510a0700a060
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
002000200a1400a1300a1201113011120111101b1401b13018152181421813213140131401313013120131100f1400f1300f12011130111201111016142161321315013140131301312013110131101311013100
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
0018002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
010c00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c002024450307102b4503071024440307002b44037700244203a7102b4203a71024410357102b410357101d45033710244503c7101d4403771024440337001d42035700244202e7101d4102e7102441037700
011800200c5700c5600c550000001157011560115500c5000c5700c5600f5710f56013570135600a5700a5600c5700c5600c550000000f5700f5600f550000000a5700a5600a5500f50011570115600a5700a560
001800200c5700c5600c55000000115701156011550000000c5700c5600f5710f56013570135600f5700f5600c5700c5700c5600c5600c5500c5300c5000c5000c5000a5000a5000a50011500115000a5000a500
000c0020247712477024762247523a0103a010187523a0103501035010187523501018750370003700037000227712277222762227001f7711f7721f762247002277122772227620070027771277722776200700
000c0020247712477024762247523a0103a010187503a01035010350101875035010187501870018700007001f7711f7701f7621f7521870000700187511b7002277122770227622275237012370123701237002
000c0000247712477024772247722476224752247422473224722247120070000700007000070000700007002e0002e0002e0102e010350103501033011330102b0102b0102b0102b00030010300123001230012
000c00200c3320c3320c3220c3220c3120c3120c3120c3020c3320c3320c3220c3220c3120c3120c3120c30207332073320732207322073120731207312073020a3320a3320a3220a3220a3120a3120a3120a302
000c00000c3300c3300c3200c3200c3100c3100c3103a0000c3300c3300c3200c3200c3100c3100c3103f0000a3300a3201333013320073300732007310113000a3300a3200a3103c0000f3300f3200f3103a000
00040000336251a605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000c00000c3300c3300c3300c3200c3200c3200c3100c3100c3100c31000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3310a3300332103320
001000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d36022370223702236022350223402232013300133001830018300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
001000102f65501075010753f615010753f6152f65501075010753f615010753f6152f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
0010000016270162701f2711f2701f2701f270182711827013271132701d2711d270162711627016270162701b2711b2701b2701b270000001b200000001b2000000000000000000000000000000000000000000
00080020245753057524545305451b565275651f5752b5751f5452b5451f5352b5351f5252b5251f5152b5151b575275751b545275451b535275351d575295751d545295451d535295351f5752b5751f5452b545
002000200c2650c2650c2550c2550c2450c2450c2350a2310f2650f2650f2550f2550f2450f2450f2351623113265132651325513255132451324513235132351322507240162701326113250132420f2600f250
00100000072750726507255072450f2650f2550c2750c2650c2550c2450c2350c22507275072650725507245072750726507255072450c2650c25511275112651125511245132651325516275162651625516245
000800201f5702b5701f5402b54018550245501b570275701b540275401857024570185402454018530245301b570275701b540275401d530295301d520295201f5702b5701f5402b5401f5302b5301b55027550
00100020112751126511255112451326513255182751826518255182451d2651d2550f2651824513275162550f2750f2650f2550f2451126511255162751626516255162451b2651b255222751f2451826513235
00100010010752f655010753f6152f6553f615010753f615010753f6152f655010752f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000100107501075010753f6152f6553f6153f61501075010753f615010753f6152f6553f6152f6553f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
002000002904029040290302b031290242b021290142b01133044300412e0442e03030044300302b0412b0302e0442e0402e030300312e024300212e024300212b0442e0412b0342e0212b0442b0402903129022
000800202451524515245252452524535245352454524545245552455524565245652457500505245750050524565005052456500505245550050524555005052454500505245350050524525005052451500505
000800201f5151f5151f5251f5251f5351f5351f5451f5451f5551f5551f5651f5651f575000051f575000051f565000051f565000051f555000051f555000051f545000051f535000051f525000051f51500005
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
002000200c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f2350c2650c2550c2450c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f235112651125511245
002000001327513265132551324513235112651125511245162751626516255162451623513265132551324513275132651325513245132350f2650f2550f2450c25011231162650f24516272162520c2700c255
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5753c5453c5353c5253c5153c51537555375453a5753a5553a5453a5353a5253a5253a5153a51535575355553554535545355353553535525355253551535515335753355533545335353352533515
00100000355753555535545355353552535525355153551537555375353357533555335453353533525335253a5753a5453a5353a5253a5153a51533575335553354533545335353353533525335253351533515
001000200c0600c0300c0500c0300c0500c0300c0100c0000c0600c0300c0500c0300c0500c0300c0100f0001106011030110501103011010110000a0600a0300a0500a0300a0500a0300a0500a0300a01000000
001000000506005030050500503005010050000706007030070500703007010000000f0600f0300f010000000c0600c0300c0500c0300c0500c0300c0500c0300c0500c0300c010000000c0600c0300c0100c000
0010000003625246150060503615246251b61522625036150060503615116253361522625006051d6250a61537625186152e6251d615006053761537625186152e6251d61511625036150060503615246251d615
00100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000302453020530235332252b23530205302253020530205302253020530205302153020530205302152b2452b2052b23527225292352b2052b2252b2052b2052b2252b2052b2052b2152b2052b2052b215
__music__
01 150a5644
00 0a160c44
00 0a160c44
00 0a0b0c44
00 14131244
00 0a160c44
00 0a160c44
02 0a111244
00 41424344
00 41424344
01 18191a44
00 18191a44
00 1c1b1a44
00 1d1b1a44
00 1f211a44
00 1f1a2144
00 1e1a2244
02 201a2444
00 41424344
00 41424344
01 2a272944
00 2a272944
00 2f2b2944
00 2f2b2c44
00 2f2b2944
00 2f2b2c44
00 2e2d3044
00 34312744
02 35322744
00 41424344
01 3d7e4344
00 3d7e4344
00 3d4a4344
02 3d3e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 383a3c44
02 393b3c44

