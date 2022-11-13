unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,  FMX.Utils,
  System.Math, System.Threading;

const
  NUM_OF_AGENTS = 65000;

type
  TAntObj = Record
    x,y:Single;
    direction:Single;
    Gcolor:Byte;
  End;
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
  public
    { Public declarations }
    BaseBitmap:TBitmap;
    Ants:Array[1..NUM_OF_AGENTS] of TAntObj;
    speed:Single;
    alpha_param:byte;
    stillmove:boolean;
    mode:byte;
    settings_angle:Single;
    function Sense(Ant:TAntObj;AngleOffset:Single;Data: TBitmapData):Byte;
    procedure AgentMove(i:Integer;Data:TBitmapData;alpha_param:byte;w,h:Integer);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
function TForm1.Sense(Ant:TAntObj;AngleOffset:Single;Data: TBitmapData):Byte;
var
  Angle:Single;
  newPosX,newPosY:Single;
begin
  Angle:=Ant.direction + AngleOffset;
  newPosX:=Ant.x+sin(Angle)*(speed+2);
  newPosY:=Ant.y+cos(Angle)*(speed+2);
  if newPosX>BaseBitmap.Width-1 then newPosX:=0;
  if newPosX<0 then newPosX:=BaseBitmap.Width-1;
  if newPosY>BaseBitmap.Height-1 then newPosY:=0;
  if newPosY<0 then newPosY:=BaseBitmap.Height-1;
Result := TAlphaColorRec(Data.GetPixel(Round(newPosX),Round(newPosY))).R;
//if Result>100 then Result:=Result-(Result-100)*2;
if (Result<10) and (mode = 1) then Result:=50;
if (Result>100) and (mode = 1) then Result:=0;
if (Ant.x>Ants[1].x-50) and (Ant.x<Ants[1].x+50) and (Ant.y>Ants[1].y-50) and (Ant.y<Ants[1].y+50)
                        and(ant.x <> Ants[1].x)and(ant.y <> Ants[1].y) then result:=0;
if (Result>100) and (mode = 2) then Result:=Result-(Result-100)*2;
//if (Result<10) and (mode = 4) then Result:=TAlphaColorRec(Data.GetPixel(Round(newPosX),Round(newPosY))).B;
if mode = 3 then Result:=(Result*Random(100)) div 100;
end;

function ARGBtoColorChannels(A, R, G, B: Byte):TAlphaColor;
var rec:TAlphaColorRec;
begin
rec.A:=A;
rec.R:=R;
rec.G:=G;
rec.B:=B;
Result:=TAlphaColor(rec);
end;

type
  PIntArray = ^TIntArray;
  TIntArray = array [0 .. 0] of Integer;

procedure Diffuse(Data: TBitmapData;w,h:Integer);
var
  pix: PAlphaColorArray;
  offsetX,offsetY,sampleX,sampleY:Integer;
  x,y,sum:integer;
  R,B:PIntArray;
begin
GetMem(R,w * h * SizeOf(Integer));
GetMem(B,w * h * SizeOf(Integer));

TParallel.&For(0,w*h-1,
  procedure(i:Integer)
  var
    offsetX,offsetY,sampleX,sampleY:Integer;
    x,y,sum, sumB:integer;
  begin
    y:=i div w;
    x:=i mod w;
    sum:=0;
    sumB:=0;
    for offsetX := -1 to 1 do begin
      for offsetY := -1 to 1 do begin
        SampleX := min(w-1,max(0,x+offsetX));
        SampleY := min(h-1,max(0,y+offsetY));
        sum:=sum+TAlphaColorRec(Data.GetPixel(SampleX,SampleY)).R;
        sumB:=sumB+TAlphaColorRec(Data.GetPixel(SampleX,SampleY)).B;
        end;
      end;
    R[i]:=sum div 9;
    B[i]:=sumB div 9;
    if R[i]>0 then R[i]:=R[i]-1;
    if B[i]>0 then B[i]:=B[i]-1;
  end);
TParallel.&For(0,w*h-1,
  procedure(i:Integer)
  begin
    Data.SetPixel(i mod w,i div w,ARGBtoColorChannels(180,R[i],0,B[i]));
  end);
FreeMem(R,w * h * SizeOf(Integer));
FreeMem(B,w * h * SizeOf(Integer));
end;


procedure TForm1.AgentMove(i:Integer;Data:TBitmapData;alpha_param:byte;w,h:Integer);
var
  weights:array[1..3] of Byte;
  r:byte;
begin
weights[1]:=Sense(ants[i],settings_angle,Data);
weights[2]:=Sense(ants[i],0,Data);
weights[3]:=Sense(ants[i],-settings_angle,Data);
r:=TAlphaColorRec(Data.GetPixel(Round(Ants[i].x),Round(Ants[i].y))).R;
r:=r+20;
if r>200 then r:=200;
Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,Ants[i].Gcolor,Ants[i].Gcolor div 2 + 128));
if i = 1 then
  Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(255,255,255,255));

