#!/usr/bin/env python3
"""Mapa de dependencias locales del workspace de Warp.

Lee los Cargo.toml, resuelve las dependencias `workspace = true` y calcula
qué crates son alcanzables desde los paquetes que nos interesan (terminal,
editor, UI) frente a las que solo usa el binario `warp` (agentes, nube, etc.).

Salida:
  notes/dependency-map.md
  notes/dependency-map.json
"""

from __future__ import annotations

import json
import tomllib
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NOTES = Path(__file__).resolve().parents[1] / "notes"

CORE_ROOTS = [
    "warp_terminal",
    "warp_editor",
    "warpui",
    "warpui_core",
    "command",
    "sum_tree",
    "settings",
]
APP_ROOT = "warp"


def load_toml(path: Path) -> dict:
    with path.open("rb") as fh:
        return tomllib.load(fh)


def local_path(name: str, spec: object, workspace_deps: dict[str, object]) -> str | None:
    if isinstance(spec, dict):
        if "path" in spec and isinstance(spec["path"], str):
            return spec["path"]
        if spec.get("workspace") is True:
            ws = workspace_deps.get(name)
            if isinstance(ws, dict) and isinstance(ws.get("path"), str):
                return ws["path"]
    return None


def dep_sections(manifest: dict) -> dict[str, object]:
    merged: dict[str, object] = {}
    for key in ("dependencies", "build-dependencies", "dev-dependencies"):
        merged.update(manifest.get(key, {}) or {})
    for target in (manifest.get("target") or {}).values():
        for key in ("dependencies", "build-dependencies", "dev-dependencies"):
            merged.update((target or {}).get(key, {}) or {})
    return merged


def main() -> None:
    root_manifest = load_toml(ROOT / "Cargo.toml")
    workspace_deps = root_manifest.get("workspace", {}).get("dependencies", {})

    manifests: dict[str, dict] = {}
    for cargo in [ROOT / "app" / "Cargo.toml", *sorted((ROOT / "crates").glob("*/Cargo.toml"))]:
        manifest = load_toml(cargo)
        package = manifest.get("package", {})
        name = package.get("name")
        if not name:
            continue
        manifests[name] = {
            "manifest": cargo,
            "dir": cargo.parent,
            "deps": dep_sections(manifest),
        }

    graph: dict[str, set[str]] = defaultdict(set)
    for name, info in manifests.items():
        for dep_name, spec in info["deps"].items():
            if dep_name not in manifests:
                continue
            path = local_path(dep_name, spec, workspace_deps)
            if path is not None or dep_name in manifests:
                graph[name].add(dep_name)

    def reachable(roots: list[str]) -> set[str]:
        seen: set[str] = set()
        queue = deque(roots)
        while queue:
            node = queue.popleft()
            if node in seen or node not in manifests:
                continue
            seen.add(node)
            queue.extend(graph.get(node, ()))
        return seen

    core = reachable(CORE_ROOTS)
    app = reachable([APP_ROOT])
    app_only = app - core

    # Heurística de clasificación por nombre. Es solo para orientar la poda;
    # el árbol real manda.
    buckets = {
        "agent/ai": ("ai", "agent", "llm", "mcp", "voice", "prompt", "skill", "harness"),
        "cloud/server": ("cloud", "server", "graphql", "firebase", "auth", "drive", "remote", "websocket", "http"),
        "telemetry/crash": ("sentry", "telemetry", "logging", "trace", "analytics"),
        "editor/code": ("lsp", "syntax", "language", "repo", "git", "file", "watcher", "ripgrep", "search"),
        "terminal/ui": ("terminal", "editor", "warpui", "ui", "command", "sum_tree", "settings", "vim"),
    }

    def classify(name: str) -> str:
        for bucket, needles in buckets.items():
            if any(n in name for n in needles):
                return bucket
        return "otros"

    core_by_bucket: dict[str, list[str]] = defaultdict(list)
    for name in sorted(core):
        core_by_bucket[classify(name)].append(name)

    app_only_by_bucket: dict[str, list[str]] = defaultdict(list)
    for name in sorted(app_only):
        app_only_by_bucket[classify(name)].append(name)

    payload = {
        "workspace_crates": len(manifests),
        "core_roots": CORE_ROOTS,
        "core_reachable": sorted(core),
        "app_reachable": sorted(app),
        "app_only": sorted(app_only),
        "core_by_bucket": {k: v for k, v in sorted(core_by_bucket.items())},
        "app_only_by_bucket": {k: v for k, v in sorted(app_only_by_bucket.items())},
        "graph": {k: sorted(v) for k, v in sorted(graph.items())},
    }

    NOTES.mkdir(parents=True, exist_ok=True)
    (NOTES / "dependency-map.json").write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    lines: list[str] = []
    lines.append("# Mapa de dependencias del workspace\n")
    lines.append(f"Generado desde `{ROOT}`.\n")
    lines.append(f"- Crates del workspace: **{len(manifests)}**")
    lines.append(f"- Alcanzables desde el núcleo ({', '.join(CORE_ROOTS)}): **{len(core)}**")
    lines.append(f"- Alcanzables desde `warp` (app): **{len(app)}**")
    lines.append(f"- Solo en la app (no en el núcleo): **{len(app_only)}**\n")

    lines.append("## Núcleo (lo que habría que llevarse a Warp Lite)\n")
    for bucket, names in sorted(core_by_bucket.items()):
        lines.append(f"### {bucket} ({len(names)})\n")
        lines.append(", ".join(f"`{n}`" for n in names) + "\n")

    lines.append("## Solo en la app (candidato a poda)\n")
    for bucket, names in sorted(app_only_by_bucket.items()):
        lines.append(f"### {bucket} ({len(names)})\n")
        lines.append(", ".join(f"`{n}`" for n in names) + "\n")

    lines.append("## Dependencias directas de `warp_terminal`\n")
    lines.append(", ".join(f"`{n}`" for n in sorted(graph.get("warp_terminal", ()))) + "\n")
    lines.append("## Dependencias directas de `warp_editor`\n")
    lines.append(", ".join(f"`{n}`" for n in sorted(graph.get("warp_editor", ()))) + "\n")

    (NOTES / "dependency-map.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"OK: {NOTES / 'dependency-map.md'}")
    print(f"OK: {NOTES / 'dependency-map.json'}")
    print(f"core={len(core)} app={len(app)} app_only={len(app_only)}")


if __name__ == "__main__":
    main()
