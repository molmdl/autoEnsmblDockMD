#!/usr/bin/env python3
"""
Verification gate system for human review between workflow stages.

Provides VerificationGate class for creating and managing human verification
checkpoints that pause workflow execution until approved.
"""

import argparse
import json
import os
import sys
import tempfile
import fcntl
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional


class GateState(Enum):
    """Verification gate states."""
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PAUSED = 'paused'


class VerificationGate:
    """Human verification gate mechanism.
    
    Provides persistent verification gates for workflow stages. Gates persist
    state across sessions and enforce state transition rules.
    
    Attributes:
        stage_name: Name of the workflow stage this gate belongs to.
        gate_dir: Directory where gate files are stored.
    
    Example:
        >>> gate = VerificationGate('docking', '.gates')
        >>> gate.create_gate('Review docking results',
        ...                  metadata={'ligand_count': 5},
        ...                  output_paths=['/path/to/poses.pdb'])
        >>> gate.approve(notes='Looks good')
        >>> assert gate.can_proceed()
    """
    
    # Valid state transitions: {from_state: [allowed_to_states]}
    VALID_TRANSITIONS = {
        GateState.PENDING: [GateState.APPROVED, GateState.REJECTED, GateState.PAUSED],
        GateState.PAUSED: [GateState.APPROVED, GateState.REJECTED],
        GateState.APPROVED: [],  # Terminal state
        GateState.REJECTED: [],  # Terminal state
    }
    
    LOCK_TIMEOUT = 5  # seconds
    
    def __init__(self, stage_name: str, gate_dir: str = '.gates'):
        """Initialize gate for specific stage.
        
        Args:
            stage_name: Name of the workflow stage.
            gate_dir: Directory for storing gate files. Defaults to '.gates'.
        """
        self.stage_name = stage_name
        self.gate_dir = Path(gate_dir)
        self.gate_file = self.gate_dir / f"{stage_name}_gate.json"
    
    def create_gate(self, description: str, metadata: Dict[str, Any] = None,
                    output_paths: List[str] = None, 
                    metrics: Dict[str, Any] = None) -> None:
        """Create a new verification gate with context for human review.
        
        Args:
            description: Human-readable description of what needs verification.
            metadata: Optional metadata dictionary.
            output_paths: Optional list of output file paths to review.
            metrics: Optional metrics dictionary.
        
        Raises:
            ValueError: If description is empty.
            OSError: If gate directory cannot be created or file cannot be written.
        """
        if not description or not description.strip():
            raise ValueError("Description is required and cannot be empty")
        
        # Ensure directory exists
        self.gate_dir.mkdir(parents=True, exist_ok=True)
        
        # Build gate data
        gate_data = {
            'stage': self.stage_name,
            'state': GateState.PENDING.value,
            'created_at': datetime.utcnow().isoformat() + 'Z',
            'description': description.strip(),
            'metadata': metadata or {},
            'output_paths': output_paths or [],
            'metrics': metrics or {},
            'history': [
                {
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'action': 'created',
                    'actor': 'system',
                    'notes': ''
                }
            ]
        }
        
        # Write gate file with exclusive lock
        self._write_gate_file(gate_data)
    
    def approve(self, approver: str = 'human', notes: str = '') -> bool:
        """Approve the gate and record decision.
        
        Args:
            approver: Who approved the gate. Defaults to 'human'.
            notes: Optional notes about the approval.
        
        Returns:
            True if approval succeeded.
        
        Raises:
            ValueError: If state transition is invalid.
        """
        def _approve_operation(gate_data: Dict[str, Any]) -> None:
            current_state = GateState(gate_data['state'])
            self._validate_transition(current_state, GateState.APPROVED)
            
            # Update state
            gate_data['state'] = GateState.APPROVED.value
            
            # Add history entry
            gate_data['history'].append({
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'action': 'approved',
                'actor': approver,
                'notes': notes
            })
        
        return self._modify_gate(_approve_operation)
    
    def reject(self, reason: str, rejecter: str = 'human') -> bool:
        """Reject the gate with reason.
        
        Args:
            reason: Reason for rejection.
            rejecter: Who rejected the gate. Defaults to 'human'.
        
        Returns:
            True if rejection succeeded.
        
        Raises:
            ValueError: If state transition is invalid or reason is empty.
        """
        if not reason or not reason.strip():
            raise ValueError("Rejection reason is required")
        
        reason_text = reason.strip()
        
        def _reject_operation(gate_data: Dict[str, Any]) -> None:
            current_state = GateState(gate_data['state'])
            self._validate_transition(current_state, GateState.REJECTED)
            
            # Update state
            gate_data['state'] = GateState.REJECTED.value
            
            # Add history entry
            gate_data['history'].append({
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'action': 'rejected',
                'actor': rejecter,
                'notes': reason_text
            })
        
        return self._modify_gate(_reject_operation)
    
    def pause(self, reason: str = '') -> bool:
        """Pause at current gate for later review.
        
        Args:
            reason: Optional reason for pausing.
        
        Returns:
            True if pause succeeded.
        
        Raises:
            ValueError: If state transition is invalid.
        """
        def _pause_operation(gate_data: Dict[str, Any]) -> None:
            current_state = GateState(gate_data['state'])
            self._validate_transition(current_state, GateState.PAUSED)
            
            # Update state
            gate_data['state'] = GateState.PAUSED.value
            
            # Add history entry
            gate_data['history'].append({
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'action': 'paused',
                'actor': 'system',
                'notes': reason
            })
        
        return self._modify_gate(_pause_operation)
    
    def get_state(self) -> Optional[GateState]:
        """Get current gate state.
        
        Returns:
            Current GateState enum value, or None if gate doesn't exist.
        """
        gate_data = self._read_gate_file()
        if gate_data is None:
            return None
        return GateState(gate_data['state'])
    
    def can_proceed(self) -> bool:
        """Check if workflow can proceed past this gate.
        
        Returns:
            True only if gate is in APPROVED state. False otherwise.
        """
        state = self.get_state()
        return state == GateState.APPROVED
    
    def get_gate_info(self) -> Optional[Dict[str, Any]]:
        """Get full gate information including history.
        
        Returns:
            Full gate dictionary, or None if gate doesn't exist.
        """
        return self._read_gate_file()
    
    def add_note(self, note: str) -> bool:
        """Add a note to the gate without changing state.
        
        Args:
            note: Note to add.
        
        Returns:
            True if note was added successfully.
        
        Raises:
            ValueError: If note is empty.
        """
        if not note or not note.strip():
            raise ValueError("Note cannot be empty")
        
        note_text = note.strip()
        
        def _add_note_operation(gate_data: Dict[str, Any]) -> None:
            # Add history entry
            gate_data['history'].append({
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'action': 'note_added',
                'actor': 'human',
                'notes': note_text
            })
        
        return self._modify_gate(_add_note_operation)
    
    def get_context_summary(self) -> str:
        """Get formatted summary for human review.
        
        Returns:
            Human-readable summary string.
        
        Raises:
            ValueError: If gate doesn't exist.
        """
        gate_data = self._read_gate_file()
        if gate_data is None:
            raise ValueError(f"No gate found for stage '{self.stage_name}'")
        
        lines = []
        lines.append(f"=== Verification Gate: {gate_data['stage']} ===")
        lines.append(f"State: {gate_data['state'].upper()}")
        lines.append(f"Created: {self._format_timestamp(gate_data['created_at'])}")
        lines.append("")
        lines.append(f"Description: {gate_data['description']}")
        lines.append("")
        
        # Output files
        if gate_data.get('output_paths'):
            lines.append("Output Files:")
            for path in gate_data['output_paths']:
                lines.append(f"  - {path}")
            lines.append("")
        
        # Metrics
        if gate_data.get('metrics'):
            lines.append("Key Metrics:")
            for key, value in gate_data['metrics'].items():
                lines.append(f"  - {key}: {value}")
            lines.append("")
        
        # Metadata
        if gate_data.get('metadata'):
            lines.append("Metadata:")
            for key, value in gate_data['metadata'].items():
                lines.append(f"  - {key}: {value}")
            lines.append("")
        
        # History
        lines.append("History:")
        for entry in gate_data['history']:
            timestamp = self._format_timestamp(entry['timestamp'])
            action = entry['action']
            actor = entry['actor']
            notes = entry.get('notes', '')
            
            if action == 'created':
                lines.append(f"  - {timestamp}: Gate created by {actor}")
            elif action == 'approved':
                lines.append(f"  - {timestamp}: Approved by {actor}")
                if notes:
                    lines.append(f"    Notes: {notes}")
            elif action == 'rejected':
                lines.append(f"  - {timestamp}: Rejected by {actor}")
                lines.append(f"    Reason: {notes}")
            elif action == 'paused':
                lines.append(f"  - {timestamp}: Paused by {actor}")
                if notes:
                    lines.append(f"    Reason: {notes}")
            elif action == 'note_added':
                lines.append(f"  - {timestamp}: Note added by {actor}")
                lines.append(f"    {notes}")
        
        return '\n'.join(lines)
    
    def _validate_transition(self, from_state: GateState, to_state: GateState) -> None:
        """Validate state transition.
        
        Args:
            from_state: Current state.
            to_state: Target state.
        
        Raises:
            ValueError: If transition is invalid.
        """
        allowed = self.VALID_TRANSITIONS.get(from_state, [])
        if to_state not in allowed:
            raise ValueError(
                f"Invalid state transition: {from_state.value} → {to_state.value}. "
                f"Allowed transitions from {from_state.value}: "
                f"{[s.value for s in allowed]}"
            )
    
    def _modify_gate(self, operation) -> bool:
        """Execute a modification operation with exclusive lock.
        
        Provides atomic read-modify-write semantics by holding an exclusive
        lock for the entire operation.
        
        Args:
            operation: Callable that takes gate_data dict and modifies it in place.
        
        Returns:
            True if operation succeeded.
        
        Raises:
            ValueError: If gate doesn't exist.
        """
        # Ensure directory exists
        self.gate_dir.mkdir(parents=True, exist_ok=True)
        
        # Use a lock file to synchronize operations
        lock_file = self.gate_dir / ".gate_write.lock"
        
        # Open/create lock file and acquire exclusive lock
        with open(lock_file, 'a') as lockf:
            self._acquire_lock(lockf, fcntl.LOCK_EX)
            try:
                # Read current state
                if not self.gate_file.exists():
                    raise ValueError(f"No gate found for stage '{self.stage_name}'")
                
                with open(self.gate_file, 'r') as f:
                    gate_data = json.load(f)
                
                # Apply the modification
                operation(gate_data)
                
                # Write back atomically
                with tempfile.NamedTemporaryFile(
                    mode='w',
                    dir=self.gate_dir,
                    delete=False,
                    suffix='.json'
                ) as tmp:
                    json.dump(gate_data, tmp, indent=2, default=str)
                    tmp_path = tmp.name
                
                os.replace(tmp_path, self.gate_file)
            finally:
                fcntl.flock(lockf.fileno(), fcntl.LOCK_UN)
        
        return True
    
    def _read_gate_file(self) -> Optional[Dict[str, Any]]:
        """Read gate file with shared lock.
        
        Returns:
            Gate data dictionary, or None if file doesn't exist.
        """
        if not self.gate_file.exists():
            return None
        
        try:
            with open(self.gate_file, 'r') as f:
                # Acquire shared lock with timeout
                self._acquire_lock(f, fcntl.LOCK_SH)
                try:
                    data = json.load(f)
                finally:
                    fcntl.flock(f.fileno(), fcntl.LOCK_UN)
            return data
        except (json.JSONDecodeError, IOError):
            return None
    
    def _write_gate_file(self, gate_data: Dict[str, Any]) -> None:
        """Write gate file with exclusive lock using atomic write.
        
        Args:
            gate_data: Gate data to write.
        """
        # Ensure directory exists
        self.gate_dir.mkdir(parents=True, exist_ok=True)
        
        # Use a lock file to synchronize writes
        lock_file = self.gate_dir / ".gate_write.lock"
        
        # Open/create lock file and acquire exclusive lock
        # Use 'a' mode to create if doesn't exist, without truncating
        with open(lock_file, 'a') as lockf:
            self._acquire_lock(lockf, fcntl.LOCK_EX)
            try:
                # Atomic write: write to temp file, then rename
                with tempfile.NamedTemporaryFile(
                    mode='w',
                    dir=self.gate_dir,
                    delete=False,
                    suffix='.json'
                ) as tmp:
                    json.dump(gate_data, tmp, indent=2, default=str)
                    tmp_path = tmp.name
                
                # Atomic rename
                os.replace(tmp_path, self.gate_file)
            finally:
                fcntl.flock(lockf.fileno(), fcntl.LOCK_UN)
    
    def _acquire_lock(self, file_obj, lock_type: int) -> None:
        """Acquire file lock with timeout.
        
        Args:
            file_obj: File object to lock.
            lock_type: fcntl.LOCK_SH or fcntl.LOCK_EX.
        
        Raises:
            TimeoutError: If lock cannot be acquired within timeout.
        """
        import time
        start_time = time.time()
        
        while True:
            try:
                # LOCK_NB = non-blocking
                fcntl.flock(file_obj.fileno(), lock_type | fcntl.LOCK_NB)
                return
            except IOError:
                if time.time() - start_time >= self.LOCK_TIMEOUT:
                    raise TimeoutError(
                        f"Could not acquire lock on {self.gate_file} "
                        f"within {self.LOCK_TIMEOUT} seconds"
                    )
                time.sleep(0.1)
    
    def _format_timestamp(self, timestamp: str) -> str:
        """Format ISO timestamp for human reading.
        
        Args:
            timestamp: ISO format timestamp string.
        
        Returns:
            Human-readable timestamp.
        """
        try:
            # Parse ISO timestamp
            if timestamp.endswith('Z'):
                timestamp = timestamp[:-1]
            dt = datetime.fromisoformat(timestamp)
            return dt.strftime('%Y-%m-%d %H:%M:%S')
        except (ValueError, TypeError):
            return timestamp
    
    def __repr__(self) -> str:
        """String representation of VerificationGate."""
        state = self.get_state()
        state_str = state.value if state else 'none'
        return f"VerificationGate(stage='{self.stage_name}', state='{state_str}')"


