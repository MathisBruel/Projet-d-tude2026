import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';

enum _DashboardState {
  defaultState,
  loading,
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const dashboardState = _DashboardState.defaultState;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _DashboardHeader(),
            Expanded(
              child: dashboardState == _DashboardState.loading
                  ? const _LoadingDashContent()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        _FadeInUp(
                          delay: 0,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: _WeatherCard(),
                          ),
                        ),
                        _FadeInUp(
                          delay: 90,
                          child: const _SectionTitle(
                            title: 'Mes alertes',
                            trailing: '3 actives',
                          ),
                        ),
                        _FadeInUp(
                          delay: 140,
                          child: const SizedBox(
                            height: 92,
                            child: _AlertsList(),
                          ),
                        ),
                        _FadeInUp(
                          delay: 200,
                          child: const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: _SectionTitle(
                              title: 'Dernières prédictions',
                              trailing: 'Tout voir →',
                            ),
                          ),
                        ),
                        _FadeInUp(
                          delay: 250,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: const [
                                _PredictionRow(
                                  crop: 'Blé tendre',
                                  parcel: 'Parcelle Nord',
                                  yieldValue: '7.2',
                                  confidence: 78,
                                  when: 'il y a 2h',
                                  emoji: '🌾',
                                ),
                                SizedBox(height: 10),
                                _PredictionRow(
                                  crop: 'Maïs',
                                  parcel: 'Parcelle Sud',
                                  yieldValue: '9.1',
                                  confidence: 85,
                                  when: 'hier',
                                  emoji: '🌽',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const BottomNavBar(activeTab: 'home'),
          ],
        ),
      ),
    );
  }
}

class _LoadingDashContent extends StatelessWidget {
  const _LoadingDashContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: const [
        _LoadingCardWeather(),
        SizedBox(height: 14),
        _LoadingAlertCards(),
        SizedBox(height: 14),
        _LoadingPredictionCard(),
        SizedBox(height: 10),
        _LoadingPredictionCard(),
      ],
    );
  }
}

class _LoadingCardWeather extends StatelessWidget {
  const _LoadingCardWeather();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0A1C2B2D)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerSkeleton(width: 140, height: 12, radius: 8),
                    SizedBox(height: 10),
                    _ShimmerSkeleton(width: 80, height: 40, radius: 8),
                    SizedBox(height: 10),
                    _ShimmerSkeleton(width: 120, height: 12, radius: 8),
                  ],
                ),
              ),
              _ShimmerSkeleton(width: 64, height: 64, radius: 32),
            ],
          ),
          SizedBox(height: 18),
          _ShimmerSkeleton(height: 56, radius: 12),
        ],
      ),
    );
  }
}

class _LoadingAlertCards extends StatelessWidget {
  const _LoadingAlertCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        clipBehavior: Clip.hardEdge,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          return const _ShimmerSkeleton(width: 180, height: 60, radius: 14);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: 3,
      ),
    );
  }
}

