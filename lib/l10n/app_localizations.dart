import 'package:flutter/material.dart';

import 'app_localizations_zh.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('ar'), Locale('zh')];

  String get appTitle;
  // ── «Ultimate Wallet» wallet ──────────────────────────────────────────────
  String get walletBalanceLabel;
  String get walletActionSend;
  String get walletActionReceive;
  String get walletActionTopUp;
  String get walletActionScan;
  String get walletServicesTitle;
  String get walletPayBills;
  String get walletTransferToBank;
  String get walletBeneficiaries;
  String get walletFavorites;
  String get walletRecentActivity;
  String get walletNoRecentActivity;
  String get walletReceiveTitle;
  String get walletReceiveShareHint;
  String get walletNumberLabel;
  String get walletRetry;
  String get walletMyWallets;
  String get walletQuickAccessTitle;
  String get walletPromotionsTitle;
  String get walletComingSoon;

  // ─── Home services: group titles, "coming soon" services & sheet ───
  String get svcGroupTransfers;
  String get svcGroupPayments;
  String get svcGroupRechargeBills;
  String get svcGroupWalletServices;
  String get svcGroupOther;
  String get svcSendToWallet;
  String get svcBetweenAccounts;
  String get svcMobileTopup;
  String get svcPurchases;
  String get svcExchange;
  String get svcInternetCards;
  String get svcCashWithdrawal;
  String get svcRewardsStore;
  String get svcServicePoints;
  String get comingSoonSheetMessage;
  String get svcPurchasesDesc;
  String get svcExchangeDesc;
  String get svcInternetCardsDesc;
  String get svcCashWithdrawalDesc;
  String get svcRewardsStoreDesc;
  String get svcServicePointsDesc;

  // ─── Home services (reorganised grid + grouped option sheets) ───
  String get svcMoneyTransfers;
  String get svcWithdrawFunds;
  String get svcRechargeAndPay;
  String get svcPurchasePayment;
  String get svcOtherBanksWallets;
  String get svcOtherBanksWalletsDesc;
  String get svcTransferToSubscriber;
  String get svcTransferToSubscriberDesc;
  String get svcPayBillsFull;
  String get svcPayBillsDesc;
  String get svcRechargeBalance;
  String get svcRechargeBalanceDesc;
  String get svcPayMerchant;
  String get svcPayMerchantDesc;
  String get svcScanToPay;
  String get svcScanToPayDesc;
  String get svcFavoriteMerchants;
  String get svcFavoriteMerchantsDesc;
  String get merchantNumberLabel;
  String get noteOptionalLabel;
  String get merchantPayContinue;
  String get favoriteMerchantsEmptyTitle;
  String get favoriteMerchantsEmpty;

  String get walletAddFavorite;
  String get walletServiceInternet;
  String get walletCurrencySar;
  String get walletCurrencyYer;
  String get walletCurrencyUsd;
  String get navHome;
  String get navTransfers;
  String get navPayments;
  String get navReports;

  // ─── Reports (transaction reports tab + filter sheet) ───
  String get reportsTitle;
  String get reportsTabAll;
  String get reportsTabSent;
  String get reportsTabReceived;
  String get reportsTabFees;
  String get reportsEmpty;
  String get reportsFilterTitle;
  String get reportsFilterCurrency;
  String get reportsFilterPhoneHint;
  String get reportsFilterOr;
  String get reportsFilterOperationType;
  String get reportsFilterFromDate;
  String get reportsFilterToDate;
  String get reportsFilterPurposeHint;
  String get reportsApply;
  String get reportsReset;
  String get reportsOpTransfer;
  String get reportsOpPayment;
  String get reportsOpDeposit;
  String get reportsOpWithdrawal;
  String get reportsExportComingSoon;

  String get navSettings;
  String get settingsTitle;
  String get appearance;
  String get theme;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get language;
  String get languageEnglish;
  String get languageArabic;
  String get languageChinese;
  String get security;
  String get sessionTimeout;
  String get sessionTimeoutSubtitle;
  String get sessionTimeoutUpdated;
  String sessionTimeoutMinutesLabel(int minutes);
  String get sessionExpiredMessage;
  String get reloginPasswordChangeRequired;
  String get reloginFailedGeneric;
  String get serverUnreachableMessage;
  String get biometricLogin;
  String get biometricLoginSubtitle;
  String get changePin;
  String get changePinSubtitle;
  String get forgotPin;
  String get forgotPinSubtitle;
  String get account;
  String get profile;
  String get profileSubtitle;
  String get copied;
  String get defaultAccountsTitle;
  String get defaultAccountsSubtitle;
  String get defaultAccountsSettingsSubtitle;
  String get defaultAccountsGlobal;
  String get defaultAccountsPerCurrency;
  String get saveDefaultAccounts;
  String get defaultAccountsSaved;
  String get saving;
  String get resetPassword;
  String get resetPasswordSubtitle;
  String get signOut;
  String get helpSupport;
  String get helpSupportSubtitle;
  String get termsAndConditions;
  String get termsAndConditionsSubtitle;
  String get termsAndConditionsFooter;
  String get supportTitle;
  String get supportNewCase;
  String get supportSubject;
  String get supportMessage;
  String get supportSubmit;
  String get supportNoCases;
  String get supportReply;
  String get supportSend;
  String get supportCaseNumber;
  String get needHelp;
  String get trackExistingCase;
  String get guestName;
  String get guestMobile;
  String get supportCreatedTitle;
  String supportCreatedBody(String caseNumber);
  String get supportQueued;
  String supportAssignedTo(String name);
  String get supportWaitingForYou;
  String get supportSeen;
  String get supportDelivered;
  String get enterTransactionPin;
  String get pinRequiredEnableBiometric;
  String get pinRequiredDisableBiometric;
  String get biometricEnabled;
  String get biometricSetupCancelled;
  String get biometricDisabled;
  String get transferToMyAccounts;
  String get transferToOthers;
  String get addAccount;
  String get addAccountDesc;
  String get betweenYourAccounts;
  String get betweenYourAccountsSubtitle;
  String get toAnotherAccount;
  String get toAnotherAccountSubtitle;
  String get debitAccount;
  String get creditAccount;
  String get beneficiaryAccount;
  String get amount;
  String get transferMax;
  String get reviewTransfer;
  String get dealRate;
  String get youSend;
  String get recipientGets;
  String get fetchingRate;
  String get scanQr;
  String get noAccountsForTransfer;
  String get needTwoAccounts;
  String get chooseAccountsAndAmount;
  String get chooseDebitBeneficiaryAmount;
  String get fromLabel;
  String get toLabel;
  String get confirmTransfer;
  String get validationDetails;
  String get editDetails;
  String get authorizeTransfer;
  String get enterPinToComplete;
  String get transferComplete;
  String get saveReferenceHint;
  String get reference;
  String get referenceCopied;
  String get copyReference;
  String get newTransfer;
  String get customerIdMissing;
  String get noAccountsFound;
  String get allAccounts;
  String get searchAccounts;
  String get noMatchingAccounts;
  String get hideZeroBalances;
  String accountsCount(int count);
  String get yourCards;
  String get viewAll;
  String get recentTransactions;
  String get recentTransfers;
  String get transferAgain;
  String get noRecentTransfers;
  String get favoritesLabel;
  String get removeFavorite;
  String get favoritesEmpty;
  String get transferOthersSubtitle;
  String get addAccountSubtitle;
  String get cancel;
  String get quickSend;
  String get quickRequest;
  String get quickQr;
  String get quickHistory;
  String get featureComingSoonTitle;
  String get featureComingSoonMessage;
  String get debitCard;
  String get creditCard;
  String get details;
  String get scanToPay;
  String get shareQrForTransfers;
  String get accountNumberCopied;
  String get statusPending;
  String get statusCompleted;
  String get txnRetailPurchase;
  String get txnIncomingTransfer;
  String get txnPosPayment;
  String get txnToday;
  String get txnYesterday;
  String get txnMar12;
  String get noTransactionsForAccount;
  String transactionsShowingCount(int shown, int total);
  String accountsPageIndicator(int current, int total);
  String get transactionHistory;
  String get accountStatement;
  String get searchTransactions;
  String get filterAll;
  String get filterIncoming;
  String get filterOutgoing;
  String get noMatchingTransactions;
  String transactionsCount(int count);

  // Pre-login / auth flows
  String get secureMobileBanking;
  String get welcomeBack;
  String get signInWithUsernamePassword;
  String get username;
  String get usernameHint;
  String get enterUsername;
  String get password;
  String get enterPassword;
  String get signInAfterPasswordResetBanner;
  String get signIn;
  String get opening;
  String get signInWithBiometrics;
  String get forgotPassword;
  String get newCustomerRegister;
  // Jaib-style login screen
  String get loginTabCustomer;
  String get loginTabMerchant;
  String get mobileNumberHint;
  String get enterMobileNumber;
  String get signInAsCustomer;
  String get dontHaveAccount;
  String get createAccount;
  String get supportTollFree;
  String get supportServicePoints;
  String get supportCustomerService;
  String get merchantLoginComingSoon;
  String get biometricSignIn;
  String get biometricSignInSubtitle;
  String get confirmYourIdentity;
  String get biometricPromptMessage;
  String get pleaseWait;
  String get unlock;
  String get usePasswordInstead;
  String get biometricVerificationFailed;
  String get enableBiometricLoginTitle;
  String get enableBiometricLoginSubtitle;
  String get biometricEnrollPinSubtitle;
  String get skipForNow;
  String get biometricLoginEnabledMessage;
  String get biometricSetupUnavailable;
  String get enterYourPin;
  String get registerTitle;
  String get createYourAccount;
  String get registrationSubtitle;
  String get coreCustomerId;
  String get coreCustomerIdHint;
  String get enterCoreCustomerId;
  String get fetchProfile;
  String get fullName;
  String get mobile;
  String get gender;
  String get dateOfBirth;
  String get mobileLoginUsername;
  String get coreCustomerIdOption;
  String get customUsername;
  String get customUsernameHint;
  String get customUsernameRules;
  String get changeId;
  String get registerButton;
  String get enterCustomUsername;
  String get registrationUsernameMissing;
  String get alreadyHaveAccountSignIn;
  String get registerWelcomeTitle;
  String get registerWelcomeSubtitle;
  String get registerNameAsIdHint;
  String get firstName;
  String get secondName;
  String get thirdName;
  String get surname;
  String get genderMale;
  String get genderFemale;
  String get agreeToTerms;
  String get createAccountButton;
  String get customerService;
  String get servicePoints;
  String get tollFreeNumber;
  String get mustAgreeToTerms;
  String get requiredField;
  String get activationTitle;
  String activationSubtitle(String mobile);
  String get activationExpiresIn;
  String get didntReceiveCode;
  String get contactCustomerService;
  String get activationConfirm;
  String get kycBannerText;
  String get kycVerifyAccount;
  String get kycTitle;
  String get kycSubtitle;
  String get kycIdFront;
  String get kycIdBack;
  String get kycSelfie;
  String get kycUploadHint;
  String get kycCamera;
  String get kycGallery;
  String get kycSubmit;
  String get kycSubmitted;
  // ── KYC status ─────────────────────────────────────────────────────────
  String get kycStatusUnverifiedTitle;
  String get kycStatusUnverifiedDesc;
  String get kycStatusIncompleteTitle;
  String get kycStatusIncompleteDesc;
  String get kycStatusPendingTitle;
  String get kycStatusPendingDesc;
  String get kycStatusVerifiedTitle;
  String get kycStatusVerifiedDesc;
  String get kycStatusRejectedTitle;
  String get kycStatusRejectedDesc;
  // ── KYC capture flow ───────────────────────────────────────────────────
  String kycStepProgress(int current, int total);
  String get kycChooseSource;
  String get kycRetake;
  String get kycUsePhoto;
  String get kycPreviewTitle;
  String get kycPreviewHint;
  String get kycIdFrontGuide;
  String get kycIdBackGuide;
  String get kycSelfieGuide;
  String get kycUploaded;
  String get kycUploading;
  String get kycDocsIntro;
  String get kycAllReadyHint;
  // ── KYC identity type + custom camera ──────────────────────────────────
  String get kycIdType;
  String get kycIdTypeNationalId;
  String get kycIdTypePassport;
  String get kycPassport;
  String get kycPassportGuide;
  String get kycCameraLightingHint;
  String get kycProcessing;
  String get kycCameraUnavailable;
  String get kycCameraUnavailableBody;
  // ── KYC permissions & errors ───────────────────────────────────────────
  String get kycCameraPermissionTitle;
  String get kycCameraPermissionBody;
  String get kycOpenSettings;
  String get kycUploadFailed;
  String get kycSubmitFailed;
  String get kycServiceUnavailable;
  String get kycRetry;
  String get kycCancel;
  // ── KYC result states ──────────────────────────────────────────────────
  String get kycPendingHeadline;
  String get kycPendingBody;
  String get kycVerifiedHeadline;
  String get kycVerifiedBody;
  String get kycRejectedHeadline;
  String get kycRejectionReasonLabel;
  String get kycResubmit;
  String get kycBackToHome;
  // ── KYC banner variants ────────────────────────────────────────────────
  String get kycBannerPendingText;
  String get kycBannerRejectedText;
  // ── KYC data-entry form (account confirmation) ─────────────────────────
  String get kycDataIntro;
  String get kycSectionIdentity;

  String get kycSectionPersonal;

  String get kycIdentityLocked;
  String get kycSectionResidence;
  String get kycFieldIdNumber;
  String get kycFieldPassportNumber;
  String get kycFieldIssuingAuthority;
  String get kycFieldIssueDate;
  String get kycFieldExpiryDate;
  String get kycFieldPlaceOfBirth;
  String get kycFieldDateOfBirth;
  String get kycFieldCountry;
  String get kycFieldCity;
  String get kycFieldDistrict;
  String get kycFieldRegion;
  String get kycFieldAddress;
  String get kycFieldSelectDate;
  String get kycFieldRequired;
  String get kycFieldExpiryBeforeIssue;
  String get kycContinue;
  String get kycFinalStepTitle;
  String get kycFinalStepSubtitle;
  String get kycConfirmAccount;
  String get kycBack;
  // ── Profile verification ───────────────────────────────────────────────
  String get profileVerified;
  String get profileVerificationStatus;
  String get profileCompleteVerification;
  String get forgotPasswordTitle;
  String get resetPasswordHeading;
  String get resetPasswordDescription;
  String get mobileNumber;
  String get enterRegisteredMobile;
  String get resetPasswordSuccess;
  String get requestReset;
  String get backToSignIn;
  String get setPasswordTitle;
  String get createYourPassword;
  String get setPasswordSubtitle;
  String usernameLabel(String username);
  String get newPassword;
  String get passwordLengthHint;
  String get atLeast8Characters;
  String get confirmPassword;
  String get passwordsDoNotMatch;
  String get passwordNotAccepted;
  String get saveAndContinue;
  String get transactionPinTitle;
  String get transactionPinSubtitle;
  String get confirmYourPin;
  String get createYourPin;
  String get confirmPinSubtitle;
  String get choosePinSubtitle;
  String get pinsDoNotMatch;
  String get continueLabel;

  // New UI
  String get totalBalance;
  String get clickToAccess;
  String get viewFinancialStatus;
  String get newAccount;
  String get navExplore;
  String get yourPoints;

  // Screen A Circular buttons
  String get actionMedical;
  String get actionDonate;
  String get actionAlert;
  String get actionApple;
  String get actionNewCard;

  // Screen B Services
  String get serviceTransfer;
  String get serviceAccounts;
  String get serviceCards;
  String get serviceBills;
  String get serviceOffers;
  String get serviceFinance;

  // Home dashboard: quick services pill row
  String get quickSendRemittance;
  String get quickUnifiedNetwork;

  // Beneficiaries
  String get beneficiaries;
  String get addBeneficiary;
  String get beneficiaryName;
  String get beneficiaryAccountOrIban;
  String get beneficiaryNickname;
  String get validateAccount;
  String get beneficiaryAddedSuccessfully;
  String get emptyBeneficiaries;
  String get deleteBeneficiary;
  String get beneficiaryDeleted;
  String get confirmDeleteBeneficiary;
  String get transferToBeneficiary;
  String get editBeneficiary;
  String get editBeneficiarySubtitle;
  String get beneficiaryUpdatedSuccessfully;
  String get saveChanges;
  String get noChangesDetected;
  String get verifyNewAccount;

  // Newly added localizations (68 keys)
  String get methodAccount;
  String get methodMobile;
  String get methodIban;
  String get hintEnterAccount;
  String get hintEnterMobile;
  String get hintEnterIban;
  String get validationEnterValue;
  String get localTransferSubtitle;
  String get verifyAccount;
  String get addBeneficiaryBy;
  String get verifiedSecurelyNote;
  String get change;
  String get accountVerified;
  String get accountHolder;
  String get nicknameOptional;
  String get nicknameExample;
  String get currencyLabel;
  String get categoryElectricity;
  String get categoryWater;
  String get categoryTelecom;
  String get categoryGovernment;
  String get categoryMobile;
  String get categoryTraffic;
  String get categoryEducation;
  String get categoryViewAll;
  String get payBills;
  String get searchBillersHint;
  String get categories;
  String get dueThisWeek;
  String get electricityPec;
  String get due24Jun;
  String get telecomYemenMobile;
  String get due27Jun;
  String get paymentHistory;
  String get historyPecSubtitle;
  String get historyWaterTitle;
  String get historyWaterSubtitle;
  String get payButton;
  String get paidStatus;
  String get comingSoonToast;
  String get serviceStandingOrders;
  String get serviceSendGift;
  String get serviceCharity;
  String get serviceTransferSettings;
  String get serviceInvestmentWallet;
  String get btnNewBeneficiary;
  String get servicesLabel;
  String get recentTransfersLabel;
  String get chooseDebitAccount;
  String get chooseCreditAccount;
  String get hintBeneficiaryAccountOrIban;
  String get exclusiveOffers;
  String get cashBackTitle;
  String get cashBackSubtitle;
  String get travelDiscountTitle;
  String get travelDiscountSubtitle;
  String get financeCalculatorTitle;
  String get financeCalculatorSubtitle;
  String get financeDisclaimer;
  String get closeButton;
  String get saudiRiyal;
  String get enableFingerprintTitle;
  String get enableFingerprintMessage;
  String get okButton;
  String get verifyingStatus;
  String get biometricFailed;
  String get enterRegisteredMobileHint;
  String get enterCustomerIdHint;

  // Notifications
  String get notificationsTitle;
  String get notificationSettingsTitle;
  String get notificationsAllow;
  String get notificationsTransfers;
  String get notificationsGeneral;
  String get notificationsSecurityAlerts;
  String get notificationsComingSoon;
  String get securityBlockedTitle;
  String get securityBlockedMessage;
  String get securityRestrictedTitle;
  String get securityRestrictedMessage;
  String get myCards;
  String get cardDetails;
  String get cardStatusActive;
  String get cardStatusFrozen;
  String get freezeCard;
  String get unfreezeCard;
  String get freezeCardConfirmTitle;
  String get freezeCardConfirmMessage;
  String get cardFrozenBanner;
  String get cardFrozenToast;
  String get cardUnfrozenToast;
  String get cardSettings;
  String get onlinePayments;
  String get onlinePaymentsSubtitle;
  String get contactlessPayments;
  String get contactlessPaymentsSubtitle;
  String get cardLimits;
  String get dailyPurchaseLimit;
  String get atmWithdrawalLimit;
  String get limitUpdated;
  String get linkedAccount;
  String get noCardTransactions;

  // ─── Bill payments (Section 7) ───
  String get serviceProviders;
  String get noProvidersFound;
  String get subscriberNumberLabel;
  String get phoneNumberLabel;
  String get billAccountNoLabel;
  String get invalidSubscriberNumber;
  String get inquireBill;
  String get billDetails;
  String get subscriberNameLabel;
  String get balanceDueLabel;
  String get availableCreditLabel;
  String get lineTypeLabel;
  String get expiresLabel;
  String get minAmountLabel;
  String get offersAndPackages;
  String get chooseOffer;
  String get offersEmpty;
  String get payAmountLabel;
  String get debitAccountLabel;
  String get chooseAccount;
  String get reviewPayment;
  String get confirmWithPin;
  String get payNow;
  String get telecomPaymentTitle;
  String get payServicesSheetTitle;
  String get serviceTypeLabel;
  String get packageTypeLabel;
  String get fromAccountLabel;
  String get executeOperation;
  String get balanceInquiry;
  String get landlinePaymentTitle;
  String get internetPaymentTitle;
  String get categoryLandline;
  String get enterPhoneForServices;
  String get paymentSuccessful;
  String get paymentPendingTitle;
  String get paymentPendingBody;
  String get paymentFailed;
  String get referenceNumberLabel;
  String get providerReferenceLabel;
  String get checkStatus;
  String get shareBillReceipt;
  String get billPaymentHistoryEmpty;
  String get statusFailed;
  String get unMoneyTitle;
  String get networkTransfersTitle;
  String get unMoneySend;
  String get unMoneySendSubtitle;
  String get unMoneyReceive;
  String get unMoneyReceiveSubtitle;
  String get unMoneyHistory;
  String get unMoneyRecipientLabel;
  String get unMoneyPickupCode;
  String get unMoneyLookup;
  String get unMoneyReceiveConfirm;
  String get unifiedNetworkCancelTile;
  String get unifiedNetworkSendTile;
  String get unifiedNetworkPayTile;
  String get unifiedNetworkSendTitle;
  String get unifiedNetworkPayTitle;
  String get unifiedNetworkCancelTitle;
  String get tabTransferToBeneficiary;
  String get tabSendUnifiedNetwork;
  String get beneficiaryNameLabel;
  String get beneficiaryNumberLabel;
  String get transferPurposeLabel;
  String get purposePersonal;
  String get purposeWork;
  String get transferNotesWarning;
  String get transferNotesHint;
  String get depositAccountLabel;
  String get referenceNumberHint;
  String get depositNoteLine1;
  String get depositNoteLine2;
  String get transferNumberHint;
  String get confirmLabel;
  String get categoryInternet;
  String get categoryMoneyTransfer;
  String get categoryEntertainment;
}

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appTitle => 'Ultimate Wallet';

  // ── «Ultimate Wallet» wallet ──────────────────────────────────────────────
  @override
  String get walletBalanceLabel => 'Wallet balance';
  @override
  String get walletActionSend => 'Send';
  @override
  String get walletActionReceive => 'Receive';
  @override
  String get walletActionTopUp => 'Top up';
  @override
  String get walletActionScan => 'Scan';
  @override
  String get walletServicesTitle => 'Services';
  @override
  String get walletPayBills => 'Bills';
  @override
  String get walletTransferToBank => 'To bank';
  @override
  String get walletBeneficiaries => 'Beneficiaries';
  @override
  String get walletFavorites => 'Favorites';
  @override
  String get walletRecentActivity => 'Recent activity';
  @override
  String get walletNoRecentActivity => 'No transactions yet';
  @override
  String get walletReceiveTitle => 'Receive money';
  @override
  String get walletReceiveShareHint =>
      'Share this code to receive money into your wallet';
  @override
  String get walletNumberLabel => 'Wallet number';
  @override
  String get walletRetry => 'Retry';
  @override
  String get walletMyWallets => 'My wallets';
  @override
  String get walletQuickAccessTitle => 'Quick access';
  @override
  String get walletPromotionsTitle => 'Offers for you';
  @override
  String get walletComingSoon => 'Soon';

  @override
  String get svcGroupTransfers => 'Transfers';
  @override
  String get svcGroupPayments => 'Payments';
  @override
  String get svcGroupRechargeBills => 'Recharge & Bills';
  @override
  String get svcGroupWalletServices => 'Wallet Services';
  @override
  String get svcGroupOther => 'Other Financial Services';
  @override
  String get svcSendToWallet => 'Send to Wallet';
  @override
  String get svcBetweenAccounts => 'Between My Accounts';
  @override
  String get svcMobileTopup => 'Mobile Top-up';
  @override
  String get svcPurchases => 'Purchases';
  @override
  String get svcExchange => 'Currency Exchange';
  @override
  String get svcInternetCards => 'Internet Cards';
  @override
  String get svcCashWithdrawal => 'Cash Withdrawal';
  @override
  String get svcRewardsStore => 'Rewards Store';
  @override
  String get svcServicePoints => 'Agents & Service Points';
  @override
  String get comingSoonSheetMessage => 'This service will be available soon.';
  @override
  String get svcPurchasesDesc =>
      'Shop and pay for your purchases directly from your wallet.';
  @override
  String get svcExchangeDesc =>
      'Convert between currencies at live rates inside the app.';
  @override
  String get svcInternetCardsDesc => 'Buy prepaid internet cards instantly.';
  @override
  String get svcCashWithdrawalDesc =>
      'Withdraw cash from approved service points and agents.';
  @override
  String get svcRewardsStoreDesc =>
      'Redeem your points for rewards and exclusive offers.';
  @override
  String get svcServicePointsDesc =>
      'Find the nearest agent or service point on the map.';

  @override
  String get svcMoneyTransfers => 'Money Transfers';
  @override
  String get svcWithdrawFunds => 'Cash Withdrawal';
  @override
  String get svcRechargeAndPay => 'Recharge & Pay';
  @override
  String get svcPurchasePayment => 'Pay for Purchases';
  @override
  String get svcOtherBanksWallets => 'Banks & Wallets';
  @override
  String get svcOtherBanksWalletsDesc =>
      'Transfer to other banks and wallets — coming soon.';
  @override
  String get svcTransferToSubscriber => 'Transfer to Subscriber';
  @override
  String get svcTransferToSubscriberDesc =>
      'Send money instantly to another wallet subscriber.';
  @override
  String get svcPayBillsFull => 'Pay Bills';
  @override
  String get svcPayBillsDesc =>
      'Settle utility, telecom and government bills.';
  @override
  String get svcRechargeBalance => 'Recharge Balance';
  @override
  String get svcRechargeBalanceDesc => 'Top up mobile credit and data bundles.';
  @override
  String get svcPayMerchant => 'Pay a Merchant';
  @override
  String get svcPayMerchantDesc =>
      'Pay an approved merchant from your wallet.';
  @override
  String get svcScanToPay => 'Scan QR / Barcode';
  @override
  String get svcScanToPayDesc => 'Scan a payment code to complete a purchase.';
  @override
  String get svcFavoriteMerchants => 'Favorite Merchants';
  @override
  String get svcFavoriteMerchantsDesc =>
      'Pay your favorite merchants in one tap.';
  @override
  String get merchantNumberLabel => 'Merchant or wallet number';
  @override
  String get noteOptionalLabel => 'Note (optional)';
  @override
  String get merchantPayContinue => 'Continue payment';
  @override
  String get favoriteMerchantsEmptyTitle => 'No favorite merchants yet';
  @override
  String get favoriteMerchantsEmpty =>
      'Add merchants you pay often for faster payments next time.';

  @override
  String get walletAddFavorite => 'Add favorite';
  @override
  String get walletServiceInternet => 'Internet';
  @override
  String get walletCurrencySar => 'Saudi Riyal';
  @override
  String get walletCurrencyYer => 'Yemeni Rial';
  @override
  String get walletCurrencyUsd => 'US Dollar';

  @override
  String get navHome => 'Home';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navPayments => 'Payments';

  @override
  String get navReports => 'Reports';

  @override
  String get reportsTitle => 'Reports';
  @override
  String get reportsTabAll => 'All';
  @override
  String get reportsTabSent => 'Sent';
  @override
  String get reportsTabReceived => 'Received';
  @override
  String get reportsTabFees => 'Fees';
  @override
  String get reportsEmpty => 'No items';
  @override
  String get reportsFilterTitle => 'Filter reports';
  @override
  String get reportsFilterCurrency => 'Currency';
  @override
  String get reportsFilterPhoneHint => 'Phone';
  @override
  String get reportsFilterOr => 'or';
  @override
  String get reportsFilterOperationType => 'Operation type';
  @override
  String get reportsFilterFromDate => 'From date';
  @override
  String get reportsFilterToDate => 'To date';
  @override
  String get reportsFilterPurposeHint => 'Purpose';
  @override
  String get reportsApply => 'Confirm';
  @override
  String get reportsReset => 'Reset';
  @override
  String get reportsOpTransfer => 'Transfer';
  @override
  String get reportsOpPayment => 'Payment';
  @override
  String get reportsOpDeposit => 'Deposit';
  @override
  String get reportsOpWithdrawal => 'Withdrawal';
  @override
  String get reportsExportComingSoon => 'Export will be available soon';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageChinese => '中文';

  @override
  String get security => 'Security';

  @override
  String get sessionTimeout => 'Session timeout';

  @override
  String get sessionTimeoutSubtitle =>
      'Sign out automatically after inactivity';

  @override
  String get sessionTimeoutUpdated => 'Session timeout updated';

  @override
  String sessionTimeoutMinutesLabel(int minutes) =>
      minutes == 1 ? '1 minute' : '$minutes minutes';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please sign in again.';

  @override
  String get reloginPasswordChangeRequired =>
      'Your password is temporary and must be changed. Tap Cancel, then sign in from the login screen to set a new password.';

  @override
  String get reloginFailedGeneric => 'Sign-in failed. Please try again.';

  @override
  String get serverUnreachableMessage =>
      'Cannot reach the server right now. Check your connection, then pull down to retry.';

  @override
  String get biometricLogin => 'Biometric login';

  @override
  String get biometricLoginSubtitle => 'Sign in with fingerprint or face';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinSubtitle => 'Update your transaction PIN';

  @override
  String get forgotPin => 'Forgot PIN';

  @override
  String get forgotPinSubtitle => 'Reset PIN using your sign-in password';

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get profileSubtitle => 'View your personal details';

  @override
  String get copied => 'Copied';

  @override
  String get defaultAccountsTitle => 'Default accounts';

  @override
  String get defaultAccountsSubtitle =>
      'Choose your primary account and one default per currency.';

  @override
  String get defaultAccountsSettingsSubtitle =>
      'Primary and per-currency defaults';

  @override
  String get defaultAccountsGlobal => 'Primary account (all currencies)';

  @override
  String get defaultAccountsPerCurrency => 'Default per currency';

  @override
  String get saveDefaultAccounts => 'Save default accounts';

  @override
  String get defaultAccountsSaved => 'Default accounts saved';

  @override
  String get saving => 'Saving…';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordSubtitle => 'Reset password via registered mobile';

  @override
  String get signOut => 'Sign out';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get helpSupportSubtitle => 'Contact customer service';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get termsAndConditionsSubtitle => 'E-money wallet account policy';

  @override
  String get termsAndConditionsFooter =>
      'This document is provided for reference. Please refer to the officially approved version.';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportNewCase => 'New case';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportMessage => 'Message';

  @override
  String get supportSubmit => 'Submit';

  @override
  String get supportNoCases => 'No support cases yet.';

  @override
  String get supportReply => 'Reply';

  @override
  String get supportSend => 'Send';

  @override
  String get supportCaseNumber => 'Case number';

  @override
  String get needHelp => 'Need help?';

  @override
  String get trackExistingCase => 'Track existing case';

  @override
  String get guestName => 'Your name';

  @override
  String get guestMobile => 'Mobile number';

  @override
  String get supportCreatedTitle => 'Case submitted';

  @override
  String supportCreatedBody(String caseNumber) =>
      'Your case $caseNumber was created. Save this number to check replies.';

  @override
  String get supportQueued => 'Waiting in queue — not assigned yet';

  @override
  String supportAssignedTo(String name) => 'Assigned to $name';

  @override
  String get supportWaitingForYou => 'Waiting for your reply';

  @override
  String get supportSeen => 'Seen';

  @override
  String get supportDelivered => 'Delivered';

  @override
  String get enterTransactionPin => 'Enter transaction PIN';

  @override
  String get pinRequiredEnableBiometric => 'Required to enable biometric login';

  @override
  String get pinRequiredDisableBiometric =>
      'Required to disable biometric login';

  @override
  String get biometricEnabled => 'Biometric login enabled';

  @override
  String get biometricSetupCancelled => 'Biometric setup was cancelled';

  @override
  String get biometricDisabled => 'Biometric login disabled';

  @override
  String get transferToMyAccounts => 'To My Accounts';

  @override
  String get transferToOthers => 'To Others';

  @override
  String get addAccount => 'Add account';

  @override
  String get addAccountDesc =>
      'Open an additional account in another currency or type — coming soon.';

  @override
  String get betweenYourAccounts => 'Between your accounts';

  @override
  String get betweenYourAccountsSubtitle =>
      'Move funds between your own accounts';

  @override
  String get toAnotherAccount => 'To another account';

  @override
  String get toAnotherAccountSubtitle => 'Send to an external beneficiary';

  @override
  String get debitAccount => 'Debit account';

  @override
  String get creditAccount => 'Credit account';

  @override
  String get beneficiaryAccount => 'Beneficiary account';

  @override
  String get amount => 'Amount';

  @override
  String get transferMax => 'Transfer max';

  @override
  String get reviewTransfer => 'Review transfer';

  @override
  String get dealRate => 'Deal rate';

  @override
  String get youSend => 'You send';

  @override
  String get recipientGets => 'Recipient gets';

  @override
  String get fetchingRate => 'Fetching exchange rate…';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get noAccountsForTransfer => 'No accounts available for transfer.';

  @override
  String get needTwoAccounts =>
      'You need at least two accounts to transfer between your own accounts.';

  @override
  String get chooseAccountsAndAmount =>
      'Choose debit and credit accounts and enter amount';

  @override
  String get chooseDebitBeneficiaryAmount =>
      'Choose debit account, beneficiary account, and amount';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get confirmTransfer => 'Confirm transfer';

  @override
  String get validationDetails => 'Validation details';

  @override
  String get editDetails => 'Edit details';

  @override
  String get authorizeTransfer => 'Authorize transfer';

  @override
  String get enterPinToComplete => 'Enter your transaction PIN to complete';

  @override
  String get transferComplete => 'Transfer complete';

  @override
  String get saveReferenceHint => 'Save this reference for your records';

  @override
  String get reference => 'Reference';

  @override
  String get referenceCopied => 'Reference copied';

  @override
  String get copyReference => 'Copy reference';

  @override
  String get newTransfer => 'New transfer';

  @override
  String get customerIdMissing => 'Customer ID missing on profile.';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get searchAccounts => 'Search accounts';

  @override
  String get noMatchingAccounts => 'No matching accounts.';

  @override
  String get hideZeroBalances => 'Hide zero';

  @override
  String accountsCount(int count) => '$count accounts';

  @override
  String get yourCards => 'Your Cards';

  @override
  String get viewAll => 'View All';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get recentTransfers => 'Recent transfers';

  @override
  String get transferAgain => 'Transfer again';

  @override
  String get noRecentTransfers => 'No recent transfers yet.';

  @override
  String get favoritesLabel => 'Favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get favoritesEmpty =>
      'No favorites yet. Star a transfer target to see it here.';

  @override
  String get transferOthersSubtitle =>
      'Send to another customer or beneficiary';

  @override
  String get addAccountSubtitle => 'Open a new current or savings account';

  @override
  String get cancel => 'Cancel';

  @override
  String get quickSend => 'Send';

  @override
  String get quickRequest => 'Request';

  @override
  String get quickQr => 'QR';

  @override
  String get quickHistory => 'History';

  @override
  String get featureComingSoonTitle => 'Coming soon';

  @override
  String get featureComingSoonMessage => 'These features are coming soon.';

  @override
  String get debitCard => 'Debit Card';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get details => 'Details';

  @override
  String get scanToPay => 'Scan to pay';

  @override
  String get shareQrForTransfers =>
      'Share this QR for transfers to this account';

  @override
  String get accountNumberCopied => 'Account number copied';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get txnRetailPurchase => 'Retail purchase';

  @override
  String get txnIncomingTransfer => 'Incoming transfer';

  @override
  String get txnPosPayment => 'POS payment';

  @override
  String get txnToday => 'Today, 2:45 PM';

  @override
  String get txnYesterday => 'Yesterday, 9:00 AM';

  @override
  String get txnMar12 => 'Mar 12, 8:15 AM';

  @override
  String get noTransactionsForAccount =>
      'No recent transactions for this account.';

  @override
  String transactionsShowingCount(int shown, int total) => '$shown of $total';

  @override
  String get transactionHistory => 'Transaction history';

  @override
  String get accountStatement => 'Account statement';

  @override
  String get searchTransactions => 'Search transactions';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncoming => 'Incoming';

  @override
  String get filterOutgoing => 'Outgoing';

  @override
  String get noMatchingTransactions => 'No matching transactions.';

  @override
  String transactionsCount(int count) => '$count transactions';

  @override
  String accountsPageIndicator(int current, int total) => '$current of $total';

  @override
  String get secureMobileBanking => 'Secure mobile banking';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInWithUsernamePassword =>
      'Sign in with your username and password.';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'e.g. 1019 or osama.ibrahim';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get signInAfterPasswordResetBanner =>
      'Sign in with your temporary password. You will be asked to set a new password, then your transaction PIN.';

  @override
  String get signIn => 'Sign in';

  @override
  String get opening => 'Opening…';

  @override
  String get signInWithBiometrics => 'Sign in with biometrics';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newCustomerRegister => 'New customer? Register';

  @override
  String get loginTabCustomer => 'Customer';

  @override
  String get loginTabMerchant => 'Point of sale';

  @override
  String get mobileNumberHint => 'e.g. 777563940';

  @override
  String get enterMobileNumber => 'Enter your mobile number';

  @override
  String get signInAsCustomer => 'Sign in as customer';

  @override
  String get dontHaveAccount => "Don't have an account?";

  @override
  String get createAccount => 'Create account';

  @override
  String get supportTollFree => 'Toll-free';

  @override
  String get supportServicePoints => 'Service points';

  @override
  String get supportCustomerService => 'Customer service';

  @override
  String get merchantLoginComingSoon => 'Point-of-sale sign-in is coming soon.';

  @override
  String get biometricSignIn => 'Biometric sign-in';

  @override
  String get biometricSignInSubtitle =>
      'Use fingerprint or face to access your accounts.';

  @override
  String get confirmYourIdentity => 'Confirm your identity';

  @override
  String get biometricPromptMessage =>
      'Your device will prompt for biometric verification.';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get unlock => 'Unlock';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get biometricVerificationFailed => 'Biometric verification failed';

  @override
  String get enableBiometricLoginTitle => 'Enable biometric login';

  @override
  String get enableBiometricLoginSubtitle =>
      'Sign in faster with fingerprint or face. Your PIN is required once to enroll.';

  @override
  String get biometricEnrollPinSubtitle =>
      'Confirm with your transaction PIN to enable biometrics';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get biometricLoginEnabledMessage =>
      'Biometric login enabled. Sign in with biometrics next time.';

  @override
  String get biometricSetupUnavailable =>
      'Biometric setup was cancelled or unavailable';

  @override
  String get enterYourPin => 'Enter your PIN';

  @override
  String get registerTitle => 'Register';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get registrationSubtitle =>
      'Enter your core banking customer ID to fetch your profile.';

  @override
  String get coreCustomerId => 'Core customer ID';

  @override
  String get coreCustomerIdHint => 'e.g. 000001295';

  @override
  String get enterCoreCustomerId => 'Enter your core banking customer ID';

  @override
  String get fetchProfile => 'Fetch profile';

  @override
  String get fullName => 'Full name';

  @override
  String get mobile => 'Mobile';

  @override
  String get gender => 'Gender';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get mobileLoginUsername => 'Mobile login username';

  @override
  String get coreCustomerIdOption => 'Core customer ID';

  @override
  String get customUsername => 'Custom username';

  @override
  String get customUsernameHint => 'e.g. osama.ibrahim';

  @override
  String get customUsernameRules =>
      '3–64 characters: letters, numbers, dots, underscores, hyphens.';

  @override
  String get changeId => 'Change ID';

  @override
  String get registerButton => 'Register';

  @override
  String get enterCustomUsername => 'Enter a custom username';

  @override
  String get registrationUsernameMissing =>
      'Registration succeeded but username is missing';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get registerWelcomeTitle => 'Welcome to Ultimate Wallet';

  @override
  String get registerWelcomeSubtitle =>
      'Create your account, join Ultimate Wallet customers';

  @override
  String get registerNameAsIdHint => 'Enter your name exactly as in your ID';

  @override
  String get firstName => 'First name';

  @override
  String get secondName => 'Second name';

  @override
  String get thirdName => 'Third name';

  @override
  String get surname => 'Surname';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get agreeToTerms => 'I agree to the Terms & Conditions';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get customerService => 'Customer service';

  @override
  String get servicePoints => 'Service points';

  @override
  String get tollFreeNumber => 'Toll-free number';

  @override
  String get mustAgreeToTerms => 'You must agree to the Terms & Conditions';

  @override
  String get requiredField => 'Required';

  @override
  String get activationTitle => 'Ultimate Wallet account activation code';

  @override
  String activationSubtitle(String mobile) =>
      'We sent an SMS with the activation code to your phone $mobile';

  @override
  String get activationExpiresIn => 'The confirmation code will expire in';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get contactCustomerService => 'Contact customer service';

  @override
  String get activationConfirm => 'Confirm';

  @override
  String get kycBannerText =>
      'Your account isn\'t verified — complete your details to activate your wallet.';

  @override
  String get kycVerifyAccount => 'Verify account';

  @override
  String get kycTitle => 'Account verification';

  @override
  String get kycSubtitle =>
      'Upload photos of your documents to verify your identity';

  @override
  String get kycIdFront => 'ID card — front';

  @override
  String get kycIdBack => 'ID card — back';

  @override
  String get kycSelfie => 'Selfie photo';

  @override
  String get kycUploadHint => 'Tap to upload';

  @override
  String get kycCamera => 'Camera';

  @override
  String get kycGallery => 'Gallery';

  @override
  String get kycSubmit => 'Submit for verification';

  @override
  String get kycSubmitted =>
      'Your documents were submitted and will be reviewed soon.';

  @override
  String get kycStatusUnverifiedTitle => 'Not verified';
  @override
  String get kycStatusUnverifiedDesc =>
      'Verify your identity to unlock the full wallet.';
  @override
  String get kycStatusIncompleteTitle => 'Incomplete';
  @override
  String get kycStatusIncompleteDesc =>
      'A few steps left — finish uploading your documents.';
  @override
  String get kycStatusPendingTitle => 'Under review';
  @override
  String get kycStatusPendingDesc =>
      'We\'re reviewing your documents. This usually takes a short while.';
  @override
  String get kycStatusVerifiedTitle => 'Verified';
  @override
  String get kycStatusVerifiedDesc =>
      'Your identity is confirmed. All wallet features are active.';
  @override
  String get kycStatusRejectedTitle => 'Verification declined';
  @override
  String get kycStatusRejectedDesc =>
      'We couldn\'t verify your documents. Please review and resubmit.';

  @override
  String kycStepProgress(int current, int total) => 'Step $current of $total';
  @override
  String get kycChooseSource => 'Add photo';
  @override
  String get kycRetake => 'Retake';
  @override
  String get kycUsePhoto => 'Use photo';
  @override
  String get kycPreviewTitle => 'Review photo';
  @override
  String get kycPreviewHint =>
      'Make sure all details are sharp, well-lit and fully inside the frame.';
  @override
  String get kycIdFrontGuide =>
      'Place the front of your ID inside the frame. Avoid glare and shadows.';
  @override
  String get kycIdBackGuide =>
      'Now capture the back of your ID. Keep all text readable.';
  @override
  String get kycSelfieGuide =>
      'Take a selfie in good lighting with a neutral expression.';
  @override
  String get kycUploaded => 'Uploaded';
  @override
  String get kycUploading => 'Uploading…';
  @override
  String get kycDocsIntro =>
      'Provide three clear photos so we can verify your identity.';
  @override
  String get kycAllReadyHint => 'All set — submit your documents for review.';
  @override
  String get kycIdType => 'ID type';
  @override
  String get kycIdTypeNationalId => 'National ID';
  @override
  String get kycIdTypePassport => 'Passport';
  @override
  String get kycPassport => 'Passport';
  @override
  String get kycPassportGuide =>
      'Place the passport data page inside the frame. Keep all text readable.';
  @override
  String get kycCameraLightingHint => 'Good light · no glare · hold steady';
  @override
  String get kycProcessing => 'Processing…';
  @override
  String get kycCameraUnavailable => 'Camera unavailable';
  @override
  String get kycCameraUnavailableBody =>
      'We couldn\'t start the camera. Make sure no other app is using it and try again.';

  @override
  String get kycCameraPermissionTitle => 'Camera access needed';
  @override
  String get kycCameraPermissionBody =>
      'Allow camera access to photograph your documents. You can enable it in Settings.';
  @override
  String get kycOpenSettings => 'Open settings';
  @override
  String get kycUploadFailed => 'Couldn\'t upload the photo. Please try again.';
  @override
  String get kycSubmitFailed =>
      'Couldn\'t submit your documents. Please try again.';
  @override
  String get kycServiceUnavailable =>
      'Verification isn\'t available right now. Please try again later.';
  @override
  String get kycRetry => 'Retry';
  @override
  String get kycCancel => 'Cancel';

  @override
  String get kycPendingHeadline => 'Documents submitted';
  @override
  String get kycPendingBody =>
      'Your identity documents are under review. We\'ll notify you once it\'s done.';
  @override
  String get kycVerifiedHeadline => 'You\'re verified';
  @override
  String get kycVerifiedBody =>
      'Your identity is confirmed and every wallet feature is unlocked.';
  @override
  String get kycRejectedHeadline => 'Verification declined';
  @override
  String get kycRejectionReasonLabel => 'Reason';
  @override
  String get kycResubmit => 'Resubmit documents';
  @override
  String get kycBackToHome => 'Back to home';

  @override
  String get kycBannerPendingText =>
      'Your documents are under review — we\'ll update you shortly.';
  @override
  String get kycBannerRejectedText =>
      'Verification was declined — tap to review and resubmit.';

  @override
  String get kycDataIntro =>
      'Confirm the details printed on your identity document, then continue to attach your photos.';
  @override
  String get kycSectionIdentity => 'Identity details';

  @override
  String get kycSectionPersonal => 'Your details';

  @override
  String get kycIdentityLocked => 'From your registration — can\'t be edited';
  @override
  String get kycSectionResidence => 'Residence details';
  @override
  String get kycFieldIdNumber => 'ID card number';
  @override
  String get kycFieldPassportNumber => 'Passport number';
  @override
  String get kycFieldIssuingAuthority => 'Issuing authority';
  @override
  String get kycFieldIssueDate => 'Issue date';
  @override
  String get kycFieldExpiryDate => 'Expiry date';
  @override
  String get kycFieldPlaceOfBirth => 'Place of birth';
  @override
  String get kycFieldDateOfBirth => 'Date of birth';
  @override
  String get kycFieldCountry => 'Country';
  @override
  String get kycFieldCity => 'City';
  @override
  String get kycFieldDistrict => 'District';
  @override
  String get kycFieldRegion => 'Region';
  @override
  String get kycFieldAddress => 'Current address';
  @override
  String get kycFieldSelectDate => 'Select date';
  @override
  String get kycFieldRequired => 'Required';
  @override
  String get kycFieldExpiryBeforeIssue =>
      'Expiry must be after the issue date';
  @override
  String get kycContinue => 'Continue';
  @override
  String get kycFinalStepTitle => 'Final step';
  @override
  String get kycFinalStepSubtitle =>
      'Attach your identity photos and supporting documents.';
  @override
  String get kycConfirmAccount => 'Confirm account';
  @override
  String get kycBack => 'Back';

  @override
  String get profileVerified => 'Verified';
  @override
  String get profileVerificationStatus => 'Verification';
  @override
  String get profileCompleteVerification => 'Complete verification';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get resetPasswordHeading => 'Reset password';

  @override
  String get resetPasswordDescription =>
      'Enter the mobile number linked to your account. Biometric login will be cleared on all devices.';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get enterRegisteredMobile => 'Enter your registered mobile number';

  @override
  String get resetPasswordSuccess =>
      'Password reset. Sign in with your temporary password (usually your customer ID), then create a new password and set your PIN.';

  @override
  String get requestReset => 'Request reset';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get createYourPassword => 'Create your password';

  @override
  String get setPasswordSubtitle =>
      'Your temporary password must be changed before you can continue.';

  @override
  String usernameLabel(String username) => 'Username: $username';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordLengthHint => '8–64 characters';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordNotAccepted =>
      'Password was not accepted. Try again or contact support.';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get transactionPinTitle => 'Transaction PIN';

  @override
  String get transactionPinSubtitle =>
      'Used to authorize transfers. Your device will be registered for secure access.';

  @override
  String get confirmYourPin => 'Confirm your PIN';

  @override
  String get createYourPin => 'Create your PIN';

  @override
  String get confirmPinSubtitle => 'Re-enter the same 4–6 digit PIN';

  @override
  String get choosePinSubtitle => 'Choose a 4–6 digit PIN for transfers';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get continueLabel => 'Continue';

  @override
  String get totalBalance => 'Total Balance';
  @override
  String get clickToAccess => 'Click here to access';
  @override
  String get viewFinancialStatus => 'View financial status';
  @override
  String get newAccount => 'New Account';
  @override
  String get navExplore => 'Settings';
  @override
  String get yourPoints => 'Your points';

  @override
  String get actionMedical => 'Medical practitioner?';
  @override
  String get actionDonate => 'Donate!';
  @override
  String get actionAlert => 'Be alert!';
  @override
  String get actionApple => 'Apple Arcade';
  @override
  String get actionNewCard => 'New card';

  @override
  String get serviceTransfer => 'Transfer';
  @override
  String get serviceAccounts => 'Accounts';
  @override
  String get serviceCards => 'Cards';
  @override
  String get serviceBills => 'Bills';
  @override
  String get serviceOffers => 'Offers';
  @override
  String get serviceFinance => 'Finance';

  // Home dashboard: quick services pill row
  @override
  String get quickSendRemittance => 'Send remittance';
  @override
  String get quickUnifiedNetwork => 'Unified Network';

  // Beneficiaries
  @override
  String get beneficiaries => 'Beneficiaries';
  @override
  String get addBeneficiary => 'Add Beneficiary';
  @override
  String get beneficiaryName => 'Beneficiary Name';
  @override
  String get beneficiaryAccountOrIban => 'Account Number or IBAN';
  @override
  String get beneficiaryNickname => 'Nickname';
  @override
  String get validateAccount => 'Validate Account';
  @override
  String get beneficiaryAddedSuccessfully => 'Beneficiary added successfully';
  @override
  String get emptyBeneficiaries => 'No saved beneficiaries yet.';
  @override
  String get deleteBeneficiary => 'Delete Beneficiary';
  @override
  String get beneficiaryDeleted => 'Beneficiary deleted';
  @override
  String get confirmDeleteBeneficiary =>
      'Are you sure you want to delete this beneficiary?';
  @override
  String get transferToBeneficiary => 'Transfer';
  @override
  String get editBeneficiary => 'Edit Beneficiary';
  @override
  String get editBeneficiarySubtitle => 'Update beneficiary details';
  @override
  String get beneficiaryUpdatedSuccessfully =>
      'Beneficiary updated successfully';
  @override
  String get saveChanges => 'Save Changes';
  @override
  String get noChangesDetected => 'No changes detected';
  @override
  String get verifyNewAccount => 'Verify new account';

  @override
  String get methodAccount => 'Account no.';
  @override
  String get methodMobile => 'Mobile';
  @override
  String get methodIban => 'IBAN';
  @override
  String get hintEnterAccount => 'Enter account number';
  @override
  String get hintEnterMobile => 'Enter mobile number';
  @override
  String get hintEnterIban => 'Enter IBAN';
  @override
  String get validationEnterValue => 'Please enter a value';
  @override
  String get localTransferSubtitle => 'Local transfer · within KSA';
  @override
  String get verifyAccount => 'Verify account';
  @override
  String get addBeneficiaryBy => 'Add beneficiary by';
  @override
  String get verifiedSecurelyNote =>
      'Verified securely via the core banking system';
  @override
  String get change => 'Change';
  @override
  String get accountVerified => 'Account verified';
  @override
  String get accountHolder => 'Account holder';
  @override
  String get nicknameOptional => 'Nickname (optional)';
  @override
  String get nicknameExample => 'e.g. Abdullah — rent';
  @override
  String get currencyLabel => 'Currency';
  @override
  String get categoryElectricity => 'Electricity';
  @override
  String get categoryWater => 'Water';
  @override
  String get categoryTelecom => 'Telecom';
  @override
  String get categoryGovernment => 'Government';
  @override
  String get categoryMobile => 'Mobile';
  @override
  String get categoryTraffic => 'Traffic';
  @override
  String get categoryEducation => 'Education';
  @override
  String get categoryViewAll => 'View all';
  @override
  String get payBills => 'Pay Bills';
  @override
  String get searchBillersHint => 'Search for billers';
  @override
  String get categories => 'Categories';
  @override
  String get dueThisWeek => 'Due this week';
  @override
  String get electricityPec => 'Electricity — PEC';
  @override
  String get due24Jun => 'Due · 24 Jun';
  @override
  String get telecomYemenMobile => 'Telecom';
  @override
  String get due27Jun => 'Due · 27 Jun';
  @override
  String get paymentHistory => 'Payment history';
  @override
  String get historyPecSubtitle => 'Jun 12 · Paid';
  @override
  String get historyWaterTitle => 'Water — Local Corp';
  @override
  String get historyWaterSubtitle => 'Jun 08 · Paid';
  @override
  String get payButton => 'Pay';
  @override
  String get paidStatus => 'Paid';
  @override
  String get comingSoonToast => 'Coming soon';
  @override
  String get serviceStandingOrders => 'Standing orders';
  @override
  String get serviceSendGift => 'Send a gift';
  @override
  String get serviceCharity => 'Charity';
  @override
  String get serviceTransferSettings => 'Transfer settings';
  @override
  String get serviceInvestmentWallet => 'Investment wallet';
  @override
  String get btnNewBeneficiary => 'New beneficiary';
  @override
  String get servicesLabel => 'Services';
  @override
  String get recentTransfersLabel => 'Recent transfers';
  @override
  String get chooseDebitAccount => 'Choose debit account';
  @override
  String get chooseCreditAccount => 'Choose credit account';
  @override
  String get hintBeneficiaryAccountOrIban => 'Beneficiary account or IBAN';
  @override
  String get exclusiveOffers => 'Exclusive Offers 🎁';
  @override
  String get cashBackTitle => '5% Cash Back on Purchases';
  @override
  String get cashBackSubtitle => 'Enjoy instant cash back on your credit cards';
  @override
  String get travelDiscountTitle => 'Travel Discounts up to 20%';
  @override
  String get travelDiscountSubtitle => 'Book flights and hotels at best rates';
  @override
  String get financeCalculatorTitle => 'Instant Finance Calculator 📈';
  @override
  String get financeCalculatorSubtitle =>
      'You are eligible for instant personal financing up to:';
  @override
  String get financeDisclaimer => '*Bank terms and conditions apply.';
  @override
  String get closeButton => 'Close';
  @override
  String get saudiRiyal => 'SAR';
  @override
  String get enableFingerprintTitle => 'Enable Fingerprint';
  @override
  String get enableFingerprintMessage =>
      'To enable fingerprint login, please sign in with your account first and activate it from the settings.';
  @override
  String get okButton => 'OK';
  @override
  String get verifyingStatus => 'Verifying...';
  @override
  String get biometricFailed => 'Biometric verification failed';
  @override
  String get enterRegisteredMobileHint => 'Enter registered mobile number';
  @override
  String get enterCustomerIdHint =>
      'Enter your customer ID in the banking system';

  // Notifications
  @override
  String get notificationsTitle => 'Notifications';
  @override
  String get notificationSettingsTitle => 'Notification Settings';
  @override
  String get notificationsAllow => 'Allow Notifications';
  @override
  String get notificationsTransfers => 'Transfers';
  @override
  String get notificationsGeneral => 'General Updates';
  @override
  String get notificationsSecurityAlerts => 'Security Alerts';
  @override
  String get notificationsComingSoon => 'Coming soon';
  @override
  String get securityBlockedTitle => 'Device not secure';
  @override
  String get securityBlockedMessage =>
      'This device appears to be compromised (rooted, tampered with, or running attack tools). To protect your accounts, the app cannot be used on it.';
  @override
  String get securityRestrictedTitle => 'Operation not available';
  @override
  String get securityRestrictedMessage =>
      'This operation is disabled because the device failed a security check (root/jailbreak or tampering detected). Use a trusted device, or contact support.';
  @override
  String get myCards => 'My Cards';
  @override
  String get cardDetails => 'Card Details';
  @override
  String get cardStatusActive => 'Active';
  @override
  String get cardStatusFrozen => 'Frozen';
  @override
  String get freezeCard => 'Freeze Card';
  @override
  String get unfreezeCard => 'Unfreeze Card';
  @override
  String get freezeCardConfirmTitle => 'Freeze this card?';
  @override
  String get freezeCardConfirmMessage =>
      'All new payments and withdrawals will be declined until you unfreeze it. You can unfreeze the card at any time.';
  @override
  String get cardFrozenBanner =>
      'This card is frozen — all payments and withdrawals are blocked.';
  @override
  String get cardFrozenToast => 'Card frozen';
  @override
  String get cardUnfrozenToast => 'Card unfrozen';
  @override
  String get cardSettings => 'Card Settings';
  @override
  String get onlinePayments => 'Online payments';
  @override
  String get onlinePaymentsSubtitle => 'E-commerce and in-app purchases';
  @override
  String get contactlessPayments => 'Contactless payments';
  @override
  String get contactlessPaymentsSubtitle => 'Tap-to-pay in stores';
  @override
  String get cardLimits => 'Card Limits';
  @override
  String get dailyPurchaseLimit => 'Daily purchase limit';
  @override
  String get atmWithdrawalLimit => 'Daily ATM withdrawal limit';
  @override
  String get limitUpdated => 'Limit updated';
  @override
  String get linkedAccount => 'Linked account';
  @override
  String get noCardTransactions => 'No transactions on this card yet.';

  // ─── Bill payments (Section 7) ───
  @override
  String get serviceProviders => 'Service providers';
  @override
  String get noProvidersFound => 'No matching providers';
  @override
  String get subscriberNumberLabel => 'Subscriber number';
  @override
  String get phoneNumberLabel => 'Phone number';
  @override
  String get billAccountNoLabel => 'Account number';
  @override
  String get invalidSubscriberNumber => 'The number format is not valid';
  @override
  String get inquireBill => 'Check bill';
  @override
  String get billDetails => 'Bill details';
  @override
  String get subscriberNameLabel => 'Subscriber name';
  @override
  String get balanceDueLabel => 'Amount due';
  @override
  String get availableCreditLabel => 'Available credit';
  @override
  String get lineTypeLabel => 'Line type';
  @override
  String get expiresLabel => 'Expires';
  @override
  String get minAmountLabel => 'Minimum amount';
  @override
  String get offersAndPackages => 'Offers & packages';
  @override
  String get chooseOffer => 'Choose a package';
  @override
  String get offersEmpty => 'No packages available right now';
  @override
  String get payAmountLabel => 'Amount';
  @override
  String get debitAccountLabel => 'Pay from account';
  @override
  String get chooseAccount => 'Choose account';
  @override
  String get reviewPayment => 'Review payment';
  @override
  String get confirmWithPin => 'Confirm with your PIN';
  @override
  String get payNow => 'Pay now';
  @override
  String get telecomPaymentTitle => 'Telecom Payment';
  @override
  String get payServicesSheetTitle => 'Pay Services';
  @override
  String get serviceTypeLabel => 'Service Type';
  @override
  String get packageTypeLabel => 'Package Type';
  @override
  String get fromAccountLabel => 'From Account';
  @override
  String get executeOperation => 'Execute';
  @override
  String get balanceInquiry => 'Balance Inquiry';
  @override
  String get landlinePaymentTitle => 'Landline Payment';
  @override
  String get internetPaymentTitle => 'Internet Payment';
  @override
  String get categoryLandline => 'Landline';
  @override
  String get enterPhoneForServices => 'Enter the phone number to see services';
  @override
  String get paymentSuccessful => 'Payment successful';
  @override
  String get paymentPendingTitle => 'Payment in progress';
  @override
  String get paymentPendingBody =>
      'The provider is processing your payment. Its status updates automatically in the payment history.';
  @override
  String get paymentFailed => 'Payment failed';
  @override
  String get referenceNumberLabel => 'Reference no.';
  @override
  String get providerReferenceLabel => 'Provider ref.';
  @override
  String get checkStatus => 'Check status';
  @override
  String get shareBillReceipt => 'Share receipt';
  @override
  String get billPaymentHistoryEmpty => 'No bill payments yet.';
  @override
  String get statusFailed => 'Failed';
  @override
  String get unMoneyTitle => 'UN Money';
  @override
  String get networkTransfersTitle => 'Network Transfers';
  @override
  String get unMoneySend => 'Send money';
  @override
  String get unMoneySendSubtitle => 'To any UN Money wallet or agent';
  @override
  String get unMoneyReceive => 'Receive money';
  @override
  String get unMoneyReceiveSubtitle =>
      'Credit a received transfer to your account';
  @override
  String get unMoneyHistory => 'Transfers history';
  @override
  String get unMoneyRecipientLabel => 'Recipient phone number';
  @override
  String get unMoneyPickupCode => 'Transfer code';
  @override
  String get unMoneyLookup => 'Find transfer';
  @override
  String get unMoneyReceiveConfirm => 'Credit to my account';
  @override
  String get unifiedNetworkCancelTile => 'Cancel transfer';
  @override
  String get unifiedNetworkSendTile => 'Send transfer';
  @override
  String get unifiedNetworkPayTile => 'Pay to account';
  @override
  String get unifiedNetworkSendTitle => 'Send transfer';
  @override
  String get unifiedNetworkPayTitle => 'Pay to account';
  @override
  String get unifiedNetworkCancelTitle => 'Cancel transfer';
  @override
  String get tabTransferToBeneficiary => 'Transfer to beneficiary';
  @override
  String get tabSendUnifiedNetwork => 'Send Unified Network transfer';
  @override
  String get beneficiaryNameLabel => 'Beneficiary name';
  @override
  String get beneficiaryNumberLabel => 'Beneficiary number';
  @override
  String get transferPurposeLabel => 'Purpose of transfer';
  @override
  String get purposePersonal => 'Personal';
  @override
  String get purposeWork => 'Work';
  @override
  String get transferNotesWarning =>
      'Warning: notes entered here will appear on your statement and be visible to the recipient, and will be archived with us.';
  @override
  String get transferNotesHint => 'Add a note';
  @override
  String get depositAccountLabel => 'Account to deposit into';
  @override
  String get referenceNumberHint => 'Please enter the reference number';
  @override
  String get depositNoteLine1 =>
      '1- The entered data must match the transfer data.';
  @override
  String get depositNoteLine2 =>
      "2- The recipient's data in the transfer must match your account data.";
  @override
  String get transferNumberHint => 'Enter the transfer number';
  @override
  String get confirmLabel => 'Confirm';
  @override
  String get categoryInternet => 'Internet';
  @override
  String get categoryMoneyTransfer => 'Transfers';
  @override
  String get categoryEntertainment => 'Entertainment';
}

