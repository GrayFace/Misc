library MM8patch;

uses
  SysUtils,
  Classes,
  RSSysUtils,
  Windows,
  RSQ,
  Hooks in 'Hooks.pas',
  Common in 'Common.pas',
  MP3 in 'MP3.pas',
  DXProxy in '..\mmcommon\DXProxy.pas',
  MMCommon in '..\mmcommon\MMCommon.pas',
  D3DHooks in '..\mmcommon\D3DHooks.pas',
  MMHooks in '..\mmcommon\MMHooks.pas',
  LayoutSupport in '..\mmcommon\LayoutSupport.pas',
  MMLayout in '..\mmcommon\MMLayout.pas';

{$R *.res}

{
Version 1.0:
[+] Multiple Quick Saves.
[+] F2 toggles Double Speed mode. DoubleSpeedKey option controls the key.
[+] TurnSpeedNormal and TurnSpeedDouble options control speed of smooth turning. Default is 100% for normal speed and 120% for double speed.
[+] InventoryKey option lets you open character's inventory screen by pressing 'I' instead of clicking a character portrait. Set it to 0 to disable.
[+] ToggleCharacterScreenKey opens or closes character screen. The default key is '~'. Set it to 0 to disable.
[+] FreeTabInInventory lets you select dead characters by Tab key while in character screen. Default is 1 (enabled).
[+] Recovery Time value is displayed in Attack and Shoot descriptions.
[+] PlayMP3 option lets you play MP3 files instead of CDAudio. Default is 0 (disabled).
[+] MusicLoopsCount option controls loops count of music. Set it to 0 for infinite loop.
[+] No Death Movie option. Default is 0 (disabled).
[+] NoCD option. Default is 1 (enabled).
[+] NoIntro option disables starting movies. Default is 0 (disabled).
[+] HardenArtifacts options lets you use Harden Item on artifacts. Default is 1 (enabled).
[+] Harden Item, Recharge Item and other similar potions don't disappear when you try to use them on improper items.
[+] NoVideoDelays disables delays before and after a video is shown. Default is 1 (enabled).
[+] ReputationNumber shows numerical reputation value together with category name. Default is 1 (enabled).
[+] HorsemanSpeakTime and BoatmanSpeakTime options control time needed for horseman or boatman to say "Let's go" before new map starts loading.
[+] MouseLookBorder option lets you can change size of area used to rotate by pressing right mouse button. Set it to -1 to remove the area completely.
[+] JumpSpeed option lets you can change Jump spell speed. Default is 1100. Game default was 1000.
[+] You can rest on shipyards.
[+] Extracted files from EnglishT.lod are loaded from DataFiles folder. Useful for modders.
[+] Loads all .dll files from ExeMods directory (I will use it in future).
[+] Improved errors reporting. (see below)
[-] There were glitches of smack animation in houses and even crashes sometimes.
[-] Events were executed incorrectly is all party members are inactive.
[-] You could attack with inactive party members.
[-] Now save/load slot is preserved.
[-] No need to set compatibility on Win XP anymore.
[-] Inactive characters could use scrolls.
[-] Items bonuses to weapon skills were ignored in recovery time calculation.
[-] Protection from Magic didn't protect from Poison.
[-] 'of Feather Faling' enchantment didn't work (and Archangel Wings too).
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

Version 1.1:
[-] Now items that didn't fit into a chest appear in it when you free space for them and reopen the chest (FixChests option)
[-] (not fixed) Some people experienced a crash in load screen in previous version due to long quicksaves names.

Version 1.1.1:
[-] Removed quicksave/autosave names length limit. In localized versions the limit could be exceeded which was leading to a crash.

Version 1.2:
[+] DataFiles lookup can now be disabled (DataFiles option)
[+] Any hooks can be disabled now
[-] DirectDraw errors are now ignored

Version 1.3:
[+] Colored monsters in D3D
[+] Monster contours are taken into account in Direct3D when you click on them.
[+] Textures from LOD in D3D
[+] Removed limit on sprites count
[+] Use Delphi memory manager
[+] Correct door state switching: param = 3
[-] Attacking big monsters D3D
[-] Credits speed
[-] Party generation screen animation speed
[-] Fix facet and ground ray interception checking out-of-bounds
[-] There is a facet without vertexes in Necromancers' Guild
[-] Fix sound loading
[-] Fix spells.txt, history.txt parsing out-of-bounds
[-] Ignore 'Invalid ID reached!'
[-] Code left from MM6

Version 1.3.1:
[-] My bug: an empty Saves directory was leading to crash.
[-] In Plane of Air FPS was very low and Error Log was spammed with 'Too many stationary lights!' messages.
[-] rnditems.txt was freed before the processing is finished

Version 1.4:
[+] Mouse look
[+] AlwaysStrafe option
[-] Two players experienced a beam of Prismatic Light that doesn't disappear

Version 1.5:
[+] MouseLookFly
[+] MouseWheelFly
[+] Mouse look update: MouseLookChangeKey, MouseLookTempKey, MouseLookUseAltMode...
[+] Custom cursor for mouse look mode
[+] Identify Monster shows monster resistances now
[+] Control palette gamma
[+] Stop time by right click
[+] StartupCopyrightDelay
[+] Now Turn Delta is set to Smooth by default
[+] When run in 32 bits mode automatically switches to 16 bit when Windowed mode is used
[+] Quick load
[+] Autorun
[-] Town Portal and Lloyd Beacon dialogs reacted spell book click
[-] Fixed strafes and walking
[-] negative/0 causes a crash in stats screen
[-] My bug: skill bonuses to recovery times were ignored
[-] Autosave before taking money for transport, not after
[-] Key strokes could be ignored if some other programs run at the same time (and call GetAsyncKeyState)
[-] In mouse look mode mouse could leave window when moved fast
[-] Lloyd: take spell points and action after autosave, not before
[-] TP: take action after autosave, not before
[-] Death on Arena no longer causes a crash 
[-] Two players experienced a beam of Prismatic Light that doesn't disappear - the right fix

Version 1.5.1:
[-] My bug: Dead monsters could sometimes move in version 1.5 

Version 2.0:
[+] Custom LODs
[+] MLookStartTime
[+] Auto strafe in MouseLook (+StandardStrafe invisible option)
[+] FixInactivePlayersActing options controls corresponding fix
[+] HDWTRCount and HDWTRDelay options control number of water frames (up to 15) and delay between them in D3D
[+] Improved D3D water frames included
[-] Save game failure on some systems
[-] *.dlv and *.ddm
[-] Unnecessary debug info was written to ErrorLog.txt
[-] The checkbox for disabling original mouse look during setup didn't work
[-] MouseLookUseAltMode wasn't supported
[-] "`" or "i" written in MMExtension console were causing character screen to open
[-] Same thing with mouse movement when mouse look is on
[-] Correctly fixed movement rounding problems, including jumps

Version 2.1:
(MM6 - MM8)
[+] SupportTrueColor, HD in D3D, RenderMaxWidth, RenderMaxHeight, ScalingParam1, ScalingParam2
[+] WindowWidth, WindowHeight
[+] BorderlessWindowed
[+] CompatibleMovieRender, SmoothMovieScaling
[+] Custom .snd and .vid archives
[+] TurnBasedSpeed
[+] MouseLookRememberTime
[+] MouseLookWhileRightClick
[+] PlayMP3 option now supports WAV files
[+] Black potion isn't wasted if it has no effect
[+] Infinite view distance in dungeons
[+] FixInfiniteScrolls option controls corresponding fix
[+] Another approach to fixing chests: now chest contents are reordered to make most valuable items be put into chest first. This can be disabled by setting FixChestsByReorder=0
[*] Some options made 'hidden' to reduce INI clutter.
[-] My bug: *.evt and *.str weren't loaded correctly from DataFiles.
[-] Fix problems with timers: immediate re-trigger in MM6, getting reset by entering location too early (FixTimers hidden option)
[-] Monsters are unlikely to jump from a bridge into lava now. Hidden "MonsterJumpDownLimit" controls the height from which they won't jump (500 by default)
[-] Jumping nerfed a bit, because the party started jumping too high after movement rounding fix. Also, "FixMovement=0" hidden option added that returns vanilla movement.
[-] Dragons and some spells couldn't target rats
[-] Crash with sprites with scale too small (happens with MM6HD)
[-] Town Portal wasting player's turn even if you cancel the dialog
[-] Evt commands couldn't operate on some skills
[-] Crash on exit
(MM7, MM8)
[-] Black border around sprites and sea shore in D3D
[-] Broken but unidentified items were green instead of red if you go to a shop to repair them.
[-] Casting Telepathy spell or stealing from a monster used to prevent you from finding random items in its corpses
[-] Light gray blinking in full screen (not on every system)
[-] Arcomage crashing, hanging
[-] Loading game while in turn based mode leading to inability to cast spells
[-] Monsters summoned by other monsters had wrong monster as their ally
[-] The game was using "asynchronous" mouse handling incompatible with mouse look of the patch if "D3D Device" = 1 in the registry. Hidden "DisableAsyncMouse" patch option controls this.
[-] items.txt: now special items accept standard English "of ..." strings. This should fix a number of localizations
[-] Shops were unable to fix some artifacts
[-] Lava was hurting players in air
[-] Memory leak in mipmaps generation code
[*] ReputationNumber option now shows positive values for good reputation. Before it showed negative values, just like it's represented internally in the game.
(MM8)
[-] Sky bitmap getting reset each time the game is loaded. To turn off the fix, add FixSkyBitmap=0 line.
[-] Unicorn King appearing before obelisks are taken and respawning. Add FixObelisks=0 to INI to disable the fix
[-] Flute making Heal sound
[-] Opening spell book and pessing "Quick Spell" key used to set quick spell to -1, causing a crash when you enter character screen
[-] My semi-bug: roster.txt and pcnames.txt weren't loaded from DataFiles
[-] Monsters couldn't cast Paralyze spell, but were wasting turn
[-] My bug: Since some version of my patch movies were again immediately cancelled when shown from a dialog.
[-] My bug: ProgressiveDaggerTrippleDamage fix didn't work in MM8

Version 2.2:
(MM6 - MM8)
[+] Resizeable window
[+] StretchWidth, StretchHeight, StretchWidthFull, StretchHeightFull
[+] Now in Software rendering mode the view is always scaled linearly, which makes it less flickery
[+] MouseLookCursorHD
[+] Quick load key works during the death movie
[+] Patch now bypasses dgVoodoo DLLs if SupportTrueColor is not disabled
[+] Minimaps zoom level is remembered indoors, not just outdoors as before
[+] Customizable mouse cursor: Data\MouseCursorArrow.cur and Data\MouseCursorTarget.cur are used if present
[-] Fixed a crash due to facet interception checking out-of-bounds (found in Tatalia in MM7)
[-] Inactive characters couldn't interact with chests
[-] TFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
[-] My bug: ScalingParam2 was read from ScalingParam1 entry
[-] My bug: Mouse position translation was wrong
[*] Smarter FixInactivePlayersActing
(MM7, MM8)
[+] Accurate sprites coordinates in D3D
[+] Accurate mouse in HD mode
[+] TurnBasedWalkDelay
[+] MipmapsBase
[+] HDWTRCountHWL, HDWTRDelayHWL
[+] Hidden FixMonsterSummon option
[-] Combining IsWater and AnimateTFT caused texture change in D3D
[-] Fixed a rare crash caused by a facet without a single vertex
[-] My bug: Sparks effect was displayed incorrectly in the previous version
(MM8)
[+] "FixQuickSpell" hidden option
[-] NoWaterShoreBumpsSW
[-] Mass Distortion and Implosion spells wasted monsters' turn, but didn't work
[-] 8 leftmost pixels of paper doll area didn't react to clicks
[-] Monsters/items/effects not visible on the sides of the view outdoors
[-] Party wasn't centered on the minimap

Version 2.3:
(MM6-MM8)
[+] PaperDollInChests
[+] Keyboard control
[+] Enter in save/load dialogs
[-] My bug: If somehow game window managed to become smaller than 640x480, it wasn't handled gracefully in software 32-bit color mode.
(MM7, MM8)
[+] Widescreen support with new UI
[+] Better blackening of background in moster info window (almost doesn't matter for users)
[+] In D3D the game was prioritizing interacting with sprites on sides of the view too often
[+] Accurate effects coordinates in D3D
[+] Accurate coordinates of top part of the outdoor sky in D3D
[-] In D3D on right/left sides of the screen bottom of sprites didn't react to clicks indoors
[-] One bitmap loading function was unable to load uncompressed bitmaps
[-] My bug: Precise mouse targeting wasn't working
(MM8)
[-] Buildings weren't drawn on sides of the screen
[-] Indoors the FOV wasn't increased, so the area of view was smaller than in MM6 and MM7
[-] Quickly pressing R,R,Esc to rest was glitching the game if monsters attacked you in your sleep  
[-] Enter key pressed in the main menu had an effect in the game
[-] Screenshots of Saves were stretched vertically (fixed in true color D3D only for now)

Version 2.3.1:
(MM6, MM8)
[+] Right click in Enchant Item dialog
(MM7, MM8)
[+] A few new UI layout commands
[-] My bug: ScalingParam1 and ScalingParam2 were ignored in flexible UI mode

Version 2.4:
(MM6-MM8)
[+] FixChestsByCompacting
[+] PlaceChestItemsVertically
[+] SpriteAngleCompensation
[+] PostponeIntro
[+] ClickThroughEffects
[+] DisableHooks
[+] Map entrance dialog can now be called from NPC topic anywhere
[-] FixSFT - SFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
[-] My bug: keyboard control of dialogs was breaking evt.Question in houses
(MM7, MM8)
[+] bitmaps.lwd support
[+] TrueColorTextures
[+] TreeHints
[+] Better D3D init errors reporting
[-] SpriteInteractIgnoreId
[-] GM Axe didn't halve armor class
[-] Disease2 and Disease3 bonus effects of monsters weren't working, Disease1 was working as Disease3
[-] Poison2 and Poison3 bonus effects of monsters were swapped
[-] My/DirectX bug: Game was failing to start in big resolutions, because Direct3D 7 doesn't work with them
[-] My bug: The game could crash when pressing Esc in UI Layout mode
[-] My bug: Out-of-bounds write when layout definition has long loops
[-] My bug caused by Delphi bug: numbers in some layout expressions were read incorrectly
[-] My bug: Memory leak when UI layout is reloaded
(MM8)
[-] Players hired in turn-based mode were going into Adventurers Inn instead of joining the party
[-] My bug: PaperDollInChests option was causing a crash in Software rendering mode
[*] StartupCopyrightDelay option made hidden and 0 by default

Version 2.4.1:
(MM6-MM8)
[+] MouseDX, MouseDY in PatchOptions
(MM8)
[-] My bug: Random items weren't appearing in chests with quest items

Version 2.5:
(MM6-MM8)
[+] WinScreenDelay hidden option controls Win screen delay during which all input is ignored. Default is 500 (half a second instead of game's original 5 seconds). 
[+] Direct unaccelerated mouse input supported through MouseSensitivityDirectMul option.
[+] FixConditionPriorities
[+] EnableAttackSpell
[+] ShowHintWithRMB
[+] ShooterMode
[+] GreenItemsWhileRightClick
[+] AddDescriptions - Descriptions in INI
[+] DeadPlayerShowItemInfo
[+] dist_mist, ViewDistanceD3D
[+] MonSpritesSizeMul
[+] FixHouseAnimationRestart
[+] CheckFreeSpace - Free space check when saving a game
[+] ExitDialogsWithRightButton
[+] MouseLookPermKey
[+] Automatic horseman and boatsman speak time detection
[+] KeepEmptyWands
[-] Changing item graphics was causing inventory corruption
[-] HintStayTime
[-] Casting stronger buffs did nothing if a weaker, but longer one is in place
[-] Item spells were causing bugs when cast onto the very 1st item in the inventory
[-] Now you can pick up stolen items from corpses of thieves (in MM7 and MM8 this was originally the case, but there was no indication)
[-] Monster hits were causing a player switch even when Endurance eliminates hit recovery
[-] When casting a Quick Spell the spell points check was incorrect (it assinged GM spell to another school of magic)
[-] AOE damage wasn't dealt to paralyzed monsters
[-] Monster spell attacks were broken (esp. Poison Spray, Shrapmetal) (thanks cthscr)
    MM6: All spells were doing Fire damage
[-] KeepCurrentDirectory
[-] FixDeadPlayerIdentifyItem
[-] Fixed another crash due to facets without vertexes
[-] Fix full brightness for a minute at 5:00 AM
[-] New Day wasn't triggered on beginning of a month when resting until down and pressing Esc
[-] Random item generation routine was generating the 1st item with bigger probability and last item with smaller probability
[-] Buff duration was displayed incorrectly in the cases like "1 day 5 minutes"
[-] "N/A" string for ranged damage wasn't localizeable
[-] FixWaterWalkManaDrain
[-] My bug: You were able to learn unavailable magic skills with keyboard navigation
[*] My inactive players acting fix wasn't perfect
[*] Now spell skills that don't fit are drawn over buttons. Still better than making them inaccessible.
[*] 3DO and other logos in postponed intro, unless NoIntoLogos
(MM7, MM8)
[+] TrueColorSprites hidden option, off by default to prevent 'out of memory' with HD sprites
[+] The game doesn't crash on exit if d3dsprite.hwl and d3dbitmap.hwl are missing
[+] Minimap background picture (mainly for color blind)
[+] ClickThroughEffects now works in Hardware mode
[+] SystemDDraw / support dgVoodoo
[+] IndoorFovMul (0.813)
[+] ClimbBetter
[-] Fixed DirectX 7 bug: inability to work with big resolutions
[-] Restore AnimatedTFT bit from Blv rather than Dlv to avoid crash
[-] FixMonstersBlockingShots
[-] Duration string for items wasn't localized
[-] Monsters shot at from a distance appearing green on minimap
[-] Display Inventory screen didn't work with unconscious players
[-] Damage bonus of Assassins' and Barbarians' enchantments didn't work
[-] 'GM' spell skill wasn't read from Monsters.txt
[-] FixIceBoltBlast
[-] FixEnergyDamageType - Ener damage type was being turned into Earth
[-] No more gamma.pcx
[-] Souldrinker was hitting monsters beyond party range
[-] Acid Burst was doing physical damage
[-] Inability to equip sword or dagger when non-master spear is equipped
[-] Arcomage hanging in some circumstances
[-] Walking on water was dealing Fire damage
[-] Bow skill bonus from items wasn't added to damage with GM Bow skill
[-] When a monster attacked another one with a spell, wrong spell was used in damage calculation
[-] Melee monsters under Berserk were hitting party from a far if their target died
[-] Alchemy failure was breaking Hardened items
[-] 'of Acid' was dealing Water damage instead of Body
[-] ArmageddonElement
[-] LeaveMap event not called on travel
[-] Monsters summon overflow crash
[-] 'Body' attack type was read as physical for monsters
[-] Windows 10 incompatibility
[-] My bug: Crash in full screen if BorderlessFullscreen=0
[-] My bug: Mipmaps were always on in full screen if BorderlessFullscreen=0 and MipmapsCount>1
[-] My bug: Empty icons were causing division by zero in UI Layout code
[-] My bug: Empty sprites causing a crash in D3D mode
(MM8)
[-] Vampires weren't immune to Mind
[-] lloyd pcx broken
[-] 'Spirit Lash', 'Inferno', 'Prismatic Light' were broken when used by monsters

Version 2.5.1:
(MM7, MM8)
[-] My bug: Energy damage wasn't displayed in identify monster dialog
(MM8)
[-] Intro was unskippable on first launch.

Version 2.5.2:
(MM6-MM8)
[*] Now Stats screen displays a condition that determines stats, unlike all other places
(MM7, MM8)
[-] "Nothing here" was shown on the screen after a dialog with a guard
[-] My bug: List of all conditions wasn't displayed in right click menu for Condition in Stats screen
(MM8)
[-] My bug: ExitDialogsWithRightButton was causing a crash in NPC/Guard dialog



Version ?:
!!! Bad asserts: 4662BA, 44C39D
????[+] ExitOnException


GamesLod:
45E2C0



46C4EA - проблема смерти от удара о потолок?
         (учитывается только 1 грань полигона)
46C0AF - аналогично


4876F8 - pointless loop

http://www.celestialheavens.com/forums/viewtopic.php?t=12042&sid=855e616a05c5e902c0e31d81cc574ff9

while the "swiftness" of the Herald Boot works, as stated in your patch, the Supreme Plate does not give any reduction in recovery. Another thing to note is that my character is already on Plate expert so I wonder if you've tinkered the swiftness effect of that plate.

Did you fix enchanted weapons "Of Poison" dealing Water damage instead of Body magic damage?

(Tested it by using such a weapon on a water immune monster - dealt no damage, and used it on a body immune monster - dealt damage)

And did you fix Acid Burst dealing Physical damage instead of Water damage? (Bug is the same as in MM7)


Wrong text: https://www.celestialheavens.com/forum/10/16657?start=6700#p384916

- MM8: When you cast Heroism or Hour of Power, you can see your new damage in
your stats. The change cannot be seen using the Heroism potion. This is probably
also true for Bless and its relation to attack bonus.

- When you do the Troll promotion quest in MM8, Volog Sandwind thanks you,
 but on behalf of the Minotaurs from Balthazar Lair. Obviously a mistake in
 coding, they've probably got the right dialogue somewhere in the game files.

- In Might and Magic 8 there's this bug that if you leave for the Arena by
coach and lose and then reload the autosave (to try again for example) more
than once, the game freezes. The first time reloading near the stables is
ok, but the second will crash the game totally. In MM7 there's no problem
with it.

- Merchant House of Alvar can sometimes fool you into thinking that it doesn't respawn

}

begin
  try
    if CompareMem(ptr($402420), PChar(#$56#$57#$8B#$F1#$E8#$65#$29#$01#$00#$8B#$86#$70#$01#$00#$00#$8B), 16) then
      exit;  // MM8Patch.exe (for the future)
    AssertErrorProc:= RSAssertErrorHandler;
    LoadIni;
    HookAll;
    Randomize;
    LoadExeMods;

  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end.
