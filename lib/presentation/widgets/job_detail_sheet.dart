import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/utils/currency_formatter.dart';
import 'package:yb_staff_app/core/utils/date_formatter.dart';
import 'package:yb_staff_app/domain/entities/job.dart';
import 'package:yb_staff_app/domain/entities/job_item.dart';

class JobDetailSheet extends StatelessWidget {
  const JobDetailSheet({super.key, required this.job});

  final Job job;

  static Future<void> show(BuildContext context, Job job) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.md, AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.jobDetailTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (job.orderCode != null)
                            Text(
                              job.orderCode!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              // ── Scrollable body ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCustomerSection(),
                      _buildLocationSection(),
                      _buildStatusSection(),
                      _buildNotesSection(),
                      _buildPhotosSection(),
                      _buildPricingSection(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildCustomerSection() {
    return _section(
      title: AppStrings.sectionCustomer,
      children: [
        _infoRow(AppStrings.labelCustomer, job.customerName),
        _infoRow(AppStrings.labelPhone, job.customerPhone, isPhone: true),
        if (job.whatsappUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(job.whatsappUrl!);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF25D366)),
                  foregroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: Text(
                  AppStrings.whatsappCustomer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _section(
      title: AppStrings.sectionLocation,
      children: [
        if (job.region != null) _infoRow(AppStrings.labelRegion, job.region!),
        _infoRow(AppStrings.labelAddress, job.address),
        if (job.mapsLink != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(job.mapsLink!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.inputBorder),
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                ),
                icon: const Icon(Icons.map_outlined, size: 16),
                label: Text(
                  AppStrings.openMaps,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final hour = job.scheduledAt.hour;
    final session = hour < 12
        ? AppStrings.sessionPagi
        : hour < 15
            ? AppStrings.sessionSiang
            : AppStrings.sessionSore;
    final scheduleText =
        '${DateFormatter.toFull(job.scheduledAt)} - ${DateFormatter.toTime(job.scheduledAt)} WIB - $session';

    return _section(
      title: AppStrings.sectionStatusSchedule,
      children: [
        _infoRow(AppStrings.labelSchedule, scheduleText),
        _infoRow(AppStrings.labelStatus, job.status.displayName),
        if (job.power != null) _infoRow(AppStrings.labelPower, job.power!),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _section(
      title: AppStrings.sectionNotes,
      children: [
        Text(
          job.notes ?? AppStrings.noNotes,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: job.notes != null ? AppColors.textPrimary : AppColors.textHint,
            fontStyle: job.notes != null ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return _section(
      title: AppStrings.sectionPhotos,
      children: [
        if (job.photos.isEmpty)
          Text(
            AppStrings.noPhotos,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: job.photos.length,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Image.network(
                job.photos[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textHint),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final showFinal = job.status == JobStatus.invoiceGenerated ||
        job.status == JobStatus.completed;
    final displayItems = showFinal ? job.finalItems : job.items;
    final sectionTitle = showFinal ? AppStrings.finalItemsTag : AppStrings.estimatedItemsTag;

    // Use API-provided values when available, fall back to calculation
    final subtotal = job.subtotalPrice > 0
        ? job.subtotalPrice
        : displayItems.fold(0.0, (s, i) => s + i.subtotal);
    final discount = job.discount;
    final total = job.finalTotalPrice > 0
        ? job.finalTotalPrice
        : subtotal - discount;
    final downPayment = job.downPayment;
    final outstanding = job.outstandingBalance;

    if (displayItems.isEmpty) {
      return _section(
        title: sectionTitle,
        children: [
          Text(
            AppStrings.noItems,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final discountLabel = _discountLabel();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sectionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B8A78),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(subtotal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...displayItems.map((item) => _itemRow(item)),
            const Divider(height: AppSpacing.xl, color: Color(0xFFE5E7EB)),
            _priceRow(AppStrings.subtotalLabel, CurrencyFormatter.format(subtotal)),
            _priceRow(discountLabel, CurrencyFormatter.format(discount),
                isDiscount: true),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: AppSpacing.md),
            // Total akhir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.totalFinal,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(CurrencyFormatter.format(total),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
            if (downPayment > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: AppSpacing.md),
              _priceRow(AppStrings.downPaymentLabel, CurrencyFormatter.format(downPayment)),
              const SizedBox(height: AppSpacing.sm),
              // Sisa tagihan — highlighted
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: outstanding > 0
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: outstanding > 0
                        ? const Color(0xFFFED7AA)
                        : const Color(0xFF6EE7B7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          outstanding > 0
                              ? Icons.pending_outlined
                              : Icons.check_circle_outline,
                          size: 14,
                          color: outstanding > 0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.remainingBill,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: outstanding > 0
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      outstanding > 0
                          ? CurrencyFormatter.format(outstanding)
                          : AppStrings.lunas,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: outstanding > 0
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
      ),
    );
  }

  String _discountLabel() {
    if (job.discountType == 'percentage' && job.discountValue > 0) {
      return '${AppStrings.discountLabel} (${job.discountValue.toStringAsFixed(job.discountValue % 1 == 0 ? 0 : 1)}%)';
    }
    return AppStrings.discountLabel;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B8A78),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isPhone = false}) {
    final Widget valueWidget = isPhone
        ? GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:$value');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          )
        : Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _itemRow(JobItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description != null)
                  Text(
                    '${item.description} - ${item.quantity} item',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            isDiscount ? '- $amount' : amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
