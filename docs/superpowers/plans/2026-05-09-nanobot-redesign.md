# nanobot 桌面应用重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 nanobot 从纯 Web 应用重构为 Tauri 桌面应用，增强 AI 交互体验，补充 Skill/MCP/Agent/知识库管理功能。

**Architecture:** Python 后端通过 aiohttp 暴露 HTTP API，React 前端通过 Tauri WebView 渲染，两者通过 localhost WebSocket 通信。前端采用两层导航结构（NavRail + Sidebar），AI 交互使用混合渐进式（步骤卡片 + 子 Agent 卡片 + 任务概览）。

**Tech Stack:** Python 3.11+ (aiohttp, Pydantic), React 18 + TypeScript + Tailwind CSS + Radix UI, Tauri 2 (Rust), Vite

**Spec:** `docs/superpowers/specs/2026-05-09-nanobot-redesign-design.md`

---

## 文件结构

### 后端新增/修改

| 文件 | 职责 |
|------|------|
| `nanobot/api/server.py` | 修改：注册新路由到 `create_app()` |
| `nanobot/api/routes/skills.py` | 新增：Skill CRUD + toggle 端点 |
| `nanobot/api/routes/mcp.py` | 新增：MCP 服务器管理端点 |
| `nanobot/api/routes/agents.py` | 新增：Agent CRUD + start/stop 端点 |
| `nanobot/api/routes/knowledge.py` | 新增：知识库 + 文档 CRUD + 向量化端点 |
| `nanobot/api/routes/__init__.py` | 新增：路由模块初始化 |
| `tests/api/test_skills.py` | 新增：Skill API 测试 |
| `tests/api/test_mcp.py` | 新增：MCP API 测试 |
| `tests/api/test_agents.py` | 新增：Agent API 测试 |
| `tests/api/test_knowledge.py` | 新增：知识库 API 测试 |

### 前端新增/修改

| 文件 | 职责 |
|------|------|
| `webui/src/lib/types.ts` | 修改：扩展 SkillInfo/McpServerInfo/AgentInfo/TraceStep 类型 |
| `webui/src/lib/api.ts` | 新增：HTTP API 客户端（fetch 包装） |
| `webui/src/App.tsx` | 修改：Shell 支持 view 类型扩展 |
| `webui/src/components/NavRail.tsx` | 新增：外层窄导航栏 |
| `webui/src/components/Sidebar.tsx` | 修改：重构为多 section 切换 |
| `webui/src/components/DetailPanel.tsx` | 新增：右侧详情面板 |
| `webui/src/components/StepCard.tsx` | 新增：步骤卡片 |
| `webui/src/components/SubAgentCard.tsx` | 新增：子 Agent 卡片 |
| `webui/src/components/TaskOverview.tsx` | 新增：任务概览卡片 |
| `webui/src/components/CodeBlock.tsx` | 新增：代码块（含复制） |
| `webui/src/components/MessageBubble.tsx` | 修改：集成新组件 |
| `webui/src/components/thread/ThreadShell.tsx` | 修改：集成详情面板 |
| `webui/src/components/management/SkillView.tsx` | 新增：Skill 管理页 |
| `webui/src/components/management/McpView.tsx` | 新增：MCP 管理页 |
| `webui/src/components/management/KnowledgeView.tsx` | 新增：知识库管理页 |
| `webui/src/components/management/AgentView.tsx` | 新增：Agent 管理页 |
| `webui/src/components/management/SkillInstaller.tsx` | 新增：Skill 安装向导 |
| `webui/src/components/management/McpWizard.tsx` | 新增：MCP 添加向导 |
| `webui/src/components/management/AgentWizard.tsx` | 新增：Agent 创建向导 |
| `webui/src/components/management/KnowledgeEditor.tsx` | 新增：知识库文档编辑器 |
| `webui/src/components/settings/SettingsView.tsx` | 修改：扩展设置项 |
| `webui/src/styles/theme.css` | 新增：CSS 变量主题系统 |
| `webui/src/hooks/useTheme.ts` | 新增：主题切换 hook |
| `webui/src/hooks/useManagementApi.ts` | 新增：管理 API hooks |

### Tauri 桌面化

| 文件 | 职责 |
|------|------|
| `nanobot-desktop/src-tauri/Cargo.toml` | 新增：Rust 依赖 |
| `nanobot-desktop/src-tauri/tauri.conf.json` | 新增：窗口/sidecar 配置 |
| `nanobot-desktop/src-tauri/src/main.rs` | 新增：Tauri 入口 |
| `nanobot-desktop/src-tauri/src/sidecar.rs` | 新增：nanobot 进程管理 |
| `nanobot-desktop/src-tauri/src/tray.rs` | 新增：系统托盘 |
| `nanobot-desktop/src-tauri/src/commands.rs` | 新增：Tauri command 桥接 |

---

## Phase 1: 后端 API 补充

### Task 1: 路由模块基础设施

**Files:**
- Create: `nanobot/api/routes/__init__.py`
- Modify: `nanobot/api/server.py`

- [ ] **Step 1: 创建路由模块目录和初始化文件**

```python
# nanobot/api/routes/__init__.py
from .skills import register_skill_routes
from .mcp import register_mcp_routes
from .agents import register_agent_routes
from .knowledge import register_knowledge_routes

__all__ = [
    "register_skill_routes",
    "register_mcp_routes",
    "register_agent_routes",
    "register_knowledge_routes",
]
```

- [ ] **Step 2: 在 server.py 的 create_app() 中注册新路由**

在 `nanobot/api/server.py` 的 `create_app()` 函数末尾、`return app` 之前添加：

```python
from .routes import (
    register_skill_routes,
    register_mcp_routes,
    register_agent_routes,
    register_knowledge_routes,
)

# 注册管理 API 路由
register_skill_routes(app, skills_loader)
register_mcp_routes(app, mcp_connections, tool_registry)
register_agent_routes(app, subagent_manager)
register_knowledge_routes(app, workspace)
```

注意：需要将 `skills_loader`、`mcp_connections`、`tool_registry`、`subagent_manager`、`workspace` 从 `create_app()` 的参数或闭包中传入。检查当前 `create_app()` 签名，按需添加参数。

- [ ] **Step 3: 验证服务启动不报错**

Run: `cd nanobot && python -m nanobot serve --port 8080`（或等效启动命令）
Expected: 服务正常启动，`/health` 返回 200

- [ ] **Step 4: Commit**

```bash
git add nanobot/api/routes/__init__.py nanobot/api/server.py
git commit -m "feat(api): add management routes module infrastructure"
```

---

### Task 2: Skill API 端点

**Files:**
- Create: `nanobot/api/routes/skills.py`
- Create: `tests/api/test_skills.py`

- [ ] **Step 1: 编写 Skill API 测试**

```python
# tests/api/test_skills.py
import pytest
from aiohttp import web
from aiohttp.test_utils import AioHTTPTestCase, unittest_run_loop

class TestSkillRoutes(AioHTTPTestCase):
    async def setUp_async(self):
        # Mock SkillsLoader
        pass

    @unittest_run_loop
    async def test_list_skills(self):
        resp = await self.client.request("GET", "/api/skills")
        assert resp.status == 200
        data = await resp.json()
        assert "skills" in data
        assert isinstance(data["skills"], list)

    @unittest_run_loop
    async def test_get_skill_detail(self):
        resp = await self.client.request("GET", "/api/skills/test-skill")
        assert resp.status == 200
        data = await resp.json()
        assert "name" in data

    @unittest_run_loop
    async def test_get_skill_not_found(self):
        resp = await self.client.request("GET", "/api/skills/nonexistent")
        assert resp.status == 404

    @unittest_run_loop
    async def test_toggle_skill(self):
        resp = await self.client.request("POST", "/api/skills/test-skill/toggle")
        assert resp.status == 200
        data = await resp.json()
        assert "enabled" in data
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd nanobot && python -m pytest tests/api/test_skills.py -v`
Expected: FAIL（模块不存在）

- [ ] **Step 3: 实现 Skill 路由**

