# Create Entity Task 

## Create folder
- C:\Users\DELL\source\repos\dhanman-timesheet\src\Core\Dhanman.TimeSheet.Domain\Entities\Tasks 

![image](https://github.com/b2atech/dhanman-docs/assets/91184041/06e939ca-32c8-4a8f-92d8-1b364834f5c6)

## Create class
- C:\Users\DELL\source\repos\dhanman-timesheet\src\Core\Dhanman.TimeSheet.Domain\Entities\Tasks\Task.cs

![image](https://github.com/b2atech/dhanman-docs/assets/91184041/291c7ff7-4dce-4a5a-91d4-10d570dd9a81)

Code for above class 
 
```using B2aTech.CrossCuttingConcern.Core.Abstractions;
using B2aTech.CrossCuttingConcern.Core.Primitives;

namespace Dhanman.TimeSheet.Domain.Entities.Tasks;

public class Task : Entity, IAuditableEntity, ISoftDeletableEntity
{

    #region Properties
    public Guid ProjectId { get; set; }
    public Guid ParentTaskId { get; set; }
    public string Name { get; set; }
    public int PlannedHours { get; set; }
    public DateTime CreatedOnUtc { get; }
    public DateTime? ModifiedOnUtc { get; set; }
    public DateTime? DeletedOnUtc { get; }
    public bool IsDeleted { get; set; }
    public Guid CreatedBy { get; set; }
    public Guid? ModifiedBy { get; set; }
    #endregion

    #region Constructor
    public Task(Guid projectId, Guid parentTaskId, string name, int plannedHours, DateTime createdOnUtc, Guid createdBy)
    {
        ProjectId = projectId;
        ParentTaskId = parentTaskId;
        Name = name;
        PlannedHours = plannedHours;
        CreatedOnUtc = createdOnUtc;
        CreatedBy = createdBy;
    }
    #endregion
}
```
## Create repository 

 
C:\Users\DELL\source\repos\dhanman-sales\src\Core\Dhanman.Sales.Domain\Abstractions\IInvoiceWorkflowRepository.cs
 

C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\Repositories\InvoiceWorkflowRepository.cs

If primary key is integer then do some changes in following files (For our project - sales, purchase, inventory already added)  
C:\Users\DELL\source\repos\dhanman-sales\src\Core\Dhanman.Sales.Application\Abstractions\Data\IApplicationDbContext.cs
GetBydIdIntAsync
C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\ApplicationDbContext.cs

C:\Users\DELL\source\repos\dhanman-sales\src\Infrastructure\Dhanman.Sales.Persistence\DependencyInjection.cs
add List line
