GrayFace MM8 Patch v2.5.6
By Sergey Rozhenko <mailto:sergroj@mail.ru>
https://grayface.github.io/

Mok's patch is included.
Save files are, of course, fully compatible with the unpatched game in both directions.
The patch has no uninstaller to make things simpler.
All configuration is done via mm8.ini, which is populated with main options on the first run.
For all exploits the patch fixes an option to disable the fix shoud be described in this ReadMe.
At the end of ReadMe you'll find info on how to report errors.

([+] - feature, [-] - fixed bug, [*] - other)

New in version 2.5.6:
  << MM6 - MM8 >>
[+] New command available to map scripts (*.evt) that powers some of the MM6 and MM7 changes of this version (code 0x45 - RefundChestArtifacts).
[-] Items laying on the ground in one map were appearing in another when traveling by foot sometimes. Add FixItemDuplicates=0 to INI to disable this fix.
[-] My bug: DisableHooks option wasn't working for some new hooks.
[-] My bug: When custom *.games.lod archives are used, incorrect data was written to autosave on New Game start. It was fully inconsequential until version 2.5.4.
  << MM7, MM8 >>
[-] My bug: The DirectX 7 bug/limitation fix was being applied prematurely, causing a crash on Wine.
  << MM8 >>
[-] Ogre corpses were containing most basic sword instead of a club. Add FixClubsGeneration=0 to INI to disable this fix.

New in version 2.5.5:
  << MM6 - MM8 >>
[-] My bug: Possible character resistances corruption when taking an item from the inventory.
[-] My bug: FixChests option got broken by 2.5.4 changes.
  << MM7, MM8 >>
[*] FixUnmarkedArtifacts option now also respects the 13 artifacts limit imposed by the game.

New in version 2.5.4:
  << MM6 - MM8 >>
[-] Now, when a location re-spawns, all artifacts generated in chests you've never opened get cleared from "obtained artifacts" list.
  << MM7, MM8 >>
[-] My bug: FixMonstersBlockingShots option didn't work right.
  << Fixes in maps >>
[-] Prison of the Lord of Water (d38): An artifact was being generated in an inaccessible chest, leading to it not being obtainable by the party anymore.

New in version 2.5.2:
  << MM6 - MM8 >>
[*] Now character's Stats screen displays a condition that determines stats, in all other places the most severe one is displayed.
  << MM7, MM8 >>
[-] "Nothing here" was shown on the screen after a dialog with a guard.
[-] My bug: List of all conditions wasn't displayed in right click menu for Condition in Stats screen.
  << MM8 >>
[-] My bug: Using ExitDialogsWithRightButton was causing a crash in a dialog with a guard.

New in version 2.5.1:
  << MM7, MM8 >>
[-] My bug: Energy damage wasn't displayed in identify monster dialog.
  << MM8 >>
[-] Intro was unskippable on first launch.

New in version 2.5:
  << MM6 - MM8 >>
