package.path = package.path .. ";/Users/stefanopeverelli/Documents/usi/6ths/Bachelor Project/scripts/?.lua;"

require 'point'

-- Convert a given table into a 3d vector
toPoint = function(t)
    local p = Point(t[1], t[2], t[3])
    return p
end

-- Get the Shape Bounding Box x y z coordinates
getShapeMaxValues = function(shape_handle)
    local localxMinMax = {0, 0}
    local localyMinMax = {0, 0}
    local localzMinMax = {0, 0}
    result, localxMinMax[1] = simGetObjectFloatParameter(shape_handle, 15)
    result, localyMinMax[1] = simGetObjectFloatParameter(shape_handle, 16)
    result, localzMinMax[1] = simGetObjectFloatParameter(shape_handle, 17)
    result, localxMinMax[2] = simGetObjectFloatParameter(shape_handle, 18)
    result, localyMinMax[2] = simGetObjectFloatParameter(shape_handle, 19)
    result, localzMinMax[2] = simGetObjectFloatParameter(shape_handle, 20)
    local xSize = localxMinMax[2] - localxMinMax[1]
    local ySize = localyMinMax[2] - localyMinMax[1]
    local zSize = localzMinMax[2] - localzMinMax[1]
    return {xSize, ySize, zSize}
end

-- Used to escape "'s by toCSV
escapeCSV = function (s)
    if string.find(s, '[,"]') then
      s = '"' .. string.gsub(s, '"', '""') .. '"'
    end
    return s
end

-- Convert from table to CSV string
toCSV = function (tt)
    local s = ""
    for _,p in ipairs(tt) do
        s = s .. ", " .. escapeCSV(p)
    end
    return string.sub(s, 3)      -- remove first comma
end

toScreenCoords = function (point, x_max, x_min, y_max, y_min)
    xs = (1 / (x_max - x_min)) * (point[1] - x_min)
    ys = (1 / (y_max - y_min)) * (point[2] - y_max)
    p = {xs, ys, 0}
    return toPoint(p)
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

saveData = function (traversed)
    if not saved then
        local record = {
            traversed,
            round(elapsed_time, 3),
            Point.__tostring(toScreenCoords(initial_point_pos, max_x / 2, -max_x / 2, max_y / 2, -max_y / 2 ), true),
            Point.__tostring(toScreenCoords(initial_robot_pos, max_x / 2, -max_x / 2, max_y / 2, -max_y / 2 ), true),
            Point.__tostring(toScreenCoords(final_robot_pos, max_x / 2, -max_x / 2, max_y / 2, -max_y / 2 ), true),
        }
        output_file = io.open("/Users/stefanopeverelli/Documents/usi/6ths/Bachelor Project/data/results/results.csv", "a")
        io.output(output_file)
        io.write(toCSV(record) .. "\n")
        io.close(output_file)
        saved = true
    end
end

-- Convert the robot orientation into a directional vector
toDirection = function(gamma)
    local p = Point(-math.sin(gamma), math.cos(gamma), 0)
    return p
end



if (sim_call_type==sim_childscriptcall_initialization) then
    robot_handle = simGetObjectHandle('ROBOT')
    goal_point_handle = simGetObjectHandle('GOAL')
    heightfield_handle = simGetObjectHandle('heightfield')
    steer_handle = simGetObjectHandle('steer_joint')
    motor_handle = simGetObjectHandle('motor_joint')
    fl_brake_handle = simGetObjectHandle('fl_brake_joint')
    fr_brake_handle = simGetObjectHandle('fr_brake_joint')
    bl_brake_handle = simGetObjectHandle('bl_brake_joint')
    br_brake_handle = simGetObjectHandle('br_brake_joint')

    --wheel radius:         0.09
    --wheel base:             0.6
    --wheel track:             0.35
    --maximum steering rate:     70 deg/sec

    --the maximum steer angle 30 degree
    max_steer_angle = 0.5235987

    --the maximum torque of the motor
    motor_torque = 60

    -- Read the robot velocity
    dVel = simGetStringParameter(sim_stringparam_app_arg2)

    if (dVel == "") then
        dVel = 1.0
    end

    dSteer = 0.1

    --input steer
    steer_angle = 0

    --input velocity
    motor_velocity = dVel*10

    --input brake
    brake_force = 0

    -- Define an angle tolerance
    epsilon = 0.02

    -- Define a radius for the area of interest
    radius = 0.7

    traversed = 0

    saved = false

    -- Read the maximum time for the simulation
    max_sim_time = simGetStringParameter(sim_stringparam_app_arg3)

    if (max_sim_time == "") then
        max_sim_time = 10
    end

    -- Compute the plane normal between two arbitrary vectors
    plane_normal = Point(1,1,0) ^ Point(1,2,0)
    plane_normal = Point.normalize(plane_normal)

    -- Get the goal position point
    goal_point_pos = toPoint(simGetObjectPosition(goal_point_handle, -1))

    -- Get the initial goal point position
    initial_point_pos = goal_point_pos

    -- Get the initial robot position
    initial_robot_pos = toPoint(simGetObjectPosition(robot_handle, -1))

    -- Get the initial robot orientation
    robot_direction = toDirection(simGetObjectOrientation(robot_handle, -1)[3])


    -- The final position is initialized as the start position 
    final_point_pos = initial_point_pos

    max_x = getShapeMaxValues(heightfield_handle)[1]
    max_y = getShapeMaxValues(heightfield_handle)[2]

