
kAIA_nerfing = false
kAIA_target_around_corner_refresh = 0.2

-- Optimizations
-- Number of time the direction is updated per sec (and pathing checked)
kAIA_BotMotion_tick = 6

-- Shared with all lifeforms
kAIA_sneak_dist = 30
kAIA_engage_dist = 10
kAIA_attack_dist = 4

-- Min distance to be from the threat before sneaking again (otherwise continue to retreat)
kAIA_retreat_dist = 8

kAIA_sound_dist = 30

-- [0-1], chances for an alien to trigger a jump if in the combat state
kAIA_jump_in_combat = 0.08

-- Control how long an alien is moving forward after trying to bite, and before turning toward the target again
-- Delay in second. (the greater the easier to dodge). This can be seen as reaction time in combat.
kAIA_attack_inertia_min = kAIA_nerfing and 0.15 or 0
kAIA_attack_inertia_max = kAIA_nerfing and 0.50 or 0

-- Deviation of the bite from the marine (the greater, the more often an attack will miss)
kAIA_attack_acc_min_deviation = kAIA_nerfing and 0.3 or 0
kAIA_attack_acc_max_deviation = kAIA_nerfing and 1.0 or 0

-- Skulk
kAIA_wall_jump = true

-- Gorge
-- Lerk
-- Fade
-- Onos


function AIA_SetDesiredViewTarget_deviation(deviation_min, deviation_max)
   local random = math.random
   local deviation_min = kAIA_attack_acc_min_deviation
   local deviation_max = kAIA_attack_acc_max_deviation

   -- Random deviation
   local deviation_x = deviation_min + (deviation_max - deviation_min) * random()
   local deviation_y = deviation_min + (deviation_max - deviation_min) * random()
   local deviation_z = deviation_min + (deviation_max - deviation_min) * random()

   -- Vector(x,y,z) can go both on negative and positive (random direction)
   deviation_x = deviation_x * (1 + -2 * random(0, 1))
   deviation_y = deviation_y * (1 + -2 * random(0, 1))
   deviation_z = deviation_z * (1 + -2 * random(0, 1))

   return Vector(deviation_x, deviation_y, deviation_z)
end