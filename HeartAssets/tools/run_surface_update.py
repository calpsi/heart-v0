"""Sequential, resumable installed-surface update; stops on first failure."""
from pathlib import Path
import subprocess,sys,json
project=Path(__file__).resolve().parents[2];folder=project/'HeartAssets/refinements/surface-v5';folder.mkdir(parents=True,exist_ok=True)
for number in map(int,sys.argv[1:]):
 print('START',number,flush=True)
 with (folder/f'{number:02}.log').open('w') as log:
  result=subprocess.run(['/Applications/Blender.app/Contents/MacOS/Blender','-b','--factory-startup','--python-exit-code','1','--python',str(project/'HeartAssets/tools/update_installed_surfaces.py'),'--',str(number)],cwd=project,stdout=log,stderr=subprocess.STDOUT)
 if result.returncode:print('FAILED',number,flush=True);sys.exit(result.returncode)
 print('INSTALLED',number,flush=True)
print('QUEUE COMPLETE',flush=True)
