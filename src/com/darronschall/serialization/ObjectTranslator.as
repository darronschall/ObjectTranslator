/*
 * Copyright (c) 2006 Darron Schall <darron@darronschall.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
package com.darronschall.serialization
{

import flash.net.ObjectEncoding;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.describeType;
import flash.utils.getDefinitionByName;

/**
 * Utility class to convert vanilla objects to class instances.
 */
public final class ObjectTranslator
{
	/**
	 * Returns whether or not the given object is simple data type.
	 *
	 * @param the object to check
	 * @return true if the given object is a simple data type; false if not
	 */
	public static function isSimple(object:Object):Boolean 
	{
		if(!object)
			return true;
		
		switch (typeof(object)) 
		{
			case "number":
			case "string":
			case "boolean":
				return true;
			case "object":
				return (object is Date) || (object is Array);
		}
		
		return false;
	}
	
	/**
	 * Converts a plain vanilla object to be an instance of the class
	 * passed as the second variable.  This is not a recursive funtion
	 * and will only work for the first level of nesting.  When you have
	 * deeply nested objects, you first need to convert the nested
	 * objects to class instances, and then convert the top level object.
	 * 
	 * TODO: This method can be improved by making it recursive.  This would be 
	 * done by looking at the typeInfo returned from describeType and determining
	 * which properties represent custom classes.  Those classes would then
	 * be registerClassAlias'd using getDefinititonByName to get a reference,
	 * and then objectToInstance would be called on those properties to complete
	 * the recursive algorithm.
	 * 
	 * @param object The plain object that should be converted
	 * @param clazz The type to convert the object to
	 */
	public static function objectToInstance( object:Object, clazz:Class ):*
	{
		// Resolve accessors and clazz information
		// Register all of the classes so they can be decoded via AMF
		var typeInfo:XML = describeType(clazz);
		var fullyQualifiedName:String = typeInfo.@name.toString().replace(/::/, ".");
		
		
		//Recursively resolve internal complex classes first
		var accessors : XMLList = typeInfo..accessor.(@access == "readwrite");
		var isComplex : Boolean;
		var complexClazz : Class;
		var complexClazzFullyQualifiedName : String;
		var arrayElementType : String;
		for each(var accessor : XML in accessors)
		{
			isComplex = !isSimple(object[accessor.@name]);
			
			if(isComplex)
			{
				complexClazzFullyQualifiedName = accessor.@type.toString().replace(/::/, ".");
				complexClazz = getDefinitionByName(complexClazzFullyQualifiedName) as Class;
				registerClassAlias(complexClazzFullyQualifiedName, complexClazz);
				object[accessor.@name] = objectToInstance(object[accessor.@name], complexClazz);
			}
			else
			{
				var typeNode : XMLList = accessor.metadata.(@name=='ArrayElementType');
				
				arrayElementType = typeNode.arg.(@key == "").@value;
				if(arrayElementType!='')
				{
					var objArray : Array = object[accessor.@name]; 
					var resultArray : Array = [];
					for each(var elem : Object in objArray)
					{
						complexClazz = getDefinitionByName(arrayElementType) as Class;
						resultArray.push(objectToInstance(elem, complexClazz));
					}
					
					object[accessor.@name] = resultArray;
				}
			}
		}
		
		// Find the objects and byetArray.writeObject them, adding in the
		// class configuration variable name -- essentially, we're constructing
		// and AMF packet here that contains the class information so that
		// we can simply byteArray.readObject the sucker for the translation
		
		var bytes:ByteArray = new ByteArray();
		bytes.objectEncoding = ObjectEncoding.AMF0;
		
		// Write out the bytes of the original object
		var objBytes:ByteArray = new ByteArray();
		objBytes.objectEncoding = ObjectEncoding.AMF0;
		objBytes.writeObject(object);
		registerClassAlias(fullyQualifiedName, clazz);
		
		// Write the new object information starting with the class information
		var len:int = fullyQualifiedName.length;
		bytes.writeByte(0x10); // 0x10 is AMF0 for "typed object (class instance)"
		bytes.writeUTF(fullyQualifiedName);
		// After the class name is set up, write the rest of the object
		bytes.writeBytes(objBytes, 1);
		
		// Read in the object with the class property added and return that
		bytes.position = 0;
		
		// This generates some ReferenceErrors of the object being passed in
		// has properties that aren't in the class instance, and generates TypeErrors
		// when property values cannot be converted to correct values (such as false
		// being the value, when it needs to be a Date instead).  However, these
		// errors are not thrown at runtime (and only appear in trace ouput when
		// debugging), so a try/catch block isn't necessary.  I'm not sure if this
		// classifies as a bug or not... but I wanted to explain why if you debug
		// you might seem some TypeError or ReferenceError items appear.
		var result:* = bytes.readObject();
		return result;
	}
	
} // end class
} // end package
