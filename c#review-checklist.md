# c# review checklist

## Naming Conventions
 - [ ] List item

## Source code file
 - [ ] Sort all the using statements (Organize Using)
 - [ ] Check if the code is structured in regions
 - [ ] Does the code work?
 - [ ] Don’t just ignore warnings
 - [ ] Check for SOLID, DRY, KISS principle opprtunities
 - [ ] Any dependency injection is missing?
 - [ ] Code Consistency e.g. int or Int32
 - [ ] Do care for Null all the times
       var first = person?.FirstName;
 - [ ] Dead code, remove commented, unreachable code
 - [ ] Large function alert (more than 20-30 lines)
 - [ ] More parameters to a function (more than 3-4 params)
 - [ ] One file shall not be more than 250-300 lines
 - [ ] Declare access specifiers explicitly (public, private, protected)
 - [ ] Use C# new language features, for example, use nameof operator to get the property/method names instead of hard coding it
      


    if (IsNullOrWhiteSpace(lastName))
        throw new ArgumentException(message: “Cannot be blank”, paramName: nameof(lastName));


  
 - [ ] if (IsNullOrWhiteSpace(lastName))

## Performance
 - [ ] Does it have a paged service endpoint?
 - [ ] Are we using foreach.parallel....
 - [ ] Are there local concurrency issues?


## Unit Test cases