class AppLocalizationsAr extends AppLocalizations {
  @override
  String get appTitle => 'Ultimate Wallet';

  // ── «Ultimate Wallet» wallet ──────────────────────────────────────────────
  @override
  String get walletBalanceLabel => 'رصيد المحفظة';
  @override
  String get walletActionSend => 'إرسال';
  @override
  String get walletActionReceive => 'استلام';
  @override
  String get walletActionTopUp => 'شحن';
  @override
  String get walletActionScan => 'مسح';
  @override
  String get walletServicesTitle => 'الخدمات';
  @override
  String get walletPayBills => 'الفواتير';
  @override
  String get walletTransferToBank => 'تحويل بنكي';
  @override
  String get walletBeneficiaries => 'المستفيدون';
  @override
  String get walletFavorites => 'المفضلة';
  @override
  String get walletRecentActivity => 'آخر العمليات';
  @override
  String get walletNoRecentActivity => 'لا توجد عمليات بعد';
  @override
  String get walletReceiveTitle => 'استلام الأموال';
  @override
  String get walletReceiveShareHint =>
      'شارك هذا الرمز لاستلام الأموال في محفظتك';
  @override
  String get walletNumberLabel => 'رقم المحفظة';
  @override
  String get walletRetry => 'إعادة المحاولة';
  @override
  String get walletMyWallets => 'محافظي';
  @override
  String get walletQuickAccessTitle => 'الوصول السريع';
  @override
  String get walletPromotionsTitle => 'عروض تهمّك';
  @override
  String get walletComingSoon => 'قريباً';

