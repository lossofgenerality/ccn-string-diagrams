import json
from playwright.sync_api import sync_playwright
out=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/google-chrome')
    pg=b.new_page(viewport={'width':1440,'height':900},device_scale_factor=2)
    errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto('file:///home/claude/ccn-string-diagrams/string-diagram-editor.html'); pg.wait_for_timeout(500)
    n=pg.eval_on_selector_all('#examples option','os=>os.length')-1
    for i in range(n):
        pg.select_option('#examples',str(i)); pg.wait_for_timeout(350)
        pg.click('#bFit'); pg.wait_for_timeout(150)
        pg.locator('#canvas').screenshot(path=f'/home/claude/intro/img/ex{i:02d}a.png')
        info=pg.evaluate('''i=>{const x=EX[i];const S=Core.parseSig(SIG[x[2]]);const sides=x[1].split('=').map(s=>Core.parse(s,S.sig));
          const tr=sides.map(e=>Core.simplifyTrace(e,{pairings:S.pairings,inverses:S.inverses,retracts:S.retracts}));
          return {title:x[0],src:x[1],sig:SIG[x[2]],mode:x[3]||'vee',
            tex:sides.map(e=>Core.toTeX(e)), type:sides.map(e=>{const t=Core.typeOf(e);return [Core.objText(t.dom),Core.objText(t.cod)]}),
            nf:tr.map(r=>Core.toTeX(r.e)), nftxt:tr.map(r=>Core.toText(r.e)), steps:tr.map(r=>r.steps.map(s=>[s.rule,Core.toTeX(s.e)])), same:tr.every(r=>r.key===tr[0].key)}}''',i)
        pg.click('#bSimp'); pg.wait_for_timeout(450); pg.click('#bFit'); pg.wait_for_timeout(150)
        pg.locator('#canvas').screenshot(path=f'/home/claude/intro/img/ex{i:02d}b.png')
        info['verdict']=pg.inner_text('#verdict')
        out.append(info)
    print('errors',errs)
json.dump(out,open('/home/claude/intro/ex.json','w'),ensure_ascii=False,indent=1)
print(len(out))
