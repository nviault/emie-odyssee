import asyncio
from playwright.async_api import async_playwright
import os

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        context = await browser.new_context(viewport={'width': 1280, 'height': 800})
        page = await context.new_page()

        # Load the local file
        path = os.path.abspath('index.html')
        await page.goto(f'file://{path}')

        # 1. Close Intro
        await page.click('button:has-text("C\'est parti !")')

        # 2. Check Voice Mode for Parent Guide
        await page.click('button:has-text("Voix")')
        await page.wait_for_timeout(500)

        guide = page.locator('#parent-guide')
        is_visible = await guide.is_visible()
        print(f"Parent Guide Visible in Voice Mode: {is_visible}")
        await page.screenshot(path='/home/jules/verification/vfinal_v2_voice.png')

        # 3. Check Rhythm Mode (Guide should be hidden)
        await page.goto(f'file://{path}')
        await page.click('button:has-text("C\'est parti !")')
        await page.click('button:has-text("Rythme")')
        await page.wait_for_timeout(500)
        is_visible_r = await guide.is_visible()
        print(f"Parent Guide Visible in Rhythm Mode: {is_visible_r}")

        await browser.close()

if __name__ == "__main__":
    asyncio.run(run())