  @override
  String get svcGroupTransfers => 'التحويلات';
  @override
  String get svcGroupPayments => 'المدفوعات';
  @override
  String get svcGroupRechargeBills => 'الشحن والفواتير';
  @override
  String get svcGroupWalletServices => 'خدمات المحفظة';
  @override
  String get svcGroupOther => 'خدمات مالية أخرى';
  @override
  String get svcSendToWallet => 'تحويل لمحفظة';
  @override
  String get svcBetweenAccounts => 'بين حساباتي';
  @override
  String get svcMobileTopup => 'شحن رصيد';
  @override
  String get svcPurchases => 'المشتريات';
  @override
  String get svcExchange => 'مصارفة العملات';
  @override
  String get svcInternetCards => 'بطاقات الإنترنت';
  @override
  String get svcCashWithdrawal => 'سحب نقدي';
  @override
  String get svcRewardsStore => 'متجر النقاط';
  @override
  String get svcServicePoints => 'الوكلاء ونقاط الخدمة';
  @override
  String get comingSoonSheetMessage => 'هذه الخدمة ستكون متاحة قريبًا';
  @override
  String get svcPurchasesDesc => 'تسوّق وادفع مشترياتك مباشرة من محفظتك.';
  @override
  String get svcExchangeDesc => 'حوّل بين العملات بأسعار محدّثة داخل التطبيق.';
  @override
  String get svcInternetCardsDesc => 'اشترِ بطاقات إنترنت مسبقة الدفع بسرعة.';
  @override
  String get svcCashWithdrawalDesc =>
      'اسحب نقدًا من نقاط الخدمة والوكلاء المعتمدين.';
  @override
  String get svcRewardsStoreDesc => 'استبدل نقاطك بمكافآت وعروض حصرية.';
  @override
  String get svcServicePointsDesc =>
      'اعثر على أقرب وكيل أو نقطة خدمة على الخريطة.';

