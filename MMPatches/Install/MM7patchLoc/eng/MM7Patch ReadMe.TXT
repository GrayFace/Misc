GrayFace MM7 Patch v2.4
By Sergey Rozhenko <mailto:sergroj@mail.ru>
https://grayface.github.io/

Official patches, Mok's patch and Black Phantom's patch are included.
Save files are, of course, fully compatible with the unpatched game in both directions.
The patch has no uninstaller to make things simpler.
All configuration is done via mm7.ini, which is populated with main options on the first run.
See description of all UILayout options near the end of ReadMe in the "UI Layout" section. They're marked with "UI.txt:" prefix in the change log.

([+] - feature, [-] - fixed bug, [*] - other)

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
  << MM7 >>
[+] MM7ResTool support, just in case. A warning that it's no longer relevant too. Adding SupportMM7ResTool=1 line to INI would disable the warning.
[-] 'Of Spirit Magic' effect of Glory Shield wasn't working.
[-] 'Water walking' effect of Lady's Escort wasn't working.
[-] Technical: Pressing space was closing evt.Question command dialog.
[-] Technical: My bug: Input field of evt.Question command dialog wasn't shown in UI Layout mode with statusbar auto-hide.
  << Fixes in maps >>
[-] The Tularean Forest (out04): There was no way to enter Clanker's Laboratory after Archibald occupies it even though he says you can enter for target practice.


New in version 2.3.1:
  << MM7, MM8 >>
[-] My bug: ScalingParam1 and ScalingParam2 options were ignored in flexible UI mode.

New in version 2.3:
  << MM6 - MM8 >>
[+] PaperDollInChests option shows paper doll in chest dialog: value 1 (default) will make it visible when you open inventory of a player, value 2 will make it visible right when you open the chest, value 0 will disable it.
[+] Keyboard control: some dialogs can now be controlled by pressing Up/Down and Enter. E.g. NPC conversations. Only those dialogs that already had everything in place to support it are effected.
[+] Save/load dialogs now react to Enter key.
[+] Newer MP3DEC.ASI version. In theory this might fix some problems with MP3 playback.
[-] My bug: If somehow game window managed to become smaller than 640x480, that wasn't handled gracefully in software 32-bit color mode.
  << MM6, MM7 >>
[-] My bug: Quick load key pressed during the death movie was causing a crash afterwards.
  << MM7, MM8 >>
[+] Widescreen-friendly flexible UI in Hardware 3D mode. Controlled by UILayout option.
[+] Accurate effects coordinates in Hardware 3D mode.
[+] Accurate coordinates of top part of the outdoor sky in Hardware 3D mode.
[+] In Hardware 3D mode the game was prioritizing interacting with sprites on sides of the view too often.
[-] In Hardware 3D mode bottom of sprites didn't react to clicks indoors when mouse is away from horizontal center of the view.
[-] My bug: "Pixel-perfect mouse targeting in HD mode" wasn't working.
  << MM7 >>
[+] HigherCloseRingsButton option places the 'Close' button that closes rings view next to the magnifying glass, like in MM6. Default is 1 (enabled).
[-] The 'Close' button that closes rings view in inventory screen was misplaced by 1 pixel.
[-] In English version autonote text for Repair item Master was replaced by a duplicate of Merchant Grandmaster.
[-] In English version Identify Item Grandmaster was written as residing in Avlee instead of Tularean Forest. I previously fixed it in Autonotes, but forgot to fix it in NPC text.
[-] My bug: Pressing the quick load key while a character is taking damage was causing a temporary sound glitch.
  << Fixes in maps >>
[-] Bracada Desert (out06): Shops didn't have a teleporter leading to them, instead there were two Temple teleporters.
[-] Castle Gryphonheart (d33): Taken paintings were reappearing upon reentry.
[-] The Haunted Mansion (d37): Taken painting was reappearing on the wall upon reentry.
[-] In the fix for Thunderfist Mountain exits the party was facing in wrong direction upon entering/exiting the dungeon.

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
  << MM7 >>
[+] Bless etc. icons near player portrait can be transparent now.
[-] Barrels and other static sprites were shrinked vertically indoors in D3D mode.
[-] Fly and Water Walk icons weren't displayed in simple message dialog.
[-] Health bars of first 2 players and danger indicators of all players were misplaced by 1 pixel (controlled by FixInterfaceBugs hidden option).
[-] My bug: Russian (Buka) version contained a broken NPC greetings file.
[-] My bug: Russian description in installer had a wrong encoding.
  << Fixes in maps >>
