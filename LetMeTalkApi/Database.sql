-- ============================================================
-- Base de datos SQL Server para LetMeTalk (CAA + ARASAAC)
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LETMETALK')
BEGIN
    CREATE DATABASE LETMETALK;
END
GO

USE LETMETALK;
GO

IF OBJECT_ID(N'dbo.Categoria', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categoria (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL,
        ColorHex NVARCHAR(16) NOT NULL,
        Icono NVARCHAR(50) NOT NULL
    );
END
GO

IF OBJECT_ID(N'dbo.Pictograma', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Pictograma (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ArasaacId INT NOT NULL,
        Etiqueta NVARCHAR(120) NOT NULL,
        TextoVoz NVARCHAR(200) NOT NULL,
        CategoriaId INT NOT NULL,
        EsFavorito BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_Pictograma_Categoria
            FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria(Id) ON DELETE CASCADE
    );
END
GO

IF OBJECT_ID(N'dbo.Frase', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Frase (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Titulo NVARCHAR(160) NOT NULL,
        TextoVoz NVARCHAR(300) NOT NULL,
        ArasaacIds NVARCHAR(120) NOT NULL,
        ColorHex NVARCHAR(16) NOT NULL DEFAULT '#0D9488'
    );
END
GO

-- Datos iniciales de Categorías (clave de color Fitzgerald)
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria)
BEGIN
    INSERT INTO dbo.Categoria (Nombre, ColorHex, Icono) VALUES
    (N'Personas',    '#D97706', 'people'),
    (N'Acciones',    '#059669', 'actions'),
    (N'Emociones',   '#0284C7', 'emotions'),
    (N'Necesidades', '#E11D48', 'needs'),
    (N'Objetos',     '#EA580C', 'objects'),
    (N'Social',      '#7C3AED', 'social');
END
GO

-- Datos iniciales de 65 Pictogramas verificados de ARASAAC
IF NOT EXISTS (SELECT 1 FROM dbo.Pictograma)
BEGIN
    DECLARE @catPersonas    INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Personas');
    DECLARE @catAcciones    INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Acciones');
    DECLARE @catEmociones   INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Emociones');
    DECLARE @catNecesidades INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Necesidades');
    DECLARE @catObjetos     INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Objetos');
    DECLARE @catSocial      INT = (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Social');

    INSERT INTO dbo.Pictograma (ArasaacId, Etiqueta, TextoVoz, CategoriaId, EsFavorito) VALUES
    -- Personas
    (6632,  N'Yo',            N'Yo',            @catPersonas, 1),
    (6625,  N'Tú',            N'Tú',            @catPersonas, 0),
    (2458,  N'Mamá',          N'Mamá',          @catPersonas, 0),
    (2497,  N'Papá',          N'Papá',          @catPersonas, 0),
    (2392,  N'Familia',       N'Familia',       @catPersonas, 0),
    (25790, N'Amigo',         N'Amigo',         @catPersonas, 0),
    (2423,  N'Hermano',       N'Hermano',       @catPersonas, 0),
    (23718, N'Abuelo',        N'Abuelo',        @catPersonas, 0),
    (6561,  N'Médico',        N'Médico',        @catPersonas, 0),
    (6556,  N'Maestro',       N'Maestro',       @catPersonas, 0),

    -- Acciones
    (5441,  N'Quiero',        N'Quiero',        @catAcciones, 1),
    (37160, N'Necesito',      N'Necesito',      @catAcciones, 1),
    (6456,  N'Comer',         N'Comer',         @catAcciones, 0),
    (6061,  N'Beber',         N'Beber',         @catAcciones, 0),
    (6479,  N'Dormir',        N'Dormir',        @catAcciones, 0),
    (6537,  N'Jugar',         N'Jugar',         @catAcciones, 1),
    (8142,  N'Ir',            N'Ir',            @catAcciones, 0),
    (32648, N'Ayuda',         N'Ayuda',         @catAcciones, 1),
    (6564,  N'Ver',           N'Ver',           @catAcciones, 0),
    (6572,  N'Escuchar',      N'Escuchar',      @catAcciones, 0),
    (7196,  N'Parar',         N'Parar',         @catAcciones, 0),
    (16697, N'Esperar',       N'Esperar',       @catAcciones, 0),

    -- Emociones
    (9907,  N'Feliz',         N'Feliz',         @catEmociones, 1),
    (35545, N'Triste',        N'Triste',        @catEmociones, 1),
    (35539, N'Enojado',       N'Enojado',       @catEmociones, 0),
    (35535, N'Asustado',      N'Asustado',      @catEmociones, 0),
    (35537, N'Cansado',       N'Cansado',       @catEmociones, 0),
    (4613,  N'Amor',          N'Amor',          @catEmociones, 0),
    (35529, N'Sorprendido',   N'Sorprendido',   @catEmociones, 0),
    (31310, N'Tranquilo',     N'Tranquilo',     @catEmociones, 0),
    (35531, N'Aburrido',      N'Aburrido',      @catEmociones, 0),
    (5397,  N'Bien',          N'Bien',          @catEmociones, 0),
    (5504,  N'Mal',           N'Mal',           @catEmociones, 0),

    -- Necesidades
    (6929,  N'Baño',          N'Baño',          @catNecesidades, 1),
    (32464, N'Agua',          N'Agua',          @catNecesidades, 1),
    (4611,  N'Comida',        N'Comida',        @catNecesidades, 1),
    (2367,  N'Dolor',         N'Dolor',         @catNecesidades, 1),
    (4652,  N'Frío',          N'Frío',          @catNecesidades, 0),
    (35561, N'Calor',         N'Calor',         @catNecesidades, 0),
    (8163,  N'Medicina',      N'Medicina',      @catNecesidades, 0),
    (16643, N'Descansar',     N'Descansar',     @catNecesidades, 0),
    (5936,  N'Silencio',      N'Silencio',      @catNecesidades, 0),
    (4550,  N'Abrazo',        N'Abrazo',        @catNecesidades, 0),

    -- Objetos
    (2494,  N'Pan',           N'Pan',           @catObjetos, 0),
    (28339, N'Fruta',         N'Fruta',         @catObjetos, 0),
    (2445,  N'Leche',         N'Leche',         @catObjetos, 0),
    (9813,  N'Juguete',       N'Juguete',       @catObjetos, 0),
    (25191, N'Libro',         N'Libro',         @catObjetos, 0),
    (26479, N'Teléfono',      N'Teléfono',      @catObjetos, 0),
    (6964,  N'Casa',          N'Casa',          @catObjetos, 0),
    (32446, N'Escuela',       N'Escuela',       @catObjetos, 0),
    (25900, N'Cama',          N'Cama',          @catObjetos, 0),
    (7233,  N'Ropa',          N'Ropa',          @catObjetos, 0),
    (3241,  N'Pelota',        N'Pelota',        @catObjetos, 0),
    (24791, N'Música',        N'Música',        @catObjetos, 0),

    -- Social
    (6522,  N'Hola',          N'Hola',          @catSocial, 1),
    (6028,  N'Adiós',         N'Adiós',         @catSocial, 0),
    (5584,  N'Sí',            N'Sí',            @catSocial, 1),
    (5526,  N'No',            N'No',            @catSocial, 1),
    (8195,  N'Por favor',     N'Por favor',     @catSocial, 1),
    (8129,  N'Gracias',       N'Gracias',       @catSocial, 1),
    (11625, N'Perdón',        N'Perdón',        @catSocial, 0),
    (6944,  N'Buenos días',   N'Buenos días',   @catSocial, 0),
    (6942,  N'Buenas noches', N'Buenas noches', @catSocial, 0),
    (3220,  N'Más',           N'Más',           @catSocial, 0);
END
GO

-- Datos iniciales de Frases Rápidas
IF NOT EXISTS (SELECT 1 FROM dbo.Frase)
BEGIN
    INSERT INTO dbo.Frase (Titulo, TextoVoz, ArasaacIds, ColorHex) VALUES
    (N'Necesito ayuda',      N'Necesito ayuda, por favor',            '37160,32648', '#E11D48'),
    (N'Quiero agua',         N'Quiero agua, por favor',               '5441,32464',  '#0284C7'),
    (N'Necesito ir al baño', N'Necesito ir al baño',                  '8142,6929',   '#0D9488'),
    (N'Tengo hambre',        N'Tengo hambre, quiero comer',           '6456,4611',   '#EA580C'),
    (N'Me duele',            N'Algo me duele',                        '6632,2367',   '#DC2626'),
    (N'Necesito descansar',  N'Estoy cansado, necesito descansar',    '35537,16643', '#4F46E5'),
    (N'Por favor, espera',   N'Por favor, espera un momento',         '8195,16697',  '#059669'),
    (N'Estoy feliz',         N'Me siento muy feliz',                  '6632,9907',   '#D97706');
END
GO