  @override
  String get svcMoneyTransfers => 'التحويلات المالية';
  @override
  String get svcWithdrawFunds => 'سحب الأموال';
  @override
  String get svcRechargeAndPay => 'الشحن والسداد';
  @override
  String get svcPurchasePayment => 'دفع المشتريات';
  @override
  String get svcOtherBanksWallets => 'بنوك ومحافظ أخرى';
  @override
  String get svcOtherBanksWalletsDesc => 'حوّل إلى بنوك ومحافظ أخرى — قريبًا.';
  @override
  String get svcTransferToSubscriber => 'تحويل إلى مشترك';
  @override
  String get svcTransferToSubscriberDesc =>
      'أرسل الأموال فوراً إلى محفظة مشترك آخر.';
  @override
  String get svcPayBillsFull => 'سداد الفواتير';
  @override
  String get svcPayBillsDesc => 'سدّد فواتير الخدمات والاتصالات والجهات الحكومية.';
  @override
  String get svcRechargeBalance => 'شحن الرصيد';
  @override
  String get svcRechargeBalanceDesc => 'اشحن رصيد هاتفك وباقات الإنترنت.';
  @override
  String get svcPayMerchant => 'دفع لتاجر';
  @override
  String get svcPayMerchantDesc => 'ادفع لتاجر معتمد مباشرة من محفظتك.';
  @override
  String get svcScanToPay => 'مسح QR / الباركود';
  @override
  String get svcScanToPayDesc => 'امسح رمز الدفع لإتمام عملية الشراء.';
  @override
  String get svcFavoriteMerchants => 'التجار المفضلون';
  @override
  String get svcFavoriteMerchantsDesc => 'ادفع لتجّارك المفضلين بلمسة واحدة.';
  @override
  String get merchantNumberLabel => 'رقم التاجر أو المحفظة';
  @override
  String get noteOptionalLabel => 'ملاحظة (اختياري)';
  @override
  String get merchantPayContinue => 'متابعة الدفع';
  @override
  String get favoriteMerchantsEmptyTitle => 'لا يوجد تجار مفضلون بعد';
  @override
  String get favoriteMerchantsEmpty =>
      'أضف تجّارك المعتادين لتدفع لهم بسرعة في المرة القادمة.';

