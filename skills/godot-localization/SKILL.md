---
name: godot-localization
description: "Add or debug Godot translations: tr/atr lookups, plurals and contexts, catalogs, translation domains, locale switching, and RTL or pseudolocalization checks."
---

# Localization

Target Godot 4.7+.

## Translating strings

- `tr(message, context)` and `tr_n(message, plural_message, n, context)` are `Object` methods. `atr()` and `atr_n()` are the `Node` variants that additionally respect `auto_translate_mode`; prefer them in node scripts so a node marked disabled stays untranslated. In a static context use `TranslationServer.translate()` / `translate_plural()`.
- `n` selects the plural form but is not substituted: `tr_n("There is %d apple", "There are %d apples", n) % n`. Pluralization applies to non-negative integers only; handle negative and float counts with `tr()`.
- Translate whole sentences, then format. Prefer named placeholders through `String.format()` so translators can reorder them: `tr("{who} picked up the {what}").format({who = who_name, what = item_name})`.
- `context` disambiguates identical source strings (`tr("Close", "Actions")`) and is part of the lookup key, so a mismatched context silently returns the source string.

## Auto-translated nodes

- Controls (`Label`, `Button`, `Window`, …) translate their text properties automatically when the value matches a key. New nodes default to `AUTO_TRANSLATE_MODE_INHERIT`; the root defaults to `ALWAYS` (`ProjectSettings.internationalization/rendering/root_node_auto_translate`). Set `AUTO_TRANSLATE_MODE_DISABLED` on player names, chat, and other user data, or a value that happens to match a key gets replaced. Disabled subtrees are also skipped during POT generation.
- Strings set from script must be rebuilt on `Node.NOTIFICATION_TRANSLATION_CHANGED`, sent on locale change, on `auto_translate_mode` change, and on tree entry. It arrives alongside `NOTIFICATION_ENTER_TREE`, so `await ready` before touching children.
- Automatic Control translation does not cover entries carrying plural or context data; call `tr()` / `tr_n()` for those.

## Catalogs and domains

- CSV: first column is keys, header row is locale codes, `_`-prefixed columns are comments. Save UTF-8 without BOM. Godot 4.6+ adds `?plural` and `?context` columns (any position except the first).
- gettext: locale comes from the `Language:` header; entries marked `fuzzy` are not read by Godot until the comment is removed. `.mo` is worth it only for very large projects.
- Importing a CSV does not register it — add it under Project Settings > Localization > Translations. Generate the POT under Localization > Template Generation; the extractor only evaluates constant strings. `# NO_TRANSLATE` excludes a line, `# TRANSLATORS:` attaches a note (same line or the line above).
- Separate catalogs: `Object.set_translation_domain(name)` with `TranslationServer.get_or_add_domain(name)`; `Node.set_translation_domain_inherited()` restores parent inheritance. Names starting with `godot.` are reserved for the engine.

## Locale at runtime

- Default to `OS.get_locale_language()` (language only, no region) and let players override it. `TranslationServer.get_locale()` returns the project locale, not the system one. `set_locale()` standardizes input (`en-US` → `en_US`); unmatched locales fall back to `internationalization/locale/fallback`, or `en` when empty.
- Godot 4.6+: `find_translations(locale, exact)` replaces the deprecated `get_translation_object()`; `TranslationServer.format_number()` / `parse_number()` convert between Western Arabic digits and the locale's numeral system.

## Verifying

- Test with `--language fr`, the Locale > Test project setting (reset it before committing), or View > Preview Translation in the editor.
- Pseudolocalization expands and accents every localizable string; `pseudolocalization_override_enabled` replaces characters with `*` to expose non-localizable ones. Changing pseudolocalization properties on a `TranslationDomain` does not refresh the scene tree — propagate `MainLoop.NOTIFICATION_TRANSLATION_CHANGED` manually.
- RTL locales mirror anchors, text alignment, and container child order automatically; the coordinate system and non-`Control` nodes are not mirrored, so flip directional icons yourself. Use `structured_text_bidi_override` for paths, URIs, and other non-natural text.
- The default project font covers only a subset of Latin-1. Use `FontFile` fallbacks rather than resource remaps, which do not apply to fonts. Enable Locale > Include Text Server Data (~4 MB) for line breaking in languages written without spaces.
