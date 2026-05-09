# nanobot 桌面应用重构设计文档

> 日期: 2026-05-09
> 状态: 待审批
> 作者: Claude + Huangqh

## 1. 背景与目标

nanobot 当前架构为 Python 后端 + React Web 前端（Vite），通过 WebSocket 通信。存在以下问题：

- **管理功能缺失**：无 Skill、MCP、知识库、Agent 的管理界面，仅有通用设置和 BYOK 配置
- **AI 交互体验差**：工具调用以纯文本折叠列表展示（TraceGroup），无思维链输出、步骤进度、子 Agent 展示
- **布局单一**：单层侧边栏承载所有功能，无法扩展
- **运行形态受限**：纯 Web 应用无法实现系统托盘、本地文件拖拽、原生通知等桌面能力

**目标**：

1. 使用 Tauri 将 Web 前端封装为桌面应用，nanobot Python 后端作为 sidecar 进程管理
2. 重构 UI 为两层导航 + 增强 AI 交互体验
3. 补充后端 HTTP API，暴露 Skill/MCP/Agent 管理接口

## 2. 设计规范

### 2.1 配色系统

基于 Claude 设计规范（暖人文风）：

| Token | 色值 | 用途 |
|-------|------|------|
| Canvas | `#faf9f5` | 主画布背景 |
| Surface | `#fff` | 卡片、输入框背景 |
| Primary | `#cc785c` | 珊瑚色，主强调色（按钮、Logo、进度条、活跃指示器） |
| Primary Hover | `#a9583e` | 主色悬浮态 |
| Dark Surface | `#181715` | 外层导航栏背景 |
| Dark Surface 2 | `#1f1e1b` | 内层侧边栏背景 |
| Dark Surface 3 | `#252320` | 暗色卡片、输入框 |
| Text Primary | `#141413` | 主文本 |
| Text Secondary | `#6c6a64` | 次要文本 |
| Text Muted | `#8e8b82` | 弱化文本 |
| Text Dark | `#faf9f5` | 暗色背景上的文本 |
| Border Light | `#e6dfd8` | 浅色分割线 |
| Border Dark | `#252320` | 暗色分割线 |
| Accent Warm | `#efe9de` | 暖色卡片背景 |
| Accent Warm 2 | `#f5f0e8` | 更浅暖色背景 |
| Green | `#5db872` | 成功、已启用、已连接 |
| Red | `#c64545` | 错误、断开 |
| Code Block | `#181715` | 代码块背景 |

### 2.2 字体

- **正文**：`Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- **代码**：`JetBrains Mono, monospace`

### 2.3 圆角

- 按钮/输入框：`8px`
- 卡片：`12px`
- 消息气泡：`14px`（用户消息右下角 `4px`）
- 药丸标签：`9999px`

### 2.4 间距

- 导航栏宽度：`64px`
- 侧边栏宽度：`260px`
- 详情面板宽度：`280px`
- 页面内边距：`24px 20px`
- 卡片内边距：`16px 20px`

## 3. 整体布局

### 3.1 两层导航结构

```
┌──────────┬──────────┬─────────────────────────────┬──────────────┐
│ Nav Rail │ Sidebar  │ Main Content                │ Detail Panel │
│ (64px)   │ (260px)  │ (flex: 1)                   │ (280px)      │
│          │          │                             │              │
│ N logo   │ 会话列表  │ Header (标题栏)              │ Token 统计   │
│ 💬 聊天   │ /Skill   │                             │ 性能指标     │
│ 🧩 Skill │ /MCP     │ Page Content                │ Skill 使用   │
│ 🔌 MCP   │ /知识库   │ (聊天/Skill/MCP/            │ MCP 工具     │
│ 📚 知识库  │ /Agent   │  知识库/Agent/设置)          │ 文件操作     │
│ 🤖 Agent │ /设置     │                             │              │
│ ⚙️ 设置   │          │ Composer (仅聊天页)          │              │
└──────────┴──────────┴─────────────────────────────┴──────────────┘
```

- **外层窄导航栏（Nav Rail）**：固定 `64px` 宽，深色背景 `#181715`，垂直排列图标按钮，当前页左侧有 `3px` 珊瑚色指示条
- **内层侧边栏（Sidebar）**：`260px` 宽，深色背景 `#1f1e1b`，根据当前导航项动态切换内容
- **主内容区（Main Content）**：弹性宽度，暖奶油背景 `#faf9f5`
- **右侧详情面板（Detail Panel）**：`280px` 宽，默认隐藏，仅聊天页可展开，暖色背景 `#f5f0e8`

