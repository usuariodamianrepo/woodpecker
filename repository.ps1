param(
	[Parameter(Mandatory = $true, HelpMessage = "Provide the Project Name.")]
    [ValidateNotNullOrEmpty()]
	[string]$ProjectName
)

<# CORE solution #>
$entityBase = @"
namespace $ProjectName.Core.Entities
{
    public abstract class EntityBase
    {
        public int Id { get; set; }
        public DateTime InsertDate { get; private set; } = DateTime.Now;
        public DateTime? UpdateDate { get; private set; }
        
        public void UpdateAudit()
        {
            UpdateDate = DateTime.Now;
        }
    }
}
"@

New-Item -Path "$ProjectName.Core/Entities/EntityBase.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Entities/EntityBase.cs" -Value $entityBase

$entityCity = @"
namespace $ProjectName.Core.Entities
{
    public class City: EntityBase
    {
        public string Name { get; set; }
        public string? Description { get; set; }
    }
}
"@

New-Item -Path "$ProjectName.Core/Entities/City.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Entities/City.cs" -Value $entityCity

$appDbContext = @"
namespace $ProjectName.Infrastructure.Data
{
    public class AppDbContext : DbContext
    {
        public DbSet<City> Cities { get; set; }
		
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {

        }

        protected override void OnModelCreating(ModelBuilder builder)
        {
		
        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Data/AppDbContext.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Data/AppDbContext.cs" -Value $appDbContext

<# create IBaseRepository #>
$iBaseRepository = @"
namespace $ProjectName.Core.Interfaces.Repositories
{
    public interface IBaseRepository<TEntity> where TEntity : class
    {
        Task AddAsync(TEntity entity);
        Task AddRangeAsync(IEnumerable<TEntity> entities);
        Task<IEnumerable<TEntity>> GetAllAsync();
        Task<IEnumerable<TEntity>> GetByFilterAsync(Expression<Func<TEntity, bool>>? filter = null,
                                                Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>>? orderBy = null,
                                                string includeProperties = "",
                                                bool tracked = false,
                                                int take = 0);
        Task<TEntity> GetByIdAsync(int id);
        Task<TEntity> GetSingleOrDefaultAsync(Expression<Func<TEntity, bool>> predicate);
        Task<(IEnumerable<TEntity> Items, int TotalCount)> GetPagedAsync(
            int pageNumber,
            int pageSize,
            Expression<Func<TEntity, bool>>? filter = null,
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>>? orderBy = null,
            string includeProperties = "",
            bool tracked = false);
        void Remove(TEntity entity);
        void RemoveRange(IEnumerable<TEntity> entities);
        void Update(TEntity entityToUpdate);
        void UpdateRange(IEnumerable<TEntity> entitiesToUpdate);
    }
}
"@
New-Item -Path "$ProjectName.Core/Interfaces/Repositories/IBaseRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/Repositories/IBaseRepository.cs" -Value $iBaseRepository

$iCityRepository = @"
namespace $ProjectName.Core.Interfaces.Repositories
{
    public interface ICityRepository:IBaseRepository<City>
    {
    }
}
"@
New-Item -Path "$ProjectName.Core/Interfaces/Repositories/ICityRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/Repositories/ICityRepository.cs" -Value $iCityRepository


<# create IUnitOfWork #>
$iUnitOfWork = @"
namespace $ProjectName.Core.Interfaces
{
    public interface IUnitOfWork
    {
        ICityRepository CityRepository { get; }

        Task<int> CommitAsync();
    }
}
"@
New-Item -Path "$ProjectName.Core/Interfaces/IUnitOfWork.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/IUnitOfWork.cs" -Value $iUnitOfWork

<# create BaseRepository #>
$baseRepository = @"
namespace $ProjectName.Infrastructure.Repositories
{
    public class BaseRepository<TEntity> : IBaseRepository<TEntity> where TEntity : class
    {
        internal AppDbContext _context;
        internal DbSet<TEntity> _dbSet;

        public BaseRepository(AppDbContext context)
        {
            _context = context;
            _dbSet = context.Set<TEntity>();
        }

        public virtual async Task AddAsync(TEntity entity)
        {
            await _dbSet.AddAsync(entity);
        }

        public virtual async Task AddRangeAsync(IEnumerable<TEntity> entities)
        {
            await _dbSet.AddRangeAsync(entities);
        }

        public virtual async Task<IEnumerable<TEntity>> GetAllAsync()
        {
            return await _dbSet.ToListAsync();
        }

        public virtual async Task<IEnumerable<TEntity>> GetByFilterAsync(
            Expression<Func<TEntity, bool>>? filter = null,
            Func<IQueryable<TEntity>,IOrderedQueryable<TEntity>>? orderBy = null, 
            string includeProperties = "",
            bool tracked = false,
            int take = 0
            )
        {
            IQueryable<TEntity> query = tracked ? _dbSet : _dbSet.AsNoTracking();

            if (filter != null)
                query = query.Where(filter);

            if (!string.IsNullOrWhiteSpace(includeProperties))
            {
                foreach (var includeProperty in includeProperties.Split(',', StringSplitOptions.RemoveEmptyEntries))
                {
                    query = query.Include(includeProperty.Trim());
                }
            }

            if (take > 0)
                query = query.Take(take);

            return orderBy != null ? await orderBy(query).ToListAsync() : await query.ToListAsync();
        }

        public virtual async Task<TEntity> GetSingleOrDefaultAsync(Expression<Func<TEntity, bool>> predicate)
        {
            if (predicate == null)
                throw new ArgumentNullException(nameof(predicate));

            return await _dbSet.SingleOrDefaultAsync(predicate);
        }

        public virtual async Task<TEntity> GetByIdAsync(int id)
        {
            return await _dbSet.FindAsync(id) ?? throw new InvalidOperationException($"No {typeof(TEntity).Name} found with ID: {id}");
        }

        public virtual async Task<(IEnumerable<TEntity> Items, int TotalCount)> GetPagedAsync(
            int pageNumber,
            int pageSize,
            Expression<Func<TEntity, bool>>? filter = null,
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>>? orderBy = null,
            string includeProperties = "",
            bool tracked = false)
        {
            IQueryable<TEntity> query = tracked ? _dbSet : _dbSet.AsNoTracking();
            if (filter != null)
                query = query.Where(filter);
            if (!string.IsNullOrWhiteSpace(includeProperties))
            {
                foreach (var includeProperty in includeProperties.Split(',', StringSplitOptions.RemoveEmptyEntries))
                {
                    query = query.Include(includeProperty.Trim());
                }
            }
            var totalCount = await query.CountAsync();
            var items = await query.Skip((pageNumber - 1) * pageSize).Take(pageSize).ToListAsync();
            return (items, totalCount);
        }

        public virtual void Remove(TEntity entity)
        {
            _dbSet.Remove(entity);
        }

        public virtual void RemoveRange(IEnumerable<TEntity> entities)
        {
            _dbSet.RemoveRange(entities);
        }

        public void Update(TEntity entityToUpdate)
        {
            _dbSet.Attach(entityToUpdate);
            _context.Entry(entityToUpdate).State = EntityState.Modified;
        }

        public void UpdateRange(IEnumerable<TEntity> entitiesToUpdate)
        {
            _dbSet.AttachRange(entitiesToUpdate);
            _context.Entry(entitiesToUpdate).State = EntityState.Modified;
        }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Repositories/BaseRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Repositories/BaseRepository.cs" -Value $baseRepository

$cityRepository = @"
namespace $ProjectName.Infrastructure.Repositories
{
    public class CityRepository : BaseRepository<City>, ICityRepository
    {
        public CityRepository(AppDbContext context) : base(context)
        {

        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Repositories/CityRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Repositories/CityRepository.cs" -Value $cityRepository

<# create UnitOfWork #>
$unitOfWork = @"
using $ProjectName.Core.Interfaces;
using $ProjectName.Core.Interfaces.Repositories;
using $ProjectName.Infrastructure.Repositories;

namespace $ProjectName.Infrastructure.Data
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly AppDbContext _context;
        private CityRepository _cityRepository;

        public UnitOfWork(AppDbContext context)
        {
            this._context = context;
        }

        public ICityRepository CityRepository => _cityRepository ??= new CityRepository(_context);
		
        public async Task<int> CommitAsync()
        {
            return await _context.SaveChangesAsync();
        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Data/UnitOfWork.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Data/UnitOfWork.cs" -Value $UnitOfWork

Write-Host "The next step is install EntityFrameworkCore in the Infrastructure project"