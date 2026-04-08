# APP_CONTROL_INFORMES

# App Móvil de Informes de Mantenimiento de Grupo Electrógeno

## 1. Objetivo del proyecto

Desarrollar una app móvil Android simple y formal para registrar informes de mantenimiento de grupos electrógenos.

La app debe permitir:

- llenar un formulario técnico de mantenimiento
- guardar la información localmente en el dispositivo
- funcionar sin internet
- generar un PDF del informe con los datos ingresados
- tomar y guardar una foto localmente
- permitir editar informes ya creados
- sincronizar posteriormente los datos en formato JSON a un backend cuando exista conexión a internet

## 2. Alcance de la versión 1

### Incluye
- app Android
- formulario de mantenimiento
- almacenamiento local
- edición de informes
- generación de PDF
- captura o selección de 1 foto
- visualización de historial de informes
- manejo de estado de sincronización
- sincronización futura de JSON a servidor

### No incluye por ahora
- login o autenticación
- usuarios reales
- firma digital dentro de la app
- envío de imágenes al backend
- envío del PDF al backend
- panel web administrativo
- numeración secuencial formal de informes

---

## 3. Flujo funcional esperado

1. El usuario abre la app.
2. Selecciona "Nuevo informe".
3. Llena el formulario completo.
4. Adjunta 1 foto.
5. Guarda el informe.
6. La app:
   - genera un UUID para el informe
   - guarda el JSON localmente
   - guarda la foto localmente con el nombre del UUID
   - genera el PDF localmente
   - guarda la ruta local del PDF
   - deja el estado del informe como `pending_sync`
7. Si el usuario edita el informe:
   - se actualiza el JSON
   - se regenera el PDF
   - si cambia la foto, se reemplaza la foto local
   - el estado vuelve a `pending_sync`
8. Cuando haya internet, el JSON podrá sincronizarse con un backend.

---

## 4. Plataforma objetivo

- Android únicamente

---

## 5. Stack sugerido

## Frontend móvil
- Flutter

## Almacenamiento local
- SQLite (preferido)
- opcionalmente Hive si se decide simplificar almacenamiento local

## Generación de PDF
- librería de PDF para Flutter

## Manejo de imágenes
- image_picker o cámara nativa desde Flutter

## Sincronización futura
- envío de JSON por API REST

## Backend futuro
- FastAPI + PostgreSQL
- este backend no forma parte de la versión 1 inicial, pero la app debe quedar preparada para sincronización posterior

---

## 6. Reglas generales del proyecto

- Toda la información del formulario es obligatoria por ahora.
- El campo de observaciones y recomendaciones será un solo campo unido.
- El técnico no inicia sesión; escribe manualmente su nombre e identificación.
- Solo se permite 1 foto por informe.
- La foto se guarda localmente, no se envía al backend en la V1.
- El PDF se genera localmente.
- El JSON sí debe quedar listo para futura sincronización.
- No habrá numeración secuencial visible para el usuario.
- Internamente cada informe se identifica por UUID.
- Todo informe debe poder editarse.
- Todo informe editado vuelve al estado `pending_sync`.

---

## 7. Estructura del formulario

# Informe de Mantenimiento de Grupo Electrógeno

## 7.1 Datos Generales
Campos:
- Fecha del servicio
- Tipo de mantenimiento
  - Preventivo
  - Correctivo
  - Emergencia
- Ubicación / sede
- Horómetro actual

## 7.2 Identificación del Equipo
Campos:
- Marca del motor
- Modelo del motor
- Marca del alternador
- Potencia (kVA/kW)
- Serie del equipo
- Año de fabricación

## 7.3 Checklist de Inspección y Tareas

Cada fila del checklist tendrá:
- Sistema
- Ítem a revisar
- Estado
- Observación

### Estados permitidos
- OK
- Requiere acción
- N/A

### Filas fijas del checklist

1. Sistema: Lubricación  
   Ítem: Nivel de aceite / Cambio realizado

2. Sistema: Combustible  
   Ítem: Nivel de tanque / Fugas / Filtros

3. Sistema: Refrigeración  
   Ítem: Nivel refrigerante / Radiador / Mangueras

4. Sistema: Admisión/Escape  
   Ítem: Filtro de aire / Estado del silenciador

5. Sistema: Eléctrico  
   Ítem: Estado de baterías (Voltaje/Bornes)

6. Sistema: Control  
   Ítem: Panel de control / Alarmas / Sensores

7. Sistema: Mecánico  
   Ítem: Correas (tensión/desgaste) / Soportes

## 7.4 Pruebas de Funcionamiento
Campos:
- Voltaje L1
- Voltaje L2
- Voltaje L3
- Frecuencia (Hz)
- Presión de aceite (PSI)
- Temperatura (°C)
- Ruidos o vibraciones anormales
  - Sí
  - No

## 7.5 Descripción de Actividades / Repuestos Utilizados
Campo:
- texto largo obligatorio

## 7.6 Observaciones y Recomendaciones
Campo:
- texto largo obligatorio

