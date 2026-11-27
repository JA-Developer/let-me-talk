namespace LetMeTalkApi.Models
{
    public class Pictograma
    {
        public int Id { get; set; }
        public int ArasaacId { get; set; }
        public string Etiqueta { get; set; } = string.Empty;
        public string TextoVoz { get; set; } = string.Empty;
        public int CategoriaId { get; set; }
        public bool EsFavorito { get; set; }
    }
}
