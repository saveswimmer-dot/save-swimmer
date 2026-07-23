# Save Swimmer - trabajar en dos computadoras

Esta guia sirve para mover Save Swimmer a otra PC y mantener ambas sincronizadas usando GitHub.

Repositorio:

```text
https://github.com/saveswimmer-dot/save-swimmer
```

## Primera vez en una PC nueva

1. Instalar Git.
2. Elegir una carpeta de trabajo, por ejemplo:

```powershell
cd C:\Users\TU_USUARIO\Documents
git clone https://github.com/saveswimmer-dot/save-swimmer.git
cd save-swimmer
```

3. Verificar que este todo:

```powershell
git status
```

## Rutina antes de trabajar

Siempre traer lo ultimo antes de tocar archivos:

```powershell
git pull
```

## Rutina despues de trabajar

Guardar cambios:

```powershell
git status
git add .
git commit -m "actualiza save swimmer"
git push
```

## Que va en GitHub

Si:
- firmware `.ino`;
- codigo Android;
- herramientas de analisis;
- README y documentacion tecnica;
- archivos pequenos de evidencia;
- notas en `outputs/`;
- disenos y moldes livianos.

No:
- claves, tokens, credenciales, ngrok privado;
- bases de datos reales;
- videos grandes;
- zips pesados;
- builds generados;
- carpetas `build/`, `.gradle/`, `work/`, `tmp/`;
- informacion personal sensible de usuarios o nadadores reales.

## Archivos grandes

Guardar en Drive/OneDrive/copia externa:
- videos de pruebas;
- fotos originales pesadas;
- datasets completos;
- APKs finales de entrega;
- PDFs grandes;
- backups completos.

En GitHub se puede dejar un documento con enlaces o descripcion de esos archivos.

## Regla para no romper nada

Antes de cambiar de computadora:

```powershell
git status
git add .
git commit -m "guarda avance antes de cambiar de pc"
git push
```

En la otra computadora:

```powershell
git pull
```

## Si aparece conflicto

No borrar ni reemplazar a ciegas. Revisar:

```powershell
git status
```

Si el conflicto es en un archivo importante, resolverlo manualmente o pedir ayuda antes de hacer commit.

## Backup recomendado

Aunque GitHub sincronice el codigo, mantener una copia mensual completa de:

```text
C:\Users\Claudia\Documents\Codex\2026-07-09\save-swimmer-desarrollo-julio-2026\save-swimmer
```

en disco externo o nube. GitHub no reemplaza un backup completo del proyecto.
