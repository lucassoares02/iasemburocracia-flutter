---
name: flutter-saas-ui
description: >
  Apply a consistent, high-end SaaS design system to Flutter widgets and pages.
  Use this skill whenever the user asks to redesign, refactor, or build a Flutter
  UI that should match the style of Stripe, Linear, or Notion — or when they say
  "use the same style", "follow the design pattern", "apply the SaaS design system",
  or "make it look modern/professional". Also use when creating new Flutter screens
  from scratch that should have a polished dashboard aesthetic. Produces complete,
  drop-in Dart files with all design tokens, components, and animations included.
---

# Flutter SaaS UI Design System

A precise, token-driven design system for Flutter that reproduces the aesthetic of
Stripe, Linear, and Notion: monochrome palette, 8px spacing grid, subtle shadows,
animated hover states, and strong typographic hierarchy.

---

## Core Principles

1. **Token-first** — Every value (color, spacing, radius, shadow) comes from `_DS`.
   Never hardcode `Colors.grey[600]` or `EdgeInsets.all(16)` directly.
2. **Monochrome by default** — Avoid colored icons or tinted backgrounds unless
   communicating semantic state (error = red, success = green). Use zinc/neutral grays.
3. **Animate everything interactive** — Buttons, inputs, list items, and dialogs all
   use `AnimatedContainer` + `MouseRegion` for hover states.
4. **Hierarchy through weight, not size** — Prefer `fontWeight` changes over large
   font-size jumps. Labels: `11px/w500/tertiary`. Values: `14px/w500/primary`. Titles: `20px/w700/-0.5tracking`.
5. **Whitespace is structure** — Section separation uses spacing, not dividers or
   colored headers.

---

## Design Token Class

Always include this `_DS` class verbatim at the top of every file:

```dart
class _DS {
  // Spacing — 8px grid
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;
  static const double s10 = 40.0;

  // Border radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;

  // Color palette (zinc-based, matches Radix UI zinc scale)
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color background  = Color(0xFFF7F7F8);
  static const Color border      = Color(0xFFE4E4E7);
  static const Color borderStrong= Color(0xFFD4D4D8);
  static const Color borderFocus = Color(0xFF18181B);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary  = Color(0xFFA1A1AA);
  static const Color accent      = Color(0xFF18181B);   // buttons, focus rings
  static const Color accentSubtle= Color(0xFFF4F4F5);   // hover backgrounds
  static const Color danger      = Color(0xFFEF4444);
  static const Color dangerSubtle= Color(0xFFFEF2F2);
  static const Color dangerBorder= Color(0xFFFECACA);
  static const Color success     = Color(0xFF22C55E);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4,  offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 1),
  ];
  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6,  offset: const Offset(0, 2)),
  ];
}
```

---

## Typography Scale

| Role          | Size | Weight | Color         | Letter-spacing |
| ------------- | ---- | ------ | ------------- | -------------- |
| Page title    | 20px | w700   | textPrimary   | -0.5           |
| Section title | 15px | w700   | textPrimary   | -0.3           |
| Dialog title  | 18px | w700   | textPrimary   | -0.4           |
| Body          | 14px | w500   | textPrimary   | —              |
| Subtitle      | 13px | normal | textSecondary | —              |
| Field label   | 11px | w600   | textTertiary  | +0.4           |
| Badge text    | 11px | w600   | semantic      | +0.1           |
| Time/mono     | 15px | w600   | textPrimary   | +0.5 + tabular |

---

## Component Patterns

