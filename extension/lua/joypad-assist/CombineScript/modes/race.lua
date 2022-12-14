--AUTHOR = Akeyroid7 & Geraint
--Edited by Sahneisttoll to fit switching modes

-- prerequisites
require("settings")
local stopAutoClutch = Race.stopAutoClutch
local handbrakeClutchLink = Race.handbrakeClutchLink
local Dualsense5_strength = Race.Dualsense5_strength / 100
local Dualsense5_TC = Race.Dualsense5_TC
local Dualsense5_ABS = Race.Dualsense5_ABS

local getrpm = ac.INIConfig.carData(car.index, "engine.ini") --loads engine.ini into getrpm.
local rpm = getrpm:get("ENGINE_DATA", "MINIMUM", 1000) --gets minimum rpm, if not found returns 1000.

local steerAngle = 0
local steerVelocity = 0

--[[
ac.debug("Race_stopAutoClutch", stopAutoClutch)
ac.debug("Race_handbrakeClutchLink", handbrakeClutchLink)
ac.debug("Race_Dualsense5_strength", Dualsense5_strength)
ac.debug("Race_Dualsense5_TC", Dualsense5_TC)
ac.debug("Race_Dualsense5_ABS", Dualsense5_ABS)
--]]--dirty debug

local dtSkip = 0.001 -- This is a debugging feature; increasing the value will reduce the frame rate of the script. (For example, to reduce the frame rate by 1/10, enter 10.)
local dtSkipCount = dtSkip

local function update(dt)

	local car = ac.getCar(0)

	local state = ac.getJoypadState()
	local steerSelf = -state.ffb	-- / 5
	local steerForce = state.steerStick
	local AngVelY = state.localAngularVelocity.y / 1
	local ndSlip = (state.ndSlipL + state.ndSlipR) / 2

	local dtDebug = dt * (dtSkip + 7) -- This is necessary for "dtDebug" to work.
	if dtSkipCount < dtSkip then
		dtSkipCount = dtSkipCount + 10
		goto apply
	end
	dtSkipCount = 0


	if car.engagedGear >= 0 then
		-- If you want to add or subtract a value each time the process is executed, put it between here and "apply" and multiply the value by "dtDebug".
		steerForce = steerForce * (2 - math.sign(steerForce) * steerSelf)
		steerForce = steerForce - steerForce * math.min(ndSlip / 3 * (1 + math.sign(steerForce) * steerAngle - 0.5), 1) -- normal
		AngVelY = AngVelY + AngVelY * math.abs(steerSelf)

		steerVelocity = steerForce + steerSelf + AngVelY
		steerAngle = math.clamp(steerAngle + steerVelocity * dtDebug, -1, 1)
	else
		steerAngle = math.clamp(steerForce + steerForce * dtDebug , -1, 1)
	end
	::apply::

	state.steer = steerAngle

	--Mysterious bug countermeasure. For some reason, this fixes it.
	if state.steer ~= state.steer then
		steerAngle = 0
		state.steer = 0
	end

	--configureable stuff
	if stopAutoClutch ~= 0 and car.rpm < rpm + (rpm / 100) then -- "+ (rpm/100)" to not have stuttery RPMs when standing still
		state.clutch = 0
	end
	if stopAutoClutch ~= 0 and state.clutch == 1 and state.gas > 0.1 then
		state.clutch = math.clamp((car.rpm - 1000) / 750, 0, 1)
	end
	if handbrakeClutchLink ~= 0 and state.handbrake > 0 then
		state.clutch = 1 - state.handbrake
	end

	-- adaptive triggers to have simulated ABS and TC
	if state.gamepadType == ac.GamepadType.DualSense then
		local frontSlip = math.max(state.ndSlipL, state.ndSlipR)
		local rearSlip = math.max(state.ndSlipRL, state.ndSlipRR)

		frontSlip = math.lerpInvSat(frontSlip, 0.3, 1)
		rearSlip = math.lerpInvSat(rearSlip, 0.3, 1)

		if rearSlip > 0 and Dualsense5_TC == 1 then
			ac.setDualSenseTriggerContinuousResitanceEffect(1, 0, rearSlip * Dualsense5_strength)
		else
			ac.setDualSenseTriggerNoEffect(1)
		end

		if frontSlip > 0 and Dualsense5_ABS == 1 then
			ac.setDualSenseTriggerContinuousResitanceEffect(0, 0, frontSlip * Dualsense5_strength)
		else
			ac.setDualSenseTriggerNoEffect(0)
		end
	end

	--[[
  	ac.debug("MINIMUM", rpm)
  	ac.debug('car.rpm', car.rpm)
  	ac.debug("state.clutch",state.clutch)
	ac.debug('state.ffb', state.ffb)
	ac.debug('state.gForces.x', state.gForces.x)
	ac.debug('state.localAngularVelocity.y', state.localAngularVelocity.y)
	ac.debug('state.localSpeedX', state.localSpeedX) -- sideways speed of front axle relative to car
	ac.debug('state.localVelocity.x', state.localVelocity.x) -- sideways speed of a car relative to car
	ac.debug('state.localVelocity.z', state.localVelocity.z) -- forwards/backwards speed of a car relative to car
	ac.debug('state.ndSlipL', state.ndSlipL) -- slipping for left front tyre
	ac.debug('state.ndSlipR', state.ndSlipR) -- slipping for right front tyre
	ac.debug("state.ndSlip",ndSlip)
	ac.debug('state.steer', state.steer)
	ac.debug('state.steerStick', state.steerStick)
	ac.debug('steerVelocity', steerVelocity)
	ac.debug('dt', dt)
	ac.debug('dtDebug', dtDebug)
	--]]-- dirty debug
end
return {
	name = "Geraint's Race",
	update = update,
	sync = function(m) steerAngle, steerVelocity = m.export() end,
	export = function() return steerAngle, steerVelocity end,
}