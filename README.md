# 🗂️ 智能项目工作空间管理器 (Workspace Manager)

一个智能的Claude Skill，用于自动创建和管理项目文件夹，让AI工作过程中的各类文件井然有序。

## ✨ 特性

- 🎯 **智能前置检测**：首次创建文件前自动搭建文件夹结构
- 📁 **自动分类**：根据文件类型自动归类到对应目录
- 🔍 **智能推断**：从任务描述自动推断项目名称
- 🗄️ **状态管理**：追踪活跃工作空间，支持多项目切换
- 📦 **归档功能**：完成任务后可打包归档，保持整洁
- ⚙️ **可配置**：支持自定义文件分类规则

## 📦 文件夹结构

```
.claude-work/
└── {任务描述}-{YYYYMMDD}/
    ├── src/           # 源代码 (.py, .js, .ts, .jsx, .tsx, .java, .go, .rs)
    ├── config/        # 配置文件 (.json, .yaml, .yml, .toml, .ini, .env)
    ├── docs/          # 文档 (.md, .txt, .doc, .docx)
    ├── scripts/       # 脚本 (.sh, .bat, .ps1)
    ├── data/          # 数据文件 (.csv, .xlsx, .parquet, .sql)
    ├── images/        # 图片 (.png, .jpg, .svg, .gif)
    ├── temp/          # 临时文件 (.tmp, .log, .cache)
    ├── artifacts/     # 生成产物 (.pdf, .html)
    └── tests/         # 测试文件 (*_test.*, *_spec.*)
```

## 🚀 快速开始

### 1. 安装脚本

将 `workspace_manager.py` 复制到你的项目根目录：

```bash
cp workspace_manager.py /path/to/your/project/
```

### 2. 使用命令行

```bash
# 创建新工作空间
python workspace_manager.py create "我的项目" "数据分析"

# 列出所有工作空间
python workspace_manager.py list

# 显示当前工作空间信息
python workspace_manager.py info

# 切换工作空间
python workspace_manager.py switch "我的项目-20260526"

# 归档工作空间
python workspace_manager.py archive

# 清理临时文件
python workspace_manager.py clean
```

### 3. 在Claude中使用

告诉Claude：
- "创建项目文件夹，名称：用户认证系统"
- "帮我写一个处理CSV的脚本"（自动创建工作空间）

Claude会自动调用脚本创建工作空间，后续文件操作会自动存入对应目录。

## 📖 使用场景

### 场景1：直接开始任务（推荐）

```
用户：帮我写一个Python脚本来处理CSV文件

系统行为：
1. 检测到需要创建.py文件
2. 自动创建工作空间 "CSV处理脚本-20260526"
3. 创建脚本文件到 src/ 目录
```

### 场景2：在现有工作空间中继续工作

```
用户：在刚才的项目中添加一个配置文件

系统行为：
1. 检测到已有活跃工作空间
2. 直接创建配置文件到 config/ 目录
3. 不再询问
```

### 场景3：手动创建新工作空间

```
用户：创建新项目文件夹，名称：数据分析平台

系统行为：
1. 创建完整文件夹结构
2. 设置为当前活跃工作空间
3. 后续文件操作自动存入此工作空间
```

## 🎯 智能推断规则

当用户没有明确提供项目名称时，自动从任务上下文推断：

| 任务描述 | 推断名称 |
|---------|---------|
| "写一个处理CSV的脚本" | CSV处理脚本 |
| "创建React登录组件" | React登录组件 |
| "分析销售数据" | 销售数据分析 |
| "修复认证bug" | 认证bug修复 |
| "搭建API服务器" | API服务器 |

## ⚙️ 配置文件

工作空间配置存放在 `.claude-work/config.json`：

```json
{
  "autoCreate": true,
  "autoInferName": true,
  "namingPattern": "{description}-{date}",
  "defaultCategories": {
    "src": [".py", ".js", ".ts", ".jsx", ".tsx", ".java", ".go", ".rs", ".c", ".cpp"],
    "config": [".json", ".yaml", ".yml", ".toml", ".ini", ".env", ".cfg"],
    "docs": [".md", ".txt", ".doc", ".docx", ".pdf"],
    "scripts": [".sh", ".bat", ".ps1"],
    "data": [".csv", ".xlsx", ".parquet", ".sql", ".db"],
    "images": [".png", ".jpg", ".svg", ".gif", ".webp"],
    "temp": [".tmp", ".log", ".cache", ".bak"],
    "artifacts": [".html", ".htm"]
  },
  "testPatterns": ["*_test.*", "*_spec.*", "test_*.*", "spec_*.*"],
  "archiveOnComplete": false,
  "archiveFormat": "zip"
}
```

## 📋 命令参考

| 命令 | 说明 |
|------|------|
| `create [名称] [描述]` | 创建新工作空间 |
| `list` | 列出所有工作空间 |
| `info [名称]` | 显示工作空间信息 |
| `switch <名称>` | 切换工作空间 |
| `archive [名称]` | 归档工作空间 |
| `clean [名称]` | 清理临时文件 |
| `resolve <文件名>` | 解析文件路径 |

## 💡 最佳实践

1. **项目命名**：使用描述性但简洁的名称，便于识别
2. **及时归档**：完成任务后使用 `archive` 命令保持整洁
3. **切换项目**：多任务并行时使用 `switch` 在不同工作空间间切换
4. **配置定制**：根据项目需求自定义文件分类规则
5. **版本控制**：建议将 `.claude-work/` 添加到 `.gitignore`

## 🔧 工作流程

```
用户请求创建文件
        ↓
是否有活跃工作空间？
    ↓ 否           ↓ 是
询问项目名称/描述    直接存入现有工作空间
        ↓
创建文件夹结构
        ↓
设置为活跃工作空间
        ↓
创建文件到对应目录
        ↓
提示创建成功
```

## 📝 示例工作流

```bash
# 1. 开始新任务
用户：帮我写一个用户认证系统

# 2. 系统创建项目
python workspace_manager.py create "用户认证系统" "开发用户认证模块"
# ✅ 工作空间已创建: .claude-work/用户认证系统-20260526/

# 3. 创建文件
用户：创建主认证模块
# 系统创建 auth.py → src/auth.py

# 4. 继续工作
用户：添加JWT配置
# 系统创建 jwt_config.json → config/jwt_config.json

# 5. 任务完成
python workspace_manager.py archive
# ✅ 工作空间已归档: .claude-work/archives/用户认证系统-20260526.zip
```

## 📄 License

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📧 联系方式

如有问题或建议，请提交Issue。
