# Clean code principle - c#

## 1. Naming Matters

A good name allows code to be used by many developers. The name shoul reflect what it does and give context. Use Camel case notation for variables i.e., first letter of first word of variable will be lower case and followed other words will be upper case. Use Pascal case notation for Methods and Classes i.e., first letters of words should be Upper case

### Meanfull name

Bad:
```c#
int p;
```

Good:
```c#
int prices;
```

### Naming Classes
Bad:

```c#
Common
MyFunctions
Utility
WebsiteBL
```

Good:
```c#
User
Account
ProductRepository
```

### Naming Methods
Bad:
```c#
Started
Complete
DoIt
Page_Load
```

Good:
```c#
SendEmail
ExportExcel
IsValidAccount
GetAcccount
```

### Naming Booleans
Bad:
```c#
open
active
login
```

Good:
```c#
isOpen
isActive
loggedIn
```

## 2. Formatting
Code should be readability. For examples, indent style is space and tab in project
Bad
```c#
using System;
namespace ConsoleApp2
{ 
    internal class Program
    {static void Main(string[] args)
        {
     Console.WriteLine("Hello World!");
        }
    }
}
```

Good
Visual Studio has a built-in feature to format your code perfectly, by simply Press CTRL + K and CTRL + D

```c#
using System;
namespace ConsoleApp2
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
        }
    }
}
```

