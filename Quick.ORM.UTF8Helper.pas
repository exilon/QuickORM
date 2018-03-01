{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.UTF8Helper
  Description : Helper functions for SynCommons RawUT8 type
  Author      : Kike Pérez
  Version     : 1.1
  Created     : 18/07/2017
  Modified    : 21/07/2017

  This file is part of QuickORM: https://github.com/exilon/QuickORM

  Uses Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez
       Synopse Informatique - https://synopse.info

 ***************************************************************************

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 *************************************************************************** }

unit Quick.UTF8Helper;

{$I Synopse.inc}

interface

uses
  Classes,
  System.SysUtils,
  SynCommons;

type
  TRawUTF8Helper = record helper for RawUTF8
  private
    function GetChars(Index: Integer): AnsiChar;
    function GetLength: Integer; inline;
    function GetCharCount: Integer; inline;
    class function EndsText(const ASubText, AText: RawUTF8) : Boolean; static;
    function IndexOfAny(const AnyOf: array of AnsiChar): Integer; overload;
    function IndexOfAny(const AnyOf: array of AnsiChar; StartIndex: Integer): Integer; overload;
    function IndexOfAny(const AnyOf: array of AnsiChar; StartIndex: Integer; Count: Integer): Integer; overload;
  public
    property Length : Integer read GetLength;
    property CharCount : Integer read GetCharCount;
    function ToBoolean : Boolean; inline;
    function ToInteger : Integer; inline;
    function ToInt64 : Int64; inline;
    function ToSingle : Single; inline;
    function ToDouble : Double; inline;
    function ToExtended : Extended; inline;
    function ToString : string;
    function ToLower : RawUTF8;
    function ToUpper : RawUTF8;
    function Capitalize : RawUTF8;
    function CapitalizeAll : RawUTF8;
    function Contains(const Value: RawUTF8; IgnoreCase : Boolean = False): Boolean;
    function IsEmpty: Boolean;
    function StartsWith(const Value: RawUTF8; IgnoreCase: Boolean = False) : Boolean;
    function EndsWith(const Value: RawUTF8; IgnoreCase: Boolean = False) : Boolean;
    function Replace(OldChar: Char; NewChar: Char): RawUTF8;
    procedure LoadFromFile(const aFilename : TFileName);
    function Substring(StartIndex: Integer): RawUTF8; overload; inline;
    function Substring(StartIndex: Integer; Length: Integer): RawUTF8; overload; inline;
    function Split(const Separator: array of AnsiChar) : TArray<RawUTF8>;
    property Chars[Index: Integer]: AnsiChar read GetChars;
    function Trim: RawUTF8; overload;
    function TrimLeft: RawUTF8; overload;
    function TrimRight: RawUTF8; overload;
  end;

implementation

{TRawUTF8Helper}

{$ZEROBASEDSTRINGS ON}

function TRawUTF8Helper.GetChars(Index: Integer): AnsiChar;
begin
  Result := Self[Index];
end;

function TRawUTF8Helper.GetLength : Integer;
begin
  Result := System.Length(Self);
end;

function TRawUTF8Helper.GetCharCount : Integer;
begin
  Result := System.Length(Self.ToString);
end;

function TRawUTF8Helper.ToBoolean : Boolean;
begin
  Result := StrToBool(Self);
end;

function TRawUTF8Helper.ToInteger : Integer;
begin
  Result := UTF8ToInteger(Self);
end;

function TRawUTF8Helper.ToInt64 : Int64;
begin
  Result := UTF8ToInt64(Self);
end;

function TRawUTF8Helper.ToSingle : Single;
begin
  Result := Single.Parse(Self);
end;

function TRawUTF8Helper.ToDouble : Double;
begin
  Result := Double.Parse(Self);
end;

function TRawUTF8Helper.ToExtended : Extended;
begin
  Result := Extended.Parse(Self);
end;

function TRawUTF8Helper.ToString : string;
begin
  Result := UTF8ToString(Self);
end;

function TRawUTF8Helper.ToLower : RawUTF8;
begin
  Result := AnsiLowerCase(Self);
end;

function TRawUTF8Helper.ToUpper : RawUTF8;
begin
  Result := AnsiUpperCase(Self);
end;

function TRawUTF8Helper.Capitalize : RawUTF8;
var
  s : string;
begin
  Result := '';
  if Self.Length = 0 then Exit;
  s := Self.ToLower;
  Result := AnsiUpperCase(Copy(s, 1, 1)) + (Copy(s, 2, s.Length)).Trim;
end;

function TRawUTF8Helper.CapitalizeAll : RawUTF8;
var
  cword : RawUTF8;
begin
  Result := '';
  if Self.Length = 0 then Exit;
  for cword in Self.Split([' ']) do
  begin
    if Result = '' then Result := cword.Capitalize
      else Result := Result + ' ' + cword.Capitalize;
  end;
end;

function TRawUTF8Helper.Contains(const Value: RawUTF8; IgnoreCase : Boolean = False): Boolean;
begin
  if IgnoreCase then Result := PosEx(Value.ToLower, Self.ToLower, 1) > 0
    else Result := PosEx(Value, Self, 1) > 0;
end;

function TRawUTF8Helper.IsEmpty: Boolean;
begin
  Result := Self = '';
end;

function TRawUTF8Helper.StartsWith(const Value: RawUTF8; IgnoreCase: Boolean = False): Boolean;
var
  s,v : string;