  @override
  String get walletAddFavorite => 'أضف مفضّلة';
  @override
  String get walletServiceInternet => 'الإنترنت';
  @override
  String get walletCurrencySar => 'الريال السعودي';
  @override
  String get walletCurrencyYer => 'الريال اليمني';
  @override
  String get walletCurrencyUsd => 'الدولار الأمريكي';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTransfers => 'التحويلات';

  @override
  String get navPayments => 'المدفوعات';

  @override
  String get navReports => 'التقارير';

  @override
  String get reportsTitle => 'التقارير';
  @override
  String get reportsTabAll => 'الكل';
  @override
  String get reportsTabSent => 'المرسلة';
  @override
  String get reportsTabReceived => 'المستلمة';
  @override
  String get reportsTabFees => 'الرسوم';
  @override
  String get reportsEmpty => 'لا توجد عناصر';
  @override
  String get reportsFilterTitle => 'تصفية التقارير';
  @override
  String get reportsFilterCurrency => 'العملة';
  @override
  String get reportsFilterPhoneHint => 'الهاتف';
  @override
  String get reportsFilterOr => 'أو';
  @override
  String get reportsFilterOperationType => 'نوع العملية';
  @override
  String get reportsFilterFromDate => 'من تاريخ';
  @override
  String get reportsFilterToDate => 'إلى تاريخ';
  @override
  String get reportsFilterPurposeHint => 'الغرض';
  @override
  String get reportsApply => 'تأكيد';
  @override
  String get reportsReset => 'إعادة تعيين';
  @override
  String get reportsOpTransfer => 'تحويل';
  @override
  String get reportsOpPayment => 'دفع';
  @override
  String get reportsOpDeposit => 'إيداع';
  @override
  String get reportsOpWithdrawal => 'سحب';
  @override
  String get reportsExportComingSoon => 'سيتوفر التصدير قريبًا';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageChinese => '中文';

  @override
  String get security => 'الأمان';

  @override
  String get sessionTimeout => 'مهلة الجلسة';

  @override
  String get sessionTimeoutSubtitle => 'تسجيل الخروج تلقائياً بعد فترة خمول';

  @override
  String get sessionTimeoutUpdated => 'تم تحديث مهلة الجلسة';

  @override
  String sessionTimeoutMinutesLabel(int minutes) {
    if (minutes == 1) return 'دقيقة واحدة';
    if (minutes == 3) return '3 دقائق';
    return '$minutes دقائق';
  }

  @override
  String get sessionExpiredMessage =>
      'انتهت الجلسة، الرجاء تسجيل الدخول مرة أخرى.';

  @override
  String get reloginPasswordChangeRequired =>
      'كلمة المرور الحالية مؤقتة ويجب تغييرها. اضغط إلغاء ثم سجّل الدخول من شاشة الدخول لتعيين كلمة مرور جديدة.';

