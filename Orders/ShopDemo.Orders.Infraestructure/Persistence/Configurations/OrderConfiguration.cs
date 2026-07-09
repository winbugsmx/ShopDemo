using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Entities;

namespace ShopDemo.Orders.Infraestructure.Persistence.Configurations;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("orders");
        builder.HasKey(o => o.Id);

        builder.Property(o => o.CreatedAt).IsRequired();
        builder.Property(o => o.LastUpdatedAt);

        builder.OwnsOne(o => o.CustomerId, ci =>
        {
            ci.Property(c => c.Value).HasColumnName("customer_id").IsRequired();
        });

        builder.OwnsOne(o => o.ShippingAddress, sa =>
        {
            sa.Property(a => a.Street).HasColumnName("ship_street").HasMaxLength(300).IsRequired();
            sa.Property(a => a.City).HasColumnName("ship_city").HasMaxLength(100).IsRequired();
            sa.Property(a => a.PostalCode).HasColumnName("ship_postal_code").HasMaxLength(20).IsRequired();
            sa.Property(a => a.Country).HasColumnName("ship_country").HasMaxLength(3).IsRequired();
        });

        builder.OwnsOne(o => o.Status, st =>
        {
            st.Property(s => s.Value).HasColumnName("status").HasMaxLength(20).IsRequired();
        });

        builder.OwnsOne(o => o.TotalAmount, money =>
        {
            money.Property(m => m.Amount).HasColumnName("total_amount").HasPrecision(18, 2);
            money.Property(m => m.Currency).HasColumnName("total_currency").HasMaxLength(3).IsRequired();
        });

        builder.OwnsMany(o => o.Lines, lines =>
        {
            lines.ToTable("order_lines");
            lines.WithOwner().HasForeignKey("OrderId");
            lines.HasKey(l => l.Id);

            lines.Property(l => l.ProductId).HasColumnName("product_id").IsRequired();
            lines.Property(l => l.ProductName).HasColumnName("product_name").HasMaxLength(200).IsRequired();

            lines.OwnsOne(l => l.UnitPrice, price =>
            {
                price.Property(p => p.Amount).HasColumnName("unit_price_amount").HasPrecision(18, 2);
                price.Property(p => p.Currency).HasColumnName("unit_price_currency").HasMaxLength(3);
            });

            lines.OwnsOne(l => l.Quantity, q =>
            {
                q.Property(x => x.Value).HasColumnName("quantity");
            });

            lines.OwnsOne(l => l.LineTotal, total =>
            {
                total.Property(t => t.Amount).HasColumnName("line_total_amount").HasPrecision(18, 2);
                total.Property(t => t.Currency).HasColumnName("line_total_currency").HasMaxLength(3);
            });
        });

        builder.Navigation(o => o.Lines).HasField("_lines");
        builder.Ignore(o => o.DomainEvents);
    }
}
