using LetMeTalkApi.Contexts;

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar una política que permita cualquier origen, cabecera y método
builder.Services.AddCors(options =>
{
    options.AddPolicy("PermitirTodo", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// Inyectar ConexionSQLServer
builder.Services.AddScoped(sp =>
{
    var connectionString = builder.Configuration.GetConnectionString("CadenaConexionSQLServer")!;
    return new ConexionSQLServer(connectionString);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("PermitirTodo");

app.UseAuthorization();

app.MapControllers();

app.Run();
