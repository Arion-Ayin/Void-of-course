// 이 파일은 프리미엄 서비스 해금 팝업을 만드는 코드예요.
// 세 가지 결제 티어를 보여주고, 선택된 티어에 맞는 버튼을 표시해요.

import 'package:flutter/material.dart';

// 결제 티어를 나타내는 열거형이에요.
enum PremiumTier {
  adRemove, // 광고 제거 라이트
  proPass, // 기능 프로 패스 (위젯+캘린더)
  masterAll, // 마스터 올인원 패스 (전체 해금) — 추천
}

// 각 티어의 정보를 담는 모델이에요.
class _TierInfo {
  final PremiumTier tier;
  final String label;
  final String price;
  final bool recommended;

  const _TierInfo({
    required this.tier,
    required this.label,
    required this.price,
    this.recommended = false,
  });
}

// 프리미엄 팝업 다이얼로그 위젯이에요.
class PremiumDialog extends StatefulWidget {
  const PremiumDialog({super.key});

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog>
    with SingleTickerProviderStateMixin {
  // 기본 선택 티어는 마스터 올인원(추천)이에요.
  PremiumTier _selectedTier = PremiumTier.masterAll;

  late final AnimationController _shimmerController;

  // 티어 목록이에요.
  static const List<_TierInfo> _tiers = [
    _TierInfo(tier: PremiumTier.adRemove, label: '광고 제거', price: '3,000원'),
    _TierInfo(
      tier: PremiumTier.proPass,
      label: '바탕화면 위젯 \n+ 보이드 구글 캘린더',
      price: '6,000원',
    ),
    _TierInfo(
      tier: PremiumTier.masterAll,
      label: '광고제거 + 바탕화면 위젯 \n+ 보이드 구글 캘린더',
      price: '7,500원',
      recommended: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 골드 shimmer 애니메이션 컨트롤러를 만들어요.
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // 현재 선택된 티어의 정보를 가져와요.
  _TierInfo get _selectedTierInfo =>
      _tiers.firstWhere((t) => t.tier == _selectedTier);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 다이얼로그 배경색
    final dialogBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1333);
    final subtitleColor =
        isDark ? const Color(0xFFBBBBBB) : const Color(0xFF666666);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 상단 헤더 (그라데이션 배너) ────────────────────────────
            _buildHeader(isDark),

            // ── 티어 선택 목록 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children:
                    _tiers.map((info) {
                      return _buildTierRow(
                        info,
                        titleColor,
                        subtitleColor,
                        isDark,
                      );
                    }).toList(),
              ),
            ),

            // ── 구매 버튼 ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _buildPurchaseButton(),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 헤더 위젯이에요.
  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    const Color.fromARGB(255, 0, 0, 0),
                    const Color(0xFF1A1040),
                  ]
                  : [
                    const Color.fromARGB(255, 0, 0, 0),
                    const Color.fromARGB(255, 0, 0, 0),
                  ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const Text(
            '프리미엄 서비스',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '한 번 결제로 평생 광고 없이 영구 소장!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // 각 티어 행을 만드는 위젯이에요.
  Widget _buildTierRow(
    _TierInfo info,
    Color titleColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final isSelected = _selectedTier == info.tier;
    final isRecommended = info.recommended;

    // 골드 테두리 & 하이라이트 — 추천 티어이면서 선택된 경우
    final bool showGoldHighlight = isRecommended && isSelected;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = info.tier),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // shimmer gradient offset
          final shimmerOffset = _shimmerController.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // 선택 상태에 따라 배경색을 다르게 해요.
              color:
                  isSelected
                      ? (isDark
                          ? const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withValues(alpha: 0.9)
                          : const Color(0xFFF5EEFF))
                      : (isDark
                          ? const Color(0xFF13102B).withValues(alpha: 0.6)
                          : const Color(0xFFF8F8F8)),
              // 골드 shimmer 테두리 또는 일반 테두리
              border:
                  showGoldHighlight
                      ? Border.all(
                        color:
                            Color.lerp(
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                              (shimmerOffset * 2).clamp(0.0, 1.0),
                            )!,
                        width: 2.2,
                      )
                      : isSelected
                      ? Border.all(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        width: 1.8,
                      )
                      : Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
              // 추천+선택 시 골드 글로우 그림자
              boxShadow:
                  showGoldHighlight
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                      : [],
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            // 라디오 버튼 역할을 하는 동그라미
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? (isRecommended
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : const Color.fromARGB(255, 0, 0, 0))
                          : Colors.grey.withValues(alpha: 0.5),
                  width: 2,
                ),
                color:
                    isSelected
                        ? (isRecommended
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 0, 0, 0))
                        : Colors.transparent,
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 12),
            // 티어 이름 + 추천 뱃지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          info.label,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '★ 추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 가격
            Text(
              info.price,
              style: TextStyle(
                color:
                    isSelected
                        ? (isRecommended
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 0, 0, 0))
                        : subtitleColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 구매 버튼이에요. 선택된 티어의 가격을 보여줘요.
  Widget _buildPurchaseButton() {
    final info = _selectedTierInfo;
    final isGold = info.recommended;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors:
                isGold
                    ? [
                      const Color.fromARGB(255, 0, 0, 0),
                      const Color.fromARGB(255, 0, 0, 0),
                    ]
                    : [
                      const Color.fromARGB(255, 0, 0, 0),
                      const Color.fromARGB(255, 0, 0, 0),
                    ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isGold
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 0, 0, 0))
                  .withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO: 실제 결제 로직 연결
              Navigator.of(context).pop();
            },
            child: Center(
              child: Text(
                '${info.price}에 평생 소장하기',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 팝업을 띄우는 편의 함수예요.
Future<void> showPremiumDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const PremiumDialog(),
  );
}
