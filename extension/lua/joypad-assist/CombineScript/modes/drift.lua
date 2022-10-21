--AUTHOR = Akeyroid7
local steerAngle = 0
local steerVelocity = 0

local dtSkip = 0 -- This is a debugging feature; increasing the value will reduce the frame rate of the script. (For example, to reduce the frame rate by 1/10, enter 10.)
local dtSkipCount = dtSkip

  -- extra options
local stopAutoClutch = 1 -- Automatic clutch when stopping.
local getrpm = ac.INIConfig.carData(car.index, 'engine.ini') --gets engine.ini
local rpm = getrpm:get('ENGINE_DATA', 'MINIMUM', 1000) --gets minimum rpm, if not found returns 1000
local handbrakeClutchLink = 1 -- Engages the clutch when the handbrake is pulled.
  -- extra options

local function update(dt)
  local state = ac.getJoypadState()
  ac.setDualSenseTriggerNoEffect(0)
  ac.setDualSenseTriggerNoEffect(1)
  local steerSelf = -state.ffb
  local steerForce = state.steerStickX
  local localAngularVelocity = state.localAngularVelocity.y
  local ndSlip = (state.ndSlipL + state.ndSlipR) / 2

  local dtDebug = dt * (dtSkip + 1) -- This is necessary for "dtDebug" to work.
  if dtSkipCount < dtSkip then
    dtSkipCount = dtSkipCount + 1
    goto apply
  end
  dtSkipCount = 0

  -- If you want to add or subtract a value each time the process is executed, put it between here and "apply" and multiply the value by "dtDebug".
  steerForce = steerForce * (2 - math.sign(steerForce) * steerSelf)
  steerForce = steerForce - steerForce * math.min(ndSlip / 5 * (1 + math.sign(steerForce) * steerAngle), 1)
  localAngularVelocity = localAngularVelocity + localAngularVelocity * math.abs(steerSelf)

  steerVelocity = steerForce + steerSelf + localAngularVelocity
  steerAngle = math.clamp(steerAngle + steerVelocity * 450 / state.steerLock * dtDebug, -1, 1)

  ::apply::

  state.steer = steerAngle

  -- extra options
  local car = ac.getCar(0)
  if stopAutoClutch ~= 0 and car.rpm < rpm + (rpm/100) then
    state.clutch = 0
  end
  if stopAutoClutch ~= 0 and state.clutch == 1 and state.gas > 0.1 then
    state.clutch = math.clamp((car.rpm - 1000) / 2000, 0, 1)
  end
  if handbrakeClutchLink ~= 0 and state.handbrake > 0 then
    state.clutch = 1 - state.handbrake
  end
  -- extra options

 --Mysterious bug countermeasure. For some reason, this fixes it.
  if state.steer ~= state.steer then
    steerAngle = 0
    state.steer = 0
  end

  --[[
  ac.debug("MINIMUM", rpm)
  ac.debug('car.rpm', car.rpm)
    ac.debug('state.ffb', state.ffb)
    ac.debug('state.gForces.x', state.gForces.x)
    ac.debug('state.localAngularVelocity.y', state.localAngularVelocity.y)
    ac.debug('state.localSpeedX', state.localSpeedX) -- sideways speed of front axle relative to car
    ac.debug('state.localVelocity.x', state.localVelocity.x) -- sideways speed of a car relative to car
    ac.debug('state.localVelocity.z', state.localVelocity.z) -- forwards/backwards speed of a car relative to car
    ac.debug('state.ndSlipL', state.ndSlipL) -- slipping for left front tyre
    ac.debug('state.ndSlipR', state.ndSlipR) -- slipping for right front tyre
    ac.debug('state.steer', state.steer)
    ac.debug('state.steerStick', state.steerStick)
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