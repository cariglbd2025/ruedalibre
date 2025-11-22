USE master;
GO

--voy a crear primero un procedimiento sin bucles que SÓLO guarde mi base de datos.

DROP PROCEDURE IF EXISTS BACKUP_RUEDALIBRE;
GO

CREATE OR ALTER PROCEDURE BACKUP_RUEDALIBRE
    @RUTA VARCHAR(256)
AS
BEGIN
    DECLARE
	@NOMBRE_BD VARCHAR(50),
    @NOMBRE_BAK VARCHAR(256),
    @FECHA_BAK VARCHAR(20);

    SET @NOMBRE_BD = 'RUEDALIBRE';
--para mi ejemplo voy a hacer que ponga la fecha y la hora
    SET @FECHA_BAK = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
    SET @NOMBRE_BAK = @RUTA + @NOMBRE_BD + '_' + @FECHA_BAK + '.bak';
    PRINT 'Se va a generar el backup de la base: ' + @NOMBRE_BAK;
    BACKUP DATABASE @NOMBRE_BD TO DISK = @NOMBRE_BAK WITH INIT;
    PRINT 'Backup completado.';
END;
GO
--Lo ejecuto
EXEC BACKUP_RUEDALIBRE 'C:\BACKUP\';
GO
--ahora voy a crear el procedimiento pero usando un while y varias bases.
DROP PROCEDURE IF EXISTS BACKUP_BDs;
GO
CREATE OR ALTER PROCEDURE BACKUP_BDs
    @RUTA VARCHAR(256)
AS
BEGIN
    DECLARE
	 -- @RUTA VARCHAR(256), -- por si quiero declararla yo a que se dé al ejecutar el procedimiento almacenado
        @NOMBRE_BD VARCHAR(50),
        @NOMBRE_BAK VARCHAR(256),
        @FECHA_BAK VARCHAR(20),
        @CANTIDAD_BACKUPS INT,
        @ACTUAL_BACKUP INT;

--tabla temporal que creamos para poner los backups que tenemos que hacer y con su clave primaria numérica que nos permitirá usar el while.
    CREATE TABLE #BACKUP_PENDIENTES (
        ID_BACKUP_PENDIENTE INT IDENTITY(1,1),
        NOMBRE_BD_PENDIENTE VARCHAR(200)
    );
    INSERT INTO #BACKUP_PENDIENTES (NOMBRE_BD_PENDIENTE)
    SELECT name
    FROM master.dbo.sysdatabases
    WHERE name IN ('RUEDALIBRE', 'pubs', 'Northwind'); --puedo poner en comas las que me interesen
--también puedo poner NOT IN ('master', 'model', 'msdb', 'tempdb')

--SELECT TOP 1 @CANTIDAD_BACKUPS = ID_BACKUP_PENDIENTE FROM [dbo].#BACKUP_PENDIENTES ORDER BY ID_BACKUP_PENDIENTE DESC
--Él coge el primer resultado de los ID_BACKUP_PENDIENTE ordenados de manera descendente y se lo asigna a @CANTIDAD_BACKUPS

--Yo voy a usar MAX
    SELECT @CANTIDAD_BACKUPS = MAX(ID_BACKUP_PENDIENTE)
    FROM #BACKUP_PENDIENTES;

--print @CANTIDAD_BACKUPS 
--si quiero ver cuántos backups se van a hacer

    IF (@CANTIDAD_BACKUPS IS NOT NULL AND @CANTIDAD_BACKUPS > 0)
    BEGIN
        SET @ACTUAL_BACKUP = 1;
        WHILE (@ACTUAL_BACKUP <= @CANTIDAD_BACKUPS)
        BEGIN
            SELECT @NOMBRE_BD = NOMBRE_BD_PENDIENTE
            FROM #BACKUP_PENDIENTES
            WHERE ID_BACKUP_PENDIENTE = @ACTUAL_BACKUP;
            SET @FECHA_BAK = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
            SET @NOMBRE_BAK = @RUTA + @NOMBRE_BD + '_' + @FECHA_BAK + '.bak';
