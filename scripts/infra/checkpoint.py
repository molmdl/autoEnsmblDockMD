#!/usr/bin/env python3
"""
Checkpoint management for scientific workflow state persistence.

Provides CheckpointManager class for saving and loading workflow checkpoints
using JSON files with atomic write operations.
"""

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


class CheckpointManager:
    """Format-agnostic checkpoint management for scientific workflows.
    
    Provides persistent checkpoint storage for workflow stages using JSON files.
    Supports atomic writes to prevent corruption and human-readable format
    for debugging.
    
    Attributes:
        checkpoint_dir: Directory where checkpoint files are stored.
    
    Example:
        >>> cm = CheckpointManager('.checkpoints')
        >>> path = cm.save_checkpoint('docking', {'poses': 100}, {'info': 'test'})
        >>> checkpoint = cm.load_checkpoint(stage='docking')
        >>> print(checkpoint['state']['poses'])
        100
    """
    
    SCHEMA_VERSION = "1.0"
    
    def __init__(self, checkpoint_dir: str = '.checkpoints'):
        """Initialize checkpoint manager with directory.
        
        Args:
            checkpoint_dir: Directory for storing checkpoint files.
                          Defaults to '.checkpoints' in current directory.
        
        Note:
            Directory is created on first save if it doesn't exist.
        """
        self.checkpoint_dir = Path(checkpoint_dir)
    
    def save_checkpoint(self, stage: str, state: Dict[str, Any], 
                        metadata: Optional[Dict[str, Any]] = None) -> Path:
        """Save checkpoint with stage name, return path to checkpoint file.
        
        Args:
            stage: Name of the workflow stage (used in filename).
            state: State dictionary to persist (must be JSON-serializable).
            metadata: Optional metadata dictionary.
        
        Returns:
            Path to the created checkpoint file.
        
        Raises:
            OSError: If checkpoint directory cannot be created or file cannot be written.
            TypeError: If state or metadata is not JSON-serializable.
        
        Example:
            >>> path = cm.save_checkpoint('minimization', {'steps': 5000}, {'info': 'test'})
        """
        # Ensure directory exists
        self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate timestamp and filename
        timestamp = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
        filename = f"{stage}_checkpoint_{timestamp}.json"
        checkpoint_path = self.checkpoint_dir / filename
        
        # Build checkpoint data
        checkpoint_data = {
            'stage': stage,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'state': state,
            'metadata': metadata or {},
            'schema_version': self.SCHEMA_VERSION
        }
        
        # Atomic write: write to temp file, then rename
        with tempfile.NamedTemporaryFile(
            mode='w',
            dir=self.checkpoint_dir,
            delete=False,
            suffix='.json'
        ) as tmp:
            json.dump(checkpoint_data, tmp, indent=2, default=str)
            tmp_path = tmp.name
        
        os.replace(tmp_path, checkpoint_path)
        
        return checkpoint_path
    
    def load_checkpoint(self, checkpoint_path: str = None, 
                        stage: str = None) -> Optional[Dict[str, Any]]:
        """Load checkpoint by path or stage name. Priority: path > stage > latest.
        
        Args:
            checkpoint_path: Explicit path to checkpoint file.
            stage: Stage name to find checkpoint for.
        
        Returns:
            Checkpoint dictionary with stage, timestamp, state, metadata,
            and schema_version keys. None if no checkpoint found.
        
        Example:
            >>> checkpoint = cm.load_checkpoint(path='/path/to/checkpoint.json')
            >>> checkpoint = cm.load_checkpoint(stage='docking')
            >>> checkpoint = cm.load_checkpoint()  # Loads latest
        """
        # Priority: explicit path > stage > latest
        if checkpoint_path:
            path = Path(checkpoint_path)
            if path.exists():
                return self._load_from_file(path)
            return None
        
        if stage:
            return self.get_checkpoint_by_stage(stage)
        
        return self.get_latest_checkpoint()
    
    def list_checkpoints(self) -> List[Dict[str, Any]]:
        """List all available checkpoints with metadata.
        
        Returns:
            List of checkpoint metadata dictionaries, each containing:
            - path: Path to checkpoint file
            - stage: Stage name
            - timestamp: ISO timestamp
            - schema_version: Schema version string
        
        Example:
            >>> checkpoints = cm.list_checkpoints()
            >>> for ckpt in checkpoints:
            ...     print(f"{ckpt['stage']}: {ckpt['timestamp']}")
        """
        if not self.checkpoint_dir.exists():
            return []
        
        checkpoints = []
        
        for ckpt_file in sorted(self.checkpoint_dir.glob('*_checkpoint_*.json')):
            try:
                with open(ckpt_file, 'r') as f:
                    data = json.load(f)
                
                checkpoints.append({
                    'path': str(ckpt_file),
                    'stage': data.get('stage', 'unknown'),
                    'timestamp': data.get('timestamp', ''),
                    'schema_version': data.get('schema_version', 'unknown')
                })
            except (json.JSONDecodeError, IOError):
                # Skip corrupted files
                continue
        
        # Sort by timestamp (most recent first)
        checkpoints.sort(key=lambda x: x['timestamp'], reverse=True)
        
        return checkpoints
    
    def get_latest_checkpoint(self) -> Optional[Dict[str, Any]]:
        """Get the most recent checkpoint.
        
        Returns:
            Full checkpoint dictionary from the most recent checkpoint file.
            None if no checkpoints exist.
        
        Example:
            >>> latest = cm.get_latest_checkpoint()
            >>> if latest:
            ...     print(f"Latest stage: {latest['stage']}")
        """
        checkpoints = self.list_checkpoints()
        
        if not checkpoints:
            return None
        
        # List is already sorted by timestamp (most recent first)
        latest_path = checkpoints[0]['path']
        return self._load_from_file(Path(latest_path))
    
    def get_checkpoint_by_stage(self, stage: str) -> Optional[Dict[str, Any]]:
        """Get checkpoint for specific stage.
        
        Returns the most recent checkpoint for the given stage.
        
        Args:
            stage: Stage name to find checkpoint for.
        
        Returns:
            Full checkpoint dictionary from the most recent checkpoint for
            the specified stage. None if no checkpoint found for stage.
        
        Example:
            >>> ckpt = cm.get_checkpoint_by_stage('docking')
        """
        checkpoints = self.list_checkpoints()
        
        for ckpt in checkpoints:
            if ckpt['stage'] == stage:
                return self._load_from_file(Path(ckpt['path']))
        
        return None
    
    def delete_checkpoint(self, checkpoint_path: str) -> bool:
        """Delete a checkpoint file.
        
        Args:
            checkpoint_path: Path to checkpoint file to delete.
        
        Returns:
            True if file was deleted, False if file didn't exist or
            deletion failed.
        
        Example:
            >>> success = cm.delete_checkpoint('/path/to/checkpoint.json')
        """
        path = Path(checkpoint_path)
        
        if not path.exists():
            return False
        
        try:
            path.unlink()
            return True
        except OSError:
            return False
    
    def _load_from_file(self, path: Path) -> Optional[Dict[str, Any]]:
        """Load checkpoint from file.
        
        Args:
            path: Path to checkpoint file.
        
        Returns:
            Checkpoint dictionary or None if loading fails.
        """
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return None
    
    def __repr__(self) -> str:
        """String representation of CheckpointManager."""
        count = len(self.list_checkpoints())
        return f"CheckpointManager(checkpoint_dir='{self.checkpoint_dir}', checkpoints={count})"


