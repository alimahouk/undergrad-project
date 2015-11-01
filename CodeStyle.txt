----------------------------
| Code Style & Conventions |
----------------------------

DO NOT use Hungarian Notation. Ever.

Be verbose in the way you name everything. CopyString() is much more obvious that strcpy().

Use typically trailing braces everywhere (if, else, functions, structures, typedefs, class definitions, etc.)
      if ( x ) 
      {
      }

The else statement starts on the line after the last closing brace.
      if ( x ) 
      {
      }
      else
      {
      }

Pad parenthesized expressions with spaces
      if ( x )
      {
      }
Instead of
      if (x)
      {
      }
And
      x = ( y * 0.5f );
Instead of
      x = (y * 0.5f);

In multi-word function names each word starts with an upper case:
      void ThisFunctionDoesSomething( void );

The standard header for functions is:
      /*
      ====================
      FunctionName
	
      Description
      ====================
      */

Variable names start with a lower case character.
      float x;

In multi-word variable names the first word starts with a lower case character and each successive word starts with an upper case.
      float maxDistanceFromPlane;

Defined names use all upper case characters. Multiple words are separated with an underscore.
      #define SIDE_FRONT 0
--------
COMMENTS
--------
Use proper grammar in all comments. End them with periods, exclamation marks, etc.
	// Use this style for single line comments.
/*
 * This style for multiline comments.
 */
If your comment goes beyond the width of half your editor screen, you should probably break it up into multiple lines. Try to make all lines the same width to aid readability.
-------
CLASSES
-------
The standard header for a class is:
       /*
       =======================================================================
       ========
       Description
       =======================================================================
       ========
       */

Class names start with "PM" and each successive word starts with an upper case.
      class PMVec3;

Class variables have the same naming convention as variables.
      class PMVec3
      {
      float x;
      float y;
      float z;
      }

Class methods have the same naming convention as functions.
      class PMVec3
      {
      float Length( void ) const;
      }

Indent the names of class variables and class methods to make nice columns. The variable type or method return type is in the first column and the variable name or method name is in the second column.
      class PMVec3
      {
      float x;
      float y;
      float z;
      float Length( void ) const;
      const float* ToFloatPtr( void ) const;
      }
The * of the pointer is in the first column because it improves readability when considered part of the type.

Ordering of class variables and methods should be as follows:
1. list of friend classes
2. public variables
3. public methods
4. protected variables
5. protected methods
6. private variables
7. private methods
This allows the public interface to be easily found at the beginning of the class.

Unless ordering matters, variables listed everywhere are ordered alphabetically, starting with the type name, then the variable name.
	float color;
      float precision;
      int sequence;
      string name;

This applies to methods as well, except for the following types of methods:
* inits: these are the first thing in every class file.
* Overrides: these always go at the bottom.
However, the ordering within the sections still goes alphabetically.

Abbreviations are written in uppercase:
	string URLResponse;

Function overloading should be avoided in most cases. For example, instead of:
const PMAnim* GetAnim( int index ) const;
const PMAnim* GetAnim( const char *name ) const;
const PMAnim* GetAnim( float randomDiversity ) const;
Use:
const PMAnim* GetAnimByIndex( int index ) const;
const PMAnim* GetAnimByName( const char *name )
const;
const PMAnim* GetRandomAnim( float randomDiversity )
const;

--------------
User Interface
--------------
Append the type of the UI element to its name.
	PMButton *loginButton;
	PMLabel  *nameLabel;

Reminder: DO NOT use Hungarian Notation.
----------
FILE NAMES
----------
Each class should be in a seperate source file unless it makes sense to group several smaller classes.
The file name should be the same as the name of the class without the "PM" prefix. (Upper/lower case is preserved.)
      class PMWinding;
Files:
      Winding.cpp
      Winding.h
When a class spans across multiple files these files have a name that starts with the name of the class without "PM", followed by an underscore and a subsection name.
      class PMRenderWorld;
Files:
      RenderWorld_load.cpp
      RenderWorld_demo.cpp
      RenderWorld_portals.cpp
