import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))   # the repository
WORK = os.environ.get('CCN_BUILD', os.path.join(ROOT, 'build', 'introduction'))      # scratch folder for screenshots and pages
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/google-chrome')
    pg=b.new_page(viewport={'width':1440,'height':900},device_scale_factor=1.5)
    pg.goto(f'file://{ROOT}/string-diagram-editor.html'); pg.wait_for_timeout(500)
    pg.select_option('#examples','21'); pg.wait_for_timeout(400); pg.click('#bSimp'); pg.wait_for_timeout(500)
    pg.screenshot(path='out/ui.png')
