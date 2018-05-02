unit ORMDemo.RestMethods;

interface

uses
  mORMot,
  ORMDemo.Interf;

type

  TServiceMethods = class(TInjectableObject,IServiceMethods)
  public
    function Sum(val1, val2 : Double) : Double;
    function Mult(val1, val2 : Double) : Double;
    function RandomNumber : Int64;
  end;

implementation

function TServiceMethods.Sum(val1, val2 : Double) : Double;
begin
  Result := val1 + val2;
end;

function TServiceMethods.Mult(val1: Double; val2: Double) : Double;
begin
  Result := val1 * val2;
end;

function TServiceMethods.RandomNumber : Int64;
begin
  Result := Random(999999999);
end;

end.
