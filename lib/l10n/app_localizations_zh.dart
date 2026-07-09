import 'app_localizations.dart';

class AppLocalizationsZh extends AppLocalizations {
  @override
  String get appTitle => 'Ultimate Wallet';

  // ── «Ultimate Wallet» wallet ──────────────────────────────────────────────
  @override
  String get walletBalanceLabel => '钱包余额';
  @override
  String get walletActionSend => '发送';
  @override
  String get walletActionReceive => '收款';
  @override
  String get walletActionTopUp => '充值';
  @override
  String get walletActionScan => '扫码';
  @override
  String get walletServicesTitle => '服务';
  @override
  String get walletPayBills => '账单';
  @override
  String get walletTransferToBank => '银行转账';
  @override
  String get walletBeneficiaries => '受益人';
  @override
  String get walletFavorites => '收藏';
  @override
  String get walletRecentActivity => '最近交易';
  @override
  String get walletNoRecentActivity => '暂无交易';
  @override
  String get walletReceiveTitle => '收款';
  @override
  String get walletReceiveShareHint => '分享此二维码以向您的钱包收款';
  @override
  String get walletNumberLabel => '钱包号码';
  @override
  String get walletRetry => '重试';
  @override
  String get walletMyWallets => '我的钱包';
  @override
  String get walletQuickAccessTitle => '快速访问';
  @override
  String get walletPromotionsTitle => '优惠活动';
  @override
  String get walletComingSoon => '即将推出';
  @override
  String get walletAddFavorite => '添加收藏';
  @override
  String get walletServiceInternet => '互联网';
  @override
  String get walletCurrencySar => '沙特里亚尔';
  @override
  String get walletCurrencyYer => '也门里亚尔';
  @override
  String get walletCurrencyUsd => '美元';

  @override
  String get navHome => '首页';

  @override
  String get navTransfers => '转账';

  @override
  String get navPayments => '支付';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageChinese => '中文';

  @override
  String get security => '安全';

  @override
  String get sessionTimeout => '会话超时';

  @override
  String get sessionTimeoutSubtitle => '闲置一段时间后自动退出登录';

  @override
  String get sessionTimeoutUpdated => '会话超时已更新';

  @override
  String sessionTimeoutMinutesLabel(int minutes) => '$minutes 分钟';

  @override
  String get sessionExpiredMessage => '会话已过期，请重新登录。';

  @override
  String get reloginPasswordChangeRequired =>
      '您的密码为临时密码，必须更改。请点击取消，然后从登录页面重新登录以设置新密码。';

  @override
  String get reloginFailedGeneric => '登录失败，请重试。';

  @override
  String get serverUnreachableMessage => '目前无法连接服务器，请检查网络后下拉重试。';

  @override
  String get biometricLogin => '生物识别登录';

  @override
  String get biometricLoginSubtitle => '使用指纹或面容登录';

  @override
  String get changePin => '修改交易密码';

  @override
  String get changePinSubtitle => '更新您的交易 PIN';

  @override
  String get forgotPin => '忘记交易密码';

  @override
  String get forgotPinSubtitle => '使用登录密码重置交易 PIN';

  @override
  String get account => '账户';

  @override
  String get profile => '个人资料';

  @override
  String get profileSubtitle => '查看您的个人信息';

  @override
  String get copied => '已复制';

  @override
  String get defaultAccountsTitle => '默认账户';

  @override
  String get defaultAccountsSubtitle => '选择主账户及每种货币的默认账户。';

  @override
  String get defaultAccountsSettingsSubtitle => '主账户与各币种默认';

  @override
  String get defaultAccountsGlobal => '主账户（所有币种）';

  @override
  String get defaultAccountsPerCurrency => '各币种默认';

  @override
  String get saveDefaultAccounts => '保存默认账户';

  @override
  String get defaultAccountsSaved => '已保存默认账户';

  @override
  String get saving => '保存中…';

  @override
  String get resetPassword => '重置密码';

  @override
  String get resetPasswordSubtitle => '通过注册手机号重置密码';

  @override
  String get signOut => '退出登录';