class _LoadingPredictionCard extends StatelessWidget {
  const _LoadingPredictionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0A1C2B2D)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: const Row(
        children: [
          _ShimmerSkeleton(width: 44, height: 44, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: _ShimmerSkeleton(height: 16, radius: 8),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: _ShimmerSkeleton(height: 12, radius: 8),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _ShimmerSkeleton(width: 44, height: 44, radius: 22),
        ],
      ),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton({
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (t * 2.0), 0),
              end: Alignment(1.0 + (t * 2.0), 0),
              colors: const [
                AppColors.neutreLight,
                Color(0xFFF7F9F7),
                AppColors.neutreLight,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}


class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mardi 22 avril',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreMedium,
                      ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Bonjour, Pierre '),
                      TextSpan(
                        text: '🌱',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const _NotificationBell(count: 3),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text(
              'PM',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none_rounded, size: 20),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.background, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfacePrimary, AppColors.white],
          stops: [0, 0.55],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14102814),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined, size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Beauce, Eure-et-Loir',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutreMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '18',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            height: 0.9,
                            letterSpacing: -2.5,
                            color: AppColors.neutreDark,
                          ),
                        ),
                        SizedBox(width: 6),
                        Padding(
                          padding: EdgeInsets.only(bottom: 7),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutreMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ensoleillé · Ressenti 17°',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const _WeatherIconBlob(),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.1))),
            ),
            child: const Row(
              children: [
                Expanded(child: _Metric(icon: Icons.water_drop, value: '12', unit: 'mm')),
                Expanded(child: _Metric(icon: Icons.air_rounded, value: '15', unit: 'km/h')),
                Expanded(child: _Metric(icon: Icons.opacity, value: '65', unit: '%')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                '7 JOURS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutreMedium,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '+2°C cette semaine',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const SizedBox(
            height: 48,
            child: _Sparkline(temperatures: [14, 16, 15, 17, 19, 18, 18]),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekLabel('L'),
              _WeekLabel('M'),
              _WeekLabel('M'),
              _WeekLabel('J'),
              _WeekLabel('V'),
              _WeekLabel('S'),
              _WeekLabel('D'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherIconBlob extends StatelessWidget {
  const _WeatherIconBlob();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 2,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withOpacity(0.13), spreadRadius: 10),
                  BoxShadow(color: AppColors.secondary.withOpacity(0.07), spreadRadius: 20),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.unit});

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutreMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.neutreMedium,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neutreDark,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      children: const [
        _AlertCard(
          bgColor: Color(0xFFFDECEC),
          sideColor: AppColors.error,
          titleColor: AppColors.error,
          emoji: '⚠',
          title: 'Risque gel',
          subtitle: 'Parcelle Nord · J+1',
        ),
        SizedBox(width: 10),
        _AlertCard(
          bgColor: Color(0xFFFFF0DC),
          sideColor: AppColors.warning,
          titleColor: AppColors.warning,
          emoji: '🌧',
          title: 'Fortes pluies',
          subtitle: 'Toutes parcelles · J+2',
        ),
        SizedBox(width: 10),
        _AlertCard(
          bgColor: AppColors.surfacePrimary,
          sideColor: AppColors.success,
          titleColor: AppColors.success,
          emoji: '✓',
          title: 'Récolte optimale',
          subtitle: 'Parcelle Est · cette sem.',
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.bgColor,
    required this.sideColor,
    required this.titleColor,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final Color bgColor;
  final Color sideColor;
  final Color titleColor;
  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: sideColor, width: 3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutreDark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    required this.crop,
    required this.parcel,
    required this.yieldValue,
    required this.confidence,
    required this.when,
    required this.emoji,
  });

  final String crop;
  final String parcel;
  final String yieldValue;
  final int confidence;
  final String when;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0A1C2B2D)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      crop,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Text('·', style: TextStyle(fontSize: 11, color: AppColors.neutreMedium)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        parcel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutreMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      yieldValue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      't/ha',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutreMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutreLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      when,
                      style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ConfidenceRing(value: confidence),
        ],
      ),
    );
  }
}

class _ConfidenceRing extends StatelessWidget {
  const _ConfidenceRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'CONFIANCE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.neutreMedium,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: AppColors.neutreLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomDashboardNav extends StatelessWidget {
  const _BottomDashboardNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: Color(0x141C2B2D), width: 0.5)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: const Row(
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Accueil', active: true),
          _NavItem(icon: Icons.map_outlined, label: 'Carte'),
          _NavItem(icon: Icons.auto_awesome_rounded, label: 'IA'),
          _NavItem(icon: Icons.groups_rounded, label: 'Communauté'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.active = false});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.neutreMedium;

    return Expanded(
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.temperatures});

  final List<double> temperatures;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(temperatures: temperatures),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.temperatures});

  final List<double> temperatures;

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.length < 2) {
      return;
    }

    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final range = (maxTemp - minTemp).abs() < 0.001 ? 1.0 : (maxTemp - minTemp);

    final points = <Offset>[];
    for (var i = 0; i < temperatures.length; i++) {
      final x = (i / (temperatures.length - 1)) * size.width;
      final y = size.height - 4 - ((temperatures[i] - minTemp) / range) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withOpacity(0.12);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final last = points.last;
    canvas.drawCircle(last, 5, Paint()..color = AppColors.white);
    canvas.drawCircle(last, 3, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.temperatures != temperatures;
  }
}

class _FadeInUp extends StatelessWidget {
  const _FadeInUp({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Opacity(opacity: value, child: childWidget),
        );
      },
      child: child,
    );
  }
}