def list_gates(gate_dir: str = '.gates') -> List[Dict[str, Any]]:
    """List all gates in directory.
    
    Args:
        gate_dir: Directory to search for gate files.
    
    Returns:
        List of gate info dictionaries.
    """
    gate_path = Path(gate_dir)
    if not gate_path.exists():
        return []
    
    gates = []
    for gate_file in sorted(gate_path.glob('*_gate.json')):
        try:
            with open(gate_file, 'r') as f:
                data = json.load(f)
            gates.append({
                'stage': data.get('stage', 'unknown'),
                'state': data.get('state', 'unknown'),
                'created_at': data.get('created_at', ''),
                'description': data.get('description', '')
            })
        except (json.JSONDecodeError, IOError):
            continue
    
    return gates


def main():
    """CLI interface for VerificationGate."""
    parser = argparse.ArgumentParser(
        description='Manage verification gates for workflow stages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create a gate
  python -m scripts.infra.verification create --stage docking --desc "Review docking results"

  # Check gate status
  python -m scripts.infra.verification status --stage docking

  # Approve a gate
  python -m scripts.infra.verification approve --stage docking --notes "Looks good"

  # Reject a gate
  python -m scripts.infra.verification reject --stage docking --reason "Need rerun"

  # Pause a gate
  python -m scripts.infra.verification pause --stage docking --reason "Waiting for input"

  # Get detailed summary
  python -m scripts.infra.verification summary --stage docking

  # List all gates
  python -m scripts.infra.verification list
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Create command
    create_parser = subparsers.add_parser('create', help='Create a verification gate')
    create_parser.add_argument('--stage', required=True, help='Stage name')
    create_parser.add_argument('--desc', required=True, help='Gate description')
    create_parser.add_argument('--metadata', default='{}', 
                               help='Metadata as JSON string (optional)')
    create_parser.add_argument('--outputs', default='[]', 
                               help='Output paths as JSON array (optional)')
    create_parser.add_argument('--metrics', default='{}', 
                               help='Metrics as JSON string (optional)')
    create_parser.add_argument('--gate-dir', default='.gates', 
                               help='Gate directory (default: .gates)')
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Get gate status')
    status_parser.add_argument('--stage', required=True, help='Stage name')
    status_parser.add_argument('--gate-dir', default='.gates', 
                               help='Gate directory (default: .gates)')
    
    # Approve command
    approve_parser = subparsers.add_parser('approve', help='Approve a gate')
    approve_parser.add_argument('--stage', required=True, help='Stage name')
    approve_parser.add_argument('--notes', default='', help='Approval notes')
    approve_parser.add_argument('--approver', default='human', help='Approver name')
    approve_parser.add_argument('--gate-dir', default='.gates', 
                                help='Gate directory (default: .gates)')
    
    # Reject command
    reject_parser = subparsers.add_parser('reject', help='Reject a gate')
    reject_parser.add_argument('--stage', required=True, help='Stage name')
    reject_parser.add_argument('--reason', required=True, help='Rejection reason')
    reject_parser.add_argument('--rejecter', default='human', help='Rejecter name')
    reject_parser.add_argument('--gate-dir', default='.gates', 
                               help='Gate directory (default: .gates)')
    
    # Pause command
    pause_parser = subparsers.add_parser('pause', help='Pause a gate')
    pause_parser.add_argument('--stage', required=True, help='Stage name')
    pause_parser.add_argument('--reason', default='', help='Pause reason')
    pause_parser.add_argument('--gate-dir', default='.gates', 
                              help='Gate directory (default: .gates)')
    
    # Summary command
    summary_parser = subparsers.add_parser('summary', help='Get gate summary')
    summary_parser.add_argument('--stage', required=True, help='Stage name')
    summary_parser.add_argument('--gate-dir', default='.gates', 
                                help='Gate directory (default: .gates)')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List all gates')
    list_parser.add_argument('--gate-dir', default='.gates', 
                             help='Gate directory (default: .gates)')
    
    # Note command
    note_parser = subparsers.add_parser('note', help='Add a note to a gate')
    note_parser.add_argument('--stage', required=True, help='Stage name')
    note_parser.add_argument('--note', required=True, help='Note to add')
    note_parser.add_argument('--gate-dir', default='.gates', 
                             help='Gate directory (default: .gates)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        if args.command == 'create':
            gate = VerificationGate(args.stage, args.gate_dir)
            metadata = json.loads(args.metadata)
            outputs = json.loads(args.outputs)
            metrics = json.loads(args.metrics)
            gate.create_gate(args.desc, metadata, outputs, metrics)
            print(f"Gate created for stage '{args.stage}'")
        
        elif args.command == 'status':
            gate = VerificationGate(args.stage, args.gate_dir)
            state = gate.get_state()
            if state:
                print(f"Stage: {args.stage}")
                print(f"State: {state.value.upper()}")
                print(f"Can proceed: {gate.can_proceed()}")
            else:
                print(f"No gate found for stage '{args.stage}'", file=sys.stderr)
                sys.exit(1)
        
        elif args.command == 'approve':
            gate = VerificationGate(args.stage, args.gate_dir)
            gate.approve(args.approver, args.notes)
            print(f"Gate approved for stage '{args.stage}'")
        
        elif args.command == 'reject':
            gate = VerificationGate(args.stage, args.gate_dir)
            gate.reject(args.reason, args.rejecter)
            print(f"Gate rejected for stage '{args.stage}'")
        
        elif args.command == 'pause':
            gate = VerificationGate(args.stage, args.gate_dir)
            gate.pause(args.reason)
            print(f"Gate paused for stage '{args.stage}'")
        
        elif args.command == 'summary':
            gate = VerificationGate(args.stage, args.gate_dir)
            print(gate.get_context_summary())
        
        elif args.command == 'list':
            gates = list_gates(args.gate_dir)
            if gates:
                print(f"Found {len(gates)} gate(s):\n")
                for g in gates:
                    print(f"Stage: {g['stage']}")
                    print(f"  State: {g['state'].upper()}")
                    print(f"  Created: {g['created_at']}")
                    print(f"  Description: {g['description']}")
                    print()
            else:
                print("No gates found")
        
        elif args.command == 'note':
            gate = VerificationGate(args.stage, args.gate_dir)
            gate.add_note(args.note)
            print(f"Note added to gate '{args.stage}'")
    
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except TimeoutError as e:
        print(f"Lock timeout: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
