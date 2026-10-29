# HealthPP iOS

App de iPhone que recibe por Bluetooth LE los datos de salud de la app HealthPP del Galaxy Watch 7.

- El reloj actúa como servidor GATT (servicio `0x181A`, característica `0x2A37`).
- El iPhone escanea ese servicio, se conecta y lee el JSON cada 10 s.

## Compilar en GitHub
1. Sube este proyecto a un repo de GitHub (rama `main`).
2. Ve a **Actions → Build iOS → Run workflow** (o simplemente haz push).
3. Descarga el artefacto `HealthPPiOS-unsigned-ipa`.

## Instalar en el iPhone
El IPA sale sin firmar. Fírmalo e instálalo con Sideloadly o AltStore (vale un Apple ID gratuito; la firma caduca a los 7 días).
