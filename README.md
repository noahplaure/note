# Notepad 📝

[![Build Notepad IPA & Run Tests](https://github.com/notepad/notepad/actions/workflows/build.yml/badge.svg)](.github/workflows/build.yml)
[![iOS 26.0+](https://img.shields.io/badge/iOS-26.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![LiveContainer Ready](https://img.shields.io/badge/LiveContainer-Compatible-green.svg)](https://github.com/khanld/livecontainer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Notepad** — профессиональный аналог Apple Notes с бескомпромиссным тёмным OLED-дизайном, архитектурой MVVM, поддержкой iPad и ультра-быстрым WYSIWYG-редактором Markdown (.md).

Приложение спроектировано под **iOS 26** и **Swift 6.2** со strict concurrency, компилируется без предупреждений и оптимизировано для запуска через **LiveContainer**, **AltStore**, **Sideloadly** и **TrollStore** без джейлбрейка.

---

## 📸 Скриншоты

```
+---------------------------+  +------------------------------------------------+
| Folders            [+] [*]|  | # Project Architecture                         |
|---------------------------|  |                                                |
| [v] All Notes          42 |  | This note describes the MVVM data layer.      |
| [*] Pinned              5 |  |                                                |
| [c] Recent              8 |  | ```swift                                       |
|                           |  | actor DocumentStorageService {                 |
| FOLDERS                   |  |     func saveNote(_ note: Note) throws         |
| [>] Work               24 |  | }                                              |
| [>] Personal           12 |  | ```                                            |
| [>] Code Snippets       6 |  |                                                |
|                           |  | | Component | Status      |                    |
|                           |  | | :-------- | :---------: |                    |
|                           |  | | FTS5 DB   | Operational |                    |
|                           |  |                                                |
|                           |  | [Aa] [x] [Table] [Img] [Code] [B] [I] [U] [M]  |
+---------------------------+  +------------------------------------------------+
     Sidebar & Notes List                  Live WYSIWYG Editor
```

---

## ⚡️ Возможности

### 📝 Редактор Markdown нового поколения
- **WYSIWYG & Исходник**: мгновенное переключение между богатым визуальным представлением и чистым исходным кодом Markdown.
- **TextKit 2**: аппаратное ускорение рендеринга текста через `NSTextLayoutManager` и `NSTextContentStorage` без задержек на документах в 10 000+ строк.
- **Форматирование**: Заголовки (H1–H6), жирный, курсив, подчёркивание, зачёркивание, встроенный код, цитаты, разделители.
- **Списки и чекбоксы**: маркированные, нумерованные и интерактивные списки задач (`- [ ]`, `- [x]`) с анимацией переключения.
- **Подсветка синтаксиса кода**: встроенный высокопроизводительный лексер с поддержкой Swift, Python, JavaScript, TypeScript, C, C++, Java, Kotlin, Go, Rust, HTML, CSS, SQL, Bash, YAML, JSON, XML, Markdown. Темы VS Code Dark+, Xcode Dark, Monokai. Копирование кода в один тап.
- **Таблицы GFM**: визуальный редактор таблиц, выравнивание столбцов (по левому/правому краю, по центру), добавление и удаление строк и столбцов.
- **Изображения**: вставка из Фотогалереи (PhotosPicker), Камеры, Файлов и буфера обмена. Автоматический downscale и компрессия в `Documents/Notepad/assets/<uuid>.jpg`.
- **Поиск и замена**: локальный поиск по текущей заметке с подсветкой и заменой совпадений.
- **Клавиатурная панель "Aa"**: всплывающее меню форматирования, быстрые кнопки над клавиатурой, поддержка хоткеев iPad (Cmd+B, Cmd+I, Cmd+U, Cmd+K, Cmd+F, Cmd+S, Cmd+N).

### 📁 Файловая система и совместимость
- Хранение заметок **строго в виде .md файлов** в папке `Documents/Notepad/`.
- Доступ через приложение «Файлы» (`UIFileSharingEnabled = YES`, `LSSupportsOpeningDocumentsInPlace = YES`).
- Метаданные (id, pinned, дата создания, дата изменения, теги, папка) хранятся в **YAML front matter** внутри каждого файла, сохраняя 100% переносимость заметок на macOS, Linux и Windows.
- Автосохранение с debounce (600 мс) и атомарной записью (`.atomic`) для защиты от потери данных.
- Отслеживание внешних изменений файлов (`NSFilePresenter` + `DispatchSourceFileSystemObject`).

### 🔍 Поиск и индексация
- **SQLite FTS5**: встроенный полнотекстовый индекс всех заметок с поддержкой префиксного поиска и извлечения контекстных сниппетов совпадений.
- Фоновая инкрементальная индексация без блокировки интерфейса.
- Интеграция с **CoreSpotlight** (`CSSearchableIndex`) для глобального поиска по iOS.
- Фильтры: по дате изменения, наличию картинок, блоков кода, таблиц и закреплению.

### 🎨 Дизайн и эргономика
- Принудительная тёмная тема (`UIUserInterfaceStyle = Dark`), чистый OLED-чёрный фон `#000000`, тёмные панели `#1C1C1E`.
- Фирменный золотистый акцент Apple Notes `#FFD60A`.
- Элементы Liquid Glass и тонкие полупрозрачные границы.
- Настоящие 1024x1024 иконки (Universal, Dark, Tinted).
- Тактильный отклик (Haptic Feedback) на ключевых действиях.

---

## 🛠 Технические решения и архитектура

### Почему собственный движок подсветки синтаксиса вместо Highlightr / Tree-sitter?
1. **Совместимость с Swift 6 strict concurrency**: Highlightr опирается на устаревший JavaScriptCore-мост highlight.js, что влечёт предупреждения о data races в Swift 6. Tree-sitter требует сборки тяжеловесных C/C++ парсеров под каждую грамматику.
2. **Работа в LiveContainer и нативных песочницах**: JavaScriptCore JIT-компиляция заблокирована или ограничена во многих средах без подписи/дебага. Наш модульный Swift-лексер (`SyntaxHighlighter`) работает мгновенно в линейное время O(N), полностью потокобезопасен (`Sendable`) и имеет нулевые внешние зависимости.
3. **Надёжность сборки SPM**: Никаких сбоев скачивания сторонних репозиториев в headless-раннерах GitHub Actions.

### Архитектура проекта
```
Notepad/
├── Sources/
│   ├── App/
│   │   └── NotepadApp.swift              # Точка входа SwiftUI, команды меню
│   ├── Models/
│   │   ├── Note.swift                    # Модель заметки с вычисляемыми свойствами
│   │   ├── Folder.swift                  # Системные и пользовательские папки
│   │   ├── NoteMetadata.swift            # Структура YAML front matter
│   │   ├── EditorMode.swift              # Режимы WYSIWYG / Source
│   │   └── SearchFilter.swift            # Фильтры поиска и сортировки
│   ├── Services/
│   │   ├── Storage/
│   │   │   ├── DocumentStorageService.swift  # Actor для работы с файлами .md и assets
│   │   │   └── FilePresenterCoordinator.swift # Слежение за внешними изменениями
│   │   ├── Markdown/
│   │   │   ├── MarkdownNode.swift        # AST узлы (BlockNode, InlineNode, TableModel)
│   │   │   ├── MarkdownParser.swift      # CommonMark + GFM + HTML парсер
│   │   │   ├── MarkdownSerializer.swift  # Lossless сериализатор в .md
│   │   │   ├── FrontMatterParser.swift   # Парсер и сериализатор YAML front matter
│   │   │   └── MarkdownHTMLHelper.swift  # Теги выравнивания, маркера, цвета, подчёркивания
│   │   ├── SyntaxHighlight/
│   │   │   ├── SyntaxLanguage.swift      # 18+ языков программирования и автоопределение
│   │   │   ├── SyntaxTheme.swift         # Темы (VS Code Dark+, Xcode Dark, Monokai)
│   │   │   └── SyntaxHighlighter.swift   # Токенизатор и построитель AttributedString
│   │   ├── Search/
│   │   │   ├── SearchIndexService.swift  # SQLite FTS5 полнотекстовый индекс
│   │   │   └── SpotlightIndexService.swift # Индексация для CoreSpotlight
│   │   └── Export/
│   │       └── ExportService.swift       # Экспорт в .md, PDF и Plain Text
│   ├── ViewModels/
│   │   ├── NoteListViewModel.swift       # Управление списком заметок, папками и поиском
│   │   ├── NoteEditorViewModel.swift     # Логика редактора, форматирование, автосохранение
│   │   └── SettingsViewModel.swift       # Настройки шрифтов, тем и базы данных
│   ├── Views/
│   │   ├── Main/
│   │   │   ├── MainSplitView.swift       # NavigationSplitView для iPad и iPhone
│   │   │   ├── NoteListView.swift        # Список заметок с секциями и поиском
│   │   │   ├── NoteRowView.swift         # Карточка заметки в стиле Apple Notes
│   │   │   └── FolderListView.swift      # Сайдбар папок
│   │   ├── Editor/
│   │   │   ├── NoteEditorView.swift      # Экран редактора заметки
│   │   │   ├── TextKitEditorView.swift   # TextKit 2 UIKit UIViewRepresentable
│   │   │   ├── MarkdownSourceEditorView.swift # Исходный код с номерами строк
│   │   │   ├── EditorToolbarView.swift   # Панель "Aa" и быстрые действия
│   │   │   ├── ColorPickerPaletteView.swift # Палитра 12 цветов + ColorPicker
│   │   │   ├── TableEditorSheet.swift    # Визуальный редактор таблиц
│   │   │   ├── CodeBlockView.swift       # Блок кода с подсветкой и копированием
│   │   │   ├── ImageAttachmentSheet.swift # Вставка фото/камеры/файлов
│   │   │   └── FindAndReplaceBar.swift   # Поиск и замена по заметке
│   │   ├── Settings/
│   │   │   └── SettingsView.swift        # Экран настроек и переиндексации
│   │   └── Common/
│   │       ├── LiquidGlassCard.swift     # Модификатор Liquid Glass / Dark Card
│   │       ├── SearchBarView.swift       # Кастомный поисковый бар
│   │       └── HapticManager.swift       # Haptic-отклик
│   └── Utils/
│       ├── Debouncer.swift               # Таймер автосохранения
│       ├── ColorExtensions.swift         # Преобразование HEX <-> Color/UIColor
│       └── ViewExtensions.swift
├── Resources/
│   ├── Info.plist                        # File sharing, Permissions, Dark mode
│   └── Assets.xcassets/                  # AppIcon (1024x1024), Цвета, Темы
├── NotepadTests/
│   ├── MarkdownParserTests.swift         # Swift Testing тесты парсера и сериализатора
│   ├── FrontMatterTests.swift            # Тесты YAML front matter round-trip
│   ├── SearchIndexTests.swift            # Тесты SQLite FTS5 полнотекстового поиска
│   └── DocumentStorageTests.swift        # Тесты файловой системы и ассетов
├── project.yml                           # Спецификация генерации проекта XcodeGen
└── .github/workflows/build.yml           # CI/CD сборки неподписанного IPA и тестов
```

---

## 🚀 Сборка проекта

### 1. Локальная сборка через XcodeGen (на Mac)
```bash
# Установка XcodeGen (если не установлен)
brew install xcodegen

# Генерация Notepad.xcodeproj
xcodegen generate

# Открытие проекта в Xcode
open Notepad.xcodeproj
```

### 2. Сборка Unsigned IPA для LiveContainer / AltStore через терминал
```bash
# Генерация проекта
xcodegen generate

# Сборка архива
xcodebuild archive \
  -project Notepad.xcodeproj \
  -scheme Notepad \
  -configuration Release \
  -sdk iphoneos \
  -archivePath build/Notepad.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

# Упаковка IPA
mkdir -p Payload
cp -R build/Notepad.xcarchive/Products/Applications/Notepad.app Payload/
zip -r Notepad.ipa Payload
```

### 3. Автоматическая сборка в GitHub Actions
Репозиторий настроен на автоматическую сборку через `.github/workflows/build.yml`:
1. Запустите workflow вручную через вкладку **Actions -> Run workflow** (или сделайте push/tag).
2. Запустится шаг прогона Unit-тестов на iOS Simulator.
3. Произойдёт сборка release-версии и упаковка в `Notepad.ipa`.
4. Готовый артефакт `Notepad-unsigned-ipa` можно скачать прямо со страницы сборки Actions!

---

## 📲 Установка IPA в LiveContainer

1. Скачайте `Notepad.ipa` из артефактов сборки GitHub Actions.
2. Откройте приложение **LiveContainer** на вашем iPhone или iPad.
3. Нажмите кнопку **+** в правом верхнем углу и выберите файл `Notepad.ipa`.
4. Notepad установится в изолированную среду LiveContainer и сразу готов к работе с файлами в приложении «Файлы».

---

## 📄 Лицензия

MIT License © 2026 Notepad Contributors.
