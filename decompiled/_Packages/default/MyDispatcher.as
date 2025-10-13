class MyDispatcher
{
   var dispatchEvent;
   function MyDispatcher()
   {
      mx.events.EventDispatcher.initialize(this);
   }
   function disOnDone()
   {
      this.dispatchEvent({type:"onDone"});
   }
   function disOnUpdate()
   {
      this.dispatchEvent({type:"onUpdate"});
   }
}

