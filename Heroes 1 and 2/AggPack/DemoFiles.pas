unit DemoFiles;

interface

uses SysUtils, Classes, RSQ;

var
  FileByHash: array[0..$FFFF] of string;

procedure InitFileByHash;

implementation

{
procedure InitFileByHashNew;
var
  sl: TStringList;
  s: string;
  i, j: int;
begin
  sl:= TStringList.Create;
  sl.LoadFromFile('c:\Documents and Settings\Serg\��� ���������\Borland Studio Projects\AggPack\Names2.txt');
  for i := 0 to sl.Count - 1 do
    if sl[i] <> '' then
      FileByHashNew[GetHashId(ptr(sl[i]))]:= sl[i];
  sl.LoadFromFile('c:\Documents and Settings\Serg\��� ���������\Borland Studio Projects\AggPack\Names3.txt');
  for i := 0 to sl.Count - 1 do
    if sl[i] <> '' then
      for j := 0 to 99 do
      begin
        s:= Format(sl[i], [j]);
        FileByHashNew[GetHashId(ptr(s))]:= s;
      end;
end;
}

procedure InitFileByHash;
begin
  // From classic Heroes 1
  FileByHash[37466]:= 'overmain.bmp';
  FileByHash[29759]:= 'overban0.bmp';
  FileByHash[29743]:= 'overban1.bmp';
  FileByHash[29727]:= 'overban2.bmp';
  FileByHash[29711]:= 'overban3.bmp';
  FileByHash[52689]:= 'bigfont.fnt';
  FileByHash[38481]:= 'smalfont.fnt';
  FileByHash[39740]:= 'advmice.mse';
  FileByHash[9422]:= 'cmbtmous.mse';
  FileByHash[8264]:= 'spelmous.mse';
  FileByHash[47939]:= 'advmice.icn';
  FileByHash[17621]:= 'cmbtmous.icn';
  FileByHash[40843]:= 'spells.icn';
  FileByHash[51272]:= 'kb.pal';
  FileByHash[1791]:= 'combat.pal';
  FileByHash[36922]:= 'poof.icn';
  FileByHash[11822]:= 'textbar.icn';
  FileByHash[44895]:= 'font.icn';
  FileByHash[44107]:= 'smalfont.icn';
  FileByHash[15455]:= 'newgame.bin';
  FileByHash[13405]:= 'newgame.bmp';
  FileByHash[18499]:= 'newgame.icn';
  FileByHash[11561]:= 'boat.xtl';
  FileByHash[10926]:= 'grass.xtl';
  FileByHash[10536]:= 'dgrass.xtl';
  FileByHash[3750]:= 'dirt.xtl';
  FileByHash[60718]:= 'snow.xtl';
  FileByHash[24284]:= 'swamp.xtl';
  FileByHash[51735]:= 'desert.xtl';
  FileByHash[37329]:= 'lava.xtl';
  FileByHash[20180]:= 'grass.obj';
  FileByHash[19790]:= 'dgrass.obj';
  FileByHash[4437]:= 'snow.obj';
  FileByHash[33538]:= 'swamp.obj';
  FileByHash[46583]:= 'lava.obj';
  FileByHash[60989]:= 'desert.obj';
  FileByHash[16262]:= 'boat.bkg';
  FileByHash[33465]:= 'frstwgrs.bkg';
  FileByHash[21923]:= 'mtnwgrsf.bkg';
  FileByHash[60561]:= 'snowfrst.bkg';
  FileByHash[3311]:= 'snowmtnf.bkg';
  FileByHash[28985]:= 'swamp.bkg';
  FileByHash[42030]:= 'lava.bkg';
  FileByHash[56436]:= 'desert.bkg';
  FileByHash[33641]:= 'frstwdrt.bkg';
  FileByHash[46500]:= 'mtnwdrtf.bkg';
  FileByHash[12823]:= 'selector.icn';
  FileByHash[9761]:= 'catapult.icn';
  FileByHash[45528]:= 'tent.icn';
  FileByHash[39272]:= 'castle00.icn';
  FileByHash[39256]:= 'castle01.icn';
  FileByHash[39240]:= 'castle02.icn';
  FileByHash[39224]:= 'castle03.icn';
  FileByHash[3675]:= 'cloud.icn';
  FileByHash[4911]:= 'peasant.std';
  FileByHash[8984]:= 'peasant.wlk';
  FileByHash[23715]:= 'archer.std';
  FileByHash[27788]:= 'archer.wlk';
  FileByHash[23780]:= 'archer.atk';
  FileByHash[42639]:= 'pikeman.std';
  FileByHash[46712]:= 'pikeman.wlk';
  FileByHash[35558]:= 'swrdsman.std';
  FileByHash[39631]:= 'swrdsman.wlk';
  FileByHash[44847]:= 'cavalry.std';
  FileByHash[48920]:= 'cavalry.wlk';
  FileByHash[42976]:= 'paladin.std';
  FileByHash[47049]:= 'paladin.wlk';
  FileByHash[24279]:= 'goblin.std';
  FileByHash[28352]:= 'goblin.wlk';
  FileByHash[36531]:= 'orc.std';
  FileByHash[40604]:= 'orc.wlk';
  FileByHash[36596]:= 'orc.atk';
  FileByHash[19993]:= 'wolf.std';
  FileByHash[24066]:= 'wolf.wlk';
  FileByHash[36908]:= 'ogre.std';
  FileByHash[40981]:= 'ogre.wlk';
  FileByHash[64186]:= 'troll.std';
  FileByHash[2724]:= 'troll.wlk';
  FileByHash[64251]:= 'troll.atk';
  FileByHash[33178]:= 'cyclops.std';
  FileByHash[37251]:= 'cyclops.wlk';
  FileByHash[65285]:= 'sprite.std';
  FileByHash[3823]:= 'sprite.wlk';
  FileByHash[52887]:= 'dwarf.std';
  FileByHash[56960]:= 'dwarf.wlk';
  FileByHash[27579]:= 'druid.std';
  FileByHash[31140]:= 'druid.wlk';
  FileByHash[27132]:= 'druid.atk';
  FileByHash[20740]:= 'elf.std';
  FileByHash[24813]:= 'elf.wlk';
  FileByHash[20805]:= 'elf.atk';
  FileByHash[29700]:= 'unicorn.std';
  FileByHash[33773]:= 'unicorn.wlk';
  FileByHash[41392]:= 'phoenix.std';
  FileByHash[45465]:= 'phoenix.wlk';
  FileByHash[55885]:= 'centaur.std';
  FileByHash[59958]:= 'centaur.wlk';
  FileByHash[55950]:= 'centaur.atk';
  FileByHash[32215]:= 'gargoyle.std';
  FileByHash[36288]:= 'gargoyle.wlk';
  FileByHash[20028]:= 'griffin.std';
  FileByHash[24101]:= 'griffin.wlk';
  FileByHash[47835]:= 'minotaur.std';
  FileByHash[51908]:= 'minotaur.wlk';
  FileByHash[51750]:= 'hydra.std';
  FileByHash[55823]:= 'hydra.wlk';
  FileByHash[7453]:= 'dragon.std';
  FileByHash[11526]:= 'dragon.wlk';
  FileByHash[24363]:= 'rogue.std';
  FileByHash[28436]:= 'rogue.wlk';
  FileByHash[57789]:= 'nomad.std';
  FileByHash[61862]:= 'nomad.wlk';
  FileByHash[10047]:= 'ghost.std';
  FileByHash[14120]:= 'ghost.wlk';
  FileByHash[59505]:= 'genie.std';
  FileByHash[63578]:= 'genie.wlk';
  FileByHash[63645]:= 'boulder.icn';
  FileByHash[14372]:= 'viewgen.icn';
  FileByHash[20510]:= 'viewarmy.icn';
  FileByHash[9791]:= 'vgenback.icn';
  FileByHash[36849]:= 'book.icn';
  FileByHash[7291]:= 'bord.bmp';
  FileByHash[62965]:= 'heroes.bmp';
  FileByHash[59460]:= 'ground32.til';
  FileByHash[49214]:= 'object32.icn';
  FileByHash[26607]:= 'ovrlay32.icn';
  FileByHash[49581]:= 'kngt32.icn';
  FileByHash[21306]:= 'barb32.icn';
  FileByHash[17624]:= 'sorc32.icn';
  FileByHash[16339]:= 'wrlk32.icn';
  FileByHash[43114]:= 'shadow32.icn';
  FileByHash[4336]:= 'b-flag32.icn';
  FileByHash[4296]:= 'g-flag32.icn';
  FileByHash[4208]:= 'r-flag32.icn';
  FileByHash[4152]:= 'y-flag32.icn';
  FileByHash[49346]:= 'boat32.icn';
  FileByHash[38642]:= 'b-bflg32.icn';
  FileByHash[38602]:= 'g-bflg32.icn';
  FileByHash[38514]:= 'r-bflg32.icn';
  FileByHash[38458]:= 'y-bflg32.icn';
  FileByHash[14875]:= 'bluefire.icn';
  FileByHash[10563]:= 'redfire.icn';
  FileByHash[23037]:= 'electric.icn';
  FileByHash[56499]:= 'physical.icn';
  FileByHash[15395]:= 'elecfire.icn';
  FileByHash[39053]:= 'reddeath.icn';
  FileByHash[64781]:= 'magic01.icn';
  FileByHash[64765]:= 'magic02.icn';
  FileByHash[64749]:= 'magic03.icn';
  FileByHash[64733]:= 'magic04.icn';
  FileByHash[64717]:= 'magic05.icn';
  FileByHash[64701]:= 'magic06.icn';
  FileByHash[64685]:= 'magic07.icn';
  FileByHash[64669]:= 'magic08.icn';
  FileByHash[1940]:= 'fireball.icn';
  FileByHash[24007]:= 'storm.icn';
  FileByHash[52319]:= 'meteor.icn';
  FileByHash[55207]:= 'advbtns.icn';
  FileByHash[323]:= 'radar.icn';
  FileByHash[25274]:= 'magegld.tod';
  FileByHash[4697]:= 'thievesg.tod';
  FileByHash[22638]:= 'tavern.tod';
  FileByHash[63439]:= 'dock.tod';
  FileByHash[23093]:= 'well.tod';
  FileByHash[31452]:= 'magegld.icn';
  FileByHash[10875]:= 'thievesg.icn';
  FileByHash[28816]:= 'tavern.icn';
  FileByHash[4082]:= 'dock.icn';
  FileByHash[29271]:= 'well.icn';
  FileByHash[29044]:= 'townbkg0.bmp';
  FileByHash[50664]:= 'farmtent.tod';
  FileByHash[42736]:= 'farmcast.tod';
  FileByHash[28407]:= 'farm_d0.tod';
  FileByHash[28391]:= 'farm_d1.tod';
  FileByHash[28375]:= 'farm_d2.tod';
  FileByHash[28359]:= 'farm_d3.tod';
  FileByHash[28343]:= 'farm_d4.tod';
  FileByHash[28327]:= 'farm_d5.tod';
  FileByHash[56842]:= 'farmtent.icn';
  FileByHash[48914]:= 'farmcast.icn';
  FileByHash[34585]:= 'farm_d0.icn';
  FileByHash[34569]:= 'farm_d1.icn';
  FileByHash[34553]:= 'farm_d2.icn';
  FileByHash[34537]:= 'farm_d3.icn';
  FileByHash[34521]:= 'farm_d4.icn';
  FileByHash[34505]:= 'farm_d5.icn';
  FileByHash[29028]:= 'townbkg1.bmp';
  FileByHash[31462]:= 'frsttent.tod';
  FileByHash[23534]:= 'frstcast.tod';
  FileByHash[60881]:= 'frst_d0.tod';
  FileByHash[60865]:= 'frst_d1.tod';
  FileByHash[60849]:= 'frst_d2.tod';
  FileByHash[60833]:= 'frst_d3.tod';
  FileByHash[60817]:= 'frst_d4.tod';
  FileByHash[60801]:= 'frst_d5.tod';
  FileByHash[37640]:= 'frsttent.icn';
  FileByHash[29712]:= 'frstcast.icn';
  FileByHash[1524]:= 'frst_d0.icn';
  FileByHash[1508]:= 'frst_d1.icn';
  FileByHash[1492]:= 'frst_d2.icn';
  FileByHash[1476]:= 'frst_d3.icn';
  FileByHash[1460]:= 'frst_d4.icn';
  FileByHash[1444]:= 'frst_d5.icn';
  FileByHash[29012]:= 'townbkg2.bmp';
  FileByHash[37792]:= 'plnstent.tod';
  FileByHash[29864]:= 'plnscast.tod';
  FileByHash[19166]:= 'plns_d0.tod';
  FileByHash[19150]:= 'plns_d1.tod';
  FileByHash[19134]:= 'plns_d2.tod';
  FileByHash[19118]:= 'plns_d3.tod';
  FileByHash[19102]:= 'plns_d4.tod';
  FileByHash[19086]:= 'plns_d5.tod';
  FileByHash[10974]:= 'plns_e0.tod';
  FileByHash[43970]:= 'plnstent.icn';
  FileByHash[36042]:= 'plnscast.icn';
  FileByHash[25344]:= 'plns_d0.icn';
  FileByHash[25328]:= 'plns_d1.icn';
  FileByHash[25312]:= 'plns_d2.icn';
  FileByHash[25296]:= 'plns_d3.icn';
  FileByHash[25280]:= 'plns_d4.icn';
  FileByHash[25264]:= 'plns_d5.icn';
  FileByHash[17152]:= 'plns_e0.icn';
  FileByHash[28996]:= 'townbkg3.bmp';
  FileByHash[39692]:= 'mtntent.tod';
  FileByHash[31764]:= 'mtncast.tod';
  FileByHash[226]:= 'mtn_d0.tod';
  FileByHash[210]:= 'mtn_d1.tod';
  FileByHash[194]:= 'mtn_d2.tod';
  FileByHash[178]:= 'mtn_d3.tod';
  FileByHash[162]:= 'mtn_d4.tod';
  FileByHash[146]:= 'mtn_d5.tod';
  FileByHash[45870]:= 'mtntent.icn';
  FileByHash[37942]:= 'mtncast.icn';
  FileByHash[6404]:= 'mtn_d0.icn';
  FileByHash[6388]:= 'mtn_d1.icn';
  FileByHash[6372]:= 'mtn_d2.icn';
  FileByHash[6356]:= 'mtn_d3.icn';
  FileByHash[6340]:= 'mtn_d4.icn';
  FileByHash[6324]:= 'mtn_d5.icn';
  FileByHash[31960]:= 'strip.icn';
  FileByHash[8170]:= 'monsters.icn';
  FileByHash[41316]:= 'treasury.icn';
  FileByHash[43353]:= 'resource.icn';
  FileByHash[11708]:= 'townfix.icn';
  FileByHash[50819]:= 'townname.icn';
  FileByHash[13301]:= 'bankbox.bin';
  FileByHash[13381]:= 'adv_wind.bin';
  FileByHash[23043]:= 'magewind.bin';
  FileByHash[21307]:= 'caslwind.bin';
  FileByHash[22960]:= 'thiefwin.bin';
  FileByHash[17065]:= 'wellwind.bin';
  FileByHash[22812]:= 'buybuild.icn';
  FileByHash[32291]:= 'recruit0.bin';
  FileByHash[32275]:= 'recruit1.bin';
  FileByHash[40475]:= 'stonebak.bmp';
  FileByHash[36628]:= 'building.icn';
  FileByHash[29925]:= 'system.icn';
  FileByHash[9359]:= 'townwind.icn';
  FileByHash[48167]:= 'obj32-00.icn';
  FileByHash[48151]:= 'obj32-01.icn';
  FileByHash[48135]:= 'obj32-02.icn';
  FileByHash[48119]:= 'obj32-03.icn';
  FileByHash[48103]:= 'obj32-04.icn';
  FileByHash[48087]:= 'obj32-05.icn';
  FileByHash[48071]:= 'obj32-06.icn';
  FileByHash[48055]:= 'obj32-07.icn';
  FileByHash[17851]:= 'mtn32.icn';
  FileByHash[49500]:= 'tree32.icn';
  FileByHash[49683]:= 'town32.icn';
  FileByHash[16602]:= 'rsrc32.icn';
  FileByHash[16614]:= 'mons32.icn';
  FileByHash[20540]:= 'art32.icn';
  FileByHash[50938]:= 'flag32.icn';
  FileByHash[62508]:= 'armywin.bin';
  FileByHash[35857]:= 'tavwin.icn';
  FileByHash[32813]:= 'tavwin.bin';
  FileByHash[13007]:= 'shipwind.bin';
  FileByHash[17180]:= 'rcrthero.bin';
  FileByHash[16405]:= 'herowind.bin';
  FileByHash[52442]:= 'heroscrn.icn';
  FileByHash[47348]:= 'heroscrn.bmp';
  FileByHash[38188]:= 'townstrp.bin';
  FileByHash[65334]:= 'artifact.icn';
  FileByHash[15660]:= 'statbar.bin';
  FileByHash[12989]:= 'spellwin.bin';
  FileByHash[11317]:= 'scroll.icn';
  FileByHash[44936]:= 'locators.icn';
  FileByHash[15451]:= 'qhero0.bin';
  FileByHash[15435]:= 'qhero1.bin';
  FileByHash[20246]:= 'qtown0.bin';
  FileByHash[20230]:= 'qtown1.bin';
  FileByHash[63990]:= 'qwikinfo.bin';
  FileByHash[62515]:= 'qwikhero.bmp';
  FileByHash[20925]:= 'qwiktown.bmp';
  FileByHash[61940]:= 'qwikinfo.bmp';
  FileByHash[13739]:= 'splitwin.bin';
  FileByHash[10312]:= 'vgenwin.bin';
  FileByHash[41900]:= 'overview.icn';
  FileByHash[63734]:= 'overwind.bin';
  FileByHash[42593]:= 'buybook.bin';
  FileByHash[6119]:= 'puzzle.icn';
  FileByHash[60725]:= 'vstat.bin';
  FileByHash[30521]:= 'cmbtwin.bin';
  FileByHash[14375]:= 'swapwin.bin';
  FileByHash[12325]:= 'swapwin.bmp';
  FileByHash[59721]:= 'swapbtn.icn';
  FileByHash[186]:= 'tree6.icn';
  FileByHash[12284]:= 'mtn6.icn';
  FileByHash[23610]:= 'town6.icn';
  FileByHash[53180]:= 'flag6.icn';
  FileByHash[35283]:= 'ground6.icn';
  FileByHash[28775]:= 'request.bin';
  FileByHash[31819]:= 'request.icn';
  FileByHash[26725]:= 'request.bmp';
  FileByHash[26192]:= 'port0000.icn';
  FileByHash[26176]:= 'port0001.icn';
  FileByHash[26160]:= 'port0002.icn';
  FileByHash[26144]:= 'port0003.icn';
  FileByHash[26128]:= 'port0004.icn';
  FileByHash[26112]:= 'port0005.icn';
  FileByHash[26096]:= 'port0006.icn';
  FileByHash[26080]:= 'port0007.icn';
  FileByHash[26064]:= 'port0008.icn';
  FileByHash[26048]:= 'port0009.icn';
  FileByHash[18000]:= 'port0010.icn';
  FileByHash[17984]:= 'port0011.icn';
  FileByHash[17968]:= 'port0012.icn';
  FileByHash[17952]:= 'port0013.icn';
  FileByHash[17936]:= 'port0014.icn';
  FileByHash[17920]:= 'port0015.icn';
  FileByHash[17904]:= 'port0016.icn';
  FileByHash[17888]:= 'port0017.icn';
  FileByHash[17872]:= 'port0018.icn';
  FileByHash[17856]:= 'port0019.icn';
  FileByHash[9808]:= 'port0020.icn';
  FileByHash[9792]:= 'port0021.icn';
  FileByHash[9776]:= 'port0022.icn';
  FileByHash[9760]:= 'port0023.icn';
  FileByHash[9744]:= 'port0024.icn';
  FileByHash[9728]:= 'port0025.icn';
  FileByHash[9712]:= 'port0026.icn';
  FileByHash[9696]:= 'port0027.icn';
  FileByHash[9680]:= 'port0028.icn';
  FileByHash[9664]:= 'port0029.icn';
  FileByHash[1616]:= 'port0030.icn';
  FileByHash[1600]:= 'port0031.icn';
  FileByHash[1584]:= 'port0032.icn';
  FileByHash[1568]:= 'port0033.icn';
  FileByHash[1552]:= 'port0034.icn';
  FileByHash[1536]:= 'port0035.icn';
  FileByHash[23222]:= 'crst0000.icn';
  FileByHash[23206]:= 'crst0001.icn';
  FileByHash[23190]:= 'crst0002.icn';
  FileByHash[23174]:= 'crst0003.icn';
  FileByHash[23158]:= 'crst0004.icn';
  FileByHash[23142]:= 'crst0005.icn';
  FileByHash[23126]:= 'crst0006.icn';
  FileByHash[23110]:= 'crst0007.icn';
  FileByHash[23094]:= 'crst0008.icn';
  FileByHash[23078]:= 'crst0009.icn';
  FileByHash[15030]:= 'crst0010.icn';
  FileByHash[15014]:= 'crst0011.icn';
  FileByHash[14998]:= 'crst0012.icn';
  FileByHash[14982]:= 'crst0013.icn';
  FileByHash[14966]:= 'crst0014.icn';
  FileByHash[14950]:= 'crst0015.icn';
  FileByHash[14934]:= 'crst0016.icn';
  FileByHash[14918]:= 'crst0017.icn';
  FileByHash[14902]:= 'crst0018.icn';
  FileByHash[14886]:= 'crst0019.icn';
  FileByHash[15015]:= 'surrendr.bin';
  FileByHash[12965]:= 'surrendr.bmp';
  FileByHash[18059]:= 'surrendr.icn';
  FileByHash[12904]:= 'recruit.bmp';
  FileByHash[17998]:= 'recruit.icn';
  FileByHash[60889]:= 'artfx.icn';
  FileByHash[2366]:= 'bigbar.icn';
  FileByHash[29626]:= 'cpanel.bin';
  FileByHash[27576]:= 'cpanel.bmp';
  FileByHash[32670]:= 'cpanel.icn';
  FileByHash[10515]:= 'peasant.wip';
  FileByHash[29319]:= 'archer.wip';
  FileByHash[48243]:= 'pikeman.wip';
  FileByHash[41162]:= 'swrdsman.wip';
  FileByHash[50451]:= 'cavalry.wip';
  FileByHash[48580]:= 'paladin.wip';
  FileByHash[29883]:= 'goblin.wip';
  FileByHash[42135]:= 'orc.wip';
  FileByHash[25597]:= 'wolf.wip';
  FileByHash[4255]:= 'troll.wip';
  FileByHash[38782]:= 'cyclops.wip';
  FileByHash[32671]:= 'druid.wip';
  FileByHash[58491]:= 'dwarf.wip';
  FileByHash[26344]:= 'elf.wip';
  FileByHash[35304]:= 'unicorn.wip';
  FileByHash[61489]:= 'centaur.wip';
  FileByHash[53439]:= 'minotaur.wip';
  FileByHash[57354]:= 'hydra.wip';
  FileByHash[29967]:= 'rogue.wip';
  FileByHash[63393]:= 'nomad.wip';
  FileByHash[42512]:= 'ogre.wip';
  FileByHash[47130]:= 'woodgrai.bmp';
  FileByHash[22882]:= 'legend.bmp';
  FileByHash[27976]:= 'legend.icn';
  FileByHash[31892]:= 'viewhros.bmp';
  FileByHash[39758]:= 'viewtwns.bmp';
  FileByHash[39872]:= 'viewrtfx.bmp';
  FileByHash[23933]:= 'viewwrld.bmp';
  FileByHash[7231]:= 'viewpuzl.bmp';
  FileByHash[9281]:= 'viewpuzl.bin';
  FileByHash[54434]:= 'view-00.bin';
  FileByHash[54418]:= 'view-01.bin';
  FileByHash[54402]:= 'view-02.bin';
  FileByHash[54386]:= 'view-03.bin';
  FileByHash[54370]:= 'view-04.bin';
  FileByHash[54354]:= 'view-05.bin';
  FileByHash[15887]:= 'spheres.icn';
  FileByHash[12636]:= 'letters.icn';
  FileByHash[43528]:= 'dimdoor.bin';
  FileByHash[54737]:= 'winlose.bmp';
  FileByHash[35150]:= 'wincmbt.icn';
  FileByHash[32106]:= 'wincmbt.bin';
  FileByHash[38908]:= 'losecmbt.bmp';
  FileByHash[40958]:= 'losecmbt.bin';
  FileByHash[44002]:= 'losecmbt.icn';
  FileByHash[28519]:= 'losewalk.icn';
  FileByHash[49911]:= 'wsnd00.82m';
  FileByHash[49895]:= 'wsnd01.82m';
  FileByHash[49879]:= 'wsnd02.82m';
  FileByHash[49863]:= 'wsnd03.82m';
  FileByHash[49847]:= 'wsnd04.82m';
  FileByHash[49831]:= 'wsnd05.82m';
  FileByHash[49815]:= 'wsnd06.82m';
  FileByHash[41719]:= 'wsnd10.82m';
  FileByHash[41703]:= 'wsnd11.82m';
  FileByHash[41687]:= 'wsnd12.82m';
  FileByHash[41671]:= 'wsnd13.82m';
  FileByHash[41655]:= 'wsnd14.82m';
  FileByHash[41639]:= 'wsnd15.82m';
  FileByHash[41623]:= 'wsnd16.82m';
  FileByHash[33527]:= 'wsnd20.82m';
  FileByHash[33511]:= 'wsnd21.82m';
  FileByHash[33495]:= 'wsnd22.82m';
  FileByHash[33479]:= 'wsnd23.82m';
  FileByHash[33463]:= 'wsnd24.82m';
  FileByHash[33447]:= 'wsnd25.82m';
  FileByHash[33431]:= 'wsnd26.82m';
  FileByHash[6315]:= 'townwind.bin';
  FileByHash[36027]:= 'loop0000.82m';
  FileByHash[36011]:= 'loop0001.82m';
  FileByHash[35995]:= 'loop0002.82m';
  FileByHash[35979]:= 'loop0003.82m';
  FileByHash[35963]:= 'loop0004.82m';
  FileByHash[35947]:= 'loop0005.82m';
  FileByHash[35931]:= 'loop0006.82m';
  FileByHash[35915]:= 'loop0007.82m';
  FileByHash[35899]:= 'loop0008.82m';
  FileByHash[35883]:= 'loop0009.82m';
  FileByHash[27835]:= 'loop0010.82m';
  FileByHash[27819]:= 'loop0011.82m';
  FileByHash[27803]:= 'loop0012.82m';
  FileByHash[27787]:= 'loop0013.82m';
  FileByHash[27771]:= 'loop0014.82m';
  FileByHash[27755]:= 'loop0015.82m';
  FileByHash[27739]:= 'loop0016.82m';
  FileByHash[27723]:= 'loop0017.82m';
  FileByHash[27707]:= 'loop0018.82m';
  FileByHash[27691]:= 'loop0019.82m';
  FileByHash[19643]:= 'loop0020.82m';
  FileByHash[19627]:= 'loop0021.82m';
  FileByHash[61397]:= 'WINCE00.82M';
  FileByHash[61381]:= 'WINCE01.82M';
  FileByHash[61365]:= 'WINCE02.82M';
  FileByHash[61349]:= 'WINCE03.82M';
  FileByHash[61333]:= 'WINCE04.82M';
  FileByHash[61317]:= 'WINCE05.82M';
  FileByHash[61301]:= 'WINCE06.82M';
  FileByHash[61285]:= 'WINCE07.82M';
  FileByHash[61269]:= 'WINCE08.82M';
  FileByHash[61253]:= 'WINCE09.82M';
  FileByHash[53205]:= 'WINCE10.82M';
  FileByHash[53189]:= 'WINCE11.82M';
  FileByHash[53173]:= 'WINCE12.82M';
  FileByHash[53157]:= 'WINCE13.82M';
  FileByHash[53141]:= 'WINCE14.82M';
  FileByHash[53125]:= 'WINCE15.82M';
  FileByHash[53109]:= 'WINCE16.82M';
  FileByHash[53093]:= 'WINCE17.82M';
  FileByHash[53077]:= 'WINCE18.82M';
  FileByHash[53061]:= 'WINCE19.82M';
  FileByHash[45013]:= 'WINCE20.82M';
  FileByHash[44997]:= 'WINCE21.82M';
  FileByHash[44981]:= 'WINCE22.82M';
  FileByHash[44965]:= 'WINCE23.82M';
  FileByHash[44949]:= 'WINCE24.82M';
  FileByHash[44933]:= 'WINCE25.82M';
  FileByHash[44917]:= 'WINCE26.82M';
  FileByHash[44901]:= 'WINCE27.82M';
  FileByHash[28940]:= 'ATKSND00.82M';
  FileByHash[28924]:= 'ATKSND01.82M';
  FileByHash[28908]:= 'ATKSND02.82M';
  FileByHash[28892]:= 'ATKSND03.82M';
  FileByHash[28876]:= 'ATKSND04.82M';
  FileByHash[28860]:= 'ATKSND05.82M';
  FileByHash[28844]:= 'ATKSND06.82M';
  FileByHash[28828]:= 'ATKSND07.82M';
  FileByHash[28812]:= 'ATKSND08.82M';
  FileByHash[28796]:= 'ATKSND09.82M';
  FileByHash[20748]:= 'ATKSND10.82M';
  FileByHash[20732]:= 'ATKSND11.82M';
  FileByHash[20716]:= 'ATKSND12.82M';
  FileByHash[20700]:= 'ATKSND13.82M';
  FileByHash[20684]:= 'ATKSND14.82M';
  FileByHash[20668]:= 'ATKSND15.82M';
  FileByHash[20652]:= 'ATKSND16.82M';
  FileByHash[20636]:= 'ATKSND17.82M';
  FileByHash[20620]:= 'ATKSND18.82M';
  FileByHash[20604]:= 'ATKSND19.82M';
  FileByHash[12556]:= 'ATKSND20.82M';
  FileByHash[12540]:= 'ATKSND21.82M';
  FileByHash[12524]:= 'ATKSND22.82M';
  FileByHash[12508]:= 'ATKSND23.82M';
  FileByHash[12492]:= 'ATKSND24.82M';
  FileByHash[12476]:= 'ATKSND25.82M';
  FileByHash[12460]:= 'ATKSND26.82M';
  FileByHash[12444]:= 'ATKSND27.82M';
  FileByHash[64257]:= 'SHOOT01.82M';
  FileByHash[64161]:= 'SHOOT07.82M';
  FileByHash[56081]:= 'SHOOT10.82M';
  FileByHash[58065]:= 'SHOOT14.82M';
  FileByHash[56001]:= 'SHOOT15.82M';
  FileByHash[55953]:= 'SHOOT18.82M';
  FileByHash[50887]:= 'MOVE00.82M';
  FileByHash[50871]:= 'MOVE01.82M';
  FileByHash[50855]:= 'MOVE02.82M';
  FileByHash[50839]:= 'MOVE03.82M';
  FileByHash[50823]:= 'MOVE04.82M';
  FileByHash[50807]:= 'MOVE05.82M';
  FileByHash[50791]:= 'MOVE06.82M';
  FileByHash[50775]:= 'MOVE07.82M';
  FileByHash[50759]:= 'MOVE08.82M';
  FileByHash[50743]:= 'MOVE09.82M';
  FileByHash[42695]:= 'MOVE10.82M';
  FileByHash[42679]:= 'MOVE11.82M';
  FileByHash[42663]:= 'MOVE12.82M';
  FileByHash[42647]:= 'MOVE13.82M';
  FileByHash[42631]:= 'MOVE14.82M';
  FileByHash[42615]:= 'MOVE15.82M';
  FileByHash[42599]:= 'MOVE16.82M';
  FileByHash[42583]:= 'MOVE17.82M';
  FileByHash[42567]:= 'MOVE18.82M';
  FileByHash[42551]:= 'MOVE19.82M';
  FileByHash[34503]:= 'MOVE20.82M';
  FileByHash[34487]:= 'MOVE21.82M';
  FileByHash[34471]:= 'MOVE22.82M';
  FileByHash[34455]:= 'MOVE23.82M';
  FileByHash[34439]:= 'MOVE24.82M';
  FileByHash[34423]:= 'MOVE25.82M';
  FileByHash[34407]:= 'MOVE26.82M';
  FileByHash[34391]:= 'MOVE27.82M';
  FileByHash[48362]:= 'CATSND00.82M';
  FileByHash[48330]:= 'CATSND02.82M';
  FileByHash[63604]:= 'evntwin0.bin';
  FileByHash[63588]:= 'evntwin1.bin';
  FileByHash[63572]:= 'evntwin2.bin';
  FileByHash[63556]:= 'evntwin3.bin';
  FileByHash[63540]:= 'evntwin4.bin';
  FileByHash[63524]:= 'evntwin5.bin';
  FileByHash[63508]:= 'evntwin6.bin';
  FileByHash[63492]:= 'evntwin7.bin';
  FileByHash[47887]:= 'clof32.til';
  FileByHash[50361]:= 'clop32.icn';
  FileByHash[32674]:= 'apanel.icn';
  FileByHash[29630]:= 'apanel.bin';
  FileByHash[27580]:= 'apanel.bmp';
  FileByHash[64404]:= 'rainbluk.icn';
  FileByHash[51455]:= 'cloudluk.icn';
  FileByHash[40393]:= 'route.icn';
  FileByHash[591]:= 'ston.til';
  FileByHash[62018]:= 'stonback.icn';
  FileByHash[1597]:= 'smcrest.icn';
  FileByHash[35116]:= 'ressmall.icn';
  FileByHash[63759]:= 'sunmoon.icn';
  FileByHash[48972]:= 'hourglas.icn';
  FileByHash[18995]:= 'brcrest.icn';
  FileByHash[20051]:= 'moraleg.icn';
  FileByHash[20131]:= 'moraleb.icn';
  FileByHash[16220]:= 'miniport.icn';
  FileByHash[7208]:= 'portxtra.icn';
  FileByHash[59557]:= 'mobility.icn';
  FileByHash[40357]:= 'herologo.til';
  FileByHash[22481]:= 'expmrl.icn';
  FileByHash[4522]:= 'minimon.icn';
  FileByHash[20040]:= 'buybuil3.bin';
  FileByHash[20024]:= 'buybuil4.bin';
  FileByHash[20008]:= 'buybuil5.bin';
  FileByHash[19992]:= 'buybuil6.bin';
  FileByHash[19976]:= 'buybuil7.bin';
  FileByHash[11215]:= 'keep00.icn';
  FileByHash[11199]:= 'keep01.icn';
  FileByHash[11183]:= 'keep02.icn';
  FileByHash[11167]:= 'keep03.icn';
  FileByHash[44246]:= 'hiscore.bmp';
  FileByHash[49340]:= 'hiscore.icn';
  FileByHash[46296]:= 'hiscore.bin';
  FileByHash[23598]:= 'winloseb.icn';
  FileByHash[52413]:= 'netbox.icn';
  FileByHash[49369]:= 'netbox.bin';
  FileByHash[33604]:= 'gravyard.bkg';
  FileByHash[56867]:= 'recruiq0.bin';
  FileByHash[56851]:= 'recruiq1.bin';
  FileByHash[30209]:= 'recruit2.bmp';
  FileByHash[55636]:= 'congrats.bmp';
  FileByHash[57686]:= 'congrats.bin';
  FileByHash[22451]:= 'scroll2.icn';
  FileByHash[16180]:= 'reqextra.bmp';
  FileByHash[18230]:= 'reqextra.bin';
  FileByHash[39961]:= 'dataentr.bin';
  FileByHash[63232]:= 'redback.bmp';
  FileByHash[63958]:= 'btncmpgn.icn';
  FileByHash[48712]:= 'btncom.icn';
  FileByHash[29556]:= 'btnhotst.icn';
  FileByHash[147]:= 'btnmain.icn';
  FileByHash[13030]:= 'btnmodem.icn';
  FileByHash[3800]:= 'btnmp.icn';
  FileByHash[64281]:= 'btnnet.icn';
  FileByHash[60714]:= 'btnnewgm.icn';
  FileByHash[60774]:= 'stpcmpgn.bin';
  FileByHash[45633]:= 'stpcom.bin';
  FileByHash[26372]:= 'stphotst.bin';
  FileByHash[44718]:= 'stpmain.bin';
  FileByHash[9846]:= 'stpmodem.bin';
  FileByHash[61811]:= 'stpmp.bin';
  FileByHash[61202]:= 'stpnet.bin';
  FileByHash[57530]:= 'stpnewgm.bin';
  FileByHash[20815]:= 'boat.obj';
  FileByHash[26671]:= 'BADLUCK.82M';
  FileByHash[51533]:= 'BADMRLE.82M';
  FileByHash[36392]:= 'BUILDTWN.82M';
  FileByHash[22392]:= 'DIGSOUND.82M';
  FileByHash[11747]:= 'GOODLUCK.82M';
  FileByHash[36609]:= 'GOODMRLE.82M';
  FileByHash[9004]:= 'KILLFADE.82M';
  FileByHash[8593]:= 'PICKUP01.82M';
  FileByHash[8577]:= 'PICKUP02.82M';
  FileByHash[8561]:= 'PICKUP03.82M';
  FileByHash[8545]:= 'PICKUP04.82M';
  FileByHash[8529]:= 'PICKUP05.82M';
  FileByHash[33762]:= 'PREBATTL.82M';
  FileByHash[45899]:= 'RSBRYFZL.82M';
  FileByHash[34563]:= 'SPELL00.82M';
  FileByHash[34547]:= 'SPELL01.82M';
  FileByHash[34531]:= 'SPELL02.82M';
  FileByHash[34515]:= 'SPELL03.82M';
  FileByHash[34499]:= 'SPELL04.82M';
  FileByHash[34483]:= 'SPELL05.82M';
  FileByHash[34467]:= 'SPELL06.82M';
  FileByHash[34451]:= 'SPELL07.82M';
  FileByHash[34435]:= 'SPELL08.82M';
  FileByHash[34419]:= 'SPELL09.82M';
  FileByHash[26371]:= 'SPELL10.82M';
  FileByHash[26355]:= 'SPELL11.82M';
  FileByHash[26339]:= 'SPELL12.82M';
  FileByHash[26323]:= 'SPELL13.82M';
  FileByHash[26307]:= 'SPELL14.82M';
  FileByHash[26291]:= 'SPELL15.82M';
  FileByHash[26275]:= 'SPELL16.82M';
  FileByHash[26259]:= 'SPELL17.82M';
  FileByHash[26243]:= 'SPELL18.82M';
  FileByHash[44763]:= 'TELEIN.82M';
  FileByHash[14999]:= 'campaign.icn';
  FileByHash[10465]:= 'campback.bmp';
  FileByHash[11955]:= 'campaign.bin';
  FileByHash[21203]:= 'sceninfo.icn';
  FileByHash[16109]:= 'sceninfo.bmp';
  FileByHash[18159]:= 'sceninfo.bin';
  FileByHash[3940]:= 'credits.bmp';
  FileByHash[40566]:= 'congspre.bin';
  FileByHash[48012]:= 'bordedit.BMP';
  FileByHash[54972]:= 'BUTTONS.ICN';
  FileByHash[31029]:= 'CELLWIN.ICN';
  FileByHash[27985]:= 'CELLWIN.BIN';
  FileByHash[16191]:= 'EDITWIND.BIN';
  FileByHash[7218]:= 'ESCROLL.ICN';
  FileByHash[10245]:= 'GROUND16.TIL';
  FileByHash[57438]:= 'HEROEDIT.BIN';
  FileByHash[51100]:= 'MONEDIT.BIN';
  FileByHash[21021]:= 'OVERLAY.ICN';
  FileByHash[18356]:= 'TERRAINS.ICN';
  FileByHash[40223]:= 'EDITTOWN.BIN';
  FileByHash[48677]:= 'obj16-00.icn';
  FileByHash[48661]:= 'obj16-01.icn';
  FileByHash[48645]:= 'obj16-02.icn';
  FileByHash[48629]:= 'obj16-03.icn';
  FileByHash[48613]:= 'obj16-04.icn';
  FileByHash[48597]:= 'obj16-05.icn';
  FileByHash[48581]:= 'obj16-06.icn';
  FileByHash[48565]:= 'obj16-07.icn';
  FileByHash[34171]:= 'mtn16.icn';
  FileByHash[285]:= 'tree16.icn';
  FileByHash[468]:= 'town16.icn';
  FileByHash[32922]:= 'rsrc16.icn';
  FileByHash[32934]:= 'mons16.icn';
  FileByHash[36860]:= 'art16.icn';
  FileByHash[20026]:= 'clearwin.bin';
  FileByHash[19785]:= 'dtlwind.bin';
  FileByHash[10281]:= 'textback.icn';
  FileByHash[59899]:= 'editnew.bin';
  FileByHash[38520]:= 'ccycle00.bin';
  FileByHash[38504]:= 'ccycle01.bin';
  FileByHash[38488]:= 'ccycle02.bin';
  FileByHash[38472]:= 'ccycle03.bin';
  FileByHash[38456]:= 'ccycle04.bin';
  FileByHash[38440]:= 'ccycle05.bin';
  FileByHash[38424]:= 'ccycle06.bin';
  FileByHash[38408]:= 'ccycle07.bin';
  FileByHash[64207]:= 'clof16.til';
  FileByHash[65024]:= 'advmco01.bmp';
  FileByHash[65008]:= 'advmco02.bmp';
  FileByHash[64992]:= 'advmco03.bmp';
  FileByHash[64976]:= 'advmco04.bmp';
  FileByHash[64960]:= 'advmco05.bmp';
  FileByHash[64944]:= 'advmco06.bmp';
  FileByHash[64928]:= 'advmco07.bmp';
  FileByHash[64912]:= 'advmco08.bmp';
  FileByHash[64896]:= 'advmco09.bmp';
  FileByHash[56848]:= 'advmco10.bmp';
  FileByHash[56832]:= 'advmco11.bmp';
  FileByHash[56816]:= 'advmco12.bmp';
  FileByHash[56800]:= 'advmco13.bmp';
  FileByHash[56784]:= 'advmco14.bmp';
  FileByHash[56768]:= 'advmco15.bmp';
  FileByHash[56752]:= 'advmco16.bmp';
  FileByHash[56736]:= 'advmco17.bmp';
  FileByHash[56720]:= 'advmco18.bmp';
  FileByHash[56704]:= 'advmco19.bmp';
  FileByHash[48656]:= 'advmco20.bmp';
  FileByHash[48640]:= 'advmco21.bmp';
  FileByHash[48624]:= 'advmco22.bmp';
  FileByHash[48608]:= 'advmco23.bmp';
  FileByHash[48592]:= 'advmco24.bmp';
  FileByHash[48576]:= 'advmco25.bmp';
  FileByHash[48560]:= 'advmco26.bmp';
  FileByHash[48544]:= 'advmco27.bmp';
  FileByHash[48528]:= 'advmco28.bmp';
  FileByHash[48512]:= 'advmco29.bmp';
  FileByHash[40464]:= 'advmco30.bmp';
  FileByHash[40448]:= 'advmco31.bmp';
  FileByHash[40432]:= 'advmco32.bmp';
  FileByHash[40416]:= 'advmco33.bmp';
  FileByHash[40400]:= 'advmco34.bmp';
  FileByHash[40384]:= 'advmco35.bmp';
  FileByHash[40368]:= 'advmco36.bmp';
  FileByHash[40352]:= 'advmco37.bmp';
  FileByHash[40336]:= 'advmco38.bmp';
  FileByHash[40320]:= 'advmco39.bmp';
  FileByHash[32272]:= 'advmco40.bmp';
  FileByHash[57846]:= 'cmseco01.bmp';
  FileByHash[57830]:= 'cmseco02.bmp';
  FileByHash[57814]:= 'cmseco03.bmp';
  FileByHash[57798]:= 'cmseco04.bmp';
  FileByHash[57782]:= 'cmseco05.bmp';
  FileByHash[57766]:= 'cmseco06.bmp';
  FileByHash[57750]:= 'cmseco07.bmp';
  FileByHash[57734]:= 'cmseco08.bmp';
  FileByHash[57718]:= 'cmseco09.bmp';
  FileByHash[49670]:= 'cmseco10.bmp';
  FileByHash[49654]:= 'cmseco11.bmp';
  FileByHash[49638]:= 'cmseco12.bmp';
  FileByHash[49622]:= 'cmseco13.bmp';
  FileByHash[49606]:= 'cmseco14.bmp';
  FileByHash[49590]:= 'cmseco15.bmp';
  FileByHash[52882]:= 'spelco01.bmp';
  FileByHash[52866]:= 'spelco02.bmp';
  FileByHash[52850]:= 'spelco03.bmp';
  FileByHash[52834]:= 'spelco04.bmp';
  FileByHash[52818]:= 'spelco05.bmp';
  FileByHash[52802]:= 'spelco06.bmp';
  FileByHash[52786]:= 'spelco07.bmp';
  FileByHash[52770]:= 'spelco08.bmp';
  FileByHash[52754]:= 'spelco09.bmp';
  FileByHash[44706]:= 'spelco10.bmp';
  FileByHash[44690]:= 'spelco11.bmp';
  FileByHash[44674]:= 'spelco12.bmp';
  FileByHash[44658]:= 'spelco13.bmp';
  FileByHash[44642]:= 'spelco14.bmp';
  FileByHash[44626]:= 'spelco15.bmp';
  FileByHash[44610]:= 'spelco16.bmp';
  FileByHash[44594]:= 'spelco17.bmp';
  FileByHash[44578]:= 'spelco18.bmp';
  FileByHash[44562]:= 'spelco19.bmp';
  FileByHash[36514]:= 'spelco20.bmp';
  FileByHash[31745]:= 'advmbw01.bmp';
  FileByHash[31729]:= 'advmbw02.bmp';
  FileByHash[31713]:= 'advmbw03.bmp';
  FileByHash[31697]:= 'advmbw04.bmp';
  FileByHash[31681]:= 'advmbw05.bmp';
  FileByHash[31665]:= 'advmbw06.bmp';
  FileByHash[31649]:= 'advmbw07.bmp';
  FileByHash[31633]:= 'advmbw08.bmp';
  FileByHash[31617]:= 'advmbw09.bmp';
  FileByHash[23569]:= 'advmbw10.bmp';
  FileByHash[23553]:= 'advmbw11.bmp';
  FileByHash[23537]:= 'advmbw12.bmp';
  FileByHash[23521]:= 'advmbw13.bmp';
  FileByHash[23505]:= 'advmbw14.bmp';
  FileByHash[23489]:= 'advmbw15.bmp';
  FileByHash[23473]:= 'advmbw16.bmp';
  FileByHash[23457]:= 'advmbw17.bmp';
  FileByHash[23441]:= 'advmbw18.bmp';
  FileByHash[23425]:= 'advmbw19.bmp';
  FileByHash[15377]:= 'advmbw20.bmp';
  FileByHash[15361]:= 'advmbw21.bmp';
  FileByHash[15345]:= 'advmbw22.bmp';
  FileByHash[15329]:= 'advmbw23.bmp';
  FileByHash[15313]:= 'advmbw24.bmp';
  FileByHash[15297]:= 'advmbw25.bmp';
  FileByHash[15281]:= 'advmbw26.bmp';
  FileByHash[15265]:= 'advmbw27.bmp';
  FileByHash[15249]:= 'advmbw28.bmp';
  FileByHash[15233]:= 'advmbw29.bmp';
  FileByHash[7185]:= 'advmbw30.bmp';
  FileByHash[7169]:= 'advmbw31.bmp';
  FileByHash[7153]:= 'advmbw32.bmp';
  FileByHash[7137]:= 'advmbw33.bmp';
  FileByHash[7121]:= 'advmbw34.bmp';
  FileByHash[7105]:= 'advmbw35.bmp';
  FileByHash[7089]:= 'advmbw36.bmp';
  FileByHash[7073]:= 'advmbw37.bmp';
  FileByHash[7057]:= 'advmbw38.bmp';
  FileByHash[7041]:= 'advmbw39.bmp';
  FileByHash[64528]:= 'advmbw40.bmp';
  FileByHash[24567]:= 'cmsebw01.bmp';
  FileByHash[24551]:= 'cmsebw02.bmp';
  FileByHash[24535]:= 'cmsebw03.bmp';
  FileByHash[24519]:= 'cmsebw04.bmp';
  FileByHash[24503]:= 'cmsebw05.bmp';
  FileByHash[24487]:= 'cmsebw06.bmp';
  FileByHash[24471]:= 'cmsebw07.bmp';
  FileByHash[24455]:= 'cmsebw08.bmp';
  FileByHash[24439]:= 'cmsebw09.bmp';
  FileByHash[16391]:= 'cmsebw10.bmp';
  FileByHash[16375]:= 'cmsebw11.bmp';
  FileByHash[16359]:= 'cmsebw12.bmp';
  FileByHash[16343]:= 'cmsebw13.bmp';
  FileByHash[16327]:= 'cmsebw14.bmp';
  FileByHash[16311]:= 'cmsebw15.bmp';
  FileByHash[19603]:= 'spelbw01.bmp';
  FileByHash[19587]:= 'spelbw02.bmp';
  FileByHash[19571]:= 'spelbw03.bmp';
  FileByHash[19555]:= 'spelbw04.bmp';
  FileByHash[19539]:= 'spelbw05.bmp';
  FileByHash[19523]:= 'spelbw06.bmp';
  FileByHash[19507]:= 'spelbw07.bmp';
  FileByHash[19491]:= 'spelbw08.bmp';
  FileByHash[19475]:= 'spelbw09.bmp';
  FileByHash[11427]:= 'spelbw10.bmp';
  FileByHash[11411]:= 'spelbw11.bmp';
  FileByHash[11395]:= 'spelbw12.bmp';
  FileByHash[11379]:= 'spelbw13.bmp';
  FileByHash[11363]:= 'spelbw14.bmp';
  FileByHash[11347]:= 'spelbw15.bmp';
  FileByHash[11331]:= 'spelbw16.bmp';
  FileByHash[11315]:= 'spelbw17.bmp';
  FileByHash[11299]:= 'spelbw18.bmp';
  FileByHash[11283]:= 'spelbw19.bmp';
  FileByHash[3235]:= 'spelbw20.bmp';
  FileByHash[3743]:= 'stpmcfg.bin';
  FileByHash[24707]:= 'btnmcfg.icn';
  FileByHash[44882]:= 'stpbaud.bin';
  FileByHash[311]:= 'btnbaud.icn';
  FileByHash[4677]:= 'stpdc.bin';
  FileByHash[12201]:= 'btndc.icn';
  FileByHash[4124]:= 'stpdccfg.bin';
  FileByHash[7308]:= 'btndccfg.icn';

  // New files
  FileByHash[22583]:= 'file_14.bin'; // "initmenu.bmp", "initmenu.icn"
  FileByHash[3858]:= 'initmenu.bmp';
  FileByHash[8952]:= 'initmenu.icn';
  FileByHash[17466]:= 'file_29.icn'; // ?