### Page Header

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Page Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: _DS.textPrimary, letterSpacing: -0.5)),
          SizedBox(height: _DS.s1),
          Text('Supporting description.', style: TextStyle(fontSize: 13,
              color: _DS.textSecondary, height: 1.5)),
        ],
      ),
    ),
    SizedBox(width: _DS.s4),
    _SaasPrimaryButton(label: 'Action', icon: LucideIcons.plus, onPressed: () {}),
  ],
)
```

### Card Container

```dart
Container(
  decoration: BoxDecoration(
    color: _DS.surface,
    borderRadius: BorderRadius.circular(_DS.radiusLg),
    border: Border.all(color: _DS.border),
    boxShadow: _DS.shadowSm,
  ),
  clipBehavior: Clip.antiAlias,
  child: Column(
    children: [
      // rows separated by:
      Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F2)),
    ],
  ),
)
```

### Field Row (inside a card)

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Icon chip — always monochrome
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: _DS.accentSubtle,
            borderRadius: BorderRadius.circular(_DS.radiusMd)),
        child: Icon(iconData, size: 16, color: _DS.textSecondary),
      ),
      SizedBox(width: _DS.s4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: _DS.textTertiary, letterSpacing: 0.4)),
            SizedBox(height: _DS.s2),
            Text('Value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: _DS.textPrimary)),
          ],
        ),
      ),
    ],
  ),
)
```

### List Item (hoverable)

Use `MouseRegion` + `AnimatedContainer` pattern:

```dart
class _HoverListItem extends StatefulWidget { ... }
class _HoverListItemState extends State<_HoverListItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAFAFB) : _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          border: Border.all(color: _hovered ? _DS.borderStrong : _DS.border),
          boxShadow: _hovered ? _DS.shadowSm : [],
        ),
        // ... content
      ),
    );
  }
}
```

### Status Badge

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: isActive ? _DS.successSubtle : _DS.dangerSubtle,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: isActive ? _DS.successBorder : _DS.dangerBorder),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(
              color: isActive ? _DS.success : _DS.danger, shape: BoxShape.circle)),
      SizedBox(width: 6),
      Text(isActive ? 'Ativo' : 'Inativo',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: isActive ? Color(0xFF15803D) : Color(0xFFB91C1C))),
    ],
  ),
)
```

### Icon Action Button (edit/delete)

```dart
class _IconActionButton extends StatefulWidget {
  const _IconActionButton({required this.icon, required this.onPressed,
      required this.tooltip, this.isDanger = false});
  // ...
}
// Invisible bg at rest → colored on hover
// isDanger: hover bg = dangerSubtle, hover color = danger
// default: hover bg = accentSubtle, hover color = textPrimary
// Size: 32×32, radius: radiusSm, icon size: 14
```

---

## Button Variants

Four variants, all stateful with `MouseRegion` hover:

| Variant  | Resting bg  | Hover bg            | Text color      | Border   |
| -------- | ----------- | ------------------- | --------------- | -------- |
| Primary  | `accent`    | `Color(0xFF27272A)` | white           | none     |
| Outlined | `surface`   | `accentSubtle`      | `textPrimary`   | `border` |
| Ghost    | transparent | `accentSubtle`      | `textSecondary` | none     |
| Danger   | `danger`    | `Color(0xFFDC2626)` | white           | none     |

All buttons:

- Padding: `horizontal: s4, vertical: 10`
- Radius: `radiusMd`
- Font: `13px / w600 / letterSpacing: -0.1`
- Icon size: `14`, gap to label: `s2`
- `AnimatedContainer` duration: `140ms`

---

## Form Input (`_SaasInput`)

Stateful widget, tracks `FocusNode`:

- **Resting**: `1px border` in `_DS.border`, `shadowSm`
- **Focused**: `1.5px border` in `_DS.borderFocus`, `shadowMd`
- Border drawn by wrapping `AnimatedContainer`, **not** via `InputDecoration.border`
- Set all `InputDecoration` borders to `InputBorder.none`
- `counterText: ''` to suppress length indicator
- Content padding: `horizontal: s3, vertical: s3`
- Font: `14px / w500 / textPrimary`

---

## Dialog Pattern

Never use `AlertDialog`. Use:

```dart
Dialog(
  backgroundColor: Colors.transparent,
  elevation: 0,
  child: Container(
    width: 480,   // or 400 for confirmations
    decoration: BoxDecoration(
      color: _DS.surface,
      borderRadius: BorderRadius.circular(_DS.radiusLg + 2),
      border: Border.all(color: _DS.border),
      boxShadow: _DS.shadowMd,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(_DS.s8),
      child: Column( ... ),
    ),
  ),
)
```

Dialog structure:

1. **Header row**: title + subtitle on left, `_DialogCloseButton` on right
2. `_DialogDivider` (1px, `Color(0xFFF1F1F2)`)
3. **Body**: form fields with `_DialogFieldLabel` above each
4. `_DialogDivider`
5. **Footer row**: Ghost cancel on left, Primary/Danger save on right

Use `AnimatedSize` for conditional sections (e.g., hiding time pickers when "closed" toggle is on).

---

## Empty & Error States

Both use the same centered column pattern:

```
56×56 Container (radiusLg, border, semantic bg)
  └─ Icon (24px, semantic color)
