using Microsoft.AspNetCore.Mvc;
using LetMeTalkApi.Contexts;
using LetMeTalkApi.Models;

namespace LetMeTalkApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PictogramaController : ControllerBase
    {
        private readonly ConexionSQLServer _conexion;

        public PictogramaController(ConexionSQLServer conexion)
        {
            _conexion = conexion;
        }

        [HttpGet]
        public async Task<IActionResult> GetPictogramas([FromQuery] int? categoriaId = null, [FromQuery] bool? soloFavoritos = null)
        {
            var pictogramas = new List<Pictograma>();

            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    var filtros = new List<string>();

                    if (categoriaId.HasValue)
                    {
                        filtros.Add("CategoriaId = @categoriaId");
                        var paramCat = command.CreateParameter();
                        paramCat.ParameterName = "@categoriaId";
                        paramCat.Value = categoriaId.Value;
                        command.Parameters.Add(paramCat);
                    }

                    if (soloFavoritos == true)
                    {
                        filtros.Add("EsFavorito = 1");
                    }

                    var whereClause = filtros.Count > 0
                        ? " WHERE " + string.Join(" AND ", filtros)
                        : string.Empty;

                    command.CommandText =
                        "SELECT Id, ArasaacId, Etiqueta, TextoVoz, CategoriaId, EsFavorito FROM Pictograma"
                        + whereClause
                        + " ORDER BY Id";

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            pictogramas.Add(new Pictograma
                            {
                                Id = reader.GetInt32(0),
                                ArasaacId = reader.GetInt32(1),
                                Etiqueta = reader.GetString(2),
                                TextoVoz = reader.GetString(3),
                                CategoriaId = reader.GetInt32(4),
                                EsFavorito = reader.GetBoolean(5)
                            });
                        }
                    }
                }
            }

            return Ok(pictogramas);
        }

        [HttpPost]
        public async Task<IActionResult> CrearPictograma([FromBody] Pictograma pictograma)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText =
                        "INSERT INTO Pictograma (ArasaacId, Etiqueta, TextoVoz, CategoriaId, EsFavorito) " +
                        "VALUES (@arasaacId, @etiqueta, @textoVoz, @categoriaId, @esFavorito)";

                    var paramArasaac = command.CreateParameter();
                    paramArasaac.ParameterName = "@arasaacId";
                    paramArasaac.Value = pictograma.ArasaacId;
                    command.Parameters.Add(paramArasaac);

                    var paramEtiqueta = command.CreateParameter();
                    paramEtiqueta.ParameterName = "@etiqueta";
                    paramEtiqueta.Value = pictograma.Etiqueta;
                    command.Parameters.Add(paramEtiqueta);

                    var paramTextoVoz = command.CreateParameter();
                    paramTextoVoz.ParameterName = "@textoVoz";
                    paramTextoVoz.Value = string.IsNullOrWhiteSpace(pictograma.TextoVoz)
                        ? pictograma.Etiqueta
                        : pictograma.TextoVoz;
                    command.Parameters.Add(paramTextoVoz);

                    var paramCategoria = command.CreateParameter();
                    paramCategoria.ParameterName = "@categoriaId";
                    paramCategoria.Value = pictograma.CategoriaId;
                    command.Parameters.Add(paramCategoria);

                    var paramFavorito = command.CreateParameter();
                    paramFavorito.ParameterName = "@esFavorito";
                    paramFavorito.Value = pictograma.EsFavorito;
                    command.Parameters.Add(paramFavorito);

                    await command.ExecuteNonQueryAsync();
                }
            }

            return Ok("Pictograma creado correctamente");
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarPictograma(int id, [FromBody] Pictograma pictograma)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText =
                        "UPDATE Pictograma SET ArasaacId = @arasaacId, Etiqueta = @etiqueta, " +
                        "TextoVoz = @textoVoz, CategoriaId = @categoriaId, EsFavorito = @esFavorito " +
                        "WHERE Id = @id";

                    var paramArasaac = command.CreateParameter();
                    paramArasaac.ParameterName = "@arasaacId";
                    paramArasaac.Value = pictograma.ArasaacId;
                    command.Parameters.Add(paramArasaac);

                    var paramEtiqueta = command.CreateParameter();
                    paramEtiqueta.ParameterName = "@etiqueta";
                    paramEtiqueta.Value = pictograma.Etiqueta;
                    command.Parameters.Add(paramEtiqueta);

                    var paramTextoVoz = command.CreateParameter();
                    paramTextoVoz.ParameterName = "@textoVoz";
                    paramTextoVoz.Value = string.IsNullOrWhiteSpace(pictograma.TextoVoz)
                        ? pictograma.Etiqueta
                        : pictograma.TextoVoz;
                    command.Parameters.Add(paramTextoVoz);

                    var paramCategoria = command.CreateParameter();
                    paramCategoria.ParameterName = "@categoriaId";
                    paramCategoria.Value = pictograma.CategoriaId;
                    command.Parameters.Add(paramCategoria);

                    var paramFavorito = command.CreateParameter();
                    paramFavorito.ParameterName = "@esFavorito";
                    paramFavorito.Value = pictograma.EsFavorito;
                    command.Parameters.Add(paramFavorito);

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró un pictograma con Id {id}");
                }
            }

            return Ok("Pictograma actualizado correctamente");
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> EliminarPictograma(int id)
        {
            using (var connection = _conexion.GetConnection())
            {
                await connection.OpenAsync();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = "DELETE FROM Pictograma WHERE Id = @id";

                    var paramId = command.CreateParameter();
                    paramId.ParameterName = "@id";
                    paramId.Value = id;
                    command.Parameters.Add(paramId);

                    int filasAfectadas = await command.ExecuteNonQueryAsync();

                    if (filasAfectadas == 0)
                        return NotFound($"No se encontró un pictograma con Id {id}");
                }
            }

            return Ok("Pictograma eliminado correctamente");
        }
    }
}
