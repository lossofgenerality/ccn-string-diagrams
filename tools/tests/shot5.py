from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/google-chrome')
    pg=b.new_page(viewport={'width':1440,'height':900})
    errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto('file:///home/claude/ccn-string-diagrams/string-diagram-editor.html'); pg.wait_for_timeout(400)
    n=pg.eval_on_selector_all('#examples option','os=>os.length')-1
    bad=[]
    for i in range(n):
        pg.select_option('#examples',str(i)); pg.wait_for_timeout(120); pg.click('#bSimp'); pg.wait_for_timeout(150)
        v=pg.inner_text('#verdict'); t=pg.evaluate('i=>EX[i][0]',i)
        if '=' in pg.evaluate('i=>EX[i][1]',i) and '✓' not in v: bad.append((i,t,v[:60]))
    print(n,'bad',bad,'errors',errs, 'ribbon after last:', pg.is_checked('#ribbon'))
    pg.screenshot(path='t/last33.png')
