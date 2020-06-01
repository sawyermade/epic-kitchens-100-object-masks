import re
from pathlib import Path
from typing import Dict, Iterator, List, Union

RAW_DETECTION_ROOT = '/media/viki/SCRATCH/epic2020_aggregated_masks'
DATA_PROCESSED = 'data/processed'


def iter_video_dirs(root_dir: Union[Path, str]) -> Iterator[Path]:
    root_dir = Path(root_dir)
    def is_person_dir(p: Path) -> bool:
        return re.match('P\d+', p.name) is not None

    def is_video_dir(p: Path) -> bool:
        return re.match('P\d+_\d+', p.name) is not None

    for person_dir in filter(is_person_dir, root_dir.iterdir()):
        for video_dir in filter(is_video_dir, person_dir.iterdir()):
            yield video_dir

videos: List[str] = [
    video_dir.name
    for video_dir in iter_video_dirs(RAW_DETECTION_ROOT)
]

def extract_ids(video_name: str) -> Dict[str, str]:
    matches = re.match(r'P(\d+)_(\d+)', video_name)
    return {
        'person': f'P{matches.group(1)}',
        'video': f'P{matches.group(1)}_{matches.group(2)}',
    }

rule all:
    input: [f'{DATA_PROCESSED}/{ids["person"]}/{ids["video"]}.pkl' \
            for ids in map(extract_ids, videos)]


rule convert_raw_detections_to_releasable_detections:
    input: RAW_DETECTION_ROOT + '/{person_id}/{video_id}.pkl'
    output: DATA_PROCESSED + '/{person_id}/{video_id}.pkl'
    shell:
         """
         python src/scripts/convert_raw_masks_to_releasable.py {input} {output}
         """
