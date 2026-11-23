import 'package:material_ui/material_ui.dart';

import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'server_client.dart';
import 'sync_service.dart';

/// Dialog „Mit Server verbinden“: Adresse prüfen, dann Server einrichten
/// (erster Administrator) oder anmelden.
Future<bool> showConnectDialog(BuildContext context, {bool loginOnly = false}) async =>
    await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _ConnectDialog(loginOnly: loginOnly)) ?? false;

class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog({this.loginOnly = false});
  final bool loginOnly;

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  late final session = AppScope.sessionOf(context);
  late final _url = TextEditingController(text: session.client?.baseUrl ?? '');
  final _user = TextEditingController();
  final _name = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  ServerStatus? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.loginOnly) WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await ServerClient(_url.text).status();
      setState(() => _status = s);
      if (s.needsSetup && _user.text.isEmpty) _user.text = 'admin';
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _go() async {
    final setup = _status!.needsSetup;
    if (setup && _pw.text != _pw2.text) {
      setState(() => _error = 'Die Passwörter stimmen nicht überein.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.loginOnly && session.client != null) {
        await session.login(_user.text, _pw.text);
      } else {
        await session.connect(url: _url.text, username: _user.text, password: _pw.text, displayName: _name.text.isEmpty ? null : _name.text, setup: setup);
      }
      if (mounted) Navigator.pop(context, true);
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final setup = s?.needsSetup ?? false;
    return AlertDialog(
      title: Text(widget.loginOnly ? 'Anmelden' : 'Mit Server verbinden'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('server-url'),
                  controller: _url,
                  autofocus: !widget.loginOnly,
                  enabled: !widget.loginOnly,
                  decoration: const InputDecoration(labelText: 'Serveradresse', hintText: 'z. B. 192.168.178.20:8080'),
                  onSubmitted: (_) => _check(),
                ),
              ),
              const SizedBox(width: 8),
              if (!widget.loginOnly) OutlinedButton(key: const Key('server-check'), onPressed: _busy ? null : _check, child: const Text('Prüfen')),
            ]),
            if (s != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, color: AppColors.ok, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('${s.name} (Version ${s.version}) erreichbar')),
              ]),
              const SizedBox(height: 12),
              if (setup)
                const Text('Der Server ist neu. Legt jetzt den ersten Administrator an. Die Daten dieses Geräts werden anschließend auf den Server übertragen.'),
              const SizedBox(height: 8),
              TextField(key: const Key('server-user'), controller: _user, autofocus: widget.loginOnly, decoration: const InputDecoration(labelText: 'Benutzername')),
              if (setup) ...[
                const SizedBox(height: 12),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Anzeigename', hintText: 'z. B. Felix Hahn')),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('server-password'),
                controller: _pw,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Passwort', helperText: setup ? 'mindestens 8 Zeichen' : null),
                onSubmitted: (_) => setup ? null : _go(),
              ),
              if (setup) ...[
                const SizedBox(height: 12),
                TextField(key: const Key('server-password2'), controller: _pw2, obscureText: true, decoration: const InputDecoration(labelText: 'Passwort wiederholen')),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (!widget.loginOnly) ...[
              const SizedBox(height: 16),
              Text('Von zu Hause: Server nur über VPN erreichbar machen (kein offener Port im Router).', style: Theme.of(context).textTheme.bodySmall),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        FilledButton(
          key: const Key('server-connect'),
          onPressed: _busy || s == null ? null : _go,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(setup ? 'Einrichten' : 'Anmelden'),
        ),
      ],
    );
  }
}