  @override
  String get helpSupport => '帮助与支持';

  @override
  String get helpSupportSubtitle => '联系客户服务';

  @override
  String get termsAndConditions => '条款和条件';

  @override
  String get termsAndConditionsSubtitle => '电子钱包账户政策';

  @override
  String get termsAndConditionsFooter => '本文件仅供参考，请以正式批准的版本为准。';

  @override
  String get supportTitle => '支持';

  @override
  String get supportNewCase => '新建工单';

  @override
  String get supportSubject => '主题';

  @override
  String get supportMessage => '消息';

  @override
  String get supportSubmit => '提交';

  @override
  String get supportNoCases => '暂无支持工单。';

  @override
  String get supportReply => '回复';

  @override
  String get supportSend => '发送';

  @override
  String get supportCaseNumber => '工单编号';

  @override
  String get needHelp => '需要帮助？';

  @override
  String get trackExistingCase => '查询已有工单';

  @override
  String get guestName => '您的姓名';

  @override
  String get guestMobile => '手机号';

  @override
  String get supportCreatedTitle => '工单已提交';

  @override
  String supportCreatedBody(String caseNumber) =>
      '工单 $caseNumber 已创建。请保存此编号以查看回复。';

  @override
  String get supportQueued => '排队等待中 — 尚未分配客服';

  @override
  String supportAssignedTo(String name) => '已分配给 $name';

  @override
  String get supportWaitingForYou => '等待您的回复';

  @override
  String get supportSeen => '已读';

  @override
  String get supportDelivered => '已发送';

  @override
  String get enterTransactionPin => '输入交易 PIN';

  @override
  String get pinRequiredEnableBiometric => '启用生物识别登录需要验证';

  @override
  String get pinRequiredDisableBiometric => '关闭生物识别登录需要验证';

  @override
  String get biometricEnabled => '已启用生物识别登录';

  @override
  String get biometricSetupCancelled => '生物识别设置已取消';

  @override
  String get biometricDisabled => '已关闭生物识别登录';

  @override
  String get transferToMyAccounts => '转至本人账户';

  @override
  String get transferToOthers => '转至他人';

  @override
  String get addAccount => '添加账户';

  @override
  String get addAccountDesc => '以其他币种或类型开立附加账户 — 即将推出。';

  @override
  String get betweenYourAccounts => '本人账户互转';

  @override
  String get betweenYourAccountsSubtitle => '在您自己的账户之间转账';

  @override
  String get toAnotherAccount => '转至其他账户';

  @override
  String get toAnotherAccountSubtitle => '向外部收款人转账';

  @override
  String get debitAccount => '付款账户';

  @override
  String get creditAccount => '收款账户';

  @override
  String get beneficiaryAccount => '收款人账户';

  @override
  String get amount => '金额';

  @override
  String get transferMax => '全额转账';

  @override
  String get reviewTransfer => '确认转账';

  @override
  String get dealRate => '汇率';

  @override
  String get youSend => '您发送';

  @override
  String get recipientGets => '收款人收到';

  @override
  String get fetchingRate => '正在获取汇率…';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get noAccountsForTransfer => '没有可用于转账的账户。';

  @override
  String get needTwoAccounts => '本人账户互转至少需要两个账户。';

  @override
  String get chooseAccountsAndAmount => '选择付款和收款账户并输入金额';

  @override
  String get chooseDebitBeneficiaryAmount => '选择付款账户、收款人账户和金额';

  @override
  String get fromLabel => '从';

  @override
  String get toLabel => '至';

  @override
  String get confirmTransfer => '确认转账';

  @override
  String get validationDetails => '验证详情';

  @override
  String get editDetails => '修改信息';

  @override
  String get authorizeTransfer => '授权转账';

  @override
  String get enterPinToComplete => '输入交易 PIN 以完成操作';

  @override
  String get transferComplete => '转账完成';

  @override
  String get saveReferenceHint => '请保存此参考号以备查询';

  @override
  String get reference => '参考号';

  @override
  String get referenceCopied => '参考号已复制';

  @override
  String get copyReference => '复制参考号';

  @override
  String get newTransfer => '新建转账';

