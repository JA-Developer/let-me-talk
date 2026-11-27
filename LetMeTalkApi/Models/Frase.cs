namespace LetMeTalkApi.Models
{
    public class Frase
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string TextoVoz { get; set; } = string.Empty;
        public string ArasaacIds { get; set; } = string.Empty;
        public string ColorHex { get; set; } = "#0D9488";
    }
}