//  FileByHash[33487]:= 'file_114';
//  FileByHash[54619]:= 'file_115';
//  FileByHash[122]:= 'file_116';
//  FileByHash[42950]:= 'file_117';
//  FileByHash[17225]:= 'file_118';
//  FileByHash[36839]:= 'file_119';
//  FileByHash[62659]:= 'file_120';
//  FileByHash[30512]:= 'file_121';
//  FileByHash[41987]:= 'file_122';
//  FileByHash[3742]:= 'file_123';
//  FileByHash[19819]:= 'file_124';
//  FileByHash[34051]:= 'file_125';
//  FileByHash[29800]:= 'file_126';
//  FileByHash[61522]:= 'file_127';
//  FileByHash[57607]:= 'file_128';
//  FileByHash[2026]:= 'file_129';
//  FileByHash[46680]:= 'file_130';
//  FileByHash[46303]:= 'file_131';
//  FileByHash[52748]:= 'file_132';
//  FileByHash[14683]:= 'file_133';
//  FileByHash[51164]:= 'file_134';
//  FileByHash[52411]:= 'file_135';
//  FileByHash[34135]:= 'file_136';
//  FileByHash[9522]:= 'file_137';
//  FileByHash[45330]:= 'file_138';
//  FileByHash[8423]:= 'file_139';
//  FileByHash[39472]:= 'file_140';
//  FileByHash[29765]:= 'file_141';
  FileByHash[63926]:= 'file_148.bmp'; // NWC Presents
