import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // TODO: Replace with your actual Supabase URL and Anon Key from your Supabase Dashboard
  static const String supabaseUrl = 'https://dlgetsqzvwwrbqltjcct.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZ2V0c3F6dnd3cmJxbHRqY2N0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMTA3MzQsImV4cCI6MjEwODU4NjczNH0.b1vCYC2u40EsARuvvAQmJvcxI-Yp3zxuyxmEiBTXpUo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
