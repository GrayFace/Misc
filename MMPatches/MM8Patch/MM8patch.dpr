library MM8patch;

uses
  SysUtils,
  Classes,
  RSSysUtils,
  Windows,
  RSQ,
  MMCommon,
  Hooks in 'Hooks.pas',
  Common in 'Common.pas',
  MP3 in 'MP3.pas';

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


The problem with Cauri is that when you free her, you absolutely have to talk to
her about each and every point of dialogue. She will end the promotion quest
herself IIRC, and if you just close the dialog box, then the quest is no longer
completable and you have to reload the game.

- MM8: When you cast Heroism or Hour of Power, you can see your new damage in
your stats. The change cannot be seen using the Heroism potion. This is probably
also true for Bless and its relation to attack bonus.

- The names of objects scattered on the map do not display when you point at
them, for example the "skeletons" and "carrions" in the Ironsand Desert or
"tar rocks" in Shadowspire do not display their names. And I remember that
quite a while ago the game would display them

- When you do the Troll promotion quest in MM8, Volog Sandwind thanks you,
 but on behalf of the Minotaurs from Balthazar Lair. Obviously a mistake in
 coding, they've probably got the right dialogue somewhere in the game files.

- In Might and Magic 8 there's this bug that if you leave for the Arena by
coach and lose and then reload the autosave (to try again for example) more
than once, the game freezes. The first time reloading near the stables is
ok, but the second will crash the game totally. In MM7 there's no problem
with it.

Xfing: Items that give + points to the Bow skill only affect the Normal and Expert bonuses (attack bonus and recovery time), but not the Grandmaster bonus, the damage. Could you make it so that a Dark Elf with GM Bow wearing the Fleetfingers gets +8 to damage? I believe the Tounrament Bow and the Longseeker both have +5 bonuses, too.

ArmsMaster with GM staff: http://www.celestialheavens.com/forums/viewtopic.php?t=14870&highlight=

}

begin
  try
    AssertErrorProc:= RSAssertErrorHandler;
    LoadIni;
    HookAll;
    Randomize;
    LoadExeMods;

  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end.
