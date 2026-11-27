using Microsoft.AspNetCore.Mvc;
using LetMeTalkApi.Contexts;
using LetMeTalkApi.Models;

namespace LetMeTalkApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoriaController : ControllerBase
    {
        private readonly ConexionSQLServer _conexion;

        public CategoriaController(ConexionSQLServer conexion)
        {
            _conexion = conexion;
        }

        [HttpGet]
        public async Task<IActionResult> GetCategorias()
        {
            var categorias = new List<Categoria>();

            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "SELECT Id, Nombre, ColorHex, Icono FROM Categoria ORDER BY Id";

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            categorias.Add(new Categoria
                            {
                                Id = reader.GetInt32(0),
                                Nombre = reader.GetString(1),
                                ColorHex = reader.GetString(2),
                                Icono = reader.GetString(3)
                            });
                        }
                    }
                }
            }

            return Ok(categorias);
        }

        [HttpPost]
        public async Task<IActionResult> CrearCategoria([FromBody] Categoria categoria)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "INSERT INTO Categoria (Nombre, ColorHex, Icono) VALUES (@nombre, @colorHex, @icono)";

                    var paramNombre = command.CreateParameter();
                    paramNombre.ParameterName = "@nombre";
                    paramNombre.Value = categoria.Nombre;
                    command.Parameters.Add(paramNombre);

                    var paramColor = command.CreateParameter();
                    paramColor.ParameterName = "@colorHex";
                    paramColor.Value = categoria.ColorHex;
                    command.Parameters.Add(paramColor);

                    var paramIcono = command.CreateParameter();
                    paramIcono.ParameterName = "@icono";
                    paramIcono.Value = categoria.Icono;
                    command.Parameters.Add(paramIcono);

                    await command.ExecuteNonQueryAsync();
                }
            }

            return Ok("Categoría creada correctamente");
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarCategoria(int id, [FromBody] Categoria categoria)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "UPDATE Categoria SET Nombre = @nombre, ColorHex = @colorHex, Icono = @icono WHERE Id = @id";

                    var paramNombre = command.CreateParameter();
                    paramNombre.ParameterName = "@nombre";
                    paramNombre.Value = categoria.Nombre;
                    command.Parameters.Add(paramNombre);

                    var paramColor = command.CreateParameter();
                    paramColor.ParameterName = "@colorHex";
                    paramColor.Value = categoria.ColorHex;
                    command.Parameters.Add(paramColor);

                    var paramIcono = command.CreateParameter();
                    paramIcono.ParameterName = "@icono";
                    paramIcono.Value = categoria.Icono;
                    command.Parameters.Add(paramIcono);

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró una categoría con Id {id}");
                }
            }

            return Ok("Categoría actualizada correctamente");
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> EliminarCategoria(int id)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "DELETE FROM Categoria WHERE Id = @id";

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró una categoría con Id {id}");
                }
            }

            return Ok("Categoría eliminada correctamente");
        }
    }
}
