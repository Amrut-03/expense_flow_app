import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/group_usecases.dart';

String groupKindLabel(AppLocalizations l10n, GroupKind kind) => switch (kind) {
  GroupKind.household => l10n.groups_kindHousehold,
  GroupKind.roommates => l10n.groups_kindRoommates,
  GroupKind.trip => l10n.groups_kindTrip,
  GroupKind.other => l10n.groups_kindOther,
};

String groupFailureLabel(AppLocalizations l10n, GroupFailure f) => switch (f) {
  GroupFailure.notSignedIn => l10n.groups_signInNeeded,
  GroupFailure.inviteNotFound => l10n.groups_inviteNotFound,
  GroupFailure.inviteExpired => l10n.groups_inviteExpired,
  GroupFailure.groupFull => l10n.groups_full,
  GroupFailure.network => l10n.groups_network,
};

String groupExpenseErrorLabel(AppLocalizations l10n, GroupExpenseError e) =>
    switch (e) {
      GroupExpenseError.title => l10n.groups_errorTitle,
      GroupExpenseError.amount => l10n.addExpense_validAmount,
      GroupExpenseError.payer => l10n.groups_errorPayer,
      GroupExpenseError.shares => l10n.groups_errorShares,
    };
