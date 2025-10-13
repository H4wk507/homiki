class CartoonSO
{
   var _$gameName;
   var _$so;
   static var _$USERS_SO = "CN_users";
   static var _$USERS_SO_PATH = "/";
   function CartoonSO(gName)
   {
      this._$gameName = gName;
      this._$so = SharedObject.getLocal(CartoonSO._$USERS_SO,CartoonSO._$USERS_SO_PATH);
   }
   function get _info()
   {
      if(this._$so.data[this._$gameName] == undefined)
      {
         this._$so.data[this._$gameName] = {};
      }
      return this._$so.data[this._$gameName];
   }
}