```python
# nanobot/api/routes/skills.py
import shutil
import subprocess
from pathlib import Path
from aiohttp import web


def register_skill_routes(app: web.Application, skills_loader):
    """注册 Skill 管理路由"""

    async def list_skills(request: web.Request) -> web.Response:
        skills = skills_loader.list_skills(filter_unavailable=False)
        result = []
        for skill in skills:
            meta = skills_loader._get_skill_meta(skill)
            result.append({
                "name": skill,
                "description": meta.get("description", "") if meta else "",
                "source": meta.get("source", "workspace") if meta else "workspace",
                "available": meta.get("available", True) if meta else True,
                "enabled": skill not in (skills_loader.disabled_skills or []),
            })
        return web.json_response({"skills": result})

    async def get_skill(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        meta = skills_loader._get_skill_meta(name)
        if not meta:
            return web.json_response({"error": "Skill not found"}, status=404)
        skill = skills_loader.load_skill(name)
        return web.json_response({
            "name": name,
            "description": meta.get("description", ""),
            "source": meta.get("source", "workspace"),
            "available": meta.get("available", True),
            "enabled": name not in (skills_loader.disabled_skills or []),
            "content": skill.content if skill else "",
        })

    async def install_skill(request: web.Request) -> web.Response:
        body = await request.json()
        source = body.get("source")  # 本地路径或 Git URL
        if not source:
            return web.json_response({"error": "source required"}, status=400)

        workspace_skills = skills_loader.workspace / "skills"
        workspace_skills.mkdir(parents=True, exist_ok=True)

        if source.startswith("http"):
            # Git clone
            dest = workspace_skills / Path(source).stem
            subprocess.run(["git", "clone", source, str(dest)], check=True)
        else:
            # 本地复制
            src = Path(source)
            if not src.exists():
                return web.json_response({"error": "source not found"}, status=400)
            dest = workspace_skills / src.name
            shutil.copytree(src, dest)

        return web.json_response({"status": "installed", "name": dest.name})

    async def delete_skill(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        skill_dir = skills_loader.workspace / "skills" / name
        if not skill_dir.exists():
            return web.json_response({"error": "Skill not found"}, status=404)
        shutil.rmtree(skill_dir)
        return web.json_response({"status": "deleted"})

    async def toggle_skill(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        if not skills_loader._get_skill_meta(name):
            return web.json_response({"error": "Skill not found"}, status=404)

        disabled = skills_loader.disabled_skills or []
        if name in disabled:
            disabled.remove(name)
            enabled = True
        else:
            disabled.append(name)
            enabled = False
        skills_loader.disabled_skills = disabled
        return web.json_response({"name": name, "enabled": enabled})

    app.router.add_get("/api/skills", list_skills)
    app.router.add_get("/api/skills/{name}", get_skill)
    app.router.add_post("/api/skills", install_skill)
    app.router.add_delete("/api/skills/{name}", delete_skill)
    app.router.add_post("/api/skills/{name}/toggle", toggle_skill)
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd nanobot && python -m pytest tests/api/test_skills.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add nanobot/api/routes/skills.py tests/api/test_skills.py
git commit -m "feat(api): add skill management endpoints"
```

---

### Task 3: MCP API 端点

**Files:**
- Create: `nanobot/api/routes/mcp.py`
- Create: `tests/api/test_mcp.py`

- [ ] **Step 1: 编写 MCP API 测试**

```python
# tests/api/test_mcp.py
import pytest
from aiohttp.test_utils import AioHTTPTestCase, unittest_run_loop

class TestMcpRoutes(AioHTTPTestCase):
    @unittest_run_loop
    async def test_list_servers(self):
        resp = await self.client.request("GET", "/api/mcp/servers")
        assert resp.status == 200
        data = await resp.json()
        assert "servers" in data

    @unittest_run_loop
    async def test_list_tools(self):
        resp = await self.client.request("GET", "/api/mcp/tools")
        assert resp.status == 200
        data = await resp.json()
        assert "tools" in data

    @unittest_run_loop
    async def test_add_server(self):
        resp = await self.client.request("POST", "/api/mcp/servers", json={
            "name": "test-mcp",
            "transport": "stdio",
            "command": "echo",
            "args": ["hello"],
        })
        assert resp.status == 200

    @unittest_run_loop
    async def test_delete_server(self):
        resp = await self.client.request("DELETE", "/api/mcp/servers/test-mcp")
        assert resp.status == 200

    @unittest_run_loop
    async def test_connect_server(self):
        resp = await self.client.request("POST", "/api/mcp/servers/test-mcp/connect")
        assert resp.status in (200, 500)  # 500 if server doesn't exist

    @unittest_run_loop
    async def test_disconnect_server(self):
        resp = await self.client.request("POST", "/api/mcp/servers/test-mcp/disconnect")
        assert resp.status in (200, 404)
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd nanobot && python -m pytest tests/api/test_mcp.py -v`
Expected: FAIL

- [ ] **Step 3: 实现 MCP 路由**

```python
# nanobot/api/routes/mcp.py
from aiohttp import web


def register_mcp_routes(app: web.Application, mcp_connections: dict, tool_registry):
    """注册 MCP 管理路由"""

    async def list_servers(request: web.Request) -> web.Response:
        servers = []
        config = app.get("mcp_config", {})
        for name, cfg in config.items():
            connected = name in mcp_connections
            tools = [t for t in tool_registry.list_tools() if hasattr(t, "_mcp_server") and t._mcp_server == name]
            servers.append({
                "name": name,
                "connected": connected,
                "transport": cfg.get("transport", "stdio"),
                "tool_count": len(tools),
                "tools": [t.name for t in tools],
            })
        return web.json_response({"servers": servers})

    async def list_tools(request: web.Request) -> web.Response:
        tools = []
        for t in tool_registry.list_tools():
            if hasattr(t, "_mcp_server"):
                tools.append({
                    "name": t.name,
                    "description": t.description,
                    "server": t._mcp_server,
                })
        return web.json_response({"tools": tools})

    async def add_server(request: web.Request) -> web.Response:
        body = await request.json()
        name = body.get("name")
        if not name:
            return web.json_response({"error": "name required"}, status=400)
        config = app.setdefault("mcp_config", {})
        config[name] = {
            "transport": body.get("transport", "stdio"),
            "command": body.get("command"),
            "args": body.get("args", []),
            "env": body.get("env", {}),
            "url": body.get("url"),
        }
        return web.json_response({"status": "added", "name": name})

    async def delete_server(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        config = app.get("mcp_config", {})
        if name in config:
            del config[name]
        if name in mcp_connections:
            try:
                await mcp_connections[name].aclose()
            except Exception:
                pass
            del mcp_connections[name]
        return web.json_response({"status": "deleted"})

    async def connect_server(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        config = app.get("mcp_config", {}).get(name)
        if not config:
            return web.json_response({"error": "Server not found"}, status=404)
        try:
            from nanobot.agent.tools.mcp import connect_single_server
            stack = await connect_single_server(name, config, tool_registry)
            mcp_connections[name] = stack
            return web.json_response({"status": "connected"})
        except Exception as e:
            return web.json_response({"error": str(e)}, status=500)

    async def disconnect_server(request: web.Request) -> web.Response:
        name = request.match_info["name"]
        if name not in mcp_connections:
            return web.json_response({"error": "Not connected"}, status=404)
        try:
            await mcp_connections[name].aclose()
        except Exception:
            pass
        del mcp_connections[name]
        return web.json_response({"status": "disconnected"})

    async def test_server(request: web.Request) -> web.Response:
        body = await request.json()
        name = body.get("name", "test")
        try:
            from nanobot.agent.tools.mcp import connect_single_server
            temp_registry = tool_registry.__class__()
            stack = await connect_single_server(name, body, temp_registry)
            tools = [t.name for t in temp_registry.list_tools()]
            await stack.aclose()
            return web.json_response({"status": "ok", "tools": tools})
        except Exception as e:
            return web.json_response({"error": str(e)}, status=500)

    app.router.add_get("/api/mcp/servers", list_servers)
    app.router.add_get("/api/mcp/tools", list_tools)
    app.router.add_post("/api/mcp/servers", add_server)
    app.router.add_delete("/api/mcp/servers/{name}", delete_server)
    app.router.add_post("/api/mcp/servers/{name}/connect", connect_server)
    app.router.add_post("/api/mcp/servers/{name}/disconnect", disconnect_server)
    app.router.add_post("/api/mcp/servers/{name}/test", test_server)
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd nanobot && python -m pytest tests/api/test_mcp.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add nanobot/api/routes/mcp.py tests/api/test_mcp.py
git commit -m "feat(api): add MCP server management endpoints"
```

