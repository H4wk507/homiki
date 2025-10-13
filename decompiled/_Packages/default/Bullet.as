class Bullet
{
   var ang;
   var bltClip;
   var doRotation;
   var grav;
   var mcBase;
   var mcName;
   var num;
   var ox;
   var oy;
   var shadClip;
   var vel;
   var xpos;
   var xvel;
   var ypos;
   var yvel;
   var hit = false;
   var pi = 3.141593;
   function Bullet(base, x, y, name, velocity, angle, gravity, bNumber)
   {
      this.mcBase = base;
      this.xpos = x;
      this.ypos = y;
      this.mcName = name;
      this.vel = velocity;
      this.ang = angle;
      this.grav = gravity;
      this.num = bNumber != undefined ? bNumber : 1;
      this.doRotation = true;
      this.init();
   }
   function init(Void)
   {
      this.createClip();
      this.setClipPos();
      this.xvel = Math.sin(this.ang) * this.vel;
      this.yvel = (- Math.cos(this.ang)) * this.vel;
   }
   function update()
   {
      this.ox = this.bltClip._x;
      this.oy = this.bltClip._y;
      var _loc2_ = Math.atan2(this.yvel,this.xvel);
      _loc2_ = this.radainsToDegrees(_loc2_);
      if(this.xvel < 7 && this.bltClip._y > 940 || this.doRotation == false)
      {
         _loc2_ = 0;
      }
      this.bltClip._rotation = _loc2_ + 90;
      this.bltClip._x += this.xvel;
      this.bltClip._y += this.yvel;
      this.shadClip._x = this.bltClip._x;
      this.shadClip._y = 963;
      var _loc3_ = 100 * (this.bltClip._y - 700) / 263;
      this.shadClip._xscale = this.shadClip._yscale = _loc3_;
   }
   function increaseGravity(n)
   {
      this.grav = -0.17 * this.xvel;
   }
   function restoreGravity()
   {
      this.grav = 0.99;
   }
   function deleteBlt()
   {
      false;
   }
   function createClip(Void)
   {
      this.bltClip = this.mcBase.attachMovie(this.mcName,"blt" + this.num,this.num);
      this.shadClip = this.mcBase.attachMovie("shadow","shadow_mc",0);
   }
   function setClipPos(Void)
   {
      this.bltClip._x = this.xpos;
      this.bltClip._y = this.ypos;
      this.bltClip._rotation = this.ang;
   }
   function degreesToRadians(degrees)
   {
      var _loc2_ = degrees * this.pi / 180;
      return _loc2_;
   }
   function radainsToDegrees(radians)
   {
      var _loc2_ = radians * 180 / this.pi;
      return _loc2_;
   }
   function toString()
   {
      return "Bullet:" + this.bltClip;
   }
}

