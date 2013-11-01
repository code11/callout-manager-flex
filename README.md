callout-manager-flex
====================
Have you ever worked on a application and just when you think you're done you realize you forgot to add some important information. Even if you haven't you might find this piece of code useful.

Now let me tell you from the start that this code was created for specific needs and might not work in some scenarios. At least not at this point. We will improve it in the future if there's a lot of request or the need arises.

It works by adding another layer to a Flex application that links to various events and displays or removes callouts when those events take place. 

It's designed in such a way that developers don't have to touch the existing application code much, all it requires is a new css file or just some more lines in the old css file and a few lines of code anywhere into your application that initialized the CalloutManager.

This is how the the callout manager is initialized:
```actionscript
public var calloutManager:CalloutManager; 
protected function onCreationCompleteHandler(event:FlexEvent):void { 
     calloutManager = new CalloutManager(); 
     calloutManager.styleManager = styleManager;
     calloutManager.manageView(this,true); 
     calloutManager.watch(this); 
     calloutManager.calloutClass = Callout; 
}
```

And this is a sample of some css:
```css
s|ToggleButton#enable {
      calloutData:"disabledinfo,rollOver|show","disabledinfo,rollOut|hide";
}
.disabledinfo{
     text:"Callout text";
     x:100;
     y:0;
     hArrowOffset:-50;
     direction:"below";
     position:"relative";
}
```

Now let me explain what all that means.

The ToggleButton that has the id "enable" triggers 2 actions on the rollOver and rollOut events. 

The calloutmanager gets the data from the "disabledinfo" info and show a callout when the user rolls over that button and removes the callout when the user rolls out.

Complete syntax is as follows:
```actionscript
calloutData: calloutname,eventToListenTo|action|property|value;
```
calloutname represents the css class name the callout manager get data from
property and value are optional and only needed when eventToListenTo is "propertyChangedEvent".

Possible actions: ``` show, hide, hideall ```
```
 show: shows a callout with the specified name.
 hide: hides the callout with the specified name.
 hideall: hides all visible callouts.
```
[A working demo](http://code11.com/lab/experiments/flex/callout-manager/)

[Example project](https://github.com/code11/callout-manager-flex-example/)

The manager also saves the state of the displayed callouts into a SharedObject. It might support different users in future versions.

The callout is just a group that can be extended and skinned if anyone chooses to. Or that someone can just change the background images, fonts and font color to make the callouts fit into their application design.

It can also retrieve the text based on locale, but that can be easily implemented in the callout view also.

Feel free to use and modify the code at your leisure.
