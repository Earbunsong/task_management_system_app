import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        body: const TabBarView(children: [_UsersTab(), _PaymentsTab()]),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, i) => ListTile(
        title: Text('User #$i'),
        trailing: FilledButton.tonal(
          onPressed: () {},
          child: const Text('Disable'),
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, i) => ListTile(
        title: Text('Payment #$i'),
        subtitle: const Text('Stripe • \$9.99'),
      ),
    );
  }
}
