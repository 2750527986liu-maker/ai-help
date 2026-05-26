#!/usr/bin/env python3
"""
项目工作空间管理器
自动创建和管理项目文件夹，用于存放AI工作过程中产生的各类文件
"""

import os
import sys
import json
import shutil
from datetime import datetime
from pathlib import Path

# 默认配置
DEFAULT_CONFIG = {
    "autoCreate": True,
    "autoInferName": True,
    "namingPattern": "{description}-{date}",
    "defaultCategories": {
        "src": [".py", ".js", ".ts", ".jsx", ".tsx", ".java", ".go", ".rs", ".c", ".cpp"],
        "config": [".json", ".yaml", ".yml", ".toml", ".ini", ".env", ".cfg"],
        "docs": [".md", ".txt", ".doc", ".docx", ".pdf"],
        "scripts": [".sh", ".bat", ".ps1"],
        "data": [".csv", ".xlsx", ".parquet", ".sql", ".db"],
        "images": [".png", ".jpg", ".svg", ".gif", ".webp"],
        "temp": [".tmp", ".log", ".cache", ".bak"],
        "artifacts": [".html", ".htm"],
        "tests": ["_test.", "_spec.", "test_", "spec_"]
    },
    "archiveOnComplete": False,
    "archiveFormat": "zip"
}

class WorkspaceManager:
    def __init__(self, base_dir="."):
        self.base_dir = Path(base_dir)
        self.work_dir = self.base_dir / ".claude-work"
        self.config_file = self.work_dir / "config.json"
        self.state_file = self.work_dir / "state.json"
        self.config = self._load_config()
        self.state = self._load_state()

    def _load_config(self):
        """加载配置文件"""
        if self.config_file.exists():
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return {**DEFAULT_CONFIG, **json.load(f)}
        return DEFAULT_CONFIG.copy()

    def _load_state(self):
        """加载状态文件"""
        if self.state_file.exists():
            with open(self.state_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {"active_workspace": None, "workspaces": []}

    def _save_state(self):
        """保存状态文件"""
        self.work_dir.mkdir(parents=True, exist_ok=True)
        with open(self.state_file, 'w', encoding='utf-8') as f:
            json.dump(self.state, f, indent=2, ensure_ascii=False)

    def _save_config(self):
        """保存配置文件"""
        self.work_dir.mkdir(parents=True, exist_ok=True)
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)

    def _infer_project_name(self, description):
        """从任务描述推断项目名称"""
        # 移除常见动词和虚词
        words = description.split()
        stop_words = {'帮我', '写一个', '创建', '做一个', '实现', '开发', '的', '来', '用于', '以便'}
        keywords = [w for w in words if w not in stop_words and len(w) > 1]

        if keywords:
            name = ''.join(keywords[:3])
        else:
            name = "项目"

        # 添加日期后缀
        date_str = datetime.now().strftime("%Y%m%d")
        return f"{name}-{date_str}"

    def _categorize_file(self, filename):
        """根据文件扩展名分类"""
        ext = Path(filename).suffix.lower()
        name = Path(filename).stem.lower()

        # 检查测试文件模式
        test_patterns = self.config.get("testPatterns", [])
        for pattern in test_patterns:
            if pattern.replace('*', '') in name:
                return "tests"

        # 根据扩展名分类
        for category, extensions in self.config["defaultCategories"].items():
            if ext in extensions:
                return category

        return "src"  # 默认放在src

    def create_workspace(self, name=None, description=None):
        """创建新的工作空间"""
        if name is None:
            if description:
                name = self._infer_project_name(description)
            else:
                name = f"项目-{datetime.now().strftime('%Y%m%d')}"

        workspace_path = self.work_dir / name

        # 创建目录结构
        directories = [
            "src", "config", "docs", "scripts",
            "data", "images", "temp", "artifacts", "tests"
        ]

        for dir_name in directories:
            (workspace_path / dir_name).mkdir(parents=True, exist_ok=True)

        # 更新状态
        self.state["active_workspace"] = name
        if name not in self.state["workspaces"]:
            self.state["workspaces"].append(name)
        self._save_state()

        return workspace_path

    def get_active_workspace(self):
        """获取当前活跃的工作空间路径"""
        if self.state["active_workspace"]:
            return self.work_dir / self.state["active_workspace"]
        return None

    def switch_workspace(self, name):
        """切换到指定的工作空间"""
        workspace_path = self.work_dir / name
        if workspace_path.exists():
            self.state["active_workspace"] = name
            self._save_state()
            return workspace_path
        else:
            print(f"错误：工作空间 '{name}' 不存在")
            return None

    def list_workspaces(self):
        """列出所有工作空间"""
        workspaces = []
        if self.work_dir.exists():
            for item in self.work_dir.iterdir():
                if item.is_dir() and item.name not in ['archives', '__pycache__']:
                    workspaces.append(item.name)
        return sorted(workspaces)

    def get_workspace_info(self, name=None):
        """获取工作空间信息"""
        if name is None:
            name = self.state["active_workspace"]

        if name is None:
            return None

        workspace_path = self.work_dir / name
        if not workspace_path.exists():
            return None

        info = {
            "name": name,
            "path": str(workspace_path),
            "directories": {},
            "total_files": 0
        }

        for dir_name in ["src", "config", "docs", "scripts", "data", "images", "temp", "artifacts", "tests"]:
            dir_path = workspace_path / dir_name
            if dir_path.exists():
                files = list(dir_path.iterdir())
                info["directories"][dir_name] = len(files)
                info["total_files"] += len(files)

        return info

    def archive_workspace(self, name=None):
        """归档工作空间"""
        if name is None:
            name = self.state["active_workspace"]

        if name is None:
            print("错误：没有活跃的工作空间")
            return None

        workspace_path = self.work_dir / name
        if not workspace_path.exists():
            print(f"错误：工作空间 '{name}' 不存在")
            return None

        # 创建归档目录
        archive_dir = self.work_dir / "archives"
        archive_dir.mkdir(exist_ok=True)

        # 创建ZIP归档
        archive_path = archive_dir / f"{name}.zip"
        shutil.make_archive(str(archive_path.with_suffix('')), 'zip', str(workspace_path))

        # 删除原工作空间
        shutil.rmtree(workspace_path)

        # 更新状态
        if self.state["active_workspace"] == name:
            self.state["active_workspace"] = None
        if name in self.state["workspaces"]:
            self.state["workspaces"].remove(name)
        self._save_state()

        return archive_path

    def clean_temp(self, name=None):
        """清理临时文件"""
        if name is None:
            name = self.state["active_workspace"]

        if name is None:
            print("错误：没有活跃的工作空间")
            return False

        temp_dir = self.work_dir / name / "temp"
        if temp_dir.exists():
            for item in temp_dir.iterdir():
                if item.is_file():
                    item.unlink()
            print(f"已清理临时文件: {temp_dir}")
            return True
        return False

    def resolve_path(self, filename, workspace_name=None):
        """解析文件在工作空间中的完整路径"""
        if workspace_name is None:
            workspace_name = self.state["active_workspace"]

        if workspace_name is None:
            return None

        category = self._categorize_file(filename)
        workspace_path = self.work_dir / workspace_name / category
        return workspace_path / filename


