# Локализация

## Обзор

- Исходная локаль: `en`
- Исходный ARB-файл: `lib/l10n/app_en.arb`
- Файлы перевода: `lib/l10n/app_<locale>.arb`
- Сгенерированные локализации Flutter: `lib/l10n/generated/`

Английский является каноничной исходной локалью для Flutter `gen_l10n` и для внешних платформ перевода.

## Локальный воркфлоу

1. Добавьте или обновите строки в `lib/l10n/app_en.arb`.
2. Обновите существующие переводы, например `lib/l10n/app_ru.arb`.
3. Выполните:

```powershell
flutter gen-l10n
```

4. Закоммите обновленные ARB-файлы вместе с `lib/l10n/generated/`.

## Настройка Hosted Weblate

Эти настройки соответствуют структуре данного репозитория и готовы для использования в Hosted Weblate (`hosted.weblate.org`).

### Доступ к репозитоию

Hosted Weblate использует специального GitHub-аккаунта для пушей с именем `weblate`. Добавьте этого пользователя в качестве коллаборатора с правом записи в репозиторий, если хотите, чтобы Weblate открывал пулл-реквесты из upstream-ветки.

Рекомендуемые настройки репозитория:

- Source code repository: `git@github.com:mxnix/kick.git`
- Repository push URL: `git@github.com:mxnix/kick.git`
- Version control system: `GitHub pull requests`
- Push branch: `l10n/weblate-translations`
- Repository branch: `main`

Если оставить поле `Push branch` пустым, Weblate будет пушить из форка, а не из upstream-ветки.

### Настройки компонента

Создайте один компонент для строк Flutter-приложения со следующими значениями:

- File mask: `lib/l10n/app_*.arb`
- Monolingual base language file: `lib/l10n/app_en.arb`
- Template for new translations: *оставь пустым*
- File format: `ARB file`

Предлагаемая настройка языков:

- Source language: English
- Initial target language: Russian, ...

### Автоматизация GitHub в этом репозитории

В этом репозитории находится файл `.github/workflows/sync-generated-localizations.yml`.

Когда Weblate обновляет любой файл `lib/l10n/*.arb` в ветке, этот воркфлоу запускает `flutter gen-l10n` и коммитит обновленные сгенерированные файлы обратно в ту же ветку. Это позволяет мержить пулл-реквесты от Weblate без конфликтов, даже несмотря на то, что исходники локализации Flutter закоммичены в репозиторий.

`CI` также проверяет, что сгенерированные файлы локализации находятся в актуальном состоянии.