### 3.2 响应式断点

- `≤1200px`：隐藏详情面板
- `≤900px`：隐藏侧边栏

## 4. 页面设计

### 4.1 聊天页（Chat）

#### 4.1.1 消息流

- **用户消息**：右对齐，暖色气泡 `#efe9de`，圆角 `14px 14px 4px 14px`，最大宽度 `70%`
- **AI 回复**：左对齐，带头像（`32px` 珊瑚色圆角方块），内容区弹性宽度

#### 4.1.2 AI 交互增强（混合渐进式）

AI 回复中包含以下可交互组件：

**任务概览卡片**：
- 暖色背景 `#f5f0e8`，圆角 `10px`
- 标题（📋 任务概览）+ 进度指示（如 2/5）
- 进度条：`#e8e0d2` 背景 + `#cc785c` 填充

**步骤卡片**：
- 已完成：暖色背景 `#efe9de`，左侧绿色 ✓ 图标
- 进行中：白底 + 边框 `#e6dfd8`，左侧珊瑚色 ⟳ 旋转图标
- 点击展开/收起详情（代码块、搜索结果等）
- 右侧 ▶ 箭头指示可展开状态

**代码块**：
- 深色背景 `#181715`，JetBrains Mono 字体
- 顶部：文件名 + 复制按钮
- 支持行号、绿色新增（`#5db872`）、红色删除（`#c64545`）

**子 Agent 卡片**：
- 暖色背景 `#f5f0e8`，左侧 `3px` 珊瑚色边框
- 标题（👥 子 Agent 名称）+ 状态标签（运行中/已完成）
- 点击展开：内嵌表格展示指标对比

#### 4.1.3 输入框（Composer）

- 白底输入框 + 珊瑚色聚焦边框 + `box-shadow: 0 0 0 3px rgba(204,120,92,0.1)`
- 左侧：附加文件按钮 📎
- 右侧：珊瑚色发送按钮 ▶

#### 4.1.4 右侧详情面板

仅在聊天页可用，包含 5 个区块：
1. **Token 统计**：输入/输出/总计
2. **性能指标**：响应时间、首 Token 延迟、生成速度
3. **使用的 Skill**：列表 + 使用状态
4. **MCP 工具**：服务器名 + 工具数量
5. **文件操作**：读取/编辑/搜索统计

### 4.2 Skill 管理页

- **侧边栏**：Skill 列表（图标 + 名称 + 启用/禁用状态标签 + 描述）
- **主内容区**：卡片网格布局（`grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))`）
  - 每张卡片：图标 + 状态标签 + 标题 + 描述 + 元信息（版本、最后使用时间）
  - 悬浮态：珊瑚色边框 + 阴影

### 4.3 MCP 管理页

- **侧边栏**：MCP 服务器列表（图标 + 名称 + 连接状态标签 + 描述）
- **主内容区**：卡片网格布局
  - 状态标签：已连接（绿色）/ 断开（红色）
  - 元信息：工具数量、传输协议（stdio/SSE）

### 4.4 知识库页

- **侧边栏**：知识库列表（图标 + 名称 + 文档数量）
- **主内容区**：卡片网格布局（`minmax(200px, 1fr)`），居中对齐
  - 大图标（`48px`）+ 标题 + 文档计数
  - 悬浮态：珊瑚色边框 + 上浮 `2px` + 阴影

### 4.5 Agent 管理页

- **侧边栏**：Agent 列表（图标 + 名称 + 状态标签 + 描述）
- **主内容区**：纵向列表布局
  - 每项：头像（`48px` 珊瑚色方块）+ 名称 + 描述 + 状态标签（运行中/已完成/失败，与后端 `AgentInfo.status` 一致）

### 4.6 设置页

