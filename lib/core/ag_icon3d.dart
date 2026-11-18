// AG_UI2 — объёмные (3D) иконки AG Service в SVG: градиент, блик, мягкая тень.
// Используются на главном экране: быстрый доступ, услуги, гараж.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'ag_icons.dart';

class AgIcon3D extends StatelessWidget {
  const AgIcon3D(this.kind, {super.key, this.size = 44});

  final String kind;
  final double size;

  static const String _defs = '''
<defs>
<linearGradient id="o" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB46B"/><stop offset=".55" stop-color="#FF6A00"/><stop offset="1" stop-color="#D94A00"/></linearGradient>
<linearGradient id="w" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DFE3EA"/></linearGradient>
<linearGradient id="m" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".5" stop-color="#C9CED6"/><stop offset="1" stop-color="#8B939F"/></linearGradient>
<linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8DB6FF"/><stop offset=".55" stop-color="#2F6BFF"/><stop offset="1" stop-color="#1A47C9"/></linearGradient>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE88A"/><stop offset=".5" stop-color="#FFBE0B"/><stop offset="1" stop-color="#E08600"/></linearGradient>
<linearGradient id="p" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDB8FF"/><stop offset=".55" stop-color="#8B5CF6"/><stop offset="1" stop-color="#6136D1"/></linearGradient>
<linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A6F5C8"/><stop offset=".55" stop-color="#2BCF77"/><stop offset="1" stop-color="#119152"/></linearGradient>
<linearGradient id="c" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B5F1FF"/><stop offset=".55" stop-color="#22B8E8"/><stop offset="1" stop-color="#0E7FB0"/></linearGradient>
<linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB0B0"/><stop offset=".55" stop-color="#F0453A"/><stop offset="1" stop-color="#B9221A"/></linearGradient>
<linearGradient id="d" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B616D"/><stop offset="1" stop-color="#14161B"/></linearGradient>
<linearGradient id="gl" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8F6FF"/><stop offset="1" stop-color="#7CC4FF"/></linearGradient>
<linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".75"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>
<radialGradient id="sh" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#000000" stop-opacity=".28"/><stop offset="1" stop-color="#000000" stop-opacity="0"/></radialGradient>
<linearGradient id="o2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFA24D"/><stop offset="1" stop-color="#E85400"/></linearGradient>
<linearGradient id="bl" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7FB0FF"/><stop offset="1" stop-color="#2557E8"/></linearGradient>
<linearGradient id="gr2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5BE39A"/><stop offset="1" stop-color="#0E9A55"/></linearGradient>
</defs>''';

