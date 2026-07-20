import re

with open('lib/views/marketing/marketing_view.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Find the class InteractiveSimulatorCard inside marketing_view.dart and remove it
class_pattern = r'class InteractiveSimulatorCard extends StatefulWidget \{.*?\n\}\n'
# It has a state class too: class _InteractiveSimulatorCardState extends State<InteractiveSimulatorCard> { ... }
# Let's just find the index of "class InteractiveSimulatorCard extends StatefulWidget {"
start_idx = code.find('class InteractiveSimulatorCard extends StatefulWidget {')
if start_idx != -1:
    # Find the end of _InteractiveSimulatorCardState
    # Let's search for "  Widget _orderCard({" and its closing brace
    # Actually, let's just find the end of the file or the start of the next thing, but wait, this class is at the END or TOP?
    # It was added at the bottom? Let's find "class InteractiveSimulatorCard"
    end_idx = code.find('class _InteractiveSimulatorCardState', start_idx)
    end_of_state = code.find('\n}\n', end_idx)
    # Actually, it's safer to just split by "class InteractiveSimulatorCard extends StatefulWidget {" and "class _MarketingViewState" or something.
    # Where did I inject it in update_marketing.py?
    # I did: `if 'InteractiveSimulatorCard' not in code: code += '\n' + sim_class`
    # So it is at the very END of the file!
    pass

# Wait, let's just use regex or simple string operations.
if start_idx != -1:
    code = code[:start_idx]

if 'import \'components/interactive_simulator_card.dart\';' not in code:
    code = code.replace("import 'dart:async';", "import 'dart:async';\nimport 'components/interactive_simulator_card.dart';")

with open('lib/views/marketing/marketing_view.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("marketing_view.dart cleaned up and imported the real simulator component!")
