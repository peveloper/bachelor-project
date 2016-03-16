-- Main script that loads the default scenario to handle simulations with a given heighfield

package.path = package.path .. ";/Users/stefanopeverelli/Documents/usi/6ths/Bachelor Project/project/scripts/?.lua;"
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
    return math.random() + math.random(-(max/2) +1 ,  (max/2) -1)
end

-- Place the robot in a suitable position
placeRobot = function(x, y, z)
    robot_position = {getRandomCoordinate(x), getRandomCoordinate(y), z}
    simSetObjectPosition(robot_handle, -1, robot_position)
end

-- Check if a point is contained in the plane
-- x and y are the point's 2d coordinates and max_x and max_ y are the bounding plane coordinates
isInPlane = function(x, y, z, max_x, max_y)
    if(x <= (max_x/2) -1 and x >= -(max_x/2) +1) and (y <= (max_y/2) -1 and y >= -(max_y/2) +1) then
        return true
    end

    return false
end

-- Compute a random angle between 0 and 2pi
randomAngle = function()
    return math.random() + math.random(0, 2 * math.pi)
end

-- Place the goal point at a distance d from the robot position that lies in the part of circle in the bounding plane
placePoint = function(d)
    angle = randomAngle()
    x = math.sin(angle) * d
    y = math.cos(angle) * d
    z = 0
    return {x, y, z}
end

-- Initialization part (executed just once, at simulation start) ---------
if (sim_call_type == sim_mainscriptcall_initialization) then
    simOpenModule(sim_handle_all)
    simHandleGraph(sim_handle_all_except_explicit, 0)
    simCreatePath(-1)
    point_handle = simGetObjectHandle('Path')
    simSetObjectName(point_handle, 'GOAL')
    simLoadModel('/Users/stefanopeverelli/Documents/dev/V-REP_PRO_EDU_V3_3_0_Mac/models/vehicles/offroad.ttm')
    robot_handle = simGetObjectHandle('ROBOT')
    heightfield_handle = simGetObjectHandle('heightfield')
    max_x = getShapeMaxValues(heightfield_handle)[1]
    max_y = getShapeMaxValues(heightfield_handle)[2]
    max_z = getShapeMaxValues(heightfield_handle)[3]
    placeRobot(max_x, max_y, max_z)
    distance = 5
    while not isInPlane(placePoint(distance)) do
        point_position = placePoint(distance)
    end
    simSetObjectPosition(point_handle, point_position)
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
