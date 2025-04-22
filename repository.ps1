param(
	[Parameter(Mandatory = $true, HelpMessage = "Provide the Project Name.")]
    [ValidateNotNullOrEmpty()]
	[string]$ProjectName
)

$appDbContext = @"
namespace $ProjectName.Infrastructure.Data
{
    public class AppDbContext : DbContext
    {
        //public DbSet<City> Cities { get; set; }
		
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
        ValueTask<TEntity> GetByIdAsync(int id);
        Task<IEnumerable<TEntity>> GetAllAsync();
        Task<IEnumerable<TEntity>> GetAsync(Expression<Func<TEntity, bool>> filter = null,
                                                Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy = null,
                                                string includeProperties = "",
                                                bool tracked = false,
                                                int take = 0);
        Task<TEntity> SingleOrDefaultAsync(Expression<Func<TEntity, bool>> predicate);
        Task AddAsync(TEntity entity);
        Task AddRangeAsync(IEnumerable<TEntity> entities);
        void Remove(TEntity entity);
        void RemoveRange(IEnumerable<TEntity> entities);
        Task Update(TEntity entityToUpdate);
        Task UpdateRange(IEnumerable<TEntity> entitiesToUpdate);
    }
}
"@
New-Item -Path "$ProjectName.Core/Interfaces/Repositories/IBaseRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Core/Interfaces/Repositories/IBaseRepository.cs" -Value $iBaseRepository

<# create IUnitOfWork #>
$iUnitOfWork = @"
namespace $ProjectName.Core.Interfaces
{
    public interface IUnitOfWork
    {
        //ICityRepository CityRepository { get; }

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

        public virtual async Task<IEnumerable<TEntity>> GetAsync(
            Expression<Func<TEntity, bool>> filter = null, 
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy = null, 
            string includeProperties = "",
            bool tracked = false,
            int take = 0
            )
        {
            IQueryable<TEntity> query = _dbSet;

            if (tracked)
            {
                query = _dbSet;
            }
            else
            {
                query = _dbSet.AsNoTracking();
            }

            if (filter != null)
                query = query.Where(filter);

            foreach (var includeProperty in includeProperties.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
            {
                query = query.Include(includeProperty);
            }

            if(take > 0)
                query = query.Take(take);

            if (orderBy != null)
                return await orderBy(query).ToListAsync();

            return await query.ToListAsync();
        }

        public virtual async ValueTask<TEntity> GetByIdAsync(int id)
        {
            return await _dbSet.FindAsync(id);
        }

        public virtual void Remove(TEntity entity)
        {
            _dbSet.Remove(entity);
        }

        public virtual void RemoveRange(IEnumerable<TEntity> entities)
        {
            _dbSet.RemoveRange(entities);
        }

        public virtual async Task<TEntity> SingleOrDefaultAsync(Expression<Func<TEntity, bool>> predicate)
        {
            return await _dbSet.SingleOrDefaultAsync(predicate);
        }

        public virtual async Task Update(TEntity entityToUpdate)
        {
            _dbSet.Attach(entityToUpdate);
            _context.Entry(entityToUpdate).State = EntityState.Modified;
        }

        public virtual async Task UpdateRange(IEnumerable<TEntity> entitiesToUpdate)
        {
            _dbSet.AttachRange(entitiesToUpdate);
            _context.Entry(entitiesToUpdate).State = EntityState.Modified;
        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Repositories/BaseRepository.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Repositories/BaseRepository.cs" -Value $baseRepository

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
        //private CityRepository _cityRepository;

        public UnitOfWork(AppDbContext context)
        {
            this._context = context;
        }

        //public ICityRepository CityRepository => _cityRepository ??= new CityRepository(_context);
		
        public async Task<int> CommitAsync()
        {
            return await _context.SaveChangesAsync();
        }
    }
}
"@
New-Item -Path "$ProjectName.Infrastructure/Data/UnitOfWork.cs" -ItemType File -Force
Set-Content -Path "$ProjectName.Infrastructure/Data/UnitOfWork.cs" -Value $UnitOfWork
