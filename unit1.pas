unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, DBCtrls, DBGrids, uSolver, dbf, DB, Model, LazUTF8;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    DataSource1: TDataSource;
    Dbf1: TDbf;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    poisk: TEdit;
    ploshadbatarei: TEdit;
    kolvoball: TEdit;
    Label24: TLabel;
    Label25: TLabel;
    otnmassSPH: TEdit;
    Label23: TLabel;
    PageControl1: TPageControl;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    udmasskotsr: TEdit;
    Label22: TLabel;
    otnmassDY: TEdit;
    Label21: TLabel;
    udmassDY: TEdit;
    Label20: TLabel;
    udmassEY: TEdit;
    energKPD: TEdit;
    Label18: TLabel;
    Label19: TLabel;
    tyagKPD: TEdit;
    Label17: TLabel;
    Moshnost: TEdit;
    Label16: TLabel;
    tyaga: TEdit;
    Label15: TLabel;
    startmass: TEdit;
    exckon: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    radiuskon: TEdit;
    naklkon: TEdit;
    exc0: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label9: TLabel;
    radius0: TEdit;
    nakl0: TEdit;
    ScorostIst: TEdit;
    MotorVr: TEdit;
    MassaPN: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure poiskChange(Sender: TObject);
    procedure Dbf1FilterRecord(DataSet: TDataSet; var Accept: Boolean);

  private
    /// заполняет таблицу всеми записями
    procedure PopulateDB;

  public

  end;

var
  Form1: TForm1;
  param: TMTAParam;
  DYParam: TTaskParam;
  r0: real;
  rk: real;
  i0: real;
  ik: real;
  Tm: real;
  mpn:real;
  rate : real;
  M0: real;
  AlphaEY:real;
  GammaDY:real;
  GammaK:real;
  GammaSPX:real;
  NuT:real;
  NuEY:real;
  bal: integer;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Путь к файлу
  Dbf1.FilePath     := ExtractFilePath(Application.ExeName);
  Dbf1.FilePathFull := Dbf1.FilePath;

  // Если файла нет — создаём схему и наполняем сразу
  if not FileExists('engines.dbf') then
  begin
    with Dbf1.FieldDefs do
    begin
      Add('ID',          ftAutoInc,  0, True);
      Add('NAME',        ftString,   32, True);
      Add('THRUST_MN',   ftString,   16, True);
      Add('ISP_KMPS',    ftString,   16, True);
      Add('POWER_KW',    ftString,   16, True);
      Add('EFF_PERCENT', ftString,    8, True);
      Add('RESOURCE_H',  ftString,   16, True);
    end;
    Dbf1.CreateTable;
    Dbf1.Open;
    PopulateDB;
  end
  else
    Dbf1.Open;

  // Привязываем фильтрацию
  Dbf1.OnFilterRecord := @Dbf1FilterRecord;
end;

// Заполняем DBF всеми строками (имя;тяга;ISP;мощность;КПД;ресурс)
procedure TForm1.PopulateDB;
var
  SL, parts: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  parts := TStringList.Create;
  try
    // Разбор по «;» без учёта пробелов
    parts.Delimiter := ';';
    parts.StrictDelimiter := True;

    // --- Таблица 1.1: основные ионные двигатели ---
    SL.Add('XIPS-13;18;23,5;0,45;50;12000');
    SL.Add('XIPS-25;79-165;35;2,0-4,2;70;');
    SL.Add('XIPS-30;92;32,5;2,4;;');
    SL.Add('NSTAR;19-92;19,5-32,8;0,49-2,3;38-64;>10000');
    SL.Add('NEXT;237;>41;6,9;>70;');
    SL.Add('NEXIS;60-90;25;;;');
    SL.Add('HiPEP;590-450;60-80;23,5;74;');

    // --- Таблица 1.2: стационарные плазменные двигатели ---
    SL.Add('СПД-25;7;8-10;0,1;20;1200');
    SL.Add('СПД-35;10;12;0,2;30;2500');
    SL.Add('СПД-50;20;12,5;0,35;35;2250');
    SL.Add('СПД-60;30;13;0,5;37;2500');
    SL.Add('СПД-70;40;14,5;0,65;44;3100');
    SL.Add('СПД-100(100Д);83/70;15/27,5;1,35/2;50;9000');
    SL.Add('СПД-1350(PPS-1350);88;>=17,2;1,5;52;7000');
    SL.Add('СПД-140;280/170;17/28;4,5;55;8200');
    SL.Add('СПД-200;185-488;17,56;3-0,11;50-63;18000');
    SL.Add('СПД-290;до1500;15-30;5,0-30,0;65;27000');

    // --- Таблица 1.4 (продолжение): ВНТ, BPT, T-220 ---
    SL.Add('BHT-200;11;13,5;0,2;>=37;2000');
    SL.Add('BHT-600;36;17;0,6;>=51;6000');
    SL.Add('BHT-1000;55;18,7;0,9;53;6000');
    SL.Add('BHT-8000;512;12-35;8;63;6000');
    SL.Add('BPT-2000;98;17;2;49;>6000');
    SL.Add('BPT-4000;187-161;16,89-18,8;3;50;>6000');
    SL.Add('T-220;>500;24,5;10;59;');

    // --- Таблица 1.3: экспериментальные образцы ---
    SL.Add('Д-38/Д-38М;25-100;13-28;0,2-1,5;50-70;');
    SL.Add('Д-60;35-140;12-30;0,4-2,2;40-55;');
    SL.Add('Д-80(двухступ.);45-240;12-33,5;0,6-5,6;40-70;');
    SL.Add('Д-90-I(одност.);260;5,0-6;3,5;50-65;');
    SL.Add('Д-90-II(двухступ.);150;8,5;4,0;55;');
    SL.Add('Д-100-I(одност.);80-340;14,5-28;1,3-7,5;40-60;');
    SL.Add('Д-100-II(двухступ.);80-650;18-42,5;3,5-15;50-65;');
    SL.Add('TM-50(двухступ.);1000-1500;30-70;20-50;50-65;');
    SL.Add('VINITAL-160;618;76,67;36;63;');

    // И наконец — пушим всё в DBF
    for i := 0 to SL.Count - 1 do
    begin
      parts.DelimitedText := SL[i];
      if parts.Count < 5 then Continue;  // мало данных
      Dbf1.Append;
      Dbf1.FieldByName('NAME').AsString      := parts[0];
      Dbf1.FieldByName('THRUST_MN').AsString := parts[1];
      Dbf1.FieldByName('ISP_KMPS').AsString  := parts[2];
      Dbf1.FieldByName('POWER_KW').AsString  := parts[3];
      Dbf1.FieldByName('EFF_PERCENT').AsString := parts[4];
      // если есть ресурс — ставим, иначе оставляем пустым
      if parts.Count >= 6 then
        Dbf1.FieldByName('RESOURCE_H').AsString := parts[5]
      else
        Dbf1.FieldByName('RESOURCE_H').Clear;
      Dbf1.Post;
    end;
  finally
    parts.Free;
    SL.Free;
  end;
