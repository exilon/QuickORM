unit ORMDemo.CustomServer;

interface

uses
  Classes,
  mORMot,
  mORMotSQLite3,
  Quick.ORM.RestServer;

type
  TORMServer = class(TCustomORMServer)
  published
    procedure Test(Ctxt: TSQLRestServerURIContext);
    procedure AppActions(Ctxt: TSQLRestServerURIContext);
    procedure List(Ctxt: TSQLRestServerURIContext);
  end;

implementation

procedure TORMServer.Test(Ctxt: TSQLRestServerURIContext);
begin
  Ctxt.Returns('{"Test" : "OK"}',200);
end;

procedure TORMServer.AppActions(Ctxt: TSQLRestServerURIContext);
begin
  Ctxt.Returns('{"AppActions" : "OK"}',200);
end;

procedure TORMServer.List(Ctxt: TSQLRestServerURIContext);
begin
  Ctxt.Returns('{"List" : "OK"}',200);
end;

end.
