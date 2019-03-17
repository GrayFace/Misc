unit RSInternet;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  SysUtils, Windows, Classes, WinInet, Math, RSQ, RSSysUtils;

function RSDownloadFile(URL: string; a: TStream; Timeout: DWORD = 0; Limit: int64 = $7fffffffffffffff): Boolean; overload;
function RSDownloadFile(URL: string; const fname: string; Timeout: DWORD = 0; Limit: int64 = $7fffffffffffffff): Boolean; overload;
//function RSInternetGetLastResponseInfo():string;

implementation

function RSDownloadFile(URL: string; a: TStream; Timeout: DWORD = 0; Limit: int64 = $7fffffffffffffff): Boolean; overload;
const
  BufferSize = 64*1024;
  Flags = INTERNET_FLAG_NO_UI or INTERNET_FLAG_NO_AUTH or INTERNET_FLAG_PRAGMA_NOCACHE or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_HYPERLINK or INTERNET_FLAG_NO_COOKIES;
var
  Buffer: array[1..BufferSize] of Byte;
  hSession, hURL: HInternet;
  BufLen, LastError: DWORD;
  sAppName: string;
begin
  Result:= false;
  sAppName:= ExtractFileName(ParamStr(0));
  hSession:= InternetOpen(PChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession = nil then  exit;

  try
    if Timeout <> 0 then
    begin
      InternetSetOption(hSession, INTERNET_OPTION_RECEIVE_TIMEOUT, @Timeout, SizeOf(Timeout));
      InternetSetOption(hSession, INTERNET_OPTION_CONNECT_TIMEOUT, @Timeout, SizeOf(Timeout));
    end;
    hURL := InternetOpenURL(hSession, PChar(URL), nil, 0, Flags, 0);
    if hURL = nil then  exit;

    try
      while InternetReadFile(hURL, @Buffer, min(SizeOf(Buffer), Limit), BufLen)
         and (BufLen <> 0) do
      begin
        a.WriteBuffer(Buffer, BufLen);
        dec(Limit, BufLen);
      end;
      LastError:= GetLastError;
    finally
      InternetCloseHandle(hURL);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
  SetLastError(LastError);
  Result:= (LastError = ERROR_SUCCESS);
end;

function RSDownloadFile(URL: string; const fname: string; Timeout: DWORD = 0; Limit: int64 = $7fffffffffffffff): Boolean; overload;
var
  LastError: DWORD;
  a: TRSFileStreamProxy;
begin
  a:= TRSFileStreamProxy.Create(fname, fmCreate);
  try
    a.CreateDir:= true;
    Result:= RSDownloadFile(URL, a, Timeout, Limit);
    LastError:= GetLastError;
  finally
    a.Free;
  end;
  SetLastError(LastError);
end;

end.
