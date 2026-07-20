import re

with open('lib/views/marketing/components/interactive_simulator_card.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Change SMS text
old_text = "Text('Siparişiniz yola çıktı! Canlı takip için: kurye.app/os-8742', style: TextStyle(color: _kTextBody, fontSize: 10, height: 1.3)),"
new_text = "Text('Kuryemiz paketinizi almak için restoranımıza doğru yola çıktı. Canlı takip: kurye.app/os-8742', style: TextStyle(color: _kTextBody, fontSize: 10, height: 1.3)),"
code = code.replace(old_text, new_text)

# Change when SMS appears from _step >= 4 to _step >= 3
code = code.replace("top: _step >= 4 ? -40 : -120,", "top: _step >= 3 ? -40 : -120,")
code = code.replace("opacity: _step >= 4 ? 1.0 : 0.0,", "opacity: _step >= 3 ? 1.0 : 0.0,")

# Change where _simulateSms is called
# Right now it's:
#   void _simulateSearching() {
#     Future.delayed(const Duration(milliseconds: 1500), () {
#       if (mounted) {
#         setState(() => _step = 3);
#         _simulateOnWay();
#       }
#     });
#   }
# 
#   void _simulateOnWay() {
#     Future.delayed(const Duration(milliseconds: 1500), () {
#       if (mounted) {
#         setState(() => _step = 4);
#         _simulateSms();
#       }
#     });
#   }

old_searching = '''  void _simulateSearching() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _step = 3);
        _simulateOnWay();
      }
    });
  }'''

new_searching = '''  void _simulateSearching() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _step = 3);
        _simulateSms(); // Trigger SMS at step 3 (kurye atandı)
        _simulateOnWay();
      }
    });
  }'''
code = code.replace(old_searching, new_searching)

old_onway = '''  void _simulateOnWay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _step = 4);
        _simulateSms();
      }
    });
  }'''

new_onway = '''  void _simulateOnWay() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _step = 4);
        _resetSimulation();
      }
    });
  }'''
code = code.replace(old_onway, new_onway)

# remove the old reset logic from _simulateSms because _simulateOnWay now triggers reset
old_sms = '''  void _simulateSms() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _step = 5);
        _resetSimulation();
      }
    });
  }'''
new_sms = '''  void _simulateSms() {
    // SMS visibility is bound to _step >= 3 now
  }'''
code = code.replace(old_sms, new_sms)

with open('lib/views/marketing/components/interactive_simulator_card.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated interactive_simulator_card.dart")
