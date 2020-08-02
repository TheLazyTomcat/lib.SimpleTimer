{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Simple timer

    Simple non-visual variant of TTimer component.

  Version 1.1.4 (2020-01-10)

  Last change 2020-08-02

  ©2015-2020 František Milt

  Contacts:
    František Milt: frantisek.milt@gmail.com

  Support:
    If you find this code useful, please consider supporting its author(s) by
    making a small donation using the following link(s):

      https://www.paypal.me/FMilt

  Changelog:
    For detailed changelog and history please refer to this git repository:

      github.com/TheLazyTomcat/Lib.SimpleTimer

  Dependencies:
    AuxTypes       - github.com/TheLazyTomcat/Lib.AuxTypes
    AuxClasses     - github.com/TheLazyTomcat/Lib.AuxClasses
    UtilityWindow  - github.com/TheLazyTomcat/Lib.UtilityWindow
    MulticastEvent - github.com/TheLazyTomcat/Lib.MulticastEvent
    WndAlloc       - github.com/TheLazyTomcat/Lib.WndAlloc
    StrRect        - github.com/TheLazyTomcat/Lib.StrRect
  * SimpleCPUID    - github.com/TheLazyTomcat/Lib.SimpleCPUID

    SimpleCPUID is required only when PurePascal symbol is not defined.

===============================================================================}
unit SimpleTimer;

{$IF not(defined(WINDOWS) or defined(MSWINDOWS))}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}
{$H+}

interface

uses
  Windows, Messages, SysUtils, Classes,
  AuxTypes, AuxClasses, UtilityWindow;

{=== TSimpleTimer - library-specific exceptions ===============================}
type
  ESTException = class(Exception);

  ESTOutOfResources = class(ESTException);

{=== TSimpleTimer - class declaration =========================================}

  TSimpleTimer = class(TCustomObject)
  private
    fOwnsWindow:  Boolean;
    fWindow:      TUtilityWindow;
    fTimerID:     PtrUInt;
    fInterval:    UInt32;
    fEnabled:     Boolean;
    fTag:         Integer;
    fOnTimer:     TNotifyEvent;
    Function GetWindowHandle: HWND;
    procedure SetInterval(Value: UInt32);
    procedure SetEnabled(Value: Boolean);
  protected
    procedure SetupTimer;
    procedure MessagesHandler(var Msg: TMessage; var Handled: Boolean; Sent: Boolean);
  public
    constructor Create(Window: TUtilityWindow = nil; TimerID: PtrUInt = 1);
    destructor Destroy; override;
    procedure ProcessMassages;
    property WindowHandle: HWND read GetWindowHandle;
    property Window: TUtilityWindow read fWindow;
    property TimerID: PtrUInt read fTimerID;
    property OwnsWindow: Boolean read fOwnsWindow;
    property Interval: UInt32 read fInterval write SetInterval;
    property Enabled: Boolean read fEnabled write SetEnabled;
    property Tag: Integer read fTag write fTag;
    property OnTimer: TNotifyEvent read fOnTimer write fOnTimer;
  end;

implementation

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{=== TSimpleTimer - class implementation ======================================}

{--- TSimpleTimer - private methods -------------------------------------------}

Function TSimpleTimer.GetWindowHandle: HWND;
begin
Result := fWindow.WindowHandle;
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.SetInterval(Value: UInt32);
begin
fInterval := Value;
SetupTimer;
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.SetEnabled(Value: Boolean);
begin
fEnabled := Value;
SetupTimer;
end;

{--- TSimpleTimer - protected methods -----------------------------------------}

procedure TSimpleTimer.SetupTimer;
begin
KillTimer(WindowHandle,fTimerID);
If (fInterval > 0) and fEnabled then
  If SetTimer(WindowHandle,fTimerID,fInterval,nil) = 0 then
    raise ESTOutOfResources.Create('Not enough timers available.');
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TSimpleTimer.MessagesHandler(var Msg: TMessage; var Handled: Boolean; Sent: Boolean);
begin
If (Msg.Msg = WM_TIMER) and (PtrUInt(Msg.wParam) = fTimerID) then
  begin
    If Assigned(fOnTimer) then
      fOnTimer(Self);
    Msg.Result := 0;
    Handled := True;
  end
else Handled := False;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{--- TSimpleTimer - public methods --------------------------------------------}

constructor TSimpleTimer.Create(Window: TUtilityWindow = nil; TimerID: PtrUInt = 1);
begin
inherited Create;
If Assigned(Window) then
  begin
    fOwnsWindow := False;
    fWindow := Window;
  end
else
  begin
    fOwnsWindow := True;
    fWindow := TUtilityWindow.Create;
  end;
fWindow.OnMessage.Add(MessagesHandler);
fTimerID := TimerID;
fInterval := 1000;
fEnabled := False;
end;

//------------------------------------------------------------------------------

destructor TSimpleTimer.Destroy;
begin
fEnabled := False;
SetupTimer;
If fOwnsWindow then
  fWindow.Free
else
  fWindow.OnMessage.Remove(MessagesHandler);
inherited;
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.ProcessMassages;
begin
fWindow.ContinuousProcessMessages(False);
end;

end.
