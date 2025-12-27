import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/net_worth_service.dart';

class NetWorthOverviewCard extends StatelessWidget {
  const NetWorthOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final netWorthService = Provider.of<NetWorthService>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<double>(
          stream: netWorthService.netWorthStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading net worth'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }

            final netWorth = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net Worth',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(netWorth),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: netWorth >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAssetLiabilityStreams(context, netWorthService, currencyFormat),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssetLiabilityStreams(
      BuildContext context, NetWorthService service, NumberFormat format) {
    return StreamBuilder(
      stream: service.totalAssetsStream,
      builder: (context, assetsSnapshot) {
        return StreamBuilder(
          stream: service.totalLiabilitiesStream,
          builder: (context, liabilitiesSnapshot) {
            final assets = assetsSnapshot.data ?? 0.0;
            final liabilities = liabilitiesSnapshot.data ?? 0.0;
            final total = assets + liabilities;

            return Column(
              children: [
                _buildDetailRow('Total Assets', format.format(assets), Colors.green),
                const SizedBox(height: 8),
                _buildDetailRow('Total Liabilities', format.format(liabilities), Colors.red),
                const SizedBox(height: 16),
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: assets / total,
                      minHeight: 10,
                      backgroundColor: Colors.red.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
