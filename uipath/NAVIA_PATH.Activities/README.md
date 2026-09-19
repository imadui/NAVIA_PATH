# NAVIA_PATH.Activities

UiPath activity library for integrating **NAVIA_PATH** into UiPath Studio workflows.

---

## Included Activities

### 1. NAVIA PATH - Edge
Automates an intelligent Microsoft Edge session:
- Automatically attaches to the active tab.
- Captures session state and transfers it into the persistent profile at `%LOCALAPPDATA%\NAVIA_PATH\EdgeProfile`.
- Executes `NAVIA_PATH_v1.1.7.exe` synchronously in the background without opening console windows.
- Returns execution result JSON into `out_ExecutionResult`.

### 2. NAVIA PATH - Chrome
Automates an intelligent Google Chrome session:
- Automatically attaches to the active tab.
- Captures session state and transfers it into the persistent profile at `%LOCALAPPDATA%\NAVIA_PATH\ChromeProfile`.
- Executes `NAVIA_PATH_v1.1.7.exe` synchronously in the background without opening console windows.
- Returns execution result JSON into `out_ExecutionResult`.

---

## Activity Arguments

| Argument | Type | Direction | Description |
| :--- | :--- | :--- | :--- |
| `in_UserPrompt` | String | In (Required) | Natural language objective for the agent. |
| `in_MaxIterations` | Int32 | In (Default: 20) | Maximum number of reasoning / action iterations. |
| `in_CloseBrowserAfterExecution` | Boolean | In (Default: False) | Whether to close the browser upon goal completion. |
| `in_NavIAPathExe` | String | In (Optional) | Custom path to `NAVIA_PATH_v1.1.7.exe` if placed outside standard directory. |
| `out_ExecutionResult` | String | Out | Complete JSON execution result string. |
| `out_NavIA_Window` | UiElement | Out | UiElement reference to the attached browser window. |

---

## Dynamic Executable Resolution

The activity automatically discovers `NAVIA_PATH_v1.1.7.exe` using the following fallback order:
1. Argument `in_NavIAPathExe` if explicitly supplied.
2. Environment variable `NAVIA_PATH_EXE`.
3. Environment variable `NAVIA_PATH_HOME` (searches for `NAVIA_PATH_HOME\NAVIA_PATH_v1.1.7.exe`).
4. Distribution parent directory (`..\..\NAVIA_PATH_v1.1.7.exe`).
5. User local application directory `%LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH_v1.1.7.exe`.
6. Current execution directory.
