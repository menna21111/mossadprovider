import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';

class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.iban,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String iban;
  final bool isDefault;
  final DateTime? createdAt;

  BankAccount copyWith({
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? iban,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'iban': iban,
        'is_default': isDefault,
      };

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      accountHolderName: (json['account_holder_name'] ?? json['holder_name'])
              ?.toString() ??
          '',
      accountNumber: json['account_number']?.toString() ?? '',
      iban: json['iban']?.toString() ?? '',
      isDefault: json['is_default'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String get maskedIban {
    final clean = iban.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 8) return clean;
    final start = clean.substring(0, 3);
    final end = clean.substring(clean.length - 3);
    return '$start* **** **** *$end';
  }
}

class CreateBankAccountPayload {
  const CreateBankAccountPayload({
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.iban,
    this.isDefault = false,
  });

  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String iban;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'iban': iban,
        'is_default': isDefault,
      };
}

class BankAccountsRepository {
  static const saudiBanks = <String>[
    'مصرف الراجحي',
    'البنك الأهلي السعودي',
    'بنك الرياض',
    'بنك الإنماء',
    'البنك السعودي الفرنسي',
    'بنك ساب',
    'بنك البلاد',
    'بنك الجزيرة',
  ];

  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['results', 'data', 'items']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }

  Future<List<BankAccount>> getAccounts() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerBankAccounts,
      );
      return _parseList(response.data)
          .whereType<Map>()
          .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<BankAccount> getAccountDetail(String accountId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerBankAccountDetail(accountId),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return BankAccount.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<BankAccount> addAccount(CreateBankAccountPayload payload) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerBankAccounts,
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data.isEmpty) {
        return BankAccount(
          id: '',
          bankName: payload.bankName,
          accountHolderName: payload.accountHolderName,
          accountNumber: payload.accountNumber,
          iban: payload.iban,
          isDefault: payload.isDefault,
        );
      }
      return BankAccount.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<BankAccount> setDefault(String id) async {
    try {
      final response = await DioHelper.patchData(
        url: AppConstants.providerBankAccountDetail(id),
        data: {'is_default': true},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data.isNotEmpty) return BankAccount.fromJson(data);
      return getAccountDetail(id);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await DioHelper.deleteData(
        url: AppConstants.providerBankAccountDetail(id),
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
