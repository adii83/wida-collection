import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/capsule_planner_controller.dart';

class CapsulePlannerScreen extends GetView<CapsulePlannerController> {
  const CapsulePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perencana Capsule Wardrobe')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlannerSheet(context),
        icon: const Icon(Icons.event_note),
        label: const Text('Rencana Mingguan'),
      ),
      body: Obx(() {
        if (controller.plans.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Atur kombinasi mix-and-match favoritmu. Rencana disimpan offline lewat Hive dan warna aksen mengikuti preferensi tema yang tersimpan pada shared_preferences.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final plan = controller.plans[index];
            return Card(
              child: ListTile(
                title: Text(plan.weekLabel),
                subtitle: Text(
                  'Top: ${plan.top}\nBottom: ${plan.bottom}\nOuter: ${plan.outer}\nAksesori: ${plan.accessories}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          int.tryParse(plan.colorHex, radix: 16) ?? 0xFF6D4C41,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.deletePlan(plan.id),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: controller.plans.length,
        );
      }),
    );
  }

  void _openPlannerSheet(BuildContext context) {
    final week = TextEditingController();
    final top = TextEditingController();
    final bottom = TextEditingController();
    final outer = TextEditingController();
    final accessories = TextEditingController();
    final color = TextEditingController(text: controller.accentColorHex.value);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Susun Rencana Capsule',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: week,
                decoration: const InputDecoration(
                  labelText: 'Label Minggu (mis. Week 3 November)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: top,
                decoration: const InputDecoration(labelText: 'Atasan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bottom,
                decoration: const InputDecoration(labelText: 'Bawahan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: outer,
                decoration: const InputDecoration(labelText: 'Outer / Layer'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accessories,
                decoration: const InputDecoration(labelText: 'Aksesori utama'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: color,
                decoration: const InputDecoration(
                  labelText: 'Warna Aksen (ARGB hex, contoh FFEE1166)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  controller.savePlan(
                    weekLabel: week.text,
                    top: top.text,
                    bottom: bottom.text,
                    outer: outer.text,
                    accessories: accessories.text,
                    colorHex: color.text,
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Simpan Rencana'),
              ),
            ],
          ),
        );
      },
    );
  }
}
