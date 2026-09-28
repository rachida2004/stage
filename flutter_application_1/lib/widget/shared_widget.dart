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
      case TicketStatus.enAttente: return StatusBadge(label: s.label, bg: AppColors.warningLight, fg: AppColors.warning);
    }
  }

  factory StatusBadge.fromUserRole(UserRole r) {
    switch (r) {
      case UserRole.admin:       return StatusBadge(label: r.label, bg: AppColors.primaryLight, fg: AppColors.primaryDark);
      case UserRole.agent:       return StatusBadge(label: r.label, bg: AppColors.warningLight, fg: AppColors.warning);
      case UserRole.superviseur: return StatusBadge(label: r.label, bg: AppColors.successLight, fg: AppColors.success);
      case UserRole.usager:      return StatusBadge(label: r.label, bg: AppColors.surface, fg: AppColors.muted);
      case UserRole.secretaire:  return StatusBadge(label: r.label, bg: AppColors.primaryLight, fg: AppColors.primary);
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
    // 🎯 Couleur alignée sur les cartes du tableau de bord ("Invitations
    // traitées") pour rester cohérent visuellement dans toute l'appli.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
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
    color: Color(0xFF15803D),
  ),
),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(delta!, style: TextStyle(fontSize: 11, color: deltaPositive ? const Color.fromARGB(255, 9, 80, 35) : AppColors.danger)),
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
    // 🎯 Même correctif que StatCard : plus de dépendance à
    // Theme.of(context).brightness, une seule apparence cohérente.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 3, 61, 17), width: 0.5),
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
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 3, 67, 3)), textAlign: TextAlign.right)),
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

// ════════════════════════════════════════════════════════════════════
// 🎯 Affichage d'erreur centralisé — un message "pas le droit" (403) ou
// "session expirée" (401) n'est pas une vraie erreur système : on l'affiche
// en orange (information claire) plutôt qu'en rouge (réservé aux erreurs
// inattendues). Le texte lui-même vient déjà d'ApiException.fromDio.
// ════════════════════════════════════════════════════════════════════
void showErrorSnack(BuildContext context, String message) {
  final pasDeDroits = message.contains('droits nécessaires') || message.contains('session a expiré');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: pasDeDroits ? Colors.orange : AppColors.danger,
    behavior: SnackBarBehavior.floating,
  ));
}

// ── Pagination moderne ──────────────────────────────────────────────────────
// 🎯 Widget réutilisable (Invitations, Tickets, et tout autre écran avec une
// longue liste) : boutons précédent/suivant + numéros de page, avec des
// points de suspension quand il y a beaucoup de pages. `currentPage` est
// 0-indexé ; l'affichage utilisateur est en 1-indexé.
class ModernPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  /// Optionnel : "X–Y sur Z résultats", affiché au-dessus des boutons.
  final String? resultsLabel;

  const ModernPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.resultsLabel,
  });

  // Fenêtre de pages à afficher : toujours la 1ère, la dernière, la page
  // courante ± 1, avec des `null` (points de suspension) pour le reste.
  List<int?> _fenetre() {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i);
    final set = <int>{0, totalPages - 1, currentPage};
    if (currentPage - 1 >= 0) set.add(currentPage - 1);
    if (currentPage + 1 < totalPages) set.add(currentPage + 1);
    final sorted = set.toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resultsLabel != null) ...[
          Text(resultsLabel!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavBtn(
              icon: Icons.chevron_left,
              enabled: currentPage > 0,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            const SizedBox(width: 4),
            ..._fenetre().map((p) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: p == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('…', style: TextStyle(color: AppColors.muted)),
                        )
                      : _PageBtn(
                          number: p + 1,
                          selected: p == currentPage,
                          onTap: () => onPageChanged(p),
                        ),
                )),
            const SizedBox(width: 4),
            _NavBtn(
              icon: Icons.chevron_right,
              enabled: currentPage < totalPages - 1,
              onTap: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34, height: 34,
          child: Icon(icon, size: 19, color: enabled ? const Color(0xFF1A1A2E) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;
  const _PageBtn({required this.number, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color.fromARGB(255, 3, 58, 26) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(color: selected ? const Color.fromARGB(255, 3, 58, 26) : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: selected ? null : onTap,
        child: SizedBox(
          width: 34, height: 34,
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}