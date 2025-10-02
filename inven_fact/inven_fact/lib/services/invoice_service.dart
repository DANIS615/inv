import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';

class InvoiceService {
  static const String _invoicesKey = 'invoices';
  
  Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = prefs.getStringList(_invoicesKey) ?? [];
    
    return invoicesJson
        .map((json) => Invoice.fromJson(jsonDecode(json)))
        .toList();
  }
  
  Future<void> saveInvoice(Invoice invoice) async {
    final invoices = await getInvoices();
    invoices.add(invoice);
    
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = invoices
        .map((invoice) => jsonEncode(invoice.toJson()))
        .toList();
    
    await prefs.setStringList(_invoicesKey, invoicesJson);
  }
  
  Future<void> deleteInvoice(String invoiceId) async {
    final invoices = await getInvoices();
    invoices.removeWhere((invoice) => invoice.id == invoiceId);
    
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = invoices
        .map((invoice) => jsonEncode(invoice.toJson()))
        .toList();
    
    await prefs.setStringList(_invoicesKey, invoicesJson);
  }
}