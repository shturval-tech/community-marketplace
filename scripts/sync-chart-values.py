#!/usr/bin/env python3
"""Merge vendored subchart values.yaml into wrapper chart values for Shturval UI defaults."""
from __future__ import annotations

import glob
import sys
import tarfile
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    print("PyYAML required: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
CHARTS = ROOT / "charts"

HEADER = """\
# Synced from vendored subchart defaults + community-marketplace overrides.
# Regenerate: make sync-values (after scripts/vendor-chart-deps.sh)
"""

# chart directory name -> (values key under parent, source kind)
WRAPPERS: dict[str, tuple[str, str]] = {
    "authentik": ("authentik", "tgz"),
    "cnpg-cluster": ("cluster", "tgz"),
    "cnpg-operator": ("cloudnative-pg", "tgz"),
    "keycloak": ("keycloakx", "tgz"),
    "mariadb-operator": ("mariadb-operator", "tgz"),
    "minio-operator": ("minio-operator", "tgz"),
    "minio-tenant": ("tenant", "tgz"),
    "proxmox-csi": ("proxmox-csi-plugin", "tgz"),
    "redis-operator": ("redis-operator", "tgz"),
    "strimzi-operator": ("strimzi-kafka-operator", "dir"),
}


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for key, val in override.items():
        if key in out and isinstance(out[key], dict) and isinstance(val, dict):
            out[key] = deep_merge(out[key], val)
        else:
            out[key] = val
    return out


def load_yaml(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    data = yaml.safe_load(text)
    return data if isinstance(data, dict) else {}


def values_from_tgz(tgz_path: Path) -> dict[str, Any]:
    with tarfile.open(tgz_path, "r:gz") as tf:
        for member in tf.getmembers():
            parts = member.name.split("/")
            if len(parts) == 2 and parts[1] == "values.yaml" and member.isfile():
                f = tf.extractfile(member)
                if f is None:
                    continue
                data = yaml.safe_load(f.read().decode("utf-8"))
                return data if isinstance(data, dict) else {}
    raise FileNotFoundError(f"values.yaml not found in {tgz_path}")


def subchart_defaults(chart_dir: Path, source_kind: str) -> dict[str, Any]:
    if source_kind == "dir":
        sub_values = chart_dir / "charts" / "strimzi-kafka-operator" / "values.yaml"
        if not sub_values.is_file():
            raise FileNotFoundError(sub_values)
        return load_yaml(sub_values)
    tgz_files = sorted(chart_dir.glob("charts/*.tgz"))
    if not tgz_files:
        raise FileNotFoundError(f"no charts/*.tgz in {chart_dir}")
    return values_from_tgz(tgz_files[0])


def sync_chart(chart_name: str, sub_key: str, source_kind: str) -> None:
    chart_dir = CHARTS / chart_name
    values_path = chart_dir / "values.yaml"
    if not values_path.is_file():
        raise FileNotFoundError(values_path)

    wrapper = load_yaml(values_path)
    global_block = wrapper.get("global") or {
        "imageRegistry": "ghcr.io/shturval-tech/community-marketplace",
        "storageClass": "",
    }
    if "ingress" not in global_block and chart_name not in ("proxmox-csi",):
        global_block.setdefault("ingress", {"className": ""})

    overrides = wrapper.get(sub_key, {})
    if not isinstance(overrides, dict):
        overrides = {}

    base = subchart_defaults(chart_dir, source_kind)
    merged_sub = deep_merge(base, overrides if isinstance(overrides, dict) else {})

    # Preserve any extra top-level keys from wrapper (e.g. future extensions)
    out: dict[str, Any] = {"global": global_block, sub_key: merged_sub}
    for k, v in wrapper.items():
        if k not in ("global", sub_key):
            out[k] = v

    values_path.write_text(
        HEADER + yaml.dump(out, default_flow_style=False, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )
    lines = values_path.read_text(encoding="utf-8").count("\n") + 1
    print(f"  {chart_name}/values.yaml ({lines} lines, key={sub_key})")


def main() -> int:
    print("==> sync-chart-values")
    errors: list[str] = []
    for chart_name, (sub_key, source_kind) in WRAPPERS.items():
        try:
            sync_chart(chart_name, sub_key, source_kind)
        except Exception as exc:
            errors.append(f"{chart_name}: {exc}")
            print(f"  ERROR {chart_name}: {exc}", file=sys.stderr)
    if errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
