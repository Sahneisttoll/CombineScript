-- AUTHOR = Akeyroid7
local steerAngle = 0
local steerVelocity = 0


local dtSkip = 0 -- This is a debugging feature; increasing the value will reduce the frame rate of the script. (For example, to reduce the frame rate by 1/10, enter 10.)
local dtSkipCount = dtSkip


local stopAutoClutch = 1 -- Automatic clutch when stopping.
local handbrakeClutchLink = 1 -- Engages the clutch when the handbrake is pulled.

local function update(dt)
  local data = ac.getJoypadState()
  local car = ac.getCar(0)

  local steerSelf = -data.ffb
  local steerForce = data.steerStickX
  local gyroSensor = data.localAngularVelocity.y
  local ndSlip = (data.ndSlipL + data.ndSlipR) / 2

  local dtDebug = dt * (dtSkip + 1) -- This is necessary for "dtDebug" to work.
  if dtSkipCount < dtSkip then
    dtSkipCount = dtSkipCount + 1
    goto apply
  end
  dtSkipCount = 0

  -- If you want to add or subtract a value each time the process is executed, put it between here and "apply" and multiply the value by "dtDebug".

  steerForce = steerForce * (2 - math.sign(steerForce) * steerSelf)
  steerForce = steerForce - steerForce * math.min(ndSlip / 5 * (1 + math.sign(steerForce) * steerAngle), 1)
  gyroSensor = gyroSensor + gyroSensor * math.abs(steerSelf)

  steerVelocity = steerForce + steerSelf + gyroSensor
  steerAngle = math.clamp(steerAngle + steerVelocity * 450 / data.steerLock * dtDebug, -1, 1)

  ::apply::

  data.steer = steerAngle

  if stopAutoClutch ~= 0 and car.rpm < 1000 then
    data.clutch = 0
  end
  if stopAutoClutch ~= 0 and data.clutch == 1 and data.gas > 0.1 then
    data.clutch = math.clamp((car.rpm - 1000) / 2000, 0, 1)
  end
  if handbrakeClutchLink ~= 0 and data.handbrake > 0 then
    data.clutch = 1 - data.handbrake
  end

  if data.steer ~= data.steer then --Mysterious bug countermeasure. For some reason, this fixes it.
    steerAngle = 0
    data.steer = 0
  end

  --[[
    ac.debug('car.rpm', car.rpm)
    ac.debug('data.ffb', data.ffb)
    ac.debug('data.gForces.x', data.gForces.x)
    ac.debug('data.localAngularVelocity.y', data.localAngularVelocity.y)
    ac.debug('data.localSpeedX', data.localSpeedX) -- sideways speed of front axle relative to car
    ac.debug('data.localVelocity.x', data.localVelocity.x) -- sideways speed of a car relative to car
    ac.debug('data.localVelocity.z', data.localVelocity.z) -- forwards/backwards speed of a car relative to car
    ac.debug('data.ndSlipL', data.ndSlipL) -- slipping for left front tyre
    ac.debug('data.ndSlipR', data.ndSlipR) -- slipping for right front tyre
    ac.debug('data.steer', data.steer)
    ac.debug('data.steerStick', data.steerStick)
    ac.debug('steerVelocity', steerVelocity)
    ac.debug('dt', dt)
    ac.debug('dtDebug', dtDebug)
  ]]

end
return {
  name = "Akeyroid7's Drift",
  update = update,
  sync = function (m) steerAngle, steerVelocity = m.export() end,
  export = function () return steerAngle, steerVelocity end,
}