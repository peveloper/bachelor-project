-- Main script that loads the default scenario to handle simulations with a given heighfield

package.path = package.path .. ";/Users/stefanopeverelli/Documents/usi/6ths/Bachelor Project/scripts/?.lua;"
require 'point'

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

-- Compute a random coordinate between the bounding box of the shape
getRandomCoordinate = function(max)
    -- max is decremented to avoid the car to be place on the border
    return math.random() + math.random(-(max/2) +2 ,  (max/2) -2)
end

-- Place the robot in a suitable position
placeRobot = function(x, y, z)
    robot_position = {getRandomCoordinate(x), getRandomCoordinate(y), z}
    simSetObjectPosition(robot_handle, -1, robot_position)
end

-- Check if a point is contained in the plane
-- x and y are the point's 2d coordinates and max_x and max_ y are the bounding plane coordinates
isInPlane = function(coords, max_x, max_y)
    if(coords[1] <= (max_x/2) -2 and coords[1] >= -(max_x/2) +2) and (coords[2] <= (max_y/2) -2 and coords[2] >= -(max_y/2) +2) then
        return true
    end

    return false
end

-- Convert a given table into a 3d vector
toPoint = function(t)
    local p = Point(t[1], t[2], t[3])
    return p
end

-- Convert the robot orientation into a directional vector
toDirection = function(gamma)
    local p = Point(-math.sin(gamma), math.cos(gamma), 0)
    return p
end

-- Place the goal point at distance d in front of the robot
placePoint = function(d, robot_direction, robot_position)
    return (d * robot_direction) + robot_position
end

-- Initialization part (executed just once, at simulation start) ---------
if (sim_call_type == sim_mainscriptcall_initialization) then
    simOpenModule(sim_handle_all)
    simHandleGraph(sim_handle_all_except_explicit, 0)

    -- Get heightfield bounding box information
    heightfield_handle = simGetObjectHandle('heightfield')
    max_x = getShapeMaxValues(heightfield_handle)[1]
    max_y = getShapeMaxValues(heightfield_handle)[2]
    max_z = getShapeMaxValues(heightfield_handle)[3]

    -- Construct the goal point
    intParams = {20, 0, 0}
    floatParams = {0.2, 0, 0}
    simCreatePath(1, intParams, floatParams, nil)
    path_handle = simGetObjectHandle('Path', -1)
    ctrlPoint1 = {0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1}
    ctrlPoint2 = {0, 0, max_z, 0, 0, 0, 1, 0, 0, 1, 1}
    simInsertPathCtrlPoints(path_handle, 0, 0, 1, ctrlPoint1);
    simInsertPathCtrlPoints(path_handle, 0, 0, 1, ctrlPoint2);
    simSetObjectName(path_handle, 'GOAL')

    -- Load the offroad mantra model with its associated script (controller)
    simLoadModel('/Users/stefanopeverelli/Documents/usi/6ths/Bachelor Project/models/offroad.ttm')
    robot_handle = simGetObjectHandle('ROBOT')

    -- Robot pose
    placeRobot(max_x, max_y, max_z)
    robot_position = simGetObjectPosition(robot_handle, -1)
    robot_position[3] = 0
    robot_position = toPoint(robot_position)
    robot_direction = toDirection(simGetObjectOrientation(robot_handle, -1)[3])

    -- Goal point pose at distance d from the robot (NOTE distance cannot be bigger than the sqrt((max_x - 4) ^ 2 + (max_y - 4)^ 2) - 2)
    distance = 6
    point_position = {Point.get(placePoint(distance, robot_direction, robot_position))}

    while not (isInPlane(point_position, max_x, max_y)) do
        placeRobot(max_x, max_y, max_z)
        robot_position = simGetObjectPosition(robot_handle, -1)
        robot_position[3] = 0
        robot_position = toPoint(robot_position)
        robot_direction = toDirection(simGetObjectOrientation(robot_handle, -1)[3])
        point_position = {Point.get(placePoint(distance, robot_direction, robot_position))}
    end

    simSetObjectPosition(path_handle, -1, point_position)
end

-- Regular part (executed at each simulation step) -----------------------
if (sim_call_type == sim_mainscriptcall_regular) then
    -- "Actuation"-part --
    simResumeThreads(sim_scriptthreadresume_default)
    simResumeThreads(sim_scriptthreadresume_actuation_first)
    simLaunchThreadedChildScripts()
    simHandleChildScripts(sim_childscriptcall_actuation)
    simResumeThreads(sim_scriptthreadresume_actuation_last)
    simHandleCustomizationScripts(sim_customizationscriptcall_simulationactuation)
    simHandleModule(sim_handle_all, false)
    simHandleJoint(sim_handle_all_except_explicit, simGetSimulationTimeStep()) -- DEPRECATED
    simHandlePath(sim_handle_all_except_explicit, simGetSimulationTimeStep()) -- DEPRECATED
    simHandleMechanism(sim_handle_all_except_explicit)
    simHandleIkGroup(sim_handle_all_except_explicit)
    simHandleDynamics(simGetSimulationTimeStep())
    simHandleVarious()
    simHandleMill(sim_handle_all_except_explicit)

    -- "Sensing"-part --
    workThreadCount = simGetInt32Parameter(sim_intparam_work_thread_count)
    coreCount = simGetInt32Parameter(sim_intparam_core_count)
    if (workThreadCount < 0) then
        workThreadCount = coreCount -- auto setting: thread count = core count
        if (workThreadCount < 2) then
            workThreadCount = 0 -- turn work threads off if less than 2 cores
        end
    end
    simEnableWorkThreads(workThreadCount) -- thread count can be changed on-the-fly.
    startTime1 = simGetSystemTimeInMilliseconds()
    simHandleCollision(sim_handle_all_except_explicit)
    simHandleDistance(sim_handle_all_except_explicit)
    simHandleProximitySensor(sim_handle_all_except_explicit)
    startTime2 = simGetSystemTimeInMilliseconds()
    simHandleVisionSensor(sim_handle_all_except_explicit)
    timeDiff2 = simGetSystemTimeInMilliseconds(startTime2)
    simWaitForWorkThreads()
    timeDiff = simGetSystemTimeInMilliseconds(startTime1)-timeDiff2
    if (workThreadCount == 0) then
        timeDiff = 0
    end
    simSetInt32Parameter(sim_intparam_work_thread_calc_time_ms, timeDiff)
    simResumeThreads(sim_scriptthreadresume_sensing_first)
    simHandleChildScripts(sim_childscriptcall_sensing)
    simResumeThreads(sim_scriptthreadresume_sensing_last)
    simHandleCustomizationScripts(sim_customizationscriptcall_simulationsensing)
    simHandleModule(sim_handle_all, true)
    simResumeThreads(sim_scriptthreadresume_allnotyetresumed)
    simHandleGraph(sim_handle_all_except_explicit, simGetSimulationTime()+simGetSimulationTimeStep())
end

-- Clean-up part (executed just once, before simulation ends) ------------
if (sim_call_type == sim_mainscriptcall_cleanup) then
    simEnableWorkThreads(0)
    simResetMilling(sim_handle_all)
    simResetMill(sim_handle_all_except_explicit)
    simResetCollision(sim_handle_all_except_explicit)
    simResetDistance(sim_handle_all_except_explicit)
    simResetProximitySensor(sim_handle_all_except_explicit)
    simResetVisionSensor(sim_handle_all_except_explicit)
    simCloseModule(sim_handle_all)
end
