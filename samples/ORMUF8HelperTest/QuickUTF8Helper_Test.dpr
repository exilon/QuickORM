program QuickUTF8Helper_Test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  SynCommons,
  Quick.Log,
  Quick.Console,
  Quick.Commons,
  Quick.UTF8Helper;

var
  R : RawUTF8;
  S : string;
  done : Boolean;
  auxR : RawUTF8;
  auxS : string;

const
  TESTPHRASE = 'Ángel, Águila, Título, Amigo, ágora, Estás?';
  TESTPHRASE2 = 'uno, dos, tres, cuatro á cinco á seis y siete';

procedure Check(const Test : string; B1, B2 : Boolean);
begin
  if B1 = B2 then coutFmt('%s [Good=%s / Real=%s]',[Test,BoolToStr(B1,True),BoolToStr(B2,True)],etSuccess)
    else coutFmt('%s [Good=%s / Real=%s]',[Test,BoolToStr(B1,True),BoolToStr(B2,True)],etError);
end;

begin
  Console.LogVerbose := LOG_DEBUG;
  R := TESTPHRASE;
  S := TESTPHRASE;
  cout(R,etDebug);
  //STRING: StartsWith Test
  cout('//STRING: StartsWith Test',etInfo);

  done := S.StartsWith('ángel',False);
  Check('1. StartsWith(''ángel'',CaseSensitive)',False,done);

  done := S.StartsWith('Ángel',False);
  Check('2. StartsWith(''Ángel'',CaseSensitive)',True,done);

  done := S.StartsWith('ángel',True);
  Check('3. StartsWith(''ángel'',IgnoreCase)',True,done);

  done := S.StartsWith('Ángel',True);
  Check('4. StartsWith(''Ángel'',IgnoreCase)',True,done);

  //RAWUTF8: StartsWith Test
  cout('//RAWUTF8: StartsWith Test',etInfo);

  done := R.StartsWith('ángel',False);
  Check('1. StartsWith(''ángel'',CaseSensitive)',False,done);

  done := R.StartsWith('Ángel',False);
  Check('2. StartsWith(''Ángel'',CaseSensitive)',True,done);

  done := R.StartsWith('ángel',True);
  Check('3. StartsWith(''ángel'',IgnoreCase)',True,done);

  done := R.StartsWith('Ángel',True);
  Check('4. StartsWith(''Ángel'',IgnoreCase)',True,done);

  //STRING: EndsWith Test
  cout('//STRING: EndsWith Test',etInfo);

  done := S.EndsWith('tás?',False);
  Check('1. EndsWith(''tás?'',CaseSensitive)',True,done);

  done := S.EndsWith('TÁS?',False);
  Check('2. EndsWith(''TÁS?'',CaseSensitive)',False,done);

  done := S.EndsWith('tás?',True);
  Check('3. EndsWith(''tás?'',IgnoreCase)',True,done);

  done := S.EndsWith('TÁS?',True);
  Check('4. EndsWith(''TÁS?'',IgnoreCase)',True,done);

  //RAWUTF8: EndsWith Test
  cout('//RAWUTF8: EndsWith Test',etInfo);

  done := R.EndsWith('tás?',False);
  Check('1. EndsWith(''tás?'',CaseSensitive)',True,done);

  done := R.EndsWith('TÁS?',False);
  Check('2. EndsWith(''TÁS?'',CaseSensitive)',False,done);

  done := R.EndsWith('tás?',True);
  Check('3. EndsWith(''tás?'',IgnoreCase)',True,done);

  done := R.EndsWith('TÁS?',True);
  Check('4. EndsWith(''TÁS?'',IgnoreCase)',True,done);

  //STRING: Contains Test
  cout('//STRING: Contains Test',etInfo);
  done := S.Contains('tás?');
  Check('1. Contains(''tás?'',CaseSensitive)',True,done);

  done := S.Contains('TÁS?');
  Check('2. Contains(''TÁS?'',CaseSensitive)',False,done);

  done := S.Contains('TÁS?');
  Check('3. Contains(''TÁS?'',IgnoreCase) [not implemented]',False,done);

  //RAWUTF8: Contains Test
  cout('//RAWUTF8: Contains Test',etInfo);
  done := R.Contains('tás?',False);
  Check('1. Contains(''tás?'',CaseSensitive)',True,done);

  done := R.Contains('TÁS?',False);
  Check('2. Contains(''TÁS?'',CaseSensitive)',False,done);

  done := R.Contains('TÍTULO',True);
  Check('3. Contains(''TÍTULO'',IgnoreCase)',True,done);

  //STRING: Uppercase Test
  cout('//STRING: Uppercase Test',etInfo);
  cout(S.ToUpper,etWarning);

  //RAWUTF8: Uppercase Test
  cout('//RAWUTF8: Uppercase Test',etInfo);
  cout(R.ToUpper,etWarning);

  //STRING: LowerCase Test
  cout('//STRING: LowerCase Test',etInfo);
  cout(S.ToLower,etWarning);

  //RAWUTF8: LowerCase Test
  cout('//RAWUTF8: LowerCase Test',etInfo);
  cout(R.ToLower,etWarning);

  R := TESTPHRASE;
  S := TESTPHRASE;
  //STRING: CapitalizeAll Test
  cout('//STRING: CapitalizeAll Test',etInfo);
  cout(CapitalizeWords(S),etWarning);

  //RAWUTF8: CapitalizeAll Test
  cout('//RAWUTF8: CapitalizeAll Test',etInfo);
  cout(R.CapitalizeAll,etWarning);

  R := TESTPHRASE2;
  S := TESTPHRASE2;
  //STRING: Split Test
  cout('//STRING: Split Test',etInfo);
  cout(S,etDebug);
  for auxS in S.Split([',','y','á']) do
  begin
    cout(auxS.Trim,etWarning);
  end;

  //RAWUTF8: Split Test
  cout('//RAWUTF8: Split Test',etInfo);
  cout(R,etDebug);
  for auxR in R.Split([',','y','á']) do
  begin
    cout(auxR.Trim,etWarning);
  end;


  ConsoleWaitForEnterKey;
end.
