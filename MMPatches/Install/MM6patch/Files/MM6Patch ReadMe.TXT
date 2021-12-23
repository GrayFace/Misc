GrayFace MM6 Patch v2.5.1
By Sergey Rozhenko <mailto:sergroj@mail.ru>
https://grayface.github.io/

Official patches, Mok's patch and Angel's patch are included.
Save files are, of course, fully compatible with the unpatched game in both directions.
The patch has no uninstaller to make things simpler.
All configuration is done via mm6.ini, which is populated with main options on the first run.
For all exploits the patch fixes an option to disable the fix shoud be described in this ReadMe.
At the end of ReadMe you'll find info on how to report errors.

([+] - feature, [-] - fixed bug, [*] - other)

New in version 2.5.1:
  << MM6 >>
[-] My bug: Crash if character doesn't have a bow (due to "N/A" string not being initialized).

New in version 2.5:
  << MM6 - MM8 >>
[+] Set ShooterMode=1 to enable FPS-like mode. Press attack button to toggle the fight mode, then press left mouse button to attack and right button to use quick spell. Regular quick spell button also works. No auto-targeting is done. A sword icon indicates this mode, which also shows health of target (or last hit) monster.
[+] Now you can set a spell that would be used when you press regular attack button. E.g. you can set Poison Spray as Attack Spell and Heal as Quick Spell. Add EnableAttackSpell=0 to INI to disable.
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
[+] Changing view distance by setting dist_mist option is now supported, but useless, because it won't increase ground drawing distance.
[+] Automatic horseman and boatman speak time detection. HorsemanSpeakTimeLimit and BoatmanSpeakTimeLimit hidden options are used as the maximum time allowed for the speeches.
[+] Wands no longer disappear when depleated, just break. Add KeepEmptyWands=0 in INI to disable this change.
[+] Fixed graphics of skeletons and enforcer units.
[-] Changing item graphics was causing inventory corruption.
[-] All spells cast by monsters were doing Fire damage. Add FixMonsterSpells=0 to INI to disable this fix.
[-] AOE damage wasn't dealt to paralyzed monsters.
[-] Element hints staying visible in some dialogs after moving the mouse off the element. Add HintStayTime=0 to INI to return this behavior. Default is 2, making hint stay up for 2 frames.
[-] Casting stronger buffs did nothing if a weaker, but longer one is active.
[-] Item spells were causing bugs when cast onto the very first item in the inventory.
[-] Now you can pick up items stolen from you from corpses of thieves.
[-] Monster attacks were causing a player switch even if Endurance eliminates hit recovery.
[-] When casting a Quick Spell the spell points check was incorrect (it assigned GM spell to another school of magic)
[-] The game couldn't be run normally when current folder is different from its folder. Add KeepCurrentDirectory=1 to INI to disable this fix.
[-] Unconscious players could identify/repair items in shops before. Add FixDeadPlayerIdentifyItem=0 to INI to disable this fix.
[-] Another situation where game could crash due to vertex-less facets.
[-] New Day effects (weakness, insanity etc.) weren't triggered on beginning of a month when pressing "Wait until Dawn" and then Esc.
[-] Often there was full brightness outdoors for a minute at 5:00 AM.
[-] Random item generation routine was generating the first matching item with bigger probability and last matching item with smaller probability. (Thanks for Tomsod for this and many fixes that I've incorporated)
[-] Buff duration was displayed incorrectly in the cases like "1 day 5 minutes".
[-] "N/A" string for ranged damage wasn't localizeable.
[-] Water Walk was draining mana every 5 minutes instead of every 20 minutes. Add FixWaterWalkManaDrain=0 to INI to disable this fix.
[-] My bug: You were able to learn unavailable magic skills with keyboard navigation.
[*] Now spell skills that don't fit on the screen (say, if you change class in Rev4 mod for MM7) are now drawn over buttons. It's still better than making them inaccessible.
[*] 3DO and other logos are now shown when intro is postponed by NoIntro=1, unless NoIntoLogos=0 line is added to INI. You can cancel logos with Esc and still watch the intro.
  << MM6, MM7 >>
[-] Horizontal speed of snow was effected by strafing too much.
[-] Copyright screen staying visible on startup if game window wasn't in focus when it appeared.
[-] Awards page wasn't updated when player is switched by pressing Tab.
[-] 'Charm' spell had wrong durations.
  << MM6 >>
[-] End game movies were unskippable, as well as the intro on first launch.
[-] Game wasn't paused in Enchant Item screen.
[-] Paralyze spell didn't do anything when cast by monsters. Add FixParalyze=0 to INI to disable this fix.
[-] Party was trying to attack enemies during their dying animation.
[-] Small text fixes in spell descriptions.
[-] My bug: Keyboard control in spell book was causing spells to be cast accidentally with arrow keys.
  << Fixes in maps >>
[-] Oracle was giving wrong hints in many cases.
[-] Dragonsand (outb3): Both Tomb of VARN doors had the same texture.
[-] Agar's Laboratory (d19): You could get +50 intellect any number of times.
[-] The Arena (zarena): Exit doors weren't triggering a confirmation dialog.
[*] Warlord's Fortress (d16): Rolled back duplicated chests fix, because it made people think there's a key for them.


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
  << MM6 >>
[-] Static Charge cost at Expert was incorrect. Spells cost wasn't taken from Spells.txt.

New in version 2.3.1:
  << MM6, MM8 >>
[+] Right click menu works in item selection dialog of Enchant Item and similar spells. In MM7 it already works by default.
  << MM6 >>
[-] My bug: Enchant Item and Golden Touch spells were bugged, effected by PaperDollInChests option.

New in version 2.3:
  << MM6 - MM8 >>
[+] PaperDollInChests option shows paper doll in chest dialog: value 1 (default) will make it visible when you open inventory of a player, value 2 will make it visible right when you open the chest, value 0 will disable it.
[+] Keyboard control: some dialogs can now be controlled by pressing Up/Down and Enter. E.g. NPC conversations. Only those dialogs that already had everything in place to support it are effected.
[+] Save/load dialogs now react to Enter key.
[+] Newer MP3DEC.ASI version. In theory this might fix some problems with MP3 playback.
[-] My bug: If somehow game window managed to become smaller than 640x480, that wasn't handled gracefully in software 32-bit color mode.
  << MM6, MM7 >>
[-] My bug: Quick load key pressed during the death movie was causing a crash afterwards.
  << MM6 >>
[-] Text files fixes for Russian (Buka) version by tolich.

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
  << MM6 >>
[+] "NoPlayerSwap" hidden option. Set it to 0 to return player swapping and bugs it opens up.

New in version 2.1:
  << MM6 - MM8 >>
[+] 32 bit color support in windowed and borderless modes. Can be turned off by adding "SupportTrueColor=0" to INI. You can specify RenderMaxWidth and RenderMaxHeight options to limit maximum resolution of quality scaling if you experience problems with FPS. Hidden options ScalingParam1 (3 by default) and ScalingParam2 (0.2 by default) control crispness of UI scaling.
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
[-] Blasters and some spells couldn't target rats.
[-] Crash with sprites with scale too small (happens with MM6HD).
[-] Town Portal wasting player's turn even if you cancel the dialog.
[-] EVT commands couldn't operate on unused Thievery skill.
[-] Crash on exit.
[*] Some options made 'hidden' to reduce INI clutter.
  << MM6, MM7 >>
[-] My bug: crash when loading custom LOD archives. (don't know how it even worked at all!)
[-] Out-of-bounds memory read in buy dialog when no player is active.
[-] Shops were buying blasters.
  << MM6 >>
[+] NoIntro option, just like in other patches. I figured this can be more convenient than "-nomovie" cmd line switch.
[+] PlayMP3 option now supports tracks in Sounds folder for compatibility with GOG version.
[+] Items stack vertically, like in MM7 and MM8 (add PlaceItemsVertically=0 to INI to disable).
[-] Scholar NPC wasn't giving +5% exp.
[-] +2/+3 weapon skill NPCs didn't effect weapon delay.
[-] My bug: Starburst and Meteor Shower range limitations still weren't accurate.
[-] My bug: Pressing CharScreenKey while holding right mouse button sometimes leading to a crash.
  << Fixes in maps >>
[-] Fixed missing dungeon/house hints in all outdoor locations (except Paradise Valley, it was fine).
[-] Fountain in Paradise Valley (outa2) was showing "+100 Power temporary" instead of "Refreshing!" when depleated.
[-] Fountains in Blackshire and Kriegspire shared the same "used" flag, drinking one was prohibiting you from drinking the other (one gives +5 Intellect and Personality, the other +10 Magic resistance).
[-] Kriegspire (outb1): One of doors on top of Castle Kriegspire didn't react to mouse. Superior Temple of Baa was entered in a wrong direction.
[-] Blackshire (outb2): Floating tree near the house with statuettes. Lair of the Wolf was entered in a wrong direction.
[-] Hall of the Fire Lord (d04): Locked chest wasn't openable if the trap detonated. Front facet of anther chest wasn't clickable.
[-] Dragoons' Caverns (d06): Better handling of chests with quest items. One of quest items wasn't obtainable if the chest was opened with an explosion. After obtaining quest items the chests were becoming duplicated.
[-] Snergle's Iron Mines (d09): Front of a Cabinet (event 77) didn't react to clicks.
[-] Dragoons' Keep (d10): Duplicated chest and unopenable cabinet fixed by Black Phantom. Better handling of the chest with Mordred dagger.
[-] Corlagon's Estate (d11): Better handling of the chest with the quest item.
[-] Warlord's Fortress (d16): Fixed duplicated chests. Better handling of the chest with the quest item.
[-] Agar's Laboratory (d19): Duplicated chests fixed (now the final chest has items, as intended).
[-] Temple of Baa (t1): Misaligned floor texture.
[-] Temple of the Moon (t5): One altar didn't increase Might of the last player only if it's below 50, another was giving +2 Luck to first player instead of +5. Fixed by Black Phantom.
[-] Superior Temple of Baa (t7): Fixed duplicated chests. Partially based on Black Phantom fix.
[-] Free Haven Sewer (sewer.blv): Rats were spawning in walls. Top of one chest didn't react to clicks. Richard Harp's exit was leading to a different house.
[-] Oracle of Enroth (oracle.blv): Problems of oracle screen with stars - often closing instead of opening.
[-] New World Computing (znwc): One door was moving a part of the wall when opened.
[-] Circus was removing all trophies when giving out Pyramids and Kegs of Wine.
[-] "Cloak of Baa" was given multiple times if you talked to Slicker Silvertongue again.

Other changes:
[+] Multiple Quick Saves. (see below for details)
[+] You can change controls. (see below for details)
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
[+] FreeTabInInventory lets you select dead characters by Tab key while in character screen. Default is 1 (enabled).
[+] Recovery Time value is displayed in Attack and Shoot descriptions.
[+] NoDeathMovie option makes your death quicker by disabling the movie. Default is 0 (disabled).
[+] When you right click on character's experience it shows level to which the character can train and experience needed to train to level after that. Just like in MM7 and MM8.
[+] ReputationNumber shows numerical reputation value together with category name. Default is 1 (enabled).
[+] NoCD option. Works only if "Anims\Anims2.vid" is present. Default is 1 (enabled). Note that it works only if Anims folder of the game contains both video files in it.
[+] HorsemanSpeakTime and BoatmanSpeakTime options control time needed for horseman or boatman to say "Let's go" before new map starts loading.
[+] When run in 32 bits color mode automatically switches to 16 bits in Windowed mode.
[+] Custom LODs (for mods). For example, Data\*.icons.lod archives would be loaded after icons.lod, possibly replacing its content. Same with every other archive.
[+] Extracted files from icons.lod (except pictures) are loaded from DataFiles folder. Useful for modders. (see below for details)
[+] Loads all .dll files from ExeMods directory (this is used by MMExtension and you can use it to add your patch).
[+] Improved errors reporting. (see below)
[+] BlasterRecovery option controls minimal blaster recovery time. Default is 5. Game default was 0.
[+] Door state switching command extended. Now modders can pass 3 instead of 2 to switch door state even if it's moving.
[-] MSS32.dll bugs fixed by using a newer version of it. The bugs are: With original version the game didn't run on some systems producing SHRINKER.ERR file with "Pager initialisation error 2" in it. With version from Mok's patch the game could hang when you enter lords' castles or a movie show up.
[-] You could drink from fountains multiple times if all party members are inactive.
[-] You could attack with inactive party members. Setting FixInactivePlayersActing=0 option would disable this fix.
[-] FixDualWeaponsRecovery option fixes wrong recovery time calculation for characters wielding a weapon in second hand. Dual-wielding was useless before the fix due to doubled recovery time. After the fix it works as in MM7 and MM8.
[-] Now all sounds are stopped when MM6 is deactivated.
[-] AlwaysRun effects turning in turn-based mode now.
[-] Town Portal pauses the game now.
[-] Now you can have gaps between save slots. Save and Load would target the same slot anyway.
[-] Walk Sound disappearing problem fixed.
[-] No need to set compatibility on Win XP anymore.
[-] Some scrolls were endless if you use them on paper doll in turn-based mode. Setting FixInfiniteScrolls=0 would disable this fix.
[-] Inactive characters could use scrolls. Setting FixInfiniteScrolls=0 would disable this fix.
[-] When using a scroll by right click on a character portrait target was chosen automatically. Thus, scrolls like Stone to Flash couldn't be used that way.
[-] Now scrolls sets the game on pause when used on paper doll. This also disallows picking up items while choosing spell target.
[-] Improved Angel's Bootlag Bay circus fix. It didn't work in some circumstances.
[-] One of circus buildings in Bootlag Bay didn't have an entrance texture.
[-] 'Increases rate of Recovery' enchantment now works. IncreaseRecoveryRateStrength controls how much it increases the rate. Default is 10%.
[-] Fixed a game bug which could cause a crash on game start.
[-] Turn-based turn used to take twice as much time as it should.
[-] Smack video volume used to be loud no metter what Sound Volume you set.
[-] Now items that didn't fit into a chest appear in it when you free space for them and reopen the chest. (FixChests option)
[-] Removed buggy character switching among slots with Ctrl + click.
[-] Now Starburst and Meteor Shower can't be used on monsters that are beyond the reach of arrows. Setting FixStarburst=0 would disable this fix.
[-] Party generation screen animation speed is now limited.
[-] Fixed a couple of index-out-of-bounds errors.
[-] When you move between locations sound buffers were freed while the sounds are playing. Also some resources weren't freed.
[-] Autosave was done after the cost of transport is withdrawn.
[-] Weapon enchants don't ignore resistances anymore.
[-] Fixed condition removal spells (they worked 3 hours/days per skill point instead of 1, also causing integer overflow on huge skill levels).
[-] My bug: Quick Save didn't work in Hive after destroying the Reactor.
[-] Waiting (using Rest dialog) didn't recover characters.
[-] Map crossing dialog was triggered while flying low, accepting it in that case did nothing.
[-] A rare case of "negative/0" caused a crash in stats screen.
[-] Lloyd Beacon used to autosave game after decreasing spell points and adding recovery delay.
[-] Town Portal used to autosave game after adding recovery delay.
[-] Town Portal triggered autosave even within when teleporting current location.
[-] Finger Of Death spell didn't give experience for killed monsters.
[-] Although Prismatic Light beam bug wan't reported in MM6, the thing that caused it was fixed here too.
[-] Movement rounding issues fixed. Strafes weren't precise because of these issues.
[-] Save game failure on some computers. Actually caused by a bug of some system software, not the game itself.
[-] Games.lod archive required very special sorting.
[*] Added Smuggler's Guild in Free Haven. Looks like it was planned by NWC, but not included in the map file.
[*] Newer versions of MSS32.dll and Smackw32.dll are used always.

Changes by Angel <mailto:angeldeath29@mail.ru> (http://sites.google.com/site/angelddeath/#TOC-MM6-)
[-] Bootlag Bay circus fixed.

Changes of Mok's patch:
[+] AlwaysRun option enables running. If you press Shift you'll walk. Default is 1 (enabled). Always disabled before the patch.
[+] Caps Lock key will toggle running/walking if CapsLockToggleRun option is 1. Default is 0 (disabled). (the option to control this was added in GrayFace Patch).
[+] FlipOnExit option turns your party when you exit a building. Default is 0 (disabled). Always enabled before the patch.
[+] LoudMusic option sets the maximum volume of in-game CD Music to maximum of your normal Windows CD Audio Volume Slider. Normally the game sets it to half the volume which is too quiet for some setups. Default is 0 (disabled). Always disabled before the patch.
[-] Fixed broken doors in Shadow Guild and Kriegspire Castle.
[-] Fixed shield and armor recovery (Thanks to Mike Kienenberger for the fix).
[-] Fixed CD Audio initialization. Music will play even if CD2 isn't in the first CD-ROM drive in your system.
[-] Buggy harddrive free space check removed.

Changes of official patches 1.1 and 1.2 are listed in Readme.txt

All options are controlled by mm6.ini. It is created when the game is run the first time.
Some localization options are kept in mm6lang.ini. You can change them or translate to your language. If you create the same options in mm6.ini they will override those from mm6lang.ini.

--------------------------------------------------------------------------------
Quick Saves:
Press F11 to use quick save. You will see "Game saved!" message. "QuickSavesKey" option in mm6.ini controls the key used to save the game.
"QuickSavesCount" option controls the number of quick saves.
"QuickSavesName" option controls names of quick saves. Default is "Quicksave".
"SpaceBeforeQuicksaveDigit" controls whether there should be a space between "Quicksave" and the number of quick save.
"QuickLoadKey" option controls the quick load key.

--------------------------------------------------------------------------------
How To Use MP3 Music:
Create "Music" folder in the game directory and place there files from "2.mp3" to "16.mp3" corresponding to CD tracks. Set "PlayMP3" to 1. Unlike CD music, MP3 music volume is affected by Sound Volume you set in Settings menu, so it's a good idea to keep it at maximum.

--------------------------------------------------------------------------------
No Starting Movies:
To turn off starting videos add -nomovie switch to the game command line. This is not a feature of the patch, it's provided by the game itself.

--------------------------------------------------------------------------------
Changing Controls:
Use https://sites.google.com/site/sergroj/mm/MM6Controls.rar to change controls.

--------------------------------------------------------------------------------
DataFiles:
Create "DataFiles" folder in the game directory. To modify a file in icons.lod extract it and place into the "DataFiles" folder. It will be used by the game instead of original file. So, you don't need to insert files into icons.lod each time you modify them. Doesn't work with pictures except *.pcx ones.
"DataFiles" option controls this. Default is 1 (enabled).

--------------------------------------------------------------------------------
Custom Archives:
Custom archives are the best way to distribute new and modified content of a mod. Here's an explanation of their loading order: https://www.dropbox.com/s/iv9c2jc8abbrj6a/CustomLods.txt?dl=0

--------------------------------------------------------------------------------
Mouse Look:

To enable mouse look set MouseLook option to 1.
Mouse look can work in two modes. The default mode is like in 3D actions and alternative mode is closer to World of Warcraft and similar games.
Here is my preset for 3D action mode: http://sites.google.com/site/sergroj/mm/MM6MouseLook.rar

You can activate alternative mode by setting MouseLookUseAltMode option to 1 or by pressing Caps Lock if the CapsLockToggleMouseLook option is set to 1. You may also want to set MouseLookTempKey to 4 or other key code and reset MouseLookChangeKey to 0 for this mode.
MouseLookChangeKey is used to switch mode (turn off mouse look in normal mode or turn it on in activate mode). The mode is restored if you open any other screen. Middle mouse button is set by default.
MouseLookTempKey changes mode while you hold it. Best fit for alternative (WoW) mode.
MouseLookPermKey changes mouse look mode, but the mode doesn't get restored when a dialog is opened.
MouseSensitivityX and MouseSensitivityY control mouse sensitivity. If you want, you can invert Y axis by making its sensitivity negative. Note that you can set values over 100 and well as non-integer values.
MouseSensitivityAltModeX and MouseSensitivityAltModeY are similar, but used for alternative mode.
MouseLookFly option lets you fly up/down by pointing your view in the desired direction.
MouseWheelFly option lets you fly up and down by scrolling your wheel. This is particularly useful for take off in mouse look mode.

Cursor used in mouse look mode is located in Data\MouseLookCursor.bmp

To convert your sensitivity from other games when using raw mouse input, first use an online converter to calculate Valorant sensitivity, then use this formula:
MouseSensitivityX = 25.486222*ValorantSensitivity/MouseSensitivityDirectMul

--------------------------------------------------------------------------------
Errors Reporting:

If an error occurs, send me a report, describing how and when it happened. Attach a savegame if possible. In case of a crash attach ErrorLog.txt file which which would be created in the game directory.
