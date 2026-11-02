# Changelog

All notable changes to `cook_mate_core` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-02

### Added
- **Core Recipe Model**: Immutable `Recipe` entity with serialization (`toJson`/`fromJson`), validation, and copy utilities.
- **Intelligent Recipe Scaler**: Sub-linear prep time scaling, thermal mass cook time scaling, fractional arithmetic (e.g., `1/2`, `2 1/4`), attached unit scaling (`250g`, `400ml`), and smart noun pluralization.
- **Culinary Unit Converter**: Complete bidirectional conversions between Metric and US Imperial units for mass (`g`, `kg`, `oz`, `lb`), volume (`ml`, `l`, `tsp`, `tbsp`, `fl oz`, `cup`), and temperature (`°C`, `°F`).
- **Accent & Diacritic-Agnostic Search Engine**: Multi-token ranking engine matching prefixes, titles, ingredients, and categories with diacritic normalization (e.g., `crème brûlée` matched by `creme brulee`).
- **Chef AI Recipe Autofill Engine**: Culinary inference dictionary auto-generating ingredient lists, instructions, and preparation metadata from dish titles.
- **Recipe Parser**: Text and JSON recipe ingestion and sanitization.
