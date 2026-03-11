# Completion flow (timer/proof/manual)

## When timer finishes
1. TimerService marks session as `finished`
2. UI shows a confirm sheet:
   - task (optional select)
   - minutes (default plannedMinutes)
   - confirm/skip
3. On confirm:
   - write completion_logs (source=timer)
   - calculate reward from game_config
   - update user xp/coin/level
   - if level increased: show LevelUpDialog

## Proof flow (no OCR)
1. User selects screenshot
2. UI asks: task + minutes
3. On confirm:
   - write completion_logs (source=proof, verified=1)
   - reward update

## Manual flow
- Same as proof but source=manual, verified=0