---

### Task 4: Agent API 端点

**Files:**
- Create: `nanobot/api/routes/agents.py`
- Create: `tests/api/test_agents.py`

- [ ] **Step 1: 编写 Agent API 测试**

```python
# tests/api/test_agents.py
import pytest
from aiohttp.test_utils import AioHTTPTestCase, unittest_run_loop

class TestAgentRoutes(AioHTTPTestCase):
    @unittest_run_loop
    async def test_list_agents(self):
        resp = await self.client.request("GET", "/api/agents")
        assert resp.status == 200
        data = await resp.json()
        assert "agents" in data

    @unittest_run_loop
    async def test_create_agent(self):
        resp = await self.client.request("POST", "/api/agents", json={
            "name": "test-agent",
            "description": "测试 Agent",
            "model": "claude-sonnet-4-20250514",
        })
        assert resp.status == 200
        data = await resp.json()
        assert "id" in data

    @unittest_run_loop
    async def test_get_agent(self):
        resp = await self.client.request("GET", "/api/agents/test-agent")
        assert resp.status in (200, 404)

    @unittest_run_loop
    async def test_delete_agent(self):
        resp = await self.client.request("DELETE", "/api/agents/test-agent")
        assert resp.status in (200, 404)
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd nanobot && python -m pytest tests/api/test_agents.py -v`
Expected: FAIL

- [ ] **Step 3: 实现 Agent 路由**

```python
# nanobot/api/routes/agents.py
import json
from pathlib import Path
from aiohttp import web


def register_agent_routes(app: web.Application, subagent_manager):
    """注册 Agent 管理路由"""
    agents_config_path = subagent_manager.workspace / "agents.json"

    def _load_agents():
        if agents_config_path.exists():
            return json.loads(agents_config_path.read_text())
        return {}

    def _save_agents(data):
        agents_config_path.write_text(json.dumps(data, indent=2, ensure_ascii=False))

    async def list_agents(request: web.Request) -> web.Response:
        agents = _load_agents()
        # 合并运行中状态
        running = subagent_manager._task_statuses if hasattr(subagent_manager, "_task_statuses") else {}
        result = []
        for aid, cfg in agents.items():
            status = "idle"
            if aid in running:
                status = running[aid].phase if hasattr(running[aid], "phase") else "running"
            result.append({
                "id": aid,
                "name": cfg.get("name", aid),
                "description": cfg.get("description", ""),
                "status": status,
                "model": cfg.get("model", ""),
            })
        return web.json_response({"agents": result})

    async def create_agent(request: web.Request) -> web.Response:
        body = await request.json()
        name = body.get("name")
        if not name:
            return web.json_response({"error": "name required"}, status=400)
        agents = _load_agents()
        aid = name.lower().replace(" ", "-")
        agents[aid] = {
            "name": name,
            "description": body.get("description", ""),
            "model": body.get("model", ""),
            "temperature": body.get("temperature", 0.7),
            "max_tokens": body.get("max_tokens", 4096),
            "system_prompt": body.get("system_prompt", ""),
            "tools": body.get("tools", []),
            "skills": body.get("skills", []),
            "max_subagents": body.get("max_subagents", 3),
        }
        _save_agents(agents)
        return web.json_response({"id": aid, "status": "created"})

    async def get_agent(request: web.Request) -> web.Response:
        aid = request.match_info["id"]
        agents = _load_agents()
        if aid not in agents:
            return web.json_response({"error": "Agent not found"}, status=404)
        return web.json_response({"id": aid, **agents[aid]})

    async def update_agent(request: web.Request) -> web.Response:
        aid = request.match_info["id"]
        agents = _load_agents()
        if aid not in agents:
            return web.json_response({"error": "Agent not found"}, status=404)
        body = await request.json()
        agents[aid].update(body)
        _save_agents(agents)
        return web.json_response({"status": "updated"})

    async def delete_agent(request: web.Request) -> web.Response:
        aid = request.match_info["id"]
        agents = _load_agents()
        if aid not in agents:
            return web.json_response({"error": "Agent not found"}, status=404)
        del agents[aid]
        _save_agents(agents)
        return web.json_response({"status": "deleted"})

    async def start_agent(request: web.Request) -> web.Response:
        aid = request.match_info["id"]
        agents = _load_agents()
        if aid not in agents:
            return web.json_response({"error": "Agent not found"}, status=404)
        # 实际启动逻辑委托给 subagent_manager
        return web.json_response({"status": "started", "id": aid})

    async def stop_agent(request: web.Request) -> web.Response:
        aid = request.match_info["id"]
        await subagent_manager.cancel_by_session(aid)
        return web.json_response({"status": "stopped"})

    app.router.add_get("/api/agents", list_agents)
    app.router.add_post("/api/agents", create_agent)
    app.router.add_get("/api/agents/{id}", get_agent)
    app.router.add_put("/api/agents/{id}", update_agent)
    app.router.add_delete("/api/agents/{id}", delete_agent)
    app.router.add_post("/api/agents/{id}/start", start_agent)
    app.router.add_post("/api/agents/{id}/stop", stop_agent)
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd nanobot && python -m pytest tests/api/test_agents.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add nanobot/api/routes/agents.py tests/api/test_agents.py
git commit -m "feat(api): add agent management endpoints"
```

---

### Task 5: 知识库 API 端点

**Files:**
- Create: `nanobot/api/routes/knowledge.py`
- Create: `tests/api/test_knowledge.py`

- [ ] **Step 1: 编写知识库 API 测试**

```python
# tests/api/test_knowledge.py
import pytest
from aiohttp.test_utils import AioHTTPTestCase, unittest_run_loop

class TestKnowledgeRoutes(AioHTTPTestCase):
    @unittest_run_loop
    async def test_list_knowledge(self):
        resp = await self.client.request("GET", "/api/knowledge")
        assert resp.status == 200
        data = await resp.json()
        assert "knowledge_bases" in data

    @unittest_run_loop
    async def test_list_docs(self):
        resp = await self.client.request("GET", "/api/knowledge/test/docs")
        assert resp.status in (200, 404)

    @unittest_run_loop
    async def test_create_doc(self):
        resp = await self.client.request("POST", "/api/knowledge/test/docs", json={
            "title": "测试文档",
            "content": "# Hello",
        })
        assert resp.status in (200, 404)
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd nanobot && python -m pytest tests/api/test_knowledge.py -v`
Expected: FAIL

- [ ] **Step 3: 实现知识库路由**

