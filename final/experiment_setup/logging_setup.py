"""Shared experiment logging for the judge and DC-PMI backends."""
import logging

logger = logging.getLogger("experiment_setup")
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s",
                                         datefmt="%Y-%m-%d %H:%M:%S"))
    logger.addHandler(handler)
logger.setLevel(logging.INFO)
logger.propagate = False
