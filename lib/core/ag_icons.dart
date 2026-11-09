import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Набор иконок AG Service в одном стиле: тонкая линия, скруглённые концы.
/// Каждая иконка — содержимое SVG 24x24. Рисуется виджетом [AgIcon].
class AgIcons {
  const AgIcons._();

  // Шапка
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>';
  static const bell =
      '<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z"/>'
      '<path d="M10 20a2 2 0 0 0 4 0"/>';

  // Нижнее меню
  static const home =
      '<path d="M4 11.5L12 4l8 7.5V19a1 1 0 0 1-1 1h-4v-5H9v5H5a1 1 0 0 1-1-1z"/>';
  static const chat =
      '<path d="M5 5h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1h-7l-5 4v-4H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/>';
  static const pin =
      '<path d="M12 21s-6.5-5.6-6.5-10.5a6.5 6.5 0 0 1 13 0C18.5 15.4 12 21 12 21z"/>'
      '<circle cx="12" cy="10.5" r="2.3"/>';
  static const history =
      '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l2.5 2"/>';
  static const settings =
      '<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/>'
      '<circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>';

  // Быстрый доступ
  static const wrench =
      '<path d="M15 4.5a4.5 4.5 0 0 0-4.3 5.9l-6.1 6.1a2 2 0 1 0 2.9 2.9l6.1-6.1A4.5 4.5 0 0 0 19.5 9l-2.7 2.7-2.5-0.6-0.6-2.5L16.4 6"/>';
  static const calendar =
      '<rect x="4" y="5.5" width="16" height="14.5" rx="2.5"/>'
      '<path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"/>'
      '<path d="M9.5 15l1.8 1.8 3.4-3.6"/>';
  static const tag =
      '<path d="M4 12.5V5a1 1 0 0 1 1-1h7.5l7.2 7.2a1 1 0 0 1 0 1.4l-7.1 7.1a1 1 0 0 1-1.4 0z"/>'
      '<circle cx="8.5" cy="8.5" r="1.4"/>';
  static const bulb =
      '<path d="M12 4a5.5 5.5 0 0 0-3.4 9.8c0.5 0.5 0.9 1.1 0.9 1.8V17h5v-1.4c0-0.7 0.4-1.3 0.9-1.8A5.5 5.5 0 0 0 12 4z"/>'
      '<path d="M10 20h4"/>';

  // Услуги
  static const oil =
      '<path d="M12 3.5s6 6.2 6 10.5a6 6 0 0 1-12 0c0-4.3 6-10.5 6-10.5z"/>'
      '<path d="M9.5 14.5A2.5 2.5 0 0 0 12 17"/>';
  static const steering =
      '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="2"/>'
      '<path d="M4.3 10.5L10 11.5M19.7 10.5L14 11.5M12 14v6"/>';
  static const tire =
      '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3.5"/>'
      '<path d="M12 4v4.5M12 15.5V20M4 12h4.5M15.5 12H20"/>';
  static const pulse = '<path d="M3 12h4l2.5-6 4 12 2.5-6h5"/>';
  static const brake =
      '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/>'
      '<path d="M12 6.4v0.2M12 17.4v0.2M6.4 12h0.2M17.4 12h0.2"/>';
  static const snow =
      '<path d="M12 3v18M4.2 7.5l15.6 9M19.8 7.5l-15.6 9"/>';

  // Разное
  static const wallet =
      '<path d="M4 8V7.5A2.5 2.5 0 0 1 6.5 5H17v3"/>'
      '<rect x="4" y="8" width="16" height="11" rx="2.5"/>'
      '<path d="M15.5 13.5h1"/>';
  static const percent =
      '<path d="M6 18L18 6"/>'
      '<circle cx="7.5" cy="7.5" r="2.2"/><circle cx="16.5" cy="16.5" r="2.2"/>';
  static const arrowRight = '<path d="M5 12h14M13 6l6 6-6 6"/>';
  static const arrowUpRight = '<path d="M7 17L17 7M9 7h8v8"/>';
  static const chevronRight = '<path d="M9 6l6 6-6 6"/>';
  static const user =
      '<circle cx="12" cy="8.5" r="3.5"/>'
      '<path d="M5 20a7 7 0 0 1 14 0"/>';
}

/// Рисует иконку из [AgIcons] нужного размера и цвета.
class AgIcon extends StatelessWidget {
  const AgIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.8,
  });

  final String icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFFFFFFFF);

    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="#000000" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">$icon</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
  }
}
