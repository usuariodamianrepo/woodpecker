$MainName = "Zero"

<# create solution #>
dotnet new solution

<# create the projects #>
dotnet new webapi -o "$MainName.Web"

dotnet new classlib -o "$MainName.Core"
mkdir "$MainName.Core/Dtos"
mkdir "$MainName.Core/Entities"
mkdir "$MainName.Core/Interfaces"

dotnet new classlib -o "$MainName.Services"
mkdir "$MainName.Services/Validations"

dotnet new classlib -o "$MainName.Infrastructure"
mkdir "$MainName.Infrastructure/Data"
mkdir "$MainName.Infrastructure/Repositories"
mkdir "$MainName.Infrastructure/Services"

<# add the projects to the solution #>
dotnet sln add "$MainName.Web/$MainName.Web.csproj"
dotnet sln add "$MainName.Core/$MainName.Core.csproj"
dotnet sln add "$MainName.Services/$MainName.Services.csproj"
dotnet sln add "$MainName.Infrastructure/$MainName.Infrastructure.csproj"

<# add the references #>
dotnet add "$MainName.Web/$MainName.Web.csproj" reference "$MainName.Core/$MainName.Core.csproj"
dotnet add "$MainName.Web/$MainName.Web.csproj" reference "$MainName.Services/$MainName.Services.csproj"
dotnet add "$MainName.Web/$MainName.Web.csproj" reference "$MainName.Infrastructure/$MainName.Infrastructure.csproj"
dotnet add "$MainName.Infrastructure/$MainName.Infrastructure.csproj" reference "$MainName.Core/$MainName.Core.csproj"
dotnet add "$MainName.Services/$MainName.Services.csproj" reference "$MainName.Core/$MainName.Core.csproj"


Write-Host "Congratulations! the $MainName successfully"