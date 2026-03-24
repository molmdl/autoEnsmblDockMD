#!/usr/bin/env python3
"""
File-based state management for agent session continuity.

Provides AgentState class for persisting agent context across sessions
using JSON files with atomic write operations.
"""

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional


class AgentState:
    """File-based state management for agent session continuity.
    
    Provides persistent storage for agent context using JSON files.
    Supports nested key access via dot notation and atomic writes
    to prevent corruption.
    
    Attributes:
        state_file: Path to the JSON state file.
        state: Current state dictionary.
    
    Example:
        >>> state = AgentState('.agent_state.json')
        >>> state.set('project.name', 'autoEnsmblDockMD')
        >>> state.set('stage.status', 'running')
        >>> print(state.get('project.name'))
        'autoEnsmblDockMD'
    """
    
    def __init__(self, state_file: str = '.agent_state.json'):
        """Initialize state manager and load existing state if file exists.
        
        Args:
            state_file: Path to the JSON state file. Defaults to
                       '.agent_state.json' in current directory.
        
        Note:
            Does not auto-create file on init. File is created on first set().
        """
        self.state_file = Path(state_file)
        self.state: Dict[str, Any] = {}
        
        # Load existing state if file exists
        if self.state_file.exists():
            self._load()
    
    def set(self, key: str, value: Any) -> None:
        """Set a state value and persist immediately.
        
        Supports nested key access via dot notation.
        
        Args:
            key: State key (supports dot notation for nested keys).
            value: Value to store (must be JSON-serializable).
        
        Example:
            >>> state.set('stage.status', 'complete')
            >>> state.set('counts.attempts', 3)
        """
        # Handle nested keys with dot notation
        keys = key.split('.')
        current = self.state
        
        # Navigate to nested location
        for k in keys[:-1]:
            if k not in current:
                current[k] = {}
            current = current[k]
        
        # Set the value
        current[keys[-1]] = value
        
        # Persist to file
        self._save()
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get a state value.
        
        Supports nested key access via dot notation.
        
        Args:
            key: State key (supports dot notation for nested keys).
            default: Default value if key not found.
        
        Returns:
            Stored value or default if not found.
        
        Example:
            >>> state.get('stage.status', 'unknown')
            'complete'
        """
        # Handle nested keys with dot notation
        keys = key.split('.')
        current = self.state
        
        try:
            for k in keys:
                current = current[k]
            return current
        except (KeyError, TypeError):
            return default
    
    def update(self, updates: Dict[str, Any]) -> None:
        """Update multiple state values atomically.
        
        Performs a single write after all updates.
        
        Args:
            updates: Dictionary of key-value pairs to update.
                    Keys support dot notation for nested access.
        
        Example:
            >>> state.update({'stage.status': 'done', 'stage.attempts': 5})
        """
        for key, value in updates.items():
            keys = key.split('.')
            current = self.state
            
            for k in keys[:-1]:
                if k not in current:
                    current[k] = {}
                current = current[k]
            
            current[keys[-1]] = value
        
        # Single save after all updates
        self._save()
    
    def clear(self) -> None:
        """Clear all state.
        
        Removes all keys and deletes the state file if it exists.
        """
        self.state = {}
        
        if self.state_file.exists():
            try:
                self.state_file.unlink()
            except Exception:
                pass
    
    def dump_to_file(self, output_path: str) -> None:
        """Dump state to specified file for session handoff.
        
        Args:
            output_path: Path where state should be written.
        
        Note:
            Does not affect the main state file.
        """
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        
        state_with_meta = {
            **self.state,
            'last_updated': datetime.utcnow().isoformat() + 'Z'
        }
        
        # Atomic write
        with tempfile.NamedTemporaryFile(
            mode='w',
            dir=output.parent,
            delete=False,
            suffix='.json'
        ) as tmp:
            json.dump(state_with_meta, tmp, indent=2, default=str)
            tmp_path = tmp.name
        
        os.replace(tmp_path, output)
    
    def load_from_file(self, input_path: str) -> bool:
        """Load state from specified file.
        
        Replaces current state with state from file.
        
        Args:
            input_path: Path to state file to load.
        
        Returns:
            True if file loaded successfully, False otherwise.
        """
        input_file = Path(input_path)
        
        if not input_file.exists():
            return False
        
        try:
            with open(input_file, 'r') as f:
                data = json.load(f)
            
            # Remove metadata
            data.pop('last_updated', None)
            self.state = data
            return True
        except (json.JSONDecodeError, IOError):
            return False
    
    def get_all(self) -> Dict[str, Any]:
        """Get entire state dictionary.
        
        Returns:
            Copy of current state dictionary.
        """
        return dict(self.state)
    
    def _save(self) -> None:
        """Save state to file with atomic write.
        
        Writes to temp file first, then renames to prevent corruption.
        Automatically adds last_updated timestamp.
        """
        # Ensure parent directory exists
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Add timestamp
        state_with_meta = {
            **self.state,
            'last_updated': datetime.utcnow().isoformat() + 'Z'
        }
        
        # Atomic write: write to temp, then rename
        try:
            with tempfile.NamedTemporaryFile(
                mode='w',
                dir=self.state_file.parent,
                delete=False,
                suffix='.json'
            ) as tmp:
                json.dump(state_with_meta, tmp, indent=2, default=str)
                tmp_path = tmp.name
            
            os.replace(tmp_path, self.state_file)
        except (IOError, OSError) as e:
            # Handle JSON serialization errors gracefully
            print(f"Warning: Failed to save state: {e}", file=sys.stderr)
    
    def _load(self) -> None:
        """Load state from file.
        
        Handles JSON errors gracefully by starting with empty state.
        """
        try:
            with open(self.state_file, 'r') as f:
                data = json.load(f)
            
            # Remove metadata
            data.pop('last_updated', None)
            self.state = data
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Failed to load state: {e}", file=sys.stderr)
            self.state = {}
    
    def __repr__(self) -> str:
        """String representation of AgentState."""
        return f"AgentState(state_file='{self.state_file}', keys={list(self.state.keys())})"


def main():
    """CLI interface for AgentState."""
    parser = argparse.ArgumentParser(
        description='Manage agent state files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Set a value
  python -m scripts.infra.state --file .agent_state.json --set project.name=myproject

  # Get a value
  python -m scripts.infra.state --file .agent_state.json --get project.name

  # Clear all state
  python -m scripts.infra.state --file .agent_state.json --clear

  # Dump to another file
  python -m scripts.infra.state --file .agent_state.json --dump handoff.json
        """
    )
    
    parser.add_argument('--file', default='.agent_state.json',
                        help='Path to state file (default: .agent_state.json)')
    parser.add_argument('--set', action='append', metavar='KEY=VALUE',
                        help='Set a key=value pair (can be used multiple times)')
    parser.add_argument('--get', metavar='KEY', help='Get a value by key')
    parser.add_argument('--clear', action='store_true', help='Clear all state')
    parser.add_argument('--dump', metavar='OUTPUT', help='Dump state to file')
    parser.add_argument('--load', metavar='INPUT', help='Load state from file')
    
    args = parser.parse_args()
    
    try:
        state = AgentState(args.file)
        
        if args.clear:
            state.clear()
            print(f"State cleared: {args.file}")
            return
        
        if args.load:
            if state.load_from_file(args.load):
                print(f"State loaded from: {args.load}")
            else:
                print(f"Failed to load state from: {args.load}", file=sys.stderr)
                sys.exit(1)
            return
        
        if args.dump:
            state.dump_to_file(args.dump)
            print(f"State dumped to: {args.dump}")
            return
        
        if args.set:
            for pair in args.set:
                if '=' not in pair:
                    print(f"Invalid format: {pair}. Use KEY=VALUE", file=sys.stderr)
                    sys.exit(1)
                key, value = pair.split('=', 1)
                state.set(key, value)
            print(f"Set {len(args.set)} value(s)")
            return
        
        if args.get:
            value = state.get(args.get)
            if value is None:
                print(f"Key '{args.get}' not found", file=sys.stderr)
                sys.exit(1)
            print(value)
            return
        
        # No action specified - show all state
        all_state = state.get_all()
        if all_state:
            print(json.dumps(all_state, indent=2, default=str))
        else:
            print("State is empty")
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
