import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const StatusBadge({super.key, required this.label, required this.bg, required this.fg});

  factory StatusBadge.fromInvStatus(InvitationStatus s) {
    switch (s) {
      case InvitationStatus.planifiee:   return StatusBadge(label: s.label, bg: AppColors.primaryLight, fg: AppColors.primaryDark);
      case InvitationStatus.enCours:     return StatusBadge(label: s.label, bg: AppColors.primaryLight, fg: AppColors.primary);
      case InvitationStatus.terminee:    return StatusBadge(label: s.label, bg: AppColors.successLight, fg: AppColors.success);
      case InvitationStatus.nonTraitee:  return StatusBadge(label: s.label, bg: AppColors.dangerLight, fg: AppColors.danger);
      case InvitationStatus.enAttente:   return StatusBadge(label: s.label, bg: AppColors.warningLight, fg: AppColors.warning);
    }
  }

  factory StatusBadge.fromTicketStatus(TicketStatus s) {
    switch (s) {
      case TicketStatus.enCours:   return StatusBadge(label: s.label, bg: AppColors.primaryLight, fg: AppColors.primaryDark);
      case TicketStatus.resolu:    return StatusBadge(label: s.label, bg: AppColors.successLight, fg: AppColors.success);
      case TicketStatus.ferme:     return StatusBadge(label: s.label, bg: AppColors.surface, fg: AppColors.muted);
      case TicketStatus.enPause:   return StatusBadge(label: s.label, bg: AppColors.surface, fg: AppColors.muted);
      case TicketStatus.enAttente: return StatusBadge(label: s.label, bg: AppColors.warningLight, fg: AppColors.warning);
    }
  }

  factory StatusBadge.fromUserRole(UserRole r) {
    switch (r) {
      case UserRole.admin:       return StatusBadge(label: r.label, bg: AppColors.primaryLight, fg: AppColors.primaryDark);
      case UserRole.agent:       return StatusBadge(label: r.label, bg: AppColors.warningLight, fg: AppColors.warning);
      case UserRole.superviseur: return StatusBadge(label: r.label, bg: AppColors.successLight, fg: AppColors.success);
      case UserRole.usager:      return StatusBadge(label: r.label, bg: AppColors.surface, fg: AppColors.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}

// ── Priority Badge ────────────────────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TicketPriority.haute: color = AppColors.danger; break;
      case TicketPriority.normale: color = AppColors.warning; break;
      case TicketPriority.basse: color = const Color.fromARGB(255, 42, 157, 0); break;
    }
    return Text(priority.label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5));
  }
}

// ── App Card ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? delta;
  final bool deltaPositive;

  const StatCard({super.key, required this.value, required this.label, this.delta, this.deltaPositive = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color.fromARGB(255, 23, 23, 23) : const Color.fromARGB(255, 245, 245, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
       Text(
  value,
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 238, 239, 244))),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(delta!, style: TextStyle(fontSize: 11, color: deltaPositive ? AppColors.success : AppColors.danger)),
          ],
        ],
      ),
    );
  }
}

// ── User Avatar ───────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bg;
  final Color? fg;

  const UserAvatar({super.key, required this.initials, this.size = 36, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials, style: TextStyle(fontSize: size * 0.33, fontWeight: FontWeight.w500, color: fg ?? AppColors.primaryDark)),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 11, 10, 10))),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color.fromARGB(255, 235, 239, 236) : AppColors.surface,//reche
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 29, 18, 237), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color.fromARGB(255, 6, 6, 6)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart Row ─────────────────────────────────────────────────────────────
class BarChartRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const BarChartRow({super.key, required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 14, 14, 220)), textAlign: TextAlign.right)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 22, child: Text('$value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ── Toggle Switch Row ─────────────────────────────────────────────────────────
class ToggleRow extends StatefulWidget {
  final String label;
  final bool initial;
  const ToggleRow({super.key, required this.label, this.initial = true});

  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  late bool value;
  @override
  void initState() { super.initState(); value = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 13))),
        Switch(
          value: value,
          onChanged: (v) => setState(() => value = v),
         activeThumbColor: AppColors.primary,
activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}