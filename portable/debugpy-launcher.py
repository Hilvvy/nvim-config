"""Run the bundled adapter with host Python, without installing into that Python."""
import runpy
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / "data/nvim-data/mason/packages/debugpy/lib"))
runpy.run_module("debugpy.adapter", run_name="__main__")
