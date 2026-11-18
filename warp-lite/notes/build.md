# Build de Warp OSS en Windows

## Herramientas

| Herramienta | Ruta / versión |
|---|---|
| Rust | 1.92.0 (pin de `rust-toolchain.toml`) |
| MSVC | `D:\buildtools` (14.44) |
| Windows SDK | 10.0.26100.0 |
| CMake | `D:\dev\warp-lite\tools\cmake\cmake-4.4.4-windows-x86_64\bin\cmake.exe` |
| protoc | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.Protobuf_...\bin\protoc.exe` (36.2) |
| LLVM/libclang | `C:\Program Files\LLVM\bin` (23.1.6) |
| Git LFS | 3.6.1 |
| Python | 3.11.15 (para `map_deps.py`) |

## Comando

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\warp-lite\scripts\build-warp.ps1 -Profile release -Features "gui,skip_login" -Jobs 6
```

El script:

- Añade CMake/protoc/LLVM al `PATH`.
- Configura `LIBCLANG_PATH`.
- Compila `warp-oss` en `release` con `skip_login`.
- Escribe el log y el informe de timings en `notes/bench/`.

## Por qué `skip_login`

El canal OSS usa la configuración de producción de Warp. Sin `skip_login`, el arranque probablemente se queda en login/onboarding. `skip_login` crea un usuario de test y credenciales falsas; las peticiones autenticadas fallan, pero el terminal local debe funcionar. Es la vía para medir el core sin cuenta.

## Por qué no `CARGO_TARGET_DIR`

`app/build.rs` copia `conpty.dll`, `OpenConsole.exe`, `dxcompiler.dll` y `dxil.dll` a `<workspace>/target/<profile>` usando `warp_util::path::app_target_dir`, que **ignora** `CARGO_TARGET_DIR`. Si cambias el target dir, el binario se queda sin esas DLLs al ejecutarlo. Por eso el build usa el `target/` del repo.

## Ejecutar

```powershell
.\target\release\warp-oss.exe
```

Si falta alguna DLL, están en `app\assets\windows\x64\` y `app/build.rs` las copia al target.

## Troubleshooting

- **CMake “Could not find CMAKE_ROOT”**: la extracción del zip quedó incompleta. Reextraer con `tar.exe -xf` y comprobar que existe `share\cmake-4.4\Modules`.
- **protoc not found**: el script busca en `%LOCALAPPDATA%\Microsoft\WinGet\Packages`; no hace falta reiniciar el shell.
- **Path too long**: el repo usa nombres de perfil cortos (`rlto`) para evitarlo. Si aparece, habilitar long paths o mover el checkout a una ruta más corta.
- **Fallo de `aws-lc-sys`/NASM**: instalar NASM portable y añadirlo al `PATH`.
- **Fallo de enlazado**: comprobar que `D:\buildtools` tiene `VC.Tools.x86.x64` y el Windows SDK; `rustc` los localiza vía `vswhere`.

