include 'lib/algebra'
lattice = require("lib/lattice")

g = grid.connect()

function init()
  grid_dirty = true
  clock.run(grid_redraw_clock)
end

function grid_redraw_clock()
  while true do
    clock.sleep(1/30)
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end
  end
end

navigation_bar = {
  ["displayed_track"] = 1,
  ["displayed_trait"] = 1,
  ["mod_keys"] = {0,0,0},
  ["sequence_or_live"] = 0,
  ["backlights"] = {5,5,5,5,0,5,5,5,5,5,0,5,5,5,0,5}
}

velocity_values = { 0, 32, 64, 96, 127 }
length_values = {.25, .5, 1, 2, 4}

function grid_redraw()
  set_up_the_nav_bar()
  if navigation_bar.sequence_or_live == 0 then -- seq page should be under this
    if navigation_bar.displayed_trait == 1 then
      set_up_the_gate_page()
    end
    if navigation_bar.displayed_trait == 2 then
      set_up_the_interval_page(navigation_bar.displayed_track)
    end
    if navigation_bar.displayed_trait == 3 then
      set_up_the_octave_page(navigation_bar.displayed_track)
    end
    if navigation_bar.displayed_trait == 4 then
      set_up_the_velocity_page(navigation_bar.displayed_track)
    end
    if navigation_bar.displayed_trait == 5 then
      set_up_the_length_page(navigation_bar.displayed_track)
    end
  end -- seq page should be above this
  g:refresh()
end

function randomize()
  for i = 1,4,1 do
    for key,value in pairs(note_traits.current) do
      params:set(key.. " div " ..i, math.random(1,6))
      params:set(key.. " sequence start " ..i, math.random(1,8))
      params:set(key.. " sequence end " ..i, math.random(params:get(key.. " sequence start " ..i) + 3, 16))
      params:set("offset " ..i, (params:get("offset " ..i) + math.random(-1,1) - 1) % 5 + 1)
      params:set("transposition " ..i, ((params:get("transposition " ..i) + (math.random(-1, 1)) + 2) % 5 - 2))
    end
    for j = 1,16,1 do
      params:set("gate " ..i .." "..j, math.random(0, 1))
      params:set("interval " ..i .." "..j, math.random (1, 5))
      params:set("octave " ..i .." "..j, math.random (1, 3))
      params:set("velocity " ..i .." "..j, velocity_values[math.random (2, 5)])
      params:set("length " ..i .." "..j, length_values[math.random (1, 5)])
    end
  end
end

function key(n,z)
  if n == 2 and z == 1 then
    randomize()
    print('randomizing!')
  end
  grid_dirty = true
end

function g.key(x,y,z)
  
  if x == 16 and y == 8 and z == 1 then -- toggle sequence and live
    sequence_or_live_toggle()
  end
  
  if navigation_bar.sequence_or_live == 0 then -- this is all for the sequencer pages!
    
    if y == 8 then -- this is all for the seq nav bar!
      if x <= 4 then
        navigation_bar.displayed_track = x
      elseif x <= 10 and x >= 6 then
        navigation_bar.displayed_trait = x - 5
      end
    end
    
    if navigation_bar.displayed_trait == 1 then
      if y <= 4 then 
        gate_toggle(x, y, z)
      end
    end
    
    if navigation_bar.displayed_trait == 2 then
      if y <= 5 then
        change_interval(x, y, z, navigation_bar.displayed_track)
      end
    end
    
    if navigation_bar.displayed_trait == 3 then
      if y >= 2 and y <= 5 then
        change_octave(x,y,z,navigation_bar.displayed_track)
      end

      
      if y == 1 and x <= 6 then
        change_track_octave(x,z,navigation_bar.displayed_track)
      end
      
    end
      
    if navigation_bar.displayed_trait == 4 then
      if y <= 5 then
        change_velocity(x,y,z,navigation_bar.displayed_track)
      end
    end
    
    if navigation_bar.displayed_trait == 5 then
      if y <= 5 then
        change_length(x,y,z,navigation_bar.displayed_track)
      end
    end
  
  end -- all seq stuff should be above this line
grid_dirty = true
end


