First create template in folder named .template.config as 

<img width="210" alt="image" src="https://github.com/b2atech/dhanman-docs/assets/91184041/036dd219-b34d-4d0e-a8d8-4b8ff1b7e741">

<img width="318" alt="image" src="https://github.com/b2atech/dhanman-docs/assets/91184041/56dbdb3e-e7bd-45a5-b73f-075258cfe9a7">

template.json
{
    "author": "Bhalchandra",
    "classifications": [
        "Web"
    ],
    "description": "Dhanman Application",
    "name": "Dhanman Clean Architecture", 
    "identity": "MyProject.StarterWeb",
    "tags":{
        "language": "C#"
    },
    "shortName": "DhanmanCleanArch",
    "sourceName": "Dhanman.Sales",
    "preferNameDirectory": "true"
}

**For create template**   C:\Users\DELL\source\repos\dhanman-sales>dotnet new --install ./
**For uninstall template**  C:\Users\DELL\source\repos\dhanman-sales>dotnet new uninstall C:\Users\DELL\source\repos\dhanman-sale
**For create project** C:\Users\DELL\source\repos>dotnet new DhanmanCleanArch -o dhanman.timesheet

