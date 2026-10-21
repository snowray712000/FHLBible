# FHLBible — ai-log index

FHLBible is the full-featured Bible reader iOS app (multiple translations, full-text search, Strong's numbers / parsing, commentary, audio Bible, offline SQLite). It is one of three sibling projects in the workspace: FHLBible, FHLBibleTW (Taiwanese-Hokkien edition), FHLCommon (shared framework). Minimum iOS 14.0.

Rules for writing and reading logs: [README.md](README.md). Read this index first, then open only the logs relevant to your task.

## 2026 · s4 (Oct–Dec)

| Log | Type | Summary | Areas / keywords | Files touched |
|---|---|---|---|---|
| [1021e_version_info_screen](2026/s4/1021e_version_info_screen.md) | feature | Home screen ⓘ next to the version number opens a grouped table of release notes parsed from a bundled `app_versions.md` (To Do first, newest version next). | version info, release notes, app_versions.md, VCIndex, VCVersionInfo, VersionInfoParser, synchronized group Helps | FHLBible/Helps/{app_versions.md,VersionInfoParser.swift,VCVersionInfo.swift}, FHLBible/VCIndex.swift |
| [1021d_git_state_cleanup](2026/s4/1021d_git_state_cleanup.md) | config | Backed up the 20 never-pushed commits to origin/複製存成圖片, committed pending work in themed commits, added .gitignore. Nothing pushed besides the backup. | git, branch, backup, .gitignore, xcuserdata, stash | repo-wide (git only) |
| [1021c_deployment_target_raised_to_15](2026/s4/1021c_deployment_target_raised_to_15.md) | config | Maintainer raised FHLBible/FHLCommon to 15.0 after Xcode 27 broke 14.0; Xcode auto-set FHLBibleTW to 17.0 via recommended settings (later set to 15.0, see FHLBibleTW log 1021c). Rules: do not touch targets. | deployment target, iOS 15, Xcode 27, RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET, pbxproj | pbxproj of all three projects (read only), CLAUDE.md files |
| [1021b_xcode27_deployment_target_warning](2026/s4/1021b_xcode27_deployment_target_warning.md) | investigation | Xcode 27 warns iOS 14.0 is outside the simulator's supported range; records the maintainer's uncommitted pbxproj workaround and the rule not to "fix" it. | deployment target, iOS 14, Xcode 27, pbxproj, `[arch=*]` | FHLBible.xcodeproj/project.pbxproj (read only), CLAUDE.md files |
| [1021a_baseline_project_overview](2026/s4/1021a_baseline_project_overview.md) | baseline | Snapshot of architecture, modules, dependencies, constraints, and legacy docs, written when ai-log was introduced. | architecture, Read, Search, FHLTools, Download, FHLCommon duplicates, iOS 14 | CLAUDE.md, ai-log/ |

## Legacy docs (pre ai-log)

Hand-written notes in `FHLBible/doc/` (Chinese, some written for AI): `260413b_parsing_format_for_ai.md`, `260413d_fix_parsing_segment_for_ai.md`, `260413f_fix_sn_dict_dynamic_type_for_ai.md`, `260927a_離線parsing資料庫_bible_parsing.md`, others `260413a/c/e/g/h_*`, `0302a.md`. Also `FHLBible/Read/Read.md`, `FHLBible/FHLTools/SNParsing/VCParsing.md`, `readme.md`, and git history (`git log`).
