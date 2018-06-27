unit DXProxy;

interface

uses
  Forms, Windows, Messages, SysUtils, Classes, IniFiles, RSSysUtils, RSQ, Math,
  RSCodeHook, DirectDraw, Direct3D, TypInfo, Common, RSResample;

{$I MMPatchVer.inc}

function MyDirectDrawCreate(lpGUID: PGUID; out lplpDD: IDirectDraw;
    const pUnkOuter: IUnknown): HResult; stdcall;
function DXProxyScaleRect(const r: TRect): TRect;
procedure DXProxyOnResize;
procedure DXProxyDraw;
procedure DXProxyScale(SrcBuf: ptr; info: PDDSurfaceDesc2);

var
  DXProxyRenderW, DXProxyRenderH: int;
  DXProxyActive: Boolean;

implementation

//{$WARN HIDDEN_VIRTUAL OFF}

var
  RenderLimX, RenderLimY: int;
  RenderW: int absolute DXProxyRenderW;
  RenderH: int absolute DXProxyRenderH;
  FrontBuffer, BackBuffer, MyBackBuffer, ScaleBuffer: IDirectDrawSurface4;
  Viewport: IDirect3DViewport3;
  Viewport_Def: TD3DViewport2;
  scale, scaleL, scaleT, scaleR, scaleB, scale3D: TRSResampleInfo;
  DrawBufSW: array of Word;
  IsDDraw1: Boolean;