begin
  if Value = '' then
    Result := True
  else
  begin
    s := Self.ToString;
    v := Value.ToString;
    if not IgnoreCase then
    begin
      Result := System.SysUtils.StrLComp(PChar(s), PChar(v), v.Length) = 0;
    end
    else
    begin
      Result := AnsiStrIComp(PChar(v),PChar(Copy(s,1,v.Length))) = 0;
      //Result := System.SysUtils.StrLIComp(PChar(Self.ToString), PChar(Value), Value.Length) = 0;
    end;
  end;
end;

class function TRawUTF8Helper.EndsText(const ASubText, AText: RawUTF8): Boolean;
var
  SubTextLocation: Integer;
  t, s : string;
begin
  if ASubText = '' then
    Result := True
  else
  begin
    t := AText.ToString;
    s := ASubText.ToString;
    SubTextLocation := t.Length - s.Length;
    if (SubTextLocation >= 0) and (ByteType(t, SubTextLocation) <> mbTrailByte) then
      Result := AnsiStrIComp(PChar(s), PChar(@t[SubTextLocation])) = 0
    else
      Result := False;
  end;
end;

function TRawUTF8Helper.EndsWith(const Value: RawUTF8; IgnoreCase: Boolean = False): Boolean;
var
  SubTextLocation: Integer;
  v : string;
begin
  if IgnoreCase then
    Result := EndsText(Value, Self)
  else
  if Value = '' then
    Result := True
  else
  begin
    v := Value.ToString;
    SubTextLocation := Self.CharCount - v.Length;
    if (SubTextLocation >= 0) and (ByteType(Self, SubTextLocation) <> mbTrailByte) then
      Result := string.Compare(v, 0, Self, SubTextLocation, v.Length, []) = 0
    else
      Result := False;
  end;
end;

function TRawUTF8Helper.Replace(OldChar: Char; NewChar: Char): RawUTF8;
begin
  Result := StringReplaceAll(Self,StringToUTF8(OldChar),StringToUTF8(NewChar));
end;

procedure TRawUTF8Helper.LoadFromFile(const aFilename : TFileName);
begin
  Self := AnyTextFileToRawUTF8(Self,True);
end;

function TRawUTF8Helper.Substring(StartIndex: Integer): RawUTF8;
begin
  Result := System.Copy(Self, StartIndex + 1, Self.Length);
end;

function TRawUTF8Helper.Substring(StartIndex, Length: Integer): RawUTF8;
begin
  Result := System.Copy(Self, StartIndex + 1, Length);
end;

function TRawUTF8Helper.IndexOfAny(const AnyOf: array of AnsiChar; StartIndex, Count: Integer): Integer;
var
  i: Integer;
  c: AnsiChar;
  max: Integer;
begin
  if (StartIndex + Count) >= Self.Length then
    max := Self.Length
    else max := StartIndex + Count;

  i := StartIndex;
  while i < max do
  begin
    for c in AnyOf do
      if Self[i] = c then Exit(i);
    Inc(i);
  end;
  Result := -1;
end;

function TRawUTF8Helper.IndexOfAny(const AnyOf: array of AnsiChar; StartIndex: Integer): Integer;
begin
  Result := IndexOfAny(AnyOf, StartIndex, Self.Length);
end;

function TRawUTF8Helper.IndexOfAny(const AnyOf: array of AnsiChar): Integer;
begin
  Result := IndexOfAny(AnyOf, 0, Self.Length);
end;

function TRawUTF8Helper.Split(const Separator: array of AnsiChar) : TArray<RawUTF8>;
const
  DeltaGrow = 32;
var
  NextSeparator, LastIndex: Integer;
  Total: Integer;
  CurrentLength: Integer;
  S: RawUTF8;
begin
  Total := 0;
  LastIndex := 0;
  CurrentLength := 0;
  NextSeparator := IndexOfAny(Separator, LastIndex);
  while (NextSeparator >= 0) do
  begin
    S := Substring(LastIndex, NextSeparator - LastIndex);
    if (S <> '') or ((S = '')) then
    begin
      Inc(Total);
      if CurrentLength < Total then
      begin
        CurrentLength := Total + DeltaGrow;
        SetLength(Result, CurrentLength);
      end;
      Result[Total - 1] := S;
    end;

    LastIndex := NextSeparator + 1;
    NextSeparator := IndexOfAny(Separator, LastIndex);
  end;

  if (LastIndex < Self.Length) then
  begin
    Inc(Total);
    SetLength(Result, Total);
    Result[Total - 1] := Substring(LastIndex, Self.Length - LastIndex);
  end
  else SetLength(Result, Total);
end;

function TRawUTF8Helper.Trim: RawUTF8;
var
  I, L: Integer;
begin
  L := Self.Length - 1;
  I := 0;
  if (L > -1) and (Self[I] > ' ') and (Self[L] > ' ') then Exit(Self);
  while (I <= L) and (Self[I] <= ' ') do Inc(I);
  if I > L then Exit('');
  while Self[L] <= ' ' do Dec(L);
  Result := Self.SubString(I, L - I + 1);
end;

function TRawUTF8Helper.TrimLeft: RawUTF8;
var
  I, L: Integer;
begin
  L := Self.Length - 1;
  I := 0;
  while (I <= L) and (Self[I] <= ' ') do Inc(I);
  if I > 0 then
    Result := Self.SubString(I)
  else
    Result := Self;
end;

function TRawUTF8Helper.TrimRight: RawUTF8;
var
  I: Integer;
begin
  I := Self.Length - 1;
  if (I >= 0) and (Self[I] > ' ') then Result := Self
  else begin
    while (I >= 0) and (Self.Chars[I] <= ' ') do Dec(I);
    Result := Self.SubString(0, I + 1);
  end;
end;



end.