## 7.7 Validación
### Técnico
- Nombre del técnico
- Identificación del técnico

### Responsable / Cliente
- Nombre del responsable / cliente
- Cargo del responsable / cliente

## 7.8 Foto
- 1 foto obligatoria
- debe guardarse localmente
- el archivo de foto debe llamarse con el UUID del informe
- ejemplo: `b7a1c1f4-7e90-4c8c-9f5f-0f8d5cb7d0d1.jpg`

---

## 8. Pantallas mínimas requeridas

## 8.1 Pantalla de inicio
Opciones:
- Nuevo informe
- Ver informes guardados
- Ver pendientes de envío

## 8.2 Pantalla de formulario
Secciones:
- Datos Generales
- Identificación del Equipo
- Checklist
- Pruebas
- Actividades / Repuestos
- Observaciones y Recomendaciones
- Validación
- Foto

## 8.3 Pantalla de detalle / resumen
Acciones:
- Ver informe
- Editar informe
- Generar PDF
- Compartir PDF

## 8.4 Pantalla de historial
Mostrar listado con:
- fecha
- técnico
- ubicación
- estado de sincronización
- acceso a editar
- acceso a ver/compartir PDF

---

## 9. Modelo de datos sugerido

## 9.1 Entidad principal: Informe

Campos sugeridos:

- id_local
- uuid
- fecha_servicio
- tipo_mantenimiento
- ubicacion_sede
- horometro_actual

### Equipo
- marca_motor
- modelo_motor
- marca_alternador
- potencia
- serie_equipo
- anio_fabricacion

### Checklist
Lista de objetos con:
- sistema
- item
- estado
- observacion

### Pruebas
- voltaje_l1
- voltaje_l2
- voltaje_l3
- frecuencia_hz
- presion_aceite_psi
- temperatura_c
- ruidos_vibraciones_anormales

### Textos
- actividades_repuestos
- observaciones_recomendaciones

### Validación
- tecnico_nombre
- tecnico_identificacion
- responsable_nombre
- responsable_cargo

### Archivos
- foto_uuid_nombre_archivo
- foto_ruta_local
- pdf_ruta_local

### Control
- estado_sync
- fecha_creacion
- fecha_actualizacion
- fecha_sync

---

## 10. Estados de sincronización

Valores previstos:
- `draft`
- `pending_sync`
- `synced`
- `sync_error`

Para la V1, como mínimo usar:
- `pending_sync`
- `synced`

Reglas:
- todo informe nuevo queda como `pending_sync`
- todo informe editado vuelve a `pending_sync`
- solo cuando la sincronización sea exitosa cambia a `synced`

---

## 11. Estructura JSON sugerida

```json
{
  "uuid": "b7a1c1f4-7e90-4c8c-9f5f-0f8d5cb7d0d1",
  "fecha_servicio": "2026-04-07",
  "tipo_mantenimiento": "preventivo",
  "ubicacion_sede": "Sucursal N1",
  "horometro_actual": "867.5",
  "equipo": {
    "marca_motor": "Cummins",
    "modelo_motor": "6BT",
    "marca_alternador": "Stamford",
    "potencia": "96.8 KVA",
    "serie_equipo": "ABC123",
    "anio_fabricacion": "2020"
  },
  "checklist": [
    {
      "sistema": "Lubricación",
      "item": "Nivel de aceite / Cambio realizado",
      "estado": "ok",
      "observacion": "Sin novedades"
    },
    {
      "sistema": "Combustible",
      "item": "Nivel de tanque / Fugas / Filtros",
      "estado": "requiere_accion",
      "observacion": "Filtro con suciedad"
    }
  ],
  "pruebas": {
    "voltaje_l1": "220",
    "voltaje_l2": "220",
    "voltaje_l3": "220",
    "frecuencia_hz": "60",
    "presion_aceite_psi": "45",
    "temperatura_c": "82",
    "ruidos_vibraciones_anormales": "no"
  },
  "actividades_repuestos": "Cambio de aceite y revisión de filtros.",
  "observaciones_recomendaciones": "Se recomienda revisar filtro de combustible en próximo mantenimiento.",
  "tecnico": {
    "nombre": "Juan Pérez",
    "identificacion": "1723456789"
  },
  "responsable_cliente": {
    "nombre": "Carlos Mena",
    "cargo": "Jefe de local"
  },
  "foto": {
    "uuid_nombre_archivo": "b7a1c1f4-7e90-4c8c-9f5f-0f8d5cb7d0d1.jpg",
    "ruta_local": "/ruta/local/foto/b7a1c1f4-7e90-4c8c-9f5f-0f8d5cb7d0d1.jpg"
  },
  "pdf": {
    "ruta_local": "/ruta/local/pdf/b7a1c1f4-7e90-4c8c-9f5f-0f8d5cb7d0d1.pdf"
  },
  "estado_sync": "pending_sync",
  "fecha_creacion": "2026-04-07T15:30:00",
  "fecha_actualizacion": "2026-04-07T15:30:00",
  "fecha_sync": null
}
