{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Simple timer

    Simple non-visual interval timer.

  Version 1.1.5 (2021-11-26)

  Last change 2021-11-26

  ©2015-2021 František Milt

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

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$ELSE}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}
  {$MODESWITCH ClassicProcVars+}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}
{$H+}

interface

uses
  Windows, Messages, SysUtils,
  AuxTypes, AuxClasses, UtilityWindow;

{===============================================================================
    Library-specific exceptions
===============================================================================}
type
  ESTException = class(Exception);

  ESTTimerCreationError = class(ESTException);

{===============================================================================
--------------------------------------------------------------------------------
                                  TSimpleTimer
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSimpleTimer - class declaration
===============================================================================}
type
  TSimpleTimer = class(TCustomObject)
  private
    fOwnsWindow:      Boolean;
    fWindow:          TUtilityWindow;
    fTimerID:         PtrUInt;
    fInterval:        UInt32;
    fEnabled:         Boolean;
    fTag:             Integer;
    fOnTimerEvent:    TNotifyEvent;
    fOnTimerCallback: TNotifyCallback;
    procedure SetInterval(Value: UInt32);
    procedure SetEnabled(Value: Boolean);
  protected
    procedure Initialize(Window: TUtilityWindow; TimerID: PtrUInt); virtual;
    procedure Finalize; virtual;
    procedure SetupTimer; virtual;
    procedure MessagesHandler(var Msg: TMessage; var Handled: Boolean; Sent: Boolean); virtual;
  public
    constructor Create(Window: TUtilityWindow = nil; TimerID: PtrUInt = 1);
    destructor Destroy; override;
    procedure ProcessMassages; virtual;
    property OwnsWindow: Boolean read fOwnsWindow;
    property Window: TUtilityWindow read fWindow;
    property TimerID: PtrUInt read fTimerID;
    property Interval: UInt32 read fInterval write SetInterval;
    property Enabled: Boolean read fEnabled write SetEnabled;
    property Tag: Integer read fTag write fTag;
    property OnTimerCallback: TNotifyCallback read fOnTimerCallback write fOnTimerCallback;
    property OnTimerEvent: TNotifyEvent read fOnTimerEvent write fOnTimerEvent;
    property OnTimer: TNotifyEvent read fOnTimerEvent write fOnTimerEvent;
  end;

implementation

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                  TSimpleTimer
--------------------------------------------------------------------------------
===============================================================================}
const
  USER_TIMER_MAXIMUM = $7FFFFFFF;
  USER_TIMER_MINIMUM = $0000000A;

{===============================================================================
    TSimpleTimer - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSimpleTimer - private methods
-------------------------------------------------------------------------------}

procedure TSimpleTimer.SetInterval(Value: UInt32);
begin
If Value < USER_TIMER_MINIMUM then
  fInterval := USER_TIMER_MINIMUM
else If Value > USER_TIMER_MAXIMUM then
  fInterval := USER_TIMER_MAXIMUM
else
  fInterval := Value;
SetupTimer;
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.SetEnabled(Value: Boolean);
begin
fEnabled := Value;
SetupTimer;
end;

{-------------------------------------------------------------------------------
    TSimpleTimer - protected methods
-------------------------------------------------------------------------------}

procedure TSimpleTimer.Initialize(Window: TUtilityWindow; TimerID: PtrUInt);
begin
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

procedure TSimpleTimer.Finalize;
begin
fEnabled := False;
SetupTimer;
If fOwnsWindow then
  fWindow.Free
else
  fWindow.OnMessage.Remove(MessagesHandler);
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.SetupTimer;
begin
KillTimer(fWindow.WindowHandle,fTimerID);
If (fInterval > 0) and fEnabled then
  If SetTimer(fWindow.WindowHandle,fTimerID,fInterval,nil) = 0 then
    raise ESTTimerCreationError.CreateFmt('TSimpleTimer.SetupTimer: Failed to setup timer (0x%.8x).',[GetLastError]);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TSimpleTimer.MessagesHandler(var Msg: TMessage; var Handled: Boolean; Sent: Boolean);
begin
If (Msg.Msg = WM_TIMER) and (PtrUInt(Msg.wParam) = fTimerID) then
  begin
    If Assigned(fOnTimerEvent) then
      fOnTimerEvent(Self);
    If Assigned(fOnTimerCallback) then
      fOnTimerCallback(Self);  
    Msg.Result := 0;
    Handled := True;
  end
else Handled := False;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{-------------------------------------------------------------------------------
    TSimpleTimer - public methods
-------------------------------------------------------------------------------}

constructor TSimpleTimer.Create(Window: TUtilityWindow = nil; TimerID: PtrUInt = 1);
begin
inherited Create;
Initialize(Window,TimerID);
end;

//------------------------------------------------------------------------------

destructor TSimpleTimer.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

procedure TSimpleTimer.ProcessMassages;
begin
fWindow.ContinuousProcessMessages(False);
end;

end.