[-] Hall of the Pit (t04): Teleporters were rotating the party to the right.
[-] Nighon (out10): Right side of the tavern door didn't react to clicks.
[-] My bug: Fixes for Avlee (out14), Barrow II (mdk03) and some for Nighon (out10) weren't included.

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
[-] Blasters and some spells couldn't target rats.
[-] Crash with sprites with scale too small (happens with MM6HD).
[-] Town Portal wasting player's turn even if you cancel the dialog.
[-] EVT commands couldn't operate on some skills.
[-] Crash on exit.
[*] Some options made 'hidden' to reduce INI clutter.
  << MM6, MM7 >>
[-] My bug: crash when loading custom LOD archives. (don't know how it even worked at all!)
[-] Out-of-bounds memory read in buy dialog when no player is active.
[-] Shops were buying blasters.
  << MM7, MM8 >>
[+] Mipmapping in D3D, controlled by "MipmapsCount" option. Value of 3 is optimal. Bigger values lead to less flickering at distance, but reduce resolution too much. Set to 1 to disable, as it was in original game. Set to -1 to generate a lot of mipmaps.
[-] There was a small semi-transparent black contour around sprites and sea shore in Hardware 3D mode.
[-] Broken but unidentified items were green instead of red if you go to a shop to repair them.
[-] Casting Telepathy spell or stealing from a monster used to prevent you from finding random items in its corpse.
[-] Light gray blinking in full screen (not on every system).
[-] Arcomage crashing, hanging.
[-] Loading game while in movement phase of turn based mode leading to inability to cast spells.
[-] Monsters summoned by other monsters had wrong monster as their ally.
[-] The game was using "asynchronous" mouse handling incompatible with mouse look of the patch if "D3D Device" = 1 in the registry. Hidden "DisableAsyncMouse" patch option controls this.
[-] items.txt: now special items accept standard English "of ..." strings. This should fix them missing their attributes in some localizations.
[-] Shops were unable to fix some artifacts.
[-] Lava was hurting players in air.
[-] Pressing Alt+Tab during the win movie 'breaking' the game.
[-] Memory leak in mipmaps generation code.
[*] ReputationNumber option now shows positive values for good reputation. It showed negative values before, just like it's represented internally in the game.
  << MM7 >>
[-] My bug: Axe skill adding damage at expert level instead of master.
[-] GM Staff ignoring Armsmaster bonus to Damage.
[-] Taledon's Helm not increasing Light Magic.
[-] My bug: Palettes were messed up in Avlee.
[-] My bug: FixChests=1 was broken - event execution was stopped after the chest is opened.
[-] Monsters summoning wrong monsters (e.g. Archmages summoning Sylphs).
  << Fixes in maps >>
[+] Now quest for Champion promotion accepts Lord difficulty arena victories as well as Knight.
[-] The Titans' Stronghold, The Breeding Zone, The Tidewater Caverns, Barrow II (d09, d10, d17, mdk03): Better handling of chests with quest items.
[-] The Wine Cellar (d16): Exit door hint changed from "Leave the Vampire Family House" to "Leave the Wine Cellar".
[-] Celeste (d25): Central fountain only worked once.
[-] Nighon (out10): Warlocks were killing 2 peasants. Half of training building door wasn't clickable.
[-] Harmondale (out02): Beacons weren't shown fired up after reloading.
[-] William Setag's Tower, The Hall of the Pit (mdt10, t04): "Door" was set as hint for chests.
[-] Barrow II (mdk03): Rat was often spawning in a wall.
[-] Avlee (out14): Flying rock at x:-15088 y:-4288.
[-] The Land of the Giants (out12): A well at coordinates x:14972 y:3968 was meant to cost 5000, but was usable without paying, thus becoming a cheat when used with Protection from Magic.
[-] Fixes of Black Phantom patch (with additional improvements):
- The Maze (d02): "Haldar's Remains" quest item was disappearing if not taken the first time the chest is opened.
- Stone City (d24): when resting there was a chance of dwarves attacking the party.
- Emerald Island (out01): Anvil was called "Button". Autonote "2 points of permanent Luck from the well on the western edge of Emerald Island" wasn't used.
- Castle Harmondale (d29): Quest "0" no longer appears in Quest Log. Under some circumstances no human/elf/neutral flags were placed in the castle after delivering the artifact. Good/evil flags didn't always match the alignment. Golem was appearing before you complete the quest (and animate it) if you found all parts.
- The Wine Cellar (d16): Unique vampire possesing Vampire's Cape item wasn't appearing in the location. Now a Light path quest requires not just entering the Wine Cellar, but killing this vampire as it was planned by developers.
- The Pit (d26): "Breeding Zone" entrance animation wasn't used.
- Colony Zod (d27): Archibald trial movie was played each time you exit the colony after killing Xenofex. Roland was giving the key each time you click on his cell.
- The Dragon Caves (mdt12): A dragon was often spawning inside a wall.
- Deyja (out05): guards of the northern town were always hostile.
- Texts Kastore was saying upon finding dark/light altar pieces were swapped.
- Reward for Loren/Riverside Plans quests even when time runs out.
- Final quest wasn't removed from Quest Log upon completion of the game.
- Wrong autonote text for Identify Item Grandmaster (Tularean Forest instead of Avlee).
- William Lasker was calling the party "Rogues" in his greeting after promotion to Spy, now he says "Spies".
- Optional: NWC made a black Mega-Dragon monster with some interesting abilities, but the "Mega-Dragon" in The Dragon Caves (mdt12) was actually a red dragon with resistances set to 0 (thus, weaker than standard ones!). Not anymore.
- Optional: Now there are videos when you enter Tunnels to Eeofol or move between Nighon Tunnels and Thunderfist Mountain. These videos were unused before.
- Optional: Eastern tunnel of Thunderfist Mountain was leading the the western village and vice versa.

Other changes:
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
[+] FreeTabInInventory lets you select dead characters by Tab key while in character screen. Default is 1 (enabled).
[+] Recovery Time value is displayed in Attack and Shoot descriptions.
[+] NoDeathMovie option makes your death quicker by disabling the movie. Default is 0 (disabled).
[+] NoCD option. Works only if "Anims\Magic7.vid" is present. Default is 1 (enabled).
[+] NoIntro option disables logo movies and displays the intro when a new game starts. Default is 0 (disabled).
[+] HardenArtifacts options lets you use Harden Item on artifacts. Default is 1 (enabled).
[+] Harden Item, Recharge Item and other similar potions don't disappear when you try to use them on improper items.
[+] NoVideoDelays disables delays before and after a video is shown. Default is 1 (enabled).
[+] ReputationNumber shows numerical reputation value together with category name. Default is 1 (enabled).
[+] PaletteSMul and PaletteVMul options let you change how bright or colorful the game looks. HSV representation of colors is used.
[+] Now monsters are colored properly in Direct3D, no more tinting. d3dsprite.hwl isn't used anymore.
[+] Monster contours are taken into account in Direct3D when you click on them.
[+] "NoBitmapsHwl" enables textures to be taken from bitmaps.lod instead of d3dbitmap.hwl in Direct3D. This leads to better quality of textures, but too much sharpness in the distance. Default is 1 (enabled).
[+] HDWTRCount and HDWTRDelay options control number of water frames (up to 15) and delay between them in D3D.
[+] Smoother D3D water frames included.
[+] HorsemanSpeakTime and BoatmanSpeakTime options control time needed for horseman or boatman to say "Let's go" before new map starts loading.
[+] When run in 32 bits color mode automatically switches to 16 bits in Windowed mode.
[+] Identify Monster shows monster resistances numbers now.
[+] Custom LODs (for mods). For example, Data\*.icons.lod archives would be loaded after icons.lod, possibly replacing its content. Same with every other archive.
[+] Extracted files from events.lod are loaded from DataFiles folder. Useful for modders. (see below for details)
[+] Loads all .dll files from ExeMods directory (this is used by MMExtension and you can use it to add your patch).
[+] Improved errors reporting. (see below)
[+] BlasterRecovery option controls minimal blaster recovery time. Default is 5. Game default was 0.
[+] Door state switching command extended. Now modders can pass 3 instead of 2 to switch door state even if it's moving.
[-] Mok's patch bug: there were glitches of smack animation in houses and even crashes sometimes.
[-] You could drink from fountains multiple times if all party members are inactive.
[-] You could attack with inactive party members. Setting FixInactivePlayersActing=0 would disable this fix.
[-] Town Portal pauses the game now.
[-] Now you can have gaps between save slots. Save and Load would target the same slot anyway.
[-] Walk Sound disappearing problem fixed.
[-] No need to set compatibility on Win XP anymore.
[-] Inactive characters could use scrolls.
[-] Items bonuses to weapon skills were ignored in recovery time calculation (Ania Selving artifact is the only such item).
[-] Protection from Magic didn't protect from Poison.
[-] 'of Feather Falling' enchantment didn't work (and Hermes' Sandals too).
[-] Dagger in second hand used to do triple damage even on Expert level.
[-] Daggers had 10% chance to do triple damage no matter what Dagger skill you have. ProgressiveDaggerTrippleDamage option makes daggers do triple damage with probability equal to skill. Default is 1 (enabled).
[-] Haste didn't work when some members are dead and weak at the same time.
[-] Buggy autosave file name localization removed.
[-] Now items that didn't fit into a chest appear in it when you free space for them and reopen the chest. (FixChests option)
[-] Return button in game menu didn't work correctly.
[-] DirectDraw errors reporting is disabled. It was leading to numerous problems on some computers.
[-] Attacking big monsters in melee in Direct3D was a problem before. Players tended to shoot in them.
[-] Lich jars not appearing in The Walls of Mist bug fixed.
[-] Credits speed is now limited.
[-] Party generation screen animation speed is now limited.
[-] 'Invalid ID reached!' that was spamming the ErrorLog.txt is now ignored.
[-] Fixed a couple of index-out-of-bounds errors.
[-] Spear skill wasn't added to damage on expert level, it required master level.
[-] Autosave was done after the cost of transport is withdrawn.
[-] Waiting (using Rest dialog) used to recover characters twice as fast.
[-] Key strokes could potentially be ignored if some other programs run at the same time and use the same keyboard access method.
[-] A rare case of "negative/0" caused a crash in stats screen.
[-] Setup for keys like R (Rest) wasn't loaded properly.
[-] Lloyd Beacon used to autosave game after decreasing spell points and adding recovery delay.
[-] Town Portal used to autosave game after adding recovery delay.
[-] Town Portal triggered autosave even when teleporting within current location.
[-] Some players experienced a beam of Prismatic Light that doesn't disappear.
[-] Movement rounding issues fixed properly. Walking and strafes weren't precise because of these issues and jump height was lower than it should be.
[-] Save game failure on some computers. Actually caused by a bug of some system software, not the game itself.
[-] Games.lod archive required very special sorting.
[-] The door of a shop on an island in Tatalia didn't react to mouse clicks.

