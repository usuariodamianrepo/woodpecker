param(
	[parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
	[string]$ProjectName
)

<# create solution #>
dotnet new solution

<# create the projects #>
dotnet new webapi -o "$ProjectName.Web"
New-Item -ItemType Directory -Path "$ProjectName.Web/Dtos"
New-Item -ItemType Directory -Path "$ProjectName.Web/Extensions"

dotnet new classlib -o "$ProjectName.Core"
New-Item -ItemType Directory -Path "$ProjectName.Core/Dtos"
New-Item -ItemType Directory -Path "$ProjectName.Core/Entities/Repositories"
New-Item -ItemType Directory -Path "$ProjectName.Core/Entities/Services"
New-Item -ItemType Directory -Path "$ProjectName.Core/Entities/Shared"
New-Item -ItemType Directory -Path "$ProjectName.Core/Interfaces"

dotnet new classlib -o "$ProjectName.Services"
New-Item -ItemType Directory -Path "$ProjectName.Services/Validations"

dotnet new classlib -o "$ProjectName.Infrastructure"
New-Item -ItemType Directory -Path "$ProjectName.Infrastructure/Data"
New-Item -ItemType Directory -Path "$ProjectName.Infrastructure/Repositories"
New-Item -ItemType Directory -Path "$ProjectName.Infrastructure/Services"

<# add the projects to the solution #>
dotnet sln add "$ProjectName.Web/$ProjectName.Web.csproj"
dotnet sln add "$ProjectName.Core/$ProjectName.Core.csproj"
dotnet sln add "$ProjectName.Services/$ProjectName.Services.csproj"
dotnet sln add "$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj"

<# add the references #>
dotnet add "$ProjectName.Web/$ProjectName.Web.csproj" reference "$ProjectName.Core/$ProjectName.Core.csproj"
dotnet add "$ProjectName.Web/$ProjectName.Web.csproj" reference "$ProjectName.Services/$ProjectName.Services.csproj"
dotnet add "$ProjectName.Web/$ProjectName.Web.csproj" reference "$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj"
dotnet add "$ProjectName.Infrastructure/$ProjectName.Infrastructure.csproj" reference "$ProjectName.Core/$ProjectName.Core.csproj"
dotnet add "$ProjectName.Services/$ProjectName.Services.csproj" reference "$ProjectName.Core/$ProjectName.Core.csproj"

Write-Host "Congratulations! the $ProjectName successfully"

dotnet build

