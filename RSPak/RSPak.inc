 // in Public domain
 
 // (Delphi Versions)

{$IFNDEF VER80}                      {Delphi 1}
  {$IFNDEF VER90}                    {Delphi 2}
    {$IFNDEF VER93}                  {BCB 1}
      {$DEFINE D3}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFNDEF VER100}                     {Delphi 3}
  {$IFNDEF VER110}                   {BCB 3}
    {$DEFINE D4}
  {$ENDIF}
{$ENDIF}

{$IFNDEF VER120}                     {Delphi 4}
  {$IFNDEF VER125}                   {BCB 4}
    {$DEFINE D5}
  {$ENDIF}
{$ENDIF}

{$IFNDEF VER130}                     {Delphi/BCB 5}
  {$DEFINE D6}
{$ENDIF}

{$IFNDEF VER140}                     {Delphi/BCB 6}
  {$DEFINE D7}
{$ENDIF}

{$IFNDEF VER150}                     {Delphi 7}
  {$DEFINE D8}
{$ENDIF}

{$IFNDEF VER160}                     {Delphi 8}
  {$DEFINE D2005}
{$ENDIF}

{$IFNDEF VER170}                     {Delphi 2005}
  {$DEFINE D2006}
{$ENDIF}

{$IFNDEF VER180}                     {Delphi 2006 / 2007}
  {$DEFINE D2007n}
{$ENDIF}

{$IFNDEF VER190}                     {Delphi 2007 net}
  {$DEFINE D2009}
{$ENDIF}

{$IFNDEF VER200}                     {Delphi 2009}
  {$DEFINE D2010}
{$ENDIF}

{$IFNDEF VER210}                     {Delphi 2010}
  {$DEFINE DXE1}
{$ENDIF}

{$IFNDEF VER220}                     {Delphi XE}
  {$DEFINE DXE2}
{$ENDIF}

{$IFNDEF VER230}                     {Delphi XE 2}
  {$DEFINE DXE3}
{$ENDIF}

{$IFNDEF VER240}                     {Delphi XE 3}
  {$DEFINE DXE4}
{$ENDIF}

{$IFNDEF VER250}                     {Delphi XE 4}
  {$DEFINE DXE5}
{$ENDIF}

{$IFNDEF VER260}                     {Delphi XE 5}
  {$DEFINE DXE6}
{$ENDIF}

{$IFNDEF VER270}                     {Delphi XE 6}
  {$DEFINE DXE7}
{$ENDIF}

{$IFNDEF VER280}                     {Delphi XE 7}
  {$DEFINE DXE8}
{$ENDIF}

{$IFNDEF VER290}                     {Delphi XE 8}
  {$DEFINE DXE9}
{$ENDIF}

{$IFNDEF VER300}                     {Delphi Seattle}
  {$DEFINE DSeattle}
{$ENDIF}


{$IFNDEF D3}     {$UNDEF D4}     {$ENDIF}
{$IFNDEF D4}     {$UNDEF D5}     {$ENDIF}
{$IFNDEF D5}     {$UNDEF D6}     {$ENDIF}
{$IFNDEF D6}     {$UNDEF D7}     {$ENDIF}
{$IFNDEF D7}     {$UNDEF D8}     {$ENDIF}
{$IFNDEF D8}     {$UNDEF D2005}  {$ENDIF}
{$IFNDEF D2005}  {$UNDEF D2006}  {$ENDIF}
{$IFNDEF D2006}  {$UNDEF D2007n} {$ENDIF}
{$IFNDEF D2007n} {$UNDEF D2009}  {$ENDIF}
{$IFNDEF D2009}  {$UNDEF D2010}  {$ENDIF}
{$IFNDEF D2010}  {$UNDEF DXE1}   {$ENDIF}
{$IFNDEF DXE1}   {$UNDEF DXE2}   {$ENDIF}
{$IFNDEF DXE2}   {$UNDEF DXE3}   {$ENDIF}
{$IFNDEF DXE3}   {$UNDEF DXE4}   {$ENDIF}
{$IFNDEF DXE4}   {$UNDEF DXE5}   {$ENDIF}
{$IFNDEF DXE5}   {$UNDEF DXE6}   {$ENDIF}
{$IFNDEF DXE6}   {$UNDEF DXE7}   {$ENDIF}
{$IFNDEF DXE7}   {$UNDEF DXE8}   {$ENDIF}
{$IFNDEF DXE8}   {$UNDEF DXE9}   {$ENDIF}
{$IFNDEF DXE9}   {$UNDEF DSeattle} {$ENDIF}

// destinguish D2007 from D2006
{$IFDEF D2007n}
  {$DEFINE D2007}
{$ENDIF}
{$IFDEF VER185}
  {$DEFINE D2007}
{$ENDIF}

 // (Options)

{$IFDEF D6}
{ $ObjExportAll On}  // Never used BCB. Should I turn this on? 
{$ENDIF}

{$IFDEF D7}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$ENDIF}

{$WARN SYMBOL_PLATFORM OFF}
{$B-} { Complete Boolean Evaluation }
{$R-} { Range-Checking }
{$Q-} { Overflow checking }
{$U-} { No support for prehistoric Pentium FDIV bug }
{$T-} { Typed @ operator }
{$X+} { Extended syntax }
{$H+} { Use long strings }
{$D+} { Enable breakpoints (should always be on everywhere!) }

