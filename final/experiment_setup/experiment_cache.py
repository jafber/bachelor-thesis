"""Cache-first, resumable inference for per-example JSON-compatible payloads."""
import hashlib
import json
from pathlib import Path
import sqlite3


def cache_key(e, inputs, config, version):
    payload = dict(benchmark=e.benchmark, task=e.task, uid=e.uid,
                   inputs=inputs, config=config, prompt_version=version)
    return hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


class ExperimentCache:
    def __init__(self, path, table):
        assert table in {"responses", "likelihoods"}
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(path)
        self.table = table
        self.db.execute(f"CREATE TABLE IF NOT EXISTS {table} (key TEXT PRIMARY KEY, benchmark TEXT NOT NULL, task TEXT NOT NULL, uid TEXT NOT NULL, payload TEXT NOT NULL, config TEXT NOT NULL)")
        self.db.execute(f"CREATE INDEX IF NOT EXISTS {table}_example ON {table} (benchmark, task, uid)")
        self.db.commit()

    def get(self, key):
        row = self.db.execute(f"SELECT payload FROM {self.table} WHERE key=?", (key,)).fetchone()
        return json.loads(row[0]) if row else None

    def put(self, key, e, payload, config):
        assert payload is not None
        serialized = json.dumps(payload, ensure_ascii=False, allow_nan=False)
        with self.db:
            self.db.execute(f"INSERT OR IGNORE INTO {self.table} VALUES (?, ?, ?, ?, ?, ?)",
                            (key, e.benchmark, e.task, e.uid, serialized, json.dumps(config, sort_keys=True)))
        assert self.get(key) == payload, "Conflicting payload for cache key"

    def close(self):
        self.db.close()


class CachedExperiment:
    """Subclass with inputs(e), process(batch), record(e, key, payload)."""
    def __init__(self, cache, config, version, batch_size, cache_only, logger):
        assert batch_size > 0
        self.cache, self.config, self.version = cache, config, version
        self.batch_size, self.cache_only = batch_size, cache_only
        self.logger = logger
        self.rows = []
        self.hits = self.misses = 0

    def run(self, examples):
        from tqdm.auto import tqdm

        total = len(examples) if hasattr(examples, "__len__") else None
        completed = False
        self.logger.info("Starting evaluation: model=%s examples=%s cache_only=%s",
                         self.config["model_id"], total if total is not None else "?", self.cache_only)
        try:
            with tqdm(total=total, desc="Evaluating", unit="example") as bar:
                pending = []
                for e in examples:
                    inputs = self.inputs(e)
                    key = cache_key(e, inputs, self.config, self.version)
                    payload = self.cache.get(key)
                    index = len(self.rows)
                    self.rows.append(None)
                    if payload is None:
                        pending.append((index, e, inputs, key))
                    else:
                        self.rows[index] = self.record(e, key, payload)
                        self.hits += 1
                        bar.update(1)
                self.logger.info("Cache lookup complete: %s/%s examples loaded from cache; %s need inference",
                                 self.hits, len(self.rows), len(pending))
                if pending and self.cache_only:
                    _, e, _, key = pending[0]
                    raise RuntimeError(f"Cache miss: {e.benchmark}/{e.task}/{e.uid} ({key})")
                if pending:
                    self.inference_count = len(pending)
                    self.logger.info("Preparing inference: %s samples, batch size %s, model=%s",
                                     self.inference_count, self.batch_size, self.config["model_id"])
                for start in range(0, len(pending), self.batch_size):
                    batch = pending[start:start + self.batch_size]
                    payloads = self.process([(e, inputs) for _, e, inputs, _ in batch])
                    assert len(payloads) == len(batch)
                    for (index, e, _, key), payload in zip(batch, payloads):
                        self.cache.put(key, e, payload, self.config)
                        self.rows[index] = self.record(e, key, payload)
                        self.misses += 1
                        bar.update(1)
                completed = True
        finally:
            self.cache.close()
            self.log_peak_memory()
            self.logger.info("Evaluation %s: %s examples (cache hits=%s, generated=%s)",
                             "complete" if completed else "interrupted", self.hits + self.misses,
                             self.hits, self.misses)
        return self.rows

    def log_peak_memory(self):
        pass
