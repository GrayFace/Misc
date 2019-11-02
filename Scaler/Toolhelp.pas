unit Toolhelp;
// Don't know who's the author/copyright holder of this module

interface

uses
  Windows, TlHelp32;
 
type 
  TToolhelp = class(TObject)
  private 
    m_hSnapshot: THandle; 
 
  public 
    constructor Create(dwFlags: DWORD = 0; dwProcessID: DWORD = 0); 
    destructor Destroy(); override; 
 
    function CreateSnapshot(dwFlags: DWORD; dwProcessID: DWORD = 0): BOOL; 
 
    function ProcessFirst(ppe: PProcessEntry32): BOOL; 
    function ProcessNext(ppe: PProcessEntry32): BOOL; 
    function ProcessFind(dwProcessId: DWORD; ppe: PProcessEntry32): BOOL; 
 
    function ModuleFirst(pme: PModuleEntry32): BOOL; 
    function ModuleNext(pme: PModuleEntry32): BOOL; 
    function ModuleFind_BaseAddr(pvBaseAddr: Pointer; pme: PModuleEntry32): BOOL; 
    function ModuleFind_ModName(pszModName: PChar; pme: PModuleEntry32): BOOL; 
 
    function ThreadFirst(pte: PThreadEntry32): BOOL; 
    function ThreadNext(pte: PThreadEntry32): BOOL; 
 
    function HeapListFirst(phl: PHeapList32): BOOL; 
    function HeapListNext(phl: PHeapList32): BOOL; 
    function HowManyHeaps(): Integer; 
 
    function HeapFirst(phe: PHeapEntry32; dwProcessID, dwHeapID: DWORD): BOOL; 
    function HeapNext(phe: PHeapEntry32): BOOL; 
    function HowManyBlocksInHeap(dwProcessID, dwHeapId: DWORD): Integer; 
    function IsAHeap(hProcess: THandle; pvBlock: Pointer; pdwFlags: PDWORD): BOOL; 
 
    function EnableDebugPrivilege(fEnable: BOOL = TRUE): BOOL; 
    function ReadProcessMemory(dwProcessID: DWORD; pvBaseAddress, pvBuffer: Pointer; 
      cbRead: DWORD; pdwNumberOfBytesRead: PDWORD = nil): BOOL; 
  end; 
 
implementation 
 
  // ……‰¸ è⁄ß 
constructor TToolhelp.Create(dwFlags: DWORD = 0; dwProcessID: DWORD = 0); 
begin 
  m_hSnapshot := INVALID_HANDLE_VALUE; 
  CreateSnapshot(dwFlags, dwProcessID);
end; 
 
  // ﬁ≥…… è⁄ß
destructor TToolhelp.Destroy(); 
begin 
  if (m_hSnapshot <> INVALID_HANDLE_VALUE) then CloseHandle(m_hSnapshot); 
end; 
 
  // Õ£—Äœ¸ÂÂ 
function TToolhelp.CreateSnapshot(dwFlags: DWORD; dwProcessID: DWORD = 0): BOOL; 
begin 
  if (m_hSnapshot <> INVALID_HANDLE_VALUE) then CloseHandle(m_hSnapshot); 
 
  if (dwFlags = 0) then 
    m_hSnapshot := INVALID_HANDLE_VALUE 
  else 
    m_hSnapshot := CreateToolhelp32Snapshot(dwFlags, dwProcessID); 
 
  Result := m_hSnapshot <> INVALID_HANDLE_VALUE; 
end; 
 
  // Õº√‹”∆ŒÈ 
function TToolhelp.ProcessFirst(ppe: PProcessEntry32): BOOL; 
begin 
  Result := Process32First(m_hSnapshot, ppe^); 
  if (Result = TRUE) and (ppe.th32ProcessID = 0) then 
    Result := ProcessNext(ppe); // Remove the "[System Process]" (PID = 0) 
end; 
 
function TToolhelp.ProcessNext(ppe: PProcessEntry32): BOOL; 
begin 
  Result := Process32Next(m_hSnapshot, ppe^); 
  if (Result = TRUE) and (ppe.th32ProcessID = 0) then 
    Result := ProcessNext(ppe); // Remove the "[System Process]" (PID = 0) 
end; 
 
function TToolhelp.ProcessFind(dwProcessId: DWORD; ppe: PProcessEntry32): BOOL; 
begin 
  Result := ProcessFirst(ppe); 
  while Result do 
  begin 
    if (ppe.th32ProcessID = dwProcessId) then Break; 
    Result := ProcessNext(ppe); 
  end; 
end; 
 
  // ‘Åœ˘”∆ŒÈ 
function TToolhelp.ModuleFirst(pme: PModuleEntry32): BOOL; 
begin 
  Result := Module32First(m_hSnapshot, pme^); 
end; 
 
function TToolhelp.ModuleNext(pme: PModuleEntry32): BOOL; 
begin 
  Result := Module32Next(m_hSnapshot, pme^); 
end; 
 
function TToolhelp.ModuleFind_BaseAddr(pvBaseAddr: Pointer; pme: PModuleEntry32): BOOL; 
begin 
  Result := ModuleFirst(pme); 
  while Result do 
  begin 
    if (pme.modBaseAddr = pvBaseAddr) then Break; 
    Result := ModuleNext(pme); 
  end; 