type
  THookedObject = class(TInterfacedObject)
  protected
    class var VMTBlocks: array of ptr;
    FCurVMT: int;
    procedure InitVMT(const Obj: IUnknown; this: IUnknown; PObj: ptr; Size: int);
  public
    function Init(const Obj: IUnknown): IUnknown; virtual;
    class function Hook(var obj): THookedObject;
  end;


  TMyDirectDraw = class(THookedObject, IDirectDraw, IDirectDraw4, IDirect3D3)
  protected
    function Compact: HResult stdcall; dynamic; abstract;
    function CreateClipper(dwFlags: DWORD;
        out lplpDDClipper: IDirectDrawClipper;
        pUnkOuter: IUnknown): HResult stdcall; dynamic; abstract;
    function CreatePalette(dwFlags: DWORD; lpColorTable: Pointer;
        out lplpDDPalette: IDirectDrawPalette;
        pUnkOuter: IUnknown): HResult stdcall; dynamic; abstract;
    function DuplicateSurface(lpDDSurface: IDirectDrawSurface4;
        out lplpDupDDSurface: IDirectDrawSurface4): HResult stdcall; overload; dynamic; abstract;
    function DuplicateSurface(lpDDSurface: IDirectDrawSurface;
        out lplpDupDDSurface: IDirectDrawSurface): HResult stdcall; overload; dynamic; abstract;
    function EnumDisplayModes(dwFlags: DWORD;
        lpDDSurfaceDesc: PDDSurfaceDesc2; lpContext: Pointer;
        lpEnumModesCallback: TDDEnumModesCallback2): HResult stdcall; overload; dynamic; abstract;
    function EnumDisplayModes(dwFlags: DWORD;
        lpDDSurfaceDesc: PDDSurfaceDesc; lpContext: Pointer;
        lpEnumModesCallback: TDDEnumModesCallback): HResult stdcall; overload; dynamic; abstract;
    function EnumSurfaces(dwFlags: DWORD; const lpDDSD: TDDSurfaceDesc2;
        lpContext: Pointer; lpEnumCallback: TDDEnumSurfacesCallback2):
        HResult stdcall; overload; dynamic; abstract;
    function EnumSurfaces(dwFlags: DWORD; const lpDDSD: TDDSurfaceDesc;
        lpContext: Pointer; lpEnumCallback: TDDEnumSurfacesCallback):
        HResult stdcall; overload; dynamic; abstract;
    function FlipToGDISurface: HResult stdcall; dynamic; abstract;
    function GetFourCCCodes(var lpNumCodes: DWORD; lpCodes: PDWORD): HResult stdcall; dynamic; abstract;
    function GetGDISurface(out lplpGDIDDSSurface: IDirectDrawSurface4): HResult stdcall; overload; dynamic; abstract;
    function GetGDISurface(out lplpGDIDDSSurface: IDirectDrawSurface): HResult stdcall; overload; dynamic; abstract;
    function GetMonitorFrequency(out lpdwFrequency: DWORD): HResult stdcall; dynamic; abstract;
    function GetScanLine(out lpdwScanLine: DWORD): HResult stdcall; dynamic; abstract;
    function GetVerticalBlankStatus(out lpbIsInVB: BOOL): HResult stdcall; dynamic; abstract;
    function Initialize(lpGUID: PGUID): HResult stdcall; dynamic; abstract;
    function RestoreDisplayMode: HResult stdcall; dynamic; abstract;
    function SetCooperativeLevel(hWnd: HWND; dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function SetDisplayMode(dwWidth: DWORD; dwHeight: DWORD; dwBPP: DWORD;
        dwRefreshRate: DWORD; dwFlags: DWORD): HResult stdcall; overload; dynamic; abstract;
    function WaitForVerticalBlank(dwFlags: DWORD; hEvent: THandle): HResult stdcall; dynamic; abstract;
    function GetAvailableVidMem(const lpDDSCaps: TDDSCaps2;
        out lpdwTotal, lpdwFree: DWORD): HResult stdcall; dynamic; abstract;
    function GetSurfaceFromDC(hdc: Windows.HDC;
        out lpDDS4: IDirectDrawSurface4): HResult stdcall; dynamic; abstract;
    function RestoreAllSurfaces: HResult stdcall; dynamic; abstract;
    function TestCooperativeLevel: HResult stdcall; dynamic; abstract;
    function GetDeviceIdentifier(out lpdddi: TDDDeviceIdentifier;
        dwFlags: DWORD): HResult stdcall; dynamic; abstract;
  protected
    function EnumDevices(lpEnumDevicesCallback: TD3DEnumDevicesCallback;
        lpUserArg: pointer): HResult stdcall; dynamic; abstract;
    function CreateLight(var lplpDirect3Dlight: IDirect3DLight;
        pUnkOuter: IUnknown): HResult stdcall; dynamic; abstract;
    function CreateMaterial(var lplpDirect3DMaterial3: IDirect3DMaterial3;
        pUnkOuter: IUnknown): HResult stdcall; dynamic; abstract;
    function FindDevice(var lpD3DFDS: TD3DFindDeviceSearch;
        var lpD3DFDR: TD3DFindDeviceResult): HResult stdcall; dynamic; abstract;
    function CreateVertexBuffer(var lpVBDesc: TD3DVertexBufferDesc;
        var lpD3DVertexBuffer: IDirect3DVertexBuffer;
        dwFlags: DWORD; pUnkOuter: IUnknown): HResult stdcall; dynamic; abstract;
    function EnumZBufferFormats(const riidDevice: TRefClsID; lpEnumCallback:
        TD3DEnumPixelFormatsCallback; lpContext: Pointer): HResult stdcall; dynamic; abstract;
    function EvictManagedTextures : HResult stdcall; dynamic; abstract;
  public
    DDraw: IDirectDraw4;
    D3D: IDirect3D3;
    IsMain: Boolean;
    destructor Destroy; override;
    function Init(const Obj: IUnknown): IUnknown; override;
    function GetDisplayMode(out lpDDSurfaceDesc: TDDSurfaceDesc2): HResult stdcall; overload;
    function GetDisplayMode(out lpDDSurfaceDesc: TDDSurfaceDesc): HResult stdcall; overload;
    function CreateSurface(const lpDDSurfaceDesc: TDDSurfaceDesc2;
        out lplpDDSurface: IDirectDrawSurface4;
        pUnkOuter: IUnknown): HResult stdcall; overload;
    function CreateSurface(var lpDDSurfaceDesc: TDDSurfaceDesc;
        out lplpDDSurface: IDirectDrawSurface;
        pUnkOuter: IUnknown): HResult stdcall; overload;
    function CreateViewport(var lplpD3DViewport3: IDirect3DViewport3;
        pUnkOuter: IUnknown): HResult stdcall;
    function CreateDevice(const rclsid: TRefClsID; lpDDS: IDirectDrawSurface4;
        out lplpD3DDevice: IDirect3DDevice3; pUnkOuter: IUnknown): HResult stdcall;
    function SetDisplayMode(dwWidth: DWORD; dwHeight: DWORD;
        dwBpp: DWORD): HResult stdcall; overload;
    function GetCaps(lpDDDriverCaps: PDDCaps; lpDDHELCaps: PDDCaps): HResult stdcall;
    procedure CreateScaleSurface;
  end;


  TMyDevice = class(THookedObject, IDirect3DDevice3)
  protected
    (*** IDirect3DDevice2 methods ***)
    function GetCaps(var lpD3DHWDevDesc: TD3DDeviceDesc;
        var lpD3DHELDevDesc: TD3DDeviceDesc): HResult stdcall; dynamic; abstract;
    function GetStats(var lpD3DStats: TD3DStats): HResult stdcall; dynamic; abstract;
    function EnumTextureFormats(
        lpd3dEnumPixelProc: TD3DEnumPixelFormatsCallback; lpArg: Pointer):
        HResult stdcall; dynamic; abstract;
    function BeginScene: HResult stdcall; dynamic; abstract;
    function EndScene: HResult stdcall; dynamic; abstract;
    function GetDirect3D(var lpD3D: IDirect3D3): HResult stdcall; dynamic; abstract;
    function SetRenderTarget(lpNewRenderTarget: IDirectDrawSurface4)
        : HResult stdcall; dynamic; abstract;
    function GetRenderTarget(var lplpNewRenderTarget: IDirectDrawSurface4)
        : HResult stdcall; dynamic; abstract;
    function Begin_(d3dpt: TD3DPrimitiveType; dwVertexTypeDesc: DWORD;
        dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function BeginIndexed(dptPrimitiveType: TD3DPrimitiveType;
        dwVertexTypeDesc: DWORD; lpvVertices: pointer; dwNumVertices: DWORD;
        dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function Vertex(lpVertex: pointer): HResult stdcall; dynamic; abstract;
    function Index(wVertexIndex: WORD): HResult stdcall; dynamic; abstract;
    function End_(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetRenderState(dwRenderStateType: TD3DRenderStateType;
        var lpdwRenderState): HResult stdcall; dynamic; abstract;
    function SetRenderState(dwRenderStateType: TD3DRenderStateType;
        dwRenderState: DWORD): HResult stdcall; dynamic; abstract;
    function GetLightState(dwLightStateType: TD3DLightStateType;
        var lpdwLightState): HResult stdcall; dynamic; abstract;
    function SetLightState(dwLightStateType: TD3DLightStateType;
        dwLightState: DWORD): HResult stdcall; dynamic; abstract;
    function SetTransform(dtstTransformStateType: TD3DTransformStateType;
        var lpD3DMatrix: TD3DMatrix): HResult stdcall; dynamic; abstract;
    function GetTransform(dtstTransformStateType: TD3DTransformStateType;
        var lpD3DMatrix: TD3DMatrix): HResult stdcall; dynamic; abstract;
    function MultiplyTransform(dtstTransformStateType: TD3DTransformStateType;
        var lpD3DMatrix: TD3DMatrix): HResult stdcall; dynamic; abstract;
    function SetClipStatus(var lpD3DClipStatus: TD3DClipStatus): HResult stdcall; dynamic; abstract;
    function GetClipStatus(var lpD3DClipStatus: TD3DClipStatus): HResult stdcall; dynamic; abstract;
    function DrawIndexedPrimitive(dptPrimitiveType: TD3DPrimitiveType;
        dwVertexTypeDesc: DWORD; const lpvVertices; dwVertexCount: DWORD;
        var lpwIndices: WORD; dwIndexCount, dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function DrawPrimitiveStrided(dptPrimitiveType: TD3DPrimitiveType;
        dwVertexTypeDesc : DWORD;
        var lpVertexArray: TD3DDrawPrimitiveStridedData;
        dwVertexCount, dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function DrawIndexedPrimitiveStrided(dptPrimitiveType: TD3DPrimitiveType;
        dwVertexTypeDesc : DWORD;
        var lpVertexArray: TD3DDrawPrimitiveStridedData; dwVertexCount: DWORD;
        var lpwIndices: WORD; dwIndexCount, dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function DrawPrimitiveVB(dptPrimitiveType: TD3DPrimitiveType;
        lpd3dVertexBuffer: IDirect3DVertexBuffer;
        dwStartVertex, dwNumVertices, dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function DrawIndexedPrimitiveVB(dptPrimitiveType: TD3DPrimitiveType;
        lpd3dVertexBuffer: IDirect3DVertexBuffer; var lpwIndices: WORD;
        dwIndexCount, dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function ComputeSphereVisibility(var lpCenters: TD3DVector;
        var lpRadii: TD3DValue; dwNumSpheres, dwFlags: DWORD;
        var lpdwReturnValues: DWORD): HResult stdcall; dynamic; abstract;
    function GetTexture(dwStage: DWORD; var lplpTexture: IDirect3DTexture2)
        : HResult stdcall; dynamic; abstract;
    function SetTexture(dwStage: DWORD; lplpTexture: IDirect3DTexture2)
        : HResult stdcall; dynamic; abstract;
    function GetTextureStageState(dwStage: DWORD;
        dwState: TD3DTextureStageStateType; var lpdwValue: DWORD): HResult stdcall; dynamic; abstract;
    function SetTextureStageState(dwStage: DWORD;
        dwState: TD3DTextureStageStateType; lpdwValue: DWORD): HResult stdcall; dynamic; abstract;
    function ValidateDevice(var lpdwExtraPasses: DWORD): HResult stdcall; dynamic; abstract;
  public
    Obj: IDirect3DDevice3;
    function Init(const aObj: IUnknown): IUnknown; override;
    function SetCurrentViewport(lpd3dViewport: IDirect3DViewport3): HResult stdcall;
    function AddViewport(lpDirect3DViewport: IDirect3DViewport3): HResult stdcall;
    function DeleteViewport(lpDirect3DViewport: IDirect3DViewport3): HResult stdcall;
    function NextViewport(lpDirect3DViewport: IDirect3DViewport3;
        var lplpAnotherViewport: IDirect3DViewport3; dwFlags: DWORD): HResult stdcall;
    function GetCurrentViewport(var lplpd3dViewport: IDirect3DViewport3)
        : HResult stdcall;
    function DrawPrimitive(dptPrimitiveType: TD3DPrimitiveType;
        dwVertexTypeDesc: DWORD; const lpvVertices;
        dwVertexCount, dwFlags: DWORD): HResult stdcall;
  end;


  TMyViewport = class(THookedObject, IDirect3DViewport3)
  protected
    function Initialize(lpDirect3D: IDirect3D): HResult stdcall; dynamic; abstract;
    function GetViewport(out lpData: TD3DViewport): HResult stdcall; dynamic; abstract;
    function SetViewport(const lpData: TD3DViewport): HResult stdcall; dynamic; abstract;
    function TransformVertices(dwVertexCount: DWORD;
        const lpData: TD3DTransformData; dwFlags: DWORD;
        out lpOffscreen: DWORD): HResult stdcall; dynamic; abstract;
    function LightElements(dwElementCount: DWORD;
        var lpData: TD3DLightData): HResult stdcall; dynamic; abstract;
    function SetBackground(hMat: TD3DMaterialHandle): HResult stdcall; dynamic; abstract;
    function GetBackground(var hMat: TD3DMaterialHandle): HResult stdcall; dynamic; abstract;
    function SetBackgroundDepth(
        lpDDSurface: IDirectDrawSurface): HResult stdcall; dynamic; abstract;
    function GetBackgroundDepth(out lplpDDSurface: IDirectDrawSurface;
        out lpValid: BOOL): HResult stdcall; dynamic; abstract;
    function Clear(dwCount: DWORD; const lpRects: TD3DRect; dwFlags: DWORD):
        HResult stdcall; virtual; abstract;
    function AddLight(lpDirect3DLight: IDirect3DLight): HResult stdcall; dynamic; abstract;
    function DeleteLight(lpDirect3DLight: IDirect3DLight): HResult stdcall; dynamic; abstract;
    function NextLight(lpDirect3DLight: IDirect3DLight;
        out lplpDirect3DLight: IDirect3DLight; dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetViewport2(out lpData: TD3DViewport2): HResult stdcall; dynamic; abstract;
    function SetBackgroundDepth2(
        lpDDSurface: IDirectDrawSurface4): HResult stdcall; dynamic; abstract;
    function GetBackgroundDepth2(out lplpDDSurface: IDirectDrawSurface4;
        out lpValid: BOOL): HResult stdcall; dynamic; abstract;
  public
    Obj: IDirect3DViewport3;
    function Init(const aObj: IUnknown): IUnknown; override;
    function Clear2(dwCount: DWORD; const lpRects: TD3DRect; dwFlags: DWORD;
        dwColor: DWORD; dvZ: TD3DValue; dwStencil: DWORD): HResult stdcall;
    function SetViewport2(const lpData: TD3DViewport2): HResult stdcall;
  end;


  TMySurface = class(THookedObject, IDirectDrawSurface4)
  protected
    (*** IDirectDrawSurface methods ***)
    function AddAttachedSurface(lpDDSAttachedSurface: IDirectDrawSurface4) :
        HResult stdcall; dynamic; abstract;
    function AddOverlayDirtyRect(const lpRect: TRect): HResult stdcall; dynamic; abstract;
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; dynamic; abstract;
    function BltBatch(const lpDDBltBatch: TDDBltBatch; dwCount: DWORD;
        dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function BltFast(dwX: DWORD; dwY: DWORD;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwTrans: DWORD): HResult stdcall; dynamic; abstract;
    function DeleteAttachedSurface(dwFlags: DWORD;
        lpDDSAttachedSurface: IDirectDrawSurface4): HResult stdcall; dynamic; abstract;
    function EnumAttachedSurfaces(lpContext: Pointer;
        lpEnumSurfacesCallback: TDDEnumSurfacesCallback2): HResult stdcall; dynamic; abstract;
    function EnumOverlayZOrders(dwFlags: DWORD; lpContext: Pointer;
        lpfnCallback: TDDEnumSurfacesCallback2): HResult stdcall; dynamic; abstract;
    function Flip(lpDDSurfaceTargetOverride: IDirectDrawSurface4;
        dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetAttachedSurface(const lpDDSCaps: TDDSCaps2;
        out lplpDDAttachedSurface: IDirectDrawSurface4): HResult stdcall; dynamic; abstract;
    function GetBltStatus(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetCaps(out lpDDSCaps: TDDSCaps2): HResult stdcall; dynamic; abstract;
    function GetClipper(out lplpDDClipper: IDirectDrawClipper): HResult stdcall; dynamic; abstract;
    function GetColorKey(dwFlags: DWORD; out lpDDColorKey: TDDColorKey) :
        HResult stdcall; dynamic; abstract;
    function GetDC(out lphDC: HDC): HResult stdcall; dynamic; abstract;
    function GetFlipStatus(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetOverlayPosition(out lplX, lplY: Longint): HResult stdcall; dynamic; abstract;
    function GetPalette(out lplpDDPalette: IDirectDrawPalette): HResult stdcall; dynamic; abstract;
    function GetPixelFormat(out lpDDPixelFormat: TDDPixelFormat): HResult stdcall; dynamic; abstract;
    function GetSurfaceDesc(out lpDDSurfaceDesc: TDDSurfaceDesc2): HResult stdcall; dynamic; abstract;
    function Initialize(lpDD: IDirectDraw;
        out lpDDSurfaceDesc: TDDSurfaceDesc2): HResult stdcall; dynamic; abstract;
    function IsLost: HResult stdcall; dynamic; abstract;
    function Lock(lpDestRect: PRect;
        out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
        hEvent: THandle): HResult stdcall; dynamic; abstract;
    function ReleaseDC(hDC: Windows.HDC): HResult stdcall; dynamic; abstract;
    function _Restore: HResult stdcall; dynamic; abstract;
    function SetClipper(lpDDClipper: IDirectDrawClipper): HResult stdcall; dynamic; abstract;
    function SetColorKey(dwFlags: DWORD; lpDDColorKey: PDDColorKey) :
        HResult stdcall; dynamic; abstract;
    function SetOverlayPosition(lX, lY: Longint): HResult stdcall; dynamic; abstract;
    function SetPalette(lpDDPalette: IDirectDrawPalette): HResult stdcall; dynamic; abstract;
    function Unlock(lpRect: PRect): HResult stdcall; dynamic; abstract;
    function UpdateOverlay(lpSrcRect: PRect;
        lpDDDestSurface: IDirectDrawSurface4; lpDestRect: PRect;
        dwFlags: DWORD; lpDDOverlayFx: PDDOverlayFX): HResult stdcall; dynamic; abstract;
    function UpdateOverlayDisplay(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function UpdateOverlayZOrder(dwFlags: DWORD;
        lpDDSReference: IDirectDrawSurface4): HResult stdcall; dynamic; abstract;
    (*** Added in the v2 interface ***)
    function GetDDInterface(out lplpDD: IUnknown): HResult stdcall; dynamic; abstract;
    function PageLock(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function PageUnlock(dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    (*** Added in the V3 interface ***)
    function SetSurfaceDesc(const lpddsd2: TDDSurfaceDesc2; dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    (*** Added in the v4 interface ***)
    function SetPrivateData(const guidTag: TGUID; lpData: Pointer;
        cbSize: DWORD; dwFlags: DWORD): HResult stdcall; dynamic; abstract;
    function GetPrivateData(const guidTag: TGUID; lpBuffer: Pointer;
        var lpcbBufferSize: DWORD): HResult stdcall; dynamic; abstract;
    function FreePrivateData(const guidTag: TGUID): HResult stdcall; dynamic; abstract;
    function GetUniquenessValue(out lpValue: DWORD): HResult stdcall; dynamic; abstract;
    function ChangeUniquenessValue: HResult stdcall; dynamic; abstract;
  public
    Surf: IDirectDrawSurface4;
    function Init(const Obj: IUnknown): IUnknown; override;
  end;


  TMyBackBufferD3D = class(TMySurface, IDirectDrawSurface4)
  public
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; reintroduce;
  end;


  TMyFrontBufferD3D = class(TMySurface, IDirectDrawSurface4)
  public
    function Lock(lpDestRect: PRect;
        out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
        hEvent: THandle): HResult stdcall; reintroduce;
    function Unlock(lpRect: PRect): HResult stdcall; reintroduce;
    function GetPixelFormat(out fmt: TDDPixelFormat): HResult stdcall; reintroduce;
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; reintroduce;
  end;


  TMySurfaceSW = class(TMySurface, IDirectDrawSurface4)
  public
    function Lock(lpDestRect: PRect;
        out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
        hEvent: THandle): HResult stdcall; reintroduce;
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; reintroduce;
    function BltBatch(const lpDDBltBatch: TDDBltBatch; dwCount: DWORD;
        dwFlags: DWORD): HResult stdcall; reintroduce;
    function BltFast(dwX: DWORD; dwY: DWORD;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwTrans: DWORD): HResult stdcall; reintroduce;
    function AddAttachedSurface(lpDDSAttachedSurface: IDirectDrawSurface4) :
        HResult stdcall; reintroduce;
    function DeleteAttachedSurface(dwFlags: DWORD;
        lpDDSAttachedSurface: IDirectDrawSurface4): HResult stdcall; reintroduce;
    function EnumAttachedSurfaces(lpContext: Pointer;
        lpEnumSurfacesCallback: TDDEnumSurfacesCallback2): HResult stdcall; reintroduce;
    function EnumOverlayZOrders(dwFlags: DWORD; lpContext: Pointer;
        lpfnCallback: TDDEnumSurfacesCallback2): HResult stdcall; reintroduce;
    function Flip(lpDDSurfaceTargetOverride: IDirectDrawSurface4;
        dwFlags: DWORD): HResult stdcall; reintroduce;
    function GetAttachedSurface(const lpDDSCaps: TDDSCaps2;
        out lplpDDAttachedSurface: IDirectDrawSurface4): HResult stdcall; reintroduce;
  end;


  TMyFrontBufferSW = class(TMySurfaceSW, IDirectDrawSurface4)
  public
    function Lock(lpDestRect: PRect;
        out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
        hEvent: THandle): HResult stdcall; reintroduce;
    function Unlock(lpRect: PRect): HResult stdcall; reintroduce;
    function GetPixelFormat(out fmt: TDDPixelFormat): HResult stdcall; reintroduce;
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; reintroduce;
  end;


  TMyBackBufferSW = class(TMySurfaceSW, IDirectDrawSurface4)
  public
    function Lock(lpDestRect: PRect;
        out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
        hEvent: THandle): HResult stdcall; reintroduce;
    function Unlock(lpRect: PRect): HResult stdcall; reintroduce;
    function Blt(lpDestRect: PRect;
        lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
        dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult stdcall; reintroduce;
  end;


{ functions }

function GetRaw(const p: IUnknown):ptr;
begin
  Result:= pptr(PChar(p) + pint(PPChar(p)^ - 4)^)^;
end;

procedure MyPixelFormat(var fmt: TDDPixelFormat; res: HRESULT);
const
  str = #32#0#0#0#64#0#0#0#0#0#0#0#16#0#0#0#0#248#0#0#224#7#0#0#31#0#0#0#0#0#0#0;
begin
  if (res <> DD_OK) or (fmt.dwRGBBitCount <> 16) then
    CopyMemory(@fmt, PChar(str), length(str));
end;

var
  ScaleRect_Rect: TRect;

function DXProxyScaleRect(const r: TRect): TRect;
var
  SW, SH: int;
begin
  SW:= _ScreenW^;
  SH:= _ScreenH^;
  with Result do
  begin
    Left:= r.Left*RenderW div SW;
    Right:= r.Right*RenderW div SW;
    Top:= r.Top*RenderH div SH;
    Bottom:= r.Bottom*RenderH div SH;
  end;
end;

procedure ScaleRect(var r: PRect);
begin
  if r <> nil then
  begin
    ScaleRect_Rect:= DXProxyScaleRect(r^);
    r:= @ScaleRect_Rect;
  end;
end;

procedure CalcRenderSize;
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  RenderW:= r.Right;
  if RenderW > RenderLimX then
    RenderW:= max(640, RenderW div ((RenderW - 1) div RenderLimX + 1));
  RenderH:= r.Bottom;
  if RenderH > RenderLimY then
    RenderH:= max(480, RenderH div ((RenderH - 1) div RenderLimY + 1));
end;

procedure CalcRenderLim;
var
  i: int;
begin
  RenderLimX:= Screen.Width;
  RenderLimY:= Screen.Height;
  for i:= 0 to Screen.MonitorCount - 1 do
    with Screen.Monitors[i] do
    begin
      RenderLimX:= max(RenderLimX, Width);
      RenderLimY:= max(RenderLimY, Height);
    end;
  if RenderLimitX >= 640 then
    RenderLimX:= RenderLimitX;
  if RenderLimitY >= 480 then
    RenderLimY:= RenderLimitY;
  CalcRenderSize;
end;

function MyDirectDrawCreate(lpGUID: PGUID; out lplpDD: IDirectDraw;
    const pUnkOuter: IUnknown): HResult; stdcall;
begin
  Result:= DirectDrawCreate(lpGUID, lplpDD, pUnkOuter);
  //IDirectDraw4(lplpDD):= lplpDD as IDirectDraw4;
  //Result:= DirectDrawCreateEx(lpGUID, IDirectDraw7(lplpDD), IID_IDirectDraw7, pUnkOuter);
  //TMyDirectDraw_VMT.Hook(@lplpDD);
  DXProxyActive:= (GetWindowLong(_MainWindow^, GWL_STYLE) and WS_BORDER <> 0) or
     BorderlessFullscreen or not _Windowed^;
  DXProxyActive:= DXProxyActive and (GetDeviceCaps(GetDC(0), BITSPIXEL) = 32);
  if DXProxyActive then
    TMyDirectDraw.Hook(lplpDD);
end;

procedure DXProxyOnResize;
begin
  if RenderLimX <> 0 then
    CalcRenderSize;
  if Viewport_Def.dwSize <> 0 then
    Viewport.SetViewport2(Viewport_Def);
end;

var
  FPSUp, FPSTime: uint;

procedure FPS;
var
  k: uint;
begin
  inc(FPSUp);
  k:= GetTickCount;
  if k >= FPSTime then
  begin
    zM(FPSUp);
    FPSUp:= 0;
    FPSTime:= k + 1000;
  end;
end;

procedure DXProxyScale(SrcBuf: ptr; info: PDDSurfaceDesc2);
var
  r: TRect;
begin
  FPS;
  if Options.TmpNoIntf then  exit;
  if (scale.DestW <> RenderW) or (scale.DestH <> RenderH) then
  begin
    RSSetResampleParams(ScalingParam1, ScalingParam2);
    scale.Init(_ScreenW^, _ScreenH^, RenderW, RenderH);
    with Options.RenderRect do
      r:= DXProxyScaleRect(Rect(max(0, Left - 1), max(0, Top - 1), Right + 1, Bottom + 1));
    r.Right:= min(r.Right, RenderW);
    r.Bottom:= min(r.Bottom, RenderH);
    scale3D:= scale.ScaleRect(r);
    scaleT:= scale.ScaleRect(Rect(0, 0, RenderW, r.Top));
    scaleB:= scale.ScaleRect(Rect(0, r.Bottom, RenderW, RenderH));
    scaleL:= scale.ScaleRect(Rect(0, r.Top, r.Left, r.Bottom));
    scaleR:= scale.ScaleRect(Rect(r.Right, r.Top, RenderW, r.Bottom));
  end;
  {$IFNDEF mm6}
  if _IsD3D^ then
  begin
    RSResample16(scaleT, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch);
    RSResample16(scaleL, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch);
    RSResampleTrans16_NoAlpha(scale3D, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch, _GreenMask^ + _BlueMask^);
    RSResample16(scaleR, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch);
    RSResample16(scaleB, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch);
  end else
  {$ENDIF}
    RSResample16(scale, SrcBuf, _ScreenW^*2, info.lpSurface, info.lPitch);
end;

procedure DXProxyDraw;
{var
  info: TDDSurfaceDesc2;
  r: TRect;}
begin
{  FillChar(info, SizeOf(info), 0);
  info.dwSize:= SizeOf(info);
  if not _LockSurface(ScaleBuffer, info) then  exit;
  DXProxyScale(_ScreenBuffer^, @info);
  ScaleBuffer.Unlock(nil);
  r:= Rect(0, 0, RenderW, RenderH);
  BackBuffer.Blt(@r, ScaleBuffer, @r, DDBLT_WAIT, nil);}
end;

//function CheckGUID

{ THookedObject }

procedure PassThrough;
asm
  mov ecx, [esp + 4]
  mov edx, [eax + 4]  // Off
  mov ecx, [ecx + edx]
  mov [esp + 4], ecx
  jmp [eax]  // objVMT[i]
end;

// this fully implementation-dependant way is the only one I could come up with
function IsDyna(p: PChar): Boolean;
begin
  Result:= false;
  if pint(p)^ <> $04244483 then  exit;
  inc(p, 5);
  if pint(p)^ <> $0424448B then  exit;
  inc(p, 4);
  if pword(p)^ <> $BA66 then  exit;
  inc(p, 4);
  Result:= (p^ = #$E8);
end;

function DoInitVMT(obj, this: PPointerArray; Off, Size: int): PPointerArray;
const
  HookBase: TRSHookInfo = (newp: @PassThrough; t: RShtCodePtrStore);
var
  hook: TRSHookInfo;
  m: PPoint;
  i: int;
begin
  Result:= AllocMem(Size + 4);
  Result[0]:= ptr(Off);
  Result:= @Result[1];
  m:= AllocMem(Size*2);
  hook:= HookBase;
  for i:= 0 to Size div 4 - 1 do
    if IsDyna(this[i]) then
    begin
      m.X:= int(obj[i]);
      m.Y:= Off;
      Result[i]:= m;
      hook.p:= int(@Result[i]);
      RSApplyHook(hook);
      inc(m);
    end else
      Result[i]:= this[i];
end;

class function THookedObject.Hook(var obj): THookedObject;
begin
  Result:= Create;
  IUnknown(obj):= Result.Init(IUnknown(obj));
end;

function THookedObject.Init(const Obj: IUnknown): IUnknown;
begin
  Result:= nil;
end;

procedure THookedObject.InitVMT(const Obj: IUnknown; this: IUnknown; PObj: ptr; Size: int);
begin
  IUnknown(PObj^):= Obj;
  if FCurVMT >= length(VMTBlocks) then
  begin
    SetLength(VMTBlocks, FCurVMT + 1);
    VMTBlocks[FCurVMT]:= DoInitVMT(pptr(Obj)^, pptr(this)^, PObj - PChar(this), Size);
  end;
  pptr(this)^:= VMTBlocks[FCurVMT];
  inc(FCurVMT);
end;

{ TMyDirectDraw }

{function TMyDirectDraw.CreateDevice(const rclsid: TRefClsID;
  lpDDS: IDirectDrawSurface4; out lplpD3DDevice: IDirect3DDevice3;
  pUnkOuter: IInterface): HResult;
begin
  Result:= D3D.CreateDevice(rclsid, IDirectDrawSurface4(GetRaw(lpDDS)), lplpD3DDevice, pUnkOuter);
end;}

function TMyDirectDraw.CreateDevice(const rclsid: TRefClsID;
  lpDDS: IDirectDrawSurface4; out lplpD3DDevice: IDirect3DDevice3;
  pUnkOuter: IInterface): HResult;
begin
  if lpDDS = MyBackBuffer then
    Result:= D3D.CreateDevice(rclsid, BackBuffer, lplpD3DDevice, pUnkOuter)
  else
    Result:= D3D.CreateDevice(rclsid, lpDDS, lplpD3DDevice, pUnkOuter);
  if (Result = DD_OK) {and DXProxyActive} then
    TMyDevice.Hook(lplpD3DDevice);
end;

procedure TMyDirectDraw.CreateScaleSurface;
var
  d: TDDSurfaceDesc2;
begin
  //if _IsD3D^ then
    exit;

  FillChar(d, SizeOf(d), 0);

  with d do
  begin
    dwSize:= SizeOf(d);
    dwWidth:= RenderLimX;
    dwHeight:= RenderLimY;
    dwFlags:= DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT or DDSD_PIXELFORMAT;
    ddsCaps.dwCaps:= DDSCAPS_TEXTURE or DDSCAPS_SYSTEMMEMORY;
    //dwAlphaBitDepth:= 8;
    with ddpfPixelFormat do
    begin
      dwSize:= SizeOf(ddpfPixelFormat);
      dwFlags:= DDPF_ALPHAPIXELS or DDPF_RGB;
{      dwRGBBitCount:= 32;
      dwRBitMask:= $FF0000;
      dwGBitMask:= $FF00;
      dwBBitMask:= $FF;
      dwRGBAlphaBitMask:= $FF000000;}
      dwRGBBitCount:= 16;
    end;
  end;
  //msgz(DDraw.CreateSurface(d, ScaleBuffer, nil));
  Assert(DDraw.CreateSurface(d, ScaleBuffer, nil) = DD_OK);
end;

function TMyDirectDraw.CreateSurface(var lpDDSurfaceDesc: TDDSurfaceDesc;
  out lplpDDSurface: IDirectDrawSurface; pUnkOuter: IInterface): HResult;
var
  d: TDDSurfaceDesc2;
begin
  IsDDraw1:= true;
  CopyMemory(@d, @lpDDSurfaceDesc, lpDDSurfaceDesc.dwSize);
  d.dwSize:= SizeOf(d);
  d.ddsCaps.dwCaps2:= 0;
  d.ddsCaps.dwCaps3:= 0;
  d.ddsCaps.dwCaps4:= 0;
  d.dwTextureStage:= 0;
  Result:= CreateSurface(d, IDirectDrawSurface4(lplpDDSurface), pUnkOuter);
end;

function TMyDirectDraw.CreateSurface(const lpDDSurfaceDesc: TDDSurfaceDesc2;
  out lplpDDSurface: IDirectDrawSurface4; pUnkOuter: IInterface): HResult;
var
  desc: TDDSurfaceDesc2;
  NeedScaling: Boolean;
begin
  {with lpDDSurfaceDesc do
    if (ddsCaps.dwCaps <> $401008) or (dwFlags <> $21007) then
      zM(ddsCaps.dwCaps, dwFlags);}
  {DXProxyActive:= _Windowed^;
  if not DXProxyActive then
  begin
    Result:= DDraw.CreateSurface(lpDDSurfaceDesc, lplpDDSurface, pUnkOuter);
    exit;
  end;}

  // back buffer or Z buffer
  with lpDDSurfaceDesc do
    if _IsD3D^ then
      NeedScaling:= (ddsCaps.dwCaps = $2040) and (dwFlags = 7) or
        (ddsCaps.dwCaps = $20000) and (dwFlags = $1007)
    else
      NeedScaling:= (ddsCaps.dwCaps = $840) and (dwFlags = 7);

  // back buffer or Z buffer
  if NeedScaling then
  begin
    if lpDDSurfaceDesc.dwFlags = 7 then  // back buffer
      CalcRenderLim;
    desc:= lpDDSurfaceDesc;
    desc.dwWidth:= RenderLimX;
    desc.dwHeight:= RenderLimY;
    Result:= DDraw.CreateSurface(desc, lplpDDSurface, pUnkOuter);
    if (lpDDSurfaceDesc.dwFlags = 7) and (Result = DD_OK) then
    begin
      BackBuffer:= lplpDDSurface;
      if _IsD3D^ then
        TMyBackBufferD3D.Hook(lplpDDSurface)
      else
        TMyBackBufferSW.Hook(lplpDDSurface);
      MyBackBuffer:= lplpDDSurface;
      IsMain:= true;
      CreateScaleSurface;
    end else if not _IsD3D^ and (Result = DD_OK) then
      TMySurfaceSW.Hook(lplpDDSurface);
    exit;
  end;

  Result:= DDraw.CreateSurface(lpDDSurfaceDesc, lplpDDSurface, pUnkOuter);
  {if Result = DD_OK then
    TMySurface.Hook(lplpDDSurface);}
  // draw buffer: (ddsCaps.dwCaps = $840) and (dwFlags = $10007)

  // front buffer
  if (lpDDSurfaceDesc.ddsCaps.dwCaps and DDSCAPS_PRIMARYSURFACE <> 0) and (Result = DD_OK) then
  begin
    FrontBuffer:= lplpDDSurface;
    if _IsD3D^ then
      TMyFrontBufferD3D.Hook(lplpDDSurface)
    else
      TMyFrontBufferSW.Hook(lplpDDSurface)
  end else if not _IsD3D^ and (Result = DD_OK) then
    TMySurfaceSW.Hook(lplpDDSurface);
end;

function TMyDirectDraw.CreateViewport(var lplpD3DViewport3: IDirect3DViewport3;
  pUnkOuter: IInterface): HResult;
begin
  Result:= D3D.CreateViewport(lplpD3DViewport3, pUnkOuter);
  if (Result = DD_OK) {and DXProxyActive} then
  begin
    TMyViewport.Hook(lplpD3DViewport3);
    Viewport:= lplpD3DViewport3;
  end;
end;

destructor TMyDirectDraw.Destroy;
begin
  if not IsMain then  exit;
  FrontBuffer:= nil;
  BackBuffer:= nil;
  MyBackBuffer:= nil;
  ScaleBuffer:= nil;
  Viewport:= nil;
  Viewport_Def.dwSize:= 0;
end;

function TMyDirectDraw.GetCaps(lpDDDriverCaps, lpDDHELCaps: PDDCaps): HResult;
begin
  Result:= DDraw.GetCaps(lpDDDriverCaps, lpDDHELCaps);
  // Avoid MouseAsync usage:
  // remove DDCAPS_BLT from dwSVBCaps or remove DDCKEYCAPS_SRCBLT from dwSVBCKeyCaps
  lpDDDriverCaps.dwSVBCKeyCaps:= lpDDDriverCaps.dwSVBCKeyCaps and not DDCKEYCAPS_SRCBLT;
end;

function TMyDirectDraw.GetDisplayMode(
  out lpDDSurfaceDesc: TDDSurfaceDesc): HResult;
var
  d: TDDSurfaceDesc2;
begin
  d.dwSize:= SizeOf(d);
  Result:= GetDisplayMode(d);
  d.dwSize:= SizeOf(TDDSurfaceDesc);
  CopyMemory(@lpDDSurfaceDesc, @d, d.dwSize);
end;

function TMyDirectDraw.GetDisplayMode(
  out lpDDSurfaceDesc: TDDSurfaceDesc2): HResult;
begin
  Result:= DDraw.GetDisplayMode(lpDDSurfaceDesc);
  MyPixelFormat(lpDDSurfaceDesc.ddpfPixelFormat, Result);
end;

function TMyDirectDraw.Init(const Obj: IInterface): IUnknown;
begin
  Result:= self as IDirectDraw;
  InitVMT(Obj as IDirectDraw4, self as IDirectDraw4, @DDraw, $70);
  InitVMT(Obj as IDirect3D3, self as IDirect3D3, @D3D, $30);
  InitVMT(DDraw, Result, @DDraw, $70 - 5*4);
end;

function TMyDirectDraw.SetDisplayMode(dwWidth, dwHeight, dwBpp: DWORD): HResult;
begin
  Result:= DDraw.SetDisplayMode(dwWidth, dwHeight, dwBpp, 0, 0);
end;

{ TMyViewport }

function TMyViewport.Clear2(dwCount: DWORD; const lpRects: TD3DRect; dwFlags,
  dwColor: DWORD; dvZ: TD3DValue; dwStencil: DWORD): HResult;
var
  r: TD3DRect;
begin
  r.x1:= 0;
  r.y1:= 0;
  r.x2:= RenderW;
  r.y2:= RenderH;
  Result:= Obj.Clear2(1, r, dwFlags, dwColor, dvZ, dwStencil);
//  Result:= Obj.Clear2(dwCount, lpRects, dwFlags, dwColor, dvZ, dwStencil);
end;

function TMyViewport.Init(const aObj: IInterface): IUnknown;
begin
  Result:= self as IDirect3DViewport3;
  InitVMT(aObj as IDirect3DViewport3, Result, @Obj, 21*4);
end;

function TMyViewport.SetViewport2(const lpData: TD3DViewport2): HResult;
begin
  Viewport_Def:= lpData;
  Viewport_Def.dwWidth:= RenderW;
  Viewport_Def.dwHeight:= RenderH;
  Result:= Obj.SetViewport2(Viewport_Def);
end;

{ TMyDevice }

function TMyDevice.AddViewport(lpDirect3DViewport: IDirect3DViewport3): HResult;
begin
  Result:= Obj.AddViewport(IDirect3DViewport3(GetRaw(lpDirect3DViewport)));
end;

function TMyDevice.DeleteViewport(
  lpDirect3DViewport: IDirect3DViewport3): HResult;
begin
  Result:= Obj.DeleteViewport(IDirect3DViewport3(GetRaw(lpDirect3DViewport)));
end;

var
  VertexBuf: array of D3DVERTEX;

function TMyDevice.DrawPrimitive(dptPrimitiveType: TD3DPrimitiveType;
  dwVertexTypeDesc: DWORD; const lpvVertices; dwVertexCount,
  dwFlags: DWORD): HResult;
var
  i: int;
begin
  Result:= DD_OK;
  if dptPrimitiveType <> D3DPT_TRIANGLEFAN then
    exit;
  if int(dwVertexCount) > length(VertexBuf) then
    SetLength(VertexBuf, dwVertexCount*2);
  CopyMemory(@VertexBuf[0], @lpvVertices, dwVertexCount*SizeOf(VertexBuf[0]));
  for i:= 0 to dwVertexCount - 1 do
  begin
    VertexBuf[i].x:= VertexBuf[i].x*RenderW/_ScreenW^;
    VertexBuf[i].y:= VertexBuf[i].y*RenderH/_ScreenH^;
  end;
  Result:= Obj.DrawPrimitive(dptPrimitiveType,
    dwVertexTypeDesc, VertexBuf[0], dwVertexCount, dwFlags)
end;

function TMyDevice.GetCurrentViewport(
  var lplpd3dViewport: IDirect3DViewport3): HResult;
begin
  Assert(false);
  Result:= DD_FALSE;
end;

function TMyDevice.Init(const aObj: IInterface): IUnknown;
begin
  Result:= self as IDirect3DDevice3;
  InitVMT(aObj as IDirect3DDevice3, Result, @Obj, 42*4);
end;

function TMyDevice.NextViewport(lpDirect3DViewport: IDirect3DViewport3;
  var lplpAnotherViewport: IDirect3DViewport3; dwFlags: DWORD): HResult;
begin
  Assert(false);
  Result:= DD_FALSE;
end;

function TMyDevice.SetCurrentViewport(lpd3dViewport: IDirect3DViewport3): HResult;
begin
  Result:= Obj.SetCurrentViewport(IDirect3DViewport3(GetRaw(lpd3dViewport)));
end;

{ TMyBackBufferD3D }

function TMyBackBufferD3D.Blt(lpDestRect: PRect;
  lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect; dwFlags: DWORD;
  lpDDBltFx: PDDBltFX): HResult;
begin
  ScaleRect(lpDestRect);
  Result:= Surf.Blt(lpDestRect, lpDDSrcSurface, lpSrcRect, dwFlags, lpDDBltFx);
end;

{ TMyFrontBufferD3D }

function TMyFrontBufferD3D.Blt(lpDestRect: PRect;
  lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect; dwFlags: DWORD;
  lpDDBltFx: PDDBltFX): HResult;
begin
  if lpDDSrcSurface = MyBackBuffer then
  begin
    ScaleRect(lpSrcRect);
    Result:= Surf.Blt(lpDestRect, BackBuffer, lpSrcRect, dwFlags, lpDDBltFx)
  end else
    Result:= Surf.Blt(lpDestRect, lpDDSrcSurface, lpSrcRect, dwFlags, lpDDBltFx);
end;

function TMyFrontBufferD3D.GetPixelFormat(out fmt: TDDPixelFormat): HResult;
begin
  MyPixelFormat(fmt, Surf.GetPixelFormat(fmt));
  Result:= DD_OK;
end;

function TMyFrontBufferD3D.Lock(lpDestRect: PRect;
  out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
  hEvent: THandle): HResult;
begin
  Result:= DDERR_GENERIC;
end;

function TMyFrontBufferD3D.Unlock(lpRect: PRect): HResult;
begin
  Result:= DDERR_GENERIC;
end;

{ TMySurface }

function TMySurfaceSW.AddAttachedSurface(
  lpDDSAttachedSurface: IDirectDrawSurface4): HResult;
begin
  Result:= Surf.AddAttachedSurface(IDirectDrawSurface4(GetRaw(lpDDSAttachedSurface)));
end;

function TMySurfaceSW.Blt(lpDestRect: PRect; lpDDSrcSurface: IDirectDrawSurface4;
  lpSrcRect: PRect; dwFlags: DWORD; lpDDBltFx: PDDBltFX): HResult;
begin
  // ignore MM6 tricks with extra surfaces when an item is carried
  if GetRaw(lpDDSrcSurface) = ptr(FrontBuffer) then
  begin
    Result:= DD_OK;
    exit;
  end;
  Result:= Surf.Blt(lpDestRect, IDirectDrawSurface4(GetRaw(lpDDSrcSurface)),
    lpSrcRect, dwFlags, lpDDBltFx);
end;

function TMySurfaceSW.BltBatch(const lpDDBltBatch: TDDBltBatch; dwCount,
  dwFlags: DWORD): HResult;
begin
  Assert(false, 'Not implemented');
  Result:= DD_OK;
end;

function TMySurfaceSW.BltFast(dwX, dwY: DWORD;
  lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect;
  dwTrans: DWORD): HResult;
begin
  Result:= Surf.BltFast(dwX, dwY, IDirectDrawSurface4(GetRaw(lpDDSrcSurface)),
    lpSrcRect, dwTrans);
end;

function TMySurfaceSW.DeleteAttachedSurface(dwFlags: DWORD;
  lpDDSAttachedSurface: IDirectDrawSurface4): HResult;
begin
  Result:= Surf.DeleteAttachedSurface(dwFlags, IDirectDrawSurface4(GetRaw(lpDDSAttachedSurface)));
end;

function TMySurfaceSW.EnumAttachedSurfaces(lpContext: Pointer;
  lpEnumSurfacesCallback: TDDEnumSurfacesCallback2): HResult;
begin
  Assert(false, 'Not implemented');
  Result:= DD_OK;
end;

function TMySurfaceSW.EnumOverlayZOrders(dwFlags: DWORD; lpContext: Pointer;
  lpfnCallback: TDDEnumSurfacesCallback2): HResult;
begin
  Assert(false, 'Not implemented');
  Result:= DD_OK;
end;

function TMySurfaceSW.Flip(lpDDSurfaceTargetOverride: IDirectDrawSurface4;
  dwFlags: DWORD): HResult;
begin
  Result:= Surf.Flip(IDirectDrawSurface4(GetRaw(lpDDSurfaceTargetOverride)), dwFlags);
end;

function TMySurfaceSW.GetAttachedSurface(const lpDDSCaps: TDDSCaps2;
  out lplpDDAttachedSurface: IDirectDrawSurface4): HResult;
begin
  Assert(false, 'Not implemented');
  Result:= DD_OK;
end;

function TMySurfaceSW.Lock(lpDestRect: PRect;
  out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
  hEvent: THandle): HResult;
var
  desc: TDDSurfaceDesc2;
begin
  if IsDDraw1 then
  begin
    desc.dwSize:= SizeOf(desc);
    Result:= Surf.Lock(lpDestRect, desc, dwFlags, hEvent);
    if Result <> DD_OK then  exit;
    desc.dwSize:= SizeOf(TDDSurfaceDesc);
    CopyMemory(@lpDDSurfaceDesc, @desc, desc.dwSize);
  end else
    Result:= Surf.Lock(lpDestRect, lpDDSurfaceDesc, dwFlags, hEvent);
end;

function TMySurface.Init(const Obj: IInterface): IUnknown;
begin
  Result:= self as IDirectDrawSurface4;
  InitVMT(Obj as IDirectDrawSurface4, Result, @Surf, $B4);
end;

{ TMyFrontBufferSW }

function TMyFrontBufferSW.Blt(lpDestRect: PRect;
  lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect; dwFlags: DWORD;
  lpDDBltFx: PDDBltFX): HResult;
var
  info: TDDSurfaceDesc2;
  r: TRect;
begin
  if DrawBufSW = nil then
  begin
    Result:= DD_OK;
    exit;
  end;
  FillChar(info, SizeOf(info), 0);
  info.dwSize:= SizeOf(info);
  Result:= BackBuffer.Lock(nil, info, DDLOCK_NOSYSLOCK or DDLOCK_WAIT, 0);
  if Result <> DD_OK then  exit;
  DXProxyScale(ptr(DrawBufSW), @info);
  BackBuffer.Unlock(nil);
  if lpDDSrcSurface <> MyBackBuffer then
    _NeedRedraw^:= 1;
  r:= Rect(0, 0, RenderW, RenderH);
  Result:= inherited Blt(lpDestRect, MyBackBuffer, @r, dwFlags, lpDDBltFx);
end;

function TMyFrontBufferSW.GetPixelFormat(out fmt: TDDPixelFormat): HResult;
begin
  MyPixelFormat(fmt, Surf.GetPixelFormat(fmt));
  Result:= DD_OK;
end;

function TMyFrontBufferSW.Lock(lpDestRect: PRect;
  out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
  hEvent: THandle): HResult;
begin
  Result:= DDERR_GENERIC;
end;

function TMyFrontBufferSW.Unlock(lpRect: PRect): HResult;
begin
  Result:= DDERR_GENERIC;
end;

{ TMyBackBufferSW }

function TMyBackBufferSW.Blt(lpDestRect: PRect;
  lpDDSrcSurface: IDirectDrawSurface4; lpSrcRect: PRect; dwFlags: DWORD;
  lpDDBltFx: PDDBltFX): HResult;
begin
  if (lpDDSrcSurface = nil) and (DrawBufSW <> nil) then
    FillChar(DrawBufSW[0], length(DrawBufSW)*2, 0);
  Result:= DD_OK;
  {else
    Result:= inherited Blt(lpDestRect, lpDDSrcSurface, lpSrcRect, dwFlags, lpDDBltFx);}
end;

function TMyBackBufferSW.Lock(lpDestRect: PRect;
  out lpDDSurfaceDesc: TDDSurfaceDesc2; dwFlags: DWORD;
  hEvent: THandle): HResult;
var
  SW, SH: int;
begin
  SW:= max(_ScreenW^, 640);
  SH:= max(_ScreenH^, 480);
  SetLength(DrawBufSW, SW*SH);
  with lpDDSurfaceDesc do
  begin
    dwWidth:= SW;
    dwHeight:= SH;
    lPitch:= SW*2;
    lpSurface:= ptr(DrawBufSW);
    with ddpfPixelFormat do
    begin
      dwRGBBitCount:= 16;
      dwRBitMask:= $F800;
      dwGBitMask:= $7E0;
      dwBBitMask:= $1F;
      dwRGBAlphaBitMask:= 0;
    end;
  end;
  Result:= DD_OK;
end;

function TMyBackBufferSW.Unlock(lpRect: PRect): HResult;
begin
  Result:= DD_OK;
end;

end.
