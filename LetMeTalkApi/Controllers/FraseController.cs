using Microsoft.AspNetCore.Mvc;
using LetMeTalkApi.Contexts;
using LetMeTalkApi.Models;

namespace LetMeTalkApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FraseController : ControllerBase
    {
        private readonly ConexionSQLServer _conexion;

        public FraseController(ConexionSQLServer conexion)
        {
            _conexion = conexion;
        }

        [HttpGet]
        public async Task<IActionResult> GetFrases()
        {
            var frases = new List<Frase>();

            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "SELECT Id, Titulo, TextoVoz, ArasaacIds, ColorHex FROM Frase ORDER BY Id";

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            frases.Add(new Frase
                            {
                                Id = reader.GetInt32(0),
                                Titulo = reader.GetString(1),
                                TextoVoz = reader.GetString(2),
                                ArasaacIds = reader.GetString(3),
                                ColorHex = reader.GetString(4)
                            });
                        }
                    }
                }
            }

            return Ok(frases);
        }

        [HttpPost]
        public async Task<IActionResult> CrearFrase([FromBody] Frase frase)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText =
                        "INSERT INTO Frase (Titulo, TextoVoz, ArasaacIds, ColorHex) " +
                        "VALUES (@titulo, @textoVoz, @arasaacIds, @colorHex)";

                    var paramTitulo = command.CreateParameter();
                    paramTitulo.ParameterName = "@titulo";
                    paramTitulo.Value = frase.Titulo;
                    command.Parameters.Add(paramTitulo);

                    var paramTextoVoz = command.CreateParameter();
                    paramTextoVoz.ParameterName = "@textoVoz";
                    paramTextoVoz.Value = string.IsNullOrWhiteSpace(frase.TextoVoz)
                        ? frase.Titulo
                        : frase.TextoVoz;
                    command.Parameters.Add(paramTextoVoz);

                    var paramIds = command.CreateParameter();
                    paramIds.ParameterName = "@arasaacIds";
                    paramIds.Value = frase.ArasaacIds ?? string.Empty;
                    command.Parameters.Add(paramIds);

                    var paramColor = command.CreateParameter();
                    paramColor.ParameterName = "@colorHex";
                    paramColor.Value = string.IsNullOrWhiteSpace(frase.ColorHex)
                        ? "#0D9488"
                        : frase.ColorHex;
                    command.Parameters.Add(paramColor);

                    await command.ExecuteNonQueryAsync();
                }
            }

            return Ok("Frase creada correctamente");
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarFrase(int id, [FromBody] Frase frase)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText =
                        "UPDATE Frase SET Titulo = @titulo, TextoVoz = @textoVoz, " +
                        "ArasaacIds = @arasaacIds, ColorHex = @colorHex WHERE Id = @id";

                    var paramTitulo = command.CreateParameter();
                    paramTitulo.ParameterName = "@titulo";
                    paramTitulo.Value = frase.Titulo;
                    command.Parameters.Add(paramTitulo);

                    var paramTextoVoz = command.CreateParameter();
                    paramTextoVoz.ParameterName = "@textoVoz";
                    paramTextoVoz.Value = string.IsNullOrWhiteSpace(frase.TextoVoz)
                        ? frase.Titulo
                        : frase.TextoVoz;
                    command.Parameters.Add(paramTextoVoz);

                    var paramIds = command.CreateParameter();
                    paramIds.ParameterName = "@arasaacIds";
                    paramIds.Value = frase.ArasaacIds ?? string.Empty;
                    command.Parameters.Add(paramIds);

                    var paramColor = command.CreateParameter();
                    paramColor.ParameterName = "@colorHex";
                    paramColor.Value = string.IsNullOrWhiteSpace(frase.ColorHex)
                        ? "#0D9488"
                        : frase.ColorHex;
                    command.Parameters.Add(paramColor);

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró una frase con Id {id}");
                }
            }

            return Ok("Frase actualizada correctamente");
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> EliminarFrase(int id)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "DELETE FROM Frase WHERE Id = @id";

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró una frase con Id {id}");
                }
            }

            return Ok("Frase eliminada correctamente");
        }
    }
}
