namespace LetMeTalkApi.Models
{
    public class Categoria
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string ColorHex { get; set; } = "#0D9488";
        public string Icono { get; set; } = "category";
    }
}
