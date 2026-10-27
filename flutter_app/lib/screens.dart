import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'design.dart';
import 'game.dart';
import 'services.dart';
import 'play_screen.dart';

void openPage(BuildContext c, Widget page) {
  ScaffoldMessenger.of(c).removeCurrentSnackBar();
  Navigator.push(c, MaterialPageRoute(builder: (_) => page));
}

void message(BuildContext c, String text) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));

class HomeScreen extends StatefulWidget {
  final QuestionBank bank;
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  const HomeScreen({
    super.key,
    required this.bank,
    required this.profile,
    required this.audio,
    required this.ads,
  });
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.profile.onboarded) onboard();
    });
  }

  Future<void> onboard() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: navy,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/parola-cemberi-app-icon.png',
                height: 90,
              ),
              const SizedBox(height: 16),
              const Text(
                'PAROLA ÇEMBERİ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: cyan,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Harfleri tamamla, kelimeleri keşfet.\n\nPas: Harf çemberin sonunda yeniden gelir.\nAtla: Harf bu tur bir daha sorulmaz.\nİpucu: Takıldığında küçük bir yardım.\n\nDil Öğren ile 6 dilde Türkçe anlamdan kelimeyi bul.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 24),
              GlowButton(
                'HADİ BAŞLAYALIM',
                warm: true,
                onTap: () => Navigator.pop(c),
              ),
            ],
          ),
        ),
      ),
    );
    widget.profile.onboarded = true;
    widget.profile.save();
  }

  void start({bool quick = false, bool daily = false}) {
    if (daily && widget.profile.dailyDate == Profile.today) {
      message(
        context,
        'Bugünün çemberi tamamlandı. Yarın yeni sorular seni bekliyor!',
      );
      return;
    }
    final seed = daily ? int.parse(Profile.today.replaceAll('-', '')) : null;
    GameEngine create() => GameEngine(
      widget.bank.round(quick: quick, seed: seed),
      quick: quick,
      daily: daily,
    );
    openPage(
      context,
      PlayScreen(
        game: create(),
        profile: widget.profile,
        audio: widget.audio,
        ads: widget.ads,
        replay: create,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.profile,
    builder: (c, _) => Scaffold(
      body: Space(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAROLA',
                          style: TextStyle(
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'ÇEMBERİ',
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: cyan,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Oyna. Keşfet. Dil öğren.',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        openPage(c, StoreScreen(profile: widget.profile)),
                    child: Container(
                      width: 66,
                      height: 66,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cyan, width: 2),
                      ),
                      child: Image.asset(
                        'assets/images/avatar-${widget.profile.avatar}.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.profile.coins}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        openPage(c, StoreScreen(profile: widget.profile)),
                    child: const Text(
                      'MAĞAZA',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MenuTile(
                key: const Key('learn'),
                title: 'Dil Öğren',
                subtitle: '6 dilde kelimeleri çemberde keşfet',
                icon: Icons.translate_rounded,
                color: cyan,
                badge: 'A1 – C2',
                onTap: () => openPage(
                  c,
                  LanguagesScreen(
                    bank: widget.bank,
                    profile: widget.profile,
                    audio: widget.audio,
                    ads: widget.ads,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Glass(
                child: Column(
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: purple, width: 9),
                        boxShadow: [
                          BoxShadow(
                            color: cyan.withValues(alpha: .12),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, size: 66),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ÇEMBER SENİ BEKLİYOR',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.bank.count('turkish')} soruyla kendine meydan oku',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    GlowButton(
                      'OYUNA BAŞLA',
                      key: const Key('start'),
                      warm: true,
                      onTap: () => start(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SmallTile(
                      'Hızlı Tur',
                      '10 harf • 60 saniye',
                      Icons.bolt_rounded,
                      orange,
                      () => start(quick: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmallTile(
                      'Günlük Çember',
                      widget.profile.dailyDate == Profile.today
                          ? 'Tamamlandı ✓'
                          : 'Her güne yeni sorular',
                      Icons.calendar_month_rounded,
                      cyan,
                      () => start(daily: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SmallTile(
                      'İstatistik',
                      'Gelişimini takip et',
                      Icons.bar_chart_rounded,
                      Colors.greenAccent,
                      () => openPage(c, StatsScreen(profile: widget.profile)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmallTile(
                      'Koleksiyon',
                      'Avatarlar ve temalar',
                      Icons.auto_awesome_rounded,
                      Colors.amber,
                      () => openPage(c, StoreScreen(profile: widget.profile)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              MenuTile(
                title: 'Ayarlar',
                subtitle: 'Ses, titreşim ve gizlilik',
                icon: Icons.settings_rounded,
                color: muted,
                onTap: () => openPage(
                  c,
                  SettingsScreen(
                    profile: widget.profile,
                    audio: widget.audio,
                    ads: widget.ads,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BannerSlot(ads: widget.ads),
            ],
          ),
        ),
      ),
    ),
  );
}

class MenuTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const MenuTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
  @override
  Widget build(BuildContext c) => InkWell(
    borderRadius: BorderRadius.circular(25),
    onTap: onTap,
    child: Glass(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        badge!,
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: cyan),
        ],
      ),
    ),
  );
}

class SmallTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback tap;
  const SmallTile(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.tap, {
    super.key,
  });
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(25),
    child: Glass(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
        ],
      ),
    ),
  );
}

class LanguagesScreen extends StatelessWidget {
  final QuestionBank bank;
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  const LanguagesScreen({
    super.key,
    required this.bank,
    required this.profile,
    required this.audio,
    required this.ads,
  });
  @override
  Widget build(BuildContext c) => Scaffold(
    body: Space(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageTitle('DİL ÖĞREN'),
            const SizedBox(height: 25),
            const Text(
              'Hangi dili keşfetmek istersin?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: muted),
            ),
            const SizedBox(height: 24),
            for (final l in Language.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  key: Key('language-${l.id}'),
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => openPage(
                    c,
                    LevelsScreen(
                      bank: bank,
                      profile: profile,
                      audio: audio,
                      ads: ads,
                      language: l,
                    ),
                  ),
                  child: Glass(
                    child: Row(
                      children: [
                        FlagBadge(l.flag),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.title,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                l.nativeName,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${bank.count(l.id)} kelime',
                                style: const TextStyle(
                                  color: cyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: cyan),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class LevelsScreen extends StatelessWidget {
  final QuestionBank bank;
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  final Language language;
  const LevelsScreen({
    super.key,
    required this.bank,
    required this.profile,
    required this.audio,
    required this.ads,
    required this.language,
  });
  void start(BuildContext c, String level) {
    if (!Language.unlocked(level)) {
      message(c, 'Bu seviye şu an kilitli. A1, B1 ve C1 ile oynayabilirsin.');
      return;
    }
    GameEngine create() => GameEngine(
      bank.round(language: language, level: level),
      language: language,
      level: level,
    );
    final g = create();
    if (g.tiles.isEmpty) {
      message(c, 'Bu seviyenin kelimeleri hazırlanıyor.');
      return;
    }
    openPage(
      c,
      PlayScreen(
        game: g,
        profile: profile,
        audio: audio,
        ads: ads,
        replay: create,
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Space(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageTitle(
              language.title
                  .replaceAll('i', 'İ')
                  .replaceAll('ı', 'I')
                  .toUpperCase(),
            ),
            const SizedBox(height: 24),
            Center(child: FlagBadge(language.flag)),
            const SizedBox(height: 16),
            const Text(
              'CEFR seviyeni seç',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 18),
            ),
            const SizedBox(height: 24),
            for (final level in Language.levels)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  key: Key('level-$level'),
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => start(c, level),
                  child: Glass(
                    child: Row(
                      children: [
                        Container(
                          width: 57,
                          height: 57,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (Language.unlocked(level) ? cyan : muted)
                                .withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Language.unlocked(level) ? cyan : muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                switch (level) {
                                  'A1' => 'İlk kelimeler',
                                  'A2' => 'Temel iletişim',
                                  'B1' => 'Bir adım ileri',
                                  'B2' => 'Akıcı keşif',
                                  'C1' => 'Usta kelimeler',
                                  _ => 'Dil ustalığı',
                                },
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${bank.count(language.id, level)} kelime${Language.unlocked(level) ? '' : ' • Kilitli'}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Language.unlocked(level)
                              ? Icons.chevron_right_rounded
                              : Icons.lock_rounded,
                          color: Language.unlocked(level) ? cyan : muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (['spanish', 'azerbaijani'].contains(language.id))
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Başlangıç paketi • Seviye dağılımı editoryaldir; sertifikalı CEFR listesi değildir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class StoreScreen extends StatelessWidget {
  final Profile profile;
  const StoreScreen({super.key, required this.profile});
  static const avatars = [
    ('robot', 'Robot', 0),
    ('astronaut', 'Kaşif', 450),
    ('fox', 'Tilki', 600),
    ('owl', 'Bilge', 750),
    ('cat', 'Kozmo', 900),
  ];
  static const themes = [
    ('classic', 'Klasik Neon', 0),
    ('sunset', 'Gün Batımı', 500),
    ('emerald', 'Zümrüt', 650),
    ('galaxy', 'Galaksi', 850),
    ('ice', 'Buz Kristali', 1000),
  ];
  Future<void> choose(
    BuildContext c,
    String id,
    String title,
    int cost,
    bool avatar,
  ) async {
    if (!profile.owned.contains(id)) {
      if (profile.coins < cost) {
        message(c, 'Yeterli altının yok. Oynayarak altın kazanabilirsin.');
        return;
      }
      final ok = await showDialog<bool>(
        context: c,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(
            '$cost oyun altını karşılığında satın almak istiyor musun? Gerçek para kullanılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Satın al'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    profile.purchase(id, cost, isAvatar: avatar);
  }

  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: profile,
    builder: (c, _) => Scaffold(
      body: Space(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PageTitle('MAĞAZA'),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '◉ ${profile.coins} ALTIN',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Oynayarak kazan, tarzını seç. Gerçek para gerekmez.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 26),
              const Text(
                'AVATARLAR',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final a in avatars)
                    SizedBox(
                      width: (MediaQuery.sizeOf(c).width - 52) / 2,
                      child: InkWell(
                        onTap: () => choose(c, a.$1, a.$2, a.$3, true),
                        child: Glass(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/avatar-${a.$1}.png',
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                a.$2,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                profile.avatar == a.$1
                                    ? 'SEÇİLİ'
                                    : profile.owned.contains(a.$1)
                                    ? 'KULLAN'
                                    : '◉ ${a.$3}',
                                style: TextStyle(
                                  color: profile.avatar == a.$1
                                      ? cyan
                                      : Colors.amber,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'ÇEMBER TEMALARI',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              for (final t in themes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => choose(c, t.$1, t.$2, t.$3, false),
                    child: Glass(
                      child: Row(
                        children: [
                          Icon(
                            Icons.donut_large_rounded,
                            color: accentFor(t.$1),
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              t.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Text(
                            profile.theme == t.$1
                                ? 'SEÇİLİ'
                                : profile.owned.contains(t.$1)
                                ? 'KULLAN'
                                : '◉ ${t.$3}',
                            style: TextStyle(
                              color: profile.theme == t.$1
                                  ? cyan
                                  : Colors.amber,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StatsScreen extends StatelessWidget {
  final Profile profile;
  const StatsScreen({super.key, required this.profile});
  @override
  Widget build(BuildContext c) => Scaffold(
    body: Space(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageTitle('İSTATİSTİK'),
            const SizedBox(height: 30),
            for (final i in [
              (
                'En yüksek puan',
                '${profile.highScore}',
                Icons.emoji_events_rounded,
              ),
              (
                'Tamamlanan oyun',
                '${profile.games}',
                Icons.sports_esports_rounded,
              ),
              ('Doğru cevap', '${profile.correct}', Icons.check_circle_rounded),
              (
                'Başarı oranı',
                profile.total == 0
                    ? '—'
                    : '%${(100 * profile.correct / profile.total).round()}',
                Icons.bar_chart_rounded,
              ),
              (
                'En iyi seri',
                '${profile.bestStreak}',
                Icons.local_fire_department_rounded,
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Glass(
                  child: Row(
                    children: [
                      Icon(i.$3, color: cyan, size: 32),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(i.$1, style: const TextStyle(fontSize: 17)),
                      ),
                      Text(
                        i.$2,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  const SettingsScreen({
    super.key,
    required this.profile,
    required this.audio,
    required this.ads,
  });
  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: profile,
    builder: (c, _) => Scaffold(
      body: Space(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PageTitle('AYARLAR'),
              const SizedBox(height: 24),
              Glass(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ses efektleri'),
                      subtitle: const Text(
                        'Doğru, yanlış, pas ve süre uyarıları',
                      ),
                      value: profile.sound,
                      onChanged: (v) {
                        profile.sound = v;
                        profile.save();
                        if (v) unawaited(audio.play('correct'));
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Titreşim'),
                      value: profile.haptics,
                      onChanged: (v) {
                        profile.haptics = v;
                        profile.save();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlowButton(
                'SESİ TEST ET',
                icon: Icons.volume_up_rounded,
                onTap: () => unawaited(audio.play('complete')),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Reklam gizlilik tercihleri'),
                trailing: const Icon(Icons.privacy_tip_outlined, color: cyan),
                onTap: () => ads.privacy(),
              ),
              const Glass(
                child: Text(
                  'Parola Çemberi • 1.0\n\nOyun ilerlemen bu cihazda saklanır. Reklamlar yalnızca menüde ve tamamlanan turlar arasında gösterilir.\n\nSoru paketleri çevrimdışı çalışır.\n\nYeni Flutter sürümünün ilerlemesi mevcut iOS sürümünden bağımsızdır.',
                  style: TextStyle(color: muted, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => showLicensePage(
                  context: c,
                  applicationName: 'Parola Çemberi',
                ),
                child: const Text('Açık kaynak lisansları'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BannerSlot extends StatefulWidget {
  final Ads ads;
  const BannerSlot({super.key, required this.ads});
  @override
  State<BannerSlot> createState() => _BannerState();
}

class _BannerState extends State<BannerSlot> {
  BannerAd? ad;
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    widget.ads.addListener(load);
    load();
  }

  void load() {
    if (!widget.ads.ready || ad != null) return;
    ad = BannerAd(
      size: AdSize.banner,
      adUnitId: widget.ads.bannerId,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => loaded = true);
        },
        onAdFailedToLoad: (a, e) {
          a.dispose();
          ad = null;
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    widget.ads.removeListener(load);
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => loaded && ad != null
      ? Center(
          child: SizedBox(
            width: ad!.size.width.toDouble(),
            height: ad!.size.height.toDouble(),
            child: AdWidget(ad: ad!),
          ),
        )
      : const SizedBox.shrink();
}