end

-- Check if the robot has reached the goal
isInAreaOfInterest = function(robot_pos, goal_point_pos)
    -- Compute vector from goal point to robot position
    distance_vector = goal_point_pos - robot_pos
    distance = Point.len(distance_vector)
    if (distance <= radius) then
        return true
    end

    return false
end


-- Correct the direction of the robot in order to reach the goal point
correctSteer = function ()
    -- Get current robot orientation
    robot_dir = toDirection(simGetObjectOrientation(robot_handle, -1)[3])

    -- Get current robot position
    robot_pos = toPoint(simGetObjectPosition(robot_handle,-1))

    -- Compute the ideal path to follow
    goal_point_pos = toPoint(simGetObjectPosition(goal_point_handle, -1))
    local ideal_path = -robot_pos + goal_point_pos

    -- Compute the signed angle between the robot_direction and the ideal path to reach the goal
    local angle = math.acos(Point.normalize(robot_dir) .. Point.normalize(ideal_path))
    local cross = robot_dir ^ ideal_path
    local c = cross .. plane_normal

    if (c < 0) then
        angle = -angle
    end

    return angle
end

if (sim_call_type == sim_childscriptcall_cleanup) then

end

if (sim_call_type == sim_childscriptcall_actuation) then
    --current steer pos
    steer_pos = simGetJointPosition(steer_handle, -1);
    --current angular velocity of back left wheel
    bl_wheel_velocity = simGetObjectFloatParameter(bl_brake_handle,sim_jointfloatparam_velocity)
    --current angular velocity of back right wheel
    br_wheel_velocity = simGetObjectFloatParameter(br_brake_handle,sim_jointfloatparam_velocity)
    --average angular velocity of the back wheels
    rear_wheel_velocity = (bl_wheel_velocity+br_wheel_velocity)/2
    --linear velocity
    linear_velocity = rear_wheel_velocity*0.09

    elapsed_time = simGetSimulationTime()

    if (elapsed_time >= tonumber(max_sim_time)) then
        final_robot_pos = toPoint(simGetObjectPosition(robot_handle, -1))
        saveData(traversed)
        simStopSimulation()
    end

    angle = correctSteer()
    if (math.abs(angle) >= epsilon) then
        steer_angle = angle
        angle = correctSteer()
    else
        steer_angle = 0
    end

    if(isInAreaOfInterest(robot_pos, goal_point_pos)) then
        brake_force = 100
        motor_velocity = 0
        simSetJointForce(motor_handle, 0)
        final_robot_pos = toPoint(simGetObjectPosition(robot_handle, -1))
        traversed = 1
        saveData(traversed)
        simStopSimulation()
    end

    if (math.abs(motor_velocity) < dVel * 0.1) then
        brake_force = 100
    else
        brake_force = 0
    end

    --set maximum steer angle
    if (steer_angle > max_steer_angle) then
        steer_angle = max_steer_angle
    end
    if (steer_angle < - max_steer_angle) then
        steer_angle = -max_steer_angle
    end

    simSetJointTargetPosition(steer_handle, steer_angle)

    --brake and motor can not be applied at the same time
    if(brake_force > 0) then
        simSetJointForce(motor_handle, 0)
    else
        simSetJointForce(motor_handle, motor_torque)
        simSetJointTargetVelocity(motor_handle, motor_velocity)
    end

    simSetJointForce(fr_brake_handle, brake_force)
    simSetJointForce(fl_brake_handle, brake_force)
    simSetJointForce(bl_brake_handle, brake_force)
    simSetJointForce(br_brake_handle, brake_force)
end
