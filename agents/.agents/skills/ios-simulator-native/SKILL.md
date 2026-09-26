---
name: ios-simulator-native
description: >-
  Test and interact with native iOS apps in the local Xcode Simulator using Appium and XCUITest. Use for requests to navigate a simulator app, inspect its accessibility tree, tap, type, swipe, capture screenshots, or verify native app flows. Do not use agent-browser's iOS provider for native apps because that provider drives Mobile Safari.
---

# Native iOS Simulator testing

Use Appium's XCUITest driver to control an installed native app. Appium runs on the Mac and connects to the simulator. The app does not run a browser or an agent.

## Before starting

1. Confirm the app bundle identifier, the target simulator, and what flow the user wants tested. Do not guess a bundle identifier or install/erase an app without authorization.
2. Check `xcrun simctl list devices booted`, `appium --version`, `appium driver list --installed`, and `appium driver doctor xcuitest`. If Xcode or WebDriverAgent is not ready, use the official [Appium XCUITest setup skill](https://github.com/appium/skills/blob/main/skills/setup-xcuitest/SKILL.md) and its referenced assets. The doctor should report zero required fixes. Optional warnings are not blockers.
3. Do not use `agent-browser -p ios`: its documented iOS workflow launches Safari, not the user's native app. Do not close or reset a simulator session owned by another agent or the user.

## Drive the app

Prefer the official [Appium MCP server](https://github.com/appium/appium-mcp) when it is available in the agent's MCP client. Discover its tools and inspect their schemas before calling them. For local iOS sessions it can use its embedded XCUITest driver; when connecting to the Homebrew Appium server, pass the local `remoteServerUrl` and explicit capabilities.

- Select the intended simulator by UDID, not just device name, when there are multiple devices.
- Create a native iOS session with `platformName: "iOS"`, `appium:automationName: "XCUITest"`, `appium:udid: "<booted-simulator-udid>"`, and `appium:bundleId: "<installed-app-bundle-id>"`. Set `appium:noReset: true` when preserving existing app data is important. Use `appium:app` only when the user wants to install an app build.
- Read the current screen with `appium_get_page_source`; use `appium_screenshot` when visual context is needed. Find controls with `appium_find_element`, preferring accessibility ids over platform predicates and XPath. Interact using the MCP gesture and text-input tools shown by discovery. Re-read the screen after navigation and verify the requested result.
- Ask the user to complete passwords, MFA, CAPTCHA, or sensitive account prompts themselves. Do not print page source or screenshots containing secrets into public logs or commit them.
- Delete only the Appium session created for this task when finished. Avoid `simctl erase`, simulator shutdown, or app deletion unless explicitly requested.

If Appium MCP is not connected, say so rather than pretending a SKILL file provides tools. Either configure that MCP server in the user's agent client or use Appium's documented WebDriver HTTP API against a local Appium server. Do not treat the agent-browser Safari provider as a native-app fallback.

## Validation and troubleshooting

First verify the environment with `appium driver doctor xcuitest`. Then create a session against an authorized installed app and verify that page source or a screenshot reflects its native UI before attempting a test flow. The first WebDriverAgent build may take time. If session creation fails, capture the exact Appium error, Xcode state, simulator UDID, and driver version; consult the official [Appium troubleshooting skill](https://github.com/appium/skills/blob/main/skills/appium-troubleshooting/SKILL.md). Do not claim simulator automation works until a native session has actually opened and read the app.

Sources: [Appium XCUITest setup skill](https://github.com/appium/skills/blob/main/skills/setup-xcuitest/SKILL.md), [Appium MCP](https://github.com/appium/appium-mcp), and [agent-browser iOS scope](https://github.com/vercel-labs/agent-browser/blob/main/docs/src/app/ios/page.mdx).