[+] Set ShooterMode=1 to enable FPS-like mode. Press attack button to toggle the fight mode, then press left mouse button to attack and right button to use quick spell. Regular quick spell button also works. No auto-targeting is done. A sword icon indicates this mode, which also shows health of target (or last hit) monster.
[+] Now you can set a spell that would be used when you press regular attack button. E.g. you can set Poison Spray as Attack Spell and Heal as Quick Spell. Add EnableAttackSpell=0 to INI to disable.
[+] ViewDistanceD3D option to set view distance in Hardware 3D mode, increased to 12000 by default. In Software mode you can increase view distance slightly by setting dist_mist. Known issue I haven't been able to fix yet: ViewDistanceD3D above game's default 8192 causes occasional brief disappearance of a near ground tile.
[+] Direct unaccelerated mouse input supported through MouseSensitivityDirectMul option. To enable, set it to a positive number, e.g. 1.0.
[+] Player condition priorities changed to demonstrate the worst condition (weak, cursed etc.). Add FixConditionPriorities=0 to INI to disable. New conditions order is Eradicated, Dead, Stoned, Unconscious, Paralyzed, Asleep, Weak, Cursed, Disease3, Poison3, Disease2, Poison2, Disease1, Poison1, Insane, Drunk, Afraid, Zombie.
[+] Now while you're holding right mouse button hint would be shown for the element you're pointing at. Especially useful for checking current time. Add ShowHintWithRMB=0 to INI to disable.
[+] In inventory screen unidentified items are now painted green while you're holding right mouse button. Add GreenItemsWhileRightClick=0 to INI to disable.
[+] Set DeadPlayerShowItemInfo=1 to be able to see items of unconscious players with right click.
[+] Better fix for inactive players acting: now you can select inactive players, but if you press the attack key, an active player would be selected.
[+] MouseLookPermKey option sets up the key that changes mouse look mode, but the mode doesn't get restored when a dialog is opened.
[+] Set ExitDialogsWithRightButton=1 to make right mouse button act as Esc in houses, NPC, map entrance and message dialogs.
[+] WinScreenDelay hidden option controls Win screen delay during which all input is ignored. Default is 500 (half a second instead of game's original 5 seconds).
[+] Set AddDescriptions=1 to add option descriptions straight into INI file. Set it to -1 to remove them.
[+] MonSpritesSizeMul option allows you to change the scale at which monsters are displayed in right button dialog. E.g. set it to 0.5 if you upscale monsters by 2. Mods can change it dynamically through the patch options API.
[+] House animation is no longer restarted when you click any topic. Add FixHouseAnimationRestart=0 to INI to disable this change.
[+] Free space check when saving a game. Add CheckFreeSpace=0 to INI to disable.
[+] Automatic horseman and boatman speak time detection. HorsemanSpeakTimeLimit and BoatmanSpeakTimeLimit hidden options are used as the maximum time allowed for the speeches.
[+] Wands no longer disappear when depleated, just break. Add KeepEmptyWands=0 in INI to disable this change.
[+] Fixed graphics of monsters that looked the same in all 3 variations, as well as thunderbirds and plane guardians.
[-] Changing item graphics was causing inventory corruption.
[-] Poison Spray, Shrapmetal and second spell attacks by monsters were doing wrong damage. Shrapmetal also wasn't going in an arc as it should. Add FixMonsterSpells=0 to INI to disable these fixes. (thanks cthscr)
[-] AOE damage wasn't dealt to paralyzed monsters.
[-] Element hints staying visible in some dialogs after moving the mouse off the element. Add HintStayTime=0 to INI to return this behavior. Default is 2, making hint stay up for 2 frames.
[-] Casting stronger buffs did nothing if a weaker, but longer one is active.
[-] Item spells were causing bugs when cast onto the very first item in the inventory.
[-] Now you when pick up items stolen from you from corpses of thieves it's properly indicated in status bar.
[-] Monster attacks were causing a player switch even if Endurance eliminates hit recovery.
[-] When casting a Quick Spell the spell points check was incorrect (it assigned GM spell to another school of magic)
[-] The game couldn't be run normally when current folder is different from its folder. Add KeepCurrentDirectory=1 to INI to disable this fix.
[-] Unconscious players could identify/repair items in shops before. Add FixDeadPlayerIdentifyItem=0 to INI to disable this fix.
[-] Another situation where game could crash due to vertex-less facets.
[-] New Day effects (weakness, insanity etc.) weren't triggered on beginning of a month when pressing "Wait until Dawn" and then Esc.
[-] Often there was full brightness outdoors for a minute at 5:00 AM.
[-] Random item generation routine was generating the first matching item with bigger probability and last matching item with smaller probability. (Thanks for Tomsod for this and many fixes that I've incorporated)
[-] Buff duration was displayed incorrectly in the cases like "1 day 5 minutes".
[-] Spell duration string for items and "N/A" string for ranged damage weren't localizeable.
[-] Water Walk was draining mana every 5 minutes instead of every 20 minutes. Add FixWaterWalkManaDrain=0 to INI to disable this fix.
[-] My bug: You were able to learn unavailable magic skills with keyboard navigation.
[*] Now spell skills that don't fit on the screen (say, if you change class in Rev4 mod for MM7) are now drawn over buttons. It's still better than making them inaccessible.
[*] 3DO and other logos are now shown when intro is postponed by NoIntro=1, unless NoIntoLogos=0 line is added to INI. You can cancel logos with Esc and still watch the intro.
  << MM7, MM8 >>
[+] UI.txt: New FloatingScreens mode makes inventory, houses and other such screens open in a panel.
[+] With IndoorFovMul hidden option you can specify the amount by which FOV is multiplied indoors in Hardware mode. Default is 0.813.
[+] TrueColorSprites hidden option, off by default to prevent 'out of memory' with HD sprites.
[+] The game now doesn't crash on exit if d3dsprite.hwl and d3dbitmap.hwl are missing.
[+] "Mapbkg" will be used as the background for minimap if present in *.icons.lod. This will help color blind people see blue dots on the minimap better.
[+] Now explosions and missiles are ignored during targeting in Hardware 3D mode too, unless ClickThroughEffects=0.
[+] When ddraw.dll is found in game folder (patch assumes it's dgVoodoo), you'll be asked whether you want to use it and SystemDDraw option would be set accordingly.
[+] Now you can climb steep mountains, like you used to when the game came out, unless ClimbBetter=0.
[-] If you set FixMonstersBlockingShots=1, enemy monsters won't block each other's shots with their body indoor resulting in projectiles being suspended in the air. This would fix the bug of reanimated monsters being unable to hit enemies of the same kind. This may increase difficulty of some encounters, like one in Rev4 mod.
[-] Fixed DirectX 7 bug: inability to support big resolutions in Hardware accelerated mode.
[-] Windows 10 compatibility issue fixed both in the game and Setup. Windowed mode also unlocked in Setup.
[-] Changing a static texture to an animated one by a script was causing a crash next time the location is loaded.
[-] Monsters shot at from a distance beyond active radius were appearing as green dots on minimap.
[-] In Display Inventory screen you couldn't do anything with unconscious players.
[-] Damage bonus of Assassins' and Barbarians' enchantments didn't work.
[-] Grand spell skill wasn't read from Monsters.txt when written as "GM".
[-] Ice Bolt was read as Ice Blast from Monsters.txt. Add FixIceBoltBlast=0 to INI to disable this fix.
[-] Energy damage type was being turned into Earth when read from Monsters.txt. Add FixEnergyDamageType=0 to INI to disable this fix.
[-] Gamma.pcx file was created whenever you open menu.
[-] Souldrinker was hitting monsters beyond party range. Add FixSouldrinker=0 to INI to disable this fix.
[-] Acid Burst spell was doing physical damage.
[-] Inability to equip sword or dagger when a spear is equipped and its skill is below Master.
[-] Arcomage hanging in some circumstances.
[-] Walking on water was dealing Fire damage.
[-] Bow skill bonus from items wasn't added to damage when you have Grandmaster Bow skill.
[-] When a monster attacked another one with a spell, wrong spell was used in damage calculation.
[-] Melee monsters under Berserk were hitting party from a far if their target died.
[-] Failed alchemy was breaking Hardened items.
[-] "of Acid" enchantment was dealing Water damage instead of Body.
[-] Armageddon spell was dealing unresistable damage. Now it deals Dark damage. Add ArmageddonElement=5 to INI to disable this fix.
[-] LeaveMap event wasn't called when travelling via stables or boat.
[-] Monsters summoning other monsters was causing a crash if monsters limit is already reached.
[-] "Body" attack type was read (from Monsters.txt) as physical for monsters.
[-] My bug: Crash in full screen if BorderlessFullscreen=0.
[-] My bug: Mipmaps were always on in full screen if BorderlessFullscreen=0 and MipmapsCount>1.
[-] My bug: Empty pictures were causing division by zero in UI Layout code.
[-] My bug: Empty sprites causing a crash in D3D mode.
[-] UI.txt: 3D view was shifted vertically in the dungeon exit screen.
[-] UI.txt: "Press Escape" message wasn't visible after the Win screen.
  << MM8 >>
[-] Lloyd images weren't saved for players with indexes above 10.
[-] Vampires weren't immune to Mind.
[-] Spirit Lash, "Inferno and Prismatic Light spells were broken when used by monsters (damaged first player multiple times, could damage players that aren't in party).
[-] "voltylX" bitmap had a black border around it.
  << Fixes in maps >>
[-] Necromancers' Guild (d19), Temple of the Sun (d22): Once clerics or necromancers got mad they never calmed down (were intended to calm down after 2 months).
[-] Murmurwoods (out07), Global: Rescuing Cauri, but not speaking to her right away was breaking the promotion.
[-] Dragon Hunter's Camp (d16): "Dragon Hunting" topic meant for Quixote when he joins the alliance wasn't used.
[-] Juggernauts were too fat and getting stuck in doorways.


New in version 2.4.1:
  << MM8 >>
[-] My bug: Random items weren't appearing in chests with quest items.

New in version 2.4:
  << MM6 - MM8 >>
[+] Chests are populated with compact non-random stacking if more items fit this way. This can be disabled by adding FixChestsByCompacting=0 line to INI.
[+] Items are stacked vertically when you place them into chests. This can be disabled by adding PlaceChestItemsVertically=0 line to INI.
[+] Sprites dimensions are tweaked based on vertical view angle. This makes them behave more realistically, especially when looking up at big monsters. Can be disabled by adding SpriteAngleCompensation=0 line to INI.
[+] If NoIntro=1 the intro is shown when you click the New Game button in MM6 or start a new game in MM8. In MM7 this was already the case. Add PostponeIntro=0 to INI to disable the intro entirely. In MM7 you can also set PostponeIntro=2 to have the first intro shown when you click the New Game button.
[+] Now in software rendering mode explosions and missiles are ignored during targeting. Before, party wasn't able to target monsters when whole screen is covered with explosions. You can disable this fix by adding ClickThroughEffects=0 line to the INI.
[+] Low level stuff you shouldn't need to use: DisableHooks option lets you disable hooks effecting certain addresses. It's a comma-separated list of hex addresses. Avoid the old way of disabling hooks by index, because hooks indexes change from version to version.
[+] Technical: Map entrance dialog can now be called from NPC topic anywhere.
[-] Sprite animations were played incorrectly - first frame was longer, last frame was shorter. This fix can be disabled by adding FixSFT=0 to INI.
[-] My bug: keyboard control of dialogs was breaking evt.Question command in houses (used for Escaton riddles in MM8).
  << MM7, MM8 >>
[+] HD textures support in Hardware 3D mode with bitmaps.lwd archives. I wrote a bit about them and custom LODs in general here: https://www.dropbox.com/s/iv9c2jc8abbrj6a/CustomLods.txt?dl=0
[+] Technical: 32-bit color sprites and bitmaps in Hardware 3D mode. This can be disabled by adding TrueColorTextures=0 line to INI.
[+] Better quality water in Hardware 3D mode.
[+] UI.txt: ShrinkStatusbar option makes statusbar size depend on text size (enabled by default).
[+] UI.txt: HideStatusbar option controls whether or not statusbar should be hidden when there's no text in it (enabled by default).
[+] TreeHints option controls whether to show hints for non-interactable decorations in Hardware 3D mode (by default enabled in MM7 and disabled in MM8). Setting it to 2 would force it even in UI Layout mode with statusbar auto-hiding.
[+] Better D3D init errors reporting (now not just for Windowed mode).
[-] Decorations (trees etc.) with Id set were considered interactive even if they aren't. This fix can be disabled by adding SpriteInteractIgnoreId=0 line to INI.
[-] GrandMaster of Axe didn't halve armor class. Now the chance to halve armor class is 1.66 per point of skill, so the skill of 60 will make it 100%. This is to compensate for overall weakness of axe wielding. Hidden AxeGMFullProbabilityAt option controls this (60 by default).
[-] Disease2 and Disease3 bonus effects of monsters weren't working. Disease1 was working as Disease3. Poison2 and Poison3 bonus effects were swapped.
[-] My/DirectX bug: Game was failing to start in resolutions over 1080p, because Direct3D 7 doesn't support them.
[-] My bug: The game could crash when pressing Esc in UI Layout mode.
[-] My bugs: Some bugs with flexible UI layout definitions in particular circumstances.
  << MM8 >>
[-] Players hired in turn-based mode were going into Adventurers Inn instead of joining the party. Now turn-based mode is canceled when you hire somebody.
[-] My bug: PaperDollInChests option was causing a crash in Software rendering mode.
[*] StartupCopyrightDelay option made hidden and 0 by default.
  << Fixes in maps >>
[-] Necromancers' Guild (d19): You could hire Dyson Leland before you get any quest that requires him.

New in version 2.3.1:
  << MM6, MM8 >>
[+] Right click menu works in item selection dialog of Enchant Item and similar spells. In MM7 it already works by default.
  << MM7, MM8 >>
[-] My bug: ScalingParam1 and ScalingParam2 options were ignored in flexible UI mode.
  << MM8 >>
[+] UI.txt: Clicking on the man that symbolizes party buffs now brings up the quest log. Turns out that's what happens if you click the top-left pixel of it in regular UI mode.

New in version 2.3:
  << MM6 - MM8 >>
[+] PaperDollInChests option shows paper doll in chest dialog: value 1 (default) will make it visible when you open inventory of a player, value 2 will make it visible right when you open the chest, value 0 will disable it.
[+] Keyboard control: some dialogs can now be controlled by pressing Up/Down and Enter. E.g. NPC conversations. Only those dialogs that already had everything in place to support it are effected.
[+] Save/load dialogs now react to Enter key.
[+] Newer MP3DEC.ASI version. In theory this might fix some problems with MP3 playback.
[-] My bug: If somehow game window managed to become smaller than 640x480, that wasn't handled gracefully in software 32-bit color mode.
  << MM7, MM8 >>
[+] Widescreen-friendly flexible UI in Hardware 3D mode. Controlled by UILayout option.
[+] Accurate effects coordinates in Hardware 3D mode.
[+] Accurate coordinates of top part of the outdoor sky in Hardware 3D mode.
[+] In Hardware 3D mode the game was prioritizing interacting with sprites on sides of the view too often.
[-] In Hardware 3D mode bottom of sprites didn't react to clicks indoors when mouse is away from horizontal center of the view.
[-] My bug: "Pixel-perfect mouse targeting in HD mode" wasn't working.
  << MM8 >>
[-] Buildings weren't drawn on sides of the view.
[-] Indoors the field of view wasn't increased to account for wider view, so the area of view was even smaller than in MM6 and MM7.
[-] Quickly pressing R, R, Esc to rest was glitching the game if monsters attacked you in your sleep.
[-] Enter key pressed in the main menu had an effect in the game (when starting a new game).
[-] Screenshots of Saves were shrinked horizontally (fixed in TrueColor Hardware 3D mode only for now).

New in version 2.2:
  << MM6 - MM8 >>
[+] Quick load key now works during the death movie.
[+] Game window is resizeable.
[+] StretchWidth and StretchHeight parameters specify the factors by which the game area gets stretched to reduce black bars on the sides. StretchWidthFull and StretchHeightFull parameters are used only if it makes the game occupy the whole screen.
[+] Now in Software rendering mode the view is always scaled linearly, which makes it less flickery.
[+] Data\MouseLookCursorHD.bmp is used for mouse look in 32-bit color mode if window is bigger than 640x480.
[+] Customizable mouse cursors: Data\MouseCursorArrow.cur and Data\MouseCursorTarget.cur are used if present.
[+] Patch now bypasses dgVoodoo DLLs if SupportTrueColor is not disabled.
[+] Minimaps zoom level is remembered always, not just outdoors as before.
[-] Fixed a crash found in Tatalia in MM7.
[-] Inactive characters couldn't interact with chests.
[-] Animated textures (via TFT) were animated incorrectly: first frame was longer, last frame was shorter.
[-] My bug: ScalingParam2 was read from ScalingParam1 entry.
[-] My bug: Mouse placed in the bottom-right corner was causing a crash sometimes.
[*] Smarter FixInactivePlayersActing: now you can select inactive characters, but they can't act.
  << MM7, MM8 >>
[+] Accurate sprites coordinates in D3D mode.
[+] Pixel-perfect mouse targeting in HD mode.
[+] Set TurnBasedWalkDelay to a value of your choice (e.g. 100) to be able to do individual steps in the walking phase of turn-based combat.
[+] Better water animation.
[+] MipmapsBase section in the INI controls how many mipmap levels matching textures can use. Smaller values lead to more mipmaps.
[+] Separate HDWTRCountHWL, HDWTRDelayHWL options for the NoD3DBitmapHwl=0 case.
[+] Hidden FixMonsterSummon option (1 - enabled by default).
[-] Some small cosmetic bugs fixed by changing pictures from icons.lod.
[-] Combination of IsWater and AnimateTFT facet attributes was causing texture change in D3D.
[-] Fixed a rare crash caused by a facet without a single vertex.
[-] My bug: Sparks effect was displayed incorrectly in the previous version.
  << MM8 >>
[+] "FixQuickSpell" hidden option you can set to 0 if you want to use the bug.
[-] In Software rendering mode water shore is no longer bumpy. Set NoWaterShoreBumpsSW=0 to disable this.
[-] Mass Distortion and Implosion spells wasted monsters' turn, but didn't work. Now they aren't used.
[-] 8 leftmost pixels of paper doll area didn't react to clicks.
[-] Monsters/items/effects weren't visible on the sides of the view outdoors.
[-] Party wasn't centered on the minimap.
  << Fixes in maps >>
[-] Castle of Air (d27) - 100k experience was given upon exiting the Plane of Air after getting the Heart of Air, so using Town Portal could lead to it getting skipping.
[-] Castle of Fire (d29) - same as above.
[-] Alvar (out03) - upon entering the Ogre Raiding Fort the party was facing in a wrong direction.
[-] Dagger Wound Islands (out01) - upon entering the Uplifted Library the party was facing in a wrong direction.

New in version 2.1:
  << MM6 - MM8 >>
[+] High resolution rendering in Hardware 3D in 32 bit color mode. 32 bit color is supported in windowed and borderless modes. Can be turned off by adding "SupportTrueColor=0" to INI. You can specify RenderMaxWidth and RenderMaxHeight options to limit maximum rendering resolution if you experience problems with FPS. Hidden options ScalingParam1 (3 by default) and ScalingParam2 (0.2 by default) control crispness of UI scaling.
[+] BorderlessFullscreen option makes the game run in your standard resolution, stretched to full screen (with black borders when needed). Set it to 0 to disable.
[+] WindowWidth and WindowHeight options control window size in windowed mode. Value of -1 means calculate automatically based on aspect ratio.
[+] Movies are smoothly stretched to any window size. To turn off in old full screen mode, add "SmoothMovieScaling=0" to INI, for windowed mode add "CompatibleMovieRender=0" (not recommended!).
[+] Custom SND and VID archives that work just like custom LOD archives.
[+] TurnBasedSpeed (for monsters' turn) and TurnBasedPartySpeed (for party turn) can help you speed up the combat.
[+] When switching from mouse look to 'standard mode' the mouse would start at screen center if over 10 seconds have passed since last switch. Otherwise it will return to its last position. Number of seconds is controlled by hidden MouseLookRememberTime option.
[+] While right mouse button is pressed the mouse look is now deactivated, letting you easily check active spells, current time or perform an action by pressing left mouse button while still holding the right button. Set MouseLookWhileRightClick=1 to keep mouse look active.
[+] PlayMP3 option now supports WAV files in Music folder. WAVs always loop properly.
[+] Another approach to fixing chests: now chest contents are reordered to make most valuable items be put into the chest first. This can be disabled by setting FixChestsByReorder=0.
[+] Black potion isn't wasted if it has no effect.
[+] Infinite view distance in dungeons (monsters don't disappear when they are too far).
[+] FixInfiniteScrolls hidden option controls corresponding fix.
[-] Fixed problems with timers: timer countdown was reset if you visited the location before the timer period passes; in MM6, upon revisiting the map late into in the game, wells could be used a huge number of times; in MM8 timers not related to refill were working differently than in other games. Add "FixTimers=0" to INI to disable the fix.
[-] My bug: *.evt and *.str weren't loaded correctly from DataFiles.
[-] Monsters are unlikely to jump from a bridge into lava now. Hidden "MonsterJumpDownLimit" controls the height from which they won't jump (500 by default).
[-] Jumping height reduced a bit, because the party started jumping too high after movement rounding fix. Also, "FixMovement=0" hidden option added that returns vanilla movement.
[-] Dragons and some spells couldn't target rats.
[-] Crash with sprites with scale too small (happens with MM6HD).
[-] Town Portal wasting player's turn even if you cancel the dialog.
[-] EVT commands couldn't operate on some skills.
[-] Crash on exit.
[*] Some options made 'hidden' to reduce INI clutter.
  << MM7, MM8 >>
[+] Mipmapping in D3D, controlled by "MipmapsCount" option. Value of 3 is optimal. Bigger values lead to less flickering at distance, but reduce resolution too much. Set to 1 to disable, as it was in original game. Set to -1 to generate a lot of mipmaps.
[-] There was a small semi-transparent black contour around sprites and sea shore in Hardware 3D mode.
[-] Broken but unidentified items were green instead of red if you go to a shop to repair them.
[-] Casting Telepathy spell or stealing from a monster used to prevent you from finding random items in its corpse.
[-] Light gray blinking in full screen on some computers.
[-] Arcomage crashing, hanging.
[-] Loading game while in movement phase of turn based mode leading to inability to cast spells.
[-] Monsters summoned by other monsters had wrong monster as their ally.
[-] The game was using "asynchronous" mouse handling incompatible with mouse look of the patch if "D3D Device" = 1 in the registry. Hidden "DisableAsyncMouse" patch option controls this.
[-] items.txt: now special items accept standard English "of ..." strings. This should fix them missing their attributes in some localizations.
[-] Shops were unable to fix some artifacts.
[-] Lava was hurting players in air.
[-] Memory leak in mipmaps generation code.
[*] ReputationNumber option now shows positive values for good reputation. It showed negative values before, just like it's represented internally in the game.
  << MM8 >>
[-] Sky bitmap getting reset each time the game is loaded. To turn off the fix, add FixSkyBitmap=0 line to mm8.ini.
[-] Flute was making Heal sound.
[-] Opening spell book and pressing "Quick Spell" key used to set quick spell to -1, causing a crash when you enter character screen.
[-] My semi-bug: roster.txt and pcnames.txt weren't loaded from DataFiles.
[-] Monsters couldn't cast Paralyze spell, but were wasting their turn.
[-] My bug: Since some version of my patch movies were immediately cancelled when shown by a dialog option click, as in original MM8.
[-] My bug: ProgressiveDaggerTrippleDamage fix didn't work in MM8.
[-] Unicorn King was appearing before obelisks are taken and respawning. Add FixObelisks=0 to INI to disable the fix.
  << Fixes in maps >>
[-] Smuggler's Cove, Dragon Hunter's Camp, Dragon Cave, Necromancers' Guild, Temple of the Sun (d07, d16, d17, d19, d22): Making guards mad, saving and then reloading was making them peaceful again, until you exit the map once.
[-] Smuggler's Cove (d07): Wererats were aggressive after you deliver the Blackmail letter and reenter.
[-] Trash Heap required Repair skill instead of Perception to loot safely. Some kinds of "Trash Heap" outputting "Poisoned!" and "Nothing Here" instead of "Diseased!".
[-] Dagger Wound Island, Ravenshore, Alvar, Ironsand Desert, Shadowspire (out01, out02, out03, out04, out06): Some trees/flowers/rocks with secrets required Repair skill instead of Perception to loot successfully.
[-] Ravenshore (out02): Pirates invasion was happening right away if you return from Regna to Ravenshore before sinking the fleet, now it happens if 2 months pass, as it was supposed to. Now you don't have to take all items from the Vault of Time at once as it doesn't disappear anymore.
[-] Plane of Earth, Abandoned Pirate Keep (eleme, d32): Duplicate chest.
[-] Church of Eep (d46): front side of the chest didn't react to mouse.

Other Changes:
[+] Multiple Quick Saves. (see below for details)
[+] F2 toggles Double Speed mode. DoubleSpeedKey option controls the key.
[+] PlayMP3 option lets you play MP3 files instead of CDAudio. Default is 0 (disabled). (see below for details)
[+] MusicLoopsCount option controls loops count of music. Set it to 0 for infinite loop.
[+] Mouse look. (see below for details)
[+] ToggleCharacterScreenKey opens or closes character screen. The default key is '~'. Set it to 0 to disable.
[+] InventoryKey option lets you open character's inventory screen by pressing 'I' instead of clicking a character portrait. Set it to 0 to disable.
[+] AutorunKey (F3 by default) turns on/off autorun, like in MMORPGs.
[+] TurnSpeedNormal and TurnSpeedDouble options control speed of smooth turning. Default is 100% for normal speed and 120% for double speed. Turn Delta is set to Smooth by default.
[+] MouseWheelFly option lets you fly up and down by scrolling your wheel.
[+] AlwaysStrafe option inverts the behavior of right/left arrows - strafing becomes the standard behavior and turning is done when Ctrl is pressed. Strafing is always on while in mouse look mode, unless you set NormalStrafe=1.
[+] InventoryKey option lets you open character's inventory screen by pressing 'I' instead of clicking a character portrait. Set it to 0 to disable.
[+] ToggleCharacterScreenKey opens or closes character screen. The default key is '~'. Set it to 0 to disable.
[+] FreeTabInInventory lets you select dead characters by Tab key while in character screen. Default is 1 (enabled).
[+] Recovery Time value is displayed in Attack and Shoot descriptions.
[+] NoDeathMovie option makes your death quicker by disabling the movie. Default is 0 (disabled).
[+] NoCD option. Works only if "Anims\Magicdod.vid" is present. Default is 1 (enabled).
[+] NoIntro option disables starting movies. Default is 0 (disabled).
[+] HardenArtifacts options lets you use Harden Item on artifacts. Default is 1 (enabled).
[+] Harden Item, Recharge Item and other similar potions don't disappear when you try to use them on improper items.
[+] NoVideoDelays disables delays before and after a video is shown. Default is 1 (enabled).
[+] ReputationNumber shows numerical reputation value together with category name. Default is 1 (enabled).
[+] MouseLookBorder option lets you can change size of area used to rotate by pressing right mouse button. Set it to -1 to return MM6 and MM7 behavior with right button pausing the game.
[+] PaletteSMul and PaletteVMul options let you change how bright or colorful the game looks. HSV representation of colors is used.
[+] Now monsters are colored properly in Direct3D, no more tinting. d3dsprite.hwl isn't used anymore.
[+] Monster contours are taken into account in Direct3D when you click on them.
[+] "NoBitmapsHwl" enables textures to be taken from bitmaps.lod instead of d3dbitmap.hwl in Direct3D. This leads to better quality of textures, but too much sharpness in the distance. Default is 1 (enabled).
[+] HDWTRCount and HDWTRDelay options control number of water frames (up to 15) and delay between them in D3D.
[+] Smoother D3D water frames included.
[+] HorsemanSpeakTime and BoatmanSpeakTime options control time needed for horseman or boatman to say "Let's go" before new map starts loading.
[+] You can rest on shipyards.
[+] When run in 32 bits color mode automatically switches to 16 bits in Windowed mode.
[+] Identify Monster shows monster resistances numbers now.
[+] StartupCopyrightDelay option lets you change the time for which the copyright window is shown when the game starts.
[+] Custom LODs (for mods). For example, Data\*.icons.lod archives would be loaded after icons.lod, possibly replacing its content. Same with every other archive.
[+] Extracted files from EnglishT.lod are loaded from DataFiles folder. Useful for modders. (see below for details)
[+] Loads all .dll files from ExeMods directory (this is used by MMExtension and you can use it to add your patch).
[+] Improved errors reporting. (see below)
[+] Door state switching command extended. Now modders can pass 3 instead of 2 to switch door state even if it's moving.
[-] There were glitches of smack animation in houses and even crashes sometimes.
[-] Events were executed incorrectly if all party members are inactive.
[-] You could attack with inactive party members. Setting FixInactivePlayersActing=0 would disable this fix.
[-] Now save/load slot is preserved.
[-] No need to set compatibility on Win XP anymore.
[-] Inactive characters could use scrolls.
[-] Items bonuses to weapon skills were ignored in recovery time calculation.
[-] Protection from Magic didn't protect from Poison.
[-] 'of Feather Falling' enchantment didn't work (and Archangel Wings too).
[-] Dagger in second hand used to do triple damage even on Expert level.
[-] Daggers had 10% chance to do triple damage no matter what Dagger skill you have. ProgressiveDaggerTrippleDamage option makes daggers do triple damage with probability equal to skill. Default is 1 (enabled).
[-] Haste didn't work when some members are dead and weak at the same time.
[-] Buggy autosave/quicksave filenames localization removed.
[-] Temporary resistance bonuses didn't work. (they are actually never given in the game, but this fix may be useful for mods)
[-] Added code to suppress a strange bug leading to crash in the Temple Of The Sun.
[-] Mok's delay before showing video is replaced with a better solution.
[-] There were wrong artifacts bonus damage ranges (4-9 instead of 4-10 and so on).
[-] Elderaxe had wrong damage type: Fire instead of Water.
[-] Herald's Boots swiftness didn't work.
[-] Now items that didn't fit into a chest appear in it when you free space for them and reopen the chest. (FixChests option)
[-] DirectDraw errors reporting is disabled.
[-] Attacking big monsters in melee in Direct3D was a problem before. Players tended to shoot in them.
[-] Credits speed is now limited.
[-] Party generation screen animation speed is now limited.
[-] Uncompressed sounds weren't loaded correctly.
[-] 'Invalid ID reached!' that was spamming the ErrorLog.txt is now ignored.
[-] In Plane of Air FPS was very low and ErrorLog.txt was spammed with 'Too many stationary lights!' messages.
[-] Fixed a couple of index-out-of-bounds errors.
[-] Death on arena no longer causes a crash.
[-] Autosave was done after the cost of transport is withdrawn.
[-] Waiting (using Rest dialog) used to recover characters twise as fast.
[-] Town Portal and Lloyd Beacon dialogs used to react spell book click in mouse look mode.
[-] A rare case of "negative/0" caused a crash in stats screen.
[-] Lloyd Beacon used to autosave game after decreasing spell points and adding recovery delay.
[-] Town Portal used to autosave game after adding recovery delay.
[-] Some players experienced a beam of Prismatic Light that doesn't disappear. Now the real cause is fixed.
[-] Movement rounding issues fixed properly. Walking and strafes weren't precise because of these issues and jump height was lower than it should be. JumpSpeed option has been removed.
[-] Save game failure on some computers. Actually caused by a bug of some system software, not the game itself.
[-] Games.lod archive required very special sorting.

Changes of Mok's patch:
- no need to use compatibility modes anymore (Windows 2K/XP)
- better sound & video support (more recent Bink, Smacker and Miles Sound System libraries)
- added small delay before displaying bink movies (on fast machines it was too easy to skip a movie just by pressing mouse button)
- removed buggy hard drive free space check.
- fixed rare crash after playing Arcomage duel (on fast machines sound buffers were released before MSS finished playing them)
- fixed Hour of Power spell (Haste part wasn’t working). Thanks to Mike Kienenberger for the fix.
- fixed Psychic Shock spell (damage 12 + 1-12 instead of 12 + 1).
- you can toggle running mode by pressing caps lock key.

All options are controlled by mm8.ini. It is created when the game is run the first time.
Some localization options are kept in mm8lang.ini. You can change them or translate to your language. If you create the same options in mm8.ini they will override those from mm8lang.ini.

--------------------------------------------------------------------------------
Quick Saves:
Press F11 to use quick save. You will see "Game saved!" message. "QuickSavesKey" option in mm8.ini controls the key used to save the game.
"QuickSavesCount" option controls the number of quick saves.
"QuickSavesName" option controls names of quick saves. Default is "Quicksave".
"SpaceBeforeQuicksaveDigit" controls whether there should be a space between "Quicksave" and the number of quick save.
"QuickLoadKey" option controls the quick load key.

--------------------------------------------------------------------------------
How to use MP3 Music:
Create "Music" folder in the game directory and place there files from "2.mp3" to "16.mp3" corresponding to CD tracks. Set "PlayMP3" to 1. Unlike CD music, MP3 music volume is affected by Sound volume you set in Settings menu, so it's a good idea to keep it at maximum.

--------------------------------------------------------------------------------
DataFiles:
Create "DataFiles" folder in the game directory. To modify a file in EnglishT.lod extract it and place into the "DataFiles" folder. It will be used by the game instead of original file. So, you don't need to insert files into EnglishT.lod each time you modify them.
"DataFiles" option controls this. Default is 1 (enabled).

--------------------------------------------------------------------------------
Custom Archives:
Custom archives are the best way to distribute new and modified content of a mod. Here's an explanation of their loading order: https://www.dropbox.com/s/iv9c2jc8abbrj6a/CustomLods.txt?dl=0

--------------------------------------------------------------------------------
Mouse Look:

To enable mouse look set MouseLook option to 1.
Mouse look can work in two modes. The default mode is like in 3D actions and alternative mode is closer to World of Warcraft and similar games.
Here is my preset for 3D action mode: http://sites.google.com/site/sergroj/mm/MM6MouseLook.rar

You can activate alternative mode by setting MouseLookUseAltMode option to 1 or by pressing Caps Lock if the CapsLockToggleMouseLook option is set to 1.
MouseLookChangeKey is used to switch mode (turn off mouse look in normal mode or turn it on in activate mode). The mode is restored if you open any other screen.
MouseLookTempKey changes mode while you hold it. Best fit for alternative (WoW) mode.
MouseLookPermKey changes mouse look mode, but the mode doesn't get restored when a dialog is opened.
MouseSensitivityX and MouseSensitivityY control mouse sensitivity. If you want, you can invert Y axis by making its sensitivity negative. Note that you can set values over 100.
MouseSensitivityAltModeX and MouseSensitivityAltModeY are similar, but used for alternative mode.
MouseLookFly option lets you fly up/down by pointing your view in the desired direction.
MouseWheelFly option lets you fly up and down by scrolling your wheel. This is particularly useful for take off in mouse look mode.

Cursor used in mouse look mode is located in Data\MouseLookCursor.bmp

--------------------------------------------------------------------------------
Video in Hardware Accelerated Mode:

If the videos aren't playing in hardware accelerated mode, try the following:
Press Win+R, type Regedit, locate the following key in it:
HKEY_LOCAL_MACHNE/Software/New World Computing/Might and Magic Day of the Destroyer/1.0 
Or on 64-bit versions of Windows:
HKEY_LOCAL_MACHNE/Wow6432Node/New World Computing/Might and Magic Day of the Destroyer/1.0 
Set 2dacceloff to 1.

--------------------------------------------------------------------------------
UI Layout:

If you set UILayout=UI, a flexible UI layout (named "UI") will be used. The layout is defined in corresponding Data\UI.txt file and uses icons.UI.lod graphics. It's possible to extend it with *.UI.txt files or create brand new layouts, but I haven't made any description for its format.

Here are options you'll find under [UILayout=UI] section after first use of it:
Scale=1  - Increasing/decreasing it would make all UI bigger/smaller
PartyScale=1.065  - Increasing/decreasing would make portraits bigger/smaller
NoCompass=1  - Set to 0 to enable compass, set to -1 to place it in the middle of the screen at the top
FlyEtcOnTop=1  - Setting it to 0 would move Fly, Water Walk and Levitate icons to the bottom of the view
FOVMul=1  - Field of view multiplier
StatusbarScale=0  - By default statusbar scale is chosen automatically, but you can set it manually
StatusbarPlace=0  - Can have 3 values: -1 - on top of the screen, 0 - above portraits, 1 - below portraits
ShrinkStatusbar=1  - Statusbar size is determined by text in it (ignored if StatusbarPlace=1 or HideStatusbar=0)
HideStatusbar=1  - Hide statusbar when it's empty (ignored if StatusbarPlace=1)
MouseShiftY_1=20.5  - Vertical shift of the middle point of the view when there is 1 player in the party
MouseShiftY_5=27.5  - Vertical shift of the middle point of the view when there are 5 players in the party (for 2-4 players a proportionate average of these values is used)

--------------------------------------------------------------------------------
Errors Reporting:

If an error occurs, send me a report, describing how and when it happened. Attach a savegame if possible. In case of a crash attach ErrorLog.txt file which which would be created in the game directory.
