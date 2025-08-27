# 🎨 Tema de Alto Contraste para Cursor

Este proyecto incluye configuraciones para maximizar el contraste en el editor Cursor, mejorando significativamente la legibilidad y accesibilidad.

## 📁 Archivos de Configuración

### 1. `.cursorrules` - Configuración principal de Cursor
- Tema de alto contraste
- Colores personalizados para máximo contraste
- Configuración de tipografía optimizada
- Ajustes del editor para desarrollo Flutter

### 2. `.vscode/settings.json` - Configuración de VS Code/Cursor
- Personalización completa de colores
- Configuración del editor
- Ajustes específicos para Flutter/Dart
- Configuración de extensiones

## 🚀 Cómo Aplicar el Tema

### Opción 1: Usar el archivo .cursorrules
1. Asegúrate de que el archivo `.cursorrules` esté en la raíz del proyecto
2. Reinicia Cursor
3. El tema se aplicará automáticamente

### Opción 2: Configuración manual en Cursor
1. Abre Cursor
2. Presiona `Ctrl + Shift + P` (Windows) o `Cmd + Shift + P` (Mac)
3. Escribe "Preferences: Color Theme"
4. Selecciona "High Contrast"

### Opción 3: Configuración de colores personalizados
1. Presiona `Ctrl + Shift + P` (Windows) o `Cmd + Shift + P` (Mac)
2. Escribe "Preferences: Open Settings (JSON)"
3. Copia y pega el contenido de `.vscode/settings.json`

## 🎯 Características del Tema

### ✨ **Máximo Contraste**
- **Fondo**: Negro puro (#000000)
- **Texto**: Blanco puro (#FFFFFF)
- **Línea actual**: Gris muy oscuro (#1A1A1A)
- **Selección**: Azul oscuro (#264F78)

### 🔍 **Mejor Visibilidad**
- **Errores**: Rojo vibrante (#F44747)
- **Warnings**: Amarillo brillante (#FFCC02)
- **Info**: Azul claro (#75BEFF)
- **Búsqueda**: Gris medio (#515C6A)

### 📝 **Tipografía Optimizada**
- **Fuente**: Consolas, Courier New, monospace
- **Tamaño**: 14px
- **Interlineado**: 1.5
- **Peso**: Normal para mejor legibilidad

### 🎮 **Funcionalidades del Editor**
- **Minimap**: Habilitado con slider siempre visible
- **Scrollbars**: Visibles con tamaño 14px
- **Guías**: Indentación y brackets resaltados
- **Cursor**: Línea de 2px con parpadeo

## 🔧 Personalización Adicional

### Cambiar Colores Específicos
Edita el archivo `.vscode/settings.json` y modifica los valores en `workbench.colorCustomizations`:

```json
"workbench.colorCustomizations": {
  "editor.background": "#000000",  // Fondo negro
  "editor.foreground": "#FFFFFF",  // Texto blanco
  "editor.lineHighlightBackground": "#1A1A1A"  // Línea actual
}
```

### Ajustar Tamaño de Fuente
```json
"editor.fontSize": 16,  // Cambiar a 16px
"editor.lineHeight": 1.8  // Cambiar interlineado
```

### Modificar Tema Base
```json
"workbench.colorTheme": "Dark+ (default dark)"  // Otro tema oscuro
```

## 🌟 Beneficios del Alto Contraste

1. **Mejor Legibilidad**: Texto blanco sobre negro es más fácil de leer
2. **Reducción de Fatiga Visual**: Menos esfuerzo para distinguir elementos
3. **Accesibilidad**: Cumple con estándares WCAG AAA
4. **Productividad**: Enfoque mejorado en el código
5. **Adaptación a Diferentes Luces**: Funciona bien en cualquier ambiente

## 🐛 Solución de Problemas

### El tema no se aplica
- Verifica que los archivos estén en la ubicación correcta
- Reinicia Cursor completamente
- Verifica que no haya conflictos con otras configuraciones

### Colores no se ven como esperado
- Limpia la caché de Cursor
- Verifica que las extensiones no estén sobrescribiendo el tema
- Asegúrate de que el archivo JSON esté bien formateado

### Problemas de rendimiento
- Reduce el tamaño de fuente si es necesario
- Deshabilita el minimap si causa lentitud
- Ajusta la configuración de bracket matching

## 📚 Recursos Adicionales

- [Documentación oficial de Cursor](https://cursor.sh/docs)
- [Guía de temas de VS Code](https://code.visualstudio.com/docs/getstarted/themes)
- [Estándares de accesibilidad WCAG](https://www.w3.org/WAI/WCAG21/quickref/)

## 🤝 Contribuciones

Si tienes sugerencias para mejorar el tema o encuentras problemas, por favor:
1. Abre un issue en el repositorio
2. Describe el problema o sugerencia
3. Incluye capturas de pantalla si es relevante

---

**¡Disfruta de tu editor Cursor con máximo contraste! 🎉**
