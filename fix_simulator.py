import re

with open('lib/views/marketing/components/interactive_simulator_card.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add missing colors
if 'const _kIndigoBorder' not in code:
    code = code.replace('const _kOrange = Color(0xFFF97316);', 'const _kOrange = Color(0xFFF97316);\nconst _kIndigoBorder = Color(0xFFC7D2FE);\nconst _kIndigoPale = Color(0xFFEEF2FF);\nconst _kBorder = Color(0xFFE2E8F0);\nconst _kTextBody = Color(0xFF475569);')

# Fix const expression issues (remove const from the parent widgets)
# For example, "const Expanded(" -> "Expanded("
code = code.replace("const Expanded(\n                        child: Column(", "Expanded(\n                        child: Column(")
code = code.replace("const Column(\n                          crossAxisAlignment:", "Column(\n                          crossAxisAlignment:")
code = code.replace("const Row(\n          children: [", "Row(\n          children: [")
code = code.replace("style: const TextStyle(color: _kTextBody, fontSize: 11)),", "style: TextStyle(color: _kTextBody, fontSize: 11)),")

with open('lib/views/marketing/components/interactive_simulator_card.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed constants and const arrays")
