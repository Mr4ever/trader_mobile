import 'package:flutter/material.dart';

class PositionTable extends StatelessWidget {
  const PositionTable({super.key, required this.rows, this.showAction = false, this.onSell});
  final List<Map<String, dynamic>> rows;
  final bool showAction;
  final void Function(int id)? onSell;

  DataRow _row(Map<String, dynamic> p) {
    final id = (p['id'] ?? '').toString();
    final sym = (p['symbol'] ?? '').toString();
    final status = (p['status'] ?? '').toString();
    final qty = (p['quantity'] ?? '').toString();
    final buy = (p['buy_price'] ?? '').toString();
    final tpct = p['target_pct'] == null ? '' : ((p['target_pct'] as num) * 100).toStringAsFixed(3) + '%';
    final tprice = (p['target_price'] ?? '').toString();
    final created = (p['created_at'] ?? '').toString();
    final closed = (p['closed_at'] ?? '').toString();
    final sellPrice = (p['sell_price'] ?? '').toString();
    final realized = (p['realized_pnl'] ?? '').toString();

    final cells = <DataCell>[
      DataCell(Text(id)),
      DataCell(Text(sym)),
      DataCell(Text(status)),
      DataCell(Text(qty)),
      DataCell(Text(buy)),
      DataCell(Text(tpct)),
      DataCell(Text(tprice)),
      DataCell(Text(created)),
      DataCell(Text(closed)),
      DataCell(Text(sellPrice)),
      DataCell(Text(realized)),
    ];
    if (showAction) {
      cells.add(
        DataCell(
          ElevatedButton(
            onPressed: onSell == null ? null : () => onSell!(int.tryParse(id) ?? -1),
            child: const Text('Sell Now'),
          ),
        ),
      );
    }
    return DataRow(cells: cells);
  }

  @override
  Widget build(BuildContext context) {
    final headers = [
      'ID','Symbol','Status','Qty','Buy Price','Target %','Target Price','Created','Closed','Sell Price','Realized PnL',
      if (showAction) 'Action'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows.map(_row).toList(),
      ),
    );
  }
}
