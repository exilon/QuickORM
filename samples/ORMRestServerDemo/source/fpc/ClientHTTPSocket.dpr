program ClientHTTPSocket;

uses
  Vcl.Forms,
  ClientMain in 'ClientMain.pas' {MainForm},
  Quick.ORM.Form.Login in '..\..\..\..\Quick.ORM.Form.Login.pas' {frmLogin},
  Quick.ORM.Security.GUI in '..\..\..\..\Quick.ORM.Security.GUI.pas',
  Quick.AppSecurity in '..\..\..\..\Quick.AppSecurity.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.Run;
end.