--print @NOMBRE_BAK si quiero ver cómo va la cosa
			PRINT 'Se va a generar el backup de la base: ' + @NOMBRE_BAK;
-- SIN INIT NO SOBREESCRIBE EL FICHERO. MEJOR USAR WITH INIT
            BACKUP DATABASE @NOMBRE_BD TO DISK = @NOMBRE_BAK WITH INIT;
            PRINT 'Backup completado.';
            SET @ACTUAL_BACKUP = @ACTUAL_BACKUP + 1;
        END
    END
    DROP TABLE #BACKUP_PENDIENTES;
END;
GO
EXEC BACKUP_BDs 'C:\BACKUP\';
GO
--procedimiento sencillo con cursor para practicar
DROP PROCEDURE IF EXISTS RECORRER_PAIS;
GO
CREATE OR ALTER PROCEDURE RECORRER_PAIS
AS
BEGIN
	DECLARE @ID_PAIS INT;
	DECLARE @NOMBRE VARCHAR(20);
	DECLARE CURSOR_PAIS CURSOR FOR
		SELECT ID_PAIS, NOMBRE FROM RUEDALIBRE.PROYECTO.PAIS;
	OPEN CURSOR_PAIS;
	FETCH NEXT FROM CURSOR_PAIS INTO @ID_PAIS, @NOMBRE;
	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT ('Estamos en el país con código ' + CAST(@ID_PAIS AS VARCHAR) + ' y nombre ' + @NOMBRE);
			FETCH NEXT FROM CURSOR_PAIS INTO @ID_PAIS, @NOMBRE;
		END;
	CLOSE CURSOR_PAIS;
	DEALLOCATE CURSOR_PAIS;
END;
GO;
EXECUTE RECORRER_PAIS;
GO;

--procedimiento para crear backups de las bases de datos, incluída la mía, usando cursores
DROP PROCEDURE IF EXISTS BACKUPS_CON_CURSOR;
GO
CREATE OR ALTER PROC BACKUPS_CON_CURSOR
AS
BEGIN
		DECLARE @NOMBRE_BD VARCHAR(50);
		DECLARE @RUTA VARCHAR(256);
		DECLARE @NOMBRE_BAK VARCHAR(256);
		DECLARE @FECHA_BAK VARCHAR(20);
 
		-- especificar dónde guardar el BU
		SET @RUTA = 'C:\Backup\';
 		--SELECT @FECHA_BAK = CONVERT(VARCHAR(20),GETDATE(),112) -- poner sólo fecha sin horas
		SELECT @FECHA_BAK = CONVERT(VARCHAR(20),GETDATE(),112) + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':',''); --necesario el REPLACE, a SQL no le gustan los ":"
		DECLARE db_cursor CURSOR READ_ONLY FOR  --READ_ONLY muy rápido cuando no voy a modificar nada, FORWARD_ONLY cuando sólo puedo ir para adelante, más rápido incluso
		SELECT name
		FROM master.dbo.sysdatabases
		--WHERE name IN ('Northwind')
		--WHERE name IN ('RUEDALIBRE', 'pubs', 'Northwind');
		WHERE name NOT IN ('master','model','msdb','tempdb');  -- quiero que haga todas, incluída la mía de RUEDA LIBRE
 		OPEN db_cursor;
		FETCH NEXT FROM db_cursor INTO @NOMBRE_BD;
 		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @NOMBRE_BAK = @RUTA + @NOMBRE_BD + '_' + @FECHA_BAK + '.BAK';
						PRINT 'Se va a generar el backup de la base: ' + @NOMBRE_BAK;
			BACKUP DATABASE @NOMBRE_BD TO DISK = @NOMBRE_BAK;
			PRINT 'Backup completado.';
			FETCH NEXT FROM db_cursor INTO @NOMBRE_BD;
		END
		CLOSE db_cursor;
		DEALLOCATE db_cursor;
END;
GO
EXECUTE BACKUPS_CON_CURSOR;
GO