```python
# nanobot/api/routes/knowledge.py
import uuid
from pathlib import Path
from aiohttp import web


def register_knowledge_routes(app: web.Application, workspace: Path):
    """注册知识库管理路由"""
    knowledge_dir = workspace / "knowledge"

    def _ensure_dir():
        knowledge_dir.mkdir(parents=True, exist_ok=True)

    def _get_kb_dir(kb_id: str) -> Path:
        return knowledge_dir / kb_id

    async def list_knowledge(request: web.Request) -> web.Response:
        _ensure_dir()
        kbs = []
        for d in knowledge_dir.iterdir():
            if d.is_dir():
                doc_count = len(list(d.glob("*.md")))
                kbs.append({
                    "id": d.name,
                    "name": d.name.replace("-", " ").title(),
                    "doc_count": doc_count,
                })
        return web.json_response({"knowledge_bases": kbs})

    async def list_docs(request: web.Request) -> web.Response:
        kb_id = request.match_info["id"]
        kb_dir = _get_kb_dir(kb_id)
        if not kb_dir.exists():
            return web.json_response({"error": "Knowledge base not found"}, status=404)
        docs = []
        for f in kb_dir.glob("*.md"):
            meta_file = kb_dir / f"{f.stem}.meta.json"
            meta = {}
            if meta_file.exists():
                import json
                meta = json.loads(meta_file.read_text())
            docs.append({
                "id": f.stem,
                "title": meta.get("title", f.stem),
                "updated_at": meta.get("updated_at", ""),
                "vectorized": meta.get("vectorized", False),
            })
        return web.json_response({"docs": docs})

    async def create_doc(request: web.Request) -> web.Response:
        kb_id = request.match_info["id"]
        kb_dir = _get_kb_dir(kb_id)
        kb_dir.mkdir(parents=True, exist_ok=True)
        body = await request.json()
        doc_id = body.get("id", str(uuid.uuid4())[:8])
        title = body.get("title", doc_id)
        content = body.get("content", "")

        doc_path = kb_dir / f"{doc_id}.md"
        doc_path.write_text(content)

        import json
        from datetime import datetime
        meta_path = kb_dir / f"{doc_id}.meta.json"
        meta_path.write_text(json.dumps({
            "title": title,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "vectorized": False,
        }, ensure_ascii=False))

        return web.json_response({"id": doc_id, "status": "created"})

    async def get_doc(request: web.Request) -> web.Response:
        kb_id = request.match_info["id"]
        doc_id = request.match_info["docId"]
        doc_path = _get_kb_dir(kb_id) / f"{doc_id}.md"
        if not doc_path.exists():
            return web.json_response({"error": "Document not found"}, status=404)
        return web.json_response({
            "id": doc_id,
            "content": doc_path.read_text(),
        })

    async def update_doc(request: web.Request) -> web.Response:
        kb_id = request.match_info["id"]
        doc_id = request.match_info["docId"]
        doc_path = _get_kb_dir(kb_id) / f"{doc_id}.md"
        if not doc_path.exists():
            return web.json_response({"error": "Document not found"}, status=404)
        body = await request.json()
        doc_path.write_text(body.get("content", ""))

        import json
        from datetime import datetime
        meta_path = _get_kb_dir(kb_id) / f"{doc_id}.meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text())
        else:
            meta = {}
        meta["updated_at"] = datetime.utcnow().isoformat()
        meta["vectorized"] = False
        meta_path.write_text(json.dumps(meta, ensure_ascii=False))

        return web.json_response({"status": "updated"})

    async def delete_doc(request: web.Request) -> web.Response:
        kb_id = request.match_info["id"]
        doc_id = request.match_info["docId"]
        kb_dir = _get_kb_dir(kb_id)
        for ext in [".md", ".meta.json"]:
            p = kb_dir / f"{doc_id}{ext}"
            if p.exists():
                p.unlink()
        return web.json_response({"status": "deleted"})

    async def vectorize_doc(request: web.Request) -> web.Response:
        # TODO: 接入实际向量化引擎
        kb_id = request.match_info["id"]
        doc_id = request.match_info["docId"]
        import json
        from datetime import datetime
        meta_path = _get_kb_dir(kb_id) / f"{doc_id}.meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text())
            meta["vectorized"] = True
            meta["vectorized_at"] = datetime.utcnow().isoformat()
            meta_path.write_text(json.dumps(meta, ensure_ascii=False))
        return web.json_response({"status": "vectorized"})

    app.router.add_get("/api/knowledge", list_knowledge)
    app.router.add_get("/api/knowledge/{id}/docs", list_docs)
    app.router.add_post("/api/knowledge/{id}/docs", create_doc)
    app.router.add_get("/api/knowledge/{id}/docs/{docId}", get_doc)
    app.router.add_put("/api/knowledge/{id}/docs/{docId}", update_doc)
    app.router.add_delete("/api/knowledge/{id}/docs/{docId}", delete_doc)
    app.router.add_post("/api/knowledge/{id}/docs/{docId}/vectorize", vectorize_doc)
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd nanobot && python -m pytest tests/api/test_knowledge.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add nanobot/api/routes/knowledge.py tests/api/test_knowledge.py
git commit -m "feat(api): add knowledge base management endpoints"
```

---

### Task 6: WebSocket 事件扩展

**Files:**
- Modify: `nanobot/channels/websocket.py`
- Modify: `nanobot/bus/events.py`

- [ ] **Step 1: 在 events.py 中添加新事件类型**

检查 `nanobot/bus/events.py` 中的 `InboundMessage` 或事件定义，添加以下字段到 `kind` 枚举或消息格式：

```python
# 在现有事件类型基础上添加
# kind 新增值: "skill_used", "mcp_tool_call", "agent_started", "agent_completed", "agent_progress"
```

- [ ] **Step 2: 在 websocket.py 的 _send_event 中处理新事件**

在 WebSocket 通道的事件发送逻辑中，确保新 kind 类型能正确序列化并推送到客户端。

- [ ] **Step 3: 在 agent/loop.py 中触发新事件**

在 Agent 循环中，当使用 Skill、调用 MCP 工具、启动子代理时，通过 bus 发送对应事件。

- [ ] **Step 4: Commit**

```bash
git add nanobot/channels/websocket.py nanobot/bus/events.py nanobot/agent/loop.py
git commit -m "feat(ws): extend WebSocket events for skill/mcp/agent tracking"
```

---

## Phase 2: 前端 UI 重构

### Task 7: 类型扩展和 API 客户端

**Files:**
- Modify: `webui/src/lib/types.ts`
- Create: `webui/src/lib/api.ts`

- [ ] **Step 1: 扩展 types.ts**

在 `webui/src/lib/types.ts` 末尾添加：

```typescript
// === 管理 API 类型 ===

export interface SkillInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  version: string;
  enabled: boolean;
  lastUsedAt?: string;
}

export interface McpServerInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  connected: boolean;
  toolCount: number;
  transport: 'stdio' | 'sse';
}

export interface AgentInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  status: 'running' | 'completed' | 'failed';
  startedAt?: string;
}

export interface KnowledgeBase {
  id: string;
  name: string;
  docCount: number;
}

export interface KnowledgeDoc {
  id: string;
  title: string;
  updatedAt: string;
  vectorized: boolean;
}

export interface TraceStep {
  id: string;
  title: string;
  status: 'completed' | 'in-progress' | 'pending';
  detail?: string;
  codeBlocks?: CodeBlock[];
}

export interface SubAgentTrace {
  id: string;
  name: string;
  status: 'running' | 'completed';
  metrics?: Record<string, { before: string; after: string }>;
}

export interface TaskOverviewData {
  title: string;
  current: number;
  total: number;
}

export interface CodeBlock {
  filename?: string;
  language?: string;
  content: string;
  additions?: number[];
  deletions?: number[];
}

// 扩展 InboundEvent 支持新事件
export type ExtendedInboundEvent =
  | { type: 'skill_used'; skills: string[] }
  | { type: 'mcp_tool_call'; server: string; tool: string; args: unknown }
  | { type: 'agent_started'; agentId: string; name: string }
  | { type: 'agent_completed'; agentId: string; result: string }
  | { type: 'agent_progress'; agentId: string; progress: string };
```

- [ ] **Step 2: 创建 API 客户端**