def main():
    """命令行接口"""
    if len(sys.argv) < 2:
        print("用法: python workspace_manager.py <命令> [参数]")
        print("\n可用命令:")
        print("  create [名称] [描述]  - 创建工作空间")
        print("  list                  - 列出所有工作空间")
        print("  info [名称]           - 显示工作空间信息")
        print("  switch <名称>         - 切换工作空间")
        print("  archive [名称]        - 归档工作空间")
        print("  clean [名称]          - 清理临时文件")
        print("  resolve <文件名>      - 解析文件路径")
        return

    manager = WorkspaceManager()
    command = sys.argv[1]

    if command == "create":
        name = sys.argv[2] if len(sys.argv) > 2 else None
        description = sys.argv[3] if len(sys.argv) > 3 else None
        path = manager.create_workspace(name, description)
        print(f"✅ 工作空间已创建: {path}")

    elif command == "list":
        workspaces = manager.list_workspaces()
        if workspaces:
            print("📁 工作空间列表:")
            for ws in workspaces:
                active = " (活跃)" if ws == manager.state.get("active_workspace") else ""
                print(f"  - {ws}{active}")
        else:
            print("暂无工作空间")

    elif command == "info":
        name = sys.argv[2] if len(sys.argv) > 2 else None
        info = manager.get_workspace_info(name)
        if info:
            print(f"📊 工作空间: {info['name']}")
            print(f"路径: {info['path']}")
            print(f"总文件数: {info['total_files']}")
            print("\n文件分布:")
            for dir_name, count in info['directories'].items():
                if count > 0:
                    print(f"  {dir_name}/: {count} 个文件")
        else:
            print("未找到工作空间")

    elif command == "switch":
        if len(sys.argv) < 3:
            print("错误: 请指定工作空间名称")
            return
        name = sys.argv[2]
        path = manager.switch_workspace(name)
        if path:
            print(f"✅ 已切换到工作空间: {name}")

    elif command == "archive":
        name = sys.argv[2] if len(sys.argv) > 2 else None
        path = manager.archive_workspace(name)
        if path:
            print(f"✅ 工作空间已归档: {path}")

    elif command == "clean":
        name = sys.argv[2] if len(sys.argv) > 2 else None
        manager.clean_temp(name)

    elif command == "resolve":
        if len(sys.argv) < 3:
            print("错误: 请指定文件名")
            return
        filename = sys.argv[2]
        path = manager.resolve_path(filename)
        if path:
            print(f"文件将存放在: {path}")
        else:
            print("错误: 没有活跃的工作空间")

    else:
        print(f"未知命令: {command}")
        print("使用 'python workspace_manager.py' 查看帮助")


if __name__ == "__main__":
    main()