- **侧边栏**：设置分类列表（通用设置、AI 模型、API Key、主题外观）
- **主内容区**：分组表单布局
  - 每组：标题 + 白底圆角卡片
  - 每项：左侧标签 + 描述，右侧控件
  - 控件类型：开关（Toggle）、下拉选择（Select）、文本输入（Input）、滑块（Range）、数字输入（Number）
  - 开关样式：`44px × 24px`，未激活 `#e6dfd8`，激活 `#cc785c`

## 5. 交互设计

### 5.1 页面切换

- 点击导航栏图标 → 切换主内容区页面 + 侧边栏内容 + 标题栏
- 活跃导航项：深色背景 + 浅色图标 + 左侧珊瑚色指示条

### 5.2 侧边栏联动

- 每个导航项对应独立的侧边栏 section
- 切换时隐藏其他 section，显示当前 section

### 5.3 步骤卡片交互

- 点击步骤卡片 → 展开/收起详情内容
- 箭头图标旋转 90° 指示展开状态
- 详情内容包含代码块、搜索结果等

### 5.4 子 Agent 交互

- 点击子 Agent 卡片 → 展开/收起内嵌内容
- 内嵌内容：指标对比表格

### 5.5 代码块交互

- 复制按钮：点击后显示"已复制"，2 秒后恢复
- 阻止事件冒泡，不影响步骤卡片展开/收起

### 5.6 搜索过滤

- 侧边栏搜索框：实时过滤列表项
- 匹配逻辑：大小写不敏感，包含匹配

### 5.7 详情面板

- 点击标题栏 ℹ️ 按钮 → 展开/收起详情面板
- 按钮激活态变为珊瑚色背景

## 6. 与现有代码的关系

### 6.1 需要修改的文件

| 文件 | 改动 |
|------|------|
| `App.tsx` | 扩展 Shell 支持更多视图类型（chat/skills/mcp/knowledge/agents/settings） |
| `Sidebar.tsx` | 重构为两层导航结构（NavRail + Sidebar） |
| `MessageBubble.tsx` | TraceGroup 重构为步骤卡片 + 子 Agent 卡片 |
| `ThreadShell.tsx` | 集成任务概览卡片、右侧详情面板 |
| `SettingsView.tsx` | 扩展设置项（AI 模型、API Key、主题、Skill、MCP） |
| `types.ts` | 扩展类型支持 Skill/MCP/Agent 数据结构 |

### 6.2 需要新增的文件

| 文件 | 用途 |
|------|------|
| `components/NavRail.tsx` | 外层窄导航栏组件 |
| `components/DetailPanel.tsx` | 右侧详情面板组件 |
| `components/StepCard.tsx` | 步骤卡片组件 |
| `components/SubAgentCard.tsx` | 子 Agent 卡片组件 |
| `components/TaskOverview.tsx` | 任务概览卡片组件 |
| `components/CodeBlock.tsx` | 代码块组件（含复制功能） |
| `components/management/SkillView.tsx` | Skill 管理页 |
| `components/management/McpView.tsx` | MCP 管理页 |
| `components/management/KnowledgeView.tsx` | 知识库管理页 |
| `components/management/AgentView.tsx` | Agent 管理页 |
| `components/management/KnowledgeEditor.tsx` | 知识库文档编辑器 |
| `components/management/SkillInstaller.tsx` | Skill 安装向导 |
| `components/management/McpWizard.tsx` | MCP 添加向导 |
| `components/management/AgentWizard.tsx` | Agent 创建向导 |

### 6.3 保持不变的部分

- WebSocket 通信协议（NanobotClient）
- 消息流式处理（useNanobotStream）
- i18n 国际化框架
- Radix UI 基础组件

## 7. 数据结构扩展

### 7.1 Skill 数据

```typescript
interface SkillInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  version: string;
  enabled: boolean;
  lastUsedAt?: string;
}
```

### 7.2 MCP 数据

```typescript
interface McpServerInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  connected: boolean;
  toolCount: number;
  transport: 'stdio' | 'sse';
}
```

### 7.3 Agent 数据

