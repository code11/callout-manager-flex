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

package com.code11.calloutmanager
{
	import com.code11.calloutmanager.data.CalloutProperties;
	import com.code11.calloutmanager.view.CalloutBase;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.core.IVisualElement;
	import mx.core.IVisualElementContainer;
	import mx.events.PropertyChangeEvent;
	import mx.resources.ResourceManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleClient;
	import mx.styles.IStyleManager2;
	
	import spark.components.Application;
	import spark.components.Button;
	import spark.components.PopUpAnchor;
	import spark.components.PopUpPosition;
	import spark.components.supportClasses.Skin;
	
	
	

	public class CalloutManager extends EventDispatcher {
		
		public static var ABSOLUTE:String = 'absolute';
		public static var RELATIVE:String = 'relative';
		
		public var calloutClass:Class;
		
		public var styleManager:IStyleManager2;
		public var showOncePerMachine:Boolean = false;
		public var localeName:String = "";
		
		private var managedViews:Dictionary;
		
		private var calloutData:Object = {}
		
		public var calloutSO:SharedObject;
		public var calloutsDisplayed:Object;
		public var openCallouts:Object = {};
		public var pendingCallouts:Object = {};
		
		private var _calloutsDisabled:Boolean = false;
		
		[Bindable]
		public function get calloutsDisabled():Boolean {
			return _calloutsDisabled
		}

		public function set calloutsDisabled(value:Boolean):void {
			_calloutsDisabled = value;
			if (value) closeAllCallouts();
			calloutsDisplayed = {};
			saveCalloutState();
		}

		
		public function CalloutManager() {
			managedViews = new Dictionary(true);
			
			calloutSO = SharedObject.getLocal("calloutSO");
			calloutsDisplayed = calloutSO.data.calloutsDiplayed || {};
			if (!calloutSO.data.calloutsDisabled) {
				calloutSO.data.calloutsDisabled = calloutsDisabled;
			} else {
				calloutsDisabled = calloutSO.data.calloutsDisabled;
			}
		}
		
		public function saveCalloutState():void {
			calloutSO.data.calloutsDiplayed = calloutsDisplayed;
			calloutSO.data.calloutsDisabled = calloutsDisabled;
			calloutSO.flush();
		}
		
		public function closeAllCallouts(e:Event = null):void {
			for (var key:String in openCallouts) {
				var c:CalloutBase = openCallouts[key];
				c.close();
			}
		}
		
		public function removeCallout(c:CalloutBase):void {
			if (openCallouts[c.calloutName] == c) delete openCallouts[c.calloutName];
		}
		
		public function addCallout(c:CalloutBase,calloutName:String):void {
			openCallouts[calloutName] = c;
			c.addEventListener(Event.CLOSE,calloutCloseHandler);
			c.addEventListener(CalloutBase.DISMISS,dismissCallouts);
			calloutsDisplayed[calloutName] = 1;
			saveCalloutState();
		}
		
		private function dismissCallouts(e:Event = null):void {
			calloutsDisabled = true;
		}
		
		private function calloutCloseHandler(e:Event):void {
			removeCallout(e.currentTarget as CalloutBase)
		}
		
	
		public function watch(view:IVisualElementContainer):void {
			(view as EventDispatcher).addEventListener(Event.ADDED,onAdded);
		}
		
		private function onAdded(e:Event):void {
			var tg:IStyleClient = e.target as IStyleClient;
			if (!tg || tg is Skin) return;
			manageView(tg);
		}
		
		
		public function manageView(view:IStyleClient,andChildren:Boolean = false):void {
			var calloutDataStyle:* = view.getStyle("calloutData");
			cleanUpView(view);
			if (calloutDataStyle) {
				managedViews[view] = [];
				if (!(calloutDataStyle is Array)) calloutDataStyle = [calloutDataStyle]
				for (var ei:int = 0; ei < calloutDataStyle.length; ei++) {
					var objectCalloutData:Array = calloutDataStyle[ei].split(',');
					if (objectCalloutData) {
						for (var i:int = 1; i < objectCalloutData.length; i++) {
							trace("MANAGING CALLOUT EVENT:",view,objectCalloutData[i].split("|")[0],objectCalloutData[i].split("|")[1]);
							var eventData:String = objectCalloutData[i];
							var eventType:String = eventData.split("|")[0];
							var eventAction:String = eventData.split("|")[1];
							managedViews[view].push(eventType);
							(view as EventDispatcher).addEventListener(eventType,handleCalloutEvent,false,0,true);
						}
					}
				}
			}
			if (andChildren && (view is IVisualElementContainer)) {
				var viewContainer:IVisualElementContainer = view as IVisualElementContainer
				for (var vci:int = 0; vci < viewContainer.numElements; vci++) {
					var viewChild:IStyleClient = viewContainer.getElementAt(vci) as IStyleClient;
					if (viewChild) manageView(viewChild,true);
				}
			}
		}
		
		public function cleanUpView(view:IStyleClient):void {
			if (!managedViews[view]) return;
			var handlers:Array = [];
			for (var hi:int = 0; hi < handlers.length; hi++) {
				(view as EventDispatcher).removeEventListener(handlers[hi],handleCalloutEvent);
			}
			delete managedViews[view];
		}
		
		
		private function handleCalloutEvent(e:Event):void {
			var calloutDataStyle:* = e.currentTarget.getStyle("calloutData");
			if (!calloutDataStyle) return;
			if (!(calloutDataStyle is Array)) calloutDataStyle = [calloutDataStyle]
			for (var ei:int = 0; ei < calloutDataStyle.length; ei++) {
				var objectCalloutData:Array = calloutDataStyle[ei].split(',')
				if (objectCalloutData) {
					for (var i:int = 1; i < objectCalloutData.length; i++) {
						var eventData:Array = objectCalloutData[i].split("|");
						var eventType:String = eventData[0];
						if (eventType != e.type) continue;
						var eventAction:String = eventData[1];
						var eventProperty:String = eventData[2];
						if (eventProperty && !(e is PropertyChangeEvent)) continue; 
						if (eventProperty) {
							if (eventProperty != (e as PropertyChangeEvent).property) continue;
							if ((e as PropertyChangeEvent).newValue == null) continue;
							if ((e as PropertyChangeEvent).newValue.hasOwnProperty("length") && (e as PropertyChangeEvent).newValue.length == 0) continue;
							if (eventData[3]) var eventPropertyValue:* = eventData[3];
							if (eventPropertyValue && (e as PropertyChangeEvent).newValue != eventPropertyValue) continue;
						}
						trace("EVENT ACTION",eventAction,objectCalloutData[0])
						switch (eventAction) {
							case "show":
								var container:IVisualElementContainer = e.currentTarget.parent as IVisualElementContainer;
								if (!container) return;
								pendingCallouts[objectCalloutData[0]] = setTimeout(showCalloutHandler,100,objectCalloutData[0],container,e.currentTarget);
								trace("SHOWING",objectCalloutData[0],eventData,eventType,eventProperty);
								break;
							case "hide":
								hideCalloutHandler(objectCalloutData[0]);
								break;
							case "hideall":
								closeAllCallouts();
								break;
						}
					}
				}
			}
			
		}
		
		public function showCalloutHandler(calloutName:String,target:IVisualElementContainer,view:IVisualElement):void {
			delete pendingCallouts[calloutName];
			if (showOncePerMachine && calloutsDisplayed[calloutName] == 1) return;
			if (calloutsDisabled ) return;
			if (openCallouts[calloutName]) {
				if (openCallouts[calloutName].view == view) return;
				openCallouts[calloutName].close();
			}
			if (!calloutData[calloutName]) {
				calloutData[calloutName] = getCalloutProps(calloutName);
			}
			var calloutProps:CalloutProperties = calloutData[calloutName];
			if (!calloutProps) return;
			
			var callout:CalloutBase = new calloutClass();
			callout.text = calloutProps.text;
			callout.calloutName = calloutName;
			callout.view = view;
			var anchor:PopUpAnchor = new PopUpAnchor();
			anchor.popUpPosition = calloutProps.direction;
			switch (calloutProps.position) {
				case ABSOLUTE:
					anchor.x = calloutProps.x;
					anchor.y = calloutProps.y;
					break;
				case RELATIVE:
					anchor.x = view.x + calloutProps.x;
					anchor.y = view.y + calloutProps.y;
					break;
			}
			anchor.popUp = callout;
			
			target.addElement(anchor);
			callout.anchor = anchor;
			callout.vArrowOffset = calloutProps.vArrowOffset || 0;
			callout.hArrowOffset = calloutProps.hArrowOffset || 0;
			anchor.displayPopUp = true;
			
			addCallout(callout,calloutName);
		}
		
		private function hideCalloutHandler(calloutName:String):void {
			if (openCallouts[calloutName]) 
				openCallouts[calloutName].close();
			if (pendingCallouts[calloutName]) {
				clearTimeout(pendingCallouts[calloutName]);
				delete pendingCallouts[calloutName];
			}
		}
		
		private function getCalloutProps(calloutId:String):Object {
			var calloutProps:Object = new CalloutProperties();
			var calloutStyleData:CSSStyleDeclaration = styleManager.getStyleDeclaration("."+calloutId);
			if (!calloutStyleData) return null;
			if (localeName) {
				calloutProps.text = ResourceManager.getInstance().getString(localeName,calloutStyleData.getStyle("text"));
			} else {
				calloutProps.text = calloutStyleData.getStyle("text");
			}
			calloutProps.x = calloutStyleData.getStyle("x");
			calloutProps.y = calloutStyleData.getStyle("y");
			calloutProps.direction = calloutStyleData.getStyle("direction");
			calloutProps.position = calloutStyleData.getStyle("position") || 'absolute';
			calloutProps.hArrowOffset = calloutStyleData.getStyle("hArrowOffset");
			calloutProps.vArrowOffset = calloutStyleData.getStyle("vArrowOffset");
			return calloutProps;
		}
		
	}
}