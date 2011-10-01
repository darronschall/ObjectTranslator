ObjectTranslator
=============

ObjectTranslator is a utility class I wrote when ActionScript 3 was brand new.  It converts generic ActionScript 3 objects into class instances.

This code originally comes from a weblog entry in October of 2006, now archived at http://archive.darronschall.com/weblog/2006/10/convert-generic-objects-into-class-instances.html

Usage
-----

Usage is as follows:

    import com.darronschall.examples.vo.Book;
    import com.darronschall.serialization.ObjectTranslator;

    // Define an object with properties that mimic the variable names
    // inside of the Book class
    var bookObj:Object = { title: "My Book title", pageCount: 10, inLibrary: true };

    // Convert the generic object into an instance of the Book class
    var book:Book = ObjectTranslator.objectToInstance( bookObj, Book ) as Book;

Limitations
-----

The code is not yet recursive (feel free to fork, implement, and submit a pull request!).  If you have nested value objects that you're converting to class instances, you'll have to manually go through the object graph:

    import com.darronschall.examples.vo.Book;
    import com.darronschall.examples.vo.Student;
    import com.darronschall.serialization.ObjectTranslator;

    var studentObj:Object = { firstName: "test first",
  				  lastName: "test last",
					  favoriteBook: { title: "Favorite Book!" }
					};	
								
    // First we need to convert the nested objects to classes
    studentObj.favoriteBook = ObjectTranslator.objectToInstance( studentObj.favoriteBook, Book );
		
    // Convert the student object to a Student class
    var student:Student = ObjectTranslator.objectToInstance( studentObj, Student ) as Student;