```typescript
interface AgentInfo {
  id: string;
  name: string;
  icon: string;
  description: string;
  status: 'running' | 'completed' | 'failed';  // 与后端 /api/agents 响应一致
  startedAt?: string;
}
```

### 7.4 扩展 TraceGroup

```typescript
interface TraceStep {
  id: string;
  title: string;
  status: 'completed' | 'in-progress' | 'pending';
  detail?: string;
  codeBlocks?: CodeBlock[];
}

interface SubAgentTrace {
  id: string;
  name: string;
  status: 'running' | 'completed';
  metrics?: Record<string, { before: string; after: string }>;
}

interface TaskOverviewData {
  title: string;
  current: number;
  total: number;
}
```

## 8. Tauri 桌面化

### 8.1 架构

```
┌─────────────────────────────────────────────┐
│ Tauri Shell (Rust)                          │
│  ┌────────────────────────────────────────┐ │
│  │ WebView (系统浏览器内核)                │ │
│  │  React + TypeScript + Tailwind CSS     │ │
│  │  (现有 webui/ 代码)                    │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │ Rust 后端 (tauri::command)             │ │
│  │  - Sidecar 进程管理 (nanobot Python)   │ │
│  │  - 系统托盘 / 原生菜单                 │ │
│  │  - 文件拖拽 / 原生对话框               │ │
│  │  - 自动更新                            │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         │ localhost WebSocket
         ▼
┌─────────────────────────────────────────────┐
│ nanobot Python 后端 (sidecar)               │
│  - Agent 循环引擎                           │
│  - WebSocket 服务                           │
│  - HTTP API (aiohttp)                       │
│  - MCP / Skill / 子代理管理                 │
└─────────────────────────────────────────────┘
```

### 8.2 Tauri 项目结构

```
nanobot-desktop/
├── src-tauri/
│   ├── Cargo.toml
│   ├── tauri.conf.json       # 窗口配置、sidecar 定义
│   ├── src/
│   │   ├── main.rs           # 入口
│   │   ├── sidecar.rs        # nanobot 进程启停、健康检查
│   │   ├── tray.rs           # 系统托盘
│   │   └── commands.rs       # Tauri command（原生能力桥接）
│   └── icons/
├── src/                      # 复用现有 webui/src/
│   ├── App.tsx
│   ├── components/
│   └── ...
├── package.json
├── vite.config.ts
└── tailwind.config.ts
```

### 8.3 Sidecar 管理

- **启动**：Tauri 应用启动时自动拉起 `nanobot serve --port 0`（随机端口），通过 stdout 获取实际端口
- **健康检查**：定期 `GET /health`，失败时自动重启
- **关闭**：应用退出时优雅终止 Python 进程（SIGTERM → 等待 → SIGKILL）
- **日志**：Python 进程 stderr 输出重定向到 Tauri 日志系统

### 8.4 桌面特有能力

| 能力 | 实现方式 |
|------|----------|
| 系统托盘 | Tauri tray API，显示连接状态，快速打开/退出 |
| 原生通知 | Tauri notification API，AI 回复完成时提醒 |
| 文件拖拽 | Tauri file drop 事件，拖文件到窗口直接附加到消息 |
| 全局快捷键 | Tauri global shortcut，呼出/隐藏窗口 |
| 原生菜单 | 应用菜单栏，集成设置、关于、检查更新 |
| 自动更新 | Tauri updater，检查新版本并下载安装 |

### 8.5 前端改动最小化

- 现有 `webui/src/` 代码**直接复用**，仅替换 WebSocket 连接地址为 `ws://localhost:{port}`
- 通过 Tauri 的 `invoke()` 桥接 Rust 原生能力（托盘、通知等）
- `vite.config.ts` 增加 Tauri 插件配置
- `package.json` 增加 `@tauri-apps/cli` 和 `@tauri-apps/api` 依赖

## 9. 后端 API 扩展

### 9.1 现状

nanobot 后端（`nanobot/api/server.py`）当前仅暴露 3 个 HTTP 端点：

| 端点 | 用途 |
|------|------|
| `POST /v1/chat/completions` | 聊天补全 |
| `GET /v1/models` | 模型列表 |
| `GET /health` | 健康检查 |