  @override
  String get reloginFailedGeneric => 'تعذر تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get serverUnreachableMessage =>
      'تعذر الوصول إلى الخادم حالياً. تأكد من اتصالك بالإنترنت ثم اسحب الشاشة للأسفل لإعادة المحاولة.';

  @override
  String get biometricLogin => 'تسجيل الدخول بالبصمة';

  @override
  String get biometricLoginSubtitle => 'الدخول ببصمة الإصبع أو الوجه';

  @override
  String get changePin => 'تغيير الرمز السري';

  @override
  String get changePinSubtitle => 'تحديث رمز المعاملات';

  @override
  String get forgotPin => 'نسيت الرمز السري';

  @override
  String get forgotPinSubtitle => 'إعادة تعيين الرمز باستخدام كلمة مرور الدخول';

  @override
  String get account => 'الحساب';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get profileSubtitle => 'عرض بياناتك الشخصية';

  @override
  String get copied => 'تم النسخ';

  @override
  String get defaultAccountsTitle => 'الحسابات الافتراضية';

  @override
  String get defaultAccountsSubtitle =>
      'اختر حسابك الرئيسي وحساباً افتراضياً لكل عملة.';

  @override
  String get defaultAccountsSettingsSubtitle => 'الافتراضي الرئيسي ولكل عملة';

  @override
  String get defaultAccountsGlobal => 'الحساب الرئيسي (كل العملات)';

  @override
  String get defaultAccountsPerCurrency => 'الافتراضي لكل عملة';

  @override
  String get saveDefaultAccounts => 'حفظ الحسابات الافتراضية';

  @override
  String get defaultAccountsSaved => 'تم حفظ الحسابات الافتراضية';

  @override
  String get saving => 'جاري الحفظ…';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordSubtitle => 'إعادة التعيين عبر رقم الجوال المسجل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get helpSupportSubtitle => 'تواصل مع خدمة العملاء';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get termsAndConditionsSubtitle => 'سياسة فتح حساب المحفظة الإلكترونية';

  @override
  String get termsAndConditionsFooter =>
      'هذا المستند للاطلاع فقط. يُرجى الرجوع إلى النسخة الرسمية المعتمدة.';

  @override
  String get supportTitle => 'الدعم';

  @override
  String get supportNewCase => 'حالة جديدة';

  @override
  String get supportSubject => 'الموضوع';

  @override
  String get supportMessage => 'الرسالة';

  @override
  String get supportSubmit => 'إرسال';

  @override
  String get supportNoCases => 'لا توجد حالات دعم بعد.';

  @override
  String get supportReply => 'رد';

  @override
  String get supportSend => 'إرسال';

  @override
  String get supportCaseNumber => 'رقم الحالة';

  @override
  String get needHelp => 'تحتاج مساعدة؟';

  @override
  String get trackExistingCase => 'متابعة حالة موجودة';

  @override
  String get guestName => 'اسمك';

  @override
  String get guestMobile => 'رقم الجوال';

  @override
  String get supportCreatedTitle => 'تم إرسال الحالة';

  @override
  String supportCreatedBody(String caseNumber) =>
      'تم إنشاء الحالة $caseNumber. احفظ هذا الرقم لمتابعة الردود.';

  @override
  String get supportQueued => 'في الانتظار — لم يُعيَّن بعد';

  @override
  String supportAssignedTo(String name) => 'معيّن إلى $name';

  @override
  String get supportWaitingForYou => 'بانتظار ردك';

  @override
  String get supportSeen => 'مقروء';

  @override
  String get supportDelivered => 'تم الإرسال';

  @override
  String get enterTransactionPin => 'أدخل رمز المعاملات';

  @override
  String get pinRequiredEnableBiometric => 'مطلوب لتفعيل الدخول بالبصمة';

  @override
  String get pinRequiredDisableBiometric => 'مطلوب لإيقاف الدخول بالبصمة';

  @override
  String get biometricEnabled => 'تم تفعيل الدخول بالبصمة';

  @override
  String get biometricSetupCancelled => 'تم إلغاء إعداد البصمة';

  @override
  String get biometricDisabled => 'تم إيقاف الدخول بالبصمة';

  @override
  String get transferToMyAccounts => 'إلى حساباتي';

  @override
  String get transferToOthers => 'إلى آخرين';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get addAccountDesc => 'افتح حساباً إضافياً بعملة أو نوع آخر — قريباً.';

  @override
  String get betweenYourAccounts => 'بين حساباتك';

  @override
  String get betweenYourAccountsSubtitle => 'تحويل الأموال بين حساباتك';

  @override
  String get toAnotherAccount => 'إلى حساب آخر';

  @override
  String get toAnotherAccountSubtitle => 'إرسال إلى مستفيد خارجي';

  @override
  String get debitAccount => 'حساب الخصم';

  @override
  String get creditAccount => 'حساب الإيداع';

  @override
  String get beneficiaryAccount => 'حساب المستفيد';

  @override
  String get amount => 'المبلغ';

  @override
  String get transferMax => 'تحويل الحد الأقصى';

  @override
  String get reviewTransfer => 'مراجعة التحويل';

  @override
  String get dealRate => 'سعر الصرف';

  @override
  String get youSend => 'تُرسل';

  @override
  String get recipientGets => 'يستلم المستفيد';

  @override
  String get fetchingRate => 'جارٍ جلب سعر الصرف…';

  @override
  String get scanQr => 'مسح QR';

  @override
  String get noAccountsForTransfer => 'لا توجد حسابات متاحة للتحويل.';

  @override
  String get needTwoAccounts =>
      'تحتاج إلى حسابين على الأقل للتحويل بين حساباتك.';

  @override
  String get chooseAccountsAndAmount =>
      'اختر حسابي الخصم والإيداع وأدخل المبلغ';

  @override
  String get chooseDebitBeneficiaryAmount =>
      'اختر حساب الخصم وحساب المستفيد والمبلغ';

  @override
  String get fromLabel => 'من';

  @override
  String get toLabel => 'إلى';

  @override
  String get confirmTransfer => 'تأكيد التحويل';

  @override
  String get validationDetails => 'تفاصيل التحقق';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get authorizeTransfer => 'تفويض التحويل';

  @override
  String get enterPinToComplete => 'أدخل رمز المعاملات لإتمام العملية';

  @override
  String get transferComplete => 'تم التحويل';

  @override
  String get saveReferenceHint => 'احفظ هذا المرجع لسجلاتك';

  @override
  String get reference => 'المرجع';

  @override
  String get referenceCopied => 'تم نسخ المرجع';

  @override
  String get copyReference => 'نسخ المرجع';

  @override
  String get newTransfer => 'تحويل جديد';

  @override
  String get customerIdMissing => 'معرف العميل غير موجود في الملف الشخصي.';

  @override
  String get noAccountsFound => 'لم يتم العثور على حسابات.';

  @override
  String get allAccounts => 'كل حساباتي';

  @override
  String get searchAccounts => 'ابحث في الحسابات';

  @override
  String get noMatchingAccounts => 'لا توجد حسابات مطابقة.';

  @override
  String get hideZeroBalances => 'إخفاء الصفرية';

  @override
  String accountsCount(int count) => '$count حساب';

  @override
  String get yourCards => 'بطاقاتك';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get recentTransactions => 'المعاملات الأخيرة';

  @override
  String get recentTransfers => 'آخر التحويلات';

  @override
  String get transferAgain => 'إعادة التحويل';

  @override
  String get noRecentTransfers => 'لا توجد تحويلات سابقة بعد.';

  @override
  String get favoritesLabel => 'المفضّلة';

  @override
  String get removeFavorite => 'إزالة من المفضّلة';

  @override
  String get favoritesEmpty =>
      'لا توجد مفضّلات بعد. ميّز مستفيداً بنجمة ليظهر هنا.';

  @override
  String get transferOthersSubtitle => 'حوّل إلى عميل أو مستفيد آخر';

  @override
  String get addAccountSubtitle => 'افتح حساباً جارياً أو توفير جديد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get quickSend => 'إرسال';

  @override
  String get quickRequest => 'طلب';

  @override
  String get quickQr => 'QR';

  @override
  String get quickHistory => 'السجل';

  @override
  String get featureComingSoonTitle => 'قريباً';

  @override
  String get featureComingSoonMessage => 'هذه الميزات قادمة قريباً.';

  @override
  String get debitCard => 'بطاقة خصم';

  @override
  String get creditCard => 'بطاقة ائتمان';

  @override
  String get details => 'التفاصيل';

  @override
  String get scanToPay => 'امسح للدفع';

  @override
  String get shareQrForTransfers => 'شارك رمز QR للتحويل إلى هذا الحساب';

  @override
  String get accountNumberCopied => 'تم نسخ رقم الحساب';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get txnRetailPurchase => 'شراء تجزئة';

  @override
  String get txnIncomingTransfer => 'تحويل وارد';

  @override
  String get txnPosPayment => 'دفع نقطة بيع';

  @override
  String get txnToday => 'اليوم، ٢:٤٥ م';

  @override
  String get txnYesterday => 'أمس، ٩:٠٠ ص';

  @override
  String get txnMar12 => '١٢ مارس، ٨:١٥ ص';

  @override
  String get noTransactionsForAccount => 'لا توجد معاملات حديثة لهذا الحساب.';

  @override
  String transactionsShowingCount(int shown, int total) => '$shown من $total';

  @override
  String get transactionHistory => 'سجل الحركات';

  @override
  String get accountStatement => 'كشف حساب';

  @override
  String get searchTransactions => 'ابحث في الحركات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterIncoming => 'وارد';

  @override
  String get filterOutgoing => 'صادر';

  @override
  String get noMatchingTransactions => 'لا توجد حركات مطابقة.';

  @override
  String transactionsCount(int count) => '$count حركة';

  @override
  String accountsPageIndicator(int current, int total) => '$current من $total';

  @override
  String get secureMobileBanking => 'خدمة مصرفية آمنة عبر الجوال';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInWithUsernamePassword =>
      'سجّل الدخول باسم المستخدم وكلمة المرور.';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'مثال: 1019 أو osama.ibrahim';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get signInAfterPasswordResetBanner =>
      'سجّل الدخول بكلمة المرور المؤقتة. سيُطلب منك تعيين كلمة مرور جديدة ثم رمز المعاملات.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get opening => 'جارٍ الفتح…';

  @override
  String get signInWithBiometrics => 'تسجيل الدخول بالبصمة';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get newCustomerRegister => 'عميل جديد؟ سجّل الآن';

  @override
  String get loginTabCustomer => 'عميل';

  @override
  String get loginTabMerchant => 'نقطة مبيعات';

  @override
  String get mobileNumberHint => 'مثال: 777563940';

  @override
  String get enterMobileNumber => 'أدخل رقم الموبايل';

  @override
  String get signInAsCustomer => 'تسجيل الدخول كـ عميل';

  @override
  String get dontHaveAccount => 'لا تملك حساباً؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get supportTollFree => 'الرقم المجاني';

  @override
  String get supportServicePoints => 'نقاط الخدمة';

  @override
  String get supportCustomerService => 'خدمة العملاء';

  @override
  String get merchantLoginComingSoon => 'دخول نقطة المبيعات سيتوفّر قريباً.';

  @override
  String get biometricSignIn => 'الدخول بالبصمة';

  @override
  String get biometricSignInSubtitle =>
      'استخدم بصمة الإصبع أو الوجه للوصول إلى حساباتك.';

  @override
  String get confirmYourIdentity => 'تأكيد هويتك';

  @override
  String get biometricPromptMessage => 'سيطلب جهازك التحقق البيومتري.';

  @override
  String get pleaseWait => 'يرجى الانتظار…';

  @override
  String get unlock => 'فتح';

  @override
  String get usePasswordInstead => 'استخدم كلمة المرور بدلاً من ذلك';

  @override
  String get biometricVerificationFailed => 'فشل التحقق البيومتري';

  @override
  String get enableBiometricLoginTitle => 'تفعيل الدخول بالبصمة';

  @override
  String get enableBiometricLoginSubtitle =>
      'سجّل الدخول بشكل أسرع بالبصمة أو الوجه. يُطلب رمز المعاملات مرة واحدة للتسجيل.';

  @override
  String get biometricEnrollPinSubtitle => 'أكّد برمز المعاملات لتفعيل البصمة';

  @override
  String get skipForNow => 'تخطي الآن';

  @override
  String get biometricLoginEnabledMessage =>
      'تم تفعيل الدخول بالبصمة. استخدم البصمة في المرة القادمة.';

  @override
  String get biometricSetupUnavailable =>
      'تم إلغاء إعداد البصمة أو أنه غير متاح';

  @override
  String get enterYourPin => 'أدخل رمزك السري';

  @override
  String get registerTitle => 'التسجيل';

  @override
  String get createYourAccount => 'إنشاء حسابك';

  @override
  String get registrationSubtitle =>
      'أدخل معرف العميل في النظام المصرفي لجلب ملفك الشخصي.';

  @override
  String get coreCustomerId => 'معرف العميل';

  @override
  String get coreCustomerIdHint => 'مثال: 000001295';

  @override
  String get enterCoreCustomerId => 'أدخل معرف العميل في النظام المصرفي';

  @override
  String get fetchProfile => 'جلب الملف الشخصي';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get mobile => 'الجوال';

  @override
  String get gender => 'الجنس';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get mobileLoginUsername => 'اسم مستخدم الدخول للجوال';

  @override
  String get coreCustomerIdOption => 'معرف العميل';

  @override
  String get customUsername => 'اسم مستخدم مخصص';

  @override
  String get customUsernameHint => 'مثال: osama.ibrahim';

  @override
  String get customUsernameRules =>
      '٣–٦٤ حرفاً: أحرف وأرقام ونقاط وشرطات سفلية وواصلات.';

  @override
  String get changeId => 'تغيير المعرف';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get enterCustomUsername => 'أدخل اسم مستخدم مخصص';

  @override
  String get registrationUsernameMissing =>
      'تم التسجيل بنجاح لكن اسم المستخدم مفقود';

  @override
  String get alreadyHaveAccountSignIn => 'لديك حساب؟ سجّل الدخول';

  @override
  String get registerWelcomeTitle => 'مرحباً بك في Ultimate Wallet';

  @override
  String get registerWelcomeSubtitle =>
      'قم بإنشاء حسابك، وانضم إلى عملاء Ultimate Wallet';