if (weights[2]>weights[1]) and (weights[2]>weights[3]) then begin
  //Ants[i].direction:=Ants[i].direction;
  //Ants[i].direction:=Ants[i].direction+random*0.264-0.132;
  //Ants[i].direction:=Ants[i].direction+random(3)*0.6-0.3;
end else if (weights[2]<weights[1]) and (weights[2]<weights[3]) then begin
  //Ants[i].direction:=Ants[i].direction+random*0.6-0.3;
  Ants[i].direction:=Ants[i].direction+random(3)*settings_angle-settings_angle;
end else if weights[3]>weights[1] then begin
  Ants[i].direction:=Ants[i].direction-settings_angle;
end else if weights[3]<weights[1] then begin
  Ants[i].direction:=Ants[i].direction+settings_angle;
end else Ants[i].direction:=Ants[i].direction+random(3)*0.2-0.2;

if Ants[i].direction>2*pi then Ants[i].direction:=Ants[i].direction-2*pi;
if Ants[i].direction<0 then Ants[i].direction:=Ants[i].direction+2*pi;

if stillmove then begin
  Ants[i].x:=Ants[i].x+sin(Ants[i].direction)*speed;
  Ants[i].y:=Ants[i].y+cos(Ants[i].direction)*speed;
  end;

if Ants[i].x>w-1 then Ants[i].x:=0;
if Ants[i].x<0 then Ants[i].x:=w-1;
if Ants[i].y>h-1 then Ants[i].y:=0;
if Ants[i].y<0 then Ants[i].y:=h-1;
//Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,Ants[i].Gcolor,255));
if i = 1 then
  Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(255,255,255,255));
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  bmp:TBitmap;
  Data: TBitmapData;
  i:Integer;
begin
bmp:= BaseBitmap;
//Blur(nil,bmp,1);
//if Timer1.Tag = 1 then Blur(nil,bmp,2);
//Timer1.Tag := (Timer1.Tag+1)mod 2;

bmp.Map(TMapAccess.ReadWrite, Data);
Diffuse(Data,bmp.Width,bmp.Height);
//NUM_OF_AGENTS
TParallel.&For(1,NUM_OF_AGENTS,
  procedure(i:Integer)
  begin
    AgentMove(i,Data,alpha_param,bmp.Width,bmp.Height);
  end);
bmp.Unmap(Data);
Canvas.BeginScene();
Canvas.DrawBitmap(bmp,RectF(0,0,bmp.Width,bmp.Height),RectF(0,0,Canvas.Width,Canvas.Height),1);
Canvas.EndScene;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
BaseBitmap.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i:word;
begin
speed:=1.7;
settings_angle:=0.3;
alpha_param:=180;
stillmove:=true;
mode:=0;
BaseBitmap:=TBitmap.Create(Canvas.Width ,Canvas.Height );
for i := 1 to NUM_OF_AGENTS do begin
//  Ants[i].x:=Random(BaseBitmap.Width);
//  Ants[i].y:=Random(BaseBitmap.Height);
  Ants[i].direction:=i*2*pi/NUM_OF_AGENTS;
  Ants[i].x:=320+sin(Ants[i].direction)*20;
  Ants[i].y:=240+cos(Ants[i].direction)*20;
  Ants[i].Gcolor:=Random(100)+50;
  end;
BaseBitmap.Canvas.BeginScene;
BaseBitmap.Canvas.Clear($FF000000);
BaseBitmap.Canvas.EndScene;
end;


procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
if KeyChar = '1' then begin
  beep;
  Timer1.Enabled:= not Timer1.Enabled;
  end;
if KeyChar = 'w' then
  alpha_param:=alpha_param+10;
if KeyChar = 's' then
  alpha_param:=alpha_param-10;
if KeyChar = ' ' then stillmove:=not stillmove;
if KeyChar = 'm' then begin
  mode:=(mode+1) mod 4;
  Caption:='Mode: '+IntToStr(mode);
  end;
if KeyChar = '-' then begin
  settings_angle:=settings_angle-0.02;
  Caption:='settings_angle: '+FloatToStr(settings_angle);
  end;
if KeyChar = '+' then begin
  settings_angle:=settings_angle+0.02;
  Caption:='settings_angle: '+FloatToStr(settings_angle);
  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var dx,dy:Integer;
begin
if Button = TMouseButton.mbLeft then begin
  BaseBitmap.Canvas.BeginScene;
  BaseBitmap.Canvas.Fill.Color:=$FF000000;
  dx:=Round(BaseBitmap.Width*x/canvas.Width);
  dy:=Round(BaseBitmap.Height*y/canvas.Height);
  BaseBitmap.Canvas.FillEllipse(RectF(dx-50,dy-50,dx+50,dy+50),1);
  BaseBitmap.Canvas.EndScene;
  end;
end;

end.