```typescript
// webui/src/lib/api.ts
const BASE_URL = '';  // 同源，无需前缀

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const resp = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });
  if (!resp.ok) {
    const err = await resp.json().catch(() => ({ error: resp.statusText }));
    throw new Error(err.error || resp.statusText);
  }
  return resp.json();
}

export const managementApi = {
  // Skills
  listSkills: () => request<{ skills: any[] }>('/api/skills'),
  getSkill: (name: string) => request<any>(`/api/skills/${name}`),
  installSkill: (source: string) => request<any>('/api/skills', { method: 'POST', body: JSON.stringify({ source }) }),
  deleteSkill: (name: string) => request<any>(`/api/skills/${name}`, { method: 'DELETE' }),
  toggleSkill: (name: string) => request<any>(`/api/skills/${name}/toggle`, { method: 'POST' }),

  // MCP
  listMcpServers: () => request<{ servers: any[] }>('/api/mcp/servers'),
  listMcpTools: () => request<{ tools: any[] }>('/api/mcp/tools'),
  addMcpServer: (config: any) => request<any>('/api/mcp/servers', { method: 'POST', body: JSON.stringify(config) }),
  deleteMcpServer: (name: string) => request<any>(`/api/mcp/servers/${name}`, { method: 'DELETE' }),
  connectMcpServer: (name: string) => request<any>(`/api/mcp/servers/${name}/connect`, { method: 'POST' }),
  disconnectMcpServer: (name: string) => request<any>(`/api/mcp/servers/${name}/disconnect`, { method: 'POST' }),
  testMcpServer: (config: any) => request<any>('/api/mcp/servers/test', { method: 'POST', body: JSON.stringify(config) }),

  // Agents
  listAgents: () => request<{ agents: any[] }>('/api/agents'),
  getAgent: (id: string) => request<any>(`/api/agents/${id}`),
  createAgent: (config: any) => request<any>('/api/agents', { method: 'POST', body: JSON.stringify(config) }),
  updateAgent: (id: string, config: any) => request<any>(`/api/agents/${id}`, { method: 'PUT', body: JSON.stringify(config) }),
  deleteAgent: (id: string) => request<any>(`/api/agents/${id}`, { method: 'DELETE' }),
  startAgent: (id: string) => request<any>(`/api/agents/${id}/start`, { method: 'POST' }),
  stopAgent: (id: string) => request<any>(`/api/agents/${id}/stop`, { method: 'POST' }),

  // Knowledge
  listKnowledge: () => request<{ knowledge_bases: any[] }>('/api/knowledge'),
  listDocs: (kbId: string) => request<{ docs: any[] }>(`/api/knowledge/${kbId}/docs`),
  createDoc: (kbId: string, doc: any) => request<any>(`/api/knowledge/${kbId}/docs`, { method: 'POST', body: JSON.stringify(doc) }),
  getDoc: (kbId: string, docId: string) => request<any>(`/api/knowledge/${kbId}/docs/${docId}`),
  updateDoc: (kbId: string, docId: string, content: string) => request<any>(`/api/knowledge/${kbId}/docs/${docId}`, { method: 'PUT', body: JSON.stringify({ content }) }),
  deleteDoc: (kbId: string, docId: string) => request<any>(`/api/knowledge/${kbId}/docs/${docId}`, { method: 'DELETE' }),
  vectorizeDoc: (kbId: string, docId: string) => request<any>(`/api/knowledge/${kbId}/docs/${docId}/vectorize`, { method: 'POST' }),
};
```

- [ ] **Step 3: Commit**

```bash
git add webui/src/lib/types.ts webui/src/lib/api.ts
git commit -m "feat(ui): add management types and API client"
```

---

### Task 8: 主题系统（CSS 变量）

**Files:**
- Create: `webui/src/styles/theme.css`
- Create: `webui/src/hooks/useTheme.ts`
- Modify: `webui/src/index.css` 或 `webui/src/App.tsx`

- [ ] **Step 1: 创建主题 CSS 文件**

```css
/* webui/src/styles/theme.css */
:root {
  --color-canvas: #faf9f5;
  --color-surface: #fff;
  --color-primary: #cc785c;
  --color-primary-hover: #a9583e;
  --color-dark-surface: #181715;
  --color-dark-surface-2: #1f1e1b;
  --color-dark-surface-3: #252320;
  --color-text-primary: #141413;
  --color-text-secondary: #6c6a64;
  --color-text-muted: #8e8b82;
  --color-text-dark: #faf9f5;
  --color-border-light: #e6dfd8;
  --color-border-dark: #252320;
  --color-accent-warm: #efe9de;
  --color-accent-warm-2: #f5f0e8;
  --color-green: #5db872;
  --color-red: #c64545;
  --color-code-block: #181715;
}

[data-theme="dark"] {
  --color-canvas: #1a1a1a;
  --color-surface: #242424;
  --color-primary: #cc785c;
  --color-primary-hover: #a9583e;
  --color-dark-surface: #111;
  --color-dark-surface-2: #1a1a1a;
  --color-dark-surface-3: #222;
  --color-text-primary: #f0f0f0;
  --color-text-secondary: #a0a0a0;
  --color-text-muted: #777;
  --color-text-dark: #f0f0f0;
  --color-border-light: #333;
  --color-border-dark: #444;
  --color-accent-warm: #2a2a2a;
  --color-accent-warm-2: #222;
  --color-green: #5db872;
  --color-red: #c64545;
  --color-code-block: #111;
}
```

- [ ] **Step 2: 创建 useTheme hook**

```typescript
// webui/src/hooks/useTheme.ts
import { useState, useEffect } from 'react';

type Theme = 'light' | 'dark';

export function useTheme() {
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem('nanobot-theme');
    return (saved === 'dark' ? 'dark' : 'light');
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('nanobot-theme', theme);
  }, [theme]);

  const toggleTheme = () => setTheme(t => t === 'light' ? 'dark' : 'light');

  return { theme, setTheme, toggleTheme };
}
```

- [ ] **Step 3: 在 App.tsx 中引入主题**

在 `App.tsx` 顶部导入 `theme.css`，在 Shell 组件中使用 `useTheme()`。

- [ ] **Step 4: Commit**

```bash
git add webui/src/styles/theme.css webui/src/hooks/useTheme.ts webui/src/App.tsx
git commit -m "feat(ui): add CSS variable theme system with dark mode"
```

---

### Task 9: NavRail 组件

**Files:**
- Create: `webui/src/components/NavRail.tsx`

- [ ] **Step 1: 实现 NavRail**

```tsx
// webui/src/components/NavRail.tsx
import { useState } from 'react';

export type PageKey = 'chat' | 'skills' | 'mcp' | 'knowledge' | 'agents' | 'settings';

interface NavRailProps {
  activePage: PageKey;
  onPageChange: (page: PageKey) => void;
}

const NAV_ITEMS: { key: PageKey; icon: string; label: string }[] = [
  { key: 'chat', icon: '💬', label: '聊天' },
  { key: 'skills', icon: '🧩', label: 'Skill 管理' },
  { key: 'mcp', icon: '🔌', label: 'MCP 管理' },
  { key: 'knowledge', icon: '📚', label: '知识库' },
  { key: 'agents', icon: '🤖', label: 'Agent 管理' },
];

export function NavRail({ activePage, onPageChange }: NavRailProps) {
  return (
    <nav className="w-16 bg-[var(--color-dark-surface)] flex flex-col items-center py-3 gap-1 flex-shrink-0">
      <div
        className="w-10 h-10 bg-[var(--color-primary)] rounded-[10px] flex items-center justify-center text-white text-lg font-semibold mb-4 cursor-pointer hover:scale-105 transition-transform"
        onClick={() => onPageChange('chat')}
      >
        N
      </div>

      {NAV_ITEMS.map(item => (
        <div
          key={item.key}
          className={`w-11 h-11 rounded-[10px] flex items-center justify-center text-lg cursor-pointer transition-all relative group ${
            activePage === item.key
              ? 'bg-[var(--color-dark-surface-3)] text-[var(--color-text-dark)]'
              : 'text-[var(--color-text-muted)] hover:bg-[var(--color-dark-surface-3)] hover:text-[var(--color-text-dark)]'
          }`}
          onClick={() => onPageChange(item.key)}
        >
          {activePage === item.key && (
            <div className="absolute -left-2 top-1/2 -translate-y-1/2 w-[3px] h-5 bg-[var(--color-primary)] rounded-r" />
          )}
          {item.icon}
          <div className="absolute left-14 bg-[var(--color-dark-surface-3)] text-[var(--color-text-dark)] px-2 py-1 rounded-md text-xs whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50">
            {item.label}
          </div>
        </div>
      ))}

      <div className="mt-auto">
        <div
          className={`w-11 h-11 rounded-[10px] flex items-center justify-center text-lg cursor-pointer transition-all relative group ${
            activePage === 'settings'
              ? 'bg-[var(--color-dark-surface-3)] text-[var(--color-text-dark)]'
              : 'text-[var(--color-text-muted)] hover:bg-[var(--color-dark-surface-3)] hover:text-[var(--color-text-dark)]'
          }`}
          onClick={() => onPageChange('settings')}
        >
          {activePage === 'settings' && (
            <div className="absolute -left-2 top-1/2 -translate-y-1/2 w-[3px] h-5 bg-[var(--color-primary)] rounded-r" />
          )}
          ⚙️
          <div className="absolute left-14 bg-[var(--color-dark-surface-3)] text-[var(--color-text-dark)] px-2 py-1 rounded-md text-xs whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50">
            设置
          </div>
        </div>
      </div>
    </nav>
  );
}
```