//  FileByHash[54814]:= 'file_166'; // ??
  FileByHash[12247]:= 'file_278.bin'; // "Recruit Monster?"
  FileByHash[19768]:= 'buybuild.bin';
  FileByHash[60994]:= 'msgwin.bin';
  FileByHash[28493]:= 'errwin.bin';
  FileByHash[25306]:= 'disarmy.bin';
  FileByHash[18102]:= 'dishero.bin';
  FileByHash[12089]:= 'overvu00.bmp';
  FileByHash[12073]:= 'overvu01.bmp';
  FileByHash[12057]:= 'overvu02.bmp';
  FileByHash[12041]:= 'overvu03.bmp';
  FileByHash[48089]:= 'vstat00.bin';
  FileByHash[48073]:= 'vstat01.bin';
  FileByHash[48057]:= 'vstat02.bin';
  FileByHash[48041]:= 'vstat03.bin';
  FileByHash[48025]:= 'vstat04.bin';
  FileByHash[22694]:= 'vstatb00.bin';
  FileByHash[22678]:= 'vstatb01.bin';
  FileByHash[22662]:= 'vstatb02.bin';
  FileByHash[22646]:= 'vstatb03.bin';
  FileByHash[22630]:= 'vstatb04.bin';
  FileByHash[21820]:= 'nospells.bin';
  FileByHash[63564]:= 'noname.bin';
  FileByHash[3255]:= 'nocolor.bin';
  FileByHash[52231]:= 'noenemy.bin';
  FileByHash[62188]:= 'idspell.bin';
  FileByHash[10060]:= 'ask2save.bin';
  FileByHash[13552]:= 'boatfail.bin';
  FileByHash[28136]:= 'dimfail.bin';
  FileByHash[48346]:= 'catsnd01.82M';
  FileByHash[26818]:= 'hintro.pal';
  FileByHash[40439]:= 'left.bmp';
  FileByHash[3192]:= 'right.bmp';
  FileByHash[40654]:= 'tent1.icn';
  FileByHash[40638]:= 'tent2.icn';
  FileByHash[40622]:= 'tent3.icn';
  FileByHash[40606]:= 'tent4.icn';
  FileByHash[40590]:= 'tent5.icn';
  FileByHash[40574]:= 'tent6.icn';
  FileByHash[40558]:= 'tent7.icn';
  FileByHash[3642]:= 'banner.icn';
  FileByHash[52823]:= 'crowd.icn';
  FileByHash[49149]:= 'msgwin01.bin';
  FileByHash[24573]:= 'msgwin31.bin';
  FileByHash[24557]:= 'msgwin32.bin';
  FileByHash[24445]:= 'msgwin39.bin';
end;

end.