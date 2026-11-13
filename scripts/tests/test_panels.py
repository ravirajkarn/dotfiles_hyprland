#!/usr/bin/env python3
"""The panel names: ShellState.panels, the LazyPanels of shell.qml and desktop-shell toggle must agree."""
from pathlib import Path
import re
import unittest

REPO = Path(__file__).resolve().parents[2]
SHELL = REPO / 'quickshell/.config/quickshell/desktop'


class PanelTests(unittest.TestCase):
    def test_the_three_lists_name_the_same_panels(self):
        state = re.search(r'readonly property var panels: \[([^\]]*)\]', (SHELL / 'ShellState.qml').read_text())
        allowed = set(re.findall(r'"([a-z]+)"', state[1]))
        lazy = set(re.findall(r'LazyPanel \{\s*(?:id: \w+\s*)?name: "([a-z]+)"', (SHELL / 'shell.qml').read_text()))
        toggle = re.search(r'toggle\)\s*case "\$\{2:-\}" in ([a-z|]+)\)', (REPO / 'shell/.local/bin/desktop-shell').read_text())
        wrapper = set(toggle[1].split('|'))
        # Former panels that are now a section of another (ShellState.aliases) stay accepted by desktop-shell.
        aliases = re.search(r'readonly property var aliases: \(\{(.*?)\n        \}\)', (SHELL / 'ShellState.qml').read_text(), re.S)
        renamed = set(re.findall(r'^            (\w+): \{', aliases[1], re.M))
        self.assertTrue(allowed)
        self.assertTrue(renamed)
        self.assertFalse(renamed & allowed, 'an alias is also a panel')
        self.assertEqual(lazy, allowed, 'shell.qml LazyPanels vs ShellState.panels')
        self.assertEqual(wrapper, allowed | renamed, 'desktop-shell toggle vs ShellState.panels and aliases')

    def test_no_method_is_named_after_a_javascript_global(self):
        # QML refuses such a method ("Illegal method name") and the whole file fails to load: a NetworkView with
        # escape() took the shell down on 2026-11-06.
        globals_ = {'escape', 'unescape', 'eval', 'isNaN', 'isFinite', 'parseInt', 'parseFloat', 'encodeURI',
                    'decodeURI', 'encodeURIComponent', 'decodeURIComponent'}
        for path in SHELL.rglob('*.qml'):
            for name in re.findall(r'^\s*function (\w+)\(', path.read_text(), re.M):
                self.assertNotIn(name, globals_, f'{path.relative_to(SHELL)}: function {name}()')

    def test_every_singleton_of_services_is_registered(self):
        # A singleton missing from services/qmldir is not found by the files that use it, and the shell does not
        # start.
        registered = set(re.findall(r'^singleton (\w+) ', (SHELL / 'services/qmldir').read_text(), re.M))
        for path in (SHELL / 'services').glob('*.qml'):
            if 'pragma Singleton' in path.read_text():
                self.assertIn(path.stem, registered, f'services/{path.name} is not in services/qmldir')

    def test_every_qmldir_entry_exists_on_disk(self):
        # Every file named in a qmldir must exist on disk, otherwise Quickshell crashes with "File not found" on startup.
        for qmldir in SHELL.rglob('qmldir'):
            for line in qmldir.read_text().splitlines():
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split()
                filename = parts[-1]
                target = qmldir.parent / filename
                self.assertTrue(target.is_file(), f'{qmldir.relative_to(SHELL)}: {filename} does not exist')

    def test_every_module_source_in_controls_exists(self):
        # Controls.qml moduleSources must point to existing files.
        controls = (SHELL / 'controlcenter/Controls.qml').read_text()
        sources = re.findall(r'(\w+):\s*"([^"]+\.qml)"', controls)
        for name, filename in sources:
            target = SHELL / 'controlcenter' / filename
            self.assertTrue(target.is_file(), f'Controls.qml moduleSources[{name}]: {filename} does not exist')

    def test_stowed_files_in_home_are_in_sync_if_installed(self):
        # If the user has stowed quickshell into ~/.config, all files from the repo must exist and point to the repo.
        home_shell = Path.home() / '.config/quickshell/desktop'
        if not (home_shell / 'shell.qml').exists():
            return
        for repo_file in SHELL.rglob('*'):
            if repo_file.is_file() and not repo_file.name.endswith('.pyc') and repo_file.name != '__pycache__':
                rel = repo_file.relative_to(SHELL)
                home_file = home_shell / rel
                self.assertTrue(home_file.exists(), f'Missing in ~/.config/quickshell/desktop: {rel} (run stow.py apply)')
                self.assertEqual(home_file.resolve(), repo_file.resolve(), f'~/.config/quickshell/desktop/{rel} does not point to {repo_file}')


if __name__ == '__main__':
    unittest.main()