内部已有 Skill/MCP/Agent 管理能力，但未暴露为 API。

### 9.2 需新增的 HTTP API（完整清单）

**Skill 管理**：

| 端点 | 方法 | 用途 | 数据来源 |
|------|------|------|----------|
| `/api/skills` | GET | 返回 Skill 列表 | `SkillsLoader.list_skills()` |
| `/api/skills` | POST | 安装 Skill（路径或 Git URL） | 复制到 workspace/skills/ |
| `/api/skills/{name}` | GET | Skill 详情（SKILL.md 内容） | `SkillsLoader.get_skill_metadata()` |
| `/api/skills/{name}` | DELETE | 卸载 Skill | 删除目录 |
| `/api/skills/{name}/toggle` | POST | 启用/禁用 Skill | 修改 `AgentDefaults.disabled_skills` |

**MCP 管理**：

| 端点 | 方法 | 用途 | 数据来源 |
|------|------|------|----------|
| `/api/mcp/servers` | GET | MCP 服务器列表及连接状态 | `MCPClient` + `ToolRegistry` |
| `/api/mcp/servers` | POST | 添加 MCP 服务器 | 写入配置 |
| `/api/mcp/servers/{name}` | PUT | 更新 MCP 配置 | 写入配置 |
| `/api/mcp/servers/{name}` | DELETE | 删除 MCP 服务器 | 删除配置 |
| `/api/mcp/servers/{name}/connect` | POST | 连接/重连 | `MCPClient.connect()` |
| `/api/mcp/servers/{name}/disconnect` | POST | 断开连接 | `MCPClient.disconnect()` |
| `/api/mcp/servers/{name}/test` | POST | 测试连接，返回发现的工具 | 尝试连接并列举工具 |
| `/api/mcp/tools` | GET | MCP 工具列表 | `ToolRegistry` 遍历 |

**Agent 管理**：

| 端点 | 方法 | 用途 | 数据来源 |
|------|------|------|----------|
| `/api/agents` | GET | 运行中子代理列表及状态 | `SubagentManager._task_statuses` |
| `/api/agents` | POST | 创建 Agent | 写入配置 |
| `/api/agents/{id}` | GET | Agent 配置详情 | 读取配置 |
| `/api/agents/{id}` | PUT | 更新 Agent 配置 | 写入配置 |
| `/api/agents/{id}` | DELETE | 删除 Agent | 删除配置 |
| `/api/agents/{id}/start` | POST | 启动 Agent | `SubagentManager` |
| `/api/agents/{id}/stop` | POST | 停止 Agent | `SubagentManager` |

**知识库管理**：

| 端点 | 方法 | 用途 | 数据来源 |
|------|------|------|----------|
| `/api/knowledge` | GET | 知识库列表 | 文件系统扫描 |
| `/api/knowledge/{id}/docs` | GET | 文档列表 | 文件系统扫描 |
| `/api/knowledge/{id}/docs` | POST | 新建文档 | 写入文件 |
| `/api/knowledge/{id}/docs/{docId}` | GET/PUT/DELETE | 文档 CRUD | 文件读写 |
| `/api/knowledge/{id}/docs/{docId}/vectorize` | POST | 触发向量化 | 向量引擎 |

**设置**：

| 端点 | 方法 | 用途 | 数据来源 |
|------|------|------|----------|
| `/api/settings` | GET/PUT | 获取/更新设置 | `ConfigManager` |

### 9.3 API 响应格式

```jsonc
// GET /api/skills
{
  "skills": [
    {
      "name": "test-driven-dev",
      "description": "TDD 开发流程自动化",
      "source": "builtin",       // builtin | workspace
      "available": true,
      "enabled": true
    }
  ]
}

// GET /api/mcp/servers
{
  "servers": [
    {
      "name": "bocha-mcp",
      "connected": true,
      "transport": "stdio",      // stdio | sse
      "tool_count": 2,
      "tools": ["bocha_web_search", "read_website"]
    }
  ]
}

// GET /api/agents
{
  "agents": [
    {
      "id": "task-abc123",
      "name": "性能分析专家",
      "status": "running",       // running | completed | failed
      "started_at": "2026-05-09T10:30:00Z"
    }
  ]
}
```

