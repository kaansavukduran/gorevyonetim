import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n.dart';

import 'package:flutter/services.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import 'character_page.dart';
import 'day_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
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
      _remind();
    });
  }

  /// Reminders already shown today (task id + time), so each shows once.
  final Set<String> _reminded = {};

  /// Shows an in-app reminder for every task whose time has come today and
  /// that is not ticked yet. (System notifications are not used: the app
  /// works only while it is open.)
  void _remind() {
    if (!mounted || controller.state != LoadState.ready) return;
    final now = controller.now();
    final today = controller.today;
    final minutes = now.hour * 60 + now.minute;
    final due = [
      for (final t in controller.data.tasksOn(today))
        if (t.time != null &&
            t.time!.minutes <= minutes &&
            !controller.data.isDone(t.id, today) &&
            _reminded.add('${today.toIso()} ${t.id} ${t.time!.format()}'))
          t,
    ];
    if (due.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('reminder'),
        width: MediaQuery.sizeOf(context).width > 560 ? 520 : null,
        duration: const Duration(seconds: 12),
        content: Text(
          'Hatırlatma: ${due.map((t) => '${t.time!.format()} ${t.title}').join(', ')}',
        ),
        action: SnackBarAction(
          label: context.t('Güne git'),
          onPressed: () => _setDay(controller.today),
        ),
      ),
    );
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

  /// Tabs in order; Karakter only in game mode.
  List<_Tab> _tabs() => [
    _Tab('gun', Icons.today_outlined, Icons.today, context.t('Gün')),
    _Tab(
      'gorevler',
      Icons.list_alt_outlined,
      Icons.list_alt,
      context.t('Görevler'),
    ),
    _Tab(
      'kontrol',
      Icons.grid_view_outlined,
      Icons.grid_view,
      context.t('Kontrol'),
    ),
    if (controller.settings.gameMode)
      _Tab(
        'karakter',
        Icons.person_outline,
        Icons.person,
        context.t('Karakter'),
      ),
    _Tab(
      'ayarlar',
      Icons.settings_outlined,
      Icons.settings,
      context.t('Ayarlar'),
    ),
  ];

  void _go(String id) {
    final i = _tabs().indexWhere((t) => t.id == id);
    if (i >= 0) setState(() => _tab = i);
  }

  Widget _ready(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final tabs = _tabs();
    if (_tab >= tabs.length) _tab = tabs.length - 1;
    final current = tabs[_tab].id;
    final Widget page = switch (current) {
      'gun' => DayPage(
        controller: controller,
        day: _day,
        onDayChanged: _setDay,
        onOpenCharacter: () => _go('karakter'),
      ),
      'gorevler' => TasksPage(controller: controller),
      'kontrol' => HistoryPage(controller: controller),
      'karakter' => CharacterPage(controller: controller),
      _ => SettingsPage(controller: controller, version: widget.version),
    };

    final body = Column(
      children: [
        if (!controller.store.persistent)
          _Banner(
            icon: Icons.info_outline_rounded,
            text: context.t(
              context.t(
                'Tarayıcı önizlemesi: görevler kaydedilmez. Uygulama masaüstü için yapıldı (Windows, macOS, Linux).',
              ),
            ),
          ),
        if (controller.saveError != null)
          _Banner(
            icon: Icons.error_outline_rounded,
            text: context.t(
              context.t(
                '{p0}\nDeğişiklik ekranda duruyor; bir sonraki değişiklikte yeniden denenecek.',
              ),
              {'p0': controller.saveError},
            ),
            error: true,
          ),
        Expanded(child: page),
      ],
    );

    final scaffold = Scaffold(
      appBar: AppBar(title: Text(context.t('Günlük Görevler'))),
      floatingActionButton: current != 'gorevler'
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-task-fab'),
              tooltip: context.t('Yeni görev (Ctrl + N)'),
              onPressed: _newTask,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.t('Yeni görev')),
            ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selected),
                    label: t.label,
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
                    for (final t in tabs)
                      NavigationRailDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selected),
                        label: Text(t.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );

    void tab(int i) {
      if (i < tabs.length) setState(() => _tab = i);
    }

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
            tab(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            tab(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            tab(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            tab(3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            tab(4),
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}

class _Tab {
  const _Tab(this.id, this.icon, this.selected, this.label);
  final String id;
  final IconData icon;
  final IconData selected;
  final String label;
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
      appBar: AppBar(title: Text(context.t('Günlük Görevler'))),
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
                  context.t('Kayıtlı görevler açılamadı'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.loadError ?? '',
                  key: const Key('unreadable-message'),
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('Dosya:'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SelectableText(store.location),
                if (store.backupLocation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.t('Günlük yedekler:'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SelectableText(store.backupLocation!),
                ],
                const SizedBox(height: 12),
                Text(
                  context.t(
                    context.t(
                      'Dosyaya dokunulmadı ve üzerine yazılmadı. Bir yedeği bu dosyanın yerine kopyalayıp uygulamayı yeniden açabilir ya da dosyayı kenara alıp boş bir listeyle başlayabilirsin.',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  key: const Key('start-over'),
                  onPressed: () async {
                    final movedTo = await controller.startOverAfterUnreadable();
                    if (!context.mounted) return;
                    showUndoSnack(
                      context,
                      context.t('Eski dosya şuraya taşındı: {p0}', {
                        'p0': movedTo,
                      }),
                    );
                  },
                  child: Text(
                    context.t('Dosyayı kenara al ve boş liste başlat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
