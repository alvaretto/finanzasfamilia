# /run - Ejecutar App en Emulador

Inicia el emulador Android y ejecuta la aplicación.

## Acciones

1. Iniciar emulador (si no está corriendo):

```bash
$ANDROID_HOME/emulator/emulator -avd FinanzasEnv &
```

2. Esperar a que el emulador esté listo:

```bash
adb wait-for-device
```

3. Ejecutar la aplicación:

```bash
fvm flutter run
```

## Opciones

- **Hot Reload**: Presiona `r` en la terminal
- **Hot Restart**: Presiona `R` en la terminal
- **Quit**: Presiona `q` en la terminal

## Troubleshooting

Si el emulador no inicia:
```bash
# Verificar AVDs disponibles
$ANDROID_HOME/emulator/emulator -list-avds

# Verificar KVM
lsmod | grep kvm
```

Si Flutter no detecta el dispositivo:
```bash
fvm flutter devices
adb devices
```
