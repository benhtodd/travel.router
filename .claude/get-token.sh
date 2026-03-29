#!/bin/bash
# Resolves the OpenRouter API key from 1Password at Claude startup.
# Used as apiKeyHelper in settings.local.json.
op read 'op://Private/open.router.one/credential' --account familytodd
