import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

void main() {
  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محفظتي',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const WalletListScreen(),
    );
  }
}

class Transaction {
  final int? id;
  final double amount;
  final String type;
  final DateTime date;
  Transaction(
      {this.id,
      required this.amount,
      required this.type,
      required this.date});

  Map<String, dynamic> toMap() {
    return {
      'wallet_id': id,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}

class Wallet {
  int? id;
  String name;
  String number;
  double balance;
  List<Transaction> transactions;

  Wallet(
      {this.id,
      required this.name,
      required this.number,
      this.balance = 0.0,
      required this.transactions});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'balance': balance,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      number: map['number'],
      balance: map['balance'],
      transactions: [],
    );
  }

  double get dailyTotal {
    double sum = 0;
    for (var t in transactions) {
      if (t.date.day == DateTime.now().day &&
          t.date.month == DateTime.now().month &&
          t.type == 'sent') {
        sum += t.amount;
      }
    }
    return sum;
  }

  double get monthlyTotal {
    double sum = 0;
    for (var t in transactions) {
      if (t.date.month == DateTime.now().month &&
          t.type == 'sent') {
        sum += t.amount;
      }
    }
    return sum;
  }

  bool get isOverLimit =>
      (dailyTotal >= 60000 || monthlyTotal >= 200000 || balance >= 200000);
}

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});
  @override
  WalletListScreenState createState() => WalletListScreenState();
}

