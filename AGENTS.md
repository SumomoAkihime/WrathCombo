## Project Notes

- The project already has a `.resx`-based localization system, but Simplified Chinese coverage is incomplete.
- Several `zh-Hans` resource files exist only as empty placeholders, so the UI silently falls back to English.
- A noticeable amount of user-facing text is still hard-coded directly inside `*.cs` config UI files instead of being routed through localization resources.
- This repository depends on git submodules (`ECommons`, `PunishLib`, `WrathCombo.API`). If those folders are present but empty/uninitialized, the solution will look structurally complete but will not build.
- The current project file targets `net10.0-windows`. Building requires a .NET SDK that supports .NET 10; using only .NET 8 will fail immediately with `NETSDK1045`.
- When adding or changing UI text, prefer updating/adding `.resx` entries first and only hard-code strings as a last resort.
- Before claiming the app is fully localized, check both:
  - existing `zh-Hans` resource coverage
  - hard-coded `Draw*("...")` strings inside config/UI code
- This repository is already connected to `SumomoAkihime/WrathCombo`. Keep that remote unless there is an explicit migration, because the sibling project in this workspace uses a different GitHub namespace and it is easy to mix them up.
