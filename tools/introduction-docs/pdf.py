from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/google-chrome')
    pg=b.new_page(); pg.goto('file:///home/claude/intro/out/intro.html'); pg.wait_for_timeout(1500)
    foot='<div style="font-size:7.5pt;width:100%;text-align:center;color:#777;font-family:serif">Introduction to CCN String Diagrams · Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0 · <span class="pageNumber"></span>/<span class="totalPages"></span></div>'
    pg.pdf(path='/home/claude/intro/out/introduction-to-ccn-string-diagrams.pdf',format='A4',print_background=True,display_header_footer=True,header_template='<div></div>',footer_template=foot,margin={'top':'16mm','bottom':'18mm','left':'15mm','right':'15mm'})
