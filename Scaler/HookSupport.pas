unit HookSupport;

interface

uses
  SysUtils, Classes, Windows, Messages, RSQ, RSSysUtils, WinSock, TlHelp32,
  Toolhelp;

function ReplaceIATEntryInOneMod(const OldProc, NewProc: FARPROC;
  hInstance: DWORD): Boolean;

function ReplaceIATEntryInAllMods(const OldProc, NewProc: FARPROC): Boolean;

implementation

// Перехват API
type
  PFARPROC = ^FARPROC;

  TIIDUnion = record
    case Integer of
      0: (Characteristics: DWORD);
      1: (OriginalFirstThunk: DWORD);
  end;

  PImageImportDescriptor = ^TImageImportDescriptor;
  TImageImportDescriptor = record
    Union: TIIDUnion;
    TimeDateStamp: DWORD;
    ForwarderChain: DWORD;
    Name: DWORD;
    FirstThunk: DWORD;
  end;

  PImageThunkData = ^TImageThunkData32;
  TImageThunkData32 = packed record
    _function : PDWORD;
  end;

{$EXTERNALSYM ImageDirectoryEntryToData}
function ImageDirectoryEntryToData(Base: Pointer; MappedAsImage: ByteBool;
  DirectoryEntry: Word; var Size: ULONG): Pointer; stdcall; external 'imagehlp.dll';

// Перехват API посредством подмены в таблице импорта
function ReplaceIATEntryInOneMod(const OldProc, NewProc: FARPROC;
  hInstance: DWORD): Boolean;
var
  Size: DWORD;
  ImportEntry: PImageImportDescriptor;
  Thunk: PImageThunkData;
  Protect, newProtect: DWORD;
  //DOSHeader: PImageDosHeader;
  //NTHeader: PImageNtHeaders;
begin
  Result:= false;
  if OldProc = nil then Exit;
  if NewProc = nil then Exit;

   // Можно искать вот так
  ImportEntry := ImageDirectoryEntryToData(Pointer(hInstance), BOOL(1),
    IMAGE_DIRECTORY_ENTRY_IMPORT, Size);
 
  // Или вот так
  {DOSHeader := PImageDosHeader(hInstance);
  if IsBadReadPtr(Pointer(hInstance), SizeOf(TImageNtHeaders)) then Exit;
  if (DOSHeader^.e_magic <> IMAGE_DOS_SIGNATURE) then Exit;
  NTHeader := PImageNtHeaders(DWORD(DOSHeader) + DWORD(DOSHeader^._lfanew));
  if NTHeader^.Signature <> IMAGE_NT_SIGNATURE then Exit;
  ImportEntry := PImageImportDescriptor(DWORD(hInstance) +
      DWORD(NTHeader^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress));
  if DWORD(ImportEntry) = DWORD(NTHeader) then Exit;  }

  if ImportEntry <> nil then
  begin
    while ImportEntry^.Name <> 0 do
    begin
        Thunk := PImageThunkData(DWORD(hInstance) +
          DWORD(ImportEntry^.FirstThunk));
        while Thunk^._function <> nil do
        begin
          if (Thunk^._function = OldProc) then
          begin
            if not IsBadWritePtr(@Thunk^._function, sizeof(DWORD)) then
              Thunk^._function := NewProc
            else
            begin

              if VirtualProtect(@Thunk^._function, SizeOf(DWORD),
                PAGE_EXECUTE_READWRITE, Protect) then
              begin
                Thunk^._function := NewProc;
                newProtect := Protect;
                VirtualProtect(@Thunk^._function, SizeOf(DWORD),
                  newProtect, Protect);
              end;
            end;
            Result:= true;
          end
          else
            Inc(PChar(Thunk), SizeOf(TImageThunkData32));
        end;
      ImportEntry := Pointer(Integer(ImportEntry) + SizeOf(TImageImportDescriptor));
    end;
  end;
end;

function ReplaceIATEntryInAllMods(const OldProc, NewProc: FARPROC): Boolean;
var
  th: TToolhelp;
  me: TModuleEntry32;
  fOk: BOOL;
begin
  me.dwSize:= SizeOf(me);
  Result:= false;
  th := TToolhelp.Create(TH32CS_SNAPMODULE, GetCurrentProcessId());
  try
    fOk := th.ModuleFirst(@me);
    while (fOk) do
    begin
      //if IsFlash(@me.szModule) then
      if me.hModule <> HInstance then
        Result:= ReplaceIATEntryInOneMod(OldProc, NewProc, me.hModule) or Result;

      fOk := th.ModuleNext(@me);
    end;
  finally
    th.Free;
  end;
end;

end.