def main():
    """CLI interface for CheckpointManager."""
    parser = argparse.ArgumentParser(
        description='Manage workflow checkpoints',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Save a checkpoint
  python -m scripts.infra.checkpoint save --stage docking --state '{"poses": 100}'

  # Load a checkpoint by stage
  python -m scripts.infra.checkpoint load --stage docking

  # Load a checkpoint by path
  python -m scripts.infra.checkpoint load --path .checkpoints/docking_checkpoint_20240315-143022.json

  # List all checkpoints
  python -m scripts.infra.checkpoint list

  # Get latest checkpoint
  python -m scripts.infra.checkpoint latest

  # Delete a checkpoint
  python -m scripts.infra.checkpoint delete --path .checkpoints/old_checkpoint.json
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Save command
    save_parser = subparsers.add_parser('save', help='Save a checkpoint')
    save_parser.add_argument('--stage', required=True, help='Stage name')
    save_parser.add_argument('--state', required=True, 
                             help='State as JSON string')
    save_parser.add_argument('--metadata', default='{}', 
                             help='Metadata as JSON string (optional)')
    save_parser.add_argument('--dir', default='.checkpoints', 
                             help='Checkpoint directory (default: .checkpoints)')
    
    # Load command
    load_parser = subparsers.add_parser('load', help='Load a checkpoint')
    load_parser.add_argument('--path', help='Path to checkpoint file')
    load_parser.add_argument('--stage', help='Stage name to load')
    load_parser.add_argument('--dir', default='.checkpoints', 
                             help='Checkpoint directory (default: .checkpoints)')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List all checkpoints')
    list_parser.add_argument('--dir', default='.checkpoints', 
                             help='Checkpoint directory (default: .checkpoints)')
    
    # Latest command
    latest_parser = subparsers.add_parser('latest', help='Get latest checkpoint')
    latest_parser.add_argument('--dir', default='.checkpoints', 
                               help='Checkpoint directory (default: .checkpoints)')
    
    # Delete command
    delete_parser = subparsers.add_parser('delete', help='Delete a checkpoint')
    delete_parser.add_argument('--path', required=True, 
                               help='Path to checkpoint file to delete')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        if args.command == 'save':
            cm = CheckpointManager(args.dir)
            state = json.loads(args.state)
            metadata = json.loads(args.metadata)
            path = cm.save_checkpoint(args.stage, state, metadata)
            print(f"Checkpoint saved: {path}")
        
        elif args.command == 'load':
            cm = CheckpointManager(args.dir)
            checkpoint = cm.load_checkpoint(
                checkpoint_path=args.path,
                stage=args.stage
            )
            if checkpoint:
                print(json.dumps(checkpoint, indent=2, default=str))
            else:
                print("No checkpoint found", file=sys.stderr)
                sys.exit(1)
        
        elif args.command == 'list':
            cm = CheckpointManager(args.dir)
            checkpoints = cm.list_checkpoints()
            if checkpoints:
                print(json.dumps(checkpoints, indent=2, default=str))
            else:
                print("No checkpoints found")
        
        elif args.command == 'latest':
            cm = CheckpointManager(args.dir)
            checkpoint = cm.get_latest_checkpoint()
            if checkpoint:
                print(json.dumps(checkpoint, indent=2, default=str))
            else:
                print("No checkpoints found", file=sys.stderr)
                sys.exit(1)
        
        elif args.command == 'delete':
            cm = CheckpointManager()
            if cm.delete_checkpoint(args.path):
                print(f"Deleted: {args.path}")
            else:
                print(f"Failed to delete: {args.path}", file=sys.stderr)
                sys.exit(1)
    
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
