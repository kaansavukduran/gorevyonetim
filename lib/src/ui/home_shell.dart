import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import 'day_page.dart';
import 'history_page.dart';
import 'task_actions.dart';
import 'tasks_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller, this.version = ''});

  final TaskController controller;
  final String version;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late LocalDate _day = widget.controller.today;
  Timer? _clock;

  TaskController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Past midnight the new day becomes "today"; a person looking at the
    // old today follows it.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      final before = controller.today;
      if (controller.refreshToday() && _day == before) {
        setState(() => _day = controller.today);
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _setDay(LocalDate d) => setState(() {
    _day = d;
    _tab = 0;
  });

  Future<void> _newTask() => addTaskWithEditor(
    context,
    controller,
    start: _tab == 0 ? _day : controller.today,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.state) {
        LoadState.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        LoadState.unreadable => _UnreadablePage(controller: controller),
        LoadState.ready => _ready(context),
      },
    );
  }

  Widget _ready(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final pages = [
      DayPage(controller: controller, day: _day, onDayChanged: _setDay),
      TasksPage(controller: controller),
      HistoryPage(controller: controller),
    ];
    const destinations = [
      (Icons.today_outlined, Icons.today_rounded, 'Gün'),
      (Icons.list_alt_outlined, Icons.list_alt_rounded, 'Görevler'),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Kontrol'),
    ];

    final body = Column(
      children: [
        if (!controller.store.persistent)
          const _Banner(
            icon: Icons.info_outline_rounded,
            text: 'Tarayıcı önizlemesi: görevler kaydedilmez. Uygulama Windows için yapıldı.',
          ),
        if (controller.saveError != null)
          _Banner(
            icon: Icons.error_outline_rounded,
            text:
                '${controller.saveError}\nDeğişiklik ekranda duruyor; bir sonraki değişiklikte yeniden denenecek.',
            error: true,
          ),
        Expanded(child: pages[_tab]),
      ],
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Görevler'),
        actions: [
          IconButton(
            key: const Key('about-button'),
            tooltip: 'Veriler nerede, kısayollar',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showAbout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _tab == 2
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-task-fab'),
              tooltip: 'Yeni görev (Ctrl + N)',
              onPressed: _newTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni görev'),
            ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: d.$3,
                  ),
              ],
            ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$3),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newTask,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
            _setDay(_day.addDays(-1)),
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
            _setDay(_day.addDays(1)),
        const SingleActivator(LogicalKeyboardKey.keyB, alt: true): () =>
            _setDay(controller.today),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            setState(() => _tab = 0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            setState(() => _tab = 1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            setState(() => _tab = 2),
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }

  void _showAbout(BuildContext context) {
    final store = controller.store;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Görevler'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.version.isNotEmpty) Text('Sürüm ${widget.version}'),
              const SizedBox(height: 12),
              const Text(
                'Görevlerin bu bilgisayarda tek bir dosyada durur; internete hiçbir şey gönderilmez.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Veri dosyası:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SelectableText(store.location, key: const Key('about-location')),
              if (store.backupLocation != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Günlük yedekler (son 14 gün):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SelectableText(store.backupLocation!),
              ],
              const SizedBox(height: 16),
              const Text(
                'Kısayollar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text(
                'Ctrl + N  yeni görev\n'
                'Alt + ← / →  önceki / sonraki gün\n'
                'Alt + B  bugüne dön\n'
                'Ctrl + 1 / 2 / 3  Gün / Görevler / Kontrol',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: error ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: error
                  ? scheme.onErrorContainer
                  : scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: error
                      ? scheme.onErrorContainer
                      : scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadablePage extends StatelessWidget {
  const _UnreadablePage({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = controller.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Görevler')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kayıtlı görevler açılamadı',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.loadError ?? '',
                  key: const Key('unreadable-message'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dosya:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SelectableText(store.location),
                if (store.backupLocation != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Günlük yedekler:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SelectableText(store.backupLocation!),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Dosyaya dokunulmadı ve üzerine yazılmadı. Bir yedeği bu dosyanın '
                  'yerine kopyalayıp uygulamayı yeniden açabilir ya da dosyayı kenara '
                  'alıp boş bir listeyle başlayabilirsin.',
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  key: const Key('start-over'),
                  onPressed: () async {
                    final movedTo = await controller.startOverAfterUnreadable();
                    if (!context.mounted) return;
                    showUndoSnack(
                      context,
                      'Eski dosya şuraya taşındı: $movedTo',
                    );
                  },
                  child: const Text('Dosyayı kenara al ve boş liste başlat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