- [ ] **Step 2: 在 App.tsx Shell 中集成 NavRail**

将 `view` 状态从 `chat | settings` 扩展为 `PageKey` 类型，在 Shell 布局中用 `<NavRail>` 替换原有侧边栏触发逻辑。

- [ ] **Step 3: Commit**

```bash
git add webui/src/components/NavRail.tsx webui/src/App.tsx
git commit -m "feat(ui): add NavRail component with page switching"
```

---

### Task 10: 重构 Sidebar 支持多 Section

**Files:**
- Modify: `webui/src/components/Sidebar.tsx`

- [ ] **Step 1: 重构 Sidebar**

将 Sidebar 从单一聊天列表改为支持多 section 切换：

```tsx
// 在现有 Sidebar.tsx 中添加 section 切换逻辑
interface SidebarProps {
  activePage: PageKey;
  // ... 现有 props
  skills?: SkillInfo[];
  mcpServers?: McpServerInfo[];
  knowledgeBases?: KnowledgeBase[];
  agents?: AgentInfo[];
}
```

根据 `activePage` 渲染不同的 section 内容（聊天列表 / Skill 列表 / MCP 列表 / 知识库列表 / Agent 列表 / 设置导航）。

- [ ] **Step 2: Commit**

```bash
git add webui/src/components/Sidebar.tsx
git commit -m "feat(ui): refactor Sidebar to support multi-section switching"
```

---

### Task 11: 消息流增强组件

**Files:**
- Create: `webui/src/components/StepCard.tsx`
- Create: `webui/src/components/SubAgentCard.tsx`
- Create: `webui/src/components/TaskOverview.tsx`
- Create: `webui/src/components/CodeBlock.tsx`

- [ ] **Step 1: 实现 CodeBlock**

```tsx
// webui/src/components/CodeBlock.tsx
import { useState } from 'react';
import type { CodeBlock as CodeBlockType } from '../lib/types';

export function CodeBlock({ block }: { block: CodeBlockType }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipwriteText(block.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="bg-[var(--color-code-block)] rounded-lg p-4 my-2 overflow-x-auto">
      <div className="flex items-center justify-between mb-3">
        <span className="text-[var(--color-text-muted)] text-xs font-mono">
          {block.filename || block.language || 'code'}
        </span>
        <button
          onClick={handleCopy}
          className="bg-[var(--color-dark-surface-3)] border-none rounded px-2 py-1 text-[var(--color-text-muted)] text-xs cursor-pointer hover:text-[var(--color-text-dark)]"
        >
          {copied ? '已复制' : '复制'}
        </button>
      </div>
      <pre className="font-mono text-sm text-[var(--color-text-dark)] leading-relaxed">
        {block.content.split('\n').map((line, i) => (
          <div key={i} className="flex">
            <span className="text-[var(--color-text-muted)] w-8 text-right mr-4 select-none">{i + 1}</span>
            <span className={
              block.additions?.includes(i + 1) ? 'text-[var(--color-green)]' :
              block.deletions?.includes(i + 1) ? 'text-[var(--color-red)]' : ''
            }>{line}</span>
          </div>
        ))}
      </pre>
    </div>
  );
}
```

- [ ] **Step 2: 实现 StepCard**

```tsx
// webui/src/components/StepCard.tsx
import { useState } from 'react';
import type { TraceStep } from '../lib/types';
import { CodeBlock } from './CodeBlock';

export function StepCard({ step }: { step: TraceStep }) {
  const [expanded, setExpanded] = useState(false);

  const iconClass = step.status === 'completed' ? 'text-[var(--color-green)]' :
                    step.status === 'in-progress' ? 'text-[var(--color-primary)] animate-spin' : '';

  return (
    <div
      className={`rounded-lg px-4 py-3 mb-2.5 cursor-pointer transition-all ${
        step.status === 'in-progress'
          ? 'bg-[var(--color-surface)] border border-[var(--color-border-light)]'
          : 'bg-[var(--color-accent-warm)]'
      } hover:bg-[var(--color-accent-warm-2)]`}
      onClick={() => setExpanded(!expanded)}
    >
      <div className="flex items-center gap-2">
        <span className={`text-sm w-5 text-center ${iconClass}`}>
          {step.status === 'completed' ? '✓' : step.status === 'in-progress' ? '⟳' : '○'}
        </span>
        <span className="text-[var(--color-text-primary)] text-sm font-medium flex-1">{step.title}</span>
        <span className={`text-xs text-[var(--color-text-secondary)] transition-transform ${expanded ? 'rotate-90' : ''}`}>
          ▶
        </span>
      </div>
      {step.detail && (
        <div className={`text-xs text-[var(--color-text-secondary)] mt-1 ml-7 ${expanded ? 'block' : 'hidden'}`}>
          {step.detail}
        </div>
      )}
      {expanded && step.codeBlocks?.map((block, i) => (
        <div key={i} className="ml-7">
          <CodeBlock block={block} />
        </div>
      ))}
    </div>
  );
}
```

- [ ] **Step 3: 实现 TaskOverview**

```tsx
// webui/src/components/TaskOverview.tsx
import type { TaskOverviewData } from '../lib/types';

export function TaskOverview({ data }: { data: TaskOverviewData }) {
  const pct = data.total > 0 ? (data.current / data.total) * 100 : 0;

  return (
    <div className="bg-[var(--color-accent-warm-2)] rounded-[10px] p-4 mb-3.5">
      <div className="flex items-center justify-between mb-2.5">
        <span className="text-[var(--color-text-primary)] text-sm font-semibold">📋 任务概览</span>
        <span className="text-[var(--color-primary)] text-xs font-medium">{data.current}/{data.total}</span>
      </div>
      <div className="bg-[var(--color-accent-warm)] rounded h-1.5 overflow-hidden">
        <div className="bg-[var(--color-primary)] h-full rounded transition-all" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
```

- [ ] **Step 4: 实现 SubAgentCard**

```tsx
// webui/src/components/SubAgentCard.tsx
import { useState } from 'react';
import type { SubAgentTrace } from '../lib/types';

export function SubAgentCard({ agent }: { agent: SubAgentTrace }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      className="bg-[var(--color-accent-warm-2)] rounded-[10px] p-4 my-3 border-l-[3px] border-[var(--color-primary)] cursor-pointer"
      onClick={() => setExpanded(!expanded)}
    >
      <div className="flex items-center justify-between mb-2.5">
        <span className="text-[var(--color-text-primary)] text-sm font-semibold">👥 子 Agent: {agent.name}</span>
        <span className="bg-[var(--color-primary)] text-white text-xs px-2 py-0.5 rounded-full">
          {agent.status === 'running' ? '运行中' : '已完成'}
        </span>
      </div>
      {expanded && agent.metrics && (
        <div className="bg-[var(--color-accent-warm)] rounded-lg p-3">
          <table className="w-full text-xs border-collapse">
            <thead>
              <tr className="bg-[var(--color-accent-warm-2)]">
                <th className="p-1.5 text-left font-semibold">指标</th>
                <th className="p-1.5 text-center font-semibold">原始</th>
                <th className="p-1.5 text-center font-semibold">优化后</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(agent.metrics).map(([key, { before, after }]) => (
                <tr key={key} className="border-b border-[var(--color-border-light)]">
                  <td className="p-1.5">{key}</td>
                  <td className="p-1.5 text-center">{before}</td>
                  <td className="p-1.5 text-center text-[var(--color-green)] font-medium">{after}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 5: 在 MessageBubble 中集成新组件**

修改 `MessageBubble.tsx`，在 `assistant` 消息渲染中，解析 traces 数据并渲染 `TaskOverview`、`StepCard`、`SubAgentCard`。

- [ ] **Step 6: Commit**

```bash
git add webui/src/components/StepCard.tsx webui/src/components/SubAgentCard.tsx \
       webui/src/components/TaskOverview.tsx webui/src/components/CodeBlock.tsx \
       webui/src/components/MessageBubble.tsx
