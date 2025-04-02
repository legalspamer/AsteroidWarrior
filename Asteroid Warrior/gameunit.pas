unit gameunit;
uses wpfobjects, sounds;

type background = class (PictureWPF)
procedure scroll;
begin
  move;
  if right <= window.width then left := window.width-1920;//условие для зацикливаннея фона
end;
end;

type session=class
  
end;

type PObj=class 
  E,P:real;
  VX,VY:REAL;
end;


type
  AsteroidT = CircleWPF;
  ExplosionT = CircleWPF;
  GameObjT = PictureWPF;

type
   SpeedVectorT = auto class
    X, Y: real;
    Draw:LineWPF;
    DrawCenter:CircleWPF;
    constructor create(X,Y:real);
    begin
      Draw := new LineWPF(100, 100, 100, 100, colors.White);
      Draw.ToFront;
      DrawCenter:=new CircleWPF(100, 100, 3, colors.White);
      DrawCenter.ToFront;
    end;
  end;
  
end.