Changes of Mok's patch:
- fixed Psychic Shock spell (damage 12 + 1-12 instead of 12 + 1).
- better 3D hardware support (Win2k/XP)
- better sound & video support (more recent Bink, Smacker and Miles Sound System libraries)
- removed buggy hard drive free space check
- fixed Hour of Power spell (Haste part wasn’t working). Thanks to Mike Kienenberger for the fix.
- fixed a saving game message in the Arena.
- fixed a bug which caused inventory corruption if you used Recharge spell on a wand with no charges. Now it will simply fail on such wands. 
- the game will no longer generate wands with max number of charges = 0. It will be minimum 1 charge. Existing wands won't be upgraded. 
- fixed a bug in Paralyze spell. It will not work on dead opponents anymore.
- you can toggle running mode by pressing caps lock key. This is controlled by CapsLockToggleRun option since GrayFace Patch. Default is 0 (disabled).

Changes of official patch 1.1 are listed in Readme.txt

All options are controlled by mm7.ini. It is created when the game is run the first time.
Some localization options are kept in mm7lang.ini. You can change them or translate to your language. If you create the same options in mm7.ini they will override those from mm7lang.ini.

--------------------------------------------------------------------------------
Quick Saves:
Press F11 to use quick save. You will see "Game saved!" message. "QuickSavesKey" option in mm7.ini controls the key used to save the game.
"QuickSavesCount" option controls the number of quick saves.
"QuickSavesName" option controls names of quick saves. Default is "Quicksave".
"SpaceBeforeQuicksaveDigit" controls whether there should be a space between "Quicksave" and the number of quick save.
"QuickLoadKey" option controls the quick load key.

