import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game.dart';

const navy = Color(0xFF060727),
    panel = Color(0xFF202340),
    cyan = Color(0xFF16E4EF),
    purple = Color(0xFF7538EE),
    orange = Color(0xFFFF8417);
const muted = Color(0xFFABB0C9);

Color accentFor(String theme) => switch (theme) {
  'sunset' => orange,
  'emerald' => const Color(0xFF53EB9C),
  'galaxy' => const Color(0xFFC17DFF),
  'ice' => const Color(0xFFA4EFFF),
  _ => cyan,
};

class Space extends StatelessWidget {
  final Widget child;
  const Space({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF060824), Color(0xFF082542), Color(0xFF0D0539)],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _Stars())),
        child,
      ],
    ),
  );
}

class _Stars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final r = math.Random(42);
    for (var i = 0; i < 48; i++) {
      p.color = (i % 3 == 0 ? cyan : Colors.white).withValues(
        alpha: .08 + r.nextDouble() * .18,
      );
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
        .7 + r.nextDouble() * 1.3,
        p,
      );
    }
    p.shader =
        RadialGradient(
          colors: [purple.withValues(alpha: .16), Colors.transparent],
        ).createShader(
          Rect.fromCircle(
            center: Offset(0, size.height * .8),
            radius: size.width,
          ),
        );
    canvas.drawRect(Offset.zero & size, p);
  }

  @override
  bool shouldRepaint(_Stars oldDelegate) => false;
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tint,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (tint ?? panel).withValues(alpha: .96),
          (tint ?? panel).withValues(alpha: .65),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: .15),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool warm;
  final IconData? icon;
  const GlowButton(
    this.label, {
    super.key,
    required this.onTap,
    this.warm = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Opacity(
      opacity: onTap == null ? .4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: warm
                ? [const Color(0xFFFFBC24), orange, const Color(0xFFFC5310)]
                : [const Color(0xFFAD42FA), purple, const Color(0xFF5120B9)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .3)),
          boxShadow: [
            BoxShadow(
              color: (warm ? orange : purple).withValues(alpha: .23),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 21),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PageTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const PageTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        key: const Key('back'),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded, color: cyan, size: 32),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
      ),
      SizedBox(width: 48, child: trailing),
    ],
  );
}

// Drawn flags avoid missing emoji glyphs and remain identical on both platforms.
class FlagBadge extends StatelessWidget {
  final String country;
  const FlagBadge(this.country, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 40,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white24),
    ),
    child: CustomPaint(painter: _Flag(country)),
  );
}

class _Flag extends CustomPainter {
  final String country;
  _Flag(this.country);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    final rect = Offset.zero & s;
    if (country == 'GB') {
      p.color = const Color(0xFF163978);
      c.drawRect(rect, p);
      p
        ..color = Colors.white
        ..strokeWidth = 10;
      c.drawLine(Offset.zero, Offset(s.width, s.height), p);
      c.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
      p
        ..color = const Color(0xFFD82C43)
        ..strokeWidth = 4;
      c.drawLine(Offset.zero, Offset(s.width, s.height), p);
      c.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
      p.color = Colors.white;
      c.drawRect(Rect.fromLTWH(s.width * .37, 0, s.width * .26, s.height), p);
      c.drawRect(Rect.fromLTWH(0, s.height * .32, s.width, s.height * .36), p);
      p.color = const Color(0xFFD82C43);
      c.drawRect(Rect.fromLTWH(s.width * .43, 0, s.width * .14, s.height), p);
      c.drawRect(Rect.fromLTWH(0, s.height * .4, s.width, s.height * .2), p);
      return;
    }
    final colors = switch (country) {
      'IT' => [const Color(0xFF159361), Colors.white, const Color(0xFFE34849)],
      'DE' => [
        const Color(0xFF151515),
        const Color(0xFFE34142),
        const Color(0xFFFFCD36),
      ],
      'NL' => [const Color(0xFFDC4246), Colors.white, const Color(0xFF2554A3)],
      'ES' => [
        const Color(0xFFBE2636),
        const Color(0xFFFFD54A),
        const Color(0xFFBE2636),
      ],
      _ => [
        const Color(0xFF14A9DE),
        const Color(0xFFE23A4A),
        const Color(0xFF1DA468),
      ],
    };
    for (var i = 0; i < 3; i++) {
      p.color = colors[i];
      c.drawRect(
        country == 'IT'
            ? Rect.fromLTWH(i * s.width / 3, 0, s.width / 3, s.height)
            : Rect.fromLTWH(0, i * s.height / 3, s.width, s.height / 3),
        p,
      );
    }
    if (country == 'AZ') {
      p.color = Colors.white;
      c.drawCircle(Offset(s.width * .51, s.height * .5), 5, p);
      p.color = colors[1];
      c.drawCircle(Offset(s.width * .54, s.height * .48), 4, p);
      p.color = Colors.white;
      c.drawCircle(Offset(s.width * .64, s.height * .5), 1.8, p);
    }
  }

  @override
  bool shouldRepaint(_Flag oldDelegate) => oldDelegate.country != country;
}

