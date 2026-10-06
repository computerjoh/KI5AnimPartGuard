# KI5AnimPartGuard

Project Zomboid mod for Build 42. Fixes the bug where a vehicle's animated
parts (doors, hoods, roof racks) warp to the vehicle's center after its
chunk unloads with the engine running.

Does this by shutting the engine off once you're far enough from a vehicle
you've driven that its chunk could unload.

Singleplayer / host-authoritative only.

## Install

Copy `42.21/` into your mod's folder under `Zomboid/mods/KI5AnimPartGuard/`,
so you end up with `Zomboid/mods/KI5AnimPartGuard/42.21/mod.info`.

Enable it in-game under Mods.