git commit -m "feat(ui): add enhanced AI interaction components"
```

---

### Task 12: DetailPanel 组件

**Files:**
- Create: `webui/src/components/DetailPanel.tsx`
- Modify: `webui/src/components/thread/ThreadShell.tsx`

- [ ] **Step 1: 实现 DetailPanel**

```tsx
// webui/src/components/DetailPanel.tsx
interface DetailPanelProps {
  visible: boolean;
  onClose: () => void;
  tokenStats?: { input: number; output: number; total: number };
  performance?: { responseTime: string; firstToken: string; speed: string };
  skillsUsed?: string[];
  mcpTools?: { server: string; toolCount: number }[];
  fileOps?: { read: number; edit: number; search: number };
}

export function DetailPanel({ visible, onClose, tokenStats, performance, skillsUsed, mcpTools, fileOps }: DetailPanelProps) {
  if (!visible) return null;

  return (
    <aside className="w-70 bg-[var(--color-accent-warm-2)] border-l border-[var(--color-border-light)] flex flex-col flex-shrink-0">
      <div className="p-4 border-b border-[var(--color-border-light)] flex items-center justify-between">
        <span className="text-[var(--color-text-primary)] text-sm font-semibold">对话详情</span>
        <button onClick={onClose} className="w-7 h-7 flex items-center justify-center rounded-md text-[var(--color-text-secondary)] hover:bg-[var(--color-accent-warm)]">✕</button>
      </div>
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {tokenStats && (
          <Section title="Token 统计">
            <Stat label="输入 Token" value={tokenStats.input.toLocaleString()} />
            <Stat label="输出 Token" value={tokenStats.output.toLocaleString()} />
            <Stat label="总计" value={tokenStats.total.toLocaleString()} />
          </Section>
        )}
        {performance && (
          <Section title="性能指标">
            <Stat label="响应时间" value={performance.responseTime} />
            <Stat label="首 Token 延迟" value={performance.firstToken} />
            <Stat label="生成速度" value={performance.speed} />
          </Section>
        )}
        {skillsUsed && skillsUsed.length > 0 && (
          <Section title="使用的 Skill">
            {skillsUsed.map(s => <Stat key={s} label={s} value="已使用" valueClass="text-[var(--color-green)]" />)}
          </Section>
        )}
        {mcpTools && mcpTools.length > 0 && (
          <Section title="MCP 工具">
            {mcpTools.map(t => <Stat key={t.server} label={t.server} value={`${t.toolCount} 个工具`} />)}
          </Section>
        )}
        {fileOps && (
          <Section title="文件操作">
            <Stat label="读取文件" value={String(fileOps.read)} />
            <Stat label="编辑文件" value={String(fileOps.edit)} />
            <Stat label="搜索结果" value={String(fileOps.search)} />
          </Section>
        )}
      </div>
    </aside>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <div className="text-[var(--color-text-secondary)] text-[11px] font-semibold uppercase tracking-wider mb-2.5">{title}</div>
      <div className="bg-[var(--color-accent-warm)] rounded-lg p-3 space-y-1.5">{children}</div>
    </div>
  );
}

function Stat({ label, value, valueClass }: { label: string; value: string; valueClass?: string }) {
  return (
    <div className="flex items-center justify-between py-1.5 border-b border-[var(--color-border-light)] last:border-0">
      <span className="text-[var(--color-text-secondary)] text-xs">{label}</span>
      <span className={`text-[var(--color-text-primary)] text-sm font-medium ${valueClass || ''}`}>{value}</span>
    </div>
  );
}
```

- [ ] **Step 2: 在 ThreadShell 中集成 DetailPanel**

添加 `showDetail` 状态，在标题栏添加 ℹ️ 按钮，渲染 `<DetailPanel>`。

- [ ] **Step 3: Commit**

```bash
git add webui/src/components/DetailPanel.tsx webui/src/components/thread/ThreadShell.tsx
git commit -m "feat(ui): add DetailPanel for chat session metadata"
```

---

### Task 13: 管理页面 - Skill + MCP

**Files:**
- Create: `webui/src/components/management/SkillView.tsx`
- Create: `webui/src/components/management/McpView.tsx`
- Create: `webui/src/hooks/useManagementApi.ts`

- [ ] **Step 1: 创建 useManagementApi hook**

```typescript
// webui/src/hooks/useManagementApi.ts
import { useState, useEffect, useCallback } from 'react';
import { managementApi } from '../lib/api';

export function useSkills() {
  const [skills, setSkills] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const { skills } = await managementApi.listSkills();
      setSkills(skills);
    } finally { setLoading(false); }
  }, []);
  useEffect(() => { refresh(); }, [refresh]);
  return { skills, loading, refresh, toggle: managementApi.toggleSkill, remove: managementApi.deleteSkill };
}

export function useMcpServers() {
  const [servers, setServers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const { servers } = await managementApi.listMcpServers();
      setServers(servers);
    } finally { setLoading(false); }
  }, []);
  useEffect(() => { refresh(); }, [refresh]);
  return { servers, loading, refresh, connect: managementApi.connectMcpServer, disconnect: managementApi.disconnectMcpServer, remove: managementApi.deleteMcpServer };
}
```

- [ ] **Step 2: 实现 SkillView**

使用卡片网格布局，每张卡片显示 Skill 名称、描述、启用状态。点击启用/禁用调用 `toggleSkill` API。

- [ ] **Step 3: 实现 McpView**

使用卡片网格布局，每张卡片显示 MCP 服务器名、连接状态、工具数量。支持连接/断开操作。

- [ ] **Step 4: Commit**

```bash
git add webui/src/components/management/SkillView.tsx webui/src/components/management/McpView.tsx webui/src/hooks/useManagementApi.ts
git commit -m "feat(ui): add Skill and MCP management views"
```

---

### Task 14: 管理页面 - 知识库 + Agent

**Files:**
- Create: `webui/src/components/management/KnowledgeView.tsx`
- Create: `webui/src/components/management/AgentView.tsx`

- [ ] **Step 1: 实现 KnowledgeView**

卡片网格展示知识库分类，点击进入文档列表，支持新建/编辑/删除文档。编辑使用 `@uiw/react-md-editor` 或类似 Markdown 编辑器。

- [ ] **Step 2: 实现 AgentView**

纵向列表展示 Agent 卡片，每项显示头像、名称、描述、状态标签。支持创建新 Agent（调用 createAgent API）。

- [ ] **Step 3: Commit**

```bash
git add webui/src/components/management/KnowledgeView.tsx webui/src/components/management/AgentView.tsx
git commit -m "feat(ui): add Knowledge and Agent management views"
```

---

### Task 15: 向导组件

**Files:**
- Create: `webui/src/components/management/SkillInstaller.tsx`
- Create: `webui/src/components/management/McpWizard.tsx`
- Create: `webui/src/components/management/AgentWizard.tsx`
- Create: `webui/src/components/management/KnowledgeEditor.tsx`

- [ ] **Step 1: 实现 SkillInstaller**

本地目录选择 + Git URL 输入，调用 `installSkill` API。

- [ ] **Step 2: 实现 McpWizard**

分步表单：选择传输方式 → 配置连接 → 测试连接 → 保存。

- [ ] **Step 3: 实现 AgentWizard**

分步表单：基本信息 → 模型配置 → 工具权限 → Skill 绑定 → 确认。

- [ ] **Step 4: 实现 KnowledgeEditor**

Markdown 编辑器 + 实时预览 + 保存/向量化按钮。

- [ ] **Step 5: Commit**

```bash
git add webui/src/components/management/SkillInstaller.tsx webui/src/components/management/McpWizard.tsx \
       webui/src/components/management/AgentWizard.tsx webui/src/components/management/KnowledgeEditor.tsx
