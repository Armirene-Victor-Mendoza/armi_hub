import 'package:armi_hub/core/theme/brand_colors.dart';
import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.contextData,
    required this.onScanPressed,
    required this.onHistoryPressed,
    required this.onEditContextPressed,
  });

  final BusinessContext contextData;
  final VoidCallback onScanPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onEditContextPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                gradient: BrandColors.topGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: BrandColors.mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hub_rounded, color: BrandColors.dark),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'ARMI HUB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white),
                        onPressed: onEditContextPressed,
                        tooltip: 'Editar contexto',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          contextData.storeName ?? 'Tienda seleccionada',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contextData.businessName ?? 'Kokoriko'}  •  ID tienda ${contextData.storeId}',
                          style: const TextStyle(color: Color(0xFF5C6570), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            _StatPill(label: 'Comercio ${contextData.businessId}'),
                            const _StatPill(label: 'Operativo'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: BrandColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: <Widget>[
                    _MenuTile(
                      icon: Icons.document_scanner_rounded,
                      title: 'Escanear factura',
                      subtitle: 'Captura recibo y crea orden',
                      color: BrandColors.mint,
                      onTap: onScanPressed,
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.history_rounded,
                      title: 'Historial de ordenes',
                      subtitle: 'Consulta envios y reintentos',
                      color: const Color(0xFF78B8FF),
                      onTap: onHistoryPressed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.mintSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: BrandColors.dark, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: BrandColors.dark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
