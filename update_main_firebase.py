import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

if 'import \'firebase_options.dart\';' not in code:
    code = code.replace("import 'package:firebase_core/firebase_core.dart';", "import 'package:firebase_core/firebase_core.dart';\nimport 'firebase_options.dart';")

if 'options: DefaultFirebaseOptions.currentPlatform' not in code:
    code = code.replace("await Firebase.initializeApp();", "await Firebase.initializeApp(\n      options: DefaultFirebaseOptions.currentPlatform,\n    );")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated main.dart with firebase_options")