  @override
  String get customerIdMissing => '个人资料中缺少客户编号。';

  @override
  String get noAccountsFound => '未找到账户。';

  @override
  String get allAccounts => '所有账户';

  @override
  String get searchAccounts => '搜索账户';

  @override
  String get noMatchingAccounts => '没有匹配的账户。';

  @override
  String get hideZeroBalances => '隐藏零余额';

  @override
  String accountsCount(int count) => '$count 个账户';

  @override
  String get yourCards => '您的银行卡';

  @override
  String get viewAll => '查看全部';

  @override
  String get recentTransactions => '最近交易';

  @override
  String get recentTransfers => '最近转账';

  @override
  String get transferAgain => '再次转账';

  @override
  String get noRecentTransfers => '暂无最近转账。';

  @override
  String get favoritesLabel => '收藏';

  @override
  String get removeFavorite => '从收藏中移除';

  @override
  String get favoritesEmpty => '还没有收藏。将转账对象加为星标即可显示在此处。';

  @override
  String get transferOthersSubtitle => '转给其他客户或收款人';

  @override
  String get addAccountSubtitle => '开设新的活期或储蓄账户';

  @override
  String get cancel => '取消';

  @override
  String get quickSend => '付款';

  @override
  String get quickRequest => '收款';

  @override
  String get quickQr => '二维码';

  @override
  String get quickHistory => '记录';

  @override
  String get featureComingSoonTitle => '即将推出';

  @override
  String get featureComingSoonMessage => '这些功能即将上线。';

  @override
  String get debitCard => '借记卡';

  @override
  String get creditCard => '信用卡';

  @override
  String get details => '详情';

  @override
  String get scanToPay => '扫码支付';

  @override
  String get shareQrForTransfers => '分享此二维码以向该账户转账';

  @override
  String get accountNumberCopied => '账号已复制';

  @override
  String get statusPending => '处理中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get txnRetailPurchase => '零售消费';

  @override
  String get txnIncomingTransfer => '转入';

  @override
  String get txnPosPayment => 'POS 支付';

  @override
  String get txnToday => '今天 14:45';

  @override
  String get txnYesterday => '昨天 09:00';

  @override
  String get txnMar12 => '3月12日 08:15';

  @override
  String get noTransactionsForAccount => '该账户暂无最近交易。';

  @override
  String transactionsShowingCount(int shown, int total) => '$shown / $total';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get accountStatement => '账户对账单';

  @override
  String get searchTransactions => '搜索交易';

  @override
  String get filterAll => '全部';

  @override
  String get filterIncoming => '收入';

  @override
  String get filterOutgoing => '支出';

  @override
  String get noMatchingTransactions => '没有匹配的交易。';

  @override
  String transactionsCount(int count) => '$count 笔交易';

  @override
  String accountsPageIndicator(int current, int total) => '$current / $total';

  @override
  String get secureMobileBanking => '安全移动银行';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signInWithUsernamePassword => '使用用户名和密码登录。';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '例如 1019 或 osama.ibrahim';

  @override
  String get enterUsername => '请输入用户名';

  @override
  String get password => '密码';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get signInAfterPasswordResetBanner =>
      '请使用临时密码登录。系统将要求您设置新密码，然后设置交易 PIN。';

  @override
  String get signIn => '登录';

  @override
  String get opening => '正在打开…';

  @override
  String get signInWithBiometrics => '生物识别登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get newCustomerRegister => '新用户？立即注册';

  @override
  String get loginTabCustomer => '客户';

  @override
  String get loginTabMerchant => '销售点';

  @override
  String get mobileNumberHint => '例如 777563940';

  @override
  String get enterMobileNumber => '请输入手机号码';

  @override
  String get signInAsCustomer => '以客户身份登录';

  @override
  String get dontHaveAccount => '没有账户？';

  @override
  String get createAccount => '创建账户';

  @override
  String get supportTollFree => '免费电话';

  @override
  String get supportServicePoints => '服务网点';

  @override
  String get supportCustomerService => '客户服务';

  @override
  String get merchantLoginComingSoon => '销售点登录即将推出。';

