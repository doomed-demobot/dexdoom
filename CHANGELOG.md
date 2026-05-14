# DexDoom Alpha 5.14.2026
- Updated to ZScript 4.14
- Weapon system rewrite:
    - Weapon action functions rewritten to determine side on call,  
      removing the need for left/right variants of weapons and functions.
    - New inventory system stores weapon attributes (class, mag, etc.)  
      to allow them to persist on respawn/level change.
    - Inventory rewritten for stability and (marginally) better readability.
    - Inventory now shows bindings/controls when open.
    - New bindings and fake buttons for reloading and unloading right weapon.
    - Weapon action functions can now be called outside of a state by  
      passing the desired tic number as an argument.
    - *DD_Condition* is now *DD_WeapAction*.
    - Removed *DD_Sound*, *A_SetCaseNumber*, and *A_SetSoundNumber*.
    - Removed functions related to out-of-date melee combo system.
- Updates to weapons:
  - Pistol
      - Decreased visual/physical recoil for single shot.
      - Reload time 29 -> 35 tics.
      - Added sounds for firing with low ammo.
      - New animations for reloading and unloading.
      - Added full-sized sprites.
  - Shotgun
      - Added full-sized sprites.
      - New animations for reloading and firing.
      - One-handed reload time 44 -> 38 tics.
      - One-handed accuracy increased by 33%
      - One-handed recoil reduced by 60%
  - Super Shotgun
      - One-handed partial reload 27 -> 21 tics.
      - New animations for reloading and firing.
  - Chaingun
      - Improved logic for alt-fire (now consistently switches to primary after spinning up).
      - Hopefully less grating sounds for spinning barrel.
      - Spins up 33% faster.
      - New animations for firing.
  - Rocket Launcher
      - New animations for firing.
      - New sprites for grenades.
      - Now reloads 2 rockets at a time.
      - Grenades contact damage 15 -> 20, splash radius 128 -> 150.
      - Grenades persist for 30 tics before exploding after coming to a stop.
  - Plasma Rifle
      - Improved reloading logic.
      - Alt-fire charging time 27 -> 30 tics.
      - New animations for recharging and firing.
  - BFG 9000
      - BFG Tracers now project in 360° field around projectile with horizontal autoaim.
      - Maximum damage possible by tracers capped to 1800-2400 damage.
      - Cell cost 40 -> 50.
      - New animations for firing.
  - Chainsaw
      - Now a 'fist weapon'; select in inventory after picking up.
- Temporarily removed experimental features (new fist weapons, extra set of arms).
- Removed Classic Mode.
- Updated Berserk powerup
  - Duration 60 -> 80 seconds.
  - Kills during berserk drop *Essence of Hate* which increase duration by 2-5 seconds.
- Tactical Backpack now also acts as a Backpack upgrade, giving bonus ammo and increasing capacity.
- New transformation system for PSprites-- controlled by PSpriteInfo-- allowing for automatic  
  translation, scaling, and rotating through linear and exponential curves.
- New icon sprites for weapon firemodes.
- New crosshairs to get an idea of your side stability (extra recoil from sustained fire).
  

# DexDoom Alpha 7.20.2024
  - Initial release.
