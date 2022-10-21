--AUTHOR = Akeyroid7 & Geraint
local steerAngle = 0
local steerVelocity = 0

local dtSkip = 0.001 -- This is a debugging feature; increasing the value will reduce the frame rate of the script. (For example, to reduce the frame rate by 1/10, enter 10.)
local dtSkipCount = dtSkip

  -- extra options
local stopAutoClutch = 1 -- Automatic clutch when stopping.
local getrpm = ac.INIConfig.carData(car.index, 'engine.ini') --gets engine.ini
local rpm = getrpm:get('ENGINE_DATA', 'MINIMUM', 1000) --gets minimum rpm, if not found returns 1000
local handbrakeClutchLink = 0 -- Engages the clutch when the handbrake is pulled.
local enableDS5Extra = 0 -- Engages the clutch when the handbrake is pulled.
  -- extra options

local function update(dt)
  local state = ac.getJoypadState()

  local steerSelf = -state.ffb
  local steerForce = state.steerStick
  local AngVelY = state.localAngularVelocity.y /1
  local ndSlip = (state.ndSlipL + state.ndSlipR) / 2

  local dtDebug = dt * (dtSkip + 7)
  if dtSkipCount < dtSkip then
    dtSkipCount = dtSkipCount + 10
    goto apply
  end
  dtSkipCount = 0

  -- If you want to add or subtract a value each time the process is executed, put it between here and "apply" and multiply the value by "dtDebug".
  steerForce = steerForce * (2 - math.sign(steerForce) * steerSelf)
  steerForce = steerForce - steerForce * math.min(ndSlip / 3 * (1 + math.sign(steerForce) * steerAngle-0.5), 1)
  AngVelY = AngVelY + AngVelY * math.abs(steerSelf)

  steerVelocity = steerForce + (steerSelf) + (AngVelY)
  steerAngle = math.clamp((steerAngle) + (steerVelocity) * dtDebug, -1, 1)

  ::apply::

  state.steer = (steerAngle)

  -- extra options
  local car = ac.getCar()
  if stopAutoClutch ~= 0 and car.rpm < rpm + math.round(rpm/80) then
    state.clutch = 0
  end
  if stopAutoClutch ~= 0 and state.clutch == 1 and state.gas > 0.1 then
    state.clutch = math.clamp((car.rpm - 1000) / 2000, 0, 1)
  end
  if handbrakeClutchLink ~= 0 and state.handbrake > 0 then
    state.clutch = 1 - state.handbrake
  end
  -- extra options

  if state.gamepadType == ac.GamepadType.DualSense and enableDS5Extra == 1 then
    local frontSlip = math.max(state.ndSlipL, state.ndSlipR)
    local rearSlip = math.max(state.ndSlipRL, state.ndSlipRR)

    -- Second attempt: resistance increases to try and prevent losing traction
    frontSlip = math.lerpInvSat(frontSlip, 0.3, 1)
    rearSlip = math.lerpInvSat(rearSlip, 0.3, 1)
    if rearSlip > 0 then
      ac.setDualSenseTriggerContinuousResitanceEffect(1, 0, rearSlip*0.5)
    else
      ac.setDualSenseTriggerNoEffect(1)
    end

    if frontSlip > 0 then
      ac.setDualSenseTriggerContinuousResitanceEffect(0, 0, frontSlip*0.5)
    else
      ac.setDualSenseTriggerNoEffect(0)
    end
    --local speedMult = math.lerpInvSat(state.speedKmh, 50, 100)
    --local bump, dirt = 0, 0
    --for i = 0, 3 do
    --  local mult = car.wheels[i].loadK
    --  dirt = dirt + car.wheels[i].surfaceDirt * mult
    --  bump = bump + math.lerpInvSat(car.wheels[i].contactNormal.y, 0.97, 0.8) * mult
    --end

    ---- Major vibrations on the left
    --state.vibrationLeft = speedMult
    --  * math.max(state.surfaceVibrationGainLeft, state.surfaceVibrationGainRight)
    --state.vibrationLeft = math.max(state.vibrationLeft, car.absInAction and 0.1 or 0)
    --state.vibrationLeft = dt % 7 == 1 and math.max(state.vibrationLeft, bump * speedMult) or state.vibrationLeft

    ---- Minor vibrations on the right
    --state.vibrationRight = dt % 4 == 0 and math.saturateN(rpm * 10 - 8.5) * 0.01 or 0
    --state.vibrationRight = dt % 5 == 3 and math.max(state.vibrationRight, dirt * speedMult * 0.1) or state.vibrationRight

  end


  --Mysterious bug countermeasure. For some reason, this fixes it.
  if state.steer ~= state.steer then
    steerAngle = 0
    state.steer = 0
  end

  --[[
  ac.debug("min RPM", math.round(rpm/80))
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
  name = "Geraint's Race",
  update = update,
  sync = function (m) steerAngle, steerVelocity = m.export() end,
  export = function () return steerAngle, steerVelocity end,
}