  @override
  String get biometricSignIn => '生物识别登录';

  @override
  String get biometricSignInSubtitle => '使用指纹或面容访问您的账户。';

  @override
  String get confirmYourIdentity => '验证身份';

  @override
  String get biometricPromptMessage => '设备将提示您进行生物识别验证。';

  @override
  String get pleaseWait => '请稍候…';

  @override
  String get unlock => '解锁';

  @override
  String get usePasswordInstead => '改用密码登录';

  @override
  String get biometricVerificationFailed => '生物识别验证失败';

  @override
  String get enableBiometricLoginTitle => '启用生物识别登录';

  @override
  String get enableBiometricLoginSubtitle => '使用指纹或面容更快登录。注册时需验证一次交易 PIN。';

  @override
  String get biometricEnrollPinSubtitle => '输入交易 PIN 以启用生物识别';

  @override
  String get skipForNow => '暂时跳过';

  @override
  String get biometricLoginEnabledMessage => '已启用生物识别登录，下次可使用生物识别登录。';

  @override
  String get biometricSetupUnavailable => '生物识别设置已取消或不可用';

  @override
  String get enterYourPin => '输入您的 PIN';

  @override
  String get registerTitle => '注册';

  @override
  String get createYourAccount => '创建账户';

  @override
  String get registrationSubtitle => '输入核心银行客户编号以获取您的资料。';

  @override
  String get coreCustomerId => '客户编号';

  @override
  String get coreCustomerIdHint => '例如 000001295';

  @override
  String get enterCoreCustomerId => '请输入核心银行客户编号';

  @override
  String get fetchProfile => '获取资料';

  @override
  String get fullName => '姓名';

  @override
  String get mobile => '手机号';

  @override
  String get gender => '性别';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get mobileLoginUsername => '手机银行用户名';

  @override
  String get coreCustomerIdOption => '客户编号';

  @override
  String get customUsername => '自定义用户名';

  @override
  String get customUsernameHint => '例如 osama.ibrahim';

  @override
  String get customUsernameRules => '3–64 个字符：字母、数字、点、下划线和连字符。';

  @override
  String get changeId => '更换编号';

  @override
  String get registerButton => '注册';

  @override
  String get enterCustomUsername => '请输入自定义用户名';

  @override
  String get registrationUsernameMissing => '注册成功但缺少用户名';

  @override
  String get alreadyHaveAccountSignIn => '已有账户？登录';

  @override
  String get registerWelcomeTitle => '欢迎来到 Ultimate Wallet';

  @override
  String get registerWelcomeSubtitle => '创建您的账户，加入 Ultimate Wallet 客户';

  @override
  String get registerNameAsIdHint => '请按身份证件填写姓名';

  @override
  String get firstName => '名字';

  @override
  String get secondName => '第二名字';

  @override
  String get thirdName => '第三名字';

  @override
  String get surname => '姓氏';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get agreeToTerms => '我同意条款和条件';

  @override
  String get createAccountButton => '创建账户';

  @override
  String get customerService => '客户服务';

  @override
  String get servicePoints => '服务网点';

  @override
  String get tollFreeNumber => '免费电话';

  @override
  String get mustAgreeToTerms => '您必须同意条款和条件';

  @override
  String get requiredField => '必填';

  @override
  String get activationTitle => 'Ultimate Wallet 账户激活码';

  @override
  String activationSubtitle(String mobile) => '我们已向您的手机 $mobile 发送了包含激活码的短信';

  @override
  String get activationExpiresIn => '确认码将在以下时间后失效';

  @override
  String get didntReceiveCode => '没有收到验证码？';

  @override
  String get contactCustomerService => '联系客户服务';

  @override
  String get activationConfirm => '确认';

  @override
  String get kycBannerText =>
      '您的账户尚未验证 — 请完善资料以激活钱包。';

  @override
  String get kycVerifyAccount => '验证账户';

  @override
  String get kycTitle => '账户验证';

  @override
  String get kycSubtitle => '上传您的证件照片以验证身份';

  @override
  String get kycIdFront => '身份证 — 正面';

