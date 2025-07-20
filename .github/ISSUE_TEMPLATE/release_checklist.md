---
name: Release Checklist
about: Checklist for preparing a new gem release
title: 'Release v[VERSION]'
labels: release
assignees: ''
---

## Pre-Release Checklist

- [ ] All tests passing locally (`bundle exec rake`)
- [ ] Version bumped in `lib/paytree/version.rb`
- [ ] CHANGELOG.md updated with new version and changes
- [ ] README.md documentation is up to date
- [ ] Gemspec metadata is current
- [ ] No sensitive information in codebase

## Release Process

- [ ] Create and push git tag: `git tag v[VERSION] && git push origin v[VERSION]`
- [ ] GitHub Actions will automatically publish to RubyGems
- [ ] Verify gem published successfully on [rubygems.org](https://rubygems.org/gems/paytree)
- [ ] Create GitHub release with changelog notes

## Post-Release

- [ ] Update any example projects/documentation
- [ ] Announce release (if applicable)
- [ ] Close this issue

---

**Version:** v[VERSION]
**Expected publish date:** [DATE]