library MM6patch;

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
[+] 2 Quick Saves
[-] AlwaysRun effects turning in turn-based mode now
[-] Town Portal pauses the game now
[+] NoDeathMovie option
[+] CapsLockToggleAlwaysRun may be disabled

Version 1.1:
[+] Customizable controls

Version 1.1.1:
[-] Bug fixed: QuickSave worked several times when holding the key

Version 1.2:
[+] The first version with all files included
[+] When you right click on character's experience it shows level to which the character can train and experience needed to train to level after that. Just like in MM7 and MM8
[+] NoCD option  
[+] Loads all .dll files from ExeMods directory
[-] MSS32.dll bugs fixed by using an unshrinked version of original dll

Version 1.3:
[*] Now Quick Save slot 1 always keeps the last save and slot 2 keeps the save before that. The very first save slot can also be occupied now. Use QuickSaveName option to set up quick save name
[-] Now you can have gaps between save slots. Save and Load would target the same slot anyway
[-] Walk Sound disappearing problem fixed
[-] No need to set compatibility on XP anymore
[-] Improved Angel's Bootlag Bay circus fix. It didn't work in some circumstances
[-] One of circus buildings in Bootlag Bay didn't have an enterance texture
[-] Previous patch version didn't work on Windows Vista
[*] Added Smuggler's Guild in Free Haven. It was planned by MM6 developers, but not included in the map file

Version 1.4:
[+] InventoryKey
[+] ToggleCharacterScreenKey
[+] FreeTabInInventory
[+] Recovery Time info
[+] PlayMP3
[-] You could drink from fauntains multiple times if all party members are inactive
[-] You could attack with inactive party members
[-] FixDualWeaponsRecovery
[-] Keys mapping didn't work for some special keys, e.g. Page Up
[-] Now all sounds are stopped when MM6 is deactivated

Version 1.4.1:
[-] Keys mapping worked incorrectly for special keys like Page Up

Version 1.5:
[+] Extracted files from icons.lod (except the pictures) are loaded from DataFiles folder. So, you don't need to insert files into icons.lod each time you modify them.
[+] ReputationNumber shows numerial reputation value together with category name
[-] Some scrolls were endless if you use them on paper doll in turn-based mode.
[-] Inactive characters could use scrolls.
[-] When using a scroll by right click on a character portrait target was chosen automatically. Thus, scrolls like Stone to Flash couldn't be used that way.
[-] Now scrolls pause the game when used on paper doll. This also disallows picking up items while choosing spell target.
[-] Some controls (like 'R') couldn't be changed.

Version 1.6:
[+] F2 toggles Double Speed mode. DoubleSpeedKey option controls the key.
[+] TurnSpeedNormal and TurnSpeedDouble options control speed of smooth turning. Default is 100% for normal speed and 120% for double speed.
[+] MusicLoopsCount option controls loops count of music. Set it to 0 for infinite loop.
[+] Multiple quicksaves, reworked quicksave
[+] HorsemanSpeakTime and BoatmanSpeakTime control time needed for horseman or boatman to say "Let's go" before new map starts loading
[+] Improved errors reporting
[-] Tab, + and - keys didn't work in previous version of the patch
[-] 'Increases rate of Recovery' enchantement now works. IncreaseRecoveryRateStrength controls how much it increases the rate. Default is 10%.
[-] Fixed a game bug which could cause a crash on game start (wrong handle was passed to RegCloseKey)
[-] Daggers had 10% chance to do tripple damage no metter what Dagger skill you have. ProgressiveDaggerTrippleDamage option makes daggers do tripple damage with probability equal to skill. Default is 1 (enabled).
[-] DataFiles didn't work in previous version.
[-] Turn-based turn used to take twice as much time as it should
[-] Smack video volume used to be loud even if you turn off the sound in Settings

Version 1.6.1:
[-] Version 1.6 didn't support Buka localization

Version 1.7:
[+] BlasterRecovery option controls minimal blaster recovery time. Default is 5. Game default was 0.
[-] Now items that didn't fit into a chest appear in it when you free space for them and reopen the chest (FixChests option)
[-] Now Recovery Rate shown by the patch reflects absense of speed limit for laser and "Increases recovery time" items
[-] Main menu music didn't start at the right position in PlayMP3 mode
[-] In previous version there were problems with sound due to WaveOut instead of DirectSound.
[-] (not fixed) Some people experienced a crash in load screen in previous version due to long quicksaves names.

Version 1.7.1:
[-] Removed quicksave names length limit. In Russian version of the patch the limit was exceeded which was leading to a crash.

Version 1.7.2:
[-] Fixed my bug with chests.  

Version 1.8:
[+] Stereo MP3 support
[+] DataFiles lookup can now be disabled (DataFiles option)
[+] Any hooks can be disabled now
[-] Removed buggy character switching (with Ctrl + click)

Version 1.9:
[+] Use Delphi memory manager
[+] Correct door state switching: param = 3
[-] Fix Starburst, Meteor Shower
[-] Party generation screen animation speed
[-] Fix facet ray interception checking out-of-bounds
[-] Fix global.txt, npcdata.txt, trans.txt, scroll.txt, npcnews.txt, intro.str parsing out-of-bounds

