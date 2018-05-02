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
  TLogin = record
    Username : RawUTF8;
    UserPass : RawUTF8;
    LastLogin : TDateTime;
  end;

  TAUser = class(TSQLRecordTimeStamped)
  private
    fName : RawUTF8;
    fSurname : RawUTF8;
    fAge : Integer;
    fLogin : TLogin;
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

end.
