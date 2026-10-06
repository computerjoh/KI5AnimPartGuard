--[[
    KI5AnimPartGuard

    Build 42 has a bug where a vehicle's animated parts (doors, hoods,
    roof racks, etc.) warp to the vehicle's center after its chunk unloads
    with the engine running. This mod prevents that by tracking vehicles
    you've driven and shutting the engine off once you're far enough away
    that the chunk could unload.

    Singleplayer / host-authoritative only.
]]

KI5AnimPartGuard = KI5AnimPartGuard or {}

-- Distance (in tiles) from the nearest player at which a running vehicle
-- gets shut off automatically. Chunks are 10x10 tiles; this margin is kept
-- well inside that so the engine is off before the vehicle's chunk is ever
-- a candidate for unloading.
KI5AnimPartGuard.SAFE_SHUTOFF_DISTANCE = 24

-- How many ticks to wait between sweeps. This doesn't need to run every
-- frame - a couple of checks a second is more than enough to catch a
-- player walking away from a running vehicle.
KI5AnimPartGuard.TICKS_BETWEEN_CHECKS = 30

KI5AnimPartGuard.tickCounter = 0

-- Set of vehicle ids (keys) the player has driven and may have left
-- running. Entries are removed once the engine is confirmed off, the
-- vehicle unloads, or we shut it off ourselves.
KI5AnimPartGuard.trackedVehicleIds = {}

-- Snapshots the currently active, living players once per sweep() call, so
-- distance checks for every tracked vehicle can reuse the same list instead
-- of re-querying getNumActivePlayers()/getSpecificPlayer() per vehicle.
function KI5AnimPartGuard.collectPlayerPositions()
    local players = {}
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p and not p:isDead() then
            players[#players + 1] = p
        end
    end
    return players
end

-- Returns the distance from (vx, vy) to the nearest player in the given
-- snapshot, or nil if the snapshot is empty.
function KI5AnimPartGuard.nearestPlayerDistance(players, vx, vy)
    local best = nil
    for _, p in ipairs(players) do
        local dist = p:DistTo(vx, vy)
        if not best or dist < best then
            best = dist
        end
    end
    return best
end

function KI5AnimPartGuard.onEnterVehicle(character)
    local vehicle = character and character:getVehicle()
    local id = vehicle and vehicle:getId()
    if id then
        KI5AnimPartGuard.trackedVehicleIds[id] = true
    end
end

function KI5AnimPartGuard.sweep()
    -- Only the authoritative side may actually shut vehicles off.
    if isClient() then
        return
    end

    -- Gathered once per sweep rather than once per tracked vehicle - see
    -- collectPlayerPositions().
    local players = KI5AnimPartGuard.collectPlayerPositions()

    for id, _ in pairs(KI5AnimPartGuard.trackedVehicleIds) do
        local vehicle = getVehicleById(id)
        if not vehicle then
            -- No longer loaded - nothing left to watch.
            KI5AnimPartGuard.trackedVehicleIds[id] = nil
        elseif not vehicle:isEngineRunning() then
            -- Already off (manually, or by us) - stop watching.
            KI5AnimPartGuard.trackedVehicleIds[id] = nil
        else
            local dist = KI5AnimPartGuard.nearestPlayerDistance(players, vehicle:getX(), vehicle:getY())
            if dist and dist > KI5AnimPartGuard.SAFE_SHUTOFF_DISTANCE then
                vehicle:shutOff()
                KI5AnimPartGuard.trackedVehicleIds[id] = nil
            end
        end
    end
end

function KI5AnimPartGuard.onTick()
    KI5AnimPartGuard.tickCounter = KI5AnimPartGuard.tickCounter + 1
    if KI5AnimPartGuard.tickCounter >= KI5AnimPartGuard.TICKS_BETWEEN_CHECKS then
        KI5AnimPartGuard.tickCounter = 0
        KI5AnimPartGuard.sweep()
    end
end

Events.OnEnterVehicle.Add(KI5AnimPartGuard.onEnterVehicle)
Events.OnTick.Add(KI5AnimPartGuard.onTick)
