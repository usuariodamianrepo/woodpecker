param(
	[Parameter(Mandatory = $true, HelpMessage = "Provide the Project Name.")]
    [ValidateNotNullOrEmpty()]
	[string]$ProjectName,
	[Parameter(Mandatory = $true, HelpMessage = "Provide the Entity Name.")]
    [ValidateNotNullOrEmpty()]
	[string]$EntityName
)

<# CORE solution #>
$entityContent = @"
namespace $ProjectName.Core.Entities
{
    public class $EntityName
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
    }
}
"@

New-Item -Path "$ProjectName.Core/Entities/$EntityName.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Entities/$EntityName.cs" -Value $entityContent

$entityRepositoryName = -join("I", $EntityName, "Repository")
$entityRepository = @"
namespace $ProjectName.Core.Interfaces.Repositories
{
    public interface $entityRepositoryName : IBaseRepository<$EntityName>
    {
    }
}
"@

New-Item -Path "$ProjectName.Core/Interfaces/Repositories/$entityRepositoryName.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/Repositories/$entityRepositoryName.cs" -Value $entityRepository

$iEntityServiceName = -join("I" + $EntityName + "Service")
$iEntityService = @"
namespace $ProjectName.Core.Interfaces.Services
{
    public interface $iEntityServiceName
    {
        Task<$EntityName> GetById(int id);
        Task<IEnumerable<$EntityName>> GetAll();
        Task<$EntityName> Create($EntityName newItem);
        Task<$EntityName> Update(int toBeUpdatedId, $EntityName newValues);
        Task Delete(int id);
    }
}
"@

New-Item -Path "$ProjectName.Core/Interfaces/Services/$iEntityServiceName.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/Services/$iEntityServiceName.cs" -Value $iEntityService

<# Infrastructure solution #>
$iRepositoryName = -join("I" + $EntityName + "Repository")
$repositoryName = -join($EntityName + "Repository")
$repositoryFile = @"
namespace $ProjectName.Infrastructure.Repositories
{
    public class $repositoryName : BaseRepository<$EntityName>, $iRepositoryName
    {
        public $repositoryName(AppDbContext context) : base(context)
        {

        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Repositories/$repositoryName.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Repositories/$repositoryName.cs" -Value $repositoryFile

<# Service solution #>
$entityServiceName = -join($EntityName + "Service")
$entityService = @"
namespace $ProjectName.Services
{
    public class $entityServiceName : $iEntityServiceName
    {
        private readonly IUnitOfWork _unitOfWork;
        public $entityServiceName(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<$EntityName> Create($EntityName newEntiry)
        {
            //EntityNameValidator validator = new();

            //var validationResult = await validator.ValidateAsync(newEntiry);
            //if (validationResult.IsValid)
            //{
                await _unitOfWork.$repositoryName.AddAsync(newEntiry);
                await _unitOfWork.CommitAsync();
            //}
            //else
            //{
            //    throw new ArgumentException(validationResult.Errors.ToString());
            //}

            return newEntiry;
        }

        public async Task Delete(int id)
        {
            $EntityName toBeDelete = await _unitOfWork.$repositoryName.GetByIdAsync(id);
            if(toBeDelete == null)
                throw new ArgumentException($"The $EntityName Id:{id} not found.");

            _unitOfWork.$repositoryName.Remove(toBeDelete);
            await _unitOfWork.CommitAsync();
        }

        public async Task<IEnumerable<$EntityName>> GetAll()
        {
            return await _unitOfWork.$repositoryName.GetAllAsync();
        }

        public async Task<$EntityName> GetById(int id)
        {
            return await _unitOfWork.$repositoryName.GetByIdAsync(id);
        }

        public async Task<$EntityName> Update(int toBeUpdatedId, $EntityName newValues)
        {
            //CityValidator cityValidator = new();

            //var validationResult = await cityValidator.ValidateAsync(newValues);
            //if (!validationResult.IsValid)
            //    throw new ArgumentException(validationResult.Errors.ToString());

            $EntityName toBeUpdated = await _unitOfWork.$repositoryName.GetByIdAsync(toBeUpdatedId);

            if (toBeUpdated == null)
                throw new ArgumentException($"Invalid $EntityName Id:{toBeUpdatedId} while updating");

            toBeUpdated.Name = newValues.Name;
            toBeUpdated.Description = newValues.Description;

            await _unitOfWork.CommitAsync();

            return await _unitOfWork.$repositoryName.GetByIdAsync(toBeUpdatedId);
        }
    }
}
"@

New-Item -Path "$ProjectName.Services/$entityServiceName.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Services/$entityServiceName.cs" -Value $entityService


Write-Host "Congratulations! the $EntityName entity was created successfully"
