using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence.Configurations;

public sealed class StockEntryConfiguration : IEntityTypeConfiguration<StockEntry>
{
    public void Configure(EntityTypeBuilder<StockEntry> builder)
    {
        builder.ToTable("stock_entries");
        builder.HasKey(s => s.Id);

        builder.Property(s => s.ProductName)
            .HasColumnName("product_name")
            .HasMaxLength(200)
            .IsRequired();

        builder.OwnsOne(s => s.AvailableUnits, q =>
        {
            q.Property(x => x.Value).HasColumnName("available_units").IsRequired();
        });

        builder.Property(s => s.CreatedAt).HasColumnName("created_at").IsRequired();
        builder.Property(s => s.LastUpdatedAt).HasColumnName("last_updated_at");

        builder.Ignore(s => s.DomainEvents);
    }
}
