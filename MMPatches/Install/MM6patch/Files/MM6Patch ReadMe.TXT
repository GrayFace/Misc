GrayFace MM6 Patch v2.1
By Sergey Rozhenko <mailto:sergroj@mail.ru>
https://grayface.github.io/

Official patches, Mok's patch and Angel's patch are included.
Save files are, of course, fully compatible with the unpatched game in both directions.
The patch has no uninstaller to make things simpler.

([+] - feature, [-] - fixed bug, [*] - other)

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
[-] Key strokes could potentially be ignored if some other programs run at the same time and use the same keyboard access method.
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
Press F11 to use quick save. You will see "Game saved!" message. "QuickSaveKeyCode" option in mm6.ini controls the key used to save the game.
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
Mouse Look

To enable mouse look set MouseLook option to 1.
Mouse look can work in two modes. The default mode is like in 3D actions and alternative mode is closer to World of Warcraft and similar games.
Here is my preset for 3D action mode: http://sites.google.com/site/sergroj/mm/MM6MouseLook.rar

You can activate alternative mode by setting MouseLookUseAltMode option to 1 or by pressing Caps Lock if the CapsLockToggleMouseLook option is set to 1. You may also want to set MouseLookTempKey to 4 or other key code and reset MouseLookChangeKey to 0 for this mode.
MouseLookChangeKey is used to switch mode (turn off mouse look in normal mode or turn it on in activate mode). The mode is restored if you open any other screen. Middle mouse button is set by default.
MouseLookTempKey changes mode while you hold it. Best fit for alternative (WoW) mode.
MouseSensitivityX and MouseSensitivityY control mouse sensitivity. If you want, you can invert Y axis by making its sensitivity negative. Note that you can set values over 100.
MouseSensitivityAltModeX and MouseSensitivityAltModeY are similar, but used for alternative mode.
MouseLookFly option lets you fly up/down by pointing your view in the desired direction.
MouseWheelFly option lets you fly up and down by scrolling your wheel. This is particularly useful for take off in mouse look mode.

Cursor used in mouse look mode is located in Data\MouseLookCursor.bmp

--------------------------------------------------------------------------------
Wide Screens
This isn't related to the patch, but note that on wide screens you can set up your video card properties not to stretch the image. At least Nvidia drivers allow setting this in Nvidia control panel.

--------------------------------------------------------------------------------
Errors Reporting
If an error occurs, send me a report, describing how and when it happened. Attach a savegame if possible. In case of a crash attach ErrorLog.txt file which which would be created in the game directory.