end; 
 
function TToolhelp.ModuleFind_ModName(pszModName: PChar; pme: PModuleEntry32): BOOL; 
begin 
  Result := ModuleFirst(pme); 
  while Result do 
  begin 
    if (lstrcmpi(pme.szModule,  pszModName) = 0) or 
       (lstrcmpi(pme.szExePath, pszModName) = 0) then Break; 
    Result := ModuleNext(pme); 
  end; 
end; 
 
  // ﬂÔ√‹”∆ŒÈ 
function TToolhelp.ThreadFirst(pte: PThreadEntry32): BOOL; 
begin 
  Result := Thread32First(m_hSnapshot, pte^); 
end; 
 
function TToolhelp.ThreadNext(pte: PThreadEntry32): BOOL; 
begin 
  Result := Thread32Next(m_hSnapshot, pte^); 
end; 
 
  // ‘Íƒˆ”∆ŒÈ 
function TToolhelp.HowManyHeaps(): Integer; 
var 
  hl: THeapList32; 
  fOk: BOOL; 
begin 
  Result := 0; 
  hl.dwSize := SizeOf(THeapList32); 
 
  fOk := HeapListFirst(@hl); 
  while fOK do 
  begin 
    Inc(Result); 
    fOk := HeapListNext(@hl); 
  end; 
end; 
 
function TToolhelp.HowManyBlocksInHeap(dwProcessID, dwHeapId: DWORD): Integer; 
var 
  he: THeapEntry32; 
  fOK: BOOL; 
begin 
  Result := 0; 
  he.dwSize := SizeOf(he); 
 
  fOk := HeapFirst(@he, dwProcessID, dwHeapID); 
  while fOK do 
  begin 
    Inc(Result); 
    fOk := HeapNext(@he); 
  end; 
end; 
 
function TToolhelp.HeapListFirst(phl: PHeapList32): BOOL; 
begin 
  Result := Heap32ListFirst(m_hSnapshot, phl^); 
end; 
 
function TToolhelp.HeapListNext(phl: PHeapList32): BOOL; 
begin 
  Result := Heap32ListNext(m_hSnapshot, phl^); 
end; 
 
function TToolhelp.HeapFirst(phe: PHeapEntry32; dwProcessID, dwHeapID: DWORD): BOOL; 
begin 
  Result := Heap32First(phe^, dwProcessID, dwHeapID); 
end; 
 
function TToolhelp.HeapNext(phe: PHeapEntry32): BOOL; 
begin 
  Result := Heap32Next(phe^); 
end; 
 
function TToolhelp.IsAHeap(hProcess: THandle; pvBlock: Pointer; pdwFlags: PDWORD): BOOL; 
var 
  hl: THeapList32; 
  he: THeapEntry32; 
  mbi: TMemoryBasicInformation; 
  fOkHL, fOkHE: BOOL; 
begin 
  Result := FALSE; 
  hl.dwSize := SizeOf(THeapList32); 
  he.dwSize := SizeOf(THeapEntry32); 
 
  fOkHL := HeapListFirst(@hl); 
  while fOkHL do 
  begin 
    fOkHE := HeapFirst(@he, hl.th32ProcessID, hl.th32HeapID); 
    while fOkHE do 
    begin 
      VirtualQueryEx(hProcess, Pointer(he.dwAddress), mbi, SizeOf(TMemoryBasicInformation)); 
 
      if (DWORD(mbi.AllocationBase) <= DWORD(pvBlock)) and 
         (DWORD(pvBlock) <= DWORD(mbi.AllocationBase) + mbi.RegionSize) then 
      begin 
        pdwFlags^ := hl.dwFlags; 
        Result := TRUE; 
        Exit; 
      end; 
 
      fOkHE := HeapNext(@he); 
    end; 
 
    fOkHL := HeapListNext(@hl); 
  end; 
end; 
 
  // ‹ÒŸßÿ£ﬂÓ 
function TToolhelp.EnableDebugPrivilege(fEnable: BOOL = TRUE): BOOL; 
const 
  SE_DEBUG_NAME: PChar = 'SeDebugPrivilege'; 
var 
  hToken: THandle; 
  tp: TTokenPrivileges; 
begin 
  Result := FALSE; 
 
  if OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hToken) then 
  begin 
    tp.PrivilegeCount := 1; 
    LookupPrivilegeValue(nil, SE_DEBUG_NAME, tp.Privileges[0].Luid); 
 
    if fEnable then 
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED 
    else 
      tp.Privileges[0].Attributes := 0; 
 
    AdjustTokenPrivileges(hToken, FALSE, tp, SizeOf(TTokenPrivileges), nil, PDWORD(nil)^); 
    Result := (GetLastError() = ERROR_SUCCESS); 
 
    CloseHandle(hToken); 
  end; 
end; 
 
  // ‘Íƒˆ∆—ÿ® 
function TToolhelp.ReadProcessMemory(dwProcessID: DWORD; pvBaseAddress, pvBuffer: Pointer; 
  cbRead: DWORD; pdwNumberOfBytesRead: PDWORD = nil): BOOL; 
begin 
  Result := Toolhelp32ReadProcessMemory(dwProcessID, pvBaseAddress, pvBuffer^, cbRead, pdwNumberOfBytesRead^); 
end;

end.