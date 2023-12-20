Create folder 
C:\Users\DELL\source\repos\dhanman-timesheet\src\Core\Dhanman.TimeSheet.Domain\Entities\**Tasks** 
<img width="143" alt="image" src="https://github.com/b2atech/dhanman-docs/assets/91184041/06e939ca-32c8-4a8f-92d8-1b364834f5c6">

Create class
C:\Users\DELL\source\repos\dhanman-timesheet\src\Core\Dhanman.TimeSheet.Domain\Entities\Tasks\Task.cs
 


Create repository 
C:\Users\DELL\source\repos\dhanman-sales\src\Core\Dhanman.Sales.Domain\Abstractions\IInvoiceWorkflowRepository.cs
 

C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\Repositories\InvoiceWorkflowRepository.cs

If primary key is integer then do some changes in following files (For our project - sales, purchase, inventory already added)  
C:\Users\DELL\source\repos\dhanman-sales\src\Core\Dhanman.Sales.Application\Abstractions\Data\IApplicationDbContext.cs
GetBydIdIntAsync
C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\ApplicationDbContext.cs

C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\DependencyInjection.cs
add List line
