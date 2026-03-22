import re

with open('lib/navigation/app_router.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace ShellRoute signatures
text = re.sub(
    r'ShellRoute\(\s*builder: \(context, state, child\) \{\s*return (.*?)Navigation\(child: child\);\s*\},',
    r'StatefulShellRoute.indexedStack(\n        builder: (context, state, navigationShell) {\n          return \1Navigation(child: navigationShell);\n        },',
    text
)

# We need to change 'routes: [' to 'branches: [' for these shell routes
# And wrap every GoRoute inside the ShellRoute into a StatefulShellBranch.

def wrap_routes_in_branches(text):
    # Find all occurrences of StatefulShellRoute.indexedStack
    parts = text.split('StatefulShellRoute.indexedStack(')
    if len(parts) == 1: return text
    
    out = [parts[0]]
    for p in parts[1:]:
        # Find 'routes: [' in this part
        routes_idx = p.find('routes: [')
        
        # We need to replace 'routes: [' with 'branches: ['
        # and wrap every GoRoute blocks in 'StatefulShellBranch(routes: [ ... ]),'
        if routes_idx != -1:
            p2 = p[:routes_idx] + 'branches: [\n'
            rest = p[routes_idx + 9:]
            
            # The 'rest' contains GoRoute(...), ], and the rest of the file.
            # We'll split by 'GoRoute(' and reconstruct. 
            # Note, this is extremely brittle if there are GoRoutes nested, but they aren't!
            
            # Let's find the closing bracket of the branches list.
            # A simple bracket matching algorithm.
            depth = 1 # We replaced 'routes: [' with 'branches: [' -> depth 1
            idx = 0
            while depth > 0 and idx < len(rest):
                if rest[idx] == '[': depth += 1
                elif rest[idx] == ']': depth -= 1
                idx += 1
            
            # The inner array string
            inner_routes = rest[:idx-1]
            tail = rest[idx:]
            
            # wrap each GoRoute
            # we can split by 'GoRoute(' but since GoRoute occurs inside, let's just do a regex replace
            # Find all top-level GoRoute(...) using bracket matching
            
            def parse_goroutes(s):
                res = []
                # find 'GoRoute('
                start = 0
                while True:
                    g_idx = s.find('GoRoute(', start)
                    if g_idx == -1:
                        break
                    # find matching pairing for this GoRoute
                    d = 0
                    i = g_idx + 7
                    while i < len(s):
                        if s[i] == '(': d += 1
                        elif s[i] == ')': 
                            d -= 1
                            if d == 0:
                                break
                        i += 1
                    # include comma
                    while i + 1 < len(s) and (s[i+1].isspace() or s[i+1] == ','):
                        i += 1
                        if s[i] == ',': break
                    
                    res.append(s[g_idx:i+1])
                    start = i + 1
                return res

            routes_list = parse_goroutes(inner_routes)
            new_branches = []
            for r in routes_list:
                new_branches.append('          StatefulShellBranch(routes: [' + r + ']),')
            
            out.append(p2 + '\n'.join(new_branches) + '\n        ]' + tail)
        else:
            out.append(p)
            
    return 'StatefulShellRoute.indexedStack('.join(out)

text = wrap_routes_in_branches(text)

with open('lib/navigation/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done replacing ShellRoutes with StatefulShellRoute!")