function set_up_the_nav_bar()
  g:all(0)
  if navigation_bar.sequence_or_live == 0 then
  for i = 1,16,1 do
    g:led(i, 8, navigation_bar.backlights[i])
  end
    g:led(navigation_bar.displayed_track, 8, 10)
    g:led(navigation_bar.displayed_trait + 5, 8, 10)
  end
  g:led(16, 8, 5)
end

function sequence_or_live_toggle()
  if navigation_bar.sequence_or_live == 0 then
    navigation_bar.sequence_or_live = 1
  else navigation_bar.sequence_or_live = 0
  end
end

function set_up_the_gate_page()
  for y = 1,4,1 do
    for x = 1,16,1 do
      if x >= params:get('gate sequence start ' ..y) and x <= params:get('gate sequence end ' ..y) then
        g:led(x,y,6)
      end
      if params:get('gate ' ..y.. ' ' ..x) == 1 then
        if x >= params:get('gate sequence start ' ..y) and x <= params:get('gate sequence end ' ..y) then
          g:led(x,y,13)
        else
          g:led(x,y,2)
        end
      end
    end
  end
end

function set_up_the_interval_page(track)
  for x = 1,16,1 do
    g:led(x, 6 - params:get('interval ' ..track.. ' ' ..x), 15)
  end
  for x = params:get('interval sequence start ' ..track), params:get('interval sequence end ' ..track) do
    g:led(x, 6, 8)
  end
  g:led(params:get('interval div ' ..track), 7, 8)
end

function set_up_the_octave_page(track)
  for x = 1,6 do
    g:led(x, 1, 6)
  end
  g:led(params:get('track octave ' ..track), 1, 12)
  for x = 1,16 do
    g:led(x, 6 - params:get('octave ' ..track.. ' ' ..x), 15)
  end
  for x = params:get('octave sequence start ' ..track), params:get('octave sequence end ' ..track) do
    g:led(x, 6, 8)
  end
  g:led(params:get('octave div ' ..track), 7, 8)
end

function set_up_the_velocity_page(track)
  local k = {}
  for x = 1,16,1 do
    k[x] = get_key_for_value( velocity_values, params:get('velocity ' ..track.. ' ' ..x))
    g:led(x, 6 - k[x], 15)
  end
  for x = params:get('velocity sequence start ' ..track), params:get('velocity sequence end ' ..track) do
    g:led(x, 6, 8)
  end
  g:led(params:get('velocity div ' ..track), 7, 8)
end

function set_up_the_length_page(track)
  local k = {}
  for x = 1,16,1 do
    k[x] = get_key_for_value( length_values, params:get('length ' ..track.. ' ' ..x))
    g:led(x, 6 - k[x], 15)
  end
  for x = params:get('length sequence start ' ..track), params:get('length sequence end ' ..track) do
    g:led(x, 6, 8)
  end
  g:led(params:get('length div ' ..track), 7, 8)
end
  
function gate_toggle(x,y,z)
  if z == 1 then
    if params:get('gate ' ..y.. ' ' ..x) == 1 then
      params:set('gate ' ..y.. ' ' ..x, 0)
    else
      params:set('gate ' ..y.. ' ' ..x, 1)
    end
  end
end

function change_interval(x,y,z,track)
  if z == 1 then
    params:set(('interval ' ..track.. ' ' ..x), 6 - y)
  end
end

function change_octave(x,y,z,track)
  if z == 1 then
    params:set(('octave ' ..track.. ' ' ..x), 6 - y)
  end
end

function change_track_octave(x,z,track)
  if z == 1 then
    params:set(('track octave ' ..track), x)
  end
end

function change_velocity(x,y,z,track)
    if z == 1 then
    params:set(('velocity ' ..track.. ' ' ..x), velocity_values[6 - y])
  end
end

function change_length(x,y,z,track)
    if z == 1 then
    params:set(('length ' ..track.. ' ' ..x), length_values[6 - y])
    print(6 - y, length_values[6 - y])
  end
end
  
function get_key_for_value( t, value )
  for k,v in pairs(t) do
    if v==value then return k end
  end
  return nil
end