end;

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
 Dbf1.Filtered:=(Sender as TCheckBox).Checked;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  P, Mpn, M0, a0, c, Tm, copt, i0, e0, r0, ik, ek, rk,
  AlphaEY, GammaDY, GammaK, GammaSPX, NuT, NuEY, bal, SSB: real;
begin
  // 1) Считываем всё в локальные переменные (как было)
  if not TryStrToFloat(MassaPN.Text, Mpn) then begin
    ShowMessage('Неверное значение массы полезной нагрузки');
    Exit;
  end;
  if not TryStrToFloat(MotorVr.Text, Tm) then begin
    ShowMessage('Неверное значение времени полёта');
    Exit;
  end;
  if not TryStrToFloat(ScorostIst.Text, c) then begin
    ShowMessage('Неверное значение скорости истечения');
    Exit;
  end;
  i0 := StrToFloat(nakl0.Text) * Pi/180;
  r0 := StrToFloat(radius0.Text);
  e0 := StrToFloat(exc0.Text);
  ik := StrToFloat(naklkon.Text) * Pi/180;
  rk := StrToFloat(radiuskon.Text);
  ek := StrToFloat(exckon.Text);

  AlphaEY  := StrToFloat(udmassEY.Text);
  GammaDY  := StrToFloat(udmassDY.Text);
  GammaK   := StrToFloat(udmasskotsr.Text);
  GammaSPX := StrToFloat(otnmassSPH.Text);
  NuT      := StrToFloat(tyagKPD.Text);
  NuEY     := StrToFloat(energKPD.Text);
  bal      := StrToFloat(kolvoball.Text);

  // 2) Простые проверки, чтобы не делить на ноль
  if (NuT = 0) or (NuEY = 0) then begin
    ShowMessage('Ошибка: КПД не может быть равным 0.');
    Exit;
  end;
  if c = 0 then begin
    ShowMessage('Ошибка: скорость истечения не может быть равной 0.');
    Exit;
  end;

  // 3) Инициализируем параметры энергоустановки
  param.AlphaEY  := AlphaEY;
  param.GammaDY  := GammaDY;
  param.GammaK   := GammaK;
  param.GammaSPX := GammaSPX;
  param.NuT      := NuT;
  param.NuEY     := NuEY;

  // 4) Подготовка параметров перелёта (не трогаем)
  InitTaskParam(DYParam, r0, i0, rk, ik, Tm, c);

  // 5) Собственно расчёты
  M0   := GetStartMass(param, c, Tm*24*3600, DYParam.Vxk*1000, Mpn);
  P    := GetMTAPower(param, c, M0*DYParam.begin_accel*1000);
  copt := GetRateopt(param, Tm*24*3600);

  // 6) Отображаем результаты
  startmass.Text := FloatToStr(M0);
  Moshnost.Text  := FloatToStr(P);
  exc0.Text      := FloatToStr(copt);
end;

procedure TForm1.poiskChange(Sender: TObject);
begin
  // «Обновляем» фильтрацию
  Dbf1.Filtered := False;
  Dbf1.Filtered := CheckBox1.Checked;
end;



procedure TForm1.Dbf1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
var
  needle, hay: string;
begin
  // Если фильтр выключен — пропускаем всё
  if not CheckBox1.Checked then
  begin
    Accept := True;
    Exit;
  end;

  // Иначе — фильтруем по подстроке (рус/латинница, без учёта регистра)
  needle := UTF8LowerCase(poisk.Text);
  hay    := UTF8LowerCase(DataSet.FieldByName('NAME').AsString);

  // Пустой текст — пускаем всё, иначе ищем вхождение
  Accept := (needle = '') or (Pos(needle, hay) > 0);
end;



end.

