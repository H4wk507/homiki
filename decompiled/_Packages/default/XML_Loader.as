class XML_Loader extends XML
{
   var _callbackFunction;
   var _callbackParent;
   var firstChild;
   function XML_Loader(sXML)
   {
      super();
      this.ignoreWhite = true;
      if(sXML)
      {
         this.parseXML(sXML);
      }
   }
   function setXML(sXML)
   {
      this.parseXML(sXML);
   }
   function getXML(sURL, callbackParent, callbackFunction)
   {
      this._callbackFunction = callbackFunction;
      this._callbackParent = callbackParent;
      this.load(sURL);
   }
   function onLoad(success)
   {
      if(!success)
      {
         _root.onError("Could not load XML");
      }
      this._callbackParent[this._callbackFunction].apply(this._callbackParent,[this]);
   }
   function getNode(nodeNamesAr)
   {
      var _loc5_;
      var _loc3_ = nodeNamesAr.shift();
      var _loc2_ = this.firstChild.firstChild;
      while(_loc2_ != null)
      {
         if(_loc2_.nodeName == _loc3_)
         {
            if(nodeNamesAr.length == 0)
            {
               _loc5_ = _loc2_;
               break;
            }
            _loc2_ = _loc2_.firstChild;
            _loc3_ = nodeNamesAr.shift();
         }
         else
         {
            _loc2_ = _loc2_.nextSibling;
         }
      }
      return _loc5_;
   }
}

