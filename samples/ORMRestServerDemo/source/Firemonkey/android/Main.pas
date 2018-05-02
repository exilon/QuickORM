unit Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Edit,
  System.Generics.Collections,
  SynCrossPlatformRest,
  Quick.Commons,
  Quick.ORM.Engine,
  Quick.ORM.RestClient.Cross,
  ORMDemo.Model,
  ORMDemo.Interf; //unit contains interface for rest methods;

type
  TForm1 = class(TForm)
    meInfo: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    edHost: TEdit;
    btnConnect: TButton;
    btnRandom: TButton;
    btnGetUsers: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnGetUsersClick(Sender: TObject);
    procedure GetUsers;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  RestClient : TORMRestClient;
  RestFunc : IServiceMethods;

implementation

{$R *.fmx}

procedure TForm1.btnConnectClick(Sender: TObject);
var
  done : Boolean;
begin
  RestClient.Host := edHost.Text;
  done := RestClient.Connect;
  if done then meInfo.Lines.Add('Connected to RestServer!')
  else
  begin
    meInfo.Lines.Add('Can''t connect to Restserver!');
    Exit;
  end;
end;

procedure TForm1.btnGetUsersClick(Sender: TObject);
begin
  GetUsers;
end;

procedure TForm1.GetUsers;
var
  User : TAUser;
begin
  User := TAUser.CreateAndFillPrepare(RestClient.ORM,'','',[]);
  try
    if User = nil then
    begin
      meInfo.Lines.Add('No results found!');
      Exit;
    end;
    while User.FillOne do
    begin
      meInfo.Lines.Add(Format('%s / %d year(s) / LastLogin: %s',[User.Name,User.Age,DateTimeToStr(User.Login.LastLogin)]));
    end;
  finally
    User.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  RestClient := TORMRestClient.Create;
  RestClient.Host := '192.168.1.107';
  RestClient.Port := 8099;
  RestClient.DataBase.IncludedClasses := [TAUser,TAGroup];
  RestClient.Login.UserName := 'Admin';
  RestClient.Login.UserPass := 'exilon';
  RestClient.HTTPOptions.Protocol := TSrvProtocol.spHTTP_Socket;
  RestClient.HTTPOptions.AuthMode := TAuthMode.amDefault;
  RestClient.Service.MethodInterface := IServiceMethods;
  RestClient.Service.InstanceImplementation := sicShared;
  RestClient.Service.Enabled := True;
end;

end.
