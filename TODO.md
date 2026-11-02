# TODO: Fix Importación Error Database UNIQUE constraint doses.id

Estado: En progreso

## Pasos:

- [x]   1. Editar `lib/features/medication/data/repositories/medication_repository_impl.dart`:
    - En `importMedications()`: DROP IF EXISTS + recreate tables + inserts con ConflictAlgorithm.replace + logs. ✓ Completado.
- [x]   2. En `generateDoses()` / `regenerate`: Añadir ConflictAlgorithm.replace al batch.insert para evitar errores de concurrencia post-importación. ✓ Completado.
- [x]   3. Corregir firmas de import/export en Repo, Interfaz y UseCases para devolver estadísticas. ✓ Completado.
- [ ] 3.1. Asegurar que `domain/usecases/import_medications.dart` y `export_medications.dart` devuelven `Future<Map<String, dynamic>?>`.
- [ ]   4. Verificar no error en OPPO si posible, marcar completado.

Próximos: Editar archivo principal.Próximos: Editar archivo principal.
