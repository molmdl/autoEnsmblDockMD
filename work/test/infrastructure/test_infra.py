#!/usr/bin/env python
"""Integration tests for Phase 1 infrastructure."""

import os
import sys
import tempfile
import json
from pathlib import Path

# Add repo root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from scripts.infra import (
    ConfigManager, AgentState, CheckpointManager,
    detect_execution_backend, LocalExecutor,
    JobStatus, LogMonitor, GateState, VerificationGate
)


def test_config_to_executor_integration():
    """Test config provides settings to executor."""
    print("Testing config → executor integration...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.ini', delete=False) as f:
        f.write("""
[execution]
backend = auto

[slurm]
account = test_account
time_limit = 01:00:00
""")
        config_path = f.name
    
    try:
        config = ConfigManager(config_path)
        backend = config.get_execution_backend()
        assert backend in ['local', 'slurm'], f"Unexpected backend: {backend}"
        print(f"  ✓ Backend detection: {backend}")
    finally:
        os.remove(config_path)


def test_checkpoint_to_verification_integration():
    """Test checkpoint and verification gate work together."""
    print("Testing checkpoint → verification integration...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create checkpoint
        ckpt_mgr = CheckpointManager(os.path.join(tmpdir, 'checkpoints'))
        ckpt_path = ckpt_mgr.save_checkpoint(
            'docking',
            {'best_score': -8.5, 'pose_count': 10},
            {'description': 'Docking results'}
        )
        print(f"  ✓ Checkpoint saved: {ckpt_path}")
        
        # Create verification gate
        gate = VerificationGate('docking', os.path.join(tmpdir, 'gates'))
        gate.create_gate(
            'Review docking results',
            output_paths=[str(ckpt_path)],
            metrics={'best_score': -8.5}
        )
        
        # Load checkpoint info into gate context
        ckpt = ckpt_mgr.load_checkpoint(checkpoint_path=str(ckpt_path))
        assert ckpt is not None
        assert ckpt['state']['best_score'] == -8.5
        
        # Approve gate
        gate.approve(notes='Docking results acceptable')
        assert gate.can_proceed()
        print("  ✓ Gate approved, can proceed")


def test_executor_to_monitor_integration():
    """Test executor output can be monitored."""
    print("Testing executor → monitor integration...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        log_path = os.path.join(tmpdir, 'test.log')
        
        # Run command and capture to log
        executor = LocalExecutor()
        ret, out, err = executor.run_command(
            ['echo', 'Test output\nGROMACS finished\n'],
        )
        
        # Write log
        with open(log_path, 'w') as f:
            f.write(out)
        
        # Monitor log
        monitor = LogMonitor(log_path)
        status = monitor.get_status()
        
        assert status == JobStatus.COMPLETED
        print(f"  ✓ Execution monitored: {status.value}")


def test_state_persistence_across_operations():
    """Test state persists across multiple operations."""
    print("Testing state persistence...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        state_file = os.path.join(tmpdir, 'state.json')
        
        # First session
        state1 = AgentState(state_file)
        state1.set('current_stage', 'docking')
        state1.set('stage.progress', 0.5)
        
        # Simulate new session
        state2 = AgentState(state_file)
        assert state2.get('current_stage') == 'docking'
        assert state2.get('stage.progress') == 0.5
        print("  ✓ State persists across sessions")


def run_all_tests():
    """Run all integration tests."""
    print("=" * 50)
    print("Phase 1 Infrastructure Integration Tests")
    print("=" * 50)
    
    tests = [
        test_config_to_executor_integration,
        test_checkpoint_to_verification_integration,
        test_executor_to_monitor_integration,
        test_state_persistence_across_operations,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"  ✗ FAILED: {e}")
            failed += 1
    
    print()
    print("=" * 50)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 50)
    
    return failed == 0


if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
