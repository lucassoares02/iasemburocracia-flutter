import 'package:portal_assoc/features/account/account_model.dart';
import 'package:portal_assoc/features/account/account_repository.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/models/business_address_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_repository.dart';

/// Snapshot derivado da realidade do backend.
class OnboardingSnapshot {
  final AccountModel? account;
  final CompaniesModel? company;
  final BusinessAddressModel? address;
  final List<MenuItemsModel> menuItems;

  final bool personalComplete;
  final bool companyComplete;
  final bool addressComplete;
  final bool menuComplete;

  const OnboardingSnapshot({
    required this.account,
    required this.company,
    required this.address,
    required this.menuItems,
    required this.personalComplete,
    required this.companyComplete,
    required this.addressComplete,
    required this.menuComplete,
  });

  factory OnboardingSnapshot.empty() => const OnboardingSnapshot(
        account: null,
        company: null,
        address: null,
        menuItems: [],
        personalComplete: false,
        companyComplete: false,
        addressComplete: false,
        menuComplete: false,
      );

  List<bool> get stepStates =>
      [personalComplete, companyComplete, addressComplete, menuComplete];

  int get totalSteps => stepStates.length;
  int get completedCount => stepStates.where((s) => s).length;
  bool get allComplete => stepStates.every((s) => s);

  /// Índice da primeira etapa incompleta; se todas completas, retorna [totalSteps].
  int get firstIncompleteIndex {
    final i = stepStates.indexWhere((s) => !s);
    return i == -1 ? totalSteps : i;
  }
}

/// Valida o progresso real do onboarding consultando a API.
class SetupValidationService {
  final _accountRepo = AccountRepository();
  final _companiesRepo = CompaniesRepository();
  final _menuItemsRepo = MenuItemsRepository();

  Future<OnboardingSnapshot> snapshot() async {
    final results = await Future.wait([
      _safeFetchAccount(),
      _safeFetchCompany(),
      _safeFetchAddress(),
      _safeFetchMenuItems(),
    ]);

    final account = results[0] as AccountModel?;
    final company = results[1] as CompaniesModel?;
    final address = results[2] as BusinessAddressModel?;
    final items = results[3] as List<MenuItemsModel>;

    return OnboardingSnapshot(
      account: account,
      company: company,
      address: address,
      menuItems: items,
      personalComplete: _isPersonalComplete(account),
      companyComplete: _isCompanyComplete(company),
      addressComplete: _isAddressComplete(address, company),
      menuComplete: items.isNotEmpty,
    );
  }

  // ─── Per-step rules ──────────────────────────────────────────────────────────

  bool _isPersonalComplete(AccountModel? a) {
    if (a == null) return false;
    final hasName = (a.name ?? '').trim().isNotEmpty;
    final hasPhone = (a.phone ?? '').trim().length >= 10;
    return hasName && hasPhone;
  }

  bool _isCompanyComplete(CompaniesModel? c) {
    if (c == null) return false;
    final hasName = (c.name ?? '').trim().isNotEmpty;
    final hasDesc = (c.description ?? '').trim().isNotEmpty;
    final hasLogo = (c.logoUrl ?? '').trim().isNotEmpty;
    return hasName && hasDesc && hasLogo;
  }

  bool _isAddressComplete(BusinessAddressModel? a, CompaniesModel? c) {
    if (a == null) return false;
    final hasStreet = (a.street ?? '').trim().isNotEmpty;
    final hasCity = (a.city ?? '').trim().isNotEmpty;
    final hasZip = (a.zipCode ?? '').trim().isNotEmpty;
    return hasStreet && hasCity && hasZip;
  }

  // ─── Safe fetchers ───────────────────────────────────────────────────────────

  Future<AccountModel?> _safeFetchAccount() async {
    try {
      final resp = await _accountRepo.find();
      if (!resp.success || resp.data == null) return null;
      return resp.data as AccountModel;
    } catch (_) {
      return null;
    }
  }

  Future<CompaniesModel?> _safeFetchCompany() async {
    try {
      final resp = await _companiesRepo.find();
      if (!resp.success || resp.data == null) return null;
      return resp.data as CompaniesModel;
    } catch (_) {
      return null;
    }
  }

  Future<BusinessAddressModel?> _safeFetchAddress() async {
    try {
      final resp = await _companiesRepo.findBusinessAddress();
      if (!resp.success || resp.data == null) return null;
      return resp.data as BusinessAddressModel;
    } catch (_) {
      return null;
    }
  }

  Future<List<MenuItemsModel>> _safeFetchMenuItems() async {
    try {
      final resp = await _menuItemsRepo.findAll();
      if (!resp.success || resp.data == null) return [];
      return (resp.data as List).cast<MenuItemsModel>();
    } catch (_) {
      return [];
    }
  }
}
