MtTheme
=======

MtTheme is a simple theme engine for Cocoa's `NSView` and subclasses.  It works similar to a (simple) CSS.

The best way understand it is to look at the definition file format

```
#
# Comment
#

# style
NSClipView[identifier="chosen"].NSTextView # selector; no ident
    backgroundColor=#404040 # property; indented 4 spaces

MyTextView
NSTextView[isEditable=NO]
    isEditable=YES
```

A theme consists of multiple styles.

## Style ##

Each style consists of one (or more) selectors and a series of properties to apply if one of the selectors match.

The selectors are considered 'OR' matches, thus the style applies if any of the asociated selectors match.

When matching a `NSView` the theme engine iterates over the styles in order (first to last), all properties of matching styles are combined; thus causing properties on the matching styles later in the list/file to overwrite identical ones which matched first.

## Selector ##

A selector is a set of class names which are matched against the target `NSView` and it's parent e.g. `NSClipView.NSTextView` will match all `NSTextView`s with a `superview` of class `NSClipView`.

You can match all subclasses of a class by adding the `isKindOf` operator (>) to the end of the class name e.g. `NSView>` will match all NSView's and subclasses of it.

You can further restrict the scope of a selector by specifying attributes in `[]`.  Attributes are applied as 'AND' matches, thus all specified attributes must match for the selector to match.

Atributes are applied to the associated view e.g. `NSClipView[identifier="chosen"].NSTextView` checks that the `identifier` property of the superview of the target view is equal to the string "chosen".  You can use '.' seperated attribute names to delve deeper e.g. `NSTextView[superview.identifier="chosen"]` would also check that the `identifier` property of the superview of the target view is equal to the string "chosen".

Attribute values can be any valid property type

## Properties ##

Each style consists of a number of properties which are applied if the property matches e.g. `    isEditable=YES` sets the `isEditable` property of the target view to `YES`.

You can use '.' seperated property names set sub properties; similar to User Defined Runtime Attributes" in Interface builder e.g. `superview.identifier="another"` would set the target view's, superview's `identifier` property to the string "another".

Supported types for properties are:

Type      | Example
-------------------
NSString  | "example"
NSNumber  | 0.56, 0x56, 56
BOOL      | YES, NO
NSColor   | #FF0000
NSRange   | Range(0, 4) # XXX; Not Implemented Yet
NSRect    | Rect(0, 0, 100, 100) # XXX; Not Implemented Yet
NSPoint   | Point(0, 0) # XXX; Not Implemented Yet
NSSize    | Size(100, 100) # XXX; Not Implemented Yet

## Usage ##

First load a theme:

```
if (MtTheme.sharedTheme appendFromFile:@"test.mttheme"
                                 error:&error] == NO) {
    if (error.line != nil) {
        NSLog(@"%@", error.line);
        NSLog(@"%@", error.marker);
    }
    NSLog(@"%@", error);
}
```

Then at a suitable time update a view using one of the theme `update*` methods e.g.

```[theme updateWindow:_window];```

