# Mapa de dependencias del workspace

Generado desde `D:\dev\warp-lite\warp`.

- Crates del workspace: **83**
- Alcanzables desde el núcleo (warp_terminal, warp_editor, warpui, warpui_core, command, sum_tree, settings): **30**
- Alcanzables desde `warp` (app): **79**
- Solo en la app (no en el núcleo): **49**

## Núcleo (lo que habría que llevarse a Warp Lite)

### cloud/server (1)

`websocket`

### otros (18)

`asset_cache`, `channel_versions`, `fuzzy_match`, `ipynb_parser`, `local_control`, `markdown_parser`, `regex_dfas`, `secret_redaction`, `string-offset`, `virtual-fs`, `warp_assets`, `warp_cli`, `warp_completer`, `warp_core`, `warp_errors`, `warp_features`, `warp_isolation_platform`, `warp_util`

### terminal/ui (11)

`command`, `settings`, `settings_value`, `settings_value_derive`, `sum_tree`, `vim`, `warp_editor`, `warp_terminal`, `warpui`, `warpui_core`, `warpui_extras`

## Solo en la app (candidato a poda)

### agent/ai (7)

`ai`, `ai_types`, `computer_use_mcp`, `mcp`, `voice_input`, `warp_harness_usage`, `warp_multi_agent_client`

### cloud/server (12)

`cloud_object_client`, `cloud_object_models`, `cloud_object_persistence`, `cloud_objects`, `firebase`, `http_client`, `http_server`, `remote_server`, `warp_graphql`, `warp_graphql_schema`, `warp_server_auth`, `warp_server_client`

### editor/code (9)

`languages`, `lsp`, `natural_language_detection`, `repo_metadata`, `syntax_tree`, `warp_files`, `warp_ripgrep`, `warp_search_core`, `watcher`

### otros (18)

`app-installation-detection`, `asset_macro`, `computer_use`, `field_mask`, `handlebars`, `input_classifier`, `ipc`, `jsonrpc`, `node_runtime`, `onboarding`, `persistence`, `prevent_sleep`, `preview_proxy`, `simple_logger`, `warp`, `warp_channel_config`, `warp_managed_secrets`, `warp_web_event_bus`

### telemetry/crash (1)

`warp_logging`

### terminal/ui (2)

`build_cache`, `ui_components`

## Dependencias directas de `warp_terminal`

`channel_versions`, `command`, `regex_dfas`, `secret_redaction`, `string-offset`, `warp_assets`, `warp_cli`, `warp_completer`, `warp_core`, `warp_errors`, `warp_isolation_platform`, `warp_util`, `warpui_core`

## Dependencias directas de `warp_editor`

`asset_cache`, `ipynb_parser`, `markdown_parser`, `string-offset`, `sum_tree`, `vim`, `warp_core`, `warp_errors`, `warp_util`, `warpui`, `warpui_core`
