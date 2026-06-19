import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/theme/app_typography.dart';
import 'package:yb_staff_app/core/utils/currency_formatter.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';
import 'package:yb_staff_app/presentation/widgets/final_items_sheet.dart';

class JobCard extends StatefulWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onStatusUpdate,
    required this.onFinalItemsSubmit,
    required this.onDetailTap,
  });

  final Job job;
  final Future<void> Function(JobStatus newStatus) onStatusUpdate;
  final FinalItemsSubmitCallback onFinalItemsSubmit;
  final VoidCallback onDetailTap;

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isUpdating = false;

  // Warna aksen atas card mengikuti warna status pekerjaan
  Color get _accentColor {
    switch (widget.job.status) {
      case JobStatus.assigned:
        return const Color(0xFFF59E0B);
      case JobStatus.inProgress:
        return const Color(0xFF3B82F6);
      case JobStatus.waitingFinalItems:
        return const Color(0xFF10B981);
      case JobStatus.invoiceGenerated:
        return const Color(0xFF8B5CF6);
      case JobStatus.completed:
        return const Color(0xFF6B7280);
      case JobStatus.canceled:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> _handleStatusUpdate(JobStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await widget.onStatusUpdate(newStatus);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openMaps() async {
    final link = widget.job.mapsLink;
    final uri = link != null && link.isNotEmpty
        ? Uri.parse(link)
        : Uri.parse(
            'https://maps.google.com/?q=${Uri.encodeComponent(widget.job.address)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _sessionLabel(int hour) {
    if (hour < 12) return AppStrings.sessionPagi;
    if (hour < 15) return AppStrings.sessionSiang;
    return AppStrings.sessionSore;
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final scheduleText =
        '${DateFormatter.toFull(job.scheduledAt)} - ${DateFormatter.toTime(job.scheduledAt)} WIB - ${_sessionLabel(job.scheduledAt.hour)}';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Garis aksen atas — warna sesuai status
            Container(height: 3, color: _accentColor),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris badges layanan + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: job.services
                              .map((s) => _ServiceBadge(label: s))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusBadge(status: job.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Nama customer
                  Text(
                    job.customerName,
                    style: AppTypography.headingLarge.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Jadwal
                  _InfoRow(icon: Icons.access_time_rounded, text: scheduleText),
                  const SizedBox(height: AppSpacing.xs),
                  // Alamat
                  _InfoRow(icon: Icons.location_on_outlined, text: job.address),
                  if (job.region != null || job.power != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RegionPowerBadge(region: job.region, power: job.power),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Tombol Buka Navigasi
                  _NavButton(onTap: _openMaps),
                  const SizedBox(height: AppSpacing.sm),
                  // Tombol aksi (Mulai / Selesai / disabled)
                  _ActionButton(
                    status: job.status,
                    isLoading: _isUpdating,
                    onTap: _buildActionCallback(context, job.status),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Tombol Detail → buka bottom sheet
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: widget.onDetailTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.inputBorder),
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusButton),
                        ),
                      ),
                      child: Text(
                        AppStrings.jobDetail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Builder(builder: (_) {
                    final showFinal =
                        job.status == JobStatus.invoiceGenerated ||
                            job.status == JobStatus.completed;
                    final cardItems =
                        showFinal ? job.finalItems : job.items;
                    final cardTitle =
                        showFinal ? AppStrings.finalItemsTag : AppStrings.estimatedItemsTag;
                    if (cardItems.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        _ItemsSection(
                          items: cardItems,
                          title: cardTitle,
                          discount: job.discount,
                          discountType: job.discountType,
                          discountValue: job.discountValue,
                          downPayment: showFinal ? job.downPayment : 0,
                          outstandingBalance:
                              showFinal ? job.outstandingBalance : 0,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _buildActionCallback(BuildContext context, JobStatus status) {
    if (_isUpdating) return null;
    switch (status) {
      case JobStatus.assigned:
        return () => _handleStatusUpdate(JobStatus.inProgress);
      case JobStatus.inProgress:
        return () => FinalItemsSheet.show(
              context,
              job: widget.job,
              onSubmit: widget.onFinalItemsSubmit,
            );
      case JobStatus.waitingFinalItems:
      case JobStatus.invoiceGenerated:
      case JobStatus.completed:
      case JobStatus.canceled:
        return null;
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label});
  final String label;

  static const _styles = <String, _ServiceStyle>{
    // Leather / sofa
    'leather':     _ServiceStyle(icon: Icons.chair_rounded,           bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706), display: 'Leather Revive'),
    'sofa':        _ServiceStyle(icon: Icons.chair_rounded,           bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706), display: 'Sofa'),
    // Vacuum / deep vacuum
    'vacuum':      _ServiceStyle(icon: Icons.air_rounded,             bg: Color(0xFFDBEAFE), fg: Color(0xFF2563EB), display: 'Deep Vacuum'),
    'deep_vacuum': _ServiceStyle(icon: Icons.air_rounded,             bg: Color(0xFFDBEAFE), fg: Color(0xFF2563EB), display: 'Deep Vacuum'),
    // Laundry / dry wash
    'dry':         _ServiceStyle(icon: Icons.water_drop_outlined,     bg: Color(0xFFCFFAFE), fg: Color(0xFF0891B2), display: 'Cuci Dry Wash'),
    'laundry':     _ServiceStyle(icon: Icons.local_laundry_service_rounded, bg: Color(0xFFCFFAFE), fg: Color(0xFF0891B2), display: 'Laundry'),
    'cuci':        _ServiceStyle(icon: Icons.water_drop_outlined,     bg: Color(0xFFCFFAFE), fg: Color(0xFF0891B2), display: 'Cuci'),
    // Disinfeksi
    'disinfeksi':  _ServiceStyle(icon: Icons.shield_outlined,         bg: Color(0xFFEDE9FE), fg: Color(0xFF7C3AED), display: 'Disinfeksi'),
    'disinfect':   _ServiceStyle(icon: Icons.shield_outlined,         bg: Color(0xFFEDE9FE), fg: Color(0xFF7C3AED), display: 'Disinfeksi'),
    // AC
    'ac':          _ServiceStyle(icon: Icons.ac_unit_rounded,         bg: Color(0xFFE0F2FE), fg: Color(0xFF0284C7), display: 'Servis AC'),
    // General cleaning
    'general':     _ServiceStyle(icon: Icons.cleaning_services_rounded, bg: Color(0xFFDCFCE7), fg: Color(0xFF16A34A), display: 'General Cleaning'),
    'regular':     _ServiceStyle(icon: Icons.cleaning_services_rounded, bg: Color(0xFFDCFCE7), fg: Color(0xFF16A34A), display: 'Regular'),
  };

  _ServiceStyle _resolve() {
    final key = label.toLowerCase().replaceAll(' ', '_');
    // exact match
    if (_styles.containsKey(key)) return _styles[key]!;
    // partial match — first keyword that appears in the label
    for (final k in _styles.keys) {
      if (key.contains(k)) return _styles[k]!;
    }
    // fallback — capitalize label
    final display = label
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return _ServiceStyle(
      icon: Icons.cleaning_services_rounded,
      bg: AppColors.badgeBg,
      fg: AppColors.primary,
      display: display,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 11, color: style.fg),
          const SizedBox(width: 4),
          Text(
            style.display,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceStyle {
  const _ServiceStyle({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.display,
  });
  final IconData icon;
  final Color bg;
  final Color fg;
  final String display;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final JobStatus status;

  Color get _dotColor {
    switch (status) {
      case JobStatus.assigned:
        return const Color(0xFFF59E0B);
      case JobStatus.inProgress:
        return const Color(0xFF3B82F6);
      case JobStatus.waitingFinalItems:
        return const Color(0xFF10B981);
      case JobStatus.invoiceGenerated:
        return const Color(0xFF8B5CF6);
      case JobStatus.completed:
        return const Color(0xFF6B7280);
      case JobStatus.canceled:
        return const Color(0xFFEF4444);
    }
  }

  Color get _bgColor {
    switch (status) {
      case JobStatus.assigned:
        return const Color(0xFFFFFBEB);
      case JobStatus.inProgress:
        return const Color(0xFFEFF6FF);
      case JobStatus.waitingFinalItems:
        return const Color(0xFFECFDF5);
      case JobStatus.invoiceGenerated:
        return const Color(0xFFF5F3FF);
      case JobStatus.completed:
        return const Color(0xFFF3F4F6);
      case JobStatus.canceled:
        return const Color(0xFFFEF2F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: AppTypography.captionSmall)),
      ],
    );
  }
}

class _RegionPowerBadge extends StatelessWidget {
  const _RegionPowerBadge({this.region, this.power});
  final String? region;
  final String? power;

  @override
  Widget build(BuildContext context) {
    final label =
        [region, power].where((s) => s != null && s.isNotEmpty).join(' - ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.inputBorder),
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 16),
            const SizedBox(width: 6),
            Text(
              AppStrings.openNavigation,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new_rounded, size: 13),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.status,
    required this.isLoading,
    required this.onTap,
  });

  final JobStatus status;
  final bool isLoading;
  final VoidCallback? onTap;

  Color get _bgColor {
    switch (status) {
      case JobStatus.assigned:
        return const Color(0xFF3B82F6);
      case JobStatus.inProgress:
        return const Color(0xFF10B981);
      case JobStatus.waitingFinalItems:
      case JobStatus.invoiceGenerated:
      case JobStatus.completed:
      case JobStatus.canceled:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    // canceled: tampilkan banner merah khusus
    if (status == JobStatus.canceled) {
      return Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined,
                size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.jobCanceled,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }

    final isDone = status == JobStatus.waitingFinalItems ||
        status == JobStatus.invoiceGenerated ||
        status == JobStatus.completed;

    if (isDone) {
      IconData doneIcon;
      String doneLabel;
      if (status == JobStatus.waitingFinalItems) {
        doneIcon = Icons.hourglass_top_rounded;
        doneLabel = AppStrings.waitingVerification;
      } else {
        doneIcon = Icons.check_circle_outline;
        doneLabel = AppStrings.jobDone;
      }
      return Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(doneIcon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              doneLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final label = status == JobStatus.assigned
        ? AppStrings.startJob
        : AppStrings.finishJob;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bgColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _bgColor.withAlpha(178),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == JobStatus.assigned
                        ? Icons.play_arrow_rounded
                        : Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.items,
    required this.title,
    this.discount = 0.0,
    this.discountType,
    this.discountValue = 0.0,
    this.downPayment = 0.0,
    this.outstandingBalance = 0.0,
  });

  final List<JobItem> items;
  final String title;
  final double discount;
  final String? discountType;
  final double discountValue;
  final double downPayment;
  final double outstandingBalance;

  String get _discountLabel {
    if (discountType == 'percentage' && discountValue > 0) {
      return '${AppStrings.discountLabel} (${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 1)}%)';
    }
    return AppStrings.discountLabel;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B8A78),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.lg, color: Color(0xFFE5E7EB)),
          if (discount > 0) ...[
            _cardPriceRow(AppStrings.subtotalLabel, CurrencyFormatter.format(subtotal)),
            const SizedBox(height: 4),
            _cardPriceRow(
              _discountLabel,
              '- ${CurrencyFormatter.format(discount)}',
              valueColor: const Color(0xFFEF4444),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalFinal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (downPayment > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: AppSpacing.sm),
            _cardPriceRow(AppStrings.downPaymentLabel, CurrencyFormatter.format(downPayment)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: outstandingBalance > 0
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: outstandingBalance > 0
                      ? const Color(0xFFFED7AA)
                      : const Color(0xFF6EE7B7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(
                      outstandingBalance > 0
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                      size: 12,
                      color: outstandingBalance > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.remainingBill,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: outstandingBalance > 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ]),
                  Text(
                    outstandingBalance > 0
                        ? CurrencyFormatter.format(outstandingBalance)
                        : AppStrings.lunas,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: outstandingBalance > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}
