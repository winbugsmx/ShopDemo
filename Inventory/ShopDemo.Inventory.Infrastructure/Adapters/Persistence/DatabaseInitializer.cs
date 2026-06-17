using Npgsql;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

public static class DatabaseInitializer
{
    public static async Task EnsureCreatedAsync(
        string connectionString, CancellationToken cancellationToken = default)
    {
        var builder = new NpgsqlConnectionStringBuilder(connectionString);
        var databaseName = builder.Database
            ?? throw new InvalidOperationException("Database name is required.");

        builder.Database = "postgres";

        await using var connection = new NpgsqlConnection(builder.ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = "SELECT 1 FROM pg_database WHERE datname = @name";
        checkCmd.Parameters.AddWithValue("name", databaseName);

        var exists = await checkCmd.ExecuteScalarAsync(cancellationToken) is not null;
        if (exists) return;

        var escapedName = databaseName.Replace("\"", "\"\"");
        var escapedUser = (builder.Username ?? "ShopDemo").Replace("\"", "\"\"");
        await using var createCmd = connection.CreateCommand();
        createCmd.CommandText = $"CREATE DATABASE \"{escapedName}\" OWNER \"{escapedUser}\"";
        await createCmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