Version 1.9.1:
[-] Version 1.9 was hanging in Free Haven

Version 1.9.2:
[-] Bug fixed (the wrong way): when you move between locations sound buffers were freed while the sounds are playing

Version 1.9.3:
[-] Bug fixed (the right way): when you move between locations sound buffers were freed while the sounds are playing. Also some resources weren't freed.
[-] My bug: an empty Saves directory was leading to crash

Version 1.10:
[+] Mouse look
[+] AlwaysStrafe option

Version 1.11:
[+] MouseLookFly
[+] MouseWheelFly
[+] Mouse look update: MouseLookChangeKey, MouseLookTempKey, MouseLookUseAltMode...
[+] Custom cursor for mouse look mode
[+] Now Turn Delta is set to Smooth by default
[+] When run in 32 bits mode automatically switches to 16 bit when Windowed mode is used
[+] Quick load
[+] Autorun
[-] Fix condition removal spells (3 hours/days instead of 1, integer overflow)
[-] Fix damage of weapon enchants (don't ignore resists)
[-] Fixed strafes and walking
[-] negative/0 causes a crash in stats screen
[-] Quick Save didn't work in Hive after destroying the Reactor
[-] Waiting didn't recover characters
[-] Travel dialog was triggered while flying low, accepting it did nothing
[-] Autosave before taking money for transport, not after
[-] Key strokes could be ignored if some other programs run at the same time (and call GetAsyncKeyState)
[-] My bug: Starburst and Meteor Shower range limitations weren't accurate
[-] In mouse look mode mouse could leave window when moved fast
[-] Lloyd: take spell points and action after autosave, not before
[-] TP: take action after autosave, not before
[-] Town Portal triggered autosave even within a location
[-] The cause of Prismatic Light from MM7 and MM8 fixed here too

Version 1.11.1:
[-] My bug: keys 1-4 didn't work if ToggleCharacterScreenKey=0
[-] My bug: in 1.11 monsters targeting didn't work

Version 1.11.2:
[-] Finger Of Death spell didn't give experience for killed monsters.
[-] My bug: [Disable] section of mm6.ini wasn't read.
[-] My bug: Dead monsters could sometimes move in version 1.11

Version 2.0:
[+] Custom LODs
[+] MLookStartTime
[+] Auto strafe in MouseLook (+StandardStrafe invisible option)
[+] FixStarburst, FixInfiniteScrolls, FixInactivePlayersActing options control corresponding fixes
[-] Save game failure on some systems
[-] *.dlv and *.ddm
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
[-] Blasters and some spells couldn't target rats
[-] Crash with sprites with scale too small (happens with MM6HD)
[-] Town Portal wasting player's turn even if you cancel the dialog
[-] Evt commands couldn't operate on some skills
[-] Crash on exit
(MM6, MM7)
[-] My bug: crash when loading custom lods (don't know how it even worked at all!)
[-] Out-of-bounds memory read in buy dialog when no player is active
[-] Shops were buying blasters
[*] Now left click (while holding right button) not only cancels right button menu, but also performs action
(MM6)
[+] NoIntro option, just like in other patches. I figured this can be more convenient than "-nomovie" cmd line switch.
[+] PlayMP3 option now supports MP3 tracks in Sounds folder, as they are in GOG version
[+] Items stack vertically, like in MM7 and MM8 (controlled by hidden PlaceItemsVertically option)
[-] Scholar NPC not giving +5% exp
[-] +2/+3 weapon skill NPCs didn't effect weapon delay
[-] My bug: Starburst and Meteor Shower range limitations still weren't accurate
[-] My bug: Pressing CharScreenKey while holding right mouse button sometimes leading to crash

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
(MM6)
[+] "NoPlayerSwap" hidden option


Если загрузить сейв, где все рожи одинаковые, а потом сейв с разными, будут черные пятна на месте рож

AV in GetFloorHeight at 45E44D (see CH)

Paralyzed targets do not take damage from Fireball and Rock Blast

Реально ли сделать на экране навыков отображение действующих значений навыков:
1) как в MM7 - приписочкой +5 в конце описания, или
2) как в MM9 - просто указать действующее значение Water Magic 18, но очки навыка на развитие тратить правильно, 13, или
3) как в Heroes 3 - писать базовое значение в скобках: Water Magic 18(12).



есть пожелание исправить дополнительный магический урон от оружия. На настоящий
 момент урон наносится всем, даже абсолютно иммунным к любому урону существам,
 не только Реактору, а еще любому существу в окаменевшей форме. Хотелось бы, чтобы этот урон:
1) учитывал сопротивляемости и иммунитеты монстров. Т.е., доп. урон огнем чтобы жарил слизней, а ядом — не травил, чтобы Реактор был уязвим только к бластерам, а закаменённые монстры абсолютно неуязвимы;
2) отображался в статусе, желательно, вместе с основным, вроде "Золтан нанес урон 0+10