  static const Map<String, String> _body = {
    'calendar': '<ellipse cx="30" cy="59.5" rx="22" ry="3.4" fill="url(#sh)"/><rect x="6" y="11" width="44" height="44" rx="12" fill="url(#w)"/><path d="M6 23a12 12 0 0 1 12-12h20a12 12 0 0 1 12 12v3H6z" fill="url(#o2)"/><path d="M11 15.5h34" stroke="#fff" stroke-opacity=".5" stroke-width="2" stroke-linecap="round"/><rect x="15" y="5" width="6" height="12" rx="3" fill="url(#m)"/><rect x="35" y="5" width="6" height="12" rx="3" fill="url(#m)"/><g fill="#E3E7EE"><rect x="12" y="31" width="7" height="6" rx="2"/><rect x="24.5" y="31" width="7" height="6" rx="2"/><rect x="37" y="31" width="7" height="6" rx="2"/><rect x="12" y="42" width="7" height="6" rx="2"/></g><rect x="24.5" y="42" width="7" height="6" rx="2" fill="url(#o)"/><circle cx="47" cy="45" r="12" fill="url(#bl)"/><circle cx="47" cy="45" r="8.5" fill="#fff" fill-opacity=".18"/><path d="M47 39.5V45l3.6 2.4" stroke="#fff" stroke-width="2.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/><ellipse cx="43" cy="38" rx="5" ry="2.4" fill="url(#s)"/>', // AG_ICON4
    'repair': '<ellipse cx="32" cy="59.5" rx="20" ry="3.2" fill="url(#sh)"/><circle cx="32" cy="31" r="25" fill="url(#w)"/><circle cx="32" cy="31" r="21" fill="none" stroke="#EEF0F4" stroke-width="5"/><path d="M32 10a21 21 0 1 1-19.6 28.5" fill="none" stroke="url(#o2)" stroke-width="5" stroke-linecap="round"/><g transform="translate(17 19)"><path d="M1 15c0-2 1.2-3.2 3.2-3.7l3.4-4.8C8.4 5.4 9.6 4.8 11 4.8h8c1.4 0 2.6.6 3.4 1.7l3.4 4.8c2 .5 3.2 1.7 3.2 3.7v3a1.6 1.6 0 0 1-1.6 1.6H2.6A1.6 1.6 0 0 1 1 17.6z" fill="url(#d)"/><path d="M9.6 7.4c.4-.6 1-.9 1.8-.9h2.4v5H6.8zM16 6.5h2.4c.8 0 1.4.3 1.8.9l2.8 4.1H16z" fill="url(#gl)"/><circle cx="7.5" cy="19.5" r="3" fill="#2A2E36"/><circle cx="22.5" cy="19.5" r="3" fill="#2A2E36"/><circle cx="7.5" cy="19.5" r="1.3" fill="url(#m)"/><circle cx="22.5" cy="19.5" r="1.3" fill="url(#m)"/></g><circle cx="49" cy="47" r="10" fill="url(#o)"/><path d="M52.5 42.6a3.6 3.6 0 0 0-4.6 4.6l-4.2 4.2a1.3 1.3 0 0 0 1.8 1.8l4.2-4.2a3.6 3.6 0 0 0 4.6-4.6l-2 2-1.8-.5-.5-1.8z" fill="#fff"/>', // AG_ICON4
    'tag': '<ellipse cx="32" cy="59.5" rx="22" ry="3.2" fill="url(#sh)"/><path d="M5 27V12a6 6 0 0 1 6-6h15a6 6 0 0 1 4.2 1.8l21 21a6 6 0 0 1 0 8.4L36.4 52a6 6 0 0 1-8.4 0L6.8 31.2A6 6 0 0 1 5 27z" fill="url(#gr2)"/><path d="M10 10.5h16" stroke="#fff" stroke-opacity=".55" stroke-width="2.2" stroke-linecap="round"/><circle cx="15.5" cy="16.5" r="4.6" fill="url(#w)"/><circle cx="15.5" cy="16.5" r="1.8" fill="#0E9A55"/><path d="M26 22.5h6.5a4.3 4.3 0 0 1 0 8.6H26zM26 22.5v15M23.5 34.5h8" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/><circle cx="48" cy="46" r="11" fill="url(#g)"/><circle cx="48" cy="46" r="8" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="1.6"/><path d="M45.5 41.5h3.6a2.4 2.4 0 0 1 0 4.8h-3.6zM45.5 41.5v8.5M44 48.5h5" stroke="#B86A00" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>', // AG_ICON4
    'bulb': '<ellipse cx="30" cy="59.5" rx="20" ry="3.2" fill="url(#sh)"/><path d="M8 10h40a6 6 0 0 1 6 6v22a6 6 0 0 1-6 6H26l-10 9v-9H8a6 6 0 0 1-6-6V16a6 6 0 0 1 6-6z" fill="url(#bl)"/><path d="M8 14.5h22" stroke="#fff" stroke-opacity=".5" stroke-width="2.2" stroke-linecap="round"/><path d="M28 16.5a9 9 0 0 0-5.3 16.3c1 .8 1.6 1.7 1.6 2.9v.8h7.4v-.8c0-1.2.6-2.1 1.6-2.9A9 9 0 0 0 28 16.5z" fill="url(#g)"/><ellipse cx="25" cy="21.5" rx="3" ry="2" fill="url(#s)"/><rect x="24.6" y="37" width="6.8" height="2.6" rx="1.3" fill="#fff"/><path d="M42 18l1.3 3.2 3.2 1.3-3.2 1.3L42 27l-1.3-3.2-3.2-1.3 3.2-1.3zM49 29l.8 1.9 1.9.8-1.9.8-.8 1.9-.8-1.9-1.9-.8 1.9-.8z" fill="#FFE27A"/><circle cx="52" cy="50" r="7.5" fill="url(#o)"/><path d="M48.8 50.2l2.2 2.2 4.2-4.4" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>', // AG_ICON4
    'oil': '<ellipse cx="32" cy="59" rx="17" ry="3.2" fill="url(#sh)"/><path d="M32 5s17 17.5 17 30a17 17 0 0 1-34 0C15 22.5 32 5 32 5z" fill="url(#o)"/><path d="M24 37a8 8 0 0 0 8 8" stroke="#fff" stroke-opacity=".75" stroke-width="3" stroke-linecap="round" fill="none"/><ellipse cx="27" cy="22" rx="4" ry="6" fill="url(#s)"/>',
    'steering': '<ellipse cx="32" cy="59" rx="20" ry="3.4" fill="url(#sh)"/><circle cx="32" cy="31" r="24" fill="url(#b)"/><circle cx="32" cy="31" r="17" fill="#0E2E86" fill-opacity=".35"/><path d="M15 27l12 2.5M49 27l-12 2.5M32 37v11" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="31" r="6" fill="url(#w)"/><path d="M15 17a22 22 0 0 1 12-8" stroke="#fff" stroke-opacity=".6" stroke-width="2.4" stroke-linecap="round" fill="none"/>',
    'tire': '<ellipse cx="32" cy="59" rx="20" ry="3.4" fill="url(#sh)"/><circle cx="32" cy="31" r="25" fill="url(#d)"/><circle cx="32" cy="31" r="14" fill="url(#m)"/><circle cx="32" cy="31" r="4.5" fill="url(#d)"/><g fill="#7D8590"><circle cx="32" cy="21.5" r="2"/><circle cx="41" cy="28" r="2"/><circle cx="37.5" cy="39" r="2"/><circle cx="26.5" cy="39" r="2"/><circle cx="23" cy="28" r="2"/></g><path d="M13 22a21 21 0 0 1 9-10" stroke="#fff" stroke-opacity=".35" stroke-width="2.4" stroke-linecap="round" fill="none"/>',
    'pulse': '<ellipse cx="32" cy="59" rx="20" ry="3.4" fill="url(#sh)"/><rect x="7" y="10" width="50" height="42" rx="12" fill="url(#p)"/><path d="M12 31h10l4-10 7 20 4-10h15" stroke="#fff" stroke-width="3.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M13 15h38" stroke="#fff" stroke-opacity=".45" stroke-width="2" stroke-linecap="round"/>',
    'brake': '<ellipse cx="32" cy="59" rx="20" ry="3.4" fill="url(#sh)"/><circle cx="32" cy="31" r="24" fill="url(#m)"/><circle cx="32" cy="31" r="8" fill="url(#d)"/><g fill="#9AA2AD"><circle cx="32" cy="15" r="2"/><circle cx="48" cy="31" r="2"/><circle cx="32" cy="47" r="2"/><circle cx="16" cy="31" r="2"/></g><path d="M44 10a24 24 0 0 1 10 14L46 27a16 16 0 0 0-6-9z" fill="url(#r)"/>',
    'snow': '<ellipse cx="32" cy="59" rx="18" ry="3.2" fill="url(#sh)"/><circle cx="32" cy="31" r="24" fill="url(#c)"/><g stroke="#fff" stroke-width="3.4" stroke-linecap="round"><path d="M32 15v32M18 23l28 16M46 23L18 39"/><path d="M28 17l4 4 4-4M28 45l4-4 4 4"/></g><ellipse cx="25" cy="16" rx="8" ry="4" fill="url(#s)"/>',
    'car': '<ellipse cx="32" cy="57" rx="26" ry="4" fill="url(#sh)"/><path d="M6 40.5c0-4 2.4-6.3 6.4-7.3l6.8-9.6c1.6-2.2 3.9-3.4 6.6-3.4h13.6c2.7 0 5 1.2 6.6 3.4l6.8 9.6c4 1 6.4 3.3 6.4 7.3v5.2a3.3 3.3 0 0 1-3.3 3.3H9.3A3.3 3.3 0 0 1 6 45.7z" fill="url(#o)"/><path d="M22.7 24.9c.9-1.3 2-1.9 3.6-1.9h4.7v10.4H16.1z" fill="url(#gl)"/><path d="M34 23h4.7c1.6 0 2.7.6 3.6 1.9l6.6 8.5H34z" fill="url(#gl)"/><path d="M11 35.5h42" stroke="#fff" stroke-opacity=".45" stroke-width="2" stroke-linecap="round"/><circle cx="19" cy="48" r="7.5" fill="url(#d)"/><circle cx="19" cy="48" r="3.4" fill="url(#m)"/><circle cx="45" cy="48" r="7.5" fill="url(#d)"/><circle cx="45" cy="48" r="3.4" fill="url(#m)"/>',
    'taxi': '<ellipse cx="32" cy="57" rx="26" ry="4" fill="url(#sh)"/><path d="M26 12.5h12a2 2 0 0 1 2 2v5.5H24v-5.5a2 2 0 0 1 2-2z" fill="url(#d)"/><rect x="27" y="14.5" width="10" height="3" rx="1" fill="#FFD84D"/><path d="M6 40.5c0-4 2.4-6.3 6.4-7.3l6.8-9.6c1.6-2.2 3.9-3.4 6.6-3.4h13.6c2.7 0 5 1.2 6.6 3.4l6.8 9.6c4 1 6.4 3.3 6.4 7.3v5.2a3.3 3.3 0 0 1-3.3 3.3H9.3A3.3 3.3 0 0 1 6 45.7z" fill="url(#g)"/><path d="M22.7 24.9c.9-1.3 2-1.9 3.6-1.9h4.7v10.4H16.1z" fill="url(#gl)"/><path d="M34 23h4.7c1.6 0 2.7.6 3.6 1.9l6.6 8.5H34z" fill="url(#gl)"/><rect x="9" y="37" width="46" height="5" fill="#FFFFFF"/><rect x="9" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="13" y="39.5" width="4" height="2.5" fill="#1F232A"/><rect x="17" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="21" y="39.5" width="4" height="2.5" fill="#1F232A"/><rect x="25" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="29" y="39.5" width="4" height="2.5" fill="#1F232A"/><rect x="33" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="37" y="39.5" width="4" height="2.5" fill="#1F232A"/><rect x="41" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="45" y="39.5" width="4" height="2.5" fill="#1F232A"/><rect x="49" y="37" width="4" height="2.5" fill="#1F232A"/><rect x="53" y="39.5" width="4" height="2.5" fill="#1F232A"/><path d="M11 34.5h42" stroke="#fff" stroke-opacity=".5" stroke-width="2" stroke-linecap="round"/><circle cx="19" cy="48" r="7.5" fill="url(#d)"/><circle cx="19" cy="48" r="3.4" fill="url(#m)"/><circle cx="45" cy="48" r="7.5" fill="url(#d)"/><circle cx="45" cy="48" r="3.4" fill="url(#m)"/>',
    'tow': '<ellipse cx="32" cy="57" rx="28" ry="4" fill="url(#sh)"/><path d="M30 44V36l20-12" stroke="#B8BEC8" stroke-width="4.5" stroke-linecap="round" fill="none"/><path d="M50 24v10" stroke="#5B616D" stroke-width="2" stroke-linecap="round"/><path d="M50 34a3 3 0 1 1-3 3" stroke="#5B616D" stroke-width="2.2" fill="none" stroke-linecap="round"/><rect x="26" y="38" width="34" height="9" rx="3" fill="url(#m)"/><path d="M4 46V31a6 6 0 0 1 6-6h9.5a4 4 0 0 1 3.3 1.8l5.2 8V46a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z" fill="url(#o)"/><path d="M9 28.5h9.5l4.6 7.5H9z" fill="url(#gl)"/><path d="M8 29h7" stroke="#fff" stroke-opacity=".55" stroke-width="2" stroke-linecap="round"/><rect x="10" y="20.5" width="8" height="4" rx="2" fill="url(#g)"/><circle cx="15" cy="48.5" r="7" fill="url(#d)"/><circle cx="15" cy="48.5" r="3.2" fill="url(#m)"/><circle cx="47" cy="48.5" r="7" fill="url(#d)"/><circle cx="47" cy="48.5" r="3.2" fill="url(#m)"/>',
    'bodycam': '<ellipse cx="30" cy="57" rx="25" ry="4" fill="url(#sh)"/><g transform="translate(-3 2) scale(.94)"><path d="M6 40.5c0-4 2.4-6.3 6.4-7.3l6.8-9.6c1.6-2.2 3.9-3.4 6.6-3.4h13.6c2.7 0 5 1.2 6.6 3.4l6.8 9.6c4 1 6.4 3.3 6.4 7.3v5.2a3.3 3.3 0 0 1-3.3 3.3H9.3A3.3 3.3 0 0 1 6 45.7z" fill="url(#b)"/><path d="M22.7 24.9c.9-1.3 2-1.9 3.6-1.9h4.7v10.4H16.1z" fill="url(#gl)"/><path d="M34 23h4.7c1.6 0 2.7.6 3.6 1.9l6.6 8.5H34z" fill="url(#gl)"/><path d="M11 35.5h42" stroke="#fff" stroke-opacity=".45" stroke-width="2" stroke-linecap="round"/><path d="M27 37.5l3 3-2.5 2.5 3 3" stroke="#FFD24D" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/><circle cx="19" cy="48" r="7.5" fill="url(#d)"/><circle cx="19" cy="48" r="3.4" fill="url(#m)"/><circle cx="45" cy="48" r="7.5" fill="url(#d)"/><circle cx="45" cy="48" r="3.4" fill="url(#m)"/></g><rect x="38" y="5" width="23" height="17" rx="5" fill="url(#d)"/><rect x="44" y="2.5" width="9" height="4.5" rx="2" fill="#3A3F48"/><circle cx="49.5" cy="13.5" r="5.6" fill="url(#m)"/><circle cx="49.5" cy="13.5" r="3.6" fill="url(#gl)"/><circle cx="48.3" cy="12.3" r="1.1" fill="#fff"/><circle cx="57" cy="8.5" r="1.2" fill="#FF6A00"/>',
    'shield': '<ellipse cx="32" cy="59" rx="18" ry="3.4" fill="url(#sh)"/><path d="M32 4l22 8.5v15.8c0 13.5-9.2 24.2-22 28.7-12.8-4.5-22-15.2-22-28.7V12.5z" fill="url(#gr)"/><path d="M32 8.6l17.8 6.9v12.8c0 11-7.3 19.8-17.8 23.7z" fill="#fff" fill-opacity=".14"/><path d="M16 14.5l16-6" stroke="#fff" stroke-opacity=".6" stroke-width="2.2" stroke-linecap="round"/><path d="M22.5 30.5l7 7 12.5-13" stroke="#fff" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    'plus': '<ellipse cx="32" cy="59" rx="16" ry="3" fill="url(#sh)"/><circle cx="32" cy="31" r="22" fill="url(#o)"/><ellipse cx="32" cy="19" rx="13" ry="7" fill="url(#s)" fill-opacity=".6"/><path d="M32 20v22M21 31h22" stroke="#fff" stroke-width="5" stroke-linecap="round"/>',
  };

  /// Объёмная иконка для линейной иконки из [AgIcons], если такая есть.
  static String? kindFor(String lineIcon) {
    if (lineIcon == AgIcons.wrench) return 'repair';
    if (lineIcon == AgIcons.calendar) return 'calendar';
    if (lineIcon == AgIcons.tag) return 'tag';
    if (lineIcon == AgIcons.bulb) return 'bulb';
    if (lineIcon == AgIcons.oil) return 'oil';
    if (lineIcon == AgIcons.steering) return 'steering';
    if (lineIcon == AgIcons.tire) return 'tire';
    if (lineIcon == AgIcons.pulse) return 'pulse';
    if (lineIcon == AgIcons.brake) return 'brake';
    if (lineIcon == AgIcons.snow) return 'snow';
    return null;
  }

  /// 3D-иконка, а если для этой иконки 3D нет — прежняя линейная.
  static Widget orLine(String lineIcon, {double size = 40, Color? color}) {
    final k = kindFor(lineIcon);
    if (k != null) return AgIcon3D(k, size: size);
    return AgIcon(lineIcon, size: size * .62, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final body = _body[kind] ?? _body['plus']!;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">$_defs$body</svg>',
      width: size,
      height: size,
    );
  }
}
