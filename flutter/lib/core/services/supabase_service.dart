import 'package:flutter/foundation.dart';

/// Supabase 云服务抽象 — Phase 4 产品化组件
///
/// 使用方式：
/// 1. 在 https://supabase.com 创建项目
/// 2. 将 URL 和 anonKey 填入下方常量
/// 3. 取消 init() 中 Supabase.initialize() 的注释
/// 4. 设置数据库表（settings, profiles）和 Auth providers
///
/// 当前为存根实现，编译通过但不执行网络请求。

// TODO: 替换为真实的 Supabase 项目 URL 和 anon key
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'your-anon-key';

/// 用户资料
class UserProfile {
  final String id;
  final String? email;
  final Map<String, dynamic>? settings;

  const UserProfile({required this.id, this.email, this.settings});
}

/// Supabase 服务（存根实现）
class SupabaseService {
  static bool _initialized = false;

  /// 初始化 Supabase 客户端
  static Future<void> init() async {
    if (_initialized) return;
    // TODO: 取消注释以下代码以启用 Supabase
    // await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _initialized = true;
    if (kDebugMode) {
      debugPrint('SupabaseService: initialized (stub — configure supabaseUrl and supabaseAnonKey)');
    }
  }

  /// 当前是否已登录
  static bool get isSignedIn => false;

  /// 当前用户资料
  static UserProfile? get currentUser => null;

  /// 邮箱注册
  static Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: SupabaseAuth.instance.signUp(email: email, password: password)
    throw UnimplementedError('Supabase not configured');
  }

  /// 邮箱登录
  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: SupabaseAuth.instance.signInWithPassword(email: email, password: password)
    throw UnimplementedError('Supabase not configured');
  }

  /// 登出
  static Future<void> signOut() async {
    // TODO: SupabaseAuth.instance.signOut()
    throw UnimplementedError('Supabase not configured');
  }

  /// 上传设置到云端
  static Future<void> uploadSettings(Map<String, dynamic> settings) async {
    // TODO: Supabase.instance.client.from('settings').upsert({...})
    throw UnimplementedError('Supabase not configured');
  }

  /// 从云端下载设置
  static Future<Map<String, dynamic>?> downloadSettings() async {
    // TODO: Supabase.instance.client.from('settings').select().single()
    throw UnimplementedError('Supabase not configured');
  }
}
