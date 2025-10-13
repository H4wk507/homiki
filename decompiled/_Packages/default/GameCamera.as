class GameCamera
{
   var _$mc;
   var bgClipRect;
   var camHeight;
   var camWidth;
   var delta;
   var dis;
   var gameClipRect;
   var mode;
   var moveInt;
   var moving;
   var newTarget;
   var panAngle;
   var pan_speed;
   var qpan_time;
   var target;
   var xvel;
   var yvel;
   var cameraTargetX = 0;
   var cameraTargetY = 0;
   var cameraX = 0;
   var cameraY = 0;
   var clipper = false;
   function GameCamera(gameClip, cWidth, cHeight)
   {
      this._$mc = gameClip;
      this.camHeight = cHeight;
      this.camWidth = cWidth;
      this.dis = new MyDispatcher();
      if(this.clipper == true)
      {
         this.gameClipRect = new flash.geom.Rectangle(0,600,600,400);
         this.bgClipRect = new flash.geom.Rectangle(0,0,600,400);
         this._$mc._y += 600;
         this._$mc.scrollRect = this.gameClipRect;
         _root.background_mc.scrollRect = this.bgClipRect;
      }
   }
   function reset()
   {
      clearInterval(this.moveInt);
      this.qpan_time = 2;
      this.quickPanTo(300,800);
   }
   function zero()
   {
      this.cameraX = 0;
      this.cameraY = 0;
      this._$mc._x = 0;
      this._$mc._y = -600;
      _root.background_mc._x = 0;
      _root.background_mc._y = 0;
   }
   function follow(targClip)
   {
      var _loc3_ = this._$mc[targClip]._x;
      var _loc2_ = this._$mc[targClip]._y;
      if(this.moveInt != undefined)
      {
         clearInterval(this.moveInt);
      }
   }
   function doFollow(targClip)
   {
      var _loc3_ = - targClip._x + 150;
      var _loc5_ = - targClip._y + 200;
      if(_loc3_ < 0)
      {
         this._$mc._x = _loc3_;
      }
      if(_loc5_ > -600)
      {
         this._$mc._y = _loc5_;
      }
      else
      {
         this._$mc._y = -600;
      }
      if(_loc3_ > -650 && _loc3_ <= 0)
      {
         _root.background_mc._x = _loc3_;
      }
      var _loc4_;
      if(_loc5_ < 4170)
      {
         _loc4_ = _loc5_ + 600;
         if(_loc4_ < 0 && _loc4_ < 1)
         {
            _loc4_ = 0;
         }
         _root.background_mc._y = _loc4_;
      }
      if(this._$mc._y > 3300)
      {
         _root.background_mc.spaceBG.stars._x = 665 + this._$mc._x % 705;
         _root.background_mc.spaceBG.stars._y = -320 + this._$mc._y % 282;
      }
      this.updateHills();
   }
   function getCameraPos()
   {
      return {x:this._$mc._x,y:this._$mc._y};
   }
   function panTo(x, y, targClip)
   {
      var _loc3_;
      var _loc2_;
      if(targClip != undefined)
      {
         _loc3_ = this._$mc[targClip]._x;
         _loc2_ = this._$mc[targClip]._y;
      }
      else
      {
         _loc3_ = x;
         _loc2_ = y;
      }
      this.panAngle = this.getPanAngle(_loc3_,_loc2_);
      this.xvel = Math.sin(this.panAngle) * 20;
      this.yvel = (- Math.cos(this.panAngle)) * 20;
      this.delta = this.getDelta(_loc3_,_loc2_);
      if(this.moveInt != undefined)
      {
         clearInterval(this.moveInt);
      }
      this.moveInt = setInterval(this,"doPanTo",50,_loc3_,_loc2_);
   }
   function quickPanTo(x, y, targClip)
   {
      var _loc3_;
      var _loc2_;
      if(targClip != undefined)
      {
         _loc3_ = this._$mc[targClip]._x;
         _loc2_ = this._$mc[targClip]._y;
         this.target = this._$mc[targClip];
      }
      else
      {
         _loc3_ = x;
         _loc2_ = y;
      }
      this.panAngle = this.getPanAngle(_loc3_,_loc2_);
      this.xvel = Math.floor(Math.cos(this.panAngle) * this.qpan_time);
      this.yvel = Math.floor(Math.sin(this.panAngle) * this.qpan_time);
      this.delta = this.getDelta(_loc3_,_loc2_);
      this.cameraTargetX = - this._$mc._x;
      this.cameraTargetY = - this._$mc._y;
      if(this.moveInt != undefined)
      {
         clearInterval(this.moveInt);
      }
      this.moveInt = setInterval(this,"doQuickPanTo",50,_loc3_,_loc2_);
   }
   function doPanTo(x, y)
   {
      var _loc6_ = (this._$mc._x - this.camWidth / 2) * -1;
      var _loc4_ = (this._$mc._y - this.camHeight / 2) * -1;
      var _loc10_ = x;
      var _loc9_ = y;
      var _loc3_ = _loc6_ - x;
      var _loc2_ = _loc4_ - y;
      var _loc5_ = Math.floor(Math.sqrt(_loc3_ * _loc3_ + _loc2_ * _loc2_));
      this._$mc._x += - this.xvel;
      if(_loc5_ < this.pan_speed)
      {
         this.moving = false;
         this.target = this.newTarget;
         this._$mc._x = - x + this.camWidth / 2;
         this._$mc._y = - y + this.camHeight / 2;
         clearInterval(this.moveInt);
      }
   }
   function doQuickPanTo(x, y)
   {
      var _loc7_ = (this._$mc._x - this.camWidth / 2) * -1;
      var _loc5_ = (this._$mc._y - this.camHeight / 2) * -1;
      var _loc11_ = x;
      var _loc10_ = y;
      var _loc4_ = _loc7_ - x;
      var _loc3_ = _loc5_ - y;
      var _loc6_ = Math.floor(Math.sqrt(_loc4_ * _loc4_ + _loc3_ * _loc3_));
      this.cameraTargetX -= _loc4_ / this.qpan_time;
      this.cameraTargetY -= _loc3_ / this.qpan_time;
      this._$mc._x = - this.cameraTargetX;
      this._$mc._y = - this.cameraTargetY;
      if(this.cameraTargetX < 600)
      {
         _root.background_mc._x = - this.cameraTargetX;
      }
      if(_loc6_ < 2)
      {
         if(this.mode == "follow")
         {
            clearInterval(this.moveInt);
            this.moveInt = setInterval(this,"doFollow",50,this.target);
         }
         else
         {
            clearInterval(this.moveInt);
            this.moving = false;
            this.target = this.newTarget;
            this._$mc._x = - x + this.camWidth / 2;
            this._$mc._y = - y + this.camHeight / 2;
            this.dis.disOnDone();
         }
      }
      this.updateHills();
   }
   function updateHills()
   {
      _root.background_mc.ground.hills._x = - _root.background_mc._x - 1249 + 0.025 * this._$mc._x;
      var _loc3_ = -1.05 * this._$mc._y - 950;
      if(_loc3_ < -390)
      {
         _loc3_ = -390;
      }
      _root.background_mc.ground.hills._y = _loc3_;
   }
   function getDelta(x, y)
   {
      var _loc3_ = this._$mc._x - x;
      var _loc2_ = this._$mc._y - y;
      var _loc4_ = Math.sqrt(_loc3_ * _loc3_ + _loc2_ * _loc2_);
      return _loc4_;
   }
   function getPanAngle(x, y)
   {
      var _loc2_ = Math.atan2(y - this._$mc._y,x - this._$mc._x);
      return _loc2_;
   }
   function moveToTarget(mcTarget)
   {
   }
   function setCamMode(cMode, args)
   {
      this.mode = cMode;
   }
   function setPanSpeed(pSpeed)
   {
      this.pan_speed = pSpeed;
   }
   function setQuickPanSpeed(n)
   {
      this.qpan_time = n;
   }
}

