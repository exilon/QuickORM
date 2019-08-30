unit ORMDemo.Model;

interface

uses
  {$IFDEF NEXTGEN}
  SynCrossPlatformJSON,
  SynCrossPlatformRest,
  {$ELSE}
  mORMot,
  SynCommons,
  {$ENDIF}
  Quick.ORM.Engine;

type
  TLogin = class
  private
    fUsername : RawUTF8;
    fUserPass : RawUTF8;
    fLastLogin : TDateTime;
  published
    property Username : RawUTF8 read fUsername write fUsername;
    property UserPass : RawUTF8 read fUserPass write fUserPass;
    property LastLogin : TDateTime read fLastLogin write fLastLogin;
  end;

  { TAUser }

  TAUser = class(TSQLRecordTimeStamped)
  private
    fName : RawUTF8;
    fSurname : RawUTF8;
    fAge : Integer;
    fLogin : TLogin;
  public
    constructor Create; override;
  published
    property Name : RawUTF8 read fName write fName;
    property Surname : RawUTF8 read fSurname write fSurname;
    property Age : Integer read fAge write fAge;
    property Login : TLogin read fLogin write fLogin;
  end;

  TAGroup = class(TSQLRecord)
  private
    fName : RawUTF8;
    fAllowNewUsers : Boolean;
  published
    property Name : RawUTF8 read fName write fName;
    property AllowNewUsers : Boolean read fAllowNewUsers write fAllowNewUsers;
  end;

implementation

{ TAUser }

constructor TAUser.Create;
begin
  inherited;
  fLogin := TLogin.Create;
end;

end.