  @override
  String get registerNameAsIdHint => 'قم بإدخال الاسم كما في الهوية';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get secondName => 'الاسم الثاني';

  @override
  String get thirdName => 'الاسم الثالث';

  @override
  String get surname => 'اللقب';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get agreeToTerms => 'أوافق على الشروط والأحكام';

  @override
  String get createAccountButton => 'إنشاء حساب';

  @override
  String get customerService => 'خدمة العملاء';

  @override
  String get servicePoints => 'نقاط الخدمة';

  @override
  String get tollFreeNumber => 'الرقم المجاني';

  @override
  String get mustAgreeToTerms => 'يجب الموافقة على الشروط والأحكام';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get activationTitle => 'كود تفعيل حساب Ultimate Wallet';

  @override
  String activationSubtitle(String mobile) =>
      'لقد أرسلنا رسالة نصية قصيرة تحتوي على رمز التفعيل إلى هاتفك $mobile';

  @override
  String get activationExpiresIn => 'رمز التأكيد سينتهي خلال';

  @override
  String get didntReceiveCode => 'لم تتلقَّ الكود؟';

  @override
  String get contactCustomerService => 'التواصل مع خدمة العملاء';

  @override
  String get activationConfirm => 'تأكيد';

  @override
  String get kycBannerText =>
      'حسابك غير مؤكد — أكمل بياناتك ووثائقك لتفعيل محفظتك.';

  @override
  String get kycVerifyAccount => 'تأكيد حسابك';

  @override
  String get kycTitle => 'تأكيد الحساب';

  @override
  String get kycSubtitle => 'قم برفع صور وثائقك للتحقق من هويتك';

  @override
  String get kycIdFront => 'وجه البطاقة الشخصية';

  @override
  String get kycIdBack => 'ظهر البطاقة الشخصية';

  @override
  String get kycSelfie => 'صورة شخصية (سيلفي)';

  @override
  String get kycUploadHint => 'اضغط للرفع';

  @override
  String get kycCamera => 'الكاميرا';

  @override
  String get kycGallery => 'المعرض';

  @override
  String get kycSubmit => 'إرسال للتحقق';

  @override
  String get kycSubmitted => 'تم إرسال وثائقك، وستتم مراجعتها قريباً.';

  @override
  String get kycStatusUnverifiedTitle => 'غير موثّق';
  @override
  String get kycStatusUnverifiedDesc =>
      'وثّق هويتك للاستفادة من كامل مزايا المحفظة.';
  @override
  String get kycStatusIncompleteTitle => 'غير مكتمل';
  @override
  String get kycStatusIncompleteDesc => 'بقيت خطوات قليلة — أكمل رفع وثائقك.';
  @override
  String get kycStatusPendingTitle => 'قيد المراجعة';
  @override
  String get kycStatusPendingDesc =>
      'نقوم بمراجعة وثائقك، ويستغرق ذلك وقتاً قصيراً عادةً.';
  @override
  String get kycStatusVerifiedTitle => 'موثّق';
  @override
  String get kycStatusVerifiedDesc =>
      'تم تأكيد هويتك، وجميع مزايا المحفظة مُفعّلة.';
  @override
  String get kycStatusRejectedTitle => 'تم رفض التوثيق';
  @override
  String get kycStatusRejectedDesc =>
      'تعذّر التحقق من وثائقك. يُرجى المراجعة وإعادة الإرسال.';

  @override
  String kycStepProgress(int current, int total) => 'الخطوة $current من $total';
  @override
  String get kycChooseSource => 'إضافة صورة';
  @override
  String get kycRetake => 'إعادة التصوير';
  @override
  String get kycUsePhoto => 'استخدام الصورة';
  @override
  String get kycPreviewTitle => 'مراجعة الصورة';
  @override
  String get kycPreviewHint =>
      'تأكد من وضوح كل التفاصيل وإضاءتها الجيدة ووقوعها بالكامل داخل الإطار.';
  @override
  String get kycIdFrontGuide =>
      'ضع وجه البطاقة داخل الإطار، وتجنّب الانعكاسات والظلال.';
  @override
  String get kycIdBackGuide =>
      'صوّر الآن ظهر البطاقة مع إبقاء جميع النصوص واضحة للقراءة.';
  @override
  String get kycSelfieGuide => 'التقط صورة سيلفي في إضاءة جيدة وبتعبير طبيعي.';
  @override
  String get kycUploaded => 'تم الرفع';
  @override
  String get kycUploading => 'جارٍ الرفع…';
  @override
  String get kycDocsIntro =>
      'قدّم ثلاث صور واضحة حتى نتمكن من التحقق من هويتك.';
  @override
  String get kycAllReadyHint => 'كل شيء جاهز — أرسل وثائقك للمراجعة.';
  @override
  String get kycIdType => 'نوع الهوية';
  @override
  String get kycIdTypeNationalId => 'بطاقة شخصية';
  @override
  String get kycIdTypePassport => 'جواز سفر';
  @override
  String get kycPassport => 'جواز السفر';
  @override
  String get kycPassportGuide =>
      'ضع صفحة بيانات الجواز داخل الإطار مع إبقاء جميع النصوص واضحة.';
  @override
  String get kycCameraLightingHint => 'إضاءة جيدة · بدون انعكاس · ثبّت يدك';
  @override
  String get kycProcessing => 'جارٍ المعالجة…';
  @override
  String get kycCameraUnavailable => 'الكاميرا غير متاحة';
  @override
  String get kycCameraUnavailableBody =>
      'تعذّر تشغيل الكاميرا. تأكد من عدم استخدامها في تطبيق آخر وحاول مجدداً.';

  @override
  String get kycCameraPermissionTitle => 'مطلوب إذن الكاميرا';
  @override
  String get kycCameraPermissionBody =>
      'اسمح بالوصول إلى الكاميرا لتصوير وثائقك. يمكنك تفعيله من الإعدادات.';
  @override
  String get kycOpenSettings => 'فتح الإعدادات';
  @override
  String get kycUploadFailed => 'تعذّر رفع الصورة. يُرجى المحاولة مرة أخرى.';
  @override
  String get kycSubmitFailed => 'تعذّر إرسال وثائقك. يُرجى المحاولة مرة أخرى.';
  @override
  String get kycServiceUnavailable =>
      'خدمة التوثيق غير متاحة حالياً. يُرجى المحاولة لاحقاً.';
  @override
  String get kycRetry => 'إعادة المحاولة';
  @override
  String get kycCancel => 'إلغاء';

  @override
  String get kycPendingHeadline => 'تم إرسال الوثائق';
  @override
  String get kycPendingBody =>
      'وثائق هويتك قيد المراجعة، وسنُعلمك فور الانتهاء.';
  @override
  String get kycVerifiedHeadline => 'تم توثيق حسابك';
  @override
  String get kycVerifiedBody => 'تم تأكيد هويتك وتفعيل جميع مزايا المحفظة.';
  @override
  String get kycRejectedHeadline => 'تم رفض التوثيق';
  @override
  String get kycRejectionReasonLabel => 'السبب';
  @override
  String get kycResubmit => 'إعادة إرسال الوثائق';
  @override
  String get kycBackToHome => 'العودة للرئيسية';

  @override
  String get kycBannerPendingText =>
      'وثائقك قيد المراجعة — سنوافيك بالتحديث قريباً.';
  @override
  String get kycBannerRejectedText =>
      'تم رفض التوثيق — اضغط للمراجعة وإعادة الإرسال.';

  @override
  String get kycDataIntro =>
      'تحقق من البيانات المدوّنة في وثيقة هويتك، ثم تابع لإرفاق صورك.';
  @override
  String get kycSectionIdentity => 'بيانات الهوية';

  @override
  String get kycSectionPersonal => 'بياناتك الشخصية';

  @override
  String get kycIdentityLocked => 'من بيانات التسجيل — لا يمكن تعديلها';
  @override
  String get kycSectionResidence => 'بيانات الإقامة';
  @override
  String get kycFieldIdNumber => 'رقم البطاقة الشخصية';
  @override
  String get kycFieldPassportNumber => 'رقم جواز السفر';
  @override
  String get kycFieldIssuingAuthority => 'جهة إصدار الهوية';
  @override
  String get kycFieldIssueDate => 'تاريخ إصدار الهوية';
  @override
  String get kycFieldExpiryDate => 'تاريخ إنتهاء الهوية';
  @override
  String get kycFieldPlaceOfBirth => 'مكان الميلاد';
  @override
  String get kycFieldDateOfBirth => 'تاريخ الميلاد';
  @override
  String get kycFieldCountry => 'الدولة';
  @override
  String get kycFieldCity => 'المدينة';
  @override
  String get kycFieldDistrict => 'المديرية';
  @override
  String get kycFieldRegion => 'المنطقة';
  @override
  String get kycFieldAddress => 'عنوان الإقامة الحالي';
  @override
  String get kycFieldSelectDate => 'اختر التاريخ';
  @override
  String get kycFieldRequired => 'مطلوب';
  @override
  String get kycFieldExpiryBeforeIssue =>
      'تاريخ الإنتهاء يجب أن يكون بعد تاريخ الإصدار';
  @override
  String get kycContinue => 'استمرار';
  @override
  String get kycFinalStepTitle => 'الخطوة الأخيرة';
  @override
  String get kycFinalStepSubtitle => 'قم بإرفاق صور وأوراق الإثباتات';
  @override
  String get kycConfirmAccount => 'تأكيد الحساب';
  @override
  String get kycBack => 'رجوع';

  @override
  String get profileVerified => 'موثّق';
  @override
  String get profileVerificationStatus => 'التوثيق';
  @override
  String get profileCompleteVerification => 'إكمال التوثيق';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get resetPasswordHeading => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordDescription =>
      'أدخل رقم الجوال المرتبط بحسابك. سيتم إلغاء الدخول بالبصمة على جميع الأجهزة.';

  @override
  String get mobileNumber => 'رقم الجوال';

  @override
  String get enterRegisteredMobile => 'أدخل رقم الجوال المسجل';

  @override
  String get resetPasswordSuccess =>
      'تم إعادة تعيين كلمة المرور. سجّل الدخول بكلمة المرور المؤقتة (عادةً معرف العميل)، ثم أنشئ كلمة مرور جديدة وعيّن رمز المعاملات.';

  @override
  String get requestReset => 'طلب إعادة التعيين';

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get setPasswordTitle => 'تعيين كلمة المرور';

  @override
  String get createYourPassword => 'إنشاء كلمة المرور';

  @override
  String get setPasswordSubtitle =>
      'يجب تغيير كلمة المرور المؤقتة قبل المتابعة.';

  @override
  String usernameLabel(String username) => 'اسم المستخدم: $username';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordLengthHint => '٨–٦٤ حرفاً';

  @override
  String get atLeast8Characters => '٨ أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordNotAccepted =>
      'لم تُقبل كلمة المرور. حاول مرة أخرى أو اتصل بالدعم.';

  @override
  String get saveAndContinue => 'حفظ ومتابعة';

  @override
  String get transactionPinTitle => 'رمز المعاملات';

  @override
  String get transactionPinSubtitle =>
      'يُستخدم لتفويض التحويلات. سيتم تسجيل جهازك للوصول الآمن.';

  @override
  String get confirmYourPin => 'تأكيد الرمز السري';

  @override
  String get createYourPin => 'إنشاء الرمز السري';

  @override
  String get confirmPinSubtitle => 'أعد إدخال نفس الرمز المكوّن من ٤–٦ أرقام';

  @override
  String get choosePinSubtitle => 'اختر رمزاً مكوّناً من ٤–٦ أرقام للتحويلات';

  @override
  String get pinsDoNotMatch => 'الرمزان غير متطابقين';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get totalBalance => 'الرصيد الإجمالي';
  @override
  String get clickToAccess => 'اضغط هنا للوصول';
  @override
  String get viewFinancialStatus => 'عرض الوضع المالي';
  @override
  String get newAccount => 'حساب جديد';
  @override
  String get navExplore => 'الإعدادات';
  @override
  String get yourPoints => 'نقاطك';

  @override
  String get actionMedical => 'ممارس طبي؟';
  @override
  String get actionDonate => 'تبرّع!';
  @override
  String get actionAlert => 'خلّك نبيه';
  @override
  String get actionApple => 'Apple Arcade';
  @override
  String get actionNewCard => 'بطاقة جديدة';

  @override
  String get serviceTransfer => 'التحويل';
  @override
  String get serviceAccounts => 'الحسابات';
  @override
  String get serviceCards => 'البطاقات';
  @override
  String get serviceBills => 'الفواتير';
  @override
  String get serviceOffers => 'العروض';
  @override
  String get serviceFinance => 'التمويل';

  // Home dashboard: quick services pill row
  @override
  String get quickSendRemittance => 'إرسال حوالة';
  @override
  String get quickUnifiedNetwork => 'الشبكة الموحدة';

  // Beneficiaries
  @override
  String get beneficiaries => 'المستفيدون';
  @override
  String get addBeneficiary => 'إضافة مستفيد';
  @override
  String get beneficiaryName => 'اسم المستفيد';
  @override
  String get beneficiaryAccountOrIban => 'رقم الحساب أو الآيبان';
  @override
  String get beneficiaryNickname => 'الاسم المستعار';
  @override
  String get validateAccount => 'تحقق من الحساب';
  @override
  String get beneficiaryAddedSuccessfully => 'تم إضافة المستفيد بنجاح';
  @override
  String get emptyBeneficiaries => 'لا يوجد مستفيدون مضافون حالياً.';
  @override
  String get deleteBeneficiary => 'حذف المستفيد';
  @override
  String get beneficiaryDeleted => 'تم حذف المستفيد';
  @override
  String get confirmDeleteBeneficiary => 'هل أنت متأكد من حذف هذا المستفيد؟';
  @override
  String get transferToBeneficiary => 'تحويل';
  @override
  String get editBeneficiary => 'تعديل المستفيد';
  @override
  String get editBeneficiarySubtitle => 'تحديث بيانات المستفيد';
  @override
  String get beneficiaryUpdatedSuccessfully => 'تم تحديث المستفيد بنجاح';
  @override
  String get saveChanges => 'حفظ التغييرات';
  @override
  String get noChangesDetected => 'لم يتم اكتشاف أي تغييرات';
  @override
  String get verifyNewAccount => 'تحقق من الحساب الجديد';

