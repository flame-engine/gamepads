# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-04-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.7`](#gamepads---v017)
 - [`gamepads_windows` - `v0.1.4`](#gamepads_windows---v014)

---

#### `gamepads` - `v0.1.7`

 - Bumped dependencies.

#### `gamepads_windows` - `v0.1.4`

 - **FIX**: Use `std::optional` for return from `GamepadListenerProc` ([#58](https://github.com/flame-engine/gamepads/issues/58)). ([fbf52fd2](https://github.com/flame-engine/gamepads/commit/fbf52fd281cec345b110c8a5c63053cafd4571cd))


## 2025-04-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.6`](#gamepads---v016)
 - [`gamepads_windows` - `v0.1.3`](#gamepads_windows---v013)

---

#### `gamepads` - `v0.1.6`

 - Bump dependencies.

#### `gamepads_windows` - `v0.1.3`

 - **FIX**: Window resizing bug ([#56](https://github.com/flame-engine/gamepads/issues/56)). ([ae7c8f3d](https://github.com/flame-engine/gamepads/commit/ae7c8f3d7f670c7cbb3d9c55119736cbf4a8f54a))


## 2025-02-11

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.5`](#gamepads---v015)

---

#### `gamepads` - `v0.1.5`

 - Bump version to 0.1.5 (due to previous manual versioning)


## 2025-02-10

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.4`](#gamepads---v014)
 - [`gamepads_windows` - `v0.1.2`](#gamepads_windows---v012)
 - [`gamepads_android` - `v0.1.3`](#gamepads_android---v013)

---

#### `gamepads` - `v0.1.4`

 - Bump "gamepads" to `0.1.4`.

#### `gamepads_windows` - `v0.1.2`

 - **FIX**: Update gamepad.cpp includes to fix windows compilation error ([#51](https://github.com/flame-engine/gamepads/issues/51)). ([d6b8ab43](https://github.com/flame-engine/gamepads/commit/d6b8ab4346b9e5f617dde5fcb54457721a54cb73))

#### `gamepads_android` - `v0.1.3`

 - **FEAT**: Add AXIS_BRAKE and AXIS_GAS as supported axes on Android. ([#50](https://github.com/flame-engine/gamepads/issues/50)). ([adfb8d1f](https://github.com/flame-engine/gamepads/commit/adfb8d1fa2206571d6c59315697d3cf9c951b423))


## 2024-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.4`](#gamepads---v014)
 - [`gamepads_platform_interface` - `v0.1.2+1`](#gamepads_platform_interface---v0121)
 - [`gamepads_linux` - `v0.1.1+3`](#gamepads_linux---v0113)
 - [`gamepads_windows` - `v0.1.1+3`](#gamepads_windows---v0113)
 - [`gamepads_darwin` - `v0.1.2+2`](#gamepads_darwin---v0122)
 - [`gamepads_ios` - `v0.1.2+2`](#gamepads_ios---v0122)
 - [`gamepads_android` - `v0.1.2+2`](#gamepads_android---v0122)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `gamepads_linux` - `v0.1.1+3`
 - `gamepads_windows` - `v0.1.1+3`
 - `gamepads_darwin` - `v0.1.2+2`
 - `gamepads_ios` - `v0.1.2+2`
 - `gamepads_android` - `v0.1.2+2`

---

#### `gamepads` - `v0.1.4`

 - fix: Take other values than 1 into consideration for pressed buttons

#### `gamepads_platform_interface` - `v0.1.2+1`

 - **FIX**: Take other values than 1 into consideration for pressed buttons ([#46](https://github.com/flame-engine/gamepads/issues/46)). ([8c27112d](https://github.com/flame-engine/gamepads/commit/8c27112ddf1f2d0ea8e07bdcdd13c84546a72836))


## 2024-10-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.3`](#gamepads---v013)
 - [`gamepads_platform_interface` - `v0.1.2`](#gamepads_platform_interface---v012)
 - [`gamepads_linux` - `v0.1.1+2`](#gamepads_linux---v0112)
 - [`gamepads_windows` - `v0.1.1+2`](#gamepads_windows---v0112)
 - [`gamepads_darwin` - `v0.1.2+1`](#gamepads_darwin---v0121)
 - [`gamepads_ios` - `v0.1.2+1`](#gamepads_ios---v0121)
 - [`gamepads_android` - `v0.1.2+1`](#gamepads_android---v0121)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `gamepads_linux` - `v0.1.1+2`
 - `gamepads_windows` - `v0.1.1+2`
 - `gamepads_darwin` - `v0.1.2+1`
 - `gamepads_ios` - `v0.1.2+1`
 - `gamepads_android` - `v0.1.2+1`

---

#### `gamepads` - `v0.1.3`

 - **FEAT**: Added GamepadState that can be updated ([#43](https://github.com/flame-engine/gamepads/issues/43)). ([0c9890e8](https://github.com/flame-engine/gamepads/commit/0c9890e80c423621c52226521612e307d8419308))

#### `gamepads_platform_interface` - `v0.1.2`

 - **FEAT**: Added GamepadState that can be updated ([#43](https://github.com/flame-engine/gamepads/issues/43)). ([0c9890e8](https://github.com/flame-engine/gamepads/commit/0c9890e80c423621c52226521612e307d8419308))


## 2024-07-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.2`](#gamepads---v012)
 - [`gamepads_android` - `v0.1.2`](#gamepads_android---v012)
 - [`gamepads_darwin` - `v0.1.2`](#gamepads_darwin---v012)
 - [`gamepads_ios` - `v0.1.2`](#gamepads_ios---v012)
 - [`gamepads_linux` - `v0.1.1+1`](#gamepads_linux---v0111)
 - [`gamepads_windows` - `v0.1.1+1`](#gamepads_windows---v0111)

---

#### `gamepads` - `v0.1.2`

 - **REFACTOR**: Lint Kotlin, C and C++ code ([#6](https://github.com/flame-engine/gamepads/issues/6)). ([6d3e9334](https://github.com/flame-engine/gamepads/commit/6d3e9334072d24525ed7ccf9f8c7fa481c8373fc))
 - **FEAT**: Support for Android ([#35](https://github.com/flame-engine/gamepads/issues/35)). ([6996109e](https://github.com/flame-engine/gamepads/commit/6996109e4452406990191af1b1f10d18461c3bfc))
 - **FEAT**: Support for iOS ([#30](https://github.com/flame-engine/gamepads/issues/30)). ([e8cb9777](https://github.com/flame-engine/gamepads/commit/e8cb9777d42cf35f4b67629a1e6b5f03517edd35))

#### `gamepads_android` - `v0.1.2`

 - **FEAT**: Support for Android ([#35](https://github.com/flame-engine/gamepads/issues/35)). ([6996109e](https://github.com/flame-engine/gamepads/commit/6996109e4452406990191af1b1f10d18461c3bfc))

#### `gamepads_darwin` - `v0.1.2`

 - **FIX**: Remove extendedGamepad from gamepads array on disconnect ([#39](https://github.com/flame-engine/gamepads/issues/39)). ([b24257d3](https://github.com/flame-engine/gamepads/commit/b24257d3e467385351bf5ba14780eacfa318cd0d))
 - **FIX**: Update GamepadsDarwinPlugin.swift to conditionally reference sfSymbolsName ([#23](https://github.com/flame-engine/gamepads/issues/23)). ([cfe9d339](https://github.com/flame-engine/gamepads/commit/cfe9d339f5db69b67f93179a092cd70466ecd4e1))
 - **FIX**: Fix for old mac os support ([#1](https://github.com/flame-engine/gamepads/issues/1)). ([090c3be8](https://github.com/flame-engine/gamepads/commit/090c3be8313aab791160e53450f163d1104f579c))
 - **FEAT**: Support for iOS ([#30](https://github.com/flame-engine/gamepads/issues/30)). ([e8cb9777](https://github.com/flame-engine/gamepads/commit/e8cb9777d42cf35f4b67629a1e6b5f03517edd35))

#### `gamepads_ios` - `v0.1.2`

 - **FIX**: Remove extendedGamepad from gamepads array on disconnect ([#39](https://github.com/flame-engine/gamepads/issues/39)). ([b24257d3](https://github.com/flame-engine/gamepads/commit/b24257d3e467385351bf5ba14780eacfa318cd0d))
 - **FEAT**: Support for Android ([#35](https://github.com/flame-engine/gamepads/issues/35)). ([6996109e](https://github.com/flame-engine/gamepads/commit/6996109e4452406990191af1b1f10d18461c3bfc))
 - **FEAT**: Support for iOS ([#30](https://github.com/flame-engine/gamepads/issues/30)). ([e8cb9777](https://github.com/flame-engine/gamepads/commit/e8cb9777d42cf35f4b67629a1e6b5f03517edd35))

#### `gamepads_linux` - `v0.1.1+1`

 - **REFACTOR**: Lint Kotlin, C and C++ code ([#6](https://github.com/flame-engine/gamepads/issues/6)). ([6d3e9334](https://github.com/flame-engine/gamepads/commit/6d3e9334072d24525ed7ccf9f8c7fa481c8373fc))

#### `gamepads_windows` - `v0.1.1+1`

 - **REFACTOR**: Lint Kotlin, C and C++ code ([#6](https://github.com/flame-engine/gamepads/issues/6)). ([6d3e9334](https://github.com/flame-engine/gamepads/commit/6d3e9334072d24525ed7ccf9f8c7fa481c8373fc))


## 2023-04-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.1`](#gamepads---v011)
 - [`gamepads_platform_interface` - `v0.1.1`](#gamepads_platform_interface---v011)
 - [`gamepads_linux` - `v0.1.1`](#gamepads_linux---v011)
 - [`gamepads_windows` - `v0.1.1`](#gamepads_windows---v011)
 - [`gamepads_darwin` - `v0.1.1`](#gamepads_darwin---v011)

---

#### `gamepads` - `v0.1.1`

 - Bump "gamepads" to `0.1.1`.

#### `gamepads_platform_interface` - `v0.1.1`

 - Bump "gamepads_platform_interface" to `0.1.1`.

#### `gamepads_linux` - `v0.1.1`

 - Bump "gamepads_linux" to `0.1.1`.

#### `gamepads_windows` - `v0.1.1`

 - Bump "gamepads_windows" to `0.1.1`.

#### `gamepads_darwin` - `v0.1.1`

 - Bump "gamepads_darwin" to `0.1.1`.


## 2023-04-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`gamepads` - `v0.1.0`](#gamepads---v010)
 - [`gamepads_platform_interface` - `v0.1.0`](#gamepads_platform_interface---v010)
 - [`gamepads_linux` - `v0.1.0`](#gamepads_linux---v010)
 - [`gamepads_windows` - `v0.1.0`](#gamepads_windows---v010)
 - [`gamepads_darwin` - `v0.1.0`](#gamepads_darwin---v010)

---

#### `gamepads` - `v0.1.0`

 - Bump "gamepads" to `0.1.0`.

#### `gamepads_platform_interface` - `v0.1.0`

 - Bump "gamepads_platform_interface" to `0.1.0`.

#### `gamepads_linux` - `v0.1.0`

#### `gamepads_windows` - `v0.1.0`

 - Bump "gamepads_windows" to `0.1.0`.

#### `gamepads_darwin` - `v0.1.0`

 - Bump "gamepads_darwin" to `0.1.0`.

