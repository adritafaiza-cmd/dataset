# Torch HPC login (enter the device code here)

**Enter the HPC / NYU MFA code here:**

**https://login.microsoft.com/device**

Torch SSH prints a short PIN, then waits. Open that link, paste the PIN, sign in with your NYU account, approve MFA, return to the terminal, and press Enter.

## Connect from ecs05

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  ft2335@login.torch.hpc.nyu.edu
```

After login:

```bash
cd /scratch/ft2335/dataset-observable
hostname
pwd
```

`hostname` should look like `torch-login-…`. `pwd` should be `/scratch/ft2335/dataset-observable`.

## RTLCoder job (19128466)

This job is **not** on ecs05. Check it only after you are on Torch:

```bash
squeue -j 19128466
sacct -j 19128466 --format=JobID,State,Elapsed,End,ExitCode,NodeList
find experiments/rtlcoder-deepseek-3prompt-10attempt-v1 -name complete.json | wc -l
tail -n 12 experiments/rtlcoder-deepseek-3prompt-10attempt-v1/slurm-19128466.out
tail -n 20 experiments/rtlcoder-deepseek-3prompt-10attempt-v1/slurm-19128466.err
```

- `R` = still generating
- no `squeue` row + `COMPLETED` in `sacct` = finished
- `TIMEOUT` / `FAILED` = stopped; finished attempts stay on disk

Do not run those `find` / `tail` paths on ecs05. They exist only under Torch `/scratch`.

## What already finished on Torch

- ComplexVCoder 3-prompt generation: **1,320 / 1,320**
- First RTLCoder job `19128210`: failed in ~35s, no RTL
- RTLCoder job `19128466`: last confirmed `R` on `gh112` with 26 completed attempts