/// Anmeldeseite, wenn das Gerät mit einem Server verbunden, aber nicht (mehr)
/// angemeldet ist.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Übungsplaner', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Verbunden mit ${session.client?.baseUrl ?? ''}. ${session.message ?? 'Bitte anmelden.'}'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('login-open'),
                  onPressed: () => showConnectDialog(context, loginOnly: true),
                  icon: const Icon(Icons.login),
                  label: const Text('Anmelden'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => session.disconnect(),
                  child: const Text('Ohne Server weiterarbeiten (nur lokal)'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kurzer Status für die Seitenleiste.
class SyncStatusLine extends StatelessWidget {
  const SyncStatusLine({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.sessionOf(context);
    final c = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final (color, text) = switch (s.state) {
          SyncState.local => (AppColors.ok, 'Nur lokal · Daten auf diesem Gerät'),
          SyncState.syncing => (AppColors.yellow, 'Abgleich läuft …'),
          SyncState.idle => (AppColors.ok, '${s.lastSync == null ? 'Verbunden' : 'Abgeglichen ${_ago(s.lastSync!)}'} · ${s.user?.displayName ?? ''} (${s.roleLabel})'),
          SyncState.offline => (AppColors.warn, 'Server nicht erreichbar – Änderungen werden später übertragen'),
          SyncState.error => (c.error, 'Fehler beim Abgleich: ${s.message ?? ''}'),
          SyncState.loggedOut => (c.error, 'Abgemeldet'),
        };
        return InkWell(
          onTap: s.networked ? s.syncNow : null,
          child: Row(children: [
            Icon(Icons.circle, size: 9, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant))),
          ]),
        );
      },
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'gerade eben';
    if (d.inMinutes < 60) return 'vor ${d.inMinutes} Min.';
    return 'um ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

/// Einstellungen: Betriebsart und Benutzerverwaltung.
class ServerSettingsSection extends StatelessWidget {
  const ServerSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.sessionOf(context);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionCard(
          title: 'Betriebsart',
          child: !s.networked
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.computer),
                  title: const Text('Nur lokal'),
                  subtitle: const Text('Die Daten liegen nur auf diesem Gerät. Mit einem Übungsplaner-Server arbeiten mehrere Geräte gemeinsam.'),
                  trailing: FilledButton.icon(
                    key: const Key('server-open'),
                    onPressed: () async {
                      if (await showConnectDialog(context) && context.mounted) showMessage(context, 'Mit dem Server verbunden');
                    },
                    icon: const Icon(Icons.cloud_sync_outlined),
                    label: const Text('Mit Server verbinden'),
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.dns_outlined),
                    title: Text(s.client!.baseUrl),
                    subtitle: Text('Angemeldet als ${s.user?.displayName ?? '–'} (${s.roleLabel})'),
                  ),
                  const SyncStatusLine(),
                  if (s.lastRejected.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${s.lastRejected.length} Änderung(en) vom Server abgelehnt: ${s.lastRejected.map((r) => r['reason']).toSet().join(', ')}',
                        style: const TextStyle(color: AppColors.warn)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.tonalIcon(onPressed: s.syncNow, icon: const Icon(Icons.sync), label: const Text('Jetzt abgleichen')),
                    OutlinedButton.icon(onPressed: s.logout, icon: const Icon(Icons.logout), label: const Text('Abmelden')),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Verbindung trennen?'),
                            content: const Text('Das Gerät arbeitet danach nur noch lokal. Die Daten auf dem Gerät und auf dem Server bleiben erhalten.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Trennen')),
                            ],
                          ),
                        );
                        if (ok == true) await s.disconnect();
                      },
                      icon: const Icon(Icons.link_off),
                      label: const Text('Verbindung trennen'),
                    ),
                  ]),
                ]),
        ),
        if (s.networked && s.user?.role == 'admin') ...[const SizedBox(height: 16), const _UsersCard()],
      ]),
    );
  }
}

class _UsersCard extends StatefulWidget {
  const _UsersCard();

  @override
  State<_UsersCard> createState() => _UsersCardState();
}

class _UsersCardState extends State<_UsersCard> {
  late final session = AppScope.sessionOf(context);
  late Future<List<ServerUser>> _users = session.client!.users();

  void _reload() => setState(() => _users = session.client!.users());

  Future<void> _edit([ServerUser? u]) async {
    final username = TextEditingController(text: u?.username);
    final name = TextEditingController(text: u?.displayName);
    final pw = TextEditingController();
    var role = u?.role ?? 'planer';
    var active = u?.active ?? true;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(u == null ? 'Benutzer anlegen' : 'Benutzer bearbeiten'),
          content: SizedBox(
            width: 440,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: username, enabled: u == null, decoration: const InputDecoration(labelText: 'Benutzername')),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Anzeigename')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rolle'),
                items: [for (final e in roleLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pw,
                obscureText: true,
                decoration: InputDecoration(labelText: u == null ? 'Passwort' : 'Neues Passwort (leer = unverändert)', helperText: 'mindestens 8 Zeichen'),
              ),
              if (u != null)
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Aktiv'), value: active, onChanged: (v) => setS(() => active = v)),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                try {
                  if (u == null) {
                    await session.client!.createUser(username: username.text, displayName: name.text.isEmpty ? username.text : name.text, password: pw.text, role: role);
                  } else {
                    await session.client!.updateUser(u.id, displayName: name.text, role: role, active: active, password: pw.text.isEmpty ? null : pw.text);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ServerException catch (e) {
                  setS(() => error = e.message);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Benutzer & Rollen',
      subtitle: 'Admin: alles · TL/Wehrführer: Übungen freigeben · Planer: planen · Beobachter: nur lesen (z. B. Tablet)',
      actions: [FilledButton.tonalIcon(onPressed: _edit, icon: const Icon(Icons.person_add_alt), label: const Text('Benutzer'))],
      child: FutureBuilder<List<ServerUser>>(
        future: _users,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(snap.error is ServerException && (snap.error! as ServerException).status == 0
                ? 'Die Benutzerliste ist nur bei Verbindung zum Server verfügbar.'
                : '${snap.error}');
          }
          if (!snap.hasData) return const LinearProgressIndicator();
          return Column(children: [
            for (final u in snap.data!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(u.active ? Icons.person_outline : Icons.person_off_outlined),
                title: Text('${u.displayName} (${u.username})'),
                subtitle: Text('${roleLabels[u.role] ?? u.role}${u.active ? '' : ' · gesperrt'}'),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(u)),
              ),
          ]);
        },
      ),
    );
  }
}