  @override
  String get kycIdBack => '身份证 — 背面';

  @override
  String get kycSelfie => '自拍照';

  @override
  String get kycUploadHint => '点击上传';

  @override
  String get kycCamera => '相机';

  @override
  String get kycGallery => '相册';

  @override
  String get kycSubmit => '提交验证';

  @override
  String get kycSubmitted => '您的证件已提交，将尽快审核。';

  @override
  String get forgotPasswordTitle => '忘记密码';

  @override
  String get resetPasswordHeading => '重置密码';

  @override
  String get resetPasswordDescription => '输入与账户关联的手机号。所有设备上的生物识别登录将被清除。';

  @override
  String get mobileNumber => '手机号';

  @override
  String get enterRegisteredMobile => '请输入注册手机号';

  @override
  String get resetPasswordSuccess => '密码已重置。请使用临时密码登录（通常为客户编号），然后设置新密码和交易 PIN。';

  @override
  String get requestReset => '申请重置';

  @override
  String get backToSignIn => '返回登录';

  @override
  String get setPasswordTitle => '设置密码';

  @override
  String get createYourPassword => '创建密码';

  @override
  String get setPasswordSubtitle => '继续前必须更改临时密码。';

  @override
  String usernameLabel(String username) => '用户名：$username';

  @override
  String get newPassword => '新密码';

  @override
  String get passwordLengthHint => '8–64 个字符';

  @override
  String get atLeast8Characters => '至少 8 个字符';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get passwordNotAccepted => '密码未被接受，请重试或联系客服。';

  @override
  String get saveAndContinue => '保存并继续';

  @override
  String get transactionPinTitle => '交易 PIN';

  @override
  String get transactionPinSubtitle => '用于授权转账。您的设备将注册以保障安全访问。';

  @override
  String get confirmYourPin => '确认 PIN';

  @override
  String get createYourPin => '创建 PIN';

  @override
  String get confirmPinSubtitle => '请再次输入相同的 4–6 位 PIN';

  @override
  String get choosePinSubtitle => '请设置 4–6 位转账 PIN';

  @override
  String get pinsDoNotMatch => '两次输入的 PIN 不一致';

  @override
  String get continueLabel => '继续';

  @override
  String get totalBalance => '总余额';
  @override
  String get clickToAccess => '点击此处获取';
  @override
  String get viewFinancialStatus => '查看财务状况';
  @override
  String get newAccount => '新账户';
  @override
  String get navExplore => '设置';
  @override
  String get yourPoints => '您的积分';

  @override
  String get actionMedical => '医疗执业人员？';
  @override
  String get actionDonate => '捐赠！';
  @override
  String get actionAlert => '保持警惕！';
  @override
  String get actionApple => 'Apple Arcade';
  @override
  String get actionNewCard => '新卡';

  @override
  String get serviceTransfer => '转账';
  @override
  String get serviceAccounts => '账户';
  @override
  String get serviceCards => '卡片';
  @override
  String get serviceBills => '账单';
  @override
  String get serviceOffers => '优惠';
  @override
  String get serviceFinance => '理财';

  // Home dashboard: quick services pill row
  @override
  String get quickSendRemittance => '发送汇款';
  @override
  String get quickUnifiedNetwork => '统一网络';

  // Beneficiaries
  @override
  String get beneficiaries => '收款人';
  @override
  String get addBeneficiary => '添加收款人';
  @override
  String get beneficiaryName => '收款人姓名';
  @override
  String get beneficiaryAccountOrIban => '账号或国际银行账号(IBAN)';
  @override
  String get beneficiaryNickname => '备注/别名';
  @override
  String get validateAccount => '验证账户';
  @override
  String get beneficiaryAddedSuccessfully => '成功添加收款人';
  @override
  String get emptyBeneficiaries => '暂无保存的收款人。';
  @override
  String get deleteBeneficiary => '删除收款人';
  @override
  String get beneficiaryDeleted => '收款人已删除';
  @override
  String get confirmDeleteBeneficiary => '确定要删除该收款人吗？';
  @override
  String get transferToBeneficiary => '转账';
  @override
  String get editBeneficiary => '编辑收款人';
  @override
  String get editBeneficiarySubtitle => '更新收款人信息';
  @override
  String get beneficiaryUpdatedSuccessfully => '收款人更新成功';
  @override
  String get saveChanges => '保存更改';
  @override
  String get noChangesDetected => '未检测到更改';
  @override
  String get verifyNewAccount => '验证新账户';