### 9.4 WebSocket 事件扩展

现有 WebSocket 事件需要扩展，支持 Skill/MCP/Agent 状态变更推送：

| 事件 | 方向 | 用途 |
|------|------|------|
| `skill_used` | S→C | 通知前端当前轮次使用了哪些 Skill |
| `mcp_tool_call` | S→C | 通知前端 MCP 工具调用详情 |
| `agent_started` | S→C | 子代理启动 |
| `agent_completed` | S→C | 子代理完成，附带结果摘要 |
| `agent_progress` | S→C | 子代理执行进度更新 |

这些事件复用现有 `InboundEvent` 的 `kind` 字段区分类型。

## 10. 扩展功能

### 10.1 深色模式完整实现

采用 CSS 变量 + Tailwind dark 前缀实现主题切换：

```css
/* 浅色模式（默认） */
:root {
  --canvas: #faf9f5;
  --surface: #fff;
  --primary: #cc785c;
  --text-primary: #141413;
  --text-secondary: #6c6a64;
  --border: #e6dfd8;
  --accent-warm: #efe9de;
  /* ... */
}

/* 深色模式 */
[data-theme="dark"] {
  --canvas: #1a1a1a;
  --surface: #242424;
  --primary: #cc785c;
  --text-primary: #f0f0f0;
  --text-secondary: #a0a0a0;
  --border: #333;
  --accent-warm: #2a2a2a;
  /* ... */
}
```

- 主题切换通过设置页开关 + `data-theme` 属性控制
- Tauri 层通过 `tauri-plugin-store` 持久化用户主题偏好
- 所有组件使用 CSS 变量而非硬编码色值，自动响应主题切换

### 10.2 知识库文档编辑

**侧边栏**：知识库列表（图标 + 名称 + 文档数量），支持搜索过滤

**主内容区**：
- 卡片网格视图：浏览知识库分类
- 点击进入文档列表：支持新建、编辑、删除文档
- 文档编辑器：Markdown 编辑器（基于 `@uiw/react-md-editor` 或类似库），支持实时预览
- 文档导入：支持从本地文件（.md, .txt, .pdf）拖拽导入
- 向量化状态：显示文档是否已向量化，支持手动触发向量化

**后端 API**：见 §9.2 知识库管理部分。

### 10.3 Agent 创建/配置界面

**侧边栏**：Agent 列表 + "新建 Agent" 按钮

**主内容区**：
- Agent 卡片列表（现有功能）
- 点击 Agent 卡片 → 进入配置页面：
  - 基本信息：名称、图标、描述
  - 模型配置：模型选择、温度、最大 Token、系统提示词
  - 工具权限：勾选可用工具（内置工具 + MCP 工具）
  - Skill 绑定：选择该 Agent 可使用的 Skill
  - 子代理策略：是否允许创建子代理、最大并发数
- Agent 创建向导：分步表单（基本信息 → 模型配置 → 工具权限 → 确认）

**后端 API**：见 §9.2 Agent 管理部分。

### 10.4 MCP 服务器添加/配置向导

**侧边栏**：MCP 服务器列表 + "添加 MCP" 按钮

**主内容区**：
- MCP 服务器卡片列表（现有功能）
- 添加向导（分步）：
  1. **选择传输方式**：stdio（本地进程）/ SSE（远程服务）
  2. **配置连接**：
     - stdio：命令、参数、环境变量
     - SSE：URL、认证头
  3. **测试连接**：点击"测试"按钮验证连接，显示发现的工具列表
  4. **保存**：写入配置文件
- 配置编辑：点击已有 MCP 卡片 → 编辑连接配置、查看工具列表、重连/断开
- 工具详情：展开查看每个工具的名称、描述、参数 schema

**后端 API**：见 §9.2 MCP 管理部分。

### 10.5 Skill 安装/卸载流程

**侧边栏**：Skill 列表 + "安装 Skill" 按钮

**主内容区**：
- Skill 卡片网格（现有功能）
- 安装方式：
  - **本地目录**：选择本地 Skill 目录（SKILL.md 所在目录），复制到 workspace/skills/
  - **Git 仓库**：输入 Git URL，克隆到 workspace/skills/
  - **内置市场**：浏览内置 Skill 列表，一键安装（如果未来支持）