Возник еще вопрос с дальностью поражения в ММ6. Знаю, что дальность метеоритного
 дождя и звезд в патче фиксилась. Лично у меня сейчас эти заклинания на пределе
 дальности (индикатор только пожелтел) работать отказываются. Например, лучники
 во Фри Хевене или ящеры в пустыне Блэкшира меня успешно расстреливают, но при
 попытке применить указанные заклинания слышу звук, но ни анимации, ни урона
 монстрам не вижу. Еще хуже то, что расстреливают в это время и монстры,
 находящиеся за пределами дальности, то есть если отойти до позеленения индикатора,
 то по партии они бить все-равно будут успешно, хотя я им даже уже и из луков
 нанести урон не могу. Это нормально? Спросил в теме и вроде говорят, что нет.


1) Blackshire +5 Intellect & +5 Personality fountain (north of Temple of Snake) and Kreigspire +10 Magic Resistance fountain (town center) appear to share flag. You can only get one or the other.

2) "This spell lasts one hour per point of skill in Air/Earth/Body magic" (taken from Protection from Cold)
 should be added to spell description text of following spells: Protection from Electricity,
 Protection from Magic and Protection from Poison. Protection from Fire description could be slightly
 revised to match this form.

3) Haste, Shield, Stone Skin, Bless and Heroism are 1 hour plus 1 or 3 minutes/point spells. Programmed
 as 64 minutes plus 1 or 3 min/pt.

4) Guardian Angel spell typically doesn't return to "last temple visited." Perhaps coding is returning
 to "temple in last zone w/ town temple visited." Similarly, town portal novice & expert levels seem to
 return to "central fountain of last zone w/ town portal town visited."

5) Cure/Remove condition spells (Awaken, Stone to Flesh, Remove Curse, Raise Dead, Resurrection,
 Remove Fear, Cure Paralysis, Cure Insanity, Cure Weakness, Cure Poison & Cure Disease) are supposed
 to cure/remove condition 3min/point, 1hr/point & 1day/point dependent on skill level.
 Andy B found problem and Khilara found that novice is 3min/pt(correct), expert is 3 hours(not 1 hour)/pt
 and master is 3 days(not 1 day)/pt. Khilara's testing showed that master effective level
 64 *3days *24hours *60minutes *60seconds = 16,588,800seconds works (<2^24.)
 Effective level 66 *3days *24hours *60minutes *60seconds = 17,107,200seconds doesn't work (>2^24.)
 Fix would be to correct per spell description to 1 hour(expert) and 1 day(master) ILO 3 hour and 3 day
 (max level 63*1.5*1.5=141 *24hours *60minutes *60seconds = 12,182,400seconds (<2^24).)
 This problem easily worked around by removing 50% rings/amulet.

6) Light magic "Day of the Gods" spell gives 2x, 3x & 4x duration increase rather then 1hr/pt duration of
 individual spells, dependent on skill level, which makes sense. Points are same for Novice(2x) and
 Expert(3x) levels but 4/3 higher for Master level(4x) compared to individual spells, which seems a
 reasonable treatment. Spell doesn't provide Guardian Angel as spell states.

7) Light magic "Hour of Power" spell gives 10min(2x), 15min(3x) & 60min(4x) time bonus duration rather
 then 5min, 5min & 15min time bonus duration of individual spells, dependent on skill level, which seems
 reasonable. Heroism(damage), Stone Shield(armor class) and Bless(attack) points are same compared to
 indivdual spells, which doesn't seem right. Seems there should be a point increase, maybe 2x, 3x & 4x
 base 5 points. Would give master 15 more points then individual spells. If this could be done, then MM6
 community should agree to change. 2x, 3x & 4x effective magic level points seems excessive.

8) Dark magic "Day of Protection" spell gives additional 4 hours duration compared to indivdual spells
 for all skill levels, which doesn't make sense. Seems spell should give 2, 3 & 4 times duration compared
 to individual spells, dependent on skill level same as "Day of the Gods. Points are 2x, 3x & 4x rather
 then 1x, 2x & 3x of individual spells, dependent on skill level, which makes sense.


The Alter in the Temple of the moon gives an abnormal amount of luck, every other Alter gives + 5 Accuracy,
 Might, Endurance and Speed to all characters.
Luck + 2 1st character
Luck + 5 2nd, 3rd and 4th character


The official game bug where you must choose between the +5 Int/Per (B2 well) or +10 Magic Resistance (B1 well) is annoying because I just realized I took one well before the other before deciding which I rather have.
+10 Mag Res is in the village of Kriegspire (bigger sized well or fountain near the north-east end - it eradicates you)
(there's is also a +5 Elem Res bigger sized well between the Mountain Hermit and Superior Temple of Baa in Kriegspire - it is pretty easy to run to - it eradicates you)
+5 Int/Per is in a normal type of well at the bottom right of Blackshire - it diseases you
(there's also a +5 Mag Res bigger sized well in Blackshire a little southeast of the carnival on the hill - a little harder to run to at low levels - it diseases you) 
}

// crash in memory manager finalization
procedure MyDllProc(Reason: Integer);
asm

end;

begin
  try
    AssertErrorProc:= RSAssertErrorHandler;
    //DllProc:=
    LoadIni;
    HookAll;
    Randomize;
    LoadExeMods;

  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end.