or by selecting Analyze and code cleanup -> run code cleanup
Code style options and code cleanup - Visual Studio (Windows)
Applies to: Visual Studio Visual Studio for Mac Visual Studio Code You can define code style settings per-project by…
[learn.microsoft.com](http://learn.microsoft.com/)
or by EditorConfig
```
root = true[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true# C# files
[*.cs]
indent_size = 4
# New line preferences
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_new_line_before_members_in_object_initializers = true
csharp_new_line_before_members_in_anonymous_types = true
csharp_new_line_within_query_expression_clauses = true# Code files
[*.{cs,csx,vb,vbx}]
indent_size = 4# Indentation preferences
csharp_indent_block_contents = true
csharp_indent_braces = false
csharp_indent_case_contents = true
csharp_indent_switch_labels = true
csharp_indent_labels = one_less_than_current# avoid this. unless absolutely necessary
dotnet_style_qualification_for_field = false:suggestion
dotnet_style_qualification_for_property = false:suggestion
dotnet_style_qualification_for_method = false:suggestion
dotnet_style_qualification_for_event = false:suggestion# only use var when it's obvious what the variable type is
# csharp_style_var_for_built_in_types = false:none
# csharp_style_var_when_type_is_apparent = false:none
# csharp_style_var_elsewhere = false:suggestion# use language keywords instead of BCL types
dotnet_style_predefined_type_for_locals_parameters_members = true:suggestion
dotnet_style_predefined_type_for_member_access = true:suggestion# name all constant fields using PascalCase
dotnet_naming_rule.constant_fields_should_be_pascal_case.severity = suggestion
dotnet_naming_rule.constant_fields_should_be_pascal_case.symbols = constant_fields
dotnet_naming_rule.constant_fields_should_be_pascal_case.style = pascal_case_styledotnet_naming_symbols.constant_fields.applicable_kinds = field
dotnet_naming_symbols.constant_fields.required_modifiers = constdotnet_naming_style.pascal_case_style.capitalization = pascal_case# static fields should have s_ prefix
dotnet_naming_rule.static_fields_should_have_prefix.severity = suggestion
dotnet_naming_rule.static_fields_should_have_prefix.symbols = static_fields
dotnet_naming_rule.static_fields_should_have_prefix.style = static_prefix_styledotnet_naming_symbols.static_fields.applicable_kinds = field
dotnet_naming_symbols.static_fields.required_modifiers = staticdotnet_naming_style.static_prefix_style.required_prefix = s_
dotnet_naming_style.static_prefix_style.capitalization = camel_case# internal and private fields should be _camelCase
dotnet_naming_rule.camel_case_for_private_internal_fields.severity = suggestion
dotnet_naming_rule.camel_case_for_private_internal_fields.symbols = private_internal_fields
dotnet_naming_rule.camel_case_for_private_internal_fields.style = camel_case_underscore_styledotnet_naming_symbols.private_internal_fields.applicable_kinds = field
dotnet_naming_symbols.private_internal_fields.applicable_accessibilities = private, internaldotnet_naming_style.camel_case_underscore_style.required_prefix = _
dotnet_naming_style.camel_case_underscore_style.capitalization = camel_case# Code style defaults
dotnet_sort_system_directives_first = true
csharp_preserve_single_line_blocks = true
csharp_preserve_single_line_statements = false# Expression-level preferences
dotnet_style_object_initializer = true:suggestion
dotnet_style_collection_initializer = true:suggestion
dotnet_style_explicit_tuple_names = true:suggestion
dotnet_style_coalesce_expression = true:suggestion
dotnet_style_null_propagation = true:suggestion# Expression-bodied members
csharp_style_expression_bodied_methods = false:none
csharp_style_expression_bodied_constructors = false:none
csharp_style_expression_bodied_operators = false:none
csharp_style_expression_bodied_properties = true:none
csharp_style_expression_bodied_indexers = true:none
csharp_style_expression_bodied_accessors = true:none# Pattern matching
csharp_style_pattern_matching_over_is_with_cast_check = true:suggestion
csharp_style_pattern_matching_over_as_with_null_check = true:suggestion
csharp_style_inlined_variable_declaration = true:suggestion# Null checking preferences
csharp_style_throw_expression = true:suggestion
csharp_style_conditional_delegate_call = true:suggestion# Space preferences
csharp_space_after_cast = false
csharp_space_after_colon_in_inheritance_clause = true
csharp_space_after_comma = true
csharp_space_after_dot = false
csharp_space_after_keywords_in_control_flow_statements = true
csharp_space_after_semicolon_in_for_statement = true
csharp_space_around_binary_operators = before_and_after
csharp_space_around_declaration_statements = do_not_ignore
csharp_space_before_colon_in_inheritance_clause = true
csharp_space_before_comma = false
csharp_space_before_dot = false
csharp_space_before_open_square_brackets = false
csharp_space_before_semicolon_in_for_statement = false
csharp_space_between_empty_square_brackets = false
csharp_space_between_method_call_empty_parameter_list_parentheses = false
csharp_space_between_method_call_name_and_opening_parenthesis = false
csharp_space_between_method_call_parameter_list_parentheses = false
csharp_space_between_method_declaration_empty_parameter_list_parentheses = false
csharp_space_between_method_declaration_name_and_open_parenthesis = false
csharp_space_between_method_declaration_parameter_list_parentheses = false
csharp_space_between_parentheses = false
csharp_space_between_square_brackets = false[*.{asm,inc}]
indent_size = 8# Xml project files
[*.{csproj,vcxproj,vcxproj.filters,proj,nativeproj,locproj}]
indent_size = 2# Xml config files
[*.{props,targets,config,nuspec}]
indent_size = 2[CMakeLists.txt]
indent_size = 2[*.cmd]
indent_size = 2
```

## 3. Commenting
Make proper comment where it is required. Don’t make zommie comment in code

```c#
using System;
namespace ConsoleApp2
{
    internal class Program
    {
        /// <summary>
        /// This is Main method to write console 
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
        }
    }
}
```

## 4. Reuse Code

Don’t copy-paste function through multiple classes. Rather make a shared library project and reference it in each of required projects. This way, we build reusable code.

## 5. Keep Class Size Small

According to single responsibitlity (one of SOLID priciple), make segregate classes to small blocks which has a single responsiblility functions only. This helps us to achieve loosely coupled code.

## 6. Avoid Magic Strings/Numbers
Magic string/number meaning do not use hardcoded strings or values in our application. This will difficult to track strings.
Bad:
```c#
if(userRole == "Admin")
{
   //logic here
}
```
Good:

```c#
const string ADMIN_ROLE = "Admin"
if(userRole == ADMIN_ROLE )
{
   //logic here
}
```

## 7. Use Async/Await

Asynchronous Programming helps improve the overall efficiency while dealing with functions that can take some time to finish computing. During such function executions, the complete application may seem to be frozen to the end-user. This results in bad user experience. In such cases, we use async methods to free the main thread
Read more [here](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/async/).

## 8. Don’t use ‘throw ex’ in the catch block
Don’t use ‘throw ex’ exception in catching block, this will lose stack trace data. Instead use ‘throw’, this will store the stack trace as well, which is kind of helps for diagnostics purposes.
And also don’t ignore caught errors
```c#
public void SomeMethod()
{
   try
   {
       DoSomething();
   }
   catch
   {

   }
}
```
Incase of WebAPI, use exception handle middleware

## 9. Avoid long if condition
Long IF/ELSE or long SWITCH (long conditional statement) with polymorphism. This is also called RIP design pattern. RIP means Replace If with Polymorphism design pattern
[Read more here.](https://www.c-sharpcorner.com/article/replace-conditional-statements-ifelse-or-switch-with-factory/)

Use Ternary Operator if it is for only one else condition
```c#
public string GetValue(int value)
{
   return value == 10 ? "Value is 10" : "Value is not 10";
}
```

## 10. Use Null Coalescing Operator
For null checks you can use null checks. ?? operator is known as Null Coalescing Operator in C#. [Read more here.](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/operators/null-coalescing-operator)

```c#
public Student SomeMethod(Student student)
{
   return student ?? new Student() { Name = "Mukesh Murugan" };
}
```

## 11.Prefer String Interpolation

Bad:
```c#
public string SomeMethod(Student student)
{
   return "Student Name is " + student.Name + ". Age is " + student.Age;
}
```
Good:
```c#
public string SomeMethod(Student student)
{
   return $"Student Name is {student.Name}. Age is {student.Age}";
}
```

## 12. Avoid too many parameters
If you want to send more then 3 parameter inputs to any mthoed, then wrap it object then pass
Bad:
```c#
public Student SomeMethod(string name, string city, int age, string section, DateTime dateOfBirth)
{
   return new Student()
   {
       Age = age,
       Name = name,
       //Other parameters too
   };
}
```
Good:
```c#
public Student SomeMethod(Student student)
{
   return student;
}
```

## 13. Use Design Patterns

Design Pattern is a way to solve a localised problem. Design pattern are basically patterns that can provide a resuable solution while architecting solutions.

## 14. Project structure
In order to favor scalability and loosely couple the solutions, we split them up to various layers like Application, Domain, Infrastructure, and so on. One the best example to use is DDD approach (with Clean Architecture)
Here are a few other advantages as well.
1. Reusability — If you want to use the same Project for another solution, you could do so.
2. Improved Security
3. Higly Maintainable
4. Scalable
5. Inversion of controls, etc

## 15. Use Expression Bodied Methods
Such methods are used in scenarios where the method body is much smaller than even the method definition itself

```c#
public string Message() => "Hello World!";
```
Read more about Expression Bodied Methods [here](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/statements-expressions-operators/expression-bodied-members).