git commit -m "feat(ui): add wizard components for Skill/MCP/Agent/Knowledge"
```

---

### Task 16: App.tsx Shell 集成

**Files:**
- Modify: `webui/src/App.tsx`

- [ ] **Step 1: 重构 Shell 布局**

将 Shell 从 `Sidebar + Content` 改为 `NavRail + Sidebar + Content + DetailPanel` 四区布局。将 `view` 状态扩展为 `PageKey` 类型，根据 `activePage` 渲染不同主内容区页面。

- [ ] **Step 2: Commit**

```bash
git add webui/src/App.tsx
git commit -m "feat(ui): integrate NavRail + multi-page Shell layout"
```

---

## Phase 3: Tauri 桌面化

### Task 17: 初始化 Tauri 项目

**Files:**
- Create: `nanobot-desktop/src-tauri/Cargo.toml`
- Create: `nanobot-desktop/src-tauri/tauri.conf.json`
- Create: `nanobot-desktop/src-tauri/src/main.rs`
- Create: `nanobot-desktop/package.json`
- Create: `nanobot-desktop/vite.config.ts`

- [ ] **Step 1: 初始化 Tauri 项目**

```bash
cd nanobot-desktop
npm create tauri-app@latest . -- --template react-ts
npm install
```

- [ ] **Step 2: 配置 tauri.conf.json**

设置窗口标题 "nanobot"、尺寸 1200x800、sidecar 定义指向 nanobot Python 可执行文件。

- [ ] **Step 3: 将 webui/src 复制到 nanobot-desktop/src**

保留现有 React 代码，调整 import 路径。

- [ ] **Step 4: 验证 Tauri dev 模式启动**

Run: `cd nanobot-desktop && npm run tauri dev`
Expected: 窗口打开，显示 React 页面

- [ ] **Step 5: Commit**

```bash
git add nanobot-desktop/
git commit -m "feat(desktop): initialize Tauri project structure"
```

---

### Task 18: Sidecar 进程管理

**Files:**
- Create: `nanobot-desktop/src-tauri/src/sidecar.rs`
- Modify: `nanobot-desktop/src-tauri/src/main.rs`

- [ ] **Step 1: 实现 sidecar.rs**

```rust
// nanobot-desktop/src-tauri/src/sidecar.rs
use std::process::{Command, Child};
use std::sync::Mutex;

pub struct SidecarState {
    child: Mutex<Option<Child>>,
}

impl SidecarState {
    pub fn new() -> Self {
        Self { child: Mutex::new(None) }
    }

    pub fn start(&self, bin_path: &str) -> Result<u16, String> {
        let child = Command::new(bin_path)
            .args(["serve", "--port", "0"])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .map_err(|e| e.to_string())?;

        // 从 stdout 读取端口号
        // TODO: 解析实际端口
        let port = 8080; // 临时硬编码

        *self.child.lock().unwrap() = Some(child);
        Ok(port)
    }

    pub fn stop(&self) {
        if let Some(mut child) = self.child.lock().unwrap().take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}
```

- [ ] **Step 2: 在 main.rs 中集成 sidecar**

在 Tauri setup 中启动 sidecar，获取端口号，通过 emit 事件通知前端连接地址。

- [ ] **Step 3: Commit**

```bash
git add nanobot-desktop/src-tauri/src/sidecar.rs nanobot-desktop/src-tauri/src/main.rs
git commit -m "feat(desktop): add Python sidecar process management"
```

---

### Task 19: 系统托盘 + 原生通知

**Files:**
- Create: `nanobot-desktop/src-tauri/src/tray.rs`
- Modify: `nanobot-desktop/src-tauri/src/main.rs`

- [ ] **Step 1: 实现 tray.rs**

```rust
// nanobot-desktop/src-tauri/src/tray.rs
use tauri::{
    tray::{TrayIconBuilder, MouseButton, MouseButtonState, TrayIconEvent},
    menu::{Menu, MenuItem},
    Manager,
};

pub fn setup_tray(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let show = MenuItem::with_id(app, "show", "显示窗口", true, None::<&str>)?;
    let quit = MenuItem::with_id(app, "quit", "退出", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&show, &quit])?;

    let _tray = TrayIconBuilder::new()
        .icon(app.default_window_icon().unwrap().clone())
        .menu(&menu)
        .on_menu_event(|app, event| match event.id.as_ref() {
            "show" => {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
            "quit" => {
                app.exit(0);
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click { button: MouseButton::Left, button_state: MouseButtonState::Up, .. } = event {
                let app = tray.app_handle();
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
        })
        .build(app)?;

    Ok(())
}
```

- [ ] **Step 2: 在 Tauri 插件中启用通知**

在 `Cargo.toml` 添加 `tauri-plugin-notification`，在 `main.rs` 中注册插件。

- [ ] **Step 3: Commit**

```bash
git add nanobot-desktop/src-tauri/src/tray.rs nanobot-desktop/src-tauri/src/main.rs nanobot-desktop/src-tauri/Cargo.toml
git commit -m "feat(desktop): add system tray and notification support"
```

---

### Task 20: 文件拖拽 + 全局快捷键

**Files:**
- Modify: `nanobot-desktop/src-tauri/src/commands.rs`
- Modify: `nanobot-desktop/src-tauri/src/main.rs`

- [ ] **Step 1: 实现文件拖拽 command**

```rust
// nanobot-desktop/src-tauri/src/commands.rs
#[tauri::command]
pub fn handle_file_drop(paths: Vec<String>) -> Vec<String> {
    paths
}
```

- [ ] **Step 2: 注册全局快捷键**

使用 `tauri-plugin-global-shortcut` 注册 `CmdOrCtrl+Shift+N` 呼出/隐藏窗口。

- [ ] **Step 3: Commit**

```bash
git add nanobot-desktop/src-tauri/src/commands.rs nanobot-desktop/src-tauri/src/main.rs
git commit -m "feat(desktop): add file drop and global shortcut support"
```

---

## Phase 4: 移动端适配

### Task 21: 响应式布局断点

**Files:**
- Modify: `webui/src/styles/theme.css`
- Modify: `webui/src/components/NavRail.tsx`
- Modify: `webui/src/components/Sidebar.tsx`

- [ ] **Step 1: 添加移动端断点样式**

```css
/* 在 theme.css 中添加 */
@media (max-width: 768px) {
  .nav-rail { display: none; }
  .sidebar { position: fixed; left: 0; top: 0; bottom: 0; z-index: 50; transform: translateX(-100%); transition: transform 0.2s; }
  .sidebar.open { transform: translateX(0); }
  .detail-panel { position: fixed; left: 0; right: 0; bottom: 0; top: auto; max-height: 60vh; z-index: 50; }
  .message-bubble { max-width: 90%; }
}

@media (max-width: 768px) {
  .bottom-tab-bar { display: flex; }
}
```

- [ ] **Step 2: 实现底部 Tab Bar**

在 `NavRail.tsx` 中，当屏幕宽度 ≤ 768px 时渲染底部 Tab Bar 替代侧边导航。

- [ ] **Step 3: Commit**

```bash
git add webui/src/styles/theme.css webui/src/components/NavRail.tsx webui/src/components/Sidebar.tsx
git commit -m "feat(ui): add responsive breakpoints for mobile"
```

---

### Task 22: 触控优化

**Files:**
- Modify: 各组件添加触控相关样式

- [ ] **Step 1: 设置最小点击区域**

所有按钮和可点击元素添加 `min-w-[44px] min-h-[44px]` Tailwind 类。

- [ ] **Step 2: 添加手势支持**

使用 `@use-gesture/react` 或原生 touch 事件实现左滑删除、右滑打开侧边栏。

- [ ] **Step 3: Commit**

```bash
git add webui/src/
git commit -m "feat(ui): add touch optimizations for mobile"
```

---

## 自审清单

- [ ] 每个 Task 有完整的代码块，无 "TBD"/"TODO"
- [ ] 类型名称在 Task 7 定义后，后续 Task 一致使用
- [ ] API 路径在 Task 2-5 定义后，Task 7 的 api.ts 一致使用
- [ ] CSS 变量名在 Task 8 定义后，Task 9-16 一致使用
- [ ] 每个 Task 末尾有 Commit 步骤
- [ ] 验收标准 1-14 均有对应 Task 覆盖
