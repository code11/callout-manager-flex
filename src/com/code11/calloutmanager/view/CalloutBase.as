////////////////////////////////////////////////////////////////////////////////
//
//  CODE11.COM
//  Copyright 2011
//  All Rights Reserved.
//
//  @author		Romeo Copaciu romeo.copaciu@code11.com
//  @date		23 March 2011
//  @version	1.0
//  @site		code11.com
//
////////////////////////////////////////////////////////////////////////////////

package com.code11.calloutmanager.view
{
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.core.IVisualElement;
	import mx.core.IVisualElementContainer;
	
	import spark.components.Group;
	import spark.components.PopUpAnchor;
	
	public class CalloutBase extends Group
	{
		
		public static const DISMISS:String = "dismiss";
		private var _text:String = "test";
		[Bindable]
		public function get text():String
		{
			return _text;
		}
		
		public function set text(value:String):void
		{
			_text = value;
		}
		
		public var anchor:PopUpAnchor;
		public var view:IVisualElement;
		
		
		public var calloutName:String;
		public var vArrowOffset:Number = 0;
		public var hArrowOffset:Number = 0;
		
		public var timeoutID:int;
		public function close(e:Event = null):void {
			clearTimeout(timeoutID);
			remove();
		}
		
		public function remove():void {
			if (anchor && anchor.parent) (anchor.parent as IVisualElementContainer).removeElement(anchor);
			if (anchor) anchor.displayPopUp = false;
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		protected function atsHandler(event:Event):void {
			timeoutID = setTimeout(close,25000);
		}
		
		public function CalloutBase() {
			super();
		}
	}
}