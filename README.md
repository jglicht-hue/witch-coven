# witch-coven

Shared scripts and reference files for the Football Witch Coven projects: Redraft Witch, Dynasty Witch, Matchup Witch, Kicker Wizerd and DST Warlock.

Chats and weekly tasks download scripts from here in one step, instead of reading each one from a project document and copying it out.

## Layout
| Folder | What | Used by |
|---|---|---|
| `shared/` | `v1.3_witch_usage.py`, `v1_witch_offense.py`, `v1_witch_redzone.py`, `v1_witch_dpi.py` | Redraft, Dynasty, Matchup (red-zone and DPI) |
| `shared/research/` | league-wide WR route table (`yprr.py`, `analyze.py`, `fd.py`) and offense diagnosis (`offense_diag.py`), from Redraft benchmarks v1.1 section 7 | Redraft, Dynasty |
| `shared/benchmarks_v2/` | `build.py`, `season.py`, `bands.py`, `carry.py`, `perroute.py`, from Redraft benchmarks v2.1 | Redraft, Dynasty (RB columns) |
| `dynasty/` | `v1_harmon_pdf_to_csv.py` (Harmon PDF to CSV) | Dynasty |
| `matchup/` | `per_route.py`; `pipeline/build.py` (weekly team docs) | Matchup and its weekly task |
| `kicker/` | the R pipeline (`run_all.R` and the scripts it runs), `07n_fit_new_model.R` (run by hand once a season), `weather_adjust.py`, and `data/` with the new model's two weight files | Kicker Wizerd and its weekly task |
| `dst/` | `v1.4_ChooserBoy_weekly_pull.R` | DST Warlock's weekly task |
| `instructions/` | reference copies of each project's instructions | this project |

Script names are kept exactly as the project instructions refer to them.

## Getting the scripts
Download one fixed, tagged version, so the code can't change under a chat:

```
curl -sL https://github.com/jglicht-hue/witch-coven/archive/refs/tags/<TAG>.tar.gz | tar xz
```

The folder it makes is `witch-coven-<TAG>/`. Each project's instructions name the tag to use.

## Changing a script
Fix it here, not in a project document. Each change gets a new tag, and each project moves to it when its instructions are updated.

`CHECKS.md` records how each script was checked against the project copies.
