# 💊 Pauta Médica - Gestión de Medicamentos

Una aplicación móvil completa desarrollada con Flutter y BLoC para gestionar fichas de medicamentos con recordatorios de horarios de toma.

## 🎯 **Funcionalidades Principales**

### ✅ **Gestión Completa de Medicamentos**
- **Alta**: Agregar nuevos medicamentos con foto, nombre, posología y horarios
- **Modificación**: Editar información existente de medicamentos
- **Eliminación**: Eliminar medicamentos con confirmación
- **Visualización**: Lista ordenada por próxima dosis

### 📱 **Interfaz de Usuario Intuitiva**
- **Lista Scrollable**: Vista vertical con tarjetas de medicamentos
- **Imágenes**: Foto del medicamento a la izquierda (tocable para ampliar)
- **Información**: Nombre, posología y horarios visibles
- **Acciones**: Botones de editar y eliminar a la derecha

### 🕐 **Sistema de Horarios Inteligente**
- **Múltiples Horarios**: Configurar varios horarios de toma por día
- **Ordenamiento Automático**: Lista ordenada de la dosis más próxima a la más lejana
- **Indicadores Visuales**: Alertas para dosis vencidas
- **Gestión de Tiempo**: Selector de hora intuitivo

## 🏗️ **Arquitectura Técnica**

### **Patrón BLoC (Business Logic Component)**
- **MedicationBloc**: Gestiona el estado de los medicamentos
- **Eventos**: Load, Add, Update, Delete
- **Estados**: Initial, Loading, Loaded, Error

### **Capas de la Aplicación**
```
📱 Presentation Layer (UI)
├── Pages: MedicationListPage, AddEditMedicationPage
├── Widgets: MedicationListItem, AddMedicationFAB
└── BLoC: MedicationBloc

🔧 Domain Layer (Business Logic)
├── Entities: Medication
└── Repositories: MedicationRepository (abstract)

💾 Data Layer (Storage)
├── Repositories: MedicationRepositoryImpl
└── Database: SQLite local
```

### **Tecnologías Utilizadas**
- **Flutter**: Framework de UI multiplataforma
- **BLoC**: Gestión de estado reactivo
- **SQLite**: Base de datos local
- **Image Picker**: Selección de imágenes
- **Path Provider**: Gestión de archivos locales

## 🚀 **Cómo Usar la Aplicación**

### **1. Agregar un Nuevo Medicamento**
1. Toca el botón **"+"** flotante
2. Selecciona una **foto** del medicamento
3. Ingresa el **nombre** del medicamento
4. Escribe la **posología** (ej: "1 comprimido cada 8 horas")
5. Agrega **horarios** de toma usando el selector de tiempo
6. Toca **"Guardar Medicamento"**

### **2. Ver la Lista de Medicamentos**
- Los medicamentos se muestran **ordenados por próxima dosis**
- Cada tarjeta muestra:
  - **Imagen** del medicamento (toca para ampliar)
  - **Nombre** y **posología**
  - **Próxima dosis** con indicador de tiempo
  - **Horarios** configurados
  - **Botones** de editar y eliminar

### **3. Editar un Medicamento**
1. Toca el **botón de editar** (ícono de lápiz)
2. Modifica la información deseada
3. Toca el **botón de guardar** en la barra superior

### **4. Eliminar un Medicamento**
1. Toca el **botón de eliminar** (ícono de papelera)
2. Confirma la eliminación en el diálogo
3. El medicamento se elimina de la base de datos

### **5. Ver Imagen en Grande**
- Toca sobre la **imagen** del medicamento en la lista
- Se abre una vista completa con zoom
- El nombre del medicamento aparece en el pie de imagen

## 🎨 **Características de Diseño**

### **Tema de Alto Contraste**
- **Colores vibrantes** para mejor visibilidad
- **Tipografías bold** para mejor legibilidad
- **Sombras pronunciadas** para profundidad visual
- **Indicadores de color** para estados (vencido, próximo, etc.)

### **Responsive Design**
- **Adaptable** a diferentes tamaños de pantalla
- **Scroll suave** en listas largas
- **Touch-friendly** con botones de tamaño adecuado
- **Feedback visual** en todas las interacciones

## 📱 **Permisos Requeridos**

### **Android**
- **Almacenamiento**: Para guardar fotos de medicamentos
- **Cámara**: Para tomar fotos (opcional)

### **iOS**
- **Fotos**: Para acceder a la galería
- **Cámara**: Para tomar fotos (opcional)

## 🔧 **Configuración del Proyecto**

### **Dependencias Principales**
```yaml
dependencies:
  flutter_bloc: ^9.1.1
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  equatable: ^2.0.7
```

### **Estructura de Carpetas**
```
lib/
├── app/
│   ├── app.dart
│   └── bloc_observer.dart
├── features/
│   └── medication/
│       ├── data/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
└── main.dart
```

## 🚀 **Ejecutar la Aplicación**

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar en dispositivo/emulador**:
   ```bash
   flutter run
   ```

3. **Construir APK**:
   ```bash
   flutter build apk
   ```

## 🌟 **Características Destacadas**

### **Inteligencia de Horarios**
- **Cálculo automático** de próxima dosis
- **Ordenamiento inteligente** por prioridad temporal
- **Alertas visuales** para dosis vencidas
- **Gestión de múltiples horarios** por medicamento

### **Experiencia de Usuario**
- **Navegación intuitiva** entre pantallas
- **Confirmaciones** para acciones destructivas
- **Validaciones** en tiempo real
- **Feedback visual** en todas las operaciones

### **Persistencia de Datos**
- **Almacenamiento local** con SQLite
- **Gestión de imágenes** optimizada
- **Backup automático** de configuraciones
- **Sincronización** de estado en tiempo real

## 🔮 **Próximas Funcionalidades**

- [ ] **Notificaciones push** para recordatorios
- [ ] **Historial de tomas** con registro de cumplimiento
- [ ] **Sincronización en la nube** para múltiples dispositivos
- [ ] **Reportes y estadísticas** de adherencia al tratamiento
- [ ] **Modo offline** completo
- [ ] **Exportación de datos** en múltiples formatos

## 🤝 **Contribuciones**

¡Las contribuciones son bienvenidas! Por favor:

1. **Fork** el repositorio
2. Crea una **rama** para tu feature
3. **Commit** tus cambios
4. **Push** a la rama
5. Abre un **Pull Request**

## 📄 **Licencia**

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

**¡Disfruta de tu aplicación de gestión de medicamentos! 💊✨**
