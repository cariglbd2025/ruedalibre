--procedimiento almacenado para borrar clientes de la tabla con el código dado

DROP PROCEDURE IF EXISTS PROYECTO.BORRAR_CLIENTE;

CREATE OR ALTER PROCEDURE PROYECTO.BORRAR_CLIENTE
	@cod_cliente VARCHAR(20)
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM PROYECTO.CLIENTE WHERE NUM_IDENTIDAD = @cod_cliente)
	BEGIN
		RAISERROR('Este cliente no existe.',16,1);
		RETURN;
	END
	DELETE FROM PROYECTO.CLIENTE WHERE NUM_IDENTIDAD = @cod_cliente;
	PRINT ('Usuario ' + @cod_cliente + ' borrado de  la tabla.');
END
GO

--procedimiento almacenado para meter un país nuevo en la tabla con el nombre dado
CREATE OR ALTER PROCEDURE PROYECTO.METERPAIS
	@NOMBRE_PAIS VARCHAR(50)
AS
BEGIN
	DECLARE @ID_PAIS_SIGUIENTE INT;

	SELECT @ID_PAIS_SIGUIENTE = MAX(ID_PAIS) + 1 FROM PROYECTO.PAIS;

	IF EXISTS (SELECT * FROM PROYECTO.PAIS WHERE NOMBRE = @NOMBRE_PAIS)
	BEGIN
		RAISERROR('Este país ya existe', 16,1);
		RETURN;
	END
	
	INSERT INTO PROYECTO.PAIS (ID_PAIS, NOMBRE)
	VALUES (@ID_PAIS_SIGUIENTE, @NOMBRE_PAIS);

	PRINT ('País ' + @NOMBRE_PAIS + ' insertado.');
END;
GO

--crear el rol de gestor clientes

DROP ROLE IF EXISTS GESTORESCLIENTES;
GO
CREATE ROLE GESTORESCLIENTES;
GO

--conceder permisos de ejecución en el esquema proyecto al rol GESTORESCLIENTES

GRANT EXECUTE ON SCHEMA::[PROYECTO] TO GESTORESCLIENTES;
GO

--crear a un usuario y añadirlo al grupo de GESTORESCLIENTES

DROP USER IF EXISTS Victor_VanLish;
GO
CREATE USER Victor_VanLish WITHOUT LOGIN;
GO
ALTER ROLE GESTORESCLIENTES
ADD MEMBER Victor_VanLish;
GO

--"loguearse" como el usuario y ejecutar el procedimiento almacenado

EXECUTE AS USER = 'Victor_VanLish';
GO


PRINT USER;
GO

--ejecutar ambos procedimientos

EXEC PROYECTO.METERPAIS @NOMBRE_PAIS = 'Islandia';
GO
EXEC PROYECTO.BORRAR_CLIENTE @cod_cliente = '12345678A';
GO

--si siguiera como el usuario de GESTORESCLIENTES daría error, de ahí el REVERT

REVERT;
GO

--verificar ambas tablas

SELECT * FROM PROYECTO.PAIS;
GO
SELECT * FROM PROYECTO.CLIENTE;
GO

--creamos la vista de la tabla clientes VISTACLIENTES

DROP VIEW IF EXISTS PROYECTO.VISTACLIENTES;
GO
CREATE VIEW PROYECTO.VISTA_CLIENTES
AS
	SELECT NUM_IDENTIDAD, NOMBRE, APELLIDO1, EMPRESA
	FROM PROYECTO.CLIENTE
GO

--concedo permisos de lectura sobre la vista creada a mi grupo.

GRANT SELECT ON PROYECTO.VISTA_CLIENTES TO GESTORESCLIENTES;
GO

--me "logueo" como el usuario que cree de nuevo:
EXECUTE AS USER = 'Victor_VanLish';
GO

--compruebo que no puedo ver en la tabla directamente

SELECT * FROM PROYECTO.CLIENTE;
GO

--pero sí puedo ver la vista y usarla

SELECT * FROM PROYECTO.VISTA_CLIENTES WHERE EMPRESA = 1;

