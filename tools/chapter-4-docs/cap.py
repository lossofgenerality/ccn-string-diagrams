import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))   # the repository
WORK = os.environ.get('CCN_BUILD', os.path.join(ROOT, 'build', 'chapter-4'))      # scratch folder for screenshots and pages
import json
from playwright.sync_api import sync_playwright
out=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/google-chrome')
    pg=b.new_page(viewport={'width':1440,'height':900},device_scale_factor=2)
    errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(f'file://{ROOT}/string-diagram-editor.html'); pg.wait_for_timeout(500)
    idx=pg.evaluate("EX.map((x,i)=>x[3]==='fus'?i:-1).filter(i=>i>=0)")
    for i in idx:
        pg.select_option('#examples',str(i)); pg.wait_for_timeout(350); pg.click('#bFit'); pg.wait_for_timeout(150)
        pg.locator('#canvas').screenshot(path=f'{WORK}/img/ex{i}a.png')
        info=pg.evaluate('''i=>{const x=EX[i];const S=Core.parseSig(SIG[x[2]]);const ps=x[1].split('=').map(s=>Core.parseLin(s.trim(),S));
          const rs=ps.map(pts=>Core.simplifyLin(pts,S,{pairings:S.pairings}));
          return {i, title:x[0], src:x[1], sig:SIG[x[2]], tex:ps.map(pts=>Core.linText(Core.termsOf(pts,S),true)),
            steps:rs.map(r=>r.traces.map(t=>t.steps.map(s=>s.rule).slice(1))), nf:rs.map(r=>Core.linText(r.terms,true)), scalar:rs[0].terms.every(t=>!t.ld.ls.length&&!t.ld.src.length), same:rs.every(r=>r.key===rs[0].key)}}''',i)
        pg.click('#bSimp'); pg.wait_for_timeout(450); pg.click('#bFit'); pg.wait_for_timeout(150)
        pg.locator('#canvas').screenshot(path=f'{WORK}/img/ex{i}b.png')
        info['verdict']=pg.inner_text('#verdict'); out.append(info)
    print('errors',errs)
json.dump(out,open(f'{WORK}/ex.json','w'),ensure_ascii=False,indent=1)
print(len(out), sum(o['same'] for o in out))