  @override
  String get methodAccount => '账号';
  @override
  String get methodMobile => '手机号';
  @override
  String get methodIban => 'IBAN';
  @override
  String get hintEnterAccount => '输入账号';
  @override
  String get hintEnterMobile => '输入手机号码';
  @override
  String get hintEnterIban => '输入 IBAN';
  @override
  String get validationEnterValue => '请输入内容';
  @override
  String get localTransferSubtitle => '本地转账 · 沙特阿拉伯境内';
  @override
  String get verifyAccount => '验证账户';
  @override
  String get addBeneficiaryBy => '添加收款人方式';
  @override
  String get verifiedSecurelyNote => '已通过核心银行系统进行安全验证';
  @override
  String get change => '更改';
  @override
  String get accountVerified => '账户已验证';
  @override
  String get accountHolder => '账户持有者';
  @override
  String get nicknameOptional => '昵称（可选）';
  @override
  String get nicknameExample => '例如 Abdullah — 房租';
  @override
  String get currencyLabel => '币种';
  @override
  String get categoryElectricity => '电费';
  @override
  String get categoryWater => '水费';
  @override
  String get categoryTelecom => '电信';
  @override
  String get categoryGovernment => '政府';
  @override
  String get categoryMobile => '手机';
  @override
  String get categoryTraffic => '交通';
  @override
  String get categoryEducation => '教育';
  @override
  String get categoryViewAll => '查看全部';
  @override
  String get payBills => '支付账单';
  @override
  String get searchBillersHint => '搜索账单机构';
  @override
  String get categories => '分类';
  @override
  String get dueThisWeek => '本周到期';
  @override
  String get electricityPec => '电费 — PEC';
  @override
  String get due24Jun => '到期日 · 6月24日';
  @override
  String get telecomYemenMobile => '电信';
  @override
  String get due27Jun => '到期日 · 6月27日';
  @override
  String get paymentHistory => '支付历史';
  @override
  String get historyPecSubtitle => '6月12日 · 已付';
  @override
  String get historyWaterTitle => '水费 — 地方企业';
  @override
  String get historyWaterSubtitle => '6月08日 · 已付';
  @override
  String get payButton => '支付';
  @override
  String get paidStatus => '已付';
  @override
  String get comingSoonToast => '敬请期待';
  @override
  String get serviceStandingOrders => '定期存单 / 常规指令';
  @override
  String get serviceSendGift => '发送礼物';
  @override
  String get serviceCharity => '慈善捐款';
  @override
  String get serviceTransferSettings => '转账设置';
  @override
  String get serviceInvestmentWallet => '投资钱包';
  @override
  String get btnNewBeneficiary => '新收款人';
  @override
  String get servicesLabel => '服务';
  @override
  String get recentTransfersLabel => '最近转账';
  @override
  String get chooseDebitAccount => '选择付款账户';
  @override
  String get chooseCreditAccount => '选择收款账户';
  @override
  String get hintBeneficiaryAccountOrIban => '收款人账户或 IBAN';
  @override
  String get exclusiveOffers => '专属优惠 🎁';
  @override
  String get cashBackTitle => '消费可享 5% 现金返还';
  @override
  String get cashBackSubtitle => '享受信用卡即时现金返还';
  @override
  String get travelDiscountTitle => '旅游折扣高达 20%';
  @override
  String get travelDiscountSubtitle => '以最优惠的价格预订机票 and 酒店';
  @override
  String get financeCalculatorTitle => '即时财务计算器 📈';
  @override
  String get financeCalculatorSubtitle => '您有资格获得高达以下额度的即时个人贷款：';
  @override
  String get financeDisclaimer => '*适用银行条款与条件。';
  @override
  String get closeButton => '关闭';
  @override
  String get saudiRiyal => '沙特里亚尔 (SAR)';
  @override
  String get enableFingerprintTitle => '启用指纹';
  @override
  String get enableFingerprintMessage => '要启用指纹登录，请先登录您的账户，并在设置中激活该功能。';
  @override
  String get okButton => '确定';
  @override
  String get verifyingStatus => '正在验证...';
  @override
  String get biometricFailed => '生物识别验证失败';
  @override
  String get enterRegisteredMobileHint => '输入绑定的手机号码';
  @override
  String get enterCustomerIdHint => '输入您在银行系统中的客户 ID';

