class Game
{
   var _$mc;
   var _bestScore;
   var _so;
   var ad;
   var ar;
   var bc;
   var blt;
   var bltInt;
   var bltNum;
   var boost;
   var bounce;
   var bounceNum;
   var bushCount;
   var bushList;
   var bushMark;
   var cam;
   var cloudCount;
   var cloudList;
   var cloudMark;
   var distances;
   var faceplant;
   var frArray;
   var frCount;
   var gameData;
   var glide;
   var glideCnt;
   var glideDot;
   var glideNum;
   var glideVals;
   var grav;
   var gravButton;
   var gravOn;
   var gravPoints;
   var gravPointsMax;
   var gravSound;
   var hitClip;
   var jumpInt;
   var nodesXML;
   var owner;
   var powerupClips;
   var powerupCount;
   var powerupMark;
   var preludeSound;
   var rebound;
   var reboundNum;
   var shooting;
   var shotNum;
   var skidSound;
   var skidding;
   var slide;
   var slideNum;
   var slideSound;
   var sndBounce;
   var sndBump;
   var sndEnding;
   var sndFadeInterval;
   var sndFly;
   var sndGrav;
   var sndHit;
   var sndPickup;
   var sndPrelude;
   var sndShoot;
   var sndSkid;
   var sndSlide;
   var sndSuperbounce;
   var sndTheme;
   var sndWind;
   var speed;
   var speedNum;
   var state;
   var superbounce;
   var superbounceNum;
   var themeSound;
   var tick;
   var timer;
   var turn;
   var vCount;
   var vehicleMark;
   var waitInt;
   var wind;
   var windNum;
   var windSound;
   var yvel;
   var cheats = false;
   var paused = false;
   var freemode = false;
   var MUSIC_MUTE = false;
   var MUSIC_VOL = 80;
   var SFX_VOLUME = 100;
   var pi = 3.141593;
   var f = 0.6;
   var slidef = 0.99;
   var hit = false;
   var falling = false;
   var clickFlag = false;
   function Game(mcClip, xmlData)
   {
      this._$mc = mcClip;
      this.gameData = xmlData;
      this.shotNum = 0;
      this.init();
      this.hit = false;
   }
   function init()
   {
      this.cam = new GameCamera(this._$mc,600,400);
      this.cam.dis.addEventListener("onDone",this);
      this.bltNum = 0;
      this.state = null;
      this.turn = 1;
      this.distances = new Array();
      this.shooting = false;
      this.faceplant = false;
      this.skidding = false;
      this.bounce = false;
      this.speed = false;
      this.glide = false;
      this.wind = false;
      this.slide = false;
      this.superbounce = false;
      this.rebound = false;
      this.gravOn = false;
      this.falling = false;
      this.bounceNum = 0;
      this.superbounceNum = 0;
      this.speedNum = 0;
      this.glideNum = 0;
      this.windNum = 0;
      this.slideNum = 0;
      this.reboundNum = 0;
      this.gravPointsMax = 100;
      this.gravPoints = 100;
      this.gravButton = false;
      this.updateGravMeter();
      this.powerupCount = 0;
      this.cloudCount = 0;
      this.bushCount = 0;
      this.vCount = 0;
      this.tick = 0;
      this.glideCnt = 0;
      this.glideVals = new Array();
      this.glideDot = 0;
      this.glideVals = [-0.5,-1,-1.5,-2,-1.5,-1,0,0.3,0.5,0.7,1,3,5,8,12,16,21,26,30,25,20,15,10,5,3];
      this.powerupClips = new Array();
      this.powerupMark = 650;
      this.cloudMark = 400;
      this.bushMark = 650;
      this.vehicleMark = 1200;
      this.cloudList = new Array();
      this.bushList = new Array();
      _root.background_mc.spaceBG._y = -4790;
      _root.launchMeter._visible = true;
      _root.gravMeter._visible = false;
      this.initSounds();
      if(this.cheats)
      {
         Key.addListener(this);
      }
      this.initSO();
      if(this.MUSIC_MUTE == true)
      {
         _root.musicBtn.gotoAndStop(1);
         this.sndTheme.setVolume(0);
         this.sndEnding.setVolume(0);
         this.sndPrelude.setVolume(0);
      }
      else
      {
         _root.musicBtn.gotoAndStop(2);
         this.sndTheme.setVolume(this.MUSIC_VOL);
         this.sndEnding.setVolume(this.MUSIC_VOL);
         this.sndPrelude.setVolume(this.MUSIC_VOL);
      }
      _root.musicBtn.owner = this;
      _root.musicBtn.onRelease = function()
      {
         this.owner.toggleMusic();
      };
      _root.musicBtn.onRollOver = function()
      {
         this.owner.clickFlag = true;
         if(this.owner.MUSIC_MUTE == true)
         {
            _root.muteMC.gotoAndStop("musicOff_RO");
         }
         else
         {
            _root.muteMC.gotoAndStop("musicOn_RO");
         }
      };
      _root.musicBtn.onRollOut = function()
      {
         this.owner.clickFlag = false;
         if(this.owner.MUSIC_MUTE == true)
         {
            _root.muteMC.gotoAndStop("musicOff");
         }
         else
         {
            _root.muteMC.gotoAndStop("musicOn");
         }
      };
      this.playSound(this.sndPrelude,this.MUSIC_VOL,9999);
      this.preludeSound = true;
      _root.scrollRect = new flash.geom.Rectangle(0,0,600,400);
      this.frCount = 0;
      this.frArray = [];
      this.timer = 0;
      this.loadTracker();
   }
   function loadTracker()
   {
      var _loc1_ = new Date().getTime();
      loadMovieNum("http://files.gamezhero.com/online/hamsters/tracker.swf?" + _loc1_,100000);
   }
   function onKeyUp()
   {
      if(Key.getCode() == 39)
      {
         this.blt.xvel += 5;
      }
      if(Key.getCode() == 32)
      {
         this.paused = !this.paused;
      }
      if(Key.getCode() == 49)
      {
         this.slide = true;
      }
      if(this.freemode)
      {
         this.blt.grav = 0;
         if(Key.getCode() == 38)
         {
            this.blt.yvel += 5;
         }
         if(Key.getCode() == 40)
         {
            this.blt.yvel -= 5;
         }
         if(Key.getCode() == 37)
         {
            this.blt.xvel -= 5;
         }
      }
   }
   function initSounds()
   {
      this._$mc.createEmptyMovieClip("sounds",10);
      this.createSound("sndShoot","snd_shoot","shoot");
      this.createSound("sndFly","snd_fly","fly");
      this.createSound("sndWind","snd_wind","wind");
      this.createSound("sndBounce","snd_bounce","bounce");
      this.createSound("sndSuperbounce","snd_superbounce","superbounce");
      this.createSound("sndHit","snd_hit","hit");
      this.createSound("sndPickup","snd_pickup","pickup");
      this.createSound("sndBump","snd_bump","bump");
      this.createSound("sndSlide","snd_slide","slide");
      this.createSound("sndSkid","snd_skid","skid");
      this.createSound("sndGrav","snd_wind","grav");
      this.createSound("sndPrelude","snd_prelude","prelude");
      this.createSound("sndTheme","snd_theme","theme");
      this.createSound("sndEnding","snd_ending","ending");
      this.slideSound = false;
      this.skidSound = false;
      this.windSound = false;
      this.gravSound = false;
      this.preludeSound = false;
      this.themeSound = false;
      _root.muteMC.gotoAndStop(2);
   }
   function createSound(name, linkName, clipName)
   {
      var _loc2_ = this._$mc.sounds.createEmptyMovieClip(clipName,this._$mc.sounds.getNextHighestDepth());
      this[name] = new Sound(_loc2_);
      this[name].attachSound(linkName);
   }
   function fadeOutSound(s)
   {
      clearInterval(this.sndFadeInterval);
      this.sndFadeInterval = setInterval(this,"doFade",50,s);
   }
   function playSound(snd, vol, loops)
   {
      snd.setVolume(vol);
      if(!loops)
      {
         loops = 0;
      }
      snd.start(0,loops);
   }
   function toggleMusic()
   {
      this.MUSIC_MUTE = !this.MUSIC_MUTE;
      if(this.MUSIC_MUTE == true)
      {
         this.MUSIC_VOL = 0;
         this.sndPrelude.setVolume(0);
         this.sndTheme.setVolume(0);
         this.sndEnding.setVolume(0);
         _root.muteMC.gotoAndStop("musicOff");
      }
      else
      {
         this.MUSIC_VOL = 60;
         this.sndPrelude.setVolume(this.MUSIC_VOL);
         this.sndTheme.setVolume(this.MUSIC_VOL);
         this.sndEnding.setVolume(this.MUSIC_VOL);
         _root.muteMC.gotoAndStop("musicOn");
      }
   }
   function doFade(s)
   {
      var _loc2_ = s.getVolume() - 3;
      s.setVolume(_loc2_);
      if(_loc2_ <= 0 || this.MUSIC_MUTE == true)
      {
         s.stop();
         clearInterval(this.sndFadeInterval);
      }
   }
   function resetBtn()
   {
      stopAllSounds();
      this.resetSounds();
      clearInterval(this.waitInt);
      clearInterval(this.jumpInt);
      clearInterval(this.bltInt);
      this._$mc.hamster._y = 956;
      this.cam.zero();
      this.reset();
   }
   function reset()
   {
      this.cleanUp();
      this.playSound(this.sndPrelude,this.MUSIC_VOL,9999);
      this.sndTheme.stop();
      _root.launchMeter._visible = true;
      _root.launchMeter.gotoAndStop(1);
      _root.gravMeter._visible = false;
      this.state = null;
      this.turn = 1;
      this.distances = new Array();
      this.shooting = false;
      this.faceplant = false;
      this.shotNum = 0;
      this.bltNum = 0;
      this.bounce = false;
      this.speed = false;
      this.glide = false;
      this.wind = false;
      this.slide = false;
      _root.skate_icon._visible = false;
      this.falling = false;
      var _loc3_ = 6;
      while(_loc3_--)
      {
         _root["shotDistance" + _loc3_ + "_txt"].text = "= 0 ft.";
         _root["shotStatus" + _loc3_ + "_mc"].gotoAndStop(1);
      }
      _root.distanceTotal_txt.text = "";
      this._$mc.hamster._visible = true;
      this._$mc.hamster.gotoAndStop(1);
      this._$mc.hWalkOut2.gotoAndStop(1);
      this._$mc.hWalkOut2._x = 30.5;
      this._$mc.hWalkOut2._visible = true;
      this._$mc.hWalkOut3.gotoAndStop(1);
      this._$mc.hWalkOut3._x = 15.5;
      this._$mc.hWalkOut3._visible = true;
      this._$mc.hWalkOut4.gotoAndStop(1);
      this._$mc.hWalkOut4._x = 0.5;
      this._$mc.hWalkOut4._visible = true;
      this._$mc.hWalkOut5.gotoAndStop(1);
      this._$mc.hWalkOut5._x = -14.5;
      this._$mc.hWalkOut5._visible = true;
      _root.gameOver_mc._visible = false;
      _root.chalkboard_mc._visible = false;
      _loc3_ = 6;
      while(_loc3_--)
      {
         this._$mc["blt" + _loc3_].removeMovieClip();
      }
      this.powerupMark = 650;
      this.cloudMark = 400;
      this.bushMark = 650;
      this.loadTracker();
   }
   function setScore()
   {
      var _loc3_ = this.updateDistance();
      this.distances.push(_loc3_);
      _root["shotStatus" + this.turn + "_mc"].gotoAndStop("on");
      _root["shotDistance" + this.turn + "_txt"].text = "= " + _loc3_ + " ft.";
   }
   function updateGameState()
   {
      this.turn = this.turn + 1;
      if(this.turn == 6)
      {
         this.gameOver();
      }
      else
      {
         this.nextHamster();
      }
   }
   function gameOver()
   {
      this.shooting = true;
      _root.gameOver_mc._visible = true;
      _root.gameOver_mc.gotoAndPlay(2);
      _root.gameOver_mc.mask_mc.gotoAndPlay(2);
      _root.chalkboard_mc._visible = true;
      this.sndPrelude.stop();
      this.fadeOutSound(this.sndTheme);
      this.playSound(this.sndEnding,this.MUSIC_VOL);
      var _loc7_ = this.distances.length;
      var _loc4_ = 0;
      while(_loc7_--)
      {
         _loc4_ += Number(this.distances[_loc7_]);
      }
      _root.distanceTotal_txt.text = "Total = " + _loc4_ + " ft.";
      _root.gameOver_mc.distanceTotal_txt.text = _loc4_ + " ft.";
      _root.gameOver_mc.finalScore_txt.text = _loc4_ + " ft.";
      _loc7_ = this.distances.length;
      var _loc6_ = "";
      var _loc3_ = 0;
      while(_loc3_ < _loc7_)
      {
         _loc6_ += this.distances[_loc3_] + " ft. \r";
         _loc3_ = _loc3_ + 1;
      }
      _loc6_ += _loc4_ + " ft.";
      _root.gameOver_mc.shots_txt.text = _loc6_;
      var _loc5_ = "You just need practice.  Don\'t give up!";
      if(_loc4_ >= 100)
      {
         _loc5_ = "Keep trying -- you\'ll get the hang of it!";
      }
      if(_loc4_ >= 200)
      {
         _loc5_ = "Not bad.  Can you do even better?";
      }
      if(_loc4_ >= 300)
      {
         _loc5_ = "Nice job!";
      }
      if(_loc4_ >= 400)
      {
         _loc5_ = "Wow!  You\'re a real pro!";
      }
      if(_loc4_ >= 600)
      {
         _loc5_ = "That was totally sweet!";
      }
      if(_loc4_ >= 800)
      {
         _loc5_ = "Hamsterrific!";
      }
      if(_loc4_ >= 1000)
      {
         _loc5_ = "Incredible!  You\'re the hamster champ!";
      }
      if(this.checkBestScore(_loc4_))
      {
         _loc5_ += "\nYou got a new high score!";
         this.saveBestScore(_loc4_);
      }
      _root.gameOver_mc.rating_txt.text = _loc5_;
   }
   function onUpdate()
   {
      if(this.paused)
      {
         return undefined;
      }
      this.frCount = this.frCount + 1;
      this.frArray.push(Math.floor(10 * (1 / ((getTimer() - this.timer) / 1000))) / 10);
      if(this.frArray.length > 20)
      {
         this.frArray.shift();
      }
      this.timer = getTimer();
      var _loc3_;
      var _loc4_;
      if(this.frCount > 20)
      {
         this.frCount = 0;
         _loc3_ = this.frArray.length;
         _loc4_ = 0;
         while(_loc3_--)
         {
            _loc4_ += this.frArray[_loc3_];
         }
         _root.framerate = _loc4_ / 20;
      }
      var _loc8_ = this.bc._y;
      this.generatePowerups();
      this.generateClouds();
      this.generateBushes();
      this.checkPowerUpsColl();
      this.checkCollision();
      if(this.wind)
      {
         this.blt.yvel -= 8;
         this.blt.xvel += 2;
         this.bc.flying_mc._visible = false;
         this.wind = false;
         if(!this.windSound)
         {
            this.playSound(this.sndWind,this.SFX_VOLUME);
            this.windSound = true;
         }
         else
         {
            this.windSound = false;
         }
      }
      if(this.gravOn)
      {
         this.grav -= 2;
         this.gravOn = false;
         if(!this.gravSound)
         {
            this.playSound(this.sndGrav,this.SFX_VOLUME);
            this.gravSound = true;
         }
         else
         {
            this.gravSound = false;
         }
      }
      if(this.speed)
      {
         this.blt.xvel += 20;
         this.speed = false;
      }
      if(this.rebound)
      {
         this.blt.xvel = 40;
         this.blt.yvel = -40;
         this.rebound = false;
         this.blt.doRotation = true;
         this.bc.slide._visible = false;
         this.bc.skid._visible = false;
         this.bc.flying_mc._visible = true;
         this.sndSlide.stop();
         this.slideSound = false;
         this.blt.hit = false;
      }
      var _loc5_;
      var _loc7_;
      if(this.slide && this.skidding)
      {
         this.blt.doRotation = false;
         this.bc.slide._visible = true;
         this.bc.slide.play();
         _root.skate_icon._visible = false;
         if(!this.slideSound)
         {
            this.playSound(this.sndSlide,this.SFX_VOLUME,9999);
            this.sndFly.setVolume(5);
            this.slideSound = true;
         }
         else
         {
            _loc5_ = Math.abs(this.blt.xvel);
            _loc5_ = Math.floor(_loc5_);
            _loc7_ = Math.floor(_loc5_ / 20 * 100);
            this.sndSlide.setVolume(_loc7_);
         }
      }
      else if(this.skidding)
      {
         this.blt.doRotation = false;
         this.bc.skid._visible = true;
         this.bc.flying_mc._visible = false;
         if(!this.skidSound)
         {
            this.playSound(this.sndSkid,this.SFX_VOLUME);
            this.sndFly.setVolume(5);
            this.skidSound = true;
         }
      }
      else
      {
         _loc5_ = Math.abs(this.blt.xvel) + Math.abs(this.blt.yvel);
         _loc5_ = Math.floor(_loc5_);
         _loc7_ = Math.floor(_loc5_ / 70 * 100);
         this.sndFly.setVolume(_loc7_);
      }
      if(this.glide)
      {
         if(this.falling || this.gravPoints == 0)
         {
            this.glide = false;
            this.glideOff();
         }
      }
      this.blt.xvel *= 0.99;
      if(!this.freemode)
      {
         this.blt.yvel += this.blt.grav;
      }
      if(this.blt.yvel > 50 && !this.bounce & !this.superbounce)
      {
         if(this.falling == false)
         {
            this.fallOn();
            this.falling = true;
         }
      }
      else if(this.falling == true)
      {
         this.falling = false;
         this.fallOff();
      }
      var _loc6_;
      if(this.blt.hit)
      {
         _loc6_ = this.bc._y;
         if(_loc6_ >= 946 && _loc8_ >= 946 && _loc6_ + this.blt.yvel >= 946)
         {
            this.skidding = true;
         }
      }
      this.blt.update();
      this.cam.doFollow(this.bc);
      if(this.blt.xvel < 1 && this.blt.hit)
      {
         this.onShotDone();
      }
      if(this.gravButton)
      {
         this.gravPoints -= 10;
         if(this.gravPoints <= 0)
         {
            this.gravPoints = 0;
            this.blt.restoreGravity();
         }
      }
      else
      {
         this.gravPoints = this.gravPoints + 1;
         if(this.gravPoints > this.gravPointsMax)
         {
            this.gravPoints = this.gravPointsMax;
         }
      }
      this.updateGravMeter();
   }
   function fallOn()
   {
      this.bc.drop._visible = true;
      this.bc.drop.gotoAndPlay(2);
      this.bc.flying_mc._visible = false;
   }
   function fallOff()
   {
      this.bc.drop._visible = false;
      this.bc.drop.gotoAndStop(1);
      this.bc.flying_mc._visible = true;
   }
   function updateGravMeter()
   {
      var _loc3_ = 1 + Math.floor(100 * this.gravPoints / this.gravPointsMax);
      _root.gravMeter.gotoAndStop(_loc3_);
   }
   function checkPowerUpsColl(Void)
   {
      var _loc5_ = this.cam.getCameraPos().x;
      var _loc4_ = 0;
      var _loc3_;
      while(_loc4_ < this.powerupClips.length)
      {
         _loc3_ = this.powerupClips[_loc4_];
         if(this._$mc._x + _loc3_._x < -100)
         {
            _loc3_.removeMovieClip();
            this.powerupClips.shift();
         }
         else
         {
            switch(_loc3_.typ)
            {
               case "bounce":
                  if(_loc3_.core.hitTest(this.bc.core) && !this.bounce)
                  {
                     this.bc.ball._visible = true;
                     this.bc.superball._visible = false;
                     this.bc.drop._visible = false;
                     this.bc.ball.gotoAndPlay(2);
                     this.bounce = true;
                     this.superbounce = false;
                     this.falling = false;
                     this.fallOff();
                     this.playSound(this.sndPickup,this.SFX_VOLUME);
                     _loc3_.play();
                  }
                  break;
               case "superbounce":
                  if(_loc3_.core.hitTest(this.bc.core) && !this.superbounce)
                  {
                     this.bc.ball._visible = false;
                     this.bc.superball._visible = true;
                     this.bc.drop._visible = false;
                     this.bc.superball.gotoAndPlay(2);
                     this.bounce = false;
                     this.superbounce = true;
                     this.falling = false;
                     this.fallOff();
                     this.playSound(this.sndPickup,this.SFX_VOLUME);
                     _loc3_.play();
                  }
                  break;
               case "speed":
                  if(_loc3_.core.hitTest(this.bc.core))
                  {
                     this.bc.blur._visible = true;
                     this.bc.flying_mc._visible = false;
                     this.bc.glide._visible = false;
                     this.bc.drop._visible = false;
                     this.bc.wind._visible = false;
                     this.bc.blur.gotoAndPlay(2);
                     this.speed = true;
                     _loc3_.play();
                  }
                  break;
               case "wind":
                  if(_loc3_.core.hitTest(this.bc.core))
                  {
                     if(!this.glide)
                     {
                        this.bc.wind._visible = true;
                        this.bc.flying_mc._visible = false;
                     }
                     this.bc.drop._visible = false;
                     this.bc.blur._visible = false;
                     this.bc.wind.play();
                     this.wind = true;
                  }
                  break;
               case "slide":
                  if(_loc3_.core.hitTest(this.bc.core) && !this.slide)
                  {
                     this.playSound(this.sndPickup,this.SFX_VOLUME);
                     this.slide = true;
                     _root.skate_icon._visible = true;
                     _loc3_.play();
                  }
                  break;
               case "rebound":
                  if(_loc3_.core.hitTest(this.bc.core) && !this.rebound)
                  {
                     this.rebound = true;
                     if(this.slide && this.skidding)
                     {
                        this.slide = false;
                     }
                     this.skidding = false;
                     this.bc.slide.stop();
                     this.bc.slide._visible = false;
                     this.falling = false;
                     this.fallOff();
                     _loc3_.play();
                  }
            }
         }
         _loc4_ = _loc4_ + 1;
      }
   }
   function checkCollision()
   {
      var _loc6_ = this.bc._y + this.blt.yvel;
      if(this.rebound)
      {
         return undefined;
      }
      var _loc10_;
      var _loc9_;
      var _loc2_;
      var _loc5_;
      var _loc3_;
      var _loc8_;
      var _loc7_;
      var _loc4_;
      if(_loc6_ >= 950)
      {
         this.bc._y = 950;
         this.blt.hit = true;
         if(this.glide)
         {
            this.glide = false;
            this.glideOff();
         }
         _loc10_ = this.bc._x - this.blt.ox;
         _loc9_ = _loc6_ - this.blt.oy;
         _loc2_ = Math.atan2(_loc9_,_loc10_);
         _loc2_ = this.radainsToDegrees(_loc2_);
         _loc5_ = 70;
         if(_loc2_ < _loc5_ && !this.bounce && !this.superbounce && !this.slide)
         {
            this.bc._y = 949;
            this.blt.xvel *= this.f;
            this.blt.yvel /= -2;
            if(!this.skidding)
            {
               this._$mc.bg_mc.bounce.removeMovieClip();
               _loc3_ = this._$mc.bg_mc.attachMovie("bounce_fx","bounce",900000);
               _loc3_._x = 155 - this.cam.getCameraPos().x;
               _loc3_._y = 955;
               this.bushCount = this.bushCount + 1;
               this.playSound(this.sndBump,this.SFX_VOLUME);
            }
         }
         else if(this.bounce)
         {
            this.bc._y = 949;
            this.blt.xvel *= this.f;
            this.blt.yvel *= -0.6;
            if(this.blt.yvel > -30)
            {
               this.blt.yvel = -30;
            }
            this.bc.ball._visible = false;
            this.bc.drop._visible = false;
            this.bc.flying_mc._visible = true;
            this.playSound(this.sndBounce,this.SFX_VOLUME);
            _loc3_ = this._$mc.bg_mc.attachMovie("break","shatter",900000);
            _loc3_._x = 165 - this.cam.getCameraPos().x;
            _loc3_._y = 955;
            this.bounce = false;
            this.blt.hit = false;
         }
         else if(this.superbounce)
         {
            this.bc._y = 949;
            this.blt.xvel *= 1 + this.f;
            this.blt.yvel *= -1.5;
            if(this.blt.yvel > -50)
            {
               this.blt.yvel = -50;
            }
            this.bc.superball._visible = false;
            this.bc.drop._visible = false;
            this.bc.flying_mc._visible = true;
            this.playSound(this.sndSuperbounce,this.SFX_VOLUME);
            _loc3_ = this._$mc.bg_mc.attachMovie("super_break","shatter",900000);
            _loc3_._x = 165 - this.cam.getCameraPos().x;
            _loc3_._y = 955;
            this.superbounce = false;
            this.blt.hit = false;
         }
         else if(_loc2_ > _loc5_)
         {
            this.bc._y = 950;
            this.blt.xvel = 0;
            this.blt.yvel = 0;
            _loc8_ = this.bc._x;
            _loc7_ = this.bc._y;
            _loc4_ = this.bc._rotation;
            this.sndFly.stop();
            this.faceplant = true;
            if(this.falling == true)
            {
               this.createHitClip(_loc8_,_loc7_,_loc4_,"hole");
               this.blt.shadClip._visible = false;
            }
            else
            {
               this.createHitClip(_loc8_,_loc7_ + 3,_loc4_,"faceplant");
               this.playSound(this.sndHit,this.SFX_VOLUME);
               this.blt.shadClip._visible = false;
            }
         }
         else if(this.slide && !this.skidding)
         {
            this.bc._y = 950;
            this.blt.xvel *= this.slidef;
            this.blt.yvel /= -2;
            this.playSound(this.sndBump,this.SFX_VOLUME);
         }
         else if(this.slide && this.skidding)
         {
            this.bc._y = 950;
            this.blt.xvel *= this.slidef;
            this.blt.yvel /= -2;
         }
         else
         {
            this.bc._y = 950;
            this.blt.xvel *= this.f;
            this.blt.yvel /= -2;
            if(!this.skidding)
            {
               this.playSound(this.sndBump,this.SFX_VOLUME);
            }
         }
         this.falling = false;
      }
   }
   function glideOn()
   {
      this.bc.glide._visible = true;
      this.bc.flying_mc._visible = false;
      this.bc.blur._visible = false;
      this.bc.wind._visible = false;
      this.bc.glide.gotoAndPlay(2);
   }
   function glideOff()
   {
      this.bc.glide._visible = false;
      if(this.bc.wind._visible != true && this.bc.blur._visible != true)
      {
         this.bc.flying_mc._visible = true;
      }
      else
      {
         this.bc.flying_mc._visible = false;
      }
      this.bc.glide.gotoAndStop(1);
   }
   function updateDistance()
   {
      var _loc2_ = Math.floor(this.blt.bltClip._x / 100);
      if(isNaN(_loc2_))
      {
         _loc2_ = 0;
      }
      return _loc2_;
   }
   function updateBestDistance()
   {
      if(this.bc._x > Number(this._$mc.best_txt.text))
      {
         return Math.floor(this.bc._x);
      }
      return Number(this._$mc.best_txt.text);
   }
   function resetSounds()
   {
      this.sndFly.stop();
      this.sndSlide.stop();
      this.sndFly.setVolume(100);
      this.sndSlide.setVolume(100);
      this.sndSkid.setVolume(100);
      this.skidSound = false;
      this.slideSound = false;
      this.windSound = false;
   }
   function onShotDone()
   {
      clearInterval(this.bltInt);
      this.blt.deleteBlt();
      this.resetSounds();
      var _loc4_;
      var _loc3_;
      var _loc2_;
      if(!this.faceplant && !this.falling)
      {
         _loc4_ = this.bc._x;
         _loc3_ = this.bc._y;
         _loc2_ = this.bc._rotation;
         this.createHitClip(_loc4_,_loc3_,_loc2_,"cheer");
      }
      this.blt.shadClip._visible = false;
   }
   function onDone()
   {
      this.blt = undefined;
      this.slide = false;
      _root.skate_icon._visible = false;
      this.skidding = false;
      this._$mc.hamster._x = 148;
      this._$mc.hamster._y = 956;
      _root.background_mc.pillow._x = 117.3;
      this._$mc.pillow._x = 117.3;
      this.updateGameState();
      this.cleanUpItems();
   }
   function nextHamster()
   {
      if(!this.preludeSound)
      {
         this.playSound(this.sndPrelude,this.MUSIC_VOL,9999);
      }
      this.fadeOutSound(this.sndTheme);
      this.preludeSound = true;
      _root.launchMeter._visible = true;
      _root.launchMeter.gotoAndStop(1);
      _root.gravMeter._visible = false;
      this._$mc.hamster._visible = false;
      this._$mc["hWalkOut" + this.turn].play();
      var _loc4_ = this.turn + 1;
      var _loc3_ = _loc4_;
      while(_loc3_ <= 5)
      {
         this._$mc["hWalkOut" + _loc3_].gotoAndPlay("walkUp");
         _loc3_ = _loc3_ + 1;
      }
      this.updateGravMeter();
   }
   function createHitClip(x, y, rot, type, dpth)
   {
      var _loc2_ = "hit_" + type;
      var _loc3_ = dpth != undefined ? 100 + this.bltNum : this.bltNum;
      this.hitClip = this._$mc.attachMovie(_loc2_,"blt" + this.bltNum,_loc3_);
      this.hitClip._rotation = 90;
      this.hitClip._x = x;
      this.hitClip._y = y;
   }
   function onMouseDown()
   {
      if(this.clickFlag == true)
      {
         return undefined;
      }
      if(this.state == null && !this.shooting)
      {
         this.state = "jump";
         this._$mc.hamster.gotoAndPlay("jump");
         _root.background_mc.gotoAndPlay(2);
         _root.background_mc.hamsterWheel1.play();
         _root.background_mc.hamsterWheel2.play();
      }
      else if(this.state == "jump" && !this.shooting)
      {
         _root.background_mc.nextFrame();
         _root.background_mc.hamsterWheel1.gotoAndStop(1);
         _root.background_mc.hamsterWheel2.gotoAndStop(1);
         this.state = "launch";
         this.playSound(this.sndShoot,this.SFX_VOLUME);
         this.launch();
      }
      else if(this.shooting && !this.skidding)
      {
         this.blt.increaseGravity();
         this.gravButton = true;
         if(this.glide == false && this.falling == false)
         {
            this.glide = true;
            this.glideOn();
         }
      }
   }
   function onMouseUp()
   {
      if(this.shooting)
      {
         this.blt.restoreGravity();
         this.gravButton = false;
         if(this.glide == true)
         {
            this.glide = false;
            this.glideOff();
         }
      }
   }
   function jump()
   {
      this.bltNum = this.bltNum + 1;
      this.yvel = (random(5) + 10) * -1;
      this.boost = false;
      if(this.jumpInt)
      {
         clearInterval(this.jumpInt);
      }
      this.jumpInt = setInterval(this,"jumpFrame",50);
   }
   function jumpFrame()
   {
      var _loc4_;
      if(!this.boost && this._$mc.hamster._y < 930)
      {
         _loc4_ = random(5) + 15;
         _loc4_ *= -1;
         this.yvel += _loc4_;
         this.boost = true;
      }
      var _loc5_ = this.yvel < 0 ? 1.5 : 0.75;
      this.yvel += _loc5_;
      this._$mc.hamster._y += this.yvel;
      if(this._$mc.hamster._y >= 956)
      {
         clearInterval(this.jumpInt);
         this.state = null;
         this._$mc.hamster._y = 956;
         this._$mc.hamster.gotoAndStop(1);
         this._$mc.hamster._visible = false;
         this.playSound(this.sndHit,this.SFX_VOLUME);
         this.shooting = true;
         this.faceplant = true;
         this.createHitClip(140,970,90,"zero",true);
      }
      if(this.yvel > 0)
      {
         _root.launchMeter.arrow._rotation = 180;
      }
      else
      {
         _root.launchMeter.arrow._rotation = 0;
      }
      var _loc3_ = 48 + 0.35417 * (this._$mc.hamster._y - 715);
      if(_loc3_ > 100)
      {
         _loc3_ = 100;
      }
      if(_loc3_ < 10)
      {
         _loc3_ = 10;
      }
      _root.launchMeter.arrow._y = _loc3_;
      this.cam.doFollow(this._$mc.hamster);
   }
   function launch()
   {
      this._$mc.pillow._x = 140;
      this.getPillowCollision();
   }
   function getPillowCollision()
   {
      var _loc4_;
      var _loc3_;
      var _loc5_;
      if(this._$mc.hamster.core.hitTest(this._$mc.pillow))
      {
         if(this._$mc.hamster._y > 759)
         {
            this._$mc.hamster._y = 759;
            this.yvel = 0;
         }
         clearInterval(this.jumpInt);
         _loc4_ = this._$mc.hamster._x - this._$mc.pillow._x + 30;
         _loc3_ = this._$mc.hamster._y - this._$mc.pillow._y - 5;
         _loc5_ = Math.sqrt(_loc4_ * _loc4_ + _loc3_ * _loc3_);
         this.ar = Math.atan2(_loc3_,_loc4_);
         this.ad = this.ar * 180 / this.pi + 90;
         this.ar = this.ad * this.pi / 180;
         this._$mc.hamster.gotoAndStop(1);
         this._$mc.hamster._visible = false;
         this.shoot(_loc5_,this.ar);
      }
      else
      {
         _root.background_mc.gotoAndPlay("miss");
      }
   }
   function shoot(f, a)
   {
      this.sndPrelude.stop();
      this.playSound(this.sndTheme,this.MUSIC_VOL,9999);
      this.preludeSound = false;
      this.themeSound = true;
      _root.launchMeter._visible = false;
      _root.gravMeter._visible = true;
      var _loc6_ = this.yvel;
      var _loc3_ = 90 - f;
      if(_loc6_ < 0)
      {
         if(this.ad <= 90)
         {
            _loc3_ -= this.yvel / 2;
         }
         else
         {
            _loc3_ += this.yvel / 2;
         }
      }
      this.faceplant = false;
      this.shooting = true;
      var _loc4_ = this._$mc.hamster._x;
      var _loc5_ = this._$mc.hamster._y;
      this.blt = new Bullet(this._$mc,_loc4_,_loc5_,"arrow",_loc3_,this.ar,0.99,this.bltNum);
      this.bc = this.blt.bltClip;
      this.setCamFollow();
      this.playSound(this.sndFly,this.SFX_VOLUME,9999);
      this.gravPoints = this.gravPointsMax;
      this.updateGravMeter();
      this.bltInt = setInterval(this,"onUpdate",50);
   }
   function cleanUp(Void)
   {
      this.shooting = false;
      this.state = null;
      this.tick = 0;
      this.glideCnt = 0;
   }
   function testShoot(y, f)
   {
      this._$mc.hamster.gotoAndStop("testFrame");
      this._$mc.hamster._y = y;
      this.yvel = f;
      this.launch();
   }
   function setCamFollow()
   {
      this.cam.setCamMode("follow");
      this.cam.setQuickPanSpeed(2);
      this.cam.follow("blt" + this.bltNum);
   }
   function setCamReset()
   {
      clearInterval(this.waitInt);
      this.cam.setCamMode("qpan");
      this.cam.setQuickPanSpeed(2);
      this.cam.reset();
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
   function generateClouds()
   {
      var _loc4_ = this.cam.getCameraPos();
      var _loc3_ = _loc4_.x;
      var _loc9_ = _loc4_.y;
      var _loc8_;
      if(this.cloudList[0]._x < -120 - _loc3_)
      {
         _loc8_ = this.cloudList.shift();
         _loc8_.removeMovieClip();
      }
      if(600 - _loc3_ < this.cloudMark)
      {
         return undefined;
      }
      var _loc6_ = 700 - random(3600);
      var _loc7_ = random(3) + 1;
      var _loc5_ = "c" + this.cloudCount;
      var _loc2_ = this._$mc.bg_mc.attachMovie("cloud" + _loc7_,_loc5_,10000 + this.cloudCount);
      this.cloudList.push(_loc2_);
      _loc2_.cacheAsBitmap = true;
      _loc2_._x = 800 - _loc3_;
      _loc2_._y = _loc6_;
      this.cloudCount = this.cloudCount + 1;
      this.cloudMark += 100 + random(200);
   }
   function generateBushes()
   {
      var _loc4_ = this.cam.getCameraPos();
      var _loc3_ = _loc4_.x;
      var _loc8_ = _loc4_.y;
      var _loc7_;
      if(this.bushList[0]._x < -100 - _loc3_)
      {
         _loc7_ = this.bushList.shift();
         _loc7_.removeMovieClip();
      }
      if(600 - _loc3_ < this.bushMark)
      {
         return undefined;
      }
      var _loc6_ = random(5) + 1;
      var _loc5_ = "c" + this.bushCount;
      var _loc2_ = this._$mc.bg_mc.attachMovie("bush" + _loc6_,_loc5_,20000 + this.bushCount);
      this.bushList.push(_loc2_);
      _loc2_.cacheAsBitmap = true;
      _loc2_._x = 800 - _loc3_;
      _loc2_._y = 885;
      this.bushCount = this.bushCount + 1;
      this.bushMark += 300 + random(300);
   }
   function generatePowerups()
   {
      var _loc4_ = this.cam.getCameraPos();
      var _loc5_ = _loc4_.x;
      var _loc6_ = _loc4_.y;
      if(600 - _loc5_ < this.powerupMark)
      {
         return undefined;
      }
      this.powerupMark += 150;
      this.powerupCount = this.powerupCount + 1;
      var _loc3_ = random(11);
      var _loc2_;
      switch(_loc3_)
      {
         case 0:
         case 1:
            _loc2_ = this._$mc.opp_mc.attachMovie("_bounce","bounce" + this.bounceNum,this.powerupCount);
            _loc2_.typ = "bounce";
            this.bounceNum = this.bounceNum + 1;
            break;
         case 2:
         case 3:
         case 4:
            _loc2_ = this._$mc.opp_mc.attachMovie("_speed","speed" + this.speedNum,this.powerupCount);
            _loc2_.cacheAsBitmap = true;
            _loc2_.typ = "speed";
            this.speedNum = this.speedNum + 1;
            break;
         case 5:
         case 6:
         case 7:
            _loc2_ = this._$mc.opp_mc.attachMovie("_wind","wind" + this.windNum,this.powerupCount);
            _loc2_.typ = "wind";
            this.windNum = this.windNum + 1;
            break;
         case 8:
            _loc2_ = this._$mc.opp_mc.attachMovie("_slide","slide" + this.slideNum,this.powerupCount);
            _loc2_.cacheAsBitmap = true;
            _loc2_.typ = "slide";
            this.slideNum = this.slideNum + 1;
            break;
         case 9:
            _loc2_ = this._$mc.opp_mc.attachMovie("_rebound","rebound" + this.reboundNum,this.powerupCount);
            _loc2_.cacheAsBitmap = true;
            _loc2_.typ = "rebound";
            this.reboundNum = this.reboundNum + 1;
            break;
         case 10:
            _loc2_ = this._$mc.opp_mc.attachMovie("_superbounce","superbounce" + this.superbounceNum,this.powerupCount);
            _loc2_.typ = "superbounce";
            this.superbounceNum = this.superbounceNum + 1;
      }
      _loc2_._x = 800 - _loc5_;
      if(_loc3_ == 9)
      {
         _loc2_._y = 930;
      }
      else
      {
         _loc2_._y = 840 - random(1200);
      }
      this.powerupClips.push(_loc2_);
   }
   function generateVehicle()
   {
      var _loc3_ = this.cam.getCameraPos();
      var _loc4_ = _loc3_.x;
      var _loc6_ = _loc3_.y;
      if(600 - _loc4_ < this.vehicleMark)
      {
         return undefined;
      }
      this.vehicleMark += 1200;
      this.vCount = this.vCount + 1;
      var _loc5_ = random(2);
      var _loc2_;
      switch(_loc5_)
      {
         case 0:
            _loc2_ = this._$mc.bg_mc.attachMovie("v_bus","vehicle",15000);
            break;
         case 1:
            _loc2_ = this._$mc.bg_mc.attachMovie("v_scamper","vehicle",15000);
            break;
         case 2:
            _loc2_ = this._$mc.bg_mc.attachMovie("v_plane","vehicle",15000);
      }
      _loc2_._x = 800 - _loc4_;
      _loc2_._y = 840 - random(1200);
   }
   function cleanUpItems()
   {
      var _loc3_ = this.powerupClips.length;
      var _loc2_;
      while(_loc3_--)
      {
         _loc2_ = this.powerupClips.pop();
         _loc2_.removeMovieClip();
      }
      _loc3_ = this.cloudList.length;
      while(_loc3_--)
      {
         _loc2_ = this.cloudList.pop();
         _loc2_.removeMovieClip();
      }
      _loc3_ = this.bushList.length;
      while(_loc3_--)
      {
         _loc2_ = this.bushList.pop();
         _loc2_.removeMovieClip();
      }
      this.bounceNum = 0;
      this.speedNum = 0;
      this.glideNum = 0;
      this.windNum = 0;
      this.slideNum = 0;
      this.powerupMark = 600;
      this.bushMark = 650;
      this.cloudMark = 400;
   }
   function plotNodes(oXML)
   {
      var _loc7_ = this.nodesXML.getNode(["bounce"]).childNodes;
      var _loc2_ = _loc7_.length;
      var _loc8_ = 0;
      var _loc3_;
      var _loc6_;
      var _loc5_;
      var _loc4_;
      while(_loc2_--)
      {
         _loc3_ = "bounce" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.opp_mc.attachMovie("_bounce",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         _loc4_.typ = "bounce";
         this.bounceNum = this.bounceNum + 1;
      }
      _loc7_ = this.nodesXML.getNode(["speed"]).childNodes;
      _loc2_ = _loc7_.length;
      _loc8_ = 50;
      while(_loc2_--)
      {
         _loc3_ = "speed" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.opp_mc.attachMovie("_speed",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         _loc4_.typ = "speed";
         this.speedNum = this.speedNum + 1;
      }
      _loc7_ = this.nodesXML.getNode(["glide"]).childNodes;
      _loc2_ = _loc7_.length;
      _loc8_ = 100;
      while(_loc2_--)
      {
         _loc3_ = "glide" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.opp_mc.attachMovie("_glide",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         _loc4_.typ = "glide";
         this.glideNum = this.glideNum + 1;
      }
      _loc7_ = this.nodesXML.getNode(["wind"]).childNodes;
      _loc2_ = _loc7_.length;
      _loc8_ = 150;
      while(_loc2_--)
      {
         _loc3_ = "wind" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.opp_mc.attachMovie("_wind",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         this.windNum = this.windNum + 1;
      }
      _loc7_ = this.nodesXML.getNode(["slide"]).childNodes;
      _loc2_ = _loc7_.length;
      _loc8_ = 200;
      while(_loc2_--)
      {
         _loc3_ = "slide" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.opp_mc.attachMovie("_slide",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         _loc4_.typ = "slide";
         this.slideNum = this.slideNum + 1;
      }
      _loc7_ = this.nodesXML.getNode(["ring"]).childNodes;
      _loc2_ = _loc7_.length;
      _loc8_ = 250;
      this._$mc.createEmptyMovieClip("ringFront_mc",5000);
      while(_loc2_--)
      {
         _loc3_ = "ring" + _loc2_;
         _loc6_ = _loc7_[_loc2_].attributes.x;
         _loc5_ = _loc7_[_loc2_].attributes.y;
         _loc4_ = this._$mc.ringFront_mc.attachMovie("_ring",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
         _loc4_ = this._$mc.opp_mc.attachMovie("_ringBack",_loc3_,_loc8_ + _loc2_);
         _loc4_._x = _loc6_;
         _loc4_._y = _loc5_ - 1000;
      }
   }
   function getPos()
   {
      _root.pos_txt.text = Math.floor(this.bc._x) + ", " + Math.floor(this.bc._y);
   }
   function initSO(Void)
   {
      this._so = new CartoonSO("HamsterLaunch");
      if(this._so._info._bestScore == undefined)
      {
         this._so._info._bestScore = 0;
         this._so._info._careerScore = 0;
      }
      this._bestScore = this._so._info._bestScore;
   }
   function checkBestScore(s)
   {
      if(s > this._bestScore)
      {
         return true;
      }
      return false;
   }
   function saveBestScore(s)
   {
      this._bestScore = s;
      this._so._info._bestScore = this._bestScore;
   }
}

