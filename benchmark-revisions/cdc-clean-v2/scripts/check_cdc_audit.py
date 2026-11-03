#!/usr/bin/env python3
"""Verify the frozen allowlist and data hashes before an audited retrain."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(data=None):
    data = data or ROOT / 'training/cdc-lora-v1'
    external = ROOT / 'training/cdc-external-v1'
    evidence = json.loads((data / 'audit-evidence.json').read_text())
    for label, path in [('manifest', data / 'audit.md'),
                        ('train', data / 'train.jsonl'),
                        ('dev', external / 'dev.jsonl')]:
        if digest(path) != evidence[label + '_sha256']:
            raise ValueError(f'{label} changed after audit freeze: {path}')
    decisions = dict(re.findall(r'^\| `([^`]+)` \| (keep|drop) \|',
                               (data / 'audit.md').read_text(), re.M))
    rows = [json.loads(line) for line in (data / 'train.jsonl').read_text().splitlines()]
    names = [row['module'] for row in rows]
    kept = {name for name, action in decisions.items() if action == 'keep'}
    if len(names) != len(set(names)) or set(names) != kept or kept != set(evidence['kept']):
        raise ValueError('training rows must match frozen keep rows exactly')
    dev = [json.loads(line) for line in (external / 'dev.jsonl').read_text().splitlines()]
    dev_texts = {m['content'].strip() for row in dev for m in row['messages']}
    original = [json.loads(line) for line in (external / 'train.jsonl').read_text().splitlines()]
    original_prompts = {m['content'].strip() for row in original
                        for m in row['messages'] if m['role'] == 'user'}
    records = {row['module']: row for row in evidence['modules']}
    for row in rows:
        name = row['module']
        directory = external / name
        for kind, filename in [('source', 'source.sv'), ('spec', 'spec.md')]:
            if digest(directory / filename) != records[name][kind + '_sha256']:
                raise ValueError(f'{name}/{filename} changed after freeze')
        if records[name]['exam_matches']:
            raise ValueError(f'{name} matches exam source')
        provenance = json.loads((directory / 'PROVENANCE.json').read_text())
        if provenance.get('split') != 'train':
            raise ValueError(f'{name} is not in the upstream train split')
        messages = row['messages']
        prompt = next(m['content'].strip() for m in messages if m['role'] == 'user')
        target = next(m['content'].strip() for m in messages if m['role'] == 'assistant')
        source = re.sub(r'^```\w*\n|\n```$', '', target).strip()
        if prompt not in original_prompts or any(m['content'].strip() in dev_texts for m in messages):
            raise ValueError(f'{name} overlaps dev or is absent from upstream train')
        if prompt != (directory / 'spec.md').read_text().strip() or source != (directory / 'source.sv').read_text().strip():
            raise ValueError(f'{name} training pair differs from audited files')
    if json.loads((data / 'filter_report.json').read_text())['kept'] != len(rows):
        raise ValueError('filter report count disagrees with manifest')
    return {'examples': len(rows), 'dev_rows_excluded': len(dev),
            'manifest_sha256': evidence['manifest_sha256'],
            'train_sha256': evidence['train_sha256']}


if __name__ == '__main__':
    print(json.dumps(check(), indent=2))