  // Notifications
  @override String get notificationsTitle => '通知';
  @override String get notificationSettingsTitle => '通知设置';
  @override String get notificationsAllow => '允许通知';
  @override String get notificationsTransfers => '转账';
  @override String get notificationsGeneral => '通用更新';
  @override String get notificationsSecurityAlerts => '安全提醒';
  @override String get notificationsComingSoon => '敬请期待';
  @override
  String get securityBlockedTitle => '设备不安全';
  @override
  String get securityBlockedMessage =>
      '检测到此设备可能已被入侵（Root/越狱或应用被篡改）。为保护您的账户，无法在此设备上使用本应用。';
  @override
  String get securityRestrictedTitle => '操作不可用';
  @override
  String get securityRestrictedMessage =>
      '由于设备未通过安全检查（如检测到 Root/越狱或篡改），此操作已被禁用。请使用受信任的设备或联系客服。';
  @override
  String get myCards => '我的卡片';
  @override
  String get cardDetails => '卡片详情';
  @override
  String get cardStatusActive => '有效';
  @override
  String get cardStatusFrozen => '已冻结';
  @override
  String get freezeCard => '冻结卡片';
  @override
  String get unfreezeCard => '解冻卡片';
  @override
  String get freezeCardConfirmTitle => '确定冻结此卡？';
  @override
  String get freezeCardConfirmMessage => '冻结后，所有新的支付和取款都将被拒绝，您可以随时解冻。';
  @override
  String get cardFrozenBanner => '此卡已冻结——所有支付和取款均已停止。';
  @override
  String get cardFrozenToast => '卡片已冻结';
  @override
  String get cardUnfrozenToast => '卡片已解冻';
  @override
  String get cardSettings => '卡片设置';
  @override
  String get onlinePayments => '线上支付';
  @override
  String get onlinePaymentsSubtitle => '电商与应用内购买';
  @override
  String get contactlessPayments => '非接触式支付';
  @override
  String get contactlessPaymentsSubtitle => '商店感应支付';
  @override
  String get cardLimits => '卡片限额';
  @override
  String get dailyPurchaseLimit => '每日消费限额';
  @override
  String get atmWithdrawalLimit => '每日 ATM 取款限额';
  @override
  String get limitUpdated => '限额已更新';
  @override
  String get linkedAccount => '关联账户';
  @override
  String get noCardTransactions => '此卡暂无交易记录。';