- Skill 详情页：查看 SKILL.md 内容、启用/禁用、查看使用统计
- 卸载：确认对话框 → 删除 Skill 目录

**后端 API**：见 §9.2 Skill 管理部分。

### 10.6 移动端适配

通过响应式布局 + Tauri 移动端支持实现：

**布局适配**：
- `≤768px`（手机）：隐藏 Nav Rail，底部 Tab Bar 替代导航
- `≤768px`：侧边栏改为抽屉式（从左侧滑出）
- `≤768px`：详情面板改为底部 Sheet（从底部滑出）
- 消息气泡最大宽度调整为 `90%`

**触控优化**：
- 按钮最小点击区域 `44px × 44px`
- 长按触发上下文菜单
- 滑动手势：左滑删除会话、右滑打开侧边栏

**Tauri 移动端**：
- Android：通过 `tauri android init` 初始化
- iOS：通过 `tauri ios init` 初始化
- 共享同一套 React 代码，平台差异通过 CSS 媒体查询处理

## 11. 实施顺序

```
Phase 1: 后端 API 补充（无需前端改动，可独立验证）
  ├── 新增 /api/skills 端点（列表 + 详情 + 安装 + 卸载 + 启用/禁用）
  ├── 新增 /api/mcp/servers 端点（列表 + 添加 + 删除 + 连接/断开 + 测试）
  ├── 新增 /api/agents 端点（列表 + 创建 + 配置 + 启动/停止）
  ├── 新增 /api/knowledge 端点（知识库 + 文档 CRUD + 向量化）
  ├── 扩展 WebSocket 事件（skill_used, mcp_tool_call, agent_*）
  └── 单元测试

Phase 2: 前端 UI 重构（纯 Web，保持现有运行方式）
  ├── 两层导航结构（NavRail + Sidebar）
  ├── 消息流增强（StepCard, SubAgentCard, TaskOverview, CodeBlock）
  ├── 管理页面（Skill, MCP, 知识库, Agent）
  ├── Skill 安装/卸载流程
  ├── MCP 添加/配置向导
  ├── Agent 创建/配置界面
  ├── 知识库文档编辑器
  ├── 设置页扩展
  ├── 右侧详情面板
  ├── 深色模式完整实现
  └── 组件测试

Phase 3: Tauri 桌面化
  ├── 初始化 Tauri 项目
  ├── Sidecar 进程管理
  ├── 系统托盘 + 原生通知
  ├── 文件拖拽 + 全局快捷键
  └── 打包发布（Windows / macOS / Linux）

Phase 4: 移动端适配
  ├── 响应式布局断点（底部 Tab Bar + 抽屉侧边栏 + 底部 Sheet）
  ├── 触控优化（最小点击区域、手势操作）
  ├── Tauri Android / iOS 初始化
  └── 移动端测试
```

## 12. 验收标准

1. Tauri 桌面应用可正常启动，自动拉起 nanobot Python 后端
2. 外层导航栏可切换 6 个页面，侧边栏联动
3. 聊天页 AI 回复展示任务概览卡片 + 步骤卡片 + 子 Agent 卡片
4. 步骤卡片可展开/收起，内含代码块
5. 右侧详情面板可展开/收起，展示 Token 统计等信息
6. Skill 管理：卡片列表 + 安装（本地目录/Git）+ 卸载 + 启用/禁用
7. MCP 管理：卡片列表 + 添加向导（stdio/SSE）+ 测试连接 + 编辑/删除
8. Agent 管理：卡片列表 + 创建向导 + 配置编辑（模型/工具/Skill）+ 启动/停止
9. 知识库：分类浏览 + 文档列表 + Markdown 编辑 + 本地文件导入 + 向量化状态
10. 设置页包含通用设置、AI 模型、API Key 配置、主题切换
11. 深色模式：浅色/深色主题切换，所有组件自动响应
12. 系统托盘显示连接状态，支持快速打开/退出
13. AI 回复完成时弹出原生通知
14. 移动端：底部导航 + 抽屉侧边栏 + 触控手势适配
