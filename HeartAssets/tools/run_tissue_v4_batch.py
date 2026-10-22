"""Sequential export/validation queue. Stops on the first failed asset."""
from pathlib import Path
import subprocess,sys,json
project=Path(__file__).resolve().parents[2]
logs=project/'HeartAssets/refinements/tissue-v4/logs';logs.mkdir(parents=True,exist_ok=True)
blender='/Applications/Blender.app/Contents/MacOS/Blender'
for stage in [int(v) for v in sys.argv[1:]]:
    for action,script in [('build','refine_tissue_v4.py'),('validate','validate_batch01.py')]:
        print(f'{action} stage {stage}',flush=True)
        with (logs/f'{stage:02}-{action}.log').open('w') as out:
            result=subprocess.run([blender,'-b','--factory-startup','--python-exit-code','1','--python',str(project/'HeartAssets/tools'/script),'--','--stage',str(stage)],cwd=project,stdout=out,stderr=subprocess.STDOUT)
        if result.returncode:sys.exit(result.returncode)
    progressfile=logs.parent/'progress.json';progress=json.loads(progressfile.read_text())
    progress['stages'][str(stage)]['status']='source and export validated; runtime pending'
    progressfile.write_text(json.dumps(progress,indent=2))
    print(f'PASS stage {stage}',flush=True)
