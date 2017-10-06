{
See DOOMRL.PAS for copyright info
}

library application;

{$IFNDEF ANDROID}
{$ERROR This library should be compiled only for Android}
{$ENDIF}

{$MODE objfpc}
{$H+}
{$LINKLIB log}

uses SysUtils, jni, vsystems,
     vdebug, doombase, dfoutput, vlog, vutil, vos,
     dfdata, doommodule, doomnet, doomio;

const
        ANDROID_LOG_UNKNOWN = 0;
        ANDROID_LOG_DEFAULT = 1;
        ANDROID_LOG_VERBOSE = 2;
        ANDROID_LOG_DEBUG = 3;
	ANDROID_LOG_INFO = 4;
        ANDROID_LOG_WARN = 5;
        ANDROID_LOG_ERROR = 6;
        ANDROID_LOG_FATAL = 7;
        ANDROID_LOG_SILENT = 8;
	PROGRAM_TAG = 'doomrl';

type

  TAndroidLogCallback = class(TObject)
    private
      function toAndroidLogLevel(aLevel: TLogLevel): Integer;
    public
      procedure AndroidLog(aLevel : TLogLevel;
                           const aMessage : AnsiString);
  end;

var RootPath : AnsiString = '';

function __android_log_write (LogLevel:Integer;
                              LogTag: PChar;
    		              LogMsg: PChar): Integer;
                              cdecl;
                              external;

function TAndroidLogCallback.toAndroidLogLevel(aLevel : TLogLevel): Integer;
begin
  case aLevel of
    LOGNONE:     Exit(ANDROID_LOG_SILENT);
    LOGREPORT:   Exit(ANDROID_LOG_INFO);
    LOGERROR:    Exit(ANDROID_LOG_ERROR);
    LOGWARN:     Exit(ANDROID_LOG_WARN);
    LOGINFO:     Exit(ANDROID_LOG_INFO);
    LOGDEBUG:    Exit(ANDROID_LOG_DEBUG);
    LOGDEBUG2:   Exit(ANDROID_LOG_VERBOSE);
    else         Exit(ANDROID_LOG_UNKNOWN);
  end;
end;

procedure TAndroidLogCallback.AndroidLog(aLevel : TLogLevel; const aMessage : AnsiString);
begin
  __android_log_write(toAndroidLogLevel(aLevel), PROGRAM_TAG, PChar(aMessage));
end;

function JNI_OnLoad(vm:PJavaVM;reserved:pointer):jint;cdecl;
begin
  __android_log_write(ANDROID_LOG_INFO, PROGRAM_TAG, 'JNI_OnLoad()');
  Exit( JNI_VERSION_1_6 );
end;

function SDL_main(argc:Integer;argv:PPChar):Integer;cdecl;
var
  cbObj : TAndroidLogCallback;
begin
try
  try
    DoomNetwork := nil;
    Modules     := nil;

    cbObj := TAndroidLogCallback.Create;
    Logger.AddSink( TCallbackLogSink.Create( LOGWARN, @cbObj.AndroidLog ) );
    Logger.AddSink( TTextFileLogSink.Create( LOGDEBUG, RootPath+'log.txt', False ) );
    LogSystemInfo();
    Logger.Log( LOGINFO, 'Root path set to - '+RootPath );

    Doom := Systems.Add(TDoom.Create) as TDoom;
    DoomNetwork := TDoomNetwork.Create;
    if DoomNetwork.AlertCheck then Halt(0);

    Modules     := TDoomModules.Create;

    Randomize;
    Doom.CreateIO;
    Doom.Run;
  finally
    FreeAndNil( Modules );
    FreeAndNil( DoomNetwork );
    FreeAndNil( Systems );
  end;
except on e : Exception do
  begin
    if not EXCEPTEMMITED then
      EmitCrashInfo( e.Message, False );
    raise
  end;
end;

end;

exports
  JNI_OnLoad name 'JNI_OnLoad',
  SDL_main name 'SDL_main';

begin
end.