  // ─── Bill payments (Section 7) ───
  @override
  String get serviceProviders => '服务提供商';
  @override
  String get noProvidersFound => '未找到匹配的服务商';
  @override
  String get subscriberNumberLabel => '用户编号';
  @override
  String get phoneNumberLabel => '电话号码';
  @override
  String get billAccountNoLabel => '账号';
  @override
  String get invalidSubscriberNumber => '号码格式不正确';
  @override
  String get inquireBill => '查询账单';
  @override
  String get billDetails => '账单详情';
  @override
  String get subscriberNameLabel => '用户姓名';
  @override
  String get balanceDueLabel => '应付金额';
  @override
  String get availableCreditLabel => '可用额度';
  @override
  String get lineTypeLabel => '线路类型';
  @override
  String get expiresLabel => '到期日';
  @override
  String get minAmountLabel => '最低金额';
  @override
  String get offersAndPackages => '优惠与套餐';
  @override
  String get chooseOffer => '选择套餐';
  @override
  String get offersEmpty => '暂无可用套餐';
  @override
  String get payAmountLabel => '金额';
  @override
  String get debitAccountLabel => '付款账户';
  @override
  String get chooseAccount => '选择账户';
  @override
  String get reviewPayment => '确认付款';
  @override
  String get confirmWithPin => '使用交易密码确认';
  @override
  String get payNow => '立即支付';
  @override
  String get telecomPaymentTitle => '电信缴费';
  @override
  String get payServicesSheetTitle => '缴费服务';
  @override
  String get serviceTypeLabel => '服务类型';
  @override
  String get packageTypeLabel => '套餐类型';
  @override
  String get fromAccountLabel => '付款账户';
  @override
  String get executeOperation => '执行操作';
  @override
  String get balanceInquiry => '余额查询';
  @override
  String get landlinePaymentTitle => '固话缴费';
  @override
  String get internetPaymentTitle => '网络缴费';
  @override
  String get categoryLandline => '固定电话';
  @override
  String get enterPhoneForServices => '输入电话号码以查看服务';
  @override
  String get paymentSuccessful => '支付成功';
  @override
  String get paymentPendingTitle => '支付处理中';
  @override
  String get paymentPendingBody => '服务商正在处理您的付款，状态将在付款记录中自动更新。';
  @override
  String get paymentFailed => '支付失败';
  @override
  String get referenceNumberLabel => '参考编号';
  @override
  String get providerReferenceLabel => '服务商参考号';
  @override
  String get checkStatus => '检查状态';
  @override
  String get shareBillReceipt => '分享回执';
  @override
  String get billPaymentHistoryEmpty => '暂无付款记录。';
  @override
  String get statusFailed => '失败';
  @override
  String get unMoneyTitle => 'UN Money 汇款网络';
  @override
  String get networkTransfersTitle => '网络转账';
  @override
  String get unMoneySend => '汇出资金';
  @override
  String get unMoneySendSubtitle => '汇至任意 UN Money 钱包或代理点';
  @override
  String get unMoneyReceive => '接收资金';
  @override
  String get unMoneyReceiveSubtitle => '将收到的汇款存入您的账户';
  @override
  String get unMoneyHistory => '汇款记录';
  @override
  String get unMoneyRecipientLabel => '收款人电话号码';
  @override
  String get unMoneyPickupCode => '汇款编码';
  @override
  String get unMoneyLookup => '查询汇款';
  @override
  String get unMoneyReceiveConfirm => '存入我的账户';
  @override
  String get unifiedNetworkCancelTile => '取消汇款';
  @override
  String get unifiedNetworkSendTile => '发送汇款';
  @override
  String get unifiedNetworkPayTile => '存入账户';
  @override
  String get unifiedNetworkSendTitle => '发送汇款';
  @override
  String get unifiedNetworkPayTitle => '存入账户';
  @override
  String get unifiedNetworkCancelTitle => '取消汇款';
  @override
  String get tabTransferToBeneficiary => '转账给受益人';
  @override
  String get tabSendUnifiedNetwork => '发送统一网络汇款';
  @override
  String get beneficiaryNameLabel => '受益人姓名';
  @override
  String get beneficiaryNumberLabel => '受益人号码';
  @override
  String get transferPurposeLabel => '转账目的';
  @override
  String get purposePersonal => '个人';
  @override
  String get purposeWork => '工作';
  @override
  String get transferNotesWarning => '警告：此处填写的备注将显示在您的对账单中，并对收款人可见，我们也会予以存档。';
  @override
  String get transferNotesHint => '添加备注';
  @override
  String get depositAccountLabel => '存入账户';
  @override
  String get referenceNumberHint => '请输入参考号';
  @override
  String get depositNoteLine1 => '1- 输入的信息必须与汇款信息一致。';
  @override
  String get depositNoteLine2 => '2- 收款人信息必须与您的账户信息一致。';
  @override
  String get transferNumberHint => '请输入汇款编号';
  @override
  String get confirmLabel => '确认';
  @override
  String get categoryInternet => '互联网';
  @override
  String get categoryMoneyTransfer => '汇款';
  @override
  String get categoryEntertainment => '娱乐';
}
