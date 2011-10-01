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

import com.darronschall.examples.vo.Book;
import com.darronschall.examples.vo.Student;

import flexunit.framework.TestCase;

/**
 * The test methods for the ObjectTranslator class
 */
public class ObjectTranslatorTest extends TestCase
{

	public function ObjectTranslatorTest( methodName:String = null )
	{
		super( methodName );
	}
	
	/**
	 * Test to make sure an object with basic properties converts
	 * successfully
	 */
	public function testDecodeBook():void
	{
		var publishedDate:Date = new Date( 2006, 2, 20 );
		
		var bookObj:Object = { title: "My Book title", 
							   pageCount: 10, 
							   publishedDate: publishedDate,
							   inLibrary: true,
							   random: [0,{test:1},2,3] };
		
		var book:Book = ObjectTranslator.objectToInstance( bookObj, Book ) as Book;
		assertNotNull( book );
		assertTrue( "book is Book?",  book is Book );
		assertEquals( "My Book title", book.title );
		assertEquals( 10, book.pageCount );
		assertEquals( publishedDate.toDateString(), book.publishedDate.toDateString() );
		assertTrue( "correct inLibrary flag?", book.inLibrary );
		assertNotNull( book.random );
		assertEquals( 0, book.random[0] );
		assertEquals( 1, book.random[1].test );
		assertEquals( 2, book.random[2] );
		assertEquals( 3, book.random[3] );
	}
	
	/**
	 * Test to make sure an object with "extra" properties does not
	 * interfere with the translation, and that the default values
	 * are set correct for the class instance.
	 */
	public function testDecodeWithExtraPropsNotInClass():void
	{
		var bookObj:Object = { title: "My Book title",
							   someProp1: true,
							   someProp2: "hello",
							   someProp3: { test: "test" },
							   someProp4: [ 1, false, "world", { foo: "bar" } ] };
		
		var book:Book = ObjectTranslator.objectToInstance( bookObj, Book ) as Book;
		assertNotNull( book );
		assertTrue( "book is Book?",  book is Book );
		assertEquals( "My Book title", book.title );
		assertEquals( 0, book.pageCount ); // verify default value
	}
	
	/**
	 * Test to make sure nested classes can be decoded correctly
	 */
	public function testDecodeWithNestedClasses():void
	{
		var studentObj:Object = { firstName: "test first",
								  lastName: "test last",
								  books: [
								  		{ title: "Book 1" },
								  		{ title: "Book 2" } ],
								  favoriteBook: { title: "Favorite Book!" }
								};	
								
		// First we need to convert the nested objects to classes
		studentObj.favoriteBook = ObjectTranslator.objectToInstance( studentObj.favoriteBook, Book );
		
		// Convert the student object to a Student class
		var student:Student = ObjectTranslator.objectToInstance( studentObj, Student ) as Student;
		// For all of the book objects in the books array, convert those to
		// Book instances - this can be done after the student is made
		for ( var i:int = 0; i < student.books.length; i++ )
		{
			var book:Book = ObjectTranslator.objectToInstance( student.books[i], Book ) as Book;
			// Use the converted class instance in place of the regular object
			student.books[i] = book;
		}
		
		assertNotNull( student );
		assertTrue( "student is Student?",  student is Student );
		assertEquals( "test first", student.firstName );
		assertEquals( "test last", student.lastName );
		assertEquals( 2, student.books.length );
		assertTrue( "nested objects in array are books?", student.books[0] is Book );
		assertTrue( "nested objects in array are books?", student.books[1] is Book );
		assertTrue( "nested book object has correct title?", Book( student.books[0] ).title == "Book 1" );
		assertNotNull( student.favoriteBook );
		assertTrue( "favoriteBook is a Book?", student.favoriteBook is Book );
		assertTrue( "favoriteBook correct title?", student.favoriteBook.title == "Favorite Book!" );
	}
	
	/**
	 * Test to make sure that the wrong default data types still produce
	 * OK results.
	 */
	public function testDecodeIncorrectDataTypes():void
	{
		var bookObj:Object = { title: [0,1,2], 
							   pageCount: 123.9, 
							   publishedDate: false,
							   inLibrary: "test" };
		
		var book:Book = ObjectTranslator.objectToInstance( bookObj, Book ) as Book;
		assertNotNull( book );
		assertTrue( "book is Book?",  book is Book );
		// Everything is converted to the default values as best as possible
		// by the Player - i.e. title becomes "0,1,2", pageCount is 123,
		// publishedDate is null, and inLibrary is true
		assertEquals( "0,1,2", book.title );
		assertEquals( 123, book.pageCount );
		assertNull( book.publishedDate );
		assertTrue( book.inLibrary );
	}
        
} // end class
} // end package