library SampleUpdateDll;

{$mode delphi}{$H+}
uses Windows;

function ApplyUpdate():boolean; stdcall;
begin
  MessageBox(0, 'Update loaded!', '', MB_OK);

  // true - run the game, false - not run
  result:=false;
end;

exports
  ApplyUpdate;

begin
end.

