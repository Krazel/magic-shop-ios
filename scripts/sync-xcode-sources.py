from pathlib import Path
import re
p=Path('MagicShop.xcodeproj/project.pbxproj')
s=p.read_text()
groups={'MagicShop/App':'B00000000000000000000004','MagicShop/World':'B00000000000000000000008','MagicShop/Core/Domain':'B00000000000000000000006','MagicShopTests':'B0000000000000000000000A'}
used=set(re.findall(r'\b[CD]([0-9A-F]{23})\b',s))
n=0x30
for directory,group in groups.items():
    for path in sorted(Path(directory).glob('*.swift')):
        name=path.name
        if f'/* {name} */' in s: continue
        while f'{n:023X}' in used: n+=1
        suffix=f'{n:023X}'; n+=1; used.add(suffix)
        c='C'+suffix; d='D'+suffix
        s=s.replace('/* End PBXBuildFile section */',f'\t\t{d} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {c} /* {name} */; }};\n/* End PBXBuildFile section */')
        s=s.replace('/* End PBXFileReference section */',f'\t\t{c} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};\n/* End PBXFileReference section */')
        pattern=rf'({group} /\*[^\n]+?\*/ = \{{\s+isa = PBXGroup;\s+children = \()'
        s,count=re.subn(pattern,lambda m:m[1]+f'\n\t\t\t\t{c} /* {name} */,',s)
        assert count==1,(name,'group')
        phase='E00000000000000000000002' if directory=='MagicShopTests' else 'E00000000000000000000001'
        pattern=rf'({phase} /\* Sources \*/ = \{{\s+isa = PBXSourcesBuildPhase;\s+buildActionMask = [0-9]+;\s+files = \()'
        s,count=re.subn(pattern,lambda m:m[1]+f'\n\t\t\t\t{d} /* {name} in Sources */,',s)
        assert count==1,(name,'phase')
        print('Added',name)
p.write_text(s)