  @override
  String get methodAccount => 'رقم الحساب';
  @override
  String get methodMobile => 'رقم الجوال';
  @override
  String get methodIban => 'رقم الآيبان';
  @override
  String get hintEnterAccount => 'أدخل رقم الحساب';
  @override
  String get hintEnterMobile => 'أدخل رقم الجوال';
  @override
  String get hintEnterIban => 'أدخل رقم الآيبان';
  @override
  String get validationEnterValue => 'الرجاء إدخال القيمة';
  @override
  String get localTransferSubtitle => 'تحويل محلي';
  @override
  String get verifyAccount => 'تحقق من الحساب';
  @override
  String get addBeneficiaryBy => 'إضافة المستفيد عن طريق';
  @override
  String get verifiedSecurelyNote => 'يتم التحقق بأمان عبر النظام المصرفي';
  @override
  String get change => 'تغيير';
  @override
  String get accountVerified => 'تم التحقق من الحساب';
  @override
  String get accountHolder => 'صاحب الحساب';
  @override
  String get nicknameOptional => 'الاسم المستعار (اختياري)';
  @override
  String get nicknameExample => 'مثال: عبدالله — الإيجار';
  @override
  String get currencyLabel => 'العملة';
  @override
  String get categoryElectricity => 'الكهرباء';
  @override
  String get categoryWater => 'المياه';
  @override
  String get categoryTelecom => 'الاتصالات';
  @override
  String get categoryGovernment => 'حكومي';
  @override
  String get categoryMobile => 'الجوال';
  @override
  String get categoryTraffic => 'المخالفات';
  @override
  String get categoryEducation => 'التعليم';
  @override
  String get categoryViewAll => 'عرض الكل';
  @override
  String get payBills => 'سداد الفواتير';
  @override
  String get searchBillersHint => 'ابحث عن جهة الفوترة';
  @override
  String get categories => 'الفئات';
  @override
  String get dueThisWeek => 'مستحقة هذا الأسبوع';
  @override
  String get electricityPec => 'الكهرباء — المؤسسة العامة';
  @override
  String get due24Jun => 'مستحقة · 24 يونيو';
  @override
  String get telecomYemenMobile => 'الاتصالات';
  @override
  String get due27Jun => 'مستحقة · 27 يونيو';
  @override
  String get paymentHistory => 'سجل المدفوعات';
  @override
  String get historyPecSubtitle => '12 يونيو · مدفوعة';
  @override
  String get historyWaterTitle => 'المياه — المحلية';
  @override
  String get historyWaterSubtitle => '08 يونيو · مدفوعة';
  @override
  String get payButton => 'ادفع';
  @override
  String get paidStatus => 'مدفوعة';
  @override
  String get comingSoonToast => 'هذه الخدمة قريباً';
  @override
  String get serviceStandingOrders => 'أوامر مستديمة';
  @override
  String get serviceSendGift => 'إرسال هدية';
  @override
  String get serviceCharity => 'جمعية خيرية';
  @override
  String get serviceTransferSettings => 'إعدادات التحويل';
  @override
  String get serviceInvestmentWallet => 'محفظة الاستثمار';
  @override
  String get btnNewBeneficiary => 'مستفيد جديد';
  @override
  String get servicesLabel => 'خدمات';
  @override
  String get recentTransfersLabel => 'آخر التحويلات';
  @override
  String get chooseDebitAccount => 'اختر حساب الخصم';
  @override
  String get chooseCreditAccount => 'اختر حساب الإيداع';
  @override
  String get hintBeneficiaryAccountOrIban => 'رقم حساب المستفيد أو الآيبان';
  @override
  String get exclusiveOffers => 'العروض الحصرية 🎁';
  @override
  String get cashBackTitle => 'استرداد نقدي 5% على المشتريات';
  @override
  String get cashBackSubtitle =>
      'استمتع باسترداد نقدي فوري على البطاقات الائتمانية';
  @override
  String get travelDiscountTitle => 'خصومات السفر تصل لـ 20%';
  @override
  String get travelDiscountSubtitle =>
      'احجز تذاكر الطيران والفنادق بأفضل الأسعار';
  @override
  String get financeCalculatorTitle => 'حاسبة التمويل الفوري 📈';
  @override
  String get financeCalculatorSubtitle =>
      'أنت مؤهل للحصول على تمويل شخصي فوري يصل إلى:';
  @override
  String get financeDisclaimer => '*تطبق الشروط والأحكام المصرفية.';
  @override
  String get closeButton => 'إغلاق';
  @override
  String get saudiRiyal => 'ريال سعودي';
  @override
  String get enableFingerprintTitle => 'تفعيل البصمة';
  @override
  String get enableFingerprintMessage =>
      'لتفعيل تسجيل الدخول بالبصمة، يرجى تسجيل الدخول بحسابك أولاً وتفعيل الخدمة من الإعدادات.';
  @override
  String get okButton => 'موافق';
  @override
  String get verifyingStatus => 'جارٍ التحقق...';
  @override
  String get biometricFailed => 'فشل التحقق البيومتري';
  @override
  String get enterRegisteredMobileHint => 'أدخل رقم الجوال المسجل';
  @override
  String get enterCustomerIdHint => 'أدخل معرف العميل في النظام المصرفي';

  // Notifications
  @override
  String get notificationsTitle => 'الإشعارات';
  @override
  String get notificationSettingsTitle => 'إعدادات الإشعارات';
  @override
  String get notificationsAllow => 'السماح بالإشعارات';
  @override
  String get notificationsTransfers => 'التحويلات';
  @override
  String get notificationsGeneral => 'التحديثات العامة';
  @override
  String get notificationsSecurityAlerts => 'التنبيهات الأمنية';
  @override
  String get notificationsComingSoon => 'قريباً';
  @override
  String get securityBlockedTitle => 'الجهاز غير آمن';
  @override
  String get securityBlockedMessage =>
      'يبدو أن هذا الجهاز مخترق (روت/جيلبريك أو تم العبث بالتطبيق). لحماية حساباتك، لا يمكن استخدام التطبيق على هذا الجهاز.';
  @override
  String get securityRestrictedTitle => 'العملية غير متاحة';
  @override
  String get securityRestrictedMessage =>
      'تم تعطيل هذه العملية لأن الجهاز لم يجتز فحص الأمان (روت/جيلبريك أو عبث بالتطبيق). استخدم جهازاً موثوقاً أو تواصل مع الدعم.';
  @override
  String get myCards => 'بطاقاتي';
  @override
  String get cardDetails => 'تفاصيل البطاقة';
  @override
  String get cardStatusActive => 'نشطة';
  @override
  String get cardStatusFrozen => 'مجمّدة';
  @override
  String get freezeCard => 'تجميد البطاقة';
  @override
  String get unfreezeCard => 'إلغاء التجميد';
  @override
  String get freezeCardConfirmTitle => 'تجميد هذه البطاقة؟';
  @override
  String get freezeCardConfirmMessage =>
      'سيتم رفض جميع عمليات الدفع والسحب الجديدة حتى تلغي التجميد. يمكنك إلغاء التجميد في أي وقت.';
  @override
  String get cardFrozenBanner =>
      'هذه البطاقة مجمّدة — جميع عمليات الدفع والسحب موقوفة.';
  @override
  String get cardFrozenToast => 'تم تجميد البطاقة';
  @override
  String get cardUnfrozenToast => 'تم إلغاء تجميد البطاقة';
  @override
  String get cardSettings => 'إعدادات البطاقة';
  @override
  String get onlinePayments => 'الدفع عبر الإنترنت';
  @override
  String get onlinePaymentsSubtitle =>
      'الشراء من المتاجر الإلكترونية والتطبيقات';
  @override
  String get contactlessPayments => 'الدفع اللاتلامسي';
  @override
  String get contactlessPaymentsSubtitle => 'الدفع بالتمرير في المتاجر';
  @override
  String get cardLimits => 'حدود البطاقة';
  @override
  String get dailyPurchaseLimit => 'حد الشراء اليومي';
  @override
  String get atmWithdrawalLimit => 'حد السحب اليومي من الصراف';
  @override
  String get limitUpdated => 'تم تحديث الحد';
  @override
  String get linkedAccount => 'الحساب المرتبط';
  @override
  String get noCardTransactions => 'لا توجد عمليات على هذه البطاقة بعد.';

  // ─── Bill payments (Section 7) ───
  @override
  String get serviceProviders => 'مزوّدو الخدمة';
  @override
  String get noProvidersFound => 'لا توجد نتائج مطابقة';
  @override
  String get subscriberNumberLabel => 'رقم المشترك';
  @override
  String get phoneNumberLabel => 'رقم الهاتف';
  @override
  String get billAccountNoLabel => 'رقم الحساب';
  @override
  String get invalidSubscriberNumber => 'صيغة الرقم غير صحيحة';
  @override
  String get inquireBill => 'استعلام';
  @override
  String get billDetails => 'تفاصيل الفاتورة';
  @override
  String get subscriberNameLabel => 'اسم المشترك';
  @override
  String get balanceDueLabel => 'المبلغ المستحق';
  @override
  String get availableCreditLabel => 'الرصيد المتاح';
  @override
  String get lineTypeLabel => 'نوع الخط';
  @override
  String get expiresLabel => 'تاريخ الانتهاء';
  @override
  String get minAmountLabel => 'الحد الأدنى';
  @override
  String get offersAndPackages => 'العروض والباقات';
  @override
  String get chooseOffer => 'اختر باقة';
  @override
  String get offersEmpty => 'لا توجد باقات متاحة حالياً';
  @override
  String get payAmountLabel => 'المبلغ';
  @override
  String get debitAccountLabel => 'الدفع من حساب';
  @override
  String get chooseAccount => 'اختر الحساب';
  @override
  String get reviewPayment => 'مراجعة العملية';
  @override
  String get confirmWithPin => 'التأكيد بالرقم السري';
  @override
  String get payNow => 'ادفع الآن';
  @override
  String get telecomPaymentTitle => 'سداد الاتصالات';
  @override
  String get payServicesSheetTitle => 'سداد خدمات';
  @override
  String get serviceTypeLabel => 'نوع الخدمة';
  @override
  String get packageTypeLabel => 'نوع الباقة';
  @override
  String get fromAccountLabel => 'من حساب';
  @override
  String get executeOperation => 'تنفيذ العملية';
  @override
  String get balanceInquiry => 'الاستعلام عن الرصيد';
  @override
  String get landlinePaymentTitle => 'سداد الهاتف الثابت';
  @override
  String get internetPaymentTitle => 'سداد الانترنت';
  @override
  String get categoryLandline => 'الهاتف الثابت';
  @override
  String get enterPhoneForServices => 'أدخل رقم الهاتف لعرض الخدمات';
  @override
  String get paymentSuccessful => 'تمت العملية بنجاح';
  @override
  String get paymentPendingTitle => 'العملية قيد التنفيذ';
  @override
  String get paymentPendingBody =>
      'المزوّد يعالج عمليتك الآن، وستتحدّث حالتها تلقائياً في سجل المدفوعات.';
  @override
  String get paymentFailed => 'فشلت العملية';
  @override
  String get referenceNumberLabel => 'رقم المرجع';
  @override
  String get providerReferenceLabel => 'مرجع المزوّد';
  @override
  String get checkStatus => 'تحديث الحالة';
  @override
  String get shareBillReceipt => 'مشاركة الإيصال';
  @override
  String get billPaymentHistoryEmpty => 'لا توجد مدفوعات بعد.';
  @override
  String get statusFailed => 'فشلت';
  @override
  String get unMoneyTitle => 'الشبكة الموحدة UN Money';
  @override
  String get networkTransfersTitle => 'حوالات الشبكات';
  @override
  String get unMoneySend => 'إرسال حوالة';
  @override
  String get unMoneySendSubtitle => 'إلى أي محفظة أو وكيل UN Money';
  @override
  String get unMoneyReceive => 'استلام حوالة';
  @override
  String get unMoneyReceiveSubtitle => 'إيداع حوالة مستلمة في حسابك';
  @override
  String get unMoneyHistory => 'سجل الحوالات';
  @override
  String get unMoneyRecipientLabel => 'رقم هاتف المستلم';
  @override
  String get unMoneyPickupCode => 'رمز الحوالة';
  @override
  String get unMoneyLookup => 'البحث عن الحوالة';
  @override
  String get unMoneyReceiveConfirm => 'إيداع في حسابي';
  @override
  String get unifiedNetworkCancelTile => 'إلغاء حوالة';
  @override
  String get unifiedNetworkSendTile => 'إرسال حوالة';
  @override
  String get unifiedNetworkPayTile => 'دفع إلى حساب';
  @override
  String get unifiedNetworkSendTitle => 'إرسال حوالة';
  @override
  String get unifiedNetworkPayTitle => 'دفع إلى حساب';
  @override
  String get unifiedNetworkCancelTitle => 'إلغاء حوالة';
  @override
  String get tabTransferToBeneficiary => 'التحويل لمستفيد';
  @override
  String get tabSendUnifiedNetwork => 'ارسال حوالة الشبكة الموحدة';
  @override
  String get beneficiaryNameLabel => 'اسم المستفيد';
  @override
  String get beneficiaryNumberLabel => 'رقم المستفيد';
  @override
  String get transferPurposeLabel => 'الغرض من التحويل';
  @override
  String get purposePersonal => 'شخصي';
  @override
  String get purposeWork => 'عمل';
  @override
  String get transferNotesWarning =>
      'تحذير: الملاحظات المُدوَّنة هنا ستظهر في كشف حسابك و تظهر عند المستلم، وسيتم أرشفتها لدينا.';
  @override
  String get transferNotesHint => 'أضف ملاحظة';
  @override
  String get depositAccountLabel => 'الحساب المراد الايداع إليه';
  @override
  String get referenceNumberHint => 'الرجاء ادخال رقم المرجع';
  @override
  String get depositNoteLine1 =>
      '1- يجب ان تكون البيانات المدخلة هنا مطابقة لبيانات الحوالة';
  @override
  String get depositNoteLine2 =>
      '2- يجب ان تكون بيانات المسلم في الحوالة مطابقة لبيانات حسابك';
  @override
  String get transferNumberHint => 'ادخل رقم الحوالة';
  @override
  String get confirmLabel => 'موافق';
  @override
  String get categoryInternet => 'الإنترنت';
  @override
  String get categoryMoneyTransfer => 'الحوالات';
  @override
  String get categoryEntertainment => 'الترفيه';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' ||
      locale.languageCode == 'ar' ||
      locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return AppLocalizationsZh();
      case 'ar':
        return AppLocalizationsAr();
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
