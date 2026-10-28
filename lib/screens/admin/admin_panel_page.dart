import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../services/account_service.dart';
import '../../theme/app_format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_ui.dart';

/// In-app administration: approve and block users, per-user feature
/// switches, maintenance mode and app-wide features. Only admins see it,
/// and firestore.rules only accept these changes from admins.
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key, this.service});

  /// Replaceable for tests
  final AccountService? service;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accountService = service ?? AccountService();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.adminPanel),
          bottom: TabBar(
            tabs: [
              Tab(text: l.usersTab),
              Tab(text: l.appControlsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _UsersTab(service: accountService),
            _ControlsTab(service: accountService),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(AppLocalizations l, AccountStatus status) =>
    switch (status) {
      AccountStatus.pending => l.statusPending,
      AccountStatus.approved => l.statusApproved,
      AccountStatus.blocked => l.statusBlocked,
    };

Color _statusColor(BuildContext context, AccountStatus status) {
  final palette = AppPalette.of(context);
  return switch (status) {
    AccountStatus.pending => palette.warning,
    AccountStatus.approved => palette.income,
    AccountStatus.blocked => palette.expense,
  };
}

(String, String, IconData) _featureInfo(AppLocalizations l, AppFeature f) =>
    switch (f) {
      AppFeature.savings => (
          l.featureSavings,
          l.featureSavingsDesc,
          Icons.savings_rounded
        ),
      AppFeature.statement => (
          l.featureStatement,
          l.featureStatementDesc,
          Icons.picture_as_pdf_rounded
        ),
      AppFeature.cloudSync => (
          l.featureCloudSync,
          l.featureCloudSyncDesc,
          Icons.cloud_sync_rounded
        ),
    };

/// Runs an admin write. Firestore keeps it queued when offline, so a slow
/// confirmation is reported as "applies once online" rather than an error.
/// Returns false only if the write was rejected.
Future<bool> _save(BuildContext context, Future<void> Function() write,
    {String? successMessage}) async {
  final l = AppLocalizations.of(context);
  try {
    await write().timeout(const Duration(seconds: 8));
    if (context.mounted && successMessage != null) {
      showAppSnack(context, successMessage);
    }
    return true;
  } on TimeoutException {
    if (context.mounted) {
      showAppSnack(context, l.savedWhenOnline, type: AppSnackType.info);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      showAppSnack(context, '${l.error}: $e', type: AppSnackType.error);
    }
    return false;
  }
}

// ---------------------------------------------------------------- Users tab

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.service});

  final AccountService service;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  AccountStatus _status = AccountStatus.pending;
  final Map<AccountStatus, int> _counts = {};
  List<AppAccount> _items = [];
  DocumentSnapshot? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.listAccounts(_status),
        for (final status in AccountStatus.values) widget.service.count(status),
      ]);
      if (!mounted) return;
      final page = results.first as ({
        List<AppAccount> accounts,
        DocumentSnapshot? cursor
      });
      setState(() {
        _items = page.accounts;
        _cursor = page.cursor;
        for (var i = 0; i < AccountStatus.values.length; i++) {
          _counts[AccountStatus.values[i]] = results[i + 1] as int;
        }
        _loading = false;
      });
    } catch (e) {
      // e.g. the (status, createdAt) index is still missing: the message
      // contains the link that creates it
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.service.listAccounts(_status, after: cursor);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.accounts];
        _cursor = page.cursor;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _findByEmail() async {
    final l = AppLocalizations.of(context);
    final email = _search.text.trim();
    if (email.isEmpty) return;
    FocusScope.of(context).unfocus();
    final account = await widget.service.findByEmail(email);
    if (!mounted) return;
    if (account == null) {
      showAppSnack(context, l.userNotFound, type: AppSnackType.info);
    } else {
      _openUser(account);
    }
  }

  void _openUser(AppAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserSheet(
        account: account,
        service: widget.service,
        onChanged: _onAccountChanged,
      ),
    );
  }

  void _onAccountChanged(AppAccount before, AppAccount after) {
    setState(() {
      if (before.status != after.status) {
        _counts[before.status] = (_counts[before.status] ?? 1) - 1;
        _counts[after.status] = (_counts[after.status] ?? 0) + 1;
      }
      _items = [
        for (final item in _items)
          if (item.uid != after.uid)
            item
          else if (after.status == _status)
            after,
      ];
    });
  }

  Future<void> _approveAll() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l.approveAllTitle,
      message: l.userCount(_items.length),
      confirmLabel: l.approveAll,
      icon: Icons.done_all_rounded,
      destructive: false,
    );
    if (!confirmed || !mounted) return;
    final ids = _items.map((a) => a.uid).toList();
    final saved = await _save(context, () => widget.service.approveAll(ids),
        successMessage: l.userApproved);
    if (!saved || !mounted) return;
    setState(() {
      _counts[AccountStatus.pending] =
          (_counts[AccountStatus.pending] ?? ids.length) - ids.length;
      _counts[AccountStatus.approved] =
          (_counts[AccountStatus.approved] ?? 0) + ids.length;
      _items = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextField(
            controller: _search,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _findByEmail(),
            decoration: InputDecoration(
              hintText: l.searchByEmail,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: _findByEmail,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AccountStatus>(
              showSelectedIcon: false,
              segments: [
                for (final status in AccountStatus.values)
                  ButtonSegment(
                    value: status,
                    label: Text(
                      _counts[status] == null
                          ? _statusLabel(l, status)
                          : '${_statusLabel(l, status)} ${AppFormat.number(context, _counts[status]!)}',
                      maxLines: 1,
                    ),
                  ),
              ],
              selected: {_status},
              onSelectionChanged: (selection) {
                setState(() => _status = selection.first);
                _reload();
              },
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_error!),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            Card(
              child: EmptyState(
                compact: true,
                icon: Icons.people_outline_rounded,
                title: l.noUsersHere,
              ),
            )
          else ...[
            if (_status == AccountStatus.pending)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _approveAll,
                  style: TextButton.styleFrom(foregroundColor: palette.income),
                  icon: const Icon(Icons.done_all_rounded),
                  label: Text(l.approveAll),
                ),
              ),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0) const Divider(indent: 72),
                    _UserRow(
                      account: _items[i],
                      onTap: () => _openUser(_items[i]),
                    ),
                  ],
                ],
              ),
            ),
            if (_cursor != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: _loadMore,
                          child: Text(l.loadMore),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account, this.radius = 22});

  final AppAccount account;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name =
        account.displayName.isNotEmpty ? account.displayName : account.email;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage:
          account.photoUrl == null ? null : NetworkImage(account.photoUrl!),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.account, required this.onTap});

  final AppAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final created = account.createdAt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _AccountAvatar(account: account),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName.isNotEmpty
                        ? account.displayName
                        : account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (created != null)
                    Text(
                      '${l.joined} ${AppFormat.date(context, created)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- User sheet

enum _Override { inherit, on, off }

class _UserSheet extends StatefulWidget {
  const _UserSheet({
    required this.account,
    required this.service,
    required this.onChanged,
  });

  final AppAccount account;
  final AccountService service;
  final void Function(AppAccount before, AppAccount after) onChanged;

  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  late AppAccount _account = widget.account;
  bool _busy = false;

  Future<void> _setStatus(AccountStatus status, String message,
      {String? reason}) async {
    setState(() => _busy = true);
    final before = _account;
    final saved = await _save(
      context,
      () => widget.service.setStatus(_account.uid, status, reason: reason),
      successMessage: message,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!saved) return;
    final after = _account.copyWith(status: status, blockedReason: reason);
    widget.onChanged(before, after);
    Navigator.pop(context);
  }

  Future<void> _block() async {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon:
            IconBadge(icon: Icons.block_rounded, color: scheme.error, size: 52),
        title: Text(l.blockUserTitle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.blockUserMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.blockReasonHint),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.pop(
                      dialogContext, reasonController.text.trim()),
                  child: Text(l.block),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    await _setStatus(AccountStatus.blocked, l.userBlocked, reason: reason);
  }

  Future<void> _setFeature(AppFeature feature, _Override value) async {
    final enabled = switch (value) {
      _Override.inherit => null,
      _Override.on => true,
      _Override.off => false,
    };
    final before = _account;
    final features = {..._account.features}..remove(feature);
    if (enabled != null) features[feature] = enabled;
    // Shown at once; reverted if the write is rejected
    setState(() => _account = _account.copyWith(features: features));
    final saved = await _save(context,
        () => widget.service.setUserFeature(_account.uid, feature, enabled));
    if (!mounted) return;
    if (saved) {
      widget.onChanged(before, _account);
    } else {
      setState(() => _account = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    final config = Provider.of<AccountProvider>(context).config;
    final account = _account;
    final reason = account.blockedReason?.trim() ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _AccountAvatar(account: account, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName.isNotEmpty
                            ? account.displayName
                            : account.email,
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        account.email,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: _statusLabel(l, account.status),
                  color: _statusColor(context, account.status),
                ),
              ],
            ),
            if (account.createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '${l.joined} ${AppFormat.date(context, account.createdAt!)}',
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (account.status == AccountStatus.blocked &&
                reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${l.reasonLabel}: $reason',
                    style: textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 20),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (account.status != AccountStatus.approved)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.income,
                          foregroundColor: palette.onAccent,
                        ),
                        onPressed: () =>
                            _setStatus(AccountStatus.approved, l.userApproved),
                        icon: Icon(account.status == AccountStatus.blocked
                            ? Icons.lock_open_rounded
                            : Icons.check_rounded),
                        label: Text(account.status == AccountStatus.blocked
                            ? l.unblock
                            : l.approve),
                      ),
                    ),
                  if (account.status == AccountStatus.approved)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setStatus(
                            AccountStatus.pending, l.userMovedToPending),
                        child:
                            Text(l.moveToPending, textAlign: TextAlign.center),
                      ),
                    ),
                  if (account.status != AccountStatus.blocked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(
                              color: scheme.error.withValues(alpha: 0.5)),
                        ),
                        onPressed: _block,
                        icon: const Icon(Icons.block_rounded),
                        label: Text(l.block),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
            SectionHeader(l.features),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                l.userFeaturesHint,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            for (final feature in AppFeature.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeatureOverrideRow(
                  feature: feature,
                  value: switch (account.features[feature]) {
                    null => _Override.inherit,
                    true => _Override.on,
                    false => _Override.off,
                  },
                  appWide: config.isEnabled(feature),
                  onChanged: (value) => _setFeature(feature, value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureOverrideRow extends StatelessWidget {
  const _FeatureOverrideRow({
    required this.feature,
    required this.value,
    required this.appWide,
    required this.onChanged,
  });

  final AppFeature feature;
  final _Override value;
  final bool appWide;
  final ValueChanged<_Override> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (title, _, icon) = _featureInfo(l, feature);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: scheme.primary, size: 34),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Override>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _Override.inherit,
                  label: Text(
                      '${l.followAppSetting} (${appWide ? l.onLabel : l.offLabel})',
                      maxLines: 1),
                ),
                ButtonSegment(value: _Override.on, label: Text(l.onLabel)),
                ButtonSegment(value: _Override.off, label: Text(l.offLabel)),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Controls tab

class _ControlsTab extends StatefulWidget {
  const _ControlsTab({required this.service});

  final AccountService service;

  @override
  State<_ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<_ControlsTab>
    with AutomaticKeepAliveClientMixin {
  late final _message = TextEditingController(
    text: Provider.of<AccountProvider>(context, listen: false)
        .config
        .maintenanceMessage,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _setMaintenance(bool on) async {
    final l = AppLocalizations.of(context);
    if (on) {
      final confirmed = await showConfirmDialog(
        context,
        title: l.maintenanceOnTitle,
        message: l.maintenanceModeDesc,
        confirmLabel: l.onLabel,
        icon: Icons.construction_rounded,
      );
      if (!confirmed || !mounted) return;
    }
    await _save(
      context,
      () => widget.service.updateConfig({
        'maintenance': on,
        'maintenanceMessage': _message.text.trim(),
      }),
      successMessage: l.settingSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final config = Provider.of<AccountProvider>(context).config;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        SettingsGroup(
          title: l.maintenanceMode,
          children: [
            SettingsTile(
              icon: Icons.construction_rounded,
              iconColor: palette.warning,
              title: l.maintenanceMode,
              subtitle: l.maintenanceModeDesc,
              trailing: Switch(
                value: config.maintenance,
                onChanged: _setMaintenance,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _message,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l.maintenanceMessageLabel,
                      hintText: l.maintenanceDefaultMessage,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => _save(
                      context,
                      () => widget.service.updateConfig(
                          {'maintenanceMessage': _message.text.trim()}),
                      successMessage: l.settingSaved,
                    ),
                    child: Text(l.save),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: l.newUsers,
          children: [
            SettingsTile(
              icon: Icons.how_to_reg_rounded,
              iconColor: palette.income,
              title: l.requireApproval,
              subtitle: l.requireApprovalDesc,
              trailing: Switch(
                value: config.requireApproval,
                onChanged: (value) => _save(
                  context,
                  () => widget.service.updateConfig({'requireApproval': value}),
                  successMessage: l.settingSaved,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          title: l.featuresForEveryone,
          children: [
            for (final feature in AppFeature.values)
              Builder(builder: (context) {
                final (title, description, icon) = _featureInfo(l, feature);
                return SettingsTile(
                  icon: icon,
                  iconColor: scheme.primary,
                  title: title,
                  subtitle: description,
                  trailing: Switch(
                    value: config.isEnabled(feature),
                    onChanged: (value) => _save(
                      context,
                      () => widget.service.updateConfig({
                        'features': {feature.name: value},
                      }),
                      successMessage: l.settingSaved,
                    ),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}
