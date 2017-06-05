program launcher;

{$mode delphi}{$H+}

uses
windows, HttpDownloader, LogMgr;

{$R *.res}
const
  REG_KEY:PChar='SOFTWARE\GSC Game World\STALKER-STCS';

  NAME_RECORD:PChar='InstallUserName';
  VERSION_RECORD:PChar='InstallVers';
  CDKEY_RECORD:PChar='InstallCDKEY';
  LANG_RECORD:PChar='InstallLang';
  PATCH_RECORD:PChar='InstallPatchID';
  PATH_RECORD:PChar='InstallPath';

  NAME_DEF_VALUE:PChar='Player';
  VERSION_DEF_VALUE:PChar='1.0010';
  CDKEY_DEF_VALUE:PChar='';
  LANG_DEF_VALUE:PChar='ru';
  PATCH_DEF_VALUE:cardinal=1428;

  ENGINE_PATH:PChar='bin\xrEngine.exe';


  GAMEPOLIS_EMERGENCY_URL='http://stalker.gamepolis.ru/stcs_emergency/update';
  STAGILA_EMERGENCY_URL='http://stalker.stagila.ru:8080/stcs_emergency/update';

  EMERGENCY_FUN:string='ApplyUpdate';
  EMERGENCY_FILENAME:string='update.dll';
  GAMESPY_MODULE:string='bin\xrGameSpy.dll';

var
  key:HKEY;
  path:array of char;
  path_string:string;
  si:TStartupInfo;
  pi:TProcessInformation;

  th:FZDownloaderThread;
  dl:FZFileDownloader;
  update_loaded:boolean;

  _ApplyUpdate: function():boolean; stdcall;
  updater_hndl:THandle;
  need_run:boolean;
begin
  LogMgr.Init();
  need_run:=true;

  setlength(path, 256);
  while GetCurrentDirectory(length(path), @path[0]) = 0 do begin
    setlength(path, length(path)*2);
  end;

  key:=0;
  if RegCreateKey(HKEY_LOCAL_MACHINE, REG_KEY, key) = ERROR_SUCCESS then begin
    if RegQueryValueEx(key, NAME_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, NAME_RECORD, 0, REG_SZ, NAME_DEF_VALUE, length(NAME_DEF_VALUE)+1);
    end;

    if RegQueryValueEx(key, VERSION_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, VERSION_RECORD, 0, REG_SZ, VERSION_DEF_VALUE, length(VERSION_DEF_VALUE)+1);
    end;

    if RegQueryValueEx(key, CDKEY_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, CDKEY_RECORD, 0, REG_SZ, CDKEY_DEF_VALUE, length(CDKEY_DEF_VALUE)+1);
    end;

    if RegQueryValueEx(key, LANG_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, LANG_RECORD, 0, REG_SZ, LANG_DEF_VALUE, length(LANG_DEF_VALUE)+1);
    end;

    if RegQueryValueEx(key, PATCH_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, PATCH_RECORD, 0, REG_DWORD, @PATCH_DEF_VALUE, sizeof(PATCH_DEF_VALUE));
    end;

    if RegQueryValueEx(key, PATH_RECORD, nil, nil, nil, nil) <> ERROR_SUCCESS then begin
      RegSetValueEx(key, PATH_RECORD, 0, REG_SZ, @path[0], length(path));
    end;

    RegCloseKey(key);
  end;


  //Try to load updater
  path_string:=PChar(@path[0]);
  if (path_string[length(path_string)]<>'\') and (path_string[length(path_string)]<>'/') then begin
    path_string:=path_string+'\';
  end;


  th:=FZDownloaderThread.Create(path_string+GAMESPY_MODULE);
  dl:=FZFileDownloader.Create(GAMEPOLIS_EMERGENCY_URL, path_string+EMERGENCY_FILENAME, 0, th);
  update_loaded := dl.StartSyncDownload();

  if not update_loaded then begin
    dl.Free;
    dl:=FZFileDownloader.Create(STAGILA_EMERGENCY_URL, path_string+EMERGENCY_FILENAME, 0, th);
    update_loaded := dl.StartSyncDownload();
  end;

  th.Free;

  //If updater present - run it
  if update_loaded then begin
    updater_hndl:=LoadLibrary(PChar(path_string+EMERGENCY_FILENAME));
    if updater_hndl<>0 then begin
      _ApplyUpdate:=GetProcAddress( updater_hndl, PChar(EMERGENCY_FUN));
      if @_ApplyUpdate<>nil then begin
        need_run:=_ApplyUpdate();
      end;
      FreeLibrary(updater_hndl);
    end;
  end;

  DeleteFile(PChar(path_string+EMERGENCY_FILENAME));

  if need_run then begin
    FillMemory(@pi, sizeof(pi), 0);
    FillMemory(@si, sizeof(si), 0);
    si.cb := sizeof(si);

    CreateProcess(ENGINE_PATH, '', nil, nil, false, 0, nil, @path[0], si, pi);
  end;

  setlength(path, 0);

  LogMgr.Free;
end.

