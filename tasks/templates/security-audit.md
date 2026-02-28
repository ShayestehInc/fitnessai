# Security Audit: [Feature Name]

## Checklist
- [ ] No secrets, API keys, passwords, or tokens in source code or docs
- [ ] No secrets in git history
- [ ] All user input sanitized
- [ ] Authentication checked on all new endpoints
- [ ] Authorization — correct role/permission guards
- [ ] No IDOR vulnerabilities
- [ ] File uploads validated
- [ ] Rate limiting on sensitive endpoints
- [ ] Error messages don't leak internals
- [ ] CORS policy appropriate

## Injection Vulnerabilities
| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|

## Auth & Authz Issues
| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|

## Security Score: X/10
## Recommendation: PASS / CONDITIONAL PASS / FAIL