SizedBox(s4)
Text title (15px / w600 / textPrimary / -0.2tracking)
SizedBox(s2)
Text body (13px / textSecondary / height 1.5)
SizedBox(s6)
_SaasOutlinedButton or _SaasGhostButton
```

- Error icon chip: `dangerSubtle` bg, `dangerBorder` border, `LucideIcons.alertTriangle`
- Empty icon chip: `accentSubtle` bg, `border` border, context-relevant Lucide icon

---

## Loading Skeleton

Mirror the exact structure of the real content using `_SkeletonBox`:

```dart
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 4});
  // Color: Color(0xFFF1F1F2)
}
```

For list skeletons: render 4–5 item-shaped containers with the same padding/radius as real items.
For form skeletons: render the header row, then card-shaped containers for each field.

---

## Page Entry Animation

Wrap the root content in a `FadeTransition` driven by a `CurvedAnimation`:

```dart
_animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
_fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
_animController.forward(); // in initState
// in build:
FadeTransition(opacity: _fadeAnim, child: ...)
```

---

## Sorting / Type Safety Note

When sorting lists from `SuccessState.data`, always create a typed copy first:

```dart
// ✅ Correct
final List<MyModel> items = List<MyModel>.from(state.data);
items.sort((MyModel a, MyModel b) => (a.order ?? 0).compareTo(b.order ?? 0));

// ❌ Wrong — causes TypeError in release mode
final items = state.data..sort((a, b) => a.order!.compareTo(b.order!));
```

---

## Lucide Icons Mapping

Replace all Material `Icons.*` with `LucideIcons.*`:

| Old                    | New                         |
| ---------------------- | --------------------------- |
| `Icons.edit_outlined`  | `LucideIcons.pencil`        |
| `Icons.delete_outline` | `LucideIcons.trash2`        |
| `Icons.add`            | `LucideIcons.plus`          |
| `Icons.close`          | `LucideIcons.x`             |
| `Icons.check`          | `LucideIcons.check`         |
| `Icons.refresh`        | `LucideIcons.refreshCw`     |
| `Icons.error_outline`  | `LucideIcons.alertTriangle` |
| `Icons.access_time`    | `LucideIcons.clock`         |
| `Icons.calendar_today` | `LucideIcons.calendar`      |
| `Icons.login`          | `LucideIcons.sunrise`       |
| `Icons.logout`         | `LucideIcons.sunset`        |
| `Icons.map_pin`        | `LucideIcons.mapPin`        |
| `Icons.numbers`        | `LucideIcons.hash`          |
| `Icons.flag`           | `LucideIcons.flag`          |
| `Icons.building`       | `LucideIcons.building2`     |
| `Icons.warning`        | `LucideIcons.alertTriangle` |

---

## Checklist Before Delivering

- [ ] `_DS` token class present and all values sourced from it
- [ ] No `Colors.grey[x]`, no raw hex outside `_DS`
- [ ] All buttons are stateful with `MouseRegion` hover
- [ ] Inputs use `_SaasInput` pattern (focus-ring via wrapping container)
- [ ] Dialogs use custom `Container`, not `AlertDialog`/`SimpleDialog`
- [ ] Page has `FadeTransition` entry animation
- [ ] List sorts use `List<T>.from()` with explicit type parameters
- [ ] All `Icons.*` replaced with `LucideIcons.*`
- [ ] Empty state and error state use icon-chip pattern
- [ ] Loading skeleton mirrors real content structure
