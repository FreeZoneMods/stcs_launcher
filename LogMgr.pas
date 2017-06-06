unit LogMgr;
{$mode delphi}
interface
type
  FZLogMessageSeverity = ( FZ_LOG_DBG, FZ_LOG_INFO, FZ_LOG_IMPORTANT_INFO, FZ_LOG_ERROR, FZ_LOG_SILENT );

  { FZLogMgr }

  FZLogMgr = class
  private
    _is_log_enabled:boolean;
    _lock:TRTLCriticalSection;

    constructor Create();
  public
    class function Get():FZLogMgr;
    procedure Write(data:string; severity:FZLogMessageSeverity = FZ_LOG_INFO);
    destructor Destroy(); override;
  end;

  function Init():boolean;
  function Free():boolean;

implementation
uses windows;

var
  Mgr:FZLogMgr;

{FZLogMgr}

constructor FZLogMgr.Create();
var
  f:textfile;
begin
  InitializeCriticalSection(_lock);

{$IFNDEF RELEASE_BUILD}
  assignfile(f, 'userdata\launcher.log');
  try
    rewrite(f);
    closefile(f);
  except
  end;
{$ENDIF}
end;

class function FZLogMgr.Get(): FZLogMgr;
begin
  result:=Mgr;
end;

procedure FZLogMgr.Write(data:string; severity:FZLogMessageSeverity);
var
  f:textfile;
begin
{$IFNDEF RELEASE_BUILD}
  EnterCriticalSection(_lock);
  try
      assignfile(f, 'userdata\launcher.log');
      try
        try
          append(f);
        except
          rewrite(f);
        end;
        writeln(f, data);
        closefile(f);
      except
      end;

  finally
    LeaveCriticalSection(_lock);
  end;
{$ENDIF}
end;

destructor FZLogMgr.Destroy();
begin
  DeleteCriticalSection(_lock);
  inherited;
end;

function Init():boolean;
begin
  Mgr:=FZLogMgr.Create();
  result:=true;
end;

function Free: boolean;
begin
  Mgr.Free();
  Mgr:=nil;
end;

end.
