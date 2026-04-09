# App Móvil de Informes de Mantenimiento de Grupo Electrógeno

## 1. Objetivo del proyecto

Desarrollar una app móvil Android simple y formal para registrar informes de mantenimiento de grupos electrógenos.

La app debe permitir:

- llenar un formulario técnico de mantenimiento
- guardar la información localmente en el dispositivo
- funcionar sin internet
- generar un PDF del informe con los datos ingresados
- el usuario toma fotos normalmente con su celular y luego adjunta 2 imágenes desde la galería
- permitir editar informes ya creados
- dejar el sistema preparado para sincronizar posteriormente los datos en formato JSON con Supabase

---

## 2. Alcance de la versión 1

### Incluye
- app Android
- formulario de mantenimiento
- almacenamiento local
- edición de informes
- generación local de PDF
- selección de 2 fotos desde galería:
  - foto antes
  - foto después
- visualización de historial de informes
- manejo de estado de sincronización
- estructura lista para sincronización de JSON con Supabase

### No incluye por ahora
- login o autenticación
- usuarios reales
- captura de foto con cámara dentro de la app
- envío de imágenes a una base de datos online
- envío del PDF a una base de datos online
- almacenamiento del PDF en una base de datos
- panel web administrativo
- numeración secuencial formal de informes

---

## 3. Flujo funcional esperado

1. El usuario abre la app.
2. Selecciona "Nuevo informe".
3. Llena el formulario completo.
4. Adjunta 2 fotos desde la galería del celular:
   - foto antes
   - foto después
5. Guarda el informe.
6. La app:
   - genera un UUID para el informe
   - guarda el JSON localmente
   - registra las rutas locales de ambas fotos
   - deja el estado del informe como `pending_sync`
7. Si el usuario desea exportar o imprimir:
   - la app genera el PDF localmente bajo demanda
   - permite compartirlo o exportarlo
   - el PDF no se almacena en ninguna base de datos
8. Si el usuario edita el informe:
   - se actualiza el JSON
   - se actualizan las rutas de fotos si fueron reemplazadas
   - el estado vuelve a `pending_sync`
9. Cuando exista conexión y se habilite el módulo de sincronización, el JSON podrá enviarse a Supabase.

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
- selector de imágenes desde galería en Flutter

## Sincronización online
- envío de JSON hacia Supabase
- integración mediante SDK oficial de Supabase para Flutter o por API REST si fuera necesario

## Backend / almacenamiento online definido
- Supabase
- la app debe quedar preparada para sincronizar el JSON de informes hacia Supabase cuando haya conectividad
- en la V1 la sincronización puede quedar lista a nivel de estructura aunque no necesariamente activada en la primera entrega

---

## 6. Reglas generales del proyecto

- Toda la información del formulario es obligatoria por ahora.
- El campo de observaciones y recomendaciones será un solo campo unido.
- El técnico no inicia sesión; escribe manualmente su nombre e identificación.
- Solo se permiten 2 fotos por informe.
- Las fotos se seleccionan desde la galería del dispositivo.
- Las fotos son:
  - una foto antes
  - una foto después
- Las fotos se guardan localmente y se usan en el PDF.
- Las fotos no se envían a ninguna base online en la V1.
- El PDF se genera solo localmente.
- El PDF no se almacena en ninguna base de datos.
- El JSON sí debe quedar listo para sincronización con Supabase.
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

## 7.8 Fotos
Campos:
- Foto antes
- Foto después

Reglas:
- ambas son obligatorias
- se seleccionan desde galería
- se guardan localmente
- se incluyen en el PDF
- no se envían a la base online por ahora

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
- Fotos

## 8.3 Pantalla de detalle / resumen
Acciones:
- Ver informe
- Editar informe
- Generar PDF
- Compartir PDF
- Exportar PDF

## 8.4 Pantalla de historial
Mostrar listado con:
- fecha
- técnico
- ubicación
- estado de sincronización
- acceso a editar
- acceso a generar/compartir PDF

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
- foto_antes_ruta_local
- foto_despues_ruta_local

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
- solo cuando la sincronización con Supabase sea exitosa cambia a `synced`

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
  "fotos": {
    "antes_ruta_local": "/ruta/local/fotos/antes_b7a1c1f4.jpg",
    "despues_ruta_local": "/ruta/local/fotos/despues_b7a1c1f4.jpg"
  },
  "estado_sync": "pending_sync",
  "fecha_creacion": "2026-04-07T15:30:00",
  "fecha_actualizacion": "2026-04-07T15:30:00",
  "fecha_sync": null
}
```

## 12. Reglas del PDF
- El PDF debe basarse visualmente en el formato - proporcionado por el cliente.
- Debe incluir logo.
- Debe reflejar exactamente los datos del formulario.
- Debe incluir las 2 fotos:
  - antes
  - después
-Debe incluir espacios para firmas:
  - técnico
  - responsable / cliente
- No se requiere firma digital en la app por ahora.
- El PDF se genera localmente solo cuando el usuario lo necesite.
- El PDF no se guarda en ninguna base de datos online.
- El PDF se usa solo para visualizar, compartir, exportar o imprimir.
## 13. Reglas de almacenamiento local
- El JSON se guarda localmente.
- Las 2 fotos se guardan o referencian localmente.
- El PDF se genera localmente bajo demanda.
- El PDF no necesita almacenarse en ninguna base de datos.
- La app debe poder abrir informes existentes, editarlos y - volver a generar su PDF cuando sea necesario.
- La app debe mostrar el estado de sincronización del informe.
## 14. Reglas de sincronización futura
- La sincronización enviará solo JSON.
- No se envían fotos en la V1.
- No se envía el PDF en la V1.
- La base de datos online definida es Supabase.
- La app debe quedar preparada para integrar la sincronización con Supabase desde el inicio.
- El JSON deberá enviarse a Supabase cuando exista conexión y se implemente el flujo de sincronización.
- Si la sincronización es exitosa, el informe cambia a `synced`.
- Si la sincronización falla, el informe puede quedar en `sync_error`.
## 15. Prioridades de desarrollo
### Fase 1
- estructura del proyecto Flutter
- modelo local de datos
- formulario
- guardado local
- listado de informes
- edición de informes
### Fase 2
- selección de 2 fotos desde galería
- generación local de PDF
- compartir/exportar PDF
### Fase 3
- integración de sincronización JSON con Supabase
- control de estados
- mejoras visuales
## 16. Resultado esperado de la V1

Una app Android funcional que permita:

crear informes
editarlos
guardar todo localmente
adjuntar 2 fotos desde galería
generar un PDF formal localmente
compartir o exportar el PDF para impresión
dejar el registro listo para sincronización con Supabase