--------------------------------------------------------------------------------
How to use MP3 Music:
Create "Music" folder in the game directory and place there files from "2.mp3" to "20.mp3" corresponding to CD tracks. Set "PlayMP3" to 1. Unlike CD music, MP3 music volume is affected by Sound Volume you set in Settings menu, so it's a good idea to keep it at maximum.

--------------------------------------------------------------------------------
DataFiles:
Create "DataFiles" folder in the game directory. To modify a file in events.lod extract it and place into the "DataFiles" folder. It will be used by the game instead of original file. So, you don't need to insert files into events.lod each time you modify them.
"DataFiles" option controls this. Default is 1 (enabled).

--------------------------------------------------------------------------------
Custom Archives
Custom archives are the best way to distribute new and modified content of a mod. Here's an explanation of their loading order: https://www.dropbox.com/s/iv9c2jc8abbrj6a/CustomLods.txt?dl=0

--------------------------------------------------------------------------------
Mouse Look

To enable mouse look set MouseLook option to 1.
Mouse look can work in two modes. The default mode is like in 3D actions and alternative mode is closer to World of Warcraft and similar games.
Here is my preset for 3D action mode: http://sites.google.com/site/sergroj/mm/MM6MouseLook.rar

You can activate alternative mode by setting MouseLookUseAltMode option to 1 or by pressing Caps Lock if the CapsLockToggleMouseLook option is set to 1.
MouseLookChangeKey is used to switch mode (turn off mouse look in normal mode or turn it on in activate mode). The mode is restored if you open any other screen.
MouseLookTempKey changes mode while you hold it. Best fit for alternative (WoW) mode.
MouseSensitivityX and MouseSensitivityY control mouse sensitivity. If you want, you can invert Y axis by making its sensitivity negative. Note that you can set values over 100.
MouseSensitivityAltModeX and MouseSensitivityAltModeY are similar, but used for alternative mode.
MouseLookFly option lets you fly up/down by pointing your view in the desired direction.
MouseWheelFly option lets you fly up and down by scrolling your wheel. This is particularly useful for take off in mouse look mode.

