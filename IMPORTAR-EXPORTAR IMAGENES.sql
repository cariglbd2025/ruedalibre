USE RUEDALIBRE;
GO
DROP TABLE IF EXISTS PROYECTO.IMAGENES
GO
CREATE TABLE PROYECTO.IMAGENES (				--creamos la tabla en proyecto.imagenes
   NOMBRE_IMG VARCHAR(40) PRIMARY KEY NOT NULL,
   NOMBRE_CON_EXT VARCHAR (100),
   IMG_DATOS VARBINARY (max)
   )
GO
Use master;					--hay que modificar lo siguiente en master
Go
EXEC sp_configure 'show advanced options', 1; --activar funciones avanzadas
GO 
RECONFIGURE WITH OVERRIDE; 
GO 
--Si hago solo RECONFIGURE tendrá que reiniciar pues no lo habrá sobreescrito

EXEC sp_configure 'Ole Automation Procedures', 1;  --activar cosas avanzadas
GO 
RECONFIGURE WITH OVERRIDE
GO

ALTER SERVER ROLE [bulkadmin] ADD MEMBER [DESKTOP-TQGNR5L\CAR_IGL] --añado un usuario al rol de bulkear datos
GO

USE RUEDALIBRE;
GO

--procedimiento para importar imágenes
DROP PROCEDURE IF EXISTS PROYECTO.IMPORTAR_IMAGEN;
GO
CREATE OR ALTER PROCEDURE PROYECTO.IMPORTAR_IMAGEN (
     @IMG_A_IMPORTAR VARCHAR (100) --variables de la imagen
   , @CARPETA_IMG VARCHAR (1000)
   , @IMG_CON_EXT VARCHAR (1000)
   )
AS
BEGIN
   DECLARE @RUTA_ABSOLUTA VARCHAR (2000);
   DECLARE @INSERCION_DINAMICA VARCHAR (2000);
   SET NOCOUNT ON --para evitar que se vean numeritos
   SET @RUTA_ABSOLUTA = CONCAT (@CARPETA_IMG,'\', @IMG_CON_EXT); --CONCAT tiene ventajas sobre concatenar a saco, como transformar valores a VARCHAR directamente
   SET @INSERCION_DINAMICA = 'insert into PROYECTO.IMAGENES (NOMBRE_IMG, NOMBRE_CON_EXT, IMG_DATOS) ' +  --como es todo varchar no hace falta usar concat o convert
               ' SELECT ' + '''' + @IMG_A_IMPORTAR + '''' + ',' + '''' + @IMG_CON_EXT + '''' + ', * ' + --las comillas simples se hacen con cuatro simples
               'FROM Openrowset( Bulk ' + '''' + @RUTA_ABSOLUTA + '''' + ', Single_Blob) as img' 
   EXEC (@INSERCION_DINAMICA) -- toda esta movida es porque OpenRowSet no se le pueden poner variables, hay que transformarlo antes a VARCHAR.
   SET NOCOUNT OFF
END
GO
DROP PROCEDURE IF EXISTS PROYECTO.EXPORTAR_IMAGEN;
GO
CREATE OR ALTER PROCEDURE PROYECTO.EXPORTAR_IMAGEN (
	@IMG_A_EXPORTAR VARCHAR (100),
	@CARPETA_SALIDA VARCHAR(1000),
	@IMG_CON_EXT VARCHAR(1000)
   )
AS
BEGIN
   DECLARE @IMAGEN VARBINARY (max);
   DECLARE @RUTA_ABSOLUTA NVARCHAR (2000);
   DECLARE @OBJETO INT
 
   SET NOCOUNT ON
 
   SELECT @IMAGEN = (
         SELECT convert (VARBINARY (max), IMG_DATOS, 1)
         FROM PROYECTO.IMAGENES
         WHERE NOMBRE_IMG = @IMG_A_EXPORTAR
         );
 
   SET @RUTA_ABSOLUTA = CONCAT (
         @CARPETA_SALIDA
         ,'\'
         , @IMG_CON_EXT
         );
    BEGIN TRY
     EXEC sp_OACreate 'ADODB.Stream' ,@OBJETO OUTPUT;
     EXEC sp_OASetProperty @OBJETO ,'Type',1;
     EXEC sp_OAMethod @OBJETO,'Open';
     EXEC sp_OAMethod @OBJETO,'Write', NULL, @IMAGEN;
     EXEC sp_OAMethod @OBJETO,'SaveToFile', NULL, @RUTA_ABSOLUTA, 2;
     EXEC sp_OAMethod @OBJETO,'Close';
     EXEC sp_OADestroy @OBJETO;
    END TRY
    
 BEGIN CATCH
  EXEC sp_OADestroy @OBJETO;
 END CATCH
 
   SET NOCOUNT OFF
END
GO

execute PROYECTO.IMPORTAR_IMAGEN 'caravana1','C:\IMAGENES\ENTRADA','caravana1.png';
GO
execute PROYECTO.EXPORTAR_IMAGEN 'caravana1', 'C:\IMAGENES\SALIDA','caravana1.png';
GO
select * FROM PROYECTO.IMAGENES;