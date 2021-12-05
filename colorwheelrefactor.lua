include 'lib/core'
include 'lib/norns'
include 'lib/grid'
include 'lib/algebra'
lattice = require("lib/lattice")

g = grid.connect()

       gate_range = {}
       gate_field = {}
       gate_display = {}
       gate_prob = {}
       range_display = {}

velocity_values = { 0, 32, 64, 96, 127 }
length_values = {1/4, 1/2, 1, 2, 4}

function key(n,z)
  if n == 3 and z == 1 then
    my_lattice:toggle()
  else if n == 2 and z == 1 then
    randomize()
    print('randomizing!')
  end
  end
  seqorlive.seq:update()
end

function down_a_fifth()
   params:set('transpose', (params:get('transpose') + 5) % 12)
end

function up_a_fifth()
    params:set('transpose', (params:get('transpose') + 7) % 12)
end

function return_to_root()
    params:set('transpose', 0)
    print("Live transposition nullified!")
end

function restart_sequences()
  for key,value in pairs(note_traits.current) do
    for i = 1,4,1 do
      params:set("current " ..key.. " step " ..i, 0)
    end
  end
  print('back to the one!')
  seqorlive.seq:update()
end

function randomize()
  for i = 1,4,1 do
    for key,value in pairs(note_traits.current) do
      params:set(key.. " div " ..i, math.random(1,6))
      params:set(key.. " sequence start " ..i, math.random(1,8))
      params:set(key.. "sequence end " ..i, math.random(params:get(key.. " sequence start " ..i) + 3, 16))
      params:set("offset " ..i, (params:get("offset " ..i) + math.random(-1,1) - 1) % 5 + 1)
      params:set("transposition " ..i, ((params:get("transposition " ..i) + (math.random(-1, 1)) + 2) % 5 - 2))
    end
    for j = 1,16,1 do
      params:set("gate " ..i .." "..j, math.random(0, 1))
      params:set("interval " ..i .." "..j, math.random (1, 5))
      params:set("octave " ..i .." "..j, math.random (1, 3))
      params:set("velocity " ..i .." "..j, velocity_values[math.random (2, 5)])
      params:set("length " ..i .." "..j, length_values[math.random (2, 5)])
    end
  end
end

function clock_sync()
  for key,value in pairs(note_traits.current) do
    for i = 1,4,1 do
      params:set(key.. " div " ..i, 1)
    end
  end
  print('clocks aligned!')
end

seqorlive = nest_ {
    meta = _grid.toggle {
      x = 16,
      y = 8,
      level = {4, 15}
},

seq = nest_ {
    enabled = function(self)
        return (seqorlive.meta.value == 0)
    end,

    loop_mod = _grid.momentary {
        x = 12,
        y = 8,
        level = {4, 15 } },

    time_mod = _grid.momentary {
        x = 13,
        y = 8,
        level = {4, 15} },

    prob_mod = _grid.momentary {
        x = 14,
        y = 8,
        level = {4, 15} },

    tab = _grid.number {
        x = {6, 10},
        y = 8,
        level = {4, 15} },

    track = _grid.number {
        x = {1, 4},
        y = 8,
        level = {4, 15},
        enabled = function(self)
            return (seqorlive.seq.loop_mod.value == 0)
        end
        },

      track_mute = nest_(4):each(

        function(i,v)

          return _grid.toggle {
              x = i,
              y = 8,
              level =
                function(self)
                  if params:get('track active ' ..i) == 1 then return 7
                    else return 2 end
                end,

                controlspec = params:lookup_param('track active ' ..i).controlspec,
                value = function() return params:get('track active ' ..i) end,
                action = function(s,v,x) params:set('track active ' ..i, v) end,

                enabled = function(self)
                  return (seqorlive.seq.loop_mod.value == 1) end,}
          end),
                          
      gate_tab = nest_ {
        enabled = 
          function(self)
            return (seqorlive.seq.tab.value == 1 and
                    seqorlive.seq.time_mod.value == 0)
          end,

        gate_page = nest_(4):each(function(i,v)

          gate_range[i] = _grid.range {
            x = {1, 16},
            y = i,
            z = -1,
            level = 4,

            value =

              function()
                return{params:get('gate sequence start ' ..i), params:get('gate sequence end ' ..i)}
              end,

            action =

              function(s, v)
                params:set('gate sequence start ' ..i, v[1])
                params:set('gate sequence end ' ..i, v[2])
              end,

            enabled =

              function(self) return (seqorlive.seq.loop_mod.value == 1 and
                                    seqorlive.seq.time_mod.value == 0 and
                                    seqorlive.seq.prob_mod.value == 0)
              end }

          gate_field[i] = nest_(16):each(function(j,v)

            return _grid.toggle {
              x = j,
              y = i,
              level = function(self)
                if j == params:get('current gate step ' ..i)
                  then return 15
                elseif params:get('gate ' ..i.. ' ' ..j) == 1 then
                  if j >= params:get('gate sequence start ' ..i)
                    then if j <= params:get('gate sequence end ' ..i) then
                      return 10
                    end
                  else return 2
                end
              else return 0
              end

              if params:get('gate ' ..i.. ' ' ..j) == 1 then
                if j > params:get('gate sequence end ' ..i) then
                  return 2
                end
              end
            end,

            controlspec = params:lookup_param('gate ' ..i.. ' ' ..j).controlspec,
            value = function() return params:get('gate ' ..i.. ' ' ..j) end,
            action = function(s,v) params:set('gate ' ..i.. ' ' ..j) end,

            enabled = function(self)
              return (seqorlive.seq.loop_mod.value == 0 and
                      seqorlive.seq.time_mod.value == 0 and
                      seqorlive.seq.prob_mod.value == 0)
              end,}end)

          range_display[i] = nest_(16):each(function(j,v)

              return _grid.toggle {
                x = j,
                y = i,
                value = 1,
                input = false,

              level = function(self)
                if i == params:get('current gate step ' ..i) then return 15
                elseif params:get('gate ' ..i.. ' ' ..j) then return 0
                elseif j >= params:get('gate sequence start ' ..i) then
                  if j <= params:get('gate sequence end ' ..i) then
                  return 4
                else return 0
                end end end,

              enabled = function(self)
              return (seqorlive.seq.loop_mod.value == 0 and
                      seqorlive.seq.time_mod.value == 0 and
                      seqorlive.seq.prob_mod.value == 0)
                    end,}end) end )
                  } --gate tab bracket
                } --seq tab bracket
              } --whole nest bracket





  function redraw()
      screen.move(0, 10)
      screen.font_size(8)
      screen.text("You are now spinning" )
      screen.move(20,37)
      screen.font_size(16)
      screen.text("colorwheel")
      screen.move(0, 60)
      screen.font_size(8)
      screen.text("the wheeeeeeeeeeel of color.")
      screen.update()
  end

seqorlive:connect { g = grid.connect()}
function init()
  screen.clear()
  algebra.init()
  my_lattice = lattice:new()
  ppqn = 16

  local transport = {}
  for key,value in pairs(note_traits.current) do
      transport[key] = {}
      for i = 1,4,1 do

        transport[key][i] = my_lattice:new_pattern{
          action = function(t) trait_tick(key, i)
          division = params:get(key.. ' div ' ..i) / 16
  end }
      
    end end

refresh = my_lattice:new_pattern{
  action = function(t) seqorlive.seq:update()
    end,
  division = 1 / 32 }

meta_counter = 0
my_lattice:start()
my_lattice:toggle()
restart_sequences()
seqorlive:init()
seqorlive.seq:update()
end
