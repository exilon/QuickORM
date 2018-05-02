program MobileHTTPRestClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {Form1},
  Quick.ORM.RestClient.Cross in '..\..\..\..\Quick.ORM.RestClient.Cross.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