class LetterWheel extends StatelessWidget {
  final GameEngine game;
  final String theme;
  const LetterWheel(this.game, {super.key, required this.theme});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight);
      final tile = math.min(39.0, size * .105);
      final radius = size / 2 - tile * .65;
      final accent = accentFor(theme);
      return Center(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _Ring(
                    game.seconds / (game.quick ? 60 : 120),
                    accent,
                    game.tiles.length,
                  ),
                ),
              ),
              SizedBox(
                width: size * .54,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        game.seconds <= 15
                            ? Icons.timer_rounded
                            : Icons.schedule_rounded,
                        color: game.seconds <= 15 ? Colors.redAccent : accent,
                        size: size * .065,
                      ),
                      Text(
                        '${(game.seconds ~/ 60).toString().padLeft(2, '0')}:${(game.seconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: size * .15,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      Container(
                        height: 1,
                        width: size * .4,
                        color: Colors.white24,
                        margin: EdgeInsets.symmetric(vertical: size * .025),
                      ),
                      Text(
                        'PUAN',
                        style: TextStyle(
                          color: accent,
                          fontSize: size * .044,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        '${game.score}',
                        style: TextStyle(
                          fontSize: size * .11,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (game.streak >= 2)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: orange,
                              size: size * .06,
                            ),
                            Text(
                              '${game.streak} SERİ',
                              style: TextStyle(
                                color: orange,
                                fontWeight: FontWeight.w900,
                                fontSize: size * .04,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < game.tiles.length; i++)
                Builder(
                  builder: (context) {
                    final angle =
                        -math.pi / 2 + i * 2 * math.pi / game.tiles.length;
                    final t = game.tiles[i];
                    final active = t.state == TileState.active;
                    final color = switch (t.state) {
                      TileState.active => orange,
                      TileState.correct => const Color(0xFF59C73A),
                      TileState.wrong => const Color(0xFFE8455D),
                      TileState.passed => accent,
                      TileState.skipped => const Color(0xFF343D56),
                      _ => const Color(0xFF433BA1),
                    };
                    return Positioned(
                      left: size / 2 + math.cos(angle) * radius - tile / 2,
                      top: size / 2 + math.sin(angle) * radius - tile * .57,
                      child: Transform.rotate(
                        angle: .20 * math.sin(angle * 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: tile,
                          height: tile * 1.14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(tile * .25),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(color, Colors.white, .16)!,
                                color,
                              ],
                            ),
                            border: Border.all(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: .3),
                              width: active ? 2.3 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: active ? .8 : .17,
                                ),
                                blurRadius: active ? 16 : 4,
                                spreadRadius: active ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              t.question.letter,
                              style: TextStyle(
                                fontSize: tile * .63,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _Ring extends CustomPainter {
  final double progress;
  final Color color;
  final int count;
  _Ring(this.progress, this.color, this.count);
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final r = s.width * .34;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = purple.withValues(alpha: .7);
    c.drawCircle(center, r, p);
    c.drawCircle(center, r - 6, p..color = color.withValues(alpha: .25));
    p
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    c.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 52; i++) {
      final a = i * 2 * math.pi / 52;
      p.color = color.withValues(alpha: i / 52 < progress ? .38 : .12);
      c.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * s.width * .407,
        s.width * .008,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
