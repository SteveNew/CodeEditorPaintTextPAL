unit ReadPALUses;

interface

uses
  System.Generics.Collections;

const
  // Set these based on some plugin config maybe - and also the PAL output path
  cPALDir = '"C:\Program Files\Peganza\Pascal Analyzer Lite"';
  cPALCMD = 'C:\Program Files\Peganza\Pascal Analyzer Lite\palcmd.exe';
type
  TUsesUnit = class
    UnitName: string;
    Unitflag: byte; // 1: move to implementation, 2: unnecessary
  public
    constructor Create(const name: string; flag: byte);
  end;

  TUsesList = class(TObjectList<TUsesUnit>)
  public
    function getflag(const unitname: string): byte;
  end;

  TModulesDictIntf = class(TObjectDictionary<string, TUsesList>)
  private
    FProjectName: string;
    FPALPAPDir: string;
  public
    procedure runPAL(const projname: string);
    procedure loadData(const projname: string); // Create uses.txt and read it
    property ProjectName: string read FProjectName write FProjectName;
    property PALPAPDir: string read FPALPAPDir write FPALPAPDir;
  end;
  //    Module -> -> interface_ -> list of uses_ and state
  //             |-> implementation_ -> list of uses_ and state

implementation

uses
  System.Classes, System.SysUtils, System.IOUtils, Winapi.Windows, Winapi.ShellAPI, Vcl.Forms;

{ TUsesUnit }

constructor TUsesUnit.Create(const name: string; flag: byte);
begin
  inherited Create;
  Self.UnitName := name;
  Self.Unitflag := flag;
end;

{ TModulesDictIntf }

procedure TModulesDictIntf.loadData(const projname: string);
var
  f: TStringList;
  l: Integer;
  u: TUsesList;
  currentModule, readModule, readUnit: string;
  flag: byte;
  cPALPAPDir: string;
  cPALOutputDir: string;
begin
  Self.Clear;
  cPALPAPDir := TPath.GetDocumentsPath+'\Pascal Analyzer Lite\Projects\'; // <ProjectName.pap>
  cPALOutputDir := TPath.GetDocumentsPath+'\Pascal Analyzer Lite\Projects\Output\'; //<ProjectName>
  currentModule := '';
  u := nil;
  f := TStringList.Create;
  try
    if FileExists(TPath.Combine(cPALOutputDir, projname)+'\Uses.txt') then
    begin
      f.LoadFromFile(TPath.Combine(cPALOutputDir, projname)+'\Uses.txt');
      for l := 0 to f.Count-1 do
      begin
        flag := 0;
        if f[l].StartsWith('Module ') then // Get ModuleName
        begin
          var p := Pos(' uses:', f[l]);
          readModule := f[l].Substring(7, p-8);
        end;
        if f[l] = '  Units used in interface:' then ;// in interface section
        if f[l] = '  Units used in implementation:' then ;// in implementation section
        if f[l].StartsWith('  ==> ') then flag := 1;// add unnecessary item to list
        if f[l].StartsWith('  --> ') then flag := 2;// add move item to list
        //
        if readModule<>currentModule then
        begin
          currentModule := readModule;
          u := TUsesList.Create;
          Self.Add(readModule, u);
        end;

        if flag>0 then
        begin
          var p := Pos(' ', f[l], 7);
          readUnit := f[l].Substring(6, p-7);
          u.Add(TUsesUnit.Create(readUnit, flag));
        end;
      end;
    end;
  finally
    f.Free;
  end;
end;

procedure TModulesDictIntf.runPAL(const projname: string);
var
  CommandLine, ParamLine : string;
begin
  // Not used - just meant as stub for refreshing with IDE
  CommandLine := cPALCMD;
  ParamLine := FPALPAPDir+projname+'.pap ';
  ShellExecute(Application.Handle, 'open', PWideChar(CommandLine), PWideChar(ParamLine), nil, SW_SHOW);
  sleep(300);
  loadData(projname);
end;

{ TUsesList }

function TUsesList.getflag(const unitname: string): byte;
begin
  Result := 0;
  for var unitItem in Self do
  begin
    if SameText(unitItem.UnitName, unitname) then
      Result := unitItem.Unitflag;
  end;
end;

end.