Cursor used in mouse look mode is located in Data\MouseLookCursor.bmp

--------------------------------------------------------------------------------
Video in Hardware Accelerated Mode
If the videos aren't playing in hardware accelerated mode, try the following:
Press Win+R, type Regedit, locate the following key in it:
HKEY_LOCAL_MACHNE/Software/New World Computing/Might and Magic VII/1.0 
Or on 64-bit versions of Windows:
HKEY_LOCAL_MACHNE/Wow6432Node/New World Computing/Might and Magic VII/1.0 
Set 2dacceloff to 1.

--------------------------------------------------------------------------------
UI Layout
If you set UILayout=UI, a flexible UI layout (named "UI") will be used. The layout is defined in corresponding Data\UI.txt file and uses icons.UI.lod graphics. It's possible to extend it with *.UI.txt files or create brand new layouts, but I haven't made any description for its format.

Here are options you'll find under [UILayout=UI] section after first use of it:
Scale=1  - Increasing/decreasing it would make all UI bigger/smaller
PartyScale=1.11  - Increasing/decreasing would make portraits bigger/smaller
PortraitsDistance=17  - Distance between portraits
FlyEtcOnTop=1  - Setting it to 0 would move Fly and Water Walk icons to the bottom of the view
FOVMul=1  - Field of view multiplier
StatusbarScale=0  - By default statusbar scale is chosen automatically, but you can set it manually
StatusbarPlace=0  - Can have 3 values: -1 - on top of the screen, 0 - above portraits, 1 - below portraits
ShrinkStatusbar=1  - Statusbar size is determined by text in it (ignored if StatusbarPlace=1 or HideStatusbar=0)
HideStatusbar=1  - Hide statusbar when it's empty (ignored if StatusbarPlace=1)
MouseShiftY=30  - Vertical shift of the middle point of the view
proportionate average of these values is used)

--------------------------------------------------------------------------------
Errors Reporting
If an error occurs, send me a report, describing how and when it happened. Attach a savegame if possible. In case of a crash attach ErrorLog.txt file which which would be created in the game directory.