class WalletListScreenState extends State<WalletListScreen> {
  List<Wallet> wallets = [];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final dbWallets = await DatabaseHelper.instance.getWallets();
    List<Wallet> loaded = [];
    for (var wMap in dbWallets) {
      var wallet = Wallet.fromMap(wMap);
      final dbTrans =
          await DatabaseHelper.instance.getTransactions(wallet.id!);
      wallet.transactions =
          dbTrans.map((t) => Transaction.fromMap(t)).toList();
      loaded.add(wallet);
    }
    setState(() => wallets = loaded);
  }

  void _showWalletDialog({Wallet? wallet, int? index}) {
    var nCtrl = TextEditingController(text: wallet?.name ?? "");
    var pCtrl = TextEditingController(text: wallet?.number ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(wallet == null ? "إضافة محفظة جديدة" : "تعديل المحفظة",
            textAlign: TextAlign.right),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nCtrl,
              decoration: const InputDecoration(labelText: "اسم المحفظة"),
              textAlign: TextAlign.right),
          TextField(
              controller: pCtrl,
              decoration: const InputDecoration(labelText: "رقم الموبايل"),
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () async {
                if (nCtrl.text.isNotEmpty) {
                  if (wallet == null) {
                    final id = await DatabaseHelper.instance.insertWallet({
                      'name': nCtrl.text,
                      'number': pCtrl.text,
                      'balance': 0.0,
                    });
                    setState(() {
                      wallets.insert(
                          0,
                          Wallet(
                              id: id,
                              name: nCtrl.text,
                              number: pCtrl.text,
                              transactions: []));
                    });
                  } else {
                    await DatabaseHelper.instance.updateWallet({
                      'id': wallet.id,
                      'name': nCtrl.text,
                      'number': pCtrl.text,
                      'balance': wallet.balance,
                    });
                    setState(() {
                      wallets[index!].name = nCtrl.text;
                      wallets[index].number = pCtrl.text;
                    });
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text("حفظ"))
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف المحفظة", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف هذه المحفظة نهائياً؟",
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("تراجع")),
          TextButton(
              onPressed: () async {
                await DatabaseHelper.instance
                    .deleteWallet(wallets[index].id!);
                setState(() => wallets.removeAt(index));
                Navigator.pop(ctx);
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('محافظي الإلكترونية'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWalletDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: wallets.isEmpty
          ? const Center(child: Text("اضغط على + لإضافة محفظة"))
          : ListView.builder(
              itemCount: wallets.length,
              itemBuilder: (context, i) {
                final w = wallets[i];
                return Card(
                  color: w.isOverLimit ? Colors.red[50] : Colors.white,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 20),
                            onPressed: () =>
                                _showWalletDialog(wallet: w, index: i)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(i)),
                      ],
                    ),
                    title: Text(w.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "الرصيد: ${w.balance} ج.م\nالرقم: ${w.number}",
                        textAlign: TextAlign.right),
                    trailing: Icon(Icons.wallet,
                        color: w.isOverLimit ? Colors.red : Colors.green),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WalletDetailScreen(
                              wallet: w, onUpdate: _loadWallets)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback onUpdate;
  const WalletDetailScreen(
      {super.key, required this.wallet, required this.onUpdate});
  @override
  WalletDetailScreenState createState() => WalletDetailScreenState();
}

class WalletDetailScreenState extends State<WalletDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final dbTrans =
        await DatabaseHelper.instance.getTransactions(widget.wallet.id!);
    setState(() {
      widget.wallet.transactions =
          dbTrans.map((t) => Transaction.fromMap(t)).toList();
    });
  }

  void _transact(String type) {
    var amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'sent' ? "إرسال (سحب)" : "استلام (إيداع)",
            textAlign: TextAlign.right),
        content: TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(hintText: "0.00")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () async {
                double amt = double.tryParse(amtCtrl.text) ?? 0;
                if (amt > 0) {
                  double newBalance = type == 'sent'
                      ? widget.wallet.balance - amt
                      : widget.wallet.balance + amt;

                  await DatabaseHelper.instance.insertTransaction({
                    'wallet_id': widget.wallet.id,
                    'amount': amt,
                    'type': type,
                    'date': DateTime.now().toIso8601String(),
                  });

                  await DatabaseHelper.instance
                      .updateBalance(widget.wallet.id!, newBalance);

                  setState(() {
                    widget.wallet.transactions.insert(
                        0,
                        Transaction(
                            amount: amt, type: type, date: DateTime.now()));
                    widget.wallet.balance = newBalance;
                  });
                  widget.onUpdate();
                  Navigator.pop(ctx);
                }
              },
              child: const Text("تأكيد"))
        ],
      ),
    );
  }

  void _confirmDeleteHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف السجل", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف جميع المعاملات؟",
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("تراجع")),
          TextButton(
              onPressed: () async {
                await DatabaseHelper.instance
                    .deleteTransactions(widget.wallet.id!);
                await DatabaseHelper.instance
                    .updateBalance(widget.wallet.id!, 0.0);
                setState(() {
                  widget.wallet.transactions.clear();
                  widget.wallet.balance = 0.0;
                });
                widget.onUpdate();
                Navigator.pop(ctx);
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallet;
    return Scaffold(
      appBar: AppBar(
          title: Text(w.name),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmDeleteHistory,
              tooltip: 'حذف السجل',
            ),
          ]),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: w.isOverLimit ? Colors.red[100] : Colors.green[50],
          child: Column(children: [
            Text("الرصيد الحالي", textAlign: TextAlign.center),
            Text("${w.balance.toStringAsFixed(2)} ج.م",
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Divider(),
            Text("المتبقي اليوم: ${60000 - w.dailyTotal} ج.م",
                style: TextStyle(
                    color: (60000 - w.dailyTotal) <= 0
                        ? Colors.red
                        : Colors.black)),
            Text("المتبقي الشهر: ${200000 - w.monthlyTotal} ج.م",
                style: TextStyle(
                    color: (200000 - w.monthlyTotal) <= 0
                        ? Colors.red
                        : Colors.black)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton.icon(
              onPressed: () => _transact('received'),
              icon: const Icon(Icons.add),
              label: const Text("استلام")),
          ElevatedButton.icon(
              onPressed: () => _transact('sent'),
              icon: const Icon(Icons.remove),
              label: const Text("إرسال"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white)),
        ]),
        const Divider(),
        const Text("سجل المعاملات",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: w.transactions.isEmpty
              ? const Center(child: Text("لا توجد معاملات"))
              : ListView.builder(
                  itemCount: w.transactions.length,
                  itemBuilder: (context, i) {
                    final t = w.transactions[i];
                    return ListTile(
                      trailing: Icon(
                          t.type == 'sent'
                              ? Icons.arrow_circle_up
                              : Icons.arrow_circle_down,
                          color: t.type == 'sent' ? Colors.red : Colors.green),
                      title: Text("${t.amount} ج.م", textAlign: TextAlign.right),
                      subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(t.date),
                          textAlign: TextAlign.right),
                      leading: Text(t.type == 'sent' ? "سحب" : "إيداع"),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
